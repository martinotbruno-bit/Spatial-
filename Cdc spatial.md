# CAHIER DES CHARGES MAÎTRE
## Jeu vidéo original pour Nintendo Entertainment System (NES)

**Genre :** Shoot'em up arcade spatial  
**Mode principal :** Coopération locale à deux joueurs  
**Mode secondaire :** Solo  
**Plateforme cible :** Nintendo Entertainment System d'origine  
**Support final souhaité :** Cartouche physique compatible NES  
**Version :** Cahier des charges consolidé

---

# 1. OBJET ET FINALITÉ DU PROJET

Le présent cahier des charges définit la conception, la production, la validation et la livraison d'un jeu vidéo original destiné à la Nintendo Entertainment System (NES).

Le projet consiste à créer un shoot'em up spatial d'arcade ambitieux, techniquement poussé et soigneusement réalisé, dans la tradition des meilleurs jeux de la console.

Le jeu doit exploiter au maximum les capacités légitimes de la NES, sans compromettre sa compatibilité avec une console d'origine.

Il doit proposer :
- Une expérience arcade immédiate et dynamique.
- Une coopération locale à deux joueurs réellement développée.
- Un mode solo complet et équilibré.
- Une campagne riche et variée.
- Une identité artistique et sonore originale.
- Une difficulté progressive et exigeante.
- Une finition comparable aux meilleures productions NES de fin de cycle.
- Une architecture technique fiable et documentée.
- Une ROM finale et un dossier complet permettant la fabrication d'une cartouche physique.

**Principe fondamental :** la jouabilité, la fluidité, la stabilité et la compatibilité matérielle sont prioritaires sur l'accumulation d'effets ou de fonctionnalités.

# 2. CONCEPT GÉNÉRAL

## 2.1 Genre et univers

Le jeu est un shoot'em up spatial pur, dans la tradition des grands classiques de l'arcade.

L'univers doit évoquer un space opera grandiose et mystérieux, avec une histoire originale racontée entre les niveaux.

Le joueur pilote un vaisseau spatial dans un conflit de grande ampleur impliquant plusieurs factions et familles d'ennemis.

## 2.2 Perspectives

Le jeu alterne deux types de niveaux :
- Défilement horizontal.
- Défilement vertical avec vue du dessus.

La répartition des deux perspectives est déterminée par les besoins de rythme, de variété et de mise en scène de la campagne.

## 2.3 Modes de jeu

**Mode coopération :**
- Deux joueurs simultanés.
- Deux vaisseaux différents.
- Actions combinées.
- Pouvoirs coopératifs.
- Réserve de vies commune.

**Mode solo :**
- Campagne entièrement jouable.
- Équilibrage adapté.
- Difficulté cohérente.
- Aucun passage ne doit imposer la présence d'un deuxième joueur.

## 2.4 Durée

La campagne doit durer environ 1 à 2 heures lors d'une première progression, selon le niveau de difficulté et les performances des joueurs.

L'IA de développement détermine le nombre optimal de niveaux pour atteindre cet objectif.

# 3. JOUABILITÉ ET CONTRÔLES

## 3.1 Déplacements

- Déplacement libre dans huit directions.
- Contrôles précis et réactifs.
- Maniabilité adaptée à chaque vaisseau.
- Aucun délai artificiel gênant la réaction du joueur.

## 3.2 Vaisseaux

Les deux vaisseaux doivent être nettement différents.

Ils possèdent :
- Une silhouette propre.
- Des caractéristiques de déplacement spécifiques.
- Des armes différentes.
- Des configurations de tir distinctes.
- Des capacités particulières.
- Des rôles tactiques complémentaires.

Aucun vaisseau ne doit être systématiquement supérieur à l'autre.

## 3.3 Collisions entre joueurs

Les deux vaisseaux peuvent entrer en collision physiquement.

Cependant :
- Ils ne doivent jamais se blesser mutuellement.
- Les collisions ne doivent pas provoquer de blocage injuste.
- Le contrôle doit rester immédiatement récupérable.

## 3.4 Coopération

La coopération doit constituer une caractéristique centrale du jeu.

