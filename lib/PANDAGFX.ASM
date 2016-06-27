IDEAL
p8086
MODEL small

CODESEG
; sets the display mode to 320x200 graphics mode
public set_graphics_mode
proc set_graphics_mode
     push ax
     mov ax, [word ptr GRAPHICS_MODE]
     int 10h
     mov ax, [ES_GRAPHICS_MODE_OFFSET]
     mov es, ax
     pop ax
     ret
endp

; (DEPRECIATED) draws a pixel via the MS-DOS interrupt
; parameters:
;       [PXL_X] - pixel column (range 0 - 320)
;       [PXL_Y] - pixel row (range 0 - 200)
;       [COLOR] - the pixel color
public draw_pixel_old
proc draw_pixel_old
     push ax
     push cx
     push dx
     mov ah, [DRAW_PIXEL_CONST]
     mov al, [COLOR]
     mov cx, [PXL_X]
     mov dx, [PXL_Y]
     int 10h
     pop dx
     pop cx
     pop ax
     ret
endp

; draws a pixel directly to the video memory
; NOTE: first call "set_graphics_mode" procedure
; in order to initialize es to the video memory
; adress (0A00h)
; parameters:
;       [PXL_X] - pixel column (range: 0 - 320)
;       [PXL_Y] - pixel row (range: 0 - 200)
;       [COLOR] - the pixel color
public draw_pixel
proc draw_pixel
     push ax
     push dx
     push si
     mov ax, 320
     mul [PXL_Y]
     add ax, [PXL_X]
     mov si, ax
     mov dl, [COLOR]
     mov [es:si], dl
     pop si
     pop dx
     pop ax
     ret
endp

; reads a pixel via the the MS-DOS interrupt
; parameters:
;       [PXL_X] - pixel column (range: 0 - 320)
;       [PXL_Y] - pixel row (range: 0 - 200)
; output:
;	[COLOR] - pixel color at given position
public read_pixel
proc read_pixel
     push ax
     push cx
     push dx
     mov ah, [READ_PIXEL_CONST]
     mov cx, [PXL_X]
     mov dx, [PXL_Y]
     int 10h
     mov [COLOR], al
     pop dx
     pop cx
     pop ax
     ret
endp

; reads a rectangle of pixels given it's width
; and height
; parameters:
;       [PXL_X] - pixel column to start reading from (range: 0 - 320)
;       [PXL_X] - pixel row to start reading from (range: 0 - 200)
;       [RCT_W] - rectangle width in pixels
;       [RCT_H] - rectangle height in pixels
;       [COLOR] - rectangle color
public read_pixel_rect
proc read_pixel_rect
     push [PXL_X]
     push [PXL_Y]
     push [RCT_W]
     push [RCT_H]
     
     loopRRY:
          push [PXL_X]
          push [RCT_W]
          loopRRX:
               call read_pixel
               inc [PXL_X]
               dec [RCT_W]
               cmp [RCT_W], 0
               jg loopRRX
          pop [RCT_W]
          pop [PXL_X]
          
          inc [PXL_Y]
          dec [RCT_H]
          cmp [RCT_H], 0
          jg loopRRY
          
     pop [RCT_H]
     pop [RCT_W]
     pop [PXL_Y]
     pop [PXL_X]
     ret
endp

public load_bmp_file
proc load_bmp_file
    call open_file_proc
    call read_image_header
    call read_image_palette
    call image_palette_to_vm
    call draw_image
    ret
endp

; Reads a BMP image header
; output:
;       [IMAGE_HEADER] - the BMP image header
public read_image_header
proc read_image_header
    push ax
    push bx
    push cx
    push dx
    
    mov ah, [READ_FILE]
    mov bx, [FILE_HANDLE]
    mov cx, 54
    mov dx, offset IMAGE_HEADER
    int 21h
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
endp

; Reads a BMP image palette
; output:
;       [IMAGE_PALETTE] - the BMP image palette
public read_image_palette
proc read_image_palette
    push ax
    push cx
    push dx
    
    mov ah, [READ_FILE]
    mov cx, 400h
    mov dx, offset IMAGE_PALETTE
    int 21h
    
    pop dx
    pop cx
    pop ax
    ret
endp

