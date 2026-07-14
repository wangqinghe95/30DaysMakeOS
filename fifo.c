#include "bootpack.h"

#define FLAGS_OVERRUN       0x0001

void fifo_init(struct FIFO8* fifo, int size, char* buf)
{
    fifo->size = size;
    fifo->buf = buf;
    fifo->free = size;
    fifo->p = fifo->q = fifo->flags = 0;
    return;
}
int fifo_put(struct FIFO8* fifo, char data)
{
    if(fifo->free == 0) {
        fifo->flags |= FLAGS_OVERRUN;
        return -1;
    }

    fifo->buf[fifo->p] = data;
    fifo->p++;
    if(fifo->p == fifo->size) {
        fifo->p = 0;
    }

    fifo->free--;
    return 0;
}
int fifo_get(struct FIFO8* fifo)
{
    if(fifo->free == fifo->size) {
        return -1;
    }
    int data = fifo->buf[fifo->q];
    fifo->q++;
    if(fifo->q == fifo->size) {
        fifo->q = 0;
    }

    fifo->free++;
    return data;
}

int fifo_status(struct FIFO8* fifo)
{
    return fifo->size - fifo->free;
}