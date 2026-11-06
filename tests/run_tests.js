// Suite de tests automatises du prototype (Phase 1) - execution en EMULATION
// (jsnes 1.2.1). Ces tests ne remplacent pas la validation sur materiel reel.
// Usage : node run_tests.js   (depuis tests/, apres "make")
"use strict";
const fs = require("fs");
const path = require("path");
const crypto = require("crypto");
const { Machine, ROOT } = require("./harness");

const SHOTS = path.join(ROOT, "docs", "captures");
const results = [];
const metrics = {};

function test(id, name, fn) {
  const t0 = Date.now();
  let ok = false;
  let detail = "";
  try {
    const r = fn();
    ok = r.ok;
    detail = r.detail || "";
  } catch (e) {
    ok = false;
    detail = "EXCEPTION : " + e.message;
  }
  results.push({ id, name, ok, detail, ms: Date.now() - t0 });
  console.log(`${ok ? "OK   " : "ECHEC"} ${id} ${name}${detail ? "  -- " + detail : ""}`);
}

const ST = { TITLE: 0, PLAY: 1, CLEAR: 2, OVER: 3, END: 4, STORY: 5, CONT: 6 };

// En-tete du secteur courant (copie RAM sec_hdr) et conversion position -> carte
const hdr = (m, o) => m.peek("sec_hdr", o);
const camStop = (m) => hdr(m, 2) | (hdr(m, 3) << 8);
const cpOf = (m) => hdr(m, 4) | (hdr(m, 5) << 8);
function mapPos(m, P) {
  const A = hdr(m, 22), L = hdr(m, 23), reps = hdr(m, 24), max = hdr(m, 1);
  if (P < A) return P;
  const k = P - A, total = L * reps;
  if (k < total) return A + (k % L);
  return Math.min(A + L + (k - total), max);
}
// Saute pres de la fin du secteur (decor non redessine) : apparition du boss
function jumpToBoss(m) {
  const stop = camStop(m) - 16;
  m.poke("cam_lo", stop & 255); m.poke("cam_hi", stop >> 8);
  let p = hdr(m, 14) | (hdr(m, 15) << 8);
  while (m.romByte(p + 1) !== 15) p += 4;
  m.poke("script_ptr", p & 255); m.poke("script_ptr", p >> 8, 1);
  m.poke("sc_last", 0);
}
// Fait defiler tout le secteur en verifiant la VRAM toutes les `step` images
function scrollWholeSector(m, step, onChunk) {
  let bad = 0, chunks = 0;
  while (m.peek("scroll_on") && chunks < 200) {
    m.frame(step, invul);
    bad += vramErrors(m);
    if (onChunk) onChunk(m, chunks);
    chunks++;
  }
  return { bad, chunks };
}

// Verifie que la zone de jeu visible correspond a la carte (H ou V) -> nb d'erreurs
function vramErrors(m) {
  let bad = 0;
  const cam = camOf(m);
  const pre = "s" + (m.peek("stage") + 1);
  if (m.peek("orient") === 0) {
    const ids = m.s(pre + "_ids"), tlo = m.s(pre + "_tlo"), thi = m.s(pre + "_thi");
    for (let c = Math.floor(cam / 8); c <= Math.floor((cam + 255) / 8); c++) {
      const id = m.romByte(ids + mapPos(m, c)), tp = m.romByte(tlo + id) | (m.romByte(thi + id) << 8);
      const nc = c & 63, base = (nc & 32 ? 0x2400 : 0x2000) + (nc & 31);
      for (let r = 0; r < 26; r++) if (m.romByte(tp + r) !== m.nt(base + (r + 4) * 32)) bad++;
    }
  } else {
    const ids = m.s(pre + "_ids"), tlo = m.s(pre + "_tlo"), thi = m.s(pre + "_thi"), vsy = m.peek("vsy");
    for (let s = 0; s < 26; s++) {
      const ntrow = ((vsy >> 3) + s) % 30;
      let r = ((29 - ntrow) % 30 + 30) % 30;
      while (r < Math.floor(cam / 8) - 2) r += 30;
      const rr = mapPos(m, r);
      const id = m.romByte(ids + rr), tp = m.romByte(tlo + id) | (m.romByte(thi + id) << 8);
      for (let c = 0; c < 32; c++) if (m.romByte(tp + c) !== m.nt(0x2400 + ntrow * 32 + c)) bad++;
      // attributs : bloc k (16 px) de la paire de rangees r>>1
      const attr = m.sym[pre + "_attr"];
      if (attr !== undefined) {
        const a = ntrow >> 2, half = (ntrow >> 1) & 1;
        for (let k = 0; k < 16; k++) {
          const want = (m.romByte(attr + (rr >> 1) * 4 + (k >> 2)) >> (2 * (k & 3))) & 3;
          const got = (m.nt(0x27c0 + a * 8 + (k >> 1)) >> ((k & 1) * 2 + half * 4)) & 3;
          if (want !== got) bad++;
        }
      }
    }
  }
  return bad;
}
const camOf = (m) => m.peek("cam_lo") + 256 * m.peek("cam_hi");
const invul = (m) => { m.poke("pl_invul", 10); m.poke("pl_invul", 10, 1); };

// Demarre une partie depuis l'ecran titre. players = 1|2, ship = 0|1, sector = 0|1
function startGame({ players = 2, ship = 0, sector = 0, sound = false } = {}) {
  const m = new Machine({ sound });
  m.frame(40);
  m.poke("sectors_unl", 255);                      // tous les secteurs accessibles
  if (players === 2) m.tap(0, "RIGHT");
  m.tap(0, "DOWN");
  if (ship === 1 && players === 1) m.tap(0, "RIGHT");
  m.tap(0, "DOWN");
  for (let i = 0; i < sector; i++) m.tap(0, "RIGHT");
  m.tap(0, "START");
  m.frame(2);
  if (m.peek("state") === ST.STORY) { m.tap(0, "START"); m.frame(2); }   // passe la sequence narrative
  return m;
}

function countOn(m, arr, n) { return m.peekBytes(arr, n).filter((x) => x !== 0).length; }

// ---------------------------------------------------------------------------
test("T01", "Demarrage : ecran titre stable, NMI actif, region NTSC detectee", () => {
  const m = new Machine();
  m.frame(180);
  const nmi1 = m.peek("nmi_count");
  m.frame(60);
  const nmi2 = m.peek("nmi_count");
  m.screenshot(path.join(SHOTS, "01_titre.png"));
  const ok = m.peek("state") === ST.TITLE && ((nmi2 - nmi1) & 0xff) === 60 && m.peek("region") === 0 && m.peek("lag_count") === 0;
  return { ok, detail: `etat=${m.peek("state")} nmi/60img=${(nmi2 - nmi1) & 0xff} region=${m.peek("region")} lag=${m.peek("lag_count")}` };
});

test("T02", "Menu : choix 1/2 joueurs, vaisseau, secteur", () => {
  const m = new Machine();
  m.frame(40);
  m.poke("sectors_unl", 255);
  m.tap(0, "RIGHT");
  const np = m.peek("nplayers");
  m.tap(0, "RIGHT");
  const np2 = m.peek("nplayers");
  m.tap(0, "DOWN");
  m.tap(0, "RIGHT");
  const ship = m.peek("solo_ship");
  m.tap(0, "DOWN");
  m.tap(0, "LEFT");
  const sec = m.peek("sector_sel");
  return { ok: np === 2 && np2 === 1 && ship === 1 && sec === 4, detail: `joueurs 1->${np}->${np2}, vaisseau=${ship}, secteur (GAUCHE depuis 1, boucle)=${sec + 1}` };
});

test("T03", "Deux manettes : deplacements independants et simultanes", () => {
  const m = startGame({ players: 2 });
  m.frame(30, invul);
  const u0 = [m.peek("pl_u"), m.peek("pl_u", 1)], v0 = [m.peek("pl_v"), m.peek("pl_v", 1)];
  m.press(0, "RIGHT"); m.press(1, "DOWN");
  m.frame(20, invul);
  m.releaseAll();
  const u1 = [m.peek("pl_u"), m.peek("pl_u", 1)], v1 = [m.peek("pl_v"), m.peek("pl_v", 1)];
  const ok = u1[0] - u0[0] === 50 && v1[0] === v0[0] && u1[1] === u0[1] && v1[1] - v0[1] === 35;
  return { ok, detail: `LANCE du=${u1[0] - u0[0]} (2.5px x 20), EGIDE dv=${v1[1] - v0[1]} (1.75px x 20)` };
});

