; ========================================================
; Программа сортировки массива (Bubble Sort и Selection Sort)
; ========================================================
include _constants_.inc
include _extern_.inc
include globalData.asm

extern validate_number:proc
extern print_array:proc
extern safe_menu_input:proc
extern input_array:proc
extern init_default_array:proc
extern bubble_sort_asc:proc
extern bubble_sort_desc:proc
extern selection_sort_asc:proc
extern selection_sort_desc:proc

.data
public array
public default_array
public current_size
public input_buffer
public temp_num_buffer

array           sqword ARRAY_SIZE dup(0)  ; Массив
default_array   sqword 34, 12, 89, 5, 67, 23, 45, 1, 78, 56  ; Массив по умолчанию
current_size    dq 0                  ; Текущий размер массива
input_buffer    db INPUT_BUFFER_SIZE dup(0) ; Буфер для ввода
temp_num_buffer db 32 dup(0)          ; Буфер для отдельного числа

.code
; --------------------------------------------------------
; Основная процедура программы
; --------------------------------------------------------
main proc
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
menu_loop:
    ; Ввод выбора с проверкой
    call safe_menu_input
    
    ; Обработка выбора
    cmp eax, 0
    je exit_program
    cmp eax, 1
    je manual_input
    cmp eax, 2
    je default_input
    cmp eax, 3
    je bubble_asc
    cmp eax, 4
    je bubble_desc
    cmp eax, 5
    je selection_asc
    cmp eax, 6
    je selection_desc
    cmp eax, 7
    je print_current
    
manual_input:
    call input_array
    jmp menu_loop
    
default_input:
    call init_default_array
    
    ; Вывод массива
    lea rcx, unsorted_msg
    lea rdx, array
    mov r8, [current_size]
    call print_array
    
    jmp menu_loop
    
bubble_asc:
    cmp qword ptr [current_size], 0
    je empty_array
    
    lea rcx, array
    mov rdx, [current_size]
    call bubble_sort_asc
    
    ; Вывод результата
    lea rcx, sorted_msg
    lea rdx, array
    mov r8, [current_size]
    call print_array
    
    jmp menu_loop
    
bubble_desc:
    cmp qword ptr [current_size], 0
    je empty_array
    
    lea rcx, array
    mov rdx, [current_size]
    call bubble_sort_desc
    
    ; Вывод результата
    lea rcx, sorted_msg
    lea rdx, array
    mov r8, [current_size]
    call print_array
    
    jmp menu_loop
    
selection_asc:
    cmp qword ptr [current_size], 0
    je empty_array
    
    lea rcx, array
    mov rdx, [current_size]
    call selection_sort_asc
    
    ; Вывод результата
    lea rcx, sorted_msg
    lea rdx, array
    mov r8, [current_size]
    call print_array
    
    jmp menu_loop
    
selection_desc:
    cmp qword ptr [current_size], 0
    je empty_array
    
    lea rcx, array
    mov rdx, [current_size]
    call selection_sort_desc
    
    ; Вывод результата
    lea rcx, sorted_msg
    lea rdx, array
    mov r8, [current_size]
    call print_array
    
    jmp menu_loop
    
print_current:
    cmp qword ptr [current_size], 0
    je empty_array
    
    lea rcx, unsorted_msg
    lea rdx, array
    mov r8, [current_size]
    call print_array
    jmp menu_loop
    
empty_array:
    lea rcx, invalid_input
    call printf
    jmp menu_loop
    
exit_program:
    ; Завершение программы
    xor ecx, ecx
    call exit
main endp

end