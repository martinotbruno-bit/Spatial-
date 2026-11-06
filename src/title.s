; =============================================================================
; title.s - Ecran titre anime et menu principal
;   HAUT/BAS : choix de la ligne ; GAUCHE/DROITE : valeur ; START : depart
; =============================================================================

title_enter:
    jsr ppu_off
    lda #0
    sta split_on
    sta orient
    sta menu_sel
    sta MMC3_MIRROR
    sta beam_t
    sta boss_on
    lda #ST_TITLE
    sta state
    lda #<pal_title
    sta ptr0
    lda #>pal_title
    sta ptr0+1
    jsr load_palette
    jsr clear_nametables
    ldx #0
@s:
    lda title_strings,x
    sta ptr1+1
    lda title_strings+1,x
    sta ptr1
    lda title_strings+2,x
    sta ptr0
    lda title_strings+3,x
    sta ptr0+1
    beq @done
    txa
    pha
    jsr put_string_direct
    pla
    clc
    adc #4
    tax
    bne @s
@done:
    ; records
    lda #$22
    sta PPUADDR
    lda #$93
    sta PPUADDR
    ldx #0
@h1:
    lda hi_solo,x
    ora #'0'
    sta PPUDATA
    inx
    cpx #6
    bne @h1
    lda #$22
    sta PPUADDR
    lda #$B3
    sta PPUADDR
    ldx #0
