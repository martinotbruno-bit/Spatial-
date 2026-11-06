# Équilibrage du secteur 1 (tranche verticale)

> Mesures **en émulation** par un **pilote automatique** (`tests/bot.js`,
> `tests/balance.js`, 3 parties par case). Le bot n'est pas un joueur humain :
> il voit tout l'état du jeu, mais ne décide que toutes les N images et fait des
> erreurs volontaires. Ces chiffres servent à **comparer** les réglages entre
> eux ; le ressenti doit être validé par des parties humaines.

## Profils du pilote automatique

| Profil | Réaction | Erreurs | Intention |
|---|---|---|---|
| Joueur moyen | 12 images (~200 ms) | 25 % des décisions | Joueur habitué aux shoot'em up |
| Débutant | 18 images (~300 ms) | 40 % des décisions | Premier contact avec le genre |

## Paramètres par difficulté

| Paramètre | RECRUE | PILOTE | VÉTÉRAN | EXPERT* |
|---|---|---|---|---|
| Vies solo / coop | 5 / 7 | 3 / 5 | 2 / 4 | 2 / 3 |
| Tirs visés | lents (1,25 px/img) | rapides (2 px/img) | rapides | rapides |
| Tourelles | 1 tir / 128 img | 1 / 64 | 1 / 64 | 1 / 32 |
| Chasseurs | 2 tirs | 2 tirs | 3 tirs | 3 tirs |
| PV du boss / seuil phase 2 | 180 / 90 | 250 / 125 | 250 / 125 | 250 / 170 |
| Boss phase 1 : gerbe de 3 tous les | 128 img | 64 img | 64 img | 64 img |
| Boss phase 2 : cycle / gerbe / tirs visés | 72 / 3 / 1 | 56 / 5 / 2 | 40 / 5 / 3 | 34 / 5 / 3 |

\* EXPERT : débloqué en terminant la campagne (enregistré dans la cartouche).

## Mesures — joueur moyen

| Mode | Difficulté | Vies | Pertes moy. | Secteur réussi | Durée boss | Ennemis abattus | Tirs ennemis (moy./max) |
|---|---|---|---|---|---|---|---|
| Solo LANCE | RECRUE | 5 | 3.0 | 3/3 | 32 s | 59 | 4.0 / 11 |
| Solo LANCE | PILOTE | 3 | 2.0 | 2/3 | 38 s | 63 | 6.9 / 16 |
| Solo LANCE | VETERAN | 2 | 2.0 | 0/3 | - | 63 | 5.8 / 16 |
| Solo EGIDE | RECRUE | 5 | 2.0 | 3/3 | 38 s | 63 | 4.0 / 11 |
| Solo EGIDE | PILOTE | 3 | 2.7 | 2/3 | 56 s | 64 | 7.0 / 16 |
| Solo EGIDE | VETERAN | 2 | 2.0 | 1/3 | 52 s | 62 | 5.9 / 16 |
| Coop | RECRUE | 7 | 2.0 | 3/3 | 25 s | 64 | 3.3 / 11 |
| Coop | PILOTE | 5 | 3.7 | 3/3 | 34 s | 64 | 5.7 / 16 |
| Coop | VETERAN | 4 | 4.7 | 2/3 | 35 s | 65 | 5.9 / 16 |

## Mesures — débutant

| Mode | Difficulté | Vies | Pertes moy. | Secteur réussi | Durée boss | Ennemis abattus | Tirs ennemis (moy./max) |
|---|---|---|---|---|---|---|---|
| Solo LANCE | RECRUE | 5 | 5.0 | 0/3 | - | 43 | 3.5 / 11 |
| Solo LANCE | PILOTE | 3 | 3.0 | 0/3 | - | 37 | 2.9 / 11 |
| Solo LANCE | VETERAN | 2 | 2.0 | 0/3 | - | 30 | 2.4 / 11 |
| Solo EGIDE | RECRUE | 5 | 2.7 | 3/3 | 47 s | 56 | 3.9 / 11 |
| Solo EGIDE | PILOTE | 3 | 3.0 | 0/3 | - | 57 | 5.2 / 16 |
| Solo EGIDE | VETERAN | 2 | 2.0 | 0/3 | - | 55 | 2.6 / 10 |
| Coop | RECRUE | 7 | 5.3 | 3/3 | 31 s | 64 | 3.6 / 11 |
| Coop | PILOTE | 5 | 6.0 | 0/3 | - | 63 | 3.2 / 11 |
| Coop | VETERAN | 4 | 5.0 | 0/3 | - | 59 | 2.8 / 11 |

## Constats et décisions

1. **Avant réglage**, 49 pertes sur 57 avaient lieu pendant le combat contre
   le boss (phase 2 : gerbe de 5 toutes les 40 images + 3 tirs visés, quelle
   que soit la difficulté). Le niveau lui-même était bien dosé. → Motifs du
   boss paramétrés par difficulté (tableau ci-dessus).
2. **Après réglage**, la progression est monotone pour le joueur moyen :
   RECRUE réussi dans tous les modes, PILOTE réussi 2 fois sur 3 en solo et
   systématiquement en coopération, VÉTÉRAN rarement réussi en solo.
   Conforme au CDC : « accessible au début, de plus en plus exigeant ».
3. **La coopération est plus facile que le solo** à difficulté égale (plus de
   vies, deux sources de tir, Faisceau). C'est voulu pour le secteur 1 ; à
   surveiller dans les secteurs suivants pour que le solo reste équilibré
   (CDC §2.3).
4. **ÉGIDE est le vaisseau le plus accessible pour un débutant** (RECRUE
   réussi 3/3 contre 0/3 pour LANCE) : son éventail détruit les ennemis avant
   qu'ils tirent, alors que la vitesse de LANCE amplifie les erreurs de
   pilotage. En contrepartie ÉGIDE met plus de temps à abattre le boss
   (47-56 s contre 32-38 s). Les deux vaisseaux restent complémentaires
   (CDC §3.2). Piste : signaler ÉGIDE comme « recommandé aux débutants »
   dans l'écran de sélection.
5. Le débutant échoue en PILOTE : normal pour la difficulté par défaut d'un
   jeu « exigeant » ; RECRUE existe pour lui.

## À faire

- Parties humaines sur la ROM (en émulateur puis sur console) pour confirmer
  ces tendances, en particulier la lisibilité des gerbes du boss.
- Rejouer `node tests/balance.js moyen` après chaque modification de
  script ou de motif (≈ 5 min).
