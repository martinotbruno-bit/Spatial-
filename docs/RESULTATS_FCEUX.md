# Résultats dans FCEUX 2.6.5 (émulation)

> Généré par `tests/run_fceux.js` : campagne complète jouée par script Lua dans
> FCEUX, avec l'ancien et le nouveau moteur PPU. **Émulation uniquement** —
> aucun test sur console.

## ancien PPU

Démarrage : `boot etat=0 region=0 lag=0` — durée 190 s — script terminé : true

| Secteur | Défilement | Résultat | Images perdues (700 img) | Tuiles + attributs vérifiés | Erreurs | HUD | Boss / transition |
|---|---|---|---|---|---|---|---|
| 1 | horizontal | OK | 0 | 888 | 0 | intact | boss=2, état après=5, page=1 |
| 2 | vertical | OK | 0 | 1248 | 0 | intact | boss=2, état après=5, page=2 |
| 3 | horizontal | OK | 0 | 888 | 0 | intact | boss=2, état après=5, page=3 |
| 4 | vertical | OK | 0 | 1248 | 0 | intact | boss=2, état après=5, page=4 |
| 5 | horizontal | OK | 0 | 888 | 0 | intact | boss=2, état après=5, page=5 |
| 6 | vertical | OK | 0 | 1248 | 0 | intact | boss=2, état après=5, page=6 |
| 7 | horizontal | OK | 0 | 888 | 0 | intact | boss=2, état après=5, page=7 |
| 8 | horizontal | OK | 0 | 888 | 0 | intact | boss=2, état après=5, page=8 |

Fin de campagne : `fin page=8 etat_final=0 debloques=255` → OK

## nouveau PPU

Démarrage : `boot etat=0 region=0 lag=0` — durée 190 s — script terminé : true

| Secteur | Défilement | Résultat | Images perdues (700 img) | Tuiles + attributs vérifiés | Erreurs | HUD | Boss / transition |
|---|---|---|---|---|---|---|---|
| 1 | horizontal | OK | 0 | 888 | 0 | intact | boss=2, état après=5, page=1 |
| 2 | vertical | OK | 0 | 1248 | 0 | intact | boss=2, état après=5, page=2 |
| 3 | horizontal | OK | 0 | 888 | 0 | intact | boss=2, état après=5, page=3 |
| 4 | vertical | OK | 0 | 1248 | 0 | intact | boss=2, état après=5, page=4 |
| 5 | horizontal | OK | 0 | 888 | 0 | intact | boss=2, état après=5, page=5 |
| 6 | vertical | OK | 0 | 1248 | 0 | intact | boss=2, état après=5, page=6 |
| 7 | horizontal | OK | 0 | 888 | 0 | intact | boss=2, état après=5, page=7 |
| 8 | horizontal | OK | 0 | 888 | 0 | intact | boss=2, état après=5, page=8 |

Fin de campagne : `fin page=8 etat_final=0 debloques=255` → OK

Captures : `docs/captures/fceux/` (planche : `planche_fceux.png`).
