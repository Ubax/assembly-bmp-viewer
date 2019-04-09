_my_print:
    mov ah, 9h
    int 21h
	ret

my_print:
    mov ax, seg data1
	mov ds, ax
	call _my_print
	ret
	
my_println:
    call my_print
	mov ax, seg my_println_newLine
	mov ds, ax
	mov dx, offset my_println_newLine
    call _my_print
	ret
	my_println_newLine		db	10,13,'$'
	
get_file_name:
	xor cx,cx
    mov cl, byte ptr es:[80h]
    cmp cl, 0
    je get_file_name_no_args

    mov ax, seg data1
	mov ds, ax
	mov si, 0 ;iterator
	mov di, 0
	get_file_name_whitespace_loop:
		xor ax,ax
		mov al, byte ptr es:[81h + si]
		cmp ax, ' '
		jle get_file_name_whitespace_loop_inc
		cmp ax, '~'
		jg get_file_name_whitespace_loop_inc
		jmp get_file_name_loop_beg
	get_file_name_whitespace_loop_inc:
		inc si
		cmp si, cx
		jl get_file_name_whitespace_loop
		jge get_file_name_no_args
	get_file_name_loop_beg:
		xor ax,ax
		mov al, byte ptr es:[81h + si]
		cmp ax, ' '
		jle get_file_name_end
		cmp ax, '~'
		jg get_file_name_end
		mov byte ptr ds:[fileName + di], al 
		inc si
		inc di
		cmp si, cx
		jl get_file_name_loop_beg
	get_file_name_end:
		mov ax,0
		ret
	get_file_name_no_args:
		mov ax,1
		ret
	
print_char:
	mov ah, 2
	mov dl, al
	int 21h
	ret