IDEAL
MODEL small
STACK 100h

DATASEG

	TRUE equ 1
	FALSE equ 0
	INVALID db 0
	FILE_TYPE_BUFFER db 0
	ERROR_CODE dw 0
	
	MISSING_FILE_DECLERATION_ERROR db 	'ERROR: Missing PANDA file head decleration.$'
	MISSING_OPEN_PAR_ERROR 		db	'ERROR: Missing opening parenthesis " ( " -> parameter handling.', 13, 10, '$'
	MISSING_CLOSE_PAR_ERROR 		db	'ERROR: Missing closing parenthesis " ) " -> parameter handling.', 13, 10, '$'
	MISSING_OPEN_BLOCK_ERROR 		db	'ERROR: Missing opening bracket " { " -> user data block.', 13, 10, '$'
	MISSING_CLOSE_BLOCK_ERROR	db	'ERROR: Missing closing bracket " } " -> user data block.', 13, 10, '$'
	FINISHED_PARSING_MSG			db	13, 10, 'Finished parsing file', '$'

	TEMPLATE_HEAD 	db 'IDEAL', 13, 10, \
					'MODEL small', 13, 10, \
					'STACK 100h', 13, 10, \
					'INCLUDE "PANDA.ASM"', 1 dup(13, 10),'$'
	TEMPLATE_HEAD_LEN equ 53
	
	INCLUDE_GFX		db 'INCLUDE "PANDAGFX.ASM"', 13, 10, '$'
	INCLUDE_GFX_LEN	equ 24
	
	INCLUDE_TXT		db 'INCLUDE "PANDATXT.ASM"', 13, 10, '$'
	INCLUDE_TXT_LEN	equ 24
	
	INCLUDE_BOTH_LEN equ 46
					
	TEMPLATE_BODY_1 	db 'CODESEG', 13, 10, \
					'start:', 13, 10, \
					'MOV AX, @data', 13, 10, \
					'MOV DS, AX', 13, 10, \
					'XOR AX, AX', 13, 10, \
					'@@gameLoop:', 13, 10, \
					'CALL handle_input', 13, 10, '$'
	TEMPLATE_BODY_1_LEN equ 88
					
	TEMPLATE_BODY_2	db 13, 10,  'CMP [CLOSE_REQUESTED], FALSE', 13, 10, \
					'JE @@gameLoop', 13, 10, '$'
	TEMPLATE_BODY_2_LEN equ 46
					
	TEMPLATE_FOOT	db 'CALL set_text_mode', 13, 10, \
					'CALL terminate_program', 13, 10, \
					'END start$'
	TEMPLATE_FOOT_LEN equ 53
					
	FILE_HANDLE dw 0
	NEWL db 13, 10, '$'
	FILE_OPEN_ERROR db 'ERROR: An error has occured while opening file', 13, 10, '$'
	FILE_CREATE_ERROR db 'ERROR: An error has occured while creating file', 13, 10, '$'
	CHARACTER db 0
	USER_CONTENT_LENGTH dw 0
	FILE_NAME_LENGTH dw 0
	
	FILE_NAME db 16 dup(0), 0
	OUT_FILE_NAME db 16 dup(0), 0
	PARAM_BUFFER db 16 dup(0)
	FILE_BUFFER db 16000 dup(0)
	USER_CONTENT_BUFFER db 16000 dup(0)
	
CODESEG
start:
	mov ax, @data
	mov ds, ax
	xor ax, ax
	
	call load_parameters
	call parse_first_param
	
	call open_file_read
	call read_file
	call parse_file
	call close_file
	
	call set_output_file_name
	call create_output_file
	call open_output_file_write
	call write_output_to_file
	call close_file
	
	mov ax, 4c00h
	int 21h
	
; ===================
; =           PROCEDURES           =
; ===================

; === PARSING ===

proc parse_first_param
	push ax
	push cx
	
	mov [INVALID], 0
	
	mov cx, 16
	xor si, si
@@loop:
	mov al, [PARAM_BUFFER + si]
	mov [CHARACTER], al
	call validate_char
	cmp [INVALID], TRUE
	je @@skip
	mov [FILE_NAME + si], al
	inc si
	inc [FILE_NAME_LENGTH]
	loop @@loop

@@skip:
	mov [CHARACTER], 0
	pop cx
	pop ax
	ret
endp

