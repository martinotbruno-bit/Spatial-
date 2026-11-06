; =============================================================================
; ency.s - Encyclopedie et classements (banc interface)
;   Encyclopedie : GAUCHE / DROITE pour parcourir, B ou START pour revenir.
;   Une fiche est decouverte a la premiere rencontre (ency_mark, save.s).
;   Classements : 5 meilleurs scores solo et coop ; B ou START pour revenir.
; =============================================================================
NUM_ENCY = 19

ency_enter:
    jsr ppu_off
    lda #ST_ENCY
    sta state
    lda #<pal_title
    sta ptr0
    lda #>pal_title
    sta ptr0+1
    jsr load_palette
    jsr clear_nametables
    lda #<str_ency_t
    sta ptr0
    lda #>str_ency_t
    sta ptr0+1
    lda #$20
    sta ptr1+1
    lda #$64                ; rangee 3, colonne 4
    sta ptr1
    jsr put_string_direct
    lda #<str_ency_help
    sta ptr0
    lda #>str_ency_help
    sta ptr0+1
    lda #$23
    sta ptr1+1
    lda #$23                ; rangee 25, colonne 3
    sta ptr1
    jsr put_string_direct
    lda #0
    sta ency_sel
    jsr ency_text_now
    jmp ppu_on

str_ency_t:    .byte "ENCYCLOPEDIE", 0
str_ency_help: .byte "<  GAUCHE / DROITE  >   B", 0
str_locked:    .byte "????????????????", 0

; Vrai (A != 0) si la fiche ency_sel est decouverte
ency_known:
    lda ency_sel
    lsr
    lsr
    lsr
    tay
    lda ency_sel
    and #7
    tax
    lda sector_bit,x
    and ency,y
    rts

ency_update:
    lda pad_new
    ora pad_new+1
    sta tmp0
    and #BTN_B | BTN_START
    beq @nb
    lda #SFX_MENU
    jsr sfx_play
    jmp title_enter
@nb:
    lda tmp0
    and #BTN_RIGHT
    beq @nr
    inc ency_sel
    lda ency_sel
    cmp #NUM_ENCY
    bcc @chg
    lda #0
    sta ency_sel
    beq @chg
@nr:
    lda tmp0
    and #BTN_LEFT
    beq @r
    dec ency_sel
    bpl @chg
    lda #NUM_ENCY-1
    sta ency_sel
@chg:
    lda #SFX_MENU
    jsr sfx_play
    lda #2                  ; texte envoye en deux images (budget du vblank)
    sta ency_dirty
@r:
    lda ency_dirty
    beq @done
    dec ency_dirty
    beq @body
    jmp ency_head
@body:
    jmp ency_body
@done:
    rts

; Ecran coupe : fiche complete ecrite d'un coup
ency_text_now:
    jsr ency_head
    jsr flush_vbuf_direct
    jsr ency_body
    jmp flush_vbuf_direct

; Numero "nn/19" et nom
ency_head:
    lda #$7A                ; rangee 3, colonne 26
    sta ptr1
    lda #$20
    sta ptr1+1
    lda #5
    jsr vbuf_open
    lda ency_sel
    clc
    adc #1
    ldy #'0'-1
    sec
@d:
    iny
    sbc #10
    bcs @d
    adc #10+'0'
    pha
    tya
    sta vbuf,x
    pla
    sta vbuf+1,x
    lda #'/'
    sta vbuf+2,x
    lda #'1'
    sta vbuf+3,x
    lda #'9'
    sta vbuf+4,x
    inx
    inx
    inx
    inx
    inx
    jsr vbuf_close
    ; nom (16 caracteres), "????" si non decouverte
    ldx ency_sel
    lda ency_name_lo,x
    sta ptr0
    lda ency_name_hi,x
    sta ptr0+1
    jsr ency_known
    bne @k
    lda #<str_locked
    sta ptr0
    lda #>str_locked
    sta ptr0+1
@k:
    lda #$C8                ; rangee 6, colonne 8
    sta ptr1
    lda #$20
    sta ptr1+1
    lda #16
    jmp ency_line

; 3 lignes de description (vides si non decouverte)
ency_body:
    lda #$02                ; rangee 16, colonne 2
    sta ptr1
    lda #$22
    sta ptr1+1
    lda #0
    sta rk_pos
