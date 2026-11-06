# Game Design Document — Projet SPATIAL (ébauche, fin de Phase 1)

Ce document fixe les décisions de conception prises pendant le prototype et
propose la structure de la campagne. Les éléments marqués *[prototype]* sont
implémentés et testés en émulation ; *[à produire]* relève des phases 2 à 4.

## 1. Univers (proposition)

**Contexte.** Le Bras d'Orion est relié par les *Liens*, un réseau d'ancrages
énergétiques bâti par une civilisation disparue. La **Concordance**, une
intelligence militaire née d'un de ces ancrages, réveille les Sentinelles et
avance de système en système en coupant les Liens derrière elle.

Deux pilotes de l'escadre de reconnaissance — volant en paire liée — forment
la dernière formation capable de *se brancher* sur un Lien :

- **LANCE** — intercepteur effilé, rapide, tir concentré.
- **ÉGIDE** — vaisseau d'escorte lourd, plus lent, tir en éventail.

Le mécanisme coopératif (jauge LIEN, Faisceau de Liaison) est ainsi justifié
par le scénario : les deux vaisseaux partagent l'énergie d'un même Lien.

**Factions** *[à produire]* : la Concordance (faction principale, palette
violet/vert), les Ancrages (structures extraterrestres neutres puis hostiles,
palette ocre/or), la flotte humaine en déroute (alliée, séquences narratives).

## 2. Vaisseaux *[prototype]*

| | LANCE | ÉGIDE |
|---|---|---|
| Rôle | Dégâts concentrés, frappe des cibles prioritaires | Couverture de zone, contrôle des vagues |
| Vitesse | 2,5 px/image | 1,75 px/image |
| Cadence | 1 salve / 6 images | 1 salve / 9 images |
| Arme niv. 1 | Trait frontal rapide (7 px/image) | Éventail de 3 orbes |
| Arme niv. 2 | Double trait parallèle | Éventail de 5 |
| Arme niv. 3 | Double trait + 2 diagonales | Éventail de 5 + 2 tirs latéraux |
| Palette | Bleu / cyan / blanc | Rouge / orange / jaune |

Aucun des deux n'est supérieur : LANCE inflige plus de dégâts par seconde sur
une cible unique, ÉGIDE couvre plus d'espace.

**Capacités propres** *[prototype]* — bouton B quand la jauge LIEN n'est pas
pleine (jauge pleine : B déclenche le pouvoir coopératif) :

| | LANCE — Surcharge | ÉGIDE — Bouclier frontal |
|---|---|---|
| Effet | 16 images à 4,5 px/image, invulnérable (esquive) | Écran 8×24 px devant le vaisseau, absorbe 4 projectiles, 2 s |
| Recharge | 90 images (1,5 s) | 240 images (4 s) |
| Rôle | Traverser un barrage, ramasser une capsule | Couvrir le partenaire, tenir une position face au boss |

**Armes évolutives** : capsule « P » lâchée par les chasseurs → niveau +1
(max 3) ; perte d'une vie → niveau −1 (min 1).

## 3. Coopération *[prototype]*

