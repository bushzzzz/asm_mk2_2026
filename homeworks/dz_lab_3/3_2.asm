stack segment para stack
db 256 dup(?)
stack ends


data segment para public

a dw 4
b dw 2
c dw ?

data ends


code segment para public
assume cs:code, ds:data, ss:stack

start:

    mov ax, data
    mov ds, ax

    mov ax, stack
    mov ss, ax


    mov ax, [a]
    add ax, [b]

    imul ax

    mov [c], ax

    mov ah, 4Ch
    mov al, 00h
    int 21h
	code ends
	
end start