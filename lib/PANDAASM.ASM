IDEAL
MODEL small
STACK 100h

DATASEG

	TRUE equ 1
	FALSE equ 0
	INVALID db 0
	FILE_TYPE_BUFFER db 0, 0, 13, 10, '$'
	ERROR_CODE db 0, 0, '$'
	
	; PANDA ASSEMBLER LAUNCH MESSAGE
	WELCOME_MSG					db	'Panda Assembler Version 1.0 Copyright (C) 2016 Elian (Shadi) Kamal', 13, 10 ,\
										'This program is licensed under the GNU General Public License v3.', 2 dup(13, 10), '$'
	
	; ERROR MESSAGES
	
	ERROR_MSG_PARSING				db 	13, 10, 'An error has occured while parsing file: $'
	TERMINATED_WITH_ERROR_SYMBOL		db	'Program terminated with error symbol: $'
	
	MISSING_FILE_DECLERATION_ERROR 	db 	'ERROR: Missing PANDA file head decleration -> file decleration.', 13, 10, '$'
	MISSING_DATA_TOKEN_ERROR			db	'ERROR: Missing data token "Bamboo" -> data section.', 13, 10, '$'
	MISSING_INITIALIZATION_TOKEN_ERROR	db	'ERROR: Missing initialization token -> init section.', 13, 10, '$'
	MISSING_APPLICATION_TOKEN_ERROR 	db 	'ERROR: Missing Application token.', 13, 10, '$'
	MISSING_OPEN_PAR_ERROR 			db	'ERROR: Missing opening parenthesis " ( " -> parameter handling.', 13, 10, '$'
	MISSING_CLOSE_PAR_ERROR 			db	'ERROR: Missing closing parenthesis " ) " -> parameter handling.', 13, 10, '$'
	MISSING_OPEN_BLOCK_ERROR 			db	'ERROR: Missing opening bracket " { " -> content block.', 13, 10, '$'
	MISSING_CLOSE_BLOCK_ERROR		db	'ERROR: Missing closing bracket " } " -> content block.', 13, 10, '$'
	MISSING_OPEN_DATA_BLOCK_ERROR 	db	'ERROR: Missing opening bracket " { " -> data block.', 13, 10, '$'
	MISSING_CLOSE_DATA_BLOCK_ERROR 	db	'ERROR: Missing closing bracket " } " -> data block.', 13, 10, '$'
	MISSING_OPEN_INIT_BLOCK_ERROR		db 	'ERROR: Missing opening bracket " { " - > initialization block.', 13, 10, '$'
	MISSING_CLOSE_INIT_BLOCK_ERROR		db 	'ERROR: Missing closing bracket " } " - > initialization block.', 13, 10, '$'
	
	;STATUS MESSAGES
	
	PARSING_FILE_MSG					db 	'Parsing file: $'
	PANDA_FOUND_MSG					db 	'Found PANDA head decleration...', 13, 10, '$'
	DATA_SECTION_FOUND_MSG			db 	'Found Bamboo data section token...', 13, 10, '$'
	INIT_TOKEN_FOUND_MSG				db	'Found initialization token...', 13, 10, '$'
	APPLICATION_TOKEN_FOUND_MSG		db 	'Found main application token...', 13, 10, '$'
	APPLICATION_MODE_MSG				db	'Application MODE: $'
	FINISHED_PARSING_MSG				db	13, 10, 'Finished parsing file.$'
	
	;TEMPLATE COMPONENTS

	TEMPLATE_HEAD 		db 'IDEAL', 13, 10, \
						'MODEL small', 13, 10, \
						'STACK 100h', 13, 10, \
						'INCLUDE "PANDA.ASM"', 1 dup(13, 10),'$'
	TEMPLATE_HEAD_LEN 	equ 53
	
	INCLUDE_GFX			db 'INCLUDE "PANDAGFX.ASM"', 13, 10, '$'
	INCLUDE_GFX_LEN		equ 24
	
	INCLUDE_TXT			db 'INCLUDE "PANDATXT.ASM"', 13, 10, '$'
	INCLUDE_TXT_LEN		equ 24
	
	TEMPLATE_DATASEG		db 'DATASEG', 13, 10, '$'
	TEMPLATE_DATASEG_LEN	equ 9
					
	TEMPLATE_BODY_1 		db 'CODESEG', 13, 10, \
						'start:', 13, 10, \
						'MOV AX, @data', 13, 10, \
						'MOV DS, AX', 13, 10, \
						'XOR AX, AX', 13, 10, '$'
	TEMPLATE_BODY_1_LEN 	equ 56
						
						
	TEMPLATE_BODY_2		db '@@gameLoop:', 13, 10, \
						'CALL handle_input', 13, 10, '$'
	TEMPLATE_BODY_2_LEN	equ 32
	
					
	TEMPLATE_BODY_3		db 'CMP [CLOSE_REQUESTED], FALSE', 13, 10, \
						'JE @@gameLoop', 13, 10, '$'
	TEMPLATE_BODY_3_LEN 	equ 45
					
	TEMPLATE_FOOT		db 'CALL set_text_mode', 13, 10, \
						'CALL terminate_program', 13, 10, \
						'END start$'
	TEMPLATE_FOOT_LEN 	equ 53
					
	FILE_HANDLE 			dw 0
	NEWL 				db 13, 10, '$'
	FILE_OPEN_ERROR 		db 'ERROR: An error has occured while opening file', 13, 10, '$'
	FILE_CREATE_ERROR 	db 'ERROR: An error has occured while creating file', 13, 10, '$'
	CHARACTER 			db 0
	USER_CONTENT_LENGTH 	dw 0
	USER_DATA_LENGTH		dw 0
	USER_INIT_LENGTH		dw 0
	FILE_NAME_LENGTH 	dw 0
	
	FILE_NAME 			db 16 dup(0), 0, 13, 10, '$'
	OUT_FILE_NAME 		db 16 dup(0), 0
	
	; Buffers
	PARAM_BUFFER 		db 16 dup(0)
	FILE_BUFFER 			db 28000 dup(0)
	USER_DATA_BUFFER 	db 8000 dup(0)
	USER_INIT_BUFFER		db 4000 dup(0)
	USER_CONTENT_BUFFER 	db 16000 dup(0)
	
