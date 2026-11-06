; =============================================================================
; enemy.s - Ennemis, projectiles ennemis, explosions, capsules
; Positions en virgule fixe 8.8, vitesses signees 8.8.
; =============================================================================

;                   -    DRONE   CHASSEUR TOURELLE KAMIKAZE DECOR LOURDE SOUTIEN MINEUR MINE CRISTAL
en_hp_tbl:    .byte 0,   1,      4,       6,       2,       3,    12,    5,      6,     2,   8
en_score_tbl: .byte 0,   1,      3,       5,       2,       2,    8,     6,      7,     1,   9  ; centaines
en_gauge_tbl: .byte 0,   2,      3,       4,       2,       1,    5,     3,      4,     1,   4

; Apparition : tmp2 = type, tmp3 = v, tmp4 = parametre
enemy_spawn:
    ldx #MAX_EN-1
@f:
    lda en_type,x
    beq @ok
    dex
    bpl @f
    rts                     ; pool plein : apparition ignoree (mesure dans les tests)
@ok:
    lda tmp2
    sta en_type,x
    tay
    lda en_hp_tbl,y
    sta en_hp,x
    lda #SPAWN_U
    sta en_u,x
    lda tmp3
    sta en_v,x
    lda tmp4
    sta en_p0,x
    lda #0
    sta en_ulo,x
    sta en_vlo,x
    sta en_t,x
    sta en_st,x
    sta en_flash,x
    sta en_dvlo,x
    sta en_dvhi,x
    ; vitesse initiale selon le type
    lda en_init_du_lo,y
    sta en_dulo,x
    lda en_init_du_hi,y
    sta en_duhi,x
    rts

;                     -     DRONE  CHASSEUR TOURELLE KAMIKAZE DECOR LOURDE SOUTIEN MINEUR MINE CRISTAL
en_init_du_lo: .byte 0,    $C0,   $00,     $00,     $00,     $00,  $40,   $00,    $C0,   $00, $00
en_init_du_hi: .byte 0,    $FE,   $FD,     $FF,     $FE,     $FF,  $FF,   $FF,    $FE,   $FF, $FF

enemies_update:
    ldx #MAX_EN-1
@l:
    lda en_type,x
    beq @n
    lda en_flash,x
    beq @nf
    dec en_flash,x
@nf:
    inc en_t,x
    lda en_type,x
    asl
    tay
    lda en_ai_tbl+1,y
    pha
    lda en_ai_tbl,y
    pha
    rts                     ; -> comportement, qui revient a en_move
@n:
    dex
    bpl @l
    rts

en_ai_tbl:
    .word 0, ai_drone-1, ai_fighter-1, ai_turret-1, ai_kamikaze-1, ai_pod-1, ai_heavy-1, ai_support-1, ai_miner-1, ai_mine-1, ai_crystal-1

; Integration de la position, puis retour a la boucle. Detruit l'ennemi s'il
; sort du champ (debordement 8 bits).
en_move:
    clc
    lda en_ulo,x
    adc en_dulo,x
    sta en_ulo,x
    lda en_u,x
    adc en_duhi,x
    sta en_u,x
    ; debordement : vitesse negative et pas de retenue => passe sous 0
    lda en_duhi,x
    bmi @neg
    bcs @gone
    bcc @v
@neg:
    bcc @gone
@v:
    clc
    lda en_vlo,x
    adc en_dvlo,x
    sta en_vlo,x
    lda en_v,x
    adc en_dvhi,x
    sta en_v,x
    lda en_dvhi,x
    bmi @vneg
    bcs @gone
    bcc @next
@vneg:
    bcc @gone
@next:
    dex
    bpl enemies_update_cont
    rts
@gone:
    lda #0
    sta en_type,x
    beq @next

enemies_update_cont:
    jmp enemies_update+2    ; reprend la boucle avec X courant

; --- DRONE : avance a vitesse constante en ondulant ---
ai_drone:
    lda en_t,x
    asl
    clc
    adc en_p0,x             ; parametre = dephasage
    and #63
    tay
    lda sine_lo,y
    sta en_dvlo,x
    lda sine_hi,y
    sta en_dvhi,x
    jmp en_move

; --- CHASSEUR : entre vite, freine jusqu'a u = parametre, tire, repart ---
ai_fighter:
    lda en_st,x
    bne @s1
    lda en_u,x
    cmp en_p0,x
    bcs @mv
    lda #1
    sta en_st,x
    lda #0
    sta en_t,x
    sta en_dulo,x
    sta en_duhi,x
    beq @mv
