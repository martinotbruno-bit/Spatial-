#!/usr/bin/env python3
"""Generateur de ressources du Projet SPATIAL (NES).

Produit, de facon deterministe (meme entree -> memes octets) :
  build/chr.bin      CHR-ROM (32 Kio : table BG + table sprites, bancs MMC3)
  build/assets.inc   donnees ca65 : palettes, cartes de niveaux, musique, SFX,
                     tables de periodes NTSC/PAL, constantes de tuiles
  build/kick.dmc     echantillon DPCM (grosse caisse) synthetise

Sources : assets/sprites.txt, assets/tiles.txt, assets/music.txt
"""
import math
import os
import random
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(ROOT, "assets")
BUILD = os.path.join(ROOT, "build")


# ---------------------------------------------------------------- art -------
def load_art(path):
    """Lit un fichier d'art -> liste ordonnee de (nom, matrice de pixels)."""
    items = []
    cur = None
    with open(path, encoding="utf-8") as f:
        for lineno, raw in enumerate(f, 1):
            line = raw.rstrip("\n").rstrip()
            if line.startswith("#") or (not line and cur is None):
                continue
            if line.startswith("@"):
                name, w, h = line[1:].split()
                cur = {"name": name, "w": int(w), "h": int(h), "rows": [], "line": lineno}
                items.append(cur)
                continue
            if not line:
                continue
            if cur is None:
                raise SystemExit(f"{path}:{lineno}: pixels hors bloc")
            if len(line) != cur["w"]:
                raise SystemExit(f"{path}:{lineno}: largeur {len(line)} != {cur['w']} ({cur['name']})")
            cur["rows"].append([0 if c == "." else int(c) for c in line])
    out = []
    for it in items:
        if len(it["rows"]) != it["h"]:
            raise SystemExit(f"{path}:{it['line']}: hauteur {len(it['rows'])} != {it['h']} ({it['name']})")
        out.append((it["name"], it["rows"]))
    return out


def rot_ccw(img):
    """Rotation de 90 degres anti-horaire : l'avant (droite) passe vers le haut."""
    h = len(img)
    w = len(img[0])
    return [[img[y][w - 1 - x] for y in range(h)] for x in range(w)]


def split_tiles(img):
    """Decoupe une image en tuiles 8x8, ordre ligne par ligne."""
    tiles = []
    for ty in range(0, len(img), 8):
        for tx in range(0, len(img[0]), 8):
            tiles.append([row[tx:tx + 8] for row in img[ty:ty + 8]])
    return tiles


def encode_tile(t):
    lo = bytearray(8)
    hi = bytearray(8)
    for y in range(8):
        for x in range(8):
            p = t[y][x]
            if p & 1:
                lo[y] |= 0x80 >> x
            if p & 2:
                hi[y] |= 0x80 >> x
    return bytes(lo + hi)


