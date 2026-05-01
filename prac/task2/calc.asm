.386

arg1 equ 4
arg2 equ 6
arg3 equ 8

stack segment para stack 'stack' use16
    db 65535 dup(?)
stack ends

data segment para public 'data' use16
    input db 255, 0, 256 dup(0)
    base_input   db 3, 0, 4 dup(0)

    msg_base     db "base (d/h): $"
    msg_expr     db "expression (num1 op num2): $"
    msg_ok_dec   db "dec: $"
    msg_ok_hex   db "hex: $"
    msg_errfmt   db "invalid format$"
    msg_errop    db "invalid operator$"
    msg_errdiv   db "division by zero$"
    msg_errrng   db "number out of range$"
    msg_errbase  db "invalid base$"
    msg_errdov   db "division overflow$"

    buf db 32 dup(0)

    ERROR_FORMAT     equ 1
    ERROR_OPERATOR   equ 2
    ERROR_DIV_ZERO   equ 3
    ERROR_RANGE      equ 4
    ERROR_BASE       equ 5
    ERROR_DIV_OVER   equ 6

    num1   dw ?
    num2   dw ?
    op     db ?
    base   db ?
    res_lo dw ?
    res_hi dw ?
    is_32  db ?

    atoi_ptr dw ?
data ends

code segment para public use16
    assume cs:code, ds:data, ss:stack

_putstr proc near
    push bp
    mov  bp, sp
    mov  dx, [bp+arg1]
    mov  ah, 09h
    int  21h
    pop  bp
    ret
_putstr endp

_newline proc near
    push bp
    mov  bp, sp
    mov  dl, 13
    mov  ah, 02h
    int  21h
    mov  dl, 10
    int  21h
    pop  bp
    ret
_newline endp

_getstr proc near
    push bp
    mov  bp, sp
    mov  dx, [bp+arg1]
    mov  ah, 0Ah
    int  21h
    mov  bx, [bp+arg1]
    xor  cx, cx
    mov  cl, byte ptr [bx+1]
    add  bx, 2
    add  bx, cx
    mov  byte ptr [bx], '$'
    pop  bp
    ret
_getstr endp

_read_base proc near
    push bp
    mov  bp, sp

    push offset msg_base
    call _putstr
    add  sp, 2

    push offset base_input
    call _getstr
    add  sp, 2

    call _newline

    cmp  byte ptr [base_input+1], 1
    jne  read_base_err
    mov  al, byte ptr [base_input+2]
    cmp  al, 'd'
    je   read_base_ok
    cmp  al, 'h'
    je   read_base_ok
read_base_err:
    mov  ax, ERROR_BASE
    stc
    jmp  read_base_exit
read_base_ok:
    mov  byte ptr [base], al
    clc
read_base_exit:
    pop  bp
    ret
_read_base endp

_atoi_dec proc near
    push bp
    mov  bp, sp
    push si
    push bx
    push dx

    mov  si, [bp+4]
    mov  cx, [bp+6]
    xor  ax, ax
    xor  di, di

    cmp  cx, 0
    je   atoi_dec_done

    cmp  byte ptr [si], '-'
    jne  atoi_dec_no_sign
    mov  di, 1
    inc  si
    dec  cx
    jz   atoi_dec_done

atoi_dec_no_sign:
atoi_dec_loop:
    mov  bl, [si]
    cmp  bl, '0'
    jb   atoi_dec_err
    cmp  bl, '9'
    ja   atoi_dec_err
    sub  bl, '0'
    xor  bh, bh

    cmp  ax, 3276
    ja   atoi_dec_overflow
    jne  atoi_dec_safe
    cmp  di, 0
    jne  atoi_dec_neg_limit
    cmp  bl, 7
    ja   atoi_dec_overflow
    jmp  atoi_dec_safe
atoi_dec_neg_limit:
    cmp  bl, 8
    ja   atoi_dec_overflow

atoi_dec_safe:
    imul ax, 10
    add  ax, bx
    inc  si
    loop atoi_dec_loop

atoi_dec_done:
    cmp  di, 0
    je   atoi_dec_ok
    cmp  ax, 32768
    je   atoi_dec_neg32768
    neg  ax
    jmp  atoi_dec_ok
atoi_dec_neg32768:
    mov  ax, -32768
atoi_dec_ok:
    clc
    jmp  atoi_dec_exit

atoi_dec_err:
    mov  ax, ERROR_FORMAT
    stc
    jmp  atoi_dec_exit

atoi_dec_overflow:
    mov  ax, ERROR_RANGE
    stc

