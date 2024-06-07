lorom

incsrc GlowData.def

; Support for custom area palette glows
; Handles tileset glows that would be misplaced when the tileset's area and the map's area don't match
; Extends the glow header format to be polumorphic. The vanilla header type is V1, and the new one is V2.
; V1 headers look like this:
; org $8DXXXX
;   DW GlowInitCode, GlowInstructionList
; org $8DYYYY
; GlowInitCode:
; org $8DZZZZ
; GlowInstructionList:
;
; V2 headers lok like this:
; org 8DXXXX
;   DW $00BB, $TTTT
; org $BBTTTT
;   DW GlowInitCode_0, GlowInstructionList_0
; ...
;   DW GlowInitCode_7, GlowInstructionList_7
; org $BBYYY0
; GlowInitCode_0:
; org $BBZZZ0
; GlowInstructionList_0:
; ...
; org $BBYYY7
; GlowInitCode_7:
; org $BBZZZ7
; GlowInstructionList_7:
;
; During each frame, the correct main handler is called for each glow for V1 or V2.
; All code for instructions for V2 glows is run in bank BB, so any instructions used need to be copied there.
; It's not possible to mix banks for a single glow. If a glow is converted to V2, it must be entirely moved.

org $8AC000
EnablePalettesFlag:
  ; Two bytes go here
  ; DW $F0F0 ; vanilla = $1478

org $8DC4FF ; Patch main glow object constructor to support polymorphic glow headers
  TYA
  STA $1E7D,X
  STZ $1E8D,X
  LDA #$0001
  STA $1ECD,X
  STZ $1EDD,X

  LDA $0000,Y
  BMI +
  JML SpawnGlow_V2
+
  JMP.w SpawnGlow_V1
MainGlowHandler_ToV2:
  JSL MainGlowHandler_V2
  BRA MainGlowHandler_Continue
warnpc $8DC528

org $8DC527
MainGlowHandler:
  PHP
  PHB
  PHK
  PLB
  REP #$30
  BIT $1E79
  BPL MainGlowHandler_Exit
  LDX #$000E
MainGlowHandler_Loop:
  STX $1E7B
  LDA $1E7D,X
  BEQ MainGlowHandler_Continue
  BMI +
  BRA MainGlowHandler_ToV2
+
  JSR MainGlowHandler_V1
MainGlowHandler_Continue:
  DEX
  DEX
  BPL MainGlowHandler_Loop
MainGlowHandler_Exit:
  PLB
  PLP
  RTL

org $8DC54C
MainGlowHandler_V1:

org $8DE45A
  JMP HeatGlowAdditionalInit ;STA $1EBD,y

org $8DF891 ; overwrite moved glow
SpawnGlow_V1:
  LDA #$C594  ; points to an RTS
  STA $1EAD,X ; pre-instruction
  LDA $0002,Y
  STA $1EBD,X
  TXA
  TYX
  TAY
  JSR ($0000,X)
  PLX
  PLB
  PLP
  CLC
  RTL

HeatGlowAdditionalInit:
  STA $1EBD,Y
  PHY
  PHX
  LDX $07BB ; tileset index
  LDA $8F0003,X
  AND #$00FF
  CMP #$0002 ; assume Norfair tilesets already handle this with glow config
  BEQ HeatGlowAdditionalInit_Exit
  LDY #FakeHeatGlowSync
  JSL $8DC4E9
HeatGlowAdditionalInit_Exit:
  PLX
  PLY
FakeHeatGlowSyncInit:
  RTS

FakeHeatGlowSync:
  DW FakeHeatGlowSyncInit, FakeHeatGlowSyncInstructionList

FakeHeatGlowSyncInstructionList:
  DW $F1C6 : DB $00
  DW $0010, $C595
  DW $F1C6 : DB $01
  DW $0004, $C595
  DW $F1C6 : DB $02
  DW $0004, $C595
  DW $F1C6 : DB $03
  DW $0005, $C595
  DW $F1C6 : DB $04
  DW $0006, $C595
  DW $F1C6 : DB $05
  DW $0007, $C595
  DW $F1C6 : DB $06
  DW $0008, $C595
  DW $F1C6 : DB $07
  DW $0008, $C595
  DW $F1C6 : DB $08
  DW $0008, $C595
  DW $F1C6 : DB $09
  DW $0008, $C595
  DW $F1C6 : DB $0A
  DW $0007, $C595
  DW $F1C6 : DB $0B
  DW $0006, $C595
  DW $F1C6 : DB $0C
  DW $0005, $C595
  DW $F1C6 : DB $0D
  DW $0004, $C595
  DW $F1C6 : DB $0E
  DW $0004, $C595
  DW $F1C6 : DB $0F
  DW $0010, $C595
  DW $C61E, FakeHeatGlowSyncInstructionList

org $BB8000
SpawnGlow_V2:
  CMP #$00BB ; assert tag
  BEQ +
  JSL $808573 ; crash
+
  STA $1E7D,X

  LDA.w #EmptyPre
  STA $1EAD,X ; pre-instruction

  PHX
  LDX $07BB ; tileset index
  LDA $8F0003,X
  PLX
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
  LDA #$0008
  BRA ReadHeader
UseMapArea:
  LDA $1F5B  ; map area

ReadHeader:
  AND #$00FF
  ASL
  ASL ; 4 byte entries
  CLC
  ADC $0002,Y ; add area table base address
  TAY ; points to the header for the glow for the area in bank BB
  PHK
  PLB

  LDA $0002,Y
  STA $1EBD,X
  TXA
  TYX
  TAY
  JSR ($0000,X)
  PLX
  PLB
  PLP
  CLC
  RTL

EmptyInit:
EmptyPre:
  RTS

MainGlowHandler_V2:
  PHB
  PHK
  PLB
  JSR ($1EAD,X)
  LDX $1E7B
  DEC $1ECD,X
  BNE MainGlowHandler_V2_Exit
  LDA $1EBD,X
  TAY
MainGlowHandler_V2_Loop1:
  LDA $0000,Y
  BPL MainGlowHandler_V2_Break1
  STA $12
  INY
  INY
  PEA.w MainGlowHandler_V2_Loop1-1
  JMP ($0012)
MainGlowHandler_V2_Break1:
  STA $1ECD,X
  LDA $1E8D,X
  TAX
MainGlowHandler_V2_Loop2:
  LDA $0002,Y
  BPL MainGlowHandler_V2_Color
  STA $12
  PEA.w MainGlowHandler_V2_Loop2-1
  JMP ($0012)
MainGlowHandler_V2_Color:
  STA $7EC000,X
  INX
  INX
  INY
  INY
  BRA MainGlowHandler_V2_Loop2

GlowYeild: ; C595
  PLA
  LDX $1E7B
  TYA
  CLC
  ADC #$0004
  STA $1EBD,X
MainGlowHandler_V2_Exit:
  PLB
  RTL

GlowJMP: ; C61E
  LDA $0000,Y
  TAY
  RTS

SetLoopCounter: ; C648
  SEP #$20
  LDA $0000,Y
  STA $1EDD,X
  REP #$20
  INY
  RTS

DecAndLoop: ; C639
  DEC $1EDD,X
  BNE GlowJMP
  INY
  INY
  RTS

GlowDelete: ; C5CF
  STZ $1E7D,X
  PLA
  RTS

SetLinkTarget:
  LDA $0000,Y
  STA $1E9D,X
  INY
  INY
  RTS

LinkJMP:
  LDA $1E9D,X
  TAY
  RTS

SetPreInstruction: ; C5D4
  LDA $0000,Y
  STA $1EAD,X
  INY
  INY
  RTS

SetColorIndex: ; C655
  LDA $0000,Y
  STA $1E8D,X
  INY
  INY
  RTS

SkipColors_2: ; C599
  TXA
  CLC
  ADC #$0004
  TAX
  INY
  INY
  RTS

SkipColors_3: ; C5A2
  TXA
  CLC
  ADC #$0006
  TAX
  INY
  INY
  RTS

SkipColors_4: ; C5AB
  TXA
  CLC
  ADC #$0008
  TAX
  INY
  INY
  RTS

SkipColors_8: ; C5B4
  TXA
  CLC
  ADC #$0010
  TAX
  INY
  INY
  RTS

SkipColors_9: ; C5BD
  TXA
  CLC
  ADC #$0012
  TAX
  INY
  INY
  RTS

PlaySFX: ; C673
  LDA $0000,Y
  JSL $8090CB
  INY
  RTS

; Crateria tileset glows

ResetLightning:
  LDA $0AFA
  CMP $197A
  BCS +
  LDA #$0001
  STA $1ECD,X
  LDA $1E9D,X
  STA $1EBD,X
+
  RTS

SkyFlashTable:
  DW EmptyInit,SkyFlash0_List, EmptyInit,SkyFlash1_List, EmptyInit,SkyFlash2_List, EmptyInit,SkyFlash3_List
  DW EmptyInit,SkyFlash4_List, EmptyInit,SkyFlash5_List, EmptyInit,SkyFlash6_List, EmptyInit,SkyFlash7_List
  DW EmptyInit,SkyFlash0_List

