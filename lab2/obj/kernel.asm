
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c02052b7          	lui	t0,0xc0205
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc0200004:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200008:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc020000a:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc020000e:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc0200012:	fff0031b          	addiw	t1,zero,-1
ffffffffc0200016:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200018:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc020001c:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200020:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
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
ffffffffc0200036:	ff650513          	addi	a0,a0,-10 # ffffffffc0206028 <free_area>
ffffffffc020003a:	00006617          	auipc	a2,0x6
ffffffffc020003e:	45660613          	addi	a2,a2,1110 # ffffffffc0206490 <end>
int kern_init(void) {
ffffffffc0200042:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200044:	8e09                	sub	a2,a2,a0
ffffffffc0200046:	4581                	li	a1,0
int kern_init(void) {
ffffffffc0200048:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004a:	44b010ef          	jal	ra,ffffffffc0201c94 <memset>
    cons_init();  // init the console
ffffffffc020004e:	404000ef          	jal	ra,ffffffffc0200452 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200052:	00002517          	auipc	a0,0x2
ffffffffc0200056:	c5650513          	addi	a0,a0,-938 # ffffffffc0201ca8 <etext+0x2>
ffffffffc020005a:	098000ef          	jal	ra,ffffffffc02000f2 <cputs>

    print_kerninfo();
ffffffffc020005e:	0e4000ef          	jal	ra,ffffffffc0200142 <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200062:	40a000ef          	jal	ra,ffffffffc020046c <idt_init>

    pmm_init();  // init physical memory management
ffffffffc0200066:	268010ef          	jal	ra,ffffffffc02012ce <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc020006a:	402000ef          	jal	ra,ffffffffc020046c <idt_init>

    clock_init();   // init clock interrupt
ffffffffc020006e:	3a2000ef          	jal	ra,ffffffffc0200410 <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc0200072:	3ee000ef          	jal	ra,ffffffffc0200460 <intr_enable>

    slub_init();
ffffffffc0200076:	584010ef          	jal	ra,ffffffffc02015fa <slub_init>
    slub_check();
ffffffffc020007a:	5e0010ef          	jal	ra,ffffffffc020165a <slub_check>
    /* do nothing */
    while (1)
ffffffffc020007e:	a001                	j	ffffffffc020007e <kern_init+0x4c>

ffffffffc0200080 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200080:	1141                	addi	sp,sp,-16
ffffffffc0200082:	e022                	sd	s0,0(sp)
ffffffffc0200084:	e406                	sd	ra,8(sp)
ffffffffc0200086:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200088:	3cc000ef          	jal	ra,ffffffffc0200454 <cons_putc>
    (*cnt) ++;
ffffffffc020008c:	401c                	lw	a5,0(s0)
}
ffffffffc020008e:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200090:	2785                	addiw	a5,a5,1
ffffffffc0200092:	c01c                	sw	a5,0(s0)
}
ffffffffc0200094:	6402                	ld	s0,0(sp)
ffffffffc0200096:	0141                	addi	sp,sp,16
ffffffffc0200098:	8082                	ret

ffffffffc020009a <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020009a:	1101                	addi	sp,sp,-32
ffffffffc020009c:	862a                	mv	a2,a0
ffffffffc020009e:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000a0:	00000517          	auipc	a0,0x0
ffffffffc02000a4:	fe050513          	addi	a0,a0,-32 # ffffffffc0200080 <cputch>
ffffffffc02000a8:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000aa:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000ac:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000ae:	710010ef          	jal	ra,ffffffffc02017be <vprintfmt>
    return cnt;
}
ffffffffc02000b2:	60e2                	ld	ra,24(sp)
ffffffffc02000b4:	4532                	lw	a0,12(sp)
ffffffffc02000b6:	6105                	addi	sp,sp,32
ffffffffc02000b8:	8082                	ret

ffffffffc02000ba <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000ba:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000bc:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000c0:	8e2a                	mv	t3,a0
ffffffffc02000c2:	f42e                	sd	a1,40(sp)
ffffffffc02000c4:	f832                	sd	a2,48(sp)
ffffffffc02000c6:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000c8:	00000517          	auipc	a0,0x0
ffffffffc02000cc:	fb850513          	addi	a0,a0,-72 # ffffffffc0200080 <cputch>
ffffffffc02000d0:	004c                	addi	a1,sp,4
ffffffffc02000d2:	869a                	mv	a3,t1
ffffffffc02000d4:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc02000d6:	ec06                	sd	ra,24(sp)
ffffffffc02000d8:	e0ba                	sd	a4,64(sp)
ffffffffc02000da:	e4be                	sd	a5,72(sp)
ffffffffc02000dc:	e8c2                	sd	a6,80(sp)
ffffffffc02000de:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000e0:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000e2:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000e4:	6da010ef          	jal	ra,ffffffffc02017be <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02000e8:	60e2                	ld	ra,24(sp)
ffffffffc02000ea:	4512                	lw	a0,4(sp)
ffffffffc02000ec:	6125                	addi	sp,sp,96
ffffffffc02000ee:	8082                	ret

ffffffffc02000f0 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02000f0:	a695                	j	ffffffffc0200454 <cons_putc>

ffffffffc02000f2 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc02000f2:	1101                	addi	sp,sp,-32
ffffffffc02000f4:	e822                	sd	s0,16(sp)
ffffffffc02000f6:	ec06                	sd	ra,24(sp)
ffffffffc02000f8:	e426                	sd	s1,8(sp)
ffffffffc02000fa:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc02000fc:	00054503          	lbu	a0,0(a0)
ffffffffc0200100:	c51d                	beqz	a0,ffffffffc020012e <cputs+0x3c>
ffffffffc0200102:	0405                	addi	s0,s0,1
ffffffffc0200104:	4485                	li	s1,1
ffffffffc0200106:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200108:	34c000ef          	jal	ra,ffffffffc0200454 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020010c:	00044503          	lbu	a0,0(s0)
ffffffffc0200110:	008487bb          	addw	a5,s1,s0
ffffffffc0200114:	0405                	addi	s0,s0,1
ffffffffc0200116:	f96d                	bnez	a0,ffffffffc0200108 <cputs+0x16>
    (*cnt) ++;
ffffffffc0200118:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc020011c:	4529                	li	a0,10
ffffffffc020011e:	336000ef          	jal	ra,ffffffffc0200454 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc0200122:	60e2                	ld	ra,24(sp)
ffffffffc0200124:	8522                	mv	a0,s0
ffffffffc0200126:	6442                	ld	s0,16(sp)
ffffffffc0200128:	64a2                	ld	s1,8(sp)
ffffffffc020012a:	6105                	addi	sp,sp,32
ffffffffc020012c:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc020012e:	4405                	li	s0,1
ffffffffc0200130:	b7f5                	j	ffffffffc020011c <cputs+0x2a>

ffffffffc0200132 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc0200132:	1141                	addi	sp,sp,-16
ffffffffc0200134:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200136:	326000ef          	jal	ra,ffffffffc020045c <cons_getc>
ffffffffc020013a:	dd75                	beqz	a0,ffffffffc0200136 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc020013c:	60a2                	ld	ra,8(sp)
ffffffffc020013e:	0141                	addi	sp,sp,16
ffffffffc0200140:	8082                	ret

ffffffffc0200142 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200142:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200144:	00002517          	auipc	a0,0x2
ffffffffc0200148:	b8450513          	addi	a0,a0,-1148 # ffffffffc0201cc8 <etext+0x22>
void print_kerninfo(void) {
ffffffffc020014c:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc020014e:	f6dff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc0200152:	00000597          	auipc	a1,0x0
ffffffffc0200156:	ee058593          	addi	a1,a1,-288 # ffffffffc0200032 <kern_init>
ffffffffc020015a:	00002517          	auipc	a0,0x2
ffffffffc020015e:	b8e50513          	addi	a0,a0,-1138 # ffffffffc0201ce8 <etext+0x42>
ffffffffc0200162:	f59ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc0200166:	00002597          	auipc	a1,0x2
ffffffffc020016a:	b4058593          	addi	a1,a1,-1216 # ffffffffc0201ca6 <etext>
ffffffffc020016e:	00002517          	auipc	a0,0x2
ffffffffc0200172:	b9a50513          	addi	a0,a0,-1126 # ffffffffc0201d08 <etext+0x62>
ffffffffc0200176:	f45ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc020017a:	00006597          	auipc	a1,0x6
ffffffffc020017e:	eae58593          	addi	a1,a1,-338 # ffffffffc0206028 <free_area>
ffffffffc0200182:	00002517          	auipc	a0,0x2
ffffffffc0200186:	ba650513          	addi	a0,a0,-1114 # ffffffffc0201d28 <etext+0x82>
ffffffffc020018a:	f31ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc020018e:	00006597          	auipc	a1,0x6
ffffffffc0200192:	30258593          	addi	a1,a1,770 # ffffffffc0206490 <end>
ffffffffc0200196:	00002517          	auipc	a0,0x2
ffffffffc020019a:	bb250513          	addi	a0,a0,-1102 # ffffffffc0201d48 <etext+0xa2>
ffffffffc020019e:	f1dff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc02001a2:	00006597          	auipc	a1,0x6
ffffffffc02001a6:	6ed58593          	addi	a1,a1,1773 # ffffffffc020688f <end+0x3ff>
ffffffffc02001aa:	00000797          	auipc	a5,0x0
ffffffffc02001ae:	e8878793          	addi	a5,a5,-376 # ffffffffc0200032 <kern_init>
ffffffffc02001b2:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001b6:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001ba:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001bc:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001c0:	95be                	add	a1,a1,a5
ffffffffc02001c2:	85a9                	srai	a1,a1,0xa
ffffffffc02001c4:	00002517          	auipc	a0,0x2
ffffffffc02001c8:	ba450513          	addi	a0,a0,-1116 # ffffffffc0201d68 <etext+0xc2>
}
ffffffffc02001cc:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001ce:	b5f5                	j	ffffffffc02000ba <cprintf>

ffffffffc02001d0 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001d0:	1141                	addi	sp,sp,-16

    panic("Not Implemented!");
ffffffffc02001d2:	00002617          	auipc	a2,0x2
ffffffffc02001d6:	bc660613          	addi	a2,a2,-1082 # ffffffffc0201d98 <etext+0xf2>
ffffffffc02001da:	04e00593          	li	a1,78
ffffffffc02001de:	00002517          	auipc	a0,0x2
ffffffffc02001e2:	bd250513          	addi	a0,a0,-1070 # ffffffffc0201db0 <etext+0x10a>
void print_stackframe(void) {
ffffffffc02001e6:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02001e8:	1cc000ef          	jal	ra,ffffffffc02003b4 <__panic>

ffffffffc02001ec <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02001ec:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02001ee:	00002617          	auipc	a2,0x2
ffffffffc02001f2:	bda60613          	addi	a2,a2,-1062 # ffffffffc0201dc8 <etext+0x122>
ffffffffc02001f6:	00002597          	auipc	a1,0x2
ffffffffc02001fa:	bf258593          	addi	a1,a1,-1038 # ffffffffc0201de8 <etext+0x142>
ffffffffc02001fe:	00002517          	auipc	a0,0x2
ffffffffc0200202:	bf250513          	addi	a0,a0,-1038 # ffffffffc0201df0 <etext+0x14a>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200206:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200208:	eb3ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc020020c:	00002617          	auipc	a2,0x2
ffffffffc0200210:	bf460613          	addi	a2,a2,-1036 # ffffffffc0201e00 <etext+0x15a>
ffffffffc0200214:	00002597          	auipc	a1,0x2
ffffffffc0200218:	c1458593          	addi	a1,a1,-1004 # ffffffffc0201e28 <etext+0x182>
ffffffffc020021c:	00002517          	auipc	a0,0x2
ffffffffc0200220:	bd450513          	addi	a0,a0,-1068 # ffffffffc0201df0 <etext+0x14a>
ffffffffc0200224:	e97ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc0200228:	00002617          	auipc	a2,0x2
ffffffffc020022c:	c1060613          	addi	a2,a2,-1008 # ffffffffc0201e38 <etext+0x192>
ffffffffc0200230:	00002597          	auipc	a1,0x2
ffffffffc0200234:	c2858593          	addi	a1,a1,-984 # ffffffffc0201e58 <etext+0x1b2>
ffffffffc0200238:	00002517          	auipc	a0,0x2
ffffffffc020023c:	bb850513          	addi	a0,a0,-1096 # ffffffffc0201df0 <etext+0x14a>
ffffffffc0200240:	e7bff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    }
    return 0;
}
ffffffffc0200244:	60a2                	ld	ra,8(sp)
ffffffffc0200246:	4501                	li	a0,0
ffffffffc0200248:	0141                	addi	sp,sp,16
ffffffffc020024a:	8082                	ret

ffffffffc020024c <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc020024c:	1141                	addi	sp,sp,-16
ffffffffc020024e:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200250:	ef3ff0ef          	jal	ra,ffffffffc0200142 <print_kerninfo>
    return 0;
}
ffffffffc0200254:	60a2                	ld	ra,8(sp)
ffffffffc0200256:	4501                	li	a0,0
ffffffffc0200258:	0141                	addi	sp,sp,16
ffffffffc020025a:	8082                	ret

ffffffffc020025c <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc020025c:	1141                	addi	sp,sp,-16
ffffffffc020025e:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200260:	f71ff0ef          	jal	ra,ffffffffc02001d0 <print_stackframe>
    return 0;
}
ffffffffc0200264:	60a2                	ld	ra,8(sp)
ffffffffc0200266:	4501                	li	a0,0
ffffffffc0200268:	0141                	addi	sp,sp,16
ffffffffc020026a:	8082                	ret

ffffffffc020026c <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc020026c:	7115                	addi	sp,sp,-224
ffffffffc020026e:	ed5e                	sd	s7,152(sp)
ffffffffc0200270:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200272:	00002517          	auipc	a0,0x2
ffffffffc0200276:	bf650513          	addi	a0,a0,-1034 # ffffffffc0201e68 <etext+0x1c2>
kmonitor(struct trapframe *tf) {
ffffffffc020027a:	ed86                	sd	ra,216(sp)
ffffffffc020027c:	e9a2                	sd	s0,208(sp)
ffffffffc020027e:	e5a6                	sd	s1,200(sp)
ffffffffc0200280:	e1ca                	sd	s2,192(sp)
ffffffffc0200282:	fd4e                	sd	s3,184(sp)
ffffffffc0200284:	f952                	sd	s4,176(sp)
ffffffffc0200286:	f556                	sd	s5,168(sp)
ffffffffc0200288:	f15a                	sd	s6,160(sp)
ffffffffc020028a:	e962                	sd	s8,144(sp)
ffffffffc020028c:	e566                	sd	s9,136(sp)
ffffffffc020028e:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200290:	e2bff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200294:	00002517          	auipc	a0,0x2
ffffffffc0200298:	bfc50513          	addi	a0,a0,-1028 # ffffffffc0201e90 <etext+0x1ea>
ffffffffc020029c:	e1fff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    if (tf != NULL) {
ffffffffc02002a0:	000b8563          	beqz	s7,ffffffffc02002aa <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002a4:	855e                	mv	a0,s7
ffffffffc02002a6:	3a4000ef          	jal	ra,ffffffffc020064a <print_trapframe>
ffffffffc02002aa:	00002c17          	auipc	s8,0x2
ffffffffc02002ae:	c56c0c13          	addi	s8,s8,-938 # ffffffffc0201f00 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002b2:	00002917          	auipc	s2,0x2
ffffffffc02002b6:	c0690913          	addi	s2,s2,-1018 # ffffffffc0201eb8 <etext+0x212>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002ba:	00002497          	auipc	s1,0x2
ffffffffc02002be:	c0648493          	addi	s1,s1,-1018 # ffffffffc0201ec0 <etext+0x21a>
        if (argc == MAXARGS - 1) {
ffffffffc02002c2:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002c4:	00002b17          	auipc	s6,0x2
ffffffffc02002c8:	c04b0b13          	addi	s6,s6,-1020 # ffffffffc0201ec8 <etext+0x222>
        argv[argc ++] = buf;
ffffffffc02002cc:	00002a17          	auipc	s4,0x2
ffffffffc02002d0:	b1ca0a13          	addi	s4,s4,-1252 # ffffffffc0201de8 <etext+0x142>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002d4:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002d6:	854a                	mv	a0,s2
ffffffffc02002d8:	069010ef          	jal	ra,ffffffffc0201b40 <readline>
ffffffffc02002dc:	842a                	mv	s0,a0
ffffffffc02002de:	dd65                	beqz	a0,ffffffffc02002d6 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002e0:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02002e4:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002e6:	e1bd                	bnez	a1,ffffffffc020034c <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc02002e8:	fe0c87e3          	beqz	s9,ffffffffc02002d6 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002ec:	6582                	ld	a1,0(sp)
ffffffffc02002ee:	00002d17          	auipc	s10,0x2
ffffffffc02002f2:	c12d0d13          	addi	s10,s10,-1006 # ffffffffc0201f00 <commands>
        argv[argc ++] = buf;
ffffffffc02002f6:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002f8:	4401                	li	s0,0
ffffffffc02002fa:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002fc:	165010ef          	jal	ra,ffffffffc0201c60 <strcmp>
ffffffffc0200300:	c919                	beqz	a0,ffffffffc0200316 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200302:	2405                	addiw	s0,s0,1
ffffffffc0200304:	0b540063          	beq	s0,s5,ffffffffc02003a4 <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200308:	000d3503          	ld	a0,0(s10)
ffffffffc020030c:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020030e:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200310:	151010ef          	jal	ra,ffffffffc0201c60 <strcmp>
ffffffffc0200314:	f57d                	bnez	a0,ffffffffc0200302 <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200316:	00141793          	slli	a5,s0,0x1
ffffffffc020031a:	97a2                	add	a5,a5,s0
ffffffffc020031c:	078e                	slli	a5,a5,0x3
ffffffffc020031e:	97e2                	add	a5,a5,s8
ffffffffc0200320:	6b9c                	ld	a5,16(a5)
ffffffffc0200322:	865e                	mv	a2,s7
ffffffffc0200324:	002c                	addi	a1,sp,8
ffffffffc0200326:	fffc851b          	addiw	a0,s9,-1
ffffffffc020032a:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc020032c:	fa0555e3          	bgez	a0,ffffffffc02002d6 <kmonitor+0x6a>
}
ffffffffc0200330:	60ee                	ld	ra,216(sp)
ffffffffc0200332:	644e                	ld	s0,208(sp)
ffffffffc0200334:	64ae                	ld	s1,200(sp)
ffffffffc0200336:	690e                	ld	s2,192(sp)
ffffffffc0200338:	79ea                	ld	s3,184(sp)
ffffffffc020033a:	7a4a                	ld	s4,176(sp)
ffffffffc020033c:	7aaa                	ld	s5,168(sp)
ffffffffc020033e:	7b0a                	ld	s6,160(sp)
ffffffffc0200340:	6bea                	ld	s7,152(sp)
ffffffffc0200342:	6c4a                	ld	s8,144(sp)
ffffffffc0200344:	6caa                	ld	s9,136(sp)
ffffffffc0200346:	6d0a                	ld	s10,128(sp)
ffffffffc0200348:	612d                	addi	sp,sp,224
ffffffffc020034a:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020034c:	8526                	mv	a0,s1
ffffffffc020034e:	131010ef          	jal	ra,ffffffffc0201c7e <strchr>
ffffffffc0200352:	c901                	beqz	a0,ffffffffc0200362 <kmonitor+0xf6>
ffffffffc0200354:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200358:	00040023          	sb	zero,0(s0)
ffffffffc020035c:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020035e:	d5c9                	beqz	a1,ffffffffc02002e8 <kmonitor+0x7c>
ffffffffc0200360:	b7f5                	j	ffffffffc020034c <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc0200362:	00044783          	lbu	a5,0(s0)
ffffffffc0200366:	d3c9                	beqz	a5,ffffffffc02002e8 <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc0200368:	033c8963          	beq	s9,s3,ffffffffc020039a <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc020036c:	003c9793          	slli	a5,s9,0x3
ffffffffc0200370:	0118                	addi	a4,sp,128
ffffffffc0200372:	97ba                	add	a5,a5,a4
ffffffffc0200374:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200378:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc020037c:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020037e:	e591                	bnez	a1,ffffffffc020038a <kmonitor+0x11e>
ffffffffc0200380:	b7b5                	j	ffffffffc02002ec <kmonitor+0x80>
ffffffffc0200382:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc0200386:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200388:	d1a5                	beqz	a1,ffffffffc02002e8 <kmonitor+0x7c>
ffffffffc020038a:	8526                	mv	a0,s1
ffffffffc020038c:	0f3010ef          	jal	ra,ffffffffc0201c7e <strchr>
ffffffffc0200390:	d96d                	beqz	a0,ffffffffc0200382 <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200392:	00044583          	lbu	a1,0(s0)
ffffffffc0200396:	d9a9                	beqz	a1,ffffffffc02002e8 <kmonitor+0x7c>
ffffffffc0200398:	bf55                	j	ffffffffc020034c <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020039a:	45c1                	li	a1,16
ffffffffc020039c:	855a                	mv	a0,s6
ffffffffc020039e:	d1dff0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc02003a2:	b7e9                	j	ffffffffc020036c <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02003a4:	6582                	ld	a1,0(sp)
ffffffffc02003a6:	00002517          	auipc	a0,0x2
ffffffffc02003aa:	b4250513          	addi	a0,a0,-1214 # ffffffffc0201ee8 <etext+0x242>
ffffffffc02003ae:	d0dff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    return 0;
ffffffffc02003b2:	b715                	j	ffffffffc02002d6 <kmonitor+0x6a>

ffffffffc02003b4 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02003b4:	00006317          	auipc	t1,0x6
ffffffffc02003b8:	08c30313          	addi	t1,t1,140 # ffffffffc0206440 <is_panic>
ffffffffc02003bc:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02003c0:	715d                	addi	sp,sp,-80
ffffffffc02003c2:	ec06                	sd	ra,24(sp)
ffffffffc02003c4:	e822                	sd	s0,16(sp)
ffffffffc02003c6:	f436                	sd	a3,40(sp)
ffffffffc02003c8:	f83a                	sd	a4,48(sp)
ffffffffc02003ca:	fc3e                	sd	a5,56(sp)
ffffffffc02003cc:	e0c2                	sd	a6,64(sp)
ffffffffc02003ce:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02003d0:	020e1a63          	bnez	t3,ffffffffc0200404 <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02003d4:	4785                	li	a5,1
ffffffffc02003d6:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02003da:	8432                	mv	s0,a2
ffffffffc02003dc:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003de:	862e                	mv	a2,a1
ffffffffc02003e0:	85aa                	mv	a1,a0
ffffffffc02003e2:	00002517          	auipc	a0,0x2
ffffffffc02003e6:	b6650513          	addi	a0,a0,-1178 # ffffffffc0201f48 <commands+0x48>
    va_start(ap, fmt);
ffffffffc02003ea:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003ec:	ccfff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    vcprintf(fmt, ap);
ffffffffc02003f0:	65a2                	ld	a1,8(sp)
ffffffffc02003f2:	8522                	mv	a0,s0
ffffffffc02003f4:	ca7ff0ef          	jal	ra,ffffffffc020009a <vcprintf>
    cprintf("\n");
ffffffffc02003f8:	00002517          	auipc	a0,0x2
ffffffffc02003fc:	99850513          	addi	a0,a0,-1640 # ffffffffc0201d90 <etext+0xea>
ffffffffc0200400:	cbbff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc0200404:	062000ef          	jal	ra,ffffffffc0200466 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200408:	4501                	li	a0,0
ffffffffc020040a:	e63ff0ef          	jal	ra,ffffffffc020026c <kmonitor>
    while (1) {
ffffffffc020040e:	bfed                	j	ffffffffc0200408 <__panic+0x54>

ffffffffc0200410 <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc0200410:	1141                	addi	sp,sp,-16
ffffffffc0200412:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc0200414:	02000793          	li	a5,32
ffffffffc0200418:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020041c:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200420:	67e1                	lui	a5,0x18
ffffffffc0200422:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200426:	953e                	add	a0,a0,a5
ffffffffc0200428:	7e6010ef          	jal	ra,ffffffffc0201c0e <sbi_set_timer>
}
ffffffffc020042c:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc020042e:	00006797          	auipc	a5,0x6
ffffffffc0200432:	0007bd23          	sd	zero,26(a5) # ffffffffc0206448 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200436:	00002517          	auipc	a0,0x2
ffffffffc020043a:	b3250513          	addi	a0,a0,-1230 # ffffffffc0201f68 <commands+0x68>
}
ffffffffc020043e:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc0200440:	b9ad                	j	ffffffffc02000ba <cprintf>

ffffffffc0200442 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200442:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200446:	67e1                	lui	a5,0x18
ffffffffc0200448:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020044c:	953e                	add	a0,a0,a5
ffffffffc020044e:	7c00106f          	j	ffffffffc0201c0e <sbi_set_timer>

ffffffffc0200452 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200452:	8082                	ret

ffffffffc0200454 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200454:	0ff57513          	zext.b	a0,a0
ffffffffc0200458:	79c0106f          	j	ffffffffc0201bf4 <sbi_console_putchar>

ffffffffc020045c <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc020045c:	7cc0106f          	j	ffffffffc0201c28 <sbi_console_getchar>

ffffffffc0200460 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200460:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200464:	8082                	ret

ffffffffc0200466 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200466:	100177f3          	csrrci	a5,sstatus,2
ffffffffc020046a:	8082                	ret

ffffffffc020046c <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020046c:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200470:	00000797          	auipc	a5,0x0
ffffffffc0200474:	2e478793          	addi	a5,a5,740 # ffffffffc0200754 <__alltraps>
ffffffffc0200478:	10579073          	csrw	stvec,a5
}
ffffffffc020047c:	8082                	ret

