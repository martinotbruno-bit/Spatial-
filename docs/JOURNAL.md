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

## 2026-11-06 — Phase 2 : audio et reprise

- Moteur audio : 6 instruments à enveloppes, commande de changement
  d'instrument dans les partitions ; musique du menu « Escadre » ;
  enregistrements WAV produits depuis l'émulateur (`make audio`).
- Point de reprise à mi-secteur et écran CONTINUER (3 crédits) ; reprise
  exacte du décor en H et en V (T31).
- Défaut détecté par T26 : l'initialisation des crédits écrasait le numéro
  de page de l'introduction (page 3 inexistante → texte illisible).
  Corrigé.
- 31/31 tests en émulation ; stress 90 % CPU, normal 64 %.

## 2026-11-06 — Phase 2 : vues de dessus et équilibrage

- Retour utilisateur : vaisseaux « étranges » en vertical. Cause : la vue
  de profil tournée de 90° ne donne pas une vue de dessus. → Sprites dédiés
  `ship_a_top`, `ship_b_top`, `fighter_top` (l'outil les préfère à la
  rotation quand ils existent). Cratères du sol assombris : ils se
  confondaient avec des projectiles.
- Difficultés RECRUE/PILOTE/VÉTÉRAN + EXPERT déblocable (sauvegardé) ; test T32.
- Pilote automatique et mesures d'équilibrage : 49/57 pertes au boss →
  motifs du boss paramétrés par difficulté (EQUILIBRAGE.md).
- 32/32 tests en émulation ; stress 91 % CPU, normal 64 %.

## 2026-11-06 — Phase 3 (début) : architecture de campagne, secteur 3

- Données de secteur en bancs PRG commutables avec en-tête ; bancs CHR par
  secteur (128 tuiles de décor + 64 tuiles de sprites) ; ressources
  découpées par secteur (`tiles_sN`, `sprites_sN`, `script_sN`).
  Vérification : les 32 tests existants restent verts après la refonte.
- Secteur 3 « Ceinture brisée » : carte d'astéroïdes, 3 palettes, rochers
  minéraliers destructibles, unité lourde (nouvelle famille), boss
  Essaim-mère, musique « Ceinture », page narrative. Test T33.
- Secteurs débloqués sauvegardés (sauvegarde v2), menu limité aux secteurs
  débloqués. Test T34.
- Défaut corrigé avant test : compteur de cycles de l'unité lourde partagé
  avec son état.
- Équilibrage secteur 3 mesuré : point ouvert documenté (EQUILIBRAGE.md).
- 34/34 tests en émulation ; stress 90 % CPU.

## 2026-11-06 — Retour utilisateur : « le .nes ne contient pas le secteur 3 »

- Vérifié : la ROM contenait le secteur 3, mais il était **verrouillé**
  (débloqué seulement après les secteurs 1 et 2 ; une sauvegarde vierge ou
  d'une version précédente ne propose que le secteur 1). Le nom de fichier
  « proto-phase1 » prêtait aussi à confusion.
- Corrections : accès libre par B à l'écran titre (session uniquement,
  sauvegarde intacte, test T35) ; ROM renommée `dist/spatial.nes` ;
  sous-titre de l'écran titre mis à jour.

## 2026-11-06 — Phase 3 : palettes verticales, secteur 4

