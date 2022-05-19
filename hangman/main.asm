	mov ah, 0x00
	mov al, 0x03
	int 0x10

	mov di, 0
	mov si, ok_message
	call print_str
	mov di, 320
	mov si, pendu_7
	call print_str

	call rng
	mov ax, di
	mov di, 160
	mov cx, __numberofwords__
	div cx
	mov ax, dx
	mov cx, 2
	mul cx
	mov bx, words_offsets
	add bx, ax
	mov word si, [es:bx]
	add si, words_offsets
	mov [word_to_find], si
	call print_str

hang:
	jmp hang

ok_message: db "Bienvenue", 0
