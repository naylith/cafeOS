/* 
 * kernel.c - Simple CafeOS kernel
 */

// Initialising kernel
void kernel_main() {
    // Video memory address for text mode
    volatile char* video_memory = (volatile char*)0xB8000;
    
    // Clear screen (set to blue background)
    for (int i = 0; i < 80 * 25 * 2; i += 2) {
        video_memory[i] = ' ';         // Space character
        video_memory[i + 1] = 0x1E;    // Blue background, yellow text
    }
    
    // Welcome message
    const char* msg = "CafeOS Kernel is now brewing!";
    
    // Print message at row 2, column 20
    int offset = (2 * 80 + 20) * 2;
    for (int i = 0; msg[i] != '\0'; i++) {
        video_memory[offset + i * 2] = msg[i];     // Character
        video_memory[offset + i * 2 + 1] = 0x1F;   // Attribute: bright white on blue
    }
    
    // Hang indefinitely
    while(1) {}
}