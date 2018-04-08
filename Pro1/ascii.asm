code segment
assume cs:code
main:
mov AX,0003H
int 10H			;clear the screen
			;使用 80x25 彩色字符模式，内存地址 0xB8000 - 0xBFFFFF
mov AX,0B800H		;从 0xB8000 开始
mov DS,AX	

xor BX,BX		;列数		
xor DX,DX		;计数

mov CX,11		;列数不超过11

MAIN_LOOP:		;主循环
    push BX
    push CX
    mov CX,25		;行数不超过25
  s:				;次循环,每次循环输出一列
    push DX 
    mov byte ptr ds:[BX],DL			;ASCII符号
    mov byte ptr ds:[BX+1],0CH			;黑底红字

    ROL DL,4					;移位取值用，移动4位
    mov DH,DL
    and DH,0FH
    CALL GET_ASCII				;转化为ASCII
    mov byte ptr ds:[BX+2],DH			;显示第二位
    mov byte ptr ds:[BX+3],0AH			;黑底绿字

    ROL DL,4					;移位取值用，移动4位
    mov DH,DL
    and DH,0FH
    CALL GET_ASCII
    mov byte ptr ds:[BX+4],DH			;显示第一位
    mov byte ptr ds:[BX+5],0AH			;黑底绿字

    add BX,160					;每两行相差160
    pop DX
    inc DL					;ASCII增加 准备输出下一位
    cmp DL,0H					;相等表示已经输出了一圈(已经全部输出)
    je DONE					;跳出主循环 准备结束
  loop s


    pop CX
    pop BX
    add BX,0EH					;增加7*2 两列之间相差7个字符位
loop MAIN_LOOP

DONE:
mov ah,0
int 16h		;等待键盘事件
mov ah,4Ch
int 21h		;退出

;将寄存器DH的值(0~F)->ASCII
GET_ASCII PROC NEAR
   CMP DH,9
   JA A_F		;数字不跳转 字母跳转
   add DH,'0'		;转化为ASCII
   JMP finish		;完成
A_F:			;是字母(大于9)
   add DH,'A'-10	;转化为ASCII
			;完成
finish:
RET			;返回
GET_ASCII ENDP

code ends
end main