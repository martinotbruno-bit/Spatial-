#!/usr/bin/env python3
"""Prepare les images a programmer sur cartouche a partir de la ROM iNES.

Usage : python3 tools/split_rom.py [build/spatial.nes] [dossier_sortie]

Produit dans le dossier de sortie (defaut : build/cartouche/) :
  prg.bin        PRG-ROM (256 Kio) -> memoire programme (ex. 27C020 / SST39SF020A)
  chr.bin        CHR-ROM (64 Kio)  -> memoire graphique  (ex. 27C512 / SST39SF010A
                 apres duplication, voir --pad-chr)
  sommes.txt     tailles, CRC32 et SHA-256 de chaque image (a verifier apres
                 programmation par relecture de la puce)

Verifie l'en-tete : signature, mapper 4 (MMC3), PRG-RAM sur pile, tailles.
"""
import hashlib
import os
import sys
import zlib


def main():
    rom = sys.argv[1] if len(sys.argv) > 1 else "build/spatial.nes"
    out = sys.argv[2] if len(sys.argv) > 2 else "build/cartouche"
    pad_chr = "--pad-chr" in sys.argv
    data = open(rom, "rb").read()
    if data[:4] != b"NES\x1a":
        raise SystemExit("signature iNES absente")
    prg_n, chr_n, f6, f7 = data[4], data[5], data[6], data[7]
    mapper = (f6 >> 4) | (f7 & 0xF0)
    battery = bool(f6 & 2)
    if mapper != 4:
        raise SystemExit(f"mapper {mapper} : MMC3 (4) attendu")
    prg = data[16:16 + prg_n * 16384]
    chr_ = data[16 + prg_n * 16384:16 + prg_n * 16384 + chr_n * 8192]
    if len(prg) != prg_n * 16384 or len(chr_) != chr_n * 8192:
        raise SystemExit("ROM tronquee")
    if pad_chr:
        # une puce plus grande que la CHR : repetition de l'image (les lignes
        # d'adresse hautes inutilisees restent sans effet)
        chr_ = chr_ * 2
    os.makedirs(out, exist_ok=True)
    lines = [f"ROM source : {rom}", f"mapper {mapper} (MMC3), PRG-RAM sur pile : {'oui' if battery else 'non'}", ""]
    for name, blob in (("prg.bin", prg), ("chr.bin", chr_)):
        open(os.path.join(out, name), "wb").write(blob)
        lines.append(f"{name:8} {len(blob):7} octets  CRC32 {zlib.crc32(blob) & 0xFFFFFFFF:08X}  "
                     f"SHA-256 {hashlib.sha256(blob).hexdigest()}")
    open(os.path.join(out, "sommes.txt"), "w").write("\n".join(lines) + "\n")
    print("\n".join(lines))


if __name__ == "__main__":
    main()
