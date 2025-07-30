      bl Name_input
      bl Number_input
      bl game_start
Name_input: 
;asks for the name of the player
      mov r0, #InputName
      str r0, .WriteString
      mov r1, #ReadInputName
      str r1, .ReadString
      str r1, .WriteString
      push {r1}
      ret
Number_input: 
;asks for the number of initial matchsticks for the game 
      mov r2, #Matchstick_no
      str r2, .WriteString
      ldr r3, .InputNum
      str r3, originalcount ;saves r3 for future use
      cmp r3, #10
      blt num_error     ;errors
      cmp r3, #100
      bgt num_error
      str r3, .WriteUnsignedNum
      push {r3}         ;pushes the r3 for use
      ret
game_start:
;displays player and the number of matchsticks
      pop {r3}          ;calls r3
      str r11, .ClearScreen
      bl DrawSystem     ;for the drawing of matchstick
      mov r5, #player_name
      str r5, .WriteString
      str r1, .WriteString
      mov r6, #match_stick
      str r6, .WriteString
      str r3, .WriteUnsignedNum
      bl player_info
      ret
num_error:              ;error
      mov r4, #readerror
      str r4, .WriteString
      b Number_input
      ret
player_info: 
      pop {r1}
; start of the game
      mov r7, #player_ingame
      str r7, .WriteString
      str r1, .WriteString
      mov r7, #matchstick_number
      str r7, .WriteString
      str r3, .WriteUnsignedNum
      mov r7, #matchstick_number_extended
      str r7, .WriteString
      cmp r3, #0
      bgt choose_number 
      push {r3}
      ret
choose_number:
;the players turn to choose the number of matchsticks to reduce
      mov r7, #player_ingame
      str r7, .WriteString
      str r1, .WriteString
      push {r1}
      mov r7, #choose_matchstick_number
      str r7, .WriteString
      ldr r8, .InputNum
;checking errors in the input
      cmp r8, #1
      blt choose_error 
      cmp r8, #7
      bgt choose_error
      cmp r8, r3
      bgt choose_error2
; calculate the total remaining matchsticks
      sub r3, r3, r8    ;draw the new number of matchsticks
      str r11, .ClearScreen
      bl DrawSystem 
;check for the win, loss or draw result
      cmp r3, #1
      blt draw
      beq win
      bl comp_turn 
comp_turn:              ;computers turn
      mov r7, #dp4      ;Load message for computer's turn
      str r7, .WriteString 
      ldr r8, .Random   ;Load random value
      and r8, r8, #7    ; Limit to range 1-7
      sub r3, r3, r8    ; Subtract random choice from matchsticks
      str r11, .ClearScreen
      bl DrawSystem
      cmp r3, #1        ; Check if any matchsticks left
      blt draw 
      beq loss          ;player loses
      bgt player_info   ;continue with player info
draw:                   ;if the game is draw
      mov r7, #DRAW
      str r7, .WriteString
      str r11, .ClearScreen
      b Retry
loss:                   ;if the game is a loss for the player
      mov r7, #lose
      str r7, .WriteString
      bl DrawSystem
      b Retry
win:                    ;player wins the game
      mov r7, #WIN
      str r7, .WriteString
      bl DrawSystem
      b Retry
choose_error:           ;error in initial matchstick input
      mov r7, #choose_matchstick_number_error
      str r7, .WriteString
      b choose_number
choose_error_1:         ;error in the player's turen machstick input
      mov r7, #choose_matchstick_number_error
      str r7, .WriteString
      b comp_turn
choose_error2:          ;error if the player's input is higher than the number of available matchsticks
      mov r7, #choose_matchstick_number_error2
      str r7, .WriteString
      b choose_number
Retry:
      ldr r3, originalcount
      push {r3}
      mov r0, #retry
      str r0, .WriteString
      mov r7, #ReadRetry
      str r7, .ReadString
      str r7, .WriteString
      ldrb r7, [r7]     ;loads 1 byte from input
      cmp r7, #121      ;ascii value of y
      beq game_start
      cmp r7, #89       ;ascii value of Y
      beq game_start
      cmp r7, #78       ;ascii value of N
      beq end
      cmp r7, #110      ; ascii value of n
      beq end
      mov r12, #retry_error
      str r12, .WriteString
      b Retry
end:
      mov r7, #game_over ;game over
      str r7, .WriteString
      str r11, .ClearScreen
      halt              ;end of program
DrawSystem:
      mov r0, #1        ;X coordinate
      mov r1, #1        ;Y coordinate
      mov r6, #0        ;Number of matchsticks drawn
      mov r11, #0       ;Line counter
      mov r12, #0       ;Matchsticks in the current line
drawMatchStick:
      mov r7, #.PixelScreen
;Draw the body
      mov r2, #0xd2b48c
      mov r9, #3        ;The number of pixels for the body
bodyLoop:
      add r0, r0, #1
;Calculate pixel index
      lsl r4, r0, #2 
      lsl r5, r1, #8 
      add r5, r5, r4    ;Get the pixel index
;Draw body pixel
      str r2, [r7+r5]
;Decrement the pixel count and check if it's greater than 0
      sub r9, r9, #1
      cmp r9, #0
      bgt bodyLoop
;Draw the head
      mov r2, #.black
      lsl r4, r0, #2 
      lsl r5, r1, #8 
      add r5, r5, r4    ;Get the pixel index
      str r2, [r7+r5]
;move to the next matchstick (add a 3-pixel distance)
      add r0, r0, #3
;Increment the number of matchsticks drawn
      add r6, r6, #1
      add r12, r12, #1
;Check if we've drawn the desired number of matchsticks
      cmp r6, r3
      beq EndDraw
;Check if we need to start a new line
      cmp r12, #10
      beq newLine
      b drawMatchStick
newLine:
;Start a new line (Y+4, X=1)
      add r1, r1, #4
      mov r0, #1
      add r11, r11, #1
      mov r12, #0       ;reset matchsticks in the current line
;Check if we've drawn all lines (up to 10)
      cmp r11, #10
      blt drawMatchStick
EndDraw:
      ret
InputName: .asciz "Please enter your name: "
ReadInputName: .block 128
ReadRetry: .block 1
originalcount: .word 0
Matchstick_no: .asciz "\nHow many matchsticks (10-100)?"
readerror: .asciz "\nPlease select a number from 10 to 100."
player_name: .asciz "\nPlayer name is "
player_ingame: .asciz "\nPlayer "
matchstick_number: .asciz ", there are "
matchstick_number_extended: .asciz "matchsticks remaining"
match_stick: .asciz "\nMatchsticks: "
choose_matchstick_number: .asciz ", how many matchsticks do you want to remove (1-7)?"
choose_matchstick_number_error:.asciz "\nPlease choose a number between 1 and 7"
choose_matchstick_number_error2: .asciz "\nThe chosen number is larger than the remaining matchsticks, please choose another number."
game_over: .asciz "\nGAME OVER"
DRAW: .asciz "\nDraw"
lose: .asciz "\nYou lose"
WIN:  .asciz "\nYou win"
dp4:  .asciz "\nComputer's Turn"
retry: .asciz "\nPlay again (y/n)"
retry_error: .asciz "\nWrong input."
