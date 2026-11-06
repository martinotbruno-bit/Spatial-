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
    sta ext_done
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
    lda #WT_BASE
    sta pl_wtype
    sta pl_wtype+1
    lda #BOMBS_START
    sta pl_bombs
    sta pl_bombs+1
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
    jmp @go
@solo:
    ldx solo_ship
    lda #1
    sta pl_on,x
    lda #0
    sta pl_pad,x
@go:
    jsr set_full_lives
    ; parametres de difficulte
    ldx diff
    lda diff_aim,x
    sta aim_speed
    lda diff_tmask,x
    sta turret_mask
    lda diff_bosshp,x
    sta boss_hp0
    lda diff_bossph2,x
    sta boss_ph2
    lda diff_fx3,x
    sta fighter_x3
    lda #CONTINUES
    sta continues
    lda sector_sel
    sta stage
    jmp story_enter         ; A = page = secteur de depart (0 = introduction)         ; page = secteur de depart (0 = introduction)

; -----------------------------------------------------------------------------
; Initialisation d'un niveau (ecran coupe pendant le chargement)
; -----------------------------------------------------------------------------
stage_start:
    jsr ppu_off
    jsr clear_entities
    lda cp_cam              ; depart au point de reprise (0 = debut)
    sta cam_lo
    lda cp_cam+1
    sta cam_hi
    lda #0
    sta boss_on
    sta beam_t
    sta nova_t
    sta sync_cd
    sta kills
    lda #1
    sta scroll_du
    sta scroll_on
    jsr sector_map          ; banc PRG + en-tete + bancs CHR du secteur
    lda sec_hdr+SH_ORIENT
    sta orient
    ; Miroir vertical pour les deux orientations : HUD en $2000 (table A),
    ; zone de jeu en $2000/$2400 (H) ou en $2400 seule (V). En V, le passage
    ; de la rangee 29 a 0 bascule vers $2C00, miroir de $2400 : la boucle de
    ; 30 rangees reste dans la table B sans jamais toucher au HUD.
    lda #0
    sta MMC3_MIRROR
    ; longueur totale du corps repete
    lda #0
    sta loop_total
    sta loop_total+1
    ldx sec_hdr+SH_REPS
@lt:
    clc
    lda loop_total
    adc sec_hdr+SH_LOOPL
    sta loop_total
    bcc @lt2
    inc loop_total+1
@lt2:
    dex
    bne @lt
    ; 1re entree du script situee dans le corps (rejouee a chaque passage)
    lda sec_hdr+SH_SCRIPT
    sta script_ptr
    lda sec_hdr+SH_SCRIPT+1
    sta script_ptr+1
    lda sec_hdr+SH_LOOPA
    jsr script_seek
    lda script_ptr
    sta sc_loop_ptr
    lda script_ptr+1
    sta sc_loop_ptr+1
    ; position de depart (point de reprise eventuel) et script correspondant
    lda #0
    jsr cam_pos
    lda map_p
    sta sp0
    lda map_p+1
    sta sp0+1
    jsr map_pos
    sta sc_last
    pha
    lda sec_hdr+SH_SCRIPT
    sta script_ptr
    lda sec_hdr+SH_SCRIPT+1
    sta script_ptr+1
    pla
    cmp sec_hdr+SH_LOOPA
    bcc @intro
    lda sc_loop_ptr         ; dans le corps ou la fin : on part du corps
    sta script_ptr
    lda sc_loop_ptr+1
    sta script_ptr+1
@intro:
    lda sc_last
    jsr script_seek
    lda sec_hdr+SH_PAL
    sta ptr0
    lda sec_hdr+SH_PAL+1
    sta ptr0+1
    jsr load_palette
    jsr clear_nametables
    ldx #63
    lda #0
@va:
    sta vattr_sh,x
    dex
    bpl @va
    jsr hud_init
    jsr place_players
    lda orient
    bne @v
    ; --- horizontal : 33 colonnes initiales a partir de la position de depart
    lda #33
    sta tmp7
    lda sp0
    sta map_p
    lda sp0+1
    sta map_p+1
@hc:
    lda map_p
    sta tmp0
    jsr map_pos
    jsr build_column_h
    jsr flush_vbuf_direct
    inc map_p
    bne @hc2
    inc map_p+1
@hc2:
    dec tmp7
    bne @hc
    jmp @done