macro SkyFlash_List(n)
SkyFlash<n>_List:
  DW SetLinkTarget, SkyFlash<n>_List_Loop1
  DW SetPreInstruction, ResetLightning
  DW SetColorIndex, $00A8
SkyFlash<n>_List_Loop1:
  DW $00F0
    DW !SkyFlash<n>_Colors_0
    DW GlowYeild
  DW SetLoopCounter : DB $02
SkyFlash<n>_List_Loop2:
  DW $0002
    DW !SkyFlash<n>_Colors_1
    DW GlowYeild
  DW $0001
    DW !SkyFlash<n>_Colors_2
    DW GlowYeild
  DW $0001
    DW !SkyFlash<n>_Colors_3
    DW GlowYeild
  DW $0001
    DW !SkyFlash<n>_Colors_4
    DW GlowYeild
  DW $0001
    DW !SkyFlash<n>_Colors_3
    DW GlowYeild
  DW $0001
    DW !SkyFlash<n>_Colors_2
    DW GlowYeild
  DW $0002
    DW !SkyFlash<n>_Colors_1
    DW GlowYeild
  DW DecAndLoop, SkyFlash<n>_List_Loop2
  DW $00F0
    DW !SkyFlash<n>_Colors_0
    DW GlowYeild
  DW SetLoopCounter : DB $01
SkyFlash<n>_List_Loop3:
  DW $0001
    DW !SkyFlash<n>_Colors_4
    DW GlowYeild
  DW $0001
    DW !SkyFlash<n>_Colors_3
    DW GlowYeild
  DW $0001
    DW !SkyFlash<n>_Colors_2
    DW GlowYeild
  DW $0002
    DW !SkyFlash<n>_Colors_1
    DW GlowYeild
  DW DecAndLoop, SkyFlash<n>_List_Loop3
  DW GlowJMP, SkyFlash<n>_List_Loop1
endmacro

%SkyFlash_List(0)
%SkyFlash_List(1)
%SkyFlash_List(2)
%SkyFlash_List(3)
%SkyFlash_List(4)
%SkyFlash_List(5)
%SkyFlash_List(6)
%SkyFlash_List(7)

SurfcEscTable:
  DW EmptyInit,SurfcEsc0_List, EmptyInit,SurfcEsc1_List, EmptyInit,SurfcEsc2_List, EmptyInit,SurfcEsc3_List
  DW EmptyInit,SurfcEsc4_List, EmptyInit,SurfcEsc5_List, EmptyInit,SurfcEsc6_List, EmptyInit,SurfcEsc7_List
  DW EmptyInit,SurfcEsc0_List

macro SurfcEsc_List(n)
SurfcEsc<n>_List:
  DW SetColorIndex, $0082
SurfcEsc<n>_List_Loop:
  DW $0008
    DW !SurfcEsc<n>_Colors_0
    DW GlowYeild
  DW $0007
    DW !SurfcEsc<n>_Colors_1
    DW GlowYeild
  DW $0006
    DW !SurfcEsc<n>_Colors_2
    DW GlowYeild
  DW $0005
    DW !SurfcEsc<n>_Colors_3
    DW GlowYeild
  DW $0004
    DW !SurfcEsc<n>_Colors_4
    DW GlowYeild
  DW $0003
    DW !SurfcEsc<n>_Colors_5
    DW GlowYeild
  DW $0002
    DW !SurfcEsc<n>_Colors_6
    DW GlowYeild
  DW $0001
    DW !SurfcEsc<n>_Colors_7
    DW GlowYeild
  DW $0002
    DW !SurfcEsc<n>_Colors_6
    DW GlowYeild
  DW $0003
    DW !SurfcEsc<n>_Colors_5
    DW GlowYeild
  DW $0004
    DW !SurfcEsc<n>_Colors_4
    DW GlowYeild
  DW $0005
    DW !SurfcEsc<n>_Colors_3
    DW GlowYeild
  DW $0006
    DW !SurfcEsc<n>_Colors_2
    DW GlowYeild
  DW $0007
    DW !SurfcEsc<n>_Colors_1
    DW GlowYeild
  DW GlowJMP, SurfcEsc<n>_List_Loop
endmacro

%SurfcEsc_List(0)
%SurfcEsc_List(1)
%SurfcEsc_List(2)
%SurfcEsc_List(3)
%SurfcEsc_List(4)
%SurfcEsc_List(5)
%SurfcEsc_List(6)
%SurfcEsc_List(7)

Sky_Esc_Table:
  DW EmptyInit,Sky_Esc_0_List, EmptyInit,Sky_Esc_1_List, EmptyInit,Sky_Esc_2_List, EmptyInit,Sky_Esc_3_List
  DW EmptyInit,Sky_Esc_4_List, EmptyInit,Sky_Esc_5_List, EmptyInit,Sky_Esc_6_List, EmptyInit,Sky_Esc_7_List
  DW EmptyInit,Sky_Esc_0_List

macro Sky_Esc_List(n)
Sky_Esc_<n>_List:
  DW SetColorIndex, $00A2
Sky_Esc_<n>_List_Loop:
  DW $0031
    DW !Sky_Esc_<n>_Colors_0
    DW GlowYeild
  DW $0001
    DW !Sky_Esc_<n>_Colors_1
    DW GlowYeild
  DW $0001
    DW !Sky_Esc_<n>_Colors_2
    DW GlowYeild
  DW $0001
    DW !Sky_Esc_<n>_Colors_3
    DW GlowYeild
  DW $0001
    DW !Sky_Esc_<n>_Colors_2
    DW GlowYeild
  DW $0011
    DW !Sky_Esc_<n>_Colors_0
    DW GlowYeild
  DW $0001
    DW !Sky_Esc_<n>_Colors_3
    DW GlowYeild
  DW $0018
    DW !Sky_Esc_<n>_Colors_0
    DW GlowYeild
  DW $0001
    DW !Sky_Esc_<n>_Colors_2
    DW GlowYeild
  DW $0001
    DW !Sky_Esc_<n>_Colors_3
    DW GlowYeild
  DW $0001
    DW !Sky_Esc_<n>_Colors_2
    DW GlowYeild
  DW GlowJMP, Sky_Esc_<n>_List_Loop
endmacro

%Sky_Esc_List(0)
%Sky_Esc_List(1)
%Sky_Esc_List(2)
%Sky_Esc_List(3)
%Sky_Esc_List(4)
%Sky_Esc_List(5)
%Sky_Esc_List(6)
%Sky_Esc_List(7)

OldT1EscTable:
  DW EmptyInit,OldT1Esc0_List, EmptyInit,OldT1Esc1_List, EmptyInit,OldT1Esc2_List, EmptyInit,OldT1Esc3_List
  DW EmptyInit,OldT1Esc4_List, EmptyInit,OldT1Esc5_List, EmptyInit,OldT1Esc6_List, EmptyInit,OldT1Esc7_List
  DW EmptyInit,OldT1Esc0_List

macro OldT1Esc_List(n)
OldT1Esc<n>_List:
  DW SetColorIndex, $00A2
