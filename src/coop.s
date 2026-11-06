; =============================================================================
; coop.s - Systemes cooperatifs
;   Ressource LIEN (0-64) : +kills, +1 toutes les 16 images quand les deux
;   vaisseaux volent a moins de 48 px l'un de l'autre (vol en formation).
;   B avec jauge pleine :
;     - deux vaisseaux en vol   -> FAISCEAU DE LIAISON : rayon tendu entre
;       les deux vaisseaux, 8 points de contact ; detruit les projectiles et
;       blesse les ennemis qui le traversent. Son efficacite depend du
;       placement relatif des deux pilotes.
;     - partenaire hors-jeu (plus de vies) -> TRANSFERT D'ENERGIE : le
;       partenaire revient en jeu.
;     - solo / partenaire en attente -> NOVA : onde de choc sur tout l'ecran.
; =============================================================================

gauge_add:
    clc
    adc gauge
    cmp #GAUGE_MAX
    bcc @st
    lda gauge
    cmp #GAUGE_MAX
    beq @full
    lda #SFX_COOPREADY
    jsr sfx_play
@full:
    lda #GAUGE_MAX
@st:
    sta gauge
    lda #1
    sta hud_dirty
    rts

; Vrai (C=1) si les deux vaisseaux sont en vol
both_alive:
    lda pl_on
    and pl_on+1
    and pl_alive
    and pl_alive+1
    lsr
    rts

coop_update:
    ; Vol en formation : recharge passive
    jsr both_alive
    bcc @beam
    lda beam_t
    bne @beam
    lda pl_u
    sec
    sbc pl_u+1
    bcs @a
    eor #$FF
    adc #1
@a:
    cmp #48
    bcs @beam
    lda pl_v
    sec
    sbc pl_v+1
    bcs @b
    eor #$FF
    adc #1
@b:
    cmp #48
    bcs @beam
    inc gauge_tick
    lda gauge_tick
    and #15
    bne @beam
    lda #1
    jsr gauge_add
@beam:
    lda nova_t
    beq @nonova
    dec nova_t
    bne @nonova
    jsr restore_bg_color
@nonova:
    lda beam_t
    beq @r
    jsr both_alive
    bcs @ok
    lda #0
    sta beam_t
    rts
@ok:
    dec beam_t
    jmp beam_compute
@r:
    rts

; X = joueur qui a appuye sur B
coop_trigger:
    lda gauge
    cmp #GAUGE_MAX
    bcc @r0
    lda beam_t
    ora nova_t
    beq @go
@r0:
    rts
@go:
    lda nplayers
    cmp #2
    bne @nova
    ; partenaire hors-jeu definitif ?
    txa
    eor #1
    tay
    lda pl_alive,y
    bne @beamchk
    lda pl_resp,y
    bne @nova               ; il revient deja : Nova
    lda #1
    sta pl_resp,y           ; TRANSFERT D'ENERGIE : reapparition immediate
    lda #0
    sta gauge
    lda #1
    sta hud_dirty
    lda #SFX_POWERUP
    jmp sfx_play
@beamchk:
    lda #BEAM_TIME
    sta beam_t
    lda #0
    sta gauge
    lda #1
    sta hud_dirty
    lda #SFX_BEAM
    jsr sfx_play
    jmp beam_compute
@nova:
    lda #NOVA_TIME
    sta nova_t
    lda #0
    sta gauge
    lda #1
    sta hud_dirty
    lda #SFX_NOVA
    jsr sfx_play
    jsr flash_bg_color
    ; degats a tous les ennemis, efface les projectiles
    stx tmp4
    ldx #MAX_EN-1
@e:
    lda en_type,x
    beq @en
    lda #8
    jsr enemy_damage
@en:
    dex
    bpl @e
    ldx #MAX_EB-1
    lda #0
@b:
    sta eb_on,x
    dex
    bpl @b
    lda #30
    jsr boss_damage
    ldx tmp4
@r:
    rts

