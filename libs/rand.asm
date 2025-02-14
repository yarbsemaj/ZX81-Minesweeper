;Fills A with a random number between 1 and 255
RAND:
		push		hl
		push		de
		ld			hl,(randData)
		ld			a,r
		ld			d,a
		ld			e,(hl)
		add			hl,de
		add			a,l
		xor			h
		ld			(randData),hl
		pop			de
		pop			hl
		ret

randData:
		.block	2					;One byte seed for random number generator

INIT_RAND:
		LD			A,($4034) 		;Get the frame counter
		LD			(randData),A	;This is out seed
		RET


