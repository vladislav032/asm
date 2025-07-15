        include _constants_.inc
        include _extern_.inc
        include globalData.asm

        extern contactCount         :qword
        extern nameBuffer           :byte
        extern phoneBuffer          :byte
        extern contacts             :Contact
        extern clearBuffer          :proc
        extern trimTrailingSpaces   :proc

.code
; Функция добавления контакта
addContact proc
        push rbx
        push rsi
        push rdi
        sub rsp, 20h

        ; Проверка на переполнение
        mov rax, [contactCount]
        cmp rax, MAX_CONTACTS
        jl can_add

        lea rcx, contactFull
        call printf
        jmp add_end

can_add:
        lea rcx, addContactPrompt
        call printf

        ; Ввод имени
        lea rcx, namePrompt
        call printf

        lea rcx, nameBuffer
        call gets

        ; Ввод телефона
        lea rcx, phonePrompt
        call printf

        lea rcx, phoneBuffer
        call gets

        ; Сохранение контакта
        mov rbx, [contactCount]
        GetContactPtr rbx, rax

        ; Копирование имени
        lea rdi, [rax].Contact.name_
        lea rsi, nameBuffer
        mov rcx, MAX_NAME_LEN
        rep movsb

        ; Копирование телефона
        lea rdi, [rax].Contact.phone
        lea rsi, phoneBuffer
        mov rcx, MAX_PHONE_LEN
        rep movsb

        ; Увеличиваем счетчик контактов
        inc qword ptr [contactCount]

        lea rcx, contactAdded
        call printf

        ; Очистка буферов
        call clearBuffer

add_end:
        add rsp, 20h
        pop rdi
        pop rsi
        pop rbx
        ret
addContact endp

; Функция удаления контакта
deleteContact proc
        push rbx
        push r12
        push rdi
        push rsi
        sub rsp, 20h
        
        lea rcx, deleteContactPrompt
        call printf
        
        ; Проверка на пустую книгу
        mov rax, [contactCount]
        test rax, rax
        jnz not_empty
        
        lea rcx, noContacts
        call printf
        jmp delete_end
        
not_empty:
        ; Ввод имени для удаления
        lea rcx, deleteNamePrompt
        call printf

        lea rcx, nameBuffer
        call gets

        ; Поиск контакта
        xor rbx, rbx  ; индекс текущего контакта
        xor r12, r12  ; флаг найденности

search_loop:
        cmp rbx, [contactCount]
        jge search_end

        GetContactPtr rbx, rax
        lea rcx, [rax].Contact.name_
        lea rdx, nameBuffer
        call strcmp
        test eax, eax
        jz found

        inc rbx
        jmp search_loop

found:
        mov r12, 1

; Сдвигаем контакты влево
shift_loop:
        mov rax, [contactCount]
        dec rax
        cmp rbx, rax
        jge shift_end

        GetContactPtr rbx, rdi      ; Текущий элемент
        mov rsi, rdi
        add rsi, sizeof Contact     ; Следующий элемент

        ; Копируем данные
        mov rcx, sizeof Contact
        rep movsb

        inc rbx
        jmp shift_loop

shift_end:
        ; Уменьшаем счетчик контактов
        dec qword ptr [contactCount]

        lea rcx, contactDeleted
        call printf
        jmp delete_end

search_end:
        test r12, r12
        jnz delete_end

        lea rcx, contactNotFound
        call printf

delete_end:
        ; Очистка буфера
        call clearBuffer
        add rsp, 20h
        pop rsi
        pop rdi
        pop r12
        pop rbx
        ret
deleteContact endp

; Функция просмотра контактов
viewContacts proc
        push rbx
        sub rsp, 20h

        lea rcx, viewContactsTitle
        call printf

        ; Проверка на пустую книгу
        mov rax, [contactCount]
        test rax, rax
        jnz view_loop

        lea rcx, noContacts
        call printf
        jmp view_end

