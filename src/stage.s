; =============================================================================
; stage.s - Niveaux : initialisation, defilement H/V, script d'apparition,
;           boucle de jeu et etats de fin (niveau libere, game over, fin).
; =============================================================================

; -----------------------------------------------------------------------------
; Demarrage d'une partie (nplayers, solo_ship et sector_sel deja choisis)
; -----------------------------------------------------------------------------
game_start:
    ldx #5
    lda #0
@sc:
    sta score,x
    dex
    bpl @sc
    lda #0
    sta pl_on
    sta pl_on+1
    sta gauge
    lda #1
    sta pl_wlv
    sta pl_wlv+1
    lda nplayers
    cmp #2
    bne @solo
    lda #1
    sta pl_on
    sta pl_on+1
    lda #0
    sta pl_pad
    lda #1
    sta pl_pad+1
    lda #LIVES_COOP
    sta lives
    jmp @go
@solo:
    ldx solo_ship
    lda #1
    sta pl_on,x
    lda #0
    sta pl_pad,x
    lda #LIVES_SOLO
    sta lives
@go:
    lda sector_sel
    sta stage
    jmp stage_start

; -----------------------------------------------------------------------------
; Initialisation d'un niveau (ecran coupe pendant le chargement)
; -----------------------------------------------------------------------------
stage_start:
    jsr ppu_off
    jsr clear_entities
    lda #0
    sta cam_lo
    sta cam_hi
    sta boss_on
    sta beam_t
    sta nova_t
    sta kills
    lda #1
    sta scroll_du
    sta scroll_on
    ldx stage
    lda stage_orient,x
    sta orient
    ; Miroir vertical pour les deux orientations : HUD en $2000 (table A),
    ; zone de jeu en $2000/$2400 (H) ou en $2400 seule (V). En V, le passage
    ; de la rangee 29 a 0 bascule vers $2C00, miroir de $2400 : la boucle de
    ; 30 rangees reste dans la table B sans jamais toucher au HUD.
    lda #0
    sta MMC3_MIRROR
    lda stage_script_lo,x
    sta script_ptr
    lda stage_script_hi,x
    sta script_ptr+1
    lda stage_pal_lo,x
    sta ptr0
    lda stage_pal_hi,x
    sta ptr0+1
    jsr load_palette
    jsr clear_nametables
    jsr hud_init
    jsr place_players
    lda orient
    bne @v
    ; --- horizontal : 33 colonnes initiales ---
    lda #0
    sta tmp5
@hc:
    lda tmp5
    jsr build_column_h
    jsr flush_vbuf_direct
    inc tmp5
    lda tmp5
    cmp #33
    bne @hc
    jmp @done
@v:
    ; --- vertical : 30 rangees initiales, defilement Y = 32 ---
    lda #32
    sta vsy
    lda #0
    sta tmp5
@vr:
    lda tmp5                ; rangee de carte r -> rangee de table (29 - r)
    sta tmp4
    lda #29
    sec
    sbc tmp5
    jsr build_row_v
    jsr flush_vbuf_direct
    inc tmp5
    lda tmp5
    cmp #30
    bne @vr
    lda #29                 ; prochaine rangee a remplir : 29 - 30 mod 30 = 29
    sta vrow
@done:
    jsr update_split
    lda #1
    sta split_on
    lda #MSG_READY
    sta msg_id
    lda #90
    sta msg_t
    lda #SONG_STAGE
    jsr play_song
    lda #ST_PLAY
    sta state
    jmp ppu_on

stage_orient:    .byte 0, 1
stage_script_lo: .byte <script_h, <script_v
stage_script_hi: .byte >script_h, >script_v
stage_pal_lo:    .byte <pal_stage_h, <pal_stage_v
stage_pal_hi:    .byte >pal_stage_h, >pal_stage_v

; Position de depart des vaisseaux
place_players:
    ldx #1
@l:
    lda #0
    sta pl_alive,x
    sta pl_abil_t,x
    sta pl_abil_cd,x
    sta pl_invul,x
    sta pl_cool,x
    sta pl_ulo,x
    sta pl_vlo,x
    lda pl_on,x
    beq @n
    lda #1
    sta pl_alive,x
    lda #60
    sta pl_invul,x
    ldy orient
    lda start_u,y
    sta pl_u,x
    txa
    asl
    ora orient
    tay
    lda nplayers
    cmp #2
    beq @coop
    lda start_v_solo,y
    jmp @sv
@coop:
    lda start_v_coop,y
@sv:
    sta pl_v,x
@n:
    dex
    bpl @l
    rts

start_u:      .byte 32, 40
;                    A-H  A-V  B-H  B-V
start_v_coop: .byte 96,  80,  144, 144
start_v_solo: .byte 120, 112, 120, 112