@l:
    lda ency_sel
    asl
    clc
    adc ency_sel            ; fiche * 3
    clc
    adc rk_pos
    tax
    lda ency_text_lo,x
    sta ptr0
    lda ency_text_hi,x
    sta ptr0+1
    jsr ency_known
    bne @k
    lda #<str_none
    sta ptr0
    lda #>str_none
    sta ptr0+1
@k:
    lda #28
    jsr ency_line
    lda ptr1
    clc
    adc #64                 ; deux rangees plus bas
    sta ptr1
    bcc @n
    inc ptr1+1
@n:
    inc rk_pos
    lda rk_pos
    cmp #3
    bne @l
    rts

str_none: .byte 0

; Ecrit A caracteres de la chaine ptr0 (completee par des espaces) a ptr1
ency_line:
    sta tmp1
    jsr vbuf_open
    ldy #0
@c:
    lda (ptr0),y
    beq @pad
    sta vbuf,x
    inx
    iny
    cpy tmp1
    bne @c
    jmp vbuf_close
@pad:
    lda #' '
@p:
    sta vbuf,x
    inx
    iny
    cpy tmp1
    bne @p
    jmp vbuf_close

ency_draw:
    jsr oam_begin
    jsr ency_known
    beq @st
    ; jeu de sprites de la fiche (boss : banc de secteur)
    ldx ency_sel
    lda #5
    sta MMC3_BANKSEL
    lda ency_chr,x
    sta MMC3_BANKDATA
    lda ency_tile,x
    sta d_tile
    lda ency_attr,x
    sta d_attr
    lda ency_size,x
    sta d_size
    lda #120
    sta d_u
    lda #84
    sta d_v
    lda d_size
    cmp #4
    bne @sm
    lda #112
    sta d_u
    lda #76
    sta d_v
@sm:
    jsr draw_obj
@st:
    jsr draw_starfield
    jmp oam_end

; -----------------------------------------------------------------------------
; Fiches : sprite (tuile, taille, palette, banc CHR) et textes
; -----------------------------------------------------------------------------
S0 = CHR_SPR_SECTOR         ; jeu de sprites des secteurs 1-2
;                LANCE        EGIDE        DRONE        CHASSEUR     TOURELLE
ency_tile: .byte S_SHIP_A_H, S_SHIP_B_H, S_DRONE_H, S_FIGHTER_H, S_TURRET_H
;                KAMIKAZE       DECOR    LOURDE       SOUTIEN        MINEUR       MINE
           .byte S_KAMIKAZE_H, S_POD_H, S_HEAVY_H, S_SUPPORT_H, S_MINER_H, S_MINE_H
;                CRISTAL       7 boss
           .byte S_CRYSTAL_H, $C0, $C0, $C0, $C0, $C0, $C0, $C0
ency_size: .byte 2,2,2,2,2,2,2,2,2,2,2,2, 4,4,4,4,4,4,4
ency_attr: .byte 0,1,2,2,2,2,2,2,2,2,2,2, 2,2,2,2,2,2,2
ency_chr:  .byte S0,S0,S0,S0,S0,S0,S0,S0,S0,S0,S0,S0
           .byte S0, S0+1, S0+2, S0+3, S0+4, S0+5, S0+6

ency_name_lo: .lobytes en_n0,en_n1,en_n2,en_n3,en_n4,en_n5,en_n6,en_n7,en_n8,en_n9,en_n10,en_n11,en_n12,en_n13,en_n14,en_n15,en_n16,en_n17,en_n18
ency_name_hi: .hibytes en_n0,en_n1,en_n2,en_n3,en_n4,en_n5,en_n6,en_n7,en_n8,en_n9,en_n10,en_n11,en_n12,en_n13,en_n14,en_n15,en_n16,en_n17,en_n18
en_n0:  .byte "LANCE", 0
en_n1:  .byte "EGIDE", 0
en_n2:  .byte "DRONE", 0
en_n3:  .byte "CHASSEUR", 0
en_n4:  .byte "TOURELLE", 0
en_n5:  .byte "KAMIKAZE", 0
en_n6:  .byte "STRUCTURES", 0
en_n7:  .byte "UNITE LOURDE", 0
en_n8:  .byte "SOUTIEN", 0
en_n9:  .byte "POSEUR DE MINES", 0
en_n10: .byte "MINE", 0
en_n11: .byte "EMETTEUR", 0
en_n12: .byte "KORVAX", 0
en_n13: .byte "ESSAIM-MERE", 0
en_n14: .byte "GARDE-CIEL", 0
en_n15: .byte "CROISEUR", 0
en_n16: .byte "GARDIEN", 0
en_n17: .byte "AMIRAL-MACHINE", 0
en_n18: .byte "LA CONCORDANCE", 0