test("T04", "Tirs simultanes des deux vaisseaux (et deplacement pendant le tir)", () => {
  const m = startGame({ players: 2 });
  m.frame(10, invul);
  m.press(0, "B"); m.press(1, "B"); m.press(0, "UP"); m.press(1, "RIGHT");
  let maxA = 0, maxB = 0;
  m.frame(30, (mm) => {
    invul(mm);
    const on = mm.peekBytes("pb_on", 16);
    maxA = Math.max(maxA, on.filter((x) => x === 1).length);
    maxB = Math.max(maxB, on.filter((x) => x === 2).length);
  });
  m.screenshot(path.join(SHOTS, "02_tirs_cooperation.png"));
  return { ok: maxA >= 3 && maxB >= 3, detail: `projectiles LANCE max=${maxA}, EGIDE max=${maxB}` };
});

test("T05", "Collision entre joueurs : contact physique, aucun degat, aucun blocage", () => {
  const m = startGame({ players: 2 });
  m.frame(5);
  m.poke("pl_u", 100); m.poke("pl_v", 120); m.poke("pl_u", 100, 1); m.poke("pl_v", 120, 1);
  m.poke("pl_invul", 0); m.poke("pl_invul", 0, 1);
  const lives0 = m.peek("lives");
  let minDist = 999, alive = true;
  m.press(0, "DOWN"); m.press(1, "UP");
  m.frame(40, (mm) => {
    mm.poke("en_type", 0); for (let i = 0; i < 10; i++) mm.poke("en_type", 0, i);
    for (let i = 0; i < 16; i++) mm.poke("eb_on", 0, i);
    const du = Math.abs(mm.peek("pl_u") - mm.peek("pl_u", 1)), dv = Math.abs(mm.peek("pl_v") - mm.peek("pl_v", 1));
    minDist = Math.min(minDist, Math.max(du, dv));
    alive = alive && mm.peek("pl_alive") === 1 && mm.peek("pl_alive", 1) === 1;
  });
  m.releaseAll();
  // le controle reste immediat : chacun peut s'eloigner
  const vA = m.peek("pl_v");
  m.press(0, "UP"); m.frame(10); m.releaseAll();
  const moved = vA - m.peek("pl_v");
  const ok = alive && m.peek("lives") === lives0 && minDist >= 10 && moved >= 20;
  return { ok, detail: `separation min=${minDist}px (corps 12px), vies ${lives0}->${m.peek("lives")}, recul libre=${moved}px` };
});

test("T06", "Ressource cooperative LIEN : remplissage par destructions et vol en formation", () => {
  const m = startGame({ players: 2 });
  m.frame(5);
  m.poke("pl_u", 60); m.poke("pl_v", 100); m.poke("pl_u", 60, 1); m.poke("pl_v", 130, 1);
  const g0 = m.peek("gauge");
  m.frame(160, (mm) => { invul(mm); for (let i = 0; i < 10; i++) mm.poke("en_type", 0, i); });
  const g1 = m.peek("gauge");
  return { ok: g1 - g0 >= 9, detail: `jauge ${g0}->${g1} en 160 images de vol en formation (attendu ~10)` };
});

test("T07", "Attaque combinee : FAISCEAU DE LIAISON entre les deux vaisseaux", () => {
  const m = startGame({ players: 2 });
  m.frame(5);
  m.poke("pl_u", 60); m.poke("pl_v", 60); m.poke("pl_u", 60, 1); m.poke("pl_v", 180, 1);
  m.poke("gauge", 64);
  // ennemi place sur la trajectoire du faisceau
  m.poke("en_type", 1, 0); m.poke("en_hp", 20, 0); m.poke("en_u", 60, 0); m.poke("en_v", 112, 0);
  m.poke("en_duhi", 0, 0); m.poke("en_dulo", 0, 0);
  m.tap(1, "A", 2, 0);
  const beam = m.peek("beam_t");
  const pts = m.peekBytes("beam_v", 8);
  let killed = false;
  m.frame(60, (mm) => { invul(mm); if (mm.peek("en_type", 0) === 0) killed = true; mm.poke("en_u", 60, 0); });
  m.screenshot(path.join(SHOTS, "03_faisceau_liaison.png"));
  const between = pts.every((v) => v > 68 && v < 188);
  return { ok: beam > 100 && between && killed && m.peek("gauge") < 16, detail: `beam_t=${beam}, points v=[${pts.join(",")}], ennemi detruit=${killed}` };
});

test("T08", "Solo : la jauge pleine declenche la NOVA (aucun partenaire requis)", () => {
  const m = startGame({ players: 1 });
  m.frame(5);
  m.poke("gauge", 64);
  for (let i = 0; i < 4; i++) { m.poke("en_type", 1, i); m.poke("en_hp", 1, i); m.poke("en_u", 150, i); m.poke("en_v", 60 + 30 * i, i); }
  for (let i = 0; i < 8; i++) { m.poke("eb_on", 1, i); m.poke("eb_u", 200, i); m.poke("eb_v", 100, i); }
  m.tap(0, "A", 2, 0);
  const nova = m.peek("nova_t");
  const enemies = countOn(m, "en_type", 10), bullets = countOn(m, "eb_on", 16);
  return { ok: nova > 0 && enemies === 0 && bullets === 0, detail: `nova_t=${nova}, ennemis restants=${enemies}, projectiles=${bullets}` };
});

test("T09", "Coop : TRANSFERT D'ENERGIE ramene un partenaire sans vie", () => {
  const m = startGame({ players: 2 });
  m.frame(5);
  m.poke("lives", 0); m.poke("pl_alive", 0, 1); m.poke("pl_resp", 0, 1); m.poke("gauge", 64);
  m.tap(0, "A", 2, 0);
  m.frame(3);
  return { ok: m.peek("pl_alive", 1) === 1 && m.peek("state") === ST.PLAY, detail: `EGIDE en vol=${m.peek("pl_alive", 1)}` };
});

test("T10", "Scrolling horizontal : decor VRAM conforme a la carte sur tout le secteur (corps repete)", () => {
  const m = startGame({ players: 2 });
  const r = scrollWholeSector(m, 97, (mm, k) => { if (k === 5) mm.screenshot(path.join(SHOTS, "04_secteur1_horizontal.png")); });
  metrics.cam_h_end = camOf(m);
  return { ok: r.bad === 0 && camOf(m) === camStop(m), detail: `${r.chunks} controles, ${r.bad} erreurs, camera finale=${camOf(m)} (fin ${camStop(m)}, ${hdr(m, 24)} passages du corps)` };
});

test("T11", "Scrolling vertical : decor et attributs VRAM conformes sur tout le secteur (corps repete)", () => {
  const m = startGame({ players: 2, sector: 1 });
  const r = scrollWholeSector(m, 101, (mm, k) => { if (k === 6) mm.screenshot(path.join(SHOTS, "05_secteur2_vertical.png")); });
  let hudOk = true;
  const row1 = " SCORE ";
  for (let i = 0; i < row1.length; i++) if (m.nt(0x2020 + i) !== row1.charCodeAt(i)) hudOk = false;
  return { ok: r.bad === 0 && hudOk && camOf(m) === camStop(m), detail: `${r.chunks} controles, ${r.bad} erreurs (tuiles + attributs), HUD intact=${hudOk}, camera=${camOf(m)} (fin ${camStop(m)})` };
});

test("T12", "Ennemis et projectiles : 4 familles + conteneurs destructibles, tirs ennemis", () => {
  const m = startGame({ players: 2 });
  const seen = new Set();
  let maxEn = 0, maxEb = 0;
  m.frame(1500, (mm) => {
    invul(mm);
    const t = mm.peekBytes("en_type", 10);
    t.forEach((x) => x && seen.add(x));
    maxEn = Math.max(maxEn, t.filter((x) => x).length);
    maxEb = Math.max(maxEb, countOn(mm, "eb_on", 16));
  });
  metrics.maxEnemies = maxEn; metrics.maxEnemyBullets = maxEb;
  return { ok: seen.size === 5 && maxEb > 0, detail: `familles vues=[${[...seen].sort().join(",")}], ennemis simultanes max=${maxEn}, projectiles ennemis max=${maxEb}` };
});

