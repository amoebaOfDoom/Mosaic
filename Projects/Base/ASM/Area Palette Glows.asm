lorom

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

org $8DC4FF ; Patch main glow object constructor to support polymorphic glow headers
  TYA
  STA $1E7D,X
  STZ $1E8D,X
  LDA #$0001
  STA $1ECD,X
  STZ $1EDD,X

  LDA $0000,Y
  BMI +
  JMP.l SpawnGlow_V2
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

org $8DF7A9 ; overwrite moved glow
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

org $BB8000
SpawnGlow_V2:
  CMP #$00BB ; assert tag
  BEQ +
  JSL $808573 ; crash
  +
  STA $1E7D,X

  LDA.w #EmptyPre
  STA $1EAD,X ; pre-instruction

  LDA $1F5B ; map area
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
SkyFlash0_List:
  DW SetLinkTarget, SkyFlash0_List_Loop1
  DW SetPreInstruction, ResetLightning
  DW SetColorIndex, $00A8
SkyFlash0_List_Loop1:
  DW $00F0
    DW $2D6C, $294B, $252A, $2109, $1CE8, $18C7, $14A6, $1085
    DW GlowYeild
  DW SetLoopCounter : DB $02
SkyFlash0_List_Loop2:
  DW $0002
    DW $4632, $4211, $3DF0, $39CF, $35AE, $318D, $2D6C, $294B
    DW GlowYeild
  DW $0001
    DW $5EF8, $5AD7, $56B6, $5295, $4E74, $4A53, $4632, $4211
    DW GlowYeild
  DW $0001
    DW $77BE, $739D, $6F7C, $6B5B, $673A, $6319, $5EF8, $5AD7
    DW GlowYeild
  DW $0001
    DW $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF
    DW GlowYeild
  DW $0001
    DW $77BE, $739D, $6F7C, $6B5B, $673A, $6319, $5EF8, $5AD7
    DW GlowYeild
  DW $0001
    DW $5EF8, $5AD7, $56B6, $5295, $4E74, $4A53, $4632, $4211
    DW GlowYeild
  DW $0002
    DW $4632, $4211, $3DF0, $39CF, $35AE, $318D, $2D6C, $294B
    DW GlowYeild
  DW DecAndLoop, SkyFlash0_List_Loop2
  DW $00F0
    DW $2D6C, $294B, $252A, $2109, $1CE8, $18C7, $14A6, $1085
    DW GlowYeild
  DW SetLoopCounter : DB $01
SkyFlash0_List_Loop3:
  DW $0001
    DW $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF
    DW GlowYeild
  DW $0001
    DW $77BE, $739D, $6F7C, $6B5B, $673A, $6319, $5EF8, $5AD7
    DW GlowYeild
  DW $0001
    DW $5EF8, $5AD7, $56B6, $5295, $4E74, $4A53, $4632, $4211
    DW GlowYeild
  DW $0002
    DW $4632, $4211, $3DF0, $39CF, $35AE, $318D, $2D6C, $294B
    DW GlowYeild
  DW DecAndLoop, SkyFlash0_List_Loop3
  DW GlowJMP, SkyFlash0_List_Loop1

SkyFlash1_List:
  DW SetLinkTarget, SkyFlash1_List_Loop1
  DW SetPreInstruction, ResetLightning
  DW SetColorIndex, $00A8
SkyFlash1_List_Loop1:
  DW $00F0
    DW $2D6C, $294B, $252A, $2109, $1CE8, $18C7, $14A6, $1085
    DW GlowYeild
  DW SetLoopCounter : DB $02
SkyFlash1_List_Loop2:
  DW $0002
    DW $4632, $4211, $3DF0, $39CF, $35AE, $318D, $2D6C, $294B
    DW GlowYeild
  DW $0001
    DW $5EF8, $5AD7, $56B6, $5295, $4E74, $4A53, $4632, $4211
    DW GlowYeild
  DW $0001
    DW $77BE, $739D, $6F7C, $6B5B, $673A, $6319, $5EF8, $5AD7
    DW GlowYeild
  DW $0001
    DW $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF
    DW GlowYeild
  DW $0001
    DW $77BE, $739D, $6F7C, $6B5B, $673A, $6319, $5EF8, $5AD7
    DW GlowYeild
  DW $0001
    DW $5EF8, $5AD7, $56B6, $5295, $4E74, $4A53, $4632, $4211
    DW GlowYeild
  DW $0002
    DW $4632, $4211, $3DF0, $39CF, $35AE, $318D, $2D6C, $294B
    DW GlowYeild
  DW DecAndLoop, SkyFlash1_List_Loop2
  DW $00F0
    DW $2D6C, $294B, $252A, $2109, $1CE8, $18C7, $14A6, $1085
    DW GlowYeild
  DW SetLoopCounter : DB $01
SkyFlash1_List_Loop3:
  DW $0001
    DW $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF
    DW GlowYeild
  DW $0001
    DW $77BE, $739D, $6F7C, $6B5B, $673A, $6319, $5EF8, $5AD7
    DW GlowYeild
  DW $0001
    DW $5EF8, $5AD7, $56B6, $5295, $4E74, $4A53, $4632, $4211
    DW GlowYeild
  DW $0002
    DW $4632, $4211, $3DF0, $39CF, $35AE, $318D, $2D6C, $294B
    DW GlowYeild
  DW DecAndLoop, SkyFlash1_List_Loop3
  DW GlowJMP, SkyFlash1_List_Loop1

SkyFlash2_List:
  DW SetLinkTarget, SkyFlash2_List_Loop1
  DW SetPreInstruction, ResetLightning
  DW SetColorIndex, $00A8
SkyFlash2_List_Loop1:
  DW $00F0
    DW $2D6C, $294B, $252A, $2109, $1CE8, $18C7, $14A6, $1085
    DW GlowYeild
  DW SetLoopCounter : DB $02
SkyFlash2_List_Loop2:
  DW $0002
    DW $4632, $4211, $3DF0, $39CF, $35AE, $318D, $2D6C, $294B
    DW GlowYeild
  DW $0001
    DW $5EF8, $5AD7, $56B6, $5295, $4E74, $4A53, $4632, $4211
    DW GlowYeild
  DW $0001
    DW $77BE, $739D, $6F7C, $6B5B, $673A, $6319, $5EF8, $5AD7
    DW GlowYeild
  DW $0001
    DW $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF
    DW GlowYeild
  DW $0001
    DW $77BE, $739D, $6F7C, $6B5B, $673A, $6319, $5EF8, $5AD7
    DW GlowYeild
  DW $0001
    DW $5EF8, $5AD7, $56B6, $5295, $4E74, $4A53, $4632, $4211
    DW GlowYeild
  DW $0002
    DW $4632, $4211, $3DF0, $39CF, $35AE, $318D, $2D6C, $294B
    DW GlowYeild
  DW DecAndLoop, SkyFlash2_List_Loop2
  DW $00F0
    DW $2D6C, $294B, $252A, $2109, $1CE8, $18C7, $14A6, $1085
    DW GlowYeild
  DW SetLoopCounter : DB $01
SkyFlash2_List_Loop3:
  DW $0001
    DW $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF
    DW GlowYeild
  DW $0001
    DW $77BE, $739D, $6F7C, $6B5B, $673A, $6319, $5EF8, $5AD7
    DW GlowYeild
  DW $0001
    DW $5EF8, $5AD7, $56B6, $5295, $4E74, $4A53, $4632, $4211
    DW GlowYeild
  DW $0002
    DW $4632, $4211, $3DF0, $39CF, $35AE, $318D, $2D6C, $294B
    DW GlowYeild
  DW DecAndLoop, SkyFlash2_List_Loop3
  DW GlowJMP, SkyFlash2_List_Loop1

SkyFlash3_List:
  DW SetLinkTarget, SkyFlash3_List_Loop1
  DW SetPreInstruction, ResetLightning
  DW SetColorIndex, $00A8
SkyFlash3_List_Loop1:
  DW $00F0
    DW $2D6C, $294B, $252A, $2109, $1CE8, $18C7, $14A6, $1085
    DW GlowYeild
  DW SetLoopCounter : DB $02
SkyFlash3_List_Loop2:
  DW $0002
    DW $4632, $4211, $3DF0, $39CF, $35AE, $318D, $2D6C, $294B
    DW GlowYeild
  DW $0001
    DW $5EF8, $5AD7, $56B6, $5295, $4E74, $4A53, $4632, $4211
    DW GlowYeild
  DW $0001
    DW $77BE, $739D, $6F7C, $6B5B, $673A, $6319, $5EF8, $5AD7
    DW GlowYeild
  DW $0001
    DW $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF
    DW GlowYeild
  DW $0001
    DW $77BE, $739D, $6F7C, $6B5B, $673A, $6319, $5EF8, $5AD7
    DW GlowYeild
  DW $0001
    DW $5EF8, $5AD7, $56B6, $5295, $4E74, $4A53, $4632, $4211
    DW GlowYeild
  DW $0002
    DW $4632, $4211, $3DF0, $39CF, $35AE, $318D, $2D6C, $294B
    DW GlowYeild
  DW DecAndLoop, SkyFlash3_List_Loop2
  DW $00F0
    DW $2D6C, $294B, $252A, $2109, $1CE8, $18C7, $14A6, $1085
    DW GlowYeild
  DW SetLoopCounter : DB $01
SkyFlash3_List_Loop3:
  DW $0001
    DW $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF
    DW GlowYeild
  DW $0001
    DW $77BE, $739D, $6F7C, $6B5B, $673A, $6319, $5EF8, $5AD7
    DW GlowYeild
  DW $0001
    DW $5EF8, $5AD7, $56B6, $5295, $4E74, $4A53, $4632, $4211
    DW GlowYeild
  DW $0002
    DW $4632, $4211, $3DF0, $39CF, $35AE, $318D, $2D6C, $294B
    DW GlowYeild
  DW DecAndLoop, SkyFlash3_List_Loop3
  DW GlowJMP, SkyFlash3_List_Loop1

SkyFlash4_List:
  DW SetLinkTarget, SkyFlash4_List_Loop1
  DW SetPreInstruction, ResetLightning
  DW SetColorIndex, $00A8
SkyFlash4_List_Loop1:
  DW $00F0
    DW $2D6C, $294B, $252A, $2109, $1CE8, $18C7, $14A6, $1085
    DW GlowYeild
  DW SetLoopCounter : DB $02
SkyFlash4_List_Loop2:
  DW $0002
    DW $4632, $4211, $3DF0, $39CF, $35AE, $318D, $2D6C, $294B
    DW GlowYeild
  DW $0001
    DW $5EF8, $5AD7, $56B6, $5295, $4E74, $4A53, $4632, $4211
    DW GlowYeild
  DW $0001
    DW $77BE, $739D, $6F7C, $6B5B, $673A, $6319, $5EF8, $5AD7
    DW GlowYeild
  DW $0001
    DW $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF
    DW GlowYeild
  DW $0001
    DW $77BE, $739D, $6F7C, $6B5B, $673A, $6319, $5EF8, $5AD7
    DW GlowYeild
  DW $0001
    DW $5EF8, $5AD7, $56B6, $5295, $4E74, $4A53, $4632, $4211
    DW GlowYeild
  DW $0002
    DW $4632, $4211, $3DF0, $39CF, $35AE, $318D, $2D6C, $294B
    DW GlowYeild
  DW DecAndLoop, SkyFlash4_List_Loop2
  DW $00F0
    DW $2D6C, $294B, $252A, $2109, $1CE8, $18C7, $14A6, $1085
    DW GlowYeild
  DW SetLoopCounter : DB $01
SkyFlash4_List_Loop3:
  DW $0001
    DW $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF
    DW GlowYeild
  DW $0001
    DW $77BE, $739D, $6F7C, $6B5B, $673A, $6319, $5EF8, $5AD7
    DW GlowYeild
  DW $0001
    DW $5EF8, $5AD7, $56B6, $5295, $4E74, $4A53, $4632, $4211
    DW GlowYeild
  DW $0002
    DW $4632, $4211, $3DF0, $39CF, $35AE, $318D, $2D6C, $294B
    DW GlowYeild
  DW DecAndLoop, SkyFlash4_List_Loop3
  DW GlowJMP, SkyFlash4_List_Loop1

SkyFlash5_List:
  DW SetLinkTarget, SkyFlash5_List_Loop1
  DW SetPreInstruction, ResetLightning
  DW SetColorIndex, $00A8
SkyFlash5_List_Loop1:
  DW $00F0
    DW $2D6C, $294B, $252A, $2109, $1CE8, $18C7, $14A6, $1085
    DW GlowYeild
  DW SetLoopCounter : DB $02
SkyFlash5_List_Loop2:
  DW $0002
    DW $4632, $4211, $3DF0, $39CF, $35AE, $318D, $2D6C, $294B
    DW GlowYeild
  DW $0001
    DW $5EF8, $5AD7, $56B6, $5295, $4E74, $4A53, $4632, $4211
    DW GlowYeild
  DW $0001
    DW $77BE, $739D, $6F7C, $6B5B, $673A, $6319, $5EF8, $5AD7
    DW GlowYeild
  DW $0001
    DW $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF
    DW GlowYeild
  DW $0001
    DW $77BE, $739D, $6F7C, $6B5B, $673A, $6319, $5EF8, $5AD7
    DW GlowYeild
  DW $0001
    DW $5EF8, $5AD7, $56B6, $5295, $4E74, $4A53, $4632, $4211
    DW GlowYeild
  DW $0002
    DW $4632, $4211, $3DF0, $39CF, $35AE, $318D, $2D6C, $294B
    DW GlowYeild
  DW DecAndLoop, SkyFlash5_List_Loop2
  DW $00F0
    DW $2D6C, $294B, $252A, $2109, $1CE8, $18C7, $14A6, $1085
    DW GlowYeild
  DW SetLoopCounter : DB $01
SkyFlash5_List_Loop3:
  DW $0001
    DW $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF
    DW GlowYeild
  DW $0001
    DW $77BE, $739D, $6F7C, $6B5B, $673A, $6319, $5EF8, $5AD7
    DW GlowYeild
  DW $0001
    DW $5EF8, $5AD7, $56B6, $5295, $4E74, $4A53, $4632, $4211
    DW GlowYeild
  DW $0002
    DW $4632, $4211, $3DF0, $39CF, $35AE, $318D, $2D6C, $294B
    DW GlowYeild
  DW DecAndLoop, SkyFlash5_List_Loop3
  DW GlowJMP, SkyFlash5_List_Loop1

SkyFlash6_List:
  DW SetLinkTarget, SkyFlash6_List_Loop1
  DW SetPreInstruction, ResetLightning
  DW SetColorIndex, $00A8
SkyFlash6_List_Loop1:
  DW $00F0
    DW $2D6C, $294B, $252A, $2109, $1CE8, $18C7, $14A6, $1085
    DW GlowYeild
  DW SetLoopCounter : DB $02
SkyFlash6_List_Loop2:
  DW $0002
    DW $4632, $4211, $3DF0, $39CF, $35AE, $318D, $2D6C, $294B
    DW GlowYeild
  DW $0001
    DW $5EF8, $5AD7, $56B6, $5295, $4E74, $4A53, $4632, $4211
    DW GlowYeild
  DW $0001
    DW $77BE, $739D, $6F7C, $6B5B, $673A, $6319, $5EF8, $5AD7
    DW GlowYeild
  DW $0001
    DW $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF
    DW GlowYeild
  DW $0001
    DW $77BE, $739D, $6F7C, $6B5B, $673A, $6319, $5EF8, $5AD7
    DW GlowYeild
  DW $0001
    DW $5EF8, $5AD7, $56B6, $5295, $4E74, $4A53, $4632, $4211
    DW GlowYeild
  DW $0002
    DW $4632, $4211, $3DF0, $39CF, $35AE, $318D, $2D6C, $294B
    DW GlowYeild
  DW DecAndLoop, SkyFlash6_List_Loop2
  DW $00F0
    DW $2D6C, $294B, $252A, $2109, $1CE8, $18C7, $14A6, $1085
    DW GlowYeild
  DW SetLoopCounter : DB $01
SkyFlash6_List_Loop3:
  DW $0001
    DW $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF
    DW GlowYeild
  DW $0001
    DW $77BE, $739D, $6F7C, $6B5B, $673A, $6319, $5EF8, $5AD7
    DW GlowYeild
  DW $0001
    DW $5EF8, $5AD7, $56B6, $5295, $4E74, $4A53, $4632, $4211
    DW GlowYeild
  DW $0002
    DW $4632, $4211, $3DF0, $39CF, $35AE, $318D, $2D6C, $294B
    DW GlowYeild
  DW DecAndLoop, SkyFlash6_List_Loop3
  DW GlowJMP, SkyFlash6_List_Loop1

SkyFlash7_List:
  DW SetLinkTarget, SkyFlash7_List_Loop1
  DW SetPreInstruction, ResetLightning
  DW SetColorIndex, $00A8
SkyFlash7_List_Loop1:
  DW $00F0
    DW $2D6C, $294B, $252A, $2109, $1CE8, $18C7, $14A6, $1085
    DW GlowYeild
  DW SetLoopCounter : DB $02
SkyFlash7_List_Loop2:
  DW $0002
    DW $4632, $4211, $3DF0, $39CF, $35AE, $318D, $2D6C, $294B
    DW GlowYeild
  DW $0001
    DW $5EF8, $5AD7, $56B6, $5295, $4E74, $4A53, $4632, $4211
    DW GlowYeild
  DW $0001
    DW $77BE, $739D, $6F7C, $6B5B, $673A, $6319, $5EF8, $5AD7
    DW GlowYeild
  DW $0001
    DW $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF
    DW GlowYeild
  DW $0001
    DW $77BE, $739D, $6F7C, $6B5B, $673A, $6319, $5EF8, $5AD7
    DW GlowYeild
  DW $0001
    DW $5EF8, $5AD7, $56B6, $5295, $4E74, $4A53, $4632, $4211
    DW GlowYeild
  DW $0002
    DW $4632, $4211, $3DF0, $39CF, $35AE, $318D, $2D6C, $294B
    DW GlowYeild
  DW DecAndLoop, SkyFlash7_List_Loop2
  DW $00F0
    DW $2D6C, $294B, $252A, $2109, $1CE8, $18C7, $14A6, $1085
    DW GlowYeild
  DW SetLoopCounter : DB $01
SkyFlash7_List_Loop3:
  DW $0001
    DW $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF, $7FFF
    DW GlowYeild
  DW $0001
    DW $77BE, $739D, $6F7C, $6B5B, $673A, $6319, $5EF8, $5AD7
    DW GlowYeild
  DW $0001
    DW $5EF8, $5AD7, $56B6, $5295, $4E74, $4A53, $4632, $4211
    DW GlowYeild
  DW $0002
    DW $4632, $4211, $3DF0, $39CF, $35AE, $318D, $2D6C, $294B
    DW GlowYeild
  DW DecAndLoop, SkyFlash7_List_Loop3
  DW GlowJMP, SkyFlash7_List_Loop1

SurfcEscTable:
  DW EmptyInit,SurfcEsc0_List, EmptyInit,SurfcEsc1_List, EmptyInit,SurfcEsc2_List, EmptyInit,SurfcEsc3_List
  DW EmptyInit,SurfcEsc4_List, EmptyInit,SurfcEsc5_List, EmptyInit,SurfcEsc6_List, EmptyInit,SurfcEsc7_List
SurfcEsc0_List:
SurfcEsc7_List:
  DW SetColorIndex, $0082
SurfaceEsc0_List_Loop:
  DW $0008
    DW $1D89, $0D06, $0CA3, $2D0E, $2D09, $28C5, $0C81
    DW GlowYeild
  DW $0007
    DW $1D8A, $0D07, $0CA4, $2D0E, $2D09, $28C5, $0421
    DW GlowYeild
  DW $0006
    DW $1D8A, $0D28, $0CC4, $2D0F, $2D0A, $28C6, $0423
    DW GlowYeild
  DW $0005
    DW $1D8B, $0D29, $0CC5, $2D0F, $2D0A, $28C6, $0424
    DW GlowYeild
  DW $0004
    DW $1DAB, $1149, $10C5, $2D0F, $2D0B, $28C7, $0845
    DW GlowYeild
  DW $0003
    DW $1DAC, $114A, $10C6, $2D0F, $2D0B, $28C7, $0846
    DW GlowYeild
  DW $0002
    DW $1DAC, $116B, $10E6, $2D10, $2D0C, $28C8, $0848
    DW GlowYeild
  DW $0001
    DW $1DAD, $116C, $10E7, $2D10, $2D0C, $28C8, $0015
    DW GlowYeild
  DW $0002
    DW $1DAC, $116B, $10E6, $2D10, $2D0C, $28C8, $0848
    DW GlowYeild
  DW $0003
    DW $1DAC, $114A, $10C6, $2D0F, $2D0B, $28C7, $0846
    DW GlowYeild
  DW $0004
    DW $1DAB, $1149, $10C5, $2D0F, $2D0B, $28C7, $0845
    DW GlowYeild
  DW $0005
    DW $1D8B, $0D29, $0CC5, $2D0F, $2D0A, $28C6, $0424
    DW GlowYeild
  DW $0006
    DW $1D8A, $0D28, $0CC4, $2D0F, $2D0A, $28C6, $0423
    DW GlowYeild
  DW $0007
    DW $1D8A, $0D07, $0CA4, $2D0E, $2D09, $28C5, $0421
    DW GlowYeild
  DW GlowJMP, SurfaceEsc0_List_Loop

SurfcEsc1_List:
  DW SetColorIndex, $0082
SurfaceEsc1_List_Loop:
  DW $0008
    DW $1D89, $0D06, $0CA3, $2D0E, $2D09, $28C5, $0C81
    DW GlowYeild
  DW $0007
    DW $1D8A, $0D07, $0CA4, $2D0E, $2D09, $28C5, $0421
    DW GlowYeild
  DW $0006
    DW $1D8A, $0D28, $0CC4, $2D0F, $2D0A, $28C6, $0423
    DW GlowYeild
  DW $0005
    DW $1D8B, $0D29, $0CC5, $2D0F, $2D0A, $28C6, $0424
    DW GlowYeild
  DW $0004
    DW $1DAB, $1149, $10C5, $2D0F, $2D0B, $28C7, $0845
    DW GlowYeild
  DW $0003
    DW $1DAC, $114A, $10C6, $2D0F, $2D0B, $28C7, $0846
    DW GlowYeild
  DW $0002
    DW $1DAC, $116B, $10E6, $2D10, $2D0C, $28C8, $0848
    DW GlowYeild
  DW $0001
    DW $1DAD, $116C, $10E7, $2D10, $2D0C, $28C8, $0015
    DW GlowYeild
  DW $0002
    DW $1DAC, $116B, $10E6, $2D10, $2D0C, $28C8, $0848
    DW GlowYeild
  DW $0003
    DW $1DAC, $114A, $10C6, $2D0F, $2D0B, $28C7, $0846
    DW GlowYeild
  DW $0004
    DW $1DAB, $1149, $10C5, $2D0F, $2D0B, $28C7, $0845
    DW GlowYeild
  DW $0005
    DW $1D8B, $0D29, $0CC5, $2D0F, $2D0A, $28C6, $0424
    DW GlowYeild
  DW $0006
    DW $1D8A, $0D28, $0CC4, $2D0F, $2D0A, $28C6, $0423
    DW GlowYeild
  DW $0007
    DW $1D8A, $0D07, $0CA4, $2D0E, $2D09, $28C5, $0421
    DW GlowYeild
  DW GlowJMP, SurfaceEsc1_List_Loop

SurfcEsc2_List:
  DW SetColorIndex, $0082
SurfaceEsc2_List_Loop:
  DW $0008
    DW $1D89, $0D06, $0CA3, $2D0E, $2D09, $28C5, $0C81
    DW GlowYeild
  DW $0007
    DW $1D8A, $0D07, $0CA4, $2D0E, $2D09, $28C5, $0421
    DW GlowYeild
  DW $0006
    DW $1D8A, $0D28, $0CC4, $2D0F, $2D0A, $28C6, $0423
    DW GlowYeild
  DW $0005
    DW $1D8B, $0D29, $0CC5, $2D0F, $2D0A, $28C6, $0424
    DW GlowYeild
  DW $0004
    DW $1DAB, $1149, $10C5, $2D0F, $2D0B, $28C7, $0845
    DW GlowYeild
  DW $0003
    DW $1DAC, $114A, $10C6, $2D0F, $2D0B, $28C7, $0846
    DW GlowYeild
  DW $0002
    DW $1DAC, $116B, $10E6, $2D10, $2D0C, $28C8, $0848
    DW GlowYeild
  DW $0001
    DW $1DAD, $116C, $10E7, $2D10, $2D0C, $28C8, $0015
    DW GlowYeild
  DW $0002
    DW $1DAC, $116B, $10E6, $2D10, $2D0C, $28C8, $0848
    DW GlowYeild
  DW $0003
    DW $1DAC, $114A, $10C6, $2D0F, $2D0B, $28C7, $0846
    DW GlowYeild
  DW $0004
    DW $1DAB, $1149, $10C5, $2D0F, $2D0B, $28C7, $0845
    DW GlowYeild
  DW $0005
    DW $1D8B, $0D29, $0CC5, $2D0F, $2D0A, $28C6, $0424
    DW GlowYeild
  DW $0006
    DW $1D8A, $0D28, $0CC4, $2D0F, $2D0A, $28C6, $0423
    DW GlowYeild
  DW $0007
    DW $1D8A, $0D07, $0CA4, $2D0E, $2D09, $28C5, $0421
    DW GlowYeild
  DW GlowJMP, SurfaceEsc2_List_Loop

SurfcEsc3_List:
  DW SetColorIndex, $0082
SurfaceEsc3_List_Loop:
  DW $0008
    DW $1D89, $0D06, $0CA3, $2D0E, $2D09, $28C5, $0C81
    DW GlowYeild
  DW $0007
    DW $1D8A, $0D07, $0CA4, $2D0E, $2D09, $28C5, $0421
    DW GlowYeild
  DW $0006
    DW $1D8A, $0D28, $0CC4, $2D0F, $2D0A, $28C6, $0423
    DW GlowYeild
  DW $0005
    DW $1D8B, $0D29, $0CC5, $2D0F, $2D0A, $28C6, $0424
    DW GlowYeild
  DW $0004
    DW $1DAB, $1149, $10C5, $2D0F, $2D0B, $28C7, $0845
    DW GlowYeild
  DW $0003
    DW $1DAC, $114A, $10C6, $2D0F, $2D0B, $28C7, $0846
    DW GlowYeild
  DW $0002
    DW $1DAC, $116B, $10E6, $2D10, $2D0C, $28C8, $0848
    DW GlowYeild
  DW $0001
    DW $1DAD, $116C, $10E7, $2D10, $2D0C, $28C8, $0015
    DW GlowYeild
  DW $0002
    DW $1DAC, $116B, $10E6, $2D10, $2D0C, $28C8, $0848
    DW GlowYeild
  DW $0003
    DW $1DAC, $114A, $10C6, $2D0F, $2D0B, $28C7, $0846
    DW GlowYeild
  DW $0004
    DW $1DAB, $1149, $10C5, $2D0F, $2D0B, $28C7, $0845
    DW GlowYeild
  DW $0005
    DW $1D8B, $0D29, $0CC5, $2D0F, $2D0A, $28C6, $0424
    DW GlowYeild
  DW $0006
    DW $1D8A, $0D28, $0CC4, $2D0F, $2D0A, $28C6, $0423
    DW GlowYeild
  DW $0007
    DW $1D8A, $0D07, $0CA4, $2D0E, $2D09, $28C5, $0421
    DW GlowYeild
  DW GlowJMP, SurfaceEsc3_List_Loop

SurfcEsc4_List:
  DW SetColorIndex, $0082
SurfaceEsc4_List_Loop:
  DW $0008
    DW $1D89, $0D06, $0CA3, $2D0E, $2D09, $28C5, $0C81
    DW GlowYeild
  DW $0007
    DW $1D8A, $0D07, $0CA4, $2D0E, $2D09, $28C5, $0421
    DW GlowYeild
  DW $0006
    DW $1D8A, $0D28, $0CC4, $2D0F, $2D0A, $28C6, $0423
    DW GlowYeild
  DW $0005
    DW $1D8B, $0D29, $0CC5, $2D0F, $2D0A, $28C6, $0424
    DW GlowYeild
  DW $0004
    DW $1DAB, $1149, $10C5, $2D0F, $2D0B, $28C7, $0845
    DW GlowYeild
  DW $0003
    DW $1DAC, $114A, $10C6, $2D0F, $2D0B, $28C7, $0846
    DW GlowYeild
  DW $0002
    DW $1DAC, $116B, $10E6, $2D10, $2D0C, $28C8, $0848
    DW GlowYeild
  DW $0001
    DW $1DAD, $116C, $10E7, $2D10, $2D0C, $28C8, $0015
    DW GlowYeild
  DW $0002
    DW $1DAC, $116B, $10E6, $2D10, $2D0C, $28C8, $0848
    DW GlowYeild
  DW $0003
    DW $1DAC, $114A, $10C6, $2D0F, $2D0B, $28C7, $0846
    DW GlowYeild
  DW $0004
    DW $1DAB, $1149, $10C5, $2D0F, $2D0B, $28C7, $0845
    DW GlowYeild
  DW $0005
    DW $1D8B, $0D29, $0CC5, $2D0F, $2D0A, $28C6, $0424
    DW GlowYeild
  DW $0006
    DW $1D8A, $0D28, $0CC4, $2D0F, $2D0A, $28C6, $0423
    DW GlowYeild
  DW $0007
    DW $1D8A, $0D07, $0CA4, $2D0E, $2D09, $28C5, $0421
    DW GlowYeild
  DW GlowJMP, SurfaceEsc4_List_Loop

SurfcEsc5_List:
  DW SetColorIndex, $0082