ffffffffc020047e <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020047e:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc0200480:	1141                	addi	sp,sp,-16
ffffffffc0200482:	e022                	sd	s0,0(sp)
ffffffffc0200484:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200486:	00002517          	auipc	a0,0x2
ffffffffc020048a:	b0250513          	addi	a0,a0,-1278 # ffffffffc0201f88 <commands+0x88>
void print_regs(struct pushregs *gpr) {
ffffffffc020048e:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200490:	c2bff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200494:	640c                	ld	a1,8(s0)
ffffffffc0200496:	00002517          	auipc	a0,0x2
ffffffffc020049a:	b0a50513          	addi	a0,a0,-1270 # ffffffffc0201fa0 <commands+0xa0>
ffffffffc020049e:	c1dff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02004a2:	680c                	ld	a1,16(s0)
ffffffffc02004a4:	00002517          	auipc	a0,0x2
ffffffffc02004a8:	b1450513          	addi	a0,a0,-1260 # ffffffffc0201fb8 <commands+0xb8>
ffffffffc02004ac:	c0fff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02004b0:	6c0c                	ld	a1,24(s0)
ffffffffc02004b2:	00002517          	auipc	a0,0x2
ffffffffc02004b6:	b1e50513          	addi	a0,a0,-1250 # ffffffffc0201fd0 <commands+0xd0>
ffffffffc02004ba:	c01ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02004be:	700c                	ld	a1,32(s0)
ffffffffc02004c0:	00002517          	auipc	a0,0x2
ffffffffc02004c4:	b2850513          	addi	a0,a0,-1240 # ffffffffc0201fe8 <commands+0xe8>
ffffffffc02004c8:	bf3ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02004cc:	740c                	ld	a1,40(s0)
ffffffffc02004ce:	00002517          	auipc	a0,0x2
ffffffffc02004d2:	b3250513          	addi	a0,a0,-1230 # ffffffffc0202000 <commands+0x100>
ffffffffc02004d6:	be5ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02004da:	780c                	ld	a1,48(s0)
ffffffffc02004dc:	00002517          	auipc	a0,0x2
ffffffffc02004e0:	b3c50513          	addi	a0,a0,-1220 # ffffffffc0202018 <commands+0x118>
ffffffffc02004e4:	bd7ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02004e8:	7c0c                	ld	a1,56(s0)
ffffffffc02004ea:	00002517          	auipc	a0,0x2
ffffffffc02004ee:	b4650513          	addi	a0,a0,-1210 # ffffffffc0202030 <commands+0x130>
ffffffffc02004f2:	bc9ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02004f6:	602c                	ld	a1,64(s0)
ffffffffc02004f8:	00002517          	auipc	a0,0x2
ffffffffc02004fc:	b5050513          	addi	a0,a0,-1200 # ffffffffc0202048 <commands+0x148>
ffffffffc0200500:	bbbff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200504:	642c                	ld	a1,72(s0)
ffffffffc0200506:	00002517          	auipc	a0,0x2
ffffffffc020050a:	b5a50513          	addi	a0,a0,-1190 # ffffffffc0202060 <commands+0x160>
ffffffffc020050e:	badff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200512:	682c                	ld	a1,80(s0)
ffffffffc0200514:	00002517          	auipc	a0,0x2
ffffffffc0200518:	b6450513          	addi	a0,a0,-1180 # ffffffffc0202078 <commands+0x178>
ffffffffc020051c:	b9fff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200520:	6c2c                	ld	a1,88(s0)
ffffffffc0200522:	00002517          	auipc	a0,0x2
ffffffffc0200526:	b6e50513          	addi	a0,a0,-1170 # ffffffffc0202090 <commands+0x190>
ffffffffc020052a:	b91ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc020052e:	702c                	ld	a1,96(s0)
ffffffffc0200530:	00002517          	auipc	a0,0x2
ffffffffc0200534:	b7850513          	addi	a0,a0,-1160 # ffffffffc02020a8 <commands+0x1a8>
ffffffffc0200538:	b83ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020053c:	742c                	ld	a1,104(s0)
ffffffffc020053e:	00002517          	auipc	a0,0x2
ffffffffc0200542:	b8250513          	addi	a0,a0,-1150 # ffffffffc02020c0 <commands+0x1c0>
ffffffffc0200546:	b75ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc020054a:	782c                	ld	a1,112(s0)
ffffffffc020054c:	00002517          	auipc	a0,0x2
ffffffffc0200550:	b8c50513          	addi	a0,a0,-1140 # ffffffffc02020d8 <commands+0x1d8>
ffffffffc0200554:	b67ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200558:	7c2c                	ld	a1,120(s0)
ffffffffc020055a:	00002517          	auipc	a0,0x2
ffffffffc020055e:	b9650513          	addi	a0,a0,-1130 # ffffffffc02020f0 <commands+0x1f0>
ffffffffc0200562:	b59ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200566:	604c                	ld	a1,128(s0)
ffffffffc0200568:	00002517          	auipc	a0,0x2
ffffffffc020056c:	ba050513          	addi	a0,a0,-1120 # ffffffffc0202108 <commands+0x208>
ffffffffc0200570:	b4bff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200574:	644c                	ld	a1,136(s0)
ffffffffc0200576:	00002517          	auipc	a0,0x2
ffffffffc020057a:	baa50513          	addi	a0,a0,-1110 # ffffffffc0202120 <commands+0x220>
ffffffffc020057e:	b3dff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200582:	684c                	ld	a1,144(s0)
ffffffffc0200584:	00002517          	auipc	a0,0x2
ffffffffc0200588:	bb450513          	addi	a0,a0,-1100 # ffffffffc0202138 <commands+0x238>
ffffffffc020058c:	b2fff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200590:	6c4c                	ld	a1,152(s0)
ffffffffc0200592:	00002517          	auipc	a0,0x2
ffffffffc0200596:	bbe50513          	addi	a0,a0,-1090 # ffffffffc0202150 <commands+0x250>
ffffffffc020059a:	b21ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc020059e:	704c                	ld	a1,160(s0)
ffffffffc02005a0:	00002517          	auipc	a0,0x2
ffffffffc02005a4:	bc850513          	addi	a0,a0,-1080 # ffffffffc0202168 <commands+0x268>
ffffffffc02005a8:	b13ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02005ac:	744c                	ld	a1,168(s0)
ffffffffc02005ae:	00002517          	auipc	a0,0x2
ffffffffc02005b2:	bd250513          	addi	a0,a0,-1070 # ffffffffc0202180 <commands+0x280>
ffffffffc02005b6:	b05ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02005ba:	784c                	ld	a1,176(s0)
ffffffffc02005bc:	00002517          	auipc	a0,0x2
ffffffffc02005c0:	bdc50513          	addi	a0,a0,-1060 # ffffffffc0202198 <commands+0x298>
ffffffffc02005c4:	af7ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02005c8:	7c4c                	ld	a1,184(s0)
ffffffffc02005ca:	00002517          	auipc	a0,0x2
ffffffffc02005ce:	be650513          	addi	a0,a0,-1050 # ffffffffc02021b0 <commands+0x2b0>
ffffffffc02005d2:	ae9ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02005d6:	606c                	ld	a1,192(s0)
ffffffffc02005d8:	00002517          	auipc	a0,0x2
ffffffffc02005dc:	bf050513          	addi	a0,a0,-1040 # ffffffffc02021c8 <commands+0x2c8>
ffffffffc02005e0:	adbff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02005e4:	646c                	ld	a1,200(s0)
ffffffffc02005e6:	00002517          	auipc	a0,0x2
ffffffffc02005ea:	bfa50513          	addi	a0,a0,-1030 # ffffffffc02021e0 <commands+0x2e0>
ffffffffc02005ee:	acdff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02005f2:	686c                	ld	a1,208(s0)
ffffffffc02005f4:	00002517          	auipc	a0,0x2
ffffffffc02005f8:	c0450513          	addi	a0,a0,-1020 # ffffffffc02021f8 <commands+0x2f8>
ffffffffc02005fc:	abfff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200600:	6c6c                	ld	a1,216(s0)
ffffffffc0200602:	00002517          	auipc	a0,0x2
ffffffffc0200606:	c0e50513          	addi	a0,a0,-1010 # ffffffffc0202210 <commands+0x310>
ffffffffc020060a:	ab1ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc020060e:	706c                	ld	a1,224(s0)
ffffffffc0200610:	00002517          	auipc	a0,0x2
ffffffffc0200614:	c1850513          	addi	a0,a0,-1000 # ffffffffc0202228 <commands+0x328>
ffffffffc0200618:	aa3ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc020061c:	746c                	ld	a1,232(s0)
ffffffffc020061e:	00002517          	auipc	a0,0x2
ffffffffc0200622:	c2250513          	addi	a0,a0,-990 # ffffffffc0202240 <commands+0x340>
ffffffffc0200626:	a95ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc020062a:	786c                	ld	a1,240(s0)
ffffffffc020062c:	00002517          	auipc	a0,0x2
ffffffffc0200630:	c2c50513          	addi	a0,a0,-980 # ffffffffc0202258 <commands+0x358>
ffffffffc0200634:	a87ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200638:	7c6c                	ld	a1,248(s0)
}
ffffffffc020063a:	6402                	ld	s0,0(sp)
ffffffffc020063c:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020063e:	00002517          	auipc	a0,0x2
ffffffffc0200642:	c3250513          	addi	a0,a0,-974 # ffffffffc0202270 <commands+0x370>
}
ffffffffc0200646:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200648:	bc8d                	j	ffffffffc02000ba <cprintf>

ffffffffc020064a <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc020064a:	1141                	addi	sp,sp,-16
ffffffffc020064c:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020064e:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200650:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200652:	00002517          	auipc	a0,0x2
ffffffffc0200656:	c3650513          	addi	a0,a0,-970 # ffffffffc0202288 <commands+0x388>
void print_trapframe(struct trapframe *tf) {
ffffffffc020065a:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020065c:	a5fff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200660:	8522                	mv	a0,s0
ffffffffc0200662:	e1dff0ef          	jal	ra,ffffffffc020047e <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200666:	10043583          	ld	a1,256(s0)
ffffffffc020066a:	00002517          	auipc	a0,0x2
ffffffffc020066e:	c3650513          	addi	a0,a0,-970 # ffffffffc02022a0 <commands+0x3a0>
ffffffffc0200672:	a49ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200676:	10843583          	ld	a1,264(s0)
ffffffffc020067a:	00002517          	auipc	a0,0x2
ffffffffc020067e:	c3e50513          	addi	a0,a0,-962 # ffffffffc02022b8 <commands+0x3b8>
ffffffffc0200682:	a39ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200686:	11043583          	ld	a1,272(s0)
ffffffffc020068a:	00002517          	auipc	a0,0x2
ffffffffc020068e:	c4650513          	addi	a0,a0,-954 # ffffffffc02022d0 <commands+0x3d0>
ffffffffc0200692:	a29ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200696:	11843583          	ld	a1,280(s0)
}
ffffffffc020069a:	6402                	ld	s0,0(sp)
ffffffffc020069c:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020069e:	00002517          	auipc	a0,0x2
ffffffffc02006a2:	c4a50513          	addi	a0,a0,-950 # ffffffffc02022e8 <commands+0x3e8>
}
ffffffffc02006a6:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02006a8:	bc09                	j	ffffffffc02000ba <cprintf>

ffffffffc02006aa <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc02006aa:	11853783          	ld	a5,280(a0)
ffffffffc02006ae:	472d                	li	a4,11
ffffffffc02006b0:	0786                	slli	a5,a5,0x1
ffffffffc02006b2:	8385                	srli	a5,a5,0x1
ffffffffc02006b4:	06f76c63          	bltu	a4,a5,ffffffffc020072c <interrupt_handler+0x82>
ffffffffc02006b8:	00002717          	auipc	a4,0x2
ffffffffc02006bc:	d1070713          	addi	a4,a4,-752 # ffffffffc02023c8 <commands+0x4c8>
ffffffffc02006c0:	078a                	slli	a5,a5,0x2
ffffffffc02006c2:	97ba                	add	a5,a5,a4
ffffffffc02006c4:	439c                	lw	a5,0(a5)
ffffffffc02006c6:	97ba                	add	a5,a5,a4
ffffffffc02006c8:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02006ca:	00002517          	auipc	a0,0x2
ffffffffc02006ce:	c9650513          	addi	a0,a0,-874 # ffffffffc0202360 <commands+0x460>
ffffffffc02006d2:	b2e5                	j	ffffffffc02000ba <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02006d4:	00002517          	auipc	a0,0x2
ffffffffc02006d8:	c6c50513          	addi	a0,a0,-916 # ffffffffc0202340 <commands+0x440>
ffffffffc02006dc:	baf9                	j	ffffffffc02000ba <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02006de:	00002517          	auipc	a0,0x2
ffffffffc02006e2:	c2250513          	addi	a0,a0,-990 # ffffffffc0202300 <commands+0x400>
ffffffffc02006e6:	bad1                	j	ffffffffc02000ba <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc02006e8:	00002517          	auipc	a0,0x2
ffffffffc02006ec:	c9850513          	addi	a0,a0,-872 # ffffffffc0202380 <commands+0x480>
ffffffffc02006f0:	b2e9                	j	ffffffffc02000ba <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc02006f2:	1141                	addi	sp,sp,-16
ffffffffc02006f4:	e406                	sd	ra,8(sp)
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // cprintf("Supervisor timer interrupt\n");
            // clear_csr(sip, SIP_STIP);
            clock_set_next_event();
ffffffffc02006f6:	d4dff0ef          	jal	ra,ffffffffc0200442 <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc02006fa:	00006697          	auipc	a3,0x6
ffffffffc02006fe:	d4e68693          	addi	a3,a3,-690 # ffffffffc0206448 <ticks>
ffffffffc0200702:	629c                	ld	a5,0(a3)
ffffffffc0200704:	06400713          	li	a4,100
ffffffffc0200708:	0785                	addi	a5,a5,1
ffffffffc020070a:	02e7f733          	remu	a4,a5,a4
ffffffffc020070e:	e29c                	sd	a5,0(a3)
ffffffffc0200710:	cf19                	beqz	a4,ffffffffc020072e <interrupt_handler+0x84>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200712:	60a2                	ld	ra,8(sp)
ffffffffc0200714:	0141                	addi	sp,sp,16
ffffffffc0200716:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200718:	00002517          	auipc	a0,0x2
ffffffffc020071c:	c9050513          	addi	a0,a0,-880 # ffffffffc02023a8 <commands+0x4a8>
ffffffffc0200720:	ba69                	j	ffffffffc02000ba <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200722:	00002517          	auipc	a0,0x2
ffffffffc0200726:	bfe50513          	addi	a0,a0,-1026 # ffffffffc0202320 <commands+0x420>
ffffffffc020072a:	ba41                	j	ffffffffc02000ba <cprintf>
            print_trapframe(tf);
ffffffffc020072c:	bf39                	j	ffffffffc020064a <print_trapframe>
}
ffffffffc020072e:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200730:	06400593          	li	a1,100
ffffffffc0200734:	00002517          	auipc	a0,0x2
ffffffffc0200738:	c6450513          	addi	a0,a0,-924 # ffffffffc0202398 <commands+0x498>
}
ffffffffc020073c:	0141                	addi	sp,sp,16
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc020073e:	bab5                	j	ffffffffc02000ba <cprintf>

ffffffffc0200740 <trap>:
            break;
    }
}

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200740:	11853783          	ld	a5,280(a0)
ffffffffc0200744:	0007c763          	bltz	a5,ffffffffc0200752 <trap+0x12>
    switch (tf->cause) {
ffffffffc0200748:	472d                	li	a4,11
ffffffffc020074a:	00f76363          	bltu	a4,a5,ffffffffc0200750 <trap+0x10>
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    trap_dispatch(tf);
}
ffffffffc020074e:	8082                	ret
            print_trapframe(tf);
ffffffffc0200750:	bded                	j	ffffffffc020064a <print_trapframe>
        interrupt_handler(tf);
ffffffffc0200752:	bfa1                	j	ffffffffc02006aa <interrupt_handler>

ffffffffc0200754 <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc0200754:	14011073          	csrw	sscratch,sp
ffffffffc0200758:	712d                	addi	sp,sp,-288
ffffffffc020075a:	e002                	sd	zero,0(sp)
ffffffffc020075c:	e406                	sd	ra,8(sp)
ffffffffc020075e:	ec0e                	sd	gp,24(sp)
ffffffffc0200760:	f012                	sd	tp,32(sp)
ffffffffc0200762:	f416                	sd	t0,40(sp)
ffffffffc0200764:	f81a                	sd	t1,48(sp)
ffffffffc0200766:	fc1e                	sd	t2,56(sp)
ffffffffc0200768:	e0a2                	sd	s0,64(sp)
ffffffffc020076a:	e4a6                	sd	s1,72(sp)
ffffffffc020076c:	e8aa                	sd	a0,80(sp)
ffffffffc020076e:	ecae                	sd	a1,88(sp)
ffffffffc0200770:	f0b2                	sd	a2,96(sp)
ffffffffc0200772:	f4b6                	sd	a3,104(sp)
ffffffffc0200774:	f8ba                	sd	a4,112(sp)
ffffffffc0200776:	fcbe                	sd	a5,120(sp)
ffffffffc0200778:	e142                	sd	a6,128(sp)
ffffffffc020077a:	e546                	sd	a7,136(sp)
ffffffffc020077c:	e94a                	sd	s2,144(sp)
ffffffffc020077e:	ed4e                	sd	s3,152(sp)
ffffffffc0200780:	f152                	sd	s4,160(sp)
ffffffffc0200782:	f556                	sd	s5,168(sp)
ffffffffc0200784:	f95a                	sd	s6,176(sp)
ffffffffc0200786:	fd5e                	sd	s7,184(sp)
ffffffffc0200788:	e1e2                	sd	s8,192(sp)
ffffffffc020078a:	e5e6                	sd	s9,200(sp)
ffffffffc020078c:	e9ea                	sd	s10,208(sp)
ffffffffc020078e:	edee                	sd	s11,216(sp)
ffffffffc0200790:	f1f2                	sd	t3,224(sp)
ffffffffc0200792:	f5f6                	sd	t4,232(sp)
ffffffffc0200794:	f9fa                	sd	t5,240(sp)
ffffffffc0200796:	fdfe                	sd	t6,248(sp)
ffffffffc0200798:	14001473          	csrrw	s0,sscratch,zero
ffffffffc020079c:	100024f3          	csrr	s1,sstatus
ffffffffc02007a0:	14102973          	csrr	s2,sepc
ffffffffc02007a4:	143029f3          	csrr	s3,stval
ffffffffc02007a8:	14202a73          	csrr	s4,scause
ffffffffc02007ac:	e822                	sd	s0,16(sp)
ffffffffc02007ae:	e226                	sd	s1,256(sp)
ffffffffc02007b0:	e64a                	sd	s2,264(sp)
ffffffffc02007b2:	ea4e                	sd	s3,272(sp)
ffffffffc02007b4:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc02007b6:	850a                	mv	a0,sp
    jal trap
ffffffffc02007b8:	f89ff0ef          	jal	ra,ffffffffc0200740 <trap>

