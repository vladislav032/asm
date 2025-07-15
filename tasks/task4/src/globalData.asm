        include _constants_.inc   ; Подключаем файл констант
        include _extern_.inc      ; Подключаем внешние объявления

.data
        ; Сообщения для пользователя
        menu_msg        db 0Dh, 0Ah, "Menu:", 0Dh, 0Ah
                        db "1. Add element", 0Dh, 0Ah
                        db "2. Remove element by index", 0Dh, 0Ah
                        db "3. Find element", 0Dh, 0Ah
                        db "4. Print array", 0Dh, 0Ah
                        db "5. Sort array", 0Dh, 0Ah
                        db "6. Save to file", 0Dh, 0Ah
                        db "7. Load from file", 0Dh, 0Ah
                        db "0. Exit", 0Dh, 0Ah
                        db "Your choice: ", 0

        input_prompt    db "Enter value: ", 0          ; Приглашение ввода значения
        filename_prompt db "Enter filename: ", 0       ; Приглашение ввода имени файла
        index_prompt    db "Enter index (0-%d): ", 0   ; Приглашение ввода индекса
        search_prompt   db "Enter value to search: ", 0 ; Приглашение ввода поиска

        ; Форматы ввода/вывода
        element_fmt     db "%lld", 0   ; Формат для 64-битных чисел
        string_fmt      db "%s", 0     ; Формат для строк
        int32_fmt       db "%d", 0     ; Формат для 32-битных чисел

        ; Форматы вывода массива
        array_start_fmt db "Current array: [", 0  ; Начало вывода массива
        array_sep_fmt   db ", ", 0               ; Разделитель элементов
        array_end_fmt   db "]", 0Dh, 0Ah, 0      ; Конец вывода массива

        ; Сообщения о состоянии
        empty_array_msg db "Current array: []", 0Dh, 0Ah, 0  ; Пустой массив
        add_success     db "Added element %lld", 0Dh, 0Ah, 0  ; Успешное добавление
        remove_success  db "Removed element at index %d", 0Dh, 0Ah, 0 ; Удаление
        search_found    db "Element %lld found at index %d", 0Dh, 0Ah, 0 ; Найден элемент
        search_notfound db "Element %lld not found", 0Dh, 0Ah, 0      ; Элемент не найден
        sort_success    db "Array sorted successfully", 0Dh, 0Ah, 0    ; Успешная сортировка
        save_success    db "Array saved to file %s", 0Dh, 0Ah, 0       ; Сохранение в файл
        load_success    db "Array loaded from file %s", 0Dh, 0Ah, 0    ; Загрузка из файла

        ; Сообщения об ошибках
        error_empty     db "Error: Array is empty!", 0Dh, 0Ah, 0       ; Ошибка пустого массива
        error_index     db "Error: Invalid index!", 0Dh, 0Ah, 0        ; Неверный индекс
        error_alloc     db "Error: Memory allocation failed!", 0Dh, 0Ah, 0 ; Ошибка выделения памяти
        error_file      db "Error: File operation failed!", 0Dh, 0Ah, 0    ; Ошибка файла
        error_big_num   db "Error: Number is too large! Must be between -2147483648 and 2147483647", 0Dh, 0Ah, 0 ; Слишком большое число
        invalid_input_msg db "Error: Invalid input! Please enter a valid number.", 0Dh, 0Ah, 0 ; Неверный ввод
        invalid_fm_msg  db "Error: Invalid data format in file!", 0Dh, 0Ah, 0 ; Неверный формат в файле
        no_numbers_msg  db "Error: No valid numbers found in file!", 0Dh, 0Ah, 0 ; Нет чисел в файле

        ; Служебные строки
        newline         db 0Dh, 0Ah, 0          ; Перевод строки
        read_mode       db "rb", 0               ; Режим чтения файла
        write_mode      db "wb", 0               ; Режим записи файла

        ; Структура динамического массива
        array_ptr       dq 0      ; Указатель на массив
        array_size      dq 0      ; Текущий размер массива
        array_capacity  dq 0      ; Текущая емкость массива

        ; Прототипы функций для работы с массивом
        array_init proto          ; Инициализация массива
        array_grow proto          ; Увеличение емкости массива
        array_add proto           ; Добавление элемента
        array_remove proto        ; Удаление по индексу
        array_find proto          ; Поиск элемента
        array_print proto         ; Вывод массива
        array_sort proto          ; Сортировка массива
        array_save proto          ; Сохранение в файл
        array_load proto          ; Загрузка из файла