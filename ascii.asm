code segment
assume cs:code
main:
mov AX,0003H
int 10H			;clear the screen
			;ʹ�� 80x25 ��ɫ�ַ�ģʽ���ڴ��ַ 0xB8000 - 0xBFFFFF
mov AX,0B800H		;�� 0xB8000 ��ʼ
mov DS,AX	

xor BX,BX		;����		
xor DX,DX		;����

mov CX,11		;����������11

MAIN_LOOP:		;��ѭ��
    push BX
    push CX
    mov CX,25		;����������25
  s:				;��ѭ��,ÿ��ѭ�����һ��
    push DX 
    mov byte ptr ds:[BX],DL			;ASCII����
    mov byte ptr ds:[BX+1],0CH			;�ڵ׺���

    ROL DL,4					;��λȡֵ�ã��ƶ�4λ
    mov DH,DL
    and DH,0FH
    CALL GET_ASCII				;ת��ΪASCII
    mov byte ptr ds:[BX+2],DH			;��ʾ�ڶ�λ
    mov byte ptr ds:[BX+3],0AH			;�ڵ�����

    ROL DL,4					;��λȡֵ�ã��ƶ�4λ
    mov DH,DL
    and DH,0FH
    CALL GET_ASCII
    mov byte ptr ds:[BX+4],DH			;��ʾ��һλ
    mov byte ptr ds:[BX+5],0AH			;�ڵ�����

    add BX,160					;ÿ�������160
    pop DX
    inc DL					;ASCII���� ׼�������һλ
    cmp DL,0H					;��ȱ�ʾ�Ѿ������һȦ(�Ѿ�ȫ�����)
    je DONE					;������ѭ�� ׼������
  loop s


    pop CX
    pop BX
    add BX,0EH					;����7*2 ����֮�����7���ַ�λ
loop MAIN_LOOP

DONE:
mov ah,0
int 16h		;�ȴ������¼�
mov ah,4Ch
int 21h		;�˳�

;���Ĵ���DH��ֵ(0~F)->ASCII
GET_ASCII PROC NEAR
   CMP DH,9
   JA A_F		;���ֲ���ת ��ĸ��ת
   add DH,'0'		;ת��ΪASCII
   JMP finish		;���
A_F:			;����ĸ(����9)
   add DH,'A'-10	;ת��ΪASCII
			;���
finish:
RET			;����
GET_ASCII ENDP

code ends
end main