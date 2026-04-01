.386

arg1 equ 4
arg2 equ 6
arg3 equ 8

stack segment para stack
db 65530 dup(?)
stack ends

data segment para public

input db 255, 0, 256 dup(0)
base_input db 3, 0, 4 dup(0)

msg_base db "base (d/h): $"
msg_expr db "expression: $"
msg_ok_dec db "dec: $"
msg_ok_hex db "hex: $"
msg_errfmt db "invalid format$"
msg_errop  db "invalid operator$"
msg_errdiv db "division by zero$"
msg_errrng db "number out of range$"
msg_errbase db "invalid base$"
msg_errdov db "division overflow$"

buf db 32 dup(0)

ERROR_FORMAT equ 1
ERROR_OPERATOR equ 2
ERROR_DIV_ZERO equ 3
ERROR_RANGE equ 4
ERROR_BASE equ 5
ERROR_DIV_OVER equ 6

num1 dw ?
num2 dw ?
op db ?
base db ?
res_lo dw ?
res_hi dw ?
is_32 db ?

data ends

code segment para public use16
assume cs:code, ds:data, ss:stack

; функция для вывода строки с '$'-терминатором на экран
_putstr:
    push bp
    mov bp, sp
    mov dx, [bp+arg1]
    mov ah, 09h
    int 21h
    pop bp
    ret

; функция для вывода перевода строки CR+LF
_newline:
    push bp
    mov bp, sp
    mov dl, 13
    mov ah, 02h
    int 21h
    mov dl, 10
    int 21h
    pop bp
    ret

; функция для чтения строки через DOS, добавляет нуль-терминатор
_getstr:
    push bp
    mov bp, sp
    mov dx, [bp+arg1]
    mov ah, 0Ah
    int 21h
    mov bx, [bp+arg1]
    xor cx, cx
    mov cl, byte ptr [bx+1]
    add bx, 2
    add bx, cx
    mov byte ptr [bx], 0
    pop bp
    ret

; функция для запроса системы счисления (d/h), сохраняет в [base]
_read_base:
    push bp
    mov bp, sp

    push offset msg_base
    call _putstr
    add sp, 2

    push offset base_input
    call _getstr
    add sp, 2

    call _newline

    cmp byte ptr [base_input+1], 1
    jne read_base_err

    mov al, byte ptr [base_input+2]
    cmp al, 'd'
    je read_base_ok
    cmp al, 'h'
    je read_base_ok

read_base_err:
    mov ax, ERROR_BASE
    stc
    jmp read_base_exit

read_base_ok:
    mov byte ptr [base], al
    clc

read_base_exit:
    pop bp
    ret

; функция для преобразования десятичной строки в знаковое 16-битное число
_atoi:
    push bp
    mov bp, sp
    push cx
    push dx
    push di

    mov si, [bp+arg1]
    xor ax, ax
    xor di, di

    cmp byte ptr [si], '-'
    jne atoi_check_digits
    mov di, 1
    inc si

atoi_check_digits:
    cmp byte ptr [si], '0'
    jb atoi_err
    cmp byte ptr [si], '9'
    ja atoi_err

atoi_loop:
    mov dl, byte ptr [si]
    cmp dl, ' '
    je atoi_done
    cmp dl, 0
    je atoi_done

    cmp dl, '0'
    jb atoi_err
    cmp dl, '9'
    ja atoi_err

    sub dl, '0'
    xor dh, dh
    xor cx, cx
    mov cx, dx

    cmp di, 0
    jne atoi_check_neg

    cmp ax, 3276
    ja atoi_range
    jne atoi_safe_mul
    cmp cl, 7
    ja atoi_range
    jmp atoi_safe_mul

atoi_check_neg:
    cmp ax, 3276
    ja atoi_range
    jne atoi_safe_mul
    cmp cl, 8
    ja atoi_range

atoi_safe_mul:
    imul ax, 10
    add ax, cx
    inc si
    jmp atoi_loop

atoi_done:
    cmp di, 0
    je atoi_ok
    neg ax

atoi_ok:
    clc
    jmp atoi_exit

atoi_err:
    mov ax, ERROR_FORMAT
    stc
    jmp atoi_exit

atoi_range:
    mov ax, ERROR_RANGE
    stc

atoi_exit:
    pop di
    pop dx
    pop cx
    pop bp
    ret

