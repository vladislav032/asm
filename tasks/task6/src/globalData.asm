        include _constants_.inc
        include _extern_.inc

.data
        newline                 db 0Ah, 0
        ; Сообщения для добавления контакта
        addContactPrompt        db "Add contact",0Ah,0
        namePrompt              db "Enter contact name: ",0
        phonePrompt             db "Enter phone number: ",0
        contactAdded            db "Contact added.",0Ah,0Ah,0
        contactFull             db "Error: phone book is full!",0Ah,0Ah,0

        ; Сообщения для удаления контакта
        deleteContactPrompt     db "Delete contact",0Ah,0
        deleteNamePrompt        db "Enter contact name to delete: ",0
        contactDeleted          db "Contact deleted.",0Ah,0Ah,0
        contactNotFound         db "Error: contact not found!",0Ah,0Ah,0

        ; Сообщения для просмотра контактов
        viewContactsTitle       db "Current contacts list:",0Ah,0
        contactFormat           db "%d. %s - %s",0Ah,0
        noContacts              db "Phone book is empty.",0Ah,0Ah,0

        ; Сообщения для редактирования контакта
        editContactPrompt       db "Edit contact",0Ah,0
        editNamePrompt          db "Enter contact name to edit: ",0
        newNamePrompt           db "Enter new name (leave empty to keep current): ",0
        newPhonePrompt          db "Enter new phone (leave empty to keep current): ",0
        contactEdited           db "Contact updated.",0Ah,0Ah,0

        FILENAME                db "phonebook.dat",0

        loadFormatString        db "%[^-]-%[^\n]",0
        ; Сообщения меню
        menuTitle               db "Phone Book",0Ah,0
        menu1                   db "1. Add contact",0Ah,0
        menu2                   db "2. Delete contact",0Ah,0
        menu3                   db "3. View contacts",0Ah,0
        menu4                   db "4. Edit contact",0Ah,0
        menu5                   db "5. Save to file",0Ah,0
        menu6                   db "6. Load from file",0Ah,0
        menu7                   db "7. Sort contacts",0Ah,0
        menu8                   db "8. Exit",0Ah,0Ah,0
        menuPrompt              db "Choose action: ",0

        sortStartMsg            db "Starting contacts sorting...",0Ah,0
        sortDebugMsg            db "Sorting %d contacts...",0Ah,0
        sortErrorMsg            db "Error: sorting failed!",0Ah,0Ah,0
        sortNothingMsg          db "Nothing to sort (less than 2 contacts).",0Ah,0Ah,0

        ; Сообщения для работы с файлами
        saveSuccess             db "Contacts saved to file.",0Ah,0Ah,0
        loadSuccess             db "Contacts loaded from file.",0Ah,0Ah,0
        fileError               db "Error working with file!",0Ah,0Ah,0

        ; Сообщения для сортировки
        sortSuccess             db "Contacts sorted alphabetically.",0Ah,0Ah,0

        ; Форматы ввода
        inputFormat             db "%d",0
        stringFormat            db "%s-%s",0Ah ,0

        ; Режимы работы с файлом
        fileWriteMode           db "wb",0
        fileReadMode            db "rb",0