.syntax unified
.cpu cortex-m7
.thumb
 
// Register addresses and bit positions match the STM32F746 CMSIS definitions.
.equ RCC_BASE,        0x40023800
.equ GPIOA_BASE,      0x40020000
.equ GPIOF_BASE,      0x40021400
.equ RCC_AHB1ENR,     0x30
.equ GPIO_MODER,      0x00
.equ GPIO_ODR,        0x14
.equ RCC_GPIOAEN,     (1 << 0)
.equ RCC_GPIOFEN,     (1 << 5)
.equ GPIOA_PIN0_OUT,  (1 << 0)
.equ GPIOA_PIN0_MODE, 0x3
.equ GPIOA_PIN0,      (1 << 0)
.equ GPIOF_PIN10_OUT, (1 << 20)
.equ GPIOF_PIN10_MODE, (3 << 20)
.equ GPIOF_PIN10,     (1 << 10)
 
.section .data
.align 2
SRAM_NUMBER:
    //10 test words for comparison
    .word 0x00000080            // Data memory test target value (128)
    .word 0x54893489
    .word 0x208f0923
    .word 0x869AE392
    .word 0xAAFFE012
    .word 0xA8026EBB
    .word 0x87877878
    .word 0xF1455423
    .word 0xB87845FE
    .word 0xA0909CCD
.section .text
.global compare_LED
.global LOOP_PROGRAM
.align 2
.thumb_func
 
compare_LED:
    PUSH {R4-R8, LR}

    // Enable the GPIOA and GPIOF peripheral clocks.
    LDR R0, =RCC_BASE
    LDR R1, [R0, #RCC_AHB1ENR]
    ORR R1, R1, #RCC_GPIOAEN
    ORR R1, R1, #RCC_GPIOFEN
    STR R1, [R0, #RCC_AHB1ENR]
 
    // Configure PA0 and PF10 as general-purpose outputs.
    LDR R0, =GPIOA_BASE
    LDR R1, [R0, #GPIO_MODER]
    BIC R1, R1, #GPIOA_PIN0_MODE
    ORR R1, R1, #GPIOA_PIN0_OUT
    STR R1, [R0, #GPIO_MODER]
    LDR R0, =GPIOF_BASE
    LDR R1, [R0, #GPIO_MODER]
    BIC R1, R1, #GPIOF_PIN10_MODE
    ORR R1, R1, #GPIOF_PIN10_OUT
    STR R1, [R0, #GPIO_MODER]

    // Scan both ten-word lists and keep the largest signed value.
    LDR R5, =SRAM_NUMBER            //load sram address into memory
    LDR R6, =FLASH_NUMBER           //load flash address into memory
    LDR R7, [R5], #4                //load sram value into memory
    LDR R8, [R6], #4                //load flash value into memory
    CMP R8, R7                      //set flags for compare
    BLE UPDATE_MAX
    MOV R7, R8                      //set max value register
UPDATE_MAX:
    MOV R4, #9                      //set counter to 9
LOOP_COMPARE:                       //then enter a loop
    LDR R8, [R5], #4                //load a new SRAM value
    CMP R8, R7                      //set flags for Flash-SRAM compare
    BGT UPDATE_MAX_SRAM             //update sram value if needed
    
CHECK_FLASH:                        //otherwise jump to flash section
    LDR R8, [R6], #4                //load a new Flash value
    CMP R8, R7                      //set flags for Flash-SRAM compare
    BGT UPDATE_MAX_FLASH            //update max if needed
    
NEXT_VALUE:                         //else jump to the loop again
    SUBS R4, R4, #1                 //decrement counter value
    BNE LOOP_COMPARE                //loop again if necessary
    CMP R7, #0                      //compare the greatest value to zero
    BLT LEDY_ON                     //if less than, turn on yellow led
    BGT LEDR_ON                     //if greater than, turn on red led
    B LED_OFF
 
LEDY_ON:
    LDR R0, =GPIOF_BASE             //turn yellow LED on
    LDR R1, [R0, #GPIO_ODR]
    BIC R1, R1, #GPIOF_PIN10
    STR R1, [R0, #GPIO_ODR]
    B COMPARE_DONE

LEDR_ON:
    LDR R0, =GPIOA_BASE            //turn red
    LDR R1, [R0, #GPIO_ODR]
    BIC R1, R1, #GPIOA_PIN0
    STR R1, [R0, #GPIO_ODR]
    B COMPARE_DONE

LED_OFF:
    LDR R0, =GPIOA_BASE
    LDR R1, [R0, #GPIO_ODR]
    BIC R1, R1, #GPIOA_PIN0
    STR R1, [R0, #GPIO_ODR]
    LDR R0, =GPIOF_BASE
    LDR R1, [R0, #GPIO_ODR]
    BIC R1, R1, #GPIOF_PIN10
    STR R1, [R0, #GPIO_ODR]
    B COMPARE_DONE

UPDATE_MAX_SRAM:
    MOV R7, R8
    B CHECK_FLASH

UPDATE_MAX_FLASH:
    MOV R7, R8
    B NEXT_VALUE

COMPARE_DONE:
    POP {R4-R8, PC}

.thumb_func
LOOP_PROGRAM:
    // init vars from input struct
    // R9 as temp

    LDR R4, [R0]     //i
    LDR R5, [R0, 4]  //j
    LDR R6, [R0, 8]  //k
    LDR R7, [R0, 12] //a
    LDR R8, [R0, 16] //b


    //asm while i > j loop
    WHILE_LOOP:
    LSL     R9, R5, #1 //2*j
    SUB     R9, R7, R9 //a-2*j
    ADD     R4, R4, R9 //i=i+a-2*j
    IF_LOOP:
    ADD     R4, R4, #2 //i=i+2
    LSL     R9, R5, #1 //2*j
    ADD     R9, R8, R9 //b+2*j
    SUB     R6, R6, R9 //k=k-b+2*j
    CMP     R5, R6
    BGE     IF_LOOP
    ADD R5, #1         //j++
    CMP     R4, R5
    BGT     WHILE_LOOP
    //now just move i,j,k,a,b to return registers
    STR R4, [R0]
    STR R5, [R0, 4]
    STR R6, [R0, 8]
    STR R7, [R0, 12]
    STR R8, [R0, 16]

    BX LR

.align 2
FLASH_NUMBER:
.word 0x00000042 // Code memory threshold reference value (66)
.word 0x00433039
.word 0x92371110
.word 0xA4772221
.word 0x88354539
.word 0x68782114
.word 0x48558583
.word 0x72749910
.word 0x000F4855
.word 0xEEED26F9