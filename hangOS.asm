[ORG 0x7C00]

xor ax, ax
mov ds, ax
mov es, ax
mov ss, ax
mov sp, 0x7c00

mov ah, 2		;read disk
mov al, 20		;number of sectors to read
mov ch, 0		;C cylinder
mov cl, 2		;S sector
mov dh, 0		;H head
;mov dl, 0x80		;drive, already set on boot drive by bios
mov bx, 0x7e00		;[es:bx] adress to load
int 0x13

jmp 0x7e00

times 510-($-$$) db 0
db 0x55, 0xAA


main_start:
	xor ax, ax
	mov es, ax
	
	mov byte [es:fails], 0
	call reset_found
	
	call display_menu
	
	mov di, 3768
	mov si, credits
	call print_str
	mov di, 3928
	mov si, my_github
	call print_str

	call menu_calc

	call select_word

	mov ah, 0x00			;clear screen
	mov al, 0x03
	int 0x10

	mov ah, 0x02			;move cursor
	xor bx, bx
	mov dh, 16
	mov dl, 16
	int 0x10

	mov di, 3768
	mov si, credits
	call print_str
	mov di, 3928
	mov si, my_github
	call print_str

main_game_loop:
	mov di, 320
	mov si, word_found
	call print_str

	mov di, 960
	call draw_gallows
	
	cmp byte [es:fails], 6
	je main_loose

	mov di, 2560
	mov si, guess_a_letter
	call print_str

main_get_key:
	xor ax, ax
	int 0x16
	call key_search

	cmp al, "A"
	jl main_get_key
	cmp al, "Z"
	jg main_get_key
	
	call search_letter

	call win_verifier
	mov dx, di
	cmp dx, 1
	je main_game_end

	jmp main_game_loop


main_loose:
	mov dx, 2

main_game_end:
	mov ah, 0x00			;clear screen
	mov al, 0x03
	int 0x10
	mov ah, 0x01			;hide cursor
	mov cx, 0x2000
	int 0x10
	
	mov di, 0
	call draw_gallows

	mov di, 1280

	cmp dx, 1
	je main_game_end_win

	mov si, loose_message
	call print_str
	jmp main_game_end_common

main_game_end_win:
	mov si, win_message
	call print_str

main_game_end_common:	
	mov di, 1600
	mov si, the_word_was
	call print_str

	mov si, [es:word_to_find]
	call print_str

	mov di, 2080
	mov si, press_enter_to_replay
	call print_str

	mov di, 3768
	mov si, credits
	call print_str
	mov di, 3928
	mov si, my_github
	call print_str

main_wait_replay:
	xor ax, ax
	int 0x16
	cmp ah, 0x1c
	jne main_wait_replay

	jmp main_start

guess_a_letter: db "Guess a letter:", 0
loose_message: db "Oh no, you lost :(", 0
win_message: db "Bravo! You won :)", 0
the_word_was: db "The word was: ", 0
press_enter_to_replay: db "Press enter to replay", 0
credits: db "hangOS, by Archenard", 0
my_github: db "https://github.com/Archenard/hangOS", 0


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


select_word:			;change [word_to_find] with pointer
	push ax
	push bx
	push cx
	push dx
	push es
	push di
	push si
	
	xor ax, ax
	mov es, ax


	mov bx, words_langs

	xor ax, ax
	mov al, [es:lang]
	shl ax, 1

	add bx, ax			;bx=pointer to the offset of the lang selected

	mov ax, [es:bx+2]		;next lang offset

	mov bx, [es:bx]			;current lang offset

	mov cx, ax
	sub cx, bx
	shr cx, 1			;number of words in this lang( /2 bc 2B per entry)

	add bx, words_langs		;pointer to array of offset of the words


	call rng
	xor dx, dx
	mov ax, di
	div cx
	mov ax, dx			;ax = ax mod cx

	shl ax, 1

	add bx, ax

	mov si, [es:bx]
	add si, words_langs
	mov [es:word_to_find], si


	xor cx, cx
select_word_loop:
	mov al, [es:si]
	or al, al
	jz select_word_loop_end
	inc cx
	inc si
	jmp select_word_loop
select_word_loop_end:
	mov si, word_found
	add si, cx
	mov byte [es:si], 0


	pop si
	pop di
	pop es
	pop dx
	pop cx
	pop bx
	pop ax
	ret


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

	mov ah, 0x00			;clear screen
	mov al, 0x03
	int 0x10
	
	mov ah, 0x01			;hide cursor
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


menu_nb_rows: db 3			;number of rows

menu_sets:
	keyboard_layout: db 0
	lang: db 0

menu_len_rows: db 2, 2, 1		;number of elements per row
menu_elem_start_offsets:
	dw 320, 334			;1st row elements offsets		
	dw 480, 496			;2nd row elements offsets
	dw 800

menu_posx: db 0
menu_posy: db 0


menu_calc:
	push ax
	push bx
	push cx
	push ds
	push es
	push si				;pointer to column offset
	
	mov ax, 0xb800
	mov ds, ax
	xor ax, ax
	mov es, ax
	xor bx, bx
	xor cx, cx
	mov si, menu_elem_start_offsets
menu_calc_loop1:

	cmp bl, [es:menu_nb_rows]		;bl=row_id
	je menu_calc_loop1_end
	
	mov al, [es:menu_sets+bx]
	
menu_calc_loop2:

	cmp cl, [es:menu_len_rows+bx]	;cl=column_id
	je menu_calc_loop2_end
	
	mov di, [es:si]
	
	push ax
	mov al, 0x0f
	call change_color
	pop ax
	mov di, [es:si]
		
	cmp cl, al
	jne menu_calc_isnotset
	push ax
	mov al, 0x02
	call change_color
	pop ax
	mov di, [es:si]

menu_calc_isnotset:
	cmp [es:menu_posx], cl
	jne menu_calc_isnothover
	cmp [es:menu_posy], bl
	jne menu_calc_isnothover
	
	call invert_colors
menu_calc_isnothover:
	inc si
	inc si
	inc cl
	
	jmp menu_calc_loop2
