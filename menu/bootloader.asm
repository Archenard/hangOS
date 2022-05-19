[ORG 0x7C00]

xor ax, ax
mov ds, ax
mov es, ax
mov ss, ax
mov sp, 0x7c00

mov ah, 2		;read disk
mov al, __sectors__		;number of sectors to read
mov ch, 0		;C cylinder
mov cl, 2		;S sector
mov dh, 0		;H head
;mov dl, 0x80		;drive, already set on boot drive by bios
mov bx, 0x7e00		;[es:bx] adress to load
int 0x13

jmp 0x7e00

times 510-($-$$) db 0
db 0x55, 0xAA
