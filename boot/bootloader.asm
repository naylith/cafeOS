;
; CafeOS Bootloader
; A cute cafe-themed bootloader for your pixel art OS
;

[BITS 16]                       ; We're working in 16-bit real mode
[ORG 0x7C00]                    ; Standard bootloader origin point

; Initialize segment registers and stack
    xor ax, ax                  ; Clear AX register
    mov ds, ax                  ; Set data segment to 0
    mov es, ax                  ; Set extra segment to 0
    mov ss, ax                  ; Set stack segment to 0
    mov sp, 0x7C00              ; Set stack pointer just below bootloader

; Clear the screen
    mov ah, 0x00                ; Set video mode function
    mov al, 0x03                ; 80x25 text mode
    int 0x10                    ; BIOS video interrupt

; Set text colors using teletype attributes instead of palette
    mov ah, 0x06                ; Scroll function (to clear screen with color)
    mov al, 0                   ; Clear entire screen
    mov bh, 0x17                ; Light gray on blue (more readable cafe colors)
    mov cx, 0                   ; Upper left corner (0,0)
    mov dh, 24                  ; Lower right row (24)
    mov dl, 79                  ; Lower right column (79)
    int 0x10                    ; Call BIOS

; Display welcome message
    mov si, welcome_msg         ; Point SI to our message
    call print_string           ; Call our string printing routine

; Display loading message
    mov si, loading_msg
    call print_string

; Simulate loading with animated dots
    mov cx, 5                   ; Number of dots to animate
    mov si, dot_msg

animate_dots:
    push cx                     ; Save counter
    
    mov ah, 0x0E                ; Teletype output function
    mov al, '.'                 ; Character to print
    mov bh, 0x00                ; Page number
    int 0x10                    ; Print character
    
    ; Delay animation
    mov cx, 0xFFFF
delay_loop:
    loop delay_loop
    
    pop cx                      ; Restore counter
    loop animate_dots           ; Repeat for number of dots
    
; Here is where you would add code to load your kernel
; This simple bootloader doesn't actually load a kernel yet
; You'll need to expand this part as you develop your OS

; Hang the system - in a real bootloader, we would jump to the kernel
    jmp hang                    ; Jump to infinite loop

; Function to print a null-terminated string from SI register
print_string:
    push ax                     ; Save registers we'll modify
    push bx
    
    mov ah, 0x0E                ; BIOS teletype function
    mov bh, 0x00                ; Page number
    mov bl, 0x0F                ; Bright white text for better visibility

.loop:
    lodsb                       ; Load next character from SI into AL
    or al, al                   ; Check if we've reached the end (AL=0)
    jz .done                    ; If AL=0, we're done
    
    int 0x10                    ; Print the character
    jmp .loop                   ; Repeat for next character

.done:
    pop bx                      ; Restore modified registers
    pop ax
    ret                         ; Return to caller

; Infinite loop to hang the system
hang:
    hlt                         ; Halt processor until next interrupt
    jmp hang                    ; Jump back to halt (in case of interrupt)

; Data section
welcome_msg:    db "Welcome to CafeOS!", 0x0D, 0x0A, "Where code is brewed with love!", 0x0D, 0x0A, 0
loading_msg:    db "Preparing your fresh batch of pixels", 0
dot_msg:        db ".", 0

; Boot signature
    times 510-($-$$) db 0       ; Pad with zeros to 510 bytes
    dw 0xAA55                   ; Boot signature at the end of the sector