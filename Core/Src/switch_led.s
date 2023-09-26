// switch_led.s
// Dave Jansing (taken from https://pygmy.utoh.org/riscy/cortex/led-stm32.html)
// 
// This program is in the public domain, developed under JHU WSE Engineering for Professionals
// program.  The idea is to get the student to initialize and use the GPIO on the 
// STM32WB55RGx board without using the HAL functions.

// Blink the blue LED on the STM32 board

// Directives
    .syntax unified
    .cpu cortex-m4
    .fpu softvfp
	.thumb

.global switchLED

// Equates 
                                        // See RM0434 Tables 1 and 45 for where to get these registers and locations
//	GPIOA (Switch)
    .equ GPIOA_MODER,   0x48000000      // 
    .equ GPIOA_OTYPER,  0x48000004      // 
    .equ GPIOA_PUPDR,   0x4800000C      // 
	.equ GPIOA_IDR,     0x48000410      // GPIOA Input Data Register, 0x10 offset

// GPIOC (breadboard LED)
    .equ GPIOC_MODER,   0x48000800      // 
    .equ GPIOC_OTYPER,  0x48000804      // 
    .equ GPIOC_PUPDR,   0x4800080C      // 
    .equ GPIOC_ODR,     0x48000814      // GPIOC Output Data Register, 0x14 offset
		
// RCC AHB2	
    .equ RCC_AHB2ENR,   0x5800004C      // Location for RCC_AHB2ENR (RM0434) Table 1 (pg 67) and Table 42 (pg 284)
    .equ ENABLE_PORTAC, 0x05            // Bit 0,2 of RCC_ABH2ENR to enable Port A/C
    
	.equ DBDELAY,      100000

.section .text
    .org 0

switchLED: 
    ldr r6, = RCC_AHB2ENR       // Enable the RCC Perh Clock
    ldr r2, [r6]                // RCC_AHB2ENR is 0xF (GPIOA/B/C/D enabled)
    ldr r3, = ENABLE_PORTAC     // r3 = 0x5
    orrs r2, r2, r3             // OR the current state of RCC with the bit to enable Port A/B
    str r2, [r6]                // Store result in RCC_AHB2ENR register to enable

    // GPIOA SETUP (PA15)
    ldr r6, = GPIOA_MODER       // GPIO Port Mode Register
    ldr r2, [r6]                // GPIOA_MODER reset state = 0xABFF FFFF
    mov r3, 0x3FFFFFFF          // Enable pin 15 as input
    ands r2, r2, r3             // r2 = 0x02bf ffff
    str r2, [r6]                // apply setting

    ldr r6, = GPIOA_PUPDR       // Set Pin Type
    ldr r2, [r6]                // GPIOA_PUPDR reset state = 0x6400 0000 
    mov r3, 0x7FFFFFFF          // pull down for Pin 15
    ands r2, r2, r3             // 
    str r2, [r6]                // apply setting
    
    // GPIOC SETUP (PC2)
    ldr r6, = GPIOC_MODER       // GPIO Port Mode Register
    ldr r2, [r6]                // What's the current state
    mov r3, 0x10                // Enable pin 2 as output
    orrs r2, r2, r3             // 
    str r2, [r6]                // apply setting

    ldr r6, = GPIOC_OTYPER      // Set output type
    mov r3, 0x0                 // Force all outputs as push-pull
    str r3, [r6]                // apply setting

    ldr r6, = GPIOC_PUPDR       // Set Pin Type
    str r3, [r6]                // Force all pins to no pull up/pull down

    // Load R2 and R3 with the "on" and "off" constants
    mov r2, 0                	// Value to turn off LED
    mov r3, 0b100            	// Value to turn on LED, target bit 2

    ldr r5, = GPIOA_IDR      	// Point to Port A input data register
    ldr r6, = GPIOC_ODR      	// Point to Port C output data register

ledoff:
    str r2, [r6]            	// turn off LED
    ldr r4, [r5]            	// read GPIOA_IDR
    ands r4, r4, 0x80       	// check if switch is pressed
    bne ledoff              
    ldr r1, = DBDELAY       	// remain pressed for this long
loop:
    ldr r4, [r5]            	// read r5
    ands r4, r4, 0x80       	// check if switch is still pressed
    bne ledoff
debounce:
    subs r1, 1              	// if so, decrement DBDELAY times before turning LED on 
    bne loop
ledon:
    str r3, [r6]            	// turn on LED
    ldr r4, [r5]            	// read r5
    ands r4, r4, 0x80       	// check if switch is pressed
    bne ledoff              	//
    b ledon                 