; функция для преобразования hex-строки в знаковое 16-битное число
_atoi_hex:
    push bp
    mov bp, sp
    push bx
    push cx
    push di

    mov si, [bp+arg1]
    xor ax, ax
    xor di, di

    cmp byte ptr [si], '-'
    jne atoi_hex_check
    mov di, 1
    inc si

atoi_hex_check:
    mov cl, byte ptr [si]
    cmp cl, '0'
    jb atoi_hex_err
    cmp cl, '9'
    jbe atoi_hex_loop
    cmp cl, 'A'
    jb atoi_hex_err
    cmp cl, 'F'
    jbe atoi_hex_loop
    cmp cl, 'a'
    jb atoi_hex_err
    cmp cl, 'f'
    jbe atoi_hex_loop
    jmp atoi_hex_err

atoi_hex_loop:
    mov cl, byte ptr [si]
    cmp cl, ' '
    je atoi_hex_done
    cmp cl, 0
    je atoi_hex_done

    cmp cl, '0'
    jb atoi_hex_err
    cmp cl, '9'
    jbe atoi_hex_digit_09
    cmp cl, 'A'
    jb atoi_hex_try_lower
    cmp cl, 'F'
    jbe atoi_hex_digit_AF

atoi_hex_try_lower:
    cmp cl, 'a'
    jb atoi_hex_err
    cmp cl, 'f'
    ja atoi_hex_err
    sub cl, 20h

atoi_hex_digit_AF:
    sub cl, 'A'
    add cl, 10
    jmp atoi_hex_apply

atoi_hex_digit_09:
    sub cl, '0'

atoi_hex_apply:
    xor ch, ch

    cmp di, 0
    jne atoi_hex_check_neg_ov

    cmp ax, 2048
    jae atoi_hex_range
    jmp atoi_hex_safe

atoi_hex_check_neg_ov:
    cmp ax, 2048
    ja atoi_hex_range
    jb atoi_hex_safe
    cmp cl, 0
    ja atoi_hex_range

atoi_hex_safe:
    shl ax, 4
    add ax, cx
    inc si
    jmp atoi_hex_loop

atoi_hex_done:
    cmp di, 0
    je atoi_hex_ok
    neg ax

atoi_hex_ok:
    clc
    jmp atoi_hex_exit

atoi_hex_err:
    mov ax, ERROR_FORMAT
    stc
    jmp atoi_hex_exit

atoi_hex_range:
    mov ax, ERROR_RANGE
    stc

atoi_hex_exit:
    pop di
    pop cx
    pop bx
    pop bp
    ret

; функция для проверки формата и парсинга выражения в десятичной системе
_check:
    push bp
    mov bp, sp
    push bx
    push cx
    push dx

    mov si, [bp+arg1]

    push si
    call _atoi
    pop dx
    jc check_exit_err
    mov word ptr [num1], ax

    cmp byte ptr [si], ' '
    jne check_fmt_err
    inc si

    mov al, byte ptr [si]
    cmp al, '+'
    je check_op_ok
    cmp al, '-'
    je check_op_ok
    cmp al, '*'
    je check_op_ok
    cmp al, '/'
    je check_op_ok
    cmp al, '%'
    je check_op_ok

    mov ax, ERROR_OPERATOR
    stc
    jmp check_exit_err

check_op_ok:
    mov byte ptr [op], al
    inc si

    cmp byte ptr [si], ' '
    jne check_fmt_err
    inc si

    push si
    call _atoi
    pop dx
    jc check_exit_err
    mov word ptr [num2], ax

    cmp byte ptr [si], 0
    jne check_fmt_err

    clc
    jmp check_exit

check_fmt_err:
    mov ax, ERROR_FORMAT
    stc

check_exit_err:
check_exit:
    pop dx
    pop cx
    pop bx
    pop bp
    ret

; функция для проверки формата и парсинга выражения в hex системе
_check_hex:
    push bp
    mov bp, sp
    push bx
    push cx
    push dx

    mov si, [bp+arg1]

    push si
    call _atoi_hex
    pop dx
    jc check_hex_exit_err
    mov word ptr [num1], ax

    cmp byte ptr [si], ' '
    jne check_hex_fmt_err
    inc si

    mov al, byte ptr [si]
    cmp al, '+'
    je check_hex_op_ok
    cmp al, '-'
    je check_hex_op_ok
    cmp al, '*'
    je check_hex_op_ok
    cmp al, '/'
    je check_hex_op_ok
    cmp al, '%'
    je check_hex_op_ok

    mov ax, ERROR_OPERATOR
    stc
    jmp check_hex_exit_err

