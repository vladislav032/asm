extrn printf        : proc
extrn scanf         : proc
extrn exit          : proc
extrn malloc        : proc
extrn free          : proc
extrn realloc       : proc
extrn memset        : proc
extrn memmove       : proc

; WinAPI functions
extrn CreateFileA   : proc
extrn ReadFile      : proc
extrn WriteFile     : proc
extrn CloseHandle   : proc
extrn GetLastError  : proc
extrn SetFilePointer: proc

; C runtime functions
extrn sprintf       : proc
extrn sscanf        : proc
