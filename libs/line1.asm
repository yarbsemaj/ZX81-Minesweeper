
;= Second BASIC line, calls ASM ==================================

line1:
   .byte   0,1                         ; line number
   .word   dfile-$-2                   ; line length

   .byte   $f9,$d4,$c5                 ; RAND USR VAL
   .byte   $b,$1d,$22,$21,$1d,$20,$b   ; "16514"
   .byte   $76                         ; N/L

;- Collapsed display file --------------------------------------------

dfile:
   .byte   $76
   .byte   $76,$76,$76,$76,$76,$76,$76,$76
   .byte   $76,$76,$76,$76,$76,$76,$76,$76
   .byte   $76,$76,$76,$76,$76,$76,$76,$76

;- BASIC-Variables ----------------------------------------

vars:
   .byte   $80

;- End of program area ----------------------------

last:
   .end
