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

org $89AB5B ; Skip loading the palette blend for MB. It's always the same as what was already laoded.
  ;BEQ $1B
  PLB
  PLP
  RTL

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

org $A4986D
  JSL LoadCrocSpikePalette
  JMP $9BB3

org $A5E87C
  JSL SetupSpoSpoTransitionColors
  NOP : NOP
  ;LDA #$0080
  ;STA $0F7A

org $A5E8E5
  LDY $12
  LDA $0000,y
  TAY
  LDA $7E7880
  BEQ SpoSpoDecay_Vanilla
  TYA
  JSL SpoSpoDecay
  BRA SpoSpoDecay_Exit
SpoSpoDecay_Vanilla:
  LDX #$0000
-
  LDA $E4F9,y
  STA $7EC080,x
  LDA $E5D9,y
  STA $7EC0E0,x
  INY
  INY
  INX
  INX
  CPX #$0020
  BNE -
SpoSpoDecay_Exit:
  PLX
  PLY
  INY
  INY
  RTL
warnpc $A5E91C

org $A5E91C
  PHY
  PHX
  LDX #$001E
-
  LDA $E4B9,x
  STA $7EC320,x
  DEX
  DEX
  BPL -

  JSL SetupSpoSpoTransitionColors
  LDA $7E7880
  BEQ SpoSpoAlreadyDead_Vanilla
  LDX #$001E
-
  LDA $7E7840,x
  STA $7EC280,x
  LDA $7E7860,x
  STA $7EC2E0,x
  DEX
  DEX
  BPL -
  BRA SpoSpoDecay_Exit
SpoSpoAlreadyDead_Vanilla:
  LDX #$001E
-
  LDA $E5B9,x
  STA $7EC280,x
  LDA $E699,x
  STA $7EC2E0,x
  DEX
  DEX
  BPL -
  BRA SpoSpoDecay_Exit
warnpc $A5E96E

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
  LDX $07BB
  LDA $8F0003,X
  AND #$00FF
  CMP #$0020
  BPL UseTilesetArea
  ; Enable area palettes is either the flag is set in ROM or one of the debug events is set
  LDA.l EnablePalettesFlag
  CMP #$F0F0
  BEQ UseMapArea
  LDA $7ED824 ; event bits $20-27
  AND #$00FF
  BNE UseMapArea

UseTilesetArea:
  LDA #$0008*3
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
  STA $13
  ;STA $07C7 ; palette bank
  LDA.l AreaPalettes+0,X
  STA $12
  LDA $08 ; tileset index
  ASL
  CLC
  ADC $08
  CLC
  ADC $12
  STA $12
  LDA [$12]
  STA $07C6
  INC $12
  LDA [$12]
  STA $07C7

  RTL

AreaPalettes:
  DL AreaPalettes_0, AreaPalettes_1, AreaPalettes_2, AreaPalettes_3, AreaPalettes_4, AreaPalettes_5, AreaPalettes_6, AreaPalettes_7, AreaPalettes_X

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
  STA $16 ; palette bank
  LDA.l AreaPalettes+0,X
  STA $15
  LDA [$15]
  STA $12
  INC $15
  LDA [$15]
  STA $13

  LDA $12
  CLC
  ADC #$0004*3 ; phantoon's tileset 4
  STA $12
  LDA [$12]
  INC
  INC
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

VanillaCrocPalette:
  DL AreaPalettes_2_1B
LoadCrocSpikePalette:
  PHY
  LDA $07C7
  STA $03
  LDA $07C6
  INC
  INC
  STA $02

  LDY #$0002
  LDX #$0162
-
  LDA [$02],Y
  STA $7EC000,X
  INX
  INX
  INY
  INY
  CPY #$0020
  BMI -

  LDA.l VanillaCrocPalette
  CMP $07C6
  BNE LoadCrocSpikePalette_NonVanilla
  LDA.l VanillaCrocPalette+1
  CMP $07C7
  BNE LoadCrocSpikePalette_NonVanilla
  PLY
  RTL
LoadCrocSpikePalette_NonVanilla:
  LDA #$0004
  STA $00

  LDY #$00CE
  LDA [$02],Y
  STA $7EC14E

  LDY #$00CA
  LDA [$02],Y
  STA $7EC152
  INY
  INY
  LDA [$02],Y
  STA $7EC154

  LDY #$00C4
  LDA [$02],Y
  STA $7EC158
  INY
  INY
  LDA [$02],Y
  STA $7EC15A
  INY
  INY
  LDA [$02],Y
  STA $7EC15C

  LDY #$00DE
  LDA [$02],Y
  STA $7EC15E

  PLY
  RTL

