// Enregistre les musiques du jeu en WAV (emulation jsnes, 44,1 kHz mono)
// Usage : node render_audio.js  -> docs/audio/*.wav
"use strict";
const fs = require("fs"), path = require("path");
const jsnes = require("jsnes");
const { Machine, ROOT } = require("./harness");
const OUT = path.join(ROOT, "docs", "audio");
fs.mkdirSync(OUT, { recursive: true });

function wav(file, samples) {
  const n = samples.length, buf = Buffer.alloc(44 + n * 2);
  buf.write("RIFF", 0); buf.writeUInt32LE(36 + n * 2, 4); buf.write("WAVEfmt ", 8);
  buf.writeUInt32LE(16, 16); buf.writeUInt16LE(1, 20); buf.writeUInt16LE(1, 22);
  buf.writeUInt32LE(44100, 24); buf.writeUInt32LE(88200, 28); buf.writeUInt16LE(2, 32); buf.writeUInt16LE(16, 34);
  buf.write("data", 36); buf.writeUInt32LE(n * 2, 40);
  for (let i = 0; i < n; i++) buf.writeInt16LE(Math.max(-32767, Math.min(32767, Math.round(samples[i] * 32767))), 44 + i * 2);
  fs.writeFileSync(file, buf);
}

function record(name, setup, seconds) {
  const m = new Machine({ sound: true });
  const samples = [];
  let rec = false;
  m.nes.opts.onAudioSample = (l) => { if (rec) samples.push(l); };
  m.nes.papu.nes.opts.onAudioSample = m.nes.opts.onAudioSample;
  setup(m);
  rec = true;
  m.frame(seconds * 60, (mm) => { mm.poke("pl_invul", 10); mm.poke("pl_invul", 10, 1); for (let i = 0; i < 10; i++) mm.poke("en_type", 0, i); for (let i = 0; i < 16; i++) mm.poke("eb_on", 0, i); });
  wav(path.join(OUT, name + ".wav"), samples);
  console.log(name, (samples.length / 44100).toFixed(1) + " s");
}

const start = (sector, skipStory) => (m) => {
  m.frame(30); m.tap(0, "DOWN"); m.tap(0, "DOWN"); if (sector) m.tap(0, "RIGHT"); m.tap(0, "START"); m.frame(2);
  if (skipStory) { m.tap(0, "START"); m.frame(2); }
};
record("1_menu_escadre", (m) => m.frame(2), 18);
record("2_histoire_liens", start(0, false), 16);
record("3_niveau_ascension", start(0, true), 22);

// Boss : saute a la fin du secteur 1, le script declenche l'apparition et le theme
record("4_boss_sentinelle", (m) => {
  start(0, true)(m);
  let p = m.s("script_h"); while (m.romByte(p) !== 220) p += 4;
  m.poke("script_ptr", p & 255); m.poke("script_ptr", p >> 8, 1);
  m.poke("cam_lo", 1744 & 255); m.poke("cam_hi", 1744 >> 8);
  m.frame(30, (mm) => { mm.poke("pl_invul", 10); mm.poke("pl_invul", 10, 1); });
  m.poke("boss_hp", 250);
}, 16);
