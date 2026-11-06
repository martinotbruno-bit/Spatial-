# Registre des risques (fin de Phase 1)

| # | Risque | Niveau | État / réponse |
|---|---|---|---|
| R1 | Trop de sprites par ligne | Moyen | Rotation de l'OAM en place (clignotement réparti) ; règle de script ≤ 8 ennemis, ≤ 12 projectiles ennemis |
| R2 | Charge CPU excessive | **Élevé** | Stress = 94 % du budget NTSC. Optimisations faites ; règle de densité de script ; profilage automatique à chaque compilation |
| R3 | Écart NTSC/PAL | Moyen | Compensation 6/5 testée (logique uniquement). En PAL, ralentissement probable 1 image sur 5 dans les pires scènes. **Non testé sur console PAL** |
| R4 | Séparation HUD instable sur matériel | Moyen | Méthode `$2006/$2005` standard, rangée tampon vide sous le HUD. **Timing non vérifié sur console** (jsnes approximatif) ; à valider dans Mesen puis sur console |
| R5 | Conflit DPCM / lecture manettes | Faible | Double lecture jusqu'à concordance. À valider sur console (bug matériel non émulé par jsnes) |
| R6 | Sauvegarde instable (coupure) | Faible | Double copie + somme de contrôle + protection en écriture ; test de corruption en émulation. Coupure réelle non testée |
| R7 | Manque de mémoire | Moyen | Banc fixe `$C000` à 95 % ; 32 Kio PRG libres, cible finale 256-512 Kio |
| R8 | Lisibilité (projectiles sur décor) | Moyen | Projectiles ennemis en palette blanc/rouge à contour ; à revoir avec les décors définitifs |
| R9 | Incompatibilité cartouche | Moyen | Carte TKROM standard ; PCB/BOM/Gerber non produits (Phase 5) |
| R10 | Durée de campagne | Moyen | 8 secteurs proposés (GDD §6) ; à recalibrer après la tranche verticale |
