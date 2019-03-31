
.set MAGIC,    0xe85250d6       /* 'magic number' lets bootloader find the header */
.set ARCH,     0x00
.set HDR_LEN,  0x10
.set CHECKSUM, 0x100000000-(MAGIC + ARCH + HDR_LEN) /* checksum of above, to prove we are multiboot */

 
/* 
Declare a multiboot header that marks the program as a kernel. These are magic
values that are documented in the multiboot standard. The bootloader will
search for this signature in the first 8 KiB of the kernel file, aligned at a
32-bit boundary. The signature is in its own section so the header can be
forced to be within the first 8 KiB of the kernel file.
*/
.section .multiboot
.align 4
.long MAGIC
.long ARCH
.long CHECKSUM
// insert optional multiboot flags here
//tags
    .balign 8
//module align
    .word 6 // type
    .word 0 // flags
    .long 8 // size in bytes (spec says 12?)
/*
    .balign 8
// loader entry
    .word 3
    .word 0
    .long 12
    .long entry
*/
    .balign 8
// console flags
    .word 4
    .word 0
    .long 12
    .long 0x03 // EGA text support, require console
    .balign 8
// info request 
    .word 1
    .word 0
    .long 4*6+8
    .long 5 // BIOS boot device
    .long 1 // command line
    .long 3 // modules
    .long 9 // ELF symbols
    .long 6 // memory map
    .long 10 // APM table
    .balign 8
    // address info
    .word 2 // type
    .word 0 // flags
    .long 24 // size
    .long .multiboot // header load addr
    .long 0x100000 // load addr
    .long 0 // load end addr (entire file)
    .long 0 // BSS end addr (no BSS)
    .balign 8
// end tags
.word 0 // type
.word 0 // flags
.long 8 // size
 
/*
The multiboot standard does not define the value of the stack pointer register
(esp) and it is up to the kernel to provide a stack. This allocates room for a
small stack by creating a symbol at the bottom of it, then allocating 16384
bytes for it, and finally creating a symbol at the top. The stack grows
downwards on x86. The stack is in its own section so it can be marked nobits,
which means the kernel file is smaller because it does not contain an
uninitialized stack. The stack on x86 must be 16-byte aligned according to the
System V ABI standard and de-facto extensions. The compiler will assume the
stack is properly aligned and failure to align the stack will result in
undefined behavior.
*/
.section .bss
.align 16
stack_bottom:
.skip 16384 // 16 KiB
stack_top:
 
/*
The linker script specifies _start as the entry point to the kernel and the
bootloader will jump to this position once the kernel has been loaded. It
doesn't make sense to return from this function as the bootloader is gone.
*/
.section .text
.global _start
.type _start, @function
_start:
	/*
	The bootloader has loaded us into 32-bit protected mode on a x86
	machine. Interrupts are disabled. Paging is disabled. The processor
	state is as defined in the multiboot standard. The kernel has full
	control of the CPU. The kernel can only make use of hardware features
	and any code it provides as part of itself. There's no printf
	function, unless the kernel provides its own <stdio.h> header and a
	printf implementation. There are no security restrictions, no
	safeguards, no debugging mechanisms, only what the kernel provides
	itself. It has absolute and complete power over the
	machine.
	*/
 
	/*
	To set up a stack, we set the esp register to point to the top of the
	stack (as it grows downwards on x86 systems). This is necessarily done
	in assembly as languages such as C cannot function without a stack.
	*/
	mov $stack_top, %esp
 
	/*
	This is a good place to initialize crucial processor state before the
	high-level kernel is entered. It's best to minimize the early
	environment where crucial features are offline. Note that the
	processor is not fully initialized yet: Features such as floating
	point instructions and instruction set extensions are not initialized
	yet. The GDT should be loaded here. Paging should be enabled here.
	C++ features such as global constructors and exceptions will require
	runtime support to work as well.
	*/
	
	/* TODO:
		Setup FPU, paging and load the GDT here
	*/

	/*
	Enter the high-level kernel. The ABI requires the stack is 16-byte
	aligned at the time of the call instruction (which afterwards pushes
	the return pointer of size 4 bytes). The stack was originally 16-byte
	aligned above and we've since pushed a multiple of 16 bytes to the
	stack since (pushed 0 bytes so far) and the alignment is thus
	preserved and the call is well defined.
	*/
	call kernel_main
 
	/*
	If the system has nothing more to do, put the computer into an
	infinite loop. To do that:
	1) Disable interrupts with cli (clear interrupt enable in eflags).
	   They are already disabled by the bootloader, so this is not needed.
	   Mind that you might later enable interrupts and return from
	   kernel_main (which is sort of nonsensical to do).
	2) Wait for the next interrupt to arrive with hlt (halt instruction).
	   Since they are disabled, this will lock up the computer.
	3) Jump to the hlt instruction if it ever wakes up due to a
	   non-maskable interrupt occurring or due to system management mode.
	*/
	cli
1:	hlt
	jmp 1b
 
/*
Set the size of the _start symbol to the current location '.' minus its start.
This is useful when debugging or when you implement call tracing.
*/
.size _start, . - _start