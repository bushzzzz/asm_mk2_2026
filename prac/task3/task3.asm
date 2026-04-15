.386

arg1 equ 4
arg2 equ 6
arg3 equ 8
arg4 equ 10

var1 equ -2
var2 equ -4
var3 equ -6
var4 equ -8
var5 equ -10
var6 equ -12
var7 equ -14
var8 equ -16

MAX_PATH_LEN equ 260

stack segment para stack
    db 65530 dup(?)
stack ends

data segment para public
    str_test_hdr    db 13, 10, "[TEST] ", 0
    str_ok          db " > OK", 13, 10, 0
    str_fail        db " > FAIL", 13, 10, 0

    str_t_strlen    db "strlen", 0
    str_t_strstr    db "strstr", 0
    str_t_strchr    db "strchr", 0
    str_t_strcpy    db "strcpy", 0
    str_t_strcat    db "strcat", 0
    str_t_strcmp    db "strcmp", 0
    str_t_stricmp   db "stricmp", 0
    str_t_strtol    db "strtol", 0
    str_t_strdup    db "strdup", 0

    str_enter_f1    db "Vvedite put' k pervomu fajlu: ", 0
    str_enter_f2    db "Vvedite put' k vtoromu fajlu: ", 0
    str_f1_read_ok  db "Fajl 1 uspeshno prochitan. Razmer: ", 0
    str_f2_read_ok  db "Fajl 2 uspeshno prochitan. Razmer: ", 0
    str_bytes       db " bajt", 13, 10, 0

    path_buf1       db MAX_PATH_LEN dup(0)
    path_buf2       db MAX_PATH_LEN dup(0)

    file1_seg       dw 0
    file1_off       dw 0
    file1_size      dw 0

    file2_seg       dw 0
    file2_off       dw 0
    file2_size      dw 0

    ts_hello        db "Hello, World!", 0
    ts_world        db "World", 0
    ts_empty        db 0
    ts_abc          db "abcdef", 0
    ts_upper        db "HELLO", 0
    ts_lower        db "hello", 0
    ts_num_dec      db "12345", 0
    ts_num_neg      db "-42", 0
    ts_num_hex      db "0xFF", 0
    ts_num_bin      db "1010", 0
    ts_str1         db "apple", 0
    ts_str2         db "banana", 0
    ts_copy_dst     db 32 dup(0)
    ts_cat_src      db "World!", 0
    ts_cat_dst      db "Hello, ", 64 dup(0)

    heap_seg       dw 0
    heap_ptr       dw 0
    heap_size      dw 0
    msg_heap_err   db "FATAL: Cannot initialize heap", 13, 10, 0
    msg_malloc_err db "FATAL: Out of memory", 13, 10, 0

    msg_fopen_err  db "ERROR: Cannot open file", 13, 10, 0
    msg_fsize_err  db "ERROR: Cannot get file size", 13, 10, 0
    msg_fread_err  db "ERROR: Cannot read file", 13, 10, 0

    tmp_endptr     dw 0
data ends

code segment para public use16
assume cs:code, ds:data, ss:stack

include strings.inc
include memory.inc
include file.inc

_print_test_name proc near
    push bp
    mov  bp, sp

    push offset str_test_hdr
    call _putstr
    add  sp, 2

    push word ptr [bp + 4]
    call _putstr
    add  sp, 2

    mov  sp, bp
    pop  bp
    ret
_print_test_name endp

_test_strlen proc near
    push bp
    mov  bp, sp

    push offset str_t_strlen
    call _print_test_name
    add  sp, 2

    push offset ts_hello
    call _strlen
    add  sp, 2
    cmp  ax, 13
    jne  test_strlen_fail

    push offset ts_empty
    call _strlen
    add  sp, 2
    cmp  ax, 0
    jne  test_strlen_fail

    push offset str_ok
    call _putstr
    add  sp, 2
    jmp  short test_strlen_done

test_strlen_fail:
    push offset str_fail
    call _putstr
    add  sp, 2

test_strlen_done:
    mov  sp, bp
    pop  bp
    ret
_test_strlen endp

