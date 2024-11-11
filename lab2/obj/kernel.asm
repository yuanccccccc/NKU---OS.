
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
ffffffffc020004a:	27b010ef          	jal	ra,ffffffffc0201ac4 <memset>
    cons_init();  // init the console
ffffffffc020004e:	3fc000ef          	jal	ra,ffffffffc020044a <cons_init>
    const char *message = "(NKU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200052:	00002517          	auipc	a0,0x2
ffffffffc0200056:	a8650513          	addi	a0,a0,-1402 # ffffffffc0201ad8 <etext+0x2>
ffffffffc020005a:	090000ef          	jal	ra,ffffffffc02000ea <cputs>

    print_kerninfo();
ffffffffc020005e:	0dc000ef          	jal	ra,ffffffffc020013a <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table 初始化中断描述符表IDT
ffffffffc0200062:	402000ef          	jal	ra,ffffffffc0200464 <idt_init>

    pmm_init();  // init physical memory management 物理内存管理
ffffffffc0200066:	19a010ef          	jal	ra,ffffffffc0201200 <pmm_init>
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
ffffffffc02000a6:	52e010ef          	jal	ra,ffffffffc02015d4 <vprintfmt>
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
ffffffffc02000dc:	4f8010ef          	jal	ra,ffffffffc02015d4 <vprintfmt>
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
ffffffffc0200140:	9bc50513          	addi	a0,a0,-1604 # ffffffffc0201af8 <etext+0x22>
void print_kerninfo(void) {
ffffffffc0200144:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200146:	f6dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc020014a:	00000597          	auipc	a1,0x0
ffffffffc020014e:	ee858593          	addi	a1,a1,-280 # ffffffffc0200032 <kern_init>
ffffffffc0200152:	00002517          	auipc	a0,0x2
ffffffffc0200156:	9c650513          	addi	a0,a0,-1594 # ffffffffc0201b18 <etext+0x42>
ffffffffc020015a:	f59ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020015e:	00002597          	auipc	a1,0x2
ffffffffc0200162:	97858593          	addi	a1,a1,-1672 # ffffffffc0201ad6 <etext>
ffffffffc0200166:	00002517          	auipc	a0,0x2
ffffffffc020016a:	9d250513          	addi	a0,a0,-1582 # ffffffffc0201b38 <etext+0x62>
ffffffffc020016e:	f45ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200172:	00006597          	auipc	a1,0x6
ffffffffc0200176:	ea658593          	addi	a1,a1,-346 # ffffffffc0206018 <buddy_s>
ffffffffc020017a:	00002517          	auipc	a0,0x2
ffffffffc020017e:	9de50513          	addi	a0,a0,-1570 # ffffffffc0201b58 <etext+0x82>
ffffffffc0200182:	f31ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200186:	00006597          	auipc	a1,0x6
ffffffffc020018a:	3e258593          	addi	a1,a1,994 # ffffffffc0206568 <end>
ffffffffc020018e:	00002517          	auipc	a0,0x2
ffffffffc0200192:	9ea50513          	addi	a0,a0,-1558 # ffffffffc0201b78 <etext+0xa2>
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
ffffffffc02001c0:	9dc50513          	addi	a0,a0,-1572 # ffffffffc0201b98 <etext+0xc2>
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
ffffffffc02001ce:	9fe60613          	addi	a2,a2,-1538 # ffffffffc0201bc8 <etext+0xf2>
ffffffffc02001d2:	04e00593          	li	a1,78
ffffffffc02001d6:	00002517          	auipc	a0,0x2
ffffffffc02001da:	a0a50513          	addi	a0,a0,-1526 # ffffffffc0201be0 <etext+0x10a>
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
ffffffffc02001ea:	a1260613          	addi	a2,a2,-1518 # ffffffffc0201bf8 <etext+0x122>
ffffffffc02001ee:	00002597          	auipc	a1,0x2
ffffffffc02001f2:	a2a58593          	addi	a1,a1,-1494 # ffffffffc0201c18 <etext+0x142>
ffffffffc02001f6:	00002517          	auipc	a0,0x2
ffffffffc02001fa:	a2a50513          	addi	a0,a0,-1494 # ffffffffc0201c20 <etext+0x14a>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02001fe:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200200:	eb3ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200204:	00002617          	auipc	a2,0x2
ffffffffc0200208:	a2c60613          	addi	a2,a2,-1492 # ffffffffc0201c30 <etext+0x15a>
ffffffffc020020c:	00002597          	auipc	a1,0x2
ffffffffc0200210:	a4c58593          	addi	a1,a1,-1460 # ffffffffc0201c58 <etext+0x182>
ffffffffc0200214:	00002517          	auipc	a0,0x2
ffffffffc0200218:	a0c50513          	addi	a0,a0,-1524 # ffffffffc0201c20 <etext+0x14a>
ffffffffc020021c:	e97ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200220:	00002617          	auipc	a2,0x2
ffffffffc0200224:	a4860613          	addi	a2,a2,-1464 # ffffffffc0201c68 <etext+0x192>
ffffffffc0200228:	00002597          	auipc	a1,0x2
ffffffffc020022c:	a6058593          	addi	a1,a1,-1440 # ffffffffc0201c88 <etext+0x1b2>
ffffffffc0200230:	00002517          	auipc	a0,0x2
ffffffffc0200234:	9f050513          	addi	a0,a0,-1552 # ffffffffc0201c20 <etext+0x14a>
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
ffffffffc020026e:	a2e50513          	addi	a0,a0,-1490 # ffffffffc0201c98 <etext+0x1c2>
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
ffffffffc0200290:	a3450513          	addi	a0,a0,-1484 # ffffffffc0201cc0 <etext+0x1ea>
ffffffffc0200294:	e1fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    if (tf != NULL) {
ffffffffc0200298:	000b8563          	beqz	s7,ffffffffc02002a2 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020029c:	855e                	mv	a0,s7
ffffffffc020029e:	3a4000ef          	jal	ra,ffffffffc0200642 <print_trapframe>
ffffffffc02002a2:	00002c17          	auipc	s8,0x2
ffffffffc02002a6:	a8ec0c13          	addi	s8,s8,-1394 # ffffffffc0201d30 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002aa:	00002917          	auipc	s2,0x2
ffffffffc02002ae:	a3e90913          	addi	s2,s2,-1474 # ffffffffc0201ce8 <etext+0x212>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002b2:	00002497          	auipc	s1,0x2
ffffffffc02002b6:	a3e48493          	addi	s1,s1,-1474 # ffffffffc0201cf0 <etext+0x21a>
        if (argc == MAXARGS - 1) {
ffffffffc02002ba:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002bc:	00002b17          	auipc	s6,0x2
ffffffffc02002c0:	a3cb0b13          	addi	s6,s6,-1476 # ffffffffc0201cf8 <etext+0x222>
        argv[argc ++] = buf;
ffffffffc02002c4:	00002a17          	auipc	s4,0x2
ffffffffc02002c8:	954a0a13          	addi	s4,s4,-1708 # ffffffffc0201c18 <etext+0x142>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002cc:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002ce:	854a                	mv	a0,s2
ffffffffc02002d0:	686010ef          	jal	ra,ffffffffc0201956 <readline>
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
ffffffffc02002ea:	a4ad0d13          	addi	s10,s10,-1462 # ffffffffc0201d30 <commands>
        argv[argc ++] = buf;
ffffffffc02002ee:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002f0:	4401                	li	s0,0
ffffffffc02002f2:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002f4:	79c010ef          	jal	ra,ffffffffc0201a90 <strcmp>
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
ffffffffc0200308:	788010ef          	jal	ra,ffffffffc0201a90 <strcmp>
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
ffffffffc0200346:	768010ef          	jal	ra,ffffffffc0201aae <strchr>
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
ffffffffc0200384:	72a010ef          	jal	ra,ffffffffc0201aae <strchr>
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
ffffffffc02003a2:	97a50513          	addi	a0,a0,-1670 # ffffffffc0201d18 <etext+0x242>
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
ffffffffc02003de:	99e50513          	addi	a0,a0,-1634 # ffffffffc0201d78 <commands+0x48>
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
ffffffffc02003f4:	2c050513          	addi	a0,a0,704 # ffffffffc02026b0 <commands+0x980>
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
ffffffffc0200420:	604010ef          	jal	ra,ffffffffc0201a24 <sbi_set_timer>
}
ffffffffc0200424:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc0200426:	00006797          	auipc	a5,0x6
ffffffffc020042a:	0e07bd23          	sd	zero,250(a5) # ffffffffc0206520 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020042e:	00002517          	auipc	a0,0x2
ffffffffc0200432:	96a50513          	addi	a0,a0,-1686 # ffffffffc0201d98 <commands+0x68>
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
ffffffffc0200446:	5de0106f          	j	ffffffffc0201a24 <sbi_set_timer>

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
ffffffffc0200450:	5ba0106f          	j	ffffffffc0201a0a <sbi_console_putchar>

ffffffffc0200454 <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc0200454:	5ea0106f          	j	ffffffffc0201a3e <sbi_console_getchar>

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
ffffffffc0200482:	93a50513          	addi	a0,a0,-1734 # ffffffffc0201db8 <commands+0x88>
{
ffffffffc0200486:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200488:	c2bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020048c:	640c                	ld	a1,8(s0)
ffffffffc020048e:	00002517          	auipc	a0,0x2
ffffffffc0200492:	94250513          	addi	a0,a0,-1726 # ffffffffc0201dd0 <commands+0xa0>
ffffffffc0200496:	c1dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc020049a:	680c                	ld	a1,16(s0)
ffffffffc020049c:	00002517          	auipc	a0,0x2
ffffffffc02004a0:	94c50513          	addi	a0,a0,-1716 # ffffffffc0201de8 <commands+0xb8>
ffffffffc02004a4:	c0fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02004a8:	6c0c                	ld	a1,24(s0)
ffffffffc02004aa:	00002517          	auipc	a0,0x2
ffffffffc02004ae:	95650513          	addi	a0,a0,-1706 # ffffffffc0201e00 <commands+0xd0>
ffffffffc02004b2:	c01ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02004b6:	700c                	ld	a1,32(s0)
ffffffffc02004b8:	00002517          	auipc	a0,0x2
ffffffffc02004bc:	96050513          	addi	a0,a0,-1696 # ffffffffc0201e18 <commands+0xe8>
ffffffffc02004c0:	bf3ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02004c4:	740c                	ld	a1,40(s0)
ffffffffc02004c6:	00002517          	auipc	a0,0x2
ffffffffc02004ca:	96a50513          	addi	a0,a0,-1686 # ffffffffc0201e30 <commands+0x100>
ffffffffc02004ce:	be5ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02004d2:	780c                	ld	a1,48(s0)
ffffffffc02004d4:	00002517          	auipc	a0,0x2
ffffffffc02004d8:	97450513          	addi	a0,a0,-1676 # ffffffffc0201e48 <commands+0x118>
ffffffffc02004dc:	bd7ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02004e0:	7c0c                	ld	a1,56(s0)
ffffffffc02004e2:	00002517          	auipc	a0,0x2
ffffffffc02004e6:	97e50513          	addi	a0,a0,-1666 # ffffffffc0201e60 <commands+0x130>
ffffffffc02004ea:	bc9ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02004ee:	602c                	ld	a1,64(s0)
ffffffffc02004f0:	00002517          	auipc	a0,0x2
ffffffffc02004f4:	98850513          	addi	a0,a0,-1656 # ffffffffc0201e78 <commands+0x148>
ffffffffc02004f8:	bbbff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02004fc:	642c                	ld	a1,72(s0)
ffffffffc02004fe:	00002517          	auipc	a0,0x2
ffffffffc0200502:	99250513          	addi	a0,a0,-1646 # ffffffffc0201e90 <commands+0x160>
ffffffffc0200506:	badff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc020050a:	682c                	ld	a1,80(s0)
ffffffffc020050c:	00002517          	auipc	a0,0x2
ffffffffc0200510:	99c50513          	addi	a0,a0,-1636 # ffffffffc0201ea8 <commands+0x178>
ffffffffc0200514:	b9fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200518:	6c2c                	ld	a1,88(s0)
ffffffffc020051a:	00002517          	auipc	a0,0x2
ffffffffc020051e:	9a650513          	addi	a0,a0,-1626 # ffffffffc0201ec0 <commands+0x190>
ffffffffc0200522:	b91ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200526:	702c                	ld	a1,96(s0)
ffffffffc0200528:	00002517          	auipc	a0,0x2
ffffffffc020052c:	9b050513          	addi	a0,a0,-1616 # ffffffffc0201ed8 <commands+0x1a8>
ffffffffc0200530:	b83ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200534:	742c                	ld	a1,104(s0)
ffffffffc0200536:	00002517          	auipc	a0,0x2
ffffffffc020053a:	9ba50513          	addi	a0,a0,-1606 # ffffffffc0201ef0 <commands+0x1c0>
ffffffffc020053e:	b75ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200542:	782c                	ld	a1,112(s0)
ffffffffc0200544:	00002517          	auipc	a0,0x2
ffffffffc0200548:	9c450513          	addi	a0,a0,-1596 # ffffffffc0201f08 <commands+0x1d8>
ffffffffc020054c:	b67ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200550:	7c2c                	ld	a1,120(s0)
ffffffffc0200552:	00002517          	auipc	a0,0x2
ffffffffc0200556:	9ce50513          	addi	a0,a0,-1586 # ffffffffc0201f20 <commands+0x1f0>
ffffffffc020055a:	b59ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc020055e:	604c                	ld	a1,128(s0)
ffffffffc0200560:	00002517          	auipc	a0,0x2
ffffffffc0200564:	9d850513          	addi	a0,a0,-1576 # ffffffffc0201f38 <commands+0x208>
ffffffffc0200568:	b4bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc020056c:	644c                	ld	a1,136(s0)
ffffffffc020056e:	00002517          	auipc	a0,0x2
ffffffffc0200572:	9e250513          	addi	a0,a0,-1566 # ffffffffc0201f50 <commands+0x220>
ffffffffc0200576:	b3dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc020057a:	684c                	ld	a1,144(s0)
ffffffffc020057c:	00002517          	auipc	a0,0x2
ffffffffc0200580:	9ec50513          	addi	a0,a0,-1556 # ffffffffc0201f68 <commands+0x238>
ffffffffc0200584:	b2fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200588:	6c4c                	ld	a1,152(s0)
ffffffffc020058a:	00002517          	auipc	a0,0x2
ffffffffc020058e:	9f650513          	addi	a0,a0,-1546 # ffffffffc0201f80 <commands+0x250>
ffffffffc0200592:	b21ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200596:	704c                	ld	a1,160(s0)
ffffffffc0200598:	00002517          	auipc	a0,0x2
ffffffffc020059c:	a0050513          	addi	a0,a0,-1536 # ffffffffc0201f98 <commands+0x268>
ffffffffc02005a0:	b13ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02005a4:	744c                	ld	a1,168(s0)
ffffffffc02005a6:	00002517          	auipc	a0,0x2
ffffffffc02005aa:	a0a50513          	addi	a0,a0,-1526 # ffffffffc0201fb0 <commands+0x280>
ffffffffc02005ae:	b05ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02005b2:	784c                	ld	a1,176(s0)
ffffffffc02005b4:	00002517          	auipc	a0,0x2
ffffffffc02005b8:	a1450513          	addi	a0,a0,-1516 # ffffffffc0201fc8 <commands+0x298>
ffffffffc02005bc:	af7ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02005c0:	7c4c                	ld	a1,184(s0)
ffffffffc02005c2:	00002517          	auipc	a0,0x2
ffffffffc02005c6:	a1e50513          	addi	a0,a0,-1506 # ffffffffc0201fe0 <commands+0x2b0>
ffffffffc02005ca:	ae9ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02005ce:	606c                	ld	a1,192(s0)
ffffffffc02005d0:	00002517          	auipc	a0,0x2
ffffffffc02005d4:	a2850513          	addi	a0,a0,-1496 # ffffffffc0201ff8 <commands+0x2c8>
ffffffffc02005d8:	adbff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02005dc:	646c                	ld	a1,200(s0)
ffffffffc02005de:	00002517          	auipc	a0,0x2
ffffffffc02005e2:	a3250513          	addi	a0,a0,-1486 # ffffffffc0202010 <commands+0x2e0>
ffffffffc02005e6:	acdff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02005ea:	686c                	ld	a1,208(s0)
ffffffffc02005ec:	00002517          	auipc	a0,0x2
ffffffffc02005f0:	a3c50513          	addi	a0,a0,-1476 # ffffffffc0202028 <commands+0x2f8>
ffffffffc02005f4:	abfff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02005f8:	6c6c                	ld	a1,216(s0)
ffffffffc02005fa:	00002517          	auipc	a0,0x2
ffffffffc02005fe:	a4650513          	addi	a0,a0,-1466 # ffffffffc0202040 <commands+0x310>
ffffffffc0200602:	ab1ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200606:	706c                	ld	a1,224(s0)
ffffffffc0200608:	00002517          	auipc	a0,0x2
ffffffffc020060c:	a5050513          	addi	a0,a0,-1456 # ffffffffc0202058 <commands+0x328>
ffffffffc0200610:	aa3ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200614:	746c                	ld	a1,232(s0)
ffffffffc0200616:	00002517          	auipc	a0,0x2
ffffffffc020061a:	a5a50513          	addi	a0,a0,-1446 # ffffffffc0202070 <commands+0x340>
ffffffffc020061e:	a95ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200622:	786c                	ld	a1,240(s0)
ffffffffc0200624:	00002517          	auipc	a0,0x2
ffffffffc0200628:	a6450513          	addi	a0,a0,-1436 # ffffffffc0202088 <commands+0x358>
ffffffffc020062c:	a87ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200630:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200632:	6402                	ld	s0,0(sp)
ffffffffc0200634:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200636:	00002517          	auipc	a0,0x2
ffffffffc020063a:	a6a50513          	addi	a0,a0,-1430 # ffffffffc02020a0 <commands+0x370>
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
ffffffffc020064e:	a6e50513          	addi	a0,a0,-1426 # ffffffffc02020b8 <commands+0x388>
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
ffffffffc0200666:	a6e50513          	addi	a0,a0,-1426 # ffffffffc02020d0 <commands+0x3a0>
ffffffffc020066a:	a49ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc020066e:	10843583          	ld	a1,264(s0)
ffffffffc0200672:	00002517          	auipc	a0,0x2
ffffffffc0200676:	a7650513          	addi	a0,a0,-1418 # ffffffffc02020e8 <commands+0x3b8>
ffffffffc020067a:	a39ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc020067e:	11043583          	ld	a1,272(s0)
ffffffffc0200682:	00002517          	auipc	a0,0x2
ffffffffc0200686:	a7e50513          	addi	a0,a0,-1410 # ffffffffc0202100 <commands+0x3d0>
ffffffffc020068a:	a29ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020068e:	11843583          	ld	a1,280(s0)
}
ffffffffc0200692:	6402                	ld	s0,0(sp)
ffffffffc0200694:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200696:	00002517          	auipc	a0,0x2
ffffffffc020069a:	a8250513          	addi	a0,a0,-1406 # ffffffffc0202118 <commands+0x3e8>
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
ffffffffc02006b4:	b4870713          	addi	a4,a4,-1208 # ffffffffc02021f8 <commands+0x4c8>
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
ffffffffc02006c6:	ace50513          	addi	a0,a0,-1330 # ffffffffc0202190 <commands+0x460>
ffffffffc02006ca:	b2e5                	j	ffffffffc02000b2 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc02006cc:	00002517          	auipc	a0,0x2
ffffffffc02006d0:	aa450513          	addi	a0,a0,-1372 # ffffffffc0202170 <commands+0x440>
ffffffffc02006d4:	baf9                	j	ffffffffc02000b2 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc02006d6:	00002517          	auipc	a0,0x2
ffffffffc02006da:	a5a50513          	addi	a0,a0,-1446 # ffffffffc0202130 <commands+0x400>
ffffffffc02006de:	bad1                	j	ffffffffc02000b2 <cprintf>
        break;
    case IRQ_U_TIMER:
        cprintf("User Timer interrupt\n");
ffffffffc02006e0:	00002517          	auipc	a0,0x2
ffffffffc02006e4:	ad050513          	addi	a0,a0,-1328 # ffffffffc02021b0 <commands+0x480>
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
ffffffffc0200718:	ac450513          	addi	a0,a0,-1340 # ffffffffc02021d8 <commands+0x4a8>
ffffffffc020071c:	ba59                	j	ffffffffc02000b2 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc020071e:	00002517          	auipc	a0,0x2
ffffffffc0200722:	a3250513          	addi	a0,a0,-1486 # ffffffffc0202150 <commands+0x420>
ffffffffc0200726:	b271                	j	ffffffffc02000b2 <cprintf>
        print_trapframe(tf);
ffffffffc0200728:	bf29                	j	ffffffffc0200642 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc020072a:	06400593          	li	a1,100
ffffffffc020072e:	00002517          	auipc	a0,0x2
ffffffffc0200732:	a9a50513          	addi	a0,a0,-1382 # ffffffffc02021c8 <commands+0x498>
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
ffffffffc020075a:	300010ef          	jal	ra,ffffffffc0201a5a <sbi_shutdown>
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
ffffffffc02008fa:	97268693          	addi	a3,a3,-1678 # ffffffffc0202268 <commands+0x538>
ffffffffc02008fe:	00002617          	auipc	a2,0x2
ffffffffc0200902:	93260613          	addi	a2,a2,-1742 # ffffffffc0202230 <commands+0x500>
ffffffffc0200906:	09b00593          	li	a1,155
ffffffffc020090a:	00002517          	auipc	a0,0x2
ffffffffc020090e:	93e50513          	addi	a0,a0,-1730 # ffffffffc0202248 <commands+0x518>
ffffffffc0200912:	a9bff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(n > 0);
ffffffffc0200916:	00002697          	auipc	a3,0x2
ffffffffc020091a:	91268693          	addi	a3,a3,-1774 # ffffffffc0202228 <commands+0x4f8>
ffffffffc020091e:	00002617          	auipc	a2,0x2
ffffffffc0200922:	91260613          	addi	a2,a2,-1774 # ffffffffc0202230 <commands+0x500>
ffffffffc0200926:	09200593          	li	a1,146
ffffffffc020092a:	00002517          	auipc	a0,0x2
ffffffffc020092e:	91e50513          	addi	a0,a0,-1762 # ffffffffc0202248 <commands+0x518>
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
ffffffffc0200974:	4505b583          	ld	a1,1104(a1) # ffffffffc0202dc0 <error_string+0x38>
ffffffffc0200978:	878d                	srai	a5,a5,0x3
ffffffffc020097a:	02b787b3          	mul	a5,a5,a1
    cprintf("buddy system will release from Page NO.%d total %d Pages\n", page2ppn(base), pnum);
ffffffffc020097e:	00002597          	auipc	a1,0x2
ffffffffc0200982:	44a5b583          	ld	a1,1098(a1) # ffffffffc0202dc8 <nbase>
ffffffffc0200986:	00002517          	auipc	a0,0x2
ffffffffc020098a:	90a50513          	addi	a0,a0,-1782 # ffffffffc0202290 <commands+0x560>
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
ffffffffc0200aac:	78068693          	addi	a3,a3,1920 # ffffffffc0202228 <commands+0x4f8>
ffffffffc0200ab0:	00001617          	auipc	a2,0x1
ffffffffc0200ab4:	78060613          	addi	a2,a2,1920 # ffffffffc0202230 <commands+0x500>
ffffffffc0200ab8:	0ed00593          	li	a1,237
ffffffffc0200abc:	00001517          	auipc	a0,0x1
ffffffffc0200ac0:	78c50513          	addi	a0,a0,1932 # ffffffffc0202248 <commands+0x518>
ffffffffc0200ac4:	8e9ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(ROUNDUP2(n) == pnum);
ffffffffc0200ac8:	00001697          	auipc	a3,0x1
ffffffffc0200acc:	7b068693          	addi	a3,a3,1968 # ffffffffc0202278 <commands+0x548>
ffffffffc0200ad0:	00001617          	auipc	a2,0x1
ffffffffc0200ad4:	76060613          	addi	a2,a2,1888 # ffffffffc0202230 <commands+0x500>
ffffffffc0200ad8:	0ef00593          	li	a1,239
ffffffffc0200adc:	00001517          	auipc	a0,0x1
ffffffffc0200ae0:	76c50513          	addi	a0,a0,1900 # ffffffffc0202248 <commands+0x518>
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
ffffffffc0200b10:	00002517          	auipc	a0,0x2
ffffffffc0200b14:	80850513          	addi	a0,a0,-2040 # ffffffffc0202318 <commands+0x5e8>
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
ffffffffc0200b2c:	830b0b13          	addi	s6,s6,-2000 # ffffffffc0202358 <commands+0x628>
                cprintf("%d page ", 1 << (p->property));
ffffffffc0200b30:	4a85                	li	s5,1
ffffffffc0200b32:	00002a17          	auipc	s4,0x2
ffffffffc0200b36:	836a0a13          	addi	s4,s4,-1994 # ffffffffc0202368 <commands+0x638>
                cprintf("【address: %p】\n", p);
ffffffffc0200b3a:	00002997          	auipc	s3,0x2
ffffffffc0200b3e:	83e98993          	addi	s3,s3,-1986 # ffffffffc0202378 <commands+0x648>
            if (i != right)
ffffffffc0200b42:	4cb9                	li	s9,14
                cprintf("\n");
ffffffffc0200b44:	00002d17          	auipc	s10,0x2
ffffffffc0200b48:	b6cd0d13          	addi	s10,s10,-1172 # ffffffffc02026b0 <commands+0x980>
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
ffffffffc0200bb8:	7ec50513          	addi	a0,a0,2028 # ffffffffc02023a0 <commands+0x670>
}
ffffffffc0200bbc:	6125                	addi	sp,sp,96
    cprintf("======================the end======================\n\n\n");
ffffffffc0200bbe:	cf4ff06f          	j	ffffffffc02000b2 <cprintf>
        cprintf("no free blocks\n");
ffffffffc0200bc2:	00001517          	auipc	a0,0x1
ffffffffc0200bc6:	7ce50513          	addi	a0,a0,1998 # ffffffffc0202390 <commands+0x660>
ffffffffc0200bca:	ce8ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200bce:	b7f9                	j	ffffffffc0200b9c <show_buddy_array.constprop.0+0xb4>
    assert(left >= 0 && left <= max_order && right >= 0 && right <= max_order);
ffffffffc0200bd0:	00001697          	auipc	a3,0x1
ffffffffc0200bd4:	70068693          	addi	a3,a3,1792 # ffffffffc02022d0 <commands+0x5a0>
ffffffffc0200bd8:	00001617          	auipc	a2,0x1
ffffffffc0200bdc:	65860613          	addi	a2,a2,1624 # ffffffffc0202230 <commands+0x500>
ffffffffc0200be0:	06300593          	li	a1,99
ffffffffc0200be4:	00001517          	auipc	a0,0x1
ffffffffc0200be8:	66450513          	addi	a0,a0,1636 # ffffffffc0202248 <commands+0x518>
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
ffffffffc0200c04:	7d850513          	addi	a0,a0,2008 # ffffffffc02023d8 <commands+0x6a8>
{
ffffffffc0200c08:	f406                	sd	ra,40(sp)
ffffffffc0200c0a:	ec26                	sd	s1,24(sp)
ffffffffc0200c0c:	e84a                	sd	s2,16(sp)
ffffffffc0200c0e:	e44e                	sd	s3,8(sp)
    cprintf("Total number of free blocks：%d\n", nr_free);
ffffffffc0200c10:	ca2ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("initial condition\n");
ffffffffc0200c14:	00001517          	auipc	a0,0x1
ffffffffc0200c18:	7ec50513          	addi	a0,a0,2028 # ffffffffc0202400 <commands+0x6d0>
ffffffffc0200c1c:	c96ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200c20:	ec9ff0ef          	jal	ra,ffffffffc0200ae8 <show_buddy_array.constprop.0>
    cprintf("p0 requests 5 Pages\n");
ffffffffc0200c24:	00001517          	auipc	a0,0x1
ffffffffc0200c28:	7f450513          	addi	a0,a0,2036 # ffffffffc0202418 <commands+0x6e8>
ffffffffc0200c2c:	c86ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    p0 = alloc_pages(5);
ffffffffc0200c30:	4515                	li	a0,5
ffffffffc0200c32:	550000ef          	jal	ra,ffffffffc0201182 <alloc_pages>
ffffffffc0200c36:	892a                	mv	s2,a0
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200c38:	eb1ff0ef          	jal	ra,ffffffffc0200ae8 <show_buddy_array.constprop.0>
    cprintf("p1 requests 5 Pages\n");
ffffffffc0200c3c:	00001517          	auipc	a0,0x1
ffffffffc0200c40:	7f450513          	addi	a0,a0,2036 # ffffffffc0202430 <commands+0x700>
ffffffffc0200c44:	c6eff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    p1 = alloc_pages(5);
ffffffffc0200c48:	4515                	li	a0,5
ffffffffc0200c4a:	538000ef          	jal	ra,ffffffffc0201182 <alloc_pages>
ffffffffc0200c4e:	84aa                	mv	s1,a0
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200c50:	e99ff0ef          	jal	ra,ffffffffc0200ae8 <show_buddy_array.constprop.0>
    cprintf("p2 requests 5 Pages\n");
ffffffffc0200c54:	00001517          	auipc	a0,0x1
ffffffffc0200c58:	7f450513          	addi	a0,a0,2036 # ffffffffc0202448 <commands+0x718>
ffffffffc0200c5c:	c56ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    p2 = alloc_pages(5);
ffffffffc0200c60:	4515                	li	a0,5
ffffffffc0200c62:	520000ef          	jal	ra,ffffffffc0201182 <alloc_pages>
ffffffffc0200c66:	89aa                	mv	s3,a0
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200c68:	e81ff0ef          	jal	ra,ffffffffc0200ae8 <show_buddy_array.constprop.0>
    cprintf("p0 Virtual Address:0x%016lx.\n", p0);
ffffffffc0200c6c:	85ca                	mv	a1,s2
ffffffffc0200c6e:	00001517          	auipc	a0,0x1
ffffffffc0200c72:	7f250513          	addi	a0,a0,2034 # ffffffffc0202460 <commands+0x730>
ffffffffc0200c76:	c3cff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("p1 Virtual Address:0x%016lx.\n", p1);
ffffffffc0200c7a:	85a6                	mv	a1,s1
ffffffffc0200c7c:	00002517          	auipc	a0,0x2
ffffffffc0200c80:	80450513          	addi	a0,a0,-2044 # ffffffffc0202480 <commands+0x750>
ffffffffc0200c84:	c2eff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("p2 Virtual Address:0x%016lx.\n", p2);
ffffffffc0200c88:	85ce                	mv	a1,s3
ffffffffc0200c8a:	00002517          	auipc	a0,0x2
ffffffffc0200c8e:	81650513          	addi	a0,a0,-2026 # ffffffffc02024a0 <commands+0x770>
ffffffffc0200c92:	c20ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200c96:	1e990a63          	beq	s2,s1,ffffffffc0200e8a <buddy_system_check+0x29a>
ffffffffc0200c9a:	1f390863          	beq	s2,s3,ffffffffc0200e8a <buddy_system_check+0x29a>
ffffffffc0200c9e:	1f348663          	beq	s1,s3,ffffffffc0200e8a <buddy_system_check+0x29a>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200ca2:	00092783          	lw	a5,0(s2)
ffffffffc0200ca6:	22079263          	bnez	a5,ffffffffc0200eca <buddy_system_check+0x2da>
ffffffffc0200caa:	409c                	lw	a5,0(s1)
ffffffffc0200cac:	20079f63          	bnez	a5,ffffffffc0200eca <buddy_system_check+0x2da>
ffffffffc0200cb0:	0009a783          	lw	a5,0(s3)
ffffffffc0200cb4:	20079b63          	bnez	a5,ffffffffc0200eca <buddy_system_check+0x2da>
ffffffffc0200cb8:	00006797          	auipc	a5,0x6
ffffffffc0200cbc:	8807b783          	ld	a5,-1920(a5) # ffffffffc0206538 <pages>
ffffffffc0200cc0:	40f90733          	sub	a4,s2,a5
ffffffffc0200cc4:	870d                	srai	a4,a4,0x3
ffffffffc0200cc6:	00002597          	auipc	a1,0x2
ffffffffc0200cca:	0fa5b583          	ld	a1,250(a1) # ffffffffc0202dc0 <error_string+0x38>
ffffffffc0200cce:	02b70733          	mul	a4,a4,a1
ffffffffc0200cd2:	00002617          	auipc	a2,0x2
ffffffffc0200cd6:	0f663603          	ld	a2,246(a2) # ffffffffc0202dc8 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200cda:	00006697          	auipc	a3,0x6
ffffffffc0200cde:	8566b683          	ld	a3,-1962(a3) # ffffffffc0206530 <npage>
ffffffffc0200ce2:	06b2                	slli	a3,a3,0xc
ffffffffc0200ce4:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200ce6:	0732                	slli	a4,a4,0xc
ffffffffc0200ce8:	2cd77163          	bgeu	a4,a3,ffffffffc0200faa <buddy_system_check+0x3ba>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; } 
ffffffffc0200cec:	40f48733          	sub	a4,s1,a5
ffffffffc0200cf0:	870d                	srai	a4,a4,0x3
ffffffffc0200cf2:	02b70733          	mul	a4,a4,a1
ffffffffc0200cf6:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200cf8:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200cfa:	1ed77863          	bgeu	a4,a3,ffffffffc0200eea <buddy_system_check+0x2fa>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; } 
ffffffffc0200cfe:	40f987b3          	sub	a5,s3,a5
ffffffffc0200d02:	878d                	srai	a5,a5,0x3
ffffffffc0200d04:	02b787b3          	mul	a5,a5,a1
ffffffffc0200d08:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200d0a:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200d0c:	1ed7ff63          	bgeu	a5,a3,ffffffffc0200f0a <buddy_system_check+0x31a>
    assert(alloc_page() == NULL);
