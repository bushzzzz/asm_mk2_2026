.386

arg1 equ 4
arg2 equ 6
arg3 equ 8
arg4 equ 10
arg5 equ 12

var1 equ -2
var2 equ -4
var3 equ -6
var4 equ -8
var5 equ -10
var6 equ -12
var7 equ -14
var8 equ -16

stack segment para stack
db 65530 dup(?)
stack ends

data segment para public
WINDOW_X equ 5
WINDOW_Y equ 2
WINDOW_WIDTH equ 70
WINDOW_HEIGHT equ 20

log_buffer db 4096 dup(0)
log_pos dw 0

file_path db 128 dup(0)
file_handle dw 0

temp_char_str db 0, 0

ctrl_pressed db 0

key_enter db '[ENTER]', 0
key_esc db '[ESC]', 0
key_f1 db '[F1]', 0
key_f2 db '[F2]', 0
key_f3 db '[F3]', 0
key_f4 db '[F4]', 0
key_f5 db '[F5]', 0
key_f6 db '[F6]', 0
key_f7 db '[F7]', 0
key_f8 db '[F8]', 0
key_f9 db '[F9]', 0
key_f10 db '[F10]', 0
key_up db '[UP]', 0
key_down db '[DOWN]', 0
key_left db '[LEFT]', 0
key_right db '[RIGHT]', 0
key_ctrl_c db '[CTRL+C]', 0
key_ctrl_l db '[CTRL+L]', 0
key_ctrl_s db '[CTRL+S]', 0

prompt1 db 'Vvedite put'' k faylu loga:', 0
prompt2 db '[Enter] - OK  [Esc] - Vyhod', 0
header_text db 'KEYLOGGER [Active]', 0
footer_text db '[Ctrl+L] - ochistit''  [Ctrl+S] - sbros v fayl', 0

save_mode db ?
data ends

code segment para public use16
assume cs:code,ds:data,ss:stack

include strings.inc

_clear_screen proc near
    push bp
    mov bp, sp
    push es
    
    mov ax, 0B800h
    mov es, ax
    xor di, di
    mov cx, 80*25
    mov ax, 0720h
    rep stosw
    
    pop es
    mov sp, bp
    pop bp
    ret
_clear_screen endp

_set_cursor proc near
    push bp
    mov bp, sp
    
    mov dh, byte ptr [bp + arg1]
    mov dl, byte ptr [bp + arg2]
    mov bh, 0
    mov ah, 02h
    int 10h
    
    mov sp, bp
    pop bp
    ret
_set_cursor endp

_write_char_at proc near
    push bp
    mov bp, sp
    push es
    
    mov ax, 0B800h
    mov es, ax
    
    movzx bx, byte ptr [bp + arg1]
    mov ax, 80
    mul bx
    movzx bx, byte ptr [bp + arg2]
    add ax, bx
    shl ax, 1
    mov di, ax
    
    mov al, byte ptr [bp + arg3]
    mov ah, byte ptr [bp + arg4]
    mov word ptr es:[di], ax
    
    pop es
    mov sp, bp
    pop bp
    ret
_write_char_at endp

_write_string_at proc near
    push bp
    mov bp, sp
    push es
    push si
    
    mov ax, 0B800h
    mov es, ax
    
    movzx bx, byte ptr [bp + arg1]
    mov ax, 80
    mul bx
    movzx bx, byte ptr [bp + arg2]
    add ax, bx
    shl ax, 1
    mov di, ax
    
    mov si, word ptr [bp + arg3]
    mov ah, byte ptr [bp + arg4]
    
write_loop:
    mov al, byte ptr [si]
    test al, al
    jz ws_done
    mov word ptr es:[di], ax
    add di, 2
    inc si
    jmp write_loop
    
ws_done:
    pop si
    pop es
    mov sp, bp
    pop bp
    ret
_write_string_at endp

