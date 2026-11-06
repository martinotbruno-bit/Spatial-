; =============================================================================
; PROJET SPATIAL - Shoot'em up spatial cooperatif pour NES
; Prototype technique - Phase 1 du cahier des charges
; Assembleur : ca65 (cc65)  -  Mapper : MMC3 (TKROM)
; =============================================================================
.include "defs.inc"
.include "ram.inc"

; --- En-tete iNES --------------------------------------------------------------
.segment "HEADER"
    .byte "NES", $1A
    .byte 16            ; PRG-ROM : 16 x 16 Kio = 256 Kio
    .byte 4             ; CHR-ROM : 4 x 8 Kio  = 32 Kio
    .byte $42           ; mapper 4 (bits bas), PRG-RAM sauvegardee par pile
    .byte $00           ; mapper 4 (bits hauts)
    .byte $00, $00, $00, $00, $00, $00, $00, $00

.segment "CHARS"
    .incbin "../build/chr.bin"

; Echantillon DPCM : doit resider a $C000-$FFFF, aligne sur 64 octets.
.segment "DPCM"
dmc_kick:
    .incbin "../build/kick.dmc"

.include "../build/assets.inc"

; =============================================================================
; Demarrage (banc fixe $E000 : le seul garanti a la mise sous tension)
; =============================================================================
.segment "CODE7"

reset:
    sei
    cld
    ldx #$40
    stx APU_FRAME           ; IRQ de trame APU desactivee
    ldx #$FF
    txs
    inx                     ; X = 0
    stx PPUCTRL
    stx PPUMASK
    stx APU_DMC_CTRL        ; IRQ DMC desactivee
    stx MMC3_IRQOFF
    ; Configuration MMC3 : mode PRG 0, bancs CHR identite, PRG-RAM active.
    ldx #0
@banks:
    stx MMC3_BANKSEL
    lda mmc3_init_banks,x
    sta MMC3_BANKDATA
    inx
    cpx #8
    bne @banks
    lda #$80
    sta MMC3_PRGRAM
    lda #0
    sta MMC3_MIRROR

    bit PPUSTATUS
@vb1:
    bit PPUSTATUS
    bpl @vb1

    ; Effacement de la RAM interne
    lda #0
    tax
@clr:
    sta $0000,x
    sta $0100,x
    sta $0300,x
    sta $0400,x
    sta $0500,x
    sta $0600,x
    sta $0700,x
    inx
    bne @clr
    lda #$FF
@clroam:
    sta $0200,x
    inx
    bne @clroam

@vb2:
    bit PPUSTATUS
    bpl @vb2

    jsr detect_region
    jsr audio_init
    lda #1
    sta rng
    lda #$5A
    sta rng+1
    jsr save_load
    lda #$C0                ; PRG-RAM en lecture seule hors sauvegarde
    sta MMC3_PRGRAM
    lda #1
    sta nmi_mode
    lda #CTRL_BASE          ; NMI actif (affichage encore coupe)
    sta ctrl_shadow
    sta PPUCTRL
    cli                     ; autorise l'IRQ MMC3 (separation HUD)
    jsr title_enter_far
    jmp main_loop

mmc3_init_banks:
    ; R0, R1 : CHR 2 Kio $0000/$0800 ; R2-R5 : CHR 1 Kio $1000-$1C00
    ; R6 : PRG $8000 = banc 0 ; R7 : PRG $A000 = banc 1
    .byte CHR_BG_COMMON, 2, CHR_SPR_COMMON, CHR_SPR_COMMON+1, CHR_SPR_COMMON+2, 19, 0, 1

; -----------------------------------------------------------------------------
; Detection NTSC / PAL : nombre d'iterations d'une boucle de 11 cycles entre
; deux NMI. NTSC ~ 29780 cycles (Y = 10), PAL ~ 33247 (Y = 11),
; Dendy ~ 35464 (Y = 12, traite comme PAL 50 Hz).
; -----------------------------------------------------------------------------
detect_region:
    lda #0
    sta nmi_mode
    lda #CTRL_BASE
    sta PPUCTRL
    lda nmi_count
@w1:
    cmp nmi_count
    beq @w1
    ldx #0
    ldy #0
    lda nmi_count
@count:
    inx                     ; 2
    bne @same               ; 3 (2 + 2 pour INY toutes les 256 iterations)
    iny
@same:
    cmp nmi_count           ; 3
    beq @count              ; 3
    lda #0
    cpy #11
    bcc @ntsc
    lda #1
@ntsc:
    sta region
    lda #0
    sta PPUCTRL
    rts

; =============================================================================
; NMI : debut de la periode de retour de trame
; =============================================================================
nmi:
    pha
    txa
    pha
    tya
    pha
    inc nmi_count
    lda nmi_mode
    bne @full
    jmp @out