# 5x7 font (colonnes de 5 bits, ligne par ligne) - dessinee pour le projet.
FONT = {
    "0": ["01110", "10001", "10011", "10101", "11001", "10001", "01110"],
    "1": ["00100", "01100", "00100", "00100", "00100", "00100", "01110"],
    "2": ["01110", "10001", "00001", "00110", "01000", "10000", "11111"],
    "3": ["11110", "00001", "00001", "01110", "00001", "00001", "11110"],
    "4": ["00010", "00110", "01010", "10010", "11111", "00010", "00010"],
    "5": ["11111", "10000", "11110", "00001", "00001", "10001", "01110"],
    "6": ["00110", "01000", "10000", "11110", "10001", "10001", "01110"],
    "7": ["11111", "00001", "00010", "00100", "01000", "01000", "01000"],
    "8": ["01110", "10001", "10001", "01110", "10001", "10001", "01110"],
    "9": ["01110", "10001", "10001", "01111", "00001", "00010", "01100"],
    "A": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
    "B": ["11110", "10001", "10001", "11110", "10001", "10001", "11110"],
    "C": ["01110", "10001", "10000", "10000", "10000", "10001", "01110"],
    "D": ["11110", "10001", "10001", "10001", "10001", "10001", "11110"],
    "E": ["11111", "10000", "10000", "11110", "10000", "10000", "11111"],
    "F": ["11111", "10000", "10000", "11110", "10000", "10000", "10000"],
    "G": ["01110", "10001", "10000", "10111", "10001", "10001", "01111"],
    "H": ["10001", "10001", "10001", "11111", "10001", "10001", "10001"],
    "I": ["01110", "00100", "00100", "00100", "00100", "00100", "01110"],
    "J": ["00111", "00010", "00010", "00010", "00010", "10010", "01100"],
    "K": ["10001", "10010", "10100", "11000", "10100", "10010", "10001"],
    "L": ["10000", "10000", "10000", "10000", "10000", "10000", "11111"],
    "M": ["10001", "11011", "10101", "10101", "10001", "10001", "10001"],
    "N": ["10001", "10001", "11001", "10101", "10011", "10001", "10001"],
    "O": ["01110", "10001", "10001", "10001", "10001", "10001", "01110"],
    "P": ["11110", "10001", "10001", "11110", "10000", "10000", "10000"],
    "Q": ["01110", "10001", "10001", "10001", "10101", "10010", "01101"],
    "R": ["11110", "10001", "10001", "11110", "10100", "10010", "10001"],
    "S": ["01111", "10000", "10000", "01110", "00001", "00001", "11110"],
    "T": ["11111", "00100", "00100", "00100", "00100", "00100", "00100"],
    "U": ["10001", "10001", "10001", "10001", "10001", "10001", "01110"],
    "V": ["10001", "10001", "10001", "10001", "10001", "01010", "00100"],
    "W": ["10001", "10001", "10001", "10101", "10101", "10101", "01010"],
    "X": ["10001", "10001", "01010", "00100", "01010", "10001", "10001"],
    "Y": ["10001", "10001", "01010", "00100", "00100", "00100", "00100"],
    "Z": ["11111", "00001", "00010", "00100", "01000", "10000", "11111"],
    ":": ["00000", "01100", "01100", "00000", "01100", "01100", "00000"],
    "-": ["00000", "00000", "00000", "11111", "00000", "00000", "00000"],
    ".": ["00000", "00000", "00000", "00000", "00000", "01100", "01100"],
    "!": ["00100", "00100", "00100", "00100", "00100", "00000", "00100"],
    "?": ["01110", "10001", "00001", "00110", "00100", "00000", "00100"],
    "/": ["00001", "00010", "00010", "00100", "01000", "01000", "10000"],
    "(": ["00010", "00100", "01000", "01000", "01000", "00100", "00010"],
    ")": ["01000", "00100", "00010", "00010", "00010", "00100", "01000"],
    ">": ["01000", "00100", "00010", "00001", "00010", "00100", "01000"],
    "<": ["00010", "00100", "01000", "10000", "01000", "00100", "00010"],
    "'": ["00100", "00100", "01000", "00000", "00000", "00000", "00000"],
    ",": ["00000", "00000", "00000", "00000", "01100", "00100", "01000"],
    "=": ["00000", "00000", "11111", "00000", "11111", "00000", "00000"],
    "+": ["00000", "00100", "00100", "11111", "00100", "00100", "00000"],
}


def font_tile(ch, color=1):
    t = [[0] * 8 for _ in range(8)]
    g = FONT.get(ch)
    if g:
        for y, row in enumerate(g):
            for x, b in enumerate(row):
                if b == "1":
                    t[y][x + 1] = color
    return t


def bar_tile(fill, color):
    """Tuile de jauge : cadre (couleur 1) + remplissage de `fill` pixels (0-8)."""
    t = [[0] * 8 for _ in range(8)]
    for x in range(8):
        t[1][x] = 1
        t[6][x] = 1
    for y in range(2, 6):
        for x in range(8):
            t[y][x] = color if x < fill else 0
    return t


# ------------------------------------------------------------- tuiles -------
# Disposition de la CHR-ROM (unites de 1 Kio, bancs MMC3) :
#   0-1   decor commun $00-$7F (police, jauges)        -> R0 = 0
#   2+2k  decor du secteur k, tuiles $80-$FF (2 Kio)   -> R1
#   16-18 sprites communs $00-$BF                       -> R2-R4 = 16,17,18
#   19+k  sprites du jeu de secteur k, $C0-$FF (1 Kio)  -> R5
CHR_BG_COMMON = 0
CHR_SPR_COMMON = 16
CHR_SPR_SECTOR = 19


def blank_tiles(n):
    return [[[0] * 8 for _ in range(8)] for _ in range(n)]


def put_big(spr, consts, art, name, base, orient, prefix="S_"):
    img = art[name]
    ts = split_tiles(img)
    for k, t in enumerate(ts):
        spr[base + k] = t
    consts[prefix + name.upper() + "_H"] = base
    if orient:
        # vue de dessus dediee si elle existe, sinon rotation de 90 degres
        ts2 = split_tiles(art[name + "_top"] if name + "_top" in art else rot_ccw(img))
        vbase = base + len(ts)
        for k, t in enumerate(ts2):
            spr[vbase + k] = t
        consts[prefix + name.upper() + "_V"] = vbase
    else:
        consts[prefix + name.upper() + "_V"] = base