atoi_dec_exit:
    pop  dx
    pop  bx
    pop  si
    pop  bp
    ret
_atoi_dec endp

_atoi_hex proc near
    push bp
    mov  bp, sp
    push si
    push di
    push bx
    push dx

    mov  si, [bp+4]
    mov  cx, [bp+6]
    xor  ax, ax
    xor  di, di

    cmp  cx, 0
    je   atoi_hex_err

    cmp  byte ptr [si], '-'
    jne  atoi_hex_check_prefix
    mov  di, 1
    inc  si
    dec  cx
    jz   atoi_hex_err

atoi_hex_check_prefix:
    cmp  cx, 2
    jb   atoi_hex_loop
    cmp  word ptr [si], 'x0'
    je   skip_prefix
    cmp  word ptr [si], 'X0'
    jne  atoi_hex_loop
skip_prefix:
    add  si, 2
    sub  cx, 2
    jz   atoi_hex_err

atoi_hex_loop:
    mov  bl, [si]
    cmp  bl, '0'
    jb   atoi_hex_err
    cmp  bl, '9'
    jbe  digit09
    cmp  bl, 'A'
    jb   atoi_hex_err
    cmp  bl, 'F'
    jbe  digitAF
    cmp  bl, 'a'
    jb   atoi_hex_err
    cmp  bl, 'f'
    ja   atoi_hex_err
    sub  bl, 'a'-'A'
digitAF:
    sub  bl, 'A'
    add  bl, 10
    jmp  got_digit
digit09:
    sub  bl, '0'
got_digit:
    xor  bh, bh

    cmp  di, 0
    jne  atoi_hex_neg_chk
    cmp  ax, 4096
    ja   atoi_hex_overflow
    jne  atoi_hex_safe
    cmp  bl, 15
    jmp  atoi_hex_safe
atoi_hex_neg_chk:
    cmp  ax, 2048
    ja   atoi_hex_overflow
    jne  atoi_hex_safe
    cmp  bl, 0
    jne  atoi_hex_overflow

atoi_hex_safe:
    shl  ax, 4
    add  ax, bx
    inc  si
    dec  cx
    jnz  atoi_hex_loop

    cmp  di, 0
    je   atoi_hex_ok
    cmp  ax, 32768
    je   atoi_hex_minus32768
    neg  ax
    jmp  atoi_hex_ok
atoi_hex_minus32768:
    mov  ax, -32768
atoi_hex_ok:
    clc
    jmp  atoi_hex_exit

atoi_hex_err:
    mov  ax, ERROR_FORMAT
    stc
    jmp  atoi_hex_exit

atoi_hex_overflow:
    mov  ax, ERROR_RANGE
    stc

atoi_hex_exit:
    pop  dx
    pop  bx
    pop  di
    pop  si
    pop  bp
    ret
_atoi_hex endp

parse_expression proc near
    push bp
    mov  bp, sp
    sub  sp, 6

    mov  si, [bp+4]
    mov  cx, [bp+6]
    mov  word ptr [bp-6], 0

skip_spc1:
    cmp  byte ptr [si], ' '
    jne  found_num1_start
    inc  si
    dec  cx
    jg   skip_spc1
    jmp  parse_fmt_err
found_num1_start:
    mov  di, si
find_end1:
    cmp  cx, 0
    je   end1_found
    cmp  byte ptr [si], ' '
    je   end1_found
    cmp  byte ptr [si], '$'
    je   end1_found
    inc  si
    dec  cx
    jmp  find_end1
end1_found:
    mov  ax, si
    sub  ax, di
    push cx
    push ax
    push di
    call [atoi_ptr]
    add  sp, 4
    pop  cx
    jc   parse_exit_err
    mov  [num1], ax

    cmp  cx, 0
    je   parse_fmt_err
    cmp  byte ptr [si], ' '
    jne  parse_fmt_err
    inc  si
    dec  cx
    jz   parse_fmt_err
    mov  al, [si]
    cmp  al, '+'
    je   op_ok
    cmp  al, '-'
    je   op_ok
    cmp  al, '*'
    je   op_ok
    cmp  al, '/'
    je   op_ok
    cmp  al, '%'
    je   op_ok
    mov  ax, ERROR_OPERATOR
    stc
    jmp  parse_exit_err
op_ok:
    mov  [op], al
    inc  si
    dec  cx
    jz   parse_fmt_err
    cmp  byte ptr [si], ' '
    jne  parse_fmt_err
    inc  si
    dec  cx
    jz   parse_fmt_err

    mov  di, si
