; =============================================================================
; hud.s - Interface (table de noms $2000, rangees 0-3, palette de decor 1)
;  rangee 1 : SCORE / HI (record du mode) / VIES (reserve commune)
;  rangee 2 : jauge LIEN / niveaux d'arme A et B / barre du boss
; =============================================================================
HUD_SCORE = $2027
HUD_HI    = $2032
HUD_LIVES = $203E
HUD_GAUGE = $2046
HUD_WPN_A = $2051
HUD_WPN_B = $2055
HUD_BOSS  = $205C

hud_row1: .byte " SCORE 000000  HI 000000 VIES 0 ", 0
hud_row2: .byte " LIEN          A:1 B:1 BOSS     ", 0

; Ecran coupe : textes fixes, attributs, puis valeurs
hud_init:
    lda #<hud_row1
    sta ptr0
    lda #>hud_row1
    sta ptr0+1
    lda #$20
    sta ptr1+1
    lda #$20
    sta ptr1
    jsr put_string_direct
    lda #<hud_row2
    sta ptr0
    lda #>hud_row2
    sta ptr0+1
    lda #$40
    sta ptr1
    jsr put_string_direct
    ; attributs : rangee 0 (HUD) en palette 1
    lda #$23
    sta PPUADDR
    lda #$C0
    sta PPUADDR
    lda #$55
    ldx #8
@at:
    sta PPUDATA
    dex
    bne @at
    ; record du mode
    lda #<HUD_HI
    sta ptr1
    lda #>HUD_HI
    sta ptr1+1
    lda #6
    jsr vbuf_open
    ldy #0
    lda nplayers
    cmp #2
    bne @hs
    ldy #6
@hs:
    lda #6
    sta tmp0
@hl:
    lda hi_solo,y
    ora #'0'
    sta vbuf,x
    inx
    iny
    dec tmp0
    bne @hl
    jsr vbuf_close
    jsr hud_update_now
    jmp flush_vbuf_direct

; Mise a jour au plus une image sur 4, et jamais dans la meme image qu'une
; colonne/rangee de decor (budget du retour de trame : voir BUDGETS.md)
hud_update:
    lda hud_wait
    cmp #4
    bcs @w
    inc hud_wait
@w:
    lda hud_dirty
    beq @no
    lda hud_wait
    cmp #4
    bcc @no
    lda vbuf_len
    bne @no                 ; decor deja en attente : HUD a l'image suivante
    lda #0
    sta hud_wait
    jmp hud_update_now
@no:
    rts
hud_update_now:
    lda #0
    sta hud_dirty
    ; score
    lda #<HUD_SCORE
    sta ptr1
    lda #>HUD_SCORE
    sta ptr1+1
    lda #6
    jsr vbuf_open
    ldy #0
@sc:
    lda score,y
    ora #'0'
    sta vbuf,x
    inx
    iny
    cpy #6
    bne @sc
    jsr vbuf_close
    ; vies
    lda #<HUD_LIVES
    sta ptr1
    lda #1
    jsr vbuf_open
    lda lives
    ora #'0'
    sta vbuf,x
    inx
    jsr vbuf_close
    ; jauge LIEN : 8 tuiles de 8 pixels
    lda #<HUD_GAUGE
    sta ptr1
    lda gauge
    sta tmp0
    jsr hud_bar
    ; armes
    lda #<HUD_WPN_A
    sta ptr1
    lda #1
    jsr vbuf_open
    lda #'-'
    ldy pl_on
    beq @wa
    lda pl_wlv
    ora #'0'
@wa:
    sta vbuf,x
    inx
    jsr vbuf_close
    lda #<HUD_WPN_B
    sta ptr1
    lda #1
    jsr vbuf_open
    lda #'-'
    ldy pl_on+1
    beq @wb
    lda pl_wlv+1
    ora #'0'
@wb:
    sta vbuf,x
    inx
    jsr vbuf_close
    ; barre du boss : 4 tuiles, PV/8
    lda #<HUD_BOSS
    sta ptr1
    lda #4
    jsr vbuf_open
    lda boss_on
    bne @boss
    lda #0
    ldy #4
@bz:
    sta vbuf,x
    inx
    dey
    bne @bz
    jmp vbuf_close
@boss:
    lda boss_hp
    lsr
    lsr
    lsr
    sta tmp0
    ldy #4
@bb:
    lda tmp0
    cmp #8
    bcc @bpart
    lda #8
@bpart:
    clc
    adc #T_BOSSBAR0
    sta vbuf,x
    inx
    lda tmp0
    sec
    sbc #8
    bcs @bpos
    lda #0
@bpos:
    sta tmp0
    dey
    bne @bb
    jmp vbuf_close

; Barre de 8 tuiles a ptr1 (hi = $20), valeur tmp0 (0-64)
hud_bar:
    lda #8
    jsr vbuf_open
    ldy #8
@l:
    lda tmp0
    cmp #8
    bcc @part
    lda #8
@part:
    clc
    adc #T_GAUGE0
    sta vbuf,x
    inx
    lda tmp0
    sec
    sbc #8
    bcs @pos
    lda #0
@pos:
    sta tmp0
    dey
    bne @l
    jmp vbuf_close
