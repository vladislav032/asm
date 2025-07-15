; ------------------------------------------------------------
; utils.asm
; ------------------------------------------------------------
        include _constants_.inc
        include _extern_.inc

        extern input_handle     :qword
        extern bytesRead        :dword
        extern newline          :byte
        extern server_prompt    :byte
        extern client_prompt    :byte
        extern buffer           :byte
        extern program_mode     :byte
        extern error_fmt        :byte

.code
; ------------------------------------------------------------
;  void print_error(char* msg)
; ------------------------------------------------------------
print_error PROC
        sub   rsp, 28h
        mov   rdx, rcx
        lea   rcx, OFFSET error_fmt
        call  printf
        add   rsp, 28h
        ret
print_error ENDP

; ------------------------------------------------------------
;  DWORD read_input() - читает ввод в buffer, удаляет CR/LF
; ------------------------------------------------------------
read_input PROC
        sub   rsp, 40h
        mov   rcx, input_handle
        lea   rdx, buffer
        mov   r8d, BUF_SIZE-1
        lea   r9, bytesRead
        mov   qword ptr [rsp+20h], 0
        call  ReadConsoleA
        test  eax, eax
        jz    short ri_fail

        mov   eax, bytesRead
        cmp   eax, 2
        jl    short ri_done
        lea   rdx, buffer
        mov   byte ptr [rdx+rax-2], 0
        sub   eax, 2
        mov   bytesRead, eax
ri_done:
        mov   eax, bytesRead
        add   rsp, 40h
        ret
ri_fail:
        xor   eax, eax
        add   rsp, 40h
        ret
read_input ENDP

; ------------------------------------------------------------
;  int strcmp(char* a, char* b) (0 = equal)
; ------------------------------------------------------------
strcmp PROC
        push  rsi
        push  rdi
        mov   rsi, rcx
        mov   rdi, rdx
cmp_loop:
        mov   al, [rsi]
        cmp   al, [rdi]
        jne   not_equal
        test  al, al
        jz    equal
        inc   rsi
        inc   rdi
        jmp   cmp_loop
not_equal:
        mov   eax, 1
        jmp   cmp_exit
equal:
        xor   eax, eax
cmp_exit:
        pop   rdi
        pop   rsi
        ret
strcmp ENDP

; ------------------------------------------------------------
;  Вывод новой строки и приглашения
; ------------------------------------------------------------
newline_and_prompt PROC
        sub     rsp, 28h

        lea     rcx, OFFSET newline
        call    printf
        
        cmp     program_mode, SERVER_MODE
        jne     client_prompt_out
        lea     rcx, OFFSET server_prompt
        jmp     print_prompt
client_prompt_out:
        lea     rcx, OFFSET client_prompt
print_prompt:
        call    printf

        add     rsp, 28h
        ret
newline_and_prompt ENDP
END