;;;;; test vs cmp
;;;;; rozkazy lancuchowe
; DS:SI - source
; ES:DI - destinstion
; CX	- repetitions
; REP, REPZ - powtarzaj dopoki nie rowne, REPNZ - powtarzaj dopoki rowne
; MOVSB, MOVSW - przesyla do celu
; LOADSB, LOADSW - przesyla do akumulatora
; STOSB, STOSW - z akumulatora do pamieci
; SCASB, SCASW - Porownanie bajtu lub bliku danych z zawartoscia akumulatora (ax)
; CMP

data1 segment

NO_FILE_NAME_MSG	db	"No file name$"
WRONG_HEADER_MSG	db	"Wrong bmp header$"
TOO_BIG_IMAGE_MSG	db	"The image is too big. Max size: 320x200$"
FILE_OPENING_MSG	db	"File opening error. Probably file doesn't exist$"

fileName        	db	"test.bmp$";100 dup(0)

file				dw	?
bmp_header			db	15 dup(0)
bmp_dib				db	120 dup('$')
bmp_width			dw	0
bmp_height			dw 	0
bmp_bufor			db	2048 dup(0)

LEFT_KEY			equ 75
RIGHT_KEY			equ 77
UP_KEY				equ 72
DOWN_KEY			equ 80
ESC_KEY				equ 1
ZOOMIN_KEY			equ 0Dh
ZOOMOUT_KEY			equ	0Ch
MONO_PAL_KEY		equ	03h
REG_PAL_KEY			equ	02h

data1 ends

code1	segment
start:	
    mov	ax,seg top1
	mov	ss,ax
	mov	sp,offset top1  ; inicjowanie stosu
	
	mov ax, seg data1
	mov ds, ax
 
open_file:
	;call get_file_name	
	mov	dx,offset fileName
	mov	al,0  ;tylko do odczytu
	mov	ah,3dh   ;otworz
	int	21h ; ax <- uchwyt
	
	jb file_opening

	mov	word ptr ds:[file],ax
		
read_header:
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

	
	mov ax, word ptr ds:[bmp_width]
	
	mov ax, word ptr ds:[bmp_height]	

	
change_to_vga:
	mov	al,13h   ;tryb graficzny 320 x 200
	mov	ah,0 ; polecenie zmiany trybu
	int	10h
	
	call set_pallete
		
show_bmp:	
set_variables:
	mov ax, word ptr cs:[zoom_in]
	mov word ptr cs:[del_zoom_in], ax
	mov word ptr cs:[del_zoom_out], 1
	cmp word ptr cs:[zoom_in], 1
	jl set_del_zoom_in
	jmp after_set_del_zoom_in
set_del_zoom_in:
	mov word ptr cs:[del_zoom_in], 1
	neg ax
	inc ax
	mov word ptr cs:[del_zoom_out], ax
after_set_del_zoom_in:

	mov word ptr cs:[del_x], 0
	mov ax, word ptr cs:[offset_x]
	cmp ax, 0
	jg set_del_x
	jmp after_set_del_x
set_del_x:
	mov word ptr cs:[del_x], ax
after_set_del_x:

	mov word ptr cs:[del_y], 0
	mov ax, word ptr ds:[bmp_height]
	cmp ax, 200
	jl after_set_del_y 
	mov ax, word ptr cs:[offset_y]
	cmp ax, 0
	jl set_del_y
	mov ax, word ptr ds:[bmp_height]
	sub ax, 200
	sub ax, word ptr cs:[offset_y]
	cmp ax, 0
	jl after_set_del_y
	mov word ptr cs:[del_y], ax
	jmp after_set_del_y
set_del_y:
	mov ax, word ptr ds:[bmp_height]
	sub ax, 200
	mov word ptr cs:[del_y], ax
	mov ax, word ptr cs:[del_y]
	cmp ax, 0
	jge after_set_del_y
	mov word ptr cs:[del_y], 0