menu_calc_loop2_end:
	xor cx, cx

	inc bl
	jmp menu_calc_loop1
menu_calc_loop1_end:
	pop si
	pop es
	pop ds
	pop cx
	pop bx
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
	cmp byte [es:menu_posy], 0
	je menu_get_key
	dec byte [es:menu_posy]
	mov byte [es:menu_posx], 0
	jmp menu_calc

menu_left:
	cmp byte [es:menu_posx], 0
	je menu_get_key
	dec byte [es:menu_posx]
	jmp menu_calc

menu_right:
	push ax
	push bx
	xor bx, bx
	mov bl, [es:menu_posy]
	mov al, [es:menu_len_rows+bx]
	dec al
	cmp [es:menu_posx], al
	pop bx
	pop ax
	je menu_get_key
	inc byte [es:menu_posx]
	jmp menu_calc

menu_down:
	push bx
	mov bl, [es:menu_nb_rows]
	dec bl
	cmp [es:menu_posy], bl
	pop bx
	je menu_get_key
	inc byte [es:menu_posy]
	mov byte [es:menu_posx], 0
	jmp menu_calc

menu_enter:
	push es
	push ax
	xor ax, ax
	mov es, ax
	cmp byte [es:menu_posy], 2
	pop ax
	pop es

	je menu_end

	push es
	push ax
	push bx
	xor bx, bx
	xor ax, ax
	mov es, ax
	mov bl, [es:menu_posy]
	mov al, [es:menu_posx]
	mov [es:menu_sets+bx], al
	pop bx
	pop ax
	pop es
	
	jmp menu_calc
	
menu_end:
	ret


invert_colors:			;di=where
	push ax
	push ds
	mov ax, 0xb800
	mov ds, ax
invert_colors_main:
	cmp byte [ds:di], 0x20
	je invert_colors_end
	inc di
	mov al, [ds:di]
	rol al, 4
	mov [ds:di], al
	inc di
	jmp invert_colors_main
invert_colors_end:
	pop ds
	pop ax
	ret

change_color:			;di=where, al=color
	push ds
	push ax
	mov ax, 0xb800
	mov ds, ax
	pop ax
change_color_main:
	cmp byte [ds:di], 0x20
	je change_color_end
	inc di
	mov [ds:di], al
	inc di
	jmp change_color_main
change_color_end:
	pop ds
	ret


key_search:					;ah=scan code , return ascii code in al
	push bx
	push cx
	push dx
	push di
	push es

	xor bx, bx
	mov es, bx

	mov bl, [es:keyboard_layout]
	shl bl, 1				;times 2, each entry is 2 Bytes
	
	add bl, 2
	mov dx, [es:keyboards+bx]
	add dx, keyboards
	sub bl, 2
	
	mov bx, [es:keyboards+bx]
	add bx, keyboards			;bx=address the begin of the codes

	mov di, bx

key_not_found:
	
	cmp di, dx
	je keyboard_end

	cmp ah, [es:di]
	je key_found
	inc di
	jmp key_not_found

key_found:
	sub di, bx
	mov cx, di
	mov al, cl
	add al, 65

keyboard_end:
	pop es
	pop di
	pop dx
	pop cx
	pop bx
	ret


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


draw_gallows:			;draw at di
	push bx
	push si

	xor bx, bx


	mov bl, [es:fails]
	shl bx, 1

	mov si, [es:designs+bx]
	add si, designs

	call print_str

	pop si
	pop bx
	ret


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


reset_found:
	push bx
	push cx
	push es

	xor bx, bx
	xor cx, cx
	mov es, bx

	mov cl, [es:max_word_length]

reset_found_loop:
	or cx, cx
	jz reset_found_end
	mov byte [es:word_found+bx], "_"
	inc bx
	dec cx
	jmp reset_found_loop
reset_found_end:
	pop es
	pop cx
	pop bx
	ret


keyboards:
dw 6
dw 32
dw 58


db 0x1e
db 0x30
db 0x2e
db 0x20
db 0x12
db 0x21
db 0x22
db 0x23
db 0x17
db 0x24
db 0x25
db 0x26
db 0x32
db 0x31
db 0x18
db 0x19
db 0x10
db 0x13
db 0x1f
db 0x14
db 0x16
db 0x2f
db 0x11
db 0x2d
db 0x15
db 0x2c

db 0x10
db 0x30
db 0x2e
db 0x20
db 0x12
db 0x21
db 0x22
db 0x23
db 0x17
db 0x24
db 0x25
db 0x26
db 0x27
db 0x31
db 0x18
db 0x19
db 0x1e
db 0x13
db 0x1f
db 0x14
db 0x16
db 0x2f
db 0x2c
db 0x2d
db 0x15
db 0x11



words_langs:
dw 6
dw 22
dw 1692





dw 1692
dw 1701
dw 1707
dw 1713
dw 1717
dw 1725
dw 1732
dw 1738



