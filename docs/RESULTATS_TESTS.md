# Resultats des tests automatises (emulation)

> Fichier genere par `tests/run_tests.js`. **Tous ces tests sont realises en EMULATION (jsnes 1.2.1, NTSC).**
> Aucun test sur materiel reel n'a ete effectue a ce stade.

Resultat : **32/32** reussis.

| ID | Test | Resultat | Details |
|---|---|---|---|
| T01 | Demarrage : ecran titre stable, NMI actif, region NTSC detectee | OK | etat=0 nmi/60img=60 region=0 lag=0 |
| T02 | Menu : choix 1/2 joueurs, vaisseau, secteur | OK | joueurs 1->2->1, vaisseau=1, secteur=1 |
| T03 | Deux manettes : deplacements independants et simultanes | OK | LANCE du=50 (2.5px x 20), EGIDE dv=35 (1.75px x 20) |
| T04 | Tirs simultanes des deux vaisseaux (et deplacement pendant le tir) | OK | projectiles LANCE max=4, EGIDE max=6 |
| T05 | Collision entre joueurs : contact physique, aucun degat, aucun blocage | OK | separation min=12px (corps 12px), vies 5->5, recul libre=25px |
| T06 | Ressource cooperative LIEN : remplissage par destructions et vol en formation | OK | jauge 0->10 en 160 images de vol en formation (attendu ~10) |
| T07 | Attaque combinee : FAISCEAU DE LIAISON entre les deux vaisseaux | OK | beam_t=148, points v=[75,90,105,120,135,150,165,180], ennemi detruit=true |
| T08 | Solo : la jauge pleine declenche la NOVA (aucun partenaire requis) | OK | nova_t=22, ennemis restants=0, projectiles=0 |
| T09 | Coop : TRANSFERT D'ENERGIE ramene un partenaire sans vie | OK | EGIDE en vol=1 |
| T10 | Scrolling horizontal : contenu VRAM conforme a la carte sur tout le niveau | OK | 16224 tuiles verifiees, 0 erreurs, camera finale=1760 |
| T11 | Scrolling vertical : contenu VRAM conforme a la carte sur tout le niveau | OK | 13312 tuiles verifiees, 0 erreurs, HUD intact=true, camera=1536 |
| T12 | Ennemis et projectiles : 4 familles + conteneurs destructibles, tirs ennemis | OK | familles vues=[1,2,3,4,5], ennemis simultanes max=10, projectiles ennemis max=6 |
| T13 | Mini-boss : apparition, 2 phases, destruction, niveau libere | OK | apparu=true, phase2=true, projectiles max=16, etat apres destruction=2, enchainement secteur 2=true |
| T14 | Perte de vie, reapparition invulnerable, game over et retour au titre | OK | vies initiales=3, pertes=4, game over=true, ecran CONTINUER=true, retour titre=true |
| T15 | Armes evolutives : capsule ramassee -> niveau +1, perte de vie -> niveau -1 | OK | niveaux 1->2->3, apres perte=2, projectiles max (niv.3)=16 |
| T16 | Musique : sequence jouee sur pulse 1/2, triangle, bruit et DPCM | OK | ecritures periode P1=21 P2=87 TRI=37 BRUIT=36, declenchements DPCM=14, registres APU utilises=19 |
| T17 | Effets sonores : plusieurs SFX distincts declenches en jeu | OK | 8 effets distincts : SHOT_A, SHOT_B, HIT, EXPLODE, POWERUP, BEAM, SYNC, COOPREADY |
| T18 | Sauvegarde : record ecrit en PRG-RAM, relu apres coupure, copie corrompue toleree | OK | signature=SPTL, relu=042420, copie A corrompue -> 042420, vierge -> 005000 |
| T19 | Performances : scene chargee (2 joueurs niv.3, 10 ennemis, 16 tirs ennemis, boss, faisceau) | OK | vblank utilise max=1530/2273 cycles, cycles/image max=27152 moy=23499 (budget NTSC 29780 = 91 %), images perdues=0, sprites/ligne max=10, images avec >8 sprites/ligne=298/595, OAM saturee=599 |
| T20 | Performances : partie normale (secteur 1 complet a 2 joueurs) | OK | cycles/image max=19197 moy=13436, images perdues=0, vblank utilise max=1530/2273 cycles |
| T21 | PAL : compensation 6/5 de la logique (cadence de jeu identique a 60 Hz) | OK | camera +600 px en 500 images a 50 Hz (attendu 600 = 10 s de jeu). Logique seule : jsnes emule uniquement le NTSC. |
| T23 | Capacite propre LANCE : surcharge (vitesse x1.8, esquive), recharge | OK | deplacement 63px en 14 images (normal 35), indemne=true, recharge=76 images, 2e appui pendant la recharge ignore=true |
| T24 | Capacite propre EGIDE : bouclier frontal absorbant 4 projectiles | OK | bouclier actif=true, absorbes=4/4, 5e projectile touche=true |
| T25 | Affichage : tuiles des vaisseaux conformes a l'orientation (H et V) | OK | H: LANCE $80 EGIDE $88 ok, V: LANCE $84 EGIDE $8c ok |
| T26 | Sequence narrative : texte affiche lettre par lettre, START pour passer | OK | etat=5, 1re ligne="AN 2291 - BRAS D'ORION", musique=1, apres START etat=1 |
| T27 | Attaque synchronisee : appuis sur A a moins de 8 images -> salve puissante | OK | salve=6 projectiles, recharge=59, appuis trop espaces -> 0, ennemi 8 PV detruit=true |
| T28 | Bilan de fin de secteur : sortie des vaisseaux, cibles, bonus de vies | OK | etat bilan=true, vaisseaux sortis=true, texte="CIBLES 42", score 010000 -> 013000 (+3 vies x 1000) |
| T29 | Decor multi-palettes : attributs VRAM conformes sur tout le secteur 1 | OK | 1190 octets d'attributs verifies, 0 erreurs, palettes de decor utilisees=[0,2,3], HUD intact=true |
| T30 | Decor destructible : conteneur ancre au decor, detruit en 3 impacts, butin | OK | defilement suivi=10px/10 img, detruit apres 28 images de tir, capsule=true, score 000000->000200 |
| T31 | Point de reprise + CONTINUER : relance au relais (H et V), decor exact | OK | H: relais=896 msg=true CONTINUER=true reprise cam=899 erreurs VRAM=0 vies=5 credits=2 score=000000 ; V: relais=768 msg=true CONTINUER=true reprise cam=772 erreurs VRAM=0 vies=5 credits=2 score=000000 |
| T32 | Difficultes : RECRUE/PILOTE/VETERAN, EXPERT verrouille puis debloque et sauvegarde | OK | [diff, vies solo, vitesse visee, masque tourelles, PV boss] = [[0,5,0,127,180],[1,3,16,63,250],[2,2,16,63,250]] ; EXPERT verrouille=true, debloque apres l'epilogue et relu=true |
| T22 | Compilation reproductible : deux constructions identiques octet pour octet | OK | sha256=31e41e8849724d49... |

## Mesures

```json
{
  "cam_h_end": 1760,
  "maxEnemies": 10,
  "maxEnemyBullets": 6,
  "stressMaxCycles": 27152,
  "stressAvgCycles": 23499,
  "stressLag": 0,
  "spLineMax": 10,
  "framesOver": 298,
  "sprFull": 599,
  "stressFrames": 595,
  "stressVblankMax": 1530,
  "normalMaxCycles": 19197,
  "normalAvgCycles": 13436,
  "normalLag": 0,
  "normalVblankMax": 1530,
  "sha256": "31e41e8849724d491854d856162b7ddbc383760a0af44e821c812b6f69b50c27",
  "romSize": 98320
}
```
