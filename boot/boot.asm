; boot.asm - Enhanced bootloader for CafeOS

[BITS 16]                       ; 16-bit real mode
[ORG 0x7C00]                    ; Standard bootloader origin point

KERNEL_OFFSET equ 0x1000        ; Memory offset kernel is loaded

; Initialize segment registers and stack
    xor ax, ax                  ; Clear AX register
    mov ds, ax                  ; Set data segment to 0
    mov es, ax                  ; Set extra segment to 0
    mov ss, ax                  ; Set stack segment to 0
    mov sp, 0x7C00              ; Set stack pointer just below bootloader

; Save boot drive number
    mov [BOOT_DRIVE], dl        ; BIOS stores boot drive in DL

; Clear the screen
    mov ah, 0x06                ; Scroll function (to clear screen with color)
    mov al, 0                   ; Clear entire screen
    mov bh, 0x17                ; Light gray on blue (cafe colors)
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

; Load the kernel
    mov si, load_kernel_msg
    call print_string
    
    mov bx, KERNEL_OFFSET       ; Destination address for kernel
    mov dh, 15                  ; Number of sectors to load (adjust as needed)
    mov dl, [BOOT_DRIVE]        ; Drive to read from
    call disk_load              ; Call disk load function
    
    mov si, done_loading_msg
    call print_string

; Switch to 32-bit protected mode
    call switch_to_pm           ; This won't return

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

; Function to load sectors from disk
; bx = destination address, dh = number of sectors, dl = drive number
disk_load:
    push ax
    push cx
    push dx
    
    mov ah, 0x02                ; BIOS read sector function
    mov al, dh                  ; Number of sectors to read
    mov ch, 0                   ; Cylinder 0
    mov dh, 0                   ; Head 0
    mov cl, 2                   ; Start from sector 2 (sector after boot sector)
    int 0x13                    ; BIOS interrupt for disk functions
    
    jc disk_error               ; If carry flag is set, there was an error
    
    pop dx
    cmp dh, al                  ; Compare number of sectors requested with number read
    jne disk_error              ; If they don't match, error
    
    pop cx
    pop ax
    ret

disk_error:
    mov si, disk_error_msg
    call print_string
    jmp $                       ; Hang

; GDT setup for protected mode
gdt_start:

gdt_null:                       ; Mandatory null descriptor
    dd 0x0                      ; 4 bytes of zeros
    dd 0x0

gdt_code:                       ; Code segment descriptor
    dw 0xffff                   ; Limit (bits 0-15)
    dw 0x0                      ; Base (bits 0-15)
    db 0x0                      ; Base (bits 16-23)
    db 10011010b                ; 1st flags, type flags
    db 11001111b                ; 2nd flags, Limit (bits 16-19)
    db 0x0                      ; Base (bits 24-31)

gdt_data:                       ; Data segment descriptor
    dw 0xffff                   ; Limit (bits 0-15)
    dw 0x0                      ; Base (bits 0-15)
    db 0x0                      ; Base (bits 16-23)
    db 10010010b                ; 1st flags, type flags
    db 11001111b                ; 2nd flags, Limit (bits 16-19)
    db 0x0                      ; Base (bits 24-31)

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1  ; Size of GDT
    dd gdt_start                ; Start address of GDT

; Define constants for GDT segment descriptor offsets
CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

; Function to switch to protected mode
switch_to_pm:
    cli                         ; Disable interrupts
    
    ; Load GDT
    lgdt [gdt_descriptor]       ; Load the GDT descriptor
    
    ; Set PE bit in CR0
    mov eax, cr0
    or eax, 0x1                 ; Set bit 0 to enter protected mode
    mov cr0, eax
    
    ; Far jump to 32-bit code
    jmp CODE_SEG:init_pm        ; Far jump to flush the pipeline

[BITS 32]                       ; We're now in 32-bit mode
init_pm:
    ; Initialize segment registers
    mov ax, DATA_SEG            ; Update segment registers
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    
    ; Set up stack
    mov ebp, 0x90000            ; New stack base
    mov esp, ebp
    
    ; Jump to the kernel
    call KERNEL_OFFSET          ; Jump to our loaded kernel
    
    ; We shouldn't reach here, but just in case...
    jmp $                       ; Hang

[BITS 16]                       ; Back to 16-bit mode for the rest of the bootloader

; Data section
BOOT_DRIVE:      db 0
welcome_msg:     db "Welcome to CafeOS!", 0x0D, 0x0A, "Where code is brewed with love!", 0x0D, 0x0A, 0
loading_msg:     db "Preparing your fresh batch of pixels...", 0x0D, 0x0A, 0
load_kernel_msg: db "Loading kernel...", 0x0D, 0x0A, 0
done_loading_msg:db "Kernel loaded, switching to protected mode...", 0x0D, 0x0A, 0
disk_error_msg:  db "Error loading kernel from disk!", 0x0D, 0x0A, 0

; Boot signature
    times 510-($-$$) db 0       ; Pad with zeros to 510 bytes
    dw 0xAA55                   ; Boot signature at the end of the sector