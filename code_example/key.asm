;---------------------------------------
;PrtSc/SysRq: E0 2A E0 37 E0 B7 E0 AA  ;
;Pause/Break: E1 1D 45 E1 9D C5        ;
;---------------------------------------
data segment
old_9h dw 0, 0
stop   db 0
key    db 0; key=31h
phead  dw 0
key_extend  db 'KeyExtend=', 0
key_up      db 'KeyUp=', 0
key_down    db 'KeyDown=', 0
key_code    db '00h ', 0
hex_tbl     db '0123456789ABCDEF'
cr          db  0Dh, 0Ah, 0
data ends

code segment
assume cs:code, ds:data
main:
   mov ax, data
   mov ds, ax
   xor ax, ax
   mov es, ax
   mov bx, 9*4
   push es:[bx]
   pop old_9h[0]
   push es:[bx+2]
   pop old_9h[2]    ; 保存int 9h的中断向量
   mov ax, offset int_9h
   cli
   mov es:[bx], ax
   mov es:[bx+2], cs; 修改int 9h的中断向量
   sti
again:
   cmp [stop], 1
   jne again        ; 主程序在此循环等待
   push old_9h[0]
   pop es:[bx]
   push old_9h[2]
   pop es:[bx+2]    ; 恢复int 9h的中断向量
   mov ah, 4Ch
   int 21h

int_9h:
   push ax
   push bx
   push cx
   push ds
   mov ax, data
   mov ds, ax       ; 这里设置DS是因为被中断的不一定是我们自己的程序
   in al, 60h       ; AL=key code
   mov [key], al
   cmp al, 0E0h
   je  extend
   cmp al, 0E1h
   jne up_or_down
extend:
   mov [phead], offset key_extend
   call output
   jmp check_esc
up_or_down:
   test al, 80h     ; 最高位==1时表示key up
   jz down
up:
   mov [phead], offset key_up
   call output
   mov bx, offset cr
   call display1     ; 输出回车换行
   jmp check_esc
down:
   mov [phead], offset key_down
   call output
check_esc:   
   cmp [key], 81h   ; Esc键的key up码
   jne int_9h_iret
   mov [stop], 1
int_9h_iret:
   in al, 61h       ;\
   or al, 80h       ; \ 
   out 61h, al      ;  \ 这6条指令是对键盘作出回应
   in al, 61h       ;  / 表示我们已经处理了这个键码
   and al, 7Fh      ; / 
   out 61h, al      ;/
   mov al, 20h      ; 发EOI(End Of Interrupt)信号给中断控制器，
   out 20h, al      ; 表示我们已处理当前的硬件中断(硬件中断处理最后都要这2条指令)。
                    ; 因为我们没有跳转到的old_9h，所以必须自己发EOI信号。
                    ; 如果跳到old_9h的话，则old_9h里面有这2条指令，这里就不要写。
   pop ds
   pop cx
   pop bx
   pop ax
   iret             ; 中断返回指令。从堆栈中逐个弹出IP、CS、FL。

output:
   push ax
   push bx
   push cx
   mov bx, offset hex_tbl
   mov cl, 4
   push ax   ; 设AL=31h
   shr al, cl; AL=03h
   xlat      ; AL = DS:[BX+AL] = '3'
   mov key_code[0], al
   pop ax
   and al, 0Fh; AL=01h
   xlat       ; AL='1'
   mov key_code[1], al
   mov bx, [phead]
   call display1     ; 输出提示信息
   mov bx, offset key_code
   call display1     ; 输出键码
   pop cx
   pop bx
   pop ax
   ret
   
display1:
   push ax
   push bx
   push si
   mov si, bx
   mov bx, 0007h    ; BL = color
   cld
display_next:
   mov ah, 0Eh      ; AH=0Eh, BIOS int 10h的子功能，具体请查中断大全
   lodsb
   or al, al
   jz display_done
   int 10h          ; 每次输出一个字符
   jmp display_next
display_done:
   pop si
   pop bx
   pop ax
   ret
code ends
end main