; Points du faisceau : interpolation lineaire entre les centres des vaisseaux.
; p(k) = P0 + (P1 - P0) * (2k + 1) / 16, en 8.8 (pas = delta * 32 = delta/8).
beam_compute:
    stx tmp4
    ; pas sur u (16 bits signe) = (u1 - u0) * 16
    lda pl_u+1
    sec
    sbc pl_u
    sta ptr0
    lda #0
    sbc #0
    sta ptr0+1              ; delta signe 16 bits
    ldx #5
@su:
    asl ptr0
    rol ptr0+1
    dex
    bne @su
    lda pl_v+1
    sec
    sbc pl_v
    sta ptr1
    lda #0
    sbc #0
    sta ptr1+1
    ldx #5
@sv:
    asl ptr1
    rol ptr1+1
    dex
    bne @sv
    ; depart : P0 + 8 (centre) + demi-pas
    lda ptr0+1
    cmp #$80
    lda ptr0+1
    ror
    sta tmp1
    lda ptr0
    ror
    sta tmp0                ; demi-pas u (lo dans tmp0, hi dans tmp1)
    clc
    adc #0
    sta tmp2                ; acc u lo
    lda pl_u
    clc
    adc #8
    clc
    adc tmp1
    sta tmp3                ; acc u hi
    lda ptr1+1
    cmp #$80
    lda ptr1+1
    ror
    sta tmp6
    lda ptr1
    ror
    sta tmp5                ; acc v lo
    lda pl_v
    clc
    adc #8
    clc
    adc tmp6
    sta tmp6                ; acc v hi
    ; la retenue du demi-pas lo est negligee (< 1 px)
    ldx #0
@pt:
    lda tmp3
    sta beam_u,x
    lda tmp6
    sta beam_v,x
    clc
    lda tmp2
    adc ptr0
    sta tmp2
    lda tmp3
    adc ptr0+1
    sta tmp3
    clc
    lda tmp5
    adc ptr1
    sta tmp5
    lda tmp6
    adc ptr1+1
    sta tmp6
    inx
    cpx #BEAM_PTS
    bne @pt
    ldx tmp4
    rts

flash_bg_color:
    lda #$30
    jmp set_bg_color
restore_bg_color:
    lda #$0F
set_bg_color:
    pha
    lda #$3F
    sta ptr1+1
    lda #$00
    sta ptr1
    lda #1
    stx tmp7
    jsr vbuf_open
    pla
    sta vbuf,x
    inx
    jsr vbuf_close
    ldx tmp7
    rts

; =============================================================================
; Collisions (tests par distance entre centres, voir docs/ARCHITECTURE.md)
; =============================================================================
collisions:
    jsr col_pb_enemies
    jsr col_pb_boss
    jsr col_eb_players
    jsr col_en_players
    jsr col_items
    jsr col_players
    lda beam_t
    beq @r
    jmp col_beam
@r:
    rts

; Projectiles joueurs / ennemis : projectile 8x8 (centre +4, demi-taille 3),
; ennemi 16x16 (centre +8, demi-taille 6).
; Pour tenir le budget CPU, chaque image ne teste qu'une moitie des projectiles
; (pairs / impairs en alternance). Les projectiles avancent de 7 px/image au
; plus, soit 14 px entre deux tests, moins que la fenetre de collision (18 px) :
; aucun projectile ne peut traverser un ennemi sans etre detecte.
col_pb_enemies:
    lda frame
    and #1
    ora #MAX_PB-2
    tay
@b:
    lda pb_on,y
    beq @nb
    ldx #MAX_EN-1
@e:
    lda en_type,x
    beq @ne
    lda pb_u,y
    sec
    sbc en_u,x
    clc
    adc #9-4                ; R=9 ; (bu+4)-(eu+8)+R
    cmp #18
    bcs @ne
    lda pb_v,y
    sec
    sbc en_v,x
    clc
    adc #8-4                ; R=8
    cmp #16
    bcs @ne
    ; touche
    lda #0
    sta pb_on,y
    sty tmp4
    lda #1
    jsr enemy_damage
    ldy tmp4
    jmp @nb
@ne:
    dex
    bpl @e
@nb:
    dey
    dey
    bpl @b
    rts

col_pb_boss:
    lda boss_on
    beq @r
    lda frame
    and #1
    ora #MAX_PB-2
    tay
