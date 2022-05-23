win_verifier:				;result in di
	push bx

	xor bx, bx
	mov di, 0

win_verifier_loop:
	cmp byte [es:word_found+bx], "_"
	je win_verifier_end

	cmp byte [es:word_found+bx], 0
	je win_verifier_positive

	inc bx
	jmp win_verifier_loop

win_verifier_positive:
	mov di, 1
win_verifier_end:
	pop bx
	ret
