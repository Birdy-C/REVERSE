data segment
clkintseg     dw ?;   原来的时钟中断服务程序段地址
clkintoff     dw ?;   原来的时钟中断服务程序偏移地址
keyintseg     dw ?;   原来的键盘中断服务程序段地址
keyintoff     dw ?;   原来的键盘中断服务程序偏移地址
esc_key_state db 1;   ESC 键状态
direct_x      db 1;   水平移动方向，-1 表示向左，1 表示向右
direct_y      db 1;   垂直移动方向，-1 表示向上，1 表示向下
cur_x         dw 150; 小方块的当前横左边
cur_y         dw 90;  小方块的当前纵坐标
data ends

code segment
assume cs:code, ds:data

main:
   mov ax, data
   mov ds, ax
   call vga13h;  进入 VGA13h 图形模式
   call drawbox; 画小方块
   cli; 关闭中断
   ;设置中断服务程序
   ;时钟中断
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
   ;键盘中断
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
   ;中断服务程序设置完毕
   sti; 开启中断，小方块开始移动
   ;主程序不断检查 ESC 键状态
mainloop:
   cmp esc_key_state, 0
   jne mainloop; 如果 ESC 未被按下则继续
   ;否则退出程序
   cli; 关闭中断
   ;恢复中断服务程序
   ;键盘中断
   mov dx, keyintoff
   mov ax, keyintseg
   push ds
   mov ds, ax
   mov ax, 2509h
   int 21h
   pop ds
   ;时钟中断
   mov dx, clkintoff
   mov ax, clkintseg
   push ds
   mov ds, ax
   mov ax, 2508h
   int 21h
   pop ds
   sti
   ;中断服务程序恢复完毕
   call vga03h; 恢复为文本模式
   ;退出
   mov ax, 4c00h
   int 21h

;==============
; 中断服务程序
;==============
clkintproc proc near; 时钟中断
   mov al, 20h
   out 20h, al
   call move
   iret
clkintproc endp

keyintproc proc near; 键盘中断
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
   cmp bl, 01h; ESC 被按下
   je esc_pressed
   cmp bl, 81h; ESC 被放开
   je esc_released
   jmp keyintproc_return
esc_pressed:
   mov esc_key_state, 0; 把那个变量设为 0
   jmp keyintproc_return
esc_released:
   mov esc_key_state, 1; 把那个变量设为 1
   jmp keyintproc_return
keyintproc_return:
   pop ds
   pop bx
   pop ax
   iret
keyintproc endp

;==============
; 画图相关函数
;==============
drawbox proc near; 画最初的小方块
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

move proc near; 移动一次
;水平方向
move_x:
   cmp direct_x, 1
   je call_move_right
call_move_left:
   call move_left
   jmp move_y
call_move_right:
   call move_right
;垂直方向
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

move_left proc near; 向左移动一格
   push cx
   push bx
   push dx
   dec cur_x
;在左边画一条红线
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
;在右边画一条黑线
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
; 如果到最左边了则把水平方向改为向右
   cmp bx, 20
   jae move_left_return
   mov direct_x, 1
move_left_return:
   pop dx
   pop bx
   pop cx
   ret
move_left endp

move_right proc near; 向右移动一格
   push cx
   push bx
   push dx
;在左边画一条黑线
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
;在右边画一条红线
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
; 如果到最右边了则把水平方向改为向左
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

move_up proc near; 向上移动一格
   push cx
   push bx
   push dx
   dec cur_y
;在上边划一条红线
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
;在下边划一条黑线
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
; 如果到最上边了则把垂直方向改为向下
   cmp dx, 20
   jae move_up_return
   mov direct_y, 1
move_up_return:
   pop dx
   pop bx
   pop cx
   ret
move_up endp

move_down proc near; 向下移动一格
   push cx
   push bx
   push dx
;在上边画一条黑线
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
;在下边画一条红线
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
; 如果到最下边了则把垂直方向改为向上
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
; 最简的图形库
;=============
vga13h proc near; 进入 VGA13h 图形模式
   mov ax, 0013h
   int 10h
   ret
vga13h endp

vga03h proc near; 进入 VGA03h 文本模式
   mov ax, 0003h
   int 10h
   ret
vga03h endp

putpix proc near; 画点，参数表： x, y, color
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
   mov es:[bx], al; 画点
   pop bx
   pop cx
   pop dx
   pop es
   pop bp
   ret 6
putpix endp

getpix proc near; 取点，参数表： x, y，返回值：颜色值
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
   mov al, es:[bx]; 取点， AL = 颜色值
   pop bx
   pop cx
   pop dx
   pop es
   pop bp
   ret 4
getpix endp

code ends

end main