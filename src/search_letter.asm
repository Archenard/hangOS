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
