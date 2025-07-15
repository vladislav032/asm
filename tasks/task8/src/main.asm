; ----------------------------------------------------------------------------
;  multithread_sum.asm ― демонстрация многопоточной обработки с Events
; ----------------------------------------------------------------------------

        include _constants_.inc
        include _extern_.inc

        extern ThreadProc1  :proc
        extern ThreadProc2  :proc

; ----------------------------------------------------------------------------
;  Данные
; ----------------------------------------------------------------------------
.data
align 16
        public array
        public thread1_sum
        public thread2_sum
        public ARRAY_LEN
        public hEvent1
        public hEvent2
        public hThread1
        public hThread2
        public fmt_part

        array       dq  1,2,3,4,5,6,7,8,9,10

        thread1_sum dq 0
        thread2_sum dq 0

        hEvent1     dq 0
        hEvent2     dq 0
        hThread1    dq 0
        hThread2    dq 0

        ; форматные строки (CR/LF = 13,10)
        fmt_part    db "Thread %u partial sum = %lld", 13,10,0
        fmt_total   db "Total sum = %lld", 13,10,0
        fmt_error   db "ERROR %#x", 13,10,0

.code
; ----------------------------------------------------------------------------
;  Точка входа процесса
; ----------------------------------------------------------------------------
main proc
        sub rsp, 48h  

    ;–– 1. СОЗДАЁМ ДВА СОБЫТИЯ (ручной сброс, начальное состояние ― nonsignaled)
        xor  rcx, rcx         ; lpEventAttributes = NULL
        mov  rdx, 1           ; bManualReset      = TRUE
        xor  r8,  r8          ; bInitialState     = FALSE
        xor  r9,  r9          ; lpName            = NULL
        call CreateEventW
        mov  [hEvent1], rax
        test rax, rax
        jnz  evt2_ok
fatal:
        call GetLastError
        lea  rcx, fmt_error
        mov  rdx, rax
        call printf
        jmp  cleanup

evt2_ok:
        xor  rcx, rcx
        mov  rdx, 1
        xor  r8,  r8
        xor  r9,  r9
        call CreateEventW
        mov  [hEvent2], rax
        test rax, rax
        jz   fatal

;–– 2. СТАРТУЕМ ПОТОК-1
start_thr1:
        xor  rcx, rcx                     ; lpThreadAttributes
        xor  rdx, rdx                     ; dwStackSize (0 = по умолч.)
        lea  r8,  ThreadProc1             ; lpStartAddress
        xor  r9,  r9                      ; lpParameter

        ; 5-я и 6-я параметры на стеке (dwCreationFlags, lpThreadId)
        mov  qword ptr [rsp+20h], 0
        mov  qword ptr [rsp+28h], 0

        call CreateThread
        mov  [hThread1], rax
        test rax, rax
        jz   fatal

;–– 3. СТАРТУЕМ ПОТОК-2
start_thr2:
        xor  rcx, rcx
        xor  rdx, rdx
        lea  r8,  ThreadProc2
        xor  r9,  r9

        mov  qword ptr [rsp+20h], 0
        mov  qword ptr [rsp+28h], 0
        call CreateThread
        mov  [hThread2], rax
        test rax, rax
        jz   fatal

;–– 4. ОЖИДАЕМ ОБА СОБЫТИЯ
        ; формируем локальный массив HANDLE'ов на стеке
        mov  rax, [hEvent1]
        mov  [rsp+30h], rax
        mov  rax, [hEvent2]
        mov  [rsp+38h], rax

        mov  ecx, 2                       ; nCount
        lea  rdx, [rsp+30h]               ; lpHandles
        mov  r8d, 1                       ; bWaitAll = TRUE
        mov  r9d, INFINITE                ; таймаут
        call WaitForMultipleObjects
        cmp  eax, WAIT_OBJECT_0
        jb   fatal                        ; WAIT_FAILED или TIMEOUT

;–– 5. СВОДИМ И ПОКАЗЫВАЕМ РЕЗУЛЬТАТ
        mov  rax, [thread1_sum]
        add  rax, [thread2_sum]
        lea  rcx, fmt_total
        mov  rdx, rax
        call printf

;–– 6. ЗАКРЫВАЕМ ДЕСкРИПТОРЫ И ВЫХОДИМ
cleanup:
        ; CloseHandle(hThread1)
        cmp  [hThread1], 0
        je   @F
        mov  rcx, [hThread1]
        call CloseHandle
@@:
        ; CloseHandle(hThread2)
        cmp  [hThread2], 0
        je   @F
        mov  rcx, [hThread2]
        call CloseHandle
@@:
        ; CloseHandle(hEvent1)
        cmp  [hEvent1], 0
        je   @F
        mov  rcx, [hEvent1]
        call CloseHandle
@@:
        ; CloseHandle(hEvent2)
        cmp  [hEvent2], 0
        je   @F
        mov  rcx, [hEvent2]
        call CloseHandle
@@:
        add  rsp, 48h
        xor  ecx, ecx
        call ExitProcess
main endp
END