; Reads image palette to video memory
; and reorder the format to fit RGB
; first color -> port 3C8h
; the palette -> port 3C9h
public image_palette_to_vm
proc image_palette_to_vm
    push si
    push ax
    push dx
    
    mov si, offset IMAGE_PALETTE
    mov dx, 3C8h
    mov al, 0
    
    out dx, al
    inc dx
    
    mov cx, 100h
    @@loop:
        mov al, [si+2]
        shr al, 2 ; dividing by 4 since video palette max is 63 (while 255 in the default palette)
        out dx, al
        mov al, [si+1]
        shr al, 2
        out dx, al
        mov al, [si]
        shr al, 2
        out dx, al
        add si, 4
        
        loop @@loop
    
    pop dx
    pop ax
    pop si
    ret
endp

; reads and draws the BMP file line by line
; displaying the lines from bottom to top
; because of the way BMP graphics are saved
; (upside down)
public draw_image
proc draw_image
    push ax
    push cx
    
    mov ax, 0A00h
    mov es, ax
    
    mov cx, 200
    
    @@loop:
        push cx
        
        mov di, cx
        shl cx, 6
        shr di, 8
        add di, cx
        
        mov ah, [READ_FILE]
        mov cx, 320
        mov dx, offset IMAGE_LINE
        int 21h
        
        cld
        mov cx, 320
        mov si, offset IMAGE_LINE
        rep movsb
        
        pop cx
        loop @@loop
    
    pop cx
    pop ax
    ret
endp


; writes a 4 pixel square (e.g BIG pixel) at given position
; parameters:
;       [PXL_X] - pixel column (range: 0 - 320)
;       [PXL_Y] - pixel row (range: 0 - 200)
;       [COLOR] - pixel color
public write_qpixel
proc write_qpixel
    push ax
    push dx
    push si
     
    mov ax, 320
    mul [PXL_Y]
    add ax, [PXL_X]
    mov si, ax
    mov dl, [COLOR]
    mov [es:si], dl
     
    inc si
    mov [es:si], dl
    add si, 319
    mov [es:si], dl
    inc si
    mov [es:si], dl
     
    pop si
    pop dx
    pop ax
    ret
endp

; draws a double pixel in a vertical alignment at given position
; parameters:
;       [PXL_X] - pixel column (range: 0 - 320)
;       [PXL_Y] - pixel row (range: 0 - 200)
;       [COLOR] - pixel color
public draw_dpixel_vertical
proc draw_dpixel_vertical
    mov ah, [DRAW_PIXEL_CONST]
    mov al, [COLOR]
    mov cx, [PXL_X]
    mov dx, [PXL_Y]
    int 10h
    inc cx
    int 10h
    ret
endp

; draws a double pixel in a horizontal alignment at given position
; parameters:
;       [PXL_X] - pixel column (range: 0 - 320)
;       [PXL_Y] - pixel row (range: 0 - 200)
;       [COLOR] - pixel color
public draw_dpixel_horizontal
proc draw_dpixel_horizontal
    mov ah, [DRAW_PIXEL_CONST]
    mov al, [COLOR]
    mov cx, [PXL_X]
    mov dx, [PXL_Y]
    int 10h
    dec dx
    int 10h
    ret
endp
    
; draws a line of pixels in a horizontal alignment at given position
; parameters:
;       [PXL_X] - line start column position (range: 0 - 320)
;       [PXL_Y] - line start row position (range: 0 - 200)
;       [HLINE_SIZE] - line length
;       [COLOR] - pixel color
public draw_line_horizontal
proc draw_line_horizontal
    push [PXL_X]
    push [HLINE_SIZE]
    @@loop:
        call draw_pixel
        inc [PXL_X]
        dec [HLINE_SIZE]
        cmp [HLINE_SIZE], 0
        jg @@loop
    pop [HLINE_SIZE]
    pop [PXL_X]
    ret
endp