SurfaceEsc5_List_Loop:
  DW $0008
    DW $1D89, $0D06, $0CA3, $2D0E, $2D09, $28C5, $0C81
    DW GlowYeild
  DW $0007
    DW $1D8A, $0D07, $0CA4, $2D0E, $2D09, $28C5, $0421
    DW GlowYeild
  DW $0006
    DW $1D8A, $0D28, $0CC4, $2D0F, $2D0A, $28C6, $0423
    DW GlowYeild
  DW $0005
    DW $1D8B, $0D29, $0CC5, $2D0F, $2D0A, $28C6, $0424
    DW GlowYeild
  DW $0004
    DW $1DAB, $1149, $10C5, $2D0F, $2D0B, $28C7, $0845
    DW GlowYeild
  DW $0003
    DW $1DAC, $114A, $10C6, $2D0F, $2D0B, $28C7, $0846
    DW GlowYeild
  DW $0002
    DW $1DAC, $116B, $10E6, $2D10, $2D0C, $28C8, $0848
    DW GlowYeild
  DW $0001
    DW $1DAD, $116C, $10E7, $2D10, $2D0C, $28C8, $0015
    DW GlowYeild
  DW $0002
    DW $1DAC, $116B, $10E6, $2D10, $2D0C, $28C8, $0848
    DW GlowYeild
  DW $0003
    DW $1DAC, $114A, $10C6, $2D0F, $2D0B, $28C7, $0846
    DW GlowYeild
  DW $0004
    DW $1DAB, $1149, $10C5, $2D0F, $2D0B, $28C7, $0845
    DW GlowYeild
  DW $0005
    DW $1D8B, $0D29, $0CC5, $2D0F, $2D0A, $28C6, $0424
    DW GlowYeild
  DW $0006
    DW $1D8A, $0D28, $0CC4, $2D0F, $2D0A, $28C6, $0423
    DW GlowYeild
  DW $0007
    DW $1D8A, $0D07, $0CA4, $2D0E, $2D09, $28C5, $0421
    DW GlowYeild
  DW GlowJMP, SurfaceEsc5_List_Loop

SurfcEsc6_List:
  DW SetColorIndex, $0082
SurfaceEsc6_List_Loop:
  DW $0008
    DW $1D89, $0D06, $0CA3, $2D0E, $2D09, $28C5, $0C81
    DW GlowYeild
  DW $0007
    DW $1D8A, $0D07, $0CA4, $2D0E, $2D09, $28C5, $0421
    DW GlowYeild
  DW $0006
    DW $1D8A, $0D28, $0CC4, $2D0F, $2D0A, $28C6, $0423
    DW GlowYeild
  DW $0005
    DW $1D8B, $0D29, $0CC5, $2D0F, $2D0A, $28C6, $0424
    DW GlowYeild
  DW $0004
    DW $1DAB, $1149, $10C5, $2D0F, $2D0B, $28C7, $0845
    DW GlowYeild
  DW $0003
    DW $1DAC, $114A, $10C6, $2D0F, $2D0B, $28C7, $0846
    DW GlowYeild
  DW $0002
    DW $1DAC, $116B, $10E6, $2D10, $2D0C, $28C8, $0848
    DW GlowYeild
  DW $0001
    DW $1DAD, $116C, $10E7, $2D10, $2D0C, $28C8, $0015
    DW GlowYeild
  DW $0002
    DW $1DAC, $116B, $10E6, $2D10, $2D0C, $28C8, $0848
    DW GlowYeild
  DW $0003
    DW $1DAC, $114A, $10C6, $2D0F, $2D0B, $28C7, $0846
    DW GlowYeild
  DW $0004
    DW $1DAB, $1149, $10C5, $2D0F, $2D0B, $28C7, $0845
    DW GlowYeild
  DW $0005
    DW $1D8B, $0D29, $0CC5, $2D0F, $2D0A, $28C6, $0424
    DW GlowYeild
  DW $0006
    DW $1D8A, $0D28, $0CC4, $2D0F, $2D0A, $28C6, $0423
    DW GlowYeild
  DW $0007
    DW $1D8A, $0D07, $0CA4, $2D0E, $2D09, $28C5, $0421
    DW GlowYeild
  DW GlowJMP, SurfaceEsc6_List_Loop

Sky_Esc_Table:
  DW EmptyInit,Sky_Esc_0_List, EmptyInit,Sky_Esc_1_List, EmptyInit,Sky_Esc_2_List, EmptyInit,Sky_Esc_3_List
  DW EmptyInit,Sky_Esc_4_List, EmptyInit,Sky_Esc_5_List, EmptyInit,Sky_Esc_6_List, EmptyInit,Sky_Esc_7_List
Sky_Esc_0_List:
Sky_Esc_7_List:
  DW SetColorIndex, $00A2
Sky_Esc_0_List_Loop:
  DW $0031
    DW $48D5, $38B0, $286A, $2488, $2067, $1846, $1425, $1024, $0C23, $0C03, $0802
    DW GlowYeild
  DW $0001
    DW $3DD8, $31D5, $2991, $25B0, $218F, $1D8E, $0C23, $0C23, $0822, $0802, $0401
    DW GlowYeild
  DW $0001
    DW $32FC, $2EDA, $26D8, $26D7, $26D7, $22B7, $0802, $0401, $0401, $0401, $0401
    DW GlowYeild
  DW $0001
    DW $27FF, $27FF, $27FF, $27FF, $27FF, $27FF, $0000, $0000, $0401, $0000, $0000
    DW GlowYeild
  DW $0001
    DW $32FC, $2EDA, $26D8, $26D7, $26D7, $22B7, $0802, $0401, $0401, $0401, $0401
    DW GlowYeild
  DW $0011
    DW $48D5, $38B0, $286A, $2488, $2067, $1846, $1425, $1024, $0C23, $0C03, $0802
    DW GlowYeild
  DW $0001
    DW $32FC, $2EDA, $26D8, $26D7, $26D7, $22B7, $0802, $0401, $0401, $0401, $0401
    DW GlowYeild
  DW $0018
    DW $48D5, $38B0, $286A, $2488, $2067, $1846, $1425, $1024, $0C23, $0C03, $0802
    DW GlowYeild
  DW $0001
    DW $32FC, $2EDA, $26D8, $26D7, $26D7, $22B7, $0802, $0401, $0401, $0401, $0401
    DW GlowYeild
  DW $0001
    DW $27FF, $27FF, $27FF, $27FF, $27FF, $27FF, $0000, $0000, $0401, $0000, $0000
    DW GlowYeild
  DW $0001
    DW $32FC, $2EDA, $26D8, $26D7, $26D7, $22B7, $0802, $0401, $0401, $0401, $0401
    DW GlowYeild
  DW GlowJMP, Sky_Esc_0_List_Loop

Sky_Esc_1_List:
  DW SetColorIndex, $00A2
Sky_Esc_1_List_Loop:
  DW $0031
    DW $48D5, $38B0, $286A, $2488, $2067, $1846, $1425, $1024, $0C23, $0C03, $0802
    DW GlowYeild
  DW $0001
    DW $3DD8, $31D5, $2991, $25B0, $218F, $1D8E, $0C23, $0C23, $0822, $0802, $0401
    DW GlowYeild
  DW $0001
    DW $32FC, $2EDA, $26D8, $26D7, $26D7, $22B7, $0802, $0401, $0401, $0401, $0401
    DW GlowYeild
  DW $0001
    DW $27FF, $27FF, $27FF, $27FF, $27FF, $27FF, $0000, $0000, $0401, $0000, $0000
    DW GlowYeild
  DW $0001
    DW $32FC, $2EDA, $26D8, $26D7, $26D7, $22B7, $0802, $0401, $0401, $0401, $0401
    DW GlowYeild
  DW $0011
    DW $48D5, $38B0, $286A, $2488, $2067, $1846, $1425, $1024, $0C23, $0C03, $0802
    DW GlowYeild
  DW $0001
    DW $32FC, $2EDA, $26D8, $26D7, $26D7, $22B7, $0802, $0401, $0401, $0401, $0401
    DW GlowYeild
  DW $0018
    DW $48D5, $38B0, $286A, $2488, $2067, $1846, $1425, $1024, $0C23, $0C03, $0802
    DW GlowYeild
  DW $0001
    DW $32FC, $2EDA, $26D8, $26D7, $26D7, $22B7, $0802, $0401, $0401, $0401, $0401
    DW GlowYeild
  DW $0001
    DW $27FF, $27FF, $27FF, $27FF, $27FF, $27FF, $0000, $0000, $0401, $0000, $0000
    DW GlowYeild
  DW $0001
    DW $32FC, $2EDA, $26D8, $26D7, $26D7, $22B7, $0802, $0401, $0401, $0401, $0401
    DW GlowYeild
  DW GlowJMP, Sky_Esc_1_List_Loop

Sky_Esc_2_List:
  DW SetColorIndex, $00A2
Sky_Esc_2_List_Loop:
  DW $0031
    DW $48D5, $38B0, $286A, $2488, $2067, $1846, $1425, $1024, $0C23, $0C03, $0802
    DW GlowYeild
  DW $0001
    DW $3DD8, $31D5, $2991, $25B0, $218F, $1D8E, $0C23, $0C23, $0822, $0802, $0401
    DW GlowYeild
  DW $0001
    DW $32FC, $2EDA, $26D8, $26D7, $26D7, $22B7, $0802, $0401, $0401, $0401, $0401
    DW GlowYeild
  DW $0001
    DW $27FF, $27FF, $27FF, $27FF, $27FF, $27FF, $0000, $0000, $0401, $0000, $0000
    DW GlowYeild
  DW $0001
    DW $32FC, $2EDA, $26D8, $26D7, $26D7, $22B7, $0802, $0401, $0401, $0401, $0401
    DW GlowYeild
  DW $0011
    DW $48D5, $38B0, $286A, $2488, $2067, $1846, $1425, $1024, $0C23, $0C03, $0802
    DW GlowYeild
  DW $0001
    DW $32FC, $2EDA, $26D8, $26D7, $26D7, $22B7, $0802, $0401, $0401, $0401, $0401
    DW GlowYeild
  DW $0018
    DW $48D5, $38B0, $286A, $2488, $2067, $1846, $1425, $1024, $0C23, $0C03, $0802
    DW GlowYeild
  DW $0001
    DW $32FC, $2EDA, $26D8, $26D7, $26D7, $22B7, $0802, $0401, $0401, $0401, $0401
    DW GlowYeild
  DW $0001
    DW $27FF, $27FF, $27FF, $27FF, $27FF, $27FF, $0000, $0000, $0401, $0000, $0000
    DW GlowYeild
  DW $0001
    DW $32FC, $2EDA, $26D8, $26D7, $26D7, $22B7, $0802, $0401, $0401, $0401, $0401
    DW GlowYeild
  DW GlowJMP, Sky_Esc_2_List_Loop

Sky_Esc_3_List:
  DW SetColorIndex, $00A2
Sky_Esc_3_List_Loop:
  DW $0031
    DW $48D5, $38B0, $286A, $2488, $2067, $1846, $1425, $1024, $0C23, $0C03, $0802
    DW GlowYeild
  DW $0001
    DW $3DD8, $31D5, $2991, $25B0, $218F, $1D8E, $0C23, $0C23, $0822, $0802, $0401
    DW GlowYeild
  DW $0001
    DW $32FC, $2EDA, $26D8, $26D7, $26D7, $22B7, $0802, $0401, $0401, $0401, $0401
    DW GlowYeild
  DW $0001
    DW $27FF, $27FF, $27FF, $27FF, $27FF, $27FF, $0000, $0000, $0401, $0000, $0000
    DW GlowYeild
  DW $0001
    DW $32FC, $2EDA, $26D8, $26D7, $26D7, $22B7, $0802, $0401, $0401, $0401, $0401
    DW GlowYeild
  DW $0011
    DW $48D5, $38B0, $286A, $2488, $2067, $1846, $1425, $1024, $0C23, $0C03, $0802
    DW GlowYeild
  DW $0001
    DW $32FC, $2EDA, $26D8, $26D7, $26D7, $22B7, $0802, $0401, $0401, $0401, $0401
    DW GlowYeild
  DW $0018
    DW $48D5, $38B0, $286A, $2488, $2067, $1846, $1425, $1024, $0C23, $0C03, $0802
    DW GlowYeild
  DW $0001
    DW $32FC, $2EDA, $26D8, $26D7, $26D7, $22B7, $0802, $0401, $0401, $0401, $0401
    DW GlowYeild
  DW $0001
    DW $27FF, $27FF, $27FF, $27FF, $27FF, $27FF, $0000, $0000, $0401, $0000, $0000
    DW GlowYeild
  DW $0001
    DW $32FC, $2EDA, $26D8, $26D7, $26D7, $22B7, $0802, $0401, $0401, $0401, $0401
    DW GlowYeild
  DW GlowJMP, Sky_Esc_3_List_Loop

Sky_Esc_4_List:
  DW SetColorIndex, $00A2
Sky_Esc_4_List_Loop:
  DW $0031
    DW $48D5, $38B0, $286A, $2488, $2067, $1846, $1425, $1024, $0C23, $0C03, $0802
    DW GlowYeild
  DW $0001
    DW $3DD8, $31D5, $2991, $25B0, $218F, $1D8E, $0C23, $0C23, $0822, $0802, $0401
    DW GlowYeild
  DW $0001
    DW $32FC, $2EDA, $26D8, $26D7, $26D7, $22B7, $0802, $0401, $0401, $0401, $0401
    DW GlowYeild
  DW $0001
    DW $27FF, $27FF, $27FF, $27FF, $27FF, $27FF, $0000, $0000, $0401, $0000, $0000
    DW GlowYeild
  DW $0001
    DW $32FC, $2EDA, $26D8, $26D7, $26D7, $22B7, $0802, $0401, $0401, $0401, $0401
    DW GlowYeild
  DW $0011
    DW $48D5, $38B0, $286A, $2488, $2067, $1846, $1425, $1024, $0C23, $0C03, $0802
    DW GlowYeild
  DW $0001
    DW $32FC, $2EDA, $26D8, $26D7, $26D7, $22B7, $0802, $0401, $0401, $0401, $0401
    DW GlowYeild
  DW $0018
    DW $48D5, $38B0, $286A, $2488, $2067, $1846, $1425, $1024, $0C23, $0C03, $0802
    DW GlowYeild
  DW $0001
    DW $32FC, $2EDA, $26D8, $26D7, $26D7, $22B7, $0802, $0401, $0401, $0401, $0401
    DW GlowYeild
  DW $0001
    DW $27FF, $27FF, $27FF, $27FF, $27FF, $27FF, $0000, $0000, $0401, $0000, $0000
    DW GlowYeild
  DW $0001
    DW $32FC, $2EDA, $26D8, $26D7, $26D7, $22B7, $0802, $0401, $0401, $0401, $0401
    DW GlowYeild
  DW GlowJMP, Sky_Esc_4_List_Loop

Sky_Esc_5_List:
  DW SetColorIndex, $00A2
Sky_Esc_5_List_Loop:
  DW $0031
    DW $48D5, $38B0, $286A, $2488, $2067, $1846, $1425, $1024, $0C23, $0C03, $0802
    DW GlowYeild
  DW $0001
    DW $3DD8, $31D5, $2991, $25B0, $218F, $1D8E, $0C23, $0C23, $0822, $0802, $0401
    DW GlowYeild
  DW $0001
    DW $32FC, $2EDA, $26D8, $26D7, $26D7, $22B7, $0802, $0401, $0401, $0401, $0401
    DW GlowYeild
  DW $0001
    DW $27FF, $27FF, $27FF, $27FF, $27FF, $27FF, $0000, $0000, $0401, $0000, $0000
    DW GlowYeild
  DW $0001
    DW $32FC, $2EDA, $26D8, $26D7, $26D7, $22B7, $0802, $0401, $0401, $0401, $0401
    DW GlowYeild
  DW $0011
    DW $48D5, $38B0, $286A, $2488, $2067, $1846, $1425, $1024, $0C23, $0C03, $0802
    DW GlowYeild
  DW $0001
    DW $32FC, $2EDA, $26D8, $26D7, $26D7, $22B7, $0802, $0401, $0401, $0401, $0401
    DW GlowYeild
  DW $0018
    DW $48D5, $38B0, $286A, $2488, $2067, $1846, $1425, $1024, $0C23, $0C03, $0802
    DW GlowYeild
  DW $0001
    DW $32FC, $2EDA, $26D8, $26D7, $26D7, $22B7, $0802, $0401, $0401, $0401, $0401
    DW GlowYeild
  DW $0001
    DW $27FF, $27FF, $27FF, $27FF, $27FF, $27FF, $0000, $0000, $0401, $0000, $0000
    DW GlowYeild
  DW $0001
    DW $32FC, $2EDA, $26D8, $26D7, $26D7, $22B7, $0802, $0401, $0401, $0401, $0401
    DW GlowYeild
  DW GlowJMP, Sky_Esc_5_List_Loop

Sky_Esc_6_List:
  DW SetColorIndex, $00A2
Sky_Esc_6_List_Loop:
  DW $0031
    DW $48D5, $38B0, $286A, $2488, $2067, $1846, $1425, $1024, $0C23, $0C03, $0802
    DW GlowYeild
  DW $0001
    DW $3DD8, $31D5, $2991, $25B0, $218F, $1D8E, $0C23, $0C23, $0822, $0802, $0401
    DW GlowYeild
  DW $0001
    DW $32FC, $2EDA, $26D8, $26D7, $26D7, $22B7, $0802, $0401, $0401, $0401, $0401
    DW GlowYeild
  DW $0001
    DW $27FF, $27FF, $27FF, $27FF, $27FF, $27FF, $0000, $0000, $0401, $0000, $0000
    DW GlowYeild
  DW $0001
    DW $32FC, $2EDA, $26D8, $26D7, $26D7, $22B7, $0802, $0401, $0401, $0401, $0401
    DW GlowYeild
  DW $0011
    DW $48D5, $38B0, $286A, $2488, $2067, $1846, $1425, $1024, $0C23, $0C03, $0802
    DW GlowYeild
  DW $0001
    DW $32FC, $2EDA, $26D8, $26D7, $26D7, $22B7, $0802, $0401, $0401, $0401, $0401
    DW GlowYeild
  DW $0018
    DW $48D5, $38B0, $286A, $2488, $2067, $1846, $1425, $1024, $0C23, $0C03, $0802
    DW GlowYeild
  DW $0001
    DW $32FC, $2EDA, $26D8, $26D7, $26D7, $22B7, $0802, $0401, $0401, $0401, $0401
    DW GlowYeild
  DW $0001
    DW $27FF, $27FF, $27FF, $27FF, $27FF, $27FF, $0000, $0000, $0401, $0000, $0000
    DW GlowYeild
  DW $0001
    DW $32FC, $2EDA, $26D8, $26D7, $26D7, $22B7, $0802, $0401, $0401, $0401, $0401
    DW GlowYeild
  DW GlowJMP, Sky_Esc_6_List_Loop

OldT1EscTable:
  DW EmptyInit,OldT1Esc0_List, EmptyInit,OldT1Esc1_List, EmptyInit,OldT1Esc2_List, EmptyInit,OldT1Esc3_List
  DW EmptyInit,OldT1Esc4_List, EmptyInit,OldT1Esc5_List, EmptyInit,OldT1Esc6_List, EmptyInit,OldT1Esc7_List
OldT1Esc0_List:
OldT1Esc7_List:
  DW SetColorIndex, $00A2
OldT1Esc0_List_Loop:
  DW $0003
    DW $5A73, $41AD, $28E7
    DW SkipColors_4
    DW $0019, $0012, $3460, $0C20
    DW SkipColors_2
    DW $7F9C
    DW GlowYeild
  DW $0003
    DW $4E14, $396E, $24C8
    DW SkipColors_4
    DW $0014, $000E, $4900, $1C60
    DW SkipColors_2
    DW $6F3C
    DW GlowYeild
  DW $0003
    DW $41D5, $312E, $1CA8
    DW SkipColors_4
    DW $000F, $000A, $5980, $2CA0
    DW SkipColors_2
    DW $62FD
    DW GlowYeild
  DW $0003
    DW $3576, $28EF, $1889
    DW SkipColors_4
    DW $000A, $0005, $6E20, $38C0
    DW SkipColors_2
    DW $529D
    DW GlowYeild
  DW $0003
    DW $2D17, $20D0, $1489
    DW SkipColors_4
    DW $0005, $0001, $7EA0, $4900
    DW SkipColors_2
    DW $423E
    DW GlowYeild
  DW $0003
    DW $20B8, $1891, $106A
    DW SkipColors_4
    DW $000A, $0005, $6E20, $38C0
    DW SkipColors_2
    DW $31DE
    DW GlowYeild
  DW $0003
    DW $1479, $1051, $084A
    DW SkipColors_4
    DW $000F, $000A, $5980, $2CA0
    DW SkipColors_2
    DW $259F
    DW GlowYeild
  DW $0003
    DW $081A, $0812, $042B
    DW SkipColors_4
    DW $0014, $000E, $4900, $1C60
    DW SkipColors_2
    DW $153F
    DW GlowYeild
  DW $0003
    DW $1479, $1051, $084A
    DW SkipColors_4
    DW $000F, $000A, $5980, $2CA0
    DW SkipColors_2
    DW $259F
    DW GlowYeild
  DW $0003
    DW $20B8, $1891, $106A
    DW SkipColors_4
    DW $000A, $0005, $6E20, $38C0
    DW SkipColors_2
    DW $31DE
    DW GlowYeild
  DW $0003
    DW $2D17, $20D0, $1489
    DW SkipColors_4
    DW $0005, $0001, $7EA0, $4900
    DW SkipColors_2
    DW $423E
    DW GlowYeild
  DW $0003
    DW $3576, $28EF, $1889
    DW SkipColors_4
    DW $000A, $0005, $6E20, $38C0
    DW SkipColors_2
    DW $529D
    DW GlowYeild
  DW $0003
    DW $41D5, $312E, $1CA8
    DW SkipColors_4
    DW $000F, $000A, $5980, $2CA0
    DW SkipColors_2
    DW $62FD
    DW GlowYeild
  DW $0003
    DW $4E14, $396E, $24C8
    DW SkipColors_4
    DW $0014, $000E, $4900, $1C60
    DW SkipColors_2
    DW $6F3C
    DW GlowYeild
  DW GlowJMP, OldT1Esc0_List_Loop

OldT1Esc1_List:
  DW SetColorIndex, $00A2
OldT1Esc1_List_Loop:
  DW $0003
    DW $5A73, $41AD, $28E7
    DW SkipColors_4
    DW $0019, $0012, $3460, $0C20
    DW SkipColors_2
    DW $7F9C
    DW GlowYeild
  DW $0003
    DW $4E14, $396E, $24C8
    DW SkipColors_4
    DW $0014, $000E, $4900, $1C60
    DW SkipColors_2
    DW $6F3C
    DW GlowYeild
  DW $0003
    DW $41D5, $312E, $1CA8
    DW SkipColors_4
    DW $000F, $000A, $5980, $2CA0
    DW SkipColors_2
    DW $62FD
    DW GlowYeild
  DW $0003
    DW $3576, $28EF, $1889
    DW SkipColors_4
    DW $000A, $0005, $6E20, $38C0
    DW SkipColors_2
    DW $529D
    DW GlowYeild
  DW $0003
    DW $2D17, $20D0, $1489
    DW SkipColors_4
    DW $0005, $0001, $7EA0, $4900
    DW SkipColors_2
    DW $423E
    DW GlowYeild
  DW $0003
    DW $20B8, $1891, $106A
    DW SkipColors_4
    DW $000A, $0005, $6E20, $38C0
    DW SkipColors_2
    DW $31DE
    DW GlowYeild
  DW $0003
    DW $1479, $1051, $084A
    DW SkipColors_4
    DW $000F, $000A, $5980, $2CA0
    DW SkipColors_2
    DW $259F
    DW GlowYeild
  DW $0003
    DW $081A, $0812, $042B
    DW SkipColors_4
    DW $0014, $000E, $4900, $1C60
    DW SkipColors_2
    DW $153F
    DW GlowYeild
  DW $0003
    DW $1479, $1051, $084A
    DW SkipColors_4
    DW $000F, $000A, $5980, $2CA0
    DW SkipColors_2
    DW $259F
    DW GlowYeild
  DW $0003
    DW $20B8, $1891, $106A
    DW SkipColors_4
    DW $000A, $0005, $6E20, $38C0
    DW SkipColors_2
    DW $31DE
    DW GlowYeild
  DW $0003
    DW $2D17, $20D0, $1489
    DW SkipColors_4
    DW $0005, $0001, $7EA0, $4900
    DW SkipColors_2
    DW $423E
    DW GlowYeild
  DW $0003
    DW $3576, $28EF, $1889
    DW SkipColors_4
    DW $000A, $0005, $6E20, $38C0
    DW SkipColors_2
    DW $529D
    DW GlowYeild
  DW $0003
    DW $41D5, $312E, $1CA8
    DW SkipColors_4
    DW $000F, $000A, $5980, $2CA0
    DW SkipColors_2
    DW $62FD
    DW GlowYeild
  DW $0003
    DW $4E14, $396E, $24C8
    DW SkipColors_4
    DW $0014, $000E, $4900, $1C60
    DW SkipColors_2
    DW $6F3C
    DW GlowYeild
  DW GlowJMP, OldT1Esc1_List_Loop

OldT1Esc2_List:
  DW SetColorIndex, $00A2
OldT1Esc2_List_Loop:
  DW $0003
    DW $5A73, $41AD, $28E7
    DW SkipColors_4
    DW $0019, $0012, $3460, $0C20
    DW SkipColors_2
    DW $7F9C
    DW GlowYeild
  DW $0003
    DW $4E14, $396E, $24C8
    DW SkipColors_4
    DW $0014, $000E, $4900, $1C60
    DW SkipColors_2
    DW $6F3C
    DW GlowYeild
  DW $0003
    DW $41D5, $312E, $1CA8
    DW SkipColors_4
    DW $000F, $000A, $5980, $2CA0
    DW SkipColors_2
    DW $62FD
    DW GlowYeild
  DW $0003
    DW $3576, $28EF, $1889
    DW SkipColors_4
    DW $000A, $0005, $6E20, $38C0
    DW SkipColors_2
    DW $529D
    DW GlowYeild
  DW $0003
    DW $2D17, $20D0, $1489
    DW SkipColors_4
    DW $0005, $0001, $7EA0, $4900
    DW SkipColors_2
    DW $423E
    DW GlowYeild
  DW $0003
    DW $20B8, $1891, $106A
    DW SkipColors_4
    DW $000A, $0005, $6E20, $38C0
    DW SkipColors_2
    DW $31DE
    DW GlowYeild
  DW $0003
    DW $1479, $1051, $084A
    DW SkipColors_4
    DW $000F, $000A, $5980, $2CA0
    DW SkipColors_2
    DW $259F
    DW GlowYeild
  DW $0003
    DW $081A, $0812, $042B
    DW SkipColors_4
    DW $0014, $000E, $4900, $1C60
    DW SkipColors_2
    DW $153F
    DW GlowYeild
  DW $0003
    DW $1479, $1051, $084A
    DW SkipColors_4
    DW $000F, $000A, $5980, $2CA0
    DW SkipColors_2
    DW $259F
    DW GlowYeild
  DW $0003
    DW $20B8, $1891, $106A
    DW SkipColors_4
    DW $000A, $0005, $6E20, $38C0
    DW SkipColors_2
    DW $31DE
    DW GlowYeild
  DW $0003
    DW $2D17, $20D0, $1489
    DW SkipColors_4
    DW $0005, $0001, $7EA0, $4900
    DW SkipColors_2
    DW $423E
    DW GlowYeild
  DW $0003
    DW $3576, $28EF, $1889
    DW SkipColors_4
    DW $000A, $0005, $6E20, $38C0
    DW SkipColors_2
    DW $529D
    DW GlowYeild
  DW $0003
    DW $41D5, $312E, $1CA8
    DW SkipColors_4
    DW $000F, $000A, $5980, $2CA0
    DW SkipColors_2
    DW $62FD
    DW GlowYeild
  DW $0003
    DW $4E14, $396E, $24C8
    DW SkipColors_4
    DW $0014, $000E, $4900, $1C60
    DW SkipColors_2
    DW $6F3C
    DW GlowYeild
  DW GlowJMP, OldT1Esc2_List_Loop

OldT1Esc3_List:
  DW SetColorIndex, $00A2
OldT1Esc3_List_Loop:
  DW $0003
    DW $5A73, $41AD, $28E7
    DW SkipColors_4
    DW $0019, $0012, $3460, $0C20
    DW SkipColors_2
    DW $7F9C
    DW GlowYeild
  DW $0003
    DW $4E14, $396E, $24C8
    DW SkipColors_4
    DW $0014, $000E, $4900, $1C60
    DW SkipColors_2
    DW $6F3C
    DW GlowYeild
  DW $0003
    DW $41D5, $312E, $1CA8
    DW SkipColors_4
    DW $000F, $000A, $5980, $2CA0
    DW SkipColors_2
    DW $62FD
    DW GlowYeild
  DW $0003
    DW $3576, $28EF, $1889
    DW SkipColors_4
    DW $000A, $0005, $6E20, $38C0
    DW SkipColors_2
    DW $529D
    DW GlowYeild
  DW $0003
    DW $2D17, $20D0, $1489
    DW SkipColors_4
    DW $0005, $0001, $7EA0, $4900
    DW SkipColors_2
    DW $423E
    DW GlowYeild
  DW $0003
    DW $20B8, $1891, $106A
    DW SkipColors_4
    DW $000A, $0005, $6E20, $38C0
    DW SkipColors_2
    DW $31DE
    DW GlowYeild
  DW $0003
    DW $1479, $1051, $084A
    DW SkipColors_4
    DW $000F, $000A, $5980, $2CA0
    DW SkipColors_2
    DW $259F
    DW GlowYeild
  DW $0003
    DW $081A, $0812, $042B
    DW SkipColors_4
    DW $0014, $000E, $4900, $1C60
    DW SkipColors_2
    DW $153F
    DW GlowYeild
  DW $0003
    DW $1479, $1051, $084A
    DW SkipColors_4
    DW $000F, $000A, $5980, $2CA0
    DW SkipColors_2
    DW $259F
    DW GlowYeild
  DW $0003
    DW $20B8, $1891, $106A
    DW SkipColors_4
    DW $000A, $0005, $6E20, $38C0
    DW SkipColors_2
    DW $31DE
    DW GlowYeild
  DW $0003
    DW $2D17, $20D0, $1489
    DW SkipColors_4
    DW $0005, $0001, $7EA0, $4900
    DW SkipColors_2
    DW $423E
    DW GlowYeild
  DW $0003
    DW $3576, $28EF, $1889
    DW SkipColors_4
    DW $000A, $0005, $6E20, $38C0
    DW SkipColors_2
    DW $529D
    DW GlowYeild
  DW $0003
    DW $41D5, $312E, $1CA8
    DW SkipColors_4
    DW $000F, $000A, $5980, $2CA0
    DW SkipColors_2
    DW $62FD
    DW GlowYeild
  DW $0003
    DW $4E14, $396E, $24C8
    DW SkipColors_4
    DW $0014, $000E, $4900, $1C60
    DW SkipColors_2
    DW $6F3C
    DW GlowYeild
  DW GlowJMP, OldT1Esc3_List_Loop