@full:
    lda nmi_ready
    beq @no_update
    ; Transfert DMA de la table des sprites
    lda #0
    sta OAMADDR
    lda #$02
    sta OAMDMA
    ; Tampon VRAM : [longueur|$80 si +32] [adresse haute] [adresse basse] [donnees]
    ldx #0
@vloop:
    lda vbuf,x
    beq @vdone
    inx
    tay
    lda ctrl_shadow
    cpy #$80
    bcc @inc1
    ora #CTRL_INC32
@inc1:
    sta PPUCTRL
    tya
    and #$7F
    tay
    lda vbuf,x
    sta PPUADDR
    inx
    lda vbuf,x
    sta PPUADDR
    inx
@vcopy:
    lda vbuf,x
    sta PPUDATA
    inx
    dey
    bne @vcopy
    beq @vloop
@vdone:
    lda #0
    sta vbuf
    sta vbuf_len
    sta nmi_ready
@no_update:
    lda render_on
    beq @audio
    ; Haut d'image : HUD en table de noms $2000, sans defilement
    lda ctrl_shadow
    sta PPUCTRL
    lda #0
    sta PPUSCROLL
    sta PPUSCROLL
    lda mask_shadow
    sta PPUMASK
    ; IRQ MMC3 pour la separation HUD / zone de jeu
    sta MMC3_IRQOFF
    lda split_on
    beq @audio
    lda #IRQ_SPLIT_LINE
    sta MMC3_IRQLATCH
    sta MMC3_IRQRELOAD
    sta MMC3_IRQON
@audio:
    ; Audio : 6 pas pour 5 images en PAL pour conserver le tempo
    jsr audio_tick
    lda region
    beq @out
    inc snd_acc
    lda snd_acc
    cmp #5
    bcc @out
    lda #0
    sta snd_acc
    jsr audio_tick
@out:
    pla
    tay
    pla
    tax
    pla
    rti

; =============================================================================
; IRQ MMC3 : changement de defilement en milieu d'image (methode $2006/$2005)
; =============================================================================
irq:
    pha
    sta MMC3_IRQOFF         ; acquittement
    lda split_a
    sta PPUADDR
    lda split_y
    sta PPUSCROLL
    lda split_x
    sta PPUSCROLL
    lda split_b
    sta PPUADDR
    pla
    rti

; Calcule les 4 valeurs de l'IRQ a partir de A = numero de table (0-3),
; split_x et split_y deja renseignes.
compute_split:
    asl
    asl
    sta split_a
    lda split_y
    and #$F8
    asl
    asl
    sta tmp0
    lda split_x
    lsr
    lsr
    lsr
    ora tmp0
    sta split_b
    rts

; =============================================================================
; Utilitaires
; =============================================================================

; Attend le prochain NMI
wait_nmi:
    lda nmi_count
@w:
    cmp nmi_count
    beq @w
    rts

; Coupe l'affichage et le NMI (pour les transferts massifs vers la VRAM)
ppu_off:
    jsr wait_nmi
    lda #0
    sta render_on
    sta PPUMASK
    sta PPUCTRL
    sta MMC3_IRQOFF
    rts

; Retablit le NMI ; l'affichage reprend au NMI suivant
ppu_on:
    lda #CTRL_BASE
    sta ctrl_shadow
    lda #MASK_ON
    sta mask_shadow
    lda #0
    sta vbuf
    sta vbuf_len
    sta nmi_ready
    bit PPUSTATUS
    lda ctrl_shadow
    sta PPUCTRL
    jsr wait_nmi
    lda #1
    sta render_on
    rts

; Lecture des manettes, repetee jusqu'a deux lectures identiques
; (les lectures DMC peuvent corrompre $4016/$4017).
read_pads:
    lda pad
    sta pad_prev
    lda pad+1
    sta pad_prev+1
@again:
    jsr read_once
    lda tmp0
    sta tmp2
    lda tmp1
    sta tmp3
    jsr read_once
    lda tmp0
    cmp tmp2
    bne @again
    lda tmp1
    cmp tmp3
    bne @again
    lda tmp0
    sta pad
    eor pad_prev
    and pad
    sta pad_new
    lda tmp1
    sta pad+1
    eor pad_prev+1
    and pad+1
    sta pad_new+1
    rts

read_once:
    lda #1
    sta JOY1
    lsr
    sta JOY1
    ldx #8
@bit:
    lda JOY1
    and #3
    cmp #1
    rol tmp0
    lda JOY2
    and #3
    cmp #1
    rol tmp1
    dex
    bne @bit
    rts

; Generateur pseudo-aleatoire (LFSR 16 bits de Galois) -> A
rand:
    lda rng
    asl
    rol rng+1
    bcc @nx
    eor #$2D