; draws a line of pixels from point A to B in accordance
; to given cartesian values using bresenham's line algorithm
; parameters:
;       [LINE_X0] - line start column position (range: 0 - 320)
;       [LINE_Y0] - line start row position (range: 0 - 200)
;       [LINE_X1] - line start column position (range: 0 - 320)
;       [LINE_Y1] - line start row position (range: 0 - 200)
;       [COLOR] - line color
public draw_line
proc draw_line
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push [PXL_X]
    push [PXL_Y]
    
    ; get delta y and delta x and store then in ax and bx respectively
    mov ax, [LINE_Y1]
    sub ax, [LINE_Y0]
    
    mov bx, [LINE_X1]
    sub bx, [LINE_X0]
     
    
    cmp ax,bx
    je @@specialcase
    jmp @@ignorespecialcase
    
    @@specialcase:
        mov cx, [LINE_X1]
        sub cx, [LINE_X0]
        mov ax, [LINE_X0]
        @@specialcaseloop:
            mov [PXL_X], ax
            mov [PXL_Y], ax
            call draw_pixel
            inc ax
            loop @@specialcaseloop
        jmp @@end
     
    @@ignorespecialcase:
        
    ; get point difference
    mov cx, ax
    sub cx, bx
    
    ; set starting y value (dx = y0) and start / end of line in si, di respectively
    mov dx, [LINE_Y0]
    
    mov si, [LINE_X0]
    mov di, [LINE_X1]
    dec di
    
@@loop:
    mov [PXL_X], si
    mov [PXL_Y], di
    call draw_pixel
    
    cmp cx, 0
    jge @@advanceYD
    cmp cx, 0
    jl @@continue
    
    @@advanceYD:
        inc di
        sub cx, bx
    
    @@continue:
        add cx, ax
        
        inc si
        cmp si, di
        jl @@loop
    
@@end:
    pop [PXL_Y]
    pop [PXL_X]
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
endp
    
; draws a line of pixels in a vertical alignment at given position
; parameters:
;       [PXL_X] - line start column position (range: 0 - 320)
;       [PXL_Y] - line start row position (range: 0 - 200)
;       [VLINE_SIZE] - line length
;       [COLOR] - line color
public draw_line_vertical
proc draw_line_vertical
    push [PXL_Y]
    push [VLINE_SIZE]
    @@loop:
        call draw_pixel
        inc [PXL_Y]
        dec [VLINE_SIZE]
        cmp [VLINE_SIZE], 0
        jg @@loop
    pop [PXL_Y]
    pop [VLINE_SIZE]
    ret
endp
   
; draws a line of BIG pixels in a horizontal alignment at given position
; parameters:
;       [PXL_X] - line start column position (range: 0 - 320)
;       [PXL_Y] - line start row position (range: 0 - 200)
;       [HLINE_SIZE] - line length
;       [COLOR] - pixel color
public draw_qline_horizontal
proc draw_qline_horizontal
    push [PXL_X]
    push [HLINE_SIZE]
    loopDQHL:
        call write_qpixel
        add [PXL_X], 2
        dec [HLINE_SIZE]
        cmp [HLINE_SIZE], 0
        jg loopDQHL
    pop [HLINE_SIZE]
    pop [PXL_X]
    ret
endp
    
; draws a line of BIG pixels in a vertical alignment at given position
; parameters:
;       [PXL_X] - line start column position (range: 0 - 320)
;       [PXL_Y] - line start row position (range: 0 - 200)
;       [VLINE_SIZE] - line length
;       [COLOR] - pixel color
public draw_qline_vertical
proc draw_qline_vertical
    push [PXL_Y]
    push [VLINE_SIZE]
    loopDQVL:
        call write_qpixel
        add [PXL_Y], 2
        dec [VLINE_SIZE]
        cmp [VLINE_SIZE], 0
        jg loopDQVL
    pop [PXL_Y]
    pop [VLINE_SIZE]
    ret
endp

; draws a square of pixel in accordance to given parameters
; NOTE: position is the top left corner of the square
; parameters:
;       [PXL_X] - square start column position (range: 0 - 320)
;       [PXL_Y] - square start row position (range: 0 - 200)
;       [SQR_SIZE] - size of the square
;       [COLOR] - color of the square
public draw_square
proc draw_square
    push [PXL_X]
    push [PXL_Y]
    push [SQR_SIZE]
    
    push ax
    mov ax, [SQR_SIZE]
    mov [COUNTER], ax
    pop ax
    
    loopDSY:
        push [PXL_X]
        push [COUNTER]
        loopDSX:
            call draw_pixel
            inc [PXL_X]
            dec [COUNTER]
            cmp [COUNTER], 0
            jg loopDSX
        pop [COUNTER]
        pop [PXL_X]
        
        inc [PXL_Y]
        dec [SQR_SIZE]
        cmp [SQR_SIZE], 0
        jg loopDSY
        
    pop [SQR_SIZE]
    pop [PXL_Y]
    pop [PXL_X]
    ret
