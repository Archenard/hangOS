main_start:
	xor ax, ax
	mov es, ax
	
	mov byte [es:fails], 0
	call reset_found
	
	call display_menu
	
	mov di, 3768
	mov si, credits
	call print_str
	mov di, 3928
	mov si, my_github
	call print_str

	call menu_calc

	call select_word

	mov ah, 0x00			;clear screen
	mov al, 0x03
	int 0x10

	mov ah, 0x02			;move cursor
	xor bx, bx
	mov dh, 16
	mov dl, 16
	int 0x10

	mov di, 3768
	mov si, credits
	call print_str
	mov di, 3928
	mov si, my_github
	call print_str

main_game_loop:
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

main_get_key:
	xor ax, ax
	int 0x16
	call key_search

	cmp al, "A"
	jl main_get_key
	cmp al, "Z"
	jg main_get_key
	
	call search_letter

	call win_verifier
	mov dx, di
	cmp dx, 1
	je main_game_end

	jmp main_game_loop


main_loose:
	mov dx, 2

main_game_end:
	mov ah, 0x00			;clear screen
	mov al, 0x03
	int 0x10
	mov ah, 0x01			;hide cursor
	mov cx, 0x2000
	int 0x10
	
	mov di, 0
	call draw_gallows

	mov di, 1280

	cmp dx, 1
	je main_game_end_win

	mov si, loose_message
	call print_str
	jmp main_game_end_common

main_game_end_win:
	mov si, win_message
	call print_str

main_game_end_common:	
	mov di, 1600
	mov si, the_word_was
	call print_str

	mov si, [es:word_to_find]
	call print_str

	mov di, 2080
	mov si, press_enter_to_play_again
	call print_str

	mov di, 3768
	mov si, credits
	call print_str
	mov di, 3928
	mov si, my_github
	call print_str

main_wait_replay:
	xor ax, ax
	int 0x16
	cmp ah, 0x1c
	jne main_wait_replay

	jmp main_start

guess_a_letter: db "Guess a letter:", 0
loose_message: db "Oh no, you lost :(", 0
win_message: db "Bravo! You won :)", 0
the_word_was: db "The word was: ", 0
press_enter_to_play_again: db "Press enter to play again", 0
credits: db "hangOS, by Archenard", 0
my_github: db "https://github.com/Archenard/hangOS", 0