OldT1Esc<n>_List_Loop:
  DW $0003
    DW !OldT1Esc<n>_Colors_0a
    DW SkipColors_4
    DW !OldT1Esc<n>_Colors_0b
    DW SkipColors_2
    DW !OldT1Esc<n>_Colors_0c
    DW GlowYeild
  DW $0003
    DW !OldT1Esc<n>_Colors_1a
    DW SkipColors_4
    DW !OldT1Esc<n>_Colors_1b
    DW SkipColors_2
    DW !OldT1Esc<n>_Colors_1c
    DW GlowYeild
  DW $0003
    DW !OldT1Esc<n>_Colors_2a
    DW SkipColors_4
    DW !OldT1Esc<n>_Colors_2b
    DW SkipColors_2
    DW !OldT1Esc<n>_Colors_2c
    DW GlowYeild
  DW $0003
    DW !OldT1Esc<n>_Colors_3a
    DW SkipColors_4
    DW !OldT1Esc<n>_Colors_3b
    DW SkipColors_2
    DW !OldT1Esc<n>_Colors_3c
    DW GlowYeild
  DW $0003
    DW !OldT1Esc<n>_Colors_4a
    DW SkipColors_4
    DW !OldT1Esc<n>_Colors_4b
    DW SkipColors_2
    DW !OldT1Esc<n>_Colors_4c
    DW GlowYeild
  DW $0003
    DW !OldT1Esc<n>_Colors_5a
    DW SkipColors_4
    DW !OldT1Esc<n>_Colors_3b
    DW SkipColors_2
    DW !OldT1Esc<n>_Colors_5c
    DW GlowYeild
  DW $0003
    DW !OldT1Esc<n>_Colors_6a
    DW SkipColors_4
    DW !OldT1Esc<n>_Colors_2b
    DW SkipColors_2
    DW !OldT1Esc<n>_Colors_6c
    DW GlowYeild
  DW $0003
    DW !OldT1Esc<n>_Colors_7a
    DW SkipColors_4
    DW !OldT1Esc<n>_Colors_1b
    DW SkipColors_2
    DW !OldT1Esc<n>_Colors_7c
    DW GlowYeild
  DW $0003
    DW !OldT1Esc<n>_Colors_6a
    DW SkipColors_4
    DW !OldT1Esc<n>_Colors_2b
    DW SkipColors_2
    DW !OldT1Esc<n>_Colors_6c
    DW GlowYeild
  DW $0003
    DW !OldT1Esc<n>_Colors_5a
    DW SkipColors_4
    DW !OldT1Esc<n>_Colors_3b
    DW SkipColors_2
    DW !OldT1Esc<n>_Colors_5c
    DW GlowYeild
  DW $0003
    DW !OldT1Esc<n>_Colors_4a
    DW SkipColors_4
    DW !OldT1Esc<n>_Colors_4b
    DW SkipColors_2
    DW !OldT1Esc<n>_Colors_4c
    DW GlowYeild
  DW $0003
    DW !OldT1Esc<n>_Colors_3a
    DW SkipColors_4
    DW !OldT1Esc<n>_Colors_3b
    DW SkipColors_2
    DW !OldT1Esc<n>_Colors_3c
    DW GlowYeild
  DW $0003
    DW !OldT1Esc<n>_Colors_2a
    DW SkipColors_4
    DW !OldT1Esc<n>_Colors_2b
    DW SkipColors_2
    DW !OldT1Esc<n>_Colors_2c
    DW GlowYeild
  DW $0003
    DW !OldT1Esc<n>_Colors_1a
    DW SkipColors_4
    DW !OldT1Esc<n>_Colors_1b
    DW SkipColors_2
    DW !OldT1Esc<n>_Colors_1c
    DW GlowYeild
  DW GlowJMP, OldT1Esc<n>_List_Loop
endmacro

%OldT1Esc_List(0)
%OldT1Esc_List(1)
%OldT1Esc_List(2)
%OldT1Esc_List(3)
%OldT1Esc_List(4)
%OldT1Esc_List(5)
%OldT1Esc_List(6)
%OldT1Esc_List(7)

OldT2EscTable:
  DW EmptyInit,OldT2Esc0_List, EmptyInit,OldT2Esc1_List, EmptyInit,OldT2Esc2_List, EmptyInit,OldT2Esc3_List
  DW EmptyInit,OldT2Esc4_List, EmptyInit,OldT2Esc5_List, EmptyInit,OldT2Esc6_List, EmptyInit,OldT2Esc7_List
  DW EmptyInit,OldT2Esc0_List

macro OldT2Esc_List(n)
OldT2Esc<n>_List:
  DW SetColorIndex, $00D2
OldT2Esc<n>_List_Loop:
  DW $0010
    DW !OldT2Esc<n>_Colors_0
    DW GlowYeild
  DW $0001
    DW !OldT2Esc<n>_Colors_1
    DW GlowYeild
  DW $0001
    DW !OldT2Esc<n>_Colors_2
    DW GlowYeild
  DW $0002
    DW !OldT2Esc<n>_Colors_3
    DW GlowYeild
  DW $0001
    DW !OldT2Esc<n>_Colors_4
    DW GlowYeild
  DW $0002
    DW !OldT2Esc<n>_Colors_0
    DW GlowYeild
  DW $0001
    DW !OldT2Esc<n>_Colors_1
    DW GlowYeild
  DW $0001
    DW !OldT2Esc<n>_Colors_2
    DW GlowYeild
  DW $0001
    DW !OldT2Esc<n>_Colors_3
    DW GlowYeild
  DW $0001
    DW !OldT2Esc<n>_Colors_4
    DW GlowYeild
  DW $0020
    DW !OldT2Esc<n>_Colors_0
    DW GlowYeild
  DW $0002
    DW !OldT2Esc<n>_Colors_1
    DW GlowYeild
  DW $0001
    DW !OldT2Esc<n>_Colors_2
    DW GlowYeild
  DW $0001
    DW !OldT2Esc<n>_Colors_3
    DW GlowYeild
  DW $0001
    DW !OldT2Esc<n>_Colors_4
    DW GlowYeild
  DW GlowJMP, OldT2Esc<n>_List_Loop
endmacro

%OldT2Esc_List(0)
%OldT2Esc_List(1)
%OldT2Esc_List(2)
%OldT2Esc_List(3)
%OldT2Esc_List(4)
%OldT2Esc_List(5)
%OldT2Esc_List(6)
%OldT2Esc_List(7)

OldT3EscTable:
  DW EmptyInit,OldT3Esc0_List, EmptyInit,OldT3Esc1_List, EmptyInit,OldT3Esc2_List, EmptyInit,OldT3Esc3_List
  DW EmptyInit,OldT3Esc4_List, EmptyInit,OldT3Esc5_List, EmptyInit,OldT3Esc6_List, EmptyInit,OldT3Esc7_List
  DW EmptyInit,OldT3Esc0_List

macro OldT3Esc_List(n)
OldT3Esc<n>_List:
  DW SetColorIndex, $00AA
OldT3Esc<n>_List_Loop:
  DW $0010
    DW !OldT3Esc<n>_Colors_0
    DW GlowYeild
  DW $0001
    DW !OldT3Esc<n>_Colors_1
    DW GlowYeild
  DW $0001
    DW !OldT3Esc<n>_Colors_2
    DW GlowYeild
  DW $0002
    DW !OldT3Esc<n>_Colors_3
    DW GlowYeild
  DW $0001
    DW !OldT3Esc<n>_Colors_4
    DW GlowYeild
  DW $0002
    DW !OldT3Esc<n>_Colors_0
    DW GlowYeild
  DW $0001
    DW !OldT3Esc<n>_Colors_1
    DW GlowYeild
  DW $0001
    DW !OldT3Esc<n>_Colors_2
    DW GlowYeild
  DW $0001
    DW !OldT3Esc<n>_Colors_3
    DW GlowYeild
  DW $0001
    DW !OldT3Esc<n>_Colors_4
    DW GlowYeild
  DW $0020
    DW !OldT3Esc<n>_Colors_0
    DW GlowYeild
  DW $0002
    DW !OldT3Esc<n>_Colors_1
    DW GlowYeild
  DW $0001
    DW !OldT3Esc<n>_Colors_2
    DW GlowYeild
  DW $0001
    DW !OldT3Esc<n>_Colors_3
    DW GlowYeild
  DW $0001
    DW !OldT3Esc<n>_Colors_4
    DW GlowYeild
  DW GlowJMP, OldT3Esc<n>_List_Loop
endmacro

%OldT3Esc_List(0)
%OldT3Esc_List(1)
%OldT3Esc_List(2)
%OldT3Esc_List(3)
%OldT3Esc_List(4)
%OldT3Esc_List(5)
%OldT3Esc_List(6)
%OldT3Esc_List(7)

; Brinstar tileset glows
; 94 75 23
; 60 49 8
Blue_BG_Table:
  DW EmptyInit,Blue_BG_0_List, EmptyInit,Blue_BG_1_List, EmptyInit,Blue_BG_2_List, EmptyInit,Blue_BG_3_List
  DW EmptyInit,Blue_BG_4_List, EmptyInit,Blue_BG_5_List, EmptyInit,Blue_BG_6_List, EmptyInit,Blue_BG_7_List
  DW EmptyInit,Blue_BG_1_List


macro Blue_BG__List(n)
Blue_BG_<n>_List:
  DW SetColorIndex, $00E2
Blue_BG_<n>_List_Loop:
  DW $000A
    DW !Blue_BG_<n>_Colors_0
    DW GlowYeild
  DW $000A
    DW !Blue_BG_<n>_Colors_1
    DW GlowYeild
  DW $000A
    DW !Blue_BG_<n>_Colors_2
    DW GlowYeild
  DW $000A
    DW !Blue_BG_<n>_Colors_3
    DW GlowYeild
  DW $000A
    DW !Blue_BG_<n>_Colors_4
    DW GlowYeild
  DW $000A
    DW !Blue_BG_<n>_Colors_5
    DW GlowYeild
  DW $000A
    DW !Blue_BG_<n>_Colors_6
    DW GlowYeild
  DW $000A
    DW !Blue_BG_<n>_Colors_7
    DW GlowYeild
  DW $000A
    DW !Blue_BG_<n>_Colors_6
    DW GlowYeild
  DW $000A
    DW !Blue_BG_<n>_Colors_5
    DW GlowYeild
  DW $000A
    DW !Blue_BG_<n>_Colors_4
    DW GlowYeild
  DW $000A
    DW !Blue_BG_<n>_Colors_3
    DW GlowYeild
  DW $000A
    DW !Blue_BG_<n>_Colors_2
    DW GlowYeild
  DW $000A
    DW !Blue_BG_<n>_Colors_1
    DW GlowYeild
  DW GlowJMP, Blue_BG_<n>_List_Loop