endp

; draws a rectangle of pixel in accordance to given parameters
; NOTE: position is the top left corner of the rectangle
; parameters:
;       [PXL_X] - rectangle start column position (range: 0 - 320)
;       [PXL_Y] - rectangle start row position (range: 0 - 200)
;       [RCT_H] - height of the rectangle
;	[RCT_W] - width of the rectangle
;       [COLOR] - color of the rectangle
public draw_rect
proc draw_rect
    push [PXL_X]
    push [PXL_Y]
    push [RCT_W]
    push [RCT_H]
    
    loopDRY:
        push [PXL_X]
        push [RCT_W]
        loopDRX:
            call draw_pixel
            inc [PXL_X]
            dec [RCT_W]
            cmp [RCT_W], 0
            jg loopDRX
        pop [RCT_W]
        pop [PXL_X]
        
        inc [PXL_Y]
        dec [RCT_H]
        cmp [RCT_H], 0
        jg loopDRY
    pop [RCT_H]
    pop [RCT_W]
    pop [PXL_Y]
    pop [PXL_X]
    ret
endp

; draws an equalateral triangle in accordance to given parameters
; NOTE: position is bottom left corner of the triangle
; parameters:
;       [PXL_X] - triangle start column position (range: 0 - 320)
;       [PXL_Y] - triangle start row position (range: 0 - 200)
;       [TRI_SIZE] - triangle size (both base length and height)
;       [COLOR] - color of the triangle
public draw_triangle_equi
proc draw_triangle_equi
    push [PXL_X]
    push [PXL_Y]
    push [TRI_SIZE]
    
    loopDTE:
        push [PXL_X]
        push [TRI_SIZE]
        loopDTEL:
            call draw_pixel
            inc [PXL_X]
            dec [TRI_SIZE]
            cmp [TRI_SIZE], 0
            jg loopDTEL
        pop [TRI_SIZE]
        pop [PXL_X]
        dec [PXL_Y]
        inc [PXL_X]
        sub [TRI_SIZE], 2
        cmp [TRI_SIZE], 0
        jg loopDTE
    
    pop [TRI_SIZE]
    pop [PXL_Y]
    pop [PXL_X]
    ret
endp

; draws the sky via given color
; parameters:
;       [BG_COLOR] - the color of the sky
public draw_sky
proc draw_sky
     push [PXL_X]
     push [PXL_Y]
     push [RCT_H]
     push [RCT_W]
     push bx
     
     mov [RCT_H], 150
     mov [RCT_W], 320
     mov [PXL_X], 0
     mov [PXL_Y], 0
     mov bl, [BG_COLOR]
     mov [COLOR], bl
     call draw_rect
     
     pop bx
     pop [RCT_W]
     pop [RCT_H]
     pop [PXL_Y]
     pop [PXL_X]
     ret
endp

; draws the ground via given color
; parameter:
;       [GROUND_COLOR] - the color of the ground
public draw_ground
proc draw_ground
     push [PXL_Y]
     push [PXL_X]
     push [RCT_H]
     push [RCT_W]
     push bx
     
     mov [RCT_H], 50
     mov [RCT_W], 320
     mov [PXL_X], 0
     mov [PXL_Y], 150
     mov bl, [GROUND_COLOR]
     mov [COLOR], bl
     call draw_rect
     
     pop bx
     pop [RCT_W]
     pop [RCT_H]
     pop [PXL_X]
     pop [PXL_Y]
     ret
endp

; draws the sun
public draw_sun
proc draw_sun
    push [PXL_X]
    push [PXL_Y]
    push ax
    mov ax, [SUN_X]
    mov [PXL_X], ax
    mov ax, [SUN_Y]
    mov [PXL_Y], ax
    pop ax
    
    call color_to_yellow
    mov [SQR_SIZE], 27
    call draw_square
    
    pop [PXL_Y]
    pop [PXL_X]
    ret
endp

