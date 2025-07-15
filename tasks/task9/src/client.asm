; ------------------------------------------------------------
; client.asm
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
        extern server_ip        :byte
        extern connecting_msg   :byte
        extern msg_connect_err  :byte

.code
; ------------------------------------------------------------
;  Инициализация клиента
; ------------------------------------------------------------
init_client PROC
        sub   rsp, 28h

        ; Создание сокета
        mov   ecx, AF_INET
        mov   edx, SOCK_STREAM
        mov   r8d, IPPROTO_TCP
        call  socket
        cmp   rax, INVALID_SOCKET
        je    client_socket_fail
        mov   client_socket, rax

        ; Настройка адреса сервера
        mov   word ptr sockaddr_in.sin_family, AF_INET
        mov   ecx, DEFAULT_PORT
        call  htons
        mov   word ptr sockaddr_in.sin_port, ax
        
        lea   rcx, server_ip
        call  inet_addr
        mov   sockaddr_in.sin_addr, eax

        ; Подключение к серверу
        lea   rcx, OFFSET connecting_msg
        call  printf
        
        mov   rcx, client_socket
        lea   rdx, sockaddr_in
        mov   r8d, SIZEOF SOCKADDR_IN
        call  connect
        cmp   eax, SOCKET_ERROR
        je    client_connect_fail
        
        lea   rcx, OFFSET connected_msg
        call  printf

        add   rsp, 28h
        ret

client_socket_fail:
        lea   rcx, msg_socket_err
        call  print_error
        jmp   client_error

client_connect_fail:
        lea   rcx, msg_connect_err
        call  print_error
        jmp   client_error

client_error:
        mov   rcx, client_socket
        call  closesocket
        xor   eax, eax
        add   rsp, 28h
        ret
init_client ENDP
END