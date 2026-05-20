; Функции для ввода-вывода строк/символов (используется соглашение cdecl)

; void putchar(int c)
; выводит символ на экран (младший байт переданного аргумента)
_putchar proc near
    push bp
    mov bp, sp
    
    mov dx, word ptr [bp + 4]
    mov ah, 02h
    int 21h
    
    mov sp, bp
    pop bp
    ret
_putchar endp    
    
; int getchar()
; читает символ с клавиатуры и возвращает его (считанный символ - младший байт (al) регистра ax)
_getchar proc near
    push bp
    mov bp, sp
    
    mov ah, 01h
    int 21h
    
    mov sp, bp
    pop bp
    ret
_getchar endp

; int strlen(const char *str)
; находит длинну строки (до завершающего нуля), адрес которой является аргументом
_strlen proc near
    push bp
    mov bp, sp
    
    mov bx, word ptr [bp + 4] 
    xor ax, ax ; счётчик (ax)

lencyc:    
    cmp byte ptr [bx], 0
    je lenret
    inc ax
    inc bx
    jmp lencyc
    
lenret:    
    mov sp, bp
    pop bp
    ret
_strlen endp
    
; void putstr(const char *str)
; выводит строку на экран (до завершающего нуля), адрес которой передан в качестве аргумента
_putstr proc near
    push bp
    mov bp, sp
    
    ; находим длину строки
    push word ptr [bp + 4] 
    call _strlen
    add sp, 2
    
    ; выводим строку
    mov cx, ax
    mov dx, word ptr [bp + 4]
    mov ah, 40h
    mov bx, 1
    int 21h
    
    mov sp, bp
    pop bp
    ret
_putstr endp
    
; void getstr(const char *str, int max_len)
; читает строку с клавиатуры (либо max_len - 1 байт, либо до перевода строки) и сохраняет её в память, 
; при этом дописывает в конец строки завершающий 0
_getstr proc near
    push bp
    mov bp, sp
    
    dec word ptr [bp + 6] ; уменьшаем требуемую длину на 1 (max_len - 1)
    mov bx, word ptr [bp + 4] ; адрес начала строки
    mov si, 0 ; счётчик
 
getscyc: 
    cmp si, word ptr [bp + 6]
    je getsret
    
    call _getchar
    
    cmp al, 10
    je getsret
    cmp al, 13
    je getsret
    
    mov byte ptr [bx], al
    inc bx
    inc si
    jmp getscyc
    
getsret:
    mov byte ptr [bx], 0
    call _putnewline
    mov sp, bp
    pop bp
    ret
_getstr endp

; void putnewline()
; выводит на экран возврат каретки (\r) и перевод строки (\n), т.е. переводит вывод на новую строку
_putnewline proc near
    push bp
    mov bp, sp
    
    mov dx, 10
    push dx
    call _putchar
    add sp, 2
    
    mov dx, 13
    push dx
    call _putchar
    add sp, 2
    
    mov sp, bp
    pop bp
    ret
_putnewline endp

; void exit(int code)
; завершает работу программы с кодом, переданным в качетве аргумента (кодом является младший байт аргумента)  
_exit proc near
    push bp
    mov bp, sp
    
    mov ax, word ptr [bp + 4]
    mov ah, 4ch
	int 21h
    
    mov sp, bp
    pop bp
    ret
_exit endp
    
; void exit0()
; завершает работу программы с кодом 0 
_exit0 proc near
    push bp
    mov bp, sp
    
    mov dx, 0
    push dx
    call _exit
    add sp, 2
    
    mov sp, bp
    pop bp
    ret
_exit0 endp