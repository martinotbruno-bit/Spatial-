-- Campagne de test dans FCEUX (deuxieme emulateur, PPU plus precis que jsnes).
-- Lance par tests/run_fceux.js, qui fournit syms.lua (adresses du jeu) et le
-- dossier de sortie OUT. Le script joue les 8 secteurs a la suite :
--   * 700 images de jeu par secteur (tir maintenu, vaisseaux invulnerables),
--     capture d'ecran, extraction de la VRAM et de la RAM ;
--   * saut en fin de secteur, apparition du boss (capture), destruction
--     forcee, verification de la transition (bilan, histoire, secteur suivant) ;
--   * fin de campagne et retour au titre.
-- Les verifications de decor (VRAM contre carte) sont faites par run_fceux.js.
dofile("syms.lua")
local OUT = os.getenv("FCEUX_OUT") or "."
local log = io.open(OUT .. "/journal.txt", "w")
local function say(s) log:write(s .. "\n"); log:flush() end
local function rd(a, o) return memory.readbyte(a + (o or 0)) end
local function wr(a, v, o) memory.writebyte(a + (o or 0), v) end
local held = {}
local function frames(n, each)
  for i = 1, n do
    if each then each(i) end
    joypad.set(1, held); joypad.set(2, held)
    emu.frameadvance()
  end
end
local function tap(btn)
  local t = {}; t[btn] = true
  for i = 1, 2 do joypad.set(1, t); emu.frameadvance() end
  for i = 1, 4 do emu.frameadvance() end
end
local function invul() wr(S.pl_invul, 10); wr(S.pl_invul, 10, 1) end
local function dump(name)
  local f = io.open(OUT .. "/" .. name .. "_vram.bin", "wb")
  local t = {}
  for a = 0x2000, 0x27FF do t[#t + 1] = string.char(ppu.readbyte(a)) end
  f:write(table.concat(t)); f:close()
  f = io.open(OUT .. "/" .. name .. "_ram.bin", "wb")
  t = {}
  for a = 0, 0x7FF do t[#t + 1] = string.char(memory.readbyte(a)) end
  f:write(table.concat(t)); f:close()
end

frames(90)
say("boot etat=" .. rd(S.state) .. " region=" .. rd(S.region) .. " lag=" .. rd(S.lag_count))
gui.savescreenshotas(OUT .. "/00_titre.png")
wr(S.sectors_unl, 255)
tap("right")                          -- 2 joueurs
tap("start"); frames(4)               -- sequence narrative
say("histoire etat=" .. rd(S.state) .. " page=" .. rd(S.story_page))
tap("start"); frames(4)
held = { B = true }
for k = 0, 7 do
  local st, sg = rd(S.state), rd(S.stage)
  local lag0 = rd(S.lag_count)
  frames(700, invul)
  local lag = (rd(S.lag_count) - lag0) % 256
  gui.savescreenshotas(string.format("%s/%d_secteur%d.png", OUT, k + 1, k + 1))
  dump("s" .. (k + 1))
  local ori = rd(S.orient)
  -- saut pres de la fin du secteur : apparition du boss
  local stop = rd(S.sec_hdr, 2) + 256 * rd(S.sec_hdr, 3) - 16
  wr(S.cam_lo, stop % 256); wr(S.cam_hi, math.floor(stop / 256))
  local p = rd(S.sec_hdr, 14) + 256 * rd(S.sec_hdr, 15)
  while memory.readbyte(p + 1) ~= 15 do p = p + 4 end
  wr(S.script_ptr, p % 256); wr(S.script_ptr, math.floor(p / 256), 1); wr(S.sc_last, 0)
  frames(320, invul)
  local boss = rd(S.boss_on)
  gui.savescreenshotas(string.format("%s/%d_boss%d.png", OUT, k + 1, k + 1))
  wr(S.boss_on, 3); wr(S.boss_t, 99)
  frames(262, invul)
  local after, page = rd(S.state), rd(S.story_page)
  say(string.format("secteur %d etat=%d stage=%d orient=%d images_perdues=%d boss=%d apres=%d page=%d",
    k + 1, st, sg, ori, lag, boss, after, page))
  if k < 7 then held = {}; tap("start"); frames(4); held = { B = true } end
end
held = {}
frames(60)
gui.savescreenshotas(OUT .. "/9_fin.png")
local endpage = rd(S.story_page)
frames(900)
say("fin page=" .. endpage .. " etat_final=" .. rd(S.state) .. " debloques=" .. rd(S.sectors_unl))
say("termine")
log:close()
emu.exit()