@b:
    lda pb_on,y
    beq @nb
    lda pb_u,y
    sec
    sbc boss_u
    clc
    adc #15-12              ; centre boss +16, R = 3+12
    cmp #30
    bcs @nb
    lda pb_v,y
    sec
    sbc boss_v
    clc
    adc #14-12              ; R = 3+11
    cmp #28
    bcs @nb
    lda #0
    sta pb_on,y
    sty tmp4
    lda #1
    jsr boss_damage
    ldy tmp4
@nb:
    dey
    dey
    bpl @b
@r:
    rts

; Projectiles ennemis / joueurs : noyau du joueur 4x4 (centre +8, demi 2),
; projectile (centre +4, demi 2) -> R = 4
col_eb_players:
    ldx #1
@p:
    lda pl_alive,x
    beq @np
    lda pl_invul,x
    bne @np
    ldy #MAX_EB-1
@b:
    lda eb_on,y
    beq @nb
    lda eb_u,y
    sec
    sbc pl_u,x
    clc
    adc #4-4
    cmp #8
    bcs @nb
    lda eb_v,y
    sec
    sbc pl_v,x
    clc
    adc #4-4
    cmp #8
    bcs @nb
    lda #0
    sta eb_on,y
    jsr player_kill
    jmp @np
@nb:
    dey
    bpl @b
@np:
    dex
    bpl @p
    rts

; Contact ennemi / joueur (R = 6+2 = 8) et boss / joueur
col_en_players:
    ldx #1
@p:
    lda pl_alive,x
    beq @np
    lda pl_invul,x
    bne @np
    ldy #MAX_EN-1
@e:
    lda en_type,y
    beq @ne
    lda en_u,y
    sec
    sbc pl_u,x
    clc
    adc #8
    cmp #16
    bcs @ne
    lda en_v,y
    sec
    sbc pl_v,x
    clc
    adc #8
    cmp #16
    bcs @ne
    jsr player_kill
    jmp @np
@ne:
    dey
    bpl @e
    ; boss : centre +16 (demi 12) contre centre joueur +8 (demi 2) -> R=14
    lda boss_on
    beq @np
    lda boss_u
    sec
    sbc pl_u,x
    clc
    adc #14+8
    cmp #28
    bcs @np
    lda boss_v
    sec
    sbc pl_v,x
    clc
    adc #12+8
    cmp #24
    bcs @np
    jsr player_kill
@np:
    dex
    bpl @p
    rts

; Capsules : ramassage genereux (R = 4+8)
col_items:
    ldx #1
@p:
    lda pl_alive,x
    beq @np
    ldy #MAX_IT-1
@i:
    lda it_on,y
    beq @ni
    lda it_u,y
    sec
    sbc pl_u,x
    clc
    adc #12-4
    cmp #24
    bcs @ni
    lda it_v,y
    sec
    sbc pl_v,x
    clc
    adc #12-4
    cmp #24
    bcs @ni
    lda #0
    sta it_on,y
    lda pl_wlv,x
    cmp #3
    bcs @maxed
    inc pl_wlv,x
@maxed:
    lda #1
    sta hud_dirty
    sty tmp4
    lda #1
    jsr add_score_hundreds
    lda #SFX_POWERUP
    jsr sfx_play
    ldy tmp4
@ni:
    dey
    bpl @i
@np:
    dex
    bpl @p
    rts

; Collision physique entre les deux vaisseaux : jamais de degats, separation
; immediate selon l'axe de moindre penetration (corps 12x12, R = 12).
col_players:
    jsr both_alive
    bcc @r0
    lda pl_u+1
    sec
    sbc pl_u
    sta tmp0                ; du signe (u1 - u0)
    clc
    adc #12
    cmp #24
    bcs @r0
    lda pl_v+1
    sec
    sbc pl_v
    sta tmp1
    clc
    adc #12
    cmp #24
    bcc @hit
@r0:
    rts
@hit:
    ; penetrations
    lda tmp0
    bpl @pu
    eor #$FF
    clc
    adc #1
