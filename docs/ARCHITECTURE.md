# Architecture technique et logicielle — Prototype Phase 1

## 1. Choix matériels

### Mapper : MMC3 (carte TKROM)

| Critère | MMC3 (TKROM) | MMC5 (EKROM/ELROM) |
|---|---|---|
| Disponibilité de PCB de reproduction | Très large, peu coûteux | Rare ; répliques CPLD récentes |
| Compatibilité consoles et clones | Excellente | Bonne, plus de cas limites |
| PRG / CHR max | 512 Kio / 256 Kio | 1 Mio / 1 Mio |
| IRQ de ligne | Oui (compteur A12) | Oui (comparateur) |
| PRG-RAM sur pile | 8 Kio | jusqu'à 64 Kio |
| Atouts spécifiques | — | ExRAM (attribut par tuile), multiplicateur, split vertical |
| Complexité / risque | Faible | Élevée |

**Décision :** MMC3/TKROM. Les besoins du jeu (bancs, IRQ de séparation du
HUD, sauvegarde) sont couverts ; le MMC5 n'apporterait que des confort
(attributs fins, multiplication) au prix d'un risque de fabrication et de
compatibilité plus élevé. Rappel : aucun mapper n'accélère le CPU.

Configuration actuelle : PRG 256 Kio (32 bancs de 8 Kio), CHR-ROM 32 Kio,
PRG-RAM 8 Kio sur pile. Bancs fixes : 30 (`$C000`) et 31 (`$E000`).
L'écran titre et les séquences narratives tournent depuis un banc commutable
(banc 5, mappé en `$8000` à la place des données de secteur) ; des tremplins
du code fixe (`title_enter_far`, `story_enter_far`) le mappent avant d'y
entrer. Le banc de test vérifie à chaque instruction qu'aucun code ne
s'exécute en `$8000-$9FFF` si ce banc n'y est pas mappé.

### Contraintes de configuration MMC3 respectées

- Décor en table de motifs `$0000`, sprites en `$1000`, sprites 8×8 : seule
  configuration où le compteur de lignes (front montant de A12) avance une
  fois par ligne de façon fiable.
- Mode PRG 0 : `$C000-$FFFF` fixe (code), `$8000`/`$A000` commutables
  (cartes, musique). Le vecteur RESET et l'initialisation sont dans le dernier
  banc (`$E000`), seul banc garanti à la mise sous tension.
- PRG-RAM protégée en écriture (`$A001 = $C0`) hors des sauvegardes.

### Secteurs et bancs (Phase 3)

Chaque secteur occupe un **banc PRG de 8 Kio** mappé en `$8000` (R6) pendant
son niveau, et commence par un **en-tête** de 22 octets (offsets `SH_*` dans
`defs.inc`) : orientation, longueur de carte, fin de défilement, relais,
pointeurs (ids, gabarits, attributs, script, palette), bancs CHR, musique,
type de boss. `sector_map` copie l'en-tête et place les pointeurs de carte en
page zéro ; tout le code de niveau est indépendant du secteur.

CHR-ROM (unités de 1 Kio) :

| Unités | Contenu | Registre |
|---|---|---|
| 0-1 | décor commun `$00-$7F` (police, jauges) | R0 = 0 |
| 2+2k | décor du secteur k, tuiles `$80-$FF` | R1 |
| 16-18 | sprites communs `$00-$BF` (vaisseaux, ennemis, tirs, explosions) | R2-R4 |
| 19+j | jeu de sprites j, `$C0-$FF` (boss H/V, objet de décor) | R5 |

**Longueur des secteurs** : la carte est découpée en intro (jouée une fois),
corps (joué `SH_REPS` fois) et fin (arène du boss). `map_pos` convertit la
position réelle (16 bits) en index de carte ; le script d'apparition revient
à sa première entrée du corps à chaque nouveau passage. Le corps est aligné
sur les blocs d'attributs (4 colonnes / 2 rangées) ; la fin de défilement
et le relais (milieu) sont calculés par le générateur, qui vérifie que le
déclencheur du boss coïncide avec la fin.

Ajouter un secteur = un fichier de tuiles, un script, une entrée `SECTORS`
dans `tools/gen_assets.py` (et un jeu de sprites si le boss est nouveau).

## 2. Boucle principale et interruptions

