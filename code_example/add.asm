ASSUME  CS:CODE, DS:DATA
DATA   SEGMENT
    MSG1   DB  13, 10, 'Please  input  number_1: $'
    MSG2   DB  13, 10, 'Please  input  number_2: $'
    CRLF   DB  13, 10, '$'
    NN     DB  ?, ?
    MM     DB  ?
DATA   ENDS


CODE   SEGMENT
START:
    MOV   AX, DATA
    MOV   DS, AX
    LEA   DX, MSG1
    MOV   AH, 9
    INT   21H
    CALL  IN_CHAR
    MOV   MM, AL
    LEA   DX, MSG2
    MOV   AH, 9
    INT   21H
    CALL  IN_CHAR
    MOV   NN, AL
    LEA   DX, CRLF
    MOV   AH, 9
    INT   21H
    MOV   AL, MM
    CALL  OUT_NUM
    MOV   DL, '+'
    MOV   AH, 2
    INT   21H
    MOV   AL, NN
    CALL  OUT_NUM
    MOV   DL, '='
    MOV   AH, 2
    INT   21H
    MOV   AL, NN
    ADD   AL, MM
    MOV   AH, 0
    ADC   AH, 0
    CALL  OUT_1
EXIT:
    MOV   AH, 4CH
    INT   21H      
IN_CHAR:
    LEA   BX, NN
    MOV   CX, 2
IN_1:
    MOV   AH, 1
    INT   21H
    CMP   AL, '0'
    JB    IN_1
    CMP   AL, 'F'
    JA    IN_1
    CMP   AL, '9'
    JBE   _09
    CMP   AL, 'A'
    JB    IN_1
    SUB   AL, 7
_09:
    SUB   AL, 30H
    MOV   [BX], AL
    INC   BX
    LOOP  IN_1
    XCHG  AL, NN
    MOV   BL, 16
    MUL   BL
    ADD   AL, NN
    RET
OUT_NUM:
    MOV   AH, 0
OUT_1:
    MOV   DX, 0
    MOV   BX, 100
    DIV   BX
    XCHG  AX, DX
    CALL  OUT_CHAR
    MOV   DX, 0
    MOV   BX, 10
    DIV   BX
    XCHG  AX, DX
    CALL  OUT_CHAR
    MOV   DL, AL
    CALL  OUT_CHAR
    RET
OUT_CHAR:
    PUSH  AX
    ADD   DL, 30H
    MOV   AH, 2
    INT   21H
    POP   AX
    RET
CODE   ENDS
    END  START