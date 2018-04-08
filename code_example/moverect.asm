data segment
clkintseg     dw ?;   ԭ����ʱ���жϷ������ε�ַ
clkintoff     dw ?;   ԭ����ʱ���жϷ������ƫ�Ƶ�ַ
keyintseg     dw ?;   ԭ���ļ����жϷ������ε�ַ
keyintoff     dw ?;   ԭ���ļ����жϷ������ƫ�Ƶ�ַ
esc_key_state db 1;   ESC ��״̬
direct_x      db 1;   ˮƽ�ƶ�����-1 ��ʾ����1 ��ʾ����
direct_y      db 1;   ��ֱ�ƶ�����-1 ��ʾ���ϣ�1 ��ʾ����
cur_x         dw 150; С����ĵ�ǰ�����
cur_y         dw 90;  С����ĵ�ǰ������
data ends

code segment
assume cs:code, ds:data

main:
   mov ax, data
   mov ds, ax
   call vga13h;  ���� VGA13h ͼ��ģʽ
   call drawbox; ��С����
   cli; �ر��ж�
   ;�����жϷ������
   ;ʱ���ж�
   mov ax, 3508h
   int 21h
   mov clkintseg, es
   mov clkintoff, bx
   push ds
   mov ax, seg clkintproc
   mov ds, ax
   mov dx, offset clkintproc
   mov ax, 2508h
   int 21h
   pop ds
   ;�����ж�
   mov ax, 3509h
   int 21h
   mov keyintseg, es
   mov keyintoff, bx
   push ds
   mov ax, seg keyintproc
   mov ds, ax
   mov dx, offset keyintproc
   mov ax, 2509h
   int 21h
   pop ds
   ;�жϷ�������������
   sti; �����жϣ�С���鿪ʼ�ƶ�
   ;�����򲻶ϼ�� ESC ��״̬
mainloop:
   cmp esc_key_state, 0
   jne mainloop; ��� ESC δ�����������
   ;�����˳�����
   cli; �ر��ж�
   ;�ָ��жϷ������
   ;�����ж�
   mov dx, keyintoff
   mov ax, keyintseg
   push ds
   mov ds, ax
   mov ax, 2509h
   int 21h
   pop ds
   ;ʱ���ж�
   mov dx, clkintoff
   mov ax, clkintseg
   push ds
   mov ds, ax
   mov ax, 2508h
   int 21h
   pop ds
   sti
   ;�жϷ������ָ����
   call vga03h; �ָ�Ϊ�ı�ģʽ
   ;�˳�
   mov ax, 4c00h
   int 21h

;==============
; �жϷ������
;==============
clkintproc proc near; ʱ���ж�
   mov al, 20h
   out 20h, al
   call move
   iret
clkintproc endp

keyintproc proc near; �����ж�
   push ax
   push bx
   push ds
   mov ax, data
   mov ds, ax
   in al, 60h
   mov bl, al
   in al, 61h
   or al, 80h
   out 61h, al
   and al, 7fh
   out 61h, al
   mov al, 20h
   out 20h, al
   cmp bl, 01h; ESC ������
   je esc_pressed
   cmp bl, 81h; ESC ���ſ�
   je esc_released
   jmp keyintproc_return
esc_pressed:
   mov esc_key_state, 0; ���Ǹ�������Ϊ 0
   jmp keyintproc_return
esc_released:
   mov esc_key_state, 1; ���Ǹ�������Ϊ 1
   jmp keyintproc_return
keyintproc_return:
   pop ds
   pop bx
   pop ax
   iret
keyintproc endp

;==============
; ��ͼ��غ���
;==============
drawbox proc near; �������С����
   push cx
   push bx
   push dx
   mov ax, 4
   mov dx, cur_y
   mov cx, 20
loop_y:
   mov bx, cur_x
   push cx
   mov cx, 20
loop_x:
   push ax
   push dx
   push bx
   call putpix
   inc bx
   loop loop_x
   pop cx
   inc dx
   loop loop_y
   pop dx
   pop bx
   pop cx
   ret
drawbox endp

move proc near; �ƶ�һ��
;ˮƽ����
move_x:
   cmp direct_x, 1
   je call_move_right
call_move_left:
   call move_left
   jmp move_y
call_move_right:
   call move_right
;��ֱ����
move_y:
   cmp direct_y, 1
   je call_move_down
call_move_up:
   call move_up
   jmp move_end
call_move_down:
   call move_down
move_end:
   ret
move endp

move_left proc near; �����ƶ�һ��
   push cx
   push bx
   push dx
   dec cur_x