dw 1745
dw 1751
dw 1759
dw 1764
dw 1771
dw 1779
dw 1787
dw 1794
dw 1801
dw 1806
dw 1811
dw 1819
dw 1827
dw 1831
dw 1837
dw 1844
dw 1853
dw 1861
dw 1871
dw 1879
dw 1889
dw 1896
dw 1900
dw 1907
dw 1915
dw 1926
dw 1933
dw 1940
dw 1944
dw 1952
dw 1960
dw 1968
dw 1974
dw 1983
dw 1993
dw 1999
dw 2006
dw 2014
dw 2020
dw 2026
dw 2034
dw 2044
dw 2050
dw 2057
dw 2065
dw 2069
dw 2077
dw 2086
dw 2093
dw 2099
dw 2107
dw 2116
dw 2122
dw 2129
dw 2138
dw 2144
dw 2150
dw 2157
dw 2166
dw 2174
dw 2183
dw 2191
dw 2199
dw 2206
dw 2215
dw 2223
dw 2232
dw 2239
dw 2246
dw 2254
dw 2264
dw 2270
dw 2277
dw 2285
dw 2296
dw 2303
dw 2310
dw 2317
dw 2323
dw 2330
dw 2336
dw 2340
dw 2345
dw 2353
dw 2360
dw 2367
dw 2374
dw 2381
dw 2388
dw 2393
dw 2398
dw 2403
dw 2408
dw 2412
dw 2418
dw 2424
dw 2431
dw 2436
dw 2439
dw 2448
dw 2455
dw 2458
dw 2463
dw 2467
dw 2474
dw 2480
dw 2487
dw 2492
dw 2498
dw 2505
dw 2515
dw 2522
dw 2531
dw 2539
dw 2547
dw 2553
dw 2560
dw 2568
dw 2575
dw 2582
dw 2589
dw 2597
dw 2607
dw 2614
dw 2618
dw 2624
dw 2632
dw 2638
dw 2645
dw 2652
dw 2660
dw 2669
dw 2673
dw 2679
dw 2684
dw 2691
dw 2698
dw 2703
dw 2709
dw 2715
dw 2721
dw 2727
dw 2732
dw 2737
dw 2745
dw 2752
dw 2758
dw 2767
dw 2780
dw 2786
dw 2792
dw 2798
dw 2804
dw 2817
dw 2826
dw 2836
dw 2841
dw 2847
dw 2851
dw 2861
dw 2871
dw 2877
dw 2883
dw 2891
dw 2900
dw 2909
dw 2919
dw 2928
dw 2935
dw 2943
dw 2951
dw 2961
dw 2972
dw 2978
dw 2984
dw 2993
dw 2998
dw 3003
dw 3007
dw 3012
dw 3023
dw 3030
dw 3037
dw 3043
dw 3056
dw 3061
dw 3067
dw 3074
dw 3082
dw 3086
dw 3093
dw 3103
dw 3114
dw 3120
dw 3126
dw 3133
dw 3139
dw 3146
dw 3155
dw 3161
dw 3166
dw 3174
dw 3187
dw 3197
dw 3208
dw 3214
dw 3224
dw 3229
dw 3239
dw 3244
dw 3252
dw 3261
dw 3269
dw 3279
dw 3286
dw 3295
dw 3305
dw 3314
dw 3322
dw 3333
dw 3343
dw 3350
dw 3357
dw 3366
dw 3375
dw 3383
dw 3392
dw 3400
dw 3409
dw 3414
dw 3423
dw 3431
dw 3438
dw 3446
dw 3455
dw 3464
dw 3472
dw 3478
dw 3484
dw 3493
dw 3500
dw 3507
dw 3515
dw 3520
dw 3527
dw 3535
dw 3542
dw 3549
dw 3557
dw 3563
dw 3569
dw 3577
dw 3586
dw 3593
dw 3601
dw 3613
dw 3622
dw 3631
dw 3639
dw 3648
dw 3655
dw 3665
dw 3673
dw 3679
dw 3688
dw 3696
dw 3707
dw 3713
dw 3717
dw 3727
dw 3736
dw 3743
dw 3750
dw 3757
dw 3762
dw 3772
dw 3783
dw 3789
dw 3796
dw 3802
dw 3809
dw 3817
dw 3823
dw 3829
dw 3836
dw 3844
dw 3851
dw 3858
dw 3868
dw 3877
dw 3883
dw 3892
dw 3899
dw 3906
dw 3914
dw 3922
dw 3928
dw 3937
dw 3946
dw 3957
dw 3966
dw 3976
dw 3984
dw 3990
dw 3998
dw 4007
dw 4014
dw 4021
dw 4031
dw 4039
dw 4050
dw 4056
dw 4064
dw 4073
dw 4083
dw 4091
dw 4099
dw 4105
dw 4110
dw 4116
dw 4124
dw 4134
dw 4139
dw 4147
dw 4154
dw 4160
dw 4170
dw 4182
dw 4189
dw 4195
dw 4200
dw 4205
dw 4213
dw 4219
dw 4224
dw 4231
dw 4236
dw 4241
dw 4246
dw 4254
dw 4260
dw 4271
dw 4280
dw 4289
dw 4295
dw 4302
dw 4308
dw 4316
dw 4326
dw 4333
dw 4340
dw 4350
dw 4359
dw 4367
dw 4374
dw 4384
dw 4392
dw 4398
dw 4405
dw 4411
dw 4419
dw 4424
dw 4428
dw 4433
dw 4437
dw 4447
dw 4456
dw 4461
dw 4469
dw 4475
dw 4481
dw 4487
dw 4494
dw 4501
dw 4509
dw 4518
dw 4526
dw 4534
dw 4543
dw 4551
dw 4558
dw 4567
dw 4575
dw 4587
dw 4595
dw 4603
dw 4610
dw 4617
dw 4625
dw 4633
dw 4641
dw 4647
dw 4653
dw 4662
dw 4671
dw 4677
dw 4686
dw 4694
dw 4702
dw 4710
dw 4718
dw 4727
dw 4735
dw 4745
dw 4752
dw 4759
dw 4768
dw 4774
dw 4782
dw 4790
dw 4797
dw 4803
dw 4811
dw 4819
dw 4825
dw 4831
dw 4838
dw 4850
dw 4858
dw 4862
dw 4874
dw 4881
dw 4888
dw 4897
dw 4904
dw 4910
dw 4914
dw 4919
dw 4924
dw 4931
dw 4935
dw 4942
dw 4951
dw 4957
dw 4964
dw 4970
dw 4977
dw 4986
dw 4994
dw 5001
dw 5011
dw 5020
dw 5028
dw 5039
dw 5048
dw 5058
dw 5066
dw 5076
dw 5080
dw 5088
dw 5097
dw 5105
dw 5113
dw 5121
dw 5126
dw 5130
dw 5137
dw 5143
dw 5148
dw 5154
dw 5159
dw 5164
dw 5170
dw 5176
dw 5182
dw 5191
dw 5200
dw 5206
dw 5214
dw 5221
dw 5229
dw 5238
dw 5245
dw 5251
dw 5257
dw 5266
dw 5271
dw 5277
dw 5284
dw 5291
dw 5297
dw 5302
dw 5306
dw 5312
dw 5320
dw 5327
dw 5335
dw 5341
dw 5348
dw 5354
dw 5360
dw 5367
dw 5376
dw 5383
dw 5389
dw 5398
dw 5406
dw 5415
dw 5423
dw 5432
dw 5444
dw 5452
dw 5461
dw 5467
dw 5474
dw 5485
dw 5491
dw 5497
dw 5504
dw 5510
dw 5515
dw 5521
dw 5526
dw 5538
dw 5541
dw 5545
dw 5550
dw 5554
dw 5560
dw 5568
dw 5577
dw 5585
dw 5591
dw 5596
dw 5601
dw 5611
dw 5617
dw 5624
dw 5631
dw 5636
dw 5642
dw 5650
dw 5660
dw 5668
dw 5672
dw 5684
dw 5692
dw 5698
dw 5704
dw 5712
dw 5719
dw 5725
dw 5731
dw 5740
dw 5748
dw 5756
dw 5763
dw 5768
dw 5778
dw 5782
dw 5790
dw 5799
dw 5808
dw 5815
dw 5822
dw 5831
dw 5840
dw 5848
dw 5857
dw 5867
dw 5875
dw 5882
dw 5889
dw 5897
dw 5905
dw 5912
dw 5918
dw 5925
dw 5933
dw 5940
dw 5950
dw 5954
dw 5961
dw 5967
dw 5977
dw 5984
dw 5990
dw 5999
dw 6008
dw 6015
dw 6021
dw 6025
dw 6031
dw 6037
dw 6044
dw 6049
dw 6054
dw 6066
dw 6071
dw 6077
dw 6085
dw 6092
dw 6097
dw 6102
dw 6108
dw 6115
dw 6123
dw 6130
dw 6136
dw 6143
dw 6151
dw 6160
dw 6167
dw 6175
dw 6184
dw 6193
dw 6205
dw 6212
dw 6220
dw 6228
dw 6235
dw 6241
dw 6249
dw 6256
dw 6262
dw 6270
dw 6277
dw 6284
dw 6296
dw 6302
dw 6308
dw 6315
dw 6321
dw 6326
dw 6332
dw 6337
dw 6345
dw 6350
dw 6359
dw 6363
dw 6368
dw 6373
dw 6378
dw 6384
dw 6389
dw 6394
dw 6401
dw 6409
dw 6416
dw 6422
dw 6427
dw 6432
dw 6436
dw 6443
dw 6449
dw 6459
dw 6462
dw 6467
dw 6474
dw 6481
dw 6486
dw 6491
dw 6500
dw 6506
dw 6514
dw 6520
dw 6528
dw 6533
dw 6538
dw 6546
dw 6553
dw 6562
dw 6568
dw 6574
dw 6580
dw 6586
dw 6591
dw 6595
dw 6601
dw 6608
dw 6615
dw 6622
dw 6626
dw 6635
dw 6643
dw 6650
dw 6657
dw 6666
dw 6672
dw 6678
dw 6683
dw 6689
dw 6701
dw 6708
dw 6714
dw 6718
dw 6724
dw 6731
dw 6740
dw 6744
dw 6753
dw 6760
dw 6767
dw 6773
dw 6782
dw 6786
dw 6797
dw 6803
dw 6808
dw 6813
dw 6823
dw 6831
dw 6837
dw 6842
dw 6848
dw 6854
dw 6861
dw 6871
dw 6877
dw 6885
dw 6895
dw 6903
dw 6913
dw 6918
dw 6926
dw 6932
dw 6940
dw 6945
dw 6954
dw 6959
dw 6970
dw 6977
dw 6984
dw 6994
dw 7002
dw 7010
dw 7018
dw 7027
dw 7034
dw 7044
dw 7051
dw 7058
dw 7065
dw 7074
dw 7084
dw 7092
dw 7102
dw 7109
dw 7115
dw 7123
dw 7131
dw 7139
dw 7146
dw 7153
dw 7160
dw 7168
dw 7176
dw 7184
dw 7191
dw 7198
dw 7204
dw 7214
dw 7223
dw 7233
dw 7241
dw 7248
dw 7257
dw 7264
dw 7271
dw 7282
dw 7292
dw 7303
dw 7309
dw 7314
dw 7321
dw 7330
dw 7335
dw 7341
dw 7348
dw 7357
dw 7361
dw 7368
dw 7377
dw 7385
dw 7393
dw 7404
dw 7411
dw 7417
dw 7428
dw 7434
dw 7439
dw 7448
dw 7453
dw 7460
dw 7468
dw 7473
dw 7478
dw 7485
dw 7493
dw 7500
dw 7504
dw 7509
dw 7516
dw 7523
dw 7530
dw 7536
dw 7542
dw 7548
dw 7557
dw 7563
dw 7574
dw 7580
dw 7588
dw 7594
dw 7598
dw 7607
dw 7613
dw 7618
dw 7623
dw 7628
dw 7637
dw 7644
dw 7651
dw 7659
dw 7667
dw 7673
dw 7683
dw 7691
dw 7700
dw 7708
dw 7715
dw 7723
dw 7730
dw 7738
dw 7747
dw 7755
dw 7766
dw 7775
dw 7783
dw 7789
dw 7797
dw 7808
dw 7816
dw 7824
dw 7828