; draws the player
public draw_creature1
proc draw_creature1
     push ax
     mov ax, [PET1_X]
     mov [PXL_X], ax
     mov ax, [PET1_Y]
     mov [PXL_Y], ax
     pop ax

     ;===DRAWS BODY (BLUE PARTS)===
     ;ears
     add [PXL_X], 6
     push ax
     mov al, [PET_COLOR]
     mov [COLOR], al
     pop ax
     call write_qpixel
     add [PXL_X], 2
     call write_qpixel
     add [PXL_X], 10
     call write_qpixel
     add [PXL_X], 2
     call write_qpixel
     
     push ax
     mov ax, [PXL_Y]
     add ax, 3
     mov [COUNTER], ax
     pop ax
     
     loopDP11:
     add [PXL_Y], 2

     mov ax, [PET1_X]
     mov [PXL_X], ax
     add [PXL_X], 4
     call write_qpixel
     add [PXL_X], 6
     call write_qpixel
     add [PXL_X], 6
     call write_qpixel
     add [PXL_X], 6
     call write_qpixel

     push ax
     mov ax, [PXL_Y]
     cmp ax, [COUNTER]
     pop ax
     jl loopDP11
     
     sub [PXL_X], 2
     call write_qpixel
     sub [PXL_X], 2
     call write_qpixel
     sub [PXL_X], 10
     call write_qpixel
     sub [PXL_X], 2
     call write_qpixel
     
     ;body
     add [PXL_Y], 2

     call reset_creature1_pos_x

     add [PXL_X], 6
     mov [SQR_SIZE], 15
     call draw_square

     ;hands
     push ax
     mov ax, [PET1_Y]
     add ax, 9
     mov [WHOLDER1], ax
     pop ax
     push [WHOLDER1] ;for later use in the draw function
     call reset_creature1_pos_x
     push ax
     mov ax, [WHOLDER1]
     mov [PXL_Y], ax
     pop ax
     call write_qpixel
     add [PXL_X], 2
     add [PXL_Y], 2
     call write_qpixel
     add [PXL_X], 2
     add [PXL_Y], 2
     call write_qpixel
     add [PXL_X], 18
     call write_qpixel
     add [PXL_X], 2
     sub [PXL_Y], 2
     call write_qpixel
     add [PXL_X], 2
     sub [PXL_Y], 2
     call write_qpixel

     ;feet
     push ax
     mov ax, [PET1_Y]
     add ax, 21
     mov [WHOLDER1], ax
     pop ax
     call reset_creature1_pos_x
     push ax
     mov ax, [WHOLDER1]
     mov [PXL_Y], ax
     pop ax
     mov [COUNTER], 3
     add [PXL_X], 2
     push [COUNTER]
     loopDP13:
          call write_qpixel
          add [PXL_X], 2
          dec [COUNTER]
          cmp [COUNTER], 0
          jge loopDP13
     pop [COUNTER]
     add [PXL_X], 8
     loopDP14:
          call write_qpixel
          add [PXL_X], 2
          dec [COUNTER]
          cmp [COUNTER], 0
          jge loopDP14

     ;===Draw Details (Ears, Eyes, Exp. etc.)===

     push ax
     mov ax, [PET1_Y]
     add ax, 4
     mov [WHOLDER1], ax
     pop ax
     ;Ears
     call reset_creature1_pos_x
     push ax
     mov ax, [WHOLDER1]
     mov [PXL_Y], ax
     pop ax
     add [PXL_X], 6
     call color_to_pink
     call write_qpixel
     add [PXL_X], 2
     call write_qpixel
     add [PXL_X], 10
     call write_qpixel
     add [PXL_X], 2
     call write_qpixel
     sub [PXL_Y], 2
     call write_qpixel
     sub [PXL_X], 2
     call write_qpixel
     sub [PXL_X], 10
     call write_qpixel
     sub [PXL_X], 2
     call write_qpixel

     call reset_creature1_pos_x
     
    
     ;pop the holder from back then to refain from repeating
     ;the add 5 pxl to pet_y code again
     pop [WHOLDER1]
     
     ;Eyes
     call reset_creature1_pos_x
     call color_to_black
     push ax
     mov ax, [WHOLDER1]
     mov [PXL_Y], ax
     pop ax
     add [PXL_X], 8
     call write_qpixel
     call color_to_white
     add [PXL_X], 2
     call write_qpixel
     call color_to_black
     add [PXL_X], 6
     call write_qpixel
     call color_to_white
     add [PXL_X], 2
     call write_qpixel
     call color_to_black
     add [PXL_Y], 2
     call write_qpixel
     sub [PXL_X], 2
     call write_qpixel
     sub [PXL_X], 6
     call write_qpixel
     sub [PXL_X], 2
     call write_qpixel
     
     ;Mouth
     call color_to_red
     add [PXL_X], 2
     add [PXL_Y], 4
     call write_qpixel
     add [PXL_X], 2
     add [PXL_Y], 2
     call write_qpixel
     add [PXL_X], 2
     call write_qpixel
     add [PXL_X], 2
     sub [PXL_Y], 2
     call write_qpixel

     ret
