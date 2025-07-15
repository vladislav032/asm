include _constants_.inc
include _extern_.inc

.data
LIMIT_POS    db "2147483647",0      ; +INT_MAX
LIMIT_NEG    db "2147483648",0      ; |-INT_MIN| (для сравнения без знака)

.code
; --------------------------------------------------------
; Проверка числовой строки
; Вход: RCX - указатель на строку
; Выход: RAX - 1 если число валидно, 0 если нет
; --------------------------------------------------------
validate_number proc
    push rbp
    mov  rbp, rsp
    
    push rsi 
    push rdi 
    push rbx 
    push r12 
    push r13

    xor  eax, eax                   ; предполагаем НЕвалидно
    mov  rsi, rcx                   ; rsi ← ptr to string
    xor  ebx, ebx                   ; ebx=0 ‑ положит.; 1 ‑ минус
    xor  r8d, r8d                   ; r8d = счётчик цифр

    ; --- пустая строка? ---
    cmp  byte ptr [rsi], 0
    je   _done                      ; сразу выход

    ; --- анализ знака ---
    mov  dl, [rsi]
    cmp  dl, '-'
    jne  _chk_plus
    inc  ebx                        ; отмечаем минус
    inc  rsi                        ; пропускаем знак
    jmp  _first_digit
_chk_plus:
    cmp  dl, '+'
    jne  _first_digit
    inc  rsi                        ; пропускаем '+'

_first_digit:
    ; rdi запомним как начало цифр
    mov  rdi, rsi

_scan_loop:
    mov  dl, [rsi]
    test dl, dl
    jz   _after_digits              ; конец строки
    cmp  dl, '0'
    jb   _invalid
    cmp  dl, '9'
    ja   _invalid
    inc  r8d                        ; ++кол-во цифр
    inc  rsi
    jmp  _scan_loop

_after_digits:
    test r8d, r8d                   ; хотя бы одна цифра?
    jz   _invalid

    ; ---- проверка диапазона ----
    cmp  r8d, 10
    jl   _valid                     ; <10 цифр — точно помещается
    ja   _invalid                   ; >10 цифр — переполнение
    ; exactly 10 digits → сравниваем с лимитом
    lea  r12, LIMIT_POS
    cmp  ebx, 1
    jne  _cmp_limit
    lea  r12, LIMIT_NEG             ; отрицательное число

_cmp_limit:
    xor  r13d, r13d                 ; индекс
_cmp_loop:
    cmp  r13, 10
    jge  _valid                     ; все символы ≤ пределу → OK
    mov  al, [rdi + r13]
    mov  dl, [r12 + r13]
    cmp  al, dl
    jb   _valid                     ; меньше лимита → OK
    ja   _invalid                   ; больше → переполнение
    inc  r13
    jmp  _cmp_loop

_valid:
    mov  eax, 1                     ; успех!
    jmp  _done

_invalid:
    xor  eax, eax

_done:
    pop  r13 
    pop  r12 
    pop  rbx 
    pop  rdi 
    pop  rsi
    leave
    ret
validate_number endp
END