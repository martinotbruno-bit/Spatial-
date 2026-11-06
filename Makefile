# Projet SPATIAL - chaine de compilation reproductible
# Prerequis : cc65 (ca65/ld65) >= 2.18, Python 3, Node.js >= 18 (tests)
CA65  ?= ca65
LD65  ?= ld65
PY    ?= python3

ROM   = build/spatial.nes
SRCS  = $(wildcard src/*.s src/*.inc)
GEN   = build/assets.inc build/chr.bin build/kick.dmc

all: $(ROM)

$(GEN): tools/gen_assets.py assets/sprites.txt assets/tiles.txt assets/music.txt
	$(PY) tools/gen_assets.py

build/main.o: $(SRCS) $(GEN)
	$(CA65) -I src -g -o $@ src/main.s

$(ROM): build/main.o cfg/mmc3.cfg
	$(LD65) -C cfg/mmc3.cfg -o $@ -m build/spatial.map -Ln build/spatial.lbl --dbgfile build/spatial.dbg build/main.o
	@$(PY) -c "import hashlib,sys;d=open('$@','rb').read();print('$@', len(d), 'octets  sha256', hashlib.sha256(d).hexdigest())"

# ROM livrable versionnee
dist: $(ROM)
	mkdir -p dist && cp $(ROM) dist/spatial-proto-phase1.nes

test: $(ROM)
	cd tests && npm install --silent && node run_tests.js && node make_sheet.js

clean:
	rm -rf build/*.o build/*.nes build/*.map build/*.lbl build/*.dbg build/*.inc build/*.bin build/*.dmc

.PHONY: all dist test clean