@s1:
    cmp #1
    bne @mv
    lda en_t,x
    cmp #20
    bne @n20
    jsr fire_aimed
@n20:
    lda en_t,x
    cmp #32
    bne @n32
    lda fighter_x3          ; VETERAN/EXPERT : tir supplementaire
    beq @mv
    jsr fire_aimed
    jmp @mv
@n32:
    cmp #44
    bne @mv
    jsr fire_aimed
    lda #2
    sta en_st,x
    lda #$80
    sta en_dulo,x
    lda #$FD                ; -2.5 : repart vers l'arriere
    sta en_duhi,x
@mv:
    jmp en_move

; --- TOURELLE : liee au decor, tir vise periodique ---
ai_turret:
    lda scroll_on
    bne @sc
    lda #0
    sta en_duhi,x
    beq @f
@sc:
    lda #$FF
    sta en_duhi,x           ; -1 px/image = vitesse du decor
@f:
    lda en_t,x
    and turret_mask         ; periode selon la difficulte
    cmp #16
    bne @mv
    lda en_u,x
    cmp #232
    bcs @mv
    jsr fire_aimed
@mv:
    jmp en_move

; --- UNITE LOURDE : s'avance jusqu'a u = parametre, se maintient en
; derivant lateralement, gerbe de 3 + tir vise toutes les 96 images, repart
; apres 10 s ---
ai_heavy:
    lda en_st,x
    bne @hold
    lda en_u,x
    cmp en_p0,x
    bcc @stop
    jmp en_move
@stop:
    lda #1
    sta en_st,x
    lda #0
    sta en_t,x
    sta en_p0,x             ; desormais : compteur de cycles de tir
    sta en_dulo,x
    sta en_duhi,x
@hold:
    cmp #2
    beq @mv
    ; derive laterale lente (sinus / 4)
    lda en_t,x
    and #63
    tay
    lda sine_hi,y
    cmp #$80
    ror
    sta en_dvhi,x
    lda sine_lo,y
    ror
    sta en_dvlo,x
    lda en_dvhi,x
    cmp #$80
    ror en_dvhi,x
    ror en_dvlo,x
    ; tirs
    lda en_t,x
    cmp #96
    bcc @t
    lda #0
    sta en_t,x
    inc en_p0,x
    lda en_p0,x
    cmp #7                  ; ~11 s de maintien
    bcc @t
    lda #2                  ; depart : recule a -1.5 px/image
    sta en_st,x
    lda #$80
    sta en_dulo,x
    lda #$FE
    sta en_duhi,x
    jmp en_move
@t:
    lda en_t,x
    cmp #20
    bne @n1
    lda en_u,x
    clc
    adc #4
    sta tmp3
    lda en_v,x
    clc
    adc #4
    sta tmp4
    lda #7
    sta tmp2
    jsr eb_spawn
    inc tmp2
    jsr eb_spawn
    inc tmp2
    jsr eb_spawn
    jmp @mv
@n1:
    cmp #60
    bne @mv
    jsr fire_aimed
@mv:
    jmp en_move

; --- APPAREIL DE SOUTIEN : s'arrete a u = parametre ; toutes les 48 images
; il repare (+2 PV, max 20) les ennemis a moins de 40 px, qui clignotent ;
; repart apres 12 cycles. Cible prioritaire ---
ai_support:
    lda en_st,x
    bne @hold
    lda en_u,x
    cmp en_p0,x
    bcc @stop
    jmp en_move
@stop:
    lda #1
    sta en_st,x
    lda #0
    sta en_t,x
    sta en_p0,x
    sta en_dulo,x
    sta en_duhi,x
@hold:
    cmp #2
    beq @mv
    lda en_t,x
    cmp #48
    bcc @mv
    lda #0
    sta en_t,x
    inc en_p0,x
    lda en_p0,x
    cmp #12
    bcc @rep
    lda #2                  ; depart
    sta en_st,x
    lda #$80
    sta en_dulo,x
    lda #$FE
    sta en_duhi,x
    jmp en_move
@rep:
    ldy #MAX_EN-1
