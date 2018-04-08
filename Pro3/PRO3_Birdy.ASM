				
.386
data segment use16
t  db  '0123456789ABCDEF','$'		;char t[] = "0123456789ABCDEF";

filename  db  100  
          db   ?
	  db   100 dup  (?)		;char filename[100];
buf  db  256  dup  (?)			;char buf[256];

handle  dw  0
key  dd  0
bytes_in_buf dw 0			;int  handle, key, bytes_in_buf;
file_size dd 0
n dd 0
offset1 dd 0				;long file_size, offset, n;
offset2 dd 0				;long file_size, offset, n;

str_input db 'Please input filename:','$'
pattern db '00000000:            |           |           |                             ','$'
s       db '00000000:            |           |           |                             ','$'

data ends

code segment use16
assume cs:code,ds:data
.386
main:
    mov  ax, data
    mov  ds, ax
  
    ;输出提示
    mov  dx, offset str_input
    mov  ah, 09h
    int  21h
    ;输入字符串
    mov  dx, offset filename
    mov  ah, 0Ah
    int  21h

    ;输出回车
    mov  ah,2
    mov  dl, 0Ah
    int  21h

    ;插入结束符
    xor bx,bx
    mov bl,byte ptr [offset filename + 1]
    add bl,2
    mov byte ptr [offset filename + bx],'$'

    ;打开文件, 返回句柄; 
    
    mov ah, 3Dh
    mov al, 0   ; 对应_open()的第2个参数, 表示只读方式
    mov dx, offset filename +2
    int 21h
    mov handle, ax
    jc Exit0

    PUSHA 

    mov ah, 42h
    mov al, 2; 对应lseek()的第3个参数,
               ; 表示以EOF为参照点进行移动
    mov bx, handle
    mov cx, 0; \ 对应lseek()的第2个参数
    mov dx, 0; /
    int 21h
    mov word ptr file_size[2], dx
    mov word ptr file_size[0], ax

    POPA

main_loop:
    mov  word ptr[offset bytes_in_buf], 256
    mov  EAX, dword ptr [offset file_size]
    sub  EAX, dword ptr [offset offset1]
    cmp  EAX, 256
    ja   continue1
    mov  word ptr[offset bytes_in_buf], AX 
continue1:

   ; PUSHA 

 ;移动文件指针;
    mov ah, 42h
    mov al, 0; 对应lseek()的第3个参数,
    ; 表示以偏移0作为参照点进行移动
    mov bx, handle
    mov cx, word ptr offset1[2]; \cx:dx合一起构成
    mov dx, word ptr offset1[0]; /32位值=offset
    int 21h


;读取文件中的bytes_in_buf个字节到buf中 
   mov ah, 3Fh
   mov bx, handle
   mov cx, bytes_in_buf
   mov dx, data
   mov ds, dx
   mov dx, offset buf
   int 21h

  ; POPA
;offset1 = 0  buf = all info in files  byte_in_buf 
   call show_this_page


;键盘输入;
input:
    mov  ah, 0
    int  16h
    cmp  AX,04900h
    je   bn_pageup
    cmp  AX,05100h
    je   bn_pagedown
    cmp  AX,04700h
    je   bn_home
    cmp  AX,04F00h
    je   bn_end
    cmp  AX,011Bh
    je   bn_esc
    jmp  input
;==============================
bn_pageup:
    push EAX
    mov  EAX, dword ptr[offset offset1];
    sub  EAX, 256
    cmp  EAX, 0
    jl  bn_pageup1

    mov dword ptr[offset offset1],EAX
    pop EAX
    jmp main_loop

bn_pageup1:
    mov dword ptr[offset offset1],0
  jmp main_loop
;==============================
bn_pagedown:
    push EAX
    mov  EAX, dword ptr[offset offset1];
    add  EAX, 256
    cmp  EAX, dword ptr[offset file_size]
    ja  bn_pagedown1
    mov dword ptr[offset offset1],EAX
bn_pagedown1:
    pop EAX
  jmp main_loop
;==============================
bn_home:
    mov dword ptr[offset offset1],0
  jmp main_loop
;==============================
bn_end:
    push EAX
    mov  EAX, dword ptr[offset file_size];
    sub  EAX, 1
    and  EAX, 0FFFFFF00h
    mov  dword ptr[offset offset1],EAX
    pop EAX
    jmp main_loop

bn_esc:


;关闭文件
    mov  ah, 3Eh
    mov  bx, handle
    int  21h

;return
    mov  AH,4Ch
    int  21h

Exit0:
    mov ah, 4Ch
    mov al, 0; 对应exit()中的参数
    int 21h
