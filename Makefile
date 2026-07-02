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

UTILS_FOLDER := ./utils
MAKEFONT := $(UTILS_FOLDER)/makefont

IMG = haribote.img

all: $(IMG)


ipl.bin: ipl.asm
	$(NASM) -f bin -o ipl.bin ipl.asm

naskfunc.elf : naskfunc.asm
	$(NASM) -f elf32 -o $@ $< -l $(basename $@).lst

hankaku.asm : hankaku.txt
	gcc -o $(MAKEFONT) $(UTILS_FOLDER)/makefont.c 
	$(MAKEFONT) -i $< -o $@ -f 1

hankaku.elf : hankaku.asm
	$(NASM) -f elf32 -o $@ $< -l hakaku.lst

bootpack.o : bootpack.c
	$(CC) $(CFLAGS) -S $< -o bootpack.s 
	$(CC) $(CFLAGS) -c bootpack.s -o $@

asmhead.bin : asmhead.asm
	$(NASM) -f bin -o $@ $< -l $(basename $@).lst

bootpack.hrb: bootpack.o naskfunc.elf hankaku.elf
	$(LD) $(LDFLAGS) --oformat binary -o $@ --defsym=STACK_SIZE=3136*1024 -T $(HRB_LDS) $^ -Map $(basename $@).map

haribote.sys : asmhead.bin bootpack.hrb
	cat asmhead.bin > $@
	cat bootpack.hrb >> $@

$(IMG): ipl.bin haribote.sys 
	dd if=/dev/zero of=$@ bs=512 count=2880
	mformat -f 1440 -i $@ ::
	dd if=ipl.bin of=$@ bs=512 count=1 conv=notrunc
	mcopy -i $@ haribote.sys ::/

run: $(IMG)
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

