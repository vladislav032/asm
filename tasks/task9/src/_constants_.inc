; _constants_.inc
option casemap:none

; Константы Windows
STD_INPUT_HANDLE   equ -10
STD_OUTPUT_HANDLE  equ -11
INFINITE           equ 0FFFFFFFFh

; Константы сокетов
AF_INET            equ 2
SOCK_STREAM        equ 1
IPPROTO_TCP        equ 6
INVALID_SOCKET     equ -1
SOCKET_ERROR       equ -1

; Размеры буферов
BUF_SIZE           equ 1024

; Режимы работы
SERVER_MODE        equ 's'
CLIENT_MODE        equ 'c'
DEFAULT_PORT       equ 1234

; Структуры
SOCKADDR_IN STRUCT
    sin_family WORD  ?
    sin_port   WORD  ?
    sin_addr   DWORD ?
    sin_zero   BYTE  8 DUP(?)
SOCKADDR_IN ENDS