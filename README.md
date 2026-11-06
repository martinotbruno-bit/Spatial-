# Projet SPATIAL — Shoot'em up spatial coopératif pour NES

Jeu original pour Nintendo Entertainment System d'origine, réalisé selon le
[cahier des charges maître](Cdc%20spatial.md).

> **État : campagne complète jouable (8 secteurs, 2 fins), testée en émulation.**
> Restent : finition, fabrication de la cartouche et tests sur matériel réel. Aucun test sur matériel réel n'a été effectué : voir
> [docs/CONFORMITE.md](docs/CONFORMITE.md) pour l'état exact de chaque exigence.

![Planche de captures (émulation)](docs/captures/planche.png)

## Contenu du prototype

- ROM NES MMC3 (TKROM), 256 Kio de PRG + 32 Kio de CHR : `dist/spatial.nes`
- Coopération à 2 joueurs simultanés (2 manettes) **et** mode solo complet
- Deux vaisseaux différents : **LANCE** (intercepteur rapide, tir concentré)
  et **ÉGIDE** (vaisseau lourd, tir en éventail)
- Arsenal : arme d'origine, **laser perçant**, **missiles à tête
  chercheuse** (3 niveaux chacun), **bombes** (SELECT), capsules
  changeantes P / L / M / B
- Capacités propres : **Surcharge** (LANCE, esquive rapide) et **Bouclier
  frontal** (ÉGIDE, absorbe 4 projectiles)
- Collisions physiques entre joueurs, sans dégâts ni blocage
- **Salve synchronisée** : les deux pilotes appuient sur B (tir) ensemble
- Séquences narratives entre les secteurs, écran de bilan de fin de secteur
- Ressource coopérative **LIEN** et trois pouvoirs : **Faisceau de Liaison**
  (attaque combinée dépendant du placement des deux vaisseaux),
  **Transfert d'énergie** (ramène un partenaire sans vie), **Nova** (solo)
- **Campagne complète de 8 secteurs** : **Station Vesta** (horizontal, 3 palettes, conteneurs
  destructibles), **Surface de Kéra** (vertical), **Ceinture brisée**
  (horizontal, astéroïdes, unités lourdes, boss Essaim-mère), **Cité de
  Lumen** (vertical, appareils de soutien, boss Garde-ciel), **Chantiers
  d'Hadar** (horizontal, poseurs de mines, croiseur à tourelles destructibles),
  **Premier Ancrage** (vertical, émetteurs cristallins, Gardien d'Ancrage),
  **Front de la Concordance** (horizontal, Amiral-machine), **Cœur du Lien**
  (horizontal, boss final la Concordance en 3 phases)
- **Encyclopédie** (19 fiches découvertes en jeu) et **classements** solo et
  coop (5 entrées), sauvegardés dans la cartouche
- **Deux fins** : *Fin de Liaison* (campagne terminée sans « Continuer ») ou
  *Fin de Rupture*
- Secteurs débloqués sauvegardés et rejouables, secteur 2 en **défilement vertical**,
  HUD fixe par séparation d'écran (IRQ de ligne MMC3)
- 4 familles d'ennemis (drones, chasseurs, tourelles, kamikazes), tirs visés
  sur 16 directions, mini-boss à 2 phases
- Moteur audio sur les 5 canaux (2 pulse, triangle, bruit, DPCM),
  5 musiques originales (écoute : `docs/audio/`), instruments à
  enveloppes, 15 effets sonores
- Point de reprise à mi-secteur et 3 crédits « CONTINUER »
- 3 difficultés + mode EXPERT à débloquer, équilibrage mesuré par un pilote
  automatique ([docs/EQUILIBRAGE.md](docs/EQUILIBRAGE.md))
- Sprites dédiés « vue de dessus » pour les niveaux verticaux
- Sauvegarde des records sur PRG-RAM à pile (double copie + somme de contrôle)
- Détection NTSC/PAL et compensation de cadence 6/5 en 50 Hz

## Compiler

Prérequis : `cc65` (ca65/ld65 ≥ 2.18), Python 3, et Node.js ≥ 18 pour les tests.

```sh
make          # build/spatial.nes (+ carte mémoire et symboles)
make dist     # copie la ROM dans dist/
make test     # suite de tests automatisés en émulation (jsnes)
```

La compilation est reproductible (test T22 : deux constructions identiques
octet pour octet).

## Commandes

| Action | Manette |
|---|---|
| Déplacement 8 directions | Croix |
| Tir (maintenu) | B |
| Capacité du vaisseau / pouvoir coopératif (jauge LIEN pleine) | A |
| Pause | START |
| Menu : ligne / valeur / départ | Haut-Bas / Gauche-Droite / START |
| Bombe | SELECT |
| Menu : accès libre à tous les secteurs (prototype) | A |

L'affectation des boutons est définie en un seul endroit (`BTN_FIRE`,
`BTN_POWER` dans `src/defs.inc`).

En coopération, la manette 1 pilote LANCE et la manette 2 ÉGIDE.

## Organisation

| Dossier | Contenu |
|---|---|
| `src/` | Code 6502 (ca65), un fichier par système |
| `assets/` | Sources graphiques (pixel art texte), partitions |
| `tools/gen_assets.py` | Conversion des ressources (CHR, cartes, musique, DPCM) |
| `cfg/mmc3.cfg` | Configuration de l'éditeur de liens (bancs MMC3) |
| `tests/` | Banc de test jsnes et suite automatisée |
| `docs/` | Conception, architecture, budgets, journal, résultats |

## Documentation

- [Conformité au cahier des charges](docs/CONFORMITE.md)
- [Game Design Document (ébauche)](docs/GDD.md)
- [Architecture logicielle et technique](docs/ARCHITECTURE.md)
- [Cartographie mémoire](docs/MEMOIRE.md)
- [Budgets de performance](docs/BUDGETS.md)
- [Résultats des tests](docs/RESULTATS_TESTS.md)
- [Journal de production](docs/JOURNAL.md)
- [Équilibrage](docs/EQUILIBRAGE.md)
- [Risques](docs/RISQUES.md)
- [Fabrication de la cartouche](docs/FABRICATION.md)
- [Manuel du joueur](docs/MANUEL.md)
