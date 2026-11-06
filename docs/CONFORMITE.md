# Conformité au cahier des charges

Légende :
**✅ ÉMU** = réalisé et vérifié par un test automatisé **en émulation** ·
**🟡** = réalisé partiellement ou vérifié visuellement seulement ·
**⬜** = non réalisé (phase ultérieure) ·
**❌ MAT** = test sur matériel réel **non effectué**.

> Aucune fonction n'est déclarée validée sur matériel : aucun test sur
> console NES, aucune cartouche n'a été produite (CDC §15.3).

## Phase 1 — Prototype technique (§14)

| # | Exigence | État | Preuve |
|---|---|---|---|
| 1 | Chaîne de compilation fonctionnelle | ✅ ÉMU | `make`, T22 (reproductible) |
| 2 | Écran de test stable | ✅ ÉMU | T01 (titre animé, 0 image perdue) |
| 3 | Gestion de deux manettes | ✅ ÉMU | T03 |
| 4 | Deux vaisseaux simultanés | ✅ ÉMU | T03, T04 |
| 5 | Déplacements et tirs simultanés | ✅ ÉMU | T04 |
| 6 | Collisions entre joueurs sans dégâts | ✅ ÉMU | T05 |
| 7 | Une attaque combinée | ✅ ÉMU | T07 (Faisceau de Liaison) |
| 8 | Une ressource coopérative | ✅ ÉMU | T06 (jauge LIEN) |
| 9 | Un scrolling horizontal | ✅ ÉMU | T10 (16 224 tuiles VRAM vérifiées) |
| 10 | Un scrolling vertical | ✅ ÉMU | T11 (13 312 tuiles, HUD intact) |
| 11 | Des ennemis et projectiles | ✅ ÉMU | T12 (4 familles, tirs visés) |
| 12 | Un mini-boss | ✅ ÉMU | T13 (2 phases, destruction, enchaînement) |
| 13 | Une séquence musicale | ✅ ÉMU | T16 (3 musiques, 5 canaux dont DPCM) |
| 14 | Plusieurs effets sonores | ✅ ÉMU | T17 (12 définis, 6 observés en jeu automatique) |
| — | Mesurer les performances, définir les budgets | ✅ ÉMU | T19, T20, BUDGETS.md |
| — | **Jalon critique** : prototype stable avant production | 🟡 | Atteint en émulation ; validation Mesen + console recommandée avant Phase 3 |

## Exigences générales (état à la fin de la Phase 1)

| § | Exigence | État | Commentaire |
|---|---|---|---|
| 2.2 | Niveaux horizontaux et verticaux | ✅ ÉMU | 1 secteur de chaque |
| 2.3 | Coop 2 joueurs, vaisseaux différents, vies communes | ✅ ÉMU | T03-T09 |
| 2.3 | Solo complet, sans passage imposant 2 joueurs | 🟡 | Solo jouable avec les 2 vaisseaux, Nova de remplacement ; campagne non produite |
| 2.4 | Campagne de 1 à 2 h | ⬜ | 8 secteurs proposés (GDD §6) ; 2 secteurs prototypes (~1 min chacun) |
| 3.1 | 8 directions, contrôles précis | ✅ ÉMU | Déplacement sub-pixel 8.8, sans inertie |
| 3.2 | Vaisseaux distincts et complémentaires | 🟡 | Vitesse, armes, cadence différentes ; capacités propres à produire |
| 3.3 | Collisions entre joueurs sans blocage | ✅ ÉMU | T05 |
| 3.4 | Plusieurs pouvoirs coopératifs, jauge identifiable | 🟡 | Faisceau, Transfert d'énergie (+ Nova solo) ; attaque synchronisée à produire |
| 3.5 | Vies communes équilibrées | 🟡 | Réserve commune + Transfert d'énergie ; équilibrage à faire |
| 4 | Armement riche et évolutif | 🟡 | 2 × 3 niveaux (frontal, concentré, éventail, latéral, diagonal) ; bombes/armes défensives à produire |
| 5.1 | Grande variété d'ennemis | 🟡 | 4 familles sur 8 demandées |
| 5.2 | Boss multi-phases | 🟡 | 1 mini-boss 2 phases ; parties destructibles à produire |
| 6 | Scénario, séquences, 2 fins, encyclopédie | ⬜ | Univers proposé (GDD §1) |
| 7 | Direction artistique | 🟡 | Palettes par faction/secteur, sprites originaux ; décors de prototype |
| 7.4 | HUD complet | ✅ ÉMU | Vies, score, record, jauge, armes, boss |
| 8 | Musique et SFX sur 5 canaux | ✅ ÉMU | Moteur maison, DPCM |
| 9.1 | Difficultés sélectionnables, mode expert | ⬜ | Bit réservé en sauvegarde |
| 9.2 | Classements et sauvegarde non volatile | 🟡 | Records solo/coop sauvegardés (T18) ; classement complet à produire |
| 10 | Menus et présentation | 🟡 | Titre animé, menu, présentation des vaisseaux ; autres écrans à produire |
| 11 | Compatibilité NES d'origine, sans matériel additionnel | 🟡 | Conçu pour MMC3 standard ; **❌ MAT** |
| 11.2 | Mapper choisi et justifié | ✅ | ARCHITECTURE §1 |
| 11.3 | Scrolling prototypé dès le début | ✅ ÉMU | T10, T11 |
| 11.4 | Budgets stricts et mesurables | ✅ ÉMU | BUDGETS.md |
| 11.5 | NTSC et PAL | 🟡 | Détection + compensation testées en logique (T21) ; **❌ MAT** PAL |
| 12 | Architecture logicielle documentée | ✅ | ARCHITECTURE.md, MEMOIRE.md |
| 13 | Journal, arbitrages, risques | ✅ | JOURNAL.md, RISQUES.md |
| 15.1 | Tests automatisés, plusieurs émulateurs | 🟡 | 22 tests jsnes ; **un seul émulateur** (Mesen/FCEUX à ajouter) |
| 15.2 | Tests matériels | ❌ MAT | Non réalisables sans console |
| 16.1 | ROM, sources, scripts, instructions | ✅ | `dist/`, `src/`, `Makefile`, README |
| 16.2 | Sources des ressources | ✅ | `assets/` (texte) + générateur |
| 16.3 | GDD, bible artistique, fiches | 🟡 | GDD ébauche ; bible et fiches à produire |
| 16.4 | Documentation technique | 🟡 | Architecture, mémoire, budgets, manuel ; spécification mapper/PCB finale à produire |
| 16.5 | Rapports de tests, matrice de compatibilité | 🟡 | RESULTATS_TESTS.md ; matrice matériel vide (aucun test matériel) |
| 16.6 | Fichiers de fabrication de cartouche | ⬜ | Phase 5 |
| 18 | Originalité (références non copiées) | ✅ | Univers, vaisseaux, ennemis, musique, graphismes créés pour le projet |

## Matrice de compatibilité

| Plateforme | État |
|---|---|
| jsnes 1.2.1 (NTSC) | ✅ 22/22 tests |
| Mesen / FCEUX / Nestopia | ⬜ non testé |
| NES NTSC (toutes révisions) | ❌ non testé |
| NES PAL | ❌ non testé |
| Famicom / clones | ❌ non testé |
| Cartouche de production | ⬜ non fabriquée |
