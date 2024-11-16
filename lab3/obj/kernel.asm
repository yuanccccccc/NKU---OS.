
bin/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c02092b7          	lui	t0,0xc0209
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc0200004:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200008:	01e31313          	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc020000c:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200010:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc0200014:	fff0031b          	addiw	t1,zero,-1
ffffffffc0200018:	03f31313          	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc020001c:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200020:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200024:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc0200028:	c0209137          	lui	sp,0xc0209

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc020002c:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200030:	03628293          	addi	t0,t0,54 # ffffffffc0200036 <kern_init>
    jr t0
ffffffffc0200034:	8282                	jr	t0

ffffffffc0200036 <kern_init>:


int
kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200036:	0000a517          	auipc	a0,0xa
ffffffffc020003a:	00a50513          	addi	a0,a0,10 # ffffffffc020a040 <edata>
ffffffffc020003e:	00011617          	auipc	a2,0x11
ffffffffc0200042:	56260613          	addi	a2,a2,1378 # ffffffffc02115a0 <end>
kern_init(void) {
ffffffffc0200046:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200048:	8e09                	sub	a2,a2,a0
ffffffffc020004a:	4581                	li	a1,0
kern_init(void) {
ffffffffc020004c:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004e:	5fb030ef          	jal	ra,ffffffffc0203e48 <memset>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc0200052:	00004597          	auipc	a1,0x4
ffffffffc0200056:	2ce58593          	addi	a1,a1,718 # ffffffffc0204320 <etext+0x4>
ffffffffc020005a:	00004517          	auipc	a0,0x4
ffffffffc020005e:	2e650513          	addi	a0,a0,742 # ffffffffc0204340 <etext+0x24>
ffffffffc0200062:	05c000ef          	jal	ra,ffffffffc02000be <cprintf>

    print_kerninfo();
ffffffffc0200066:	0fe000ef          	jal	ra,ffffffffc0200164 <print_kerninfo>

    // grade_backtrace();

    pmm_init();                 // init physical memory management
ffffffffc020006a:	711000ef          	jal	ra,ffffffffc0200f7a <pmm_init>

    idt_init();                 // init interrupt descriptor table
ffffffffc020006e:	4fc000ef          	jal	ra,ffffffffc020056a <idt_init>

    vmm_init();                 // init virtual memory management
ffffffffc0200072:	5d9010ef          	jal	ra,ffffffffc0201e4a <vmm_init>

    ide_init();                 // init ide devices
ffffffffc0200076:	35a000ef          	jal	ra,ffffffffc02003d0 <ide_init>
    swap_init();                // init swap
ffffffffc020007a:	3e2020ef          	jal	ra,ffffffffc020245c <swap_init>

    clock_init();               // init clock interrupt
ffffffffc020007e:	3aa000ef          	jal	ra,ffffffffc0200428 <clock_init>
    // intr_enable();              // enable irq interrupt



    /* do nothing */
    while (1);
ffffffffc0200082:	a001                	j	ffffffffc0200082 <kern_init+0x4c>

ffffffffc0200084 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200084:	1141                	addi	sp,sp,-16
ffffffffc0200086:	e022                	sd	s0,0(sp)
ffffffffc0200088:	e406                	sd	ra,8(sp)
ffffffffc020008a:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020008c:	3f0000ef          	jal	ra,ffffffffc020047c <cons_putc>
    (*cnt) ++;
ffffffffc0200090:	401c                	lw	a5,0(s0)
}
ffffffffc0200092:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200094:	2785                	addiw	a5,a5,1
ffffffffc0200096:	c01c                	sw	a5,0(s0)
}
ffffffffc0200098:	6402                	ld	s0,0(sp)
ffffffffc020009a:	0141                	addi	sp,sp,16
ffffffffc020009c:	8082                	ret

ffffffffc020009e <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020009e:	1101                	addi	sp,sp,-32
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000a0:	86ae                	mv	a3,a1
ffffffffc02000a2:	862a                	mv	a2,a0
ffffffffc02000a4:	006c                	addi	a1,sp,12
ffffffffc02000a6:	00000517          	auipc	a0,0x0
ffffffffc02000aa:	fde50513          	addi	a0,a0,-34 # ffffffffc0200084 <cputch>
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000ae:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000b0:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000b2:	62d030ef          	jal	ra,ffffffffc0203ede <vprintfmt>
    return cnt;
}
ffffffffc02000b6:	60e2                	ld	ra,24(sp)
ffffffffc02000b8:	4532                	lw	a0,12(sp)
ffffffffc02000ba:	6105                	addi	sp,sp,32
ffffffffc02000bc:	8082                	ret

ffffffffc02000be <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000be:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000c0:	02810313          	addi	t1,sp,40 # ffffffffc0209028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000c4:	f42e                	sd	a1,40(sp)
ffffffffc02000c6:	f832                	sd	a2,48(sp)
ffffffffc02000c8:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000ca:	862a                	mv	a2,a0
ffffffffc02000cc:	004c                	addi	a1,sp,4
ffffffffc02000ce:	00000517          	auipc	a0,0x0
ffffffffc02000d2:	fb650513          	addi	a0,a0,-74 # ffffffffc0200084 <cputch>
ffffffffc02000d6:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc02000d8:	ec06                	sd	ra,24(sp)
ffffffffc02000da:	e0ba                	sd	a4,64(sp)
ffffffffc02000dc:	e4be                	sd	a5,72(sp)
ffffffffc02000de:	e8c2                	sd	a6,80(sp)
ffffffffc02000e0:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000e2:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000e4:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000e6:	5f9030ef          	jal	ra,ffffffffc0203ede <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02000ea:	60e2                	ld	ra,24(sp)
ffffffffc02000ec:	4512                	lw	a0,4(sp)
ffffffffc02000ee:	6125                	addi	sp,sp,96
ffffffffc02000f0:	8082                	ret

ffffffffc02000f2 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02000f2:	a669                	j	ffffffffc020047c <cons_putc>

ffffffffc02000f4 <getchar>:
    return cnt;
}

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc02000f4:	1141                	addi	sp,sp,-16
ffffffffc02000f6:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc02000f8:	3b8000ef          	jal	ra,ffffffffc02004b0 <cons_getc>
ffffffffc02000fc:	dd75                	beqz	a0,ffffffffc02000f8 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc02000fe:	60a2                	ld	ra,8(sp)
ffffffffc0200100:	0141                	addi	sp,sp,16
ffffffffc0200102:	8082                	ret

ffffffffc0200104 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200104:	00011317          	auipc	t1,0x11
ffffffffc0200108:	33c30313          	addi	t1,t1,828 # ffffffffc0211440 <is_panic>
ffffffffc020010c:	00032303          	lw	t1,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200110:	715d                	addi	sp,sp,-80
ffffffffc0200112:	ec06                	sd	ra,24(sp)
ffffffffc0200114:	e822                	sd	s0,16(sp)
ffffffffc0200116:	f436                	sd	a3,40(sp)
ffffffffc0200118:	f83a                	sd	a4,48(sp)
ffffffffc020011a:	fc3e                	sd	a5,56(sp)
ffffffffc020011c:	e0c2                	sd	a6,64(sp)
ffffffffc020011e:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc0200120:	02031c63          	bnez	t1,ffffffffc0200158 <__panic+0x54>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200124:	4785                	li	a5,1
ffffffffc0200126:	8432                	mv	s0,a2
ffffffffc0200128:	00011717          	auipc	a4,0x11
ffffffffc020012c:	30f72c23          	sw	a5,792(a4) # ffffffffc0211440 <is_panic>

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200130:	862e                	mv	a2,a1
    va_start(ap, fmt);
ffffffffc0200132:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200134:	85aa                	mv	a1,a0
ffffffffc0200136:	00004517          	auipc	a0,0x4
ffffffffc020013a:	21250513          	addi	a0,a0,530 # ffffffffc0204348 <etext+0x2c>
    va_start(ap, fmt);
ffffffffc020013e:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200140:	f7fff0ef          	jal	ra,ffffffffc02000be <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200144:	65a2                	ld	a1,8(sp)
ffffffffc0200146:	8522                	mv	a0,s0
ffffffffc0200148:	f57ff0ef          	jal	ra,ffffffffc020009e <vcprintf>
    cprintf("\n");
ffffffffc020014c:	00005517          	auipc	a0,0x5
ffffffffc0200150:	01450513          	addi	a0,a0,20 # ffffffffc0205160 <commands+0xcf8>
ffffffffc0200154:	f6bff0ef          	jal	ra,ffffffffc02000be <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc0200158:	39a000ef          	jal	ra,ffffffffc02004f2 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc020015c:	4501                	li	a0,0
ffffffffc020015e:	130000ef          	jal	ra,ffffffffc020028e <kmonitor>
ffffffffc0200162:	bfed                	j	ffffffffc020015c <__panic+0x58>

ffffffffc0200164 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200164:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200166:	00004517          	auipc	a0,0x4
ffffffffc020016a:	23250513          	addi	a0,a0,562 # ffffffffc0204398 <etext+0x7c>
void print_kerninfo(void) {
ffffffffc020016e:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200170:	f4fff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc0200174:	00000597          	auipc	a1,0x0
ffffffffc0200178:	ec258593          	addi	a1,a1,-318 # ffffffffc0200036 <kern_init>
ffffffffc020017c:	00004517          	auipc	a0,0x4
ffffffffc0200180:	23c50513          	addi	a0,a0,572 # ffffffffc02043b8 <etext+0x9c>
ffffffffc0200184:	f3bff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200188:	00004597          	auipc	a1,0x4
ffffffffc020018c:	19458593          	addi	a1,a1,404 # ffffffffc020431c <etext>
ffffffffc0200190:	00004517          	auipc	a0,0x4
ffffffffc0200194:	24850513          	addi	a0,a0,584 # ffffffffc02043d8 <etext+0xbc>
ffffffffc0200198:	f27ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc020019c:	0000a597          	auipc	a1,0xa
ffffffffc02001a0:	ea458593          	addi	a1,a1,-348 # ffffffffc020a040 <edata>
ffffffffc02001a4:	00004517          	auipc	a0,0x4
ffffffffc02001a8:	25450513          	addi	a0,a0,596 # ffffffffc02043f8 <etext+0xdc>
ffffffffc02001ac:	f13ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc02001b0:	00011597          	auipc	a1,0x11
ffffffffc02001b4:	3f058593          	addi	a1,a1,1008 # ffffffffc02115a0 <end>
ffffffffc02001b8:	00004517          	auipc	a0,0x4
ffffffffc02001bc:	26050513          	addi	a0,a0,608 # ffffffffc0204418 <etext+0xfc>
ffffffffc02001c0:	effff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc02001c4:	00011597          	auipc	a1,0x11
ffffffffc02001c8:	7db58593          	addi	a1,a1,2011 # ffffffffc021199f <end+0x3ff>
ffffffffc02001cc:	00000797          	auipc	a5,0x0
ffffffffc02001d0:	e6a78793          	addi	a5,a5,-406 # ffffffffc0200036 <kern_init>
ffffffffc02001d4:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001d8:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001dc:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001de:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001e2:	95be                	add	a1,a1,a5
ffffffffc02001e4:	85a9                	srai	a1,a1,0xa
ffffffffc02001e6:	00004517          	auipc	a0,0x4
ffffffffc02001ea:	25250513          	addi	a0,a0,594 # ffffffffc0204438 <etext+0x11c>
}
ffffffffc02001ee:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001f0:	b5f9                	j	ffffffffc02000be <cprintf>

ffffffffc02001f2 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001f2:	1141                	addi	sp,sp,-16

    panic("Not Implemented!");
ffffffffc02001f4:	00004617          	auipc	a2,0x4
ffffffffc02001f8:	17460613          	addi	a2,a2,372 # ffffffffc0204368 <etext+0x4c>
ffffffffc02001fc:	04e00593          	li	a1,78
ffffffffc0200200:	00004517          	auipc	a0,0x4
ffffffffc0200204:	18050513          	addi	a0,a0,384 # ffffffffc0204380 <etext+0x64>
void print_stackframe(void) {
ffffffffc0200208:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc020020a:	efbff0ef          	jal	ra,ffffffffc0200104 <__panic>

ffffffffc020020e <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc020020e:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200210:	00004617          	auipc	a2,0x4
ffffffffc0200214:	33060613          	addi	a2,a2,816 # ffffffffc0204540 <commands+0xd8>
ffffffffc0200218:	00004597          	auipc	a1,0x4
ffffffffc020021c:	34858593          	addi	a1,a1,840 # ffffffffc0204560 <commands+0xf8>
ffffffffc0200220:	00004517          	auipc	a0,0x4
ffffffffc0200224:	34850513          	addi	a0,a0,840 # ffffffffc0204568 <commands+0x100>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200228:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020022a:	e95ff0ef          	jal	ra,ffffffffc02000be <cprintf>
ffffffffc020022e:	00004617          	auipc	a2,0x4
ffffffffc0200232:	34a60613          	addi	a2,a2,842 # ffffffffc0204578 <commands+0x110>
ffffffffc0200236:	00004597          	auipc	a1,0x4
ffffffffc020023a:	36a58593          	addi	a1,a1,874 # ffffffffc02045a0 <commands+0x138>
ffffffffc020023e:	00004517          	auipc	a0,0x4
ffffffffc0200242:	32a50513          	addi	a0,a0,810 # ffffffffc0204568 <commands+0x100>
ffffffffc0200246:	e79ff0ef          	jal	ra,ffffffffc02000be <cprintf>
ffffffffc020024a:	00004617          	auipc	a2,0x4
ffffffffc020024e:	36660613          	addi	a2,a2,870 # ffffffffc02045b0 <commands+0x148>
ffffffffc0200252:	00004597          	auipc	a1,0x4
ffffffffc0200256:	37e58593          	addi	a1,a1,894 # ffffffffc02045d0 <commands+0x168>
ffffffffc020025a:	00004517          	auipc	a0,0x4
ffffffffc020025e:	30e50513          	addi	a0,a0,782 # ffffffffc0204568 <commands+0x100>
ffffffffc0200262:	e5dff0ef          	jal	ra,ffffffffc02000be <cprintf>
    }
    return 0;
}
ffffffffc0200266:	60a2                	ld	ra,8(sp)
ffffffffc0200268:	4501                	li	a0,0
ffffffffc020026a:	0141                	addi	sp,sp,16
ffffffffc020026c:	8082                	ret

ffffffffc020026e <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc020026e:	1141                	addi	sp,sp,-16
ffffffffc0200270:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200272:	ef3ff0ef          	jal	ra,ffffffffc0200164 <print_kerninfo>
    return 0;
}
ffffffffc0200276:	60a2                	ld	ra,8(sp)
ffffffffc0200278:	4501                	li	a0,0
ffffffffc020027a:	0141                	addi	sp,sp,16
ffffffffc020027c:	8082                	ret

ffffffffc020027e <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc020027e:	1141                	addi	sp,sp,-16
ffffffffc0200280:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200282:	f71ff0ef          	jal	ra,ffffffffc02001f2 <print_stackframe>
    return 0;
}
ffffffffc0200286:	60a2                	ld	ra,8(sp)
ffffffffc0200288:	4501                	li	a0,0
ffffffffc020028a:	0141                	addi	sp,sp,16
ffffffffc020028c:	8082                	ret

ffffffffc020028e <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc020028e:	7115                	addi	sp,sp,-224
ffffffffc0200290:	e962                	sd	s8,144(sp)
ffffffffc0200292:	8c2a                	mv	s8,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200294:	00004517          	auipc	a0,0x4
ffffffffc0200298:	21c50513          	addi	a0,a0,540 # ffffffffc02044b0 <commands+0x48>
kmonitor(struct trapframe *tf) {
ffffffffc020029c:	ed86                	sd	ra,216(sp)
ffffffffc020029e:	e9a2                	sd	s0,208(sp)
ffffffffc02002a0:	e5a6                	sd	s1,200(sp)
ffffffffc02002a2:	e1ca                	sd	s2,192(sp)
ffffffffc02002a4:	fd4e                	sd	s3,184(sp)
ffffffffc02002a6:	f952                	sd	s4,176(sp)
ffffffffc02002a8:	f556                	sd	s5,168(sp)
ffffffffc02002aa:	f15a                	sd	s6,160(sp)
ffffffffc02002ac:	ed5e                	sd	s7,152(sp)
ffffffffc02002ae:	e566                	sd	s9,136(sp)
ffffffffc02002b0:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002b2:	e0dff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc02002b6:	00004517          	auipc	a0,0x4
ffffffffc02002ba:	22250513          	addi	a0,a0,546 # ffffffffc02044d8 <commands+0x70>
ffffffffc02002be:	e01ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    if (tf != NULL) {
ffffffffc02002c2:	000c0563          	beqz	s8,ffffffffc02002cc <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002c6:	8562                	mv	a0,s8
ffffffffc02002c8:	48c000ef          	jal	ra,ffffffffc0200754 <print_trapframe>
ffffffffc02002cc:	00004c97          	auipc	s9,0x4
ffffffffc02002d0:	19cc8c93          	addi	s9,s9,412 # ffffffffc0204468 <commands>
        if ((buf = readline("")) != NULL) {
ffffffffc02002d4:	00005997          	auipc	s3,0x5
ffffffffc02002d8:	6e498993          	addi	s3,s3,1764 # ffffffffc02059b8 <commands+0x1550>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002dc:	00004917          	auipc	s2,0x4
ffffffffc02002e0:	22490913          	addi	s2,s2,548 # ffffffffc0204500 <commands+0x98>
        if (argc == MAXARGS - 1) {
ffffffffc02002e4:	4a3d                	li	s4,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002e6:	00004b17          	auipc	s6,0x4
ffffffffc02002ea:	222b0b13          	addi	s6,s6,546 # ffffffffc0204508 <commands+0xa0>
    if (argc == 0) {
ffffffffc02002ee:	00004a97          	auipc	s5,0x4
ffffffffc02002f2:	272a8a93          	addi	s5,s5,626 # ffffffffc0204560 <commands+0xf8>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002f6:	4b8d                	li	s7,3
        if ((buf = readline("")) != NULL) {
ffffffffc02002f8:	854e                	mv	a0,s3
ffffffffc02002fa:	765030ef          	jal	ra,ffffffffc020425e <readline>
ffffffffc02002fe:	842a                	mv	s0,a0
ffffffffc0200300:	dd65                	beqz	a0,ffffffffc02002f8 <kmonitor+0x6a>
ffffffffc0200302:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc0200306:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200308:	c999                	beqz	a1,ffffffffc020031e <kmonitor+0x90>
ffffffffc020030a:	854a                	mv	a0,s2
ffffffffc020030c:	31f030ef          	jal	ra,ffffffffc0203e2a <strchr>
ffffffffc0200310:	c925                	beqz	a0,ffffffffc0200380 <kmonitor+0xf2>
            *buf ++ = '\0';
ffffffffc0200312:	00144583          	lbu	a1,1(s0)
ffffffffc0200316:	00040023          	sb	zero,0(s0)
ffffffffc020031a:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020031c:	f5fd                	bnez	a1,ffffffffc020030a <kmonitor+0x7c>
    if (argc == 0) {
ffffffffc020031e:	dce9                	beqz	s1,ffffffffc02002f8 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200320:	6582                	ld	a1,0(sp)
ffffffffc0200322:	00004d17          	auipc	s10,0x4
ffffffffc0200326:	146d0d13          	addi	s10,s10,326 # ffffffffc0204468 <commands>
    if (argc == 0) {
ffffffffc020032a:	8556                	mv	a0,s5
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020032c:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020032e:	0d61                	addi	s10,s10,24
ffffffffc0200330:	2d1030ef          	jal	ra,ffffffffc0203e00 <strcmp>
ffffffffc0200334:	c919                	beqz	a0,ffffffffc020034a <kmonitor+0xbc>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200336:	2405                	addiw	s0,s0,1
ffffffffc0200338:	09740463          	beq	s0,s7,ffffffffc02003c0 <kmonitor+0x132>
ffffffffc020033c:	000d3503          	ld	a0,0(s10)
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200340:	6582                	ld	a1,0(sp)
ffffffffc0200342:	0d61                	addi	s10,s10,24
ffffffffc0200344:	2bd030ef          	jal	ra,ffffffffc0203e00 <strcmp>
ffffffffc0200348:	f57d                	bnez	a0,ffffffffc0200336 <kmonitor+0xa8>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc020034a:	00141793          	slli	a5,s0,0x1
ffffffffc020034e:	97a2                	add	a5,a5,s0
ffffffffc0200350:	078e                	slli	a5,a5,0x3
ffffffffc0200352:	97e6                	add	a5,a5,s9
ffffffffc0200354:	6b9c                	ld	a5,16(a5)
ffffffffc0200356:	8662                	mv	a2,s8
ffffffffc0200358:	002c                	addi	a1,sp,8
ffffffffc020035a:	fff4851b          	addiw	a0,s1,-1
ffffffffc020035e:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200360:	f8055ce3          	bgez	a0,ffffffffc02002f8 <kmonitor+0x6a>
}
ffffffffc0200364:	60ee                	ld	ra,216(sp)
ffffffffc0200366:	644e                	ld	s0,208(sp)
ffffffffc0200368:	64ae                	ld	s1,200(sp)
ffffffffc020036a:	690e                	ld	s2,192(sp)
ffffffffc020036c:	79ea                	ld	s3,184(sp)
ffffffffc020036e:	7a4a                	ld	s4,176(sp)
ffffffffc0200370:	7aaa                	ld	s5,168(sp)
ffffffffc0200372:	7b0a                	ld	s6,160(sp)
ffffffffc0200374:	6bea                	ld	s7,152(sp)
ffffffffc0200376:	6c4a                	ld	s8,144(sp)
ffffffffc0200378:	6caa                	ld	s9,136(sp)
ffffffffc020037a:	6d0a                	ld	s10,128(sp)
ffffffffc020037c:	612d                	addi	sp,sp,224
ffffffffc020037e:	8082                	ret
        if (*buf == '\0') {
ffffffffc0200380:	00044783          	lbu	a5,0(s0)
ffffffffc0200384:	dfc9                	beqz	a5,ffffffffc020031e <kmonitor+0x90>
        if (argc == MAXARGS - 1) {
ffffffffc0200386:	03448863          	beq	s1,s4,ffffffffc02003b6 <kmonitor+0x128>
        argv[argc ++] = buf;
ffffffffc020038a:	00349793          	slli	a5,s1,0x3
ffffffffc020038e:	0118                	addi	a4,sp,128
ffffffffc0200390:	97ba                	add	a5,a5,a4
ffffffffc0200392:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200396:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc020039a:	2485                	addiw	s1,s1,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020039c:	e591                	bnez	a1,ffffffffc02003a8 <kmonitor+0x11a>
ffffffffc020039e:	b749                	j	ffffffffc0200320 <kmonitor+0x92>
            buf ++;
ffffffffc02003a0:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003a2:	00044583          	lbu	a1,0(s0)
ffffffffc02003a6:	ddad                	beqz	a1,ffffffffc0200320 <kmonitor+0x92>
ffffffffc02003a8:	854a                	mv	a0,s2
ffffffffc02003aa:	281030ef          	jal	ra,ffffffffc0203e2a <strchr>
ffffffffc02003ae:	d96d                	beqz	a0,ffffffffc02003a0 <kmonitor+0x112>
ffffffffc02003b0:	00044583          	lbu	a1,0(s0)
ffffffffc02003b4:	bf91                	j	ffffffffc0200308 <kmonitor+0x7a>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003b6:	45c1                	li	a1,16
ffffffffc02003b8:	855a                	mv	a0,s6
ffffffffc02003ba:	d05ff0ef          	jal	ra,ffffffffc02000be <cprintf>
ffffffffc02003be:	b7f1                	j	ffffffffc020038a <kmonitor+0xfc>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02003c0:	6582                	ld	a1,0(sp)
ffffffffc02003c2:	00004517          	auipc	a0,0x4
ffffffffc02003c6:	16650513          	addi	a0,a0,358 # ffffffffc0204528 <commands+0xc0>
ffffffffc02003ca:	cf5ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    return 0;
ffffffffc02003ce:	b72d                	j	ffffffffc02002f8 <kmonitor+0x6a>

ffffffffc02003d0 <ide_init>:
#include <stdio.h>
#include <string.h>
#include <trap.h>
#include <riscv.h>

void ide_init(void) {}
ffffffffc02003d0:	8082                	ret

ffffffffc02003d2 <ide_device_valid>:

#define MAX_IDE 2
#define MAX_DISK_NSECS 56
static char ide[MAX_DISK_NSECS * SECTSIZE];

bool ide_device_valid(unsigned short ideno) { return ideno < MAX_IDE; }
ffffffffc02003d2:	00253513          	sltiu	a0,a0,2
ffffffffc02003d6:	8082                	ret

ffffffffc02003d8 <ide_device_size>:

size_t ide_device_size(unsigned short ideno) { return MAX_DISK_NSECS; }
ffffffffc02003d8:	03800513          	li	a0,56
ffffffffc02003dc:	8082                	ret

ffffffffc02003de <ide_read_secs>:

int ide_read_secs(unsigned short ideno, uint32_t secno, void *dst,
                  size_t nsecs) {
    int iobase = secno * SECTSIZE;
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc02003de:	0000a797          	auipc	a5,0xa
ffffffffc02003e2:	c6278793          	addi	a5,a5,-926 # ffffffffc020a040 <edata>
ffffffffc02003e6:	0095959b          	slliw	a1,a1,0x9
                  size_t nsecs) {
ffffffffc02003ea:	1141                	addi	sp,sp,-16
ffffffffc02003ec:	8532                	mv	a0,a2
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc02003ee:	95be                	add	a1,a1,a5
ffffffffc02003f0:	00969613          	slli	a2,a3,0x9
                  size_t nsecs) {
ffffffffc02003f4:	e406                	sd	ra,8(sp)
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc02003f6:	265030ef          	jal	ra,ffffffffc0203e5a <memcpy>
    return 0;
}
ffffffffc02003fa:	60a2                	ld	ra,8(sp)
ffffffffc02003fc:	4501                	li	a0,0
ffffffffc02003fe:	0141                	addi	sp,sp,16
ffffffffc0200400:	8082                	ret

ffffffffc0200402 <ide_write_secs>:

int ide_write_secs(unsigned short ideno, uint32_t secno, const void *src,
                   size_t nsecs) {
ffffffffc0200402:	8732                	mv	a4,a2
    int iobase = secno * SECTSIZE;
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc0200404:	0095979b          	slliw	a5,a1,0x9
ffffffffc0200408:	0000a517          	auipc	a0,0xa
ffffffffc020040c:	c3850513          	addi	a0,a0,-968 # ffffffffc020a040 <edata>
                   size_t nsecs) {
ffffffffc0200410:	1141                	addi	sp,sp,-16
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc0200412:	00969613          	slli	a2,a3,0x9
ffffffffc0200416:	85ba                	mv	a1,a4
ffffffffc0200418:	953e                	add	a0,a0,a5
                   size_t nsecs) {
ffffffffc020041a:	e406                	sd	ra,8(sp)
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc020041c:	23f030ef          	jal	ra,ffffffffc0203e5a <memcpy>
    return 0;
}
ffffffffc0200420:	60a2                	ld	ra,8(sp)
ffffffffc0200422:	4501                	li	a0,0
ffffffffc0200424:	0141                	addi	sp,sp,16
ffffffffc0200426:	8082                	ret

ffffffffc0200428 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc0200428:	67e1                	lui	a5,0x18
ffffffffc020042a:	6a078793          	addi	a5,a5,1696 # 186a0 <BASE_ADDRESS-0xffffffffc01e7960>
ffffffffc020042e:	00011717          	auipc	a4,0x11
ffffffffc0200432:	00f73d23          	sd	a5,26(a4) # ffffffffc0211448 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200436:	c0102573          	rdtime	a0
static inline void sbi_set_timer(uint64_t stime_value)
{
#if __riscv_xlen == 32
	SBI_CALL_2(SBI_SET_TIMER, stime_value, stime_value >> 32);
#else
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc020043a:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020043c:	953e                	add	a0,a0,a5
ffffffffc020043e:	4601                	li	a2,0
ffffffffc0200440:	4881                	li	a7,0
ffffffffc0200442:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200446:	02000793          	li	a5,32
ffffffffc020044a:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc020044e:	00004517          	auipc	a0,0x4
ffffffffc0200452:	19250513          	addi	a0,a0,402 # ffffffffc02045e0 <commands+0x178>
    ticks = 0;
ffffffffc0200456:	00011797          	auipc	a5,0x11
ffffffffc020045a:	0207b123          	sd	zero,34(a5) # ffffffffc0211478 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020045e:	b185                	j	ffffffffc02000be <cprintf>

ffffffffc0200460 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200460:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200464:	00011797          	auipc	a5,0x11
ffffffffc0200468:	fe478793          	addi	a5,a5,-28 # ffffffffc0211448 <timebase>
ffffffffc020046c:	639c                	ld	a5,0(a5)
ffffffffc020046e:	4581                	li	a1,0
ffffffffc0200470:	4601                	li	a2,0
ffffffffc0200472:	953e                	add	a0,a0,a5
ffffffffc0200474:	4881                	li	a7,0
ffffffffc0200476:	00000073          	ecall
ffffffffc020047a:	8082                	ret

ffffffffc020047c <cons_putc>:
#include <intr.h>
#include <mmu.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020047c:	100027f3          	csrr	a5,sstatus
ffffffffc0200480:	8b89                	andi	a5,a5,2
ffffffffc0200482:	0ff57513          	andi	a0,a0,255
ffffffffc0200486:	e799                	bnez	a5,ffffffffc0200494 <cons_putc+0x18>
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200488:	4581                	li	a1,0
ffffffffc020048a:	4601                	li	a2,0
ffffffffc020048c:	4885                	li	a7,1
ffffffffc020048e:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc0200492:	8082                	ret

/* cons_init - initializes the console devices */
void cons_init(void) {}

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc0200494:	1101                	addi	sp,sp,-32
ffffffffc0200496:	ec06                	sd	ra,24(sp)
ffffffffc0200498:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020049a:	058000ef          	jal	ra,ffffffffc02004f2 <intr_disable>
ffffffffc020049e:	6522                	ld	a0,8(sp)
ffffffffc02004a0:	4581                	li	a1,0
ffffffffc02004a2:	4601                	li	a2,0
ffffffffc02004a4:	4885                	li	a7,1
ffffffffc02004a6:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02004aa:	60e2                	ld	ra,24(sp)
ffffffffc02004ac:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02004ae:	a83d                	j	ffffffffc02004ec <intr_enable>

ffffffffc02004b0 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02004b0:	100027f3          	csrr	a5,sstatus
ffffffffc02004b4:	8b89                	andi	a5,a5,2
ffffffffc02004b6:	eb89                	bnez	a5,ffffffffc02004c8 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc02004b8:	4501                	li	a0,0
ffffffffc02004ba:	4581                	li	a1,0
ffffffffc02004bc:	4601                	li	a2,0
ffffffffc02004be:	4889                	li	a7,2
ffffffffc02004c0:	00000073          	ecall
ffffffffc02004c4:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc02004c6:	8082                	ret
int cons_getc(void) {
ffffffffc02004c8:	1101                	addi	sp,sp,-32
ffffffffc02004ca:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc02004cc:	026000ef          	jal	ra,ffffffffc02004f2 <intr_disable>
ffffffffc02004d0:	4501                	li	a0,0
ffffffffc02004d2:	4581                	li	a1,0
ffffffffc02004d4:	4601                	li	a2,0
ffffffffc02004d6:	4889                	li	a7,2
ffffffffc02004d8:	00000073          	ecall
ffffffffc02004dc:	2501                	sext.w	a0,a0
ffffffffc02004de:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02004e0:	00c000ef          	jal	ra,ffffffffc02004ec <intr_enable>
}
ffffffffc02004e4:	60e2                	ld	ra,24(sp)
ffffffffc02004e6:	6522                	ld	a0,8(sp)
ffffffffc02004e8:	6105                	addi	sp,sp,32
ffffffffc02004ea:	8082                	ret

ffffffffc02004ec <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02004ec:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02004f0:	8082                	ret

ffffffffc02004f2 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02004f2:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02004f6:	8082                	ret

ffffffffc02004f8 <pgfault_handler>:
    set_csr(sstatus, SSTATUS_SUM);
}

/* trap_in_kernel - test if trap happened in kernel */
bool trap_in_kernel(struct trapframe *tf) {
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02004f8:	10053783          	ld	a5,256(a0)
    cprintf("page fault at 0x%08x: %c/%c\n", tf->badvaddr,
            trap_in_kernel(tf) ? 'K' : 'U',
            tf->cause == CAUSE_STORE_PAGE_FAULT ? 'W' : 'R');
}

static int pgfault_handler(struct trapframe *tf) {
ffffffffc02004fc:	1141                	addi	sp,sp,-16
ffffffffc02004fe:	e022                	sd	s0,0(sp)
ffffffffc0200500:	e406                	sd	ra,8(sp)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200502:	1007f793          	andi	a5,a5,256
static int pgfault_handler(struct trapframe *tf) {
ffffffffc0200506:	842a                	mv	s0,a0
    cprintf("page fault at 0x%08x: %c/%c\n", tf->badvaddr,
ffffffffc0200508:	11053583          	ld	a1,272(a0)
ffffffffc020050c:	05500613          	li	a2,85
ffffffffc0200510:	c399                	beqz	a5,ffffffffc0200516 <pgfault_handler+0x1e>
ffffffffc0200512:	04b00613          	li	a2,75
ffffffffc0200516:	11843703          	ld	a4,280(s0)
ffffffffc020051a:	47bd                	li	a5,15
ffffffffc020051c:	05700693          	li	a3,87
ffffffffc0200520:	00f70463          	beq	a4,a5,ffffffffc0200528 <pgfault_handler+0x30>
ffffffffc0200524:	05200693          	li	a3,82
ffffffffc0200528:	00004517          	auipc	a0,0x4
ffffffffc020052c:	3b050513          	addi	a0,a0,944 # ffffffffc02048d8 <commands+0x470>
ffffffffc0200530:	b8fff0ef          	jal	ra,ffffffffc02000be <cprintf>
    extern struct mm_struct *check_mm_struct;
    print_pgfault(tf);
    if (check_mm_struct != NULL) {
ffffffffc0200534:	00011797          	auipc	a5,0x11
ffffffffc0200538:	f8478793          	addi	a5,a5,-124 # ffffffffc02114b8 <check_mm_struct>
ffffffffc020053c:	6388                	ld	a0,0(a5)
ffffffffc020053e:	c911                	beqz	a0,ffffffffc0200552 <pgfault_handler+0x5a>
        return do_pgfault(check_mm_struct, tf->cause, tf->badvaddr);
ffffffffc0200540:	11043603          	ld	a2,272(s0)
ffffffffc0200544:	11843583          	ld	a1,280(s0)
    }
    panic("unhandled page fault.\n");
}
ffffffffc0200548:	6402                	ld	s0,0(sp)
ffffffffc020054a:	60a2                	ld	ra,8(sp)
ffffffffc020054c:	0141                	addi	sp,sp,16
        return do_pgfault(check_mm_struct, tf->cause, tf->badvaddr);
ffffffffc020054e:	63b0106f          	j	ffffffffc0202388 <do_pgfault>
    panic("unhandled page fault.\n");
ffffffffc0200552:	00004617          	auipc	a2,0x4
ffffffffc0200556:	3a660613          	addi	a2,a2,934 # ffffffffc02048f8 <commands+0x490>
ffffffffc020055a:	07800593          	li	a1,120
ffffffffc020055e:	00004517          	auipc	a0,0x4
ffffffffc0200562:	3b250513          	addi	a0,a0,946 # ffffffffc0204910 <commands+0x4a8>
ffffffffc0200566:	b9fff0ef          	jal	ra,ffffffffc0200104 <__panic>

ffffffffc020056a <idt_init>:
    write_csr(sscratch, 0);
ffffffffc020056a:	14005073          	csrwi	sscratch,0
    write_csr(stvec, &__alltraps);
ffffffffc020056e:	00000797          	auipc	a5,0x0
ffffffffc0200572:	48278793          	addi	a5,a5,1154 # ffffffffc02009f0 <__alltraps>
ffffffffc0200576:	10579073          	csrw	stvec,a5
    set_csr(sstatus, SSTATUS_SIE);
ffffffffc020057a:	100167f3          	csrrsi	a5,sstatus,2
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc020057e:	000407b7          	lui	a5,0x40
ffffffffc0200582:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc0200586:	8082                	ret

ffffffffc0200588 <print_regs>:
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200588:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc020058a:	1141                	addi	sp,sp,-16
ffffffffc020058c:	e022                	sd	s0,0(sp)
ffffffffc020058e:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200590:	00004517          	auipc	a0,0x4
ffffffffc0200594:	39850513          	addi	a0,a0,920 # ffffffffc0204928 <commands+0x4c0>
void print_regs(struct pushregs *gpr) {
ffffffffc0200598:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020059a:	b25ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020059e:	640c                	ld	a1,8(s0)
ffffffffc02005a0:	00004517          	auipc	a0,0x4
ffffffffc02005a4:	3a050513          	addi	a0,a0,928 # ffffffffc0204940 <commands+0x4d8>
ffffffffc02005a8:	b17ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02005ac:	680c                	ld	a1,16(s0)
ffffffffc02005ae:	00004517          	auipc	a0,0x4
ffffffffc02005b2:	3aa50513          	addi	a0,a0,938 # ffffffffc0204958 <commands+0x4f0>
ffffffffc02005b6:	b09ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02005ba:	6c0c                	ld	a1,24(s0)
ffffffffc02005bc:	00004517          	auipc	a0,0x4
ffffffffc02005c0:	3b450513          	addi	a0,a0,948 # ffffffffc0204970 <commands+0x508>
ffffffffc02005c4:	afbff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02005c8:	700c                	ld	a1,32(s0)
ffffffffc02005ca:	00004517          	auipc	a0,0x4
ffffffffc02005ce:	3be50513          	addi	a0,a0,958 # ffffffffc0204988 <commands+0x520>
ffffffffc02005d2:	aedff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02005d6:	740c                	ld	a1,40(s0)
ffffffffc02005d8:	00004517          	auipc	a0,0x4
ffffffffc02005dc:	3c850513          	addi	a0,a0,968 # ffffffffc02049a0 <commands+0x538>
ffffffffc02005e0:	adfff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02005e4:	780c                	ld	a1,48(s0)
ffffffffc02005e6:	00004517          	auipc	a0,0x4
ffffffffc02005ea:	3d250513          	addi	a0,a0,978 # ffffffffc02049b8 <commands+0x550>
ffffffffc02005ee:	ad1ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02005f2:	7c0c                	ld	a1,56(s0)
ffffffffc02005f4:	00004517          	auipc	a0,0x4
ffffffffc02005f8:	3dc50513          	addi	a0,a0,988 # ffffffffc02049d0 <commands+0x568>
ffffffffc02005fc:	ac3ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200600:	602c                	ld	a1,64(s0)
ffffffffc0200602:	00004517          	auipc	a0,0x4
ffffffffc0200606:	3e650513          	addi	a0,a0,998 # ffffffffc02049e8 <commands+0x580>
ffffffffc020060a:	ab5ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc020060e:	642c                	ld	a1,72(s0)
ffffffffc0200610:	00004517          	auipc	a0,0x4
ffffffffc0200614:	3f050513          	addi	a0,a0,1008 # ffffffffc0204a00 <commands+0x598>
ffffffffc0200618:	aa7ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc020061c:	682c                	ld	a1,80(s0)
ffffffffc020061e:	00004517          	auipc	a0,0x4
ffffffffc0200622:	3fa50513          	addi	a0,a0,1018 # ffffffffc0204a18 <commands+0x5b0>
ffffffffc0200626:	a99ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc020062a:	6c2c                	ld	a1,88(s0)
ffffffffc020062c:	00004517          	auipc	a0,0x4
ffffffffc0200630:	40450513          	addi	a0,a0,1028 # ffffffffc0204a30 <commands+0x5c8>
ffffffffc0200634:	a8bff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200638:	702c                	ld	a1,96(s0)
ffffffffc020063a:	00004517          	auipc	a0,0x4
ffffffffc020063e:	40e50513          	addi	a0,a0,1038 # ffffffffc0204a48 <commands+0x5e0>
ffffffffc0200642:	a7dff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200646:	742c                	ld	a1,104(s0)
ffffffffc0200648:	00004517          	auipc	a0,0x4
ffffffffc020064c:	41850513          	addi	a0,a0,1048 # ffffffffc0204a60 <commands+0x5f8>
ffffffffc0200650:	a6fff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200654:	782c                	ld	a1,112(s0)
ffffffffc0200656:	00004517          	auipc	a0,0x4
ffffffffc020065a:	42250513          	addi	a0,a0,1058 # ffffffffc0204a78 <commands+0x610>
ffffffffc020065e:	a61ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200662:	7c2c                	ld	a1,120(s0)
ffffffffc0200664:	00004517          	auipc	a0,0x4
ffffffffc0200668:	42c50513          	addi	a0,a0,1068 # ffffffffc0204a90 <commands+0x628>
ffffffffc020066c:	a53ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200670:	604c                	ld	a1,128(s0)
ffffffffc0200672:	00004517          	auipc	a0,0x4
ffffffffc0200676:	43650513          	addi	a0,a0,1078 # ffffffffc0204aa8 <commands+0x640>
ffffffffc020067a:	a45ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc020067e:	644c                	ld	a1,136(s0)
ffffffffc0200680:	00004517          	auipc	a0,0x4
ffffffffc0200684:	44050513          	addi	a0,a0,1088 # ffffffffc0204ac0 <commands+0x658>
ffffffffc0200688:	a37ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc020068c:	684c                	ld	a1,144(s0)
ffffffffc020068e:	00004517          	auipc	a0,0x4
ffffffffc0200692:	44a50513          	addi	a0,a0,1098 # ffffffffc0204ad8 <commands+0x670>
ffffffffc0200696:	a29ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc020069a:	6c4c                	ld	a1,152(s0)
ffffffffc020069c:	00004517          	auipc	a0,0x4
ffffffffc02006a0:	45450513          	addi	a0,a0,1108 # ffffffffc0204af0 <commands+0x688>
ffffffffc02006a4:	a1bff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc02006a8:	704c                	ld	a1,160(s0)
ffffffffc02006aa:	00004517          	auipc	a0,0x4
ffffffffc02006ae:	45e50513          	addi	a0,a0,1118 # ffffffffc0204b08 <commands+0x6a0>
ffffffffc02006b2:	a0dff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02006b6:	744c                	ld	a1,168(s0)
ffffffffc02006b8:	00004517          	auipc	a0,0x4
ffffffffc02006bc:	46850513          	addi	a0,a0,1128 # ffffffffc0204b20 <commands+0x6b8>
ffffffffc02006c0:	9ffff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02006c4:	784c                	ld	a1,176(s0)
ffffffffc02006c6:	00004517          	auipc	a0,0x4
ffffffffc02006ca:	47250513          	addi	a0,a0,1138 # ffffffffc0204b38 <commands+0x6d0>
ffffffffc02006ce:	9f1ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02006d2:	7c4c                	ld	a1,184(s0)
ffffffffc02006d4:	00004517          	auipc	a0,0x4
ffffffffc02006d8:	47c50513          	addi	a0,a0,1148 # ffffffffc0204b50 <commands+0x6e8>
ffffffffc02006dc:	9e3ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02006e0:	606c                	ld	a1,192(s0)
ffffffffc02006e2:	00004517          	auipc	a0,0x4
ffffffffc02006e6:	48650513          	addi	a0,a0,1158 # ffffffffc0204b68 <commands+0x700>
ffffffffc02006ea:	9d5ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02006ee:	646c                	ld	a1,200(s0)
ffffffffc02006f0:	00004517          	auipc	a0,0x4
ffffffffc02006f4:	49050513          	addi	a0,a0,1168 # ffffffffc0204b80 <commands+0x718>
ffffffffc02006f8:	9c7ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02006fc:	686c                	ld	a1,208(s0)
ffffffffc02006fe:	00004517          	auipc	a0,0x4
ffffffffc0200702:	49a50513          	addi	a0,a0,1178 # ffffffffc0204b98 <commands+0x730>
ffffffffc0200706:	9b9ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc020070a:	6c6c                	ld	a1,216(s0)
ffffffffc020070c:	00004517          	auipc	a0,0x4
ffffffffc0200710:	4a450513          	addi	a0,a0,1188 # ffffffffc0204bb0 <commands+0x748>
ffffffffc0200714:	9abff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200718:	706c                	ld	a1,224(s0)
ffffffffc020071a:	00004517          	auipc	a0,0x4
ffffffffc020071e:	4ae50513          	addi	a0,a0,1198 # ffffffffc0204bc8 <commands+0x760>
ffffffffc0200722:	99dff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200726:	746c                	ld	a1,232(s0)
ffffffffc0200728:	00004517          	auipc	a0,0x4
ffffffffc020072c:	4b850513          	addi	a0,a0,1208 # ffffffffc0204be0 <commands+0x778>
ffffffffc0200730:	98fff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200734:	786c                	ld	a1,240(s0)
ffffffffc0200736:	00004517          	auipc	a0,0x4
ffffffffc020073a:	4c250513          	addi	a0,a0,1218 # ffffffffc0204bf8 <commands+0x790>
ffffffffc020073e:	981ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200742:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200744:	6402                	ld	s0,0(sp)
ffffffffc0200746:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200748:	00004517          	auipc	a0,0x4
ffffffffc020074c:	4c850513          	addi	a0,a0,1224 # ffffffffc0204c10 <commands+0x7a8>
}
ffffffffc0200750:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200752:	b2b5                	j	ffffffffc02000be <cprintf>

ffffffffc0200754 <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc0200754:	1141                	addi	sp,sp,-16
ffffffffc0200756:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200758:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc020075a:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc020075c:	00004517          	auipc	a0,0x4
ffffffffc0200760:	4cc50513          	addi	a0,a0,1228 # ffffffffc0204c28 <commands+0x7c0>
void print_trapframe(struct trapframe *tf) {
ffffffffc0200764:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200766:	959ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    print_regs(&tf->gpr);
ffffffffc020076a:	8522                	mv	a0,s0
ffffffffc020076c:	e1dff0ef          	jal	ra,ffffffffc0200588 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200770:	10043583          	ld	a1,256(s0)
ffffffffc0200774:	00004517          	auipc	a0,0x4
ffffffffc0200778:	4cc50513          	addi	a0,a0,1228 # ffffffffc0204c40 <commands+0x7d8>
ffffffffc020077c:	943ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200780:	10843583          	ld	a1,264(s0)
ffffffffc0200784:	00004517          	auipc	a0,0x4
ffffffffc0200788:	4d450513          	addi	a0,a0,1236 # ffffffffc0204c58 <commands+0x7f0>
ffffffffc020078c:	933ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200790:	11043583          	ld	a1,272(s0)
ffffffffc0200794:	00004517          	auipc	a0,0x4
ffffffffc0200798:	4dc50513          	addi	a0,a0,1244 # ffffffffc0204c70 <commands+0x808>
ffffffffc020079c:	923ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02007a0:	11843583          	ld	a1,280(s0)
}
ffffffffc02007a4:	6402                	ld	s0,0(sp)
ffffffffc02007a6:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02007a8:	00004517          	auipc	a0,0x4
ffffffffc02007ac:	4e050513          	addi	a0,a0,1248 # ffffffffc0204c88 <commands+0x820>
}
ffffffffc02007b0:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02007b2:	90dff06f          	j	ffffffffc02000be <cprintf>

ffffffffc02007b6 <interrupt_handler>:

static volatile int in_swap_tick_event = 0;
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc02007b6:	11853783          	ld	a5,280(a0)
    switch (cause) {
ffffffffc02007ba:	472d                	li	a4,11
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc02007bc:	0786                	slli	a5,a5,0x1
ffffffffc02007be:	8385                	srli	a5,a5,0x1
    switch (cause) {
ffffffffc02007c0:	06f76f63          	bltu	a4,a5,ffffffffc020083e <interrupt_handler+0x88>
ffffffffc02007c4:	00004717          	auipc	a4,0x4
ffffffffc02007c8:	e3870713          	addi	a4,a4,-456 # ffffffffc02045fc <commands+0x194>
ffffffffc02007cc:	078a                	slli	a5,a5,0x2
ffffffffc02007ce:	97ba                	add	a5,a5,a4
ffffffffc02007d0:	439c                	lw	a5,0(a5)
ffffffffc02007d2:	97ba                	add	a5,a5,a4
ffffffffc02007d4:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02007d6:	00004517          	auipc	a0,0x4
ffffffffc02007da:	0b250513          	addi	a0,a0,178 # ffffffffc0204888 <commands+0x420>
ffffffffc02007de:	8e1ff06f          	j	ffffffffc02000be <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02007e2:	00004517          	auipc	a0,0x4
ffffffffc02007e6:	08650513          	addi	a0,a0,134 # ffffffffc0204868 <commands+0x400>
ffffffffc02007ea:	8d5ff06f          	j	ffffffffc02000be <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02007ee:	00004517          	auipc	a0,0x4
ffffffffc02007f2:	03a50513          	addi	a0,a0,58 # ffffffffc0204828 <commands+0x3c0>
ffffffffc02007f6:	8c9ff06f          	j	ffffffffc02000be <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc02007fa:	00004517          	auipc	a0,0x4
ffffffffc02007fe:	04e50513          	addi	a0,a0,78 # ffffffffc0204848 <commands+0x3e0>
ffffffffc0200802:	8bdff06f          	j	ffffffffc02000be <cprintf>
            break;
        case IRQ_U_EXT:
            cprintf("User software interrupt\n");
            break;
        case IRQ_S_EXT:
            cprintf("Supervisor external interrupt\n");
ffffffffc0200806:	00004517          	auipc	a0,0x4
ffffffffc020080a:	0b250513          	addi	a0,a0,178 # ffffffffc02048b8 <commands+0x450>
ffffffffc020080e:	8b1ff06f          	j	ffffffffc02000be <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200812:	1141                	addi	sp,sp,-16
ffffffffc0200814:	e406                	sd	ra,8(sp)
            clock_set_next_event();
ffffffffc0200816:	c4bff0ef          	jal	ra,ffffffffc0200460 <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc020081a:	00011797          	auipc	a5,0x11
ffffffffc020081e:	c5e78793          	addi	a5,a5,-930 # ffffffffc0211478 <ticks>
ffffffffc0200822:	639c                	ld	a5,0(a5)
ffffffffc0200824:	06400713          	li	a4,100
ffffffffc0200828:	0785                	addi	a5,a5,1
ffffffffc020082a:	02e7f733          	remu	a4,a5,a4
ffffffffc020082e:	00011697          	auipc	a3,0x11
ffffffffc0200832:	c4f6b523          	sd	a5,-950(a3) # ffffffffc0211478 <ticks>
ffffffffc0200836:	c709                	beqz	a4,ffffffffc0200840 <interrupt_handler+0x8a>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200838:	60a2                	ld	ra,8(sp)
ffffffffc020083a:	0141                	addi	sp,sp,16
ffffffffc020083c:	8082                	ret
            print_trapframe(tf);
ffffffffc020083e:	bf19                	j	ffffffffc0200754 <print_trapframe>
}
ffffffffc0200840:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200842:	06400593          	li	a1,100
ffffffffc0200846:	00004517          	auipc	a0,0x4
ffffffffc020084a:	06250513          	addi	a0,a0,98 # ffffffffc02048a8 <commands+0x440>
}
ffffffffc020084e:	0141                	addi	sp,sp,16
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200850:	86fff06f          	j	ffffffffc02000be <cprintf>

ffffffffc0200854 <exception_handler>:


void exception_handler(struct trapframe *tf) {
    int ret;
    switch (tf->cause) {
ffffffffc0200854:	11853783          	ld	a5,280(a0)
ffffffffc0200858:	473d                	li	a4,15
ffffffffc020085a:	16f76463          	bltu	a4,a5,ffffffffc02009c2 <exception_handler+0x16e>
ffffffffc020085e:	00004717          	auipc	a4,0x4
ffffffffc0200862:	dce70713          	addi	a4,a4,-562 # ffffffffc020462c <commands+0x1c4>
ffffffffc0200866:	078a                	slli	a5,a5,0x2
ffffffffc0200868:	97ba                	add	a5,a5,a4
ffffffffc020086a:	439c                	lw	a5,0(a5)
void exception_handler(struct trapframe *tf) {
ffffffffc020086c:	1101                	addi	sp,sp,-32
ffffffffc020086e:	e822                	sd	s0,16(sp)
ffffffffc0200870:	ec06                	sd	ra,24(sp)
ffffffffc0200872:	e426                	sd	s1,8(sp)
    switch (tf->cause) {
ffffffffc0200874:	97ba                	add	a5,a5,a4
ffffffffc0200876:	842a                	mv	s0,a0
ffffffffc0200878:	8782                	jr	a5
                print_trapframe(tf);
                panic("handle pgfault failed. %e\n", ret);
            }
            break;
        case CAUSE_STORE_PAGE_FAULT:
            cprintf("Store/AMO page fault\n");
ffffffffc020087a:	00004517          	auipc	a0,0x4
ffffffffc020087e:	f9650513          	addi	a0,a0,-106 # ffffffffc0204810 <commands+0x3a8>
ffffffffc0200882:	83dff0ef          	jal	ra,ffffffffc02000be <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200886:	8522                	mv	a0,s0
ffffffffc0200888:	c71ff0ef          	jal	ra,ffffffffc02004f8 <pgfault_handler>
ffffffffc020088c:	84aa                	mv	s1,a0
ffffffffc020088e:	12051b63          	bnez	a0,ffffffffc02009c4 <exception_handler+0x170>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200892:	60e2                	ld	ra,24(sp)
ffffffffc0200894:	6442                	ld	s0,16(sp)
ffffffffc0200896:	64a2                	ld	s1,8(sp)
ffffffffc0200898:	6105                	addi	sp,sp,32
ffffffffc020089a:	8082                	ret
            cprintf("Instruction address misaligned\n");
ffffffffc020089c:	00004517          	auipc	a0,0x4
ffffffffc02008a0:	dd450513          	addi	a0,a0,-556 # ffffffffc0204670 <commands+0x208>
}
ffffffffc02008a4:	6442                	ld	s0,16(sp)
ffffffffc02008a6:	60e2                	ld	ra,24(sp)
ffffffffc02008a8:	64a2                	ld	s1,8(sp)
ffffffffc02008aa:	6105                	addi	sp,sp,32
            cprintf("Instruction access fault\n");
ffffffffc02008ac:	813ff06f          	j	ffffffffc02000be <cprintf>
ffffffffc02008b0:	00004517          	auipc	a0,0x4
ffffffffc02008b4:	de050513          	addi	a0,a0,-544 # ffffffffc0204690 <commands+0x228>
ffffffffc02008b8:	b7f5                	j	ffffffffc02008a4 <exception_handler+0x50>
            cprintf("Illegal instruction\n");
ffffffffc02008ba:	00004517          	auipc	a0,0x4
ffffffffc02008be:	df650513          	addi	a0,a0,-522 # ffffffffc02046b0 <commands+0x248>
ffffffffc02008c2:	b7cd                	j	ffffffffc02008a4 <exception_handler+0x50>
            cprintf("Breakpoint\n");
ffffffffc02008c4:	00004517          	auipc	a0,0x4
ffffffffc02008c8:	e0450513          	addi	a0,a0,-508 # ffffffffc02046c8 <commands+0x260>
ffffffffc02008cc:	bfe1                	j	ffffffffc02008a4 <exception_handler+0x50>
            cprintf("Load address misaligned\n");
ffffffffc02008ce:	00004517          	auipc	a0,0x4
ffffffffc02008d2:	e0a50513          	addi	a0,a0,-502 # ffffffffc02046d8 <commands+0x270>
ffffffffc02008d6:	b7f9                	j	ffffffffc02008a4 <exception_handler+0x50>
            cprintf("Load access fault\n");
ffffffffc02008d8:	00004517          	auipc	a0,0x4
ffffffffc02008dc:	e2050513          	addi	a0,a0,-480 # ffffffffc02046f8 <commands+0x290>
ffffffffc02008e0:	fdeff0ef          	jal	ra,ffffffffc02000be <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc02008e4:	8522                	mv	a0,s0
ffffffffc02008e6:	c13ff0ef          	jal	ra,ffffffffc02004f8 <pgfault_handler>
ffffffffc02008ea:	84aa                	mv	s1,a0
ffffffffc02008ec:	d15d                	beqz	a0,ffffffffc0200892 <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc02008ee:	8522                	mv	a0,s0
ffffffffc02008f0:	e65ff0ef          	jal	ra,ffffffffc0200754 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc02008f4:	86a6                	mv	a3,s1
ffffffffc02008f6:	00004617          	auipc	a2,0x4
ffffffffc02008fa:	e1a60613          	addi	a2,a2,-486 # ffffffffc0204710 <commands+0x2a8>
ffffffffc02008fe:	0ca00593          	li	a1,202
ffffffffc0200902:	00004517          	auipc	a0,0x4
ffffffffc0200906:	00e50513          	addi	a0,a0,14 # ffffffffc0204910 <commands+0x4a8>
ffffffffc020090a:	ffaff0ef          	jal	ra,ffffffffc0200104 <__panic>
            cprintf("AMO address misaligned\n");
ffffffffc020090e:	00004517          	auipc	a0,0x4
ffffffffc0200912:	e2250513          	addi	a0,a0,-478 # ffffffffc0204730 <commands+0x2c8>
ffffffffc0200916:	b779                	j	ffffffffc02008a4 <exception_handler+0x50>
            cprintf("Store/AMO access fault\n");
ffffffffc0200918:	00004517          	auipc	a0,0x4
ffffffffc020091c:	e3050513          	addi	a0,a0,-464 # ffffffffc0204748 <commands+0x2e0>
ffffffffc0200920:	f9eff0ef          	jal	ra,ffffffffc02000be <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200924:	8522                	mv	a0,s0
ffffffffc0200926:	bd3ff0ef          	jal	ra,ffffffffc02004f8 <pgfault_handler>
ffffffffc020092a:	84aa                	mv	s1,a0
ffffffffc020092c:	d13d                	beqz	a0,ffffffffc0200892 <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc020092e:	8522                	mv	a0,s0
ffffffffc0200930:	e25ff0ef          	jal	ra,ffffffffc0200754 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200934:	86a6                	mv	a3,s1
ffffffffc0200936:	00004617          	auipc	a2,0x4
ffffffffc020093a:	dda60613          	addi	a2,a2,-550 # ffffffffc0204710 <commands+0x2a8>
ffffffffc020093e:	0d400593          	li	a1,212
ffffffffc0200942:	00004517          	auipc	a0,0x4
ffffffffc0200946:	fce50513          	addi	a0,a0,-50 # ffffffffc0204910 <commands+0x4a8>
ffffffffc020094a:	fbaff0ef          	jal	ra,ffffffffc0200104 <__panic>
            cprintf("Environment call from U-mode\n");
ffffffffc020094e:	00004517          	auipc	a0,0x4
ffffffffc0200952:	e1250513          	addi	a0,a0,-494 # ffffffffc0204760 <commands+0x2f8>
ffffffffc0200956:	b7b9                	j	ffffffffc02008a4 <exception_handler+0x50>
            cprintf("Environment call from S-mode\n");
ffffffffc0200958:	00004517          	auipc	a0,0x4
ffffffffc020095c:	e2850513          	addi	a0,a0,-472 # ffffffffc0204780 <commands+0x318>
ffffffffc0200960:	b791                	j	ffffffffc02008a4 <exception_handler+0x50>
            cprintf("Environment call from H-mode\n");
ffffffffc0200962:	00004517          	auipc	a0,0x4
ffffffffc0200966:	e3e50513          	addi	a0,a0,-450 # ffffffffc02047a0 <commands+0x338>
ffffffffc020096a:	bf2d                	j	ffffffffc02008a4 <exception_handler+0x50>
            cprintf("Environment call from M-mode\n");
ffffffffc020096c:	00004517          	auipc	a0,0x4
ffffffffc0200970:	e5450513          	addi	a0,a0,-428 # ffffffffc02047c0 <commands+0x358>
ffffffffc0200974:	bf05                	j	ffffffffc02008a4 <exception_handler+0x50>
            cprintf("Instruction page fault\n");
ffffffffc0200976:	00004517          	auipc	a0,0x4
ffffffffc020097a:	e6a50513          	addi	a0,a0,-406 # ffffffffc02047e0 <commands+0x378>
ffffffffc020097e:	b71d                	j	ffffffffc02008a4 <exception_handler+0x50>
            cprintf("Load page fault\n");
ffffffffc0200980:	00004517          	auipc	a0,0x4
ffffffffc0200984:	e7850513          	addi	a0,a0,-392 # ffffffffc02047f8 <commands+0x390>
ffffffffc0200988:	f36ff0ef          	jal	ra,ffffffffc02000be <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc020098c:	8522                	mv	a0,s0
ffffffffc020098e:	b6bff0ef          	jal	ra,ffffffffc02004f8 <pgfault_handler>
ffffffffc0200992:	84aa                	mv	s1,a0
ffffffffc0200994:	ee050fe3          	beqz	a0,ffffffffc0200892 <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc0200998:	8522                	mv	a0,s0
ffffffffc020099a:	dbbff0ef          	jal	ra,ffffffffc0200754 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc020099e:	86a6                	mv	a3,s1
ffffffffc02009a0:	00004617          	auipc	a2,0x4
ffffffffc02009a4:	d7060613          	addi	a2,a2,-656 # ffffffffc0204710 <commands+0x2a8>
ffffffffc02009a8:	0ea00593          	li	a1,234
ffffffffc02009ac:	00004517          	auipc	a0,0x4
ffffffffc02009b0:	f6450513          	addi	a0,a0,-156 # ffffffffc0204910 <commands+0x4a8>
ffffffffc02009b4:	f50ff0ef          	jal	ra,ffffffffc0200104 <__panic>
}
ffffffffc02009b8:	6442                	ld	s0,16(sp)
ffffffffc02009ba:	60e2                	ld	ra,24(sp)
ffffffffc02009bc:	64a2                	ld	s1,8(sp)
ffffffffc02009be:	6105                	addi	sp,sp,32
            print_trapframe(tf);
ffffffffc02009c0:	bb51                	j	ffffffffc0200754 <print_trapframe>
ffffffffc02009c2:	bb49                	j	ffffffffc0200754 <print_trapframe>
                print_trapframe(tf);
ffffffffc02009c4:	8522                	mv	a0,s0
ffffffffc02009c6:	d8fff0ef          	jal	ra,ffffffffc0200754 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc02009ca:	86a6                	mv	a3,s1
ffffffffc02009cc:	00004617          	auipc	a2,0x4
ffffffffc02009d0:	d4460613          	addi	a2,a2,-700 # ffffffffc0204710 <commands+0x2a8>
ffffffffc02009d4:	0f100593          	li	a1,241
ffffffffc02009d8:	00004517          	auipc	a0,0x4
ffffffffc02009dc:	f3850513          	addi	a0,a0,-200 # ffffffffc0204910 <commands+0x4a8>
ffffffffc02009e0:	f24ff0ef          	jal	ra,ffffffffc0200104 <__panic>

ffffffffc02009e4 <trap>:
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    if ((intptr_t)tf->cause < 0) {
ffffffffc02009e4:	11853783          	ld	a5,280(a0)
ffffffffc02009e8:	0007c363          	bltz	a5,ffffffffc02009ee <trap+0xa>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
ffffffffc02009ec:	b5a5                	j	ffffffffc0200854 <exception_handler>
        interrupt_handler(tf);
ffffffffc02009ee:	b3e1                	j	ffffffffc02007b6 <interrupt_handler>

ffffffffc02009f0 <__alltraps>:
    .endm

    .align 4
    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc02009f0:	14011073          	csrw	sscratch,sp
ffffffffc02009f4:	712d                	addi	sp,sp,-288
ffffffffc02009f6:	e406                	sd	ra,8(sp)
ffffffffc02009f8:	ec0e                	sd	gp,24(sp)
ffffffffc02009fa:	f012                	sd	tp,32(sp)
ffffffffc02009fc:	f416                	sd	t0,40(sp)
ffffffffc02009fe:	f81a                	sd	t1,48(sp)
ffffffffc0200a00:	fc1e                	sd	t2,56(sp)
ffffffffc0200a02:	e0a2                	sd	s0,64(sp)
ffffffffc0200a04:	e4a6                	sd	s1,72(sp)
ffffffffc0200a06:	e8aa                	sd	a0,80(sp)
ffffffffc0200a08:	ecae                	sd	a1,88(sp)
ffffffffc0200a0a:	f0b2                	sd	a2,96(sp)
ffffffffc0200a0c:	f4b6                	sd	a3,104(sp)
ffffffffc0200a0e:	f8ba                	sd	a4,112(sp)
ffffffffc0200a10:	fcbe                	sd	a5,120(sp)
ffffffffc0200a12:	e142                	sd	a6,128(sp)
ffffffffc0200a14:	e546                	sd	a7,136(sp)
ffffffffc0200a16:	e94a                	sd	s2,144(sp)
ffffffffc0200a18:	ed4e                	sd	s3,152(sp)
ffffffffc0200a1a:	f152                	sd	s4,160(sp)
ffffffffc0200a1c:	f556                	sd	s5,168(sp)
ffffffffc0200a1e:	f95a                	sd	s6,176(sp)
ffffffffc0200a20:	fd5e                	sd	s7,184(sp)
ffffffffc0200a22:	e1e2                	sd	s8,192(sp)
ffffffffc0200a24:	e5e6                	sd	s9,200(sp)
ffffffffc0200a26:	e9ea                	sd	s10,208(sp)
ffffffffc0200a28:	edee                	sd	s11,216(sp)
ffffffffc0200a2a:	f1f2                	sd	t3,224(sp)
ffffffffc0200a2c:	f5f6                	sd	t4,232(sp)
ffffffffc0200a2e:	f9fa                	sd	t5,240(sp)
ffffffffc0200a30:	fdfe                	sd	t6,248(sp)
ffffffffc0200a32:	14002473          	csrr	s0,sscratch
ffffffffc0200a36:	100024f3          	csrr	s1,sstatus
ffffffffc0200a3a:	14102973          	csrr	s2,sepc
ffffffffc0200a3e:	143029f3          	csrr	s3,stval
ffffffffc0200a42:	14202a73          	csrr	s4,scause
ffffffffc0200a46:	e822                	sd	s0,16(sp)
ffffffffc0200a48:	e226                	sd	s1,256(sp)
ffffffffc0200a4a:	e64a                	sd	s2,264(sp)
ffffffffc0200a4c:	ea4e                	sd	s3,272(sp)
ffffffffc0200a4e:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200a50:	850a                	mv	a0,sp
    jal trap
ffffffffc0200a52:	f93ff0ef          	jal	ra,ffffffffc02009e4 <trap>

ffffffffc0200a56 <__trapret>:
    // sp should be the same as before "jal trap"
    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200a56:	6492                	ld	s1,256(sp)
ffffffffc0200a58:	6932                	ld	s2,264(sp)
ffffffffc0200a5a:	10049073          	csrw	sstatus,s1
ffffffffc0200a5e:	14191073          	csrw	sepc,s2
ffffffffc0200a62:	60a2                	ld	ra,8(sp)
ffffffffc0200a64:	61e2                	ld	gp,24(sp)
ffffffffc0200a66:	7202                	ld	tp,32(sp)
ffffffffc0200a68:	72a2                	ld	t0,40(sp)
ffffffffc0200a6a:	7342                	ld	t1,48(sp)
ffffffffc0200a6c:	73e2                	ld	t2,56(sp)
ffffffffc0200a6e:	6406                	ld	s0,64(sp)
ffffffffc0200a70:	64a6                	ld	s1,72(sp)
ffffffffc0200a72:	6546                	ld	a0,80(sp)
ffffffffc0200a74:	65e6                	ld	a1,88(sp)
ffffffffc0200a76:	7606                	ld	a2,96(sp)
ffffffffc0200a78:	76a6                	ld	a3,104(sp)
ffffffffc0200a7a:	7746                	ld	a4,112(sp)
ffffffffc0200a7c:	77e6                	ld	a5,120(sp)
ffffffffc0200a7e:	680a                	ld	a6,128(sp)
ffffffffc0200a80:	68aa                	ld	a7,136(sp)
ffffffffc0200a82:	694a                	ld	s2,144(sp)
ffffffffc0200a84:	69ea                	ld	s3,152(sp)
ffffffffc0200a86:	7a0a                	ld	s4,160(sp)
ffffffffc0200a88:	7aaa                	ld	s5,168(sp)
ffffffffc0200a8a:	7b4a                	ld	s6,176(sp)
ffffffffc0200a8c:	7bea                	ld	s7,184(sp)
ffffffffc0200a8e:	6c0e                	ld	s8,192(sp)
ffffffffc0200a90:	6cae                	ld	s9,200(sp)
ffffffffc0200a92:	6d4e                	ld	s10,208(sp)
ffffffffc0200a94:	6dee                	ld	s11,216(sp)
ffffffffc0200a96:	7e0e                	ld	t3,224(sp)
ffffffffc0200a98:	7eae                	ld	t4,232(sp)
ffffffffc0200a9a:	7f4e                	ld	t5,240(sp)
ffffffffc0200a9c:	7fee                	ld	t6,248(sp)
ffffffffc0200a9e:	6142                	ld	sp,16(sp)
    // go back from supervisor call
    sret
ffffffffc0200aa0:	10200073          	sret
	...

ffffffffc0200ab0 <pa2page.part.4>:

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
}

static inline struct Page *pa2page(uintptr_t pa) {
ffffffffc0200ab0:	1141                	addi	sp,sp,-16
    if (PPN(pa) >= npage) {
        panic("pa2page called with invalid pa");
ffffffffc0200ab2:	00004617          	auipc	a2,0x4
ffffffffc0200ab6:	26e60613          	addi	a2,a2,622 # ffffffffc0204d20 <commands+0x8b8>
ffffffffc0200aba:	06500593          	li	a1,101
ffffffffc0200abe:	00004517          	auipc	a0,0x4
ffffffffc0200ac2:	28250513          	addi	a0,a0,642 # ffffffffc0204d40 <commands+0x8d8>
static inline struct Page *pa2page(uintptr_t pa) {
ffffffffc0200ac6:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0200ac8:	e3cff0ef          	jal	ra,ffffffffc0200104 <__panic>

ffffffffc0200acc <alloc_pages>:
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - 调用 pmm->alloc_pages 来分配连续的 n*PAGESIZE 内存
struct Page *alloc_pages(size_t n)
{
ffffffffc0200acc:	715d                	addi	sp,sp,-80
ffffffffc0200ace:	e0a2                	sd	s0,64(sp)
ffffffffc0200ad0:	fc26                	sd	s1,56(sp)
ffffffffc0200ad2:	f84a                	sd	s2,48(sp)
ffffffffc0200ad4:	f44e                	sd	s3,40(sp)
ffffffffc0200ad6:	f052                	sd	s4,32(sp)
ffffffffc0200ad8:	ec56                	sd	s5,24(sp)
ffffffffc0200ada:	e486                	sd	ra,72(sp)
ffffffffc0200adc:	842a                	mv	s0,a0
ffffffffc0200ade:	00011497          	auipc	s1,0x11
ffffffffc0200ae2:	9ba48493          	addi	s1,s1,-1606 # ffffffffc0211498 <pmm_manager>
        {
            page = pmm_manager->alloc_pages(n);
        }
        local_intr_restore(intr_flag);

        if (page != NULL || n > 1 || swap_init_ok == 0)
ffffffffc0200ae6:	4985                	li	s3,1
ffffffffc0200ae8:	00011a17          	auipc	s4,0x11
ffffffffc0200aec:	988a0a13          	addi	s4,s4,-1656 # ffffffffc0211470 <swap_init_ok>
            break;

        extern struct mm_struct *check_mm_struct;
        // cprintf("page %x, call swap_out in alloc_pages %d\n",page, n);
        swap_out(check_mm_struct, n, 0);
ffffffffc0200af0:	0005091b          	sext.w	s2,a0
ffffffffc0200af4:	00011a97          	auipc	s5,0x11
ffffffffc0200af8:	9c4a8a93          	addi	s5,s5,-1596 # ffffffffc02114b8 <check_mm_struct>
ffffffffc0200afc:	a00d                	j	ffffffffc0200b1e <alloc_pages+0x52>
            page = pmm_manager->alloc_pages(n);
ffffffffc0200afe:	609c                	ld	a5,0(s1)
ffffffffc0200b00:	6f9c                	ld	a5,24(a5)
ffffffffc0200b02:	9782                	jalr	a5
        swap_out(check_mm_struct, n, 0);
ffffffffc0200b04:	4601                	li	a2,0
ffffffffc0200b06:	85ca                	mv	a1,s2
        if (page != NULL || n > 1 || swap_init_ok == 0)
ffffffffc0200b08:	ed0d                	bnez	a0,ffffffffc0200b42 <alloc_pages+0x76>
ffffffffc0200b0a:	0289ec63          	bltu	s3,s0,ffffffffc0200b42 <alloc_pages+0x76>
ffffffffc0200b0e:	000a2783          	lw	a5,0(s4)
ffffffffc0200b12:	2781                	sext.w	a5,a5
ffffffffc0200b14:	c79d                	beqz	a5,ffffffffc0200b42 <alloc_pages+0x76>
        swap_out(check_mm_struct, n, 0);
ffffffffc0200b16:	000ab503          	ld	a0,0(s5)
ffffffffc0200b1a:	01a020ef          	jal	ra,ffffffffc0202b34 <swap_out>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200b1e:	100027f3          	csrr	a5,sstatus
ffffffffc0200b22:	8b89                	andi	a5,a5,2
            page = pmm_manager->alloc_pages(n);
ffffffffc0200b24:	8522                	mv	a0,s0
ffffffffc0200b26:	dfe1                	beqz	a5,ffffffffc0200afe <alloc_pages+0x32>
        intr_disable();
ffffffffc0200b28:	9cbff0ef          	jal	ra,ffffffffc02004f2 <intr_disable>
ffffffffc0200b2c:	609c                	ld	a5,0(s1)
ffffffffc0200b2e:	8522                	mv	a0,s0
ffffffffc0200b30:	6f9c                	ld	a5,24(a5)
ffffffffc0200b32:	9782                	jalr	a5
ffffffffc0200b34:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0200b36:	9b7ff0ef          	jal	ra,ffffffffc02004ec <intr_enable>
ffffffffc0200b3a:	6522                	ld	a0,8(sp)
        swap_out(check_mm_struct, n, 0);
ffffffffc0200b3c:	4601                	li	a2,0
ffffffffc0200b3e:	85ca                	mv	a1,s2
        if (page != NULL || n > 1 || swap_init_ok == 0)
ffffffffc0200b40:	d569                	beqz	a0,ffffffffc0200b0a <alloc_pages+0x3e>
    }
    // cprintf("n %d,get page %x, No %d in alloc_pages\n",n,page,(page-pages));
    return page;
}
ffffffffc0200b42:	60a6                	ld	ra,72(sp)
ffffffffc0200b44:	6406                	ld	s0,64(sp)
ffffffffc0200b46:	74e2                	ld	s1,56(sp)
ffffffffc0200b48:	7942                	ld	s2,48(sp)
ffffffffc0200b4a:	79a2                	ld	s3,40(sp)
ffffffffc0200b4c:	7a02                	ld	s4,32(sp)
ffffffffc0200b4e:	6ae2                	ld	s5,24(sp)
ffffffffc0200b50:	6161                	addi	sp,sp,80
ffffffffc0200b52:	8082                	ret

ffffffffc0200b54 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200b54:	100027f3          	csrr	a5,sstatus
ffffffffc0200b58:	8b89                	andi	a5,a5,2
ffffffffc0200b5a:	eb89                	bnez	a5,ffffffffc0200b6c <free_pages+0x18>
{
    bool intr_flag;

    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0200b5c:	00011797          	auipc	a5,0x11
ffffffffc0200b60:	93c78793          	addi	a5,a5,-1732 # ffffffffc0211498 <pmm_manager>
ffffffffc0200b64:	639c                	ld	a5,0(a5)
ffffffffc0200b66:	0207b303          	ld	t1,32(a5)
ffffffffc0200b6a:	8302                	jr	t1
{
ffffffffc0200b6c:	1101                	addi	sp,sp,-32
ffffffffc0200b6e:	ec06                	sd	ra,24(sp)
ffffffffc0200b70:	e822                	sd	s0,16(sp)
ffffffffc0200b72:	e426                	sd	s1,8(sp)
ffffffffc0200b74:	842a                	mv	s0,a0
ffffffffc0200b76:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0200b78:	97bff0ef          	jal	ra,ffffffffc02004f2 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0200b7c:	00011797          	auipc	a5,0x11
ffffffffc0200b80:	91c78793          	addi	a5,a5,-1764 # ffffffffc0211498 <pmm_manager>
ffffffffc0200b84:	639c                	ld	a5,0(a5)
ffffffffc0200b86:	85a6                	mv	a1,s1
ffffffffc0200b88:	8522                	mv	a0,s0
ffffffffc0200b8a:	739c                	ld	a5,32(a5)
ffffffffc0200b8c:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200b8e:	6442                	ld	s0,16(sp)
ffffffffc0200b90:	60e2                	ld	ra,24(sp)
ffffffffc0200b92:	64a2                	ld	s1,8(sp)
ffffffffc0200b94:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0200b96:	957ff06f          	j	ffffffffc02004ec <intr_enable>

ffffffffc0200b9a <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200b9a:	100027f3          	csrr	a5,sstatus
ffffffffc0200b9e:	8b89                	andi	a5,a5,2
ffffffffc0200ba0:	eb89                	bnez	a5,ffffffffc0200bb2 <nr_free_pages+0x18>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0200ba2:	00011797          	auipc	a5,0x11
ffffffffc0200ba6:	8f678793          	addi	a5,a5,-1802 # ffffffffc0211498 <pmm_manager>
ffffffffc0200baa:	639c                	ld	a5,0(a5)
ffffffffc0200bac:	0287b303          	ld	t1,40(a5)
ffffffffc0200bb0:	8302                	jr	t1
{
ffffffffc0200bb2:	1141                	addi	sp,sp,-16
ffffffffc0200bb4:	e406                	sd	ra,8(sp)
ffffffffc0200bb6:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0200bb8:	93bff0ef          	jal	ra,ffffffffc02004f2 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0200bbc:	00011797          	auipc	a5,0x11
ffffffffc0200bc0:	8dc78793          	addi	a5,a5,-1828 # ffffffffc0211498 <pmm_manager>
ffffffffc0200bc4:	639c                	ld	a5,0(a5)
ffffffffc0200bc6:	779c                	ld	a5,40(a5)
ffffffffc0200bc8:	9782                	jalr	a5
ffffffffc0200bca:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0200bcc:	921ff0ef          	jal	ra,ffffffffc02004ec <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0200bd0:	8522                	mv	a0,s0
ffffffffc0200bd2:	60a2                	ld	ra,8(sp)
ffffffffc0200bd4:	6402                	ld	s0,0(sp)
ffffffffc0200bd6:	0141                	addi	sp,sp,16
ffffffffc0200bd8:	8082                	ret

ffffffffc0200bda <get_pte>:
//  pgdir:  PDT 的内核虚拟基地址
//  la:     需要映射的线性地址
//  create: 一个逻辑值，决定是否为 PT 分配一个页
// 返回值：此 pte 的内核虚拟地址
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
ffffffffc0200bda:	715d                	addi	sp,sp,-80
ffffffffc0200bdc:	fc26                	sd	s1,56(sp)
     * 定义：
     *   PTE_P           0x001                   // 页表/目录项标志位：存在
     *   PTE_W           0x002                   // 页表/目录项标志位：可写
     *   PTE_U           0x004                   // 页表/目录项标志位：用户可访问
     */
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0200bde:	01e5d493          	srli	s1,a1,0x1e
ffffffffc0200be2:	1ff4f493          	andi	s1,s1,511
ffffffffc0200be6:	048e                	slli	s1,s1,0x3
ffffffffc0200be8:	94aa                	add	s1,s1,a0
    if (!(*pdep1 & PTE_V))
ffffffffc0200bea:	6094                	ld	a3,0(s1)
{
ffffffffc0200bec:	f84a                	sd	s2,48(sp)
ffffffffc0200bee:	f44e                	sd	s3,40(sp)
ffffffffc0200bf0:	f052                	sd	s4,32(sp)
ffffffffc0200bf2:	e486                	sd	ra,72(sp)
ffffffffc0200bf4:	e0a2                	sd	s0,64(sp)
ffffffffc0200bf6:	ec56                	sd	s5,24(sp)
ffffffffc0200bf8:	e85a                	sd	s6,16(sp)
ffffffffc0200bfa:	e45e                	sd	s7,8(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0200bfc:	0016f793          	andi	a5,a3,1
{
ffffffffc0200c00:	892e                	mv	s2,a1
ffffffffc0200c02:	8a32                	mv	s4,a2
ffffffffc0200c04:	00011997          	auipc	s3,0x11
ffffffffc0200c08:	85498993          	addi	s3,s3,-1964 # ffffffffc0211458 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0200c0c:	e3c9                	bnez	a5,ffffffffc0200c8e <get_pte+0xb4>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0200c0e:	16060163          	beqz	a2,ffffffffc0200d70 <get_pte+0x196>
ffffffffc0200c12:	4505                	li	a0,1
ffffffffc0200c14:	eb9ff0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc0200c18:	842a                	mv	s0,a0
ffffffffc0200c1a:	14050b63          	beqz	a0,ffffffffc0200d70 <get_pte+0x196>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200c1e:	00011b97          	auipc	s7,0x11
ffffffffc0200c22:	892b8b93          	addi	s7,s7,-1902 # ffffffffc02114b0 <pages>
ffffffffc0200c26:	000bb503          	ld	a0,0(s7)
ffffffffc0200c2a:	00004797          	auipc	a5,0x4
ffffffffc0200c2e:	07678793          	addi	a5,a5,118 # ffffffffc0204ca0 <commands+0x838>
ffffffffc0200c32:	0007bb03          	ld	s6,0(a5)
ffffffffc0200c36:	40a40533          	sub	a0,s0,a0
ffffffffc0200c3a:	850d                	srai	a0,a0,0x3
ffffffffc0200c3c:	03650533          	mul	a0,a0,s6
ffffffffc0200c40:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0200c44:	00011997          	auipc	s3,0x11
ffffffffc0200c48:	81498993          	addi	s3,s3,-2028 # ffffffffc0211458 <npage>
    return pa2page(PDE_ADDR(pde));
}

static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200c4c:	4785                	li	a5,1
ffffffffc0200c4e:	0009b703          	ld	a4,0(s3)
ffffffffc0200c52:	c01c                	sw	a5,0(s0)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200c54:	9556                	add	a0,a0,s5
ffffffffc0200c56:	00c51793          	slli	a5,a0,0xc
ffffffffc0200c5a:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0200c5c:	0532                	slli	a0,a0,0xc
ffffffffc0200c5e:	16e7f063          	bgeu	a5,a4,ffffffffc0200dbe <get_pte+0x1e4>
ffffffffc0200c62:	00011797          	auipc	a5,0x11
ffffffffc0200c66:	83e78793          	addi	a5,a5,-1986 # ffffffffc02114a0 <va_pa_offset>
ffffffffc0200c6a:	639c                	ld	a5,0(a5)
ffffffffc0200c6c:	6605                	lui	a2,0x1
ffffffffc0200c6e:	4581                	li	a1,0
ffffffffc0200c70:	953e                	add	a0,a0,a5
ffffffffc0200c72:	1d6030ef          	jal	ra,ffffffffc0203e48 <memset>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200c76:	000bb683          	ld	a3,0(s7)
ffffffffc0200c7a:	40d406b3          	sub	a3,s0,a3
ffffffffc0200c7e:	868d                	srai	a3,a3,0x3
ffffffffc0200c80:	036686b3          	mul	a3,a3,s6
ffffffffc0200c84:	96d6                	add	a3,a3,s5

static inline void flush_tlb() { asm volatile("sfence.vma"); }

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type) {
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0200c86:	06aa                	slli	a3,a3,0xa
ffffffffc0200c88:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0200c8c:	e094                	sd	a3,0(s1)
    }
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0200c8e:	77fd                	lui	a5,0xfffff
ffffffffc0200c90:	068a                	slli	a3,a3,0x2
ffffffffc0200c92:	0009b703          	ld	a4,0(s3)
ffffffffc0200c96:	8efd                	and	a3,a3,a5
ffffffffc0200c98:	00c6d793          	srli	a5,a3,0xc
ffffffffc0200c9c:	0ce7fc63          	bgeu	a5,a4,ffffffffc0200d74 <get_pte+0x19a>
ffffffffc0200ca0:	00011a97          	auipc	s5,0x11
ffffffffc0200ca4:	800a8a93          	addi	s5,s5,-2048 # ffffffffc02114a0 <va_pa_offset>
ffffffffc0200ca8:	000ab403          	ld	s0,0(s5)
ffffffffc0200cac:	01595793          	srli	a5,s2,0x15
ffffffffc0200cb0:	1ff7f793          	andi	a5,a5,511
ffffffffc0200cb4:	96a2                	add	a3,a3,s0
ffffffffc0200cb6:	00379413          	slli	s0,a5,0x3
ffffffffc0200cba:	9436                	add	s0,s0,a3
    //    pde_t *pdep0 = &((pde_t *)(PDE_ADDR(*pdep1)))[PDX0(la)];
    if (!(*pdep0 & PTE_V))
ffffffffc0200cbc:	6014                	ld	a3,0(s0)
ffffffffc0200cbe:	0016f793          	andi	a5,a3,1
ffffffffc0200cc2:	ebbd                	bnez	a5,ffffffffc0200d38 <get_pte+0x15e>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0200cc4:	0a0a0663          	beqz	s4,ffffffffc0200d70 <get_pte+0x196>
ffffffffc0200cc8:	4505                	li	a0,1
ffffffffc0200cca:	e03ff0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc0200cce:	84aa                	mv	s1,a0
ffffffffc0200cd0:	c145                	beqz	a0,ffffffffc0200d70 <get_pte+0x196>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200cd2:	00010b97          	auipc	s7,0x10
ffffffffc0200cd6:	7deb8b93          	addi	s7,s7,2014 # ffffffffc02114b0 <pages>
ffffffffc0200cda:	000bb503          	ld	a0,0(s7)
ffffffffc0200cde:	00004797          	auipc	a5,0x4
ffffffffc0200ce2:	fc278793          	addi	a5,a5,-62 # ffffffffc0204ca0 <commands+0x838>
ffffffffc0200ce6:	0007bb03          	ld	s6,0(a5)
ffffffffc0200cea:	40a48533          	sub	a0,s1,a0
ffffffffc0200cee:	850d                	srai	a0,a0,0x3
ffffffffc0200cf0:	03650533          	mul	a0,a0,s6
ffffffffc0200cf4:	00080a37          	lui	s4,0x80
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200cf8:	4785                	li	a5,1
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0200cfa:	0009b703          	ld	a4,0(s3)
ffffffffc0200cfe:	c09c                	sw	a5,0(s1)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200d00:	9552                	add	a0,a0,s4
ffffffffc0200d02:	00c51793          	slli	a5,a0,0xc
ffffffffc0200d06:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0200d08:	0532                	slli	a0,a0,0xc
ffffffffc0200d0a:	08e7fd63          	bgeu	a5,a4,ffffffffc0200da4 <get_pte+0x1ca>
ffffffffc0200d0e:	000ab783          	ld	a5,0(s5)
ffffffffc0200d12:	6605                	lui	a2,0x1
ffffffffc0200d14:	4581                	li	a1,0
ffffffffc0200d16:	953e                	add	a0,a0,a5
ffffffffc0200d18:	130030ef          	jal	ra,ffffffffc0203e48 <memset>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200d1c:	000bb683          	ld	a3,0(s7)
ffffffffc0200d20:	40d486b3          	sub	a3,s1,a3
ffffffffc0200d24:	868d                	srai	a3,a3,0x3
ffffffffc0200d26:	036686b3          	mul	a3,a3,s6
ffffffffc0200d2a:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0200d2c:	06aa                	slli	a3,a3,0xa
ffffffffc0200d2e:	0116e693          	ori	a3,a3,17
        //   	memset(pa, 0, PGSIZE);
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0200d32:	e014                	sd	a3,0(s0)
ffffffffc0200d34:	0009b703          	ld	a4,0(s3)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0200d38:	068a                	slli	a3,a3,0x2
ffffffffc0200d3a:	757d                	lui	a0,0xfffff
ffffffffc0200d3c:	8ee9                	and	a3,a3,a0
ffffffffc0200d3e:	00c6d793          	srli	a5,a3,0xc
ffffffffc0200d42:	04e7f563          	bgeu	a5,a4,ffffffffc0200d8c <get_pte+0x1b2>
ffffffffc0200d46:	000ab503          	ld	a0,0(s5)
ffffffffc0200d4a:	00c95793          	srli	a5,s2,0xc
ffffffffc0200d4e:	1ff7f793          	andi	a5,a5,511
ffffffffc0200d52:	96aa                	add	a3,a3,a0
ffffffffc0200d54:	00379513          	slli	a0,a5,0x3
ffffffffc0200d58:	9536                	add	a0,a0,a3
}
ffffffffc0200d5a:	60a6                	ld	ra,72(sp)
ffffffffc0200d5c:	6406                	ld	s0,64(sp)
ffffffffc0200d5e:	74e2                	ld	s1,56(sp)
ffffffffc0200d60:	7942                	ld	s2,48(sp)
ffffffffc0200d62:	79a2                	ld	s3,40(sp)
ffffffffc0200d64:	7a02                	ld	s4,32(sp)
ffffffffc0200d66:	6ae2                	ld	s5,24(sp)
ffffffffc0200d68:	6b42                	ld	s6,16(sp)
ffffffffc0200d6a:	6ba2                	ld	s7,8(sp)
ffffffffc0200d6c:	6161                	addi	sp,sp,80
ffffffffc0200d6e:	8082                	ret
            return NULL;
ffffffffc0200d70:	4501                	li	a0,0
ffffffffc0200d72:	b7e5                	j	ffffffffc0200d5a <get_pte+0x180>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0200d74:	00004617          	auipc	a2,0x4
ffffffffc0200d78:	f3460613          	addi	a2,a2,-204 # ffffffffc0204ca8 <commands+0x840>
ffffffffc0200d7c:	10800593          	li	a1,264
ffffffffc0200d80:	00004517          	auipc	a0,0x4
ffffffffc0200d84:	f5050513          	addi	a0,a0,-176 # ffffffffc0204cd0 <commands+0x868>
ffffffffc0200d88:	b7cff0ef          	jal	ra,ffffffffc0200104 <__panic>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0200d8c:	00004617          	auipc	a2,0x4
ffffffffc0200d90:	f1c60613          	addi	a2,a2,-228 # ffffffffc0204ca8 <commands+0x840>
ffffffffc0200d94:	11700593          	li	a1,279
ffffffffc0200d98:	00004517          	auipc	a0,0x4
ffffffffc0200d9c:	f3850513          	addi	a0,a0,-200 # ffffffffc0204cd0 <commands+0x868>
ffffffffc0200da0:	b64ff0ef          	jal	ra,ffffffffc0200104 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0200da4:	86aa                	mv	a3,a0
ffffffffc0200da6:	00004617          	auipc	a2,0x4
ffffffffc0200daa:	f0260613          	addi	a2,a2,-254 # ffffffffc0204ca8 <commands+0x840>
ffffffffc0200dae:	11300593          	li	a1,275
ffffffffc0200db2:	00004517          	auipc	a0,0x4
ffffffffc0200db6:	f1e50513          	addi	a0,a0,-226 # ffffffffc0204cd0 <commands+0x868>
ffffffffc0200dba:	b4aff0ef          	jal	ra,ffffffffc0200104 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0200dbe:	86aa                	mv	a3,a0
ffffffffc0200dc0:	00004617          	auipc	a2,0x4
ffffffffc0200dc4:	ee860613          	addi	a2,a2,-280 # ffffffffc0204ca8 <commands+0x840>
ffffffffc0200dc8:	10500593          	li	a1,261
ffffffffc0200dcc:	00004517          	auipc	a0,0x4
ffffffffc0200dd0:	f0450513          	addi	a0,a0,-252 # ffffffffc0204cd0 <commands+0x868>
ffffffffc0200dd4:	b30ff0ef          	jal	ra,ffffffffc0200104 <__panic>

ffffffffc0200dd8 <get_page>:

// get_page - 使用 PDT pgdir 获取线性地址 la 相关的 Page 结构
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc0200dd8:	1141                	addi	sp,sp,-16
ffffffffc0200dda:	e022                	sd	s0,0(sp)
ffffffffc0200ddc:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0200dde:	4601                	li	a2,0
{
ffffffffc0200de0:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0200de2:	df9ff0ef          	jal	ra,ffffffffc0200bda <get_pte>
    if (ptep_store != NULL)
ffffffffc0200de6:	c011                	beqz	s0,ffffffffc0200dea <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc0200de8:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0200dea:	c511                	beqz	a0,ffffffffc0200df6 <get_page+0x1e>
ffffffffc0200dec:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0200dee:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0200df0:	0017f713          	andi	a4,a5,1
ffffffffc0200df4:	e709                	bnez	a4,ffffffffc0200dfe <get_page+0x26>
}
ffffffffc0200df6:	60a2                	ld	ra,8(sp)
ffffffffc0200df8:	6402                	ld	s0,0(sp)
ffffffffc0200dfa:	0141                	addi	sp,sp,16
ffffffffc0200dfc:	8082                	ret
    if (PPN(pa) >= npage) {
ffffffffc0200dfe:	00010717          	auipc	a4,0x10
ffffffffc0200e02:	65a70713          	addi	a4,a4,1626 # ffffffffc0211458 <npage>
ffffffffc0200e06:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc0200e08:	078a                	slli	a5,a5,0x2
ffffffffc0200e0a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0200e0c:	02e7f363          	bgeu	a5,a4,ffffffffc0200e32 <get_page+0x5a>
    return &pages[PPN(pa) - nbase];
ffffffffc0200e10:	fff80537          	lui	a0,0xfff80
ffffffffc0200e14:	97aa                	add	a5,a5,a0
ffffffffc0200e16:	00010697          	auipc	a3,0x10
ffffffffc0200e1a:	69a68693          	addi	a3,a3,1690 # ffffffffc02114b0 <pages>
ffffffffc0200e1e:	6288                	ld	a0,0(a3)
ffffffffc0200e20:	60a2                	ld	ra,8(sp)
ffffffffc0200e22:	6402                	ld	s0,0(sp)
ffffffffc0200e24:	00379713          	slli	a4,a5,0x3
ffffffffc0200e28:	97ba                	add	a5,a5,a4
ffffffffc0200e2a:	078e                	slli	a5,a5,0x3
ffffffffc0200e2c:	953e                	add	a0,a0,a5
ffffffffc0200e2e:	0141                	addi	sp,sp,16
ffffffffc0200e30:	8082                	ret
ffffffffc0200e32:	c7fff0ef          	jal	ra,ffffffffc0200ab0 <pa2page.part.4>

ffffffffc0200e36 <page_remove>:
    }
}

// page_remove - 释放与线性地址 la 相关并具有有效 pte 的 Page
void page_remove(pde_t *pgdir, uintptr_t la)
{
ffffffffc0200e36:	1141                	addi	sp,sp,-16
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0200e38:	4601                	li	a2,0
{
ffffffffc0200e3a:	e406                	sd	ra,8(sp)
ffffffffc0200e3c:	e022                	sd	s0,0(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0200e3e:	d9dff0ef          	jal	ra,ffffffffc0200bda <get_pte>
    if (ptep != NULL)
ffffffffc0200e42:	c511                	beqz	a0,ffffffffc0200e4e <page_remove+0x18>
    if (*ptep & PTE_V)
ffffffffc0200e44:	611c                	ld	a5,0(a0)
ffffffffc0200e46:	842a                	mv	s0,a0
ffffffffc0200e48:	0017f713          	andi	a4,a5,1
ffffffffc0200e4c:	e709                	bnez	a4,ffffffffc0200e56 <page_remove+0x20>
    {
        page_remove_pte(pgdir, la, ptep);
    }
}
ffffffffc0200e4e:	60a2                	ld	ra,8(sp)
ffffffffc0200e50:	6402                	ld	s0,0(sp)
ffffffffc0200e52:	0141                	addi	sp,sp,16
ffffffffc0200e54:	8082                	ret
    if (PPN(pa) >= npage) {
ffffffffc0200e56:	00010717          	auipc	a4,0x10
ffffffffc0200e5a:	60270713          	addi	a4,a4,1538 # ffffffffc0211458 <npage>
ffffffffc0200e5e:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc0200e60:	078a                	slli	a5,a5,0x2
ffffffffc0200e62:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0200e64:	04e7f063          	bgeu	a5,a4,ffffffffc0200ea4 <page_remove+0x6e>
    return &pages[PPN(pa) - nbase];
ffffffffc0200e68:	fff80737          	lui	a4,0xfff80
ffffffffc0200e6c:	97ba                	add	a5,a5,a4
ffffffffc0200e6e:	00010717          	auipc	a4,0x10
ffffffffc0200e72:	64270713          	addi	a4,a4,1602 # ffffffffc02114b0 <pages>
ffffffffc0200e76:	6308                	ld	a0,0(a4)
ffffffffc0200e78:	00379713          	slli	a4,a5,0x3
ffffffffc0200e7c:	97ba                	add	a5,a5,a4
ffffffffc0200e7e:	078e                	slli	a5,a5,0x3
ffffffffc0200e80:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0200e82:	411c                	lw	a5,0(a0)
ffffffffc0200e84:	fff7871b          	addiw	a4,a5,-1
ffffffffc0200e88:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0200e8a:	cb09                	beqz	a4,ffffffffc0200e9c <page_remove+0x66>
        *ptep = 0;                 //(5) 清除二级页表项
ffffffffc0200e8c:	00043023          	sd	zero,0(s0)
static inline void flush_tlb() { asm volatile("sfence.vma"); }
ffffffffc0200e90:	12000073          	sfence.vma
}
ffffffffc0200e94:	60a2                	ld	ra,8(sp)
ffffffffc0200e96:	6402                	ld	s0,0(sp)
ffffffffc0200e98:	0141                	addi	sp,sp,16
ffffffffc0200e9a:	8082                	ret
            free_page(page);
ffffffffc0200e9c:	4585                	li	a1,1
ffffffffc0200e9e:	cb7ff0ef          	jal	ra,ffffffffc0200b54 <free_pages>
ffffffffc0200ea2:	b7ed                	j	ffffffffc0200e8c <page_remove+0x56>
ffffffffc0200ea4:	c0dff0ef          	jal	ra,ffffffffc0200ab0 <pa2page.part.4>

ffffffffc0200ea8 <page_insert>:
//  la:    需要映射的线性地址
//  perm:  设置在相关 pte 中的 Page 权限
// 返回值：始终为 0
// 注意：PT 已更改，因此需要使 TLB 无效
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm)
{
ffffffffc0200ea8:	7179                	addi	sp,sp,-48
ffffffffc0200eaa:	87b2                	mv	a5,a2
ffffffffc0200eac:	f022                	sd	s0,32(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0200eae:	4605                	li	a2,1
{
ffffffffc0200eb0:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0200eb2:	85be                	mv	a1,a5
{
ffffffffc0200eb4:	ec26                	sd	s1,24(sp)
ffffffffc0200eb6:	f406                	sd	ra,40(sp)
ffffffffc0200eb8:	e84a                	sd	s2,16(sp)
ffffffffc0200eba:	e44e                	sd	s3,8(sp)
ffffffffc0200ebc:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0200ebe:	d1dff0ef          	jal	ra,ffffffffc0200bda <get_pte>
    if (ptep == NULL)
ffffffffc0200ec2:	c945                	beqz	a0,ffffffffc0200f72 <page_insert+0xca>
    page->ref += 1;
ffffffffc0200ec4:	4014                	lw	a3,0(s0)
    {
        return -E_NO_MEM;
    }
    page_ref_inc(page);
    if (*ptep & PTE_V)
ffffffffc0200ec6:	611c                	ld	a5,0(a0)
ffffffffc0200ec8:	892a                	mv	s2,a0
ffffffffc0200eca:	0016871b          	addiw	a4,a3,1
ffffffffc0200ece:	c018                	sw	a4,0(s0)
ffffffffc0200ed0:	0017f713          	andi	a4,a5,1
ffffffffc0200ed4:	e339                	bnez	a4,ffffffffc0200f1a <page_insert+0x72>
ffffffffc0200ed6:	00010797          	auipc	a5,0x10
ffffffffc0200eda:	5da78793          	addi	a5,a5,1498 # ffffffffc02114b0 <pages>
ffffffffc0200ede:	639c                	ld	a5,0(a5)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200ee0:	00004717          	auipc	a4,0x4
ffffffffc0200ee4:	dc070713          	addi	a4,a4,-576 # ffffffffc0204ca0 <commands+0x838>
ffffffffc0200ee8:	40f407b3          	sub	a5,s0,a5
ffffffffc0200eec:	6300                	ld	s0,0(a4)
ffffffffc0200eee:	878d                	srai	a5,a5,0x3
ffffffffc0200ef0:	000806b7          	lui	a3,0x80
ffffffffc0200ef4:	028787b3          	mul	a5,a5,s0
ffffffffc0200ef8:	97b6                	add	a5,a5,a3
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0200efa:	07aa                	slli	a5,a5,0xa
ffffffffc0200efc:	8fc5                	or	a5,a5,s1
ffffffffc0200efe:	0017e793          	ori	a5,a5,1
        else
        {
            page_remove_pte(pgdir, la, ptep);
        }
    }
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc0200f02:	00f93023          	sd	a5,0(s2)
static inline void flush_tlb() { asm volatile("sfence.vma"); }
ffffffffc0200f06:	12000073          	sfence.vma
    tlb_invalidate(pgdir, la);
    return 0;
ffffffffc0200f0a:	4501                	li	a0,0
}
ffffffffc0200f0c:	70a2                	ld	ra,40(sp)
ffffffffc0200f0e:	7402                	ld	s0,32(sp)
ffffffffc0200f10:	64e2                	ld	s1,24(sp)
ffffffffc0200f12:	6942                	ld	s2,16(sp)
ffffffffc0200f14:	69a2                	ld	s3,8(sp)
ffffffffc0200f16:	6145                	addi	sp,sp,48
ffffffffc0200f18:	8082                	ret
    if (PPN(pa) >= npage) {
ffffffffc0200f1a:	00010717          	auipc	a4,0x10
ffffffffc0200f1e:	53e70713          	addi	a4,a4,1342 # ffffffffc0211458 <npage>
ffffffffc0200f22:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc0200f24:	00279513          	slli	a0,a5,0x2
ffffffffc0200f28:	8131                	srli	a0,a0,0xc
    if (PPN(pa) >= npage) {
ffffffffc0200f2a:	04e57663          	bgeu	a0,a4,ffffffffc0200f76 <page_insert+0xce>
    return &pages[PPN(pa) - nbase];
ffffffffc0200f2e:	fff807b7          	lui	a5,0xfff80
ffffffffc0200f32:	953e                	add	a0,a0,a5
ffffffffc0200f34:	00010997          	auipc	s3,0x10
ffffffffc0200f38:	57c98993          	addi	s3,s3,1404 # ffffffffc02114b0 <pages>
ffffffffc0200f3c:	0009b783          	ld	a5,0(s3)
ffffffffc0200f40:	00351713          	slli	a4,a0,0x3
ffffffffc0200f44:	953a                	add	a0,a0,a4
ffffffffc0200f46:	050e                	slli	a0,a0,0x3
ffffffffc0200f48:	953e                	add	a0,a0,a5
        if (p == page)
ffffffffc0200f4a:	00a40e63          	beq	s0,a0,ffffffffc0200f66 <page_insert+0xbe>
    page->ref -= 1;
ffffffffc0200f4e:	411c                	lw	a5,0(a0)
ffffffffc0200f50:	fff7871b          	addiw	a4,a5,-1
ffffffffc0200f54:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0200f56:	cb11                	beqz	a4,ffffffffc0200f6a <page_insert+0xc2>
        *ptep = 0;                 //(5) 清除二级页表项
ffffffffc0200f58:	00093023          	sd	zero,0(s2)
static inline void flush_tlb() { asm volatile("sfence.vma"); }
ffffffffc0200f5c:	12000073          	sfence.vma
ffffffffc0200f60:	0009b783          	ld	a5,0(s3)
ffffffffc0200f64:	bfb5                	j	ffffffffc0200ee0 <page_insert+0x38>
    page->ref -= 1;
ffffffffc0200f66:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0200f68:	bfa5                	j	ffffffffc0200ee0 <page_insert+0x38>
            free_page(page);
ffffffffc0200f6a:	4585                	li	a1,1
ffffffffc0200f6c:	be9ff0ef          	jal	ra,ffffffffc0200b54 <free_pages>
ffffffffc0200f70:	b7e5                	j	ffffffffc0200f58 <page_insert+0xb0>
        return -E_NO_MEM;
ffffffffc0200f72:	5571                	li	a0,-4
ffffffffc0200f74:	bf61                	j	ffffffffc0200f0c <page_insert+0x64>
ffffffffc0200f76:	b3bff0ef          	jal	ra,ffffffffc0200ab0 <pa2page.part.4>

ffffffffc0200f7a <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0200f7a:	00005797          	auipc	a5,0x5
ffffffffc0200f7e:	e5678793          	addi	a5,a5,-426 # ffffffffc0205dd0 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200f82:	638c                	ld	a1,0(a5)
{
ffffffffc0200f84:	711d                	addi	sp,sp,-96
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200f86:	00004517          	auipc	a0,0x4
ffffffffc0200f8a:	de250513          	addi	a0,a0,-542 # ffffffffc0204d68 <commands+0x900>
{
ffffffffc0200f8e:	ec86                	sd	ra,88(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0200f90:	00010717          	auipc	a4,0x10
ffffffffc0200f94:	50f73423          	sd	a5,1288(a4) # ffffffffc0211498 <pmm_manager>
{
ffffffffc0200f98:	e8a2                	sd	s0,80(sp)
ffffffffc0200f9a:	e4a6                	sd	s1,72(sp)
ffffffffc0200f9c:	e0ca                	sd	s2,64(sp)
ffffffffc0200f9e:	fc4e                	sd	s3,56(sp)
ffffffffc0200fa0:	f852                	sd	s4,48(sp)
ffffffffc0200fa2:	f456                	sd	s5,40(sp)
ffffffffc0200fa4:	f05a                	sd	s6,32(sp)
ffffffffc0200fa6:	ec5e                	sd	s7,24(sp)
ffffffffc0200fa8:	e862                	sd	s8,16(sp)
ffffffffc0200faa:	e466                	sd	s9,8(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0200fac:	00010417          	auipc	s0,0x10
ffffffffc0200fb0:	4ec40413          	addi	s0,s0,1260 # ffffffffc0211498 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200fb4:	90aff0ef          	jal	ra,ffffffffc02000be <cprintf>
    pmm_manager->init();
ffffffffc0200fb8:	601c                	ld	a5,0(s0)
    cprintf("membegin %llx memend %llx mem_size %llx\n", mem_begin, mem_end, mem_size);
ffffffffc0200fba:	49c5                	li	s3,17
ffffffffc0200fbc:	40100a13          	li	s4,1025
    pmm_manager->init();
ffffffffc0200fc0:	679c                	ld	a5,8(a5)
ffffffffc0200fc2:	00010497          	auipc	s1,0x10
ffffffffc0200fc6:	49648493          	addi	s1,s1,1174 # ffffffffc0211458 <npage>
ffffffffc0200fca:	00010917          	auipc	s2,0x10
ffffffffc0200fce:	4e690913          	addi	s2,s2,1254 # ffffffffc02114b0 <pages>
ffffffffc0200fd2:	9782                	jalr	a5
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0200fd4:	57f5                	li	a5,-3
ffffffffc0200fd6:	07fa                	slli	a5,a5,0x1e
    cprintf("membegin %llx memend %llx mem_size %llx\n", mem_begin, mem_end, mem_size);
ffffffffc0200fd8:	07e006b7          	lui	a3,0x7e00
ffffffffc0200fdc:	01b99613          	slli	a2,s3,0x1b
ffffffffc0200fe0:	015a1593          	slli	a1,s4,0x15
ffffffffc0200fe4:	00004517          	auipc	a0,0x4
ffffffffc0200fe8:	d9c50513          	addi	a0,a0,-612 # ffffffffc0204d80 <commands+0x918>
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0200fec:	00010717          	auipc	a4,0x10
ffffffffc0200ff0:	4af73a23          	sd	a5,1204(a4) # ffffffffc02114a0 <va_pa_offset>
    cprintf("membegin %llx memend %llx mem_size %llx\n", mem_begin, mem_end, mem_size);
ffffffffc0200ff4:	8caff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("physcial memory map:\n");
ffffffffc0200ff8:	00004517          	auipc	a0,0x4
ffffffffc0200ffc:	db850513          	addi	a0,a0,-584 # ffffffffc0204db0 <commands+0x948>
ffffffffc0201000:	8beff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc0201004:	01b99693          	slli	a3,s3,0x1b
ffffffffc0201008:	16fd                	addi	a3,a3,-1
ffffffffc020100a:	015a1613          	slli	a2,s4,0x15
ffffffffc020100e:	07e005b7          	lui	a1,0x7e00
ffffffffc0201012:	00004517          	auipc	a0,0x4
ffffffffc0201016:	db650513          	addi	a0,a0,-586 # ffffffffc0204dc8 <commands+0x960>
ffffffffc020101a:	8a4ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020101e:	777d                	lui	a4,0xfffff
ffffffffc0201020:	00011797          	auipc	a5,0x11
ffffffffc0201024:	57f78793          	addi	a5,a5,1407 # ffffffffc021259f <end+0xfff>
ffffffffc0201028:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc020102a:	00088737          	lui	a4,0x88
ffffffffc020102e:	00010697          	auipc	a3,0x10
ffffffffc0201032:	42e6b523          	sd	a4,1066(a3) # ffffffffc0211458 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201036:	00010717          	auipc	a4,0x10
ffffffffc020103a:	46f73d23          	sd	a5,1146(a4) # ffffffffc02114b0 <pages>
ffffffffc020103e:	4681                	li	a3,0
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0201040:	4701                	li	a4,0
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201042:	4585                	li	a1,1
ffffffffc0201044:	fff80637          	lui	a2,0xfff80
ffffffffc0201048:	a019                	j	ffffffffc020104e <pmm_init+0xd4>
ffffffffc020104a:	00093783          	ld	a5,0(s2)
        SetPageReserved(pages + i);
ffffffffc020104e:	97b6                	add	a5,a5,a3
ffffffffc0201050:	07a1                	addi	a5,a5,8
ffffffffc0201052:	40b7b02f          	amoor.d	zero,a1,(a5)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0201056:	609c                	ld	a5,0(s1)
ffffffffc0201058:	0705                	addi	a4,a4,1
ffffffffc020105a:	04868693          	addi	a3,a3,72
ffffffffc020105e:	00c78533          	add	a0,a5,a2
ffffffffc0201062:	fea764e3          	bltu	a4,a0,ffffffffc020104a <pmm_init+0xd0>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201066:	00093503          	ld	a0,0(s2)
ffffffffc020106a:	00379693          	slli	a3,a5,0x3
ffffffffc020106e:	96be                	add	a3,a3,a5
ffffffffc0201070:	fdc00737          	lui	a4,0xfdc00
ffffffffc0201074:	972a                	add	a4,a4,a0
ffffffffc0201076:	068e                	slli	a3,a3,0x3
ffffffffc0201078:	96ba                	add	a3,a3,a4
ffffffffc020107a:	c0200737          	lui	a4,0xc0200
ffffffffc020107e:	58e6e863          	bltu	a3,a4,ffffffffc020160e <pmm_init+0x694>
ffffffffc0201082:	00010997          	auipc	s3,0x10
ffffffffc0201086:	41e98993          	addi	s3,s3,1054 # ffffffffc02114a0 <va_pa_offset>
ffffffffc020108a:	0009b703          	ld	a4,0(s3)
    if (freemem < mem_end)
ffffffffc020108e:	45c5                	li	a1,17
ffffffffc0201090:	05ee                	slli	a1,a1,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201092:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end)
ffffffffc0201094:	44b6ed63          	bltu	a3,a1,ffffffffc02014ee <pmm_init+0x574>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0201098:	601c                	ld	a5,0(s0)
    boot_pgdir = (pte_t *)boot_page_table_sv39;
ffffffffc020109a:	00010417          	auipc	s0,0x10
ffffffffc020109e:	3b640413          	addi	s0,s0,950 # ffffffffc0211450 <boot_pgdir>
    pmm_manager->check();
ffffffffc02010a2:	7b9c                	ld	a5,48(a5)
ffffffffc02010a4:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02010a6:	00004517          	auipc	a0,0x4
ffffffffc02010aa:	d7250513          	addi	a0,a0,-654 # ffffffffc0204e18 <commands+0x9b0>
ffffffffc02010ae:	810ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    boot_pgdir = (pte_t *)boot_page_table_sv39;
ffffffffc02010b2:	00008697          	auipc	a3,0x8
ffffffffc02010b6:	f4e68693          	addi	a3,a3,-178 # ffffffffc0209000 <boot_page_table_sv39>
ffffffffc02010ba:	00010797          	auipc	a5,0x10
ffffffffc02010be:	38d7bb23          	sd	a3,918(a5) # ffffffffc0211450 <boot_pgdir>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc02010c2:	c02007b7          	lui	a5,0xc0200
ffffffffc02010c6:	0ef6eae3          	bltu	a3,a5,ffffffffc02019ba <pmm_init+0xa40>
ffffffffc02010ca:	0009b783          	ld	a5,0(s3)
ffffffffc02010ce:	8e9d                	sub	a3,a3,a5
ffffffffc02010d0:	00010797          	auipc	a5,0x10
ffffffffc02010d4:	3cd7bc23          	sd	a3,984(a5) # ffffffffc02114a8 <boot_cr3>
    // assert(npage <= KMEMSIZE / PGSIZE);
    // 内存从 RISC-V 中的 2GB 开始
    // 因此 npage 始终大于 KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();
ffffffffc02010d8:	ac3ff0ef          	jal	ra,ffffffffc0200b9a <nr_free_pages>

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02010dc:	6098                	ld	a4,0(s1)
ffffffffc02010de:	c80007b7          	lui	a5,0xc8000
ffffffffc02010e2:	83b1                	srli	a5,a5,0xc
    nr_free_store = nr_free_pages();
ffffffffc02010e4:	8a2a                	mv	s4,a0
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02010e6:	0ae7eae3          	bltu	a5,a4,ffffffffc020199a <pmm_init+0xa20>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc02010ea:	6008                	ld	a0,0(s0)
ffffffffc02010ec:	4c050163          	beqz	a0,ffffffffc02015ae <pmm_init+0x634>
ffffffffc02010f0:	03451793          	slli	a5,a0,0x34
ffffffffc02010f4:	4a079d63          	bnez	a5,ffffffffc02015ae <pmm_init+0x634>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc02010f8:	4601                	li	a2,0
ffffffffc02010fa:	4581                	li	a1,0
ffffffffc02010fc:	cddff0ef          	jal	ra,ffffffffc0200dd8 <get_page>
ffffffffc0201100:	4c051763          	bnez	a0,ffffffffc02015ce <pmm_init+0x654>

    struct Page *p1, *p2;
    p1 = alloc_page();
ffffffffc0201104:	4505                	li	a0,1
ffffffffc0201106:	9c7ff0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc020110a:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc020110c:	6008                	ld	a0,0(s0)
ffffffffc020110e:	4681                	li	a3,0
ffffffffc0201110:	4601                	li	a2,0
ffffffffc0201112:	85d6                	mv	a1,s5
ffffffffc0201114:	d95ff0ef          	jal	ra,ffffffffc0200ea8 <page_insert>
ffffffffc0201118:	52051763          	bnez	a0,ffffffffc0201646 <pmm_init+0x6cc>
    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc020111c:	6008                	ld	a0,0(s0)
ffffffffc020111e:	4601                	li	a2,0
ffffffffc0201120:	4581                	li	a1,0
ffffffffc0201122:	ab9ff0ef          	jal	ra,ffffffffc0200bda <get_pte>
ffffffffc0201126:	50050063          	beqz	a0,ffffffffc0201626 <pmm_init+0x6ac>
    assert(pte2page(*ptep) == p1);
ffffffffc020112a:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc020112c:	0017f713          	andi	a4,a5,1
ffffffffc0201130:	46070363          	beqz	a4,ffffffffc0201596 <pmm_init+0x61c>
    if (PPN(pa) >= npage) {
ffffffffc0201134:	6090                	ld	a2,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0201136:	078a                	slli	a5,a5,0x2
ffffffffc0201138:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020113a:	44c7f063          	bgeu	a5,a2,ffffffffc020157a <pmm_init+0x600>
    return &pages[PPN(pa) - nbase];
ffffffffc020113e:	fff80737          	lui	a4,0xfff80
ffffffffc0201142:	97ba                	add	a5,a5,a4
ffffffffc0201144:	00379713          	slli	a4,a5,0x3
ffffffffc0201148:	00093683          	ld	a3,0(s2)
ffffffffc020114c:	97ba                	add	a5,a5,a4
ffffffffc020114e:	078e                	slli	a5,a5,0x3
ffffffffc0201150:	97b6                	add	a5,a5,a3
ffffffffc0201152:	5efa9463          	bne	s5,a5,ffffffffc020173a <pmm_init+0x7c0>
    assert(page_ref(p1) == 1);
ffffffffc0201156:	000aab83          	lw	s7,0(s5)
ffffffffc020115a:	4785                	li	a5,1
ffffffffc020115c:	5afb9f63          	bne	s7,a5,ffffffffc020171a <pmm_init+0x7a0>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc0201160:	6008                	ld	a0,0(s0)
ffffffffc0201162:	76fd                	lui	a3,0xfffff
ffffffffc0201164:	611c                	ld	a5,0(a0)
ffffffffc0201166:	078a                	slli	a5,a5,0x2
ffffffffc0201168:	8ff5                	and	a5,a5,a3
ffffffffc020116a:	00c7d713          	srli	a4,a5,0xc
ffffffffc020116e:	58c77963          	bgeu	a4,a2,ffffffffc0201700 <pmm_init+0x786>
ffffffffc0201172:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201176:	97e2                	add	a5,a5,s8
ffffffffc0201178:	0007bb03          	ld	s6,0(a5) # ffffffffc8000000 <end+0x7deea60>
ffffffffc020117c:	0b0a                	slli	s6,s6,0x2
ffffffffc020117e:	00db7b33          	and	s6,s6,a3
ffffffffc0201182:	00cb5793          	srli	a5,s6,0xc
ffffffffc0201186:	56c7f063          	bgeu	a5,a2,ffffffffc02016e6 <pmm_init+0x76c>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc020118a:	4601                	li	a2,0
ffffffffc020118c:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020118e:	9b62                	add	s6,s6,s8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0201190:	a4bff0ef          	jal	ra,ffffffffc0200bda <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201194:	0b21                	addi	s6,s6,8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0201196:	53651863          	bne	a0,s6,ffffffffc02016c6 <pmm_init+0x74c>

    p2 = alloc_page();
ffffffffc020119a:	4505                	li	a0,1
ffffffffc020119c:	931ff0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc02011a0:	8b2a                	mv	s6,a0
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02011a2:	6008                	ld	a0,0(s0)
ffffffffc02011a4:	46d1                	li	a3,20
ffffffffc02011a6:	6605                	lui	a2,0x1
ffffffffc02011a8:	85da                	mv	a1,s6
ffffffffc02011aa:	cffff0ef          	jal	ra,ffffffffc0200ea8 <page_insert>
ffffffffc02011ae:	4e051c63          	bnez	a0,ffffffffc02016a6 <pmm_init+0x72c>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc02011b2:	6008                	ld	a0,0(s0)
ffffffffc02011b4:	4601                	li	a2,0
ffffffffc02011b6:	6585                	lui	a1,0x1
ffffffffc02011b8:	a23ff0ef          	jal	ra,ffffffffc0200bda <get_pte>
ffffffffc02011bc:	4c050563          	beqz	a0,ffffffffc0201686 <pmm_init+0x70c>
    assert(*ptep & PTE_U);
ffffffffc02011c0:	611c                	ld	a5,0(a0)
ffffffffc02011c2:	0107f713          	andi	a4,a5,16
ffffffffc02011c6:	4a070063          	beqz	a4,ffffffffc0201666 <pmm_init+0x6ec>
    assert(*ptep & PTE_W);
ffffffffc02011ca:	8b91                	andi	a5,a5,4
ffffffffc02011cc:	66078763          	beqz	a5,ffffffffc020183a <pmm_init+0x8c0>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc02011d0:	6008                	ld	a0,0(s0)
ffffffffc02011d2:	611c                	ld	a5,0(a0)
ffffffffc02011d4:	8bc1                	andi	a5,a5,16
ffffffffc02011d6:	64078263          	beqz	a5,ffffffffc020181a <pmm_init+0x8a0>
    assert(page_ref(p2) == 1);
ffffffffc02011da:	000b2783          	lw	a5,0(s6)
ffffffffc02011de:	61779e63          	bne	a5,s7,ffffffffc02017fa <pmm_init+0x880>

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc02011e2:	4681                	li	a3,0
ffffffffc02011e4:	6605                	lui	a2,0x1
ffffffffc02011e6:	85d6                	mv	a1,s5
ffffffffc02011e8:	cc1ff0ef          	jal	ra,ffffffffc0200ea8 <page_insert>
ffffffffc02011ec:	5e051763          	bnez	a0,ffffffffc02017da <pmm_init+0x860>
    assert(page_ref(p1) == 2);
ffffffffc02011f0:	000aa703          	lw	a4,0(s5)
ffffffffc02011f4:	4789                	li	a5,2
ffffffffc02011f6:	5cf71263          	bne	a4,a5,ffffffffc02017ba <pmm_init+0x840>
    assert(page_ref(p2) == 0);
ffffffffc02011fa:	000b2783          	lw	a5,0(s6)
ffffffffc02011fe:	58079e63          	bnez	a5,ffffffffc020179a <pmm_init+0x820>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0201202:	6008                	ld	a0,0(s0)
ffffffffc0201204:	4601                	li	a2,0
ffffffffc0201206:	6585                	lui	a1,0x1
ffffffffc0201208:	9d3ff0ef          	jal	ra,ffffffffc0200bda <get_pte>
ffffffffc020120c:	56050763          	beqz	a0,ffffffffc020177a <pmm_init+0x800>
    assert(pte2page(*ptep) == p1);
ffffffffc0201210:	6114                	ld	a3,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0201212:	0016f793          	andi	a5,a3,1
ffffffffc0201216:	38078063          	beqz	a5,ffffffffc0201596 <pmm_init+0x61c>
    if (PPN(pa) >= npage) {
ffffffffc020121a:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc020121c:	00269793          	slli	a5,a3,0x2
ffffffffc0201220:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201222:	34e7fc63          	bgeu	a5,a4,ffffffffc020157a <pmm_init+0x600>
    return &pages[PPN(pa) - nbase];
ffffffffc0201226:	fff80737          	lui	a4,0xfff80
ffffffffc020122a:	97ba                	add	a5,a5,a4
ffffffffc020122c:	00379713          	slli	a4,a5,0x3
ffffffffc0201230:	00093603          	ld	a2,0(s2)
ffffffffc0201234:	97ba                	add	a5,a5,a4
ffffffffc0201236:	078e                	slli	a5,a5,0x3
ffffffffc0201238:	97b2                	add	a5,a5,a2
ffffffffc020123a:	52fa9063          	bne	s5,a5,ffffffffc020175a <pmm_init+0x7e0>
    assert((*ptep & PTE_U) == 0);
ffffffffc020123e:	8ac1                	andi	a3,a3,16
ffffffffc0201240:	6e069d63          	bnez	a3,ffffffffc020193a <pmm_init+0x9c0>

    page_remove(boot_pgdir, 0x0);
ffffffffc0201244:	6008                	ld	a0,0(s0)
ffffffffc0201246:	4581                	li	a1,0
ffffffffc0201248:	befff0ef          	jal	ra,ffffffffc0200e36 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc020124c:	000aa703          	lw	a4,0(s5)
ffffffffc0201250:	4785                	li	a5,1
ffffffffc0201252:	6cf71463          	bne	a4,a5,ffffffffc020191a <pmm_init+0x9a0>
    assert(page_ref(p2) == 0);
ffffffffc0201256:	000b2783          	lw	a5,0(s6)
ffffffffc020125a:	6a079063          	bnez	a5,ffffffffc02018fa <pmm_init+0x980>

    page_remove(boot_pgdir, PGSIZE);
ffffffffc020125e:	6008                	ld	a0,0(s0)
ffffffffc0201260:	6585                	lui	a1,0x1
ffffffffc0201262:	bd5ff0ef          	jal	ra,ffffffffc0200e36 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0201266:	000aa783          	lw	a5,0(s5)
ffffffffc020126a:	66079863          	bnez	a5,ffffffffc02018da <pmm_init+0x960>
    assert(page_ref(p2) == 0);
ffffffffc020126e:	000b2783          	lw	a5,0(s6)
ffffffffc0201272:	70079463          	bnez	a5,ffffffffc020197a <pmm_init+0xa00>

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc0201276:	00043b03          	ld	s6,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc020127a:	6090                	ld	a2,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020127c:	000b3783          	ld	a5,0(s6)
ffffffffc0201280:	078a                	slli	a5,a5,0x2
ffffffffc0201282:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201284:	2ec7fb63          	bgeu	a5,a2,ffffffffc020157a <pmm_init+0x600>
    return &pages[PPN(pa) - nbase];
ffffffffc0201288:	fff80737          	lui	a4,0xfff80
ffffffffc020128c:	973e                	add	a4,a4,a5
ffffffffc020128e:	00371793          	slli	a5,a4,0x3
ffffffffc0201292:	00093803          	ld	a6,0(s2)
ffffffffc0201296:	97ba                	add	a5,a5,a4
ffffffffc0201298:	078e                	slli	a5,a5,0x3
ffffffffc020129a:	00f80733          	add	a4,a6,a5
ffffffffc020129e:	4314                	lw	a3,0(a4)
ffffffffc02012a0:	4705                	li	a4,1
ffffffffc02012a2:	6ae69c63          	bne	a3,a4,ffffffffc020195a <pmm_init+0x9e0>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02012a6:	00004a97          	auipc	s5,0x4
ffffffffc02012aa:	9faa8a93          	addi	s5,s5,-1542 # ffffffffc0204ca0 <commands+0x838>
ffffffffc02012ae:	000ab703          	ld	a4,0(s5)
ffffffffc02012b2:	4037d693          	srai	a3,a5,0x3
ffffffffc02012b6:	00080bb7          	lui	s7,0x80
ffffffffc02012ba:	02e686b3          	mul	a3,a3,a4
ffffffffc02012be:	96de                	add	a3,a3,s7
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc02012c0:	00c69793          	slli	a5,a3,0xc
ffffffffc02012c4:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02012c6:	06b2                	slli	a3,a3,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc02012c8:	2ac7fb63          	bgeu	a5,a2,ffffffffc020157e <pmm_init+0x604>

    pde_t *pd1 = boot_pgdir, *pd0 = page2kva(pde2page(boot_pgdir[0]));
    free_page(pde2page(pd0[0]));
ffffffffc02012cc:	0009b703          	ld	a4,0(s3)
ffffffffc02012d0:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc02012d2:	629c                	ld	a5,0(a3)
ffffffffc02012d4:	078a                	slli	a5,a5,0x2
ffffffffc02012d6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02012d8:	2ac7f163          	bgeu	a5,a2,ffffffffc020157a <pmm_init+0x600>
    return &pages[PPN(pa) - nbase];
ffffffffc02012dc:	417787b3          	sub	a5,a5,s7
ffffffffc02012e0:	00379513          	slli	a0,a5,0x3
ffffffffc02012e4:	97aa                	add	a5,a5,a0
ffffffffc02012e6:	00379513          	slli	a0,a5,0x3
ffffffffc02012ea:	9542                	add	a0,a0,a6
ffffffffc02012ec:	4585                	li	a1,1
ffffffffc02012ee:	867ff0ef          	jal	ra,ffffffffc0200b54 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc02012f2:	000b3503          	ld	a0,0(s6)
    if (PPN(pa) >= npage) {
ffffffffc02012f6:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02012f8:	050a                	slli	a0,a0,0x2
ffffffffc02012fa:	8131                	srli	a0,a0,0xc
    if (PPN(pa) >= npage) {
ffffffffc02012fc:	26f57f63          	bgeu	a0,a5,ffffffffc020157a <pmm_init+0x600>
    return &pages[PPN(pa) - nbase];
ffffffffc0201300:	417507b3          	sub	a5,a0,s7
ffffffffc0201304:	00379513          	slli	a0,a5,0x3
ffffffffc0201308:	00093703          	ld	a4,0(s2)
ffffffffc020130c:	953e                	add	a0,a0,a5
ffffffffc020130e:	050e                	slli	a0,a0,0x3
    free_page(pde2page(pd1[0]));
ffffffffc0201310:	4585                	li	a1,1
ffffffffc0201312:	953a                	add	a0,a0,a4
ffffffffc0201314:	841ff0ef          	jal	ra,ffffffffc0200b54 <free_pages>
    boot_pgdir[0] = 0;
ffffffffc0201318:	601c                	ld	a5,0(s0)
ffffffffc020131a:	0007b023          	sd	zero,0(a5)

    assert(nr_free_store == nr_free_pages());
ffffffffc020131e:	87dff0ef          	jal	ra,ffffffffc0200b9a <nr_free_pages>
ffffffffc0201322:	2caa1663          	bne	s4,a0,ffffffffc02015ee <pmm_init+0x674>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0201326:	00004517          	auipc	a0,0x4
ffffffffc020132a:	e2250513          	addi	a0,a0,-478 # ffffffffc0205148 <commands+0xce0>
ffffffffc020132e:	d91fe0ef          	jal	ra,ffffffffc02000be <cprintf>
{
    size_t nr_free_store;
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();
ffffffffc0201332:	869ff0ef          	jal	ra,ffffffffc0200b9a <nr_free_pages>

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0201336:	6098                	ld	a4,0(s1)
ffffffffc0201338:	c02007b7          	lui	a5,0xc0200
    nr_free_store = nr_free_pages();
ffffffffc020133c:	8b2a                	mv	s6,a0
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc020133e:	00c71693          	slli	a3,a4,0xc
ffffffffc0201342:	1cd7fd63          	bgeu	a5,a3,ffffffffc020151c <pmm_init+0x5a2>
    {
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0201346:	83b1                	srli	a5,a5,0xc
ffffffffc0201348:	6008                	ld	a0,0(s0)
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc020134a:	c0200a37          	lui	s4,0xc0200
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc020134e:	1ce7f963          	bgeu	a5,a4,ffffffffc0201520 <pmm_init+0x5a6>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0201352:	7c7d                	lui	s8,0xfffff
ffffffffc0201354:	6b85                	lui	s7,0x1
ffffffffc0201356:	a029                	j	ffffffffc0201360 <pmm_init+0x3e6>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0201358:	00ca5713          	srli	a4,s4,0xc
ffffffffc020135c:	1cf77263          	bgeu	a4,a5,ffffffffc0201520 <pmm_init+0x5a6>
ffffffffc0201360:	0009b583          	ld	a1,0(s3)
ffffffffc0201364:	4601                	li	a2,0
ffffffffc0201366:	95d2                	add	a1,a1,s4
ffffffffc0201368:	873ff0ef          	jal	ra,ffffffffc0200bda <get_pte>
ffffffffc020136c:	1c050763          	beqz	a0,ffffffffc020153a <pmm_init+0x5c0>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0201370:	611c                	ld	a5,0(a0)
ffffffffc0201372:	078a                	slli	a5,a5,0x2
ffffffffc0201374:	0187f7b3          	and	a5,a5,s8
ffffffffc0201378:	1f479163          	bne	a5,s4,ffffffffc020155a <pmm_init+0x5e0>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc020137c:	609c                	ld	a5,0(s1)
ffffffffc020137e:	9a5e                	add	s4,s4,s7
ffffffffc0201380:	6008                	ld	a0,0(s0)
ffffffffc0201382:	00c79713          	slli	a4,a5,0xc
ffffffffc0201386:	fcea69e3          	bltu	s4,a4,ffffffffc0201358 <pmm_init+0x3de>
    }

    assert(boot_pgdir[0] == 0);
ffffffffc020138a:	611c                	ld	a5,0(a0)
ffffffffc020138c:	6a079363          	bnez	a5,ffffffffc0201a32 <pmm_init+0xab8>

    struct Page *p;
    p = alloc_page();
ffffffffc0201390:	4505                	li	a0,1
ffffffffc0201392:	f3aff0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc0201396:	8a2a                	mv	s4,a0
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0201398:	6008                	ld	a0,0(s0)
ffffffffc020139a:	4699                	li	a3,6
ffffffffc020139c:	10000613          	li	a2,256
ffffffffc02013a0:	85d2                	mv	a1,s4
ffffffffc02013a2:	b07ff0ef          	jal	ra,ffffffffc0200ea8 <page_insert>
ffffffffc02013a6:	66051663          	bnez	a0,ffffffffc0201a12 <pmm_init+0xa98>
    assert(page_ref(p) == 1);
ffffffffc02013aa:	000a2703          	lw	a4,0(s4) # ffffffffc0200000 <kern_entry>
ffffffffc02013ae:	4785                	li	a5,1
ffffffffc02013b0:	64f71163          	bne	a4,a5,ffffffffc02019f2 <pmm_init+0xa78>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02013b4:	6008                	ld	a0,0(s0)
ffffffffc02013b6:	6b85                	lui	s7,0x1
ffffffffc02013b8:	4699                	li	a3,6
ffffffffc02013ba:	100b8613          	addi	a2,s7,256 # 1100 <BASE_ADDRESS-0xffffffffc01fef00>
ffffffffc02013be:	85d2                	mv	a1,s4
ffffffffc02013c0:	ae9ff0ef          	jal	ra,ffffffffc0200ea8 <page_insert>
ffffffffc02013c4:	60051763          	bnez	a0,ffffffffc02019d2 <pmm_init+0xa58>
    assert(page_ref(p) == 2);
ffffffffc02013c8:	000a2703          	lw	a4,0(s4)
ffffffffc02013cc:	4789                	li	a5,2
ffffffffc02013ce:	4ef71663          	bne	a4,a5,ffffffffc02018ba <pmm_init+0x940>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc02013d2:	00004597          	auipc	a1,0x4
ffffffffc02013d6:	eae58593          	addi	a1,a1,-338 # ffffffffc0205280 <commands+0xe18>
ffffffffc02013da:	10000513          	li	a0,256
ffffffffc02013de:	211020ef          	jal	ra,ffffffffc0203dee <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02013e2:	100b8593          	addi	a1,s7,256
ffffffffc02013e6:	10000513          	li	a0,256
ffffffffc02013ea:	217020ef          	jal	ra,ffffffffc0203e00 <strcmp>
ffffffffc02013ee:	4a051663          	bnez	a0,ffffffffc020189a <pmm_init+0x920>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02013f2:	00093683          	ld	a3,0(s2)
ffffffffc02013f6:	000abc83          	ld	s9,0(s5)
ffffffffc02013fa:	00080c37          	lui	s8,0x80
ffffffffc02013fe:	40da06b3          	sub	a3,s4,a3
ffffffffc0201402:	868d                	srai	a3,a3,0x3
ffffffffc0201404:	039686b3          	mul	a3,a3,s9
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201408:	5afd                	li	s5,-1
ffffffffc020140a:	609c                	ld	a5,0(s1)
ffffffffc020140c:	00cada93          	srli	s5,s5,0xc
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201410:	96e2                	add	a3,a3,s8
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201412:	0156f733          	and	a4,a3,s5
    return page2ppn(page) << PGSHIFT;
ffffffffc0201416:	06b2                	slli	a3,a3,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201418:	16f77363          	bgeu	a4,a5,ffffffffc020157e <pmm_init+0x604>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc020141c:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0201420:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0201424:	96be                	add	a3,a3,a5
ffffffffc0201426:	10068023          	sb	zero,256(a3) # fffffffffffff100 <end+0x3fdedb60>
    assert(strlen((const char *)0x100) == 0);
ffffffffc020142a:	181020ef          	jal	ra,ffffffffc0203daa <strlen>
ffffffffc020142e:	44051663          	bnez	a0,ffffffffc020187a <pmm_init+0x900>

    pde_t *pd1 = boot_pgdir, *pd0 = page2kva(pde2page(boot_pgdir[0]));
ffffffffc0201432:	00043b83          	ld	s7,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc0201436:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201438:	000bb783          	ld	a5,0(s7)
ffffffffc020143c:	078a                	slli	a5,a5,0x2
ffffffffc020143e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201440:	12e7fd63          	bgeu	a5,a4,ffffffffc020157a <pmm_init+0x600>
    return &pages[PPN(pa) - nbase];
ffffffffc0201444:	418787b3          	sub	a5,a5,s8
ffffffffc0201448:	00379693          	slli	a3,a5,0x3
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020144c:	96be                	add	a3,a3,a5
ffffffffc020144e:	039686b3          	mul	a3,a3,s9
ffffffffc0201452:	96e2                	add	a3,a3,s8
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201454:	0156fab3          	and	s5,a3,s5
    return page2ppn(page) << PGSHIFT;
ffffffffc0201458:	06b2                	slli	a3,a3,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc020145a:	12eaf263          	bgeu	s5,a4,ffffffffc020157e <pmm_init+0x604>
ffffffffc020145e:	0009b983          	ld	s3,0(s3)
    free_page(p);
ffffffffc0201462:	4585                	li	a1,1
ffffffffc0201464:	8552                	mv	a0,s4
ffffffffc0201466:	99b6                	add	s3,s3,a3
ffffffffc0201468:	eecff0ef          	jal	ra,ffffffffc0200b54 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc020146c:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage) {
ffffffffc0201470:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201472:	078a                	slli	a5,a5,0x2
ffffffffc0201474:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201476:	10e7f263          	bgeu	a5,a4,ffffffffc020157a <pmm_init+0x600>
    return &pages[PPN(pa) - nbase];
ffffffffc020147a:	fff809b7          	lui	s3,0xfff80
ffffffffc020147e:	97ce                	add	a5,a5,s3
ffffffffc0201480:	00379513          	slli	a0,a5,0x3
ffffffffc0201484:	00093703          	ld	a4,0(s2)
ffffffffc0201488:	97aa                	add	a5,a5,a0
ffffffffc020148a:	00379513          	slli	a0,a5,0x3
    free_page(pde2page(pd0[0]));
ffffffffc020148e:	953a                	add	a0,a0,a4
ffffffffc0201490:	4585                	li	a1,1
ffffffffc0201492:	ec2ff0ef          	jal	ra,ffffffffc0200b54 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0201496:	000bb503          	ld	a0,0(s7)
    if (PPN(pa) >= npage) {
ffffffffc020149a:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020149c:	050a                	slli	a0,a0,0x2
ffffffffc020149e:	8131                	srli	a0,a0,0xc
    if (PPN(pa) >= npage) {
ffffffffc02014a0:	0cf57d63          	bgeu	a0,a5,ffffffffc020157a <pmm_init+0x600>
    return &pages[PPN(pa) - nbase];
ffffffffc02014a4:	013507b3          	add	a5,a0,s3
ffffffffc02014a8:	00379513          	slli	a0,a5,0x3
ffffffffc02014ac:	00093703          	ld	a4,0(s2)
ffffffffc02014b0:	953e                	add	a0,a0,a5
ffffffffc02014b2:	050e                	slli	a0,a0,0x3
    free_page(pde2page(pd1[0]));
ffffffffc02014b4:	4585                	li	a1,1
ffffffffc02014b6:	953a                	add	a0,a0,a4
ffffffffc02014b8:	e9cff0ef          	jal	ra,ffffffffc0200b54 <free_pages>
    boot_pgdir[0] = 0;
ffffffffc02014bc:	601c                	ld	a5,0(s0)
ffffffffc02014be:	0007b023          	sd	zero,0(a5) # ffffffffc0200000 <kern_entry>

    assert(nr_free_store == nr_free_pages());
ffffffffc02014c2:	ed8ff0ef          	jal	ra,ffffffffc0200b9a <nr_free_pages>
ffffffffc02014c6:	38ab1a63          	bne	s6,a0,ffffffffc020185a <pmm_init+0x8e0>
}
ffffffffc02014ca:	6446                	ld	s0,80(sp)
ffffffffc02014cc:	60e6                	ld	ra,88(sp)
ffffffffc02014ce:	64a6                	ld	s1,72(sp)
ffffffffc02014d0:	6906                	ld	s2,64(sp)
ffffffffc02014d2:	79e2                	ld	s3,56(sp)
ffffffffc02014d4:	7a42                	ld	s4,48(sp)
ffffffffc02014d6:	7aa2                	ld	s5,40(sp)
ffffffffc02014d8:	7b02                	ld	s6,32(sp)
ffffffffc02014da:	6be2                	ld	s7,24(sp)
ffffffffc02014dc:	6c42                	ld	s8,16(sp)
ffffffffc02014de:	6ca2                	ld	s9,8(sp)

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc02014e0:	00004517          	auipc	a0,0x4
ffffffffc02014e4:	e1850513          	addi	a0,a0,-488 # ffffffffc02052f8 <commands+0xe90>
}
ffffffffc02014e8:	6125                	addi	sp,sp,96
    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc02014ea:	bd5fe06f          	j	ffffffffc02000be <cprintf>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02014ee:	6705                	lui	a4,0x1
ffffffffc02014f0:	177d                	addi	a4,a4,-1
ffffffffc02014f2:	96ba                	add	a3,a3,a4
    if (PPN(pa) >= npage) {
ffffffffc02014f4:	00c6d713          	srli	a4,a3,0xc
ffffffffc02014f8:	08f77163          	bgeu	a4,a5,ffffffffc020157a <pmm_init+0x600>
    pmm_manager->init_memmap(base, n);
ffffffffc02014fc:	00043803          	ld	a6,0(s0)
    return &pages[PPN(pa) - nbase];
ffffffffc0201500:	9732                	add	a4,a4,a2
ffffffffc0201502:	00371793          	slli	a5,a4,0x3
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201506:	767d                	lui	a2,0xfffff
ffffffffc0201508:	8ef1                	and	a3,a3,a2
ffffffffc020150a:	97ba                	add	a5,a5,a4
    pmm_manager->init_memmap(base, n);
ffffffffc020150c:	01083703          	ld	a4,16(a6)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201510:	8d95                	sub	a1,a1,a3
ffffffffc0201512:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0201514:	81b1                	srli	a1,a1,0xc
ffffffffc0201516:	953e                	add	a0,a0,a5
ffffffffc0201518:	9702                	jalr	a4
ffffffffc020151a:	bebd                	j	ffffffffc0201098 <pmm_init+0x11e>
ffffffffc020151c:	6008                	ld	a0,0(s0)
ffffffffc020151e:	b5b5                	j	ffffffffc020138a <pmm_init+0x410>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0201520:	86d2                	mv	a3,s4
ffffffffc0201522:	00003617          	auipc	a2,0x3
ffffffffc0201526:	78660613          	addi	a2,a2,1926 # ffffffffc0204ca8 <commands+0x840>
ffffffffc020152a:	1e300593          	li	a1,483
ffffffffc020152e:	00003517          	auipc	a0,0x3
ffffffffc0201532:	7a250513          	addi	a0,a0,1954 # ffffffffc0204cd0 <commands+0x868>
ffffffffc0201536:	bcffe0ef          	jal	ra,ffffffffc0200104 <__panic>
ffffffffc020153a:	00004697          	auipc	a3,0x4
ffffffffc020153e:	c2e68693          	addi	a3,a3,-978 # ffffffffc0205168 <commands+0xd00>
ffffffffc0201542:	00004617          	auipc	a2,0x4
ffffffffc0201546:	91660613          	addi	a2,a2,-1770 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc020154a:	1e300593          	li	a1,483
ffffffffc020154e:	00003517          	auipc	a0,0x3
ffffffffc0201552:	78250513          	addi	a0,a0,1922 # ffffffffc0204cd0 <commands+0x868>
ffffffffc0201556:	baffe0ef          	jal	ra,ffffffffc0200104 <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc020155a:	00004697          	auipc	a3,0x4
ffffffffc020155e:	c4e68693          	addi	a3,a3,-946 # ffffffffc02051a8 <commands+0xd40>
ffffffffc0201562:	00004617          	auipc	a2,0x4
ffffffffc0201566:	8f660613          	addi	a2,a2,-1802 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc020156a:	1e400593          	li	a1,484
ffffffffc020156e:	00003517          	auipc	a0,0x3
ffffffffc0201572:	76250513          	addi	a0,a0,1890 # ffffffffc0204cd0 <commands+0x868>
ffffffffc0201576:	b8ffe0ef          	jal	ra,ffffffffc0200104 <__panic>
ffffffffc020157a:	d36ff0ef          	jal	ra,ffffffffc0200ab0 <pa2page.part.4>
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc020157e:	00003617          	auipc	a2,0x3
ffffffffc0201582:	72a60613          	addi	a2,a2,1834 # ffffffffc0204ca8 <commands+0x840>
ffffffffc0201586:	06a00593          	li	a1,106
ffffffffc020158a:	00003517          	auipc	a0,0x3
ffffffffc020158e:	7b650513          	addi	a0,a0,1974 # ffffffffc0204d40 <commands+0x8d8>
ffffffffc0201592:	b73fe0ef          	jal	ra,ffffffffc0200104 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0201596:	00004617          	auipc	a2,0x4
ffffffffc020159a:	99a60613          	addi	a2,a2,-1638 # ffffffffc0204f30 <commands+0xac8>
ffffffffc020159e:	07000593          	li	a1,112
ffffffffc02015a2:	00003517          	auipc	a0,0x3
ffffffffc02015a6:	79e50513          	addi	a0,a0,1950 # ffffffffc0204d40 <commands+0x8d8>
ffffffffc02015aa:	b5bfe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc02015ae:	00004697          	auipc	a3,0x4
ffffffffc02015b2:	8c268693          	addi	a3,a3,-1854 # ffffffffc0204e70 <commands+0xa08>
ffffffffc02015b6:	00004617          	auipc	a2,0x4
ffffffffc02015ba:	8a260613          	addi	a2,a2,-1886 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc02015be:	1a700593          	li	a1,423
ffffffffc02015c2:	00003517          	auipc	a0,0x3
ffffffffc02015c6:	70e50513          	addi	a0,a0,1806 # ffffffffc0204cd0 <commands+0x868>
ffffffffc02015ca:	b3bfe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc02015ce:	00004697          	auipc	a3,0x4
ffffffffc02015d2:	8da68693          	addi	a3,a3,-1830 # ffffffffc0204ea8 <commands+0xa40>
ffffffffc02015d6:	00004617          	auipc	a2,0x4
ffffffffc02015da:	88260613          	addi	a2,a2,-1918 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc02015de:	1a800593          	li	a1,424
ffffffffc02015e2:	00003517          	auipc	a0,0x3
ffffffffc02015e6:	6ee50513          	addi	a0,a0,1774 # ffffffffc0204cd0 <commands+0x868>
ffffffffc02015ea:	b1bfe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc02015ee:	00004697          	auipc	a3,0x4
ffffffffc02015f2:	b3268693          	addi	a3,a3,-1230 # ffffffffc0205120 <commands+0xcb8>
ffffffffc02015f6:	00004617          	auipc	a2,0x4
ffffffffc02015fa:	86260613          	addi	a2,a2,-1950 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc02015fe:	1d400593          	li	a1,468
ffffffffc0201602:	00003517          	auipc	a0,0x3
ffffffffc0201606:	6ce50513          	addi	a0,a0,1742 # ffffffffc0204cd0 <commands+0x868>
ffffffffc020160a:	afbfe0ef          	jal	ra,ffffffffc0200104 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020160e:	00003617          	auipc	a2,0x3
ffffffffc0201612:	7e260613          	addi	a2,a2,2018 # ffffffffc0204df0 <commands+0x988>
ffffffffc0201616:	08200593          	li	a1,130
ffffffffc020161a:	00003517          	auipc	a0,0x3
ffffffffc020161e:	6b650513          	addi	a0,a0,1718 # ffffffffc0204cd0 <commands+0x868>
ffffffffc0201622:	ae3fe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc0201626:	00004697          	auipc	a3,0x4
ffffffffc020162a:	8da68693          	addi	a3,a3,-1830 # ffffffffc0204f00 <commands+0xa98>
ffffffffc020162e:	00004617          	auipc	a2,0x4
ffffffffc0201632:	82a60613          	addi	a2,a2,-2006 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0201636:	1ae00593          	li	a1,430
ffffffffc020163a:	00003517          	auipc	a0,0x3
ffffffffc020163e:	69650513          	addi	a0,a0,1686 # ffffffffc0204cd0 <commands+0x868>
ffffffffc0201642:	ac3fe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc0201646:	00004697          	auipc	a3,0x4
ffffffffc020164a:	88a68693          	addi	a3,a3,-1910 # ffffffffc0204ed0 <commands+0xa68>
ffffffffc020164e:	00004617          	auipc	a2,0x4
ffffffffc0201652:	80a60613          	addi	a2,a2,-2038 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0201656:	1ac00593          	li	a1,428
ffffffffc020165a:	00003517          	auipc	a0,0x3
ffffffffc020165e:	67650513          	addi	a0,a0,1654 # ffffffffc0204cd0 <commands+0x868>
ffffffffc0201662:	aa3fe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(*ptep & PTE_U);
ffffffffc0201666:	00004697          	auipc	a3,0x4
ffffffffc020166a:	9b268693          	addi	a3,a3,-1614 # ffffffffc0205018 <commands+0xbb0>
ffffffffc020166e:	00003617          	auipc	a2,0x3
ffffffffc0201672:	7ea60613          	addi	a2,a2,2026 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0201676:	1b900593          	li	a1,441
ffffffffc020167a:	00003517          	auipc	a0,0x3
ffffffffc020167e:	65650513          	addi	a0,a0,1622 # ffffffffc0204cd0 <commands+0x868>
ffffffffc0201682:	a83fe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0201686:	00004697          	auipc	a3,0x4
ffffffffc020168a:	96268693          	addi	a3,a3,-1694 # ffffffffc0204fe8 <commands+0xb80>
ffffffffc020168e:	00003617          	auipc	a2,0x3
ffffffffc0201692:	7ca60613          	addi	a2,a2,1994 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0201696:	1b800593          	li	a1,440
ffffffffc020169a:	00003517          	auipc	a0,0x3
ffffffffc020169e:	63650513          	addi	a0,a0,1590 # ffffffffc0204cd0 <commands+0x868>
ffffffffc02016a2:	a63fe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02016a6:	00004697          	auipc	a3,0x4
ffffffffc02016aa:	90a68693          	addi	a3,a3,-1782 # ffffffffc0204fb0 <commands+0xb48>
ffffffffc02016ae:	00003617          	auipc	a2,0x3
ffffffffc02016b2:	7aa60613          	addi	a2,a2,1962 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc02016b6:	1b700593          	li	a1,439
ffffffffc02016ba:	00003517          	auipc	a0,0x3
ffffffffc02016be:	61650513          	addi	a0,a0,1558 # ffffffffc0204cd0 <commands+0x868>
ffffffffc02016c2:	a43fe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc02016c6:	00004697          	auipc	a3,0x4
ffffffffc02016ca:	8c268693          	addi	a3,a3,-1854 # ffffffffc0204f88 <commands+0xb20>
ffffffffc02016ce:	00003617          	auipc	a2,0x3
ffffffffc02016d2:	78a60613          	addi	a2,a2,1930 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc02016d6:	1b400593          	li	a1,436
ffffffffc02016da:	00003517          	auipc	a0,0x3
ffffffffc02016de:	5f650513          	addi	a0,a0,1526 # ffffffffc0204cd0 <commands+0x868>
ffffffffc02016e2:	a23fe0ef          	jal	ra,ffffffffc0200104 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02016e6:	86da                	mv	a3,s6
ffffffffc02016e8:	00003617          	auipc	a2,0x3
ffffffffc02016ec:	5c060613          	addi	a2,a2,1472 # ffffffffc0204ca8 <commands+0x840>
ffffffffc02016f0:	1b300593          	li	a1,435
ffffffffc02016f4:	00003517          	auipc	a0,0x3
ffffffffc02016f8:	5dc50513          	addi	a0,a0,1500 # ffffffffc0204cd0 <commands+0x868>
ffffffffc02016fc:	a09fe0ef          	jal	ra,ffffffffc0200104 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc0201700:	86be                	mv	a3,a5
ffffffffc0201702:	00003617          	auipc	a2,0x3
ffffffffc0201706:	5a660613          	addi	a2,a2,1446 # ffffffffc0204ca8 <commands+0x840>
ffffffffc020170a:	1b200593          	li	a1,434
ffffffffc020170e:	00003517          	auipc	a0,0x3
ffffffffc0201712:	5c250513          	addi	a0,a0,1474 # ffffffffc0204cd0 <commands+0x868>
ffffffffc0201716:	9effe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc020171a:	00004697          	auipc	a3,0x4
ffffffffc020171e:	85668693          	addi	a3,a3,-1962 # ffffffffc0204f70 <commands+0xb08>
ffffffffc0201722:	00003617          	auipc	a2,0x3
ffffffffc0201726:	73660613          	addi	a2,a2,1846 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc020172a:	1b000593          	li	a1,432
ffffffffc020172e:	00003517          	auipc	a0,0x3
ffffffffc0201732:	5a250513          	addi	a0,a0,1442 # ffffffffc0204cd0 <commands+0x868>
ffffffffc0201736:	9cffe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc020173a:	00004697          	auipc	a3,0x4
ffffffffc020173e:	81e68693          	addi	a3,a3,-2018 # ffffffffc0204f58 <commands+0xaf0>
ffffffffc0201742:	00003617          	auipc	a2,0x3
ffffffffc0201746:	71660613          	addi	a2,a2,1814 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc020174a:	1af00593          	li	a1,431
ffffffffc020174e:	00003517          	auipc	a0,0x3
ffffffffc0201752:	58250513          	addi	a0,a0,1410 # ffffffffc0204cd0 <commands+0x868>
ffffffffc0201756:	9affe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc020175a:	00003697          	auipc	a3,0x3
ffffffffc020175e:	7fe68693          	addi	a3,a3,2046 # ffffffffc0204f58 <commands+0xaf0>
ffffffffc0201762:	00003617          	auipc	a2,0x3
ffffffffc0201766:	6f660613          	addi	a2,a2,1782 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc020176a:	1c200593          	li	a1,450
ffffffffc020176e:	00003517          	auipc	a0,0x3
ffffffffc0201772:	56250513          	addi	a0,a0,1378 # ffffffffc0204cd0 <commands+0x868>
ffffffffc0201776:	98ffe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc020177a:	00004697          	auipc	a3,0x4
ffffffffc020177e:	86e68693          	addi	a3,a3,-1938 # ffffffffc0204fe8 <commands+0xb80>
ffffffffc0201782:	00003617          	auipc	a2,0x3
ffffffffc0201786:	6d660613          	addi	a2,a2,1750 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc020178a:	1c100593          	li	a1,449
ffffffffc020178e:	00003517          	auipc	a0,0x3
ffffffffc0201792:	54250513          	addi	a0,a0,1346 # ffffffffc0204cd0 <commands+0x868>
ffffffffc0201796:	96ffe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020179a:	00004697          	auipc	a3,0x4
ffffffffc020179e:	91668693          	addi	a3,a3,-1770 # ffffffffc02050b0 <commands+0xc48>
ffffffffc02017a2:	00003617          	auipc	a2,0x3
ffffffffc02017a6:	6b660613          	addi	a2,a2,1718 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc02017aa:	1c000593          	li	a1,448
ffffffffc02017ae:	00003517          	auipc	a0,0x3
ffffffffc02017b2:	52250513          	addi	a0,a0,1314 # ffffffffc0204cd0 <commands+0x868>
ffffffffc02017b6:	94ffe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc02017ba:	00004697          	auipc	a3,0x4
ffffffffc02017be:	8de68693          	addi	a3,a3,-1826 # ffffffffc0205098 <commands+0xc30>
ffffffffc02017c2:	00003617          	auipc	a2,0x3
ffffffffc02017c6:	69660613          	addi	a2,a2,1686 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc02017ca:	1bf00593          	li	a1,447
ffffffffc02017ce:	00003517          	auipc	a0,0x3
ffffffffc02017d2:	50250513          	addi	a0,a0,1282 # ffffffffc0204cd0 <commands+0x868>
ffffffffc02017d6:	92ffe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc02017da:	00004697          	auipc	a3,0x4
ffffffffc02017de:	88e68693          	addi	a3,a3,-1906 # ffffffffc0205068 <commands+0xc00>
ffffffffc02017e2:	00003617          	auipc	a2,0x3
ffffffffc02017e6:	67660613          	addi	a2,a2,1654 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc02017ea:	1be00593          	li	a1,446
ffffffffc02017ee:	00003517          	auipc	a0,0x3
ffffffffc02017f2:	4e250513          	addi	a0,a0,1250 # ffffffffc0204cd0 <commands+0x868>
ffffffffc02017f6:	90ffe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc02017fa:	00004697          	auipc	a3,0x4
ffffffffc02017fe:	85668693          	addi	a3,a3,-1962 # ffffffffc0205050 <commands+0xbe8>
ffffffffc0201802:	00003617          	auipc	a2,0x3
ffffffffc0201806:	65660613          	addi	a2,a2,1622 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc020180a:	1bc00593          	li	a1,444
ffffffffc020180e:	00003517          	auipc	a0,0x3
ffffffffc0201812:	4c250513          	addi	a0,a0,1218 # ffffffffc0204cd0 <commands+0x868>
ffffffffc0201816:	8effe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc020181a:	00004697          	auipc	a3,0x4
ffffffffc020181e:	81e68693          	addi	a3,a3,-2018 # ffffffffc0205038 <commands+0xbd0>
ffffffffc0201822:	00003617          	auipc	a2,0x3
ffffffffc0201826:	63660613          	addi	a2,a2,1590 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc020182a:	1bb00593          	li	a1,443
ffffffffc020182e:	00003517          	auipc	a0,0x3
ffffffffc0201832:	4a250513          	addi	a0,a0,1186 # ffffffffc0204cd0 <commands+0x868>
ffffffffc0201836:	8cffe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(*ptep & PTE_W);
ffffffffc020183a:	00003697          	auipc	a3,0x3
ffffffffc020183e:	7ee68693          	addi	a3,a3,2030 # ffffffffc0205028 <commands+0xbc0>
ffffffffc0201842:	00003617          	auipc	a2,0x3
ffffffffc0201846:	61660613          	addi	a2,a2,1558 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc020184a:	1ba00593          	li	a1,442
ffffffffc020184e:	00003517          	auipc	a0,0x3
ffffffffc0201852:	48250513          	addi	a0,a0,1154 # ffffffffc0204cd0 <commands+0x868>
ffffffffc0201856:	8affe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc020185a:	00004697          	auipc	a3,0x4
ffffffffc020185e:	8c668693          	addi	a3,a3,-1850 # ffffffffc0205120 <commands+0xcb8>
ffffffffc0201862:	00003617          	auipc	a2,0x3
ffffffffc0201866:	5f660613          	addi	a2,a2,1526 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc020186a:	1fd00593          	li	a1,509
ffffffffc020186e:	00003517          	auipc	a0,0x3
ffffffffc0201872:	46250513          	addi	a0,a0,1122 # ffffffffc0204cd0 <commands+0x868>
ffffffffc0201876:	88ffe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc020187a:	00004697          	auipc	a3,0x4
ffffffffc020187e:	a5668693          	addi	a3,a3,-1450 # ffffffffc02052d0 <commands+0xe68>
ffffffffc0201882:	00003617          	auipc	a2,0x3
ffffffffc0201886:	5d660613          	addi	a2,a2,1494 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc020188a:	1f500593          	li	a1,501
ffffffffc020188e:	00003517          	auipc	a0,0x3
ffffffffc0201892:	44250513          	addi	a0,a0,1090 # ffffffffc0204cd0 <commands+0x868>
ffffffffc0201896:	86ffe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc020189a:	00004697          	auipc	a3,0x4
ffffffffc020189e:	9fe68693          	addi	a3,a3,-1538 # ffffffffc0205298 <commands+0xe30>
ffffffffc02018a2:	00003617          	auipc	a2,0x3
ffffffffc02018a6:	5b660613          	addi	a2,a2,1462 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc02018aa:	1f200593          	li	a1,498
ffffffffc02018ae:	00003517          	auipc	a0,0x3
ffffffffc02018b2:	42250513          	addi	a0,a0,1058 # ffffffffc0204cd0 <commands+0x868>
ffffffffc02018b6:	84ffe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(page_ref(p) == 2);
ffffffffc02018ba:	00004697          	auipc	a3,0x4
ffffffffc02018be:	9ae68693          	addi	a3,a3,-1618 # ffffffffc0205268 <commands+0xe00>
ffffffffc02018c2:	00003617          	auipc	a2,0x3
ffffffffc02018c6:	59660613          	addi	a2,a2,1430 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc02018ca:	1ee00593          	li	a1,494
ffffffffc02018ce:	00003517          	auipc	a0,0x3
ffffffffc02018d2:	40250513          	addi	a0,a0,1026 # ffffffffc0204cd0 <commands+0x868>
ffffffffc02018d6:	82ffe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc02018da:	00004697          	auipc	a3,0x4
ffffffffc02018de:	80668693          	addi	a3,a3,-2042 # ffffffffc02050e0 <commands+0xc78>
ffffffffc02018e2:	00003617          	auipc	a2,0x3
ffffffffc02018e6:	57660613          	addi	a2,a2,1398 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc02018ea:	1ca00593          	li	a1,458
ffffffffc02018ee:	00003517          	auipc	a0,0x3
ffffffffc02018f2:	3e250513          	addi	a0,a0,994 # ffffffffc0204cd0 <commands+0x868>
ffffffffc02018f6:	80ffe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02018fa:	00003697          	auipc	a3,0x3
ffffffffc02018fe:	7b668693          	addi	a3,a3,1974 # ffffffffc02050b0 <commands+0xc48>
ffffffffc0201902:	00003617          	auipc	a2,0x3
ffffffffc0201906:	55660613          	addi	a2,a2,1366 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc020190a:	1c700593          	li	a1,455
ffffffffc020190e:	00003517          	auipc	a0,0x3
ffffffffc0201912:	3c250513          	addi	a0,a0,962 # ffffffffc0204cd0 <commands+0x868>
ffffffffc0201916:	feefe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc020191a:	00003697          	auipc	a3,0x3
ffffffffc020191e:	65668693          	addi	a3,a3,1622 # ffffffffc0204f70 <commands+0xb08>
ffffffffc0201922:	00003617          	auipc	a2,0x3
ffffffffc0201926:	53660613          	addi	a2,a2,1334 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc020192a:	1c600593          	li	a1,454
ffffffffc020192e:	00003517          	auipc	a0,0x3
ffffffffc0201932:	3a250513          	addi	a0,a0,930 # ffffffffc0204cd0 <commands+0x868>
ffffffffc0201936:	fcefe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc020193a:	00003697          	auipc	a3,0x3
ffffffffc020193e:	78e68693          	addi	a3,a3,1934 # ffffffffc02050c8 <commands+0xc60>
ffffffffc0201942:	00003617          	auipc	a2,0x3
ffffffffc0201946:	51660613          	addi	a2,a2,1302 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc020194a:	1c300593          	li	a1,451
ffffffffc020194e:	00003517          	auipc	a0,0x3
ffffffffc0201952:	38250513          	addi	a0,a0,898 # ffffffffc0204cd0 <commands+0x868>
ffffffffc0201956:	faefe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc020195a:	00003697          	auipc	a3,0x3
ffffffffc020195e:	79e68693          	addi	a3,a3,1950 # ffffffffc02050f8 <commands+0xc90>
ffffffffc0201962:	00003617          	auipc	a2,0x3
ffffffffc0201966:	4f660613          	addi	a2,a2,1270 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc020196a:	1cd00593          	li	a1,461
ffffffffc020196e:	00003517          	auipc	a0,0x3
ffffffffc0201972:	36250513          	addi	a0,a0,866 # ffffffffc0204cd0 <commands+0x868>
ffffffffc0201976:	f8efe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020197a:	00003697          	auipc	a3,0x3
ffffffffc020197e:	73668693          	addi	a3,a3,1846 # ffffffffc02050b0 <commands+0xc48>
ffffffffc0201982:	00003617          	auipc	a2,0x3
ffffffffc0201986:	4d660613          	addi	a2,a2,1238 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc020198a:	1cb00593          	li	a1,459
ffffffffc020198e:	00003517          	auipc	a0,0x3
ffffffffc0201992:	34250513          	addi	a0,a0,834 # ffffffffc0204cd0 <commands+0x868>
ffffffffc0201996:	f6efe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc020199a:	00003697          	auipc	a3,0x3
ffffffffc020199e:	49e68693          	addi	a3,a3,1182 # ffffffffc0204e38 <commands+0x9d0>
ffffffffc02019a2:	00003617          	auipc	a2,0x3
ffffffffc02019a6:	4b660613          	addi	a2,a2,1206 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc02019aa:	1a600593          	li	a1,422
ffffffffc02019ae:	00003517          	auipc	a0,0x3
ffffffffc02019b2:	32250513          	addi	a0,a0,802 # ffffffffc0204cd0 <commands+0x868>
ffffffffc02019b6:	f4efe0ef          	jal	ra,ffffffffc0200104 <__panic>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc02019ba:	00003617          	auipc	a2,0x3
ffffffffc02019be:	43660613          	addi	a2,a2,1078 # ffffffffc0204df0 <commands+0x988>
ffffffffc02019c2:	0c800593          	li	a1,200
ffffffffc02019c6:	00003517          	auipc	a0,0x3
ffffffffc02019ca:	30a50513          	addi	a0,a0,778 # ffffffffc0204cd0 <commands+0x868>
ffffffffc02019ce:	f36fe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02019d2:	00004697          	auipc	a3,0x4
ffffffffc02019d6:	85668693          	addi	a3,a3,-1962 # ffffffffc0205228 <commands+0xdc0>
ffffffffc02019da:	00003617          	auipc	a2,0x3
ffffffffc02019de:	47e60613          	addi	a2,a2,1150 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc02019e2:	1ed00593          	li	a1,493
ffffffffc02019e6:	00003517          	auipc	a0,0x3
ffffffffc02019ea:	2ea50513          	addi	a0,a0,746 # ffffffffc0204cd0 <commands+0x868>
ffffffffc02019ee:	f16fe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(page_ref(p) == 1);
ffffffffc02019f2:	00004697          	auipc	a3,0x4
ffffffffc02019f6:	81e68693          	addi	a3,a3,-2018 # ffffffffc0205210 <commands+0xda8>
ffffffffc02019fa:	00003617          	auipc	a2,0x3
ffffffffc02019fe:	45e60613          	addi	a2,a2,1118 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0201a02:	1ec00593          	li	a1,492
ffffffffc0201a06:	00003517          	auipc	a0,0x3
ffffffffc0201a0a:	2ca50513          	addi	a0,a0,714 # ffffffffc0204cd0 <commands+0x868>
ffffffffc0201a0e:	ef6fe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0201a12:	00003697          	auipc	a3,0x3
ffffffffc0201a16:	7c668693          	addi	a3,a3,1990 # ffffffffc02051d8 <commands+0xd70>
ffffffffc0201a1a:	00003617          	auipc	a2,0x3
ffffffffc0201a1e:	43e60613          	addi	a2,a2,1086 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0201a22:	1eb00593          	li	a1,491
ffffffffc0201a26:	00003517          	auipc	a0,0x3
ffffffffc0201a2a:	2aa50513          	addi	a0,a0,682 # ffffffffc0204cd0 <commands+0x868>
ffffffffc0201a2e:	ed6fe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(boot_pgdir[0] == 0);
ffffffffc0201a32:	00003697          	auipc	a3,0x3
ffffffffc0201a36:	78e68693          	addi	a3,a3,1934 # ffffffffc02051c0 <commands+0xd58>
ffffffffc0201a3a:	00003617          	auipc	a2,0x3
ffffffffc0201a3e:	41e60613          	addi	a2,a2,1054 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0201a42:	1e700593          	li	a1,487
ffffffffc0201a46:	00003517          	auipc	a0,0x3
ffffffffc0201a4a:	28a50513          	addi	a0,a0,650 # ffffffffc0204cd0 <commands+0x868>
ffffffffc0201a4e:	eb6fe0ef          	jal	ra,ffffffffc0200104 <__panic>

ffffffffc0201a52 <tlb_invalidate>:
static inline void flush_tlb() { asm volatile("sfence.vma"); }
ffffffffc0201a52:	12000073          	sfence.vma
void tlb_invalidate(pde_t *pgdir, uintptr_t la) { flush_tlb(); }
ffffffffc0201a56:	8082                	ret

ffffffffc0201a58 <pgdir_alloc_page>:
{
ffffffffc0201a58:	7179                	addi	sp,sp,-48
ffffffffc0201a5a:	e84a                	sd	s2,16(sp)
ffffffffc0201a5c:	892a                	mv	s2,a0
    struct Page *page = alloc_page();
ffffffffc0201a5e:	4505                	li	a0,1
{
ffffffffc0201a60:	f022                	sd	s0,32(sp)
ffffffffc0201a62:	ec26                	sd	s1,24(sp)
ffffffffc0201a64:	e44e                	sd	s3,8(sp)
ffffffffc0201a66:	f406                	sd	ra,40(sp)
ffffffffc0201a68:	84ae                	mv	s1,a1
ffffffffc0201a6a:	89b2                	mv	s3,a2
    struct Page *page = alloc_page();
ffffffffc0201a6c:	860ff0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc0201a70:	842a                	mv	s0,a0
    if (page != NULL)
ffffffffc0201a72:	cd19                	beqz	a0,ffffffffc0201a90 <pgdir_alloc_page+0x38>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc0201a74:	85aa                	mv	a1,a0
ffffffffc0201a76:	86ce                	mv	a3,s3
ffffffffc0201a78:	8626                	mv	a2,s1
ffffffffc0201a7a:	854a                	mv	a0,s2
ffffffffc0201a7c:	c2cff0ef          	jal	ra,ffffffffc0200ea8 <page_insert>
ffffffffc0201a80:	ed39                	bnez	a0,ffffffffc0201ade <pgdir_alloc_page+0x86>
        if (swap_init_ok)
ffffffffc0201a82:	00010797          	auipc	a5,0x10
ffffffffc0201a86:	9ee78793          	addi	a5,a5,-1554 # ffffffffc0211470 <swap_init_ok>
ffffffffc0201a8a:	439c                	lw	a5,0(a5)
ffffffffc0201a8c:	2781                	sext.w	a5,a5
ffffffffc0201a8e:	eb89                	bnez	a5,ffffffffc0201aa0 <pgdir_alloc_page+0x48>
}
ffffffffc0201a90:	8522                	mv	a0,s0
ffffffffc0201a92:	70a2                	ld	ra,40(sp)
ffffffffc0201a94:	7402                	ld	s0,32(sp)
ffffffffc0201a96:	64e2                	ld	s1,24(sp)
ffffffffc0201a98:	6942                	ld	s2,16(sp)
ffffffffc0201a9a:	69a2                	ld	s3,8(sp)
ffffffffc0201a9c:	6145                	addi	sp,sp,48
ffffffffc0201a9e:	8082                	ret
            swap_map_swappable(check_mm_struct, la, page, 0);
ffffffffc0201aa0:	00010797          	auipc	a5,0x10
ffffffffc0201aa4:	a1878793          	addi	a5,a5,-1512 # ffffffffc02114b8 <check_mm_struct>
ffffffffc0201aa8:	6388                	ld	a0,0(a5)
ffffffffc0201aaa:	4681                	li	a3,0
ffffffffc0201aac:	8622                	mv	a2,s0
ffffffffc0201aae:	85a6                	mv	a1,s1
ffffffffc0201ab0:	074010ef          	jal	ra,ffffffffc0202b24 <swap_map_swappable>
            assert(page_ref(page) == 1);
ffffffffc0201ab4:	4018                	lw	a4,0(s0)
            page->pra_vaddr = la;
ffffffffc0201ab6:	e024                	sd	s1,64(s0)
            assert(page_ref(page) == 1);
ffffffffc0201ab8:	4785                	li	a5,1
ffffffffc0201aba:	fcf70be3          	beq	a4,a5,ffffffffc0201a90 <pgdir_alloc_page+0x38>
ffffffffc0201abe:	00003697          	auipc	a3,0x3
ffffffffc0201ac2:	29268693          	addi	a3,a3,658 # ffffffffc0204d50 <commands+0x8e8>
ffffffffc0201ac6:	00003617          	auipc	a2,0x3
ffffffffc0201aca:	39260613          	addi	a2,a2,914 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0201ace:	18c00593          	li	a1,396
ffffffffc0201ad2:	00003517          	auipc	a0,0x3
ffffffffc0201ad6:	1fe50513          	addi	a0,a0,510 # ffffffffc0204cd0 <commands+0x868>
ffffffffc0201ada:	e2afe0ef          	jal	ra,ffffffffc0200104 <__panic>
            free_page(page);
ffffffffc0201ade:	8522                	mv	a0,s0
ffffffffc0201ae0:	4585                	li	a1,1
ffffffffc0201ae2:	872ff0ef          	jal	ra,ffffffffc0200b54 <free_pages>
            return NULL;
ffffffffc0201ae6:	4401                	li	s0,0
ffffffffc0201ae8:	b765                	j	ffffffffc0201a90 <pgdir_alloc_page+0x38>

ffffffffc0201aea <kmalloc>:
}

void *kmalloc(size_t n)
{
ffffffffc0201aea:	1141                	addi	sp,sp,-16
    void *ptr = NULL;
    struct Page *base = NULL;
    assert(n > 0 && n < 1024 * 0124);
ffffffffc0201aec:	67d5                	lui	a5,0x15
{
ffffffffc0201aee:	e406                	sd	ra,8(sp)
    assert(n > 0 && n < 1024 * 0124);
ffffffffc0201af0:	fff50713          	addi	a4,a0,-1
ffffffffc0201af4:	17f9                	addi	a5,a5,-2
ffffffffc0201af6:	04e7ee63          	bltu	a5,a4,ffffffffc0201b52 <kmalloc+0x68>
    int num_pages = (n + PGSIZE - 1) / PGSIZE;
ffffffffc0201afa:	6785                	lui	a5,0x1
ffffffffc0201afc:	17fd                	addi	a5,a5,-1
ffffffffc0201afe:	953e                	add	a0,a0,a5
    base = alloc_pages(num_pages);
ffffffffc0201b00:	8131                	srli	a0,a0,0xc
ffffffffc0201b02:	fcbfe0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
    assert(base != NULL);
ffffffffc0201b06:	c159                	beqz	a0,ffffffffc0201b8c <kmalloc+0xa2>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201b08:	00010797          	auipc	a5,0x10
ffffffffc0201b0c:	9a878793          	addi	a5,a5,-1624 # ffffffffc02114b0 <pages>
ffffffffc0201b10:	639c                	ld	a5,0(a5)
ffffffffc0201b12:	8d1d                	sub	a0,a0,a5
ffffffffc0201b14:	00003797          	auipc	a5,0x3
ffffffffc0201b18:	18c78793          	addi	a5,a5,396 # ffffffffc0204ca0 <commands+0x838>
ffffffffc0201b1c:	6394                	ld	a3,0(a5)
ffffffffc0201b1e:	850d                	srai	a0,a0,0x3
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201b20:	00010797          	auipc	a5,0x10
ffffffffc0201b24:	93878793          	addi	a5,a5,-1736 # ffffffffc0211458 <npage>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201b28:	02d50533          	mul	a0,a0,a3
ffffffffc0201b2c:	000806b7          	lui	a3,0x80
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201b30:	6398                	ld	a4,0(a5)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201b32:	9536                	add	a0,a0,a3
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201b34:	00c51793          	slli	a5,a0,0xc
ffffffffc0201b38:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201b3a:	0532                	slli	a0,a0,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201b3c:	02e7fb63          	bgeu	a5,a4,ffffffffc0201b72 <kmalloc+0x88>
ffffffffc0201b40:	00010797          	auipc	a5,0x10
ffffffffc0201b44:	96078793          	addi	a5,a5,-1696 # ffffffffc02114a0 <va_pa_offset>
ffffffffc0201b48:	639c                	ld	a5,0(a5)
    ptr = page2kva(base);
    return ptr;
}
ffffffffc0201b4a:	60a2                	ld	ra,8(sp)
ffffffffc0201b4c:	953e                	add	a0,a0,a5
ffffffffc0201b4e:	0141                	addi	sp,sp,16
ffffffffc0201b50:	8082                	ret
    assert(n > 0 && n < 1024 * 0124);
ffffffffc0201b52:	00003697          	auipc	a3,0x3
ffffffffc0201b56:	19e68693          	addi	a3,a3,414 # ffffffffc0204cf0 <commands+0x888>
ffffffffc0201b5a:	00003617          	auipc	a2,0x3
ffffffffc0201b5e:	2fe60613          	addi	a2,a2,766 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0201b62:	20600593          	li	a1,518
ffffffffc0201b66:	00003517          	auipc	a0,0x3
ffffffffc0201b6a:	16a50513          	addi	a0,a0,362 # ffffffffc0204cd0 <commands+0x868>
ffffffffc0201b6e:	d96fe0ef          	jal	ra,ffffffffc0200104 <__panic>
ffffffffc0201b72:	86aa                	mv	a3,a0
ffffffffc0201b74:	00003617          	auipc	a2,0x3
ffffffffc0201b78:	13460613          	addi	a2,a2,308 # ffffffffc0204ca8 <commands+0x840>
ffffffffc0201b7c:	06a00593          	li	a1,106
ffffffffc0201b80:	00003517          	auipc	a0,0x3
ffffffffc0201b84:	1c050513          	addi	a0,a0,448 # ffffffffc0204d40 <commands+0x8d8>
ffffffffc0201b88:	d7cfe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(base != NULL);
ffffffffc0201b8c:	00003697          	auipc	a3,0x3
ffffffffc0201b90:	18468693          	addi	a3,a3,388 # ffffffffc0204d10 <commands+0x8a8>
ffffffffc0201b94:	00003617          	auipc	a2,0x3
ffffffffc0201b98:	2c460613          	addi	a2,a2,708 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0201b9c:	20900593          	li	a1,521
ffffffffc0201ba0:	00003517          	auipc	a0,0x3
ffffffffc0201ba4:	13050513          	addi	a0,a0,304 # ffffffffc0204cd0 <commands+0x868>
ffffffffc0201ba8:	d5cfe0ef          	jal	ra,ffffffffc0200104 <__panic>

ffffffffc0201bac <kfree>:

void kfree(void *ptr, size_t n)
{
ffffffffc0201bac:	1141                	addi	sp,sp,-16
    assert(n > 0 && n < 1024 * 0124);
ffffffffc0201bae:	67d5                	lui	a5,0x15
{
ffffffffc0201bb0:	e406                	sd	ra,8(sp)
    assert(n > 0 && n < 1024 * 0124);
ffffffffc0201bb2:	fff58713          	addi	a4,a1,-1
ffffffffc0201bb6:	17f9                	addi	a5,a5,-2
ffffffffc0201bb8:	04e7eb63          	bltu	a5,a4,ffffffffc0201c0e <kfree+0x62>
    assert(ptr != NULL);
ffffffffc0201bbc:	c941                	beqz	a0,ffffffffc0201c4c <kfree+0xa0>
    struct Page *base = NULL;
    int num_pages = (n + PGSIZE - 1) / PGSIZE;
ffffffffc0201bbe:	6785                	lui	a5,0x1
ffffffffc0201bc0:	17fd                	addi	a5,a5,-1
ffffffffc0201bc2:	95be                	add	a1,a1,a5
static inline struct Page *kva2page(void *kva) { return pa2page(PADDR(kva)); }
ffffffffc0201bc4:	c02007b7          	lui	a5,0xc0200
ffffffffc0201bc8:	81b1                	srli	a1,a1,0xc
ffffffffc0201bca:	06f56463          	bltu	a0,a5,ffffffffc0201c32 <kfree+0x86>
ffffffffc0201bce:	00010797          	auipc	a5,0x10
ffffffffc0201bd2:	8d278793          	addi	a5,a5,-1838 # ffffffffc02114a0 <va_pa_offset>
ffffffffc0201bd6:	639c                	ld	a5,0(a5)
    if (PPN(pa) >= npage) {
ffffffffc0201bd8:	00010717          	auipc	a4,0x10
ffffffffc0201bdc:	88070713          	addi	a4,a4,-1920 # ffffffffc0211458 <npage>
ffffffffc0201be0:	6318                	ld	a4,0(a4)
static inline struct Page *kva2page(void *kva) { return pa2page(PADDR(kva)); }
ffffffffc0201be2:	40f507b3          	sub	a5,a0,a5
    if (PPN(pa) >= npage) {
ffffffffc0201be6:	83b1                	srli	a5,a5,0xc
ffffffffc0201be8:	04e7f363          	bgeu	a5,a4,ffffffffc0201c2e <kfree+0x82>
    return &pages[PPN(pa) - nbase];
ffffffffc0201bec:	fff80537          	lui	a0,0xfff80
ffffffffc0201bf0:	97aa                	add	a5,a5,a0
ffffffffc0201bf2:	00010697          	auipc	a3,0x10
ffffffffc0201bf6:	8be68693          	addi	a3,a3,-1858 # ffffffffc02114b0 <pages>
ffffffffc0201bfa:	6288                	ld	a0,0(a3)
ffffffffc0201bfc:	00379713          	slli	a4,a5,0x3
    base = kva2page(ptr);
    free_pages(base, num_pages);
}
ffffffffc0201c00:	60a2                	ld	ra,8(sp)
ffffffffc0201c02:	97ba                	add	a5,a5,a4
ffffffffc0201c04:	078e                	slli	a5,a5,0x3
    free_pages(base, num_pages);
ffffffffc0201c06:	953e                	add	a0,a0,a5
}
ffffffffc0201c08:	0141                	addi	sp,sp,16
    free_pages(base, num_pages);
ffffffffc0201c0a:	f4bfe06f          	j	ffffffffc0200b54 <free_pages>
    assert(n > 0 && n < 1024 * 0124);
ffffffffc0201c0e:	00003697          	auipc	a3,0x3
ffffffffc0201c12:	0e268693          	addi	a3,a3,226 # ffffffffc0204cf0 <commands+0x888>
ffffffffc0201c16:	00003617          	auipc	a2,0x3
ffffffffc0201c1a:	24260613          	addi	a2,a2,578 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0201c1e:	21000593          	li	a1,528
ffffffffc0201c22:	00003517          	auipc	a0,0x3
ffffffffc0201c26:	0ae50513          	addi	a0,a0,174 # ffffffffc0204cd0 <commands+0x868>
ffffffffc0201c2a:	cdafe0ef          	jal	ra,ffffffffc0200104 <__panic>
ffffffffc0201c2e:	e83fe0ef          	jal	ra,ffffffffc0200ab0 <pa2page.part.4>
static inline struct Page *kva2page(void *kva) { return pa2page(PADDR(kva)); }
ffffffffc0201c32:	86aa                	mv	a3,a0
ffffffffc0201c34:	00003617          	auipc	a2,0x3
ffffffffc0201c38:	1bc60613          	addi	a2,a2,444 # ffffffffc0204df0 <commands+0x988>
ffffffffc0201c3c:	06c00593          	li	a1,108
ffffffffc0201c40:	00003517          	auipc	a0,0x3
ffffffffc0201c44:	10050513          	addi	a0,a0,256 # ffffffffc0204d40 <commands+0x8d8>
ffffffffc0201c48:	cbcfe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(ptr != NULL);
ffffffffc0201c4c:	00003697          	auipc	a3,0x3
ffffffffc0201c50:	09468693          	addi	a3,a3,148 # ffffffffc0204ce0 <commands+0x878>
ffffffffc0201c54:	00003617          	auipc	a2,0x3
ffffffffc0201c58:	20460613          	addi	a2,a2,516 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0201c5c:	21100593          	li	a1,529
ffffffffc0201c60:	00003517          	auipc	a0,0x3
ffffffffc0201c64:	07050513          	addi	a0,a0,112 # ffffffffc0204cd0 <commands+0x868>
ffffffffc0201c68:	c9cfe0ef          	jal	ra,ffffffffc0200104 <__panic>

ffffffffc0201c6c <check_vma_overlap.isra.0.part.1>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0201c6c:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0201c6e:	00003697          	auipc	a3,0x3
ffffffffc0201c72:	6aa68693          	addi	a3,a3,1706 # ffffffffc0205318 <commands+0xeb0>
ffffffffc0201c76:	00003617          	auipc	a2,0x3
ffffffffc0201c7a:	1e260613          	addi	a2,a2,482 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0201c7e:	08c00593          	li	a1,140
ffffffffc0201c82:	00003517          	auipc	a0,0x3
ffffffffc0201c86:	6b650513          	addi	a0,a0,1718 # ffffffffc0205338 <commands+0xed0>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0201c8a:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0201c8c:	c78fe0ef          	jal	ra,ffffffffc0200104 <__panic>

ffffffffc0201c90 <mm_create>:
{
ffffffffc0201c90:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0201c92:	03000513          	li	a0,48
{
ffffffffc0201c96:	e022                	sd	s0,0(sp)
ffffffffc0201c98:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0201c9a:	e51ff0ef          	jal	ra,ffffffffc0201aea <kmalloc>
ffffffffc0201c9e:	842a                	mv	s0,a0
    if (mm != NULL)
ffffffffc0201ca0:	c115                	beqz	a0,ffffffffc0201cc4 <mm_create+0x34>
        if (swap_init_ok)
ffffffffc0201ca2:	0000f797          	auipc	a5,0xf
ffffffffc0201ca6:	7ce78793          	addi	a5,a5,1998 # ffffffffc0211470 <swap_init_ok>
ffffffffc0201caa:	439c                	lw	a5,0(a5)
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0201cac:	e408                	sd	a0,8(s0)
ffffffffc0201cae:	e008                	sd	a0,0(s0)
        mm->mmap_cache = NULL;
ffffffffc0201cb0:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0201cb4:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0201cb8:	02052023          	sw	zero,32(a0)
        if (swap_init_ok)
ffffffffc0201cbc:	2781                	sext.w	a5,a5
ffffffffc0201cbe:	eb81                	bnez	a5,ffffffffc0201cce <mm_create+0x3e>
            mm->sm_priv = NULL;
ffffffffc0201cc0:	02053423          	sd	zero,40(a0)
}
ffffffffc0201cc4:	8522                	mv	a0,s0
ffffffffc0201cc6:	60a2                	ld	ra,8(sp)
ffffffffc0201cc8:	6402                	ld	s0,0(sp)
ffffffffc0201cca:	0141                	addi	sp,sp,16
ffffffffc0201ccc:	8082                	ret
            swap_init_mm(mm);
ffffffffc0201cce:	647000ef          	jal	ra,ffffffffc0202b14 <swap_init_mm>
}
ffffffffc0201cd2:	8522                	mv	a0,s0
ffffffffc0201cd4:	60a2                	ld	ra,8(sp)
ffffffffc0201cd6:	6402                	ld	s0,0(sp)
ffffffffc0201cd8:	0141                	addi	sp,sp,16
ffffffffc0201cda:	8082                	ret

ffffffffc0201cdc <vma_create>:
{
ffffffffc0201cdc:	1101                	addi	sp,sp,-32
ffffffffc0201cde:	e04a                	sd	s2,0(sp)
ffffffffc0201ce0:	892a                	mv	s2,a0
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0201ce2:	03000513          	li	a0,48
{
ffffffffc0201ce6:	e822                	sd	s0,16(sp)
ffffffffc0201ce8:	e426                	sd	s1,8(sp)
ffffffffc0201cea:	ec06                	sd	ra,24(sp)
ffffffffc0201cec:	84ae                	mv	s1,a1
ffffffffc0201cee:	8432                	mv	s0,a2
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0201cf0:	dfbff0ef          	jal	ra,ffffffffc0201aea <kmalloc>
    if (vma != NULL)
ffffffffc0201cf4:	c509                	beqz	a0,ffffffffc0201cfe <vma_create+0x22>
        vma->vm_start = vm_start;
ffffffffc0201cf6:	01253423          	sd	s2,8(a0)
        vma->vm_end = vm_end;
ffffffffc0201cfa:	e904                	sd	s1,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0201cfc:	ed00                	sd	s0,24(a0)
}
ffffffffc0201cfe:	60e2                	ld	ra,24(sp)
ffffffffc0201d00:	6442                	ld	s0,16(sp)
ffffffffc0201d02:	64a2                	ld	s1,8(sp)
ffffffffc0201d04:	6902                	ld	s2,0(sp)
ffffffffc0201d06:	6105                	addi	sp,sp,32
ffffffffc0201d08:	8082                	ret

ffffffffc0201d0a <find_vma>:
    if (mm != NULL)
ffffffffc0201d0a:	c51d                	beqz	a0,ffffffffc0201d38 <find_vma+0x2e>
        vma = mm->mmap_cache;
ffffffffc0201d0c:	691c                	ld	a5,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0201d0e:	c781                	beqz	a5,ffffffffc0201d16 <find_vma+0xc>
ffffffffc0201d10:	6798                	ld	a4,8(a5)
ffffffffc0201d12:	02e5f663          	bgeu	a1,a4,ffffffffc0201d3e <find_vma+0x34>
            list_entry_t *list = &(mm->mmap_list), *le = list;
ffffffffc0201d16:	87aa                	mv	a5,a0
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0201d18:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc0201d1a:	00f50f63          	beq	a0,a5,ffffffffc0201d38 <find_vma+0x2e>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc0201d1e:	fe87b703          	ld	a4,-24(a5)
ffffffffc0201d22:	fee5ebe3          	bltu	a1,a4,ffffffffc0201d18 <find_vma+0xe>
ffffffffc0201d26:	ff07b703          	ld	a4,-16(a5)
ffffffffc0201d2a:	fee5f7e3          	bgeu	a1,a4,ffffffffc0201d18 <find_vma+0xe>
                vma = le2vma(le, list_link);
ffffffffc0201d2e:	1781                	addi	a5,a5,-32
        if (vma != NULL)
ffffffffc0201d30:	c781                	beqz	a5,ffffffffc0201d38 <find_vma+0x2e>
            mm->mmap_cache = vma;
ffffffffc0201d32:	e91c                	sd	a5,16(a0)
}
ffffffffc0201d34:	853e                	mv	a0,a5
ffffffffc0201d36:	8082                	ret
    struct vma_struct *vma = NULL;
ffffffffc0201d38:	4781                	li	a5,0
}
ffffffffc0201d3a:	853e                	mv	a0,a5
ffffffffc0201d3c:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0201d3e:	6b98                	ld	a4,16(a5)
ffffffffc0201d40:	fce5fbe3          	bgeu	a1,a4,ffffffffc0201d16 <find_vma+0xc>
            mm->mmap_cache = vma;
ffffffffc0201d44:	e91c                	sd	a5,16(a0)
    return vma;
ffffffffc0201d46:	b7fd                	j	ffffffffc0201d34 <find_vma+0x2a>

ffffffffc0201d48 <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc0201d48:	6590                	ld	a2,8(a1)
ffffffffc0201d4a:	0105b803          	ld	a6,16(a1)
{
ffffffffc0201d4e:	1141                	addi	sp,sp,-16
ffffffffc0201d50:	e406                	sd	ra,8(sp)
ffffffffc0201d52:	872a                	mv	a4,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0201d54:	01066863          	bltu	a2,a6,ffffffffc0201d64 <insert_vma_struct+0x1c>
ffffffffc0201d58:	a8b9                	j	ffffffffc0201db6 <insert_vma_struct+0x6e>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0201d5a:	fe87b683          	ld	a3,-24(a5)
ffffffffc0201d5e:	04d66763          	bltu	a2,a3,ffffffffc0201dac <insert_vma_struct+0x64>
ffffffffc0201d62:	873e                	mv	a4,a5
ffffffffc0201d64:	671c                	ld	a5,8(a4)
    while ((le = list_next(le)) != list)
ffffffffc0201d66:	fef51ae3          	bne	a0,a5,ffffffffc0201d5a <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc0201d6a:	02a70463          	beq	a4,a0,ffffffffc0201d92 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0201d6e:	ff073683          	ld	a3,-16(a4)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0201d72:	fe873883          	ld	a7,-24(a4)
ffffffffc0201d76:	08d8f063          	bgeu	a7,a3,ffffffffc0201df6 <insert_vma_struct+0xae>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0201d7a:	04d66e63          	bltu	a2,a3,ffffffffc0201dd6 <insert_vma_struct+0x8e>
    }
    if (le_next != list)
ffffffffc0201d7e:	00f50a63          	beq	a0,a5,ffffffffc0201d92 <insert_vma_struct+0x4a>
ffffffffc0201d82:	fe87b683          	ld	a3,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0201d86:	0506e863          	bltu	a3,a6,ffffffffc0201dd6 <insert_vma_struct+0x8e>
    assert(next->vm_start < next->vm_end);
ffffffffc0201d8a:	ff07b603          	ld	a2,-16(a5)
ffffffffc0201d8e:	02c6f263          	bgeu	a3,a2,ffffffffc0201db2 <insert_vma_struct+0x6a>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0201d92:	5114                	lw	a3,32(a0)
    vma->vm_mm = mm;
ffffffffc0201d94:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0201d96:	02058613          	addi	a2,a1,32
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201d9a:	e390                	sd	a2,0(a5)
ffffffffc0201d9c:	e710                	sd	a2,8(a4)
}
ffffffffc0201d9e:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0201da0:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0201da2:	f198                	sd	a4,32(a1)
    mm->map_count++;
ffffffffc0201da4:	2685                	addiw	a3,a3,1
ffffffffc0201da6:	d114                	sw	a3,32(a0)
}
ffffffffc0201da8:	0141                	addi	sp,sp,16
ffffffffc0201daa:	8082                	ret
    if (le_prev != list)
ffffffffc0201dac:	fca711e3          	bne	a4,a0,ffffffffc0201d6e <insert_vma_struct+0x26>
ffffffffc0201db0:	bfd9                	j	ffffffffc0201d86 <insert_vma_struct+0x3e>
ffffffffc0201db2:	ebbff0ef          	jal	ra,ffffffffc0201c6c <check_vma_overlap.isra.0.part.1>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0201db6:	00003697          	auipc	a3,0x3
ffffffffc0201dba:	61268693          	addi	a3,a3,1554 # ffffffffc02053c8 <commands+0xf60>
ffffffffc0201dbe:	00003617          	auipc	a2,0x3
ffffffffc0201dc2:	09a60613          	addi	a2,a2,154 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0201dc6:	09200593          	li	a1,146
ffffffffc0201dca:	00003517          	auipc	a0,0x3
ffffffffc0201dce:	56e50513          	addi	a0,a0,1390 # ffffffffc0205338 <commands+0xed0>
ffffffffc0201dd2:	b32fe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0201dd6:	00003697          	auipc	a3,0x3
ffffffffc0201dda:	63268693          	addi	a3,a3,1586 # ffffffffc0205408 <commands+0xfa0>
ffffffffc0201dde:	00003617          	auipc	a2,0x3
ffffffffc0201de2:	07a60613          	addi	a2,a2,122 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0201de6:	08b00593          	li	a1,139
ffffffffc0201dea:	00003517          	auipc	a0,0x3
ffffffffc0201dee:	54e50513          	addi	a0,a0,1358 # ffffffffc0205338 <commands+0xed0>
ffffffffc0201df2:	b12fe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0201df6:	00003697          	auipc	a3,0x3
ffffffffc0201dfa:	5f268693          	addi	a3,a3,1522 # ffffffffc02053e8 <commands+0xf80>
ffffffffc0201dfe:	00003617          	auipc	a2,0x3
ffffffffc0201e02:	05a60613          	addi	a2,a2,90 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0201e06:	08a00593          	li	a1,138
ffffffffc0201e0a:	00003517          	auipc	a0,0x3
ffffffffc0201e0e:	52e50513          	addi	a0,a0,1326 # ffffffffc0205338 <commands+0xed0>
ffffffffc0201e12:	af2fe0ef          	jal	ra,ffffffffc0200104 <__panic>

ffffffffc0201e16 <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
ffffffffc0201e16:	1141                	addi	sp,sp,-16
ffffffffc0201e18:	e022                	sd	s0,0(sp)
ffffffffc0201e1a:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc0201e1c:	6508                	ld	a0,8(a0)
ffffffffc0201e1e:	e406                	sd	ra,8(sp)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc0201e20:	00a40e63          	beq	s0,a0,ffffffffc0201e3c <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc0201e24:	6118                	ld	a4,0(a0)
ffffffffc0201e26:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link), sizeof(struct vma_struct)); // kfree vma
ffffffffc0201e28:	03000593          	li	a1,48
ffffffffc0201e2c:	1501                	addi	a0,a0,-32
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201e2e:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0201e30:	e398                	sd	a4,0(a5)
ffffffffc0201e32:	d7bff0ef          	jal	ra,ffffffffc0201bac <kfree>
    return listelm->next;
ffffffffc0201e36:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc0201e38:	fea416e3          	bne	s0,a0,ffffffffc0201e24 <mm_destroy+0xe>
    }
    kfree(mm, sizeof(struct mm_struct)); // kfree mm
ffffffffc0201e3c:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc0201e3e:	6402                	ld	s0,0(sp)
ffffffffc0201e40:	60a2                	ld	ra,8(sp)
    kfree(mm, sizeof(struct mm_struct)); // kfree mm
ffffffffc0201e42:	03000593          	li	a1,48
}
ffffffffc0201e46:	0141                	addi	sp,sp,16
    kfree(mm, sizeof(struct mm_struct)); // kfree mm
ffffffffc0201e48:	b395                	j	ffffffffc0201bac <kfree>

ffffffffc0201e4a <vmm_init>:

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0201e4a:	715d                	addi	sp,sp,-80
ffffffffc0201e4c:	e486                	sd	ra,72(sp)
ffffffffc0201e4e:	e0a2                	sd	s0,64(sp)
ffffffffc0201e50:	fc26                	sd	s1,56(sp)
ffffffffc0201e52:	f84a                	sd	s2,48(sp)
ffffffffc0201e54:	f052                	sd	s4,32(sp)
ffffffffc0201e56:	f44e                	sd	s3,40(sp)
ffffffffc0201e58:	ec56                	sd	s5,24(sp)
ffffffffc0201e5a:	e85a                	sd	s6,16(sp)
ffffffffc0201e5c:	e45e                	sd	s7,8(sp)

// check_vmm - check correctness of vmm
static void
check_vmm(void)
{
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0201e5e:	d3dfe0ef          	jal	ra,ffffffffc0200b9a <nr_free_pages>
ffffffffc0201e62:	892a                	mv	s2,a0
}

static void
check_vma_struct(void)
{
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0201e64:	d37fe0ef          	jal	ra,ffffffffc0200b9a <nr_free_pages>
ffffffffc0201e68:	8a2a                	mv	s4,a0

    struct mm_struct *mm = mm_create();
ffffffffc0201e6a:	e27ff0ef          	jal	ra,ffffffffc0201c90 <mm_create>
    assert(mm != NULL);
ffffffffc0201e6e:	842a                	mv	s0,a0
ffffffffc0201e70:	03200493          	li	s1,50
ffffffffc0201e74:	e919                	bnez	a0,ffffffffc0201e8a <vmm_init+0x40>
ffffffffc0201e76:	aeed                	j	ffffffffc0202270 <vmm_init+0x426>
        vma->vm_start = vm_start;
ffffffffc0201e78:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc0201e7a:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0201e7c:	00053c23          	sd	zero,24(a0)
    int i;
    for (i = step1; i >= 1; i--)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0201e80:	14ed                	addi	s1,s1,-5
ffffffffc0201e82:	8522                	mv	a0,s0
ffffffffc0201e84:	ec5ff0ef          	jal	ra,ffffffffc0201d48 <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0201e88:	c88d                	beqz	s1,ffffffffc0201eba <vmm_init+0x70>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0201e8a:	03000513          	li	a0,48
ffffffffc0201e8e:	c5dff0ef          	jal	ra,ffffffffc0201aea <kmalloc>
ffffffffc0201e92:	85aa                	mv	a1,a0
ffffffffc0201e94:	00248793          	addi	a5,s1,2
    if (vma != NULL)
ffffffffc0201e98:	f165                	bnez	a0,ffffffffc0201e78 <vmm_init+0x2e>
        assert(vma != NULL);
ffffffffc0201e9a:	00003697          	auipc	a3,0x3
ffffffffc0201e9e:	7b668693          	addi	a3,a3,1974 # ffffffffc0205650 <commands+0x11e8>
ffffffffc0201ea2:	00003617          	auipc	a2,0x3
ffffffffc0201ea6:	fb660613          	addi	a2,a2,-74 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0201eaa:	0e400593          	li	a1,228
ffffffffc0201eae:	00003517          	auipc	a0,0x3
ffffffffc0201eb2:	48a50513          	addi	a0,a0,1162 # ffffffffc0205338 <commands+0xed0>
ffffffffc0201eb6:	a4efe0ef          	jal	ra,ffffffffc0200104 <__panic>
    for (i = step1; i >= 1; i--)
ffffffffc0201eba:	03700493          	li	s1,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0201ebe:	1f900993          	li	s3,505
ffffffffc0201ec2:	a819                	j	ffffffffc0201ed8 <vmm_init+0x8e>
        vma->vm_start = vm_start;
ffffffffc0201ec4:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc0201ec6:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0201ec8:	00053c23          	sd	zero,24(a0)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0201ecc:	0495                	addi	s1,s1,5
ffffffffc0201ece:	8522                	mv	a0,s0
ffffffffc0201ed0:	e79ff0ef          	jal	ra,ffffffffc0201d48 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0201ed4:	03348a63          	beq	s1,s3,ffffffffc0201f08 <vmm_init+0xbe>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0201ed8:	03000513          	li	a0,48
ffffffffc0201edc:	c0fff0ef          	jal	ra,ffffffffc0201aea <kmalloc>
ffffffffc0201ee0:	85aa                	mv	a1,a0
ffffffffc0201ee2:	00248793          	addi	a5,s1,2
    if (vma != NULL)
ffffffffc0201ee6:	fd79                	bnez	a0,ffffffffc0201ec4 <vmm_init+0x7a>
        assert(vma != NULL);
ffffffffc0201ee8:	00003697          	auipc	a3,0x3
ffffffffc0201eec:	76868693          	addi	a3,a3,1896 # ffffffffc0205650 <commands+0x11e8>
ffffffffc0201ef0:	00003617          	auipc	a2,0x3
ffffffffc0201ef4:	f6860613          	addi	a2,a2,-152 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0201ef8:	0eb00593          	li	a1,235
ffffffffc0201efc:	00003517          	auipc	a0,0x3
ffffffffc0201f00:	43c50513          	addi	a0,a0,1084 # ffffffffc0205338 <commands+0xed0>
ffffffffc0201f04:	a00fe0ef          	jal	ra,ffffffffc0200104 <__panic>
ffffffffc0201f08:	6418                	ld	a4,8(s0)
ffffffffc0201f0a:	479d                	li	a5,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0201f0c:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0201f10:	2ae40063          	beq	s0,a4,ffffffffc02021b0 <vmm_init+0x366>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0201f14:	fe873603          	ld	a2,-24(a4)
ffffffffc0201f18:	ffe78693          	addi	a3,a5,-2
ffffffffc0201f1c:	20d61a63          	bne	a2,a3,ffffffffc0202130 <vmm_init+0x2e6>
ffffffffc0201f20:	ff073683          	ld	a3,-16(a4)
ffffffffc0201f24:	20d79663          	bne	a5,a3,ffffffffc0202130 <vmm_init+0x2e6>
ffffffffc0201f28:	0795                	addi	a5,a5,5
ffffffffc0201f2a:	6718                	ld	a4,8(a4)
    for (i = 1; i <= step2; i++)
ffffffffc0201f2c:	feb792e3          	bne	a5,a1,ffffffffc0201f10 <vmm_init+0xc6>
ffffffffc0201f30:	499d                	li	s3,7
ffffffffc0201f32:	4495                	li	s1,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0201f34:	1f900b93          	li	s7,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0201f38:	85a6                	mv	a1,s1
ffffffffc0201f3a:	8522                	mv	a0,s0
ffffffffc0201f3c:	dcfff0ef          	jal	ra,ffffffffc0201d0a <find_vma>
ffffffffc0201f40:	8b2a                	mv	s6,a0
        assert(vma1 != NULL);
ffffffffc0201f42:	2e050763          	beqz	a0,ffffffffc0202230 <vmm_init+0x3e6>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0201f46:	00148593          	addi	a1,s1,1
ffffffffc0201f4a:	8522                	mv	a0,s0
ffffffffc0201f4c:	dbfff0ef          	jal	ra,ffffffffc0201d0a <find_vma>
ffffffffc0201f50:	8aaa                	mv	s5,a0
        assert(vma2 != NULL);
ffffffffc0201f52:	2a050f63          	beqz	a0,ffffffffc0202210 <vmm_init+0x3c6>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0201f56:	85ce                	mv	a1,s3
ffffffffc0201f58:	8522                	mv	a0,s0
ffffffffc0201f5a:	db1ff0ef          	jal	ra,ffffffffc0201d0a <find_vma>
        assert(vma3 == NULL);
ffffffffc0201f5e:	28051963          	bnez	a0,ffffffffc02021f0 <vmm_init+0x3a6>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0201f62:	00348593          	addi	a1,s1,3
ffffffffc0201f66:	8522                	mv	a0,s0
ffffffffc0201f68:	da3ff0ef          	jal	ra,ffffffffc0201d0a <find_vma>
        assert(vma4 == NULL);
ffffffffc0201f6c:	26051263          	bnez	a0,ffffffffc02021d0 <vmm_init+0x386>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0201f70:	00448593          	addi	a1,s1,4
ffffffffc0201f74:	8522                	mv	a0,s0
ffffffffc0201f76:	d95ff0ef          	jal	ra,ffffffffc0201d0a <find_vma>
        assert(vma5 == NULL);
ffffffffc0201f7a:	2c051b63          	bnez	a0,ffffffffc0202250 <vmm_init+0x406>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0201f7e:	008b3783          	ld	a5,8(s6)
ffffffffc0201f82:	1c979763          	bne	a5,s1,ffffffffc0202150 <vmm_init+0x306>
ffffffffc0201f86:	010b3783          	ld	a5,16(s6)
ffffffffc0201f8a:	1d379363          	bne	a5,s3,ffffffffc0202150 <vmm_init+0x306>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0201f8e:	008ab783          	ld	a5,8(s5)
ffffffffc0201f92:	1c979f63          	bne	a5,s1,ffffffffc0202170 <vmm_init+0x326>
ffffffffc0201f96:	010ab783          	ld	a5,16(s5)
ffffffffc0201f9a:	1d379b63          	bne	a5,s3,ffffffffc0202170 <vmm_init+0x326>
ffffffffc0201f9e:	0495                	addi	s1,s1,5
ffffffffc0201fa0:	0995                	addi	s3,s3,5
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0201fa2:	f9749be3          	bne	s1,s7,ffffffffc0201f38 <vmm_init+0xee>
ffffffffc0201fa6:	4491                	li	s1,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0201fa8:	59fd                	li	s3,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0201faa:	85a6                	mv	a1,s1
ffffffffc0201fac:	8522                	mv	a0,s0
ffffffffc0201fae:	d5dff0ef          	jal	ra,ffffffffc0201d0a <find_vma>
ffffffffc0201fb2:	0004859b          	sext.w	a1,s1
        if (vma_below_5 != NULL)
ffffffffc0201fb6:	c90d                	beqz	a0,ffffffffc0201fe8 <vmm_init+0x19e>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0201fb8:	6914                	ld	a3,16(a0)
ffffffffc0201fba:	6510                	ld	a2,8(a0)
ffffffffc0201fbc:	00003517          	auipc	a0,0x3
ffffffffc0201fc0:	57c50513          	addi	a0,a0,1404 # ffffffffc0205538 <commands+0x10d0>
ffffffffc0201fc4:	8fafe0ef          	jal	ra,ffffffffc02000be <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0201fc8:	00003697          	auipc	a3,0x3
ffffffffc0201fcc:	59868693          	addi	a3,a3,1432 # ffffffffc0205560 <commands+0x10f8>
ffffffffc0201fd0:	00003617          	auipc	a2,0x3
ffffffffc0201fd4:	e8860613          	addi	a2,a2,-376 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0201fd8:	11100593          	li	a1,273
ffffffffc0201fdc:	00003517          	auipc	a0,0x3
ffffffffc0201fe0:	35c50513          	addi	a0,a0,860 # ffffffffc0205338 <commands+0xed0>
ffffffffc0201fe4:	920fe0ef          	jal	ra,ffffffffc0200104 <__panic>
ffffffffc0201fe8:	14fd                	addi	s1,s1,-1
    for (i = 4; i >= 0; i--)
ffffffffc0201fea:	fd3490e3          	bne	s1,s3,ffffffffc0201faa <vmm_init+0x160>
    }

    mm_destroy(mm);
ffffffffc0201fee:	8522                	mv	a0,s0
ffffffffc0201ff0:	e27ff0ef          	jal	ra,ffffffffc0201e16 <mm_destroy>

    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0201ff4:	ba7fe0ef          	jal	ra,ffffffffc0200b9a <nr_free_pages>
ffffffffc0201ff8:	28aa1c63          	bne	s4,a0,ffffffffc0202290 <vmm_init+0x446>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0201ffc:	00003517          	auipc	a0,0x3
ffffffffc0202000:	5a450513          	addi	a0,a0,1444 # ffffffffc02055a0 <commands+0x1138>
ffffffffc0202004:	8bafe0ef          	jal	ra,ffffffffc02000be <cprintf>
// check_pgfault - check correctness of pgfault handler
static void
check_pgfault(void)
{
    // char *name = "check_pgfault";
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0202008:	b93fe0ef          	jal	ra,ffffffffc0200b9a <nr_free_pages>
ffffffffc020200c:	89aa                	mv	s3,a0

    check_mm_struct = mm_create();
ffffffffc020200e:	c83ff0ef          	jal	ra,ffffffffc0201c90 <mm_create>
ffffffffc0202012:	0000f797          	auipc	a5,0xf
ffffffffc0202016:	4aa7b323          	sd	a0,1190(a5) # ffffffffc02114b8 <check_mm_struct>
ffffffffc020201a:	842a                	mv	s0,a0

    assert(check_mm_struct != NULL);
ffffffffc020201c:	2a050a63          	beqz	a0,ffffffffc02022d0 <vmm_init+0x486>
    struct mm_struct *mm = check_mm_struct;
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0202020:	0000f797          	auipc	a5,0xf
ffffffffc0202024:	43078793          	addi	a5,a5,1072 # ffffffffc0211450 <boot_pgdir>
ffffffffc0202028:	6384                	ld	s1,0(a5)
    assert(pgdir[0] == 0);
ffffffffc020202a:	609c                	ld	a5,0(s1)
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc020202c:	ed04                	sd	s1,24(a0)
    assert(pgdir[0] == 0);
ffffffffc020202e:	32079d63          	bnez	a5,ffffffffc0202368 <vmm_init+0x51e>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202032:	03000513          	li	a0,48
ffffffffc0202036:	ab5ff0ef          	jal	ra,ffffffffc0201aea <kmalloc>
ffffffffc020203a:	8a2a                	mv	s4,a0
    if (vma != NULL)
ffffffffc020203c:	14050a63          	beqz	a0,ffffffffc0202190 <vmm_init+0x346>
        vma->vm_end = vm_end;
ffffffffc0202040:	002007b7          	lui	a5,0x200
ffffffffc0202044:	00fa3823          	sd	a5,16(s4)
        vma->vm_flags = vm_flags;
ffffffffc0202048:	4789                	li	a5,2

    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);

    assert(vma != NULL);

    insert_vma_struct(mm, vma);
ffffffffc020204a:	85aa                	mv	a1,a0
        vma->vm_flags = vm_flags;
ffffffffc020204c:	00fa3c23          	sd	a5,24(s4)
    insert_vma_struct(mm, vma);
ffffffffc0202050:	8522                	mv	a0,s0
        vma->vm_start = vm_start;
ffffffffc0202052:	000a3423          	sd	zero,8(s4)
    insert_vma_struct(mm, vma);
ffffffffc0202056:	cf3ff0ef          	jal	ra,ffffffffc0201d48 <insert_vma_struct>

    uintptr_t addr = 0x100;
    assert(find_vma(mm, addr) == vma);
ffffffffc020205a:	10000593          	li	a1,256
ffffffffc020205e:	8522                	mv	a0,s0
ffffffffc0202060:	cabff0ef          	jal	ra,ffffffffc0201d0a <find_vma>
ffffffffc0202064:	10000793          	li	a5,256

    int i, sum = 0;
    for (i = 0; i < 100; i++)
ffffffffc0202068:	16400713          	li	a4,356
    assert(find_vma(mm, addr) == vma);
ffffffffc020206c:	2aaa1263          	bne	s4,a0,ffffffffc0202310 <vmm_init+0x4c6>
    {
        *(char *)(addr + i) = i;
ffffffffc0202070:	00f78023          	sb	a5,0(a5) # 200000 <BASE_ADDRESS-0xffffffffc0000000>
        sum += i;
ffffffffc0202074:	0785                	addi	a5,a5,1
    for (i = 0; i < 100; i++)
ffffffffc0202076:	fee79de3          	bne	a5,a4,ffffffffc0202070 <vmm_init+0x226>
        sum += i;
ffffffffc020207a:	6705                	lui	a4,0x1
    for (i = 0; i < 100; i++)
ffffffffc020207c:	10000793          	li	a5,256
        sum += i;
ffffffffc0202080:	35670713          	addi	a4,a4,854 # 1356 <BASE_ADDRESS-0xffffffffc01fecaa>
    }
    for (i = 0; i < 100; i++)
ffffffffc0202084:	16400613          	li	a2,356
    {
        sum -= *(char *)(addr + i);
ffffffffc0202088:	0007c683          	lbu	a3,0(a5)
ffffffffc020208c:	0785                	addi	a5,a5,1
ffffffffc020208e:	9f15                	subw	a4,a4,a3
    for (i = 0; i < 100; i++)
ffffffffc0202090:	fec79ce3          	bne	a5,a2,ffffffffc0202088 <vmm_init+0x23e>
    }
    assert(sum == 0);
ffffffffc0202094:	2a071a63          	bnez	a4,ffffffffc0202348 <vmm_init+0x4fe>

    page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));
ffffffffc0202098:	4581                	li	a1,0
ffffffffc020209a:	8526                	mv	a0,s1
ffffffffc020209c:	d9bfe0ef          	jal	ra,ffffffffc0200e36 <page_remove>
    return pa2page(PDE_ADDR(pde));
ffffffffc02020a0:	609c                	ld	a5,0(s1)
    if (PPN(pa) >= npage) {
ffffffffc02020a2:	0000f717          	auipc	a4,0xf
ffffffffc02020a6:	3b670713          	addi	a4,a4,950 # ffffffffc0211458 <npage>
ffffffffc02020aa:	6318                	ld	a4,0(a4)
    return pa2page(PDE_ADDR(pde));
ffffffffc02020ac:	078a                	slli	a5,a5,0x2
ffffffffc02020ae:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02020b0:	28e7f063          	bgeu	a5,a4,ffffffffc0202330 <vmm_init+0x4e6>
    return &pages[PPN(pa) - nbase];
ffffffffc02020b4:	00004717          	auipc	a4,0x4
ffffffffc02020b8:	11c70713          	addi	a4,a4,284 # ffffffffc02061d0 <nbase>
ffffffffc02020bc:	6318                	ld	a4,0(a4)
ffffffffc02020be:	0000f697          	auipc	a3,0xf
ffffffffc02020c2:	3f268693          	addi	a3,a3,1010 # ffffffffc02114b0 <pages>
ffffffffc02020c6:	6288                	ld	a0,0(a3)
ffffffffc02020c8:	8f99                	sub	a5,a5,a4
ffffffffc02020ca:	00379713          	slli	a4,a5,0x3
ffffffffc02020ce:	97ba                	add	a5,a5,a4
ffffffffc02020d0:	078e                	slli	a5,a5,0x3

    free_page(pde2page(pgdir[0]));
ffffffffc02020d2:	953e                	add	a0,a0,a5
ffffffffc02020d4:	4585                	li	a1,1
ffffffffc02020d6:	a7ffe0ef          	jal	ra,ffffffffc0200b54 <free_pages>

    pgdir[0] = 0;
ffffffffc02020da:	0004b023          	sd	zero,0(s1)

    mm->pgdir = NULL;
    mm_destroy(mm);
ffffffffc02020de:	8522                	mv	a0,s0
    mm->pgdir = NULL;
ffffffffc02020e0:	00043c23          	sd	zero,24(s0)
    mm_destroy(mm);
ffffffffc02020e4:	d33ff0ef          	jal	ra,ffffffffc0201e16 <mm_destroy>

    check_mm_struct = NULL;
    nr_free_pages_store--; // szx : Sv39第二级页表多占了一个内存页，所以执行此操作
ffffffffc02020e8:	19fd                	addi	s3,s3,-1
    check_mm_struct = NULL;
ffffffffc02020ea:	0000f797          	auipc	a5,0xf
ffffffffc02020ee:	3c07b723          	sd	zero,974(a5) # ffffffffc02114b8 <check_mm_struct>

    assert(nr_free_pages_store == nr_free_pages());
ffffffffc02020f2:	aa9fe0ef          	jal	ra,ffffffffc0200b9a <nr_free_pages>
ffffffffc02020f6:	1aa99d63          	bne	s3,a0,ffffffffc02022b0 <vmm_init+0x466>

    cprintf("check_pgfault() succeeded!\n");
ffffffffc02020fa:	00003517          	auipc	a0,0x3
ffffffffc02020fe:	51e50513          	addi	a0,a0,1310 # ffffffffc0205618 <commands+0x11b0>
ffffffffc0202102:	fbdfd0ef          	jal	ra,ffffffffc02000be <cprintf>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0202106:	a95fe0ef          	jal	ra,ffffffffc0200b9a <nr_free_pages>
    nr_free_pages_store--; // szx : Sv39三级页表多占一个内存页，所以执行此操作
ffffffffc020210a:	197d                	addi	s2,s2,-1
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc020210c:	1ea91263          	bne	s2,a0,ffffffffc02022f0 <vmm_init+0x4a6>
}
ffffffffc0202110:	6406                	ld	s0,64(sp)
ffffffffc0202112:	60a6                	ld	ra,72(sp)
ffffffffc0202114:	74e2                	ld	s1,56(sp)
ffffffffc0202116:	7942                	ld	s2,48(sp)
ffffffffc0202118:	79a2                	ld	s3,40(sp)
ffffffffc020211a:	7a02                	ld	s4,32(sp)
ffffffffc020211c:	6ae2                	ld	s5,24(sp)
ffffffffc020211e:	6b42                	ld	s6,16(sp)
ffffffffc0202120:	6ba2                	ld	s7,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0202122:	00003517          	auipc	a0,0x3
ffffffffc0202126:	51650513          	addi	a0,a0,1302 # ffffffffc0205638 <commands+0x11d0>
}
ffffffffc020212a:	6161                	addi	sp,sp,80
    cprintf("check_vmm() succeeded.\n");
ffffffffc020212c:	f93fd06f          	j	ffffffffc02000be <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0202130:	00003697          	auipc	a3,0x3
ffffffffc0202134:	32068693          	addi	a3,a3,800 # ffffffffc0205450 <commands+0xfe8>
ffffffffc0202138:	00003617          	auipc	a2,0x3
ffffffffc020213c:	d2060613          	addi	a2,a2,-736 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0202140:	0f500593          	li	a1,245
ffffffffc0202144:	00003517          	auipc	a0,0x3
ffffffffc0202148:	1f450513          	addi	a0,a0,500 # ffffffffc0205338 <commands+0xed0>
ffffffffc020214c:	fb9fd0ef          	jal	ra,ffffffffc0200104 <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0202150:	00003697          	auipc	a3,0x3
ffffffffc0202154:	38868693          	addi	a3,a3,904 # ffffffffc02054d8 <commands+0x1070>
ffffffffc0202158:	00003617          	auipc	a2,0x3
ffffffffc020215c:	d0060613          	addi	a2,a2,-768 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0202160:	10600593          	li	a1,262
ffffffffc0202164:	00003517          	auipc	a0,0x3
ffffffffc0202168:	1d450513          	addi	a0,a0,468 # ffffffffc0205338 <commands+0xed0>
ffffffffc020216c:	f99fd0ef          	jal	ra,ffffffffc0200104 <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0202170:	00003697          	auipc	a3,0x3
ffffffffc0202174:	39868693          	addi	a3,a3,920 # ffffffffc0205508 <commands+0x10a0>
ffffffffc0202178:	00003617          	auipc	a2,0x3
ffffffffc020217c:	ce060613          	addi	a2,a2,-800 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0202180:	10700593          	li	a1,263
ffffffffc0202184:	00003517          	auipc	a0,0x3
ffffffffc0202188:	1b450513          	addi	a0,a0,436 # ffffffffc0205338 <commands+0xed0>
ffffffffc020218c:	f79fd0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(vma != NULL);
ffffffffc0202190:	00003697          	auipc	a3,0x3
ffffffffc0202194:	4c068693          	addi	a3,a3,1216 # ffffffffc0205650 <commands+0x11e8>
ffffffffc0202198:	00003617          	auipc	a2,0x3
ffffffffc020219c:	cc060613          	addi	a2,a2,-832 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc02021a0:	12d00593          	li	a1,301
ffffffffc02021a4:	00003517          	auipc	a0,0x3
ffffffffc02021a8:	19450513          	addi	a0,a0,404 # ffffffffc0205338 <commands+0xed0>
ffffffffc02021ac:	f59fd0ef          	jal	ra,ffffffffc0200104 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc02021b0:	00003697          	auipc	a3,0x3
ffffffffc02021b4:	28868693          	addi	a3,a3,648 # ffffffffc0205438 <commands+0xfd0>
ffffffffc02021b8:	00003617          	auipc	a2,0x3
ffffffffc02021bc:	ca060613          	addi	a2,a2,-864 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc02021c0:	0f300593          	li	a1,243
ffffffffc02021c4:	00003517          	auipc	a0,0x3
ffffffffc02021c8:	17450513          	addi	a0,a0,372 # ffffffffc0205338 <commands+0xed0>
ffffffffc02021cc:	f39fd0ef          	jal	ra,ffffffffc0200104 <__panic>
        assert(vma4 == NULL);
ffffffffc02021d0:	00003697          	auipc	a3,0x3
ffffffffc02021d4:	2e868693          	addi	a3,a3,744 # ffffffffc02054b8 <commands+0x1050>
ffffffffc02021d8:	00003617          	auipc	a2,0x3
ffffffffc02021dc:	c8060613          	addi	a2,a2,-896 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc02021e0:	10200593          	li	a1,258
ffffffffc02021e4:	00003517          	auipc	a0,0x3
ffffffffc02021e8:	15450513          	addi	a0,a0,340 # ffffffffc0205338 <commands+0xed0>
ffffffffc02021ec:	f19fd0ef          	jal	ra,ffffffffc0200104 <__panic>
        assert(vma3 == NULL);
ffffffffc02021f0:	00003697          	auipc	a3,0x3
ffffffffc02021f4:	2b868693          	addi	a3,a3,696 # ffffffffc02054a8 <commands+0x1040>
ffffffffc02021f8:	00003617          	auipc	a2,0x3
ffffffffc02021fc:	c6060613          	addi	a2,a2,-928 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0202200:	10000593          	li	a1,256
ffffffffc0202204:	00003517          	auipc	a0,0x3
ffffffffc0202208:	13450513          	addi	a0,a0,308 # ffffffffc0205338 <commands+0xed0>
ffffffffc020220c:	ef9fd0ef          	jal	ra,ffffffffc0200104 <__panic>
        assert(vma2 != NULL);
ffffffffc0202210:	00003697          	auipc	a3,0x3
ffffffffc0202214:	28868693          	addi	a3,a3,648 # ffffffffc0205498 <commands+0x1030>
ffffffffc0202218:	00003617          	auipc	a2,0x3
ffffffffc020221c:	c4060613          	addi	a2,a2,-960 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0202220:	0fe00593          	li	a1,254
ffffffffc0202224:	00003517          	auipc	a0,0x3
ffffffffc0202228:	11450513          	addi	a0,a0,276 # ffffffffc0205338 <commands+0xed0>
ffffffffc020222c:	ed9fd0ef          	jal	ra,ffffffffc0200104 <__panic>
        assert(vma1 != NULL);
ffffffffc0202230:	00003697          	auipc	a3,0x3
ffffffffc0202234:	25868693          	addi	a3,a3,600 # ffffffffc0205488 <commands+0x1020>
ffffffffc0202238:	00003617          	auipc	a2,0x3
ffffffffc020223c:	c2060613          	addi	a2,a2,-992 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0202240:	0fc00593          	li	a1,252
ffffffffc0202244:	00003517          	auipc	a0,0x3
ffffffffc0202248:	0f450513          	addi	a0,a0,244 # ffffffffc0205338 <commands+0xed0>
ffffffffc020224c:	eb9fd0ef          	jal	ra,ffffffffc0200104 <__panic>
        assert(vma5 == NULL);
ffffffffc0202250:	00003697          	auipc	a3,0x3
ffffffffc0202254:	27868693          	addi	a3,a3,632 # ffffffffc02054c8 <commands+0x1060>
ffffffffc0202258:	00003617          	auipc	a2,0x3
ffffffffc020225c:	c0060613          	addi	a2,a2,-1024 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0202260:	10400593          	li	a1,260
ffffffffc0202264:	00003517          	auipc	a0,0x3
ffffffffc0202268:	0d450513          	addi	a0,a0,212 # ffffffffc0205338 <commands+0xed0>
ffffffffc020226c:	e99fd0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(mm != NULL);
ffffffffc0202270:	00003697          	auipc	a3,0x3
ffffffffc0202274:	1b868693          	addi	a3,a3,440 # ffffffffc0205428 <commands+0xfc0>
ffffffffc0202278:	00003617          	auipc	a2,0x3
ffffffffc020227c:	be060613          	addi	a2,a2,-1056 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0202280:	0dc00593          	li	a1,220
ffffffffc0202284:	00003517          	auipc	a0,0x3
ffffffffc0202288:	0b450513          	addi	a0,a0,180 # ffffffffc0205338 <commands+0xed0>
ffffffffc020228c:	e79fd0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0202290:	00003697          	auipc	a3,0x3
ffffffffc0202294:	2e868693          	addi	a3,a3,744 # ffffffffc0205578 <commands+0x1110>
ffffffffc0202298:	00003617          	auipc	a2,0x3
ffffffffc020229c:	bc060613          	addi	a2,a2,-1088 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc02022a0:	11600593          	li	a1,278
ffffffffc02022a4:	00003517          	auipc	a0,0x3
ffffffffc02022a8:	09450513          	addi	a0,a0,148 # ffffffffc0205338 <commands+0xed0>
ffffffffc02022ac:	e59fd0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc02022b0:	00003697          	auipc	a3,0x3
ffffffffc02022b4:	2c868693          	addi	a3,a3,712 # ffffffffc0205578 <commands+0x1110>
ffffffffc02022b8:	00003617          	auipc	a2,0x3
ffffffffc02022bc:	ba060613          	addi	a2,a2,-1120 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc02022c0:	14c00593          	li	a1,332
ffffffffc02022c4:	00003517          	auipc	a0,0x3
ffffffffc02022c8:	07450513          	addi	a0,a0,116 # ffffffffc0205338 <commands+0xed0>
ffffffffc02022cc:	e39fd0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(check_mm_struct != NULL);
ffffffffc02022d0:	00003697          	auipc	a3,0x3
ffffffffc02022d4:	2f068693          	addi	a3,a3,752 # ffffffffc02055c0 <commands+0x1158>
ffffffffc02022d8:	00003617          	auipc	a2,0x3
ffffffffc02022dc:	b8060613          	addi	a2,a2,-1152 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc02022e0:	12600593          	li	a1,294
ffffffffc02022e4:	00003517          	auipc	a0,0x3
ffffffffc02022e8:	05450513          	addi	a0,a0,84 # ffffffffc0205338 <commands+0xed0>
ffffffffc02022ec:	e19fd0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc02022f0:	00003697          	auipc	a3,0x3
ffffffffc02022f4:	28868693          	addi	a3,a3,648 # ffffffffc0205578 <commands+0x1110>
ffffffffc02022f8:	00003617          	auipc	a2,0x3
ffffffffc02022fc:	b6060613          	addi	a2,a2,-1184 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0202300:	0d100593          	li	a1,209
ffffffffc0202304:	00003517          	auipc	a0,0x3
ffffffffc0202308:	03450513          	addi	a0,a0,52 # ffffffffc0205338 <commands+0xed0>
ffffffffc020230c:	df9fd0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(find_vma(mm, addr) == vma);
ffffffffc0202310:	00003697          	auipc	a3,0x3
ffffffffc0202314:	2d868693          	addi	a3,a3,728 # ffffffffc02055e8 <commands+0x1180>
ffffffffc0202318:	00003617          	auipc	a2,0x3
ffffffffc020231c:	b4060613          	addi	a2,a2,-1216 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0202320:	13200593          	li	a1,306
ffffffffc0202324:	00003517          	auipc	a0,0x3
ffffffffc0202328:	01450513          	addi	a0,a0,20 # ffffffffc0205338 <commands+0xed0>
ffffffffc020232c:	dd9fd0ef          	jal	ra,ffffffffc0200104 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0202330:	00003617          	auipc	a2,0x3
ffffffffc0202334:	9f060613          	addi	a2,a2,-1552 # ffffffffc0204d20 <commands+0x8b8>
ffffffffc0202338:	06500593          	li	a1,101
ffffffffc020233c:	00003517          	auipc	a0,0x3
ffffffffc0202340:	a0450513          	addi	a0,a0,-1532 # ffffffffc0204d40 <commands+0x8d8>
ffffffffc0202344:	dc1fd0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(sum == 0);
ffffffffc0202348:	00003697          	auipc	a3,0x3
ffffffffc020234c:	2c068693          	addi	a3,a3,704 # ffffffffc0205608 <commands+0x11a0>
ffffffffc0202350:	00003617          	auipc	a2,0x3
ffffffffc0202354:	b0860613          	addi	a2,a2,-1272 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0202358:	13e00593          	li	a1,318
ffffffffc020235c:	00003517          	auipc	a0,0x3
ffffffffc0202360:	fdc50513          	addi	a0,a0,-36 # ffffffffc0205338 <commands+0xed0>
ffffffffc0202364:	da1fd0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(pgdir[0] == 0);
ffffffffc0202368:	00003697          	auipc	a3,0x3
ffffffffc020236c:	27068693          	addi	a3,a3,624 # ffffffffc02055d8 <commands+0x1170>
ffffffffc0202370:	00003617          	auipc	a2,0x3
ffffffffc0202374:	ae860613          	addi	a2,a2,-1304 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0202378:	12900593          	li	a1,297
ffffffffc020237c:	00003517          	auipc	a0,0x3
ffffffffc0202380:	fbc50513          	addi	a0,a0,-68 # ffffffffc0205338 <commands+0xed0>
ffffffffc0202384:	d81fd0ef          	jal	ra,ffffffffc0200104 <__panic>

ffffffffc0202388 <do_pgfault>:
 *         -- P标志（第0位）指示异常是由于不存在的页面（0）还是由于访问权限违规或使用保留位（1）。
 *         -- W/R标志（第1位）指示导致异常的内存访问是读取（0）还是写入（1）。
 *         -- U/S标志（第2位）指示处理器在发生异常时是处于用户模式（1）还是管理模式（0）。
 */
int do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr)
{
ffffffffc0202388:	7179                	addi	sp,sp,-48
    int ret = -E_INVAL;
    // 尝试找到包含 addr 的 vma
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc020238a:	85b2                	mv	a1,a2
{
ffffffffc020238c:	f022                	sd	s0,32(sp)
ffffffffc020238e:	ec26                	sd	s1,24(sp)
ffffffffc0202390:	f406                	sd	ra,40(sp)
ffffffffc0202392:	e84a                	sd	s2,16(sp)
ffffffffc0202394:	8432                	mv	s0,a2
ffffffffc0202396:	84aa                	mv	s1,a0
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0202398:	973ff0ef          	jal	ra,ffffffffc0201d0a <find_vma>

    pgfault_num++;
ffffffffc020239c:	0000f797          	auipc	a5,0xf
ffffffffc02023a0:	0c478793          	addi	a5,a5,196 # ffffffffc0211460 <pgfault_num>
ffffffffc02023a4:	439c                	lw	a5,0(a5)
ffffffffc02023a6:	2785                	addiw	a5,a5,1
ffffffffc02023a8:	0000f717          	auipc	a4,0xf
ffffffffc02023ac:	0af72c23          	sw	a5,184(a4) # ffffffffc0211460 <pgfault_num>
    // 如果 addr 在 mm 的 vma 范围内？
    if (vma == NULL || vma->vm_start > addr)
ffffffffc02023b0:	c549                	beqz	a0,ffffffffc020243a <do_pgfault+0xb2>
ffffffffc02023b2:	651c                	ld	a5,8(a0)
ffffffffc02023b4:	08f46363          	bltu	s0,a5,ffffffffc020243a <do_pgfault+0xb2>
     * (写一个不存在的地址且地址是可写的) 或
     * (读一个不存在的地址且地址是可读的)
     * 那么继续处理
     */
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE)
ffffffffc02023b8:	6d1c                	ld	a5,24(a0)
    uint32_t perm = PTE_U;
ffffffffc02023ba:	4941                	li	s2,16
    if (vma->vm_flags & VM_WRITE)
ffffffffc02023bc:	8b89                	andi	a5,a5,2
ffffffffc02023be:	efa9                	bnez	a5,ffffffffc0202418 <do_pgfault+0x90>
    {
        perm |= (PTE_R | PTE_W);
    }
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc02023c0:	767d                	lui	a2,0xfffff
     * 变量:
     *   mm->pgdir : 这些 vma 的页目录表
     *
     */

    ptep = get_pte(mm->pgdir, addr, 1); //(1) 尝试找到一个页表项，如果页表项的页表不存在，则创建一个页表。
ffffffffc02023c2:	6c88                	ld	a0,24(s1)
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc02023c4:	8c71                	and	s0,s0,a2
    ptep = get_pte(mm->pgdir, addr, 1); //(1) 尝试找到一个页表项，如果页表项的页表不存在，则创建一个页表。
ffffffffc02023c6:	85a2                	mv	a1,s0
ffffffffc02023c8:	4605                	li	a2,1
ffffffffc02023ca:	811fe0ef          	jal	ra,ffffffffc0200bda <get_pte>
    if (*ptep == 0)
ffffffffc02023ce:	610c                	ld	a1,0(a0)
ffffffffc02023d0:	c5b1                	beqz	a1,ffffffffc020241c <do_pgfault+0x94>
         *    swap_in(mm, addr, &page) : 分配一个内存页，然后根据
         *    PTE中的swap条目的addr，找到磁盘页的地址，将磁盘页的内容读入这个内存页
         *    page_insert ： 建立一个Page的phy addr与线性addr la的映射
         *    swap_map_swappable ： 设置页面可交换
         */
        if (swap_init_ok)
ffffffffc02023d2:	0000f797          	auipc	a5,0xf
ffffffffc02023d6:	09e78793          	addi	a5,a5,158 # ffffffffc0211470 <swap_init_ok>
ffffffffc02023da:	439c                	lw	a5,0(a5)
ffffffffc02023dc:	2781                	sext.w	a5,a5
ffffffffc02023de:	c7bd                	beqz	a5,ffffffffc020244c <do_pgfault+0xc4>
        {
            struct Page *page = NULL;
            // 你要编写的内容在这里，请基于上文说明以及下文的英文注释完成代码编写
            //(1）根据 mm 和 addr，尝试将正确的磁盘页内容加载到 page 管理的内存中。
            swap_in(mm, addr, &page);
ffffffffc02023e0:	85a2                	mv	a1,s0
ffffffffc02023e2:	0030                	addi	a2,sp,8
ffffffffc02023e4:	8526                	mv	a0,s1
            struct Page *page = NULL;
ffffffffc02023e6:	e402                	sd	zero,8(sp)
            swap_in(mm, addr, &page);
ffffffffc02023e8:	061000ef          	jal	ra,ffffffffc0202c48 <swap_in>
            //(2) 根据 mm、addr 和 page，设置物理地址和逻辑地址之间的映射。
            page_insert(mm->pgdir, page, addr, perm);
ffffffffc02023ec:	65a2                	ld	a1,8(sp)
ffffffffc02023ee:	6c88                	ld	a0,24(s1)
ffffffffc02023f0:	86ca                	mv	a3,s2
ffffffffc02023f2:	8622                	mv	a2,s0
ffffffffc02023f4:	ab5fe0ef          	jal	ra,ffffffffc0200ea8 <page_insert>
            //(3) 使页面可交换。
            swap_map_swappable(mm, addr, page, 1);
ffffffffc02023f8:	6622                	ld	a2,8(sp)
ffffffffc02023fa:	4685                	li	a3,1
ffffffffc02023fc:	85a2                	mv	a1,s0
ffffffffc02023fe:	8526                	mv	a0,s1
ffffffffc0202400:	724000ef          	jal	ra,ffffffffc0202b24 <swap_map_swappable>
            page->pra_vaddr = addr;
ffffffffc0202404:	6722                	ld	a4,8(sp)
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
            goto failed;
        }
    }

    ret = 0;
ffffffffc0202406:	4781                	li	a5,0
            page->pra_vaddr = addr;
ffffffffc0202408:	e320                	sd	s0,64(a4)
failed:
    return ret;
}
ffffffffc020240a:	70a2                	ld	ra,40(sp)
ffffffffc020240c:	7402                	ld	s0,32(sp)
ffffffffc020240e:	64e2                	ld	s1,24(sp)
ffffffffc0202410:	6942                	ld	s2,16(sp)
ffffffffc0202412:	853e                	mv	a0,a5
ffffffffc0202414:	6145                	addi	sp,sp,48
ffffffffc0202416:	8082                	ret
        perm |= (PTE_R | PTE_W);
ffffffffc0202418:	4959                	li	s2,22
ffffffffc020241a:	b75d                	j	ffffffffc02023c0 <do_pgfault+0x38>
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL)
ffffffffc020241c:	6c88                	ld	a0,24(s1)
ffffffffc020241e:	864a                	mv	a2,s2
ffffffffc0202420:	85a2                	mv	a1,s0
ffffffffc0202422:	e36ff0ef          	jal	ra,ffffffffc0201a58 <pgdir_alloc_page>
    ret = 0;
ffffffffc0202426:	4781                	li	a5,0
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL)
ffffffffc0202428:	f16d                	bnez	a0,ffffffffc020240a <do_pgfault+0x82>
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
ffffffffc020242a:	00003517          	auipc	a0,0x3
ffffffffc020242e:	f4e50513          	addi	a0,a0,-178 # ffffffffc0205378 <commands+0xf10>
ffffffffc0202432:	c8dfd0ef          	jal	ra,ffffffffc02000be <cprintf>
    ret = -E_NO_MEM;
ffffffffc0202436:	57f1                	li	a5,-4
            goto failed;
ffffffffc0202438:	bfc9                	j	ffffffffc020240a <do_pgfault+0x82>
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
ffffffffc020243a:	85a2                	mv	a1,s0
ffffffffc020243c:	00003517          	auipc	a0,0x3
ffffffffc0202440:	f0c50513          	addi	a0,a0,-244 # ffffffffc0205348 <commands+0xee0>
ffffffffc0202444:	c7bfd0ef          	jal	ra,ffffffffc02000be <cprintf>
    int ret = -E_INVAL;
ffffffffc0202448:	57f5                	li	a5,-3
        goto failed;
ffffffffc020244a:	b7c1                	j	ffffffffc020240a <do_pgfault+0x82>
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
ffffffffc020244c:	00003517          	auipc	a0,0x3
ffffffffc0202450:	f5450513          	addi	a0,a0,-172 # ffffffffc02053a0 <commands+0xf38>
ffffffffc0202454:	c6bfd0ef          	jal	ra,ffffffffc02000be <cprintf>
    ret = -E_NO_MEM;
ffffffffc0202458:	57f1                	li	a5,-4
            goto failed;
ffffffffc020245a:	bf45                	j	ffffffffc020240a <do_pgfault+0x82>

ffffffffc020245c <swap_init>:
unsigned int swap_in_seq_no[MAX_SEQ_NO], swap_out_seq_no[MAX_SEQ_NO];

static void check_swap(void);

int swap_init(void)
{
ffffffffc020245c:	7135                	addi	sp,sp,-160
ffffffffc020245e:	ed06                	sd	ra,152(sp)
ffffffffc0202460:	e922                	sd	s0,144(sp)
ffffffffc0202462:	e526                	sd	s1,136(sp)
ffffffffc0202464:	e14a                	sd	s2,128(sp)
ffffffffc0202466:	fcce                	sd	s3,120(sp)
ffffffffc0202468:	f8d2                	sd	s4,112(sp)
ffffffffc020246a:	f4d6                	sd	s5,104(sp)
ffffffffc020246c:	f0da                	sd	s6,96(sp)
ffffffffc020246e:	ecde                	sd	s7,88(sp)
ffffffffc0202470:	e8e2                	sd	s8,80(sp)
ffffffffc0202472:	e4e6                	sd	s9,72(sp)
ffffffffc0202474:	e0ea                	sd	s10,64(sp)
ffffffffc0202476:	fc6e                	sd	s11,56(sp)
     swapfs_init();
ffffffffc0202478:	7ae010ef          	jal	ra,ffffffffc0203c26 <swapfs_init>

     // 由于 IDE 是模拟的，它最多只能存储 7 页以通过测试
     if (!(7 <= max_swap_offset &&
ffffffffc020247c:	0000f797          	auipc	a5,0xf
ffffffffc0202480:	0cc78793          	addi	a5,a5,204 # ffffffffc0211548 <max_swap_offset>
ffffffffc0202484:	6394                	ld	a3,0(a5)
ffffffffc0202486:	010007b7          	lui	a5,0x1000
ffffffffc020248a:	17e1                	addi	a5,a5,-8
ffffffffc020248c:	ff968713          	addi	a4,a3,-7
ffffffffc0202490:	44e7e663          	bltu	a5,a4,ffffffffc02028dc <swap_init+0x480>
           max_swap_offset < MAX_SWAP_OFFSET_LIMIT))
     {
          panic("bad max_swap_offset %08x.\n", max_swap_offset);
     }

     sm = &swap_manager_clock; // 使用CLOCK页面置换算法
ffffffffc0202494:	00008797          	auipc	a5,0x8
ffffffffc0202498:	b6c78793          	addi	a5,a5,-1172 # ffffffffc020a000 <swap_manager_clock>
     // sm = &swap_manager_lru; // 使用LRU页面置换算法
     // sm = &swap_manager_fifo; // 使用FIFO页面替换算法
     int r = sm->init();
ffffffffc020249c:	6798                	ld	a4,8(a5)
     sm = &swap_manager_clock; // 使用CLOCK页面置换算法
ffffffffc020249e:	0000f697          	auipc	a3,0xf
ffffffffc02024a2:	fcf6b523          	sd	a5,-54(a3) # ffffffffc0211468 <sm>
     int r = sm->init();
ffffffffc02024a6:	9702                	jalr	a4
ffffffffc02024a8:	8b2a                	mv	s6,a0

     if (r == 0)
ffffffffc02024aa:	c10d                	beqz	a0,ffffffffc02024cc <swap_init+0x70>
          cprintf("SWAP: manager = %s\n", sm->name);
          check_swap();
     }

     return r;
}
ffffffffc02024ac:	60ea                	ld	ra,152(sp)
ffffffffc02024ae:	644a                	ld	s0,144(sp)
ffffffffc02024b0:	855a                	mv	a0,s6
ffffffffc02024b2:	64aa                	ld	s1,136(sp)
ffffffffc02024b4:	690a                	ld	s2,128(sp)
ffffffffc02024b6:	79e6                	ld	s3,120(sp)
ffffffffc02024b8:	7a46                	ld	s4,112(sp)
ffffffffc02024ba:	7aa6                	ld	s5,104(sp)
ffffffffc02024bc:	7b06                	ld	s6,96(sp)
ffffffffc02024be:	6be6                	ld	s7,88(sp)
ffffffffc02024c0:	6c46                	ld	s8,80(sp)
ffffffffc02024c2:	6ca6                	ld	s9,72(sp)
ffffffffc02024c4:	6d06                	ld	s10,64(sp)
ffffffffc02024c6:	7de2                	ld	s11,56(sp)
ffffffffc02024c8:	610d                	addi	sp,sp,160
ffffffffc02024ca:	8082                	ret
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc02024cc:	0000f797          	auipc	a5,0xf
ffffffffc02024d0:	f9c78793          	addi	a5,a5,-100 # ffffffffc0211468 <sm>
ffffffffc02024d4:	639c                	ld	a5,0(a5)
ffffffffc02024d6:	00003517          	auipc	a0,0x3
ffffffffc02024da:	20a50513          	addi	a0,a0,522 # ffffffffc02056e0 <commands+0x1278>
ffffffffc02024de:	0000f417          	auipc	s0,0xf
ffffffffc02024e2:	0aa40413          	addi	s0,s0,170 # ffffffffc0211588 <free_area>
ffffffffc02024e6:	638c                	ld	a1,0(a5)
          swap_init_ok = 1;
ffffffffc02024e8:	4785                	li	a5,1
ffffffffc02024ea:	0000f717          	auipc	a4,0xf
ffffffffc02024ee:	f8f72323          	sw	a5,-122(a4) # ffffffffc0211470 <swap_init_ok>
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc02024f2:	bcdfd0ef          	jal	ra,ffffffffc02000be <cprintf>
ffffffffc02024f6:	641c                	ld	a5,8(s0)
check_swap(void)
{
     // 备份内存环境
     int ret, count = 0, total = 0, i;
     list_entry_t *le = &free_list;
     while ((le = list_next(le)) != &free_list)
ffffffffc02024f8:	30878663          	beq	a5,s0,ffffffffc0202804 <swap_init+0x3a8>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02024fc:	fe87b703          	ld	a4,-24(a5)
ffffffffc0202500:	8305                	srli	a4,a4,0x1
     {
          struct Page *p = le2page(le, page_link);
          assert(PageProperty(p));
ffffffffc0202502:	8b05                	andi	a4,a4,1
ffffffffc0202504:	30070463          	beqz	a4,ffffffffc020280c <swap_init+0x3b0>
     int ret, count = 0, total = 0, i;
ffffffffc0202508:	4481                	li	s1,0
ffffffffc020250a:	4901                	li	s2,0
ffffffffc020250c:	a031                	j	ffffffffc0202518 <swap_init+0xbc>
ffffffffc020250e:	fe87b703          	ld	a4,-24(a5)
          assert(PageProperty(p));
ffffffffc0202512:	8b09                	andi	a4,a4,2
ffffffffc0202514:	2e070c63          	beqz	a4,ffffffffc020280c <swap_init+0x3b0>
          count++, total += p->property;
ffffffffc0202518:	ff87a703          	lw	a4,-8(a5)
ffffffffc020251c:	679c                	ld	a5,8(a5)
ffffffffc020251e:	2905                	addiw	s2,s2,1
ffffffffc0202520:	9cb9                	addw	s1,s1,a4
     while ((le = list_next(le)) != &free_list)
ffffffffc0202522:	fe8796e3          	bne	a5,s0,ffffffffc020250e <swap_init+0xb2>
ffffffffc0202526:	89a6                	mv	s3,s1
     }
     assert(total == nr_free_pages());
ffffffffc0202528:	e72fe0ef          	jal	ra,ffffffffc0200b9a <nr_free_pages>
ffffffffc020252c:	5d351463          	bne	a0,s3,ffffffffc0202af4 <swap_init+0x698>
     cprintf("BEGIN check_swap: count %d, total %d\n", count, total);
ffffffffc0202530:	8626                	mv	a2,s1
ffffffffc0202532:	85ca                	mv	a1,s2
ffffffffc0202534:	00003517          	auipc	a0,0x3
ffffffffc0202538:	1f450513          	addi	a0,a0,500 # ffffffffc0205728 <commands+0x12c0>
ffffffffc020253c:	b83fd0ef          	jal	ra,ffffffffc02000be <cprintf>

     // 现在我们设置物理页环境
     struct mm_struct *mm = mm_create();
ffffffffc0202540:	f50ff0ef          	jal	ra,ffffffffc0201c90 <mm_create>
ffffffffc0202544:	8baa                	mv	s7,a0
     assert(mm != NULL);
ffffffffc0202546:	52050763          	beqz	a0,ffffffffc0202a74 <swap_init+0x618>

     extern struct mm_struct *check_mm_struct;
     assert(check_mm_struct == NULL);
ffffffffc020254a:	0000f797          	auipc	a5,0xf
ffffffffc020254e:	f6e78793          	addi	a5,a5,-146 # ffffffffc02114b8 <check_mm_struct>
ffffffffc0202552:	639c                	ld	a5,0(a5)
ffffffffc0202554:	54079063          	bnez	a5,ffffffffc0202a94 <swap_init+0x638>

     check_mm_struct = mm;

     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0202558:	0000f797          	auipc	a5,0xf
ffffffffc020255c:	ef878793          	addi	a5,a5,-264 # ffffffffc0211450 <boot_pgdir>
ffffffffc0202560:	6398                	ld	a4,0(a5)
     check_mm_struct = mm;
ffffffffc0202562:	0000f797          	auipc	a5,0xf
ffffffffc0202566:	f4a7bb23          	sd	a0,-170(a5) # ffffffffc02114b8 <check_mm_struct>
     assert(pgdir[0] == 0);
ffffffffc020256a:	631c                	ld	a5,0(a4)
     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc020256c:	ec3a                	sd	a4,24(sp)
ffffffffc020256e:	ed18                	sd	a4,24(a0)
     assert(pgdir[0] == 0);
ffffffffc0202570:	54079263          	bnez	a5,ffffffffc0202ab4 <swap_init+0x658>

     struct vma_struct *vma = vma_create(BEING_CHECK_VALID_VADDR, CHECK_VALID_VADDR, VM_WRITE | VM_READ);
ffffffffc0202574:	6599                	lui	a1,0x6
ffffffffc0202576:	460d                	li	a2,3
ffffffffc0202578:	6505                	lui	a0,0x1
ffffffffc020257a:	f62ff0ef          	jal	ra,ffffffffc0201cdc <vma_create>
ffffffffc020257e:	85aa                	mv	a1,a0
     assert(vma != NULL);
ffffffffc0202580:	54050a63          	beqz	a0,ffffffffc0202ad4 <swap_init+0x678>

     insert_vma_struct(mm, vma);
ffffffffc0202584:	855e                	mv	a0,s7
ffffffffc0202586:	fc2ff0ef          	jal	ra,ffffffffc0201d48 <insert_vma_struct>

     // 设置临时页表 vaddr 0~4MB
     cprintf("setup Page Table for vaddr 0X1000, so alloc a page\n");
ffffffffc020258a:	00003517          	auipc	a0,0x3
ffffffffc020258e:	1de50513          	addi	a0,a0,478 # ffffffffc0205768 <commands+0x1300>
ffffffffc0202592:	b2dfd0ef          	jal	ra,ffffffffc02000be <cprintf>
     pte_t *temp_ptep = NULL;
     temp_ptep = get_pte(mm->pgdir, BEING_CHECK_VALID_VADDR, 1);
ffffffffc0202596:	018bb503          	ld	a0,24(s7)
ffffffffc020259a:	4605                	li	a2,1
ffffffffc020259c:	6585                	lui	a1,0x1
ffffffffc020259e:	e3cfe0ef          	jal	ra,ffffffffc0200bda <get_pte>
     assert(temp_ptep != NULL);
ffffffffc02025a2:	42050963          	beqz	a0,ffffffffc02029d4 <swap_init+0x578>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc02025a6:	00003517          	auipc	a0,0x3
ffffffffc02025aa:	21250513          	addi	a0,a0,530 # ffffffffc02057b8 <commands+0x1350>
ffffffffc02025ae:	0000fa17          	auipc	s4,0xf
ffffffffc02025b2:	f12a0a13          	addi	s4,s4,-238 # ffffffffc02114c0 <check_rp>
ffffffffc02025b6:	b09fd0ef          	jal	ra,ffffffffc02000be <cprintf>

     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++)
ffffffffc02025ba:	0000fa97          	auipc	s5,0xf
ffffffffc02025be:	f26a8a93          	addi	s5,s5,-218 # ffffffffc02114e0 <swap_in_seq_no>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc02025c2:	89d2                	mv	s3,s4
     {
          check_rp[i] = alloc_page();
ffffffffc02025c4:	4505                	li	a0,1
ffffffffc02025c6:	d06fe0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc02025ca:	00a9b023          	sd	a0,0(s3) # fffffffffff80000 <end+0x3fd6ea60>
          assert(check_rp[i] != NULL);
ffffffffc02025ce:	2c050763          	beqz	a0,ffffffffc020289c <swap_init+0x440>
ffffffffc02025d2:	651c                	ld	a5,8(a0)
          assert(!PageProperty(check_rp[i]));
ffffffffc02025d4:	8b89                	andi	a5,a5,2
ffffffffc02025d6:	2a079363          	bnez	a5,ffffffffc020287c <swap_init+0x420>
ffffffffc02025da:	09a1                	addi	s3,s3,8
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++)
ffffffffc02025dc:	ff5994e3          	bne	s3,s5,ffffffffc02025c4 <swap_init+0x168>
     }
     list_entry_t free_list_store = free_list;
ffffffffc02025e0:	601c                	ld	a5,0(s0)
ffffffffc02025e2:	00843983          	ld	s3,8(s0)
     assert(list_empty(&free_list));

     // assert(alloc_page() == NULL);

     unsigned int nr_free_store = nr_free;
     nr_free = 0;
ffffffffc02025e6:	0000fd17          	auipc	s10,0xf
ffffffffc02025ea:	edad0d13          	addi	s10,s10,-294 # ffffffffc02114c0 <check_rp>
     list_entry_t free_list_store = free_list;
ffffffffc02025ee:	f03e                	sd	a5,32(sp)
     unsigned int nr_free_store = nr_free;
ffffffffc02025f0:	481c                	lw	a5,16(s0)
ffffffffc02025f2:	f43e                	sd	a5,40(sp)
    elm->prev = elm->next = elm;
ffffffffc02025f4:	0000f797          	auipc	a5,0xf
ffffffffc02025f8:	f887be23          	sd	s0,-100(a5) # ffffffffc0211590 <free_area+0x8>
ffffffffc02025fc:	0000f797          	auipc	a5,0xf
ffffffffc0202600:	f887b623          	sd	s0,-116(a5) # ffffffffc0211588 <free_area>
     nr_free = 0;
ffffffffc0202604:	0000f797          	auipc	a5,0xf
ffffffffc0202608:	f807aa23          	sw	zero,-108(a5) # ffffffffc0211598 <free_area+0x10>
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++)
     {
          free_pages(check_rp[i], 1);
ffffffffc020260c:	000d3503          	ld	a0,0(s10)
ffffffffc0202610:	4585                	li	a1,1
ffffffffc0202612:	0d21                	addi	s10,s10,8
ffffffffc0202614:	d40fe0ef          	jal	ra,ffffffffc0200b54 <free_pages>
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++)
ffffffffc0202618:	ff5d1ae3          	bne	s10,s5,ffffffffc020260c <swap_init+0x1b0>
     }
     assert(nr_free == CHECK_VALID_PHY_PAGE_NUM);
ffffffffc020261c:	01042d03          	lw	s10,16(s0)
ffffffffc0202620:	4791                	li	a5,4
ffffffffc0202622:	38fd1963          	bne	s10,a5,ffffffffc02029b4 <swap_init+0x558>

     cprintf("set up init env for check_swap begin!\n");
ffffffffc0202626:	00003517          	auipc	a0,0x3
ffffffffc020262a:	21a50513          	addi	a0,a0,538 # ffffffffc0205840 <commands+0x13d8>
ffffffffc020262e:	a91fd0ef          	jal	ra,ffffffffc02000be <cprintf>
     cprintf("into check content set\n");
ffffffffc0202632:	00003517          	auipc	a0,0x3
ffffffffc0202636:	23650513          	addi	a0,a0,566 # ffffffffc0205868 <commands+0x1400>
     // 设置初始虚拟页<->物理页环境以测试页面置换算法

     pgfault_num = 0;
ffffffffc020263a:	0000f797          	auipc	a5,0xf
ffffffffc020263e:	e207a323          	sw	zero,-474(a5) # ffffffffc0211460 <pgfault_num>
     cprintf("into check content set\n");
ffffffffc0202642:	a7dfd0ef          	jal	ra,ffffffffc02000be <cprintf>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0202646:	6685                	lui	a3,0x1
ffffffffc0202648:	4629                	li	a2,10
     pgfault_num = 0;
ffffffffc020264a:	0000f797          	auipc	a5,0xf
ffffffffc020264e:	e1678793          	addi	a5,a5,-490 # ffffffffc0211460 <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0202652:	00c68023          	sb	a2,0(a3) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
     assert(pgfault_num == 1);
ffffffffc0202656:	4398                	lw	a4,0(a5)
ffffffffc0202658:	4585                	li	a1,1
ffffffffc020265a:	2701                	sext.w	a4,a4
ffffffffc020265c:	30b71c63          	bne	a4,a1,ffffffffc0202974 <swap_init+0x518>
     *(unsigned char *)0x1010 = 0x0a;
ffffffffc0202660:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num == 1);
ffffffffc0202664:	4394                	lw	a3,0(a5)
ffffffffc0202666:	2681                	sext.w	a3,a3
ffffffffc0202668:	32e69663          	bne	a3,a4,ffffffffc0202994 <swap_init+0x538>
     *(unsigned char *)0x2000 = 0x0b;
ffffffffc020266c:	6689                	lui	a3,0x2
ffffffffc020266e:	462d                	li	a2,11
ffffffffc0202670:	00c68023          	sb	a2,0(a3) # 2000 <BASE_ADDRESS-0xffffffffc01fe000>
     assert(pgfault_num == 2);
ffffffffc0202674:	4398                	lw	a4,0(a5)
ffffffffc0202676:	4589                	li	a1,2
ffffffffc0202678:	2701                	sext.w	a4,a4
ffffffffc020267a:	26b71d63          	bne	a4,a1,ffffffffc02028f4 <swap_init+0x498>
     *(unsigned char *)0x2010 = 0x0b;
ffffffffc020267e:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num == 2);
ffffffffc0202682:	4394                	lw	a3,0(a5)
ffffffffc0202684:	2681                	sext.w	a3,a3
ffffffffc0202686:	28e69763          	bne	a3,a4,ffffffffc0202914 <swap_init+0x4b8>
     *(unsigned char *)0x3000 = 0x0c;
ffffffffc020268a:	668d                	lui	a3,0x3
ffffffffc020268c:	4631                	li	a2,12
ffffffffc020268e:	00c68023          	sb	a2,0(a3) # 3000 <BASE_ADDRESS-0xffffffffc01fd000>
     assert(pgfault_num == 3);
ffffffffc0202692:	4398                	lw	a4,0(a5)
ffffffffc0202694:	458d                	li	a1,3
ffffffffc0202696:	2701                	sext.w	a4,a4
ffffffffc0202698:	28b71e63          	bne	a4,a1,ffffffffc0202934 <swap_init+0x4d8>
     *(unsigned char *)0x3010 = 0x0c;
ffffffffc020269c:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num == 3);
ffffffffc02026a0:	4394                	lw	a3,0(a5)
ffffffffc02026a2:	2681                	sext.w	a3,a3
ffffffffc02026a4:	2ae69863          	bne	a3,a4,ffffffffc0202954 <swap_init+0x4f8>
     *(unsigned char *)0x4000 = 0x0d;
ffffffffc02026a8:	6691                	lui	a3,0x4
ffffffffc02026aa:	4635                	li	a2,13
ffffffffc02026ac:	00c68023          	sb	a2,0(a3) # 4000 <BASE_ADDRESS-0xffffffffc01fc000>
     assert(pgfault_num == 4);
ffffffffc02026b0:	4398                	lw	a4,0(a5)
ffffffffc02026b2:	2701                	sext.w	a4,a4
ffffffffc02026b4:	35a71063          	bne	a4,s10,ffffffffc02029f4 <swap_init+0x598>
     *(unsigned char *)0x4010 = 0x0d;
ffffffffc02026b8:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num == 4);
ffffffffc02026bc:	439c                	lw	a5,0(a5)
ffffffffc02026be:	2781                	sext.w	a5,a5
ffffffffc02026c0:	34e79a63          	bne	a5,a4,ffffffffc0202a14 <swap_init+0x5b8>
     cprintf("end check content set\n");
ffffffffc02026c4:	00003517          	auipc	a0,0x3
ffffffffc02026c8:	21c50513          	addi	a0,a0,540 # ffffffffc02058e0 <commands+0x1478>
ffffffffc02026cc:	9f3fd0ef          	jal	ra,ffffffffc02000be <cprintf>

     check_content_set();
     assert(nr_free == 0);
ffffffffc02026d0:	481c                	lw	a5,16(s0)
ffffffffc02026d2:	36079163          	bnez	a5,ffffffffc0202a34 <swap_init+0x5d8>
ffffffffc02026d6:	0000f797          	auipc	a5,0xf
ffffffffc02026da:	e0a78793          	addi	a5,a5,-502 # ffffffffc02114e0 <swap_in_seq_no>
ffffffffc02026de:	0000f717          	auipc	a4,0xf
ffffffffc02026e2:	e2a70713          	addi	a4,a4,-470 # ffffffffc0211508 <swap_out_seq_no>
ffffffffc02026e6:	0000f617          	auipc	a2,0xf
ffffffffc02026ea:	e2260613          	addi	a2,a2,-478 # ffffffffc0211508 <swap_out_seq_no>
     for (i = 0; i < MAX_SEQ_NO; i++)
          swap_out_seq_no[i] = swap_in_seq_no[i] = -1;
ffffffffc02026ee:	56fd                	li	a3,-1
ffffffffc02026f0:	c394                	sw	a3,0(a5)
ffffffffc02026f2:	c314                	sw	a3,0(a4)
ffffffffc02026f4:	0791                	addi	a5,a5,4
ffffffffc02026f6:	0711                	addi	a4,a4,4
     for (i = 0; i < MAX_SEQ_NO; i++)
ffffffffc02026f8:	fec79ce3          	bne	a5,a2,ffffffffc02026f0 <swap_init+0x294>
ffffffffc02026fc:	0000f697          	auipc	a3,0xf
ffffffffc0202700:	e6c68693          	addi	a3,a3,-404 # ffffffffc0211568 <check_ptep>
ffffffffc0202704:	0000f817          	auipc	a6,0xf
ffffffffc0202708:	dbc80813          	addi	a6,a6,-580 # ffffffffc02114c0 <check_rp>
ffffffffc020270c:	6c05                	lui	s8,0x1
    if (PPN(pa) >= npage) {
ffffffffc020270e:	0000fc97          	auipc	s9,0xf
ffffffffc0202712:	d4ac8c93          	addi	s9,s9,-694 # ffffffffc0211458 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0202716:	0000fd97          	auipc	s11,0xf
ffffffffc020271a:	d9ad8d93          	addi	s11,s11,-614 # ffffffffc02114b0 <pages>
ffffffffc020271e:	00004d17          	auipc	s10,0x4
ffffffffc0202722:	ab2d0d13          	addi	s10,s10,-1358 # ffffffffc02061d0 <nbase>

     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++)
     {
          check_ptep[i] = 0;
          check_ptep[i] = get_pte(pgdir, (i + 1) * 0x1000, 0);
ffffffffc0202726:	6562                	ld	a0,24(sp)
          check_ptep[i] = 0;
ffffffffc0202728:	0006b023          	sd	zero,0(a3)
          check_ptep[i] = get_pte(pgdir, (i + 1) * 0x1000, 0);
ffffffffc020272c:	4601                	li	a2,0
ffffffffc020272e:	85e2                	mv	a1,s8
ffffffffc0202730:	e842                	sd	a6,16(sp)
          check_ptep[i] = 0;
ffffffffc0202732:	e436                	sd	a3,8(sp)
          check_ptep[i] = get_pte(pgdir, (i + 1) * 0x1000, 0);
ffffffffc0202734:	ca6fe0ef          	jal	ra,ffffffffc0200bda <get_pte>
ffffffffc0202738:	66a2                	ld	a3,8(sp)
          // cprintf("i %d, check_ptep addr %x, value %x\n", i, check_ptep[i], *check_ptep[i]);
          assert(check_ptep[i] != NULL);
ffffffffc020273a:	6842                	ld	a6,16(sp)
          check_ptep[i] = get_pte(pgdir, (i + 1) * 0x1000, 0);
ffffffffc020273c:	e288                	sd	a0,0(a3)
          assert(check_ptep[i] != NULL);
ffffffffc020273e:	16050f63          	beqz	a0,ffffffffc02028bc <swap_init+0x460>
          assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0202742:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0202744:	0017f613          	andi	a2,a5,1
ffffffffc0202748:	10060263          	beqz	a2,ffffffffc020284c <swap_init+0x3f0>
    if (PPN(pa) >= npage) {
ffffffffc020274c:	000cb603          	ld	a2,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202750:	078a                	slli	a5,a5,0x2
ffffffffc0202752:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202754:	10c7f863          	bgeu	a5,a2,ffffffffc0202864 <swap_init+0x408>
    return &pages[PPN(pa) - nbase];
ffffffffc0202758:	000d3603          	ld	a2,0(s10)
ffffffffc020275c:	000db583          	ld	a1,0(s11)
ffffffffc0202760:	00083503          	ld	a0,0(a6)
ffffffffc0202764:	8f91                	sub	a5,a5,a2
ffffffffc0202766:	00379613          	slli	a2,a5,0x3
ffffffffc020276a:	97b2                	add	a5,a5,a2
ffffffffc020276c:	078e                	slli	a5,a5,0x3
ffffffffc020276e:	97ae                	add	a5,a5,a1
ffffffffc0202770:	0af51e63          	bne	a0,a5,ffffffffc020282c <swap_init+0x3d0>
ffffffffc0202774:	6785                	lui	a5,0x1
ffffffffc0202776:	9c3e                	add	s8,s8,a5
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++)
ffffffffc0202778:	6795                	lui	a5,0x5
ffffffffc020277a:	06a1                	addi	a3,a3,8
ffffffffc020277c:	0821                	addi	a6,a6,8
ffffffffc020277e:	fafc14e3          	bne	s8,a5,ffffffffc0202726 <swap_init+0x2ca>
          assert((*check_ptep[i] & PTE_V));
     }
     cprintf("set up init env for check_swap over!\n");
ffffffffc0202782:	00003517          	auipc	a0,0x3
ffffffffc0202786:	1c650513          	addi	a0,a0,454 # ffffffffc0205948 <commands+0x14e0>
ffffffffc020278a:	935fd0ef          	jal	ra,ffffffffc02000be <cprintf>
     int ret = sm->check_swap();
ffffffffc020278e:	0000f797          	auipc	a5,0xf
ffffffffc0202792:	cda78793          	addi	a5,a5,-806 # ffffffffc0211468 <sm>
ffffffffc0202796:	639c                	ld	a5,0(a5)
ffffffffc0202798:	7f9c                	ld	a5,56(a5)
ffffffffc020279a:	9782                	jalr	a5
     // 现在访问虚拟页以测试页面置换算法
     ret = check_content_access();
     assert(ret == 0);
ffffffffc020279c:	2a051c63          	bnez	a0,ffffffffc0202a54 <swap_init+0x5f8>

     // 恢复内核内存环境
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++)
     {
          free_pages(check_rp[i], 1);
ffffffffc02027a0:	000a3503          	ld	a0,0(s4)
ffffffffc02027a4:	4585                	li	a1,1
ffffffffc02027a6:	0a21                	addi	s4,s4,8
ffffffffc02027a8:	bacfe0ef          	jal	ra,ffffffffc0200b54 <free_pages>
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++)
ffffffffc02027ac:	ff5a1ae3          	bne	s4,s5,ffffffffc02027a0 <swap_init+0x344>
     }

     // free_page(pte2page(*temp_ptep));

     mm_destroy(mm);
ffffffffc02027b0:	855e                	mv	a0,s7
ffffffffc02027b2:	e64ff0ef          	jal	ra,ffffffffc0201e16 <mm_destroy>

     nr_free = nr_free_store;
ffffffffc02027b6:	77a2                	ld	a5,40(sp)
ffffffffc02027b8:	0000f717          	auipc	a4,0xf
ffffffffc02027bc:	def72023          	sw	a5,-544(a4) # ffffffffc0211598 <free_area+0x10>
     free_list = free_list_store;
ffffffffc02027c0:	7782                	ld	a5,32(sp)
ffffffffc02027c2:	0000f717          	auipc	a4,0xf
ffffffffc02027c6:	dcf73323          	sd	a5,-570(a4) # ffffffffc0211588 <free_area>
ffffffffc02027ca:	0000f797          	auipc	a5,0xf
ffffffffc02027ce:	dd37b323          	sd	s3,-570(a5) # ffffffffc0211590 <free_area+0x8>

     le = &free_list;
     while ((le = list_next(le)) != &free_list)
ffffffffc02027d2:	00898a63          	beq	s3,s0,ffffffffc02027e6 <swap_init+0x38a>
     {
          struct Page *p = le2page(le, page_link);
          count--, total -= p->property;
ffffffffc02027d6:	ff89a783          	lw	a5,-8(s3)
    return listelm->next;
ffffffffc02027da:	0089b983          	ld	s3,8(s3)
ffffffffc02027de:	397d                	addiw	s2,s2,-1
ffffffffc02027e0:	9c9d                	subw	s1,s1,a5
     while ((le = list_next(le)) != &free_list)
ffffffffc02027e2:	fe899ae3          	bne	s3,s0,ffffffffc02027d6 <swap_init+0x37a>
     }
     cprintf("count is %d, total is %d\n", count, total);
ffffffffc02027e6:	8626                	mv	a2,s1
ffffffffc02027e8:	85ca                	mv	a1,s2
ffffffffc02027ea:	00003517          	auipc	a0,0x3
ffffffffc02027ee:	19650513          	addi	a0,a0,406 # ffffffffc0205980 <commands+0x1518>
ffffffffc02027f2:	8cdfd0ef          	jal	ra,ffffffffc02000be <cprintf>
     // assert(count == 0);

     cprintf("check_swap() succeeded!\n");
ffffffffc02027f6:	00003517          	auipc	a0,0x3
ffffffffc02027fa:	1aa50513          	addi	a0,a0,426 # ffffffffc02059a0 <commands+0x1538>
ffffffffc02027fe:	8c1fd0ef          	jal	ra,ffffffffc02000be <cprintf>
ffffffffc0202802:	b16d                	j	ffffffffc02024ac <swap_init+0x50>
     int ret, count = 0, total = 0, i;
ffffffffc0202804:	4481                	li	s1,0
ffffffffc0202806:	4901                	li	s2,0
     while ((le = list_next(le)) != &free_list)
ffffffffc0202808:	4981                	li	s3,0
ffffffffc020280a:	bb39                	j	ffffffffc0202528 <swap_init+0xcc>
          assert(PageProperty(p));
ffffffffc020280c:	00003697          	auipc	a3,0x3
ffffffffc0202810:	eec68693          	addi	a3,a3,-276 # ffffffffc02056f8 <commands+0x1290>
ffffffffc0202814:	00002617          	auipc	a2,0x2
ffffffffc0202818:	64460613          	addi	a2,a2,1604 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc020281c:	0bb00593          	li	a1,187
ffffffffc0202820:	00003517          	auipc	a0,0x3
ffffffffc0202824:	eb050513          	addi	a0,a0,-336 # ffffffffc02056d0 <commands+0x1268>
ffffffffc0202828:	8ddfd0ef          	jal	ra,ffffffffc0200104 <__panic>
          assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc020282c:	00003697          	auipc	a3,0x3
ffffffffc0202830:	0f468693          	addi	a3,a3,244 # ffffffffc0205920 <commands+0x14b8>
ffffffffc0202834:	00002617          	auipc	a2,0x2
ffffffffc0202838:	62460613          	addi	a2,a2,1572 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc020283c:	0fd00593          	li	a1,253
ffffffffc0202840:	00003517          	auipc	a0,0x3
ffffffffc0202844:	e9050513          	addi	a0,a0,-368 # ffffffffc02056d0 <commands+0x1268>
ffffffffc0202848:	8bdfd0ef          	jal	ra,ffffffffc0200104 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc020284c:	00002617          	auipc	a2,0x2
ffffffffc0202850:	6e460613          	addi	a2,a2,1764 # ffffffffc0204f30 <commands+0xac8>
ffffffffc0202854:	07000593          	li	a1,112
ffffffffc0202858:	00002517          	auipc	a0,0x2
ffffffffc020285c:	4e850513          	addi	a0,a0,1256 # ffffffffc0204d40 <commands+0x8d8>
ffffffffc0202860:	8a5fd0ef          	jal	ra,ffffffffc0200104 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0202864:	00002617          	auipc	a2,0x2
ffffffffc0202868:	4bc60613          	addi	a2,a2,1212 # ffffffffc0204d20 <commands+0x8b8>
ffffffffc020286c:	06500593          	li	a1,101
ffffffffc0202870:	00002517          	auipc	a0,0x2
ffffffffc0202874:	4d050513          	addi	a0,a0,1232 # ffffffffc0204d40 <commands+0x8d8>
ffffffffc0202878:	88dfd0ef          	jal	ra,ffffffffc0200104 <__panic>
          assert(!PageProperty(check_rp[i]));
ffffffffc020287c:	00003697          	auipc	a3,0x3
ffffffffc0202880:	f7c68693          	addi	a3,a3,-132 # ffffffffc02057f8 <commands+0x1390>
ffffffffc0202884:	00002617          	auipc	a2,0x2
ffffffffc0202888:	5d460613          	addi	a2,a2,1492 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc020288c:	0dd00593          	li	a1,221
ffffffffc0202890:	00003517          	auipc	a0,0x3
ffffffffc0202894:	e4050513          	addi	a0,a0,-448 # ffffffffc02056d0 <commands+0x1268>
ffffffffc0202898:	86dfd0ef          	jal	ra,ffffffffc0200104 <__panic>
          assert(check_rp[i] != NULL);
ffffffffc020289c:	00003697          	auipc	a3,0x3
ffffffffc02028a0:	f4468693          	addi	a3,a3,-188 # ffffffffc02057e0 <commands+0x1378>
ffffffffc02028a4:	00002617          	auipc	a2,0x2
ffffffffc02028a8:	5b460613          	addi	a2,a2,1460 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc02028ac:	0dc00593          	li	a1,220
ffffffffc02028b0:	00003517          	auipc	a0,0x3
ffffffffc02028b4:	e2050513          	addi	a0,a0,-480 # ffffffffc02056d0 <commands+0x1268>
ffffffffc02028b8:	84dfd0ef          	jal	ra,ffffffffc0200104 <__panic>
          assert(check_ptep[i] != NULL);
ffffffffc02028bc:	00003697          	auipc	a3,0x3
ffffffffc02028c0:	04c68693          	addi	a3,a3,76 # ffffffffc0205908 <commands+0x14a0>
ffffffffc02028c4:	00002617          	auipc	a2,0x2
ffffffffc02028c8:	59460613          	addi	a2,a2,1428 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc02028cc:	0fc00593          	li	a1,252
ffffffffc02028d0:	00003517          	auipc	a0,0x3
ffffffffc02028d4:	e0050513          	addi	a0,a0,-512 # ffffffffc02056d0 <commands+0x1268>
ffffffffc02028d8:	82dfd0ef          	jal	ra,ffffffffc0200104 <__panic>
          panic("bad max_swap_offset %08x.\n", max_swap_offset);
ffffffffc02028dc:	00003617          	auipc	a2,0x3
ffffffffc02028e0:	dd460613          	addi	a2,a2,-556 # ffffffffc02056b0 <commands+0x1248>
ffffffffc02028e4:	02800593          	li	a1,40
ffffffffc02028e8:	00003517          	auipc	a0,0x3
ffffffffc02028ec:	de850513          	addi	a0,a0,-536 # ffffffffc02056d0 <commands+0x1268>
ffffffffc02028f0:	815fd0ef          	jal	ra,ffffffffc0200104 <__panic>
     assert(pgfault_num == 2);
ffffffffc02028f4:	00003697          	auipc	a3,0x3
ffffffffc02028f8:	fa468693          	addi	a3,a3,-92 # ffffffffc0205898 <commands+0x1430>
ffffffffc02028fc:	00002617          	auipc	a2,0x2
ffffffffc0202900:	55c60613          	addi	a2,a2,1372 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0202904:	09400593          	li	a1,148
ffffffffc0202908:	00003517          	auipc	a0,0x3
ffffffffc020290c:	dc850513          	addi	a0,a0,-568 # ffffffffc02056d0 <commands+0x1268>
ffffffffc0202910:	ff4fd0ef          	jal	ra,ffffffffc0200104 <__panic>
     assert(pgfault_num == 2);
ffffffffc0202914:	00003697          	auipc	a3,0x3
ffffffffc0202918:	f8468693          	addi	a3,a3,-124 # ffffffffc0205898 <commands+0x1430>
ffffffffc020291c:	00002617          	auipc	a2,0x2
ffffffffc0202920:	53c60613          	addi	a2,a2,1340 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0202924:	09600593          	li	a1,150
ffffffffc0202928:	00003517          	auipc	a0,0x3
ffffffffc020292c:	da850513          	addi	a0,a0,-600 # ffffffffc02056d0 <commands+0x1268>
ffffffffc0202930:	fd4fd0ef          	jal	ra,ffffffffc0200104 <__panic>
     assert(pgfault_num == 3);
ffffffffc0202934:	00003697          	auipc	a3,0x3
ffffffffc0202938:	f7c68693          	addi	a3,a3,-132 # ffffffffc02058b0 <commands+0x1448>
ffffffffc020293c:	00002617          	auipc	a2,0x2
ffffffffc0202940:	51c60613          	addi	a2,a2,1308 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0202944:	09800593          	li	a1,152
ffffffffc0202948:	00003517          	auipc	a0,0x3
ffffffffc020294c:	d8850513          	addi	a0,a0,-632 # ffffffffc02056d0 <commands+0x1268>
ffffffffc0202950:	fb4fd0ef          	jal	ra,ffffffffc0200104 <__panic>
     assert(pgfault_num == 3);
ffffffffc0202954:	00003697          	auipc	a3,0x3
ffffffffc0202958:	f5c68693          	addi	a3,a3,-164 # ffffffffc02058b0 <commands+0x1448>
ffffffffc020295c:	00002617          	auipc	a2,0x2
ffffffffc0202960:	4fc60613          	addi	a2,a2,1276 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0202964:	09a00593          	li	a1,154
ffffffffc0202968:	00003517          	auipc	a0,0x3
ffffffffc020296c:	d6850513          	addi	a0,a0,-664 # ffffffffc02056d0 <commands+0x1268>
ffffffffc0202970:	f94fd0ef          	jal	ra,ffffffffc0200104 <__panic>
     assert(pgfault_num == 1);
ffffffffc0202974:	00003697          	auipc	a3,0x3
ffffffffc0202978:	f0c68693          	addi	a3,a3,-244 # ffffffffc0205880 <commands+0x1418>
ffffffffc020297c:	00002617          	auipc	a2,0x2
ffffffffc0202980:	4dc60613          	addi	a2,a2,1244 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0202984:	09000593          	li	a1,144
ffffffffc0202988:	00003517          	auipc	a0,0x3
ffffffffc020298c:	d4850513          	addi	a0,a0,-696 # ffffffffc02056d0 <commands+0x1268>
ffffffffc0202990:	f74fd0ef          	jal	ra,ffffffffc0200104 <__panic>
     assert(pgfault_num == 1);
ffffffffc0202994:	00003697          	auipc	a3,0x3
ffffffffc0202998:	eec68693          	addi	a3,a3,-276 # ffffffffc0205880 <commands+0x1418>
ffffffffc020299c:	00002617          	auipc	a2,0x2
ffffffffc02029a0:	4bc60613          	addi	a2,a2,1212 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc02029a4:	09200593          	li	a1,146
ffffffffc02029a8:	00003517          	auipc	a0,0x3
ffffffffc02029ac:	d2850513          	addi	a0,a0,-728 # ffffffffc02056d0 <commands+0x1268>
ffffffffc02029b0:	f54fd0ef          	jal	ra,ffffffffc0200104 <__panic>
     assert(nr_free == CHECK_VALID_PHY_PAGE_NUM);
ffffffffc02029b4:	00003697          	auipc	a3,0x3
ffffffffc02029b8:	e6468693          	addi	a3,a3,-412 # ffffffffc0205818 <commands+0x13b0>
ffffffffc02029bc:	00002617          	auipc	a2,0x2
ffffffffc02029c0:	49c60613          	addi	a2,a2,1180 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc02029c4:	0eb00593          	li	a1,235
ffffffffc02029c8:	00003517          	auipc	a0,0x3
ffffffffc02029cc:	d0850513          	addi	a0,a0,-760 # ffffffffc02056d0 <commands+0x1268>
ffffffffc02029d0:	f34fd0ef          	jal	ra,ffffffffc0200104 <__panic>
     assert(temp_ptep != NULL);
ffffffffc02029d4:	00003697          	auipc	a3,0x3
ffffffffc02029d8:	dcc68693          	addi	a3,a3,-564 # ffffffffc02057a0 <commands+0x1338>
ffffffffc02029dc:	00002617          	auipc	a2,0x2
ffffffffc02029e0:	47c60613          	addi	a2,a2,1148 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc02029e4:	0d600593          	li	a1,214
ffffffffc02029e8:	00003517          	auipc	a0,0x3
ffffffffc02029ec:	ce850513          	addi	a0,a0,-792 # ffffffffc02056d0 <commands+0x1268>
ffffffffc02029f0:	f14fd0ef          	jal	ra,ffffffffc0200104 <__panic>
     assert(pgfault_num == 4);
ffffffffc02029f4:	00003697          	auipc	a3,0x3
ffffffffc02029f8:	ed468693          	addi	a3,a3,-300 # ffffffffc02058c8 <commands+0x1460>
ffffffffc02029fc:	00002617          	auipc	a2,0x2
ffffffffc0202a00:	45c60613          	addi	a2,a2,1116 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0202a04:	09c00593          	li	a1,156
ffffffffc0202a08:	00003517          	auipc	a0,0x3
ffffffffc0202a0c:	cc850513          	addi	a0,a0,-824 # ffffffffc02056d0 <commands+0x1268>
ffffffffc0202a10:	ef4fd0ef          	jal	ra,ffffffffc0200104 <__panic>
     assert(pgfault_num == 4);
ffffffffc0202a14:	00003697          	auipc	a3,0x3
ffffffffc0202a18:	eb468693          	addi	a3,a3,-332 # ffffffffc02058c8 <commands+0x1460>
ffffffffc0202a1c:	00002617          	auipc	a2,0x2
ffffffffc0202a20:	43c60613          	addi	a2,a2,1084 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0202a24:	09e00593          	li	a1,158
ffffffffc0202a28:	00003517          	auipc	a0,0x3
ffffffffc0202a2c:	ca850513          	addi	a0,a0,-856 # ffffffffc02056d0 <commands+0x1268>
ffffffffc0202a30:	ed4fd0ef          	jal	ra,ffffffffc0200104 <__panic>
     assert(nr_free == 0);
ffffffffc0202a34:	00003697          	auipc	a3,0x3
ffffffffc0202a38:	ec468693          	addi	a3,a3,-316 # ffffffffc02058f8 <commands+0x1490>
ffffffffc0202a3c:	00002617          	auipc	a2,0x2
ffffffffc0202a40:	41c60613          	addi	a2,a2,1052 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0202a44:	0f300593          	li	a1,243
ffffffffc0202a48:	00003517          	auipc	a0,0x3
ffffffffc0202a4c:	c8850513          	addi	a0,a0,-888 # ffffffffc02056d0 <commands+0x1268>
ffffffffc0202a50:	eb4fd0ef          	jal	ra,ffffffffc0200104 <__panic>
     assert(ret == 0);
ffffffffc0202a54:	00003697          	auipc	a3,0x3
ffffffffc0202a58:	f1c68693          	addi	a3,a3,-228 # ffffffffc0205970 <commands+0x1508>
ffffffffc0202a5c:	00002617          	auipc	a2,0x2
ffffffffc0202a60:	3fc60613          	addi	a2,a2,1020 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0202a64:	10300593          	li	a1,259
ffffffffc0202a68:	00003517          	auipc	a0,0x3
ffffffffc0202a6c:	c6850513          	addi	a0,a0,-920 # ffffffffc02056d0 <commands+0x1268>
ffffffffc0202a70:	e94fd0ef          	jal	ra,ffffffffc0200104 <__panic>
     assert(mm != NULL);
ffffffffc0202a74:	00003697          	auipc	a3,0x3
ffffffffc0202a78:	9b468693          	addi	a3,a3,-1612 # ffffffffc0205428 <commands+0xfc0>
ffffffffc0202a7c:	00002617          	auipc	a2,0x2
ffffffffc0202a80:	3dc60613          	addi	a2,a2,988 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0202a84:	0c300593          	li	a1,195
ffffffffc0202a88:	00003517          	auipc	a0,0x3
ffffffffc0202a8c:	c4850513          	addi	a0,a0,-952 # ffffffffc02056d0 <commands+0x1268>
ffffffffc0202a90:	e74fd0ef          	jal	ra,ffffffffc0200104 <__panic>
     assert(check_mm_struct == NULL);
ffffffffc0202a94:	00003697          	auipc	a3,0x3
ffffffffc0202a98:	cbc68693          	addi	a3,a3,-836 # ffffffffc0205750 <commands+0x12e8>
ffffffffc0202a9c:	00002617          	auipc	a2,0x2
ffffffffc0202aa0:	3bc60613          	addi	a2,a2,956 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0202aa4:	0c600593          	li	a1,198
ffffffffc0202aa8:	00003517          	auipc	a0,0x3
ffffffffc0202aac:	c2850513          	addi	a0,a0,-984 # ffffffffc02056d0 <commands+0x1268>
ffffffffc0202ab0:	e54fd0ef          	jal	ra,ffffffffc0200104 <__panic>
     assert(pgdir[0] == 0);
ffffffffc0202ab4:	00003697          	auipc	a3,0x3
ffffffffc0202ab8:	b2468693          	addi	a3,a3,-1244 # ffffffffc02055d8 <commands+0x1170>
ffffffffc0202abc:	00002617          	auipc	a2,0x2
ffffffffc0202ac0:	39c60613          	addi	a2,a2,924 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0202ac4:	0cb00593          	li	a1,203
ffffffffc0202ac8:	00003517          	auipc	a0,0x3
ffffffffc0202acc:	c0850513          	addi	a0,a0,-1016 # ffffffffc02056d0 <commands+0x1268>
ffffffffc0202ad0:	e34fd0ef          	jal	ra,ffffffffc0200104 <__panic>
     assert(vma != NULL);
ffffffffc0202ad4:	00003697          	auipc	a3,0x3
ffffffffc0202ad8:	b7c68693          	addi	a3,a3,-1156 # ffffffffc0205650 <commands+0x11e8>
ffffffffc0202adc:	00002617          	auipc	a2,0x2
ffffffffc0202ae0:	37c60613          	addi	a2,a2,892 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0202ae4:	0ce00593          	li	a1,206
ffffffffc0202ae8:	00003517          	auipc	a0,0x3
ffffffffc0202aec:	be850513          	addi	a0,a0,-1048 # ffffffffc02056d0 <commands+0x1268>
ffffffffc0202af0:	e14fd0ef          	jal	ra,ffffffffc0200104 <__panic>
     assert(total == nr_free_pages());
ffffffffc0202af4:	00003697          	auipc	a3,0x3
ffffffffc0202af8:	c1468693          	addi	a3,a3,-1004 # ffffffffc0205708 <commands+0x12a0>
ffffffffc0202afc:	00002617          	auipc	a2,0x2
ffffffffc0202b00:	35c60613          	addi	a2,a2,860 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0202b04:	0be00593          	li	a1,190
ffffffffc0202b08:	00003517          	auipc	a0,0x3
ffffffffc0202b0c:	bc850513          	addi	a0,a0,-1080 # ffffffffc02056d0 <commands+0x1268>
ffffffffc0202b10:	df4fd0ef          	jal	ra,ffffffffc0200104 <__panic>

ffffffffc0202b14 <swap_init_mm>:
     return sm->init_mm(mm);
ffffffffc0202b14:	0000f797          	auipc	a5,0xf
ffffffffc0202b18:	95478793          	addi	a5,a5,-1708 # ffffffffc0211468 <sm>
ffffffffc0202b1c:	639c                	ld	a5,0(a5)
ffffffffc0202b1e:	0107b303          	ld	t1,16(a5)
ffffffffc0202b22:	8302                	jr	t1

ffffffffc0202b24 <swap_map_swappable>:
     return sm->map_swappable(mm, addr, page, swap_in);
ffffffffc0202b24:	0000f797          	auipc	a5,0xf
ffffffffc0202b28:	94478793          	addi	a5,a5,-1724 # ffffffffc0211468 <sm>
ffffffffc0202b2c:	639c                	ld	a5,0(a5)
ffffffffc0202b2e:	0207b303          	ld	t1,32(a5)
ffffffffc0202b32:	8302                	jr	t1

ffffffffc0202b34 <swap_out>:
{
ffffffffc0202b34:	711d                	addi	sp,sp,-96
ffffffffc0202b36:	ec86                	sd	ra,88(sp)
ffffffffc0202b38:	e8a2                	sd	s0,80(sp)
ffffffffc0202b3a:	e4a6                	sd	s1,72(sp)
ffffffffc0202b3c:	e0ca                	sd	s2,64(sp)
ffffffffc0202b3e:	fc4e                	sd	s3,56(sp)
ffffffffc0202b40:	f852                	sd	s4,48(sp)
ffffffffc0202b42:	f456                	sd	s5,40(sp)
ffffffffc0202b44:	f05a                	sd	s6,32(sp)
ffffffffc0202b46:	ec5e                	sd	s7,24(sp)
ffffffffc0202b48:	e862                	sd	s8,16(sp)
     for (i = 0; i != n; ++i)
ffffffffc0202b4a:	cde9                	beqz	a1,ffffffffc0202c24 <swap_out+0xf0>
ffffffffc0202b4c:	8ab2                	mv	s5,a2
ffffffffc0202b4e:	892a                	mv	s2,a0
ffffffffc0202b50:	8a2e                	mv	s4,a1
ffffffffc0202b52:	4401                	li	s0,0
ffffffffc0202b54:	0000f997          	auipc	s3,0xf
ffffffffc0202b58:	91498993          	addi	s3,s3,-1772 # ffffffffc0211468 <sm>
               cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr / PGSIZE + 1);
ffffffffc0202b5c:	00003b17          	auipc	s6,0x3
ffffffffc0202b60:	ec4b0b13          	addi	s6,s6,-316 # ffffffffc0205a20 <commands+0x15b8>
               cprintf("SWAP: failed to save\n");
ffffffffc0202b64:	00003b97          	auipc	s7,0x3
ffffffffc0202b68:	ea4b8b93          	addi	s7,s7,-348 # ffffffffc0205a08 <commands+0x15a0>
ffffffffc0202b6c:	a825                	j	ffffffffc0202ba4 <swap_out+0x70>
               cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr / PGSIZE + 1);
ffffffffc0202b6e:	67a2                	ld	a5,8(sp)
ffffffffc0202b70:	8626                	mv	a2,s1
ffffffffc0202b72:	85a2                	mv	a1,s0
ffffffffc0202b74:	63b4                	ld	a3,64(a5)
ffffffffc0202b76:	855a                	mv	a0,s6
     for (i = 0; i != n; ++i)
ffffffffc0202b78:	2405                	addiw	s0,s0,1
               cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr / PGSIZE + 1);
ffffffffc0202b7a:	82b1                	srli	a3,a3,0xc
ffffffffc0202b7c:	0685                	addi	a3,a3,1
ffffffffc0202b7e:	d40fd0ef          	jal	ra,ffffffffc02000be <cprintf>
               *ptep = (page->pra_vaddr / PGSIZE + 1) << 8;
ffffffffc0202b82:	6522                	ld	a0,8(sp)
               free_page(page);
ffffffffc0202b84:	4585                	li	a1,1
               *ptep = (page->pra_vaddr / PGSIZE + 1) << 8;
ffffffffc0202b86:	613c                	ld	a5,64(a0)
ffffffffc0202b88:	83b1                	srli	a5,a5,0xc
ffffffffc0202b8a:	0785                	addi	a5,a5,1
ffffffffc0202b8c:	07a2                	slli	a5,a5,0x8
ffffffffc0202b8e:	00fc3023          	sd	a5,0(s8) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
               free_page(page);
ffffffffc0202b92:	fc3fd0ef          	jal	ra,ffffffffc0200b54 <free_pages>
          tlb_invalidate(mm->pgdir, v);
ffffffffc0202b96:	01893503          	ld	a0,24(s2)
ffffffffc0202b9a:	85a6                	mv	a1,s1
ffffffffc0202b9c:	eb7fe0ef          	jal	ra,ffffffffc0201a52 <tlb_invalidate>
     for (i = 0; i != n; ++i)
ffffffffc0202ba0:	048a0d63          	beq	s4,s0,ffffffffc0202bfa <swap_out+0xc6>
          int r = sm->swap_out_victim(mm, &page, in_tick);
ffffffffc0202ba4:	0009b783          	ld	a5,0(s3)
ffffffffc0202ba8:	8656                	mv	a2,s5
ffffffffc0202baa:	002c                	addi	a1,sp,8
ffffffffc0202bac:	7b9c                	ld	a5,48(a5)
ffffffffc0202bae:	854a                	mv	a0,s2
ffffffffc0202bb0:	9782                	jalr	a5
          if (r != 0)
ffffffffc0202bb2:	e12d                	bnez	a0,ffffffffc0202c14 <swap_out+0xe0>
          v = page->pra_vaddr;
ffffffffc0202bb4:	67a2                	ld	a5,8(sp)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0202bb6:	01893503          	ld	a0,24(s2)
ffffffffc0202bba:	4601                	li	a2,0
          v = page->pra_vaddr;
ffffffffc0202bbc:	63a4                	ld	s1,64(a5)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0202bbe:	85a6                	mv	a1,s1
ffffffffc0202bc0:	81afe0ef          	jal	ra,ffffffffc0200bda <get_pte>
          assert((*ptep & PTE_V) != 0);
ffffffffc0202bc4:	611c                	ld	a5,0(a0)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0202bc6:	8c2a                	mv	s8,a0
          assert((*ptep & PTE_V) != 0);
ffffffffc0202bc8:	8b85                	andi	a5,a5,1
ffffffffc0202bca:	cfb9                	beqz	a5,ffffffffc0202c28 <swap_out+0xf4>
          if (swapfs_write((page->pra_vaddr / PGSIZE + 1) << 8, page) != 0)
ffffffffc0202bcc:	65a2                	ld	a1,8(sp)
ffffffffc0202bce:	61bc                	ld	a5,64(a1)
ffffffffc0202bd0:	83b1                	srli	a5,a5,0xc
ffffffffc0202bd2:	00178513          	addi	a0,a5,1
ffffffffc0202bd6:	0522                	slli	a0,a0,0x8
ffffffffc0202bd8:	12c010ef          	jal	ra,ffffffffc0203d04 <swapfs_write>
ffffffffc0202bdc:	d949                	beqz	a0,ffffffffc0202b6e <swap_out+0x3a>
               cprintf("SWAP: failed to save\n");
ffffffffc0202bde:	855e                	mv	a0,s7
ffffffffc0202be0:	cdefd0ef          	jal	ra,ffffffffc02000be <cprintf>
               sm->map_swappable(mm, v, page, 0);
ffffffffc0202be4:	0009b783          	ld	a5,0(s3)
ffffffffc0202be8:	6622                	ld	a2,8(sp)
ffffffffc0202bea:	4681                	li	a3,0
ffffffffc0202bec:	739c                	ld	a5,32(a5)
ffffffffc0202bee:	85a6                	mv	a1,s1
ffffffffc0202bf0:	854a                	mv	a0,s2
     for (i = 0; i != n; ++i)
ffffffffc0202bf2:	2405                	addiw	s0,s0,1
               sm->map_swappable(mm, v, page, 0);
ffffffffc0202bf4:	9782                	jalr	a5
     for (i = 0; i != n; ++i)
ffffffffc0202bf6:	fa8a17e3          	bne	s4,s0,ffffffffc0202ba4 <swap_out+0x70>
}
ffffffffc0202bfa:	8522                	mv	a0,s0
ffffffffc0202bfc:	60e6                	ld	ra,88(sp)
ffffffffc0202bfe:	6446                	ld	s0,80(sp)
ffffffffc0202c00:	64a6                	ld	s1,72(sp)
ffffffffc0202c02:	6906                	ld	s2,64(sp)
ffffffffc0202c04:	79e2                	ld	s3,56(sp)
ffffffffc0202c06:	7a42                	ld	s4,48(sp)
ffffffffc0202c08:	7aa2                	ld	s5,40(sp)
ffffffffc0202c0a:	7b02                	ld	s6,32(sp)
ffffffffc0202c0c:	6be2                	ld	s7,24(sp)
ffffffffc0202c0e:	6c42                	ld	s8,16(sp)
ffffffffc0202c10:	6125                	addi	sp,sp,96
ffffffffc0202c12:	8082                	ret
               cprintf("i %d, swap_out: call swap_out_victim failed\n", i);
ffffffffc0202c14:	85a2                	mv	a1,s0
ffffffffc0202c16:	00003517          	auipc	a0,0x3
ffffffffc0202c1a:	daa50513          	addi	a0,a0,-598 # ffffffffc02059c0 <commands+0x1558>
ffffffffc0202c1e:	ca0fd0ef          	jal	ra,ffffffffc02000be <cprintf>
               break;
ffffffffc0202c22:	bfe1                	j	ffffffffc0202bfa <swap_out+0xc6>
     for (i = 0; i != n; ++i)
ffffffffc0202c24:	4401                	li	s0,0
ffffffffc0202c26:	bfd1                	j	ffffffffc0202bfa <swap_out+0xc6>
          assert((*ptep & PTE_V) != 0);
ffffffffc0202c28:	00003697          	auipc	a3,0x3
ffffffffc0202c2c:	dc868693          	addi	a3,a3,-568 # ffffffffc02059f0 <commands+0x1588>
ffffffffc0202c30:	00002617          	auipc	a2,0x2
ffffffffc0202c34:	22860613          	addi	a2,a2,552 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0202c38:	06500593          	li	a1,101
ffffffffc0202c3c:	00003517          	auipc	a0,0x3
ffffffffc0202c40:	a9450513          	addi	a0,a0,-1388 # ffffffffc02056d0 <commands+0x1268>
ffffffffc0202c44:	cc0fd0ef          	jal	ra,ffffffffc0200104 <__panic>

ffffffffc0202c48 <swap_in>:
{
ffffffffc0202c48:	7179                	addi	sp,sp,-48
ffffffffc0202c4a:	e84a                	sd	s2,16(sp)
ffffffffc0202c4c:	892a                	mv	s2,a0
     struct Page *result = alloc_page();
ffffffffc0202c4e:	4505                	li	a0,1
{
ffffffffc0202c50:	ec26                	sd	s1,24(sp)
ffffffffc0202c52:	e44e                	sd	s3,8(sp)
ffffffffc0202c54:	f406                	sd	ra,40(sp)
ffffffffc0202c56:	f022                	sd	s0,32(sp)
ffffffffc0202c58:	84ae                	mv	s1,a1
ffffffffc0202c5a:	89b2                	mv	s3,a2
     struct Page *result = alloc_page();
ffffffffc0202c5c:	e71fd0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
     assert(result != NULL);
ffffffffc0202c60:	c129                	beqz	a0,ffffffffc0202ca2 <swap_in+0x5a>
     pte_t *ptep = get_pte(mm->pgdir, addr, 0);
ffffffffc0202c62:	842a                	mv	s0,a0
ffffffffc0202c64:	01893503          	ld	a0,24(s2)
ffffffffc0202c68:	4601                	li	a2,0
ffffffffc0202c6a:	85a6                	mv	a1,s1
ffffffffc0202c6c:	f6ffd0ef          	jal	ra,ffffffffc0200bda <get_pte>
ffffffffc0202c70:	892a                	mv	s2,a0
     if ((r = swapfs_read((*ptep), result)) != 0)
ffffffffc0202c72:	6108                	ld	a0,0(a0)
ffffffffc0202c74:	85a2                	mv	a1,s0
ffffffffc0202c76:	7e9000ef          	jal	ra,ffffffffc0203c5e <swapfs_read>
     cprintf("swap_in: load disk swap entry %d with swap_page in vadr 0x%x\n", (*ptep) >> 8, addr);
ffffffffc0202c7a:	00093583          	ld	a1,0(s2)
ffffffffc0202c7e:	8626                	mv	a2,s1
ffffffffc0202c80:	00003517          	auipc	a0,0x3
ffffffffc0202c84:	9f050513          	addi	a0,a0,-1552 # ffffffffc0205670 <commands+0x1208>
ffffffffc0202c88:	81a1                	srli	a1,a1,0x8
ffffffffc0202c8a:	c34fd0ef          	jal	ra,ffffffffc02000be <cprintf>
}
ffffffffc0202c8e:	70a2                	ld	ra,40(sp)
     *ptr_result = result;
ffffffffc0202c90:	0089b023          	sd	s0,0(s3)
}
ffffffffc0202c94:	7402                	ld	s0,32(sp)
ffffffffc0202c96:	64e2                	ld	s1,24(sp)
ffffffffc0202c98:	6942                	ld	s2,16(sp)
ffffffffc0202c9a:	69a2                	ld	s3,8(sp)
ffffffffc0202c9c:	4501                	li	a0,0
ffffffffc0202c9e:	6145                	addi	sp,sp,48
ffffffffc0202ca0:	8082                	ret
     assert(result != NULL);
ffffffffc0202ca2:	00003697          	auipc	a3,0x3
ffffffffc0202ca6:	9be68693          	addi	a3,a3,-1602 # ffffffffc0205660 <commands+0x11f8>
ffffffffc0202caa:	00002617          	auipc	a2,0x2
ffffffffc0202cae:	1ae60613          	addi	a2,a2,430 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0202cb2:	07c00593          	li	a1,124
ffffffffc0202cb6:	00003517          	auipc	a0,0x3
ffffffffc0202cba:	a1a50513          	addi	a0,a0,-1510 # ffffffffc02056d0 <commands+0x1268>
ffffffffc0202cbe:	c46fd0ef          	jal	ra,ffffffffc0200104 <__panic>

ffffffffc0202cc2 <default_init>:
    elm->prev = elm->next = elm;
ffffffffc0202cc2:	0000f797          	auipc	a5,0xf
ffffffffc0202cc6:	8c678793          	addi	a5,a5,-1850 # ffffffffc0211588 <free_area>
ffffffffc0202cca:	e79c                	sd	a5,8(a5)
ffffffffc0202ccc:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc0202cce:	0007a823          	sw	zero,16(a5)
}
ffffffffc0202cd2:	8082                	ret

ffffffffc0202cd4 <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0202cd4:	0000f517          	auipc	a0,0xf
ffffffffc0202cd8:	8c456503          	lwu	a0,-1852(a0) # ffffffffc0211598 <free_area+0x10>
ffffffffc0202cdc:	8082                	ret

ffffffffc0202cde <default_check>:
// LAB2: below code is used to check the first fit allocation algorithm

// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc0202cde:	715d                	addi	sp,sp,-80
ffffffffc0202ce0:	f84a                	sd	s2,48(sp)
    return listelm->next;
ffffffffc0202ce2:	0000f917          	auipc	s2,0xf
ffffffffc0202ce6:	8a690913          	addi	s2,s2,-1882 # ffffffffc0211588 <free_area>
ffffffffc0202cea:	00893783          	ld	a5,8(s2)
ffffffffc0202cee:	e486                	sd	ra,72(sp)
ffffffffc0202cf0:	e0a2                	sd	s0,64(sp)
ffffffffc0202cf2:	fc26                	sd	s1,56(sp)
ffffffffc0202cf4:	f44e                	sd	s3,40(sp)
ffffffffc0202cf6:	f052                	sd	s4,32(sp)
ffffffffc0202cf8:	ec56                	sd	s5,24(sp)
ffffffffc0202cfa:	e85a                	sd	s6,16(sp)
ffffffffc0202cfc:	e45e                	sd	s7,8(sp)
ffffffffc0202cfe:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0202d00:	31278f63          	beq	a5,s2,ffffffffc020301e <default_check+0x340>
ffffffffc0202d04:	fe87b703          	ld	a4,-24(a5)
ffffffffc0202d08:	8305                	srli	a4,a4,0x1
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0202d0a:	8b05                	andi	a4,a4,1
ffffffffc0202d0c:	30070d63          	beqz	a4,ffffffffc0203026 <default_check+0x348>
    int count = 0, total = 0;
ffffffffc0202d10:	4401                	li	s0,0
ffffffffc0202d12:	4481                	li	s1,0
ffffffffc0202d14:	a031                	j	ffffffffc0202d20 <default_check+0x42>
ffffffffc0202d16:	fe87b703          	ld	a4,-24(a5)
        assert(PageProperty(p));
ffffffffc0202d1a:	8b09                	andi	a4,a4,2
ffffffffc0202d1c:	30070563          	beqz	a4,ffffffffc0203026 <default_check+0x348>
        count++, total += p->property;
ffffffffc0202d20:	ff87a703          	lw	a4,-8(a5)
ffffffffc0202d24:	679c                	ld	a5,8(a5)
ffffffffc0202d26:	2485                	addiw	s1,s1,1
ffffffffc0202d28:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0202d2a:	ff2796e3          	bne	a5,s2,ffffffffc0202d16 <default_check+0x38>
ffffffffc0202d2e:	89a2                	mv	s3,s0
    }
    assert(total == nr_free_pages());
ffffffffc0202d30:	e6bfd0ef          	jal	ra,ffffffffc0200b9a <nr_free_pages>
ffffffffc0202d34:	75351963          	bne	a0,s3,ffffffffc0203486 <default_check+0x7a8>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0202d38:	4505                	li	a0,1
ffffffffc0202d3a:	d93fd0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc0202d3e:	8a2a                	mv	s4,a0
ffffffffc0202d40:	48050363          	beqz	a0,ffffffffc02031c6 <default_check+0x4e8>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0202d44:	4505                	li	a0,1
ffffffffc0202d46:	d87fd0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc0202d4a:	89aa                	mv	s3,a0
ffffffffc0202d4c:	74050d63          	beqz	a0,ffffffffc02034a6 <default_check+0x7c8>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0202d50:	4505                	li	a0,1
ffffffffc0202d52:	d7bfd0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc0202d56:	8aaa                	mv	s5,a0
ffffffffc0202d58:	4e050763          	beqz	a0,ffffffffc0203246 <default_check+0x568>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0202d5c:	2f3a0563          	beq	s4,s3,ffffffffc0203046 <default_check+0x368>
ffffffffc0202d60:	2eaa0363          	beq	s4,a0,ffffffffc0203046 <default_check+0x368>
ffffffffc0202d64:	2ea98163          	beq	s3,a0,ffffffffc0203046 <default_check+0x368>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0202d68:	000a2783          	lw	a5,0(s4)
ffffffffc0202d6c:	2e079d63          	bnez	a5,ffffffffc0203066 <default_check+0x388>
ffffffffc0202d70:	0009a783          	lw	a5,0(s3)
ffffffffc0202d74:	2e079963          	bnez	a5,ffffffffc0203066 <default_check+0x388>
ffffffffc0202d78:	411c                	lw	a5,0(a0)
ffffffffc0202d7a:	2e079663          	bnez	a5,ffffffffc0203066 <default_check+0x388>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0202d7e:	0000e797          	auipc	a5,0xe
ffffffffc0202d82:	73278793          	addi	a5,a5,1842 # ffffffffc02114b0 <pages>
ffffffffc0202d86:	639c                	ld	a5,0(a5)
ffffffffc0202d88:	00002717          	auipc	a4,0x2
ffffffffc0202d8c:	f1870713          	addi	a4,a4,-232 # ffffffffc0204ca0 <commands+0x838>
ffffffffc0202d90:	630c                	ld	a1,0(a4)
ffffffffc0202d92:	40fa0733          	sub	a4,s4,a5
ffffffffc0202d96:	870d                	srai	a4,a4,0x3
ffffffffc0202d98:	02b70733          	mul	a4,a4,a1
ffffffffc0202d9c:	00003697          	auipc	a3,0x3
ffffffffc0202da0:	43468693          	addi	a3,a3,1076 # ffffffffc02061d0 <nbase>
ffffffffc0202da4:	6290                	ld	a2,0(a3)
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0202da6:	0000e697          	auipc	a3,0xe
ffffffffc0202daa:	6b268693          	addi	a3,a3,1714 # ffffffffc0211458 <npage>
ffffffffc0202dae:	6294                	ld	a3,0(a3)
ffffffffc0202db0:	06b2                	slli	a3,a3,0xc
ffffffffc0202db2:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0202db4:	0732                	slli	a4,a4,0xc
ffffffffc0202db6:	2cd77863          	bgeu	a4,a3,ffffffffc0203086 <default_check+0x3a8>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0202dba:	40f98733          	sub	a4,s3,a5
ffffffffc0202dbe:	870d                	srai	a4,a4,0x3
ffffffffc0202dc0:	02b70733          	mul	a4,a4,a1
ffffffffc0202dc4:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0202dc6:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0202dc8:	4ed77f63          	bgeu	a4,a3,ffffffffc02032c6 <default_check+0x5e8>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0202dcc:	40f507b3          	sub	a5,a0,a5
ffffffffc0202dd0:	878d                	srai	a5,a5,0x3
ffffffffc0202dd2:	02b787b3          	mul	a5,a5,a1
ffffffffc0202dd6:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0202dd8:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0202dda:	34d7f663          	bgeu	a5,a3,ffffffffc0203126 <default_check+0x448>
    assert(alloc_page() == NULL);
ffffffffc0202dde:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0202de0:	00093c03          	ld	s8,0(s2)
ffffffffc0202de4:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc0202de8:	01092b03          	lw	s6,16(s2)
    elm->prev = elm->next = elm;
ffffffffc0202dec:	0000e797          	auipc	a5,0xe
ffffffffc0202df0:	7b27b223          	sd	s2,1956(a5) # ffffffffc0211590 <free_area+0x8>
ffffffffc0202df4:	0000e797          	auipc	a5,0xe
ffffffffc0202df8:	7927ba23          	sd	s2,1940(a5) # ffffffffc0211588 <free_area>
    nr_free = 0;
ffffffffc0202dfc:	0000e797          	auipc	a5,0xe
ffffffffc0202e00:	7807ae23          	sw	zero,1948(a5) # ffffffffc0211598 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0202e04:	cc9fd0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc0202e08:	2e051f63          	bnez	a0,ffffffffc0203106 <default_check+0x428>
    free_page(p0);
ffffffffc0202e0c:	4585                	li	a1,1
ffffffffc0202e0e:	8552                	mv	a0,s4
ffffffffc0202e10:	d45fd0ef          	jal	ra,ffffffffc0200b54 <free_pages>
    free_page(p1);
ffffffffc0202e14:	4585                	li	a1,1
ffffffffc0202e16:	854e                	mv	a0,s3
ffffffffc0202e18:	d3dfd0ef          	jal	ra,ffffffffc0200b54 <free_pages>
    free_page(p2);
ffffffffc0202e1c:	4585                	li	a1,1
ffffffffc0202e1e:	8556                	mv	a0,s5
ffffffffc0202e20:	d35fd0ef          	jal	ra,ffffffffc0200b54 <free_pages>
    assert(nr_free == 3);
ffffffffc0202e24:	01092703          	lw	a4,16(s2)
ffffffffc0202e28:	478d                	li	a5,3
ffffffffc0202e2a:	2af71e63          	bne	a4,a5,ffffffffc02030e6 <default_check+0x408>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0202e2e:	4505                	li	a0,1
ffffffffc0202e30:	c9dfd0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc0202e34:	89aa                	mv	s3,a0
ffffffffc0202e36:	28050863          	beqz	a0,ffffffffc02030c6 <default_check+0x3e8>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0202e3a:	4505                	li	a0,1
ffffffffc0202e3c:	c91fd0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc0202e40:	8aaa                	mv	s5,a0
ffffffffc0202e42:	3e050263          	beqz	a0,ffffffffc0203226 <default_check+0x548>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0202e46:	4505                	li	a0,1
ffffffffc0202e48:	c85fd0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc0202e4c:	8a2a                	mv	s4,a0
ffffffffc0202e4e:	3a050c63          	beqz	a0,ffffffffc0203206 <default_check+0x528>
    assert(alloc_page() == NULL);
ffffffffc0202e52:	4505                	li	a0,1
ffffffffc0202e54:	c79fd0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc0202e58:	38051763          	bnez	a0,ffffffffc02031e6 <default_check+0x508>
    free_page(p0);
ffffffffc0202e5c:	4585                	li	a1,1
ffffffffc0202e5e:	854e                	mv	a0,s3
ffffffffc0202e60:	cf5fd0ef          	jal	ra,ffffffffc0200b54 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0202e64:	00893783          	ld	a5,8(s2)
ffffffffc0202e68:	23278f63          	beq	a5,s2,ffffffffc02030a6 <default_check+0x3c8>
    assert((p = alloc_page()) == p0);
ffffffffc0202e6c:	4505                	li	a0,1
ffffffffc0202e6e:	c5ffd0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc0202e72:	32a99a63          	bne	s3,a0,ffffffffc02031a6 <default_check+0x4c8>
    assert(alloc_page() == NULL);
ffffffffc0202e76:	4505                	li	a0,1
ffffffffc0202e78:	c55fd0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc0202e7c:	30051563          	bnez	a0,ffffffffc0203186 <default_check+0x4a8>
    assert(nr_free == 0);
ffffffffc0202e80:	01092783          	lw	a5,16(s2)
ffffffffc0202e84:	2e079163          	bnez	a5,ffffffffc0203166 <default_check+0x488>
    free_page(p);
ffffffffc0202e88:	854e                	mv	a0,s3
ffffffffc0202e8a:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0202e8c:	0000e797          	auipc	a5,0xe
ffffffffc0202e90:	6f87be23          	sd	s8,1788(a5) # ffffffffc0211588 <free_area>
ffffffffc0202e94:	0000e797          	auipc	a5,0xe
ffffffffc0202e98:	6f77be23          	sd	s7,1788(a5) # ffffffffc0211590 <free_area+0x8>
    nr_free = nr_free_store;
ffffffffc0202e9c:	0000e797          	auipc	a5,0xe
ffffffffc0202ea0:	6f67ae23          	sw	s6,1788(a5) # ffffffffc0211598 <free_area+0x10>
    free_page(p);
ffffffffc0202ea4:	cb1fd0ef          	jal	ra,ffffffffc0200b54 <free_pages>
    free_page(p1);
ffffffffc0202ea8:	4585                	li	a1,1
ffffffffc0202eaa:	8556                	mv	a0,s5
ffffffffc0202eac:	ca9fd0ef          	jal	ra,ffffffffc0200b54 <free_pages>
    free_page(p2);
ffffffffc0202eb0:	4585                	li	a1,1
ffffffffc0202eb2:	8552                	mv	a0,s4
ffffffffc0202eb4:	ca1fd0ef          	jal	ra,ffffffffc0200b54 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0202eb8:	4515                	li	a0,5
ffffffffc0202eba:	c13fd0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc0202ebe:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0202ec0:	28050363          	beqz	a0,ffffffffc0203146 <default_check+0x468>
ffffffffc0202ec4:	651c                	ld	a5,8(a0)
ffffffffc0202ec6:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0202ec8:	8b85                	andi	a5,a5,1
ffffffffc0202eca:	54079e63          	bnez	a5,ffffffffc0203426 <default_check+0x748>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0202ece:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0202ed0:	00093b03          	ld	s6,0(s2)
ffffffffc0202ed4:	00893a83          	ld	s5,8(s2)
ffffffffc0202ed8:	0000e797          	auipc	a5,0xe
ffffffffc0202edc:	6b27b823          	sd	s2,1712(a5) # ffffffffc0211588 <free_area>
ffffffffc0202ee0:	0000e797          	auipc	a5,0xe
ffffffffc0202ee4:	6b27b823          	sd	s2,1712(a5) # ffffffffc0211590 <free_area+0x8>
    assert(alloc_page() == NULL);
ffffffffc0202ee8:	be5fd0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc0202eec:	50051d63          	bnez	a0,ffffffffc0203406 <default_check+0x728>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0202ef0:	09098a13          	addi	s4,s3,144
ffffffffc0202ef4:	8552                	mv	a0,s4
ffffffffc0202ef6:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0202ef8:	01092b83          	lw	s7,16(s2)
    nr_free = 0;
ffffffffc0202efc:	0000e797          	auipc	a5,0xe
ffffffffc0202f00:	6807ae23          	sw	zero,1692(a5) # ffffffffc0211598 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0202f04:	c51fd0ef          	jal	ra,ffffffffc0200b54 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0202f08:	4511                	li	a0,4
ffffffffc0202f0a:	bc3fd0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc0202f0e:	4c051c63          	bnez	a0,ffffffffc02033e6 <default_check+0x708>
ffffffffc0202f12:	0989b783          	ld	a5,152(s3)
ffffffffc0202f16:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0202f18:	8b85                	andi	a5,a5,1
ffffffffc0202f1a:	4a078663          	beqz	a5,ffffffffc02033c6 <default_check+0x6e8>
ffffffffc0202f1e:	0a89a703          	lw	a4,168(s3)
ffffffffc0202f22:	478d                	li	a5,3
ffffffffc0202f24:	4af71163          	bne	a4,a5,ffffffffc02033c6 <default_check+0x6e8>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0202f28:	450d                	li	a0,3
ffffffffc0202f2a:	ba3fd0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc0202f2e:	8c2a                	mv	s8,a0
ffffffffc0202f30:	46050b63          	beqz	a0,ffffffffc02033a6 <default_check+0x6c8>
    assert(alloc_page() == NULL);
ffffffffc0202f34:	4505                	li	a0,1
ffffffffc0202f36:	b97fd0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc0202f3a:	44051663          	bnez	a0,ffffffffc0203386 <default_check+0x6a8>
    assert(p0 + 2 == p1);
ffffffffc0202f3e:	438a1463          	bne	s4,s8,ffffffffc0203366 <default_check+0x688>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0202f42:	4585                	li	a1,1
ffffffffc0202f44:	854e                	mv	a0,s3
ffffffffc0202f46:	c0ffd0ef          	jal	ra,ffffffffc0200b54 <free_pages>
    free_pages(p1, 3);
ffffffffc0202f4a:	458d                	li	a1,3
ffffffffc0202f4c:	8552                	mv	a0,s4
ffffffffc0202f4e:	c07fd0ef          	jal	ra,ffffffffc0200b54 <free_pages>
ffffffffc0202f52:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0202f56:	04898c13          	addi	s8,s3,72
ffffffffc0202f5a:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0202f5c:	8b85                	andi	a5,a5,1
ffffffffc0202f5e:	3e078463          	beqz	a5,ffffffffc0203346 <default_check+0x668>
ffffffffc0202f62:	0189a703          	lw	a4,24(s3)
ffffffffc0202f66:	4785                	li	a5,1
ffffffffc0202f68:	3cf71f63          	bne	a4,a5,ffffffffc0203346 <default_check+0x668>
ffffffffc0202f6c:	008a3783          	ld	a5,8(s4)
ffffffffc0202f70:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0202f72:	8b85                	andi	a5,a5,1
ffffffffc0202f74:	3a078963          	beqz	a5,ffffffffc0203326 <default_check+0x648>
ffffffffc0202f78:	018a2703          	lw	a4,24(s4)
ffffffffc0202f7c:	478d                	li	a5,3
ffffffffc0202f7e:	3af71463          	bne	a4,a5,ffffffffc0203326 <default_check+0x648>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0202f82:	4505                	li	a0,1
ffffffffc0202f84:	b49fd0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc0202f88:	36a99f63          	bne	s3,a0,ffffffffc0203306 <default_check+0x628>
    free_page(p0);
ffffffffc0202f8c:	4585                	li	a1,1
ffffffffc0202f8e:	bc7fd0ef          	jal	ra,ffffffffc0200b54 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0202f92:	4509                	li	a0,2
ffffffffc0202f94:	b39fd0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc0202f98:	34aa1763          	bne	s4,a0,ffffffffc02032e6 <default_check+0x608>

    free_pages(p0, 2);
ffffffffc0202f9c:	4589                	li	a1,2
ffffffffc0202f9e:	bb7fd0ef          	jal	ra,ffffffffc0200b54 <free_pages>
    free_page(p2);
ffffffffc0202fa2:	4585                	li	a1,1
ffffffffc0202fa4:	8562                	mv	a0,s8
ffffffffc0202fa6:	baffd0ef          	jal	ra,ffffffffc0200b54 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0202faa:	4515                	li	a0,5
ffffffffc0202fac:	b21fd0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc0202fb0:	89aa                	mv	s3,a0
ffffffffc0202fb2:	48050a63          	beqz	a0,ffffffffc0203446 <default_check+0x768>
    assert(alloc_page() == NULL);
ffffffffc0202fb6:	4505                	li	a0,1
ffffffffc0202fb8:	b15fd0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc0202fbc:	2e051563          	bnez	a0,ffffffffc02032a6 <default_check+0x5c8>

    assert(nr_free == 0);
ffffffffc0202fc0:	01092783          	lw	a5,16(s2)
ffffffffc0202fc4:	2c079163          	bnez	a5,ffffffffc0203286 <default_check+0x5a8>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0202fc8:	4595                	li	a1,5
ffffffffc0202fca:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0202fcc:	0000e797          	auipc	a5,0xe
ffffffffc0202fd0:	5d77a623          	sw	s7,1484(a5) # ffffffffc0211598 <free_area+0x10>
    free_list = free_list_store;
ffffffffc0202fd4:	0000e797          	auipc	a5,0xe
ffffffffc0202fd8:	5b67ba23          	sd	s6,1460(a5) # ffffffffc0211588 <free_area>
ffffffffc0202fdc:	0000e797          	auipc	a5,0xe
ffffffffc0202fe0:	5b57ba23          	sd	s5,1460(a5) # ffffffffc0211590 <free_area+0x8>
    free_pages(p0, 5);
ffffffffc0202fe4:	b71fd0ef          	jal	ra,ffffffffc0200b54 <free_pages>
    return listelm->next;
ffffffffc0202fe8:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0202fec:	01278963          	beq	a5,s2,ffffffffc0202ffe <default_check+0x320>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc0202ff0:	ff87a703          	lw	a4,-8(a5)
ffffffffc0202ff4:	679c                	ld	a5,8(a5)
ffffffffc0202ff6:	34fd                	addiw	s1,s1,-1
ffffffffc0202ff8:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0202ffa:	ff279be3          	bne	a5,s2,ffffffffc0202ff0 <default_check+0x312>
    }
    assert(count == 0);
ffffffffc0202ffe:	26049463          	bnez	s1,ffffffffc0203266 <default_check+0x588>
    assert(total == 0);
ffffffffc0203002:	46041263          	bnez	s0,ffffffffc0203466 <default_check+0x788>
}
ffffffffc0203006:	60a6                	ld	ra,72(sp)
ffffffffc0203008:	6406                	ld	s0,64(sp)
ffffffffc020300a:	74e2                	ld	s1,56(sp)
ffffffffc020300c:	7942                	ld	s2,48(sp)
ffffffffc020300e:	79a2                	ld	s3,40(sp)
ffffffffc0203010:	7a02                	ld	s4,32(sp)
ffffffffc0203012:	6ae2                	ld	s5,24(sp)
ffffffffc0203014:	6b42                	ld	s6,16(sp)
ffffffffc0203016:	6ba2                	ld	s7,8(sp)
ffffffffc0203018:	6c02                	ld	s8,0(sp)
ffffffffc020301a:	6161                	addi	sp,sp,80
ffffffffc020301c:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc020301e:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0203020:	4401                	li	s0,0
ffffffffc0203022:	4481                	li	s1,0
ffffffffc0203024:	b331                	j	ffffffffc0202d30 <default_check+0x52>
        assert(PageProperty(p));
ffffffffc0203026:	00002697          	auipc	a3,0x2
ffffffffc020302a:	6d268693          	addi	a3,a3,1746 # ffffffffc02056f8 <commands+0x1290>
ffffffffc020302e:	00002617          	auipc	a2,0x2
ffffffffc0203032:	e2a60613          	addi	a2,a2,-470 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0203036:	12800593          	li	a1,296
ffffffffc020303a:	00003517          	auipc	a0,0x3
ffffffffc020303e:	a2650513          	addi	a0,a0,-1498 # ffffffffc0205a60 <commands+0x15f8>
ffffffffc0203042:	8c2fd0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0203046:	00003697          	auipc	a3,0x3
ffffffffc020304a:	a9268693          	addi	a3,a3,-1390 # ffffffffc0205ad8 <commands+0x1670>
ffffffffc020304e:	00002617          	auipc	a2,0x2
ffffffffc0203052:	e0a60613          	addi	a2,a2,-502 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0203056:	0f200593          	li	a1,242
ffffffffc020305a:	00003517          	auipc	a0,0x3
ffffffffc020305e:	a0650513          	addi	a0,a0,-1530 # ffffffffc0205a60 <commands+0x15f8>
ffffffffc0203062:	8a2fd0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0203066:	00003697          	auipc	a3,0x3
ffffffffc020306a:	a9a68693          	addi	a3,a3,-1382 # ffffffffc0205b00 <commands+0x1698>
ffffffffc020306e:	00002617          	auipc	a2,0x2
ffffffffc0203072:	dea60613          	addi	a2,a2,-534 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0203076:	0f300593          	li	a1,243
ffffffffc020307a:	00003517          	auipc	a0,0x3
ffffffffc020307e:	9e650513          	addi	a0,a0,-1562 # ffffffffc0205a60 <commands+0x15f8>
ffffffffc0203082:	882fd0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0203086:	00003697          	auipc	a3,0x3
ffffffffc020308a:	aba68693          	addi	a3,a3,-1350 # ffffffffc0205b40 <commands+0x16d8>
ffffffffc020308e:	00002617          	auipc	a2,0x2
ffffffffc0203092:	dca60613          	addi	a2,a2,-566 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0203096:	0f500593          	li	a1,245
ffffffffc020309a:	00003517          	auipc	a0,0x3
ffffffffc020309e:	9c650513          	addi	a0,a0,-1594 # ffffffffc0205a60 <commands+0x15f8>
ffffffffc02030a2:	862fd0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(!list_empty(&free_list));
ffffffffc02030a6:	00003697          	auipc	a3,0x3
ffffffffc02030aa:	b2268693          	addi	a3,a3,-1246 # ffffffffc0205bc8 <commands+0x1760>
ffffffffc02030ae:	00002617          	auipc	a2,0x2
ffffffffc02030b2:	daa60613          	addi	a2,a2,-598 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc02030b6:	10e00593          	li	a1,270
ffffffffc02030ba:	00003517          	auipc	a0,0x3
ffffffffc02030be:	9a650513          	addi	a0,a0,-1626 # ffffffffc0205a60 <commands+0x15f8>
ffffffffc02030c2:	842fd0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02030c6:	00003697          	auipc	a3,0x3
ffffffffc02030ca:	9b268693          	addi	a3,a3,-1614 # ffffffffc0205a78 <commands+0x1610>
ffffffffc02030ce:	00002617          	auipc	a2,0x2
ffffffffc02030d2:	d8a60613          	addi	a2,a2,-630 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc02030d6:	10700593          	li	a1,263
ffffffffc02030da:	00003517          	auipc	a0,0x3
ffffffffc02030de:	98650513          	addi	a0,a0,-1658 # ffffffffc0205a60 <commands+0x15f8>
ffffffffc02030e2:	822fd0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(nr_free == 3);
ffffffffc02030e6:	00003697          	auipc	a3,0x3
ffffffffc02030ea:	ad268693          	addi	a3,a3,-1326 # ffffffffc0205bb8 <commands+0x1750>
ffffffffc02030ee:	00002617          	auipc	a2,0x2
ffffffffc02030f2:	d6a60613          	addi	a2,a2,-662 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc02030f6:	10500593          	li	a1,261
ffffffffc02030fa:	00003517          	auipc	a0,0x3
ffffffffc02030fe:	96650513          	addi	a0,a0,-1690 # ffffffffc0205a60 <commands+0x15f8>
ffffffffc0203102:	802fd0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0203106:	00003697          	auipc	a3,0x3
ffffffffc020310a:	a9a68693          	addi	a3,a3,-1382 # ffffffffc0205ba0 <commands+0x1738>
ffffffffc020310e:	00002617          	auipc	a2,0x2
ffffffffc0203112:	d4a60613          	addi	a2,a2,-694 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0203116:	10000593          	li	a1,256
ffffffffc020311a:	00003517          	auipc	a0,0x3
ffffffffc020311e:	94650513          	addi	a0,a0,-1722 # ffffffffc0205a60 <commands+0x15f8>
ffffffffc0203122:	fe3fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0203126:	00003697          	auipc	a3,0x3
ffffffffc020312a:	a5a68693          	addi	a3,a3,-1446 # ffffffffc0205b80 <commands+0x1718>
ffffffffc020312e:	00002617          	auipc	a2,0x2
ffffffffc0203132:	d2a60613          	addi	a2,a2,-726 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0203136:	0f700593          	li	a1,247
ffffffffc020313a:	00003517          	auipc	a0,0x3
ffffffffc020313e:	92650513          	addi	a0,a0,-1754 # ffffffffc0205a60 <commands+0x15f8>
ffffffffc0203142:	fc3fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(p0 != NULL);
ffffffffc0203146:	00003697          	auipc	a3,0x3
ffffffffc020314a:	aba68693          	addi	a3,a3,-1350 # ffffffffc0205c00 <commands+0x1798>
ffffffffc020314e:	00002617          	auipc	a2,0x2
ffffffffc0203152:	d0a60613          	addi	a2,a2,-758 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0203156:	13000593          	li	a1,304
ffffffffc020315a:	00003517          	auipc	a0,0x3
ffffffffc020315e:	90650513          	addi	a0,a0,-1786 # ffffffffc0205a60 <commands+0x15f8>
ffffffffc0203162:	fa3fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(nr_free == 0);
ffffffffc0203166:	00002697          	auipc	a3,0x2
ffffffffc020316a:	79268693          	addi	a3,a3,1938 # ffffffffc02058f8 <commands+0x1490>
ffffffffc020316e:	00002617          	auipc	a2,0x2
ffffffffc0203172:	cea60613          	addi	a2,a2,-790 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0203176:	11400593          	li	a1,276
ffffffffc020317a:	00003517          	auipc	a0,0x3
ffffffffc020317e:	8e650513          	addi	a0,a0,-1818 # ffffffffc0205a60 <commands+0x15f8>
ffffffffc0203182:	f83fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0203186:	00003697          	auipc	a3,0x3
ffffffffc020318a:	a1a68693          	addi	a3,a3,-1510 # ffffffffc0205ba0 <commands+0x1738>
ffffffffc020318e:	00002617          	auipc	a2,0x2
ffffffffc0203192:	cca60613          	addi	a2,a2,-822 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0203196:	11200593          	li	a1,274
ffffffffc020319a:	00003517          	auipc	a0,0x3
ffffffffc020319e:	8c650513          	addi	a0,a0,-1850 # ffffffffc0205a60 <commands+0x15f8>
ffffffffc02031a2:	f63fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc02031a6:	00003697          	auipc	a3,0x3
ffffffffc02031aa:	a3a68693          	addi	a3,a3,-1478 # ffffffffc0205be0 <commands+0x1778>
ffffffffc02031ae:	00002617          	auipc	a2,0x2
ffffffffc02031b2:	caa60613          	addi	a2,a2,-854 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc02031b6:	11100593          	li	a1,273
ffffffffc02031ba:	00003517          	auipc	a0,0x3
ffffffffc02031be:	8a650513          	addi	a0,a0,-1882 # ffffffffc0205a60 <commands+0x15f8>
ffffffffc02031c2:	f43fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02031c6:	00003697          	auipc	a3,0x3
ffffffffc02031ca:	8b268693          	addi	a3,a3,-1870 # ffffffffc0205a78 <commands+0x1610>
ffffffffc02031ce:	00002617          	auipc	a2,0x2
ffffffffc02031d2:	c8a60613          	addi	a2,a2,-886 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc02031d6:	0ee00593          	li	a1,238
ffffffffc02031da:	00003517          	auipc	a0,0x3
ffffffffc02031de:	88650513          	addi	a0,a0,-1914 # ffffffffc0205a60 <commands+0x15f8>
ffffffffc02031e2:	f23fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02031e6:	00003697          	auipc	a3,0x3
ffffffffc02031ea:	9ba68693          	addi	a3,a3,-1606 # ffffffffc0205ba0 <commands+0x1738>
ffffffffc02031ee:	00002617          	auipc	a2,0x2
ffffffffc02031f2:	c6a60613          	addi	a2,a2,-918 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc02031f6:	10b00593          	li	a1,267
ffffffffc02031fa:	00003517          	auipc	a0,0x3
ffffffffc02031fe:	86650513          	addi	a0,a0,-1946 # ffffffffc0205a60 <commands+0x15f8>
ffffffffc0203202:	f03fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0203206:	00003697          	auipc	a3,0x3
ffffffffc020320a:	8b268693          	addi	a3,a3,-1870 # ffffffffc0205ab8 <commands+0x1650>
ffffffffc020320e:	00002617          	auipc	a2,0x2
ffffffffc0203212:	c4a60613          	addi	a2,a2,-950 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0203216:	10900593          	li	a1,265
ffffffffc020321a:	00003517          	auipc	a0,0x3
ffffffffc020321e:	84650513          	addi	a0,a0,-1978 # ffffffffc0205a60 <commands+0x15f8>
ffffffffc0203222:	ee3fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0203226:	00003697          	auipc	a3,0x3
ffffffffc020322a:	87268693          	addi	a3,a3,-1934 # ffffffffc0205a98 <commands+0x1630>
ffffffffc020322e:	00002617          	auipc	a2,0x2
ffffffffc0203232:	c2a60613          	addi	a2,a2,-982 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0203236:	10800593          	li	a1,264
ffffffffc020323a:	00003517          	auipc	a0,0x3
ffffffffc020323e:	82650513          	addi	a0,a0,-2010 # ffffffffc0205a60 <commands+0x15f8>
ffffffffc0203242:	ec3fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0203246:	00003697          	auipc	a3,0x3
ffffffffc020324a:	87268693          	addi	a3,a3,-1934 # ffffffffc0205ab8 <commands+0x1650>
ffffffffc020324e:	00002617          	auipc	a2,0x2
ffffffffc0203252:	c0a60613          	addi	a2,a2,-1014 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0203256:	0f000593          	li	a1,240
ffffffffc020325a:	00003517          	auipc	a0,0x3
ffffffffc020325e:	80650513          	addi	a0,a0,-2042 # ffffffffc0205a60 <commands+0x15f8>
ffffffffc0203262:	ea3fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(count == 0);
ffffffffc0203266:	00003697          	auipc	a3,0x3
ffffffffc020326a:	aea68693          	addi	a3,a3,-1302 # ffffffffc0205d50 <commands+0x18e8>
ffffffffc020326e:	00002617          	auipc	a2,0x2
ffffffffc0203272:	bea60613          	addi	a2,a2,-1046 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0203276:	15e00593          	li	a1,350
ffffffffc020327a:	00002517          	auipc	a0,0x2
ffffffffc020327e:	7e650513          	addi	a0,a0,2022 # ffffffffc0205a60 <commands+0x15f8>
ffffffffc0203282:	e83fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(nr_free == 0);
ffffffffc0203286:	00002697          	auipc	a3,0x2
ffffffffc020328a:	67268693          	addi	a3,a3,1650 # ffffffffc02058f8 <commands+0x1490>
ffffffffc020328e:	00002617          	auipc	a2,0x2
ffffffffc0203292:	bca60613          	addi	a2,a2,-1078 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0203296:	15200593          	li	a1,338
ffffffffc020329a:	00002517          	auipc	a0,0x2
ffffffffc020329e:	7c650513          	addi	a0,a0,1990 # ffffffffc0205a60 <commands+0x15f8>
ffffffffc02032a2:	e63fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02032a6:	00003697          	auipc	a3,0x3
ffffffffc02032aa:	8fa68693          	addi	a3,a3,-1798 # ffffffffc0205ba0 <commands+0x1738>
ffffffffc02032ae:	00002617          	auipc	a2,0x2
ffffffffc02032b2:	baa60613          	addi	a2,a2,-1110 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc02032b6:	15000593          	li	a1,336
ffffffffc02032ba:	00002517          	auipc	a0,0x2
ffffffffc02032be:	7a650513          	addi	a0,a0,1958 # ffffffffc0205a60 <commands+0x15f8>
ffffffffc02032c2:	e43fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02032c6:	00003697          	auipc	a3,0x3
ffffffffc02032ca:	89a68693          	addi	a3,a3,-1894 # ffffffffc0205b60 <commands+0x16f8>
ffffffffc02032ce:	00002617          	auipc	a2,0x2
ffffffffc02032d2:	b8a60613          	addi	a2,a2,-1142 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc02032d6:	0f600593          	li	a1,246
ffffffffc02032da:	00002517          	auipc	a0,0x2
ffffffffc02032de:	78650513          	addi	a0,a0,1926 # ffffffffc0205a60 <commands+0x15f8>
ffffffffc02032e2:	e23fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02032e6:	00003697          	auipc	a3,0x3
ffffffffc02032ea:	a2a68693          	addi	a3,a3,-1494 # ffffffffc0205d10 <commands+0x18a8>
ffffffffc02032ee:	00002617          	auipc	a2,0x2
ffffffffc02032f2:	b6a60613          	addi	a2,a2,-1174 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc02032f6:	14a00593          	li	a1,330
ffffffffc02032fa:	00002517          	auipc	a0,0x2
ffffffffc02032fe:	76650513          	addi	a0,a0,1894 # ffffffffc0205a60 <commands+0x15f8>
ffffffffc0203302:	e03fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0203306:	00003697          	auipc	a3,0x3
ffffffffc020330a:	9ea68693          	addi	a3,a3,-1558 # ffffffffc0205cf0 <commands+0x1888>
ffffffffc020330e:	00002617          	auipc	a2,0x2
ffffffffc0203312:	b4a60613          	addi	a2,a2,-1206 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0203316:	14800593          	li	a1,328
ffffffffc020331a:	00002517          	auipc	a0,0x2
ffffffffc020331e:	74650513          	addi	a0,a0,1862 # ffffffffc0205a60 <commands+0x15f8>
ffffffffc0203322:	de3fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0203326:	00003697          	auipc	a3,0x3
ffffffffc020332a:	9a268693          	addi	a3,a3,-1630 # ffffffffc0205cc8 <commands+0x1860>
ffffffffc020332e:	00002617          	auipc	a2,0x2
ffffffffc0203332:	b2a60613          	addi	a2,a2,-1238 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0203336:	14600593          	li	a1,326
ffffffffc020333a:	00002517          	auipc	a0,0x2
ffffffffc020333e:	72650513          	addi	a0,a0,1830 # ffffffffc0205a60 <commands+0x15f8>
ffffffffc0203342:	dc3fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0203346:	00003697          	auipc	a3,0x3
ffffffffc020334a:	95a68693          	addi	a3,a3,-1702 # ffffffffc0205ca0 <commands+0x1838>
ffffffffc020334e:	00002617          	auipc	a2,0x2
ffffffffc0203352:	b0a60613          	addi	a2,a2,-1270 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0203356:	14500593          	li	a1,325
ffffffffc020335a:	00002517          	auipc	a0,0x2
ffffffffc020335e:	70650513          	addi	a0,a0,1798 # ffffffffc0205a60 <commands+0x15f8>
ffffffffc0203362:	da3fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(p0 + 2 == p1);
ffffffffc0203366:	00003697          	auipc	a3,0x3
ffffffffc020336a:	92a68693          	addi	a3,a3,-1750 # ffffffffc0205c90 <commands+0x1828>
ffffffffc020336e:	00002617          	auipc	a2,0x2
ffffffffc0203372:	aea60613          	addi	a2,a2,-1302 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0203376:	14000593          	li	a1,320
ffffffffc020337a:	00002517          	auipc	a0,0x2
ffffffffc020337e:	6e650513          	addi	a0,a0,1766 # ffffffffc0205a60 <commands+0x15f8>
ffffffffc0203382:	d83fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0203386:	00003697          	auipc	a3,0x3
ffffffffc020338a:	81a68693          	addi	a3,a3,-2022 # ffffffffc0205ba0 <commands+0x1738>
ffffffffc020338e:	00002617          	auipc	a2,0x2
ffffffffc0203392:	aca60613          	addi	a2,a2,-1334 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0203396:	13f00593          	li	a1,319
ffffffffc020339a:	00002517          	auipc	a0,0x2
ffffffffc020339e:	6c650513          	addi	a0,a0,1734 # ffffffffc0205a60 <commands+0x15f8>
ffffffffc02033a2:	d63fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02033a6:	00003697          	auipc	a3,0x3
ffffffffc02033aa:	8ca68693          	addi	a3,a3,-1846 # ffffffffc0205c70 <commands+0x1808>
ffffffffc02033ae:	00002617          	auipc	a2,0x2
ffffffffc02033b2:	aaa60613          	addi	a2,a2,-1366 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc02033b6:	13e00593          	li	a1,318
ffffffffc02033ba:	00002517          	auipc	a0,0x2
ffffffffc02033be:	6a650513          	addi	a0,a0,1702 # ffffffffc0205a60 <commands+0x15f8>
ffffffffc02033c2:	d43fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02033c6:	00003697          	auipc	a3,0x3
ffffffffc02033ca:	87a68693          	addi	a3,a3,-1926 # ffffffffc0205c40 <commands+0x17d8>
ffffffffc02033ce:	00002617          	auipc	a2,0x2
ffffffffc02033d2:	a8a60613          	addi	a2,a2,-1398 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc02033d6:	13d00593          	li	a1,317
ffffffffc02033da:	00002517          	auipc	a0,0x2
ffffffffc02033de:	68650513          	addi	a0,a0,1670 # ffffffffc0205a60 <commands+0x15f8>
ffffffffc02033e2:	d23fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02033e6:	00003697          	auipc	a3,0x3
ffffffffc02033ea:	84268693          	addi	a3,a3,-1982 # ffffffffc0205c28 <commands+0x17c0>
ffffffffc02033ee:	00002617          	auipc	a2,0x2
ffffffffc02033f2:	a6a60613          	addi	a2,a2,-1430 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc02033f6:	13c00593          	li	a1,316
ffffffffc02033fa:	00002517          	auipc	a0,0x2
ffffffffc02033fe:	66650513          	addi	a0,a0,1638 # ffffffffc0205a60 <commands+0x15f8>
ffffffffc0203402:	d03fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0203406:	00002697          	auipc	a3,0x2
ffffffffc020340a:	79a68693          	addi	a3,a3,1946 # ffffffffc0205ba0 <commands+0x1738>
ffffffffc020340e:	00002617          	auipc	a2,0x2
ffffffffc0203412:	a4a60613          	addi	a2,a2,-1462 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0203416:	13600593          	li	a1,310
ffffffffc020341a:	00002517          	auipc	a0,0x2
ffffffffc020341e:	64650513          	addi	a0,a0,1606 # ffffffffc0205a60 <commands+0x15f8>
ffffffffc0203422:	ce3fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(!PageProperty(p0));
ffffffffc0203426:	00002697          	auipc	a3,0x2
ffffffffc020342a:	7ea68693          	addi	a3,a3,2026 # ffffffffc0205c10 <commands+0x17a8>
ffffffffc020342e:	00002617          	auipc	a2,0x2
ffffffffc0203432:	a2a60613          	addi	a2,a2,-1494 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0203436:	13100593          	li	a1,305
ffffffffc020343a:	00002517          	auipc	a0,0x2
ffffffffc020343e:	62650513          	addi	a0,a0,1574 # ffffffffc0205a60 <commands+0x15f8>
ffffffffc0203442:	cc3fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0203446:	00003697          	auipc	a3,0x3
ffffffffc020344a:	8ea68693          	addi	a3,a3,-1814 # ffffffffc0205d30 <commands+0x18c8>
ffffffffc020344e:	00002617          	auipc	a2,0x2
ffffffffc0203452:	a0a60613          	addi	a2,a2,-1526 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0203456:	14f00593          	li	a1,335
ffffffffc020345a:	00002517          	auipc	a0,0x2
ffffffffc020345e:	60650513          	addi	a0,a0,1542 # ffffffffc0205a60 <commands+0x15f8>
ffffffffc0203462:	ca3fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(total == 0);
ffffffffc0203466:	00003697          	auipc	a3,0x3
ffffffffc020346a:	8fa68693          	addi	a3,a3,-1798 # ffffffffc0205d60 <commands+0x18f8>
ffffffffc020346e:	00002617          	auipc	a2,0x2
ffffffffc0203472:	9ea60613          	addi	a2,a2,-1558 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0203476:	15f00593          	li	a1,351
ffffffffc020347a:	00002517          	auipc	a0,0x2
ffffffffc020347e:	5e650513          	addi	a0,a0,1510 # ffffffffc0205a60 <commands+0x15f8>
ffffffffc0203482:	c83fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(total == nr_free_pages());
ffffffffc0203486:	00002697          	auipc	a3,0x2
ffffffffc020348a:	28268693          	addi	a3,a3,642 # ffffffffc0205708 <commands+0x12a0>
ffffffffc020348e:	00002617          	auipc	a2,0x2
ffffffffc0203492:	9ca60613          	addi	a2,a2,-1590 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0203496:	12b00593          	li	a1,299
ffffffffc020349a:	00002517          	auipc	a0,0x2
ffffffffc020349e:	5c650513          	addi	a0,a0,1478 # ffffffffc0205a60 <commands+0x15f8>
ffffffffc02034a2:	c63fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02034a6:	00002697          	auipc	a3,0x2
ffffffffc02034aa:	5f268693          	addi	a3,a3,1522 # ffffffffc0205a98 <commands+0x1630>
ffffffffc02034ae:	00002617          	auipc	a2,0x2
ffffffffc02034b2:	9aa60613          	addi	a2,a2,-1622 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc02034b6:	0ef00593          	li	a1,239
ffffffffc02034ba:	00002517          	auipc	a0,0x2
ffffffffc02034be:	5a650513          	addi	a0,a0,1446 # ffffffffc0205a60 <commands+0x15f8>
ffffffffc02034c2:	c43fc0ef          	jal	ra,ffffffffc0200104 <__panic>

ffffffffc02034c6 <default_free_pages>:
{
ffffffffc02034c6:	1141                	addi	sp,sp,-16
ffffffffc02034c8:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02034ca:	18058063          	beqz	a1,ffffffffc020364a <default_free_pages+0x184>
    for (; p != base + n; p++)
ffffffffc02034ce:	00359693          	slli	a3,a1,0x3
ffffffffc02034d2:	96ae                	add	a3,a3,a1
ffffffffc02034d4:	068e                	slli	a3,a3,0x3
ffffffffc02034d6:	96aa                	add	a3,a3,a0
ffffffffc02034d8:	02d50d63          	beq	a0,a3,ffffffffc0203512 <default_free_pages+0x4c>
ffffffffc02034dc:	651c                	ld	a5,8(a0)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02034de:	8b85                	andi	a5,a5,1
ffffffffc02034e0:	14079563          	bnez	a5,ffffffffc020362a <default_free_pages+0x164>
ffffffffc02034e4:	651c                	ld	a5,8(a0)
ffffffffc02034e6:	8385                	srli	a5,a5,0x1
ffffffffc02034e8:	8b85                	andi	a5,a5,1
ffffffffc02034ea:	14079063          	bnez	a5,ffffffffc020362a <default_free_pages+0x164>
ffffffffc02034ee:	87aa                	mv	a5,a0
ffffffffc02034f0:	a809                	j	ffffffffc0203502 <default_free_pages+0x3c>
ffffffffc02034f2:	6798                	ld	a4,8(a5)
ffffffffc02034f4:	8b05                	andi	a4,a4,1
ffffffffc02034f6:	12071a63          	bnez	a4,ffffffffc020362a <default_free_pages+0x164>
ffffffffc02034fa:	6798                	ld	a4,8(a5)
ffffffffc02034fc:	8b09                	andi	a4,a4,2
ffffffffc02034fe:	12071663          	bnez	a4,ffffffffc020362a <default_free_pages+0x164>
        p->flags = 0;
ffffffffc0203502:	0007b423          	sd	zero,8(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0203506:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc020350a:	04878793          	addi	a5,a5,72
ffffffffc020350e:	fed792e3          	bne	a5,a3,ffffffffc02034f2 <default_free_pages+0x2c>
    base->property = n;
ffffffffc0203512:	2581                	sext.w	a1,a1
ffffffffc0203514:	cd0c                	sw	a1,24(a0)
    SetPageProperty(base);
ffffffffc0203516:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020351a:	4789                	li	a5,2
ffffffffc020351c:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0203520:	0000e697          	auipc	a3,0xe
ffffffffc0203524:	06868693          	addi	a3,a3,104 # ffffffffc0211588 <free_area>
ffffffffc0203528:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc020352a:	669c                	ld	a5,8(a3)
ffffffffc020352c:	9db9                	addw	a1,a1,a4
ffffffffc020352e:	0000e717          	auipc	a4,0xe
ffffffffc0203532:	06b72523          	sw	a1,106(a4) # ffffffffc0211598 <free_area+0x10>
    if (list_empty(&free_list))
ffffffffc0203536:	08d78f63          	beq	a5,a3,ffffffffc02035d4 <default_free_pages+0x10e>
            struct Page *page = le2page(le, page_link);
ffffffffc020353a:	fe078713          	addi	a4,a5,-32
ffffffffc020353e:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list))
ffffffffc0203540:	4801                	li	a6,0
ffffffffc0203542:	02050613          	addi	a2,a0,32
            if (base < page)
ffffffffc0203546:	00e56a63          	bltu	a0,a4,ffffffffc020355a <default_free_pages+0x94>
    return listelm->next;
ffffffffc020354a:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc020354c:	02d70563          	beq	a4,a3,ffffffffc0203576 <default_free_pages+0xb0>
        while ((le = list_next(le)) != &free_list)
ffffffffc0203550:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0203552:	fe078713          	addi	a4,a5,-32
            if (base < page)
ffffffffc0203556:	fee57ae3          	bgeu	a0,a4,ffffffffc020354a <default_free_pages+0x84>
ffffffffc020355a:	00080663          	beqz	a6,ffffffffc0203566 <default_free_pages+0xa0>
ffffffffc020355e:	0000e817          	auipc	a6,0xe
ffffffffc0203562:	02b83523          	sd	a1,42(a6) # ffffffffc0211588 <free_area>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0203566:	638c                	ld	a1,0(a5)
    prev->next = next->prev = elm;
ffffffffc0203568:	e390                	sd	a2,0(a5)
ffffffffc020356a:	e590                	sd	a2,8(a1)
    elm->next = next;
ffffffffc020356c:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc020356e:	f10c                	sd	a1,32(a0)
    if (le != &free_list)
ffffffffc0203570:	02d59163          	bne	a1,a3,ffffffffc0203592 <default_free_pages+0xcc>
ffffffffc0203574:	a091                	j	ffffffffc02035b8 <default_free_pages+0xf2>
    prev->next = next->prev = elm;
ffffffffc0203576:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0203578:	f514                	sd	a3,40(a0)
ffffffffc020357a:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020357c:	f11c                	sd	a5,32(a0)
                list_add(le, &(base->page_link));
ffffffffc020357e:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list)
ffffffffc0203580:	00d70563          	beq	a4,a3,ffffffffc020358a <default_free_pages+0xc4>
ffffffffc0203584:	4805                	li	a6,1
ffffffffc0203586:	87ba                	mv	a5,a4
ffffffffc0203588:	b7e9                	j	ffffffffc0203552 <default_free_pages+0x8c>
ffffffffc020358a:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc020358c:	85be                	mv	a1,a5
    if (le != &free_list)
ffffffffc020358e:	02d78163          	beq	a5,a3,ffffffffc02035b0 <default_free_pages+0xea>
        if (p + p->property == base)
ffffffffc0203592:	ff85a803          	lw	a6,-8(a1) # ff8 <BASE_ADDRESS-0xffffffffc01ff008>
        p = le2page(le, page_link);
ffffffffc0203596:	fe058613          	addi	a2,a1,-32
        if (p + p->property == base)
ffffffffc020359a:	02081713          	slli	a4,a6,0x20
ffffffffc020359e:	9301                	srli	a4,a4,0x20
ffffffffc02035a0:	00371793          	slli	a5,a4,0x3
ffffffffc02035a4:	97ba                	add	a5,a5,a4
ffffffffc02035a6:	078e                	slli	a5,a5,0x3
ffffffffc02035a8:	97b2                	add	a5,a5,a2
ffffffffc02035aa:	02f50e63          	beq	a0,a5,ffffffffc02035e6 <default_free_pages+0x120>
ffffffffc02035ae:	751c                	ld	a5,40(a0)
    if (le != &free_list)
ffffffffc02035b0:	fe078713          	addi	a4,a5,-32
ffffffffc02035b4:	00d78d63          	beq	a5,a3,ffffffffc02035ce <default_free_pages+0x108>
        if (base + base->property == p)
ffffffffc02035b8:	4d0c                	lw	a1,24(a0)
ffffffffc02035ba:	02059613          	slli	a2,a1,0x20
ffffffffc02035be:	9201                	srli	a2,a2,0x20
ffffffffc02035c0:	00361693          	slli	a3,a2,0x3
ffffffffc02035c4:	96b2                	add	a3,a3,a2
ffffffffc02035c6:	068e                	slli	a3,a3,0x3
ffffffffc02035c8:	96aa                	add	a3,a3,a0
ffffffffc02035ca:	04d70063          	beq	a4,a3,ffffffffc020360a <default_free_pages+0x144>
}
ffffffffc02035ce:	60a2                	ld	ra,8(sp)
ffffffffc02035d0:	0141                	addi	sp,sp,16
ffffffffc02035d2:	8082                	ret
ffffffffc02035d4:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc02035d6:	02050713          	addi	a4,a0,32
    prev->next = next->prev = elm;
ffffffffc02035da:	e398                	sd	a4,0(a5)
ffffffffc02035dc:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc02035de:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc02035e0:	f11c                	sd	a5,32(a0)
}
ffffffffc02035e2:	0141                	addi	sp,sp,16
ffffffffc02035e4:	8082                	ret
            p->property += base->property;
ffffffffc02035e6:	4d1c                	lw	a5,24(a0)
ffffffffc02035e8:	0107883b          	addw	a6,a5,a6
ffffffffc02035ec:	ff05ac23          	sw	a6,-8(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02035f0:	57f5                	li	a5,-3
ffffffffc02035f2:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc02035f6:	02053803          	ld	a6,32(a0)
ffffffffc02035fa:	7518                	ld	a4,40(a0)
            base = p;
ffffffffc02035fc:	8532                	mv	a0,a2
    prev->next = next;
ffffffffc02035fe:	00e83423          	sd	a4,8(a6)
    next->prev = prev;
ffffffffc0203602:	659c                	ld	a5,8(a1)
ffffffffc0203604:	01073023          	sd	a6,0(a4)
ffffffffc0203608:	b765                	j	ffffffffc02035b0 <default_free_pages+0xea>
            base->property += p->property;
ffffffffc020360a:	ff87a703          	lw	a4,-8(a5)
ffffffffc020360e:	fe878693          	addi	a3,a5,-24
ffffffffc0203612:	9db9                	addw	a1,a1,a4
ffffffffc0203614:	cd0c                	sw	a1,24(a0)
ffffffffc0203616:	5775                	li	a4,-3
ffffffffc0203618:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020361c:	6398                	ld	a4,0(a5)
ffffffffc020361e:	679c                	ld	a5,8(a5)
}
ffffffffc0203620:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0203622:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203624:	e398                	sd	a4,0(a5)
ffffffffc0203626:	0141                	addi	sp,sp,16
ffffffffc0203628:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020362a:	00002697          	auipc	a3,0x2
ffffffffc020362e:	74668693          	addi	a3,a3,1862 # ffffffffc0205d70 <commands+0x1908>
ffffffffc0203632:	00002617          	auipc	a2,0x2
ffffffffc0203636:	82660613          	addi	a2,a2,-2010 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc020363a:	0ab00593          	li	a1,171
ffffffffc020363e:	00002517          	auipc	a0,0x2
ffffffffc0203642:	42250513          	addi	a0,a0,1058 # ffffffffc0205a60 <commands+0x15f8>
ffffffffc0203646:	abffc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(n > 0);
ffffffffc020364a:	00002697          	auipc	a3,0x2
ffffffffc020364e:	74e68693          	addi	a3,a3,1870 # ffffffffc0205d98 <commands+0x1930>
ffffffffc0203652:	00002617          	auipc	a2,0x2
ffffffffc0203656:	80660613          	addi	a2,a2,-2042 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc020365a:	0a700593          	li	a1,167
ffffffffc020365e:	00002517          	auipc	a0,0x2
ffffffffc0203662:	40250513          	addi	a0,a0,1026 # ffffffffc0205a60 <commands+0x15f8>
ffffffffc0203666:	a9ffc0ef          	jal	ra,ffffffffc0200104 <__panic>

ffffffffc020366a <default_alloc_pages>:
    assert(n > 0);
ffffffffc020366a:	cd51                	beqz	a0,ffffffffc0203706 <default_alloc_pages+0x9c>
    if (n > nr_free)
ffffffffc020366c:	0000e597          	auipc	a1,0xe
ffffffffc0203670:	f1c58593          	addi	a1,a1,-228 # ffffffffc0211588 <free_area>
ffffffffc0203674:	0105a803          	lw	a6,16(a1)
ffffffffc0203678:	862a                	mv	a2,a0
ffffffffc020367a:	02081793          	slli	a5,a6,0x20
ffffffffc020367e:	9381                	srli	a5,a5,0x20
ffffffffc0203680:	00a7ee63          	bltu	a5,a0,ffffffffc020369c <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc0203684:	87ae                	mv	a5,a1
ffffffffc0203686:	a801                	j	ffffffffc0203696 <default_alloc_pages+0x2c>
        if (p->property >= n)
ffffffffc0203688:	ff87a703          	lw	a4,-8(a5)
ffffffffc020368c:	02071693          	slli	a3,a4,0x20
ffffffffc0203690:	9281                	srli	a3,a3,0x20
ffffffffc0203692:	00c6f763          	bgeu	a3,a2,ffffffffc02036a0 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0203696:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc0203698:	feb798e3          	bne	a5,a1,ffffffffc0203688 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc020369c:	4501                	li	a0,0
}
ffffffffc020369e:	8082                	ret
        struct Page *p = le2page(le, page_link);
ffffffffc02036a0:	fe078513          	addi	a0,a5,-32
    if (page != NULL)
ffffffffc02036a4:	dd6d                	beqz	a0,ffffffffc020369e <default_alloc_pages+0x34>
    return listelm->prev;
ffffffffc02036a6:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02036aa:	0087b303          	ld	t1,8(a5)
    prev->next = next;
ffffffffc02036ae:	00060e1b          	sext.w	t3,a2
ffffffffc02036b2:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc02036b6:	01133023          	sd	a7,0(t1)
        if (page->property > n)
ffffffffc02036ba:	02d67b63          	bgeu	a2,a3,ffffffffc02036f0 <default_alloc_pages+0x86>
            struct Page *p = page + n;
ffffffffc02036be:	00361693          	slli	a3,a2,0x3
ffffffffc02036c2:	96b2                	add	a3,a3,a2
ffffffffc02036c4:	068e                	slli	a3,a3,0x3
ffffffffc02036c6:	96aa                	add	a3,a3,a0
            p->property = page->property - n;
ffffffffc02036c8:	41c7073b          	subw	a4,a4,t3
ffffffffc02036cc:	ce98                	sw	a4,24(a3)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02036ce:	00868613          	addi	a2,a3,8
ffffffffc02036d2:	4709                	li	a4,2
ffffffffc02036d4:	40e6302f          	amoor.d	zero,a4,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc02036d8:	0088b703          	ld	a4,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc02036dc:	02068613          	addi	a2,a3,32
    prev->next = next->prev = elm;
ffffffffc02036e0:	0105a803          	lw	a6,16(a1)
ffffffffc02036e4:	e310                	sd	a2,0(a4)
ffffffffc02036e6:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc02036ea:	f698                	sd	a4,40(a3)
    elm->prev = prev;
ffffffffc02036ec:	0316b023          	sd	a7,32(a3)
        nr_free -= n;
ffffffffc02036f0:	41c8083b          	subw	a6,a6,t3
ffffffffc02036f4:	0000e717          	auipc	a4,0xe
ffffffffc02036f8:	eb072223          	sw	a6,-348(a4) # ffffffffc0211598 <free_area+0x10>
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02036fc:	5775                	li	a4,-3
ffffffffc02036fe:	17a1                	addi	a5,a5,-24
ffffffffc0203700:	60e7b02f          	amoand.d	zero,a4,(a5)
ffffffffc0203704:	8082                	ret
{
ffffffffc0203706:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0203708:	00002697          	auipc	a3,0x2
ffffffffc020370c:	69068693          	addi	a3,a3,1680 # ffffffffc0205d98 <commands+0x1930>
ffffffffc0203710:	00001617          	auipc	a2,0x1
ffffffffc0203714:	74860613          	addi	a2,a2,1864 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0203718:	08300593          	li	a1,131
ffffffffc020371c:	00002517          	auipc	a0,0x2
ffffffffc0203720:	34450513          	addi	a0,a0,836 # ffffffffc0205a60 <commands+0x15f8>
{
ffffffffc0203724:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0203726:	9dffc0ef          	jal	ra,ffffffffc0200104 <__panic>

ffffffffc020372a <default_init_memmap>:
{
ffffffffc020372a:	7179                	addi	sp,sp,-48
ffffffffc020372c:	f406                	sd	ra,40(sp)
ffffffffc020372e:	f022                	sd	s0,32(sp)
ffffffffc0203730:	ec26                	sd	s1,24(sp)
ffffffffc0203732:	e84a                	sd	s2,16(sp)
ffffffffc0203734:	e44e                	sd	s3,8(sp)
ffffffffc0203736:	e052                	sd	s4,0(sp)
    assert(n > 0);
ffffffffc0203738:	12058563          	beqz	a1,ffffffffc0203862 <default_init_memmap+0x138>
ffffffffc020373c:	892e                	mv	s2,a1
ffffffffc020373e:	842a                	mv	s0,a0
    for (; p != base + 3; p++)
ffffffffc0203740:	0d850a13          	addi	s4,a0,216
ffffffffc0203744:	84aa                	mv	s1,a0
        cprintf("p的虚拟地址: 0x%016lx.\n", (uintptr_t)p);
ffffffffc0203746:	00002997          	auipc	s3,0x2
ffffffffc020374a:	65a98993          	addi	s3,s3,1626 # ffffffffc0205da0 <commands+0x1938>
ffffffffc020374e:	85a6                	mv	a1,s1
ffffffffc0203750:	854e                	mv	a0,s3
    for (; p != base + 3; p++)
ffffffffc0203752:	04848493          	addi	s1,s1,72
        cprintf("p的虚拟地址: 0x%016lx.\n", (uintptr_t)p);
ffffffffc0203756:	969fc0ef          	jal	ra,ffffffffc02000be <cprintf>
    for (; p != base + 3; p++)
ffffffffc020375a:	ff449ae3          	bne	s1,s4,ffffffffc020374e <default_init_memmap+0x24>
    for (; p != base + n; p++)
ffffffffc020375e:	00391693          	slli	a3,s2,0x3
ffffffffc0203762:	96ca                	add	a3,a3,s2
ffffffffc0203764:	068e                	slli	a3,a3,0x3
ffffffffc0203766:	96a2                	add	a3,a3,s0
ffffffffc0203768:	02d40463          	beq	s0,a3,ffffffffc0203790 <default_init_memmap+0x66>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020376c:	6418                	ld	a4,8(s0)
        assert(PageReserved(p));
ffffffffc020376e:	87a2                	mv	a5,s0
ffffffffc0203770:	8b05                	andi	a4,a4,1
ffffffffc0203772:	e709                	bnez	a4,ffffffffc020377c <default_init_memmap+0x52>
ffffffffc0203774:	a0f9                	j	ffffffffc0203842 <default_init_memmap+0x118>
ffffffffc0203776:	6798                	ld	a4,8(a5)
ffffffffc0203778:	8b05                	andi	a4,a4,1
ffffffffc020377a:	c761                	beqz	a4,ffffffffc0203842 <default_init_memmap+0x118>
        p->flags = p->property = 0;
ffffffffc020377c:	0007ac23          	sw	zero,24(a5)
ffffffffc0203780:	0007b423          	sd	zero,8(a5)
ffffffffc0203784:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0203788:	04878793          	addi	a5,a5,72
ffffffffc020378c:	fed795e3          	bne	a5,a3,ffffffffc0203776 <default_init_memmap+0x4c>
    base->property = n;
ffffffffc0203790:	2901                	sext.w	s2,s2
ffffffffc0203792:	01242c23          	sw	s2,24(s0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0203796:	4789                	li	a5,2
ffffffffc0203798:	00840713          	addi	a4,s0,8
ffffffffc020379c:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02037a0:	0000e697          	auipc	a3,0xe
ffffffffc02037a4:	de868693          	addi	a3,a3,-536 # ffffffffc0211588 <free_area>
ffffffffc02037a8:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02037aa:	669c                	ld	a5,8(a3)
ffffffffc02037ac:	0127093b          	addw	s2,a4,s2
ffffffffc02037b0:	0000e717          	auipc	a4,0xe
ffffffffc02037b4:	df272423          	sw	s2,-536(a4) # ffffffffc0211598 <free_area+0x10>
    if (list_empty(&free_list))
ffffffffc02037b8:	04d78e63          	beq	a5,a3,ffffffffc0203814 <default_init_memmap+0xea>
            struct Page *page = le2page(le, page_link);
ffffffffc02037bc:	fe078713          	addi	a4,a5,-32
ffffffffc02037c0:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list))
ffffffffc02037c2:	4501                	li	a0,0
ffffffffc02037c4:	02040613          	addi	a2,s0,32
            if (base < page)
ffffffffc02037c8:	00e46a63          	bltu	s0,a4,ffffffffc02037dc <default_init_memmap+0xb2>
    return listelm->next;
ffffffffc02037cc:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02037ce:	02d70963          	beq	a4,a3,ffffffffc0203800 <default_init_memmap+0xd6>
        while ((le = list_next(le)) != &free_list)
ffffffffc02037d2:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02037d4:	fe078713          	addi	a4,a5,-32
            if (base < page)
ffffffffc02037d8:	fee47ae3          	bgeu	s0,a4,ffffffffc02037cc <default_init_memmap+0xa2>
ffffffffc02037dc:	c509                	beqz	a0,ffffffffc02037e6 <default_init_memmap+0xbc>
ffffffffc02037de:	0000e717          	auipc	a4,0xe
ffffffffc02037e2:	dab73523          	sd	a1,-598(a4) # ffffffffc0211588 <free_area>
    __list_add(elm, listelm->prev, listelm);
ffffffffc02037e6:	6398                	ld	a4,0(a5)
    prev->next = next->prev = elm;
ffffffffc02037e8:	e390                	sd	a2,0(a5)
}
ffffffffc02037ea:	70a2                	ld	ra,40(sp)
ffffffffc02037ec:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02037ee:	f41c                	sd	a5,40(s0)
    elm->prev = prev;
ffffffffc02037f0:	f018                	sd	a4,32(s0)
ffffffffc02037f2:	7402                	ld	s0,32(sp)
ffffffffc02037f4:	64e2                	ld	s1,24(sp)
ffffffffc02037f6:	6942                	ld	s2,16(sp)
ffffffffc02037f8:	69a2                	ld	s3,8(sp)
ffffffffc02037fa:	6a02                	ld	s4,0(sp)
ffffffffc02037fc:	6145                	addi	sp,sp,48
ffffffffc02037fe:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0203800:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0203802:	f414                	sd	a3,40(s0)
ffffffffc0203804:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0203806:	f01c                	sd	a5,32(s0)
                list_add(le, &(base->page_link));
ffffffffc0203808:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list)
ffffffffc020380a:	02d70363          	beq	a4,a3,ffffffffc0203830 <default_init_memmap+0x106>
ffffffffc020380e:	4505                	li	a0,1
ffffffffc0203810:	87ba                	mv	a5,a4
ffffffffc0203812:	b7c9                	j	ffffffffc02037d4 <default_init_memmap+0xaa>
        list_add(&free_list, &(base->page_link));
ffffffffc0203814:	02040713          	addi	a4,s0,32
    elm->next = next;
ffffffffc0203818:	f41c                	sd	a5,40(s0)
    elm->prev = prev;
ffffffffc020381a:	f01c                	sd	a5,32(s0)
}
ffffffffc020381c:	70a2                	ld	ra,40(sp)
ffffffffc020381e:	7402                	ld	s0,32(sp)
    prev->next = next->prev = elm;
ffffffffc0203820:	e398                	sd	a4,0(a5)
ffffffffc0203822:	e798                	sd	a4,8(a5)
ffffffffc0203824:	64e2                	ld	s1,24(sp)
ffffffffc0203826:	6942                	ld	s2,16(sp)
ffffffffc0203828:	69a2                	ld	s3,8(sp)
ffffffffc020382a:	6a02                	ld	s4,0(sp)
ffffffffc020382c:	6145                	addi	sp,sp,48
ffffffffc020382e:	8082                	ret
ffffffffc0203830:	70a2                	ld	ra,40(sp)
ffffffffc0203832:	7402                	ld	s0,32(sp)
ffffffffc0203834:	e290                	sd	a2,0(a3)
ffffffffc0203836:	64e2                	ld	s1,24(sp)
ffffffffc0203838:	6942                	ld	s2,16(sp)
ffffffffc020383a:	69a2                	ld	s3,8(sp)
ffffffffc020383c:	6a02                	ld	s4,0(sp)
ffffffffc020383e:	6145                	addi	sp,sp,48
ffffffffc0203840:	8082                	ret
        assert(PageReserved(p));
ffffffffc0203842:	00002697          	auipc	a3,0x2
ffffffffc0203846:	57e68693          	addi	a3,a3,1406 # ffffffffc0205dc0 <commands+0x1958>
ffffffffc020384a:	00001617          	auipc	a2,0x1
ffffffffc020384e:	60e60613          	addi	a2,a2,1550 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0203852:	05900593          	li	a1,89
ffffffffc0203856:	00002517          	auipc	a0,0x2
ffffffffc020385a:	20a50513          	addi	a0,a0,522 # ffffffffc0205a60 <commands+0x15f8>
ffffffffc020385e:	8a7fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(n > 0);
ffffffffc0203862:	00002697          	auipc	a3,0x2
ffffffffc0203866:	53668693          	addi	a3,a3,1334 # ffffffffc0205d98 <commands+0x1930>
ffffffffc020386a:	00001617          	auipc	a2,0x1
ffffffffc020386e:	5ee60613          	addi	a2,a2,1518 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0203872:	04a00593          	li	a1,74
ffffffffc0203876:	00002517          	auipc	a0,0x2
ffffffffc020387a:	1ea50513          	addi	a0,a0,490 # ffffffffc0205a60 <commands+0x15f8>
ffffffffc020387e:	887fc0ef          	jal	ra,ffffffffc0200104 <__panic>

ffffffffc0203882 <_clock_init_mm>:
    elm->prev = elm->next = elm;
ffffffffc0203882:	0000e797          	auipc	a5,0xe
ffffffffc0203886:	bfe78793          	addi	a5,a5,-1026 # ffffffffc0211480 <pra_list_head>
    // 初始化pra_list_head为空链表
    list_init(&pra_list_head);
    // 初始化当前指针curr_ptr指向pra_list_head，表示当前页面替换位置为链表头
    curr_ptr = &pra_list_head;
    // 将mm的私有成员指针指向pra_list_head，用于后续的页面替换算法操作
    mm->sm_priv = &pra_list_head;
ffffffffc020388a:	f51c                	sd	a5,40(a0)
ffffffffc020388c:	e79c                	sd	a5,8(a5)
ffffffffc020388e:	e39c                	sd	a5,0(a5)
    curr_ptr = &pra_list_head;
ffffffffc0203890:	0000e717          	auipc	a4,0xe
ffffffffc0203894:	c0f73023          	sd	a5,-1024(a4) # ffffffffc0211490 <curr_ptr>
    // cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
    return 0;
}
ffffffffc0203898:	4501                	li	a0,0
ffffffffc020389a:	8082                	ret

ffffffffc020389c <_clock_init>:

static int
_clock_init(void)
{
    return 0;
}
ffffffffc020389c:	4501                	li	a0,0
ffffffffc020389e:	8082                	ret

ffffffffc02038a0 <_clock_set_unswappable>:

static int
_clock_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}
ffffffffc02038a0:	4501                	li	a0,0
ffffffffc02038a2:	8082                	ret

ffffffffc02038a4 <_clock_tick_event>:

static int
_clock_tick_event(struct mm_struct *mm)
{
    return 0;
}
ffffffffc02038a4:	4501                	li	a0,0
ffffffffc02038a6:	8082                	ret

ffffffffc02038a8 <_clock_check_swap>:
{
ffffffffc02038a8:	1141                	addi	sp,sp,-16
    cprintf("into check clock swap\n");
ffffffffc02038aa:	00002517          	auipc	a0,0x2
ffffffffc02038ae:	57650513          	addi	a0,a0,1398 # ffffffffc0205e20 <default_pmm_manager+0x50>
{
ffffffffc02038b2:	e406                	sd	ra,8(sp)
    cprintf("into check clock swap\n");
ffffffffc02038b4:	80bfc0ef          	jal	ra,ffffffffc02000be <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc02038b8:	678d                	lui	a5,0x3
ffffffffc02038ba:	4731                	li	a4,12
ffffffffc02038bc:	00e78023          	sb	a4,0(a5) # 3000 <BASE_ADDRESS-0xffffffffc01fd000>
    assert(pgfault_num == 4);
ffffffffc02038c0:	0000e797          	auipc	a5,0xe
ffffffffc02038c4:	ba078793          	addi	a5,a5,-1120 # ffffffffc0211460 <pgfault_num>
ffffffffc02038c8:	4398                	lw	a4,0(a5)
ffffffffc02038ca:	4691                	li	a3,4
ffffffffc02038cc:	2701                	sext.w	a4,a4
ffffffffc02038ce:	0ad71563          	bne	a4,a3,ffffffffc0203978 <_clock_check_swap+0xd0>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc02038d2:	6685                	lui	a3,0x1
ffffffffc02038d4:	4629                	li	a2,10
ffffffffc02038d6:	00c68023          	sb	a2,0(a3) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
    assert(pgfault_num == 4);
ffffffffc02038da:	4394                	lw	a3,0(a5)
ffffffffc02038dc:	2681                	sext.w	a3,a3
ffffffffc02038de:	20e69d63          	bne	a3,a4,ffffffffc0203af8 <_clock_check_swap+0x250>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc02038e2:	6711                	lui	a4,0x4
ffffffffc02038e4:	4635                	li	a2,13
ffffffffc02038e6:	00c70023          	sb	a2,0(a4) # 4000 <BASE_ADDRESS-0xffffffffc01fc000>
    assert(pgfault_num == 4);
ffffffffc02038ea:	4398                	lw	a4,0(a5)
ffffffffc02038ec:	2701                	sext.w	a4,a4
ffffffffc02038ee:	1ed71563          	bne	a4,a3,ffffffffc0203ad8 <_clock_check_swap+0x230>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc02038f2:	6689                	lui	a3,0x2
ffffffffc02038f4:	462d                	li	a2,11
ffffffffc02038f6:	00c68023          	sb	a2,0(a3) # 2000 <BASE_ADDRESS-0xffffffffc01fe000>
    assert(pgfault_num == 4);
ffffffffc02038fa:	4394                	lw	a3,0(a5)
ffffffffc02038fc:	2681                	sext.w	a3,a3
ffffffffc02038fe:	1ae69d63          	bne	a3,a4,ffffffffc0203ab8 <_clock_check_swap+0x210>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0203902:	6715                	lui	a4,0x5
ffffffffc0203904:	46b9                	li	a3,14
ffffffffc0203906:	00d70023          	sb	a3,0(a4) # 5000 <BASE_ADDRESS-0xffffffffc01fb000>
    assert(pgfault_num == 5);
ffffffffc020390a:	4398                	lw	a4,0(a5)
ffffffffc020390c:	4695                	li	a3,5
ffffffffc020390e:	2701                	sext.w	a4,a4
ffffffffc0203910:	18d71463          	bne	a4,a3,ffffffffc0203a98 <_clock_check_swap+0x1f0>
    assert(pgfault_num == 5);
ffffffffc0203914:	4394                	lw	a3,0(a5)
ffffffffc0203916:	2681                	sext.w	a3,a3
ffffffffc0203918:	16e69063          	bne	a3,a4,ffffffffc0203a78 <_clock_check_swap+0x1d0>
    assert(pgfault_num == 5);
ffffffffc020391c:	4398                	lw	a4,0(a5)
ffffffffc020391e:	2701                	sext.w	a4,a4
ffffffffc0203920:	12d71c63          	bne	a4,a3,ffffffffc0203a58 <_clock_check_swap+0x1b0>
    assert(pgfault_num == 5);
ffffffffc0203924:	4394                	lw	a3,0(a5)
ffffffffc0203926:	2681                	sext.w	a3,a3
ffffffffc0203928:	10e69863          	bne	a3,a4,ffffffffc0203a38 <_clock_check_swap+0x190>
    assert(pgfault_num == 5);
ffffffffc020392c:	4398                	lw	a4,0(a5)
ffffffffc020392e:	2701                	sext.w	a4,a4
ffffffffc0203930:	0ed71463          	bne	a4,a3,ffffffffc0203a18 <_clock_check_swap+0x170>
    assert(pgfault_num == 5);
ffffffffc0203934:	4394                	lw	a3,0(a5)
ffffffffc0203936:	2681                	sext.w	a3,a3
ffffffffc0203938:	0ce69063          	bne	a3,a4,ffffffffc02039f8 <_clock_check_swap+0x150>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc020393c:	6715                	lui	a4,0x5
ffffffffc020393e:	46b9                	li	a3,14
ffffffffc0203940:	00d70023          	sb	a3,0(a4) # 5000 <BASE_ADDRESS-0xffffffffc01fb000>
    assert(pgfault_num == 5);
ffffffffc0203944:	4398                	lw	a4,0(a5)
ffffffffc0203946:	4695                	li	a3,5
ffffffffc0203948:	2701                	sext.w	a4,a4
ffffffffc020394a:	08d71763          	bne	a4,a3,ffffffffc02039d8 <_clock_check_swap+0x130>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc020394e:	6705                	lui	a4,0x1
ffffffffc0203950:	00074683          	lbu	a3,0(a4) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
ffffffffc0203954:	4729                	li	a4,10
ffffffffc0203956:	06e69163          	bne	a3,a4,ffffffffc02039b8 <_clock_check_swap+0x110>
    assert(pgfault_num == 6);
ffffffffc020395a:	439c                	lw	a5,0(a5)
ffffffffc020395c:	4719                	li	a4,6
ffffffffc020395e:	2781                	sext.w	a5,a5
ffffffffc0203960:	02e79c63          	bne	a5,a4,ffffffffc0203998 <_clock_check_swap+0xf0>
    cprintf("end check clock swap\n");
ffffffffc0203964:	00002517          	auipc	a0,0x2
ffffffffc0203968:	54450513          	addi	a0,a0,1348 # ffffffffc0205ea8 <default_pmm_manager+0xd8>
ffffffffc020396c:	f52fc0ef          	jal	ra,ffffffffc02000be <cprintf>
}
ffffffffc0203970:	60a2                	ld	ra,8(sp)
ffffffffc0203972:	4501                	li	a0,0
ffffffffc0203974:	0141                	addi	sp,sp,16
ffffffffc0203976:	8082                	ret
    assert(pgfault_num == 4);
ffffffffc0203978:	00002697          	auipc	a3,0x2
ffffffffc020397c:	f5068693          	addi	a3,a3,-176 # ffffffffc02058c8 <commands+0x1460>
ffffffffc0203980:	00001617          	auipc	a2,0x1
ffffffffc0203984:	4d860613          	addi	a2,a2,1240 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0203988:	09600593          	li	a1,150
ffffffffc020398c:	00002517          	auipc	a0,0x2
ffffffffc0203990:	4ac50513          	addi	a0,a0,1196 # ffffffffc0205e38 <default_pmm_manager+0x68>
ffffffffc0203994:	f70fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(pgfault_num == 6);
ffffffffc0203998:	00002697          	auipc	a3,0x2
ffffffffc020399c:	4f868693          	addi	a3,a3,1272 # ffffffffc0205e90 <default_pmm_manager+0xc0>
ffffffffc02039a0:	00001617          	auipc	a2,0x1
ffffffffc02039a4:	4b860613          	addi	a2,a2,1208 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc02039a8:	0ad00593          	li	a1,173
ffffffffc02039ac:	00002517          	auipc	a0,0x2
ffffffffc02039b0:	48c50513          	addi	a0,a0,1164 # ffffffffc0205e38 <default_pmm_manager+0x68>
ffffffffc02039b4:	f50fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc02039b8:	00002697          	auipc	a3,0x2
ffffffffc02039bc:	4b068693          	addi	a3,a3,1200 # ffffffffc0205e68 <default_pmm_manager+0x98>
ffffffffc02039c0:	00001617          	auipc	a2,0x1
ffffffffc02039c4:	49860613          	addi	a2,a2,1176 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc02039c8:	0ab00593          	li	a1,171
ffffffffc02039cc:	00002517          	auipc	a0,0x2
ffffffffc02039d0:	46c50513          	addi	a0,a0,1132 # ffffffffc0205e38 <default_pmm_manager+0x68>
ffffffffc02039d4:	f30fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(pgfault_num == 5);
ffffffffc02039d8:	00002697          	auipc	a3,0x2
ffffffffc02039dc:	47868693          	addi	a3,a3,1144 # ffffffffc0205e50 <default_pmm_manager+0x80>
ffffffffc02039e0:	00001617          	auipc	a2,0x1
ffffffffc02039e4:	47860613          	addi	a2,a2,1144 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc02039e8:	0aa00593          	li	a1,170
ffffffffc02039ec:	00002517          	auipc	a0,0x2
ffffffffc02039f0:	44c50513          	addi	a0,a0,1100 # ffffffffc0205e38 <default_pmm_manager+0x68>
ffffffffc02039f4:	f10fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(pgfault_num == 5);
ffffffffc02039f8:	00002697          	auipc	a3,0x2
ffffffffc02039fc:	45868693          	addi	a3,a3,1112 # ffffffffc0205e50 <default_pmm_manager+0x80>
ffffffffc0203a00:	00001617          	auipc	a2,0x1
ffffffffc0203a04:	45860613          	addi	a2,a2,1112 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0203a08:	0a800593          	li	a1,168
ffffffffc0203a0c:	00002517          	auipc	a0,0x2
ffffffffc0203a10:	42c50513          	addi	a0,a0,1068 # ffffffffc0205e38 <default_pmm_manager+0x68>
ffffffffc0203a14:	ef0fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(pgfault_num == 5);
ffffffffc0203a18:	00002697          	auipc	a3,0x2
ffffffffc0203a1c:	43868693          	addi	a3,a3,1080 # ffffffffc0205e50 <default_pmm_manager+0x80>
ffffffffc0203a20:	00001617          	auipc	a2,0x1
ffffffffc0203a24:	43860613          	addi	a2,a2,1080 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0203a28:	0a600593          	li	a1,166
ffffffffc0203a2c:	00002517          	auipc	a0,0x2
ffffffffc0203a30:	40c50513          	addi	a0,a0,1036 # ffffffffc0205e38 <default_pmm_manager+0x68>
ffffffffc0203a34:	ed0fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(pgfault_num == 5);
ffffffffc0203a38:	00002697          	auipc	a3,0x2
ffffffffc0203a3c:	41868693          	addi	a3,a3,1048 # ffffffffc0205e50 <default_pmm_manager+0x80>
ffffffffc0203a40:	00001617          	auipc	a2,0x1
ffffffffc0203a44:	41860613          	addi	a2,a2,1048 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0203a48:	0a400593          	li	a1,164
ffffffffc0203a4c:	00002517          	auipc	a0,0x2
ffffffffc0203a50:	3ec50513          	addi	a0,a0,1004 # ffffffffc0205e38 <default_pmm_manager+0x68>
ffffffffc0203a54:	eb0fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(pgfault_num == 5);
ffffffffc0203a58:	00002697          	auipc	a3,0x2
ffffffffc0203a5c:	3f868693          	addi	a3,a3,1016 # ffffffffc0205e50 <default_pmm_manager+0x80>
ffffffffc0203a60:	00001617          	auipc	a2,0x1
ffffffffc0203a64:	3f860613          	addi	a2,a2,1016 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0203a68:	0a200593          	li	a1,162
ffffffffc0203a6c:	00002517          	auipc	a0,0x2
ffffffffc0203a70:	3cc50513          	addi	a0,a0,972 # ffffffffc0205e38 <default_pmm_manager+0x68>
ffffffffc0203a74:	e90fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(pgfault_num == 5);
ffffffffc0203a78:	00002697          	auipc	a3,0x2
ffffffffc0203a7c:	3d868693          	addi	a3,a3,984 # ffffffffc0205e50 <default_pmm_manager+0x80>
ffffffffc0203a80:	00001617          	auipc	a2,0x1
ffffffffc0203a84:	3d860613          	addi	a2,a2,984 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0203a88:	0a000593          	li	a1,160
ffffffffc0203a8c:	00002517          	auipc	a0,0x2
ffffffffc0203a90:	3ac50513          	addi	a0,a0,940 # ffffffffc0205e38 <default_pmm_manager+0x68>
ffffffffc0203a94:	e70fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(pgfault_num == 5);
ffffffffc0203a98:	00002697          	auipc	a3,0x2
ffffffffc0203a9c:	3b868693          	addi	a3,a3,952 # ffffffffc0205e50 <default_pmm_manager+0x80>
ffffffffc0203aa0:	00001617          	auipc	a2,0x1
ffffffffc0203aa4:	3b860613          	addi	a2,a2,952 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0203aa8:	09e00593          	li	a1,158
ffffffffc0203aac:	00002517          	auipc	a0,0x2
ffffffffc0203ab0:	38c50513          	addi	a0,a0,908 # ffffffffc0205e38 <default_pmm_manager+0x68>
ffffffffc0203ab4:	e50fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(pgfault_num == 4);
ffffffffc0203ab8:	00002697          	auipc	a3,0x2
ffffffffc0203abc:	e1068693          	addi	a3,a3,-496 # ffffffffc02058c8 <commands+0x1460>
ffffffffc0203ac0:	00001617          	auipc	a2,0x1
ffffffffc0203ac4:	39860613          	addi	a2,a2,920 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0203ac8:	09c00593          	li	a1,156
ffffffffc0203acc:	00002517          	auipc	a0,0x2
ffffffffc0203ad0:	36c50513          	addi	a0,a0,876 # ffffffffc0205e38 <default_pmm_manager+0x68>
ffffffffc0203ad4:	e30fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(pgfault_num == 4);
ffffffffc0203ad8:	00002697          	auipc	a3,0x2
ffffffffc0203adc:	df068693          	addi	a3,a3,-528 # ffffffffc02058c8 <commands+0x1460>
ffffffffc0203ae0:	00001617          	auipc	a2,0x1
ffffffffc0203ae4:	37860613          	addi	a2,a2,888 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0203ae8:	09a00593          	li	a1,154
ffffffffc0203aec:	00002517          	auipc	a0,0x2
ffffffffc0203af0:	34c50513          	addi	a0,a0,844 # ffffffffc0205e38 <default_pmm_manager+0x68>
ffffffffc0203af4:	e10fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(pgfault_num == 4);
ffffffffc0203af8:	00002697          	auipc	a3,0x2
ffffffffc0203afc:	dd068693          	addi	a3,a3,-560 # ffffffffc02058c8 <commands+0x1460>
ffffffffc0203b00:	00001617          	auipc	a2,0x1
ffffffffc0203b04:	35860613          	addi	a2,a2,856 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0203b08:	09800593          	li	a1,152
ffffffffc0203b0c:	00002517          	auipc	a0,0x2
ffffffffc0203b10:	32c50513          	addi	a0,a0,812 # ffffffffc0205e38 <default_pmm_manager+0x68>
ffffffffc0203b14:	df0fc0ef          	jal	ra,ffffffffc0200104 <__panic>

ffffffffc0203b18 <_clock_swap_out_victim>:
    list_entry_t *head = (list_entry_t *)mm->sm_priv;
ffffffffc0203b18:	7514                	ld	a3,40(a0)
{
ffffffffc0203b1a:	1101                	addi	sp,sp,-32
ffffffffc0203b1c:	ec06                	sd	ra,24(sp)
ffffffffc0203b1e:	e822                	sd	s0,16(sp)
ffffffffc0203b20:	e426                	sd	s1,8(sp)
ffffffffc0203b22:	e04a                	sd	s2,0(sp)
    assert(head != NULL);
ffffffffc0203b24:	cead                	beqz	a3,ffffffffc0203b9e <_clock_swap_out_victim+0x86>
    assert(in_tick == 0);
ffffffffc0203b26:	ee41                	bnez	a2,ffffffffc0203bbe <_clock_swap_out_victim+0xa6>
    if (list_empty(head))
ffffffffc0203b28:	669c                	ld	a5,8(a3)
ffffffffc0203b2a:	06f68363          	beq	a3,a5,ffffffffc0203b90 <_clock_swap_out_victim+0x78>
ffffffffc0203b2e:	0000e497          	auipc	s1,0xe
ffffffffc0203b32:	96248493          	addi	s1,s1,-1694 # ffffffffc0211490 <curr_ptr>
ffffffffc0203b36:	892e                	mv	s2,a1
ffffffffc0203b38:	6080                	ld	s0,0(s1)
ffffffffc0203b3a:	4601                	li	a2,0
ffffffffc0203b3c:	a801                	j	ffffffffc0203b4c <_clock_swap_out_victim+0x34>
        if (page->visited == 0)
ffffffffc0203b3e:	fe043703          	ld	a4,-32(s0)
ffffffffc0203b42:	cf11                	beqz	a4,ffffffffc0203b5e <_clock_swap_out_victim+0x46>
            page->visited = 0;
ffffffffc0203b44:	fe043023          	sd	zero,-32(s0)
    return listelm->prev;
ffffffffc0203b48:	4605                	li	a2,1
ffffffffc0203b4a:	843e                	mv	s0,a5
        if (head == curr_ptr)
ffffffffc0203b4c:	601c                	ld	a5,0(s0)
ffffffffc0203b4e:	fed418e3          	bne	s0,a3,ffffffffc0203b3e <_clock_swap_out_victim+0x26>
ffffffffc0203b52:	843e                	mv	s0,a5
        if (page->visited == 0)
ffffffffc0203b54:	fe043703          	ld	a4,-32(s0)
        if (head == curr_ptr)
ffffffffc0203b58:	639c                	ld	a5,0(a5)
ffffffffc0203b5a:	4605                	li	a2,1
        if (page->visited == 0)
ffffffffc0203b5c:	f765                	bnez	a4,ffffffffc0203b44 <_clock_swap_out_victim+0x2c>
ffffffffc0203b5e:	c609                	beqz	a2,ffffffffc0203b68 <_clock_swap_out_victim+0x50>
ffffffffc0203b60:	0000e717          	auipc	a4,0xe
ffffffffc0203b64:	92873823          	sd	s0,-1744(a4) # ffffffffc0211490 <curr_ptr>
    __list_del(listelm->prev, listelm->next);
ffffffffc0203b68:	6418                	ld	a4,8(s0)
            cprintf("curr_ptr: %p\n", curr_ptr);
ffffffffc0203b6a:	85a2                	mv	a1,s0
ffffffffc0203b6c:	00002517          	auipc	a0,0x2
ffffffffc0203b70:	39c50513          	addi	a0,a0,924 # ffffffffc0205f08 <default_pmm_manager+0x138>
    prev->next = next;
ffffffffc0203b74:	e798                	sd	a4,8(a5)
    next->prev = prev;
ffffffffc0203b76:	e31c                	sd	a5,0(a4)
ffffffffc0203b78:	d46fc0ef          	jal	ra,ffffffffc02000be <cprintf>
    return listelm->prev;
ffffffffc0203b7c:	609c                	ld	a5,0(s1)
        page = le2page(curr_ptr, pra_page_link);
ffffffffc0203b7e:	fd040413          	addi	s0,s0,-48
            curr_ptr = list_prev(curr_ptr);
ffffffffc0203b82:	639c                	ld	a5,0(a5)
ffffffffc0203b84:	0000e717          	auipc	a4,0xe
ffffffffc0203b88:	90f73623          	sd	a5,-1780(a4) # ffffffffc0211490 <curr_ptr>
            *ptr_page = page;
ffffffffc0203b8c:	00893023          	sd	s0,0(s2)
}
ffffffffc0203b90:	60e2                	ld	ra,24(sp)
ffffffffc0203b92:	6442                	ld	s0,16(sp)
ffffffffc0203b94:	64a2                	ld	s1,8(sp)
ffffffffc0203b96:	6902                	ld	s2,0(sp)
ffffffffc0203b98:	4501                	li	a0,0
ffffffffc0203b9a:	6105                	addi	sp,sp,32
ffffffffc0203b9c:	8082                	ret
    assert(head != NULL);
ffffffffc0203b9e:	00002697          	auipc	a3,0x2
ffffffffc0203ba2:	34a68693          	addi	a3,a3,842 # ffffffffc0205ee8 <default_pmm_manager+0x118>
ffffffffc0203ba6:	00001617          	auipc	a2,0x1
ffffffffc0203baa:	2b260613          	addi	a2,a2,690 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0203bae:	04200593          	li	a1,66
ffffffffc0203bb2:	00002517          	auipc	a0,0x2
ffffffffc0203bb6:	28650513          	addi	a0,a0,646 # ffffffffc0205e38 <default_pmm_manager+0x68>
ffffffffc0203bba:	d4afc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(in_tick == 0);
ffffffffc0203bbe:	00002697          	auipc	a3,0x2
ffffffffc0203bc2:	33a68693          	addi	a3,a3,826 # ffffffffc0205ef8 <default_pmm_manager+0x128>
ffffffffc0203bc6:	00001617          	auipc	a2,0x1
ffffffffc0203bca:	29260613          	addi	a2,a2,658 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0203bce:	04300593          	li	a1,67
ffffffffc0203bd2:	00002517          	auipc	a0,0x2
ffffffffc0203bd6:	26650513          	addi	a0,a0,614 # ffffffffc0205e38 <default_pmm_manager+0x68>
ffffffffc0203bda:	d2afc0ef          	jal	ra,ffffffffc0200104 <__panic>

ffffffffc0203bde <_clock_map_swappable>:
    list_entry_t *entry = &(page->pra_page_link);
ffffffffc0203bde:	03060713          	addi	a4,a2,48
    assert(entry != NULL && curr_ptr != NULL);
ffffffffc0203be2:	c305                	beqz	a4,ffffffffc0203c02 <_clock_map_swappable+0x24>
ffffffffc0203be4:	0000e797          	auipc	a5,0xe
ffffffffc0203be8:	8ac78793          	addi	a5,a5,-1876 # ffffffffc0211490 <curr_ptr>
ffffffffc0203bec:	639c                	ld	a5,0(a5)
ffffffffc0203bee:	cb91                	beqz	a5,ffffffffc0203c02 <_clock_map_swappable+0x24>
    __list_add(elm, listelm, listelm->next);
ffffffffc0203bf0:	6794                	ld	a3,8(a5)
}
ffffffffc0203bf2:	4501                	li	a0,0
    prev->next = next->prev = elm;
ffffffffc0203bf4:	e298                	sd	a4,0(a3)
ffffffffc0203bf6:	e798                	sd	a4,8(a5)
    elm->prev = prev;
ffffffffc0203bf8:	fa1c                	sd	a5,48(a2)
    page->visited = 1;
ffffffffc0203bfa:	4785                	li	a5,1
    elm->next = next;
ffffffffc0203bfc:	fe14                	sd	a3,56(a2)
ffffffffc0203bfe:	ea1c                	sd	a5,16(a2)
}
ffffffffc0203c00:	8082                	ret
{
ffffffffc0203c02:	1141                	addi	sp,sp,-16
    assert(entry != NULL && curr_ptr != NULL);
ffffffffc0203c04:	00002697          	auipc	a3,0x2
ffffffffc0203c08:	2bc68693          	addi	a3,a3,700 # ffffffffc0205ec0 <default_pmm_manager+0xf0>
ffffffffc0203c0c:	00001617          	auipc	a2,0x1
ffffffffc0203c10:	24c60613          	addi	a2,a2,588 # ffffffffc0204e58 <commands+0x9f0>
ffffffffc0203c14:	03100593          	li	a1,49
ffffffffc0203c18:	00002517          	auipc	a0,0x2
ffffffffc0203c1c:	22050513          	addi	a0,a0,544 # ffffffffc0205e38 <default_pmm_manager+0x68>
{
ffffffffc0203c20:	e406                	sd	ra,8(sp)
    assert(entry != NULL && curr_ptr != NULL);
ffffffffc0203c22:	ce2fc0ef          	jal	ra,ffffffffc0200104 <__panic>

ffffffffc0203c26 <swapfs_init>:
#include <ide.h>
#include <pmm.h>
#include <assert.h>

void
swapfs_init(void) {
ffffffffc0203c26:	1141                	addi	sp,sp,-16
    static_assert((PGSIZE % SECTSIZE) == 0);
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0203c28:	4505                	li	a0,1
swapfs_init(void) {
ffffffffc0203c2a:	e406                	sd	ra,8(sp)
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0203c2c:	fa6fc0ef          	jal	ra,ffffffffc02003d2 <ide_device_valid>
ffffffffc0203c30:	cd01                	beqz	a0,ffffffffc0203c48 <swapfs_init+0x22>
        panic("swap fs isn't available.\n");
    }
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0203c32:	4505                	li	a0,1
ffffffffc0203c34:	fa4fc0ef          	jal	ra,ffffffffc02003d8 <ide_device_size>
}
ffffffffc0203c38:	60a2                	ld	ra,8(sp)
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0203c3a:	810d                	srli	a0,a0,0x3
ffffffffc0203c3c:	0000e797          	auipc	a5,0xe
ffffffffc0203c40:	90a7b623          	sd	a0,-1780(a5) # ffffffffc0211548 <max_swap_offset>
}
ffffffffc0203c44:	0141                	addi	sp,sp,16
ffffffffc0203c46:	8082                	ret
        panic("swap fs isn't available.\n");
ffffffffc0203c48:	00002617          	auipc	a2,0x2
ffffffffc0203c4c:	2e860613          	addi	a2,a2,744 # ffffffffc0205f30 <default_pmm_manager+0x160>
ffffffffc0203c50:	45b5                	li	a1,13
ffffffffc0203c52:	00002517          	auipc	a0,0x2
ffffffffc0203c56:	2fe50513          	addi	a0,a0,766 # ffffffffc0205f50 <default_pmm_manager+0x180>
ffffffffc0203c5a:	caafc0ef          	jal	ra,ffffffffc0200104 <__panic>

ffffffffc0203c5e <swapfs_read>:

int
swapfs_read(swap_entry_t entry, struct Page *page) {
ffffffffc0203c5e:	1141                	addi	sp,sp,-16
ffffffffc0203c60:	e406                	sd	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203c62:	00855793          	srli	a5,a0,0x8
ffffffffc0203c66:	c7b5                	beqz	a5,ffffffffc0203cd2 <swapfs_read+0x74>
ffffffffc0203c68:	0000e717          	auipc	a4,0xe
ffffffffc0203c6c:	8e070713          	addi	a4,a4,-1824 # ffffffffc0211548 <max_swap_offset>
ffffffffc0203c70:	6318                	ld	a4,0(a4)
ffffffffc0203c72:	06e7f063          	bgeu	a5,a4,ffffffffc0203cd2 <swapfs_read+0x74>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203c76:	0000e717          	auipc	a4,0xe
ffffffffc0203c7a:	83a70713          	addi	a4,a4,-1990 # ffffffffc02114b0 <pages>
ffffffffc0203c7e:	6310                	ld	a2,0(a4)
ffffffffc0203c80:	00001717          	auipc	a4,0x1
ffffffffc0203c84:	02070713          	addi	a4,a4,32 # ffffffffc0204ca0 <commands+0x838>
ffffffffc0203c88:	00002697          	auipc	a3,0x2
ffffffffc0203c8c:	54868693          	addi	a3,a3,1352 # ffffffffc02061d0 <nbase>
ffffffffc0203c90:	40c58633          	sub	a2,a1,a2
ffffffffc0203c94:	630c                	ld	a1,0(a4)
ffffffffc0203c96:	860d                	srai	a2,a2,0x3
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203c98:	0000d717          	auipc	a4,0xd
ffffffffc0203c9c:	7c070713          	addi	a4,a4,1984 # ffffffffc0211458 <npage>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203ca0:	02b60633          	mul	a2,a2,a1
ffffffffc0203ca4:	0037959b          	slliw	a1,a5,0x3
ffffffffc0203ca8:	629c                	ld	a5,0(a3)
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203caa:	6318                	ld	a4,0(a4)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203cac:	963e                	add	a2,a2,a5
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203cae:	00c61793          	slli	a5,a2,0xc
ffffffffc0203cb2:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0203cb4:	0632                	slli	a2,a2,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203cb6:	02e7fa63          	bgeu	a5,a4,ffffffffc0203cea <swapfs_read+0x8c>
ffffffffc0203cba:	0000d797          	auipc	a5,0xd
ffffffffc0203cbe:	7e678793          	addi	a5,a5,2022 # ffffffffc02114a0 <va_pa_offset>
ffffffffc0203cc2:	639c                	ld	a5,0(a5)
}
ffffffffc0203cc4:	60a2                	ld	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203cc6:	46a1                	li	a3,8
ffffffffc0203cc8:	963e                	add	a2,a2,a5
ffffffffc0203cca:	4505                	li	a0,1
}
ffffffffc0203ccc:	0141                	addi	sp,sp,16
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203cce:	f10fc06f          	j	ffffffffc02003de <ide_read_secs>
ffffffffc0203cd2:	86aa                	mv	a3,a0
ffffffffc0203cd4:	00002617          	auipc	a2,0x2
ffffffffc0203cd8:	29460613          	addi	a2,a2,660 # ffffffffc0205f68 <default_pmm_manager+0x198>
ffffffffc0203cdc:	45d1                	li	a1,20
ffffffffc0203cde:	00002517          	auipc	a0,0x2
ffffffffc0203ce2:	27250513          	addi	a0,a0,626 # ffffffffc0205f50 <default_pmm_manager+0x180>
ffffffffc0203ce6:	c1efc0ef          	jal	ra,ffffffffc0200104 <__panic>
ffffffffc0203cea:	86b2                	mv	a3,a2
ffffffffc0203cec:	06a00593          	li	a1,106
ffffffffc0203cf0:	00001617          	auipc	a2,0x1
ffffffffc0203cf4:	fb860613          	addi	a2,a2,-72 # ffffffffc0204ca8 <commands+0x840>
ffffffffc0203cf8:	00001517          	auipc	a0,0x1
ffffffffc0203cfc:	04850513          	addi	a0,a0,72 # ffffffffc0204d40 <commands+0x8d8>
ffffffffc0203d00:	c04fc0ef          	jal	ra,ffffffffc0200104 <__panic>

ffffffffc0203d04 <swapfs_write>:

int
swapfs_write(swap_entry_t entry, struct Page *page) {
ffffffffc0203d04:	1141                	addi	sp,sp,-16
ffffffffc0203d06:	e406                	sd	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203d08:	00855793          	srli	a5,a0,0x8
ffffffffc0203d0c:	c7b5                	beqz	a5,ffffffffc0203d78 <swapfs_write+0x74>
ffffffffc0203d0e:	0000e717          	auipc	a4,0xe
ffffffffc0203d12:	83a70713          	addi	a4,a4,-1990 # ffffffffc0211548 <max_swap_offset>
ffffffffc0203d16:	6318                	ld	a4,0(a4)
ffffffffc0203d18:	06e7f063          	bgeu	a5,a4,ffffffffc0203d78 <swapfs_write+0x74>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203d1c:	0000d717          	auipc	a4,0xd
ffffffffc0203d20:	79470713          	addi	a4,a4,1940 # ffffffffc02114b0 <pages>
ffffffffc0203d24:	6310                	ld	a2,0(a4)
ffffffffc0203d26:	00001717          	auipc	a4,0x1
ffffffffc0203d2a:	f7a70713          	addi	a4,a4,-134 # ffffffffc0204ca0 <commands+0x838>
ffffffffc0203d2e:	00002697          	auipc	a3,0x2
ffffffffc0203d32:	4a268693          	addi	a3,a3,1186 # ffffffffc02061d0 <nbase>
ffffffffc0203d36:	40c58633          	sub	a2,a1,a2
ffffffffc0203d3a:	630c                	ld	a1,0(a4)
ffffffffc0203d3c:	860d                	srai	a2,a2,0x3
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203d3e:	0000d717          	auipc	a4,0xd
ffffffffc0203d42:	71a70713          	addi	a4,a4,1818 # ffffffffc0211458 <npage>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203d46:	02b60633          	mul	a2,a2,a1
ffffffffc0203d4a:	0037959b          	slliw	a1,a5,0x3
ffffffffc0203d4e:	629c                	ld	a5,0(a3)
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203d50:	6318                	ld	a4,0(a4)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203d52:	963e                	add	a2,a2,a5
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203d54:	00c61793          	slli	a5,a2,0xc
ffffffffc0203d58:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0203d5a:	0632                	slli	a2,a2,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203d5c:	02e7fa63          	bgeu	a5,a4,ffffffffc0203d90 <swapfs_write+0x8c>
ffffffffc0203d60:	0000d797          	auipc	a5,0xd
ffffffffc0203d64:	74078793          	addi	a5,a5,1856 # ffffffffc02114a0 <va_pa_offset>
ffffffffc0203d68:	639c                	ld	a5,0(a5)
}
ffffffffc0203d6a:	60a2                	ld	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203d6c:	46a1                	li	a3,8
ffffffffc0203d6e:	963e                	add	a2,a2,a5
ffffffffc0203d70:	4505                	li	a0,1
}
ffffffffc0203d72:	0141                	addi	sp,sp,16
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203d74:	e8efc06f          	j	ffffffffc0200402 <ide_write_secs>
ffffffffc0203d78:	86aa                	mv	a3,a0
ffffffffc0203d7a:	00002617          	auipc	a2,0x2
ffffffffc0203d7e:	1ee60613          	addi	a2,a2,494 # ffffffffc0205f68 <default_pmm_manager+0x198>
ffffffffc0203d82:	45e5                	li	a1,25
ffffffffc0203d84:	00002517          	auipc	a0,0x2
ffffffffc0203d88:	1cc50513          	addi	a0,a0,460 # ffffffffc0205f50 <default_pmm_manager+0x180>
ffffffffc0203d8c:	b78fc0ef          	jal	ra,ffffffffc0200104 <__panic>
ffffffffc0203d90:	86b2                	mv	a3,a2
ffffffffc0203d92:	06a00593          	li	a1,106
ffffffffc0203d96:	00001617          	auipc	a2,0x1
ffffffffc0203d9a:	f1260613          	addi	a2,a2,-238 # ffffffffc0204ca8 <commands+0x840>
ffffffffc0203d9e:	00001517          	auipc	a0,0x1
ffffffffc0203da2:	fa250513          	addi	a0,a0,-94 # ffffffffc0204d40 <commands+0x8d8>
ffffffffc0203da6:	b5efc0ef          	jal	ra,ffffffffc0200104 <__panic>

ffffffffc0203daa <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0203daa:	00054783          	lbu	a5,0(a0)
ffffffffc0203dae:	cb91                	beqz	a5,ffffffffc0203dc2 <strlen+0x18>
    size_t cnt = 0;
ffffffffc0203db0:	4781                	li	a5,0
        cnt ++;
ffffffffc0203db2:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc0203db4:	00f50733          	add	a4,a0,a5
ffffffffc0203db8:	00074703          	lbu	a4,0(a4)
ffffffffc0203dbc:	fb7d                	bnez	a4,ffffffffc0203db2 <strlen+0x8>
    }
    return cnt;
}
ffffffffc0203dbe:	853e                	mv	a0,a5
ffffffffc0203dc0:	8082                	ret
    size_t cnt = 0;
ffffffffc0203dc2:	4781                	li	a5,0
}
ffffffffc0203dc4:	853e                	mv	a0,a5
ffffffffc0203dc6:	8082                	ret

ffffffffc0203dc8 <strnlen>:
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203dc8:	c185                	beqz	a1,ffffffffc0203de8 <strnlen+0x20>
ffffffffc0203dca:	00054783          	lbu	a5,0(a0)
ffffffffc0203dce:	cf89                	beqz	a5,ffffffffc0203de8 <strnlen+0x20>
    size_t cnt = 0;
ffffffffc0203dd0:	4781                	li	a5,0
ffffffffc0203dd2:	a021                	j	ffffffffc0203dda <strnlen+0x12>
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203dd4:	00074703          	lbu	a4,0(a4)
ffffffffc0203dd8:	c711                	beqz	a4,ffffffffc0203de4 <strnlen+0x1c>
        cnt ++;
ffffffffc0203dda:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203ddc:	00f50733          	add	a4,a0,a5
ffffffffc0203de0:	fef59ae3          	bne	a1,a5,ffffffffc0203dd4 <strnlen+0xc>
    }
    return cnt;
}
ffffffffc0203de4:	853e                	mv	a0,a5
ffffffffc0203de6:	8082                	ret
    size_t cnt = 0;
ffffffffc0203de8:	4781                	li	a5,0
}
ffffffffc0203dea:	853e                	mv	a0,a5
ffffffffc0203dec:	8082                	ret

ffffffffc0203dee <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0203dee:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0203df0:	0585                	addi	a1,a1,1
ffffffffc0203df2:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0203df6:	0785                	addi	a5,a5,1
ffffffffc0203df8:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0203dfc:	fb75                	bnez	a4,ffffffffc0203df0 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0203dfe:	8082                	ret

ffffffffc0203e00 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203e00:	00054783          	lbu	a5,0(a0)
ffffffffc0203e04:	0005c703          	lbu	a4,0(a1)
ffffffffc0203e08:	cb91                	beqz	a5,ffffffffc0203e1c <strcmp+0x1c>
ffffffffc0203e0a:	00e79c63          	bne	a5,a4,ffffffffc0203e22 <strcmp+0x22>
        s1 ++, s2 ++;
ffffffffc0203e0e:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203e10:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
ffffffffc0203e14:	0585                	addi	a1,a1,1
ffffffffc0203e16:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203e1a:	fbe5                	bnez	a5,ffffffffc0203e0a <strcmp+0xa>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e1c:	4501                	li	a0,0
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0203e1e:	9d19                	subw	a0,a0,a4
ffffffffc0203e20:	8082                	ret
ffffffffc0203e22:	0007851b          	sext.w	a0,a5
ffffffffc0203e26:	9d19                	subw	a0,a0,a4
ffffffffc0203e28:	8082                	ret

ffffffffc0203e2a <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0203e2a:	00054783          	lbu	a5,0(a0)
ffffffffc0203e2e:	cb91                	beqz	a5,ffffffffc0203e42 <strchr+0x18>
        if (*s == c) {
ffffffffc0203e30:	00b79563          	bne	a5,a1,ffffffffc0203e3a <strchr+0x10>
ffffffffc0203e34:	a809                	j	ffffffffc0203e46 <strchr+0x1c>
ffffffffc0203e36:	00b78763          	beq	a5,a1,ffffffffc0203e44 <strchr+0x1a>
            return (char *)s;
        }
        s ++;
ffffffffc0203e3a:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0203e3c:	00054783          	lbu	a5,0(a0)
ffffffffc0203e40:	fbfd                	bnez	a5,ffffffffc0203e36 <strchr+0xc>
    }
    return NULL;
ffffffffc0203e42:	4501                	li	a0,0
}
ffffffffc0203e44:	8082                	ret
ffffffffc0203e46:	8082                	ret

ffffffffc0203e48 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0203e48:	ca01                	beqz	a2,ffffffffc0203e58 <memset+0x10>
ffffffffc0203e4a:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0203e4c:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0203e4e:	0785                	addi	a5,a5,1
ffffffffc0203e50:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0203e54:	fec79de3          	bne	a5,a2,ffffffffc0203e4e <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0203e58:	8082                	ret

ffffffffc0203e5a <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0203e5a:	ca19                	beqz	a2,ffffffffc0203e70 <memcpy+0x16>
ffffffffc0203e5c:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0203e5e:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0203e60:	0585                	addi	a1,a1,1
ffffffffc0203e62:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0203e66:	0785                	addi	a5,a5,1
ffffffffc0203e68:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0203e6c:	fec59ae3          	bne	a1,a2,ffffffffc0203e60 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0203e70:	8082                	ret

ffffffffc0203e72 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0203e72:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203e76:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0203e78:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203e7c:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0203e7e:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203e82:	f022                	sd	s0,32(sp)
ffffffffc0203e84:	ec26                	sd	s1,24(sp)
ffffffffc0203e86:	e84a                	sd	s2,16(sp)
ffffffffc0203e88:	f406                	sd	ra,40(sp)
ffffffffc0203e8a:	e44e                	sd	s3,8(sp)
ffffffffc0203e8c:	84aa                	mv	s1,a0
ffffffffc0203e8e:	892e                	mv	s2,a1
ffffffffc0203e90:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0203e94:	2a01                	sext.w	s4,s4

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
ffffffffc0203e96:	03067e63          	bgeu	a2,a6,ffffffffc0203ed2 <printnum+0x60>
ffffffffc0203e9a:	89be                	mv	s3,a5
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0203e9c:	00805763          	blez	s0,ffffffffc0203eaa <printnum+0x38>
ffffffffc0203ea0:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0203ea2:	85ca                	mv	a1,s2
ffffffffc0203ea4:	854e                	mv	a0,s3
ffffffffc0203ea6:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0203ea8:	fc65                	bnez	s0,ffffffffc0203ea0 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203eaa:	1a02                	slli	s4,s4,0x20
ffffffffc0203eac:	020a5a13          	srli	s4,s4,0x20
ffffffffc0203eb0:	00002797          	auipc	a5,0x2
ffffffffc0203eb4:	26878793          	addi	a5,a5,616 # ffffffffc0206118 <error_string+0x38>
ffffffffc0203eb8:	9a3e                	add	s4,s4,a5
}
ffffffffc0203eba:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203ebc:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0203ec0:	70a2                	ld	ra,40(sp)
ffffffffc0203ec2:	69a2                	ld	s3,8(sp)
ffffffffc0203ec4:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203ec6:	85ca                	mv	a1,s2
ffffffffc0203ec8:	8326                	mv	t1,s1
}
ffffffffc0203eca:	6942                	ld	s2,16(sp)
ffffffffc0203ecc:	64e2                	ld	s1,24(sp)
ffffffffc0203ece:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203ed0:	8302                	jr	t1
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0203ed2:	03065633          	divu	a2,a2,a6
ffffffffc0203ed6:	8722                	mv	a4,s0
ffffffffc0203ed8:	f9bff0ef          	jal	ra,ffffffffc0203e72 <printnum>
ffffffffc0203edc:	b7f9                	j	ffffffffc0203eaa <printnum+0x38>

ffffffffc0203ede <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0203ede:	7119                	addi	sp,sp,-128
ffffffffc0203ee0:	f4a6                	sd	s1,104(sp)
ffffffffc0203ee2:	f0ca                	sd	s2,96(sp)
ffffffffc0203ee4:	e8d2                	sd	s4,80(sp)
ffffffffc0203ee6:	e4d6                	sd	s5,72(sp)
ffffffffc0203ee8:	e0da                	sd	s6,64(sp)
ffffffffc0203eea:	fc5e                	sd	s7,56(sp)
ffffffffc0203eec:	f862                	sd	s8,48(sp)
ffffffffc0203eee:	f06a                	sd	s10,32(sp)
ffffffffc0203ef0:	fc86                	sd	ra,120(sp)
ffffffffc0203ef2:	f8a2                	sd	s0,112(sp)
ffffffffc0203ef4:	ecce                	sd	s3,88(sp)
ffffffffc0203ef6:	f466                	sd	s9,40(sp)
ffffffffc0203ef8:	ec6e                	sd	s11,24(sp)
ffffffffc0203efa:	892a                	mv	s2,a0
ffffffffc0203efc:	84ae                	mv	s1,a1
ffffffffc0203efe:	8d32                	mv	s10,a2
ffffffffc0203f00:	8ab6                	mv	s5,a3
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0203f02:	5b7d                	li	s6,-1
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203f04:	00002a17          	auipc	s4,0x2
ffffffffc0203f08:	084a0a13          	addi	s4,s4,132 # ffffffffc0205f88 <default_pmm_manager+0x1b8>
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203f0c:	05e00b93          	li	s7,94
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203f10:	00002c17          	auipc	s8,0x2
ffffffffc0203f14:	1d0c0c13          	addi	s8,s8,464 # ffffffffc02060e0 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203f18:	000d4503          	lbu	a0,0(s10)
ffffffffc0203f1c:	02500793          	li	a5,37
ffffffffc0203f20:	001d0413          	addi	s0,s10,1
ffffffffc0203f24:	00f50e63          	beq	a0,a5,ffffffffc0203f40 <vprintfmt+0x62>
            if (ch == '\0') {
ffffffffc0203f28:	c521                	beqz	a0,ffffffffc0203f70 <vprintfmt+0x92>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203f2a:	02500993          	li	s3,37
ffffffffc0203f2e:	a011                	j	ffffffffc0203f32 <vprintfmt+0x54>
            if (ch == '\0') {
ffffffffc0203f30:	c121                	beqz	a0,ffffffffc0203f70 <vprintfmt+0x92>
            putch(ch, putdat);
ffffffffc0203f32:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203f34:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0203f36:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203f38:	fff44503          	lbu	a0,-1(s0)
ffffffffc0203f3c:	ff351ae3          	bne	a0,s3,ffffffffc0203f30 <vprintfmt+0x52>
ffffffffc0203f40:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0203f44:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0203f48:	4981                	li	s3,0
ffffffffc0203f4a:	4801                	li	a6,0
        width = precision = -1;
ffffffffc0203f4c:	5cfd                	li	s9,-1
ffffffffc0203f4e:	5dfd                	li	s11,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203f50:	05500593          	li	a1,85
                if (ch < '0' || ch > '9') {
ffffffffc0203f54:	4525                	li	a0,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203f56:	fdd6069b          	addiw	a3,a2,-35
ffffffffc0203f5a:	0ff6f693          	andi	a3,a3,255
ffffffffc0203f5e:	00140d13          	addi	s10,s0,1
ffffffffc0203f62:	1ed5ef63          	bltu	a1,a3,ffffffffc0204160 <vprintfmt+0x282>
ffffffffc0203f66:	068a                	slli	a3,a3,0x2
ffffffffc0203f68:	96d2                	add	a3,a3,s4
ffffffffc0203f6a:	4294                	lw	a3,0(a3)
ffffffffc0203f6c:	96d2                	add	a3,a3,s4
ffffffffc0203f6e:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0203f70:	70e6                	ld	ra,120(sp)
ffffffffc0203f72:	7446                	ld	s0,112(sp)
ffffffffc0203f74:	74a6                	ld	s1,104(sp)
ffffffffc0203f76:	7906                	ld	s2,96(sp)
ffffffffc0203f78:	69e6                	ld	s3,88(sp)
ffffffffc0203f7a:	6a46                	ld	s4,80(sp)
ffffffffc0203f7c:	6aa6                	ld	s5,72(sp)
ffffffffc0203f7e:	6b06                	ld	s6,64(sp)
ffffffffc0203f80:	7be2                	ld	s7,56(sp)
ffffffffc0203f82:	7c42                	ld	s8,48(sp)
ffffffffc0203f84:	7ca2                	ld	s9,40(sp)
ffffffffc0203f86:	7d02                	ld	s10,32(sp)
ffffffffc0203f88:	6de2                	ld	s11,24(sp)
ffffffffc0203f8a:	6109                	addi	sp,sp,128
ffffffffc0203f8c:	8082                	ret
            padc = '-';
ffffffffc0203f8e:	87b2                	mv	a5,a2
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203f90:	00144603          	lbu	a2,1(s0)
ffffffffc0203f94:	846a                	mv	s0,s10
ffffffffc0203f96:	b7c1                	j	ffffffffc0203f56 <vprintfmt+0x78>
            precision = va_arg(ap, int);
ffffffffc0203f98:	000aac83          	lw	s9,0(s5)
            goto process_precision;
ffffffffc0203f9c:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0203fa0:	0aa1                	addi	s5,s5,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203fa2:	846a                	mv	s0,s10
            if (width < 0)
ffffffffc0203fa4:	fa0dd9e3          	bgez	s11,ffffffffc0203f56 <vprintfmt+0x78>
                width = precision, precision = -1;
ffffffffc0203fa8:	8de6                	mv	s11,s9
ffffffffc0203faa:	5cfd                	li	s9,-1
ffffffffc0203fac:	b76d                	j	ffffffffc0203f56 <vprintfmt+0x78>
            if (width < 0)
ffffffffc0203fae:	fffdc693          	not	a3,s11
ffffffffc0203fb2:	96fd                	srai	a3,a3,0x3f
ffffffffc0203fb4:	00ddfdb3          	and	s11,s11,a3
ffffffffc0203fb8:	00144603          	lbu	a2,1(s0)
ffffffffc0203fbc:	2d81                	sext.w	s11,s11
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203fbe:	846a                	mv	s0,s10
ffffffffc0203fc0:	bf59                	j	ffffffffc0203f56 <vprintfmt+0x78>
    if (lflag >= 2) {
ffffffffc0203fc2:	4705                	li	a4,1
ffffffffc0203fc4:	008a8593          	addi	a1,s5,8
ffffffffc0203fc8:	01074463          	blt	a4,a6,ffffffffc0203fd0 <vprintfmt+0xf2>
    else if (lflag) {
ffffffffc0203fcc:	22080863          	beqz	a6,ffffffffc02041fc <vprintfmt+0x31e>
        return va_arg(*ap, unsigned long);
ffffffffc0203fd0:	000ab603          	ld	a2,0(s5)
ffffffffc0203fd4:	46c1                	li	a3,16
ffffffffc0203fd6:	8aae                	mv	s5,a1
ffffffffc0203fd8:	a291                	j	ffffffffc020411c <vprintfmt+0x23e>
                precision = precision * 10 + ch - '0';
ffffffffc0203fda:	fd060c9b          	addiw	s9,a2,-48
                ch = *fmt;
ffffffffc0203fde:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203fe2:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0203fe4:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0203fe8:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc0203fec:	fad56ce3          	bltu	a0,a3,ffffffffc0203fa4 <vprintfmt+0xc6>
            for (precision = 0; ; ++ fmt) {
ffffffffc0203ff0:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0203ff2:	002c969b          	slliw	a3,s9,0x2
                ch = *fmt;
ffffffffc0203ff6:	00044603          	lbu	a2,0(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0203ffa:	0196873b          	addw	a4,a3,s9
ffffffffc0203ffe:	0017171b          	slliw	a4,a4,0x1
ffffffffc0204002:	0117073b          	addw	a4,a4,a7
                if (ch < '0' || ch > '9') {
ffffffffc0204006:	fd06069b          	addiw	a3,a2,-48
                precision = precision * 10 + ch - '0';
ffffffffc020400a:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc020400e:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc0204012:	fcd57fe3          	bgeu	a0,a3,ffffffffc0203ff0 <vprintfmt+0x112>
ffffffffc0204016:	b779                	j	ffffffffc0203fa4 <vprintfmt+0xc6>
            putch(va_arg(ap, int), putdat);
ffffffffc0204018:	000aa503          	lw	a0,0(s5)
ffffffffc020401c:	85a6                	mv	a1,s1
ffffffffc020401e:	0aa1                	addi	s5,s5,8
ffffffffc0204020:	9902                	jalr	s2
            break;
ffffffffc0204022:	bddd                	j	ffffffffc0203f18 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0204024:	4705                	li	a4,1
ffffffffc0204026:	008a8993          	addi	s3,s5,8
ffffffffc020402a:	01074463          	blt	a4,a6,ffffffffc0204032 <vprintfmt+0x154>
    else if (lflag) {
ffffffffc020402e:	1c080463          	beqz	a6,ffffffffc02041f6 <vprintfmt+0x318>
        return va_arg(*ap, long);
ffffffffc0204032:	000ab403          	ld	s0,0(s5)
            if ((long long)num < 0) {
ffffffffc0204036:	1c044a63          	bltz	s0,ffffffffc020420a <vprintfmt+0x32c>
            num = getint(&ap, lflag);
ffffffffc020403a:	8622                	mv	a2,s0
ffffffffc020403c:	8ace                	mv	s5,s3
ffffffffc020403e:	46a9                	li	a3,10
ffffffffc0204040:	a8f1                	j	ffffffffc020411c <vprintfmt+0x23e>
            err = va_arg(ap, int);
ffffffffc0204042:	000aa783          	lw	a5,0(s5)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0204046:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0204048:	0aa1                	addi	s5,s5,8
            if (err < 0) {
ffffffffc020404a:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc020404e:	8fb5                	xor	a5,a5,a3
ffffffffc0204050:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0204054:	12d74963          	blt	a4,a3,ffffffffc0204186 <vprintfmt+0x2a8>
ffffffffc0204058:	00369793          	slli	a5,a3,0x3
ffffffffc020405c:	97e2                	add	a5,a5,s8
ffffffffc020405e:	639c                	ld	a5,0(a5)
ffffffffc0204060:	12078363          	beqz	a5,ffffffffc0204186 <vprintfmt+0x2a8>
                printfmt(putch, putdat, "%s", p);
ffffffffc0204064:	86be                	mv	a3,a5
ffffffffc0204066:	00002617          	auipc	a2,0x2
ffffffffc020406a:	16260613          	addi	a2,a2,354 # ffffffffc02061c8 <error_string+0xe8>
ffffffffc020406e:	85a6                	mv	a1,s1
ffffffffc0204070:	854a                	mv	a0,s2
ffffffffc0204072:	1cc000ef          	jal	ra,ffffffffc020423e <printfmt>
ffffffffc0204076:	b54d                	j	ffffffffc0203f18 <vprintfmt+0x3a>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0204078:	000ab603          	ld	a2,0(s5)
ffffffffc020407c:	0aa1                	addi	s5,s5,8
ffffffffc020407e:	1a060163          	beqz	a2,ffffffffc0204220 <vprintfmt+0x342>
            if (width > 0 && padc != '-') {
ffffffffc0204082:	00160413          	addi	s0,a2,1
ffffffffc0204086:	15b05763          	blez	s11,ffffffffc02041d4 <vprintfmt+0x2f6>
ffffffffc020408a:	02d00593          	li	a1,45
ffffffffc020408e:	10b79d63          	bne	a5,a1,ffffffffc02041a8 <vprintfmt+0x2ca>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204092:	00064783          	lbu	a5,0(a2)
ffffffffc0204096:	0007851b          	sext.w	a0,a5
ffffffffc020409a:	c905                	beqz	a0,ffffffffc02040ca <vprintfmt+0x1ec>
ffffffffc020409c:	000cc563          	bltz	s9,ffffffffc02040a6 <vprintfmt+0x1c8>
ffffffffc02040a0:	3cfd                	addiw	s9,s9,-1
ffffffffc02040a2:	036c8263          	beq	s9,s6,ffffffffc02040c6 <vprintfmt+0x1e8>
                    putch('?', putdat);
ffffffffc02040a6:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02040a8:	14098f63          	beqz	s3,ffffffffc0204206 <vprintfmt+0x328>
ffffffffc02040ac:	3781                	addiw	a5,a5,-32
ffffffffc02040ae:	14fbfc63          	bgeu	s7,a5,ffffffffc0204206 <vprintfmt+0x328>
                    putch('?', putdat);
ffffffffc02040b2:	03f00513          	li	a0,63
ffffffffc02040b6:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02040b8:	0405                	addi	s0,s0,1
ffffffffc02040ba:	fff44783          	lbu	a5,-1(s0)
ffffffffc02040be:	3dfd                	addiw	s11,s11,-1
ffffffffc02040c0:	0007851b          	sext.w	a0,a5
ffffffffc02040c4:	fd61                	bnez	a0,ffffffffc020409c <vprintfmt+0x1be>
            for (; width > 0; width --) {
ffffffffc02040c6:	e5b059e3          	blez	s11,ffffffffc0203f18 <vprintfmt+0x3a>
ffffffffc02040ca:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02040cc:	85a6                	mv	a1,s1
ffffffffc02040ce:	02000513          	li	a0,32
ffffffffc02040d2:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02040d4:	e40d82e3          	beqz	s11,ffffffffc0203f18 <vprintfmt+0x3a>
ffffffffc02040d8:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02040da:	85a6                	mv	a1,s1
ffffffffc02040dc:	02000513          	li	a0,32
ffffffffc02040e0:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02040e2:	fe0d94e3          	bnez	s11,ffffffffc02040ca <vprintfmt+0x1ec>
ffffffffc02040e6:	bd0d                	j	ffffffffc0203f18 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02040e8:	4705                	li	a4,1
ffffffffc02040ea:	008a8593          	addi	a1,s5,8
ffffffffc02040ee:	01074463          	blt	a4,a6,ffffffffc02040f6 <vprintfmt+0x218>
    else if (lflag) {
ffffffffc02040f2:	0e080863          	beqz	a6,ffffffffc02041e2 <vprintfmt+0x304>
        return va_arg(*ap, unsigned long);
ffffffffc02040f6:	000ab603          	ld	a2,0(s5)
ffffffffc02040fa:	46a1                	li	a3,8
ffffffffc02040fc:	8aae                	mv	s5,a1
ffffffffc02040fe:	a839                	j	ffffffffc020411c <vprintfmt+0x23e>
            putch('0', putdat);
ffffffffc0204100:	03000513          	li	a0,48
ffffffffc0204104:	85a6                	mv	a1,s1
ffffffffc0204106:	e03e                	sd	a5,0(sp)
ffffffffc0204108:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc020410a:	85a6                	mv	a1,s1
ffffffffc020410c:	07800513          	li	a0,120
ffffffffc0204110:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0204112:	0aa1                	addi	s5,s5,8
ffffffffc0204114:	ff8ab603          	ld	a2,-8(s5)
            goto number;
ffffffffc0204118:	6782                	ld	a5,0(sp)
ffffffffc020411a:	46c1                	li	a3,16
            printnum(putch, putdat, num, base, width, padc);
ffffffffc020411c:	2781                	sext.w	a5,a5
ffffffffc020411e:	876e                	mv	a4,s11
ffffffffc0204120:	85a6                	mv	a1,s1
ffffffffc0204122:	854a                	mv	a0,s2
ffffffffc0204124:	d4fff0ef          	jal	ra,ffffffffc0203e72 <printnum>
            break;
ffffffffc0204128:	bbc5                	j	ffffffffc0203f18 <vprintfmt+0x3a>
            lflag ++;
ffffffffc020412a:	00144603          	lbu	a2,1(s0)
ffffffffc020412e:	2805                	addiw	a6,a6,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204130:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0204132:	b515                	j	ffffffffc0203f56 <vprintfmt+0x78>
            goto reswitch;
ffffffffc0204134:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0204138:	4985                	li	s3,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020413a:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020413c:	bd29                	j	ffffffffc0203f56 <vprintfmt+0x78>
            putch(ch, putdat);
ffffffffc020413e:	85a6                	mv	a1,s1
ffffffffc0204140:	02500513          	li	a0,37
ffffffffc0204144:	9902                	jalr	s2
            break;
ffffffffc0204146:	bbc9                	j	ffffffffc0203f18 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0204148:	4705                	li	a4,1
ffffffffc020414a:	008a8593          	addi	a1,s5,8
ffffffffc020414e:	01074463          	blt	a4,a6,ffffffffc0204156 <vprintfmt+0x278>
    else if (lflag) {
ffffffffc0204152:	08080d63          	beqz	a6,ffffffffc02041ec <vprintfmt+0x30e>
        return va_arg(*ap, unsigned long);
ffffffffc0204156:	000ab603          	ld	a2,0(s5)
ffffffffc020415a:	46a9                	li	a3,10
ffffffffc020415c:	8aae                	mv	s5,a1
ffffffffc020415e:	bf7d                	j	ffffffffc020411c <vprintfmt+0x23e>
            putch('%', putdat);
ffffffffc0204160:	85a6                	mv	a1,s1
ffffffffc0204162:	02500513          	li	a0,37
ffffffffc0204166:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0204168:	fff44703          	lbu	a4,-1(s0)
ffffffffc020416c:	02500793          	li	a5,37
ffffffffc0204170:	8d22                	mv	s10,s0
ffffffffc0204172:	daf703e3          	beq	a4,a5,ffffffffc0203f18 <vprintfmt+0x3a>
ffffffffc0204176:	02500713          	li	a4,37
ffffffffc020417a:	1d7d                	addi	s10,s10,-1
ffffffffc020417c:	fffd4783          	lbu	a5,-1(s10)
ffffffffc0204180:	fee79de3          	bne	a5,a4,ffffffffc020417a <vprintfmt+0x29c>
ffffffffc0204184:	bb51                	j	ffffffffc0203f18 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0204186:	00002617          	auipc	a2,0x2
ffffffffc020418a:	03260613          	addi	a2,a2,50 # ffffffffc02061b8 <error_string+0xd8>
ffffffffc020418e:	85a6                	mv	a1,s1
ffffffffc0204190:	854a                	mv	a0,s2
ffffffffc0204192:	0ac000ef          	jal	ra,ffffffffc020423e <printfmt>
ffffffffc0204196:	b349                	j	ffffffffc0203f18 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0204198:	00002617          	auipc	a2,0x2
ffffffffc020419c:	01860613          	addi	a2,a2,24 # ffffffffc02061b0 <error_string+0xd0>
            if (width > 0 && padc != '-') {
ffffffffc02041a0:	00002417          	auipc	s0,0x2
ffffffffc02041a4:	01140413          	addi	s0,s0,17 # ffffffffc02061b1 <error_string+0xd1>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02041a8:	8532                	mv	a0,a2
ffffffffc02041aa:	85e6                	mv	a1,s9
ffffffffc02041ac:	e032                	sd	a2,0(sp)
ffffffffc02041ae:	e43e                	sd	a5,8(sp)
ffffffffc02041b0:	c19ff0ef          	jal	ra,ffffffffc0203dc8 <strnlen>
ffffffffc02041b4:	40ad8dbb          	subw	s11,s11,a0
ffffffffc02041b8:	6602                	ld	a2,0(sp)
ffffffffc02041ba:	01b05d63          	blez	s11,ffffffffc02041d4 <vprintfmt+0x2f6>
ffffffffc02041be:	67a2                	ld	a5,8(sp)
ffffffffc02041c0:	2781                	sext.w	a5,a5
ffffffffc02041c2:	e43e                	sd	a5,8(sp)
                    putch(padc, putdat);
ffffffffc02041c4:	6522                	ld	a0,8(sp)
ffffffffc02041c6:	85a6                	mv	a1,s1
ffffffffc02041c8:	e032                	sd	a2,0(sp)
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02041ca:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc02041cc:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02041ce:	6602                	ld	a2,0(sp)
ffffffffc02041d0:	fe0d9ae3          	bnez	s11,ffffffffc02041c4 <vprintfmt+0x2e6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02041d4:	00064783          	lbu	a5,0(a2)
ffffffffc02041d8:	0007851b          	sext.w	a0,a5
ffffffffc02041dc:	ec0510e3          	bnez	a0,ffffffffc020409c <vprintfmt+0x1be>
ffffffffc02041e0:	bb25                	j	ffffffffc0203f18 <vprintfmt+0x3a>
        return va_arg(*ap, unsigned int);
ffffffffc02041e2:	000ae603          	lwu	a2,0(s5)
ffffffffc02041e6:	46a1                	li	a3,8
ffffffffc02041e8:	8aae                	mv	s5,a1
ffffffffc02041ea:	bf0d                	j	ffffffffc020411c <vprintfmt+0x23e>
ffffffffc02041ec:	000ae603          	lwu	a2,0(s5)
ffffffffc02041f0:	46a9                	li	a3,10
ffffffffc02041f2:	8aae                	mv	s5,a1
ffffffffc02041f4:	b725                	j	ffffffffc020411c <vprintfmt+0x23e>
        return va_arg(*ap, int);
ffffffffc02041f6:	000aa403          	lw	s0,0(s5)
ffffffffc02041fa:	bd35                	j	ffffffffc0204036 <vprintfmt+0x158>
        return va_arg(*ap, unsigned int);
ffffffffc02041fc:	000ae603          	lwu	a2,0(s5)
ffffffffc0204200:	46c1                	li	a3,16
ffffffffc0204202:	8aae                	mv	s5,a1
ffffffffc0204204:	bf21                	j	ffffffffc020411c <vprintfmt+0x23e>
                    putch(ch, putdat);
ffffffffc0204206:	9902                	jalr	s2
ffffffffc0204208:	bd45                	j	ffffffffc02040b8 <vprintfmt+0x1da>
                putch('-', putdat);
ffffffffc020420a:	85a6                	mv	a1,s1
ffffffffc020420c:	02d00513          	li	a0,45
ffffffffc0204210:	e03e                	sd	a5,0(sp)
ffffffffc0204212:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0204214:	8ace                	mv	s5,s3
ffffffffc0204216:	40800633          	neg	a2,s0
ffffffffc020421a:	46a9                	li	a3,10
ffffffffc020421c:	6782                	ld	a5,0(sp)
ffffffffc020421e:	bdfd                	j	ffffffffc020411c <vprintfmt+0x23e>
            if (width > 0 && padc != '-') {
ffffffffc0204220:	01b05663          	blez	s11,ffffffffc020422c <vprintfmt+0x34e>
ffffffffc0204224:	02d00693          	li	a3,45
ffffffffc0204228:	f6d798e3          	bne	a5,a3,ffffffffc0204198 <vprintfmt+0x2ba>
ffffffffc020422c:	00002417          	auipc	s0,0x2
ffffffffc0204230:	f8540413          	addi	s0,s0,-123 # ffffffffc02061b1 <error_string+0xd1>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204234:	02800513          	li	a0,40
ffffffffc0204238:	02800793          	li	a5,40
ffffffffc020423c:	b585                	j	ffffffffc020409c <vprintfmt+0x1be>

ffffffffc020423e <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020423e:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0204240:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0204244:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0204246:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0204248:	ec06                	sd	ra,24(sp)
ffffffffc020424a:	f83a                	sd	a4,48(sp)
ffffffffc020424c:	fc3e                	sd	a5,56(sp)
ffffffffc020424e:	e0c2                	sd	a6,64(sp)
ffffffffc0204250:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0204252:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0204254:	c8bff0ef          	jal	ra,ffffffffc0203ede <vprintfmt>
}
ffffffffc0204258:	60e2                	ld	ra,24(sp)
ffffffffc020425a:	6161                	addi	sp,sp,80
ffffffffc020425c:	8082                	ret

ffffffffc020425e <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc020425e:	715d                	addi	sp,sp,-80
ffffffffc0204260:	e486                	sd	ra,72(sp)
ffffffffc0204262:	e0a2                	sd	s0,64(sp)
ffffffffc0204264:	fc26                	sd	s1,56(sp)
ffffffffc0204266:	f84a                	sd	s2,48(sp)
ffffffffc0204268:	f44e                	sd	s3,40(sp)
ffffffffc020426a:	f052                	sd	s4,32(sp)
ffffffffc020426c:	ec56                	sd	s5,24(sp)
ffffffffc020426e:	e85a                	sd	s6,16(sp)
ffffffffc0204270:	e45e                	sd	s7,8(sp)
    if (prompt != NULL) {
ffffffffc0204272:	c901                	beqz	a0,ffffffffc0204282 <readline+0x24>
        cprintf("%s", prompt);
ffffffffc0204274:	85aa                	mv	a1,a0
ffffffffc0204276:	00002517          	auipc	a0,0x2
ffffffffc020427a:	f5250513          	addi	a0,a0,-174 # ffffffffc02061c8 <error_string+0xe8>
ffffffffc020427e:	e41fb0ef          	jal	ra,ffffffffc02000be <cprintf>
readline(const char *prompt) {
ffffffffc0204282:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0204284:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0204286:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0204288:	4aa9                	li	s5,10
ffffffffc020428a:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc020428c:	0000db97          	auipc	s7,0xd
ffffffffc0204290:	db4b8b93          	addi	s7,s7,-588 # ffffffffc0211040 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0204294:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0204298:	e5dfb0ef          	jal	ra,ffffffffc02000f4 <getchar>
ffffffffc020429c:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc020429e:	00054b63          	bltz	a0,ffffffffc02042b4 <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02042a2:	00a95b63          	bge	s2,a0,ffffffffc02042b8 <readline+0x5a>
ffffffffc02042a6:	029a5463          	bge	s4,s1,ffffffffc02042ce <readline+0x70>
        c = getchar();
ffffffffc02042aa:	e4bfb0ef          	jal	ra,ffffffffc02000f4 <getchar>
ffffffffc02042ae:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc02042b0:	fe0559e3          	bgez	a0,ffffffffc02042a2 <readline+0x44>
            return NULL;
ffffffffc02042b4:	4501                	li	a0,0
ffffffffc02042b6:	a099                	j	ffffffffc02042fc <readline+0x9e>
        else if (c == '\b' && i > 0) {
ffffffffc02042b8:	03341463          	bne	s0,s3,ffffffffc02042e0 <readline+0x82>
ffffffffc02042bc:	e8b9                	bnez	s1,ffffffffc0204312 <readline+0xb4>
        c = getchar();
ffffffffc02042be:	e37fb0ef          	jal	ra,ffffffffc02000f4 <getchar>
ffffffffc02042c2:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc02042c4:	fe0548e3          	bltz	a0,ffffffffc02042b4 <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02042c8:	fea958e3          	bge	s2,a0,ffffffffc02042b8 <readline+0x5a>
ffffffffc02042cc:	4481                	li	s1,0
            cputchar(c);
ffffffffc02042ce:	8522                	mv	a0,s0
ffffffffc02042d0:	e23fb0ef          	jal	ra,ffffffffc02000f2 <cputchar>
            buf[i ++] = c;
ffffffffc02042d4:	009b87b3          	add	a5,s7,s1
ffffffffc02042d8:	00878023          	sb	s0,0(a5)
ffffffffc02042dc:	2485                	addiw	s1,s1,1
ffffffffc02042de:	bf6d                	j	ffffffffc0204298 <readline+0x3a>
        else if (c == '\n' || c == '\r') {
ffffffffc02042e0:	01540463          	beq	s0,s5,ffffffffc02042e8 <readline+0x8a>
ffffffffc02042e4:	fb641ae3          	bne	s0,s6,ffffffffc0204298 <readline+0x3a>
            cputchar(c);
ffffffffc02042e8:	8522                	mv	a0,s0
ffffffffc02042ea:	e09fb0ef          	jal	ra,ffffffffc02000f2 <cputchar>
            buf[i] = '\0';
ffffffffc02042ee:	0000d517          	auipc	a0,0xd
ffffffffc02042f2:	d5250513          	addi	a0,a0,-686 # ffffffffc0211040 <buf>
ffffffffc02042f6:	94aa                	add	s1,s1,a0
ffffffffc02042f8:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc02042fc:	60a6                	ld	ra,72(sp)
ffffffffc02042fe:	6406                	ld	s0,64(sp)
ffffffffc0204300:	74e2                	ld	s1,56(sp)
ffffffffc0204302:	7942                	ld	s2,48(sp)
ffffffffc0204304:	79a2                	ld	s3,40(sp)
ffffffffc0204306:	7a02                	ld	s4,32(sp)
ffffffffc0204308:	6ae2                	ld	s5,24(sp)
ffffffffc020430a:	6b42                	ld	s6,16(sp)
ffffffffc020430c:	6ba2                	ld	s7,8(sp)
ffffffffc020430e:	6161                	addi	sp,sp,80
ffffffffc0204310:	8082                	ret
            cputchar(c);
ffffffffc0204312:	4521                	li	a0,8
ffffffffc0204314:	ddffb0ef          	jal	ra,ffffffffc02000f2 <cputchar>
            i --;
ffffffffc0204318:	34fd                	addiw	s1,s1,-1
ffffffffc020431a:	bfbd                	j	ffffffffc0204298 <readline+0x3a>