;===========================================
;把8位数转化成16进制格式
;AX输入 char
;BP输出char[2]
;==========================================
char2hex  PROC NEAR
    push  DI
    push  BP
    push  CX

    push  AX
    shr   AX, 4
    and   AX, 0Fh
    mov   DI, offset t
    add   DI, AX
    
    mov   DL,byte ptr[DI]
    mov   byte ptr DS:[BP],DL
    pop   AX

    push  AX
    and   AX, 0Fh
    mov   DI, offset t
    add   DI, AX
 
    mov   DL, byte ptr [DI]
    mov   byte ptr DS:[BP+1], DL
    pop   AX

    
    pop   CX
    pop   BP
    pop   DI
RETN
char2hex  ENDP

;===========================================
;offset2
;BP
;===========================================

long2hex  PROC NEAR
    push  BP
    push  SI
    push  CX
    push  AX
    push  DX

    mov  CX,5
    mov  EAX, dword ptr[offset offset2]
    add  BP, 6

c: 
    push CX
;AX输入 char
;BP输出char   [2]
    call char2hex
    pop  CX
    ;mov  EAX, dword ptr[offset offset2]
    shr  EAX, 8
    sub  BP, 2
loop c

    pop   DX
    pop   AX
    pop   CX
    pop   SI
    pop   BP
RETN
long2hex  ENDP

;===========================================
;   show_this_row(i, offset+i*16, &buf[i*16], bytes_on_row)
; /* 显示这一行 */;DX i BX bytes
;===========================================
show_this_row  PROC NEAR
    mov  CX, data
    mov  ES, CX
    mov  DI,offset s
    mov  SI,offset pattern
    mov  CX,75

    rep movsb;   strcpy(s, pattern)


    mov  BP, offset s
;offset2输入到bp
    push DX
    call long2hex
    pop  DX
;   p
;long2hex(offset, s); /* 把32位偏移地址转化成16进制格式填入s左侧8个'0'处 */


;把buf中各个字节转化成16进制格式填入s中的xx处
;CX = 16 
    mov  CX, BX
    mov  BP, offset s
    add  BP,0Ah;s+10

;DX line < 16
    push DX
    mov  SI,offset buf
    shl  DX, 4 ;i*16
    add  SI, DX;SI buf
    pop  DX

    push CX
    push BP
;CX<=16

c1_show:
   ; mov  byte ptr[offset buf]
   ;SI = buf[i]
   ;BP = s + 10 + i*3
    mov  AX, word ptr[SI]

    push DX
    call char2hex          ;      char2hex(buf[i], s+10+i*3); AX BP
    pop  DX
    add  BP,3;s
    inc  SI
loop c1_show
    

    pop BP
    pop  CX

    push  CX
    push  ES
    push  DI
    push  BP
 ;   push  SI


    push DX
    mov  SI, 59

    shl  DX, 4 ;i*16
    mov  DI, DX
    pop  DX

    mov  CX, BX
c2_show:
    mov  BL, buf[DI]
    inc  DI
    mov  s[SI], BL;
    inc  SI
loop c2_show
   ;pop SI
    pop BP
    pop DI
    pop ES
    pop CX


;es:di  cs:si
    push ES
    push AX		
    mov  AX, 0B800h
    mov  ES, AX

    mov  AX,DX;row
    mov  BX, 0A0h
    mul  BL
    mov  DI,AX

    pop  AX

    xor  CX,CX
    xor  SI,SI


c3_show:
    mov DL,s[SI]
    mov byte ptr ES:[DI],DL     
    cmp DX,'|'
    jne c3_cmp
    mov byte ptr ES:[DI+1],0Fh
    jmp c3_end
c3_cmp:
    mov byte ptr ES:[DI+1],07h
c3_end:
    inc SI
    add DI,2
    inc CX
    cmp CX,74
    jne c3_show

    pop ES

RETN
show_this_row  ENDP

;===========================================

;===========================================

clear_this_page  PROC NEAR
    push  DI
    push  ES
    push  CX
    push  AX

    mov AX,0003H
    int 10H			;clear the screen

    pop   AX
    pop   CX
    pop   ES
    pop   DI
RETN
clear_this_page  ENDP

;===========================================

;===========================================

show_this_page  PROC NEAR
    push  CX
    push  DX

    call  clear_this_page
    mov   CX, word ptr [offset bytes_in_buf]
    add   CX, 0Fh
    shr   CX, 4 ;CX = row
    xor   DX, DX
    mov   EAX, dword ptr[offset offset1]
c_show:
    mov   dword ptr[offset offset2],EAX
    mov   BX, 010h
    cmp   CX, 1
    jne   con
    mov   BX, word ptr [offset bytes_in_buf]
    shr   BX, 4
    and   BX, 1Fh

con:
    ;DX = i, offset2 = offset1 + 16*i, BX = bytes_on_this_row 0-16
    push  CX
    push  DX
    call  show_this_row
    pop   DX
    pop   CX
    inc   DX
    mov   EAX,dword ptr[offset offset2]
    add   EAX,16
    loop  c_show

    pop   DX
    pop   CX
RETN
show_this_page  ENDP

code ends
    end  main