CODESEG
start:
	mov ax, @data
	mov ds, ax
	xor ax, ax
	
	push ax dx
	mov ah, 09h
	mov dx, offset WELCOME_MSG
	int 21h
	pop dx ax
	
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
	
	call exit
	
; ===================
; =           PROCEDURES           =
; ===================

; === PARSING ===

proc exit
	mov ax, 4c00h
	int 21h
	ret
endp

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

proc space_loop
@@space:
	inc si
	mov al, [ds:bx + si]
	cmp al, 10
	je @@space
	cmp al, 13
	je @@space
	cmp al, ' '
	je @@space
	ret
endp

proc parse_file
	push ax
	push bx
	push cx
	push si
	push di
	
	push ax dx
	mov ah, 09h
	mov dx, offset PARSING_FILE_MSG
	int 21h
	mov dx, offset FILE_NAME
	int 21h
	pop dx ax
	
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
	
jmp @@skip_error1
@@panda_error:
	mov ah, 09h
	mov dx, offset MISSING_FILE_DECLERATION_ERROR
	int 21h
	mov [ERROR_CODE], 1
	jmp end_err
@@skip_error1:
	
	push ax dx
	mov ah, 09h
	mov dx, offset PANDA_FOUND_MSG
	int 21h
	pop dx ax
	
	call space_loop

	mov al, [ds:bx + si]
	cmp al, 'B'
	jne @@missing_data_token
	inc si
	mov al, [ds:bx + si]
	cmp al, 'a'
	jne @@missing_data_token
	inc si
	mov al, [ds:bx + si]
	cmp al, 'm'
	jne @@missing_data_token
	inc si
	mov al, [ds:bx + si]
	cmp al, 'b'
	jne @@missing_data_token
	inc si
	mov al, [ds:bx + si]
	cmp al, 'o'
	jne @@missing_data_token
	inc si
	mov al, [ds:bx + si]
	cmp al, 'o'
	jne @@missing_data_token
	inc si
	
jmp @@skip_data_err
	@@missing_data_token:
	mov ah, 09h
	mov dx, offset MISSING_DATA_TOKEN_ERROR
	int 21h
	mov [ERROR_CODE], 2
	jmp end_err
@@skip_data_err:

	push ax dx
	mov ah, 09h
	mov dx, offset DATA_SECTION_FOUND_MSG
	int 21h
	pop dx ax
	
	call space_loop
	
	mov al, [ds:bx + si]
	cmp al, '{'
	jne @@missing_open_data_block
	
jmp @@skip_data_block_open_err
@@missing_open_data_block:
	mov ah, 09h
	mov [ERROR_CODE], 21
	mov dx, offset MISSING_OPEN_DATA_BLOCK_ERROR
	int 21h
	jmp end_err