@v:
    ; --- vertical : 30 rangees initiales a partir de c0 ---
    ; rangee de carte R -> rangee de table 29 - (R mod 30)
    ; Y de defilement = (32 - cam) mod 240
    lda cam_lo
    sta tmp0
    lda cam_hi
    sta tmp1
@m240:
    lda tmp1
    bne @sub
    lda tmp0
    cmp #240
    bcc @m_ok
@sub:
    sec
    lda tmp0
    sbc #240
    sta tmp0
    lda tmp1
    sbc #0
    sta tmp1
    jmp @m240
@m_ok:
    lda #32
    sec
    sbc tmp0
    bcs @vs
    adc #240
@vs:
    sta vsy
    lda #30
    sta tmp7
    lda sp0
    sta map_p
    lda sp0+1
    sta map_p+1
@vr:
    jsr map_pos
    sta tmp4                ; rangee de carte
    jsr mod30w
    eor #$FF
    sec
    adc #29                 ; rangee de table : 29 - (R mod 30)
    jsr build_row_v
    jsr flush_vbuf_direct
    inc map_p
    bne @vr2
    inc map_p+1
@vr2:
    dec tmp7
    bne @vr
    lda sp0                 ; prochaine rangee : 29 - (R0 mod 30)
    sta map_p
    lda sp0+1
    sta map_p+1
    jsr mod30w
    eor #$FF
    sec
    adc #29
    sta vrow
@done:
    jsr update_split
    lda #1
    sta split_on
    lda #MSG_READY
    sta msg_id
    lda #90
    sta msg_t
    lda sec_hdr+SH_SONG
    jsr play_song
    lda #ST_PLAY
    sta state
    jmp ppu_on

sector_bit: .byte 1, 2, 4, 8, 16, 32, 64, 128

; Reserve de vies pleine selon le mode et la difficulte
set_full_lives:
    ldx diff
    lda diff_lives_solo,x
    ldy nplayers
    cpy #2
    bne @s
    lda diff_lives_coop,x
@s:
    sta lives
    rts

