select_word:			;change [word_to_find] with pointer
	push ax
	push bx
	push cx
	push dx
	push es
	push di
	push si
	
	xor ax, ax
	mov es, ax


	mov bx, words_langs

	xor ax, ax
	mov al, [es:lang]
	shl ax, 1

	add bx, ax			;bx=pointer to the offset of the lang selected

	mov ax, [es:bx+2]		;next lang offset

	mov bx, [es:bx]			;current lang offset

	mov cx, ax
	sub cx, bx
	shr cx, 1			;number of words in this lang( /2 bc 2B per entry)

	add bx, words_langs		;pointer to array of offset of the words


	call rng
	xor dx, dx
	mov ax, di
	div cx
	mov ax, dx			;ax = ax mod cx

	shl ax, 1

	add bx, ax

	mov si, [es:bx]
	add si, words_langs
	mov [es:word_to_find], si


	xor cx, cx
select_word_loop:
	mov al, [es:si]
	or al, al
	jz select_word_loop_end
	inc cx
	inc si
	jmp select_word_loop
select_word_loop_end:
	mov si, word_found
	add si, cx
	mov byte [es:si], 0


	pop si
	pop di
	pop es
	pop dx
	pop cx
	pop bx
	pop ax
	ret
