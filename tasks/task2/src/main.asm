; ========================================================
;  Программа вычисления факториала (исправленная версия)
;  Работает в Win64 MASM + MSVCRT, без scanf / getchar зависаний
; ========================================================

OPTION casemap:none

; --- внешние функции из MSVCRT / KERNEL32 ---------------------------------
EXTRN  printf  :PROC
EXTRN  gets    :PROC        
EXTRN  atoi    :PROC
EXTRN  ExitProcess:PROC

; -------------------------------------------------------------------------
.const
menu_msg        db 13,10,"Choose operation:",13,10,
                "1. Calculate factorial",13,10,
                "2. Exit",13,10,
                "Your choice: ",0
prompt_num_msg  db "Enter number (0-12): ",0
result_msg      db "%d! = %d",13,10,0
continue_msg    db "Calculate another factorial? (1=Yes, 0=No): ",0

fmt_err_input   db "Error: invalid input format!",13,10,0
fmt_err_range   db "Error: number must be between 0 and 12.",13,10,0
fmt_int         db "%d",0

; -------------------------------------------------------------------------
.data
input_buf       db 32 dup(0)
user_choice     dd 0
input_number    dd 0            ; 0..12
factorial_res   dd 1            ; результат 0..479001600 умещается в 32‑бит

; -------------------------------------------------------------------------
.code

; --------------------------------------------------------
; validate_number: проверка, что строка – целое число (+/- и цифры)
;  RCX = ptr to ASCIIZ, RAX = 1 ok / 0 bad
; --------------------------------------------------------
validate_number PROC
    push rbp
    mov  rbp, rsp

    xor  eax, eax            ; по умолчанию 0 = invalid
    mov  rsi, rcx            ; rsi -> строка

    ; пустая?
    cmp  byte ptr [rsi], 0
    je   done

    ; опциональный знак
    cmp  byte ptr [rsi], '+'
    je   next_ch
    cmp  byte ptr [rsi], '-'
    je   next_ch

chk_loop:
    mov  dl, [rsi]
    test dl, dl            ; 0 ? конец
    jz   good
    cmp  dl, '0'
    jb   bad
    cmp  dl, '9'
    ja   bad
next_ch:
    inc  rsi
    jmp  chk_loop

bad:
    jmp  done               ; eax=0

good:
    mov  eax, 1

done:
    leave
    ret
validate_number ENDP

; --------------------------------------------------------
; read_int: безопасное чтение целого числа с консоли
;  RET: EAX = число (если строка пустая/не число – спрашиваем снова)
; --------------------------------------------------------
read_int PROC
    push rbp
    mov  rbp, rsp
    sub  rsp, 32

read_loop:
    lea  rcx, input_buf
    call gets                ; читает строку (без CR/LF)

    lea  rcx, input_buf
    call validate_number
    test rax, rax
    jz   bad_input

    lea  rcx, input_buf
    call atoi
    jmp  ok

bad_input:
    ; сообщение
    lea  rcx, fmt_err_input
    call printf
    jmp  read_loop

ok:
    leave
    ret
read_int ENDP

; --------------------------------------------------------
; calculate_factorial: RCX = n (0..12) -> RAX = n!
; --------------------------------------------------------
calculate_factorial PROC
    xor  rax, rax
    mov  eax, 1
    test rcx, rcx
    jz   done

fact_loop:
    imul rax, rcx
    dec  rcx
    jnz  fact_loop

done:
    ret
calculate_factorial ENDP

; --------------------------------------------------------
; main
; --------------------------------------------------------
main PROC
    sub rsp, 40h            ; shadow space + align

app_menu:
    ; меню
    lea  rcx, menu_msg
    call printf

    call read_int           ; EAX = выбор
    mov  user_choice, eax

    cmp  eax, 1
    je   factorial_mode
    cmp  eax, 2
    je   quit
    ; иначе ошибка – просто повторим меню
    lea  rcx, fmt_err_input
    call printf
    jmp  app_menu

factorial_mode:
    ; запрос числа
    lea  rcx, prompt_num_msg
    call printf

    call read_int           ; EAX = число
    mov  input_number, eax

    ; диапазон 0‑12
    cmp  eax, 0
    jl   range_err
    cmp  eax, 12
    jg   range_err

    ; расчёт
    mov  ecx, eax           ; RCX = n
    call calculate_factorial
    mov  factorial_res, eax

    ; вывод
    lea  rcx, result_msg
    mov  edx, input_number
    mov  r8d, factorial_res
    call printf

continue_prompt:
    lea  rcx, continue_msg
    call printf

    call read_int           ; EAX = 0/1
    mov  user_choice, eax
    cmp  eax, 1
    je   factorial_mode     ; ещё раз
    jmp  app_menu           ; иначе в меню

range_err:
    lea  rcx, fmt_err_range
    call printf
    jmp  factorial_mode

quit:
    xor  ecx, ecx
    call ExitProcess
main ENDP

END
