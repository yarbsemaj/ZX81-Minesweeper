bin2bcd:
	push    bc
	ld	b,10
	ld	c,-1
div10:	inc	c
	sub	b
	jr	nc,div10
	add	a,b
	ld	b,a
	ld	a,c
	add	a,a
	add	a,a
	add	a,a
	add	a,a
	or	b
	pop	bc
	ret