ffffffffc0200d10:	4505                	li	a0,1
    nr_free = 0;
ffffffffc0200d12:	00005797          	auipc	a5,0x5
ffffffffc0200d16:	3e07af23          	sw	zero,1022(a5) # ffffffffc0206110 <buddy_s+0xf8>
    assert(alloc_page() == NULL);
ffffffffc0200d1a:	468000ef          	jal	ra,ffffffffc0201182 <alloc_pages>
ffffffffc0200d1e:	20051663          	bnez	a0,ffffffffc0200f2a <buddy_system_check+0x33a>
    cprintf("releasing p0......\n");
ffffffffc0200d22:	00002517          	auipc	a0,0x2
ffffffffc0200d26:	87e50513          	addi	a0,a0,-1922 # ffffffffc02025a0 <commands+0x870>
ffffffffc0200d2a:	b88ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    free_pages(p0, 5);
ffffffffc0200d2e:	4595                	li	a1,5
ffffffffc0200d30:	854a                	mv	a0,s2
ffffffffc0200d32:	48e000ef          	jal	ra,ffffffffc02011c0 <free_pages>
    cprintf("after releasing p0，counts of total free blocks：%d\n", nr_free); // 变成了8
ffffffffc0200d36:	0f842583          	lw	a1,248(s0)
ffffffffc0200d3a:	00002517          	auipc	a0,0x2
ffffffffc0200d3e:	87e50513          	addi	a0,a0,-1922 # ffffffffc02025b8 <commands+0x888>
ffffffffc0200d42:	b70ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200d46:	da3ff0ef          	jal	ra,ffffffffc0200ae8 <show_buddy_array.constprop.0>
    cprintf("releasing p1......\n");
