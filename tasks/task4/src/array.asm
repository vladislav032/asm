include _constants_.inc   ; Подключаем константы программы
include _extern_.inc      ; Внешние объявления функций
include globalData.asm    ; Глобальные данные

extern check_int32_range:proc  ; Внешняя функция проверки диапазона

.code
; --------------------------------------------------------
; Инициализация динамического массива
; --------------------------------------------------------
array_init proc
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; Выделяем память под начальный массив
    mov rcx, INITIAL_CAPACITY * 8  ; 8 байт на элемент
    call malloc
    test rax, rax
    jz alloc_error                 ; Если malloc вернул NULL
    
    ; Обнуляем выделенную память
    mov rcx, rax
    mov rdx, 0
    mov r8, INITIAL_CAPACITY * 8
    call memset
    
    ; Сохраняем указатель и устанавливаем параметры
    mov [array_ptr], rax           ; Сохраняем указатель на массив
    mov [array_size], 0            ; Начальный размер - 0
    mov [array_capacity], INITIAL_CAPACITY ; Начальная емкость
    jmp init_done
    
alloc_error:
    ; Обработка ошибки выделения памяти
    lea rcx, error_alloc
    call printf
    mov ecx, 1
    call exit                      ; Выход с кодом ошибки
    
init_done:
    leave
    ret
array_init endp

; --------------------------------------------------------
; Сохранение массива в файл
; --------------------------------------------------------
array_save proc
    push rbp
    mov rbp, rsp
    sub rsp, 256
    
    ; Проверка на пустой массив
    cmp qword ptr [array_size], 0
    jne get_filename
    
    lea rcx, error_empty
    call printf
    jmp save_done
    
get_filename:
    ; Запрос имени файла у пользователя
    lea rcx, filename_prompt
    call printf
    lea rcx, string_fmt
    lea rdx, [rbp-32]   ; Буфер для имени файла
    call scanf
    
    ; Открываем файл для записи
    lea rcx, [rbp-32]        ; Имя файла
    mov rdx, GENERIC_WRITE    ; Режим доступа
    mov r8, FILE_SHARE_READ   ; Режим совместного доступа
    xor r9, r9               ; Атрибуты безопасности
    mov qword ptr [rsp+32], CREATE_ALWAYS ; Флаги создания
    mov qword ptr [rsp+40], FILE_ATTRIBUTE_NORMAL ; Атрибуты
    mov qword ptr [rsp+48], 0 ; Шаблон файла
    call CreateFileA
    cmp rax, -1              ; Проверка на ошибку
    je save_file_error
    
    mov [rbp-40], rax        ; Сохраняем хэндл файла
    
    ; Вычисляем размер буфера (максимально возможный)
    mov rcx, [array_size]
    imul rcx, 21             ; 20 цифр + пробел на число
    inc rcx                  ; +1 для нуль-терминатора
    
    ; Выделяем буфер
    call malloc
    test rax, rax
    jz save_alloc_error
    
    mov [rbp-48], rax        ; Сохраняем указатель на буфер
    mov rdi, rax             ; Указатель для записи
    
    ; Форматируем числа в буфер
    mov rsi, [array_ptr]     ; Указатель на массив
    mov rbx, 0               ; Индекс
    
format_loop:
    cmp rbx, [array_size]
    jge format_done
    
    ; Форматируем текущее число
    lea rcx, [rdi]           ; Позиция в буфере
    lea rdx, element_fmt     ; Формат "%lld"
    mov r8, [rsi + rbx*8]    ; Элемент массива
    call sprintf
    
    ; Сдвигаем указатель
    add rdi, rax
    
    ; Добавляем пробел, если не последний элемент
    inc rbx
    cmp rbx, [array_size]
    jge no_space
    
    mov byte ptr [rdi], ' '
    inc rdi
    
no_space:
    jmp format_loop
    