after_set_del_y:
move_after_bottom_rows:
	mov bx, word ptr cs:[del_y]
	mov ax, word ptr ds:[bmp_header+10]
	mov word ptr cs:[del_file_pos], ax
	call move_absolute_file
	mov ax, word ptr ds:[bmp_width]
	;add ax, word ptr cs:[rem]
	mov bx, word ptr cs:[del_y]
	mul bx
	mov cx, dx
	mov bx, word ptr cs:[del_zoom_in]
	mul bx
	push ax
	mov ax, cx
	mul bx
	add dx, ax
	mov cx, dx
	pop dx
	call move_relative_file
	
	
	mov al, 225
	;call clear_display
	
	mov word ptr cs:[y_max], 199
	mov ax, word ptr ds:[bmp_height]
	cmp ax, 199
	jl set_y_max
	jmp after_set_y_max
set_y_max:
	mov word ptr cs:[y_max], ax
after_set_y_max:
	
	mov word ptr cs:[x_max], 320
	mov ax, word ptr ds:[bmp_width]
	cmp ax, 320
	jl set_x_max
	jmp after_set_x_max
set_x_max:
	mov word ptr cs:[x_max], ax
after_set_x_max:
	mov word ptr cs:[y_it], 0
	mov ax, word ptr cs:[y_max]
	mov word ptr cs:[cur_y], ax 
	y_loop:
		mov word ptr cs:[cur_x], 0
		mov word ptr cs:[x_it], 0
		
		mov	dx,offset bmp_bufor
		mov	bx,word ptr ds:[file]	
		mov	cx,word ptr ds:[bmp_width]
		mov	ah,3fh
		int	21h
		x_loop:
			mov si, word ptr cs:[cur_x]
			add si, word ptr cs:[del_x]
			mov ax, word ptr cs:[del_zoom_out]
			mul si
			mov si, ax
			mov ax, word ptr ds:[bmp_bufor + si]
			mov byte ptr cs:[point_k], al
			
			mov bx, word ptr cs:[cur_y]
			mov ax, word ptr cs:[del_zoom_in]
			mul bx
			mov word ptr cs:[point_y], ax
			
			mov ax, word ptr cs:[del_zoom_in]
			mov word ptr cs:[zoom_y_it], ax
			y_zoom_loop:
				mov ax, word ptr cs:[point_y]
				cmp ax, 200
				jge after_y_zoom_loop
				
				mov ax, word ptr cs:[del_zoom_in]
				mov word ptr cs:[zoom_x_it], ax
				mov bx, word ptr cs:[cur_x]
				mov ax, word ptr cs:[del_zoom_in]
				mul bx
				mov word ptr cs:[point_x], ax
				x_zoom_loop:
					mov ax, word ptr cs:[point_x]
					cmp ax, 320
					jge after_x_zoom_loop
					mov ax, word ptr cs:[point_x]
					cmp ax, 0
					jl after_draw_point
					call draw_point
					after_draw_point:
					inc word ptr cs:[point_x]
					
					dec word ptr cs:[zoom_x_it]
					mov ax, word ptr cs:[zoom_x_it]
					cmp ax, 0
					jg x_zoom_loop
				after_x_zoom_loop:
				inc word ptr cs:[point_y]
				dec word ptr cs:[zoom_y_it]
				mov ax, word ptr cs:[zoom_y_it]
				cmp ax, 0
				jg y_zoom_loop
			after_y_zoom_loop:
			inc word ptr cs:[cur_x]
			mov ax, word ptr cs:[cur_x]
			mov bx, word ptr cs:[x_max]
			cmp ax, 320
			jl x_loop
		dec word ptr cs:[cur_y]
		mov ax, word ptr cs:[cur_y]
		cmp ax, 0
		jge y_loop
	end_pixel_loop:
	jmp key_loop
zoom_in_show_loop:
	
right_key_pressed:
	add word ptr cs:[offset_x], 10
	jmp show_bmp
left_key_pressed:
	sub word ptr cs:[offset_x], 10
	jmp show_bmp
up_key_pressed:
	sub word ptr cs:[offset_y], 5
	jmp show_bmp
down_key_pressed:
	add word ptr cs:[offset_y], 5
	jmp show_bmp
zoomin_key_pressed:
	inc word ptr cs:[zoom_in]
	jmp show_bmp
zoomout_key_pressed:
	dec word ptr cs:[zoom_in]
	jmp show_bmp