endmacro

%Blue_BG__List(0)
%Blue_BG__List(1)
%Blue_BG__List(2)
%Blue_BG__List(3)
%Blue_BG__List(4)
%Blue_BG__List(5)
%Blue_BG__List(6)
%Blue_BG__List(7)

SpoSpoBGInit:
  PHX
  LDX $079F
  LDA $7ED828,X
  PLX
  AND #$0002
  BEQ +
  LDA #$0000
  STA $1E7D,Y
+
  RTS

SpoSpoBGPreInstruction:
  PHX
  LDX $079F
  LDA $7ED828,X
  PLX
  AND #$0002
  BEQ +
  LDA #$0000
  STA $1E7D,X
+
  RTS

SpoSpoBGTable:
  DW SpoSpoBGInit,SpoSpoBG0_List, SpoSpoBGInit,SpoSpoBG1_List, SpoSpoBGInit,SpoSpoBG2_List, SpoSpoBGInit,SpoSpoBG3_List
  DW SpoSpoBGInit,SpoSpoBG4_List, SpoSpoBGInit,SpoSpoBG5_List, SpoSpoBGInit,SpoSpoBG6_List, SpoSpoBGInit,SpoSpoBG7_List
  DW SpoSpoBGInit,SpoSpoBG1_List
SpoSpoBG0_List:
  DW SetPreInstruction, SpoSpoBGPreInstruction
  DW GlowJMP, Blue_BG_0_List
SpoSpoBG1_List:
  DW SetPreInstruction, SpoSpoBGPreInstruction
  DW GlowJMP, Blue_BG_1_List
SpoSpoBG2_List:
  DW SetPreInstruction, SpoSpoBGPreInstruction
  DW GlowJMP, Blue_BG_2_List
SpoSpoBG3_List:
  DW SetPreInstruction, SpoSpoBGPreInstruction
  DW GlowJMP, Blue_BG_3_List
SpoSpoBG4_List:
  DW SetPreInstruction, SpoSpoBGPreInstruction
  DW GlowJMP, Blue_BG_4_List
SpoSpoBG5_List:
  DW SetPreInstruction, SpoSpoBGPreInstruction
  DW GlowJMP, Blue_BG_5_List
SpoSpoBG6_List:
  DW SetPreInstruction, SpoSpoBGPreInstruction
  DW GlowJMP, Blue_BG_6_List
SpoSpoBG7_List:
  DW SetPreInstruction, SpoSpoBGPreInstruction
  DW GlowJMP, Blue_BG_7_List

; 87 56 34 26 19 11 8 4
Purp_BG_Table:
  DW EmptyInit,Purp_BG_0_List, EmptyInit,Purp_BG_1_List, EmptyInit,Purp_BG_2_List, EmptyInit,Purp_BG_3_List
  DW EmptyInit,Purp_BG_4_List, EmptyInit,Purp_BG_5_List, EmptyInit,Purp_BG_6_List, EmptyInit,Purp_BG_7_List
  DW EmptyInit,Purp_BG_1_List

macro Purp_BG__List(n)
Purp_BG_<n>_List:
  DW SetColorIndex, $00C8
Purp_BG_<n>_List_Loop:
  DW $000A
    DW !Purp_BG_<n>_Colors_0
    DW GlowYeild
  DW $000A
    DW !Purp_BG_<n>_Colors_1
    DW GlowYeild
  DW $000A
    DW !Purp_BG_<n>_Colors_2
    DW GlowYeild
  DW $000A
    DW !Purp_BG_<n>_Colors_3
    DW GlowYeild
  DW $000A
    DW !Purp_BG_<n>_Colors_4
    DW GlowYeild
  DW $000A
    DW !Purp_BG_<n>_Colors_5
    DW GlowYeild
  DW $000A
    DW !Purp_BG_<n>_Colors_6
    DW GlowYeild
  DW $000A
    DW !Purp_BG_<n>_Colors_7
    DW GlowYeild
  DW $000A
    DW !Purp_BG_<n>_Colors_6
    DW GlowYeild
  DW $000A
    DW !Purp_BG_<n>_Colors_5
    DW GlowYeild
  DW $000A
    DW !Purp_BG_<n>_Colors_4
    DW GlowYeild
  DW $000A
    DW !Purp_BG_<n>_Colors_3
    DW GlowYeild
  DW $000A
    DW !Purp_BG_<n>_Colors_2
    DW GlowYeild
  DW $000A
    DW !Purp_BG_<n>_Colors_1
    DW GlowYeild
  DW GlowJMP, Purp_BG_<n>_List_Loop
endmacro

%Purp_BG__List(0)
%Purp_BG__List(1)
%Purp_BG__List(2)
%Purp_BG__List(3)
%Purp_BG__List(4)
%Purp_BG__List(5)
%Purp_BG__List(6)
%Purp_BG__List(7)

; Crateria and Brinstar need to use the same table to keep vanilla rooms working as expected
Beacon__Table:
  DW EmptyInit,Beacon__0_List, EmptyInit,Beacon__1_List, EmptyInit,Beacon__2_List, EmptyInit,Beacon__3_List
  DW EmptyInit,Beacon__4_List, EmptyInit,Beacon__5_List, EmptyInit,Beacon__6_List, EmptyInit,Beacon__7_List
  DW EmptyInit,Beacon__1_List

macro Beacon___List(n)
Beacon__<n>_List:
  DW SetColorIndex, $00E2
Beacon__<n>_List_Loop:
  DW $000A
    DW !Beacon__<n>_Colors_0a
    DW SkipColors_9
    DW !Beacon__<n>_Colors_0b
    DW GlowYeild
  DW $000A
    DW !Beacon__<n>_Colors_1a
    DW SkipColors_9
    DW !Beacon__<n>_Colors_1b
    DW GlowYeild
  DW $000A
    DW !Beacon__<n>_Colors_2a
    DW SkipColors_9
    DW !Beacon__<n>_Colors_2b
    DW GlowYeild
  DW $000A
    DW !Beacon__<n>_Colors_3a
    DW SkipColors_9
    DW !Beacon__<n>_Colors_3b
    DW GlowYeild
  DW $000A
    DW !Beacon__<n>_Colors_4a
    DW SkipColors_9
    DW !Beacon__<n>_Colors_4b
    DW GlowYeild
  DW $000A
    DW !Beacon__<n>_Colors_5a
    DW SkipColors_9
    DW !Beacon__<n>_Colors_5b
    DW GlowYeild
  DW PlaySFX : DB $18
  DW $000A
    DW !Beacon__<n>_Colors_5a
    DW SkipColors_9
    DW !Beacon__<n>_Colors_5b
    DW GlowYeild
  DW $000A
    DW !Beacon__<n>_Colors_4a
    DW SkipColors_9
    DW !Beacon__<n>_Colors_4b
    DW GlowYeild
  DW $000A
    DW !Beacon__<n>_Colors_3a
    DW SkipColors_9
    DW !Beacon__<n>_Colors_3b
    DW GlowYeild
  DW $000A
    DW !Beacon__<n>_Colors_2a
    DW SkipColors_9
    DW !Beacon__<n>_Colors_2b
    DW GlowYeild
  DW $000A
    DW !Beacon__<n>_Colors_1a
    DW SkipColors_9
    DW !Beacon__<n>_Colors_1b
    DW GlowYeild
  DW GlowJMP, Beacon__<n>_List_Loop
endmacro

%Beacon___List(0)
%Beacon___List(1)
%Beacon___List(2)
%Beacon___List(3)
%Beacon___List(4)
%Beacon___List(5)
%Beacon___List(6)
%Beacon___List(7)

; Norfair tileset glows

SetHeatGlowSync:
  LDA $0000,Y
  AND #$00FF
  STA $1EED
  INY
  RTS

NorfairCommonColors_0:
  DW $09FD, $093B, $0459
NorfairCommonColors_1:
  DW $0E3D, $0D7C, $089A
NorfairCommonColors_2:
  DW $165E, $0DBC, $08FB
NorfairCommonColors_3:
  DW $1A9E, $11FD, $0D3C
NorfairCommonColors_4:
  DW $1EBE, $161D, $119C
NorfairCommonColors_5:
  DW $22FE, $1A5E, $15DD
NorfairCommonColors_6:
  DW $2B1F, $1A9E, $163E
NorfairCommonColors_7:
  DW $2F5F, $1EDF, $1A7F

NorfairCommon:
  LDA $0000,Y
  STA $7EC000,X
  INX
  INX
  LDA $0002,Y
  STA $7EC000,X
  INX
  INX
  LDA $0004,Y
  STA $7EC000,X
  INX
  INX
  PLY
  INY
  INY
  RTS