ffffffffc0200d4a:	00002517          	auipc	a0,0x2
ffffffffc0200d4e:	8a650513          	addi	a0,a0,-1882 # ffffffffc02025f0 <commands+0x8c0>
ffffffffc0200d52:	b60ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    free_pages(p1, 5);
ffffffffc0200d56:	4595                	li	a1,5
ffffffffc0200d58:	8526                	mv	a0,s1
ffffffffc0200d5a:	466000ef          	jal	ra,ffffffffc02011c0 <free_pages>
    cprintf("after releasing p1，counts of total free blocks：%d\n", nr_free); // 变成了16
ffffffffc0200d5e:	0f842583          	lw	a1,248(s0)
ffffffffc0200d62:	00002517          	auipc	a0,0x2
ffffffffc0200d66:	8a650513          	addi	a0,a0,-1882 # ffffffffc0202608 <commands+0x8d8>
ffffffffc0200d6a:	b48ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200d6e:	d7bff0ef          	jal	ra,ffffffffc0200ae8 <show_buddy_array.constprop.0>
    cprintf("releasing p2......\n");
ffffffffc0200d72:	00002517          	auipc	a0,0x2
ffffffffc0200d76:	8ce50513          	addi	a0,a0,-1842 # ffffffffc0202640 <commands+0x910>
ffffffffc0200d7a:	b38ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    free_pages(p2, 5);
ffffffffc0200d7e:	4595                	li	a1,5
ffffffffc0200d80:	854e                	mv	a0,s3
ffffffffc0200d82:	43e000ef          	jal	ra,ffffffffc02011c0 <free_pages>
    cprintf("after releasing p2，counts of total free blocks：%d\n", nr_free); // 变成了24
ffffffffc0200d86:	0f842583          	lw	a1,248(s0)
ffffffffc0200d8a:	00002517          	auipc	a0,0x2
ffffffffc0200d8e:	8ce50513          	addi	a0,a0,-1842 # ffffffffc0202658 <commands+0x928>
ffffffffc0200d92:	b20ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200d96:	d53ff0ef          	jal	ra,ffffffffc0200ae8 <show_buddy_array.constprop.0>
    nr_free = 16384;
ffffffffc0200d9a:	6791                	lui	a5,0x4
    struct Page *p3 = alloc_pages(16384);
ffffffffc0200d9c:	6511                	lui	a0,0x4
    nr_free = 16384;
ffffffffc0200d9e:	0ef42c23          	sw	a5,248(s0)
    struct Page *p3 = alloc_pages(16384);
ffffffffc0200da2:	3e0000ef          	jal	ra,ffffffffc0201182 <alloc_pages>
ffffffffc0200da6:	842a                	mv	s0,a0
    cprintf("after allocating p3(16384 Pages)\n");
ffffffffc0200da8:	00002517          	auipc	a0,0x2
ffffffffc0200dac:	8e850513          	addi	a0,a0,-1816 # ffffffffc0202690 <commands+0x960>
ffffffffc0200db0:	b02ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200db4:	d35ff0ef          	jal	ra,ffffffffc0200ae8 <show_buddy_array.constprop.0>
    free_pages(p3, 16384);
ffffffffc0200db8:	6591                	lui	a1,0x4
ffffffffc0200dba:	8522                	mv	a0,s0
ffffffffc0200dbc:	404000ef          	jal	ra,ffffffffc02011c0 <free_pages>
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200dc0:	d29ff0ef          	jal	ra,ffffffffc0200ae8 <show_buddy_array.constprop.0>
    basic_check();

    // 一些复杂的操作
    cprintf("==========complex testing beginning==========\n");
ffffffffc0200dc4:	00002517          	auipc	a0,0x2
ffffffffc0200dc8:	8f450513          	addi	a0,a0,-1804 # ffffffffc02026b8 <commands+0x988>
ffffffffc0200dcc:	ae6ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("p0 requests 5 Pages\n");
ffffffffc0200dd0:	00001517          	auipc	a0,0x1
ffffffffc0200dd4:	64850513          	addi	a0,a0,1608 # ffffffffc0202418 <commands+0x6e8>
ffffffffc0200dd8:	adaff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200ddc:	4515                	li	a0,5
ffffffffc0200dde:	3a4000ef          	jal	ra,ffffffffc0201182 <alloc_pages>
ffffffffc0200de2:	842a                	mv	s0,a0
    assert(p0 != NULL);
ffffffffc0200de4:	1a050363          	beqz	a0,ffffffffc0200f8a <buddy_system_check+0x39a>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200de8:	651c                	ld	a5,8(a0)
ffffffffc0200dea:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200dec:	8b85                	andi	a5,a5,1
ffffffffc0200dee:	16079e63          	bnez	a5,ffffffffc0200f6a <buddy_system_check+0x37a>
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200df2:	cf7ff0ef          	jal	ra,ffffffffc0200ae8 <show_buddy_array.constprop.0>

    cprintf("p1 requests 15 Pages\n");
ffffffffc0200df6:	00002517          	auipc	a0,0x2
ffffffffc0200dfa:	91a50513          	addi	a0,a0,-1766 # ffffffffc0202710 <commands+0x9e0>
ffffffffc0200dfe:	ab4ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    p1 = alloc_pages(15);
ffffffffc0200e02:	453d                	li	a0,15
ffffffffc0200e04:	37e000ef          	jal	ra,ffffffffc0201182 <alloc_pages>
ffffffffc0200e08:	892a                	mv	s2,a0
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200e0a:	cdfff0ef          	jal	ra,ffffffffc0200ae8 <show_buddy_array.constprop.0>

    cprintf("p2 requests 21 Pages\n");
ffffffffc0200e0e:	00002517          	auipc	a0,0x2
ffffffffc0200e12:	91a50513          	addi	a0,a0,-1766 # ffffffffc0202728 <commands+0x9f8>
ffffffffc0200e16:	a9cff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    p2 = alloc_pages(21);
ffffffffc0200e1a:	4555                	li	a0,21
ffffffffc0200e1c:	366000ef          	jal	ra,ffffffffc0201182 <alloc_pages>
ffffffffc0200e20:	84aa                	mv	s1,a0
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200e22:	cc7ff0ef          	jal	ra,ffffffffc0200ae8 <show_buddy_array.constprop.0>

    cprintf("p0 Virtual Address:0x%016lx.\n", p0);
ffffffffc0200e26:	85a2                	mv	a1,s0
ffffffffc0200e28:	00001517          	auipc	a0,0x1
ffffffffc0200e2c:	63850513          	addi	a0,a0,1592 # ffffffffc0202460 <commands+0x730>
ffffffffc0200e30:	a82ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("p1 Virtual Address:0x%016lx.\n", p1);
ffffffffc0200e34:	85ca                	mv	a1,s2
ffffffffc0200e36:	00001517          	auipc	a0,0x1
ffffffffc0200e3a:	64a50513          	addi	a0,a0,1610 # ffffffffc0202480 <commands+0x750>
ffffffffc0200e3e:	a74ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("p2 Virtual Address:0x%016lx.\n", p2);
ffffffffc0200e42:	85a6                	mv	a1,s1
ffffffffc0200e44:	00001517          	auipc	a0,0x1
ffffffffc0200e48:	65c50513          	addi	a0,a0,1628 # ffffffffc02024a0 <commands+0x770>
ffffffffc0200e4c:	a66ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>

    // 检查幂次正确
    assert(p0->property == 3 && p1->property == 4 && p2->property == 5);
ffffffffc0200e50:	4818                	lw	a4,16(s0)
ffffffffc0200e52:	478d                	li	a5,3
ffffffffc0200e54:	04f71b63          	bne	a4,a5,ffffffffc0200eaa <buddy_system_check+0x2ba>
ffffffffc0200e58:	01092703          	lw	a4,16(s2)
ffffffffc0200e5c:	4791                	li	a5,4
ffffffffc0200e5e:	04f71663          	bne	a4,a5,ffffffffc0200eaa <buddy_system_check+0x2ba>
ffffffffc0200e62:	4898                	lw	a4,16(s1)
ffffffffc0200e64:	4795                	li	a5,5
ffffffffc0200e66:	04f71263          	bne	a4,a5,ffffffffc0200eaa <buddy_system_check+0x2ba>

    // 暂存p0，删后分配看看能不能找到
    struct Page *temp = p0;

    free_pages(p0, 5);
ffffffffc0200e6a:	8522                	mv	a0,s0
ffffffffc0200e6c:	4595                	li	a1,5
ffffffffc0200e6e:	352000ef          	jal	ra,ffffffffc02011c0 <free_pages>

    p0 = alloc_pages(5);
ffffffffc0200e72:	4515                	li	a0,5
ffffffffc0200e74:	30e000ef          	jal	ra,ffffffffc0201182 <alloc_pages>
    assert(p0 == temp);
