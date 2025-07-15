; ------------------------------------------------------------------------
;  Конвертер единиц измерения на MASM (исправленная версия)
; ------------------------------------------------------------------------
option casemap:none
extrn  ExitProcess   :PROC
extrn  printf        :PROC
extrn  scanf         :PROC
extrn  __imp_fflush  :PROC
extrn  __imp_getchar :PROC
extrn  atoi          :PROC
extrn  atof          :PROC
extrn  gets          :PROC    

.const
fmt_menu        db 13,10
                db "Unit Converter",13,10
                db "Select conversion type:",13,10
                db "1. Meters to kilometers",13,10
                db "2. Centimeters to meters",13,10
                db "3. Kilometers to meters",13,10
                db "4. Inches to centimeters",13,10
                db "Enter operation number: ",0

fmt_prompt      db "Enter value: ",0
fmt_err_int     db "Error: please enter number 1-4!",13,10,0
fmt_err_num     db "Error: please enter valid number!",13,10,0
fmt_err_input   db "Error: invalid input format!",13,10,0

; Результирующие сообщения
fmt_res1        db "Result: %.3f m = %.6f km",13,10,0
fmt_res2        db "Result: %.3f cm = %.6f m",13,10,0
fmt_res3        db "Result: %.3f km = %.6f m",13,10,0
fmt_res4        db "Result: %.3f in = %.6f cm",13,10,0

fmt_int         db "%d",0
fmt_float       db "%lf",0

; Константы для вычислений
Ten        REAL8 10.0
Kilo       REAL8 1000.0
Hundred    REAL8 100.0
Inch2cm    REAL8 2.54

.data
choice      dd  ?
valueIn     REAL8 ?
input_buf   db 32 dup(0)    ; Буфер для ввода строки
MIN_VAL     REAL8  0.0          ; Minimum allowed value
MAX_VAL     REAL8  1000000.0    ; Maximum allowed value
fmt_err_range db "Error: value out of allowed range!",13,10,0

.code

; --------------------------------------------------------
; Проверка числовой строки (допустимы цифры, одна точка и знак)
; Вход: RCX - указатель на строку
; Выход: RAX - 1 если число валидно, 0 если нет
; --------------------------------------------------------
validate_number proc
    push rbp
    mov  rbp, rsp
    push rbx

    xor  eax, eax            ; al=0  – невалидно по умолчанию
    mov  rsi, rcx            ; rsi -> строка

    ; пустая строка?
    cmp  byte ptr [rsi], 0
    je   done

    ; знак +/-
    cmp  byte ptr [rsi], '+'
    je   inc_ptr
    cmp  byte ptr [rsi], '-'
    je   inc_ptr

check_loop:
    mov  dl, [rsi]
    test dl, dl
    jz   good               ; конец строки – успешно

    ; разрешаем одну точку
    cmp  dl, '.'
    je   maybe_dot
    ; цифры 0‑9
    cmp  dl, '0'
    jb   bad
    cmp  dl, '9'
    ja   bad

inc_ptr:
    inc  rsi
    jmp  check_loop

maybe_dot:
    ; ищем вторую точку – если найдём, невалидно
    inc  rsi
    mov  rdx, rsi
find_dot:
    mov  bl, [rdx]
    test bl, bl
    jz   good
    cmp  bl, '.'
    je   bad
    inc  rdx
    jmp  find_dot

bad:
    xor  eax, eax
    jmp  done

good:
    mov  eax, 1

done:
    pop  rbx 
    leave
    ret
validate_number endp

; --------------------------------------------------------
; Чтение целого числа с проверкой
; Выход: EAX = число
; --------------------------------------------------------
read_int proc
    push rbp
    mov  rbp, rsp
    sub  rsp, 32

read_int_loop:
    lea  rcx, input_buf
    call gets

    lea  rcx, input_buf
    call validate_number
    test rax, rax
    jz   invalid_int

    lea  rcx, input_buf
    call atoi
    jmp  ok_int

invalid_int:
    lea  rcx, fmt_err_input
    call printf
    jmp  read_int_loop

ok_int:
    leave
    ret
read_int endp

; --------------------------------------------------------
; Чтение числа с плавающей точкой (double) с проверкой формата
; и диапазона. При ошибке выводится сообщение и ввод повторяется.
; Возврат: XMM0 = введённое число (если валидно и в диапазоне)
; --------------------------------------------------------
read_double proc
    push    rbp
    mov     rbp, rsp
    sub     rsp, 32                    ; резервируем место на стеке

