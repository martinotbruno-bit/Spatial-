; =============================================================================
; player.s - Vaisseaux joueurs, armement, projectiles joueurs
; =============================================================================

;                       LANCE  EGIDE
ship_spd_lo:     .byte $80,   $C0     ; LANCE 2.5 px/image, EGIDE 1.75 px/image
ship_spd_hi:     .byte $02,   $01
ship_fire_rate:  .byte 6,     9
;                       H     V
lim_umin:        .byte 8,    16
lim_umax:        .byte 224,  200
lim_vmin:        .byte 40,   8
lim_vmax:        .byte 208,  232
pb_vmin:         .byte 28,   0
pb_vmax:         .byte 232,  248
; masques de manette : avant, arriere, lateral +, lateral -
dir_masks:
    .byte BTN_RIGHT, BTN_LEFT, BTN_DOWN, BTN_UP      ; horizontal
    .byte BTN_UP, BTN_DOWN, BTN_RIGHT, BTN_LEFT      ; vertical

players_update:
    ldx #0
@l:
    lda pl_on,x
    beq @n
    jsr player_update
@n:
    inx
    cpx #2
    bne @l
    rts

; X = joueur
player_update:
    lda pl_alive,x
    bne @alive
    lda pl_resp,x
    beq @r
    dec pl_resp,x
    bne @r
    ; reapparition
    lda #1
    sta pl_alive,x
    lda #INVUL_TIME
    sta pl_invul,x
    ldy orient
    lda start_u,y
    sta pl_u,x
    lda lim_vmin,y
    clc
    adc lim_vmax,y
    ror
    sta pl_v,x
    lda #1
    sta hud_dirty
@r:
    rts
@alive:
    lda pl_invul,x
    beq @ni
    dec pl_invul,x
@ni:
    lda pl_cool,x
    beq @nc
    dec pl_cool,x
@nc:
    ; manette associee
    ldy pl_pad,x
    lda pad,y
    sta tmp7
    lda pad_new,y
    sta tmp6
    lda state
    cmp #ST_PLAY
    beq @ctl
    lda #0                  ; hors jeu actif : pas de controle
    sta tmp7
    sta tmp6
@ctl:
    lda orient
    asl
    asl
    tay
    ; --- avant (+u) ---
    lda tmp7
    and dir_masks,y
    beq @nf
    lda pl_ulo,x
    clc
    adc ship_spd_lo,x
    sta pl_ulo,x
    lda pl_u,x
    adc ship_spd_hi,x
    sta pl_u,x
    sty tmp5
    ldy orient
    cmp lim_umax,y
    bcc @nf0
    lda lim_umax,y
    sta pl_u,x
@nf0:
    ldy tmp5
@nf:
    ; --- arriere (-u) ---
    lda tmp7
    and dir_masks+1,y
    beq @nb
    lda pl_ulo,x
    sec
    sbc ship_spd_lo,x
    sta pl_ulo,x
    lda pl_u,x
    sbc ship_spd_hi,x
    sta pl_u,x
    sty tmp5
    ldy orient
    bcc @bclamp
    cmp lim_umin,y
    bcs @nb0
@bclamp:
    lda lim_umin,y
    sta pl_u,x
@nb0:
    ldy tmp5
@nb:
    ; --- lateral + (+v) ---
    lda tmp7
    and dir_masks+2,y
    beq @np
    lda pl_vlo,x
    clc
    adc ship_spd_lo,x
    sta pl_vlo,x
    lda pl_v,x
    adc ship_spd_hi,x
    sta pl_v,x
    sty tmp5
    ldy orient
    cmp lim_vmax,y
    bcc @np0
    lda lim_vmax,y
    sta pl_v,x
@np0:
    ldy tmp5
@np:
    ; --- lateral - (-v) ---
    lda tmp7
    and dir_masks+3,y
    beq @nm
    lda pl_vlo,x
    sec
    sbc ship_spd_lo,x
    sta pl_vlo,x
    lda pl_v,x
    sbc ship_spd_hi,x
    sta pl_v,x
    ldy orient
    bcc @mclamp
    cmp lim_vmin,y
    bcs @nm
@mclamp:
    lda lim_vmin,y
    sta pl_v,x
@nm:
    ; --- tir (A maintenu) ---
    lda tmp7
    and #BTN_A
    beq @nofire
    lda pl_cool,x
    bne @nofire
    lda ship_fire_rate,x
    sta pl_cool,x
    jsr player_fire