clear_entities:
    lda #0
    ldx #MAX_EN-1
@e:
    sta en_type,x
    dex
    bpl @e
    ldx #MAX_EB-1
@b:
    sta eb_on,x
    sta pb_on,x
    dex
    bpl @b
    ldx #MAX_FX-1
@f:
    sta fx_t,x
    dex
    bpl @f
    ldx #MAX_IT-1
@i:
    sta it_on,x
    dex
    bpl @i
    rts

; Ecrit immediatement le tampon VRAM (ecran coupe) puis le vide
flush_vbuf_direct:
    ldx #0
@loop:
    lda vbuf,x
    beq @done
    inx
    tay
    lda #CTRL_BASE & $7F
    cpy #$80
    bcc @i1
    ora #CTRL_INC32
@i1:
    sta PPUCTRL
    tya
    and #$7F
    tay
    lda vbuf,x
    sta PPUADDR
    inx
    lda vbuf,x
    sta PPUADDR
    inx
@c:
    lda vbuf,x
    sta PPUDATA
    inx
    dey
    bne @c
    beq @loop
@done:
    lda #0
    sta vbuf
    sta vbuf_len
    lda #CTRL_BASE & $7F
    sta PPUCTRL
    rts

; -----------------------------------------------------------------------------
; Defilement horizontal : construit la colonne de carte A (0-255) dans le
; tampon VRAM. Colonne de table = A mod 64 (tables $2000 | $2400), rangees 4-29.
; -----------------------------------------------------------------------------
build_column_h:
    sta tmp0                ; colonne de carte
    ; gabarit
    tay
.if MAP_H_LEN < 256
    cpy #MAP_H_LEN
    bcc @in
    ldy #MAP_H_LEN-1
@in:
.endif
    lda map_h_ids,y
    tay
    lda map_h_tpl_lo,y
    sta ptr0
    lda map_h_tpl_hi,y
    sta ptr0+1
    ; adresse : $2000 + (col & 32 ? $400 : 0) + 4*32 + (col & 31)
    lda tmp0
    and #31
    clc
    adc #$80                ; rangee 4 = +$80
    sta ptr1
    lda tmp0
    and #32
    lsr
    lsr
    lsr                     ; 32 -> 4
    ora #$20
    sta ptr1+1
    lda #26 | $80
    jsr vbuf_open
    ldy #0
@c:
    lda (ptr0),y
    sta vbuf,x
    inx
    iny
    cpy #26
    bne @c
    jmp vbuf_close

; -----------------------------------------------------------------------------
; Defilement vertical : rangee de carte tmp4 vers la rangee de table A (0-29)
; de la table $2400.
; -----------------------------------------------------------------------------
build_row_v:
    sta tmp1
    ldy tmp4
    cpy #MAP_V_LEN
    bcc @in
    ldy #MAP_V_LEN-1
@in:
    lda map_v_ids,y
    tay
    lda map_v_tpl_lo,y
    sta ptr0
    lda map_v_tpl_hi,y
    sta ptr0+1
    ; adresse $2400 + rangee*32
    lda tmp1
    lsr
    lsr
    lsr
    ora #$24
    sta ptr1+1
    lda tmp1
    asl
    asl
    asl
    asl
    asl
    sta ptr1
    lda #32
    jsr vbuf_open
    ldy #0
@c:
    lda (ptr0),y
    sta vbuf,x
    inx
    iny
    cpy #32
    bne @c
    jmp vbuf_close

; Avance la camera de scroll_du pixels et diffuse les colonnes/rangees.
scroll_update:
    lda scroll_on
    beq @r
    lda scroll_du
    beq @r
    ; fin de niveau atteinte ?
    ldx orient
    lda cam_hi
    cmp cam_stop_hi,x
    bcc @adv
    lda cam_lo
    cmp cam_stop_lo,x
    bcc @adv
    lda #0
    sta scroll_on
@r:
    rts
@adv:
    inc cam_lo
    bne @nc
    inc cam_hi
@nc:
    lda cam_lo
    and #7
    bne @split
    lda orient
    bne @v
    ; colonne de carte (cam/8) + 32
    lda cam_hi
    sta tmp0
    lda cam_lo
    lsr tmp0
    ror
    lsr tmp0
    ror
    lsr tmp0
    ror
    clc
    adc #32
    jsr build_column_h
    jmp @split
@v:
    ; rangee de carte (cam/8) + 29 -> rangee de table vrow, puis vrow -= 1 mod 30
    lda cam_hi
    sta tmp0
    lda cam_lo
    lsr tmp0
    ror
    lsr tmp0
    ror
    lsr tmp0
    ror
    clc
    adc #29
    sta tmp4
    lda vrow
    jsr build_row_v
    dec vrow
    bpl @split
    lda #29
    sta vrow
