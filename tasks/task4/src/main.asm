        include _constants_.inc   ; Константы программы
        include _extern_.inc      ; Внешние объявления
        include globalData.asm    ; Глобальные данные

        extern validate_number  :proc  ; Внешняя функция проверки числа

.code
; --------------------------------------------------------
; Основная программа
; --------------------------------------------------------
main proc
        push rbp
        mov rbp, rsp
        sub rsp, 256          ; Выделяем место для локальных переменных

        ; Инициализация массива
        call array_init

menu_loop:
        ; Вывод меню
        lea rcx, menu_msg
        call printf

        ; Получаем выбор пользователя (как строку)
        lea rcx, string_fmt
        lea rdx, [rbp-40]     ; Буфер для ввода
        call scanf

        ; Проверяем что ввод - число
        lea rcx, [rbp-40]
        call validate_number
        test rax, rax
        jz invalid_menu_input

        ; Конвертируем строку в число
        lea rcx, [rbp-40]
        lea rdx, int32_fmt
        lea r8, [rbp-8]       ; Переменная для выбора
        call sscanf
        cmp rax, 1
        jne invalid_menu_input

        ; Обработка выбора
        mov eax, dword ptr [rbp-8]
        cmp eax, 0
        je exit_program
        cmp eax, 1
        je add_element
        cmp eax, 2
        je remove_element
        cmp eax, 3
        je find_element
        cmp eax, 4
        je print_array
        cmp eax, 5
        je sort_array
        cmp eax, 6
        je save_array
        cmp eax, 7
        je load_array

        ; Некорректный выбор
        jmp invalid_menu_input

add_element:
        ; Получаем значение элемента (как строку)
        lea rcx, input_prompt
        call printf
        lea rcx, string_fmt
        lea rdx, [rbp-48]     ; Буфер для ввода
        call scanf

        ; Проверка ввода
        lea rcx, [rbp-48]
        call validate_number
        test rax, rax
        jz invalid_number_input

        ; Конвертируем в число
        lea rcx, [rbp-48]
        lea rdx, element_fmt
        lea r8, [rbp-16]      ; Переменная для значения
        call sscanf

        ; Добавляем элемент в массив
        mov rcx, [rbp-16]
        call array_add

        ; Выводим массив
        call array_print
        jmp menu_loop

remove_element:
        ; Проверка на пустой массив
        cmp qword ptr [array_size], 0
        jne input_index

        lea rcx, error_empty
        call printf
        jmp menu_loop

input_index:
        ; Получаем индекс (как строку)
        lea rcx, index_prompt
        mov rdx, [array_size]
        dec rdx
        call printf
        lea rcx, string_fmt
        lea rdx, [rbp-40]     ; Буфер для ввода
        call scanf

        ; Проверка ввода
        lea rcx, [rbp-40]
        call validate_number
        test rax, rax
        jz invalid_index_input

        ; Конвертируем в число
        lea rcx, [rbp-40]
        lea rdx, int32_fmt
        lea r8, [rbp-24]      ; Переменная для индекса
        call sscanf

        ; Проверка диапазона индекса
        mov rax, [rbp-24]
        cmp rax, [array_size]
        jge invalid_index_range
        test rax, rax
        js invalid_index_range

        ; Удаляем элемент
        mov rcx, [rbp-24]
        call array_remove

        ; Выводим массив
        call array_print
        jmp menu_loop

find_element:
        ; Получаем искомое значение (как строку)
        lea rcx, search_prompt
        call printf
        lea rcx, string_fmt
        lea rdx, [rbp-48]     ; Буфер для ввода
        call scanf

        ; Проверка ввода
        lea rcx, [rbp-48]
        call validate_number
        test rax, rax
        jz invalid_search_input

        ; Конвертируем в число
        lea rcx, [rbp-48]
        lea rdx, element_fmt
        lea r8, [rbp-32]      ; Переменная для поиска
        call sscanf

        ; Поиск элемента
        mov rcx, [rbp-32]
        call array_find

        ; Вывод результата
        cmp rax, -1
        je not_found_msg

        lea rcx, search_found
        mov rdx, [rbp-32]
        mov r8, rax
        call printf
        jmp menu_loop

print_array:
        call array_print
        jmp menu_loop

sort_array:
        call array_sort
        call array_print
        jmp menu_loop

save_array:
        call array_save
        jmp menu_loop

load_array:
        call array_load
        jmp menu_loop

invalid_menu_input:
invalid_number_input:
invalid_index_input:
invalid_search_input:
        lea rcx, invalid_input_msg
        call printf
        jmp menu_loop

invalid_index_range:
        lea rcx, error_index
        call printf
        jmp menu_loop

not_found_msg:
        lea rcx, search_notfound
        mov rdx, [rbp-32]
        call printf
        jmp menu_loop

exit_program:
        ; Освобождаем память массива
        mov rcx, [array_ptr]
        test rcx, rcx
        jz no_free
        call free

no_free:
        ; Завершение программы
        xor ecx, ecx
        call exit
main endp
end