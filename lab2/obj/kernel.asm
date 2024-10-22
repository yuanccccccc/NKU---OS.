
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址，lui加载高20位进入t0，低12位为页内偏移量我们不需要
    # boot_page_table_sv39 是一个全局符号，它指向系统启动时使用的页表的开始位置
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c02052b7          	lui	t0,0xc0205
    # t1 := 0xffffffff40000000 即虚实映射偏移量，这一步是得到虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc0200004:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200008:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc020000a:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号（物理地址右移12位抹除低12位后得到物理页号）
    srli    t0, t0, 12
ffffffffc020000e:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39 39位虚拟地址模式
    li      t1, 8 << 60
ffffffffc0200012:	fff0031b          	addiw	t1,zero,-1
ffffffffc0200016:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    //一个按位或操作把satp的MODE字段，高1000后面全0，和三级页表的物理页号t1合并到一起
    or      t0, t0, t1
ffffffffc0200018:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    // satp放的是最高级页表的物理页号（44位），除此以外还有MODE字段（4位）、备用 ASID（address space identifier）16位
    csrw    satp, t0
ffffffffc020001c:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200020:	12000073          	sfence.vma
    #如果不加参数的， sfence.vma 会刷新整个 TLB 。你可以在后面加上一个虚拟地址，这样 sfence.vma 只会刷新这个虚拟地址的映射
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop) // 指向一个预先定义的虚拟地址 bootstacktop，这是内核栈的顶部。
ffffffffc0200024:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200028:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020002c:	03228293          	addi	t0,t0,50 # ffffffffc0200032 <kern_init>
    jr t0
ffffffffc0200030:	8282                	jr	t0

ffffffffc0200032 <kern_init>:
void grade_backtrace(void);


int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200032:	00006517          	auipc	a0,0x6
ffffffffc0200036:	fe650513          	addi	a0,a0,-26 # ffffffffc0206018 <buddy_s>
ffffffffc020003a:	00006617          	auipc	a2,0x6
ffffffffc020003e:	52e60613          	addi	a2,a2,1326 # ffffffffc0206568 <end>
int kern_init(void) {
ffffffffc0200042:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200044:	8e09                	sub	a2,a2,a0
ffffffffc0200046:	4581                	li	a1,0
int kern_init(void) {
ffffffffc0200048:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004a:	26b010ef          	jal	ra,ffffffffc0201ab4 <memset>
    cons_init();  // init the console
ffffffffc020004e:	3fc000ef          	jal	ra,ffffffffc020044a <cons_init>
    const char *message = "(NKU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200052:	00002517          	auipc	a0,0x2
ffffffffc0200056:	a7650513          	addi	a0,a0,-1418 # ffffffffc0201ac8 <etext+0x2>
ffffffffc020005a:	090000ef          	jal	ra,ffffffffc02000ea <cputs>

    print_kerninfo();
ffffffffc020005e:	0dc000ef          	jal	ra,ffffffffc020013a <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table 初始化中断描述符表IDT
ffffffffc0200062:	402000ef          	jal	ra,ffffffffc0200464 <idt_init>

    pmm_init();  // init physical memory management 物理内存管理
ffffffffc0200066:	18a010ef          	jal	ra,ffffffffc02011f0 <pmm_init>
    /* pmm_init()函数需要注册缺页中断处理程序，用于处理页面访问异常。
        当程序试图访问一个不存在的页面时，CPU会触发缺页异常，此时会调用缺页中断处理程序
        该程序会在物理内存中分配一个新的页面，并将其映射到虚拟地址空间中。
    */

    idt_init();  // init interrupt descriptor table
ffffffffc020006a:	3fa000ef          	jal	ra,ffffffffc0200464 <idt_init>

    clock_init();   // init clock interrupt 时钟中断
ffffffffc020006e:	39a000ef          	jal	ra,ffffffffc0200408 <clock_init>
    /*
    clock_init()函数需要注册时钟中断处理程序，用于定时触发时钟中断。
    当时钟中断被触发时，CPU会跳转到时钟中断处理程序，该程序会更新系统时间，并执行一些周期性的操作，如调度进程等
    */
    //这两个函数都需要使用中断描述符表，所以要在中断描述符表初始化之后再初始化时钟中断
    intr_enable();  // enable irq interrupt 开启中断
ffffffffc0200072:	3e6000ef          	jal	ra,ffffffffc0200458 <intr_enable>



    /* do nothing */
    while (1)
ffffffffc0200076:	a001                	j	ffffffffc0200076 <kern_init+0x44>

ffffffffc0200078 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200078:	1141                	addi	sp,sp,-16
ffffffffc020007a:	e022                	sd	s0,0(sp)
ffffffffc020007c:	e406                	sd	ra,8(sp)
ffffffffc020007e:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200080:	3cc000ef          	jal	ra,ffffffffc020044c <cons_putc>
    (*cnt) ++;
ffffffffc0200084:	401c                	lw	a5,0(s0)
}
ffffffffc0200086:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200088:	2785                	addiw	a5,a5,1
ffffffffc020008a:	c01c                	sw	a5,0(s0)
}
ffffffffc020008c:	6402                	ld	s0,0(sp)
ffffffffc020008e:	0141                	addi	sp,sp,16
ffffffffc0200090:	8082                	ret

ffffffffc0200092 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200092:	1101                	addi	sp,sp,-32
ffffffffc0200094:	862a                	mv	a2,a0
ffffffffc0200096:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200098:	00000517          	auipc	a0,0x0
ffffffffc020009c:	fe050513          	addi	a0,a0,-32 # ffffffffc0200078 <cputch>
ffffffffc02000a0:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000a2:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000a4:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000a6:	51e010ef          	jal	ra,ffffffffc02015c4 <vprintfmt>
    return cnt;
}
ffffffffc02000aa:	60e2                	ld	ra,24(sp)
ffffffffc02000ac:	4532                	lw	a0,12(sp)
ffffffffc02000ae:	6105                	addi	sp,sp,32
ffffffffc02000b0:	8082                	ret

ffffffffc02000b2 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000b2:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000b4:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000b8:	8e2a                	mv	t3,a0
ffffffffc02000ba:	f42e                	sd	a1,40(sp)
ffffffffc02000bc:	f832                	sd	a2,48(sp)
ffffffffc02000be:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000c0:	00000517          	auipc	a0,0x0
ffffffffc02000c4:	fb850513          	addi	a0,a0,-72 # ffffffffc0200078 <cputch>
ffffffffc02000c8:	004c                	addi	a1,sp,4
ffffffffc02000ca:	869a                	mv	a3,t1
ffffffffc02000cc:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc02000ce:	ec06                	sd	ra,24(sp)
ffffffffc02000d0:	e0ba                	sd	a4,64(sp)
ffffffffc02000d2:	e4be                	sd	a5,72(sp)
ffffffffc02000d4:	e8c2                	sd	a6,80(sp)
ffffffffc02000d6:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000d8:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000da:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000dc:	4e8010ef          	jal	ra,ffffffffc02015c4 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02000e0:	60e2                	ld	ra,24(sp)
ffffffffc02000e2:	4512                	lw	a0,4(sp)
ffffffffc02000e4:	6125                	addi	sp,sp,96
ffffffffc02000e6:	8082                	ret

ffffffffc02000e8 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02000e8:	a695                	j	ffffffffc020044c <cons_putc>

ffffffffc02000ea <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc02000ea:	1101                	addi	sp,sp,-32
ffffffffc02000ec:	e822                	sd	s0,16(sp)
ffffffffc02000ee:	ec06                	sd	ra,24(sp)
ffffffffc02000f0:	e426                	sd	s1,8(sp)
ffffffffc02000f2:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc02000f4:	00054503          	lbu	a0,0(a0)
ffffffffc02000f8:	c51d                	beqz	a0,ffffffffc0200126 <cputs+0x3c>
ffffffffc02000fa:	0405                	addi	s0,s0,1
ffffffffc02000fc:	4485                	li	s1,1
ffffffffc02000fe:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200100:	34c000ef          	jal	ra,ffffffffc020044c <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200104:	00044503          	lbu	a0,0(s0)
ffffffffc0200108:	008487bb          	addw	a5,s1,s0
ffffffffc020010c:	0405                	addi	s0,s0,1
ffffffffc020010e:	f96d                	bnez	a0,ffffffffc0200100 <cputs+0x16>
    (*cnt) ++;
ffffffffc0200110:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc0200114:	4529                	li	a0,10
ffffffffc0200116:	336000ef          	jal	ra,ffffffffc020044c <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc020011a:	60e2                	ld	ra,24(sp)
ffffffffc020011c:	8522                	mv	a0,s0
ffffffffc020011e:	6442                	ld	s0,16(sp)
ffffffffc0200120:	64a2                	ld	s1,8(sp)
ffffffffc0200122:	6105                	addi	sp,sp,32
ffffffffc0200124:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc0200126:	4405                	li	s0,1
ffffffffc0200128:	b7f5                	j	ffffffffc0200114 <cputs+0x2a>

ffffffffc020012a <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc020012a:	1141                	addi	sp,sp,-16
ffffffffc020012c:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020012e:	326000ef          	jal	ra,ffffffffc0200454 <cons_getc>
ffffffffc0200132:	dd75                	beqz	a0,ffffffffc020012e <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200134:	60a2                	ld	ra,8(sp)
ffffffffc0200136:	0141                	addi	sp,sp,16
ffffffffc0200138:	8082                	ret

ffffffffc020013a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020013a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc020013c:	00002517          	auipc	a0,0x2
ffffffffc0200140:	9ac50513          	addi	a0,a0,-1620 # ffffffffc0201ae8 <etext+0x22>
void print_kerninfo(void) {
ffffffffc0200144:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200146:	f6dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc020014a:	00000597          	auipc	a1,0x0
ffffffffc020014e:	ee858593          	addi	a1,a1,-280 # ffffffffc0200032 <kern_init>
ffffffffc0200152:	00002517          	auipc	a0,0x2
ffffffffc0200156:	9b650513          	addi	a0,a0,-1610 # ffffffffc0201b08 <etext+0x42>
ffffffffc020015a:	f59ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020015e:	00002597          	auipc	a1,0x2
ffffffffc0200162:	96858593          	addi	a1,a1,-1688 # ffffffffc0201ac6 <etext>
ffffffffc0200166:	00002517          	auipc	a0,0x2
ffffffffc020016a:	9c250513          	addi	a0,a0,-1598 # ffffffffc0201b28 <etext+0x62>
ffffffffc020016e:	f45ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200172:	00006597          	auipc	a1,0x6
ffffffffc0200176:	ea658593          	addi	a1,a1,-346 # ffffffffc0206018 <buddy_s>
ffffffffc020017a:	00002517          	auipc	a0,0x2
ffffffffc020017e:	9ce50513          	addi	a0,a0,-1586 # ffffffffc0201b48 <etext+0x82>
ffffffffc0200182:	f31ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200186:	00006597          	auipc	a1,0x6
ffffffffc020018a:	3e258593          	addi	a1,a1,994 # ffffffffc0206568 <end>
ffffffffc020018e:	00002517          	auipc	a0,0x2
ffffffffc0200192:	9da50513          	addi	a0,a0,-1574 # ffffffffc0201b68 <etext+0xa2>
ffffffffc0200196:	f1dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020019a:	00006597          	auipc	a1,0x6
ffffffffc020019e:	7cd58593          	addi	a1,a1,1997 # ffffffffc0206967 <end+0x3ff>
ffffffffc02001a2:	00000797          	auipc	a5,0x0
ffffffffc02001a6:	e9078793          	addi	a5,a5,-368 # ffffffffc0200032 <kern_init>
ffffffffc02001aa:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001ae:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001b2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001b4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001b8:	95be                	add	a1,a1,a5
ffffffffc02001ba:	85a9                	srai	a1,a1,0xa
ffffffffc02001bc:	00002517          	auipc	a0,0x2
ffffffffc02001c0:	9cc50513          	addi	a0,a0,-1588 # ffffffffc0201b88 <etext+0xc2>
}
ffffffffc02001c4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001c6:	b5f5                	j	ffffffffc02000b2 <cprintf>

ffffffffc02001c8 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001c8:	1141                	addi	sp,sp,-16

    panic("Not Implemented!");
ffffffffc02001ca:	00002617          	auipc	a2,0x2
ffffffffc02001ce:	9ee60613          	addi	a2,a2,-1554 # ffffffffc0201bb8 <etext+0xf2>
ffffffffc02001d2:	04e00593          	li	a1,78
ffffffffc02001d6:	00002517          	auipc	a0,0x2
ffffffffc02001da:	9fa50513          	addi	a0,a0,-1542 # ffffffffc0201bd0 <etext+0x10a>
void print_stackframe(void) {
ffffffffc02001de:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02001e0:	1cc000ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc02001e4 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02001e4:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02001e6:	00002617          	auipc	a2,0x2
ffffffffc02001ea:	a0260613          	addi	a2,a2,-1534 # ffffffffc0201be8 <etext+0x122>
ffffffffc02001ee:	00002597          	auipc	a1,0x2
ffffffffc02001f2:	a1a58593          	addi	a1,a1,-1510 # ffffffffc0201c08 <etext+0x142>
ffffffffc02001f6:	00002517          	auipc	a0,0x2
ffffffffc02001fa:	a1a50513          	addi	a0,a0,-1510 # ffffffffc0201c10 <etext+0x14a>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02001fe:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200200:	eb3ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200204:	00002617          	auipc	a2,0x2
ffffffffc0200208:	a1c60613          	addi	a2,a2,-1508 # ffffffffc0201c20 <etext+0x15a>
ffffffffc020020c:	00002597          	auipc	a1,0x2
ffffffffc0200210:	a3c58593          	addi	a1,a1,-1476 # ffffffffc0201c48 <etext+0x182>
ffffffffc0200214:	00002517          	auipc	a0,0x2
ffffffffc0200218:	9fc50513          	addi	a0,a0,-1540 # ffffffffc0201c10 <etext+0x14a>
ffffffffc020021c:	e97ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200220:	00002617          	auipc	a2,0x2
ffffffffc0200224:	a3860613          	addi	a2,a2,-1480 # ffffffffc0201c58 <etext+0x192>
ffffffffc0200228:	00002597          	auipc	a1,0x2
ffffffffc020022c:	a5058593          	addi	a1,a1,-1456 # ffffffffc0201c78 <etext+0x1b2>
ffffffffc0200230:	00002517          	auipc	a0,0x2
ffffffffc0200234:	9e050513          	addi	a0,a0,-1568 # ffffffffc0201c10 <etext+0x14a>
ffffffffc0200238:	e7bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    }
    return 0;
}
ffffffffc020023c:	60a2                	ld	ra,8(sp)
ffffffffc020023e:	4501                	li	a0,0
ffffffffc0200240:	0141                	addi	sp,sp,16
ffffffffc0200242:	8082                	ret

ffffffffc0200244 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200244:	1141                	addi	sp,sp,-16
ffffffffc0200246:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200248:	ef3ff0ef          	jal	ra,ffffffffc020013a <print_kerninfo>
    return 0;
}
ffffffffc020024c:	60a2                	ld	ra,8(sp)
ffffffffc020024e:	4501                	li	a0,0
ffffffffc0200250:	0141                	addi	sp,sp,16
ffffffffc0200252:	8082                	ret

ffffffffc0200254 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200254:	1141                	addi	sp,sp,-16
ffffffffc0200256:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200258:	f71ff0ef          	jal	ra,ffffffffc02001c8 <print_stackframe>
    return 0;
}
ffffffffc020025c:	60a2                	ld	ra,8(sp)
ffffffffc020025e:	4501                	li	a0,0
ffffffffc0200260:	0141                	addi	sp,sp,16
ffffffffc0200262:	8082                	ret

ffffffffc0200264 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200264:	7115                	addi	sp,sp,-224
ffffffffc0200266:	ed5e                	sd	s7,152(sp)
ffffffffc0200268:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020026a:	00002517          	auipc	a0,0x2
ffffffffc020026e:	a1e50513          	addi	a0,a0,-1506 # ffffffffc0201c88 <etext+0x1c2>
kmonitor(struct trapframe *tf) {
ffffffffc0200272:	ed86                	sd	ra,216(sp)
ffffffffc0200274:	e9a2                	sd	s0,208(sp)
ffffffffc0200276:	e5a6                	sd	s1,200(sp)
ffffffffc0200278:	e1ca                	sd	s2,192(sp)
ffffffffc020027a:	fd4e                	sd	s3,184(sp)
ffffffffc020027c:	f952                	sd	s4,176(sp)
ffffffffc020027e:	f556                	sd	s5,168(sp)
ffffffffc0200280:	f15a                	sd	s6,160(sp)
ffffffffc0200282:	e962                	sd	s8,144(sp)
ffffffffc0200284:	e566                	sd	s9,136(sp)
ffffffffc0200286:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200288:	e2bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020028c:	00002517          	auipc	a0,0x2
ffffffffc0200290:	a2450513          	addi	a0,a0,-1500 # ffffffffc0201cb0 <etext+0x1ea>
ffffffffc0200294:	e1fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    if (tf != NULL) {
ffffffffc0200298:	000b8563          	beqz	s7,ffffffffc02002a2 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020029c:	855e                	mv	a0,s7
ffffffffc020029e:	3a4000ef          	jal	ra,ffffffffc0200642 <print_trapframe>
ffffffffc02002a2:	00002c17          	auipc	s8,0x2
ffffffffc02002a6:	a7ec0c13          	addi	s8,s8,-1410 # ffffffffc0201d20 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002aa:	00002917          	auipc	s2,0x2
ffffffffc02002ae:	a2e90913          	addi	s2,s2,-1490 # ffffffffc0201cd8 <etext+0x212>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002b2:	00002497          	auipc	s1,0x2
ffffffffc02002b6:	a2e48493          	addi	s1,s1,-1490 # ffffffffc0201ce0 <etext+0x21a>
        if (argc == MAXARGS - 1) {
ffffffffc02002ba:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002bc:	00002b17          	auipc	s6,0x2
ffffffffc02002c0:	a2cb0b13          	addi	s6,s6,-1492 # ffffffffc0201ce8 <etext+0x222>
        argv[argc ++] = buf;
ffffffffc02002c4:	00002a17          	auipc	s4,0x2
ffffffffc02002c8:	944a0a13          	addi	s4,s4,-1724 # ffffffffc0201c08 <etext+0x142>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002cc:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002ce:	854a                	mv	a0,s2
ffffffffc02002d0:	676010ef          	jal	ra,ffffffffc0201946 <readline>
ffffffffc02002d4:	842a                	mv	s0,a0
ffffffffc02002d6:	dd65                	beqz	a0,ffffffffc02002ce <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002d8:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02002dc:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002de:	e1bd                	bnez	a1,ffffffffc0200344 <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc02002e0:	fe0c87e3          	beqz	s9,ffffffffc02002ce <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002e4:	6582                	ld	a1,0(sp)
ffffffffc02002e6:	00002d17          	auipc	s10,0x2
ffffffffc02002ea:	a3ad0d13          	addi	s10,s10,-1478 # ffffffffc0201d20 <commands>
        argv[argc ++] = buf;
ffffffffc02002ee:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002f0:	4401                	li	s0,0
ffffffffc02002f2:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002f4:	78c010ef          	jal	ra,ffffffffc0201a80 <strcmp>
ffffffffc02002f8:	c919                	beqz	a0,ffffffffc020030e <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002fa:	2405                	addiw	s0,s0,1
ffffffffc02002fc:	0b540063          	beq	s0,s5,ffffffffc020039c <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200300:	000d3503          	ld	a0,0(s10)
ffffffffc0200304:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200306:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200308:	778010ef          	jal	ra,ffffffffc0201a80 <strcmp>
ffffffffc020030c:	f57d                	bnez	a0,ffffffffc02002fa <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc020030e:	00141793          	slli	a5,s0,0x1
ffffffffc0200312:	97a2                	add	a5,a5,s0
ffffffffc0200314:	078e                	slli	a5,a5,0x3
ffffffffc0200316:	97e2                	add	a5,a5,s8
ffffffffc0200318:	6b9c                	ld	a5,16(a5)
ffffffffc020031a:	865e                	mv	a2,s7
ffffffffc020031c:	002c                	addi	a1,sp,8
ffffffffc020031e:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200322:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200324:	fa0555e3          	bgez	a0,ffffffffc02002ce <kmonitor+0x6a>
}
ffffffffc0200328:	60ee                	ld	ra,216(sp)
ffffffffc020032a:	644e                	ld	s0,208(sp)
ffffffffc020032c:	64ae                	ld	s1,200(sp)
ffffffffc020032e:	690e                	ld	s2,192(sp)
ffffffffc0200330:	79ea                	ld	s3,184(sp)
ffffffffc0200332:	7a4a                	ld	s4,176(sp)
ffffffffc0200334:	7aaa                	ld	s5,168(sp)
ffffffffc0200336:	7b0a                	ld	s6,160(sp)
ffffffffc0200338:	6bea                	ld	s7,152(sp)
ffffffffc020033a:	6c4a                	ld	s8,144(sp)
ffffffffc020033c:	6caa                	ld	s9,136(sp)
ffffffffc020033e:	6d0a                	ld	s10,128(sp)
ffffffffc0200340:	612d                	addi	sp,sp,224
ffffffffc0200342:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200344:	8526                	mv	a0,s1
ffffffffc0200346:	758010ef          	jal	ra,ffffffffc0201a9e <strchr>
ffffffffc020034a:	c901                	beqz	a0,ffffffffc020035a <kmonitor+0xf6>
ffffffffc020034c:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200350:	00040023          	sb	zero,0(s0)
ffffffffc0200354:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200356:	d5c9                	beqz	a1,ffffffffc02002e0 <kmonitor+0x7c>
ffffffffc0200358:	b7f5                	j	ffffffffc0200344 <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc020035a:	00044783          	lbu	a5,0(s0)
ffffffffc020035e:	d3c9                	beqz	a5,ffffffffc02002e0 <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc0200360:	033c8963          	beq	s9,s3,ffffffffc0200392 <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc0200364:	003c9793          	slli	a5,s9,0x3
ffffffffc0200368:	0118                	addi	a4,sp,128
ffffffffc020036a:	97ba                	add	a5,a5,a4
ffffffffc020036c:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200370:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200374:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200376:	e591                	bnez	a1,ffffffffc0200382 <kmonitor+0x11e>
ffffffffc0200378:	b7b5                	j	ffffffffc02002e4 <kmonitor+0x80>
ffffffffc020037a:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc020037e:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200380:	d1a5                	beqz	a1,ffffffffc02002e0 <kmonitor+0x7c>
ffffffffc0200382:	8526                	mv	a0,s1
ffffffffc0200384:	71a010ef          	jal	ra,ffffffffc0201a9e <strchr>
ffffffffc0200388:	d96d                	beqz	a0,ffffffffc020037a <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020038a:	00044583          	lbu	a1,0(s0)
ffffffffc020038e:	d9a9                	beqz	a1,ffffffffc02002e0 <kmonitor+0x7c>
ffffffffc0200390:	bf55                	j	ffffffffc0200344 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200392:	45c1                	li	a1,16
ffffffffc0200394:	855a                	mv	a0,s6
ffffffffc0200396:	d1dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc020039a:	b7e9                	j	ffffffffc0200364 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020039c:	6582                	ld	a1,0(sp)
ffffffffc020039e:	00002517          	auipc	a0,0x2
ffffffffc02003a2:	96a50513          	addi	a0,a0,-1686 # ffffffffc0201d08 <etext+0x242>
ffffffffc02003a6:	d0dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    return 0;
ffffffffc02003aa:	b715                	j	ffffffffc02002ce <kmonitor+0x6a>

ffffffffc02003ac <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02003ac:	00006317          	auipc	t1,0x6
ffffffffc02003b0:	16c30313          	addi	t1,t1,364 # ffffffffc0206518 <is_panic>
ffffffffc02003b4:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02003b8:	715d                	addi	sp,sp,-80
ffffffffc02003ba:	ec06                	sd	ra,24(sp)
ffffffffc02003bc:	e822                	sd	s0,16(sp)
ffffffffc02003be:	f436                	sd	a3,40(sp)
ffffffffc02003c0:	f83a                	sd	a4,48(sp)
ffffffffc02003c2:	fc3e                	sd	a5,56(sp)
ffffffffc02003c4:	e0c2                	sd	a6,64(sp)
ffffffffc02003c6:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02003c8:	020e1a63          	bnez	t3,ffffffffc02003fc <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02003cc:	4785                	li	a5,1
ffffffffc02003ce:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02003d2:	8432                	mv	s0,a2
ffffffffc02003d4:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003d6:	862e                	mv	a2,a1
ffffffffc02003d8:	85aa                	mv	a1,a0
ffffffffc02003da:	00002517          	auipc	a0,0x2
ffffffffc02003de:	98e50513          	addi	a0,a0,-1650 # ffffffffc0201d68 <commands+0x48>
    va_start(ap, fmt);
ffffffffc02003e2:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003e4:	ccfff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02003e8:	65a2                	ld	a1,8(sp)
ffffffffc02003ea:	8522                	mv	a0,s0
ffffffffc02003ec:	ca7ff0ef          	jal	ra,ffffffffc0200092 <vcprintf>
    cprintf("\n");
ffffffffc02003f0:	00002517          	auipc	a0,0x2
ffffffffc02003f4:	4c050513          	addi	a0,a0,1216 # ffffffffc02028b0 <buddy_system_pmm_manager+0xd8>
ffffffffc02003f8:	cbbff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc02003fc:	062000ef          	jal	ra,ffffffffc020045e <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200400:	4501                	li	a0,0
ffffffffc0200402:	e63ff0ef          	jal	ra,ffffffffc0200264 <kmonitor>
    while (1) {
ffffffffc0200406:	bfed                	j	ffffffffc0200400 <__panic+0x54>

ffffffffc0200408 <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc0200408:	1141                	addi	sp,sp,-16
ffffffffc020040a:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc020040c:	02000793          	li	a5,32
ffffffffc0200410:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200414:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200418:	67e1                	lui	a5,0x18
ffffffffc020041a:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020041e:	953e                	add	a0,a0,a5
ffffffffc0200420:	5f4010ef          	jal	ra,ffffffffc0201a14 <sbi_set_timer>
}
ffffffffc0200424:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc0200426:	00006797          	auipc	a5,0x6
ffffffffc020042a:	0e07bd23          	sd	zero,250(a5) # ffffffffc0206520 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020042e:	00002517          	auipc	a0,0x2
ffffffffc0200432:	95a50513          	addi	a0,a0,-1702 # ffffffffc0201d88 <commands+0x68>
}
ffffffffc0200436:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc0200438:	b9ad                	j	ffffffffc02000b2 <cprintf>

ffffffffc020043a <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020043a:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020043e:	67e1                	lui	a5,0x18
ffffffffc0200440:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200444:	953e                	add	a0,a0,a5
ffffffffc0200446:	5ce0106f          	j	ffffffffc0201a14 <sbi_set_timer>

ffffffffc020044a <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020044a:	8082                	ret

ffffffffc020044c <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc020044c:	0ff57513          	zext.b	a0,a0
ffffffffc0200450:	5aa0106f          	j	ffffffffc02019fa <sbi_console_putchar>

ffffffffc0200454 <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc0200454:	5da0106f          	j	ffffffffc0201a2e <sbi_console_getchar>

ffffffffc0200458 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200458:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc020045c:	8082                	ret

ffffffffc020045e <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc020045e:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200462:	8082                	ret

ffffffffc0200464 <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200464:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200468:	00000797          	auipc	a5,0x0
ffffffffc020046c:	30c78793          	addi	a5,a5,780 # ffffffffc0200774 <__alltraps>
ffffffffc0200470:	10579073          	csrw	stvec,a5
}
ffffffffc0200474:	8082                	ret

ffffffffc0200476 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200476:	610c                	ld	a1,0(a0)
{
ffffffffc0200478:	1141                	addi	sp,sp,-16
ffffffffc020047a:	e022                	sd	s0,0(sp)
ffffffffc020047c:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020047e:	00002517          	auipc	a0,0x2
ffffffffc0200482:	92a50513          	addi	a0,a0,-1750 # ffffffffc0201da8 <commands+0x88>
{
ffffffffc0200486:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200488:	c2bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020048c:	640c                	ld	a1,8(s0)
ffffffffc020048e:	00002517          	auipc	a0,0x2
ffffffffc0200492:	93250513          	addi	a0,a0,-1742 # ffffffffc0201dc0 <commands+0xa0>
ffffffffc0200496:	c1dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc020049a:	680c                	ld	a1,16(s0)
ffffffffc020049c:	00002517          	auipc	a0,0x2
ffffffffc02004a0:	93c50513          	addi	a0,a0,-1732 # ffffffffc0201dd8 <commands+0xb8>
ffffffffc02004a4:	c0fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02004a8:	6c0c                	ld	a1,24(s0)
ffffffffc02004aa:	00002517          	auipc	a0,0x2
ffffffffc02004ae:	94650513          	addi	a0,a0,-1722 # ffffffffc0201df0 <commands+0xd0>
ffffffffc02004b2:	c01ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02004b6:	700c                	ld	a1,32(s0)
ffffffffc02004b8:	00002517          	auipc	a0,0x2
ffffffffc02004bc:	95050513          	addi	a0,a0,-1712 # ffffffffc0201e08 <commands+0xe8>
ffffffffc02004c0:	bf3ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02004c4:	740c                	ld	a1,40(s0)
ffffffffc02004c6:	00002517          	auipc	a0,0x2
ffffffffc02004ca:	95a50513          	addi	a0,a0,-1702 # ffffffffc0201e20 <commands+0x100>
ffffffffc02004ce:	be5ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02004d2:	780c                	ld	a1,48(s0)
ffffffffc02004d4:	00002517          	auipc	a0,0x2
ffffffffc02004d8:	96450513          	addi	a0,a0,-1692 # ffffffffc0201e38 <commands+0x118>
ffffffffc02004dc:	bd7ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02004e0:	7c0c                	ld	a1,56(s0)
ffffffffc02004e2:	00002517          	auipc	a0,0x2
ffffffffc02004e6:	96e50513          	addi	a0,a0,-1682 # ffffffffc0201e50 <commands+0x130>
ffffffffc02004ea:	bc9ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02004ee:	602c                	ld	a1,64(s0)
ffffffffc02004f0:	00002517          	auipc	a0,0x2
ffffffffc02004f4:	97850513          	addi	a0,a0,-1672 # ffffffffc0201e68 <commands+0x148>
ffffffffc02004f8:	bbbff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02004fc:	642c                	ld	a1,72(s0)
ffffffffc02004fe:	00002517          	auipc	a0,0x2
ffffffffc0200502:	98250513          	addi	a0,a0,-1662 # ffffffffc0201e80 <commands+0x160>
ffffffffc0200506:	badff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc020050a:	682c                	ld	a1,80(s0)
ffffffffc020050c:	00002517          	auipc	a0,0x2
ffffffffc0200510:	98c50513          	addi	a0,a0,-1652 # ffffffffc0201e98 <commands+0x178>
ffffffffc0200514:	b9fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200518:	6c2c                	ld	a1,88(s0)
ffffffffc020051a:	00002517          	auipc	a0,0x2
ffffffffc020051e:	99650513          	addi	a0,a0,-1642 # ffffffffc0201eb0 <commands+0x190>
ffffffffc0200522:	b91ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200526:	702c                	ld	a1,96(s0)
ffffffffc0200528:	00002517          	auipc	a0,0x2
ffffffffc020052c:	9a050513          	addi	a0,a0,-1632 # ffffffffc0201ec8 <commands+0x1a8>
ffffffffc0200530:	b83ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200534:	742c                	ld	a1,104(s0)
ffffffffc0200536:	00002517          	auipc	a0,0x2
ffffffffc020053a:	9aa50513          	addi	a0,a0,-1622 # ffffffffc0201ee0 <commands+0x1c0>
ffffffffc020053e:	b75ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200542:	782c                	ld	a1,112(s0)
ffffffffc0200544:	00002517          	auipc	a0,0x2
ffffffffc0200548:	9b450513          	addi	a0,a0,-1612 # ffffffffc0201ef8 <commands+0x1d8>
ffffffffc020054c:	b67ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200550:	7c2c                	ld	a1,120(s0)
ffffffffc0200552:	00002517          	auipc	a0,0x2
ffffffffc0200556:	9be50513          	addi	a0,a0,-1602 # ffffffffc0201f10 <commands+0x1f0>
ffffffffc020055a:	b59ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc020055e:	604c                	ld	a1,128(s0)
ffffffffc0200560:	00002517          	auipc	a0,0x2
ffffffffc0200564:	9c850513          	addi	a0,a0,-1592 # ffffffffc0201f28 <commands+0x208>
ffffffffc0200568:	b4bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc020056c:	644c                	ld	a1,136(s0)
ffffffffc020056e:	00002517          	auipc	a0,0x2
ffffffffc0200572:	9d250513          	addi	a0,a0,-1582 # ffffffffc0201f40 <commands+0x220>
ffffffffc0200576:	b3dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc020057a:	684c                	ld	a1,144(s0)
ffffffffc020057c:	00002517          	auipc	a0,0x2
ffffffffc0200580:	9dc50513          	addi	a0,a0,-1572 # ffffffffc0201f58 <commands+0x238>
ffffffffc0200584:	b2fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200588:	6c4c                	ld	a1,152(s0)
ffffffffc020058a:	00002517          	auipc	a0,0x2
ffffffffc020058e:	9e650513          	addi	a0,a0,-1562 # ffffffffc0201f70 <commands+0x250>
ffffffffc0200592:	b21ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200596:	704c                	ld	a1,160(s0)
ffffffffc0200598:	00002517          	auipc	a0,0x2
ffffffffc020059c:	9f050513          	addi	a0,a0,-1552 # ffffffffc0201f88 <commands+0x268>
ffffffffc02005a0:	b13ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02005a4:	744c                	ld	a1,168(s0)
ffffffffc02005a6:	00002517          	auipc	a0,0x2
ffffffffc02005aa:	9fa50513          	addi	a0,a0,-1542 # ffffffffc0201fa0 <commands+0x280>
ffffffffc02005ae:	b05ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02005b2:	784c                	ld	a1,176(s0)
ffffffffc02005b4:	00002517          	auipc	a0,0x2
ffffffffc02005b8:	a0450513          	addi	a0,a0,-1532 # ffffffffc0201fb8 <commands+0x298>
ffffffffc02005bc:	af7ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02005c0:	7c4c                	ld	a1,184(s0)
ffffffffc02005c2:	00002517          	auipc	a0,0x2
ffffffffc02005c6:	a0e50513          	addi	a0,a0,-1522 # ffffffffc0201fd0 <commands+0x2b0>
ffffffffc02005ca:	ae9ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02005ce:	606c                	ld	a1,192(s0)
ffffffffc02005d0:	00002517          	auipc	a0,0x2
ffffffffc02005d4:	a1850513          	addi	a0,a0,-1512 # ffffffffc0201fe8 <commands+0x2c8>
ffffffffc02005d8:	adbff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02005dc:	646c                	ld	a1,200(s0)
ffffffffc02005de:	00002517          	auipc	a0,0x2
ffffffffc02005e2:	a2250513          	addi	a0,a0,-1502 # ffffffffc0202000 <commands+0x2e0>
ffffffffc02005e6:	acdff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02005ea:	686c                	ld	a1,208(s0)
ffffffffc02005ec:	00002517          	auipc	a0,0x2
ffffffffc02005f0:	a2c50513          	addi	a0,a0,-1492 # ffffffffc0202018 <commands+0x2f8>
ffffffffc02005f4:	abfff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02005f8:	6c6c                	ld	a1,216(s0)
ffffffffc02005fa:	00002517          	auipc	a0,0x2
ffffffffc02005fe:	a3650513          	addi	a0,a0,-1482 # ffffffffc0202030 <commands+0x310>
ffffffffc0200602:	ab1ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200606:	706c                	ld	a1,224(s0)
ffffffffc0200608:	00002517          	auipc	a0,0x2
ffffffffc020060c:	a4050513          	addi	a0,a0,-1472 # ffffffffc0202048 <commands+0x328>
ffffffffc0200610:	aa3ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200614:	746c                	ld	a1,232(s0)
ffffffffc0200616:	00002517          	auipc	a0,0x2
ffffffffc020061a:	a4a50513          	addi	a0,a0,-1462 # ffffffffc0202060 <commands+0x340>
ffffffffc020061e:	a95ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200622:	786c                	ld	a1,240(s0)
ffffffffc0200624:	00002517          	auipc	a0,0x2
ffffffffc0200628:	a5450513          	addi	a0,a0,-1452 # ffffffffc0202078 <commands+0x358>
ffffffffc020062c:	a87ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200630:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200632:	6402                	ld	s0,0(sp)
ffffffffc0200634:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200636:	00002517          	auipc	a0,0x2
ffffffffc020063a:	a5a50513          	addi	a0,a0,-1446 # ffffffffc0202090 <commands+0x370>
}
ffffffffc020063e:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200640:	bc8d                	j	ffffffffc02000b2 <cprintf>

ffffffffc0200642 <print_trapframe>:
{
ffffffffc0200642:	1141                	addi	sp,sp,-16
ffffffffc0200644:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200646:	85aa                	mv	a1,a0
{
ffffffffc0200648:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc020064a:	00002517          	auipc	a0,0x2
ffffffffc020064e:	a5e50513          	addi	a0,a0,-1442 # ffffffffc02020a8 <commands+0x388>
{
ffffffffc0200652:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200654:	a5fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200658:	8522                	mv	a0,s0
ffffffffc020065a:	e1dff0ef          	jal	ra,ffffffffc0200476 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc020065e:	10043583          	ld	a1,256(s0)
ffffffffc0200662:	00002517          	auipc	a0,0x2
ffffffffc0200666:	a5e50513          	addi	a0,a0,-1442 # ffffffffc02020c0 <commands+0x3a0>
ffffffffc020066a:	a49ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc020066e:	10843583          	ld	a1,264(s0)
ffffffffc0200672:	00002517          	auipc	a0,0x2
ffffffffc0200676:	a6650513          	addi	a0,a0,-1434 # ffffffffc02020d8 <commands+0x3b8>
ffffffffc020067a:	a39ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc020067e:	11043583          	ld	a1,272(s0)
ffffffffc0200682:	00002517          	auipc	a0,0x2
ffffffffc0200686:	a6e50513          	addi	a0,a0,-1426 # ffffffffc02020f0 <commands+0x3d0>
ffffffffc020068a:	a29ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020068e:	11843583          	ld	a1,280(s0)
}
ffffffffc0200692:	6402                	ld	s0,0(sp)
ffffffffc0200694:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200696:	00002517          	auipc	a0,0x2
ffffffffc020069a:	a7250513          	addi	a0,a0,-1422 # ffffffffc0202108 <commands+0x3e8>
}
ffffffffc020069e:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02006a0:	bc09                	j	ffffffffc02000b2 <cprintf>

ffffffffc02006a2 <interrupt_handler>:

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc02006a2:	11853783          	ld	a5,280(a0)
ffffffffc02006a6:	472d                	li	a4,11
ffffffffc02006a8:	0786                	slli	a5,a5,0x1
ffffffffc02006aa:	8385                	srli	a5,a5,0x1
ffffffffc02006ac:	06f76e63          	bltu	a4,a5,ffffffffc0200728 <interrupt_handler+0x86>
ffffffffc02006b0:	00002717          	auipc	a4,0x2
ffffffffc02006b4:	b3870713          	addi	a4,a4,-1224 # ffffffffc02021e8 <commands+0x4c8>
ffffffffc02006b8:	078a                	slli	a5,a5,0x2
ffffffffc02006ba:	97ba                	add	a5,a5,a4
ffffffffc02006bc:	439c                	lw	a5,0(a5)
ffffffffc02006be:	97ba                	add	a5,a5,a4
ffffffffc02006c0:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc02006c2:	00002517          	auipc	a0,0x2
ffffffffc02006c6:	abe50513          	addi	a0,a0,-1346 # ffffffffc0202180 <commands+0x460>
ffffffffc02006ca:	b2e5                	j	ffffffffc02000b2 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc02006cc:	00002517          	auipc	a0,0x2
ffffffffc02006d0:	a9450513          	addi	a0,a0,-1388 # ffffffffc0202160 <commands+0x440>
ffffffffc02006d4:	baf9                	j	ffffffffc02000b2 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc02006d6:	00002517          	auipc	a0,0x2
ffffffffc02006da:	a4a50513          	addi	a0,a0,-1462 # ffffffffc0202120 <commands+0x400>
ffffffffc02006de:	bad1                	j	ffffffffc02000b2 <cprintf>
        break;
    case IRQ_U_TIMER:
        cprintf("User Timer interrupt\n");
ffffffffc02006e0:	00002517          	auipc	a0,0x2
ffffffffc02006e4:	ac050513          	addi	a0,a0,-1344 # ffffffffc02021a0 <commands+0x480>
ffffffffc02006e8:	b2e9                	j	ffffffffc02000b2 <cprintf>
{
ffffffffc02006ea:	1141                	addi	sp,sp,-16
ffffffffc02006ec:	e406                	sd	ra,8(sp)
ffffffffc02006ee:	e022                	sd	s0,0(sp)
        // read-only." -- privileged spec1.9.1, 4.1.4, p59
        // In fact, Call sbi_set_timer will clear STIP, or you can clear it
        // directly.
        // cprintf("Supervisor timer interrupt\n");
        // clear_csr(sip, SIP_STIP);
        clock_set_next_event();
ffffffffc02006f0:	d4bff0ef          	jal	ra,ffffffffc020043a <clock_set_next_event>
        ticks++;
ffffffffc02006f4:	00006797          	auipc	a5,0x6
ffffffffc02006f8:	e2c78793          	addi	a5,a5,-468 # ffffffffc0206520 <ticks>
ffffffffc02006fc:	6398                	ld	a4,0(a5)
        if (ticks == 100)
ffffffffc02006fe:	06400693          	li	a3,100
        ticks++;
ffffffffc0200702:	0705                	addi	a4,a4,1
ffffffffc0200704:	e398                	sd	a4,0(a5)
        if (ticks == 100)
ffffffffc0200706:	639c                	ld	a5,0(a5)
ffffffffc0200708:	02d78163          	beq	a5,a3,ffffffffc020072a <interrupt_handler+0x88>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc020070c:	60a2                	ld	ra,8(sp)
ffffffffc020070e:	6402                	ld	s0,0(sp)
ffffffffc0200710:	0141                	addi	sp,sp,16
ffffffffc0200712:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200714:	00002517          	auipc	a0,0x2
ffffffffc0200718:	ab450513          	addi	a0,a0,-1356 # ffffffffc02021c8 <commands+0x4a8>
ffffffffc020071c:	ba59                	j	ffffffffc02000b2 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc020071e:	00002517          	auipc	a0,0x2
ffffffffc0200722:	a2250513          	addi	a0,a0,-1502 # ffffffffc0202140 <commands+0x420>
ffffffffc0200726:	b271                	j	ffffffffc02000b2 <cprintf>
        print_trapframe(tf);
ffffffffc0200728:	bf29                	j	ffffffffc0200642 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc020072a:	06400593          	li	a1,100
ffffffffc020072e:	00002517          	auipc	a0,0x2
ffffffffc0200732:	a8a50513          	addi	a0,a0,-1398 # ffffffffc02021b8 <commands+0x498>
            ticks = 0;
ffffffffc0200736:	00006797          	auipc	a5,0x6
ffffffffc020073a:	de07b523          	sd	zero,-534(a5) # ffffffffc0206520 <ticks>
            if (num == 10)
ffffffffc020073e:	00006417          	auipc	s0,0x6
ffffffffc0200742:	dea40413          	addi	s0,s0,-534 # ffffffffc0206528 <num>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200746:	96dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
            if (num == 10)
ffffffffc020074a:	6018                	ld	a4,0(s0)
ffffffffc020074c:	47a9                	li	a5,10
ffffffffc020074e:	00f70663          	beq	a4,a5,ffffffffc020075a <interrupt_handler+0xb8>
            num++;
ffffffffc0200752:	601c                	ld	a5,0(s0)
ffffffffc0200754:	0785                	addi	a5,a5,1
ffffffffc0200756:	e01c                	sd	a5,0(s0)
ffffffffc0200758:	bf55                	j	ffffffffc020070c <interrupt_handler+0x6a>
                sbi_shutdown();
ffffffffc020075a:	2f0010ef          	jal	ra,ffffffffc0201a4a <sbi_shutdown>
ffffffffc020075e:	bfd5                	j	ffffffffc0200752 <interrupt_handler+0xb0>

ffffffffc0200760 <trap>:
    }
}

static inline void trap_dispatch(struct trapframe *tf)
{
    if ((intptr_t)tf->cause < 0)
ffffffffc0200760:	11853783          	ld	a5,280(a0)
ffffffffc0200764:	0007c763          	bltz	a5,ffffffffc0200772 <trap+0x12>
    switch (tf->cause)
ffffffffc0200768:	472d                	li	a4,11
ffffffffc020076a:	00f76363          	bltu	a4,a5,ffffffffc0200770 <trap+0x10>
 * */
void trap(struct trapframe *tf)
{
    // dispatch based on what type of trap occurred
    trap_dispatch(tf);
}
ffffffffc020076e:	8082                	ret
        print_trapframe(tf);
ffffffffc0200770:	bdc9                	j	ffffffffc0200642 <print_trapframe>
        interrupt_handler(tf);
ffffffffc0200772:	bf05                	j	ffffffffc02006a2 <interrupt_handler>

ffffffffc0200774 <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc0200774:	14011073          	csrw	sscratch,sp
ffffffffc0200778:	712d                	addi	sp,sp,-288
ffffffffc020077a:	e002                	sd	zero,0(sp)
ffffffffc020077c:	e406                	sd	ra,8(sp)
ffffffffc020077e:	ec0e                	sd	gp,24(sp)
ffffffffc0200780:	f012                	sd	tp,32(sp)
ffffffffc0200782:	f416                	sd	t0,40(sp)
ffffffffc0200784:	f81a                	sd	t1,48(sp)
ffffffffc0200786:	fc1e                	sd	t2,56(sp)
ffffffffc0200788:	e0a2                	sd	s0,64(sp)
ffffffffc020078a:	e4a6                	sd	s1,72(sp)
ffffffffc020078c:	e8aa                	sd	a0,80(sp)
ffffffffc020078e:	ecae                	sd	a1,88(sp)
ffffffffc0200790:	f0b2                	sd	a2,96(sp)
ffffffffc0200792:	f4b6                	sd	a3,104(sp)
ffffffffc0200794:	f8ba                	sd	a4,112(sp)
ffffffffc0200796:	fcbe                	sd	a5,120(sp)
ffffffffc0200798:	e142                	sd	a6,128(sp)
ffffffffc020079a:	e546                	sd	a7,136(sp)
ffffffffc020079c:	e94a                	sd	s2,144(sp)
ffffffffc020079e:	ed4e                	sd	s3,152(sp)
ffffffffc02007a0:	f152                	sd	s4,160(sp)
ffffffffc02007a2:	f556                	sd	s5,168(sp)
ffffffffc02007a4:	f95a                	sd	s6,176(sp)
ffffffffc02007a6:	fd5e                	sd	s7,184(sp)
ffffffffc02007a8:	e1e2                	sd	s8,192(sp)
ffffffffc02007aa:	e5e6                	sd	s9,200(sp)
ffffffffc02007ac:	e9ea                	sd	s10,208(sp)
ffffffffc02007ae:	edee                	sd	s11,216(sp)
ffffffffc02007b0:	f1f2                	sd	t3,224(sp)
ffffffffc02007b2:	f5f6                	sd	t4,232(sp)
ffffffffc02007b4:	f9fa                	sd	t5,240(sp)
ffffffffc02007b6:	fdfe                	sd	t6,248(sp)
ffffffffc02007b8:	14001473          	csrrw	s0,sscratch,zero
ffffffffc02007bc:	100024f3          	csrr	s1,sstatus
ffffffffc02007c0:	14102973          	csrr	s2,sepc
ffffffffc02007c4:	143029f3          	csrr	s3,stval
ffffffffc02007c8:	14202a73          	csrr	s4,scause
ffffffffc02007cc:	e822                	sd	s0,16(sp)
ffffffffc02007ce:	e226                	sd	s1,256(sp)
ffffffffc02007d0:	e64a                	sd	s2,264(sp)
ffffffffc02007d2:	ea4e                	sd	s3,272(sp)
ffffffffc02007d4:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc02007d6:	850a                	mv	a0,sp
    jal trap
ffffffffc02007d8:	f89ff0ef          	jal	ra,ffffffffc0200760 <trap>

ffffffffc02007dc <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc02007dc:	6492                	ld	s1,256(sp)
ffffffffc02007de:	6932                	ld	s2,264(sp)
ffffffffc02007e0:	10049073          	csrw	sstatus,s1
ffffffffc02007e4:	14191073          	csrw	sepc,s2
ffffffffc02007e8:	60a2                	ld	ra,8(sp)
ffffffffc02007ea:	61e2                	ld	gp,24(sp)
ffffffffc02007ec:	7202                	ld	tp,32(sp)
ffffffffc02007ee:	72a2                	ld	t0,40(sp)
ffffffffc02007f0:	7342                	ld	t1,48(sp)
ffffffffc02007f2:	73e2                	ld	t2,56(sp)
ffffffffc02007f4:	6406                	ld	s0,64(sp)
ffffffffc02007f6:	64a6                	ld	s1,72(sp)
ffffffffc02007f8:	6546                	ld	a0,80(sp)
ffffffffc02007fa:	65e6                	ld	a1,88(sp)
ffffffffc02007fc:	7606                	ld	a2,96(sp)
ffffffffc02007fe:	76a6                	ld	a3,104(sp)
ffffffffc0200800:	7746                	ld	a4,112(sp)
ffffffffc0200802:	77e6                	ld	a5,120(sp)
ffffffffc0200804:	680a                	ld	a6,128(sp)
ffffffffc0200806:	68aa                	ld	a7,136(sp)
ffffffffc0200808:	694a                	ld	s2,144(sp)
ffffffffc020080a:	69ea                	ld	s3,152(sp)
ffffffffc020080c:	7a0a                	ld	s4,160(sp)
ffffffffc020080e:	7aaa                	ld	s5,168(sp)
ffffffffc0200810:	7b4a                	ld	s6,176(sp)
ffffffffc0200812:	7bea                	ld	s7,184(sp)
ffffffffc0200814:	6c0e                	ld	s8,192(sp)
ffffffffc0200816:	6cae                	ld	s9,200(sp)
ffffffffc0200818:	6d4e                	ld	s10,208(sp)
ffffffffc020081a:	6dee                	ld	s11,216(sp)
ffffffffc020081c:	7e0e                	ld	t3,224(sp)
ffffffffc020081e:	7eae                	ld	t4,232(sp)
ffffffffc0200820:	7f4e                	ld	t5,240(sp)
ffffffffc0200822:	7fee                	ld	t6,248(sp)
ffffffffc0200824:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200826:	10200073          	sret

ffffffffc020082a <buddy_system_init>:

static void
buddy_system_init(void)
{
    // 初始化伙伴堆链表数组中的每个free_list头
    for (int i = 0; i < MAX_BUDDY_ORDER + 1; i++)
ffffffffc020082a:	00005797          	auipc	a5,0x5
ffffffffc020082e:	7f678793          	addi	a5,a5,2038 # ffffffffc0206020 <buddy_s+0x8>
ffffffffc0200832:	00006717          	auipc	a4,0x6
ffffffffc0200836:	8de70713          	addi	a4,a4,-1826 # ffffffffc0206110 <buddy_s+0xf8>
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm)
{
    elm->prev = elm->next = elm;
ffffffffc020083a:	e79c                	sd	a5,8(a5)
ffffffffc020083c:	e39c                	sd	a5,0(a5)
ffffffffc020083e:	07c1                	addi	a5,a5,16
ffffffffc0200840:	fee79de3          	bne	a5,a4,ffffffffc020083a <buddy_system_init+0x10>
    {
        list_init(buddy_array + i);
    }
    max_order = 0;
ffffffffc0200844:	00005797          	auipc	a5,0x5
ffffffffc0200848:	7c07aa23          	sw	zero,2004(a5) # ffffffffc0206018 <buddy_s>
    nr_free = 0;
ffffffffc020084c:	00006797          	auipc	a5,0x6
ffffffffc0200850:	8c07a223          	sw	zero,-1852(a5) # ffffffffc0206110 <buddy_s+0xf8>
    return;
}
ffffffffc0200854:	8082                	ret

ffffffffc0200856 <buddy_system_nr_free_pages>:

static size_t
buddy_system_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0200856:	00006517          	auipc	a0,0x6
ffffffffc020085a:	8ba56503          	lwu	a0,-1862(a0) # ffffffffc0206110 <buddy_s+0xf8>
ffffffffc020085e:	8082                	ret

ffffffffc0200860 <buddy_system_init_memmap>:
{
ffffffffc0200860:	1141                	addi	sp,sp,-16
ffffffffc0200862:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200864:	c9cd                	beqz	a1,ffffffffc0200916 <buddy_system_init_memmap+0xb6>
    if (n & (n - 1))
ffffffffc0200866:	fff58793          	addi	a5,a1,-1
ffffffffc020086a:	8fed                	and	a5,a5,a1
ffffffffc020086c:	c799                	beqz	a5,ffffffffc020087a <buddy_system_init_memmap+0x1a>
ffffffffc020086e:	4785                	li	a5,1
            n = n >> 1;
ffffffffc0200870:	8185                	srli	a1,a1,0x1
            res = res << 1;
ffffffffc0200872:	0786                	slli	a5,a5,0x1
        while (n)
ffffffffc0200874:	fdf5                	bnez	a1,ffffffffc0200870 <buddy_system_init_memmap+0x10>
        return res >> 1;
ffffffffc0200876:	0017d593          	srli	a1,a5,0x1
    while (n >> 1)
ffffffffc020087a:	0015d793          	srli	a5,a1,0x1
    unsigned int order = 0;
ffffffffc020087e:	4601                	li	a2,0
    while (n >> 1)
ffffffffc0200880:	c781                	beqz	a5,ffffffffc0200888 <buddy_system_init_memmap+0x28>
ffffffffc0200882:	8385                	srli	a5,a5,0x1
        order++;
ffffffffc0200884:	2605                	addiw	a2,a2,1
    while (n >> 1)
ffffffffc0200886:	fff5                	bnez	a5,ffffffffc0200882 <buddy_system_init_memmap+0x22>
    for (; p != base + pnum; p++)
ffffffffc0200888:	00259693          	slli	a3,a1,0x2
ffffffffc020088c:	96ae                	add	a3,a3,a1
ffffffffc020088e:	068e                	slli	a3,a3,0x3
ffffffffc0200890:	96aa                	add	a3,a3,a0
ffffffffc0200892:	02a68163          	beq	a3,a0,ffffffffc02008b4 <buddy_system_init_memmap+0x54>
ffffffffc0200896:	87aa                	mv	a5,a0
        p->property = -1; // 全部初始化为非头页
ffffffffc0200898:	587d                	li	a6,-1
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr)
{
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020089a:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc020089c:	8b05                	andi	a4,a4,1
ffffffffc020089e:	cf21                	beqz	a4,ffffffffc02008f6 <buddy_system_init_memmap+0x96>
        p->flags = 0;     // 清除所有flag标记
ffffffffc02008a0:	0007b423          	sd	zero,8(a5)
        p->property = -1; // 全部初始化为非头页
ffffffffc02008a4:	0107a823          	sw	a6,16(a5)

//获取 Page 结构体中的 ref 成员，即页面的引用计数。
static inline int page_ref(struct Page *page) { return page->ref; }

//设置 Page 结构体中的 ref 成员，即页面的引用计数
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02008a8:	0007a023          	sw	zero,0(a5)
    for (; p != base + pnum; p++)
ffffffffc02008ac:	02878793          	addi	a5,a5,40
ffffffffc02008b0:	fef695e3          	bne	a3,a5,ffffffffc020089a <buddy_system_init_memmap+0x3a>
 * is already in the list.
 * */
static inline void
list_add_after(list_entry_t *listelm, list_entry_t *elm)
{
    __list_add(elm, listelm, listelm->next);
ffffffffc02008b4:	02061693          	slli	a3,a2,0x20
    max_order = order;
ffffffffc02008b8:	00005797          	auipc	a5,0x5
ffffffffc02008bc:	76078793          	addi	a5,a5,1888 # ffffffffc0206018 <buddy_s>
ffffffffc02008c0:	01c6d713          	srli	a4,a3,0x1c
ffffffffc02008c4:	00e78833          	add	a6,a5,a4
ffffffffc02008c8:	01083683          	ld	a3,16(a6)
    nr_free = pnum;
ffffffffc02008cc:	0eb7ac23          	sw	a1,248(a5)
    max_order = order;
ffffffffc02008d0:	c390                	sw	a2,0(a5)
    list_add(&(buddy_array[max_order]), &(base->page_link)); // 将第一页base插入数组的最后一个链表，作为初始化的最大块的头页
ffffffffc02008d2:	01850593          	addi	a1,a0,24
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next)
{
    // prev: 新节点 elm 的前一个节点。
    // next: 新节点 elm 的后一个节点。
    prev->next = next->prev = elm;
ffffffffc02008d6:	e28c                	sd	a1,0(a3)
ffffffffc02008d8:	0721                	addi	a4,a4,8
ffffffffc02008da:	00b83823          	sd	a1,16(a6)
ffffffffc02008de:	97ba                	add	a5,a5,a4
    elm->next = next;
    elm->prev = prev;
ffffffffc02008e0:	ed1c                	sd	a5,24(a0)
    elm->next = next;
ffffffffc02008e2:	f114                	sd	a3,32(a0)
    base->property = max_order; // 将第一页base的property设为最大块的2幂
ffffffffc02008e4:	c910                	sw	a2,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02008e6:	4789                	li	a5,2
ffffffffc02008e8:	00850713          	addi	a4,a0,8
ffffffffc02008ec:	40f7302f          	amoor.d	zero,a5,(a4)
}
ffffffffc02008f0:	60a2                	ld	ra,8(sp)
ffffffffc02008f2:	0141                	addi	sp,sp,16
ffffffffc02008f4:	8082                	ret
        assert(PageReserved(p));
ffffffffc02008f6:	00002697          	auipc	a3,0x2
ffffffffc02008fa:	96268693          	addi	a3,a3,-1694 # ffffffffc0202258 <commands+0x538>
ffffffffc02008fe:	00002617          	auipc	a2,0x2
ffffffffc0200902:	92260613          	addi	a2,a2,-1758 # ffffffffc0202220 <commands+0x500>
ffffffffc0200906:	09b00593          	li	a1,155
ffffffffc020090a:	00002517          	auipc	a0,0x2
ffffffffc020090e:	92e50513          	addi	a0,a0,-1746 # ffffffffc0202238 <commands+0x518>
ffffffffc0200912:	a9bff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(n > 0);
ffffffffc0200916:	00002697          	auipc	a3,0x2
ffffffffc020091a:	90268693          	addi	a3,a3,-1790 # ffffffffc0202218 <commands+0x4f8>
ffffffffc020091e:	00002617          	auipc	a2,0x2
ffffffffc0200922:	90260613          	addi	a2,a2,-1790 # ffffffffc0202220 <commands+0x500>
ffffffffc0200926:	09200593          	li	a1,146
ffffffffc020092a:	00002517          	auipc	a0,0x2
ffffffffc020092e:	90e50513          	addi	a0,a0,-1778 # ffffffffc0202238 <commands+0x518>
ffffffffc0200932:	a7bff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200936 <buddy_system_free_pages>:
{
ffffffffc0200936:	1101                	addi	sp,sp,-32
ffffffffc0200938:	ec06                	sd	ra,24(sp)
ffffffffc020093a:	e822                	sd	s0,16(sp)
ffffffffc020093c:	e426                	sd	s1,8(sp)
    assert(n > 0);
ffffffffc020093e:	16058563          	beqz	a1,ffffffffc0200aa8 <buddy_system_free_pages+0x172>
    unsigned int pnum = 1 << (base->property); // 块中页的数目
ffffffffc0200942:	4918                	lw	a4,16(a0)
    if (n & (n - 1))
ffffffffc0200944:	fff58793          	addi	a5,a1,-1
    unsigned int pnum = 1 << (base->property); // 块中页的数目
ffffffffc0200948:	4485                	li	s1,1
ffffffffc020094a:	00e494bb          	sllw	s1,s1,a4
    if (n & (n - 1))
ffffffffc020094e:	8fed                	and	a5,a5,a1
ffffffffc0200950:	842a                	mv	s0,a0
    unsigned int pnum = 1 << (base->property); // 块中页的数目
ffffffffc0200952:	0004861b          	sext.w	a2,s1
    if (n & (n - 1))
ffffffffc0200956:	14079363          	bnez	a5,ffffffffc0200a9c <buddy_system_free_pages+0x166>
    assert(ROUNDUP2(n) == pnum);
ffffffffc020095a:	02049793          	slli	a5,s1,0x20
ffffffffc020095e:	9381                	srli	a5,a5,0x20
ffffffffc0200960:	16b79463          	bne	a5,a1,ffffffffc0200ac8 <buddy_system_free_pages+0x192>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; } 
ffffffffc0200964:	00006797          	auipc	a5,0x6
ffffffffc0200968:	bd47b783          	ld	a5,-1068(a5) # ffffffffc0206538 <pages>
ffffffffc020096c:	40f407b3          	sub	a5,s0,a5
ffffffffc0200970:	00002597          	auipc	a1,0x2
ffffffffc0200974:	4285b583          	ld	a1,1064(a1) # ffffffffc0202d98 <error_string+0x38>
ffffffffc0200978:	878d                	srai	a5,a5,0x3
ffffffffc020097a:	02b787b3          	mul	a5,a5,a1
    cprintf("buddy system will release from Page NO.%d total %d Pages\n", page2ppn(base), pnum);
ffffffffc020097e:	00002597          	auipc	a1,0x2
ffffffffc0200982:	4225b583          	ld	a1,1058(a1) # ffffffffc0202da0 <nbase>
ffffffffc0200986:	00002517          	auipc	a0,0x2
ffffffffc020098a:	8fa50513          	addi	a0,a0,-1798 # ffffffffc0202280 <commands+0x560>
ffffffffc020098e:	95be                	add	a1,a1,a5
ffffffffc0200990:	f22ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    list_add(&(buddy_array[left_block->property]), &(left_block->page_link)); // 将当前块先插入对应链表中
ffffffffc0200994:	4810                	lw	a2,16(s0)
    size_t real_block_size = 1 << block_size;                    // 幂次转换成数
ffffffffc0200996:	4785                	li	a5,1
    size_t relative_block_addr = (size_t)block_addr - mem_begin; // 计算相对于初始化的第一个页的偏移量
ffffffffc0200998:	3fdf1eb7          	lui	t4,0x3fdf1
    size_t real_block_size = 1 << block_size;                    // 幂次转换成数
ffffffffc020099c:	00c7973b          	sllw	a4,a5,a2
    size_t sizeOfPage = real_block_size * sizeof(struct Page);                  // sizeof(struct Page)是0x28
ffffffffc02009a0:	00271793          	slli	a5,a4,0x2
    size_t relative_block_addr = (size_t)block_addr - mem_begin; // 计算相对于初始化的第一个页的偏移量
ffffffffc02009a4:	ce8e8e93          	addi	t4,t4,-792 # 3fdf0ce8 <kern_entry-0xffffffff8040f318>
    size_t sizeOfPage = real_block_size * sizeof(struct Page);                  // sizeof(struct Page)是0x28
ffffffffc02009a8:	97ba                	add	a5,a5,a4
    __list_add(elm, listelm, listelm->next);
ffffffffc02009aa:	02061693          	slli	a3,a2,0x20
ffffffffc02009ae:	01c6d713          	srli	a4,a3,0x1c
ffffffffc02009b2:	00005897          	auipc	a7,0x5
ffffffffc02009b6:	66688893          	addi	a7,a7,1638 # ffffffffc0206018 <buddy_s>
    size_t relative_block_addr = (size_t)block_addr - mem_begin; // 计算相对于初始化的第一个页的偏移量
ffffffffc02009ba:	01d406b3          	add	a3,s0,t4
    size_t sizeOfPage = real_block_size * sizeof(struct Page);                  // sizeof(struct Page)是0x28
ffffffffc02009be:	078e                	slli	a5,a5,0x3
ffffffffc02009c0:	00e88533          	add	a0,a7,a4
    size_t buddy_relative_addr = (size_t)relative_block_addr ^ sizeOfPage;      // 异或得到伙伴块的相对地址
ffffffffc02009c4:	8fb5                	xor	a5,a5,a3
ffffffffc02009c6:	690c                	ld	a1,16(a0)
    struct Page *buddy_page = (struct Page *)(buddy_relative_addr + mem_begin); // 返回伙伴块指针
ffffffffc02009c8:	41d787b3          	sub	a5,a5,t4
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02009cc:	6794                	ld	a3,8(a5)
    list_add(&(buddy_array[left_block->property]), &(left_block->page_link)); // 将当前块先插入对应链表中
ffffffffc02009ce:	01840813          	addi	a6,s0,24
    prev->next = next->prev = elm;
ffffffffc02009d2:	0105b023          	sd	a6,0(a1)
ffffffffc02009d6:	0721                	addi	a4,a4,8
ffffffffc02009d8:	01053823          	sd	a6,16(a0)
ffffffffc02009dc:	9746                	add	a4,a4,a7
ffffffffc02009de:	8285                	srli	a3,a3,0x1
    elm->prev = prev;
ffffffffc02009e0:	ec18                	sd	a4,24(s0)
    elm->next = next;
ffffffffc02009e2:	f00c                	sd	a1,32(s0)
    while (PageProperty(buddy) && left_block->property < max_order)
ffffffffc02009e4:	0016f713          	andi	a4,a3,1
            left_block->property = -1; // 将左块幂次置为无效
ffffffffc02009e8:	5ffd                	li	t6,-1
    while (PageProperty(buddy) && left_block->property < max_order)
ffffffffc02009ea:	86a2                	mv	a3,s0
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02009ec:	4f09                	li	t5,2
    size_t real_block_size = 1 << block_size;                    // 幂次转换成数
ffffffffc02009ee:	4505                	li	a0,1
    while (PageProperty(buddy) && left_block->property < max_order)
ffffffffc02009f0:	e359                	bnez	a4,ffffffffc0200a76 <buddy_system_free_pages+0x140>
ffffffffc02009f2:	a071                	j	ffffffffc0200a7e <buddy_system_free_pages+0x148>
        if (left_block > buddy)
ffffffffc02009f4:	00d7fc63          	bgeu	a5,a3,ffffffffc0200a0c <buddy_system_free_pages+0xd6>
            left_block->property = -1; // 将左块幂次置为无效
ffffffffc02009f8:	01f6a823          	sw	t6,16(a3)
ffffffffc02009fc:	00840713          	addi	a4,s0,8
ffffffffc0200a00:	41e7302f          	amoor.d	zero,t5,(a4)
        left_block->property += 1; // 左快头页设置幂次加一
ffffffffc0200a04:	8736                	mv	a4,a3
ffffffffc0200a06:	4b90                	lw	a2,16(a5)
ffffffffc0200a08:	86be                	mv	a3,a5
ffffffffc0200a0a:	87ba                	mv	a5,a4
    __list_del(listelm->prev, listelm->next);
ffffffffc0200a0c:	0186b803          	ld	a6,24(a3)
ffffffffc0200a10:	728c                	ld	a1,32(a3)
ffffffffc0200a12:	2605                	addiw	a2,a2,1
    size_t real_block_size = 1 << block_size;                    // 幂次转换成数
ffffffffc0200a14:	00c5173b          	sllw	a4,a0,a2
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next)
{
    prev->next = next;
ffffffffc0200a18:	00b83423          	sd	a1,8(a6)
    next->prev = prev;
ffffffffc0200a1c:	0105b023          	sd	a6,0(a1)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200a20:	0187b303          	ld	t1,24(a5)
ffffffffc0200a24:	0207b803          	ld	a6,32(a5)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200a28:	02061e13          	slli	t3,a2,0x20
    size_t sizeOfPage = real_block_size * sizeof(struct Page);                  // sizeof(struct Page)是0x28
ffffffffc0200a2c:	00271793          	slli	a5,a4,0x2
    prev->next = next;
ffffffffc0200a30:	01033423          	sd	a6,8(t1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200a34:	01ce5593          	srli	a1,t3,0x1c
ffffffffc0200a38:	97ba                	add	a5,a5,a4
    next->prev = prev;
ffffffffc0200a3a:	00683023          	sd	t1,0(a6)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200a3e:	00b88e33          	add	t3,a7,a1
ffffffffc0200a42:	00379713          	slli	a4,a5,0x3
    size_t relative_block_addr = (size_t)block_addr - mem_begin; // 计算相对于初始化的第一个页的偏移量
ffffffffc0200a46:	01d687b3          	add	a5,a3,t4
ffffffffc0200a4a:	010e3303          	ld	t1,16(t3)
    size_t buddy_relative_addr = (size_t)relative_block_addr ^ sizeOfPage;      // 异或得到伙伴块的相对地址
ffffffffc0200a4e:	8fb9                	xor	a5,a5,a4
    struct Page *buddy_page = (struct Page *)(buddy_relative_addr + mem_begin); // 返回伙伴块指针
ffffffffc0200a50:	41d787b3          	sub	a5,a5,t4
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200a54:	0087b803          	ld	a6,8(a5)
        list_add(&(buddy_array[left_block->property]), &(left_block->page_link)); // 头插入相应链表
ffffffffc0200a58:	01868713          	addi	a4,a3,24
        left_block->property += 1; // 左快头页设置幂次加一
ffffffffc0200a5c:	ca90                	sw	a2,16(a3)
    prev->next = next->prev = elm;
ffffffffc0200a5e:	00e33023          	sd	a4,0(t1)
        list_add(&(buddy_array[left_block->property]), &(left_block->page_link)); // 头插入相应链表
ffffffffc0200a62:	05a1                	addi	a1,a1,8
ffffffffc0200a64:	00ee3823          	sd	a4,16(t3)
ffffffffc0200a68:	95c6                	add	a1,a1,a7
    elm->next = next;
ffffffffc0200a6a:	0266b023          	sd	t1,32(a3)
    elm->prev = prev;
ffffffffc0200a6e:	ee8c                	sd	a1,24(a3)
    while (PageProperty(buddy) && left_block->property < max_order)
ffffffffc0200a70:	00287713          	andi	a4,a6,2
ffffffffc0200a74:	c709                	beqz	a4,ffffffffc0200a7e <buddy_system_free_pages+0x148>
ffffffffc0200a76:	0008a703          	lw	a4,0(a7)
ffffffffc0200a7a:	f6e66de3          	bltu	a2,a4,ffffffffc02009f4 <buddy_system_free_pages+0xbe>
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200a7e:	4789                	li	a5,2
ffffffffc0200a80:	00868713          	addi	a4,a3,8
ffffffffc0200a84:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += pnum;
ffffffffc0200a88:	0f88a783          	lw	a5,248(a7)
}
ffffffffc0200a8c:	60e2                	ld	ra,24(sp)
ffffffffc0200a8e:	6442                	ld	s0,16(sp)
    nr_free += pnum;
ffffffffc0200a90:	9cbd                	addw	s1,s1,a5
ffffffffc0200a92:	0e98ac23          	sw	s1,248(a7)
}
ffffffffc0200a96:	64a2                	ld	s1,8(sp)
ffffffffc0200a98:	6105                	addi	sp,sp,32
ffffffffc0200a9a:	8082                	ret
ffffffffc0200a9c:	4785                	li	a5,1
            n = n >> 1;
ffffffffc0200a9e:	8185                	srli	a1,a1,0x1
            res = res << 1;
ffffffffc0200aa0:	0786                	slli	a5,a5,0x1
        while (n)
ffffffffc0200aa2:	fdf5                	bnez	a1,ffffffffc0200a9e <buddy_system_free_pages+0x168>
            res = res << 1;
ffffffffc0200aa4:	85be                	mv	a1,a5
ffffffffc0200aa6:	bd55                	j	ffffffffc020095a <buddy_system_free_pages+0x24>
    assert(n > 0);
ffffffffc0200aa8:	00001697          	auipc	a3,0x1
ffffffffc0200aac:	77068693          	addi	a3,a3,1904 # ffffffffc0202218 <commands+0x4f8>
ffffffffc0200ab0:	00001617          	auipc	a2,0x1
ffffffffc0200ab4:	77060613          	addi	a2,a2,1904 # ffffffffc0202220 <commands+0x500>
ffffffffc0200ab8:	0ed00593          	li	a1,237
ffffffffc0200abc:	00001517          	auipc	a0,0x1
ffffffffc0200ac0:	77c50513          	addi	a0,a0,1916 # ffffffffc0202238 <commands+0x518>
ffffffffc0200ac4:	8e9ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(ROUNDUP2(n) == pnum);
ffffffffc0200ac8:	00001697          	auipc	a3,0x1
ffffffffc0200acc:	7a068693          	addi	a3,a3,1952 # ffffffffc0202268 <commands+0x548>
ffffffffc0200ad0:	00001617          	auipc	a2,0x1
ffffffffc0200ad4:	75060613          	addi	a2,a2,1872 # ffffffffc0202220 <commands+0x500>
ffffffffc0200ad8:	0ef00593          	li	a1,239
ffffffffc0200adc:	00001517          	auipc	a0,0x1
ffffffffc0200ae0:	75c50513          	addi	a0,a0,1884 # ffffffffc0202238 <commands+0x518>
ffffffffc0200ae4:	8c9ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200ae8 <show_buddy_array.constprop.0>:
show_buddy_array(int left, int right) // 左闭右闭
ffffffffc0200ae8:	711d                	addi	sp,sp,-96
ffffffffc0200aea:	ec86                	sd	ra,88(sp)
ffffffffc0200aec:	e8a2                	sd	s0,80(sp)
ffffffffc0200aee:	e4a6                	sd	s1,72(sp)
ffffffffc0200af0:	e0ca                	sd	s2,64(sp)
ffffffffc0200af2:	fc4e                	sd	s3,56(sp)
ffffffffc0200af4:	f852                	sd	s4,48(sp)
ffffffffc0200af6:	f456                	sd	s5,40(sp)
ffffffffc0200af8:	f05a                	sd	s6,32(sp)
ffffffffc0200afa:	ec5e                	sd	s7,24(sp)
ffffffffc0200afc:	e862                	sd	s8,16(sp)
ffffffffc0200afe:	e466                	sd	s9,8(sp)
ffffffffc0200b00:	e06a                	sd	s10,0(sp)
    assert(left >= 0 && left <= max_order && right >= 0 && right <= max_order);
ffffffffc0200b02:	00005717          	auipc	a4,0x5
ffffffffc0200b06:	51672703          	lw	a4,1302(a4) # ffffffffc0206018 <buddy_s>
ffffffffc0200b0a:	47b5                	li	a5,13
ffffffffc0200b0c:	0ce7f263          	bgeu	a5,a4,ffffffffc0200bd0 <show_buddy_array.constprop.0+0xe8>
    cprintf("==================taking on free_list==================\n");
ffffffffc0200b10:	00001517          	auipc	a0,0x1
ffffffffc0200b14:	7f850513          	addi	a0,a0,2040 # ffffffffc0202308 <commands+0x5e8>
ffffffffc0200b18:	d9aff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    for (int i = left; i <= right; i++)
ffffffffc0200b1c:	00005497          	auipc	s1,0x5
ffffffffc0200b20:	50448493          	addi	s1,s1,1284 # ffffffffc0206020 <buddy_s+0x8>
    bool empty = 1; // 表示空闲链表数组为空
ffffffffc0200b24:	4c05                	li	s8,1
    for (int i = left; i <= right; i++)
ffffffffc0200b26:	4901                	li	s2,0
                cprintf("No.%d free_list", i);
ffffffffc0200b28:	00002b17          	auipc	s6,0x2
ffffffffc0200b2c:	820b0b13          	addi	s6,s6,-2016 # ffffffffc0202348 <commands+0x628>
                cprintf("%d page ", 1 << (p->property));
ffffffffc0200b30:	4a85                	li	s5,1
ffffffffc0200b32:	00002a17          	auipc	s4,0x2
ffffffffc0200b36:	826a0a13          	addi	s4,s4,-2010 # ffffffffc0202358 <commands+0x638>
                cprintf("【address: %p】\n", p);
ffffffffc0200b3a:	00002997          	auipc	s3,0x2
ffffffffc0200b3e:	82e98993          	addi	s3,s3,-2002 # ffffffffc0202368 <commands+0x648>
            if (i != right)
ffffffffc0200b42:	4cb9                	li	s9,14
                cprintf("\n");
ffffffffc0200b44:	00002d17          	auipc	s10,0x2
ffffffffc0200b48:	d6cd0d13          	addi	s10,s10,-660 # ffffffffc02028b0 <buddy_system_pmm_manager+0xd8>
    for (int i = left; i <= right; i++)
ffffffffc0200b4c:	4bbd                	li	s7,15
ffffffffc0200b4e:	a029                	j	ffffffffc0200b58 <show_buddy_array.constprop.0+0x70>
ffffffffc0200b50:	2905                	addiw	s2,s2,1
ffffffffc0200b52:	04c1                	addi	s1,s1,16
ffffffffc0200b54:	05790263          	beq	s2,s7,ffffffffc0200b98 <show_buddy_array.constprop.0+0xb0>
    return listelm->next;
ffffffffc0200b58:	6480                	ld	s0,8(s1)
        if (list_next(le) != &buddy_array[i])
ffffffffc0200b5a:	fe848be3          	beq	s1,s0,ffffffffc0200b50 <show_buddy_array.constprop.0+0x68>
                cprintf("No.%d free_list", i);
ffffffffc0200b5e:	85ca                	mv	a1,s2
ffffffffc0200b60:	855a                	mv	a0,s6
ffffffffc0200b62:	d50ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
                cprintf("%d page ", 1 << (p->property));
ffffffffc0200b66:	ff842583          	lw	a1,-8(s0)
ffffffffc0200b6a:	8552                	mv	a0,s4
ffffffffc0200b6c:	00ba95bb          	sllw	a1,s5,a1
ffffffffc0200b70:	d42ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
                cprintf("【address: %p】\n", p);
ffffffffc0200b74:	fe840593          	addi	a1,s0,-24
ffffffffc0200b78:	854e                	mv	a0,s3
ffffffffc0200b7a:	d38ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200b7e:	6400                	ld	s0,8(s0)
            while ((le = list_next(le)) != &buddy_array[i])
ffffffffc0200b80:	fc941fe3          	bne	s0,s1,ffffffffc0200b5e <show_buddy_array.constprop.0+0x76>
            empty = 0;
ffffffffc0200b84:	4c01                	li	s8,0
            if (i != right)
ffffffffc0200b86:	fd9905e3          	beq	s2,s9,ffffffffc0200b50 <show_buddy_array.constprop.0+0x68>
                cprintf("\n");
ffffffffc0200b8a:	856a                	mv	a0,s10
    for (int i = left; i <= right; i++)
ffffffffc0200b8c:	2905                	addiw	s2,s2,1
                cprintf("\n");
ffffffffc0200b8e:	d24ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    for (int i = left; i <= right; i++)
ffffffffc0200b92:	04c1                	addi	s1,s1,16
ffffffffc0200b94:	fd7912e3          	bne	s2,s7,ffffffffc0200b58 <show_buddy_array.constprop.0+0x70>
    if (empty)
ffffffffc0200b98:	020c1563          	bnez	s8,ffffffffc0200bc2 <show_buddy_array.constprop.0+0xda>
}
ffffffffc0200b9c:	6446                	ld	s0,80(sp)
ffffffffc0200b9e:	60e6                	ld	ra,88(sp)
ffffffffc0200ba0:	64a6                	ld	s1,72(sp)
ffffffffc0200ba2:	6906                	ld	s2,64(sp)
ffffffffc0200ba4:	79e2                	ld	s3,56(sp)
ffffffffc0200ba6:	7a42                	ld	s4,48(sp)
ffffffffc0200ba8:	7aa2                	ld	s5,40(sp)
ffffffffc0200baa:	7b02                	ld	s6,32(sp)
ffffffffc0200bac:	6be2                	ld	s7,24(sp)
ffffffffc0200bae:	6c42                	ld	s8,16(sp)
ffffffffc0200bb0:	6ca2                	ld	s9,8(sp)
ffffffffc0200bb2:	6d02                	ld	s10,0(sp)
    cprintf("======================the end======================\n\n\n");
ffffffffc0200bb4:	00001517          	auipc	a0,0x1
ffffffffc0200bb8:	7dc50513          	addi	a0,a0,2012 # ffffffffc0202390 <commands+0x670>
}
ffffffffc0200bbc:	6125                	addi	sp,sp,96
    cprintf("======================the end======================\n\n\n");
ffffffffc0200bbe:	cf4ff06f          	j	ffffffffc02000b2 <cprintf>
        cprintf("no free blocks\n");
ffffffffc0200bc2:	00001517          	auipc	a0,0x1
ffffffffc0200bc6:	7be50513          	addi	a0,a0,1982 # ffffffffc0202380 <commands+0x660>
ffffffffc0200bca:	ce8ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200bce:	b7f9                	j	ffffffffc0200b9c <show_buddy_array.constprop.0+0xb4>
    assert(left >= 0 && left <= max_order && right >= 0 && right <= max_order);
ffffffffc0200bd0:	00001697          	auipc	a3,0x1
ffffffffc0200bd4:	6f068693          	addi	a3,a3,1776 # ffffffffc02022c0 <commands+0x5a0>
ffffffffc0200bd8:	00001617          	auipc	a2,0x1
ffffffffc0200bdc:	64860613          	addi	a2,a2,1608 # ffffffffc0202220 <commands+0x500>
ffffffffc0200be0:	06300593          	li	a1,99
ffffffffc0200be4:	00001517          	auipc	a0,0x1
ffffffffc0200be8:	65450513          	addi	a0,a0,1620 # ffffffffc0202238 <commands+0x518>
ffffffffc0200bec:	fc0ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200bf0 <buddy_system_check>:

// LAB2: below code is used to check the first fit allocation algorithm
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
buddy_system_check(void)
{
ffffffffc0200bf0:	7179                	addi	sp,sp,-48
ffffffffc0200bf2:	f022                	sd	s0,32(sp)
    cprintf("Total number of free blocks：%d\n", nr_free);
ffffffffc0200bf4:	00005417          	auipc	s0,0x5
ffffffffc0200bf8:	42440413          	addi	s0,s0,1060 # ffffffffc0206018 <buddy_s>
ffffffffc0200bfc:	0f842583          	lw	a1,248(s0)
ffffffffc0200c00:	00001517          	auipc	a0,0x1
ffffffffc0200c04:	7c850513          	addi	a0,a0,1992 # ffffffffc02023c8 <commands+0x6a8>
{
ffffffffc0200c08:	f406                	sd	ra,40(sp)
ffffffffc0200c0a:	ec26                	sd	s1,24(sp)
ffffffffc0200c0c:	e84a                	sd	s2,16(sp)
ffffffffc0200c0e:	e44e                	sd	s3,8(sp)
    cprintf("Total number of free blocks：%d\n", nr_free);
ffffffffc0200c10:	ca2ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("p0 requests 5 Pages\n");
ffffffffc0200c14:	00001517          	auipc	a0,0x1
ffffffffc0200c18:	7dc50513          	addi	a0,a0,2012 # ffffffffc02023f0 <commands+0x6d0>
ffffffffc0200c1c:	c96ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    p0 = alloc_pages(5);
ffffffffc0200c20:	4515                	li	a0,5
ffffffffc0200c22:	550000ef          	jal	ra,ffffffffc0201172 <alloc_pages>
ffffffffc0200c26:	892a                	mv	s2,a0
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200c28:	ec1ff0ef          	jal	ra,ffffffffc0200ae8 <show_buddy_array.constprop.0>
    cprintf("p1 requests 5 Pages\n");
ffffffffc0200c2c:	00001517          	auipc	a0,0x1
ffffffffc0200c30:	7dc50513          	addi	a0,a0,2012 # ffffffffc0202408 <commands+0x6e8>
ffffffffc0200c34:	c7eff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    p1 = alloc_pages(5);
ffffffffc0200c38:	4515                	li	a0,5
ffffffffc0200c3a:	538000ef          	jal	ra,ffffffffc0201172 <alloc_pages>
ffffffffc0200c3e:	84aa                	mv	s1,a0
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200c40:	ea9ff0ef          	jal	ra,ffffffffc0200ae8 <show_buddy_array.constprop.0>
    cprintf("p2 requests 5 Pages\n");
ffffffffc0200c44:	00001517          	auipc	a0,0x1
ffffffffc0200c48:	7dc50513          	addi	a0,a0,2012 # ffffffffc0202420 <commands+0x700>
ffffffffc0200c4c:	c66ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    p2 = alloc_pages(5);
ffffffffc0200c50:	4515                	li	a0,5
ffffffffc0200c52:	520000ef          	jal	ra,ffffffffc0201172 <alloc_pages>
ffffffffc0200c56:	89aa                	mv	s3,a0
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200c58:	e91ff0ef          	jal	ra,ffffffffc0200ae8 <show_buddy_array.constprop.0>
    cprintf("p0 Virtual Address:0x%016lx.\n", p0);
ffffffffc0200c5c:	85ca                	mv	a1,s2
ffffffffc0200c5e:	00001517          	auipc	a0,0x1
ffffffffc0200c62:	7da50513          	addi	a0,a0,2010 # ffffffffc0202438 <commands+0x718>
ffffffffc0200c66:	c4cff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("p1 Virtual Address:0x%016lx.\n", p1);
ffffffffc0200c6a:	85a6                	mv	a1,s1
ffffffffc0200c6c:	00001517          	auipc	a0,0x1
ffffffffc0200c70:	7ec50513          	addi	a0,a0,2028 # ffffffffc0202458 <commands+0x738>
ffffffffc0200c74:	c3eff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("p2 Virtual Address:0x%016lx.\n", p2);
ffffffffc0200c78:	85ce                	mv	a1,s3
ffffffffc0200c7a:	00001517          	auipc	a0,0x1
ffffffffc0200c7e:	7fe50513          	addi	a0,a0,2046 # ffffffffc0202478 <commands+0x758>
ffffffffc0200c82:	c30ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200c86:	1e990a63          	beq	s2,s1,ffffffffc0200e7a <buddy_system_check+0x28a>
ffffffffc0200c8a:	1f390863          	beq	s2,s3,ffffffffc0200e7a <buddy_system_check+0x28a>
ffffffffc0200c8e:	1f348663          	beq	s1,s3,ffffffffc0200e7a <buddy_system_check+0x28a>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200c92:	00092783          	lw	a5,0(s2)
ffffffffc0200c96:	22079263          	bnez	a5,ffffffffc0200eba <buddy_system_check+0x2ca>
ffffffffc0200c9a:	409c                	lw	a5,0(s1)
ffffffffc0200c9c:	20079f63          	bnez	a5,ffffffffc0200eba <buddy_system_check+0x2ca>
ffffffffc0200ca0:	0009a783          	lw	a5,0(s3)
ffffffffc0200ca4:	20079b63          	bnez	a5,ffffffffc0200eba <buddy_system_check+0x2ca>
ffffffffc0200ca8:	00006797          	auipc	a5,0x6
ffffffffc0200cac:	8907b783          	ld	a5,-1904(a5) # ffffffffc0206538 <pages>
ffffffffc0200cb0:	40f90733          	sub	a4,s2,a5
ffffffffc0200cb4:	870d                	srai	a4,a4,0x3
ffffffffc0200cb6:	00002597          	auipc	a1,0x2
ffffffffc0200cba:	0e25b583          	ld	a1,226(a1) # ffffffffc0202d98 <error_string+0x38>
ffffffffc0200cbe:	02b70733          	mul	a4,a4,a1
ffffffffc0200cc2:	00002617          	auipc	a2,0x2
ffffffffc0200cc6:	0de63603          	ld	a2,222(a2) # ffffffffc0202da0 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200cca:	00006697          	auipc	a3,0x6
ffffffffc0200cce:	8666b683          	ld	a3,-1946(a3) # ffffffffc0206530 <npage>
ffffffffc0200cd2:	06b2                	slli	a3,a3,0xc
ffffffffc0200cd4:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200cd6:	0732                	slli	a4,a4,0xc
ffffffffc0200cd8:	2cd77163          	bgeu	a4,a3,ffffffffc0200f9a <buddy_system_check+0x3aa>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; } 
ffffffffc0200cdc:	40f48733          	sub	a4,s1,a5
ffffffffc0200ce0:	870d                	srai	a4,a4,0x3
ffffffffc0200ce2:	02b70733          	mul	a4,a4,a1
ffffffffc0200ce6:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200ce8:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200cea:	1ed77863          	bgeu	a4,a3,ffffffffc0200eda <buddy_system_check+0x2ea>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; } 
ffffffffc0200cee:	40f987b3          	sub	a5,s3,a5
ffffffffc0200cf2:	878d                	srai	a5,a5,0x3
ffffffffc0200cf4:	02b787b3          	mul	a5,a5,a1
ffffffffc0200cf8:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200cfa:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200cfc:	1ed7ff63          	bgeu	a5,a3,ffffffffc0200efa <buddy_system_check+0x30a>
    assert(alloc_page() == NULL);
ffffffffc0200d00:	4505                	li	a0,1
    nr_free = 0;
ffffffffc0200d02:	00005797          	auipc	a5,0x5
ffffffffc0200d06:	4007a723          	sw	zero,1038(a5) # ffffffffc0206110 <buddy_s+0xf8>
    assert(alloc_page() == NULL);
ffffffffc0200d0a:	468000ef          	jal	ra,ffffffffc0201172 <alloc_pages>
ffffffffc0200d0e:	20051663          	bnez	a0,ffffffffc0200f1a <buddy_system_check+0x32a>
    cprintf("releasing p0......\n");
ffffffffc0200d12:	00002517          	auipc	a0,0x2
ffffffffc0200d16:	86650513          	addi	a0,a0,-1946 # ffffffffc0202578 <commands+0x858>
ffffffffc0200d1a:	b98ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    free_pages(p0, 5);
ffffffffc0200d1e:	4595                	li	a1,5
ffffffffc0200d20:	854a                	mv	a0,s2
ffffffffc0200d22:	48e000ef          	jal	ra,ffffffffc02011b0 <free_pages>
    cprintf("after releasing p0，counts of total free blocks：%d\n", nr_free); // 变成了8
ffffffffc0200d26:	0f842583          	lw	a1,248(s0)
ffffffffc0200d2a:	00002517          	auipc	a0,0x2
ffffffffc0200d2e:	86650513          	addi	a0,a0,-1946 # ffffffffc0202590 <commands+0x870>
ffffffffc0200d32:	b80ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200d36:	db3ff0ef          	jal	ra,ffffffffc0200ae8 <show_buddy_array.constprop.0>
    cprintf("releasing p1......\n");
ffffffffc0200d3a:	00002517          	auipc	a0,0x2
ffffffffc0200d3e:	88e50513          	addi	a0,a0,-1906 # ffffffffc02025c8 <commands+0x8a8>
ffffffffc0200d42:	b70ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    free_pages(p1, 5);
ffffffffc0200d46:	4595                	li	a1,5
ffffffffc0200d48:	8526                	mv	a0,s1
ffffffffc0200d4a:	466000ef          	jal	ra,ffffffffc02011b0 <free_pages>
    cprintf("after releasing p1，counts of total free blocks：%d\n", nr_free); // 变成了16
ffffffffc0200d4e:	0f842583          	lw	a1,248(s0)
ffffffffc0200d52:	00002517          	auipc	a0,0x2
ffffffffc0200d56:	88e50513          	addi	a0,a0,-1906 # ffffffffc02025e0 <commands+0x8c0>
ffffffffc0200d5a:	b58ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200d5e:	d8bff0ef          	jal	ra,ffffffffc0200ae8 <show_buddy_array.constprop.0>
    cprintf("releasing p2......\n");
ffffffffc0200d62:	00002517          	auipc	a0,0x2
ffffffffc0200d66:	8b650513          	addi	a0,a0,-1866 # ffffffffc0202618 <commands+0x8f8>
ffffffffc0200d6a:	b48ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    free_pages(p2, 5);
ffffffffc0200d6e:	4595                	li	a1,5
ffffffffc0200d70:	854e                	mv	a0,s3
ffffffffc0200d72:	43e000ef          	jal	ra,ffffffffc02011b0 <free_pages>
    cprintf("after releasing p2，counts of total free blocks：%d\n", nr_free); // 变成了24
ffffffffc0200d76:	0f842583          	lw	a1,248(s0)
ffffffffc0200d7a:	00002517          	auipc	a0,0x2
ffffffffc0200d7e:	8b650513          	addi	a0,a0,-1866 # ffffffffc0202630 <commands+0x910>
ffffffffc0200d82:	b30ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200d86:	d63ff0ef          	jal	ra,ffffffffc0200ae8 <show_buddy_array.constprop.0>
    nr_free = 16384;
ffffffffc0200d8a:	6791                	lui	a5,0x4
    struct Page *p3 = alloc_pages(16384);
ffffffffc0200d8c:	6511                	lui	a0,0x4
    nr_free = 16384;
ffffffffc0200d8e:	0ef42c23          	sw	a5,248(s0)
    struct Page *p3 = alloc_pages(16384);
ffffffffc0200d92:	3e0000ef          	jal	ra,ffffffffc0201172 <alloc_pages>
ffffffffc0200d96:	842a                	mv	s0,a0
    cprintf("after releasing p2(16384 Pages)\n");
ffffffffc0200d98:	00002517          	auipc	a0,0x2
ffffffffc0200d9c:	8d050513          	addi	a0,a0,-1840 # ffffffffc0202668 <commands+0x948>
ffffffffc0200da0:	b12ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200da4:	d45ff0ef          	jal	ra,ffffffffc0200ae8 <show_buddy_array.constprop.0>
    free_pages(p3, 16384);
ffffffffc0200da8:	6591                	lui	a1,0x4
ffffffffc0200daa:	8522                	mv	a0,s0
ffffffffc0200dac:	404000ef          	jal	ra,ffffffffc02011b0 <free_pages>
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200db0:	d39ff0ef          	jal	ra,ffffffffc0200ae8 <show_buddy_array.constprop.0>
    basic_check();

    // 一些复杂的操作
    cprintf("==========complex testing beginning==========\n");
ffffffffc0200db4:	00002517          	auipc	a0,0x2
ffffffffc0200db8:	8dc50513          	addi	a0,a0,-1828 # ffffffffc0202690 <commands+0x970>
ffffffffc0200dbc:	af6ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("p0 requests 5 Pages\n");
ffffffffc0200dc0:	00001517          	auipc	a0,0x1
ffffffffc0200dc4:	63050513          	addi	a0,a0,1584 # ffffffffc02023f0 <commands+0x6d0>
ffffffffc0200dc8:	aeaff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200dcc:	4515                	li	a0,5
ffffffffc0200dce:	3a4000ef          	jal	ra,ffffffffc0201172 <alloc_pages>
ffffffffc0200dd2:	842a                	mv	s0,a0
    assert(p0 != NULL);
ffffffffc0200dd4:	1a050363          	beqz	a0,ffffffffc0200f7a <buddy_system_check+0x38a>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200dd8:	651c                	ld	a5,8(a0)
ffffffffc0200dda:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200ddc:	8b85                	andi	a5,a5,1
ffffffffc0200dde:	16079e63          	bnez	a5,ffffffffc0200f5a <buddy_system_check+0x36a>
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200de2:	d07ff0ef          	jal	ra,ffffffffc0200ae8 <show_buddy_array.constprop.0>

    cprintf("p1 requests 15 Pages\n");
ffffffffc0200de6:	00002517          	auipc	a0,0x2
ffffffffc0200dea:	90250513          	addi	a0,a0,-1790 # ffffffffc02026e8 <commands+0x9c8>
ffffffffc0200dee:	ac4ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    p1 = alloc_pages(15);
ffffffffc0200df2:	453d                	li	a0,15
ffffffffc0200df4:	37e000ef          	jal	ra,ffffffffc0201172 <alloc_pages>
ffffffffc0200df8:	892a                	mv	s2,a0
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200dfa:	cefff0ef          	jal	ra,ffffffffc0200ae8 <show_buddy_array.constprop.0>

    cprintf("p2 requests 21 Pages\n");
ffffffffc0200dfe:	00002517          	auipc	a0,0x2
ffffffffc0200e02:	90250513          	addi	a0,a0,-1790 # ffffffffc0202700 <commands+0x9e0>
ffffffffc0200e06:	aacff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    p2 = alloc_pages(21);
ffffffffc0200e0a:	4555                	li	a0,21
ffffffffc0200e0c:	366000ef          	jal	ra,ffffffffc0201172 <alloc_pages>
ffffffffc0200e10:	84aa                	mv	s1,a0
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200e12:	cd7ff0ef          	jal	ra,ffffffffc0200ae8 <show_buddy_array.constprop.0>

    cprintf("p0 Virtual Address:0x%016lx.\n", p0);
ffffffffc0200e16:	85a2                	mv	a1,s0
ffffffffc0200e18:	00001517          	auipc	a0,0x1
ffffffffc0200e1c:	62050513          	addi	a0,a0,1568 # ffffffffc0202438 <commands+0x718>
ffffffffc0200e20:	a92ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("p1 Virtual Address:0x%016lx.\n", p1);
ffffffffc0200e24:	85ca                	mv	a1,s2
ffffffffc0200e26:	00001517          	auipc	a0,0x1
ffffffffc0200e2a:	63250513          	addi	a0,a0,1586 # ffffffffc0202458 <commands+0x738>
ffffffffc0200e2e:	a84ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("p2 Virtual Address:0x%016lx.\n", p2);
ffffffffc0200e32:	85a6                	mv	a1,s1
ffffffffc0200e34:	00001517          	auipc	a0,0x1
ffffffffc0200e38:	64450513          	addi	a0,a0,1604 # ffffffffc0202478 <commands+0x758>
ffffffffc0200e3c:	a76ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>

    // 检查幂次正确
    assert(p0->property == 3 && p1->property == 4 && p2->property == 5);
ffffffffc0200e40:	4818                	lw	a4,16(s0)
ffffffffc0200e42:	478d                	li	a5,3
ffffffffc0200e44:	04f71b63          	bne	a4,a5,ffffffffc0200e9a <buddy_system_check+0x2aa>
ffffffffc0200e48:	01092703          	lw	a4,16(s2)
ffffffffc0200e4c:	4791                	li	a5,4
ffffffffc0200e4e:	04f71663          	bne	a4,a5,ffffffffc0200e9a <buddy_system_check+0x2aa>
ffffffffc0200e52:	4898                	lw	a4,16(s1)
ffffffffc0200e54:	4795                	li	a5,5
ffffffffc0200e56:	04f71263          	bne	a4,a5,ffffffffc0200e9a <buddy_system_check+0x2aa>

    // 暂存p0，删后分配看看能不能找到
    struct Page *temp = p0;

    free_pages(p0, 5);
ffffffffc0200e5a:	8522                	mv	a0,s0
ffffffffc0200e5c:	4595                	li	a1,5
ffffffffc0200e5e:	352000ef          	jal	ra,ffffffffc02011b0 <free_pages>

    p0 = alloc_pages(5);
ffffffffc0200e62:	4515                	li	a0,5
ffffffffc0200e64:	30e000ef          	jal	ra,ffffffffc0201172 <alloc_pages>
    assert(p0 == temp);
ffffffffc0200e68:	0ca41963          	bne	s0,a0,ffffffffc0200f3a <buddy_system_check+0x34a>
    show_buddy_array(0, MAX_BUDDY_ORDER);
}
ffffffffc0200e6c:	7402                	ld	s0,32(sp)
ffffffffc0200e6e:	70a2                	ld	ra,40(sp)
ffffffffc0200e70:	64e2                	ld	s1,24(sp)
ffffffffc0200e72:	6942                	ld	s2,16(sp)
ffffffffc0200e74:	69a2                	ld	s3,8(sp)
ffffffffc0200e76:	6145                	addi	sp,sp,48
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200e78:	b985                	j	ffffffffc0200ae8 <show_buddy_array.constprop.0>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200e7a:	00001697          	auipc	a3,0x1
ffffffffc0200e7e:	61e68693          	addi	a3,a3,1566 # ffffffffc0202498 <commands+0x778>
ffffffffc0200e82:	00001617          	auipc	a2,0x1
ffffffffc0200e86:	39e60613          	addi	a2,a2,926 # ffffffffc0202220 <commands+0x500>
ffffffffc0200e8a:	13700593          	li	a1,311
ffffffffc0200e8e:	00001517          	auipc	a0,0x1
ffffffffc0200e92:	3aa50513          	addi	a0,a0,938 # ffffffffc0202238 <commands+0x518>
ffffffffc0200e96:	d16ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p0->property == 3 && p1->property == 4 && p2->property == 5);
ffffffffc0200e9a:	00002697          	auipc	a3,0x2
ffffffffc0200e9e:	87e68693          	addi	a3,a3,-1922 # ffffffffc0202718 <commands+0x9f8>
ffffffffc0200ea2:	00001617          	auipc	a2,0x1
ffffffffc0200ea6:	37e60613          	addi	a2,a2,894 # ffffffffc0202220 <commands+0x500>
ffffffffc0200eaa:	17c00593          	li	a1,380
ffffffffc0200eae:	00001517          	auipc	a0,0x1
ffffffffc0200eb2:	38a50513          	addi	a0,a0,906 # ffffffffc0202238 <commands+0x518>
ffffffffc0200eb6:	cf6ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200eba:	00001697          	auipc	a3,0x1
ffffffffc0200ebe:	60668693          	addi	a3,a3,1542 # ffffffffc02024c0 <commands+0x7a0>
ffffffffc0200ec2:	00001617          	auipc	a2,0x1
ffffffffc0200ec6:	35e60613          	addi	a2,a2,862 # ffffffffc0202220 <commands+0x500>
ffffffffc0200eca:	13800593          	li	a1,312
ffffffffc0200ece:	00001517          	auipc	a0,0x1
ffffffffc0200ed2:	36a50513          	addi	a0,a0,874 # ffffffffc0202238 <commands+0x518>
ffffffffc0200ed6:	cd6ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200eda:	00001697          	auipc	a3,0x1
ffffffffc0200ede:	64668693          	addi	a3,a3,1606 # ffffffffc0202520 <commands+0x800>
ffffffffc0200ee2:	00001617          	auipc	a2,0x1
ffffffffc0200ee6:	33e60613          	addi	a2,a2,830 # ffffffffc0202220 <commands+0x500>
ffffffffc0200eea:	13b00593          	li	a1,315
ffffffffc0200eee:	00001517          	auipc	a0,0x1
ffffffffc0200ef2:	34a50513          	addi	a0,a0,842 # ffffffffc0202238 <commands+0x518>
ffffffffc0200ef6:	cb6ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200efa:	00001697          	auipc	a3,0x1
ffffffffc0200efe:	64668693          	addi	a3,a3,1606 # ffffffffc0202540 <commands+0x820>
ffffffffc0200f02:	00001617          	auipc	a2,0x1
ffffffffc0200f06:	31e60613          	addi	a2,a2,798 # ffffffffc0202220 <commands+0x500>
ffffffffc0200f0a:	13c00593          	li	a1,316
ffffffffc0200f0e:	00001517          	auipc	a0,0x1
ffffffffc0200f12:	32a50513          	addi	a0,a0,810 # ffffffffc0202238 <commands+0x518>
ffffffffc0200f16:	c96ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200f1a:	00001697          	auipc	a3,0x1
ffffffffc0200f1e:	64668693          	addi	a3,a3,1606 # ffffffffc0202560 <commands+0x840>
ffffffffc0200f22:	00001617          	auipc	a2,0x1
ffffffffc0200f26:	2fe60613          	addi	a2,a2,766 # ffffffffc0202220 <commands+0x500>
ffffffffc0200f2a:	14200593          	li	a1,322
ffffffffc0200f2e:	00001517          	auipc	a0,0x1
ffffffffc0200f32:	30a50513          	addi	a0,a0,778 # ffffffffc0202238 <commands+0x518>
ffffffffc0200f36:	c76ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p0 == temp);
ffffffffc0200f3a:	00002697          	auipc	a3,0x2
ffffffffc0200f3e:	81e68693          	addi	a3,a3,-2018 # ffffffffc0202758 <commands+0xa38>
ffffffffc0200f42:	00001617          	auipc	a2,0x1
ffffffffc0200f46:	2de60613          	addi	a2,a2,734 # ffffffffc0202220 <commands+0x500>
ffffffffc0200f4a:	18400593          	li	a1,388
ffffffffc0200f4e:	00001517          	auipc	a0,0x1
ffffffffc0200f52:	2ea50513          	addi	a0,a0,746 # ffffffffc0202238 <commands+0x518>
ffffffffc0200f56:	c56ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(!PageProperty(p0));
ffffffffc0200f5a:	00001697          	auipc	a3,0x1
ffffffffc0200f5e:	77668693          	addi	a3,a3,1910 # ffffffffc02026d0 <commands+0x9b0>
ffffffffc0200f62:	00001617          	auipc	a2,0x1
ffffffffc0200f66:	2be60613          	addi	a2,a2,702 # ffffffffc0202220 <commands+0x500>
ffffffffc0200f6a:	16c00593          	li	a1,364
ffffffffc0200f6e:	00001517          	auipc	a0,0x1
ffffffffc0200f72:	2ca50513          	addi	a0,a0,714 # ffffffffc0202238 <commands+0x518>
ffffffffc0200f76:	c36ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p0 != NULL);
ffffffffc0200f7a:	00001697          	auipc	a3,0x1
ffffffffc0200f7e:	74668693          	addi	a3,a3,1862 # ffffffffc02026c0 <commands+0x9a0>
ffffffffc0200f82:	00001617          	auipc	a2,0x1
ffffffffc0200f86:	29e60613          	addi	a2,a2,670 # ffffffffc0202220 <commands+0x500>
ffffffffc0200f8a:	16b00593          	li	a1,363
ffffffffc0200f8e:	00001517          	auipc	a0,0x1
ffffffffc0200f92:	2aa50513          	addi	a0,a0,682 # ffffffffc0202238 <commands+0x518>
ffffffffc0200f96:	c16ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200f9a:	00001697          	auipc	a3,0x1
ffffffffc0200f9e:	56668693          	addi	a3,a3,1382 # ffffffffc0202500 <commands+0x7e0>
ffffffffc0200fa2:	00001617          	auipc	a2,0x1
ffffffffc0200fa6:	27e60613          	addi	a2,a2,638 # ffffffffc0202220 <commands+0x500>
ffffffffc0200faa:	13a00593          	li	a1,314
ffffffffc0200fae:	00001517          	auipc	a0,0x1
ffffffffc0200fb2:	28a50513          	addi	a0,a0,650 # ffffffffc0202238 <commands+0x518>
ffffffffc0200fb6:	bf6ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200fba <buddy_system_alloc_pages>:
{
ffffffffc0200fba:	1141                	addi	sp,sp,-16
ffffffffc0200fbc:	e406                	sd	ra,8(sp)
    assert(requested_pages > 0);
ffffffffc0200fbe:	14050c63          	beqz	a0,ffffffffc0201116 <buddy_system_alloc_pages+0x15c>
    if (requested_pages > nr_free)
ffffffffc0200fc2:	00005817          	auipc	a6,0x5
ffffffffc0200fc6:	05680813          	addi	a6,a6,86 # ffffffffc0206018 <buddy_s>
ffffffffc0200fca:	0f886783          	lwu	a5,248(a6)
ffffffffc0200fce:	832a                	mv	t1,a0
ffffffffc0200fd0:	0ea7e063          	bltu	a5,a0,ffffffffc02010b0 <buddy_system_alloc_pages+0xf6>
    if (n & (n - 1))
ffffffffc0200fd4:	fff50793          	addi	a5,a0,-1
ffffffffc0200fd8:	8fe9                	and	a5,a5,a0
ffffffffc0200fda:	eff9                	bnez	a5,ffffffffc02010b8 <buddy_system_alloc_pages+0xfe>
    while (n >> 1)
ffffffffc0200fdc:	00135793          	srli	a5,t1,0x1
ffffffffc0200fe0:	10078763          	beqz	a5,ffffffffc02010ee <buddy_system_alloc_pages+0x134>
    unsigned int order = 0;
ffffffffc0200fe4:	4881                	li	a7,0
    while (n >> 1)
ffffffffc0200fe6:	8385                	srli	a5,a5,0x1
        order++;
ffffffffc0200fe8:	2885                	addiw	a7,a7,1
    while (n >> 1)
ffffffffc0200fea:	fff5                	bnez	a5,ffffffffc0200fe6 <buddy_system_alloc_pages+0x2c>
ffffffffc0200fec:	02089793          	slli	a5,a7,0x20
ffffffffc0200ff0:	01c7de93          	srli	t4,a5,0x1c
ffffffffc0200ff4:	008e8f13          	addi	t5,t4,8
    while (!found)
ffffffffc0200ff8:	2885                	addiw	a7,a7,1
ffffffffc0200ffa:	00489e13          	slli	t3,a7,0x4
ffffffffc0200ffe:	0e21                	addi	t3,t3,8
        if (!list_empty(&(buddy_array[order_of_2])))
ffffffffc0201000:	9f42                	add	t5,t5,a6
ffffffffc0201002:	9e42                	add	t3,t3,a6
    return list->next == list;
ffffffffc0201004:	9ec2                	add	t4,t4,a6
ffffffffc0201006:	0008829b          	sext.w	t0,a7
    page_b = page_a + (1 << (n - 1)); // 找到a的伙伴块b，因为是大块分割的，直接加2的n-1次幂就行
ffffffffc020100a:	4f85                	li	t6,1
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020100c:	4509                	li	a0,2
ffffffffc020100e:	010eb783          	ld	a5,16(t4)
        if (!list_empty(&(buddy_array[order_of_2])))
ffffffffc0201012:	0aff1b63          	bne	t5,a5,ffffffffc02010c8 <buddy_system_alloc_pages+0x10e>
            for (i = order_of_2 + 1; i <= max_order; ++i)
ffffffffc0201016:	00082583          	lw	a1,0(a6)
ffffffffc020101a:	0915eb63          	bltu	a1,a7,ffffffffc02010b0 <buddy_system_alloc_pages+0xf6>
ffffffffc020101e:	8772                	mv	a4,t3
ffffffffc0201020:	87c6                	mv	a5,a7
ffffffffc0201022:	8696                	mv	a3,t0
ffffffffc0201024:	a039                	j	ffffffffc0201032 <buddy_system_alloc_pages+0x78>
ffffffffc0201026:	0785                	addi	a5,a5,1
ffffffffc0201028:	0007869b          	sext.w	a3,a5
ffffffffc020102c:	0741                	addi	a4,a4,16
ffffffffc020102e:	08d5e163          	bltu	a1,a3,ffffffffc02010b0 <buddy_system_alloc_pages+0xf6>
                if (!list_empty(&(buddy_array[i])))
ffffffffc0201032:	6710                	ld	a2,8(a4)
ffffffffc0201034:	fec709e3          	beq	a4,a2,ffffffffc0201026 <buddy_system_alloc_pages+0x6c>
    assert(n > 0 && n <= max_order);
ffffffffc0201038:	cfdd                	beqz	a5,ffffffffc02010f6 <buddy_system_alloc_pages+0x13c>
ffffffffc020103a:	1582                	slli	a1,a1,0x20
ffffffffc020103c:	9181                	srli	a1,a1,0x20
ffffffffc020103e:	0af5ec63          	bltu	a1,a5,ffffffffc02010f6 <buddy_system_alloc_pages+0x13c>
ffffffffc0201042:	00479613          	slli	a2,a5,0x4
ffffffffc0201046:	9642                	add	a2,a2,a6
ffffffffc0201048:	6a10                	ld	a2,16(a2)
    assert(!list_empty(&(buddy_array[n])));
ffffffffc020104a:	0ee60663          	beq	a2,a4,ffffffffc0201136 <buddy_system_alloc_pages+0x17c>
    page_b = page_a + (1 << (n - 1)); // 找到a的伙伴块b，因为是大块分割的，直接加2的n-1次幂就行
ffffffffc020104e:	fff6859b          	addiw	a1,a3,-1
ffffffffc0201052:	00bf93bb          	sllw	t2,t6,a1
ffffffffc0201056:	00239713          	slli	a4,t2,0x2
ffffffffc020105a:	971e                	add	a4,a4,t2
ffffffffc020105c:	070e                	slli	a4,a4,0x3
ffffffffc020105e:	1721                	addi	a4,a4,-24
    page_a->property = n - 1;
ffffffffc0201060:	feb62c23          	sw	a1,-8(a2)
    page_b = page_a + (1 << (n - 1)); // 找到a的伙伴块b，因为是大块分割的，直接加2的n-1次幂就行
ffffffffc0201064:	9732                	add	a4,a4,a2
    page_b->property = n - 1;
ffffffffc0201066:	cb0c                	sw	a1,16(a4)
ffffffffc0201068:	ff060593          	addi	a1,a2,-16
ffffffffc020106c:	40a5b02f          	amoor.d	zero,a0,(a1)
ffffffffc0201070:	00870593          	addi	a1,a4,8
ffffffffc0201074:	40a5b02f          	amoor.d	zero,a0,(a1)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201078:	00063383          	ld	t2,0(a2)
ffffffffc020107c:	660c                	ld	a1,8(a2)
    list_add(&(buddy_array[n - 1]), &(page_a->page_link));
ffffffffc020107e:	17fd                	addi	a5,a5,-1
    __list_add(elm, listelm, listelm->next);
ffffffffc0201080:	0792                	slli	a5,a5,0x4
    prev->next = next;
ffffffffc0201082:	00b3b423          	sd	a1,8(t2)
    next->prev = prev;
ffffffffc0201086:	0075b023          	sd	t2,0(a1) # 4000 <kern_entry-0xffffffffc01fc000>
    __list_add(elm, listelm, listelm->next);
ffffffffc020108a:	00f803b3          	add	t2,a6,a5
ffffffffc020108e:	0103b583          	ld	a1,16(t2)
ffffffffc0201092:	07a1                	addi	a5,a5,8
    prev->next = next->prev = elm;
ffffffffc0201094:	00c3b823          	sd	a2,16(t2)
ffffffffc0201098:	97c2                	add	a5,a5,a6
    elm->prev = prev;
ffffffffc020109a:	e21c                	sd	a5,0(a2)
    list_add(&(page_a->page_link), &(page_b->page_link));
ffffffffc020109c:	01870793          	addi	a5,a4,24
    prev->next = next->prev = elm;
ffffffffc02010a0:	e19c                	sd	a5,0(a1)
            if (i > max_order)
ffffffffc02010a2:	00082383          	lw	t2,0(a6)
ffffffffc02010a6:	e61c                	sd	a5,8(a2)
    elm->next = next;
ffffffffc02010a8:	f30c                	sd	a1,32(a4)
    elm->prev = prev;
ffffffffc02010aa:	ef10                	sd	a2,24(a4)
ffffffffc02010ac:	f6d3f1e3          	bgeu	t2,a3,ffffffffc020100e <buddy_system_alloc_pages+0x54>
}
ffffffffc02010b0:	60a2                	ld	ra,8(sp)
        return NULL;
ffffffffc02010b2:	4501                	li	a0,0
}
ffffffffc02010b4:	0141                	addi	sp,sp,16
ffffffffc02010b6:	8082                	ret
ffffffffc02010b8:	4785                	li	a5,1
            n = n >> 1;
ffffffffc02010ba:	00135313          	srli	t1,t1,0x1
            res = res << 1;
ffffffffc02010be:	0786                	slli	a5,a5,0x1
        while (n)
ffffffffc02010c0:	fe031de3          	bnez	t1,ffffffffc02010ba <buddy_system_alloc_pages+0x100>
            res = res << 1;
ffffffffc02010c4:	833e                	mv	t1,a5
ffffffffc02010c6:	bf19                	j	ffffffffc0200fdc <buddy_system_alloc_pages+0x22>
    __list_del(listelm->prev, listelm->next);
ffffffffc02010c8:	6798                	ld	a4,8(a5)
ffffffffc02010ca:	6394                	ld	a3,0(a5)
            allocated_page = le2page(list_next(&(buddy_array[order_of_2])), page_link);
ffffffffc02010cc:	fe878513          	addi	a0,a5,-24 # 3fe8 <kern_entry-0xffffffffc01fc018>
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02010d0:	17c1                	addi	a5,a5,-16
    prev->next = next;
ffffffffc02010d2:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc02010d4:	e314                	sd	a3,0(a4)
ffffffffc02010d6:	5775                	li	a4,-3
ffffffffc02010d8:	60e7b02f          	amoand.d	zero,a4,(a5)
        nr_free -= adjusted_pages;
ffffffffc02010dc:	0f882783          	lw	a5,248(a6)
}
ffffffffc02010e0:	60a2                	ld	ra,8(sp)
        nr_free -= adjusted_pages;
ffffffffc02010e2:	4067833b          	subw	t1,a5,t1
ffffffffc02010e6:	0e682c23          	sw	t1,248(a6)
}
ffffffffc02010ea:	0141                	addi	sp,sp,16
ffffffffc02010ec:	8082                	ret
    while (n >> 1)
ffffffffc02010ee:	4f21                	li	t5,8
    unsigned int order = 0;
ffffffffc02010f0:	4881                	li	a7,0
ffffffffc02010f2:	4e81                	li	t4,0
ffffffffc02010f4:	b711                	j	ffffffffc0200ff8 <buddy_system_alloc_pages+0x3e>
    assert(n > 0 && n <= max_order);
ffffffffc02010f6:	00001697          	auipc	a3,0x1
ffffffffc02010fa:	68a68693          	addi	a3,a3,1674 # ffffffffc0202780 <commands+0xa60>
ffffffffc02010fe:	00001617          	auipc	a2,0x1
ffffffffc0201102:	12260613          	addi	a2,a2,290 # ffffffffc0202220 <commands+0x500>
ffffffffc0201106:	04a00593          	li	a1,74
ffffffffc020110a:	00001517          	auipc	a0,0x1
ffffffffc020110e:	12e50513          	addi	a0,a0,302 # ffffffffc0202238 <commands+0x518>
ffffffffc0201112:	a9aff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(requested_pages > 0);
ffffffffc0201116:	00001697          	auipc	a3,0x1
ffffffffc020111a:	65268693          	addi	a3,a3,1618 # ffffffffc0202768 <commands+0xa48>
ffffffffc020111e:	00001617          	auipc	a2,0x1
ffffffffc0201122:	10260613          	addi	a2,a2,258 # ffffffffc0202220 <commands+0x500>
ffffffffc0201126:	0ac00593          	li	a1,172
ffffffffc020112a:	00001517          	auipc	a0,0x1
ffffffffc020112e:	10e50513          	addi	a0,a0,270 # ffffffffc0202238 <commands+0x518>
ffffffffc0201132:	a7aff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(!list_empty(&(buddy_array[n])));
ffffffffc0201136:	00001697          	auipc	a3,0x1
ffffffffc020113a:	66268693          	addi	a3,a3,1634 # ffffffffc0202798 <commands+0xa78>
ffffffffc020113e:	00001617          	auipc	a2,0x1
ffffffffc0201142:	0e260613          	addi	a2,a2,226 # ffffffffc0202220 <commands+0x500>
ffffffffc0201146:	04b00593          	li	a1,75
ffffffffc020114a:	00001517          	auipc	a0,0x1
ffffffffc020114e:	0ee50513          	addi	a0,a0,238 # ffffffffc0202238 <commands+0x518>
ffffffffc0201152:	a5aff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0201156 <pa2page.part.0>:
它的作用是将物理地址转换为对应的 Page 结构体指针。
通过 PPN 宏获取物理页面号，然后判断物理页面号是否大于等于全局变量 npage
如果是，则表示物理地址无效，会触发 panic 异常
如果物理地址有效，则通过 pages 数组和物理页面号计算出对应的 Page 结构体指针，并返回该指针。
*/
static inline struct Page *pa2page(uintptr_t pa)
ffffffffc0201156:	1141                	addi	sp,sp,-16
{
    if (PPN(pa) >= npage)
    {
        panic("pa2page called with invalid pa");
ffffffffc0201158:	00001617          	auipc	a2,0x1
ffffffffc020115c:	6b860613          	addi	a2,a2,1720 # ffffffffc0202810 <buddy_system_pmm_manager+0x38>
ffffffffc0201160:	08200593          	li	a1,130
ffffffffc0201164:	00001517          	auipc	a0,0x1
ffffffffc0201168:	6cc50513          	addi	a0,a0,1740 # ffffffffc0202830 <buddy_system_pmm_manager+0x58>
static inline struct Page *pa2page(uintptr_t pa)
ffffffffc020116c:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc020116e:	a3eff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0201172 <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201172:	100027f3          	csrr	a5,sstatus
ffffffffc0201176:	8b89                	andi	a5,a5,2
ffffffffc0201178:	e799                	bnez	a5,ffffffffc0201186 <alloc_pages+0x14>
    // 为确保内存管理修改相关数据时不被中断打断，提供两个功能，
    // 一个是保存 sstatus寄存器中的中断使能位(SIE)信息并屏蔽中断的功能，
    // 另一个是根据保存的中断使能位信息来使能中断的功能
    local_intr_save(intr_flag); // 禁止中断，保证物理内存管理器的操作原子性，即不能被其他中断打断
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc020117a:	00005797          	auipc	a5,0x5
ffffffffc020117e:	3c67b783          	ld	a5,966(a5) # ffffffffc0206540 <pmm_manager>
ffffffffc0201182:	6f9c                	ld	a5,24(a5)
ffffffffc0201184:	8782                	jr	a5
{
ffffffffc0201186:	1141                	addi	sp,sp,-16
ffffffffc0201188:	e406                	sd	ra,8(sp)
ffffffffc020118a:	e022                	sd	s0,0(sp)
ffffffffc020118c:	842a                	mv	s0,a0
        intr_disable();
ffffffffc020118e:	ad0ff0ef          	jal	ra,ffffffffc020045e <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201192:	00005797          	auipc	a5,0x5
ffffffffc0201196:	3ae7b783          	ld	a5,942(a5) # ffffffffc0206540 <pmm_manager>
ffffffffc020119a:	6f9c                	ld	a5,24(a5)
ffffffffc020119c:	8522                	mv	a0,s0
ffffffffc020119e:	9782                	jalr	a5
ffffffffc02011a0:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc02011a2:	ab6ff0ef          	jal	ra,ffffffffc0200458 <intr_enable>
    }
    local_intr_restore(intr_flag); // 恢复中断
    return page;
}
ffffffffc02011a6:	60a2                	ld	ra,8(sp)
ffffffffc02011a8:	8522                	mv	a0,s0
ffffffffc02011aa:	6402                	ld	s0,0(sp)
ffffffffc02011ac:	0141                	addi	sp,sp,16
ffffffffc02011ae:	8082                	ret

ffffffffc02011b0 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02011b0:	100027f3          	csrr	a5,sstatus
ffffffffc02011b4:	8b89                	andi	a5,a5,2
ffffffffc02011b6:	e799                	bnez	a5,ffffffffc02011c4 <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc02011b8:	00005797          	auipc	a5,0x5
ffffffffc02011bc:	3887b783          	ld	a5,904(a5) # ffffffffc0206540 <pmm_manager>
ffffffffc02011c0:	739c                	ld	a5,32(a5)
ffffffffc02011c2:	8782                	jr	a5
{
ffffffffc02011c4:	1101                	addi	sp,sp,-32
ffffffffc02011c6:	ec06                	sd	ra,24(sp)
ffffffffc02011c8:	e822                	sd	s0,16(sp)
ffffffffc02011ca:	e426                	sd	s1,8(sp)
ffffffffc02011cc:	842a                	mv	s0,a0
ffffffffc02011ce:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc02011d0:	a8eff0ef          	jal	ra,ffffffffc020045e <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02011d4:	00005797          	auipc	a5,0x5
ffffffffc02011d8:	36c7b783          	ld	a5,876(a5) # ffffffffc0206540 <pmm_manager>
ffffffffc02011dc:	739c                	ld	a5,32(a5)
ffffffffc02011de:	85a6                	mv	a1,s1
ffffffffc02011e0:	8522                	mv	a0,s0
ffffffffc02011e2:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc02011e4:	6442                	ld	s0,16(sp)
ffffffffc02011e6:	60e2                	ld	ra,24(sp)
ffffffffc02011e8:	64a2                	ld	s1,8(sp)
ffffffffc02011ea:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02011ec:	a6cff06f          	j	ffffffffc0200458 <intr_enable>

ffffffffc02011f0 <pmm_init>:
    pmm_manager = &buddy_system_pmm_manager;
ffffffffc02011f0:	00001797          	auipc	a5,0x1
ffffffffc02011f4:	5e878793          	addi	a5,a5,1512 # ffffffffc02027d8 <buddy_system_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02011f8:	638c                	ld	a1,0(a5)
    // 0x8000-0x7cb9=0x0347个不可用，这些页存的是结构体page的数据
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void)
{
ffffffffc02011fa:	715d                	addi	sp,sp,-80
ffffffffc02011fc:	f44e                	sd	s3,40(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02011fe:	00001517          	auipc	a0,0x1
ffffffffc0201202:	64250513          	addi	a0,a0,1602 # ffffffffc0202840 <buddy_system_pmm_manager+0x68>
    pmm_manager = &buddy_system_pmm_manager;
ffffffffc0201206:	00005997          	auipc	s3,0x5
ffffffffc020120a:	33a98993          	addi	s3,s3,826 # ffffffffc0206540 <pmm_manager>
{
ffffffffc020120e:	e486                	sd	ra,72(sp)
ffffffffc0201210:	e0a2                	sd	s0,64(sp)
ffffffffc0201212:	f84a                	sd	s2,48(sp)
ffffffffc0201214:	f052                	sd	s4,32(sp)
ffffffffc0201216:	ec56                	sd	s5,24(sp)
    pmm_manager = &buddy_system_pmm_manager;
ffffffffc0201218:	00f9b023          	sd	a5,0(s3)
{
ffffffffc020121c:	fc26                	sd	s1,56(sp)
ffffffffc020121e:	e85a                	sd	s6,16(sp)
ffffffffc0201220:	e45e                	sd	s7,8(sp)
ffffffffc0201222:	e062                	sd	s8,0(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201224:	e8ffe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    pmm_manager->init();
ffffffffc0201228:	0009b783          	ld	a5,0(s3)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET; // 设置虚拟到物理地址的偏移: 硬编码0xFFFFFFFF40000000
ffffffffc020122c:	00005917          	auipc	s2,0x5
ffffffffc0201230:	32c90913          	addi	s2,s2,812 # ffffffffc0206558 <va_pa_offset>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0201234:	4445                	li	s0,17
    pmm_manager->init();
ffffffffc0201236:	679c                	ld	a5,8(a5)
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0201238:	046e                	slli	s0,s0,0x1b
    npage = maxpa / PGSIZE;
ffffffffc020123a:	00005a97          	auipc	s5,0x5
ffffffffc020123e:	2f6a8a93          	addi	s5,s5,758 # ffffffffc0206530 <npage>
    pmm_manager->init();
ffffffffc0201242:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET; // 设置虚拟到物理地址的偏移: 硬编码0xFFFFFFFF40000000
ffffffffc0201244:	57f5                	li	a5,-3
ffffffffc0201246:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc0201248:	00001517          	auipc	a0,0x1
ffffffffc020124c:	61050513          	addi	a0,a0,1552 # ffffffffc0202858 <buddy_system_pmm_manager+0x80>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET; // 设置虚拟到物理地址的偏移: 硬编码0xFFFFFFFF40000000
ffffffffc0201250:	00f93023          	sd	a5,0(s2)
    cprintf("physcial memory map:\n");
ffffffffc0201254:	e5ffe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0201258:	40100613          	li	a2,1025
ffffffffc020125c:	fff40693          	addi	a3,s0,-1
ffffffffc0201260:	0656                	slli	a2,a2,0x15
ffffffffc0201262:	07e005b7          	lui	a1,0x7e00
ffffffffc0201266:	00001517          	auipc	a0,0x1
ffffffffc020126a:	60a50513          	addi	a0,a0,1546 # ffffffffc0202870 <buddy_system_pmm_manager+0x98>
ffffffffc020126e:	e45fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("maxpa: 0x%016lx.\n", maxpa); // test point
ffffffffc0201272:	85a2                	mv	a1,s0
ffffffffc0201274:	00001517          	auipc	a0,0x1
ffffffffc0201278:	62c50513          	addi	a0,a0,1580 # ffffffffc02028a0 <buddy_system_pmm_manager+0xc8>
ffffffffc020127c:	e37fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0201280:	000887b7          	lui	a5,0x88
    cprintf("npage: 0x%016lx.\n", npage); // test point,为0x8800_0
ffffffffc0201284:	000885b7          	lui	a1,0x88
ffffffffc0201288:	00001517          	auipc	a0,0x1
ffffffffc020128c:	63050513          	addi	a0,a0,1584 # ffffffffc02028b8 <buddy_system_pmm_manager+0xe0>
    npage = maxpa / PGSIZE;
ffffffffc0201290:	00fab023          	sd	a5,0(s5)
    cprintf("npage: 0x%016lx.\n", npage); // test point,为0x8800_0
ffffffffc0201294:	e1ffe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("nbase: 0x%016lx.\n", nbase); // test point，为0x8000_0
ffffffffc0201298:	000805b7          	lui	a1,0x80
ffffffffc020129c:	00001517          	auipc	a0,0x1
ffffffffc02012a0:	63450513          	addi	a0,a0,1588 # ffffffffc02028d0 <buddy_system_pmm_manager+0xf8>
ffffffffc02012a4:	e0ffe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("end pythical address: 0x%016lx.\n", PADDR((uintptr_t)end)); // test point
ffffffffc02012a8:	c0200a37          	lui	s4,0xc0200
ffffffffc02012ac:	00005697          	auipc	a3,0x5
ffffffffc02012b0:	2bc68693          	addi	a3,a3,700 # ffffffffc0206568 <end>
ffffffffc02012b4:	2746e963          	bltu	a3,s4,ffffffffc0201526 <pmm_init+0x336>
ffffffffc02012b8:	00093583          	ld	a1,0(s2)
ffffffffc02012bc:	00001517          	auipc	a0,0x1
ffffffffc02012c0:	66450513          	addi	a0,a0,1636 # ffffffffc0202920 <buddy_system_pmm_manager+0x148>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02012c4:	00005497          	auipc	s1,0x5
ffffffffc02012c8:	27448493          	addi	s1,s1,628 # ffffffffc0206538 <pages>
    cprintf("end pythical address: 0x%016lx.\n", PADDR((uintptr_t)end)); // test point
ffffffffc02012cc:	40b685b3          	sub	a1,a3,a1
ffffffffc02012d0:	de3fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02012d4:	00006697          	auipc	a3,0x6
ffffffffc02012d8:	29368693          	addi	a3,a3,659 # ffffffffc0207567 <end+0xfff>
ffffffffc02012dc:	75fd                	lui	a1,0xfffff
ffffffffc02012de:	8eed                	and	a3,a3,a1
ffffffffc02012e0:	e094                	sd	a3,0(s1)
    cprintf("pages pythical address: 0x%016lx.\n", PADDR((uintptr_t)pages)); // test point
ffffffffc02012e2:	2346e663          	bltu	a3,s4,ffffffffc020150e <pmm_init+0x31e>
ffffffffc02012e6:	00093583          	ld	a1,0(s2)
ffffffffc02012ea:	00001517          	auipc	a0,0x1
ffffffffc02012ee:	65e50513          	addi	a0,a0,1630 # ffffffffc0202948 <buddy_system_pmm_manager+0x170>
ffffffffc02012f2:	40b685b3          	sub	a1,a3,a1
ffffffffc02012f6:	dbdfe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02012fa:	000ab503          	ld	a0,0(s5)
ffffffffc02012fe:	000807b7          	lui	a5,0x80
ffffffffc0201302:	4681                	li	a3,0
ffffffffc0201304:	4701                	li	a4,0
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201306:	4585                	li	a1,1
ffffffffc0201308:	fff80637          	lui	a2,0xfff80
ffffffffc020130c:	00f50f63          	beq	a0,a5,ffffffffc020132a <pmm_init+0x13a>
        SetPageReserved(pages + i); // 在memlayout.h中，SetPageReserved是一个宏，将给定的页面标记为保留给内存使用的
ffffffffc0201310:	609c                	ld	a5,0(s1)
ffffffffc0201312:	97b6                	add	a5,a5,a3
ffffffffc0201314:	07a1                	addi	a5,a5,8
ffffffffc0201316:	40b7b02f          	amoor.d	zero,a1,(a5)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020131a:	000ab783          	ld	a5,0(s5)
ffffffffc020131e:	0705                	addi	a4,a4,1
ffffffffc0201320:	02868693          	addi	a3,a3,40
ffffffffc0201324:	97b2                	add	a5,a5,a2
ffffffffc0201326:	fef765e3          	bltu	a4,a5,ffffffffc0201310 <pmm_init+0x120>
ffffffffc020132a:	4a01                	li	s4,0
    for (size_t i = 0; i < 5; i++)
ffffffffc020132c:	4401                	li	s0,0
        cprintf("pages[%d] pythical address: 0x%016lx.\n", i, PADDR((uintptr_t)(pages + i))); // test point
ffffffffc020132e:	c0200b37          	lui	s6,0xc0200
ffffffffc0201332:	00001c17          	auipc	s8,0x1
ffffffffc0201336:	63ec0c13          	addi	s8,s8,1598 # ffffffffc0202970 <buddy_system_pmm_manager+0x198>
    for (size_t i = 0; i < 5; i++)
ffffffffc020133a:	4b95                	li	s7,5
        cprintf("pages[%d] pythical address: 0x%016lx.\n", i, PADDR((uintptr_t)(pages + i))); // test point
ffffffffc020133c:	6094                	ld	a3,0(s1)
ffffffffc020133e:	96d2                	add	a3,a3,s4
ffffffffc0201340:	1966e063          	bltu	a3,s6,ffffffffc02014c0 <pmm_init+0x2d0>
ffffffffc0201344:	00093603          	ld	a2,0(s2)
ffffffffc0201348:	85a2                	mv	a1,s0
ffffffffc020134a:	8562                	mv	a0,s8
ffffffffc020134c:	40c68633          	sub	a2,a3,a2
    for (size_t i = 0; i < 5; i++)
ffffffffc0201350:	0405                	addi	s0,s0,1
        cprintf("pages[%d] pythical address: 0x%016lx.\n", i, PADDR((uintptr_t)(pages + i))); // test point
ffffffffc0201352:	d61fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    for (size_t i = 0; i < 5; i++)
ffffffffc0201356:	028a0a13          	addi	s4,s4,40 # ffffffffc0200028 <kern_entry+0x28>
ffffffffc020135a:	ff7411e3          	bne	s0,s7,ffffffffc020133c <pmm_init+0x14c>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase)); // 0x8034 7000 = 0x8020 7000 + 0x28 * 0x8000
ffffffffc020135e:	000ab783          	ld	a5,0(s5)
ffffffffc0201362:	6080                	ld	s0,0(s1)
ffffffffc0201364:	00279693          	slli	a3,a5,0x2
ffffffffc0201368:	96be                	add	a3,a3,a5
ffffffffc020136a:	068e                	slli	a3,a3,0x3
ffffffffc020136c:	9436                	add	s0,s0,a3
ffffffffc020136e:	fec006b7          	lui	a3,0xfec00
ffffffffc0201372:	9436                	add	s0,s0,a3
ffffffffc0201374:	19646063          	bltu	s0,s6,ffffffffc02014f4 <pmm_init+0x304>
ffffffffc0201378:	00093683          	ld	a3,0(s2)
    cprintf("size of struct page: 0x%016lx.\n", sizeof(struct Page));                         // test point
ffffffffc020137c:	02800593          	li	a1,40
ffffffffc0201380:	00001517          	auipc	a0,0x1
ffffffffc0201384:	61850513          	addi	a0,a0,1560 # ffffffffc0202998 <buddy_system_pmm_manager+0x1c0>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201388:	6a05                	lui	s4,0x1
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase)); // 0x8034 7000 = 0x8020 7000 + 0x28 * 0x8000
ffffffffc020138a:	8c15                	sub	s0,s0,a3
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc020138c:	1a7d                	addi	s4,s4,-1
    cprintf("size of struct page: 0x%016lx.\n", sizeof(struct Page));                         // test point
ffffffffc020138e:	d25fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201392:	75fd                	lui	a1,0xfffff
ffffffffc0201394:	9a22                	add	s4,s4,s0
ffffffffc0201396:	00ba7a33          	and	s4,s4,a1
    cprintf("freemem: 0x%016lx.\n", freemem);     // test point
ffffffffc020139a:	00001517          	auipc	a0,0x1
ffffffffc020139e:	61e50513          	addi	a0,a0,1566 # ffffffffc02029b8 <buddy_system_pmm_manager+0x1e0>
ffffffffc02013a2:	85a2                	mv	a1,s0
ffffffffc02013a4:	d0ffe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("mem_begin: 0x%016lx.\n", mem_begin); // test point
ffffffffc02013a8:	85d2                	mv	a1,s4
ffffffffc02013aa:	00001517          	auipc	a0,0x1
ffffffffc02013ae:	68e50513          	addi	a0,a0,1678 # ffffffffc0202a38 <buddy_system_pmm_manager+0x260>
ffffffffc02013b2:	d01fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("mem_end: 0x%016lx.\n", mem_end);     // test point
ffffffffc02013b6:	4b45                	li	s6,17
ffffffffc02013b8:	01bb1593          	slli	a1,s6,0x1b
ffffffffc02013bc:	00001517          	auipc	a0,0x1
ffffffffc02013c0:	61450513          	addi	a0,a0,1556 # ffffffffc02029d0 <buddy_system_pmm_manager+0x1f8>
    if (freemem < mem_end)
ffffffffc02013c4:	0b6e                	slli	s6,s6,0x1b
    cprintf("mem_end: 0x%016lx.\n", mem_end);     // test point
ffffffffc02013c6:	cedfe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    if (PPN(pa) >= npage)
ffffffffc02013ca:	00ca5b93          	srli	s7,s4,0xc
    if (freemem < mem_end)
ffffffffc02013ce:	0d646263          	bltu	s0,s6,ffffffffc0201492 <pmm_init+0x2a2>
ffffffffc02013d2:	000ab783          	ld	a5,0(s5)
ffffffffc02013d6:	10fbf163          	bgeu	s7,a5,ffffffffc02014d8 <pmm_init+0x2e8>
    }
    return &pages[PPN(pa) - nbase];
ffffffffc02013da:	fff80437          	lui	s0,0xfff80
ffffffffc02013de:	008b86b3          	add	a3,s7,s0
ffffffffc02013e2:	608c                	ld	a1,0(s1)
ffffffffc02013e4:	00269413          	slli	s0,a3,0x2
ffffffffc02013e8:	9436                	add	s0,s0,a3
ffffffffc02013ea:	040e                	slli	s0,s0,0x3
    cprintf("The Virtual Address corresponding to the page structure record (struct page) of mem_begin: 0x%016lx.\n", pa2page(mem_begin));        // test point
ffffffffc02013ec:	95a2                	add	a1,a1,s0
ffffffffc02013ee:	00001517          	auipc	a0,0x1
ffffffffc02013f2:	5fa50513          	addi	a0,a0,1530 # ffffffffc02029e8 <buddy_system_pmm_manager+0x210>
ffffffffc02013f6:	cbdfe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    if (PPN(pa) >= npage)
ffffffffc02013fa:	000ab783          	ld	a5,0(s5)
ffffffffc02013fe:	0cfbfd63          	bgeu	s7,a5,ffffffffc02014d8 <pmm_init+0x2e8>
    return &pages[PPN(pa) - nbase];
ffffffffc0201402:	6094                	ld	a3,0(s1)
    cprintf("The Physical Address corresponding to the page structure record (struct page) of mem_begin: 0x%016lx.\n", PADDR(pa2page(mem_begin))); // test point
ffffffffc0201404:	c02004b7          	lui	s1,0xc0200
ffffffffc0201408:	96a2                	add	a3,a3,s0
ffffffffc020140a:	0c96e963          	bltu	a3,s1,ffffffffc02014dc <pmm_init+0x2ec>
ffffffffc020140e:	00093583          	ld	a1,0(s2)
ffffffffc0201412:	00001517          	auipc	a0,0x1
ffffffffc0201416:	63e50513          	addi	a0,a0,1598 # ffffffffc0202a50 <buddy_system_pmm_manager+0x278>
ffffffffc020141a:	40b685b3          	sub	a1,a3,a1
ffffffffc020141e:	c95fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("counts of free pages available to use: 0x%016lx.\n", (mem_end - mem_begin) / PGSIZE); // test point
ffffffffc0201422:	45c5                	li	a1,17
ffffffffc0201424:	05ee                	slli	a1,a1,0x1b
ffffffffc0201426:	414585b3          	sub	a1,a1,s4
ffffffffc020142a:	81b1                	srli	a1,a1,0xc
ffffffffc020142c:	00001517          	auipc	a0,0x1
ffffffffc0201430:	68c50513          	addi	a0,a0,1676 # ffffffffc0202ab8 <buddy_system_pmm_manager+0x2e0>
ffffffffc0201434:	c7ffe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0201438:	0009b783          	ld	a5,0(s3)
ffffffffc020143c:	7b9c                	ld	a5,48(a5)
ffffffffc020143e:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201440:	00001517          	auipc	a0,0x1
ffffffffc0201444:	6b050513          	addi	a0,a0,1712 # ffffffffc0202af0 <buddy_system_pmm_manager+0x318>
ffffffffc0201448:	c6bfe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    satp_virtual = (pte_t *)boot_page_table_sv39; // pte_t 页表项
ffffffffc020144c:	00004597          	auipc	a1,0x4
ffffffffc0201450:	bb458593          	addi	a1,a1,-1100 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0201454:	00005797          	auipc	a5,0x5
ffffffffc0201458:	0eb7be23          	sd	a1,252(a5) # ffffffffc0206550 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc020145c:	0e95e163          	bltu	a1,s1,ffffffffc020153e <pmm_init+0x34e>
ffffffffc0201460:	00093603          	ld	a2,0(s2)
}
ffffffffc0201464:	6406                	ld	s0,64(sp)
ffffffffc0201466:	60a6                	ld	ra,72(sp)
ffffffffc0201468:	74e2                	ld	s1,56(sp)
ffffffffc020146a:	7942                	ld	s2,48(sp)
ffffffffc020146c:	79a2                	ld	s3,40(sp)
ffffffffc020146e:	7a02                	ld	s4,32(sp)
ffffffffc0201470:	6ae2                	ld	s5,24(sp)
ffffffffc0201472:	6b42                	ld	s6,16(sp)
ffffffffc0201474:	6ba2                	ld	s7,8(sp)
ffffffffc0201476:	6c02                	ld	s8,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0201478:	40c58633          	sub	a2,a1,a2
ffffffffc020147c:	00005797          	auipc	a5,0x5
ffffffffc0201480:	0cc7b623          	sd	a2,204(a5) # ffffffffc0206548 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201484:	00001517          	auipc	a0,0x1
ffffffffc0201488:	68c50513          	addi	a0,a0,1676 # ffffffffc0202b10 <buddy_system_pmm_manager+0x338>
}
ffffffffc020148c:	6161                	addi	sp,sp,80
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020148e:	c25fe06f          	j	ffffffffc02000b2 <cprintf>
    if (PPN(pa) >= npage)
