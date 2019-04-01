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
	
bmp_load_pixel_map:
	call change_ds_to_bitmap
	
	mov	dx,offset buf
	
bmp_close_file:
	call change_ds_to_bitmap
	mov	bx,word ptr ds:[file]
	mov	ah,3eh  ; zamknij
	int	21h	
	ret