; ------------------------------------------------------------
; Async Tcp-chat (x64, MinGW-w64) - сервер или клиент
; Запуск: chat.exe s (сервер) или chat.exe c (клиент)
; ------------------------------------------------------------
        include _constants_.inc
        include _extern_.inc

        extern newline_and_prompt   :proc
        extern read_input           :proc
        extern strcmp               :proc
        extern print_error          :proc
        extern init_server          :proc
        extern init_client          :proc
        extern RecvThread           :proc
        extern InputThread          :proc
        
; ---------- Данные ----------
.data
;--------------------------------------------------
        public newline
        public server_prompt
        public client_prompt
        public error_fmt
        public sockaddr_in
        public startup_msg
        public bind_msg
        public msg_bind_err
        public msg_listen_err
        public msg_accept_err
        public listen_msg
        public connected_msg
        public msg_socket_err
        public server_ip
        public connecting_msg
        public msg_connect_err
        public quit_str
;--------------------------------------------------

        newline           db 0Dh,0Ah,0
        wsaData           db 408 DUP(?)
        sockaddr_in       SOCKADDR_IN {}

        server_ip         db "127.0.0.1",0
        startup_msg       db "Server started on port %d",0Dh,0Ah,0
        bind_msg          db "Socket bound.",0Dh,0Ah,0
        listen_msg        db "Waiting for client...",0Dh,0Ah,0
        connecting_msg    db "Connecting to server...",0Dh,0Ah,0
        connected_msg     db "Connected.",0Dh,0Ah,0
        disconnect_msg    db "Disconnected.",0Dh,0Ah,0
        usage_msg         db "Usage: chat.exe s (server) or chat.exe c (client)",0Dh,0Ah,0

        server_prompt     db "Server> ",0
        client_prompt     db "Client> ",0

        error_fmt         db "Error: %s",0Dh,0Ah,0
        msg_wsa_err       db "WSAStartup failed",0
        msg_socket_err    db "socket() failed",0
        msg_bind_err      db "bind() failed",0
        msg_listen_err    db "listen() failed",0
        msg_connect_err   db "connect() failed",0
        msg_accept_err    db "accept() failed",0
        msg_send_err      db "send() failed",0
        msg_recv_err      db "recv() failed",0
        msg_thread_err    db "thread creation failed",0
        quit_str          db "quit",0

; ---------- Неинициализированные данные ----------
.data?
;--------------------------------------------------
        public buffer
        public input_handle
        public bytesRead
        public program_mode
        public listen_socket
        public client_socket
        public hExitEvent
;--------------------------------------------------
        listen_socket     dq ?
        client_socket     dq ?
        buffer            db BUF_SIZE DUP(?)
        bytesRead         dd ?
        input_handle      dq ?
        output_handle     dq ?
        hRecvThread       dq ?
        hInputThread      dq ?
        hExitEvent        dq ?
        program_mode      db ? ; 's' или 'c'

; ---------- Код ----------
.code
; ------------------------------------------------------------
;  Парсинг аргументов командной строки
; ------------------------------------------------------------
parse_args PROC
        sub   rsp, 38h
        
        ; Получаем командную строку
        call  GetCommandLineW
        mov   rcx, rax
        ; Преобразуем в массив аргументов
        lea   rdx, [rsp+20h]
        call  CommandLineToArgvW
        test  rax, rax
        jz    parse_error
        
        mov   rsi, rax        ; сохраняем указатель на массив аргументов
        mov   rax, [rsi+8]    ; второй аргумент (первый - имя программы)
        test  rax, rax
        jz    parse_error
        
        ; Проверяем первый символ аргумента
        movzx eax, word ptr [rax]
        ; Преобразуем в нижний регистр для сравнения
        or    ax, 20h         ; преобразуем в нижний регистр
        
        cmp   ax, 's'
        je    set_server
        cmp   ax, 'c'
        je    set_client
        jmp   parse_error

set_server:
        mov   program_mode, SERVER_MODE
        jmp   parse_success
set_client:
        mov   program_mode, CLIENT_MODE

parse_success:
        ; Освобождаем память, выделенную CommandLineToArgvW
        mov   rcx, rsi
        call  LocalFree
        mov   eax, 1          ; успех
        add   rsp, 38h
        ret

parse_error:
        lea   rcx, OFFSET usage_msg
        call  printf
        xor   eax, eax        ; ошибка
        add   rsp, 38h
        ret
parse_args ENDP

; ------------------------------------------------------------
;  main
; ------------------------------------------------------------
main PROC
        sub   rsp, 48h

        ; Парсинг аргументов командной строки
        call  parse_args
        test  eax, eax
        jz    exit_program

        ; Инициализация handles консоли
        mov   ecx, STD_INPUT_HANDLE
        call  GetStdHandle
        mov   input_handle, rax
        mov   ecx, STD_OUTPUT_HANDLE
        call  GetStdHandle
        mov   output_handle, rax

        ; Инициализация Winsock
        mov   rcx, 202h
        lea   rdx, wsaData
        call  WSAStartup
        test  eax, eax
        jnz   wsa_fail

        ; Инициализация сервера или клиента
        cmp   program_mode, SERVER_MODE
        jne   init_as_client
        call  init_server
        jmp   init_done
init_as_client:
        call  init_client
init_done:
        test  eax, eax
        jz    cleanup

        ; Создание события для выхода
        xor   rcx, rcx
        xor   rdx, rdx
        xor   r8, r8
        xor   r9, r9
        call  CreateEventA
        mov   hExitEvent, rax

        ; Создание потока для приема данных
        xor   rcx, rcx
        xor   rdx, rdx
        lea   r8, RecvThread
        xor   r9, r9
        mov   qword ptr [rsp+20h], 0
        mov   qword ptr [rsp+28h], 0
        call  CreateThread
        mov   hRecvThread, rax
        test  rax, rax
        jz    thread_fail

        ; Создание потока для ввода данных
        xor   rcx, rcx
        xor   rdx, rdx
        lea   r8, InputThread
        xor   r9, r9
        mov   qword ptr [rsp+20h], 0
        mov   qword ptr [rsp+28h], 0
        call  CreateThread
        mov   hInputThread, rax
        test  rax, rax
        jz    thread_fail

        ; Ожидание события выхода
        mov   rcx, hExitEvent
        mov   edx, INFINITE
        call  WaitForSingleObject

        ; Завершение работы
        mov   rcx, client_socket
        call  closesocket
        
        cmp   program_mode, SERVER_MODE
        jne   cleanup_client
        mov   rcx, listen_socket
        call  closesocket
        
cleanup_client:
        lea   rcx, OFFSET disconnect_msg
        call  printf
        
        call  WSACleanup
        xor   ecx, ecx
        jmp   exit_program

; Обработчики ошибок
thread_fail:
        lea   rcx, msg_thread_err
        call  print_error
        jmp   cleanup

wsa_fail:
        lea   rcx, msg_wsa_err
        call  print_error

cleanup:
        mov   rcx, client_socket
        cmp   rcx, 0
        je    no_close
        call  closesocket
no_close:
        cmp   program_mode, SERVER_MODE
        jne   no_listen_close
        mov   rcx, listen_socket
        call  closesocket
no_listen_close:
        call  WSACleanup
        mov   ecx, 1

exit_program:
        call  ExitProcess
main ENDP
END