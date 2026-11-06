# Cartographie mémoire — Prototype Phase 1

Valeurs relevées dans `build/spatial.map` (ROM sha256 indiqué dans
RESULTATS_TESTS.md).

## Espace CPU

| Plage | Usage | Occupation |
|---|---|---|
| `$0000-$00FF` | Page zéro : temporaires, pointeurs, état global, audio | 80 / 256 octets |
| `$0100-$01FF` | Pile | — |
| `$0200-$02FF` | Copie de l'OAM (DMA à chaque image) | 256 octets |
| `$0300-$07FF` | Variables (`BSS`) : tampon VRAM, pools d'entités, audio, partie | 646 / 1280 octets |
| `$5FF0-$5FF1` | Marqueurs de profilage (non décodés par le MMC3) | — |
| `$6000-$7FFF` | PRG-RAM sur pile (sauvegarde) | 64 / 8192 octets |
| `$8000-$9FFF` | Banc R6 = banc du secteur courant (0 = secteur 1, 2 = secteur 2, 3 = secteur 3) : en-tête, carte, attributs, script, palettes | ≤ 6,6 / 8 Kio par secteur |
| `$A000-$BFFF` | Banc R7 = PRG 1 : musique, SFX, tables de périodes, directions, sinus | 2873 / 8192 octets |
| `$C000-$DFFF` | PRG 6 fixe : échantillon DPCM (273 o, aligné 64) + code de jeu | 8047 / 8192 octets (**98 %**) |
| `$E000-$FFFF` | PRG 7 fixe : démarrage, NMI, IRQ, audio, sauvegarde, titre, HUD, palettes/scripts, vecteurs | 3558 / 8192 octets |

Banc PRG 4 : secteur 4. Banc PRG 5 : libre (8 Kio). La ROM finale (256-512 Kio) donnera un banc
par secteur restant.

> Phase 2 : titre, HUD et données de niveau déplacés vers `$E000` ; le banc
> `$C000` est passé de 95 % à 74 %. Les secteurs suivants iront dans les
> bancs commutables 2 à 5.

## Page zéro (principales variables)

| Variables | Rôle |
|---|---|
| `nmi_count`, `nmi_ready`, `nmi_mode`, `render_on`, `lag_count`, `loop_nmi` | Synchronisation boucle / NMI |
| `tmp0`–`tmp7`, `ptr0`, `ptr1` | Temporaires (jamais utilisés par le code du NMI) |
| `pad`, `pad_prev`, `pad_new` | Manettes 1 et 2 |
| `region`, `pal_acc`, `snd_acc` | NTSC/PAL et compensation 6/5 |
| `state`, `state_t`, `orient`, `nplayers`, `solo_ship`, `stage` | Partie |
| `cam_lo/hi`, `scroll_on`, `vsy`, `vrow` | Défilement |
| `split_a/y/x/b`, `split_on` | Valeurs de l'IRQ de séparation |
| `oam_idx`, `oam_start`, `spr_left`, `d_*` | Construction de l'OAM |
| `script_ptr` | Curseur du script d'apparition |
| `au_ptr`, `au_note`, `sfx_tp`, `tbl_*` | Audio (réservés au NMI et à `sfx_play`) |

## Structures en RAM (`$0300+`)

Organisation en tableaux parallèles (une table par champ, indexée par X/Y) :

| Pool | Champs | Taille |
|---|---|---|
| `vbuf` | tampon VRAM | 128 |
| Joueurs ×2 | on, alive, pad, u, ulo, v, vlo, cool, wlv, invul, resp | 22 |
| Ennemis ×10 | type, hp, t, st, u/v (8.8), du/dv (8.8), flash, p0 | 140 |
| Projectiles ennemis ×16 | on, u/v (8.8), du/dv (8.8) | 144 |
| Projectiles joueurs ×16 | on (propriétaire), u, v, du, dv | 80 |
| Explosions ×8, capsules ×3 | — | 36 |
| Boss, coopération, faisceau ×8 | — | 30 |
| Score, records, menu, divers | — | ~40 |
| Audio | 4 canaux musique + 2 canaux SFX | ~35 |

## Sauvegarde (PRG-RAM `$6000`)

Deux copies identiques de 32 octets (`$6000` = A, `$6020` = B) :

| Octets | Contenu |
|---|---|
| 0-3 | Signature `SPTL` |
| 4 | Version (1) |
| 5-10 | Record solo (6 chiffres) |
| 11-16 | Record coopération |
| 17 | Déblocages (bit 0 réservé au mode Expert) |
| 18 | Somme des octets 4-17, XOR `$A5` |

Écriture : copie B puis copie A, PRG-RAM déverrouillée uniquement pendant
l'écriture. Lecture : A si valide, sinon B, sinon valeurs par défaut.

## CHR-ROM (8 Kio utiles, ×4)

| Table | Tuiles |
|---|---|
| Décor `$0000` | `$01-$11` décors des secteurs, `$20-$5F` police ASCII, `$60-$68` jauge LIEN, `$69-$71` barre du boss |
| Sprites `$1000` | `$01-$07` projectiles/capsule/faisceau, `$20-$5F` police, `$80-$BF` vaisseaux et ennemis (H puis V), `$B0-$BB` explosions, `$C0-$DF` boss (H puis V) |
