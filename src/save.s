; =============================================================================
; save.s - Sauvegarde non volatile (PRG-RAM MMC3 + pile, $6000-$7FFF)
; Deux copies (A puis B) avec signature et somme de controle : une coupure
; d'alimentation pendant l'ecriture ne peut corrompre qu'une seule copie.
; Disposition d'une copie (32 octets) :
;   0-3  signature "SPTL"   4  version   5-10 record solo   11-16 record coop
;   17   deblocages (bit 0 = mode expert)   18 secteurs debloques (bit k)
;   19   somme de controle
; =============================================================================
SAVE_VERSION = 2
SAVE_LEN     = 19           ; octets couverts par la somme (0-18)

save_magic: .byte "SPTL", SAVE_VERSION

; Retourne C=1 si la copie pointee par ptr0 est valide
save_check:
    ldy #0
@m:
    lda (ptr0),y
    cmp save_magic,y
    bne @bad
    iny
    cpy #5
    bne @m
    jsr save_sum
    ldy #SAVE_LEN
    cmp (ptr0),y
    bne @bad
    sec
    rts
@bad:
    clc
    rts

; A = somme des octets 4..17 de (ptr0), eor $A5
save_sum:
    ldy #4
    lda #0
    clc
@s:
    adc (ptr0),y
    iny
    cpy #SAVE_LEN
    bne @s
    eor #$A5
    rts

save_load:
    lda #<save_a
    sta ptr0
    lda #>save_a
    sta ptr0+1
    jsr save_check
    bcs @load
    lda #<save_b
    sta ptr0
    lda #>save_b
    sta ptr0+1
    jsr save_check
    bcs @load
    ; Aucune sauvegarde valide : valeurs par defaut puis ecriture
    ldx #5
@def:
    lda default_hi,x
    sta hi_solo,x
    sta hi_coop,x
    dex
    bpl @def
    lda #1
    sta sectors_unl
    jmp save_write
@load:
    ldy #5
    ldx #0
@l:
    lda (ptr0),y
    sta hi_solo,x
    iny
    inx
    cpx #12                 ; hi_solo puis hi_coop (contigus)
    bne @l
    lda (ptr0),y            ; y = 17
    sta unlocked
    iny
    lda (ptr0),y
    ora #1                  ; le secteur 1 est toujours disponible
    sta sectors_unl
    rts

default_hi: .byte 0, 0, 5, 0, 0, 0

; Ecrit la copie B puis la copie A
save_write:
    lda #$80                ; PRG-RAM : ecriture autorisee
    sta MMC3_PRGRAM
    lda #<save_b
    sta ptr0
    lda #>save_b
    sta ptr0+1
    jsr save_write_one
    lda #<save_a
    sta ptr0
    lda #>save_a
    sta ptr0+1
    jsr save_write_one
    lda #$C0                ; PRG-RAM : lecture seule (protection)
    sta MMC3_PRGRAM
    rts

save_write_one:
    ldy #0
@m:
    lda save_magic,y
    sta (ptr0),y
    iny
    cpy #5
    bne @m
    ldx #0
@d:
    lda hi_solo,x
    sta (ptr0),y
    iny
    inx
    cpx #12
    bne @d
    lda unlocked            ; octet 17 : deblocages (bit 0 = EXPERT)
    sta (ptr0),y
    iny
    lda sectors_unl         ; octet 18 : secteurs debloques
    sta (ptr0),y
    jsr save_sum
    ldy #SAVE_LEN
    sta (ptr0),y
    rts

; Met a jour le record correspondant au mode si score > record
save_update_hi:
    lda nplayers
    cmp #2
    beq @coop
    lda #<hi_solo
    sta ptr0
    lda #>hi_solo
    sta ptr0+1
    jmp @cmp
@coop:
    lda #<hi_coop
    sta ptr0
    lda #>hi_coop
    sta ptr0+1
@cmp:
    ldy #0
@c:
    lda score,y
    cmp (ptr0),y
    bcc @no
    bne @yes
    iny
    cpy #6
    bne @c
@no:
    rts
@yes:
    ldy #5
@cp:
    lda score,y
    sta (ptr0),y
    dey
    bpl @cp
    jmp save_write
