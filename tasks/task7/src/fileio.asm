; File I/O procedures
        option casemap:none  ; Отключаем чувствительность к регистру символов

        ; Подключаем необходимые заголовочные файлы
        include _constants_.inc  ; Файл с константами
        include _extern_.inc     ; Файл с объявлениями внешних функций
        include _macros_.inc     ; Файл с макросами
        include globalData.asm   ; Файл с глобальными данными

        ; Объявляем внешние переменные, которые определены в других модулях
        extern fileBuffer:word    ; Буфер для имени файла (2 байта на символ Unicode)
        extern hFile:qword       ; Дескриптор открытого файла

.code

; Процедура выбора файла через диалоговое окно
SelectFile proc
        sub rsp, 98h         ; Выделяем место в стеке для структуры OPENFILENAMEW

        ; Заполняем структуру OPENFILENAMEW для функции GetOpenFileNameW
        lea rax, [rsp]       ; Указатель на структуру в стеке

        ; Заполнение полей структуры:
        mov qword ptr [rax+0], 98h       ; lStructSize - размер структуры
        mov qword ptr [rax+8], 0         ; hwndOwner - родительское окно (NULL)
        mov qword ptr [rax+10h], 0       ; hInstance - дескриптор приложения
        lea rdx, fileFilter
        mov qword ptr [rax+18h], rdx     ; lpstrFilter - фильтры для отображения файлов
        mov qword ptr [rax+20h], 0       ; lpstrCustomFilter - не используется
        mov dword ptr [rax+28h], 0       ; nMaxCustFilter - не используется
        mov dword ptr [rax+2Ch], 1       ; nFilterIndex - индекс выбранного фильтра
        lea rdx, fileBuffer
        mov qword ptr [rax+30h], rdx     ; lpstrFile - буфер для имени файла
        mov dword ptr [rax+38h], 260     ; nMaxFile - размер буфера
        mov qword ptr [rax+40h], 0       ; lpstrFileTitle - не используется
        mov dword ptr [rax+48h], 0       ; nMaxFileTitle - не используется
        mov qword ptr [rax+50h], 0       ; lpstrInitialDir - начальная директория
        lea rdx, openFileTitle
        mov qword ptr [rax+58h], rdx     ; lpstrTitle - заголовок диалогового окна
        mov dword ptr [rax+60h], 00080000h ; Flags - флаги диалога
        mov word ptr [rax+64h], 0        ; nFileOffset - смещение в имени файла
        mov word ptr [rax+66h], 0        ; nFileExtension - расширение файла
        mov qword ptr [rax+68h], 0       ; lpstrDefExt - расширение по умолчанию
        mov qword ptr [rax+70h], 0       ; lCustData - пользовательские данные
        mov qword ptr [rax+78h], 0       ; lpfnHook - callback-функция
        mov qword ptr [rax+80h], 0       ; lpTemplateName - шаблон диалога
        mov qword ptr [rax+88h], 0       ; pvReserved - зарезервировано
        mov dword ptr [rax+90h], 0       ; dwReserved - зарезервировано
        mov dword ptr [rax+94h], 0       ; FlagsEx - дополнительные флаги

        ; Вызываем API-функцию для отображения диалога выбора файла
        mov rcx, rax          ; Указатель на структуру
        call [__imp_GetOpenFileNameW]

        add rsp, 98h         ; Восстанавливаем стек
        ret                  ; Возвращаем управление
SelectFile endp

; Процедура закрытия текущего открытого файла
CloseCurrentFile proc
        cmp [hFile], 0       ; Проверяем, есть ли открытый файл
        jz no_file_to_close  ; Если нет, выходим

        ; Закрываем дескриптор файла
        mov rcx, [hFile]     ; Помещаем дескриптор в rcx
        call [__imp_CloseHandle]

        ; Обнуляем переменную с дескриптором
        mov [hFile], 0

no_file_to_close:
        ret                  ; Возвращаем управление
CloseCurrentFile endp
END