OldT1Esc4_List:
  DW SetColorIndex, $00A2
OldT1Esc4_List_Loop:
  DW $0003
    DW $5A73, $41AD, $28E7
    DW SkipColors_4
    DW $0019, $0012, $3460, $0C20
    DW SkipColors_2
    DW $7F9C
    DW GlowYeild
  DW $0003
    DW $4E14, $396E, $24C8
    DW SkipColors_4
    DW $0014, $000E, $4900, $1C60
    DW SkipColors_2
    DW $6F3C
    DW GlowYeild
  DW $0003
    DW $41D5, $312E, $1CA8
    DW SkipColors_4
    DW $000F, $000A, $5980, $2CA0
    DW SkipColors_2
    DW $62FD
    DW GlowYeild
  DW $0003
    DW $3576, $28EF, $1889
    DW SkipColors_4
    DW $000A, $0005, $6E20, $38C0
    DW SkipColors_2
    DW $529D
    DW GlowYeild
  DW $0003
    DW $2D17, $20D0, $1489
    DW SkipColors_4
    DW $0005, $0001, $7EA0, $4900
    DW SkipColors_2
    DW $423E
    DW GlowYeild
  DW $0003
    DW $20B8, $1891, $106A
    DW SkipColors_4
    DW $000A, $0005, $6E20, $38C0
    DW SkipColors_2
    DW $31DE
    DW GlowYeild
  DW $0003
    DW $1479, $1051, $084A
    DW SkipColors_4
    DW $000F, $000A, $5980, $2CA0
    DW SkipColors_2
    DW $259F
    DW GlowYeild
  DW $0003
    DW $081A, $0812, $042B
    DW SkipColors_4
    DW $0014, $000E, $4900, $1C60
    DW SkipColors_2
    DW $153F
    DW GlowYeild
  DW $0003
    DW $1479, $1051, $084A
    DW SkipColors_4
    DW $000F, $000A, $5980, $2CA0
    DW SkipColors_2
    DW $259F
    DW GlowYeild
  DW $0003
    DW $20B8, $1891, $106A
    DW SkipColors_4
    DW $000A, $0005, $6E20, $38C0
    DW SkipColors_2
    DW $31DE
    DW GlowYeild
  DW $0003
    DW $2D17, $20D0, $1489
    DW SkipColors_4
    DW $0005, $0001, $7EA0, $4900
    DW SkipColors_2
    DW $423E
    DW GlowYeild
  DW $0003
    DW $3576, $28EF, $1889
    DW SkipColors_4
    DW $000A, $0005, $6E20, $38C0
    DW SkipColors_2
    DW $529D
    DW GlowYeild
  DW $0003
    DW $41D5, $312E, $1CA8
    DW SkipColors_4
    DW $000F, $000A, $5980, $2CA0
    DW SkipColors_2
    DW $62FD
    DW GlowYeild
  DW $0003
    DW $4E14, $396E, $24C8
    DW SkipColors_4
    DW $0014, $000E, $4900, $1C60
    DW SkipColors_2
    DW $6F3C
    DW GlowYeild
  DW GlowJMP, OldT1Esc4_List_Loop

OldT1Esc5_List:
  DW SetColorIndex, $00A2
OldT1Esc5_List_Loop:
  DW $0003
    DW $5A73, $41AD, $28E7
    DW SkipColors_4
    DW $0019, $0012, $3460, $0C20
    DW SkipColors_2
    DW $7F9C
    DW GlowYeild
  DW $0003
    DW $4E14, $396E, $24C8
    DW SkipColors_4
    DW $0014, $000E, $4900, $1C60
    DW SkipColors_2
    DW $6F3C
    DW GlowYeild
  DW $0003
    DW $41D5, $312E, $1CA8
    DW SkipColors_4
    DW $000F, $000A, $5980, $2CA0
    DW SkipColors_2
    DW $62FD
    DW GlowYeild
  DW $0003
    DW $3576, $28EF, $1889
    DW SkipColors_4
    DW $000A, $0005, $6E20, $38C0
    DW SkipColors_2
    DW $529D
    DW GlowYeild
  DW $0003
    DW $2D17, $20D0, $1489
    DW SkipColors_4
    DW $0005, $0001, $7EA0, $4900
    DW SkipColors_2
    DW $423E
    DW GlowYeild
  DW $0003
    DW $20B8, $1891, $106A
    DW SkipColors_4
    DW $000A, $0005, $6E20, $38C0
    DW SkipColors_2
    DW $31DE
    DW GlowYeild
  DW $0003
    DW $1479, $1051, $084A
    DW SkipColors_4
    DW $000F, $000A, $5980, $2CA0
    DW SkipColors_2
    DW $259F
    DW GlowYeild
  DW $0003
    DW $081A, $0812, $042B
    DW SkipColors_4
    DW $0014, $000E, $4900, $1C60
    DW SkipColors_2
    DW $153F
    DW GlowYeild
  DW $0003
    DW $1479, $1051, $084A
    DW SkipColors_4
    DW $000F, $000A, $5980, $2CA0
    DW SkipColors_2
    DW $259F
    DW GlowYeild
  DW $0003
    DW $20B8, $1891, $106A
    DW SkipColors_4
    DW $000A, $0005, $6E20, $38C0
    DW SkipColors_2
    DW $31DE
    DW GlowYeild
  DW $0003
    DW $2D17, $20D0, $1489
    DW SkipColors_4
    DW $0005, $0001, $7EA0, $4900
    DW SkipColors_2
    DW $423E
    DW GlowYeild
  DW $0003
    DW $3576, $28EF, $1889
    DW SkipColors_4
    DW $000A, $0005, $6E20, $38C0
    DW SkipColors_2
    DW $529D
    DW GlowYeild
  DW $0003
    DW $41D5, $312E, $1CA8
    DW SkipColors_4
    DW $000F, $000A, $5980, $2CA0
    DW SkipColors_2
    DW $62FD
    DW GlowYeild
  DW $0003
    DW $4E14, $396E, $24C8
    DW SkipColors_4
    DW $0014, $000E, $4900, $1C60
    DW SkipColors_2
    DW $6F3C
    DW GlowYeild
  DW GlowJMP, OldT1Esc5_List_Loop

OldT1Esc6_List:
  DW SetColorIndex, $00A2
OldT1Esc6_List_Loop:
  DW $0003
    DW $5A73, $41AD, $28E7
    DW SkipColors_4
    DW $0019, $0012, $3460, $0C20
    DW SkipColors_2
    DW $7F9C
    DW GlowYeild
  DW $0003
    DW $4E14, $396E, $24C8
    DW SkipColors_4
    DW $0014, $000E, $4900, $1C60
    DW SkipColors_2
    DW $6F3C
    DW GlowYeild
  DW $0003
    DW $41D5, $312E, $1CA8
    DW SkipColors_4
    DW $000F, $000A, $5980, $2CA0
    DW SkipColors_2
    DW $62FD
    DW GlowYeild
  DW $0003
    DW $3576, $28EF, $1889
    DW SkipColors_4
    DW $000A, $0005, $6E20, $38C0
    DW SkipColors_2
    DW $529D
    DW GlowYeild
  DW $0003
    DW $2D17, $20D0, $1489
    DW SkipColors_4
    DW $0005, $0001, $7EA0, $4900
    DW SkipColors_2
    DW $423E
    DW GlowYeild
  DW $0003
    DW $20B8, $1891, $106A
    DW SkipColors_4
    DW $000A, $0005, $6E20, $38C0
    DW SkipColors_2
    DW $31DE
    DW GlowYeild
  DW $0003
    DW $1479, $1051, $084A
    DW SkipColors_4
    DW $000F, $000A, $5980, $2CA0
    DW SkipColors_2
    DW $259F
    DW GlowYeild
  DW $0003
    DW $081A, $0812, $042B
    DW SkipColors_4
    DW $0014, $000E, $4900, $1C60
    DW SkipColors_2
    DW $153F
    DW GlowYeild
  DW $0003
    DW $1479, $1051, $084A
    DW SkipColors_4
    DW $000F, $000A, $5980, $2CA0
    DW SkipColors_2
    DW $259F
    DW GlowYeild
  DW $0003
    DW $20B8, $1891, $106A
    DW SkipColors_4
    DW $000A, $0005, $6E20, $38C0
    DW SkipColors_2
    DW $31DE
    DW GlowYeild
  DW $0003
    DW $2D17, $20D0, $1489
    DW SkipColors_4
    DW $0005, $0001, $7EA0, $4900
    DW SkipColors_2
    DW $423E
    DW GlowYeild
  DW $0003
    DW $3576, $28EF, $1889
    DW SkipColors_4
    DW $000A, $0005, $6E20, $38C0
    DW SkipColors_2
    DW $529D
    DW GlowYeild
  DW $0003
    DW $41D5, $312E, $1CA8
    DW SkipColors_4
    DW $000F, $000A, $5980, $2CA0
    DW SkipColors_2
    DW $62FD
    DW GlowYeild
  DW $0003
    DW $4E14, $396E, $24C8
    DW SkipColors_4
    DW $0014, $000E, $4900, $1C60
    DW SkipColors_2
    DW $6F3C
    DW GlowYeild
  DW GlowJMP, OldT1Esc6_List_Loop

OldT2EscTable:
  DW EmptyInit,OldT2Esc0_List, EmptyInit,OldT2Esc1_List, EmptyInit,OldT2Esc2_List, EmptyInit,OldT2Esc3_List
  DW EmptyInit,OldT2Esc4_List, EmptyInit,OldT2Esc5_List, EmptyInit,OldT2Esc6_List, EmptyInit,OldT2Esc7_List
OldT2Esc0_List:
OldT2Esc7_List:
  DW SetColorIndex, $00D2
OldT2Esc0_List_Loop:
  DW $0010
    DW $35AD, $1CE7, $0C63
    DW GlowYeild
  DW $0001
    DW $29D0, $150A, $0885
    DW GlowYeild
  DW $0001
    DW $1E14, $114D, $08A7
    DW GlowYeild
  DW $0002
    DW $0E37, $096F, $04A8
    DW GlowYeild
  DW $0001
    DW $025A, $0192, $00CA
    DW GlowYeild
  DW $0002
    DW $35AD, $1CE7, $0C63
    DW GlowYeild
  DW $0001
    DW $29D0, $150A, $0885
    DW GlowYeild
  DW $0001
    DW $1E14, $114D, $08A7
    DW GlowYeild
  DW $0001
    DW $0E37, $096F, $04A8
    DW GlowYeild
  DW $0001
    DW $025A, $0192, $00CA
    DW GlowYeild
  DW $0020
    DW $35AD, $1CE7, $0C63
    DW GlowYeild
  DW $0002
    DW $29D0, $150A, $0885
    DW GlowYeild
  DW $0001
    DW $1E14, $114D, $08A7
    DW GlowYeild
  DW $0001
    DW $0E37, $096F, $04A8
    DW GlowYeild
  DW $0001
    DW $025A, $0192, $00CA
    DW GlowYeild
  DW GlowJMP, OldT2Esc0_List_Loop

OldT2Esc1_List:
  DW SetColorIndex, $00D2
OldT2Esc1_List_Loop:
  DW $0010
    DW $35AD, $1CE7, $0C63
    DW GlowYeild
  DW $0001
    DW $29D0, $150A, $0885
    DW GlowYeild
  DW $0001
    DW $1E14, $114D, $08A7
    DW GlowYeild
  DW $0002
    DW $0E37, $096F, $04A8
    DW GlowYeild
  DW $0001
    DW $025A, $0192, $00CA
    DW GlowYeild
  DW $0002
    DW $35AD, $1CE7, $0C63
    DW GlowYeild
  DW $0001
    DW $29D0, $150A, $0885
    DW GlowYeild
  DW $0001
    DW $1E14, $114D, $08A7
    DW GlowYeild
  DW $0001
    DW $0E37, $096F, $04A8
    DW GlowYeild
  DW $0001
    DW $025A, $0192, $00CA
    DW GlowYeild
  DW $0020
    DW $35AD, $1CE7, $0C63
    DW GlowYeild
  DW $0002
    DW $29D0, $150A, $0885
    DW GlowYeild
  DW $0001
    DW $1E14, $114D, $08A7
    DW GlowYeild
  DW $0001
    DW $0E37, $096F, $04A8
    DW GlowYeild
  DW $0001
    DW $025A, $0192, $00CA
    DW GlowYeild
  DW GlowJMP, OldT2Esc1_List_Loop

OldT2Esc2_List:
  DW SetColorIndex, $00D2
OldT2Esc2_List_Loop:
  DW $0010
    DW $35AD, $1CE7, $0C63
    DW GlowYeild
  DW $0001
    DW $29D0, $150A, $0885
    DW GlowYeild
  DW $0001
    DW $1E14, $114D, $08A7
    DW GlowYeild
  DW $0002
    DW $0E37, $096F, $04A8
    DW GlowYeild
  DW $0001
    DW $025A, $0192, $00CA
    DW GlowYeild
  DW $0002
    DW $35AD, $1CE7, $0C63
    DW GlowYeild
  DW $0001
    DW $29D0, $150A, $0885
    DW GlowYeild
  DW $0001
    DW $1E14, $114D, $08A7
    DW GlowYeild
  DW $0001
    DW $0E37, $096F, $04A8
    DW GlowYeild
  DW $0001
    DW $025A, $0192, $00CA
    DW GlowYeild
  DW $0020
    DW $35AD, $1CE7, $0C63
    DW GlowYeild
  DW $0002
    DW $29D0, $150A, $0885
    DW GlowYeild
  DW $0001
    DW $1E14, $114D, $08A7
    DW GlowYeild
  DW $0001
    DW $0E37, $096F, $04A8
    DW GlowYeild
  DW $0001
    DW $025A, $0192, $00CA
    DW GlowYeild
  DW GlowJMP, OldT2Esc2_List_Loop

OldT2Esc3_List:
  DW SetColorIndex, $00D2
OldT2Esc3_List_Loop:
  DW $0010
    DW $35AD, $1CE7, $0C63
    DW GlowYeild
  DW $0001
    DW $29D0, $150A, $0885
    DW GlowYeild
  DW $0001
    DW $1E14, $114D, $08A7
    DW GlowYeild
  DW $0002
    DW $0E37, $096F, $04A8
    DW GlowYeild
  DW $0001
    DW $025A, $0192, $00CA
    DW GlowYeild
  DW $0002
    DW $35AD, $1CE7, $0C63
    DW GlowYeild
  DW $0001
    DW $29D0, $150A, $0885
    DW GlowYeild
  DW $0001
    DW $1E14, $114D, $08A7
    DW GlowYeild
  DW $0001
    DW $0E37, $096F, $04A8
    DW GlowYeild
  DW $0001
    DW $025A, $0192, $00CA
    DW GlowYeild
  DW $0020
    DW $35AD, $1CE7, $0C63
    DW GlowYeild
  DW $0002
    DW $29D0, $150A, $0885
    DW GlowYeild
  DW $0001
    DW $1E14, $114D, $08A7
    DW GlowYeild
  DW $0001
    DW $0E37, $096F, $04A8
    DW GlowYeild
  DW $0001
    DW $025A, $0192, $00CA
    DW GlowYeild
  DW GlowJMP, OldT2Esc3_List_Loop

OldT2Esc4_List:
  DW SetColorIndex, $00D2
OldT2Esc4_List_Loop:
  DW $0010
    DW $35AD, $1CE7, $0C63
    DW GlowYeild
  DW $0001
    DW $29D0, $150A, $0885
    DW GlowYeild
  DW $0001
    DW $1E14, $114D, $08A7
    DW GlowYeild
  DW $0002
    DW $0E37, $096F, $04A8
    DW GlowYeild
  DW $0001
    DW $025A, $0192, $00CA
    DW GlowYeild
  DW $0002
    DW $35AD, $1CE7, $0C63
    DW GlowYeild
  DW $0001
    DW $29D0, $150A, $0885
    DW GlowYeild
  DW $0001
    DW $1E14, $114D, $08A7
    DW GlowYeild
  DW $0001
    DW $0E37, $096F, $04A8
    DW GlowYeild
  DW $0001
    DW $025A, $0192, $00CA
    DW GlowYeild
  DW $0020
    DW $35AD, $1CE7, $0C63
    DW GlowYeild
  DW $0002
    DW $29D0, $150A, $0885
    DW GlowYeild
  DW $0001
    DW $1E14, $114D, $08A7
    DW GlowYeild
  DW $0001
    DW $0E37, $096F, $04A8
    DW GlowYeild
  DW $0001
    DW $025A, $0192, $00CA
    DW GlowYeild
  DW GlowJMP, OldT2Esc4_List_Loop

OldT2Esc5_List:
  DW SetColorIndex, $00D2
OldT2Esc5_List_Loop:
  DW $0010
    DW $35AD, $1CE7, $0C63
    DW GlowYeild
  DW $0001
    DW $29D0, $150A, $0885
    DW GlowYeild
  DW $0001
    DW $1E14, $114D, $08A7
    DW GlowYeild
  DW $0002
    DW $0E37, $096F, $04A8
    DW GlowYeild
  DW $0001
    DW $025A, $0192, $00CA
    DW GlowYeild
  DW $0002
    DW $35AD, $1CE7, $0C63
    DW GlowYeild
  DW $0001
    DW $29D0, $150A, $0885
    DW GlowYeild
  DW $0001
    DW $1E14, $114D, $08A7
    DW GlowYeild
  DW $0001
    DW $0E37, $096F, $04A8
    DW GlowYeild
  DW $0001
    DW $025A, $0192, $00CA
    DW GlowYeild
  DW $0020
    DW $35AD, $1CE7, $0C63
    DW GlowYeild
  DW $0002
    DW $29D0, $150A, $0885
    DW GlowYeild
  DW $0001
    DW $1E14, $114D, $08A7
    DW GlowYeild
  DW $0001
    DW $0E37, $096F, $04A8
    DW GlowYeild
  DW $0001
    DW $025A, $0192, $00CA
    DW GlowYeild
  DW GlowJMP, OldT2Esc5_List_Loop

OldT2Esc6_List:
  DW SetColorIndex, $00D2
OldT2Esc6_List_Loop:
  DW $0010
    DW $35AD, $1CE7, $0C63
    DW GlowYeild
  DW $0001
    DW $29D0, $150A, $0885
    DW GlowYeild
  DW $0001
    DW $1E14, $114D, $08A7
    DW GlowYeild
  DW $0002
    DW $0E37, $096F, $04A8
    DW GlowYeild
  DW $0001
    DW $025A, $0192, $00CA
    DW GlowYeild
  DW $0002
    DW $35AD, $1CE7, $0C63
    DW GlowYeild
  DW $0001
    DW $29D0, $150A, $0885
    DW GlowYeild
  DW $0001
    DW $1E14, $114D, $08A7
    DW GlowYeild
  DW $0001
    DW $0E37, $096F, $04A8
    DW GlowYeild
  DW $0001
    DW $025A, $0192, $00CA
    DW GlowYeild
  DW $0020
    DW $35AD, $1CE7, $0C63
    DW GlowYeild
  DW $0002
    DW $29D0, $150A, $0885
    DW GlowYeild
  DW $0001
    DW $1E14, $114D, $08A7
    DW GlowYeild
  DW $0001
    DW $0E37, $096F, $04A8
    DW GlowYeild
  DW $0001
    DW $025A, $0192, $00CA
    DW GlowYeild
  DW GlowJMP, OldT2Esc6_List_Loop

OldT3EscTable:
  DW EmptyInit,OldT3Esc0_List, EmptyInit,OldT3Esc1_List, EmptyInit,OldT3Esc2_List, EmptyInit,OldT3Esc3_List
  DW EmptyInit,OldT3Esc4_List, EmptyInit,OldT3Esc5_List, EmptyInit,OldT3Esc6_List, EmptyInit,OldT3Esc7_List
OldT3Esc0_List:
OldT3Esc7_List:
  DW SetColorIndex, $00AA
OldT3Esc0_List_Loop:
  DW $0010
    DW $28C8, $2484, $1C61
    DW GlowYeild
  DW $0001
    DW $398E, $296B, $1549
    DW GlowYeild
  DW $0001
    DW $4A74, $2E52, $1230
    DW GlowYeild
  DW $0002
    DW $5739, $3318, $0B18
    DW GlowYeild
  DW $0001
    DW $67FF, $43FF, $03FF
    DW GlowYeild
  DW $0002
    DW $28C8, $2484, $1C61
    DW GlowYeild
  DW $0001
    DW $398E, $296B, $1549
    DW GlowYeild
  DW $0001
    DW $4A74, $2E52, $1230
    DW GlowYeild
  DW $0001
    DW $5739, $3318, $0B18
    DW GlowYeild
  DW $0001
    DW $67FF, $43FF, $03FF
    DW GlowYeild
  DW $0020
    DW $28C8, $2484, $1C61
    DW GlowYeild
  DW $0002
    DW $398E, $296B, $1549
    DW GlowYeild
  DW $0001
    DW $4A74, $2E52, $1230
    DW GlowYeild
  DW $0001
    DW $5739, $3318, $0B18
    DW GlowYeild
  DW $0001
    DW $67FF, $43FF, $03FF
    DW GlowYeild
  DW GlowJMP, OldT3Esc0_List_Loop

OldT3Esc1_List:
  DW SetColorIndex, $00AA
OldT3Esc1_List_Loop:
  DW $0010
    DW $28C8, $2484, $1C61
    DW GlowYeild
  DW $0001
    DW $398E, $296B, $1549
    DW GlowYeild
  DW $0001
    DW $4A74, $2E52, $1230
    DW GlowYeild
  DW $0002
    DW $5739, $3318, $0B18
    DW GlowYeild
  DW $0001
    DW $67FF, $43FF, $03FF
    DW GlowYeild
  DW $0002
    DW $28C8, $2484, $1C61
    DW GlowYeild
  DW $0001
    DW $398E, $296B, $1549
    DW GlowYeild
  DW $0001
    DW $4A74, $2E52, $1230
    DW GlowYeild
  DW $0001
    DW $5739, $3318, $0B18
    DW GlowYeild
  DW $0001
    DW $67FF, $43FF, $03FF
    DW GlowYeild
  DW $0020
    DW $28C8, $2484, $1C61
    DW GlowYeild
  DW $0002
    DW $398E, $296B, $1549
    DW GlowYeild
  DW $0001
    DW $4A74, $2E52, $1230
    DW GlowYeild
  DW $0001
    DW $5739, $3318, $0B18
    DW GlowYeild
  DW $0001
    DW $67FF, $43FF, $03FF
    DW GlowYeild
  DW GlowJMP, OldT3Esc1_List_Loop

OldT3Esc2_List:
  DW SetColorIndex, $00AA
OldT3Esc2_List_Loop:
  DW $0010
    DW $28C8, $2484, $1C61
    DW GlowYeild
  DW $0001
    DW $398E, $296B, $1549
    DW GlowYeild
  DW $0001
    DW $4A74, $2E52, $1230
    DW GlowYeild
  DW $0002
    DW $5739, $3318, $0B18
    DW GlowYeild
  DW $0001
    DW $67FF, $43FF, $03FF
    DW GlowYeild
  DW $0002
    DW $28C8, $2484, $1C61
    DW GlowYeild
  DW $0001
    DW $398E, $296B, $1549
    DW GlowYeild
  DW $0001
    DW $4A74, $2E52, $1230
    DW GlowYeild
  DW $0001
    DW $5739, $3318, $0B18
    DW GlowYeild
  DW $0001
    DW $67FF, $43FF, $03FF
    DW GlowYeild
  DW $0020
    DW $28C8, $2484, $1C61
    DW GlowYeild
  DW $0002
    DW $398E, $296B, $1549
    DW GlowYeild
  DW $0001
    DW $4A74, $2E52, $1230
    DW GlowYeild
  DW $0001
    DW $5739, $3318, $0B18
    DW GlowYeild
  DW $0001
    DW $67FF, $43FF, $03FF
    DW GlowYeild
  DW GlowJMP, OldT3Esc2_List_Loop

OldT3Esc3_List:
  DW SetColorIndex, $00AA
OldT3Esc3_List_Loop:
  DW $0010
    DW $28C8, $2484, $1C61
    DW GlowYeild
  DW $0001
    DW $398E, $296B, $1549
    DW GlowYeild
  DW $0001
    DW $4A74, $2E52, $1230
    DW GlowYeild
  DW $0002
    DW $5739, $3318, $0B18
    DW GlowYeild
  DW $0001
    DW $67FF, $43FF, $03FF
    DW GlowYeild
  DW $0002
    DW $28C8, $2484, $1C61
    DW GlowYeild
  DW $0001
    DW $398E, $296B, $1549
    DW GlowYeild
  DW $0001
    DW $4A74, $2E52, $1230
    DW GlowYeild
  DW $0001
    DW $5739, $3318, $0B18
    DW GlowYeild
  DW $0001
    DW $67FF, $43FF, $03FF
    DW GlowYeild
  DW $0020
    DW $28C8, $2484, $1C61
    DW GlowYeild
  DW $0002
    DW $398E, $296B, $1549
    DW GlowYeild
  DW $0001
    DW $4A74, $2E52, $1230
    DW GlowYeild
  DW $0001
    DW $5739, $3318, $0B18
    DW GlowYeild
  DW $0001
    DW $67FF, $43FF, $03FF
    DW GlowYeild
  DW GlowJMP, OldT3Esc3_List_Loop

OldT3Esc4_List:
  DW SetColorIndex, $00AA
OldT3Esc4_List_Loop:
  DW $0010
    DW $28C8, $2484, $1C61
    DW GlowYeild
  DW $0001
    DW $398E, $296B, $1549
    DW GlowYeild
  DW $0001
    DW $4A74, $2E52, $1230
    DW GlowYeild
  DW $0002
    DW $5739, $3318, $0B18
    DW GlowYeild
  DW $0001
    DW $67FF, $43FF, $03FF
    DW GlowYeild
  DW $0002
    DW $28C8, $2484, $1C61
    DW GlowYeild
  DW $0001
    DW $398E, $296B, $1549
    DW GlowYeild
  DW $0001
    DW $4A74, $2E52, $1230
    DW GlowYeild
  DW $0001
    DW $5739, $3318, $0B18
    DW GlowYeild
  DW $0001
    DW $67FF, $43FF, $03FF
    DW GlowYeild
  DW $0020
    DW $28C8, $2484, $1C61
    DW GlowYeild
  DW $0002
    DW $398E, $296B, $1549
    DW GlowYeild
  DW $0001
    DW $4A74, $2E52, $1230
    DW GlowYeild
  DW $0001
    DW $5739, $3318, $0B18
    DW GlowYeild
  DW $0001
    DW $67FF, $43FF, $03FF
    DW GlowYeild
  DW GlowJMP, OldT3Esc4_List_Loop

OldT3Esc5_List:
  DW SetColorIndex, $00AA
OldT3Esc5_List_Loop:
  DW $0010
    DW $28C8, $2484, $1C61
    DW GlowYeild
  DW $0001
    DW $398E, $296B, $1549
    DW GlowYeild
  DW $0001
    DW $4A74, $2E52, $1230
    DW GlowYeild
  DW $0002
    DW $5739, $3318, $0B18
    DW GlowYeild
  DW $0001
    DW $67FF, $43FF, $03FF
    DW GlowYeild
  DW $0002
    DW $28C8, $2484, $1C61
    DW GlowYeild
  DW $0001
    DW $398E, $296B, $1549
    DW GlowYeild
  DW $0001
    DW $4A74, $2E52, $1230
    DW GlowYeild
  DW $0001
    DW $5739, $3318, $0B18
    DW GlowYeild
  DW $0001
    DW $67FF, $43FF, $03FF
    DW GlowYeild
  DW $0020
    DW $28C8, $2484, $1C61
    DW GlowYeild
  DW $0002
    DW $398E, $296B, $1549
    DW GlowYeild
  DW $0001
    DW $4A74, $2E52, $1230
    DW GlowYeild
  DW $0001
    DW $5739, $3318, $0B18
    DW GlowYeild
  DW $0001
    DW $67FF, $43FF, $03FF
    DW GlowYeild
  DW GlowJMP, OldT3Esc5_List_Loop

OldT3Esc6_List:
  DW SetColorIndex, $00AA
OldT3Esc6_List_Loop:
  DW $0010
    DW $28C8, $2484, $1C61
    DW GlowYeild
  DW $0001
    DW $398E, $296B, $1549
    DW GlowYeild
  DW $0001
    DW $4A74, $2E52, $1230
    DW GlowYeild
  DW $0002
    DW $5739, $3318, $0B18
    DW GlowYeild
  DW $0001
    DW $67FF, $43FF, $03FF
    DW GlowYeild
  DW $0002
    DW $28C8, $2484, $1C61
    DW GlowYeild
  DW $0001
    DW $398E, $296B, $1549
    DW GlowYeild
  DW $0001
    DW $4A74, $2E52, $1230
    DW GlowYeild
  DW $0001
    DW $5739, $3318, $0B18
    DW GlowYeild
  DW $0001
    DW $67FF, $43FF, $03FF
    DW GlowYeild
  DW $0020
    DW $28C8, $2484, $1C61
    DW GlowYeild
  DW $0002
    DW $398E, $296B, $1549
    DW GlowYeild
  DW $0001
    DW $4A74, $2E52, $1230
    DW GlowYeild
  DW $0001
    DW $5739, $3318, $0B18
    DW GlowYeild
  DW $0001
    DW $67FF, $43FF, $03FF
    DW GlowYeild
  DW GlowJMP, OldT3Esc6_List_Loop

; Brinstar tileset glows

Blue_BG_Table:
  DW EmptyInit,Blue_BG_0_List, EmptyInit,Blue_BG_1_List, EmptyInit,Blue_BG_2_List, EmptyInit,Blue_BG_3_List
  DW EmptyInit,Blue_BG_4_List, EmptyInit,Blue_BG_5_List, EmptyInit,Blue_BG_6_List, EmptyInit,Blue_BG_7_List
Blue_BG_0_List:
  DW SetColorIndex, $00E2
