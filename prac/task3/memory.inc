
HEAP_PARAGRAPHS equ 4096

_heap_init proc near
    push bp
    mov  bp, sp

    mov  ah, 4Ah
    mov  bx, 512
    int  21h

heap_alloc:
    mov  ah, 48h
    mov  bx, HEAP_PARAGRAPHS
    int  21h
    jc   heap_init_err

    mov  word ptr [heap_seg], ax
    mov  word ptr [heap_ptr], 0
    mov  word ptr [heap_size], HEAP_PARAGRAPHS
    jmp  short heap_init_done

heap_init_err:
    push offset msg_heap_err
    call _putstr
    add  sp, 2
    push 1
    call _exit
    add  sp, 2

heap_init_done:
    mov  sp, bp
    pop  bp
    ret
_heap_init endp

_malloc proc near
    push bp
    mov  bp, sp
    push bx

    mov  bx, word ptr [bp + 4]
    test bx, 1
    jz   short malloc_aligned
    inc  bx
malloc_aligned:
    mov  ax, word ptr [heap_ptr]
    add  ax, bx
    jc   malloc_oom
    cmp  ax, 0FFF0h
    ja   malloc_oom

    mov  ax, word ptr [heap_ptr]
    mov  dx, word ptr [heap_seg]
    add  word ptr [heap_ptr], bx

    pop  bx
    mov  sp, bp
    pop  bp
    ret

malloc_oom:
    push offset msg_malloc_err
    call _putstr
    add  sp, 2
    push 1
    call _exit
    add  sp, 2

    pop  bx
    mov  sp, bp
    pop  bp
    ret
_malloc endp

_free proc near
    push bp
    mov  bp, sp
    mov  sp, bp
    pop  bp
    ret
_free endp