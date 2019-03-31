#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include "term.h"
#include "string.h"

size_t terminal_row;
size_t terminal_column;
uint8_t terminal_color;
uint16_t* terminal_buffer;
size_t TERM_WIDTH = 80;
size_t TERM_HEIGHT = 25;

void terminal_initialize(uint32_t width, uint32_t height)
{
	terminal_row = 0;
	terminal_column = 0;
	terminal_color = vga_entry_color(VGA_COLOR_LIGHT_GREY, VGA_COLOR_BLACK);
	terminal_buffer = (uint16_t*) 0xB8000;
	TERM_WIDTH = width;
	TERM_HEIGHT = height;
	for (size_t y = 0; y < height; y++) {
		for (size_t x = 0; x < width; x++) {
			const size_t index = y * width + x;
			terminal_buffer[index] = vga_entry(' ', terminal_color);
		}
	}
}

void terminal_setcolor(uint8_t color)
{
	terminal_color = color;
}

void terminal_putentryat(char c, uint8_t color, size_t x, size_t y)
{
	const size_t index = y * TERM_WIDTH + x;
	terminal_buffer[index] = vga_entry(c, color);
}

void terminal_putchar(char c)
{
	terminal_putentryat(c, terminal_color, terminal_column, terminal_row);
	if (++terminal_column == TERM_WIDTH) {
		terminal_column = 0;
		if (++terminal_row == TERM_HEIGHT)
			terminal_row = 0;
	}
}

void terminal_write(const char* data, size_t size)
{
	for (size_t i = 0; i < size; i++)
		terminal_putchar(data[i]);
}

void terminal_writestring(const char* data)
{
	terminal_write(data, strlen(data));
}
