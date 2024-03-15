lorom

; Hook "load state header" to modify palette address
org $82DF1D
  JSL GetPalettePointer
  BRA +
  NOP : NOP : NOP
  NOP : NOP : NOP
+
  ;LDA $0007,X
  ;STA $07C7
  ;LDA $0006,X
  ;STA $07C6

org $89ABFB
  JSR GetPaletteBlendIndex_Trampoline
  ;AND #$00FF
org $89AC01 : LDA.l $8A0000,X
org $89AC09 : LDA.l $8A0002,X
org $89AC11 : LDA.l $8A0004,X

org $89AA02
GetPaletteBlendIndex_Trampoline:
  JSL GetPaletteBlendIndex
  RTS

org $A6A4D6
  CMP #$000F
  BMI +
  SEC
  RTS
+
  JSL RidleyLightsOn
  CLC
  RTS
warnpc $A6A6AF

org $A7DC71
  JSL LoadPhantoonTargetColor
  ;LDA $CA61,X
  ;TAY

org $ADF24B
  CMP #$0008
  BNE +
  SEC
  RTL
+
  JSL MBLightsOn
  CLC
  RTL
warnpc $ADF40B

org $8AC000
EnablePalettesFlag:
  ; Two bytes go here
  ; DW $F0F0 ; vanilla = $1478

org $8AC002
GetArea:
  ; Enable area palettes is either the flag is set in ROM or one of the debug events is set
  LDA.l EnablePalettesFlag
  CMP #$F0F0
  BEQ UseMapArea
  LDA $7ED824 ; event bits $20-27
  AND #$00FF
  BNE UseMapArea

;UseTilesetArea:
  LDX $07BB ; tileset index
  LDA $8F0003,X
  AND #$00FF
  TAX
  LDA.l StandardArea,X
  AND #$00FF
  RTS
UseMapArea:
  LDA $1F5B  ; map area
  ASL
  CLC
  ADC $1F5B
  AND #$00FF
  RTS

GetPalettePointer:
  JSR GetArea
  TAX
  LDA.l AreaPalettes+1,X
  STA $07C7 ; palette bank
  LDA.l AreaPalettes+0,X
  STA $12 ; palette base offset

  LDA $08 ; tileset index
  STA $14
  ASL $14
  ASL $14 ; $14 = tileset index * 4
  XBA
  CLC
  ADC $14 ; tileset index * $104
  ADC $12 ; can't overflow the bank because we don't allow the area palettes to cross banks
  STA $07C6

  RTL

AreaPalettes:
  DL AreaPalettes_0, AreaPalettes_1, AreaPalettes_2, AreaPalettes_3, AreaPalettes_4, AreaPalettes_5, AreaPalettes_6, AreaPalettes_7

StandardArea:
  DB $00*3, $00*3 ;Crateria Surface
  DB $00*3, $00*3 ;Inner Crateria
  DB $03*3, $03*3 ;Wrecked Ship
  DB $01*3, $01*3 ;Brinstar
  DB $01*3 ;Tourian Statues Access/Blue brinstar
  DB $02*3, $02*3 ;Norfair
  DB $04*3, $04*3 ;Maridia
  DB $05*3, $05*3 ;Tourian
  DB $06*3, $06*3, $06*3, $06*3, $06*3, $06*3 ;Ceres
  DB $00*3, $00*3, $00*3, $00*3, $00*3 ;Utility Rooms
  ;Bosses
  DB $01*3 ;Kraid
  DB $04*3 ;Draygon
  DB $04*3 ;Draygon
  DB $01*3 ;SpoSpo
  DB $03*3 ;Phantoon

; Calculate the [A]th transitional color from start color in [X] to target color in [Y]
; Copy of $82DAA6 but the current denominator is stored at $00
ComputeTransitionalColor:
  PHA
  PHA
  PHX
  PHY
  LDA $01,S
  AND #$001F
  TAY
  LDA $03,S
  AND #$001F
  TAX
  LDA $05,S
  JSR ComputeTransitionalComponent
  STA $07,S
  LDA $01,S
  ASL
  ASL
  ASL
  XBA
  AND #$001F
  TAY
  LDA $03,S
  ASL
  ASL
  ASL
  XBA
  AND #$001F
  TAX
  LDA $05,S
  JSR ComputeTransitionalComponent
  ASL
  ASL
  ASL
  ASL
  ASL
  ORA $07,S
  STA $07,S
  LDA $01,S
  LSR
  LSR
  XBA
  AND #$001F
  TAY
  LDA $03,S
  LSR
  LSR
  XBA
  AND #$001F
  TAX
  LDA $05,S
  JSR ComputeTransitionalComponent
  ASL
  ASL
  XBA
  ORA $07,S
  STA $07,S
  PLY
  PLX
  PLA
  PLA
  RTS