check_hex_op_ok:
    mov byte ptr [op], al
    inc si

    cmp byte ptr [si], ' '
    jne check_hex_fmt_err
    inc si

    push si
    call _atoi_hex
    pop dx
    jc check_hex_exit_err
    mov word ptr [num2], ax

    cmp byte ptr [si], 0
    jne check_hex_fmt_err

    clc
    jmp check_hex_exit

check_hex_fmt_err:
    mov ax, ERROR_FORMAT
    stc

check_hex_exit_err:
check_hex_exit:
    pop dx
    pop cx
    pop bx
    pop bp
    ret

; функция для преобразования знакового 16-битного числа в десятичную строку
_itoa:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov ax, [bp+arg1]
    mov bx, [bp+arg2]
    xor di, di

    cmp ax, 0
    jge itoa_not_neg
    mov di, 1
    neg ax

itoa_not_neg:
    cmp ax, 0
    jne itoa_not_zero
    mov byte ptr [bx], '0'
    mov byte ptr [bx+1], '$'
    jmp itoa_end

itoa_not_zero:
    mov si, bx
    add si, 10
    mov byte ptr [si], '$'

itoa_conv_loop:
    xor dx, dx
    mov cx, 10
    div cx
    add dl, '0'
    dec si
    mov byte ptr [si], dl
    cmp ax, 0
    jne itoa_conv_loop

    cmp di, 0
    je itoa_copy
    dec si
    mov byte ptr [si], '-'

itoa_copy:
    cmp si, bx
    je itoa_end

itoa_copy_loop:
    mov cl, byte ptr [si]
    mov byte ptr [bx], cl
    inc bx
    inc si
    cmp byte ptr [si], '$'
    jne itoa_copy_loop
    mov byte ptr [bx], '$'

itoa_end:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret

; функция для преобразования знакового 16-битного числа в hex строку
_itoa_hex16:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    push si

    mov ax, [bp+arg1]
    mov si, [bp+arg2]

    cmp ax, 0
    jge itoa_h16_pos
    mov byte ptr [si], '-'
    inc si
    neg ax

itoa_h16_pos:
    mov dx, ax
    mov cx, 4
    xor bx, bx

itoa_h16_loop:
    rol dx, 4
    mov ax, dx
    and ax, 000Fh

    cmp bx, 0
    jne itoa_h16_write
    cmp ax, 0
    je itoa_h16_skip
    mov bx, 1

itoa_h16_write:
    cmp al, 10
    jb itoa_h16_below
    add al, 'A' - 10
    jmp itoa_h16_store
itoa_h16_below:
    add al, '0'
itoa_h16_store:
    mov byte ptr [si], al
    inc si

itoa_h16_skip:
    loop itoa_h16_loop

    cmp bx, 0
    jne itoa_h16_done
    mov byte ptr [si], '0'
    inc si

itoa_h16_done:
    mov byte ptr [si], '$'

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret

; функция для преобразования знакового 32-битного числа в десятичную строку
_itoa32:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov ax, [bp+arg1]
    mov dx, [bp+arg2]
    mov di, [bp+arg3]

    cmp ax, 0
    jne itoa32_not_zero
    cmp dx, 0
    jne itoa32_not_zero
    mov byte ptr [di], '0'
    mov byte ptr [di+1], '$'
    jmp itoa32_end

itoa32_not_zero:
    xor cx, cx
    test dx, 8000h
    jz itoa32_pos
    not ax
    not dx
    add ax, 1
    adc dx, 0
    mov cx, 1

itoa32_pos:
    push cx
    push di
    add di, 16
    mov byte ptr [di], '$'

itoa32_divide:
    push di
    xor si, si
    mov cx, 32
    mov di, ax
    mov bx, dx
    xor ax, ax
    xor dx, dx

itoa32_div_loop:
    shl di, 1
    rcl bx, 1
    rcl si, 1
    cmp si, 10
    jb itoa32_below_10
    sub si, 10
    shl ax, 1
    rcl dx, 1
    or ax, 1
    jmp itoa32_next_bit

itoa32_below_10:
    shl ax, 1
    rcl dx, 1

itoa32_next_bit:
    loop itoa32_div_loop

    mov cx, si
    pop di
    add cl, '0'
    dec di
    mov byte ptr [di], cl

    or dx, dx
    jnz itoa32_divide
    or ax, ax
    jnz itoa32_divide

    pop si
    pop cx
    cmp cx, 1
    jne itoa32_copy
    dec di
    mov byte ptr [di], '-'