NorfairCommon_0:
  PHY
  LDY #NorfairCommonColors_0
  JMP NorfairCommon

NorfairCommon_1:
  PHY
  LDY #NorfairCommonColors_1
  JMP NorfairCommon

NorfairCommon_2:
  PHY
  LDY #NorfairCommonColors_2
  JMP NorfairCommon

NorfairCommon_3:
  PHY
  LDY #NorfairCommonColors_3
  JMP NorfairCommon

NorfairCommon_4:
  PHY
  LDY #NorfairCommonColors_4
  JMP NorfairCommon

NorfairCommon_5:
  PHY
  LDY #NorfairCommonColors_5
  JMP NorfairCommon

NorfairCommon_6:
  PHY
  LDY #NorfairCommonColors_6
  JMP NorfairCommon

NorfairCommon_7:
  PHY
  LDY #NorfairCommonColors_7
  JMP NorfairCommon

NorfairCommonColorsInit:
  PHX
  PHY
  LDA $1EBD,Y
  TAY
  LDX $0002,Y
  LDA NorfairCommonColors_0+0
  STA $7EC200,X
  LDA NorfairCommonColors_0+2
  STA $7EC202,X
  LDA NorfairCommonColors_0+4
  STA $7EC204,X

  LDA #$0EDF
  STA $7EC268
  STA $7EC250
  LDA #$0E3F
  STA $7EC252
  LDA #$0D7F
  STA $7EC254
  LDA #$0C9F
  STA $7EC256
  LDA #$0EDF
  STA $7EC25A

  PLY
  PLX
  RTS

NorHot1_Table:
  DW NorfairCommonColorsInit,NorHot1_0_List, NorfairCommonColorsInit,NorHot1_1_List, NorfairCommonColorsInit,NorHot1_2_List, NorfairCommonColorsInit,NorHot1_3_List
  DW NorfairCommonColorsInit,NorHot1_4_List, NorfairCommonColorsInit,NorHot1_5_List, NorfairCommonColorsInit,NorHot1_6_List, NorfairCommonColorsInit,NorHot1_7_List
  DW NorfairCommonColorsInit,NorHot1_2_List

macro NorHot1__List(n)
NorHot1_<n>_List:
  DW SetColorIndex, $006A
NorHot1_<n>_List_Loop:
  DW SetHeatGlowSync : DB $00
  DW $0010
    DW NorfairCommon_0
    DW SkipColors_4
    DW !NorHot1_<n>_Colors_0
    DW GlowYeild
  DW SetHeatGlowSync : DB $01
  DW $0004
    DW NorfairCommon_1
    DW SkipColors_4
    DW !NorHot1_<n>_Colors_1
    DW GlowYeild
  DW SetHeatGlowSync : DB $02
  DW $0004
    DW NorfairCommon_2
    DW SkipColors_4
    DW !NorHot1_<n>_Colors_2
    DW GlowYeild
  DW SetHeatGlowSync : DB $03
  DW $0005
    DW NorfairCommon_3
    DW SkipColors_4
    DW !NorHot1_<n>_Colors_3
    DW GlowYeild
  DW SetHeatGlowSync : DB $04
  DW $0006
    DW NorfairCommon_4
    DW SkipColors_4
    DW !NorHot1_<n>_Colors_4
    DW GlowYeild
  DW SetHeatGlowSync : DB $05
  DW $0007
    DW NorfairCommon_5
    DW SkipColors_4
    DW !NorHot1_<n>_Colors_5
    DW GlowYeild
  DW SetHeatGlowSync : DB $06
  DW $0008
    DW NorfairCommon_6
    DW SkipColors_4
    DW !NorHot1_<n>_Colors_6
    DW GlowYeild
  DW SetHeatGlowSync : DB $07
  DW $0008
    DW NorfairCommon_7
    DW SkipColors_4
    DW !NorHot1_<n>_Colors_7
    DW GlowYeild
  DW SetHeatGlowSync : DB $08
  DW $0008
    DW NorfairCommon_7
    DW SkipColors_4
    DW !NorHot1_<n>_Colors_7
    DW GlowYeild
  DW SetHeatGlowSync : DB $09
  DW $0008
    DW NorfairCommon_6
    DW SkipColors_4
    DW !NorHot1_<n>_Colors_6
    DW GlowYeild
  DW SetHeatGlowSync : DB $0A
  DW $0007
    DW NorfairCommon_5
    DW SkipColors_4
    DW !NorHot1_<n>_Colors_5
    DW GlowYeild
  DW SetHeatGlowSync : DB $0B
  DW $0006
    DW NorfairCommon_4
    DW SkipColors_4
    DW !NorHot1_<n>_Colors_4
    DW GlowYeild
  DW SetHeatGlowSync : DB $0C
  DW $0005
    DW NorfairCommon_3
    DW SkipColors_4
    DW !NorHot1_<n>_Colors_3
    DW GlowYeild
  DW SetHeatGlowSync : DB $0D
  DW $0004
    DW NorfairCommon_2
    DW SkipColors_4
    DW !NorHot1_<n>_Colors_2
    DW GlowYeild
  DW SetHeatGlowSync : DB $0E
  DW $0004
    DW NorfairCommon_1
    DW SkipColors_4
    DW !NorHot1_<n>_Colors_1
    DW GlowYeild
  DW SetHeatGlowSync : DB $0F
  DW $0010
    DW NorfairCommon_0
    DW SkipColors_4
    DW !NorHot1_<n>_Colors_0
    DW GlowYeild
  DW GlowJMP, NorHot1_<n>_List_Loop
endmacro

%NorHot1__List(0)
%NorHot1__List(1)
%NorHot1__List(2)
%NorHot1__List(3)
%NorHot1__List(4)
%NorHot1__List(5)
%NorHot1__List(6)
%NorHot1__List(7)

NorHot2_Table:
  DW NorfairCommonColorsInit,NorHot2_0_List, NorfairCommonColorsInit,NorHot2_1_List, NorfairCommonColorsInit,NorHot2_2_List, NorfairCommonColorsInit,NorHot2_3_List
  DW NorfairCommonColorsInit,NorHot2_4_List, NorfairCommonColorsInit,NorHot2_5_List, NorfairCommonColorsInit,NorHot2_6_List, NorfairCommonColorsInit,NorHot2_7_List
  DW NorfairCommonColorsInit,NorHot2_2_List

macro NorHot2__List(n)
NorHot2_<n>_List:
  DW SetColorIndex, $0082
NorHot2_<n>_List_Loop:
  DW $0010
    DW NorfairCommon_0
    DW SkipColors_8
    DW !NorHot2_<n>_Colors_0
    DW GlowYeild
  DW $0004
    DW NorfairCommon_1
    DW SkipColors_8
    DW !NorHot2_<n>_Colors_1
    DW GlowYeild
  DW $0004
    DW NorfairCommon_2
    DW SkipColors_8
    DW !NorHot2_<n>_Colors_2
    DW GlowYeild
  DW $0005
    DW NorfairCommon_3
    DW SkipColors_8
    DW !NorHot2_<n>_Colors_3
    DW GlowYeild
  DW $0006
    DW NorfairCommon_4
    DW SkipColors_8
    DW !NorHot2_<n>_Colors_4
    DW GlowYeild
  DW $0007
    DW NorfairCommon_5
    DW SkipColors_8
    DW !NorHot2_<n>_Colors_5
    DW GlowYeild
  DW $0008
    DW NorfairCommon_6
    DW SkipColors_8
    DW !NorHot2_<n>_Colors_6
    DW GlowYeild
  DW $0010
    DW NorfairCommon_7
    DW SkipColors_8
    DW !NorHot2_<n>_Colors_7
    DW GlowYeild
  DW $0008
    DW NorfairCommon_6
    DW SkipColors_8
    DW !NorHot2_<n>_Colors_6
    DW GlowYeild
  DW $0007
    DW NorfairCommon_5
    DW SkipColors_8
    DW !NorHot2_<n>_Colors_5
    DW GlowYeild
  DW $0006
    DW NorfairCommon_4
    DW SkipColors_8
    DW !NorHot2_<n>_Colors_4
    DW GlowYeild
  DW $0005
    DW NorfairCommon_3
    DW SkipColors_8
    DW !NorHot2_<n>_Colors_3
    DW GlowYeild
  DW $0004
    DW NorfairCommon_2
    DW SkipColors_8
    DW !NorHot2_<n>_Colors_2
    DW GlowYeild
  DW $0004
    DW NorfairCommon_1
    DW SkipColors_8
    DW !NorHot2_<n>_Colors_1
    DW GlowYeild
  DW $0010
    DW NorfairCommon_0
    DW SkipColors_8
    DW !NorHot2_<n>_Colors_0
    DW GlowYeild
  DW GlowJMP, NorHot2_<n>_List_Loop
endmacro

