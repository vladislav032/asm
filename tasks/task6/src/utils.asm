include _constants_.inc
include _extern_.inc
include globalData.asm
extern nameBuffer:byte
extern phoneBuffer:byte

.code
; Функция очистки буфера
clearBuffer proc
    push rdi
    push rcx
    push rax
    
    lea rdi, nameBuffer
    mov rcx, MAX_NAME_LEN
    xor al, al
    rep stosb
    
    lea rdi, phoneBuffer
    mov rcx, MAX_PHONE_LEN
    xor al, al
    rep stosb
    
    pop rax
    pop rcx
    pop rdi
    ret
clearBuffer endp

; Вспомогательная функция для удаления пробелов в конце строки
; Вход: RDI - указатель на строку
trimTrailingSpaces proc
    push rcx
    push rsi
    
    ; Находим конец строки
    mov rsi, rdi
    mov rcx, MAX_NAME_LEN
    xor al, al
    repne scasb
    
    ; Двигаемся назад, пока не найдем не пробел
    sub rdi, 2 ; переходим на последний символ перед нуль-терминатором
    
trim_loop:
    cmp rdi, rsi
    jb trim_done
    
    cmp byte ptr [rdi], ' '
    jne trim_done
    
    mov byte ptr [rdi], 0 ; заменяем пробел на нуль-терминатор
    dec rdi
    jmp trim_loop
    
trim_done:
    pop rsi
    pop rcx
    ret
trimTrailingSpaces endp
END