itoa32_copy:
    xor bx, bx
itoa32_copy_loop:
    mov bl, byte ptr [di]
    mov byte ptr [si], bl
    inc si
    inc di
    cmp byte ptr [di], '$'
    jne itoa32_copy_loop
    mov byte ptr [si], '$'

itoa32_end:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret

; функция для преобразования знакового 32-битного числа в hex строку
_itoa_hex32:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov ax, [bp+arg1]
    mov dx, [bp+arg2]
    mov di, [bp+arg3]

    xor cx, cx
    test dx, 8000h
    jz itoa_h32_pos
    mov byte ptr [di], '-'
    inc di
    not ax
    not dx
    add ax, 1
    adc dx, 0

itoa_h32_pos:
    cmp dx, 0
    jne itoa_h32_nonzero
    cmp ax, 0
    jne itoa_h32_nonzero
    mov byte ptr [di], '0'
    inc di
    jmp itoa_h32_finish

itoa_h32_nonzero:
    mov si, ax
    mov bx, dx
    xor cx, cx

    push si
    mov dx, bx
    mov si, 4

itoa_h32_hi_loop:
    rol dx, 4
    mov ax, dx
    and ax, 000Fh

    cmp cx, 0
    jne itoa_h32_hi_write
    cmp ax, 0
    je itoa_h32_hi_skip
    mov cx, 1

itoa_h32_hi_write:
    cmp al, 10
    jb itoa_h32_hi_below
    add al, 'A' - 10
    jmp itoa_h32_hi_store
itoa_h32_hi_below:
    add al, '0'
itoa_h32_hi_store:
    mov byte ptr [di], al
    inc di

itoa_h32_hi_skip:
    dec si
    jnz itoa_h32_hi_loop
    pop si

    mov dx, si
    mov si, 4

    cmp cx, 0
    je itoa_h32_lo_loop

itoa_h32_lo_loop_full:
    rol dx, 4
    mov ax, dx
    and ax, 000Fh
    cmp al, 10
    jb itoa_h32_lof_below
    add al, 'A' - 10
    jmp itoa_h32_lof_store
itoa_h32_lof_below:
    add al, '0'
itoa_h32_lof_store:
    mov byte ptr [di], al
    inc di
    dec si
    jnz itoa_h32_lo_loop_full
    jmp itoa_h32_finish

itoa_h32_lo_loop:
    rol dx, 4
    mov ax, dx
    and ax, 000Fh

    cmp cx, 0
    jne itoa_h32_lo_write
    cmp ax, 0
    je itoa_h32_lo_skip
    mov cx, 1

itoa_h32_lo_write:
    cmp al, 10
    jb itoa_h32_lo_below
    add al, 'A' - 10
    jmp itoa_h32_lo_store
itoa_h32_lo_below:
    add al, '0'
itoa_h32_lo_store:
    mov byte ptr [di], al
    inc di

itoa_h32_lo_skip:
    dec si
    jnz itoa_h32_lo_loop

    cmp cx, 0
    jne itoa_h32_finish
    mov byte ptr [di], '0'
    inc di

itoa_h32_finish:
    mov byte ptr [di], '$'

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret

; функция для выполнения арифметической операции над двумя числами
_operation:
    push bp
    mov bp, sp
    push bx

    mov ax, [bp+arg1]
    mov bx, [bp+arg2]
    mov cx, [bp+arg3]

    cmp cl, '+'
    je op_add
    cmp cl, '-'
    je op_sub
    cmp cl, '*'
    je op_mul
    cmp cl, '/'
    je op_div
    cmp cl, '%'
    je op_mod

    mov ax, ERROR_OPERATOR
    stc
    jmp op_exit

op_add:
    add ax, bx
    jo op_overflow
    mov word ptr [res_lo], ax
    mov word ptr [res_hi], 0
    mov byte ptr [is_32], 0
    clc
    jmp op_exit

op_sub:
    sub ax, bx
    jo op_overflow
    mov word ptr [res_lo], ax
    mov word ptr [res_hi], 0
    mov byte ptr [is_32], 0
    clc
    jmp op_exit

op_mul:
    imul bx
    mov word ptr [res_lo], ax
    mov word ptr [res_hi], dx
    mov byte ptr [is_32], 1
    clc
    jmp op_exit

