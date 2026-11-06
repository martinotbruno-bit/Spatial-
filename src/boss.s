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
    lda sec_hdr+SH_BOSS     ; boss final : PV et seuils de phase propres
    cmp #7
    bne @nf7
    ldx diff
    lda boss7_hp,x
    sta boss_hp
@nf7:
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
    ; boss 4 : 2 tourelles de coque a detruire avant le noyau
    lda #0
    sta part_hp
    sta part_hp+1
    lda sec_hdr+SH_BOSS
    cmp #4
    bne @nopart
    ldx diff
    lda boss4_part_hp,x
    sta part_hp
    sta part_hp+1
@nopart:
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
    lda sec_hdr+SH_BOSS
    cmp #2
    bne @k1
    jmp boss2_fire
@k1:
    cmp #3
    bne @k2
    jmp boss3_fire
@k2:
    cmp #4
    bne @k3
    jmp boss4_fire
@k3:
    cmp #5
    bne @k4
    jmp boss5_fire
@k4:
    cmp #6
    bne @k5
    jmp boss6_fire
@k5:
    cmp #7
    bne @k6
    jmp boss7_fire
@k6:
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

; -----------------------------------------------------------------------------
; Boss 2 : ESSAIM-MERE (secteur 3)
;   Phase 1 : anneau de 8 projectiles lents + un drone lache toutes les 128 img
;   Phase 2 : anneaux alternes (decales d'une direction) + tirs vises
; -----------------------------------------------------------------------------
boss2_fire:
    ldx diff
    lda boss_hp
    cmp boss_ph2
    bcc @p2
    lda boss_t
    and #127
    cmp #64
    bne @nodrone
    jsr boss2_drone
@nodrone:
    ldx diff
    lda boss_t
    and boss2_p1_mask,x
    bne @r
    lda #0
    jmp boss_ring
@p2:
    lda boss_t
    cmp boss2_p2_len,x
    bcc @t
    lda #0
    sta boss_t
    inc boss_burst          ; alterne le decalage des anneaux
@t:
    lda boss_t
    bne @na
    lda boss_burst
    and #1
    ora aim_speed           ; phase 2 : anneaux rapides sauf en RECRUE
    jmp boss_ring
@na:
    cmp #20
    beq @aim
    ldy boss_p2_aims,x
    cpy #2
    bcc @r
    cmp #28
    bne @r
@aim:
    jmp boss_aim
@r:
    rts

;                RECRUE PILOTE VETERAN EXPERT
boss2_p1_mask: .byte 63,  31,  31,  31
boss2_p2_len:  .byte 64,  44,  36,  30

; -----------------------------------------------------------------------------
; Boss 3 : GARDE-CIEL (secteur 4) - spirales
;   Phase 1 : spirale simple (direction +1 a chaque tir) + tir vise / 64 img
;   Phase 2 : double spirale opposee + tirs vises
; -----------------------------------------------------------------------------
boss3_fire:
    ldx diff
    lda boss_hp
    cmp boss_ph2
    bcc @p2
    lda boss_t
    and #63
    cmp #32
    bne @s1
    jmp boss_aim
@s1:
    lda boss_t
    and boss3_m1,x
    bne @r
    jsr boss3_origin
    lda boss_burst
    and #15
    sta tmp2
    inc boss_burst
    jmp eb_spawn
@p2:
    lda boss_t
    and #63
    cmp #20
    beq @aim
    ldy boss_p2_aims,x
    cpy #2
    bcc @s2
    cmp #44
    bne @s2
@aim:
    jmp boss_aim
@s2:
    lda boss_t
    and boss3_m2,x
    bne @r
    jsr boss3_origin
    lda boss_burst
    and #15
    sta tmp2
    jsr eb_spawn
    lda tmp2
    eor #8                  ; direction opposee
    sta tmp2
    inc boss_burst
    jmp eb_spawn
@r:
    rts

boss3_origin:
    lda boss_u
    clc
    adc #12
    sta tmp3
    lda boss_v
    clc
    adc #12
    sta tmp4
    rts

;              RECRUE PILOTE VETERAN EXPERT
boss3_m1: .byte 15,    7,     7,      3     ; periode de la spirale (masque)
boss3_m2: .byte 15,    7,     3,      3

; -----------------------------------------------------------------------------
; Boss 4 : CROISEUR EN CONSTRUCTION (secteur 5) - parties destructibles
;   Tant qu'une tourelle de coque est debout : chaque tourelle tire (vise
;   et gerbe de 3) ; le noyau est invulnerable.
;   Tourelles detruites : le noyau expose tire des anneaux et des tirs vises.
; -----------------------------------------------------------------------------
boss4_fire:
    ldx #1
