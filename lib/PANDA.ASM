; ========================================================================
;                                	 PANDA8086
; PANDA8086 is a game and general purpose engine for game
; and program development with TASM for 8086 architecture
; processors on MS-DOS. 
;    Copyright (C) 2016  Elian Kamal
;
;    This program is free software: you can redistribute it and/or modify
;    it under the terms of the GNU General Public License as published by
;    the Free Software Foundation, either version 3 of the License, or
;    (at your option) any later version.
;
;    This program is distributed in the hope that it will be useful,
;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;    GNU General Public License for more details.
;
;    You should have received a copy of the GNU General Public License
;    along with this program.  If not, see <http://www.gnu.org/licenses/>.
; ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
; Preface:
;		This is an engine that gives game engine integration for assembly
;		programmers to create  games and programs for MS-DOS by using a
;		provided sizeable programming interface/library.
;		
; Brief explanation:
; 		The library/interface consists of one main core file which is this
;		file  (PANDA.ASM)  which you should include  regardless of how you
;		wish to use  the  library,  it contains all  the  main  procedures
;		that are required in order for your program to behave properly.
;		and of two other files  named  "PANDAGFX.ASM"  and  "PANDATXT.ASM" 
;		which contain graphics procedures and text art/handling procedures 
;		respectively.
;		for additional  details on  the files and for a  detailed  content
;		table refer to the mentioned files.
;		
; ========================================================================

IDEAL
p8086
MODEL small

DATASEG
;=====================
;===== CONSTANTS =====
;=====================
;=== OFFSETS ===
ES_GRAPHICS_MODE_OFFSET dw 0a000h

;=== AH INT VALUES ===
EXIT_MODE db 4ch
GRAPHICS_MODE dw 13h
TEXT_MODE dw 3h
READ_PIXEL_CONST db 0dh
DRAW_PIXEL_CONST db 0ch
OPEN_FILE db 3dh
READ_FILE db 3fh
CLOSE_FILE db 3eh


