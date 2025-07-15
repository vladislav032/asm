        include _constants_.inc
        include _extern_.inc
        include globalData.asm

        extern contacts     :Contact
        extern contactCount :qword
        extern inputBuffer  :byte
        extern phoneBuffer  :byte
        extern nameBuffer   :byte

.code
; Функция сохранения контактов в файл
saveToFile proc
        push rbx
        push rsi
        sub rsp, 40h

        ; Открываем файл для записи
        lea rcx, FILENAME
        lea rdx, fileWriteMode
        call fopen
        test rax, rax
        jz save_error

        mov rsi, rax ; сохраняем указатель на файл

        ; Проверяем, есть ли контакты для сохранения
        mov rbx, [contactCount]
        test rbx, rbx
        jz save_empty

        ; Сохраняем каждый контакт
        xor rbx, rbx

save_loop:
        cmp rbx, [contactCount]
        jge save_done

        GetContactPtr rbx, rax

        ; Формируем строку в формате "name-phone\n"
        lea rcx, inputBuffer    ; используем inputBuffer как временный буфер
        lea rdx, stringFormat   ; формат "%s-%s\n"
        lea r8, [rax].Contact.name_
        lea r9, [rax].Contact.phone
        call sprintf

        ; Записываем строку в файл
        lea rcx, inputBuffer
        mov rdx, 1              ; размер элемента
        mov r8, rax             ; длина строки (возвращается в eax после sprintf)
        mov r9, rsi             ; указатель на файл
        call fwrite

        inc rbx
        jmp save_loop

save_empty:
        ; Если нет контактов, просто создаем пустой файл
        lea rcx, noContacts
        call printf

save_done:
        ; Закрываем файл
        mov rcx, rsi
        call fclose

        lea rcx, saveSuccess
        call printf
        jmp save_end

save_error:
        lea rcx, fileError
        call printf

save_end:
        add rsp, 40h
        pop rsi
        pop rbx
        ret
saveToFile endp

; Функция загрузки контактов из файла
loadFromFile proc
        push rbx                ; сохраняем регистры, которые будем использовать
        push r12
        push rdi
        push rsi
        sub  rsp, 20h           ; резервируем место (32 байта) для вызовов функций

        ; Открытие файла для чтения (rb mode)
        lea  rcx, FILENAME      ; имя файла "phonebook.dat"
        lea  rdx, fileReadMode  ; режим "rb"
        call fopen
        test rax, rax
        jz   load_error         ; если rax == 0, файл не открыт -> ошибка

        mov  r12, rax           ; сохранить указатель FILE* в r12
        xor  rax, rax
        mov  [contactCount], rax  ; обнуляем счетчик контактов (замена списка)

load_loop:
        ; Проверка: не больше MAX_CONTACTS контактов
        mov  rax, [contactCount]
        cmp  rax, MAX_CONTACTS
        jge  load_done          ; если достигнут лимит (100), завершаем чтение

        ; Чтение одной строки из файла
        lea  rcx, inputBuffer
        mov  edx, 100           ; размер буфера (читаем не более 99 символов + null)
        mov  r8, r12            ; FILE* (указатель на открытый файл)
        call fgets
        test rax, rax
        jz   load_done          ; если fgets вернул 0 (EOF или ошибка чтения) -> выход из цикла

        ; Разбор строки на имя и телефон по формату "%[^-]-%[^\n]"
        lea  rcx, inputBuffer
        lea  rdx, loadFormatString
        lea  r8,  nameBuffer
        lea  r9,  phoneBuffer
        call sscanf
        cmp  eax, 2
        jne  load_loop          ; если не удалось считать оба поля, пропускаем эту строку

        ; Сохранение прочитанного контакта в массив
        mov  rbx, [contactCount]    ; индекс для нового контакта
        GetContactPtr rbx, rax      ; rax -> адрес структуры contacts[rbx]
        ; Копируем имя (фиксированной длины MAX_NAME_LEN)
        lea  rdi, [rax].Contact.name_
        lea  rsi, nameBuffer
        mov  rcx, MAX_NAME_LEN
        rep movsb
        ; Копируем телефон (MAX_PHONE_LEN)
        lea  rdi, [rax].Contact.phone
        lea  rsi, phoneBuffer
        mov  rcx, MAX_PHONE_LEN
        rep movsb

        inc qword ptr [contactCount]  ; увеличиваем счетчик контактов
        jmp  load_loop               ; переходим к чтению следующей записи

load_done:
        mov  rcx, r12       ; закрываем файл, r12 содержит FILE*
        call fclose
        lea  rcx, loadSuccess
        call printf         ; выводим сообщение об успешной загрузке
        jmp  load_end

load_error:
        lea  rcx, fileError
        call printf         ; выводим сообщение об ошибке работы с файлом

load_end:
        add  rsp, 20h
        pop  rsi
        pop  rdi
        pop  r12
        pop  rbx
        ret
loadFromFile endp
END