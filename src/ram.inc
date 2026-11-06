; =============================================================================
; ram.inc - Cartographie de la memoire de travail (voir docs/MEMOIRE.md)
; =============================================================================

.segment "ZEROPAGE"
nmi_count:   .res 1     ; incremente a chaque NMI
nmi_ready:   .res 1     ; 1 = OAM et tampon VRAM prets pour le prochain NMI
nmi_mode:    .res 1     ; 0 = NMI minimal (detection region), 1 = complet
render_on:   .res 1     ; 1 = affichage actif (le NMI ecrit le defilement)
lag_count:   .res 1     ; images ou la logique n'a pas fini a temps
loop_nmi:    .res 1
frame:       .res 1
tmp0:        .res 1
tmp1:        .res 1
tmp2:        .res 1
tmp3:        .res 1
tmp4:        .res 1
tmp5:        .res 1
tmp6:        .res 1
tmp7:        .res 1
ptr0:        .res 2
ptr1:        .res 2
pad:         .res 2     ; etat des manettes 1 et 2
pad_prev:    .res 2
pad_new:     .res 2     ; boutons nouvellement presses
region:      .res 1     ; 0 = NTSC 60 Hz, 1 = PAL/Dendy 50 Hz
pal_acc:     .res 1     ; compteur 0-4 pour la compensation 6/5 en PAL
snd_acc:     .res 1
state:       .res 1
state_t:     .res 2
orient:      .res 1     ; 0 = niveau horizontal, 1 = niveau vertical
nplayers:    .res 1
solo_ship:   .res 1     ; 0 = LANCE, 1 = EGIDE (mode solo)
stage:       .res 1
cam_lo:      .res 1     ; progression du defilement en pixels (16 bits)
cam_hi:      .res 1
scroll_on:   .res 1
vsy:         .res 1     ; defilement vertical : Y dans la table de noms (0-239)
vrow:        .res 1     ; prochaine rangee de table de noms a ecrire (0-29)
split_on:    .res 1
split_a:     .res 1     ; valeurs ecrites par l'IRQ ($2006,$2005,$2005,$2006)
split_y:     .res 1
split_x:     .res 1
split_b:     .res 1
ctrl_shadow: .res 1
mask_shadow: .res 1
oam_idx:     .res 1
oam_start:   .res 1
spr_left:    .res 1
rng:         .res 2
vbuf_len:    .res 1
script_ptr:  .res 2
; parametres du dessin de metasprite
d_xlo:       .res 1
d_xhi:       .res 1
d_ylo:       .res 1
d_yhi:       .res 1
d_tile:      .res 1
d_attr:      .res 1
d_size:      .res 1     ; cote en tuiles (1, 2 ou 4)
d_u:         .res 1
d_v:         .res 1
dsave_x:     .res 1
; audio
au_ptr:      .res 2
au_note:     .res 1
sfx_tp:      .res 4
tbl_plo:     .res 2
tbl_phi:     .res 2
tbl_tlo:     .res 2
tbl_thi:     .res 2

.segment "BSS"
vbuf:        .res 128   ; tampon de mises a jour VRAM pour le NMI

; --- joueurs (index 0 = LANCE, 1 = EGIDE) ---
pl_on:       .res 2     ; vaisseau engage dans la partie
pl_alive:    .res 2
pl_pad:      .res 2     ; manette qui pilote ce vaisseau
pl_u:        .res 2
pl_ulo:      .res 2
pl_v:        .res 2
pl_vlo:      .res 2
pl_cool:     .res 2
pl_wlv:      .res 2     ; niveau d'arme 1-3
pl_invul:    .res 2
pl_resp:     .res 2

; --- ennemis ---
en_type:     .res MAX_EN
en_hp:       .res MAX_EN
en_t:        .res MAX_EN
en_st:       .res MAX_EN
en_ulo:      .res MAX_EN
en_u:        .res MAX_EN
en_vlo:      .res MAX_EN
en_v:        .res MAX_EN
en_dulo:     .res MAX_EN
en_duhi:     .res MAX_EN
en_dvlo:     .res MAX_EN
en_dvhi:     .res MAX_EN
en_flash:    .res MAX_EN
en_p0:       .res MAX_EN

; --- projectiles ennemis ---
eb_on:       .res MAX_EB
eb_ulo:      .res MAX_EB
eb_u:        .res MAX_EB
eb_vlo:      .res MAX_EB
eb_v:        .res MAX_EB
eb_dulo:     .res MAX_EB
eb_duhi:     .res MAX_EB
eb_dvlo:     .res MAX_EB
eb_dvhi:     .res MAX_EB

; --- projectiles joueurs ---
pb_on:       .res MAX_PB    ; 0 = libre, 1 = LANCE, 2 = EGIDE
pb_u:        .res MAX_PB
pb_v:        .res MAX_PB
pb_du:       .res MAX_PB
pb_dv:       .res MAX_PB

; --- explosions ---
fx_t:        .res MAX_FX    ; 0 = libre, sinon age+1
fx_u:        .res MAX_FX
fx_v:        .res MAX_FX

; --- capsules ---
it_on:       .res MAX_IT
it_u:        .res MAX_IT
it_ulo:      .res MAX_IT
it_v:        .res MAX_IT

; --- boss ---
boss_on:     .res 1     ; 0 absent, 1 entree, 2 combat, 3 destruction
boss_hp:     .res 1
boss_u:      .res 1
boss_ulo:    .res 1
boss_v:      .res 1
boss_vlo:    .res 1
boss_t:      .res 1
boss_ph:     .res 1     ; phase angulaire de l'oscillation
boss_flash:  .res 1
boss_burst:  .res 1

; --- cooperation ---
gauge:       .res 1     ; ressource LIEN 0-64
gauge_tick:  .res 1
beam_t:      .res 1
nova_t:      .res 1
beam_u:      .res BEAM_PTS
beam_v:      .res BEAM_PTS

; --- partie ---
score:       .res 6     ; chiffres decimaux, poids fort en premier
lives:       .res 1
hud_dirty:   .res 1
scroll_du:   .res 1     ; vitesse de defilement (px/image), 0 pendant le boss
msg_t:       .res 1
msg_id:      .res 1
menu_sel:    .res 1
menu_dirty:  .res 1
sector_sel:  .res 1
hi_solo:     .res 6
hi_coop:     .res 6
kills:       .res 1
diff_bonus:  .res 1

; --- audio ---
mus_on:      .res 1
mus_ptr_lo:  .res 4
mus_ptr_hi:  .res 4
mus_st_lo:   .res 4
mus_st_hi:   .res 4
mus_dur:     .res 4
mus_vol:     .res 4
mus_env:     .res 4
mus_lasthi:  .res 2
sfx_left:    .res 2     ; 0 = pulse 2, 1 = bruit
sfx_plo:     .res 2
sfx_phi:     .res 2
sfx_lasthi:  .res 1

; --- sauvegarde (PRG-RAM sur pile, $6000-$7FFF) ---
.segment "SAVE"
save_a:      .res 32
save_b:      .res 32
