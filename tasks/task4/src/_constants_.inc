option casemap:none
; Constants
INITIAL_CAPACITY equ 4   ; Initial array capacity
GROW_FACTOR equ 2        ; Array growth factor
MAX_INT equ 2147483647   ; Maximum 32-bit signed integer
MIN_INT equ -2147483648  ; Minimum 32-bit signed integer

; File access constants
GENERIC_READ equ 80000000h
GENERIC_WRITE equ 40000000h
FILE_SHARE_READ equ 1
FILE_SHARE_WRITE equ 2
CREATE_ALWAYS equ 2
OPEN_EXISTING equ 3
FILE_ATTRIBUTE_NORMAL equ 80h