format_done:
    ; Вычисляем реальный размер данных
    mov rax, rdi
    sub rax, [rbp-48]
    mov [rbp-56], rax        ; Сохраняем размер
    
    ; Записываем в файл
    mov rcx, [rbp-40]        ; Хэндл файла
    mov rdx, [rbp-48]        ; Буфер
    mov r8, [rbp-56]         ; Размер данных
    lea r9, [rbp-64]         ; Количество записанных байт
    mov qword ptr [rsp+32], 0 ; Overlapped структура
    call WriteFile
    test rax, rax
    jz write_error           ; Если запись не удалась
    
    ; Закрываем файл
    mov rcx, [rbp-40]
    call CloseHandle
    
    ; Освобождаем буфер
    mov rcx, [rbp-48]
    call free
    
    ; Сообщение об успехе
    lea rcx, save_success
    lea rdx, [rbp-32]
    call printf
    
    jmp save_done
    
save_file_error:
write_error:
    ; Получаем код ошибки
    call GetLastError
    
    ; Освобождаем ресурсы
    mov rcx, [rbp-48]
    test rcx, rcx
    jz no_free_needed
    call free
    
no_free_needed:
    mov rcx, [rbp-40]
    cmp rcx, -1
    je no_close_needed
    call CloseHandle
    
no_close_needed:
    ; Сообщение об ошибке
    lea rcx, error_file
    call printf
    jmp save_done
    
save_alloc_error:
    ; Ошибка выделения памяти
    lea rcx, error_alloc
    call printf
    
save_done:
    leave
    ret
array_save endp

; --------------------------------------------------------
; Загрузка массива из файла
; --------------------------------------------------------
array_load proc
    push rbp
    mov rbp, rsp
    sub rsp, 256
    
    ; Запрос имени файла
    lea rcx, filename_prompt
    call printf
    lea rcx, string_fmt
    lea rdx, [rbp-32]   ; Буфер для имени файла
    call scanf
    
    ; Открываем файл
    lea rcx, [rbp-32]       ; Имя файла
    mov rdx, GENERIC_READ    ; Режим доступа
    mov r8, FILE_SHARE_READ  ; Режим совместного доступа
    xor r9, r9              ; Атрибуты безопасности
    mov qword ptr [rsp+32], OPEN_EXISTING ; Флаги открытия
    mov qword ptr [rsp+40], FILE_ATTRIBUTE_NORMAL ; Атрибуты
    mov qword ptr [rsp+48], 0 ; Шаблон файла
    call CreateFileA
    cmp rax, -1             ; Проверка на ошибку
    je load_file_error
    
    mov [rbp-40], rax       ; Сохраняем хэндл
    
    ; Определяем размер файла
    mov rcx, [rbp-40]
    xor rdx, rdx
    xor r8, r8
    mov r9, 2               ; FILE_END
    call SetFilePointer
    mov [rbp-48], rax       ; Размер файла
    
    ; Возвращаем указатель в начало
    mov rcx, [rbp-40]
    xor rdx, rdx
    xor r8, r8
    mov r9, 0               ; FILE_BEGIN
    call SetFilePointer
    
    ; Выделяем буфер для содержимого файла
    mov rcx, [rbp-48]
    inc rcx                 ; +1 для нуль-терминатора
    call malloc
    test rax, rax
    jz load_alloc_error
    
    mov [rbp-56], rax       ; Сохраняем указатель
    
    ; Читаем весь файл
    mov rcx, [rbp-40]       ; Хэндл файла
    mov rdx, [rbp-56]       ; Буфер
    mov r8, [rbp-48]        ; Размер файла
    lea r9, [rbp-64]        ; Количество прочитанных байт
    mov qword ptr [rsp+32], 0 ; Overlapped структура
    call ReadFile
    test rax, rax
    jz read_error           ; Если чтение не удалось
    
    ; Добавляем нуль-терминатор
    mov rax, [rbp-56]
    add rax, [rbp-48]
    mov byte ptr [rax], 0
    
    ; Закрываем файл
    mov rcx, [rbp-40]
    call CloseHandle
    
    ; Подсчитываем количество чисел в файле
    mov rsi, [rbp-56]       ; Указатель на данные
    mov qword ptr [rbp-72], 0 ; Счетчик чисел
    
