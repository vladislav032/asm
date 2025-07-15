option casemap:none

; Константы
STD_OUTPUT_HANDLE equ -11
STD_INPUT_HANDLE  equ -10
NULL equ 0
GENERIC_READ equ 80000000h
FILE_SHARE_READ equ 1
OPEN_EXISTING equ 3
FILE_ATTRIBUTE_NORMAL equ 80h

; Структура для диалогового окна
OPENFILENAMEW STRUCT
    lStructSize       DWORD ?
    hwndOwner         QWORD ?
    hInstance         QWORD ?
    lpstrFilter       QWORD ?
    lpstrCustomFilter QWORD ?
    nMaxCustFilter    DWORD ?
    nFilterIndex      DWORD ?
    lpstrFile         QWORD ?
    nMaxFile          DWORD ?
    lpstrFileTitle    QWORD ?
    nMaxFileTitle     DWORD ?
    lpstrInitialDir   QWORD ?
    lpstrTitle        QWORD ?
    Flags             DWORD ?
    nFileOffset       WORD  ?
    nFileExtension    WORD  ?
    lpstrDefExt       QWORD ?
    lCustData         QWORD ?
    lpfnHook          QWORD ?
    lpTemplateName    QWORD ?
    pvReserved        QWORD ?
    dwReserved        DWORD ?
    FlagsEx           DWORD ?
OPENFILENAMEW ENDS