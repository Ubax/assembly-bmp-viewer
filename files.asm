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

fileName        	db	"abc.bmp$";100 dup(0)

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
	
set_pallete:
	mov dx, 3c8h	;RGB write port
	
	mov byte ptr cs:[r], 0
	mov byte ptr cs:[g], 0
	mov byte ptr cs:[b], 0
	
	mov si, 0
	mov cx, 8
	set_palette_r_loop:
		mov word ptr cs:[r_iterator], cx
		mov cx, 4
		set_palette_g_loop:
			mov word ptr cs:[g_iterator], cx
			mov cx, 8
			set_palette_b_loop:
				mov word ptr cs:[b_iterator], cx
				mov ax, si
				out dx, al
				inc dx
				mov al, byte ptr cs:[r]
				out dx, al
				mov al, byte ptr cs:[g]
				out dx, al
				mov al, byte ptr cs:[b]
				out dx, al
				dec dx
				inc si
				
				add byte ptr cs:[b], 9
				mov ax, word ptr cs:[b_iterator]
				mov cx, ax
				loop set_palette_b_loop
			add byte ptr cs:[g], 21
			mov ax, word ptr cs:[g_iterator]
			mov cx, ax
			loop set_palette_g_loop
		add byte ptr cs:[r], 9
		mov ax, word ptr cs:[r_iterator]
		mov cx, ax
		loop set_palette_r_loop
	mov al,255
	out dx, al
	inc dx
	mov al, 63
	out dx, al
	mov al, 63
	out dx, al
	mov al, 63
	out dx, al
	dec dx
	
show_bmp:
	mov al, 7
	call clear_display
	call show_bitmap
key_loop:
	in al, 60h		;get key scancode
	cmp al, ESC_KEY		
	je change_to_text
	cmp al, LEFT_KEY		
	je show_bmp
	cmp al, RIGHT_KEY		
	je show_bmp
	cmp al, UP_KEY			
	je show_bmp
	cmp al, DOWN_KEY		
	je show_bmp
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
offset_x		db	0
offset_y		db 	0

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

show_bitmap:	
	;-- si - cols iterator
	;-- di - rows iterator
	mov al, 255;
	call clear_display
	
	; pushf
	; push cx
	; push dx
	; push di
	; push si
	; pushf
	mov	bx,word ptr ds:[file]
	mov cx, 0
	mov dx,	54
	mov ax, 4200h
	int 21h
	mov cx, 100
	bmp_load_pixel_map_rows_loop_beg:
		push cx
		mov di,cx
		dec di
		mov cx, 100
		xor si,si
		bmp_load_pixel_map_cols_loop_beg:
			push cx
			mov	dx,offset bmp_bufor
			mov	bx,word ptr ds:[file]	
			mov	cx,3  ;ilosc bajtow do czytania
			mov	ah,3fh
			int	21h
					
			;---- X
			mov	word ptr cs:[point_x], si
			
			mov	word ptr cs:[point_y], di
			
			;---- COLOR
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
			
			mov byte ptr cs:[point_k], dl
			call draw_point
			
			inc si
			mov ax, word ptr ds:[bmp_width]
			cmp si, ax
			pop cx
			jge bmp_load_pixel_map_cols_loop_end
			loop bmp_load_pixel_map_cols_loop_beg
		bmp_load_pixel_map_cols_loop_end:
		pop cx
		loop bmp_load_pixel_map_rows_loop_beg
	; popf
	; push si
	; push di
	; push dx
	; push cx
	; popf		
	ret

include io.asm
;include show_bmp.asm

code1	ends
 
 
stos1	segment STACK
	dw	200 dup(?)   ;200 x slowo o dow. wartosci
top1	dw	?
stos1	ends
 
end start
