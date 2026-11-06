# Resultats des tests automatises (emulation)

> Fichier genere par `tests/run_tests.js`. **Tous ces tests sont realises en EMULATION (jsnes 1.2.1, NTSC).**
> Aucun test sur materiel reel n'a ete effectue a ce stade.

Resultat : **48/48** reussis.

| ID | Test | Resultat | Details |
|---|---|---|---|
| T01 | Demarrage : ecran titre stable, NMI actif, region NTSC detectee | OK | etat=0 nmi/60img=60 region=0 lag=0 |
| T02 | Menu : choix 1/2 joueurs, vaisseau, secteur | OK | joueurs 1->2->1, vaisseau=1, secteur (GAUCHE depuis 1, boucle)=8 |
| T03 | Deux manettes : deplacements independants et simultanes | OK | LANCE du=50 (2.5px x 20), EGIDE dv=35 (1.75px x 20) |
| T04 | Tirs simultanes des deux vaisseaux (et deplacement pendant le tir) | OK | projectiles LANCE max=4, EGIDE max=6 |
| T05 | Collision entre joueurs : contact physique, aucun degat, aucun blocage | OK | separation min=12px (corps 12px), vies 7->7, recul libre=25px |
| T06 | Ressource cooperative LIEN : remplissage par destructions et vol en formation | OK | jauge 0->10 en 160 images de vol en formation (attendu ~10) |
| T07 | Attaque combinee : FAISCEAU DE LIAISON entre les deux vaisseaux | OK | beam_t=148, points v=[75,90,105,120,135,150,165,180], ennemi detruit=true |
| T08 | Solo : la jauge pleine declenche la NOVA (aucun partenaire requis) | OK | nova_t=22, ennemis restants=0, projectiles=0 |
| T09 | Coop : TRANSFERT D'ENERGIE ramene un partenaire sans vie | OK | EGIDE en vol=1 |
| T10 | Scrolling horizontal : decor VRAM conforme a la carte sur tout le secteur (corps repete) | OK | 131 controles, 0 erreurs, camera finale=12704 (fin 12704, 10 passages du corps) |
| T11 | Scrolling vertical : decor et attributs VRAM conformes sur tout le secteur (corps repete) | OK | 102 controles, 0 erreurs (tuiles + attributs), HUD intact=true, camera=10272 (fin 10272) |
| T12 | Ennemis et projectiles : 4 familles + conteneurs destructibles, tirs ennemis | OK | familles vues=[1,2,3,4,5], ennemis simultanes max=10, projectiles ennemis max=6 |
| T13 | Mini-boss : apparition, 2 phases, destruction, niveau libere | OK | apparu=true, phase2=true, projectiles max=16, etat apres destruction=2, enchainement secteur 2=true |
| T14 | Perte de vie, reapparition invulnerable, game over et retour au titre | OK | vies initiales=7, pertes=8, game over=true, ecran CONTINUER=true, retour titre=true |
| T15 | Armes evolutives : capsule ramassee -> niveau +1, perte de vie -> niveau -1 | OK | niveaux 1->2->3, apres perte=2, projectiles max (niv.3)=16 |
| T16 | Musique : sequence jouee sur pulse 1/2, triangle, bruit et DPCM | OK | ecritures periode P1=21 P2=87 TRI=37 BRUIT=36, declenchements DPCM=14, registres APU utilises=19 |
| T17 | Effets sonores : plusieurs SFX distincts declenches en jeu | OK | 7 effets distincts : SHOT_A, SHOT_B, HIT, EXPLODE, POWERUP, BEAM, SYNC |
| T18 | Sauvegarde : record ecrit en PRG-RAM, relu apres coupure, copie corrompue toleree | OK | signature=SPTL, relu=042420, copie A corrompue -> 042420, vierge -> 005000 |
| T19 | Performances : scene chargee (2 joueurs niv.3, 10 ennemis, 16 tirs ennemis, boss, faisceau) | OK | vblank utilise max=1530/2273 cycles, cycles/image max=27489 moy=23716 (budget NTSC 29780 = 92 %), images perdues=0, sprites/ligne max=10, images avec >8 sprites/ligne=298/595, OAM saturee=599 |
| T20 | Performances : partie normale (secteur 1, 1900 images a 2 joueurs) | OK | cycles/image max=19026 moy=12948, images perdues=0, vblank utilise max=1530/2273 cycles |
| T21 | PAL : compensation 6/5 de la logique (cadence de jeu identique a 60 Hz) | OK | camera +600 px en 500 images a 50 Hz (attendu 600 = 10 s de jeu). Logique seule : jsnes emule uniquement le NTSC. |
| T23 | Capacite propre LANCE : surcharge (vitesse x1.8, esquive), recharge | OK | deplacement 63px en 14 images (normal 35), indemne=true, recharge=76 images, 2e appui pendant la recharge ignore=true |
| T24 | Capacite propre EGIDE : bouclier frontal absorbant 4 projectiles | OK | bouclier actif=true, absorbes=4/4, 5e projectile touche=true |
| T25 | Affichage : tuiles des vaisseaux conformes a l'orientation (H et V) | OK | H: LANCE $80 EGIDE $88 ok, V: LANCE $84 EGIDE $8c ok |
| T26 | Sequence narrative : texte affiche lettre par lettre, START pour passer | OK | etat=5, 1re ligne="AN 2291 - BRAS D'ORION", musique=1, apres START etat=1 |
| T27 | Attaque synchronisee : appuis sur A a moins de 8 images -> salve puissante | OK | salve=6 projectiles, recharge=59, appuis trop espaces -> 0, ennemi 8 PV detruit=true |
| T28 | Bilan de fin de secteur : sortie des vaisseaux, cibles, bonus de vies | OK | etat bilan=true, vaisseaux sortis=true, texte="CIBLES 42", score 010000 -> 013000 (+3 vies x 1000) |
| T29 | Decor multi-palettes : attributs VRAM conformes sur tout le secteur 1 | OK | 131 controles, erreurs d'attributs=0, palettes de decor utilisees=[0,2,3], HUD intact=true |
| T30 | Decor destructible : conteneur ancre au decor, detruit en 3 impacts, butin | OK | defilement suivi=10px/10 img, detruit apres 28 images de tir, capsule=true, score 000000->000200 |
| T31 | Point de reprise + CONTINUER : relance au relais (H et V), decor exact | OK | H: relais=6336 msg=true vie bonus=true CONTINUER=true dernier relais=6464 reprise cam=6467 erreurs VRAM=0 vies=7 credits=2 score=000000 ; V: relais=5120 msg=true vie bonus=true CONTINUER=true dernier relais=5264 reprise cam=5266 erreurs VRAM=0 vies=7 credits=2 score=000000 |
| T32 | Difficultes : RECRUE/PILOTE/VETERAN, EXPERT verrouille puis debloque et sauvegarde | OK | [diff, vies solo, vitesse visee, masque tourelles, PV boss] = [[0,9,0,127,150],[1,7,0,127,200],[2,4,16,63,250]] ; EXPERT verrouille=true, debloque apres l'epilogue et relu=true |
| T33 | Secteur 3 Ceinture brisee : decor/attributs, unites lourdes, Essaim-mere, epilogue | OK | secteur charge=true, erreurs VRAM decor=0 attributs=0, unites lourdes=true (tirent=true), drones laches par le boss=3, projectiles max=16, boss vaincu=true, epilogue=true |
| T34 | Secteurs debloques : sauvegardes, seuls les debloques sont proposes au menu | OK | sauvegarde vierge : secteur 2 inaccessible=true ; apres secteur 1 : masque=3, menu -> secteur 2 puis 1 |
| T35 | Acces libre (B au titre) : secteur 3 jouable sans sauvegarde, sauvegarde inchangee | OK | sans acces libre : verrouille=true ; avec B : secteur 3, texte="ACCES LIBRE : ACTIF", partie secteur 3 lancee=true, sauvegarde intacte=true |
| T36 | Secteur 4 Cite de Lumen (V) : decor/attributs, soutiens qui reparent, Garde-ciel, epilogue | OK | secteur charge=true, erreurs VRAM (tuiles+attributs)=0, vblank max=1341/2273, soutiens=true, reparation observee=true, directions de spirale distinctes=12, boss vaincu=true, epilogue=true |
| T37 | Capsules changeantes P/L/M/B et laser percant | OK | types successifs=PLMB, capsule L -> arme L1, 2e L -> niveau 2, trait unique : 1er ennemi -1 PV, 2e ennemi -1 PV (percant) |
| T38 | Missiles a tete chercheuse : recalage lateral sur la cible | OK | arme M, cible a +50 px lateralement : 4 PV infliges (2 par missile) |
| T39 | Bombes (SELECT) : munitions, projectiles effaces, degats, invulnerabilite, HUD | OK | bombes 2->1, invulnerable=40 img, ennemis restants=0, projectiles=0, HUD="S1*2 S1*1", sans munition inactif=true, capsule B -> 1 |
| T40 | Vie bonus tous les 20 000 points (max 9) | OK | score 020000 : vies 5 -> 6 ; plafond : 9 vies, palier=2 |
| T41 | Secteur 5 Chantiers d'Hadar : decor, mines, boss a tourelles destructibles | OK | secteur charge=true, VRAM 0/0 erreurs, poseurs=true, mines simultanees=2, explosion -> 8 projectiles, tourelles PV=[35,35], noyau intact tant que tourelles=true, tourelles detruites apres 265 img, boss vaincu=true, epilogue=true |
| T42 | Secteur 6 Premier Ancrage (V) : decor, emetteurs cristallins, Gardien d'Ancrage | OK | secteur charge=true, erreurs VRAM=0, emetteurs vus=true, ferme=true puis ouvert=true avec 4 projectiles en croix, directions boss=12, boss vaincu=true, epilogue=true |
| T43 | Secteur 7 Front de la Concordance : decor, Amiral-machine (kamikazes lances) | OK | secteur charge=true, VRAM 0/0 erreurs, kamikazes lances par le boss (max)=1, boss vaincu=true, arrivee secteur 8=true |
| T44 | Secteur 8 Coeur du Lien : Concordance en 3 phases, deux fins (LIAISON / RUPTURE) | OK | credits=3 : phases vues=1,2,3, page de fin=8 (LIAISON), retour titre=true, EXPERT=1 ; credits=2 : phases vues=1,2,3, page de fin=9 (RUPTURE), retour titre=true, EXPERT=1 |
| T45 | Campagne complete enchainee : secteurs 1 a 8, histoire, deblocages, fin | OK | secteurs joues=0,1,2,3,4,5,6,7, page finale=8 (LIAISON), secteurs debloques=11111111, retour titre=true |
| T46 | Encyclopedie : fiches decouvertes en jeu, sauvegardees, consultables | OK | sauvegarde vierge : fiches=11 ; apres 200 images de jeu : 111 ; fiche 1="LANCE", fiche 3="DRONE", fiche 4 (non vue)="????", retour titre=true |
| T47 | Classements : insertion triee, secteur et difficulte, sauvegarde, ecran | OK | classement solo=042420 > 005000 > 004500 > 004000 > 003000, secteur/difficulte 1re entree=1/1, ecran : "1.  042420  S1   PILOT" |
| T48 | Relais a chaque passage du corps : reprise exacte apres CONTINUER (H et V) | OK | H: relais=1600 (attendu 1600), erreurs VRAM apres reprise=0 ; V: relais=1520 (attendu 1520), erreurs VRAM apres reprise=0 |
| T22 | Compilation reproductible : deux constructions identiques octet pour octet | OK | sha256=f65e0aab7eccb964... |

## Mesures

```json
{
  "cam_h_end": 12704,
  "maxEnemies": 10,
  "maxEnemyBullets": 6,
  "stressMaxCycles": 27489,
  "stressAvgCycles": 23716,
  "stressLag": 0,
  "spLineMax": 10,
  "framesOver": 298,
  "sprFull": 599,
  "stressFrames": 595,
  "stressVblankMax": 1530,
  "normalMaxCycles": 19026,
  "normalAvgCycles": 12948,
  "normalLag": 0,
  "normalVblankMax": 1530,
  "sha256": "f65e0aab7eccb964873b6262c91b291dca73f1f0e0528d9e5cdab9d30646586e",
  "romSize": 327696
}
```
