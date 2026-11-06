; =============================================================================
; story.s - Sequences narratives entre les secteurs et bilan de fin de secteur
;   Texte affiche lettre par lettre (1 caractere / 2 images) sur fond etoile.
;   START (l'une ou l'autre manette) passe la sequence.
; =============================================================================
STORY_ORIGIN = $20C3        ; rangee 6, colonne 3

; A = page (0 = introduction, 1 = transition secteur 2, 2 = epilogue)
story_enter:
    sta story_page
    jsr ppu_off
    lda #0
    sta split_on
    sta orient
    sta MMC3_MIRROR
    sta beam_t
    sta boss_on
    sta story_wait
    lda #ST_STORY
    sta state
    lda #<pal_title
    sta ptr0
    lda #>pal_title
    sta ptr0+1
    jsr load_palette
    jsr clear_nametables
    ldx story_page
    lda story_lo,x
    sta story_ptr
    lda story_hi,x
    sta story_ptr+1
    lda #<STORY_ORIGIN
    sta story_va
    sta story_line
    lda #>STORY_ORIGIN
    sta story_va+1
    sta story_line+1
    ; etoiles du fond (meme champ que l'ecran titre)
    ldx #MAX_FX-1
@st:
    jsr rand
    sta fx_u,x
    jsr rand
    ora #$10
    sta fx_v,x
    dex
    bpl @st
    lda #SONG_STORY
    jsr play_song
    jmp ppu_on

story_lo: .lobytes story_p0, story_p1, story_p2
story_hi: .hibytes story_p0, story_p1, story_p2

story_update:
    lda pad_new
    ora pad_new+1
    and #BTN_START
    bne story_done
    lda story_wait
    beq @type
    dec story_wait
    beq story_done
    rts
@type:
    lda frame
    and #1
    bne @r
    ldy #0
    lda (story_ptr),y
    bne @ch
    lda #180                ; texte complet : pause de 3 s
    sta story_wait
@r:
    rts
@ch:
    inc story_ptr
    bne @nc
    inc story_ptr+1
@nc:
    cmp #$0A
    bne @put
    ; saut de ligne : rangee suivante (deux rangees d'ecart)
    clc
    lda story_line
    adc #64
    sta story_line
    sta story_va
    lda story_line+1
    adc #0
    sta story_line+1
    sta story_va+1
    rts
@put:
    pha
    lda story_va
    sta ptr1
    lda story_va+1
    sta ptr1+1
    lda #1
    jsr vbuf_open
    pla
    sta vbuf,x
    inx
    jsr vbuf_close
    inc story_va
    bne @r2
    inc story_va+1
@r2:
    rts

story_done:
    lda story_page
    cmp #2
    bne @play
    jmp title_enter
@play:
    jmp stage_start

; Fond etoile anime (reutilise le dessin de l'ecran titre sans les vaisseaux)
story_draw:
    jsr oam_begin
    jsr draw_starfield
    jmp oam_end

; Textes : majuscules ASCII, $0A = nouvelle ligne, 0 = fin. 26 caracteres max.
story_p0:
    .byte "AN 2291 - BRAS D'ORION", $0A, $0A
    .byte "LA CONCORDANCE A REVEILLE", $0A
    .byte "LES SENTINELLES ET COUPE", $0A
    .byte "LES LIENS ENTRE LES MONDES.", $0A, $0A
    .byte "DEUX PILOTES VOLENT ENCORE", $0A
    .byte "EN PAIRE LIEE :", $0A
    .byte "LANCE ET EGIDE.", $0A, $0A
    .byte "OBJECTIF : STATION VESTA.", 0
story_p1:
    .byte "VESTA EST LIBEREE.", $0A, $0A
    .byte "LE SIGNAL DE LA CONCORDANCE", $0A
    .byte "VIENT DE LA SURFACE", $0A
    .byte "DE KERA.", $0A, $0A
    .byte "DESCENTE EN ORBITE BASSE...", 0
story_p2:
    .byte "KERA EST LIBEREE.", $0A, $0A
    .byte "MAIS AU LOIN, LES ANCRAGES", $0A
    .byte "S'EVEILLENT UN A UN...", $0A, $0A, $0A
    .byte "   FIN DU PROTOTYPE", $0A, $0A
    .byte "   MERCI D'AVOIR JOUE !", 0

; -----------------------------------------------------------------------------
; Bilan de fin de secteur (texte en sprites, 8 caracteres max par ligne)
; -----------------------------------------------------------------------------
bilan_build:
    ; "CIBLES nn" (nn plafonne a 99)
    ldx #0
@c:
    lda str_cibles,x
    sta bilan_buf,x
    inx
    cpx #7
    bne @c
    lda kills
    cmp #100
    bcc @k
    lda #99
@k:
    ldy #'0'-1
    sec
@div:
    iny
    sbc #10
    bcs @div
    adc #10+'0'
    sty bilan_buf+7
    sta bilan_buf+8
    lda #0
    sta bilan_buf+9
    ; "VIES n"
    lda #'V'
    sta bilan_buf+10
    lda #'I'
    sta bilan_buf+11
    lda #'E'
    sta bilan_buf+12
    lda #'S'
    sta bilan_buf+13
    lda #' '
    sta bilan_buf+14
    lda lives
    cmp #10
    bcc @l
    lda #9
@l:
    pha
    ora #'0'
    sta bilan_buf+15
    lda #0
    sta bilan_buf+16
    ; "+n000"
    lda #'+'
    sta bilan_buf+17
    pla
    ora #'0'
    sta bilan_buf+18
    lda #'0'
    sta bilan_buf+19
    sta bilan_buf+20
    sta bilan_buf+21
    lda #0
    sta bilan_buf+22
    rts

str_cibles: .byte "CIBLES "
str_bilan:  .byte "BILAN", 0
str_bonus:  .byte "BONUS", 0

; Appele par play_draw pendant l'etat NIVEAU LIBERE
draw_bilan:
    lda state
    cmp #ST_CLEAR
    bne @r
    lda state_t
    cmp #191
    bcs @r
    lda #3
    sta d_attr
    lda #<str_bilan
    ldx #>str_bilan
    ldy #80
    jsr @line
    lda #<bilan_buf
    ldx #>bilan_buf
    ldy #100
    jsr @line
    lda #<(bilan_buf+10)
    ldx #>(bilan_buf+10)
    ldy #116
    jsr @line
    lda state_t
    cmp #171
    bcs @r
    lda #<str_bonus
    ldx #>str_bonus
    ldy #136
    jsr @line
    lda #<(bilan_buf+17)
    ldx #>(bilan_buf+17)
    ldy #152
@line:
    sta ptr0
    stx ptr0+1
    sty tmp1
    lda #96
    sta tmp0
    jmp draw_text
@r:
    rts
