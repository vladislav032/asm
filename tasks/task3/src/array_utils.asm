include _constants_.inc
include _extern_.inc
include globalData.asm

extern array:qword
extern default_array:qword
extern current_size:qword

.code
; --------------------------------------------------------
; Процедура вывода массива
; Вход: RCX - адрес сообщения, RDX - адрес массива, R8 - размер массива
; --------------------------------------------------------
print_array proc
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; Сохраняем параметры
    mov [rbp+16], rcx    ; Сохраняем адрес сообщения
    mov [rbp+24], rdx    ; Сохраняем адрес массива
    mov [rbp+32], r8     ; Сохраняем размер массива
    
    ; Вывод заголовка
    call printf
    
    ; Восстанавливаем параметры
    mov rsi, [rbp+24]    ; Адрес массива
    mov rbx, [rbp+32]    ; Размер массива
    xor rdi, rdi         ; Индекс элемента
    
print_loop:
    cmp rdi, rbx
    jge print_done
    
    ; Вывод элемента массива
    lea rcx, array_fmt
    mov rdx, [rsi + rdi*8]
    call printf
    
    inc rdi
    jmp print_loop
    
print_done:
    ; Переход на новую строку
    lea rcx, newline
    call printf
    
    leave
    ret
print_array endp

; --------------------------------------------------------
; Инициализация массива значениями по умолчанию
; --------------------------------------------------------
init_default_array proc
    push rbp
    mov rbp, rsp
    
    ; Копируем массив по умолчанию
    lea rsi, default_array
    lea rdi, array
    mov rcx, ARRAY_SIZE
    rep movsq
    
    mov [current_size], ARRAY_SIZE
    
    leave
    ret
init_default_array endp
END