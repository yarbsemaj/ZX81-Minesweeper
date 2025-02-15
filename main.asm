;;
;; TYPE.ASM
;;   Print a key as it is touched on the keyboard
;;   The program scans the keyboard and if a key is touched
;;   it prints the character to the screen.  If the / character
;;   is touched, the program exists to BASIC.
;;

; assemble with:  TASM -80 -b -s type.asm type.p

#define AUTORUN line1
#include "libs/sysvars.asm"
#include "libs/line0.asm"
#include "libs/charcode.asm"
#include "libs/rom.asm"

#define BOARD 			$6000   ;The board lives at 6000 hex
#define BOARD_W			16
#define BOARD_H			16
#define B_OFFSET_T		3
#define B_OFFSET_L		3


#define MINE_OFFSET		7
#define VISABLE_OFFSET	5
#define FLAG_OFFSET		6


#define SHOW_MINES		0
#define FIRST_MOVE		1

START:
DRAW_TITLE_SCREEN:
		LD		HL,(D_FILE)
		PUSH	HL
		LD		HL, TITLE_SCREEN
		LD		(D_FILE), HL
WAIT_TS	CALL 	KSCAN		; get a key from the keyboard
		LD		B,H
		LD		C,L
		LD		D,C
		INC		D
		LD		A,01h					; If no key entered
		JR		Z, WAIT_TS				; then loop
		CALL	FINDCHAR				; Translate keyboard result to character
		LD		A,(HL)					; Put results into reg a
		CP		_E						; Move Cursor
		JR 		Z, GAME_START_E			;
		CP		_N						;
		JR 		Z, GAME_START_N			;
		CP		_H						;
		JR 		Z, GAME_START_H			;
		LD		BC,$1200				; Set pause to $1200
DELAY_TS
		DEC		BC						; Pause routine  - Probably need a debounce routine
		LD		A,B
		OR		C
		JR		NZ,DELAY_TS
		JP		WAIT_TS


GAME_START_E
		LD		A, 20
		LD		(MINES),A
		JR		GAME_START

GAME_START_N
		LD		A, 30
		LD		(MINES),A
		JR		GAME_START

GAME_START_H
		LD		A, 40
		LD		(MINES),A
		JR		GAME_START


GAME_START:
		POP		HL
		LD		(D_FILE), HL
		;RESET THE FLAGS
		LD		HL,GAME_FLAGS
		LD		(HL),0
		CALL	INIT_RAND

		CALL	INIT_BOARD
		CALL	CLS
		CALL	DRAW_BOARDER
		CALL	DRAW_BOARD
		CALL	CALC_SCORE


WAIT	CALL 	KSCAN		; get a key from the keyboard
		LD		B,H
		LD		C,L
		LD		D,C
		INC		D
		LD		A,01h					; If no key entered
		JR		Z, WAIT					; then loop
		CALL	FINDCHAR				; Translate keyboard result to character
		LD		A,(HL)					; Put results into reg a
		CP		_W						; Move Cursor
		JR 		Z, MOVE_CURSOR_UP		;
		CP		_S						;
		JR 		Z, MOVE_CURSOR_DOWN		;
		CP		_A						;
		JR 		Z, MOVE_CURSOR_LEFT		;
		CP		_D						;
		JR 		Z, MOVE_CURSOR_RIGHT	;
		CP		_F						;
		JR		Z, FLAG					;
		CP		_R						;
		JR		Z, REMOVE				;
INPUT_END
		CALL	CALC_SCORE
		LD		BC,$1200				; Set pause to $1200
DELAY	DEC		BC						; Pause routine  - Probably need a debounce routine
		LD		A,B
		OR		C
		JR		NZ,DELAY
		JP		WAIT



MOVE_CURSOR_UP
		LD		A,(CURSOR)				;Get current cursor pos
		PUSH	AF						;Save it for later
		SUB		$10						;Move Cursor
		LD		(CURSOR),A				;Save new cursor pos back
		CALL 	DRAW_CELL				;Redraw new cursor pos cell
		POP		AF						;Get old pos
		CALL 	DRAW_CELL				;Redraw old pos
		JR		INPUT_END				;Return