ffffffffc02007bc <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc02007bc:	6492                	ld	s1,256(sp)
ffffffffc02007be:	6932                	ld	s2,264(sp)
ffffffffc02007c0:	10049073          	csrw	sstatus,s1
ffffffffc02007c4:	14191073          	csrw	sepc,s2
ffffffffc02007c8:	60a2                	ld	ra,8(sp)
ffffffffc02007ca:	61e2                	ld	gp,24(sp)
ffffffffc02007cc:	7202                	ld	tp,32(sp)
ffffffffc02007ce:	72a2                	ld	t0,40(sp)
ffffffffc02007d0:	7342                	ld	t1,48(sp)
ffffffffc02007d2:	73e2                	ld	t2,56(sp)
ffffffffc02007d4:	6406                	ld	s0,64(sp)
ffffffffc02007d6:	64a6                	ld	s1,72(sp)
ffffffffc02007d8:	6546                	ld	a0,80(sp)
ffffffffc02007da:	65e6                	ld	a1,88(sp)
ffffffffc02007dc:	7606                	ld	a2,96(sp)
ffffffffc02007de:	76a6                	ld	a3,104(sp)
ffffffffc02007e0:	7746                	ld	a4,112(sp)
ffffffffc02007e2:	77e6                	ld	a5,120(sp)
ffffffffc02007e4:	680a                	ld	a6,128(sp)
ffffffffc02007e6:	68aa                	ld	a7,136(sp)
ffffffffc02007e8:	694a                	ld	s2,144(sp)
ffffffffc02007ea:	69ea                	ld	s3,152(sp)
ffffffffc02007ec:	7a0a                	ld	s4,160(sp)
ffffffffc02007ee:	7aaa                	ld	s5,168(sp)
ffffffffc02007f0:	7b4a                	ld	s6,176(sp)
ffffffffc02007f2:	7bea                	ld	s7,184(sp)
ffffffffc02007f4:	6c0e                	ld	s8,192(sp)
ffffffffc02007f6:	6cae                	ld	s9,200(sp)
ffffffffc02007f8:	6d4e                	ld	s10,208(sp)
ffffffffc02007fa:	6dee                	ld	s11,216(sp)
ffffffffc02007fc:	7e0e                	ld	t3,224(sp)
ffffffffc02007fe:	7eae                	ld	t4,232(sp)
ffffffffc0200800:	7f4e                	ld	t5,240(sp)
ffffffffc0200802:	7fee                	ld	t6,248(sp)
ffffffffc0200804:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200806:	10200073          	sret

ffffffffc020080a <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc020080a:	00006797          	auipc	a5,0x6
ffffffffc020080e:	81e78793          	addi	a5,a5,-2018 # ffffffffc0206028 <free_area>
ffffffffc0200812:	e79c                	sd	a5,8(a5)
ffffffffc0200814:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200816:	0007a823          	sw	zero,16(a5)
}
ffffffffc020081a:	8082                	ret

ffffffffc020081c <best_fit_nr_free_pages>:
}

static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc020081c:	00006517          	auipc	a0,0x6
ffffffffc0200820:	81c56503          	lwu	a0,-2020(a0) # ffffffffc0206038 <free_area+0x10>
ffffffffc0200824:	8082                	ret