@l:
    lda en_type,y
    beq @n
    cmp #EN_SUPPORT
    beq @n
    lda en_u,y
    sec
    sbc en_u,x
    clc
    adc #40
    cmp #80
    bcs @n
    lda en_v,y
    sec
    sbc en_v,x
    clc
    adc #40
    cmp #80
    bcs @n
    lda en_hp,y
    cmp #19
    bcs @n
    adc #2
    sta en_hp,y
    lda #8
    sta en_flash,y          ; signal visuel de reparation
@n:
    dey
    bpl @l
@mv:
    jmp en_move

; --- POSEUR DE MINES : s'arrete a u = parametre, largue une mine toutes les
; 64 images (8 fois), puis repart ---
ai_miner:
    lda en_st,x
    bne @hold
    lda en_u,x
    cmp en_p0,x
    bcc @stop
    jmp en_move
@stop:
    lda #1
    sta en_st,x
    lda #0
    sta en_t,x
    sta en_p0,x
    sta en_dulo,x
    sta en_duhi,x
@hold:
    cmp #2
    beq @mv
    lda en_t,x
    cmp #64
    bcc @mv
    lda #0
    sta en_t,x
    inc en_p0,x
    lda en_p0,x
    cmp #9
    bcc @drop
    lda #2
    sta en_st,x
    lda #$80
    sta en_dulo,x
    lda #$FE
    sta en_duhi,x
    jmp en_move
@drop:
    txa
    pha
    lda en_u,x
    pha
    lda #EN_MINE
    sta tmp2
    lda en_v,x
    sta tmp3
    lda #0
    sta tmp4
    jsr enemy_spawn
    pla
    cpx #MAX_EN
    bcs @full
    sec
    sbc #8                  ; largue derriere le poseur
    sta en_u,x
@full:
    pla
    tax
@mv:
    jmp en_move

; --- MINE : derive avec le decor ; explose en anneau de 8 projectiles apres
; 150 images ou quand un vaisseau passe a moins de 28 px ---
ai_mine:
    lda #$FF
    ldy scroll_on
    bne @s
    lda #0
@s:
    sta en_duhi,x
    lda en_t,x
    cmp #150
    bcs @boom
    ldy #1
@p:
    lda pl_alive,y
    beq @np
    lda pl_u,y
    sec
    sbc en_u,x
    clc
    adc #28
    cmp #56
    bcs @np
    lda pl_v,y
    sec
    sbc en_v,x
    clc
    adc #28
    cmp #56
    bcc @boom
@np:
    dey
    bpl @p
    jmp en_move
@boom:
    lda en_u,x
    clc
    adc #4
    sta tmp3
    lda en_v,x
    clc
    adc #4
    sta tmp4
    lda #0
    sta tmp2
    lda #8
    sta tmp0
@ring:
    jsr eb_spawn
    lda tmp2
    clc
    adc #2
    sta tmp2
    dec tmp0
    bne @ring
    lda en_u,x
    sta tmp0
    lda en_v,x
    sta tmp1
    jsr fx_spawn
    lda #SFX_HIT
    jsr sfx_play
    lda #0
    sta en_type,x
    jmp en_move

; --- EMETTEUR CRISTALLIN : ancre au decor ; cycle de 128 images :
; 0-63 ferme (blanc, invulnerable), 64-127 ouvert (tir en croix a 64,
; en diagonales a 96) ---
ai_crystal:
    lda #$FF
    ldy scroll_on
    bne @s
    lda #0
@s:
    sta en_duhi,x
    lda en_t,x
    and #127
    cmp #64
    bcs @open
    lda #2                  ; ferme : palette blanche (meme que le flash)
    sta en_flash,x
    lda #1
    sta en_st,x
    jmp en_move
@open:
    lda #0
    sta en_st,x
    lda en_t,x
    and #127
    cmp #64
    beq @cross
    cmp #96
    bne @mv
    lda #2                  ; diagonales
    jmp @fire
@cross:
    lda #0
@fire:
    sta tmp2
    lda en_u,x
    clc
    adc #4
    sta tmp3
    lda en_v,x
    clc
    adc #4
    sta tmp4
    lda #4
    sta tmp0
@f:
    jsr eb_spawn
    lda tmp2
    clc
    adc #4
    sta tmp2
    dec tmp0
    bne @f
@mv:
    jmp en_move

; --- CONTENEUR : ancre sur la coque, suit le decor, ne tire pas ---
ai_pod:
    lda #$FF
    ldy scroll_on
    bne @s
    lda #0
