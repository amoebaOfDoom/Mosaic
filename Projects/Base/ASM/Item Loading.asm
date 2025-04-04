lorom

; Load the graphics for Energy Tanks, Missiles, Supers, and Power Bombs
; dynamically, the same as with all other items, to free up space in the CRE
; graphics. In order to patch the PLM instruction lists in place, we make
; a helper function for loading item PLM graphics using palette 0 for all tiles.

!bank_84_free_space_start = $8486D1   ; space where vanilla has an unused function
!bank_84_free_space_end = $84870B

!bank_89_free_space_start = $899200   ; skipping $9100 since Map Rando uses it for walljump boots.
!bank_89_free_space_end = $899600

macro RegularItemPLM(addr, gfx)
org $840000+<addr>
  dw load_item_gfx, <gfx>  ; load item graphics
  dw $887C, <addr>+$21           ; go to end if item is collected
  dw $8A24, <addr>+$18           ; set link instruction
  dw $86C1, $DF89                ; pre-instruction = go to link instruction if triggered
  dw $E04F                       ; draw first frame
  dw $E067                       ; draw second frame
  dw $8724, <addr>+$10           ; loop
endmacro

macro ChozoBallItemPLM(addr, gfx)
org $840000+<addr>
  dw load_item_gfx, <gfx>  ; load item graphics
  dw $887C, <addr>+$2C           ; go to end if item is collected
  dw $8A2E, $DFAF                ; call $DFAF (item orb)
  dw $8A2E, $DFC7                ; call $DFC7 (item orb burst)
  dw $8A24, <addr>+$23           ; set link instruction
  dw $86C1, $DF89                ; pre-instruction = go to link instruction if triggered
  dw $874E
  db $16                         ; timer = $16
  dw $E04F                       ; draw first frame
  dw $E067                       ; draw second frame
  dw $8724, <addr>+$1B           ; loop
endmacro

macro ShotBlockItemPLM(addr, gfx)
org $840000+<addr>
  dw load_item_gfx, <gfx>  ; load item graphics
  dw $8A2E, $E007                ; call $E007 (item shot block)
  dw $887C, <addr>+$30           ; go to end if item is collected
  dw $8A24, <addr>+$27           ; set link instruction
  dw $86C1, $DF89                ; pre-instruction = go to link instruction if triggered
  dw $874E
  db $16                         ; timer = $16
  dw $E04F                       ; draw first frame
  dw $E067                       ; draw second frame
  dw $873F, <addr>+$17           ; decrement timer and loop if non-zero
  dw $8A2E, $E020                ; call $E020 (item shot block reconcealing)
  dw $8724, <addr>+$04           ; go to start (without loading graphics again)
endmacro

; Patch item PLM instruction lists:
%RegularItemPLM($E099, etank_gfx_header)
%RegularItemPLM($E0BE, missile_gfx_header)
%RegularItemPLM($E0E3, super_gfx_header)
%RegularItemPLM($E108, pb_gfx_header)
%ChozoBallItemPLM($E44A, etank_gfx_header)
%ChozoBallItemPLM($E47C, missile_gfx_header)
%ChozoBallItemPLM($E4AE, super_gfx_header)
%ChozoBallItemPLM($E4E0, pb_gfx_header)
%ShotBlockItemPLM($E911, etank_gfx_header)
%ShotBlockItemPLM($E949, missile_gfx_header)
%ShotBlockItemPLM($E981, super_gfx_header)
%ShotBlockItemPLM($E9B9, pb_gfx_header)

; Unused space in bank $84:
org !bank_84_free_space_start
; load item PLM graphics, with reference to item graphics header anywhere in bank $84
; (rather than it having to be embedded in the instruction list)
load_item_gfx:
    PHY

    ; Y = pointer to item graphics header (at [[Y]])
    LDA $0000,y
    TAY

    ; call vanilla function to load item PLM graphics
    JSR $8764

    PLY
    INY
    INY
    RTS

etank_gfx_header:
    dw etank_gfx, $0000, $0000, $0000, $0000

missile_gfx_header:
    dw missile_gfx, $0000, $0000, $0000, $0000

super_gfx_header:
    dw super_gfx, $0000, $0000, $0000, $0000

pb_gfx_header:
    dw pb_gfx, $0000, $0000, $0000, $0000

print pc
warnpc !bank_84_free_space_end