@h2:
    lda hi_coop,x
    ora #'0'
    sta PPUDATA
    inx
    cpx #6
    bne @h2
    ; etoiles du fond anime (pool d'explosions reutilise)
    ldx #MAX_FX-1
@st:
    jsr rand
    sta fx_u,x
    jsr rand
    and #$7F
    clc
    adc #40
    sta fx_v,x
    dex
    bpl @st
    lda nplayers
    bne @np
    lda #1
    sta nplayers
@np:
    jsr menu_write
    jsr flush_vbuf_direct
    lda #SONG_TITLE
    jsr play_song
    jmp ppu_on

title_strings:
    ;      adresse VRAM, chaine
    .dbyt $20A9
    .word str_t_logo
    .dbyt $20E1
    .word str_t_sub
    .dbyt $2186
    .word str_t_m1
    .dbyt $21C6
    .word str_t_m2
    .dbyt $2206
    .word str_t_m3
    .dbyt $2286
    .word str_t_r1
    .dbyt $22A6
    .word str_t_r2
    .dbyt $2366
    .word str_t_copy
    .dbyt $0000
    .word 0

str_t_logo: .byte "S P A T I A L", 0
str_t_sub:  .byte " PROTOTYPE TECHNIQUE - PHASE 1", 0
str_t_m1:   .byte "  JOUEURS  :", 0
str_t_m2:   .byte "  VAISSEAU :", 0
str_t_m3:   .byte "  SECTEUR  :", 0
str_t_r1:   .byte "RECORD SOLO", 0
str_t_r2:   .byte "RECORD COOP", 0
str_t_copy: .byte "2026 - PROJET SPATIAL", 0
str_start:  .byte "APPUYEZ SUR START", 0
str_blank:  .byte "                 ", 0

; Ecrit les valeurs du menu et le curseur dans le tampon VRAM
menu_write:
    ; curseur
    ldy #0
@cur:
    lda menu_cursor_lo,y
    sta ptr1
    lda #$21
    cpy #2
    bne @c1
    lda #$22
@c1:
    sta ptr1+1
    lda #1
    jsr vbuf_open
    lda #' '
    cpy menu_sel
    bne @c2
    lda #'>'
@c2:
    sta vbuf,x
    inx
    jsr vbuf_close
    iny
    cpy #3
    bne @cur
    ; nombre de joueurs
    lda #$93
    sta ptr1
    lda #$21
    sta ptr1+1
    lda #1
    jsr vbuf_open
    lda nplayers
    ora #'0'
    sta vbuf,x
    inx
    jsr vbuf_close
    ; vaisseau
    lda nplayers
    cmp #2
    beq @both
    lda solo_ship
    beq @la
    lda #<str_v_egide
    ldy #>str_v_egide
    bne @wv
@la:
    lda #<str_v_lance
    ldy #>str_v_lance
    bne @wv
@both:
    lda #<str_v_both
    ldy #>str_v_both
@wv:
    sta ptr0
    sty ptr0+1
    lda #$D3
    sta ptr1
    jsr vbuf_str11
    ; secteur
    lda sector_sel
    bne @s2
    lda #<str_s1
    ldy #>str_s1
    bne @ws
@s2:
    lda #<str_s2
    ldy #>str_s2
@ws:
    sta ptr0
    sty ptr0+1
    lda #$13
    sta ptr1
    lda #$22
    sta ptr1+1
    jmp vbuf_str11

menu_cursor_lo: .byte $86, $C6, $06

; Copie 11 caracteres de ptr0 vers ptr1 via le tampon VRAM
vbuf_str11:
    lda #11
    jsr vbuf_open
    ldy #0
@l:
    lda (ptr0),y
    sta vbuf,x
    inx
    iny
    cpy #11
    bne @l
    jmp vbuf_close

str_v_lance: .byte "LANCE      "
str_v_egide: .byte "EGIDE      "
str_v_both:  .byte "LANCE+EGIDE"
str_s1:      .byte "1 STATION H"
str_s2:      .byte "2 PLANETE V"

title_update:
    lda pad_new
    ora pad_new+1
    sta tmp0
    beq @r
    and #BTN_START
    beq @nostart
    lda #SFX_MENU
    jsr sfx_play
    jmp game_start
@nostart:
    lda tmp0
    and #BTN_DOWN | BTN_SELECT
    beq @nd
    inc menu_sel
    lda menu_sel
    cmp #3
    bcc @chg
    lda #0
    sta menu_sel
    beq @chg
@nd:
    lda tmp0
    and #BTN_UP
    beq @nu
    dec menu_sel
    bpl @chg
    lda #2
    sta menu_sel
    bne @chg
@nu:
    lda tmp0
    and #BTN_LEFT | BTN_RIGHT
    beq @r
    lda menu_sel
    bne @n1
    lda nplayers            ; 1 <-> 2
    eor #3
    sta nplayers
    jmp @chg
@n1:
    cmp #1
    bne @n2
    lda solo_ship
    eor #1
    sta solo_ship
    jmp @chg
@n2:
    lda sector_sel
    eor #1
    sta sector_sel
@chg:
    lda #SFX_MENU
    jsr sfx_play
    jsr menu_write
@r:
    ; clignotement du message
    lda frame
    and #31
    bne @nb
    lda #$07
    sta ptr1
    lda #$23
    sta ptr1+1
    lda frame
    and #32
    beq @on
    lda #<str_blank
    ldy #>str_blank
    bne @w
@on:
    lda #<str_start
    ldy #>str_start
@w:
    sta ptr0
    sty ptr0+1
    lda #17
    jsr vbuf_open
    ldy #0
@cp:
    lda (ptr0),y
    sta vbuf,x
    inx
    iny
    cpy #17
    bne @cp
    jsr vbuf_close
@nb:
    rts

title_draw:
    jsr oam_begin
    ; vaisseaux de presentation
    lda #2
    sta d_size
    lda #48
    sta d_u
    lda #84
    sta d_v
    lda #0
    sta d_attr
    lda #S_SHIP_A_H
    sta d_tile
    jsr draw_obj
    lda #192
    sta d_u
    lda #1
    sta d_attr
    lda #S_SHIP_B_H
    sta d_tile
    jsr draw_obj
    jsr draw_starfield
    jmp oam_end

; Etoiles defilantes (pool d'explosions reutilise hors du jeu)
draw_starfield:
    ldx #MAX_FX-1
@st:
    txa
    and #3
    clc
    adc #1
    sta tmp0
    lda fx_u,x
    sec
    sbc tmp0
    sta fx_u,x
    ldy oam_idx
    lda fx_v,x
    sta $0200,y
    lda #'.'
    sta $0201,y
    lda #3
    sta $0202,y
    lda fx_u,x
    sta $0203,y
    iny
    iny
    iny
    iny
    sty oam_idx
    dec spr_left
    dex
    bpl @st
    rts
