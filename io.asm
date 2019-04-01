my_print:
    call change_ds_to_data
    mov ah, 9h
    int 21h
	ret
	
my_println:
    call my_print
	my_println_newLine		db	10,13,'$'
	mov ax, seg my_println_newLine
	mov ds, ax
	mov dx, offset my_println_newLine
    call my_print
	ret
	
get_file_name:
	xor cx,cx
    mov cl, byte ptr es:[80h]
    cmp cl, 0
    je get_file_name_no_args

    call change_ds_to_data
	mov si, 0 ;iterator
	mov di, 0
	get_file_name_whitespace_loop:
		xor ax,ax
		mov al, byte ptr es:[81h + si]
		cmp ax, '.'
		je get_file_name_loop_beg
		cmp ax, 'A'
		jl get_file_name_whitespace_loop_inc
		cmp ax, 'z'
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
		cmp ax, '.'
		je get_file_name_assertion
		cmp ax, 'A'
		jl get_file_name_end
		cmp ax, 'z'
		jg get_file_name_end
	get_file_name_assertion:
		mov byte ptr ds:[fileName + di], al 
		inc si
		inc di
		cmp si, cx
		jl get_file_name_loop_beg
	get_file_name_end:
		ret
	get_file_name_no_args:
		mov dx, offset NO_FILE_NAME_MSG
		ret
	
print_char:
	mov ah, 2
	mov dl, al
	int 21h
	ret