;����߻�һ������
   mov ax, 4
   mov bx, cur_x
   mov dx, cur_y
   mov cx, 20
draw_left:
   push ax
   push dx
   push bx
   call putpix
   inc dx
   loop draw_left
;���ұ߻�һ������
   mov ax, 0
   add bx, 20
   mov dx, cur_y
   mov cx, 20
clear_right:
   push ax
   push dx
   push bx
   call putpix
   inc dx
   loop clear_right
; ���������������ˮƽ�����Ϊ����
   cmp bx, 20
   jae move_left_return
   mov direct_x, 1
move_left_return:
   pop dx
   pop bx
   pop cx
   ret
move_left endp

move_right proc near; �����ƶ�һ��
   push cx
   push bx
   push dx
;����߻�һ������
   mov ax, 0
   mov bx, cur_x
   mov dx, cur_y
   mov cx, 20
clear_left:
   push ax
   push dx
   push bx
   call putpix
   inc dx
   loop clear_left
;���ұ߻�һ������
   mov ax, 4
   add bx, 20
   mov dx, cur_y
   mov cx, 20
draw_right:
   push ax
   push dx
   push bx
   call putpix
   inc dx
   loop draw_right
; ��������ұ������ˮƽ�����Ϊ����
   cmp bx, 319
   jbe move_right_return
   mov direct_x, -1
move_right_return:
   inc cur_x
   pop dx
   pop bx
   pop cx
   ret
move_right endp

move_up proc near; �����ƶ�һ��
   push cx
   push bx
   push dx
   dec cur_y
;���ϱ߻�һ������
   mov ax, 4
   mov dx, cur_y
   mov bx, cur_x
   mov cx, 20
draw_up:
   push ax
   push dx
   push bx
   call putpix
   inc bx
   loop draw_up
;���±߻�һ������
   mov ax, 0
   add dx, 20
   mov bx, cur_x
   mov cx, 20
clear_down:
   push ax
   push dx
   push bx
   call putpix
   inc bx
   loop clear_down
; ��������ϱ�����Ѵ�ֱ�����Ϊ����
   cmp dx, 20
   jae move_up_return
   mov direct_y, 1
move_up_return:
   pop dx
   pop bx
   pop cx
   ret
move_up endp

move_down proc near; �����ƶ�һ��
   push cx
   push bx
   push dx
;���ϱ߻�һ������
   mov ax, 0
   mov dx, cur_y
   mov bx, cur_x
   mov cx, 20
clear_up:
   push ax
   push dx
   push bx
   call putpix
   inc bx
   loop clear_up
;���±߻�һ������
   mov ax, 4
   add dx, 20
   mov bx, cur_x
   mov cx, 20
draw_down:
   push ax
   push dx
   push bx
   call putpix
   inc bx
   loop draw_down
; ��������±�����Ѵ�ֱ�����Ϊ����
   cmp dx, 199
   jbe move_down_return
   mov direct_y, -1
move_down_return:
   inc cur_y
   pop dx
   pop bx
   pop cx
   ret
move_down endp

;=============
; ����ͼ�ο�
;=============
vga13h proc near; ���� VGA13h ͼ��ģʽ
   mov ax, 0013h
   int 10h
   ret
vga13h endp

vga03h proc near; ���� VGA03h �ı�ģʽ
   mov ax, 0003h
   int 10h
   ret
vga03h endp

putpix proc near; ���㣬������ x, y, color
   push bp
   mov bp, sp
   push es
   push dx
   push cx
   push bx
   mov ax, 0A000h
   mov es, ax
   mov ax, [bp+6]; AX = y
   mov cl, 6
   shl ax, cl
   mov bx, ax
   mov cl, 2
   shl ax, cl
   add bx, ax; BX = ax*320 = y*320
   add bx, [bp+4]; BX += x
   mov al, [bp+8]
   mov es:[bx], al; ����
   pop bx
   pop cx
   pop dx
   pop es
   pop bp
   ret 6
putpix endp

getpix proc near; ȡ�㣬������ x, y������ֵ����ɫֵ
   push bp
   mov bp, sp
   push es
   push dx
   push cx
   push bx
   mov ax, 0A000h
   mov es, ax
   mov ax, [bp+6]; AX = y
   mov cl, 6
   shl ax, cl
   mov bx, ax
   mov cl, 2
   shl ax, cl
   add bx, ax; BX = ax*320 = y*320
   add bx, [bp+4]; BX += x
   mov al, es:[bx]; ȡ�㣬 AL = ��ɫֵ
   pop bx
   pop cx
   pop dx
   pop es
   pop bp
   ret 4
getpix endp

code ends

end main