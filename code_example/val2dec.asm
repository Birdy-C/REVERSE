.386
data segment use16
abc dd 2147483647
s db 10 dup(' '), 0Dh, 0Ah, '$'
data ends
code segment use16
assume cs:code, ds:data
main:
  mov ax, data
  mov ds, ax
  mov di, 0; ����s���±�
  mov eax, abc
  mov cx, 0; ͳ��push�Ĵ���
again:
  mov edx, 0; ������ΪEDX:EAX
  mov ebx, 10
  div ebx; EAX=��, EDX=����
  add dl, '0'
  push dx
  inc cx
  cmp eax, 0
  jne again
pop_again:
  pop dx
  mov s[di], dl
  inc di
  dec cx
  jnz pop_again

  mov ah, 9
  mov dx, offset s
  int 21h
  mov ah, 4Ch
  int 21h
code ends
end main