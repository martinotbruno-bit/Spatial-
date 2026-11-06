; =============================================================================
; story.s - Sequences narratives entre les secteurs et bilan de fin de secteur
;   Texte affiche lettre par lettre (1 caractere / 2 images) sur fond etoile.
;   START (l'une ou l'autre manette) passe la sequence.
; =============================================================================
STORY_ORIGIN = $20C3        ; rangee 6, colonne 3

; A = page (k = arrivee dans le secteur k, NUM_SECTORS = epilogue)
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
    sta cp_cam              ; nouveau secteur : pas de point de reprise
    sta cp_cam+1
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

; page k = arrivee dans le secteur k ; page NUM_SECTORS = epilogue
story_lo: .lobytes story_p0, story_p1, story_p2, story_p3, story_p4, story_p5, story_end
story_hi: .hibytes story_p0, story_p1, story_p2, story_p3, story_p4, story_p5, story_end

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
    cmp #NUM_SECTORS
    bne @play
    ; campagne terminee : mode EXPERT debloque
    lda unlocked
    ora #1
    cmp unlocked
    beq @t
    sta unlocked
    jsr save_write
@t:
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
    .byte "LA CONCORDANCE SE REPLIE", $0A
    .byte "DERRIERE LA CEINTURE", $0A
    .byte "BRISEE, OU GRANDIT", $0A
    .byte "L'ESSAIM-MERE.", $0A, $0A
    .byte "TRAVERSEE DU CHAMP", $0A
    .byte "D'ASTEROIDES...", 0
story_p3:
    .byte "LA CEINTURE EST FRANCHIE.", $0A, $0A
    .byte "LA CONCORDANCE A PRIS", $0A
    .byte "LA CITE DE LUMEN.", $0A, $0A
    .byte "SES APPAREILS DE SOUTIEN", $0A
    .byte "REPARENT LES ESCADRES.", $0A
    .byte "ABATTEZ-LES EN PREMIER !", $0A, $0A
    .byte "AU SOMMET : LE GARDE-CIEL.", 0
story_p4:
    .byte "LUMEN EST LIBEREE.", $0A, $0A
    .byte "AUX CHANTIERS D'HADAR,", $0A
    .byte "LA CONCORDANCE ACHEVE", $0A
    .byte "UN CROISEUR DE GUERRE.", $0A, $0A
    .byte "DETRUISEZ SES TOURELLES", $0A
    .byte "AVANT QU'IL NE QUITTE", $0A
    .byte "SA CALE !", 0
story_p5:
    .byte "LE CROISEUR EST DETRUIT.", $0A, $0A
    .byte "SA ROUTE MENAIT AU", $0A
    .byte "PREMIER ANCRAGE, BATI", $0A
    .byte "AVANT LES HOMMES.", $0A, $0A
    .byte "SES CRISTAUX SE FERMENT", $0A
    .byte "SOUS LE FEU : VISEZ-LES", $0A
    .byte "QUAND ILS S'OUVRENT.", 0
story_end:
    .byte "LE GARDIEN EST TOMBE.", $0A, $0A
    .byte "MAIS AU LOIN, LES ANCRAGES", $0A
    .byte "S'EVEILLENT UN A UN...", $0A, $0A, $0A
    .byte "  A SUIVRE : SECTEUR 7", $0A, $0A
    .byte "   MERCI D'AVOIR JOUE !", 0

