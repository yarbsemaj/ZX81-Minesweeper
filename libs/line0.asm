
;= First BASIC line, asm code ==================================

line0:
   .byte $00,$01        ; line number
   .word line1-$-2      ; line length

   .byte $ea            ; REM

   .byte $7e            ; m/c for ld a,(hl),  BASIC token for 'next 5 bytes are fp number'

   jp    start          ; this instruction and all following will be hidden. All you see is the REM...

   .byte 0,0            ; ... what a neat trick - thanks Math123!

   .byte $76            ; end of line

start:
