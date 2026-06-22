; hello-os

  ORG   0x7c00            ; 指明程序的装载地址

; 用于标准FAT12格式的软盘
    JMP   entry             ;   0x00	3	EB 4E 90	跳转到入口（
    DB    0x90
    DB    "HELLOIPL"        ;   0x03	8	HELLOIPL	OEM 厂商名称（任意）
    DW    512               ;   0x0B	2	0x0200	每扇区字节
    DB    1                 ;   0x0D	1	0x01	每簇扇区
    DW    1                 ;   0x0E	2	0x0001	保留扇区数（FAT起始位置）
    DB    2                 ;   0x10	1	0x02	FAT 表个数
    DW    224               ;   0x11	2	0x00E0	根目录最大条目数
    DW    2880              ;   0x13	2	0x0B40	磁盘总扇区数（1.44
    DB    0xf0              ;   0x15	1	0xF0	磁盘类型（可移动介质）
    DW    9                 ;   0x16	2	0x0009	每个 FAT 表占用的扇区数
    DW    18                ;   0x18	2	0x0012	每磁道扇区数
    DW    2                 ;   0x1A	2	0x0002	磁头数
    DD    0                 ;   0x1C	4	0x00000000	隐藏扇区数（不使用分区
    DD    2880              ;   0x20	4	0x00000B40	磁盘总扇区数（再次声明）
    DB    0, 0, 0x29        ;   0x24	3	00 00 29	扩展引导签名（固定值）
    DD    0xffffffff        ;   0x27	4	FFFFFFFF	卷序列号
    DB    "HELLO-OS   "     ;   0x2B	11	HELLO-OS	磁盘卷标
    DB    "FAT12   "        ;   0x36	8	FAT12	文件系统类型
    RESB  18                ;   0x3E	18	全部为 0	保留区（填充至引导代码区）

; 程序核心

entry:
    MOV   AX, 0
    MOV   SS, AX          ; 栈段寄存器设为 0
    MOV   SP, 0x7c00      ; 栈指针指向 0x7C00（栈向下生长）
    MOV   DS, AX          ; 数据段设为 0

; Disk read setup

    ; set range of reading, (loading 0x8200)
    MOV AX, 0x0820
    MOV ES, AX

    ; 柱头 0， 磁头0，扇区2
    MOV CH, 0
    MOV DH, 0
    MOV CL, 2

    MOV SI, 0

retry:

    ; 读取第一个扇区
    MOV   AH, 0x02
    MOV   AL, 1
    MOV   BX, 0
    MOV   DL, 0x00
    INT   0x13
    JC    fin
    ADD   SI, 1
    CMP   SI, 5
    JAE   error
    MOV   AH, 0x00
    MOV   DL, 0x00
    INT   0x13
    JMP   retry

error:
    MOV   SI, msg         ; SI 指向字符串起始地址

putloop:
    MOV   AL, [SI]      ; 从 SI 地址读取一个字节到 AL
    ADD   SI, 1         ; SI 指向下一个字符
    CMP   AL, 0         ; 判断是否为字符串结束符（'\0'）
    JE    fin           ; 如果是 0，跳转到 fin

    MOV   AH, 0x0e      ; 设置 BIOS 显示功能号（0x0e = 字符输出）
    MOV   BX, 15        ; 设置颜色属性（15 = 白色）
    INT   0x10          ; 调用 BIOS 中断 0x10 显示字符
    JMP   putloop       ; 继续下一个字符

fin:
  HLT                     ; CPU停止，等待指令
  JMP   fin               ; 无限循环

msg:
  DB    0x0a, 0x0a    ; ASCII 0x0A = 换行符（LF），两个换行
  DB    "hello, world"
  DB    0x0a          ; 换行符
  DB    0             ; 字符串结束符（C 风格 '\0'）


RESB	0x7dfe-0x7c00-($-$$)  ; 从当前位置填充到 0x1FE
DB    0x55, 0xaa        ; 引导扇区有效标志

; $$	    当前段的起始地址	0x7C00
; $	        当前汇编地址	假设为 0x7C2A
; $ - $$	已写入的字节数	0x2A（42 字节）
; 0x1FE - ($ - $$)	还需要填充的字节数	0x1FE - 0x2A = 0x1D4