```
           NMI (début du retour de trame)                IRQ MMC3 (ligne ~31)
  ┌────────────────────────────────────────────┐   ┌─────────────────────────┐
  │ si nmi_ready : DMA OAM, tampon VRAM          │   │ $2006/$2005/$2005/$2006 │
  │ défilement HUD (0,0), PPUMASK                │   │ = défilement de la zone │
  │ armement IRQ MMC3 (latch = ligne de split)   │   │   de jeu (X,Y,table)    │
  │ audio (×2 toutes les 5 images en PAL)        │   └─────────────────────────┘
  └────────────────────────────────────────────┘
  Boucle : attente NMI → manettes → logique (×2 toutes les 5 images en PAL)
           → construction OAM + tampon VRAM → nmi_ready = 1
```

- Le NMI n'écrit en VRAM que si la logique a fini (`nmi_ready`), sinon
  l'image est comptée comme perdue (`lag_count`) et l'écran reste cohérent.
- Le programme principal ne touche jamais au PPU pendant l'affichage : toutes
  les mises à jour passent par le **tampon VRAM** (`vbuf`, 128 octets,
  format `[longueur|$80 si +32][adr haute][adr basse][données…]`).
- L'audio est dans le NMI pour un tempo stable même en cas de ralentissement.
- Marqueurs de profilage : écritures en `$5FF1` (début) et `$5FF0` (fin du
  travail). Zone non décodée par le MMC3, sans effet sur console.

## 3. Écran : HUD fixe + zone de jeu défilante

Miroir **vertical** dans les deux orientations :

| | Table A (`$2000`) | Table B (`$2400`) |
|---|---|---|
| Rangées 0-3 | HUD (rangée 3 vide : masque la ligne de transition) | inutilisées |
| Niveau horizontal | colonnes 0-31 de la zone de jeu (rangées 4-29) | colonnes 32-63 |
| Niveau vertical | — | anneau de 30 rangées de la zone de jeu |

- **Horizontal** : une colonne de 26 tuiles est envoyée (mode +32) chaque
  fois que la caméra franchit 8 px, 32 colonnes en avance ; défilement X sur
  512 px. Split : table `(cam>>8)&1`, X = `cam & 255`, Y = 32.
- **Vertical** : une rangée de 32 tuiles tous les 8 px ; Y diminue de 0 à 239
  en boucle dans la table B. Le passage de la rangée 29 à 0 fait basculer le
  PPU vers `$2C00`, miroir de `$2400` : l'anneau reste dans la table B et le
  HUD n'est jamais écrasé (problème découvert et corrigé pendant le
  prototype, voir JOURNAL).
- Split par la méthode `$2006/$2005/$2005/$2006`, seule façon de changer Y en
  cours d'image. Les 4 valeurs sont précalculées par la logique : l'IRQ ne
  fait que 4 écritures (~40 cycles).
- Attributs des secteurs verticaux : chaque paire de rangées de carte
  (2m, 2m+1) forme une rangée de blocs 16×16 ; quand la rangée impaire est
  écrite, la moitié correspondante de la rangée d'attributs est recomposée
  dans une copie RAM (`vattr_sh`, 64 o) puis envoyée (8 octets). Vérifié
  bloc par bloc (T11, T31, T36).
