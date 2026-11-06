; =============================================================================
; boss.s - Mini-boss "Sentinelle KORVAX" (32x32, 2 phases)
;   Phase 1 : oscillation lente, gerbe de 3 projectiles + tir vise
;   Phase 2 (PV < 50 %) : oscillation rapide, gerbe de 5 + rafales visees
; =============================================================================

boss_spawn:
    lda #1
    sta boss_on
    lda boss_hp0
    sta boss_hp
    lda #SPAWN_U
    sta boss_u
    ldy orient
    lda lim_vmin,y
    clc
    adc lim_vmax,y
    ror
    sec
    sbc #8
    sta boss_v
    lda #0
    sta boss_ulo
    sta boss_vlo
    sta boss_t
    sta boss_ph
    sta boss_flash
    lda #1
    sta hud_dirty
    lda #MSG_WARN
    sta msg_id
    lda #120
    sta msg_t
    lda #SONG_BOSS
    jsr play_song
    lda #SFX_ALERT
    jmp sfx_play

boss_update:
    lda boss_on
    bne @on
    rts
@on:
    lda boss_flash
    beq @nf
    dec boss_flash
@nf:
    inc boss_t
    lda boss_on
    cmp #2
    beq boss_fight
    cmp #3
    bne @enter
    jmp boss_dying
@enter:
    dec boss_u
    lda boss_u
    cmp #176
    bcs @r
    lda #2
    sta boss_on
    lda #0
    sta boss_t
@r:
    rts

boss_fight:
    ; --- oscillation laterale ---
    lda boss_hp
    cmp boss_ph2
    lda #1
    bcs @p1
    lda #3
@p1:
    clc
    adc boss_ph
    sta boss_ph
    lsr
    lsr
    and #63
    tay
    clc
    lda boss_vlo
    adc sine_lo,y
    sta boss_vlo
    lda boss_v
    adc sine_hi,y
    sta boss_v
    ; bornes
    ldy orient
    cmp lim_vmin,y
    bcs @ok1
    lda lim_vmin,y
    sta boss_v
@ok1:
    lda lim_vmax,y
    sec
    sbc #16
    cmp boss_v
    bcs @ok2
    sta boss_v
@ok2:
    ; --- tirs ---
    lda boss_hp
    cmp boss_ph2
    bcc @phase2
    ; phase 1 : gerbe de 3 au debut du cycle, tir vise a mi-cycle
    ldx diff
    lda boss_t
    and boss_p1_mask,x
    bne @nf1
    lda #7
    ldy #3
    jmp boss_fan
@nf1:
    cmp #32
    bne @r
    jmp boss_aim
@phase2:
    ; phase 2 : cycle de boss_p2_len images, gerbe de boss_p2_fan projectiles,
    ; puis boss_p2_aims tirs vises espaces de 6 images
    ldx diff
    lda boss_t
    cmp boss_p2_len,x
    bcc @t
    lda #0
    sta boss_t
@t:
    lda boss_t
    bne @nf2
    lda boss_p2_dir,x
    ldy boss_p2_fan,x
    jmp boss_fan
@nf2:
    ldy boss_p2_aims,x
    cmp #12
    beq @aim
    cpy #2
    bcc @r
    cmp #18
    beq @aim
    cpy #3
    bcc @r
    cmp #24
    bne @r
@aim:
    jmp boss_aim
@r:
    rts

; Parametres de tir par difficulte : RECRUE PILOTE VETERAN EXPERT
boss_p1_mask: .byte 127, 63, 63, 63
boss_p2_len:  .byte 72,  56, 40, 34
boss_p2_fan:  .byte 3,   5,  5,  5
boss_p2_dir:  .byte 7,   6,  6,  6      ; premiere direction (gerbe centree sur 8)
boss_p2_aims: .byte 1,   2,  3,  3

; Gerbe : A = premiere direction, Y = nombre (vitesse lente)
boss_fan:
    sta tmp2
    sty tmp0
    lda boss_u
    clc
    adc #12
    sta tmp3
    lda boss_v
    clc
    adc #12
    sta tmp4
@l:
    jsr eb_spawn
    inc tmp2
    dec tmp0
    bne @l
    rts

; Tir vise rapide vers le joueur vivant le plus proche
boss_aim:
    ldy #1
    lda #$FF
    sta tmp6
@find:
    lda pl_on,y
    beq @nx
    lda pl_alive,y
    beq @nx
    sty tmp6
@nx:
    dey
    bpl @find
    ldy tmp6
    bmi @r
    lda boss_u
    clc
    adc #8
    sta tmp0
    lda pl_u,y
    sec
    sbc tmp0
    ror
    eor #$80
    sta tmp0
    lda boss_v
    clc
    adc #8
    sta tmp1
    lda pl_v,y
    sec
    sbc tmp1
    ror
    eor #$80
    sta tmp1
    jsr atan16
    ora aim_speed
    sta tmp2
    lda boss_u
    clc
    adc #12
    sta tmp3
    lda boss_v
    clc
    adc #12
    sta tmp4
    jmp eb_spawn
@r:
    rts

; Degats au boss : A = degats (invulnerable pendant l'entree)
boss_damage:
    ldy boss_on
    cpy #2
    bne @r
    sta tmp5
    lda boss_hp
    sec
    sbc tmp5
    bcc @dead
    beq @dead
    sta boss_hp
    lda #3
    sta boss_flash
    lda #1
    sta hud_dirty
@r:
    rts
@dead:
    lda #0
    sta boss_hp
    lda #3
    sta boss_on
    lda #0
    sta boss_t
    lda #1
    sta hud_dirty
    jmp stop_music

boss_dying:
    lda boss_t
    and #7
    bne @nofx
    jsr rand
    and #15
    clc
    adc boss_u
    sta tmp0
    jsr rand
    and #15
    clc
    adc boss_v
    sta tmp1
    jsr fx_spawn
    lda #SFX_EXPLODE
    jsr sfx_play
@nofx:
    lda boss_t
    cmp #100
    bcc @r
    lda #0
    sta boss_on
    lda #SFX_BIGEXPLODE
    jsr sfx_play
    lda #1
    ldy #1                  ; +10 000 points
    jsr add_score
    lda #8
    jsr gauge_add
    jmp stage_cleared
@r:
    rts
