draw_gallows:			;draw at di
	push bx
	push si

	xor bx, bx


	mov bl, [es:fails]
	shl bx, 1

	mov si, [es:designs+bx]
	add si, designs

	call print_str

	pop si
	pop bx
	ret
