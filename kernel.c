#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include "term/term.h"
#include "lib/math.h"
#include "lib/string.h"
#include "lib/printf/printf.h"

/* Check if the compiler thinks you are targeting the wrong operating system. */
#if defined(__linux__)
#error "You are not using a cross-compiler, you will most certainly run into trouble"
#endif

/* This tutorial will only work for the 32-bit ix86 targets. */
#if !defined(__i386__)
//#error "This tutorial needs to be compiled with a ix86-elf compiler"
#endif

static const size_t VGA_WIDTH = 1024;
static const size_t VGA_HEIGHT = 640;

void kernel_main(void)
{
	/* Initialize terminal interface */
	terminal_initialize(VGA_HEIGHT, VGA_WIDTH);

	/* Newline support is left as an exercise. */
	terminal_writestring("Hello, kernel World!\n");
	printf("\nTest\n");
}