find_end2:
    cmp  cx, 0
    je   end2_found
    cmp  byte ptr [si], ' '
    je   end2_found
    cmp  byte ptr [si], '$'
    je   end2_found
    inc  si
    dec  cx
    jmp  find_end2
end2_found:
    mov  ax, si
    sub  ax, di
    push cx
    push ax
    push di
    call [atoi_ptr]
    add  sp, 4
    pop  cx
    jc   parse_exit_err
    mov  [num2], ax
    clc
    jmp  parse_exit

parse_fmt_err:
    mov  ax, ERROR_FORMAT
    stc
    jmp  parse_exit
parse_exit_err:
parse_exit:
    mov  sp, bp
    pop  bp
    ret
parse_expression endp

_operation proc near
    push bp
    mov  bp, sp

    mov  ax, [num1]
    mov  bx, [num2]
    mov  cl, [op]

    cmp  cl, '+'
    je   op_add
    cmp  cl, '-'
    je   op_sub
    cmp  cl, '*'
    je   op_mul
    cmp  cl, '/'
    je   op_div
    cmp  cl, '%'
    je   op_mod
    mov  ax, ERROR_OPERATOR
    stc
    jmp  op_exit

op_add:
    add  ax, bx
    jo   op_ovf
    mov  [res_lo], ax
    mov  word ptr [res_hi], 0
    mov  byte ptr [is_32], 0
    clc
    jmp  op_exit

op_sub:
    sub  ax, bx
    jo   op_ovf
    mov  [res_lo], ax
    mov  word ptr [res_hi], 0
    mov  byte ptr [is_32], 0
    clc
    jmp  op_exit

op_mul:
    imul bx
    mov  [res_lo], ax
    mov  [res_hi], dx
    mov  byte ptr [is_32], 1
    clc
    jmp  op_exit

op_div:
    cmp  bx, 0
    je   op_div_zero
    cmp  ax, 8000h
    jne  do_div
    cmp  bx, 0FFFFh
    je   op_div_ovf
do_div:
    cwd
    idiv bx
    mov  [res_lo], ax
    mov  word ptr [res_hi], 0
    mov  byte ptr [is_32], 0
    clc
    jmp  op_exit

op_mod:
    cmp  bx, 0
    je   op_div_zero
    cmp  ax, 8000h
    jne  do_mod
    cmp  bx, 0FFFFh
    jne  do_mod
    mov  word ptr [res_lo], 0
    mov  word ptr [res_hi], 0
    mov  byte ptr [is_32], 0
    clc
    jmp  op_exit
do_mod:
    cwd
    idiv bx
    mov  [res_lo], dx
    mov  word ptr [res_hi], 0
    mov  byte ptr [is_32], 0
    clc
    jmp  op_exit

op_ovf:
    mov  ax, ERROR_RANGE
    stc
    jmp  op_exit
op_div_zero:
    mov  ax, ERROR_DIV_ZERO
    stc
    jmp  op_exit
op_div_ovf:
    mov  ax, ERROR_DIV_OVER
    stc
op_exit:
    pop  bp
    ret
_operation endp

_itoa proc near
    push bp
    mov  bp, sp
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov  ax, [bp+arg1]
    mov  bx, [bp+arg2]
    xor  di, di
    cmp  ax, 0
    jge  itoa_not_neg
    mov  di, 1
    neg  ax
itoa_not_neg:
    cmp  ax, 0
    jne  itoa_not_zero
    mov  byte ptr [bx], '0'
    mov  byte ptr [bx+1], '$'
    jmp  itoa_end

itoa_not_zero:
    mov  si, bx
    add  si, 10
    mov  byte ptr [si], '$'
itoa_loop:
    xor  dx, dx
    mov  cx, 10
    div  cx
    add  dl, '0'
    dec  si
    mov  [si], dl
    cmp  ax, 0
    jne  itoa_loop

    cmp  di, 0
    je   itoa_copy
    dec  si
    mov  byte ptr [si], '-'
itoa_copy:
itoa_copy_loop:
    mov  cl, [si]
    mov  [bx], cl
    inc  bx
    inc  si
    cmp  byte ptr [si], '$'
    jne  itoa_copy_loop
    mov  byte ptr [bx], '$'
itoa_end:
    pop  di
    pop  si
    pop  dx
    pop  cx
    pop  bx
    pop  ax
    pop  bp
    ret
_itoa endp

_itoa_hex16 proc near
    push bp
    mov  bp, sp
    push ax
    push bx
    push cx
    push dx
    push si

    mov  ax, [bp+arg1]
    mov  si, [bp+arg2]
    cmp  ax, 0
    jge  itoa_h16_pos
    mov  byte ptr [si], '-'
    inc  si
    neg  ax
