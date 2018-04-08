.386
data segment use16
number	 dw  0,0
temp  dw 0,0
data ends
code segment use16
assume cs:code, ds:data
main:
    MOV ax, data
    MOV ds, ax
    CALL GET_NUMBER
    MOV AX, [number]
    MUL ds:[number+2]
    MOV [temp],AX

    MOV [temp+2],DX
    MOV EAX, dword ptr[temp]

    MOV EBX,10
    CALL OUTPUT

;ʮ������
    MOV EBX, 16
    CALL OUTPUT
    PUSH EAX
    MOV DL, 'h'
    MOV AH, 02H
    INT 21H
    POP EAX

;������
    MOV EBX, 2
    CALL OUTPUT_2
    PUSH EAX
    MOV DL, 'B'
    MOV AH, 02H
    INT 21H
    POP EAX

DONE:
    MOV AH,0
    INT 16h			;�ȴ����� (system pause)
    MOV AH,4Ch
    INT 21h			;return
 

 ;��ȡ��������&��ʼ��
GET_NUMBER:
    LEA   BX, number		;ȡ��ַ

IN_1:
    MOV   AH, 1
    INT   21H
    CMP   AL, '*'		;��һ�����ֽ��� *
    JE	  IN_finish_first
    CMP   AL, '='		;�ڶ������ֽ��� =
    JE	  IN_return

    CMP   AL, '0'		;��֤  char ��  '0' & '9' ��
    JB    IN_1
    CMP   AL, '9'
    JA    IN_1

    SUB   AL, '0'
    MOVSX EAX, AL		;��� the AL to 16b
    XCHG  [BX], EAX		;�� number[0] or number[1]��ȡ��������
    MOV   EDX, 10
    MUL   EDX			;10����
    ADD   [BX], AX
    
    JMP  IN_1
IN_return:
    RET
IN_finish_first:		;��һ�����ֶ�ȡ���
    ADD   BX, 2
    JMP   IN_1
    RET


;���EAX�� BX����
OUTPUT PROC NEAR
    PUSH EAX
    PUSH EDX

    MOV DL,0AH
    MOV AH,2
    INT 21H;����

    POP EDX
    POP EAX
    PUSH EAX
    PUSH EDX
    XOR CX,CX
 loop_devide:
    INC CX
    XOR EDX, EDX

    DIV EBX
    PUSH DX
    CMP EAX,0
    JNE loop_devide
 s:
    POP DX
    CALL PRINT_ASCII
 loop s
    POP EDX
    POP EAX
 RET
OUTPUT ENDP


;���EAX�� BX==2����
;���������Ҫ������ǰ���0������λ��һ����������д
OUTPUT_2 PROC NEAR
    PUSH EAX
    PUSH EDX

    MOV DL,0AH
    MOV AH,2
    INT 21H				;����

    POP EDX
    POP EAX

    PUSH EAX
    PUSH EDX
    XOR CX,CX
 loop_devide2:
    INC CX
    XOR EDX, EDX
    DIV EBX
    PUSH DX
    CMP CX,32				;������һ�����32λ
    JNE loop_devide2
 s2:
    POP DX
    CALL PRINT_ASCII

    PUSH AX
    PUSH DX

    CMP CX,1
    JE next2

    MOV AX,CX
    MOV DL,4
    DIV DL
    CMP AH,1
    JNE next2

;ÿ4λ����ո�
    MOV DL,' '
    MOV AH, 02H
    INT 21H

  next2:
    POP DX
    POP AX
 loop s2
    POP EDX
    POP EAX
 RET
OUTPUT_2 ENDP


 ;���Ĵ���DH��ֵ(0~F)->ASCII���
PRINT_ASCII PROC NEAR
    CMP DL, 9
    JA A_F				;���ֲ���ת ��ĸ��ת
    ADD DL, '0'				;ת��ΪASCII
    JMP finish				;���
A_F:					;����ĸ(����9)
    ADD DL, 'A'-0AH			;ת��ΪASCII
finish:					;���
    PUSH  AX
    MOV   AH, 02H
    INT   21H
    POP   AX
RET					;����
PRINT_ASCII ENDP 

code ends
end main