count_loop:
    ; Пропускаем пробелы
    call skip_whitespace
    cmp byte ptr [rsi], 0
    je count_done
    
    ; Пытаемся распарсить число
    lea rcx, [rsi]          ; Строка
    lea rdx, element_fmt    ; Формат "%lld"
    lea r8, [rbp-80]        ; Временное хранилище
    call sscanf
    cmp eax, 1
    jne invalid_format      ; Если не удалось распарсить
    
    ; Увеличиваем счетчик чисел
    inc qword ptr [rbp-72]
    
    ; Пропускаем число
    call skip_number
    jmp count_loop
    
count_done:
    ; Проверяем, есть ли числа
    cmp qword ptr [rbp-72], 0
    je no_numbers
    
    ; Освобождаем старый массив, если был
    mov rcx, [array_ptr]
    test rcx, rcx
    jz no_free_needed
    call free
    
no_free_needed:
    ; Выделяем память под новый массив
    mov rcx, [rbp-72]
    mov [array_size], rcx    ; Устанавливаем новый размер
    shl rcx, 3              ; Умножаем на 8 (размер элемента)
    call malloc
    test rax, rax
    jz load_alloc_error
    
    mov [array_ptr], rax
    mov rdi, rax            ; Указатель на массив
    
    ; Парсим числа в массив
    mov rsi, [rbp-56]       ; Сбрасываем указатель
    mov rbx, 0              ; Индекс
    
parse_loop:
    cmp rbx, [array_size]
    jge parse_done
    
    ; Пропускаем пробелы
    call skip_whitespace
    cmp byte ptr [rsi], 0
    je parse_done
    
    ; Читаем число
    lea rcx, [rsi]          ; Строка
    lea rdx, element_fmt    ; Формат "%lld"
    lea r8, [rbp-80]        ; Временное хранилище
    call sscanf
    cmp eax, 1
    jne invalid_format      ; Если не удалось распарсить
    
    ; Проверяем диапазон числа
    mov rax, [rbp-80]
    call check_int32_range
    jz range_ok
    
    ; Число вне диапазона - пропускаем
    lea rcx, error_big_num
    call printf
    call skip_number
    dec qword ptr [array_size]  ; Уменьшаем размер
    jmp parse_loop
    
range_ok:
    ; Сохраняем число в массиве
    mov rax, [rbp-80]
    mov [rdi + rbx*8], rax
    
    ; Переходим к следующему числу
    call skip_number
    inc rbx
    jmp parse_loop
    
parse_done:
    ; Освобождаем буфер файла
    mov rcx, [rbp-56]
    call free
    
    ; Сообщение об успехе
    lea rcx, load_success
    lea rdx, [rbp-32]
    call printf
    
    ; Выводим загруженный массив
    call array_print
    jmp load_done
    
load_file_error:
read_error:
    ; Получаем код ошибки
    call GetLastError
    
    ; Освобождаем ресурсы
    mov rcx, [rbp-56]
    test rcx, rcx
    jz no_free_needed2
    call free
    
no_free_needed2:
    mov rcx, [rbp-40]
    cmp rcx, -1
    je no_close_needed
    call CloseHandle
    
no_close_needed:
    ; Сообщение об ошибке
    lea rcx, error_file
    call printf
    jmp load_done
    
load_alloc_error:
    ; Ошибка выделения памяти
    lea rcx, error_alloc
    call printf
    jmp load_done
    
invalid_format:
    ; Очистка и сообщение о неверном формате
    mov rcx, [rbp-56]
    call free
    mov rcx, [rbp-40]
    call CloseHandle
    
    lea rcx, error_file
    lea rdx, invalid_fm_msg
    call printf
    jmp load_done
    
no_numbers:
    ; Сообщение об отсутствии чисел
    mov rcx, [rbp-56]
    call free
    
    lea rcx, error_file
    lea rdx, no_numbers_msg
    call printf
    
load_done:
    leave
    ret

