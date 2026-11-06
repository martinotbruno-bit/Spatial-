// Pilote automatique pour les mesures d'equilibrage (emulation).
// Ce n'est PAS un joueur humain : il voit tout l'etat du jeu, reagit toutes
// les 3 images avec un leger bruit, et sert d'etalon reproductible pour
// comparer les difficultes et les modes entre eux.
"use strict";

const s8 = (x) => (x > 127 ? x - 256 : x);
const fix = (hi, lo) => s8(hi) + lo / 256;

class Bot {
  constructor(m, opts = {}) {
    this.m = m;
    this.react = opts.react || 3;          // images entre deux decisions
    this.noise = opts.noise ?? 0.15;       // probabilite d'une erreur de decision
    this.seed = opts.seed || 1;
    this.dirs = [[0, 0], [0, 0]];
    this.t = 0;
  }
  rnd() { this.seed = (this.seed * 1103515245 + 12345) & 0x7fffffff; return this.seed / 0x7fffffff; }

  snapshot() {
    const m = this.m, mem = m.nes.cpu.mem;
    const rd = (n, i = 0) => mem[m.s(n) + i];
    const eb = [];
    for (let i = 0; i < 16; i++) if (rd("eb_on", i)) eb.push({ u: rd("eb_u", i) + 4, v: rd("eb_v", i) + 4, du: fix(rd("eb_duhi", i), rd("eb_dulo", i)), dv: fix(rd("eb_dvhi", i), rd("eb_dvlo", i)) });
    const en = [];
    for (let i = 0; i < 10; i++) if (rd("en_type", i)) en.push({ t: rd("en_type", i), u: rd("en_u", i) + 8, v: rd("en_v", i) + 8, du: fix(rd("en_duhi", i), rd("en_dulo", i)), dv: fix(rd("en_dvhi", i), rd("en_dvlo", i)) });
    const boss = rd("boss_on") ? { u: rd("boss_u") + 16, v: rd("boss_v") + 16 } : null;
    const items = [];
    for (let i = 0; i < 3; i++) if (rd("it_on", i)) items.push({ u: rd("it_u", i) + 4, v: rd("it_v", i) + 4 });
    const o = rd("orient");
    const lim = o ? { umin: 16, umax: 200, vmin: 8, vmax: 232 } : { umin: 8, umax: 224, vmin: 40, vmax: 208 };
    return { eb, en, boss, items, o, lim };
  }

  cost(p, d, spd, w) {
    let c = 0;
    for (let t = 1; t <= 10; t += 1) {
      const u = p.u + d[0] * spd * t, v = p.v + d[1] * spd * t;
      if (u < w.lim.umin + 8 || u > w.lim.umax + 8 || v < w.lim.vmin + 8 || v > w.lim.vmax + 8) c += 40;
      const wt = 1.5 - t * 0.1;
      for (const b of w.eb) {
        const dist = Math.hypot(b.u + b.du * t - u, b.v + b.dv * t - v);
        if (dist < 16) c += (16 - dist) * 6 * wt;
      }
      for (const e of w.en) {
        const dist = Math.hypot(e.u + e.du * t - u, e.v + e.dv * t - v);
        if (dist < 22) c += (22 - dist) * 4 * wt;
      }
      if (w.boss) {
        const dist = Math.hypot(w.boss.u - u, w.boss.v - v);
        if (dist < 30) c += (30 - dist) * 5 * wt;
      }
    }
    // placement offensif : rester en arriere et s'aligner sur une cible
    const u2 = p.u + d[0] * spd * 6, v2 = p.v + d[1] * spd * 6;
    if (u2 > 100) c += (u2 - 100) * 0.4;
    if (u2 < 30) c += (30 - u2) * 0.4;
    let target = w.boss || null, best = 1e9;
    for (const e of w.en) if (e.u > u2 && e.u - u2 < best) { best = e.u - u2; target = e; }
    if (target) c += Math.abs(target.v - v2) * 0.25;
    for (const it of w.items) c -= Math.max(0, 40 - Math.hypot(it.u - u2, it.v - v2)) * 0.5;
    return c;
  }

  // a appeler a chaque image avant m.frame(1)
  step() {
    const m = this.m;
    this.t++;
    const w = this.snapshot();
    const btn = w.o
      ? { up: "UP", down: "DOWN", fwd: "UP", back: "DOWN", vp: "RIGHT", vm: "LEFT" }
      : { fwd: "RIGHT", back: "LEFT", vp: "DOWN", vm: "UP" };
    const coop = m.peek("nplayers") === 2;
    for (let p = 0; p < 2; p++) {
      if (!m.peek("pl_on", p)) continue;
      const pad = m.peek("pl_pad", p);
      for (const b of ["UP", "DOWN", "LEFT", "RIGHT", "A"]) m.release(pad, b);
      if (!m.peek("pl_alive", p)) continue;
      const pos = { u: m.peek("pl_u", p) + 8, v: m.peek("pl_v", p) + 8 };
      const spd = p === 0 ? 2.5 : 1.75;
      if (this.t % this.react === 0) {
        let bestD = [0, 0], bestC = Infinity;
        for (const du of [-1, 0, 1]) for (const dv of [-1, 0, 1]) {
          const c = this.cost(pos, [du, dv], spd, w);
          if (c < bestC) { bestC = c; bestD = [du, dv]; }
        }
        if (this.rnd() < this.noise) bestD = [Math.floor(this.rnd() * 3) - 1, Math.floor(this.rnd() * 3) - 1];
        this.dirs[p] = bestD;
        // danger imminent : capacite propre (ou pouvoir coop si jauge pleine)
        const near = w.eb.some((b) => Math.hypot(b.u + b.du * 4 - pos.u, b.v + b.dv * 4 - pos.v) < 14);
        if ((near && !m.peek("pl_abil_cd", p)) || m.peek("gauge") === 64) m.press(pad, "A");
      }
      const d = this.dirs[p];
      if (d[0] > 0) m.press(pad, btn.fwd); else if (d[0] < 0) m.press(pad, btn.back);
      if (d[1] > 0) m.press(pad, btn.vp); else if (d[1] < 0) m.press(pad, btn.vm);
      // tir continu, relache toutes les 40 images (salve synchronisee en coop)
      if (coop && this.t % 40 === 0) m.release(pad, "B"); else m.press(pad, "B");
    }
  }
}

module.exports = { Bot };
