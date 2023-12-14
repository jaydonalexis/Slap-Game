$NOLIST
$MODLP51
$LIST

CLK                   EQU 22118400 					
TIMER0_RATE_LOW       EQU 2000   
TIMER0_RELOAD_LOW     EQU ((65536-(CLK/TIMER0_RATE_LOW)))  					
TIMER0_RATE_HIGH      EQU 2100
TIMER0_RELOAD_HIGH    EQU ((65536-(CLK/TIMER0_RATE_HIGH)))
TIMER0_RATE_WAIT      EQU 1000
TIMER0_RELOAD_WAIT    EQU ((65536-(CLK/TIMER0_RATE_HIGH)))
TIMER1_RATE           EQU 1000
TIMER1_RELOAD         EQU ((65536-(CLK/TIMER1_RATE)))
STEADY_STATE          EQU
WINNING_SCORE         EQU 5
SOUND_OUT             EQU P1.1
SEED_GENERATOR        EQU P4.5

; Reset vector
org 0000H
   ljmp Start
   
; Timer/Counter 0 overflow interrupt vector
org 0x000B
    ljmp Timer0_ISR

; Timer/Counter 1 overflow interrupt vector
org 0x001B
    ljmp Timer1_ISR

; Timer/Counter 2 overflow interrupt vector
org 0x002B
    ljmp Timer2_ISR

; These register definitions needed by 'math32.inc'
DSEG at 30H
x:   ds 4
y:   ds 4
seed: ds 4
bcd: ds 5
t2ov: ds 2
t1ov: ds 2
t0ov: ds 0
player1: ds 1
player2: ds 1

; Bit/boolean variables to help control program flow
BSEG
tone: dbit 1
mf: dbit 1
game: dbit 1
go_to_wait: dbit 1
score_to_update: dbit 1

; Include necessary files
$NOLIST
$include(math32.inc)
$include(LCD_4bit.inc)
$LIST

CSEG
; These 'equ' must match the hardware wiring
LCD_RS equ P2.6
; LCD_RW equ PX.X ; Not used in this code, connect the pin to GND
LCD_E  equ P2.7
LCD_D4 equ P3.4
LCD_D5 equ P3.5
LCD_D6 equ P2.5
LCD_D7 equ P2.3

; LCD messages
Initial_Message_Top:    db 'Player 1: 0', 0
Initial_Message_Bottom: db 'Player 2: 0', 0
Clear:                  db '                ', 0
Player1_Message:        db 'Player One Won!', 0
Player2_Message:        db 'Player Two Won!', 0

Display_10_digit_BCD:
    Display_BCD(bcd+4)
    Display_BCD(bcd+3)
    Display_BCD(bcd+2)
    Display_BCD(bcd+1)
    Display_BCD(bcd+0)
    ret

; Initializes timer/counter 0 as a 16-bit timer
Init_Timer0:
    mov a, TMOD
    anl a, #0x00
    orl a, #0x01
    mov TMOD, a
    setb ET0
    ; Disable timer so that transducer does not produce sound
    clr TR0
    ret

; Interrupt service routine for timer 0
Timer0_ISR:
push acc
push psw
jz go_to_wait, Waiting_Period
    cpl SOUND_OUT
    reti

Waiting_Period:
    inc t0ov+0
    mov a, t0ov+0
    jnz Compare
    inc t0ov+1

Compare:
    mov a, t0ov+0
    cjne a, #low(4000), Timer0_ISR_Done
    mov a, t0ov+1
    cjne a, #high(4000), Timer0_ISR_Done
    clr go_to_wait

Timer0_ISR_Done:
    pop acc
    pop psw
    reti

; Initializes timer/counter 1
Init_Timer1:
    mov a, TMOD
    orl a, #0x10
    mov TMOD, a
    mov TH1, #high(TIMER1_RELOAD)
    mov TL1, #low(TIMER1_RELOAD)
    mov RH1, #0
    mov RL1, #0
    setb ET1
    clr TR1
    ret

; Interrupt service routine for timer 1
Timer1_ISR:
    push acc
    push psw
    inc t1ov+0
    mov a, t1ov+0
    jnz Timer1_ISR_Done
    inc t1ov+1

