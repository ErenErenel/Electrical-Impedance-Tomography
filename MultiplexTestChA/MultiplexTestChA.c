#include <stdio.h>
#include <ctype.h>
#include <stdint.h>

#include "pico/stdlib.h"
#include "hardware/gpio.h"
#include "pico/stdio_usb.h"

#define A0_GPIO 0
#define A1_GPIO 1
#define A2_GPIO 2
#define A3_GPIO 3

static void mux_init(void) {
    for (int p = 0; p <= 3; p++) {
        gpio_init(p);
        gpio_set_dir(p, GPIO_OUT);
        gpio_put(p, 0);
    }
}

static void mux_select_switch(uint8_t sw) {
    if (sw < 1 || sw > 16) return;

    uint32_t code = (uint32_t)(sw - 1) & 0x0F;
    gpio_put_masked(0x0F, code);
}

static void print_banner(void) {
    printf("\n============================\n");
    printf(" Multiplexer Control Ready\n");
    printf(" Enter switch number 1–16\n");
    printf(" Mapping: switch -> (switch-1)\n");
    printf(" Example: 1 -> 0000, 16 -> 1111\n");
    printf("============================\n\n");
    printf("switch (1-16)> ");
}

int main(void) {
    stdio_init_all();
    mux_init();

    // 🔴 WAIT until USB serial connection is opened
    while (!stdio_usb_connected()) {
        sleep_ms(10);
    }

    // Print banner exactly once on connect
    print_banner();

    int value = 0;
    bool has_digit = false;

    while (true) {
        int ch = getchar_timeout_us(0);

        if (ch == PICO_ERROR_TIMEOUT) {
            tight_loop_contents();
            continue;
        }

        if (ch == '\r' || ch == '\n') {
            printf("\n");

            if (has_digit) {
                if (value >= 1 && value <= 16) {
                    mux_select_switch((uint8_t)value);
                    uint8_t code = (uint8_t)(value - 1);

                    printf("Selected switch %d\n", value);
                    printf("A3A2A1A0 = %u%u%u%u\n",
                           (code >> 3) & 1u,
                           (code >> 2) & 1u,
                           (code >> 1) & 1u,
                           (code >> 0) & 1u);
                } else {
                    printf("Error: enter a number 1–16\n");
                }
            }

            value = 0;
            has_digit = false;
            printf("\nswitch (1-16)> ");
            continue;
        }

        if (isdigit((unsigned char)ch)) {
            value = value * 10 + (ch - '0');
            has_digit = true;
            putchar_raw(ch);  // echo
        }
    }
}