def build_common(consts):
    bg = blank_tiles(128)
    spr = blank_tiles(192)
    for code in range(0x20, 0x60):
        bg[code] = font_tile(chr(code))
        spr[code] = font_tile(chr(code))
    for k in range(9):
        bg[0x60 + k] = bar_tile(k, 2)   # jauge LIEN
        bg[0x69 + k] = bar_tile(k, 3)   # barre du boss
    consts["T_GAUGE0"] = 0x60
    consts["T_BOSSBAR0"] = 0x69
    art = dict(load_art(os.path.join(ASSETS, "sprites.txt")))
    small = [("shot_a", True), ("shot_b", True), ("ebullet", False),
             ("capsule", False), ("beam", False)]
    idx = 0x01
    for name, orient in small:
        img = art[name]
        spr[idx] = img
        consts["S_" + name.upper() + "_H"] = idx
        consts["S_" + name.upper() + "_V"] = idx + (1 if orient else 0)
        if orient:
            spr[idx + 1] = rot_ccw(img)
            idx += 2
        else:
            idx += 1
    big = [("heavy", 0x60, True),
           ("ship_a", 0x80, True), ("ship_b", 0x88, True), ("drone", 0x90, True),
           ("fighter", 0x98, True), ("turret", 0xA0, True), ("kamikaze", 0xA8, True),
           ("explo1", 0xB0, False), ("explo2", 0xB4, False), ("explo3", 0xB8, False)]
    for name, base, orient in big:
        put_big(spr, consts, art, name, base, orient)
    return bg, spr


def build_sector_sprites(fname):
    """Jeu de sprites de secteur (64 tuiles, $C0-$FF) : boss H/V, objet de decor."""
    spr = blank_tiles(64)
    art = dict(load_art(os.path.join(ASSETS, fname)))
    c = {}
    tmp = blank_tiles(256)
    put_big(tmp, c, art, "boss", 0xC0, True)
    put_big(tmp, c, art, "pod", 0xE0, False)
    return tmp[0xC0:0x100]


def build_sector_bg(fname):
    """Decor de secteur : tuiles $80-$FF ; renvoie (tuiles, constantes T_*)."""
    bg = blank_tiles(128)
    c = {}
    for i, (name, img) in enumerate(load_art(os.path.join(ASSETS, fname))):
        bg[i] = img
        c["T_" + name.upper()] = 0x80 + i
    return bg, c


# ------------------------------------------------------------- cartes -------
def gen_map_h(c):
    """Secteur 1 : station orbitale, colonnes de 26 tuiles (lignes 4-29)."""
    rng = random.Random(1234)
    cols = []
    ncols = 256
    star_cols = []
    for _ in range(8):
        col = [0] * 26
        for y in range(26):
            r = rng.random()
            if r < 0.05:
                col[y] = c["T_STAR1"]
            elif r < 0.08:
                col[y] = c["T_STAR2"]
            elif r < 0.09:
                col[y] = c["T_STAR3"]
        star_cols.append(col)
    for x in range(ncols):
        col = list(star_cols[rng.randrange(len(star_cols))])
        if 48 <= x < 200:
            seg = (x - 48) // 16
            top = [2, 3, 4, 3, 2, 3, 5, 4, 3, 2][seg % 10]
            bot = [3, 2, 3, 4, 5, 3, 2, 3, 4, 3][seg % 10]
            for y in range(top):
                col[y] = c["T_HULL"]
            col[top] = c["T_HULL_EDGE_DOWN"]
            for y in range(26 - bot, 26):
                col[y] = c["T_HULL"]
            col[25 - bot] = c["T_HULL_EDGE_UP"]
            if x % 4 == 3:
                col[0] = c["T_LIGHT"]
                col[25] = c["T_LIGHT"]
            if x % 16 in (6, 7, 8):
                col[1] = c["T_PIPE"]
            if x % 32 == 20:
                for y in range(top + 1, 25 - bot):
                    col[y] = c["T_GIRDER"] if (y % 2) else c["T_PYLON"]
        elif 200 <= x < 216:
            if x % 3 == 0:
                for y in (rng.randrange(2, 24), rng.randrange(2, 24)):
                    col[y] = c["T_GIRDER"]
        cols.append(col)
    return cols