ffffffffc0200826 <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc0200826:	c14d                	beqz	a0,ffffffffc02008c8 <best_fit_alloc_pages+0xa2>
    if (n > nr_free) {
ffffffffc0200828:	00006617          	auipc	a2,0x6
ffffffffc020082c:	80060613          	addi	a2,a2,-2048 # ffffffffc0206028 <free_area>
ffffffffc0200830:	01062803          	lw	a6,16(a2)
ffffffffc0200834:	86aa                	mv	a3,a0
ffffffffc0200836:	02081793          	slli	a5,a6,0x20
ffffffffc020083a:	9381                	srli	a5,a5,0x20
ffffffffc020083c:	08a7e463          	bltu	a5,a0,ffffffffc02008c4 <best_fit_alloc_pages+0x9e>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200840:	661c                	ld	a5,8(a2)
    size_t min_size = nr_free + 1;
ffffffffc0200842:	0018059b          	addiw	a1,a6,1
ffffffffc0200846:	1582                	slli	a1,a1,0x20
ffffffffc0200848:	9181                	srli	a1,a1,0x20
    struct Page *page = NULL;
ffffffffc020084a:	4501                	li	a0,0
    while ((le = list_next(le)) != &free_list) {
ffffffffc020084c:	06c78b63          	beq	a5,a2,ffffffffc02008c2 <best_fit_alloc_pages+0x9c>
        if (p->property >= n && p->property < min_size) {
ffffffffc0200850:	ff87e703          	lwu	a4,-8(a5)
ffffffffc0200854:	00d76763          	bltu	a4,a3,ffffffffc0200862 <best_fit_alloc_pages+0x3c>
ffffffffc0200858:	00b77563          	bgeu	a4,a1,ffffffffc0200862 <best_fit_alloc_pages+0x3c>
        struct Page *p = le2page(le, page_link);
ffffffffc020085c:	fe878513          	addi	a0,a5,-24
ffffffffc0200860:	85ba                	mv	a1,a4
ffffffffc0200862:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200864:	fec796e3          	bne	a5,a2,ffffffffc0200850 <best_fit_alloc_pages+0x2a>
    if (page != NULL) {
ffffffffc0200868:	cd29                	beqz	a0,ffffffffc02008c2 <best_fit_alloc_pages+0x9c>
    __list_del(listelm->prev, listelm->next);
ffffffffc020086a:	711c                	ld	a5,32(a0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc020086c:	6d18                	ld	a4,24(a0)
        if (page->property > n) {
ffffffffc020086e:	490c                	lw	a1,16(a0)
            p->property = page->property - n;
ffffffffc0200870:	0006889b          	sext.w	a7,a3
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200874:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0200876:	e398                	sd	a4,0(a5)
        if (page->property > n) {
ffffffffc0200878:	02059793          	slli	a5,a1,0x20
ffffffffc020087c:	9381                	srli	a5,a5,0x20
ffffffffc020087e:	02f6f863          	bgeu	a3,a5,ffffffffc02008ae <best_fit_alloc_pages+0x88>
            struct Page *p = page + n;
ffffffffc0200882:	00269793          	slli	a5,a3,0x2
ffffffffc0200886:	97b6                	add	a5,a5,a3
ffffffffc0200888:	078e                	slli	a5,a5,0x3
ffffffffc020088a:	97aa                	add	a5,a5,a0
            p->property = page->property - n;
ffffffffc020088c:	411585bb          	subw	a1,a1,a7
ffffffffc0200890:	cb8c                	sw	a1,16(a5)
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200892:	4689                	li	a3,2
ffffffffc0200894:	00878593          	addi	a1,a5,8
ffffffffc0200898:	40d5b02f          	amoor.d	zero,a3,(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc020089c:	6714                	ld	a3,8(a4)
            list_add(prev, &(p->page_link));
ffffffffc020089e:	01878593          	addi	a1,a5,24
        nr_free -= n;
ffffffffc02008a2:	01062803          	lw	a6,16(a2)
    prev->next = next->prev = elm;
ffffffffc02008a6:	e28c                	sd	a1,0(a3)
ffffffffc02008a8:	e70c                	sd	a1,8(a4)
    elm->next = next;
ffffffffc02008aa:	f394                	sd	a3,32(a5)
    elm->prev = prev;
ffffffffc02008ac:	ef98                	sd	a4,24(a5)
ffffffffc02008ae:	4118083b          	subw	a6,a6,a7
ffffffffc02008b2:	01062823          	sw	a6,16(a2)
 * clear_bit - Atomically clears a bit in memory
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void clear_bit(int nr, volatile void *addr) {
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02008b6:	57f5                	li	a5,-3
ffffffffc02008b8:	00850713          	addi	a4,a0,8
ffffffffc02008bc:	60f7302f          	amoand.d	zero,a5,(a4)
}
ffffffffc02008c0:	8082                	ret
}
ffffffffc02008c2:	8082                	ret
        return NULL;
ffffffffc02008c4:	4501                	li	a0,0
ffffffffc02008c6:	8082                	ret
best_fit_alloc_pages(size_t n) {
ffffffffc02008c8:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02008ca:	00002697          	auipc	a3,0x2
ffffffffc02008ce:	b2e68693          	addi	a3,a3,-1234 # ffffffffc02023f8 <commands+0x4f8>
ffffffffc02008d2:	00002617          	auipc	a2,0x2
ffffffffc02008d6:	b2e60613          	addi	a2,a2,-1234 # ffffffffc0202400 <commands+0x500>
ffffffffc02008da:	07000593          	li	a1,112
ffffffffc02008de:	00002517          	auipc	a0,0x2
ffffffffc02008e2:	b3a50513          	addi	a0,a0,-1222 # ffffffffc0202418 <commands+0x518>
best_fit_alloc_pages(size_t n) {
ffffffffc02008e6:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02008e8:	acdff0ef          	jal	ra,ffffffffc02003b4 <__panic>

ffffffffc02008ec <best_fit_check>:
}

// LAB2: below code is used to check the best fit allocation algorithm 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
best_fit_check(void) {
ffffffffc02008ec:	715d                	addi	sp,sp,-80
ffffffffc02008ee:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc02008f0:	00005417          	auipc	s0,0x5
ffffffffc02008f4:	73840413          	addi	s0,s0,1848 # ffffffffc0206028 <free_area>
ffffffffc02008f8:	641c                	ld	a5,8(s0)
ffffffffc02008fa:	e486                	sd	ra,72(sp)
ffffffffc02008fc:	fc26                	sd	s1,56(sp)
ffffffffc02008fe:	f84a                	sd	s2,48(sp)
ffffffffc0200900:	f44e                	sd	s3,40(sp)
ffffffffc0200902:	f052                	sd	s4,32(sp)
ffffffffc0200904:	ec56                	sd	s5,24(sp)
ffffffffc0200906:	e85a                	sd	s6,16(sp)
ffffffffc0200908:	e45e                	sd	s7,8(sp)
ffffffffc020090a:	e062                	sd	s8,0(sp)
    int score = 0 ,sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc020090c:	26878b63          	beq	a5,s0,ffffffffc0200b82 <best_fit_check+0x296>
    int count = 0, total = 0;
ffffffffc0200910:	4481                	li	s1,0
ffffffffc0200912:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200914:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200918:	8b09                	andi	a4,a4,2
ffffffffc020091a:	26070863          	beqz	a4,ffffffffc0200b8a <best_fit_check+0x29e>
        count ++, total += p->property;
ffffffffc020091e:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200922:	679c                	ld	a5,8(a5)
ffffffffc0200924:	2905                	addiw	s2,s2,1
ffffffffc0200926:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200928:	fe8796e3          	bne	a5,s0,ffffffffc0200914 <best_fit_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc020092c:	89a6                	mv	s3,s1
ffffffffc020092e:	167000ef          	jal	ra,ffffffffc0201294 <nr_free_pages>
ffffffffc0200932:	33351c63          	bne	a0,s3,ffffffffc0200c6a <best_fit_check+0x37e>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200936:	4505                	li	a0,1
ffffffffc0200938:	0df000ef          	jal	ra,ffffffffc0201216 <alloc_pages>
ffffffffc020093c:	8a2a                	mv	s4,a0
ffffffffc020093e:	36050663          	beqz	a0,ffffffffc0200caa <best_fit_check+0x3be>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200942:	4505                	li	a0,1
ffffffffc0200944:	0d3000ef          	jal	ra,ffffffffc0201216 <alloc_pages>
ffffffffc0200948:	89aa                	mv	s3,a0
ffffffffc020094a:	34050063          	beqz	a0,ffffffffc0200c8a <best_fit_check+0x39e>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020094e:	4505                	li	a0,1
ffffffffc0200950:	0c7000ef          	jal	ra,ffffffffc0201216 <alloc_pages>
ffffffffc0200954:	8aaa                	mv	s5,a0
ffffffffc0200956:	2c050a63          	beqz	a0,ffffffffc0200c2a <best_fit_check+0x33e>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020095a:	253a0863          	beq	s4,s3,ffffffffc0200baa <best_fit_check+0x2be>
ffffffffc020095e:	24aa0663          	beq	s4,a0,ffffffffc0200baa <best_fit_check+0x2be>
ffffffffc0200962:	24a98463          	beq	s3,a0,ffffffffc0200baa <best_fit_check+0x2be>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200966:	000a2783          	lw	a5,0(s4)
ffffffffc020096a:	26079063          	bnez	a5,ffffffffc0200bca <best_fit_check+0x2de>
ffffffffc020096e:	0009a783          	lw	a5,0(s3)
ffffffffc0200972:	24079c63          	bnez	a5,ffffffffc0200bca <best_fit_check+0x2de>
ffffffffc0200976:	411c                	lw	a5,0(a0)
ffffffffc0200978:	24079963          	bnez	a5,ffffffffc0200bca <best_fit_check+0x2de>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020097c:	00006797          	auipc	a5,0x6
ffffffffc0200980:	adc7b783          	ld	a5,-1316(a5) # ffffffffc0206458 <pages>
ffffffffc0200984:	40fa0733          	sub	a4,s4,a5
ffffffffc0200988:	870d                	srai	a4,a4,0x3
ffffffffc020098a:	00002597          	auipc	a1,0x2
ffffffffc020098e:	1de5b583          	ld	a1,478(a1) # ffffffffc0202b68 <error_string+0x38>
ffffffffc0200992:	02b70733          	mul	a4,a4,a1
ffffffffc0200996:	00002617          	auipc	a2,0x2
ffffffffc020099a:	1da63603          	ld	a2,474(a2) # ffffffffc0202b70 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020099e:	00006697          	auipc	a3,0x6
ffffffffc02009a2:	ab26b683          	ld	a3,-1358(a3) # ffffffffc0206450 <npage>
ffffffffc02009a6:	06b2                	slli	a3,a3,0xc
ffffffffc02009a8:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc02009aa:	0732                	slli	a4,a4,0xc
ffffffffc02009ac:	22d77f63          	bgeu	a4,a3,ffffffffc0200bea <best_fit_check+0x2fe>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02009b0:	40f98733          	sub	a4,s3,a5
ffffffffc02009b4:	870d                	srai	a4,a4,0x3
ffffffffc02009b6:	02b70733          	mul	a4,a4,a1
ffffffffc02009ba:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02009bc:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02009be:	3ed77663          	bgeu	a4,a3,ffffffffc0200daa <best_fit_check+0x4be>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02009c2:	40f507b3          	sub	a5,a0,a5
ffffffffc02009c6:	878d                	srai	a5,a5,0x3
ffffffffc02009c8:	02b787b3          	mul	a5,a5,a1
ffffffffc02009cc:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02009ce:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02009d0:	3ad7fd63          	bgeu	a5,a3,ffffffffc0200d8a <best_fit_check+0x49e>
    assert(alloc_page() == NULL);
ffffffffc02009d4:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02009d6:	00043c03          	ld	s8,0(s0)
ffffffffc02009da:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc02009de:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc02009e2:	e400                	sd	s0,8(s0)
ffffffffc02009e4:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc02009e6:	00005797          	auipc	a5,0x5
ffffffffc02009ea:	6407a923          	sw	zero,1618(a5) # ffffffffc0206038 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc02009ee:	029000ef          	jal	ra,ffffffffc0201216 <alloc_pages>
ffffffffc02009f2:	36051c63          	bnez	a0,ffffffffc0200d6a <best_fit_check+0x47e>
    free_page(p0);
ffffffffc02009f6:	4585                	li	a1,1
ffffffffc02009f8:	8552                	mv	a0,s4
ffffffffc02009fa:	05b000ef          	jal	ra,ffffffffc0201254 <free_pages>
    free_page(p1);
ffffffffc02009fe:	4585                	li	a1,1
ffffffffc0200a00:	854e                	mv	a0,s3
ffffffffc0200a02:	053000ef          	jal	ra,ffffffffc0201254 <free_pages>
    free_page(p2);
ffffffffc0200a06:	4585                	li	a1,1
ffffffffc0200a08:	8556                	mv	a0,s5
ffffffffc0200a0a:	04b000ef          	jal	ra,ffffffffc0201254 <free_pages>
    assert(nr_free == 3);
ffffffffc0200a0e:	4818                	lw	a4,16(s0)
ffffffffc0200a10:	478d                	li	a5,3
ffffffffc0200a12:	32f71c63          	bne	a4,a5,ffffffffc0200d4a <best_fit_check+0x45e>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200a16:	4505                	li	a0,1
ffffffffc0200a18:	7fe000ef          	jal	ra,ffffffffc0201216 <alloc_pages>
ffffffffc0200a1c:	89aa                	mv	s3,a0
ffffffffc0200a1e:	30050663          	beqz	a0,ffffffffc0200d2a <best_fit_check+0x43e>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200a22:	4505                	li	a0,1
ffffffffc0200a24:	7f2000ef          	jal	ra,ffffffffc0201216 <alloc_pages>
ffffffffc0200a28:	8aaa                	mv	s5,a0
ffffffffc0200a2a:	2e050063          	beqz	a0,ffffffffc0200d0a <best_fit_check+0x41e>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200a2e:	4505                	li	a0,1
ffffffffc0200a30:	7e6000ef          	jal	ra,ffffffffc0201216 <alloc_pages>
ffffffffc0200a34:	8a2a                	mv	s4,a0
ffffffffc0200a36:	2a050a63          	beqz	a0,ffffffffc0200cea <best_fit_check+0x3fe>
    assert(alloc_page() == NULL);
ffffffffc0200a3a:	4505                	li	a0,1
ffffffffc0200a3c:	7da000ef          	jal	ra,ffffffffc0201216 <alloc_pages>
ffffffffc0200a40:	28051563          	bnez	a0,ffffffffc0200cca <best_fit_check+0x3de>
    free_page(p0);
ffffffffc0200a44:	4585                	li	a1,1
ffffffffc0200a46:	854e                	mv	a0,s3
ffffffffc0200a48:	00d000ef          	jal	ra,ffffffffc0201254 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200a4c:	641c                	ld	a5,8(s0)
ffffffffc0200a4e:	1a878e63          	beq	a5,s0,ffffffffc0200c0a <best_fit_check+0x31e>
    assert((p = alloc_page()) == p0);
ffffffffc0200a52:	4505                	li	a0,1
ffffffffc0200a54:	7c2000ef          	jal	ra,ffffffffc0201216 <alloc_pages>
ffffffffc0200a58:	52a99963          	bne	s3,a0,ffffffffc0200f8a <best_fit_check+0x69e>
    assert(alloc_page() == NULL);
ffffffffc0200a5c:	4505                	li	a0,1
ffffffffc0200a5e:	7b8000ef          	jal	ra,ffffffffc0201216 <alloc_pages>
ffffffffc0200a62:	50051463          	bnez	a0,ffffffffc0200f6a <best_fit_check+0x67e>
    assert(nr_free == 0);
ffffffffc0200a66:	481c                	lw	a5,16(s0)
ffffffffc0200a68:	4e079163          	bnez	a5,ffffffffc0200f4a <best_fit_check+0x65e>
    free_page(p);
ffffffffc0200a6c:	854e                	mv	a0,s3
ffffffffc0200a6e:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200a70:	01843023          	sd	s8,0(s0)
ffffffffc0200a74:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200a78:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200a7c:	7d8000ef          	jal	ra,ffffffffc0201254 <free_pages>
    free_page(p1);
ffffffffc0200a80:	4585                	li	a1,1
ffffffffc0200a82:	8556                	mv	a0,s5
ffffffffc0200a84:	7d0000ef          	jal	ra,ffffffffc0201254 <free_pages>
    free_page(p2);
ffffffffc0200a88:	4585                	li	a1,1
ffffffffc0200a8a:	8552                	mv	a0,s4
ffffffffc0200a8c:	7c8000ef          	jal	ra,ffffffffc0201254 <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200a90:	4515                	li	a0,5
ffffffffc0200a92:	784000ef          	jal	ra,ffffffffc0201216 <alloc_pages>
ffffffffc0200a96:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200a98:	48050963          	beqz	a0,ffffffffc0200f2a <best_fit_check+0x63e>
ffffffffc0200a9c:	651c                	ld	a5,8(a0)
ffffffffc0200a9e:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200aa0:	8b85                	andi	a5,a5,1
ffffffffc0200aa2:	46079463          	bnez	a5,ffffffffc0200f0a <best_fit_check+0x61e>
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200aa6:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200aa8:	00043a83          	ld	s5,0(s0)
ffffffffc0200aac:	00843a03          	ld	s4,8(s0)
ffffffffc0200ab0:	e000                	sd	s0,0(s0)
ffffffffc0200ab2:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200ab4:	762000ef          	jal	ra,ffffffffc0201216 <alloc_pages>
ffffffffc0200ab8:	42051963          	bnez	a0,ffffffffc0200eea <best_fit_check+0x5fe>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc0200abc:	4589                	li	a1,2
ffffffffc0200abe:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc0200ac2:	01042b03          	lw	s6,16(s0)
    free_pages(p0 + 4, 1);
ffffffffc0200ac6:	0a098c13          	addi	s8,s3,160
    nr_free = 0;
ffffffffc0200aca:	00005797          	auipc	a5,0x5
ffffffffc0200ace:	5607a723          	sw	zero,1390(a5) # ffffffffc0206038 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc0200ad2:	782000ef          	jal	ra,ffffffffc0201254 <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc0200ad6:	8562                	mv	a0,s8
ffffffffc0200ad8:	4585                	li	a1,1
ffffffffc0200ada:	77a000ef          	jal	ra,ffffffffc0201254 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200ade:	4511                	li	a0,4
ffffffffc0200ae0:	736000ef          	jal	ra,ffffffffc0201216 <alloc_pages>
ffffffffc0200ae4:	3e051363          	bnez	a0,ffffffffc0200eca <best_fit_check+0x5de>
ffffffffc0200ae8:	0309b783          	ld	a5,48(s3)
ffffffffc0200aec:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200aee:	8b85                	andi	a5,a5,1
ffffffffc0200af0:	3a078d63          	beqz	a5,ffffffffc0200eaa <best_fit_check+0x5be>
ffffffffc0200af4:	0389a703          	lw	a4,56(s3)
ffffffffc0200af8:	4789                	li	a5,2
ffffffffc0200afa:	3af71863          	bne	a4,a5,ffffffffc0200eaa <best_fit_check+0x5be>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200afe:	4505                	li	a0,1
ffffffffc0200b00:	716000ef          	jal	ra,ffffffffc0201216 <alloc_pages>
ffffffffc0200b04:	8baa                	mv	s7,a0
ffffffffc0200b06:	38050263          	beqz	a0,ffffffffc0200e8a <best_fit_check+0x59e>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200b0a:	4509                	li	a0,2
ffffffffc0200b0c:	70a000ef          	jal	ra,ffffffffc0201216 <alloc_pages>
ffffffffc0200b10:	34050d63          	beqz	a0,ffffffffc0200e6a <best_fit_check+0x57e>
    assert(p0 + 4 == p1);
ffffffffc0200b14:	337c1b63          	bne	s8,s7,ffffffffc0200e4a <best_fit_check+0x55e>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc0200b18:	854e                	mv	a0,s3
ffffffffc0200b1a:	4595                	li	a1,5
ffffffffc0200b1c:	738000ef          	jal	ra,ffffffffc0201254 <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200b20:	4515                	li	a0,5
ffffffffc0200b22:	6f4000ef          	jal	ra,ffffffffc0201216 <alloc_pages>
ffffffffc0200b26:	89aa                	mv	s3,a0
ffffffffc0200b28:	30050163          	beqz	a0,ffffffffc0200e2a <best_fit_check+0x53e>
    assert(alloc_page() == NULL);
ffffffffc0200b2c:	4505                	li	a0,1
ffffffffc0200b2e:	6e8000ef          	jal	ra,ffffffffc0201216 <alloc_pages>
ffffffffc0200b32:	2c051c63          	bnez	a0,ffffffffc0200e0a <best_fit_check+0x51e>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc0200b36:	481c                	lw	a5,16(s0)
ffffffffc0200b38:	2a079963          	bnez	a5,ffffffffc0200dea <best_fit_check+0x4fe>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200b3c:	4595                	li	a1,5
ffffffffc0200b3e:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200b40:	01642823          	sw	s6,16(s0)
    free_list = free_list_store;
ffffffffc0200b44:	01543023          	sd	s5,0(s0)
ffffffffc0200b48:	01443423          	sd	s4,8(s0)
    free_pages(p0, 5);
ffffffffc0200b4c:	708000ef          	jal	ra,ffffffffc0201254 <free_pages>
    return listelm->next;
ffffffffc0200b50:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200b52:	00878963          	beq	a5,s0,ffffffffc0200b64 <best_fit_check+0x278>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200b56:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200b5a:	679c                	ld	a5,8(a5)
ffffffffc0200b5c:	397d                	addiw	s2,s2,-1
ffffffffc0200b5e:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200b60:	fe879be3          	bne	a5,s0,ffffffffc0200b56 <best_fit_check+0x26a>
    }
    assert(count == 0);
ffffffffc0200b64:	26091363          	bnez	s2,ffffffffc0200dca <best_fit_check+0x4de>
    assert(total == 0);
ffffffffc0200b68:	e0ed                	bnez	s1,ffffffffc0200c4a <best_fit_check+0x35e>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
}
ffffffffc0200b6a:	60a6                	ld	ra,72(sp)
ffffffffc0200b6c:	6406                	ld	s0,64(sp)
ffffffffc0200b6e:	74e2                	ld	s1,56(sp)
ffffffffc0200b70:	7942                	ld	s2,48(sp)
ffffffffc0200b72:	79a2                	ld	s3,40(sp)
ffffffffc0200b74:	7a02                	ld	s4,32(sp)
ffffffffc0200b76:	6ae2                	ld	s5,24(sp)
ffffffffc0200b78:	6b42                	ld	s6,16(sp)
ffffffffc0200b7a:	6ba2                	ld	s7,8(sp)
ffffffffc0200b7c:	6c02                	ld	s8,0(sp)
ffffffffc0200b7e:	6161                	addi	sp,sp,80
ffffffffc0200b80:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200b82:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200b84:	4481                	li	s1,0
ffffffffc0200b86:	4901                	li	s2,0
ffffffffc0200b88:	b35d                	j	ffffffffc020092e <best_fit_check+0x42>
        assert(PageProperty(p));
ffffffffc0200b8a:	00002697          	auipc	a3,0x2
ffffffffc0200b8e:	8a668693          	addi	a3,a3,-1882 # ffffffffc0202430 <commands+0x530>
ffffffffc0200b92:	00002617          	auipc	a2,0x2
ffffffffc0200b96:	86e60613          	addi	a2,a2,-1938 # ffffffffc0202400 <commands+0x500>
ffffffffc0200b9a:	11000593          	li	a1,272
ffffffffc0200b9e:	00002517          	auipc	a0,0x2
ffffffffc0200ba2:	87a50513          	addi	a0,a0,-1926 # ffffffffc0202418 <commands+0x518>
ffffffffc0200ba6:	80fff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200baa:	00002697          	auipc	a3,0x2
ffffffffc0200bae:	91668693          	addi	a3,a3,-1770 # ffffffffc02024c0 <commands+0x5c0>
ffffffffc0200bb2:	00002617          	auipc	a2,0x2
ffffffffc0200bb6:	84e60613          	addi	a2,a2,-1970 # ffffffffc0202400 <commands+0x500>
ffffffffc0200bba:	0dc00593          	li	a1,220
ffffffffc0200bbe:	00002517          	auipc	a0,0x2
ffffffffc0200bc2:	85a50513          	addi	a0,a0,-1958 # ffffffffc0202418 <commands+0x518>
ffffffffc0200bc6:	feeff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200bca:	00002697          	auipc	a3,0x2
ffffffffc0200bce:	91e68693          	addi	a3,a3,-1762 # ffffffffc02024e8 <commands+0x5e8>
ffffffffc0200bd2:	00002617          	auipc	a2,0x2
ffffffffc0200bd6:	82e60613          	addi	a2,a2,-2002 # ffffffffc0202400 <commands+0x500>
ffffffffc0200bda:	0dd00593          	li	a1,221
ffffffffc0200bde:	00002517          	auipc	a0,0x2
ffffffffc0200be2:	83a50513          	addi	a0,a0,-1990 # ffffffffc0202418 <commands+0x518>
ffffffffc0200be6:	fceff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200bea:	00002697          	auipc	a3,0x2
ffffffffc0200bee:	93e68693          	addi	a3,a3,-1730 # ffffffffc0202528 <commands+0x628>
ffffffffc0200bf2:	00002617          	auipc	a2,0x2
ffffffffc0200bf6:	80e60613          	addi	a2,a2,-2034 # ffffffffc0202400 <commands+0x500>
ffffffffc0200bfa:	0df00593          	li	a1,223
ffffffffc0200bfe:	00002517          	auipc	a0,0x2
ffffffffc0200c02:	81a50513          	addi	a0,a0,-2022 # ffffffffc0202418 <commands+0x518>
ffffffffc0200c06:	faeff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200c0a:	00002697          	auipc	a3,0x2
ffffffffc0200c0e:	9a668693          	addi	a3,a3,-1626 # ffffffffc02025b0 <commands+0x6b0>
ffffffffc0200c12:	00001617          	auipc	a2,0x1
ffffffffc0200c16:	7ee60613          	addi	a2,a2,2030 # ffffffffc0202400 <commands+0x500>
ffffffffc0200c1a:	0f800593          	li	a1,248
ffffffffc0200c1e:	00001517          	auipc	a0,0x1
ffffffffc0200c22:	7fa50513          	addi	a0,a0,2042 # ffffffffc0202418 <commands+0x518>
ffffffffc0200c26:	f8eff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200c2a:	00002697          	auipc	a3,0x2
ffffffffc0200c2e:	87668693          	addi	a3,a3,-1930 # ffffffffc02024a0 <commands+0x5a0>
ffffffffc0200c32:	00001617          	auipc	a2,0x1
ffffffffc0200c36:	7ce60613          	addi	a2,a2,1998 # ffffffffc0202400 <commands+0x500>
ffffffffc0200c3a:	0da00593          	li	a1,218
ffffffffc0200c3e:	00001517          	auipc	a0,0x1
ffffffffc0200c42:	7da50513          	addi	a0,a0,2010 # ffffffffc0202418 <commands+0x518>
ffffffffc0200c46:	f6eff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(total == 0);
ffffffffc0200c4a:	00002697          	auipc	a3,0x2
ffffffffc0200c4e:	a9668693          	addi	a3,a3,-1386 # ffffffffc02026e0 <commands+0x7e0>
ffffffffc0200c52:	00001617          	auipc	a2,0x1
ffffffffc0200c56:	7ae60613          	addi	a2,a2,1966 # ffffffffc0202400 <commands+0x500>
ffffffffc0200c5a:	15200593          	li	a1,338
ffffffffc0200c5e:	00001517          	auipc	a0,0x1
ffffffffc0200c62:	7ba50513          	addi	a0,a0,1978 # ffffffffc0202418 <commands+0x518>
ffffffffc0200c66:	f4eff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(total == nr_free_pages());
ffffffffc0200c6a:	00001697          	auipc	a3,0x1
ffffffffc0200c6e:	7d668693          	addi	a3,a3,2006 # ffffffffc0202440 <commands+0x540>
ffffffffc0200c72:	00001617          	auipc	a2,0x1
ffffffffc0200c76:	78e60613          	addi	a2,a2,1934 # ffffffffc0202400 <commands+0x500>
ffffffffc0200c7a:	11300593          	li	a1,275
ffffffffc0200c7e:	00001517          	auipc	a0,0x1
ffffffffc0200c82:	79a50513          	addi	a0,a0,1946 # ffffffffc0202418 <commands+0x518>
ffffffffc0200c86:	f2eff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200c8a:	00001697          	auipc	a3,0x1
ffffffffc0200c8e:	7f668693          	addi	a3,a3,2038 # ffffffffc0202480 <commands+0x580>
ffffffffc0200c92:	00001617          	auipc	a2,0x1
ffffffffc0200c96:	76e60613          	addi	a2,a2,1902 # ffffffffc0202400 <commands+0x500>
ffffffffc0200c9a:	0d900593          	li	a1,217
ffffffffc0200c9e:	00001517          	auipc	a0,0x1
ffffffffc0200ca2:	77a50513          	addi	a0,a0,1914 # ffffffffc0202418 <commands+0x518>
ffffffffc0200ca6:	f0eff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200caa:	00001697          	auipc	a3,0x1
ffffffffc0200cae:	7b668693          	addi	a3,a3,1974 # ffffffffc0202460 <commands+0x560>
ffffffffc0200cb2:	00001617          	auipc	a2,0x1
ffffffffc0200cb6:	74e60613          	addi	a2,a2,1870 # ffffffffc0202400 <commands+0x500>
ffffffffc0200cba:	0d800593          	li	a1,216
ffffffffc0200cbe:	00001517          	auipc	a0,0x1
ffffffffc0200cc2:	75a50513          	addi	a0,a0,1882 # ffffffffc0202418 <commands+0x518>
ffffffffc0200cc6:	eeeff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200cca:	00002697          	auipc	a3,0x2
ffffffffc0200cce:	8be68693          	addi	a3,a3,-1858 # ffffffffc0202588 <commands+0x688>
ffffffffc0200cd2:	00001617          	auipc	a2,0x1
ffffffffc0200cd6:	72e60613          	addi	a2,a2,1838 # ffffffffc0202400 <commands+0x500>
ffffffffc0200cda:	0f500593          	li	a1,245
ffffffffc0200cde:	00001517          	auipc	a0,0x1
ffffffffc0200ce2:	73a50513          	addi	a0,a0,1850 # ffffffffc0202418 <commands+0x518>
ffffffffc0200ce6:	eceff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200cea:	00001697          	auipc	a3,0x1
ffffffffc0200cee:	7b668693          	addi	a3,a3,1974 # ffffffffc02024a0 <commands+0x5a0>
ffffffffc0200cf2:	00001617          	auipc	a2,0x1
ffffffffc0200cf6:	70e60613          	addi	a2,a2,1806 # ffffffffc0202400 <commands+0x500>
ffffffffc0200cfa:	0f300593          	li	a1,243
ffffffffc0200cfe:	00001517          	auipc	a0,0x1
ffffffffc0200d02:	71a50513          	addi	a0,a0,1818 # ffffffffc0202418 <commands+0x518>
ffffffffc0200d06:	eaeff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200d0a:	00001697          	auipc	a3,0x1
ffffffffc0200d0e:	77668693          	addi	a3,a3,1910 # ffffffffc0202480 <commands+0x580>
ffffffffc0200d12:	00001617          	auipc	a2,0x1
ffffffffc0200d16:	6ee60613          	addi	a2,a2,1774 # ffffffffc0202400 <commands+0x500>
ffffffffc0200d1a:	0f200593          	li	a1,242
ffffffffc0200d1e:	00001517          	auipc	a0,0x1
ffffffffc0200d22:	6fa50513          	addi	a0,a0,1786 # ffffffffc0202418 <commands+0x518>
ffffffffc0200d26:	e8eff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200d2a:	00001697          	auipc	a3,0x1
ffffffffc0200d2e:	73668693          	addi	a3,a3,1846 # ffffffffc0202460 <commands+0x560>
ffffffffc0200d32:	00001617          	auipc	a2,0x1
ffffffffc0200d36:	6ce60613          	addi	a2,a2,1742 # ffffffffc0202400 <commands+0x500>
ffffffffc0200d3a:	0f100593          	li	a1,241
ffffffffc0200d3e:	00001517          	auipc	a0,0x1
ffffffffc0200d42:	6da50513          	addi	a0,a0,1754 # ffffffffc0202418 <commands+0x518>
ffffffffc0200d46:	e6eff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(nr_free == 3);
ffffffffc0200d4a:	00002697          	auipc	a3,0x2
ffffffffc0200d4e:	85668693          	addi	a3,a3,-1962 # ffffffffc02025a0 <commands+0x6a0>
ffffffffc0200d52:	00001617          	auipc	a2,0x1
ffffffffc0200d56:	6ae60613          	addi	a2,a2,1710 # ffffffffc0202400 <commands+0x500>
ffffffffc0200d5a:	0ef00593          	li	a1,239
ffffffffc0200d5e:	00001517          	auipc	a0,0x1
ffffffffc0200d62:	6ba50513          	addi	a0,a0,1722 # ffffffffc0202418 <commands+0x518>
ffffffffc0200d66:	e4eff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200d6a:	00002697          	auipc	a3,0x2
ffffffffc0200d6e:	81e68693          	addi	a3,a3,-2018 # ffffffffc0202588 <commands+0x688>
ffffffffc0200d72:	00001617          	auipc	a2,0x1
ffffffffc0200d76:	68e60613          	addi	a2,a2,1678 # ffffffffc0202400 <commands+0x500>
ffffffffc0200d7a:	0ea00593          	li	a1,234
ffffffffc0200d7e:	00001517          	auipc	a0,0x1
ffffffffc0200d82:	69a50513          	addi	a0,a0,1690 # ffffffffc0202418 <commands+0x518>
ffffffffc0200d86:	e2eff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200d8a:	00001697          	auipc	a3,0x1
ffffffffc0200d8e:	7de68693          	addi	a3,a3,2014 # ffffffffc0202568 <commands+0x668>
ffffffffc0200d92:	00001617          	auipc	a2,0x1
ffffffffc0200d96:	66e60613          	addi	a2,a2,1646 # ffffffffc0202400 <commands+0x500>
ffffffffc0200d9a:	0e100593          	li	a1,225
ffffffffc0200d9e:	00001517          	auipc	a0,0x1
ffffffffc0200da2:	67a50513          	addi	a0,a0,1658 # ffffffffc0202418 <commands+0x518>
ffffffffc0200da6:	e0eff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200daa:	00001697          	auipc	a3,0x1
ffffffffc0200dae:	79e68693          	addi	a3,a3,1950 # ffffffffc0202548 <commands+0x648>
ffffffffc0200db2:	00001617          	auipc	a2,0x1
ffffffffc0200db6:	64e60613          	addi	a2,a2,1614 # ffffffffc0202400 <commands+0x500>
ffffffffc0200dba:	0e000593          	li	a1,224
ffffffffc0200dbe:	00001517          	auipc	a0,0x1
ffffffffc0200dc2:	65a50513          	addi	a0,a0,1626 # ffffffffc0202418 <commands+0x518>
ffffffffc0200dc6:	deeff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(count == 0);
ffffffffc0200dca:	00002697          	auipc	a3,0x2
ffffffffc0200dce:	90668693          	addi	a3,a3,-1786 # ffffffffc02026d0 <commands+0x7d0>
ffffffffc0200dd2:	00001617          	auipc	a2,0x1
ffffffffc0200dd6:	62e60613          	addi	a2,a2,1582 # ffffffffc0202400 <commands+0x500>
ffffffffc0200dda:	15100593          	li	a1,337
ffffffffc0200dde:	00001517          	auipc	a0,0x1
ffffffffc0200de2:	63a50513          	addi	a0,a0,1594 # ffffffffc0202418 <commands+0x518>
ffffffffc0200de6:	dceff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(nr_free == 0);
ffffffffc0200dea:	00001697          	auipc	a3,0x1
ffffffffc0200dee:	7fe68693          	addi	a3,a3,2046 # ffffffffc02025e8 <commands+0x6e8>
ffffffffc0200df2:	00001617          	auipc	a2,0x1
ffffffffc0200df6:	60e60613          	addi	a2,a2,1550 # ffffffffc0202400 <commands+0x500>
ffffffffc0200dfa:	14600593          	li	a1,326
ffffffffc0200dfe:	00001517          	auipc	a0,0x1
ffffffffc0200e02:	61a50513          	addi	a0,a0,1562 # ffffffffc0202418 <commands+0x518>
ffffffffc0200e06:	daeff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200e0a:	00001697          	auipc	a3,0x1
ffffffffc0200e0e:	77e68693          	addi	a3,a3,1918 # ffffffffc0202588 <commands+0x688>
ffffffffc0200e12:	00001617          	auipc	a2,0x1
ffffffffc0200e16:	5ee60613          	addi	a2,a2,1518 # ffffffffc0202400 <commands+0x500>
ffffffffc0200e1a:	14000593          	li	a1,320
ffffffffc0200e1e:	00001517          	auipc	a0,0x1
ffffffffc0200e22:	5fa50513          	addi	a0,a0,1530 # ffffffffc0202418 <commands+0x518>
ffffffffc0200e26:	d8eff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200e2a:	00002697          	auipc	a3,0x2
ffffffffc0200e2e:	88668693          	addi	a3,a3,-1914 # ffffffffc02026b0 <commands+0x7b0>
ffffffffc0200e32:	00001617          	auipc	a2,0x1
ffffffffc0200e36:	5ce60613          	addi	a2,a2,1486 # ffffffffc0202400 <commands+0x500>
ffffffffc0200e3a:	13f00593          	li	a1,319
ffffffffc0200e3e:	00001517          	auipc	a0,0x1
ffffffffc0200e42:	5da50513          	addi	a0,a0,1498 # ffffffffc0202418 <commands+0x518>
ffffffffc0200e46:	d6eff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(p0 + 4 == p1);
ffffffffc0200e4a:	00002697          	auipc	a3,0x2
ffffffffc0200e4e:	85668693          	addi	a3,a3,-1962 # ffffffffc02026a0 <commands+0x7a0>
ffffffffc0200e52:	00001617          	auipc	a2,0x1
ffffffffc0200e56:	5ae60613          	addi	a2,a2,1454 # ffffffffc0202400 <commands+0x500>
ffffffffc0200e5a:	13700593          	li	a1,311
ffffffffc0200e5e:	00001517          	auipc	a0,0x1
ffffffffc0200e62:	5ba50513          	addi	a0,a0,1466 # ffffffffc0202418 <commands+0x518>
ffffffffc0200e66:	d4eff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200e6a:	00002697          	auipc	a3,0x2
ffffffffc0200e6e:	81e68693          	addi	a3,a3,-2018 # ffffffffc0202688 <commands+0x788>
ffffffffc0200e72:	00001617          	auipc	a2,0x1
ffffffffc0200e76:	58e60613          	addi	a2,a2,1422 # ffffffffc0202400 <commands+0x500>
ffffffffc0200e7a:	13600593          	li	a1,310
ffffffffc0200e7e:	00001517          	auipc	a0,0x1
ffffffffc0200e82:	59a50513          	addi	a0,a0,1434 # ffffffffc0202418 <commands+0x518>
ffffffffc0200e86:	d2eff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200e8a:	00001697          	auipc	a3,0x1
ffffffffc0200e8e:	7de68693          	addi	a3,a3,2014 # ffffffffc0202668 <commands+0x768>
ffffffffc0200e92:	00001617          	auipc	a2,0x1
ffffffffc0200e96:	56e60613          	addi	a2,a2,1390 # ffffffffc0202400 <commands+0x500>
ffffffffc0200e9a:	13500593          	li	a1,309
ffffffffc0200e9e:	00001517          	auipc	a0,0x1
ffffffffc0200ea2:	57a50513          	addi	a0,a0,1402 # ffffffffc0202418 <commands+0x518>
ffffffffc0200ea6:	d0eff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200eaa:	00001697          	auipc	a3,0x1
ffffffffc0200eae:	78e68693          	addi	a3,a3,1934 # ffffffffc0202638 <commands+0x738>
ffffffffc0200eb2:	00001617          	auipc	a2,0x1
ffffffffc0200eb6:	54e60613          	addi	a2,a2,1358 # ffffffffc0202400 <commands+0x500>
ffffffffc0200eba:	13300593          	li	a1,307
ffffffffc0200ebe:	00001517          	auipc	a0,0x1
ffffffffc0200ec2:	55a50513          	addi	a0,a0,1370 # ffffffffc0202418 <commands+0x518>
ffffffffc0200ec6:	ceeff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0200eca:	00001697          	auipc	a3,0x1
ffffffffc0200ece:	75668693          	addi	a3,a3,1878 # ffffffffc0202620 <commands+0x720>
ffffffffc0200ed2:	00001617          	auipc	a2,0x1
ffffffffc0200ed6:	52e60613          	addi	a2,a2,1326 # ffffffffc0202400 <commands+0x500>
ffffffffc0200eda:	13200593          	li	a1,306
ffffffffc0200ede:	00001517          	auipc	a0,0x1
ffffffffc0200ee2:	53a50513          	addi	a0,a0,1338 # ffffffffc0202418 <commands+0x518>
ffffffffc0200ee6:	cceff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200eea:	00001697          	auipc	a3,0x1
ffffffffc0200eee:	69e68693          	addi	a3,a3,1694 # ffffffffc0202588 <commands+0x688>
ffffffffc0200ef2:	00001617          	auipc	a2,0x1
ffffffffc0200ef6:	50e60613          	addi	a2,a2,1294 # ffffffffc0202400 <commands+0x500>
ffffffffc0200efa:	12600593          	li	a1,294
ffffffffc0200efe:	00001517          	auipc	a0,0x1
ffffffffc0200f02:	51a50513          	addi	a0,a0,1306 # ffffffffc0202418 <commands+0x518>
ffffffffc0200f06:	caeff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(!PageProperty(p0));
ffffffffc0200f0a:	00001697          	auipc	a3,0x1
ffffffffc0200f0e:	6fe68693          	addi	a3,a3,1790 # ffffffffc0202608 <commands+0x708>
ffffffffc0200f12:	00001617          	auipc	a2,0x1
ffffffffc0200f16:	4ee60613          	addi	a2,a2,1262 # ffffffffc0202400 <commands+0x500>
ffffffffc0200f1a:	11d00593          	li	a1,285
ffffffffc0200f1e:	00001517          	auipc	a0,0x1
ffffffffc0200f22:	4fa50513          	addi	a0,a0,1274 # ffffffffc0202418 <commands+0x518>
ffffffffc0200f26:	c8eff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(p0 != NULL);
ffffffffc0200f2a:	00001697          	auipc	a3,0x1
ffffffffc0200f2e:	6ce68693          	addi	a3,a3,1742 # ffffffffc02025f8 <commands+0x6f8>
ffffffffc0200f32:	00001617          	auipc	a2,0x1
ffffffffc0200f36:	4ce60613          	addi	a2,a2,1230 # ffffffffc0202400 <commands+0x500>
ffffffffc0200f3a:	11c00593          	li	a1,284
ffffffffc0200f3e:	00001517          	auipc	a0,0x1
ffffffffc0200f42:	4da50513          	addi	a0,a0,1242 # ffffffffc0202418 <commands+0x518>
ffffffffc0200f46:	c6eff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(nr_free == 0);
ffffffffc0200f4a:	00001697          	auipc	a3,0x1
ffffffffc0200f4e:	69e68693          	addi	a3,a3,1694 # ffffffffc02025e8 <commands+0x6e8>
ffffffffc0200f52:	00001617          	auipc	a2,0x1
ffffffffc0200f56:	4ae60613          	addi	a2,a2,1198 # ffffffffc0202400 <commands+0x500>
ffffffffc0200f5a:	0fe00593          	li	a1,254
ffffffffc0200f5e:	00001517          	auipc	a0,0x1
ffffffffc0200f62:	4ba50513          	addi	a0,a0,1210 # ffffffffc0202418 <commands+0x518>
ffffffffc0200f66:	c4eff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200f6a:	00001697          	auipc	a3,0x1
ffffffffc0200f6e:	61e68693          	addi	a3,a3,1566 # ffffffffc0202588 <commands+0x688>
ffffffffc0200f72:	00001617          	auipc	a2,0x1
ffffffffc0200f76:	48e60613          	addi	a2,a2,1166 # ffffffffc0202400 <commands+0x500>
ffffffffc0200f7a:	0fc00593          	li	a1,252
ffffffffc0200f7e:	00001517          	auipc	a0,0x1
ffffffffc0200f82:	49a50513          	addi	a0,a0,1178 # ffffffffc0202418 <commands+0x518>
ffffffffc0200f86:	c2eff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0200f8a:	00001697          	auipc	a3,0x1
ffffffffc0200f8e:	63e68693          	addi	a3,a3,1598 # ffffffffc02025c8 <commands+0x6c8>
ffffffffc0200f92:	00001617          	auipc	a2,0x1
ffffffffc0200f96:	46e60613          	addi	a2,a2,1134 # ffffffffc0202400 <commands+0x500>
ffffffffc0200f9a:	0fb00593          	li	a1,251
ffffffffc0200f9e:	00001517          	auipc	a0,0x1
ffffffffc0200fa2:	47a50513          	addi	a0,a0,1146 # ffffffffc0202418 <commands+0x518>
ffffffffc0200fa6:	c0eff0ef          	jal	ra,ffffffffc02003b4 <__panic>

ffffffffc0200faa <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc0200faa:	1141                	addi	sp,sp,-16
ffffffffc0200fac:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200fae:	14058a63          	beqz	a1,ffffffffc0201102 <best_fit_free_pages+0x158>
    for (; p != base + n; p ++) {
ffffffffc0200fb2:	00259693          	slli	a3,a1,0x2
ffffffffc0200fb6:	96ae                	add	a3,a3,a1
ffffffffc0200fb8:	068e                	slli	a3,a3,0x3
ffffffffc0200fba:	96aa                	add	a3,a3,a0
ffffffffc0200fbc:	87aa                	mv	a5,a0
ffffffffc0200fbe:	02d50263          	beq	a0,a3,ffffffffc0200fe2 <best_fit_free_pages+0x38>
ffffffffc0200fc2:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200fc4:	8b05                	andi	a4,a4,1
ffffffffc0200fc6:	10071e63          	bnez	a4,ffffffffc02010e2 <best_fit_free_pages+0x138>
ffffffffc0200fca:	6798                	ld	a4,8(a5)
ffffffffc0200fcc:	8b09                	andi	a4,a4,2
ffffffffc0200fce:	10071a63          	bnez	a4,ffffffffc02010e2 <best_fit_free_pages+0x138>
        p->flags = 0;
ffffffffc0200fd2:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200fd6:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0200fda:	02878793          	addi	a5,a5,40
ffffffffc0200fde:	fed792e3          	bne	a5,a3,ffffffffc0200fc2 <best_fit_free_pages+0x18>
    base->property = n;
ffffffffc0200fe2:	2581                	sext.w	a1,a1
ffffffffc0200fe4:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0200fe6:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200fea:	4789                	li	a5,2
ffffffffc0200fec:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0200ff0:	00005697          	auipc	a3,0x5
ffffffffc0200ff4:	03868693          	addi	a3,a3,56 # ffffffffc0206028 <free_area>
ffffffffc0200ff8:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0200ffa:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0200ffc:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201000:	9db9                	addw	a1,a1,a4
ffffffffc0201002:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201004:	0ad78863          	beq	a5,a3,ffffffffc02010b4 <best_fit_free_pages+0x10a>
            struct Page* page = le2page(le, page_link);
ffffffffc0201008:	fe878713          	addi	a4,a5,-24
ffffffffc020100c:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0201010:	4581                	li	a1,0
            if (base < page) {
ffffffffc0201012:	00e56a63          	bltu	a0,a4,ffffffffc0201026 <best_fit_free_pages+0x7c>
    return listelm->next;
ffffffffc0201016:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201018:	06d70263          	beq	a4,a3,ffffffffc020107c <best_fit_free_pages+0xd2>
    for (; p != base + n; p ++) {
ffffffffc020101c:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc020101e:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201022:	fee57ae3          	bgeu	a0,a4,ffffffffc0201016 <best_fit_free_pages+0x6c>
ffffffffc0201026:	c199                	beqz	a1,ffffffffc020102c <best_fit_free_pages+0x82>
ffffffffc0201028:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020102c:	6398                	ld	a4,0(a5)
    prev->next = next->prev = elm;
ffffffffc020102e:	e390                	sd	a2,0(a5)
ffffffffc0201030:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201032:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201034:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc0201036:	02d70063          	beq	a4,a3,ffffffffc0201056 <best_fit_free_pages+0xac>
        if (p + p->property == base)//连续
ffffffffc020103a:	ff872803          	lw	a6,-8(a4)
        p = le2page(le, page_link);
ffffffffc020103e:	fe870593          	addi	a1,a4,-24
        if (p + p->property == base)//连续
ffffffffc0201042:	02081613          	slli	a2,a6,0x20
ffffffffc0201046:	9201                	srli	a2,a2,0x20
ffffffffc0201048:	00261793          	slli	a5,a2,0x2
ffffffffc020104c:	97b2                	add	a5,a5,a2
ffffffffc020104e:	078e                	slli	a5,a5,0x3
ffffffffc0201050:	97ae                	add	a5,a5,a1
ffffffffc0201052:	02f50f63          	beq	a0,a5,ffffffffc0201090 <best_fit_free_pages+0xe6>
    return listelm->next;
ffffffffc0201056:	7118                	ld	a4,32(a0)
    if (le != &free_list) {
ffffffffc0201058:	00d70f63          	beq	a4,a3,ffffffffc0201076 <best_fit_free_pages+0xcc>
        if (base + base->property == p) {
ffffffffc020105c:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc020105e:	fe870693          	addi	a3,a4,-24
        if (base + base->property == p) {
ffffffffc0201062:	02059613          	slli	a2,a1,0x20
ffffffffc0201066:	9201                	srli	a2,a2,0x20
ffffffffc0201068:	00261793          	slli	a5,a2,0x2
ffffffffc020106c:	97b2                	add	a5,a5,a2
ffffffffc020106e:	078e                	slli	a5,a5,0x3
ffffffffc0201070:	97aa                	add	a5,a5,a0
ffffffffc0201072:	04f68863          	beq	a3,a5,ffffffffc02010c2 <best_fit_free_pages+0x118>
}
ffffffffc0201076:	60a2                	ld	ra,8(sp)
ffffffffc0201078:	0141                	addi	sp,sp,16
ffffffffc020107a:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020107c:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020107e:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201080:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201082:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201084:	02d70563          	beq	a4,a3,ffffffffc02010ae <best_fit_free_pages+0x104>
    prev->next = next->prev = elm;
ffffffffc0201088:	8832                	mv	a6,a2
ffffffffc020108a:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc020108c:	87ba                	mv	a5,a4
ffffffffc020108e:	bf41                	j	ffffffffc020101e <best_fit_free_pages+0x74>
            p->property += base->property;
ffffffffc0201090:	491c                	lw	a5,16(a0)
ffffffffc0201092:	0107883b          	addw	a6,a5,a6
ffffffffc0201096:	ff072c23          	sw	a6,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020109a:	57f5                	li	a5,-3
ffffffffc020109c:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc02010a0:	6d10                	ld	a2,24(a0)
ffffffffc02010a2:	711c                	ld	a5,32(a0)
            base = p;
ffffffffc02010a4:	852e                	mv	a0,a1
    prev->next = next;
ffffffffc02010a6:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc02010a8:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc02010aa:	e390                	sd	a2,0(a5)
ffffffffc02010ac:	b775                	j	ffffffffc0201058 <best_fit_free_pages+0xae>
ffffffffc02010ae:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02010b0:	873e                	mv	a4,a5
ffffffffc02010b2:	b761                	j	ffffffffc020103a <best_fit_free_pages+0x90>
}
ffffffffc02010b4:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02010b6:	e390                	sd	a2,0(a5)
ffffffffc02010b8:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02010ba:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02010bc:	ed1c                	sd	a5,24(a0)
ffffffffc02010be:	0141                	addi	sp,sp,16
ffffffffc02010c0:	8082                	ret
            base->property += p->property;
ffffffffc02010c2:	ff872783          	lw	a5,-8(a4)
ffffffffc02010c6:	ff070693          	addi	a3,a4,-16
ffffffffc02010ca:	9dbd                	addw	a1,a1,a5
ffffffffc02010cc:	c90c                	sw	a1,16(a0)
ffffffffc02010ce:	57f5                	li	a5,-3
ffffffffc02010d0:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02010d4:	6314                	ld	a3,0(a4)
ffffffffc02010d6:	671c                	ld	a5,8(a4)
}
ffffffffc02010d8:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc02010da:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc02010dc:	e394                	sd	a3,0(a5)
ffffffffc02010de:	0141                	addi	sp,sp,16
ffffffffc02010e0:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02010e2:	00001697          	auipc	a3,0x1
ffffffffc02010e6:	60e68693          	addi	a3,a3,1550 # ffffffffc02026f0 <commands+0x7f0>
ffffffffc02010ea:	00001617          	auipc	a2,0x1
ffffffffc02010ee:	31660613          	addi	a2,a2,790 # ffffffffc0202400 <commands+0x500>
ffffffffc02010f2:	09700593          	li	a1,151
ffffffffc02010f6:	00001517          	auipc	a0,0x1
ffffffffc02010fa:	32250513          	addi	a0,a0,802 # ffffffffc0202418 <commands+0x518>
ffffffffc02010fe:	ab6ff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(n > 0);
ffffffffc0201102:	00001697          	auipc	a3,0x1
ffffffffc0201106:	2f668693          	addi	a3,a3,758 # ffffffffc02023f8 <commands+0x4f8>
ffffffffc020110a:	00001617          	auipc	a2,0x1
ffffffffc020110e:	2f660613          	addi	a2,a2,758 # ffffffffc0202400 <commands+0x500>
ffffffffc0201112:	09400593          	li	a1,148
ffffffffc0201116:	00001517          	auipc	a0,0x1
ffffffffc020111a:	30250513          	addi	a0,a0,770 # ffffffffc0202418 <commands+0x518>
ffffffffc020111e:	a96ff0ef          	jal	ra,ffffffffc02003b4 <__panic>

ffffffffc0201122 <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc0201122:	1141                	addi	sp,sp,-16
ffffffffc0201124:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201126:	c9e1                	beqz	a1,ffffffffc02011f6 <best_fit_init_memmap+0xd4>
    for (; p != base + n; p ++) {
ffffffffc0201128:	00259693          	slli	a3,a1,0x2
ffffffffc020112c:	96ae                	add	a3,a3,a1
ffffffffc020112e:	068e                	slli	a3,a3,0x3
ffffffffc0201130:	96aa                	add	a3,a3,a0
ffffffffc0201132:	87aa                	mv	a5,a0
ffffffffc0201134:	00d50f63          	beq	a0,a3,ffffffffc0201152 <best_fit_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201138:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc020113a:	8b05                	andi	a4,a4,1
ffffffffc020113c:	cf49                	beqz	a4,ffffffffc02011d6 <best_fit_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc020113e:	0007a823          	sw	zero,16(a5)
ffffffffc0201142:	0007b423          	sd	zero,8(a5)
ffffffffc0201146:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc020114a:	02878793          	addi	a5,a5,40
ffffffffc020114e:	fed795e3          	bne	a5,a3,ffffffffc0201138 <best_fit_init_memmap+0x16>
    base->property = n;
ffffffffc0201152:	2581                	sext.w	a1,a1
ffffffffc0201154:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201156:	4789                	li	a5,2
ffffffffc0201158:	00850713          	addi	a4,a0,8
ffffffffc020115c:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201160:	00005697          	auipc	a3,0x5
ffffffffc0201164:	ec868693          	addi	a3,a3,-312 # ffffffffc0206028 <free_area>
ffffffffc0201168:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc020116a:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc020116c:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201170:	9db9                	addw	a1,a1,a4
ffffffffc0201172:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201174:	04d78a63          	beq	a5,a3,ffffffffc02011c8 <best_fit_init_memmap+0xa6>
            struct Page* page = le2page(le, page_link);
ffffffffc0201178:	fe878713          	addi	a4,a5,-24
ffffffffc020117c:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0201180:	4581                	li	a1,0
            if(base < page) 
ffffffffc0201182:	00e56a63          	bltu	a0,a4,ffffffffc0201196 <best_fit_init_memmap+0x74>
    return listelm->next;
ffffffffc0201186:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0201188:	02d70263          	beq	a4,a3,ffffffffc02011ac <best_fit_init_memmap+0x8a>
    for (; p != base + n; p ++) {
ffffffffc020118c:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc020118e:	fe878713          	addi	a4,a5,-24
            if(base < page) 
ffffffffc0201192:	fee57ae3          	bgeu	a0,a4,ffffffffc0201186 <best_fit_init_memmap+0x64>
ffffffffc0201196:	c199                	beqz	a1,ffffffffc020119c <best_fit_init_memmap+0x7a>
ffffffffc0201198:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020119c:	6398                	ld	a4,0(a5)
}
ffffffffc020119e:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02011a0:	e390                	sd	a2,0(a5)
ffffffffc02011a2:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02011a4:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02011a6:	ed18                	sd	a4,24(a0)
ffffffffc02011a8:	0141                	addi	sp,sp,16
ffffffffc02011aa:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02011ac:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02011ae:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02011b0:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02011b2:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02011b4:	00d70663          	beq	a4,a3,ffffffffc02011c0 <best_fit_init_memmap+0x9e>
    prev->next = next->prev = elm;
ffffffffc02011b8:	8832                	mv	a6,a2
ffffffffc02011ba:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc02011bc:	87ba                	mv	a5,a4
ffffffffc02011be:	bfc1                	j	ffffffffc020118e <best_fit_init_memmap+0x6c>
}
ffffffffc02011c0:	60a2                	ld	ra,8(sp)
ffffffffc02011c2:	e290                	sd	a2,0(a3)
ffffffffc02011c4:	0141                	addi	sp,sp,16
ffffffffc02011c6:	8082                	ret
ffffffffc02011c8:	60a2                	ld	ra,8(sp)
ffffffffc02011ca:	e390                	sd	a2,0(a5)
ffffffffc02011cc:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02011ce:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02011d0:	ed1c                	sd	a5,24(a0)
ffffffffc02011d2:	0141                	addi	sp,sp,16
ffffffffc02011d4:	8082                	ret
        assert(PageReserved(p));
ffffffffc02011d6:	00001697          	auipc	a3,0x1
ffffffffc02011da:	54268693          	addi	a3,a3,1346 # ffffffffc0202718 <commands+0x818>
ffffffffc02011de:	00001617          	auipc	a2,0x1
ffffffffc02011e2:	22260613          	addi	a2,a2,546 # ffffffffc0202400 <commands+0x500>
ffffffffc02011e6:	04c00593          	li	a1,76
ffffffffc02011ea:	00001517          	auipc	a0,0x1
ffffffffc02011ee:	22e50513          	addi	a0,a0,558 # ffffffffc0202418 <commands+0x518>
ffffffffc02011f2:	9c2ff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(n > 0);
ffffffffc02011f6:	00001697          	auipc	a3,0x1
ffffffffc02011fa:	20268693          	addi	a3,a3,514 # ffffffffc02023f8 <commands+0x4f8>
ffffffffc02011fe:	00001617          	auipc	a2,0x1
ffffffffc0201202:	20260613          	addi	a2,a2,514 # ffffffffc0202400 <commands+0x500>
ffffffffc0201206:	04800593          	li	a1,72
ffffffffc020120a:	00001517          	auipc	a0,0x1
ffffffffc020120e:	20e50513          	addi	a0,a0,526 # ffffffffc0202418 <commands+0x518>
ffffffffc0201212:	9a2ff0ef          	jal	ra,ffffffffc02003b4 <__panic>

ffffffffc0201216 <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201216:	100027f3          	csrr	a5,sstatus
ffffffffc020121a:	8b89                	andi	a5,a5,2
ffffffffc020121c:	e799                	bnez	a5,ffffffffc020122a <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc020121e:	00005797          	auipc	a5,0x5
ffffffffc0201222:	2427b783          	ld	a5,578(a5) # ffffffffc0206460 <pmm_manager>
ffffffffc0201226:	6f9c                	ld	a5,24(a5)
ffffffffc0201228:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc020122a:	1141                	addi	sp,sp,-16
ffffffffc020122c:	e406                	sd	ra,8(sp)
ffffffffc020122e:	e022                	sd	s0,0(sp)
ffffffffc0201230:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201232:	a34ff0ef          	jal	ra,ffffffffc0200466 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201236:	00005797          	auipc	a5,0x5
ffffffffc020123a:	22a7b783          	ld	a5,554(a5) # ffffffffc0206460 <pmm_manager>
ffffffffc020123e:	6f9c                	ld	a5,24(a5)
ffffffffc0201240:	8522                	mv	a0,s0
ffffffffc0201242:	9782                	jalr	a5
ffffffffc0201244:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc0201246:	a1aff0ef          	jal	ra,ffffffffc0200460 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc020124a:	60a2                	ld	ra,8(sp)
ffffffffc020124c:	8522                	mv	a0,s0
ffffffffc020124e:	6402                	ld	s0,0(sp)
ffffffffc0201250:	0141                	addi	sp,sp,16
ffffffffc0201252:	8082                	ret

ffffffffc0201254 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201254:	100027f3          	csrr	a5,sstatus
ffffffffc0201258:	8b89                	andi	a5,a5,2
ffffffffc020125a:	e799                	bnez	a5,ffffffffc0201268 <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc020125c:	00005797          	auipc	a5,0x5
ffffffffc0201260:	2047b783          	ld	a5,516(a5) # ffffffffc0206460 <pmm_manager>
ffffffffc0201264:	739c                	ld	a5,32(a5)
ffffffffc0201266:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc0201268:	1101                	addi	sp,sp,-32
ffffffffc020126a:	ec06                	sd	ra,24(sp)
ffffffffc020126c:	e822                	sd	s0,16(sp)
ffffffffc020126e:	e426                	sd	s1,8(sp)
ffffffffc0201270:	842a                	mv	s0,a0
ffffffffc0201272:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201274:	9f2ff0ef          	jal	ra,ffffffffc0200466 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201278:	00005797          	auipc	a5,0x5
ffffffffc020127c:	1e87b783          	ld	a5,488(a5) # ffffffffc0206460 <pmm_manager>
ffffffffc0201280:	739c                	ld	a5,32(a5)
ffffffffc0201282:	85a6                	mv	a1,s1
ffffffffc0201284:	8522                	mv	a0,s0
ffffffffc0201286:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201288:	6442                	ld	s0,16(sp)
ffffffffc020128a:	60e2                	ld	ra,24(sp)
ffffffffc020128c:	64a2                	ld	s1,8(sp)
ffffffffc020128e:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201290:	9d0ff06f          	j	ffffffffc0200460 <intr_enable>

ffffffffc0201294 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201294:	100027f3          	csrr	a5,sstatus
ffffffffc0201298:	8b89                	andi	a5,a5,2
ffffffffc020129a:	e799                	bnez	a5,ffffffffc02012a8 <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc020129c:	00005797          	auipc	a5,0x5
ffffffffc02012a0:	1c47b783          	ld	a5,452(a5) # ffffffffc0206460 <pmm_manager>
ffffffffc02012a4:	779c                	ld	a5,40(a5)
ffffffffc02012a6:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc02012a8:	1141                	addi	sp,sp,-16
ffffffffc02012aa:	e406                	sd	ra,8(sp)
ffffffffc02012ac:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc02012ae:	9b8ff0ef          	jal	ra,ffffffffc0200466 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc02012b2:	00005797          	auipc	a5,0x5
ffffffffc02012b6:	1ae7b783          	ld	a5,430(a5) # ffffffffc0206460 <pmm_manager>
ffffffffc02012ba:	779c                	ld	a5,40(a5)
ffffffffc02012bc:	9782                	jalr	a5
ffffffffc02012be:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02012c0:	9a0ff0ef          	jal	ra,ffffffffc0200460 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc02012c4:	60a2                	ld	ra,8(sp)
ffffffffc02012c6:	8522                	mv	a0,s0
ffffffffc02012c8:	6402                	ld	s0,0(sp)
ffffffffc02012ca:	0141                	addi	sp,sp,16
ffffffffc02012cc:	8082                	ret

ffffffffc02012ce <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;      //在此更换页面管理函数指针
ffffffffc02012ce:	00001797          	auipc	a5,0x1
ffffffffc02012d2:	47278793          	addi	a5,a5,1138 # ffffffffc0202740 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02012d6:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc02012d8:	1101                	addi	sp,sp,-32
ffffffffc02012da:	e426                	sd	s1,8(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02012dc:	00001517          	auipc	a0,0x1
ffffffffc02012e0:	49c50513          	addi	a0,a0,1180 # ffffffffc0202778 <best_fit_pmm_manager+0x38>
    pmm_manager = &best_fit_pmm_manager;      //在此更换页面管理函数指针
ffffffffc02012e4:	00005497          	auipc	s1,0x5
ffffffffc02012e8:	17c48493          	addi	s1,s1,380 # ffffffffc0206460 <pmm_manager>
void pmm_init(void) {
ffffffffc02012ec:	ec06                	sd	ra,24(sp)
ffffffffc02012ee:	e822                	sd	s0,16(sp)
    pmm_manager = &best_fit_pmm_manager;      //在此更换页面管理函数指针
ffffffffc02012f0:	e09c                	sd	a5,0(s1)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02012f2:	dc9fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    pmm_manager->init();
ffffffffc02012f6:	609c                	ld	a5,0(s1)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02012f8:	00005417          	auipc	s0,0x5
ffffffffc02012fc:	18040413          	addi	s0,s0,384 # ffffffffc0206478 <va_pa_offset>
    pmm_manager->init();
ffffffffc0201300:	679c                	ld	a5,8(a5)
ffffffffc0201302:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201304:	57f5                	li	a5,-3
ffffffffc0201306:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc0201308:	00001517          	auipc	a0,0x1
ffffffffc020130c:	48850513          	addi	a0,a0,1160 # ffffffffc0202790 <best_fit_pmm_manager+0x50>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201310:	e01c                	sd	a5,0(s0)
    cprintf("physcial memory map:\n");
ffffffffc0201312:	da9fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0201316:	46c5                	li	a3,17
ffffffffc0201318:	06ee                	slli	a3,a3,0x1b
ffffffffc020131a:	40100613          	li	a2,1025
ffffffffc020131e:	16fd                	addi	a3,a3,-1
ffffffffc0201320:	07e005b7          	lui	a1,0x7e00
ffffffffc0201324:	0656                	slli	a2,a2,0x15
ffffffffc0201326:	00001517          	auipc	a0,0x1
ffffffffc020132a:	48250513          	addi	a0,a0,1154 # ffffffffc02027a8 <best_fit_pmm_manager+0x68>
ffffffffc020132e:	d8dfe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201332:	777d                	lui	a4,0xfffff
ffffffffc0201334:	00006797          	auipc	a5,0x6
ffffffffc0201338:	15b78793          	addi	a5,a5,347 # ffffffffc020748f <end+0xfff>
ffffffffc020133c:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc020133e:	00005517          	auipc	a0,0x5
ffffffffc0201342:	11250513          	addi	a0,a0,274 # ffffffffc0206450 <npage>
ffffffffc0201346:	00088737          	lui	a4,0x88
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020134a:	00005597          	auipc	a1,0x5
ffffffffc020134e:	10e58593          	addi	a1,a1,270 # ffffffffc0206458 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0201352:	e118                	sd	a4,0(a0)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201354:	e19c                	sd	a5,0(a1)
ffffffffc0201356:	4681                	li	a3,0
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201358:	4701                	li	a4,0
ffffffffc020135a:	4885                	li	a7,1
ffffffffc020135c:	fff80837          	lui	a6,0xfff80
ffffffffc0201360:	a011                	j	ffffffffc0201364 <pmm_init+0x96>
        SetPageReserved(pages + i);
ffffffffc0201362:	619c                	ld	a5,0(a1)
ffffffffc0201364:	97b6                	add	a5,a5,a3
ffffffffc0201366:	07a1                	addi	a5,a5,8
ffffffffc0201368:	4117b02f          	amoor.d	zero,a7,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020136c:	611c                	ld	a5,0(a0)
ffffffffc020136e:	0705                	addi	a4,a4,1
ffffffffc0201370:	02868693          	addi	a3,a3,40
ffffffffc0201374:	01078633          	add	a2,a5,a6
ffffffffc0201378:	fec765e3          	bltu	a4,a2,ffffffffc0201362 <pmm_init+0x94>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020137c:	6190                	ld	a2,0(a1)
ffffffffc020137e:	00279713          	slli	a4,a5,0x2
ffffffffc0201382:	973e                	add	a4,a4,a5
ffffffffc0201384:	fec006b7          	lui	a3,0xfec00
ffffffffc0201388:	070e                	slli	a4,a4,0x3
ffffffffc020138a:	96b2                	add	a3,a3,a2
ffffffffc020138c:	96ba                	add	a3,a3,a4
ffffffffc020138e:	c0200737          	lui	a4,0xc0200
ffffffffc0201392:	08e6ef63          	bltu	a3,a4,ffffffffc0201430 <pmm_init+0x162>
ffffffffc0201396:	6018                	ld	a4,0(s0)
    if (freemem < mem_end) {
ffffffffc0201398:	45c5                	li	a1,17
ffffffffc020139a:	05ee                	slli	a1,a1,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020139c:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc020139e:	04b6e863          	bltu	a3,a1,ffffffffc02013ee <pmm_init+0x120>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02013a2:	609c                	ld	a5,0(s1)
ffffffffc02013a4:	7b9c                	ld	a5,48(a5)
ffffffffc02013a6:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02013a8:	00001517          	auipc	a0,0x1
ffffffffc02013ac:	49850513          	addi	a0,a0,1176 # ffffffffc0202840 <best_fit_pmm_manager+0x100>
ffffffffc02013b0:	d0bfe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc02013b4:	00004597          	auipc	a1,0x4
ffffffffc02013b8:	c4c58593          	addi	a1,a1,-948 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc02013bc:	00005797          	auipc	a5,0x5
ffffffffc02013c0:	0ab7ba23          	sd	a1,180(a5) # ffffffffc0206470 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc02013c4:	c02007b7          	lui	a5,0xc0200
ffffffffc02013c8:	08f5e063          	bltu	a1,a5,ffffffffc0201448 <pmm_init+0x17a>
ffffffffc02013cc:	6010                	ld	a2,0(s0)
}
ffffffffc02013ce:	6442                	ld	s0,16(sp)
ffffffffc02013d0:	60e2                	ld	ra,24(sp)
ffffffffc02013d2:	64a2                	ld	s1,8(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc02013d4:	40c58633          	sub	a2,a1,a2
ffffffffc02013d8:	00005797          	auipc	a5,0x5
ffffffffc02013dc:	08c7b823          	sd	a2,144(a5) # ffffffffc0206468 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02013e0:	00001517          	auipc	a0,0x1
ffffffffc02013e4:	48050513          	addi	a0,a0,1152 # ffffffffc0202860 <best_fit_pmm_manager+0x120>
}
ffffffffc02013e8:	6105                	addi	sp,sp,32
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02013ea:	cd1fe06f          	j	ffffffffc02000ba <cprintf>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02013ee:	6705                	lui	a4,0x1
ffffffffc02013f0:	177d                	addi	a4,a4,-1
ffffffffc02013f2:	96ba                	add	a3,a3,a4
ffffffffc02013f4:	777d                	lui	a4,0xfffff
ffffffffc02013f6:	8ef9                	and	a3,a3,a4
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc02013f8:	00c6d513          	srli	a0,a3,0xc
ffffffffc02013fc:	00f57e63          	bgeu	a0,a5,ffffffffc0201418 <pmm_init+0x14a>
    pmm_manager->init_memmap(base, n);
ffffffffc0201400:	609c                	ld	a5,0(s1)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0201402:	982a                	add	a6,a6,a0
ffffffffc0201404:	00281513          	slli	a0,a6,0x2
ffffffffc0201408:	9542                	add	a0,a0,a6
ffffffffc020140a:	6b9c                	ld	a5,16(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc020140c:	8d95                	sub	a1,a1,a3
ffffffffc020140e:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0201410:	81b1                	srli	a1,a1,0xc
ffffffffc0201412:	9532                	add	a0,a0,a2
ffffffffc0201414:	9782                	jalr	a5
}
ffffffffc0201416:	b771                	j	ffffffffc02013a2 <pmm_init+0xd4>
        panic("pa2page called with invalid pa");
ffffffffc0201418:	00001617          	auipc	a2,0x1
ffffffffc020141c:	3f860613          	addi	a2,a2,1016 # ffffffffc0202810 <best_fit_pmm_manager+0xd0>
ffffffffc0201420:	06b00593          	li	a1,107
ffffffffc0201424:	00001517          	auipc	a0,0x1
ffffffffc0201428:	40c50513          	addi	a0,a0,1036 # ffffffffc0202830 <best_fit_pmm_manager+0xf0>
ffffffffc020142c:	f89fe0ef          	jal	ra,ffffffffc02003b4 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201430:	00001617          	auipc	a2,0x1
ffffffffc0201434:	3a860613          	addi	a2,a2,936 # ffffffffc02027d8 <best_fit_pmm_manager+0x98>
ffffffffc0201438:	07100593          	li	a1,113
ffffffffc020143c:	00001517          	auipc	a0,0x1
ffffffffc0201440:	3c450513          	addi	a0,a0,964 # ffffffffc0202800 <best_fit_pmm_manager+0xc0>
ffffffffc0201444:	f71fe0ef          	jal	ra,ffffffffc02003b4 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201448:	86ae                	mv	a3,a1
ffffffffc020144a:	00001617          	auipc	a2,0x1
ffffffffc020144e:	38e60613          	addi	a2,a2,910 # ffffffffc02027d8 <best_fit_pmm_manager+0x98>
ffffffffc0201452:	08d00593          	li	a1,141
ffffffffc0201456:	00001517          	auipc	a0,0x1
ffffffffc020145a:	3aa50513          	addi	a0,a0,938 # ffffffffc0202800 <best_fit_pmm_manager+0xc0>
ffffffffc020145e:	f57fe0ef          	jal	ra,ffffffffc02003b4 <__panic>

ffffffffc0201462 <slob_free>:
}

static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	if (!block)
ffffffffc0201462:	cd1d                	beqz	a0,ffffffffc02014a0 <slob_free+0x3e>
		return;
	if (size)
ffffffffc0201464:	ed9d                	bnez	a1,ffffffffc02014a2 <slob_free+0x40>

	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
		if (cur >= cur->next && (b > cur || b < cur->next))
			break;

	if (b + b->units == cur->next) {
ffffffffc0201466:	4114                	lw	a3,0(a0)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201468:	00005597          	auipc	a1,0x5
ffffffffc020146c:	ba858593          	addi	a1,a1,-1112 # ffffffffc0206010 <slobfree>
ffffffffc0201470:	619c                	ld	a5,0(a1)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201472:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201474:	679c                	ld	a5,8(a5)
ffffffffc0201476:	02a77b63          	bgeu	a4,a0,ffffffffc02014ac <slob_free+0x4a>
ffffffffc020147a:	00f56463          	bltu	a0,a5,ffffffffc0201482 <slob_free+0x20>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc020147e:	fef76ae3          	bltu	a4,a5,ffffffffc0201472 <slob_free+0x10>
	if (b + b->units == cur->next) {
ffffffffc0201482:	00469613          	slli	a2,a3,0x4
ffffffffc0201486:	962a                	add	a2,a2,a0
ffffffffc0201488:	02c78b63          	beq	a5,a2,ffffffffc02014be <slob_free+0x5c>
		b->units += cur->next->units;
		b->next = cur->next->next;
	} else
		b->next = cur->next;

	if (cur + cur->units == b) {
ffffffffc020148c:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc020148e:	e51c                	sd	a5,8(a0)
	if (cur + cur->units == b) {
ffffffffc0201490:	00469793          	slli	a5,a3,0x4
ffffffffc0201494:	97ba                	add	a5,a5,a4
ffffffffc0201496:	02f50f63          	beq	a0,a5,ffffffffc02014d4 <slob_free+0x72>
		cur->units += b->units;
		cur->next = b->next;
	} else
		cur->next = b;
ffffffffc020149a:	e708                	sd	a0,8(a4)

	slobfree = cur;
ffffffffc020149c:	e198                	sd	a4,0(a1)
ffffffffc020149e:	8082                	ret
}
ffffffffc02014a0:	8082                	ret
		b->units = SLOB_UNITS(size);
ffffffffc02014a2:	00f5869b          	addiw	a3,a1,15
ffffffffc02014a6:	8691                	srai	a3,a3,0x4
ffffffffc02014a8:	c114                	sw	a3,0(a0)
ffffffffc02014aa:	bf7d                	j	ffffffffc0201468 <slob_free+0x6>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02014ac:	fcf763e3          	bltu	a4,a5,ffffffffc0201472 <slob_free+0x10>
ffffffffc02014b0:	fcf571e3          	bgeu	a0,a5,ffffffffc0201472 <slob_free+0x10>
	if (b + b->units == cur->next) {
ffffffffc02014b4:	00469613          	slli	a2,a3,0x4
ffffffffc02014b8:	962a                	add	a2,a2,a0
ffffffffc02014ba:	fcc799e3          	bne	a5,a2,ffffffffc020148c <slob_free+0x2a>
		b->units += cur->next->units;
ffffffffc02014be:	4390                	lw	a2,0(a5)
		b->next = cur->next->next;
ffffffffc02014c0:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc02014c2:	9eb1                	addw	a3,a3,a2
ffffffffc02014c4:	c114                	sw	a3,0(a0)
	if (cur + cur->units == b) {
ffffffffc02014c6:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc02014c8:	e51c                	sd	a5,8(a0)
	if (cur + cur->units == b) {
ffffffffc02014ca:	00469793          	slli	a5,a3,0x4
ffffffffc02014ce:	97ba                	add	a5,a5,a4
ffffffffc02014d0:	fcf515e3          	bne	a0,a5,ffffffffc020149a <slob_free+0x38>
		cur->units += b->units;
ffffffffc02014d4:	411c                	lw	a5,0(a0)
		cur->next = b->next;
ffffffffc02014d6:	6510                	ld	a2,8(a0)
	slobfree = cur;
ffffffffc02014d8:	e198                	sd	a4,0(a1)
		cur->units += b->units;
ffffffffc02014da:	9ebd                	addw	a3,a3,a5
ffffffffc02014dc:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc02014de:	e710                	sd	a2,8(a4)
	slobfree = cur;
ffffffffc02014e0:	8082                	ret

ffffffffc02014e2 <slob_alloc>:
{
ffffffffc02014e2:	1101                	addi	sp,sp,-32
ffffffffc02014e4:	ec06                	sd	ra,24(sp)
ffffffffc02014e6:	e822                	sd	s0,16(sp)
ffffffffc02014e8:	e426                	sd	s1,8(sp)
ffffffffc02014ea:	e04a                	sd	s2,0(sp)
    assert(size < PGSIZE);
ffffffffc02014ec:	6785                	lui	a5,0x1
ffffffffc02014ee:	08f57363          	bgeu	a0,a5,ffffffffc0201574 <slob_alloc+0x92>
	prev = slobfree;
ffffffffc02014f2:	00005417          	auipc	s0,0x5
ffffffffc02014f6:	b1e40413          	addi	s0,s0,-1250 # ffffffffc0206010 <slobfree>
ffffffffc02014fa:	6010                	ld	a2,0(s0)
	int  units = SLOB_UNITS(size);
ffffffffc02014fc:	053d                	addi	a0,a0,15
ffffffffc02014fe:	00455913          	srli	s2,a0,0x4
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc0201502:	6618                	ld	a4,8(a2)
	int  units = SLOB_UNITS(size);
ffffffffc0201504:	0009049b          	sext.w	s1,s2
		if (cur->units >= units) {
ffffffffc0201508:	4314                	lw	a3,0(a4)
ffffffffc020150a:	0696d263          	bge	a3,s1,ffffffffc020156e <slob_alloc+0x8c>
		if (cur == slobfree) {
ffffffffc020150e:	00e60a63          	beq	a2,a4,ffffffffc0201522 <slob_alloc+0x40>
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc0201512:	671c                	ld	a5,8(a4)
		if (cur->units >= units) {
ffffffffc0201514:	4394                	lw	a3,0(a5)
ffffffffc0201516:	0296d363          	bge	a3,s1,ffffffffc020153c <slob_alloc+0x5a>
		if (cur == slobfree) {
ffffffffc020151a:	6010                	ld	a2,0(s0)
ffffffffc020151c:	873e                	mv	a4,a5
ffffffffc020151e:	fee61ae3          	bne	a2,a4,ffffffffc0201512 <slob_alloc+0x30>
			cur = (slob_t *)alloc_pages(1);
ffffffffc0201522:	4505                	li	a0,1
ffffffffc0201524:	cf3ff0ef          	jal	ra,ffffffffc0201216 <alloc_pages>
ffffffffc0201528:	87aa                	mv	a5,a0
			if (!cur)
ffffffffc020152a:	c51d                	beqz	a0,ffffffffc0201558 <slob_alloc+0x76>
			slob_free(cur, PGSIZE);
ffffffffc020152c:	6585                	lui	a1,0x1
ffffffffc020152e:	f35ff0ef          	jal	ra,ffffffffc0201462 <slob_free>
			cur = slobfree;
ffffffffc0201532:	6018                	ld	a4,0(s0)
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc0201534:	671c                	ld	a5,8(a4)
		if (cur->units >= units) {
ffffffffc0201536:	4394                	lw	a3,0(a5)
ffffffffc0201538:	fe96c1e3          	blt	a3,s1,ffffffffc020151a <slob_alloc+0x38>
			if (cur->units == units)
ffffffffc020153c:	02d48563          	beq	s1,a3,ffffffffc0201566 <slob_alloc+0x84>
				prev->next = cur + units;
ffffffffc0201540:	0912                	slli	s2,s2,0x4
ffffffffc0201542:	993e                	add	s2,s2,a5
ffffffffc0201544:	01273423          	sd	s2,8(a4) # fffffffffffff008 <end+0x3fdf8b78>
				prev->next->next = cur->next;
ffffffffc0201548:	6790                	ld	a2,8(a5)
				prev->next->units = cur->units - units;
ffffffffc020154a:	9e85                	subw	a3,a3,s1
ffffffffc020154c:	00d92023          	sw	a3,0(s2)
				prev->next->next = cur->next;
ffffffffc0201550:	00c93423          	sd	a2,8(s2)
				cur->units = units;
ffffffffc0201554:	c384                	sw	s1,0(a5)
			slobfree = prev;
ffffffffc0201556:	e018                	sd	a4,0(s0)
}
ffffffffc0201558:	60e2                	ld	ra,24(sp)
ffffffffc020155a:	6442                	ld	s0,16(sp)
ffffffffc020155c:	64a2                	ld	s1,8(sp)
ffffffffc020155e:	6902                	ld	s2,0(sp)
ffffffffc0201560:	853e                	mv	a0,a5
ffffffffc0201562:	6105                	addi	sp,sp,32
ffffffffc0201564:	8082                	ret
				prev->next = cur->next;
ffffffffc0201566:	6794                	ld	a3,8(a5)
			slobfree = prev;
ffffffffc0201568:	e018                	sd	a4,0(s0)
				prev->next = cur->next;
ffffffffc020156a:	e714                	sd	a3,8(a4)
			return cur;
ffffffffc020156c:	b7f5                	j	ffffffffc0201558 <slob_alloc+0x76>
		if (cur->units >= units) {
ffffffffc020156e:	87ba                	mv	a5,a4
ffffffffc0201570:	8732                	mv	a4,a2
ffffffffc0201572:	b7e9                	j	ffffffffc020153c <slob_alloc+0x5a>
    assert(size < PGSIZE);
ffffffffc0201574:	00001697          	auipc	a3,0x1
ffffffffc0201578:	32c68693          	addi	a3,a3,812 # ffffffffc02028a0 <best_fit_pmm_manager+0x160>
ffffffffc020157c:	00001617          	auipc	a2,0x1
ffffffffc0201580:	e8460613          	addi	a2,a2,-380 # ffffffffc0202400 <commands+0x500>
ffffffffc0201584:	02100593          	li	a1,33
ffffffffc0201588:	00001517          	auipc	a0,0x1
ffffffffc020158c:	32850513          	addi	a0,a0,808 # ffffffffc02028b0 <best_fit_pmm_manager+0x170>
ffffffffc0201590:	e25fe0ef          	jal	ra,ffffffffc02003b4 <__panic>

ffffffffc0201594 <slub_alloc.part.0>:
void 
slub_init(void) {
    cprintf("slub_init() succeeded!\n");
}

void *slub_alloc(size_t size)
ffffffffc0201594:	1101                	addi	sp,sp,-32
ffffffffc0201596:	e822                	sd	s0,16(sp)
ffffffffc0201598:	842a                	mv	s0,a0
	if (size < PGSIZE - SLOB_UNIT) {
		m = slob_alloc(size + SLOB_UNIT);
		return m ? (void *)(m + 1) : 0;
	}

	bb = slob_alloc(sizeof(bigblock_t));
ffffffffc020159a:	4561                	li	a0,24
void *slub_alloc(size_t size)
ffffffffc020159c:	ec06                	sd	ra,24(sp)
ffffffffc020159e:	e426                	sd	s1,8(sp)
	bb = slob_alloc(sizeof(bigblock_t));
ffffffffc02015a0:	f43ff0ef          	jal	ra,ffffffffc02014e2 <slob_alloc>
	if (!bb)
ffffffffc02015a4:	c915                	beqz	a0,ffffffffc02015d8 <slub_alloc.part.0+0x44>
		return 0;

	bb->order = ((size-1) >> PGSHIFT) + 1;
ffffffffc02015a6:	fff40793          	addi	a5,s0,-1
ffffffffc02015aa:	83b1                	srli	a5,a5,0xc
ffffffffc02015ac:	84aa                	mv	s1,a0
ffffffffc02015ae:	0017851b          	addiw	a0,a5,1
ffffffffc02015b2:	c088                	sw	a0,0(s1)
	bb->pages = (void *)alloc_pages(bb->order);
ffffffffc02015b4:	c63ff0ef          	jal	ra,ffffffffc0201216 <alloc_pages>
ffffffffc02015b8:	e488                	sd	a0,8(s1)
ffffffffc02015ba:	842a                	mv	s0,a0

	if (bb->pages) {
ffffffffc02015bc:	c50d                	beqz	a0,ffffffffc02015e6 <slub_alloc.part.0+0x52>
		bb->next = bigblocks;
ffffffffc02015be:	00005797          	auipc	a5,0x5
ffffffffc02015c2:	ec278793          	addi	a5,a5,-318 # ffffffffc0206480 <bigblocks>
ffffffffc02015c6:	6398                	ld	a4,0(a5)
		return bb->pages;
	}

	slob_free(bb, sizeof(bigblock_t));
	return 0;
}
ffffffffc02015c8:	60e2                	ld	ra,24(sp)
ffffffffc02015ca:	8522                	mv	a0,s0
ffffffffc02015cc:	6442                	ld	s0,16(sp)
		bigblocks = bb;
ffffffffc02015ce:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc02015d0:	e898                	sd	a4,16(s1)
}
ffffffffc02015d2:	64a2                	ld	s1,8(sp)
ffffffffc02015d4:	6105                	addi	sp,sp,32
ffffffffc02015d6:	8082                	ret
		return 0;
ffffffffc02015d8:	4401                	li	s0,0
}
ffffffffc02015da:	60e2                	ld	ra,24(sp)
ffffffffc02015dc:	8522                	mv	a0,s0
ffffffffc02015de:	6442                	ld	s0,16(sp)
ffffffffc02015e0:	64a2                	ld	s1,8(sp)
ffffffffc02015e2:	6105                	addi	sp,sp,32
ffffffffc02015e4:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc02015e6:	8526                	mv	a0,s1
ffffffffc02015e8:	45e1                	li	a1,24
ffffffffc02015ea:	e79ff0ef          	jal	ra,ffffffffc0201462 <slob_free>
}
ffffffffc02015ee:	60e2                	ld	ra,24(sp)
ffffffffc02015f0:	8522                	mv	a0,s0
ffffffffc02015f2:	6442                	ld	s0,16(sp)
ffffffffc02015f4:	64a2                	ld	s1,8(sp)
ffffffffc02015f6:	6105                	addi	sp,sp,32
ffffffffc02015f8:	8082                	ret

ffffffffc02015fa <slub_init>:
    cprintf("slub_init() succeeded!\n");
ffffffffc02015fa:	00001517          	auipc	a0,0x1
ffffffffc02015fe:	2ce50513          	addi	a0,a0,718 # ffffffffc02028c8 <best_fit_pmm_manager+0x188>
ffffffffc0201602:	ab9fe06f          	j	ffffffffc02000ba <cprintf>

ffffffffc0201606 <slub_free>:

void slub_free(void *block)
{
	bigblock_t *bb, **last = &bigblocks;

	if (!block)
ffffffffc0201606:	c531                	beqz	a0,ffffffffc0201652 <slub_free+0x4c>
		return;

	if (!((unsigned long)block & (PGSIZE-1))) {
ffffffffc0201608:	03451793          	slli	a5,a0,0x34
ffffffffc020160c:	e7a1                	bnez	a5,ffffffffc0201654 <slub_free+0x4e>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc020160e:	00005697          	auipc	a3,0x5
ffffffffc0201612:	e7268693          	addi	a3,a3,-398 # ffffffffc0206480 <bigblocks>
ffffffffc0201616:	629c                	ld	a5,0(a3)
ffffffffc0201618:	cf95                	beqz	a5,ffffffffc0201654 <slub_free+0x4e>
{
ffffffffc020161a:	1141                	addi	sp,sp,-16
ffffffffc020161c:	e406                	sd	ra,8(sp)
ffffffffc020161e:	e022                	sd	s0,0(sp)
ffffffffc0201620:	a021                	j	ffffffffc0201628 <slub_free+0x22>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201622:	01040693          	addi	a3,s0,16
ffffffffc0201626:	c385                	beqz	a5,ffffffffc0201646 <slub_free+0x40>
			if (bb->pages == block) {
ffffffffc0201628:	6798                	ld	a4,8(a5)
ffffffffc020162a:	843e                	mv	s0,a5
				*last = bb->next;
ffffffffc020162c:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block) {
ffffffffc020162e:	fea71ae3          	bne	a4,a0,ffffffffc0201622 <slub_free+0x1c>
				free_pages((struct Page *)block, bb->order);
ffffffffc0201632:	400c                	lw	a1,0(s0)
				*last = bb->next;
ffffffffc0201634:	e29c                	sd	a5,0(a3)
				free_pages((struct Page *)block, bb->order);
ffffffffc0201636:	c1fff0ef          	jal	ra,ffffffffc0201254 <free_pages>
				slob_free(bb, sizeof(bigblock_t));
ffffffffc020163a:	8522                	mv	a0,s0
		}
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc020163c:	6402                	ld	s0,0(sp)
ffffffffc020163e:	60a2                	ld	ra,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201640:	45e1                	li	a1,24
}
ffffffffc0201642:	0141                	addi	sp,sp,16
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201644:	bd39                	j	ffffffffc0201462 <slob_free>
}
ffffffffc0201646:	6402                	ld	s0,0(sp)
ffffffffc0201648:	60a2                	ld	ra,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc020164a:	4581                	li	a1,0
ffffffffc020164c:	1541                	addi	a0,a0,-16
}
ffffffffc020164e:	0141                	addi	sp,sp,16
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201650:	bd09                	j	ffffffffc0201462 <slob_free>
ffffffffc0201652:	8082                	ret
ffffffffc0201654:	4581                	li	a1,0
ffffffffc0201656:	1541                	addi	a0,a0,-16
ffffffffc0201658:	b529                	j	ffffffffc0201462 <slob_free>

ffffffffc020165a <slub_check>:
        len ++;
    return len;
}

void slub_check()
{
ffffffffc020165a:	1101                	addi	sp,sp,-32
    cprintf("slub check begin\n");
ffffffffc020165c:	00001517          	auipc	a0,0x1
ffffffffc0201660:	28450513          	addi	a0,a0,644 # ffffffffc02028e0 <best_fit_pmm_manager+0x1a0>
{
ffffffffc0201664:	e822                	sd	s0,16(sp)
ffffffffc0201666:	ec06                	sd	ra,24(sp)
ffffffffc0201668:	e426                	sd	s1,8(sp)
ffffffffc020166a:	e04a                	sd	s2,0(sp)
    for(slob_t* curr = slobfree->next; curr != slobfree; curr = curr->next)
ffffffffc020166c:	00005417          	auipc	s0,0x5
ffffffffc0201670:	9a440413          	addi	s0,s0,-1628 # ffffffffc0206010 <slobfree>
    cprintf("slub check begin\n");
ffffffffc0201674:	a47fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    for(slob_t* curr = slobfree->next; curr != slobfree; curr = curr->next)
ffffffffc0201678:	6018                	ld	a4,0(s0)
    int len = 0;
ffffffffc020167a:	4581                	li	a1,0
    for(slob_t* curr = slobfree->next; curr != slobfree; curr = curr->next)
ffffffffc020167c:	671c                	ld	a5,8(a4)
ffffffffc020167e:	00f70663          	beq	a4,a5,ffffffffc020168a <slub_check+0x30>
ffffffffc0201682:	679c                	ld	a5,8(a5)
        len ++;
ffffffffc0201684:	2585                	addiw	a1,a1,1
    for(slob_t* curr = slobfree->next; curr != slobfree; curr = curr->next)
ffffffffc0201686:	fef71ee3          	bne	a4,a5,ffffffffc0201682 <slub_check+0x28>
    cprintf("slobfree len: %d\n", slobfree_len());
ffffffffc020168a:	00001517          	auipc	a0,0x1
ffffffffc020168e:	26e50513          	addi	a0,a0,622 # ffffffffc02028f8 <best_fit_pmm_manager+0x1b8>
ffffffffc0201692:	a29fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
	if (size < PGSIZE - SLOB_UNIT) {
ffffffffc0201696:	6505                	lui	a0,0x1
ffffffffc0201698:	efdff0ef          	jal	ra,ffffffffc0201594 <slub_alloc.part.0>
    for(slob_t* curr = slobfree->next; curr != slobfree; curr = curr->next)
ffffffffc020169c:	6018                	ld	a4,0(s0)
    int len = 0;
ffffffffc020169e:	4581                	li	a1,0
    for(slob_t* curr = slobfree->next; curr != slobfree; curr = curr->next)
ffffffffc02016a0:	671c                	ld	a5,8(a4)
ffffffffc02016a2:	00f70663          	beq	a4,a5,ffffffffc02016ae <slub_check+0x54>
ffffffffc02016a6:	679c                	ld	a5,8(a5)
        len ++;
ffffffffc02016a8:	2585                	addiw	a1,a1,1
    for(slob_t* curr = slobfree->next; curr != slobfree; curr = curr->next)
ffffffffc02016aa:	fef71ee3          	bne	a4,a5,ffffffffc02016a6 <slub_check+0x4c>
    void* p1 = slub_alloc(4096);
    cprintf("slobfree len: %d\n", slobfree_len());
ffffffffc02016ae:	00001517          	auipc	a0,0x1
ffffffffc02016b2:	24a50513          	addi	a0,a0,586 # ffffffffc02028f8 <best_fit_pmm_manager+0x1b8>
ffffffffc02016b6:	a05fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
		m = slob_alloc(size + SLOB_UNIT);
ffffffffc02016ba:	4549                	li	a0,18
ffffffffc02016bc:	e27ff0ef          	jal	ra,ffffffffc02014e2 <slob_alloc>
ffffffffc02016c0:	892a                	mv	s2,a0
		return m ? (void *)(m + 1) : 0;
ffffffffc02016c2:	c119                	beqz	a0,ffffffffc02016c8 <slub_check+0x6e>
ffffffffc02016c4:	01050913          	addi	s2,a0,16
		m = slob_alloc(size + SLOB_UNIT);
ffffffffc02016c8:	4549                	li	a0,18
ffffffffc02016ca:	e19ff0ef          	jal	ra,ffffffffc02014e2 <slob_alloc>
ffffffffc02016ce:	84aa                	mv	s1,a0
		return m ? (void *)(m + 1) : 0;
ffffffffc02016d0:	c119                	beqz	a0,ffffffffc02016d6 <slub_check+0x7c>
ffffffffc02016d2:	01050493          	addi	s1,a0,16
    for(slob_t* curr = slobfree->next; curr != slobfree; curr = curr->next)
ffffffffc02016d6:	6018                	ld	a4,0(s0)
    int len = 0;
ffffffffc02016d8:	4581                	li	a1,0
    for(slob_t* curr = slobfree->next; curr != slobfree; curr = curr->next)
ffffffffc02016da:	671c                	ld	a5,8(a4)
ffffffffc02016dc:	00f70663          	beq	a4,a5,ffffffffc02016e8 <slub_check+0x8e>
ffffffffc02016e0:	679c                	ld	a5,8(a5)
        len ++;
ffffffffc02016e2:	2585                	addiw	a1,a1,1
    for(slob_t* curr = slobfree->next; curr != slobfree; curr = curr->next)
ffffffffc02016e4:	fef71ee3          	bne	a4,a5,ffffffffc02016e0 <slub_check+0x86>
    void* p2 = slub_alloc(2);
    void* p3 = slub_alloc(2);
    cprintf("slobfree len: %d\n", slobfree_len());
ffffffffc02016e8:	00001517          	auipc	a0,0x1
ffffffffc02016ec:	21050513          	addi	a0,a0,528 # ffffffffc02028f8 <best_fit_pmm_manager+0x1b8>
ffffffffc02016f0:	9cbfe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    slub_free(p2);
ffffffffc02016f4:	854a                	mv	a0,s2
ffffffffc02016f6:	f11ff0ef          	jal	ra,ffffffffc0201606 <slub_free>
    for(slob_t* curr = slobfree->next; curr != slobfree; curr = curr->next)
ffffffffc02016fa:	6018                	ld	a4,0(s0)
    int len = 0;
ffffffffc02016fc:	4581                	li	a1,0
    for(slob_t* curr = slobfree->next; curr != slobfree; curr = curr->next)
ffffffffc02016fe:	671c                	ld	a5,8(a4)
ffffffffc0201700:	00f70663          	beq	a4,a5,ffffffffc020170c <slub_check+0xb2>
ffffffffc0201704:	679c                	ld	a5,8(a5)
        len ++;
ffffffffc0201706:	2585                	addiw	a1,a1,1
    for(slob_t* curr = slobfree->next; curr != slobfree; curr = curr->next)
ffffffffc0201708:	fef71ee3          	bne	a4,a5,ffffffffc0201704 <slub_check+0xaa>
    cprintf("slobfree len: %d\n", slobfree_len());
ffffffffc020170c:	00001517          	auipc	a0,0x1
ffffffffc0201710:	1ec50513          	addi	a0,a0,492 # ffffffffc02028f8 <best_fit_pmm_manager+0x1b8>
ffffffffc0201714:	9a7fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    slub_free(p3);
ffffffffc0201718:	8526                	mv	a0,s1
ffffffffc020171a:	eedff0ef          	jal	ra,ffffffffc0201606 <slub_free>
    for(slob_t* curr = slobfree->next; curr != slobfree; curr = curr->next)
ffffffffc020171e:	6018                	ld	a4,0(s0)
    int len = 0;
ffffffffc0201720:	4581                	li	a1,0
    for(slob_t* curr = slobfree->next; curr != slobfree; curr = curr->next)
ffffffffc0201722:	671c                	ld	a5,8(a4)
ffffffffc0201724:	00e78663          	beq	a5,a4,ffffffffc0201730 <slub_check+0xd6>
ffffffffc0201728:	679c                	ld	a5,8(a5)
        len ++;
ffffffffc020172a:	2585                	addiw	a1,a1,1
    for(slob_t* curr = slobfree->next; curr != slobfree; curr = curr->next)
ffffffffc020172c:	fef71ee3          	bne	a4,a5,ffffffffc0201728 <slub_check+0xce>
    cprintf("slobfree len: %d\n", slobfree_len());
ffffffffc0201730:	00001517          	auipc	a0,0x1
ffffffffc0201734:	1c850513          	addi	a0,a0,456 # ffffffffc02028f8 <best_fit_pmm_manager+0x1b8>
ffffffffc0201738:	983fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("slub check end\n");
ffffffffc020173c:	6442                	ld	s0,16(sp)
ffffffffc020173e:	60e2                	ld	ra,24(sp)
ffffffffc0201740:	64a2                	ld	s1,8(sp)
ffffffffc0201742:	6902                	ld	s2,0(sp)
    cprintf("slub check end\n");
ffffffffc0201744:	00001517          	auipc	a0,0x1
ffffffffc0201748:	1cc50513          	addi	a0,a0,460 # ffffffffc0202910 <best_fit_pmm_manager+0x1d0>
ffffffffc020174c:	6105                	addi	sp,sp,32
    cprintf("slub check end\n");
ffffffffc020174e:	96dfe06f          	j	ffffffffc02000ba <cprintf>

ffffffffc0201752 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201752:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201756:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201758:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020175c:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020175e:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201762:	f022                	sd	s0,32(sp)
ffffffffc0201764:	ec26                	sd	s1,24(sp)
ffffffffc0201766:	e84a                	sd	s2,16(sp)
ffffffffc0201768:	f406                	sd	ra,40(sp)
ffffffffc020176a:	e44e                	sd	s3,8(sp)
ffffffffc020176c:	84aa                	mv	s1,a0
ffffffffc020176e:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201770:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201774:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201776:	03067e63          	bgeu	a2,a6,ffffffffc02017b2 <printnum+0x60>
ffffffffc020177a:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc020177c:	00805763          	blez	s0,ffffffffc020178a <printnum+0x38>
ffffffffc0201780:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201782:	85ca                	mv	a1,s2
ffffffffc0201784:	854e                	mv	a0,s3
ffffffffc0201786:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201788:	fc65                	bnez	s0,ffffffffc0201780 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020178a:	1a02                	slli	s4,s4,0x20
ffffffffc020178c:	00001797          	auipc	a5,0x1
ffffffffc0201790:	19478793          	addi	a5,a5,404 # ffffffffc0202920 <best_fit_pmm_manager+0x1e0>
ffffffffc0201794:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201798:	9a3e                	add	s4,s4,a5
}
ffffffffc020179a:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020179c:	000a4503          	lbu	a0,0(s4)
}
ffffffffc02017a0:	70a2                	ld	ra,40(sp)
ffffffffc02017a2:	69a2                	ld	s3,8(sp)
ffffffffc02017a4:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02017a6:	85ca                	mv	a1,s2
ffffffffc02017a8:	87a6                	mv	a5,s1
}
ffffffffc02017aa:	6942                	ld	s2,16(sp)
ffffffffc02017ac:	64e2                	ld	s1,24(sp)
ffffffffc02017ae:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02017b0:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02017b2:	03065633          	divu	a2,a2,a6
ffffffffc02017b6:	8722                	mv	a4,s0
ffffffffc02017b8:	f9bff0ef          	jal	ra,ffffffffc0201752 <printnum>
ffffffffc02017bc:	b7f9                	j	ffffffffc020178a <printnum+0x38>

ffffffffc02017be <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02017be:	7119                	addi	sp,sp,-128
ffffffffc02017c0:	f4a6                	sd	s1,104(sp)
ffffffffc02017c2:	f0ca                	sd	s2,96(sp)
ffffffffc02017c4:	ecce                	sd	s3,88(sp)
ffffffffc02017c6:	e8d2                	sd	s4,80(sp)
ffffffffc02017c8:	e4d6                	sd	s5,72(sp)
ffffffffc02017ca:	e0da                	sd	s6,64(sp)
ffffffffc02017cc:	fc5e                	sd	s7,56(sp)
ffffffffc02017ce:	f06a                	sd	s10,32(sp)
ffffffffc02017d0:	fc86                	sd	ra,120(sp)
ffffffffc02017d2:	f8a2                	sd	s0,112(sp)
ffffffffc02017d4:	f862                	sd	s8,48(sp)
ffffffffc02017d6:	f466                	sd	s9,40(sp)
ffffffffc02017d8:	ec6e                	sd	s11,24(sp)
ffffffffc02017da:	892a                	mv	s2,a0
ffffffffc02017dc:	84ae                	mv	s1,a1
ffffffffc02017de:	8d32                	mv	s10,a2
ffffffffc02017e0:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02017e2:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02017e6:	5b7d                	li	s6,-1
ffffffffc02017e8:	00001a97          	auipc	s5,0x1
ffffffffc02017ec:	16ca8a93          	addi	s5,s5,364 # ffffffffc0202954 <best_fit_pmm_manager+0x214>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02017f0:	00001b97          	auipc	s7,0x1
ffffffffc02017f4:	340b8b93          	addi	s7,s7,832 # ffffffffc0202b30 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02017f8:	000d4503          	lbu	a0,0(s10)
ffffffffc02017fc:	001d0413          	addi	s0,s10,1
ffffffffc0201800:	01350a63          	beq	a0,s3,ffffffffc0201814 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0201804:	c121                	beqz	a0,ffffffffc0201844 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0201806:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201808:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc020180a:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020180c:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201810:	ff351ae3          	bne	a0,s3,ffffffffc0201804 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201814:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201818:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc020181c:	4c81                	li	s9,0
ffffffffc020181e:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201820:	5c7d                	li	s8,-1
ffffffffc0201822:	5dfd                	li	s11,-1
ffffffffc0201824:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201828:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020182a:	fdd6059b          	addiw	a1,a2,-35
ffffffffc020182e:	0ff5f593          	zext.b	a1,a1
ffffffffc0201832:	00140d13          	addi	s10,s0,1
ffffffffc0201836:	04b56263          	bltu	a0,a1,ffffffffc020187a <vprintfmt+0xbc>
ffffffffc020183a:	058a                	slli	a1,a1,0x2
ffffffffc020183c:	95d6                	add	a1,a1,s5
ffffffffc020183e:	4194                	lw	a3,0(a1)
ffffffffc0201840:	96d6                	add	a3,a3,s5
ffffffffc0201842:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201844:	70e6                	ld	ra,120(sp)
ffffffffc0201846:	7446                	ld	s0,112(sp)
ffffffffc0201848:	74a6                	ld	s1,104(sp)
ffffffffc020184a:	7906                	ld	s2,96(sp)
ffffffffc020184c:	69e6                	ld	s3,88(sp)
ffffffffc020184e:	6a46                	ld	s4,80(sp)
ffffffffc0201850:	6aa6                	ld	s5,72(sp)
ffffffffc0201852:	6b06                	ld	s6,64(sp)
ffffffffc0201854:	7be2                	ld	s7,56(sp)
ffffffffc0201856:	7c42                	ld	s8,48(sp)
ffffffffc0201858:	7ca2                	ld	s9,40(sp)
ffffffffc020185a:	7d02                	ld	s10,32(sp)
ffffffffc020185c:	6de2                	ld	s11,24(sp)
ffffffffc020185e:	6109                	addi	sp,sp,128
ffffffffc0201860:	8082                	ret
            padc = '0';
ffffffffc0201862:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201864:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201868:	846a                	mv	s0,s10
ffffffffc020186a:	00140d13          	addi	s10,s0,1
ffffffffc020186e:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201872:	0ff5f593          	zext.b	a1,a1
ffffffffc0201876:	fcb572e3          	bgeu	a0,a1,ffffffffc020183a <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc020187a:	85a6                	mv	a1,s1
ffffffffc020187c:	02500513          	li	a0,37
ffffffffc0201880:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201882:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201886:	8d22                	mv	s10,s0
ffffffffc0201888:	f73788e3          	beq	a5,s3,ffffffffc02017f8 <vprintfmt+0x3a>
ffffffffc020188c:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201890:	1d7d                	addi	s10,s10,-1
ffffffffc0201892:	ff379de3          	bne	a5,s3,ffffffffc020188c <vprintfmt+0xce>
ffffffffc0201896:	b78d                	j	ffffffffc02017f8 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201898:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc020189c:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02018a0:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc02018a2:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc02018a6:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02018aa:	02d86463          	bltu	a6,a3,ffffffffc02018d2 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc02018ae:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02018b2:	002c169b          	slliw	a3,s8,0x2
ffffffffc02018b6:	0186873b          	addw	a4,a3,s8
ffffffffc02018ba:	0017171b          	slliw	a4,a4,0x1
ffffffffc02018be:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc02018c0:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02018c4:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02018c6:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc02018ca:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02018ce:	fed870e3          	bgeu	a6,a3,ffffffffc02018ae <vprintfmt+0xf0>
            if (width < 0)
ffffffffc02018d2:	f40ddce3          	bgez	s11,ffffffffc020182a <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc02018d6:	8de2                	mv	s11,s8
ffffffffc02018d8:	5c7d                	li	s8,-1
ffffffffc02018da:	bf81                	j	ffffffffc020182a <vprintfmt+0x6c>
            if (width < 0)
ffffffffc02018dc:	fffdc693          	not	a3,s11
ffffffffc02018e0:	96fd                	srai	a3,a3,0x3f
ffffffffc02018e2:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02018e6:	00144603          	lbu	a2,1(s0)
ffffffffc02018ea:	2d81                	sext.w	s11,s11
ffffffffc02018ec:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02018ee:	bf35                	j	ffffffffc020182a <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc02018f0:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02018f4:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02018f8:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02018fa:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc02018fc:	bfd9                	j	ffffffffc02018d2 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc02018fe:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201900:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201904:	01174463          	blt	a4,a7,ffffffffc020190c <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201908:	1a088e63          	beqz	a7,ffffffffc0201ac4 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc020190c:	000a3603          	ld	a2,0(s4)
ffffffffc0201910:	46c1                	li	a3,16
ffffffffc0201912:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201914:	2781                	sext.w	a5,a5
ffffffffc0201916:	876e                	mv	a4,s11
ffffffffc0201918:	85a6                	mv	a1,s1
ffffffffc020191a:	854a                	mv	a0,s2
ffffffffc020191c:	e37ff0ef          	jal	ra,ffffffffc0201752 <printnum>
            break;
ffffffffc0201920:	bde1                	j	ffffffffc02017f8 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201922:	000a2503          	lw	a0,0(s4)
ffffffffc0201926:	85a6                	mv	a1,s1
ffffffffc0201928:	0a21                	addi	s4,s4,8
ffffffffc020192a:	9902                	jalr	s2
            break;
ffffffffc020192c:	b5f1                	j	ffffffffc02017f8 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020192e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201930:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201934:	01174463          	blt	a4,a7,ffffffffc020193c <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201938:	18088163          	beqz	a7,ffffffffc0201aba <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc020193c:	000a3603          	ld	a2,0(s4)
ffffffffc0201940:	46a9                	li	a3,10
ffffffffc0201942:	8a2e                	mv	s4,a1
ffffffffc0201944:	bfc1                	j	ffffffffc0201914 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201946:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc020194a:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020194c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020194e:	bdf1                	j	ffffffffc020182a <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201950:	85a6                	mv	a1,s1
ffffffffc0201952:	02500513          	li	a0,37
ffffffffc0201956:	9902                	jalr	s2
            break;
ffffffffc0201958:	b545                	j	ffffffffc02017f8 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020195a:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc020195e:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201960:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201962:	b5e1                	j	ffffffffc020182a <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201964:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201966:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020196a:	01174463          	blt	a4,a7,ffffffffc0201972 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc020196e:	14088163          	beqz	a7,ffffffffc0201ab0 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201972:	000a3603          	ld	a2,0(s4)
ffffffffc0201976:	46a1                	li	a3,8
ffffffffc0201978:	8a2e                	mv	s4,a1
ffffffffc020197a:	bf69                	j	ffffffffc0201914 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc020197c:	03000513          	li	a0,48
ffffffffc0201980:	85a6                	mv	a1,s1
ffffffffc0201982:	e03e                	sd	a5,0(sp)
ffffffffc0201984:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201986:	85a6                	mv	a1,s1
ffffffffc0201988:	07800513          	li	a0,120
ffffffffc020198c:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020198e:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201990:	6782                	ld	a5,0(sp)
ffffffffc0201992:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201994:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201998:	bfb5                	j	ffffffffc0201914 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020199a:	000a3403          	ld	s0,0(s4)
ffffffffc020199e:	008a0713          	addi	a4,s4,8
ffffffffc02019a2:	e03a                	sd	a4,0(sp)
ffffffffc02019a4:	14040263          	beqz	s0,ffffffffc0201ae8 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc02019a8:	0fb05763          	blez	s11,ffffffffc0201a96 <vprintfmt+0x2d8>
ffffffffc02019ac:	02d00693          	li	a3,45
ffffffffc02019b0:	0cd79163          	bne	a5,a3,ffffffffc0201a72 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02019b4:	00044783          	lbu	a5,0(s0)
ffffffffc02019b8:	0007851b          	sext.w	a0,a5
ffffffffc02019bc:	cf85                	beqz	a5,ffffffffc02019f4 <vprintfmt+0x236>
ffffffffc02019be:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02019c2:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02019c6:	000c4563          	bltz	s8,ffffffffc02019d0 <vprintfmt+0x212>
ffffffffc02019ca:	3c7d                	addiw	s8,s8,-1
ffffffffc02019cc:	036c0263          	beq	s8,s6,ffffffffc02019f0 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc02019d0:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02019d2:	0e0c8e63          	beqz	s9,ffffffffc0201ace <vprintfmt+0x310>
ffffffffc02019d6:	3781                	addiw	a5,a5,-32
ffffffffc02019d8:	0ef47b63          	bgeu	s0,a5,ffffffffc0201ace <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc02019dc:	03f00513          	li	a0,63
ffffffffc02019e0:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02019e2:	000a4783          	lbu	a5,0(s4)
ffffffffc02019e6:	3dfd                	addiw	s11,s11,-1
ffffffffc02019e8:	0a05                	addi	s4,s4,1
ffffffffc02019ea:	0007851b          	sext.w	a0,a5
ffffffffc02019ee:	ffe1                	bnez	a5,ffffffffc02019c6 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc02019f0:	01b05963          	blez	s11,ffffffffc0201a02 <vprintfmt+0x244>
ffffffffc02019f4:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02019f6:	85a6                	mv	a1,s1
ffffffffc02019f8:	02000513          	li	a0,32
ffffffffc02019fc:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02019fe:	fe0d9be3          	bnez	s11,ffffffffc02019f4 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201a02:	6a02                	ld	s4,0(sp)
ffffffffc0201a04:	bbd5                	j	ffffffffc02017f8 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201a06:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201a08:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201a0c:	01174463          	blt	a4,a7,ffffffffc0201a14 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201a10:	08088d63          	beqz	a7,ffffffffc0201aaa <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201a14:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201a18:	0a044d63          	bltz	s0,ffffffffc0201ad2 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201a1c:	8622                	mv	a2,s0
ffffffffc0201a1e:	8a66                	mv	s4,s9
ffffffffc0201a20:	46a9                	li	a3,10
ffffffffc0201a22:	bdcd                	j	ffffffffc0201914 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201a24:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201a28:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201a2a:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201a2c:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201a30:	8fb5                	xor	a5,a5,a3
ffffffffc0201a32:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201a36:	02d74163          	blt	a4,a3,ffffffffc0201a58 <vprintfmt+0x29a>
ffffffffc0201a3a:	00369793          	slli	a5,a3,0x3
ffffffffc0201a3e:	97de                	add	a5,a5,s7
ffffffffc0201a40:	639c                	ld	a5,0(a5)
ffffffffc0201a42:	cb99                	beqz	a5,ffffffffc0201a58 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201a44:	86be                	mv	a3,a5
ffffffffc0201a46:	00001617          	auipc	a2,0x1
ffffffffc0201a4a:	f0a60613          	addi	a2,a2,-246 # ffffffffc0202950 <best_fit_pmm_manager+0x210>
ffffffffc0201a4e:	85a6                	mv	a1,s1
ffffffffc0201a50:	854a                	mv	a0,s2
ffffffffc0201a52:	0ce000ef          	jal	ra,ffffffffc0201b20 <printfmt>
ffffffffc0201a56:	b34d                	j	ffffffffc02017f8 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201a58:	00001617          	auipc	a2,0x1
ffffffffc0201a5c:	ee860613          	addi	a2,a2,-280 # ffffffffc0202940 <best_fit_pmm_manager+0x200>
ffffffffc0201a60:	85a6                	mv	a1,s1
ffffffffc0201a62:	854a                	mv	a0,s2
ffffffffc0201a64:	0bc000ef          	jal	ra,ffffffffc0201b20 <printfmt>
ffffffffc0201a68:	bb41                	j	ffffffffc02017f8 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201a6a:	00001417          	auipc	s0,0x1
ffffffffc0201a6e:	ece40413          	addi	s0,s0,-306 # ffffffffc0202938 <best_fit_pmm_manager+0x1f8>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201a72:	85e2                	mv	a1,s8
ffffffffc0201a74:	8522                	mv	a0,s0
ffffffffc0201a76:	e43e                	sd	a5,8(sp)
ffffffffc0201a78:	1cc000ef          	jal	ra,ffffffffc0201c44 <strnlen>
ffffffffc0201a7c:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201a80:	01b05b63          	blez	s11,ffffffffc0201a96 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201a84:	67a2                	ld	a5,8(sp)
ffffffffc0201a86:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201a8a:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201a8c:	85a6                	mv	a1,s1
ffffffffc0201a8e:	8552                	mv	a0,s4
ffffffffc0201a90:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201a92:	fe0d9ce3          	bnez	s11,ffffffffc0201a8a <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201a96:	00044783          	lbu	a5,0(s0)
ffffffffc0201a9a:	00140a13          	addi	s4,s0,1
ffffffffc0201a9e:	0007851b          	sext.w	a0,a5
ffffffffc0201aa2:	d3a5                	beqz	a5,ffffffffc0201a02 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201aa4:	05e00413          	li	s0,94
ffffffffc0201aa8:	bf39                	j	ffffffffc02019c6 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201aaa:	000a2403          	lw	s0,0(s4)
ffffffffc0201aae:	b7ad                	j	ffffffffc0201a18 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201ab0:	000a6603          	lwu	a2,0(s4)
ffffffffc0201ab4:	46a1                	li	a3,8
ffffffffc0201ab6:	8a2e                	mv	s4,a1
ffffffffc0201ab8:	bdb1                	j	ffffffffc0201914 <vprintfmt+0x156>
ffffffffc0201aba:	000a6603          	lwu	a2,0(s4)
ffffffffc0201abe:	46a9                	li	a3,10
ffffffffc0201ac0:	8a2e                	mv	s4,a1
ffffffffc0201ac2:	bd89                	j	ffffffffc0201914 <vprintfmt+0x156>
ffffffffc0201ac4:	000a6603          	lwu	a2,0(s4)
ffffffffc0201ac8:	46c1                	li	a3,16
ffffffffc0201aca:	8a2e                	mv	s4,a1
ffffffffc0201acc:	b5a1                	j	ffffffffc0201914 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0201ace:	9902                	jalr	s2
ffffffffc0201ad0:	bf09                	j	ffffffffc02019e2 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201ad2:	85a6                	mv	a1,s1
ffffffffc0201ad4:	02d00513          	li	a0,45
ffffffffc0201ad8:	e03e                	sd	a5,0(sp)
ffffffffc0201ada:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201adc:	6782                	ld	a5,0(sp)
ffffffffc0201ade:	8a66                	mv	s4,s9
ffffffffc0201ae0:	40800633          	neg	a2,s0
ffffffffc0201ae4:	46a9                	li	a3,10
ffffffffc0201ae6:	b53d                	j	ffffffffc0201914 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201ae8:	03b05163          	blez	s11,ffffffffc0201b0a <vprintfmt+0x34c>
ffffffffc0201aec:	02d00693          	li	a3,45
ffffffffc0201af0:	f6d79de3          	bne	a5,a3,ffffffffc0201a6a <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0201af4:	00001417          	auipc	s0,0x1
ffffffffc0201af8:	e4440413          	addi	s0,s0,-444 # ffffffffc0202938 <best_fit_pmm_manager+0x1f8>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201afc:	02800793          	li	a5,40
ffffffffc0201b00:	02800513          	li	a0,40
ffffffffc0201b04:	00140a13          	addi	s4,s0,1
ffffffffc0201b08:	bd6d                	j	ffffffffc02019c2 <vprintfmt+0x204>
ffffffffc0201b0a:	00001a17          	auipc	s4,0x1
ffffffffc0201b0e:	e2fa0a13          	addi	s4,s4,-465 # ffffffffc0202939 <best_fit_pmm_manager+0x1f9>
ffffffffc0201b12:	02800513          	li	a0,40
ffffffffc0201b16:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201b1a:	05e00413          	li	s0,94
ffffffffc0201b1e:	b565                	j	ffffffffc02019c6 <vprintfmt+0x208>

ffffffffc0201b20 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201b20:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201b22:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201b26:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201b28:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201b2a:	ec06                	sd	ra,24(sp)
ffffffffc0201b2c:	f83a                	sd	a4,48(sp)
ffffffffc0201b2e:	fc3e                	sd	a5,56(sp)
ffffffffc0201b30:	e0c2                	sd	a6,64(sp)
ffffffffc0201b32:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201b34:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201b36:	c89ff0ef          	jal	ra,ffffffffc02017be <vprintfmt>
}
ffffffffc0201b3a:	60e2                	ld	ra,24(sp)
ffffffffc0201b3c:	6161                	addi	sp,sp,80
ffffffffc0201b3e:	8082                	ret

ffffffffc0201b40 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201b40:	715d                	addi	sp,sp,-80
ffffffffc0201b42:	e486                	sd	ra,72(sp)
ffffffffc0201b44:	e0a6                	sd	s1,64(sp)
ffffffffc0201b46:	fc4a                	sd	s2,56(sp)
ffffffffc0201b48:	f84e                	sd	s3,48(sp)
ffffffffc0201b4a:	f452                	sd	s4,40(sp)
ffffffffc0201b4c:	f056                	sd	s5,32(sp)
ffffffffc0201b4e:	ec5a                	sd	s6,24(sp)
ffffffffc0201b50:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc0201b52:	c901                	beqz	a0,ffffffffc0201b62 <readline+0x22>
ffffffffc0201b54:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0201b56:	00001517          	auipc	a0,0x1
ffffffffc0201b5a:	dfa50513          	addi	a0,a0,-518 # ffffffffc0202950 <best_fit_pmm_manager+0x210>
ffffffffc0201b5e:	d5cfe0ef          	jal	ra,ffffffffc02000ba <cprintf>
readline(const char *prompt) {
ffffffffc0201b62:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201b64:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201b66:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201b68:	4aa9                	li	s5,10
ffffffffc0201b6a:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0201b6c:	00004b97          	auipc	s7,0x4
ffffffffc0201b70:	4d4b8b93          	addi	s7,s7,1236 # ffffffffc0206040 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201b74:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0201b78:	dbafe0ef          	jal	ra,ffffffffc0200132 <getchar>
        if (c < 0) {
ffffffffc0201b7c:	00054a63          	bltz	a0,ffffffffc0201b90 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201b80:	00a95a63          	bge	s2,a0,ffffffffc0201b94 <readline+0x54>
ffffffffc0201b84:	029a5263          	bge	s4,s1,ffffffffc0201ba8 <readline+0x68>
        c = getchar();
ffffffffc0201b88:	daafe0ef          	jal	ra,ffffffffc0200132 <getchar>
        if (c < 0) {
ffffffffc0201b8c:	fe055ae3          	bgez	a0,ffffffffc0201b80 <readline+0x40>
            return NULL;
ffffffffc0201b90:	4501                	li	a0,0
ffffffffc0201b92:	a091                	j	ffffffffc0201bd6 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0201b94:	03351463          	bne	a0,s3,ffffffffc0201bbc <readline+0x7c>
ffffffffc0201b98:	e8a9                	bnez	s1,ffffffffc0201bea <readline+0xaa>
        c = getchar();
ffffffffc0201b9a:	d98fe0ef          	jal	ra,ffffffffc0200132 <getchar>
        if (c < 0) {
ffffffffc0201b9e:	fe0549e3          	bltz	a0,ffffffffc0201b90 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201ba2:	fea959e3          	bge	s2,a0,ffffffffc0201b94 <readline+0x54>
ffffffffc0201ba6:	4481                	li	s1,0
            cputchar(c);
ffffffffc0201ba8:	e42a                	sd	a0,8(sp)
ffffffffc0201baa:	d46fe0ef          	jal	ra,ffffffffc02000f0 <cputchar>
            buf[i ++] = c;
ffffffffc0201bae:	6522                	ld	a0,8(sp)
ffffffffc0201bb0:	009b87b3          	add	a5,s7,s1
ffffffffc0201bb4:	2485                	addiw	s1,s1,1
ffffffffc0201bb6:	00a78023          	sb	a0,0(a5)
ffffffffc0201bba:	bf7d                	j	ffffffffc0201b78 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0201bbc:	01550463          	beq	a0,s5,ffffffffc0201bc4 <readline+0x84>
ffffffffc0201bc0:	fb651ce3          	bne	a0,s6,ffffffffc0201b78 <readline+0x38>
            cputchar(c);
ffffffffc0201bc4:	d2cfe0ef          	jal	ra,ffffffffc02000f0 <cputchar>
            buf[i] = '\0';
ffffffffc0201bc8:	00004517          	auipc	a0,0x4
ffffffffc0201bcc:	47850513          	addi	a0,a0,1144 # ffffffffc0206040 <buf>
ffffffffc0201bd0:	94aa                	add	s1,s1,a0
ffffffffc0201bd2:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0201bd6:	60a6                	ld	ra,72(sp)
ffffffffc0201bd8:	6486                	ld	s1,64(sp)
ffffffffc0201bda:	7962                	ld	s2,56(sp)
ffffffffc0201bdc:	79c2                	ld	s3,48(sp)
ffffffffc0201bde:	7a22                	ld	s4,40(sp)
ffffffffc0201be0:	7a82                	ld	s5,32(sp)
ffffffffc0201be2:	6b62                	ld	s6,24(sp)
ffffffffc0201be4:	6bc2                	ld	s7,16(sp)
ffffffffc0201be6:	6161                	addi	sp,sp,80
ffffffffc0201be8:	8082                	ret
            cputchar(c);
ffffffffc0201bea:	4521                	li	a0,8
ffffffffc0201bec:	d04fe0ef          	jal	ra,ffffffffc02000f0 <cputchar>
            i --;
ffffffffc0201bf0:	34fd                	addiw	s1,s1,-1
ffffffffc0201bf2:	b759                	j	ffffffffc0201b78 <readline+0x38>

ffffffffc0201bf4 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201bf4:	4781                	li	a5,0
ffffffffc0201bf6:	00004717          	auipc	a4,0x4
ffffffffc0201bfa:	42a73703          	ld	a4,1066(a4) # ffffffffc0206020 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201bfe:	88ba                	mv	a7,a4
ffffffffc0201c00:	852a                	mv	a0,a0
ffffffffc0201c02:	85be                	mv	a1,a5
ffffffffc0201c04:	863e                	mv	a2,a5
ffffffffc0201c06:	00000073          	ecall
ffffffffc0201c0a:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201c0c:	8082                	ret

ffffffffc0201c0e <sbi_set_timer>:
    __asm__ volatile (
ffffffffc0201c0e:	4781                	li	a5,0
ffffffffc0201c10:	00005717          	auipc	a4,0x5
ffffffffc0201c14:	87873703          	ld	a4,-1928(a4) # ffffffffc0206488 <SBI_SET_TIMER>
ffffffffc0201c18:	88ba                	mv	a7,a4
ffffffffc0201c1a:	852a                	mv	a0,a0
ffffffffc0201c1c:	85be                	mv	a1,a5
ffffffffc0201c1e:	863e                	mv	a2,a5
ffffffffc0201c20:	00000073          	ecall
ffffffffc0201c24:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc0201c26:	8082                	ret

ffffffffc0201c28 <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc0201c28:	4501                	li	a0,0
ffffffffc0201c2a:	00004797          	auipc	a5,0x4
ffffffffc0201c2e:	3ee7b783          	ld	a5,1006(a5) # ffffffffc0206018 <SBI_CONSOLE_GETCHAR>
ffffffffc0201c32:	88be                	mv	a7,a5
ffffffffc0201c34:	852a                	mv	a0,a0
ffffffffc0201c36:	85aa                	mv	a1,a0
ffffffffc0201c38:	862a                	mv	a2,a0
ffffffffc0201c3a:	00000073          	ecall
ffffffffc0201c3e:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
ffffffffc0201c40:	2501                	sext.w	a0,a0
ffffffffc0201c42:	8082                	ret

ffffffffc0201c44 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201c44:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201c46:	e589                	bnez	a1,ffffffffc0201c50 <strnlen+0xc>
ffffffffc0201c48:	a811                	j	ffffffffc0201c5c <strnlen+0x18>
        cnt ++;
ffffffffc0201c4a:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201c4c:	00f58863          	beq	a1,a5,ffffffffc0201c5c <strnlen+0x18>
ffffffffc0201c50:	00f50733          	add	a4,a0,a5
ffffffffc0201c54:	00074703          	lbu	a4,0(a4)
ffffffffc0201c58:	fb6d                	bnez	a4,ffffffffc0201c4a <strnlen+0x6>
ffffffffc0201c5a:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201c5c:	852e                	mv	a0,a1
ffffffffc0201c5e:	8082                	ret

ffffffffc0201c60 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201c60:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201c64:	0005c703          	lbu	a4,0(a1) # 1000 <kern_entry-0xffffffffc01ff000>
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201c68:	cb89                	beqz	a5,ffffffffc0201c7a <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201c6a:	0505                	addi	a0,a0,1
ffffffffc0201c6c:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201c6e:	fee789e3          	beq	a5,a4,ffffffffc0201c60 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201c72:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201c76:	9d19                	subw	a0,a0,a4
ffffffffc0201c78:	8082                	ret
ffffffffc0201c7a:	4501                	li	a0,0
ffffffffc0201c7c:	bfed                	j	ffffffffc0201c76 <strcmp+0x16>

ffffffffc0201c7e <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201c7e:	00054783          	lbu	a5,0(a0)
ffffffffc0201c82:	c799                	beqz	a5,ffffffffc0201c90 <strchr+0x12>
        if (*s == c) {
ffffffffc0201c84:	00f58763          	beq	a1,a5,ffffffffc0201c92 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0201c88:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0201c8c:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201c8e:	fbfd                	bnez	a5,ffffffffc0201c84 <strchr+0x6>
    }
    return NULL;
ffffffffc0201c90:	4501                	li	a0,0
}
ffffffffc0201c92:	8082                	ret

ffffffffc0201c94 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201c94:	ca01                	beqz	a2,ffffffffc0201ca4 <memset+0x10>
ffffffffc0201c96:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201c98:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201c9a:	0785                	addi	a5,a5,1
ffffffffc0201c9c:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201ca0:	fec79de3          	bne	a5,a2,ffffffffc0201c9a <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201ca4:	8082                	ret