org !bank_89_free_space_start
etank_gfx:
  db $3f, $3f, $50, $7f, $90, $fc, $3d, $d1, $1d, $91, $10, $90, $11, $91, $7d, $91, $30, $00, $70, $00, $f3, $03, $f3, $03, $f3, $03, $ff, $6f, $ff, $03, $f3, $03
  db $fc, $fc, $0a, $fe, $29, $3f, $fc, $eb, $18, $e9, $48, $49, $e8, $c9, $1e, $e9, $0c, $00, $0e, $00, $ef, $e0, $ef, $e0, $0f, $00, $ff, $d6, $ff, $c0, $0f, $00
  db $3c, $d0, $93, $ff, $5f, $7f, $3f, $3f, $0c, $0c, $08, $04, $66, $78, $66, $78, $f3, $03, $f3, $03, $70, $10, $3f, $00, $0c, $00, $0c, $00, $7f, $01, $7f, $01
  db $3c, $2b, $e9, $ff, $fa, $fe, $fc, $fc, $30, $30, $20, $10, $66, $1e, $66, $1e, $ef, $e0, $ef, $e0, $0e, $08, $fc, $00, $30, $00, $30, $00, $fe, $80, $fe, $80
  db $3f, $3f, $50, $7f, $90, $ff, $3d, $d3, $1d, $93, $10, $93, $11, $93, $7d, $93, $30, $00, $70, $00, $f0, $00, $f1, $01, $f1, $01, $fc, $6c, $fd, $01, $f1, $01
  db $fc, $fc, $0a, $fe, $29, $ff, $fc, $eb, $18, $e9, $48, $c9, $e8, $c9, $1e, $e9, $0c, $00, $0e, $00, $2f, $20, $ef, $e0, $0f, $00, $7f, $56, $ff, $c0, $0f, $00
  db $3c, $d3, $93, $ff, $5f, $7f, $3f, $3f, $0c, $0c, $08, $04, $64, $78, $64, $78, $f0, $00, $f3, $03, $70, $10, $3f, $00, $0c, $00, $0c, $00, $7f, $01, $7f, $01
  db $3c, $eb, $e9, $ff, $fa, $fe, $fc, $fc, $30, $30, $20, $10, $26, $1e, $26, $1e, $2f, $20, $ef, $e0, $0e, $08, $fc, $00, $30, $00, $30, $00, $fe, $80, $fe, $80

missile_gfx:
  db $04, $04, $13, $13, $2d, $2d, $13, $12, $56, $54, $27, $24, $25, $26, $26, $24, $07, $00, $1f, $00, $3d, $00, $32, $01, $75, $03, $64, $03, $64, $00, $67, $01
  db $e0, $20, $f8, $c8, $bc, $b4, $cc, $48, $ee, $2a, $e6, $24, $26, $e4, $e6, $a4, $e0, $00, $f8, $00, $bc, $00, $4c, $80, $2e, $c0, $26, $c0, $26, $00, $e6, $00
  db $26, $27, $24, $26, $24, $26, $26, $27, $22, $24, $3a, $34, $7c, $3f, $1c, $60, $67, $00, $67, $01, $67, $01, $6f, $08, $6f, $01, $7f, $01, $7f, $00, $7f, $00
  db $66, $e4, $a6, $64, $a6, $64, $66, $e4, $96, $e4, $be, $cc, $3c, $fe, $38, $06, $e6, $00, $e6, $00, $e6, $00, $f6, $00, $f6, $00, $fe, $00, $fe, $00, $fe, $00
  db $04, $04, $13, $13, $2d, $2d, $13, $12, $56, $54, $27, $24, $25, $26, $24, $24, $07, $03, $1f, $0c, $3d, $10, $32, $21, $75, $23, $64, $43, $64, $40, $67, $41
  db $20, $20, $c8, $c8, $b4, $b4, $c8, $48, $ea, $2a, $e4, $24, $24, $e4, $a4, $a4, $e0, $00, $f8, $00, $bc, $00, $4c, $80, $2e, $c0, $26, $c0, $26, $00, $e6, $00
  db $27, $26, $26, $24, $26, $24, $26, $27, $24, $20, $34, $30, $3f, $3c, $70, $00, $67, $40, $67, $41, $67, $41, $6f, $48, $6f, $49, $7f, $41, $7f, $00, $7f, $00
  db $e4, $64, $64, $24, $64, $24, $64, $e4, $e4, $84, $cc, $8c, $fe, $3c, $0e, $00, $e6, $00, $e6, $00, $e6, $00, $f6, $10, $f6, $00, $fe, $00, $fe, $00, $fe, $00