MOVE_CURSOR_DOWN
		LD		A,(CURSOR)
		PUSH	AF
		ADD		A,$10
		LD		(CURSOR),A
		CALL 	DRAW_CELL
		POP		AF
		CALL 	DRAW_CELL
		JR		INPUT_END
MOVE_CURSOR_LEFT
		LD		A,(CURSOR)
		PUSH	AF
		DEC		A
		LD		(CURSOR),A
		CALL 	DRAW_CELL
		POP		AF
		CALL 	DRAW_CELL
		JR		INPUT_END	
MOVE_CURSOR_RIGHT
		LD		A,(CURSOR)
		PUSH	AF
		INC		A
		LD		(CURSOR),A
		CALL 	DRAW_CELL
		POP		AF
		CALL 	DRAW_CELL
		JR		INPUT_END

FLAG
		LD		HL, BOARD							;Get Start of the board
		LD		A,(CURSOR)							;Get the cursor pos
		LD		L,A									;Offset into the board
		LD		A, (HL)								;Get the board value
		BIT		VISABLE_OFFSET,A					;Is the tile visable
		JR		NZ, INPUT_END
		XOR		$40									;Flip 6th bit (from 0 base)
		LD		(HL),A
		LD		A,(CURSOR)							;Get the cursor pos
		CALL 	DRAW_CELL
		JR		INPUT_END	



REMOVE:
		LD		HL, BOARD							;Get Start of the board
		LD		A,(CURSOR)							;Get the cursor pos
		LD		L,A									;Offset into the board
		LD		A, (HL)								;Get the board value
		BIT		VISABLE_OFFSET,A					;Is the tile visable
		JR		NZ, INPUT_END
		BIT		MINE_OFFSET,A						;Is this a game over
		JP		NZ, GAME_OVER
CONTINUE_REMOVE
		PUSH	HL
		LD		HL, GAME_FLAGS						;Set Move as fist move
		SET		FIRST_MOVE,(HL)
		POP		HL
		LD		BC, $00
		PUSH	BC									;Set the stack terminator
		PUSH	HL									;Add the Position to visit to the stack

REMOVE_RECURSIVE
		POP		HL									;Get the last move from the stack
		LD		A,H									;We only need to check the top byte for the Stack terminator
		OR		A									;CP with 0
		JP		Z,END_REMOVE						;We have hit the end of the stack, time to finish
		LD		A,(HL)								;Get the value at that stack position
		BIT		VISABLE_OFFSET,A					;Is the tile visable?
		JR		NZ, REMOVE_RECURSIVE				;It is? The we have already visisted it, and thus can move on
		;With all that out of the way, we can now compute the tiles new value
		;For the top we can mask off the upper 4 bits and check that its Zero
		LD		C,0									;Starts with zero bombs
		LD		B,0									;Number of valid negbours
		PUSH	HL									;Copy HL into DE
		POP		DE									;
COUNT_UP
		;First check were not at the top
		LD		A,E
		CP		16									;15 is the end of the top row
		JR		C,COUNT_LEFT						;If A >= 16, then C flag is reset.
		SUB		BOARD_W								;Get the lower nibble of the byte
		LD		L,A									;Reconstruct HL
		BIT		MINE_OFFSET,(HL)					;TT
		JP		NZ, CUH
		INC		B									;We have visited a negbour
		PUSH	HL									;Push it to the stack
TOP_LEFT
		LD		A,E									;Are we at the very left
		AND		$0F									;Mask off the bottom Bits		
		JP		Z,TOP_RIGHT							;If the bottom bits are all zero, we know that we must be at the very left
		LD		A,E									;Are we at the very left
		SUB		BOARD_W + 1							;Get the lower nibble of the byte
		LD		L,A									;Reconstruct HL
		BIT		MINE_OFFSET, (HL)					;TL
		JP		NZ, TLH
		INC		B									;We have visited a negbour
		PUSH	HL									;Push it to the stack