Blue_BG_0_List_Loop:
  DW $000A
    DW $5D22, $4463, $1840
    DW GlowYeild
  DW $000A
    DW $5901, $4042, $1420
    DW GlowYeild
  DW $000A
    DW $54E0, $3C21, $1000
    DW GlowYeild
  DW $000A
    DW $50C0, $3C21, $1000
    DW GlowYeild
  DW $000A
    DW $4CA0, $3800, $0C00
    DW GlowYeild
  DW $000A
    DW $4880, $3800, $0C00
    DW GlowYeild
  DW $000A
    DW $4460, $3400, $0800
    DW GlowYeild
  DW $000A
    DW $4040, $3400, $0800
    DW GlowYeild
  DW $000A
    DW $4460, $3400, $0800
    DW GlowYeild
  DW $000A
    DW $4880, $3800, $0C00
    DW GlowYeild
  DW $000A
    DW $4CA0, $3800, $0C00
    DW GlowYeild
  DW $000A
    DW $50C0, $3C21, $1000
    DW GlowYeild
  DW $000A
    DW $54E0, $3C21, $1000
    DW GlowYeild
  DW $000A
    DW $5901, $4042, $1420
    DW GlowYeild
  DW GlowJMP, Blue_BG_0_List_Loop

Blue_BG_1_List:
  DW SetColorIndex, $00E2
Blue_BG_1_List_Loop:
  DW $000A
    DW $5D22, $4463, $1840
    DW GlowYeild
  DW $000A
    DW $5901, $4042, $1420
    DW GlowYeild
  DW $000A
    DW $54E0, $3C21, $1000
    DW GlowYeild
  DW $000A
    DW $50C0, $3C21, $1000
    DW GlowYeild
  DW $000A
    DW $4CA0, $3800, $0C00
    DW GlowYeild
  DW $000A
    DW $4880, $3800, $0C00
    DW GlowYeild
  DW $000A
    DW $4460, $3400, $0800
    DW GlowYeild
  DW $000A
    DW $4040, $3400, $0800
    DW GlowYeild
  DW $000A
    DW $4460, $3400, $0800
    DW GlowYeild
  DW $000A
    DW $4880, $3800, $0C00
    DW GlowYeild
  DW $000A
    DW $4CA0, $3800, $0C00
    DW GlowYeild
  DW $000A
    DW $50C0, $3C21, $1000
    DW GlowYeild
  DW $000A
    DW $54E0, $3C21, $1000
    DW GlowYeild
  DW $000A
    DW $5901, $4042, $1420
    DW GlowYeild
  DW GlowJMP, Blue_BG_1_List_Loop

Blue_BG_2_List:
  DW SetColorIndex, $00E2
Blue_BG_2_List_Loop:
  DW $000A
    DW $5D22, $4463, $1840
    DW GlowYeild
  DW $000A
    DW $5901, $4042, $1420
    DW GlowYeild
  DW $000A
    DW $54E0, $3C21, $1000
    DW GlowYeild
  DW $000A
    DW $50C0, $3C21, $1000
    DW GlowYeild
  DW $000A
    DW $4CA0, $3800, $0C00
    DW GlowYeild
  DW $000A
    DW $4880, $3800, $0C00
    DW GlowYeild
  DW $000A
    DW $4460, $3400, $0800
    DW GlowYeild
  DW $000A
    DW $4040, $3400, $0800
    DW GlowYeild
  DW $000A
    DW $4460, $3400, $0800
    DW GlowYeild
  DW $000A
    DW $4880, $3800, $0C00
    DW GlowYeild
  DW $000A
    DW $4CA0, $3800, $0C00
    DW GlowYeild
  DW $000A
    DW $50C0, $3C21, $1000
    DW GlowYeild
  DW $000A
    DW $54E0, $3C21, $1000
    DW GlowYeild
  DW $000A
    DW $5901, $4042, $1420
    DW GlowYeild
  DW GlowJMP, Blue_BG_2_List_Loop

Blue_BG_3_List:
  DW SetColorIndex, $00E2
Blue_BG_3_List_Loop:
  DW $000A
    DW $5D22, $4463, $1840
    DW GlowYeild
  DW $000A
    DW $5901, $4042, $1420
    DW GlowYeild
  DW $000A
    DW $54E0, $3C21, $1000
    DW GlowYeild
  DW $000A
    DW $50C0, $3C21, $1000
    DW GlowYeild
  DW $000A
    DW $4CA0, $3800, $0C00
    DW GlowYeild
  DW $000A
    DW $4880, $3800, $0C00
    DW GlowYeild
  DW $000A
    DW $4460, $3400, $0800
    DW GlowYeild
  DW $000A
    DW $4040, $3400, $0800
    DW GlowYeild
  DW $000A
    DW $4460, $3400, $0800
    DW GlowYeild
  DW $000A
    DW $4880, $3800, $0C00
    DW GlowYeild
  DW $000A
    DW $4CA0, $3800, $0C00
    DW GlowYeild
  DW $000A
    DW $50C0, $3C21, $1000
    DW GlowYeild
  DW $000A
    DW $54E0, $3C21, $1000
    DW GlowYeild
  DW $000A
    DW $5901, $4042, $1420
    DW GlowYeild
  DW GlowJMP, Blue_BG_3_List_Loop

Blue_BG_4_List:
  DW SetColorIndex, $00E2
Blue_BG_4_List_Loop:
  DW $000A
    DW $5D22, $4463, $1840
    DW GlowYeild
  DW $000A
    DW $5901, $4042, $1420
    DW GlowYeild
  DW $000A
    DW $54E0, $3C21, $1000
    DW GlowYeild
  DW $000A
    DW $50C0, $3C21, $1000
    DW GlowYeild
  DW $000A
    DW $4CA0, $3800, $0C00
    DW GlowYeild
  DW $000A
    DW $4880, $3800, $0C00
    DW GlowYeild
  DW $000A
    DW $4460, $3400, $0800
    DW GlowYeild
  DW $000A
    DW $4040, $3400, $0800
    DW GlowYeild
  DW $000A
    DW $4460, $3400, $0800
    DW GlowYeild
  DW $000A
    DW $4880, $3800, $0C00
    DW GlowYeild
  DW $000A
    DW $4CA0, $3800, $0C00
    DW GlowYeild
  DW $000A
    DW $50C0, $3C21, $1000
    DW GlowYeild
  DW $000A
    DW $54E0, $3C21, $1000
    DW GlowYeild
  DW $000A
    DW $5901, $4042, $1420
    DW GlowYeild
  DW GlowJMP, Blue_BG_4_List_Loop

Blue_BG_5_List:
  DW SetColorIndex, $00E2
Blue_BG_5_List_Loop:
  DW $000A
    DW $5D22, $4463, $1840
    DW GlowYeild
  DW $000A
    DW $5901, $4042, $1420
    DW GlowYeild
  DW $000A
    DW $54E0, $3C21, $1000
    DW GlowYeild
  DW $000A
    DW $50C0, $3C21, $1000
    DW GlowYeild
  DW $000A
    DW $4CA0, $3800, $0C00
    DW GlowYeild
  DW $000A
    DW $4880, $3800, $0C00
    DW GlowYeild
  DW $000A
    DW $4460, $3400, $0800
    DW GlowYeild
  DW $000A
    DW $4040, $3400, $0800
    DW GlowYeild
  DW $000A
    DW $4460, $3400, $0800
    DW GlowYeild
  DW $000A
    DW $4880, $3800, $0C00
    DW GlowYeild
  DW $000A
    DW $4CA0, $3800, $0C00
    DW GlowYeild
  DW $000A
    DW $50C0, $3C21, $1000
    DW GlowYeild
  DW $000A
    DW $54E0, $3C21, $1000
    DW GlowYeild
  DW $000A
    DW $5901, $4042, $1420
    DW GlowYeild
  DW GlowJMP, Blue_BG_5_List_Loop

Blue_BG_6_List:
  DW SetColorIndex, $00E2
Blue_BG_6_List_Loop:
  DW $000A
    DW $5D22, $4463, $1840
    DW GlowYeild
  DW $000A
    DW $5901, $4042, $1420
    DW GlowYeild
  DW $000A
    DW $54E0, $3C21, $1000
    DW GlowYeild
  DW $000A
    DW $50C0, $3C21, $1000
    DW GlowYeild
  DW $000A
    DW $4CA0, $3800, $0C00
    DW GlowYeild
  DW $000A
    DW $4880, $3800, $0C00
    DW GlowYeild
  DW $000A
    DW $4460, $3400, $0800
    DW GlowYeild
  DW $000A
    DW $4040, $3400, $0800
    DW GlowYeild
  DW $000A
    DW $4460, $3400, $0800
    DW GlowYeild
  DW $000A
    DW $4880, $3800, $0C00
    DW GlowYeild
  DW $000A
    DW $4CA0, $3800, $0C00
    DW GlowYeild
  DW $000A
    DW $50C0, $3C21, $1000
    DW GlowYeild
  DW $000A
    DW $54E0, $3C21, $1000
    DW GlowYeild
  DW $000A
    DW $5901, $4042, $1420
    DW GlowYeild
  DW GlowJMP, Blue_BG_6_List_Loop

Blue_BG_7_List:
  DW SetColorIndex, $00E2
Blue_BG_7_List_Loop:
  DW $000A
    DW $5D22, $4463, $1840
    DW GlowYeild
  DW $000A
    DW $5901, $4042, $1420
    DW GlowYeild
  DW $000A
    DW $54E0, $3C21, $1000
    DW GlowYeild
  DW $000A
    DW $50C0, $3C21, $1000
    DW GlowYeild
  DW $000A
    DW $4CA0, $3800, $0C00
    DW GlowYeild
  DW $000A
    DW $4880, $3800, $0C00
    DW GlowYeild
  DW $000A
    DW $4460, $3400, $0800
    DW GlowYeild
  DW $000A
    DW $4040, $3400, $0800
    DW GlowYeild
  DW $000A
    DW $4460, $3400, $0800
    DW GlowYeild
  DW $000A
    DW $4880, $3800, $0C00
    DW GlowYeild
  DW $000A
    DW $4CA0, $3800, $0C00
    DW GlowYeild
  DW $000A
    DW $50C0, $3C21, $1000
    DW GlowYeild
  DW $000A
    DW $54E0, $3C21, $1000
    DW GlowYeild
  DW $000A
    DW $5901, $4042, $1420
    DW GlowYeild
  DW GlowJMP, Blue_BG_7_List_Loop

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
SpoSpoBG0_List:
  DW SetPreInstruction, SpoSpoBGPreInstruction
  DW GlowJMP, Blue_BG_0_List_Loop
SpoSpoBG1_List:
  DW SetPreInstruction, SpoSpoBGPreInstruction
  DW GlowJMP, Blue_BG_1_List_Loop
SpoSpoBG2_List:
  DW SetPreInstruction, SpoSpoBGPreInstruction
  DW GlowJMP, Blue_BG_2_List_Loop
SpoSpoBG3_List:
  DW SetPreInstruction, SpoSpoBGPreInstruction
  DW GlowJMP, Blue_BG_3_List_Loop
SpoSpoBG4_List:
  DW SetPreInstruction, SpoSpoBGPreInstruction
  DW GlowJMP, Blue_BG_4_List_Loop
SpoSpoBG5_List:
  DW SetPreInstruction, SpoSpoBGPreInstruction
  DW GlowJMP, Blue_BG_5_List_Loop
SpoSpoBG6_List:
  DW SetPreInstruction, SpoSpoBGPreInstruction
  DW GlowJMP, Blue_BG_6_List_Loop
SpoSpoBG7_List:
  DW SetPreInstruction, SpoSpoBGPreInstruction
  DW GlowJMP, Blue_BG_7_List_Loop

Purp_BG_Table:
  DW EmptyInit,Purp_BG_0_List, EmptyInit,Purp_BG_1_List, EmptyInit,Purp_BG_2_List, EmptyInit,Purp_BG_3_List
  DW EmptyInit,Purp_BG_4_List, EmptyInit,Purp_BG_5_List, EmptyInit,Purp_BG_6_List, EmptyInit,Purp_BG_7_List
Purp_BG_0_List:
  DW SetColorIndex, $00C8
Purp_BG_0_List_Loop:
  DW $000A
    DW $4C17, $280F, $2409, $1C07, $1405, $0C03, $0802, $0401
    DW GlowYeild
  DW $000A
    DW $4816, $240E, $2008, $1806, $1004, $0802, $0401, $0000
    DW GlowYeild
  DW $000A
    DW $4415, $200D, $1C07, $1405, $0C03, $0401, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $4014, $1C0C, $1806, $1004, $0802, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3C13, $180B, $1405, $0C03, $0401, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3812, $140A, $1004, $0802, $0000, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3411, $1009, $0C03, $0401, $0000, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3010, $0C08, $0802, $0000, $0000, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3411, $1009, $0C03, $0401, $0000, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3812, $140A, $1004, $0802, $0000, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3C13, $180B, $1405, $0C03, $0401, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $4014, $1C0C, $1806, $1004, $0802, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $4415, $200D, $1C07, $1405, $0C03, $0401, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $4816, $240E, $2008, $1806, $1004, $0802, $0401, $0000
    DW GlowYeild
  DW GlowJMP, Purp_BG_0_List_Loop

Purp_BG_1_List:
  DW SetColorIndex, $00C8
Purp_BG_1_List_Loop:
  DW $000A
    DW $4C17, $280F, $2409, $1C07, $1405, $0C03, $0802, $0401
    DW GlowYeild
  DW $000A
    DW $4816, $240E, $2008, $1806, $1004, $0802, $0401, $0000
    DW GlowYeild
  DW $000A
    DW $4415, $200D, $1C07, $1405, $0C03, $0401, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $4014, $1C0C, $1806, $1004, $0802, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3C13, $180B, $1405, $0C03, $0401, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3812, $140A, $1004, $0802, $0000, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3411, $1009, $0C03, $0401, $0000, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3010, $0C08, $0802, $0000, $0000, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3411, $1009, $0C03, $0401, $0000, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3812, $140A, $1004, $0802, $0000, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3C13, $180B, $1405, $0C03, $0401, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $4014, $1C0C, $1806, $1004, $0802, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $4415, $200D, $1C07, $1405, $0C03, $0401, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $4816, $240E, $2008, $1806, $1004, $0802, $0401, $0000
    DW GlowYeild
  DW GlowJMP, Purp_BG_1_List_Loop

Purp_BG_2_List:
  DW SetColorIndex, $00C8
Purp_BG_2_List_Loop:
  DW $000A
    DW $4C17, $280F, $2409, $1C07, $1405, $0C03, $0802, $0401
    DW GlowYeild
  DW $000A
    DW $4816, $240E, $2008, $1806, $1004, $0802, $0401, $0000
    DW GlowYeild
  DW $000A
    DW $4415, $200D, $1C07, $1405, $0C03, $0401, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $4014, $1C0C, $1806, $1004, $0802, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3C13, $180B, $1405, $0C03, $0401, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3812, $140A, $1004, $0802, $0000, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3411, $1009, $0C03, $0401, $0000, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3010, $0C08, $0802, $0000, $0000, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3411, $1009, $0C03, $0401, $0000, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3812, $140A, $1004, $0802, $0000, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3C13, $180B, $1405, $0C03, $0401, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $4014, $1C0C, $1806, $1004, $0802, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $4415, $200D, $1C07, $1405, $0C03, $0401, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $4816, $240E, $2008, $1806, $1004, $0802, $0401, $0000
    DW GlowYeild
  DW GlowJMP, Purp_BG_2_List_Loop

Purp_BG_3_List:
  DW SetColorIndex, $00C8
Purp_BG_3_List_Loop:
  DW $000A
    DW $4C17, $280F, $2409, $1C07, $1405, $0C03, $0802, $0401
    DW GlowYeild
  DW $000A
    DW $4816, $240E, $2008, $1806, $1004, $0802, $0401, $0000
    DW GlowYeild
  DW $000A
    DW $4415, $200D, $1C07, $1405, $0C03, $0401, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $4014, $1C0C, $1806, $1004, $0802, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3C13, $180B, $1405, $0C03, $0401, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3812, $140A, $1004, $0802, $0000, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3411, $1009, $0C03, $0401, $0000, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3010, $0C08, $0802, $0000, $0000, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3411, $1009, $0C03, $0401, $0000, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3812, $140A, $1004, $0802, $0000, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3C13, $180B, $1405, $0C03, $0401, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $4014, $1C0C, $1806, $1004, $0802, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $4415, $200D, $1C07, $1405, $0C03, $0401, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $4816, $240E, $2008, $1806, $1004, $0802, $0401, $0000
    DW GlowYeild
  DW GlowJMP, Purp_BG_3_List_Loop

Purp_BG_4_List:
  DW SetColorIndex, $00C8
Purp_BG_4_List_Loop:
  DW $000A
    DW $4C17, $280F, $2409, $1C07, $1405, $0C03, $0802, $0401
    DW GlowYeild
  DW $000A
    DW $4816, $240E, $2008, $1806, $1004, $0802, $0401, $0000
    DW GlowYeild
  DW $000A
    DW $4415, $200D, $1C07, $1405, $0C03, $0401, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $4014, $1C0C, $1806, $1004, $0802, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3C13, $180B, $1405, $0C03, $0401, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3812, $140A, $1004, $0802, $0000, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3411, $1009, $0C03, $0401, $0000, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3010, $0C08, $0802, $0000, $0000, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3411, $1009, $0C03, $0401, $0000, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3812, $140A, $1004, $0802, $0000, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3C13, $180B, $1405, $0C03, $0401, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $4014, $1C0C, $1806, $1004, $0802, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $4415, $200D, $1C07, $1405, $0C03, $0401, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $4816, $240E, $2008, $1806, $1004, $0802, $0401, $0000
    DW GlowYeild
  DW GlowJMP, Purp_BG_4_List_Loop

Purp_BG_5_List:
  DW SetColorIndex, $00C8
Purp_BG_5_List_Loop:
  DW $000A
    DW $4C17, $280F, $2409, $1C07, $1405, $0C03, $0802, $0401
    DW GlowYeild
  DW $000A
    DW $4816, $240E, $2008, $1806, $1004, $0802, $0401, $0000
    DW GlowYeild
  DW $000A
    DW $4415, $200D, $1C07, $1405, $0C03, $0401, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $4014, $1C0C, $1806, $1004, $0802, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3C13, $180B, $1405, $0C03, $0401, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3812, $140A, $1004, $0802, $0000, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3411, $1009, $0C03, $0401, $0000, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3010, $0C08, $0802, $0000, $0000, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3411, $1009, $0C03, $0401, $0000, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3812, $140A, $1004, $0802, $0000, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3C13, $180B, $1405, $0C03, $0401, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $4014, $1C0C, $1806, $1004, $0802, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $4415, $200D, $1C07, $1405, $0C03, $0401, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $4816, $240E, $2008, $1806, $1004, $0802, $0401, $0000
    DW GlowYeild
  DW GlowJMP, Purp_BG_5_List_Loop

Purp_BG_6_List:
  DW SetColorIndex, $00C8
Purp_BG_6_List_Loop:
  DW $000A
    DW $4C17, $280F, $2409, $1C07, $1405, $0C03, $0802, $0401
    DW GlowYeild
  DW $000A
    DW $4816, $240E, $2008, $1806, $1004, $0802, $0401, $0000
    DW GlowYeild
  DW $000A
    DW $4415, $200D, $1C07, $1405, $0C03, $0401, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $4014, $1C0C, $1806, $1004, $0802, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3C13, $180B, $1405, $0C03, $0401, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3812, $140A, $1004, $0802, $0000, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3411, $1009, $0C03, $0401, $0000, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3010, $0C08, $0802, $0000, $0000, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3411, $1009, $0C03, $0401, $0000, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3812, $140A, $1004, $0802, $0000, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3C13, $180B, $1405, $0C03, $0401, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $4014, $1C0C, $1806, $1004, $0802, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $4415, $200D, $1C07, $1405, $0C03, $0401, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $4816, $240E, $2008, $1806, $1004, $0802, $0401, $0000
    DW GlowYeild
  DW GlowJMP, Purp_BG_6_List_Loop

Purp_BG_7_List:
  DW SetColorIndex, $00C8
Purp_BG_7_List_Loop:
  DW $000A
    DW $4C17, $280F, $2409, $1C07, $1405, $0C03, $0802, $0401
    DW GlowYeild
  DW $000A
    DW $4816, $240E, $2008, $1806, $1004, $0802, $0401, $0000
    DW GlowYeild
  DW $000A
    DW $4415, $200D, $1C07, $1405, $0C03, $0401, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $4014, $1C0C, $1806, $1004, $0802, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3C13, $180B, $1405, $0C03, $0401, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3812, $140A, $1004, $0802, $0000, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3411, $1009, $0C03, $0401, $0000, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3010, $0C08, $0802, $0000, $0000, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3411, $1009, $0C03, $0401, $0000, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3812, $140A, $1004, $0802, $0000, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $3C13, $180B, $1405, $0C03, $0401, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $4014, $1C0C, $1806, $1004, $0802, $0000, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $4415, $200D, $1C07, $1405, $0C03, $0401, $0000, $0000
    DW GlowYeild
  DW $000A
    DW $4816, $240E, $2008, $1806, $1004, $0802, $0401, $0000
    DW GlowYeild
  DW GlowJMP, Purp_BG_7_List_Loop

Beacon__Table:
  DW EmptyInit,Beacon__0_List, EmptyInit,Beacon__1_List, EmptyInit,Beacon__2_List, EmptyInit,Beacon__3_List
  DW EmptyInit,Beacon__4_List, EmptyInit,Beacon__5_List, EmptyInit,Beacon__6_List, EmptyInit,Beacon__7_List
Beacon__0_List:
Beacon__7_List:
  DW SetColorIndex, $00E2
Beacon__0_List_Loop:
  DW $000A
    DW $02BF, $017F, $0015
    DW SkipColors_9
    DW $7FFF
    DW GlowYeild
  DW $000A
    DW $023B, $00FB, $0011
    DW SkipColors_9
    DW $739C
    DW GlowYeild
  DW $000A
    DW $01D8, $0098, $000E
    DW SkipColors_9
    DW $5AD6
    DW GlowYeild
  DW $000A
    DW $0154, $0055, $000B
    DW SkipColors_9
    DW $4E73
    DW GlowYeild
  DW $000A
    DW $00D0, $0010, $0007
    DW SkipColors_9
    DW $4631
    DW GlowYeild
  DW $000A
    DW $00AA, $000B, $0004
    DW SkipColors_9
    DW $3DEF
    DW GlowYeild
  DW PlaySFX : DB $18
  DW $000A
    DW $00D0, $0010, $0007
    DW SkipColors_9
    DW $4631
    DW GlowYeild
  DW $000A
    DW $0154, $0055, $000B
    DW SkipColors_9
    DW $4E73
    DW GlowYeild
  DW $000A
    DW $01D8, $0098, $000E
    DW SkipColors_9
    DW $5AD6
    DW GlowYeild
  DW $000A
    DW $023B, $00FB, $0011
    DW SkipColors_9
    DW $739C
    DW GlowYeild
  DW GlowJMP, Beacon__0_List_Loop

Beacon__1_List:
  DW SetColorIndex, $00E2
Beacon__1_List_Loop:
  DW $000A
    DW $02BF, $017F, $0015
    DW SkipColors_9
    DW $7FFF
    DW GlowYeild
  DW $000A
    DW $023B, $00FB, $0011
    DW SkipColors_9
    DW $739C
    DW GlowYeild
  DW $000A
    DW $01D8, $0098, $000E
    DW SkipColors_9
    DW $5AD6
    DW GlowYeild
  DW $000A
    DW $0154, $0055, $000B
    DW SkipColors_9
    DW $4E73
    DW GlowYeild
  DW $000A
    DW $00D0, $0010, $0007
    DW SkipColors_9
    DW $4631
    DW GlowYeild
  DW $000A
    DW $00AA, $000B, $0004
    DW SkipColors_9
    DW $3DEF
    DW GlowYeild
  DW PlaySFX : DB $18
  DW $000A
    DW $00D0, $0010, $0007
    DW SkipColors_9
    DW $4631
    DW GlowYeild
  DW $000A
    DW $0154, $0055, $000B
    DW SkipColors_9
    DW $4E73
    DW GlowYeild
  DW $000A
    DW $01D8, $0098, $000E
    DW SkipColors_9
    DW $5AD6
    DW GlowYeild
  DW $000A
    DW $023B, $00FB, $0011
    DW SkipColors_9
    DW $739C
    DW GlowYeild
  DW GlowJMP, Beacon__1_List_Loop

Beacon__2_List:
  DW SetColorIndex, $00E2
Beacon__2_List_Loop:
  DW $000A
    DW $02BF, $017F, $0015
    DW SkipColors_9
    DW $7FFF
    DW GlowYeild
  DW $000A
    DW $023B, $00FB, $0011
    DW SkipColors_9
    DW $739C
    DW GlowYeild
  DW $000A
    DW $01D8, $0098, $000E
    DW SkipColors_9
    DW $5AD6
    DW GlowYeild
  DW $000A
    DW $0154, $0055, $000B
    DW SkipColors_9
    DW $4E73
    DW GlowYeild
  DW $000A
    DW $00D0, $0010, $0007
    DW SkipColors_9
    DW $4631
    DW GlowYeild
  DW $000A
    DW $00AA, $000B, $0004
    DW SkipColors_9
    DW $3DEF
    DW GlowYeild
  DW PlaySFX : DB $18
  DW $000A
    DW $00D0, $0010, $0007
    DW SkipColors_9
    DW $4631
    DW GlowYeild
  DW $000A
    DW $0154, $0055, $000B
    DW SkipColors_9
    DW $4E73
    DW GlowYeild
  DW $000A
    DW $01D8, $0098, $000E
    DW SkipColors_9
    DW $5AD6
    DW GlowYeild
  DW $000A
    DW $023B, $00FB, $0011
    DW SkipColors_9
    DW $739C
    DW GlowYeild
  DW GlowJMP, Beacon__2_List_Loop

Beacon__3_List:
  DW SetColorIndex, $00E2
Beacon__3_List_Loop:
  DW $000A
    DW $02BF, $017F, $0015
    DW SkipColors_9
    DW $7FFF
    DW GlowYeild
  DW $000A
    DW $023B, $00FB, $0011
    DW SkipColors_9
    DW $739C
    DW GlowYeild
  DW $000A
    DW $01D8, $0098, $000E
    DW SkipColors_9
    DW $5AD6
    DW GlowYeild
  DW $000A
    DW $0154, $0055, $000B
    DW SkipColors_9
    DW $4E73
    DW GlowYeild
  DW $000A
    DW $00D0, $0010, $0007
    DW SkipColors_9
    DW $4631
    DW GlowYeild
  DW $000A
    DW $00AA, $000B, $0004
    DW SkipColors_9
    DW $3DEF
    DW GlowYeild
  DW PlaySFX : DB $18
  DW $000A
    DW $00D0, $0010, $0007
    DW SkipColors_9
    DW $4631
    DW GlowYeild
  DW $000A
    DW $0154, $0055, $000B
    DW SkipColors_9
    DW $4E73
    DW GlowYeild
  DW $000A
    DW $01D8, $0098, $000E
    DW SkipColors_9
    DW $5AD6
    DW GlowYeild
  DW $000A
    DW $023B, $00FB, $0011
    DW SkipColors_9
    DW $739C
    DW GlowYeild
  DW GlowJMP, Beacon__3_List_Loop

Beacon__4_List:
  DW SetColorIndex, $00E2
Beacon__4_List_Loop:
  DW $000A
    DW $02BF, $017F, $0015
    DW SkipColors_9
    DW $7FFF
    DW GlowYeild
  DW $000A
    DW $023B, $00FB, $0011
    DW SkipColors_9
    DW $739C
    DW GlowYeild
  DW $000A
    DW $01D8, $0098, $000E
    DW SkipColors_9
    DW $5AD6
    DW GlowYeild
  DW $000A
    DW $0154, $0055, $000B
    DW SkipColors_9
    DW $4E73
    DW GlowYeild
  DW $000A
    DW $00D0, $0010, $0007
    DW SkipColors_9
    DW $4631
    DW GlowYeild
  DW $000A
    DW $00AA, $000B, $0004
    DW SkipColors_9
    DW $3DEF
    DW GlowYeild
  DW PlaySFX : DB $18
  DW $000A
    DW $00D0, $0010, $0007
    DW SkipColors_9
    DW $4631
    DW GlowYeild
  DW $000A
    DW $0154, $0055, $000B
    DW SkipColors_9
    DW $4E73
    DW GlowYeild
  DW $000A
    DW $01D8, $0098, $000E
    DW SkipColors_9
    DW $5AD6
    DW GlowYeild
  DW $000A
    DW $023B, $00FB, $0011
    DW SkipColors_9
    DW $739C
    DW GlowYeild
  DW GlowJMP, Beacon__4_List_Loop

Beacon__5_List:
  DW SetColorIndex, $00E2
Beacon__5_List_Loop:
  DW $000A
    DW $02BF, $017F, $0015
    DW SkipColors_9
    DW $7FFF
    DW GlowYeild
  DW $000A
    DW $023B, $00FB, $0011
    DW SkipColors_9
    DW $739C
    DW GlowYeild
  DW $000A
    DW $01D8, $0098, $000E
    DW SkipColors_9
    DW $5AD6
    DW GlowYeild
  DW $000A
    DW $0154, $0055, $000B
    DW SkipColors_9
    DW $4E73
    DW GlowYeild
  DW $000A
    DW $00D0, $0010, $0007
    DW SkipColors_9
    DW $4631
    DW GlowYeild
  DW $000A
    DW $00AA, $000B, $0004
    DW SkipColors_9
    DW $3DEF
    DW GlowYeild
  DW PlaySFX : DB $18
  DW $000A
    DW $00D0, $0010, $0007
    DW SkipColors_9
    DW $4631
    DW GlowYeild
  DW $000A
    DW $0154, $0055, $000B
    DW SkipColors_9
    DW $4E73
    DW GlowYeild
  DW $000A
    DW $01D8, $0098, $000E
    DW SkipColors_9
    DW $5AD6
    DW GlowYeild
  DW $000A
    DW $023B, $00FB, $0011
    DW SkipColors_9
    DW $739C
    DW GlowYeild
  DW GlowJMP, Beacon__5_List_Loop

Beacon__6_List:
  DW SetColorIndex, $00E2
