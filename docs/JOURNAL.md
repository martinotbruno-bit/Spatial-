# Journal de production

## 2026-11-06 — Phase 1 : prototype technique

### Décisions et arbitrages

| Sujet | Options comparées | Décision | Justification |
|---|---|---|---|
| Langage | C (cc65) / assembleur 6502 (ca65) | Assembleur ca65 | Budget CPU serré (2 joueurs, 64 sprites, scrolling) ; contrôle exact des cycles du NMI/IRQ |
| Mapper | MMC3 / MMC5 | MMC3 (TKROM) | Voir ARCHITECTURE §1 : fiabilité, disponibilité, IRQ de ligne suffisante |
| HUD | Sprite 0 / IRQ MMC3 / HUD en sprites | IRQ MMC3 | Sprite 0 = attente active coûteuse ; HUD en sprites = budget sprites déjà critique |
| Miroir | Horizontal en V / vertical partout | Vertical partout | Un seul schéma de tables pour les deux orientations, HUD protégé (voir bug n°3) |
| Repère de simulation | Code par orientation / repère (u,v) | Repère (u,v) unique | Ennemis, armes, boss, collisions écrits une fois pour H et V |
| Sprites verticaux | Dessin séparé / rotation automatique | Rotation par l'outil | Moitié moins de sources graphiques, cohérence garantie |
| Taille des sprites | 8×8 / 8×16 | 8×8 | Exigé par le compteur A12 du MMC3 avec sprites en `$1000` |
| Ressources | Éditeurs binaires / sources texte + générateur | Texte + `gen_assets.py` | Versionnable, relisible, compilation reproductible |
| PAL | Vitesses ajustées / mise à jour 6/5 | Mise à jour 6/5 | Une seule logique ; comportement identique à 60 Hz ; coût documenté |
| Musique | Moteur tiers / moteur maison | Moteur maison minimal | Pas de dépendance de licence ; contrôle de la cohabitation avec les SFX |
| Tests | Émulateur graphique manuel / émulation scriptée | jsnes en Node, sans affichage | Tests automatisables, mesures de cycles, captures |

### Défauts trouvés et corrigés pendant le prototype

1. **Blocage au démarrage** : `title_enter` appelait `wait_nmi` alors que le
   NMI était désactivé après la détection de région. → NMI réactivé avant le
   premier écran.
2. **Saut vers une adresse invalide** : `title_enter` atteint par `jmp`
   depuis RESET puis terminé par `rts` (pile vide). → appel par `jsr`.
3. **HUD dupliqué en bas de l'écran (niveau vertical)** : en miroir
   horizontal, le passage de la rangée 29 à 0 bascule de table de noms ; la
   zone de jeu « débordait » sur la table du HUD. → miroir vertical et
   anneau de 30 rangées dans la table `$2400`.
4. **Zone de jeu non défilée** : l'IRQ MMC3 n'était jamais servie (aucun
   `CLI` après l'initialisation). Défaut qui aurait existé sur console.
5. **Détection de région erronée** (PAL détecté en NTSC) : la boucle de
   comptage fait 11 cycles et non 14. Seuils recalculés (10/11/12).
6. **Carte horizontale de 264 colonnes** non indexable sur 8 bits →
   256 colonnes, fin de défilement à 1760 px.
7. **Faisceau de Liaison ne couvrant que la moitié du segment** (pas
   d'interpolation divisé par 16 au lieu de 8). → pas = delta × 32 en 8.8.
8. **Ralentissements en scène de stress** (175 images perdues sur 600) →
   4 optimisations (BUDGETS.md), 0 image perdue.
9. **Mesure de performance sous-estimée** : jsnes comptabilise le DMA OAM
   hors du compteur d'instructions. → banc de test corrigé (+513 cycles).

### État en fin de Phase 1

- 22 tests automatisés réussis en émulation (RESULTATS_TESTS.md).
- **Aucun test sur matériel réel.** Le jalon critique du §14 (« prototype à
  deux joueurs, deux scrollings et scènes chargées suffisamment stables »)
  est atteint **en émulation uniquement**. Recommandation : valider la ROM
  sur une console via cartouche flash (type EverDrive / PowerPak, mapper 4)
  et dans Mesen (précision de cycle) avant de lancer la Phase 3.

### Prochaines étapes proposées (Phase 2 — tranche verticale)

1. Validation Mesen + console réelle de la ROM Phase 1 (séparation HUD,
   DPCM/manettes, sauvegarde après coupure).
2. Secteur 1 complet : décor définitif (attributs par paire de colonnes,
   2-3 palettes), décor interactif/destructible, checkpoint.
3. Capacités propres à chaque vaisseau, deuxième pouvoir coopératif.
4. Séquence narrative d'introduction, écran de fin de secteur avec bilan.
5. Moteur audio : enveloppes par instrument, musique de menu dédiée.
6. Réorganisation des bancs (banc `$C000` rempli à 95 %).