test("T13", "Mini-boss : apparition, 2 phases, destruction, niveau libere", () => {
  const m = startGame({ players: 2 });
  jumpToBoss(m);
  m.press(0, "B"); m.press(1, "B");
  let appeared = false, phase2 = false, state2 = false, fanSeen = 0;
  for (let i = 0; i < 4000 && m.peek("state") === ST.PLAY; i++) {
    m.frame(1, invul);
    // vaisseaux face au boss
    const bv = m.peek("boss_v");
    m.poke("pl_v", Math.max(40, bv)); m.poke("pl_v", Math.min(208, bv + 16), 1);
    m.poke("pl_u", 120); m.poke("pl_u", 120, 1);
    if (m.peek("boss_on")) appeared = true;
    if (m.peek("boss_on") === 2) state2 = true;
    if (m.peek("boss_on") === 2 && m.peek("boss_hp") < 125) phase2 = true;
    fanSeen = Math.max(fanSeen, countOn(m, "eb_on", 16));
    if (i === 400) m.screenshot(path.join(SHOTS, "06_miniboss.png"));
  }
  m.releaseAll();
  const st = m.peek("state");
  // bilan puis sequence narrative puis secteur 2 (vertical)
  m.frame(252, invul);
  const story = m.peek("state") === ST.STORY && m.peek("story_page") === 1;
  m.tap(0, "START"); m.frame(4);
  const next = story && m.peek("state") === ST.PLAY && m.peek("stage") === 1 && m.peek("orient") === 1;
  return { ok: appeared && state2 && phase2 && st === ST.CLEAR && next, detail: `apparu=${appeared}, phase2=${phase2}, projectiles max=${fanSeen}, etat apres destruction=${st}, enchainement secteur 2=${next}` };
});

test("T14", "Perte de vie, reapparition invulnerable, game over et retour au titre", () => {
  const m = startGame({ players: 1 });
  m.frame(80);
  const lives0 = m.peek("lives");
  let deaths = 0, prev = 1;
  for (let i = 0; i < 3000 && m.peek("state") === ST.PLAY; i++) {
    m.frame(1);
    m.poke("pl_invul", 0);
    // projectile ennemi force sur le vaisseau
    m.poke("eb_on", 1, 0); m.poke("eb_u", m.peek("pl_u") + 4, 0); m.poke("eb_v", m.peek("pl_v") + 4, 0);
    m.poke("eb_duhi", 0, 0); m.poke("eb_dulo", 0, 0); m.poke("eb_dvhi", 0, 0); m.poke("eb_dvlo", 0, 0);
    const a = m.peek("pl_alive");
    if (prev === 1 && a === 0) deaths++;
    prev = a;
  }
  const over = m.peek("state") === ST.OVER;
  m.frame(260);
  const cont = m.peek("state") === ST.CONT;
  m.frame(620);                                   // compte a rebours ecoule sans START
  return { ok: lives0 === 7 && deaths === 8 && over && cont && m.peek("state") === ST.TITLE, detail: `vies initiales=${lives0}, pertes=${deaths}, game over=${over}, ecran CONTINUER=${cont}, retour titre=${m.peek("state") === 0}` };
});

test("T15", "Armes evolutives : capsule ramassee -> niveau +1, perte de vie -> niveau -1", () => {
  const m = startGame({ players: 1 });
  m.frame(10, invul);
  m.poke("it_on", 1, 0); m.poke("it_u", m.peek("pl_u") + 4, 0); m.poke("it_v", m.peek("pl_v") + 4, 0);
  m.frame(2, invul);
  const lv = m.peek("pl_wlv");
  m.press(0, "B");
  let maxShots = 0;
  m.poke("it_on", 1, 0); m.poke("it_u", m.peek("pl_u") + 4, 0); m.poke("it_v", m.peek("pl_v") + 4, 0);
  m.frame(40, (mm) => { invul(mm); maxShots = Math.max(maxShots, countOn(mm, "pb_on", 16)); });
  const lv3 = m.peek("pl_wlv");
  m.releaseAll();
  m.poke("pl_invul", 0);
  m.poke("eb_on", 1, 0); m.poke("eb_u", m.peek("pl_u") + 4, 0); m.poke("eb_v", m.peek("pl_v") + 4, 0);
  m.frame(2);
  const lvAfter = m.peek("pl_wlv");
  return { ok: lv === 2 && lv3 === 3 && lvAfter === 2 && maxShots >= 10, detail: `niveaux 1->${lv}->${lv3}, apres perte=${lvAfter}, projectiles max (niv.3)=${maxShots}` };
});

test("T16", "Musique : sequence jouee sur pulse 1/2, triangle, bruit et DPCM", () => {
  const m = startGame({ players: 2, sound: true });
  m.frame(400, invul);
  const regs = new Set(m.apuLog.map((e) => e[1]));
  const notes = (a) => m.apuLog.filter((e) => e[1] === a).length;
  const dmc = m.apuLog.filter((e) => e[1] === 0x4015 && (e[2] & 0x10)).length;
  const ok = notes(0x4002) > 20 && notes(0x4006) > 20 && notes(0x400a) > 20 && notes(0x400e) > 20 && dmc > 5;
  return { ok, detail: `ecritures periode P1=${notes(0x4002)} P2=${notes(0x4006)} TRI=${notes(0x400a)} BRUIT=${notes(0x400e)}, declenchements DPCM=${dmc}, registres APU utilises=${regs.size}` };
});

test("T17", "Effets sonores : plusieurs SFX distincts declenches en jeu", () => {
  const m = startGame({ players: 2 });
  const sfx = new Map();
  const entry = m.s("sfx_play");
  const cpu = m.nes.cpu, emu = cpu.emulate;
  cpu.emulate = () => { if (((cpu.REG_PC + 1) & 0xffff) === entry) sfx.set(cpu.REG_ACC, (sfx.get(cpu.REG_ACC) || 0) + 1); return emu(); };
  m.press(0, "B"); m.press(1, "B");
  m.frame(1200, (mm, i) => { if (i < 1100) invul(mm); if (i === 500) mm.poke("gauge", 64); if (i === 502) mm.press(0, "A"); if (i === 506) mm.release(0, "A"); });
  cpu.emulate = emu;
  const names = ["SHOT_A", "SHOT_B", "HIT", "EXPLODE", "BIGEXPLODE", "POWERUP", "BEAM", "NOVA", "DEATH", "MENU", "ALERT", "DASH", "SHIELD", "SYNC", "COOPREADY"];
  const seen = [...sfx.keys()].sort((a, b) => a - b).map((k) => names[k] || k);
  return { ok: sfx.size >= 6, detail: `${sfx.size} effets distincts : ${seen.join(", ")}` };
});

test("T18", "Sauvegarde : record ecrit en PRG-RAM, relu apres coupure, copie corrompue toleree", () => {
  const m = startGame({ players: 1 });
  m.frame(5);
  [0, 1, 2, 3, 4, 5].forEach((i) => m.poke("score", [0, 4, 2, 4, 2, 0][i], i));
  // force le game over
  m.poke("lives", 0); m.poke("pl_invul", 0);
  m.poke("eb_on", 1, 0); m.poke("eb_u", m.peek("pl_u") + 4, 0); m.poke("eb_v", m.peek("pl_v") + 4, 0);
  m.frame(400);
  const sram = m.sram(64);
  const magic = String.fromCharCode(...sram.slice(0, 4));
  // "coupure" : nouvelle machine avec le contenu de la PRG-RAM
  const m2 = new Machine({ sram });
  m2.frame(30);
  const hi = m2.peekBytes("hi_solo", 6).join("");
  // corruption de la copie A -> la copie B doit etre utilisee
  const bad = sram.slice(); bad[7] ^= 0xff;
  const m3 = new Machine({ sram: bad });
  m3.frame(30);
  const hi3 = m3.peekBytes("hi_solo", 6).join("");
  // aucune sauvegarde : valeurs par defaut
  const m4 = new Machine({ sram: new Array(64).fill(0) });
  m4.frame(30);
  const hi4 = m4.peekBytes("hi_solo", 6).join("");
  return { ok: magic === "SPTL" && hi === "042420" && hi3 === "042420" && hi4 === "005000", detail: `signature=${magic}, relu=${hi}, copie A corrompue -> ${hi3}, vierge -> ${hi4}` };
});

