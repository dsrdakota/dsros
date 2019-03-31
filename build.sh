#!/bin/bash
export PATH="$HOME/cross-32/bin:$HOME/cross-32/i386-elf/bin:$PATH"
C_FILES="kernel.c lib/string.c term/term.c"
O_FILES=""
function compile() {
	echo "Building bootloader ..."
	i386-elf-as boot2.s -o boot.o
	echo "Building kernel ..."
	for f in $C_FILES; do
		i386-elf-gcc -c $f -o "$(dirname $f)/$(basename $f .c).o" -I. -Iterm -Ilib -I$HOME/cross-32/include -std=gnu99 -ffreestanding -O2 -Wall -Wextra
		O_FILES="$(dirname $f)/$(basename $f .c).o $O_FILES"
	done
	i386-elf-gcc -T linker.ld -o kernel.bin -ffreestanding -O2 -nostdlib -L$HOME/cross-32/lib -static-libgcc -static boot.o $O_FILES -lgcc $HOME/cross-32/lib/libm.a $HOME/cross-32/lib/libc.a
	cp -f kernel.bin iso/
	return $?
}

function build_iso() {
	grub-mkrescue -o grub.iso iso
	return $?
}

function run() {
	qemu-system-x86_64 -cdrom grub.iso -boot d -m 512 -soundhw ac97
	return $?
}

[[ -z "$@" ]] && compile && build_iso && run && exit $? 

[[ "$1" == "build-only" ]] && compile && build_iso && exit $?
[[ "$1" == "build-run" ]] && compile && build_iso && run && exit $?
[[ "$1" == "run-only" ]] && run && exit $?

if [[ "$1" == "test" ]]; then
	grub-file --is-x86-multiboot2 kernel.bin
	if [[ $? -eq 0 ]]; then
		echo "Info: Successfully found magic header in kernel as a multiboot2 kernel."
	else
		echo "Error: kernel hasnt been built as a multiboot2-kernel."
	fi
fi
