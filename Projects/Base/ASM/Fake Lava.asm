lorom

org $88B4E4
  BIT #$0012


org $9081D8
  ;LDA $09A2
  ;BIT #$0020
  LDA $197E
  JSR CheckLavaPhysics

org $90820A
  BRA LiquidDamageEffect
org $908258
LiquidDamageEffect:

org $909741
  ;LDA $09A2
  ;BIT #$0020
  LDA $197E
  JSR CheckLavaPhysics

org $9098C2
  ;LDA $09A2
  ;BIT #$0020
  LDA $197E
  JSR CheckLavaPhysics

org $9099DC
  ;LDA $09A2
  ;BIT #$0020
  LDA $197E
  JSR CheckLavaPhysics

org $909A2F
  ;LDA $09A2
  ;BIT #$0020
  LDA $197E
  JSR CheckLavaPhysics

org $909BD4
  ;LDA $09A2
  ;BIT #$0020
  LDA $197E
  JSR CheckLavaPhysics

org $909C5B
  ;LDA $09A2
  ;BIT #$0020
  LDA $197E
  JSR CheckLavaPhysics

org $90A439
  ;LDA $0A74
  ;BIT #$0004
  LDA $197E
  JSR CheckLavaPhysics

org $91D9B2
  ;LDA $0A74
  ;BIT #$0004
  LDA $197E
  JSR CheckLavaPhysics_3

org $91F68A
  ;LDA $09A2
  ;BIT #$0020
  LDA $197E
  JSR CheckLavaPhysics_3

org $91F6EB
  ;LDA $09A2
  ;BIT #$0020
  LDA $197E
  JSR CheckLavaPhysics_3

org $91FA76
  ;JSL $90EC3E
  ;LDA $195E
  LDA $197E
  JSL CheckLavaPhysics_2

org $91FB0E
  ;LDA $09A2
  ;BIT #$0020
  LDA $197E
  JSR CheckLavaPhysics_3


org $90FC00 ; free space
CheckLavaPhysics:
  BIT #$0004
  BEQ +
  RTS
+
  LDA $09A2
  BIT #$0020
  RTS

CheckLavaPhysics_2:
  LDA $197E
  JSR CheckLavaPhysics
  BNE +
  JSL $90EC3E
  LDA $195E
  RTL
+
  LDA #$FFFF
  RTL


org $91FFEE ; free space
CheckLavaPhysics_3:
  BIT #$0004
  BEQ +
  RTS
+
  LDA $09A2
  BIT #$0020
  RTS
warnpc $91FFFF
