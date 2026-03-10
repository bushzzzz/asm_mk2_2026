stack segment para stack
db 256 dup(?)
stack ends

data segment para public

str1_max db 240
str1_len db ?
str1 db 240 dup("$")

str2_max db 240
str2_len db ?
str2 db 240 dup("$")

str3_max db 240
str3_len db ?
str3 db 240 dup("$")


data ends


code segment para public
assume cs:code, ds:data, ss:stack

start:
	mov ax, data
	mov ds, ax
	mov ax, stack
	mov ss, ax

	mov dx, offset str1_max
	mov ah, 0Ah
	int 21h

	mov dx, offset str2_max
	mov ah, 0Ah
	int 21h

	mov dx, offset str3_max
	mov ah, 0Ah
	int 21h


	mov dl, 0Ah       
    mov ah, 02h
    int 21h

    mov dl, 0Dh
    mov ah, 02h
    int 21h

	mov dx, offset str1
	mov ah, 09h
	int 21h

	mov dl, 0Ah       
    mov ah, 02h
    int 21h

    mov dl, 0Dh
    mov ah, 02h
    int 21h

	mov dx, offset str2
	mov ah, 09h
	int 21h

	mov dl, 0Ah       
    mov ah, 02h
    int 21h

    mov dl, 0Dh
    mov ah, 02h
    int 21h

	mov dx, offset str3
	mov ah, 09h
	int 21h
	
	mov dl, 0Ah       
    mov ah, 02h
    int 21h

    mov dl, 0Dh
    mov ah, 02h
    int 21h

	mov ah, 4Ch
	mov al, 0
	int 21h
	code ends

end start