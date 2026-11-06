; =============================================================================
; audio.s - Moteur sonore (appele depuis le NMI)
; Canaux : pulse 1 = melodie, pulse 2 = harmonie (prioritaire pour les SFX),
;          triangle = basse, bruit = batterie (et SFX), DPCM = grosse caisse.
; N'utilise que ses propres variables (au_*, mus_*, sfx_*) : aucune
; interference avec les temporaires du programme principal.
; =============================================================================

audio_init:
    lda #$0F
    sta APU_STATUS
    lda #$30
    sta APU_P1_CTRL
    sta APU_P2_CTRL
    sta APU_NO_CTRL
    lda #$80
    sta APU_TR_CTRL
    lda #$08
    sta APU_P1_SWP
    sta APU_P2_SWP
    lda #0
    sta mus_on
    sta sfx_left
    sta sfx_left+1
    ; Tables de periodes selon la region (frequence CPU differente en PAL)
    lda region
    bne @pal
    lda #<pulse_lo_ntsc
    sta tbl_plo
    lda #>pulse_lo_ntsc
    sta tbl_plo+1
    lda #<pulse_hi_ntsc
    sta tbl_phi
    lda #>pulse_hi_ntsc
    sta tbl_phi+1
    lda #<tri_lo_ntsc
    sta tbl_tlo
    lda #>tri_lo_ntsc
    sta tbl_tlo+1
    lda #<tri_hi_ntsc
    sta tbl_thi
    lda #>tri_hi_ntsc
    sta tbl_thi+1
    rts
@pal:
    lda #<pulse_lo_pal
    sta tbl_plo
    lda #>pulse_lo_pal
    sta tbl_plo+1
    lda #<pulse_hi_pal
    sta tbl_phi
    lda #>pulse_hi_pal
    sta tbl_phi+1
    lda #<tri_lo_pal
    sta tbl_tlo
    lda #>tri_lo_pal
    sta tbl_tlo+1
    lda #<tri_hi_pal
    sta tbl_thi
    lda #>tri_hi_pal
    sta tbl_thi+1
    rts

; A = numero de musique (SONG_*). Appele depuis le programme principal.
play_song:
    ldx #0
    stx mus_on              ; suspend le moteur pendant l'initialisation
    asl
    asl
    asl
    tay
@ch:
    lda song_ptrs,y
    sta mus_st_lo,x
    sta mus_ptr_lo,x
    lda song_ptrs+1,y
    sta mus_st_hi,x
    sta mus_ptr_hi,x
    lda #1
    sta mus_dur,x
    lda #0
    sta mus_vol,x
    lda ins_default,x
    sta mus_inst,x
    iny
    iny
    inx
    cpx #4
    bne @ch
    lda #$FF
    sta mus_lasthi
    sta mus_lasthi+1
    lda #1
    sta mus_on
    rts

ins_default: .byte 0, 1, 0, 0     ; lead sur pulse 1, arpege sur pulse 2

stop_music:
    lda #0
    sta mus_on
    lda #$30
    sta APU_P1_CTRL
    sta APU_P2_CTRL
    sta APU_NO_CTRL
    lda #$80
    sta APU_TR_CTRL
    rts

; A = numero d'effet (SFX_*). Preserve X et Y.
sfx_play:
    sty sfx_tp+2
    stx sfx_tp+3
    tay
    lda sfx_ptr_lo,y
    sta sfx_tp
    lda sfx_ptr_hi,y
    sta sfx_tp+1
    ldy #0
    lda (sfx_tp),y          ; canal
    tax
    lda #0
    sta sfx_left,x          ; coupe l'effet en cours sur ce canal
    clc
    lda sfx_tp
    adc #2
    sta sfx_plo,x
    lda sfx_tp+1
    adc #0
    sta sfx_phi,x
    lda #$FF
    sta sfx_lasthi
    iny
    lda (sfx_tp),y          ; nombre de trames (ecrit en dernier)
    sta sfx_left,x
    ldy sfx_tp+2
    ldx sfx_tp+3
    rts

; -----------------------------------------------------------------------------
audio_tick:
    lda mus_on
    beq @sfx
    ldx #0
@ch:
    dec mus_dur,x
    bne @env
    jsr mus_fetch
    jmp @write
@env:
    jsr mus_envelope
@write:
    jsr mus_write_vol
    inx
    cpx #4
    bne @ch
@sfx:
    jmp sfx_tick

; Lecture de l'evenement suivant du canal X et declenchement de la note
mus_fetch:
    lda mus_ptr_lo,x
    sta au_ptr
    lda mus_ptr_hi,x
    sta au_ptr+1
@read:
    ldy #0
    lda (au_ptr),y
    cmp #$FF
    bne @noloop
    lda mus_st_lo,x         ; fin de sequence : boucle
    sta au_ptr
    lda mus_st_hi,x
    sta au_ptr+1
    jmp @read
@noloop:
    cmp #$FD                ; changement d'instrument
    bne @ok
    iny
    lda (au_ptr),y
    sta mus_inst,x
    clc
    lda au_ptr
    adc #2
    sta au_ptr
    bcc @read
    inc au_ptr+1
    jmp @read
@ok:
    sta au_note
    iny
    lda (au_ptr),y
    sta mus_dur,x
    clc
    lda au_ptr
    adc #2
    sta mus_ptr_lo,x
    lda au_ptr+1
    adc #0
    sta mus_ptr_hi,x
    lda #0
    sta mus_env,x
    cpx #2
    beq @tri
    bcs @noise
    ; --- pulse 1 / pulse 2 ---
    lda au_note
    cmp #$7E
    bne @pnote
    lda #0
    sta mus_vol,x
    rts
