# Resultats des tests automatises (emulation)

> Fichier genere par `tests/run_tests.js`. **Tous ces tests sont realises en EMULATION (jsnes 1.2.1, NTSC).**
> Aucun test sur materiel reel n'a ete effectue a ce stade.

Resultat : **22/22** reussis.

| ID | Test | Resultat | Details |
|---|---|---|---|
| T01 | Demarrage : ecran titre stable, NMI actif, region NTSC detectee | OK | etat=0 nmi/60img=60 region=0 lag=0 |
| T02 | Menu : choix 1/2 joueurs, vaisseau, secteur | OK | joueurs 1->2->1, vaisseau=1, secteur=1 |
| T03 | Deux manettes : deplacements independants et simultanes | OK | LANCE du=50 (2.5px x 20), EGIDE dv=35 (1.75px x 20) |
| T04 | Tirs simultanes des deux vaisseaux (et deplacement pendant le tir) | OK | projectiles LANCE max=5, EGIDE max=11 |
| T05 | Collision entre joueurs : contact physique, aucun degat, aucun blocage | OK | separation min=12px (corps 12px), vies 5->5, recul libre=25px |
| T06 | Ressource cooperative LIEN : remplissage par destructions et vol en formation | OK | jauge 0->10 en 160 images de vol en formation (attendu ~10) |
| T07 | Attaque combinee : FAISCEAU DE LIAISON entre les deux vaisseaux | OK | beam_t=148, points v=[75,90,105,120,135,150,165,180], ennemi detruit=true |
| T08 | Solo : la jauge pleine declenche la NOVA (aucun partenaire requis) | OK | nova_t=22, ennemis restants=0, projectiles=0 |
| T09 | Coop : TRANSFERT D'ENERGIE ramene un partenaire sans vie | OK | EGIDE en vol=1 |
| T10 | Scrolling horizontal : contenu VRAM conforme a la carte sur tout le niveau | OK | 16224 tuiles verifiees, 0 erreurs, camera finale=1760 |
| T11 | Scrolling vertical : contenu VRAM conforme a la carte sur tout le niveau | OK | 13312 tuiles verifiees, 0 erreurs, HUD intact=true, camera=1536 |
| T12 | Ennemis et projectiles : apparition des 4 familles, tirs ennemis | OK | familles vues=[1,2,3,4], ennemis simultanes max=10, projectiles ennemis max=9 |
| T13 | Mini-boss : apparition, 2 phases, destruction, niveau libere | OK | apparu=true, phase2=true, projectiles max=16, etat apres destruction=2, enchainement secteur 2=true |
| T14 | Perte de vie, reapparition invulnerable, game over et retour au titre | OK | vies initiales=3, pertes=4, game over=true, retour titre=true |
| T15 | Armes evolutives : capsule ramassee -> niveau +1, perte de vie -> niveau -1 | OK | niveaux 1->2->3, apres perte=2, projectiles max (niv.3)=16 |
| T16 | Musique : sequence jouee sur pulse 1/2, triangle, bruit et DPCM | OK | ecritures periode P1=22 P2=89 TRI=39 BRUIT=39, declenchements DPCM=15, registres APU utilises=19 |
| T17 | Effets sonores : plusieurs SFX distincts declenches en jeu | OK | 6 effets distincts : SHOT_A, SHOT_B, HIT, EXPLODE, POWERUP, BEAM |
| T18 | Sauvegarde : record ecrit en PRG-RAM, relu apres coupure, copie corrompue toleree | OK | signature=SPTL, relu=042420, copie A corrompue -> 042420, vierge -> 005000 |
| T19 | Performances : scene chargee (2 joueurs niv.3, 10 ennemis, 16 tirs ennemis, boss, faisceau) | OK | vblank utilise max=1237/2273 cycles, cycles/image max=28012 moy=24456 (budget NTSC 29780 = 94 %), images perdues=0, sprites/ligne max=10, images avec >8 sprites/ligne=296/595, OAM saturee=599 |
| T20 | Performances : partie normale (secteur 1 complet a 2 joueurs) | OK | cycles/image max=19800 moy=13731, images perdues=0, vblank utilise max=1237/2273 cycles |
| T21 | PAL : compensation 6/5 de la logique (cadence de jeu identique a 60 Hz) | OK | camera +600 px en 500 images a 50 Hz (attendu 600 = 10 s de jeu). Logique seule : jsnes emule uniquement le NTSC. |
| T22 | Compilation reproductible : deux constructions identiques octet pour octet | OK | sha256=729018f21be53fad... |

## Mesures

```json
{
  "cam_h_end": 1760,
  "maxEnemies": 10,
  "maxEnemyBullets": 9,
  "stressMaxCycles": 28012,
  "stressAvgCycles": 24456,
  "stressLag": 0,
  "spLineMax": 10,
  "framesOver": 296,
  "sprFull": 599,
  "stressFrames": 595,
  "stressVblankMax": 1237,
  "normalMaxCycles": 19800,
  "normalAvgCycles": 13731,
  "normalLag": 0,
  "normalVblankMax": 1237,
  "sha256": "729018f21be53fadbf0bf6d7987f6881a0e7ec28ebbbf584e16181ec1b3d5bad",
  "romSize": 98320
}
```