@@skip_data_block_open_err:

	xor di, di
	dec di
@@data_content:
	inc di
	inc si
	mov al, [ds:bx + si]
	cmp di, 8000
	jge @@missing_data_close_block
	cmp al, '}'
	je @@data_content_end
	mov [USER_DATA_BUFFER + di], al
	inc [USER_DATA_LENGTH]
	jmp @@data_content
@@data_content_end:

jmp @@skip_data_close_block_err
	@@missing_data_close_block:
	mov ah, 09h
	mov dx, offset MISSING_CLOSE_DATA_BLOCK_ERROR
	mov [ERROR_CODE], 22
	int 21h
	jmp end_err
@@skip_data_close_block_err:
	
	call space_loop
	
	mov al, [ds:bx + si]
	cmp al, 'I'
	jne @@missing_init_token
	inc si
	mov al, [ds:bx + si]
	cmp al, 'n'
	jne @@missing_init_token
	inc si
	mov al, [ds:bx + si]
	cmp al, 'i'
	jne @@missing_init_token
	inc si
	mov al, [ds:bx+ si]
	cmp al, 't'
	jne @@missing_init_token
	inc si
	
	
jmp @@skip_init_err
	@@missing_init_token:
	mov ah, 09h
	mov dx, offset MISSING_INITIALIZATION_TOKEN_ERROR
	mov [ERROR_CODE], 3
	int 21h
	jmp end_err
@@skip_init_err:

	push ax dx
	mov ah, 09h
	mov dx, offset INIT_TOKEN_FOUND_MSG
	int 21h
	pop dx ax
	
	call space_loop
	
	mov al, [ds:bx + si]
	cmp al, '{'
	jne @@missing_open_init_block
	
jmp @@skip_open_init_block_err
	@@missing_open_init_block:
	mov ah, 09h
	mov dx, offset MISSING_OPEN_INIT_BLOCK_ERROR
	mov [ERROR_CODE], 31
	int 21h
	jmp end_err
@@skip_open_init_block_err:

	xor di, di
	dec di
@@init_loop:
	inc di
	inc si
	cmp di, 4000
	jge @@missing_init_close_block
	mov al, [ds:bx + si]
	cmp al, '}'
	je @@init_loop_end
	mov [USER_INIT_BUFFER + di], al
	inc [USER_INIT_LENGTH]
	jmp @@init_loop
@@init_loop_end:
	
jmp @@skip_missing_init_close_err
	@@missing_init_close_block:
	mov ah, 09h
	mov dx, offset MISSING_CLOSE_INIT_BLOCK_ERROR
	mov [ERROR_CODE], 32
	int 21h
	jmp end_err
@@skip_missing_init_close_err:

	call space_loop
	
	mov al, [ds:bx + si]
	cmp al, 'A'
	jne @@missing_application_token
	inc si
	mov al, [ds:bx + si]
	cmp al, 'p'
	jne @@missing_application_token
	inc si
	mov al, [ds:bx + si]
	cmp al, 'p'
	jne @@missing_application_token
	inc si
	mov al, [ds:bx + si]
	cmp al, 'l'
	jne @@missing_application_token
	inc si
	mov al, [ds: bx + si]
	cmp al, 'i'
	jne @@missing_application_token
	inc si
	mov al, [ds:bx + si]
	cmp al, 'c'
	jne @@missing_application_token
	inc si
	mov al, [ds:bx + si]
	cmp al, 'a'
	jne @@missing_application_token
	inc si
	mov al, [ds:bx + si]
	cmp al, 't'
	jne @@missing_application_token
	inc si
	mov al, [ds:bx + si]
	cmp al, 'i'
	jne @@missing_application_token
	inc si
	mov al, [ds:bx + si]
	cmp al, 'o'
	jne @@missing_application_token
	inc si
	mov al, [ds:bx + si]
	cmp al, 'n'
	jne @@missing_application_token
	
jmp @@skip_app_error
@@missing_application_token:
	mov ah, 09h
	mov dx, offset MISSING_APPLICATION_TOKEN_ERROR 
	int 21h
	mov [ERROR_CODE], 4
	jmp @@end
@@skip_app_error:

	inc si
	
	; Check for parameters
	
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
	
	push ax dx
	mov ah, 09h
	mov dx, offset APPLICATION_TOKEN_FOUND_MSG
	int 21h
	mov dx, offset APPLICATION_MODE_MSG
	int 21h
	mov dx, offset FILE_TYPE_BUFFER
	int 21h
	pop dx ax
	
	; Parse and store content block
	
	call space_loop
	
	mov al, [ds:bx + si]
	cmp al, '{'
	jne @@missing_open_block
	
	xor di, di
	dec di