_draw_box proc near
    row equ var1
    col equ var2
    push bp
    mov bp, sp
    sub sp, 4
    
    mov ax, word ptr [bp + arg2]
    mov word ptr [bp + row], ax
    
    mov ax, word ptr [bp + arg1]
    mov word ptr [bp + col], ax
    
    push word ptr [bp + arg5]
    push 0C9h
    push word ptr [bp + col]
    push word ptr [bp + row]
    call _write_char_at
    add sp, 8
    
    inc word ptr [bp + col]
    mov cx, word ptr [bp + arg3]
    sub cx, 2
top_line:
    push cx
    push word ptr [bp + arg5]
    push 0CDh
    push word ptr [bp + col]
    push word ptr [bp + row]
    call _write_char_at
    add sp, 8
    inc word ptr [bp + col]
    pop cx
    loop top_line
    
    push word ptr [bp + arg5]
    push 0BBh
    push word ptr [bp + col]
    push word ptr [bp + row]
    call _write_char_at
    add sp, 8
    
    inc word ptr [bp + row]
    mov cx, word ptr [bp + arg4]
    sub cx, 2
side_lines:
    push cx
    
    mov ax, word ptr [bp + arg1]
    push word ptr [bp + arg5]
    push 0BAh
    push ax
    push word ptr [bp + row]
    call _write_char_at
    add sp, 8
    
    mov ax, word ptr [bp + arg1]
    add ax, word ptr [bp + arg3]
    dec ax
    push word ptr [bp + arg5]
    push 0BAh
    push ax
    push word ptr [bp + row]
    call _write_char_at
    add sp, 8
    
    inc word ptr [bp + row]
    pop cx
    loop side_lines
    
    mov ax, word ptr [bp + arg1]
    mov word ptr [bp + col], ax
    
    push word ptr [bp + arg5]
    push 0C8h
    push word ptr [bp + col]
    push word ptr [bp + row]
    call _write_char_at
    add sp, 8
    
    inc word ptr [bp + col]
    mov cx, word ptr [bp + arg3]
    sub cx, 2
bottom_line:
    push cx
    push word ptr [bp + arg5]
    push 0CDh
    push word ptr [bp + col]
    push word ptr [bp + row]
    call _write_char_at
    add sp, 8
    inc word ptr [bp + col]
    pop cx
    loop bottom_line
    
    push word ptr [bp + arg5]
    push 0BCh
    push word ptr [bp + col]
    push word ptr [bp + row]
    call _write_char_at
    add sp, 8
    
    mov sp, bp
    pop bp
    ret
_draw_box endp

_scroll_log_window proc near
    push bp
    mov bp, sp
    
    mov ax, 0601h
    mov bh, 0Fh
    mov ch, WINDOW_Y + 2
    mov cl, WINDOW_X + 1
    mov dh, WINDOW_Y + WINDOW_HEIGHT - 2
    mov dl, WINDOW_X + WINDOW_WIDTH - 2
    int 10h
    
    mov sp, bp
    pop bp
    ret
_scroll_log_window endp

_open_file proc near
    push bp
    mov bp, sp
    
    mov dx, word ptr [bp + arg1]
    mov ah, 3Ch
    mov cx, 0
    int 21h
    jc open_error
    
    mov word ptr [file_handle], ax
    jmp open_done
    
open_error:
    mov ax, 0FFFFh
    
open_done:
    mov sp, bp
    pop bp
    ret
_open_file endp

_write_to_file proc near
    push bp
    mov bp, sp
    
    cmp word ptr [file_handle], 0
    je wf_done
    
    mov bx, word ptr [file_handle]
    mov dx, word ptr [bp + arg1]
    mov cx, word ptr [bp + arg2]
    mov ah, 40h
    int 21h
    
wf_done:
    mov sp, bp
    pop bp
    ret
_write_to_file endp

_close_file proc near
    push bp
    mov bp, sp
    
    cmp word ptr [file_handle], 0
    je close_done
    
    mov bx, word ptr [file_handle]
    mov ah, 3Eh
    int 21h
    
close_done:
    mov sp, bp
    pop bp
    ret
_close_file endp

_add_to_log proc near
    push bp
    mov bp, sp
    push si
    push di
    
    mov si, word ptr [bp + arg1]
    mov di, offset log_buffer
    add di, word ptr [log_pos]
    
