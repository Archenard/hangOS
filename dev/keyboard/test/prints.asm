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
