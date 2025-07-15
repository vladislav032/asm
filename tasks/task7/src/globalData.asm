        
; Глобальные данные
        option casemap:none

        include _constants_.inc
        include _extern_.inc
        include _macros_.inc

.data
        ; Меню и сообщения
        menuHeader      db 10,13,'=== File Selector Menu ===',10,13,0
        menuOption1     db '1. Select and read file',10,13,0
        menuOption2     db '2. Exit',10,13,0
        menuPrompt      db 'Enter your choice: ',0
        selectedFileMsg db 'Selected file: %S',10,13,0
        fileContentMsg  db 10,13,'File content:',10,13,0
        invalidChoice   db 'Invalid choice, try again.',10,13,0
        readErrorMsg    db 'Error reading file',10,13,0
        newLine         db 10,13,0

        ; Для работы с файлом
        fileFilter      dw 'A','l','l',' ','F','i','l','e','s',0,'*','.','*',0,0
        openFileTitle   dw 'S','e','l','e','c','t',' ','a',' ','F','i','l','e',0