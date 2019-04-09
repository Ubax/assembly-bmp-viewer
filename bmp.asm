read_header:
	push dx
	push bx
	push cx
	push ax
	mov	dx,offset bmp_header
	mov	bx,word ptr ds:[file]	
	mov	cx,14  ;ilosc bajtow do czytania
	mov	ah,3fh
	int	21h
	
	mov ax, word ptr ds:[bmp_header] ;wczytanie na raz BM
	cmp al, 'B'
	jne wrong_header
	cmp ah, 'M'
	jne wrong_header
	
	mov	dx,offset bmp_dib
	mov	bx,word ptr ds:[file]	
	mov	cx,40  ;ilosc bajtow do czytania
	mov	ah,3fh
	int	21h
	
	mov al, byte ptr ds:[bmp_dib + 4]
	mov ah, byte ptr ds:[bmp_dib + 5]
	mov word ptr ds:[bmp_width], ax
	
	mov al, byte ptr ds:[bmp_dib + 8]
	mov ah, byte ptr ds:[bmp_dib + 9]
	mov word ptr ds:[bmp_height], ax
	pop ax
	pop cx
	pop bx
	pop dx
	ret
	
move_after_bottom_rows:
	push ax
	push bx
	push cx
	push dx
	mov ax, word ptr ds:[bmp_header+10]
	mov word ptr cs:[del_file_pos], ax
	call move_absolute_file
	mov ax, word ptr ds:[bmp_width]
	mov bx, word ptr cs:[del_y]
	mul bx
	mov cx, dx
	mov dx, ax
	call move_relative_file
	pop dx
	pop cx
	pop bx
	pop ax
	ret
	
set_pallete:
	mov word ptr cs:[del_file_pos], 54
	call move_absolute_file
	mov dx, 3c8h	;RGB write port
	
	xor si, si
	set_pallete_loop:
		mov	dx,offset bmp_bufor
		mov	bx,word ptr ds:[file]	
		mov	cx,4  ;bgra
		mov	ah,3fh
		int	21h
		mov dx, 3c8h
		mov ax, si
		out dx, al
		inc dx
		mov cx,2
		mov al, byte ptr ds:[bmp_bufor+2]
		shr al, cl
		out dx, al
		mov al, byte ptr ds:[bmp_bufor+1]
		shr al, cl
		out dx, al
		mov al, byte ptr ds:[bmp_bufor]
		shr al, cl
		out dx, al
		dec dx
		inc si
		cmp si, 256
		jl set_pallete_loop
		ret
		
set_mono_pallete:
	mov word ptr cs:[del_file_pos], 54
	call move_absolute_file
	mov dx, 3c8h	;RGB write port
	
	xor si, si
	set_mono_pallete_loop:
		mov	dx,offset bmp_bufor
		mov	bx,word ptr ds:[file]	
		mov	cx,4  ;bgra
		mov	ah,3fh
		int	21h
		mov dx, 3c8h
		mov ax, si
		out dx, al
		inc dx
		mov cx,2
		xor bx, bx
		mov al, byte ptr ds:[bmp_bufor+2]
		shr al, cl
		add bl, al
		mov al, byte ptr ds:[bmp_bufor+1]
		shr al, cl
		add bl, al
		mov al, byte ptr ds:[bmp_bufor]
		shr al, cl
		add bl, al
		mov al, bl
		mov bl, 3
		div bl
		out dx, al
		out dx, al
		out dx, al
		dec dx
		inc si
		cmp si, 256
		jl set_mono_pallete_loop
		ret

set_inverted_pallete:
	mov word ptr cs:[del_file_pos], 54
	call move_absolute_file
	mov dx, 3c8h	;RGB write port
	
	xor si, si
	set_inverted_pallete_loop:
		mov	dx,offset bmp_bufor
		mov	bx,word ptr ds:[file]	
		mov	cx,4  ;bgra
		mov	ah,3fh
		int	21h
		mov dx, 3c8h
		mov ax, si
		out dx, al
		inc dx
		mov cx,2
		xor bx, bx
		mov al, byte ptr ds:[bmp_bufor+2]
		shr al, cl
		mov bl, 63
		sub bl, al
		mov al, bl
		out dx, al
		mov al, byte ptr ds:[bmp_bufor+1]
		shr al, cl
		mov bl, 63
		sub bl, al
		mov al, bl
		out dx, al
		mov al, byte ptr ds:[bmp_bufor]
		shr al, cl
		mov bl, 63
		sub bl, al
		mov al, bl
		out dx, al
		
		dec dx
		inc si
		cmp si, 256
		jl set_inverted_pallete_loop
		ret
		
set_darker_pallete:
	mov word ptr cs:[del_file_pos], 54
	call move_absolute_file
	mov dx, 3c8h	;RGB write port
	
	xor si, si
	set_darker_pallete_loop:
		mov	dx,offset bmp_bufor
		mov	bx,word ptr ds:[file]	
		mov	cx,4  ;bgra
		mov	ah,3fh
		int	21h
		mov dx, 3c8h
		mov ax, si
		out dx, al
		inc dx
		mov cx,4
		xor bx, bx
		mov al, byte ptr ds:[bmp_bufor+2]
		shr al, cl
		out dx, al
		mov al, byte ptr ds:[bmp_bufor+1]
		shr al, cl
		out dx, al
		mov al, byte ptr ds:[bmp_bufor]
		shr al, cl
		out dx, al
		
		dec dx
		inc si
		cmp si, 256
		jl set_darker_pallete_loop
		ret