@s:
    sta en_duhi,x
    jmp en_move

; --- KAMIKAZE : fonce en se recalant lateralement sur le joueur le plus proche
ai_kamikaze:
    jsr nearest_player      ; -> Y = joueur ou C=0
    bcc @mv
    lda pl_v,y
    cmp en_v,x
    bcc @up
    ; accelere vers +v
    lda en_dvlo,x
    clc
    adc #$10
    sta en_dvlo,x
    lda en_dvhi,x
    adc #0
    sta en_dvhi,x
    jmp @clamp
@up:
    lda en_dvlo,x
    sec
    sbc #$10
    sta en_dvlo,x
    lda en_dvhi,x
    sbc #0
    sta en_dvhi,x
@clamp:
    ; |dv| <= 1.5
    lda en_dvhi,x
    bmi @negc
    cmp #1
    bcc @mv
    lda en_dvlo,x
    cmp #$80
    bcc @mv
    lda #$80
    sta en_dvlo,x
    lda #1
    sta en_dvhi,x
    bne @mv
@negc:
    cmp #$FE
    bcs @mv1
    lda #$80
    sta en_dvlo,x
    lda #$FE
    sta en_dvhi,x
    bne @mv
@mv1:
    bne @mv
    lda en_dvlo,x
    cmp #$80
    bcs @mv
    lda #$80
    sta en_dvlo,x
@mv:
    jmp en_move

; Joueur vivant le plus proche (distance sur v) -> Y, C=1 ; C=0 si aucun
nearest_player:
    lda #$FF
    sta tmp5
    ldy #$FF
    sty tmp6
    ldy #1
@l:
    lda pl_on,y
    beq @n
    lda pl_alive,y
    beq @n
    lda pl_v,y
    sec
    sbc en_v,x
    bcs @p
    eor #$FF
    adc #1
@p:
    cmp tmp5
    bcs @n
    sta tmp5
    sty tmp6
@n:
    dey
    bpl @l
    ldy tmp6
    cpy #$FF
    beq @none
    sec
    rts
@none:
    clc
    rts

; -----------------------------------------------------------------------------
; Tir vise depuis l'ennemi X (vitesse rapide)
; -----------------------------------------------------------------------------
fire_aimed:
    ; en solo, un tir vise sur deux est annule (les motifs des boss, eux,
    ; restent complets)
    lda nplayers
    cmp #2
    beq @go
    inc solo_skip
    lda solo_skip
    and #1
    beq @r
@go:
    jsr nearest_player
    bcc @r
    ; du = (pu - eu) / 2, dv = (pv - ev) / 2  (centres identiques : 16x16)
    lda pl_u,y
    sec
    sbc en_u,x
    ror                     ; retenue = signe inverse -> division signee
    eor #$80
    sta tmp0
    lda pl_v,y
    sec
    sbc en_v,x
    ror
    eor #$80
    sta tmp1
    jsr atan16              ; -> A = direction 0-15
    ora aim_speed           ; vitesse selon la difficulte
    sta tmp2
    lda en_u,x
    clc
    adc #4
    sta tmp3
    lda en_v,x
    clc
    adc #4
    sta tmp4
    jmp eb_spawn
@r:
    rts

; Projectile ennemi : tmp2 = direction (+16 = rapide), tmp3/tmp4 = u/v
; Preserve X.
eb_spawn:
    stx tmp7
    ldx #MAX_EB-1
@f:
    lda eb_on,x
    beq @ok
    dex
    bpl @f
    ldx tmp7
    rts
@ok:
    lda #1
    sta eb_on,x
    lda tmp3
    sta eb_u,x
    lda tmp4
    sta eb_v,x
    lda #0
    sta eb_ulo,x
    sta eb_vlo,x
    ldy tmp2
    cpy #16
    bcs @fast
    lda dir0_du_lo,y
    sta eb_dulo,x
    lda dir0_du_hi,y
    sta eb_duhi,x
    lda dir0_dv_lo,y
    sta eb_dvlo,x
    lda dir0_dv_hi,y
    sta eb_dvhi,x
    ldx tmp7
    rts
@fast:
    lda dir1_du_lo-16,y
    sta eb_dulo,x
    lda dir1_du_hi-16,y
    sta eb_duhi,x
    lda dir1_dv_lo-16,y
    sta eb_dvlo,x
    lda dir1_dv_hi-16,y
    sta eb_dvhi,x
    ldx tmp7
    rts

