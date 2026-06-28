HRB_LDS := hrb.lds

NASM = nasm
CC 			= 		gcc
AS 			= 		as
LD 			= 		ld
CFLAGS = -fleading-underscore \
		 -ffreestanding \
		 -fno-stack-protector \
		 -nostdlib \
		 -nostdinc \
		 -nostartfiles \
		 -Wall \
		 -fno-pie \
		 -m32 \
		 -mtune=i486 -march=i486 \
		 -masm=intel

LDFLAGS 	=	-m elf_i386
DEL 		= 		rm -f


all: haribote.img

ipl.bin: ipl.asm
	$(NASM) -f bin -o ipl.bin ipl.asm

asmhead.bin : asmhead.asm
	$(NASM) -f bin -o asmhead.bin asmhead.asm

bootpack.hrb: bootpack.obj naskfunc.obj
	$(LD) $(LDFLAGS) --oformat binary -o $@ --defsym=STACK_SIZE=3136*1024 -T $(HRB_LDS) $^ -Map $(basename $@).map

naskfunc.obj : naskfunc.asm
	$(NASM) -f elf32 -o $@ $< -l $(basename $@).lst

haribote.sys : asmhead.bin bootpack.hrb
	cat asmhead.bin > $@
	cat bootpack.hrb >> $@

haribote.img: ipl.bin haribote.sys 
	dd if=/dev/zero of=$@ bs=512 count=2880
	mformat -f 1440 -i $@ ::
	dd if=ipl.bin of=$@ bs=512 count=1 conv=notrunc
	mcopy -i $@ haribote.sys ::/

%.obj : %.c
	$(CC) $(CFLAGS) -c $< -o $@

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
	-$(DEL) *.lst
	-$(DEL) *.elf
	-$(DEL) *.o
	-$(DEL) *.obj
	-$(DEL) *.map
	-$(DEL) *.hrb
	-$(DEL) bootpack.s
	-$(DEL) haribote.sys
	-$(DEL) haribote.img