ffffffffc0200e78:	0ca41963          	bne	s0,a0,ffffffffc0200f4a <buddy_system_check+0x35a>
    show_buddy_array(0, MAX_BUDDY_ORDER);
}
ffffffffc0200e7c:	7402                	ld	s0,32(sp)
ffffffffc0200e7e:	70a2                	ld	ra,40(sp)
ffffffffc0200e80:	64e2                	ld	s1,24(sp)
ffffffffc0200e82:	6942                	ld	s2,16(sp)
ffffffffc0200e84:	69a2                	ld	s3,8(sp)
ffffffffc0200e86:	6145                	addi	sp,sp,48
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200e88:	b185                	j	ffffffffc0200ae8 <show_buddy_array.constprop.0>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200e8a:	00001697          	auipc	a3,0x1
ffffffffc0200e8e:	63668693          	addi	a3,a3,1590 # ffffffffc02024c0 <commands+0x790>
ffffffffc0200e92:	00001617          	auipc	a2,0x1
ffffffffc0200e96:	39e60613          	addi	a2,a2,926 # ffffffffc0202230 <commands+0x500>
ffffffffc0200e9a:	13800593          	li	a1,312
ffffffffc0200e9e:	00001517          	auipc	a0,0x1
ffffffffc0200ea2:	3aa50513          	addi	a0,a0,938 # ffffffffc0202248 <commands+0x518>
ffffffffc0200ea6:	d06ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p0->property == 3 && p1->property == 4 && p2->property == 5);
ffffffffc0200eaa:	00002697          	auipc	a3,0x2
ffffffffc0200eae:	89668693          	addi	a3,a3,-1898 # ffffffffc0202740 <commands+0xa10>
ffffffffc0200eb2:	00001617          	auipc	a2,0x1
ffffffffc0200eb6:	37e60613          	addi	a2,a2,894 # ffffffffc0202230 <commands+0x500>
ffffffffc0200eba:	17d00593          	li	a1,381
ffffffffc0200ebe:	00001517          	auipc	a0,0x1
ffffffffc0200ec2:	38a50513          	addi	a0,a0,906 # ffffffffc0202248 <commands+0x518>
ffffffffc0200ec6:	ce6ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200eca:	00001697          	auipc	a3,0x1
ffffffffc0200ece:	61e68693          	addi	a3,a3,1566 # ffffffffc02024e8 <commands+0x7b8>
ffffffffc0200ed2:	00001617          	auipc	a2,0x1
ffffffffc0200ed6:	35e60613          	addi	a2,a2,862 # ffffffffc0202230 <commands+0x500>
ffffffffc0200eda:	13900593          	li	a1,313
ffffffffc0200ede:	00001517          	auipc	a0,0x1
ffffffffc0200ee2:	36a50513          	addi	a0,a0,874 # ffffffffc0202248 <commands+0x518>
ffffffffc0200ee6:	cc6ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200eea:	00001697          	auipc	a3,0x1
ffffffffc0200eee:	65e68693          	addi	a3,a3,1630 # ffffffffc0202548 <commands+0x818>
ffffffffc0200ef2:	00001617          	auipc	a2,0x1
ffffffffc0200ef6:	33e60613          	addi	a2,a2,830 # ffffffffc0202230 <commands+0x500>
ffffffffc0200efa:	13c00593          	li	a1,316
ffffffffc0200efe:	00001517          	auipc	a0,0x1
ffffffffc0200f02:	34a50513          	addi	a0,a0,842 # ffffffffc0202248 <commands+0x518>
ffffffffc0200f06:	ca6ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200f0a:	00001697          	auipc	a3,0x1
ffffffffc0200f0e:	65e68693          	addi	a3,a3,1630 # ffffffffc0202568 <commands+0x838>
ffffffffc0200f12:	00001617          	auipc	a2,0x1
ffffffffc0200f16:	31e60613          	addi	a2,a2,798 # ffffffffc0202230 <commands+0x500>
ffffffffc0200f1a:	13d00593          	li	a1,317
ffffffffc0200f1e:	00001517          	auipc	a0,0x1
ffffffffc0200f22:	32a50513          	addi	a0,a0,810 # ffffffffc0202248 <commands+0x518>
ffffffffc0200f26:	c86ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200f2a:	00001697          	auipc	a3,0x1
ffffffffc0200f2e:	65e68693          	addi	a3,a3,1630 # ffffffffc0202588 <commands+0x858>
ffffffffc0200f32:	00001617          	auipc	a2,0x1
ffffffffc0200f36:	2fe60613          	addi	a2,a2,766 # ffffffffc0202230 <commands+0x500>
ffffffffc0200f3a:	14300593          	li	a1,323
ffffffffc0200f3e:	00001517          	auipc	a0,0x1
ffffffffc0200f42:	30a50513          	addi	a0,a0,778 # ffffffffc0202248 <commands+0x518>
ffffffffc0200f46:	c66ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p0 == temp);
ffffffffc0200f4a:	00002697          	auipc	a3,0x2
ffffffffc0200f4e:	83668693          	addi	a3,a3,-1994 # ffffffffc0202780 <commands+0xa50>
ffffffffc0200f52:	00001617          	auipc	a2,0x1
ffffffffc0200f56:	2de60613          	addi	a2,a2,734 # ffffffffc0202230 <commands+0x500>
ffffffffc0200f5a:	18500593          	li	a1,389
ffffffffc0200f5e:	00001517          	auipc	a0,0x1
ffffffffc0200f62:	2ea50513          	addi	a0,a0,746 # ffffffffc0202248 <commands+0x518>
ffffffffc0200f66:	c46ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(!PageProperty(p0));
ffffffffc0200f6a:	00001697          	auipc	a3,0x1
ffffffffc0200f6e:	78e68693          	addi	a3,a3,1934 # ffffffffc02026f8 <commands+0x9c8>
ffffffffc0200f72:	00001617          	auipc	a2,0x1
ffffffffc0200f76:	2be60613          	addi	a2,a2,702 # ffffffffc0202230 <commands+0x500>
ffffffffc0200f7a:	16d00593          	li	a1,365
ffffffffc0200f7e:	00001517          	auipc	a0,0x1
ffffffffc0200f82:	2ca50513          	addi	a0,a0,714 # ffffffffc0202248 <commands+0x518>
ffffffffc0200f86:	c26ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p0 != NULL);
ffffffffc0200f8a:	00001697          	auipc	a3,0x1
ffffffffc0200f8e:	75e68693          	addi	a3,a3,1886 # ffffffffc02026e8 <commands+0x9b8>
ffffffffc0200f92:	00001617          	auipc	a2,0x1
ffffffffc0200f96:	29e60613          	addi	a2,a2,670 # ffffffffc0202230 <commands+0x500>
ffffffffc0200f9a:	16c00593          	li	a1,364
ffffffffc0200f9e:	00001517          	auipc	a0,0x1
ffffffffc0200fa2:	2aa50513          	addi	a0,a0,682 # ffffffffc0202248 <commands+0x518>
ffffffffc0200fa6:	c06ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200faa:	00001697          	auipc	a3,0x1
ffffffffc0200fae:	57e68693          	addi	a3,a3,1406 # ffffffffc0202528 <commands+0x7f8>
ffffffffc0200fb2:	00001617          	auipc	a2,0x1
ffffffffc0200fb6:	27e60613          	addi	a2,a2,638 # ffffffffc0202230 <commands+0x500>
ffffffffc0200fba:	13b00593          	li	a1,315
ffffffffc0200fbe:	00001517          	auipc	a0,0x1
ffffffffc0200fc2:	28a50513          	addi	a0,a0,650 # ffffffffc0202248 <commands+0x518>
ffffffffc0200fc6:	be6ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200fca <buddy_system_alloc_pages>:
{
ffffffffc0200fca:	1141                	addi	sp,sp,-16
ffffffffc0200fcc:	e406                	sd	ra,8(sp)
    assert(requested_pages > 0);
ffffffffc0200fce:	14050c63          	beqz	a0,ffffffffc0201126 <buddy_system_alloc_pages+0x15c>
    if (requested_pages > nr_free)
ffffffffc0200fd2:	00005817          	auipc	a6,0x5
ffffffffc0200fd6:	04680813          	addi	a6,a6,70 # ffffffffc0206018 <buddy_s>
ffffffffc0200fda:	0f886783          	lwu	a5,248(a6)
ffffffffc0200fde:	832a                	mv	t1,a0
ffffffffc0200fe0:	0ea7e063          	bltu	a5,a0,ffffffffc02010c0 <buddy_system_alloc_pages+0xf6>
    if (n & (n - 1))
ffffffffc0200fe4:	fff50793          	addi	a5,a0,-1
ffffffffc0200fe8:	8fe9                	and	a5,a5,a0
ffffffffc0200fea:	eff9                	bnez	a5,ffffffffc02010c8 <buddy_system_alloc_pages+0xfe>
    while (n >> 1)
ffffffffc0200fec:	00135793          	srli	a5,t1,0x1
ffffffffc0200ff0:	10078763          	beqz	a5,ffffffffc02010fe <buddy_system_alloc_pages+0x134>
    unsigned int order = 0;
ffffffffc0200ff4:	4881                	li	a7,0
    while (n >> 1)
ffffffffc0200ff6:	8385                	srli	a5,a5,0x1
        order++;
ffffffffc0200ff8:	2885                	addiw	a7,a7,1
    while (n >> 1)
ffffffffc0200ffa:	fff5                	bnez	a5,ffffffffc0200ff6 <buddy_system_alloc_pages+0x2c>
ffffffffc0200ffc:	02089793          	slli	a5,a7,0x20
ffffffffc0201000:	01c7de93          	srli	t4,a5,0x1c
ffffffffc0201004:	008e8f13          	addi	t5,t4,8
    while (!found)
ffffffffc0201008:	2885                	addiw	a7,a7,1
ffffffffc020100a:	00489e13          	slli	t3,a7,0x4
ffffffffc020100e:	0e21                	addi	t3,t3,8
        if (!list_empty(&(buddy_array[order_of_2])))
ffffffffc0201010:	9f42                	add	t5,t5,a6
ffffffffc0201012:	9e42                	add	t3,t3,a6
    return list->next == list;
ffffffffc0201014:	9ec2                	add	t4,t4,a6
ffffffffc0201016:	0008829b          	sext.w	t0,a7
    page_b = page_a + (1 << (n - 1)); // 找到a的伙伴块b，因为是大块分割的，直接加2的n-1次幂就行
ffffffffc020101a:	4f85                	li	t6,1
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020101c:	4509                	li	a0,2
ffffffffc020101e:	010eb783          	ld	a5,16(t4)
        if (!list_empty(&(buddy_array[order_of_2])))
ffffffffc0201022:	0aff1b63          	bne	t5,a5,ffffffffc02010d8 <buddy_system_alloc_pages+0x10e>
            for (i = order_of_2 + 1; i <= max_order; ++i)
ffffffffc0201026:	00082583          	lw	a1,0(a6)
ffffffffc020102a:	0915eb63          	bltu	a1,a7,ffffffffc02010c0 <buddy_system_alloc_pages+0xf6>
ffffffffc020102e:	8772                	mv	a4,t3
ffffffffc0201030:	87c6                	mv	a5,a7
ffffffffc0201032:	8696                	mv	a3,t0
ffffffffc0201034:	a039                	j	ffffffffc0201042 <buddy_system_alloc_pages+0x78>
ffffffffc0201036:	0785                	addi	a5,a5,1
ffffffffc0201038:	0007869b          	sext.w	a3,a5
ffffffffc020103c:	0741                	addi	a4,a4,16
ffffffffc020103e:	08d5e163          	bltu	a1,a3,ffffffffc02010c0 <buddy_system_alloc_pages+0xf6>
                if (!list_empty(&(buddy_array[i])))
ffffffffc0201042:	6710                	ld	a2,8(a4)
ffffffffc0201044:	fec709e3          	beq	a4,a2,ffffffffc0201036 <buddy_system_alloc_pages+0x6c>
    assert(n > 0 && n <= max_order);
ffffffffc0201048:	cfdd                	beqz	a5,ffffffffc0201106 <buddy_system_alloc_pages+0x13c>
ffffffffc020104a:	1582                	slli	a1,a1,0x20
ffffffffc020104c:	9181                	srli	a1,a1,0x20
ffffffffc020104e:	0af5ec63          	bltu	a1,a5,ffffffffc0201106 <buddy_system_alloc_pages+0x13c>
ffffffffc0201052:	00479613          	slli	a2,a5,0x4
ffffffffc0201056:	9642                	add	a2,a2,a6
ffffffffc0201058:	6a10                	ld	a2,16(a2)
    assert(!list_empty(&(buddy_array[n])));
ffffffffc020105a:	0ee60663          	beq	a2,a4,ffffffffc0201146 <buddy_system_alloc_pages+0x17c>
    page_b = page_a + (1 << (n - 1)); // 找到a的伙伴块b，因为是大块分割的，直接加2的n-1次幂就行
ffffffffc020105e:	fff6859b          	addiw	a1,a3,-1
ffffffffc0201062:	00bf93bb          	sllw	t2,t6,a1
ffffffffc0201066:	00239713          	slli	a4,t2,0x2
ffffffffc020106a:	971e                	add	a4,a4,t2
ffffffffc020106c:	070e                	slli	a4,a4,0x3
ffffffffc020106e:	1721                	addi	a4,a4,-24
    page_a->property = n - 1;
ffffffffc0201070:	feb62c23          	sw	a1,-8(a2)
    page_b = page_a + (1 << (n - 1)); // 找到a的伙伴块b，因为是大块分割的，直接加2的n-1次幂就行
ffffffffc0201074:	9732                	add	a4,a4,a2
    page_b->property = n - 1;
ffffffffc0201076:	cb0c                	sw	a1,16(a4)
ffffffffc0201078:	ff060593          	addi	a1,a2,-16
ffffffffc020107c:	40a5b02f          	amoor.d	zero,a0,(a1)
ffffffffc0201080:	00870593          	addi	a1,a4,8
ffffffffc0201084:	40a5b02f          	amoor.d	zero,a0,(a1)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201088:	00063383          	ld	t2,0(a2)
ffffffffc020108c:	660c                	ld	a1,8(a2)
    list_add(&(buddy_array[n - 1]), &(page_a->page_link));
ffffffffc020108e:	17fd                	addi	a5,a5,-1
    __list_add(elm, listelm, listelm->next);
ffffffffc0201090:	0792                	slli	a5,a5,0x4
    prev->next = next;
ffffffffc0201092:	00b3b423          	sd	a1,8(t2)
    next->prev = prev;
ffffffffc0201096:	0075b023          	sd	t2,0(a1) # 4000 <kern_entry-0xffffffffc01fc000>
    __list_add(elm, listelm, listelm->next);
ffffffffc020109a:	00f803b3          	add	t2,a6,a5
ffffffffc020109e:	0103b583          	ld	a1,16(t2)
ffffffffc02010a2:	07a1                	addi	a5,a5,8
    prev->next = next->prev = elm;
ffffffffc02010a4:	00c3b823          	sd	a2,16(t2)
ffffffffc02010a8:	97c2                	add	a5,a5,a6
    elm->prev = prev;
ffffffffc02010aa:	e21c                	sd	a5,0(a2)
    list_add(&(page_a->page_link), &(page_b->page_link));
ffffffffc02010ac:	01870793          	addi	a5,a4,24
    prev->next = next->prev = elm;
ffffffffc02010b0:	e19c                	sd	a5,0(a1)
            if (i > max_order)
ffffffffc02010b2:	00082383          	lw	t2,0(a6)
ffffffffc02010b6:	e61c                	sd	a5,8(a2)
    elm->next = next;
ffffffffc02010b8:	f30c                	sd	a1,32(a4)
    elm->prev = prev;
ffffffffc02010ba:	ef10                	sd	a2,24(a4)
ffffffffc02010bc:	f6d3f1e3          	bgeu	t2,a3,ffffffffc020101e <buddy_system_alloc_pages+0x54>
}
ffffffffc02010c0:	60a2                	ld	ra,8(sp)
        return NULL;
ffffffffc02010c2:	4501                	li	a0,0
}
ffffffffc02010c4:	0141                	addi	sp,sp,16
ffffffffc02010c6:	8082                	ret
ffffffffc02010c8:	4785                	li	a5,1
            n = n >> 1;
ffffffffc02010ca:	00135313          	srli	t1,t1,0x1
            res = res << 1;
ffffffffc02010ce:	0786                	slli	a5,a5,0x1
        while (n)
ffffffffc02010d0:	fe031de3          	bnez	t1,ffffffffc02010ca <buddy_system_alloc_pages+0x100>
            res = res << 1;
ffffffffc02010d4:	833e                	mv	t1,a5
ffffffffc02010d6:	bf19                	j	ffffffffc0200fec <buddy_system_alloc_pages+0x22>
    __list_del(listelm->prev, listelm->next);
ffffffffc02010d8:	6798                	ld	a4,8(a5)
ffffffffc02010da:	6394                	ld	a3,0(a5)
            allocated_page = le2page(list_next(&(buddy_array[order_of_2])), page_link);
ffffffffc02010dc:	fe878513          	addi	a0,a5,-24 # 3fe8 <kern_entry-0xffffffffc01fc018>
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02010e0:	17c1                	addi	a5,a5,-16
    prev->next = next;
ffffffffc02010e2:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc02010e4:	e314                	sd	a3,0(a4)
ffffffffc02010e6:	5775                	li	a4,-3
ffffffffc02010e8:	60e7b02f          	amoand.d	zero,a4,(a5)
        nr_free -= adjusted_pages;
ffffffffc02010ec:	0f882783          	lw	a5,248(a6)
}
ffffffffc02010f0:	60a2                	ld	ra,8(sp)
        nr_free -= adjusted_pages;
ffffffffc02010f2:	4067833b          	subw	t1,a5,t1
ffffffffc02010f6:	0e682c23          	sw	t1,248(a6)
}
ffffffffc02010fa:	0141                	addi	sp,sp,16
ffffffffc02010fc:	8082                	ret
    while (n >> 1)
ffffffffc02010fe:	4f21                	li	t5,8
    unsigned int order = 0;
ffffffffc0201100:	4881                	li	a7,0
ffffffffc0201102:	4e81                	li	t4,0
ffffffffc0201104:	b711                	j	ffffffffc0201008 <buddy_system_alloc_pages+0x3e>
    assert(n > 0 && n <= max_order);
