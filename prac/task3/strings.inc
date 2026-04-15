
_putchar proc near
    push bp
    mov  bp, sp

    mov  dl, byte ptr [bp + 4]
    mov  ah, 02h
    int  21h

    mov  sp, bp
    pop  bp
    ret
_putchar endp

_getchar proc near
    push bp
    mov  bp, sp

    mov  ah, 01h
    int  21h

    mov  sp, bp
    pop  bp
    ret
_getchar endp

_strlen proc near
    push bp
    mov  bp, sp
    push bx

    mov  bx, word ptr [bp + 4]
    xor  ax, ax

strlen_loop:
    cmp  byte ptr [bx], 0
    je   strlen_done
    inc  ax
    inc  bx
    jmp  strlen_loop

strlen_done:
    pop  bx
    mov  sp, bp
    pop  bp
    ret
_strlen endp

_putstr proc near
    push bp
    mov  bp, sp
    push bx
    push cx
    push dx

    push word ptr [bp + 4]
    call _strlen
    add  sp, 2

    mov  cx, ax
    mov  dx, word ptr [bp + 4]
    mov  ah, 40h
    mov  bx, 1
    int  21h

    pop  dx
    pop  cx
    pop  bx
    mov  sp, bp
    pop  bp
    ret
_putstr endp

_getstr proc near
    push bp
    mov  bp, sp
    push bx
    push si

    dec  word ptr [bp + 6]
    mov  bx, word ptr [bp + 4]
    xor  si, si

getstr_loop:
    cmp  si, word ptr [bp + 6]
    je   getstr_done
    call _getchar
    cmp  al, 10
    je   getstr_done
    cmp  al, 13
    je   getstr_done
    mov  byte ptr [bx], al
    inc  bx
    inc  si
    jmp  getstr_loop

getstr_done:
    mov  byte ptr [bx], 0
    call _putnewline

    pop  si
    pop  bx
    mov  sp, bp
    pop  bp
    ret
_getstr endp

_putnewline proc near
    push bp
    mov  bp, sp

    push 10
    call _putchar
    add  sp, 2

    push 13
    call _putchar
    add  sp, 2

    mov  sp, bp
    pop  bp
    ret
_putnewline endp

_exit proc near
    push bp
    mov  bp, sp
    mov  ax, word ptr [bp + 4]
    mov  ah, 4Ch
    int  21h
    mov  sp, bp
    pop  bp
    ret
_exit endp

_exit0 proc near
    push bp
    mov  bp, sp
    push 0
    call _exit
    add  sp, 2
    mov  sp, bp
    pop  bp
    ret
_exit0 endp

_strstr proc near
    push bp
    mov  bp, sp
    push bx
    push si
    push di

    push word ptr [bp + 6]
    call _strlen
    add  sp, 2
    cmp  ax, 0
    je   strstr_empty

    mov  si, word ptr [bp + 4]

strstr_outer:
    cmp  byte ptr [si], 0
    je   strstr_not_found

    mov  di, word ptr [bp + 6]
    mov  bx, si

strstr_inner:
    cmp  byte ptr [di], 0
    je   strstr_found

    mov  al, byte ptr [bx]
    cmp  al, byte ptr [di]
    jne  strstr_next

    inc  bx
    inc  di
    jmp  strstr_inner

strstr_next:
    inc  si
    jmp  strstr_outer

strstr_found:
    mov  ax, si
    jmp  strstr_done

strstr_empty:
    mov  ax, word ptr [bp + 4]
    jmp  strstr_done

strstr_not_found:
    xor  ax, ax

strstr_done:
    pop  di
    pop  si
    pop  bx
    mov  sp, bp
    pop  bp
    ret
_strstr endp

_strchr proc near
    push bp
    mov  bp, sp
    push bx

    mov  bx, word ptr [bp + 4]
    mov  cl, byte ptr [bp + 6]

strchr_loop:
    mov  al, byte ptr [bx]
    cmp  al, cl
    je   strchr_found
    cmp  al, 0
    je   strchr_not_found
    inc  bx
    jmp  strchr_loop

strchr_found:
    mov  ax, bx
    jmp  strchr_done

strchr_not_found:
    xor  ax, ax

