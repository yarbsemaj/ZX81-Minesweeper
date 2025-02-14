
; SYSVARS which aren't saved

ERR_NR		.equ	$4000
FLAGS		.equ	$4001
ERR_SP		.equ	$4002
RAMTOP		.equ	$4004
MODE		.equ	$4006
PPC		.equ	$4007

		.org	$4009

; SYSVARS which are. This is the start of the .P

VERSN:		.byte	0
E_PPC:		.word	0
D_FILE:		.word	dfile
DF_CC:		.word	dfile+1
VARS:		.word	vars
DEST:		.word	0
E_LINE:		.word	vars+1
CH_ADD:		.word	last-1
X_PTR:		.word	0
STKBOT:		.word	last
STKEND:		.word	last
BERG:		.byte	0
MEM:		.word	MEMBOT
		.byte	0
DF_SZ:		.byte	2
S_TOP:		.word	1
LAST_K:		.byte	$FF,$FF,$FF
MARGIN:		.byte	55
NXTLIN:		.word	AUTORUN				; #define this in your main asm file; use 'line0', etc. 'dfile' if no autorun.
OLDPPC:		.word	0
FLAGX:		.byte	0
STRLEN:		.word	0
T_ADDR:		.word	$0C8D
SEED:		.word	0
FRAMES:		.word	$FFFF
COORDS:		.byte	0,0
PR_CC:		.byte	$BC
S_POSN:		.byte	33,24
CDFLAG:		.byte	01000000B

PRTBUF:		.block	33

MEMBOT:		.block	30			      ; calculator's scratch
			   .block	2

; some useful ROM routines

CLS			.equ	$0a2a
CLASS6		.equ	$0d92
DEBOUNCE	.equ	$0f4b
DECODEKEY	.equ	$07bd
FAST		.equ	$0f23
FINDINT		.equ	$0ea7
MAKEROOM	.equ	$099e
NEXTLINE	.equ	$0676
PRINT		.equ	$0010
PRINTAT		.equ	$08f5
RESET	  	.equ	$0000
SETFAST		.equ	$02E7
SETMIN		.equ	$14BC
SLOW		.equ	$0f2b
SLOWFAST	.equ	$0207
STACK2BC	.equ	$0bf5
STACK2A		.equ	$0c02