@nofire:
    ; --- pouvoir cooperatif (B) ---
    lda tmp6
    and #BTN_B
    beq @nob
    jsr coop_trigger
@nob:
    rts

; Tir selon le vaisseau X et son niveau d'arme
player_fire:
    txa
    asl
    clc
    adc pl_wlv,x            ; ship*2 + niveau (1..3) -> index 1..5 (ship*3 serait
    adc ship_wofs,x         ; plus simple : corrige par ship_wofs)
    tay
    lda weapon_ptr_lo-1,y
    sta ptr0
    lda weapon_ptr_hi-1,y
    sta ptr0+1
    ldy #0
    lda (ptr0),y
    sta tmp0                ; nombre de projectiles
    iny
@shot:
    jsr pb_alloc            ; -> tmp1 = index libre ou C=0
    bcc @done
    stx tmp2
    ldx tmp1
    lda (ptr0),y
    sta pb_du,x
    iny
    lda (ptr0),y
    sta pb_dv,x
    iny
    lda tmp2
    tax
    lda pl_u,x
    clc
    adc #8
    pha
    lda pl_v,x
    clc
    adc #4
    clc
    adc (ptr0),y
    iny
    ldx tmp1
    sta pb_v,x
    pla
    sta pb_u,x
    ldx tmp2
    txa
    clc
    adc #1
    pha
    ldx tmp1
    pla
    sta pb_on,x
    ldx tmp2
    dec tmp0
    bne @shot
@done:
    lda shot_sfx,x
    jmp sfx_play

ship_wofs: .byte 0, 1        ; LANCE : 0+lv (1-3), EGIDE : 2+lv+1 (4-6)
shot_sfx:  .byte SFX_SHOT_A, SFX_SHOT_B

; Cherche un projectile joueur libre -> C=1 et tmp1 = index
pb_alloc:
    stx tmp3
    ldx #MAX_PB-1
@l:
    lda pb_on,x
    beq @f
    dex
    bpl @l
    ldx tmp3
    clc
    rts
@f:
    stx tmp1
    ldx tmp3
    sec
    rts

weapon_ptr_lo: .lobytes wpn_a1, wpn_a2, wpn_a3, wpn_b1, wpn_b2, wpn_b3
weapon_ptr_hi: .hibytes wpn_a1, wpn_a2, wpn_a3, wpn_b1, wpn_b2, wpn_b3
; [nombre] puis (du, dv, decalage lateral) - vitesses en px/image (signees)
wpn_a1: .byte 1,  7,0,0
wpn_a2: .byte 2,  7,0,<-4,  7,0,4
wpn_a3: .byte 4,  7,0,<-4,  7,0,4,  6,<-2,0,  6,2,0
wpn_b1: .byte 3,  5,0,0,  5,<-1,0,  5,1,0
wpn_b2: .byte 5,  5,0,0,  5,<-1,0,  5,1,0,  4,<-2,0,  4,2,0
wpn_b3: .byte 7,  5,0,0,  5,<-1,0,  5,1,0,  4,<-2,0,  4,2,0,  0,<-5,0,  0,5,0

pbullets_update:
    ldy orient
    ldx #MAX_PB-1
@l:
    lda pb_on,x
    beq @n
    lda pb_u,x
    clc
    adc pb_du,x
    sta pb_u,x
    cmp #248
    bcs @kill
    cmp #4
    bcc @kill
    lda pb_v,x
    clc
    adc pb_dv,x
    sta pb_v,x
    cmp pb_vmin,y
    bcc @kill
    cmp pb_vmax,y
    bcs @kill
@n:
    dex
    bpl @l
    rts
@kill:
    lda #0
    sta pb_on,x
    beq @n

; Perte d'un vaisseau (X = joueur)
player_kill:
    lda pl_invul,x
    bne @r
    lda pl_alive,x
    beq @r
    lda #0
    sta pl_alive,x
    sta beam_t
    lda pl_u,x
    sta tmp0
    lda pl_v,x
    sta tmp1
    jsr fx_spawn
    lda #SFX_DEATH
    jsr sfx_play
    lda pl_wlv,x
    cmp #2
    bcc @w
    dec pl_wlv,x            ; l'arme perd un niveau
@w:
    lda #1
    sta hud_dirty
    lda lives
    beq @out
    dec lives
    lda #RESPAWN_TIME
    sta pl_resp,x
@r:
    rts
@out:
    lda #0
    sta pl_resp,x
    rts