; --------------------------------------------------------
; Вспомогательные функции для пропуска пробелов и чисел
; --------------------------------------------------------
skip_whitespace:
    mov al, [rsi]
    test al, al
    jz skip_ws_done       ; Конец строки
    cmp al, ' '           ; Пробел
    je skip_ws_advance
    cmp al, 9             ; Табуляция
    je skip_ws_advance
    cmp al, 10            ; Новая строка
    je skip_ws_advance
    cmp al, 13            ; Возврат каретки
    je skip_ws_advance
    jmp skip_ws_done      ; Не пробельный символ
skip_ws_advance:
    inc rsi               ; Следующий символ
    jmp skip_whitespace
skip_ws_done:
    ret

skip_number:
    mov al, [rsi]
    test al, al
    jz skip_num_done      ; Конец строки
    cmp al, '-'           ; Минус
    je skip_num_advance
    cmp al, '+'           ; Плюс
    je skip_num_advance
    cmp al, '0'           ; Цифры
    jb skip_num_check_ws
    cmp al, '9'
    jbe skip_num_advance
skip_num_check_ws:
    ; Проверяем пробельные символы (конец числа)
    cmp al, ' '
    je skip_num_done
    cmp al, 9
    je skip_num_done
    cmp al, 10
    je skip_num_done
    cmp al, 13
    je skip_num_done
    ; Неверный символ
    jmp invalid_format
skip_num_advance:
    inc rsi               ; Следующий символ
    jmp skip_number
skip_num_done:
    ret
array_load endp

; --------------------------------------------------------
; Сортировка массива пузырьком
; --------------------------------------------------------
array_sort proc
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; Проверка на пустой массив
    cmp qword ptr [array_size], 0
    jne sort_array
    
    lea rcx, error_empty
    call printf
    jmp sort_done
    
sort_array:
    mov rcx, [array_size]
    dec rcx                 ; i = size-1
    jle sort_done           ; Если size <= 1, уже отсортирован
    
outer_loop:
    xor rdx, rdx            ; j = 0
    mov r8, [array_ptr]     ; Указатель на массив
    
inner_loop:
    ; Сравниваем соседние элементы
    mov rax, [r8 + rdx*8]   ; array[j]
    mov r9, [r8 + rdx*8 + 8] ; array[j+1]
    cmp rax, r9
    jle no_swap             ; Если уже в правильном порядке
    
    ; Меняем местами
    mov [r8 + rdx*8], r9
    mov [r8 + rdx*8 + 8], rax
    
no_swap:
    inc rdx                 ; j++
    cmp rdx, rcx            ; j < i ?
    jl inner_loop
    
    dec rcx                 ; i--
    jnz outer_loop          ; Продолжаем, пока i > 0
    
    ; Сообщение об успешной сортировке
    lea rcx, sort_success
    call printf
    
sort_done:
    leave
    ret
array_sort endp

; --------------------------------------------------------
; Увеличение емкости массива при необходимости
; --------------------------------------------------------
array_grow proc
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; Проверяем, нужно ли увеличивать
    mov rax, [array_size]
    cmp rax, [array_capacity]
    jl grow_done            ; Если размер < емкости, не нужно
    
    ; Увеличиваем емкость в GROW_FACTOR раз
    mov rax, [array_capacity]
    imul rax, GROW_FACTOR
    
    ; Перевыделяем память
    mov rcx, [array_ptr]
    mov rdx, rax
    shl rdx, 3              ; Умножаем на 8 (размер элемента)
    call realloc
    test rax, rax
    jz grow_error           ; Если не удалось
    
    ; Обновляем параметры массива
    mov [array_ptr], rax
    mov [array_capacity], rax
    jmp grow_done
    
grow_error:
    ; Ошибка выделения памяти
    lea rcx, error_alloc
    call printf
    xor eax, eax
    jmp exit
    
grow_done:
    leave
    ret
array_grow endp