read_dbl_loop:
    lea     rcx, input_buf             ; RCX ← адрес буфера строки
    call    gets                       ; читаем строку из stdin → input_buf

    lea     rcx, input_buf
    call    validate_number            ; проверяем, что строка — число
    test    rax, rax
    jz      invalid_input              ; не число → сообщение об ошибке

    ;-------- конвертация строки в double --------
    lea     rcx, input_buf
    call    atof                       ; XMM0 ← значение пользователя

    ;-------- проверка диапазона [MIN_VAL, MAX_VAL] --------
    movsd   xmm1, qword ptr [MIN_VAL]  ; минимально допустимое значение
    comisd  xmm0, xmm1                 ; XMM0 < MIN_VAL ?
    jb      invalid_input              ; да → ошибка (слишком маленькое)

    movsd   xmm1, qword ptr [MAX_VAL]  ; максимально допустимое значение
    comisd  xmm0, xmm1                 ; XMM0 > MAX_VAL ?
    ja      invalid_input              ; да → ошибка (слишком большое)

    ; если дошли сюда, значение в допустимых пределах
    jmp     got_valid_input

invalid_input:
    ; вывод сообщения об ошибке и повтор ввода
    lea     rcx, fmt_err_range         ; "значение вне допустимого диапазона"
    call    printf
    jmp     read_dbl_loop              ; запрашиваем ввод заново

got_valid_input:
    leave
    ret
read_double endp


; --------------------------------------------------------
; Выбор операции из меню
; Выход: EAX = выбор (1‑4)
; --------------------------------------------------------
read_menu proc
    push rbp
    mov  rbp, rsp
    sub  rsp, 32

menu_loop:
    lea  rcx, fmt_menu
    call printf

    call read_int
    mov  [choice], eax

    cmp  eax, 1
    jl   menu_err
    cmp  eax, 4
    jg   menu_err
    jmp  menu_ok

menu_err:
    lea  rcx, fmt_err_int
    call printf
    jmp  menu_loop

menu_ok:
    mov  eax, [choice]
    leave
    ret
read_menu endp

; --------------------------------------------------------
; Вывод результата (printf c двумя double)
; Вход: RCX = fmt, XMM0 = val1, XMM1 = val2
; --------------------------------------------------------
print_result proc
    sub  rsp, 20h           ; Windows x64 shadow space
    movq rdx, xmm0
    movq r8,  xmm1
    call printf
    add  rsp, 20h
    ret
print_result endp

; --------------------------------------------------------
; Точка входа
; --------------------------------------------------------
main proc
    sub rsp, 40h            ; выравнивание стека

    ; 1) выбор операции
    call read_menu
    mov  ebx, eax

    ; 2) ввод значения
    lea  rcx, fmt_prompt
    call printf
    call read_double        ; результат в XMM0
    movsd [valueIn], xmm0   ; *** Сохраняем исходное значение ***
    movsd xmm2, xmm0        ; xmm2 = исходное значение для вычисл.

    ; 3) конвертация
    cmp  ebx, 1
    je   m_to_km
    cmp  ebx, 2
    je   cm_to_m
    cmp  ebx, 3
    je   km_to_m

in_to_cm:
    movsd xmm1, Inch2cm
    mulsd xmm1, xmm2        ; in * 2.54
    movsd xmm0, xmm2
    lea  rcx, fmt_res4
    jmp  show

km_to_m:
    movsd xmm1, Kilo
    mulsd xmm1, xmm2        ; km * 1000
    movsd xmm0, xmm2
    lea  rcx, fmt_res3
    jmp  show

cm_to_m:
    movsd xmm1, Hundred
    divsd xmm2, xmm1        ; cm / 100
    movsd xmm0, [valueIn]   ; исходное значение (cm)
    movsd xmm1, xmm2        ; результат (m)
    lea  rcx, fmt_res2
    jmp  show

m_to_km:
    movsd xmm1, Kilo
    divsd xmm2, xmm1        ; m / 1000
    movsd xmm0, [valueIn]   ; исходное значение (m)
    movsd xmm1, xmm2        ; результат (km)
    lea  rcx, fmt_res1

show:
    call print_result

    xor  ecx, ecx           ; ExitCode = 0
    call ExitProcess
main endp

end
