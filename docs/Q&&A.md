# Q&&A

## 07 从鼠标接受数据（harib04g）

Q1:
```
struct FIFO8
{
    unsigned char *buf;
    int p, q, size, free, flags;
};
```

`unsigned char *buf;` 和 `char *buf;` 显示的位数不对，后者显示的是32b的16进制数据，而前者只有8位

Q2:

只能先接受鼠标驱动显示，再接受键盘输出，顺序不对鼠标显示有问题。