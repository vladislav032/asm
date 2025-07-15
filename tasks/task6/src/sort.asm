include _constants_.inc
include _extern_.inc
include globalData.asm
extern contactCount:qword
extern contacts:Contact
.code

compareContacts proc
    push rbx
    sub rsp, 20h

    ; rcx и rdx уже указывают на элементы Contact напрямую!
    lea rcx, [rcx].Contact.name_
    lea rdx, [rdx].Contact.name_
    call strcmp             ; сравниваем имена

    add rsp, 20h
    pop rbx
    ret
compareContacts endp

; Функция сортировки контактов по имени (с защитой от ошибок)
sortContacts proc
    push rbx
    sub rsp, 28h

    mov rax, [contactCount]
    cmp rax, 2
    jl sort_nothing

    lea rcx, sortStartMsg
    call printf

    ; параметры qsort
    lea rcx, contacts           ; указатель на массив контактов
    mov rdx, [contactCount]     ; количество элементов
    mov r8, sizeof Contact      ; размер одного элемента
    lea r9, compareContacts     ; функция сравнения
    call qsort

    lea rcx, sortSuccess
    call printf
    jmp sort_done

sort_nothing:
    lea rcx, sortNothingMsg
    call printf

sort_done:
    add rsp, 28h
    pop rbx
    ret
sortContacts endp
END