itoa_h16_pos:
    mov  dx, ax
    mov  cx, 4
    xor  bx, bx
itoa_h16_loop:
    rol  dx, 4
    mov  ax, dx
    and  ax, 0Fh
    cmp  bx, 0
    jne  itoa_h16_write
    cmp  ax, 0
    je   itoa_h16_skip
    mov  bx, 1
itoa_h16_write:
    cmp  al, 10
    jb   itoa_h16_digit
    add  al, 'A'-10
    jmp  itoa_h16_store
itoa_h16_digit:
    add  al, '0'
itoa_h16_store:
    mov  [si], al
    inc  si
itoa_h16_skip:
    loop itoa_h16_loop
    cmp  bx, 0
    jne  itoa_h16_done
    mov  byte ptr [si], '0'
    inc  si
itoa_h16_done:
    mov  byte ptr [si], '$'
    pop  si
    pop  dx
    pop  cx
    pop  bx
    pop  ax
    pop  bp
    ret
_itoa_hex16 endp

_itoa32 proc near
    push bp
    mov  bp, sp
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov  ax, [bp+arg1]
    mov  dx, [bp+arg2]
    mov  di, [bp+arg3]

    mov  cx, 0
    test dx, 8000h
    jz   itoa32_pos
    mov  cx, 1
    not  ax
    not  dx
    add  ax, 1
    adc  dx, 0
itoa32_pos:
    push cx
    push di
    add  di, 16
    mov  byte ptr [di], '$'

itoa32_div:
    push di
    xor  si, si
    mov  cx, 32
    mov  di, ax
    mov  bx, dx
    xor  ax, ax
    xor  dx, dx
itoa32_div_loop:
    shl  di, 1
    rcl  bx, 1
    rcl  si, 1
    cmp  si, 10
    jb   itoa32_below10
    sub  si, 10
    shl  ax, 1
    rcl  dx, 1
    or   ax, 1
    jmp  itoa32_next
itoa32_below10:
    shl  ax, 1
    rcl  dx, 1
itoa32_next:
    loop itoa32_div_loop
    mov  cx, si
    pop  di
    add  cl, '0'
    dec  di
    mov  [di], cl
    or   dx, dx
    jnz  itoa32_div
    or   ax, ax
    jnz  itoa32_div
    pop  si
    pop  cx
    cmp  cx, 1
    jne  itoa32_copy
    dec  di
    mov  byte ptr [di], '-'
itoa32_copy:
    xor  bx, bx
itoa32_copy_loop:
    mov  bl, [di]
    mov  [si], bl
    inc  si
    inc  di
    cmp  byte ptr [di], '$'
    jne  itoa32_copy_loop
    mov  byte ptr [si], '$'
    pop  di
    pop  si
    pop  dx
    pop  cx
    pop  bx
    pop  ax
    pop  bp
    ret
_itoa32 endp

_itoa_hex32 proc near
    push bp
    mov  bp, sp
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov  ax, [bp+arg1]
    mov  dx, [bp+arg2]
    mov  di, [bp+arg3]

    xor  cx, cx
    test dx, 8000h
    jz   itoa_h32_pos
    mov  byte ptr [di], '-'
    inc  di
    not  ax
    not  dx
    add  ax, 1
    adc  dx, 0
itoa_h32_pos:
    cmp  dx, 0
    jne  itoa_h32_nonzero
    cmp  ax, 0
    jne  itoa_h32_nonzero
    mov  byte ptr [di], '0'
    inc  di
    jmp  itoa_h32_finish

itoa_h32_nonzero:
    mov  si, ax
    mov  bx, dx
    xor  cx, cx
    push si
    mov  dx, bx
    mov  si, 4
itoa_h32_hi_loop:
    rol  dx, 4
    mov  ax, dx
    and  ax, 0Fh
    cmp  cx, 0
    jne  itoa_h32_hi_write
    cmp  ax, 0
    je   itoa_h32_hi_skip
    mov  cx, 1
itoa_h32_hi_write:
    cmp  al, 10
    jb   itoa_h32_hi_digit
    add  al, 'A'-10
    jmp  itoa_h32_hi_store
itoa_h32_hi_digit:
    add  al, '0'
itoa_h32_hi_store:
    mov  [di], al
    inc  di
itoa_h32_hi_skip:
    dec  si
    jnz  itoa_h32_hi_loop
    pop  si

    mov  dx, si
    mov  si, 4
    cmp  cx, 0
    je   itoa_h32_lo_loop