db "COMPUTER", 0
db "CLOCK", 0
db "MOUSE", 0
db "CAT", 0
db "RAINBOW", 0
db "RANDOM", 0
db "TABLE", 0
db "SCREEN", 0



db "ANGLE", 0
db "ARMOIRE", 0
db "BANC", 0
db "BUREAU", 0
db "CABINET", 0
db "CARREAU", 0
db "CHAISE", 0
db "CLASSE", 0
db "CLEF", 0
db "COIN", 0
db "COULOIR", 0
db "DOSSIER", 0
db "EAU", 0
db "ECOLE", 0
db "ENTRER", 0
db "ESCALIER", 0
db "ETAGERE", 0
db "EXTERIEUR", 0
db "FENETRE", 0
db "INTERIEUR", 0
db "LAVABO", 0
db "LIT", 0
db "MARCHE", 0
db "MATELAS", 0
db "MATERNELLE", 0
db "MEUBLE", 0
db "MOUSSE", 0
db "MUR", 0
db "PELUCHE", 0
db "PLACARD", 0
db "PLAFOND", 0
db "PORTE", 0
db "POUBELLE", 0
db "RADIATEUR", 0
db "RAMPE", 0
db "RIDEAU", 0
db "ROBINET", 0
db "SALLE", 0
db "SALON", 0
db "SERRURE", 0
db "SERVIETTE", 0
db "SIEGE", 0
db "SIESTE", 0
db "SILENCE", 0
db "SOL", 0
db "SOMMEIL", 0
db "SONNETTE", 0
db "SORTIE", 0
db "TABLE", 0
db "TABLEAU", 0
db "TABOURET", 0
db "TAPIS", 0
db "TIROIR", 0
db "TOILETTE", 0
db "VITRE", 0
db "ALLER", 0
db "AMENER", 0
db "APPORTER", 0
db "APPUYER", 0
db "ATTENDRE", 0
db "BAILLER", 0
db "COUCHER", 0
db "DORMIR", 0
db "ECLAIRER", 0
db "EMMENER", 0
db "EMPORTER", 0
db "ENTRER", 0
db "FERMER", 0
db "FRAPPER", 0
db "INSTALLER", 0
db "LEVER", 0
db "OUVRIR", 0
db "PRESSER", 0
db "RECHAUFFER", 0
db "RESTER", 0
db "SONNER", 0
db "SORTIR", 0
db "VENIR", 0
db "ABSENT", 0
db "ASSIS", 0
db "BAS", 0
db "HAUT", 0
db "PRESENT", 0
db "GAUCHE", 0
db "DROITE", 0
db "DEBOUT", 0
db "DEDANS", 0
db "DEHORS", 0
db "FACE", 0
db "LOIN", 0
db "PRES", 0
db "TARD", 0
db "TOT", 0
db "APRES", 0
db "AVANT", 0
db "CONTRE", 0
db "DANS", 0
db "DE", 0
db "DERRIERE", 0
db "DEVANT", 0
db "DU", 0
db "SOUS", 0
db "SUR", 0
db "CRAYON", 0
db "STYLO", 0
db "FEUTRE", 0
db "MINE", 0
db "GOMME", 0
db "DESSIN", 0
db "COLORIAGE", 0
db "RAYURE", 0
db "PEINTURE", 0
db "PINCEAU", 0
db "COULEUR", 0
db "CRAIE", 0
db "PAPIER", 0
db "FEUILLE", 0
db "CAHIER", 0
db "CARNET", 0
db "CARTON", 0
db "CISEAUX", 0
db "DECOUPAGE", 0
db "PLIAGE", 0
db "PLI", 0
db "COLLE", 0
db "AFFAIRE", 0
db "BOITE", 0
db "CASIER", 0
db "CAISSE", 0
db "TROUSSE", 0
db "CARTABLE", 0
db "JEU", 0
db "JOUET", 0
db "PION", 0
db "DOMINO", 0
db "PUZZLE", 0
db "CUBE", 0
db "PERLE", 0
db "CHOSE", 0
db "FORME", 0
db "CARRE", 0
db "ROND", 0
db "PATE", 0
db "MODELER", 0
db "TAMPON", 0
db "LIVRE", 0
db "HISTOIRE", 0
db "BIBLIOTHEQUE", 0
db "IMAGE", 0
db "ALBUM", 0
db "TITRE", 0
db "CONTE", 0
db "DICTIONNAIRE", 0
db "MAGAZINE", 0
db "CATALOGUE", 0
db "PAGE", 0
db "LIGNE", 0
db "MOT", 0
db "ENVELOPPE", 0
db "ETIQUETTE", 0
db "CARTE", 0
db "APPEL", 0
db "AFFICHE", 0
db "ALPHABET", 0
db "APPAREIL", 0
db "CAMESCOPE", 0
db "CASSETTE", 0
db "CHAINE", 0
db "CHANSON", 0
db "CHIFFRE", 0
db "CONTRAIRE", 0
db "DIFFERENCE", 0
db "DOIGT", 0
db "ECRAN", 0
db "ECRITURE", 0
db "FILM", 0
db "FOIS", 0
db "FOI", 0
db "IDEE", 0
db "INSTRUMENT", 0
db "INTRUS", 0
db "LETTRE", 0
db "LISTE", 0
db "MAGNETOSCOPE", 0
db "MAIN", 0
db "MICRO", 0
db "MODELE", 0
db "MUSIQUE", 0
db "NOM", 0
db "NOMBRE", 0
db "ORCHESTRE", 0
db "ORDINATEUR", 0
db "PHOTO", 0
db "POINT", 0
db "POSTER", 0
db "POUCE", 0
db "PRENOM", 0
db "QUESTION", 0
db "RADIO", 0
db "SENS", 0
db "TAMBOUR", 0
db "TELECOMMANDE", 0
db "TELEPHONE", 0
db "TELEVISION", 0
db "TRAIT", 0
db "TROMPETTE", 0
db "VOIX", 0
db "XYLOPHONE", 0
db "ZERO", 0
db "CHANTER", 0
db "CHERCHER", 0
db "CHOISIR", 0
db "CHUCHOTER", 0
db "COLLER", 0
db "COLORIER", 0
db "COMMENCER", 0
db "COMPARER", 0
db "COMPTER", 0
db "CONSTRUIRE", 0
db "CONTINUER", 0
db "COPIER", 0
db "COUPER", 0
db "DECHIRER", 0
db "DECOLLER", 0
db "DECORER", 0
db "DECOUPER", 0
db "DEMOLIR", 0
db "DESSINER", 0
db "DIRE", 0
db "DISCUTER", 0
db "ECOUTER", 0
db "ECRIRE", 0
db "EFFACER", 0
db "ENTENDRE", 0
db "ENTOURER", 0
db "ENVOYER", 0
db "FAIRE", 0
db "FINIR", 0
db "FOUILLER", 0
db "GOUTER", 0
db "IMITER", 0
db "LAISSER", 0
db "LIRE", 0
db "METTRE", 0
db "MONTRER", 0
db "OUVRIR", 0
db "PARLER", 0
db "PEINDRE", 0
db "PLIER", 0
db "POSER", 0
db "PRENDRE", 0
db "PREPARER", 0
db "RANGER", 0
db "RECITER", 0
db "RECOMMENCER", 0
db "REGARDER", 0
db "REMETTRE", 0
db "REPETER", 0
db "REPONDRE", 0
db "SENTIR", 0
db "SOULIGNER", 0
db "TAILLER", 0
db "TENIR", 0
db "TERMINER", 0
db "TOUCHER", 0
db "TRAVAILLER", 0
db "TRIER", 0
db "AMI", 0
db "ATTENTION", 0
db "CAMARADE", 0
db "COLERE", 0
db "COPAIN", 0
db "COQUIN", 0
db "DAME", 0
db "DIRECTEUR", 0
db "DIRECTRICE", 0
db "DROIT", 0
db "EFFORT", 0
db "ELEVE", 0
db "ENFANT", 0
db "FATIGUE", 0
db "FAUTE", 0
db "FILLE", 0
db "GARCON", 0
db "GARDIEN", 0
db "MADAME", 0
db "MAITRE", 0
db "MAITRESSE", 0
db "MENSONGE", 0
db "ORDRE", 0
db "PERSONNE", 0
db "RETARD", 0
db "JOUEUR", 0
db "SOURIRE", 0
db "TRAVAIL", 0
db "AIDER", 0
db "DEFENDRE", 0
db "DESOBEIR", 0
db "DISTRIBUER", 0
db "ECHANGER", 0
db "EXPLIQUER", 0
db "GRONDER", 0
db "OBEIR", 0
db "OBLIGER", 0
db "PARTAGER", 0
db "PRETER", 0
db "PRIVER", 0
db "PROMETTRE", 0
db "PROGRES", 0
db "PROGRESSER", 0
db "PUNIR", 0
db "QUITTER", 0
db "RACONTER", 0
db "EXPLIQUER", 0
db "REFUSER", 0
db "SEPARER", 0
db "BLOND", 0
db "BRUN", 0
db "CALME", 0
db "CURIEUX", 0
db "DIFFERENT", 0
db "DOUX", 0
db "ENERVER", 0
db "GENTIL", 0
db "GRAND", 0
db "HANDICAPE", 0
db "INSEPARABLE", 0
db "JALOUX", 0
db "MOYEN", 0
db "MUET", 0
db "NOIR", 0
db "NOUVEAU", 0
db "PETIT", 0
db "POLI", 0
db "PROPRE", 0
db "ROUX", 0
db "SAGE", 0
db "SALE", 0
db "SERIEUX", 0
db "SOURD", 0
db "TRANQUILLE", 0
db "ARROSOIR", 0
db "ASSIETTE", 0
db "BALLE", 0
db "BATEAU", 0
db "BOITE", 0
db "BOUCHON", 0
db "BOUTEILLE", 0
db "BULLES", 0
db "CANARD", 0
db "CASSEROLE", 0
db "CUILLERE", 0
db "CUVETTE", 0
db "DOUCHE", 0
db "ENTONNOIR", 0
db "GOUTTES", 0
db "LITRE", 0
db "MOULIN", 0
db "PLUIE", 0
db "POISSON", 0
db "PONT", 0
db "POT", 0
db "ROUE", 0
db "SAC", 0
db "PLASTIQUE", 0
db "SALADIER", 0
db "SEAU", 0
db "TABLIER", 0
db "TASSE", 0
db "TROUS", 0
db "VERRE", 0
db "AGITER", 0
db "AMUSER", 0
db "ARROSER", 0
db "ATTRAPER", 0
db "AVANCER", 0
db "BAIGNER", 0
db "BARBOTER", 0
db "BOUCHER", 0
db "BOUGER", 0
db "DEBORDER", 0
db "DOUCHER", 0
db "ECLABOUSSER", 0
db "ESSUYER", 0
db "ENVOYER", 0
db "COULER", 0
db "PARTIR", 0
db "FLOTTER", 0
db "GONFLER", 0
db "INONDER", 0
db "JOUER", 0
db "LAVER", 0
db "MELANGER", 0
db "MOUILLER", 0
db "NAGER", 0
db "PLEUVOIR", 0
db "PLONGER", 0
db "POUSSER", 0
db "POUVOIR", 0
db "PRESSER", 0
db "RECEVOIR", 0
db "REMPLIR", 0
db "RENVERSER", 0
db "SECHER", 0
db "SERRER", 0
db "SOUFFLER", 0
db "TIRER", 0
db "TOURNER", 0
db "TREMPER", 0
db "VERSER", 0
db "VIDER", 0
db "VOULOIR", 0
db "AMUSANT", 0
db "CHAUD", 0
db "FROID", 0
db "HUMIDE", 0
db "INTERESSANT", 0
db "MOUILLE", 0
db "SEC", 0
db "TRANSPARENT", 0
db "MOITIE", 0
db "AUTANT", 0
db "BEAUCOUP", 0
db "ENCORE", 0
db "MOINS", 0
db "PEU", 0
db "PLUS", 0
db "TROP", 0
db "ANORAK", 0
db "ARC", 0
db "BAGAGE", 0
db "BAGUETTE", 0
db "BARBE", 0
db "BONNET", 0
db "BOTTE", 0
db "BOUTON", 0
db "BRETELLE", 0
db "CAGOULE", 0
db "CASQUE", 0
db "CASQUETTE", 0
db "CEINTURE", 0
db "CHAPEAU", 0
db "CHAUSSETTE", 0
db "CHAUSSON", 0
db "CHAUSSURE", 0
db "CHEMISE", 0
db "CIGARETTE", 0
db "COL", 0
db "COLLANT", 0
db "COURONNE", 0
db "CRAVATE", 0
db "CULOTTE", 0
db "ECHARPE", 0
db "EPEE", 0
db "FEE", 0
db "FLECHE", 0
db "FUSIL", 0
db "GANT", 0
db "HABIT", 0
db "JEAN", 0
db "JUPE", 0
db "LACET", 0
db "LAINE", 0
db "LINGE", 0
db "LUNETTES", 0
db "MAGICIEN", 0
db "MAGIE", 0
db "MAILLOT", 0
db "MANCHE", 0
db "MANTEAU", 0
db "MOUCHOIR", 0
db "MOUFLE", 0
db "NOEUD", 0
db "PAIRE", 0
db "PANTALON", 0
db "PIED", 0
db "POCHE", 0
db "PRINCE", 0
db "PYJAMA", 0
db "REINE", 0
db "ROBE", 0
db "ROI", 0
db "RUBAN", 0
db "SEMELLE", 0
db "SOLDAT", 0
db "SOCIERE", 0
db "TACHE", 0
db "TAILLE", 0
db "TALON", 0
db "TISSU", 0
db "TRICOT", 0
db "UNIFORME", 0
db "VALISE", 0
db "VESTE", 0
db "VETEMENT", 0
db "CHANGER", 0
db "CHAUSSER", 0
db "COUVRIR", 0
db "DEGUISER", 0
db "DESHABILLER", 0
db "ENLEVER", 0
db "HABILLER", 0
db "LACER", 0
db "PORTER", 0
db "RESSEMBLER", 0
db "CLAIR", 0
db "COURT", 0
db "ETROIT", 0
db "FONCE", 0
db "JOLI", 0
db "LARGE", 0
db "LONG", 0
db "MULTICOLORE", 0
db "NU", 0
db "USE", 0
db "BIEN", 0
db "MAL", 0
db "MIEUX", 0
db "PRESQUE", 0
db "AIGUILLE", 0
db "AMPOULE", 0
db "AVION", 0
db "BOIS", 0
db "BOUT", 0
db "BRICOLAGE", 0
db "BRUIT", 0
db "CABANE", 0
db "CARTON", 0
db "CLOU", 0
db "COLLE", 0
db "CROCHET", 0
db "ELASTIQUE", 0
db "FICELLE", 0
db "FIL", 0
db "MARIONNETTE", 0
db "MARTEAU", 0
db "METAL", 0
db "METRE", 0
db "MORCEAU", 0
db "MOTEUR", 0
db "OBJET", 0
db "OUTIL", 0
db "PEINTURE", 0
db "PINCEAU", 0
db "PLANCHE", 0
db "PLATRE", 0
db "SCIE", 0
db "TOURNEVIS", 0
db "VIS", 0
db "VOITURE", 0
db "ARRACHER", 0
db "ATTACHER", 0
db "CASSER", 0
db "COUDRE", 0
db "DETRUIRE", 0
db "ECORCHER", 0
db "ENFILER", 0
db "ENFONCER", 0
db "FABRIQUER", 0
db "MESURER", 0
db "PERCER", 0
db "PINCER", 0
db "REPARER", 0
db "REUSSIR", 0
db "SERVIR", 0
db "TAPER", 0
db "TROUER", 0
db "TROUVER", 0
db "ADROIT", 0
db "DIFFICILE", 0
db "DUR", 0
db "FACILE", 0
db "LISSE", 0
db "MALADROIT", 0
db "POINTU", 0
db "TORDU", 0
db "ACCIDENT", 0
db "AEROPORT", 0
db "CAMION", 0
db "ENGIN", 0
db "FEU", 0
db "FREIN", 0
db "FUSEE", 0
db "GARAGE", 0
db "GARE", 0
db "GRUE", 0
db "HELICOPTERE", 0
db "MOTO", 0
db "PANNE", 0
db "PARKING", 0
db "PILOTE", 0
db "PNEU", 0
db "QUAI", 0
db "TRAIN", 0
db "VIRAGE", 0
db "VITESSE", 0
db "VOYAGE", 0
db "WAGON", 0
db "ZIGZAG", 0
db "ARRETER", 0
db "ATTERRIR", 0
db "BOUDER", 0
db "CHARGER", 0
db "CONDUIRE", 0
db "DEMARRER", 0
db "DISPARAITRE", 0
db "DONNER", 0
db "ECRASER", 0
db "ENVOLER", 0
db "GARDER", 0
db "GARER", 0
db "MANQUER", 0
db "PARTIR", 0
db "POSER", 0
db "RECULER", 0
db "ROULER", 0
db "TENDRE", 0
db "TRANSPORTER", 0
db "VOLER", 0
db "ABIME", 0
db "ANCIEN", 0
db "BLANC", 0
db "BLEU", 0
db "CASSE", 0
db "CINQ", 0
db "DERNIER", 0
db "DEUX", 0
db "DEUXIEME", 0
db "DIX", 0
db "GRIS", 0
db "GROS", 0
db "HUIT", 0
db "JAUNE", 0
db "MEME", 0
db "NEUF", 0
db "PAREIL", 0
db "PREMIER", 0
db "QUATRE", 0
db "ROUGE", 0
db "SEPT", 0
db "SEUL", 0
db "SIX", 0
db "SOLIDE", 0
db "TROIS", 0
db "TROISIEME", 0
db "UN", 0
db "VERT", 0
db "DESSUS", 0
db "AUTOUR", 0
db "VITE", 0
db "VERS", 0
db "ACROBATE", 0
db "ARRET", 0
db "ARRIERE", 0
db "BARRE", 0
db "BARREAU", 0
db "BORD", 0
db "BRAS", 0
db "CERCEAU", 0
db "CHAISE", 0
db "CHEVILLE", 0
db "CHUTE", 0
db "COEUR", 0
db "CORDE", 0
db "CORPS", 0
db "COTE", 0
db "COU", 0
db "COUDE", 0
db "CUISSE", 0
db "DANGER", 0
db "DOIGTS", 0
db "DOS", 0
db "ECHASSES", 0
db "ECHELLE", 0
db "EPAULE", 0
db "EQUIPE", 0
db "ESCABEAU", 0
db "FESSE", 0
db "FILET", 0
db "FOND", 0
db "GENOU", 0
db "GYMNASTIQUE", 0
db "HANCHE", 0
db "JAMBE", 0
db "JEU", 0
db "MAINS", 0
db "MILIEU", 0
db "MONTAGNE", 0
db "MUR", 0
db "ESCALADE", 0
db "MUSCLE", 0
db "NUMERO", 0
db "ONGLE", 0
db "PARCOURS", 0
db "PAS", 0
db "PASSERELLE", 0
db "PENTE", 0
db "PEUR", 0
db "PIED", 0
db "PLONGEOIR", 0
db "POIGNET", 0
db "POING", 0
db "PONT", 0
db "SIGNE", 0
db "SINGE", 0
db "POUTRE", 0
db "EQUILIBRE", 0
db "PRISE", 0
db "RIVIERE", 0
db "CROCODILE", 0
db "ROULADE", 0
db "PIROUETTE", 0
db "SAUT", 0
db "SERPENT", 0
db "SPORT", 0
db "SUIVANT", 0
db "TETE", 0
db "TOBOGGAN", 0
db "TOUR", 0
db "TRAMPOLINE", 0
db "TUNNEL", 0
db "VENTRE", 0
db "ACCROCHER", 0
db "APPUYER", 0
db "ARRIVER", 0
db "BAISSER", 0
db "BALANCER", 0
db "BONDIR", 0
db "BOUSCULER", 0
db "COGNER", 0
db "COURIR", 0
db "DANSER", 0
db "DEPASSER", 0
db "DESCENDRE", 0
db "ECARTER", 0
db "ESCALADER", 0
db "GAGNER", 0
db "GENER", 0
db "GLISSER", 0
db "GRIMPER", 0
db "MARCHER", 0
db "PATTES", 0
db "DEBOUT", 0
db "MONTER", 0
db "MONTRER", 0
db "PENCHER", 0
db "PERCHER", 0
db "PERDRE", 0
db "RAMPER", 0
db "RATER", 0
db "REMPLACER", 0
db "RESPIRER", 0
db "RETOURNER", 0
db "REVENIR", 0
db "SAUTER", 0
db "SOULEVER", 0
db "SUIVRE", 0
db "TOMBER", 0
db "TRANSPIRER", 0
db "TRAVERSER", 0
db "DANGEUREUX", 0
db "EPAIS", 0
db "FORT", 0
db "GROUPE", 0
db "IMMOBILE", 0
db "ROND", 0
db "SERRE", 0
db "SOUPLE", 0
db "ENSEMBLE", 0
db "ICI", 0
db "JAMAIS", 0
db "TOUJOURS", 0
db "SOUVENT", 0
db "BAGARRE", 0
db "BALANCOIRE", 0
db "BALLON", 0
db "BANDE", 0
db "BICYCLETTE", 0
db "BILLE", 0
db "CAGE", 0
db "ECUREUIL", 0
db "CERF", 0
db "VOLANT", 0
db "CHATEAU", 0
db "COUP", 0
db "COUR", 0
db "COURSE", 0
db "ECHASSE", 0
db "FLAQUE", 0
db "EAU", 0
db "PAIX", 0
db "PARDON", 0
db "PARTIE", 0
db "PEDALE", 0
db "PELLE", 0
db "POMPE", 0
db "PREAU", 0
db "RAQUETTE", 0
db "RAYON", 0
db "RECREATION", 0
db "SABLE", 0
db "SIFFLET", 0
db "SIGNE", 0
db "TAS", 0
db "TRICYCLE", 0
db "TUYAU", 0
db "VELO", 0
db "FILE", 0
db "RANG", 0
db "BAGARRER", 0
db "BATTRE", 0
db "CACHER", 0
db "CRACHER", 0
db "CREUSER", 0
db "CRIER", 0
db "DEGONFLER", 0
db "DISPUTE", 0
db "EMPECHER", 0
db "GALOPER", 0
db "HURLER", 0
db "JONGLER", 0
db "LANCER", 0
db "PEDALER", 0
db "PLAINDRE", 0
db "PLEURER", 0
db "POURSUIVRE", 0
db "PROTEGER", 0
db "SAIGNER", 0
db "SALIR", 0
db "SIFFLER", 0
db "SURVEILLER", 0
db "TRAINER", 0
db "TROUVER", 0
db "FOU", 0
db "MECHANT", 0



