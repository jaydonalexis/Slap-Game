cseg

; When using a 22.1184MHz crystal in fast mode
; one cycle takes 1.0 / 22.1184 MHz = 45.21123 ns

; Wait 40 microseconds
Wait_Forty_Micro_Seconds:
    push AR0
    mov R0, #177
L0: 
    nop
    nop
    ; 1 + 1 + 3 cycles -> 5 * 45.21123 ns * 177 = 40 us
    djnz R0, L0
    pop AR0
    ret

; Wait 'R2' milliseconds
Wait_Milli_Seconds mac
    push AR2
    mov R2, %0
    lcall ?Wait_Milli_Seconds
    pop AR2
endmac

?Wait_Milli_Seconds:
    push AR0
    push AR1
L3: mov R1, #45
L2: mov R0, #166
; 3 cycles -> 3 * 45.21123 ns * 166 = 22.51519 us
L1: djnz R0, L1
    ; 22.51519 us * 45 = 1.013 ms
    djnz R1, L2
    ; number of milliseconds to wait passed in R2
    djnz R2, L3
    pop AR1
    pop AR0
    ret
    
; Toggles the 'E' pin of the LCD module
LCD_Pulse:
    setb LCD_E
    lcall Wait_Forty_Micro_Seconds
    clr LCD_E
    ret

; Writes acc to LCD in 4-bit mode
LCD_Byte:
    ; Write high 4 bits first
    mov c, ACC.7
    mov LCD_D7, c
    mov c, ACC.6
    mov LCD_D6, c
    mov c, ACC.5
    mov LCD_D5, c
    mov c, ACC.4
    mov LCD_D4, c
    lcall LCD_Pulse
    lcall Wait_Forty_Micro_Seconds
    ; Write low 4 bits next
    mov c, ACC.3
    mov LCD_D7, c
    mov c, ACC.2
    mov LCD_D6, c
    mov c, ACC.1
    mov LCD_D5, c
    mov c, ACC.0
    mov LCD_D4, c
    lcall LCD_Pulse
    ret

; Write data to LCD
Write_Data mac
    mov a, %0
    lcall ?Write_Data
endmac
    
?Write_Data:
    setb LCD_RS
    ljmp LCD_Byte

; Write command to LCD
Write_Command mac
    mov a, %0
    lcall ?Write_Command
endmac

?Write_Command:
    clr LCD_RS
    ljmp LCD_Byte

; Configure LCD in 4-bit mode
LCD_4BIT:
    ; Resting state of LCD's enable pin is zero
    clr LCD_E
    
    ; First make sure the LCD is in 8-bit mode and then change to 4-bit mode
    Write_Command(#0x33)
    Write_Command(#0x33)
    Write_Command(#0x32) ; change to 4-bit mode

    ; Configure the LCD
    Write_Command(#0x28)
    Write_Command(#0x0c)
    Write_Command(#0x01) ;  Clear screen command

    ; Wait for the clear screen command to finish.
    Wait_Milli_Seconds(#2)
    ret

; Send a constant string to LCD
Send_Constant_String mac
    push dph
    push dpl
    push acc
    mov dptr, %0
    lcall ?Send_Constant_String
    pop acc
    pop dpl
    pop dph
endmac

?Send_Constant_String:
    clr a
    movc a, @a+dptr
    jz ?Send_Constant_String_Done
    lcall ?Write_Data
    inc dptr
    sjmp ?Send_Constant_String
?Send_Constant_String_Done:
    ret	

; Set LCD cursor at row, column
Set_Cursor mac
    push acc
    mov a, #%1
    dec a
    lcall ?Set_Cursor_%0 ; Select column and row
    pop acc
endmac

?Set_Cursor_2:
    orl a, #01000000B
?Set_Cursor_1:
    orl a, #10000000B
    ljmp ?Write_Command ; Select column and row

; Display a BCD number in the LCD
Display_BCD mac
    push ar0
    mov r0, %0
    lcall ?Display_BCD
    pop ar0
endmac

?Display_BCD:
    push acc
    ; Write most significant digit
    mov a, r0
    swap a
    anl a, #0fh
    orl a, #30h
    lcall ?Write_Data
    ; write least significant digit
    mov a, r0
    anl a, #0fh
    orl a, #30h
    lcall ?Write_Data
    pop acc
    ret

; Display a char in the LCD
Display_Char mac
    push acc
    mov a, %0
    lcall ?Write_Data
    pop acc
endmac

    