TOP_RIGHT
		LD		A,E									;Are we at the very right
		AND		$0F									;Mask off the bottom nibble
		CP		$0F									;Is the bottom nibble all set 
		JP		Z,COUNT_LEFT						;If its all set, then were at the very right
		LD		A,E
		SUB		BOARD_W - 1							;Get the lower nibble of the byte
		LD		L,A									;Reconstruct HL
		BIT		MINE_OFFSET,(HL)					;TR
		JP		NZ, TRH
		INC		B									;We have visited a negbour
		PUSH	HL									;Push it to the stack
COUNT_LEFT
		LD		A,E									;Are we at the very left
		AND		$0F									;Mask off the bottom Bits		
		JP		Z,COUNT_RIGHT						;If the bottom bits are all zero, we know that we must be at the very left
		LD		A,E
		DEC		A									;Get the lower nibble of the byte
		LD		L,A									;Reconstruct HL
		BIT		MINE_OFFSET,(HL)					;LL
		JP		NZ, CLH
		INC		B									;We have visited a negbour
		PUSH	HL									;Push it to the stack
COUNT_RIGHT
		LD		A,E									;Are we at the very right
		AND		$0F									;Mask off the bottom nibble
		CP		$0F									;Is the bottom nibble all set 
		JP		Z,COUNT_DOWN						;If its all set, then were at the very right
		LD		A,E
		INC		A									;Get the lower nibble of the byte
		LD		L,A								;Reconstruct HL	
		BIT		MINE_OFFSET,(HL)					;RR
		JP		NZ, CRH
		INC		B									;We have visited a negbour
		PUSH	HL									;Push it to the stack
COUNT_DOWN
		LD		A,E									;Are we at the very bottom
		CP		$F0									;The last cell on the previous row is $F0
		JP		NC,RECALC_CELL						;If A >= $F0, then C flag is reset.
		ADD		A,BOARD_W							;Get the lower nibble of the byte
		LD		L,A									;Reconstruct HL
		BIT		MINE_OFFSET,(HL)					;BB
		JP		NZ, CDH
		INC		B									;We have visited a negbour
		PUSH	HL									;Push it to the stack
BOTTOM_LEFT
		LD		A,E									;Are we at the very left
		AND		$0F									;Mask off the bottom Bits		
		JP		Z,BOTTOM_RIGHT						;If the bottom bits are all zero, we know that we must be at the very left	
		LD		A,E
		ADD		A,BOARD_W-1							;Get the lower nibble of the byte
		LD		L,A									;Reconstruct HL			
		BIT		MINE_OFFSET, (HL)	;BL
		JP		NZ, BLH
		INC		B									;We have visited a negbour
		PUSH	HL									;Push it to the stack
BOTTOM_RIGHT
		LD		A,E									;Are we at the very right
		AND		$0F									;Mask off the bottom nibble
		CP		$0F									;Is the bottom nibble all set 
		JP		Z,RECALC_CELL						;If its all set, then were at the very right	
		LD		A,E									;Get Back our origional A
		ADD		A,BOARD_W+ 1						;Get the lower nibble of the byte
		LD		L,A									;Reconstruct HL
		BIT		MINE_OFFSET,(HL)					;BR
		JP		NZ, BRH
		INC		B									;We have visited a negbour
		PUSH	HL									;Push it to the stack
		JP		RECALC_CELL

CUH
		INC		C
		JP		TOP_LEFT
TLH
		INC		C
		JP		TOP_RIGHT
TRH
		INC		C
		JP		COUNT_LEFT
CLH
		INC		C
		JP		COUNT_RIGHT
CRH		
		INC		C
		JP		COUNT_DOWN
CDH
		INC		C
		JP		BOTTOM_LEFT
BLH
		INC		C
		JP		BOTTOM_RIGHT
BRH
		INC		C		
													;Fall to recalc cell
