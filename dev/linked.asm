[ORG 0x7C00]

xor ax, ax
mov ds, ax
mov es, ax
mov ss, ax
mov sp, 0x7c00

mov ah, 2		;read disk
mov al, 5		;number of sectors to read
mov ch, 0		;C cylinder
mov cl, 2		;S sector
mov dh, 0		;H head
;mov dl, 0x80		;drive, already set on boot drive by bios
mov bx, 0x7e00		;[es:bx] adress to load
int 0x13

jmp 0x7e00

times 510-($-$$) db 0
db 0x55, 0xAA


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


print_hex:		;print the content of si, not a pointed value
	push ax
	push cx
	push ds
	xor cx, cx
	mov ax, 0xb800
	mov ds, ax
print_hex_loop:
	cmp cx, 4
	je print_hex_end
	rol si, 4
	mov ax, si
	and ax, 0xf
	cmp al, 10
	jl print_hex_number
	add al, 7
print_hex_number:
	add al, 48
	mov byte [ds:di], al
	inc di
	mov byte [ds:di], 0x20
	inc di
	inc cx
	jmp print_hex_loop
print_hex_end:
	pop ds
	pop cx
	pop ax
	ret

print_str:		;pointed by es:si
	push ax
	push cx
	push dx
	push ds
	mov ax, 0xb800
	mov ds, ax
print_str_char:
	mov byte al, [es:si]
	or al, al
	jz print_str_end
	
	cmp al, 10
	je print_str_newline
	
	mov byte [ds:di], al
	inc di
	mov byte [ds:di], 0x0f
	inc di
	inc si
	jmp print_str_char

print_str_newline:
	mov ax, di
	mov cx, 160
	xor dx, dx
	div cx
	mul cx
	mov di, ax
	add di, 160

	inc si
	jmp print_str_char
print_str_end:
	pop ds
	pop dx
	pop cx
	pop ax
	ret


rng:				;result in di
	push ax
	push cx
	push dx
	xor ax, ax
	int 0x1A
	mov ax, dx
	mov dx, 0
	mov cx, 75
	mul cx
	shl edx, 16
	mov dx, ax
	mov eax, edx
	xor edx, edx
	mov ecx, 65537
	div ecx
	xor ecx, ecx
	mov edi, edx
	and edi, 0x0000ffff
	xor edx, edx
	pop dx
	pop cx
	pop ax
	ret


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


display_menu:
	jmp display_menu_start

m0: db "Choose settings with arrow keys and enter", 0
m1: db "qwerty", 0
m2: db "azerty", 0
m3: db "english", 0
m4: db "french", 0
m5: db "play", 0

display_menu_start:
	push ax
	push cx
	push di
	push si
	
	mov ax, 0x0003
	int 0x10
	
	mov ah, 0x01
	mov cx, 0x2000
	int 0x10
	
	mov di, 0
	mov si, m0
	call print_str

	mov di, 320
	mov si, m1
	call print_str
	
	mov di, 334
	mov si, m2
	call print_str
	
	mov di, 480
	mov si, m3
	call print_str
	
	mov di, 496
	mov si, m4
	call print_str
	
	mov di, 800
	mov si, m5
	call print_str

	pop si
	pop di
	pop cx
	pop ax

	ret


menu_nb_rows: db 3			;number of rows

menu_sets:
	keyboard_layout: db 0
	lang: db 0

menu_len_rows: db 2, 2, 1		;number of elements per row
menu_elem_start_offsets:
	dw 320, 334			;1st row elements offsets		
	dw 480, 496			;2nd row elements offsets
	dw 800

menu_posx: db 0
menu_posy: db 0


menu_calc:
	push ax
	push bx
	push cx
	push ds
	push es
	push si				;pointer to column offset
	
	mov ax, 0xb800
	mov ds, ax
	xor ax, ax
	mov es, ax
	xor bx, bx
	xor cx, cx
	mov si, menu_elem_start_offsets
menu_calc_loop1:

	cmp bl, [es:menu_nb_rows]		;bl=row_id
	je menu_calc_loop1_end
	
	mov al, [es:menu_sets+bx]
	