@fl:
    lda part_flash,x
    beq @nf
    dec part_flash,x
@nf:
    dex
    bpl @fl
    lda part_hp
    ora part_hp+1
    beq @core
    ; tourelles : tir alterne toutes les 32 images, gerbe toutes les 96
    lda boss_t
    and #31
    bne @r
    lda boss_t
    and #32
    lsr
    lsr
    lsr
    lsr
    lsr
    tax                     ; tourelle 0 ou 1
    lda part_hp,x
    beq @r
    lda boss_u
    clc
    adc #12
    sta tmp3
    lda boss_v
    clc
    adc part_dv,x
    clc
    adc #4
    sta tmp4
    lda boss_t
    and #64
    beq @aim
    lda #7
    sta tmp2
    jsr eb_spawn
    inc tmp2
    jsr eb_spawn
    inc tmp2
    jmp eb_spawn
@aim:
    lda #8                  ; vers l'arriere (rapide selon difficulte)
    ora aim_speed
    sta tmp2
    jmp eb_spawn
@core:
    ldx diff
    lda boss_t
    and boss2_p1_mask,x
    bne @c2
    lda boss_burst
    inc boss_burst
    and #1
    jmp boss_ring
@c2:
    cmp #24
    bne @r
    jmp boss_aim
@r:
    rts

;                RECRUE PILOTE VETERAN EXPERT
boss4_part_hp: .byte 25, 35, 45, 50

; Degats aux tourelles du boss 4 : projectile joueur Y (appele par les
; collisions). C=1 si une tourelle a ete touchee (projectile consomme).
part_hit:
    ldx #1
@l:
    lda part_hp,x
    beq @n
    lda pb_u,y
    sec
    sbc boss_u
    sec
    sbc #8
    clc
    adc #10-4               ; centre tourelle +8, R = 3+7
    cmp #20
    bcs @n
    lda boss_v
    clc
    adc part_dv,x
    sta tmp0
    lda pb_v,y
    sec
    sbc tmp0
    clc
    adc #10-4
    cmp #20
    bcs @n
    jsr pb_damage
    sta tmp0
    lda part_hp,x
    sec
    sbc tmp0
    bcs @alive
    lda #0
@alive:
    sta part_hp,x
    bne @flash
    ; tourelle detruite
    lda boss_u
    clc
    adc #8
    sta tmp0
    lda boss_v
    clc
    adc part_dv,x
    sta tmp1
    jsr fx_spawn
    lda #SFX_EXPLODE
    jsr sfx_play
    sty tmp4
    lda #2
    ldy #2                  ; +2 000 points
    jsr add_score
    ldy tmp4
    sec
    rts
@flash:
    lda #4
    sta part_flash,x
    sec
    rts
@n:
    dex
    bpl @l
    clc
    rts

; -----------------------------------------------------------------------------
; Boss 5 : GARDIEN D'ANCRAGE (secteur 6) - croix tournantes
;   Phase 1 : croix de 4 projectiles qui tourne d'un cran a chaque salve
;   Phase 2 : croix tournante plus rapide, anneau de 8 toutes les 4 salves,
;             tirs vises
; -----------------------------------------------------------------------------
boss5_fire:
    ldx diff
    lda boss_hp
    cmp boss_ph2
    bcc @p2
    lda boss_t
    and boss5_m1,x
    bne @r
    jmp boss_cross
@p2:
    lda boss_t
    and #63
    cmp #30
    bne @nai
    jmp boss_aim
@nai:
    lda boss_t
    and boss5_m2,x
    bne @r
    lda boss_burst
    and #3
    bne @x
    lda boss_burst
    lsr
    lsr
    and #1
    jsr boss_ring
@x:
    jmp boss_cross
@r:
    rts

; Croix de 4 projectiles lents, rotation d'une direction a chaque appel
boss_cross:
    jsr boss3_origin
    lda boss_burst
    inc boss_burst
    and #3
    sta tmp2
    lda #4
    sta tmp0
@l:
    jsr eb_spawn
    lda tmp2
    clc
    adc #4
    sta tmp2
    dec tmp0
    bne @l
    rts

