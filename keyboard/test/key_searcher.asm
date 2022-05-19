key_search:
push bx
push cx
push di
push es

xor bx, bx
mov es, bx

mov bl, [es:keyboard_type]
shl bl, 1				;times 2, each entry is 2Bytes
mov bx, [es:keyboards+bx]
add bx, keyboards			;bx=address the begin of the codes

mov di, bx

key_not_found:
	cmp [es:di], ah
	je key_found
	inc di
	jmp key_not_found

key_found:
	sub di, bx
	mov cx, di
	mov al, cl
	add al, 65
	
	pop es
	pop di
	pop cx
	pop bx
	ret
