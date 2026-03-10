stack segment para stack
db 256 dup(?)
stack ends


data segment para public

x dw 6
y dw 3
z dw ?

data ends


code segment para public
assume cs:code, ds:data, ss:stack

start:
    mov ax, data
    mov ds, ax
	mov ax, stack
    mov ss, ax

    mov ax, [x]
    imul word ptr [y]      

    mov cx, ax
	
	mov ax, [x]
	add ax, [y]
	
	mov bx, ax
	mov ax, cx
	idiv bx
	
    mov [z], ax

    mov ah, 4Ch
    mov al, 00h
    int 21h
	code ends

end start