endp

; draws the first tree
public draw_tree1
proc draw_tree1
    push ax
    mov ax, [TREE1_X]
    mov [PXL_X], ax
    mov ax, [TREE1_Y]
    mov [PXL_Y], ax
    pop ax
    
    ;draw leaves
    call color_to_green
    add [PXL_X], 12
    add [PXL_Y], 4
    sub [PXL_X], 4
    add [PXL_Y], 4
    mov [RCT_H], 8
    mov [RCT_W], 12
    call draw_rect
    sub [PXL_X], 4
    add [PXL_Y], 8
    add [RCT_W], 8
    call draw_rect
    sub [PXL_X], 4
    add [PXL_Y], 8
    add [RCT_W], 8
    call draw_rect
    add [PXL_Y], 8
    add [RCT_W], 4
    add [RCT_H], 4
    call draw_rect
    add [PXL_X], 8
    add [PXL_Y], 4
    call write_qpixel
    sub [PXL_X], 4
    sub [RCT_H], 4
    mov [RCT_W], 20
    call draw_rect
    
    ;draw stem
    call color_to_brown
    add [PXL_Y], 8
    add [PXL_X], 4
    mov [RCT_W], 12
    mov [RCT_H], 36
    call draw_rect
    
    ret
endp
    
; draws the first cloud
public draw_cloud1
proc draw_cloud1
    push ax
    mov ax, [CLOUD1_X]
    mov [PXL_X], ax
    mov ax, [CLOUD1_Y]
    mov [PXL_Y], ax
    pop ax
    
    ;draw cloud type 3
    call color_to_white
    add [PXL_X], 16
    mov [HLINE_SIZE], 12
    call draw_qline_horizontal
    add [PXL_Y], 2
    call draw_qline_horizontal
    add [PXL_Y], 2
    sub [PXL_X], 8
    mov [HLINE_SIZE], 24
    call draw_qline_horizontal
    add [PXL_Y], 2
    call draw_qline_horizontal
    add [PXL_Y], 2
    sub [PXL_X], 4
    mov [HLINE_SIZE], 36
    call draw_qline_horizontal
    add [PXL_Y], 2
    call draw_qline_horizontal
    add [PXL_Y], 2
    add [PXL_X], 4
    call draw_qline_horizontal
    add [PXL_Y], 2
    call draw_qline_horizontal
    ret
endp
    
; draws the second cloud
public draw_cloud2
proc draw_cloud2
    push ax
    mov ax, [CLOUD2_X]
    mov [PXL_X], ax
    mov ax, [CLOUD2_Y]
    mov [PXL_Y], ax
    pop ax
    
    ;draw cloud type 3
    call color_to_white
    add [PXL_X], 16
    mov [HLINE_SIZE], 12
    call draw_qline_horizontal
    add [PXL_Y], 2
    call draw_qline_horizontal
    add [PXL_Y], 2
    sub [PXL_X], 8
    mov [HLINE_SIZE], 24
    call draw_qline_horizontal
    add [PXL_Y], 2
    call draw_qline_horizontal
    add [PXL_Y], 2
    sub [PXL_X], 4
    mov [HLINE_SIZE], 36
    call draw_qline_horizontal
    add [PXL_Y], 2
    call draw_qline_horizontal
    add [PXL_Y], 2
    add [PXL_X], 4
    call draw_qline_horizontal
    add [PXL_Y], 2
    call draw_qline_horizontal
    ret
endp
    