@pu:
    sta tmp2                ; |du|
    lda tmp1
    bpl @pv
    eor #$FF
    clc
    adc #1
@pv:
    sta tmp3                ; |dv|
    cmp tmp2
    bcs @sep_v              ; |dv| >= |du| : separation laterale
    ; separation sur u : chacun recule de ceil((12-|du|)/2)
    lda #12
    sec
    sbc tmp2
    clc
    adc #1
    lsr
    sta tmp2
    lda tmp0
    bmi @u_neg
    ; vaisseau 1 devant : 0 recule, 1 avance
    lda pl_u
    sec
    sbc tmp2
    sta pl_u
    lda pl_u+1
    clc
    adc tmp2
    sta pl_u+1
    jmp clamp_players
@u_neg:
    lda pl_u
    clc
    adc tmp2
    sta pl_u
    lda pl_u+1
    sec
    sbc tmp2
    sta pl_u+1
    jmp clamp_players
@sep_v:
    lda #12
    sec
    sbc tmp3
    clc
    adc #1
    lsr
    sta tmp3
    lda tmp1
    bmi @v_neg
    bne @v_pos
    ; superposition exacte : ecarte selon l'index
@v_pos:
    lda pl_v
    sec
    sbc tmp3
    sta pl_v
    lda pl_v+1
    clc
    adc tmp3
    sta pl_v+1
    jmp clamp_players
@v_neg:
    lda pl_v
    clc
    adc tmp3
    sta pl_v
    lda pl_v+1
    sec
    sbc tmp3
    sta pl_v+1
    jmp clamp_players
@r:
    rts

; Ramene les deux vaisseaux dans les limites de l'ecran
clamp_players:
    ldy orient
    ldx #1
@l:
    lda pl_u,x
    cmp lim_umin,y
    bcs @a
    lda lim_umin,y
    sta pl_u,x
@a:
    lda pl_u,x
    cmp lim_umax,y
    bcc @b
    lda lim_umax,y
    sta pl_u,x
@b:
    lda pl_v,x
    cmp lim_vmin,y
    bcs @c
    lda lim_vmin,y
    sta pl_v,x
@c:
    lda pl_v,x
    cmp lim_vmax,y
    bcc @d
    lda lim_vmax,y
    sta pl_v,x
@d:
    dex
    bpl @l
    rts

; Faisceau : images paires -> ennemis et boss, impaires -> projectiles ennemis
col_beam:
    lda frame
    and #1
    bne @bullets
    ldy #BEAM_PTS-1
@pt:
    ldx #MAX_EN-1
@e:
    lda en_type,x
    beq @ne
    lda beam_u,y
    sec
    sbc en_u,x
    clc
    adc #12-8               ; point (rayon 6) vs ennemi (demi 6) : R=12
    cmp #24
    bcs @ne
    lda beam_v,y
    sec
    sbc en_v,x
    clc
    adc #12-8
    cmp #24
    bcs @ne
    sty tmp4
    lda #1
    jsr enemy_damage
    ldy tmp4
@ne:
    dex
    bpl @e
    ; boss
    lda boss_on
    beq @nboss
    lda beam_u,y
    sec
    sbc boss_u
    clc
    adc #18-16
    cmp #36
    bcs @nboss
    lda beam_v,y
    sec
    sbc boss_v
    clc
    adc #18-16
    cmp #36
    bcs @nboss
    sty tmp4
    lda #1
    jsr boss_damage
    ldy tmp4
@nboss:
    dey
    bpl @pt
    rts
@bullets:
    ldy #BEAM_PTS-1
@pt2:
    ldx #MAX_EB-1
@b:
    lda eb_on,x
    beq @nb
    lda beam_u,y
    sec
    sbc eb_u,x
    clc
    adc #9-4
    cmp #18
    bcs @nb
    lda beam_v,y
    sec
    sbc eb_v,x
    clc
    adc #9-4
    cmp #18
    bcs @nb
    lda #0
    sta eb_on,x
    lda #1
    sty tmp4
    ldy #5                  ; +1 point par projectile absorbe
    jsr add_score
    ldy tmp4
@nb:
    dex
    bpl @b
    dey
    bpl @pt2
    rts