Prévoir :
- Des attaques combinées contextuelles.
- Des actions dépendant de la position relative des deux vaisseaux.
- Des possibilités de synchronisation et de timing.
- Plusieurs pouvoirs coopératifs.
- Une ressource dédiée aux capacités combinées.
- Une jauge clairement identifiable.

Les pouvoirs peuvent notamment explorer les possibilités suivantes :
- Bouclier partagé.
- Rayon d'énergie combiné.
- Attaque synchronisée.
- Assistance défensive.
- Transfert d'énergie.
- Protection temporaire.

Ces exemples sont des pistes de conception. L'IA doit retenir les systèmes les plus intéressants et techniquement fiables.

Les attaques combinées doivent être spectaculaires, lisibles et équilibrées.

## 3.5 Vies

La réserve de vies est commune en coopération.

Le système doit être équilibré afin d'éviter qu'un joueur pénalise excessivement son partenaire.

# 4. ARMEMENT ET PROGRESSION

L'armement doit être particulièrement riche et varié, en s'inspirant des meilleurs shoot'em up.

Prévoir notamment :
- Tirs frontaux.
- Tirs concentrés.
- Tirs en éventail.
- Tirs latéraux.
- Projectiles à trajectoires particulières.
- Armes de soutien.
- Armes défensives.
- Bombes.
- Attaques spéciales.
- Armes évolutives.
- Capacités propres à chaque vaisseau.

Les armes doivent posséder des fonctions tactiques différentes.

Le joueur doit comprendre immédiatement :
- Quelle arme il possède.
- Quel effet elle produit.
- Comment elle évolue.
- Dans quelles situations elle est efficace.

La puissance des armes doit être équilibrée pour conserver un véritable défi.

Les pertes de vie, les changements d'armement et les récupérations doivent être intégrés à la progression.

# 5. ENNEMIS ET BOSS

## 5.1 Ennemis

Créer la plus grande variété d'ennemis possible dans les limites techniques de la NES.

La faction ennemie principale doit posséder plusieurs familles distinctes :
- Chasseurs.
- Drones.
- Unités lourdes.
- Tourelles.
- Appareils de soutien.
- Unités kamikazes.
- Ennemis spécialisés.
- Structures défensives.

Chaque famille doit présenter des comportements reconnaissables.

Varier :
- Les trajectoires.
- Les vitesses.
- Les formations.
- Les modes d'attaque.
- Les résistances.
- Les interactions avec le décor.

## 5.2 Boss

Les boss doivent constituer des moments forts de la campagne.

Ils peuvent combiner :
- Plusieurs phases.
- Des patterns évolutifs.
- Des parties destructibles.
- Des points faibles.
- Des changements de comportement.
- Des attaques coordonnées.
- Des séquences de mise en scène spécifiques.

Leur conception doit respecter les limites de sprites, de scanlines et de calcul de la NES.

Les attaques doivent rester lisibles et anticipables.

# 6. UNIVERS ET SCÉNARIO

Créer un univers original de science-fiction spatiale.

L'ambiance doit être :
- Grandiose.
- Mystérieuse.
- Épique.
- Cohérente.
- Immersive.

L'histoire est racontée entre les niveaux par de courtes séquences animées.

Les transitions ne doivent pas casser le rythme.

Le scénario doit donner du sens :
- Aux différentes zones.
- Aux factions.
- Aux ennemis.
- Aux boss.
- À la progression de la campagne.
- Aux événements majeurs.

## 6.1 Fins

Deux fins distinctes sont prévues.

Elles dépendent des performances du joueur ou de l'équipe.

## 6.2 Encyclopédie

Créer une encyclopédie consultable présentant :
- Les vaisseaux.
- Les ennemis.
- Les factions.
- Les éléments importants de l'univers.

Des éléments peuvent être débloqués progressivement.

Aucun niveau secret n'est prévu.

# 7. DIRECTION ARTISTIQUE

La direction artistique doit mélanger plusieurs approches tout en créant une identité originale.

## 7.1 Identité visuelle

- Contrastes marqués.
- Palettes spécifiques aux factions.
- Vaisseaux futuristes élégants et profilés.
- Silhouettes immédiatement reconnaissables.
- Environnements variés.
- Effets visuels spectaculaires mais lisibles.