add_loop:
    mov al, byte ptr [si]
    test al, al
    jz add_done
    
    mov bx, word ptr [log_pos]
    cmp bx, 4090
    jge flush_and_reset
    
    mov byte ptr [di], al
    inc di
    inc si
    inc word ptr [log_pos]
    jmp add_loop
    
flush_and_reset:
    push word ptr [log_pos]
    push offset log_buffer
    call _write_to_file
    add sp, 4
    
    mov word ptr [log_pos], 0
    mov di, offset log_buffer
    jmp add_loop
    
add_done:
    pop di
    pop si
    mov sp, bp
    pop bp
    ret
_add_to_log endp

_flush_log proc near
    push bp
    mov bp, sp
    
    cmp word ptr [log_pos], 0
    je flush_done
    
    push word ptr [log_pos]
    push offset log_buffer
    call _write_to_file
    add sp, 4
    
    mov word ptr [log_pos], 0
    
flush_done:
    mov sp, bp
    pop bp
    ret
_flush_log endp

_draw_main_window proc near
    push bp
    mov bp, sp
    
    call _clear_screen
    
    push 0Fh
    push WINDOW_HEIGHT
    push WINDOW_WIDTH
    push WINDOW_Y
    push WINDOW_X
    call _draw_box
    add sp, 10
    
    push 0Eh
    push offset header_text
    push WINDOW_X + 2
    push WINDOW_Y
    call _write_string_at
    add sp, 8
    
    mov cx, WINDOW_WIDTH - 2
    mov bx, WINDOW_X + 1
draw_separator:
    push cx
    push 0Fh
    push 0C4h
    push bx
    push WINDOW_Y + 1
    call _write_char_at
    add sp, 8
    inc bx
    pop cx
    loop draw_separator
    
    push 07h
    push offset footer_text
    push WINDOW_X + 2
    push WINDOW_Y + WINDOW_HEIGHT - 1
    call _write_string_at
    add sp, 8
    
    mov sp, bp
    pop bp
    ret
_draw_main_window endp

_draw_input_window proc near
    push bp
    mov bp, sp
    
    call _clear_screen
    
    push 0Fh
    push 10
    push 50
    push 10
    push 15
    call _draw_box
    add sp, 10
    
    push 0Eh
    push offset prompt1
    push 16
    push 11
    call _write_string_at
    add sp, 8
    
    push 0Fh
    push 3
    push 46
    push 14
    push 16
    call _draw_box
    add sp, 10
    
    push 07h
    push offset prompt2
    push 16
    push 17
    call _write_string_at
    add sp, 8
    
    mov sp, bp
    pop bp
    ret
_draw_input_window endp

_input_file_path proc near
    pos equ var1
    temp_char equ var2
    push bp
    mov bp, sp
    sub sp, 4
    
    call _draw_input_window
    
    push di
    push es
    mov ax, ds
    mov es, ax
    mov di, offset file_path
    mov cx, 128
    xor al, al
    rep stosb
    pop es
    pop di
    
    mov word ptr [bp + pos], 0
    
    push 17
    push 15
    call _set_cursor
    add sp, 4
    
input_loop:
    mov ah, 00h
    int 16h
    
    mov word ptr [bp + temp_char], ax
    
    cmp ah, 1Ch
    je input_done_ok
    
    cmp ah, 01h
    je input_done_cancel
    
    cmp ah, 0Eh
    je handle_backspace
    
    mov al, byte ptr [bp + temp_char]
    cmp al, 32
    jb input_loop
    cmp al, 126
    ja input_loop
    
    mov bx, word ptr [bp + pos]
    cmp bx, 44
    jge input_loop
    
    mov si, offset file_path
    add si, bx
    mov byte ptr [si], al
    
    mov cx, bx
    add cx, 17
    
    push 0Fh
    push ax
    push cx
    push 15
    call _write_char_at
    add sp, 8
    
    inc word ptr [bp + pos]
    
    jmp input_loop
    