; -----------------------------------------------------------------------------
; atan16 : tmp0 = du, tmp1 = dv (signes, |x| <= 128) -> A = direction 0-15
; 0 = +u, 4 = +v, 8 = -u, 12 = -v. Seuils : tan(11.25)~1/5, tan(33.75)~2/3,
; tan(56.25)~3/2, tan(78.75)~5. Utilise tmp5-tmp7 et ptr1.
; -----------------------------------------------------------------------------
atan16:
    lda tmp0
    bpl @a
    eor #$FF
    clc
    adc #1
@a:
    sta tmp5                ; a = |du|
    lda tmp1
    bpl @b
    eor #$FF
    clc
    adc #1
@b:
    sta tmp6                ; b = |dv|
    ; 5b < a ?
    lda tmp6
    sta ptr1
    lda #0
    sta ptr1+1
    asl ptr1
    rol ptr1+1
    asl ptr1
    rol ptr1+1              ; 4b
    clc
    lda ptr1
    adc tmp6
    sta ptr1
    lda ptr1+1
    adc #0
    sta ptr1+1              ; 5b
    bne @not0
    lda ptr1
    cmp tmp5
    bcs @not0
    lda #0
    jmp @quad
@not0:
    ; 3b < 2a ?
    lda tmp6
    asl
    sta ptr1
    lda #0
    rol
    sta ptr1+1
    clc
    lda ptr1
    adc tmp6
    sta ptr1
    lda ptr1+1
    adc #0
    sta ptr1+1              ; 3b
    lda tmp5
    asl
    sta tmp7
    lda #0
    rol                     ; 2a (hi dans A)
    cmp ptr1+1
    bcc @not1
    bne @is1
    lda tmp7
    cmp ptr1
    bcc @not1
    beq @not1
@is1:
    lda #1
    jmp @quad
@not1:
    ; 2b < 3a ?
    lda tmp5
    asl
    sta ptr1
    lda #0
    rol
    sta ptr1+1
    clc
    lda ptr1
    adc tmp5
    sta ptr1
    lda ptr1+1
    adc #0
    sta ptr1+1              ; 3a
    lda tmp6
    asl
    sta tmp7
    lda #0
    rol                     ; 2b hi
    cmp ptr1+1
    bcc @is2
    bne @not2
    lda tmp7
    cmp ptr1
    bcs @not2
@is2:
    lda #2
    jmp @quad
@not2:
    ; b < 5a ?
    lda tmp5
    sta ptr1
    lda #0
    sta ptr1+1
    asl ptr1
    rol ptr1+1
    asl ptr1
    rol ptr1+1
    clc
    lda ptr1
    adc tmp5
    sta ptr1
    lda ptr1+1
    adc #0
    sta ptr1+1              ; 5a
    bne @is3
    lda tmp6
    cmp ptr1
    bcs @is4
@is3:
    lda #3
    jmp @quad
@is4:
    lda #4
@quad:
    ; quadrant
    sta tmp7
    lda tmp0
    bmi @uneg
    lda tmp1
    bmi @q4
    lda tmp7                ; du>=0, dv>=0 : k
    rts
@q4:
    lda #16                 ; du>=0, dv<0 : 16-k
    sec
    sbc tmp7
    and #15
    rts
@uneg:
    lda tmp1
    bmi @q3
    lda #8                  ; du<0, dv>=0 : 8-k
    sec
    sbc tmp7
    rts
@q3:
    lda #8                  ; du<0, dv<0 : 8+k
    clc
    adc tmp7
    rts

ebullets_update:
    ldx #MAX_EB-1
@l:
    lda eb_on,x
    beq @n
    clc
    lda eb_ulo,x
    adc eb_dulo,x
    sta eb_ulo,x
    lda eb_u,x
    adc eb_duhi,x
    sta eb_u,x
    cmp #252
    bcs @kill
    cmp #2
    bcc @kill
    clc
    lda eb_vlo,x
    adc eb_dvlo,x
    sta eb_vlo,x
    lda eb_v,x
    adc eb_dvhi,x
    sta eb_v,x
    ldy orient
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
    sta eb_on,x
    beq @n

; -----------------------------------------------------------------------------
; Explosions : tmp0 = u, tmp1 = v. Preserve X.
; -----------------------------------------------------------------------------
fx_spawn:
    stx tmp7
    ldx #MAX_FX-1