ffffffffc0201492:	000ab783          	ld	a5,0(s5)
ffffffffc0201496:	04fbf163          	bgeu	s7,a5,ffffffffc02014d8 <pmm_init+0x2e8>
    pmm_manager->init_memmap(base, n);
ffffffffc020149a:	0009b683          	ld	a3,0(s3)
    return &pages[PPN(pa) - nbase];
ffffffffc020149e:	fff807b7          	lui	a5,0xfff80
ffffffffc02014a2:	00fb8733          	add	a4,s7,a5
ffffffffc02014a6:	6088                	ld	a0,0(s1)
ffffffffc02014a8:	00271793          	slli	a5,a4,0x2
ffffffffc02014ac:	97ba                	add	a5,a5,a4
ffffffffc02014ae:	6a98                	ld	a4,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc02014b0:	414b0b33          	sub	s6,s6,s4
ffffffffc02014b4:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc02014b6:	00cb5593          	srli	a1,s6,0xc
ffffffffc02014ba:	953e                	add	a0,a0,a5
ffffffffc02014bc:	9702                	jalr	a4
}
ffffffffc02014be:	bf11                	j	ffffffffc02013d2 <pmm_init+0x1e2>
        cprintf("pages[%d] pythical address: 0x%016lx.\n", i, PADDR((uintptr_t)(pages + i))); // test point
ffffffffc02014c0:	00001617          	auipc	a2,0x1
ffffffffc02014c4:	42860613          	addi	a2,a2,1064 # ffffffffc02028e8 <buddy_system_pmm_manager+0x110>
ffffffffc02014c8:	09200593          	li	a1,146
ffffffffc02014cc:	00001517          	auipc	a0,0x1
ffffffffc02014d0:	44450513          	addi	a0,a0,1092 # ffffffffc0202910 <buddy_system_pmm_manager+0x138>
ffffffffc02014d4:	ed9fe0ef          	jal	ra,ffffffffc02003ac <__panic>
ffffffffc02014d8:	c7fff0ef          	jal	ra,ffffffffc0201156 <pa2page.part.0>
    cprintf("The Physical Address corresponding to the page structure record (struct page) of mem_begin: 0x%016lx.\n", PADDR(pa2page(mem_begin))); // test point
ffffffffc02014dc:	00001617          	auipc	a2,0x1
ffffffffc02014e0:	40c60613          	addi	a2,a2,1036 # ffffffffc02028e8 <buddy_system_pmm_manager+0x110>
ffffffffc02014e4:	0a900593          	li	a1,169
ffffffffc02014e8:	00001517          	auipc	a0,0x1
ffffffffc02014ec:	42850513          	addi	a0,a0,1064 # ffffffffc0202910 <buddy_system_pmm_manager+0x138>
ffffffffc02014f0:	ebdfe0ef          	jal	ra,ffffffffc02003ac <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase)); // 0x8034 7000 = 0x8020 7000 + 0x28 * 0x8000
ffffffffc02014f4:	86a2                	mv	a3,s0
ffffffffc02014f6:	00001617          	auipc	a2,0x1
ffffffffc02014fa:	3f260613          	addi	a2,a2,1010 # ffffffffc02028e8 <buddy_system_pmm_manager+0x110>
ffffffffc02014fe:	09900593          	li	a1,153
ffffffffc0201502:	00001517          	auipc	a0,0x1
ffffffffc0201506:	40e50513          	addi	a0,a0,1038 # ffffffffc0202910 <buddy_system_pmm_manager+0x138>
ffffffffc020150a:	ea3fe0ef          	jal	ra,ffffffffc02003ac <__panic>
    cprintf("pages pythical address: 0x%016lx.\n", PADDR((uintptr_t)pages)); // test point
ffffffffc020150e:	00001617          	auipc	a2,0x1
ffffffffc0201512:	3da60613          	addi	a2,a2,986 # ffffffffc02028e8 <buddy_system_pmm_manager+0x110>
ffffffffc0201516:	08600593          	li	a1,134
ffffffffc020151a:	00001517          	auipc	a0,0x1
ffffffffc020151e:	3f650513          	addi	a0,a0,1014 # ffffffffc0202910 <buddy_system_pmm_manager+0x138>
ffffffffc0201522:	e8bfe0ef          	jal	ra,ffffffffc02003ac <__panic>
    cprintf("end pythical address: 0x%016lx.\n", PADDR((uintptr_t)end)); // test point
ffffffffc0201526:	00001617          	auipc	a2,0x1
ffffffffc020152a:	3c260613          	addi	a2,a2,962 # ffffffffc02028e8 <buddy_system_pmm_manager+0x110>
ffffffffc020152e:	08400593          	li	a1,132
ffffffffc0201532:	00001517          	auipc	a0,0x1
ffffffffc0201536:	3de50513          	addi	a0,a0,990 # ffffffffc0202910 <buddy_system_pmm_manager+0x138>
ffffffffc020153a:	e73fe0ef          	jal	ra,ffffffffc02003ac <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc020153e:	86ae                	mv	a3,a1
ffffffffc0201540:	00001617          	auipc	a2,0x1
ffffffffc0201544:	3a860613          	addi	a2,a2,936 # ffffffffc02028e8 <buddy_system_pmm_manager+0x110>
ffffffffc0201548:	0c500593          	li	a1,197
ffffffffc020154c:	00001517          	auipc	a0,0x1
ffffffffc0201550:	3c450513          	addi	a0,a0,964 # ffffffffc0202910 <buddy_system_pmm_manager+0x138>
ffffffffc0201554:	e59fe0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0201558 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201558:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020155c:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc020155e:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201562:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201564:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201568:	f022                	sd	s0,32(sp)
ffffffffc020156a:	ec26                	sd	s1,24(sp)
ffffffffc020156c:	e84a                	sd	s2,16(sp)
ffffffffc020156e:	f406                	sd	ra,40(sp)
ffffffffc0201570:	e44e                	sd	s3,8(sp)
ffffffffc0201572:	84aa                	mv	s1,a0
ffffffffc0201574:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201576:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc020157a:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc020157c:	03067e63          	bgeu	a2,a6,ffffffffc02015b8 <printnum+0x60>
ffffffffc0201580:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201582:	00805763          	blez	s0,ffffffffc0201590 <printnum+0x38>
ffffffffc0201586:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201588:	85ca                	mv	a1,s2
ffffffffc020158a:	854e                	mv	a0,s3
ffffffffc020158c:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc020158e:	fc65                	bnez	s0,ffffffffc0201586 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201590:	1a02                	slli	s4,s4,0x20
ffffffffc0201592:	00001797          	auipc	a5,0x1
ffffffffc0201596:	5be78793          	addi	a5,a5,1470 # ffffffffc0202b50 <buddy_system_pmm_manager+0x378>
ffffffffc020159a:	020a5a13          	srli	s4,s4,0x20
ffffffffc020159e:	9a3e                	add	s4,s4,a5
}
ffffffffc02015a0:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02015a2:	000a4503          	lbu	a0,0(s4) # 1000 <kern_entry-0xffffffffc01ff000>
}
ffffffffc02015a6:	70a2                	ld	ra,40(sp)
ffffffffc02015a8:	69a2                	ld	s3,8(sp)
ffffffffc02015aa:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02015ac:	85ca                	mv	a1,s2
ffffffffc02015ae:	87a6                	mv	a5,s1
}
ffffffffc02015b0:	6942                	ld	s2,16(sp)
ffffffffc02015b2:	64e2                	ld	s1,24(sp)
ffffffffc02015b4:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02015b6:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02015b8:	03065633          	divu	a2,a2,a6
ffffffffc02015bc:	8722                	mv	a4,s0
ffffffffc02015be:	f9bff0ef          	jal	ra,ffffffffc0201558 <printnum>
ffffffffc02015c2:	b7f9                	j	ffffffffc0201590 <printnum+0x38>

ffffffffc02015c4 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02015c4:	7119                	addi	sp,sp,-128
ffffffffc02015c6:	f4a6                	sd	s1,104(sp)
ffffffffc02015c8:	f0ca                	sd	s2,96(sp)
ffffffffc02015ca:	ecce                	sd	s3,88(sp)
ffffffffc02015cc:	e8d2                	sd	s4,80(sp)
ffffffffc02015ce:	e4d6                	sd	s5,72(sp)
ffffffffc02015d0:	e0da                	sd	s6,64(sp)
ffffffffc02015d2:	fc5e                	sd	s7,56(sp)
ffffffffc02015d4:	f06a                	sd	s10,32(sp)
ffffffffc02015d6:	fc86                	sd	ra,120(sp)
ffffffffc02015d8:	f8a2                	sd	s0,112(sp)
ffffffffc02015da:	f862                	sd	s8,48(sp)
ffffffffc02015dc:	f466                	sd	s9,40(sp)
ffffffffc02015de:	ec6e                	sd	s11,24(sp)
ffffffffc02015e0:	892a                	mv	s2,a0
ffffffffc02015e2:	84ae                	mv	s1,a1
ffffffffc02015e4:	8d32                	mv	s10,a2
ffffffffc02015e6:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02015e8:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02015ec:	5b7d                	li	s6,-1
ffffffffc02015ee:	00001a97          	auipc	s5,0x1
ffffffffc02015f2:	596a8a93          	addi	s5,s5,1430 # ffffffffc0202b84 <buddy_system_pmm_manager+0x3ac>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02015f6:	00001b97          	auipc	s7,0x1
ffffffffc02015fa:	76ab8b93          	addi	s7,s7,1898 # ffffffffc0202d60 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02015fe:	000d4503          	lbu	a0,0(s10)
ffffffffc0201602:	001d0413          	addi	s0,s10,1
ffffffffc0201606:	01350a63          	beq	a0,s3,ffffffffc020161a <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc020160a:	c121                	beqz	a0,ffffffffc020164a <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc020160c:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020160e:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201610:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201612:	fff44503          	lbu	a0,-1(s0) # fffffffffff7ffff <end+0x3fd79a97>
ffffffffc0201616:	ff351ae3          	bne	a0,s3,ffffffffc020160a <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020161a:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc020161e:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201622:	4c81                	li	s9,0
ffffffffc0201624:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201626:	5c7d                	li	s8,-1
ffffffffc0201628:	5dfd                	li	s11,-1
ffffffffc020162a:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc020162e:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201630:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201634:	0ff5f593          	zext.b	a1,a1
ffffffffc0201638:	00140d13          	addi	s10,s0,1
ffffffffc020163c:	04b56263          	bltu	a0,a1,ffffffffc0201680 <vprintfmt+0xbc>
ffffffffc0201640:	058a                	slli	a1,a1,0x2
ffffffffc0201642:	95d6                	add	a1,a1,s5
ffffffffc0201644:	4194                	lw	a3,0(a1)
ffffffffc0201646:	96d6                	add	a3,a3,s5
ffffffffc0201648:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc020164a:	70e6                	ld	ra,120(sp)
ffffffffc020164c:	7446                	ld	s0,112(sp)
ffffffffc020164e:	74a6                	ld	s1,104(sp)
ffffffffc0201650:	7906                	ld	s2,96(sp)
ffffffffc0201652:	69e6                	ld	s3,88(sp)
ffffffffc0201654:	6a46                	ld	s4,80(sp)
ffffffffc0201656:	6aa6                	ld	s5,72(sp)
ffffffffc0201658:	6b06                	ld	s6,64(sp)
ffffffffc020165a:	7be2                	ld	s7,56(sp)
ffffffffc020165c:	7c42                	ld	s8,48(sp)
ffffffffc020165e:	7ca2                	ld	s9,40(sp)
ffffffffc0201660:	7d02                	ld	s10,32(sp)
ffffffffc0201662:	6de2                	ld	s11,24(sp)
ffffffffc0201664:	6109                	addi	sp,sp,128
ffffffffc0201666:	8082                	ret
            padc = '0';
ffffffffc0201668:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc020166a:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020166e:	846a                	mv	s0,s10
ffffffffc0201670:	00140d13          	addi	s10,s0,1
ffffffffc0201674:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201678:	0ff5f593          	zext.b	a1,a1
ffffffffc020167c:	fcb572e3          	bgeu	a0,a1,ffffffffc0201640 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201680:	85a6                	mv	a1,s1
ffffffffc0201682:	02500513          	li	a0,37
ffffffffc0201686:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201688:	fff44783          	lbu	a5,-1(s0)
ffffffffc020168c:	8d22                	mv	s10,s0
ffffffffc020168e:	f73788e3          	beq	a5,s3,ffffffffc02015fe <vprintfmt+0x3a>
ffffffffc0201692:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201696:	1d7d                	addi	s10,s10,-1
ffffffffc0201698:	ff379de3          	bne	a5,s3,ffffffffc0201692 <vprintfmt+0xce>
ffffffffc020169c:	b78d                	j	ffffffffc02015fe <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc020169e:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc02016a2:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02016a6:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc02016a8:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc02016ac:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02016b0:	02d86463          	bltu	a6,a3,ffffffffc02016d8 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc02016b4:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02016b8:	002c169b          	slliw	a3,s8,0x2
ffffffffc02016bc:	0186873b          	addw	a4,a3,s8
ffffffffc02016c0:	0017171b          	slliw	a4,a4,0x1
ffffffffc02016c4:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc02016c6:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02016ca:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02016cc:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc02016d0:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02016d4:	fed870e3          	bgeu	a6,a3,ffffffffc02016b4 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc02016d8:	f40ddce3          	bgez	s11,ffffffffc0201630 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc02016dc:	8de2                	mv	s11,s8
ffffffffc02016de:	5c7d                	li	s8,-1
ffffffffc02016e0:	bf81                	j	ffffffffc0201630 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc02016e2:	fffdc693          	not	a3,s11
ffffffffc02016e6:	96fd                	srai	a3,a3,0x3f
ffffffffc02016e8:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02016ec:	00144603          	lbu	a2,1(s0)
ffffffffc02016f0:	2d81                	sext.w	s11,s11
ffffffffc02016f2:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02016f4:	bf35                	j	ffffffffc0201630 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc02016f6:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02016fa:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02016fe:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201700:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201702:	bfd9                	j	ffffffffc02016d8 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0201704:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201706:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020170a:	01174463          	blt	a4,a7,ffffffffc0201712 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc020170e:	1a088e63          	beqz	a7,ffffffffc02018ca <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201712:	000a3603          	ld	a2,0(s4)
ffffffffc0201716:	46c1                	li	a3,16
ffffffffc0201718:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc020171a:	2781                	sext.w	a5,a5
ffffffffc020171c:	876e                	mv	a4,s11
ffffffffc020171e:	85a6                	mv	a1,s1
ffffffffc0201720:	854a                	mv	a0,s2
ffffffffc0201722:	e37ff0ef          	jal	ra,ffffffffc0201558 <printnum>
            break;