menu_calc_loop2:

	cmp cl, [es:menu_len_rows+bx]	;cl=column_id
	je menu_calc_loop2_end
	
	mov di, [es:si]
	
	push ax
	mov al, 0x0f
	call change_color
	pop ax
	mov di, [es:si]
		
	cmp cl, al
	jne menu_calc_isnotset
	push ax
	mov al, 0x02
	call change_color
	pop ax
	mov di, [es:si]

menu_calc_isnotset:
	cmp [es:menu_posx], cl
	jne menu_calc_isnothover
	cmp [es:menu_posy], bl
	jne menu_calc_isnothover
	
	call invert_colors
menu_calc_isnothover:
	inc si
	inc si
	inc cl
	
	jmp menu_calc_loop2
menu_calc_loop2_end:
	xor cx, cx

	inc bl
	jmp menu_calc_loop1
menu_calc_loop1_end:
	pop si
	pop es
	pop ds
	pop cx
	pop bx
	pop ax


menu_get_key:
	xor ax, ax
	int 0x16
	cmp ah, 0x48		;up
	je menu_up
	cmp ah, 0x4b		;left
	je menu_left
	cmp ah, 0x4d		;right
	je menu_right
	cmp ah, 0x50		;down
	je menu_down
	cmp ah, 0x1c		;enter
	je menu_enter
	jmp menu_get_key

menu_up:
	cmp byte [es:menu_posy], 0
	je menu_get_key
	dec byte [es:menu_posy]
	mov byte [es:menu_posx], 0
	jmp menu_calc

menu_left:
	cmp byte [es:menu_posx], 0
	je menu_get_key
	dec byte [es:menu_posx]
	jmp menu_calc

menu_right:
	push ax
	push bx
	xor bx, bx
	mov bl, [es:menu_posy]
	mov al, [es:menu_len_rows+bx]
	dec al
	cmp [es:menu_posx], al
	pop bx
	pop ax
	je menu_get_key
	inc byte [es:menu_posx]
	jmp menu_calc

menu_down:
	push bx
	mov bl, [es:menu_nb_rows]
	dec bl
	cmp [es:menu_posy], bl
	pop bx
	je menu_get_key
	inc byte [es:menu_posy]
	mov byte [es:menu_posx], 0
	jmp menu_calc

menu_enter:
	push es
	push ax
	xor ax, ax
	mov es, ax
	cmp byte [es:menu_posy], 2
	pop ax
	pop es

	je menu_end

	push es
	push ax
	push bx
	xor bx, bx
	xor ax, ax
	mov es, ax
	mov bl, [es:menu_posy]
	mov al, [es:menu_posx]
	mov [es:menu_sets+bx], al
	pop bx
	pop ax
	pop es
	
	jmp menu_calc
	
menu_end:
	ret


invert_colors:			;di=where
	push ax
	push ds
	mov ax, 0xb800
	mov ds, ax
invert_colors_main:
	cmp byte [ds:di], 0x20
	je invert_colors_end
	inc di
	mov al, [ds:di]
	rol al, 4
	mov [ds:di], al
	inc di
	jmp invert_colors_main
invert_colors_end:
	pop ds
	pop ax
	ret

change_color:			;di=where, al=color
	push ds
	push ax
	mov ax, 0xb800
	mov ds, ax
	pop ax
change_color_main:
	cmp byte [ds:di], 0x20
	je change_color_end
	inc di
	mov [ds:di], al
	inc di
	jmp change_color_main
change_color_end:
	pop ds
	ret


key_search:					;ah=scan code , return ascii code in al
	push bx
	push cx
	push dx
	push di
	push es

	xor bx, bx
	mov es, bx

	mov bl, [es:keyboard_layout]
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


search_letter:				;letter to search in al
	push bx
	push cx				;fail or not
	push si
	push es

	xor bx, bx
	xor cx, cx
	mov es, bx
	mov si, [es:word_to_find]
	

search_letter_loop:
	cmp [es:si+bx], al			;letter of index bx
	je search_letter_found

	cmp byte [es:si+bx], 0
	je search_letter_loop_end

	inc bx
	jmp search_letter_loop

search_letter_found:
	mov [es:word_found+bx], al
	inc cx
	inc bx
	jmp search_letter_loop