view_loop:
        xor rbx, rbx  ; индекс текущего контакта
    
print_loop:
        cmp rbx, [contactCount]
        jge view_end

        GetContactPtr rbx, rax

        lea rcx, contactFormat
        mov rdx, rbx
        inc rdx  ; нумерация с 1
        lea r8, [rax].Contact.name_
        lea r9, [rax].Contact.phone
        call printf

        inc rbx
        jmp print_loop

view_end:
        lea rcx, newline
        call printf
        add rsp, 20h
        pop rbx
        ret
viewContacts endp

; Функция редактирования контакта
editContact proc
        push rbx
        push r12
        push r13
        push rdi
        push rsi
        sub rsp, 20h

        lea rcx, editContactPrompt
        call printf

        ; Проверка на пустую книгу
        mov rax, [contactCount]
        test rax, rax
        jnz edit_not_empty

        lea rcx, noContacts
        call printf
        jmp edit_end

edit_not_empty:
        ; Ввод имени для редактирования
        lea rcx, deleteNamePrompt
        call printf

        lea rcx, nameBuffer
        call gets

        ; Удаляем пробелы в конце введенного имени
        lea rdi, nameBuffer
        call trimTrailingSpaces

        ; Поиск контакта
        xor rbx, rbx  ; индекс текущего контакта
        xor r12, r12  ; флаг найденности

edit_search_loop:
        cmp rbx, [contactCount]
        jge edit_search_end

        GetContactPtr rbx, rsi

        ; Создаем временную копию имени контакта без пробелов в конце
        lea rdi, phoneBuffer ; временно используем phoneBuffer как буфер
        lea rsi, [rsi].Contact.name_
        mov r13, rsi        ; сохраняем оригинальный указатель

        ; Копируем имя во временный буфер
        mov rcx, MAX_NAME_LEN
        rep movsb

        ; Удаляем пробелы в конце
        lea rdi, phoneBuffer
        call trimTrailingSpaces

        ; Сравниваем с введенным именем (уже без пробелов)
        lea rcx, phoneBuffer
        lea rdx, nameBuffer
        call strcmp
        test eax, eax
        jz edit_found

        inc rbx
        jmp edit_search_loop

edit_found:
        mov r12, 1
        GetContactPtr rbx, rsi ; Получаем указатель на найденный контакт

        ; Ввод нового имени
        lea rcx, newNamePrompt
        call printf

        lea rcx, nameBuffer
        call gets

        ; Удаляем пробелы в конце нового имени
        lea rdi, nameBuffer
        call trimTrailingSpaces

        ; Проверяем, не пустая ли строка
        lea rcx, nameBuffer
        call strlen
        test rax, rax
        jz skip_name_update

        ; Обновляем имя
        lea rdi, [rsi].Contact.name_
        lea rsi, nameBuffer
        mov rcx, MAX_NAME_LEN
        rep movsb
        GetContactPtr rbx, rsi ; Восстанавливаем указатель

skip_name_update:
        ; Ввод нового телефона
        lea rcx, newPhonePrompt
        call printf

        lea rcx, phoneBuffer
        call gets

        ; Проверяем, не пустая ли строка
        lea rcx, phoneBuffer
        call strlen
        test rax, rax
        jz skip_phone_update

        ; Обновляем телефон
        lea rdi, [rsi].Contact.phone
        lea rsi, phoneBuffer
        mov rcx, MAX_PHONE_LEN
        rep movsb
        GetContactPtr rbx, rsi ; Восстанавливаем указатель

skip_phone_update:
        lea rcx, contactEdited
        call printf
        jmp edit_end

edit_search_end:
        test r12, r12
        jnz edit_end

        lea rcx, contactNotFound
        call printf

edit_end:
        ; Очистка буфера
        call clearBuffer
        add rsp, 20h
        pop rsi
        pop rdi
        pop r13
        pop r12
        pop rbx
        ret
editContact endp
END