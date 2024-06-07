; This is here so we can test this stuff in Mosaic without having the map code in too
; We shouldn't need it in the main repo

; Set the "map area" based on the first event bit set in $20-27
; Set bit 20 for Crateria, etc
; If no bits are set, then always set the map area to match the tileset

lorom
org $82DEF7
  ;LDX $07BB
  JSR SetMapAreaInject
org $82BEA3 ; overwrite unused code
SetMapAreaInject:
  LDA $7ED824 ; event bits $20-27
  AND #$00FF
  BEQ SkipSettingMapArea
  STZ $1F5B
  DEC $1F5B
-
  INC $1F5B
  LSR
  BCC -
  LDX $07BB
  RTS

; In Mosaic the map area is only used if one of the event bits is set
; In an actual map rando seed, this is set up by the map area.
; So nothing needs to be done if no event bits are set.
SkipSettingMapArea:
  LDX $07BB
  RTS

warnpc $82BF03