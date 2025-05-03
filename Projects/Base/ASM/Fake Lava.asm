lorom

!bank_90_free_space_start = $90FC00
!bank_90_free_space_end = $90FC10
!bank_91_free_space_start = $91FFEE
!bank_91_free_space_end = $91FFFF
!bank_88_free_space_start = $88EE32
!bank_88_free_space_end = $88EE50

; Patch Samus interactions with lava/acid, replacing instances of LDA $1962
; (lava/acid Y position) with a hook that returns #$8000 if lava/acid physics
; is disabled. The code in all these places then handles this negative value
; by treating lava/acid as disabled.
org $9081C0 : JSR CheckLavaActive_90
org $908219 : JSR CheckLavaActive_90
org $90843C : JSR CheckLavaActive_90
org $908E3A : JSR CheckLavaActive_90
org $909758 : JSR CheckLavaActive_90
org $9098D9 : JSR CheckLavaActive_90
org $909966 : JSR CheckLavaActive_90
org $9099F3 : JSR CheckLavaActive_90
org $909A46 : JSR CheckLavaActive_90
org $909BEB : JSR CheckLavaActive_90
org $909C3B : JSR CheckLavaActive_90
org $909C72 : JSR CheckLavaActive_90
org $90A458 : JSR CheckLavaActive_90
org $90EE03 : JSR CheckLavaActive_90
org $90EE86 : JSR CheckLavaActive_90
org $91D9D1 : JSR CheckLavaActive_91
org $91F12D : JSR CheckLavaActive_91
org $91F17D : JSR CheckLavaActive_91
org $91F6A9 : JSR CheckLavaActive_91
org $91F70A : JSR CheckLavaActive_91
org $91FA8D : JSR CheckLavaActive_91
org $91FB36 : JSR CheckLavaActive_91

; Patch lava/acid initialization, to avoid spawning a BG2 Y scroll HDMA object
; if lava/acid physics and wavy effect are both disabled. This can reduce
; lag and also avoid interfering with G-mode Crystal Flash strats.
org $88B28D : JSL MaybeSpawnBG2ScrollHDMA : nop : nop : nop : nop
org $88B2B5 : JSL MaybeSpawnBG2ScrollHDMA : nop : nop : nop : nop

; For lava/acid, use $0010 instead of $0004 as the liquidflags bit to enable
; horizontal wavy BG2 effect, since we are using $0004 to disable lava/acid physics.
; With lava/acid, the horizontal wavy BG2 effect is never used anyway (and probably never
; should be used); so if we wanted to use the bit $0010 for something else, then
; "BIT #$0012" below could just be replaced with "BIT #$0002".
org $88B4E4
  BIT #$0012

org !bank_90_free_space_start
CheckLavaActive_90:
  ; replaces LDA $1962, to override the value with #$8000 if lava physics is disabled.
  LDA $197E
  BIT #$0004
  BEQ +
  LDA #$8000  ; set negative bit
  RTS
+
  LDA $1962
  RTS
warnpc !bank_90_free_space_end

org !bank_91_free_space_start
CheckLavaActive_91:
  ; replaces LDA $1962, to override the value with #$8000 if lava physics is disabled.
  LDA $197E
  BIT #$0004
  BEQ +
  LDA #$8000  ; set negative bit
  RTS
+
  LDA $1962
  RTS
warnpc !bank_91_free_space_end

org !bank_88_free_space_start
MaybeSpawnBG2ScrollHDMA:
  LDA $197E
  BIT #$0004  ; is lava/acid physics disabled?
  BEQ +       ; (if not, spawn HDMA object as usual)
  BIT #$0012  ; is wavy effect enabled?
  BNE +       ; (if so, spawn HDMA object as usual)
  RTL
+  
  ; Spawn BG2 scroll HDMA object, for the wavy heat effect
  JSL $888435
  db $42, $10, $F0, $C3
  RTL
warnpc !bank_88_free_space_end
