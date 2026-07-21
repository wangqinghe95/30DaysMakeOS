#include "bootpack.h"


struct SHTCTL *shtctl_init(struct MEMMAN* memman, unsigned char* vram, int xsize, int ysize)
{
    struct SHTCTL *ctl = (struct SHTCTL *)memman_alloc_4k(memman, sizeof(struct SHTCTL));
    if(0 == ctl) {
        goto err;
    }

    ctl->vram = vram;
    ctl->xsize = xsize;
    ctl->ysize = ysize;
    ctl->top = -1;
    for(int i = 0; i < MAX_SHEETS; i++) {
        ctl->sheet0[i].flags = 0;
    }
err:
    return ctl;
}


struct SHEET *sheet_alloc(struct SHTCTL *ctl)
{
    struct SHEET *sht;
    for(int i = 0; i < MAX_SHEETS; i++) {
        if(ctl->sheet0[i].flags == 0) {
            sht = &ctl->sheet0[i];
            sht->flags = SHEET_USE;
            sht->height = -1;
            return sht;
        }
    }
    return 0;
}

void sheet_setbuf(struct SHEET *sht, unsigned char *buf, int xsize, int ysize, int col_inv)
{
    sht->buf = buf;
    sht->bxsize = xsize;
    sht->bysize = ysize;
    sht->col_inv = col_inv;
    return;
}

void sheet_updown(struct SHTCTL* ctl, struct SHEET *sht, int height)
{
    int old = sht->height;

    if(height > ctl->top + 1) {
        height = ctl->top + 1;
    }

    if(height < -1) height = -1;

    sht->height = height;

    if(old > height) {
        if(height >= 0) {
            for(int h = old; h > height; h--) {
                ctl->sheets[h] = ctl->sheets[h-1];
                ctl->sheets[h]->height = h;
            }
            ctl->sheets[height] = sht;
        }
        else {
            if(ctl->top > old) {
                for(int h = old; h < ctl->top; h++) {
                    ctl->sheets[h] = ctl->sheets[h+1];
                    ctl->sheets[h]->height = h;
                }
            }
            ctl->top--;
        }
        sheet_refreshsub(ctl, sht->vx0, sht->vy0, sht->vx0+sht->bxsize, sht->vy0+sht->bysize);
    }
    else if(old < height) {
        if(old >= 0) {
            for(int h = 0; h < height; h++) {
                ctl->sheets[h] = ctl->sheets[h+1];
                ctl->sheets[h]->height = h;
            }
            ctl->sheets[height] = sht;
        }
        else {
            for(int h = ctl->top; h >= height; h--) {
                ctl->sheets[h+1] = ctl->sheets[h];
                ctl->sheets[h+1]->height = h + 1;
            }
            ctl->sheets[height] = sht;
            ctl->top++;
        }
        sheet_refreshsub(ctl, sht->vx0, sht->vy0, sht->vx0+sht->bxsize, sht->vy0+sht->bysize);
    }
    return;
}

void sheet_refreshsub(struct SHTCTL *ctl, int vx0, int vy0, int vx1, int vy1)
{
    unsigned char* vram = ctl->vram;
    if(vx0 < 0) vx0 = 0;
    if(vy0 < 0) vy0 = 0;
    if(vx1 > ctl->xsize) vx1 = ctl->xsize;
    if(vy1 > ctl->ysize) vy1 = ctl->ysize;
    for(int h = 0; h <= ctl->top; h++) {
        struct SHEET *sht = ctl->sheets[h];
        unsigned char* buf = sht->buf;

        int bx0 = vx0 - sht->vx0;
        int by0 = vy0 - sht->vy0;
        int bx1 = vx1 - sht->vx0;
        int by1 = vy1 - sht->vy0;

        if(bx0 < 0) bx0 = 0;
        if(by0 < 0) by0 = 0;

        if(bx1 > sht->bxsize) bx1 = sht->bxsize;
        if(by1 > sht->bysize) by1 = sht->bysize;

        for(int by = by0; by < by1; by++) {
            int vy = sht->vy0 + by;
            for(int bx = bx0; bx < bx1; bx++) {
                int vx = sht->vx0 + bx;
                unsigned char c = buf[by * sht->bxsize + bx];
                if(c != sht->col_inv) {
                    vram[vy * ctl -> xsize + vx] = c;
                }
            }
        } 
    }
    return;
}

void sheet_refresh(struct SHTCTL *ctl, struct SHEET *sht, int bx0, int by0, int bx1, int by1)
{
    if(sht->height >= 0) {
        sheet_refreshsub(ctl, sht->vx0+bx0, sht->vy0+by0, sht->vx0+bx1, sht->vy0+by1);
    }
    return;
}

void sheet_slide(struct SHTCTL *ctl, struct SHEET *sht, int vx0, int vy0)
{
    int old_vx0 = sht->vx0, old_vy0 = sht->vy0;
    sht->vx0 = vx0;
    sht->vy0 = vy0;
    if(sht->height >= 0) {
        sheet_refreshsub(ctl, old_vx0, old_vy0, old_vx0 + sht->bxsize, old_vy0 + sht->bysize);
        sheet_refreshsub(ctl, vx0, vy0, vx0 + sht->bxsize, vy0 + sht->bysize);
    }
    return;
}

void sheet_free(struct SHTCTL *ctl, struct SHEET *sht)
{
    if(sht->height >= 0) {
        sheet_updown(ctl, sht, -1);
    }

    sht->flags = 0;
    return;
}