RECALC_CELL
		PUSH	DE
		POP		HL
		SET		VISABLE_OFFSET,(HL)					;MArk the cell as visable
		RES		FLAG_OFFSET,(HL)					;Unset The flag
		LD		A,C									;Is C Zero
		OR		A
		JP		Z,REMOVE_RECURSIVE					;Lets visit the negbours
													;else add the negbours to the lower nibble
		OR		(HL)								;Combine C with HL
		LD		(HL),A								;Put the result back
		LD		A,B									;IS B 0; (the number of negbours weve pushed)
		OR		A
		JP		Z,REMOVE_RECURSIVE					;If its 0, we can just the try next cell
REMOVE_NEIGHBORS_FOR_STACK_LOOP
		POP		HL
		DJNZ	REMOVE_NEIGHBORS_FOR_STACK_LOOP
		JP		REMOVE_RECURSIVE


END_REMOVE
		CALL	DRAW_BOARD
		JP		INPUT_END


GAME_OVER
		PUSH	HL								;If its our first move, move the mine
		LD		HL,GAME_FLAGS
		BIT		FIRST_MOVE,(HL)					;
		POP		HL
		JP		NZ,SHOW_GAME_OVER_MESSAGE		;Were saved
		PUSH	HL								;Save HL for later
REMOVE_LOOP
		CALL	RAND				;Get a random number
		LD		L,A					;Set the lower byte of the address to A, the upper byte will be $50, and the lower byte the offset
		LD		A,(HL)				;Get the current value in that square
		OR		A					;Is the Square blank
		JR		NZ,ADD_MINES_LOOP	;If not try again
		LD		(HL),$80			;Set the Mine bit (MSB)

		POP		HL					;GEt back the origional mine position
		RES		MINE_OFFSET,(HL)	;Remove the mine
		JP		CONTINUE_REMOVE




SHOW_GAME_OVER_MESSAGE
		LD		HL, GAME_FLAGS
		SET		SHOW_MINES,(HL)
		CALL	DRAW_BOARD
		LD		BC,$0916
		CALL 	PRINTAT
		LD		HL,GAME_OVER_MESSAGE
		CALL	PLINE

PLAY_AGAIN
		LD		BC,$0B16
		CALL 	PRINTAT
		LD		HL,PLAY_AGAIN_MESSAGE
		CALL	PLINE

		LD		BC,$0C16
		CALL 	PRINTAT
		LD		HL,QUIT_MESSAGE
		CALL	PLINE


PLAY_AGAIN_LOOP	
		CALL 	KSCAN		; get a key from the keyboard
		LD		B,H
		LD		C,L
		LD		D,C
		INC		D
		LD		A,01h					; If no key entered
		JR		Z, PLAY_AGAIN_LOOP		; then loop
		CALL	FINDCHAR				; Translate keyboard result to character
		LD		A,(HL)					; Put results into reg a
		CP		_P						;
		JP 		Z, START				;
		CP		_Q						;
		JR 		Z, QUIT					;
		LD		BC,$1200				; Set pause to $1200
PA_DELAY
		DEC		BC						; Pause routine  - Probably need a debounce routine
		LD		A,B
		OR		C
		JR		NZ,PA_DELAY
		JP		PLAY_AGAIN_LOOP

QUIT
		RET

INIT_BOARD
		LD		A, 0		; were going to fill the board with 0
		LD		(CURSOR), A	; Start the cursor in the top right
		LD		B, 0		; the board size 0 = 256
		LD		HL,BOARD	; the board address
INIT_BOARD_LOOP
		LD		(HL), A		; fill the value
		INC		HL
		DJNZ 	INIT_BOARD_LOOP
									; We now have a blank board, lets add some mines
		LD		A,(MINES)
		LD		B, A				;How many mines
		LD		HL,BOARD			;Get the board
ADD_MINES_LOOP
		CALL	RAND				;Get a random number
		LD		L,A					;Set the lower byte of the address to A, the upper byte will be $50, and the lower byte the offset
		LD		A,(HL)				;Get the current value in that square
		OR		A					;Is the Square blank
		JR		NZ,ADD_MINES_LOOP	;If not try again
		LD		(HL),$80			;Set the Mine bit (MSB)
		DJNZ	ADD_MINES_LOOP
		RET