proc parse_file
	push ax
	push bx
	push cx
	push si
	push di
	
	; Check if file type declaration exists at file start
	; throw an error otherwise
	
	xor si, si
	mov bx, offset FILE_BUFFER
	mov al, [ds:bx + si]
	cmp al, 'P'
	jne @@panda_error
	inc si
	mov al, [ds:bx + si]
	cmp al, 'A'
	jne @@panda_error
	inc si
	mov al, [ds:bx + si]
	cmp al, 'N'
	jne @@panda_error
	inc si
	mov al, [ds:bx + si]
	cmp al, 'D'
	jne @@panda_error
	inc si
	mov al, [ds:bx + si]
	cmp al, 'A'
	jne @@panda_error

	; Check for parameters
	
	inc si
	mov al, [ds:bx + si]
	cmp al, '('
	jne @@missing_open_par
	
	inc si
	mov al, [ds:bx + si]
	mov [FILE_TYPE_BUFFER], al
	inc di
	
	inc si
	mov al, [ds:bx + si]
	cmp al, ')'
	jne @@missing_close_par
	
	; Parse and store content block
	
	add si, 3
	mov al, [ds:bx + si]
	cmp al, '{'
	jne @@missing_open_block
	
	xor di, di
	dec di
@@contentLoop:
	inc di
	inc si
	mov al, [ds:bx + si]
	cmp di, 32000
	jge @@missing_close_block
	cmp al, '}'
	je @@contentEnd
	mov [USER_CONTENT_BUFFER + di], al
	inc [USER_CONTENT_LENGTH]
	jmp @@contentLoop
@@contentEnd:

jmp @@skip_error1
@@panda_error:
	mov ah, 09h
	mov dx, offset MISSING_FILE_DECLERATION_ERROR
	int 21h
	jmp @@end
@@skip_error1:

jmp @@skip_error2
@@missing_open_par:
	mov ah, 09h
	mov dx, offset MISSING_OPEN_PAR_ERROR 
	int 21h
	jmp @@end
@@skip_error2:

jmp @@skip_error3
@@missing_close_par:
	mov ah, 09h
	mov dx, offset MISSING_CLOSE_PAR_ERROR 
	int 21h
	jmp @@end
@@skip_error3:

jmp @@skip_error4
@@missing_open_block:
	mov ah, 09h
	mov dx, offset  MISSING_OPEN_BLOCK_ERROR 
	int 21h
	jmp @@end
@@skip_error4:

jmp @@skip_error5
@@missing_close_block:
	mov ah, 09h
	mov dx, offset  MISSING_CLOSE_BLOCK_ERROR 
	int 21h
	jmp @@end
@@skip_error5:
	
@@end:
	mov ah, 09h
	mov dx, offset FINISHED_PARSING_MSG
	int 21h
	
	pop di
	pop si
	pop cx
	pop bx
	pop ax
	ret
endp

proc set_output_file_name
	push ax
	push cx
	push si
	
	xor si, si
	mov cx, [FILE_NAME_LENGTH]
	sub cx, 4
@@loop:
	mov al, [FILE_NAME + si]
	mov [OUT_FILE_NAME + si], al
	inc si
	loop @@loop
	
	mov al, '.'
	mov [OUT_FILE_NAME + si], al
	
	inc si
	mov al, 'A'
	mov [OUT_FILE_NAME + si], al
	
	inc si
	mov al, 'S'
	mov [OUT_FILE_NAME + si], al
	
	inc si
	mov al, 'M'
	mov [OUT_FILE_NAME + si], al
	
	pop si
	pop ax
	pop cx
	ret
endp

proc write_output_to_file
	push ax
	push bx
	push cx
	push dx
	
	mov ah, 40h
	mov bx, [FILE_HANDLE] 
	mov cx, TEMPLATE_HEAD_LEN
	mov dx, offset TEMPLATE_HEAD
	int 21h
	
	cmp [FILE_TYPE_BUFFER], 'g'
	je @@addGFXInclude
	
	cmp [FILE_TYPE_BUFFER], 't'
	je @@addTXTInclude
	
	jmp @@includeSectionEnd
@@addGFXInclude:
	mov ah, 40h
	mov bx, [FILE_HANDLE] 
	mov cx, INCLUDE_GFX_LEN
	mov dx, offset INCLUDE_GFX
	int 21h
	jmp @@includeSectionEnd
	
@@addTXTInclude:
	mov ah, 40h
	mov bx, [FILE_HANDLE] 
	mov cx, INCLUDE_TXT_LEN
	mov dx, offset INCLUDE_TXT
	int 21h
	jmp @@includeSectionEnd