ffffffffc0201106:	00001697          	auipc	a3,0x1
ffffffffc020110a:	6a268693          	addi	a3,a3,1698 # ffffffffc02027a8 <commands+0xa78>
ffffffffc020110e:	00001617          	auipc	a2,0x1
ffffffffc0201112:	12260613          	addi	a2,a2,290 # ffffffffc0202230 <commands+0x500>
ffffffffc0201116:	04a00593          	li	a1,74
ffffffffc020111a:	00001517          	auipc	a0,0x1
ffffffffc020111e:	12e50513          	addi	a0,a0,302 # ffffffffc0202248 <commands+0x518>
ffffffffc0201122:	a8aff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(requested_pages > 0);
ffffffffc0201126:	00001697          	auipc	a3,0x1
ffffffffc020112a:	66a68693          	addi	a3,a3,1642 # ffffffffc0202790 <commands+0xa60>
ffffffffc020112e:	00001617          	auipc	a2,0x1
ffffffffc0201132:	10260613          	addi	a2,a2,258 # ffffffffc0202230 <commands+0x500>
ffffffffc0201136:	0ac00593          	li	a1,172
ffffffffc020113a:	00001517          	auipc	a0,0x1
ffffffffc020113e:	10e50513          	addi	a0,a0,270 # ffffffffc0202248 <commands+0x518>
ffffffffc0201142:	a6aff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(!list_empty(&(buddy_array[n])));
ffffffffc0201146:	00001697          	auipc	a3,0x1
ffffffffc020114a:	67a68693          	addi	a3,a3,1658 # ffffffffc02027c0 <commands+0xa90>
ffffffffc020114e:	00001617          	auipc	a2,0x1
ffffffffc0201152:	0e260613          	addi	a2,a2,226 # ffffffffc0202230 <commands+0x500>
ffffffffc0201156:	04b00593          	li	a1,75
ffffffffc020115a:	00001517          	auipc	a0,0x1
ffffffffc020115e:	0ee50513          	addi	a0,a0,238 # ffffffffc0202248 <commands+0x518>
ffffffffc0201162:	a4aff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0201166 <pa2page.part.0>:
它的作用是将物理地址转换为对应的 Page 结构体指针。
通过 PPN 宏获取物理页面号，然后判断物理页面号是否大于等于全局变量 npage
如果是，则表示物理地址无效，会触发 panic 异常
如果物理地址有效，则通过 pages 数组和物理页面号计算出对应的 Page 结构体指针，并返回该指针。
*/
static inline struct Page *pa2page(uintptr_t pa)
ffffffffc0201166:	1141                	addi	sp,sp,-16
{
    if (PPN(pa) >= npage)
    {
        panic("pa2page called with invalid pa");
ffffffffc0201168:	00001617          	auipc	a2,0x1
ffffffffc020116c:	6d060613          	addi	a2,a2,1744 # ffffffffc0202838 <buddy_system_pmm_manager+0x38>
ffffffffc0201170:	08200593          	li	a1,130
ffffffffc0201174:	00001517          	auipc	a0,0x1
ffffffffc0201178:	6e450513          	addi	a0,a0,1764 # ffffffffc0202858 <buddy_system_pmm_manager+0x58>
static inline struct Page *pa2page(uintptr_t pa)
ffffffffc020117c:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc020117e:	a2eff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0201182 <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201182:	100027f3          	csrr	a5,sstatus
ffffffffc0201186:	8b89                	andi	a5,a5,2
ffffffffc0201188:	e799                	bnez	a5,ffffffffc0201196 <alloc_pages+0x14>
    // 为确保内存管理修改相关数据时不被中断打断，提供两个功能，
    // 一个是保存 sstatus寄存器中的中断使能位(SIE)信息并屏蔽中断的功能，
    // 另一个是根据保存的中断使能位信息来使能中断的功能
    local_intr_save(intr_flag); // 禁止中断，保证物理内存管理器的操作原子性，即不能被其他中断打断
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc020118a:	00005797          	auipc	a5,0x5
ffffffffc020118e:	3b67b783          	ld	a5,950(a5) # ffffffffc0206540 <pmm_manager>
ffffffffc0201192:	6f9c                	ld	a5,24(a5)
ffffffffc0201194:	8782                	jr	a5
{
ffffffffc0201196:	1141                	addi	sp,sp,-16
ffffffffc0201198:	e406                	sd	ra,8(sp)
ffffffffc020119a:	e022                	sd	s0,0(sp)
ffffffffc020119c:	842a                	mv	s0,a0
        intr_disable();
ffffffffc020119e:	ac0ff0ef          	jal	ra,ffffffffc020045e <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02011a2:	00005797          	auipc	a5,0x5
ffffffffc02011a6:	39e7b783          	ld	a5,926(a5) # ffffffffc0206540 <pmm_manager>
ffffffffc02011aa:	6f9c                	ld	a5,24(a5)
ffffffffc02011ac:	8522                	mv	a0,s0
ffffffffc02011ae:	9782                	jalr	a5
ffffffffc02011b0:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc02011b2:	aa6ff0ef          	jal	ra,ffffffffc0200458 <intr_enable>
    }
    local_intr_restore(intr_flag); // 恢复中断
    return page;
}
ffffffffc02011b6:	60a2                	ld	ra,8(sp)
ffffffffc02011b8:	8522                	mv	a0,s0
ffffffffc02011ba:	6402                	ld	s0,0(sp)
ffffffffc02011bc:	0141                	addi	sp,sp,16
ffffffffc02011be:	8082                	ret

ffffffffc02011c0 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02011c0:	100027f3          	csrr	a5,sstatus
ffffffffc02011c4:	8b89                	andi	a5,a5,2
ffffffffc02011c6:	e799                	bnez	a5,ffffffffc02011d4 <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc02011c8:	00005797          	auipc	a5,0x5
ffffffffc02011cc:	3787b783          	ld	a5,888(a5) # ffffffffc0206540 <pmm_manager>
ffffffffc02011d0:	739c                	ld	a5,32(a5)
ffffffffc02011d2:	8782                	jr	a5
{
ffffffffc02011d4:	1101                	addi	sp,sp,-32
ffffffffc02011d6:	ec06                	sd	ra,24(sp)
ffffffffc02011d8:	e822                	sd	s0,16(sp)
ffffffffc02011da:	e426                	sd	s1,8(sp)
ffffffffc02011dc:	842a                	mv	s0,a0
ffffffffc02011de:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc02011e0:	a7eff0ef          	jal	ra,ffffffffc020045e <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02011e4:	00005797          	auipc	a5,0x5
ffffffffc02011e8:	35c7b783          	ld	a5,860(a5) # ffffffffc0206540 <pmm_manager>
ffffffffc02011ec:	739c                	ld	a5,32(a5)
ffffffffc02011ee:	85a6                	mv	a1,s1
ffffffffc02011f0:	8522                	mv	a0,s0
ffffffffc02011f2:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc02011f4:	6442                	ld	s0,16(sp)
ffffffffc02011f6:	60e2                	ld	ra,24(sp)
ffffffffc02011f8:	64a2                	ld	s1,8(sp)
ffffffffc02011fa:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02011fc:	a5cff06f          	j	ffffffffc0200458 <intr_enable>

ffffffffc0201200 <pmm_init>:
    pmm_manager = &buddy_system_pmm_manager;
ffffffffc0201200:	00001797          	auipc	a5,0x1
ffffffffc0201204:	60078793          	addi	a5,a5,1536 # ffffffffc0202800 <buddy_system_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201208:	638c                	ld	a1,0(a5)
    // 0x8000-0x7cb9=0x0347个不可用，这些页存的是结构体page的数据
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void)
{
ffffffffc020120a:	715d                	addi	sp,sp,-80
ffffffffc020120c:	f44e                	sd	s3,40(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020120e:	00001517          	auipc	a0,0x1
ffffffffc0201212:	65a50513          	addi	a0,a0,1626 # ffffffffc0202868 <buddy_system_pmm_manager+0x68>
    pmm_manager = &buddy_system_pmm_manager;
ffffffffc0201216:	00005997          	auipc	s3,0x5
ffffffffc020121a:	32a98993          	addi	s3,s3,810 # ffffffffc0206540 <pmm_manager>
{
ffffffffc020121e:	e486                	sd	ra,72(sp)
ffffffffc0201220:	e0a2                	sd	s0,64(sp)
ffffffffc0201222:	f84a                	sd	s2,48(sp)
ffffffffc0201224:	f052                	sd	s4,32(sp)
ffffffffc0201226:	ec56                	sd	s5,24(sp)
    pmm_manager = &buddy_system_pmm_manager;
ffffffffc0201228:	00f9b023          	sd	a5,0(s3)
{
ffffffffc020122c:	fc26                	sd	s1,56(sp)
ffffffffc020122e:	e85a                	sd	s6,16(sp)
ffffffffc0201230:	e45e                	sd	s7,8(sp)
ffffffffc0201232:	e062                	sd	s8,0(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201234:	e7ffe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    pmm_manager->init();
ffffffffc0201238:	0009b783          	ld	a5,0(s3)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET; // 设置虚拟到物理地址的偏移: 硬编码0xFFFFFFFF40000000
ffffffffc020123c:	00005917          	auipc	s2,0x5
ffffffffc0201240:	31c90913          	addi	s2,s2,796 # ffffffffc0206558 <va_pa_offset>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0201244:	4445                	li	s0,17
    pmm_manager->init();
ffffffffc0201246:	679c                	ld	a5,8(a5)
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0201248:	046e                	slli	s0,s0,0x1b
    npage = maxpa / PGSIZE;
ffffffffc020124a:	00005a97          	auipc	s5,0x5
ffffffffc020124e:	2e6a8a93          	addi	s5,s5,742 # ffffffffc0206530 <npage>
    pmm_manager->init();
ffffffffc0201252:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET; // 设置虚拟到物理地址的偏移: 硬编码0xFFFFFFFF40000000
ffffffffc0201254:	57f5                	li	a5,-3
ffffffffc0201256:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc0201258:	00001517          	auipc	a0,0x1
ffffffffc020125c:	62850513          	addi	a0,a0,1576 # ffffffffc0202880 <buddy_system_pmm_manager+0x80>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET; // 设置虚拟到物理地址的偏移: 硬编码0xFFFFFFFF40000000
ffffffffc0201260:	00f93023          	sd	a5,0(s2)
    cprintf("physcial memory map:\n");
ffffffffc0201264:	e4ffe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0201268:	40100613          	li	a2,1025
ffffffffc020126c:	fff40693          	addi	a3,s0,-1
ffffffffc0201270:	0656                	slli	a2,a2,0x15
ffffffffc0201272:	07e005b7          	lui	a1,0x7e00
ffffffffc0201276:	00001517          	auipc	a0,0x1
ffffffffc020127a:	62250513          	addi	a0,a0,1570 # ffffffffc0202898 <buddy_system_pmm_manager+0x98>
ffffffffc020127e:	e35fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("maxpa: 0x%016lx.\n", maxpa); // test point
ffffffffc0201282:	85a2                	mv	a1,s0
ffffffffc0201284:	00001517          	auipc	a0,0x1
ffffffffc0201288:	64450513          	addi	a0,a0,1604 # ffffffffc02028c8 <buddy_system_pmm_manager+0xc8>
ffffffffc020128c:	e27fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0201290:	000887b7          	lui	a5,0x88
    cprintf("npage: 0x%016lx.\n", npage); // test point,为0x8800_0
ffffffffc0201294:	000885b7          	lui	a1,0x88
ffffffffc0201298:	00001517          	auipc	a0,0x1
ffffffffc020129c:	64850513          	addi	a0,a0,1608 # ffffffffc02028e0 <buddy_system_pmm_manager+0xe0>
    npage = maxpa / PGSIZE;
ffffffffc02012a0:	00fab023          	sd	a5,0(s5)
    cprintf("npage: 0x%016lx.\n", npage); // test point,为0x8800_0
ffffffffc02012a4:	e0ffe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("nbase: 0x%016lx.\n", nbase); // test point，为0x8000_0
ffffffffc02012a8:	000805b7          	lui	a1,0x80
ffffffffc02012ac:	00001517          	auipc	a0,0x1
ffffffffc02012b0:	64c50513          	addi	a0,a0,1612 # ffffffffc02028f8 <buddy_system_pmm_manager+0xf8>
ffffffffc02012b4:	dfffe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("end pythical address: 0x%016lx.\n", PADDR((uintptr_t)end)); // test point
ffffffffc02012b8:	c0200a37          	lui	s4,0xc0200
ffffffffc02012bc:	00005697          	auipc	a3,0x5
ffffffffc02012c0:	2ac68693          	addi	a3,a3,684 # ffffffffc0206568 <end>
ffffffffc02012c4:	2746e963          	bltu	a3,s4,ffffffffc0201536 <pmm_init+0x336>
ffffffffc02012c8:	00093583          	ld	a1,0(s2)
ffffffffc02012cc:	00001517          	auipc	a0,0x1
ffffffffc02012d0:	67c50513          	addi	a0,a0,1660 # ffffffffc0202948 <buddy_system_pmm_manager+0x148>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02012d4:	00005497          	auipc	s1,0x5
ffffffffc02012d8:	26448493          	addi	s1,s1,612 # ffffffffc0206538 <pages>
    cprintf("end pythical address: 0x%016lx.\n", PADDR((uintptr_t)end)); // test point
ffffffffc02012dc:	40b685b3          	sub	a1,a3,a1
ffffffffc02012e0:	dd3fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02012e4:	00006697          	auipc	a3,0x6
ffffffffc02012e8:	28368693          	addi	a3,a3,643 # ffffffffc0207567 <end+0xfff>
ffffffffc02012ec:	75fd                	lui	a1,0xfffff
ffffffffc02012ee:	8eed                	and	a3,a3,a1
ffffffffc02012f0:	e094                	sd	a3,0(s1)
    cprintf("pages pythical address: 0x%016lx.\n", PADDR((uintptr_t)pages)); // test point
ffffffffc02012f2:	2346e663          	bltu	a3,s4,ffffffffc020151e <pmm_init+0x31e>
ffffffffc02012f6:	00093583          	ld	a1,0(s2)
ffffffffc02012fa:	00001517          	auipc	a0,0x1
ffffffffc02012fe:	67650513          	addi	a0,a0,1654 # ffffffffc0202970 <buddy_system_pmm_manager+0x170>
ffffffffc0201302:	40b685b3          	sub	a1,a3,a1
ffffffffc0201306:	dadfe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020130a:	000ab503          	ld	a0,0(s5)
ffffffffc020130e:	000807b7          	lui	a5,0x80
ffffffffc0201312:	4681                	li	a3,0
ffffffffc0201314:	4701                	li	a4,0
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201316:	4585                	li	a1,1
ffffffffc0201318:	fff80637          	lui	a2,0xfff80
ffffffffc020131c:	00f50f63          	beq	a0,a5,ffffffffc020133a <pmm_init+0x13a>
        SetPageReserved(pages + i); // 在memlayout.h中，SetPageReserved是一个宏，将给定的页面标记为保留给内存使用的
ffffffffc0201320:	609c                	ld	a5,0(s1)
ffffffffc0201322:	97b6                	add	a5,a5,a3
ffffffffc0201324:	07a1                	addi	a5,a5,8
ffffffffc0201326:	40b7b02f          	amoor.d	zero,a1,(a5)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020132a:	000ab783          	ld	a5,0(s5)
ffffffffc020132e:	0705                	addi	a4,a4,1
ffffffffc0201330:	02868693          	addi	a3,a3,40
ffffffffc0201334:	97b2                	add	a5,a5,a2
ffffffffc0201336:	fef765e3          	bltu	a4,a5,ffffffffc0201320 <pmm_init+0x120>
ffffffffc020133a:	4a01                	li	s4,0
    for (size_t i = 0; i < 5; i++)
ffffffffc020133c:	4401                	li	s0,0
        cprintf("pages[%d] pythical address: 0x%016lx.\n", i, PADDR((uintptr_t)(pages + i))); // test point
ffffffffc020133e:	c0200b37          	lui	s6,0xc0200
ffffffffc0201342:	00001c17          	auipc	s8,0x1
ffffffffc0201346:	656c0c13          	addi	s8,s8,1622 # ffffffffc0202998 <buddy_system_pmm_manager+0x198>
    for (size_t i = 0; i < 5; i++)
ffffffffc020134a:	4b95                	li	s7,5
        cprintf("pages[%d] pythical address: 0x%016lx.\n", i, PADDR((uintptr_t)(pages + i))); // test point
ffffffffc020134c:	6094                	ld	a3,0(s1)
ffffffffc020134e:	96d2                	add	a3,a3,s4
ffffffffc0201350:	1966e063          	bltu	a3,s6,ffffffffc02014d0 <pmm_init+0x2d0>
ffffffffc0201354:	00093603          	ld	a2,0(s2)
ffffffffc0201358:	85a2                	mv	a1,s0
ffffffffc020135a:	8562                	mv	a0,s8
ffffffffc020135c:	40c68633          	sub	a2,a3,a2
    for (size_t i = 0; i < 5; i++)
ffffffffc0201360:	0405                	addi	s0,s0,1
        cprintf("pages[%d] pythical address: 0x%016lx.\n", i, PADDR((uintptr_t)(pages + i))); // test point
ffffffffc0201362:	d51fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    for (size_t i = 0; i < 5; i++)
ffffffffc0201366:	028a0a13          	addi	s4,s4,40 # ffffffffc0200028 <kern_entry+0x28>
ffffffffc020136a:	ff7411e3          	bne	s0,s7,ffffffffc020134c <pmm_init+0x14c>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase)); // 0x8034 7000 = 0x8020 7000 + 0x28 * 0x8000
ffffffffc020136e:	000ab783          	ld	a5,0(s5)
ffffffffc0201372:	6080                	ld	s0,0(s1)
ffffffffc0201374:	00279693          	slli	a3,a5,0x2
ffffffffc0201378:	96be                	add	a3,a3,a5
ffffffffc020137a:	068e                	slli	a3,a3,0x3
ffffffffc020137c:	9436                	add	s0,s0,a3
ffffffffc020137e:	fec006b7          	lui	a3,0xfec00
ffffffffc0201382:	9436                	add	s0,s0,a3
ffffffffc0201384:	19646063          	bltu	s0,s6,ffffffffc0201504 <pmm_init+0x304>
ffffffffc0201388:	00093683          	ld	a3,0(s2)
    cprintf("size of struct page: 0x%016lx.\n", sizeof(struct Page));                         // test point
ffffffffc020138c:	02800593          	li	a1,40
ffffffffc0201390:	00001517          	auipc	a0,0x1
ffffffffc0201394:	63050513          	addi	a0,a0,1584 # ffffffffc02029c0 <buddy_system_pmm_manager+0x1c0>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201398:	6a05                	lui	s4,0x1
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase)); // 0x8034 7000 = 0x8020 7000 + 0x28 * 0x8000
ffffffffc020139a:	8c15                	sub	s0,s0,a3
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc020139c:	1a7d                	addi	s4,s4,-1
    cprintf("size of struct page: 0x%016lx.\n", sizeof(struct Page));                         // test point
ffffffffc020139e:	d15fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02013a2:	75fd                	lui	a1,0xfffff
ffffffffc02013a4:	9a22                	add	s4,s4,s0
ffffffffc02013a6:	00ba7a33          	and	s4,s4,a1
    cprintf("freemem: 0x%016lx.\n", freemem);     // test point
ffffffffc02013aa:	00001517          	auipc	a0,0x1
ffffffffc02013ae:	63650513          	addi	a0,a0,1590 # ffffffffc02029e0 <buddy_system_pmm_manager+0x1e0>
ffffffffc02013b2:	85a2                	mv	a1,s0
ffffffffc02013b4:	cfffe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("mem_begin: 0x%016lx.\n", mem_begin); // test point
ffffffffc02013b8:	85d2                	mv	a1,s4
ffffffffc02013ba:	00001517          	auipc	a0,0x1
ffffffffc02013be:	6a650513          	addi	a0,a0,1702 # ffffffffc0202a60 <buddy_system_pmm_manager+0x260>
ffffffffc02013c2:	cf1fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("mem_end: 0x%016lx.\n", mem_end);     // test point
ffffffffc02013c6:	4b45                	li	s6,17
ffffffffc02013c8:	01bb1593          	slli	a1,s6,0x1b
ffffffffc02013cc:	00001517          	auipc	a0,0x1
ffffffffc02013d0:	62c50513          	addi	a0,a0,1580 # ffffffffc02029f8 <buddy_system_pmm_manager+0x1f8>
    if (freemem < mem_end)
ffffffffc02013d4:	0b6e                	slli	s6,s6,0x1b
    cprintf("mem_end: 0x%016lx.\n", mem_end);     // test point
ffffffffc02013d6:	cddfe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    if (PPN(pa) >= npage)
ffffffffc02013da:	00ca5b93          	srli	s7,s4,0xc
    if (freemem < mem_end)
ffffffffc02013de:	0d646263          	bltu	s0,s6,ffffffffc02014a2 <pmm_init+0x2a2>
ffffffffc02013e2:	000ab783          	ld	a5,0(s5)
ffffffffc02013e6:	10fbf163          	bgeu	s7,a5,ffffffffc02014e8 <pmm_init+0x2e8>
    }
    return &pages[PPN(pa) - nbase];
ffffffffc02013ea:	fff80437          	lui	s0,0xfff80
ffffffffc02013ee:	008b86b3          	add	a3,s7,s0
ffffffffc02013f2:	608c                	ld	a1,0(s1)
ffffffffc02013f4:	00269413          	slli	s0,a3,0x2
ffffffffc02013f8:	9436                	add	s0,s0,a3
ffffffffc02013fa:	040e                	slli	s0,s0,0x3
    cprintf("The Virtual Address corresponding to the page structure record (struct page) of mem_begin: 0x%016lx.\n", pa2page(mem_begin));        // test point
ffffffffc02013fc:	95a2                	add	a1,a1,s0
ffffffffc02013fe:	00001517          	auipc	a0,0x1
ffffffffc0201402:	61250513          	addi	a0,a0,1554 # ffffffffc0202a10 <buddy_system_pmm_manager+0x210>
ffffffffc0201406:	cadfe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    if (PPN(pa) >= npage)
ffffffffc020140a:	000ab783          	ld	a5,0(s5)
ffffffffc020140e:	0cfbfd63          	bgeu	s7,a5,ffffffffc02014e8 <pmm_init+0x2e8>
    return &pages[PPN(pa) - nbase];
ffffffffc0201412:	6094                	ld	a3,0(s1)
    cprintf("The Physical Address corresponding to the page structure record (struct page) of mem_begin: 0x%016lx.\n", PADDR(pa2page(mem_begin))); // test point
ffffffffc0201414:	c02004b7          	lui	s1,0xc0200
ffffffffc0201418:	96a2                	add	a3,a3,s0
ffffffffc020141a:	0c96e963          	bltu	a3,s1,ffffffffc02014ec <pmm_init+0x2ec>
ffffffffc020141e:	00093583          	ld	a1,0(s2)
ffffffffc0201422:	00001517          	auipc	a0,0x1
ffffffffc0201426:	65650513          	addi	a0,a0,1622 # ffffffffc0202a78 <buddy_system_pmm_manager+0x278>
ffffffffc020142a:	40b685b3          	sub	a1,a3,a1
ffffffffc020142e:	c85fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("counts of free pages available to use: 0x%016lx.\n", (mem_end - mem_begin) / PGSIZE); // test point
ffffffffc0201432:	45c5                	li	a1,17
ffffffffc0201434:	05ee                	slli	a1,a1,0x1b
ffffffffc0201436:	414585b3          	sub	a1,a1,s4
ffffffffc020143a:	81b1                	srli	a1,a1,0xc
ffffffffc020143c:	00001517          	auipc	a0,0x1
ffffffffc0201440:	6a450513          	addi	a0,a0,1700 # ffffffffc0202ae0 <buddy_system_pmm_manager+0x2e0>
ffffffffc0201444:	c6ffe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0201448:	0009b783          	ld	a5,0(s3)
ffffffffc020144c:	7b9c                	ld	a5,48(a5)
ffffffffc020144e:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201450:	00001517          	auipc	a0,0x1
ffffffffc0201454:	6c850513          	addi	a0,a0,1736 # ffffffffc0202b18 <buddy_system_pmm_manager+0x318>
ffffffffc0201458:	c5bfe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    satp_virtual = (pte_t *)boot_page_table_sv39; // pte_t 页表项
ffffffffc020145c:	00004597          	auipc	a1,0x4
ffffffffc0201460:	ba458593          	addi	a1,a1,-1116 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0201464:	00005797          	auipc	a5,0x5
ffffffffc0201468:	0eb7b623          	sd	a1,236(a5) # ffffffffc0206550 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc020146c:	0e95e163          	bltu	a1,s1,ffffffffc020154e <pmm_init+0x34e>
ffffffffc0201470:	00093603          	ld	a2,0(s2)
}
ffffffffc0201474:	6406                	ld	s0,64(sp)
ffffffffc0201476:	60a6                	ld	ra,72(sp)
ffffffffc0201478:	74e2                	ld	s1,56(sp)
ffffffffc020147a:	7942                	ld	s2,48(sp)
ffffffffc020147c:	79a2                	ld	s3,40(sp)
ffffffffc020147e:	7a02                	ld	s4,32(sp)
ffffffffc0201480:	6ae2                	ld	s5,24(sp)
ffffffffc0201482:	6b42                	ld	s6,16(sp)
ffffffffc0201484:	6ba2                	ld	s7,8(sp)
ffffffffc0201486:	6c02                	ld	s8,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0201488:	40c58633          	sub	a2,a1,a2
ffffffffc020148c:	00005797          	auipc	a5,0x5
ffffffffc0201490:	0ac7be23          	sd	a2,188(a5) # ffffffffc0206548 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201494:	00001517          	auipc	a0,0x1
ffffffffc0201498:	6a450513          	addi	a0,a0,1700 # ffffffffc0202b38 <buddy_system_pmm_manager+0x338>
}
ffffffffc020149c:	6161                	addi	sp,sp,80
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020149e:	c15fe06f          	j	ffffffffc02000b2 <cprintf>
    if (PPN(pa) >= npage)
