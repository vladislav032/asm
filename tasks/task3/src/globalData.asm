include _constants_.inc
include _extern_.inc

.data
; Сообщения для пользователя
menu_msg        db 0Dh, 0Ah, "Menu:", 0Dh, 0Ah
                db "1. Input array manually", 0Dh, 0Ah
                db "2. Use default array", 0Dh, 0Ah
                db "3. Bubble Sort (ascending)", 0Dh, 0Ah
                db "4. Bubble Sort (descending)", 0Dh, 0Ah
                db "5. Selection Sort (ascending)", 0Dh, 0Ah
                db "6. Selection Sort (descending)", 0Dh, 0Ah
                db "7. Print array", 0Dh, 0Ah
                db "0. Exit", 0Dh, 0Ah
                db "Your choice: ", 0

input_prompt    db "Enter up to %d numbers (separated by spaces): ", 0Dh, 0Ah
                db "Note: Only numbers will be processed", 0Dh, 0Ah, 0
element_fmt     db "%s", 0            ; Для чтения строки
unsorted_msg    db "Unsorted array: ", 0
sorted_msg      db "Sorted array:   ", 0
array_fmt       db "%d ", 0
newline         db 0Dh, 0Ah, 0
invalid_input   db "Invalid input! Please enter a valid number.", 0Dh, 0Ah, 0
invalid_menu    db "Invalid menu choice! Please enter a number from 0 to 7.", 0Dh, 0Ah, 0

; Данные