CALC_SCORE
		LD 		B,0										;Loop 256 times
		LD		HL,BOARD								;BOARD
		LD		DE,$00									;We start with no blank squares (E), and no flags (D)
CALC_SCORE_LOOP
		LD		L,B										;Update lower nibble
		LD		A,(HL)									;Get Board Value

		BIT		FLAG_OFFSET,A
		JR		NZ, COUNT_FLAG
COUNT_FLAG_RET
		BIT		VISABLE_OFFSET,A
		JR		Z, COUNT_HIDDEN
COUNT_HIDDEN_RET
		DJNZ	CALC_SCORE_LOOP							;Loop
		LD		A,(MINES)
		CP		E
		JP		Z,WIN									;You Win
		PUSH	DE
		LD		BC,$0916
		CALL 	PRINTAT
		LD		HL,MINES_MESSAGE
		CALL	PLINE
		LD		A,(MINES)
		POP		DE
		SUB		D
		JR		C, TOO_MANY_FLAGS
		CALL	bin2bcd										;Work out the Number of mines left
		PUSH	AF
		AND		$F0											;Mask off the top nibble
		RRCA												;Move the top bits into the bottom
		RRCA
		RRCA
		RRCA
		ADD		A,_0
		CALL	PRINT
		POP		AF
		AND		$0F
		ADD		A,_0
		CALL	PRINT
		RET

TOO_MANY_FLAGS
		LD		A,$17
		CALL	PRINT
		LD		A,$17
		CALL	PRINT
		RET

WIN
		POP		HL										;Remove the RET Address
		LD		HL, GAME_FLAGS
		SET		SHOW_MINES,(HL)
		CALL	DRAW_BOARD
		LD		BC,$0916
		CALL 	PRINTAT
		LD		HL,WIN_MESSAGE
		CALL	PLINE
		JP		PLAY_AGAIN

COUNT_FLAG
		INC		D
		JR		COUNT_FLAG_RET

COUNT_HIDDEN
		INC		E
		JR		COUNT_HIDDEN_RET

;Board Makeup
DRAW_BOARD
		LD 		B,0										;Loop 256 times
DRAW_BOARD_LOOP
		PUSH	BC										;Preserve Loop counter
		LD		A,B										;Draw Using A
		CALL	DRAW_CELL								;Daw current cell
		POP		BC										;Restore loop counter
		DJNZ	DRAW_BOARD_LOOP							;Loop
		RET


;(A) board Address offset
DRAW_CELL
		;First we need to get the display file address of A
		PUSH	AF										;Preserve A
		LD		HL,(D_FILE)								;Get start of board
		LD		DE,(B_OFFSET_T + 1) * 33 + B_OFFSET_L+1	;Load and add the board offset, we dont need to this do this for the top
		ADD		HL,DE									;"
		;At this point were at the top of the board; now using top nibble of A, we move down that many rows
		AND		$F0										;Mask off the top nibble
		RRA												;Move the top bits into the bottom
		RRA
		RRA
		RRA
		OR		A
		JR		Z,LEFT_OFFSET						;IF were offaset by 0, then no need to loop


		LD		B,A									;We need to move this so we can loop		
		LD		DE, 33								;Add one line
TOP_OFFSET_LOOP
		ADD		HL,DE								
		DJNZ	TOP_OFFSET_LOOP
		;Now we have the top offset, we need to move along to the coloum
LEFT_OFFSET
		POP		AF									;A is back
		PUSH	AF
		AND		$0F									;Mask off lower nibble
		LD		B,0									;B should aready be 0, but never heard to make sure
		LD		C,A									;BC is now our line offset
		ADD		HL,BC								;Add Our line offset to HL, HL is now the adress in the dfile of our chat

