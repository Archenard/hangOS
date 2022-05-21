main_start:
	xor ax, ax
	mov es, ax
	
	mov byte [es:fails], 0
	
	call display_menu
	call menu_calc

	call select_word

	mov ah, 0x00			;clear screen
	mov al, 0x03
	int 0x10

	mov di, 0
	mov si, ok_message
	call print_str

	mov ah, 0x02			;move cursor
	xor bx, bx
	mov dh, 16
	mov dl, 16
	int 0x10
tmp:
	mov di, 320
	mov si, word_found
	call print_str

	mov di, 960
	call draw_gallows
	
	cmp byte [es:fails], 6
	je main_loose

	mov di, 2560
	mov si, guess_a_letter
	call print_str

	xor ax, ax
	int 0x16
	call key_search
	
	call search_letter

	call win_verifier
	cmp di, 1
	je main_win

	jmp tmp


main_win:
	mov ah, 0x00			;clear screen
	mov al, 0x03
	int 0x10
	jmp hang

main_loose:
	mov ah, 0x00			;clear screen
	mov al, 0x03
	int 0x10
	
	mov di, 0
	call draw_gallows
	
	mov di, 1280
	mov si, loose_message
	call print_str
	
	mov di, 1600
	mov si, the_word_was
	call print_str
	
	mov si, [es:word_to_find]
	call print_str
hang:
	jmp hang

ok_message: db "Bienvvvvenue", 0
guess_a_letter: db "Guess a letter:", 0
loose_message: db "Oh no, you lost :(", 0
the_word_was: db "The word was: ", 0