@split:
    lda orient
    beq update_split
    ; vertical : Y diminue de 1 (mod 240)
    dec vsy
    lda vsy
    cmp #$FF
    bne update_split
    lda #239
    sta vsy
    ; continue
update_split:
    lda orient
    bne @v
    lda cam_lo
    sta split_x
    lda #32
    sta split_y
    lda cam_hi
    and #1
    jmp compute_split
@v:
    lda #0
    sta split_x
    lda vsy
    sta split_y
    lda #1
    jmp compute_split

cam_stop_lo: .byte <CAM_STOP_H, <CAM_STOP_V
cam_stop_hi: .byte >CAM_STOP_H, >CAM_STOP_V

; -----------------------------------------------------------------------------
; Script d'apparition : entrees [declencheur (cam/8), type, v, parametre]
; terminees par $FF.
; -----------------------------------------------------------------------------
script_update:
    lda cam_hi
    sta tmp0
    lda cam_lo
    lsr tmp0
    ror
    lsr tmp0
    ror
    lsr tmp0
    ror
    sta tmp1                ; position courante en unites de 8 px
@next:
    ldy #0
    lda (script_ptr),y
    cmp #$FF
    beq @r
    cmp tmp1
    beq @spawn
    bcs @r
@spawn:
    iny
    lda (script_ptr),y
    sta tmp2                ; type
    iny
    lda (script_ptr),y
    sta tmp3                ; v
    iny
    lda (script_ptr),y
    sta tmp4                ; parametre
    lda tmp2
    cmp #EN_BOSS
    bne @en
    jsr boss_spawn
    jmp @adv
@en:
    jsr enemy_spawn
@adv:
    clc
    lda script_ptr
    adc #4
    sta script_ptr
    lda script_ptr+1
    adc #0
    sta script_ptr+1
    jmp @next
@r:
    rts

; -----------------------------------------------------------------------------
; Etat JEU
; -----------------------------------------------------------------------------
play_update:
    ; pause : START de l'une ou l'autre manette
    lda pad_new
    ora pad_new+1
    and #BTN_START
    beq @nopause
    lda msg_id
    cmp #MSG_PAUSE
    bne @setpause
    lda msg_t
    beq @setpause
    lda #0
    sta msg_t
    jmp @nopause
@setpause:
    lda #MSG_PAUSE
    sta msg_id
    lda #255
    sta msg_t
    lda #SFX_MENU
    jsr sfx_play
    rts
@nopause:
    lda msg_id
    cmp #MSG_PAUSE
    bne @run
    lda msg_t
    beq @run
    rts                     ; en pause
@run:
    lda msg_t
    beq @nomsg
    dec msg_t
@nomsg:
    jsr scroll_update
    jsr script_update
    jsr players_update
    jsr coop_update
    jsr pbullets_update
    jsr enemies_update
    jsr boss_update
    jsr ebullets_update
    jsr items_update
    jsr fx_update
    jsr collisions
    jsr check_game_over
    rts

check_game_over:
    lda lives
    bne @r
    ldx #1
@l:
    lda pl_on,x
    beq @n
    lda pl_alive,x
    bne @r
    lda pl_resp,x
    bne @r
@n:
    dex
    bpl @l
    ; plus aucun vaisseau ni vie
    lda #ST_OVER
    sta state
    lda #MSG_OVER
    sta msg_id
    lda #255
    sta msg_t
    lda #200
    sta state_t
    jsr stop_music
    jmp save_update_hi
@r:
    rts

; Etat NIVEAU LIBERE (le jeu continue de tourner sans ennemis)
clear_update:
    jsr players_update
    jsr pbullets_update
    jsr fx_update
    dec state_t
    bne @r
    lda stage
    cmp #1
    bcs @end
    inc stage
    jmp stage_start
@end:
    lda #ST_END
    sta state
    lda #MSG_END
    sta msg_id
    lda #255
    sta msg_t
    lda #240
    sta state_t
    jsr save_update_hi
@r:
    rts

over_update:
    jsr fx_update
    dec state_t
    bne @r
    jmp title_enter
@r:
    rts

end_update:
    jsr fx_update
    dec state_t
    bne @r
    jmp title_enter
@r:
    rts

; Appele par le boss detruit
stage_cleared:
    lda #ST_CLEAR
    sta state
    lda #MSG_CLEAR
    sta msg_id
    lda #255
    sta msg_t
    lda #240
    sta state_t
    ldx #MAX_EB-1
    lda #0
@b:
    sta eb_on,x
    dex
    bpl @b
    lda #SONG_CLEAR
    jmp play_song