ComputeTransitionalComponent:
  CMP #$0000
  BNE +
  TXA
  RTS
+
  DEC
  CMP $00
  BNE +
  TYA
  RTS
+
  PHX
  INC
  STA $14
  TYA
  SEC
  SBC $01,S
  STA $12
  BPL +
  EOR #$FFFF
  INC
+
  SEP #$21
  STZ $4204
  STA $4205
  LDA $00
  SBC $14
  INC
  STA $4206
  REP #$20
  NOP
  NOP
  NOP
  NOP
  NOP
  LDA $4214
  BIT $12
  BPL +
  EOR #$FFFF
  INC
+
  STA $12
  PLA
  XBA
  CLC
  ADC $12
  XBA
  AND #$00FF
  RTS

LoadPhantoonTargetColor:
  TXY
  JSR GetArea
  TAX
  LDA.l AreaPalettes+1,X
  STA $13 ; palette bank
  LDA.l AreaPalettes+0,X
  CLC
  ADC #$0412 ; WS awake is palette $04 + skip header
  STA $12
  LDA [$12],Y
  TYX
  TAY
  RTL

MBLightsOn:
  INC
  STA $16 ; transition index
  LDA #$0007
  STA $00

  LDA $07C7
  STA $03
  LDA $07C6
  INC
  INC
  STA $02

  LDA #$0062
  STA $06
-
  LDY $06
  LDA [$02],Y
  TAY ; target color
  LDX #$0000 ; source color
  LDA $16
  JSR ComputeTransitionalColor
  LDX $06
  STA $7EC000,X
  INX
  INX
  STX $06
  CPX #$0080
  BMI -

  LDA #$00A2
  STA $06
-
  LDY $06
  LDA [$02],Y
  TAY
  LDX #$0000
  LDA $16
  JSR ComputeTransitionalColor
  LDX $06
  STA $7EC000,X
  INX
  INX
  STX $06
  CPX #$00C0
  BMI -
  RTL

RidleyLightsOn:
  PHY
  STA $16 ; transition index
  LDA #$000F
  STA $00

  LDA $07C7
  STA $03
  LDA $07C6
  INC
  INC
  STA $02

  LDA #$00E2
  STA $06
-
  LDY $06
  LDA [$02],Y
  TAY ; target color
  LDX #$0000 ; source color
  LDA $16
  JSR ComputeTransitionalColor
  LDX $06
  STA $7EC000,X
  INX
  INX
  STX $06
  CPX #$0100
  BMI -

  PLY
  RTL

GetPaletteBlendIndex:
  AND #$00FF
  BNE +
  RTL
+
  STA $00
  JSR GetArea
  TAX
  LDA.l BlendTable,X
  CLC
  ADC $00
  RTL

!unused_blend_ent = $6318,$6318,$0000

BlendTable:
  DL Blends_0, Blends_1, Blends_2, Blends_3, Blends_4, Blends_5, Blends_6, Blends_7
Blends_0:
  DW $0000, $0E3F,$0D7F,$0000, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $314A,$20C6,$0820, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $0400,$1C63,$0000, $28E3,$1C60,$0000, $2485,$3D88,$0000, $0880,$0420,$0000, !unused_blend_ent
  DW $3800, $20A5,$1C84,$1024, $1087,$14A8,$0844, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $0400,$18A2,$0000, $0020,$0C62,$0000, $0400,$1C45,$0000, !unused_blend_ent, !unused_blend_ent
Blends_1:
  DW $0000, $0E3F,$0D7F,$0000, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $314A,$20C6,$0820, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $0400,$1C63,$0000, $28E3,$1C60,$0000, $2485,$3D88,$0000, $0880,$0420,$0000, !unused_blend_ent
  DW $3800, $20A4,$1C83,$1061, $1087,$14A8,$0844, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $0400,$18A2,$0000, $0020,$0C62,$0000, $0401,$1467,$0000, !unused_blend_ent, !unused_blend_ent
Blends_2:
  DW $0000, $0E3F,$0D7F,$0000, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $294C,$18C8,$0022, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $0400,$1C63,$0000, $28E3,$1C60,$0000, $2485,$3D88,$0000, $0880,$0420,$0000, !unused_blend_ent
  DW $3800, $14A8,$1087,$0C23, $1087,$14A8,$0844, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $0400,$18A2,$0000, $0020,$0C62,$0000, $0002,$0066,$0000, !unused_blend_ent, !unused_blend_ent
Blends_3:
  DW $0000, $0E3F,$0D7F,$0000, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $298A,$1906,$0040, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $0400,$1C63,$0000, $28E3,$1C60,$0000, $2485,$3D88,$0000, $0880,$0420,$0000, !unused_blend_ent
  DW $3800, $14E7,$10C6,$0442, $1087,$14A8,$0844, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $0400,$18A2,$0000, $0020,$0C62,$0000, $0021,$0082,$0000, !unused_blend_ent, !unused_blend_ent