;              RECRUE PILOTE VETERAN EXPERT
boss5_m1: .byte 31,    15,    15,     7
boss5_m2: .byte 15,    15,    7,      7

; -----------------------------------------------------------------------------
; Boss 6 : AMIRAL-MACHINE (secteur 7)
;   Phase 1 : gerbe de 5 + tir vise, lache un kamikaze toutes les 128 img
;   Phase 2 : cycle de 40 img : gerbe de 5, 3 tirs vises, kamikaze / 64 img
; -----------------------------------------------------------------------------
boss6_fire:
    lda boss_hp
    cmp boss_ph2
    bcc @p2
    lda boss_t
    and #127
    cmp #96
    bne @n1
    lda #EN_KAMIKAZE
    jmp boss_minion
@n1:
    and #63
    bne @n2
    lda #6
    ldy #5
    jmp boss_fan
@n2:
    cmp #32
    bne @r
    jmp boss_aim
@p2:
    lda boss_t
    and #63
    cmp #50
    bne @nk
    lda #EN_KAMIKAZE
    jmp boss_minion
@nk:
    lda boss_burst
    cmp #40
    bcc @t
    lda #0
    sta boss_burst
@t:
    inc boss_burst
    lda boss_burst
    cmp #1
    bne @a
    lda #6
    ldy #5
    jmp boss_fan
@a:
    cmp #12
    beq @aim
    cmp #18
    beq @aim
    cmp #24
    bne @r
@aim:
    jmp boss_aim
@r:
    rts

; -----------------------------------------------------------------------------
; Boss 7 : LA CONCORDANCE (secteur 8, boss final) - 3 phases selon les PV
;   Phase 1 : anneaux alternes
;   Phase 2 : spirale rapide + tirs vises
;   Phase 3 : croix tournantes + anneaux + tirs vises + drones
; -----------------------------------------------------------------------------
boss7_fire:
    ldx diff
    lda boss_hp
    cmp boss7_th2,x
    bcc @p3
    cmp boss7_th1,x
    bcc @p2
    ; phase 1
    lda boss_t
    and boss7_m1,x
    bne @r
    lda boss_burst
    inc boss_burst
    and #1
    jmp boss_ring
@p2:
    lda boss_t
    and #63
    cmp #40
    bne @s
    jmp boss_aim
@s:
    lda boss_t
    and boss7_m2,x
    bne @r
    jsr boss3_origin
    lda boss_burst
    inc boss_burst
    and #15
    sta tmp2
    jmp eb_spawn
@p3:
    lda boss_t
    and #127
    cmp #100
    bne @nd
    lda #EN_DRONE
    jmp boss_minion
@nd:
    and #31
    cmp #16
    bne @nr
    jmp boss_aim
@nr:
    lda boss_t
    and #63
    bne @nc
    lda boss_burst
    and #1
    jmp boss_ring
@nc:
    lda boss_t
    and boss5_m2,x
    bne @r
    jmp boss_cross
@r:
    rts

;              RECRUE PILOTE VETERAN EXPERT
boss7_hp:  .byte 200,   250,   250,    250
boss7_th1: .byte 133,   166,   166,    180  ; passage en phase 2
boss7_th2: .byte 66,    83,    83,     100  ; passage en phase 3
boss7_m1:  .byte 63,    31,    31,     31
boss7_m2:  .byte 7,     3,     3,      3

; Anneau de 8 projectiles, directions A, A+2, ..., A+14 (A+16 : rapides)
boss_ring:
    sta tmp2
    lda #8
    sta tmp0
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
    lda tmp2
    clc
    adc #2
    and #31                 ; conserve le bit de vitesse (+16)
    sta tmp2
    dec tmp0
    bne @l
    rts

; Lache un drone depuis le boss
boss2_drone:
    lda #EN_DRONE
; Lache un ennemi de type A depuis le boss
boss_minion:
    sta tmp2
    lda boss_v
    clc
    adc #8
    sta tmp3
    lda boss_t
    sta tmp4
    jsr enemy_spawn
    cpx #MAX_EN
    bcs @r                  ; pool plein (X = $FF)
    lda boss_u
    sta en_u,x
@r:
    rts

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
    ; boss 4 : noyau protege tant qu'une tourelle de coque est debout
    ldy sec_hdr+SH_BOSS
    cpy #4
    bne @hit
    ldy part_hp
    bne @r
    ldy part_hp+1
    bne @r
@hit:
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