ComputeSepiaTone:
; extract color channels in 8.8 fixed point
  CLC
  STA $08
  AND #$001F
  XBA
  STA $0A
  LDA $08
  AND #$03E0
  ASL
  ASL
  ASL
  STA $0C
  LDA $08
  AND #$7C00
  LSR
  LSR
  STA $0E

; R = R*$00.64 + G*$00.C5 + B*$00.30
; G = R*$00.59 + G*$00.B0 + B*$00.2B
; B = R*$00.46 + G*$00.89 + B*$00.21

  LDA $0A
  LDY #$0064
  JSR FixedPointMultiply
  STA $10
  LDA $0C
  LDY #$00C5
  JSR FixedPointMultiply
  CLC
  ADC $10
  STA $10
  LDA $0E
  LDY #$0030
  JSR FixedPointMultiply
  CLC
  ADC $10
  AND #$1F00 ; truncate and store as R
  XBA
  STA $08

  LDA $0A
  LDY #$0059
  JSR FixedPointMultiply
  STA $10
  LDA $0C
  LDY #$00B0
  JSR FixedPointMultiply
  CLC
  ADC $10
  STA $10
  LDA $0E
  LDY #$002B
  JSR FixedPointMultiply
  CLC
  ADC $10
  AND #$1F00
  LSR
  LSR
  LSR
  ORA $08
  STA $08 ; truncate and store as G

  LDA $0A
  LDY #$0046
  JSR FixedPointMultiply
  STA $10
  LDA $0C
  LDY #$0089
  JSR FixedPointMultiply
  CLC
  ADC $10
  STA $10
  LDA $0E
  LDY #$0021
  JSR FixedPointMultiply
  CLC
  ADC $10
  AND #$1F00
  ASL
  ASL
  ORA $08
  STA $08 ; truncate and store as B

  RTS

; unsigned multiply A * Y, where A is 000aaaaa.00000000 and Y is 00000000.hyyyyyyy
FixedPointMultiply:
  BEQ ++
  STA $05F1
  STZ $05F3

  ; result = (A*h)/2 + (A*y)/$100
  ; the fast multiplier is 16x8 signed multiplication
  SEP #$30
  STA $211B
  XBA
  STA $211B
  TYA
  AND #$7F
  STA $211C

  TYA
  BPL +
  REP #$30
  LDA $05F1
  LSR ;(A*1)/2
  CLC
  ADC $2135 ; + (A*y)/$100
  RTS
+
  REP #$30
  LDA $2135 ;(A*0)/2 + (A*y)/$100
++
  RTS

SetupSpoSpoTransitionColors:
  PHX
  PHY
  LDA #$0080
  STA $0F7A

; test for vanilla colors
  LDA $07C7
  STA $03
  LDA $07C6
  INC
  INC
  STA $02

  LDY #$0080
  LDX #$0000
-
  LDA [$02],Y
  STA $7E7800,X
  INY
  INY
  INX
  INX
  CPX #$0020
  BMI -

  LDY #$00E0
  LDX #$0000
-
  LDA [$02],Y
  STA $7E7820,X
  INY
  INY
  INX
  INX
  CPX #$0020
  BMI -

  LDA.l VanillaSpoSpoPalette
  CMP $07C6
  BNE SetupSpoSpoTransitionColors_NonVanilla
  LDA.l VanillaSpoSpoPalette+1
  CMP $07C7
  BNE SetupSpoSpoTransitionColors_NonVanilla
  LDA #$0000
  STA $7E7880
  PLY
  PLX
  RTL

VanillaSpoSpoPalette:
  DL AreaPalettes_1_1D

SetupSpoSpoTransitionColors_NonVanilla:
  LDX #$0000
-
  LDA $7E7800,X
  PHX
  JSR ComputeSepiaTone
  PLX
  STA $7E7840,X

  LDA $7E7820,X
  PHX
  JSR ComputeSepiaTone
  PLX
  STA $7E7860,X

  INX
  INX
  CPX #$0020
  BMI -

  LDA #$0001
  STA $7E7880
  PLY
  PLX
  RTL