handle_backspace:
    cmp word ptr [bp + pos], 0
    je input_loop
    
    dec word ptr [bp + pos]
    mov bx, word ptr [bp + pos]
    
    mov si, offset file_path
    add si, bx
    mov byte ptr [si], 0
    
    mov cx, bx
    add cx, 17
    
    push 0Fh
    push ' '
    push cx
    push 15
    call _write_char_at
    add sp, 8
    
    jmp input_loop
    
input_done_ok:
    cmp word ptr [bp + pos], 0
    je input_done_cancel
    
    mov bx, word ptr [bp + pos]
    mov si, offset file_path
    add si, bx
    mov byte ptr [si], 0
    
    mov ax, 1
    jmp input_exit
    
input_done_cancel:
    mov ax, 0
    
input_exit:
    mov sp, bp
    pop bp
    ret
_input_file_path endp

_main_loop proc near
    cur_row equ var1
    cur_col equ var2
    key_scan equ var3
    key_ascii equ var4
    push bp
    mov bp, sp
    sub sp, 8
    
    call _draw_main_window
    
    mov word ptr [bp + cur_row], WINDOW_Y + 2
    mov word ptr [bp + cur_col], WINDOW_X + 1
    
    push word ptr [bp + cur_col]
    push word ptr [bp + cur_row]
    call _set_cursor
    add sp, 4
    
main_loop:
    mov ah, 00h
    int 16h
    
    mov byte ptr [bp + key_scan], ah
    mov byte ptr [bp + key_ascii], al
    
    push ax
    mov ah, 02h
    int 16h
    test al, 04h
    jz no_ctrl
    mov byte ptr [ctrl_pressed], 1
    jmp check_keys
    
no_ctrl:
    mov byte ptr [ctrl_pressed], 0
    
check_keys:
    pop ax
    
    cmp byte ptr [ctrl_pressed], 1
    jne not_ctrl_combo
    
    cmp byte ptr [bp + key_scan], 26h
    je handle_ctrl_l
    
    cmp byte ptr [bp + key_scan], 1Fh
    je handle_ctrl_s
    
    cmp byte ptr [bp + key_scan], 2Eh
    je handle_ctrl_c
    
not_ctrl_combo:
    
    cmp byte ptr [bp + key_scan], 1Ch
    je handle_enter
    
    cmp byte ptr [bp + key_scan], 01h
    je exit_main_loop
    
    cmp byte ptr [bp + key_scan], 3Bh
    je handle_f1
    cmp byte ptr [bp + key_scan], 3Ch
    je handle_f2
    cmp byte ptr [bp + key_scan], 3Dh
    je handle_f3
    cmp byte ptr [bp + key_scan], 3Eh
    je handle_f4
    cmp byte ptr [bp + key_scan], 3Fh
    je handle_f5
    cmp byte ptr [bp + key_scan], 40h
    je handle_f6
    cmp byte ptr [bp + key_scan], 41h
    je handle_f7
    cmp byte ptr [bp + key_scan], 42h
    je handle_f8
    cmp byte ptr [bp + key_scan], 43h
    je handle_f9
    cmp byte ptr [bp + key_scan], 44h
    je handle_f10
    
    cmp byte ptr [bp + key_scan], 48h
    je handle_up
    cmp byte ptr [bp + key_scan], 50h
    je handle_down
    cmp byte ptr [bp + key_scan], 4Bh
    je handle_left
    cmp byte ptr [bp + key_scan], 4Dh
    je handle_right
    
    mov al, byte ptr [bp + key_ascii]
    cmp al, 32
    jb main_loop
    cmp al, 126
    ja main_loop
    
    mov byte ptr [temp_char_str], al
    push offset temp_char_str
    call _add_to_log
    add sp, 2
    
    movzx ax, byte ptr [bp + key_ascii]
    push 0Fh
    push ax
    push word ptr [bp + cur_col]
    push word ptr [bp + cur_row]
    call _write_char_at
    add sp, 8
    
    inc word ptr [bp + cur_col]
    mov ax, WINDOW_X + WINDOW_WIDTH - 2
    cmp word ptr [bp + cur_col], ax
    jl update_cursor
    
    mov ax, WINDOW_X + 1
    mov word ptr [bp + cur_col], ax
    inc word ptr [bp + cur_row]
    
    mov ax, WINDOW_Y + WINDOW_HEIGHT - 2
    cmp word ptr [bp + cur_row], ax
    jle update_cursor
    
    call _scroll_log_window
    mov ax, WINDOW_Y + WINDOW_HEIGHT - 2
    mov word ptr [bp + cur_row], ax
    
    jmp update_cursor

