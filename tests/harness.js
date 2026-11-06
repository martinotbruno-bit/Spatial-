// Banc d'essai : pilote l'emulateur jsnes en mode sans affichage.
// Fournit : chargement de la ROM, symboles ld65, entrees des 2 manettes,
// lecture/ecriture RAM et VRAM, profilage CPU par image, journal APU,
// captures PNG, statistiques de sprites par ligne.
"use strict";
const fs = require("fs");
const path = require("path");
const jsnes = require("jsnes");
const { PNG } = require("pngjs");

const ROOT = path.resolve(__dirname, "..");
const ROM = path.join(ROOT, "build", "spatial.nes");
const LBL = path.join(ROOT, "build", "spatial.lbl");

const BTN = { A: 0, B: 1, SELECT: 2, START: 3, UP: 4, DOWN: 5, LEFT: 6, RIGHT: 7 };

function loadLabels() {
  const map = {};
  for (const line of fs.readFileSync(LBL, "utf8").split("\n")) {
    const m = line.match(/^al ([0-9A-F]+) \.(\w+)/);
    if (m) map[m[2]] = parseInt(m[1], 16);
  }
  return map;
}

class Machine {
  constructor(opts = {}) {
    this.sym = loadLabels();
    this.fb = null;
    this.nes = new jsnes.NES({
      onFrame: (buf) => { this.fb = buf.slice(); },
      onAudioSample: null,
      emulateSound: !!opts.sound,
    });
    const rom = fs.readFileSync(ROM).toString("binary");
    this.nes.loadROM(rom);
    if (opts.sram) {
      for (let i = 0; i < opts.sram.length; i++) this.nes.cpu.mem[0x6000 + i] = opts.sram[i];
    }
    this.cycles = 0;
    this.nmiAt = 0;
    this.frameCycles = [];      // cycles NMI -> fin du travail, par image
    this.vblankUse = [];        // cycles NMI -> fin des ecritures PPU
    this.apuLog = [];           // [image, adresse, valeur]
    this.frameNo = 0;
    this.held = [new Set(), new Set()];
    const cpu = this.nes.cpu;
    const emu = cpu.emulate.bind(cpu);
    cpu.emulate = () => { const c = emu(); this.cycles += c; return c; };
    // jsnes compte le DMA OAM (513 cycles) comme cycles d'arret hors emulate()
    const halt = cpu.haltCycles.bind(cpu);
    cpu.haltCycles = (c) => { this.cycles += c; return halt(c); };
    const req = cpu.requestIrq.bind(cpu);
    cpu.requestIrq = (t) => { if (t === cpu.IRQ_NMI) this.nmiAt = this.cycles; return req(t); };
    const mm = this.nes.mmap;
    const wr = mm.write.bind(mm);
    mm.write = (a, v) => {
      // $5FF1 : debut du travail (juste apres le NMI) ; $5FF0 : fin du travail.
      // Mesure = cycles ecoules depuis le NMI qui a lance l'image (NMI inclus).
      if (a === 0x5ff1) this.workNmi = this.nmiAt;
      else if (a === 0x5ff0) this.frameCycles.push(this.cycles - this.workNmi);
      // ecriture de PPUMASK en fin de travail PPU du NMI : duree utilisee du vblank
      else if (a === 0x2001 && this.cycles - this.nmiAt < 6000) this.vblankUse.push(this.cycles - this.nmiAt);
      else if (a >= 0x4000 && a <= 0x4015) this.apuLog.push([this.frameNo, a, v]);
      return wr(a, v);
    };
  }
  s(name) {
    const a = this.sym[name];
    if (a === undefined) throw new Error("symbole inconnu: " + name);
    return a;
  }
  peek(name, off = 0) { const a = (typeof name === "number" ? name : this.s(name)) + off; return a < 0x800 ? this.nes.cpu.mem[a] : this.nes.cpu.mem[a]; }
  poke(name, v, off = 0) { const a = (typeof name === "number" ? name : this.s(name)) + off; this.nes.cpu.mem[a] = v & 0xff; }
  peekBytes(name, n) { const a = this.s(name); return Array.from({ length: n }, (_, i) => this.nes.cpu.mem[a + i]); }
  press(pad, btn) { this.held[pad].add(btn); this.nes.buttonDown(pad + 1, BTN[btn]); }
  release(pad, btn) { this.held[pad].delete(btn); this.nes.buttonUp(pad + 1, BTN[btn]); }
  releaseAll() { for (const p of [0, 1]) for (const b of [...this.held[p]]) this.release(p, b); }
  frame(n = 1, each) {
    for (let i = 0; i < n; i++) {
      this.nes.frame();
      this.frameNo++;
      if (each) each(this, i);
    }
  }
  tap(pad, btn, hold = 2, after = 4) { this.press(pad, btn); this.frame(hold); this.release(pad, btn); this.frame(after); }
  // VRAM : lecture d'une case de table de noms en tenant compte du miroir
  nt(addr) {
    const ppu = this.nes.ppu;
    const q = ((addr - 0x2000) >> 10) & 3;
    const t = ppu.nameTable[ppu.ntable1[q]];
    const off = addr & 0x3ff;
    return off < 0x3c0 ? t.tile[off] : t.attrib[off - 0x3c0];
  }
  romByte(cpuAddr) { return this.nes.mmap.load(cpuAddr); }
  oam() { return this.nes.ppu.spriteMem.slice(0, 256); }
  // Nombre maximal de sprites sur une meme ligne (zone visible), selon l'OAM
  maxSpritesPerLine() {
    const oam = this.peekBytes("vbuf", 0) && this.nes.cpu.mem.slice(0x200, 0x300);
    const lines = new Array(240).fill(0);
    for (let i = 0; i < 64; i++) {
      const y = oam[i * 4] + 1;
      if (y >= 240) continue;
      for (let k = 0; k < 8 && y + k < 240; k++) lines[y + k]++;
    }
    return { max: Math.max(...lines), over: lines.filter((c) => c > 8).length };
  }
  screenshot(file) {
    if (!this.fb) return;
    const png = new PNG({ width: 256, height: 240 });
    for (let i = 0; i < 256 * 240; i++) {
      const c = this.fb[i];
      png.data[i * 4] = c & 0xff;
      png.data[i * 4 + 1] = (c >> 8) & 0xff;
      png.data[i * 4 + 2] = (c >> 16) & 0xff;
      png.data[i * 4 + 3] = 255;
    }
    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.writeFileSync(file, PNG.sync.write(png));
  }
  sram(n = 64) { return Array.from({ length: n }, (_, i) => this.nes.cpu.mem[0x6000 + i]); }
}

module.exports = { Machine, BTN, ROOT };
