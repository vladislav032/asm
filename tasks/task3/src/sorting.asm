include _constants_.inc   ; Подключаем файл констант
include _extern_.inc      ; Подключаем внешние объявления
include globalData.asm    ; Подключаем глобальные данные
extern current_size:qword ; Внешняя переменная - текущий размер массива

.code
; --------------------------------------------------------
; Сортировка пузырьком по возрастанию
; Вход: RCX - указатель на массив
;       RDX - размер массива
; --------------------------------------------------------
bubble_sort_asc proc
    push rbp
    mov rbp, rsp

    mov rsi, rcx         ; Сохраняем указатель на массив в RSI
    mov rcx, rdx         ; Количество элементов в RCX
    dec rcx              ; Нужно (n-1) итераций

outer_loop:
    xor rbx, rbx         ; Индекс текущего элемента (сбрасываем в 0)
    mov rdx, rcx         ; Счетчик внутреннего цикла

inner_loop:
    ; Сравниваем текущий и следующий элементы
    mov rax, [rsi + rbx*8]   ; Текущий элемент
    mov rdi, [rsi + rbx*8 + 8] ; Следующий элемент

    cmp rax, rdi         ; Сравниваем элементы
    jle no_swap          ; Если уже в правильном порядке, не меняем

    ; Меняем элементы местами
    mov [rsi + rbx*8], rdi
    mov [rsi + rbx*8 + 8], rax

no_swap:
    inc rbx              ; Переходим к следующей паре
    dec rdx              ; Уменьшаем счетчик внутреннего цикла
    jnz inner_loop       ; Продолжаем, пока не пройдем весь массив

    loop outer_loop      ; Повторяем для всех элементов

    leave
    ret
bubble_sort_asc endp

; --------------------------------------------------------
; Сортировка пузырьком по убыванию
; Вход: RCX - указатель на массив
;       RDX - размер массива
; --------------------------------------------------------
bubble_sort_desc proc
    push rbp
    mov rbp, rsp

    mov rsi, rcx         ; Сохраняем указатель на массив
    mov rcx, rdx         ; Количество элементов
    dec rcx              ; Нужно (n-1) итераций

outer_loop:
    xor rbx, rbx         ; Индекс текущего элемента
    mov rdx, rcx         ; Счетчик внутреннего цикла

inner_loop:
    ; Сравниваем текущий и следующий элементы
    mov rax, [rsi + rbx*8]   ; Текущий элемент
    mov rdi, [rsi + rbx*8 + 8] ; Следующий элемент

    cmp rax, rdi         ; Сравниваем элементы
    jge no_swap          ; Если уже в правильном порядке, не меняем

    ; Меняем элементы местами
    mov [rsi + rbx*8], rdi
    mov [rsi + rbx*8 + 8], rax

no_swap:
    inc rbx              ; Переходим к следующей паре
    dec rdx              ; Уменьшаем счетчик внутреннего цикла
    jnz inner_loop       ; Продолжаем, пока не пройдем весь массив

    loop outer_loop      ; Повторяем для всех элементов

    leave
    ret
bubble_sort_desc endp

; --------------------------------------------------------
; Сортировка выбором по возрастанию
; Вход: RCX - указатель на массив
; Использует глобальную переменную current_size
; --------------------------------------------------------
selection_sort_asc proc
    push rbp
    mov rbp, rsp

    mov rsi, rcx         ; Сохраняем указатель на массив
    xor rbx, rbx         ; Индекс текущего элемента (i)

outer_loop:
    mov rdi, rbx         ; Индекс минимального элемента (min_idx = i)
    mov rdx, rbx         ; Индекс для поиска (j = i + 1)
    inc rdx

inner_loop:
    cmp rdx, [current_size] ; Проверяем выход за границы массива
    jge end_inner

    ; Сравниваем текущий элемент с найденным минимальным
    mov r8, [rsi + rdi*8]   ; Текущий минимальный элемент
    mov r9, [rsi + rdx*8]   ; Следующий элемент
    cmp r9, r8
    jge no_new_min       ; Если не меньше, пропускаем

    mov rdi, rdx         ; Нашли новый минимальный элемент

no_new_min:
    inc rdx              ; Переходим к следующему элементу
    jmp inner_loop

end_inner:
    ; Меняем местами текущий элемент и найденный минимальный
    mov rax, [rsi + rbx*8]   ; array[i]
    mov rdx, [rsi + rdi*8]   ; array[min_idx]
    mov [rsi + rbx*8], rdx   ; array[i] = array[min_idx]
    mov [rsi + rdi*8], rax   ; array[min_idx] = array[i]

    inc rbx              ; Переходим к следующему элементу
    cmp rbx, [current_size] ; Проверяем конец массива
    jl outer_loop        ; Продолжаем, если не дошли до конца

    leave
    ret
selection_sort_asc endp

; --------------------------------------------------------
; Сортировка выбором по убыванию
; Вход: RCX - указатель на массив
; Использует глобальную переменную current_size
; --------------------------------------------------------
selection_sort_desc proc
    push rbp
    mov rbp, rsp

    mov rsi, rcx         ; Сохраняем указатель на массив
    xor rbx, rbx         ; Индекс текущего элемента (i)

outer_loop:
    mov rdi, rbx         ; Индекс максимального элемента (max_idx = i)
    mov rdx, rbx         ; Индекс для поиска (j = i + 1)
    inc rdx

inner_loop:
    cmp rdx, [current_size] ; Проверяем выход за границы массива
    jge end_inner

    ; Сравниваем текущий элемент с найденным максимальным
    mov r8, [rsi + rdi*8]   ; Текущий максимальный элемент
    mov r9, [rsi + rdx*8]   ; Следующий элемент
    cmp r9, r8
    jle no_new_max       ; Если не больше, пропускаем

    mov rdi, rdx         ; Нашли новый максимальный элемент

no_new_max:
    inc rdx              ; Переходим к следующему элементу
    jmp inner_loop

end_inner:
    ; Меняем местами текущий элемент и найденный максимальный
    mov rax, [rsi + rbx*8]   ; array[i]
    mov rdx, [rsi + rdi*8]   ; array[max_idx]
    mov [rsi + rbx*8], rdx   ; array[i] = array[max_idx]
    mov [rsi + rdi*8], rax   ; array[max_idx] = array[i]

    inc rbx              ; Переходим к следующему элементу
    cmp rbx, [current_size] ; Проверяем конец массива
    jl outer_loop        ; Продолжаем, если не дошли до конца

    leave
    ret
selection_sort_desc endp
end