## 7.2 Environnements

Prévoir une grande diversité :
- Espace profond.
- Planètes.
- Stations spatiales.
- Cités futuristes.
- Bases militaires.
- Installations industrielles.
- Zones de combat spécifiques.
- Structures extraterrestres.

Les décors peuvent être interactifs ou destructibles lorsque cela apporte une réelle valeur au gameplay et reste techniquement viable.

## 7.3 Effets visuels

Exploiter au maximum les possibilités graphiques de la NES :
- Explosions.
- Impacts.
- Projectiles.
- Animations.
- Flashs.
- Effets de destruction.
- Effets de décor.
- Apparitions et transformations de boss.

La fluidité et la lisibilité doivent toujours primer.

## 7.4 Interface

Le HUD doit évoluer selon les niveaux et afficher les informations utiles :
- Vies.
- État des joueurs.
- Armement.
- Ressource coopérative.
- Score.
- Informations relatives aux boss.

L'interface doit rester discrète et parfaitement lisible.

# 8. MUSIQUE ET EFFETS SONORES

Créer une bande-son épique de science-fiction avec des thèmes mémorables.

Prévoir :
- Thèmes de niveaux.
- Thèmes de boss.
- Musique des menus.
- Musique des séquences narratives.
- Sons de tirs.
- Impacts.
- Explosions.
- Alertes.
- Récupérations.
- Sons d'interface.

Aucune voix n'est requise.

L'audio doit exploiter les cinq canaux natifs de la NES :
- Deux canaux pulse.
- Un canal triangle.
- Un canal bruit.
- Un canal DPCM.

L'IA doit arbitrer entre richesse musicale, effets simultanés et compatibilité matérielle.

# 9. CAMPAGNE ET REJOUABILITÉ

La campagne suit une progression linéaire, avec une route unique.

Aucun niveau secret n'est prévu.

Le nombre de niveaux est déterminé par l'IA afin d'atteindre la durée cible de 1 à 2 heures.

Les niveaux horizontaux et verticaux sont répartis selon les besoins de la campagne.

## 9.1 Difficulté

Prévoir plusieurs difficultés sélectionnables.

La progression doit être :
- Accessible au début.
- Progressive.
- De plus en plus exigeante.
- Très difficile en fin de campagne.

Un mode expert est déblocable après avoir terminé la campagne.

Les différences de difficulté doivent être équilibrées et testées.

## 9.2 Scores et sauvegardes

Prévoir :
- Classement solo.
- Classement coopération.
- Meilleurs scores sauvegardés.
- Niveaux débloqués sauvegardés.
- Rejouabilité des niveaux.
- Possibilité d'améliorer ses scores.

La sauvegarde doit utiliser une solution non volatile compatible avec le mapper et le PCB retenus.

# 10. MENUS ET PRÉSENTATION

Prévoir :
- Écran titre animé.
- Menu principal.
- Sélection des pilotes.
- Présentation des vaisseaux.
- Sélection de difficulté.
- Encyclopédie.
- Classements.
- Écrans de transition.
- Écran de fin de niveau.
- Écran de game over.
- Deux fins distinctes.

La finition doit être premium :
- Animations soignées.
- Transitions propres.
- Interface cohérente.
- Retours visuels et sonores.
- Navigation simple à la manette.
- Équilibrage précis.

# 11. ARCHITECTURE TECHNIQUE NES

La compatibilité avec une NES d'origine est une exigence fondamentale.

Aucune modification de la console ne doit être nécessaire.

Aucun coprocesseur ou matériel additionnel transformant les caractéristiques de la console ne doit être requis.

Les extensions mémoire et fonctions de mapper compatibles avec les consoles NES d'origine peuvent être utilisées si elles sont justifiées et validées.

## 11.1 Référentiel matériel

