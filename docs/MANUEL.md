# Manuel du joueur — Prototype SPATIAL (Phase 1)

## Lancer le jeu

Ouvrir `dist/spatial-proto-phase1.nes` dans un émulateur NES compatible
mapper 4 (MMC3), ou sur une cartouche flash compatible. Testé uniquement en
émulation à ce stade.

## Menu

- **HAUT / BAS** (ou SELECT) : choisir une ligne.
- **GAUCHE / DROITE** : changer la valeur.
  - JOUEURS : 1 ou 2.
  - VAISSEAU (solo) : LANCE ou ÉGIDE.
  - SECTEUR : 1 STATION (horizontal) ou 2 PLANÈTE (vertical).
- **START** : lancer la partie.

## En vol

| Bouton | Action |
|---|---|
| Croix | Déplacement dans 8 directions |
| A (maintenu) | Tir automatique |
| B | Capacité du vaisseau (LANCE : Surcharge, ÉGIDE : Bouclier) ; pouvoir coopératif si la jauge LIEN est pleine |
| START | Pause |

- **LANCE** (manette 1) : rapide, tir concentré.
- **ÉGIDE** (manette 2) : plus lent, tir en éventail.
- Les deux vaisseaux peuvent se toucher sans se blesser.
- **Capsule P** (lâchée par les chasseurs) : arme +1 niveau (max 3).
  Une vie perdue fait perdre un niveau.
- **Vies** : réserve commune (5 en coopération, 3 en solo).

## La jauge LIEN

Elle se remplit en détruisant des ennemis et en **volant en formation**
(vaisseaux proches). Pleine, appuyez sur B :

- à deux : **Faisceau de Liaison** — un rayon relie les deux vaisseaux et
  détruit tout ce qui le traverse ; placez-vous de part et d'autre des
  ennemis pour les balayer ;
- si votre partenaire n'a plus de vie : **Transfert d'énergie**, il revient
  en jeu ;
- en solo : **Nova**, une onde de choc qui balaie l'écran.

## HUD

`SCORE` — `HI` (record du mode) — `VIES` / `LIEN` (jauge) — `A:` `B:`
(niveau d'arme de LANCE et ÉGIDE) — `BOSS` (énergie du mini-boss).

Les records sont sauvegardés dans la cartouche.
