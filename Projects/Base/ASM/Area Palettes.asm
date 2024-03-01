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


org $8AC000
EnablePalettesFlag:
  ; Two bytes go here
  ; DW $F0F0 ; vanilla = $1478

org $8AC002
GetPalettePointer:
  ; Enable area palettes is either the flag is set in ROM or one of the debug events is set
  LDA EnablePalettesFlag
  CMP #$F0F0
  BEQ UseMapArea
  LDA $7ED824 ; event bits $20-27
  AND #$00FF
  BNE UseMapArea

;UseTilesetArea:
  LDX $7E07BB ; tileset index
  LDA $8F0003,X
  AND #$00FF
  TAX
  LDA StandardArea,X
  AND #$00FF
  BRA LoadBasedOnArea
UseMapArea:
  LDA $1F5B  ; map area
  ASL
  CLC
  ADC $1F5B
  AND #$00FF
  ;BRA LoadBasedOnArea

LoadBasedOnArea:
  TAX
  LDA AreaPalettes+1,X
  STA $07C7 ; palette bank
  LDA AreaPalettes+0,X
  STA $12 ; palette base offset

  LDX $7E07BB ; tileset index
  LDA $8F0003,X
  AND #$00FF

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
  DB $06*3, $06*3, $06*3, $60*3, $60*3, $60*3 ;Ceres
  DB $00*3, $00*3, $00*3, $00*3, $00*3 ;Utility Rooms
  ;Bosses
  DB $01*3 ;Kraid
  DB $04*3 ;Draygon
  DB $04*3 ;Draygon
  DB $01*3 ;SpoSpo
  DB $03*3 ;Phantoon

; Use "InputFile" working directory mode in SMART if you want this to assemble in xkas
; Each uncompressed paletter is 256 bytes. Compressing these palettes doesn't always make them smaller anyway

macro PaletteFile(t, n, area)
AreaPalettes_<n>_<t>:
  DB $E0, $FF ; header for the decompressor (copy $100 literal bytes)
incbin ..\..\<area>\Export\Tileset\SCE\<t>\palette.snes ; not actually compressed
  DB $FF ; footer for the decompressor
  DB $FF ; 1 byte padding
endmacro

macro PaletteSet(n, area)
!dir = ..\..\<area>\Export\Tileset\SCE
!file = palette.snes

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