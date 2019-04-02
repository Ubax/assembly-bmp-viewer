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

data1 ends

code1	segment
start:	
    mov	ax,seg top1
	mov	ss,ax
	mov	sp,offset top1  ; inicjowanie stosu
 
	;call get_file_name
	
	call bmp_open_file 
	cmp ax, 0
	jne file_opening
	
	call bmp_read_header
	cmp ax, 0
	jne wrong_header
	
	call change_ds_to_bitmap
	
	mov ax, word ptr ds:[bmp_width]
	;cmp ax, 320
	;jg too_big_image
	
	mov ax, word ptr ds:[bmp_height]
	;cmp ax, 200
	;jg too_big_image
	
	;Change mode to vga 320x200
	mov	al,13h   ;tryb graficzny 320 x 200
	mov	ah,0 ; polecenie zmiany trybu
	int	10h
	
	call bmp_set_palette
	
	mov bl, 50 ;x offset
	mov bh, 40 ;y offset
	call bmp_load_pixel_map
	
	;call bmp_show_pixel_map
	
	xor	ax,ax
	int	16h			;wait for key
	
	mov	al,3
	mov	ah,0 ; polecenie zmiany trybu
	int	10h
 
	call bmp_close_file
	
 
printing_args:
	call change_ds_to_bitmap
	mov	dx,offset bmp_dib
	mov	ah,9   ;wypisz na ekranie string ds:dx
	int	21h

end1:
	mov	ax,04c00h  ; zakoncz program
	int	21h
	
	
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
change_ds_to_bitmap:
	push ax
	mov ax, seg bmp_segment
	mov ds, ax
	pop ax
	ret
	
change_ds_to_data:
	push ax
	mov ax, seg data1
	mov ds, ax
	pop ax
	ret

include io.asm
include bmp.asm
;include show_bmp.asm

code1	ends
 
 
stos1	segment STACK
	dw	200 dup(?)   ;200 x slowo o dow. wartosci
top1	dw	?
stos1	ends

bmp_segment segment
	file				dw	?
	bmp_header			db	15 dup(0)
	bmp_dib				db	120 dup('$')
	bmp_width			dw	0
	bmp_height			dw 	0
	bmp_bufor			db	2048 dup(0)
bmp_segment ends
 
end start