- **Ressource LIEN (0–64)**, affichée en permanence dans le HUD.
  Remplissage : destructions (+2 à +4 selon l'ennemi, +8 pour un boss) et
  **vol en formation** (+1 toutes les 16 images lorsque les deux vaisseaux
  sont à moins de 48 px). Un signal sonore annonce la jauge pleine.
- **Faisceau de Liaison** (B, jauge pleine, deux vaisseaux en vol) : rayon
  tendu entre les deux vaisseaux pendant 2,5 s. Il blesse tout ennemi qui le
  traverse et absorbe les projectiles ennemis (+1 point chacun). Son efficacité
  dépend directement du **placement relatif** : écartés, les pilotes balaient
  une large bande ; rapprochés, ils concentrent l'attaque.
- **Transfert d'énergie** (B, jauge pleine, partenaire sans vie) : le
  partenaire revient immédiatement. Évite qu'un joueur pénalise durablement
  l'autre quand la réserve commune est vide.
- **Nova** (solo, ou partenaire en cours de réapparition) : onde de choc qui
  efface les projectiles et blesse tous les ennemis à l'écran.
- **Réserve de vies commune** : 5 en coopération, 3 en solo.
- **Collisions entre vaisseaux** : contact physique (corps 12×12 px),
  séparation immédiate selon l'axe de moindre pénétration, jamais de dégâts.

- **Salve synchronisée** *[prototype]* : les deux pilotes appuient sur A à
  moins de 8 images d'intervalle → chaque vaisseau tire 3 projectiles
  lourds (4 dégâts chacun). Recharge 1 s, aucune jauge consommée : le
  pouvoir récompense le timing, pas l'accumulation.

Piste restante : *bouclier partagé* (deuxième usage du LIEN à demi-jauge).

## 4. Ennemis *[prototype : 4 familles]*

| Famille | Comportement | PV | Points |
|---|---|---|---|
| Drone | Avance en ondulant (sinus 64 pas, déphasage par script) | 1 | 100 |
| Chasseur | Entre vite, freine, 2 tirs visés, repart ; lâche une capsule | 4 | 300 |
| Tourelle | Liée au décor, tir visé toutes les 64 images | 6 | 500 |
| Kamikaze | Fonce et se recale latéralement sur le joueur le plus proche | 2 | 200 |

*[à produire]* : unités lourdes, appareils de soutien (réparation, bouclier
de groupe), ennemis spécialisés (mines, poseurs de barrage), structures
défensives destructibles du décor.

## 5. Boss *[prototype : mini-boss]*

**Sentinelle KORVAX** (32×32, 250 PV, barre dans le HUD) :
entrée scriptée (invulnérable), phase 1 oscillation lente + gerbe de 3 +
tir visé ; phase 2 sous 50 % : oscillation rapide, gerbe de 5 et rafales de
3 tirs visés. Flash à l'impact, destruction en chaîne de 100 images.

## 6. Campagne proposée (durée cible 1 à 2 h)

Hypothèse de calibrage, issue du prototype : un secteur sans perte dure
~1 min (30 s de défilement + mini-boss) dans le prototype ; un secteur final durera 5 à 7 min
(défilement plus long, 2 mini-boss + boss). Avec les reprises de checkpoint
d'une première partie, la durée observée est estimée à 1,5–2× la durée sans
perte.

**Décision : 8 secteurs** (5 horizontaux, 3 verticaux), soit 45–55 min sans
perte et ~1 h 15 – 1 h 45 en première progression.

| # | Secteur | Défilement | Environnement | Boss |
|---|---|---|---|---|
| 1 | Station Orbitale Vesta | H | Station spatiale | Sentinelle KORVAX |
| 2 | Surface de Kéra | V | Planète, base militaire | Forteresse mobile |
| 3 | Ceinture brisée | H | Espace profond, astéroïdes | Essaim-mère |
| 4 | Cité de Lumen | V | Cité futuriste | Garde-ciel |
| 5 | Chantiers d'Hadar | H | Installations industrielles | Croiseur en construction |
| 6 | Le Premier Ancrage | V | Structures extraterrestres | Gardien d'Ancrage |
| 7 | Front de la Concordance | H | Zone de combat, flotte | Amiral-machine |
| 8 | Cœur du Lien | H | Intérieur extraterrestre | Concordance (3 phases) |

Deux fins : *Fin de Liaison* (partie terminée avec ≥ 1 vie et ≥ 60 % des
Ancrages sauvés — compteur de performance) et *Fin de Rupture* (sinon).

## 7. Difficulté *[à produire]*

Trois niveaux sélectionnables (Recrue / Pilote / Vétéran) + **Expert**
débloqué après une fin (bit réservé dans la sauvegarde). Leviers : vitesse
des projectiles (table lente/rapide déjà en place), cadence des tourelles,
PV des boss, nombre de vies. Progression interne : densité des scripts
croissante de secteur en secteur.

## 8. Score et rejouabilité

Score d'équipe à 6 chiffres. Records solo et coop sauvegardés *[prototype]*.
*[à produire]* : sélection des secteurs débloqués, classement à 5 entrées
par mode, multiplicateur de chaîne pour les destructions rapides.
