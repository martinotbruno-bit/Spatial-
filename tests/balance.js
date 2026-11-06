// Mesures d'equilibrage du secteur 1 par le pilote automatique (emulation).
// Usage : node balance.js   -> docs/EQUILIBRAGE.md (section "Mesures")
"use strict";
const fs = require("fs"), path = require("path");
const { Machine, ROOT } = require("./harness");
const { Bot } = require("./bot");

const ST = { PLAY: 1, CLEAR: 2, OVER: 3, CONT: 6 };

const SECTOR = Number(process.argv[3] || 0);
function run({ players, ship = 0, diff, seed, profile }) {
  const m = new Machine();
  m.frame(40);
  m.poke("sectors_unl", 255);
  if (players === 2) m.tap(0, "RIGHT");
  m.tap(0, "DOWN");
  if (players === 1 && ship) m.tap(0, "RIGHT");
  m.tap(0, "DOWN");
  for (let i = 0; i < SECTOR; i++) m.tap(0, "RIGHT");
  m.tap(0, "DOWN");
  // difficulte : PILOTE par defaut
  if (diff === 0) m.tap(0, "LEFT");
  for (let i = 1; i < diff; i++) m.tap(0, "RIGHT");
  m.tap(0, "START"); m.frame(2); m.tap(0, "START"); m.frame(2);
  if (m.peek("stage") !== SECTOR) throw new Error(`secteur ${SECTOR + 1} non selectionne (stage=${m.peek("stage")})`);
  const bot = new Bot(m, { seed, ...profile });
  const lives0 = m.peek("lives");
  let deaths = 0, prev = [1, 1], bossStart = 0, bossEnd = 0, frames = 0, ebSum = 0, ebMax = 0;
  while (frames < 20000) {
    bot.step();
    m.frame(1);
    frames++;
    for (const p of [0, 1]) {
      const a = m.peek("pl_alive", p);
      if (m.peek("pl_on", p) && prev[p] === 1 && a === 0 && m.peek("state") === ST.PLAY) deaths++;
      prev[p] = a;
    }
    let eb = 0; for (let i = 0; i < 16; i++) eb += m.peek("eb_on", i) ? 1 : 0;
    ebSum += eb; ebMax = Math.max(ebMax, eb);
    if (!bossStart && m.peek("boss_on")) bossStart = frames;
    const st = m.peek("state");
    if (st === ST.CLEAR) { bossEnd = frames; break; }
    if (st === ST.OVER || st === ST.CONT) break;
  }
  return {
    players, ship, diff, seed, lives0, deaths, cleared: !!bossEnd,
    livesLeft: bossEnd ? m.peek("lives") : 0,
    bossSec: bossEnd ? ((bossEnd - bossStart) / 60).toFixed(1) : "-",
    kills: m.peek("kills"), score: Number(m.peekBytes("score", 6).join("")),
    ebAvg: (ebSum / frames).toFixed(1), ebMax, sec: (frames / 60).toFixed(0),
  };
}

const DIFF = ["RECRUE", "PILOTE", "VETERAN"];
const MODES = [{ players: 1, ship: 0, name: "Solo LANCE" }, { players: 1, ship: 1, name: "Solo EGIDE" }, { players: 2, ship: 0, name: "Coop" }];
const SEEDS = [1, 7, 42];
// Profils : reaction en images (~200 ms = 12 images pour un joueur moyen)
const PROFILES = { moyen: { react: 12, noise: 0.25 }, debutant: { react: 18, noise: 0.4 } };
const PROF = process.argv[2] || "moyen";
const rows = [];
for (const mode of MODES) for (let d = 0; d < 3; d++) {
  const rs = SEEDS.map((seed) => run({ ...mode, diff: d, seed, profile: PROFILES[PROF] }));
  const avg = (k) => (rs.reduce((a, r) => a + Number(r[k] === "-" ? NaN : r[k]), 0) / rs.length);
  const cleared = rs.filter((r) => r.cleared).length;
  const bossTimes = rs.filter((r) => r.cleared).map((r) => Number(r.bossSec));
  rows.push({ mode: mode.name, diff: DIFF[d], lives0: rs[0].lives0, deaths: avg("deaths").toFixed(1), cleared: `${cleared}/${rs.length}`,
    boss: bossTimes.length ? (bossTimes.reduce((a, b) => a + b, 0) / bossTimes.length).toFixed(0) + " s" : "-",
    kills: avg("kills").toFixed(0), ebAvg: avg("ebAvg").toFixed(1), ebMax: Math.max(...rs.map((r) => r.ebMax)) });
  const r = rows[rows.length - 1];
  console.log(`${r.mode.padEnd(11)} ${r.diff.padEnd(8)} vies=${r.lives0} pertes=${r.deaths} reussite=${r.cleared} boss=${r.boss} abattus=${r.kills} tirs ennemis moy=${r.ebAvg} max=${r.ebMax}`);
}
const md = ["| Mode | Difficulté | Vies | Pertes moy. | Secteur réussi | Durée boss | Ennemis abattus | Tirs ennemis (moy./max) |", "|---|---|---|---|---|---|---|---|"];
for (const r of rows) md.push(`| ${r.mode} | ${r.diff} | ${r.lives0} | ${r.deaths} | ${r.cleared} | ${r.boss} | ${r.kills} | ${r.ebAvg} / ${r.ebMax} |`);
fs.writeFileSync(path.join(ROOT, "build", `balance_${PROF}_s${SECTOR + 1}.md`), md.join("\n") + "\n");
console.log("\n" + md.join("\n"));
