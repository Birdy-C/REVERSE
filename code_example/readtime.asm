data segment
current_time db "00:00:00", 0Dh, 0Ah, "$"
data ends
code segment
assume cs:code, ds:data
main:
   mov ax, data
   mov ds, ax
   mov al, 4
   out 70h,al; index hour
   in al,71h ; AL=hour(e.g. 19h means 19 pm.)
   call convert
   ;mov word ptr current_time[0],ax
   mov current_time[0], al
   mov current_time[1], ah
   mov al,2
   out 70h,al; index minute
   in  al,71h; AL=minute
   call convert
   mov word ptr current_time[3],ax;
   ;mov current_time[3], al
   ;mov current_time[4], ah
   mov al,0  ; index second
   out 70h,al
   in  al,71h; AL=second
   call convert
   mov word ptr current_time[6],ax
   mov ah, 9
   mov dx, offset current_time
   int 21h
   mov ah, 4Ch
   int 21h
;---------Convert----------------
;Input:AL=hour or minute or second
;      format:e.g. hour   15h means 3 pm.
;                  second 56h means 56s
;Output: (e.g. AL=56h)
;     AL='5'
;     AH='6'
convert:
    push cx
    mov ah,al ; e.g. assume AL=56h
    and ah,0Fh; AH=06h
    mov cl,4
    shr al,cl ; AL=05h
    ; shr:shift right”““∆
    add ah, '0'; AH='6'
    add al, '0'; AL='5'
    pop  cx
    ret
;---------End of Convert---------
code ends
end main
