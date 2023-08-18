lorom

org $89AC62
  JSR GetTilesetIndex ;LDA $079F
  ASL A
  TAY
  LDA GlowTypeTable,Y ;DB is $83

org $89AC98
  JSR GetTilesetIndex ;LDA $079F
  ASL A
  TAY
  LDA AnimTypeTable,Y

org $89AF60 ;free space
GetTilesetIndex:
  PHX
  LDX $07BB
  LDA $8F0003,X
  PLX
  AND #$00FF
  RTS

; Move animation VRAM offsets
org $878279
  DW $2500 ; R_Tread
org $87827F
  DW $2500 ; L_Tread
org $878285
  DW $2400 ; Vileplum
org $87828B
  DW $26D0 ; SandHead
org $878291
  DW $26F0 ; SandFall

;Move vileplume tilemap tiles
org $849E0D
  DW $0002, $37D9, $87D8
  DB $FE, $00
  DW $0002, $83D8, $53D9
  DB $FE, $FF
  DW $0004, $23B8, $23B9, $27B9, $27B8
  DW $0000
org $849E45
  DW $0002, $07DB, $87DA
  DB $FE, $00
  DW $0002, $83DA, $03DB
  DB $FE, $FF
  DW $0004, $23BA, $23BB, $27BB, $27BA
  DW $0000
org $849E61
  DW $0002, $07DD, $87DC
  DB $FE, $00
  DW $0002, $83DC, $03DD
  DB $FE, $FF
  DW $0004, $23BC, $23BD, $27BD, $27BC
  DW $0000
org $849E7D
  DW $0002, $07DF, $87DE
  DB $FE, $00
  DW $0002, $83DE, $03DF
  DB $FE, $FF
  DW $0004, $23BE, $23BF, $27BF, $27BE
  DW $0000

org $849E99
  DW $0002, $3FD9, $8FD8
  DB $FE, $00
  DW $0002, $8BD8, $5BD9
  DB $FE, $01
  DW $0004, $2BB8, $2BB9, $2FB9, $2FB8
  DW $0000
org $849ED1
  DW $0002, $0FDB, $8FDA
  DB $FE, $00
  DW $0002, $8BDA, $0BDB
  DB $FE, $01
  DW $0004, $2BBA, $2BBB, $2FBB, $2FBA
  DW $0000
org $849EED
  DW $0002, $0FDD, $8FDC
  DB $FE, $00
  DW $0002, $8BDC, $0BDD
  DB $FE, $01
  DW $0004, $2BBC, $2BBD, $2FBD, $2FBC
  DW $0000
org $849F09
  DW $0002, $0FDF, $8FDE
  DB $FE, $00
  DW $0002, $8BDE, $0BDF
  DB $FE, $01
  DW $0004, $2BBE, $2BBF, $2FBF, $2FBE
  DW $0000

org $83B480

!NullGlow = $F745
;!Statue_3 = $F749
;!Statue_1 = $F74D
;!Statue_4 = $F751
;!Statue_2 = $F755
;!BT_Glow_ = $F759
;!GT_Glow_ = $F75D
!SamusHot = $F761
!SkyFlash = $F765
;!UnusedG1 = $F769
!WS_Green = $F76D
;!UnusedG2 = $F771
!Blue_BG_ = $F775
!SpoSpoBG = $F779
!Purp_BG_ = $F77D
!Beacon__ = $F781
!Nor_Hot1 = $F785
!Nor_Hot2 = $F789
!Nor_Hot3 = $F78D
!Nor_Hot4 = $F791
!SandFlor = $F795
!HevySand = $F799
!Waterfal = $F79D
!Tourian1 = $F7A1
!Tourian2 = $F7A5
!Tor_1Esc = $FFC9
!Tor_2Esc = $FFCD
!Tor_3Esc = $FFD1
!Tor_4Esc = $FFD5
!OldT1Esc = $FFD9
!OldT2Esc = $FFDD
!OldT3Esc = $FFE1
!SurfcEsc = $FFE5
!Sky_Esc_ = $FFE9
!CRE_Esc_ = $FFED

  ;  01         02         04         08         10         20         40         80
Glow_Area_0a:
  DW !SkyFlash, !SurfcEsc, !Sky_Esc_, !NullGlow, !NullGlow, !SandFlor, !HevySand, !SamusHot
Glow_Area_0b:
  DW !OldT3Esc, !NullGlow, !NullGlow, !OldT1Esc, !OldT2Esc, !SandFlor, !HevySand, !SamusHot
Glow_Area_1:
  DW !Blue_BG_, !Purp_BG_, !Beacon__, !SpoSpoBG, !NullGlow, !SandFlor, !HevySand, !SamusHot
Glow_Area_2:
  DW !SamusHot, !Nor_Hot1, !Nor_Hot2, !Nor_Hot3, !Nor_Hot4, !SandFlor, !HevySand, !SamusHot
Glow_Area_3:
  DW !WS_Green, !NullGlow, !NullGlow, !NullGlow, !NullGlow, !SandFlor, !HevySand, !SamusHot
