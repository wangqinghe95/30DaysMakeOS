#include<stdio.h>
#include "bootpack.h"

void HariMain(void)
{
    struct BOOTINFO *binfo = (struct BOOTINFO*) 0x0ff0;
    char s[40], mcursor[256], keybuf[32], mousebuf[128];
    int mx, my;
    struct MOUSE_DEC mdec;

    init_gdtidt();
    init_pic();

    io_sti();

    fifo8_init(&keyfifo, 32, keybuf);
    fifo8_init(&mousefifo, 128, mousebuf);
    io_out8(PIC0_IMR, 0xf9);
    io_out8(PIC1_IMR, 0xef);

    init_keyboard();

	init_palette();
    init_screen8(binfo->vram, binfo->scrnx, binfo->scrny);
    
    mx = (binfo->scrnx - 16 ) / 2;
    my = (binfo->scrny - 28 - 16) / 2;

    init_mouse_cursor8(mcursor, COL8_008484);

    putblock8_8(binfo->vram, binfo->scrnx, 16, 16, mx, my, mcursor, 16);
    sprintf(s, "(%d %d)",  mx, my);

    putfonts8_asc(binfo->vram, binfo->scrnx, 0, 0, COL8_FFFFFF, s);

    enable_mouse(&mdec);

	for (;;) {
		io_cli();
        if(fifo8_status(&keyfifo)+ fifo8_status(&mousefifo)  == 0 ) {
            io_stihlt();
        }
        else {
            if(fifo8_status(&keyfifo) != 0) {
                int data = fifo8_get(&keyfifo);
                io_sti();
                sprintf(s, "%02X", data);
                boxfill8(binfo->vram, binfo->scrnx, COL8_008484, 0, 16, 15, 31);
                putfonts8_asc(binfo->vram, binfo->scrnx, 0, 16, COL8_FFFFFF, s);
            }
            else if(fifo8_status(&mousefifo) != 0) {
                int data = fifo8_get(&mousefifo);
                io_sti();
                if(mouse_decode(&mdec, data) != 0) {
                    sprintf(s, "[lcr %4d %4d]", mdec.x, mdec.y);
                    if(mdec.btn & 0x01 != 0) {
                        s[1] = 'L';
                    }
                    if(mdec.btn & 0x02 != 0) {
                        s[3] = 'R';
                    }
                    if(mdec.btn & 0x01 != 0) {
                        s[2] = 'C';
                    }
                    boxfill8(binfo->vram, binfo->scrnx, COL8_008484, 32, 16, 32+15*8-1, 31);
                    putfonts8_asc(binfo->vram, binfo->scrnx, 32, 16, COL8_FFFFFF, s);
                    
                    // move mouse
                    boxfill8(binfo->vram, binfo->scrnx, COL8_008484, mx, my, mx+15, my+15);
                    mx += mdec.x;
                    my += mdec.y;

                    mx = mx < 0 ? 0 : mx;
                    my = my < 0 ? 0 : my;

                    mx = mx > binfo->scrnx - 16 ? binfo->scrnx - 16 : mx;
                    my = mx > binfo->scrny - 16 ? binfo->scrny - 16 : mx;

                    sprintf(s, "(%3d %3d)", mx, my);
                    boxfill8(binfo->vram, binfo->scrnx, COL8_008484, 0, 0, 79, 15);
                    putfonts8_asc(binfo->vram, binfo->scrnx, 0, 0, COL8_FFFFFF, s);
                    putblock8_8(binfo->vram, binfo->scrnx, 16, 16, mx, my, mcursor, 16);


                    
                }
            }
        }
	}
}