| Élément | Référence |
|---|---|
| Résolution | 256 × 240 pixels |
| Sprites matériels | 64 par image au maximum |
| Limite par scanline | 8 sprites avant risque de disparition |
| Taille des sprites | 8×8 ou 8×16 pixels |
| Palettes | 3 couleurs visibles par palette, plus transparence |
| Audio | 5 canaux natifs |
| Contrôleurs | 2 ports manettes |
| NTSC | Environ 60 Hz |
| PAL | 50 Hz |
| CPU NTSC | Ricoh 2A03 |
| CPU PAL | Ricoh 2A07 |

## 11.2 ROM et mapper

La capacité ROM doit être poussée aussi loin que raisonnablement utile.

L'IA doit choisir le mapper le plus performant et fiable selon les besoins du jeu.

MMC3 et MMC5 peuvent être évalués, mais aucun choix n'est imposé à ce stade.

Important :
- Un mapper ne rend pas le CPU plus rapide.
- Il peut fournir des fonctions de banque mémoire et, selon le modèle, des fonctions vidéo ou d'interruption.
- Toute fonction additionnelle doit être compatible avec une NES d'origine.
- Le PCB et les composants doivent correspondre au mapper retenu.

## 11.3 Scrolling

La technique de défilement doit être choisie pour chaque niveau.

Les niveaux horizontaux et verticaux doivent être prototypés dès le début.

Tester :
- Changements de direction.
- Transitions.
- Mises à jour de nametables.
- Attributs de palettes.
- Changements de banques.
- Charge CPU.
- Stabilité du rendu.

## 11.4 Budgets techniques

L'IA doit définir des budgets stricts et mesurables pour :
- CPU par image.
- Sprites par scanline.
- Mises à jour PPU.
- Ennemis actifs.
- Projectiles.
- Effets visuels.
- Mémoire de travail.
- Banques ROM.
- Audio.

Ces budgets doivent être respectés même dans les scènes les plus chargées.

## 11.5 NTSC et PAL

Le jeu doit viser une expérience aussi proche que possible sur NTSC et PAL.

Adapter :
- Cadence de simulation.
- Animations.
- Temporisations.
- Audio.
- Difficulté.

Une identité strictement identique image par image n'est pas garantie en raison des différences matérielles.

# 12. ARCHITECTURE LOGICIELLE

Le langage de programmation est libre.

La priorité est donnée à :
- La qualité.
- La fiabilité.
- La maintenabilité.
- La reproductibilité.
- Les performances.

Le code doit être organisé en systèmes clairement identifiés :
- Boucle principale.
- Contrôles.
- Joueurs.
- Armes.
- Ennemis.
- Collisions.
- Boss.
- Scrolling.
- Rendu.
- Audio.
- Sauvegarde.
- Menus.
- Campagne.

L'architecture doit être documentée.

# 13. AUTONOMIE DE L'IA DE DÉVELOPPEMENT

L'IA doit disposer de la plus grande autonomie possible.

Elle doit :
- Prendre les décisions techniques et artistiques nécessaires.
- Comparer les solutions possibles.
- Réaliser des prototypes.
- Mesurer les performances.
- Documenter les arbitrages.
- Corriger les problèmes.
- Maintenir un journal de production.
- Signaler les risques et blocages.
- Demander une décision humaine uniquement si elle est indispensable.

Elle ne doit jamais déclarer une fonction terminée ou validée si elle ne l'a pas réellement testée.

# 14. MÉTHODE DE DÉVELOPPEMENT

## Phase 1 : Prototype technique

Avant de produire la campagne complète, créer un prototype comprenant :

1. Une chaîne de compilation fonctionnelle.
2. Un écran de test stable.
3. La gestion de deux manettes.
4. Deux vaisseaux simultanés.
5. Déplacements et tirs simultanés.
6. Collisions entre joueurs sans dégâts.
7. Une attaque combinée.
8. Une ressource coopérative.
9. Un scrolling horizontal.
10. Un scrolling vertical.
11. Des ennemis et projectiles.
12. Un mini-boss.
13. Une séquence musicale.
14. Plusieurs effets sonores.

Mesurer les performances et définir les budgets techniques.

**Jalon critique :** ne pas lancer la production complète tant que le prototype à deux joueurs, les deux types de scrolling et les scènes chargées ne sont pas suffisamment stables.

## Phase 2 : Tranche verticale