@pnote:
    ldy mus_inst,x
    lda ins_vol0,y
    sta mus_vol,x
    cpx #1
    bne @p1
    lda sfx_left
    bne @p2skip
    ldy au_note
    lda (tbl_plo),y
    sta APU_P2_LO
    lda (tbl_phi),y
    cmp mus_lasthi+1
    beq @p2same
    sta mus_lasthi+1
    sta APU_P2_HI
@p2same:
    rts
@p2skip:
    lda #$FF
    sta mus_lasthi+1
    rts
@p1:
    ldy au_note
    lda (tbl_plo),y
    sta APU_P1_LO
    lda (tbl_phi),y
    cmp mus_lasthi
    beq @p1same
    sta mus_lasthi
    sta APU_P1_HI
@p1same:
    rts
@tri:
    lda au_note
    cmp #$7E
    bne @tnote
    lda #$80
    sta APU_TR_CTRL
    rts
@tnote:
    lda #$FF
    sta APU_TR_CTRL
    ldy au_note
    lda (tbl_tlo),y
    sta APU_TR_LO
    lda (tbl_thi),y
    sta APU_TR_HI
    rts
@noise:
    lda au_note
    cmp #$7E
    bne @drum
    lda #0
    sta mus_vol,x
    rts
@drum:
    tay
    lda drum_vol,y
    sta mus_vol,x
    lda drum_decay,y
    sta mus_env,x
    lda sfx_left+1
    bne @nskip
    lda drum_period,y
    sta APU_NO_LO
    lda #$08
    sta APU_NO_HI
@nskip:
    cpy #0
    bne @nodmc
    ; grosse caisse : echantillon DPCM
    lda #$0D
    sta APU_DMC_CTRL
    lda #<((dmc_kick - $C000) >> 6)
    sta APU_DMC_ADDR
    lda #DMC_KICK_LEN
    sta APU_DMC_LEN
    lda #$0F
    sta APU_STATUS
    lda #$1F
    sta APU_STATUS
@nodmc:
    rts

; Decroissance du volume
mus_envelope:
    cpx #2
    beq @done
    bcs @noise
    ldy mus_inst,x
    inc mus_env,x
    lda mus_env,x
    and ins_rate,y
    bne @done
    lda mus_vol,x
    cmp ins_volmin,y
    bcc @done
    beq @done
    dec mus_vol,x
@done:
    rts
@noise:
    lda mus_vol,x
    sec
    sbc mus_env,x
    bcs @nz
    lda #0
@nz:
    sta mus_vol,x
    rts

mus_write_vol:
    cpx #2
    beq @done
    bcs @noise
    cpx #1
    beq @p2
    ldy mus_inst
    lda mus_vol
    ora ins_duty,y          ; rapport cyclique de l'instrument, volume constant
    sta APU_P1_CTRL
    rts
@p2:
    lda sfx_left
    bne @done
    ldy mus_inst+1
    lda mus_vol+1
    ora ins_duty,y
    sta APU_P2_CTRL
@done:
    rts
@noise:
    lda sfx_left+1
    bne @done
    lda mus_vol+3
    ora #$30
    sta APU_NO_CTRL
    rts

; -----------------------------------------------------------------------------
sfx_tick:
    ldx #0
@ch:
    lda sfx_left,x
    beq @next
    lda sfx_plo,x
    sta au_ptr
    lda sfx_phi,x
    sta au_ptr+1
    ldy #0
    cpx #0
    bne @noise
    lda (au_ptr),y
    sta APU_P2_CTRL
    lda #$08
    sta APU_P2_SWP
    iny
    lda (au_ptr),y
    sta APU_P2_LO
    iny
    lda (au_ptr),y
    cmp sfx_lasthi
    beq @adv
    sta sfx_lasthi
    sta APU_P2_HI
    jmp @adv
@noise:
    lda (au_ptr),y
    sta APU_NO_CTRL
    iny
    lda (au_ptr),y
    sta APU_NO_LO
    lda #$08
    sta APU_NO_HI
@adv:
    clc
    lda sfx_plo,x
    adc #3
    sta sfx_plo,x
    lda sfx_phi,x
    adc #0
    sta sfx_phi,x
    dec sfx_left,x
    bne @next
    ; fin de l'effet : silence, la musique reprend le canal
    lda #$30
    cpx #0
    bne @nend
    sta APU_P2_CTRL
    lda #$FF
    sta mus_lasthi+1
    jmp @next
@nend:
    sta APU_NO_CTRL
@next:
    inx
    cpx #2
    bne @ch
    rts

; Instruments des canaux pulse : rapport cyclique ($30 = volume constant),
; volume d'attaque, periode de decroissance (masque : 0 = chaque image,
; 3 = toutes les 4 images...), volume de maintien.
;               lead  arp   pluck brass pad   bell
ins_duty:   .byte $B0,  $70,  $70,  $B0,  $30,  $F0
ins_vol0:   .byte 10,   5,    12,   12,   7,    13
ins_rate:   .byte 3,    3,    0,    7,    15,   1
ins_volmin: .byte 4,    2,    0,    8,    4,    0
;               K    S    H
drum_vol:     .byte 12,  11,  5
drum_decay:   .byte 3,   1,   2
drum_period:  .byte $0C, $05, $01
