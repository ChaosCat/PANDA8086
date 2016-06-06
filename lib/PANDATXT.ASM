IDEAL
MODEL small
STACK 100h

CODESEG
public print_text
proc print_text
	push ax
	push bx
	push cx
	push dx
	push si
	push bp
	
	xor si, si
	mov bx, [TXT_PTR]
@@count:
	mov al, [bx + si]
	cmp al, [KEY_TILDE]
	je @@continue
	inc si
	jmp @@count
	
@@continue:
	mov ah, 13h
	mov al, 01b
	xor bh, bh
	mov bl, [COLOR]
	mov cx, si
	mov dl, [byte ptr TXT_X]
	mov dh, [byte ptr TXT_Y]
	push ds
	pop es
	mov bp, [TXT_PTR]
	int 10h
	
	pop bp
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret
endp

DATASEG
	TXT_CHAR db 0
CODESEG
public print_char
proc print_char
	push ax
	push bx
	push cx
	push dx
	
	xor bh, bh
	
	mov ah, 2
	mov dh, [byte ptr TXT_Y]
	mov dl, [byte ptr TXT_X]
	int 10h
	
	mov ah, 9
	mov al, [TXT_CHAR]
	mov bl, [COLOR]
	mov cx, 1
	int 10h
	
	pop dx
	pop cx
	pop bx
	pop ax
	ret
endp

DATASEG
	TXT_FRAME_W dw 0
	TXT_FRAME_H dw 0
CODESEG
public print_text_frame
proc print_text_frame
	push cx
	push [TXT_FRAME_W]
	push [TXT_FRAME_H]
	push [TXT_X]
	push [TXT_Y]
	
	push [TXT_X]
	push [TXT_X]
	
	mov cx, [TXT_FRAME_W]
	mov [TXT_CHAR], KEY_EQUAL_SIGN
@@startline:
	call print_char
	inc [TXT_X]
	loop @@startline

	pop [TXT_X]
	
	inc [TXT_Y]

	push [TXT_FRAME_W]
	
	sub [TXT_FRAME_H], 2
	sub [TXT_FRAME_W], 2
	
@@loopY:
	mov [TXT_CHAR], KEY_PIPE_SIGN
	call print_char
	
	push [TXT_FRAME_W]
	push [TXT_X]
	mov [TXT_CHAR], KEY_SPACE
	@@loopX:
		call print_char
		inc [TXT_X]
		dec [TXT_FRAME_W]
		cmp [TXT_FRAME_W], 0
		jg @@loopX
		
	mov [TXT_CHAR], KEY_PIPE_SIGN
	call print_char
	
	pop [TXT_X]
	pop [TXT_FRAME_W]
	
	inc [TXT_Y]
	dec [TXT_FRAME_H]
	cmp [TXT_FRAME_H], 0
	jg @@loopY
	
	pop [TXT_FRAME_W]
	
	pop [PXL_X]
	mov cx, [TXT_FRAME_W]
	mov [TXT_CHAR], KEY_EQUAL_SIGN
@@endline:
	call print_char
	loop @@endline
	
	pop [TXT_Y]
	pop [TXT_X]
	pop [TXT_FRAME_H]
	pop [TXT_FRAME_W]
	pop cx
	ret
endp