@@includeSectionEnd:

	mov ah, 40h
	mov bx, [FILE_HANDLE]
	mov cx, TEMPLATE_BODY_1_LEN
	mov dx, offset TEMPLATE_BODY_1
	int 21h
	
	mov ah, 40h
	mov bx, [FILE_HANDLE]
	mov cx, [USER_CONTENT_LENGTH]
	mov dx, offset USER_CONTENT_BUFFER
	int 21h
	
	mov ah, 40h
	mov bx, [FILE_HANDLE]
	mov cx, TEMPLATE_BODY_2_LEN
	mov dx, offset TEMPLATE_BODY_2
	int 21h
	
	mov ah, 40h
	mov bx, [FILE_HANDLE]
	mov cx, TEMPLATE_FOOT_LEN
	mov dx, offset TEMPLATE_FOOT
	int 21h
	
	pop dx
	pop cx
	pop bx
	pop ax
	ret
endp

; === OTHER ===

proc load_parameters
	push ax
	push cx
	push si

	mov cx, 16
	xor si, si
	xor ah, ah
@@loop:
	mov al, [BYTE PTR es:82h + si]
	mov [PARAM_BUFFER + si], al
	inc si
	loop @@loop
	
	pop ax
	pop cx
	pop si
	ret
endp

proc open_file_read
    push ax
    push dx
    
    mov ah, 3dh
    mov al, 0
    mov dx, offset FILE_NAME
    int 21h
    
    jc @@openError
    mov [FILE_HANDLE], ax
    jmp @@end
    
    @@openError:
	mov dx, offset FILE_OPEN_ERROR
        mov ah, 9
        int 21h
    
    @@end:
    pop dx
    pop ax
    ret
endp

proc open_output_file_write
	push ax
	push dx
	
	mov ah, 3dh
	mov al, 1
	mov dx, offset OUT_FILE_NAME

	jc @@openError
	jmp @@end
	@@openError:
		mov dx, offset FILE_OPEN_ERROR
		mov ah, 9
		int 21h
    
	@@end:
	pop dx
	pop ax
	ret
endp

proc create_output_file
	push ax
	push cx
	push dx
	
	mov ah, 3ch
	mov cx, 0
	mov dx, offset OUT_FILE_NAME
	int 21h
	jc @@createError
	mov [FILE_HANDLE], ax
	jmp @@end
	
@@createError:
	mov dx, offset FILE_CREATE_ERROR
	mov ah, 9
	int 21h
	
@@end:
	pop dx
	pop cx
	pop ax
	ret
endp

proc read_file
	push ax
	push bx
	push cx
	push dx
	
	mov ah, 3fh
	mov bx, [FILE_HANDLE]
	mov cx, 16000
	mov dx, offset FILE_BUFFER
	int 21h
	
	pop dx
	pop cx
	pop bx
	pop ax
	ret
endp

proc close_file
	push ax
	push bx
	
	mov ah, 3eh
	mov bx, [FILE_HANDLE]
	int 21h
	
	pop bx
	pop ax
	ret
endp

; Performs a series of checks (in ASCII ranges) to verify the validity of a character as:
;	A) A dot (.)
;	B) A number (0-9)
;	C) A letter (a-z/ A-Z)
proc validate_char
	push ax
	mov al , [CHARACTER]
	
	cmp al, 30h
	jl @@check1
@@continue1:
	cmp al, 39h
	jg @@check2
@@continue2:
	cmp al, 5ah
	jg @@check3
@@continue3:
	cmp al, 7ah
	jl @@skip_fail
	cmp al, 7ah
	jg @@fail
	
; dot case
@@check1:
	cmp al, 2eh
	je @@skip_fail
	cmp al, 2eh
	jne @@fail
	
@@check2:
	cmp al, 41h
	jge @@continue2
	cmp al, 41h
	jl @@fail
	
@@check3:
	cmp al, 61h
	jge @@continue3
	cmp al, 61h
	jl @@fail
	

jmp @@skip_fail
@@fail:
	mov [INVALID], TRUE
@@skip_fail:
	pop ax
	ret
endp

; Prints an example of the text for debugging info
proc print_example
	push ax
	push dx
	
	mov ah, 09h
	mov dx, offset TEMPLATE_HEAD
	int 21h
	
	mov ah, 09h
	mov dx, offset NEWL
	int 21h
	
	mov ah, 09h
	mov dx, offset TEMPLATE_BODY_1
	int 21h
	
	mov ah, 09h
	mov dx, offset NEWL
	int 21h
	
	mov ah, 09h
	mov dx, offset TEMPLATE_BODY_2
	int 21h
	
	mov ah, 09h
	mov dx, offset NEWL
	int 21h
	
	mov ah, 09h
	mov dx, offset TEMPLATE_FOOT
	int 21h
	
	pop dx
	pop ax
	ret
endp

END start