; draws the third cloud
public draw_cloud3
proc draw_cloud3
    push ax
    mov ax, [CLOUD3_X]
    mov [PXL_X], ax
    mov ax, [CLOUD3_Y]
    mov [PXL_Y], ax
    pop ax
    
    ;draw cloud type 3
    call color_to_white
    add [PXL_X], 16
    mov [HLINE_SIZE], 12
    call draw_qline_horizontal
    add [PXL_Y], 2
    call draw_qline_horizontal
    add [PXL_Y], 2
    sub [PXL_X], 8
    mov [HLINE_SIZE], 24
    call draw_qline_horizontal
    add [PXL_Y], 2
    call draw_qline_horizontal
    add [PXL_Y], 2
    sub [PXL_X], 4
    mov [HLINE_SIZE], 36
    call draw_qline_horizontal
    add [PXL_Y], 2
    call draw_qline_horizontal
    add [PXL_Y], 2
    add [PXL_X], 4
    call draw_qline_horizontal
    add [PXL_Y], 2
    call draw_qline_horizontal
    ret
endp
  
; draws the pond
public draw_pond
proc draw_pond
    push ax
    mov ax, [POND_X]
    mov [PXL_X], ax
    mov ax, [POND_Y]
    mov [PXL_Y], ax
    pop ax
    
    ;draw pond
    call color_to_cyan
    add [PXL_X], 16
    mov [HLINE_SIZE], 12
    call draw_qline_horizontal
    add [PXL_Y], 2
    call draw_qline_horizontal
    add [PXL_Y], 2
    sub [PXL_X], 8
    mov [HLINE_SIZE], 24
    call draw_qline_horizontal
    add [PXL_Y], 2
    call draw_qline_horizontal
    add [PXL_Y], 2
    sub [PXL_X], 4
    mov [HLINE_SIZE], 36
    call draw_qline_horizontal
    add [PXL_Y], 2
    call draw_qline_horizontal
    add [PXL_Y], 2
    add [PXL_X], 4
    call draw_qline_horizontal
    add [PXL_Y], 2
    add [PXL_X], 3
    mov [HLINE_SIZE], 32
    call draw_qline_horizontal
    sub [PXL_Y], 12
    call draw_qline_horizontal
    add [PXL_Y], 2
    mov [HLINE_SIZE], 30
    call draw_qline_horizontal
    add [PXL_Y], 2
    mov [HLINE_SIZE], 28
    call draw_qline_horizontal
    ret
endp

; ===================
;		  EXAMPLES
; ===================

; The default runtime procedure
; should be referred to as a 
; reference of how should the 
; main game loop look like
public run
proc run
     call handle_input
     call wait_micro
     call draw_scene
     cmp [CLOSE_REQUESTED], FALSE
     jz run
     call set_text_mode
     call terminate_program
     ret
endp

; (IGNORE) used to draw the example scene
public draw_scene
proc draw_scene
    call draw_sky
    call draw_ground
    call draw_pond
    push ax
    push cx
    mov ax, [TREE1_Y]
    add ax, 80
    mov cx, [PET1_Y]
    add cx, 24
    cmp cx, ax
    jge @@petAbvTree1Label
    cmp cx, ax
    jl @@petBlwTree1Label
    
    @@petBlwTree1Label:
        pop cx
        pop ax
        call draw_creature1_below_tree
        
        jmp @@drawSkyDetailsLabel
    @@petAbvTree1Label:
        pop cx
        pop ax
        call draw_creature1_above_tree
        
        jmp @@drawSkyDetailsLabel
    
    @@drawSkyDetailsLabel:
    call draw_sky_details
    ret
endp draw_scene

; draws the creature above the first tree
public draw_creature1_above_tree
proc draw_creature1_above_tree
    call draw_tree1
    call draw_creature1
    ret
endp
    
; draws the creature below the first tree
public draw_creature1_below_tree
proc draw_creature1_below_tree
    call draw_creature1
    call draw_tree1
    ret
endp

; draws the sky details (sun and clouds)
public draw_sky_details
proc draw_sky_details
    call draw_sun
    call draw_clouds
    ret
endp
    
; draws the clouds and animates them when ran through a loop
public draw_clouds
proc draw_clouds
    call draw_cloud1
    dec [CLOUD1_X]
    call draw_cloud2
    dec [CLOUD2_X]
    call draw_cloud3
    dec [CLOUD3_X]
    ret
endp