strchr_done:
    pop  bx
    mov  sp, bp
    pop  bp
    ret
_strchr endp

_strcpy proc near
    push bp
    mov  bp, sp
    push bx
    push si

    mov  bx, word ptr [bp + 4]
    mov  si, word ptr [bp + 6]

strcpy_loop:
    mov  al, byte ptr [si]
    mov  byte ptr [bx], al
    cmp  al, 0
    je   strcpy_done
    inc  bx
    inc  si
    jmp  strcpy_loop

strcpy_done:
    mov  ax, word ptr [bp + 4]

    pop  si
    pop  bx
    mov  sp, bp
    pop  bp
    ret
_strcpy endp

_strcat proc near
    push bp
    mov  bp, sp
    push bx
    push si

    push word ptr [bp + 4]
    call _strlen
    add  sp, 2

    mov  bx, word ptr [bp + 4]
    add  bx, ax

    mov  si, word ptr [bp + 6]

strcat_loop:
    mov  al, byte ptr [si]
    mov  byte ptr [bx], al
    cmp  al, 0
    je   strcat_done
    inc  bx
    inc  si
    jmp  strcat_loop

strcat_done:
    mov  ax, word ptr [bp + 4]

    pop  si
    pop  bx
    mov  sp, bp
    pop  bp
    ret
_strcat endp

_strcmp proc near
    push bp
    mov  bp, sp
    push bx
    push si

    mov  bx, word ptr [bp + 4]
    mov  si, word ptr [bp + 6]

strcmp_loop:
    mov  al, byte ptr [bx]
    mov  ah, byte ptr [si]
    cmp  al, ah
    jne  strcmp_diff
    cmp  al, 0
    je   strcmp_equal
    inc  bx
    inc  si
    jmp  strcmp_loop

strcmp_diff:
    xor  ah, ah
    mov  bl, byte ptr [si]
    xor  bh, bh
    sub  ax, bx
    jmp  strcmp_done

strcmp_equal:
    xor  ax, ax

strcmp_done:
    pop  si
    pop  bx
    mov  sp, bp
    pop  bp
    ret
_strcmp endp

_stricmp proc near
    push bp
    mov  bp, sp
    push bx
    push si

    mov  bx, word ptr [bp + 4]
    mov  si, word ptr [bp + 6]

stricmp_loop:
    mov  al, byte ptr [bx]
    mov  cl, byte ptr [si]

    cmp  al, 'A'
    jb   stricmp_l1
    cmp  al, 'Z'
    ja   stricmp_l1
    add  al, 32
stricmp_l1:
    cmp  cl, 'A'
    jb   stricmp_l2
    cmp  cl, 'Z'
    ja   stricmp_l2
    add  cl, 32
stricmp_l2:
    cmp  al, cl
    jne  stricmp_diff
    cmp  al, 0
    je   stricmp_equal
    inc  bx
    inc  si
    jmp  stricmp_loop

stricmp_diff:
    xor  ah, ah
    xor  ch, ch
    sub  ax, cx
    jmp  stricmp_done

stricmp_equal:
    xor  ax, ax

stricmp_done:
    pop  si
    pop  bx
    mov  sp, bp
    pop  bp
    ret
_stricmp endp

_strtol proc near
    push bp
    mov  bp, sp
    sub  sp, 4
    push bx
    push si
    push di

    mov  si, word ptr [bp + 4]
    xor  di, di
    mov  word ptr [bp - 4], 0

strtol_ws:
    mov  al, byte ptr [si]
    cmp  al, ' '
    je   strtol_ws_skip
    cmp  al, 9
    je   strtol_ws_skip
    jmp  strtol_sign
strtol_ws_skip:
    inc  si
    jmp  strtol_ws

strtol_sign:
    cmp  al, '-'
    jne  strtol_plus
    mov  word ptr [bp - 4], 1
    inc  si
    jmp  strtol_base
strtol_plus:
    cmp  al, '+'
    jne  strtol_base
    inc  si

