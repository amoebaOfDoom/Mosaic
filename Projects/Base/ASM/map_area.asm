; This is here so we can test this stuff in Mosaic without having the map code in too
; We shouldn't need it in the main repo

; Set the "map area" to the area of the first room loaded and then never changes it

lorom
org $82DE86
  ;STA $079F
  JSR SetMapAreaInject
org $82BEED ; overwrite unused code
SetMapAreaInject:
  LDA $1F5B
  AND #$FF00
  CMP #$E700
  BEQ +

  LDA $079F
  AND #$00FF
  ORA #$E700
  STA $1F5B
+
  RTS