;=== COLOR VALUES ===
COLOR db 0
BG_COLOR db 0
GROUND_COLOR db 0
PET_COLOR db 4 	; Default color red (no real reason it just shouldn't be black)

COLOR_BLACK 					db 0000b
COLOR_BLUE 					db 0001b
COLOR_GREEN 					db 0010b
COLOR_CYAN 					db 0011b
COLOR_RED 					db 0100b
COLOR_MAGENTA 				db 0101b
COLOR_BROWN 				db 0110b
COLOR_LIGHT_GRAY 				db 0111b
COLOR_DARK_GRAY 				db 1000b
COLOR_LIGHT_BLUE 				db 1001b
COLOR_LIGHT_GREEN 			db 1010b
COLOR_LIGHT_CYAN 				db 1011b
COLOR_LIGHT_RED 				db 1100b
COLOR_LIGHT_MAGENTA 			db 1101b
COLOR_YELLOW 				db 1110b
COLOR_WHITE 					db 1111b

COLOR_BLACK_CONST 			equ 0000b
COLOR_BLUE_CONST 			equ 0001b
COLOR_GREEN_CONST 			equ 0010b
COLOR_CYAN_CONST 			equ 0011b
COLOR_RED_CONST 				equ 0100b
COLOR_MAGENTA_CONST 			equ 0101b
COLOR_BROWN_CONST 			equ 0110b
COLOR_LIGHT_GRAY_CONST 		equ 0111b
COLOR_DARK_GRAY_CONST 		equ 1000b
COLOR_LIGHT_BLUE_CONST 		equ 1001b
COLOR_LIGHT_GREEN_CONST 		equ 1010b
COLOR_LIGHT_CYAN_CONST 		equ 1011b
COLOR_LIGHT_RED_CONST 		equ 1100b
COLOR_LIGHT_MAGENTA_CONST 	equ 1101b
COLOR_YELLOW_CONST 			equ 1110b
COLOR_WHITE_CONST			equ 1111b

;===ASCII CODES===
KEY_NUL  db 00h
KEY_SOH db 01h
KEY_STX db 02h
KEY_ETX db 03h
KEY_EOT db 04h
KEY_ENQ db 05h
KEY_ACK db 06h
KEY_BEL db 07h
KEY_BS db 08h
KEY_HT db 09h
KEY_LF db 0ah
KEY_VT db 0bh
KEY_FF db 0ch
KEY_CR db 0dh
KEY_SO db 0eh
KEY_SI db 0fh
KEY_DLE db 10h
KEY_DC1 db 11h
KEY_DC2 db 12h
KEY_DC3 db 13h
KEY_DC4 db 14h
KEY_NAK db 15h
KEY_SYN db 16h
KEY_ETB db 17h
KEY_CAN db 18h
KEY_EM db 19h
KEY_SUB db 1ah
KEY_ESCAPE db 1bh
KEY_FS db 1ch
KEY_GS db 1dh
KEY_RS db 1eh
KEY_US db 1fh
KEY_SPACE equ 20h
KEY_EXCLAMATION db 21h
KEY_QUOTE_DOUBLE db 22h
KEY_POUND db 23h
KEY_US_DOLLAR db 24h
KEY_PERCENT db 25h
KEY_AND db 26h
KEY_QUOTE_SINGLE db 27h
KEY_PARENTHESIS_OPEN db 28h
KEY_PARENTHESIS_CLOSE db 29h
KEY_STAR db 2ah
KEY_PLUS db 2bh
KEY_COMMA db 2ch
KEY_DASH db 2dh
KEY_DOT db 2eh
KEY_SLASH_FWD db 2fh
KEY_ZERO db 30h
KEY_ONE db 31h
KEY_TWO db 32h
KEY_THREE db 33h
KEY_FOUR db 34h
KEY_FIVE db 35h
KEY_SIX db 36h
KEY_SEVEN db 37h
KEY_EIGHT db 38h
KEY_NINE db 39h
KEY_COLONS db 3ah
KEY_SEMICOLON db 3bh
KEY_LESS_THAN db 3ch
KEY_EQUAL_SIGN equ 3dh
KEY_GREATER_THAN db 3eh
KEY_QUESTION_MARK db 3fh
KEY_AT_SIGN db 40h
KEY_CAP_A db 41h
KEY_CAP_B db 42h
KEY_CAP_C db 43h
KEY_CAP_D db 44h
KEY_CAP_E db 45h
KEY_CAP_F db 46h
KEY_CAP_G db 47h
KEY_CAP_H db 48h
KEY_CAP_I db 49h
KEY_CAP_J db 4ah
KEY_CAP_K db 4bh
KEY_CAP_L db 4ch
KEY_CAP_M db 4dh
KEY_CAP_N db 4eh
KEY_CAP_O db 4fh
KEY_CAP_P db 50h
KEY_CAP_Q db 51h
KEY_CAP_R db 52h
KEY_CAP_S db 53h
KEY_CAP_T db 54h
KEY_CAP_U db 55h
KEY_CAP_V db 56h
KEY_CAP_W db 57h
KEY_CAP_X db 58h
KEY_CAP_Y db 59h
KEY_CAP_Z db 5ah
KEY_BRACE_SQR_L db 5bh
KEY_SLASH_BWD db 5ch
KEY_BRACE_SQR_R db 5dh
KEY_ROOF_SIGN db 5eh
KEY_UNDERSCORE db 5fh
KEY_TICK db 60h
KEY_A db 61h
KEY_B db 62h
KEY_C db 63h
KEY_D db 64h
KEY_E db 65h
KEY_F db 66h
KEY_G db 67h
KEY_H db 68h
KEY_I db 69h
KEY_J db 6ah
KEY_K db 6bh
KEY_L db 6ch
KEY_M db 6dh
KEY_N db 6eh
KEY_O db 6fh
KEY_P db 70h
KEY_Q db 71h
KEY_R db 72h
KEY_S db 73h
KEY_T db 74h
KEY_U db 75h
KEY_V db 76h
KEY_W db 77h
KEY_X db 78h
KEY_Y db 79h
KEY_Z db 7ah
KEY_BRACE_CURLY_L db 7bh
KEY_PIPE_SIGN equ 7ch
KEY_BRACE_CURLY_R db 7dh
KEY_TILDE db 7eh
KEY_DEL db 7fh

;=== OTHER ===
TRUE equ 1
FALSE equ 0
FILE_ACCESS_READ db 0
FILE_ACCESS_WRITE db 1
FILE_ACCESS_BOTH db 2
FILE_ACCESS_MODE db 0


;=====================
;===== VARIABLES =====
;=====================

;=== X & Y VALUES ===
PXL_X dw 0
PXL_Y dw 0
TXT_X dw 0
TXT_Y dw 0
PET1_X dw 155
PET1_Y dw 147
SQR_X dw 0
SQR_Y dw 0
TREE1_X dw 0
TREE1_Y dw 0
CLOUD1_X dw 45
CLOUD1_Y dw 45
CLOUD2_X dw 247
CLOUD2_Y dw 20
CLOUD3_X dw 152
CLOUD3_Y dw 30
SUN_X dw 5
SUN_Y dw 5
POND_X dw 205
POND_Y dw 165
LINE_X0 dw 0
LINE_Y0 dw 0
LINE_X1 dw 0
LINE_Y1 dw 0



;=== OTHER / MULTI-PURPOSE ===
RANDOM db 16 dup(0)
RES_GW dw 320
RES_GH dw 200
CLOSE_REQUESTED db 0
COUNTER dw 0
SQR_SIZE dw 0
TRI_SIZE dw 0
HLINE_SIZE dw 0
VLINE_SIZE dw 0
WHOLDER1 dw 0
BHOLDERS db 16 dup(0)
RCT_W dw 0
RCT_H dw 0
WAIT_TIME dd 0
EXIT_CODE db 0
FILE_NAME db 'IMAGE.BMP', 0
FILE_HANDLE dw ?
IMAGE_HEADER db 54 dup (0)
IMAGE_PALETTE db 256*4 dup (0)
IMAGE_LINE db 320 dup(0)
ERROR_MSG db 'Error', 13, 10, '$'
TXT_PTR dw 0

CODESEG

; sets the display mode to 80x25 text mode
public set_text_mode
proc set_text_mode
     push ax
     mov ax, [TEXT_MODE]
     int 10h
     pop ax
     ret
endp

; terminates the program
; parameters:
;       [EXIT_CODE] - Exit code (default value: 0)
public terminate_program
proc terminate_program
     push ax
     mov ah, [EXIT_MODE]
     mov al, [EXIT_CODE]
     int 21h
     pop ax
     ret
endp

; checks for input in the keyboard buffer
; if input is available:
;       proceed to parsing input
; else:
;       return
public handle_input
proc handle_input
     mov ah, 1
     int 16h
     jnz parse_input
     ret
endp

; parses the input and calls the relevant procedures upon
; assigned key events
; NOTE: it is advised to keep the 
public parse_input
proc parse_input
     xor ah, ah
     int 16h
     cmp al, [KEY_ESCAPE]
     je request_termination
     cmp al, [KEY_A]
     je move_left
     cmp al, [KEY_CAP_A]
     je move_left
     cmp al, [KEY_D]
     je move_right
     cmp al, [KEY_CAP_D]
     je move_right
     cmp al, [KEY_W]
     je move_up
     cmp al, [KEY_CAP_W]
     je move_up
     cmp al, [KEY_S]
     je move_down
     cmp al, [KEY_CAP_S]
     je move_down
     ret
endp
     
; moves the player to the left
public move_left
proc move_left
    sub [PET1_X], 6
    ret
endp

; moves the player to the right
public move_right
proc move_right
    add [PET1_X], 6 
    ret
endp
    
; moves the player up and does a porder check
public move_up
proc move_up
    cmp [PET1_Y], 130
    jle failP1UpperBorderCheck
    sub [PET1_Y], 6
    failP1UpperBorderCheck:
    ret
endp

; moves the player down and does a border check
public move_down
proc move_down
    push ax
    mov ax, [RES_GH]
    sub ax, 25
    cmp [PET1_Y], ax
    pop ax
    jge failP1DownBorderCheck
    add [PET1_Y], 6
    failP1DownBorderCheck:
    ret
endp

; requests termination of the process
; should be used as the event upon which
; the game loop decides to iterate or terminate
; output:
;       [CLOSE_REQUESTED] - loaded with the value of 1
public request_termination
proc request_termination
    mov [CLOSE_REQUESTED], 1
    ret
endp


; clears the general registers ax, bx, cx and dx
; output:
;       AX - cleared
;       BX - cleared
;       CX - cleared
;       DX - cleared
public clear_basic_registers
proc clear_basic_registers
     xor ax, ax
     xor bx, bx
     xor cx, cx
     xor dx, dx
     ret
endp
     
; (IGNORE) resets the pet position
public reset_creature1_pos_x
proc reset_creature1_pos_x
     push ax
     mov ax, [PET1_X]
     mov [PXL_X], ax
     pop ax
     ret
endp
    
; changes the value of COLOR to light magenta (pink)
; NOTE: preferred over manually setting the [COLOR]
; when dealing with the basic 16 colors
; output:
;       [COLOR] - [COLOR_LIGHT_MAGENTA]
public color_to_pink
proc color_to_pink
     push ax
     mov al, [COLOR_LIGHT_MAGENTA]
     mov [COLOR], al
     pop ax
     ret
endp

; changes the value of COLOR to brown
; NOTE: preferred over manually setting the [COLOR]
; when dealing with the basic 16 colors
; output:
;       [COLOR] - [COLOR_BROWN]
public color_to_brown
proc color_to_brown
     push ax
     mov al, [COLOR_BROWN]
     mov [COLOR], al
     pop ax
     ret
endp

; changes the value of COLOR to black
; NOTE: preferred over manually setting the [COLOR]
; when dealing with the basic 16 colors
; output:
;       [COLOR] - [COLOR_BLACK]
public color_to_black
proc color_to_black
     push ax
     mov al, [COLOR_BLACK]
     mov [COLOR], al
     pop ax
     ret
endp
    
; changes the value of COLOR to white
; NOTE: preferred over manually setting the [COLOR]
; when dealing with the basic 16 colors
; output:
;       [COLOR] - [COLOR_WHITE]
public color_to_white
proc color_to_white
    push ax
    mov al, [COLOR_WHITE]
    mov [COLOR], al
    pop ax
    ret
endp
   
; changes the value of COLOR to red
; NOTE: preferred over manually setting the [COLOR]
; when dealing with the basic 16 colors
; output:
;       [COLOR] - [COLOR_RED]
proc color_to_red
    push ax
    mov al, [COLOR_LIGHT_RED]
    mov [COLOR], al
    pop ax
    ret
endp

; changes the value of COLOR to blue
; NOTE: preferred over manually setting the [COLOR]
; when dealing with the basic 16 colors
; output:
;       [COLOR] - [COLOR_BLUE]
public color_to_blue
proc color_to_blue
    push ax
    mov al, [COLOR_BLUE]
    mov [COLOR], al
    pop ax
    ret
endp
    
; changes the value of COLOR to light blue
; NOTE: preferred over manually setting the [COLOR]
; when dealing with the basic 16 colors
; output:
;       [COLOR] - [COLOR_LIGHT_BLUE]
public color_to_light_blue
proc color_to_light_blue
    push ax
    mov al, [COLOR_LIGHT_BLUE]
    mov [COLOR], al
    pop ax
    ret
endp
    
; changes the value of COLOR to green
; NOTE: preferred over manually setting the [COLOR]
; when dealing with the basic 16 colors
; output:
;       [COLOR] - [COLOR_GREEN]
public color_to_green
proc color_to_green
    push ax
    mov al, [COLOR_GREEN]
    mov [COLOR], al
    pop ax
    ret
endp

; changes the value of COLOR to yellow
; NOTE: preferred over manually setting the [COLOR]
; when dealing with the basic 16 colors
; output:
;       [COLOR] - [COLOR_YELLOW]
public color_to_yellow
proc color_to_yellow
    push ax
    mov al, [COLOR_YELLOW]
    mov [COLOR], al
    pop ax
    ret
endp

; changes the value of COLOR to magenta
; NOTE: preferred over manually setting the [COLOR]
; when dealing with the basic 16 colors
; output:
;       [COLOR] - [COLOR_MAGENTA]
public color_to_magenta
proc color_to_magenta
    push ax
    mov al, [COLOR_MAGENTA]
    mov [COLOR], al
    pop ax
    ret
endp

; changes the value of COLOR to cyan
; NOTE: preferred over manually setting the [COLOR]
; when dealing with the basic 16 colors
; output:
;       [COLOR] - [COLOR_CYAN]
public color_to_cyan
proc color_to_cyan
    push ax
    mov al, [COLOR_CYAN]
    mov [COLOR], al
    pop ax
    ret
endp
    
; waits a specified amount of microseconds via the MS-DOS API call
; parameters:
;   [WAIT_TIME] - time to wait (in microseconds)
public wait_micro
proc wait_micro
    push cx
    push dx
    mov cx, [word ptr WAIT_TIME]
    mov dx, [word ptr WAIT_TIME + 2]
    mov ah, 86h
    int 15h
    pop cx
    pop dx
    ret
endp

; Generates a random DWORD and stores it in [RANDOM]
; output:
;   [RANDOM] - Random generated data buffer
public generate_random
proc generate_random
    push ax
    push bx
    push cx
    push dx
    push si
    
    xor si, si
    mov di, 4
@@mainloop:
    push si
    mov ah, 2ch
    int 21h
    mov [BHOLDERS], dl
    xor ah, ah
    int 1ah
    push si
    sub si, 2
    xor dx, [word ptr RANDOM + si]
    pop si
    cmp dx, 7FFFh
    jl @@choose1
    cmp dx, 7FFFh
    jge @@choose2
    
    @@choose1:
        push bx
        mov bx, dx
        xor cx, [word ptr cs:bx]
        pop bx
        cmp cx, 7FFFh
        jle @@case1
        cmp cx, 7FFFh
        jg @@case2
    
    @@choose2:
        push bx
        mov bx, dx
        xor cx, [word ptr cs:bx]
        pop bx
        cmp cx, 7FFFh
        jge @@case1
        cmp cx, 7FFFh
        jl @@case2
    
    @@case1:
        mov [BHOLDERS + si], ch
        inc si
        mov [BHOLDERS + si], dl
        inc si
        mov [BHOLDERS + si], cl
        inc si
        mov [BHOLDERS + si], dh
        shl dl, 2
        xor ch, dh
        jmp @@continue1
        
    @@checkpointlabel:
        jmp @@mainloop
    
    @@case2:
        int 12h
        mov [BHOLDERS + si], dl
        inc si
        mov [BHOLDERS + si], cl
        inc si
        mov [BHOLDERS + si], dh
        inc si
        mov [BHOLDERS + si], ch
        shr dl, 3
        xor dh, cl
        jmp @@continue1
    
    @@case3:
        int 12h
        cmp al, 8
        jg @@case1
        cmp al, 8
        jl @@case2
        cmp al, 8
        je @@end
    
    @@continue1:
        mov ah, 0dh
        mov cx, dx
        mov dx, cx
        int 10h
        cmp al, 2
        jge @@case3
        
    @@checkpointlabel2:
        jmp @@checkpointlabel
    
    @@end:
        pop si
        push ax
        mov ax, [word ptr BHOLDERS]
        mov [word ptr RANDOM + si], ax
        add si, 2
        mov ax, [word ptr BHOLDERS + 2]
        mov [word ptr RANDOM + si], ax
        pop ax
        
        push si
        push bx
        mov ax, [word ptr RANDOM + si]
        sub si, 4
        xor ax, [word ptr RANDOM + si]
        add si, 2
        mov [word ptr RANDOM  + si], ax
        
        add si, 2
        
        mov ax, [word ptr RANDOM + si]
        sub si, 4
        xor ax, [word ptr RANDOM + si]
        add si, 2
        mov [word ptr RANDOM  + si], ax
        pop bx
        pop si
        
        dec di
        cmp di, 0
        jg @@checkpointlabel2
    pop si
    pop dx
    pop cx
    pop bx
    pop dx
    ret
endp

; Opens a specified file in accordance to given arguments
; parameters:
;       [FILE_NAME] - file name to open
;       [FILE_ACCESS_MODE] - file access mode (FILE_READ / FILE_WRITE / FILE_BOTH)
;                            use access_to_read / access_to_write / access_to_both
;                            in order to switch between different the access modes
; output:
;       [FILE_HANDLE] - the handle of the file (0 if error whilst opening the file)
public open_file_proc
proc open_file_proc
    push ax
    push dx
    mov ah, [OPEN_FILE]
    mov al, [FILE_ACCESS_MODE]
    mov dx, offset FILE_NAME
    int 21h
    
    jc @@openError
    mov [FILE_HANDLE], ax
    jmp @@end
    
    @@openError:
        mov dx, offset ERROR_MSG
        mov ah, 9
        int 21h
    
    @@end:
    pop dx
    pop ax
    ret
endp

; Changes FILE_ACCESS_MODE to reading
; output:
;       [FILE_ACCESS_MODE] - FILE_ACCESS_READ
public access_to_read
proc access_to_read
    push ax
    mov al, [FILE_ACCESS_READ]
    mov [FILE_ACCESS_MODE], al
    pop ax
    ret
endp

; Changes FILE_ACCESS_MODE to writing
; output:
;       [FILE_ACCESS_MODE] - FILE_ACCESS_WRITE
public access_to_write
proc access_to_write
    push ax
    mov al, [FILE_ACCESS_WRITE]
    mov [FILE_ACCESS_MODE], al
    pop ax
    ret
endp

; Changes FILE_ACCESS_MODE to both read/write
; output:
;       [FILE_ACCESS_MODE] - FILE_ACCESS_BOTH
public access_to_both
proc access_to_both
    push ax
    mov al, [FILE_ACCESS_BOTH]
    mov [FILE_ACCESS_MODE], al
    pop ax
    ret
endp