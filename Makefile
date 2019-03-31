TOOLCHAIN=i386-elf
CC=$(HOME)/cross-32/bin/$(TOOLCHAIN)-gcc
LD=$(HOME)/cross-32/bin/$(TOOLCHAIN)-gcc
CPP=$(HOME)/cross-32/bin/$(TOOLCHAIN)-cpp
AS=$(HOME)/cross-32/bin/$(TOOLCHAIN)-as

CFLAGS=-I. -Iterm -Ilib -I$(HOME)/cross-32/include -std=gnu99 -ffreestanding -O2 -Wall -Wextra
LDFLAGS=-T linker.ld -ffreestanding -O2 -nostdlib -lgcc

TARGET=kernel.bin

assrc=  $(wildcard *.s) 
csrc =  $(wildcard *.c) \
	$(wildcard lib/printf/*.c) \
	$(wildcard lib/*.c) \
	$(wildcard term/*.c)
obj = $(assrc:.s=.o) $(csrc:.c=.o) $(ccsrc:.cc=.o)

.PHONY: all
all: clean $(TARGET)

.PHONY: clean
clean:
	rm -f $(obj)

%.o: %.s
	$(AS) $(ASFLAGS) -o $@ $<

%.o: %.c
	$(CC) $(CFLAGS) -o $@ -c $<

$(TARGET): $(obj)
#$(CC) -o $@ -c $^ $(CFLAGS)
	$(LD) $(LDFLAGS) -o $@ $^