_test_strstr proc near
    push bp
    mov  bp, sp

    push offset str_t_strstr
    call _print_test_name
    add  sp, 2

    push offset ts_world
    push offset ts_hello
    call _strstr
    add  sp, 4
    cmp  ax, 0
    je   test_strstr_fail

    push offset ts_empty
    push offset ts_hello
    call _strstr
    add  sp, 4
    cmp  ax, offset ts_hello
    jne  test_strstr_fail

    push offset str_ok
    call _putstr
    add  sp, 2
    jmp  short test_strstr_done

test_strstr_fail:
    push offset str_fail
    call _putstr
    add  sp, 2

test_strstr_done:
    mov  sp, bp
    pop  bp
    ret
_test_strstr endp

_test_strchr proc near
    push bp
    mov  bp, sp

    push offset str_t_strchr
    call _print_test_name
    add  sp, 2

    push 'W'
    push offset ts_hello
    call _strchr
    add  sp, 4
    cmp  ax, 0
    je   test_strchr_fail

    push 'Z'
    push offset ts_hello
    call _strchr
    add  sp, 4
    cmp  ax, 0
    jne  test_strchr_fail

    push offset str_ok
    call _putstr
    add  sp, 2
    jmp  short test_strchr_done

test_strchr_fail:
    push offset str_fail
    call _putstr
    add  sp, 2

test_strchr_done:
    mov  sp, bp
    pop  bp
    ret
_test_strchr endp

_test_strcpy proc near
    push bp
    mov  bp, sp

    push offset str_t_strcpy
    call _print_test_name
    add  sp, 2

    push offset ts_hello
    push offset ts_copy_dst
    call _strcpy
    add  sp, 4

    push offset ts_hello
    push offset ts_copy_dst
    call _strcmp
    add  sp, 4
    cmp  ax, 0
    jne  test_strcpy_fail

    push offset str_ok
    call _putstr
    add  sp, 2
    jmp  short test_strcpy_done

test_strcpy_fail:
    push offset str_fail
    call _putstr
    add  sp, 2

test_strcpy_done:
    mov  sp, bp
    pop  bp
    ret
_test_strcpy endp

_test_strcat proc near
    push bp
    mov  bp, sp

    push offset str_t_strcat
    call _print_test_name
    add  sp, 2

    mov  byte ptr [ts_cat_dst+0], 'H'
    mov  byte ptr [ts_cat_dst+1], 'e'
    mov  byte ptr [ts_cat_dst+2], 'l'
    mov  byte ptr [ts_cat_dst+3], 'l'
    mov  byte ptr [ts_cat_dst+4], 'o'
    mov  byte ptr [ts_cat_dst+5], ','
    mov  byte ptr [ts_cat_dst+6], ' '
    mov  byte ptr [ts_cat_dst+7], 0

    push offset ts_cat_src
    push offset ts_cat_dst
    call _strcat
    add  sp, 4

    push offset ts_cat_dst
    call _strlen
    add  sp, 2
    cmp  ax, 13
    jne  test_strcat_fail

    push offset str_ok
    call _putstr
    add  sp, 2
    jmp  short test_strcat_done

test_strcat_fail:
    push offset str_fail
    call _putstr
    add  sp, 2

test_strcat_done:
    mov  sp, bp
    pop  bp
    ret
_test_strcat endp

_test_strcmp proc near
    push bp
    mov  bp, sp

    push offset str_t_strcmp
    call _print_test_name
    add  sp, 2

    push offset ts_str1
    push offset ts_str1
    call _strcmp
    add  sp, 4
    cmp  ax, 0
    jne  test_strcmp_fail

    push offset ts_str2
    push offset ts_str1
    call _strcmp
    add  sp, 4
    cmp  ax, 0
    je   test_strcmp_fail

    push offset str_ok
    call _putstr
    add  sp, 2
    jmp  short test_strcmp_done

test_strcmp_fail:
    push offset str_fail
    call _putstr
    add  sp, 2

test_strcmp_done:
    mov  sp, bp
    pop  bp
    ret
_test_strcmp endp

_test_stricmp proc near
    push bp
    mov  bp, sp

    push offset str_t_stricmp
    call _print_test_name
    add  sp, 2

    push offset ts_lower
    push offset ts_upper
    call _stricmp
    add  sp, 4
    cmp  ax, 0
    jne  test_stricmp_fail

    push offset ts_str2
    push offset ts_str1
    call _stricmp
    add  sp, 4
    cmp  ax, 0
    je   test_stricmp_fail

    push offset str_ok
    call _putstr
    add  sp, 2
    jmp  short test_stricmp_done

