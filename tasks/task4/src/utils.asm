        include _constants_.inc   ; Подключаем файл с константами
        include _extern_.inc      ; Подключаем файл с внешними объявлениями
        include globalData.asm    ; Подключаем файл с глобальными данными

.code
; --------------------------------------------------------
; Проверка, является ли строка числом
; Вход: RCX - указатель на строку
; Выход: RAX - 1 если валидное число, 0 если нет
; --------------------------------------------------------
validate_number proc
        push rbp
        mov rbp, rsp

        xor eax, eax        ; Изначально считаем невалидным
        mov rsi, rcx        ; Сохраняем указатель на строку

        ; Проверка на пустую строку
        cmp byte ptr [rsi], 0
        je done

        ; Проверка на знак (+/-)
        cmp byte ptr [rsi], '+'
        je next_char
        cmp byte ptr [rsi], '-'
        je next_char

check_digits:
        mov al, [rsi]       ; Читаем текущий символ
        test al, al         ; Проверка на конец строки
        jz valid            ; Если конец строки - число валидно

        ; Проверка что символ цифра (0-9)
        cmp al, '0'
        jb invalid
        cmp al, '9'
        ja invalid

next_char:
        inc rsi             ; Переходим к следующему символу
        jmp check_digits    ; Продолжаем проверку
        
valid:
        mov eax, 1          ; Устанавливаем флаг валидности

invalid:
done:
        leave
        ret
validate_number endp

; --------------------------------------------------------
; Проверка что число в 32-битном диапазоне
; Вход: RAX - число для проверки
; Выход: ZF=1 если в диапазоне, ZF=0 если нет
; --------------------------------------------------------
check_int32_range proc
        cmp rax, MAX_INT    ; Сравниваем с максимальным 32-битным значением
        jg range_error      ; Если больше - ошибка
        cmp rax, MIN_INT    ; Сравниваем с минимальным 32-битным значением
        jl range_error      ; Если меньше - ошибка
        xor eax, eax        ; Устанавливаем ZF=1 (успех)
        ret
range_error:
        or eax, 1           ; Сбрасываем ZF (ошибка)
        ret
check_int32_range endp
END