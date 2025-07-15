; _constants_.inc
option casemap:none
; Константы
MAX_CONTACTS  equ 100
MAX_NAME_LEN  equ 50
MAX_PHONE_LEN equ 20

; Структура контакта
Contact struct
        name_  db MAX_NAME_LEN dup(0)
        phone db MAX_PHONE_LEN dup(0)
Contact ends

; Макрос для безопасного доступа к элементам массива
GetContactPtr macro index, destReg
        lea destReg, contacts
        mov r11, sizeof Contact
        imul r11, index
        add destReg, r11
endm