ffffffffc02014a2:	000ab783          	ld	a5,0(s5)
ffffffffc02014a6:	04fbf163          	bgeu	s7,a5,ffffffffc02014e8 <pmm_init+0x2e8>
    pmm_manager->init_memmap(base, n);
ffffffffc02014aa:	0009b683          	ld	a3,0(s3)
    return &pages[PPN(pa) - nbase];
ffffffffc02014ae:	fff807b7          	lui	a5,0xfff80
ffffffffc02014b2:	00fb8733          	add	a4,s7,a5
ffffffffc02014b6:	6088                	ld	a0,0(s1)
ffffffffc02014b8:	00271793          	slli	a5,a4,0x2
ffffffffc02014bc:	97ba                	add	a5,a5,a4
ffffffffc02014be:	6a98                	ld	a4,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc02014c0:	414b0b33          	sub	s6,s6,s4
ffffffffc02014c4:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc02014c6:	00cb5593          	srli	a1,s6,0xc
ffffffffc02014ca:	953e                	add	a0,a0,a5
ffffffffc02014cc:	9702                	jalr	a4
}
ffffffffc02014ce:	bf11                	j	ffffffffc02013e2 <pmm_init+0x1e2>
        cprintf("pages[%d] pythical address: 0x%016lx.\n", i, PADDR((uintptr_t)(pages + i))); // test point
ffffffffc02014d0:	00001617          	auipc	a2,0x1
ffffffffc02014d4:	44060613          	addi	a2,a2,1088 # ffffffffc0202910 <buddy_system_pmm_manager+0x110>
ffffffffc02014d8:	09200593          	li	a1,146
ffffffffc02014dc:	00001517          	auipc	a0,0x1
ffffffffc02014e0:	45c50513          	addi	a0,a0,1116 # ffffffffc0202938 <buddy_system_pmm_manager+0x138>
ffffffffc02014e4:	ec9fe0ef          	jal	ra,ffffffffc02003ac <__panic>
ffffffffc02014e8:	c7fff0ef          	jal	ra,ffffffffc0201166 <pa2page.part.0>
    cprintf("The Physical Address corresponding to the page structure record (struct page) of mem_begin: 0x%016lx.\n", PADDR(pa2page(mem_begin))); // test point
ffffffffc02014ec:	00001617          	auipc	a2,0x1
ffffffffc02014f0:	42460613          	addi	a2,a2,1060 # ffffffffc0202910 <buddy_system_pmm_manager+0x110>
ffffffffc02014f4:	0a900593          	li	a1,169
ffffffffc02014f8:	00001517          	auipc	a0,0x1
ffffffffc02014fc:	44050513          	addi	a0,a0,1088 # ffffffffc0202938 <buddy_system_pmm_manager+0x138>
ffffffffc0201500:	eadfe0ef          	jal	ra,ffffffffc02003ac <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase)); // 0x8034 7000 = 0x8020 7000 + 0x28 * 0x8000
ffffffffc0201504:	86a2                	mv	a3,s0
ffffffffc0201506:	00001617          	auipc	a2,0x1
ffffffffc020150a:	40a60613          	addi	a2,a2,1034 # ffffffffc0202910 <buddy_system_pmm_manager+0x110>
ffffffffc020150e:	09900593          	li	a1,153
ffffffffc0201512:	00001517          	auipc	a0,0x1
ffffffffc0201516:	42650513          	addi	a0,a0,1062 # ffffffffc0202938 <buddy_system_pmm_manager+0x138>
ffffffffc020151a:	e93fe0ef          	jal	ra,ffffffffc02003ac <__panic>
    cprintf("pages pythical address: 0x%016lx.\n", PADDR((uintptr_t)pages)); // test point
ffffffffc020151e:	00001617          	auipc	a2,0x1
ffffffffc0201522:	3f260613          	addi	a2,a2,1010 # ffffffffc0202910 <buddy_system_pmm_manager+0x110>
ffffffffc0201526:	08600593          	li	a1,134
ffffffffc020152a:	00001517          	auipc	a0,0x1
ffffffffc020152e:	40e50513          	addi	a0,a0,1038 # ffffffffc0202938 <buddy_system_pmm_manager+0x138>
ffffffffc0201532:	e7bfe0ef          	jal	ra,ffffffffc02003ac <__panic>
    cprintf("end pythical address: 0x%016lx.\n", PADDR((uintptr_t)end)); // test point