Timer1_ISR_Done:
    pop acc
    pop psw
    reti

; Initializes timer/counter 2
Init_Timer2:
    mov T2CON, #0
    mov RCAP2H, #0
    mov RCAP2L, #0
    clr ET2
    clr TR2
    ret

; Interrupt service routine for timer 2
Timer2_ISR:
    clr TF2
    push acc
    inc t2ov+0
    mov a, t2ov+0
    jnz Timer2_ISR_Done
    inc t2ov+1

Timer2_ISR_Done:
    pop acc
    reti

; Hardware initialization
Initialize_All:
    lcall Init_Timer0
    lcall Init_Timer1
    lcall Init_Timer2
    lcall LCD_4BIT
    setb EA
    ret

; Seed for random number generation
Initial_Seed:
    setb TR2
    jb SEED_GENERATOR, $
    mov seed+0, TH2
    mov seed+1, #0x20
    mov seed+2, #0x81
    mov seed+3, TL2
    clr TR2
    ret

; Main program loop
; Generate random number
Random:
    mov x+0, seed+0
    mov x+1, seed+1
    mov x+2, seed+2
    mov x+3, seed+3
    load_y(214013)
    lcall mul32
    load_y(2531011)
    lcall add32
    mov seed+0, x+0
    mov seed+1, x+1
    mov seed+2, x+2
    mov seed+3, x+3
    ret 

; Wait arbitrary amount of time
Wait_Random:
    Wait_Milli_Seconds(seed+0)
    Wait_Milli_Seconds(seed+1)
    Wait_Milli_Seconds(seed+2)
    Wait_Milli_Seconds(seed+3)
    Wait_Milli_Seconds(seed+0)
    Wait_Milli_Seconds(seed+1)
    Wait_Milli_Seconds(seed+2)
    Wait_Milli_Seconds(seed+3)
    Wait_Milli_Seconds(seed+0)
    Wait_Milli_Seconds(seed+1)
    Wait_Milli_Seconds(seed+2)
    Wait_Milli_Seconds(seed+3)
    Wait_Milli_Seconds(seed+0)
    Wait_Milli_Seconds(seed+1)
    Wait_Milli_Seconds(seed+2)
    Wait_Milli_Seconds(seed+3)
    Wait_Milli_Seconds(seed+0)
    Wait_Milli_Seconds(seed+1)
    Wait_Milli_Seconds(seed+2)
    Wait_Milli_Seconds(seed+3)
       Wait_Milli_Seconds(seed+0)
    Wait_Milli_Seconds(seed+1)
    Wait_Milli_Seconds(seed+2)
    Wait_Milli_Seconds(seed+3)
    ret
    
Game_Select:
    mov TMOD, #20H
    mov TH1, #-6
    mov SCON, #50H
    setb TR1
