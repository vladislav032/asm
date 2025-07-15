; Main program
        option casemap:none
        include _constants_.inc
        include _extern_.inc
        include _macros_.inc
        include globalData.asm
        
        ; External procedures
        extern PrintMenu            :proc
        extern CloseCurrentFile     :proc
        extern SelectFile           :proc

.data
        public fileBuffer, hFile, hStdOut, bytesWritten

        hInstance       dq 0       ; Handle текущего модуля
        hStdOut         dq 0       ; Handle стандартного вывода
        hStdIn          dq 0       ; Handle стандартного ввода
        hFile           dq 0       ; Handle открытого файла
        fileBuffer      dw 260 dup(0)  ; Буфер для имени файла

        ; Рабочие буферы
        inputBuffer     db 16 dup(0)   ; Ввод пользователя
        outputBuffer    db 256 dup(0)  ; Форматированный вывод
        fileDataBuffer  db 4096 dup(0) ; Данные файла
        bytesWritten    dd 0           ; Количество записанных байт
        fileSize        dd 0           ; Размер файла
        bytesRead_      dd 0           ; Количество прочитанных байт

.code
main proc
        sub rsp, 28h  ; Выравнивание стека

        ; Инициализация handles
        mov rcx, STD_OUTPUT_HANDLE
        call [__imp_GetStdHandle]
        mov [hStdOut], rax

        mov rcx, STD_INPUT_HANDLE
        call [__imp_GetStdHandle]
        mov [hStdIn], rax

        ; Получаем handle модуля
        xor rcx, rcx
        call [__imp_GetModuleHandleW]
        mov hInstance, rax
    
menu_loop:
        call PrintMenu

        ; Чтение ввода пользователя
        mov rcx, [hStdIn]
        lea rdx, inputBuffer
        mov r8, 16
        lea r9, bytesRead_
        call [__imp_ReadConsoleA]

        ; Обработка выбора
        movzx eax, byte ptr [inputBuffer]
        cmp ax, '1'
        je select_file
        cmp ax, '2'
        je exit_program

        print_str invalidChoice
        jmp menu_loop
    
select_file:
        call CloseCurrentFile
        call SelectFile
        test rax, rax
        jz menu_loop

        ; Вывод имени файла
        lea rcx, outputBuffer
        lea rdx, selectedFileMsg
        lea r8, fileBuffer
        call [__imp_wsprintfA]
        print_str outputBuffer

        ; Открытие файла
        lea rcx, fileBuffer
        mov rdx, GENERIC_READ
        mov r8, FILE_SHARE_READ
        call [__imp_CreateFileW]
        cmp rax, -1
        je read_error
        mov [hFile], rax

        ; Получение размера файла
        mov rcx, rax
        call [__imp_GetFileSize]
        mov [fileSize], eax

        ; Проверка размера буфера
        cmp eax, sizeof fileDataBuffer
        jae buffer_too_small

        ; Чтение файла
        mov rcx, [hFile]
        lea rdx, fileDataBuffer
        mov r8d, [fileSize]
        call [__imp_ReadFile]
        test rax, rax
        jz read_error

        ; Вывод содержимого
        print_str fileContentMsg
        mov rcx, [hStdOut]
        lea rdx, fileDataBuffer
        mov r8d, [bytesRead_]
        call [__imp_WriteFile]

        jmp menu_loop
    
buffer_too_small:
read_error:
        print_str readErrorMsg
        call CloseCurrentFile
        jmp menu_loop
    
exit_program:
        call CloseCurrentFile
        xor ecx, ecx
        call [__imp_ExitProcess]
main endp
end