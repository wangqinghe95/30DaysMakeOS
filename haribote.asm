CYLS	EQU		0x0ff0      ; 设置启动区
LEDS	EQU		0x0ff1
VMODE	EQU		0x0ff2      ; 设置颜色数目，颜色位数等信息
SCRNX	EQU		0x0ff4      ; 分辨率 X （screen X）
SCRNY	EQU		0x0ff6      ; 分辨率 Y （screen Y）
VRAM	EQU		0x0ff8      ; 图像缓冲区的起始地址

    ORG     0xc200

    MOV     AL, 0x13        ; VGA 显卡，320*200*8
    MOV     AH, 0x00
    INT     0x10

    MOV     BYTE    [VMODE],8
    MOV     WORD    [SCRNX],320
    MOV     WORD    [SCRNY],200
    MOV     DWORD   [VRAM], 0x000a0000

    ; 用 BIOS 获取键盘上各种 LED 指示灯状态
    MOV     AH,0x02
    INT     0x16
    MOV     [LEDS],AL

fin:
    HLT
    JMP fin