strtol_base:
    mov  ax, word ptr [bp + 8]
    cmp  ax, 0
    jne  strtol_set_base

    mov  al, byte ptr [si]
    cmp  al, '0'
    jne  strtol_dec
    mov  al, byte ptr [si + 1]
    cmp  al, 'x'
    je   strtol_hex_prefix
    cmp  al, 'X'
    je   strtol_hex_prefix
    mov  ax, 8
    jmp  strtol_set_base
strtol_hex_prefix:
    add  si, 2
    mov  ax, 16
    jmp  strtol_set_base
strtol_dec:
    mov  ax, 10

strtol_set_base:
    mov  word ptr [bp - 2], ax

    cmp  ax, 16
    jne  strtol_conv
    mov  al, byte ptr [si]
    cmp  al, '0'
    jne  strtol_conv
    mov  al, byte ptr [si+1]
    cmp  al, 'x'
    je   strtol_skip_0x
    cmp  al, 'X'
    je   strtol_skip_0x
    jmp  strtol_conv
strtol_skip_0x:
    add  si, 2

strtol_conv:
    mov  al, byte ptr [si]
    cmp  al, 0
    je   strtol_end
    cmp  al, '0'
    jb   strtol_end
    cmp  al, '9'
    ja   strtol_alpha
    sub  al, '0'
    jmp  strtol_digit
strtol_alpha:
    cmp  al, 'A'
    jb   strtol_end
    cmp  al, 'F'
    jbe  strtol_upper
    cmp  al, 'a'
    jb   strtol_end
    cmp  al, 'f'
    ja   strtol_end
    sub  al, 'a'
    add  al, 10
    jmp  strtol_digit
strtol_upper:
    sub  al, 'A'
    add  al, 10

strtol_digit:
    xor  ah, ah
    cmp  ax, word ptr [bp - 2]
    jae  strtol_end

    push ax
    mov  ax, di
    mul  word ptr [bp - 2]
    mov  di, ax
    pop  ax
    add  di, ax
    inc  si
    jmp  strtol_conv

strtol_end:
    mov  bx, word ptr [bp + 6]
    cmp  bx, 0
    je   strtol_apply_sign
    mov  word ptr [bx], si

strtol_apply_sign:
    mov  ax, di
    cmp  word ptr [bp - 4], 0
    je   strtol_done
    neg  ax

strtol_done:
    pop  di
    pop  si
    pop  bx
    mov  sp, bp
    pop  bp
    ret
_strtol endp

_strdup proc near
    push bp
    mov  bp, sp
    sub  sp, 6
    push bx
    push si
    push di
    push es

    push word ptr [bp + 4]
    call _strlen
    add  sp, 2

    mov  word ptr [bp - 2], ax
    inc  ax
    push ax
    call _malloc
    add  sp, 2

    mov  word ptr [bp - 4], ax
    mov  word ptr [bp - 6], dx

    mov  si, word ptr [bp + 4]
    mov  es, dx
    mov  di, ax

    mov  cx, word ptr [bp - 2]
    inc  cx

strdup_loop:
    mov  al, byte ptr [si]
    mov  byte ptr es:[di], al
    inc  si
    inc  di
    loop strdup_loop

    mov  ax, word ptr [bp - 4]
    mov  dx, word ptr [bp - 6]

    pop  es
    pop  di
    pop  si
    pop  bx
    mov  sp, bp
    pop  bp
    ret
_strdup endp

_putint proc near
    push bp
    mov  bp, sp
    sub  sp, 10
    push bx
    push cx
    push dx
    push si

    mov  ax, word ptr [bp + 4]
    lea  si, [bp - 9]
    mov  byte ptr [si], 0
    dec  si

    xor  cx, cx
    cmp  ax, 0
    jge  putint_pos
    mov  cx, 1
    neg  ax

putint_pos:
    mov  bx, 10
putint_lp:
    xor  dx, dx
    div  bx
    add  dl, '0'
    mov  byte ptr [si], dl
    dec  si
    cmp  ax, 0
    jne  putint_lp

    cmp  cx, 1
    jne  putint_pr
    mov  byte ptr [si], '-'
    dec  si

putint_pr:
    inc  si
    push si
    call _putstr
    add  sp, 2

    pop  si
    pop  dx
    pop  cx
    pop  bx
    mov  sp, bp
    pop  bp
    ret
_putint endp