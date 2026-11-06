; =============================================================================
; save.s - Sauvegarde non volatile (PRG-RAM MMC3 + pile, $6000-$7FFF)
; Deux copies (A en $6000, B en $6080) avec signature et somme de controle :
; une coupure d'alimentation pendant l'ecriture ne peut corrompre qu'une
; seule copie. Disposition d'une copie :
;   0-3  signature "SPTL"   4 version
;   5..  bloc persistant (persist, PERSIST_LEN octets, voir ram.inc) :
;        deblocages, secteurs debloques, encyclopedie (3 octets),
;        classement solo (5 x 8 octets), classement coop (5 x 8 octets)
;        entree de classement : 6 chiffres de score, secteur atteint
;        (1-8, 9 = campagne terminee), difficulte
;   5+PERSIST_LEN : somme de controle
; =============================================================================
SAVE_VERSION = 3
SAVE_CK      = 5 + PERSIST_LEN  ; position de la somme de controle

save_magic: .byte "SPTL", SAVE_VERSION

; Retourne C=1 si la copie pointee par ptr0 est valide
save_check:
    ldy #0
@m:
    lda (ptr0),y
    cmp save_magic,y
    bne @bad
    iny
    cpy #5
    bne @m
    jsr save_sum
    ldy #SAVE_CK
    cmp (ptr0),y
    bne @bad
    sec
    rts
@bad:
    clc
    rts

; A = somme des octets 4..SAVE_CK-1 de (ptr0), eor $A5
save_sum:
    ldy #4
    lda #0
    clc
@s:
    adc (ptr0),y
    iny
    cpy #SAVE_CK
    bne @s
    eor #$A5
    rts

save_load:
    lda #<save_a
    sta ptr0
    lda #>save_a
    sta ptr0+1
    jsr save_check
    bcs @load
    lda #<save_b
    sta ptr0
    lda #>save_b
    sta ptr0+1
    jsr save_check
    bcs @load
    ; Aucune sauvegarde valide : valeurs par defaut puis ecriture
    ldx #PERSIST_LEN-1
@def:
    lda persist_default,x
    sta persist,x
    dex
    bpl @def
    jmp save_write
@load:
    ldy #5
    ldx #0
@l:
    lda (ptr0),y
    sta persist,x
    iny
    inx
    cpx #PERSIST_LEN
    bne @l
    lda sectors_unl
    ora #1                  ; le secteur 1 est toujours disponible
    sta sectors_unl
    lda ency
    ora #3                  ; LANCE et EGIDE toujours presents
    sta ency
    rts

; Valeurs par defaut : classements 5 000, 4 000, ... 1 000 (secteur 1, PILOTE)
persist_default:
    .byte 0                 ; deblocages
    .byte 1                 ; secteurs debloques
    .byte 3, 0, 0           ; encyclopedie : LANCE, EGIDE
    .repeat 2
    .byte 0,0,5,0,0,0, 1, 1
    .byte 0,0,4,0,0,0, 1, 1
    .byte 0,0,3,0,0,0, 1, 1
    .byte 0,0,2,0,0,0, 1, 1
    .byte 0,0,1,0,0,0, 1, 1
    .endrepeat

; Ecrit la copie B puis la copie A
save_write:
    lda #$80                ; PRG-RAM : ecriture autorisee
    sta MMC3_PRGRAM
    lda #<save_b
    sta ptr0
    lda #>save_b
    sta ptr0+1
    jsr save_write_one
    lda #<save_a
    sta ptr0
    lda #>save_a
    sta ptr0+1
    jsr save_write_one
    lda #$C0                ; PRG-RAM : lecture seule (protection)
    sta MMC3_PRGRAM
    rts

save_write_one:
    ldy #0
@m:
    lda save_magic,y
    sta (ptr0),y
    iny
    cpy #5
    bne @m
    ldx #0
@d:
    lda persist,x
    sta (ptr0),y
    iny
    inx
    cpx #PERSIST_LEN
    bne @d
    jsr save_sum
    ldy #SAVE_CK
    sta (ptr0),y
    rts

; -----------------------------------------------------------------------------
; Fin de partie : insere le score dans le classement du mode (5 entrees,
; triees), puis sauvegarde. A = secteur atteint (1-8, 9 = campagne terminee).
; -----------------------------------------------------------------------------
save_update_hi:
    sta rk_sector
    lda #<rank_solo
    ldy #>rank_solo
    ldx nplayers
    cpx #2
    bne @m
    lda #<rank_coop
    ldy #>rank_coop
@m:
    sta ptr0
    sty ptr0+1
    ; position d'insertion : premiere entree dont le score est inferieur
    lda #0
    sta rk_pos
@e:
    lda rk_pos
    asl
    asl
    asl
    tay                     ; debut de l'entree
    ldx #0
@c:
    lda score,x
    cmp (ptr0),y
    bcc @next               ; plus petit : entree suivante
    bne @ins                ; plus grand : insertion ici
    iny
    inx
    cpx #6
    bne @c
@next:                      ; egalite ou inferieur : on place apres
    inc rk_pos
    lda rk_pos
    cmp #5
    bcc @e
    jmp save_write          ; hors classement : sauvegarde seulement
@ins:
    ; decale les entrees rk_pos..3 d'un cran vers le bas (de la fin)
    ldy #39-8               ; dernier octet de l'entree 3
@sh:
    tya
    lsr
    lsr
    lsr
    cmp rk_pos
    bcc @put
    lda (ptr0),y
    pha
    tya
    clc
    adc #8
    tay
    pla
    sta (ptr0),y
    tya
    sec
    sbc #9
    tay
    bpl @sh
@put:
    lda rk_pos
    asl
    asl
    asl
    tay
    ldx #0
@w:
    lda score,x
    sta (ptr0),y
    iny
    inx
    cpx #6
    bne @w
    lda rk_sector
    sta (ptr0),y
    iny
    lda diff
    sta (ptr0),y
    jmp save_write

; -----------------------------------------------------------------------------
; Encyclopedie : marque la fiche A comme decouverte. Preserve X et Y.
; Fiches : 0-1 vaisseaux, 2-11 ennemis (type + 1), 12-18 boss (11 + type).
; -----------------------------------------------------------------------------
ency_mark:
    sty rk_t
    pha
    lsr
    lsr
    lsr
    tay
    pla
    and #7
    stx rk_t+1
    tax
    lda sector_bit,x
    ora ency,y
    sta ency,y
    ldx rk_t+1
    ldy rk_t
    rts