test("T19", "Performances : scene chargee (2 joueurs niv.3, 10 ennemis, 16 tirs ennemis, boss, faisceau)", () => {
  const m = startGame({ players: 2 });
  m.frame(100, invul);
  m.poke("pl_wlv", 3); m.poke("pl_wlv", 3, 1);
  m.press(0, "B"); m.press(1, "B");
  const lag0 = m.peek("lag_count");
  m.frameCycles.length = 0;
  m.vblankUse.length = 0;
  let spLineMax = 0, linesOver = 0, framesOver = 0, sprFull = 0;
  m.poke("boss_on", 2); m.poke("boss_hp", 250); m.poke("boss_u", 176); m.poke("boss_v", 110);
  m.frame(600, (mm, i) => {
    invul(mm);
    mm.poke("boss_hp", 250);
    mm.poke("pl_u", 40); mm.poke("pl_v", 60); mm.poke("pl_u", 40, 1); mm.poke("pl_v", 190, 1);
    for (let k = 0; k < 10; k++) if (!mm.peek("en_type", k)) {
      mm.poke("en_type", 1 + (k % 4), k); mm.poke("en_hp", 50, k); mm.poke("en_u", 120 + (k * 13) % 100, k);
      mm.poke("en_v", 50 + k * 15, k); mm.poke("en_st", 0, k); mm.poke("en_p0", 100, k); mm.poke("en_t", 0, k);
      mm.poke("en_duhi", 0, k); mm.poke("en_dulo", 0, k);
    }
    for (let k = 0; k < 10; k++) { mm.poke("en_hp", 50, k); if (mm.peek("en_u", k) < 60) mm.poke("en_u", 200, k); }
    for (let k = 0; k < 16; k++) if (!mm.peek("eb_on", k)) {
      mm.poke("eb_on", 1, k); mm.poke("eb_u", 230, k); mm.poke("eb_v", 40 + k * 11, k);
      mm.poke("eb_duhi", 0xff, k); mm.poke("eb_dulo", 0x80, k); mm.poke("eb_dvhi", 0, k); mm.poke("eb_dvlo", 0, k);
    }
    if (mm.peek("beam_t") < 2) { mm.poke("gauge", 64); mm.poke("beam_t", 150); }
    const s = mm.maxSpritesPerLine();
    spLineMax = Math.max(spLineMax, s.max); linesOver += s.over; if (s.over) framesOver++;
    if (mm.peek("spr_left") === 0) sprFull++;
  });
  m.screenshot(path.join(SHOTS, "07_scene_chargee.png"));
  const fc = m.frameCycles.slice(5);
  const max = Math.max(...fc), avg = Math.round(fc.reduce((a, b) => a + b, 0) / fc.length);
  const lag = (m.peek("lag_count") - lag0) & 0xff;
  const vb = Math.max(...m.vblankUse);
  Object.assign(metrics, { stressMaxCycles: max, stressAvgCycles: avg, stressLag: lag, spLineMax, framesOver, sprFull, stressFrames: fc.length, stressVblankMax: vb });
  return { ok: lag === 0 && max < 29780 && vb < 2273, detail: `vblank utilise max=${vb}/2273 cycles, cycles/image max=${max} moy=${avg} (budget NTSC 29780 = ${(100 * max / 29780).toFixed(0)} %), images perdues=${lag}, sprites/ligne max=${spLineMax}, images avec >8 sprites/ligne=${framesOver}/${fc.length}, OAM saturee=${sprFull}` };
});

test("T20", "Performances : partie normale (secteur 1, 1900 images a 2 joueurs)", () => {
  const m = startGame({ players: 2 });
  m.press(0, "B"); m.press(1, "B");
  m.frame(5, invul);
  m.frameCycles.length = 0;
  m.vblankUse.length = 0;
  const lag0 = m.peek("lag_count");
  m.frame(1900, invul);
  const fc = m.frameCycles;
  const max = Math.max(...fc), avg = Math.round(fc.reduce((a, b) => a + b, 0) / fc.length);
  const lag = (m.peek("lag_count") - lag0) & 0xff;
  const vb = Math.max(...m.vblankUse);
  Object.assign(metrics, { normalMaxCycles: max, normalAvgCycles: avg, normalLag: lag, normalVblankMax: vb });
  return { ok: lag === 0 && vb < 2273, detail: `cycles/image max=${max} moy=${avg}, images perdues=${lag}, vblank utilise max=${vb}/2273 cycles` };
});

test("T21", "PAL : compensation 6/5 de la logique (cadence de jeu identique a 60 Hz)", () => {
  const m = startGame({ players: 2 });
  m.frame(5, invul);
  m.poke("region", 1);
  const c0 = camOf(m);
  m.frame(500, invul);
  const d = camOf(m) - c0;
  return { ok: d === 600, detail: `camera +${d} px en 500 images a 50 Hz (attendu 600 = 10 s de jeu). Logique seule : jsnes emule uniquement le NTSC.` };
});

test("T23", "Capacite propre LANCE : surcharge (vitesse x1.8, esquive), recharge", () => {
  const m = startGame({ players: 2 });
  m.frame(80, (mm) => { for (let i = 0; i < 16; i++) mm.poke("eb_on", 0, i); });
  m.poke("pl_u", 40); m.poke("pl_v", 120); m.poke("gauge", 0);
  m.press(0, "RIGHT");
  m.tap(0, "A", 1, 0);
  const u0 = m.peek("pl_u");
  let hitFree = true;
  m.frame(14, (mm) => {
    // projectile force sur le vaisseau pendant la surcharge
    mm.poke("eb_on", 1, 0); mm.poke("eb_u", mm.peek("pl_u") + 4, 0); mm.poke("eb_v", mm.peek("pl_v") + 4, 0);
    mm.poke("eb_duhi", 0, 0); mm.poke("eb_dulo", 0, 0); mm.poke("eb_dvhi", 0, 0); mm.poke("eb_dvlo", 0, 0);
    if (!mm.peek("pl_alive")) hitFree = false;
  });
  m.poke("eb_on", 0, 0);
  const du = m.peek("pl_u") - u0;
  m.releaseAll();
  const cd = m.peek("pl_abil_cd");
  m.tap(0, "A", 1, 0);
  const cd2 = m.peek("pl_abil_cd");
  return { ok: du >= 60 && hitFree && cd > 0 && cd2 === cd - 1, detail: `deplacement ${du}px en 14 images (normal 35), indemne=${hitFree}, recharge=${cd} images, 2e appui pendant la recharge ignore=${cd2 === cd - 1}` };
});

test("T24", "Capacite propre EGIDE : bouclier frontal absorbant 4 projectiles", () => {
  const m = startGame({ players: 2 });
  m.frame(80, (mm) => { for (let i = 0; i < 16; i++) mm.poke("eb_on", 0, i); });
  m.poke("pl_u", 60, 1); m.poke("pl_v", 120, 1); m.poke("gauge", 0); m.poke("pl_invul", 0, 1);
  m.tap(1, "A", 1, 0);
  const on = m.peek("pl_abil_t", 1);
  let absorbed = 0;
  for (let k = 0; k < 5; k++) {
    m.poke("eb_on", 1, k); m.poke("eb_u", 90, k); m.poke("eb_v", 124, k);
    m.poke("eb_duhi", 0xff, k); m.poke("eb_dulo", 0, k); m.poke("eb_dvhi", 0, k); m.poke("eb_dvlo", 0, k);
    m.frame(6, (mm) => { mm.poke("pl_u", 60, 1); mm.poke("pl_v", 120, 1); for (let i = 0; i < 10; i++) mm.poke("en_type", 0, i); });
    if (k === 1) m.screenshot(path.join(SHOTS, "08_bouclier_egide.png"));
    if (m.peek("pl_alive", 1) === 1 && k < 4) absorbed++;
  }
  // 5e projectile : bouclier epuise, il atteint le vaisseau
  m.frame(40, (mm) => { mm.poke("pl_u", 60, 1); mm.poke("pl_v", 120, 1); for (let i = 0; i < 10; i++) mm.poke("en_type", 0, i); });
  const diedAfter = m.peek("pl_alive", 1) === 0;
  return { ok: on > 0 && absorbed === 4 && diedAfter, detail: `bouclier actif=${on > 0}, absorbes=${absorbed}/4, 5e projectile touche=${diedAfter}` };
});

