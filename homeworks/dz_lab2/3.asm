stack segment para stack
db 256 dup(?)
stack ends

data segment para public
buffer db 240       
len db ?         
str db 240 dup("$")  
data ends

code segment para public

assume cs:code, ds:data, ss:stack

start:
    mov ax, data
    mov ds, ax
    mov ax, stack
    mov ss, ax

    mov dx, offset buffer
    mov ah, 0Ah       
    int 21h

    mov dl, 0Ah       
    mov ah, 02h
    int 21h

    mov dl, 0Dh
    mov ah, 02h
    int 21h

    mov dx, offset str
    mov ah, 09h       
    int 21h

    mov ah, 4ch
    mov al, 00h
    int 21h
code ends

end start