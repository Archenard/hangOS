reset_found:
	push bx
	push cx
	push es

	xor bx, bx
	xor cx, cx
	mov es, bx

	mov cl, [es:max_word_length]

reset_found_loop:
	or cx, cx
	jz reset_found_end
	mov byte [es:word_found+bx], "_"
	inc bx
	dec cx
	jmp reset_found_loop
reset_found_end:
	pop es
	pop cx
	pop bx
	ret
