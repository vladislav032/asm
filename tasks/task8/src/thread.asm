        include _constants_.inc
        include _extern_.inc

        extern array        :qword
        extern thread1_sum  :qword
        extern thread2_sum  :qword
        extern hEvent1      :qword
        extern hEvent2      :qword
        extern hEvent2      :qword
        extern fmt_part     :byte
.code
; ----------------------------------------------------------------------------
;  Поток-1 ― суммирует первую половину массива
; ----------------------------------------------------------------------------
ThreadProc1 proc
        ; сохраняем RBX, тк он non-volatile
        push rbx
        sub  rsp, 20h                     ; shadow space

        lea  rbx, array                   ; база массива в RBX
        xor  rcx, rcx                     ; индекс
        xor  rax, rax                     ; аккумулятор
        mov  r8, ARRAY_LEN
        shr  r8, 1                        ; половина длины

sum_loop1:
        cmp  rcx, r8
        jge  done1
        add  rax, [rbx + rcx*8]
        inc  rcx
        jmp  sum_loop1

done1:
        mov  [thread1_sum], rax           ; сохранили частичную сумму

        ; выводим диагностическое сообщение
        lea  rcx, fmt_part                ; RCX = fmt
        mov  edx, 1                       ; RDX = номер потока
        mov  r8,  rax                     ; R8  = сумма
        call printf

        ; сигнализируем событие
        mov  rcx, [hEvent1]
        call SetEvent

        add  rsp, 20h
        pop  rbx
        xor  eax, eax                     ; код выхода потока = 0
        ret
ThreadProc1 endp

; ----------------------------------------------------------------------------
;  Поток-2 ― суммирует вторую половину массива
; ----------------------------------------------------------------------------
ThreadProc2 proc
        push rbx
        sub  rsp, 20h

        lea  rbx, array

        mov  rcx, ARRAY_LEN
        shr  rcx, 1                       ; старт = середина
        xor  rax, rax

sum_loop2:
        cmp  rcx, ARRAY_LEN
        jge  done2
        add  rax, [rbx + rcx*8]
        inc  rcx
        jmp  sum_loop2

done2:
        mov  [thread2_sum], rax

        lea  rcx, fmt_part
        mov  edx, 2                       ; номер потока
        mov  r8,  rax
        call printf

        mov  rcx, [hEvent2]
        call SetEvent

        add  rsp, 20h
        pop  rbx
        xor  eax, eax
        ret
ThreadProc2 endp
END