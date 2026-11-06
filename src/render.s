; =============================================================================
; render.s - Construction de la table des sprites (OAM)
; Coordonnees "logiques" (u = axe d'avancee, v = axe lateral) converties en
; coordonnees ecran selon l'orientation du niveau :
;   horizontal : x = u,  y = v
;   vertical   : x = v,  y = (256 - taille) - u   (l'avant pointe vers le haut)
; Les sprites hors zone de jeu (HUD, bords) sont elimines tuile par tuile.
; L'ordre d'ecriture tourne chaque image (pas de 17 sprites) pour repartir
; le clignotement quand plus de 8 sprites partagent une ligne.
; =============================================================================

oam_begin:
    lda oam_start
    sta oam_idx
    clc
    adc #68
    sta oam_start
    lda #64
    sta spr_left
    rts

oam_end:
    lda spr_left
    beq @done
    ldy oam_idx
    tax
    lda #$FF
@l:
    sta $0200,y
    iny
    iny
    iny
    iny
    dex
    bne @l
    sty oam_idx
@done:
    rts

vbase_tbl: .byte 0, 248, 240, 0, 224

; Dessine un objet carre. Entrees : d_u, d_v, d_size (1/2/4), d_tile, d_attr.
; Preserve X.
draw_obj:
    lda spr_left
    bne @start
    rts
@start:
    lda d_size
    cmp #1
    bne @big
    jmp draw_small
@big:
    stx dsave_x
    lda orient
    bne @vert
    lda d_u
    sta d_xlo
    lda d_v
    sta d_ylo
    lda #0
    sta d_xhi
    sta d_yhi
    beq @go
@vert:
    lda d_v
    sta d_xlo
    lda #0
    sta d_xhi
    ldx d_size
    lda vbase_tbl,x
    sec
    sbc d_u
    sta d_ylo
    lda #0
    sbc #0
    sta d_yhi
@go:
    ; Chemin rapide 16x16 entierement visible (cas le plus frequent) :
    ; 4 entrees ecrites d'un bloc, sans boucle ni test par tuile.
    lda d_size
    cmp #2
    bne @gen
    lda spr_left
    cmp #4
    bcc @gen
    lda oam_idx             ; les 4 entrees ne doivent pas reboucler en fin
    cmp #$F1                ; d'OAM (l'ecriture deborderait sur $0300)
    bcs @gen
    lda d_yhi
    ora d_xhi
    bne @gen
    lda d_xlo
    cmp #248
    bcs @gen
    lda d_ylo
    cmp #32
    bcc @gen
    cmp #232
    bcs @gen
    ldy oam_idx
    sec
    sbc #1                  ; OAM : y - 1
    sta $0200,y
    sta $0204,y
    clc
    adc #8
    sta $0208,y
    sta $020C,y
    lda d_tile              ; tuiles < $FC : pas de retenue
    sta $0201,y
    clc
    adc #1
    sta $0205,y
    adc #1
    sta $0209,y
    adc #1
    sta $020D,y
    lda d_attr
    sta $0202,y
    sta $0206,y
    sta $020A,y
    sta $020E,y
    lda d_xlo               ; < 248 : pas de retenue
    sta $0203,y
    sta $020B,y
    clc
    adc #8
    sta $0207,y
    sta $020F,y
    tya
    clc
    adc #16
    sta oam_idx
    lda spr_left
    sec
    sbc #4
    sta spr_left
    ldx dsave_x
    rts
@gen:
    lda d_tile
    sta tmp6
    lda d_size
    sta tmp4
    ldy oam_idx
@row:
    lda d_yhi
    bne @skiprow
    lda d_ylo
    cmp #32
    bcc @skiprow
    cmp #240
    bcs @skiprow
    lda d_xlo
    sta tmp7
    lda d_xhi
    sta tmp3
    ldx d_size
@col:
    lda tmp3
    bne @skipcol
    lda d_ylo
    sec
    sbc #1
    sta $0200,y
    lda tmp6
    sta $0201,y
    lda d_attr
    sta $0202,y
    lda tmp7
    sta $0203,y
    iny
    iny
    iny
    iny
    dec spr_left
    beq @full
@skipcol:
    inc tmp6
    lda tmp7
    clc
    adc #8
    sta tmp7
    lda tmp3
    adc #0
    sta tmp3
    dex
    bne @col
    jmp @nextrow
@skiprow:
    lda tmp6
    clc
    adc d_size
    sta tmp6
@nextrow:
    lda d_ylo
    clc
    adc #8
    sta d_ylo
    lda d_yhi
    adc #0
    sta d_yhi
    dec tmp4
    bne @row
@full:
    sty oam_idx
    ldx dsave_x
    rts

; Chemin rapide pour un objet 8x8 (projectiles, faisceau, capsules)
draw_small:
    lda orient
    bne @v
    lda d_v
    cmp #32
    bcc @r
    cmp #240
    bcs @r
    ldy oam_idx
    sbc #0                  ; C=0 ici : y - 1
    sta $0200,y
    lda d_u
    sta $0203,y
    jmp @w
@v:
    lda #248
    sec
    sbc d_u
    bcc @r
    cmp #32
    bcc @r
    cmp #240
    bcs @r
    ldy oam_idx
    sbc #0
    sta $0200,y
    lda d_v
    sta $0203,y
@w:
    lda d_tile
    sta $0201,y
    lda d_attr
    sta $0202,y
    iny
    iny
    iny
    iny
    sty oam_idx
    dec spr_left
@r:
    rts

; Texte en sprites : ptr0 = chaine (0 final), tmp0 = x, tmp1 = y ecran,
; d_attr = attributs. Les espaces ne consomment pas de sprite.
draw_text:
    ldy #0
@l:
    lda spr_left
    beq @d
    lda (ptr0),y
    beq @d
    cmp #' '
    beq @sp
    sty tmp2
    ldy oam_idx
    sta $0201,y
    lda tmp1
    sta $0200,y
    lda d_attr
    sta $0202,y
    lda tmp0
    sta $0203,y
    iny
    iny
    iny
    iny
    sty oam_idx
    dec spr_left
    ldy tmp2
@sp:
    lda tmp0
    clc
    adc #8
    sta tmp0
    iny
    bne @l
@d:
    rts

; -----------------------------------------------------------------------------
; Affichage d'une image de jeu
; -----------------------------------------------------------------------------
play_draw:
    jsr oam_begin
    jsr draw_message
    jsr draw_bilan
    jsr draw_players
    jsr draw_beam
    jsr draw_ebullets
    jsr draw_boss
    jsr draw_enemies
    jsr draw_items
    jsr draw_pbullets
    jsr draw_fx
    jsr oam_end
    jmp hud_update

draw_players:
    ldx #0
@l:
    lda pl_on,x
    beq @n
    lda pl_alive,x
    beq @n
    lda pl_invul,x
    beq @vis
    lda frame
    and #2
    bne @n                  ; clignotement d'invulnerabilite
@vis:
    lda pl_u,x
    sta d_u
    lda pl_v,x
    sta d_v
    lda #2
    sta d_size
    txa
    sta d_attr              ; palette 0 = LANCE, 1 = EGIDE
    lda orient              ; index = vaisseau*4 + orientation (0/1)
    ora ship_tile_sel,x
    tay
    lda ship_tiles,y
    sta d_tile
    jsr draw_obj
    cpx #1
    bne @n
    lda pl_abil_t+1
    beq @n
    ; bouclier frontal : 3 particules devant EGIDE
    lda #1
    sta d_size
    lda #S_BEAM_H
    sta d_tile
    lda pl_u+1
    clc
    adc #16
    sta d_u
    lda pl_v+1
    sec
    sbc #4
    sta d_v
    jsr draw_obj
    lda d_v
    clc
    adc #8
    sta d_v
    jsr draw_obj
    lda d_v
    clc
    adc #8
    sta d_v
    jsr draw_obj
@n:
    inx
    cpx #2
    bne @l
    rts

ship_tile_sel: .byte 0, 4
ship_tiles: .byte S_SHIP_A_H, S_SHIP_A_V, 0, 0, S_SHIP_B_H, S_SHIP_B_V

draw_ebullets:
    lda #1
    sta d_size
    lda #3
    sta d_attr
    lda #S_EBULLET_H
    sta d_tile
    ldx #MAX_EB-1
@l:
    lda eb_on,x
    beq @n
    lda eb_u,x
    sta d_u
    lda eb_v,x
    sta d_v
    jsr draw_obj
@n:
    dex
    bpl @l
    rts

draw_pbullets:
    lda #1
    sta d_size
    ldx #MAX_PB-1
@l:
    lda pb_on,x
    beq @n
    lda pb_u,x
    sta d_u
    lda pb_v,x
    sta d_v
    ldy pb_on,x
    dey
    tya
    sta d_attr
    asl
    ora orient
    tay
    lda shot_tiles,y
    sta d_tile
    cpy #4
    bcc @own
    lda #3                  ; salve synchronisee : palette blanc/orange
    sta d_attr
@own:
    jsr draw_obj
@n:
    dex
    bpl @l
    rts

shot_tiles: .byte S_SHOT_A_H, S_SHOT_A_V, S_SHOT_B_H, S_SHOT_B_V, S_BEAM_H, S_BEAM_H

draw_enemies:
    lda #2
    sta d_size
    ldx #MAX_EN-1
@l:
    lda en_type,x
    beq @n
    lda en_u,x
    sta d_u
    lda en_v,x
    sta d_v
    lda en_type,x
    asl
    ora orient
    tay
    lda enemy_tiles,y
    sta d_tile
    lda #2
    ldy en_flash,x
    beq @nf
    lda #3                  ; flash d'impact
@nf:
    sta d_attr
    jsr draw_obj
@n:
    dex
    bpl @l
    rts

enemy_tiles:
    .byte 0, 0
    .byte S_DRONE_H, S_DRONE_V
    .byte S_FIGHTER_H, S_FIGHTER_V
    .byte S_TURRET_H, S_TURRET_V
    .byte S_KAMIKAZE_H, S_KAMIKAZE_V
    .byte S_POD_H, S_POD_V
    .byte S_HEAVY_H, S_HEAVY_V

draw_fx:
    lda #2
    sta d_size
    lda #3
    sta d_attr
    ldx #MAX_FX-1
@l:
    lda fx_t,x
    beq @n
    lda fx_u,x
    sta d_u
    lda fx_v,x
    sta d_v
    lda fx_t,x
    lsr
    lsr
    lsr                     ; 0..2 (8 images par etape)
    tay
    lda fx_tiles,y
    sta d_tile
    jsr draw_obj
@n:
    dex
    bpl @l
    rts

fx_tiles: .byte S_EXPLO1_H, S_EXPLO2_H, S_EXPLO3_H, S_EXPLO3_H

draw_items:
    lda #1
    sta d_size
    lda #1
    sta d_attr
    lda #S_CAPSULE_H
    sta d_tile
    ldx #MAX_IT-1
@l:
    lda it_on,x
    beq @n
    lda frame
    and #8
    beq @c
    lda #0
    sta d_attr
    beq @d
@c:
    lda #1
    sta d_attr
@d:
    lda it_u,x
    sta d_u
    lda it_v,x
    sta d_v
    jsr draw_obj
@n:
    dex
    bpl @l
    rts

draw_beam:
    lda beam_t
    beq @r
    lda #1
    sta d_size
    lda frame
    and #1
    sta d_attr
    lda #S_BEAM_H
    sta d_tile
    ldx #BEAM_PTS-1
@l:
    lda beam_u,x
    sec
    sbc #4
    sta d_u
    lda beam_v,x
    sec
    sbc #4
    sta d_v
    jsr draw_obj
    dex
    bpl @l
@r:
    rts

draw_boss:
    lda boss_on
    beq @r
    lda boss_u
    sta d_u
    lda boss_v
    sta d_v
    lda #4
    sta d_size
    lda #S_BOSS_H
    ldy orient
    beq @h
    lda #S_BOSS_V
@h:
    sta d_tile
    lda #2
    ldy boss_flash
    beq @nf
    lda #3
@nf:
    sta d_attr
    jmp draw_obj
@r:
    rts

; Message central (READY, PAUSE, ...) sur deux lignes de 5 caracteres max.
draw_message:
    lda msg_t
    beq @r
    lda msg_id
    asl
    asl
    tax
    lda #3
    sta d_attr
    lda msg_tbl,x
    sta ptr0
    lda msg_tbl+1,x
    sta ptr0+1
    lda #108
    sta tmp0
    lda #112
    sta tmp1
    txa
    pha
    jsr draw_text
    pla
    tax
    lda msg_tbl+2,x
    sta ptr0
    lda msg_tbl+3,x
    sta ptr0+1
    beq @r
    lda #108
    sta tmp0
    lda #124
    sta tmp1
    jmp draw_text
@r:
    rts

MSG_READY = 0
MSG_PAUSE = 1
MSG_CLEAR = 2
MSG_OVER  = 3
MSG_WARN  = 4
MSG_END   = 5
MSG_CP    = 6
MSG_CONT  = 7
msg_tbl:
    .word str_ready, 0
    .word str_pause, 0
    .word str_stage, str_clear
    .word str_game, str_over
    .word str_alert, str_boss
    .word str_bravo, str_fin
    .word str_relai, 0
    .word str_suite, cont_buf
str_ready: .byte "PRET!", 0
str_pause: .byte "PAUSE", 0
str_stage: .byte "SECT.", 0
str_clear: .byte "LIBRE", 0
str_game:  .byte "GAME", 0
str_over:  .byte "OVER", 0
str_alert: .byte "ALERT", 0
str_boss:  .byte "BOSS!", 0
str_bravo: .byte "BRAVO", 0
str_fin:   .byte " FIN ", 0
str_relai: .byte "RELAI", 0
str_suite: .byte "SUITE?", 0
