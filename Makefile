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

ifdef DEBUG
QEMU_FLAGS += -s -S 
QEMU_FLAGS += -monitor stdio
CFLAGS += -g
NAMS_FLAGS += -F dwarf -g 
endif

LDFLAGS 	=		-m elf_i386
DEL 		= 		rm -f

UTILS_FOLDER := ./utils
MAKEFONT := $(UTILS_FOLDER)/makefont
CFLAGS += -I$(UTILS_FOLDER)/libc/include

IMG = haribote.img

all: $(IMG)

ipl.bin: ipl.asm
	$(NASM) -f bin -o $@ $< -l $(basename $@).lst

naskfunc.elf : naskfunc.asm
	$(NASM) $(NAMS_FLAGS) -f elf32 -o $@ $< -l $(basename $@).lst

hankaku.asm : hankaku.txt
	gcc -o $(MAKEFONT) $(UTILS_FOLDER)/makefont.c 
	$(MAKEFONT) -i $< -o $@ -f 1

hankaku.elf : hankaku.asm
	$(NASM) $(NAMS_FLAGS) -f elf32 -o $@ $< -l $(basename $@).lst

OBJ_FILES := bootpack.obj stdio.obj dsctbl.obj graphic.obj int.obj fifo.obj keyboard.obj mouse.obj memory.obj

%.obj : %.c 
	$(CC) $(CFLAGS) -c $< -o $@
vpath %.c $(UTILS_FOLDER)/libc/src

asmhead.bin : asmhead.asm
	$(NASM) -f bin -o $@ $< -l $(basename $@).lst

bootpack.hrb: naskfunc.elf hankaku.elf $(OBJ_FILES)
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
	-$(DEL) hankaku.asm

.PHONY: all run

