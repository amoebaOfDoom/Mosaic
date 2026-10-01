lorom

org $A0F7D3


; freespace
org $B2FEAA
print "Init"
print pc
Tube_Init:
  LDX $0E54
  LDA #SpriteMap
  STA $0F8E,X
  LDA #$0001
  STA $0F94,X ; Enemy instruction timer
  STZ $0F90,X ; Enemy timer
  STZ $0F98,X ; Enemy VRAM tiles index
  LDA #InstructionList
  STA $0F92,X
  LDA $0F86,X ; Enemy properties
  ORA #$0400  ; Disable hitbox
  STA $0F86,X
  LDA #$01D0  ; Setup sprite extended mode area
  STA $0F98,X ; VRAM tiles index

  LDA $0F7A,X ; enemy X position
  AND #$FF00
  ORA #$0080
  STA $0F7A,X ; Center on screen

  PHB
  PEA.w $7E7E
  PLB
  PLB
  LDA $0F96,X ; Palette sprite mask
  LSR : LSR : LSR : LSR
  TAX

  LDY #$0006
-
  LDA $C208,Y
  STA $C30E,X
  DEX
  DEX
  DEY
  DEY
  BPL -
  PLB

print "Main"
print pc
Tube_Main:
  LDX $0E54
  LDA $0915 ; Screen's Y position in pixels
  AND #$FFF0
  CLC
  ADC #$0010
  STA $0F7E,X ; enemy Y position
  RTL

InstructionList:
  DW $0001, SpriteMap
  DW $812F

; s = size (8/0)
; x = x offset (9 bit)
; y = y offset
; t = tile num
; v = v flip
; h = h flip
; p = priority
; DW $sxxx : DB $yy,    $tt, #%vhpp000t
macro TubeRow(y)
  DW $81F0 : DB <y>*16, $00, #%01100001
  DW $8000 : DB <y>*16, $00, #%00100001
endmacro

SpriteMap:
  DW 2*14
%TubeRow(0)
%TubeRow(1)
%TubeRow(2)
%TubeRow(3)
%TubeRow(4)
%TubeRow(5)
%TubeRow(6)
%TubeRow(7)
%TubeRow(8)
%TubeRow(9)
%TubeRow(10)
%TubeRow(11)
%TubeRow(12)
%TubeRow(13)

warnpc $B2FFFF
