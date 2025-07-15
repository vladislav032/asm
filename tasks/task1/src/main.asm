; ========================================================
;  Чётность и простота чисел (1‑100). Финальная версия
;  Win64 + MSVCRT. Корректный вывод без «‑1» и «0».
; ========================================================
OPTION casemap:none

; --- внешние функции ------------------------------------------------------
EXTRN  printf :PROC
EXTRN  gets   :PROC
EXTRN  atoi   :PROC
EXTRN  ExitProcess:PROC

; --------------------------- ДАННЫЕ --------------------------------------
.const
prompt_msg      db "Enter numbers (1-100). Enter 0 to stop:",13,10,0
even_msg        db "  %d is even",13,10,0
odd_msg         db "  %d is odd",13,10,0
prime_msg       db "  %d is prime",13,10,0
not_prime_msg   db "  %d is not prime",13,10,0
error_msg       db "Error: invalid input, enter integer 1‑100.",13,10,0
summary_msg     db "Summary: %d numbers processed (%d even, %d odd, %d prime)",13,10,0

.data
input_buf   db 32 dup(0)
cnt_total   dd 0
cnt_even    dd 0
cnt_odd     dd 0
cnt_prime   dd 0

; ---------------------------- КОД ----------------------------------------
.code
; validate_number – 1 = ok, 0 = bad
validate_number PROC
    push rbp
    mov  rbp, rsp

    xor  eax, eax
    mov  rsi, rcx
    cmp  byte ptr [rsi], 0
    je   done

    cmp  byte ptr [rsi], '+'
    je   next
    cmp  byte ptr [rsi], '-'
    je   next
chk_loop:
    mov  dl, [rsi]
    test dl, dl
    jz   good
    cmp  dl, '0'
    jb   done
    cmp  dl, '9'
    ja   done
next:
    inc  rsi
    jmp  chk_loop
good:
    mov  eax, 1
done:
    leave
    ret
validate_number ENDP

; read_int – безопасный ввод
read_int PROC
    push rbp
    mov  rbp, rsp
    sub  rsp, 32
retry:
    lea  rcx, input_buf
    call gets
    lea  rcx, input_buf
    call validate_number
    test rax, rax
    jz   retry
    lea  rcx, input_buf
    call atoi         ; EAX
    leave
    ret
read_int ENDP

; is_prime  RCX=n → RAX=0 prime, 1 composite
is_prime PROC
    push rbx
    xor  rax, rax
    cmp  rcx, 2
    jl   composite    ; числа < 2 — составные
    je   prime        ; 2 — простое
    test rcx, 1
    jz   composite    ; чётные > 2 — составные
    cmp  rcx, 3
    je   prime        ; 3 — простое (исправление!)
    mov  rbx, 3       ; начинаем проверку с 3
loop_div:
    mov  rax, rcx
    xor  rdx, rdx
    div  rbx
    test rdx, rdx
    jz   composite    ; если делится без остатка → составное
    add  rbx, 2       ; проверяем только нечётные делители
    mov  rax, rbx
    mul  rax
    cmp  rax, rcx
    jbe  loop_div     ; пока rbx² ≤ n
prime:
    xor  rax, rax     ; простое (возвращаем 0)
    pop  rbx
    ret
composite:
    mov  rax, 1       ; составное (возвращаем 1)
    pop  rbx
    ret
is_prime ENDP

; ----------------------------- main --------------------------------------
main PROC
    sub rsp, 40h
    lea rcx, prompt_msg
    call printf
read_loop:
    call read_int
    mov  ebx, eax          ; EBX = введённое число
    test ebx, ebx
    jz   summary
    cmp  ebx, 1
    jb   bad_input
    cmp  ebx, 100
    ja   bad_input

    inc  cnt_total

    ; четность
    test ebx, 1
    jz   even_case
odd_case:
    inc  cnt_odd
    mov  rdx, rbx          ; число
    lea  rcx, odd_msg
    call printf
    jmp  prime_check
even_case:
    inc  cnt_even
    mov  rdx, rbx
    lea  rcx, even_msg
    call printf

prime_check:
    mov  ecx, ebx
    call is_prime
    test eax, eax
    jnz  composite_case
prime_case:
    inc  cnt_prime
    mov  rdx, rbx
    lea  rcx, prime_msg
    call printf
    jmp  read_loop
composite_case:
    mov  rdx, rbx
    lea  rcx, not_prime_msg
    call printf
    jmp  read_loop

bad_input:
    lea  rcx, error_msg
    call printf
    jmp  read_loop

summary:
    lea  rcx, summary_msg
    mov  edx, cnt_total
    mov  r8d, cnt_even
    mov  r9d, cnt_odd
    mov  eax, cnt_prime
    mov  [rsp+32], eax
    call printf
    xor  ecx, ecx
    call ExitProcess
main ENDP
END