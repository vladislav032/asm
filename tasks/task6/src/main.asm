; Программа "Телефонная книга" на MASM x64

        include _constants_.inc
        include _extern_.inc
        include globalData.asm

        extern trimTrailingSpaces   :proc
        extern clearBuffer          :proc
        extern saveToFile           :proc
        extern loadFromFile         :proc
        extern addContact           :proc
        extern deleteContact        :proc
        extern viewContacts         :proc
        extern editContact          :proc
        extern sortContacts         :proc

.data
        public nameBuffer
        public phoneBuffer
        public contactCount
        public contacts
        public inputBuffer

        ; Данные программы
        contacts      Contact MAX_CONTACTS dup(<>) 
        contactCount  dq 0

        ; Буферы для ввода
        inputBuffer db 100 dup(0)
        nameBuffer  db MAX_NAME_LEN dup(0)
        phoneBuffer db MAX_PHONE_LEN dup(0)
        emptyString db 0

.code
; Функция вывода меню
printMenu proc
        sub rsp, 28h

        lea rcx, menuTitle
        call printf

        lea rcx, menu1
        call printf

        lea rcx, menu2
        call printf

        lea rcx, menu3
        call printf

        lea rcx, menu4
        call printf

        lea rcx, menu5
        call printf

        lea rcx, menu6
        call printf

        lea rcx, menu7
        call printf

        lea rcx, menu8
        call printf

        lea rcx, menuPrompt
        call printf

        add rsp, 28h
        ret
printMenu endp

; Главная функция
main proc
        sub rsp, 28h
    
main_loop:
        ; Вывод меню
        call printMenu

        ; Ввод выбора
        lea rcx, inputFormat
        lea rdx, inputBuffer
        call scanf

        sub     rsp, 20h             ; shadow-space для getchar
        call    getchar              ; вычитываем '\n'
        add     rsp, 20h

        ; Обработка выбора
        cmp dword ptr [inputBuffer], 1
        je add_case
        cmp dword ptr [inputBuffer], 2
        je delete_case
        cmp dword ptr [inputBuffer], 3
        je view_case
        cmp dword ptr [inputBuffer], 4
        je edit_case
        cmp dword ptr [inputBuffer], 5
        je save_case
        cmp dword ptr [inputBuffer], 6
        je load_case
        cmp dword ptr [inputBuffer], 7
        je sort_case
        cmp dword ptr [inputBuffer], 8
        je exit_case

        ; Некорректный ввод
        jmp main_loop

add_case:
        call addContact
        jmp main_loop

delete_case:
        call deleteContact
        jmp main_loop

view_case:
        call viewContacts
        jmp main_loop

edit_case:
        call editContact
        jmp main_loop

save_case:
        call saveToFile
        jmp main_loop

load_case:
        call loadFromFile
        jmp main_loop

sort_case:
        call sortContacts
        jmp main_loop

exit_case:
        ; Выход из программы
        xor rcx, rcx
        call exit
        
        add rsp, 28h
        ret
main endp

end