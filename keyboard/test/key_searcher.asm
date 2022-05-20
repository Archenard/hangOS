key_search:
	push bx
	push cx
	push dx
	push di
	push es

	xor bx, bx
	mov es, bx

	mov bl, [es:keyboard_type]
	shl bl, 1				;times 2, each entry is 2 Bytes
	
	add bl, 2
	mov dx, [es:keyboards+bx]
	add dx, keyboards
	sub bl, 2
	
	mov bx, [es:keyboards+bx]
	add bx, keyboards			;bx=address the begin of the codes

	mov di, bx

key_not_found:
	
	cmp di, dx
	je keyboard_end

	cmp ah, [es:di]
	je key_found
	inc di
	jmp key_not_found

key_found:
	sub di, bx
	mov cx, di
	mov al, cl
	add al, 65

keyboard_end:
	pop es
	pop di
	pop dx
	pop cx
	pop bx
	ret