@f:
    lda fx_t,x
    beq @ok
    dex
    bpl @f
    ldx tmp7
    rts
@ok:
    lda #1
    sta fx_t,x
    lda tmp0
    sta fx_u,x
    lda tmp1
    sta fx_v,x
    ldx tmp7
    rts

fx_update:
    ldx #MAX_FX-1
@l:
    lda fx_t,x
    beq @n
    inc fx_t,x
    lda fx_t,x
    cmp #24
    bcc @mv
    lda #0
    sta fx_t,x
    beq @n
@mv:
    lda scroll_on
    beq @n
    dec fx_u,x              ; les debris suivent le decor
@n:
    dex
    bpl @l
    rts

; -----------------------------------------------------------------------------
; Capsules d'amelioration : tmp0 = u, tmp1 = v. Preserve X.
; -----------------------------------------------------------------------------
item_spawn:
    stx tmp7
    ldx #MAX_IT-1
@f:
    lda it_on,x
    beq @ok
    dex
    bpl @f
    ldx tmp7
    rts
@ok:
    lda #1
    sta it_on,x
    lda tmp0
    clc
    adc #4
    sta it_u,x
    lda tmp1
    clc
    adc #4
    sta it_v,x
    lda #0
    sta it_ulo,x
    sta it_t,x
    ldx tmp7
    rts

items_update:
    ldx #MAX_IT-1
@l:
    lda it_on,x
    beq @n
    inc it_t,x
    lda it_ulo,x            ; recule a 0.75 px/image
    sec
    sbc #$C0
    sta it_ulo,x
    lda it_u,x
    sbc #0
    sta it_u,x
    cmp #4
    bcs @n
    lda #0
    sta it_on,x
@n:
    dex
    bpl @l
    rts

; -----------------------------------------------------------------------------
; Degats a l'ennemi X : A = degats, tmp6 = joueur auteur (pour les capsules)
; -----------------------------------------------------------------------------
enemy_damage:
    sta tmp5
    lda en_type,x           ; emetteur cristallin ferme : invulnerable
    cmp #EN_CRYSTAL
    bne @vuln
    lda en_st,x
    beq @vuln
    rts
@vuln:
    lda en_hp,x
    sec
    sbc tmp5
    bcc @dead
    beq @dead
    sta en_hp,x
    lda #4
    sta en_flash,x
    lda #SFX_HIT
    jmp sfx_play
@dead:
    lda en_type,x
    pha
    tay
    lda en_score_tbl,y
    jsr add_score_hundreds
    pla
    tay
    lda en_gauge_tbl,y
    jsr gauge_add
    lda en_u,x
    sta tmp0
    lda en_v,x
    sta tmp1
    jsr fx_spawn
    lda en_type,x
    cmp #EN_FIGHTER
    beq @drop
    cmp #EN_POD
    bne @nodrop
    lda kills               ; un conteneur sur deux contient une capsule
    and #1
    bne @nodrop
@drop:
    jsr item_spawn
@nodrop:
    lda #0
    sta en_type,x
    inc kills
    lda #SFX_EXPLODE
    jmp sfx_play

; Ajoute A centaines de points au score (A < 10). Preserve X.
add_score_hundreds:
    ldy #3
; Ajoute A (0-9) au chiffre Y du score (0 = centaines de milliers). Preserve X.
add_score:
    clc
    adc score,y
@c:
    cmp #10
    bcc @st
    sbc #10                 ; C=1 ici
    sta score,y
    dey
    bmi @max
    lda score,y
    adc #0                  ; +1 (retenue)
    jmp @c
@st:
    sta score,y
    lda #1
    sta hud_dirty
    ; vie bonus tous les 20 000 points (max 9 vies)
    lda score
    asl
    sta ext_t
    asl
    asl
    clc
    adc ext_t
    adc score+1             ; dizaines de milliers (0-99)
    lsr                     ; / 2 -> paliers de 20 000
    cmp ext_done
    beq @r
    bcc @r
    sta ext_done
    lda lives
    cmp #9
    bcs @r
    inc lives
    lda #SFX_POWERUP
    jmp sfx_play
@r:
    rts
@max:
    ldy #5
    lda #9
@m:
    sta score,y
    dey
    bpl @m
    lda #1
    sta hud_dirty
    rts