; Tables de difficulte :        RECRUE PILOTE VETERAN EXPERT
; (revues a la baisse apres l'allongement des secteurs : voir EQUILIBRAGE.md)
diff_lives_solo: .byte          9,     7,     4,      2
diff_lives_coop: .byte          9,     7,     5,      3
diff_aim:        .byte          0,     0,     16,     16   ; vitesse des tirs vises
diff_tmask:      .byte          127,   127,   63,     31   ; periode des tourelles
diff_bosshp:     .byte          150,   200,   250,    250
diff_bossph2:    .byte          75,    100,   125,    170  ; seuil de la phase 2
; vie bonus au relais (sauf EXPERT)
diff_cp_life:    .byte          1,     1,     1,      0
diff_fx3:        .byte          0,     0,     1,      1    ; 3e tir des chasseurs

; -----------------------------------------------------------------------------
; Conversion position reelle -> index de carte (map_p 16 bits -> A).
; La carte = intro [0, A) jouee une fois, corps [A, A+L) joue SH_REPS fois,
; puis la fin [A+L, longueur) (arene du boss). A et L sont alignes sur les
; blocs d'attributs (4 colonnes / 2 rangees) par le generateur.
; -----------------------------------------------------------------------------
map_pos:
    lda map_p+1
    bne @body
    lda map_p
    cmp sec_hdr+SH_LOOPA
    bcs @body
    rts                     ; intro
@body:
    sec
    lda map_p
    sbc sec_hdr+SH_LOOPA
    sta mp_t
    lda map_p+1
    sbc #0
    sta mp_t+1              ; k = P - A
    lda mp_t+1
    cmp loop_total+1
    bcc @rep
    bne @tail
    lda mp_t
    cmp loop_total
    bcc @rep
@tail:
    sec                     ; fin : A + L + (k - total)
    lda mp_t
    sbc loop_total
    clc
    adc sec_hdr+SH_LOOPA
    clc
    adc sec_hdr+SH_LOOPL
    bcs @max
    cmp sec_hdr+SH_MAXIDX
    bcc @ok
@max:
    lda sec_hdr+SH_MAXIDX
@ok:
    rts
@rep:
    ; k mod L (soustractions successives, k < ~1100)
    lda mp_t+1
    bne @sub
    lda mp_t
    cmp sec_hdr+SH_LOOPL
    bcc @done
@sub:
    sec
    lda mp_t
    sbc sec_hdr+SH_LOOPL
    sta mp_t
    lda mp_t+1
    sbc #0
    sta mp_t+1
    jmp @rep
@done:
    clc
    adc sec_hdr+SH_LOOPA
    rts

; map_p = cam / 8 + A
cam_pos:
    sta map_p
    lda cam_hi
    sta map_p+1
    lda cam_lo
    lsr map_p+1
    ror
    lsr map_p+1
    ror
    lsr map_p+1
    ror
    clc
    adc map_p
    sta map_p
    bcc @r
    inc map_p+1
@r:
    rts

; A = map_p mod 30 (16 bits)
mod30w:
    lda map_p
    sta mp_t
    lda map_p+1
    sta mp_t+1
@l:
    lda mp_t+1
    bne @s
    lda mp_t
    cmp #30
    bcc @r
@s:
    sec
    lda mp_t
    sbc #30
    sta mp_t
    lda mp_t+1
    sbc #0
    sta mp_t+1
    jmp @l
@r:
    rts

; A = cam / 8 (camera < 2048)
cam_div8:
    lda cam_hi
    sta tmp0
    lda cam_lo
    lsr tmp0
    ror
    lsr tmp0
    ror
    lsr tmp0
    ror
    rts

; A = A mod 30
mod30:
    cmp #30
    bcc @r
    sbc #30
    jmp mod30
@r:
    rts

; -----------------------------------------------------------------------------
; Selection du secteur `stage` : banc PRG en $8000 (R6), copie de l'en-tete,
; pointeurs de carte en page zero, bancs CHR du decor (R1) et des sprites (R5).
; En-tete genere par tools/gen_assets.py (offsets SH_* dans defs.inc).
; -----------------------------------------------------------------------------
sector_map:
    ldx stage
    lda #6
    sta MMC3_BANKSEL
    lda sector_banks,x
    sta MMC3_BANKDATA
    ldy #SH_SIZE-1
@c:
    lda $8000,y
    sta sec_hdr,y
    dey
    bpl @c
    ldx #7
@p:
    lda sec_hdr+SH_IDS,x    ; ids, tlo, thi, attr -> m_ids..m_attr
    sta m_ids,x
    dex
    bpl @p
    lda #1
    sta MMC3_BANKSEL
    lda sec_hdr+SH_CHRBG
    sta MMC3_BANKDATA
    lda #5
    sta MMC3_BANKSEL
    lda sec_hdr+SH_CHRSPR
    sta MMC3_BANKDATA
    rts

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
    sta bc_map              ; index de carte ; tmp0 = colonne reelle (octet bas)
    ; gabarit
    tay
    cpy sec_hdr+SH_MAXIDX
    bcc @in
    ldy sec_hdr+SH_MAXIDX
@in:
    lda (m_ids),y
    tay
    lda (m_tlo),y
    sta ptr0
    lda (m_thi),y
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
    jsr vbuf_close
    ; tous les 4 colonnes : colonne d'attributs (7 octets, pas de 8 en VRAM)
    ; Ecrite avec la 1re colonne du groupe : les 3 suivantes sont encore hors
    ; champ, l'ancienne colonne recouverte (col - 64) l'est deja.
    lda tmp0
    and #3
    bne @r
    lda m_attr+1            ; secteur sans attributs : palette unique
    beq @r
    lda bc_map
    lsr
    lsr
    sta tmp1
    lda #0
    sta ptr0+1
    lda tmp1
    asl
    rol ptr0+1
    asl
    rol ptr0+1
    asl
    rol ptr0+1
    sec
    sbc tmp1
    sta ptr0
    lda ptr0+1
    sbc #0
    sta ptr0+1              ; groupe * 7
    clc
    lda ptr0
    adc m_attr
    sta ptr0
    lda ptr0+1
    adc m_attr+1
    sta ptr0+1
    lda tmp0
    and #32
    lsr
    lsr
    lsr
    ora #$23
    sta ptr1+1              ; $23C0 ou $27C0
    lda tmp0
    and #31
    lsr
    lsr
    clc
    adc #$C8                ; rangee d'attributs 1
    sta ptr1
    ldy #0
@a:
    lda #1
    jsr vbuf_open
    lda (ptr0),y
    sta vbuf,x
    inx
    jsr vbuf_close
    lda ptr1
    clc
    adc #8
    sta ptr1
    iny
    cpy #7
    bne @a
@r:
    rts

; -----------------------------------------------------------------------------
; Defilement vertical : rangee de carte tmp4 vers la rangee de table A (0-29)
; de la table $2400.
; -----------------------------------------------------------------------------
build_row_v:
    sta tmp1
    ldy tmp4
    cpy sec_hdr+SH_MAXIDX
    bcc @in
    ldy sec_hdr+SH_MAXIDX
@in:
    sty av_row
    lda (m_ids),y
    tay
    lda (m_tlo),y
    sta ptr0
    lda (m_thi),y
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
    jsr vbuf_close
    ; --- attributs (secteurs verticaux multi-palettes) ---
    ; Une paire de rangees de carte (2m, 2m+1) forme une rangee de blocs 16x16.
    ; Quand la 2e rangee (impaire) est ecrite, sa rangee de table n est paire :
    ; on met a jour la moitie haute (n mod 4 = 0) ou basse (n mod 4 = 2) de la
    ; rangee d'attributs n/4, dans une copie en RAM, puis on envoie ses 8 octets.
    lda m_attr+1
    beq @r0
    lda av_row
    and #1
    bne @go
@r0:
    rts
@go:
    lda av_row
    lsr
    sta ptr0
    lda #0
    sta ptr0+1
    asl ptr0
    rol ptr0+1
    asl ptr0
    rol ptr0+1              ; paire * 4
    clc
    lda ptr0
    adc m_attr
    sta ptr0
    lda ptr0+1
    adc m_attr+1
    sta ptr0+1
    lda tmp1
    and #$FC
    asl
    sta av_base             ; (n / 4) * 8
    lda tmp1
    and #2
    sta av_half             ; 0 = moitie haute, 2 = moitie basse
    ldx #0
@b:
    txa
    lsr
    tay
    lda (ptr0),y            ; 4 blocs par octet (2 bits chacun)
    sta av_tmp
    txa
    and #1
    beq @lo
    lda av_tmp
    lsr
    lsr
    lsr
    lsr
    sta av_tmp
@lo:
    lda av_tmp
    and #$0F                ; blocs 2c et 2c+1
    ldy av_half
    beq @top
    asl
    asl
    asl
    asl
    sta av_tmp
    txa
    clc
    adc av_base
    tay
    lda vattr_sh,y
    and #$0F
    ora av_tmp
    sta vattr_sh,y
    jmp @nx
@top:
    sta av_tmp
    txa
    clc
    adc av_base
    tay
    lda vattr_sh,y
    and #$F0
    ora av_tmp
    sta vattr_sh,y
@nx:
    inx
    cpx #8
    bne @b
    lda av_base
    clc
    adc #$C0
    sta ptr1
    lda #$27
    sta ptr1+1
    lda #8
    jsr vbuf_open
    ldy av_base
@w:
    lda vattr_sh,y
    sta vbuf,x
    inx
    iny
    tya
    and #7
    bne @w
    jmp vbuf_close
@r:
    rts

; Avance la camera de scroll_du pixels et diffuse les colonnes/rangees.
scroll_update:
    lda scroll_on
    beq @r
    lda scroll_du
    beq @r
    ; fin de niveau atteinte ?
    lda cam_hi
    cmp sec_hdr+SH_STOP+1
    bcc @adv
    lda cam_lo
    cmp sec_hdr+SH_STOP
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
    ; point de reprise
    lda cp_cam
    ora cp_cam+1
    bne @nocp
    lda cam_lo
    cmp sec_hdr+SH_CP
    bne @nocp
    lda cam_hi
    cmp sec_hdr+SH_CP+1
    bne @nocp
    sta cp_cam+1
    lda cam_lo
    sta cp_cam
    lda #MSG_CP
    sta msg_id
    lda #90
    sta msg_t
    lda #SFX_COOPREADY
    jsr sfx_play
    ldx diff                ; vie bonus au relais (max 9)
    lda diff_cp_life,x
    beq @nocp
    lda lives
    cmp #9
    bcs @nocp
    inc lives
    lda #1
    sta hud_dirty
@nocp:
    lda cam_lo
    and #7
    bne @split
    lda orient
    bne @v
    lda #32                 ; colonne reelle cam/8 + 32
    jsr cam_pos
    lda map_p
    sta tmp0
    jsr map_pos
    jsr build_column_h
    jmp @split
@v:
    ; rangee reelle cam/8 + 29 -> rangee de table vrow, puis vrow -= 1 mod 30
    lda #29
    jsr cam_pos
    jsr map_pos
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



; -----------------------------------------------------------------------------
; Script d'apparition : entrees [declencheur (cam/8), type, v, parametre]
; terminees par $FF.
; -----------------------------------------------------------------------------
; Avance le script jusqu'a la 1re entree de declencheur >= A
script_seek:
    sta tmp1
@l:
    ldy #0
    lda (script_ptr),y
    cmp #$FF
    beq @r
    cmp tmp1
    bcs @r
    clc
    lda script_ptr
    adc #4
    sta script_ptr
    bcc @l
    inc script_ptr+1
    bne @l
@r:
    rts

script_update:
    lda #0
    jsr cam_pos
    jsr map_pos
    sta tmp1                ; position courante dans la carte (unites de 8 px)
    cmp sc_last
    sta sc_last
    bcs @next
    lda sc_loop_ptr         ; nouveau passage dans le corps : vagues rejouees
    sta script_ptr
    lda sc_loop_ptr+1
    sta script_ptr+1
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
; Etat NIVEAU LIBERE : 300 images
;   250-231 : message "SECT. LIBRE", les vaisseaux restent en place
;   230-191 : les vaisseaux quittent l'ecran par l'avant (6 px/image)
;   190-0   : bilan (cibles, vies, bonus de 1000 points par vie a 170)
clear_update:
    lda msg_t
    beq @nm
    dec msg_t
@nm:
    jsr players_update
    jsr pbullets_update
    jsr fx_update
    lda state_t
    cmp #230
    bcs @nofly
    ldx #1
@fly:
    lda pl_alive,x
    beq @nf
    lda pl_u,x
    clc
    adc #6
    bcs @out
    sta pl_u,x
    cmp #236
    bcc @nf
@out:
    lda #0
    sta pl_alive,x
    beq @nf
    cmp #236
    bcc @nf
    lda #0
    sta pl_alive,x
@nf:
    dex
    bpl @fly
@nofly:
    lda state_t
    cmp #170
    bne @nobonus
    lda lives
    beq @nobonus
    cmp #10
    bcc @lv
    lda #9
@lv:
    ldy #2                  ; milliers
    jsr add_score
    lda #SFX_POWERUP
    jsr sfx_play
@nobonus:
    dec state_t
    bne @r
    jsr save_update_hi
    lda stage
    clc
    adc #1
    cmp #NUM_SECTORS
    bcs @end
    sta stage
    tax                     ; secteur suivant debloque (sauvegarde)
    lda sector_bit,x
    ora sectors_unl
    cmp sectors_unl
    beq @known
    sta sectors_unl
    jsr save_write
@known:
    lda stage
    jmp story_enter
@end:
    lda #NUM_SECTORS        ; epilogue
    jmp story_enter
@r:
    rts

; GAME OVER (200 images) puis, s'il reste des credits, compte a rebours
over_update:
    jsr fx_update
    dec state_t
    bne @r
    lda continues
    bne @cont
    jmp title_enter
@cont:
    lda #ST_CONT
    sta state
    lda #9
    sta cont_digit
    lda #60
    sta cont_t
    lda #MSG_CONT
    sta msg_id
    lda #255
    sta msg_t
    jmp cont_text
@r:
    rts

; CONTINUER ? : START relance au dernier point de reprise
cont_update:
    lda #255
    sta msg_t
    lda pad_new
    ora pad_new+1
    and #BTN_START
    bne continue_game
    dec cont_t
    bne @r
    lda #60
    sta cont_t
    lda #SFX_MENU
    jsr sfx_play
    dec cont_digit
    bpl cont_text
    jmp title_enter
@r:
    rts

cont_text:
    lda #' '
    sta cont_buf
    lda cont_digit
    ora #'0'
    sta cont_buf+1
    lda #' '
    sta cont_buf+2
    lda #0
    sta cont_buf+3
    rts

continue_game:
    dec continues
    ldx #5
    lda #0
    sta ext_done
@s:
    sta score,x             ; le score repart de zero (record deja enregistre)
    dex
    bpl @s
    sta gauge
    lda #1
    sta pl_wlv
    sta pl_wlv+1
    lda #WT_BASE
    sta pl_wtype
    sta pl_wtype+1
    lda #BOMBS_START
    sta pl_bombs
    sta pl_bombs+1
    jsr set_full_lives
    lda #SFX_MENU
    jsr sfx_play
    jmp stage_start

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
    lda #30
    sta msg_t
    lda #250
    sta state_t
    jsr bilan_build
    ldx #MAX_EB-1
    lda #0
@b:
    sta eb_on,x
    dex
    bpl @b
    lda #SONG_CLEAR
    jmp play_song