search_letter_loop_end:
	or cx, cx
	jnz search_letter_end
	inc byte [es:fails]

search_letter_end:
	pop es
	pop si
	pop cx
	pop bx
	ret



fails: db 0


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


win_verifier:				;result in di
	push bx

	xor bx, bx
	mov di, 0

win_verifier_loop:
	cmp byte [es:word_found+bx], "_"
	je win_verifier_end

	cmp byte [es:word_found+bx], 0
	je win_verifier_positive

	inc bx
	jmp win_verifier_loop

win_verifier_positive:
	mov di, 1
win_verifier_end:
	pop bx
	ret


keyboards:
dw 6
dw 32
dw 58


db 0x1e
db 0x30
db 0x2e
db 0x20
db 0x12
db 0x21
db 0x22
db 0x23
db 0x17
db 0x24
db 0x25
db 0x26
db 0x32
db 0x31
db 0x18
db 0x19
db 0x10
db 0x13
db 0x1f
db 0x14
db 0x16
db 0x2f
db 0x11
db 0x2d
db 0x15
db 0x2c

db 0x10
db 0x30
db 0x2e
db 0x20
db 0x12
db 0x21
db 0x22
db 0x23
db 0x17
db 0x24
db 0x25
db 0x26
db 0x27
db 0x31
db 0x18
db 0x19
db 0x1e
db 0x13
db 0x1f
db 0x14
db 0x16
db 0x2f
db 0x2c
db 0x2d
db 0x15
db 0x11



words_langs:
dw 6
dw 22
dw 68





dw 68
dw 77
dw 83
dw 89
dw 93
dw 101
dw 108
dw 114



dw 121
dw 127
dw 135
dw 140
dw 147
dw 155
dw 163
dw 170
dw 177
dw 182
dw 187
dw 195
dw 203
dw 207
dw 213
dw 220
dw 229
dw 237
dw 247
dw 255
dw 265
dw 272
dw 276








db "COMPUTER", 0
db "CLOCK", 0
db "MOUSE", 0
db "CAT", 0
db "RAINBOW", 0
db "RANDOM", 0
db "TABLE", 0
db "SCREEN", 0



db "ANGLE", 0
db "ARMOIRE", 0
db "BANC", 0
db "BUREAU", 0
db "CABINET", 0
db "CARREAU", 0
db "CHAISE", 0
db "CLASSE", 0
db "CLEF", 0
db "COIN", 0
db "COULOIR", 0
db "DOSSIER", 0
db "EAU", 0
db "ECOLE", 0
db "ENTRER", 0
db "ESCALIER", 0
db "ETAGERE", 0
db "EXTERIEUR", 0
db "FENETRE", 0
db "INTERIEUR", 0
db "LAVABO", 0
db "LIT", 0
db "MARCHE", 0



word_found: db "_________", 0

designs:
dw 14
dw 96
dw 194
dw 300
dw 406
dw 513
dw 627



db "       +-------+", 10
db "       |", 10
db "       |", 10
db "       |", 10
db "       |", 10
db "       |", 10
db "    ==============", 10
db 0

db "       +-------+", 10
db "       |       |", 10
db "       |       O", 10
db "       |", 10
db "       |", 10
db "       |", 10
db "    ==============", 10
db 0

db "       +-------+", 10
db "       |       |", 10
db "       |       O", 10
db "       |       |", 10
db "       |", 10
db "       |", 10
db "    ==============", 10
db 0

db "       +-------+", 10
db "       |       |", 10
db "       |       O", 10
db "       |      -|", 10
db "       |", 10
db "       |", 10
db "    ==============", 10
db 0

db "       +-------+", 10
db "       |       |", 10
db "       |       O", 10
db "       |      -|-", 10
db "       |", 10
db "       |", 10
db "    ==============", 10
db 0

db "       +-------+", 10
db "       |       |", 10
db "       |       O", 10
db "       |      -|-", 10
db "       |      |", 10
db "       |", 10
db "    ==============", 10
db 0

db "       +-------+", 10
db "       |       |", 10
db "       |       O", 10
db "       |      -|-", 10
db "       |      | |", 10
db "       |", 10
db "    ==============", 10
db 0



word_to_find: dw 0


times 316 db 0