Beacon__6_List_Loop:
  DW $000A
    DW $02BF, $017F, $0015
    DW SkipColors_9
    DW $7FFF
    DW GlowYeild
  DW $000A
    DW $023B, $00FB, $0011
    DW SkipColors_9
    DW $739C
    DW GlowYeild
  DW $000A
    DW $01D8, $0098, $000E
    DW SkipColors_9
    DW $5AD6
    DW GlowYeild
  DW $000A
    DW $0154, $0055, $000B
    DW SkipColors_9
    DW $4E73
    DW GlowYeild
  DW $000A
    DW $00D0, $0010, $0007
    DW SkipColors_9
    DW $4631
    DW GlowYeild
  DW $000A
    DW $00AA, $000B, $0004
    DW SkipColors_9
    DW $3DEF
    DW GlowYeild
  DW PlaySFX : DB $18
  DW $000A
    DW $00D0, $0010, $0007
    DW SkipColors_9
    DW $4631
    DW GlowYeild
  DW $000A
    DW $0154, $0055, $000B
    DW SkipColors_9
    DW $4E73
    DW GlowYeild
  DW $000A
    DW $01D8, $0098, $000E
    DW SkipColors_9
    DW $5AD6
    DW GlowYeild
  DW $000A
    DW $023B, $00FB, $0011
    DW SkipColors_9
    DW $739C
    DW GlowYeild
  DW GlowJMP, Beacon__6_List_Loop

; Norfair tileset glows

SetHeatGlowSync:
  LDA $0000,Y
  AND #$00FF
  STA $1EED
  INY
  RTS

NorHot1_Table:
  DW EmptyInit,NorHot1_0_List, EmptyInit,NorHot1_1_List, EmptyInit,NorHot1_2_List, EmptyInit,NorHot1_3_List
  DW EmptyInit,NorHot1_4_List, EmptyInit,NorHot1_5_List, EmptyInit,NorHot1_6_List, EmptyInit,NorHot1_7_List
NorHot1_0_List:
NorHot1_7_List:
  DW SetColorIndex, $006A
NorHot1_0_List_Loop:
  DW SetHeatGlowSync : DB $00
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_4
    DW $09FD, $4A52
    DW GlowYeild
  DW SetHeatGlowSync : DB $01
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_4
    DW $0E3D, $4214
    DW GlowYeild
  DW SetHeatGlowSync : DB $02
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_4
    DW $165E, $39F5
    DW GlowYeild
  DW SetHeatGlowSync : DB $03
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_4
    DW $1A9E, $31D7
    DW GlowYeild
  DW SetHeatGlowSync : DB $04
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_4
    DW $1EBE, $29D9
    DW GlowYeild
  DW SetHeatGlowSync : DB $05
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_4
    DW $22FE, $21BA
    DW GlowYeild
  DW SetHeatGlowSync : DB $06
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_4
    DW $2B1F, $199C
    DW GlowYeild
  DW SetHeatGlowSync : DB $07
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_4
    DW $2F5F, $0D7F
    DW GlowYeild
  DW SetHeatGlowSync : DB $08
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_4
    DW $2F5F, $0D7F
    DW GlowYeild
  DW SetHeatGlowSync : DB $09
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_4
    DW $2B1F, $199C
    DW GlowYeild
  DW SetHeatGlowSync : DB $0A
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_4
    DW $22FE, $21BA
    DW GlowYeild
  DW SetHeatGlowSync : DB $0B
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_4
    DW $1EBE, $29D9
    DW GlowYeild
  DW SetHeatGlowSync : DB $0C
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_4
    DW $1A9E, $31D7
    DW GlowYeild
  DW SetHeatGlowSync : DB $0D
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_4
    DW $165E, $39F5
    DW GlowYeild
  DW SetHeatGlowSync : DB $0E
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_4
    DW $0E3D, $4214
    DW GlowYeild
  DW SetHeatGlowSync : DB $0F
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_4
    DW $09FD, $4A52
    DW GlowYeild
  DW GlowJMP, NorHot1_0_List_Loop

NorHot1_1_List:
  DW SetColorIndex, $006A
NorHot1_1_List_Loop:
  DW SetHeatGlowSync : DB $00
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_4
    DW $09FD, $4A52
    DW GlowYeild
  DW SetHeatGlowSync : DB $01
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_4
    DW $0E3D, $4214
    DW GlowYeild
  DW SetHeatGlowSync : DB $02
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_4
    DW $165E, $39F5
    DW GlowYeild
  DW SetHeatGlowSync : DB $03
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_4
    DW $1A9E, $31D7
    DW GlowYeild
  DW SetHeatGlowSync : DB $04
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_4
    DW $1EBE, $29D9
    DW GlowYeild
  DW SetHeatGlowSync : DB $05
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_4
    DW $22FE, $21BA
    DW GlowYeild
  DW SetHeatGlowSync : DB $06
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_4
    DW $2B1F, $199C
    DW GlowYeild
  DW SetHeatGlowSync : DB $07
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_4
    DW $2F5F, $0D7F
    DW GlowYeild
  DW SetHeatGlowSync : DB $08
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_4
    DW $2F5F, $0D7F
    DW GlowYeild
  DW SetHeatGlowSync : DB $09
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_4
    DW $2B1F, $199C
    DW GlowYeild
  DW SetHeatGlowSync : DB $0A
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_4
    DW $22FE, $21BA
    DW GlowYeild
  DW SetHeatGlowSync : DB $0B
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_4
    DW $1EBE, $29D9
    DW GlowYeild
  DW SetHeatGlowSync : DB $0C
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_4
    DW $1A9E, $31D7
    DW GlowYeild
  DW SetHeatGlowSync : DB $0D
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_4
    DW $165E, $39F5
    DW GlowYeild
  DW SetHeatGlowSync : DB $0E
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_4
    DW $0E3D, $4214
    DW GlowYeild
  DW SetHeatGlowSync : DB $0F
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_4
    DW $09FD, $4A52
    DW GlowYeild
  DW GlowJMP, NorHot1_1_List_Loop

NorHot1_2_List:
  DW SetColorIndex, $006A
NorHot1_2_List_Loop:
  DW SetHeatGlowSync : DB $00
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_4
    DW $09FD, $4A52
    DW GlowYeild
  DW SetHeatGlowSync : DB $01
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_4
    DW $0E3D, $4214
    DW GlowYeild
  DW SetHeatGlowSync : DB $02
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_4
    DW $165E, $39F5
    DW GlowYeild
  DW SetHeatGlowSync : DB $03
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_4
    DW $1A9E, $31D7
    DW GlowYeild
  DW SetHeatGlowSync : DB $04
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_4
    DW $1EBE, $29D9
    DW GlowYeild
  DW SetHeatGlowSync : DB $05
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_4
    DW $22FE, $21BA
    DW GlowYeild
  DW SetHeatGlowSync : DB $06
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_4
    DW $2B1F, $199C
    DW GlowYeild
  DW SetHeatGlowSync : DB $07
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_4
    DW $2F5F, $0D7F
    DW GlowYeild
  DW SetHeatGlowSync : DB $08
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_4
    DW $2F5F, $0D7F
    DW GlowYeild
  DW SetHeatGlowSync : DB $09
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_4
    DW $2B1F, $199C
    DW GlowYeild
  DW SetHeatGlowSync : DB $0A
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_4
    DW $22FE, $21BA
    DW GlowYeild
  DW SetHeatGlowSync : DB $0B
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_4
    DW $1EBE, $29D9
    DW GlowYeild
  DW SetHeatGlowSync : DB $0C
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_4
    DW $1A9E, $31D7
    DW GlowYeild
  DW SetHeatGlowSync : DB $0D
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_4
    DW $165E, $39F5
    DW GlowYeild
  DW SetHeatGlowSync : DB $0E
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_4
    DW $0E3D, $4214
    DW GlowYeild
  DW SetHeatGlowSync : DB $0F
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_4
    DW $09FD, $4A52
    DW GlowYeild
  DW GlowJMP, NorHot1_2_List_Loop

NorHot1_3_List:
  DW SetColorIndex, $006A
NorHot1_3_List_Loop:
  DW SetHeatGlowSync : DB $00
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_4
    DW $09FD, $4A52
    DW GlowYeild
  DW SetHeatGlowSync : DB $01
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_4
    DW $0E3D, $4214
    DW GlowYeild
  DW SetHeatGlowSync : DB $02
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_4
    DW $165E, $39F5
    DW GlowYeild
  DW SetHeatGlowSync : DB $03
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_4
    DW $1A9E, $31D7
    DW GlowYeild
  DW SetHeatGlowSync : DB $04
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_4
    DW $1EBE, $29D9
    DW GlowYeild
  DW SetHeatGlowSync : DB $05
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_4
    DW $22FE, $21BA
    DW GlowYeild
  DW SetHeatGlowSync : DB $06
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_4
    DW $2B1F, $199C
    DW GlowYeild
  DW SetHeatGlowSync : DB $07
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_4
    DW $2F5F, $0D7F
    DW GlowYeild
  DW SetHeatGlowSync : DB $08
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_4
    DW $2F5F, $0D7F
    DW GlowYeild
  DW SetHeatGlowSync : DB $09
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_4
    DW $2B1F, $199C
    DW GlowYeild
  DW SetHeatGlowSync : DB $0A
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_4
    DW $22FE, $21BA
    DW GlowYeild
  DW SetHeatGlowSync : DB $0B
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_4
    DW $1EBE, $29D9
    DW GlowYeild
  DW SetHeatGlowSync : DB $0C
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_4
    DW $1A9E, $31D7
    DW GlowYeild
  DW SetHeatGlowSync : DB $0D
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_4
    DW $165E, $39F5
    DW GlowYeild
  DW SetHeatGlowSync : DB $0E
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_4
    DW $0E3D, $4214
    DW GlowYeild
  DW SetHeatGlowSync : DB $0F
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_4
    DW $09FD, $4A52
    DW GlowYeild
  DW GlowJMP, NorHot1_3_List_Loop

NorHot1_4_List:
  DW SetColorIndex, $006A
NorHot1_4_List_Loop:
  DW SetHeatGlowSync : DB $00
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_4
    DW $09FD, $4A52
    DW GlowYeild
  DW SetHeatGlowSync : DB $01
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_4
    DW $0E3D, $4214
    DW GlowYeild
  DW SetHeatGlowSync : DB $02
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_4
    DW $165E, $39F5
    DW GlowYeild
  DW SetHeatGlowSync : DB $03
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_4
    DW $1A9E, $31D7
    DW GlowYeild
  DW SetHeatGlowSync : DB $04
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_4
    DW $1EBE, $29D9
    DW GlowYeild
  DW SetHeatGlowSync : DB $05
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_4
    DW $22FE, $21BA
    DW GlowYeild
  DW SetHeatGlowSync : DB $06
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_4
    DW $2B1F, $199C
    DW GlowYeild
  DW SetHeatGlowSync : DB $07
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_4
    DW $2F5F, $0D7F
    DW GlowYeild
  DW SetHeatGlowSync : DB $08
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_4
    DW $2F5F, $0D7F
    DW GlowYeild
  DW SetHeatGlowSync : DB $09
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_4
    DW $2B1F, $199C
    DW GlowYeild
  DW SetHeatGlowSync : DB $0A
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_4
    DW $22FE, $21BA
    DW GlowYeild
  DW SetHeatGlowSync : DB $0B
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_4
    DW $1EBE, $29D9
    DW GlowYeild
  DW SetHeatGlowSync : DB $0C
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_4
    DW $1A9E, $31D7
    DW GlowYeild
  DW SetHeatGlowSync : DB $0D
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_4
    DW $165E, $39F5
    DW GlowYeild
  DW SetHeatGlowSync : DB $0E
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_4
    DW $0E3D, $4214
    DW GlowYeild
  DW SetHeatGlowSync : DB $0F
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_4
    DW $09FD, $4A52
    DW GlowYeild
  DW GlowJMP, NorHot1_4_List_Loop

NorHot1_5_List:
  DW SetColorIndex, $006A
NorHot1_5_List_Loop:
  DW SetHeatGlowSync : DB $00
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_4
    DW $09FD, $4A52
    DW GlowYeild
  DW SetHeatGlowSync : DB $01
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_4
    DW $0E3D, $4214
    DW GlowYeild
  DW SetHeatGlowSync : DB $02
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_4
    DW $165E, $39F5
    DW GlowYeild
  DW SetHeatGlowSync : DB $03
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_4
    DW $1A9E, $31D7
    DW GlowYeild
  DW SetHeatGlowSync : DB $04
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_4
    DW $1EBE, $29D9
    DW GlowYeild
  DW SetHeatGlowSync : DB $05
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_4
    DW $22FE, $21BA
    DW GlowYeild
  DW SetHeatGlowSync : DB $06
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_4
    DW $2B1F, $199C
    DW GlowYeild
  DW SetHeatGlowSync : DB $07
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_4
    DW $2F5F, $0D7F
    DW GlowYeild
  DW SetHeatGlowSync : DB $08
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_4
    DW $2F5F, $0D7F
    DW GlowYeild
  DW SetHeatGlowSync : DB $09
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_4
    DW $2B1F, $199C
    DW GlowYeild
  DW SetHeatGlowSync : DB $0A
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_4
    DW $22FE, $21BA
    DW GlowYeild
  DW SetHeatGlowSync : DB $0B
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_4
    DW $1EBE, $29D9
    DW GlowYeild
  DW SetHeatGlowSync : DB $0C
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_4
    DW $1A9E, $31D7
    DW GlowYeild
  DW SetHeatGlowSync : DB $0D
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_4
    DW $165E, $39F5
    DW GlowYeild
  DW SetHeatGlowSync : DB $0E
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_4
    DW $0E3D, $4214
    DW GlowYeild
  DW SetHeatGlowSync : DB $0F
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_4
    DW $09FD, $4A52
    DW GlowYeild
  DW GlowJMP, NorHot1_5_List_Loop

NorHot1_6_List:
  DW SetColorIndex, $006A
NorHot1_6_List_Loop:
  DW SetHeatGlowSync : DB $00
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_4
    DW $09FD, $4A52
    DW GlowYeild
  DW SetHeatGlowSync : DB $01
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_4
    DW $0E3D, $4214
    DW GlowYeild
  DW SetHeatGlowSync : DB $02
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_4
    DW $165E, $39F5
    DW GlowYeild
  DW SetHeatGlowSync : DB $03
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_4
    DW $1A9E, $31D7
    DW GlowYeild
  DW SetHeatGlowSync : DB $04
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_4
    DW $1EBE, $29D9
    DW GlowYeild
  DW SetHeatGlowSync : DB $05
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_4
    DW $22FE, $21BA
    DW GlowYeild
  DW SetHeatGlowSync : DB $06
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_4
    DW $2B1F, $199C
    DW GlowYeild
  DW SetHeatGlowSync : DB $07
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_4
    DW $2F5F, $0D7F
    DW GlowYeild
  DW SetHeatGlowSync : DB $08
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_4
    DW $2F5F, $0D7F
    DW GlowYeild
  DW SetHeatGlowSync : DB $09
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_4
    DW $2B1F, $199C
    DW GlowYeild
  DW SetHeatGlowSync : DB $0A
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_4
    DW $22FE, $21BA
    DW GlowYeild
  DW SetHeatGlowSync : DB $0B
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_4
    DW $1EBE, $29D9
    DW GlowYeild
  DW SetHeatGlowSync : DB $0C
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_4
    DW $1A9E, $31D7
    DW GlowYeild
  DW SetHeatGlowSync : DB $0D
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_4
    DW $165E, $39F5
    DW GlowYeild
  DW SetHeatGlowSync : DB $0E
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_4
    DW $0E3D, $4214
    DW GlowYeild
  DW SetHeatGlowSync : DB $0F
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_4
    DW $09FD, $4A52
    DW GlowYeild
  DW GlowJMP, NorHot1_6_List_Loop

NorHot2_Table:
  DW EmptyInit,NorHot2_1_List, EmptyInit,NorHot2_1_List, EmptyInit,NorHot2_2_List, EmptyInit,NorHot2_3_List
  DW EmptyInit,NorHot2_4_List, EmptyInit,NorHot2_5_List, EmptyInit,NorHot2_6_List, EmptyInit,NorHot2_7_List
NorHot2_0_List:
NorHot2_7_List:
  DW SetColorIndex, $0082
NorHot2_0_List_Loop:
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_8
    DW $4309, $0C77
    DW GlowYeild
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_8
    DW $36AC, $0CB8
    DW GlowYeild
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_8
    DW $328F, $1119
    DW GlowYeild
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_8
    DW $2A52, $157A
    DW GlowYeild
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_8
    DW $2214, $15BB
    DW GlowYeild
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_8
    DW $1DF7, $1A1C
    DW GlowYeild
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_8
    DW $15BA, $1E7D
    DW GlowYeild
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_8
    DW $0D7F, $22FF
    DW GlowYeild
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_8
    DW $0D7F, $22FF
    DW GlowYeild
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_8
    DW $15BA, $1E7D
    DW GlowYeild
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_8
    DW $1DF7, $1A1C
    DW GlowYeild
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_8
    DW $2214, $15BB
    DW GlowYeild
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_8
    DW $2A52, $157A
    DW GlowYeild
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_8
    DW $328F, $1119
    DW GlowYeild
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_8
    DW $36AC, $0CB8
    DW GlowYeild
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_8
    DW $4309, $0C77
    DW GlowYeild
  DW GlowJMP, NorHot2_0_List_Loop

NorHot2_1_List:
  DW SetColorIndex, $0082
NorHot2_1_List_Loop:
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_8
    DW $4309, $0C77
    DW GlowYeild
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_8
    DW $36AC, $0CB8
    DW GlowYeild
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_8
    DW $328F, $1119
    DW GlowYeild
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_8
    DW $2A52, $157A
    DW GlowYeild
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_8
    DW $2214, $15BB
    DW GlowYeild
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_8
    DW $1DF7, $1A1C
    DW GlowYeild
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_8
    DW $15BA, $1E7D
    DW GlowYeild
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_8
    DW $0D7F, $22FF
    DW GlowYeild
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_8
    DW $0D7F, $22FF
    DW GlowYeild
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_8
    DW $15BA, $1E7D
    DW GlowYeild
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_8
    DW $1DF7, $1A1C
    DW GlowYeild
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_8
    DW $2214, $15BB
    DW GlowYeild
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_8
    DW $2A52, $157A
    DW GlowYeild
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_8
    DW $328F, $1119
    DW GlowYeild
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_8
    DW $36AC, $0CB8
    DW GlowYeild
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_8
    DW $4309, $0C77
    DW GlowYeild
  DW GlowJMP, NorHot2_1_List_Loop

NorHot2_2_List:
  DW SetColorIndex, $0082
NorHot2_2_List_Loop:
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_8
    DW $4309, $0C77
    DW GlowYeild
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_8
    DW $36AC, $0CB8
    DW GlowYeild
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_8
    DW $328F, $1119
    DW GlowYeild
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_8
    DW $2A52, $157A
    DW GlowYeild
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_8
    DW $2214, $15BB
    DW GlowYeild
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_8
    DW $1DF7, $1A1C
    DW GlowYeild
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_8
    DW $15BA, $1E7D
    DW GlowYeild
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_8
    DW $0D7F, $22FF
    DW GlowYeild
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_8
    DW $0D7F, $22FF
    DW GlowYeild
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_8
    DW $15BA, $1E7D
    DW GlowYeild
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_8
    DW $1DF7, $1A1C
    DW GlowYeild
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_8
    DW $2214, $15BB
    DW GlowYeild
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_8
    DW $2A52, $157A
    DW GlowYeild
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_8
    DW $328F, $1119
    DW GlowYeild
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_8
    DW $36AC, $0CB8
    DW GlowYeild
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_8
    DW $4309, $0C77
    DW GlowYeild
  DW GlowJMP, NorHot2_2_List_Loop

NorHot2_3_List:
  DW SetColorIndex, $0082
NorHot2_3_List_Loop:
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_8
    DW $4309, $0C77
    DW GlowYeild
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_8
    DW $36AC, $0CB8
    DW GlowYeild
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_8
    DW $328F, $1119
    DW GlowYeild
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_8
    DW $2A52, $157A
    DW GlowYeild
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_8
    DW $2214, $15BB
    DW GlowYeild
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_8
    DW $1DF7, $1A1C
    DW GlowYeild
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_8
    DW $15BA, $1E7D
    DW GlowYeild
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_8
    DW $0D7F, $22FF
    DW GlowYeild
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_8
    DW $0D7F, $22FF
    DW GlowYeild
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_8
    DW $15BA, $1E7D
    DW GlowYeild
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_8
    DW $1DF7, $1A1C
    DW GlowYeild
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_8
    DW $2214, $15BB
    DW GlowYeild
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_8
    DW $2A52, $157A
    DW GlowYeild
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_8
    DW $328F, $1119
    DW GlowYeild
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_8
    DW $36AC, $0CB8
    DW GlowYeild
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_8
    DW $4309, $0C77
    DW GlowYeild
  DW GlowJMP, NorHot2_3_List_Loop

NorHot2_4_List:
  DW SetColorIndex, $0082
NorHot2_4_List_Loop:
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_8
    DW $4309, $0C77
    DW GlowYeild
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_8
    DW $36AC, $0CB8
    DW GlowYeild
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_8
    DW $328F, $1119
    DW GlowYeild
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_8
    DW $2A52, $157A
    DW GlowYeild
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_8
    DW $2214, $15BB
    DW GlowYeild
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_8
    DW $1DF7, $1A1C
    DW GlowYeild
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_8
    DW $15BA, $1E7D
    DW GlowYeild
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_8
    DW $0D7F, $22FF
    DW GlowYeild
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_8
    DW $0D7F, $22FF
    DW GlowYeild
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_8
    DW $15BA, $1E7D
    DW GlowYeild
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_8
    DW $1DF7, $1A1C
    DW GlowYeild
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_8
    DW $2214, $15BB
    DW GlowYeild
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_8
    DW $2A52, $157A
    DW GlowYeild
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_8
    DW $328F, $1119
    DW GlowYeild
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_8
    DW $36AC, $0CB8
    DW GlowYeild
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_8
    DW $4309, $0C77
    DW GlowYeild
  DW GlowJMP, NorHot2_4_List_Loop

NorHot2_5_List:
  DW SetColorIndex, $0082
NorHot2_5_List_Loop:
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_8
    DW $4309, $0C77
    DW GlowYeild
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_8
    DW $36AC, $0CB8
    DW GlowYeild
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_8
    DW $328F, $1119
    DW GlowYeild
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_8
    DW $2A52, $157A
    DW GlowYeild
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_8
    DW $2214, $15BB
    DW GlowYeild
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_8
    DW $1DF7, $1A1C
    DW GlowYeild
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_8
    DW $15BA, $1E7D
    DW GlowYeild
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_8
    DW $0D7F, $22FF
    DW GlowYeild
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_8
    DW $0D7F, $22FF
    DW GlowYeild
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_8
    DW $15BA, $1E7D
    DW GlowYeild
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_8
    DW $1DF7, $1A1C
    DW GlowYeild
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_8
    DW $2214, $15BB
    DW GlowYeild
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_8
    DW $2A52, $157A
    DW GlowYeild
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_8
    DW $328F, $1119
    DW GlowYeild
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_8
    DW $36AC, $0CB8
    DW GlowYeild
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_8
    DW $4309, $0C77
    DW GlowYeild
  DW GlowJMP, NorHot2_5_List_Loop

NorHot2_6_List:
  DW SetColorIndex, $0082
NorHot2_6_List_Loop:
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_8
    DW $4309, $0C77
    DW GlowYeild
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_8
    DW $36AC, $0CB8
    DW GlowYeild
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_8
    DW $328F, $1119
    DW GlowYeild
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_8
    DW $2A52, $157A
    DW GlowYeild
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_8
    DW $2214, $15BB
    DW GlowYeild
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_8
    DW $1DF7, $1A1C
    DW GlowYeild
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_8
    DW $15BA, $1E7D
    DW GlowYeild
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_8
    DW $0D7F, $22FF
    DW GlowYeild
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_8
    DW $0D7F, $22FF
    DW GlowYeild
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_8
    DW $15BA, $1E7D
    DW GlowYeild
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_8
    DW $1DF7, $1A1C
    DW GlowYeild
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_8
    DW $2214, $15BB
    DW GlowYeild
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_8
    DW $2A52, $157A
    DW GlowYeild
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_8
    DW $328F, $1119
    DW GlowYeild
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_8
    DW $36AC, $0CB8
    DW GlowYeild
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_8
    DW $4309, $0C77
    DW GlowYeild
  DW GlowJMP, NorHot2_6_List_Loop

NorHot3_Table:
  DW EmptyInit,NorHot3_0_List, EmptyInit,NorHot3_1_List, EmptyInit,NorHot3_2_List, EmptyInit,NorHot3_3_List
  DW EmptyInit,NorHot3_4_List, EmptyInit,NorHot3_5_List, EmptyInit,NorHot3_6_List, EmptyInit,NorHot3_7_List
NorHot3_0_List:
NorHot3_7_List:
  DW SetColorIndex, $00A2
NorHot3_0_List_Loop:
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_8
    DW $2DB3, $38CF
    DW GlowYeild
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_8
    DW $2594, $30D1
    DW GlowYeild
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_8
    DW $2176, $28D3
    DW GlowYeild
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_8
    DW $1D57, $24D5
    DW GlowYeild
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_8
    DW $1959, $20F7
    DW GlowYeild
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_8
    DW $153B, $18F9
    DW GlowYeild
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_8
    DW $111C, $14FB
    DW GlowYeild
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_8
    DW $0D1F, $0D1F
    DW GlowYeild
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_8
    DW $0D1F, $0D1F
    DW GlowYeild
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_8
    DW $111C, $14FB
    DW GlowYeild
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_8
    DW $153B, $18F9
    DW GlowYeild
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_8
    DW $1959, $20F7
    DW GlowYeild
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_8
    DW $1D57, $24D5
    DW GlowYeild
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_8
    DW $2176, $28D3
    DW GlowYeild
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_8
    DW $2594, $30D1
    DW GlowYeild
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_8
    DW $2DB3, $38CF
    DW GlowYeild
  DW GlowJMP, NorHot3_0_List_Loop

NorHot3_1_List:
  DW SetColorIndex, $00A2
NorHot3_1_List_Loop:
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_8
    DW $2DB3, $38CF
    DW GlowYeild
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_8
    DW $2594, $30D1
    DW GlowYeild
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_8
    DW $2176, $28D3
    DW GlowYeild
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_8
    DW $1D57, $24D5
    DW GlowYeild
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_8
    DW $1959, $20F7
    DW GlowYeild
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_8
    DW $153B, $18F9
    DW GlowYeild
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_8
    DW $111C, $14FB
    DW GlowYeild
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_8
    DW $0D1F, $0D1F
    DW GlowYeild
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_8
    DW $0D1F, $0D1F
    DW GlowYeild
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_8
    DW $111C, $14FB
    DW GlowYeild
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_8
    DW $153B, $18F9
    DW GlowYeild
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_8
    DW $1959, $20F7
    DW GlowYeild
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_8
    DW $1D57, $24D5
    DW GlowYeild
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_8
    DW $2176, $28D3
    DW GlowYeild
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_8
    DW $2594, $30D1
    DW GlowYeild
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_8
    DW $2DB3, $38CF
    DW GlowYeild
  DW GlowJMP, NorHot3_1_List_Loop

NorHot3_2_List:
  DW SetColorIndex, $00A2
NorHot3_2_List_Loop:
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_8
    DW $2DB3, $38CF
    DW GlowYeild
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_8
    DW $2594, $30D1
    DW GlowYeild
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_8
    DW $2176, $28D3
    DW GlowYeild
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_8
    DW $1D57, $24D5
    DW GlowYeild
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_8
    DW $1959, $20F7
    DW GlowYeild
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_8
    DW $153B, $18F9
    DW GlowYeild
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_8
    DW $111C, $14FB
    DW GlowYeild
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_8
    DW $0D1F, $0D1F
    DW GlowYeild
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_8
    DW $0D1F, $0D1F
    DW GlowYeild
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_8
    DW $111C, $14FB
    DW GlowYeild
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_8
    DW $153B, $18F9
    DW GlowYeild
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_8
    DW $1959, $20F7
    DW GlowYeild
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_8
    DW $1D57, $24D5
    DW GlowYeild
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_8
    DW $2176, $28D3
    DW GlowYeild
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_8
    DW $2594, $30D1
    DW GlowYeild
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_8
    DW $2DB3, $38CF
    DW GlowYeild
  DW GlowJMP, NorHot3_2_List_Loop

NorHot3_3_List:
  DW SetColorIndex, $00A2
NorHot3_3_List_Loop:
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_8
    DW $2DB3, $38CF
    DW GlowYeild
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_8
    DW $2594, $30D1
    DW GlowYeild
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_8
    DW $2176, $28D3
    DW GlowYeild
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_8
    DW $1D57, $24D5
    DW GlowYeild
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_8
    DW $1959, $20F7
    DW GlowYeild
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_8
    DW $153B, $18F9
    DW GlowYeild
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_8
    DW $111C, $14FB
    DW GlowYeild
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_8
    DW $0D1F, $0D1F
    DW GlowYeild
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_8
    DW $0D1F, $0D1F
    DW GlowYeild
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_8
    DW $111C, $14FB
    DW GlowYeild
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_8
    DW $153B, $18F9
    DW GlowYeild
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_8
    DW $1959, $20F7
    DW GlowYeild
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_8
    DW $1D57, $24D5
    DW GlowYeild
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_8
    DW $2176, $28D3
    DW GlowYeild
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_8
    DW $2594, $30D1
    DW GlowYeild
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_8
    DW $2DB3, $38CF
    DW GlowYeild
  DW GlowJMP, NorHot3_3_List_Loop

NorHot3_4_List:
  DW SetColorIndex, $00A2
NorHot3_4_List_Loop:
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_8
    DW $2DB3, $38CF
    DW GlowYeild
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_8
    DW $2594, $30D1
    DW GlowYeild
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_8
    DW $2176, $28D3
    DW GlowYeild
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_8
    DW $1D57, $24D5
    DW GlowYeild
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_8
    DW $1959, $20F7
    DW GlowYeild
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_8
    DW $153B, $18F9
    DW GlowYeild
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_8
    DW $111C, $14FB
    DW GlowYeild
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_8
    DW $0D1F, $0D1F
    DW GlowYeild
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_8
    DW $0D1F, $0D1F
    DW GlowYeild
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_8
    DW $111C, $14FB
    DW GlowYeild
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_8
    DW $153B, $18F9
    DW GlowYeild
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_8
    DW $1959, $20F7
    DW GlowYeild
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_8
    DW $1D57, $24D5
    DW GlowYeild
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_8
    DW $2176, $28D3
    DW GlowYeild
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_8
    DW $2594, $30D1
    DW GlowYeild
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_8
    DW $2DB3, $38CF
    DW GlowYeild
  DW GlowJMP, NorHot3_4_List_Loop