Wait:
    jnb RI, Wait
    mov a, SBUF
    mov x+0, a
    mov x+1, #0
    mov x+2, #0
    mov x+3, #0
    load_y(#1)
    lcall x_eq_y
    ret

; Start of game
Start:
    ; Initialize the hardware:
    mov SP, #7FH
    lcall Game_Select
    lcall Initialize_All
    setb P0.0 ; Pin is used as input for timer 2
    setb P0.1 ; Pin is used as input for timer 1
    jb mf, Rapid_Touch
    
Sound_Off:
    lcall Initial_Seed
    setb ET2
    Set_Cursor(1, 1)
    Send_Constant_String(#Initial_Message_Top)
    Set_Cursor(2, 1)
    Send_Constant_String(#Initial_Message_Bottom)
    mov player1, #0
    mov player2, #0
    
Sound_Off_Forever:
    lcall Random
    mov a, seed+1
    mov c, acc.3
    jc Tone_High

; Play 2000 Hz tone
Tone_Low:
    mov TH0, #high(TIMER0_RELOAD_LOW)
    mov TL0, #low(TIMER0_RELOAD_LOW)
    ; Set autoreload value
    mov RH0, #high(TIMER0_RELOAD_LOW)
    mov RL0, #low(TIMER0_RELOAD_LOW)
    lcall Wait_Random
    setb TR0
    sjmp Tone_Off

; Play 2100 Hz tone
Tone_High:
    mov TH0, #high(TIMER0_RELOAD_HIGH)
    mov TL0, #high(TIMER0_RELOAD_HIGH)
    ; Set autoreload value
    mov RH0, #high(TIMER0_RELOAD_HIGH)
    mov RL0, #low(TIMER0_RELOAD_HIGH)
    lcall Wait_Random
    setb TR0
    sjmp Tone_Off

Tone_Off:
    Wait_Milli_Seconds(#255)
    Wait_Milli_Seconds(#255)
    Wait_Milli_Seconds(#100)
    clr TR0

Wait_For_Input:
    setb go_to_wait
    mov TH0, #high(TIMER0_RELOAD_WAIT)
    mov TL0, #low(TIMER0_RELOAD_WAIT)
    mov RH0, #0
    mov RL0, #0
    mov t0ov+0, #0
    mov t0ov+1, #0
    clr TF0
    setb TR0

Waiting:
    clr TR1
    mov TL1, #0
    mov TH1, #0
    mov t1ov+0, #0
    mov t1ov+1, #0
    clr TF1
    setb TR1

Synch1_TR1:
    jb P0.1, Synch1_TR1

Synch2_TR1:
    jnb P0.1, Synch2_TR1

    clr TR1
    mov TL1, #0
    mov TH1, #0
    mov t1ov+0, #0
    mov t1ov+1, #0
    clr TF1
    setb TR1

Measure1_TR1:
    jb P0.1, Measure1_TR1

Measure2_TR1:
    jnb P0.1, Measure2_TR1
    clr TR1

    clr TR2
    mov TL2, #0
    mov TH2, #0
    mov t2ov+0, #0
    mov t2ov+1, #0
    clr TF2
    setb TR2

Synch1_TR2:
    jb P0.0, Synch1_TR2

Synch2_TR2:
    jnb P0.0, Synch2_TR2

    clr TR2
    mov TL2, #0
    mov TH2, #0
    mov t2ov+0, #0
    mov t2ov+1, #0
    clr TF2
    setb TR2

Measure1_TR2:
    jb P0.0, Measure1_TR2

Measure2_TR2:
    jnb P0.0, Measure2_TR2
    clr TR2

    mov x+0, TL1
    mov x+1, TH1
    mov x+2, t1ov+0
    mov x+3, t1ov+1
    load_y(STEADY_STATE)
    lcall x_gt_y
    setb score_to_update
    jb mf, Done_Waiting

    mov x+0, TL2
    mov x+1, TH2
    mov x+2, t2ov+0
    mov x+3, t2ov+1
    load_y(STEADY_STATE)
    lcall x_gt_y
    clr score_to_update
    jb mf, Done_Waiting
    ljmp Still_Waiting

; At this point, the periods are stored in their respective registers
; Determine what the steady state value is and compare the values
; stored in the registers to this steady state value to see whether
; either player should gain a point

Done_Waiting:
    jb score_to_update, Update_Player1

; Update player 2 score in memory and on display
Update_Player2:
    inc player2
    Set_Cursor(2, 11)
    Display_BCD(player2)
    clr go_to_wait
    sjmp Still_Waiting

; Update player 1 score in memory and on display
Update_Player1:
    inc player1
    Set_Cursor(1, 11)
    Display_BCD(player1)
    clr go_to_wait
    sjmp Still_Waiting

; Still waiting for player input
Still_Waiting:
    jz go_to_wait, Waiting

; Check if either player has won
Continue:
    clr TF0
    clr TR0

    mov a, player1
    cjne a, WINNING_SCORE, Check_Player2
    ljmp Player1_Won

Check_Player2:
    mov a, player2
    cjne a, WINNING_SCORE, Game_Still_In_Progress
    ljmp Player2_Won

; Neither player has won yet
Game_Still_In_Progress:
    ljmp Sound_Off_Forever

; Indicate that player 1 has won on the display
Player1_Won:
    Set_Cursor(1, 1)
    Send_Constant_String(#Player1_Message)
    sjmp Complete

; Indicate that player 2 has won on the display
Player2_Won:
    Set_Cursor(2, 1)
    Send_Constant_String(#Player2_Message)
    sjmp Complete
    
Rapid_Touch:
    sjmp Rapid_Touch

Complete:
    sjmp Complete
end