mono_pal_key_pressed:
	call set_mono_pallete
	jmp show_bmp
reg_pal_key_pressed:
	call set_pallete
	jmp show_bmp
inv_pal_key_pressed:
	call set_inverted_pallete
	jmp show_bmp
key_loop:
	in al, 60h		;get key scancode
	cmp al, ESC_KEY		
	je change_to_text
	cmp al, LEFT_KEY		
	je left_key_pressed
	cmp al, RIGHT_KEY		
	je right_key_pressed
	cmp al, UP_KEY			
	je up_key_pressed
	cmp al, DOWN_KEY		
	je down_key_pressed
	cmp al, ZOOMIN_KEY		
	je zoomin_key_pressed
	cmp al, ZOOMOUT_KEY		
	je zoomout_key_pressed
	cmp al, REG_PAL_KEY
	je reg_pal_key_pressed
	cmp al, MONO_PAL_KEY
	je mono_pal_key_pressed
	cmp al, MONO_PAL_KEY+1
	je inv_pal_key_pressed
	jmp key_loop
	
change_to_text:
	mov	al,3
	mov	ah,0 ; polecenie zmiany trybu
	int	10h
	
close_file:
	mov	bx,word ptr ds:[file]
	mov	ah,3eh  ; zamknij
	int	21h	

end1:
	mov	ax,04c00h  ; zakoncz program
	int	21h

;-------------------------------------------------------
;--------------------- VARIABLES -----------------------
;-------------------------------------------------------	
r_iterator		dw	0
g_iterator		dw	0
b_iterator		dw	0
r				db	0
g				db	0
b				db	0
a				db	0
offset_x		dw	0
offset_y		dw 	0
zoom_in			dw 	1
del_zoom_in		dw	1
del_zoom_out	dw	1
cur_x			dw	0
cur_y			dw 	0
del_x			dw	0
del_y			dw 	0
rem				dw	0
del_file_pos	dw	0
zoom_x_it		dw	0
zoom_y_it		dw	0
x_it			dw	0
y_it			dw	0
x_max			dw	0
y_max			dw 	0


;-------------------------------------------------------
;----------------------- POINT -------------------------
;-------------------------------------------------------
point_x		dw	?
point_y		dw	?
point_k		db	?
 
draw_point:
	push ax
	push bx
	push es
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
	pop es
	pop bx
	pop ax
	ret
;-------------------------------------------------------
	
;-------------------------------------------------------
;----------------------- ERRORS ------------------------
;-------------------------------------------------------
wrong_header:
	mov dx, offset WRONG_HEADER_MSG
	call my_println
	jmp end1
	
too_big_image:
	mov dx, offset TOO_BIG_IMAGE_MSG
	call my_println
	jmp end1
	
file_opening:
	mov dx, offset FILE_OPENING_MSG
	call my_println
	jmp end1


;-------------------------------------------------------
;--------------------- FUNCTIONS -----------------------
;-------------------------------------------------------

; al - color
clear_display:
	xor di,di
	clear_display_rows_loop_beg:
		xor si,si
		clear_display_cols_loop_beg:
			mov	word ptr cs:[point_x], si
			mov	word ptr cs:[point_y], di
			mov byte ptr cs:[point_k], al
			
			call draw_point
			inc si
			cmp si, 320
			jl clear_display_cols_loop_beg
		inc di
		cmp di, 200
		jl clear_display_rows_loop_beg
	ret

move_absolute_file:
	push bx
	push cx
	push dx
	push ax
	mov bx, word ptr ds:[file]
    xor cx, cx
	mov dx, word ptr cs:[del_file_pos]
    mov ax, 4200h
    int 21h
	pop ax
	pop dx
	pop cx
	pop bx
	ret
	
move_relative_file:
	push bx
	push ax
	mov bx, word ptr ds:[file]
    mov ax, 4201h
    int 21h
	pop ax
	pop bx
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
include io.asm
;include show_bmp.asm

code1	ends
 
 
stos1	segment STACK
	dw	200 dup(?)   ;200 x slowo o dow. wartosci
top1	dw	?
stos1	ends
 
end start
