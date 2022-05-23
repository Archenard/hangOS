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