- Attributs : rangée 0 = palette HUD. Secteur horizontal : 3 palettes de
  décor par blocs 16×16, précalculées par l'outil (7 octets par groupe de
  4 colonnes, `map_h_attr`) et envoyées avec la 1re colonne de chaque groupe
  (7 entrées d'un octet, pas de 8 en VRAM). Secteur vertical : palette
  unique (l'anneau de 30 rangées n'est pas aligné sur les blocs
  d'attributs de 4 rangées ; à traiter en Phase 3).

## 4. Coordonnées logiques (u, v)

Toute la simulation se fait dans un repère indépendant de l'orientation :
**u = axe d'avancée** (les ennemis arrivent par les u élevés), **v = axe
latéral**. Seuls le rendu et la lecture de la croix dépendent du niveau :

| | Écran X | Écran Y | Croix « avant » |
|---|---|---|---|
| Horizontal | u | v | Droite |
| Vertical | v | (256 − taille) − u | Haut |

Conséquences : ennemis, armes, collisions, boss et scripts sont **partagés**
par les deux types de niveaux. Les sprites sont dessinés une seule fois
(orientés vers la droite) ; l'outil produit la version verticale par rotation
de 90°.

## 5. Systèmes (un fichier par système)

| Fichier | Système |
|---|---|
| `main.s` | En-tête iNES, RESET, NMI, IRQ, boucle principale, manettes, utilitaires |
| `stage.s` | Niveaux : chargement, défilement H/V, scripts d'apparition, états de jeu |
| `player.s` | Vaisseaux, déplacements, armement, projectiles joueurs, pertes de vie |
| `enemy.s` | Ennemis (IA par type), projectiles ennemis, tir visé (atan 16 directions), explosions, capsules, score |
| `boss.s` | Mini-boss : entrée, 2 phases, motifs de tir, destruction |
| `coop.s` | Jauge LIEN, Faisceau / Transfert / Nova, **toutes les collisions** |
| `render.s` | OAM : métasprites, rotation de priorité, textes en sprites |
| `hud.s` | Interface |
| `audio.s` | Moteur musical et SFX |
| `save.s` | Sauvegarde PRG-RAM |
| `title.s` | Écran titre et menu |
| `data.s` | Palettes, scripts des secteurs |

### Collisions

Test par distance entre centres sur chaque axe :
`(p1 − p2) + (o1 − o2) + R < 2R` en non signé (o = décalage du centre,
R = somme des demi-tailles). Une soustraction, une addition et une
comparaison par axe, sans débordement.

| Paire | Boîtes |
|---|---|
| Projectile ennemi / joueur | noyau joueur 4×4 (généreux pour le joueur) |
| Ennemi / joueur | ennemi 12×12, noyau 4×4 |
| Projectile joueur / ennemi | 6×6 contre 12×12 (moitié des projectiles par image, sans traversée possible) |
| Joueur / joueur | 12×12, séparation selon l'axe de moindre pénétration |

### Sprites

- Pools : 10 ennemis, 16 projectiles ennemis, 16 projectiles joueurs,
  8 explosions, 3 capsules, 8 points de faisceau, 1 boss (16 sprites).
- Ordre de priorité de dessin : message, joueurs, faisceau, projectiles
  ennemis (lisibilité/équité), boss, ennemis, capsules, tirs joueurs, effets.
- Au-delà de 8 sprites par ligne, la **rotation de la position de départ
  dans l'OAM** (pas de 17 entrées par image) répartit la disparition : un
  clignotement plutôt qu'une disparition permanente.

### Tir visé

`atan16` : direction 0-15 à partir de (du, dv) par seuils de pente
(1/5, 2/3, 3/2, 5) puis quadrant ; vitesses lues dans des tables 8.8
générées (2 vitesses × 16 directions).

## 6. Audio

- Données compilées depuis `assets/music.txt` (notation texte). Commande
  `$FD n` dans un flux : changement d'instrument.
- 6 instruments pulse (lead, arpège, pincé, cuivre, nappe, cloche) :
  rapport cyclique, volume d'attaque, vitesse de décroissance, volume de
  maintien (tables `ins_*` de `audio.s`).
- 4 flux (pulse 1 mélodie, pulse 2 harmonie, triangle basse, bruit
  batterie) ; la grosse caisse déclenche aussi un échantillon **DPCM**
  synthétisé (273 octets à `$C000`).
- SFX prioritaires sur pulse 2 et bruit ; la musique reprend le canal à la
  fin de l'effet.
- Tables de périodes séparées NTSC/PAL (fréquence CPU différente) ; tempo
  conservé en PAL par 6 pas audio pour 5 images.
- Les lectures DMC pouvant corrompre `$4016/$4017`, les manettes sont lues
  jusqu'à obtenir deux lectures identiques.

## 6 bis. Point de reprise

À mi-secteur (H : 896 px, V : 768 px, multiples de 32 pour rester aligné
sur les groupes d'attributs), la caméra mémorise `cp_cam`. « CONTINUER »
relance `stage_start` à cette position : script avancé jusqu'au
déclencheur courant, 33 colonnes (H) ou 30 rangées (V) dessinées depuis
`cam/8`, et pour le vertical `vsy = (32 − cam) mod 240`,
`vrow = 29 − (cam/8 mod 30)`. Vérifié par T31 (0 erreur VRAM en H et en V).

## 7. NTSC / PAL

Détection au démarrage (boucle de 11 cycles entre deux NMI : 10 → NTSC,
11 → PAL, 12 → Dendy traité comme 50 Hz). En 50 Hz, une mise à jour logique
supplémentaire toutes les 5 images restitue la vitesse de jeu (60 mises à
jour/s) ; l'affichage reste à 50 images/s. Voir BUDGETS.md pour le coût de
cette mise à jour double dans les scènes chargées.

## 8. Chaîne de production

`tools/gen_assets.py` (déterministe) → `build/chr.bin`, `build/assets.inc`,
`build/kick.dmc` → `ca65` → `ld65` (`cfg/mmc3.cfg`) → `build/spatial.nes`,
carte mémoire `build/spatial.map`, symboles `build/spatial.lbl` (utilisés par
les tests et les débogueurs d'émulateur).