; --------------------------------------------------------
; Добавление элемента в массив
; Вход: RCX - значение элемента
; --------------------------------------------------------
array_add proc
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; Проверяем диапазон числа
    mov rax, rcx
    call check_int32_range
    jz range_ok
    
    ; Число вне диапазона
    lea rcx, error_big_num
    call printf
    jmp add_done
    
range_ok:
    ; Сохраняем значение элемента
    mov [rbp+16], rcx
    
    ; Увеличиваем емкость при необходимости
    call array_grow
    
    ; Добавляем элемент в конец
    mov rax, [array_size]
    mov rdx, [array_ptr]
    mov rcx, [rbp+16]    ; Восстанавливаем значение
    mov [rdx + rax*8], rcx
    
    ; Увеличиваем размер
    inc qword ptr [array_size]
    
    ; Сообщение об успешном добавлении
    lea rcx, add_success
    mov rdx, [rbp+16]
    call printf
    
add_done:
    leave
    ret
array_add endp

; --------------------------------------------------------
; Удаление элемента по индексу
; Вход: RCX - индекс элемента
; --------------------------------------------------------
array_remove proc
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; Сохраняем индекс
    mov [rbp+16], rcx
    
    ; Проверка на пустой массив
    cmp qword ptr [array_size], 0
    jne check_index
    
    lea rcx, error_empty
    call printf
    jmp remove_done
    
check_index:
    ; Проверка корректности индекса
    cmp rcx, [array_size]
    jl valid_index
    
    lea rcx, error_index
    call printf
    jmp remove_done
    
valid_index:
    ; Вычисляем области памяти для перемещения
    mov rcx, [array_ptr]
    mov rdx, [rbp+16]    ; Индекс
    lea rdi, [rcx + rdx*8]    ; Куда копировать
    lea rsi, [rcx + rdx*8 + 8] ; Откуда копировать
    mov rdx, [array_size]
    sub rdx, [rbp+16]
    dec rdx
    shl rdx, 3           ; Умножаем на 8 (размер элемента)
    
    ; Перемещаем элементы
    call memmove
    
    ; Уменьшаем размер
    dec qword ptr [array_size]
    
    ; Сообщение об успешном удалении
    lea rcx, remove_success
    mov rdx, [rbp+16]
    call printf
    
remove_done:
    leave
    ret
array_remove endp

; --------------------------------------------------------
; Поиск элемента в массиве
; Вход: RCX - значение для поиска
; Выход: RAX - индекс или -1 если не найден
; --------------------------------------------------------
array_find proc
    push rbp
    mov rbp, rsp
    
    xor rax, rax         ; Начинаем с индекса 0
    mov rdx, [array_ptr] ; Указатель на массив
    
find_loop:
    cmp rax, [array_size]
    jge not_found        ; Если дошли до конца
    
    ; Сравниваем текущий элемент с искомым
    cmp rcx, [rdx + rax*8]
    je found             ; Если нашли
    
    inc rax              ; Следующий индекс
    jmp find_loop
    
not_found:
    mov rax, -1          ; Возвращаем -1 если не нашли
    
found:
    leave
    ret
array_find endp

; --------------------------------------------------------
; Вывод массива
; --------------------------------------------------------
array_print proc
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; Проверка на пустой массив
    cmp qword ptr [array_size], 0
    jne print_elements
    
    lea rcx, empty_array_msg
    call printf
    jmp print_done
    
print_elements:
    ; Вывод начала массива
    lea rcx, array_start_fmt
    call printf
    
    ; Вывод элементов
    mov rbx, [array_ptr] ; Указатель на массив
    xor rsi, rsi         ; Индекс
    
print_loop:
    ; Вывод текущего элемента
    lea rcx, element_fmt
    mov rdx, [rbx + rsi*8]
    call printf
    
    ; Проверяем последний ли это элемент
    inc rsi
    cmp rsi, [array_size]
    jge print_end
    
    ; Вывод разделителя
    lea rcx, array_sep_fmt
    call printf
    jmp print_loop
    
print_end:
    ; Вывод конца массива
    lea rcx, array_end_fmt
    call printf
    
print_done:
    leave
    ret
array_print endp