NorHot3_5_List:
  DW SetColorIndex, $00A2
NorHot3_5_List_Loop:
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_8
    DW $2DB3, $38CF
    DW GlowYeild
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_8
    DW $2594, $30D1
    DW GlowYeild
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_8
    DW $2176, $28D3
    DW GlowYeild
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_8
    DW $1D57, $24D5
    DW GlowYeild
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_8
    DW $1959, $20F7
    DW GlowYeild
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_8
    DW $153B, $18F9
    DW GlowYeild
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_8
    DW $111C, $14FB
    DW GlowYeild
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_8
    DW $0D1F, $0D1F
    DW GlowYeild
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_8
    DW $0D1F, $0D1F
    DW GlowYeild
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_8
    DW $111C, $14FB
    DW GlowYeild
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_8
    DW $153B, $18F9
    DW GlowYeild
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_8
    DW $1959, $20F7
    DW GlowYeild
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_8
    DW $1D57, $24D5
    DW GlowYeild
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_8
    DW $2176, $28D3
    DW GlowYeild
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_8
    DW $2594, $30D1
    DW GlowYeild
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_8
    DW $2DB3, $38CF
    DW GlowYeild
  DW GlowJMP, NorHot3_5_List_Loop

NorHot3_6_List:
  DW SetColorIndex, $00A2
NorHot3_6_List_Loop:
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_8
    DW $2DB3, $38CF
    DW GlowYeild
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_8
    DW $2594, $30D1
    DW GlowYeild
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_8
    DW $2176, $28D3
    DW GlowYeild
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_8
    DW $1D57, $24D5
    DW GlowYeild
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_8
    DW $1959, $20F7
    DW GlowYeild
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_8
    DW $153B, $18F9
    DW GlowYeild
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_8
    DW $111C, $14FB
    DW GlowYeild
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_8
    DW $0D1F, $0D1F
    DW GlowYeild
  DW $0008
    DW $2F5F, $1EDF, $1A7F
    DW SkipColors_8
    DW $0D1F, $0D1F
    DW GlowYeild
  DW $0008
    DW $2B1F, $1A9E, $163E
    DW SkipColors_8
    DW $111C, $14FB
    DW GlowYeild
  DW $0007
    DW $22FE, $1A5E, $15DD
    DW SkipColors_8
    DW $153B, $18F9
    DW GlowYeild
  DW $0006
    DW $1EBE, $161D, $119C
    DW SkipColors_8
    DW $1959, $20F7
    DW GlowYeild
  DW $0005
    DW $1A9E, $11FD, $0D3C
    DW SkipColors_8
    DW $1D57, $24D5
    DW GlowYeild
  DW $0004
    DW $165E, $0DBC, $08FB
    DW SkipColors_8
    DW $2176, $28D3
    DW GlowYeild
  DW $0004
    DW $0E3D, $0D7C, $089A
    DW SkipColors_8
    DW $2594, $30D1
    DW GlowYeild
  DW $0010
    DW $09FD, $093B, $0459
    DW SkipColors_8
    DW $2DB3, $38CF
    DW GlowYeild
  DW GlowJMP, NorHot3_6_List_Loop

NorHot4_Table:
  DW EmptyInit,NorHot4_0_List, EmptyInit,NorHot4_1_List, EmptyInit,NorHot4_2_List, EmptyInit,NorHot4_3_List
  DW EmptyInit,NorHot4_4_List, EmptyInit,NorHot4_5_List, EmptyInit,NorHot4_6_List, EmptyInit,NorHot4_7_List
NorHot4_0_List:
NorHot4_7_List:
  DW SetColorIndex, $00C2
NorHot4_0_List_Loop:
  DW $0010
    DW $09DA, $091A, $087A
    DW SkipColors_8
    DW $08A8, $0C05
    DW GlowYeild
  DW $0004
    DW $0DDA, $093A, $089A
    DW SkipColors_8
    DW $08AA, $0828
    DW GlowYeild
  DW $0004
    DW $0DFA, $0D5A, $08BA
    DW SkipColors_8
    DW $08AC, $084A
    DW GlowYeild
  DW $0005
    DW $11FA, $0D7A, $08FA
    DW SkipColors_8
    DW $08CF, $086D
    DW GlowYeild
  DW $0006
    DW $161A, $119A, $0D1A
    DW SkipColors_8
    DW $08D1, $0890
    DW GlowYeild
  DW $0007
    DW $1A1A, $11BA, $0D3A
    DW SkipColors_8
    DW $08F4, $08B3
    DW GlowYeild
  DW $0008
    DW $1A3A, $15DA, $0D7A
    DW SkipColors_8
    DW $08F6, $08D5
    DW GlowYeild
  DW $0008
    DW $225A, $1A1A, $11BA
    DW SkipColors_8
    DW $091A, $091A
    DW GlowYeild
  DW $0008
    DW $225A, $1A1A, $11BA
    DW SkipColors_8
    DW $091A, $091A
    DW GlowYeild
  DW $0008
    DW $1A3A, $15DA, $0D7A
    DW SkipColors_8
    DW $08F6, $08D5
    DW GlowYeild
  DW $0007
    DW $1A1A, $11BA, $0D3A
    DW SkipColors_8
    DW $08F4, $08B3
    DW GlowYeild
  DW $0006
    DW $161A, $119A, $0D1A
    DW SkipColors_8
    DW $08D1, $0890
    DW GlowYeild
  DW $0005
    DW $11FA, $0D7A, $08FA
    DW SkipColors_8
    DW $08CF, $086D
    DW GlowYeild
  DW $0004
    DW $0DFA, $0D5A, $08BA
    DW SkipColors_8
    DW $08AC, $084A
    DW GlowYeild
  DW $0004
    DW $0DDA, $093A, $089A
    DW SkipColors_8
    DW $08AA, $0828
    DW GlowYeild
  DW $0010
    DW $09DA, $091A, $087A
    DW SkipColors_8
    DW $08A8, $0C05
    DW GlowYeild
  DW GlowJMP, NorHot4_0_List_Loop

NorHot4_1_List:
  DW SetColorIndex, $00C2
NorHot4_1_List_Loop:
  DW $0010
    DW $09DA, $091A, $087A
    DW SkipColors_8
    DW $08A8, $0C05
    DW GlowYeild
  DW $0004
    DW $0DDA, $093A, $089A
    DW SkipColors_8
    DW $08AA, $0828
    DW GlowYeild
  DW $0004
    DW $0DFA, $0D5A, $08BA
    DW SkipColors_8
    DW $08AC, $084A
    DW GlowYeild
  DW $0005
    DW $11FA, $0D7A, $08FA
    DW SkipColors_8
    DW $08CF, $086D
    DW GlowYeild
  DW $0006
    DW $161A, $119A, $0D1A
    DW SkipColors_8
    DW $08D1, $0890
    DW GlowYeild
  DW $0007
    DW $1A1A, $11BA, $0D3A
    DW SkipColors_8
    DW $08F4, $08B3
    DW GlowYeild
  DW $0008
    DW $1A3A, $15DA, $0D7A
    DW SkipColors_8
    DW $08F6, $08D5
    DW GlowYeild
  DW $0008
    DW $225A, $1A1A, $11BA
    DW SkipColors_8
    DW $091A, $091A
    DW GlowYeild
  DW $0008
    DW $225A, $1A1A, $11BA
    DW SkipColors_8
    DW $091A, $091A
    DW GlowYeild
  DW $0008
    DW $1A3A, $15DA, $0D7A
    DW SkipColors_8
    DW $08F6, $08D5
    DW GlowYeild
  DW $0007
    DW $1A1A, $11BA, $0D3A
    DW SkipColors_8
    DW $08F4, $08B3
    DW GlowYeild
  DW $0006
    DW $161A, $119A, $0D1A
    DW SkipColors_8
    DW $08D1, $0890
    DW GlowYeild
  DW $0005
    DW $11FA, $0D7A, $08FA
    DW SkipColors_8
    DW $08CF, $086D
    DW GlowYeild
  DW $0004
    DW $0DFA, $0D5A, $08BA
    DW SkipColors_8
    DW $08AC, $084A
    DW GlowYeild
  DW $0004
    DW $0DDA, $093A, $089A
    DW SkipColors_8
    DW $08AA, $0828
    DW GlowYeild
  DW $0010
    DW $09DA, $091A, $087A
    DW SkipColors_8
    DW $08A8, $0C05
    DW GlowYeild
  DW GlowJMP, NorHot4_1_List_Loop

NorHot4_2_List:
  DW SetColorIndex, $00C2
NorHot4_2_List_Loop:
  DW $0010
    DW $09DA, $091A, $087A
    DW SkipColors_8
    DW $08A8, $0C05
    DW GlowYeild
  DW $0004
    DW $0DDA, $093A, $089A
    DW SkipColors_8
    DW $08AA, $0828
    DW GlowYeild
  DW $0004
    DW $0DFA, $0D5A, $08BA
    DW SkipColors_8
    DW $08AC, $084A
    DW GlowYeild
  DW $0005
    DW $11FA, $0D7A, $08FA
    DW SkipColors_8
    DW $08CF, $086D
    DW GlowYeild
  DW $0006
    DW $161A, $119A, $0D1A
    DW SkipColors_8
    DW $08D1, $0890
    DW GlowYeild
  DW $0007
    DW $1A1A, $11BA, $0D3A
    DW SkipColors_8
    DW $08F4, $08B3
    DW GlowYeild
  DW $0008
    DW $1A3A, $15DA, $0D7A
    DW SkipColors_8
    DW $08F6, $08D5
    DW GlowYeild
  DW $0008
    DW $225A, $1A1A, $11BA
    DW SkipColors_8
    DW $091A, $091A
    DW GlowYeild
  DW $0008
    DW $225A, $1A1A, $11BA
    DW SkipColors_8
    DW $091A, $091A
    DW GlowYeild
  DW $0008
    DW $1A3A, $15DA, $0D7A
    DW SkipColors_8
    DW $08F6, $08D5
    DW GlowYeild
  DW $0007
    DW $1A1A, $11BA, $0D3A
    DW SkipColors_8
    DW $08F4, $08B3
    DW GlowYeild
  DW $0006
    DW $161A, $119A, $0D1A
    DW SkipColors_8
    DW $08D1, $0890
    DW GlowYeild
  DW $0005
    DW $11FA, $0D7A, $08FA
    DW SkipColors_8
    DW $08CF, $086D
    DW GlowYeild
  DW $0004
    DW $0DFA, $0D5A, $08BA
    DW SkipColors_8
    DW $08AC, $084A
    DW GlowYeild
  DW $0004
    DW $0DDA, $093A, $089A
    DW SkipColors_8
    DW $08AA, $0828
    DW GlowYeild
  DW $0010
    DW $09DA, $091A, $087A
    DW SkipColors_8
    DW $08A8, $0C05
    DW GlowYeild
  DW GlowJMP, NorHot4_2_List_Loop

NorHot4_3_List:
  DW SetColorIndex, $00C2
NorHot4_3_List_Loop:
  DW $0010
    DW $09DA, $091A, $087A
    DW SkipColors_8
    DW $08A8, $0C05
    DW GlowYeild
  DW $0004
    DW $0DDA, $093A, $089A
    DW SkipColors_8
    DW $08AA, $0828
    DW GlowYeild
  DW $0004
    DW $0DFA, $0D5A, $08BA
    DW SkipColors_8
    DW $08AC, $084A
    DW GlowYeild
  DW $0005
    DW $11FA, $0D7A, $08FA
    DW SkipColors_8
    DW $08CF, $086D
    DW GlowYeild
  DW $0006
    DW $161A, $119A, $0D1A
    DW SkipColors_8
    DW $08D1, $0890
    DW GlowYeild
  DW $0007
    DW $1A1A, $11BA, $0D3A
    DW SkipColors_8
    DW $08F4, $08B3
    DW GlowYeild
  DW $0008
    DW $1A3A, $15DA, $0D7A
    DW SkipColors_8
    DW $08F6, $08D5
    DW GlowYeild
  DW $0008
    DW $225A, $1A1A, $11BA
    DW SkipColors_8
    DW $091A, $091A
    DW GlowYeild
  DW $0008
    DW $225A, $1A1A, $11BA
    DW SkipColors_8
    DW $091A, $091A
    DW GlowYeild
  DW $0008
    DW $1A3A, $15DA, $0D7A
    DW SkipColors_8
    DW $08F6, $08D5
    DW GlowYeild
  DW $0007
    DW $1A1A, $11BA, $0D3A
    DW SkipColors_8
    DW $08F4, $08B3
    DW GlowYeild
  DW $0006
    DW $161A, $119A, $0D1A
    DW SkipColors_8
    DW $08D1, $0890
    DW GlowYeild
  DW $0005
    DW $11FA, $0D7A, $08FA
    DW SkipColors_8
    DW $08CF, $086D
    DW GlowYeild
  DW $0004
    DW $0DFA, $0D5A, $08BA
    DW SkipColors_8
    DW $08AC, $084A
    DW GlowYeild
  DW $0004
    DW $0DDA, $093A, $089A
    DW SkipColors_8
    DW $08AA, $0828
    DW GlowYeild
  DW $0010
    DW $09DA, $091A, $087A
    DW SkipColors_8
    DW $08A8, $0C05
    DW GlowYeild
  DW GlowJMP, NorHot4_3_List_Loop

NorHot4_4_List:
  DW SetColorIndex, $00C2
NorHot4_4_List_Loop:
  DW $0010
    DW $09DA, $091A, $087A
    DW SkipColors_8
    DW $08A8, $0C05
    DW GlowYeild
  DW $0004
    DW $0DDA, $093A, $089A
    DW SkipColors_8
    DW $08AA, $0828
    DW GlowYeild
  DW $0004
    DW $0DFA, $0D5A, $08BA
    DW SkipColors_8
    DW $08AC, $084A
    DW GlowYeild
  DW $0005
    DW $11FA, $0D7A, $08FA
    DW SkipColors_8
    DW $08CF, $086D
    DW GlowYeild
  DW $0006
    DW $161A, $119A, $0D1A
    DW SkipColors_8
    DW $08D1, $0890
    DW GlowYeild
  DW $0007
    DW $1A1A, $11BA, $0D3A
    DW SkipColors_8
    DW $08F4, $08B3
    DW GlowYeild
  DW $0008
    DW $1A3A, $15DA, $0D7A
    DW SkipColors_8
    DW $08F6, $08D5
    DW GlowYeild
  DW $0008
    DW $225A, $1A1A, $11BA
    DW SkipColors_8
    DW $091A, $091A
    DW GlowYeild
  DW $0008
    DW $225A, $1A1A, $11BA
    DW SkipColors_8
    DW $091A, $091A
    DW GlowYeild
  DW $0008
    DW $1A3A, $15DA, $0D7A
    DW SkipColors_8
    DW $08F6, $08D5
    DW GlowYeild
  DW $0007
    DW $1A1A, $11BA, $0D3A
    DW SkipColors_8
    DW $08F4, $08B3
    DW GlowYeild
  DW $0006
    DW $161A, $119A, $0D1A
    DW SkipColors_8
    DW $08D1, $0890
    DW GlowYeild
  DW $0005
    DW $11FA, $0D7A, $08FA
    DW SkipColors_8
    DW $08CF, $086D
    DW GlowYeild
  DW $0004
    DW $0DFA, $0D5A, $08BA
    DW SkipColors_8
    DW $08AC, $084A
    DW GlowYeild
  DW $0004
    DW $0DDA, $093A, $089A
    DW SkipColors_8
    DW $08AA, $0828
    DW GlowYeild
  DW $0010
    DW $09DA, $091A, $087A
    DW SkipColors_8
    DW $08A8, $0C05
    DW GlowYeild
  DW GlowJMP, NorHot4_4_List_Loop

NorHot4_5_List:
  DW SetColorIndex, $00C2
NorHot4_5_List_Loop:
  DW $0010
    DW $09DA, $091A, $087A
    DW SkipColors_8
    DW $08A8, $0C05
    DW GlowYeild
  DW $0004
    DW $0DDA, $093A, $089A
    DW SkipColors_8
    DW $08AA, $0828
    DW GlowYeild
  DW $0004
    DW $0DFA, $0D5A, $08BA
    DW SkipColors_8
    DW $08AC, $084A
    DW GlowYeild
  DW $0005
    DW $11FA, $0D7A, $08FA
    DW SkipColors_8
    DW $08CF, $086D
    DW GlowYeild
  DW $0006
    DW $161A, $119A, $0D1A
    DW SkipColors_8
    DW $08D1, $0890
    DW GlowYeild
  DW $0007
    DW $1A1A, $11BA, $0D3A
    DW SkipColors_8
    DW $08F4, $08B3
    DW GlowYeild
  DW $0008
    DW $1A3A, $15DA, $0D7A
    DW SkipColors_8
    DW $08F6, $08D5
    DW GlowYeild
  DW $0008
    DW $225A, $1A1A, $11BA
    DW SkipColors_8
    DW $091A, $091A
    DW GlowYeild
  DW $0008
    DW $225A, $1A1A, $11BA
    DW SkipColors_8
    DW $091A, $091A
    DW GlowYeild
  DW $0008
    DW $1A3A, $15DA, $0D7A
    DW SkipColors_8
    DW $08F6, $08D5
    DW GlowYeild
  DW $0007
    DW $1A1A, $11BA, $0D3A
    DW SkipColors_8
    DW $08F4, $08B3
    DW GlowYeild
  DW $0006
    DW $161A, $119A, $0D1A
    DW SkipColors_8
    DW $08D1, $0890
    DW GlowYeild
  DW $0005
    DW $11FA, $0D7A, $08FA
    DW SkipColors_8
    DW $08CF, $086D
    DW GlowYeild
  DW $0004
    DW $0DFA, $0D5A, $08BA
    DW SkipColors_8
    DW $08AC, $084A
    DW GlowYeild
  DW $0004
    DW $0DDA, $093A, $089A
    DW SkipColors_8
    DW $08AA, $0828
    DW GlowYeild
  DW $0010
    DW $09DA, $091A, $087A
    DW SkipColors_8
    DW $08A8, $0C05
    DW GlowYeild
  DW GlowJMP, NorHot4_5_List_Loop

NorHot4_6_List:
  DW SetColorIndex, $00C2
NorHot4_6_List_Loop:
  DW $0010
    DW $09DA, $091A, $087A
    DW SkipColors_8
    DW $08A8, $0C05
    DW GlowYeild
  DW $0004
    DW $0DDA, $093A, $089A
    DW SkipColors_8
    DW $08AA, $0828
    DW GlowYeild
  DW $0004
    DW $0DFA, $0D5A, $08BA
    DW SkipColors_8
    DW $08AC, $084A
    DW GlowYeild
  DW $0005
    DW $11FA, $0D7A, $08FA
    DW SkipColors_8
    DW $08CF, $086D
    DW GlowYeild
  DW $0006
    DW $161A, $119A, $0D1A
    DW SkipColors_8
    DW $08D1, $0890
    DW GlowYeild
  DW $0007
    DW $1A1A, $11BA, $0D3A
    DW SkipColors_8
    DW $08F4, $08B3
    DW GlowYeild
  DW $0008
    DW $1A3A, $15DA, $0D7A
    DW SkipColors_8
    DW $08F6, $08D5
    DW GlowYeild
  DW $0008
    DW $225A, $1A1A, $11BA
    DW SkipColors_8
    DW $091A, $091A
    DW GlowYeild
  DW $0008
    DW $225A, $1A1A, $11BA
    DW SkipColors_8
    DW $091A, $091A
    DW GlowYeild
  DW $0008
    DW $1A3A, $15DA, $0D7A
    DW SkipColors_8
    DW $08F6, $08D5
    DW GlowYeild
  DW $0007
    DW $1A1A, $11BA, $0D3A
    DW SkipColors_8
    DW $08F4, $08B3
    DW GlowYeild
  DW $0006
    DW $161A, $119A, $0D1A
    DW SkipColors_8
    DW $08D1, $0890
    DW GlowYeild
  DW $0005
    DW $11FA, $0D7A, $08FA
    DW SkipColors_8
    DW $08CF, $086D
    DW GlowYeild
  DW $0004
    DW $0DFA, $0D5A, $08BA
    DW SkipColors_8
    DW $08AC, $084A
    DW GlowYeild
  DW $0004
    DW $0DDA, $093A, $089A
    DW SkipColors_8
    DW $08AA, $0828
    DW GlowYeild
  DW $0010
    DW $09DA, $091A, $087A
    DW SkipColors_8
    DW $08A8, $0C05
    DW GlowYeild
  DW GlowJMP, NorHot4_6_List_Loop

; Wrecked Ship tileset glows

WS_GreenTable:
  DW EmptyInit,WS_Green0_List, EmptyInit,WS_Green1_List, EmptyInit,WS_Green2_List, EmptyInit,WS_Green3_List
  DW EmptyInit,WS_Green4_List, EmptyInit,WS_Green5_List, EmptyInit,WS_Green6_List, EmptyInit,WS_Green7_List
WS_Green0_List:
WS_Green7_List:
  DW SetColorIndex, $0098
WS_Green0_List_Loop:
  DW $000A
    DW $1EA9, $0BB1
    DW GlowYeild
  DW $000A
    DW $1667, $034E
    DW GlowYeild
  DW $000A
    DW $0E25, $02EB
    DW GlowYeild
  DW $000A
    DW $05E3, $0288
    DW GlowYeild
  DW $000A
    DW $01A1, $0225
    DW GlowYeild
  DW $000A
    DW $05E3, $0288
    DW GlowYeild
  DW $000A
    DW $0E25, $02EB
    DW GlowYeild
  DW $000A
    DW $1667, $034E
    DW GlowYeild
  DW GlowJMP, WS_Green0_List_Loop

WS_Green1_List:
  DW SetColorIndex, $0098
WS_Green1_List_Loop:
  DW $000A
    DW $1EA9, $0BB1
    DW GlowYeild
  DW $000A
    DW $1667, $034E
    DW GlowYeild
  DW $000A
    DW $0E25, $02EB
    DW GlowYeild
  DW $000A
    DW $05E3, $0288
    DW GlowYeild
  DW $000A
    DW $01A1, $0225
    DW GlowYeild
  DW $000A
    DW $05E3, $0288
    DW GlowYeild
  DW $000A
    DW $0E25, $02EB
    DW GlowYeild
  DW $000A
    DW $1667, $034E
    DW GlowYeild
  DW GlowJMP, WS_Green1_List_Loop

WS_Green2_List:
  DW SetColorIndex, $0098
WS_Green2_List_Loop:
  DW $000A
    DW $1EA9, $0BB1
    DW GlowYeild
  DW $000A
    DW $1667, $034E
    DW GlowYeild
  DW $000A
    DW $0E25, $02EB
    DW GlowYeild
  DW $000A
    DW $05E3, $0288
    DW GlowYeild
  DW $000A
    DW $01A1, $0225
    DW GlowYeild
  DW $000A
    DW $05E3, $0288
    DW GlowYeild
  DW $000A
    DW $0E25, $02EB
    DW GlowYeild
  DW $000A
    DW $1667, $034E
    DW GlowYeild
  DW GlowJMP, WS_Green2_List_Loop

WS_Green3_List:
  DW SetColorIndex, $0098
WS_Green3_List_Loop:
  DW $000A
    DW $1EA9, $0BB1
    DW GlowYeild
  DW $000A
    DW $1667, $034E
    DW GlowYeild
  DW $000A
    DW $0E25, $02EB
    DW GlowYeild
  DW $000A
    DW $05E3, $0288
    DW GlowYeild
  DW $000A
    DW $01A1, $0225
    DW GlowYeild
  DW $000A
    DW $05E3, $0288
    DW GlowYeild
  DW $000A
    DW $0E25, $02EB
    DW GlowYeild
  DW $000A
    DW $1667, $034E
    DW GlowYeild
  DW GlowJMP, WS_Green3_List_Loop

WS_Green4_List:
  DW SetColorIndex, $0098
WS_Green4_List_Loop:
  DW $000A
    DW $1EA9, $0BB1
    DW GlowYeild
  DW $000A
    DW $1667, $034E
    DW GlowYeild
  DW $000A
    DW $0E25, $02EB
    DW GlowYeild
  DW $000A
    DW $05E3, $0288
    DW GlowYeild
  DW $000A
    DW $01A1, $0225
    DW GlowYeild
  DW $000A
    DW $05E3, $0288
    DW GlowYeild
  DW $000A
    DW $0E25, $02EB
    DW GlowYeild
  DW $000A
    DW $1667, $034E
    DW GlowYeild
  DW GlowJMP, WS_Green4_List_Loop

WS_Green5_List:
  DW SetColorIndex, $0098
WS_Green5_List_Loop:
  DW $000A
    DW $1EA9, $0BB1
    DW GlowYeild
  DW $000A
    DW $1667, $034E
    DW GlowYeild
  DW $000A
    DW $0E25, $02EB
    DW GlowYeild
  DW $000A
    DW $05E3, $0288
    DW GlowYeild
  DW $000A
    DW $01A1, $0225
    DW GlowYeild
  DW $000A
    DW $05E3, $0288
    DW GlowYeild
  DW $000A
    DW $0E25, $02EB
    DW GlowYeild
  DW $000A
    DW $1667, $034E
    DW GlowYeild
  DW GlowJMP, WS_Green5_List_Loop

WS_Green6_List:
  DW SetColorIndex, $0098
WS_Green6_List_Loop:
  DW $000A
    DW $1EA9, $0BB1
    DW GlowYeild
  DW $000A
    DW $1667, $034E
    DW GlowYeild
  DW $000A
    DW $0E25, $02EB
    DW GlowYeild
  DW $000A
    DW $05E3, $0288
    DW GlowYeild
  DW $000A
    DW $01A1, $0225
    DW GlowYeild
  DW $000A
    DW $05E3, $0288
    DW GlowYeild
  DW $000A
    DW $0E25, $02EB
    DW GlowYeild
  DW $000A
    DW $1667, $034E
    DW GlowYeild
  DW GlowJMP, WS_Green6_List_Loop

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
Waterfal0_List:
Waterfal7_List:
  DW SetColorIndex, $0068
Waterfal0_List_Loop:
  DW $0002
    DW $0400, $0C22, $1864, $2086, $2CC9, $1C65, $1043, $0821
    DW GlowYeild
  DW $0002
    DW $0C22, $1864, $2086, $2CC9, $1C65, $1043, $0821, $0400
    DW GlowYeild
  DW $0002
    DW $1864, $2086, $2CC9, $1C65, $1043, $0821, $0400, $0C22
    DW GlowYeild
  DW $0002
    DW $2086, $2CC9, $1C65, $1043, $0821, $0400, $0C22, $1864
    DW GlowYeild
  DW $0002
    DW $2CC9, $1C65, $1043, $0821, $0400, $0C22, $1864, $2086
    DW GlowYeild
  DW $0002
    DW $1C65, $1043, $0821, $0400, $0C22, $1864, $2086, $2CC9
    DW GlowYeild
  DW $0002
    DW $1043, $0821, $0400, $0C22, $1864, $2086, $2CC9, $1C65
    DW GlowYeild
  DW $0002
    DW $0821, $0400, $0C22, $1864, $2086, $2CC9, $1C65, $1043
    DW GlowYeild
  DW GlowJMP, Waterfal0_List_Loop

Waterfal1_List:
  DW SetColorIndex, $0068
Waterfal1_List_Loop:
  DW $0002
    DW $0400, $0C22, $1864, $2086, $2CC9, $1C65, $1043, $0821
    DW GlowYeild
  DW $0002
    DW $0C22, $1864, $2086, $2CC9, $1C65, $1043, $0821, $0400
    DW GlowYeild
  DW $0002
    DW $1864, $2086, $2CC9, $1C65, $1043, $0821, $0400, $0C22
    DW GlowYeild
  DW $0002
    DW $2086, $2CC9, $1C65, $1043, $0821, $0400, $0C22, $1864
    DW GlowYeild
  DW $0002
    DW $2CC9, $1C65, $1043, $0821, $0400, $0C22, $1864, $2086
    DW GlowYeild
  DW $0002
    DW $1C65, $1043, $0821, $0400, $0C22, $1864, $2086, $2CC9
    DW GlowYeild
  DW $0002
    DW $1043, $0821, $0400, $0C22, $1864, $2086, $2CC9, $1C65
    DW GlowYeild
  DW $0002
    DW $0821, $0400, $0C22, $1864, $2086, $2CC9, $1C65, $1043
    DW GlowYeild
  DW GlowJMP, Waterfal1_List_Loop

Waterfal2_List:
  DW SetColorIndex, $0068
Waterfal2_List_Loop:
  DW $0002
    DW $0400, $0C22, $1864, $2086, $2CC9, $1C65, $1043, $0821
    DW GlowYeild
  DW $0002
    DW $0C22, $1864, $2086, $2CC9, $1C65, $1043, $0821, $0400
    DW GlowYeild
  DW $0002
    DW $1864, $2086, $2CC9, $1C65, $1043, $0821, $0400, $0C22
    DW GlowYeild
  DW $0002
    DW $2086, $2CC9, $1C65, $1043, $0821, $0400, $0C22, $1864
    DW GlowYeild
  DW $0002
    DW $2CC9, $1C65, $1043, $0821, $0400, $0C22, $1864, $2086
    DW GlowYeild
  DW $0002
    DW $1C65, $1043, $0821, $0400, $0C22, $1864, $2086, $2CC9
    DW GlowYeild
  DW $0002
    DW $1043, $0821, $0400, $0C22, $1864, $2086, $2CC9, $1C65
    DW GlowYeild
  DW $0002
    DW $0821, $0400, $0C22, $1864, $2086, $2CC9, $1C65, $1043
    DW GlowYeild
  DW GlowJMP, Waterfal2_List_Loop

Waterfal3_List:
  DW SetColorIndex, $0068