max_word_length: db 12
word_found: db "____________", 0
word_to_find: dw 0

designs:
dw 14
dw 96
dw 194
dw 300
dw 406
dw 513
dw 627



db "       +-------+", 10
db "       |", 10
db "       |", 10
db "       |", 10
db "       |", 10
db "       |", 10
db "    ==============", 10
db 0

db "       +-------+", 10
db "       |       |", 10
db "       |       O", 10
db "       |", 10
db "       |", 10
db "       |", 10
db "    ==============", 10
db 0

db "       +-------+", 10
db "       |       |", 10
db "       |       O", 10
db "       |       |", 10
db "       |", 10
db "       |", 10
db "    ==============", 10
db 0

db "       +-------+", 10
db "       |       |", 10
db "       |       O", 10
db "       |      -|", 10
db "       |", 10
db "       |", 10
db "    ==============", 10
db 0

db "       +-------+", 10
db "       |       |", 10
db "       |       O", 10
db "       |      -|-", 10
db "       |", 10
db "       |", 10
db "    ==============", 10
db 0

db "       +-------+", 10
db "       |       |", 10
db "       |       O", 10
db "       |      -|-", 10
db "       |      |", 10
db "       |", 10
db "    ==============", 10
db 0

db "       +-------+", 10
db "       |       |", 10
db "       |       O", 10
db "       |      -|-", 10
db "       |      | |", 10
db "       |", 10
db "    ==============", 10
db 0



times 230 db 0