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