%NorHot2__List(0)
%NorHot2__List(1)
%NorHot2__List(2)
%NorHot2__List(3)
%NorHot2__List(4)
%NorHot2__List(5)
%NorHot2__List(6)
%NorHot2__List(7)

NorHot3_Table:
  DW NorfairCommonColorsInit,NorHot3_0_List, NorfairCommonColorsInit,NorHot3_1_List, NorfairCommonColorsInit,NorHot3_2_List, NorfairCommonColorsInit,NorHot3_3_List
  DW NorfairCommonColorsInit,NorHot3_4_List, NorfairCommonColorsInit,NorHot3_5_List, NorfairCommonColorsInit,NorHot3_6_List, NorfairCommonColorsInit,NorHot3_7_List
  DW NorfairCommonColorsInit,NorHot3_2_List

macro NorHot3__List(n)
NorHot3_<n>_List:
  DW SetColorIndex, $00A2
NorHot3_<n>_List_Loop:
  DW $0010
    DW NorfairCommon_0
    DW SkipColors_8
    DW !NorHot3_<n>_Colors_0
    DW GlowYeild
  DW $0004
    DW NorfairCommon_1
    DW SkipColors_8
    DW !NorHot3_<n>_Colors_1
    DW GlowYeild
  DW $0004
    DW NorfairCommon_2
    DW SkipColors_8
    DW !NorHot3_<n>_Colors_2
    DW GlowYeild
  DW $0005
    DW NorfairCommon_3
    DW SkipColors_8
    DW !NorHot3_<n>_Colors_3
    DW GlowYeild
  DW $0006
    DW NorfairCommon_4
    DW SkipColors_8
    DW !NorHot3_<n>_Colors_4
    DW GlowYeild
  DW $0007
    DW NorfairCommon_5
    DW SkipColors_8
    DW !NorHot3_<n>_Colors_5
    DW GlowYeild
  DW $0008
    DW NorfairCommon_6
    DW SkipColors_8
    DW !NorHot3_<n>_Colors_6
    DW GlowYeild
  DW $0010
    DW NorfairCommon_7
    DW SkipColors_8
    DW !NorHot3_<n>_Colors_7
    DW GlowYeild
  DW $0008
    DW NorfairCommon_6
    DW SkipColors_8
    DW !NorHot3_<n>_Colors_6
    DW GlowYeild
  DW $0007
    DW NorfairCommon_5
    DW SkipColors_8
    DW !NorHot3_<n>_Colors_5
    DW GlowYeild
  DW $0006
    DW NorfairCommon_4
    DW SkipColors_8
    DW !NorHot3_<n>_Colors_4
    DW GlowYeild
  DW $0005
    DW NorfairCommon_3
    DW SkipColors_8
    DW !NorHot3_<n>_Colors_3
    DW GlowYeild
  DW $0004
    DW NorfairCommon_2
    DW SkipColors_8
    DW !NorHot3_<n>_Colors_2
    DW GlowYeild
  DW $0004
    DW NorfairCommon_1
    DW SkipColors_8
    DW !NorHot3_<n>_Colors_1
    DW GlowYeild
  DW $0010
    DW NorfairCommon_0
    DW SkipColors_8
    DW !NorHot3_<n>_Colors_0
    DW GlowYeild
  DW GlowJMP, NorHot3_<n>_List_Loop
endmacro

%NorHot3__List(0)
%NorHot3__List(1)
%NorHot3__List(2)
%NorHot3__List(3)
%NorHot3__List(4)
%NorHot3__List(5)
%NorHot3__List(6)
%NorHot3__List(7)

NorfairCommonDark_0:
  DW $09DA, $091A, $087A
NorfairCommonDark_1:
  DW $0DDA, $093A, $089A
NorfairCommonDark_2:
  DW $0DFA, $0D5A, $08BA
NorfairCommonDark_3:
  DW $11FA, $0D7A, $08FA
NorfairCommonDark_4:
  DW $161A, $119A, $0D1A
NorfairCommonDark_5:
  DW $1A1A, $11BA, $0D3A
NorfairCommonDark_6:
  DW $1A3A, $15DA, $0D7A
NorfairCommonDark_7:
  DW $225A, $1A1A, $11BA

NorfairDark_0:
  PHY
  LDY #NorfairCommonDark_0
  JMP NorfairCommon

NorfairDark_1:
  PHY
  LDY #NorfairCommonDark_1
  JMP NorfairCommon

NorfairDark_2:
  PHY
  LDY #NorfairCommonDark_2
  JMP NorfairCommon

NorfairDark_3:
  PHY
  LDY #NorfairCommonDark_3
  JMP NorfairCommon

NorfairDark_4:
  PHY
  LDY #NorfairCommonDark_4
  JMP NorfairCommon

NorfairDark_5:
  PHY
  LDY #NorfairCommonDark_5
  JMP NorfairCommon

NorfairDark_6:
  PHY
  LDY #NorfairCommonDark_6
  JMP NorfairCommon

NorfairDark_7:
  PHY
  LDY #NorfairCommonDark_7
  JMP NorfairCommon

NorfairCommonDarkInit:
  PHX
  PHY
  LDA $1EBD,Y
  TAY
  LDX $0002,Y
  LDA NorfairCommonDark_0+0
  STA $7EC200,X
  LDA NorfairCommonDark_0+2
  STA $7EC202,X
  LDA NorfairCommonDark_0+4
  STA $7EC204,X

  LDA #$0596
  STA $7EC220,X
  LDA #$04D6
  STA $7EC222,X
  LDA #$0456
  STA $7EC224,X

  PLY
  PLX
  RTS

NorHot4_Table:
  DW NorfairCommonDarkInit,NorHot4_0_List, NorfairCommonDarkInit,NorHot4_1_List, NorfairCommonDarkInit,NorHot4_2_List, NorfairCommonDarkInit,NorHot4_3_List
  DW NorfairCommonDarkInit,NorHot4_4_List, NorfairCommonDarkInit,NorHot4_5_List, NorfairCommonDarkInit,NorHot4_6_List, NorfairCommonDarkInit,NorHot4_7_List
  DW NorfairCommonDarkInit,NorHot4_2_List

macro NorHot4__List(n)
NorHot4_<n>_List:
  DW SetColorIndex, $00C2
NorHot4_<n>_List_Loop:
  DW $0010
    DW NorfairDark_0
    DW SkipColors_8
    DW !NorHot4_<n>_Colors_0
    DW GlowYeild
  DW $0004
    DW NorfairDark_1
    DW SkipColors_8
    DW !NorHot4_<n>_Colors_1
    DW GlowYeild
  DW $0004
    DW NorfairDark_2
    DW SkipColors_8
    DW !NorHot4_<n>_Colors_2
    DW GlowYeild
  DW $0005
    DW NorfairDark_3
    DW SkipColors_8
    DW !NorHot4_<n>_Colors_3
    DW GlowYeild
  DW $0006
    DW NorfairDark_4
    DW SkipColors_8
    DW !NorHot4_<n>_Colors_4
    DW GlowYeild
  DW $0007
    DW NorfairDark_5
    DW SkipColors_8
    DW !NorHot4_<n>_Colors_5
    DW GlowYeild
  DW $0008
    DW NorfairDark_6
    DW SkipColors_8
    DW !NorHot4_<n>_Colors_6
    DW GlowYeild
  DW $0010
    DW NorfairDark_7
    DW SkipColors_8
    DW !NorHot4_<n>_Colors_7
    DW GlowYeild
  DW $0008
    DW NorfairDark_6
    DW SkipColors_8
    DW !NorHot4_<n>_Colors_6
    DW GlowYeild
  DW $0007
    DW NorfairDark_5
    DW SkipColors_8
    DW !NorHot4_<n>_Colors_5
    DW GlowYeild
  DW $0006
    DW NorfairDark_4
    DW SkipColors_8
    DW !NorHot4_<n>_Colors_4
    DW GlowYeild
  DW $0005
    DW NorfairDark_3
    DW SkipColors_8
    DW !NorHot4_<n>_Colors_3
    DW GlowYeild
  DW $0004
    DW NorfairDark_2
    DW SkipColors_8
    DW !NorHot4_<n>_Colors_2
    DW GlowYeild
  DW $0004
    DW NorfairDark_1
    DW SkipColors_8
    DW !NorHot4_<n>_Colors_1
    DW GlowYeild
  DW $0010
    DW NorfairDark_0
    DW SkipColors_8
    DW !NorHot4_<n>_Colors_0
    DW GlowYeild
  DW GlowJMP, NorHot4_<n>_List_Loop
endmacro

%NorHot4__List(0)
%NorHot4__List(1)
%NorHot4__List(2)
%NorHot4__List(3)
%NorHot4__List(4)
%NorHot4__List(5)
%NorHot4__List(6)
%NorHot4__List(7)

; Wrecked Ship tileset glows

