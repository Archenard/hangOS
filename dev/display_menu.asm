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