Glow_Area_4:
  DW !SandFlor, !HevySand, !Waterfal, !NullGlow, !NullGlow, !SandFlor, !HevySand, !SamusHot
Glow_Area_5:
  DW !Tor_4Esc, !Tourian1, !Tor_3Esc, !Tor_1Esc, !Tor_2Esc, !SandFlor, !HevySand, !SamusHot
Glow_Area_6:
  DW !NullGlow, !NullGlow, !NullGlow, !NullGlow, !NullGlow, !SandFlor, !HevySand, !SamusHot
Glow_Area_7:
  DW !NullGlow, !NullGlow, !NullGlow, !NullGlow, !NullGlow, !SandFlor, !HevySand, !SamusHot


!NullAnim = $824B
!V_Spike_ = $8251
!H_Spike_ = $8257
!Ocean___ = $825D
;!UnusedA1 = $8263
;!UnusedA2 = $8269
!Laundry_ = $826F
!R_Tread_ = $8275
!L_Tread_ = $827B
!VilePlum = $8281
!SandHead = $8287
!SandFall = $828D

  ;  01         02         04         08         10         20         40         80
Anim_Area_0:
  DW !H_Spike_, !V_Spike_, !Ocean___, !SandFall, !SandHead, !VilePlum, !R_Tread_, !L_Tread_
Anim_Area_1:
  DW !H_Spike_, !V_Spike_, !NullAnim, !SandFall, !SandHead, !VilePlum, !R_Tread_, !L_Tread_
Anim_Area_2:
  DW !H_Spike_, !V_Spike_, !NullAnim, !SandFall, !SandHead, !VilePlum, !R_Tread_, !L_Tread_
Anim_Area_3:
  DW !H_Spike_, !V_Spike_, !Laundry_, !SandFall, !SandHead, !VilePlum, !R_Tread_, !L_Tread_
Anim_Area_4:
  DW !H_Spike_, !V_Spike_, !NullAnim, !SandFall, !SandHead, !VilePlum, !R_Tread_, !L_Tread_
Anim_Area_5:
  DW !H_Spike_, !V_Spike_, !NullAnim, !SandFall, !SandHead, !VilePlum, !R_Tread_, !L_Tread_
Anim_Area_6:
  DW !H_Spike_, !V_Spike_, !NullAnim, !SandFall, !SandHead, !VilePlum, !R_Tread_, !L_Tread_
Anim_Area_7:
  DW !H_Spike_, !V_Spike_, !NullAnim, !SandFall, !SandHead, !VilePlum, !R_Tread_, !L_Tread_

GlowTypeTable:
  DW Glow_Area_0a, Glow_Area_0a ;Crateria Surface
  DW Glow_Area_0b, Glow_Area_0b ;Inner Crateria
  DW Glow_Area_3, Glow_Area_3 ;Wrecked Ship
  DW Glow_Area_1, Glow_Area_1 ;Brinstar
  DW Glow_Area_1 ;Tourian Statues Access
  DW Glow_Area_2, Glow_Area_2 ;Norfair
  DW Glow_Area_4, Glow_Area_4 ;Maridia
  DW Glow_Area_5, Glow_Area_5 ;Tourian
  DW Glow_Area_6, Glow_Area_6, Glow_Area_6, Glow_Area_6, Glow_Area_6, Glow_Area_6 ;Ceres
  DW Glow_Area_7, Glow_Area_7, Glow_Area_7, Glow_Area_7, Glow_Area_7 ;Utility Rooms
  ;Bosses
  DW Glow_Area_1 ;Kraid
  DW Glow_Area_2 ;Crocomire
  DW Glow_Area_4 ;Draygon
  DW Glow_Area_1 ;SpoSpo
  DW Glow_Area_3 ;Phantoon
  
AnimTypeTable:
  DW Anim_Area_0, Anim_Area_0 ;Crateria Surface
  DW Anim_Area_0, Anim_Area_0 ;Inner Crateria
  DW Anim_Area_3, Anim_Area_3 ;Wrecked Ship
  DW Anim_Area_1, Anim_Area_1 ;Brinstar
  DW Anim_Area_1 ;Tourian Statues Access
  DW Anim_Area_2, Anim_Area_2 ;Norfair
  DW Anim_Area_4, Anim_Area_4 ;Maridia
  DW Anim_Area_5, Anim_Area_5 ;Tourian
  DW Anim_Area_6, Anim_Area_6, Anim_Area_6, Anim_Area_6, Anim_Area_6, Anim_Area_6 ;Ceres
  DW Anim_Area_0, Anim_Area_0, Anim_Area_0, Anim_Area_0, Anim_Area_0 ;Utility Rooms
  ;Bosses
  DW Anim_Area_1 ;Kraid
  DW Anim_Area_2 ;Crocomire
  DW Anim_Area_4 ;Draygon
  DW Anim_Area_1 ;SpoSpo
  DW Anim_Area_3 ;Phantoon
