; Макрос для вывода строки
print_str MACRO strLabel
    lea     rdx, strLabel
    mov     rcx, rdx
    call    [__imp_lstrlenA]
    mov     rcx, [hStdOut]
    mov     r8,  rax
    lea     r9,  bytesWritten
    mov     qword ptr [rsp+20h], 0
    call    [__imp_WriteConsoleA]
ENDM