Produire un segment représentatif du jeu final comprenant :
- Un environnement abouti.
- Plusieurs ennemis.
- Un boss ou mini-boss.
- Une séquence coopérative.
- Le HUD.
- La musique.
- Les effets sonores.
- Les transitions.

Cette tranche doit démontrer le niveau de qualité final visé.

## Phase 3 : Production de la campagne

Développer :
- Tous les niveaux.
- Les ennemis.
- Les boss.
- Les armes.
- Les environnements.
- Les séquences narratives.
- Les transitions.
- Les menus.

## Phase 4 : Équilibrage et finition

Régler :
- Difficulté.
- Lisibilité.
- Scores.
- Récompenses.
- Collisions.
- Armes.
- Pouvoirs coopératifs.
- Musique.
- Effets sonores.
- Interface.

Corriger les défauts visuels, sonores et techniques.

## Phase 5 : Préparation cartouche

Finaliser :
- ROM.
- Mapper.
- Sauvegarde.
- PCB.
- Composants.
- Fichiers de fabrication.
- Documentation de programmation.

Valider la cartouche sur du matériel réel.

# 15. TESTS ET VALIDATION

## 15.1 Tests automatisés et émulation

Prévoir :
- Compilation reproductible.
- Tests automatisés des systèmes critiques lorsque possible.
- Tests dans plusieurs émulateurs reconnus.
- Tests NTSC et PAL.
- Tests des collisions.
- Tests des sauvegardes.
- Tests des transitions.
- Tests des entrées manette.
- Tests des scènes chargées.
- Tests de non-régression.

## 15.2 Tests matériels

La validation finale doit être effectuée sur :
- Plusieurs révisions de NES lorsque disponibles.
- Consoles NTSC.
- Consoles PAL.
- Deux manettes standard.
- Cartouche de production.

La compatibilité avec les manettes alternatives peut être testée sans compromettre le fonctionnement standard.

## 15.3 Limite de certification

Une IA qui ne dispose pas physiquement des consoles, cartouches et instruments nécessaires ne peut pas certifier un test matériel réel.

Elle doit distinguer clairement :
- Tests réalisés en émulation.
- Tests réalisés sur matériel réel.
- Tests restant à réaliser.

## 15.4 Critères d'acceptation

Le jeu est acceptable lorsque :
- La ROM démarre et fonctionne sur le matériel validé.
- Les deux joueurs peuvent jouer simultanément.
- Le mode solo permet de terminer la campagne.
- Les niveaux horizontaux et verticaux sont stables.
- Les boss et armes fonctionnent.
- Les pouvoirs coopératifs fonctionnent.
- Les scores et sauvegardes fonctionnent.
- Les scènes chargées restent lisibles et jouables.
- Les ralentissements et clignotements ne rendent pas le jeu injuste.
- L'audio reste stable.
- Les différences NTSC/PAL sont documentées.
- La compilation est reproductible.

# 16. LIVRABLES OBLIGATOIRES

## 16.1 Logiciel

- ROM finale `.nes`.
- Versions de test.
- Code source intégral.
- Historique ou journal des versions.
- Scripts de compilation.
- Outils et dépendances nécessaires.
- Instructions de reconstruction de la ROM.

## 16.2 Ressources

- Sources graphiques.
- Sprites.
- Tilesets.
- Palettes.
- Animations.
- Musiques.
- Effets sonores.
- Formats de travail des ressources.

## 16.3 Documentation de conception

- Game Design Document (GDD).
- Bible artistique.
- Scénario.
- Fiches des vaisseaux.
- Fiches des ennemis.
- Fiches des boss.
- Fiches des armes.
- Cartographie des niveaux.
- Progression et événements de campagne.

## 16.4 Documentation technique

- Documentation logicielle.
- Cartographie mémoire.
- Spécifications du mapper.
- Budgets de performance.
- Documentation audio.
- Manuel du joueur.
- Instructions de compilation.

## 16.5 Qualité

- Rapports de tests.
- Matrice de compatibilité.
- Liste des défauts connus.
- Résultats des tests de performance.
- Résultats des tests NTSC/PAL.

## 16.6 Fabrication de cartouche