WS_GreenTable:
  DW EmptyInit,WS_Green0_List, EmptyInit,WS_Green1_List, EmptyInit,WS_Green2_List, EmptyInit,WS_Green3_List
  DW EmptyInit,WS_Green4_List, EmptyInit,WS_Green5_List, EmptyInit,WS_Green6_List, EmptyInit,WS_Green7_List
  DW EmptyInit,WS_Green3_List

macro WS_Green_List(n)
WS_Green<n>_List:
  DW SetColorIndex, $0098
WS_Green<n>_List_Loop:
  DW $000A
    DW !WS_Green<n>_Colors_0
    DW GlowYeild
  DW $000A
    DW !WS_Green<n>_Colors_1
    DW GlowYeild
  DW $000A
    DW !WS_Green<n>_Colors_2
    DW GlowYeild
  DW $000A
    DW !WS_Green<n>_Colors_3
    DW GlowYeild
  DW $000A
    DW !WS_Green<n>_Colors_4
    DW GlowYeild
  DW $000A
    DW !WS_Green<n>_Colors_3
    DW GlowYeild
  DW $000A
    DW !WS_Green<n>_Colors_2
    DW GlowYeild
  DW $000A
    DW !WS_Green<n>_Colors_1
    DW GlowYeild
  DW GlowJMP, WS_Green<n>_List_Loop
endmacro

%WS_Green_List(0)
%WS_Green_List(1)
%WS_Green_List(2)
%WS_Green_List(3)
%WS_Green_List(4)
%WS_Green_List(5)
%WS_Green_List(6)
%WS_Green_List(7)

; Maridia tileset glows

WaterfallColorsInit:
  PHX
  PHY
  LDA $1EBD,Y
  CLC
  ADC #$0006
  STA $12

  LDY #$0000
  LDX #$0068
-
  LDA ($12),Y
  STA $7EC200,X
  INX
  INX
  INY
  INY
  CPY #$0010
  BMI -
  PLY
  PLX
  RTS

WaterfalTable:
  DW WaterfallColorsInit,Waterfal0_List, WaterfallColorsInit,Waterfal1_List, WaterfallColorsInit,Waterfal2_List, WaterfallColorsInit,Waterfal3_List
  DW WaterfallColorsInit,Waterfal4_List, WaterfallColorsInit,Waterfal5_List, WaterfallColorsInit,Waterfal6_List, WaterfallColorsInit,Waterfal7_List
  DW WaterfallColorsInit,Waterfal4_List

macro Waterfal_List(n)
Waterfal<n>_List:
  DW SetColorIndex, $0068
Waterfal<n>_List_Loop:
  DW $0002
    DW !Waterfal<n>_Color_0, !Waterfal<n>_Color_1, !Waterfal<n>_Color_2, !Waterfal<n>_Color_3, !Waterfal<n>_Color_4, !Waterfal<n>_Color_5, !Waterfal<n>_Color_6, !Waterfal<n>_Color_7
    DW GlowYeild
  DW $0002
    DW !Waterfal<n>_Color_1, !Waterfal<n>_Color_2, !Waterfal<n>_Color_3, !Waterfal<n>_Color_4, !Waterfal<n>_Color_5, !Waterfal<n>_Color_6, !Waterfal<n>_Color_7, !Waterfal<n>_Color_0
    DW GlowYeild
  DW $0002
    DW !Waterfal<n>_Color_2, !Waterfal<n>_Color_3, !Waterfal<n>_Color_4, !Waterfal<n>_Color_5, !Waterfal<n>_Color_6, !Waterfal<n>_Color_7, !Waterfal<n>_Color_0, !Waterfal<n>_Color_1
    DW GlowYeild
  DW $0002
    DW !Waterfal<n>_Color_3, !Waterfal<n>_Color_4, !Waterfal<n>_Color_5, !Waterfal<n>_Color_6, !Waterfal<n>_Color_7, !Waterfal<n>_Color_0, !Waterfal<n>_Color_1, !Waterfal<n>_Color_2
    DW GlowYeild
  DW $0002
    DW !Waterfal<n>_Color_4, !Waterfal<n>_Color_5, !Waterfal<n>_Color_6, !Waterfal<n>_Color_7, !Waterfal<n>_Color_0, !Waterfal<n>_Color_1, !Waterfal<n>_Color_2, !Waterfal<n>_Color_3
    DW GlowYeild
  DW $0002
    DW !Waterfal<n>_Color_5, !Waterfal<n>_Color_6, !Waterfal<n>_Color_7, !Waterfal<n>_Color_0, !Waterfal<n>_Color_1, !Waterfal<n>_Color_2, !Waterfal<n>_Color_3, !Waterfal<n>_Color_4
    DW GlowYeild
  DW $0002
    DW !Waterfal<n>_Color_6, !Waterfal<n>_Color_7, !Waterfal<n>_Color_0, !Waterfal<n>_Color_1, !Waterfal<n>_Color_2, !Waterfal<n>_Color_3, !Waterfal<n>_Color_4, !Waterfal<n>_Color_5
    DW GlowYeild
  DW $0002
    DW !Waterfal<n>_Color_7, !Waterfal<n>_Color_0, !Waterfal<n>_Color_1, !Waterfal<n>_Color_2, !Waterfal<n>_Color_3, !Waterfal<n>_Color_4, !Waterfal<n>_Color_5, !Waterfal<n>_Color_6
    DW GlowYeild
  DW GlowJMP, Waterfal<n>_List_Loop
endmacro

%Waterfal_List(0)
%Waterfal_List(1)
%Waterfal_List(2)
%Waterfal_List(3)
%Waterfal_List(4)
%Waterfal_List(5)
%Waterfal_List(6)
%Waterfal_List(7)

; Tourian tileset glows
Tourian_PreInstruction:
  LDA $1E79,X
  BEQ +
  STZ $1E7D,X
+
  RTS

Tourian_Table:
  DW EmptyInit,Tourian_0_List, EmptyInit,Tourian_1_List, EmptyInit,Tourian_2_List, EmptyInit,Tourian_3_List
  DW EmptyInit,Tourian_4_List, EmptyInit,Tourian_5_List, EmptyInit,Tourian_6_List, EmptyInit,Tourian_7_List
  DW EmptyInit,Tourian_5_List

macro Tourian__List(n)
Tourian_<n>_List:
  DW SetColorIndex, $00E8
Tourian_<n>_List_Loop:
  DW $000A
    DW !Tourian_<n>_Colors_0a
    DW SkipColors_3
    DW !Tourian_<n>_Colors_0b
    DW GlowYeild
  DW $000A
    DW !Tourian_<n>_Colors_1a
    DW SkipColors_3
    DW !Tourian_<n>_Colors_1b
    DW GlowYeild
  DW $000A
    DW !Tourian_<n>_Colors_2a
    DW SkipColors_3
    DW !Tourian_<n>_Colors_2b
    DW GlowYeild
  DW $000A
    DW !Tourian_<n>_Colors_3a
    DW SkipColors_3
    DW !Tourian_<n>_Colors_3b
    DW GlowYeild
  DW $000A
    DW !Tourian_<n>_Colors_4a
    DW SkipColors_3
    DW !Tourian_<n>_Colors_4b
    DW GlowYeild
  DW $0014
    DW !Tourian_<n>_Colors_5a
    DW SkipColors_3
    DW !Tourian_<n>_Colors_5b
    DW GlowYeild
  DW $000A
    DW !Tourian_<n>_Colors_4a
    DW SkipColors_3
    DW !Tourian_<n>_Colors_4b
    DW GlowYeild
  DW $000A
    DW !Tourian_<n>_Colors_3a
    DW SkipColors_3
    DW !Tourian_<n>_Colors_3b
    DW GlowYeild
  DW $000A
    DW !Tourian_<n>_Colors_2a
    DW SkipColors_3
    DW !Tourian_<n>_Colors_2b
    DW GlowYeild
  DW $000A
    DW !Tourian_<n>_Colors_1a
    DW SkipColors_3
    DW !Tourian_<n>_Colors_1b
    DW GlowYeild
  DW GlowJMP, Tourian_<n>_List_Loop
endmacro

%Tourian__List(0)
%Tourian__List(1)
%Tourian__List(2)
%Tourian__List(3)
%Tourian__List(4)
%Tourian__List(5)
%Tourian__List(6)
%Tourian__List(7)

Tor_2EscTable:
  DW EmptyInit,Tor_2Esc0_List, EmptyInit,Tor_2Esc1_List, EmptyInit,Tor_2Esc2_List, EmptyInit,Tor_2Esc3_List
  DW EmptyInit,Tor_2Esc4_List, EmptyInit,Tor_2Esc5_List, EmptyInit,Tor_2Esc6_List, EmptyInit,Tor_2Esc7_List
  DW EmptyInit,Tor_2Esc5_List

macro Tor_2Esc_List(n)
Tor_2Esc<n>_List:
  DW SetColorIndex, $0070
