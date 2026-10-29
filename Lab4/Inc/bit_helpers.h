// Arduino-style GPIO helpers for the STM32F746G-DISCO (UM1907 Table 3, CN4-CN7)
#ifndef BIT_HELPERS_H
#define BIT_HELPERS_H

#include "stm32f7xx.h"

enum PinMode
{
    INPUT = 0,
    OUTPUT = 1
};

enum DigitalValue
{
    LOW = 0,
    HIGH = 1
};

enum OutputType
{
    PUSH_PULL = 0,
    OPEN_DRAIN = 1
};

enum PullMode
{
    NO_PULL = 0,
    PULL_UP = 1,
    PULL_DOWN = 2
};

enum PinMap
{
    A1 = 0,
    A2 = 1,
    A3 = 2,
    A4 = 3,
    A5 = 4,
    D15 = 5,
    D14 = 6,
    D13 = 7,
    D12 = 8,
    D11 = 9,
    D10 = 10,
    D9 = 11,
    D8 = 12,
    D7 = 13,
    D6 = 14,
    D5 = 15,
    D4 = 16,
    D3 = 17,
    D2 = 18,
    D1 = 19,
    D0 = 20,
    A0 = 21
};

typedef struct
{
    GPIO_TypeDef *port;
    uint32_t clockEnable;
    uint8_t bit;
} PinInfo;

// Indexed by enum PinMap
static const PinInfo pinTable[] = {
    {GPIOF, RCC_AHB1ENR_GPIOFEN, 10}, // A1
    {GPIOF, RCC_AHB1ENR_GPIOFEN, 9},  // A2
    {GPIOF, RCC_AHB1ENR_GPIOFEN, 8},  // A3
    {GPIOF, RCC_AHB1ENR_GPIOFEN, 7},  // A4
    {GPIOF, RCC_AHB1ENR_GPIOFEN, 6},  // A5
    {GPIOB, RCC_AHB1ENR_GPIOBEN, 8},  // D15
    {GPIOB, RCC_AHB1ENR_GPIOBEN, 9},  // D14
    {GPIOI, RCC_AHB1ENR_GPIOIEN, 1},  // D13
    {GPIOB, RCC_AHB1ENR_GPIOBEN, 14}, // D12
    {GPIOB, RCC_AHB1ENR_GPIOBEN, 15}, // D11
    {GPIOI, RCC_AHB1ENR_GPIOIEN, 0},  // D10
    {GPIOA, RCC_AHB1ENR_GPIOAEN, 15}, // D9
    {GPIOI, RCC_AHB1ENR_GPIOIEN, 2},  // D8
    {GPIOI, RCC_AHB1ENR_GPIOIEN, 3},  // D7
    {GPIOH, RCC_AHB1ENR_GPIOHEN, 6},  // D6
    {GPIOA, RCC_AHB1ENR_GPIOAEN, 8},  // D5
    {GPIOG, RCC_AHB1ENR_GPIOGEN, 7},  // D4
    {GPIOB, RCC_AHB1ENR_GPIOBEN, 4},  // D3
    {GPIOG, RCC_AHB1ENR_GPIOGEN, 6},  // D2
    {GPIOC, RCC_AHB1ENR_GPIOCEN, 6},  // D1
    {GPIOC, RCC_AHB1ENR_GPIOCEN, 7},  // D0
    {GPIOA, RCC_AHB1ENR_GPIOAEN, 0},  // A0
};

// Enables the port clock and sets the pin as input (MODER 00) or output (MODER 01)
static inline void pinMode(enum PinMap pin, enum PinMode mode)
{
    const PinInfo *p = &pinTable[pin];

    RCC->AHB1ENR |= p->clockEnable;
    (void)RCC->AHB1ENR; // read back so the clock is active before the next access

    p->port->MODER &= ~(0x3UL << (p->bit * 2));
    if (mode == OUTPUT)
    {
        p->port->MODER |= (0x1UL << (p->bit * 2));
    }
}

// Sets OTYPER: push-pull (0) or open-drain (1); only affects output mode
static inline void pinType(enum PinMap pin, enum OutputType type)
{
    const PinInfo *p = &pinTable[pin];

    RCC->AHB1ENR |= p->clockEnable;
    (void)RCC->AHB1ENR;

    if (type == OPEN_DRAIN)
    {
        p->port->OTYPER |= (1UL << p->bit);
    }
    else
    {
        p->port->OTYPER &= ~(1UL << p->bit);
    }
}

// Sets PUPDR: 00 none, 01 pull-up, 10 pull-down
static inline void pinPull(enum PinMap pin, enum PullMode pull)
{
    const PinInfo *p = &pinTable[pin];

    RCC->AHB1ENR |= p->clockEnable;
    (void)RCC->AHB1ENR;

    p->port->PUPDR &= ~(0x3UL << (p->bit * 2));
    p->port->PUPDR |= ((uint32_t)pull << (p->bit * 2));
}

static inline int digitalRead(enum PinMap pin)
{
    const PinInfo *p = &pinTable[pin];
    return (p->port->IDR >> p->bit) & 0x1;
}

// BSRR low half sets, high half resets; atomic, no read-modify-write
static inline void digitalWrite(enum PinMap pin, enum DigitalValue value)
{
    const PinInfo *p = &pinTable[pin];

    if (value == HIGH)
    {
        p->port->BSRR = (1UL << p->bit);
    }
    else
    {
        p->port->BSRR = (1UL << (p->bit + 16));
    }
}

#endif // BIT_HELPERS_H
