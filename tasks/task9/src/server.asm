; ------------------------------------------------------------
; server.asm
; ------------------------------------------------------------        
        include _constants_.inc
        include _extern_.inc

        extern print_error      :proc

        extern sockaddr_in      :SOCKADDR_IN
        extern listen_socket    :qword
        extern client_socket    :qword
        extern startup_msg      :byte
        extern bind_msg         :byte
        extern listen_msg       :byte
        extern connected_msg    :byte
        extern msg_socket_err   :byte
        extern msg_bind_err     :byte
        extern msg_listen_err   :byte
        extern msg_accept_err   :byte
.code
init_server PROC
        sub   rsp, 28h

        ; Создание сокета
        mov   ecx, AF_INET
        mov   edx, SOCK_STREAM
        mov   r8d, IPPROTO_TCP
        call  socket
        cmp   rax, INVALID_SOCKET
        je    socket_fail
        mov   listen_socket, rax

        ; Настройка адреса
        mov   word ptr sockaddr_in.sin_family, AF_INET
        mov   ecx, DEFAULT_PORT
        call  htons
        mov   word ptr sockaddr_in.sin_port, ax
        mov   dword ptr sockaddr_in.sin_addr, 0

        ; Привязка сокета
        mov   rcx, listen_socket
        lea   rdx, sockaddr_in
        mov   r8d, SIZEOF SOCKADDR_IN
        call  bind
        cmp   eax, SOCKET_ERROR
        je    bind_fail

        ; Ожидание подключения
        mov   rcx, listen_socket
        mov   edx, 1
        call  listen
        cmp   eax, SOCKET_ERROR
        je    listen_fail

        ; Вывод сообщений о успешной инициализации
        mov   rdx, DEFAULT_PORT
        lea   rcx, OFFSET startup_msg
        call  printf
        lea   rcx, OFFSET bind_msg
        call  printf
        lea   rcx, OFFSET listen_msg
        call  printf

        ; Принятие подключения
        mov   rcx, listen_socket
        xor   rdx, rdx
        xor   r8, r8
        call  accept
        cmp   rax, INVALID_SOCKET
        je    accept_fail
        mov   client_socket, rax
        lea   rcx, OFFSET connected_msg
        call  printf

        add   rsp, 28h
        ret

socket_fail:
        lea   rcx, msg_socket_err
        call  print_error
        jmp   server_error

bind_fail:
        lea   rcx, msg_bind_err
        call  print_error
        jmp   server_error

listen_fail:
        lea   rcx, msg_listen_err
        call  print_error
        jmp   server_error

accept_fail:
        lea   rcx, msg_accept_err
        call  print_error
        jmp   server_error

server_error:
        mov   rcx, listen_socket
        call  closesocket
        xor   eax, eax
        add   rsp, 28h
        ret
init_server ENDP
END