test("T25", "Affichage : tuiles des vaisseaux conformes a l'orientation (H et V)", () => {
  const res = [];
  for (const sector of [0, 1]) {
    const m = startGame({ players: 2, sector });
    m.frame(100, (mm) => {
      mm.poke("pl_invul", 0); mm.poke("pl_invul", 0, 1);
      for (let i = 0; i < 10; i++) mm.poke("en_type", 0, i);
      for (let i = 0; i < 16; i++) { mm.poke("eb_on", 0, i); mm.poke("pb_on", 0, i); }
    });
    const tbl = m.s("ship_tiles");
    const a = m.romByte(tbl + sector), b = m.romByte(tbl + 4 + sector);
    const oam = m.nes.cpu.mem.slice(0x200, 0x300);
    const rel = new Set();
    for (let i = 0; i < 64; i++) {
      if (oam[i * 4] >= 239 || oam[i * 4 + 2] > 1) continue;
      rel.add((oam[i * 4 + 2] ? "A" : "B") + (oam[i * 4 + 1] - (oam[i * 4 + 2] ? b : a)));
    }
    const ok = a >= 0x80 && b >= 0x80 && ["A0", "A1", "A2", "A3", "B0", "B1", "B2", "B3"].every((k) => rel.has(k)) && rel.size === 8;
    res.push({ o: sector ? "V" : "H", a, b, ok });
    if (sector) m.screenshot(path.join(SHOTS, "05_secteur2_vertical.png"));
  }
  return { ok: res.every((r) => r.ok), detail: res.map((r) => `${r.o}: LANCE $${r.a.toString(16)} EGIDE $${r.b.toString(16)} ${r.ok ? "ok" : "ERREUR"}`).join(", ") };
});

test("T26", "Sequence narrative : texte affiche lettre par lettre, START pour passer", () => {
  const m = new Machine();
  m.frame(40);
  m.tap(0, "START");
  m.frame(2);
  const st = m.peek("state");
  m.frame(400);
  // premiere ligne en table de noms : rangee 6, colonne 3
  const want = "AN 2291 - BRAS D'ORION";
  let line = "";
  for (let i = 0; i < want.length; i++) line += String.fromCharCode(m.nt(0x20c3 + i));
  m.screenshot(path.join(SHOTS, "09_sequence_narrative.png"));
  const music = m.peek("mus_on");
  m.tap(0, "START"); m.frame(4);
  return { ok: st === ST.STORY && line === want && music === 1 && m.peek("state") === ST.PLAY, detail: `etat=${st}, 1re ligne="${line}", musique=${music}, apres START etat=${m.peek("state")}` };
});

test("T27", "Attaque synchronisee : appuis sur A a moins de 8 images -> salve puissante", () => {
  const m = startGame({ players: 2 });
  m.frame(80, (mm) => { for (let i = 0; i < 16; i++) mm.poke("eb_on", 0, i); });
  // appuis decales de 3 images
  m.press(0, "B"); m.frame(3); m.press(1, "B"); m.frame(1);
  const syncShots = m.peekBytes("pb_on", 16).filter((x) => x === 3).length;
  const cd = m.peek("sync_cd");
  m.releaseAll(); m.frame(70);
  // appuis decales de 20 images : pas de salve
  m.press(0, "B"); m.frame(20); m.press(1, "B"); m.frame(1);
  const none = m.peekBytes("pb_on", 16).filter((x) => x === 3).length;
  m.releaseAll();
  // degats : un ennemi a 8 PV detruit par 2 projectiles synchronises
  m.frame(70);
  for (let i = 0; i < 16; i++) m.poke("pb_on", 0, i);
  m.poke("en_type", 1, 0); m.poke("en_hp", 8, 0); m.poke("en_u", m.peek("pl_u") + 30, 0); m.poke("en_v", m.peek("pl_v"), 0);
  m.poke("en_duhi", 0, 0); m.poke("en_dulo", 0, 0);
  m.press(0, "B"); m.press(1, "B"); m.frame(1); m.release(0, "B"); m.release(1, "B");
  let killed = false;
  m.frame(12, (mm) => { if (!mm.peek("en_type", 0)) killed = true; mm.poke("en_dvhi", 0, 0); mm.poke("en_dvlo", 0, 0); });
  return { ok: syncShots === 6 && cd > 0 && none === 0 && killed, detail: `salve=${syncShots} projectiles, recharge=${cd}, appuis trop espaces -> ${none}, ennemi 8 PV detruit=${killed}` };
});

test("T28", "Bilan de fin de secteur : sortie des vaisseaux, cibles, bonus de vies", () => {
  const m = startGame({ players: 2 });
  m.frame(5);
  m.poke("kills", 42); m.poke("lives", 3);
  [0, 0, 0, 0, 0, 0].forEach((v, i) => m.poke("score", v, i));
  // destruction immediate du boss
  m.poke("boss_on", 3); m.poke("boss_t", 99);
  m.frame(2);
  const cleared = m.peek("state") === ST.CLEAR;
  m.frame(58);                                   // state_t ~ 190 : debut du bilan
  const gone = m.peek("pl_alive") === 0 && m.peek("pl_alive", 1) === 0;
  const txt = String.fromCharCode(...m.peekBytes("bilan_buf", 9));
  const s0 = m.peekBytes("score", 6).join("");
  m.frame(40);
  m.screenshot(path.join(SHOTS, "10_bilan.png"));
  const s1 = m.peekBytes("score", 6).join("");
  return { ok: cleared && gone && txt === "CIBLES 42" && s1 === "013000" && s0 === "010000", detail: `etat bilan=${cleared}, vaisseaux sortis=${gone}, texte="${txt}", score ${s0} -> ${s1} (+3 vies x 1000)` };
});

test("T29", "Decor multi-palettes : attributs VRAM conformes sur tout le secteur 1", () => {
  const m = startGame({ players: 2 });
  let abad = 0;
  const pals = new Set();
  const r = scrollWholeSector(m, 97, (mm, k) => { abad += attrErrors(mm); if (k === 7) mm.screenshot(path.join(SHOTS, "04_secteur1_horizontal.png")); });
  const attr = m.s("s1_attr");
  for (let i = 0; i < 64 * 7; i++) { const b = m.romByte(attr + i); for (let q = 0; q < 4; q++) pals.add((b >> (2 * q)) & 3); }
  let hud = true;
  for (let i = 0; i < 8; i++) if (m.nt(0x23c0 + i) !== 0x55) hud = false;
  return { ok: abad === 0 && r.bad === 0 && hud && pals.size === 3, detail: `${r.chunks} controles, erreurs d'attributs=${abad}, palettes de decor utilisees=[${[...pals].sort()}], HUD intact=${hud}` };
});
test("T30", "Decor destructible : conteneur ancre au decor, detruit en 3 impacts, butin", () => {
  const m = startGame({ players: 1 });
  m.frame(20, invul);
  for (let i = 0; i < 10; i++) m.poke("en_type", 0, i);
  m.poke("en_type", 5, 0); m.poke("en_hp", 3, 0); m.poke("en_u", 200, 0); m.poke("en_v", m.peek("pl_v"), 0);
  m.poke("en_duhi", 0xff, 0); m.poke("en_dulo", 0, 0); m.poke("en_dvhi", 0, 0); m.poke("en_dvlo", 0, 0); m.poke("kills", 0);
  m.frame(10, invul);
  const moved = 200 - m.peek("en_u", 0);            // suit le decor : 1 px/image
  const hp0 = m.peek("en_hp", 0);
  const s0 = m.peekBytes("score", 6).join("");
  m.press(0, "B");
  let destroyed = -1;
  m.frame(80, (mm, i) => { invul(mm); if (destroyed < 0 && mm.peek("en_type", 0) === 0) destroyed = i; });
  m.releaseAll();
  const item = m.peekBytes("it_on", 3).some((x) => x);
  const s1 = m.peekBytes("score", 6).join("");
  return { ok: moved === 10 && hp0 === 3 && destroyed > 0 && item && s1 > s0, detail: `defilement suivi=${moved}px/10 img, detruit apres ${destroyed} images de tir, capsule=${item}, score ${s0}->${s1}` };
});