- Schéma PCB.
- Nomenclature des composants (BOM).
- Fichiers Gerber.
- Instructions de fabrication.
- Instructions de programmation de la ROM.
- Instructions de programmation de la mémoire de sauvegarde.

Tous les fichiers de fabrication doivent correspondre exactement à la révision de ROM et de mapper validée.

# 17. GESTION DES RISQUES

L'IA doit anticiper les risques techniques et proposer des solutions.

| Risque | Réponse attendue |
|---|---|
| Trop de sprites sur une scanline | Répartir les objets, simplifier les silhouettes et contrôler les priorités |
| Charge CPU excessive | Profiler, limiter les entités et optimiser les routines |
| Scrolling complexe | Prototyper chaque technique et retenir la plus fiable |
| Manque de mémoire | Mesurer les ressources, organiser les banques et compresser avec prudence |
| Lisibilité insuffisante | Réduire les effets concurrents et renforcer les contrastes |
| Écart NTSC/PAL | Adapter les temporisations et valider les deux cadences |
| Sauvegarde instable | Choisir une mémoire non volatile adaptée et tester les coupures |
| Incompatibilité cartouche | Valider mapper, PCB et composants sur matériel réel |

Lorsqu'un objectif artistique ou fonctionnel entre en conflit avec une contrainte matérielle, l'IA doit comparer plusieurs solutions et retenir la plus robuste.

Elle ne doit jamais masquer un compromis important.

# 18. RÉFÉRENCES DE QUALITÉ

Les jeux suivants peuvent servir de références de qualité, de rythme, de variété ou de maîtrise technique :

- Crisis Force.
- Recca.
- Gradius II.
- Over Horizon.
- Gun-Nac.

Ces références ne doivent pas être copiées.

Le projet doit posséder :
- Son propre univers.
- Ses propres personnages.
- Ses propres vaisseaux.
- Ses propres ennemis.
- Ses propres mécaniques.
- Ses propres niveaux.
- Sa propre direction artistique.
- Sa propre musique.

# 19. RÈGLES FINALES IMPOSÉES À L'IA

1. Respecter ce cahier des charges comme référence centrale du projet.
2. Préserver toutes les décisions confirmées.
3. Ne pas introduire de fonctionnalités contradictoires.
4. Créer une œuvre originale, sans copier les références.
5. Privilégier la jouabilité et la stabilité avant les effets supplémentaires.
6. Prototyper et mesurer avant de figer les choix techniques.
7. Ne jamais déclarer une compatibilité matérielle sans test correspondant.
8. Documenter les choix, les limites et les résultats.
9. Signaler explicitement les blocages.
10. Demander une intervention humaine uniquement lorsqu'elle est indispensable.
11. Livrer l'ensemble des éléments nécessaires à la compilation, à la maintenance et à la fabrication de la cartouche.

# 20. DÉFINITION DU RÉSULTAT FINAL ATTENDU

Le projet est considéré comme abouti lorsque le jeu propose :

- Une campagne complète et rejouable.
- Une coopération locale à deux joueurs convaincante.
- Un mode solo équilibré.
- Deux vaisseaux complémentaires.
- Un armement riche et varié.
- Des ennemis et boss mémorables.
- Une alternance maîtrisée de niveaux horizontaux et verticaux.
- Un univers original et cohérent.
- Une direction artistique forte.
- Une musique et des effets sonores de qualité.
- Une difficulté progressive et exigeante.
- Une finition soignée.
- Une stabilité conforme aux contraintes de la NES.
- Une compatibilité matérielle vérifiée.

Le résultat final doit comprendre une ROM `.nes` fonctionnelle, l'intégralité des sources, les ressources de production, la documentation technique et les fichiers nécessaires à la fabrication d'une cartouche physique compatible avec une NES d'origine.

**EXIGENCE DE VÉRITÉ :** toute fonctionnalité non implémentée, tout test non réalisé et toute compatibilité non vérifiée doivent être explicitement signalés. La qualité du livrable se mesure autant à sa fiabilité et à sa documentation qu'à son ambition.

---

**FIN DU CAHIER DES CHARGES MAÎTRE**