itoa_h32_lo_loop_full:
    rol  dx, 4
    mov  ax, dx
    and  ax, 0Fh
    cmp  al, 10
    jb   itoa_h32_lo_digit
    add  al, 'A'-10
    jmp  itoa_h32_lo_store
itoa_h32_lo_digit:
    add  al, '0'
itoa_h32_lo_store:
    mov  [di], al
    inc  di
    dec  si
    jnz  itoa_h32_lo_loop_full
    jmp  itoa_h32_finish

itoa_h32_lo_loop:
    rol  dx, 4
    mov  ax, dx
    and  ax, 0Fh
    cmp  cx, 0
    jne  itoa_h32_lo_write
    cmp  ax, 0
    je   itoa_h32_lo_skip
    mov  cx, 1
itoa_h32_lo_write:
    cmp  al, 10
    jb   itoa_h32_lo_digit2
    add  al, 'A'-10
    jmp  itoa_h32_lo_store2
itoa_h32_lo_digit2:
    add  al, '0'
itoa_h32_lo_store2:
    mov  [di], al
    inc  di
itoa_h32_lo_skip:
    dec  si
    jnz  itoa_h32_lo_loop
    cmp  cx, 0
    jne  itoa_h32_finish
    mov  byte ptr [di], '0'
    inc  di
itoa_h32_finish:
    mov  byte ptr [di], '$'
    pop  di
    pop  si
    pop  dx
    pop  cx
    pop  bx
    pop  ax
    pop  bp
    ret
_itoa_hex32 endp

_print_result proc near
    push bp
    mov  bp, sp

    push offset msg_ok_dec
    call _putstr
    add  sp, 2

    cmp  byte ptr [is_32], 1
    je   pr_dec32

    push offset buf
    push [res_lo]
    call _itoa
    add  sp, 4
    jmp  pr_dec_out
pr_dec32:
    push offset buf
    push [res_hi]
    push [res_lo]
    call _itoa32
    add  sp, 6
pr_dec_out:
    push offset buf
    call _putstr
    add  sp, 2

    call _newline

    push offset msg_ok_hex
    call _putstr
    add  sp, 2

    cmp  byte ptr [is_32], 1
    je   pr_hex32

    push offset buf
    push [res_lo]
    call _itoa_hex16
    add  sp, 4
    jmp  pr_hex_out
pr_hex32:
    push offset buf
    push [res_hi]
    push [res_lo]
    call _itoa_hex32
    add  sp, 6
pr_hex_out:
    push offset buf
    call _putstr
    add  sp, 2

    pop  bp
    ret
_print_result endp

_print_error proc near
    push bp
    mov  bp, sp
    mov  ax, [bp+arg1]

    cmp  ax, ERROR_FORMAT
    je   pe_fmt
    cmp  ax, ERROR_OPERATOR
    je   pe_op
    cmp  ax, ERROR_DIV_ZERO
    je   pe_div
    cmp  ax, ERROR_RANGE
    je   pe_rng
    cmp  ax, ERROR_BASE
    je   pe_base
    cmp  ax, ERROR_DIV_OVER
    je   pe_dov
pe_fmt:
    push offset msg_errfmt
    jmp  pe_print
pe_op:
    push offset msg_errop
    jmp  pe_print
pe_div:
    push offset msg_errdiv
    jmp  pe_print
pe_rng:
    push offset msg_errrng
    jmp  pe_print
pe_base:
    push offset msg_errbase
    jmp  pe_print
pe_dov:
    push offset msg_errdov
pe_print:
    call _putstr
    add  sp, 2
    pop  bp
    ret
_print_error endp

_calc proc near
    push bp
    mov  bp, sp

    call _read_base
    jc   calc_error

    cmp  byte ptr [base], 'h'
    je   use_hex
    mov  word ptr [atoi_ptr], offset _atoi_dec
    jmp  base_set
use_hex:
    mov  word ptr [atoi_ptr], offset _atoi_hex
base_set:

    push offset msg_expr
    call _putstr
    add  sp, 2

    push offset input
    call _getstr
    add  sp, 2

    call _newline

    mov  bx, offset input
    xor  cx, cx
    mov  cl, [bx+1]

    lea  ax, [bx+2]
    push cx
    push ax
    call parse_expression
    add  sp, 4
    jc   calc_error

    call _operation
    jc   calc_error

    call _print_result
    jmp  calc_done

calc_error:
    push ax
    call _print_error
    add  sp, 2
calc_done:
    call _newline
    pop  bp
    ret
_calc endp

start:
    mov  ax, data
    mov  ds, ax
    mov  ax, stack
    mov  ss, ax

    call _calc
    mov  ax, 4C00h
    int  21h

	code ends

end start
