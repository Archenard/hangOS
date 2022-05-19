menu_nb_rows: db 2			;number of rows
menu_sets: db 0, 0
menu_len_rows: db 2, 2			;number of elements per row
menu_elem_start_offset:
	db 0, 14			;1st row elements offsets
	db 160, 176			;2nd row elements offsets


menu_posx: db 0
menu_posy: db 0



menu_calc:
	push ax
	push ds
	mov ax, 0xb800
	mov ds, ax
	xor ax, ax
	push bx
	push cx
	push es
	push si				;pointer to column offset
	mov si, menu_elem_start_offsets
menu_calc_loop1:
	cmp bl, [menu_nb_rows]		;bl=row_id
	je menu_calc_loop1_end
	
	mov al, [menu_sets+bx]
	
menu_calc_loop2:
	cmp cl, [menu_len_rows+bx]	;cl=column_id
	je menu_calc_loop2_end
	
	mov di, [es:si]
	
	cmp cl, al
	jne menu_calc_isnotset
	push ax
	mov al, 0x02
	call change_color
	pop ax
menu_calc_isnotset:
	cmp [menu_posx], cl
	jne menu_calc_isnothover
	cmp [menu_posy], bl
	jne menu_calc_isnothover
	
	call invert_colors
menu_calc_isnothover:

	inc cl
	jmp menu_calc_loop2
menu_calc_loop2_end:
	inc si
	xor cx, cx

	inc bl
	jmp menu_calc_loop1
menu_calc_loop1_end:
	pop si
	pop es
	pop cx
	pop bx
	pop ds
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
	cmp byte [menu_posy], 0
	je no_mov
	dec byte [menu_posy]
	mov byte [menu_posx], 0
	jmp menu_calc

menu_left:
	cmp byte [menu_posx], 0
	je no_mov
	dec byte [menu_posx]
	jmp menu_calc

menu_right:
	push ax
	push bx
	mov bl, [menu_posy]
	mov al, [menu_len_rows+bx]
	cmp [menu_posx], al
	pop bx
	pop ax
	je no_mov
	inc byte [menu_posx]
	jmp menu_calc

menu_down:
	push bx
	mov bl, [menu_nb_rows]
	dec bl
	cmp [menu_posy], bl
	pop bx
	je no_mov
	inc byte [menu_posy]
	jmp menu_calc

menu_enter:


no_mov:
