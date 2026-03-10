stack segment para stack
db 256 dup(?)
stack ends

data segment para public
str db "omg asm no good",0Dh,0Ah,"$"
data ends

code segment para public

assume cs:code, ds:data, ss:stack

start:
	mov ax, data
	mov ds, ax
	mov ax, stack
	mov ss, ax
	
	mov dx, offset str
	mov ah, 09h
	int 21h
	
	mov ah, 4ch
	mov al, 00h
	int 21h	
code ends

end start