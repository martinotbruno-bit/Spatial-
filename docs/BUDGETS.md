# Budgets techniques — définis et mesurés en Phase 1

Mesures réalisées **en émulation** (jsnes 1.2.1, NTSC) par les tests T19/T20.
La précision de jsnes sur la synchronisation fine n'est pas celle d'une
console : ces valeurs doivent être confirmées sur matériel (Phase 5) ou dans
un émulateur de référence (Mesen) avant la Phase 3.

## Référence matérielle

| Grandeur | NTSC | PAL |
|---|---|---|
| Cycles CPU par image | 29 780 | 33 247 |
| Cycles de retour de trame (vblank) | ~2 273 | ~7 459 |
| DMA OAM | 513 cycles | 513 cycles |

## Budgets fixés

| Poste | Budget | Mesuré (pire cas) | Marge |
|---|---|---|---|
| Écritures PPU dans le NMI (DMA + tampon VRAM) | ≤ 1 800 cycles | 1 530 (colonne + 7 attributs) | 15 % |
| Tampon VRAM par image | ≤ 96 octets | 29 (colonne) + 28 (attributs) + 4 (palette) + 1 = 62 ; le HUD (39) attend une image sans décor | 35 % |
| CPU par image, partie normale | ≤ 70 % (20 800) | 19 076 (64 %), moyenne 13 518 | ✔ |
| CPU par image, scène de stress | ≤ 100 % (29 780) | 26 756 (90 %), moyenne 23 226 | 10 % — à surveiller |
| Ennemis actifs | 10 | 10 | — |
| Projectiles ennemis | 16 | 16 | — |
| Projectiles joueurs | 16 (2 × 8 en moyenne) | 16 | — |
| Sprites matériels | 64 | 64 (saturé en stress) | — |
| Sprites par ligne | 8 (au-delà : clignotement réparti) | 10 en stress, ≤ 8 en jeu normal la plupart du temps | — |
| Mise à jour du HUD | 1 image sur 4 max | — | — |
| RAM | 1 280 o (`$0300-$07FF`) | 646 | 50 % |
| Page zéro | 256 o | 80 | 69 % |

## Scène de stress (T19)

Deux joueurs en arme niveau 3 tirant en continu, 10 ennemis de toutes
familles tirant, 16 projectiles ennemis, mini-boss actif, Faisceau de
Liaison permanent. Résultat : **0 image perdue sur 600**, 94 % du budget.

Optimisations déjà appliquées pour y parvenir (avant : 175 images perdues
sur 600) :

1. chemin rapide de dessin pour les objets 8×8 (projectiles, faisceau) ;
2. test des projectiles joueurs contre les ennemis/boss par moitiés
   alternées (sans traversée possible : 14 px entre deux tests < fenêtre de
   18 px) ;
3. HUD rafraîchi au plus une image sur quatre ;
4. faisceau : ennemis et projectiles testés une image sur deux ;
5. (Phase 2) chemin rapide déroulé pour les objets 16×16 entièrement
   visibles : 97 % → 90 % en stress. Il n'est pris que si les 4 entrées
   ne rebouclent pas en fin d'OAM (sinon débordement sur `$0300`, défaut
   détecté par les tests T10/T11/T29 et corrigé).

## Points de vigilance

- **PAL** : la mise à jour logique double (une image sur 5) dépasse le
  budget dans la scène de stress (~2 × 22 000 cycles > 33 247). Effet attendu :
  une image ralentie sur 5 dans les pires scènes, sans incohérence. Piste
  Phase 2 : ne pas doubler la mise à jour quand l'image précédente a été
  chargée (compensation lissée sur plusieurs images).
- La scène de stress est volontairement pire que ce que les scripts
  produisent. Règle de conception pour la Phase 3 : **au plus 8 ennemis et
  12 projectiles ennemis simultanés** dans les scripts, pour conserver
  ≥ 15 % de marge CPU.
- Profileur : `tests/` mesure les cycles entre le NMI et le marqueur `$5FF0`
  (DMA OAM inclus).