super_gfx:
  db $18, $18, $27, $27, $5c, $5c, $50, $50, $27, $27, $2a, $2c, $2f, $2f, $32, $34, $1f, $00, $3f, $00, $7c, $03, $71, $07, $67, $00, $6f, $00, $6f, $00, $7f, $00
  db $fc, $1c, $fe, $e6, $1e, $1a, $0e, $0a, $e6, $e4, $56, $34, $f6, $f4, $4e, $2c, $fc, $00, $fe, $00, $1e, $c0, $8e, $e0, $e6, $00, $f6, $80, $f6, $00, $fe, $80
  db $32, $34, $29, $2e, $27, $27, $24, $26, $27, $27, $a7, $a4, $ff, $bf, $9c, $e0, $7f, $08, $6f, $00, $67, $00, $67, $00, $67, $00, $e7, $00, $ff, $00, $ff, $00
  db $4e, $2c, $96, $74, $e6, $e4, $26, $64, $e6, $e4, $27, $65, $fd, $ff, $39, $07, $fe, $90, $f6, $00, $e6, $00, $e6, $80, $e6, $00, $e7, $00, $ff, $00, $ff, $00
  db $18, $18, $27, $27, $58, $58, $50, $50, $27, $27, $2c, $28, $2f, $2f, $34, $30, $1f, $07, $3f, $18, $78, $23, $71, $27, $67, $40, $6f, $40, $6f, $40, $7f, $48
  db $18, $18, $e4, $e4, $1a, $1a, $0a, $0a, $e4, $e4, $34, $14, $f4, $f4, $2c, $0c, $f8, $00, $fc, $00, $1e, $c0, $8e, $e0, $e6, $00, $f6, $80, $f6, $00, $fe, $90
  db $34, $30, $2e, $28, $27, $27, $26, $24, $27, $27, $26, $24, $ff, $ff, $e0, $80, $7f, $48, $6f, $40, $67, $40, $67, $40, $67, $00, $67, $00, $ff, $00, $ff, $03
  db $2c, $0c, $74, $14, $e4, $e4, $64, $24, $e4, $e4, $64, $24, $ff, $ff, $07, $01, $fe, $90, $f6, $00, $e6, $00, $e6, $80, $e6, $00, $e6, $80, $ff, $00, $ff, $c0

pb_gfx:
  db $00, $00, $03, $03, $0f, $0e, $1f, $1f, $3e, $32, $27, $33, $26, $32, $3f, $33, $00, $00, $03, $00, $0e, $00, $13, $00, $23, $01, $2b, $08, $2b, $09, $23, $00
  db $00, $00, $c0, $c0, $f0, $70, $f8, $f8, $7c, $4c, $ec, $c4, $6c, $44, $fc, $cc, $00, $00, $c0, $00, $70, $00, $c8, $00, $c4, $80, $d4, $10, $d4, $90, $c4, $00
  db $3f, $3e, $3f, $37, $3f, $3a, $1f, $1f, $0f, $0e, $1f, $0f, $6f, $73, $48, $70, $3a, $00, $27, $00, $3a, $00, $13, $00, $0e, $00, $1f, $0e, $7f, $01, $7f, $01
  db $fc, $7c, $fc, $ec, $fc, $5c, $f8, $f8, $f0, $70, $f8, $f0, $f6, $ce, $12, $0e, $5c, $00, $e4, $00, $5c, $00, $c8, $00, $70, $00, $f8, $70, $fe, $80, $fe, $80
  db $00, $00, $03, $03, $0e, $0f, $13, $1f, $32, $3f, $23, $3f, $22, $3f, $33, $3f, $00, $00, $02, $02, $02, $02, $02, $02, $00, $00, $00, $00, $00, $00, $20, $20
  db $00, $00, $c0, $c0, $70, $f0, $c8, $f8, $4c, $fc, $c4, $fc, $44, $fc, $cc, $fc, $00, $00, $40, $40, $40, $40, $40, $40, $00, $00, $00, $00, $00, $00, $00, $00
  db $3e, $3f, $27, $3f, $32, $3f, $13, $1f, $0e, $0f, $0f, $0f, $63, $73, $40, $70, $10, $10, $00, $00, $00, $00, $02, $02, $02, $02, $1e, $0e, $7f, $01, $7f, $01
  db $7c, $fc, $e4, $fc, $4c, $fc, $c8, $f8, $70, $f0, $f0, $f0, $c6, $ce, $02, $0e, $08, $08, $00, $00, $00, $00, $40, $40, $40, $40, $78, $70, $fe, $80, $fe, $80

warnpc !bank_89_free_space_end