Waterfal3_List_Loop:
  DW $0002
    DW $0400, $0C22, $1864, $2086, $2CC9, $1C65, $1043, $0821
    DW GlowYeild
  DW $0002
    DW $0C22, $1864, $2086, $2CC9, $1C65, $1043, $0821, $0400
    DW GlowYeild
  DW $0002
    DW $1864, $2086, $2CC9, $1C65, $1043, $0821, $0400, $0C22
    DW GlowYeild
  DW $0002
    DW $2086, $2CC9, $1C65, $1043, $0821, $0400, $0C22, $1864
    DW GlowYeild
  DW $0002
    DW $2CC9, $1C65, $1043, $0821, $0400, $0C22, $1864, $2086
    DW GlowYeild
  DW $0002
    DW $1C65, $1043, $0821, $0400, $0C22, $1864, $2086, $2CC9
    DW GlowYeild
  DW $0002
    DW $1043, $0821, $0400, $0C22, $1864, $2086, $2CC9, $1C65
    DW GlowYeild
  DW $0002
    DW $0821, $0400, $0C22, $1864, $2086, $2CC9, $1C65, $1043
    DW GlowYeild
  DW GlowJMP, Waterfal3_List_Loop

Waterfal4_List:
  DW SetColorIndex, $0068
Waterfal4_List_Loop:
  DW $0002
    DW $0400, $0C22, $1864, $2086, $2CC9, $1C65, $1043, $0821
    DW GlowYeild
  DW $0002
    DW $0C22, $1864, $2086, $2CC9, $1C65, $1043, $0821, $0400
    DW GlowYeild
  DW $0002
    DW $1864, $2086, $2CC9, $1C65, $1043, $0821, $0400, $0C22
    DW GlowYeild
  DW $0002
    DW $2086, $2CC9, $1C65, $1043, $0821, $0400, $0C22, $1864
    DW GlowYeild
  DW $0002
    DW $2CC9, $1C65, $1043, $0821, $0400, $0C22, $1864, $2086
    DW GlowYeild
  DW $0002
    DW $1C65, $1043, $0821, $0400, $0C22, $1864, $2086, $2CC9
    DW GlowYeild
  DW $0002
    DW $1043, $0821, $0400, $0C22, $1864, $2086, $2CC9, $1C65
    DW GlowYeild
  DW $0002
    DW $0821, $0400, $0C22, $1864, $2086, $2CC9, $1C65, $1043
    DW GlowYeild
  DW GlowJMP, Waterfal4_List_Loop

Waterfal5_List:
  DW SetColorIndex, $0068
Waterfal5_List_Loop:
  DW $0002
    DW $0400, $0C22, $1864, $2086, $2CC9, $1C65, $1043, $0821
    DW GlowYeild
  DW $0002
    DW $0C22, $1864, $2086, $2CC9, $1C65, $1043, $0821, $0400
    DW GlowYeild
  DW $0002
    DW $1864, $2086, $2CC9, $1C65, $1043, $0821, $0400, $0C22
    DW GlowYeild
  DW $0002
    DW $2086, $2CC9, $1C65, $1043, $0821, $0400, $0C22, $1864
    DW GlowYeild
  DW $0002
    DW $2CC9, $1C65, $1043, $0821, $0400, $0C22, $1864, $2086
    DW GlowYeild
  DW $0002
    DW $1C65, $1043, $0821, $0400, $0C22, $1864, $2086, $2CC9
    DW GlowYeild
  DW $0002
    DW $1043, $0821, $0400, $0C22, $1864, $2086, $2CC9, $1C65
    DW GlowYeild
  DW $0002
    DW $0821, $0400, $0C22, $1864, $2086, $2CC9, $1C65, $1043
    DW GlowYeild
  DW GlowJMP, Waterfal5_List_Loop

Waterfal6_List:
  DW SetColorIndex, $0068
Waterfal6_List_Loop:
  DW $0002
    DW $0400, $0C22, $1864, $2086, $2CC9, $1C65, $1043, $0821
    DW GlowYeild
  DW $0002
    DW $0C22, $1864, $2086, $2CC9, $1C65, $1043, $0821, $0400
    DW GlowYeild
  DW $0002
    DW $1864, $2086, $2CC9, $1C65, $1043, $0821, $0400, $0C22
    DW GlowYeild
  DW $0002
    DW $2086, $2CC9, $1C65, $1043, $0821, $0400, $0C22, $1864
    DW GlowYeild
  DW $0002
    DW $2CC9, $1C65, $1043, $0821, $0400, $0C22, $1864, $2086
    DW GlowYeild
  DW $0002
    DW $1C65, $1043, $0821, $0400, $0C22, $1864, $2086, $2CC9
    DW GlowYeild
  DW $0002
    DW $1043, $0821, $0400, $0C22, $1864, $2086, $2CC9, $1C65
    DW GlowYeild
  DW $0002
    DW $0821, $0400, $0C22, $1864, $2086, $2CC9, $1C65, $1043
    DW GlowYeild
  DW GlowJMP, Waterfal6_List_Loop

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
Tourian_0_List:
Tourian_7_List:
  DW SetColorIndex, $00E8
  DW SetPreInstruction, Tourian_PreInstruction
Tourian_0_List_Loop:
  DW $000A
    DW $5294
    DW SkipColors_3
    DW $0019, $0012, $5C00, $4000, $1084, $197F, $7FFF
    DW GlowYeild
  DW $000A
    DW $4A52
    DW SkipColors_3
    DW $0016, $000F, $5000, $3400, $1084, $0D1C, $739C
    DW GlowYeild
  DW $000A
    DW $4210
    DW SkipColors_3
    DW $0013, $000C, $4400, $2800, $1084, $00B9, $6739
    DW GlowYeild
  DW $000A
    DW $39CE
    DW SkipColors_3
    DW $0010, $0009, $3800, $1C00, $1084, $0056, $5AD6
    DW GlowYeild
  DW $000A
    DW $318C
    DW SkipColors_3
    DW $000D, $0006, $2C00, $1000, $1084, $0013, $4E73
    DW GlowYeild
  DW $000A
    DW $294A
    DW SkipColors_3
    DW $000A, $0003, $2000, $0400, $1084, $0010, $4210
    DW GlowYeild
  DW $000A
    DW $294A
    DW SkipColors_3
    DW $000A, $0003, $2000, $0400, $1084, $0010, $4210
    DW GlowYeild
  DW $000A
    DW $318C
    DW SkipColors_3
    DW $000D, $0006, $2C00, $1000, $1084, $0013, $4E73
    DW GlowYeild
  DW $000A
    DW $39CE
    DW SkipColors_3
    DW $0010, $0009, $3800, $1C00, $1084, $0056, $5AD6
    DW GlowYeild
  DW $000A
    DW $4210
    DW SkipColors_3
    DW $0013, $000C, $4400, $2800, $1084, $00B9, $6739
    DW GlowYeild
  DW $000A
    DW $4A52
    DW SkipColors_3
    DW $0016, $000F, $5000, $3400, $1084, $0D1C, $739C
    DW GlowYeild
  DW GlowJMP, Tourian_0_List_Loop

Tourian_1_List:
  DW SetColorIndex, $00E8
  DW SetPreInstruction, Tourian_PreInstruction
Tourian_1_List_Loop:
  DW $000A
    DW $5294
    DW SkipColors_3
    DW $0019, $0012, $5C00, $4000, $1084, $197F, $7FFF
    DW GlowYeild
  DW $000A
    DW $4A52
    DW SkipColors_3
    DW $0016, $000F, $5000, $3400, $1084, $0D1C, $739C
    DW GlowYeild
  DW $000A
    DW $4210
    DW SkipColors_3
    DW $0013, $000C, $4400, $2800, $1084, $00B9, $6739
    DW GlowYeild
  DW $000A
    DW $39CE
    DW SkipColors_3
    DW $0010, $0009, $3800, $1C00, $1084, $0056, $5AD6
    DW GlowYeild
  DW $000A
    DW $318C
    DW SkipColors_3
    DW $000D, $0006, $2C00, $1000, $1084, $0013, $4E73
    DW GlowYeild
  DW $000A
    DW $294A
    DW SkipColors_3
    DW $000A, $0003, $2000, $0400, $1084, $0010, $4210
    DW GlowYeild
  DW $000A
    DW $294A
    DW SkipColors_3
    DW $000A, $0003, $2000, $0400, $1084, $0010, $4210
    DW GlowYeild
  DW $000A
    DW $318C
    DW SkipColors_3
    DW $000D, $0006, $2C00, $1000, $1084, $0013, $4E73
    DW GlowYeild
  DW $000A
    DW $39CE
    DW SkipColors_3
    DW $0010, $0009, $3800, $1C00, $1084, $0056, $5AD6
    DW GlowYeild
  DW $000A
    DW $4210
    DW SkipColors_3
    DW $0013, $000C, $4400, $2800, $1084, $00B9, $6739
    DW GlowYeild
  DW $000A
    DW $4A52
    DW SkipColors_3
    DW $0016, $000F, $5000, $3400, $1084, $0D1C, $739C
    DW GlowYeild
  DW GlowJMP, Tourian_1_List_Loop

Tourian_2_List:
  DW SetColorIndex, $00E8
  DW SetPreInstruction, Tourian_PreInstruction
Tourian_2_List_Loop:
  DW $000A
    DW $5294
    DW SkipColors_3
    DW $0019, $0012, $5C00, $4000, $1084, $197F, $7FFF
    DW GlowYeild
  DW $000A
    DW $4A52
    DW SkipColors_3
    DW $0016, $000F, $5000, $3400, $1084, $0D1C, $739C
    DW GlowYeild
  DW $000A
    DW $4210
    DW SkipColors_3
    DW $0013, $000C, $4400, $2800, $1084, $00B9, $6739
    DW GlowYeild
  DW $000A
    DW $39CE
    DW SkipColors_3
    DW $0010, $0009, $3800, $1C00, $1084, $0056, $5AD6
    DW GlowYeild
  DW $000A
    DW $318C
    DW SkipColors_3
    DW $000D, $0006, $2C00, $1000, $1084, $0013, $4E73
    DW GlowYeild
  DW $000A
    DW $294A
    DW SkipColors_3
    DW $000A, $0003, $2000, $0400, $1084, $0010, $4210
    DW GlowYeild
  DW $000A
    DW $294A
    DW SkipColors_3
    DW $000A, $0003, $2000, $0400, $1084, $0010, $4210
    DW GlowYeild
  DW $000A
    DW $318C
    DW SkipColors_3
    DW $000D, $0006, $2C00, $1000, $1084, $0013, $4E73
    DW GlowYeild
  DW $000A
    DW $39CE
    DW SkipColors_3
    DW $0010, $0009, $3800, $1C00, $1084, $0056, $5AD6
    DW GlowYeild
  DW $000A
    DW $4210
    DW SkipColors_3
    DW $0013, $000C, $4400, $2800, $1084, $00B9, $6739
    DW GlowYeild
  DW $000A
    DW $4A52
    DW SkipColors_3
    DW $0016, $000F, $5000, $3400, $1084, $0D1C, $739C
    DW GlowYeild
  DW GlowJMP, Tourian_2_List_Loop

Tourian_3_List:
  DW SetColorIndex, $00E8
  DW SetPreInstruction, Tourian_PreInstruction
Tourian_3_List_Loop:
  DW $000A
    DW $5294
    DW SkipColors_3
    DW $0019, $0012, $5C00, $4000, $1084, $197F, $7FFF
    DW GlowYeild
  DW $000A
    DW $4A52
    DW SkipColors_3
    DW $0016, $000F, $5000, $3400, $1084, $0D1C, $739C
    DW GlowYeild
  DW $000A
    DW $4210
    DW SkipColors_3
    DW $0013, $000C, $4400, $2800, $1084, $00B9, $6739
    DW GlowYeild
  DW $000A
    DW $39CE
    DW SkipColors_3
    DW $0010, $0009, $3800, $1C00, $1084, $0056, $5AD6
    DW GlowYeild
  DW $000A
    DW $318C
    DW SkipColors_3
    DW $000D, $0006, $2C00, $1000, $1084, $0013, $4E73
    DW GlowYeild
  DW $000A
    DW $294A
    DW SkipColors_3
    DW $000A, $0003, $2000, $0400, $1084, $0010, $4210
    DW GlowYeild
  DW $000A
    DW $294A
    DW SkipColors_3
    DW $000A, $0003, $2000, $0400, $1084, $0010, $4210
    DW GlowYeild
  DW $000A
    DW $318C
    DW SkipColors_3
    DW $000D, $0006, $2C00, $1000, $1084, $0013, $4E73
    DW GlowYeild
  DW $000A
    DW $39CE
    DW SkipColors_3
    DW $0010, $0009, $3800, $1C00, $1084, $0056, $5AD6
    DW GlowYeild
  DW $000A
    DW $4210
    DW SkipColors_3
    DW $0013, $000C, $4400, $2800, $1084, $00B9, $6739
    DW GlowYeild
  DW $000A
    DW $4A52
    DW SkipColors_3
    DW $0016, $000F, $5000, $3400, $1084, $0D1C, $739C
    DW GlowYeild
  DW GlowJMP, Tourian_3_List_Loop

Tourian_4_List:
  DW SetColorIndex, $00E8
  DW SetPreInstruction, Tourian_PreInstruction
Tourian_4_List_Loop:
  DW $000A
    DW $5294
    DW SkipColors_3
    DW $0019, $0012, $5C00, $4000, $1084, $197F, $7FFF
    DW GlowYeild
  DW $000A
    DW $4A52
    DW SkipColors_3
    DW $0016, $000F, $5000, $3400, $1084, $0D1C, $739C
    DW GlowYeild
  DW $000A
    DW $4210
    DW SkipColors_3
    DW $0013, $000C, $4400, $2800, $1084, $00B9, $6739
    DW GlowYeild
  DW $000A
    DW $39CE
    DW SkipColors_3
    DW $0010, $0009, $3800, $1C00, $1084, $0056, $5AD6
    DW GlowYeild
  DW $000A
    DW $318C
    DW SkipColors_3
    DW $000D, $0006, $2C00, $1000, $1084, $0013, $4E73
    DW GlowYeild
  DW $000A
    DW $294A
    DW SkipColors_3
    DW $000A, $0003, $2000, $0400, $1084, $0010, $4210
    DW GlowYeild
  DW $000A
    DW $294A
    DW SkipColors_3
    DW $000A, $0003, $2000, $0400, $1084, $0010, $4210
    DW GlowYeild
  DW $000A
    DW $318C
    DW SkipColors_3
    DW $000D, $0006, $2C00, $1000, $1084, $0013, $4E73
    DW GlowYeild
  DW $000A
    DW $39CE
    DW SkipColors_3
    DW $0010, $0009, $3800, $1C00, $1084, $0056, $5AD6
    DW GlowYeild
  DW $000A
    DW $4210
    DW SkipColors_3
    DW $0013, $000C, $4400, $2800, $1084, $00B9, $6739
    DW GlowYeild
  DW $000A
    DW $4A52
    DW SkipColors_3
    DW $0016, $000F, $5000, $3400, $1084, $0D1C, $739C
    DW GlowYeild
  DW GlowJMP, Tourian_4_List_Loop

Tourian_5_List:
  DW SetColorIndex, $00E8
  DW SetPreInstruction, Tourian_PreInstruction
Tourian_5_List_Loop:
  DW $000A
    DW $5294
    DW SkipColors_3
    DW $0019, $0012, $5C00, $4000, $1084, $197F, $7FFF
    DW GlowYeild
  DW $000A
    DW $4A52
    DW SkipColors_3
    DW $0016, $000F, $5000, $3400, $1084, $0D1C, $739C
    DW GlowYeild
  DW $000A
    DW $4210
    DW SkipColors_3
    DW $0013, $000C, $4400, $2800, $1084, $00B9, $6739
    DW GlowYeild
  DW $000A
    DW $39CE
    DW SkipColors_3
    DW $0010, $0009, $3800, $1C00, $1084, $0056, $5AD6
    DW GlowYeild
  DW $000A
    DW $318C
    DW SkipColors_3
    DW $000D, $0006, $2C00, $1000, $1084, $0013, $4E73
    DW GlowYeild
  DW $000A
    DW $294A
    DW SkipColors_3
    DW $000A, $0003, $2000, $0400, $1084, $0010, $4210
    DW GlowYeild
  DW $000A
    DW $294A
    DW SkipColors_3
    DW $000A, $0003, $2000, $0400, $1084, $0010, $4210
    DW GlowYeild
  DW $000A
    DW $318C
    DW SkipColors_3
    DW $000D, $0006, $2C00, $1000, $1084, $0013, $4E73
    DW GlowYeild
  DW $000A
    DW $39CE
    DW SkipColors_3
    DW $0010, $0009, $3800, $1C00, $1084, $0056, $5AD6
    DW GlowYeild
  DW $000A
    DW $4210
    DW SkipColors_3
    DW $0013, $000C, $4400, $2800, $1084, $00B9, $6739
    DW GlowYeild
  DW $000A
    DW $4A52
    DW SkipColors_3
    DW $0016, $000F, $5000, $3400, $1084, $0D1C, $739C
    DW GlowYeild
  DW GlowJMP, Tourian_5_List_Loop

Tourian_6_List:
  DW SetColorIndex, $00E8
  DW SetPreInstruction, Tourian_PreInstruction
Tourian_6_List_Loop:
  DW $000A
    DW $5294
    DW SkipColors_3
    DW $0019, $0012, $5C00, $4000, $1084, $197F, $7FFF
    DW GlowYeild
  DW $000A
    DW $4A52
    DW SkipColors_3
    DW $0016, $000F, $5000, $3400, $1084, $0D1C, $739C
    DW GlowYeild
  DW $000A
    DW $4210
    DW SkipColors_3
    DW $0013, $000C, $4400, $2800, $1084, $00B9, $6739
    DW GlowYeild
  DW $000A
    DW $39CE
    DW SkipColors_3
    DW $0010, $0009, $3800, $1C00, $1084, $0056, $5AD6
    DW GlowYeild
  DW $000A
    DW $318C
    DW SkipColors_3
    DW $000D, $0006, $2C00, $1000, $1084, $0013, $4E73
    DW GlowYeild
  DW $000A
    DW $294A
    DW SkipColors_3
    DW $000A, $0003, $2000, $0400, $1084, $0010, $4210
    DW GlowYeild
  DW $000A
    DW $294A
    DW SkipColors_3
    DW $000A, $0003, $2000, $0400, $1084, $0010, $4210
    DW GlowYeild
  DW $000A
    DW $318C
    DW SkipColors_3
    DW $000D, $0006, $2C00, $1000, $1084, $0013, $4E73
    DW GlowYeild
  DW $000A
    DW $39CE
    DW SkipColors_3
    DW $0010, $0009, $3800, $1C00, $1084, $0056, $5AD6
    DW GlowYeild
  DW $000A
    DW $4210
    DW SkipColors_3
    DW $0013, $000C, $4400, $2800, $1084, $00B9, $6739
    DW GlowYeild
  DW $000A
    DW $4A52
    DW SkipColors_3
    DW $0016, $000F, $5000, $3400, $1084, $0D1C, $739C
    DW GlowYeild
  DW GlowJMP, Tourian_6_List_Loop

Tor_1EscTable:
  DW EmptyInit,Tor_1Esc0_List, EmptyInit,Tor_1Esc1_List, EmptyInit,Tor_1Esc2_List, EmptyInit,Tor_1Esc3_List
  DW EmptyInit,Tor_1Esc4_List, EmptyInit,Tor_1Esc5_List, EmptyInit,Tor_1Esc6_List, EmptyInit,Tor_1Esc7_List
Tor_1Esc0_List:
Tor_1Esc7_List:
  DW SetColorIndex, $0132
Tor_1Esc0_List_Loop:
  DW $0002
    DW $5294, $4210, $318C, $2108, $1084, $7FFF
    DW GlowYeild
  DW $0002
    DW $4E75, $3DF1, $2D6D, $1CE8, $0C64, $77BF
    DW GlowYeild
  DW $0002
    DW $4A55, $39D1, $2D6D, $1CE8, $0C64, $739F
    DW GlowYeild
  DW $0002
    DW $4636, $35B2, $294D, $18C9, $0844, $6B5F
    DW GlowYeild
  DW $0002
    DW $3DF6, $3192, $252D, $14A9, $0844, $673F
    DW GlowYeild
  DW $0002
    DW $39D7, $2D72, $210E, $1089, $0424, $5EFF
    DW GlowYeild
  DW $0002
    DW $35B7, $2952, $1CEE, $1089, $0424, $5ADF
    DW GlowYeild
  DW $0002
    DW $3198, $2533, $18CE, $0C69, $0004, $529F
    DW GlowYeild
  DW $0002
    DW $35B7, $2952, $1CEE, $1089, $0424, $5ADF
    DW GlowYeild
  DW $0002
    DW $39D7, $2D72, $210E, $1089, $0424, $5EFF
    DW GlowYeild
  DW $0002
    DW $3DF6, $3192, $252D, $14A9, $0844, $673F
    DW GlowYeild
  DW $0002
    DW $4636, $35B2, $294D, $18C9, $0844, $6B5F
    DW GlowYeild
  DW $0002
    DW $4A55, $39D1, $2D6D, $1CE8, $0C64, $739F
    DW GlowYeild
  DW $0002
    DW $4E75, $3DF1, $2D6D, $1CE8, $0C64, $77BF
    DW GlowYeild
  DW GlowJMP, Tor_1Esc0_List_Loop

Tor_1Esc1_List:
  DW SetColorIndex, $0132
Tor_1Esc1_List_Loop:
  DW $0002
    DW $5294, $4210, $318C, $2108, $1084, $7FFF
    DW GlowYeild
  DW $0002
    DW $4E75, $3DF1, $2D6D, $1CE8, $0C64, $77BF
    DW GlowYeild
  DW $0002
    DW $4A55, $39D1, $2D6D, $1CE8, $0C64, $739F
    DW GlowYeild
  DW $0002
    DW $4636, $35B2, $294D, $18C9, $0844, $6B5F
    DW GlowYeild
  DW $0002
    DW $3DF6, $3192, $252D, $14A9, $0844, $673F
    DW GlowYeild
  DW $0002
    DW $39D7, $2D72, $210E, $1089, $0424, $5EFF
    DW GlowYeild
  DW $0002
    DW $35B7, $2952, $1CEE, $1089, $0424, $5ADF
    DW GlowYeild
  DW $0002
    DW $3198, $2533, $18CE, $0C69, $0004, $529F
    DW GlowYeild
  DW $0002
    DW $35B7, $2952, $1CEE, $1089, $0424, $5ADF
    DW GlowYeild
  DW $0002
    DW $39D7, $2D72, $210E, $1089, $0424, $5EFF
    DW GlowYeild
  DW $0002
    DW $3DF6, $3192, $252D, $14A9, $0844, $673F
    DW GlowYeild
  DW $0002
    DW $4636, $35B2, $294D, $18C9, $0844, $6B5F
    DW GlowYeild
  DW $0002
    DW $4A55, $39D1, $2D6D, $1CE8, $0C64, $739F
    DW GlowYeild
  DW $0002
    DW $4E75, $3DF1, $2D6D, $1CE8, $0C64, $77BF
    DW GlowYeild
  DW GlowJMP, Tor_1Esc1_List_Loop

Tor_1Esc2_List:
  DW SetColorIndex, $0132
Tor_1Esc2_List_Loop:
  DW $0002
    DW $5294, $4210, $318C, $2108, $1084, $7FFF
    DW GlowYeild
  DW $0002
    DW $4E75, $3DF1, $2D6D, $1CE8, $0C64, $77BF
    DW GlowYeild
  DW $0002
    DW $4A55, $39D1, $2D6D, $1CE8, $0C64, $739F
    DW GlowYeild
  DW $0002
    DW $4636, $35B2, $294D, $18C9, $0844, $6B5F
    DW GlowYeild
  DW $0002
    DW $3DF6, $3192, $252D, $14A9, $0844, $673F
    DW GlowYeild
  DW $0002
    DW $39D7, $2D72, $210E, $1089, $0424, $5EFF
    DW GlowYeild
  DW $0002
    DW $35B7, $2952, $1CEE, $1089, $0424, $5ADF
    DW GlowYeild
  DW $0002
    DW $3198, $2533, $18CE, $0C69, $0004, $529F
    DW GlowYeild
  DW $0002
    DW $35B7, $2952, $1CEE, $1089, $0424, $5ADF
    DW GlowYeild
  DW $0002
    DW $39D7, $2D72, $210E, $1089, $0424, $5EFF
    DW GlowYeild
  DW $0002
    DW $3DF6, $3192, $252D, $14A9, $0844, $673F
    DW GlowYeild
  DW $0002
    DW $4636, $35B2, $294D, $18C9, $0844, $6B5F
    DW GlowYeild
  DW $0002
    DW $4A55, $39D1, $2D6D, $1CE8, $0C64, $739F
    DW GlowYeild
  DW $0002
    DW $4E75, $3DF1, $2D6D, $1CE8, $0C64, $77BF
    DW GlowYeild
  DW GlowJMP, Tor_1Esc2_List_Loop

Tor_1Esc3_List:
  DW SetColorIndex, $0132
Tor_1Esc3_List_Loop:
  DW $0002
    DW $5294, $4210, $318C, $2108, $1084, $7FFF
    DW GlowYeild
  DW $0002
    DW $4E75, $3DF1, $2D6D, $1CE8, $0C64, $77BF
    DW GlowYeild
  DW $0002
    DW $4A55, $39D1, $2D6D, $1CE8, $0C64, $739F
    DW GlowYeild
  DW $0002
    DW $4636, $35B2, $294D, $18C9, $0844, $6B5F
    DW GlowYeild
  DW $0002
    DW $3DF6, $3192, $252D, $14A9, $0844, $673F
    DW GlowYeild
  DW $0002
    DW $39D7, $2D72, $210E, $1089, $0424, $5EFF
    DW GlowYeild
  DW $0002
    DW $35B7, $2952, $1CEE, $1089, $0424, $5ADF
    DW GlowYeild
  DW $0002
    DW $3198, $2533, $18CE, $0C69, $0004, $529F
    DW GlowYeild
  DW $0002
    DW $35B7, $2952, $1CEE, $1089, $0424, $5ADF
    DW GlowYeild
  DW $0002
    DW $39D7, $2D72, $210E, $1089, $0424, $5EFF
    DW GlowYeild
  DW $0002
    DW $3DF6, $3192, $252D, $14A9, $0844, $673F
    DW GlowYeild
  DW $0002
    DW $4636, $35B2, $294D, $18C9, $0844, $6B5F
    DW GlowYeild
  DW $0002
    DW $4A55, $39D1, $2D6D, $1CE8, $0C64, $739F
    DW GlowYeild
  DW $0002
    DW $4E75, $3DF1, $2D6D, $1CE8, $0C64, $77BF
    DW GlowYeild
  DW GlowJMP, Tor_1Esc3_List_Loop

Tor_1Esc4_List:
  DW SetColorIndex, $0132
Tor_1Esc4_List_Loop:
  DW $0002
    DW $5294, $4210, $318C, $2108, $1084, $7FFF
    DW GlowYeild
  DW $0002
    DW $4E75, $3DF1, $2D6D, $1CE8, $0C64, $77BF
    DW GlowYeild
  DW $0002
    DW $4A55, $39D1, $2D6D, $1CE8, $0C64, $739F
    DW GlowYeild
  DW $0002
    DW $4636, $35B2, $294D, $18C9, $0844, $6B5F
    DW GlowYeild
  DW $0002
    DW $3DF6, $3192, $252D, $14A9, $0844, $673F
    DW GlowYeild
  DW $0002
    DW $39D7, $2D72, $210E, $1089, $0424, $5EFF
    DW GlowYeild
  DW $0002
    DW $35B7, $2952, $1CEE, $1089, $0424, $5ADF
    DW GlowYeild
  DW $0002
    DW $3198, $2533, $18CE, $0C69, $0004, $529F
    DW GlowYeild
  DW $0002
    DW $35B7, $2952, $1CEE, $1089, $0424, $5ADF
    DW GlowYeild
  DW $0002
    DW $39D7, $2D72, $210E, $1089, $0424, $5EFF
    DW GlowYeild
  DW $0002
    DW $3DF6, $3192, $252D, $14A9, $0844, $673F
    DW GlowYeild
  DW $0002
    DW $4636, $35B2, $294D, $18C9, $0844, $6B5F
    DW GlowYeild
  DW $0002
    DW $4A55, $39D1, $2D6D, $1CE8, $0C64, $739F
    DW GlowYeild
  DW $0002
    DW $4E75, $3DF1, $2D6D, $1CE8, $0C64, $77BF
    DW GlowYeild
  DW GlowJMP, Tor_1Esc4_List_Loop

Tor_1Esc5_List:
  DW SetColorIndex, $0132
Tor_1Esc5_List_Loop:
  DW $0002
    DW $5294, $4210, $318C, $2108, $1084, $7FFF
    DW GlowYeild
  DW $0002
    DW $4E75, $3DF1, $2D6D, $1CE8, $0C64, $77BF
    DW GlowYeild
  DW $0002
    DW $4A55, $39D1, $2D6D, $1CE8, $0C64, $739F
    DW GlowYeild
  DW $0002
    DW $4636, $35B2, $294D, $18C9, $0844, $6B5F
    DW GlowYeild
  DW $0002
    DW $3DF6, $3192, $252D, $14A9, $0844, $673F
    DW GlowYeild
  DW $0002
    DW $39D7, $2D72, $210E, $1089, $0424, $5EFF
    DW GlowYeild
  DW $0002
    DW $35B7, $2952, $1CEE, $1089, $0424, $5ADF
    DW GlowYeild
  DW $0002
    DW $3198, $2533, $18CE, $0C69, $0004, $529F
    DW GlowYeild
  DW $0002
    DW $35B7, $2952, $1CEE, $1089, $0424, $5ADF
    DW GlowYeild
  DW $0002
    DW $39D7, $2D72, $210E, $1089, $0424, $5EFF
    DW GlowYeild
  DW $0002
    DW $3DF6, $3192, $252D, $14A9, $0844, $673F
    DW GlowYeild
  DW $0002
    DW $4636, $35B2, $294D, $18C9, $0844, $6B5F
    DW GlowYeild
  DW $0002
    DW $4A55, $39D1, $2D6D, $1CE8, $0C64, $739F
    DW GlowYeild
  DW $0002
    DW $4E75, $3DF1, $2D6D, $1CE8, $0C64, $77BF
    DW GlowYeild
  DW GlowJMP, Tor_1Esc5_List_Loop

Tor_1Esc6_List:
  DW SetColorIndex, $0132
