; =============================================================================
; defs.inc - Constantes materielles et constantes de jeu
; =============================================================================

; --- PPU ---------------------------------------------------------------------
PPUCTRL   = $2000
PPUMASK   = $2001
PPUSTATUS = $2002
OAMADDR   = $2003
PPUSCROLL = $2005
PPUADDR   = $2006
PPUDATA   = $2007
OAMDMA    = $4014

; PPUCTRL : NMI actif, sprites 8x8 en table $1000, decor en table $0000.
; (Configuration requise par le compteur de lignes MMC3 base sur A12.)
CTRL_BASE  = %10001000
CTRL_INC32 = %00000100
MASK_ON    = %00011110      ; decor + sprites, y compris les 8 pixels de gauche
MASK_OFF   = %00000000

; --- APU ---------------------------------------------------------------------
APU_P1_CTRL = $4000
APU_P1_SWP  = $4001
APU_P1_LO   = $4002
APU_P1_HI   = $4003
APU_P2_CTRL = $4004
APU_P2_SWP  = $4005
APU_P2_LO   = $4006
APU_P2_HI   = $4007
APU_TR_CTRL = $4008
APU_TR_LO   = $400A
APU_TR_HI   = $400B
APU_NO_CTRL = $400C
APU_NO_LO   = $400E
APU_NO_HI   = $400F
APU_DMC_CTRL = $4010
APU_DMC_RAW  = $4011
APU_DMC_ADDR = $4012
APU_DMC_LEN  = $4013
APU_STATUS  = $4015
APU_FRAME   = $4017
JOY1        = $4016
JOY2        = $4017

; --- MMC3 --------------------------------------------------------------------
MMC3_BANKSEL  = $8000
MMC3_BANKDATA = $8001
MMC3_MIRROR   = $A000       ; 0 = miroir vertical, 1 = miroir horizontal
MMC3_PRGRAM   = $A001       ; $80 = PRG-RAM active, ecriture autorisee
MMC3_IRQLATCH = $C000
MMC3_IRQRELOAD = $C001
MMC3_IRQOFF   = $E000
MMC3_IRQON    = $E001

; Ligne de declenchement de l'IRQ de separation HUD / zone de jeu.
; Le HUD occupe les lignes 0-31, la derniere rangee de tuiles du HUD (24-31)
; est vide pour masquer la ligne de transition.
IRQ_SPLIT_LINE = 30

; Marqueur de profilage : ecriture ignoree par le MMC3 ($4020-$5FFF non decode
; sur TKROM). Le banc de test (tests/) mesure les cycles CPU jusqu'a ce point.
DEBUG_MARK  = $5FF0
DEBUG_MARK_START = $5FF1

; --- Manettes ----------------------------------------------------------------
BTN_A      = $80
BTN_B      = $40
BTN_SELECT = $20
BTN_START  = $10
BTN_UP     = $08
BTN_DOWN   = $04
BTN_LEFT   = $02
BTN_RIGHT  = $01

; --- Etats du jeu --------------------------------------------------------------
ST_TITLE  = 0
ST_PLAY   = 1
ST_CLEAR  = 2
ST_OVER   = 3
ST_END    = 4
ST_STORY  = 5
ST_CONT   = 6

; --- Pools d'entites -----------------------------------------------------------
MAX_EN = 10     ; ennemis
MAX_EB = 16     ; projectiles ennemis
MAX_PB = 16     ; projectiles joueurs
MAX_FX = 8      ; explosions
MAX_IT = 3      ; capsules
BEAM_PTS = 8    ; points du Faisceau de Liaison

; Types d'ennemis
EN_NONE     = 0
EN_DRONE    = 1
EN_FIGHTER  = 2
EN_TURRET   = 3
EN_KAMIKAZE = 4
EN_POD      = 5     ; objet de decor destructible (conteneur, rocher...)
EN_HEAVY    = 6     ; unite lourde
EN_SUPPORT  = 7     ; appareil de soutien (repare les ennemis proches)
EN_BOSS     = 15    ; marqueur de script uniquement

; --- Regles --------------------------------------------------------------------
GAUGE_MAX     = 64
LIVES_SOLO    = 3
LIVES_COOP    = 5
BEAM_TIME     = 150
DASH_TIME     = 16      ; LANCE : surcharge
DASH_CD       = 90
SHIELD_TIME   = 120     ; EGIDE : bouclier frontal
SHIELD_CD     = 240
SHIELD_HP     = 4
SYNC_WINDOW   = 8       ; ecart max (images) entre les deux appuis sur A
SYNC_CD       = 60
SYNC_DMG      = 4
NOVA_TIME     = 24
INVUL_TIME    = 120
RESPAWN_TIME  = 80
BOSS_HP       = 250
BOSS_PHASE2   = 125
SPAWN_U       = 250  ; position "avant" d'apparition (hors champ partiel)

; En-tete de secteur (debut du banc PRG du secteur, copie dans sec_hdr).
; Fin de defilement et point de reprise (multiple de 32) y sont definis.
SH_ORIENT = 0
SH_MAXIDX = 1   ; derniere colonne/rangee de carte
SH_STOP   = 2   ; camera de fin de defilement (16 bits)
SH_CP     = 4   ; point de reprise (16 bits)
SH_IDS    = 6   ; pointeurs : ids, gabarits lo/hi, attributs (0 = aucun)
SH_TLO    = 8
SH_THI    = 10
SH_ATTR   = 12
SH_SCRIPT = 14
SH_PAL    = 16
SH_CHRBG  = 18  ; banc CHR R1 (decor $80-$FF)
SH_CHRSPR = 19  ; banc CHR R5 (sprites $C0-$FF)
SH_SONG   = 20
SH_BOSS   = 21  ; type de boss
SH_SIZE   = 22
CONTINUES = 3
