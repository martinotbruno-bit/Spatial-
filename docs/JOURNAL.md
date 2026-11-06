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

## 2026-11-06 — Phase 2 (début)

- Réorganisation des bancs : titre, HUD, palettes et scripts en `$E000` ;
  banc `$C000` de 95 % à 74 %.
- Capacités propres des vaisseaux sur B (jauge non pleine) : Surcharge de
  LANCE, Bouclier frontal d'ÉGIDE ; 2 SFX ajoutés ; tests T23-T24.
  Arbitrage : pas de troisième bouton sur la manette NES, donc B est
  contextuel (capacité / pouvoir coopératif selon la jauge), règle lisible
  grâce à la jauge affichée en permanence.
- Coût CPU : +0,3 % en scène de stress (28 090 cycles, 0 image perdue).
- Push vers GitHub toujours refusé (403, accès de l'application Claude au
  dépôt) : commits conservés en local.

## 2026-11-06 — Phase 2 (suite)

- Correction : tuiles des vaisseaux erronées en niveau vertical (index de
  table décalé) ; test T25 contrôlant les tuiles OAM ajouté.
- Salve synchronisée (2e pouvoir coopératif), projectiles à dégâts
  variables ; test T27.
- Séquences narratives (introduction, transition, épilogue), affichage
  lettre par lettre, musique « Liens » ; nouvel état ST_STORY ; test T26.
- Fin de secteur : sortie des vaisseaux, bilan (cibles, vies, bonus
  1000 points par vie) ; test T28.
- Budget du retour de trame : une colonne de décor et le HUD complet dans
  la même image prenaient 1704 cycles (> budget 1800 avec peu de marge) ;
  le HUD est désormais différé d'une image quand le décor est en attente
  (retour à 1237 cycles max).
- 28/28 tests en émulation. Stress : 94 % CPU, 0 image perdue.

## 2026-11-06 — Phase 2 : décor définitif du secteur 1

- Attributs de couleur transmis au fil du défilement horizontal :
  coque grise, sections rouillées et conduites orange, hublots et pylônes
  d'énergie bleus (palettes 0/2/3). Test T29 (1190 octets d'attributs
  vérifiés, HUD intact).
- Décor destructible : conteneurs de fret ancrés sur la coque (type
  ennemi n°5, 3 PV, une capsule sur deux). Arbitrage : sprites plutôt que
  tuiles de décor destructibles, pour ne pas ajouter un test
  projectile/carte coûteux alors que le budget CPU de stress est serré.
  Test T30.
- Banc de test : lecture de la VRAM brute (jsnes « déplie » les attributs
  dans ses structures internes, ce qui faussait la vérification).
- Optimisation : chemin rapide 16×16 (stress 97 % → 90 %) ; un premier
  essai débordait de l'OAM sur le tampon VRAM, détecté par les tests.
- 30/30 tests en émulation.

### Prochaines étapes proposées (Phase 2 — tranche verticale)

1. Validation Mesen + console réelle de la ROM Phase 1 (séparation HUD,
   DPCM/manettes, sauvegarde après coupure).
2. Secteur 1 : ~~décor définitif multi-palettes, décor destructible~~ (faits) ; checkpoint.
3. ~~Capacités propres à chaque vaisseau~~ ~~deuxième pouvoir coopératif~~ (faits).
4. ~~Séquence narrative d'introduction, écran de fin de secteur avec bilan~~ (faits).
5. Moteur audio : enveloppes par instrument, musique de menu dédiée.
6. ~~Réorganisation des bancs~~ (fait).