@@contentLoop:
	inc di
	inc si
	mov al, [ds:bx + si]
	cmp di, 16000
	jge @@missing_close_block
	cmp al, '}'
	je @@contentEnd
	mov [USER_CONTENT_BUFFER + di], al
	inc [USER_CONTENT_LENGTH]
	jmp @@contentLoop
@@contentEnd:

jmp @@skip_error3
@@missing_open_par:
	mov ah, 09h
	mov dx, offset MISSING_OPEN_PAR_ERROR 
	int 21h
	mov [ERROR_CODE], 42
	jmp end_err
@@skip_error3:

jmp @@skip_error4
@@missing_close_par:
	mov ah, 09h
	mov dx, offset MISSING_CLOSE_PAR_ERROR 
	int 21h
	mov [ERROR_CODE], 43
	jmp end_err
@@skip_error4:

jmp @@skip_error5
@@missing_open_block:
	mov ah, 09h
	mov dx, offset  MISSING_OPEN_BLOCK_ERROR 
	int 21h
	mov [ERROR_CODE], 52
	jmp end_err
@@skip_error5:

jmp @@skip_error6
@@missing_close_block:
	mov ah, 09h
	mov dx, offset  MISSING_CLOSE_BLOCK_ERROR 
	int 21h
	mov [ERROR_CODE], 52
	jmp end_err
@@skip_error6:
	
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

proc end_err
	mov ah, 09h
	mov dx, offset ERROR_MSG_PARSING
	int 21h
	mov dx, offset FILE_NAME
	int 21h
	mov dx, offset TERMINATED_WITH_ERROR_SYMBOL
	int 21h
	mov ah, 02h
	mov dl, [ERROR_CODE]
	int 21h
	mov ah, 4ch
	int 21h
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
	
	cmp [FILE_TYPE_BUFFER], 'a'
	je @@addALLIncludes
	
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
	
@@addALLIncludes:
	mov ah, 40h
	mov bx, [FILE_HANDLE] 
	mov cx, INCLUDE_GFX_LEN
	mov dx, offset INCLUDE_GFX
	int 21h
	mov ah, 40h
	mov bx, [FILE_HANDLE] 
	mov cx, INCLUDE_TXT_LEN
	mov dx, offset INCLUDE_TXT
	int 21h
	jmp @@includeSectionEnd

@@includeSectionEnd:

	mov ah, 40h
	mov bx, [FILE_HANDLE]
	mov cx, TEMPLATE_DATASEG_LEN
	mov dx, offset TEMPLATE_DATASEG
	int 21h
	
	mov ah, 40h
	mov bx, [FILE_HANDLE]
	mov cx, [USER_DATA_LENGTH]
	mov dx, offset USER_DATA_BUFFER
	int 21h
	
	mov ah, 40h
	mov bx, [FILE_HANDLE]
	mov cx, 2
	mov dx, offset NEWL
	int 21h

	mov ah, 40h
	mov bx, [FILE_HANDLE]
	mov cx, TEMPLATE_BODY_1_LEN
	mov dx, offset TEMPLATE_BODY_1
	int 21h
	
	mov ah, 40h
	mov bx, [FILE_HANDLE]
	mov cx, [USER_INIT_LENGTH]
	mov dx, offset USER_INIT_BUFFER
	int 21h
	
	mov ah, 40h
	mov bx, [FILE_HANDLE]
	mov cx, 2
	mov dx, offset NEWL
	int 21h
	
	mov ah, 40h
	mov bx, [FILE_HANDLE]
	mov cx, TEMPLATE_BODY_2_LEN
	mov dx, offset TEMPLATE_BODY_2
	int 21h
	
	mov ah, 40h
	mov bx, [FILE_HANDLE]
	mov cx, [USER_CONTENT_LENGTH]
	mov dx, offset USER_CONTENT_BUFFER
	int 21h
	
	mov ah, 40h
	mov bx, [FILE_HANDLE]
	mov cx, 2
	mov dx, offset NEWL
	int 21h
	
	mov ah, 40h
	mov bx, [FILE_HANDLE]
	mov cx, TEMPLATE_BODY_3_LEN
	mov dx, offset TEMPLATE_BODY_3
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
;Input:
;	[CHARACTER] - Character to be validated
;Output:
;	[INVALID] - 1 or 0 if check was INVALID or NOT-INVALID (Respectively)
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

END start