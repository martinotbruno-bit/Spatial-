; =============================================================================
; data.s - Palettes et scripts d'apparition des niveaux du prototype
; =============================================================================

;            fond  c1   c2   c3
pal_title:
    .byte $0F, $30, $21, $11,  $0F, $30, $21, $16,  $0F, $30, $21, $11,  $0F, $30, $21, $11
    .byte $0F, $02, $21, $30,  $0F, $06, $27, $38,  $0F, $04, $14, $2A,  $0F, $30, $27, $16
pal_stage_h:   ; Secteur 1 : station orbitale (metal froid)
    .byte $0F, $00, $10, $3C,  $0F, $30, $21, $16,  $0F, $00, $10, $3C,  $0F, $00, $10, $3C
    .byte $0F, $02, $21, $30,  $0F, $06, $27, $38,  $0F, $04, $14, $2A,  $0F, $30, $27, $16
pal_stage_v:   ; Secteur 2 : surface planetaire (ocre)
    .byte $0F, $08, $18, $38,  $0F, $30, $21, $16,  $0F, $08, $18, $38,  $0F, $08, $18, $38
    .byte $0F, $02, $21, $30,  $0F, $06, $27, $38,  $0F, $04, $14, $2A,  $0F, $30, $27, $16

; Scripts : declencheur (camera / 8 px), type, v, parametre
.macro SPAWN t, typ, v, p
    .byte t, typ, v, p
.endmacro
D = EN_DRONE
F = EN_FIGHTER
T = EN_TURRET
K = EN_KAMIKAZE

; --- Secteur 1 : horizontal (v = y ecran 40-208), fin a 220 ---
script_h:
    SPAWN  8, D,  64,  0
    SPAWN 10, D,  64,  8
    SPAWN 12, D,  64, 16
    SPAWN 14, D,  64, 24
    SPAWN 16, D,  64, 32
    SPAWN 24, D, 168,  0
    SPAWN 26, D, 168,  8
    SPAWN 28, D, 168, 16
    SPAWN 30, D, 168, 24
    SPAWN 32, D, 168, 32
    SPAWN 40, F,  80, 190
    SPAWN 44, F, 150, 170
    SPAWN 52, K,  60,  0
    SPAWN 54, K, 180,  0
    SPAWN 60, T,  48,  0
    SPAWN 62, T, 192,  0
    SPAWN 66, D, 110,  0
    SPAWN 67, D, 110, 16
    SPAWN 68, D, 110, 32
    SPAWN 69, D, 110, 48
    SPAWN 76, F,  60, 200
    SPAWN 76, F, 170, 200
    SPAWN 84, T,  48,  0
    SPAWN 86, T, 192,  0
    SPAWN 90, K, 120,  0
    SPAWN 92, K,  80,  0
    SPAWN 94, K, 160,  0
    SPAWN 100, D, 60,  0
    SPAWN 100, D, 180, 32
    SPAWN 102, D, 60,  8
    SPAWN 102, D, 180, 40
    SPAWN 104, D, 60, 16
    SPAWN 104, D, 180, 48
    SPAWN 112, F, 120, 180
    SPAWN 116, T,  48,  0
    SPAWN 116, T, 192,  0
    SPAWN 124, F,  70, 200
    SPAWN 126, F, 160, 200
    SPAWN 132, K,  60,  0
    SPAWN 133, K, 120,  0
    SPAWN 134, K, 180,  0
    SPAWN 144, D, 120,  0
    SPAWN 145, D, 120, 12
    SPAWN 146, D, 120, 24
    SPAWN 147, D, 120, 36
    SPAWN 148, D, 120, 48
    SPAWN 156, T,  48,  0
    SPAWN 158, T, 192,  0
    SPAWN 160, F,  90, 190
    SPAWN 162, F, 150, 190
    SPAWN 172, K,  50,  0
    SPAWN 172, K, 190,  0
    SPAWN 174, K, 120,  0
    SPAWN 180, D,  70,  0
    SPAWN 181, D,  70, 16
    SPAWN 182, D, 170,  0
    SPAWN 183, D, 170, 16
    SPAWN 190, F,  60, 200
    SPAWN 190, F, 120, 180
    SPAWN 190, F, 180, 200
    SPAWN 220, EN_BOSS, 0, 0
    .byte $FF

; --- Secteur 2 : vertical (v = x ecran 8-232), fin a 192 ---
script_v:
    SPAWN  8, D,  48,  0
    SPAWN 10, D,  48,  8
    SPAWN 12, D,  48, 16
    SPAWN 14, D,  48, 24
    SPAWN 20, D, 176,  0
    SPAWN 22, D, 176,  8
    SPAWN 24, D, 176, 16
    SPAWN 26, D, 176, 24
    SPAWN 34, F,  64, 170
    SPAWN 34, F, 160, 170
    SPAWN 44, K,  40,  0
    SPAWN 45, K, 112,  0
    SPAWN 46, K, 184,  0
    SPAWN 54, T,  32,  0
    SPAWN 54, T, 192,  0
    SPAWN 60, D, 112,  0
    SPAWN 61, D, 112, 16
    SPAWN 62, D, 112, 32
    SPAWN 63, D, 112, 48
    SPAWN 70, F,  40, 180
    SPAWN 72, F, 184, 180
    SPAWN 80, T,  64,  0
    SPAWN 80, T, 160,  0
    SPAWN 88, K,  60,  0
    SPAWN 89, K, 112,  0
    SPAWN 90, K, 164,  0
    SPAWN 96, D,  32,  0
    SPAWN 96, D, 192, 32
    SPAWN 98, D,  32,  8
    SPAWN 98, D, 192, 40
    SPAWN 104, F, 112, 170
    SPAWN 110, T, 32,   0
    SPAWN 110, T, 192,  0
    SPAWN 118, F,  56, 180
    SPAWN 118, F, 168, 180
    SPAWN 128, K,  40,  0
    SPAWN 128, K, 184,  0
    SPAWN 130, K, 112,  0
    SPAWN 140, D,  80,  0
    SPAWN 141, D,  80, 16
    SPAWN 142, D, 144,  0
    SPAWN 143, D, 144, 16
    SPAWN 152, T,  48,  0
    SPAWN 152, T, 176,  0
    SPAWN 160, F,  40, 190
    SPAWN 160, F, 112, 170
    SPAWN 160, F, 184, 190
    SPAWN 170, K,  60,  0
    SPAWN 171, K, 164,  0
    SPAWN 192, EN_BOSS, 0, 0
    .byte $FF