test("T31", "Point de reprise + CONTINUER : relance au relais (H et V), decor exact", () => {
  const res = [];
  for (const sector of [0, 1]) {
    const m = startGame({ players: 2, sector });
    const cp = cpOf(m);
    let msg = false, bonus = false;
    const l0 = m.peek("lives");
    m.frame(cp + 30, (mm) => { invul(mm); if (mm.peek("msg_id") === 6 && mm.peek("msg_t") > 0) msg = true; });
    bonus = m.peek("lives") === l0 + 1;
    const cpCam = m.peek("cp_cam") + 256 * m.peek("cp_cam", 1);
    m.frame(200, invul);
    // game over force
    m.poke("lives", 0);
    for (const p of [0, 1]) { m.poke("pl_alive", 0, p); m.poke("pl_resp", 0, p); }
    m.frame(205);
    const inCont = m.peek("state") === ST.CONT;
    m.tap(0, "START"); m.frame(3);
    const camAfter = camOf(m);
    const bad0 = vramErrors(m);
    let bad = 0;
    for (let k = 0; k < 6; k++) { m.frame(37, invul); bad += vramErrors(m); }
    const score = m.peekBytes("score", 6).join("");
    res.push({ sector, ok: msg && bonus && cpCam === cp && inCont && camAfter >= cp && camAfter < cp + 8 && bad0 + bad === 0 && m.peek("lives") === 7 && m.peek("continues") === 2,
      txt: `${sector ? "V" : "H"}: relais=${cpCam} msg=${msg} vie bonus=${bonus} CONTINUER=${inCont} reprise cam=${camAfter} erreurs VRAM=${bad0 + bad} vies=${m.peek("lives")} credits=${m.peek("continues")} score=${score}` });
    if (sector === 1) m.screenshot(path.join(SHOTS, "11_reprise_vertical.png"));
  }
  return { ok: res.every((r) => r.ok), detail: res.map((r) => r.txt).join(" ; ") };
});

test("T32", "Difficultes : RECRUE/PILOTE/VETERAN, EXPERT verrouille puis debloque et sauvegarde", () => {
  const out = [];
  for (const d of [0, 1, 2]) {
    const m = new Machine();
    m.frame(40); m.tap(0, "DOWN"); m.tap(0, "DOWN"); m.tap(0, "DOWN");
    if (d === 0) m.tap(0, "LEFT"); if (d === 2) m.tap(0, "RIGHT");
    m.tap(0, "START"); m.frame(2); m.tap(0, "START"); m.frame(2);
    out.push([m.peek("diff"), m.peek("lives"), m.peek("aim_speed"), m.peek("turret_mask"), m.peek("boss_hp0")]);
  }
  const ok1 = JSON.stringify(out) === JSON.stringify([[0, 9, 0, 127, 150], [1, 7, 0, 127, 200], [2, 4, 16, 63, 250]]);
  // EXPERT indisponible sans deblocage : DROITE depuis VETERAN revient a RECRUE
  const m = new Machine();
  m.frame(40); m.tap(0, "DOWN"); m.tap(0, "DOWN"); m.tap(0, "DOWN"); m.tap(0, "RIGHT"); m.tap(0, "RIGHT");
  const locked = m.peek("diff") === 0;
  // fin de campagne : epilogue -> deblocage ecrit en PRG-RAM
  m.tap(0, "START"); m.frame(2);
  m.poke("story_page", 5); m.tap(0, "START"); m.frame(10);
  const sram = m.sram(64);
  const m2 = new Machine({ sram });
  m2.frame(40); m2.tap(0, "DOWN"); m2.tap(0, "DOWN"); m2.tap(0, "DOWN"); m2.tap(0, "RIGHT"); m2.tap(0, "RIGHT");
  const expert = m2.peek("diff") === 3 && m2.peek("unlocked") === 1;
  return { ok: ok1 && locked && expert, detail: `[diff, vies solo, vitesse visee, masque tourelles, PV boss] = ${JSON.stringify(out)} ; EXPERT verrouille=${locked}, debloque apres l'epilogue et relu=${expert}` };
});

// Verifie les attributs visibles d'un secteur horizontal -> nb d'erreurs
function attrErrors(m) {
  const attr = m.s("s" + (m.peek("stage") + 1) + "_attr");
  const cam = camOf(m);
  let bad = 0;
  for (let g = Math.floor(cam / 32); g <= Math.floor((cam + 255) / 32); g++) {
    const mg = mapPos(m, g * 4) >> 2;
    const nc = (g * 4) & 63, base = (nc & 32 ? 0x27c0 : 0x23c0) + ((nc & 31) >> 2);
    for (let r = 1; r < 8; r++) if (m.romByte(attr + mg * 7 + r - 1) !== m.nt(base + 8 * r)) bad++;
  }
  return bad;
}

test("T33", "Secteur 3 Ceinture brisee : decor/attributs, unites lourdes, Essaim-mere, epilogue", () => {
  const m = startGame({ players: 2, sector: 2 });
  const okSector = m.peek("stage") === 2 && m.peek("orient") === 0;
  const chr = [m.nes.mmap.chrRomBank1 || 0];
  let vbad = 0, abad = 0, heavy = false, heavyShot = false;
  for (let k = 0; k < 18; k++) {
    m.frame(97, (mm) => {
      invul(mm);
      for (let i = 0; i < 10; i++) if (mm.peek("en_type", i) === 6) { heavy = true; if (mm.peek("en_st", i) === 1 && mm.peek("en_t", i) === 21) heavyShot = true; }
    });
    vbad += vramErrors(m); abad += attrErrors(m);
    if (k === 8) m.screenshot(path.join(SHOTS, "12_secteur3_ceinture.png"));
  }
  // boss : drones laches et anneaux de 8 projectiles
  jumpToBoss(m);
  let drones = 0, ring = 0;
  m.press(0, "B"); m.press(1, "B");
  for (let i = 0; i < 1200 && m.peek("state") === ST.PLAY; i++) {
    const before = m.peekBytes("en_type", 10).filter((x) => x === 1).length;
    m.frame(1, invul);
    const bv = m.peek("boss_v");
    m.poke("pl_v", Math.max(40, bv)); m.poke("pl_v", Math.min(208, bv + 16), 1); m.poke("pl_u", 110); m.poke("pl_u", 110, 1);
    if (m.peek("boss_on") === 2 && m.peekBytes("en_type", 10).filter((x) => x === 1).length > before) drones++;
    ring = Math.max(ring, countOn(m, "eb_on", 16));
    if (i === 300) m.screenshot(path.join(SHOTS, "13_essaim_mere.png"));
  }
  m.releaseAll();
  const cleared = m.peek("state") === ST.CLEAR;
  m.frame(252, invul);
  const epi = m.peek("state") === ST.STORY && m.peek("story_page") === 3;   // arrivee secteur 4
  return { ok: okSector && vbad === 0 && abad === 0 && heavy && heavyShot && drones > 0 && ring >= 8 && cleared && epi,
    detail: `secteur charge=${okSector}, erreurs VRAM decor=${vbad} attributs=${abad}, unites lourdes=${heavy} (tirent=${heavyShot}), drones laches par le boss=${drones}, projectiles max=${ring}, boss vaincu=${cleared}, epilogue=${epi}` };
});

test("T34", "Secteurs debloques : sauvegardes, seuls les debloques sont proposes au menu", () => {
  const m = new Machine();
  m.frame(40);
  m.tap(0, "DOWN"); m.tap(0, "DOWN"); m.tap(0, "RIGHT");
  const lockedOnly1 = m.peek("sector_sel") === 0;
  // termine le secteur 1
  m.tap(0, "START"); m.frame(2); m.tap(0, "START"); m.frame(4);
  m.poke("boss_on", 3); m.poke("boss_t", 99);
  m.frame(252);
  const unl = m.peek("sectors_unl");
  const sram = m.sram(64);
  const m2 = new Machine({ sram });
  m2.frame(40); m2.tap(0, "DOWN"); m2.tap(0, "DOWN"); m2.tap(0, "RIGHT");
  const s2 = m2.peek("sector_sel");
  m2.tap(0, "RIGHT");
  const back = m2.peek("sector_sel");
  return { ok: lockedOnly1 && unl === 3 && s2 === 1 && back === 0, detail: `sauvegarde vierge : secteur 2 inaccessible=${lockedOnly1} ; apres secteur 1 : masque=${unl}, menu -> secteur ${s2 + 1} puis ${back + 1}` };
});

test("T35", "Acces libre (B au titre) : secteur 3 jouable sans sauvegarde, sauvegarde inchangee", () => {
  const m = new Machine();
  m.frame(40);
  m.tap(0, "DOWN"); m.tap(0, "DOWN"); m.tap(0, "RIGHT");
  const locked = m.peek("sector_sel") === 0;
  m.tap(0, "A");
  m.tap(0, "RIGHT"); m.tap(0, "RIGHT");
  const sel = m.peek("sector_sel");
  let txt = ""; for (let i = 0; i < 20; i++) txt += String.fromCharCode(m.nt(0x2327 + i));
  m.screenshot(path.join(SHOTS, "01_titre.png"));
  m.tap(0, "START"); m.frame(2); m.tap(0, "START"); m.frame(4);
  const playing = m.peek("state") === ST.PLAY && m.peek("stage") === 2;
  return { ok: locked && sel === 2 && txt.startsWith("ACCES LIBRE") && playing && m.peek("sectors_unl") === 1, detail: `sans acces libre : verrouille=${locked} ; avec B : secteur ${sel + 1}, texte="${txt.trim()}", partie secteur 3 lancee=${playing}, sauvegarde intacte=${m.peek("sectors_unl") === 1}` };
});

