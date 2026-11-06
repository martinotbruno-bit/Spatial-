// Campagne de test dans FCEUX (Lua), ancien et nouveau moteur PPU.
// Usage : node run_fceux.js   (prerequis : fceux, xvfb-run)
// Resultats : docs/RESULTATS_FCEUX.md, captures dans docs/captures/fceux/
"use strict";
const fs = require("fs"), path = require("path"), { execFileSync } = require("child_process");
const ROOT = path.resolve(__dirname, "..");
const ROM = path.join(ROOT, "build", "spatial.nes");
const rom = fs.readFileSync(ROM);
const sym = {};
for (const l of fs.readFileSync(path.join(ROOT, "build", "spatial.lbl"), "utf8").split("\n")) {
  const m = l.match(/^al ([0-9A-F]+) \.(\w+)/);
  if (m) sym[m[2]] = parseInt(m[1], 16);
}
const NEED = ["state", "stage", "region", "lag_count", "pl_invul", "sectors_unl", "story_page", "sec_hdr",
  "cam_lo", "cam_hi", "script_ptr", "sc_last", "boss_on", "boss_t", "orient"];

// Lecture ROM : banc fixe ($C000+), banc de secteur mappe en $8000
const fixedByte = (a) => rom[16 + 30 * 8192 + (a - 0xc000)];
function bankByte(bank, a) { return rom[16 + bank * 8192 + (a - 0x8000)]; }

function verifySector(dir, k) {
  const vram = fs.readFileSync(path.join(dir, `s${k + 1}_vram.bin`));
  const ram = fs.readFileSync(path.join(dir, `s${k + 1}_ram.bin`));
  const bank = fixedByte(sym.sector_banks + k);
  const H = (o) => ram[sym.sec_hdr + o];
  const w16 = (o) => H(o) | (H(o + 1) << 8);
  const A = H(22), L = H(23), reps = H(24), max = H(1);
  const mapPos = (P) => { if (P < A) return P; const kk = P - A, t = L * reps; return kk < t ? A + (kk % L) : Math.min(A + L + (kk - t), max); };
  const rb = (a) => bankByte(bank, a);
  const ids = w16(6), tlo = w16(8), thi = w16(10), attr = w16(12);
  const cam = ram[sym.cam_lo] | (ram[sym.cam_hi] << 8);
  const nt = (a) => vram[a - 0x2000];     // FCEUX : $2000-$27FF lus en miroir vertical
  let bad = 0, checks = 0;
  if (H(0) === 0) {
    for (let c = Math.floor(cam / 8); c <= Math.floor((cam + 255) / 8); c++) {
      const id = rb(ids + mapPos(c)), tp = rb(tlo + id) | (rb(thi + id) << 8);
      const nc = c & 63, base = (nc & 32 ? 0x2400 : 0x2000) + (nc & 31);
      for (let r = 0; r < 26; r++) { checks++; if (rb(tp + r) !== nt(base + (r + 4) * 32)) bad++; }
    }
    if (attr) for (let g = Math.floor(cam / 32); g <= Math.floor((cam + 255) / 32); g++) {
      const mg = mapPos(g * 4) >> 2, nc = (g * 4) & 63, base = (nc & 32 ? 0x27c0 : 0x23c0) + ((nc & 31) >> 2);
      for (let r = 1; r < 8; r++) { checks++; if (rb(attr + mg * 7 + r - 1) !== nt(base + 8 * r)) bad++; }
    }
  } else {
    const vsy = ram[sym.vsy];
    for (let s = 0; s < 26; s++) {
      const ntrow = ((vsy >> 3) + s) % 30;
      let r = ((29 - ntrow) % 30 + 30) % 30;
      while (r < Math.floor(cam / 8) - 2) r += 30;
      const rr = mapPos(r), id = rb(ids + rr), tp = rb(tlo + id) | (rb(thi + id) << 8);
      for (let c = 0; c < 32; c++) { checks++; if (rb(tp + c) !== nt(0x2400 + ntrow * 32 + c)) bad++; }
      if (attr) for (let q = 0; q < 16; q++) {
        const want = (rb(attr + (rr >> 1) * 4 + (q >> 2)) >> (2 * (q & 3))) & 3;
        const got = (nt(0x27c0 + (ntrow >> 2) * 8 + (q >> 1)) >> ((q & 1) * 2 + ((ntrow >> 1) & 1) * 4)) & 3;
        checks++; if (want !== got) bad++;
      }
    }
  }
  // HUD intact
  const row1 = " SCORE ";
  let hud = true;
  for (let i = 0; i < row1.length; i++) if (nt(0x2020 + i) !== row1.charCodeAt(i)) hud = false;
  return { checks, bad, hud, cam };
}