op_div:
    cmp bx, 0
    je op_div_zero
    cmp ax, 8000h
    jne op_div_safe
    cmp bx, 0FFFFh
    je op_div_over

op_div_safe:
    cwd
    idiv bx
    mov word ptr [res_lo], ax
    mov word ptr [res_hi], 0
    mov byte ptr [is_32], 0
    clc
    jmp op_exit

op_mod:
    cmp bx, 0
    je op_div_zero
    cmp ax, 8000h
    jne op_mod_safe
    cmp bx, 0FFFFh
    jne op_mod_safe
    mov word ptr [res_lo], 0
    mov word ptr [res_hi], 0
    mov byte ptr [is_32], 0
    clc
    jmp op_exit

op_mod_safe:
    cwd
    idiv bx
    mov word ptr [res_lo], dx
    mov word ptr [res_hi], 0
    mov byte ptr [is_32], 0
    clc
    jmp op_exit

op_overflow:
    mov ax, ERROR_RANGE
    stc
    jmp op_exit

op_div_zero:
    mov ax, ERROR_DIV_ZERO
    stc
    jmp op_exit

op_div_over:
    mov ax, ERROR_DIV_OVER
    stc

op_exit:
    pop bx
    pop bp
    ret

; функция для вывода результата вычисления в десятичной и hex системах
_print_result:
    push bp
    mov bp, sp

    push offset msg_ok_dec
    call _putstr
    add sp, 2

    cmp byte ptr [is_32], 1
    je pr_dec32

    push offset buf
    push word ptr [res_lo]
    call _itoa
    add sp, 4
    jmp pr_dec_out

pr_dec32:
    push offset buf
    push word ptr [res_hi]
    push word ptr [res_lo]
    call _itoa32
    add sp, 6

pr_dec_out:
    push offset buf
    call _putstr
    add sp, 2

    call _newline

    push offset msg_ok_hex
    call _putstr
    add sp, 2

    cmp byte ptr [is_32], 1
    je pr_hex32

    push offset buf
    push word ptr [res_lo]
    call _itoa_hex16
    add sp, 4
    jmp pr_hex_out

pr_hex32:
    push offset buf
    push word ptr [res_hi]
    push word ptr [res_lo]
    call _itoa_hex32
    add sp, 6

pr_hex_out:
    push offset buf
    call _putstr
    add sp, 2

    pop bp
    ret


_print_error:
    push bp
    mov bp, sp

    mov ax, [bp+arg1]

    cmp ax, ERROR_FORMAT
    je pe_fmt
    cmp ax, ERROR_OPERATOR
    je pe_op
    cmp ax, ERROR_DIV_ZERO
    je pe_div
    cmp ax, ERROR_RANGE
    je pe_rng
    cmp ax, ERROR_BASE
    je pe_base
    cmp ax, ERROR_DIV_OVER
    je pe_dov
    jmp pe_fmt

pe_fmt:
    push offset msg_errfmt
    jmp pe_print
pe_op:
    push offset msg_errop
    jmp pe_print
pe_div:
    push offset msg_errdiv
    jmp pe_print
pe_rng:
    push offset msg_errrng
    jmp pe_print
pe_base:
    push offset msg_errbase
    jmp pe_print
pe_dov:
    push offset msg_errdov

pe_print:
    call _putstr
    add sp, 2

    pop bp
    ret


_calc:
    push bp
    mov bp, sp

    call _read_base
    jc calc_error

    push offset msg_expr
    call _putstr
    pop dx

    push offset input
    call _getstr
    pop dx

    call _newline

    lea ax, [input+2]

    cmp byte ptr [base], 'h'
    je calc_use_hex

    push ax
    call _check
    pop dx
    jc calc_error
    jmp calc_compute

calc_use_hex:
    push ax
    call _check_hex
    pop dx
    jc calc_error

calc_compute:
    mov al, byte ptr [op]
    xor ah, ah
    push ax
    push word ptr [num2]
    push word ptr [num1]
    call _operation
    pop dx
    pop dx
    pop dx
    jc calc_error

    call _print_result
    jmp calc_done

calc_error:
    push ax
    call _print_error
    pop dx

calc_done:
    call _newline
    pop bp
    ret


_exit0:
    mov ax, 4C00h
    int 21h


start:
    mov ax, data
    mov ds, ax
    mov ax, stack
    mov ss, ax

    call _calc
    call _exit0
	
	code ends
end start