test("T36", "Secteur 4 Cite de Lumen (V) : decor/attributs, soutiens qui reparent, Garde-ciel, epilogue", () => {
  const m = startGame({ players: 2, sector: 3 });
  const ok0 = m.peek("stage") === 3 && m.peek("orient") === 1;
  m.vblankUse.length = 0;
  let vbad = 0, repaired = false, support = false;
  for (let k = 0; k < 16; k++) {
    m.frame(101, (mm) => {
      invul(mm);
      for (let i = 0; i < 10; i++) if (mm.peek("en_type", i) === 7) {
        support = true;
        // place un drone blesse a cote du soutien : il doit etre repare
        if (mm.peek("en_st", i) === 1 && mm.peek("en_t", i) === 40) {
          for (let j = 0; j < 10; j++) if (!mm.peek("en_type", j)) {
            mm.poke("en_type", 1, j); mm.poke("en_hp", 1, j); mm.poke("en_u", mm.peek("en_u", i) + 10, j); mm.poke("en_v", mm.peek("en_v", i), j);
            mm.poke("en_duhi", 0, j); mm.poke("en_dulo", 0, j); mm.poke("en_dvhi", 0, j); mm.poke("en_dvlo", 0, j); mm.poke("en_p0", 0, j);
            mm._probe = j; break;
          }
        }
      }
      if (mm._probe !== undefined && mm.peek("en_type", mm._probe) === 1 && mm.peek("en_hp", mm._probe) >= 3) repaired = true;
    });
    vbad += vramErrors(m);
    if (k === 8) m.screenshot(path.join(SHOTS, "14_secteur4_lumen.png"));
  }
  const vb = Math.max(...m.vblankUse);
  jumpToBoss(m);
  let dirs = new Set();
  m.press(0, "B"); m.press(1, "B");
  for (let i = 0; i < 1500 && m.peek("state") === ST.PLAY; i++) {
    m.frame(1, invul);
    const bv = m.peek("boss_v");
    m.poke("pl_v", Math.max(8, bv)); m.poke("pl_v", Math.min(232, bv + 16), 1); m.poke("pl_u", 60); m.poke("pl_u", 60, 1);
    if (m.peek("boss_on") === 2) for (let e = 0; e < 16; e++) if (m.peek("eb_on", e)) dirs.add(m.peek("eb_duhi", e) * 256 + m.peek("eb_dvhi", e));
    if (i === 400) m.screenshot(path.join(SHOTS, "15_garde_ciel.png"));
  }
  m.releaseAll();
  const cleared = m.peek("state") === ST.CLEAR;
  m.frame(252, invul);
  const epi = m.peek("state") === ST.STORY && m.peek("story_page") === 4;   // arrivee secteur 5
  return { ok: ok0 && vbad === 0 && support && repaired && dirs.size >= 6 && cleared && epi && vb < 2273,
    detail: `secteur charge=${ok0}, erreurs VRAM (tuiles+attributs)=${vbad}, vblank max=${vb}/2273, soutiens=${support}, reparation observee=${repaired}, directions de spirale distinctes=${dirs.size}, boss vaincu=${cleared}, epilogue=${epi}` };
});

// Place une capsule d'age donne sur le joueur p et la fait ramasser
function grab(m, p, age) {
  m.poke("it_on", 1, 0); m.poke("it_t", age, 0);
  m.poke("it_u", m.peek("pl_u", p) + 4, 0); m.poke("it_v", m.peek("pl_v", p) + 4, 0);
  m.frame(2, invul);
}
function clearField(mm) { for (let i = 0; i < 10; i++) mm.poke("en_type", 0, i); for (let i = 0; i < 16; i++) mm.poke("eb_on", 0, i); }

test("T37", "Capsules changeantes P/L/M/B et laser percant", () => {
  const m = startGame({ players: 1 });
  m.frame(20, (mm) => { invul(mm); clearField(mm); });
  // le type change toutes les 64 images
  m.poke("it_on", 1, 1); m.poke("it_t", 0, 1); m.poke("it_u", 200, 1); m.poke("it_v", 60, 1);
  const kinds = [];
  for (let k = 0; k < 4; k++) { kinds.push((m.peek("it_t", 1) >> 6) & 3); m.frame(64, invul); }
  m.poke("it_on", 0, 1);
  grab(m, 0, 64);                                     // L
  const wt = m.peek("pl_wtype"), lv = m.peek("pl_wlv");
  grab(m, 0, 64);                                     // L de nouveau : niveau +1
  const lv2 = m.peek("pl_wlv");
  // laser percant : deux ennemis alignes touches par le meme trait
  m.poke("pl_wlv", 1);
  const pu = m.peek("pl_u"), pv = m.peek("pl_v");
  for (const [i, du] of [[0, 40], [1, 80]]) {
    m.poke("en_type", 3, i); m.poke("en_hp", 30, i); m.poke("en_u", pu + du, i); m.poke("en_v", pv - 4, i);
    m.poke("en_duhi", 0, i); m.poke("en_dulo", 0, i); m.poke("en_dvhi", 0, i); m.poke("en_dvlo", 0, i); m.poke("en_t", 1, i);
  }
  m.press(0, "B"); m.frame(1); m.release(0, "B");
  m.frame(20, (mm) => { invul(mm); for (const i of [0, 1]) { mm.poke("en_u", pu + (i ? 80 : 40), i); mm.poke("en_t", 1, i); } for (let e = 0; e < 16; e++) mm.poke("eb_on", 0, e); });
  const hit0 = 30 - m.peek("en_hp", 0), hit1 = 30 - m.peek("en_hp", 1);
  m.screenshot(path.join(SHOTS, "16_laser.png"));
  return { ok: JSON.stringify(kinds) === "[0,1,2,3]" && wt === 1 && lv === 1 && lv2 === 2 && hit0 > 0 && hit1 > 0,
    detail: `types successifs=${kinds.map((k) => "PLMB"[k]).join("")}, capsule L -> arme ${"SLM"[wt]}${lv}, 2e L -> niveau ${lv2}, trait unique : 1er ennemi -${hit0} PV, 2e ennemi -${hit1} PV (percant)` };
});

test("T38", "Missiles a tete chercheuse : recalage lateral sur la cible", () => {
  const m = startGame({ players: 1 });
  m.frame(20, (mm) => { invul(mm); clearField(mm); });
  grab(m, 0, 128);                                    // M
  const wt = m.peek("pl_wtype");
  const pu = m.peek("pl_u"), pv = m.peek("pl_v");
  // cible decalee de 50 px lateralement
  m.poke("en_type", 3, 0); m.poke("en_hp", 40, 0); m.poke("en_u", pu + 120, 0); m.poke("en_v", pv + 50, 0);
  m.poke("en_duhi", 0, 0); m.poke("en_dulo", 0, 0); m.poke("en_dvhi", 0, 0); m.poke("en_dvlo", 0, 0);
  m.press(0, "B"); m.frame(1); m.release(0, "B");
  m.frame(40, (mm) => { invul(mm); mm.poke("en_u", pu + 120, 0); mm.poke("en_v", pv + 50, 0); mm.poke("en_t", 1, 0); for (let e = 0; e < 16; e++) mm.poke("eb_on", 0, e); });
  const dmg = 40 - m.peek("en_hp", 0);
  return { ok: wt === 2 && dmg >= 4, detail: `arme ${"SLM"[wt]}, cible a +50 px lateralement : ${dmg} PV infliges (2 par missile)` };
});

