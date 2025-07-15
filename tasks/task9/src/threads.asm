; ------------------------------------------------------------
; threads.asm
; ------------------------------------------------------------            
        include _constants_.inc
        include _extern_.inc

        extern newline_and_prompt   :proc
        extern read_input           :proc
        extern strcmp               :proc

        extern hExitEvent           :qword
        extern client_socket        :qword
        extern bytesRead            :dword
        extern newline              :byte
        extern server_prompt        :byte
        extern client_prompt        :byte
        extern buffer               :byte
        extern program_mode         :byte
        extern quit_str             :byte
.code
; ------------------------------------------------------------
;  Поток приема данных
; ------------------------------------------------------------
RecvThread PROC
        sub   rsp, 28h

recv_loop:
        ; Прием данных
        mov   rcx, client_socket
        lea   rdx, buffer
        mov   r8d, BUF_SIZE-1
        xor   r9d, r9d
        call  recv
        cmp   eax, SOCKET_ERROR
        jle   thread_exit

        ; Подготовка строки
        lea   rdx, buffer
        mov   byte ptr [rdx+rax], 0

        ; Вывод полученного сообщения
        lea   rcx, OFFSET newline
        call  printf

        ; Вывод соответствующего приглашения (Server> или Client>)
        cmp   program_mode, SERVER_MODE
        jne   show_server_prompt
        lea   rcx, OFFSET client_prompt
        jmp   print_recv_msg
show_server_prompt:
        lea   rcx, OFFSET server_prompt
print_recv_msg:
        call  printf
        lea   rcx, buffer
        call  printf

        ; Новая строка и приглашение
        call  newline_and_prompt

        jmp   recv_loop

thread_exit:
        add   rsp, 28h
        ret
RecvThread ENDP

; ------------------------------------------------------------
;  Поток ввода данных с консоли
; ------------------------------------------------------------
InputThread PROC
        sub   rsp, 28h

input_loop:
        ; Вывод правильного приглашения
        cmp   program_mode, SERVER_MODE
        jne   client_input_prompt
        lea   rcx, server_prompt
        jmp   print_input_prompt
client_input_prompt:
        lea   rcx, client_prompt
print_input_prompt:
        call  printf

        ; Чтение ввода
        call  read_input
        test  eax, eax
        jz    input_loop

        ; Проверка на команду выхода
        lea   rcx, buffer
        lea   rdx, quit_str
        call  strcmp
        test  eax, eax
        jz    exit_signal

        ; Отправка сообщения
        mov   rcx, client_socket
        lea   rdx, buffer
        mov   r8d, bytesRead
        xor   r9d, r9d
        call  send
        cmp   eax, SOCKET_ERROR
        je    exit_signal

        jmp   input_loop

exit_signal:
        ; Сигнал о завершении
        mov   rcx, hExitEvent
        call  SetEvent

        add   rsp, 28h
        ret
InputThread ENDP
END