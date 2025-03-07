/* Linker script for CafeOS kernel */
ENTRY(kernel_main)
SECTIONS
{
    /* Ensure the kernel is loaded at right memory address */
    . = 0x1000;
    
    .text : {
        *(.text)
    }
    
    .rodata : {
        *(.rodata)
    }
    
    .data : {
        *(.data)
    }
    
    .bss : {
        *(.bss)
    }
}