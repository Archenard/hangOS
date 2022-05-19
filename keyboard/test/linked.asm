[ORG 0x7C00]

xor ax, ax
mov ds, ax
mov es, ax
mov ss, ax
mov sp, 0x7c00

mov ah, 2		;read disk
mov al, 2		;number of sectors to read
mov ch, 0		;C cylinder
mov cl, 2		;S sector number
mov dh, 0		;H head
mov bx, 0x7e00		;[es:bx] adress to load
int 0x13

jmp 0x7e00

times 510-($-$$) db 0
db 0x55, 0xAA


org 0x7c00

xor ax, ax
mov ds, ax
mov es, ax
mov ss, ax
mov sp, 0x7c00

get_key:
	xor ax, ax
kb:
	int 0x16

	call key_search
	mov ah, 0x0e
	int 0x10
	jmp get_key

hang:
	jmp hang


print_hex:		;print the content of si, not a pointed value
	push ax
	push cx
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
	mov byte [ds:di], " "
	inc di
	inc cx
	jmp print_hex_loop
print_hex_end:
	pop cx
	pop ax
	ret

print_str:		;pointed by es:si
	push ax
	mov ax, 0xb800
	mov ds, ax
print_str_char:
	mov byte al, [es:si]
	or al, al
	jz print_str_end
	mov byte [ds:di], al
	inc di
	mov byte [ds:di], " "
	inc di
	inc si
	jmp print_str_char
print_str_end:
	pop ax
	ret


keyboards:
dw 4
dw 30


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


menu_nb_rows: db 3			;number of rows

menu_sets:
	keyboard_type: db 1
	lang: db 0

menu_len_rows: db 2, 2, 1		;number of elements per row
menu_elem_start_offsets:
	;dw 0, 14			;1st row elements offsets
	dw 320, 334
	;dw 160, 176			;2nd row elements offsets
	dw 480, 496
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
	je no_mov
	dec byte [es:menu_posy]
	mov byte [es:menu_posx], 0
	jmp menu_calc

menu_left:
	cmp byte [es:menu_posx], 0
	je no_mov
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
	je no_mov
	inc byte [es:menu_posx]
	jmp menu_calc

menu_down:
	push bx
	mov bl, [es:menu_nb_rows]
	dec bl
	cmp [es:menu_posy], bl
	pop bx
	je no_mov
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
	je game
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

no_mov:
	jmp menu_calc
	
game:
	jmp no_mov


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


times 469 db 0