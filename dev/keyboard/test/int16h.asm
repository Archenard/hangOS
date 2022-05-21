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