Tor_2Esc<n>_List_Loop:
  DW $0004
    DW !Tor_2Esc<n>_Colors_0
    DW GlowYeild
  DW $0004
    DW !Tor_2Esc<n>_Colors_1
    DW GlowYeild
  DW $0004
    DW !Tor_2Esc<n>_Colors_2
    DW GlowYeild
  DW $0004
    DW !Tor_2Esc<n>_Colors_3
    DW GlowYeild
  DW $0004
    DW !Tor_2Esc<n>_Colors_4
    DW GlowYeild
  DW $0004
    DW !Tor_2Esc<n>_Colors_5
    DW GlowYeild
  DW $0004
    DW !Tor_2Esc<n>_Colors_6
    DW GlowYeild
  DW $0004
    DW !Tor_2Esc<n>_Colors_7
    DW GlowYeild
  DW $0004
    DW !Tor_2Esc<n>_Colors_6
    DW GlowYeild
  DW $0004
    DW !Tor_2Esc<n>_Colors_5
    DW GlowYeild
  DW $0004
    DW !Tor_2Esc<n>_Colors_4
    DW GlowYeild
  DW $0004
    DW !Tor_2Esc<n>_Colors_3
    DW GlowYeild
  DW $0004
    DW !Tor_2Esc<n>_Colors_2
    DW GlowYeild
  DW $0004
    DW !Tor_2Esc<n>_Colors_1
    DW GlowYeild
  DW GlowJMP, Tor_2Esc<n>_List_Loop
endmacro

%Tor_2Esc_List(0)
%Tor_2Esc_List(1)
%Tor_2Esc_List(2)
%Tor_2Esc_List(3)
%Tor_2Esc_List(4)
%Tor_2Esc_List(5)
%Tor_2Esc_List(6)
%Tor_2Esc_List(7)

Tor_3EscTable:
  DW EmptyInit,Tor_3Esc0_List, EmptyInit,Tor_3Esc1_List, EmptyInit,Tor_3Esc2_List, EmptyInit,Tor_3Esc3_List
  DW EmptyInit,Tor_3Esc4_List, EmptyInit,Tor_3Esc5_List, EmptyInit,Tor_3Esc6_List, EmptyInit,Tor_3Esc7_List
  DW EmptyInit,Tor_3Esc5_List
Tor_3Esc0_List:
  DW SetColorIndex, $00A8
  DW GlowJMP, Tor_4Esc0_List_Loop
Tor_3Esc1_List:
  DW SetColorIndex, $00A8
  DW GlowJMP, Tor_4Esc1_List_Loop
Tor_3Esc2_List:
  DW SetColorIndex, $00A8
  DW GlowJMP, Tor_4Esc2_List_Loop
Tor_3Esc3_List:
  DW SetColorIndex, $00A8
  DW GlowJMP, Tor_4Esc3_List_Loop
Tor_3Esc4_List:
  DW SetColorIndex, $00A8
  DW GlowJMP, Tor_4Esc4_List_Loop
Tor_3Esc5_List:
  DW SetColorIndex, $00A8
  DW GlowJMP, Tor_4Esc5_List_Loop
Tor_3Esc6_List:
  DW SetColorIndex, $00A8
  DW GlowJMP, Tor_4Esc6_List_Loop
Tor_3Esc7_List:
  DW SetColorIndex, $00A8
  DW GlowJMP, Tor_4Esc0_List_Loop

Tor_4EscTable:
  DW EmptyInit,Tor_4Esc0_List, EmptyInit,Tor_4Esc1_List, EmptyInit,Tor_4Esc2_List, EmptyInit,Tor_4Esc3_List
  DW EmptyInit,Tor_4Esc4_List, EmptyInit,Tor_4Esc5_List, EmptyInit,Tor_4Esc6_List, EmptyInit,Tor_4Esc7_List
  DW EmptyInit,Tor_4Esc5_List

macro Tor_4Esc_List(n)
Tor_4Esc<n>_List:
  DW SetColorIndex, $00E8
Tor_4Esc<n>_List_Loop:
  DW $0002
    DW !Tor_4Esc<n>_Colors_0a, !Tor_4Esc<n>_Colors_0b
    DW SkipColors_4
    DW !Tor_4Esc<n>_Colors_0c
    DW GlowYeild
  DW $0002
    DW !Tor_4Esc<n>_Colors_1a, !Tor_4Esc<n>_Colors_1b
    DW SkipColors_4
    DW !Tor_4Esc<n>_Colors_1c
    DW GlowYeild
  DW $0002
    DW !Tor_4Esc<n>_Colors_2a, !Tor_4Esc<n>_Colors_2b
    DW SkipColors_4
    DW !Tor_4Esc<n>_Colors_2c
    DW GlowYeild
  DW $0002
    DW !Tor_4Esc<n>_Colors_3a, !Tor_4Esc<n>_Colors_1b
    DW SkipColors_4
    DW !Tor_4Esc<n>_Colors_3c
    DW GlowYeild
  DW $0002
    DW !Tor_4Esc<n>_Colors_4a, !Tor_4Esc<n>_Colors_0b
    DW SkipColors_4
    DW !Tor_4Esc<n>_Colors_4c
    DW GlowYeild
  DW $0002
    DW !Tor_4Esc<n>_Colors_5a, !Tor_4Esc<n>_Colors_1b
    DW SkipColors_4
    DW !Tor_4Esc<n>_Colors_5c
    DW GlowYeild
  DW $0002
    DW !Tor_4Esc<n>_Colors_6a, !Tor_4Esc<n>_Colors_2b
    DW SkipColors_4
    DW !Tor_4Esc<n>_Colors_6c
    DW GlowYeild
  DW $0002
    DW !Tor_4Esc<n>_Colors_7a, !Tor_4Esc<n>_Colors_1b
    DW SkipColors_4
    DW !Tor_4Esc<n>_Colors_7c
    DW GlowYeild
  DW $0002
    DW !Tor_4Esc<n>_Colors_6a, !Tor_4Esc<n>_Colors_2b
    DW SkipColors_4
    DW !Tor_4Esc<n>_Colors_6c
    DW GlowYeild
  DW $0002
    DW !Tor_4Esc<n>_Colors_5a, !Tor_4Esc<n>_Colors_1b
    DW SkipColors_4
    DW !Tor_4Esc<n>_Colors_5c
    DW GlowYeild
  DW $0002
    DW !Tor_4Esc<n>_Colors_4a, !Tor_4Esc<n>_Colors_0b
    DW SkipColors_4
    DW !Tor_4Esc<n>_Colors_4c
    DW GlowYeild
  DW $0002
    DW !Tor_4Esc<n>_Colors_3a, !Tor_4Esc<n>_Colors_1b
    DW SkipColors_4
    DW !Tor_4Esc<n>_Colors_3c
    DW GlowYeild
  DW $0002
    DW !Tor_4Esc<n>_Colors_2a, !Tor_4Esc<n>_Colors_2b
    DW SkipColors_4
    DW !Tor_4Esc<n>_Colors_2c
    DW GlowYeild
  DW $0002
    DW !Tor_4Esc<n>_Colors_1a, !Tor_4Esc<n>_Colors_1b
    DW SkipColors_4
    DW !Tor_4Esc<n>_Colors_1c
    DW GlowYeild
  DW GlowJMP, Tor_4Esc<n>_List_Loop
endmacro

%Tor_4Esc_List(0)
%Tor_4Esc_List(1)
%Tor_4Esc_List(2)
%Tor_4Esc_List(3)
%Tor_4Esc_List(4)
%Tor_4Esc_List(5)
%Tor_4Esc_List(6)
%Tor_4Esc_List(7)
print pc

org $8DF765
SkyFlash:
  DW $00BB, SkyFlashTable
org $8DF76D
WS_Green:
  DW $00BB, WS_GreenTable
org $8DF775
Blue_BG_:
  DW $00BB, Blue_BG_Table
SpoSpoBG:
  DW $00BB, SpoSpoBGTable
Purp_BG_:
  DW $00BB, Purp_BG_Table
Beacon__:
  DW $00BB, Beacon__Table
NorHot1_:
  DW $00BB, NorHot1_Table
NorHot2_:
  DW $00BB, NorHot2_Table
NorHot3_:
  DW $00BB, NorHot3_Table
NorHot4_:
  DW $00BB, NorHot4_Table
org $8DF79D
Waterfal:
  DW $00BB, WaterfalTable
Tourian_:
  DW $00BB, Tourian_Table
org $8DFFCD
Tor_2Esc:
  DW $00BB, Tor_2EscTable
Tor_3Esc:
  DW $00BB, Tor_3EscTable
Tor_4Esc:
  DW $00BB, Tor_4EscTable
OldT1Esc:
  DW $00BB, OldT1EscTable
OldT2Esc:
  DW $00BB, OldT2EscTable
OldT3Esc:
  DW $00BB, OldT3EscTable
SurfcEsc:
  DW $00BB, SurfcEscTable
Sky_Esc_:
  DW $00BB, Sky_Esc_Table