ffffffffc0201536:	00001617          	auipc	a2,0x1
ffffffffc020153a:	3da60613          	addi	a2,a2,986 # ffffffffc0202910 <buddy_system_pmm_manager+0x110>
ffffffffc020153e:	08400593          	li	a1,132
ffffffffc0201542:	00001517          	auipc	a0,0x1
ffffffffc0201546:	3f650513          	addi	a0,a0,1014 # ffffffffc0202938 <buddy_system_pmm_manager+0x138>
ffffffffc020154a:	e63fe0ef          	jal	ra,ffffffffc02003ac <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc020154e:	86ae                	mv	a3,a1
ffffffffc0201550:	00001617          	auipc	a2,0x1
ffffffffc0201554:	3c060613          	addi	a2,a2,960 # ffffffffc0202910 <buddy_system_pmm_manager+0x110>
ffffffffc0201558:	0c500593          	li	a1,197
ffffffffc020155c:	00001517          	auipc	a0,0x1
ffffffffc0201560:	3dc50513          	addi	a0,a0,988 # ffffffffc0202938 <buddy_system_pmm_manager+0x138>
ffffffffc0201564:	e49fe0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0201568 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201568:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020156c:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc020156e:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201572:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201574:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201578:	f022                	sd	s0,32(sp)
ffffffffc020157a:	ec26                	sd	s1,24(sp)
ffffffffc020157c:	e84a                	sd	s2,16(sp)
ffffffffc020157e:	f406                	sd	ra,40(sp)
ffffffffc0201580:	e44e                	sd	s3,8(sp)
ffffffffc0201582:	84aa                	mv	s1,a0
ffffffffc0201584:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201586:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc020158a:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc020158c:	03067e63          	bgeu	a2,a6,ffffffffc02015c8 <printnum+0x60>
ffffffffc0201590:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201592:	00805763          	blez	s0,ffffffffc02015a0 <printnum+0x38>
ffffffffc0201596:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201598:	85ca                	mv	a1,s2
ffffffffc020159a:	854e                	mv	a0,s3
ffffffffc020159c:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc020159e:	fc65                	bnez	s0,ffffffffc0201596 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02015a0:	1a02                	slli	s4,s4,0x20
ffffffffc02015a2:	00001797          	auipc	a5,0x1
ffffffffc02015a6:	5d678793          	addi	a5,a5,1494 # ffffffffc0202b78 <buddy_system_pmm_manager+0x378>
ffffffffc02015aa:	020a5a13          	srli	s4,s4,0x20
ffffffffc02015ae:	9a3e                	add	s4,s4,a5
}
ffffffffc02015b0:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02015b2:	000a4503          	lbu	a0,0(s4) # 1000 <kern_entry-0xffffffffc01ff000>
}
ffffffffc02015b6:	70a2                	ld	ra,40(sp)
ffffffffc02015b8:	69a2                	ld	s3,8(sp)
ffffffffc02015ba:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02015bc:	85ca                	mv	a1,s2
ffffffffc02015be:	87a6                	mv	a5,s1
}
ffffffffc02015c0:	6942                	ld	s2,16(sp)
ffffffffc02015c2:	64e2                	ld	s1,24(sp)
ffffffffc02015c4:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02015c6:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02015c8:	03065633          	divu	a2,a2,a6
ffffffffc02015cc:	8722                	mv	a4,s0
ffffffffc02015ce:	f9bff0ef          	jal	ra,ffffffffc0201568 <printnum>
ffffffffc02015d2:	b7f9                	j	ffffffffc02015a0 <printnum+0x38>

ffffffffc02015d4 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02015d4:	7119                	addi	sp,sp,-128
ffffffffc02015d6:	f4a6                	sd	s1,104(sp)
ffffffffc02015d8:	f0ca                	sd	s2,96(sp)
ffffffffc02015da:	ecce                	sd	s3,88(sp)
ffffffffc02015dc:	e8d2                	sd	s4,80(sp)
ffffffffc02015de:	e4d6                	sd	s5,72(sp)
ffffffffc02015e0:	e0da                	sd	s6,64(sp)
ffffffffc02015e2:	fc5e                	sd	s7,56(sp)
ffffffffc02015e4:	f06a                	sd	s10,32(sp)
ffffffffc02015e6:	fc86                	sd	ra,120(sp)
ffffffffc02015e8:	f8a2                	sd	s0,112(sp)
ffffffffc02015ea:	f862                	sd	s8,48(sp)
ffffffffc02015ec:	f466                	sd	s9,40(sp)
ffffffffc02015ee:	ec6e                	sd	s11,24(sp)
ffffffffc02015f0:	892a                	mv	s2,a0
ffffffffc02015f2:	84ae                	mv	s1,a1
ffffffffc02015f4:	8d32                	mv	s10,a2
ffffffffc02015f6:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02015f8:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02015fc:	5b7d                	li	s6,-1
ffffffffc02015fe:	00001a97          	auipc	s5,0x1
ffffffffc0201602:	5aea8a93          	addi	s5,s5,1454 # ffffffffc0202bac <buddy_system_pmm_manager+0x3ac>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201606:	00001b97          	auipc	s7,0x1
ffffffffc020160a:	782b8b93          	addi	s7,s7,1922 # ffffffffc0202d88 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020160e:	000d4503          	lbu	a0,0(s10)
ffffffffc0201612:	001d0413          	addi	s0,s10,1
ffffffffc0201616:	01350a63          	beq	a0,s3,ffffffffc020162a <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc020161a:	c121                	beqz	a0,ffffffffc020165a <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc020161c:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020161e:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201620:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201622:	fff44503          	lbu	a0,-1(s0) # fffffffffff7ffff <end+0x3fd79a97>
ffffffffc0201626:	ff351ae3          	bne	a0,s3,ffffffffc020161a <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020162a:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc020162e:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201632:	4c81                	li	s9,0
ffffffffc0201634:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201636:	5c7d                	li	s8,-1
ffffffffc0201638:	5dfd                	li	s11,-1
ffffffffc020163a:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc020163e:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201640:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201644:	0ff5f593          	zext.b	a1,a1
ffffffffc0201648:	00140d13          	addi	s10,s0,1
ffffffffc020164c:	04b56263          	bltu	a0,a1,ffffffffc0201690 <vprintfmt+0xbc>
ffffffffc0201650:	058a                	slli	a1,a1,0x2
ffffffffc0201652:	95d6                	add	a1,a1,s5
ffffffffc0201654:	4194                	lw	a3,0(a1)
ffffffffc0201656:	96d6                	add	a3,a3,s5
ffffffffc0201658:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc020165a:	70e6                	ld	ra,120(sp)
ffffffffc020165c:	7446                	ld	s0,112(sp)
ffffffffc020165e:	74a6                	ld	s1,104(sp)
ffffffffc0201660:	7906                	ld	s2,96(sp)
ffffffffc0201662:	69e6                	ld	s3,88(sp)
ffffffffc0201664:	6a46                	ld	s4,80(sp)
ffffffffc0201666:	6aa6                	ld	s5,72(sp)
ffffffffc0201668:	6b06                	ld	s6,64(sp)
ffffffffc020166a:	7be2                	ld	s7,56(sp)
ffffffffc020166c:	7c42                	ld	s8,48(sp)
ffffffffc020166e:	7ca2                	ld	s9,40(sp)
ffffffffc0201670:	7d02                	ld	s10,32(sp)
ffffffffc0201672:	6de2                	ld	s11,24(sp)
ffffffffc0201674:	6109                	addi	sp,sp,128
ffffffffc0201676:	8082                	ret
            padc = '0';
ffffffffc0201678:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc020167a:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020167e:	846a                	mv	s0,s10
ffffffffc0201680:	00140d13          	addi	s10,s0,1
ffffffffc0201684:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201688:	0ff5f593          	zext.b	a1,a1
ffffffffc020168c:	fcb572e3          	bgeu	a0,a1,ffffffffc0201650 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201690:	85a6                	mv	a1,s1
ffffffffc0201692:	02500513          	li	a0,37
ffffffffc0201696:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201698:	fff44783          	lbu	a5,-1(s0)
ffffffffc020169c:	8d22                	mv	s10,s0
ffffffffc020169e:	f73788e3          	beq	a5,s3,ffffffffc020160e <vprintfmt+0x3a>
ffffffffc02016a2:	ffed4783          	lbu	a5,-2(s10)
ffffffffc02016a6:	1d7d                	addi	s10,s10,-1
ffffffffc02016a8:	ff379de3          	bne	a5,s3,ffffffffc02016a2 <vprintfmt+0xce>
ffffffffc02016ac:	b78d                	j	ffffffffc020160e <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc02016ae:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc02016b2:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02016b6:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc02016b8:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc02016bc:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02016c0:	02d86463          	bltu	a6,a3,ffffffffc02016e8 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc02016c4:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02016c8:	002c169b          	slliw	a3,s8,0x2
ffffffffc02016cc:	0186873b          	addw	a4,a3,s8
ffffffffc02016d0:	0017171b          	slliw	a4,a4,0x1
ffffffffc02016d4:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc02016d6:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02016da:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02016dc:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc02016e0:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02016e4:	fed870e3          	bgeu	a6,a3,ffffffffc02016c4 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc02016e8:	f40ddce3          	bgez	s11,ffffffffc0201640 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc02016ec:	8de2                	mv	s11,s8
ffffffffc02016ee:	5c7d                	li	s8,-1
ffffffffc02016f0:	bf81                	j	ffffffffc0201640 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc02016f2:	fffdc693          	not	a3,s11
ffffffffc02016f6:	96fd                	srai	a3,a3,0x3f
ffffffffc02016f8:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02016fc:	00144603          	lbu	a2,1(s0)
ffffffffc0201700:	2d81                	sext.w	s11,s11
ffffffffc0201702:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201704:	bf35                	j	ffffffffc0201640 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0201706:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020170a:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc020170e:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201710:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201712:	bfd9                	j	ffffffffc02016e8 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0201714:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201716:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020171a:	01174463          	blt	a4,a7,ffffffffc0201722 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc020171e:	1a088e63          	beqz	a7,ffffffffc02018da <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201722:	000a3603          	ld	a2,0(s4)
ffffffffc0201726:	46c1                	li	a3,16
ffffffffc0201728:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc020172a:	2781                	sext.w	a5,a5
ffffffffc020172c:	876e                	mv	a4,s11
ffffffffc020172e:	85a6                	mv	a1,s1
ffffffffc0201730:	854a                	mv	a0,s2
ffffffffc0201732:	e37ff0ef          	jal	ra,ffffffffc0201568 <printnum>
            break;
ffffffffc0201736:	bde1                	j	ffffffffc020160e <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201738:	000a2503          	lw	a0,0(s4)
ffffffffc020173c:	85a6                	mv	a1,s1
ffffffffc020173e:	0a21                	addi	s4,s4,8
ffffffffc0201740:	9902                	jalr	s2
            break;
ffffffffc0201742:	b5f1                	j	ffffffffc020160e <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201744:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201746:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020174a:	01174463          	blt	a4,a7,ffffffffc0201752 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc020174e:	18088163          	beqz	a7,ffffffffc02018d0 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201752:	000a3603          	ld	a2,0(s4)
ffffffffc0201756:	46a9                	li	a3,10
ffffffffc0201758:	8a2e                	mv	s4,a1
ffffffffc020175a:	bfc1                	j	ffffffffc020172a <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020175c:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201760:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201762:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201764:	bdf1                	j	ffffffffc0201640 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201766:	85a6                	mv	a1,s1
ffffffffc0201768:	02500513          	li	a0,37
ffffffffc020176c:	9902                	jalr	s2
            break;
ffffffffc020176e:	b545                	j	ffffffffc020160e <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201770:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0201774:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201776:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201778:	b5e1                	j	ffffffffc0201640 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc020177a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020177c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201780:	01174463          	blt	a4,a7,ffffffffc0201788 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0201784:	14088163          	beqz	a7,ffffffffc02018c6 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201788:	000a3603          	ld	a2,0(s4)
ffffffffc020178c:	46a1                	li	a3,8
ffffffffc020178e:	8a2e                	mv	s4,a1
ffffffffc0201790:	bf69                	j	ffffffffc020172a <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201792:	03000513          	li	a0,48
ffffffffc0201796:	85a6                	mv	a1,s1
ffffffffc0201798:	e03e                	sd	a5,0(sp)
ffffffffc020179a:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc020179c:	85a6                	mv	a1,s1
ffffffffc020179e:	07800513          	li	a0,120
ffffffffc02017a2:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02017a4:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc02017a6:	6782                	ld	a5,0(sp)
ffffffffc02017a8:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02017aa:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc02017ae:	bfb5                	j	ffffffffc020172a <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02017b0:	000a3403          	ld	s0,0(s4)
ffffffffc02017b4:	008a0713          	addi	a4,s4,8
ffffffffc02017b8:	e03a                	sd	a4,0(sp)
ffffffffc02017ba:	14040263          	beqz	s0,ffffffffc02018fe <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc02017be:	0fb05763          	blez	s11,ffffffffc02018ac <vprintfmt+0x2d8>
ffffffffc02017c2:	02d00693          	li	a3,45
ffffffffc02017c6:	0cd79163          	bne	a5,a3,ffffffffc0201888 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02017ca:	00044783          	lbu	a5,0(s0)
ffffffffc02017ce:	0007851b          	sext.w	a0,a5
ffffffffc02017d2:	cf85                	beqz	a5,ffffffffc020180a <vprintfmt+0x236>
ffffffffc02017d4:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02017d8:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02017dc:	000c4563          	bltz	s8,ffffffffc02017e6 <vprintfmt+0x212>
ffffffffc02017e0:	3c7d                	addiw	s8,s8,-1
ffffffffc02017e2:	036c0263          	beq	s8,s6,ffffffffc0201806 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc02017e6:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02017e8:	0e0c8e63          	beqz	s9,ffffffffc02018e4 <vprintfmt+0x310>
ffffffffc02017ec:	3781                	addiw	a5,a5,-32
ffffffffc02017ee:	0ef47b63          	bgeu	s0,a5,ffffffffc02018e4 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc02017f2:	03f00513          	li	a0,63
ffffffffc02017f6:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02017f8:	000a4783          	lbu	a5,0(s4)
ffffffffc02017fc:	3dfd                	addiw	s11,s11,-1
ffffffffc02017fe:	0a05                	addi	s4,s4,1
ffffffffc0201800:	0007851b          	sext.w	a0,a5
ffffffffc0201804:	ffe1                	bnez	a5,ffffffffc02017dc <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201806:	01b05963          	blez	s11,ffffffffc0201818 <vprintfmt+0x244>
ffffffffc020180a:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc020180c:	85a6                	mv	a1,s1
ffffffffc020180e:	02000513          	li	a0,32
ffffffffc0201812:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201814:	fe0d9be3          	bnez	s11,ffffffffc020180a <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201818:	6a02                	ld	s4,0(sp)
ffffffffc020181a:	bbd5                	j	ffffffffc020160e <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020181c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020181e:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201822:	01174463          	blt	a4,a7,ffffffffc020182a <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201826:	08088d63          	beqz	a7,ffffffffc02018c0 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc020182a:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc020182e:	0a044d63          	bltz	s0,ffffffffc02018e8 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201832:	8622                	mv	a2,s0
ffffffffc0201834:	8a66                	mv	s4,s9
ffffffffc0201836:	46a9                	li	a3,10
ffffffffc0201838:	bdcd                	j	ffffffffc020172a <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc020183a:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020183e:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201840:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201842:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201846:	8fb5                	xor	a5,a5,a3
ffffffffc0201848:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020184c:	02d74163          	blt	a4,a3,ffffffffc020186e <vprintfmt+0x29a>
ffffffffc0201850:	00369793          	slli	a5,a3,0x3
ffffffffc0201854:	97de                	add	a5,a5,s7
ffffffffc0201856:	639c                	ld	a5,0(a5)
ffffffffc0201858:	cb99                	beqz	a5,ffffffffc020186e <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc020185a:	86be                	mv	a3,a5
ffffffffc020185c:	00001617          	auipc	a2,0x1
ffffffffc0201860:	34c60613          	addi	a2,a2,844 # ffffffffc0202ba8 <buddy_system_pmm_manager+0x3a8>
ffffffffc0201864:	85a6                	mv	a1,s1
ffffffffc0201866:	854a                	mv	a0,s2
ffffffffc0201868:	0ce000ef          	jal	ra,ffffffffc0201936 <printfmt>
ffffffffc020186c:	b34d                	j	ffffffffc020160e <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc020186e:	00001617          	auipc	a2,0x1
ffffffffc0201872:	32a60613          	addi	a2,a2,810 # ffffffffc0202b98 <buddy_system_pmm_manager+0x398>
ffffffffc0201876:	85a6                	mv	a1,s1
ffffffffc0201878:	854a                	mv	a0,s2
ffffffffc020187a:	0bc000ef          	jal	ra,ffffffffc0201936 <printfmt>
ffffffffc020187e:	bb41                	j	ffffffffc020160e <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201880:	00001417          	auipc	s0,0x1
ffffffffc0201884:	31040413          	addi	s0,s0,784 # ffffffffc0202b90 <buddy_system_pmm_manager+0x390>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201888:	85e2                	mv	a1,s8
ffffffffc020188a:	8522                	mv	a0,s0
ffffffffc020188c:	e43e                	sd	a5,8(sp)
ffffffffc020188e:	1e6000ef          	jal	ra,ffffffffc0201a74 <strnlen>
ffffffffc0201892:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201896:	01b05b63          	blez	s11,ffffffffc02018ac <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc020189a:	67a2                	ld	a5,8(sp)
ffffffffc020189c:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02018a0:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc02018a2:	85a6                	mv	a1,s1
ffffffffc02018a4:	8552                	mv	a0,s4
ffffffffc02018a6:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02018a8:	fe0d9ce3          	bnez	s11,ffffffffc02018a0 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02018ac:	00044783          	lbu	a5,0(s0)
ffffffffc02018b0:	00140a13          	addi	s4,s0,1
ffffffffc02018b4:	0007851b          	sext.w	a0,a5
ffffffffc02018b8:	d3a5                	beqz	a5,ffffffffc0201818 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02018ba:	05e00413          	li	s0,94
ffffffffc02018be:	bf39                	j	ffffffffc02017dc <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc02018c0:	000a2403          	lw	s0,0(s4)
ffffffffc02018c4:	b7ad                	j	ffffffffc020182e <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc02018c6:	000a6603          	lwu	a2,0(s4)
ffffffffc02018ca:	46a1                	li	a3,8
ffffffffc02018cc:	8a2e                	mv	s4,a1
ffffffffc02018ce:	bdb1                	j	ffffffffc020172a <vprintfmt+0x156>
ffffffffc02018d0:	000a6603          	lwu	a2,0(s4)
ffffffffc02018d4:	46a9                	li	a3,10
ffffffffc02018d6:	8a2e                	mv	s4,a1
ffffffffc02018d8:	bd89                	j	ffffffffc020172a <vprintfmt+0x156>
ffffffffc02018da:	000a6603          	lwu	a2,0(s4)
ffffffffc02018de:	46c1                	li	a3,16
ffffffffc02018e0:	8a2e                	mv	s4,a1
ffffffffc02018e2:	b5a1                	j	ffffffffc020172a <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc02018e4:	9902                	jalr	s2
ffffffffc02018e6:	bf09                	j	ffffffffc02017f8 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc02018e8:	85a6                	mv	a1,s1
ffffffffc02018ea:	02d00513          	li	a0,45
ffffffffc02018ee:	e03e                	sd	a5,0(sp)
ffffffffc02018f0:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02018f2:	6782                	ld	a5,0(sp)
ffffffffc02018f4:	8a66                	mv	s4,s9
ffffffffc02018f6:	40800633          	neg	a2,s0
ffffffffc02018fa:	46a9                	li	a3,10
ffffffffc02018fc:	b53d                	j	ffffffffc020172a <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc02018fe:	03b05163          	blez	s11,ffffffffc0201920 <vprintfmt+0x34c>
ffffffffc0201902:	02d00693          	li	a3,45
ffffffffc0201906:	f6d79de3          	bne	a5,a3,ffffffffc0201880 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc020190a:	00001417          	auipc	s0,0x1
ffffffffc020190e:	28640413          	addi	s0,s0,646 # ffffffffc0202b90 <buddy_system_pmm_manager+0x390>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201912:	02800793          	li	a5,40
ffffffffc0201916:	02800513          	li	a0,40
ffffffffc020191a:	00140a13          	addi	s4,s0,1
ffffffffc020191e:	bd6d                	j	ffffffffc02017d8 <vprintfmt+0x204>
ffffffffc0201920:	00001a17          	auipc	s4,0x1
ffffffffc0201924:	271a0a13          	addi	s4,s4,625 # ffffffffc0202b91 <buddy_system_pmm_manager+0x391>
ffffffffc0201928:	02800513          	li	a0,40
ffffffffc020192c:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201930:	05e00413          	li	s0,94
ffffffffc0201934:	b565                	j	ffffffffc02017dc <vprintfmt+0x208>

