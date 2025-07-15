; User interface procedures
        option casemap:none

        ; Подключаемые файлы:
        include _constants_.inc  ; Константы и определения
        include _extern_.inc     ; Внешние объявления
        include _macros_.inc     ; Макросы
        include globalData.asm   ; Глобальные данные

        ; Внешние переменные, используемые в этом модуле:
        extrn hStdOut:qword
        extern bytesWritten:dword

.code

; Процедура вывода меню на экран
PrintMenu proc
        sub rsp, 28h         ; Выравнивание стека (32-байтовая тень + 8 для выравнивания)
        
        ; Вывод элементов меню с помощью макроса print_str:
        print_str menuHeader  ; Заголовок меню
        print_str menuOption1 ; Пункт меню 1
        print_str menuOption2 ; Пункт меню 2
        print_str menuPrompt  ; Приглашение для ввода
        
        add rsp, 28h         ; Восстановление стека
        ret                  ; Возврат из процедуры
PrintMenu endp

END