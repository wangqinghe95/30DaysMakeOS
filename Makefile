NASM = nasm
CC 			= 		i686-linux-gnu-gcc
AS 			= 		i686-linux-gnu-as
LD 			= 		i686-linux-gnu-ld
CFLAGS 		= 		-ffreestanding -nostdlib -nostartfiles
LDFLAGS 	= 		-Ttext 0x1000
DEL 		= 		rm -f


all: haribote.img

ipl.bin: ipl.asm
	$(NASM) -f bin -o ipl.bin ipl.asm

asmhead.bin : asmhead.asm
	$(NASM) -f bin -o asmhead.bin asmhead.asm

bootpack.bin : bootpack.c
# 	$(CC) -S $(CFLAGS) $< -o bootpack.s
# 	$(AS) bootpack.s -o bootpack.o
# 	$(LD) bootpack.o -o bootpack.bin

	$(CC) $(CFLAGS) -c $< -o bootpack.bin

naskfunc.obj : naskfunc.asm
	$(NASM) -f bin -o naskfunc.obj naskfunc.asm

haribote.sys : asmhead.bin bootpack.bin naskfunc.obj 
	cat $^ > $@

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
	-$(DEL) *.bin
	-$(DEL) *.elf
	-$(DEL) *.o
	-$(DEL) bootpack.s
	-$(DEL) haribote.sys
	-$(DEL) haribote.img