;Now get the value of our char from the board
		POP		AF									;A is back
		PUSH	AF									;Save A For the cursor check
		LD		BC,	BOARD							;
		ADD		A,C									;B will always be $50, so we just need to add to C to get our offset
		LD		C,A
		LD		A, (BC)								;A now contains the value in the board
		BIT		MINE_OFFSET,A
		JR		NZ, DRAW_BOMB
SKIP_BOMB_DRAW:
		BIT		FLAG_OFFSET,A
		JR		NZ, DRAW_FLAG
		BIT		VISABLE_OFFSET,A
		JR		Z, DRAW_HIDDEN
		AND		$0F									;Baottom Byte
		JP		Z,DRAW_REVEALED						;If its blank draw a space
		ADD		A,$1C								;Otherwise draw a number
		LD		(HL), A
DRAW_CURSOR
		LD		A,(CURSOR)
		POP		BC									;The OG argument A, is now in B
		CP		B
		RET		NZ
		LD		A,$80								;Invert the last bit															
		XOR		(HL)
		LD		(HL),A
		RET

DRAW_BOMB
		PUSH	HL
		LD		HL, GAME_FLAGS
		BIT		SHOW_MINES,(HL)
		POP		HL
		JR		Z,	SKIP_BOMB_DRAW
		LD		(HL),$97
		JR		DRAW_CURSOR
DRAW_FLAG
		LD		(HL),$92
		JR		DRAW_CURSOR
DRAW_HIDDEN
		LD		(HL),$B1
		JR		DRAW_CURSOR

DRAW_REVEALED
		LD		(HL), $00
		JR		DRAW_CURSOR
		

DRAW_BOARDER
		LD		HL,(D_FILE)							; Get start of display
		LD		DE,  B_OFFSET_T * 33 + B_OFFSET_L	;Load and add the board offset
		ADD		HL,DE								;"
		LD		B, 18								;Draw 18 chars
DRAW_TOP
		LD		(HL),$88							;Top of the board filled with grey
		INC		HL									;Next char		
		DJNZ	DRAW_TOP							;Loop until were done
		DEC		HL
		LD		B,16								;16 rows
DRAW_ROWS	
		LD		DE, 33 - 17							;Offset for the next line (line length minus how far we have already traveled)
		ADD		HL,DE								
		LD		(HL),$88							;Right edge
		LD		DE,16+1								;Middle
		ADD		HL,DE								
		LD		(HL),$88							;Right edge
		DJNZ	DRAW_ROWS

		LD		DE, 33 - 17							;Offset for the next line (line length minus how far we have already traveled)
		ADD		HL,DE								

		LD		B, 18								;Draw 18 chars
DRAW_BOTTOM
		LD		(HL),$88							;Top of the board filled with grey
		INC		HL									;Next char		
		DJNZ	DRAW_BOTTOM							;Loop until were done
		RET

PLINE	LD		A,(HL)		;load A with a character at HL
		CP		$FF			;is this $FF
		RET		Z			;if so, then jump to end
		CALL	PRINT		;print character
		INC		HL			;increment HL to get to next character
		JP		PLINE		;jump to beginning of loop

CURSOR
		.byte	0					;Cursor address
GAME_FLAGS
		.byte	0	
MINES
		.byte	0			

GAME_OVER_MESSAGE:
		.byte	_G,_A,_M,_E,$00,_O,_V,_E,_R,$76,$ff
WIN_MESSAGE:
		.byte	_Y,_O,_U,$00,_W,_I,_N,$76,$ff
PLAY_AGAIN_MESSAGE:
		.byte	$B5,_L,_A,_Y,$00,_A,_G,_A,_I,_N,$ff
QUIT_MESSAGE:
		.byte	$B6,_U,_I,_T,$ff
MINES_MESSAGE
		.byte	_M,_I,_N,_E,_S,,$0E,$00,$ff

; the ordering of this file's includes is critical - don't change it.
;
#include "libs/rand.asm"
#include "libs/bcd.asm"
TITLE_SCREEN
#include "title.txt"


#include "libs/line1.asm"