Blends_4:
  DW $0000, $0E3F,$0D7F,$0000, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $314A,$20C6,$0820, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $0400,$1C63,$0000, $28E3,$1C60,$0000, $2485,$3D88,$0000, $0880,$0420,$0000, !unused_blend_ent
  DW $3800, $14E5,$10C4,$0461, $1087,$14A8,$0844, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $0400,$18A2,$0000, $0020,$0C62,$0000, $0400,$1C45,$0000, !unused_blend_ent, !unused_blend_ent
Blends_5:
  DW $0000, $0E3F,$0D7F,$0000, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $2D6B,$1CE7,$0421, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $0400,$1C63,$0000, $28E3,$1C60,$0000, $2485,$3D88,$0000, $0880,$0420,$0000, !unused_blend_ent
  DW $3800, $1CC6,$18A5,$0C63, $1087,$14A8,$0844, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $0400,$18A2,$0000, $0020,$0C62,$0000, $0421,$0C63,$0000, !unused_blend_ent, !unused_blend_ent
Blends_6:
  DW $0000, $0E3F,$0D7F,$0000, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $314A,$20C6,$0820, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $0400,$1C63,$0000, $28E3,$1C60,$0000, $2485,$3D88,$0000, $0880,$0420,$0000, !unused_blend_ent
  DW $3800, $20A5,$1C84,$1024, $1087,$14A8,$0844, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $0400,$18A2,$0000, $0020,$0C62,$0000, $0400,$1C45,$0000, !unused_blend_ent, !unused_blend_ent
Blends_7:
  DW $0000, $0E3F,$0D7F,$0000, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $314A,$20C6,$0820, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $0400,$1C63,$0000, $28E3,$1C60,$0000, $2485,$3D88,$0000, $0880,$0420,$0000, !unused_blend_ent
  DW $3800, $20A5,$1C84,$1024, $1087,$14A8,$0844, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $0400,$18A2,$0000, $0020,$0C62,$0000, $0400,$1C45,$0000, !unused_blend_ent, !unused_blend_ent


; Use "InputFile" working directory mode in SMART if you want this to assemble in xkas
; Each uncompressed palette is 256 bytes. Compressing these palettes doesn't always make them smaller anyway

macro PaletteFile(t, n, area)
AreaPalettes_<n>_<t>:
  DB $E0, $FF ; header for the decompressor (copy $100 literal bytes)
incbin ..\..\<area>\Export\Tileset\SCE\<t>\palette.snes ; not actually compressed
  DB $FF ; footer for the decompressor
  DB $FF ; 1 byte padding
endmacro

macro PaletteSet(n, area)

print "Area Palettes <n>:"
print pc
AreaPalettes_<n>:
%PaletteFile(00, <n>, <area>)
%PaletteFile(01, <n>, <area>)
%PaletteFile(02, <n>, <area>)
%PaletteFile(03, <n>, <area>)
%PaletteFile(04, <n>, <area>)
%PaletteFile(05, <n>, <area>)
%PaletteFile(06, <n>, <area>)
%PaletteFile(07, <n>, <area>)
%PaletteFile(08, <n>, <area>)
%PaletteFile(09, <n>, <area>)
%PaletteFile(0A, <n>, <area>)
%PaletteFile(0B, <n>, <area>)
%PaletteFile(0C, <n>, <area>)
%PaletteFile(0D, <n>, <area>)
%PaletteFile(0E, <n>, <area>)
%PaletteFile(0F, <n>, <area>)
%PaletteFile(10, <n>, <area>)
%PaletteFile(11, <n>, <area>)
%PaletteFile(12, <n>, <area>)
%PaletteFile(13, <n>, <area>)
%PaletteFile(14, <n>, <area>)
%PaletteFile(15, <n>, <area>)
%PaletteFile(16, <n>, <area>)
%PaletteFile(17, <n>, <area>)
%PaletteFile(18, <n>, <area>)
%PaletteFile(19, <n>, <area>)
%PaletteFile(1A, <n>, <area>)
%PaletteFile(1B, <n>, <area>)
%PaletteFile(1C, <n>, <area>)
%PaletteFile(1D, <n>, <area>)
%PaletteFile(1E, <n>, <area>)
endmacro

org $C08000
%PaletteSet(0, CrateriaPalette)
%PaletteSet(1, BrinstarPalette)
%PaletteSet(2, NorfairPalette)
%PaletteSet(3, WreckedShipPalette)
warnpc $C0FFFF
org $C18000
%PaletteSet(4, MaridiaPalette)
%PaletteSet(5, TourianPalette)
%PaletteSet(6, CrateriaPalette)
%PaletteSet(7, CrateriaPalette)
warnpc $C1FFFF
