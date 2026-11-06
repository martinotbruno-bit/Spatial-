# Manuel du joueur — Prototype SPATIAL (Phase 1)

## Lancer le jeu

Ouvrir `dist/spatial.nes` dans un émulateur NES compatible
mapper 4 (MMC3), ou sur une cartouche flash compatible. Testé uniquement en
émulation à ce stade.

## Menu

- **HAUT / BAS** (ou SELECT) : choisir une ligne.
- **GAUCHE / DROITE** : changer la valeur.
  - JOUEURS : 1 ou 2.
  - VAISSEAU (solo) : LANCE ou ÉGIDE.
  - SECTEUR : les secteurs déjà atteints (sauvegardés) peuvent être rejoués :
    1 STATION (horizontal), 2 PLANÈTE (vertical), 3 CEINTURE (horizontal),
    4 LUMEN (vertical), 5 HADAR (horizontal).
  - NIVEAU : RECRUE, PILOTE (par défaut) ou VÉTÉRAN ; EXPERT apparaît
    après avoir terminé la campagne. Débutant ? Essayez ÉGIDE en RECRUE.
- **START** : lancer la partie.
- **A** (prototype) : **accès libre** à tous les secteurs pour la session,
  sans modifier la sauvegarde. Sans lui, un secteur n'est proposé qu'après
  avoir terminé le précédent.

## En vol

| Bouton | Action |
|---|---|
| Croix | Déplacement dans 8 directions |
| B (maintenu) | Tir automatique |
| A | Capacité du vaisseau (LANCE : Surcharge, ÉGIDE : Bouclier) ; pouvoir coopératif si la jauge LIEN est pleine |
| SELECT | Bombe (munitions limitées, affichées dans le HUD) |
| START | Pause |

- **LANCE** (manette 1) : rapide, tir concentré.
- **ÉGIDE** (manette 2) : plus lent, tir en éventail.
- Les deux vaisseaux peuvent se toucher sans se blesser.
- **Capsules** : leur lettre change toutes les secondes environ —
  **P** niveau d'arme +1, **L** laser perçant, **M** missiles à tête
  chercheuse, **B** bombe supplémentaire. Ramassez-les au bon moment !
  Une vie perdue fait perdre un niveau d'arme.
- **Vies** : réserve commune, selon le niveau (PILOTE : 7 en coopération,
  7 en solo) ; **une vie bonus à chaque relais et tous les 20 000 points** (max 9).

## La jauge LIEN

Elle se remplit en détruisant des ennemis et en **volant en formation**
(vaisseaux proches). Pleine, appuyez sur A :

- à deux : **Faisceau de Liaison** — un rayon relie les deux vaisseaux et
  détruit tout ce qui le traverse ; placez-vous de part et d'autre des
  ennemis pour les balayer ;
- si votre partenaire n'a plus de vie : **Transfert d'énergie**, il revient
  en jeu ;
- en solo : **Nova**, une onde de choc qui balaie l'écran.

## Salve synchronisée

À deux, appuyez sur B (tir) **en même temps** que votre partenaire (moins de
8 images d'écart) : les deux vaisseaux tirent une salve lourde. Une salve
par seconde au maximum.

## Entre les secteurs

Un texte raconte la mission (START pour passer). À la fin d'un secteur, les
vaisseaux quittent l'écran et un bilan s'affiche : cibles détruites et bonus
de 1000 points par vie restante.

## Relais et crédits

À mi-secteur, le message RELAI indique un point de reprise. Après un
GAME OVER, l'écran SUITE ? laisse 9 secondes : START relance au dernier
relais (3 crédits par partie, score remis à zéro).

## HUD

`SCORE` — `HI` (record du mode) — `VIES` / `LIEN` (jauge) — pour LANCE
puis ÉGIDE : type d'arme (S, L ou M), niveau, `*` et nombre de bombes —
icône de boss et sa barre d'énergie.

Les records sont sauvegardés dans la cartouche.