.define ENCY_T et0a,et0b,et0c, et1a,et1b,et1c, et2a,et2b,et2c, et3a,et3b,et3c, et4a,et4b,et4c, et5a,et5b,et5c, et6a,et6b,et6c, et7a,et7b,et7c, et8a,et8b,et8c, et9a,et9b,et9c, et10a,et10b,et10c, et11a,et11b,et11c, et12a,et12b,et12c, et13a,et13b,et13c, et14a,et14b,et14c, et15a,et15b,et15c, et16a,et16b,et16c, et17a,et17b,et17c, et18a,et18b,et18c
ency_text_lo: .lobytes ENCY_T
ency_text_hi: .hibytes ENCY_T
et0a:  .byte "INTERCEPTEUR RAPIDE.", 0
et0b:  .byte "TIR CONCENTRE ET", 0
et0c:  .byte "SURCHARGE D'ESQUIVE.", 0
et1a:  .byte "VAISSEAU D'ESCORTE LOURD.", 0
et1b:  .byte "TIR EN EVENTAIL ET", 0
et1c:  .byte "BOUCLIER FRONTAL.", 0
et2a:  .byte "AUTOMATE DE LA", 0
et2b:  .byte "CONCORDANCE. VOLE EN", 0
et2c:  .byte "ESSAIMS ONDULANTS.", 0
et3a:  .byte "FREINE, VISE DEUX FOIS", 0
et3b:  .byte "PUIS REPART. LAISSE", 0
et3c:  .byte "UNE CAPSULE.", 0
et4a:  .byte "ANCREE AU DECOR, ELLE", 0
et4b:  .byte "VISE LE VAISSEAU LE", 0
et4c:  .byte "PLUS PROCHE.", 0
et5a:  .byte "FONCE SUR SA CIBLE EN", 0
et5b:  .byte "SE RECALANT. A ABATTRE", 0
et5c:  .byte "AU PLUS VITE.", 0
et6a:  .byte "CONTENEURS, RESERVOIRS,", 0
et6b:  .byte "ROCHERS, EPAVES : DES", 0
et6c:  .byte "BUTINS A SAISIR.", 0
et7a:  .byte "CANONNIERE BLINDEE.", 0
et7b:  .byte "GERBES ET TIRS VISES,", 0
et7c:  .byte "12 POINTS DE STRUCTURE.", 0
et8a:  .byte "REPARE LES ENNEMIS", 0
et8b:  .byte "PROCHES QUI CLIGNOTENT.", 0
et8c:  .byte "CIBLE PRIORITAIRE.", 0
et9a:  .byte "S'ARRETE ET LARGUE", 0
et9b:  .byte "DES MINES DERRIERE", 0
et9c:  .byte "LUI.", 0
et10a: .byte "DERIVE PUIS EXPLOSE EN", 0
et10b: .byte "HUIT PROJECTILES.", 0
et10c: .byte "DETRUISEZ-LA AVANT.", 0
et11a: .byte "STRUCTURE CRISTALLINE.", 0
et11b: .byte "FERMEE : INVULNERABLE.", 0
et11c: .byte "OUVERTE : TIR EN CROIX.", 0
et12a: .byte "SENTINELLE DE LA", 0
et12b: .byte "STATION VESTA ET DE", 0
et12c: .byte "KERA. DEUX PHASES.", 0
et13a: .byte "RUCHE VIVANTE DE LA", 0
et13b: .byte "CEINTURE : ANNEAUX ET", 0
et13c: .byte "DRONES.", 0
et14a: .byte "FORTERESSE VOLANTE DE", 0
et14b: .byte "LUMEN. SPIRALES DE", 0
et14c: .byte "PROJECTILES.", 0
et15a: .byte "CROISEUR INACHEVE.", 0
et15b: .byte "DETRUIRE SES TOURELLES", 0
et15c: .byte "POUR ATTEINDRE LE NOYAU.", 0
et16a: .byte "OEIL DU PREMIER", 0
et16b: .byte "ANCRAGE. CROIX", 0
et16c: .byte "TOURNANTES.", 0
et17a: .byte "TETE DE LA FLOTTE.", 0
et17b: .byte "RAFALES ET LANCERS DE", 0
et17c: .byte "KAMIKAZES.", 0
et18a: .byte "INTELLIGENCE NEE D'UN", 0
et18b: .byte "ANCRAGE. COEUR DU LIEN.", 0
et18c: .byte "TROIS PHASES.", 0