- Palettes multiples en niveau vertical (copie RAM des attributs) ; le
  secteur 2 en profite (murs acier, aires d'atterrissage). Cratères laissés
  dans la palette du sol (sinon blocs rouges grossiers).
- Secteur 4 « Cité de Lumen » (V) : ville vue de dessus, appareils de
  soutien (réparation des ennemis proches), boss Garde-ciel (spirales),
  musique « Lumen », page narrative. Palettes revues après capture : les
  toits saturés nuisaient à la lisibilité. Test T36 (vblank V : 1341 cycles).
- 36/36 tests en émulation.

## 2026-11-06 — Arsenal enrichi

- Inversion des boutons à la demande : B = tir, A = capacité / pouvoir
  (affectation centralisée `BTN_FIRE` / `BTN_POWER` / `BTN_BOMB`).
- Laser perçant, missiles guidés (cible choisie à la salve, recalage
  latéral amorti), bombes sur SELECT, capsules changeantes P/L/M/B, HUD
  par joueur (type, niveau, bombes). Tests T37-T39.
- Défaut trouvé par T38 : les missiles dépassaient leur cible (correction
  trop lente, sans amortissement) → recalage toutes les 2 images avec
  retour à 0 près de la cible.
- Le flash blanc plein écran de la bombe masquait le HUD et posait un
  risque de photosensibilité → gris foncé pendant 6 images.
- Banc `$C000` à 94 % : le boss a été déplacé en `$E000`. **L'extension de
  la ROM devient nécessaire avant le secteur 5.**
- 39/39 tests ; stress avec missiles : 96 % CPU, 0 image perdue.

## 2026-11-06 — Secteurs rallongés (demande utilisateur)

- Chaque secteur : intro + corps répété 5 à 6 fois + arène du boss.
  Durées de défilement : Vesta 131 s, Kéra 109 s, Ceinture 132 s, Lumen
  115 s (au lieu de 25-30 s), plus le combat de boss. Vagues d'ennemis
  rejouées à chaque passage ; relais au milieu.
- Conversion position → carte en 16 bits (`map_pos`), script réarmé à
  chaque passage, attributs H/V alignés. Tests de défilement étendus au
  secteur entier (T10, T11, T29 : 0 erreur VRAM) ; tests de boss par saut
  en fin de secteur.
- Banc `$C000` à 98 % : **l'extension de la ROM est maintenant le
  préalable à toute nouvelle fonction**.

## 2026-11-06 — Difficulté réduite (demande utilisateur)

- Après l'allongement des secteurs : vies +2 en RECRUE/PILOTE, +1 en
  VÉTÉRAN ; vie bonus au relais (sauf EXPERT) ; PILOTE avec tirs visés lents
  et tourelles deux fois moins rapides ; PV des boss réduits en RECRUE et
  PILOTE. Tests T14, T31 (vie bonus), T32 mis à jour : 39/39.
- Module coopération déplacé en `$E000` (banc `$C000` : 98 % → 83 %).
- Mesures sur le secteur long : la coopération réussissait, pas le solo →
  vie bonus tous les 20 000 points (T40), solo 9 / 7 / 4 vies, et en solo un
  tir visé ennemi sur deux annulé. Résultats dans EQUILIBRAGE.md.

## 2026-11-06 — Extension de la ROM

- PRG 64 → 256 Kio (32 bancs, MMC3/TKROM standard). Écran titre et
  séquences narratives déplacés dans un banc commutable (tremplins dans le
  code fixe) : banc `$E000` de 88 % à 60 %.
- Défaut détecté : le bilan de fin de secteur (dans `story.s`) était appelé
  pendant le jeu alors que son banc n'était pas mappé → déplacé dans le
  code fixe. Garde ajoutée au banc de test contre ce type d'erreur.
- 40/40 tests.

## 2026-11-06 — Secteur 5 « Chantiers d'Hadar »

- Chantier naval (échafaudages, couples de coque, grues, soudures),
  3 palettes, musique « Hadar », page narrative.
- 7e famille : poseur de mines, mines explosant en anneau.
- Boss Croiseur à **parties destructibles** (2 tourelles, noyau protégé).
- Test T41 ; 41/41 en émulation. Bancs fixes : 84 % / 64 %.

## 2026-11-06 — Secteur 6 « Le Premier Ancrage »

- Structure extraterrestre verticale (chitine, veines, runes, cristaux),
  3 palettes, musique « Ancrage », page narrative.
- 8e famille : émetteur cristallin (structure défensive, invulnérable
  fermé) — les 8 familles du CDC sont couvertes.
- Boss Gardien d'Ancrage (croix tournantes). Test T42 ; 42/42.

## 2026-11-06 — Campagne complète : secteurs 7 et 8, deux fins

- CHR-ROM 32 → 64 Kio (décors de 8 secteurs + 7 jeux de sprites).
- Secteur 7 « Front de la Concordance » (flotte en bataille, Amiral-machine
  lançant des kamikazes) ; secteur 8 « Cœur du Lien » (boss final la
  Concordance en 3 phases). Musiques « Front » et « Cœur ».
- Deux fins (Liaison / Rupture) selon l'usage des crédits.
- Tests T43, T44, T45 (campagne enchaînée de 1 à 8) : 45/45.
- Incident de génération : deux scripts écrits à la racine du dépôt au lieu
  de `assets/`, détecté au contrôle et supprimé (contenu identique).

## 2026-11-06 — Encyclopédie et classements

- Sauvegarde v3 : bloc persistant (déblocages, secteurs, encyclopédie,
  2 classements de 5 entrées) en double copie de 128 octets.
- Encyclopédie (19 fiches, sprite + 3 lignes, sprites de boss pris dans le
  banc CHR de leur secteur) et écran des classements, dans le banc
  interface. Classement mis à jour en fin de partie (game over ou fin de
  campagne), plus à chaque fin de secteur.
- Défauts trouvés à la capture : lignes de classement qui se chevauchaient,
  sous-titre coupé. Tests T46, T47 ; 47/47.

## 2026-11-06 — Durée de campagne

- Corps des secteurs joué 8 à 10 fois (2 min 50 à 3 min 30 de défilement
  par secteur, ≈ 35 min sans perte) ; relais au début de chaque passage
  (vie bonus réservée au relais principal). Test T48 ; 48/48.

### Prochaines étapes proposées (Phase 2 — tranche verticale)

1. Validation Mesen + console réelle de la ROM Phase 1 (séparation HUD,
   DPCM/manettes, sauvegarde après coupure).
2. Secteur 1 : ~~décor définitif multi-palettes, décor destructible, point de reprise~~ (faits).
3. ~~Capacités propres à chaque vaisseau~~ ~~deuxième pouvoir coopératif~~ (faits).
4. ~~Séquence narrative d'introduction, écran de fin de secteur avec bilan~~ (faits).
5. ~~Moteur audio : enveloppes par instrument, musique de menu dédiée~~ (faits).
6. ~~Réorganisation des bancs~~ (fait).
