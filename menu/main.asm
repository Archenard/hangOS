jmp main_start

m0: db "Select your parameters with arrows key and enter", 0
m1: db "qwerty", 0
m2: db "azerty", 0
m3: db "english", 0
m4: db "french", 0
m5: db "play", 0

main_start:
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

jmp menu_calc
