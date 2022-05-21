	call display_menu
	call menu_calc

	call select_word

	mov ah, 0x00			;clear screen
	mov al, 0x03
	int 0x10

	mov di, 0
	mov si, ok_message
	call print_str

	mov di, 320
	mov si, word_found
	call print_str

	mov di, 960
	mov si, pendu_0
	call print_str

	mov di, 2560
	mov si, guess_a_letter
	call print_str

	mov ah, 0x02			;move cursor
	xor bx, bx
	mov dh, 16
	mov dl, 16
	int 0x10
tmp:
	xor ax, ax
	int 0x16
	call key_search
	
	call search_letter
	
	mov si, [es:fails]
	and si, 0x00ff
	mov di, 3200
	call print_hex
	
	mov di, 320
	mov si, word_found
	call print_str
	jmp tmp

hang:
	jmp hang

ok_message: db "Bienvvvvenue", 0
guess_a_letter: db "Guess a letter:", 0