; =============================================================================
; Classements
; =============================================================================
rank_enter:
    jsr ppu_off
    lda #ST_RANK
    sta state
    lda #<pal_title
    sta ptr0
    lda #>pal_title
    sta ptr0+1
    jsr load_palette
    jsr clear_nametables
    lda #<str_rank_t
    sta ptr0
    lda #>str_rank_t
    sta ptr0+1
    lda #$20
    sta ptr1+1
    lda #$6A                ; rangee 3, colonne 10
    sta ptr1
    jsr put_string_direct
    lda #<str_rk_solo
    sta ptr0
    lda #>str_rk_solo
    sta ptr0+1
    lda #$C4                ; rangee 6
    sta ptr1
    jsr put_string_direct
    lda #<str_rk_coop
    sta ptr0
    lda #>str_rk_coop
    sta ptr0+1
    lda #$21
    sta ptr1+1
    lda #$E4                ; rangee 15
    sta ptr1
    jsr put_string_direct
    lda #<rank_solo
    sta ptr0
    lda #>rank_solo
    sta ptr0+1
    lda #$21
    sta rk_t+1
    lda #$04                ; rangee 8
    sta rk_t
    jsr rank_table
    lda #<rank_coop
    sta ptr0
    lda #>rank_coop
    sta ptr0+1
    lda #$22
    sta rk_t+1
    lda #$24                ; rangee 17
    sta rk_t
    jsr rank_table
    jmp ppu_on

str_rank_t:  .byte "CLASSEMENTS", 0
str_rk_solo: .byte "SOLO", 0
str_rk_coop: .byte "COOPERATION", 0

; 5 lignes "n.  SSSSSS  Sx  NIVEAU" depuis (ptr0) a la VRAM rk_t (ecran coupe)
rank_table:
    lda #0
    sta rk_pos
@line:
    lda rk_t+1
    sta PPUADDR
    lda rk_t
    sta PPUADDR
    lda rk_pos
    clc
    adc #'1'
    sta PPUDATA
    lda #'.'
    sta PPUDATA
    lda #' '
    sta PPUDATA
    sta PPUDATA
    lda rk_pos
    asl
    asl
    asl
    tay
    ldx #6
@d:
    lda (ptr0),y
    ora #'0'
    sta PPUDATA
    iny
    dex
    bne @d
    lda #' '
    sta PPUDATA
    sta PPUDATA
    lda (ptr0),y            ; secteur atteint
    iny
    cmp #9
    bne @sec
    lda #'F'
    sta PPUDATA
    lda #'I'
    sta PPUDATA
    lda #'N'
    sta PPUDATA
    jmp @df
@sec:
    pha
    lda #'S'
    sta PPUDATA
    pla
    ora #'0'
    sta PPUDATA
    lda #' '
    sta PPUDATA
@df:
    lda #' '
    sta PPUDATA
    sta PPUDATA
    lda (ptr0),y            ; difficulte
    and #3
    tax
    lda diff_str_lo,x
    sta ptr1
    lda diff_str_hi,x
    sta ptr1+1
    ldy #0
@n:
    lda (ptr1),y
    sta PPUDATA
    iny
    cpy #7
    bne @n
    lda rk_t
    clc
    adc #32                 ; rangee suivante
    sta rk_t
    bcc @nc
    inc rk_t+1
@nc:
    inc rk_pos
    lda rk_pos
    cmp #5
    beq @r
    jmp @line
@r:
    rts

rank_update:
    lda pad_new
    ora pad_new+1
    and #BTN_B | BTN_START | BTN_A
    beq @r
    lda #SFX_MENU
    jsr sfx_play
    jmp title_enter
@r:
    rts

rank_draw:
    jsr oam_begin
    jsr draw_starfield
    jmp oam_end