test("T39", "Bombes (SELECT) : munitions, projectiles effaces, degats, invulnerabilite, HUD", () => {
  const m = startGame({ players: 2 });
  m.frame(20, (mm) => { invul(mm); clearField(mm); });
  for (let i = 0; i < 4; i++) { m.poke("en_type", 1, i); m.poke("en_hp", 5, i); m.poke("en_u", 150, i); m.poke("en_v", 60 + 30 * i, i); }
  for (let i = 0; i < 10; i++) { m.poke("eb_on", 1, i); m.poke("eb_u", 180, i); m.poke("eb_v", 50 + 10 * i, i); }
  const b0 = m.peek("pl_bombs", 1);
  m.poke("pl_invul", 0, 1);
  m.tap(1, "SELECT", 1, 0);
  const b1 = m.peek("pl_bombs", 1), inv = m.peek("pl_invul", 1);
  const en = countOn(m, "en_type", 10), eb = countOn(m, "eb_on", 16);
  m.frame(6);
  let hud = ""; for (let i = 0; i < 9; i++) hud += String.fromCharCode(m.nt(0x204f + i));
  // sans munitions : rien
  m.poke("pl_bombs", 0, 1); m.poke("nova_t", 0);
  m.tap(1, "SELECT", 1, 0);
  const none = m.peek("nova_t") === 0;
  // une capsule B recharge
  grab(m, 1, 192);
  return { ok: b0 === 2 && b1 === 1 && inv > 30 && en === 0 && eb === 0 && hud === "S1*2 S1*1" && none && m.peek("pl_bombs", 1) === 1,
    detail: `bombes ${b0}->${b1}, invulnerable=${inv} img, ennemis restants=${en}, projectiles=${eb}, HUD="${hud}", sans munition inactif=${none}, capsule B -> ${m.peek("pl_bombs", 1)}` };
});

test("T40", "Vie bonus tous les 20 000 points (max 9)", () => {
  const m = startGame({ players: 2 });
  m.frame(5);
  m.poke("lives", 5);
  [0, 1, 9, 9, 0, 0].forEach((v, i) => m.poke("score", v, i));   // 019 900
  m.poke("ext_done", 0);
  // +200 points via un drone detruit : passage a 020 000 -> +1 vie
  m.poke("en_type", 1, 0); m.poke("en_hp", 1, 0); m.poke("en_u", 150, 0); m.poke("en_v", 100, 0);
  m.poke("en_duhi", 0, 0); m.poke("en_dulo", 0, 0);
  m.frame(1);
  m.poke("en_hp", 0, 0);
  // appel direct : 100 points
  const before = m.peek("lives");
  m.poke("eb_on", 0, 0);
  m.poke("pb_on", 1, 0); m.poke("pb_kind", 0, 0); m.poke("pb_u", 150, 0); m.poke("pb_v", 104, 0); m.poke("pb_du", 0, 0); m.poke("pb_dv", 0, 0);
  m.poke("en_hp", 1, 0);
  m.frame(3, invul);
  const s1 = m.peekBytes("score", 6).join(""), l1 = m.peek("lives");
  // 9 vies maximum
  m.poke("lives", 9); [0, 3, 9, 9, 0, 0].forEach((v, i) => m.poke("score", v, i));
  m.poke("en_type", 1, 0); m.poke("en_hp", 1, 0); m.poke("en_u", 150, 0); m.poke("en_v", 100, 0);
  m.poke("pb_on", 1, 0); m.poke("pb_u", 150, 0); m.poke("pb_v", 104, 0);
  m.frame(3, invul);
  return { ok: s1 === "020000" && l1 === before + 1 && m.peek("lives") === 9 && m.peek("ext_done") === 2,
    detail: `score ${s1} : vies ${before} -> ${l1} ; plafond : ${m.peek("lives")} vies, palier=${m.peek("ext_done")}` };
});

test("T41", "Secteur 5 Chantiers d'Hadar : decor, mines, boss a tourelles destructibles", () => {
  const m = startGame({ players: 2, sector: 4 });
  const ok0 = m.peek("stage") === 4 && m.peek("orient") === 0;
  let vbad = 0, abad = 0, miner = false, mines = 0, booms = 0;
  for (let k = 0; k < 14; k++) {
    m.frame(97, (mm) => {
      invul(mm);
      const t = mm.peekBytes("en_type", 10);
      if (t.includes(8)) miner = true;
      mines = Math.max(mines, t.filter((x) => x === 9).length);
    });
    vbad += vramErrors(m); abad += attrErrors(m);
    if (k === 6) m.screenshot(path.join(SHOTS, "17_secteur5_hadar.png"));
  }
  // explosion d'une mine pres d'un vaisseau : anneau de projectiles
  for (let i = 0; i < 16; i++) m.poke("eb_on", 0, i);
  m.poke("en_type", 9, 9); m.poke("en_hp", 2, 9); m.poke("en_t", 0, 9);
  m.poke("en_u", m.peek("pl_u") + 20, 9); m.poke("en_v", m.peek("pl_v"), 9);
  m.frame(2, invul);
  const ring = countOn(m, "eb_on", 16), mineGone = m.peek("en_type", 9) !== 9;
  // boss : noyau invulnerable tant que les tourelles sont debout
  jumpToBoss(m);
  m.frame(260, (mm) => { invul(mm); clearField(mm); });
  const parts0 = [m.peek("part_hp"), m.peek("part_hp", 1)], hp0 = m.peek("boss_hp");
  m.press(0, "B"); m.press(1, "B");
  let hpWhileParts = hp0, partsDead = -1;
  for (let i = 0; i < 2500 && m.peek("state") === ST.PLAY; i++) {
    m.frame(1, invul);
    const bv = m.peek("boss_v");
    m.poke("pl_u", 100); m.poke("pl_u", 100, 1);
    m.poke("pl_v", Math.max(40, bv - 16)); m.poke("pl_v", Math.min(208, bv + 28), 1);
    if (partsDead < 0 && (m.peek("part_hp") || m.peek("part_hp", 1))) hpWhileParts = m.peek("boss_hp");
    if (partsDead < 0 && !m.peek("part_hp") && !m.peek("part_hp", 1)) partsDead = i;
    if (i === 60) m.screenshot(path.join(SHOTS, "18_croiseur.png"));
    if (partsDead > 0) { m.poke("pl_v", Math.max(40, bv)); m.poke("pl_v", Math.min(208, bv + 16), 1); }
  }
  m.releaseAll();
  const cleared = m.peek("state") === ST.CLEAR;
  m.frame(252, invul);
  const epi = m.peek("state") === ST.STORY && m.peek("story_page") === 5;
  return { ok: ok0 && vbad === 0 && abad === 0 && miner && mines > 0 && ring >= 8 && mineGone && parts0[0] > 0 && hpWhileParts === hp0 && partsDead > 0 && cleared && epi,
    detail: `secteur charge=${ok0}, VRAM ${vbad}/${abad} erreurs, poseurs=${miner}, mines simultanees=${mines}, explosion -> ${ring} projectiles, tourelles PV=[${parts0}], noyau intact tant que tourelles=${hpWhileParts === hp0}, tourelles detruites apres ${partsDead} img, boss vaincu=${cleared}, epilogue=${epi}` };
});

test("T22", "Compilation reproductible : deux constructions identiques octet pour octet", () => {
  const { execSync } = require("child_process");
  const rom = path.join(ROOT, "build", "spatial.nes");
  const h1 = crypto.createHash("sha256").update(fs.readFileSync(rom)).digest("hex");
  execSync("make clean >/dev/null && make >/dev/null", { cwd: ROOT });
  const h2 = crypto.createHash("sha256").update(fs.readFileSync(rom)).digest("hex");
  metrics.sha256 = h2;
  metrics.romSize = fs.statSync(rom).size;
  return { ok: h1 === h2, detail: `sha256=${h2.slice(0, 16)}...` };
});

// ---------------------------------------------------------------------------
const pass = results.filter((r) => r.ok).length;
console.log(`\n${pass}/${results.length} tests reussis`);
const out = [];
out.push("# Resultats des tests automatises (emulation)", "");
out.push("> Fichier genere par `tests/run_tests.js`. **Tous ces tests sont realises en EMULATION (jsnes 1.2.1, NTSC).**");
out.push("> Aucun test sur materiel reel n'a ete effectue a ce stade.", "");
out.push(`Resultat : **${pass}/${results.length}** reussis.`, "");
out.push("| ID | Test | Resultat | Details |", "|---|---|---|---|");
for (const r of results) out.push(`| ${r.id} | ${r.name} | ${r.ok ? "OK" : "**ECHEC**"} | ${r.detail.replace(/\|/g, "/")} |`);
out.push("", "## Mesures", "", "```json", JSON.stringify(metrics, null, 2), "```", "");
fs.writeFileSync(path.join(ROOT, "docs", "RESULTATS_TESTS.md"), out.join("\n"));
process.exit(pass === results.length ? 0 : 1);