ffffffffc0201726:	bde1                	j	ffffffffc02015fe <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201728:	000a2503          	lw	a0,0(s4)
ffffffffc020172c:	85a6                	mv	a1,s1
ffffffffc020172e:	0a21                	addi	s4,s4,8
ffffffffc0201730:	9902                	jalr	s2
            break;
ffffffffc0201732:	b5f1                	j	ffffffffc02015fe <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201734:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201736:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020173a:	01174463          	blt	a4,a7,ffffffffc0201742 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc020173e:	18088163          	beqz	a7,ffffffffc02018c0 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201742:	000a3603          	ld	a2,0(s4)
ffffffffc0201746:	46a9                	li	a3,10
ffffffffc0201748:	8a2e                	mv	s4,a1
ffffffffc020174a:	bfc1                	j	ffffffffc020171a <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020174c:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201750:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201752:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201754:	bdf1                	j	ffffffffc0201630 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201756:	85a6                	mv	a1,s1
ffffffffc0201758:	02500513          	li	a0,37
ffffffffc020175c:	9902                	jalr	s2
            break;
ffffffffc020175e:	b545                	j	ffffffffc02015fe <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201760:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0201764:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201766:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201768:	b5e1                	j	ffffffffc0201630 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc020176a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020176c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201770:	01174463          	blt	a4,a7,ffffffffc0201778 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0201774:	14088163          	beqz	a7,ffffffffc02018b6 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201778:	000a3603          	ld	a2,0(s4)
ffffffffc020177c:	46a1                	li	a3,8
ffffffffc020177e:	8a2e                	mv	s4,a1
ffffffffc0201780:	bf69                	j	ffffffffc020171a <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201782:	03000513          	li	a0,48
ffffffffc0201786:	85a6                	mv	a1,s1
ffffffffc0201788:	e03e                	sd	a5,0(sp)
ffffffffc020178a:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc020178c:	85a6                	mv	a1,s1
ffffffffc020178e:	07800513          	li	a0,120
ffffffffc0201792:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201794:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201796:	6782                	ld	a5,0(sp)
ffffffffc0201798:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020179a:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc020179e:	bfb5                	j	ffffffffc020171a <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02017a0:	000a3403          	ld	s0,0(s4)
ffffffffc02017a4:	008a0713          	addi	a4,s4,8
ffffffffc02017a8:	e03a                	sd	a4,0(sp)
ffffffffc02017aa:	14040263          	beqz	s0,ffffffffc02018ee <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc02017ae:	0fb05763          	blez	s11,ffffffffc020189c <vprintfmt+0x2d8>
ffffffffc02017b2:	02d00693          	li	a3,45
ffffffffc02017b6:	0cd79163          	bne	a5,a3,ffffffffc0201878 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02017ba:	00044783          	lbu	a5,0(s0)
ffffffffc02017be:	0007851b          	sext.w	a0,a5
ffffffffc02017c2:	cf85                	beqz	a5,ffffffffc02017fa <vprintfmt+0x236>
ffffffffc02017c4:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02017c8:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02017cc:	000c4563          	bltz	s8,ffffffffc02017d6 <vprintfmt+0x212>
ffffffffc02017d0:	3c7d                	addiw	s8,s8,-1
ffffffffc02017d2:	036c0263          	beq	s8,s6,ffffffffc02017f6 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc02017d6:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02017d8:	0e0c8e63          	beqz	s9,ffffffffc02018d4 <vprintfmt+0x310>
ffffffffc02017dc:	3781                	addiw	a5,a5,-32
ffffffffc02017de:	0ef47b63          	bgeu	s0,a5,ffffffffc02018d4 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc02017e2:	03f00513          	li	a0,63
ffffffffc02017e6:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02017e8:	000a4783          	lbu	a5,0(s4)
ffffffffc02017ec:	3dfd                	addiw	s11,s11,-1
ffffffffc02017ee:	0a05                	addi	s4,s4,1
ffffffffc02017f0:	0007851b          	sext.w	a0,a5
ffffffffc02017f4:	ffe1                	bnez	a5,ffffffffc02017cc <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc02017f6:	01b05963          	blez	s11,ffffffffc0201808 <vprintfmt+0x244>
ffffffffc02017fa:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02017fc:	85a6                	mv	a1,s1
ffffffffc02017fe:	02000513          	li	a0,32
ffffffffc0201802:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201804:	fe0d9be3          	bnez	s11,ffffffffc02017fa <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201808:	6a02                	ld	s4,0(sp)
ffffffffc020180a:	bbd5                	j	ffffffffc02015fe <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020180c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020180e:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201812:	01174463          	blt	a4,a7,ffffffffc020181a <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201816:	08088d63          	beqz	a7,ffffffffc02018b0 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc020181a:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc020181e:	0a044d63          	bltz	s0,ffffffffc02018d8 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201822:	8622                	mv	a2,s0
ffffffffc0201824:	8a66                	mv	s4,s9
ffffffffc0201826:	46a9                	li	a3,10
ffffffffc0201828:	bdcd                	j	ffffffffc020171a <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc020182a:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020182e:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201830:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201832:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201836:	8fb5                	xor	a5,a5,a3
ffffffffc0201838:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020183c:	02d74163          	blt	a4,a3,ffffffffc020185e <vprintfmt+0x29a>
ffffffffc0201840:	00369793          	slli	a5,a3,0x3
ffffffffc0201844:	97de                	add	a5,a5,s7
ffffffffc0201846:	639c                	ld	a5,0(a5)
ffffffffc0201848:	cb99                	beqz	a5,ffffffffc020185e <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc020184a:	86be                	mv	a3,a5
ffffffffc020184c:	00001617          	auipc	a2,0x1
ffffffffc0201850:	33460613          	addi	a2,a2,820 # ffffffffc0202b80 <buddy_system_pmm_manager+0x3a8>
ffffffffc0201854:	85a6                	mv	a1,s1
ffffffffc0201856:	854a                	mv	a0,s2
ffffffffc0201858:	0ce000ef          	jal	ra,ffffffffc0201926 <printfmt>
ffffffffc020185c:	b34d                	j	ffffffffc02015fe <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc020185e:	00001617          	auipc	a2,0x1
ffffffffc0201862:	31260613          	addi	a2,a2,786 # ffffffffc0202b70 <buddy_system_pmm_manager+0x398>
ffffffffc0201866:	85a6                	mv	a1,s1
ffffffffc0201868:	854a                	mv	a0,s2
ffffffffc020186a:	0bc000ef          	jal	ra,ffffffffc0201926 <printfmt>
ffffffffc020186e:	bb41                	j	ffffffffc02015fe <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201870:	00001417          	auipc	s0,0x1
ffffffffc0201874:	2f840413          	addi	s0,s0,760 # ffffffffc0202b68 <buddy_system_pmm_manager+0x390>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201878:	85e2                	mv	a1,s8
ffffffffc020187a:	8522                	mv	a0,s0
ffffffffc020187c:	e43e                	sd	a5,8(sp)
ffffffffc020187e:	1e6000ef          	jal	ra,ffffffffc0201a64 <strnlen>
ffffffffc0201882:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201886:	01b05b63          	blez	s11,ffffffffc020189c <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc020188a:	67a2                	ld	a5,8(sp)
ffffffffc020188c:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201890:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201892:	85a6                	mv	a1,s1
ffffffffc0201894:	8552                	mv	a0,s4
ffffffffc0201896:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201898:	fe0d9ce3          	bnez	s11,ffffffffc0201890 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020189c:	00044783          	lbu	a5,0(s0)
ffffffffc02018a0:	00140a13          	addi	s4,s0,1
ffffffffc02018a4:	0007851b          	sext.w	a0,a5
ffffffffc02018a8:	d3a5                	beqz	a5,ffffffffc0201808 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02018aa:	05e00413          	li	s0,94
ffffffffc02018ae:	bf39                	j	ffffffffc02017cc <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc02018b0:	000a2403          	lw	s0,0(s4)
ffffffffc02018b4:	b7ad                	j	ffffffffc020181e <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc02018b6:	000a6603          	lwu	a2,0(s4)
ffffffffc02018ba:	46a1                	li	a3,8
ffffffffc02018bc:	8a2e                	mv	s4,a1
ffffffffc02018be:	bdb1                	j	ffffffffc020171a <vprintfmt+0x156>
ffffffffc02018c0:	000a6603          	lwu	a2,0(s4)
ffffffffc02018c4:	46a9                	li	a3,10
ffffffffc02018c6:	8a2e                	mv	s4,a1
ffffffffc02018c8:	bd89                	j	ffffffffc020171a <vprintfmt+0x156>
ffffffffc02018ca:	000a6603          	lwu	a2,0(s4)
ffffffffc02018ce:	46c1                	li	a3,16
ffffffffc02018d0:	8a2e                	mv	s4,a1
ffffffffc02018d2:	b5a1                	j	ffffffffc020171a <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc02018d4:	9902                	jalr	s2
ffffffffc02018d6:	bf09                	j	ffffffffc02017e8 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc02018d8:	85a6                	mv	a1,s1
ffffffffc02018da:	02d00513          	li	a0,45
ffffffffc02018de:	e03e                	sd	a5,0(sp)
ffffffffc02018e0:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02018e2:	6782                	ld	a5,0(sp)
ffffffffc02018e4:	8a66                	mv	s4,s9
ffffffffc02018e6:	40800633          	neg	a2,s0
ffffffffc02018ea:	46a9                	li	a3,10
ffffffffc02018ec:	b53d                	j	ffffffffc020171a <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc02018ee:	03b05163          	blez	s11,ffffffffc0201910 <vprintfmt+0x34c>
ffffffffc02018f2:	02d00693          	li	a3,45
ffffffffc02018f6:	f6d79de3          	bne	a5,a3,ffffffffc0201870 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc02018fa:	00001417          	auipc	s0,0x1
ffffffffc02018fe:	26e40413          	addi	s0,s0,622 # ffffffffc0202b68 <buddy_system_pmm_manager+0x390>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201902:	02800793          	li	a5,40
ffffffffc0201906:	02800513          	li	a0,40
ffffffffc020190a:	00140a13          	addi	s4,s0,1
ffffffffc020190e:	bd6d                	j	ffffffffc02017c8 <vprintfmt+0x204>
ffffffffc0201910:	00001a17          	auipc	s4,0x1
ffffffffc0201914:	259a0a13          	addi	s4,s4,601 # ffffffffc0202b69 <buddy_system_pmm_manager+0x391>
ffffffffc0201918:	02800513          	li	a0,40
ffffffffc020191c:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201920:	05e00413          	li	s0,94
ffffffffc0201924:	b565                	j	ffffffffc02017cc <vprintfmt+0x208>

ffffffffc0201926 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201926:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201928:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020192c:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020192e:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201930:	ec06                	sd	ra,24(sp)
ffffffffc0201932:	f83a                	sd	a4,48(sp)
ffffffffc0201934:	fc3e                	sd	a5,56(sp)
ffffffffc0201936:	e0c2                	sd	a6,64(sp)
ffffffffc0201938:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020193a:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020193c:	c89ff0ef          	jal	ra,ffffffffc02015c4 <vprintfmt>
}
ffffffffc0201940:	60e2                	ld	ra,24(sp)
ffffffffc0201942:	6161                	addi	sp,sp,80
ffffffffc0201944:	8082                	ret

ffffffffc0201946 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201946:	715d                	addi	sp,sp,-80
ffffffffc0201948:	e486                	sd	ra,72(sp)
ffffffffc020194a:	e0a6                	sd	s1,64(sp)
ffffffffc020194c:	fc4a                	sd	s2,56(sp)
ffffffffc020194e:	f84e                	sd	s3,48(sp)
ffffffffc0201950:	f452                	sd	s4,40(sp)
ffffffffc0201952:	f056                	sd	s5,32(sp)
ffffffffc0201954:	ec5a                	sd	s6,24(sp)
ffffffffc0201956:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc0201958:	c901                	beqz	a0,ffffffffc0201968 <readline+0x22>
ffffffffc020195a:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc020195c:	00001517          	auipc	a0,0x1
ffffffffc0201960:	22450513          	addi	a0,a0,548 # ffffffffc0202b80 <buddy_system_pmm_manager+0x3a8>
ffffffffc0201964:	f4efe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
readline(const char *prompt) {
ffffffffc0201968:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020196a:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc020196c:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc020196e:	4aa9                	li	s5,10
ffffffffc0201970:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0201972:	00004b97          	auipc	s7,0x4
ffffffffc0201976:	7a6b8b93          	addi	s7,s7,1958 # ffffffffc0206118 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020197a:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc020197e:	facfe0ef          	jal	ra,ffffffffc020012a <getchar>
        if (c < 0) {
ffffffffc0201982:	00054a63          	bltz	a0,ffffffffc0201996 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201986:	00a95a63          	bge	s2,a0,ffffffffc020199a <readline+0x54>
ffffffffc020198a:	029a5263          	bge	s4,s1,ffffffffc02019ae <readline+0x68>
        c = getchar();
ffffffffc020198e:	f9cfe0ef          	jal	ra,ffffffffc020012a <getchar>
        if (c < 0) {
ffffffffc0201992:	fe055ae3          	bgez	a0,ffffffffc0201986 <readline+0x40>
            return NULL;
ffffffffc0201996:	4501                	li	a0,0
ffffffffc0201998:	a091                	j	ffffffffc02019dc <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc020199a:	03351463          	bne	a0,s3,ffffffffc02019c2 <readline+0x7c>
ffffffffc020199e:	e8a9                	bnez	s1,ffffffffc02019f0 <readline+0xaa>
        c = getchar();
ffffffffc02019a0:	f8afe0ef          	jal	ra,ffffffffc020012a <getchar>
        if (c < 0) {
ffffffffc02019a4:	fe0549e3          	bltz	a0,ffffffffc0201996 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02019a8:	fea959e3          	bge	s2,a0,ffffffffc020199a <readline+0x54>
ffffffffc02019ac:	4481                	li	s1,0
            cputchar(c);
ffffffffc02019ae:	e42a                	sd	a0,8(sp)
ffffffffc02019b0:	f38fe0ef          	jal	ra,ffffffffc02000e8 <cputchar>
            buf[i ++] = c;
ffffffffc02019b4:	6522                	ld	a0,8(sp)
ffffffffc02019b6:	009b87b3          	add	a5,s7,s1
ffffffffc02019ba:	2485                	addiw	s1,s1,1
ffffffffc02019bc:	00a78023          	sb	a0,0(a5)
ffffffffc02019c0:	bf7d                	j	ffffffffc020197e <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc02019c2:	01550463          	beq	a0,s5,ffffffffc02019ca <readline+0x84>
ffffffffc02019c6:	fb651ce3          	bne	a0,s6,ffffffffc020197e <readline+0x38>
            cputchar(c);
ffffffffc02019ca:	f1efe0ef          	jal	ra,ffffffffc02000e8 <cputchar>
            buf[i] = '\0';
ffffffffc02019ce:	00004517          	auipc	a0,0x4
ffffffffc02019d2:	74a50513          	addi	a0,a0,1866 # ffffffffc0206118 <buf>
ffffffffc02019d6:	94aa                	add	s1,s1,a0
ffffffffc02019d8:	00048023          	sb	zero,0(s1) # ffffffffc0200000 <kern_entry>
            return buf;
        }
    }
}
ffffffffc02019dc:	60a6                	ld	ra,72(sp)
ffffffffc02019de:	6486                	ld	s1,64(sp)
ffffffffc02019e0:	7962                	ld	s2,56(sp)
ffffffffc02019e2:	79c2                	ld	s3,48(sp)
ffffffffc02019e4:	7a22                	ld	s4,40(sp)
ffffffffc02019e6:	7a82                	ld	s5,32(sp)
ffffffffc02019e8:	6b62                	ld	s6,24(sp)
ffffffffc02019ea:	6bc2                	ld	s7,16(sp)
ffffffffc02019ec:	6161                	addi	sp,sp,80
ffffffffc02019ee:	8082                	ret
            cputchar(c);
ffffffffc02019f0:	4521                	li	a0,8
ffffffffc02019f2:	ef6fe0ef          	jal	ra,ffffffffc02000e8 <cputchar>
            i --;
ffffffffc02019f6:	34fd                	addiw	s1,s1,-1
ffffffffc02019f8:	b759                	j	ffffffffc020197e <readline+0x38>

ffffffffc02019fa <sbi_console_putchar>:
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2)
{
    uint64_t ret_val;
    __asm__ volatile(
ffffffffc02019fa:	4781                	li	a5,0
ffffffffc02019fc:	00004717          	auipc	a4,0x4
ffffffffc0201a00:	60c73703          	ld	a4,1548(a4) # ffffffffc0206008 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201a04:	88ba                	mv	a7,a4
ffffffffc0201a06:	852a                	mv	a0,a0
ffffffffc0201a08:	85be                	mv	a1,a5
ffffffffc0201a0a:	863e                	mv	a2,a5
ffffffffc0201a0c:	00000073          	ecall
ffffffffc0201a10:	87aa                	mv	a5,a0
}

void sbi_console_putchar(unsigned char ch)
{
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201a12:	8082                	ret

ffffffffc0201a14 <sbi_set_timer>:
    __asm__ volatile(
ffffffffc0201a14:	4781                	li	a5,0
ffffffffc0201a16:	00005717          	auipc	a4,0x5
ffffffffc0201a1a:	b4a73703          	ld	a4,-1206(a4) # ffffffffc0206560 <SBI_SET_TIMER>
ffffffffc0201a1e:	88ba                	mv	a7,a4
ffffffffc0201a20:	852a                	mv	a0,a0
ffffffffc0201a22:	85be                	mv	a1,a5
ffffffffc0201a24:	863e                	mv	a2,a5
ffffffffc0201a26:	00000073          	ecall
ffffffffc0201a2a:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value)
{
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc0201a2c:	8082                	ret

ffffffffc0201a2e <sbi_console_getchar>:
    __asm__ volatile(
ffffffffc0201a2e:	4501                	li	a0,0
ffffffffc0201a30:	00004797          	auipc	a5,0x4
ffffffffc0201a34:	5d07b783          	ld	a5,1488(a5) # ffffffffc0206000 <SBI_CONSOLE_GETCHAR>
ffffffffc0201a38:	88be                	mv	a7,a5
ffffffffc0201a3a:	852a                	mv	a0,a0
ffffffffc0201a3c:	85aa                	mv	a1,a0
ffffffffc0201a3e:	862a                	mv	a2,a0
ffffffffc0201a40:	00000073          	ecall
ffffffffc0201a44:	852a                	mv	a0,a0

int sbi_console_getchar(void)
{
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
ffffffffc0201a46:	2501                	sext.w	a0,a0
ffffffffc0201a48:	8082                	ret

ffffffffc0201a4a <sbi_shutdown>:
    __asm__ volatile(
ffffffffc0201a4a:	4781                	li	a5,0
ffffffffc0201a4c:	00004717          	auipc	a4,0x4
ffffffffc0201a50:	5c473703          	ld	a4,1476(a4) # ffffffffc0206010 <SBI_SHUTDOWN>
ffffffffc0201a54:	88ba                	mv	a7,a4
ffffffffc0201a56:	853e                	mv	a0,a5
ffffffffc0201a58:	85be                	mv	a1,a5
ffffffffc0201a5a:	863e                	mv	a2,a5
ffffffffc0201a5c:	00000073          	ecall
ffffffffc0201a60:	87aa                	mv	a5,a0

void sbi_shutdown(void)
{
    sbi_call(SBI_SHUTDOWN, 0, 0, 0);
ffffffffc0201a62:	8082                	ret

ffffffffc0201a64 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201a64:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201a66:	e589                	bnez	a1,ffffffffc0201a70 <strnlen+0xc>
ffffffffc0201a68:	a811                	j	ffffffffc0201a7c <strnlen+0x18>
        cnt ++;
ffffffffc0201a6a:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201a6c:	00f58863          	beq	a1,a5,ffffffffc0201a7c <strnlen+0x18>
ffffffffc0201a70:	00f50733          	add	a4,a0,a5
ffffffffc0201a74:	00074703          	lbu	a4,0(a4)
ffffffffc0201a78:	fb6d                	bnez	a4,ffffffffc0201a6a <strnlen+0x6>
ffffffffc0201a7a:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201a7c:	852e                	mv	a0,a1
ffffffffc0201a7e:	8082                	ret

ffffffffc0201a80 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201a80:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201a84:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201a88:	cb89                	beqz	a5,ffffffffc0201a9a <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201a8a:	0505                	addi	a0,a0,1
ffffffffc0201a8c:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201a8e:	fee789e3          	beq	a5,a4,ffffffffc0201a80 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201a92:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201a96:	9d19                	subw	a0,a0,a4
ffffffffc0201a98:	8082                	ret
ffffffffc0201a9a:	4501                	li	a0,0
ffffffffc0201a9c:	bfed                	j	ffffffffc0201a96 <strcmp+0x16>

ffffffffc0201a9e <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201a9e:	00054783          	lbu	a5,0(a0)
ffffffffc0201aa2:	c799                	beqz	a5,ffffffffc0201ab0 <strchr+0x12>
        if (*s == c) {
ffffffffc0201aa4:	00f58763          	beq	a1,a5,ffffffffc0201ab2 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0201aa8:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0201aac:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201aae:	fbfd                	bnez	a5,ffffffffc0201aa4 <strchr+0x6>
    }
    return NULL;
ffffffffc0201ab0:	4501                	li	a0,0
}
ffffffffc0201ab2:	8082                	ret

ffffffffc0201ab4 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201ab4:	ca01                	beqz	a2,ffffffffc0201ac4 <memset+0x10>
ffffffffc0201ab6:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201ab8:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201aba:	0785                	addi	a5,a5,1
ffffffffc0201abc:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201ac0:	fec79de3          	bne	a5,a2,ffffffffc0201aba <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201ac4:	8082                	ret