ffffffffc0201936 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201936:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201938:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020193c:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020193e:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201940:	ec06                	sd	ra,24(sp)
ffffffffc0201942:	f83a                	sd	a4,48(sp)
ffffffffc0201944:	fc3e                	sd	a5,56(sp)
ffffffffc0201946:	e0c2                	sd	a6,64(sp)
ffffffffc0201948:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020194a:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020194c:	c89ff0ef          	jal	ra,ffffffffc02015d4 <vprintfmt>
}
ffffffffc0201950:	60e2                	ld	ra,24(sp)
ffffffffc0201952:	6161                	addi	sp,sp,80
ffffffffc0201954:	8082                	ret

ffffffffc0201956 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201956:	715d                	addi	sp,sp,-80
ffffffffc0201958:	e486                	sd	ra,72(sp)
ffffffffc020195a:	e0a6                	sd	s1,64(sp)
ffffffffc020195c:	fc4a                	sd	s2,56(sp)
ffffffffc020195e:	f84e                	sd	s3,48(sp)
ffffffffc0201960:	f452                	sd	s4,40(sp)
ffffffffc0201962:	f056                	sd	s5,32(sp)
ffffffffc0201964:	ec5a                	sd	s6,24(sp)
ffffffffc0201966:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc0201968:	c901                	beqz	a0,ffffffffc0201978 <readline+0x22>
ffffffffc020196a:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc020196c:	00001517          	auipc	a0,0x1
ffffffffc0201970:	23c50513          	addi	a0,a0,572 # ffffffffc0202ba8 <buddy_system_pmm_manager+0x3a8>
ffffffffc0201974:	f3efe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
readline(const char *prompt) {
ffffffffc0201978:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020197a:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc020197c:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc020197e:	4aa9                	li	s5,10
ffffffffc0201980:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0201982:	00004b97          	auipc	s7,0x4
ffffffffc0201986:	796b8b93          	addi	s7,s7,1942 # ffffffffc0206118 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020198a:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc020198e:	f9cfe0ef          	jal	ra,ffffffffc020012a <getchar>
        if (c < 0) {
ffffffffc0201992:	00054a63          	bltz	a0,ffffffffc02019a6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201996:	00a95a63          	bge	s2,a0,ffffffffc02019aa <readline+0x54>
ffffffffc020199a:	029a5263          	bge	s4,s1,ffffffffc02019be <readline+0x68>
        c = getchar();
ffffffffc020199e:	f8cfe0ef          	jal	ra,ffffffffc020012a <getchar>
        if (c < 0) {
ffffffffc02019a2:	fe055ae3          	bgez	a0,ffffffffc0201996 <readline+0x40>
            return NULL;
ffffffffc02019a6:	4501                	li	a0,0
ffffffffc02019a8:	a091                	j	ffffffffc02019ec <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02019aa:	03351463          	bne	a0,s3,ffffffffc02019d2 <readline+0x7c>
ffffffffc02019ae:	e8a9                	bnez	s1,ffffffffc0201a00 <readline+0xaa>
        c = getchar();
ffffffffc02019b0:	f7afe0ef          	jal	ra,ffffffffc020012a <getchar>
        if (c < 0) {
ffffffffc02019b4:	fe0549e3          	bltz	a0,ffffffffc02019a6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02019b8:	fea959e3          	bge	s2,a0,ffffffffc02019aa <readline+0x54>
ffffffffc02019bc:	4481                	li	s1,0
            cputchar(c);
ffffffffc02019be:	e42a                	sd	a0,8(sp)
ffffffffc02019c0:	f28fe0ef          	jal	ra,ffffffffc02000e8 <cputchar>
            buf[i ++] = c;
ffffffffc02019c4:	6522                	ld	a0,8(sp)
ffffffffc02019c6:	009b87b3          	add	a5,s7,s1
ffffffffc02019ca:	2485                	addiw	s1,s1,1
ffffffffc02019cc:	00a78023          	sb	a0,0(a5)
ffffffffc02019d0:	bf7d                	j	ffffffffc020198e <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc02019d2:	01550463          	beq	a0,s5,ffffffffc02019da <readline+0x84>
ffffffffc02019d6:	fb651ce3          	bne	a0,s6,ffffffffc020198e <readline+0x38>
            cputchar(c);
ffffffffc02019da:	f0efe0ef          	jal	ra,ffffffffc02000e8 <cputchar>
            buf[i] = '\0';
ffffffffc02019de:	00004517          	auipc	a0,0x4
ffffffffc02019e2:	73a50513          	addi	a0,a0,1850 # ffffffffc0206118 <buf>
ffffffffc02019e6:	94aa                	add	s1,s1,a0
ffffffffc02019e8:	00048023          	sb	zero,0(s1) # ffffffffc0200000 <kern_entry>
            return buf;
        }
    }
}
ffffffffc02019ec:	60a6                	ld	ra,72(sp)
ffffffffc02019ee:	6486                	ld	s1,64(sp)
ffffffffc02019f0:	7962                	ld	s2,56(sp)
ffffffffc02019f2:	79c2                	ld	s3,48(sp)
ffffffffc02019f4:	7a22                	ld	s4,40(sp)
ffffffffc02019f6:	7a82                	ld	s5,32(sp)
ffffffffc02019f8:	6b62                	ld	s6,24(sp)
ffffffffc02019fa:	6bc2                	ld	s7,16(sp)
ffffffffc02019fc:	6161                	addi	sp,sp,80
ffffffffc02019fe:	8082                	ret
            cputchar(c);
ffffffffc0201a00:	4521                	li	a0,8
ffffffffc0201a02:	ee6fe0ef          	jal	ra,ffffffffc02000e8 <cputchar>
            i --;
ffffffffc0201a06:	34fd                	addiw	s1,s1,-1
ffffffffc0201a08:	b759                	j	ffffffffc020198e <readline+0x38>

ffffffffc0201a0a <sbi_console_putchar>:
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2)
{
    uint64_t ret_val;
    __asm__ volatile(
ffffffffc0201a0a:	4781                	li	a5,0
ffffffffc0201a0c:	00004717          	auipc	a4,0x4
ffffffffc0201a10:	5fc73703          	ld	a4,1532(a4) # ffffffffc0206008 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201a14:	88ba                	mv	a7,a4
ffffffffc0201a16:	852a                	mv	a0,a0
ffffffffc0201a18:	85be                	mv	a1,a5
ffffffffc0201a1a:	863e                	mv	a2,a5
ffffffffc0201a1c:	00000073          	ecall
ffffffffc0201a20:	87aa                	mv	a5,a0
}

void sbi_console_putchar(unsigned char ch)
{
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201a22:	8082                	ret

ffffffffc0201a24 <sbi_set_timer>:
    __asm__ volatile(
ffffffffc0201a24:	4781                	li	a5,0
ffffffffc0201a26:	00005717          	auipc	a4,0x5
ffffffffc0201a2a:	b3a73703          	ld	a4,-1222(a4) # ffffffffc0206560 <SBI_SET_TIMER>
ffffffffc0201a2e:	88ba                	mv	a7,a4
ffffffffc0201a30:	852a                	mv	a0,a0
ffffffffc0201a32:	85be                	mv	a1,a5
ffffffffc0201a34:	863e                	mv	a2,a5
ffffffffc0201a36:	00000073          	ecall
ffffffffc0201a3a:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value)
{
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc0201a3c:	8082                	ret

ffffffffc0201a3e <sbi_console_getchar>:
    __asm__ volatile(
ffffffffc0201a3e:	4501                	li	a0,0
ffffffffc0201a40:	00004797          	auipc	a5,0x4
ffffffffc0201a44:	5c07b783          	ld	a5,1472(a5) # ffffffffc0206000 <SBI_CONSOLE_GETCHAR>
ffffffffc0201a48:	88be                	mv	a7,a5
ffffffffc0201a4a:	852a                	mv	a0,a0
ffffffffc0201a4c:	85aa                	mv	a1,a0
ffffffffc0201a4e:	862a                	mv	a2,a0
ffffffffc0201a50:	00000073          	ecall
ffffffffc0201a54:	852a                	mv	a0,a0

int sbi_console_getchar(void)
{
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
ffffffffc0201a56:	2501                	sext.w	a0,a0
ffffffffc0201a58:	8082                	ret

ffffffffc0201a5a <sbi_shutdown>:
    __asm__ volatile(
ffffffffc0201a5a:	4781                	li	a5,0
ffffffffc0201a5c:	00004717          	auipc	a4,0x4
ffffffffc0201a60:	5b473703          	ld	a4,1460(a4) # ffffffffc0206010 <SBI_SHUTDOWN>
ffffffffc0201a64:	88ba                	mv	a7,a4
ffffffffc0201a66:	853e                	mv	a0,a5
ffffffffc0201a68:	85be                	mv	a1,a5
ffffffffc0201a6a:	863e                	mv	a2,a5
ffffffffc0201a6c:	00000073          	ecall
ffffffffc0201a70:	87aa                	mv	a5,a0

void sbi_shutdown(void)
{
    sbi_call(SBI_SHUTDOWN, 0, 0, 0);
ffffffffc0201a72:	8082                	ret

ffffffffc0201a74 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201a74:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201a76:	e589                	bnez	a1,ffffffffc0201a80 <strnlen+0xc>
ffffffffc0201a78:	a811                	j	ffffffffc0201a8c <strnlen+0x18>
        cnt ++;
ffffffffc0201a7a:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201a7c:	00f58863          	beq	a1,a5,ffffffffc0201a8c <strnlen+0x18>
ffffffffc0201a80:	00f50733          	add	a4,a0,a5
ffffffffc0201a84:	00074703          	lbu	a4,0(a4)
ffffffffc0201a88:	fb6d                	bnez	a4,ffffffffc0201a7a <strnlen+0x6>
ffffffffc0201a8a:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201a8c:	852e                	mv	a0,a1
ffffffffc0201a8e:	8082                	ret

ffffffffc0201a90 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201a90:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201a94:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201a98:	cb89                	beqz	a5,ffffffffc0201aaa <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201a9a:	0505                	addi	a0,a0,1
ffffffffc0201a9c:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201a9e:	fee789e3          	beq	a5,a4,ffffffffc0201a90 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201aa2:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201aa6:	9d19                	subw	a0,a0,a4
ffffffffc0201aa8:	8082                	ret
ffffffffc0201aaa:	4501                	li	a0,0
ffffffffc0201aac:	bfed                	j	ffffffffc0201aa6 <strcmp+0x16>

ffffffffc0201aae <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201aae:	00054783          	lbu	a5,0(a0)
ffffffffc0201ab2:	c799                	beqz	a5,ffffffffc0201ac0 <strchr+0x12>
        if (*s == c) {
ffffffffc0201ab4:	00f58763          	beq	a1,a5,ffffffffc0201ac2 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0201ab8:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0201abc:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201abe:	fbfd                	bnez	a5,ffffffffc0201ab4 <strchr+0x6>
    }
    return NULL;
ffffffffc0201ac0:	4501                	li	a0,0
}
ffffffffc0201ac2:	8082                	ret

ffffffffc0201ac4 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201ac4:	ca01                	beqz	a2,ffffffffc0201ad4 <memset+0x10>
ffffffffc0201ac6:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201ac8:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201aca:	0785                	addi	a5,a5,1
ffffffffc0201acc:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201ad0:	fec79de3          	bne	a5,a2,ffffffffc0201aca <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201ad4:	8082                	ret