def pal_s1(c, cols, x, y):
    t = cols[x][y]
    if t in (c["T_LIGHT"], c["T_PYLON"], c["T_GIRDER"]):
        return 3
    if t == c["T_PIPE"]:
        return 2
    if t in (c["T_HULL"], c["T_HULL_EDGE_DOWN"], c["T_HULL_EDGE_UP"]) and 48 <= x < 200 and ((x - 48) // 16) % 3 == 2:
        return 2
    return 0


def gen_map_belt(c):
    """Secteur 3 : Ceinture brisee. Bandes d'asteroides haute/basse d'epaisseur
    variable, champ central de rochers 16x16 et de cristaux. Les motifs sont
    tires dans un petit catalogue pour limiter le nombre de gabarits."""
    rng = random.Random(777)
    ncols = 256
    # motifs centraux sur 2 colonnes : liste de (rangee, type) ; 'B' = gros rocher
    field = []
    for _ in range(10):
        items = []
        for _ in range(rng.randrange(0, 3)):
            items.append((rng.randrange(6, 18), rng.choice("BBsc")))
        field.append(items)
    star = []
    for _ in range(4):
        col = [0] * 26
        for y in range(26):
            r = rng.random()
            if r < 0.05:
                col[y] = c["T_STAR1"]
            elif r < 0.08:
                col[y] = c["T_STAR2"]
        star.append(col)
    cols = []
    pat = None
    for x in range(ncols):
        col = list(star[(x * 7) % 4])
        if 24 <= x < 216:
            seg = (x - 24) // 8
            top = [1, 2, 3, 4, 3, 2, 3, 5, 4, 2, 1, 2][seg % 12]
            bot = [2, 3, 2, 1, 2, 4, 5, 3, 2, 3, 4, 2][seg % 12]
            for y in range(top):
                col[y] = c["T_ROCK_FILL"]
            col[top] = c["T_BAND_DOWN"]
            for y in range(26 - bot, 26):
                col[y] = c["T_ROCK_FILL"]
            col[25 - bot] = c["T_BAND_UP"]
            if x % 2 == 0:
                pat = field[rng.randrange(len(field))] if (x // 2) % 3 else []
            half = x % 2
            for (ry, kind) in pat:
                if kind == "B":
                    col[ry] = c["T_ROCK_TR" if half else "T_ROCK_TL"]
                    col[ry + 1] = c["T_ROCK_BR" if half else "T_ROCK_BL"]
                elif kind == "s" and not half:
                    col[ry] = c["T_ROCK_S"]
                elif kind == "c" and not half:
                    col[ry] = c["T_CRYSTAL"]
        cols.append(col)
    return cols


def pal_s3(c, cols, x, y):
    t = cols[x][y]
    if t == c["T_CRYSTAL"]:
        return 3
    if t in (c["T_ROCK_TL"], c["T_ROCK_TR"], c["T_ROCK_BL"], c["T_ROCK_BR"], c["T_ROCK_S"]):
        return 2
    return 0


def attrs_h(cols, palfn):
    """Attributs : une palette par bloc 16x16, priorite 3 > 2 > 0 dans un bloc.
    Sortie : 7 octets (rangees d'attributs 1-7) par groupe de 4 colonnes."""
    def cell(x, q):
        if q > 12:
            return 0
        return max(palfn(x + dx, 2 * q + dy) for dx in (0, 1) for dy in (0, 1))

    out = []
    for a in range(len(cols) // 4):
        for r in range(1, 8):
            q0, q1 = 2 * r - 2, 2 * r - 1
            x0 = 4 * a
            b = cell(x0, q0) | (cell(x0 + 2, q0) << 2) | (cell(x0, q1) << 4) | (cell(x0 + 2, q1) << 6)
            out.append(b)
    return out


def gen_map_v(c):
    """Secteur 2 : survol planetaire, lignes de 32 tuiles. Ligne 0 = bas (debut)."""
    rng = random.Random(4321)
    rows = []
    nrows = 232
    star_rows = []
    for _ in range(4):
        row = [0] * 32
        for x in range(32):
            r = rng.random()
            if r < 0.05:
                row[x] = c["T_STAR1"]
            elif r < 0.08:
                row[x] = c["T_STAR2"]
        star_rows.append(row)
    for y in range(nrows):
        row = [0] * 32
        if y < 30:
            row = list(star_rows[rng.randrange(len(star_rows))])
        elif y < 34:
            for x in range(32):
                row[x] = c["T_RIDGE"] if y == 30 else c["T_GROUND2"]
        else:
            for x in range(32):
                row[x] = c["T_GROUND"] if (x * 7 + y * 3) % 5 else c["T_GROUND2"]
            if rng.random() < 0.35:
                row[(5, 13, 19, 26)[rng.randrange(4)]] = c["T_CRATER"]
            if y % 24 == 10:
                row[:] = [c["T_RIDGE"]] * 32
            if 90 <= y < 150:
                base_l = 3 + ((y // 8) % 3)
                base_r = 28 - ((y // 8) % 3)
                row[base_l] = c["T_WALL"]
                row[base_r] = c["T_WALL"]
                if y % 12 == 0:
                    for x in range(base_l, base_r + 1):
                        row[x] = c["T_WALL"]
                if y % 12 == 6:
                    row[8] = c["T_PAD"]
                    row[23] = c["T_PAD"]
        rows.append(row)
    return rows


# Definition des secteurs (ordre de la campagne)
SECTORS = [
    dict(name="s1", title="Station Vesta", orient=0, bank=0, tiles="tiles_s1.txt",
         sprites="sprites_s1.txt", spr_set=0, gen=gen_map_h, palfn=pal_s1,
         cam_stop=1760, cp=896, song="stage", boss=1,
         pal=[0x0F, 0x00, 0x10, 0x3C, 0x0F, 0x30, 0x21, 0x16, 0x0F, 0x07, 0x17, 0x27, 0x0F, 0x01, 0x11, 0x31]),
    dict(name="s2", title="Surface de Kera", orient=1, bank=2, tiles="tiles_s2.txt",
         sprites="sprites_s1.txt", spr_set=0, gen=gen_map_v, palfn=None,
         cam_stop=1536, cp=768, song="stage", boss=1,
         pal=[0x0F, 0x08, 0x18, 0x38, 0x0F, 0x30, 0x21, 0x16, 0x0F, 0x08, 0x18, 0x38, 0x0F, 0x08, 0x18, 0x38]),
    dict(name="s3", title="Ceinture brisee", orient=0, bank=3, tiles="tiles_s3.txt",
         sprites="sprites_s3.txt", spr_set=1, gen=gen_map_belt, palfn=pal_s3,
         cam_stop=1760, cp=896, song="belt", boss=2,
         pal=[0x0F, 0x07, 0x17, 0x27, 0x0F, 0x30, 0x21, 0x16, 0x0F, 0x00, 0x2D, 0x10, 0x0F, 0x0C, 0x1C, 0x3C]),
]
# Palettes de sprites communes
SPR_PAL = [0x0F, 0x02, 0x21, 0x30, 0x0F, 0x06, 0x27, 0x38, 0x0F, 0x04, 0x14, 0x2A, 0x0F, 0x30, 0x27, 0x16]

ENEMY_NAMES = {"DRONE": 1, "CHASSEUR": 2, "TOURELLE": 3, "KAMIKAZE": 4, "DECOR": 5, "LOURDE": 6, "BOSS": 15}


def load_script(name):
    out = []
    last = -1
    with open(os.path.join(ASSETS, f"script_{name}.txt"), encoding="utf-8") as f:
        for lineno, raw in enumerate(f, 1):
            line = raw.split("#")[0].split()
            if not line:
                continue
            t, fam, v, p = int(line[0]), ENEMY_NAMES[line[1]], int(line[2]), int(line[3])
            if t < last:
                raise SystemExit(f"script_{name}.txt:{lineno}: declencheurs non tries")
            last = t
            out += [t, fam, v, p]
    out.append(0xFF)
    return out


def dedupe(lines):
    templates = []
    index = {}
    ids = []
    for ln in lines:
        k = tuple(ln)
        if k not in index:
            index[k] = len(templates)
            templates.append(ln)
        ids.append(index[k])
    if len(templates) > 255:
        raise SystemExit("trop de gabarits uniques")
    return templates, ids


# ------------------------------------------------------------- musique ------
NOTE_NAMES = {"C": 0, "Cs": 1, "D": 2, "Ds": 3, "E": 4, "F": 5, "Fs": 6, "G": 7,
              "Gs": 8, "A": 9, "As": 10, "B": 11}
CPU_NTSC = 1789773
CPU_PAL = 1662607
NOTE_BASE_MIDI = 33   # A1 = index 0
NUM_NOTES = 72


def midi_freq(m):
    return 440.0 * 2 ** ((m - 69) / 12.0)


def period_tables():
    out = {}
    for region, cpu in (("ntsc", CPU_NTSC), ("pal", CPU_PAL)):
        pulse = []
        tri = []
        for i in range(NUM_NOTES):
            f = midi_freq(NOTE_BASE_MIDI + i)
            pulse.append(max(8, min(2047, round(cpu / (16 * f) - 1))))
            tri.append(max(2, min(2047, round(cpu / (32 * f) - 1))))
        out[region] = (pulse, tri)
    return out


def expand(tokens):
    out = []
    i = 0
    while i < len(tokens):
        t = tokens[i]
        if t.startswith("["):
            depth = 0
            j = i
            while True:
                if tokens[j].startswith("["):
                    depth += tokens[j].count("[")
                if "]" in tokens[j]:
                    depth -= tokens[j].count("]")
                    if depth == 0:
                        break
                j += 1
            inner = " ".join(tokens[i:j + 1])
            m = re.match(r"^\[(.*)\]x(\d+)$", inner)
            if not m:
                raise SystemExit("repetition invalide: " + inner)
            sub = expand(m.group(1).split())
            out.extend(sub * int(m.group(2)))
            i = j + 1
        else:
            out.append(t)
            i += 1
    return out


DRUMS = {"K": 0, "S": 1, "H": 2}
# Instruments des canaux pulse (ordre = table ins_* de audio.s)
INSTRUMENTS = {"lead": 0, "arp": 1, "pluck": 2, "brass": 3, "pad": 4, "bell": 5}


def compile_channel(tokens, tempo, chan):
    data = []
    total = 0
    for t in expand(tokens):
        if t.startswith("@"):
            if chan not in ("P1", "P2"):
                raise SystemExit("instrument sur un canal non pulse: " + t)
            data += [0xFD, INSTRUMENTS[t[1:]]]
            continue
        name, dur = t.split("/")
        frames = int(dur) * tempo
        total += int(dur)
        if name == "r":
            code = 0x7E
        elif chan == "NO":
            code = DRUMS[name]
        else:
            m = re.match(r"^([A-G]s?)(\d)$", name)
            if not m:
                raise SystemExit("note invalide: " + t)
            midi = 12 * (int(m.group(2)) + 1) + NOTE_NAMES[m.group(1)]
            code = midi - NOTE_BASE_MIDI
            if not 0 <= code < NUM_NOTES:
                raise SystemExit("note hors tessiture: " + t)
        while frames > 255:
            data += [code, 255]
            frames -= 255
            code = 0x7E if chan != "NO" else 0x7E
        data += [code, frames]
    data.append(0xFF)
    return data, total


def load_music():
    songs = []
    cur = None
    with open(os.path.join(ASSETS, "music.txt"), encoding="utf-8") as f:
        for raw in f:
            line = raw.split("#")[0].strip()
            if not line:
                continue
            if line.startswith("@song"):
                parts = line.split()
                tempo = int(parts[2].split("=")[1])
                cur = {"name": parts[1], "tempo": tempo, "P1": [], "P2": [], "TR": [], "NO": []}
                songs.append(cur)
                continue
            ch, rest = line.split(":", 1)
            cur[ch.strip()] += rest.split()
    out = []
    for s in songs:
        chans = {}
        lens = set()
        for ch in ("P1", "P2", "TR", "NO"):
            d, total = compile_channel(s[ch], s["tempo"], ch)
            chans[ch] = d
            lens.add(total)
        if len(lens) != 1:
            print(f"avertissement: canaux de longueurs differentes dans {s['name']}: {lens}",
                  file=sys.stderr)
        out.append((s["name"], chans))
    return out


# ------------------------------------------------------------- SFX ----------
def sfx_tables():
    """SFX : canal (0=pulse2, 1=bruit), puis trames (reg0, reg2, reg3), fin=0 en reg0 n/a.
    Format emis : [canal, nb_trames, (r0, r2, r3) * nb_trames]."""
    sfx = {}

    def pulse(frames):
        return [0, len(frames)] + [b for fr in frames for b in fr]

    def noise(frames):
        return [1, len(frames)] + [b for fr in frames for b in fr]

    def pf(duty, vol, period):
        return ((duty << 6) | 0x30 | vol, period & 0xFF, (period >> 8) & 7)

    sfx["SHOT_A"] = pulse([pf(2, 6 - i, 0x50 + i * 0x18) for i in range(5)])
    sfx["SHOT_B"] = pulse([pf(1, 6 - i, 0x90 + i * 0x20) for i in range(6)])
    sfx["HIT"] = noise([(0x30 | (6 - i), 0x04 + i, 0) for i in range(4)])
    sfx["EXPLODE"] = noise([(0x30 | max(0, 12 - i // 2), 0x09 + min(5, i // 4), 0) for i in range(22)])
    sfx["BIGEXPLODE"] = noise([(0x30 | max(0, 15 - i // 3), 0x0A + min(5, i // 8), 0) for i in range(46)])
    sfx["POWERUP"] = pulse([pf(2, 10, p) for p in (0x150, 0x150, 0x11C, 0x11C, 0xE2, 0xE2, 0xA9, 0xA9, 0x8E, 0x8E, 0x71, 0x71)])
    sfx["BEAM"] = pulse([pf(3 if i % 2 else 2, 12 - i // 4, 0x40 + (i % 4) * 6) for i in range(36)])
    sfx["NOVA"] = noise([(0x30 | max(0, 15 - i // 3), 0x03 + min(12, i // 3), 0) for i in range(40)])
    sfx["DEATH"] = pulse([pf(2, max(1, 12 - i // 3), 0x80 + i * 0x14) for i in range(32)])
    sfx["MENU"] = pulse([pf(2, 8, 0xD5), pf(2, 8, 0xD5), pf(2, 6, 0xA0), pf(2, 4, 0xA0)])
    sfx["ALERT"] = pulse([pf(2, 10, 0xA0 if (i // 8) % 2 == 0 else 0xD5) for i in range(64)])
    sfx["DASH"] = pulse([pf(1, 10 - i // 2, 0x200 - i * 0x18) for i in range(14)])
    sfx["SHIELD"] = pulse([pf(3, 9, 0x120 if i % 4 < 2 else 0x100) for i in range(16)])
    sfx["SYNC"] = pulse([pf(2, 15 - i // 2, 0x60 + (i % 3) * 0x30) for i in range(20)])
    sfx["COOPREADY"] = pulse([pf(1, 9, p) for p in (0xD5, 0xD5, 0xA9, 0xA9, 0x8E, 0x8E, 0x6A, 0x6A, 0x6A, 0x6A)])
    return sfx


# ------------------------------------------------------------- DPCM ---------
def gen_kick():
    """Grosse caisse synthetisee (balayage 140 Hz -> 45 Hz) encodee en DPCM 1 bit.
    Taux DMC index 13 (~22 kHz NTSC). Longueur = 16*L+1 octets."""
    rate = 22050.0
    L = 17
    nbytes = 16 * L + 1
    nbits = nbytes * 8
    level = 64
    bits = []
    phase = 0.0
    for n in range(nbits):
        t = n / rate
        f = 45 + 95 * math.exp(-t * 30)
        phase += 2 * math.pi * f / rate
        amp = 50 * math.exp(-t * 14)
        target = 64 + amp * math.sin(phase)
        if target > level and level <= 125:
            bits.append(1)
            level += 2
        elif level >= 2:
            bits.append(0)
            level -= 2
        else:
            bits.append(1)
            level += 2
    out = bytearray()
    for i in range(0, nbits, 8):
        b = 0
        for k in range(8):
            if bits[i + k]:
                b |= 1 << k   # DMC lit les bits du LSB vers le MSB
        out.append(b)
    return bytes(out), L


# ------------------------------------------------------------- sortie -------
def ca65_bytes(label, data, per_line=16):
    lines = [f"{label}:"] if label else []
    for i in range(0, len(data), per_line):
        lines.append("    .byte " + ",".join(f"${b:02X}" for b in data[i:i + per_line]))
    return "\n".join(lines)


def main():
    os.makedirs(BUILD, exist_ok=True)
    consts = {}
    bg_common, spr_common = build_common(consts)
    units = [bytes(1024)] * 32
    def enc(tiles):
        return b"".join(encode_tile(t) for t in tiles)
    units[0:2] = [enc(bg_common[0:64]), enc(bg_common[64:128])]
    units[16:19] = [enc(spr_common[0:64]), enc(spr_common[64:128]), enc(spr_common[128:192])]
    spr_sets = []
    sector_data = []
    for k, sec in enumerate(SECTORS):
        bg, c = build_sector_bg(sec["tiles"])
        units[2 + 2 * k:4 + 2 * k] = [enc(bg[0:64]), enc(bg[64:128])]
        if sec["sprites"] not in spr_sets:
            spr_sets.append(sec["sprites"])
            units[CHR_SPR_SECTOR + len(spr_sets) - 1] = enc(build_sector_sprites(sec["sprites"]))
        lines = sec["gen"](c)
        tpl, ids = dedupe(lines)
        attr = attrs_h(lines, lambda x, y, c=c, lines=lines, f=sec["palfn"]: f(c, lines, x, y)) if sec["palfn"] else None
        sector_data.append((sec, c, tpl, ids, attr, load_script(sec["name"])))
    chr_data = b"".join(units)
    assert len(chr_data) == 32768
    with open(os.path.join(BUILD, "chr.bin"), "wb") as f:
        f.write(chr_data)
    consts["S_BOSS_H"] = 0xC0
    consts["S_BOSS_V"] = 0xD0
    consts["S_POD_H"] = 0xE0
    consts["S_POD_V"] = 0xE0

    out = ["; Fichier genere par tools/gen_assets.py - ne pas modifier a la main", ""]
    for k in sorted(consts):
        out.append(f"{k} = ${consts[k]:02X}")
    out.append(f"NUM_SECTORS = {len(SECTORS)}")
    out.append(f"CHR_BG_COMMON = {CHR_BG_COMMON}")
    out.append(f"CHR_SPR_COMMON = {CHR_SPR_COMMON}")
    out.append("")

    # Secteurs : un banc PRG chacun, en-tete a $8000 (voir stage.s : SH_*)
    songs_names = [s_[0] for s_ in load_music()]
    out.append("sector_banks: .byte " + ",".join(str(sd[0]["bank"]) for sd in sector_data))
    for sec, c, tpl, ids, attr, script in sector_data:
        n = sec["name"]
        seg = "DATA0" if sec["bank"] == 0 else f"SEC{sec['bank']}"
        width = 26 if sec["orient"] == 0 else 32
        out.append(f'.segment "{seg}"')
        out.append(f"; ---- Secteur {n} : {sec['title']} - {len(ids)} lignes, {len(tpl)} gabarits uniques")
        out.append(f"{n}_hdr:")
        out.append(f"    .byte {sec['orient']}, {len(ids) - 1}")
        out.append(f"    .word {sec['cam_stop']}, {sec['cp']}")
        out.append(f"    .word {n}_ids, {n}_tlo, {n}_thi, {n + '_attr' if attr else 0}, {n}_script, {n}_pal")
        k = SECTORS.index(sec)
        out.append(f"    .byte {2 + 2 * k}, {CHR_SPR_SECTOR + spr_sets.index(sec['sprites'])}, {songs_names.index(sec['song'])}, {sec['boss']}")
        out.append(ca65_bytes(f"{n}_pal", sec["pal"] + SPR_PAL))
        out.append(ca65_bytes(f"{n}_ids", ids))
        if attr:
            out.append(ca65_bytes(f"{n}_attr", attr, 7))
        out.append(f"{n}_tlo:\n    .lobytes " + ",".join(f"{n}_t{i}" for i in range(len(tpl))))
        out.append(f"{n}_thi:\n    .hibytes " + ",".join(f"{n}_t{i}" for i in range(len(tpl))))
        for i, t in enumerate(tpl):
            out.append(ca65_bytes(f"{n}_t{i}", t, width))
        out.append(ca65_bytes(f"{n}_script", script, 4))
        print(f"  secteur {n}: {len(ids)} lignes, {len(tpl)} gabarits, script {len(script) // 4} entrees")
    out.append("")

    # Musique
    out.append('.segment "DATA1"')
    songs = load_music()
    for idx, (name, chans) in enumerate(songs):
        out.append(f"SONG_{name.upper()} = {idx}")
    out.append("song_ptrs:")
    for name, _ in songs:
        out.append(f"    .word mus_{name}_p1, mus_{name}_p2, mus_{name}_tr, mus_{name}_no")
    for name, chans in songs:
        for ch in ("P1", "P2", "TR", "NO"):
            out.append(ca65_bytes(f"mus_{name}_{ch.lower()}", chans[ch]))
    tables = period_tables()
    for region in ("ntsc", "pal"):
        pulse, tri = tables[region]
        out.append(ca65_bytes(f"pulse_lo_{region}", [p & 0xFF for p in pulse]))
        out.append(ca65_bytes(f"pulse_hi_{region}", [p >> 8 for p in pulse]))
        out.append(ca65_bytes(f"tri_lo_{region}", [p & 0xFF for p in tri]))
        out.append(ca65_bytes(f"tri_hi_{region}", [p >> 8 for p in tri]))
    sfx = sfx_tables()
    names = list(sfx)
    for i, n in enumerate(names):
        out.append(f"SFX_{n} = {i}")
    out.append("sfx_ptr_lo:\n    .lobytes " + ",".join(f"sfx_{n.lower()}" for n in names))
    out.append("sfx_ptr_hi:\n    .hibytes " + ",".join(f"sfx_{n.lower()}" for n in names))
    for n in names:
        out.append(ca65_bytes(f"sfx_{n.lower()}", sfx[n]))

    # Tables de directions (16 directions, 0 = +u avant, 4 = +v, 8 = -u, 12 = -v)
    # pour les projectiles ennemis, en virgule fixe 8.8 signee, 2 vitesses.
    for si, spd in enumerate((1.25, 2.0)):
        du = [round(spd * 256 * math.cos(2 * math.pi * k / 16)) & 0xFFFF for k in range(16)]
        dv = [round(spd * 256 * math.sin(2 * math.pi * k / 16)) & 0xFFFF for k in range(16)]
        out.append(ca65_bytes(f"dir{si}_du_lo", [x & 0xFF for x in du]))
        out.append(ca65_bytes(f"dir{si}_du_hi", [x >> 8 for x in du]))
        out.append(ca65_bytes(f"dir{si}_dv_lo", [x & 0xFF for x in dv]))
        out.append(ca65_bytes(f"dir{si}_dv_hi", [x >> 8 for x in dv]))
    # Sinus 64 pas, amplitude 1.25 px/image (8.8) pour les trajectoires ondulantes
    sn = [round(1.25 * 256 * math.sin(2 * math.pi * k / 64)) & 0xFFFF for k in range(64)]
    out.append(ca65_bytes("sine_lo", [x & 0xFF for x in sn]))
    out.append(ca65_bytes("sine_hi", [x >> 8 for x in sn]))

    kick, L = gen_kick()
    with open(os.path.join(BUILD, "kick.dmc"), "wb") as f:
        f.write(kick)
    out.append(f"DMC_KICK_LEN = {L}")
    out.append("")

    with open(os.path.join(BUILD, "assets.inc"), "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")
    print(f"chr.bin {len(chr_data)} o | {len(SECTORS)} secteurs | {len(songs)} musiques | {len(sfx)} SFX | "
          f"DPCM {len(kick)} o")


if __name__ == "__main__":
    main()
