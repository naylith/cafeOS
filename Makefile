# Makefile for CafeOS

# Compiler settings
CC = gcc
# Compiler flags: 32-bit, freestanding, no standard library, no warnings, enable debugging
CFLAGS = -m32 -ffreestanding -fno-pie -fno-stack-protector -nostdlib -Wall -Wextra -g

# Assembler
AS = nasm

# Linker settings
LD = ld
LDFLAGS = -m elf_i386

# Directories
BOOT_DIR = boot
KERNEL_DIR = kernel
BUILD_DIR = build

# Output files
KERNEL_BIN = $(BUILD_DIR)/kernel.bin
BOOTLOADER_BIN = $(BUILD_DIR)/bootloader.bin
OS_IMAGE = $(BUILD_DIR)/cafeos.bin

# Source files
KERNEL_SRC = $(KERNEL_DIR)/kernel.c
BOOTLOADER_SRC = $(BOOT_DIR)/boot.asm

# Default target
all: setup $(OS_IMAGE)

# Create build directory
setup:
	mkdir -p $(BUILD_DIR)

# Build the OS image by concatenating bootloader and kernel
$(OS_IMAGE): $(BOOTLOADER_BIN) $(KERNEL_BIN)
	cat $(BOOTLOADER_BIN) $(KERNEL_BIN) > $(OS_IMAGE)
	# Pad the kernel if needed to ensure it's the right size
	truncate -s 10K $(OS_IMAGE)

# Compile the bootloader
$(BOOTLOADER_BIN): $(BOOTLOADER_SRC)
	$(AS) -f bin $(BOOTLOADER_SRC) -o $(BOOTLOADER_BIN)

# Compile the kernel
$(KERNEL_BIN): $(KERNEL_SRC)
	$(CC) $(CFLAGS) -c $(KERNEL_SRC) -o $(BUILD_DIR)/kernel.o
	$(LD) $(LDFLAGS) -T linker.ld $(BUILD_DIR)/kernel.o -o $(BUILD_DIR)/kernel.elf
	objcopy -O binary $(BUILD_DIR)/kernel.elf $(KERNEL_BIN)

# Run the OS in QEMU
run: $(OS_IMAGE)
	qemu-system-i386 -fda $(OS_IMAGE) -display sdl

# Clean up build files
clean:
	rm -rf $(BUILD_DIR)

.PHONY: all setup run clean