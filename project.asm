.MODEL SMALL                 ; Use SMALL memory model (1 code segment + 1 data segment)
.STACK 100h                  ; Allocate 256 bytes for stack

.DATA
; ================= MENU TEXT =================
menu    DB 13,10,"----- 8086 SIGNED CALCULATOR -----",13,10
        DB "1. Addition",13,10
        DB "2. Subtraction",13,10
        DB "3. Multiplication",13,10
        DB "4. Division",13,10
        DB "5. Exit",13,10
        DB "Select option: $"     ; '$' terminates string for DOS print

; ================= PROMPT MESSAGES =================
msg1    DB 13,10,"Enter first number: $"
msg2    DB 13,10,"Enter second number: $"
result  DB 13,10,"Result = $"
newline DB 13,10,"$"

; ================= ERROR MESSAGE =================
div0msg DB 13,10,"Error: Division by zero is not allowed!",13,10,"$"

; ================= VARIABLES =================
choice  DB ?                 ; Stores menu choice (1–5)
num1    DW ?                 ; First signed number
num2    DW ?                 ; Second signed number
res     DW ?                 ; Stores calculation result

.CODE
MAIN:
    MOV AX, @DATA            ; Load data segment address
    MOV DS, AX               ; Initialize DS register

; ================= MENU LOOP =================
MENU_SHOW:
    LEA DX, menu             ; Load address of menu string
    CALL PRINT               ; Display menu

    CALL READ_CHAR           ; Read menu choice (single key)
    SUB AL, '0'              ; Convert ASCII to numeric value
    MOV choice, AL           ; Save choice

    CMP AL, 5                ; Check if choice == 5 (Exit)
    JE EXIT                  ; If yes, terminate program

    ; -------- Read first number --------
    LEA DX, msg1             ; Prompt message
    CALL PRINT
    CALL READ_NUM            ; Read signed number
    MOV num1, AX             ; Store first number

    ; -------- Read second number --------
    LEA DX, msg2
    CALL PRINT
    CALL READ_NUM
    MOV num2, AX             ; Store second number

    MOV AX, num1             ; Load first number into AX

    ; -------- Operation selection --------
    CMP choice, 1
    JE ADDITION
    CMP choice, 2
    JE SUBTRACTION
    CMP choice, 3
    JE MULTIPLICATION
    CMP choice, 4
    JE DIVISION
    JMP MENU_SHOW            ; Invalid choice → show menu again

; ================= ARITHMETIC OPERATIONS =================
ADDITION:
    ADD AX, num2             ; AX = num1 + num2
    JMP SHOW

SUBTRACTION:
    SUB AX, num2             ; AX = num1 - num2
    JMP SHOW

MULTIPLICATION:
    IMUL num2                ; Signed multiplication (AX = num1 * num2)
    JMP SHOW

DIVISION:
    CMP num2, 0              ; Check division by zero
    JNE DO_DIV
    LEA DX, div0msg          ; Show error message
    CALL PRINT
    JMP MENU_SHOW

DO_DIV:
    CWD                      ; Sign-extend AX into DX
    IDIV num2                ; Signed division (AX = quotient)
    JMP SHOW

; ================= DISPLAY RESULT =================
SHOW:
    MOV res, AX              ; Save result
    LEA DX, result
    CALL PRINT               ; Print "Result = "
    MOV AX, res
    CALL PRINT_NUM           ; Print signed result
    LEA DX, newline
    CALL PRINT
    JMP MENU_SHOW            ; Return to menu

; ================= PROGRAM EXIT =================
EXIT:
    MOV AH, 4Ch              ; DOS terminate program
    INT 21h

; =================================================
; PRINT: Prints $-terminated string at DS:DX
; Uses DOS interrupt 21h function 09h
; =================================================
PRINT PROC
    MOV AH, 09h
    INT 21h
    RET
PRINT ENDP

; =================================================
; READ_CHAR: Reads a single character from keyboard
; Uses DOS interrupt 21h function 01h
; =================================================
READ_CHAR PROC
    MOV AH, 01h
    INT 21h
    RET
READ_CHAR ENDP

; =================================================
; READ_NUM: Reads a signed decimal number into AX
; Supports negative numbers using '-' sign
; =================================================
READ_NUM PROC
    XOR BX, BX               ; Clear BX (digit holder)
    XOR CX, CX               ; CX = accumulated value
    MOV SI, 1                ; SI = sign (1 = positive)

    MOV AH, 01h
    INT 21h                  ; Read first character

    CMP AL, '-'              ; Check for negative sign
    JNE READ_LOOP
    MOV SI, -1               ; Mark number as negative
    MOV AH, 01h
    INT 21h                  ; Read next character

READ_LOOP:
    CMP AL, 13               ; Enter key pressed?
    JE DONE_READ

    SUB AL, '0'              ; Convert ASCII to digit
    MOV BL, AL               ; Save digit

    MOV AX, CX               ; AX = current number
    MOV DX, 10
    MUL DX                   ; AX = CX * 10
    ADD AX, BX               ; AX = AX + digit

    MOV CX, AX               ; Store back in CX

    MOV AH, 01h
    INT 21h                  ; Read next character
    JMP READ_LOOP

DONE_READ:
    MOV AX, CX               ; Move final value to AX
    CMP SI, 1                ; Apply sign
    JE OK
    NEG AX                   ; Make number negative
OK:
    RET
READ_NUM ENDP

; =================================================
; PRINT_NUM: Prints signed 16-bit number in AX
; =================================================
PRINT_NUM PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    OR AX, AX                ; Check sign
    JNS POSITIVE

    MOV DL, '-'              ; Print minus sign
    MOV AH, 02h
    INT 21h
    NEG AX                   ; Convert to positive

POSITIVE:
    XOR CX, CX               ; Digit counter
    MOV BX, 10               ; Base 10

DIGIT_LOOP:
    XOR DX, DX
    DIV BX                   ; AX = AX / 10, DX = remainder
    PUSH DX                  ; Save digit
    INC CX
    OR AX, AX
    JNE DIGIT_LOOP

PRINT_LOOP:
    POP DX
    ADD DL, '0'              ; Convert digit to ASCII
    MOV AH, 02h
    INT 21h
    LOOP PRINT_LOOP

    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_NUM ENDP

END MAIN