SpoSpoDecay:
  LSR
  LSR
  LSR
  LSR
  LSR
  INC
  STA $16 ; transition index
  LDA #$0007
  STA $00

  LDA #$0000
  STA $06
  TAX
-
  LDA $7E7840,X
  TAY ; target color
  LDA $7E7800,X
  TAX ; source color
  LDA $16
  JSR ComputeTransitionalColor
  LDX $06
  STA $7EC080,X
  INX
  INX
  STX $06
  CPX #$0020
  BMI -

  LDA #$0000
  STA $06
  TAX
-
  LDA $7E7860,X
  TAY ; target color
  LDA $7E7820,X
  TAX ; source color
  LDA $16
  JSR ComputeTransitionalColor
  LDX $06
  STA $7EC0E0,X
  INX
  INX
  STX $06
  CPX #$0020
  BMI -

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
  DL Blends_0, Blends_1, Blends_2, Blends_3, Blends_4, Blends_5, Blends_6, Blends_7, Blends_X
Blends_0:
  DW $0000, $0E3F,$0D7F,$0000, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $314A,$20C6,$0820, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $0020,$1064,$0000, $28E3,$1C60,$0000, $2485,$3D88,$0000, $20A1,$1840,$0000, !unused_blend_ent
  DW $3800, $20A5,$1C84,$1024, $1087,$14A8,$0844, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $0401,$1844,$0000, $0000,$0862,$0000, $0400,$1C45,$0000, !unused_blend_ent, !unused_blend_ent
Blends_1:
  DW $0000, $0E3F,$0D7F,$0000, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $314A,$20C6,$0820, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $0800,$14A5,$0000, $28E3,$1C60,$0000, $2485,$3D88,$0000, $20A1,$1840,$0000, !unused_blend_ent
  DW $3800, $20A4,$1C83,$1061, $1087,$14A8,$0844, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $0400,$1464,$0000, $0020,$0C62,$0000, $0401,$1467,$0000, !unused_blend_ent, !unused_blend_ent
Blends_2:
  DW $0000, $0E3F,$0D7F,$0000, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $294C,$18C8,$0022, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $0400,$1484,$0000, $28E3,$1C60,$0000, $2485,$3D88,$0000, $20A1,$1840,$0000, !unused_blend_ent
  DW $3800, $14A8,$1087,$0C23, $1087,$14A8,$0844, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $0001,$0C66,$0000, $0420,$0843,$0000, $0002,$0066,$0000, !unused_blend_ent, !unused_blend_ent
Blends_3:
  DW $0000, $0E3F,$0D7F,$0000, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $298A,$1906,$0040, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $0401,$1485,$0000, $28E3,$1C60,$0000, $2485,$3D88,$0000, $20A1,$1840,$0000, !unused_blend_ent
  DW $3800, $14E7,$10C6,$0442, $1087,$14A8,$0844, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $0020,$0C84,$0000, $0020,$0863,$0000, $0021,$0082,$0000, !unused_blend_ent, !unused_blend_ent
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
  DW $3800, $0421,$14A5,$0000, $28E3,$1C60,$0000, $2485,$3D88,$0000, $20A1,$1840,$0000, !unused_blend_ent
  DW $3800, $1CC6,$18A5,$0C63, $1087,$14A8,$0844, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $0421,$1084,$0000, $0400,$0C63,$0000, $0421,$0C63,$0000, !unused_blend_ent, !unused_blend_ent
Blends_6:
  DW $0000, $0E3F,$0D7F,$0000, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $314A,$20C6,$0820, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $0400,$1C63,$0000, $28E3,$1C60,$0000, $2485,$3D88,$0000, $20A1,$1840,$0000, !unused_blend_ent
  DW $3800, $20A5,$1C84,$1024, $1087,$14A8,$0844, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $0400,$18A2,$0000, $0020,$0C62,$0000, $0400,$1C45,$0000, !unused_blend_ent, !unused_blend_ent
Blends_7:
  DW $0000, $0E3F,$0D7F,$0000, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $314A,$20C6,$0820, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $0400,$1C63,$0000, $28E3,$1C60,$0000, $2485,$3D88,$0000, $20A1,$1840,$0000, !unused_blend_ent
  DW $3800, $20A5,$1C84,$1024, $1087,$14A8,$0844, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $0400,$18A2,$0000, $0020,$0C62,$0000, $0400,$1C45,$0000, !unused_blend_ent, !unused_blend_ent
