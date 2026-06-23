DEL 	= rm -f

all: haribote.img

ipl.bin: ipl.asm
	nasm -f bin -o ipl.bin ipl.asm

haribote.img: ipl.bin
	dd if=/dev/zero of=haribote.img bs=512 count=2880
	dd if=ipl.bin of=haribote.img bs=512 count=1 conv=notrunc
	printf "HELLO_KERNEL" | dd of=haribote.img bs=512 seek=1 count=1 conv=notrunc

run: haribote.img
	qemu-system-x86_64 -drive file=haribote.img,format=raw,if=floppy -boot a

run-debug:
	qemu-system-x86_64 -drive file=haribote.img,format=raw,if=floppy -boot a -monitor stdio

run-dirve: haribote.img
	qemu-system-x86_64 -drive file=haribote.img,format=raw,if=floppy


clean:
	-$(DEL) ipl.bin haribote.img 

