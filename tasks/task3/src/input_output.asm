include _constants_.inc
include _extern_.inc
include globalData.asm

extern validate_number:proc
extern print_array:proc

extern array:qword
extern default_array:qword
extern current_size:qword
extern input_buffer:byte
extern temp_num_buffer:byte

.code
; --------------------------------------------------------
; Ввод массива
; --------------------------------------------------------
input_array proc
    push rbp
    mov rbp, rsp
    sub rsp, 64

    lea rcx, input_prompt
    mov rdx, ARRAY_SIZE
    call printf

    lea rdi, array
    mov rcx, ARRAY_SIZE
    xor rax, rax
    rep stosq

    lea rcx, input_buffer
    call gets

    lea rsi, input_buffer
    lea rdi, array
    xor rbx, rbx

parse_loop:
    lodsb
    test al, al
    jz parse_done
    cmp al, ' '
    je parse_loop
    cmp al, 9
    je parse_loop
    cmp al, 10
    je parse_loop
    cmp al, 13
    je parse_loop

    dec rsi
    lea rcx, temp_num_buffer
    mov rdx, 31

copy_num:
    mov al, [rsi]
    test al, al
    jz end_copy
    cmp al, ' '
    je end_copy
    cmp al, 9
    je end_copy
    cmp al, 10
    je end_copy
    cmp al, 13
    je end_copy

    mov [rcx], al
    inc rsi
    inc rcx
    dec rdx
    jnz copy_num

end_copy:
    mov byte ptr [rcx], 0

    lea rcx, temp_num_buffer
    call validate_number
    test rax, rax
    jz skip_invalid

    lea rcx, temp_num_buffer
    call atoi
    movsxd rax, eax       ; ВАЖНО: знаковое расширение результата atoi

    mov [rdi + rbx*8], rax
    inc rbx
    cmp rbx, ARRAY_SIZE
    jge parse_done

skip_invalid:
    jmp parse_loop

parse_done:
    mov [current_size], rbx

    lea rcx, unsorted_msg
    lea rdx, array
    mov r8, [current_size]
    call print_array

    leave
    ret
input_array endp


; --------------------------------------------------------
; Безопасный ввод для меню
; Возвращает: RAX - введенное число
; --------------------------------------------------------
safe_menu_input proc
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
input_again:
    ; Вывод приглашения
    lea rcx, menu_msg
    call printf
    
    ; Ввод строки
    lea rcx, input_buffer
    call gets
    
    ; Проверка числа
    lea rcx, input_buffer
    call validate_number
    test rax, rax
    jz invalid_input_
    
    ; Преобразование в число
    lea rcx, input_buffer
    call atoi
    
    ; Проверка диапазона
    cmp rax, 0
    jl invalid_range
    cmp rax, 7
    jg invalid_range
    
    jmp done
    
invalid_input_:
    lea rcx, invalid_input
    call printf
    jmp input_again
    
invalid_range:
    lea rcx, invalid_menu
    call printf
    jmp input_again
    
done:
    leave
    ret
safe_menu_input endp
END