Tor_1Esc6_List_Loop:
  DW $0002
    DW $5294, $4210, $318C, $2108, $1084, $7FFF
    DW GlowYeild
  DW $0002
    DW $4E75, $3DF1, $2D6D, $1CE8, $0C64, $77BF
    DW GlowYeild
  DW $0002
    DW $4A55, $39D1, $2D6D, $1CE8, $0C64, $739F
    DW GlowYeild
  DW $0002
    DW $4636, $35B2, $294D, $18C9, $0844, $6B5F
    DW GlowYeild
  DW $0002
    DW $3DF6, $3192, $252D, $14A9, $0844, $673F
    DW GlowYeild
  DW $0002
    DW $39D7, $2D72, $210E, $1089, $0424, $5EFF
    DW GlowYeild
  DW $0002
    DW $35B7, $2952, $1CEE, $1089, $0424, $5ADF
    DW GlowYeild
  DW $0002
    DW $3198, $2533, $18CE, $0C69, $0004, $529F
    DW GlowYeild
  DW $0002
    DW $35B7, $2952, $1CEE, $1089, $0424, $5ADF
    DW GlowYeild
  DW $0002
    DW $39D7, $2D72, $210E, $1089, $0424, $5EFF
    DW GlowYeild
  DW $0002
    DW $3DF6, $3192, $252D, $14A9, $0844, $673F
    DW GlowYeild
  DW $0002
    DW $4636, $35B2, $294D, $18C9, $0844, $6B5F
    DW GlowYeild
  DW $0002
    DW $4A55, $39D1, $2D6D, $1CE8, $0C64, $739F
    DW GlowYeild
  DW $0002
    DW $4E75, $3DF1, $2D6D, $1CE8, $0C64, $77BF
    DW GlowYeild
  DW GlowJMP, Tor_1Esc6_List_Loop

Tor_2EscTable:
  DW EmptyInit,Tor_2Esc0_List, EmptyInit,Tor_2Esc1_List, EmptyInit,Tor_2Esc2_List, EmptyInit,Tor_2Esc3_List
  DW EmptyInit,Tor_2Esc4_List, EmptyInit,Tor_2Esc5_List, EmptyInit,Tor_2Esc6_List, EmptyInit,Tor_2Esc7_List
Tor_2Esc0_List:
Tor_2Esc7_List:
  DW SetColorIndex, $0070
Tor_2Esc0_List_Loop:
  DW $0004
    DW $081A, $0812, $042B, $0423
    DW GlowYeild
  DW $0004
    DW $0C37, $0C30, $042A, $0423
    DW GlowYeild
  DW $0004
    DW $1054, $0C2E, $0849, $0422
    DW GlowYeild
  DW $0004
    DW $1471, $104C, $0848, $0422
    DW GlowYeild
  DW $0004
    DW $148E, $106A, $0C66, $0842
    DW GlowYeild
  DW $0004
    DW $18AB, $1488, $0C65, $0842
    DW GlowYeild
  DW $0004
    DW $1CC8, $1486, $1084, $0841
    DW GlowYeild
  DW $0004
    DW $20E5, $18A4, $1083, $0841
    DW GlowYeild
  DW $0004
    DW $1CC8, $1486, $1084, $0841
    DW GlowYeild
  DW $0004
    DW $18AB, $1488, $0C65, $0842
    DW GlowYeild
  DW $0004
    DW $148E, $106A, $0C66, $0842
    DW GlowYeild
  DW $0004
    DW $1471, $104C, $0848, $0422
    DW GlowYeild
  DW $0004
    DW $1054, $0C2E, $0849, $0422
    DW GlowYeild
  DW $0004
    DW $0C37, $0C30, $042A, $0423
    DW GlowYeild
  DW GlowJMP, Tor_2Esc0_List_Loop

Tor_2Esc1_List:
  DW SetColorIndex, $0070
Tor_2Esc1_List_Loop:
  DW $0004
    DW $081A, $0812, $042B, $0423
    DW GlowYeild
  DW $0004
    DW $0C37, $0C30, $042A, $0423
    DW GlowYeild
  DW $0004
    DW $1054, $0C2E, $0849, $0422
    DW GlowYeild
  DW $0004
    DW $1471, $104C, $0848, $0422
    DW GlowYeild
  DW $0004
    DW $148E, $106A, $0C66, $0842
    DW GlowYeild
  DW $0004
    DW $18AB, $1488, $0C65, $0842
    DW GlowYeild
  DW $0004
    DW $1CC8, $1486, $1084, $0841
    DW GlowYeild
  DW $0004
    DW $20E5, $18A4, $1083, $0841
    DW GlowYeild
  DW $0004
    DW $1CC8, $1486, $1084, $0841
    DW GlowYeild
  DW $0004
    DW $18AB, $1488, $0C65, $0842
    DW GlowYeild
  DW $0004
    DW $148E, $106A, $0C66, $0842
    DW GlowYeild
  DW $0004
    DW $1471, $104C, $0848, $0422
    DW GlowYeild
  DW $0004
    DW $1054, $0C2E, $0849, $0422
    DW GlowYeild
  DW $0004
    DW $0C37, $0C30, $042A, $0423
    DW GlowYeild
  DW GlowJMP, Tor_2Esc1_List_Loop

Tor_2Esc2_List:
  DW SetColorIndex, $0070
Tor_2Esc2_List_Loop:
  DW $0004
    DW $081A, $0812, $042B, $0423
    DW GlowYeild
  DW $0004
    DW $0C37, $0C30, $042A, $0423
    DW GlowYeild
  DW $0004
    DW $1054, $0C2E, $0849, $0422
    DW GlowYeild
  DW $0004
    DW $1471, $104C, $0848, $0422
    DW GlowYeild
  DW $0004
    DW $148E, $106A, $0C66, $0842
    DW GlowYeild
  DW $0004
    DW $18AB, $1488, $0C65, $0842
    DW GlowYeild
  DW $0004
    DW $1CC8, $1486, $1084, $0841
    DW GlowYeild
  DW $0004
    DW $20E5, $18A4, $1083, $0841
    DW GlowYeild
  DW $0004
    DW $1CC8, $1486, $1084, $0841
    DW GlowYeild
  DW $0004
    DW $18AB, $1488, $0C65, $0842
    DW GlowYeild
  DW $0004
    DW $148E, $106A, $0C66, $0842
    DW GlowYeild
  DW $0004
    DW $1471, $104C, $0848, $0422
    DW GlowYeild
  DW $0004
    DW $1054, $0C2E, $0849, $0422
    DW GlowYeild
  DW $0004
    DW $0C37, $0C30, $042A, $0423
    DW GlowYeild
  DW GlowJMP, Tor_2Esc2_List_Loop

Tor_2Esc3_List:
  DW SetColorIndex, $0070
Tor_2Esc3_List_Loop:
  DW $0004
    DW $081A, $0812, $042B, $0423
    DW GlowYeild
  DW $0004
    DW $0C37, $0C30, $042A, $0423
    DW GlowYeild
  DW $0004
    DW $1054, $0C2E, $0849, $0422
    DW GlowYeild
  DW $0004
    DW $1471, $104C, $0848, $0422
    DW GlowYeild
  DW $0004
    DW $148E, $106A, $0C66, $0842
    DW GlowYeild
  DW $0004
    DW $18AB, $1488, $0C65, $0842
    DW GlowYeild
  DW $0004
    DW $1CC8, $1486, $1084, $0841
    DW GlowYeild
  DW $0004
    DW $20E5, $18A4, $1083, $0841
    DW GlowYeild
  DW $0004
    DW $1CC8, $1486, $1084, $0841
    DW GlowYeild
  DW $0004
    DW $18AB, $1488, $0C65, $0842
    DW GlowYeild
  DW $0004
    DW $148E, $106A, $0C66, $0842
    DW GlowYeild
  DW $0004
    DW $1471, $104C, $0848, $0422
    DW GlowYeild
  DW $0004
    DW $1054, $0C2E, $0849, $0422
    DW GlowYeild
  DW $0004
    DW $0C37, $0C30, $042A, $0423
    DW GlowYeild
  DW GlowJMP, Tor_2Esc3_List_Loop

Tor_2Esc4_List:
  DW SetColorIndex, $0070
Tor_2Esc4_List_Loop:
  DW $0004
    DW $081A, $0812, $042B, $0423
    DW GlowYeild
  DW $0004
    DW $0C37, $0C30, $042A, $0423
    DW GlowYeild
  DW $0004
    DW $1054, $0C2E, $0849, $0422
    DW GlowYeild
  DW $0004
    DW $1471, $104C, $0848, $0422
    DW GlowYeild
  DW $0004
    DW $148E, $106A, $0C66, $0842
    DW GlowYeild
  DW $0004
    DW $18AB, $1488, $0C65, $0842
    DW GlowYeild
  DW $0004
    DW $1CC8, $1486, $1084, $0841
    DW GlowYeild
  DW $0004
    DW $20E5, $18A4, $1083, $0841
    DW GlowYeild
  DW $0004
    DW $1CC8, $1486, $1084, $0841
    DW GlowYeild
  DW $0004
    DW $18AB, $1488, $0C65, $0842
    DW GlowYeild
  DW $0004
    DW $148E, $106A, $0C66, $0842
    DW GlowYeild
  DW $0004
    DW $1471, $104C, $0848, $0422
    DW GlowYeild
  DW $0004
    DW $1054, $0C2E, $0849, $0422
    DW GlowYeild
  DW $0004
    DW $0C37, $0C30, $042A, $0423
    DW GlowYeild
  DW GlowJMP, Tor_2Esc4_List_Loop

Tor_2Esc5_List:
  DW SetColorIndex, $0070
Tor_2Esc5_List_Loop:
  DW $0004
    DW $081A, $0812, $042B, $0423
    DW GlowYeild
  DW $0004
    DW $0C37, $0C30, $042A, $0423
    DW GlowYeild
  DW $0004
    DW $1054, $0C2E, $0849, $0422
    DW GlowYeild
  DW $0004
    DW $1471, $104C, $0848, $0422
    DW GlowYeild
  DW $0004
    DW $148E, $106A, $0C66, $0842
    DW GlowYeild
  DW $0004
    DW $18AB, $1488, $0C65, $0842
    DW GlowYeild
  DW $0004
    DW $1CC8, $1486, $1084, $0841
    DW GlowYeild
  DW $0004
    DW $20E5, $18A4, $1083, $0841
    DW GlowYeild
  DW $0004
    DW $1CC8, $1486, $1084, $0841
    DW GlowYeild
  DW $0004
    DW $18AB, $1488, $0C65, $0842
    DW GlowYeild
  DW $0004
    DW $148E, $106A, $0C66, $0842
    DW GlowYeild
  DW $0004
    DW $1471, $104C, $0848, $0422
    DW GlowYeild
  DW $0004
    DW $1054, $0C2E, $0849, $0422
    DW GlowYeild
  DW $0004
    DW $0C37, $0C30, $042A, $0423
    DW GlowYeild
  DW GlowJMP, Tor_2Esc5_List_Loop

Tor_2Esc6_List:
  DW SetColorIndex, $0070
Tor_2Esc6_List_Loop:
  DW $0004
    DW $081A, $0812, $042B, $0423
    DW GlowYeild
  DW $0004
    DW $0C37, $0C30, $042A, $0423
    DW GlowYeild
  DW $0004
    DW $1054, $0C2E, $0849, $0422
    DW GlowYeild
  DW $0004
    DW $1471, $104C, $0848, $0422
    DW GlowYeild
  DW $0004
    DW $148E, $106A, $0C66, $0842
    DW GlowYeild
  DW $0004
    DW $18AB, $1488, $0C65, $0842
    DW GlowYeild
  DW $0004
    DW $1CC8, $1486, $1084, $0841
    DW GlowYeild
  DW $0004
    DW $20E5, $18A4, $1083, $0841
    DW GlowYeild
  DW $0004
    DW $1CC8, $1486, $1084, $0841
    DW GlowYeild
  DW $0004
    DW $18AB, $1488, $0C65, $0842
    DW GlowYeild
  DW $0004
    DW $148E, $106A, $0C66, $0842
    DW GlowYeild
  DW $0004
    DW $1471, $104C, $0848, $0422
    DW GlowYeild
  DW $0004
    DW $1054, $0C2E, $0849, $0422
    DW GlowYeild
  DW $0004
    DW $0C37, $0C30, $042A, $0423
    DW GlowYeild
  DW GlowJMP, Tor_2Esc6_List_Loop

Tor_3EscTable:
  DW EmptyInit,Tor_3Esc0_List, EmptyInit,Tor_3Esc1_List, EmptyInit,Tor_3Esc2_List, EmptyInit,Tor_3Esc3_List
  DW EmptyInit,Tor_3Esc4_List, EmptyInit,Tor_3Esc5_List, EmptyInit,Tor_3Esc6_List, EmptyInit,Tor_3Esc7_List
Tor_3Esc0_List:
Tor_3Esc7_List:
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

  DW GlowJMP, Tor_4Esc0_List_Loop
Tor_4EscTable:
  DW EmptyInit,Tor_4Esc0_List, EmptyInit,Tor_4Esc1_List, EmptyInit,Tor_4Esc2_List, EmptyInit,Tor_4Esc3_List
  DW EmptyInit,Tor_4Esc4_List, EmptyInit,Tor_4Esc5_List, EmptyInit,Tor_4Esc6_List, EmptyInit,Tor_4Esc7_List
Tor_4Esc0_List:
Tor_4Esc7_List:
  DW SetColorIndex, $00E8
Tor_4Esc0_List_Loop:
  DW $0002
    DW $5294, $39CE, $2108, $1084, $0019, $0012
    DW SkipColors_4
    DW $7FFF
    DW GlowYeild
  DW $0002
    DW $4E75, $35AF, $1CE8, $0C64, $080D, $0809
    DW SkipColors_4
    DW $77BF
    DW GlowYeild
  DW $0002
    DW $4A55, $318F, $1CE9, $0C64, $1000, $1000
    DW SkipColors_4
    DW $739F
    DW GlowYeild
  DW $0002
    DW $4636, $2D70, $18C9, $0844, $080D, $0809
    DW SkipColors_4
    DW $6B5F
    DW GlowYeild
  DW $0002
    DW $3DF6, $2D70, $18CA, $0844, $0019, $0012
    DW SkipColors_4
    DW $673F
    DW GlowYeild
  DW $0002
    DW $39D7, $2951, $14AA, $0424, $080D, $0809
    DW SkipColors_4
    DW $5EFF
    DW GlowYeild
  DW $0002
    DW $35B7, $2531, $14AB, $0424, $1000, $1000
    DW SkipColors_4
    DW $5ADF
    DW GlowYeild
  DW $0002
    DW $3198, $2112, $108B, $0004, $080D, $0809
    DW SkipColors_4
    DW $529F
    DW GlowYeild
  DW $0002
    DW $35B7, $2531, $14AB, $0424, $1000, $1000
    DW SkipColors_4
    DW $5ADF
    DW GlowYeild
  DW $0002
    DW $39D7, $2951, $14AA, $0424, $080D, $0809
    DW SkipColors_4
    DW $5EFF
    DW GlowYeild
  DW $0002
    DW $3DF6, $2D70, $18CA, $0844, $0019, $0012
    DW SkipColors_4
    DW $673F
    DW GlowYeild
  DW $0002
    DW $4636, $2D70, $18C9, $0844, $080D, $0809
    DW SkipColors_4
    DW $6B5F
    DW GlowYeild
  DW $0002
    DW $4A55, $318F, $1CE9, $0C64, $1000, $1000
    DW SkipColors_4
    DW $739F
    DW GlowYeild
  DW $0002
    DW $4E75, $35AF, $1CE8, $0C64, $080D, $0809
    DW SkipColors_4
    DW $77BF
    DW GlowYeild
  DW GlowJMP, Tor_4Esc0_List_Loop

Tor_4Esc1_List:
  DW SetColorIndex, $00E8
Tor_4Esc1_List_Loop:
  DW $0002
    DW $5294, $39CE, $2108, $1084, $0019, $0012
    DW SkipColors_4
    DW $7FFF
    DW GlowYeild
  DW $0002
    DW $4E75, $35AF, $1CE8, $0C64, $080D, $0809
    DW SkipColors_4
    DW $77BF
    DW GlowYeild
  DW $0002
    DW $4A55, $318F, $1CE9, $0C64, $1000, $1000
    DW SkipColors_4
    DW $739F
    DW GlowYeild
  DW $0002
    DW $4636, $2D70, $18C9, $0844, $080D, $0809
    DW SkipColors_4
    DW $6B5F
    DW GlowYeild
  DW $0002
    DW $3DF6, $2D70, $18CA, $0844, $0019, $0012
    DW SkipColors_4
    DW $673F
    DW GlowYeild
  DW $0002
    DW $39D7, $2951, $14AA, $0424, $080D, $0809
    DW SkipColors_4
    DW $5EFF
    DW GlowYeild
  DW $0002
    DW $35B7, $2531, $14AB, $0424, $1000, $1000
    DW SkipColors_4
    DW $5ADF
    DW GlowYeild
  DW $0002
    DW $3198, $2112, $108B, $0004, $080D, $0809
    DW SkipColors_4
    DW $529F
    DW GlowYeild
  DW $0002
    DW $35B7, $2531, $14AB, $0424, $1000, $1000
    DW SkipColors_4
    DW $5ADF
    DW GlowYeild
  DW $0002
    DW $39D7, $2951, $14AA, $0424, $080D, $0809
    DW SkipColors_4
    DW $5EFF
    DW GlowYeild
  DW $0002
    DW $3DF6, $2D70, $18CA, $0844, $0019, $0012
    DW SkipColors_4
    DW $673F
    DW GlowYeild
  DW $0002
    DW $4636, $2D70, $18C9, $0844, $080D, $0809
    DW SkipColors_4
    DW $6B5F
    DW GlowYeild
  DW $0002
    DW $4A55, $318F, $1CE9, $0C64, $1000, $1000
    DW SkipColors_4
    DW $739F
    DW GlowYeild
  DW $0002
    DW $4E75, $35AF, $1CE8, $0C64, $080D, $0809
    DW SkipColors_4
    DW $77BF
    DW GlowYeild
  DW GlowJMP, Tor_4Esc1_List_Loop

Tor_4Esc2_List:
  DW SetColorIndex, $00E8
Tor_4Esc2_List_Loop:
  DW $0002
    DW $5294, $39CE, $2108, $1084, $0019, $0012
    DW SkipColors_4
    DW $7FFF
    DW GlowYeild
  DW $0002
    DW $4E75, $35AF, $1CE8, $0C64, $080D, $0809
    DW SkipColors_4
    DW $77BF
    DW GlowYeild
  DW $0002
    DW $4A55, $318F, $1CE9, $0C64, $1000, $1000
    DW SkipColors_4
    DW $739F
    DW GlowYeild
  DW $0002
    DW $4636, $2D70, $18C9, $0844, $080D, $0809
    DW SkipColors_4
    DW $6B5F
    DW GlowYeild
  DW $0002
    DW $3DF6, $2D70, $18CA, $0844, $0019, $0012
    DW SkipColors_4
    DW $673F
    DW GlowYeild
  DW $0002
    DW $39D7, $2951, $14AA, $0424, $080D, $0809
    DW SkipColors_4
    DW $5EFF
    DW GlowYeild
  DW $0002
    DW $35B7, $2531, $14AB, $0424, $1000, $1000
    DW SkipColors_4
    DW $5ADF
    DW GlowYeild
  DW $0002
    DW $3198, $2112, $108B, $0004, $080D, $0809
    DW SkipColors_4
    DW $529F
    DW GlowYeild
  DW $0002
    DW $35B7, $2531, $14AB, $0424, $1000, $1000
    DW SkipColors_4
    DW $5ADF
    DW GlowYeild
  DW $0002
    DW $39D7, $2951, $14AA, $0424, $080D, $0809
    DW SkipColors_4
    DW $5EFF
    DW GlowYeild
  DW $0002
    DW $3DF6, $2D70, $18CA, $0844, $0019, $0012
    DW SkipColors_4
    DW $673F
    DW GlowYeild
  DW $0002
    DW $4636, $2D70, $18C9, $0844, $080D, $0809
    DW SkipColors_4
    DW $6B5F
    DW GlowYeild
  DW $0002
    DW $4A55, $318F, $1CE9, $0C64, $1000, $1000
    DW SkipColors_4
    DW $739F
    DW GlowYeild
  DW $0002
    DW $4E75, $35AF, $1CE8, $0C64, $080D, $0809
    DW SkipColors_4
    DW $77BF
    DW GlowYeild
  DW GlowJMP, Tor_4Esc2_List_Loop

Tor_4Esc3_List:
  DW SetColorIndex, $00E8
Tor_4Esc3_List_Loop:
  DW $0002
    DW $5294, $39CE, $2108, $1084, $0019, $0012
    DW SkipColors_4
    DW $7FFF
    DW GlowYeild
  DW $0002
    DW $4E75, $35AF, $1CE8, $0C64, $080D, $0809
    DW SkipColors_4
    DW $77BF
    DW GlowYeild
  DW $0002
    DW $4A55, $318F, $1CE9, $0C64, $1000, $1000
    DW SkipColors_4
    DW $739F
    DW GlowYeild
  DW $0002
    DW $4636, $2D70, $18C9, $0844, $080D, $0809
    DW SkipColors_4
    DW $6B5F
    DW GlowYeild
  DW $0002
    DW $3DF6, $2D70, $18CA, $0844, $0019, $0012
    DW SkipColors_4
    DW $673F
    DW GlowYeild
  DW $0002
    DW $39D7, $2951, $14AA, $0424, $080D, $0809
    DW SkipColors_4
    DW $5EFF
    DW GlowYeild
  DW $0002
    DW $35B7, $2531, $14AB, $0424, $1000, $1000
    DW SkipColors_4
    DW $5ADF
    DW GlowYeild
  DW $0002
    DW $3198, $2112, $108B, $0004, $080D, $0809
    DW SkipColors_4
    DW $529F
    DW GlowYeild
  DW $0002
    DW $35B7, $2531, $14AB, $0424, $1000, $1000
    DW SkipColors_4
    DW $5ADF
    DW GlowYeild
  DW $0002
    DW $39D7, $2951, $14AA, $0424, $080D, $0809
    DW SkipColors_4
    DW $5EFF
    DW GlowYeild
  DW $0002
    DW $3DF6, $2D70, $18CA, $0844, $0019, $0012
    DW SkipColors_4
    DW $673F
    DW GlowYeild
  DW $0002
    DW $4636, $2D70, $18C9, $0844, $080D, $0809
    DW SkipColors_4
    DW $6B5F
    DW GlowYeild
  DW $0002
    DW $4A55, $318F, $1CE9, $0C64, $1000, $1000
    DW SkipColors_4
    DW $739F
    DW GlowYeild
  DW $0002
    DW $4E75, $35AF, $1CE8, $0C64, $080D, $0809
    DW SkipColors_4
    DW $77BF
    DW GlowYeild
  DW GlowJMP, Tor_4Esc3_List_Loop

Tor_4Esc4_List:
  DW SetColorIndex, $00E8
Tor_4Esc4_List_Loop:
  DW $0002
    DW $5294, $39CE, $2108, $1084, $0019, $0012
    DW SkipColors_4
    DW $7FFF
    DW GlowYeild
  DW $0002
    DW $4E75, $35AF, $1CE8, $0C64, $080D, $0809
    DW SkipColors_4
    DW $77BF
    DW GlowYeild
  DW $0002
    DW $4A55, $318F, $1CE9, $0C64, $1000, $1000
    DW SkipColors_4
    DW $739F
    DW GlowYeild
  DW $0002
    DW $4636, $2D70, $18C9, $0844, $080D, $0809
    DW SkipColors_4
    DW $6B5F
    DW GlowYeild
  DW $0002
    DW $3DF6, $2D70, $18CA, $0844, $0019, $0012
    DW SkipColors_4
    DW $673F
    DW GlowYeild
  DW $0002
    DW $39D7, $2951, $14AA, $0424, $080D, $0809
    DW SkipColors_4
    DW $5EFF
    DW GlowYeild
  DW $0002
    DW $35B7, $2531, $14AB, $0424, $1000, $1000
    DW SkipColors_4
    DW $5ADF
    DW GlowYeild
  DW $0002
    DW $3198, $2112, $108B, $0004, $080D, $0809
    DW SkipColors_4
    DW $529F
    DW GlowYeild
  DW $0002
    DW $35B7, $2531, $14AB, $0424, $1000, $1000
    DW SkipColors_4
    DW $5ADF
    DW GlowYeild
  DW $0002
    DW $39D7, $2951, $14AA, $0424, $080D, $0809
    DW SkipColors_4
    DW $5EFF
    DW GlowYeild
  DW $0002
    DW $3DF6, $2D70, $18CA, $0844, $0019, $0012
    DW SkipColors_4
    DW $673F
    DW GlowYeild
  DW $0002
    DW $4636, $2D70, $18C9, $0844, $080D, $0809
    DW SkipColors_4
    DW $6B5F
    DW GlowYeild
  DW $0002
    DW $4A55, $318F, $1CE9, $0C64, $1000, $1000
    DW SkipColors_4
    DW $739F
    DW GlowYeild
  DW $0002
    DW $4E75, $35AF, $1CE8, $0C64, $080D, $0809
    DW SkipColors_4
    DW $77BF
    DW GlowYeild
  DW GlowJMP, Tor_4Esc4_List_Loop

Tor_4Esc5_List:
  DW SetColorIndex, $00E8
Tor_4Esc5_List_Loop:
  DW $0002
    DW $5294, $39CE, $2108, $1084, $0019, $0012
    DW SkipColors_4
    DW $7FFF
    DW GlowYeild
  DW $0002
    DW $4E75, $35AF, $1CE8, $0C64, $080D, $0809
    DW SkipColors_4
    DW $77BF
    DW GlowYeild
  DW $0002
    DW $4A55, $318F, $1CE9, $0C64, $1000, $1000
    DW SkipColors_4
    DW $739F
    DW GlowYeild
  DW $0002
    DW $4636, $2D70, $18C9, $0844, $080D, $0809
    DW SkipColors_4
    DW $6B5F
    DW GlowYeild
  DW $0002
    DW $3DF6, $2D70, $18CA, $0844, $0019, $0012
    DW SkipColors_4
    DW $673F
    DW GlowYeild
  DW $0002
    DW $39D7, $2951, $14AA, $0424, $080D, $0809
    DW SkipColors_4
    DW $5EFF
    DW GlowYeild
  DW $0002
    DW $35B7, $2531, $14AB, $0424, $1000, $1000
    DW SkipColors_4
    DW $5ADF
    DW GlowYeild
  DW $0002
    DW $3198, $2112, $108B, $0004, $080D, $0809
    DW SkipColors_4
    DW $529F
    DW GlowYeild
  DW $0002
    DW $35B7, $2531, $14AB, $0424, $1000, $1000
    DW SkipColors_4
    DW $5ADF
    DW GlowYeild
  DW $0002
    DW $39D7, $2951, $14AA, $0424, $080D, $0809
    DW SkipColors_4
    DW $5EFF
    DW GlowYeild
  DW $0002
    DW $3DF6, $2D70, $18CA, $0844, $0019, $0012
    DW SkipColors_4
    DW $673F
    DW GlowYeild
  DW $0002
    DW $4636, $2D70, $18C9, $0844, $080D, $0809
    DW SkipColors_4
    DW $6B5F
    DW GlowYeild
  DW $0002
    DW $4A55, $318F, $1CE9, $0C64, $1000, $1000
    DW SkipColors_4
    DW $739F
    DW GlowYeild
  DW $0002
    DW $4E75, $35AF, $1CE8, $0C64, $080D, $0809
    DW SkipColors_4
    DW $77BF
    DW GlowYeild
  DW GlowJMP, Tor_4Esc5_List_Loop

Tor_4Esc6_List:
  DW SetColorIndex, $00E8
Tor_4Esc6_List_Loop:
  DW $0002
    DW $5294, $39CE, $2108, $1084, $0019, $0012
    DW SkipColors_4
    DW $7FFF
    DW GlowYeild
  DW $0002
    DW $4E75, $35AF, $1CE8, $0C64, $080D, $0809
    DW SkipColors_4
    DW $77BF
    DW GlowYeild
  DW $0002
    DW $4A55, $318F, $1CE9, $0C64, $1000, $1000
    DW SkipColors_4
    DW $739F
    DW GlowYeild
  DW $0002
    DW $4636, $2D70, $18C9, $0844, $080D, $0809
    DW SkipColors_4
    DW $6B5F
    DW GlowYeild
  DW $0002
    DW $3DF6, $2D70, $18CA, $0844, $0019, $0012
    DW SkipColors_4
    DW $673F
    DW GlowYeild
  DW $0002
    DW $39D7, $2951, $14AA, $0424, $080D, $0809
    DW SkipColors_4
    DW $5EFF
    DW GlowYeild
  DW $0002
    DW $35B7, $2531, $14AB, $0424, $1000, $1000
    DW SkipColors_4
    DW $5ADF
    DW GlowYeild
  DW $0002
    DW $3198, $2112, $108B, $0004, $080D, $0809
    DW SkipColors_4
    DW $529F
    DW GlowYeild
  DW $0002
    DW $35B7, $2531, $14AB, $0424, $1000, $1000
    DW SkipColors_4
    DW $5ADF
    DW GlowYeild
  DW $0002
    DW $39D7, $2951, $14AA, $0424, $080D, $0809
    DW SkipColors_4
    DW $5EFF
    DW GlowYeild
  DW $0002
    DW $3DF6, $2D70, $18CA, $0844, $0019, $0012
    DW SkipColors_4
    DW $673F
    DW GlowYeild
  DW $0002
    DW $4636, $2D70, $18C9, $0844, $080D, $0809
    DW SkipColors_4
    DW $6B5F
    DW GlowYeild
  DW $0002
    DW $4A55, $318F, $1CE9, $0C64, $1000, $1000
    DW SkipColors_4
    DW $739F
    DW GlowYeild
  DW $0002
    DW $4E75, $35AF, $1CE8, $0C64, $080D, $0809
    DW SkipColors_4
    DW $77BF
    DW GlowYeild
  DW GlowJMP, Tor_4Esc6_List_Loop

print pc

org $8DF765
SkyFlash:
  DW $00BB, SkyFlashTable
org $8DF760
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
org $8DFFC9
Tor_1Esc:
  DW $00BB, Tor_1EscTable
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