test_stricmp_fail:
    push offset str_fail
    call _putstr
    add  sp, 2

test_stricmp_done:
    mov  sp, bp
    pop  bp
    ret
_test_stricmp endp

_test_strtol proc near
    push bp
    mov  bp, sp

    push offset str_t_strtol
    call _print_test_name
    add  sp, 2

    push 10
    push offset tmp_endptr
    push offset ts_num_dec
    call _strtol
    add  sp, 6
    cmp  ax, 12345
    jne  test_strtol_fail

    push 10
    push offset tmp_endptr
    push offset ts_num_neg
    call _strtol
    add  sp, 6
    cmp  ax, -42
    jne  test_strtol_fail

    push 0
    push offset tmp_endptr
    push offset ts_num_hex
    call _strtol
    add  sp, 6
    cmp  ax, 255
    jne  test_strtol_fail

    push offset str_ok
    call _putstr
    add  sp, 2
    jmp  short test_strtol_done

test_strtol_fail:
    push offset str_fail
    call _putstr
    add  sp, 2

test_strtol_done:
    mov  sp, bp
    pop  bp
    ret
_test_strtol endp

_test_strdup proc near
    push bp
    mov  bp, sp
    push bx
    push si
    push es

    push offset str_t_strdup
    call _print_test_name
    add  sp, 2

    push offset ts_hello
    call _strdup
    add  sp, 2

    cmp  dx, 0
    je   test_strdup_fail

    mov  es, dx
    mov  bx, ax
    mov  si, offset ts_hello

test_strdup_cmp:
    mov  al, es:[bx]
    cmp  al, byte ptr [si]
    jne  test_strdup_fail
    cmp  al, 0
    je   test_strdup_ok
    inc  bx
    inc  si
    jmp  test_strdup_cmp

test_strdup_ok:
    push offset str_ok
    call _putstr
    add  sp, 2
    jmp  short test_strdup_done

test_strdup_fail:
    push offset str_fail
    call _putstr
    add  sp, 2

test_strdup_done:
    pop  es
    pop  si
    pop  bx
    mov  sp, bp
    pop  bp
    ret
_test_strdup endp

_run_file_test proc near
    push bp
    mov  bp, sp

    push offset str_enter_f1
    call _putstr
    add  sp, 2

    push MAX_PATH_LEN
    push offset path_buf1
    call _getstr
    add  sp, 4

    push offset str_enter_f2
    call _putstr
    add  sp, 2

    push MAX_PATH_LEN
    push offset path_buf2
    call _getstr
    add  sp, 4

    push offset file1_off
    push offset file1_seg
    push offset path_buf1
    call _fread_all
    add  sp, 6
    mov  file1_size, ax
    cmp  ax, 0
    je   file_test_done

    push offset str_f1_read_ok
    call _putstr
    add  sp, 2
    push file1_size
    call _putint
    add  sp, 2
    push offset str_bytes
    call _putstr
    add  sp, 2

    push offset file2_off
    push offset file2_seg
    push offset path_buf2
    call _fread_all
    add  sp, 6
    mov  file2_size, ax
    cmp  ax, 0
    je   file_test_done

    push offset str_f2_read_ok
    call _putstr
    add  sp, 2
    push file2_size
    call _putint
    add  sp, 2
    push offset str_bytes
    call _putstr
    add  sp, 2

file_test_done:
    mov  sp, bp
    pop  bp
    ret
_run_file_test endp

_tests proc near
    push bp
    mov  bp, sp

    call _heap_init

    call _test_strlen
    call _test_strstr
    call _test_strchr
    call _test_strcpy
    call _test_strcat
    call _test_strcmp
    call _test_stricmp
    call _test_strtol
    call _test_strdup

    call _run_file_test

    mov  sp, bp
    pop  bp
    ret
_tests endp

start:
    mov  ax, data
    mov  ds, ax
    mov  ax, stack
    mov  ss, ax

    call _tests
    call _exit0
	code ends

end start