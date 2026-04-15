
_fopen proc near
    push bp
    mov  bp, sp
    push dx

    mov  dx, word ptr [bp + 4]
    mov  ax, 3D00h
    int  21h
    jc   fopen_err
    jmp  short fopen_done

fopen_err:
    mov  ax, 0FFFFh

fopen_done:
    pop  dx
    mov  sp, bp
    pop  bp
    ret
_fopen endp

_fclose proc near
    push bp
    mov  bp, sp

    mov  bx, word ptr [bp + 4]
    mov  ah, 3Eh
    int  21h

    mov  sp, bp
    pop  bp
    ret
_fclose endp

_fsize proc near
    push bp
    mov  bp, sp
    push bx
    push cx
    push dx

    mov  bx, word ptr [bp + 4]

    mov  ax, 4202h
    xor  cx, cx
    xor  dx, dx
    int  21h
    jc   fsize_err
    push ax

    mov  ax, 4200h
    xor  cx, cx
    xor  dx, dx
    int  21h

    pop  ax
    jmp  short fsize_done

fsize_err:
    xor  ax, ax

fsize_done:
    pop  dx
    pop  cx
    pop  bx
    mov  sp, bp
    pop  bp
    ret
_fsize endp

_fread proc near
    push bp
    mov  bp, sp
    push bx
    push cx
    push dx
    push ds

    mov  bx, word ptr [bp + 4]
    mov  ax, word ptr [bp + 6]
    mov  ds, ax
    mov  dx, word ptr [bp + 8]
    mov  cx, word ptr [bp + 10]
    mov  ah, 3Fh
    int  21h
    jc   fread_err
    jmp  short fread_done

fread_err:
    mov  ax, 0FFFFh

fread_done:
    pop  ds
    pop  dx
    pop  cx
    pop  bx
    mov  sp, bp
    pop  bp
    ret
_fread endp

_fread_all proc near
    push bp
    mov  bp, sp
    sub  sp, 8
    push bx
    push dx
    push si

    push word ptr [bp + 4]
    call _fopen
    add  sp, 2
    cmp  ax, 0FFFFh
    je   fra_err_open
    mov  word ptr [bp - 2], ax

    push ax
    call _fsize
    add  sp, 2
    cmp  ax, 0
    je   fra_err_size
    mov  word ptr [bp - 4], ax

    mov  cx, ax
    inc  cx
    push cx
    call _malloc
    add  sp, 2
    mov  word ptr [bp - 6], dx
    mov  word ptr [bp - 8], ax

    push word ptr [bp - 4]
    push word ptr [bp - 8]
    push word ptr [bp - 6]
    push word ptr [bp - 2]
    call _fread
    add  sp, 8
    cmp  ax, 0FFFFh
    je   fra_err_read
    mov  si, ax

    push es
    mov  es, word ptr [bp - 6]
    mov  bx, word ptr [bp - 8]
    add  bx, si
    mov  byte ptr es:[bx], 0
    pop  es

    push word ptr [bp - 2]
    call _fclose
    add  sp, 2

    mov  bx, word ptr [bp + 6]
    mov  ax, word ptr [bp - 6]
    mov  word ptr [bx], ax

    mov  bx, word ptr [bp + 8]
    mov  ax, word ptr [bp - 8]
    mov  word ptr [bx], ax

    mov  ax, si
    jmp  short fra_done

fra_err_open:
    push offset msg_fopen_err
    call _putstr
    add  sp, 2
    xor  ax, ax
    jmp  short fra_done

fra_err_size:
    push word ptr [bp - 2]
    call _fclose
    add  sp, 2
    push offset msg_fsize_err
    call _putstr
    add  sp, 2
    xor  ax, ax
    jmp  short fra_done

fra_err_read:
    push word ptr [bp - 2]
    call _fclose
    add  sp, 2
    push offset msg_fread_err
    call _putstr
    add  sp, 2
    xor  ax, ax

fra_done:
    pop  si
    pop  dx
    pop  bx
    mov  sp, bp
    pop  bp
    ret
_fread_all endp