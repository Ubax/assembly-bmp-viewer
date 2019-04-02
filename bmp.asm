;-------------------------------------------------------
;----------------------- POINT -------------------------
;-------------------------------------------------------
point_x		dw	?
point_y		dw	?
point_k		db	?
 
draw_point:
	mov	ax,0a000h  ; adres segmentu pamieci w trybie graficznym
	mov	es,ax
	mov	ax,cs:[point_y]
	mov	bx,320
	mul	bx  ; dx:ax = ax * bx  ->   ax= y*320
	add	ax, cs:[point_x]     ;ax - y*320 +x
	mov	bx,ax
	mov	al,cs:[point_k]
	mov	es:[bx],al
draw_point_end:
	ret
;-------------------------------------------------------

bmp_open_file:
	call change_ds_to_data
	mov	dx,offset fileName
	mov	al,0  ;tylko do odczytu
	mov	ah,3dh   ;otworz
	int	21h ; ax <- uchwyt
	
	jb bmp_open_file_error
	
	call change_ds_to_bitmap
	mov	word ptr ds:[file],ax
	
	mov ax,0
	ret
bmp_open_file_error:
	mov ax,1
	ret
	
bmp_read_header:
	call change_ds_to_bitmap
	
	mov	dx,offset bmp_header
	mov	bx,word ptr ds:[file]	
	mov	cx,14  ;ilosc bajtow do czytania
	mov	ah,3fh
	int	21h
	mov ax, word ptr ds:[bmp_header] ;wczytanie na raz BM
	cmp al, 'B'
	jne bmp_read_header_error
	cmp ah, 'M'
	jne bmp_read_header_error
	
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
	
	mov ax, 0
	ret
bmp_read_header_error:
	mov ax,1
	ret
	
clear_display:
	xor di,di
	clear_display_rows_loop_beg:
		xor si,si
		clear_display_cols_loop_beg:
			mov	word ptr cs:[point_x], si
			mov	word ptr cs:[point_y], di
			mov byte ptr cs:[point_k], 0Fh
			
			call draw_point
			inc si
			cmp si, 320
			jl clear_display_cols_loop_beg
		inc di
		cmp di, 200
		jl clear_display_rows_loop_beg
	ret

bmp_set_palette:
	push si
	mov si, 0
	xor bx,bx
	xor dx,dx
	xor si,si
	mov cx, 7
	bmp_set_palette_r_loop_beg:
		push cx
		xor di,di
		mov cx, 3
		bmp_set_palette_g_loop_beg:
			push cx
			mov cx, 7
			xor si,si
			bmp_set_palette_b_loop_beg:
				push cx
				mov dx, 03c8h	;RGB write port
				mov ax, 
				mov al, 
				out dx, al
				inc dx
				
				mov ax, bx
				out dx, al
		
				mov ax, di
				out dx, al
		
				mov ax, si
				out dx, al
				pop cx
				add si, 9
				loop bmp_set_palette_b_loop_beg
			pop cx
			add di, 21
			loop bmp_set_palette_g_loop_beg
		pop cx
		add bx, 9
		loop bmp_set_palette_r_loop_beg
	pop si
	ret

;-- ARGUMENTS:
;-- dl - zoom in
;-- dh - zoom out (only if al=0)
;-- bl - x
;-- bh - y	
bmp_load_pixel_map:
	x		db	0
	y		db 	0
	mov ax, seg x
	mov ds, ax
	mov byte ptr ds:[x], bl
	mov byte ptr ds:[y], bh
	
	call change_ds_to_bitmap
	;-- si - cols iterator
	;-- di - rows iterator
	
	call clear_display
	
	mov cx, 200
	bmp_load_pixel_map_rows_loop_beg:
		push cx
		mov di,cx
		xor si,si
		bmp_load_pixel_map_cols_loop_beg:
			mov	dx,offset bmp_bufor
			mov	bx,word ptr ds:[file]	
			mov	cx,3  ;ilosc bajtow do czytania
			mov	ah,3fh
			int	21h
					
			;---- X
			xor dx,dx
			;mov dl, byte ptr ds:[x]
			add dx, si
			cmp dx, 320
			jge bmp_load_pixel_map_cols_loop_end
			mov	word ptr cs:[point_x], dx
			
			mov	word ptr cs:[point_y], di
			
			;---- COLOR
			call bmp_load_color_from_bufor
			mov bl, 11100000b
			mov byte ptr cs:[point_k], bl
			call draw_point
			
			inc si
			mov ax, word ptr ds:[bmp_width]
			cmp si, ax
			jl bmp_load_pixel_map_cols_loop_beg
		bmp_load_pixel_map_cols_loop_end:
		;inc di
		;mov ax, word ptr ds:[bmp_height]
		;cmp di, ax
		pop cx
		loop bmp_load_pixel_map_rows_loop_beg
		;jl bmp_load_pixel_map_rows_loop_beg
bmp_load_pixel_map_end:
	mov	ax, 0
	ret
	
bmp_load_color_from_bufor:
	push dx
	push cx
	pushf
	
	xor bx,bx
	xor dx,dx
	mov bl, byte ptr ds:[bmp_bufor]
	mov cx, 5
	shr bx, cl
	shl bx, cl
	add dx, bx
	mov bl, byte ptr ds:[bmp_bufor+1]
	mov cx, 6
	shr bx, cl
	mov cx, 3
	shl bx, cl
	add dx, bx
	mov bl, byte ptr ds:[bmp_bufor+2]
	mov cx, 5
	shr bx, cl
	add dx, bx
	mov dx,bx
	
	popf
	pop cx
	pop dx
	ret
bmp_close_file:
	call change_ds_to_bitmap
	mov	bx,word ptr ds:[file]
	mov	ah,3eh  ; zamknij
	int	21h	
	ret