DEL 	= rm -f

all: haribote.img

ipl.bin: ipl.asm
	nasm -f bin -o ipl.bin ipl.asm

haribote.sys : haribote.asm
	nasm -f bin -o haribote.sys haribote.asm

haribote.img: ipl.bin haribote.sys 
	dd if=/dev/zero of=$@ bs=512 count=2880
	mformat -f 1440 -i $@ ::
	dd if=ipl.bin of=$@ bs=512 count=1 conv=notrunc
	mcopy -i $@ haribote.sys ::/

run: haribote.img
	qemu-system-x86_64 -drive file=$<,format=raw,if=floppy -boot a

run-debug: haribote.img
	qemu-system-x86_64 -drive file=haribote.img,format=raw,if=floppy -boot a -monitor stdio

run-dirve: haribote.img
	qemu-system-x86_64 -drive file=haribote.img,format=raw,if=floppy

run-gdb: haribote.img
	qemu-system-x86_64 -drive file=$<,format=raw,if=floppy -boot a -s -S

clean:
	-$(DEL) ipl.bin
	-$(DEL) ipl.lst
	-$(DEL) haribote.sys
	-$(DEL) haribote.lst
	-$(DEL) haribote.img