function runMode(newPPU) {
  const name = newPPU ? "nouveau PPU" : "ancien PPU";
  const work = path.join(ROOT, "build", "fceux", newPPU ? "newppu" : "oldppu");
  fs.rmSync(work, { recursive: true, force: true });
  fs.mkdirSync(path.join(work, ".fceux"), { recursive: true });
  fs.writeFileSync(path.join(work, ".fceux", "fceux.cfg"), `SDL.NewPPU = ${newPPU ? 1 : 0}\nSDL.Sound = 0\n`);
  fs.writeFileSync(path.join(work, "syms.lua"), "S = {\n" + NEED.concat(["vsy"]).map((k) => `  ${k} = ${sym[k]},`).join("\n") + "\n}\n");
  fs.copyFileSync(path.join(__dirname, "fceux", "campagne.lua"), path.join(work, "campagne.lua"));
  const t0 = Date.now();
  try {
    execFileSync("xvfb-run", ["-a", "/usr/games/fceux", "--loadlua", "campagne.lua", ROM],
      { cwd: work, env: { ...process.env, HOME: work, FCEUX_OUT: work }, timeout: 900000, stdio: "ignore" });
  } catch (e) { /* fceux renvoie parfois un code non nul a la sortie */ }
  const journal = fs.existsSync(path.join(work, "journal.txt")) ? fs.readFileSync(path.join(work, "journal.txt"), "utf8") : "";
  const sectors = [];
  for (let k = 0; k < 8; k++) {
    const line = journal.split("\n").find((l) => l.startsWith(`secteur ${k + 1} `)) || "";
    const v = fs.existsSync(path.join(work, `s${k + 1}_vram.bin`)) ? verifySector(work, k) : null;
    const get = (key) => { const m = line.match(new RegExp(key + "=(-?\\d+)")); return m ? +m[1] : -1; };
    const ok = !!v && v.bad === 0 && v.hud && get("etat") === 1 && get("stage") === k && get("orient") === [0,1,0,1,0,1,0,0][k] && get("images_perdues") === 0 &&
      get("boss") >= 1 && get("apres") === 5 && get("page") === k + 1;
    sectors.push({ k, ok, line, v });
  }
  const fin = journal.split("\n").find((l) => l.startsWith("fin ")) || "";
  const finOk = /page=8 etat_final=0 debloques=255/.test(fin);
  // captures copiees dans docs/
  const cap = path.join(ROOT, "docs", "captures", "fceux", newPPU ? "newppu" : "oldppu");
  fs.mkdirSync(cap, { recursive: true });
  for (const f of fs.readdirSync(work)) if (f.endsWith(".png")) fs.copyFileSync(path.join(work, f), path.join(cap, f));
  return { name, sectors, fin, finOk, boot: journal.split("\n")[0] || "", s: ((Date.now() - t0) / 1000).toFixed(0), done: journal.includes("termine") };
}

const results = [runMode(false), runMode(true)];
const md = ["# Résultats dans FCEUX 2.6.5 (émulation)", "",
  "> Généré par `tests/run_fceux.js` : campagne complète jouée par script Lua dans",
  "> FCEUX, avec l'ancien et le nouveau moteur PPU. **Émulation uniquement** —",
  "> aucun test sur console.", ""];
let allOk = true;
for (const r of results) {
  md.push(`## ${r.name}`, "", `Démarrage : \`${r.boot}\` — durée ${r.s} s — script terminé : ${r.done}`, "",
    "| Secteur | Défilement | Résultat | Images perdues (700 img) | Tuiles + attributs vérifiés | Erreurs | HUD | Boss / transition |", "|---|---|---|---|---|---|---|---|");
  for (const s of r.sectors) {
    const g = (k) => { const m = s.line.match(new RegExp(k + "=(-?\\d+)")); return m ? m[1] : "?"; };
    md.push(`| ${s.k + 1} | ${g("orient") === "1" ? "vertical" : "horizontal"} | ${s.ok ? "OK" : "**ECHEC**"} | ${g("images_perdues")} | ${s.v ? s.v.checks : "-"} | ${s.v ? s.v.bad : "-"} | ${s.v && s.v.hud ? "intact" : "?"} | boss=${g("boss")}, état après=${g("apres")}, page=${g("page")} |`);
    allOk = allOk && s.ok;
  }
  md.push("", `Fin de campagne : \`${r.fin}\` → ${r.finOk ? "OK" : "**ECHEC**"}`, "");
  allOk = allOk && r.finOk && r.done;
  console.log(`${r.name} : ${r.sectors.filter((s) => s.ok).length}/8 secteurs OK, fin ${r.finOk ? "OK" : "ECHEC"} (${r.s} s)`);
}
md.push(`Captures : \`docs/captures/fceux/\`.`);
fs.writeFileSync(path.join(ROOT, "docs", "RESULTATS_FCEUX.md"), md.join("\n") + "\n");
process.exit(allOk ? 0 : 1);
