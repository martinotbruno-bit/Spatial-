# Fabrication de la cartouche — état et marche à suivre

> **Statut honnête.** Ce dépôt fournit la ROM, les images à programmer et
> leurs sommes de contrôle, ainsi que la liste des composants et les
> procédures. Il **ne fournit pas** de schéma PCB, de nomenclature validée ni
> de fichiers Gerber : ils n'ont pas pu être conçus ni vérifiés sans
> matériel (CDC §15.3). Aucune cartouche n'a été fabriquée ni testée.

## 1. Cible matérielle

| Élément | Valeur |
|---|---|
| Mapper | MMC3 (mapper iNES 4), configuration de type **NES-TKROM** |
| PRG-ROM | 256 Kio (32 bancs de 8 Kio) |
| CHR-ROM | 64 Kio (64 bancs de 1 Kio) |
| PRG-RAM | 8 Kio, **sauvegardée par pile** (`$6000-$7FFF`) |
| Miroir | piloté par le MMC3 (registre `$A000`), le jeu utilise le miroir vertical |
| IRQ | compteur de lignes MMC3 (séparation HUD / zone de jeu) |
| Fonctions hors console | aucune (pas de coprocesseur, pas d'audio d'extension) |

La configuration TKROM accepte jusqu'à 512 Kio de PRG et 256 Kio de CHR : la
ROM actuelle y tient avec de la marge.

## 2. Images à programmer

```sh
make                                  # build/spatial.nes
python3 tools/split_rom.py            # build/cartouche/prg.bin, chr.bin, sommes.txt
python3 tools/split_rom.py build/spatial.nes build/cartouche --pad-chr
                                      # CHR dupliquée (128 Kio) pour une puce de 1 Mbit
```

`sommes.txt` donne taille, CRC32 et SHA-256 de chaque image : après
programmation, relire la puce et comparer.

## 3. Composants (nomenclature indicative — à valider)

| Fonction | Choix possibles | Remarques |
|---|---|---|
| Mapper MMC3 | MMC3B / MMC3C de récupération (cartouche TKROM ou TSROM donneuse), ou clone CPLD/FPGA de MMC3 | Les MMC3 ne sont plus fabriqués. Un clone doit reproduire le comportement du compteur IRQ (variantes « A12 ») : **à valider sur console**, l'IRQ est critique pour le HUD |
| PRG-ROM 2 Mbit | EPROM 27C020 (UV) ou flash parallèle 39SF020A | 32 broches ; vérifier la correspondance des broches avec le support du PCB |
| CHR-ROM | EPROM 27C512 (64 Kio) ou 1 Mbit (27C010 / 39SF010A) avec image dupliquée (`--pad-chr`) | Selon le support CHR du PCB |
| PRG-RAM | SRAM 6264 (8 Kio) ou 62256 (lignes hautes à la masse) | Alimentation commutée pile / console |
| Sauvegarde | pile CR2032 + support, diode Schottky (BAT85 ou équivalent), résistance série (≈ 1 kΩ) | Isolation de la pile quand la console est allumée |
| Découplage | condensateurs 100 nF près de chaque circuit intégré | |
| Verrouillage 10NES | CIC de récupération ou clone du CIC | Nécessaire sur NES « frontloader » ; non requis sur Famicom / NES-101 |
| Boîtier | coque 72 broches standard | |

## 4. PCB

Non produit. Démarche recommandée :

1. partir d'un **schéma TKROM de référence publié** (cartouche d'origine
   relevée ou carte de reproduction open source) plutôt que de le recréer ;
2. reprendre le routage (KiCad), générer Gerber et nomenclature, faire
   relire la correspondance des broches mémoire avant fabrication ;
3. versionner ces fichiers dans `fabrication/` avec la révision de ROM
   (SHA-256) qu'ils accompagnent — CDC §16.6 : les fichiers doivent
   correspondre exactement à la ROM validée.

## 5. Programmation

Avec un programmateur universel (par exemple TL866II / T48 et `minipro`) :

```sh
minipro -p <reference exacte de la puce PRG> -w build/cartouche/prg.bin
minipro -p <reference exacte de la puce CHR> -w build/cartouche/chr.bin
```

puis relecture (`-r`) et comparaison avec `sommes.txt`.

**Mémoire de sauvegarde** : aucune programmation nécessaire. Au premier
démarrage, le jeu ne trouve pas de sauvegarde valide (signature + somme de
contrôle) et écrit lui-même les valeurs par défaut dans ses deux copies.

## 6. Validation sur matériel (à réaliser)

| Point | Pourquoi | Test associé en émulation |
|---|---|---|
| Séparation HUD / zone de jeu, sans artefact | timing IRQ MMC3 réel (jsnes est approximatif) | T10, T11 |
| Lecture des manettes pendant le DPCM | conflit DMC / `$4016` non émulé par jsnes | T16 |
| Sauvegarde après coupures répétées en cours d'écriture | double copie + somme de contrôle | T18 |
| Console PAL | compensation 6/5, tables de périodes audio | T21 (logique seule) |
| Plusieurs révisions de NES, Famicom, deux manettes | compatibilité générale | — |
| Scène chargée | 92-96 % du budget CPU en émulation | T19 |

Consigner les résultats dans `docs/RESULTATS_TESTS.md` (section matériel) et
la matrice de compatibilité de `docs/CONFORMITE.md`.