handle_ctrl_l:
    call _draw_main_window
    mov word ptr [bp + cur_row], WINDOW_Y + 2
    mov word ptr [bp + cur_col], WINDOW_X + 1
    jmp update_cursor
    
handle_ctrl_s:
    call _flush_log
    jmp main_loop
    
handle_ctrl_c:
    push offset key_ctrl_c
    call _add_to_log
    add sp, 2
    jmp main_loop
    
handle_enter:
    push offset key_enter
    call _add_to_log
    add sp, 2
    
    mov ax, WINDOW_X + 1
    mov word ptr [bp + cur_col], ax
    inc word ptr [bp + cur_row]
    
    mov ax, WINDOW_Y + WINDOW_HEIGHT - 2
    cmp word ptr [bp + cur_row], ax
    jle update_cursor
    
    call _scroll_log_window
    mov ax, WINDOW_Y + WINDOW_HEIGHT - 2
    mov word ptr [bp + cur_row], ax
    
    jmp update_cursor
    
handle_f1:
    push offset key_f1
    call _add_to_log
    add sp, 2
    jmp main_loop
handle_f2:
    push offset key_f2
    call _add_to_log
    add sp, 2
    jmp main_loop
handle_f3:
    push offset key_f3
    call _add_to_log
    add sp, 2
    jmp main_loop
handle_f4:
    push offset key_f4
    call _add_to_log
    add sp, 2
    jmp main_loop
handle_f5:
    push offset key_f5
    call _add_to_log
    add sp, 2
    jmp main_loop
handle_f6:
    push offset key_f6
    call _add_to_log
    add sp, 2
    jmp main_loop
handle_f7:
    push offset key_f7
    call _add_to_log
    add sp, 2
    jmp main_loop
handle_f8:
    push offset key_f8
    call _add_to_log
    add sp, 2
    jmp main_loop
handle_f9:
    push offset key_f9
    call _add_to_log
    add sp, 2
    jmp main_loop
handle_f10:
    push offset key_f10
    call _add_to_log
    add sp, 2
    jmp main_loop
    
handle_up:
    push offset key_up
    call _add_to_log
    add sp, 2
    jmp main_loop
handle_down:
    push offset key_down
    call _add_to_log
    add sp, 2
    jmp main_loop
handle_left:
    push offset key_left
    call _add_to_log
    add sp, 2
    jmp main_loop
handle_right:
    push offset key_right
    call _add_to_log
    add sp, 2
    jmp main_loop
    
update_cursor:
    push word ptr [bp + cur_col]
    push word ptr [bp + cur_row]
    call _set_cursor
    add sp, 4
    jmp main_loop
    
exit_main_loop:
    mov sp, bp
    pop bp
    ret
_main_loop endp

_getmode proc near
    push bp
    mov bp, sp
    
    mov ah, 0fh
    int 10h
    movzx ax, al
    
    mov sp, bp
    pop bp
    ret
_getmode endp

_setmode proc near
    push bp
    mov bp, sp
    
    mov ax, word ptr [bp + arg1]
    mov ah, 00h
    int 10h
    
    mov sp, bp
    pop bp
    ret
_setmode endp

start:
    mov ax, data
    mov ds, ax
    mov ax, stack
    mov ss, ax
    nop
    
    call _getmode
    mov [save_mode], al
    
    push 3
    call _setmode
    add sp, 2
    
    call _input_file_path
    test ax, ax
    jz exit_program
    
    push offset file_path
    call _open_file
    add sp, 2
    
    call _main_loop
    
    call _flush_log
    
    call _close_file
    
exit_program:
    movzx dx, byte ptr [save_mode]
    push dx
    call _setmode
    add sp, 2
    
    call _exit0
    
code ends
end start