Blends_X:
  DW $0000, $0E3F,$0D7F,$0000, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $314A,$20C6,$0820, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent, !unused_blend_ent
  DW $3800, $0400,$1C63,$0000, $28E3,$1C60,$0000, $2485,$3D88,$0000, $20A1,$1840,$0000, !unused_blend_ent
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
  DL AreaPalettes_<n>_00, AreaPalettes_<n>_01, AreaPalettes_<n>_02, AreaPalettes_<n>_03
  DL AreaPalettes_<n>_04, AreaPalettes_<n>_05, AreaPalettes_<n>_06, AreaPalettes_<n>_07
  DL AreaPalettes_<n>_08, AreaPalettes_<n>_09, AreaPalettes_<n>_0A, AreaPalettes_<n>_0B
  DL AreaPalettes_<n>_0C, AreaPalettes_<n>_0D, AreaPalettes_<n>_0E, AreaPalettes_SHR_0F
  DL AreaPalettes_SHR_10, AreaPalettes_SHR_11, AreaPalettes_SHR_12, AreaPalettes_SHR_13
  DL AreaPalettes_SHR_14, AreaPalettes_SHR_15, AreaPalettes_SHR_16, AreaPalettes_SHR_17
  DL AreaPalettes_SHR_18, AreaPalettes_SHR_19, AreaPalettes_<n>_1A, AreaPalettes_<n>_1B
  DL AreaPalettes_<n>_1C, AreaPalettes_<n>_1D, AreaPalettes_<n>_1E, AreaPalettes_<n>_1F

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

%PaletteFile(1A, <n>, <area>)
%PaletteFile(1B, <n>, <area>)
%PaletteFile(1C, <n>, <area>)
%PaletteFile(1D, <n>, <area>)
%PaletteFile(1E, <n>, <area>)
%PaletteFile(1F, <n>, <area>)
endmacro

org $C08000
print "Shared Palettes:"
print pc
%PaletteSet(0, CrateriaPalette)
%PaletteSet(1, BrinstarPalette)
%PaletteSet(2, NorfairPalette)
%PaletteSet(3, WreckedShipPalette)
%PaletteSet(4, MaridiaPalette)
warnpc $C0FFFF
org $C18000
%PaletteSet(5, TourianPalette)
%PaletteSet(6, CrateriaPalette)
%PaletteSet(7, CrateriaPalette)

print "Non-themed Palettes:"
print pc
AreaPalettes_X:
  ; Vanilla
  DL AreaPalettes_0_00, AreaPalettes_0_01, AreaPalettes_0_02, AreaPalettes_0_03
  DL AreaPalettes_3_04, AreaPalettes_3_05
  DL AreaPalettes_1_06, AreaPalettes_1_07, AreaPalettes_1_08
  DL AreaPalettes_2_09, AreaPalettes_2_0A
  DL AreaPalettes_4_0B, AreaPalettes_4_0C
  DL AreaPalettes_5_0D, AreaPalettes_5_0E
  DL AreaPalettes_SHR_0F, AreaPalettes_SHR_10, AreaPalettes_SHR_11, AreaPalettes_SHR_12, AreaPalettes_SHR_13, AreaPalettes_SHR_14
  DL AreaPalettes_SHR_15, AreaPalettes_SHR_16, AreaPalettes_SHR_17, AreaPalettes_SHR_18, AreaPalettes_SHR_19
  DL AreaPalettes_1_1A
  DL AreaPalettes_2_1B
  DL AreaPalettes_4_1C
  DL AreaPalettes_1_1D
  DL AreaPalettes_3_1E
  DL AreaPalettes_1_1F
  ; Exotic
  DL AreaPalettes_X_20

; Ceres
%PaletteFile(0F, SHR, Base)
%PaletteFile(10, SHR, Base)
%PaletteFile(11, SHR, Base)
%PaletteFile(12, SHR, Base)
%PaletteFile(13, SHR, Base)
%PaletteFile(14, SHR, Base)
; Utility rooms
%PaletteFile(15, SHR, Base)
%PaletteFile(16, SHR, Base)
%PaletteFile(17, SHR, Base)
%PaletteFile(18, SHR, Base)
%PaletteFile(19, SHR, Base)
; Exotic
%PaletteFile(20, X, Matrix)
warnpc $C1FFFF
