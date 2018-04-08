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

;十六进制
    MOV EBX, 16
    CALL OUTPUT
    PUSH EAX
    MOV DL, 'h'
    MOV AH, 02H
    INT 21H
    POP EAX

;二进制
    MOV EBX, 2
    CALL OUTPUT_2
    PUSH EAX
    MOV DL, 'B'
    MOV AH, 02H
    INT 21H
    POP EAX

DONE:
    MOV AH,0
    INT 16h			;等待输入 (system pause)
    MOV AH,4Ch
    INT 21h			;return
 

 ;读取键盘输入&初始化
GET_NUMBER:
    LEA   BX, number		;取地址

IN_1:
    MOV   AH, 1
    INT   21H
    CMP   AL, '*'		;第一个数字结束 *
    JE	  IN_finish_first
    CMP   AL, '='		;第二个数字结束 =
    JE	  IN_return

    CMP   AL, '0'		;保证  char 在  '0' & '9' 间
    JB    IN_1
    CMP   AL, '9'
    JA    IN_1

    SUB   AL, '0'
    MOVSX EAX, AL		;填充 the AL to 16b
    XCHG  [BX], EAX		;从 number[0] or number[1]读取已有数字
    MOV   EDX, 10
    MUL   EDX			;10进制
    ADD   [BX], AX
    
    JMP  IN_1
IN_return:
    RET
IN_finish_first:		;第一个数字读取完毕
    ADD   BX, 2
    JMP   IN_1
    RET


;输出EAX的 BX进制
OUTPUT PROC NEAR
    PUSH EAX
    PUSH EDX

    MOV DL,0AH
    MOV AH,2
    INT 21H;换行

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


;输出EAX的 BX==2进制
;二进制输出要保留最前面的0并且四位空一格所以另外写
OUTPUT_2 PROC NEAR
    PUSH EAX
    PUSH EDX

    MOV DL,0AH
    MOV AH,2
    INT 21H				;换行

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
    CMP CX,32				;二进制一定输出32位
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

;每4位输出空格
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


 ;将寄存器DH的值(0~F)->ASCII输出
PRINT_ASCII PROC NEAR
    CMP DL, 9
    JA A_F				;数字不跳转 字母跳转
    ADD DL, '0'				;转化为ASCII
    JMP finish				;完成
A_F:					;是字母(大于9)
    ADD DL, 'A'-0AH			;转化为ASCII
finish:					;完成
    PUSH  AX
    MOV   AH, 02H
    INT   21H
    POP   AX
RET					;返回
PRINT_ASCII ENDP 

code ends
end main