@nx:
    sta rng
    eor rng+1
    rts

; Ajoute une entree au tampon VRAM.
; Entree : A = longueur (|$80 pour +32), ptr1 = adresse VRAM (hi dans ptr1+1)
; Sortie : X = index ou ecrire les donnees. L'appelant ecrit A octets a vbuf,x
; puis appelle vbuf_close avec X apres le dernier octet.
vbuf_open:
    ldx vbuf_len
    sta vbuf,x
    inx
    lda ptr1+1
    sta vbuf,x
    inx
    lda ptr1
    sta vbuf,x
    inx
    rts

vbuf_close:
    lda #0
    sta vbuf,x
    stx vbuf_len
    rts

; Ecrit une chaine terminee par 0 (ptr0) a l'adresse VRAM ptr1 - ecran coupe.
put_string_direct:
    lda ptr1+1
    sta PPUADDR
    lda ptr1
    sta PPUADDR
    ldy #0
@l:
    lda (ptr0),y
    beq @d
    sta PPUDATA
    iny
    bne @l
@d:
    rts

; Remplit les 4 tables de noms (et leurs attributs) avec 0 - ecran coupe.
clear_nametables:
    lda #CTRL_BASE & $7F
    sta PPUCTRL
    lda #$20
    sta PPUADDR
    lda #$00
    sta PPUADDR
    ldy #16
    ldx #0
    lda #0
@l:
    sta PPUDATA
    inx
    bne @l
    dey
    bne @l
    rts

; Charge 32 octets de palette depuis ptr0 - ecran coupe.
load_palette:
    lda #$3F
    sta PPUADDR
    lda #$00
    sta PPUADDR
    ldy #0
@l:
    lda (ptr0),y
    sta PPUDATA
    iny
    cpy #32
    bne @l
    rts

; =============================================================================
; Boucle principale
; =============================================================================
main_loop:
    jsr wait_nmi
    sta DEBUG_MARK_START    ; debut du travail de l'image (profilage)
    lda nmi_count
    sta loop_nmi
    jsr read_pads
    inc frame
    jsr state_update
    ; Compensation PAL : une mise a jour logique supplementaire toutes les 5
    ; images, sans affichage (50 Hz x 6/5 = 60 mises a jour par seconde).
    lda region
    beq @draw
    inc pal_acc
    lda pal_acc
    cmp #5
    bcc @draw
    lda #0
    sta pal_acc
    lda #0
    sta pad_new
    sta pad_new+1
    jsr state_update
@draw:
    jsr state_draw
    sta DEBUG_MARK          ; fin du travail de l'image (profilage)
    ; Si un NMI est survenu pendant le calcul, une image a ete perdue (lag).
    lda nmi_count
    cmp loop_nmi
    beq @ok
    inc lag_count
@ok:
    lda #1
    sta nmi_ready
    jmp main_loop

state_update:
    lda state
    asl
    tax
    lda state_upd_tbl+1,x
    pha
    lda state_upd_tbl,x
    pha
    rts

state_draw:
    lda state
    asl
    tax
    lda state_drw_tbl+1,x
    pha
    lda state_drw_tbl,x
    pha
    rts

state_upd_tbl:
    .word title_update-1, play_update-1, clear_update-1, over_update-1, end_update-1
    .word story_update-1, cont_update-1
state_drw_tbl:
    .word title_draw-1, play_draw-1, play_draw-1, play_draw-1, play_draw-1
    .word story_draw-1, play_draw-1

.include "audio.s"
.include "save.s"
.include "hud.s"
.include "data.s"
.include "boss.s"
.include "coop.s"

; Banc fixe $C000 : code critique du jeu
.segment "CODE"
.include "render.s"
.include "stage.s"
.include "player.s"
.include "enemy.s"

; -----------------------------------------------------------------------------
; Interface en banc commutable (banc UI_BANK en $8000) : l'ecran titre et les
; sequences narratives ne tournent que lorsqu'aucun secteur n'est charge.
; Les tremplins ci-dessous (banc fixe) mappent le banc avant d'y sauter ;
; story_done quitte le banc par un saut vers stage_start (banc fixe), qui
; remappe le secteur.
; -----------------------------------------------------------------------------
UI_BANK = 5
.segment "CODE7"
map_ui:
    lda #6
    sta MMC3_BANKSEL
    lda #UI_BANK
    sta MMC3_BANKDATA
    rts

title_enter_far:
    jsr map_ui
    jmp title_enter

; A = page
story_enter_far:
    pha
    jsr map_ui
    pla
    jmp story_enter

.segment "UI"
.include "title.s"
.include "story.s"

.segment "VECTORS"
    .word nmi, reset, irq
