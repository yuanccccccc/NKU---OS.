
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
ffffffffc0200042:	55a60613          	addi	a2,a2,1370 # ffffffffc0211598 <end>
kern_init(void) {
ffffffffc0200046:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200048:	8e09                	sub	a2,a2,a0
ffffffffc020004a:	4581                	li	a1,0
kern_init(void) {
ffffffffc020004c:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004e:	639030ef          	jal	ra,ffffffffc0203e86 <memset>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc0200052:	00004597          	auipc	a1,0x4
ffffffffc0200056:	30e58593          	addi	a1,a1,782 # ffffffffc0204360 <etext+0x6>
ffffffffc020005a:	00004517          	auipc	a0,0x4
ffffffffc020005e:	32650513          	addi	a0,a0,806 # ffffffffc0204380 <etext+0x26>
ffffffffc0200062:	05c000ef          	jal	ra,ffffffffc02000be <cprintf>

    print_kerninfo();
ffffffffc0200066:	0fe000ef          	jal	ra,ffffffffc0200164 <print_kerninfo>

    // grade_backtrace();

    pmm_init();                 // init physical memory management
ffffffffc020006a:	711000ef          	jal	ra,ffffffffc0200f7a <pmm_init>

    idt_init();                 // init interrupt descriptor table
ffffffffc020006e:	4fc000ef          	jal	ra,ffffffffc020056a <idt_init>

    vmm_init();                 // init virtual memory management
ffffffffc0200072:	1d2020ef          	jal	ra,ffffffffc0202244 <vmm_init>

    ide_init();                 // init ide devices
ffffffffc0200076:	35a000ef          	jal	ra,ffffffffc02003d0 <ide_init>
    swap_init();                // init swap
ffffffffc020007a:	7dc020ef          	jal	ra,ffffffffc0202856 <swap_init>

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
ffffffffc02000b2:	66b030ef          	jal	ra,ffffffffc0203f1c <vprintfmt>
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
ffffffffc02000e6:	637030ef          	jal	ra,ffffffffc0203f1c <vprintfmt>
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
ffffffffc020013a:	25250513          	addi	a0,a0,594 # ffffffffc0204388 <etext+0x2e>
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
ffffffffc0200150:	05450513          	addi	a0,a0,84 # ffffffffc02051a0 <commands+0xcf8>
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
ffffffffc020016a:	27250513          	addi	a0,a0,626 # ffffffffc02043d8 <etext+0x7e>
void print_kerninfo(void) {
ffffffffc020016e:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200170:	f4fff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc0200174:	00000597          	auipc	a1,0x0
ffffffffc0200178:	ec258593          	addi	a1,a1,-318 # ffffffffc0200036 <kern_init>
ffffffffc020017c:	00004517          	auipc	a0,0x4
ffffffffc0200180:	27c50513          	addi	a0,a0,636 # ffffffffc02043f8 <etext+0x9e>
ffffffffc0200184:	f3bff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200188:	00004597          	auipc	a1,0x4
ffffffffc020018c:	1d258593          	addi	a1,a1,466 # ffffffffc020435a <etext>
ffffffffc0200190:	00004517          	auipc	a0,0x4
ffffffffc0200194:	28850513          	addi	a0,a0,648 # ffffffffc0204418 <etext+0xbe>
ffffffffc0200198:	f27ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc020019c:	0000a597          	auipc	a1,0xa
ffffffffc02001a0:	ea458593          	addi	a1,a1,-348 # ffffffffc020a040 <edata>
ffffffffc02001a4:	00004517          	auipc	a0,0x4
ffffffffc02001a8:	29450513          	addi	a0,a0,660 # ffffffffc0204438 <etext+0xde>
ffffffffc02001ac:	f13ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc02001b0:	00011597          	auipc	a1,0x11
ffffffffc02001b4:	3e858593          	addi	a1,a1,1000 # ffffffffc0211598 <end>
ffffffffc02001b8:	00004517          	auipc	a0,0x4
ffffffffc02001bc:	2a050513          	addi	a0,a0,672 # ffffffffc0204458 <etext+0xfe>
ffffffffc02001c0:	effff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc02001c4:	00011597          	auipc	a1,0x11
ffffffffc02001c8:	7d358593          	addi	a1,a1,2003 # ffffffffc0211997 <end+0x3ff>
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
ffffffffc02001ea:	29250513          	addi	a0,a0,658 # ffffffffc0204478 <etext+0x11e>
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
ffffffffc02001f8:	1b460613          	addi	a2,a2,436 # ffffffffc02043a8 <etext+0x4e>
ffffffffc02001fc:	04e00593          	li	a1,78
ffffffffc0200200:	00004517          	auipc	a0,0x4
ffffffffc0200204:	1c050513          	addi	a0,a0,448 # ffffffffc02043c0 <etext+0x66>
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
ffffffffc0200214:	37060613          	addi	a2,a2,880 # ffffffffc0204580 <commands+0xd8>
ffffffffc0200218:	00004597          	auipc	a1,0x4
ffffffffc020021c:	38858593          	addi	a1,a1,904 # ffffffffc02045a0 <commands+0xf8>
ffffffffc0200220:	00004517          	auipc	a0,0x4
ffffffffc0200224:	38850513          	addi	a0,a0,904 # ffffffffc02045a8 <commands+0x100>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200228:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020022a:	e95ff0ef          	jal	ra,ffffffffc02000be <cprintf>
ffffffffc020022e:	00004617          	auipc	a2,0x4
ffffffffc0200232:	38a60613          	addi	a2,a2,906 # ffffffffc02045b8 <commands+0x110>
ffffffffc0200236:	00004597          	auipc	a1,0x4
ffffffffc020023a:	3aa58593          	addi	a1,a1,938 # ffffffffc02045e0 <commands+0x138>
ffffffffc020023e:	00004517          	auipc	a0,0x4
ffffffffc0200242:	36a50513          	addi	a0,a0,874 # ffffffffc02045a8 <commands+0x100>
ffffffffc0200246:	e79ff0ef          	jal	ra,ffffffffc02000be <cprintf>
ffffffffc020024a:	00004617          	auipc	a2,0x4
ffffffffc020024e:	3a660613          	addi	a2,a2,934 # ffffffffc02045f0 <commands+0x148>
ffffffffc0200252:	00004597          	auipc	a1,0x4
ffffffffc0200256:	3be58593          	addi	a1,a1,958 # ffffffffc0204610 <commands+0x168>
ffffffffc020025a:	00004517          	auipc	a0,0x4
ffffffffc020025e:	34e50513          	addi	a0,a0,846 # ffffffffc02045a8 <commands+0x100>
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
ffffffffc0200298:	25c50513          	addi	a0,a0,604 # ffffffffc02044f0 <commands+0x48>
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
ffffffffc02002ba:	26250513          	addi	a0,a0,610 # ffffffffc0204518 <commands+0x70>
ffffffffc02002be:	e01ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    if (tf != NULL) {
ffffffffc02002c2:	000c0563          	beqz	s8,ffffffffc02002cc <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002c6:	8562                	mv	a0,s8
ffffffffc02002c8:	48c000ef          	jal	ra,ffffffffc0200754 <print_trapframe>
ffffffffc02002cc:	00004c97          	auipc	s9,0x4
ffffffffc02002d0:	1dcc8c93          	addi	s9,s9,476 # ffffffffc02044a8 <commands>
        if ((buf = readline("")) != NULL) {
ffffffffc02002d4:	00006997          	auipc	s3,0x6
ffffffffc02002d8:	8fc98993          	addi	s3,s3,-1796 # ffffffffc0205bd0 <commands+0x1728>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002dc:	00004917          	auipc	s2,0x4
ffffffffc02002e0:	26490913          	addi	s2,s2,612 # ffffffffc0204540 <commands+0x98>
        if (argc == MAXARGS - 1) {
ffffffffc02002e4:	4a3d                	li	s4,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002e6:	00004b17          	auipc	s6,0x4
ffffffffc02002ea:	262b0b13          	addi	s6,s6,610 # ffffffffc0204548 <commands+0xa0>
    if (argc == 0) {
ffffffffc02002ee:	00004a97          	auipc	s5,0x4
ffffffffc02002f2:	2b2a8a93          	addi	s5,s5,690 # ffffffffc02045a0 <commands+0xf8>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002f6:	4b8d                	li	s7,3
        if ((buf = readline("")) != NULL) {
ffffffffc02002f8:	854e                	mv	a0,s3
ffffffffc02002fa:	7a3030ef          	jal	ra,ffffffffc020429c <readline>
ffffffffc02002fe:	842a                	mv	s0,a0
ffffffffc0200300:	dd65                	beqz	a0,ffffffffc02002f8 <kmonitor+0x6a>
ffffffffc0200302:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc0200306:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200308:	c999                	beqz	a1,ffffffffc020031e <kmonitor+0x90>
ffffffffc020030a:	854a                	mv	a0,s2
ffffffffc020030c:	35d030ef          	jal	ra,ffffffffc0203e68 <strchr>
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
ffffffffc0200326:	186d0d13          	addi	s10,s10,390 # ffffffffc02044a8 <commands>
    if (argc == 0) {
ffffffffc020032a:	8556                	mv	a0,s5
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020032c:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020032e:	0d61                	addi	s10,s10,24
ffffffffc0200330:	30f030ef          	jal	ra,ffffffffc0203e3e <strcmp>
ffffffffc0200334:	c919                	beqz	a0,ffffffffc020034a <kmonitor+0xbc>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200336:	2405                	addiw	s0,s0,1
ffffffffc0200338:	09740463          	beq	s0,s7,ffffffffc02003c0 <kmonitor+0x132>
ffffffffc020033c:	000d3503          	ld	a0,0(s10)
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200340:	6582                	ld	a1,0(sp)
ffffffffc0200342:	0d61                	addi	s10,s10,24
ffffffffc0200344:	2fb030ef          	jal	ra,ffffffffc0203e3e <strcmp>
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
ffffffffc02003aa:	2bf030ef          	jal	ra,ffffffffc0203e68 <strchr>
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
ffffffffc02003c6:	1a650513          	addi	a0,a0,422 # ffffffffc0204568 <commands+0xc0>
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
ffffffffc02003f6:	2a3030ef          	jal	ra,ffffffffc0203e98 <memcpy>
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
ffffffffc020041c:	27d030ef          	jal	ra,ffffffffc0203e98 <memcpy>
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
ffffffffc0200452:	1d250513          	addi	a0,a0,466 # ffffffffc0204620 <commands+0x178>
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
ffffffffc020052c:	3f050513          	addi	a0,a0,1008 # ffffffffc0204918 <commands+0x470>
ffffffffc0200530:	b8fff0ef          	jal	ra,ffffffffc02000be <cprintf>
    extern struct mm_struct *check_mm_struct;
    print_pgfault(tf);
    if (check_mm_struct != NULL) {
ffffffffc0200534:	00011797          	auipc	a5,0x11
ffffffffc0200538:	f7c78793          	addi	a5,a5,-132 # ffffffffc02114b0 <check_mm_struct>
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
ffffffffc020054e:	2340206f          	j	ffffffffc0202782 <do_pgfault>
    panic("unhandled page fault.\n");
ffffffffc0200552:	00004617          	auipc	a2,0x4
ffffffffc0200556:	3e660613          	addi	a2,a2,998 # ffffffffc0204938 <commands+0x490>
ffffffffc020055a:	07800593          	li	a1,120
ffffffffc020055e:	00004517          	auipc	a0,0x4
ffffffffc0200562:	3f250513          	addi	a0,a0,1010 # ffffffffc0204950 <commands+0x4a8>
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
ffffffffc0200594:	3d850513          	addi	a0,a0,984 # ffffffffc0204968 <commands+0x4c0>
void print_regs(struct pushregs *gpr) {
ffffffffc0200598:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020059a:	b25ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020059e:	640c                	ld	a1,8(s0)
ffffffffc02005a0:	00004517          	auipc	a0,0x4
ffffffffc02005a4:	3e050513          	addi	a0,a0,992 # ffffffffc0204980 <commands+0x4d8>
ffffffffc02005a8:	b17ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02005ac:	680c                	ld	a1,16(s0)
ffffffffc02005ae:	00004517          	auipc	a0,0x4
ffffffffc02005b2:	3ea50513          	addi	a0,a0,1002 # ffffffffc0204998 <commands+0x4f0>
ffffffffc02005b6:	b09ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02005ba:	6c0c                	ld	a1,24(s0)
ffffffffc02005bc:	00004517          	auipc	a0,0x4
ffffffffc02005c0:	3f450513          	addi	a0,a0,1012 # ffffffffc02049b0 <commands+0x508>
ffffffffc02005c4:	afbff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02005c8:	700c                	ld	a1,32(s0)
ffffffffc02005ca:	00004517          	auipc	a0,0x4
ffffffffc02005ce:	3fe50513          	addi	a0,a0,1022 # ffffffffc02049c8 <commands+0x520>
ffffffffc02005d2:	aedff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02005d6:	740c                	ld	a1,40(s0)
ffffffffc02005d8:	00004517          	auipc	a0,0x4
ffffffffc02005dc:	40850513          	addi	a0,a0,1032 # ffffffffc02049e0 <commands+0x538>
ffffffffc02005e0:	adfff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02005e4:	780c                	ld	a1,48(s0)
ffffffffc02005e6:	00004517          	auipc	a0,0x4
ffffffffc02005ea:	41250513          	addi	a0,a0,1042 # ffffffffc02049f8 <commands+0x550>
ffffffffc02005ee:	ad1ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02005f2:	7c0c                	ld	a1,56(s0)
ffffffffc02005f4:	00004517          	auipc	a0,0x4
ffffffffc02005f8:	41c50513          	addi	a0,a0,1052 # ffffffffc0204a10 <commands+0x568>
ffffffffc02005fc:	ac3ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200600:	602c                	ld	a1,64(s0)
ffffffffc0200602:	00004517          	auipc	a0,0x4
ffffffffc0200606:	42650513          	addi	a0,a0,1062 # ffffffffc0204a28 <commands+0x580>
ffffffffc020060a:	ab5ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc020060e:	642c                	ld	a1,72(s0)
ffffffffc0200610:	00004517          	auipc	a0,0x4
ffffffffc0200614:	43050513          	addi	a0,a0,1072 # ffffffffc0204a40 <commands+0x598>
ffffffffc0200618:	aa7ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc020061c:	682c                	ld	a1,80(s0)
ffffffffc020061e:	00004517          	auipc	a0,0x4
ffffffffc0200622:	43a50513          	addi	a0,a0,1082 # ffffffffc0204a58 <commands+0x5b0>
ffffffffc0200626:	a99ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc020062a:	6c2c                	ld	a1,88(s0)
ffffffffc020062c:	00004517          	auipc	a0,0x4
ffffffffc0200630:	44450513          	addi	a0,a0,1092 # ffffffffc0204a70 <commands+0x5c8>
ffffffffc0200634:	a8bff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200638:	702c                	ld	a1,96(s0)
ffffffffc020063a:	00004517          	auipc	a0,0x4
ffffffffc020063e:	44e50513          	addi	a0,a0,1102 # ffffffffc0204a88 <commands+0x5e0>
ffffffffc0200642:	a7dff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200646:	742c                	ld	a1,104(s0)
ffffffffc0200648:	00004517          	auipc	a0,0x4
ffffffffc020064c:	45850513          	addi	a0,a0,1112 # ffffffffc0204aa0 <commands+0x5f8>
ffffffffc0200650:	a6fff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200654:	782c                	ld	a1,112(s0)
ffffffffc0200656:	00004517          	auipc	a0,0x4
ffffffffc020065a:	46250513          	addi	a0,a0,1122 # ffffffffc0204ab8 <commands+0x610>
ffffffffc020065e:	a61ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200662:	7c2c                	ld	a1,120(s0)
ffffffffc0200664:	00004517          	auipc	a0,0x4
ffffffffc0200668:	46c50513          	addi	a0,a0,1132 # ffffffffc0204ad0 <commands+0x628>
ffffffffc020066c:	a53ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200670:	604c                	ld	a1,128(s0)
ffffffffc0200672:	00004517          	auipc	a0,0x4
ffffffffc0200676:	47650513          	addi	a0,a0,1142 # ffffffffc0204ae8 <commands+0x640>
ffffffffc020067a:	a45ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc020067e:	644c                	ld	a1,136(s0)
ffffffffc0200680:	00004517          	auipc	a0,0x4
ffffffffc0200684:	48050513          	addi	a0,a0,1152 # ffffffffc0204b00 <commands+0x658>
ffffffffc0200688:	a37ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc020068c:	684c                	ld	a1,144(s0)
ffffffffc020068e:	00004517          	auipc	a0,0x4
ffffffffc0200692:	48a50513          	addi	a0,a0,1162 # ffffffffc0204b18 <commands+0x670>
ffffffffc0200696:	a29ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc020069a:	6c4c                	ld	a1,152(s0)
ffffffffc020069c:	00004517          	auipc	a0,0x4
ffffffffc02006a0:	49450513          	addi	a0,a0,1172 # ffffffffc0204b30 <commands+0x688>
ffffffffc02006a4:	a1bff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc02006a8:	704c                	ld	a1,160(s0)
ffffffffc02006aa:	00004517          	auipc	a0,0x4
ffffffffc02006ae:	49e50513          	addi	a0,a0,1182 # ffffffffc0204b48 <commands+0x6a0>
ffffffffc02006b2:	a0dff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02006b6:	744c                	ld	a1,168(s0)
ffffffffc02006b8:	00004517          	auipc	a0,0x4
ffffffffc02006bc:	4a850513          	addi	a0,a0,1192 # ffffffffc0204b60 <commands+0x6b8>
ffffffffc02006c0:	9ffff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02006c4:	784c                	ld	a1,176(s0)
ffffffffc02006c6:	00004517          	auipc	a0,0x4
ffffffffc02006ca:	4b250513          	addi	a0,a0,1202 # ffffffffc0204b78 <commands+0x6d0>
ffffffffc02006ce:	9f1ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02006d2:	7c4c                	ld	a1,184(s0)
ffffffffc02006d4:	00004517          	auipc	a0,0x4
ffffffffc02006d8:	4bc50513          	addi	a0,a0,1212 # ffffffffc0204b90 <commands+0x6e8>
ffffffffc02006dc:	9e3ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02006e0:	606c                	ld	a1,192(s0)
ffffffffc02006e2:	00004517          	auipc	a0,0x4
ffffffffc02006e6:	4c650513          	addi	a0,a0,1222 # ffffffffc0204ba8 <commands+0x700>
ffffffffc02006ea:	9d5ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02006ee:	646c                	ld	a1,200(s0)
ffffffffc02006f0:	00004517          	auipc	a0,0x4
ffffffffc02006f4:	4d050513          	addi	a0,a0,1232 # ffffffffc0204bc0 <commands+0x718>
ffffffffc02006f8:	9c7ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02006fc:	686c                	ld	a1,208(s0)
ffffffffc02006fe:	00004517          	auipc	a0,0x4
ffffffffc0200702:	4da50513          	addi	a0,a0,1242 # ffffffffc0204bd8 <commands+0x730>
ffffffffc0200706:	9b9ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc020070a:	6c6c                	ld	a1,216(s0)
ffffffffc020070c:	00004517          	auipc	a0,0x4
ffffffffc0200710:	4e450513          	addi	a0,a0,1252 # ffffffffc0204bf0 <commands+0x748>
ffffffffc0200714:	9abff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200718:	706c                	ld	a1,224(s0)
ffffffffc020071a:	00004517          	auipc	a0,0x4
ffffffffc020071e:	4ee50513          	addi	a0,a0,1262 # ffffffffc0204c08 <commands+0x760>
ffffffffc0200722:	99dff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200726:	746c                	ld	a1,232(s0)
ffffffffc0200728:	00004517          	auipc	a0,0x4
ffffffffc020072c:	4f850513          	addi	a0,a0,1272 # ffffffffc0204c20 <commands+0x778>
ffffffffc0200730:	98fff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200734:	786c                	ld	a1,240(s0)
ffffffffc0200736:	00004517          	auipc	a0,0x4
ffffffffc020073a:	50250513          	addi	a0,a0,1282 # ffffffffc0204c38 <commands+0x790>
ffffffffc020073e:	981ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200742:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200744:	6402                	ld	s0,0(sp)
ffffffffc0200746:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200748:	00004517          	auipc	a0,0x4
ffffffffc020074c:	50850513          	addi	a0,a0,1288 # ffffffffc0204c50 <commands+0x7a8>
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
ffffffffc0200760:	50c50513          	addi	a0,a0,1292 # ffffffffc0204c68 <commands+0x7c0>
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
ffffffffc0200778:	50c50513          	addi	a0,a0,1292 # ffffffffc0204c80 <commands+0x7d8>
ffffffffc020077c:	943ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200780:	10843583          	ld	a1,264(s0)
ffffffffc0200784:	00004517          	auipc	a0,0x4
ffffffffc0200788:	51450513          	addi	a0,a0,1300 # ffffffffc0204c98 <commands+0x7f0>
ffffffffc020078c:	933ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200790:	11043583          	ld	a1,272(s0)
ffffffffc0200794:	00004517          	auipc	a0,0x4
ffffffffc0200798:	51c50513          	addi	a0,a0,1308 # ffffffffc0204cb0 <commands+0x808>
ffffffffc020079c:	923ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02007a0:	11843583          	ld	a1,280(s0)
}
ffffffffc02007a4:	6402                	ld	s0,0(sp)
ffffffffc02007a6:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02007a8:	00004517          	auipc	a0,0x4
ffffffffc02007ac:	52050513          	addi	a0,a0,1312 # ffffffffc0204cc8 <commands+0x820>
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
ffffffffc02007c8:	e7870713          	addi	a4,a4,-392 # ffffffffc020463c <commands+0x194>
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
ffffffffc02007da:	0f250513          	addi	a0,a0,242 # ffffffffc02048c8 <commands+0x420>
ffffffffc02007de:	8e1ff06f          	j	ffffffffc02000be <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02007e2:	00004517          	auipc	a0,0x4
ffffffffc02007e6:	0c650513          	addi	a0,a0,198 # ffffffffc02048a8 <commands+0x400>
ffffffffc02007ea:	8d5ff06f          	j	ffffffffc02000be <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02007ee:	00004517          	auipc	a0,0x4
ffffffffc02007f2:	07a50513          	addi	a0,a0,122 # ffffffffc0204868 <commands+0x3c0>
ffffffffc02007f6:	8c9ff06f          	j	ffffffffc02000be <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc02007fa:	00004517          	auipc	a0,0x4
ffffffffc02007fe:	08e50513          	addi	a0,a0,142 # ffffffffc0204888 <commands+0x3e0>
ffffffffc0200802:	8bdff06f          	j	ffffffffc02000be <cprintf>
            break;
        case IRQ_U_EXT:
            cprintf("User software interrupt\n");
            break;
        case IRQ_S_EXT:
            cprintf("Supervisor external interrupt\n");
ffffffffc0200806:	00004517          	auipc	a0,0x4
ffffffffc020080a:	0f250513          	addi	a0,a0,242 # ffffffffc02048f8 <commands+0x450>
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
ffffffffc020084a:	0a250513          	addi	a0,a0,162 # ffffffffc02048e8 <commands+0x440>
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
ffffffffc0200862:	e0e70713          	addi	a4,a4,-498 # ffffffffc020466c <commands+0x1c4>
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
ffffffffc020087e:	fd650513          	addi	a0,a0,-42 # ffffffffc0204850 <commands+0x3a8>
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
ffffffffc02008a0:	e1450513          	addi	a0,a0,-492 # ffffffffc02046b0 <commands+0x208>
}
ffffffffc02008a4:	6442                	ld	s0,16(sp)
ffffffffc02008a6:	60e2                	ld	ra,24(sp)
ffffffffc02008a8:	64a2                	ld	s1,8(sp)
ffffffffc02008aa:	6105                	addi	sp,sp,32
            cprintf("Instruction access fault\n");
ffffffffc02008ac:	813ff06f          	j	ffffffffc02000be <cprintf>
ffffffffc02008b0:	00004517          	auipc	a0,0x4
ffffffffc02008b4:	e2050513          	addi	a0,a0,-480 # ffffffffc02046d0 <commands+0x228>
ffffffffc02008b8:	b7f5                	j	ffffffffc02008a4 <exception_handler+0x50>
            cprintf("Illegal instruction\n");
ffffffffc02008ba:	00004517          	auipc	a0,0x4
ffffffffc02008be:	e3650513          	addi	a0,a0,-458 # ffffffffc02046f0 <commands+0x248>
ffffffffc02008c2:	b7cd                	j	ffffffffc02008a4 <exception_handler+0x50>
            cprintf("Breakpoint\n");
ffffffffc02008c4:	00004517          	auipc	a0,0x4
ffffffffc02008c8:	e4450513          	addi	a0,a0,-444 # ffffffffc0204708 <commands+0x260>
ffffffffc02008cc:	bfe1                	j	ffffffffc02008a4 <exception_handler+0x50>
            cprintf("Load address misaligned\n");
ffffffffc02008ce:	00004517          	auipc	a0,0x4
ffffffffc02008d2:	e4a50513          	addi	a0,a0,-438 # ffffffffc0204718 <commands+0x270>
ffffffffc02008d6:	b7f9                	j	ffffffffc02008a4 <exception_handler+0x50>
            cprintf("Load access fault\n");
ffffffffc02008d8:	00004517          	auipc	a0,0x4
ffffffffc02008dc:	e6050513          	addi	a0,a0,-416 # ffffffffc0204738 <commands+0x290>
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
ffffffffc02008fa:	e5a60613          	addi	a2,a2,-422 # ffffffffc0204750 <commands+0x2a8>
ffffffffc02008fe:	0ca00593          	li	a1,202
ffffffffc0200902:	00004517          	auipc	a0,0x4
ffffffffc0200906:	04e50513          	addi	a0,a0,78 # ffffffffc0204950 <commands+0x4a8>
ffffffffc020090a:	ffaff0ef          	jal	ra,ffffffffc0200104 <__panic>
            cprintf("AMO address misaligned\n");
ffffffffc020090e:	00004517          	auipc	a0,0x4
ffffffffc0200912:	e6250513          	addi	a0,a0,-414 # ffffffffc0204770 <commands+0x2c8>
ffffffffc0200916:	b779                	j	ffffffffc02008a4 <exception_handler+0x50>
            cprintf("Store/AMO access fault\n");
ffffffffc0200918:	00004517          	auipc	a0,0x4
ffffffffc020091c:	e7050513          	addi	a0,a0,-400 # ffffffffc0204788 <commands+0x2e0>
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
ffffffffc020093a:	e1a60613          	addi	a2,a2,-486 # ffffffffc0204750 <commands+0x2a8>
ffffffffc020093e:	0d400593          	li	a1,212
ffffffffc0200942:	00004517          	auipc	a0,0x4
ffffffffc0200946:	00e50513          	addi	a0,a0,14 # ffffffffc0204950 <commands+0x4a8>
ffffffffc020094a:	fbaff0ef          	jal	ra,ffffffffc0200104 <__panic>
            cprintf("Environment call from U-mode\n");
ffffffffc020094e:	00004517          	auipc	a0,0x4
ffffffffc0200952:	e5250513          	addi	a0,a0,-430 # ffffffffc02047a0 <commands+0x2f8>
ffffffffc0200956:	b7b9                	j	ffffffffc02008a4 <exception_handler+0x50>
            cprintf("Environment call from S-mode\n");
ffffffffc0200958:	00004517          	auipc	a0,0x4
ffffffffc020095c:	e6850513          	addi	a0,a0,-408 # ffffffffc02047c0 <commands+0x318>
ffffffffc0200960:	b791                	j	ffffffffc02008a4 <exception_handler+0x50>
            cprintf("Environment call from H-mode\n");
ffffffffc0200962:	00004517          	auipc	a0,0x4
ffffffffc0200966:	e7e50513          	addi	a0,a0,-386 # ffffffffc02047e0 <commands+0x338>
ffffffffc020096a:	bf2d                	j	ffffffffc02008a4 <exception_handler+0x50>
            cprintf("Environment call from M-mode\n");
ffffffffc020096c:	00004517          	auipc	a0,0x4
ffffffffc0200970:	e9450513          	addi	a0,a0,-364 # ffffffffc0204800 <commands+0x358>
ffffffffc0200974:	bf05                	j	ffffffffc02008a4 <exception_handler+0x50>
            cprintf("Instruction page fault\n");
ffffffffc0200976:	00004517          	auipc	a0,0x4
ffffffffc020097a:	eaa50513          	addi	a0,a0,-342 # ffffffffc0204820 <commands+0x378>
ffffffffc020097e:	b71d                	j	ffffffffc02008a4 <exception_handler+0x50>
            cprintf("Load page fault\n");
ffffffffc0200980:	00004517          	auipc	a0,0x4
ffffffffc0200984:	eb850513          	addi	a0,a0,-328 # ffffffffc0204838 <commands+0x390>
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
ffffffffc02009a4:	db060613          	addi	a2,a2,-592 # ffffffffc0204750 <commands+0x2a8>
ffffffffc02009a8:	0ea00593          	li	a1,234
ffffffffc02009ac:	00004517          	auipc	a0,0x4
ffffffffc02009b0:	fa450513          	addi	a0,a0,-92 # ffffffffc0204950 <commands+0x4a8>
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
ffffffffc02009d0:	d8460613          	addi	a2,a2,-636 # ffffffffc0204750 <commands+0x2a8>
ffffffffc02009d4:	0f100593          	li	a1,241
ffffffffc02009d8:	00004517          	auipc	a0,0x4
ffffffffc02009dc:	f7850513          	addi	a0,a0,-136 # ffffffffc0204950 <commands+0x4a8>
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
ffffffffc0200ab6:	2ae60613          	addi	a2,a2,686 # ffffffffc0204d60 <commands+0x8b8>
ffffffffc0200aba:	06500593          	li	a1,101
ffffffffc0200abe:	00004517          	auipc	a0,0x4
ffffffffc0200ac2:	2c250513          	addi	a0,a0,706 # ffffffffc0204d80 <commands+0x8d8>
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
ffffffffc0200ae2:	9a248493          	addi	s1,s1,-1630 # ffffffffc0211480 <pmm_manager>
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
ffffffffc0200af8:	9bca8a93          	addi	s5,s5,-1604 # ffffffffc02114b0 <check_mm_struct>
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
ffffffffc0200b1a:	3fc020ef          	jal	ra,ffffffffc0202f16 <swap_out>
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
ffffffffc0200b60:	92478793          	addi	a5,a5,-1756 # ffffffffc0211480 <pmm_manager>
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
ffffffffc0200b80:	90478793          	addi	a5,a5,-1788 # ffffffffc0211480 <pmm_manager>
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
ffffffffc0200ba6:	8de78793          	addi	a5,a5,-1826 # ffffffffc0211480 <pmm_manager>
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
ffffffffc0200bc0:	8c478793          	addi	a5,a5,-1852 # ffffffffc0211480 <pmm_manager>
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
ffffffffc0200c22:	87ab8b93          	addi	s7,s7,-1926 # ffffffffc0211498 <pages>
ffffffffc0200c26:	000bb503          	ld	a0,0(s7)
ffffffffc0200c2a:	00004797          	auipc	a5,0x4
ffffffffc0200c2e:	0b678793          	addi	a5,a5,182 # ffffffffc0204ce0 <commands+0x838>
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
ffffffffc0200c66:	82678793          	addi	a5,a5,-2010 # ffffffffc0211488 <va_pa_offset>
ffffffffc0200c6a:	639c                	ld	a5,0(a5)
ffffffffc0200c6c:	6605                	lui	a2,0x1
ffffffffc0200c6e:	4581                	li	a1,0
ffffffffc0200c70:	953e                	add	a0,a0,a5
ffffffffc0200c72:	214030ef          	jal	ra,ffffffffc0203e86 <memset>
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
ffffffffc0200ca0:	00010a97          	auipc	s5,0x10
ffffffffc0200ca4:	7e8a8a93          	addi	s5,s5,2024 # ffffffffc0211488 <va_pa_offset>
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
ffffffffc0200cd6:	7c6b8b93          	addi	s7,s7,1990 # ffffffffc0211498 <pages>
ffffffffc0200cda:	000bb503          	ld	a0,0(s7)
ffffffffc0200cde:	00004797          	auipc	a5,0x4
ffffffffc0200ce2:	00278793          	addi	a5,a5,2 # ffffffffc0204ce0 <commands+0x838>
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
ffffffffc0200d18:	16e030ef          	jal	ra,ffffffffc0203e86 <memset>
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
ffffffffc0200d78:	f7460613          	addi	a2,a2,-140 # ffffffffc0204ce8 <commands+0x840>
ffffffffc0200d7c:	10800593          	li	a1,264
ffffffffc0200d80:	00004517          	auipc	a0,0x4
ffffffffc0200d84:	f9050513          	addi	a0,a0,-112 # ffffffffc0204d10 <commands+0x868>
ffffffffc0200d88:	b7cff0ef          	jal	ra,ffffffffc0200104 <__panic>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0200d8c:	00004617          	auipc	a2,0x4
ffffffffc0200d90:	f5c60613          	addi	a2,a2,-164 # ffffffffc0204ce8 <commands+0x840>
ffffffffc0200d94:	11700593          	li	a1,279
ffffffffc0200d98:	00004517          	auipc	a0,0x4
ffffffffc0200d9c:	f7850513          	addi	a0,a0,-136 # ffffffffc0204d10 <commands+0x868>
ffffffffc0200da0:	b64ff0ef          	jal	ra,ffffffffc0200104 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0200da4:	86aa                	mv	a3,a0
ffffffffc0200da6:	00004617          	auipc	a2,0x4
ffffffffc0200daa:	f4260613          	addi	a2,a2,-190 # ffffffffc0204ce8 <commands+0x840>
ffffffffc0200dae:	11300593          	li	a1,275
ffffffffc0200db2:	00004517          	auipc	a0,0x4
ffffffffc0200db6:	f5e50513          	addi	a0,a0,-162 # ffffffffc0204d10 <commands+0x868>
ffffffffc0200dba:	b4aff0ef          	jal	ra,ffffffffc0200104 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0200dbe:	86aa                	mv	a3,a0
ffffffffc0200dc0:	00004617          	auipc	a2,0x4
ffffffffc0200dc4:	f2860613          	addi	a2,a2,-216 # ffffffffc0204ce8 <commands+0x840>
ffffffffc0200dc8:	10500593          	li	a1,261
ffffffffc0200dcc:	00004517          	auipc	a0,0x4
ffffffffc0200dd0:	f4450513          	addi	a0,a0,-188 # ffffffffc0204d10 <commands+0x868>
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
ffffffffc0200e1a:	68268693          	addi	a3,a3,1666 # ffffffffc0211498 <pages>
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
ffffffffc0200e72:	62a70713          	addi	a4,a4,1578 # ffffffffc0211498 <pages>
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
ffffffffc0200eda:	5c278793          	addi	a5,a5,1474 # ffffffffc0211498 <pages>
ffffffffc0200ede:	639c                	ld	a5,0(a5)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200ee0:	00004717          	auipc	a4,0x4
ffffffffc0200ee4:	e0070713          	addi	a4,a4,-512 # ffffffffc0204ce0 <commands+0x838>
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
ffffffffc0200f38:	56498993          	addi	s3,s3,1380 # ffffffffc0211498 <pages>
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
ffffffffc0200f7e:	06e78793          	addi	a5,a5,110 # ffffffffc0205fe8 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200f82:	638c                	ld	a1,0(a5)
{
ffffffffc0200f84:	711d                	addi	sp,sp,-96
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200f86:	00004517          	auipc	a0,0x4
ffffffffc0200f8a:	e2250513          	addi	a0,a0,-478 # ffffffffc0204da8 <commands+0x900>
{
ffffffffc0200f8e:	ec86                	sd	ra,88(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0200f90:	00010717          	auipc	a4,0x10
ffffffffc0200f94:	4ef73823          	sd	a5,1264(a4) # ffffffffc0211480 <pmm_manager>
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
ffffffffc0200fb0:	4d440413          	addi	s0,s0,1236 # ffffffffc0211480 <pmm_manager>
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
ffffffffc0200fce:	4ce90913          	addi	s2,s2,1230 # ffffffffc0211498 <pages>
ffffffffc0200fd2:	9782                	jalr	a5
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0200fd4:	57f5                	li	a5,-3
ffffffffc0200fd6:	07fa                	slli	a5,a5,0x1e
    cprintf("membegin %llx memend %llx mem_size %llx\n", mem_begin, mem_end, mem_size);
ffffffffc0200fd8:	07e006b7          	lui	a3,0x7e00
ffffffffc0200fdc:	01b99613          	slli	a2,s3,0x1b
ffffffffc0200fe0:	015a1593          	slli	a1,s4,0x15
ffffffffc0200fe4:	00004517          	auipc	a0,0x4
ffffffffc0200fe8:	ddc50513          	addi	a0,a0,-548 # ffffffffc0204dc0 <commands+0x918>
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0200fec:	00010717          	auipc	a4,0x10
ffffffffc0200ff0:	48f73e23          	sd	a5,1180(a4) # ffffffffc0211488 <va_pa_offset>
    cprintf("membegin %llx memend %llx mem_size %llx\n", mem_begin, mem_end, mem_size);
ffffffffc0200ff4:	8caff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("physcial memory map:\n");
ffffffffc0200ff8:	00004517          	auipc	a0,0x4
ffffffffc0200ffc:	df850513          	addi	a0,a0,-520 # ffffffffc0204df0 <commands+0x948>
ffffffffc0201000:	8beff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc0201004:	01b99693          	slli	a3,s3,0x1b
ffffffffc0201008:	16fd                	addi	a3,a3,-1
ffffffffc020100a:	015a1613          	slli	a2,s4,0x15
ffffffffc020100e:	07e005b7          	lui	a1,0x7e00
ffffffffc0201012:	00004517          	auipc	a0,0x4
ffffffffc0201016:	df650513          	addi	a0,a0,-522 # ffffffffc0204e08 <commands+0x960>
ffffffffc020101a:	8a4ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020101e:	777d                	lui	a4,0xfffff
ffffffffc0201020:	00011797          	auipc	a5,0x11
ffffffffc0201024:	57778793          	addi	a5,a5,1399 # ffffffffc0212597 <end+0xfff>
ffffffffc0201028:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc020102a:	00088737          	lui	a4,0x88
ffffffffc020102e:	00010697          	auipc	a3,0x10
ffffffffc0201032:	42e6b523          	sd	a4,1066(a3) # ffffffffc0211458 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201036:	00010717          	auipc	a4,0x10
ffffffffc020103a:	46f73123          	sd	a5,1122(a4) # ffffffffc0211498 <pages>
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
ffffffffc0201086:	40698993          	addi	s3,s3,1030 # ffffffffc0211488 <va_pa_offset>
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
ffffffffc02010aa:	db250513          	addi	a0,a0,-590 # ffffffffc0204e58 <commands+0x9b0>
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
ffffffffc02010d4:	3cd7b023          	sd	a3,960(a5) # ffffffffc0211490 <boot_cr3>
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
ffffffffc0201178:	0007bb03          	ld	s6,0(a5) # ffffffffc8000000 <end+0x7deea68>
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
ffffffffc02012aa:	a3aa8a93          	addi	s5,s5,-1478 # ffffffffc0204ce0 <commands+0x838>
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
ffffffffc020132a:	e6250513          	addi	a0,a0,-414 # ffffffffc0205188 <commands+0xce0>
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
ffffffffc02013d6:	eee58593          	addi	a1,a1,-274 # ffffffffc02052c0 <commands+0xe18>
ffffffffc02013da:	10000513          	li	a0,256
ffffffffc02013de:	24f020ef          	jal	ra,ffffffffc0203e2c <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02013e2:	100b8593          	addi	a1,s7,256
ffffffffc02013e6:	10000513          	li	a0,256
ffffffffc02013ea:	255020ef          	jal	ra,ffffffffc0203e3e <strcmp>
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
ffffffffc0201426:	10068023          	sb	zero,256(a3) # fffffffffffff100 <end+0x3fdedb68>
    assert(strlen((const char *)0x100) == 0);
ffffffffc020142a:	1bf020ef          	jal	ra,ffffffffc0203de8 <strlen>
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
ffffffffc02014e4:	e5850513          	addi	a0,a0,-424 # ffffffffc0205338 <commands+0xe90>
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
ffffffffc0201526:	7c660613          	addi	a2,a2,1990 # ffffffffc0204ce8 <commands+0x840>
ffffffffc020152a:	1e300593          	li	a1,483
ffffffffc020152e:	00003517          	auipc	a0,0x3
ffffffffc0201532:	7e250513          	addi	a0,a0,2018 # ffffffffc0204d10 <commands+0x868>
ffffffffc0201536:	bcffe0ef          	jal	ra,ffffffffc0200104 <__panic>
ffffffffc020153a:	00004697          	auipc	a3,0x4
ffffffffc020153e:	c6e68693          	addi	a3,a3,-914 # ffffffffc02051a8 <commands+0xd00>
ffffffffc0201542:	00004617          	auipc	a2,0x4
ffffffffc0201546:	95660613          	addi	a2,a2,-1706 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc020154a:	1e300593          	li	a1,483
ffffffffc020154e:	00003517          	auipc	a0,0x3
ffffffffc0201552:	7c250513          	addi	a0,a0,1986 # ffffffffc0204d10 <commands+0x868>
ffffffffc0201556:	baffe0ef          	jal	ra,ffffffffc0200104 <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc020155a:	00004697          	auipc	a3,0x4
ffffffffc020155e:	c8e68693          	addi	a3,a3,-882 # ffffffffc02051e8 <commands+0xd40>
ffffffffc0201562:	00004617          	auipc	a2,0x4
ffffffffc0201566:	93660613          	addi	a2,a2,-1738 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc020156a:	1e400593          	li	a1,484
ffffffffc020156e:	00003517          	auipc	a0,0x3
ffffffffc0201572:	7a250513          	addi	a0,a0,1954 # ffffffffc0204d10 <commands+0x868>
ffffffffc0201576:	b8ffe0ef          	jal	ra,ffffffffc0200104 <__panic>
ffffffffc020157a:	d36ff0ef          	jal	ra,ffffffffc0200ab0 <pa2page.part.4>
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc020157e:	00003617          	auipc	a2,0x3
ffffffffc0201582:	76a60613          	addi	a2,a2,1898 # ffffffffc0204ce8 <commands+0x840>
ffffffffc0201586:	06a00593          	li	a1,106
ffffffffc020158a:	00003517          	auipc	a0,0x3
ffffffffc020158e:	7f650513          	addi	a0,a0,2038 # ffffffffc0204d80 <commands+0x8d8>
ffffffffc0201592:	b73fe0ef          	jal	ra,ffffffffc0200104 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0201596:	00004617          	auipc	a2,0x4
ffffffffc020159a:	9da60613          	addi	a2,a2,-1574 # ffffffffc0204f70 <commands+0xac8>
ffffffffc020159e:	07000593          	li	a1,112
ffffffffc02015a2:	00003517          	auipc	a0,0x3
ffffffffc02015a6:	7de50513          	addi	a0,a0,2014 # ffffffffc0204d80 <commands+0x8d8>
ffffffffc02015aa:	b5bfe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc02015ae:	00004697          	auipc	a3,0x4
ffffffffc02015b2:	90268693          	addi	a3,a3,-1790 # ffffffffc0204eb0 <commands+0xa08>
ffffffffc02015b6:	00004617          	auipc	a2,0x4
ffffffffc02015ba:	8e260613          	addi	a2,a2,-1822 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc02015be:	1a700593          	li	a1,423
ffffffffc02015c2:	00003517          	auipc	a0,0x3
ffffffffc02015c6:	74e50513          	addi	a0,a0,1870 # ffffffffc0204d10 <commands+0x868>
ffffffffc02015ca:	b3bfe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc02015ce:	00004697          	auipc	a3,0x4
ffffffffc02015d2:	91a68693          	addi	a3,a3,-1766 # ffffffffc0204ee8 <commands+0xa40>
ffffffffc02015d6:	00004617          	auipc	a2,0x4
ffffffffc02015da:	8c260613          	addi	a2,a2,-1854 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc02015de:	1a800593          	li	a1,424
ffffffffc02015e2:	00003517          	auipc	a0,0x3
ffffffffc02015e6:	72e50513          	addi	a0,a0,1838 # ffffffffc0204d10 <commands+0x868>
ffffffffc02015ea:	b1bfe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc02015ee:	00004697          	auipc	a3,0x4
ffffffffc02015f2:	b7268693          	addi	a3,a3,-1166 # ffffffffc0205160 <commands+0xcb8>
ffffffffc02015f6:	00004617          	auipc	a2,0x4
ffffffffc02015fa:	8a260613          	addi	a2,a2,-1886 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc02015fe:	1d400593          	li	a1,468
ffffffffc0201602:	00003517          	auipc	a0,0x3
ffffffffc0201606:	70e50513          	addi	a0,a0,1806 # ffffffffc0204d10 <commands+0x868>
ffffffffc020160a:	afbfe0ef          	jal	ra,ffffffffc0200104 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020160e:	00004617          	auipc	a2,0x4
ffffffffc0201612:	82260613          	addi	a2,a2,-2014 # ffffffffc0204e30 <commands+0x988>
ffffffffc0201616:	08200593          	li	a1,130
ffffffffc020161a:	00003517          	auipc	a0,0x3
ffffffffc020161e:	6f650513          	addi	a0,a0,1782 # ffffffffc0204d10 <commands+0x868>
ffffffffc0201622:	ae3fe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc0201626:	00004697          	auipc	a3,0x4
ffffffffc020162a:	91a68693          	addi	a3,a3,-1766 # ffffffffc0204f40 <commands+0xa98>
ffffffffc020162e:	00004617          	auipc	a2,0x4
ffffffffc0201632:	86a60613          	addi	a2,a2,-1942 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0201636:	1ae00593          	li	a1,430
ffffffffc020163a:	00003517          	auipc	a0,0x3
ffffffffc020163e:	6d650513          	addi	a0,a0,1750 # ffffffffc0204d10 <commands+0x868>
ffffffffc0201642:	ac3fe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc0201646:	00004697          	auipc	a3,0x4
ffffffffc020164a:	8ca68693          	addi	a3,a3,-1846 # ffffffffc0204f10 <commands+0xa68>
ffffffffc020164e:	00004617          	auipc	a2,0x4
ffffffffc0201652:	84a60613          	addi	a2,a2,-1974 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0201656:	1ac00593          	li	a1,428
ffffffffc020165a:	00003517          	auipc	a0,0x3
ffffffffc020165e:	6b650513          	addi	a0,a0,1718 # ffffffffc0204d10 <commands+0x868>
ffffffffc0201662:	aa3fe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(*ptep & PTE_U);
ffffffffc0201666:	00004697          	auipc	a3,0x4
ffffffffc020166a:	9f268693          	addi	a3,a3,-1550 # ffffffffc0205058 <commands+0xbb0>
ffffffffc020166e:	00004617          	auipc	a2,0x4
ffffffffc0201672:	82a60613          	addi	a2,a2,-2006 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0201676:	1b900593          	li	a1,441
ffffffffc020167a:	00003517          	auipc	a0,0x3
ffffffffc020167e:	69650513          	addi	a0,a0,1686 # ffffffffc0204d10 <commands+0x868>
ffffffffc0201682:	a83fe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0201686:	00004697          	auipc	a3,0x4
ffffffffc020168a:	9a268693          	addi	a3,a3,-1630 # ffffffffc0205028 <commands+0xb80>
ffffffffc020168e:	00004617          	auipc	a2,0x4
ffffffffc0201692:	80a60613          	addi	a2,a2,-2038 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0201696:	1b800593          	li	a1,440
ffffffffc020169a:	00003517          	auipc	a0,0x3
ffffffffc020169e:	67650513          	addi	a0,a0,1654 # ffffffffc0204d10 <commands+0x868>
ffffffffc02016a2:	a63fe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02016a6:	00004697          	auipc	a3,0x4
ffffffffc02016aa:	94a68693          	addi	a3,a3,-1718 # ffffffffc0204ff0 <commands+0xb48>
ffffffffc02016ae:	00003617          	auipc	a2,0x3
ffffffffc02016b2:	7ea60613          	addi	a2,a2,2026 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc02016b6:	1b700593          	li	a1,439
ffffffffc02016ba:	00003517          	auipc	a0,0x3
ffffffffc02016be:	65650513          	addi	a0,a0,1622 # ffffffffc0204d10 <commands+0x868>
ffffffffc02016c2:	a43fe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc02016c6:	00004697          	auipc	a3,0x4
ffffffffc02016ca:	90268693          	addi	a3,a3,-1790 # ffffffffc0204fc8 <commands+0xb20>
ffffffffc02016ce:	00003617          	auipc	a2,0x3
ffffffffc02016d2:	7ca60613          	addi	a2,a2,1994 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc02016d6:	1b400593          	li	a1,436
ffffffffc02016da:	00003517          	auipc	a0,0x3
ffffffffc02016de:	63650513          	addi	a0,a0,1590 # ffffffffc0204d10 <commands+0x868>
ffffffffc02016e2:	a23fe0ef          	jal	ra,ffffffffc0200104 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02016e6:	86da                	mv	a3,s6
ffffffffc02016e8:	00003617          	auipc	a2,0x3
ffffffffc02016ec:	60060613          	addi	a2,a2,1536 # ffffffffc0204ce8 <commands+0x840>
ffffffffc02016f0:	1b300593          	li	a1,435
ffffffffc02016f4:	00003517          	auipc	a0,0x3
ffffffffc02016f8:	61c50513          	addi	a0,a0,1564 # ffffffffc0204d10 <commands+0x868>
ffffffffc02016fc:	a09fe0ef          	jal	ra,ffffffffc0200104 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc0201700:	86be                	mv	a3,a5
ffffffffc0201702:	00003617          	auipc	a2,0x3
ffffffffc0201706:	5e660613          	addi	a2,a2,1510 # ffffffffc0204ce8 <commands+0x840>
ffffffffc020170a:	1b200593          	li	a1,434
ffffffffc020170e:	00003517          	auipc	a0,0x3
ffffffffc0201712:	60250513          	addi	a0,a0,1538 # ffffffffc0204d10 <commands+0x868>
ffffffffc0201716:	9effe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc020171a:	00004697          	auipc	a3,0x4
ffffffffc020171e:	89668693          	addi	a3,a3,-1898 # ffffffffc0204fb0 <commands+0xb08>
ffffffffc0201722:	00003617          	auipc	a2,0x3
ffffffffc0201726:	77660613          	addi	a2,a2,1910 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc020172a:	1b000593          	li	a1,432
ffffffffc020172e:	00003517          	auipc	a0,0x3
ffffffffc0201732:	5e250513          	addi	a0,a0,1506 # ffffffffc0204d10 <commands+0x868>
ffffffffc0201736:	9cffe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc020173a:	00004697          	auipc	a3,0x4
ffffffffc020173e:	85e68693          	addi	a3,a3,-1954 # ffffffffc0204f98 <commands+0xaf0>
ffffffffc0201742:	00003617          	auipc	a2,0x3
ffffffffc0201746:	75660613          	addi	a2,a2,1878 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc020174a:	1af00593          	li	a1,431
ffffffffc020174e:	00003517          	auipc	a0,0x3
ffffffffc0201752:	5c250513          	addi	a0,a0,1474 # ffffffffc0204d10 <commands+0x868>
ffffffffc0201756:	9affe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc020175a:	00004697          	auipc	a3,0x4
ffffffffc020175e:	83e68693          	addi	a3,a3,-1986 # ffffffffc0204f98 <commands+0xaf0>
ffffffffc0201762:	00003617          	auipc	a2,0x3
ffffffffc0201766:	73660613          	addi	a2,a2,1846 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc020176a:	1c200593          	li	a1,450
ffffffffc020176e:	00003517          	auipc	a0,0x3
ffffffffc0201772:	5a250513          	addi	a0,a0,1442 # ffffffffc0204d10 <commands+0x868>
ffffffffc0201776:	98ffe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc020177a:	00004697          	auipc	a3,0x4
ffffffffc020177e:	8ae68693          	addi	a3,a3,-1874 # ffffffffc0205028 <commands+0xb80>
ffffffffc0201782:	00003617          	auipc	a2,0x3
ffffffffc0201786:	71660613          	addi	a2,a2,1814 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc020178a:	1c100593          	li	a1,449
ffffffffc020178e:	00003517          	auipc	a0,0x3
ffffffffc0201792:	58250513          	addi	a0,a0,1410 # ffffffffc0204d10 <commands+0x868>
ffffffffc0201796:	96ffe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020179a:	00004697          	auipc	a3,0x4
ffffffffc020179e:	95668693          	addi	a3,a3,-1706 # ffffffffc02050f0 <commands+0xc48>
ffffffffc02017a2:	00003617          	auipc	a2,0x3
ffffffffc02017a6:	6f660613          	addi	a2,a2,1782 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc02017aa:	1c000593          	li	a1,448
ffffffffc02017ae:	00003517          	auipc	a0,0x3
ffffffffc02017b2:	56250513          	addi	a0,a0,1378 # ffffffffc0204d10 <commands+0x868>
ffffffffc02017b6:	94ffe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc02017ba:	00004697          	auipc	a3,0x4
ffffffffc02017be:	91e68693          	addi	a3,a3,-1762 # ffffffffc02050d8 <commands+0xc30>
ffffffffc02017c2:	00003617          	auipc	a2,0x3
ffffffffc02017c6:	6d660613          	addi	a2,a2,1750 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc02017ca:	1bf00593          	li	a1,447
ffffffffc02017ce:	00003517          	auipc	a0,0x3
ffffffffc02017d2:	54250513          	addi	a0,a0,1346 # ffffffffc0204d10 <commands+0x868>
ffffffffc02017d6:	92ffe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc02017da:	00004697          	auipc	a3,0x4
ffffffffc02017de:	8ce68693          	addi	a3,a3,-1842 # ffffffffc02050a8 <commands+0xc00>
ffffffffc02017e2:	00003617          	auipc	a2,0x3
ffffffffc02017e6:	6b660613          	addi	a2,a2,1718 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc02017ea:	1be00593          	li	a1,446
ffffffffc02017ee:	00003517          	auipc	a0,0x3
ffffffffc02017f2:	52250513          	addi	a0,a0,1314 # ffffffffc0204d10 <commands+0x868>
ffffffffc02017f6:	90ffe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc02017fa:	00004697          	auipc	a3,0x4
ffffffffc02017fe:	89668693          	addi	a3,a3,-1898 # ffffffffc0205090 <commands+0xbe8>
ffffffffc0201802:	00003617          	auipc	a2,0x3
ffffffffc0201806:	69660613          	addi	a2,a2,1686 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc020180a:	1bc00593          	li	a1,444
ffffffffc020180e:	00003517          	auipc	a0,0x3
ffffffffc0201812:	50250513          	addi	a0,a0,1282 # ffffffffc0204d10 <commands+0x868>
ffffffffc0201816:	8effe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc020181a:	00004697          	auipc	a3,0x4
ffffffffc020181e:	85e68693          	addi	a3,a3,-1954 # ffffffffc0205078 <commands+0xbd0>
ffffffffc0201822:	00003617          	auipc	a2,0x3
ffffffffc0201826:	67660613          	addi	a2,a2,1654 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc020182a:	1bb00593          	li	a1,443
ffffffffc020182e:	00003517          	auipc	a0,0x3
ffffffffc0201832:	4e250513          	addi	a0,a0,1250 # ffffffffc0204d10 <commands+0x868>
ffffffffc0201836:	8cffe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(*ptep & PTE_W);
ffffffffc020183a:	00004697          	auipc	a3,0x4
ffffffffc020183e:	82e68693          	addi	a3,a3,-2002 # ffffffffc0205068 <commands+0xbc0>
ffffffffc0201842:	00003617          	auipc	a2,0x3
ffffffffc0201846:	65660613          	addi	a2,a2,1622 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc020184a:	1ba00593          	li	a1,442
ffffffffc020184e:	00003517          	auipc	a0,0x3
ffffffffc0201852:	4c250513          	addi	a0,a0,1218 # ffffffffc0204d10 <commands+0x868>
ffffffffc0201856:	8affe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc020185a:	00004697          	auipc	a3,0x4
ffffffffc020185e:	90668693          	addi	a3,a3,-1786 # ffffffffc0205160 <commands+0xcb8>
ffffffffc0201862:	00003617          	auipc	a2,0x3
ffffffffc0201866:	63660613          	addi	a2,a2,1590 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc020186a:	1fd00593          	li	a1,509
ffffffffc020186e:	00003517          	auipc	a0,0x3
ffffffffc0201872:	4a250513          	addi	a0,a0,1186 # ffffffffc0204d10 <commands+0x868>
ffffffffc0201876:	88ffe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc020187a:	00004697          	auipc	a3,0x4
ffffffffc020187e:	a9668693          	addi	a3,a3,-1386 # ffffffffc0205310 <commands+0xe68>
ffffffffc0201882:	00003617          	auipc	a2,0x3
ffffffffc0201886:	61660613          	addi	a2,a2,1558 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc020188a:	1f500593          	li	a1,501
ffffffffc020188e:	00003517          	auipc	a0,0x3
ffffffffc0201892:	48250513          	addi	a0,a0,1154 # ffffffffc0204d10 <commands+0x868>
ffffffffc0201896:	86ffe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc020189a:	00004697          	auipc	a3,0x4
ffffffffc020189e:	a3e68693          	addi	a3,a3,-1474 # ffffffffc02052d8 <commands+0xe30>
ffffffffc02018a2:	00003617          	auipc	a2,0x3
ffffffffc02018a6:	5f660613          	addi	a2,a2,1526 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc02018aa:	1f200593          	li	a1,498
ffffffffc02018ae:	00003517          	auipc	a0,0x3
ffffffffc02018b2:	46250513          	addi	a0,a0,1122 # ffffffffc0204d10 <commands+0x868>
ffffffffc02018b6:	84ffe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(page_ref(p) == 2);
ffffffffc02018ba:	00004697          	auipc	a3,0x4
ffffffffc02018be:	9ee68693          	addi	a3,a3,-1554 # ffffffffc02052a8 <commands+0xe00>
ffffffffc02018c2:	00003617          	auipc	a2,0x3
ffffffffc02018c6:	5d660613          	addi	a2,a2,1494 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc02018ca:	1ee00593          	li	a1,494
ffffffffc02018ce:	00003517          	auipc	a0,0x3
ffffffffc02018d2:	44250513          	addi	a0,a0,1090 # ffffffffc0204d10 <commands+0x868>
ffffffffc02018d6:	82ffe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc02018da:	00004697          	auipc	a3,0x4
ffffffffc02018de:	84668693          	addi	a3,a3,-1978 # ffffffffc0205120 <commands+0xc78>
ffffffffc02018e2:	00003617          	auipc	a2,0x3
ffffffffc02018e6:	5b660613          	addi	a2,a2,1462 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc02018ea:	1ca00593          	li	a1,458
ffffffffc02018ee:	00003517          	auipc	a0,0x3
ffffffffc02018f2:	42250513          	addi	a0,a0,1058 # ffffffffc0204d10 <commands+0x868>
ffffffffc02018f6:	80ffe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02018fa:	00003697          	auipc	a3,0x3
ffffffffc02018fe:	7f668693          	addi	a3,a3,2038 # ffffffffc02050f0 <commands+0xc48>
ffffffffc0201902:	00003617          	auipc	a2,0x3
ffffffffc0201906:	59660613          	addi	a2,a2,1430 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc020190a:	1c700593          	li	a1,455
ffffffffc020190e:	00003517          	auipc	a0,0x3
ffffffffc0201912:	40250513          	addi	a0,a0,1026 # ffffffffc0204d10 <commands+0x868>
ffffffffc0201916:	feefe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc020191a:	00003697          	auipc	a3,0x3
ffffffffc020191e:	69668693          	addi	a3,a3,1686 # ffffffffc0204fb0 <commands+0xb08>
ffffffffc0201922:	00003617          	auipc	a2,0x3
ffffffffc0201926:	57660613          	addi	a2,a2,1398 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc020192a:	1c600593          	li	a1,454
ffffffffc020192e:	00003517          	auipc	a0,0x3
ffffffffc0201932:	3e250513          	addi	a0,a0,994 # ffffffffc0204d10 <commands+0x868>
ffffffffc0201936:	fcefe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc020193a:	00003697          	auipc	a3,0x3
ffffffffc020193e:	7ce68693          	addi	a3,a3,1998 # ffffffffc0205108 <commands+0xc60>
ffffffffc0201942:	00003617          	auipc	a2,0x3
ffffffffc0201946:	55660613          	addi	a2,a2,1366 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc020194a:	1c300593          	li	a1,451
ffffffffc020194e:	00003517          	auipc	a0,0x3
ffffffffc0201952:	3c250513          	addi	a0,a0,962 # ffffffffc0204d10 <commands+0x868>
ffffffffc0201956:	faefe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc020195a:	00003697          	auipc	a3,0x3
ffffffffc020195e:	7de68693          	addi	a3,a3,2014 # ffffffffc0205138 <commands+0xc90>
ffffffffc0201962:	00003617          	auipc	a2,0x3
ffffffffc0201966:	53660613          	addi	a2,a2,1334 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc020196a:	1cd00593          	li	a1,461
ffffffffc020196e:	00003517          	auipc	a0,0x3
ffffffffc0201972:	3a250513          	addi	a0,a0,930 # ffffffffc0204d10 <commands+0x868>
ffffffffc0201976:	f8efe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020197a:	00003697          	auipc	a3,0x3
ffffffffc020197e:	77668693          	addi	a3,a3,1910 # ffffffffc02050f0 <commands+0xc48>
ffffffffc0201982:	00003617          	auipc	a2,0x3
ffffffffc0201986:	51660613          	addi	a2,a2,1302 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc020198a:	1cb00593          	li	a1,459
ffffffffc020198e:	00003517          	auipc	a0,0x3
ffffffffc0201992:	38250513          	addi	a0,a0,898 # ffffffffc0204d10 <commands+0x868>
ffffffffc0201996:	f6efe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc020199a:	00003697          	auipc	a3,0x3
ffffffffc020199e:	4de68693          	addi	a3,a3,1246 # ffffffffc0204e78 <commands+0x9d0>
ffffffffc02019a2:	00003617          	auipc	a2,0x3
ffffffffc02019a6:	4f660613          	addi	a2,a2,1270 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc02019aa:	1a600593          	li	a1,422
ffffffffc02019ae:	00003517          	auipc	a0,0x3
ffffffffc02019b2:	36250513          	addi	a0,a0,866 # ffffffffc0204d10 <commands+0x868>
ffffffffc02019b6:	f4efe0ef          	jal	ra,ffffffffc0200104 <__panic>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc02019ba:	00003617          	auipc	a2,0x3
ffffffffc02019be:	47660613          	addi	a2,a2,1142 # ffffffffc0204e30 <commands+0x988>
ffffffffc02019c2:	0c800593          	li	a1,200
ffffffffc02019c6:	00003517          	auipc	a0,0x3
ffffffffc02019ca:	34a50513          	addi	a0,a0,842 # ffffffffc0204d10 <commands+0x868>
ffffffffc02019ce:	f36fe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02019d2:	00004697          	auipc	a3,0x4
ffffffffc02019d6:	89668693          	addi	a3,a3,-1898 # ffffffffc0205268 <commands+0xdc0>
ffffffffc02019da:	00003617          	auipc	a2,0x3
ffffffffc02019de:	4be60613          	addi	a2,a2,1214 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc02019e2:	1ed00593          	li	a1,493
ffffffffc02019e6:	00003517          	auipc	a0,0x3
ffffffffc02019ea:	32a50513          	addi	a0,a0,810 # ffffffffc0204d10 <commands+0x868>
ffffffffc02019ee:	f16fe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(page_ref(p) == 1);
ffffffffc02019f2:	00004697          	auipc	a3,0x4
ffffffffc02019f6:	85e68693          	addi	a3,a3,-1954 # ffffffffc0205250 <commands+0xda8>
ffffffffc02019fa:	00003617          	auipc	a2,0x3
ffffffffc02019fe:	49e60613          	addi	a2,a2,1182 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0201a02:	1ec00593          	li	a1,492
ffffffffc0201a06:	00003517          	auipc	a0,0x3
ffffffffc0201a0a:	30a50513          	addi	a0,a0,778 # ffffffffc0204d10 <commands+0x868>
ffffffffc0201a0e:	ef6fe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0201a12:	00004697          	auipc	a3,0x4
ffffffffc0201a16:	80668693          	addi	a3,a3,-2042 # ffffffffc0205218 <commands+0xd70>
ffffffffc0201a1a:	00003617          	auipc	a2,0x3
ffffffffc0201a1e:	47e60613          	addi	a2,a2,1150 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0201a22:	1eb00593          	li	a1,491
ffffffffc0201a26:	00003517          	auipc	a0,0x3
ffffffffc0201a2a:	2ea50513          	addi	a0,a0,746 # ffffffffc0204d10 <commands+0x868>
ffffffffc0201a2e:	ed6fe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(boot_pgdir[0] == 0);
ffffffffc0201a32:	00003697          	auipc	a3,0x3
ffffffffc0201a36:	7ce68693          	addi	a3,a3,1998 # ffffffffc0205200 <commands+0xd58>
ffffffffc0201a3a:	00003617          	auipc	a2,0x3
ffffffffc0201a3e:	45e60613          	addi	a2,a2,1118 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0201a42:	1e700593          	li	a1,487
ffffffffc0201a46:	00003517          	auipc	a0,0x3
ffffffffc0201a4a:	2ca50513          	addi	a0,a0,714 # ffffffffc0204d10 <commands+0x868>
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
ffffffffc0201aa4:	a1078793          	addi	a5,a5,-1520 # ffffffffc02114b0 <check_mm_struct>
ffffffffc0201aa8:	6388                	ld	a0,0(a5)
ffffffffc0201aaa:	4681                	li	a3,0
ffffffffc0201aac:	8622                	mv	a2,s0
ffffffffc0201aae:	85a6                	mv	a1,s1
ffffffffc0201ab0:	456010ef          	jal	ra,ffffffffc0202f06 <swap_map_swappable>
            assert(page_ref(page) == 1);
ffffffffc0201ab4:	4018                	lw	a4,0(s0)
            page->pra_vaddr = la;
ffffffffc0201ab6:	e024                	sd	s1,64(s0)
            assert(page_ref(page) == 1);
ffffffffc0201ab8:	4785                	li	a5,1
ffffffffc0201aba:	fcf70be3          	beq	a4,a5,ffffffffc0201a90 <pgdir_alloc_page+0x38>
ffffffffc0201abe:	00003697          	auipc	a3,0x3
ffffffffc0201ac2:	2d268693          	addi	a3,a3,722 # ffffffffc0204d90 <commands+0x8e8>
ffffffffc0201ac6:	00003617          	auipc	a2,0x3
ffffffffc0201aca:	3d260613          	addi	a2,a2,978 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0201ace:	18c00593          	li	a1,396
ffffffffc0201ad2:	00003517          	auipc	a0,0x3
ffffffffc0201ad6:	23e50513          	addi	a0,a0,574 # ffffffffc0204d10 <commands+0x868>
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
ffffffffc0201b0c:	99078793          	addi	a5,a5,-1648 # ffffffffc0211498 <pages>
ffffffffc0201b10:	639c                	ld	a5,0(a5)
ffffffffc0201b12:	8d1d                	sub	a0,a0,a5
ffffffffc0201b14:	00003797          	auipc	a5,0x3
ffffffffc0201b18:	1cc78793          	addi	a5,a5,460 # ffffffffc0204ce0 <commands+0x838>
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
ffffffffc0201b44:	94878793          	addi	a5,a5,-1720 # ffffffffc0211488 <va_pa_offset>
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
ffffffffc0201b56:	1de68693          	addi	a3,a3,478 # ffffffffc0204d30 <commands+0x888>
ffffffffc0201b5a:	00003617          	auipc	a2,0x3
ffffffffc0201b5e:	33e60613          	addi	a2,a2,830 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0201b62:	20600593          	li	a1,518
ffffffffc0201b66:	00003517          	auipc	a0,0x3
ffffffffc0201b6a:	1aa50513          	addi	a0,a0,426 # ffffffffc0204d10 <commands+0x868>
ffffffffc0201b6e:	d96fe0ef          	jal	ra,ffffffffc0200104 <__panic>
ffffffffc0201b72:	86aa                	mv	a3,a0
ffffffffc0201b74:	00003617          	auipc	a2,0x3
ffffffffc0201b78:	17460613          	addi	a2,a2,372 # ffffffffc0204ce8 <commands+0x840>
ffffffffc0201b7c:	06a00593          	li	a1,106
ffffffffc0201b80:	00003517          	auipc	a0,0x3
ffffffffc0201b84:	20050513          	addi	a0,a0,512 # ffffffffc0204d80 <commands+0x8d8>
ffffffffc0201b88:	d7cfe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(base != NULL);
ffffffffc0201b8c:	00003697          	auipc	a3,0x3
ffffffffc0201b90:	1c468693          	addi	a3,a3,452 # ffffffffc0204d50 <commands+0x8a8>
ffffffffc0201b94:	00003617          	auipc	a2,0x3
ffffffffc0201b98:	30460613          	addi	a2,a2,772 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0201b9c:	20900593          	li	a1,521
ffffffffc0201ba0:	00003517          	auipc	a0,0x3
ffffffffc0201ba4:	17050513          	addi	a0,a0,368 # ffffffffc0204d10 <commands+0x868>
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
ffffffffc0201bd2:	8ba78793          	addi	a5,a5,-1862 # ffffffffc0211488 <va_pa_offset>
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
ffffffffc0201bf6:	8a668693          	addi	a3,a3,-1882 # ffffffffc0211498 <pages>
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
ffffffffc0201c12:	12268693          	addi	a3,a3,290 # ffffffffc0204d30 <commands+0x888>
ffffffffc0201c16:	00003617          	auipc	a2,0x3
ffffffffc0201c1a:	28260613          	addi	a2,a2,642 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0201c1e:	21000593          	li	a1,528
ffffffffc0201c22:	00003517          	auipc	a0,0x3
ffffffffc0201c26:	0ee50513          	addi	a0,a0,238 # ffffffffc0204d10 <commands+0x868>
ffffffffc0201c2a:	cdafe0ef          	jal	ra,ffffffffc0200104 <__panic>
ffffffffc0201c2e:	e83fe0ef          	jal	ra,ffffffffc0200ab0 <pa2page.part.4>
static inline struct Page *kva2page(void *kva) { return pa2page(PADDR(kva)); }
ffffffffc0201c32:	86aa                	mv	a3,a0
ffffffffc0201c34:	00003617          	auipc	a2,0x3
ffffffffc0201c38:	1fc60613          	addi	a2,a2,508 # ffffffffc0204e30 <commands+0x988>
ffffffffc0201c3c:	06c00593          	li	a1,108
ffffffffc0201c40:	00003517          	auipc	a0,0x3
ffffffffc0201c44:	14050513          	addi	a0,a0,320 # ffffffffc0204d80 <commands+0x8d8>
ffffffffc0201c48:	cbcfe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(ptr != NULL);
ffffffffc0201c4c:	00003697          	auipc	a3,0x3
ffffffffc0201c50:	0d468693          	addi	a3,a3,212 # ffffffffc0204d20 <commands+0x878>
ffffffffc0201c54:	00003617          	auipc	a2,0x3
ffffffffc0201c58:	24460613          	addi	a2,a2,580 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0201c5c:	21100593          	li	a1,529
ffffffffc0201c60:	00003517          	auipc	a0,0x3
ffffffffc0201c64:	0b050513          	addi	a0,a0,176 # ffffffffc0204d10 <commands+0x868>
ffffffffc0201c68:	c9cfe0ef          	jal	ra,ffffffffc0200104 <__panic>

ffffffffc0201c6c <_fifo_init_mm>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0201c6c:	00010797          	auipc	a5,0x10
ffffffffc0201c70:	83478793          	addi	a5,a5,-1996 # ffffffffc02114a0 <pra_list_head>
 */
static int
_fifo_init_mm(struct mm_struct *mm)
{
    list_init(&pra_list_head);
    mm->sm_priv = &pra_list_head;
ffffffffc0201c74:	f51c                	sd	a5,40(a0)
ffffffffc0201c76:	e79c                	sd	a5,8(a5)
ffffffffc0201c78:	e39c                	sd	a5,0(a5)
    // cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
    return 0;
}
ffffffffc0201c7a:	4501                	li	a0,0
ffffffffc0201c7c:	8082                	ret

ffffffffc0201c7e <_fifo_init>:

static int
_fifo_init(void)
{
    return 0;
}
ffffffffc0201c7e:	4501                	li	a0,0
ffffffffc0201c80:	8082                	ret

ffffffffc0201c82 <_fifo_set_unswappable>:

static int
_fifo_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}
ffffffffc0201c82:	4501                	li	a0,0
ffffffffc0201c84:	8082                	ret

ffffffffc0201c86 <_fifo_tick_event>:

static int
_fifo_tick_event(struct mm_struct *mm)
{
    return 0;
}
ffffffffc0201c86:	4501                	li	a0,0
ffffffffc0201c88:	8082                	ret

ffffffffc0201c8a <_fifo_check_swap>:
{
ffffffffc0201c8a:	711d                	addi	sp,sp,-96
ffffffffc0201c8c:	fc4e                	sd	s3,56(sp)
ffffffffc0201c8e:	f852                	sd	s4,48(sp)
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0201c90:	00003517          	auipc	a0,0x3
ffffffffc0201c94:	6c850513          	addi	a0,a0,1736 # ffffffffc0205358 <commands+0xeb0>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0201c98:	698d                	lui	s3,0x3
ffffffffc0201c9a:	4a31                	li	s4,12
{
ffffffffc0201c9c:	e8a2                	sd	s0,80(sp)
ffffffffc0201c9e:	e4a6                	sd	s1,72(sp)
ffffffffc0201ca0:	ec86                	sd	ra,88(sp)
ffffffffc0201ca2:	e0ca                	sd	s2,64(sp)
ffffffffc0201ca4:	f456                	sd	s5,40(sp)
ffffffffc0201ca6:	f05a                	sd	s6,32(sp)
ffffffffc0201ca8:	ec5e                	sd	s7,24(sp)
ffffffffc0201caa:	e862                	sd	s8,16(sp)
ffffffffc0201cac:	e466                	sd	s9,8(sp)
    assert(pgfault_num == 4);
ffffffffc0201cae:	0000f417          	auipc	s0,0xf
ffffffffc0201cb2:	7b240413          	addi	s0,s0,1970 # ffffffffc0211460 <pgfault_num>
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0201cb6:	c08fe0ef          	jal	ra,ffffffffc02000be <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0201cba:	01498023          	sb	s4,0(s3) # 3000 <BASE_ADDRESS-0xffffffffc01fd000>
    assert(pgfault_num == 4);
ffffffffc0201cbe:	4004                	lw	s1,0(s0)
ffffffffc0201cc0:	4791                	li	a5,4
ffffffffc0201cc2:	2481                	sext.w	s1,s1
ffffffffc0201cc4:	14f49963          	bne	s1,a5,ffffffffc0201e16 <_fifo_check_swap+0x18c>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0201cc8:	00003517          	auipc	a0,0x3
ffffffffc0201ccc:	6e850513          	addi	a0,a0,1768 # ffffffffc02053b0 <commands+0xf08>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0201cd0:	6a85                	lui	s5,0x1
ffffffffc0201cd2:	4b29                	li	s6,10
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0201cd4:	beafe0ef          	jal	ra,ffffffffc02000be <cprintf>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0201cd8:	016a8023          	sb	s6,0(s5) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
    assert(pgfault_num == 4);
ffffffffc0201cdc:	00042903          	lw	s2,0(s0)
ffffffffc0201ce0:	2901                	sext.w	s2,s2
ffffffffc0201ce2:	2a991a63          	bne	s2,s1,ffffffffc0201f96 <_fifo_check_swap+0x30c>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0201ce6:	00003517          	auipc	a0,0x3
ffffffffc0201cea:	6f250513          	addi	a0,a0,1778 # ffffffffc02053d8 <commands+0xf30>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0201cee:	6b91                	lui	s7,0x4
ffffffffc0201cf0:	4c35                	li	s8,13
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0201cf2:	bccfe0ef          	jal	ra,ffffffffc02000be <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0201cf6:	018b8023          	sb	s8,0(s7) # 4000 <BASE_ADDRESS-0xffffffffc01fc000>
    assert(pgfault_num == 4);
ffffffffc0201cfa:	4004                	lw	s1,0(s0)
ffffffffc0201cfc:	2481                	sext.w	s1,s1
ffffffffc0201cfe:	27249c63          	bne	s1,s2,ffffffffc0201f76 <_fifo_check_swap+0x2ec>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0201d02:	00003517          	auipc	a0,0x3
ffffffffc0201d06:	6fe50513          	addi	a0,a0,1790 # ffffffffc0205400 <commands+0xf58>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0201d0a:	6909                	lui	s2,0x2
ffffffffc0201d0c:	4cad                	li	s9,11
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0201d0e:	bb0fe0ef          	jal	ra,ffffffffc02000be <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0201d12:	01990023          	sb	s9,0(s2) # 2000 <BASE_ADDRESS-0xffffffffc01fe000>
    assert(pgfault_num == 4);
ffffffffc0201d16:	401c                	lw	a5,0(s0)
ffffffffc0201d18:	2781                	sext.w	a5,a5
ffffffffc0201d1a:	22979e63          	bne	a5,s1,ffffffffc0201f56 <_fifo_check_swap+0x2cc>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc0201d1e:	00003517          	auipc	a0,0x3
ffffffffc0201d22:	70a50513          	addi	a0,a0,1802 # ffffffffc0205428 <commands+0xf80>
ffffffffc0201d26:	b98fe0ef          	jal	ra,ffffffffc02000be <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0201d2a:	6795                	lui	a5,0x5
ffffffffc0201d2c:	4739                	li	a4,14
ffffffffc0201d2e:	00e78023          	sb	a4,0(a5) # 5000 <BASE_ADDRESS-0xffffffffc01fb000>
    assert(pgfault_num == 5);
ffffffffc0201d32:	4004                	lw	s1,0(s0)
ffffffffc0201d34:	4795                	li	a5,5
ffffffffc0201d36:	2481                	sext.w	s1,s1
ffffffffc0201d38:	1ef49f63          	bne	s1,a5,ffffffffc0201f36 <_fifo_check_swap+0x2ac>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0201d3c:	00003517          	auipc	a0,0x3
ffffffffc0201d40:	6c450513          	addi	a0,a0,1732 # ffffffffc0205400 <commands+0xf58>
ffffffffc0201d44:	b7afe0ef          	jal	ra,ffffffffc02000be <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0201d48:	01990023          	sb	s9,0(s2)
    assert(pgfault_num == 5);
ffffffffc0201d4c:	401c                	lw	a5,0(s0)
ffffffffc0201d4e:	2781                	sext.w	a5,a5
ffffffffc0201d50:	1c979363          	bne	a5,s1,ffffffffc0201f16 <_fifo_check_swap+0x28c>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0201d54:	00003517          	auipc	a0,0x3
ffffffffc0201d58:	65c50513          	addi	a0,a0,1628 # ffffffffc02053b0 <commands+0xf08>
ffffffffc0201d5c:	b62fe0ef          	jal	ra,ffffffffc02000be <cprintf>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0201d60:	016a8023          	sb	s6,0(s5)
    assert(pgfault_num == 6);
ffffffffc0201d64:	401c                	lw	a5,0(s0)
ffffffffc0201d66:	4719                	li	a4,6
ffffffffc0201d68:	2781                	sext.w	a5,a5
ffffffffc0201d6a:	18e79663          	bne	a5,a4,ffffffffc0201ef6 <_fifo_check_swap+0x26c>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0201d6e:	00003517          	auipc	a0,0x3
ffffffffc0201d72:	69250513          	addi	a0,a0,1682 # ffffffffc0205400 <commands+0xf58>
ffffffffc0201d76:	b48fe0ef          	jal	ra,ffffffffc02000be <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0201d7a:	01990023          	sb	s9,0(s2)
    assert(pgfault_num == 7);
ffffffffc0201d7e:	401c                	lw	a5,0(s0)
ffffffffc0201d80:	471d                	li	a4,7
ffffffffc0201d82:	2781                	sext.w	a5,a5
ffffffffc0201d84:	14e79963          	bne	a5,a4,ffffffffc0201ed6 <_fifo_check_swap+0x24c>
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0201d88:	00003517          	auipc	a0,0x3
ffffffffc0201d8c:	5d050513          	addi	a0,a0,1488 # ffffffffc0205358 <commands+0xeb0>
ffffffffc0201d90:	b2efe0ef          	jal	ra,ffffffffc02000be <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0201d94:	01498023          	sb	s4,0(s3)
    assert(pgfault_num == 8);
ffffffffc0201d98:	401c                	lw	a5,0(s0)
ffffffffc0201d9a:	4721                	li	a4,8
ffffffffc0201d9c:	2781                	sext.w	a5,a5
ffffffffc0201d9e:	10e79c63          	bne	a5,a4,ffffffffc0201eb6 <_fifo_check_swap+0x22c>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0201da2:	00003517          	auipc	a0,0x3
ffffffffc0201da6:	63650513          	addi	a0,a0,1590 # ffffffffc02053d8 <commands+0xf30>
ffffffffc0201daa:	b14fe0ef          	jal	ra,ffffffffc02000be <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0201dae:	018b8023          	sb	s8,0(s7)
    assert(pgfault_num == 9);
ffffffffc0201db2:	401c                	lw	a5,0(s0)
ffffffffc0201db4:	4725                	li	a4,9
ffffffffc0201db6:	2781                	sext.w	a5,a5
ffffffffc0201db8:	0ce79f63          	bne	a5,a4,ffffffffc0201e96 <_fifo_check_swap+0x20c>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc0201dbc:	00003517          	auipc	a0,0x3
ffffffffc0201dc0:	66c50513          	addi	a0,a0,1644 # ffffffffc0205428 <commands+0xf80>
ffffffffc0201dc4:	afafe0ef          	jal	ra,ffffffffc02000be <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0201dc8:	6795                	lui	a5,0x5
ffffffffc0201dca:	4739                	li	a4,14
ffffffffc0201dcc:	00e78023          	sb	a4,0(a5) # 5000 <BASE_ADDRESS-0xffffffffc01fb000>
    assert(pgfault_num == 10);
ffffffffc0201dd0:	4004                	lw	s1,0(s0)
ffffffffc0201dd2:	47a9                	li	a5,10
ffffffffc0201dd4:	2481                	sext.w	s1,s1
ffffffffc0201dd6:	0af49063          	bne	s1,a5,ffffffffc0201e76 <_fifo_check_swap+0x1ec>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0201dda:	00003517          	auipc	a0,0x3
ffffffffc0201dde:	5d650513          	addi	a0,a0,1494 # ffffffffc02053b0 <commands+0xf08>
ffffffffc0201de2:	adcfe0ef          	jal	ra,ffffffffc02000be <cprintf>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0201de6:	6785                	lui	a5,0x1
ffffffffc0201de8:	0007c783          	lbu	a5,0(a5) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
ffffffffc0201dec:	06979563          	bne	a5,s1,ffffffffc0201e56 <_fifo_check_swap+0x1cc>
    assert(pgfault_num == 11);
ffffffffc0201df0:	401c                	lw	a5,0(s0)
ffffffffc0201df2:	472d                	li	a4,11
ffffffffc0201df4:	2781                	sext.w	a5,a5
ffffffffc0201df6:	04e79063          	bne	a5,a4,ffffffffc0201e36 <_fifo_check_swap+0x1ac>
}
ffffffffc0201dfa:	60e6                	ld	ra,88(sp)
ffffffffc0201dfc:	6446                	ld	s0,80(sp)
ffffffffc0201dfe:	64a6                	ld	s1,72(sp)
ffffffffc0201e00:	6906                	ld	s2,64(sp)
ffffffffc0201e02:	79e2                	ld	s3,56(sp)
ffffffffc0201e04:	7a42                	ld	s4,48(sp)
ffffffffc0201e06:	7aa2                	ld	s5,40(sp)
ffffffffc0201e08:	7b02                	ld	s6,32(sp)
ffffffffc0201e0a:	6be2                	ld	s7,24(sp)
ffffffffc0201e0c:	6c42                	ld	s8,16(sp)
ffffffffc0201e0e:	6ca2                	ld	s9,8(sp)
ffffffffc0201e10:	4501                	li	a0,0
ffffffffc0201e12:	6125                	addi	sp,sp,96
ffffffffc0201e14:	8082                	ret
    assert(pgfault_num == 4);
ffffffffc0201e16:	00003697          	auipc	a3,0x3
ffffffffc0201e1a:	56a68693          	addi	a3,a3,1386 # ffffffffc0205380 <commands+0xed8>
ffffffffc0201e1e:	00003617          	auipc	a2,0x3
ffffffffc0201e22:	07a60613          	addi	a2,a2,122 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0201e26:	05200593          	li	a1,82
ffffffffc0201e2a:	00003517          	auipc	a0,0x3
ffffffffc0201e2e:	56e50513          	addi	a0,a0,1390 # ffffffffc0205398 <commands+0xef0>
ffffffffc0201e32:	ad2fe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(pgfault_num == 11);
ffffffffc0201e36:	00003697          	auipc	a3,0x3
ffffffffc0201e3a:	6d268693          	addi	a3,a3,1746 # ffffffffc0205508 <commands+0x1060>
ffffffffc0201e3e:	00003617          	auipc	a2,0x3
ffffffffc0201e42:	05a60613          	addi	a2,a2,90 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0201e46:	07400593          	li	a1,116
ffffffffc0201e4a:	00003517          	auipc	a0,0x3
ffffffffc0201e4e:	54e50513          	addi	a0,a0,1358 # ffffffffc0205398 <commands+0xef0>
ffffffffc0201e52:	ab2fe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0201e56:	00003697          	auipc	a3,0x3
ffffffffc0201e5a:	68a68693          	addi	a3,a3,1674 # ffffffffc02054e0 <commands+0x1038>
ffffffffc0201e5e:	00003617          	auipc	a2,0x3
ffffffffc0201e62:	03a60613          	addi	a2,a2,58 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0201e66:	07200593          	li	a1,114
ffffffffc0201e6a:	00003517          	auipc	a0,0x3
ffffffffc0201e6e:	52e50513          	addi	a0,a0,1326 # ffffffffc0205398 <commands+0xef0>
ffffffffc0201e72:	a92fe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(pgfault_num == 10);
ffffffffc0201e76:	00003697          	auipc	a3,0x3
ffffffffc0201e7a:	65268693          	addi	a3,a3,1618 # ffffffffc02054c8 <commands+0x1020>
ffffffffc0201e7e:	00003617          	auipc	a2,0x3
ffffffffc0201e82:	01a60613          	addi	a2,a2,26 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0201e86:	07000593          	li	a1,112
ffffffffc0201e8a:	00003517          	auipc	a0,0x3
ffffffffc0201e8e:	50e50513          	addi	a0,a0,1294 # ffffffffc0205398 <commands+0xef0>
ffffffffc0201e92:	a72fe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(pgfault_num == 9);
ffffffffc0201e96:	00003697          	auipc	a3,0x3
ffffffffc0201e9a:	61a68693          	addi	a3,a3,1562 # ffffffffc02054b0 <commands+0x1008>
ffffffffc0201e9e:	00003617          	auipc	a2,0x3
ffffffffc0201ea2:	ffa60613          	addi	a2,a2,-6 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0201ea6:	06d00593          	li	a1,109
ffffffffc0201eaa:	00003517          	auipc	a0,0x3
ffffffffc0201eae:	4ee50513          	addi	a0,a0,1262 # ffffffffc0205398 <commands+0xef0>
ffffffffc0201eb2:	a52fe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(pgfault_num == 8);
ffffffffc0201eb6:	00003697          	auipc	a3,0x3
ffffffffc0201eba:	5e268693          	addi	a3,a3,1506 # ffffffffc0205498 <commands+0xff0>
ffffffffc0201ebe:	00003617          	auipc	a2,0x3
ffffffffc0201ec2:	fda60613          	addi	a2,a2,-38 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0201ec6:	06a00593          	li	a1,106
ffffffffc0201eca:	00003517          	auipc	a0,0x3
ffffffffc0201ece:	4ce50513          	addi	a0,a0,1230 # ffffffffc0205398 <commands+0xef0>
ffffffffc0201ed2:	a32fe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(pgfault_num == 7);
ffffffffc0201ed6:	00003697          	auipc	a3,0x3
ffffffffc0201eda:	5aa68693          	addi	a3,a3,1450 # ffffffffc0205480 <commands+0xfd8>
ffffffffc0201ede:	00003617          	auipc	a2,0x3
ffffffffc0201ee2:	fba60613          	addi	a2,a2,-70 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0201ee6:	06700593          	li	a1,103
ffffffffc0201eea:	00003517          	auipc	a0,0x3
ffffffffc0201eee:	4ae50513          	addi	a0,a0,1198 # ffffffffc0205398 <commands+0xef0>
ffffffffc0201ef2:	a12fe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(pgfault_num == 6);
ffffffffc0201ef6:	00003697          	auipc	a3,0x3
ffffffffc0201efa:	57268693          	addi	a3,a3,1394 # ffffffffc0205468 <commands+0xfc0>
ffffffffc0201efe:	00003617          	auipc	a2,0x3
ffffffffc0201f02:	f9a60613          	addi	a2,a2,-102 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0201f06:	06400593          	li	a1,100
ffffffffc0201f0a:	00003517          	auipc	a0,0x3
ffffffffc0201f0e:	48e50513          	addi	a0,a0,1166 # ffffffffc0205398 <commands+0xef0>
ffffffffc0201f12:	9f2fe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(pgfault_num == 5);
ffffffffc0201f16:	00003697          	auipc	a3,0x3
ffffffffc0201f1a:	53a68693          	addi	a3,a3,1338 # ffffffffc0205450 <commands+0xfa8>
ffffffffc0201f1e:	00003617          	auipc	a2,0x3
ffffffffc0201f22:	f7a60613          	addi	a2,a2,-134 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0201f26:	06100593          	li	a1,97
ffffffffc0201f2a:	00003517          	auipc	a0,0x3
ffffffffc0201f2e:	46e50513          	addi	a0,a0,1134 # ffffffffc0205398 <commands+0xef0>
ffffffffc0201f32:	9d2fe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(pgfault_num == 5);
ffffffffc0201f36:	00003697          	auipc	a3,0x3
ffffffffc0201f3a:	51a68693          	addi	a3,a3,1306 # ffffffffc0205450 <commands+0xfa8>
ffffffffc0201f3e:	00003617          	auipc	a2,0x3
ffffffffc0201f42:	f5a60613          	addi	a2,a2,-166 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0201f46:	05e00593          	li	a1,94
ffffffffc0201f4a:	00003517          	auipc	a0,0x3
ffffffffc0201f4e:	44e50513          	addi	a0,a0,1102 # ffffffffc0205398 <commands+0xef0>
ffffffffc0201f52:	9b2fe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(pgfault_num == 4);
ffffffffc0201f56:	00003697          	auipc	a3,0x3
ffffffffc0201f5a:	42a68693          	addi	a3,a3,1066 # ffffffffc0205380 <commands+0xed8>
ffffffffc0201f5e:	00003617          	auipc	a2,0x3
ffffffffc0201f62:	f3a60613          	addi	a2,a2,-198 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0201f66:	05b00593          	li	a1,91
ffffffffc0201f6a:	00003517          	auipc	a0,0x3
ffffffffc0201f6e:	42e50513          	addi	a0,a0,1070 # ffffffffc0205398 <commands+0xef0>
ffffffffc0201f72:	992fe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(pgfault_num == 4);
ffffffffc0201f76:	00003697          	auipc	a3,0x3
ffffffffc0201f7a:	40a68693          	addi	a3,a3,1034 # ffffffffc0205380 <commands+0xed8>
ffffffffc0201f7e:	00003617          	auipc	a2,0x3
ffffffffc0201f82:	f1a60613          	addi	a2,a2,-230 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0201f86:	05800593          	li	a1,88
ffffffffc0201f8a:	00003517          	auipc	a0,0x3
ffffffffc0201f8e:	40e50513          	addi	a0,a0,1038 # ffffffffc0205398 <commands+0xef0>
ffffffffc0201f92:	972fe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(pgfault_num == 4);
ffffffffc0201f96:	00003697          	auipc	a3,0x3
ffffffffc0201f9a:	3ea68693          	addi	a3,a3,1002 # ffffffffc0205380 <commands+0xed8>
ffffffffc0201f9e:	00003617          	auipc	a2,0x3
ffffffffc0201fa2:	efa60613          	addi	a2,a2,-262 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0201fa6:	05500593          	li	a1,85
ffffffffc0201faa:	00003517          	auipc	a0,0x3
ffffffffc0201fae:	3ee50513          	addi	a0,a0,1006 # ffffffffc0205398 <commands+0xef0>
ffffffffc0201fb2:	952fe0ef          	jal	ra,ffffffffc0200104 <__panic>

ffffffffc0201fb6 <_fifo_swap_out_victim>:
    list_entry_t *head = (list_entry_t *)mm->sm_priv;
ffffffffc0201fb6:	7518                	ld	a4,40(a0)
{
ffffffffc0201fb8:	1141                	addi	sp,sp,-16
ffffffffc0201fba:	e406                	sd	ra,8(sp)
    assert(head != NULL);
ffffffffc0201fbc:	c731                	beqz	a4,ffffffffc0202008 <_fifo_swap_out_victim+0x52>
    assert(in_tick == 0);
ffffffffc0201fbe:	e60d                	bnez	a2,ffffffffc0201fe8 <_fifo_swap_out_victim+0x32>
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc0201fc0:	631c                	ld	a5,0(a4)
    if (entry != head)
ffffffffc0201fc2:	00f70d63          	beq	a4,a5,ffffffffc0201fdc <_fifo_swap_out_victim+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc0201fc6:	6394                	ld	a3,0(a5)
ffffffffc0201fc8:	6798                	ld	a4,8(a5)
}
ffffffffc0201fca:	60a2                	ld	ra,8(sp)
        *ptr_page = le2page(entry, pra_page_link);
ffffffffc0201fcc:	fd078793          	addi	a5,a5,-48
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201fd0:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc0201fd2:	e314                	sd	a3,0(a4)
ffffffffc0201fd4:	e19c                	sd	a5,0(a1)
}
ffffffffc0201fd6:	4501                	li	a0,0
ffffffffc0201fd8:	0141                	addi	sp,sp,16
ffffffffc0201fda:	8082                	ret
ffffffffc0201fdc:	60a2                	ld	ra,8(sp)
        *ptr_page = NULL;
ffffffffc0201fde:	0005b023          	sd	zero,0(a1)
}
ffffffffc0201fe2:	4501                	li	a0,0
ffffffffc0201fe4:	0141                	addi	sp,sp,16
ffffffffc0201fe6:	8082                	ret
    assert(in_tick == 0);
ffffffffc0201fe8:	00003697          	auipc	a3,0x3
ffffffffc0201fec:	56868693          	addi	a3,a3,1384 # ffffffffc0205550 <commands+0x10a8>
ffffffffc0201ff0:	00003617          	auipc	a2,0x3
ffffffffc0201ff4:	ea860613          	addi	a2,a2,-344 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0201ff8:	03c00593          	li	a1,60
ffffffffc0201ffc:	00003517          	auipc	a0,0x3
ffffffffc0202000:	39c50513          	addi	a0,a0,924 # ffffffffc0205398 <commands+0xef0>
ffffffffc0202004:	900fe0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(head != NULL);
ffffffffc0202008:	00003697          	auipc	a3,0x3
ffffffffc020200c:	53868693          	addi	a3,a3,1336 # ffffffffc0205540 <commands+0x1098>
ffffffffc0202010:	00003617          	auipc	a2,0x3
ffffffffc0202014:	e8860613          	addi	a2,a2,-376 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0202018:	03b00593          	li	a1,59
ffffffffc020201c:	00003517          	auipc	a0,0x3
ffffffffc0202020:	37c50513          	addi	a0,a0,892 # ffffffffc0205398 <commands+0xef0>
ffffffffc0202024:	8e0fe0ef          	jal	ra,ffffffffc0200104 <__panic>

ffffffffc0202028 <_fifo_map_swappable>:
    list_entry_t *entry = &(page->pra_page_link);
ffffffffc0202028:	03060713          	addi	a4,a2,48
    list_entry_t *head = (list_entry_t *)mm->sm_priv;
ffffffffc020202c:	751c                	ld	a5,40(a0)
    assert(entry != NULL && head != NULL);
ffffffffc020202e:	cb09                	beqz	a4,ffffffffc0202040 <_fifo_map_swappable+0x18>
ffffffffc0202030:	cb81                	beqz	a5,ffffffffc0202040 <_fifo_map_swappable+0x18>
    __list_add(elm, listelm, listelm->next);
ffffffffc0202032:	6794                	ld	a3,8(a5)
}
ffffffffc0202034:	4501                	li	a0,0
    prev->next = next->prev = elm;
ffffffffc0202036:	e298                	sd	a4,0(a3)
ffffffffc0202038:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc020203a:	fe14                	sd	a3,56(a2)
    elm->prev = prev;
ffffffffc020203c:	fa1c                	sd	a5,48(a2)
ffffffffc020203e:	8082                	ret
{
ffffffffc0202040:	1141                	addi	sp,sp,-16
    assert(entry != NULL && head != NULL);
ffffffffc0202042:	00003697          	auipc	a3,0x3
ffffffffc0202046:	4de68693          	addi	a3,a3,1246 # ffffffffc0205520 <commands+0x1078>
ffffffffc020204a:	00003617          	auipc	a2,0x3
ffffffffc020204e:	e4e60613          	addi	a2,a2,-434 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0202052:	02c00593          	li	a1,44
ffffffffc0202056:	00003517          	auipc	a0,0x3
ffffffffc020205a:	34250513          	addi	a0,a0,834 # ffffffffc0205398 <commands+0xef0>
{
ffffffffc020205e:	e406                	sd	ra,8(sp)
    assert(entry != NULL && head != NULL);
ffffffffc0202060:	8a4fe0ef          	jal	ra,ffffffffc0200104 <__panic>

ffffffffc0202064 <check_vma_overlap.isra.0.part.1>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0202064:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0202066:	00003697          	auipc	a3,0x3
ffffffffc020206a:	51268693          	addi	a3,a3,1298 # ffffffffc0205578 <commands+0x10d0>
ffffffffc020206e:	00003617          	auipc	a2,0x3
ffffffffc0202072:	e2a60613          	addi	a2,a2,-470 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0202076:	08c00593          	li	a1,140
ffffffffc020207a:	00003517          	auipc	a0,0x3
ffffffffc020207e:	51e50513          	addi	a0,a0,1310 # ffffffffc0205598 <commands+0x10f0>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0202082:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0202084:	880fe0ef          	jal	ra,ffffffffc0200104 <__panic>

ffffffffc0202088 <mm_create>:
{
ffffffffc0202088:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020208a:	03000513          	li	a0,48
{
ffffffffc020208e:	e022                	sd	s0,0(sp)
ffffffffc0202090:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0202092:	a59ff0ef          	jal	ra,ffffffffc0201aea <kmalloc>
ffffffffc0202096:	842a                	mv	s0,a0
    if (mm != NULL)
ffffffffc0202098:	c115                	beqz	a0,ffffffffc02020bc <mm_create+0x34>
        if (swap_init_ok)
ffffffffc020209a:	0000f797          	auipc	a5,0xf
ffffffffc020209e:	3d678793          	addi	a5,a5,982 # ffffffffc0211470 <swap_init_ok>
ffffffffc02020a2:	439c                	lw	a5,0(a5)
    elm->prev = elm->next = elm;
ffffffffc02020a4:	e408                	sd	a0,8(s0)
ffffffffc02020a6:	e008                	sd	a0,0(s0)
        mm->mmap_cache = NULL;
ffffffffc02020a8:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc02020ac:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc02020b0:	02052023          	sw	zero,32(a0)
        if (swap_init_ok)
ffffffffc02020b4:	2781                	sext.w	a5,a5
ffffffffc02020b6:	eb81                	bnez	a5,ffffffffc02020c6 <mm_create+0x3e>
            mm->sm_priv = NULL;
ffffffffc02020b8:	02053423          	sd	zero,40(a0)
}
ffffffffc02020bc:	8522                	mv	a0,s0
ffffffffc02020be:	60a2                	ld	ra,8(sp)
ffffffffc02020c0:	6402                	ld	s0,0(sp)
ffffffffc02020c2:	0141                	addi	sp,sp,16
ffffffffc02020c4:	8082                	ret
            swap_init_mm(mm);
ffffffffc02020c6:	631000ef          	jal	ra,ffffffffc0202ef6 <swap_init_mm>
}
ffffffffc02020ca:	8522                	mv	a0,s0
ffffffffc02020cc:	60a2                	ld	ra,8(sp)
ffffffffc02020ce:	6402                	ld	s0,0(sp)
ffffffffc02020d0:	0141                	addi	sp,sp,16
ffffffffc02020d2:	8082                	ret

ffffffffc02020d4 <vma_create>:
{
ffffffffc02020d4:	1101                	addi	sp,sp,-32
ffffffffc02020d6:	e04a                	sd	s2,0(sp)
ffffffffc02020d8:	892a                	mv	s2,a0
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02020da:	03000513          	li	a0,48
{
ffffffffc02020de:	e822                	sd	s0,16(sp)
ffffffffc02020e0:	e426                	sd	s1,8(sp)
ffffffffc02020e2:	ec06                	sd	ra,24(sp)
ffffffffc02020e4:	84ae                	mv	s1,a1
ffffffffc02020e6:	8432                	mv	s0,a2
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02020e8:	a03ff0ef          	jal	ra,ffffffffc0201aea <kmalloc>
    if (vma != NULL)
ffffffffc02020ec:	c509                	beqz	a0,ffffffffc02020f6 <vma_create+0x22>
        vma->vm_start = vm_start;
ffffffffc02020ee:	01253423          	sd	s2,8(a0)
        vma->vm_end = vm_end;
ffffffffc02020f2:	e904                	sd	s1,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc02020f4:	ed00                	sd	s0,24(a0)
}
ffffffffc02020f6:	60e2                	ld	ra,24(sp)
ffffffffc02020f8:	6442                	ld	s0,16(sp)
ffffffffc02020fa:	64a2                	ld	s1,8(sp)
ffffffffc02020fc:	6902                	ld	s2,0(sp)
ffffffffc02020fe:	6105                	addi	sp,sp,32
ffffffffc0202100:	8082                	ret

ffffffffc0202102 <find_vma>:
    if (mm != NULL)
ffffffffc0202102:	c51d                	beqz	a0,ffffffffc0202130 <find_vma+0x2e>
        vma = mm->mmap_cache;
ffffffffc0202104:	691c                	ld	a5,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0202106:	c781                	beqz	a5,ffffffffc020210e <find_vma+0xc>
ffffffffc0202108:	6798                	ld	a4,8(a5)
ffffffffc020210a:	02e5f663          	bgeu	a1,a4,ffffffffc0202136 <find_vma+0x34>
            list_entry_t *list = &(mm->mmap_list), *le = list;
ffffffffc020210e:	87aa                	mv	a5,a0
    return listelm->next;
ffffffffc0202110:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc0202112:	00f50f63          	beq	a0,a5,ffffffffc0202130 <find_vma+0x2e>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc0202116:	fe87b703          	ld	a4,-24(a5)
ffffffffc020211a:	fee5ebe3          	bltu	a1,a4,ffffffffc0202110 <find_vma+0xe>
ffffffffc020211e:	ff07b703          	ld	a4,-16(a5)
ffffffffc0202122:	fee5f7e3          	bgeu	a1,a4,ffffffffc0202110 <find_vma+0xe>
                vma = le2vma(le, list_link);
ffffffffc0202126:	1781                	addi	a5,a5,-32
        if (vma != NULL)
ffffffffc0202128:	c781                	beqz	a5,ffffffffc0202130 <find_vma+0x2e>
            mm->mmap_cache = vma;
ffffffffc020212a:	e91c                	sd	a5,16(a0)
}
ffffffffc020212c:	853e                	mv	a0,a5
ffffffffc020212e:	8082                	ret
    struct vma_struct *vma = NULL;
ffffffffc0202130:	4781                	li	a5,0
}
ffffffffc0202132:	853e                	mv	a0,a5
ffffffffc0202134:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0202136:	6b98                	ld	a4,16(a5)
ffffffffc0202138:	fce5fbe3          	bgeu	a1,a4,ffffffffc020210e <find_vma+0xc>
            mm->mmap_cache = vma;
ffffffffc020213c:	e91c                	sd	a5,16(a0)
    return vma;
ffffffffc020213e:	b7fd                	j	ffffffffc020212c <find_vma+0x2a>

ffffffffc0202140 <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202140:	6590                	ld	a2,8(a1)
ffffffffc0202142:	0105b803          	ld	a6,16(a1)
{
ffffffffc0202146:	1141                	addi	sp,sp,-16
ffffffffc0202148:	e406                	sd	ra,8(sp)
ffffffffc020214a:	872a                	mv	a4,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc020214c:	01066863          	bltu	a2,a6,ffffffffc020215c <insert_vma_struct+0x1c>
ffffffffc0202150:	a8b9                	j	ffffffffc02021ae <insert_vma_struct+0x6e>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0202152:	fe87b683          	ld	a3,-24(a5)
ffffffffc0202156:	04d66763          	bltu	a2,a3,ffffffffc02021a4 <insert_vma_struct+0x64>
ffffffffc020215a:	873e                	mv	a4,a5
ffffffffc020215c:	671c                	ld	a5,8(a4)
    while ((le = list_next(le)) != list)
ffffffffc020215e:	fef51ae3          	bne	a0,a5,ffffffffc0202152 <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc0202162:	02a70463          	beq	a4,a0,ffffffffc020218a <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0202166:	ff073683          	ld	a3,-16(a4)
    assert(prev->vm_start < prev->vm_end);
ffffffffc020216a:	fe873883          	ld	a7,-24(a4)
ffffffffc020216e:	08d8f063          	bgeu	a7,a3,ffffffffc02021ee <insert_vma_struct+0xae>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202172:	04d66e63          	bltu	a2,a3,ffffffffc02021ce <insert_vma_struct+0x8e>
    }
    if (le_next != list)
ffffffffc0202176:	00f50a63          	beq	a0,a5,ffffffffc020218a <insert_vma_struct+0x4a>
ffffffffc020217a:	fe87b683          	ld	a3,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc020217e:	0506e863          	bltu	a3,a6,ffffffffc02021ce <insert_vma_struct+0x8e>
    assert(next->vm_start < next->vm_end);
ffffffffc0202182:	ff07b603          	ld	a2,-16(a5)
ffffffffc0202186:	02c6f263          	bgeu	a3,a2,ffffffffc02021aa <insert_vma_struct+0x6a>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc020218a:	5114                	lw	a3,32(a0)
    vma->vm_mm = mm;
ffffffffc020218c:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc020218e:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0202192:	e390                	sd	a2,0(a5)
ffffffffc0202194:	e710                	sd	a2,8(a4)
}
ffffffffc0202196:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0202198:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc020219a:	f198                	sd	a4,32(a1)
    mm->map_count++;
ffffffffc020219c:	2685                	addiw	a3,a3,1
ffffffffc020219e:	d114                	sw	a3,32(a0)
}
ffffffffc02021a0:	0141                	addi	sp,sp,16
ffffffffc02021a2:	8082                	ret
    if (le_prev != list)
ffffffffc02021a4:	fca711e3          	bne	a4,a0,ffffffffc0202166 <insert_vma_struct+0x26>
ffffffffc02021a8:	bfd9                	j	ffffffffc020217e <insert_vma_struct+0x3e>
ffffffffc02021aa:	ebbff0ef          	jal	ra,ffffffffc0202064 <check_vma_overlap.isra.0.part.1>
    assert(vma->vm_start < vma->vm_end);
ffffffffc02021ae:	00003697          	auipc	a3,0x3
ffffffffc02021b2:	47a68693          	addi	a3,a3,1146 # ffffffffc0205628 <commands+0x1180>
ffffffffc02021b6:	00003617          	auipc	a2,0x3
ffffffffc02021ba:	ce260613          	addi	a2,a2,-798 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc02021be:	09200593          	li	a1,146
ffffffffc02021c2:	00003517          	auipc	a0,0x3
ffffffffc02021c6:	3d650513          	addi	a0,a0,982 # ffffffffc0205598 <commands+0x10f0>
ffffffffc02021ca:	f3bfd0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02021ce:	00003697          	auipc	a3,0x3
ffffffffc02021d2:	49a68693          	addi	a3,a3,1178 # ffffffffc0205668 <commands+0x11c0>
ffffffffc02021d6:	00003617          	auipc	a2,0x3
ffffffffc02021da:	cc260613          	addi	a2,a2,-830 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc02021de:	08b00593          	li	a1,139
ffffffffc02021e2:	00003517          	auipc	a0,0x3
ffffffffc02021e6:	3b650513          	addi	a0,a0,950 # ffffffffc0205598 <commands+0x10f0>
ffffffffc02021ea:	f1bfd0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc02021ee:	00003697          	auipc	a3,0x3
ffffffffc02021f2:	45a68693          	addi	a3,a3,1114 # ffffffffc0205648 <commands+0x11a0>
ffffffffc02021f6:	00003617          	auipc	a2,0x3
ffffffffc02021fa:	ca260613          	addi	a2,a2,-862 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc02021fe:	08a00593          	li	a1,138
ffffffffc0202202:	00003517          	auipc	a0,0x3
ffffffffc0202206:	39650513          	addi	a0,a0,918 # ffffffffc0205598 <commands+0x10f0>
ffffffffc020220a:	efbfd0ef          	jal	ra,ffffffffc0200104 <__panic>

ffffffffc020220e <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
ffffffffc020220e:	1141                	addi	sp,sp,-16
ffffffffc0202210:	e022                	sd	s0,0(sp)
ffffffffc0202212:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc0202214:	6508                	ld	a0,8(a0)
ffffffffc0202216:	e406                	sd	ra,8(sp)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc0202218:	00a40e63          	beq	s0,a0,ffffffffc0202234 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc020221c:	6118                	ld	a4,0(a0)
ffffffffc020221e:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link), sizeof(struct vma_struct)); // kfree vma
ffffffffc0202220:	03000593          	li	a1,48
ffffffffc0202224:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0202226:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0202228:	e398                	sd	a4,0(a5)
ffffffffc020222a:	983ff0ef          	jal	ra,ffffffffc0201bac <kfree>
    return listelm->next;
ffffffffc020222e:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc0202230:	fea416e3          	bne	s0,a0,ffffffffc020221c <mm_destroy+0xe>
    }
    kfree(mm, sizeof(struct mm_struct)); // kfree mm
ffffffffc0202234:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc0202236:	6402                	ld	s0,0(sp)
ffffffffc0202238:	60a2                	ld	ra,8(sp)
    kfree(mm, sizeof(struct mm_struct)); // kfree mm
ffffffffc020223a:	03000593          	li	a1,48
}
ffffffffc020223e:	0141                	addi	sp,sp,16
    kfree(mm, sizeof(struct mm_struct)); // kfree mm
ffffffffc0202240:	96dff06f          	j	ffffffffc0201bac <kfree>

ffffffffc0202244 <vmm_init>:

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0202244:	715d                	addi	sp,sp,-80
ffffffffc0202246:	e486                	sd	ra,72(sp)
ffffffffc0202248:	e0a2                	sd	s0,64(sp)
ffffffffc020224a:	fc26                	sd	s1,56(sp)
ffffffffc020224c:	f84a                	sd	s2,48(sp)
ffffffffc020224e:	f052                	sd	s4,32(sp)
ffffffffc0202250:	f44e                	sd	s3,40(sp)
ffffffffc0202252:	ec56                	sd	s5,24(sp)
ffffffffc0202254:	e85a                	sd	s6,16(sp)
ffffffffc0202256:	e45e                	sd	s7,8(sp)

// check_vmm - check correctness of vmm
static void
check_vmm(void)
{
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0202258:	943fe0ef          	jal	ra,ffffffffc0200b9a <nr_free_pages>
ffffffffc020225c:	892a                	mv	s2,a0
}

static void
check_vma_struct(void)
{
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc020225e:	93dfe0ef          	jal	ra,ffffffffc0200b9a <nr_free_pages>
ffffffffc0202262:	8a2a                	mv	s4,a0

    struct mm_struct *mm = mm_create();
ffffffffc0202264:	e25ff0ef          	jal	ra,ffffffffc0202088 <mm_create>
    assert(mm != NULL);
ffffffffc0202268:	842a                	mv	s0,a0
ffffffffc020226a:	03200493          	li	s1,50
ffffffffc020226e:	e919                	bnez	a0,ffffffffc0202284 <vmm_init+0x40>
ffffffffc0202270:	aeed                	j	ffffffffc020266a <vmm_init+0x426>
        vma->vm_start = vm_start;
ffffffffc0202272:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc0202274:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202276:	00053c23          	sd	zero,24(a0)
    int i;
    for (i = step1; i >= 1; i--)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc020227a:	14ed                	addi	s1,s1,-5
ffffffffc020227c:	8522                	mv	a0,s0
ffffffffc020227e:	ec3ff0ef          	jal	ra,ffffffffc0202140 <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0202282:	c88d                	beqz	s1,ffffffffc02022b4 <vmm_init+0x70>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202284:	03000513          	li	a0,48
ffffffffc0202288:	863ff0ef          	jal	ra,ffffffffc0201aea <kmalloc>
ffffffffc020228c:	85aa                	mv	a1,a0
ffffffffc020228e:	00248793          	addi	a5,s1,2
    if (vma != NULL)
ffffffffc0202292:	f165                	bnez	a0,ffffffffc0202272 <vmm_init+0x2e>
        assert(vma != NULL);
ffffffffc0202294:	00003697          	auipc	a3,0x3
ffffffffc0202298:	61c68693          	addi	a3,a3,1564 # ffffffffc02058b0 <commands+0x1408>
ffffffffc020229c:	00003617          	auipc	a2,0x3
ffffffffc02022a0:	bfc60613          	addi	a2,a2,-1028 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc02022a4:	0e400593          	li	a1,228
ffffffffc02022a8:	00003517          	auipc	a0,0x3
ffffffffc02022ac:	2f050513          	addi	a0,a0,752 # ffffffffc0205598 <commands+0x10f0>
ffffffffc02022b0:	e55fd0ef          	jal	ra,ffffffffc0200104 <__panic>
    for (i = step1; i >= 1; i--)
ffffffffc02022b4:	03700493          	li	s1,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc02022b8:	1f900993          	li	s3,505
ffffffffc02022bc:	a819                	j	ffffffffc02022d2 <vmm_init+0x8e>
        vma->vm_start = vm_start;
ffffffffc02022be:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc02022c0:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc02022c2:	00053c23          	sd	zero,24(a0)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc02022c6:	0495                	addi	s1,s1,5
ffffffffc02022c8:	8522                	mv	a0,s0
ffffffffc02022ca:	e77ff0ef          	jal	ra,ffffffffc0202140 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc02022ce:	03348a63          	beq	s1,s3,ffffffffc0202302 <vmm_init+0xbe>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02022d2:	03000513          	li	a0,48
ffffffffc02022d6:	815ff0ef          	jal	ra,ffffffffc0201aea <kmalloc>
ffffffffc02022da:	85aa                	mv	a1,a0
ffffffffc02022dc:	00248793          	addi	a5,s1,2
    if (vma != NULL)
ffffffffc02022e0:	fd79                	bnez	a0,ffffffffc02022be <vmm_init+0x7a>
        assert(vma != NULL);
ffffffffc02022e2:	00003697          	auipc	a3,0x3
ffffffffc02022e6:	5ce68693          	addi	a3,a3,1486 # ffffffffc02058b0 <commands+0x1408>
ffffffffc02022ea:	00003617          	auipc	a2,0x3
ffffffffc02022ee:	bae60613          	addi	a2,a2,-1106 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc02022f2:	0eb00593          	li	a1,235
ffffffffc02022f6:	00003517          	auipc	a0,0x3
ffffffffc02022fa:	2a250513          	addi	a0,a0,674 # ffffffffc0205598 <commands+0x10f0>
ffffffffc02022fe:	e07fd0ef          	jal	ra,ffffffffc0200104 <__panic>
ffffffffc0202302:	6418                	ld	a4,8(s0)
ffffffffc0202304:	479d                	li	a5,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0202306:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc020230a:	2ae40063          	beq	s0,a4,ffffffffc02025aa <vmm_init+0x366>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc020230e:	fe873603          	ld	a2,-24(a4)
ffffffffc0202312:	ffe78693          	addi	a3,a5,-2
ffffffffc0202316:	20d61a63          	bne	a2,a3,ffffffffc020252a <vmm_init+0x2e6>
ffffffffc020231a:	ff073683          	ld	a3,-16(a4)
ffffffffc020231e:	20d79663          	bne	a5,a3,ffffffffc020252a <vmm_init+0x2e6>
ffffffffc0202322:	0795                	addi	a5,a5,5
ffffffffc0202324:	6718                	ld	a4,8(a4)
    for (i = 1; i <= step2; i++)
ffffffffc0202326:	feb792e3          	bne	a5,a1,ffffffffc020230a <vmm_init+0xc6>
ffffffffc020232a:	499d                	li	s3,7
ffffffffc020232c:	4495                	li	s1,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc020232e:	1f900b93          	li	s7,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0202332:	85a6                	mv	a1,s1
ffffffffc0202334:	8522                	mv	a0,s0
ffffffffc0202336:	dcdff0ef          	jal	ra,ffffffffc0202102 <find_vma>
ffffffffc020233a:	8b2a                	mv	s6,a0
        assert(vma1 != NULL);
ffffffffc020233c:	2e050763          	beqz	a0,ffffffffc020262a <vmm_init+0x3e6>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0202340:	00148593          	addi	a1,s1,1
ffffffffc0202344:	8522                	mv	a0,s0
ffffffffc0202346:	dbdff0ef          	jal	ra,ffffffffc0202102 <find_vma>
ffffffffc020234a:	8aaa                	mv	s5,a0
        assert(vma2 != NULL);
ffffffffc020234c:	2a050f63          	beqz	a0,ffffffffc020260a <vmm_init+0x3c6>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0202350:	85ce                	mv	a1,s3
ffffffffc0202352:	8522                	mv	a0,s0
ffffffffc0202354:	dafff0ef          	jal	ra,ffffffffc0202102 <find_vma>
        assert(vma3 == NULL);
ffffffffc0202358:	28051963          	bnez	a0,ffffffffc02025ea <vmm_init+0x3a6>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc020235c:	00348593          	addi	a1,s1,3
ffffffffc0202360:	8522                	mv	a0,s0
ffffffffc0202362:	da1ff0ef          	jal	ra,ffffffffc0202102 <find_vma>
        assert(vma4 == NULL);
ffffffffc0202366:	26051263          	bnez	a0,ffffffffc02025ca <vmm_init+0x386>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc020236a:	00448593          	addi	a1,s1,4
ffffffffc020236e:	8522                	mv	a0,s0
ffffffffc0202370:	d93ff0ef          	jal	ra,ffffffffc0202102 <find_vma>
        assert(vma5 == NULL);
ffffffffc0202374:	2c051b63          	bnez	a0,ffffffffc020264a <vmm_init+0x406>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0202378:	008b3783          	ld	a5,8(s6)
ffffffffc020237c:	1c979763          	bne	a5,s1,ffffffffc020254a <vmm_init+0x306>
ffffffffc0202380:	010b3783          	ld	a5,16(s6)
ffffffffc0202384:	1d379363          	bne	a5,s3,ffffffffc020254a <vmm_init+0x306>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0202388:	008ab783          	ld	a5,8(s5)
ffffffffc020238c:	1c979f63          	bne	a5,s1,ffffffffc020256a <vmm_init+0x326>
ffffffffc0202390:	010ab783          	ld	a5,16(s5)
ffffffffc0202394:	1d379b63          	bne	a5,s3,ffffffffc020256a <vmm_init+0x326>
ffffffffc0202398:	0495                	addi	s1,s1,5
ffffffffc020239a:	0995                	addi	s3,s3,5
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc020239c:	f9749be3          	bne	s1,s7,ffffffffc0202332 <vmm_init+0xee>
ffffffffc02023a0:	4491                	li	s1,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc02023a2:	59fd                	li	s3,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc02023a4:	85a6                	mv	a1,s1
ffffffffc02023a6:	8522                	mv	a0,s0
ffffffffc02023a8:	d5bff0ef          	jal	ra,ffffffffc0202102 <find_vma>
ffffffffc02023ac:	0004859b          	sext.w	a1,s1
        if (vma_below_5 != NULL)
ffffffffc02023b0:	c90d                	beqz	a0,ffffffffc02023e2 <vmm_init+0x19e>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc02023b2:	6914                	ld	a3,16(a0)
ffffffffc02023b4:	6510                	ld	a2,8(a0)
ffffffffc02023b6:	00003517          	auipc	a0,0x3
ffffffffc02023ba:	3e250513          	addi	a0,a0,994 # ffffffffc0205798 <commands+0x12f0>
ffffffffc02023be:	d01fd0ef          	jal	ra,ffffffffc02000be <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc02023c2:	00003697          	auipc	a3,0x3
ffffffffc02023c6:	3fe68693          	addi	a3,a3,1022 # ffffffffc02057c0 <commands+0x1318>
ffffffffc02023ca:	00003617          	auipc	a2,0x3
ffffffffc02023ce:	ace60613          	addi	a2,a2,-1330 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc02023d2:	11100593          	li	a1,273
ffffffffc02023d6:	00003517          	auipc	a0,0x3
ffffffffc02023da:	1c250513          	addi	a0,a0,450 # ffffffffc0205598 <commands+0x10f0>
ffffffffc02023de:	d27fd0ef          	jal	ra,ffffffffc0200104 <__panic>
ffffffffc02023e2:	14fd                	addi	s1,s1,-1
    for (i = 4; i >= 0; i--)
ffffffffc02023e4:	fd3490e3          	bne	s1,s3,ffffffffc02023a4 <vmm_init+0x160>
    }

    mm_destroy(mm);
ffffffffc02023e8:	8522                	mv	a0,s0
ffffffffc02023ea:	e25ff0ef          	jal	ra,ffffffffc020220e <mm_destroy>

    assert(nr_free_pages_store == nr_free_pages());
ffffffffc02023ee:	facfe0ef          	jal	ra,ffffffffc0200b9a <nr_free_pages>
ffffffffc02023f2:	28aa1c63          	bne	s4,a0,ffffffffc020268a <vmm_init+0x446>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc02023f6:	00003517          	auipc	a0,0x3
ffffffffc02023fa:	40a50513          	addi	a0,a0,1034 # ffffffffc0205800 <commands+0x1358>
ffffffffc02023fe:	cc1fd0ef          	jal	ra,ffffffffc02000be <cprintf>
// check_pgfault - check correctness of pgfault handler
static void
check_pgfault(void)
{
    // char *name = "check_pgfault";
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0202402:	f98fe0ef          	jal	ra,ffffffffc0200b9a <nr_free_pages>
ffffffffc0202406:	89aa                	mv	s3,a0

    check_mm_struct = mm_create();
ffffffffc0202408:	c81ff0ef          	jal	ra,ffffffffc0202088 <mm_create>
ffffffffc020240c:	0000f797          	auipc	a5,0xf
ffffffffc0202410:	0aa7b223          	sd	a0,164(a5) # ffffffffc02114b0 <check_mm_struct>
ffffffffc0202414:	842a                	mv	s0,a0

    assert(check_mm_struct != NULL);
ffffffffc0202416:	2a050a63          	beqz	a0,ffffffffc02026ca <vmm_init+0x486>
    struct mm_struct *mm = check_mm_struct;
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc020241a:	0000f797          	auipc	a5,0xf
ffffffffc020241e:	03678793          	addi	a5,a5,54 # ffffffffc0211450 <boot_pgdir>
ffffffffc0202422:	6384                	ld	s1,0(a5)
    assert(pgdir[0] == 0);
ffffffffc0202424:	609c                	ld	a5,0(s1)
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0202426:	ed04                	sd	s1,24(a0)
    assert(pgdir[0] == 0);
ffffffffc0202428:	32079d63          	bnez	a5,ffffffffc0202762 <vmm_init+0x51e>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020242c:	03000513          	li	a0,48
ffffffffc0202430:	ebaff0ef          	jal	ra,ffffffffc0201aea <kmalloc>
ffffffffc0202434:	8a2a                	mv	s4,a0
    if (vma != NULL)
ffffffffc0202436:	14050a63          	beqz	a0,ffffffffc020258a <vmm_init+0x346>
        vma->vm_end = vm_end;
ffffffffc020243a:	002007b7          	lui	a5,0x200
ffffffffc020243e:	00fa3823          	sd	a5,16(s4)
        vma->vm_flags = vm_flags;
ffffffffc0202442:	4789                	li	a5,2

    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);

    assert(vma != NULL);

    insert_vma_struct(mm, vma);
ffffffffc0202444:	85aa                	mv	a1,a0
        vma->vm_flags = vm_flags;
ffffffffc0202446:	00fa3c23          	sd	a5,24(s4)
    insert_vma_struct(mm, vma);
ffffffffc020244a:	8522                	mv	a0,s0
        vma->vm_start = vm_start;
ffffffffc020244c:	000a3423          	sd	zero,8(s4)
    insert_vma_struct(mm, vma);
ffffffffc0202450:	cf1ff0ef          	jal	ra,ffffffffc0202140 <insert_vma_struct>

    uintptr_t addr = 0x100;
    assert(find_vma(mm, addr) == vma);
ffffffffc0202454:	10000593          	li	a1,256
ffffffffc0202458:	8522                	mv	a0,s0
ffffffffc020245a:	ca9ff0ef          	jal	ra,ffffffffc0202102 <find_vma>
ffffffffc020245e:	10000793          	li	a5,256

    int i, sum = 0;
    for (i = 0; i < 100; i++)
ffffffffc0202462:	16400713          	li	a4,356
    assert(find_vma(mm, addr) == vma);
ffffffffc0202466:	2aaa1263          	bne	s4,a0,ffffffffc020270a <vmm_init+0x4c6>
    {
        *(char *)(addr + i) = i;
ffffffffc020246a:	00f78023          	sb	a5,0(a5) # 200000 <BASE_ADDRESS-0xffffffffc0000000>
        sum += i;
ffffffffc020246e:	0785                	addi	a5,a5,1
    for (i = 0; i < 100; i++)
ffffffffc0202470:	fee79de3          	bne	a5,a4,ffffffffc020246a <vmm_init+0x226>
        sum += i;
ffffffffc0202474:	6705                	lui	a4,0x1
    for (i = 0; i < 100; i++)
ffffffffc0202476:	10000793          	li	a5,256
        sum += i;
ffffffffc020247a:	35670713          	addi	a4,a4,854 # 1356 <BASE_ADDRESS-0xffffffffc01fecaa>
    }
    for (i = 0; i < 100; i++)
ffffffffc020247e:	16400613          	li	a2,356
    {
        sum -= *(char *)(addr + i);
ffffffffc0202482:	0007c683          	lbu	a3,0(a5)
ffffffffc0202486:	0785                	addi	a5,a5,1
ffffffffc0202488:	9f15                	subw	a4,a4,a3
    for (i = 0; i < 100; i++)
ffffffffc020248a:	fec79ce3          	bne	a5,a2,ffffffffc0202482 <vmm_init+0x23e>
    }
    assert(sum == 0);
ffffffffc020248e:	2a071a63          	bnez	a4,ffffffffc0202742 <vmm_init+0x4fe>

    page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));
ffffffffc0202492:	4581                	li	a1,0
ffffffffc0202494:	8526                	mv	a0,s1
ffffffffc0202496:	9a1fe0ef          	jal	ra,ffffffffc0200e36 <page_remove>
    return pa2page(PDE_ADDR(pde));
ffffffffc020249a:	609c                	ld	a5,0(s1)
    if (PPN(pa) >= npage) {
ffffffffc020249c:	0000f717          	auipc	a4,0xf
ffffffffc02024a0:	fbc70713          	addi	a4,a4,-68 # ffffffffc0211458 <npage>
ffffffffc02024a4:	6318                	ld	a4,0(a4)
    return pa2page(PDE_ADDR(pde));
ffffffffc02024a6:	078a                	slli	a5,a5,0x2
ffffffffc02024a8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02024aa:	28e7f063          	bgeu	a5,a4,ffffffffc020272a <vmm_init+0x4e6>
    return &pages[PPN(pa) - nbase];
ffffffffc02024ae:	00004717          	auipc	a4,0x4
ffffffffc02024b2:	e2a70713          	addi	a4,a4,-470 # ffffffffc02062d8 <nbase>
ffffffffc02024b6:	6318                	ld	a4,0(a4)
ffffffffc02024b8:	0000f697          	auipc	a3,0xf
ffffffffc02024bc:	fe068693          	addi	a3,a3,-32 # ffffffffc0211498 <pages>
ffffffffc02024c0:	6288                	ld	a0,0(a3)
ffffffffc02024c2:	8f99                	sub	a5,a5,a4
ffffffffc02024c4:	00379713          	slli	a4,a5,0x3
ffffffffc02024c8:	97ba                	add	a5,a5,a4
ffffffffc02024ca:	078e                	slli	a5,a5,0x3

    free_page(pde2page(pgdir[0]));
ffffffffc02024cc:	953e                	add	a0,a0,a5
ffffffffc02024ce:	4585                	li	a1,1
ffffffffc02024d0:	e84fe0ef          	jal	ra,ffffffffc0200b54 <free_pages>

    pgdir[0] = 0;
ffffffffc02024d4:	0004b023          	sd	zero,0(s1)

    mm->pgdir = NULL;
    mm_destroy(mm);
ffffffffc02024d8:	8522                	mv	a0,s0
    mm->pgdir = NULL;
ffffffffc02024da:	00043c23          	sd	zero,24(s0)
    mm_destroy(mm);
ffffffffc02024de:	d31ff0ef          	jal	ra,ffffffffc020220e <mm_destroy>

    check_mm_struct = NULL;
    nr_free_pages_store--; // szx : Sv39第二级页表多占了一个内存页，所以执行此操作
ffffffffc02024e2:	19fd                	addi	s3,s3,-1
    check_mm_struct = NULL;
ffffffffc02024e4:	0000f797          	auipc	a5,0xf
ffffffffc02024e8:	fc07b623          	sd	zero,-52(a5) # ffffffffc02114b0 <check_mm_struct>

    assert(nr_free_pages_store == nr_free_pages());
ffffffffc02024ec:	eaefe0ef          	jal	ra,ffffffffc0200b9a <nr_free_pages>
ffffffffc02024f0:	1aa99d63          	bne	s3,a0,ffffffffc02026aa <vmm_init+0x466>

    cprintf("check_pgfault() succeeded!\n");
ffffffffc02024f4:	00003517          	auipc	a0,0x3
ffffffffc02024f8:	38450513          	addi	a0,a0,900 # ffffffffc0205878 <commands+0x13d0>
ffffffffc02024fc:	bc3fd0ef          	jal	ra,ffffffffc02000be <cprintf>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0202500:	e9afe0ef          	jal	ra,ffffffffc0200b9a <nr_free_pages>
    nr_free_pages_store--; // szx : Sv39三级页表多占一个内存页，所以执行此操作
ffffffffc0202504:	197d                	addi	s2,s2,-1
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0202506:	1ea91263          	bne	s2,a0,ffffffffc02026ea <vmm_init+0x4a6>
}
ffffffffc020250a:	6406                	ld	s0,64(sp)
ffffffffc020250c:	60a6                	ld	ra,72(sp)
ffffffffc020250e:	74e2                	ld	s1,56(sp)
ffffffffc0202510:	7942                	ld	s2,48(sp)
ffffffffc0202512:	79a2                	ld	s3,40(sp)
ffffffffc0202514:	7a02                	ld	s4,32(sp)
ffffffffc0202516:	6ae2                	ld	s5,24(sp)
ffffffffc0202518:	6b42                	ld	s6,16(sp)
ffffffffc020251a:	6ba2                	ld	s7,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc020251c:	00003517          	auipc	a0,0x3
ffffffffc0202520:	37c50513          	addi	a0,a0,892 # ffffffffc0205898 <commands+0x13f0>
}
ffffffffc0202524:	6161                	addi	sp,sp,80
    cprintf("check_vmm() succeeded.\n");
ffffffffc0202526:	b99fd06f          	j	ffffffffc02000be <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc020252a:	00003697          	auipc	a3,0x3
ffffffffc020252e:	18668693          	addi	a3,a3,390 # ffffffffc02056b0 <commands+0x1208>
ffffffffc0202532:	00003617          	auipc	a2,0x3
ffffffffc0202536:	96660613          	addi	a2,a2,-1690 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc020253a:	0f500593          	li	a1,245
ffffffffc020253e:	00003517          	auipc	a0,0x3
ffffffffc0202542:	05a50513          	addi	a0,a0,90 # ffffffffc0205598 <commands+0x10f0>
ffffffffc0202546:	bbffd0ef          	jal	ra,ffffffffc0200104 <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc020254a:	00003697          	auipc	a3,0x3
ffffffffc020254e:	1ee68693          	addi	a3,a3,494 # ffffffffc0205738 <commands+0x1290>
ffffffffc0202552:	00003617          	auipc	a2,0x3
ffffffffc0202556:	94660613          	addi	a2,a2,-1722 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc020255a:	10600593          	li	a1,262
ffffffffc020255e:	00003517          	auipc	a0,0x3
ffffffffc0202562:	03a50513          	addi	a0,a0,58 # ffffffffc0205598 <commands+0x10f0>
ffffffffc0202566:	b9ffd0ef          	jal	ra,ffffffffc0200104 <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc020256a:	00003697          	auipc	a3,0x3
ffffffffc020256e:	1fe68693          	addi	a3,a3,510 # ffffffffc0205768 <commands+0x12c0>
ffffffffc0202572:	00003617          	auipc	a2,0x3
ffffffffc0202576:	92660613          	addi	a2,a2,-1754 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc020257a:	10700593          	li	a1,263
ffffffffc020257e:	00003517          	auipc	a0,0x3
ffffffffc0202582:	01a50513          	addi	a0,a0,26 # ffffffffc0205598 <commands+0x10f0>
ffffffffc0202586:	b7ffd0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(vma != NULL);
ffffffffc020258a:	00003697          	auipc	a3,0x3
ffffffffc020258e:	32668693          	addi	a3,a3,806 # ffffffffc02058b0 <commands+0x1408>
ffffffffc0202592:	00003617          	auipc	a2,0x3
ffffffffc0202596:	90660613          	addi	a2,a2,-1786 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc020259a:	12d00593          	li	a1,301
ffffffffc020259e:	00003517          	auipc	a0,0x3
ffffffffc02025a2:	ffa50513          	addi	a0,a0,-6 # ffffffffc0205598 <commands+0x10f0>
ffffffffc02025a6:	b5ffd0ef          	jal	ra,ffffffffc0200104 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc02025aa:	00003697          	auipc	a3,0x3
ffffffffc02025ae:	0ee68693          	addi	a3,a3,238 # ffffffffc0205698 <commands+0x11f0>
ffffffffc02025b2:	00003617          	auipc	a2,0x3
ffffffffc02025b6:	8e660613          	addi	a2,a2,-1818 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc02025ba:	0f300593          	li	a1,243
ffffffffc02025be:	00003517          	auipc	a0,0x3
ffffffffc02025c2:	fda50513          	addi	a0,a0,-38 # ffffffffc0205598 <commands+0x10f0>
ffffffffc02025c6:	b3ffd0ef          	jal	ra,ffffffffc0200104 <__panic>
        assert(vma4 == NULL);
ffffffffc02025ca:	00003697          	auipc	a3,0x3
ffffffffc02025ce:	14e68693          	addi	a3,a3,334 # ffffffffc0205718 <commands+0x1270>
ffffffffc02025d2:	00003617          	auipc	a2,0x3
ffffffffc02025d6:	8c660613          	addi	a2,a2,-1850 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc02025da:	10200593          	li	a1,258
ffffffffc02025de:	00003517          	auipc	a0,0x3
ffffffffc02025e2:	fba50513          	addi	a0,a0,-70 # ffffffffc0205598 <commands+0x10f0>
ffffffffc02025e6:	b1ffd0ef          	jal	ra,ffffffffc0200104 <__panic>
        assert(vma3 == NULL);
ffffffffc02025ea:	00003697          	auipc	a3,0x3
ffffffffc02025ee:	11e68693          	addi	a3,a3,286 # ffffffffc0205708 <commands+0x1260>
ffffffffc02025f2:	00003617          	auipc	a2,0x3
ffffffffc02025f6:	8a660613          	addi	a2,a2,-1882 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc02025fa:	10000593          	li	a1,256
ffffffffc02025fe:	00003517          	auipc	a0,0x3
ffffffffc0202602:	f9a50513          	addi	a0,a0,-102 # ffffffffc0205598 <commands+0x10f0>
ffffffffc0202606:	afffd0ef          	jal	ra,ffffffffc0200104 <__panic>
        assert(vma2 != NULL);
ffffffffc020260a:	00003697          	auipc	a3,0x3
ffffffffc020260e:	0ee68693          	addi	a3,a3,238 # ffffffffc02056f8 <commands+0x1250>
ffffffffc0202612:	00003617          	auipc	a2,0x3
ffffffffc0202616:	88660613          	addi	a2,a2,-1914 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc020261a:	0fe00593          	li	a1,254
ffffffffc020261e:	00003517          	auipc	a0,0x3
ffffffffc0202622:	f7a50513          	addi	a0,a0,-134 # ffffffffc0205598 <commands+0x10f0>
ffffffffc0202626:	adffd0ef          	jal	ra,ffffffffc0200104 <__panic>
        assert(vma1 != NULL);
ffffffffc020262a:	00003697          	auipc	a3,0x3
ffffffffc020262e:	0be68693          	addi	a3,a3,190 # ffffffffc02056e8 <commands+0x1240>
ffffffffc0202632:	00003617          	auipc	a2,0x3
ffffffffc0202636:	86660613          	addi	a2,a2,-1946 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc020263a:	0fc00593          	li	a1,252
ffffffffc020263e:	00003517          	auipc	a0,0x3
ffffffffc0202642:	f5a50513          	addi	a0,a0,-166 # ffffffffc0205598 <commands+0x10f0>
ffffffffc0202646:	abffd0ef          	jal	ra,ffffffffc0200104 <__panic>
        assert(vma5 == NULL);
ffffffffc020264a:	00003697          	auipc	a3,0x3
ffffffffc020264e:	0de68693          	addi	a3,a3,222 # ffffffffc0205728 <commands+0x1280>
ffffffffc0202652:	00003617          	auipc	a2,0x3
ffffffffc0202656:	84660613          	addi	a2,a2,-1978 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc020265a:	10400593          	li	a1,260
ffffffffc020265e:	00003517          	auipc	a0,0x3
ffffffffc0202662:	f3a50513          	addi	a0,a0,-198 # ffffffffc0205598 <commands+0x10f0>
ffffffffc0202666:	a9ffd0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(mm != NULL);
ffffffffc020266a:	00003697          	auipc	a3,0x3
ffffffffc020266e:	01e68693          	addi	a3,a3,30 # ffffffffc0205688 <commands+0x11e0>
ffffffffc0202672:	00003617          	auipc	a2,0x3
ffffffffc0202676:	82660613          	addi	a2,a2,-2010 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc020267a:	0dc00593          	li	a1,220
ffffffffc020267e:	00003517          	auipc	a0,0x3
ffffffffc0202682:	f1a50513          	addi	a0,a0,-230 # ffffffffc0205598 <commands+0x10f0>
ffffffffc0202686:	a7ffd0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc020268a:	00003697          	auipc	a3,0x3
ffffffffc020268e:	14e68693          	addi	a3,a3,334 # ffffffffc02057d8 <commands+0x1330>
ffffffffc0202692:	00003617          	auipc	a2,0x3
ffffffffc0202696:	80660613          	addi	a2,a2,-2042 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc020269a:	11600593          	li	a1,278
ffffffffc020269e:	00003517          	auipc	a0,0x3
ffffffffc02026a2:	efa50513          	addi	a0,a0,-262 # ffffffffc0205598 <commands+0x10f0>
ffffffffc02026a6:	a5ffd0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc02026aa:	00003697          	auipc	a3,0x3
ffffffffc02026ae:	12e68693          	addi	a3,a3,302 # ffffffffc02057d8 <commands+0x1330>
ffffffffc02026b2:	00002617          	auipc	a2,0x2
ffffffffc02026b6:	7e660613          	addi	a2,a2,2022 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc02026ba:	14c00593          	li	a1,332
ffffffffc02026be:	00003517          	auipc	a0,0x3
ffffffffc02026c2:	eda50513          	addi	a0,a0,-294 # ffffffffc0205598 <commands+0x10f0>
ffffffffc02026c6:	a3ffd0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(check_mm_struct != NULL);
ffffffffc02026ca:	00003697          	auipc	a3,0x3
ffffffffc02026ce:	15668693          	addi	a3,a3,342 # ffffffffc0205820 <commands+0x1378>
ffffffffc02026d2:	00002617          	auipc	a2,0x2
ffffffffc02026d6:	7c660613          	addi	a2,a2,1990 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc02026da:	12600593          	li	a1,294
ffffffffc02026de:	00003517          	auipc	a0,0x3
ffffffffc02026e2:	eba50513          	addi	a0,a0,-326 # ffffffffc0205598 <commands+0x10f0>
ffffffffc02026e6:	a1ffd0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc02026ea:	00003697          	auipc	a3,0x3
ffffffffc02026ee:	0ee68693          	addi	a3,a3,238 # ffffffffc02057d8 <commands+0x1330>
ffffffffc02026f2:	00002617          	auipc	a2,0x2
ffffffffc02026f6:	7a660613          	addi	a2,a2,1958 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc02026fa:	0d100593          	li	a1,209
ffffffffc02026fe:	00003517          	auipc	a0,0x3
ffffffffc0202702:	e9a50513          	addi	a0,a0,-358 # ffffffffc0205598 <commands+0x10f0>
ffffffffc0202706:	9fffd0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(find_vma(mm, addr) == vma);
ffffffffc020270a:	00003697          	auipc	a3,0x3
ffffffffc020270e:	13e68693          	addi	a3,a3,318 # ffffffffc0205848 <commands+0x13a0>
ffffffffc0202712:	00002617          	auipc	a2,0x2
ffffffffc0202716:	78660613          	addi	a2,a2,1926 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc020271a:	13200593          	li	a1,306
ffffffffc020271e:	00003517          	auipc	a0,0x3
ffffffffc0202722:	e7a50513          	addi	a0,a0,-390 # ffffffffc0205598 <commands+0x10f0>
ffffffffc0202726:	9dffd0ef          	jal	ra,ffffffffc0200104 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020272a:	00002617          	auipc	a2,0x2
ffffffffc020272e:	63660613          	addi	a2,a2,1590 # ffffffffc0204d60 <commands+0x8b8>
ffffffffc0202732:	06500593          	li	a1,101
ffffffffc0202736:	00002517          	auipc	a0,0x2
ffffffffc020273a:	64a50513          	addi	a0,a0,1610 # ffffffffc0204d80 <commands+0x8d8>
ffffffffc020273e:	9c7fd0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(sum == 0);
ffffffffc0202742:	00003697          	auipc	a3,0x3
ffffffffc0202746:	12668693          	addi	a3,a3,294 # ffffffffc0205868 <commands+0x13c0>
ffffffffc020274a:	00002617          	auipc	a2,0x2
ffffffffc020274e:	74e60613          	addi	a2,a2,1870 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0202752:	13e00593          	li	a1,318
ffffffffc0202756:	00003517          	auipc	a0,0x3
ffffffffc020275a:	e4250513          	addi	a0,a0,-446 # ffffffffc0205598 <commands+0x10f0>
ffffffffc020275e:	9a7fd0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(pgdir[0] == 0);
ffffffffc0202762:	00003697          	auipc	a3,0x3
ffffffffc0202766:	0d668693          	addi	a3,a3,214 # ffffffffc0205838 <commands+0x1390>
ffffffffc020276a:	00002617          	auipc	a2,0x2
ffffffffc020276e:	72e60613          	addi	a2,a2,1838 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0202772:	12900593          	li	a1,297
ffffffffc0202776:	00003517          	auipc	a0,0x3
ffffffffc020277a:	e2250513          	addi	a0,a0,-478 # ffffffffc0205598 <commands+0x10f0>
ffffffffc020277e:	987fd0ef          	jal	ra,ffffffffc0200104 <__panic>

ffffffffc0202782 <do_pgfault>:
 *         -- P标志（第0位）指示异常是由于不存在的页面（0）还是由于访问权限违规或使用保留位（1）。
 *         -- W/R标志（第1位）指示导致异常的内存访问是读取（0）还是写入（1）。
 *         -- U/S标志（第2位）指示处理器在发生异常时是处于用户模式（1）还是管理模式（0）。
 */
int do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr)
{
ffffffffc0202782:	7179                	addi	sp,sp,-48
    int ret = -E_INVAL;
    // 尝试找到包含 addr 的 vma
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0202784:	85b2                	mv	a1,a2
{
ffffffffc0202786:	f022                	sd	s0,32(sp)
ffffffffc0202788:	ec26                	sd	s1,24(sp)
ffffffffc020278a:	f406                	sd	ra,40(sp)
ffffffffc020278c:	e84a                	sd	s2,16(sp)
ffffffffc020278e:	8432                	mv	s0,a2
ffffffffc0202790:	84aa                	mv	s1,a0
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0202792:	971ff0ef          	jal	ra,ffffffffc0202102 <find_vma>

    pgfault_num++;
ffffffffc0202796:	0000f797          	auipc	a5,0xf
ffffffffc020279a:	cca78793          	addi	a5,a5,-822 # ffffffffc0211460 <pgfault_num>
ffffffffc020279e:	439c                	lw	a5,0(a5)
ffffffffc02027a0:	2785                	addiw	a5,a5,1
ffffffffc02027a2:	0000f717          	auipc	a4,0xf
ffffffffc02027a6:	caf72f23          	sw	a5,-834(a4) # ffffffffc0211460 <pgfault_num>
    // 如果 addr 在 mm 的 vma 范围内？
    if (vma == NULL || vma->vm_start > addr)
ffffffffc02027aa:	c549                	beqz	a0,ffffffffc0202834 <do_pgfault+0xb2>
ffffffffc02027ac:	651c                	ld	a5,8(a0)
ffffffffc02027ae:	08f46363          	bltu	s0,a5,ffffffffc0202834 <do_pgfault+0xb2>
     * (写一个不存在的地址且地址是可写的) 或
     * (读一个不存在的地址且地址是可读的)
     * 那么继续处理
     */
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE)
ffffffffc02027b2:	6d1c                	ld	a5,24(a0)
    uint32_t perm = PTE_U;
ffffffffc02027b4:	4941                	li	s2,16
    if (vma->vm_flags & VM_WRITE)
ffffffffc02027b6:	8b89                	andi	a5,a5,2
ffffffffc02027b8:	efa9                	bnez	a5,ffffffffc0202812 <do_pgfault+0x90>
    {
        perm |= (PTE_R | PTE_W);
    }
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc02027ba:	767d                	lui	a2,0xfffff
     * 变量:
     *   mm->pgdir : 这些 vma 的页目录表
     *
     */

    ptep = get_pte(mm->pgdir, addr, 1); //(1) 尝试找到一个页表项，如果页表项的页表不存在，则创建一个页表。
ffffffffc02027bc:	6c88                	ld	a0,24(s1)
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc02027be:	8c71                	and	s0,s0,a2
    ptep = get_pte(mm->pgdir, addr, 1); //(1) 尝试找到一个页表项，如果页表项的页表不存在，则创建一个页表。
ffffffffc02027c0:	85a2                	mv	a1,s0
ffffffffc02027c2:	4605                	li	a2,1
ffffffffc02027c4:	c16fe0ef          	jal	ra,ffffffffc0200bda <get_pte>
    if (*ptep == 0)
ffffffffc02027c8:	610c                	ld	a1,0(a0)
ffffffffc02027ca:	c5b1                	beqz	a1,ffffffffc0202816 <do_pgfault+0x94>
         *    swap_in(mm, addr, &page) : 分配一个内存页，然后根据
         *    PTE中的swap条目的addr，找到磁盘页的地址，将磁盘页的内容读入这个内存页
         *    page_insert ： 建立一个Page的phy addr与线性addr la的映射
         *    swap_map_swappable ： 设置页面可交换
         */
        if (swap_init_ok)
ffffffffc02027cc:	0000f797          	auipc	a5,0xf
ffffffffc02027d0:	ca478793          	addi	a5,a5,-860 # ffffffffc0211470 <swap_init_ok>
ffffffffc02027d4:	439c                	lw	a5,0(a5)
ffffffffc02027d6:	2781                	sext.w	a5,a5
ffffffffc02027d8:	c7bd                	beqz	a5,ffffffffc0202846 <do_pgfault+0xc4>
        {
            struct Page *page = NULL;
            // 你要编写的内容在这里，请基于上文说明以及下文的英文注释完成代码编写
            //(1）根据 mm 和 addr，尝试将正确的磁盘页内容加载到 page 管理的内存中。
            swap_in(mm, addr, &page);
ffffffffc02027da:	85a2                	mv	a1,s0
ffffffffc02027dc:	0030                	addi	a2,sp,8
ffffffffc02027de:	8526                	mv	a0,s1
            struct Page *page = NULL;
ffffffffc02027e0:	e402                	sd	zero,8(sp)
            swap_in(mm, addr, &page);
ffffffffc02027e2:	049000ef          	jal	ra,ffffffffc020302a <swap_in>
            //(2) 根据 mm、addr 和 page，设置物理地址和逻辑地址之间的映射。
            page_insert(mm->pgdir, page, addr, perm);
ffffffffc02027e6:	65a2                	ld	a1,8(sp)
ffffffffc02027e8:	6c88                	ld	a0,24(s1)
ffffffffc02027ea:	86ca                	mv	a3,s2
ffffffffc02027ec:	8622                	mv	a2,s0
ffffffffc02027ee:	ebafe0ef          	jal	ra,ffffffffc0200ea8 <page_insert>
            //(3) 使页面可交换。
            swap_map_swappable(mm, addr, page, 1);
ffffffffc02027f2:	6622                	ld	a2,8(sp)
ffffffffc02027f4:	4685                	li	a3,1
ffffffffc02027f6:	85a2                	mv	a1,s0
ffffffffc02027f8:	8526                	mv	a0,s1
ffffffffc02027fa:	70c000ef          	jal	ra,ffffffffc0202f06 <swap_map_swappable>
            page->pra_vaddr = addr;
ffffffffc02027fe:	6722                	ld	a4,8(sp)
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
            goto failed;
        }
    }

    ret = 0;
ffffffffc0202800:	4781                	li	a5,0
            page->pra_vaddr = addr;
ffffffffc0202802:	e320                	sd	s0,64(a4)
failed:
    return ret;
}
ffffffffc0202804:	70a2                	ld	ra,40(sp)
ffffffffc0202806:	7402                	ld	s0,32(sp)
ffffffffc0202808:	64e2                	ld	s1,24(sp)
ffffffffc020280a:	6942                	ld	s2,16(sp)
ffffffffc020280c:	853e                	mv	a0,a5
ffffffffc020280e:	6145                	addi	sp,sp,48
ffffffffc0202810:	8082                	ret
        perm |= (PTE_R | PTE_W);
ffffffffc0202812:	4959                	li	s2,22
ffffffffc0202814:	b75d                	j	ffffffffc02027ba <do_pgfault+0x38>
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL)
ffffffffc0202816:	6c88                	ld	a0,24(s1)
ffffffffc0202818:	864a                	mv	a2,s2
ffffffffc020281a:	85a2                	mv	a1,s0
ffffffffc020281c:	a3cff0ef          	jal	ra,ffffffffc0201a58 <pgdir_alloc_page>
    ret = 0;
ffffffffc0202820:	4781                	li	a5,0
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL)
ffffffffc0202822:	f16d                	bnez	a0,ffffffffc0202804 <do_pgfault+0x82>
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
ffffffffc0202824:	00003517          	auipc	a0,0x3
ffffffffc0202828:	db450513          	addi	a0,a0,-588 # ffffffffc02055d8 <commands+0x1130>
ffffffffc020282c:	893fd0ef          	jal	ra,ffffffffc02000be <cprintf>
    ret = -E_NO_MEM;
ffffffffc0202830:	57f1                	li	a5,-4
            goto failed;
ffffffffc0202832:	bfc9                	j	ffffffffc0202804 <do_pgfault+0x82>
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
ffffffffc0202834:	85a2                	mv	a1,s0
ffffffffc0202836:	00003517          	auipc	a0,0x3
ffffffffc020283a:	d7250513          	addi	a0,a0,-654 # ffffffffc02055a8 <commands+0x1100>
ffffffffc020283e:	881fd0ef          	jal	ra,ffffffffc02000be <cprintf>
    int ret = -E_INVAL;
ffffffffc0202842:	57f5                	li	a5,-3
        goto failed;
ffffffffc0202844:	b7c1                	j	ffffffffc0202804 <do_pgfault+0x82>
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
ffffffffc0202846:	00003517          	auipc	a0,0x3
ffffffffc020284a:	dba50513          	addi	a0,a0,-582 # ffffffffc0205600 <commands+0x1158>
ffffffffc020284e:	871fd0ef          	jal	ra,ffffffffc02000be <cprintf>
    ret = -E_NO_MEM;
ffffffffc0202852:	57f1                	li	a5,-4
            goto failed;
ffffffffc0202854:	bf45                	j	ffffffffc0202804 <do_pgfault+0x82>

ffffffffc0202856 <swap_init>:
unsigned int swap_in_seq_no[MAX_SEQ_NO], swap_out_seq_no[MAX_SEQ_NO];

static void check_swap(void);

int swap_init(void)
{
ffffffffc0202856:	7135                	addi	sp,sp,-160
ffffffffc0202858:	ed06                	sd	ra,152(sp)
ffffffffc020285a:	e922                	sd	s0,144(sp)
ffffffffc020285c:	e526                	sd	s1,136(sp)
ffffffffc020285e:	e14a                	sd	s2,128(sp)
ffffffffc0202860:	fcce                	sd	s3,120(sp)
ffffffffc0202862:	f8d2                	sd	s4,112(sp)
ffffffffc0202864:	f4d6                	sd	s5,104(sp)
ffffffffc0202866:	f0da                	sd	s6,96(sp)
ffffffffc0202868:	ecde                	sd	s7,88(sp)
ffffffffc020286a:	e8e2                	sd	s8,80(sp)
ffffffffc020286c:	e4e6                	sd	s9,72(sp)
ffffffffc020286e:	e0ea                	sd	s10,64(sp)
ffffffffc0202870:	fc6e                	sd	s11,56(sp)
     swapfs_init();
ffffffffc0202872:	3f2010ef          	jal	ra,ffffffffc0203c64 <swapfs_init>

     // 由于 IDE 是模拟的，它最多只能存储 7 页以通过测试
     if (!(7 <= max_swap_offset &&
ffffffffc0202876:	0000f797          	auipc	a5,0xf
ffffffffc020287a:	cca78793          	addi	a5,a5,-822 # ffffffffc0211540 <max_swap_offset>
ffffffffc020287e:	6394                	ld	a3,0(a5)
ffffffffc0202880:	010007b7          	lui	a5,0x1000
ffffffffc0202884:	17e1                	addi	a5,a5,-8
ffffffffc0202886:	ff968713          	addi	a4,a3,-7
ffffffffc020288a:	42e7ea63          	bltu	a5,a4,ffffffffc0202cbe <swap_init+0x468>
     {
          panic("bad max_swap_offset %08x.\n", max_swap_offset);
     }

     // sm = &swap_manager_clock; // 使用CLOCK页面置换算法
     sm = &swap_manager_fifo; // 使用FIFO页面替换算法
ffffffffc020288e:	00007797          	auipc	a5,0x7
ffffffffc0202892:	77278793          	addi	a5,a5,1906 # ffffffffc020a000 <swap_manager_fifo>
     int r = sm->init();
ffffffffc0202896:	6798                	ld	a4,8(a5)
     sm = &swap_manager_fifo; // 使用FIFO页面替换算法
ffffffffc0202898:	0000f697          	auipc	a3,0xf
ffffffffc020289c:	bcf6b823          	sd	a5,-1072(a3) # ffffffffc0211468 <sm>
     int r = sm->init();
ffffffffc02028a0:	9702                	jalr	a4
ffffffffc02028a2:	8b2a                	mv	s6,a0

     if (r == 0)
ffffffffc02028a4:	c10d                	beqz	a0,ffffffffc02028c6 <swap_init+0x70>
          cprintf("SWAP: manager = %s\n", sm->name);
          check_swap();
     }

     return r;
}
ffffffffc02028a6:	60ea                	ld	ra,152(sp)
ffffffffc02028a8:	644a                	ld	s0,144(sp)
ffffffffc02028aa:	855a                	mv	a0,s6
ffffffffc02028ac:	64aa                	ld	s1,136(sp)
ffffffffc02028ae:	690a                	ld	s2,128(sp)
ffffffffc02028b0:	79e6                	ld	s3,120(sp)
ffffffffc02028b2:	7a46                	ld	s4,112(sp)
ffffffffc02028b4:	7aa6                	ld	s5,104(sp)
ffffffffc02028b6:	7b06                	ld	s6,96(sp)
ffffffffc02028b8:	6be6                	ld	s7,88(sp)
ffffffffc02028ba:	6c46                	ld	s8,80(sp)
ffffffffc02028bc:	6ca6                	ld	s9,72(sp)
ffffffffc02028be:	6d06                	ld	s10,64(sp)
ffffffffc02028c0:	7de2                	ld	s11,56(sp)
ffffffffc02028c2:	610d                	addi	sp,sp,160
ffffffffc02028c4:	8082                	ret
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc02028c6:	0000f797          	auipc	a5,0xf
ffffffffc02028ca:	ba278793          	addi	a5,a5,-1118 # ffffffffc0211468 <sm>
ffffffffc02028ce:	639c                	ld	a5,0(a5)
ffffffffc02028d0:	00003517          	auipc	a0,0x3
ffffffffc02028d4:	07050513          	addi	a0,a0,112 # ffffffffc0205940 <commands+0x1498>
ffffffffc02028d8:	0000f417          	auipc	s0,0xf
ffffffffc02028dc:	ca840413          	addi	s0,s0,-856 # ffffffffc0211580 <free_area>
ffffffffc02028e0:	638c                	ld	a1,0(a5)
          swap_init_ok = 1;
ffffffffc02028e2:	4785                	li	a5,1
ffffffffc02028e4:	0000f717          	auipc	a4,0xf
ffffffffc02028e8:	b8f72623          	sw	a5,-1140(a4) # ffffffffc0211470 <swap_init_ok>
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc02028ec:	fd2fd0ef          	jal	ra,ffffffffc02000be <cprintf>
ffffffffc02028f0:	641c                	ld	a5,8(s0)
check_swap(void)
{
     // 备份内存环境
     int ret, count = 0, total = 0, i;
     list_entry_t *le = &free_list;
     while ((le = list_next(le)) != &free_list)
ffffffffc02028f2:	2e878a63          	beq	a5,s0,ffffffffc0202be6 <swap_init+0x390>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02028f6:	fe87b703          	ld	a4,-24(a5)
ffffffffc02028fa:	8305                	srli	a4,a4,0x1
     {
          struct Page *p = le2page(le, page_link);
          assert(PageProperty(p));
ffffffffc02028fc:	8b05                	andi	a4,a4,1
ffffffffc02028fe:	2e070863          	beqz	a4,ffffffffc0202bee <swap_init+0x398>
     int ret, count = 0, total = 0, i;
ffffffffc0202902:	4481                	li	s1,0
ffffffffc0202904:	4901                	li	s2,0
ffffffffc0202906:	a031                	j	ffffffffc0202912 <swap_init+0xbc>
ffffffffc0202908:	fe87b703          	ld	a4,-24(a5)
          assert(PageProperty(p));
ffffffffc020290c:	8b09                	andi	a4,a4,2
ffffffffc020290e:	2e070063          	beqz	a4,ffffffffc0202bee <swap_init+0x398>
          count++, total += p->property;
ffffffffc0202912:	ff87a703          	lw	a4,-8(a5)
ffffffffc0202916:	679c                	ld	a5,8(a5)
ffffffffc0202918:	2905                	addiw	s2,s2,1
ffffffffc020291a:	9cb9                	addw	s1,s1,a4
     while ((le = list_next(le)) != &free_list)
ffffffffc020291c:	fe8796e3          	bne	a5,s0,ffffffffc0202908 <swap_init+0xb2>
ffffffffc0202920:	89a6                	mv	s3,s1
     }
     assert(total == nr_free_pages());
ffffffffc0202922:	a78fe0ef          	jal	ra,ffffffffc0200b9a <nr_free_pages>
ffffffffc0202926:	5b351863          	bne	a0,s3,ffffffffc0202ed6 <swap_init+0x680>
     cprintf("BEGIN check_swap: count %d, total %d\n", count, total);
ffffffffc020292a:	8626                	mv	a2,s1
ffffffffc020292c:	85ca                	mv	a1,s2
ffffffffc020292e:	00003517          	auipc	a0,0x3
ffffffffc0202932:	05a50513          	addi	a0,a0,90 # ffffffffc0205988 <commands+0x14e0>
ffffffffc0202936:	f88fd0ef          	jal	ra,ffffffffc02000be <cprintf>

     // 现在我们设置物理页环境
     struct mm_struct *mm = mm_create();
ffffffffc020293a:	f4eff0ef          	jal	ra,ffffffffc0202088 <mm_create>
ffffffffc020293e:	8baa                	mv	s7,a0
     assert(mm != NULL);
ffffffffc0202940:	50050b63          	beqz	a0,ffffffffc0202e56 <swap_init+0x600>

     extern struct mm_struct *check_mm_struct;
     assert(check_mm_struct == NULL);
ffffffffc0202944:	0000f797          	auipc	a5,0xf
ffffffffc0202948:	b6c78793          	addi	a5,a5,-1172 # ffffffffc02114b0 <check_mm_struct>
ffffffffc020294c:	639c                	ld	a5,0(a5)
ffffffffc020294e:	52079463          	bnez	a5,ffffffffc0202e76 <swap_init+0x620>

     check_mm_struct = mm;

     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0202952:	0000f797          	auipc	a5,0xf
ffffffffc0202956:	afe78793          	addi	a5,a5,-1282 # ffffffffc0211450 <boot_pgdir>
ffffffffc020295a:	6398                	ld	a4,0(a5)
     check_mm_struct = mm;
ffffffffc020295c:	0000f797          	auipc	a5,0xf
ffffffffc0202960:	b4a7ba23          	sd	a0,-1196(a5) # ffffffffc02114b0 <check_mm_struct>
     assert(pgdir[0] == 0);
ffffffffc0202964:	631c                	ld	a5,0(a4)
     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0202966:	ec3a                	sd	a4,24(sp)
ffffffffc0202968:	ed18                	sd	a4,24(a0)
     assert(pgdir[0] == 0);
ffffffffc020296a:	52079663          	bnez	a5,ffffffffc0202e96 <swap_init+0x640>

     struct vma_struct *vma = vma_create(BEING_CHECK_VALID_VADDR, CHECK_VALID_VADDR, VM_WRITE | VM_READ);
ffffffffc020296e:	6599                	lui	a1,0x6
ffffffffc0202970:	460d                	li	a2,3
ffffffffc0202972:	6505                	lui	a0,0x1
ffffffffc0202974:	f60ff0ef          	jal	ra,ffffffffc02020d4 <vma_create>
ffffffffc0202978:	85aa                	mv	a1,a0
     assert(vma != NULL);
ffffffffc020297a:	52050e63          	beqz	a0,ffffffffc0202eb6 <swap_init+0x660>

     insert_vma_struct(mm, vma);
ffffffffc020297e:	855e                	mv	a0,s7
ffffffffc0202980:	fc0ff0ef          	jal	ra,ffffffffc0202140 <insert_vma_struct>

     // 设置临时页表 vaddr 0~4MB
     cprintf("setup Page Table for vaddr 0X1000, so alloc a page\n");
ffffffffc0202984:	00003517          	auipc	a0,0x3
ffffffffc0202988:	04450513          	addi	a0,a0,68 # ffffffffc02059c8 <commands+0x1520>
ffffffffc020298c:	f32fd0ef          	jal	ra,ffffffffc02000be <cprintf>
     pte_t *temp_ptep = NULL;
     temp_ptep = get_pte(mm->pgdir, BEING_CHECK_VALID_VADDR, 1);
ffffffffc0202990:	018bb503          	ld	a0,24(s7)
ffffffffc0202994:	4605                	li	a2,1
ffffffffc0202996:	6585                	lui	a1,0x1
ffffffffc0202998:	a42fe0ef          	jal	ra,ffffffffc0200bda <get_pte>
     assert(temp_ptep != NULL);
ffffffffc020299c:	40050d63          	beqz	a0,ffffffffc0202db6 <swap_init+0x560>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc02029a0:	00003517          	auipc	a0,0x3
ffffffffc02029a4:	07850513          	addi	a0,a0,120 # ffffffffc0205a18 <commands+0x1570>
ffffffffc02029a8:	0000fa17          	auipc	s4,0xf
ffffffffc02029ac:	b10a0a13          	addi	s4,s4,-1264 # ffffffffc02114b8 <check_rp>
ffffffffc02029b0:	f0efd0ef          	jal	ra,ffffffffc02000be <cprintf>

     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++)
ffffffffc02029b4:	0000fa97          	auipc	s5,0xf
ffffffffc02029b8:	b24a8a93          	addi	s5,s5,-1244 # ffffffffc02114d8 <swap_in_seq_no>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc02029bc:	89d2                	mv	s3,s4
     {
          check_rp[i] = alloc_page();
ffffffffc02029be:	4505                	li	a0,1
ffffffffc02029c0:	90cfe0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc02029c4:	00a9b023          	sd	a0,0(s3)
          assert(check_rp[i] != NULL);
ffffffffc02029c8:	2a050b63          	beqz	a0,ffffffffc0202c7e <swap_init+0x428>
ffffffffc02029cc:	651c                	ld	a5,8(a0)
          assert(!PageProperty(check_rp[i]));
ffffffffc02029ce:	8b89                	andi	a5,a5,2
ffffffffc02029d0:	28079763          	bnez	a5,ffffffffc0202c5e <swap_init+0x408>
ffffffffc02029d4:	09a1                	addi	s3,s3,8
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++)
ffffffffc02029d6:	ff5994e3          	bne	s3,s5,ffffffffc02029be <swap_init+0x168>
     }
     list_entry_t free_list_store = free_list;
ffffffffc02029da:	601c                	ld	a5,0(s0)
ffffffffc02029dc:	00843983          	ld	s3,8(s0)
     assert(list_empty(&free_list));

     // assert(alloc_page() == NULL);

     unsigned int nr_free_store = nr_free;
     nr_free = 0;
ffffffffc02029e0:	0000fd17          	auipc	s10,0xf
ffffffffc02029e4:	ad8d0d13          	addi	s10,s10,-1320 # ffffffffc02114b8 <check_rp>
     list_entry_t free_list_store = free_list;
ffffffffc02029e8:	f03e                	sd	a5,32(sp)
     unsigned int nr_free_store = nr_free;
ffffffffc02029ea:	481c                	lw	a5,16(s0)
ffffffffc02029ec:	f43e                	sd	a5,40(sp)
    elm->prev = elm->next = elm;
ffffffffc02029ee:	0000f797          	auipc	a5,0xf
ffffffffc02029f2:	b887bd23          	sd	s0,-1126(a5) # ffffffffc0211588 <free_area+0x8>
ffffffffc02029f6:	0000f797          	auipc	a5,0xf
ffffffffc02029fa:	b887b523          	sd	s0,-1142(a5) # ffffffffc0211580 <free_area>
     nr_free = 0;
ffffffffc02029fe:	0000f797          	auipc	a5,0xf
ffffffffc0202a02:	b807a923          	sw	zero,-1134(a5) # ffffffffc0211590 <free_area+0x10>
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++)
     {
          free_pages(check_rp[i], 1);
ffffffffc0202a06:	000d3503          	ld	a0,0(s10)
ffffffffc0202a0a:	4585                	li	a1,1
ffffffffc0202a0c:	0d21                	addi	s10,s10,8
ffffffffc0202a0e:	946fe0ef          	jal	ra,ffffffffc0200b54 <free_pages>
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++)
ffffffffc0202a12:	ff5d1ae3          	bne	s10,s5,ffffffffc0202a06 <swap_init+0x1b0>
     }
     assert(nr_free == CHECK_VALID_PHY_PAGE_NUM);
ffffffffc0202a16:	01042d03          	lw	s10,16(s0)
ffffffffc0202a1a:	4791                	li	a5,4
ffffffffc0202a1c:	36fd1d63          	bne	s10,a5,ffffffffc0202d96 <swap_init+0x540>

     cprintf("set up init env for check_swap begin!\n");
ffffffffc0202a20:	00003517          	auipc	a0,0x3
ffffffffc0202a24:	08050513          	addi	a0,a0,128 # ffffffffc0205aa0 <commands+0x15f8>
ffffffffc0202a28:	e96fd0ef          	jal	ra,ffffffffc02000be <cprintf>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0202a2c:	6685                	lui	a3,0x1
     // 设置初始虚拟页<->物理页环境以测试页面置换算法

     pgfault_num = 0;
ffffffffc0202a2e:	0000f797          	auipc	a5,0xf
ffffffffc0202a32:	a207a923          	sw	zero,-1486(a5) # ffffffffc0211460 <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0202a36:	4629                	li	a2,10
     pgfault_num = 0;
ffffffffc0202a38:	0000f797          	auipc	a5,0xf
ffffffffc0202a3c:	a2878793          	addi	a5,a5,-1496 # ffffffffc0211460 <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0202a40:	00c68023          	sb	a2,0(a3) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
     assert(pgfault_num == 1);
ffffffffc0202a44:	4398                	lw	a4,0(a5)
ffffffffc0202a46:	4585                	li	a1,1
ffffffffc0202a48:	2701                	sext.w	a4,a4
ffffffffc0202a4a:	30b71663          	bne	a4,a1,ffffffffc0202d56 <swap_init+0x500>
     *(unsigned char *)0x1010 = 0x0a;
ffffffffc0202a4e:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num == 1);
ffffffffc0202a52:	4394                	lw	a3,0(a5)
ffffffffc0202a54:	2681                	sext.w	a3,a3
ffffffffc0202a56:	32e69063          	bne	a3,a4,ffffffffc0202d76 <swap_init+0x520>
     *(unsigned char *)0x2000 = 0x0b;
ffffffffc0202a5a:	6689                	lui	a3,0x2
ffffffffc0202a5c:	462d                	li	a2,11
ffffffffc0202a5e:	00c68023          	sb	a2,0(a3) # 2000 <BASE_ADDRESS-0xffffffffc01fe000>
     assert(pgfault_num == 2);
ffffffffc0202a62:	4398                	lw	a4,0(a5)
ffffffffc0202a64:	4589                	li	a1,2
ffffffffc0202a66:	2701                	sext.w	a4,a4
ffffffffc0202a68:	26b71763          	bne	a4,a1,ffffffffc0202cd6 <swap_init+0x480>
     *(unsigned char *)0x2010 = 0x0b;
ffffffffc0202a6c:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num == 2);
ffffffffc0202a70:	4394                	lw	a3,0(a5)
ffffffffc0202a72:	2681                	sext.w	a3,a3
ffffffffc0202a74:	28e69163          	bne	a3,a4,ffffffffc0202cf6 <swap_init+0x4a0>
     *(unsigned char *)0x3000 = 0x0c;
ffffffffc0202a78:	668d                	lui	a3,0x3
ffffffffc0202a7a:	4631                	li	a2,12
ffffffffc0202a7c:	00c68023          	sb	a2,0(a3) # 3000 <BASE_ADDRESS-0xffffffffc01fd000>
     assert(pgfault_num == 3);
ffffffffc0202a80:	4398                	lw	a4,0(a5)
ffffffffc0202a82:	458d                	li	a1,3
ffffffffc0202a84:	2701                	sext.w	a4,a4
ffffffffc0202a86:	28b71863          	bne	a4,a1,ffffffffc0202d16 <swap_init+0x4c0>
     *(unsigned char *)0x3010 = 0x0c;
ffffffffc0202a8a:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num == 3);
ffffffffc0202a8e:	4394                	lw	a3,0(a5)
ffffffffc0202a90:	2681                	sext.w	a3,a3
ffffffffc0202a92:	2ae69263          	bne	a3,a4,ffffffffc0202d36 <swap_init+0x4e0>
     *(unsigned char *)0x4000 = 0x0d;
ffffffffc0202a96:	6691                	lui	a3,0x4
ffffffffc0202a98:	4635                	li	a2,13
ffffffffc0202a9a:	00c68023          	sb	a2,0(a3) # 4000 <BASE_ADDRESS-0xffffffffc01fc000>
     assert(pgfault_num == 4);
ffffffffc0202a9e:	4398                	lw	a4,0(a5)
ffffffffc0202aa0:	2701                	sext.w	a4,a4
ffffffffc0202aa2:	33a71a63          	bne	a4,s10,ffffffffc0202dd6 <swap_init+0x580>
     *(unsigned char *)0x4010 = 0x0d;
ffffffffc0202aa6:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num == 4);
ffffffffc0202aaa:	439c                	lw	a5,0(a5)
ffffffffc0202aac:	2781                	sext.w	a5,a5
ffffffffc0202aae:	34e79463          	bne	a5,a4,ffffffffc0202df6 <swap_init+0x5a0>

     check_content_set();
     assert(nr_free == 0);
ffffffffc0202ab2:	481c                	lw	a5,16(s0)
ffffffffc0202ab4:	36079163          	bnez	a5,ffffffffc0202e16 <swap_init+0x5c0>
ffffffffc0202ab8:	0000f797          	auipc	a5,0xf
ffffffffc0202abc:	a2078793          	addi	a5,a5,-1504 # ffffffffc02114d8 <swap_in_seq_no>
ffffffffc0202ac0:	0000f717          	auipc	a4,0xf
ffffffffc0202ac4:	a4070713          	addi	a4,a4,-1472 # ffffffffc0211500 <swap_out_seq_no>
ffffffffc0202ac8:	0000f617          	auipc	a2,0xf
ffffffffc0202acc:	a3860613          	addi	a2,a2,-1480 # ffffffffc0211500 <swap_out_seq_no>
     for (i = 0; i < MAX_SEQ_NO; i++)
          swap_out_seq_no[i] = swap_in_seq_no[i] = -1;
ffffffffc0202ad0:	56fd                	li	a3,-1
ffffffffc0202ad2:	c394                	sw	a3,0(a5)
ffffffffc0202ad4:	c314                	sw	a3,0(a4)
ffffffffc0202ad6:	0791                	addi	a5,a5,4
ffffffffc0202ad8:	0711                	addi	a4,a4,4
     for (i = 0; i < MAX_SEQ_NO; i++)
ffffffffc0202ada:	fec79ce3          	bne	a5,a2,ffffffffc0202ad2 <swap_init+0x27c>
ffffffffc0202ade:	0000f697          	auipc	a3,0xf
ffffffffc0202ae2:	a8268693          	addi	a3,a3,-1406 # ffffffffc0211560 <check_ptep>
ffffffffc0202ae6:	0000f817          	auipc	a6,0xf
ffffffffc0202aea:	9d280813          	addi	a6,a6,-1582 # ffffffffc02114b8 <check_rp>
ffffffffc0202aee:	6c05                	lui	s8,0x1
    if (PPN(pa) >= npage) {
ffffffffc0202af0:	0000fc97          	auipc	s9,0xf
ffffffffc0202af4:	968c8c93          	addi	s9,s9,-1688 # ffffffffc0211458 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0202af8:	0000fd97          	auipc	s11,0xf
ffffffffc0202afc:	9a0d8d93          	addi	s11,s11,-1632 # ffffffffc0211498 <pages>
ffffffffc0202b00:	00003d17          	auipc	s10,0x3
ffffffffc0202b04:	7d8d0d13          	addi	s10,s10,2008 # ffffffffc02062d8 <nbase>

     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++)
     {
          check_ptep[i] = 0;
          check_ptep[i] = get_pte(pgdir, (i + 1) * 0x1000, 0);
ffffffffc0202b08:	6562                	ld	a0,24(sp)
          check_ptep[i] = 0;
ffffffffc0202b0a:	0006b023          	sd	zero,0(a3)
          check_ptep[i] = get_pte(pgdir, (i + 1) * 0x1000, 0);
ffffffffc0202b0e:	4601                	li	a2,0
ffffffffc0202b10:	85e2                	mv	a1,s8
ffffffffc0202b12:	e842                	sd	a6,16(sp)
          check_ptep[i] = 0;
ffffffffc0202b14:	e436                	sd	a3,8(sp)
          check_ptep[i] = get_pte(pgdir, (i + 1) * 0x1000, 0);
ffffffffc0202b16:	8c4fe0ef          	jal	ra,ffffffffc0200bda <get_pte>
ffffffffc0202b1a:	66a2                	ld	a3,8(sp)
          // cprintf("i %d, check_ptep addr %x, value %x\n", i, check_ptep[i], *check_ptep[i]);
          assert(check_ptep[i] != NULL);
ffffffffc0202b1c:	6842                	ld	a6,16(sp)
          check_ptep[i] = get_pte(pgdir, (i + 1) * 0x1000, 0);
ffffffffc0202b1e:	e288                	sd	a0,0(a3)
          assert(check_ptep[i] != NULL);
ffffffffc0202b20:	16050f63          	beqz	a0,ffffffffc0202c9e <swap_init+0x448>
          assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0202b24:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0202b26:	0017f613          	andi	a2,a5,1
ffffffffc0202b2a:	10060263          	beqz	a2,ffffffffc0202c2e <swap_init+0x3d8>
    if (PPN(pa) >= npage) {
ffffffffc0202b2e:	000cb603          	ld	a2,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202b32:	078a                	slli	a5,a5,0x2
ffffffffc0202b34:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202b36:	10c7f863          	bgeu	a5,a2,ffffffffc0202c46 <swap_init+0x3f0>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b3a:	000d3603          	ld	a2,0(s10)
ffffffffc0202b3e:	000db583          	ld	a1,0(s11)
ffffffffc0202b42:	00083503          	ld	a0,0(a6)
ffffffffc0202b46:	8f91                	sub	a5,a5,a2
ffffffffc0202b48:	00379613          	slli	a2,a5,0x3
ffffffffc0202b4c:	97b2                	add	a5,a5,a2
ffffffffc0202b4e:	078e                	slli	a5,a5,0x3
ffffffffc0202b50:	97ae                	add	a5,a5,a1
ffffffffc0202b52:	0af51e63          	bne	a0,a5,ffffffffc0202c0e <swap_init+0x3b8>
ffffffffc0202b56:	6785                	lui	a5,0x1
ffffffffc0202b58:	9c3e                	add	s8,s8,a5
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++)
ffffffffc0202b5a:	6795                	lui	a5,0x5
ffffffffc0202b5c:	06a1                	addi	a3,a3,8
ffffffffc0202b5e:	0821                	addi	a6,a6,8
ffffffffc0202b60:	fafc14e3          	bne	s8,a5,ffffffffc0202b08 <swap_init+0x2b2>
          assert((*check_ptep[i] & PTE_V));
     }
     cprintf("set up init env for check_swap over!\n");
ffffffffc0202b64:	00003517          	auipc	a0,0x3
ffffffffc0202b68:	ffc50513          	addi	a0,a0,-4 # ffffffffc0205b60 <commands+0x16b8>
ffffffffc0202b6c:	d52fd0ef          	jal	ra,ffffffffc02000be <cprintf>
     int ret = sm->check_swap();
ffffffffc0202b70:	0000f797          	auipc	a5,0xf
ffffffffc0202b74:	8f878793          	addi	a5,a5,-1800 # ffffffffc0211468 <sm>
ffffffffc0202b78:	639c                	ld	a5,0(a5)
ffffffffc0202b7a:	7f9c                	ld	a5,56(a5)
ffffffffc0202b7c:	9782                	jalr	a5
     // 现在访问虚拟页以测试页面置换算法
     ret = check_content_access();
     assert(ret == 0);
ffffffffc0202b7e:	2a051c63          	bnez	a0,ffffffffc0202e36 <swap_init+0x5e0>

     // 恢复内核内存环境
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++)
     {
          free_pages(check_rp[i], 1);
ffffffffc0202b82:	000a3503          	ld	a0,0(s4)
ffffffffc0202b86:	4585                	li	a1,1
ffffffffc0202b88:	0a21                	addi	s4,s4,8
ffffffffc0202b8a:	fcbfd0ef          	jal	ra,ffffffffc0200b54 <free_pages>
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++)
ffffffffc0202b8e:	ff5a1ae3          	bne	s4,s5,ffffffffc0202b82 <swap_init+0x32c>
     }

     // free_page(pte2page(*temp_ptep));

     mm_destroy(mm);
ffffffffc0202b92:	855e                	mv	a0,s7
ffffffffc0202b94:	e7aff0ef          	jal	ra,ffffffffc020220e <mm_destroy>

     nr_free = nr_free_store;
ffffffffc0202b98:	77a2                	ld	a5,40(sp)
ffffffffc0202b9a:	0000f717          	auipc	a4,0xf
ffffffffc0202b9e:	9ef72b23          	sw	a5,-1546(a4) # ffffffffc0211590 <free_area+0x10>
     free_list = free_list_store;
ffffffffc0202ba2:	7782                	ld	a5,32(sp)
ffffffffc0202ba4:	0000f717          	auipc	a4,0xf
ffffffffc0202ba8:	9cf73e23          	sd	a5,-1572(a4) # ffffffffc0211580 <free_area>
ffffffffc0202bac:	0000f797          	auipc	a5,0xf
ffffffffc0202bb0:	9d37be23          	sd	s3,-1572(a5) # ffffffffc0211588 <free_area+0x8>

     le = &free_list;
     while ((le = list_next(le)) != &free_list)
ffffffffc0202bb4:	00898a63          	beq	s3,s0,ffffffffc0202bc8 <swap_init+0x372>
     {
          struct Page *p = le2page(le, page_link);
          count--, total -= p->property;
ffffffffc0202bb8:	ff89a783          	lw	a5,-8(s3)
    return listelm->next;
ffffffffc0202bbc:	0089b983          	ld	s3,8(s3)
ffffffffc0202bc0:	397d                	addiw	s2,s2,-1
ffffffffc0202bc2:	9c9d                	subw	s1,s1,a5
     while ((le = list_next(le)) != &free_list)
ffffffffc0202bc4:	fe899ae3          	bne	s3,s0,ffffffffc0202bb8 <swap_init+0x362>
     }
     cprintf("count is %d, total is %d\n", count, total);
ffffffffc0202bc8:	8626                	mv	a2,s1
ffffffffc0202bca:	85ca                	mv	a1,s2
ffffffffc0202bcc:	00003517          	auipc	a0,0x3
ffffffffc0202bd0:	fcc50513          	addi	a0,a0,-52 # ffffffffc0205b98 <commands+0x16f0>
ffffffffc0202bd4:	ceafd0ef          	jal	ra,ffffffffc02000be <cprintf>
     // assert(count == 0);

     cprintf("check_swap() succeeded!\n");
ffffffffc0202bd8:	00003517          	auipc	a0,0x3
ffffffffc0202bdc:	fe050513          	addi	a0,a0,-32 # ffffffffc0205bb8 <commands+0x1710>
ffffffffc0202be0:	cdefd0ef          	jal	ra,ffffffffc02000be <cprintf>
ffffffffc0202be4:	b1c9                	j	ffffffffc02028a6 <swap_init+0x50>
     int ret, count = 0, total = 0, i;
ffffffffc0202be6:	4481                	li	s1,0
ffffffffc0202be8:	4901                	li	s2,0
     while ((le = list_next(le)) != &free_list)
ffffffffc0202bea:	4981                	li	s3,0
ffffffffc0202bec:	bb1d                	j	ffffffffc0202922 <swap_init+0xcc>
          assert(PageProperty(p));
ffffffffc0202bee:	00003697          	auipc	a3,0x3
ffffffffc0202bf2:	d6a68693          	addi	a3,a3,-662 # ffffffffc0205958 <commands+0x14b0>
ffffffffc0202bf6:	00002617          	auipc	a2,0x2
ffffffffc0202bfa:	2a260613          	addi	a2,a2,674 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0202bfe:	0b700593          	li	a1,183
ffffffffc0202c02:	00003517          	auipc	a0,0x3
ffffffffc0202c06:	d2e50513          	addi	a0,a0,-722 # ffffffffc0205930 <commands+0x1488>
ffffffffc0202c0a:	cfafd0ef          	jal	ra,ffffffffc0200104 <__panic>
          assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0202c0e:	00003697          	auipc	a3,0x3
ffffffffc0202c12:	f2a68693          	addi	a3,a3,-214 # ffffffffc0205b38 <commands+0x1690>
ffffffffc0202c16:	00002617          	auipc	a2,0x2
ffffffffc0202c1a:	28260613          	addi	a2,a2,642 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0202c1e:	0f900593          	li	a1,249
ffffffffc0202c22:	00003517          	auipc	a0,0x3
ffffffffc0202c26:	d0e50513          	addi	a0,a0,-754 # ffffffffc0205930 <commands+0x1488>
ffffffffc0202c2a:	cdafd0ef          	jal	ra,ffffffffc0200104 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0202c2e:	00002617          	auipc	a2,0x2
ffffffffc0202c32:	34260613          	addi	a2,a2,834 # ffffffffc0204f70 <commands+0xac8>
ffffffffc0202c36:	07000593          	li	a1,112
ffffffffc0202c3a:	00002517          	auipc	a0,0x2
ffffffffc0202c3e:	14650513          	addi	a0,a0,326 # ffffffffc0204d80 <commands+0x8d8>
ffffffffc0202c42:	cc2fd0ef          	jal	ra,ffffffffc0200104 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0202c46:	00002617          	auipc	a2,0x2
ffffffffc0202c4a:	11a60613          	addi	a2,a2,282 # ffffffffc0204d60 <commands+0x8b8>
ffffffffc0202c4e:	06500593          	li	a1,101
ffffffffc0202c52:	00002517          	auipc	a0,0x2
ffffffffc0202c56:	12e50513          	addi	a0,a0,302 # ffffffffc0204d80 <commands+0x8d8>
ffffffffc0202c5a:	caafd0ef          	jal	ra,ffffffffc0200104 <__panic>
          assert(!PageProperty(check_rp[i]));
ffffffffc0202c5e:	00003697          	auipc	a3,0x3
ffffffffc0202c62:	dfa68693          	addi	a3,a3,-518 # ffffffffc0205a58 <commands+0x15b0>
ffffffffc0202c66:	00002617          	auipc	a2,0x2
ffffffffc0202c6a:	23260613          	addi	a2,a2,562 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0202c6e:	0d900593          	li	a1,217
ffffffffc0202c72:	00003517          	auipc	a0,0x3
ffffffffc0202c76:	cbe50513          	addi	a0,a0,-834 # ffffffffc0205930 <commands+0x1488>
ffffffffc0202c7a:	c8afd0ef          	jal	ra,ffffffffc0200104 <__panic>
          assert(check_rp[i] != NULL);
ffffffffc0202c7e:	00003697          	auipc	a3,0x3
ffffffffc0202c82:	dc268693          	addi	a3,a3,-574 # ffffffffc0205a40 <commands+0x1598>
ffffffffc0202c86:	00002617          	auipc	a2,0x2
ffffffffc0202c8a:	21260613          	addi	a2,a2,530 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0202c8e:	0d800593          	li	a1,216
ffffffffc0202c92:	00003517          	auipc	a0,0x3
ffffffffc0202c96:	c9e50513          	addi	a0,a0,-866 # ffffffffc0205930 <commands+0x1488>
ffffffffc0202c9a:	c6afd0ef          	jal	ra,ffffffffc0200104 <__panic>
          assert(check_ptep[i] != NULL);
ffffffffc0202c9e:	00003697          	auipc	a3,0x3
ffffffffc0202ca2:	e8268693          	addi	a3,a3,-382 # ffffffffc0205b20 <commands+0x1678>
ffffffffc0202ca6:	00002617          	auipc	a2,0x2
ffffffffc0202caa:	1f260613          	addi	a2,a2,498 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0202cae:	0f800593          	li	a1,248
ffffffffc0202cb2:	00003517          	auipc	a0,0x3
ffffffffc0202cb6:	c7e50513          	addi	a0,a0,-898 # ffffffffc0205930 <commands+0x1488>
ffffffffc0202cba:	c4afd0ef          	jal	ra,ffffffffc0200104 <__panic>
          panic("bad max_swap_offset %08x.\n", max_swap_offset);
ffffffffc0202cbe:	00003617          	auipc	a2,0x3
ffffffffc0202cc2:	c5260613          	addi	a2,a2,-942 # ffffffffc0205910 <commands+0x1468>
ffffffffc0202cc6:	02700593          	li	a1,39
ffffffffc0202cca:	00003517          	auipc	a0,0x3
ffffffffc0202cce:	c6650513          	addi	a0,a0,-922 # ffffffffc0205930 <commands+0x1488>
ffffffffc0202cd2:	c32fd0ef          	jal	ra,ffffffffc0200104 <__panic>
     assert(pgfault_num == 2);
ffffffffc0202cd6:	00003697          	auipc	a3,0x3
ffffffffc0202cda:	e0a68693          	addi	a3,a3,-502 # ffffffffc0205ae0 <commands+0x1638>
ffffffffc0202cde:	00002617          	auipc	a2,0x2
ffffffffc0202ce2:	1ba60613          	addi	a2,a2,442 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0202ce6:	09100593          	li	a1,145
ffffffffc0202cea:	00003517          	auipc	a0,0x3
ffffffffc0202cee:	c4650513          	addi	a0,a0,-954 # ffffffffc0205930 <commands+0x1488>
ffffffffc0202cf2:	c12fd0ef          	jal	ra,ffffffffc0200104 <__panic>
     assert(pgfault_num == 2);
ffffffffc0202cf6:	00003697          	auipc	a3,0x3
ffffffffc0202cfa:	dea68693          	addi	a3,a3,-534 # ffffffffc0205ae0 <commands+0x1638>
ffffffffc0202cfe:	00002617          	auipc	a2,0x2
ffffffffc0202d02:	19a60613          	addi	a2,a2,410 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0202d06:	09300593          	li	a1,147
ffffffffc0202d0a:	00003517          	auipc	a0,0x3
ffffffffc0202d0e:	c2650513          	addi	a0,a0,-986 # ffffffffc0205930 <commands+0x1488>
ffffffffc0202d12:	bf2fd0ef          	jal	ra,ffffffffc0200104 <__panic>
     assert(pgfault_num == 3);
ffffffffc0202d16:	00003697          	auipc	a3,0x3
ffffffffc0202d1a:	de268693          	addi	a3,a3,-542 # ffffffffc0205af8 <commands+0x1650>
ffffffffc0202d1e:	00002617          	auipc	a2,0x2
ffffffffc0202d22:	17a60613          	addi	a2,a2,378 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0202d26:	09500593          	li	a1,149
ffffffffc0202d2a:	00003517          	auipc	a0,0x3
ffffffffc0202d2e:	c0650513          	addi	a0,a0,-1018 # ffffffffc0205930 <commands+0x1488>
ffffffffc0202d32:	bd2fd0ef          	jal	ra,ffffffffc0200104 <__panic>
     assert(pgfault_num == 3);
ffffffffc0202d36:	00003697          	auipc	a3,0x3
ffffffffc0202d3a:	dc268693          	addi	a3,a3,-574 # ffffffffc0205af8 <commands+0x1650>
ffffffffc0202d3e:	00002617          	auipc	a2,0x2
ffffffffc0202d42:	15a60613          	addi	a2,a2,346 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0202d46:	09700593          	li	a1,151
ffffffffc0202d4a:	00003517          	auipc	a0,0x3
ffffffffc0202d4e:	be650513          	addi	a0,a0,-1050 # ffffffffc0205930 <commands+0x1488>
ffffffffc0202d52:	bb2fd0ef          	jal	ra,ffffffffc0200104 <__panic>
     assert(pgfault_num == 1);
ffffffffc0202d56:	00003697          	auipc	a3,0x3
ffffffffc0202d5a:	d7268693          	addi	a3,a3,-654 # ffffffffc0205ac8 <commands+0x1620>
ffffffffc0202d5e:	00002617          	auipc	a2,0x2
ffffffffc0202d62:	13a60613          	addi	a2,a2,314 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0202d66:	08d00593          	li	a1,141
ffffffffc0202d6a:	00003517          	auipc	a0,0x3
ffffffffc0202d6e:	bc650513          	addi	a0,a0,-1082 # ffffffffc0205930 <commands+0x1488>
ffffffffc0202d72:	b92fd0ef          	jal	ra,ffffffffc0200104 <__panic>
     assert(pgfault_num == 1);
ffffffffc0202d76:	00003697          	auipc	a3,0x3
ffffffffc0202d7a:	d5268693          	addi	a3,a3,-686 # ffffffffc0205ac8 <commands+0x1620>
ffffffffc0202d7e:	00002617          	auipc	a2,0x2
ffffffffc0202d82:	11a60613          	addi	a2,a2,282 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0202d86:	08f00593          	li	a1,143
ffffffffc0202d8a:	00003517          	auipc	a0,0x3
ffffffffc0202d8e:	ba650513          	addi	a0,a0,-1114 # ffffffffc0205930 <commands+0x1488>
ffffffffc0202d92:	b72fd0ef          	jal	ra,ffffffffc0200104 <__panic>
     assert(nr_free == CHECK_VALID_PHY_PAGE_NUM);
ffffffffc0202d96:	00003697          	auipc	a3,0x3
ffffffffc0202d9a:	ce268693          	addi	a3,a3,-798 # ffffffffc0205a78 <commands+0x15d0>
ffffffffc0202d9e:	00002617          	auipc	a2,0x2
ffffffffc0202da2:	0fa60613          	addi	a2,a2,250 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0202da6:	0e700593          	li	a1,231
ffffffffc0202daa:	00003517          	auipc	a0,0x3
ffffffffc0202dae:	b8650513          	addi	a0,a0,-1146 # ffffffffc0205930 <commands+0x1488>
ffffffffc0202db2:	b52fd0ef          	jal	ra,ffffffffc0200104 <__panic>
     assert(temp_ptep != NULL);
ffffffffc0202db6:	00003697          	auipc	a3,0x3
ffffffffc0202dba:	c4a68693          	addi	a3,a3,-950 # ffffffffc0205a00 <commands+0x1558>
ffffffffc0202dbe:	00002617          	auipc	a2,0x2
ffffffffc0202dc2:	0da60613          	addi	a2,a2,218 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0202dc6:	0d200593          	li	a1,210
ffffffffc0202dca:	00003517          	auipc	a0,0x3
ffffffffc0202dce:	b6650513          	addi	a0,a0,-1178 # ffffffffc0205930 <commands+0x1488>
ffffffffc0202dd2:	b32fd0ef          	jal	ra,ffffffffc0200104 <__panic>
     assert(pgfault_num == 4);
ffffffffc0202dd6:	00002697          	auipc	a3,0x2
ffffffffc0202dda:	5aa68693          	addi	a3,a3,1450 # ffffffffc0205380 <commands+0xed8>
ffffffffc0202dde:	00002617          	auipc	a2,0x2
ffffffffc0202de2:	0ba60613          	addi	a2,a2,186 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0202de6:	09900593          	li	a1,153
ffffffffc0202dea:	00003517          	auipc	a0,0x3
ffffffffc0202dee:	b4650513          	addi	a0,a0,-1210 # ffffffffc0205930 <commands+0x1488>
ffffffffc0202df2:	b12fd0ef          	jal	ra,ffffffffc0200104 <__panic>
     assert(pgfault_num == 4);
ffffffffc0202df6:	00002697          	auipc	a3,0x2
ffffffffc0202dfa:	58a68693          	addi	a3,a3,1418 # ffffffffc0205380 <commands+0xed8>
ffffffffc0202dfe:	00002617          	auipc	a2,0x2
ffffffffc0202e02:	09a60613          	addi	a2,a2,154 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0202e06:	09b00593          	li	a1,155
ffffffffc0202e0a:	00003517          	auipc	a0,0x3
ffffffffc0202e0e:	b2650513          	addi	a0,a0,-1242 # ffffffffc0205930 <commands+0x1488>
ffffffffc0202e12:	af2fd0ef          	jal	ra,ffffffffc0200104 <__panic>
     assert(nr_free == 0);
ffffffffc0202e16:	00003697          	auipc	a3,0x3
ffffffffc0202e1a:	cfa68693          	addi	a3,a3,-774 # ffffffffc0205b10 <commands+0x1668>
ffffffffc0202e1e:	00002617          	auipc	a2,0x2
ffffffffc0202e22:	07a60613          	addi	a2,a2,122 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0202e26:	0ef00593          	li	a1,239
ffffffffc0202e2a:	00003517          	auipc	a0,0x3
ffffffffc0202e2e:	b0650513          	addi	a0,a0,-1274 # ffffffffc0205930 <commands+0x1488>
ffffffffc0202e32:	ad2fd0ef          	jal	ra,ffffffffc0200104 <__panic>
     assert(ret == 0);
ffffffffc0202e36:	00003697          	auipc	a3,0x3
ffffffffc0202e3a:	d5268693          	addi	a3,a3,-686 # ffffffffc0205b88 <commands+0x16e0>
ffffffffc0202e3e:	00002617          	auipc	a2,0x2
ffffffffc0202e42:	05a60613          	addi	a2,a2,90 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0202e46:	0ff00593          	li	a1,255
ffffffffc0202e4a:	00003517          	auipc	a0,0x3
ffffffffc0202e4e:	ae650513          	addi	a0,a0,-1306 # ffffffffc0205930 <commands+0x1488>
ffffffffc0202e52:	ab2fd0ef          	jal	ra,ffffffffc0200104 <__panic>
     assert(mm != NULL);
ffffffffc0202e56:	00003697          	auipc	a3,0x3
ffffffffc0202e5a:	83268693          	addi	a3,a3,-1998 # ffffffffc0205688 <commands+0x11e0>
ffffffffc0202e5e:	00002617          	auipc	a2,0x2
ffffffffc0202e62:	03a60613          	addi	a2,a2,58 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0202e66:	0bf00593          	li	a1,191
ffffffffc0202e6a:	00003517          	auipc	a0,0x3
ffffffffc0202e6e:	ac650513          	addi	a0,a0,-1338 # ffffffffc0205930 <commands+0x1488>
ffffffffc0202e72:	a92fd0ef          	jal	ra,ffffffffc0200104 <__panic>
     assert(check_mm_struct == NULL);
ffffffffc0202e76:	00003697          	auipc	a3,0x3
ffffffffc0202e7a:	b3a68693          	addi	a3,a3,-1222 # ffffffffc02059b0 <commands+0x1508>
ffffffffc0202e7e:	00002617          	auipc	a2,0x2
ffffffffc0202e82:	01a60613          	addi	a2,a2,26 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0202e86:	0c200593          	li	a1,194
ffffffffc0202e8a:	00003517          	auipc	a0,0x3
ffffffffc0202e8e:	aa650513          	addi	a0,a0,-1370 # ffffffffc0205930 <commands+0x1488>
ffffffffc0202e92:	a72fd0ef          	jal	ra,ffffffffc0200104 <__panic>
     assert(pgdir[0] == 0);
ffffffffc0202e96:	00003697          	auipc	a3,0x3
ffffffffc0202e9a:	9a268693          	addi	a3,a3,-1630 # ffffffffc0205838 <commands+0x1390>
ffffffffc0202e9e:	00002617          	auipc	a2,0x2
ffffffffc0202ea2:	ffa60613          	addi	a2,a2,-6 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0202ea6:	0c700593          	li	a1,199
ffffffffc0202eaa:	00003517          	auipc	a0,0x3
ffffffffc0202eae:	a8650513          	addi	a0,a0,-1402 # ffffffffc0205930 <commands+0x1488>
ffffffffc0202eb2:	a52fd0ef          	jal	ra,ffffffffc0200104 <__panic>
     assert(vma != NULL);
ffffffffc0202eb6:	00003697          	auipc	a3,0x3
ffffffffc0202eba:	9fa68693          	addi	a3,a3,-1542 # ffffffffc02058b0 <commands+0x1408>
ffffffffc0202ebe:	00002617          	auipc	a2,0x2
ffffffffc0202ec2:	fda60613          	addi	a2,a2,-38 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0202ec6:	0ca00593          	li	a1,202
ffffffffc0202eca:	00003517          	auipc	a0,0x3
ffffffffc0202ece:	a6650513          	addi	a0,a0,-1434 # ffffffffc0205930 <commands+0x1488>
ffffffffc0202ed2:	a32fd0ef          	jal	ra,ffffffffc0200104 <__panic>
     assert(total == nr_free_pages());
ffffffffc0202ed6:	00003697          	auipc	a3,0x3
ffffffffc0202eda:	a9268693          	addi	a3,a3,-1390 # ffffffffc0205968 <commands+0x14c0>
ffffffffc0202ede:	00002617          	auipc	a2,0x2
ffffffffc0202ee2:	fba60613          	addi	a2,a2,-70 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0202ee6:	0ba00593          	li	a1,186
ffffffffc0202eea:	00003517          	auipc	a0,0x3
ffffffffc0202eee:	a4650513          	addi	a0,a0,-1466 # ffffffffc0205930 <commands+0x1488>
ffffffffc0202ef2:	a12fd0ef          	jal	ra,ffffffffc0200104 <__panic>

ffffffffc0202ef6 <swap_init_mm>:
     return sm->init_mm(mm);
ffffffffc0202ef6:	0000e797          	auipc	a5,0xe
ffffffffc0202efa:	57278793          	addi	a5,a5,1394 # ffffffffc0211468 <sm>
ffffffffc0202efe:	639c                	ld	a5,0(a5)
ffffffffc0202f00:	0107b303          	ld	t1,16(a5)
ffffffffc0202f04:	8302                	jr	t1

ffffffffc0202f06 <swap_map_swappable>:
     return sm->map_swappable(mm, addr, page, swap_in);
ffffffffc0202f06:	0000e797          	auipc	a5,0xe
ffffffffc0202f0a:	56278793          	addi	a5,a5,1378 # ffffffffc0211468 <sm>
ffffffffc0202f0e:	639c                	ld	a5,0(a5)
ffffffffc0202f10:	0207b303          	ld	t1,32(a5)
ffffffffc0202f14:	8302                	jr	t1

ffffffffc0202f16 <swap_out>:
{
ffffffffc0202f16:	711d                	addi	sp,sp,-96
ffffffffc0202f18:	ec86                	sd	ra,88(sp)
ffffffffc0202f1a:	e8a2                	sd	s0,80(sp)
ffffffffc0202f1c:	e4a6                	sd	s1,72(sp)
ffffffffc0202f1e:	e0ca                	sd	s2,64(sp)
ffffffffc0202f20:	fc4e                	sd	s3,56(sp)
ffffffffc0202f22:	f852                	sd	s4,48(sp)
ffffffffc0202f24:	f456                	sd	s5,40(sp)
ffffffffc0202f26:	f05a                	sd	s6,32(sp)
ffffffffc0202f28:	ec5e                	sd	s7,24(sp)
ffffffffc0202f2a:	e862                	sd	s8,16(sp)
     for (i = 0; i != n; ++i)
ffffffffc0202f2c:	cde9                	beqz	a1,ffffffffc0203006 <swap_out+0xf0>
ffffffffc0202f2e:	8ab2                	mv	s5,a2
ffffffffc0202f30:	892a                	mv	s2,a0
ffffffffc0202f32:	8a2e                	mv	s4,a1
ffffffffc0202f34:	4401                	li	s0,0
ffffffffc0202f36:	0000e997          	auipc	s3,0xe
ffffffffc0202f3a:	53298993          	addi	s3,s3,1330 # ffffffffc0211468 <sm>
               cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr / PGSIZE + 1);
ffffffffc0202f3e:	00003b17          	auipc	s6,0x3
ffffffffc0202f42:	cfab0b13          	addi	s6,s6,-774 # ffffffffc0205c38 <commands+0x1790>
               cprintf("SWAP: failed to save\n");
ffffffffc0202f46:	00003b97          	auipc	s7,0x3
ffffffffc0202f4a:	cdab8b93          	addi	s7,s7,-806 # ffffffffc0205c20 <commands+0x1778>
ffffffffc0202f4e:	a825                	j	ffffffffc0202f86 <swap_out+0x70>
               cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr / PGSIZE + 1);
ffffffffc0202f50:	67a2                	ld	a5,8(sp)
ffffffffc0202f52:	8626                	mv	a2,s1
ffffffffc0202f54:	85a2                	mv	a1,s0
ffffffffc0202f56:	63b4                	ld	a3,64(a5)
ffffffffc0202f58:	855a                	mv	a0,s6
     for (i = 0; i != n; ++i)
ffffffffc0202f5a:	2405                	addiw	s0,s0,1
               cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr / PGSIZE + 1);
ffffffffc0202f5c:	82b1                	srli	a3,a3,0xc
ffffffffc0202f5e:	0685                	addi	a3,a3,1
ffffffffc0202f60:	95efd0ef          	jal	ra,ffffffffc02000be <cprintf>
               *ptep = (page->pra_vaddr / PGSIZE + 1) << 8;
ffffffffc0202f64:	6522                	ld	a0,8(sp)
               free_page(page);
ffffffffc0202f66:	4585                	li	a1,1
               *ptep = (page->pra_vaddr / PGSIZE + 1) << 8;
ffffffffc0202f68:	613c                	ld	a5,64(a0)
ffffffffc0202f6a:	83b1                	srli	a5,a5,0xc
ffffffffc0202f6c:	0785                	addi	a5,a5,1
ffffffffc0202f6e:	07a2                	slli	a5,a5,0x8
ffffffffc0202f70:	00fc3023          	sd	a5,0(s8) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
               free_page(page);
ffffffffc0202f74:	be1fd0ef          	jal	ra,ffffffffc0200b54 <free_pages>
          tlb_invalidate(mm->pgdir, v);
ffffffffc0202f78:	01893503          	ld	a0,24(s2)
ffffffffc0202f7c:	85a6                	mv	a1,s1
ffffffffc0202f7e:	ad5fe0ef          	jal	ra,ffffffffc0201a52 <tlb_invalidate>
     for (i = 0; i != n; ++i)
ffffffffc0202f82:	048a0d63          	beq	s4,s0,ffffffffc0202fdc <swap_out+0xc6>
          int r = sm->swap_out_victim(mm, &page, in_tick);
ffffffffc0202f86:	0009b783          	ld	a5,0(s3)
ffffffffc0202f8a:	8656                	mv	a2,s5
ffffffffc0202f8c:	002c                	addi	a1,sp,8
ffffffffc0202f8e:	7b9c                	ld	a5,48(a5)
ffffffffc0202f90:	854a                	mv	a0,s2
ffffffffc0202f92:	9782                	jalr	a5
          if (r != 0)
ffffffffc0202f94:	e12d                	bnez	a0,ffffffffc0202ff6 <swap_out+0xe0>
          v = page->pra_vaddr;
ffffffffc0202f96:	67a2                	ld	a5,8(sp)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0202f98:	01893503          	ld	a0,24(s2)
ffffffffc0202f9c:	4601                	li	a2,0
          v = page->pra_vaddr;
ffffffffc0202f9e:	63a4                	ld	s1,64(a5)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0202fa0:	85a6                	mv	a1,s1
ffffffffc0202fa2:	c39fd0ef          	jal	ra,ffffffffc0200bda <get_pte>
          assert((*ptep & PTE_V) != 0);
ffffffffc0202fa6:	611c                	ld	a5,0(a0)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0202fa8:	8c2a                	mv	s8,a0
          assert((*ptep & PTE_V) != 0);
ffffffffc0202faa:	8b85                	andi	a5,a5,1
ffffffffc0202fac:	cfb9                	beqz	a5,ffffffffc020300a <swap_out+0xf4>
          if (swapfs_write((page->pra_vaddr / PGSIZE + 1) << 8, page) != 0)
ffffffffc0202fae:	65a2                	ld	a1,8(sp)
ffffffffc0202fb0:	61bc                	ld	a5,64(a1)
ffffffffc0202fb2:	83b1                	srli	a5,a5,0xc
ffffffffc0202fb4:	00178513          	addi	a0,a5,1
ffffffffc0202fb8:	0522                	slli	a0,a0,0x8
ffffffffc0202fba:	589000ef          	jal	ra,ffffffffc0203d42 <swapfs_write>
ffffffffc0202fbe:	d949                	beqz	a0,ffffffffc0202f50 <swap_out+0x3a>
               cprintf("SWAP: failed to save\n");
ffffffffc0202fc0:	855e                	mv	a0,s7
ffffffffc0202fc2:	8fcfd0ef          	jal	ra,ffffffffc02000be <cprintf>
               sm->map_swappable(mm, v, page, 0);
ffffffffc0202fc6:	0009b783          	ld	a5,0(s3)
ffffffffc0202fca:	6622                	ld	a2,8(sp)
ffffffffc0202fcc:	4681                	li	a3,0
ffffffffc0202fce:	739c                	ld	a5,32(a5)
ffffffffc0202fd0:	85a6                	mv	a1,s1
ffffffffc0202fd2:	854a                	mv	a0,s2
     for (i = 0; i != n; ++i)
ffffffffc0202fd4:	2405                	addiw	s0,s0,1
               sm->map_swappable(mm, v, page, 0);
ffffffffc0202fd6:	9782                	jalr	a5
     for (i = 0; i != n; ++i)
ffffffffc0202fd8:	fa8a17e3          	bne	s4,s0,ffffffffc0202f86 <swap_out+0x70>
}
ffffffffc0202fdc:	8522                	mv	a0,s0
ffffffffc0202fde:	60e6                	ld	ra,88(sp)
ffffffffc0202fe0:	6446                	ld	s0,80(sp)
ffffffffc0202fe2:	64a6                	ld	s1,72(sp)
ffffffffc0202fe4:	6906                	ld	s2,64(sp)
ffffffffc0202fe6:	79e2                	ld	s3,56(sp)
ffffffffc0202fe8:	7a42                	ld	s4,48(sp)
ffffffffc0202fea:	7aa2                	ld	s5,40(sp)
ffffffffc0202fec:	7b02                	ld	s6,32(sp)
ffffffffc0202fee:	6be2                	ld	s7,24(sp)
ffffffffc0202ff0:	6c42                	ld	s8,16(sp)
ffffffffc0202ff2:	6125                	addi	sp,sp,96
ffffffffc0202ff4:	8082                	ret
               cprintf("i %d, swap_out: call swap_out_victim failed\n", i);
ffffffffc0202ff6:	85a2                	mv	a1,s0
ffffffffc0202ff8:	00003517          	auipc	a0,0x3
ffffffffc0202ffc:	be050513          	addi	a0,a0,-1056 # ffffffffc0205bd8 <commands+0x1730>
ffffffffc0203000:	8befd0ef          	jal	ra,ffffffffc02000be <cprintf>
               break;
ffffffffc0203004:	bfe1                	j	ffffffffc0202fdc <swap_out+0xc6>
     for (i = 0; i != n; ++i)
ffffffffc0203006:	4401                	li	s0,0
ffffffffc0203008:	bfd1                	j	ffffffffc0202fdc <swap_out+0xc6>
          assert((*ptep & PTE_V) != 0);
ffffffffc020300a:	00003697          	auipc	a3,0x3
ffffffffc020300e:	bfe68693          	addi	a3,a3,-1026 # ffffffffc0205c08 <commands+0x1760>
ffffffffc0203012:	00002617          	auipc	a2,0x2
ffffffffc0203016:	e8660613          	addi	a2,a2,-378 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc020301a:	06300593          	li	a1,99
ffffffffc020301e:	00003517          	auipc	a0,0x3
ffffffffc0203022:	91250513          	addi	a0,a0,-1774 # ffffffffc0205930 <commands+0x1488>
ffffffffc0203026:	8defd0ef          	jal	ra,ffffffffc0200104 <__panic>

ffffffffc020302a <swap_in>:
{
ffffffffc020302a:	7179                	addi	sp,sp,-48
ffffffffc020302c:	e84a                	sd	s2,16(sp)
ffffffffc020302e:	892a                	mv	s2,a0
     struct Page *result = alloc_page();
ffffffffc0203030:	4505                	li	a0,1
{
ffffffffc0203032:	ec26                	sd	s1,24(sp)
ffffffffc0203034:	e44e                	sd	s3,8(sp)
ffffffffc0203036:	f406                	sd	ra,40(sp)
ffffffffc0203038:	f022                	sd	s0,32(sp)
ffffffffc020303a:	84ae                	mv	s1,a1
ffffffffc020303c:	89b2                	mv	s3,a2
     struct Page *result = alloc_page();
ffffffffc020303e:	a8ffd0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
     assert(result != NULL);
ffffffffc0203042:	c129                	beqz	a0,ffffffffc0203084 <swap_in+0x5a>
     pte_t *ptep = get_pte(mm->pgdir, addr, 0);
ffffffffc0203044:	842a                	mv	s0,a0
ffffffffc0203046:	01893503          	ld	a0,24(s2)
ffffffffc020304a:	4601                	li	a2,0
ffffffffc020304c:	85a6                	mv	a1,s1
ffffffffc020304e:	b8dfd0ef          	jal	ra,ffffffffc0200bda <get_pte>
ffffffffc0203052:	892a                	mv	s2,a0
     if ((r = swapfs_read((*ptep), result)) != 0)
ffffffffc0203054:	6108                	ld	a0,0(a0)
ffffffffc0203056:	85a2                	mv	a1,s0
ffffffffc0203058:	445000ef          	jal	ra,ffffffffc0203c9c <swapfs_read>
     cprintf("swap_in: load disk swap entry %d with swap_page in vadr 0x%x\n", (*ptep) >> 8, addr);
ffffffffc020305c:	00093583          	ld	a1,0(s2)
ffffffffc0203060:	8626                	mv	a2,s1
ffffffffc0203062:	00003517          	auipc	a0,0x3
ffffffffc0203066:	86e50513          	addi	a0,a0,-1938 # ffffffffc02058d0 <commands+0x1428>
ffffffffc020306a:	81a1                	srli	a1,a1,0x8
ffffffffc020306c:	852fd0ef          	jal	ra,ffffffffc02000be <cprintf>
}
ffffffffc0203070:	70a2                	ld	ra,40(sp)
     *ptr_result = result;
ffffffffc0203072:	0089b023          	sd	s0,0(s3)
}
ffffffffc0203076:	7402                	ld	s0,32(sp)
ffffffffc0203078:	64e2                	ld	s1,24(sp)
ffffffffc020307a:	6942                	ld	s2,16(sp)
ffffffffc020307c:	69a2                	ld	s3,8(sp)
ffffffffc020307e:	4501                	li	a0,0
ffffffffc0203080:	6145                	addi	sp,sp,48
ffffffffc0203082:	8082                	ret
     assert(result != NULL);
ffffffffc0203084:	00003697          	auipc	a3,0x3
ffffffffc0203088:	83c68693          	addi	a3,a3,-1988 # ffffffffc02058c0 <commands+0x1418>
ffffffffc020308c:	00002617          	auipc	a2,0x2
ffffffffc0203090:	e0c60613          	addi	a2,a2,-500 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0203094:	07a00593          	li	a1,122
ffffffffc0203098:	00003517          	auipc	a0,0x3
ffffffffc020309c:	89850513          	addi	a0,a0,-1896 # ffffffffc0205930 <commands+0x1488>
ffffffffc02030a0:	864fd0ef          	jal	ra,ffffffffc0200104 <__panic>

ffffffffc02030a4 <default_init>:
    elm->prev = elm->next = elm;
ffffffffc02030a4:	0000e797          	auipc	a5,0xe
ffffffffc02030a8:	4dc78793          	addi	a5,a5,1244 # ffffffffc0211580 <free_area>
ffffffffc02030ac:	e79c                	sd	a5,8(a5)
ffffffffc02030ae:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc02030b0:	0007a823          	sw	zero,16(a5)
}
ffffffffc02030b4:	8082                	ret

ffffffffc02030b6 <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc02030b6:	0000e517          	auipc	a0,0xe
ffffffffc02030ba:	4da56503          	lwu	a0,1242(a0) # ffffffffc0211590 <free_area+0x10>
ffffffffc02030be:	8082                	ret

ffffffffc02030c0 <default_check>:
// LAB2: below code is used to check the first fit allocation algorithm

// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc02030c0:	715d                	addi	sp,sp,-80
ffffffffc02030c2:	f84a                	sd	s2,48(sp)
    return listelm->next;
ffffffffc02030c4:	0000e917          	auipc	s2,0xe
ffffffffc02030c8:	4bc90913          	addi	s2,s2,1212 # ffffffffc0211580 <free_area>
ffffffffc02030cc:	00893783          	ld	a5,8(s2)
ffffffffc02030d0:	e486                	sd	ra,72(sp)
ffffffffc02030d2:	e0a2                	sd	s0,64(sp)
ffffffffc02030d4:	fc26                	sd	s1,56(sp)
ffffffffc02030d6:	f44e                	sd	s3,40(sp)
ffffffffc02030d8:	f052                	sd	s4,32(sp)
ffffffffc02030da:	ec56                	sd	s5,24(sp)
ffffffffc02030dc:	e85a                	sd	s6,16(sp)
ffffffffc02030de:	e45e                	sd	s7,8(sp)
ffffffffc02030e0:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc02030e2:	31278f63          	beq	a5,s2,ffffffffc0203400 <default_check+0x340>
ffffffffc02030e6:	fe87b703          	ld	a4,-24(a5)
ffffffffc02030ea:	8305                	srli	a4,a4,0x1
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc02030ec:	8b05                	andi	a4,a4,1
ffffffffc02030ee:	30070d63          	beqz	a4,ffffffffc0203408 <default_check+0x348>
    int count = 0, total = 0;
ffffffffc02030f2:	4401                	li	s0,0
ffffffffc02030f4:	4481                	li	s1,0
ffffffffc02030f6:	a031                	j	ffffffffc0203102 <default_check+0x42>
ffffffffc02030f8:	fe87b703          	ld	a4,-24(a5)
        assert(PageProperty(p));
ffffffffc02030fc:	8b09                	andi	a4,a4,2
ffffffffc02030fe:	30070563          	beqz	a4,ffffffffc0203408 <default_check+0x348>
        count++, total += p->property;
ffffffffc0203102:	ff87a703          	lw	a4,-8(a5)
ffffffffc0203106:	679c                	ld	a5,8(a5)
ffffffffc0203108:	2485                	addiw	s1,s1,1
ffffffffc020310a:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc020310c:	ff2796e3          	bne	a5,s2,ffffffffc02030f8 <default_check+0x38>
ffffffffc0203110:	89a2                	mv	s3,s0
    }
    assert(total == nr_free_pages());
ffffffffc0203112:	a89fd0ef          	jal	ra,ffffffffc0200b9a <nr_free_pages>
ffffffffc0203116:	75351963          	bne	a0,s3,ffffffffc0203868 <default_check+0x7a8>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020311a:	4505                	li	a0,1
ffffffffc020311c:	9b1fd0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc0203120:	8a2a                	mv	s4,a0
ffffffffc0203122:	48050363          	beqz	a0,ffffffffc02035a8 <default_check+0x4e8>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0203126:	4505                	li	a0,1
ffffffffc0203128:	9a5fd0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc020312c:	89aa                	mv	s3,a0
ffffffffc020312e:	74050d63          	beqz	a0,ffffffffc0203888 <default_check+0x7c8>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0203132:	4505                	li	a0,1
ffffffffc0203134:	999fd0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc0203138:	8aaa                	mv	s5,a0
ffffffffc020313a:	4e050763          	beqz	a0,ffffffffc0203628 <default_check+0x568>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020313e:	2f3a0563          	beq	s4,s3,ffffffffc0203428 <default_check+0x368>
ffffffffc0203142:	2eaa0363          	beq	s4,a0,ffffffffc0203428 <default_check+0x368>
ffffffffc0203146:	2ea98163          	beq	s3,a0,ffffffffc0203428 <default_check+0x368>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020314a:	000a2783          	lw	a5,0(s4)
ffffffffc020314e:	2e079d63          	bnez	a5,ffffffffc0203448 <default_check+0x388>
ffffffffc0203152:	0009a783          	lw	a5,0(s3)
ffffffffc0203156:	2e079963          	bnez	a5,ffffffffc0203448 <default_check+0x388>
ffffffffc020315a:	411c                	lw	a5,0(a0)
ffffffffc020315c:	2e079663          	bnez	a5,ffffffffc0203448 <default_check+0x388>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203160:	0000e797          	auipc	a5,0xe
ffffffffc0203164:	33878793          	addi	a5,a5,824 # ffffffffc0211498 <pages>
ffffffffc0203168:	639c                	ld	a5,0(a5)
ffffffffc020316a:	00002717          	auipc	a4,0x2
ffffffffc020316e:	b7670713          	addi	a4,a4,-1162 # ffffffffc0204ce0 <commands+0x838>
ffffffffc0203172:	630c                	ld	a1,0(a4)
ffffffffc0203174:	40fa0733          	sub	a4,s4,a5
ffffffffc0203178:	870d                	srai	a4,a4,0x3
ffffffffc020317a:	02b70733          	mul	a4,a4,a1
ffffffffc020317e:	00003697          	auipc	a3,0x3
ffffffffc0203182:	15a68693          	addi	a3,a3,346 # ffffffffc02062d8 <nbase>
ffffffffc0203186:	6290                	ld	a2,0(a3)
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0203188:	0000e697          	auipc	a3,0xe
ffffffffc020318c:	2d068693          	addi	a3,a3,720 # ffffffffc0211458 <npage>
ffffffffc0203190:	6294                	ld	a3,0(a3)
ffffffffc0203192:	06b2                	slli	a3,a3,0xc
ffffffffc0203194:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0203196:	0732                	slli	a4,a4,0xc
ffffffffc0203198:	2cd77863          	bgeu	a4,a3,ffffffffc0203468 <default_check+0x3a8>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020319c:	40f98733          	sub	a4,s3,a5
ffffffffc02031a0:	870d                	srai	a4,a4,0x3
ffffffffc02031a2:	02b70733          	mul	a4,a4,a1
ffffffffc02031a6:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02031a8:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02031aa:	4ed77f63          	bgeu	a4,a3,ffffffffc02036a8 <default_check+0x5e8>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02031ae:	40f507b3          	sub	a5,a0,a5
ffffffffc02031b2:	878d                	srai	a5,a5,0x3
ffffffffc02031b4:	02b787b3          	mul	a5,a5,a1
ffffffffc02031b8:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02031ba:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02031bc:	34d7f663          	bgeu	a5,a3,ffffffffc0203508 <default_check+0x448>
    assert(alloc_page() == NULL);
ffffffffc02031c0:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02031c2:	00093c03          	ld	s8,0(s2)
ffffffffc02031c6:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc02031ca:	01092b03          	lw	s6,16(s2)
    elm->prev = elm->next = elm;
ffffffffc02031ce:	0000e797          	auipc	a5,0xe
ffffffffc02031d2:	3b27bd23          	sd	s2,954(a5) # ffffffffc0211588 <free_area+0x8>
ffffffffc02031d6:	0000e797          	auipc	a5,0xe
ffffffffc02031da:	3b27b523          	sd	s2,938(a5) # ffffffffc0211580 <free_area>
    nr_free = 0;
ffffffffc02031de:	0000e797          	auipc	a5,0xe
ffffffffc02031e2:	3a07a923          	sw	zero,946(a5) # ffffffffc0211590 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc02031e6:	8e7fd0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc02031ea:	2e051f63          	bnez	a0,ffffffffc02034e8 <default_check+0x428>
    free_page(p0);
ffffffffc02031ee:	4585                	li	a1,1
ffffffffc02031f0:	8552                	mv	a0,s4
ffffffffc02031f2:	963fd0ef          	jal	ra,ffffffffc0200b54 <free_pages>
    free_page(p1);
ffffffffc02031f6:	4585                	li	a1,1
ffffffffc02031f8:	854e                	mv	a0,s3
ffffffffc02031fa:	95bfd0ef          	jal	ra,ffffffffc0200b54 <free_pages>
    free_page(p2);
ffffffffc02031fe:	4585                	li	a1,1
ffffffffc0203200:	8556                	mv	a0,s5
ffffffffc0203202:	953fd0ef          	jal	ra,ffffffffc0200b54 <free_pages>
    assert(nr_free == 3);
ffffffffc0203206:	01092703          	lw	a4,16(s2)
ffffffffc020320a:	478d                	li	a5,3
ffffffffc020320c:	2af71e63          	bne	a4,a5,ffffffffc02034c8 <default_check+0x408>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0203210:	4505                	li	a0,1
ffffffffc0203212:	8bbfd0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc0203216:	89aa                	mv	s3,a0
ffffffffc0203218:	28050863          	beqz	a0,ffffffffc02034a8 <default_check+0x3e8>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020321c:	4505                	li	a0,1
ffffffffc020321e:	8affd0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc0203222:	8aaa                	mv	s5,a0
ffffffffc0203224:	3e050263          	beqz	a0,ffffffffc0203608 <default_check+0x548>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0203228:	4505                	li	a0,1
ffffffffc020322a:	8a3fd0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc020322e:	8a2a                	mv	s4,a0
ffffffffc0203230:	3a050c63          	beqz	a0,ffffffffc02035e8 <default_check+0x528>
    assert(alloc_page() == NULL);
ffffffffc0203234:	4505                	li	a0,1
ffffffffc0203236:	897fd0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc020323a:	38051763          	bnez	a0,ffffffffc02035c8 <default_check+0x508>
    free_page(p0);
ffffffffc020323e:	4585                	li	a1,1
ffffffffc0203240:	854e                	mv	a0,s3
ffffffffc0203242:	913fd0ef          	jal	ra,ffffffffc0200b54 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0203246:	00893783          	ld	a5,8(s2)
ffffffffc020324a:	23278f63          	beq	a5,s2,ffffffffc0203488 <default_check+0x3c8>
    assert((p = alloc_page()) == p0);
ffffffffc020324e:	4505                	li	a0,1
ffffffffc0203250:	87dfd0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc0203254:	32a99a63          	bne	s3,a0,ffffffffc0203588 <default_check+0x4c8>
    assert(alloc_page() == NULL);
ffffffffc0203258:	4505                	li	a0,1
ffffffffc020325a:	873fd0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc020325e:	30051563          	bnez	a0,ffffffffc0203568 <default_check+0x4a8>
    assert(nr_free == 0);
ffffffffc0203262:	01092783          	lw	a5,16(s2)
ffffffffc0203266:	2e079163          	bnez	a5,ffffffffc0203548 <default_check+0x488>
    free_page(p);
ffffffffc020326a:	854e                	mv	a0,s3
ffffffffc020326c:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc020326e:	0000e797          	auipc	a5,0xe
ffffffffc0203272:	3187b923          	sd	s8,786(a5) # ffffffffc0211580 <free_area>
ffffffffc0203276:	0000e797          	auipc	a5,0xe
ffffffffc020327a:	3177b923          	sd	s7,786(a5) # ffffffffc0211588 <free_area+0x8>
    nr_free = nr_free_store;
ffffffffc020327e:	0000e797          	auipc	a5,0xe
ffffffffc0203282:	3167a923          	sw	s6,786(a5) # ffffffffc0211590 <free_area+0x10>
    free_page(p);
ffffffffc0203286:	8cffd0ef          	jal	ra,ffffffffc0200b54 <free_pages>
    free_page(p1);
ffffffffc020328a:	4585                	li	a1,1
ffffffffc020328c:	8556                	mv	a0,s5
ffffffffc020328e:	8c7fd0ef          	jal	ra,ffffffffc0200b54 <free_pages>
    free_page(p2);
ffffffffc0203292:	4585                	li	a1,1
ffffffffc0203294:	8552                	mv	a0,s4
ffffffffc0203296:	8bffd0ef          	jal	ra,ffffffffc0200b54 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc020329a:	4515                	li	a0,5
ffffffffc020329c:	831fd0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc02032a0:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc02032a2:	28050363          	beqz	a0,ffffffffc0203528 <default_check+0x468>
ffffffffc02032a6:	651c                	ld	a5,8(a0)
ffffffffc02032a8:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc02032aa:	8b85                	andi	a5,a5,1
ffffffffc02032ac:	54079e63          	bnez	a5,ffffffffc0203808 <default_check+0x748>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc02032b0:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02032b2:	00093b03          	ld	s6,0(s2)
ffffffffc02032b6:	00893a83          	ld	s5,8(s2)
ffffffffc02032ba:	0000e797          	auipc	a5,0xe
ffffffffc02032be:	2d27b323          	sd	s2,710(a5) # ffffffffc0211580 <free_area>
ffffffffc02032c2:	0000e797          	auipc	a5,0xe
ffffffffc02032c6:	2d27b323          	sd	s2,710(a5) # ffffffffc0211588 <free_area+0x8>
    assert(alloc_page() == NULL);
ffffffffc02032ca:	803fd0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc02032ce:	50051d63          	bnez	a0,ffffffffc02037e8 <default_check+0x728>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc02032d2:	09098a13          	addi	s4,s3,144
ffffffffc02032d6:	8552                	mv	a0,s4
ffffffffc02032d8:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc02032da:	01092b83          	lw	s7,16(s2)
    nr_free = 0;
ffffffffc02032de:	0000e797          	auipc	a5,0xe
ffffffffc02032e2:	2a07a923          	sw	zero,690(a5) # ffffffffc0211590 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc02032e6:	86ffd0ef          	jal	ra,ffffffffc0200b54 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc02032ea:	4511                	li	a0,4
ffffffffc02032ec:	fe0fd0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc02032f0:	4c051c63          	bnez	a0,ffffffffc02037c8 <default_check+0x708>
ffffffffc02032f4:	0989b783          	ld	a5,152(s3)
ffffffffc02032f8:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02032fa:	8b85                	andi	a5,a5,1
ffffffffc02032fc:	4a078663          	beqz	a5,ffffffffc02037a8 <default_check+0x6e8>
ffffffffc0203300:	0a89a703          	lw	a4,168(s3)
ffffffffc0203304:	478d                	li	a5,3
ffffffffc0203306:	4af71163          	bne	a4,a5,ffffffffc02037a8 <default_check+0x6e8>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc020330a:	450d                	li	a0,3
ffffffffc020330c:	fc0fd0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc0203310:	8c2a                	mv	s8,a0
ffffffffc0203312:	46050b63          	beqz	a0,ffffffffc0203788 <default_check+0x6c8>
    assert(alloc_page() == NULL);
ffffffffc0203316:	4505                	li	a0,1
ffffffffc0203318:	fb4fd0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc020331c:	44051663          	bnez	a0,ffffffffc0203768 <default_check+0x6a8>
    assert(p0 + 2 == p1);
ffffffffc0203320:	438a1463          	bne	s4,s8,ffffffffc0203748 <default_check+0x688>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0203324:	4585                	li	a1,1
ffffffffc0203326:	854e                	mv	a0,s3
ffffffffc0203328:	82dfd0ef          	jal	ra,ffffffffc0200b54 <free_pages>
    free_pages(p1, 3);
ffffffffc020332c:	458d                	li	a1,3
ffffffffc020332e:	8552                	mv	a0,s4
ffffffffc0203330:	825fd0ef          	jal	ra,ffffffffc0200b54 <free_pages>
ffffffffc0203334:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0203338:	04898c13          	addi	s8,s3,72
ffffffffc020333c:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc020333e:	8b85                	andi	a5,a5,1
ffffffffc0203340:	3e078463          	beqz	a5,ffffffffc0203728 <default_check+0x668>
ffffffffc0203344:	0189a703          	lw	a4,24(s3)
ffffffffc0203348:	4785                	li	a5,1
ffffffffc020334a:	3cf71f63          	bne	a4,a5,ffffffffc0203728 <default_check+0x668>
ffffffffc020334e:	008a3783          	ld	a5,8(s4)
ffffffffc0203352:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0203354:	8b85                	andi	a5,a5,1
ffffffffc0203356:	3a078963          	beqz	a5,ffffffffc0203708 <default_check+0x648>
ffffffffc020335a:	018a2703          	lw	a4,24(s4)
ffffffffc020335e:	478d                	li	a5,3
ffffffffc0203360:	3af71463          	bne	a4,a5,ffffffffc0203708 <default_check+0x648>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0203364:	4505                	li	a0,1
ffffffffc0203366:	f66fd0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc020336a:	36a99f63          	bne	s3,a0,ffffffffc02036e8 <default_check+0x628>
    free_page(p0);
ffffffffc020336e:	4585                	li	a1,1
ffffffffc0203370:	fe4fd0ef          	jal	ra,ffffffffc0200b54 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0203374:	4509                	li	a0,2
ffffffffc0203376:	f56fd0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc020337a:	34aa1763          	bne	s4,a0,ffffffffc02036c8 <default_check+0x608>

    free_pages(p0, 2);
ffffffffc020337e:	4589                	li	a1,2
ffffffffc0203380:	fd4fd0ef          	jal	ra,ffffffffc0200b54 <free_pages>
    free_page(p2);
ffffffffc0203384:	4585                	li	a1,1
ffffffffc0203386:	8562                	mv	a0,s8
ffffffffc0203388:	fccfd0ef          	jal	ra,ffffffffc0200b54 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020338c:	4515                	li	a0,5
ffffffffc020338e:	f3efd0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc0203392:	89aa                	mv	s3,a0
ffffffffc0203394:	48050a63          	beqz	a0,ffffffffc0203828 <default_check+0x768>
    assert(alloc_page() == NULL);
ffffffffc0203398:	4505                	li	a0,1
ffffffffc020339a:	f32fd0ef          	jal	ra,ffffffffc0200acc <alloc_pages>
ffffffffc020339e:	2e051563          	bnez	a0,ffffffffc0203688 <default_check+0x5c8>

    assert(nr_free == 0);
ffffffffc02033a2:	01092783          	lw	a5,16(s2)
ffffffffc02033a6:	2c079163          	bnez	a5,ffffffffc0203668 <default_check+0x5a8>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc02033aa:	4595                	li	a1,5
ffffffffc02033ac:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc02033ae:	0000e797          	auipc	a5,0xe
ffffffffc02033b2:	1f77a123          	sw	s7,482(a5) # ffffffffc0211590 <free_area+0x10>
    free_list = free_list_store;
ffffffffc02033b6:	0000e797          	auipc	a5,0xe
ffffffffc02033ba:	1d67b523          	sd	s6,458(a5) # ffffffffc0211580 <free_area>
ffffffffc02033be:	0000e797          	auipc	a5,0xe
ffffffffc02033c2:	1d57b523          	sd	s5,458(a5) # ffffffffc0211588 <free_area+0x8>
    free_pages(p0, 5);
ffffffffc02033c6:	f8efd0ef          	jal	ra,ffffffffc0200b54 <free_pages>
    return listelm->next;
ffffffffc02033ca:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc02033ce:	01278963          	beq	a5,s2,ffffffffc02033e0 <default_check+0x320>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc02033d2:	ff87a703          	lw	a4,-8(a5)
ffffffffc02033d6:	679c                	ld	a5,8(a5)
ffffffffc02033d8:	34fd                	addiw	s1,s1,-1
ffffffffc02033da:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc02033dc:	ff279be3          	bne	a5,s2,ffffffffc02033d2 <default_check+0x312>
    }
    assert(count == 0);
ffffffffc02033e0:	26049463          	bnez	s1,ffffffffc0203648 <default_check+0x588>
    assert(total == 0);
ffffffffc02033e4:	46041263          	bnez	s0,ffffffffc0203848 <default_check+0x788>
}
ffffffffc02033e8:	60a6                	ld	ra,72(sp)
ffffffffc02033ea:	6406                	ld	s0,64(sp)
ffffffffc02033ec:	74e2                	ld	s1,56(sp)
ffffffffc02033ee:	7942                	ld	s2,48(sp)
ffffffffc02033f0:	79a2                	ld	s3,40(sp)
ffffffffc02033f2:	7a02                	ld	s4,32(sp)
ffffffffc02033f4:	6ae2                	ld	s5,24(sp)
ffffffffc02033f6:	6b42                	ld	s6,16(sp)
ffffffffc02033f8:	6ba2                	ld	s7,8(sp)
ffffffffc02033fa:	6c02                	ld	s8,0(sp)
ffffffffc02033fc:	6161                	addi	sp,sp,80
ffffffffc02033fe:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc0203400:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0203402:	4401                	li	s0,0
ffffffffc0203404:	4481                	li	s1,0
ffffffffc0203406:	b331                	j	ffffffffc0203112 <default_check+0x52>
        assert(PageProperty(p));
ffffffffc0203408:	00002697          	auipc	a3,0x2
ffffffffc020340c:	55068693          	addi	a3,a3,1360 # ffffffffc0205958 <commands+0x14b0>
ffffffffc0203410:	00002617          	auipc	a2,0x2
ffffffffc0203414:	a8860613          	addi	a2,a2,-1400 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0203418:	12800593          	li	a1,296
ffffffffc020341c:	00003517          	auipc	a0,0x3
ffffffffc0203420:	85c50513          	addi	a0,a0,-1956 # ffffffffc0205c78 <commands+0x17d0>
ffffffffc0203424:	ce1fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0203428:	00003697          	auipc	a3,0x3
ffffffffc020342c:	8c868693          	addi	a3,a3,-1848 # ffffffffc0205cf0 <commands+0x1848>
ffffffffc0203430:	00002617          	auipc	a2,0x2
ffffffffc0203434:	a6860613          	addi	a2,a2,-1432 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0203438:	0f200593          	li	a1,242
ffffffffc020343c:	00003517          	auipc	a0,0x3
ffffffffc0203440:	83c50513          	addi	a0,a0,-1988 # ffffffffc0205c78 <commands+0x17d0>
ffffffffc0203444:	cc1fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0203448:	00003697          	auipc	a3,0x3
ffffffffc020344c:	8d068693          	addi	a3,a3,-1840 # ffffffffc0205d18 <commands+0x1870>
ffffffffc0203450:	00002617          	auipc	a2,0x2
ffffffffc0203454:	a4860613          	addi	a2,a2,-1464 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0203458:	0f300593          	li	a1,243
ffffffffc020345c:	00003517          	auipc	a0,0x3
ffffffffc0203460:	81c50513          	addi	a0,a0,-2020 # ffffffffc0205c78 <commands+0x17d0>
ffffffffc0203464:	ca1fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0203468:	00003697          	auipc	a3,0x3
ffffffffc020346c:	8f068693          	addi	a3,a3,-1808 # ffffffffc0205d58 <commands+0x18b0>
ffffffffc0203470:	00002617          	auipc	a2,0x2
ffffffffc0203474:	a2860613          	addi	a2,a2,-1496 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0203478:	0f500593          	li	a1,245
ffffffffc020347c:	00002517          	auipc	a0,0x2
ffffffffc0203480:	7fc50513          	addi	a0,a0,2044 # ffffffffc0205c78 <commands+0x17d0>
ffffffffc0203484:	c81fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0203488:	00003697          	auipc	a3,0x3
ffffffffc020348c:	95868693          	addi	a3,a3,-1704 # ffffffffc0205de0 <commands+0x1938>
ffffffffc0203490:	00002617          	auipc	a2,0x2
ffffffffc0203494:	a0860613          	addi	a2,a2,-1528 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0203498:	10e00593          	li	a1,270
ffffffffc020349c:	00002517          	auipc	a0,0x2
ffffffffc02034a0:	7dc50513          	addi	a0,a0,2012 # ffffffffc0205c78 <commands+0x17d0>
ffffffffc02034a4:	c61fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02034a8:	00002697          	auipc	a3,0x2
ffffffffc02034ac:	7e868693          	addi	a3,a3,2024 # ffffffffc0205c90 <commands+0x17e8>
ffffffffc02034b0:	00002617          	auipc	a2,0x2
ffffffffc02034b4:	9e860613          	addi	a2,a2,-1560 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc02034b8:	10700593          	li	a1,263
ffffffffc02034bc:	00002517          	auipc	a0,0x2
ffffffffc02034c0:	7bc50513          	addi	a0,a0,1980 # ffffffffc0205c78 <commands+0x17d0>
ffffffffc02034c4:	c41fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(nr_free == 3);
ffffffffc02034c8:	00003697          	auipc	a3,0x3
ffffffffc02034cc:	90868693          	addi	a3,a3,-1784 # ffffffffc0205dd0 <commands+0x1928>
ffffffffc02034d0:	00002617          	auipc	a2,0x2
ffffffffc02034d4:	9c860613          	addi	a2,a2,-1592 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc02034d8:	10500593          	li	a1,261
ffffffffc02034dc:	00002517          	auipc	a0,0x2
ffffffffc02034e0:	79c50513          	addi	a0,a0,1948 # ffffffffc0205c78 <commands+0x17d0>
ffffffffc02034e4:	c21fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02034e8:	00003697          	auipc	a3,0x3
ffffffffc02034ec:	8d068693          	addi	a3,a3,-1840 # ffffffffc0205db8 <commands+0x1910>
ffffffffc02034f0:	00002617          	auipc	a2,0x2
ffffffffc02034f4:	9a860613          	addi	a2,a2,-1624 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc02034f8:	10000593          	li	a1,256
ffffffffc02034fc:	00002517          	auipc	a0,0x2
ffffffffc0203500:	77c50513          	addi	a0,a0,1916 # ffffffffc0205c78 <commands+0x17d0>
ffffffffc0203504:	c01fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0203508:	00003697          	auipc	a3,0x3
ffffffffc020350c:	89068693          	addi	a3,a3,-1904 # ffffffffc0205d98 <commands+0x18f0>
ffffffffc0203510:	00002617          	auipc	a2,0x2
ffffffffc0203514:	98860613          	addi	a2,a2,-1656 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0203518:	0f700593          	li	a1,247
ffffffffc020351c:	00002517          	auipc	a0,0x2
ffffffffc0203520:	75c50513          	addi	a0,a0,1884 # ffffffffc0205c78 <commands+0x17d0>
ffffffffc0203524:	be1fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(p0 != NULL);
ffffffffc0203528:	00003697          	auipc	a3,0x3
ffffffffc020352c:	8f068693          	addi	a3,a3,-1808 # ffffffffc0205e18 <commands+0x1970>
ffffffffc0203530:	00002617          	auipc	a2,0x2
ffffffffc0203534:	96860613          	addi	a2,a2,-1688 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0203538:	13000593          	li	a1,304
ffffffffc020353c:	00002517          	auipc	a0,0x2
ffffffffc0203540:	73c50513          	addi	a0,a0,1852 # ffffffffc0205c78 <commands+0x17d0>
ffffffffc0203544:	bc1fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(nr_free == 0);
ffffffffc0203548:	00002697          	auipc	a3,0x2
ffffffffc020354c:	5c868693          	addi	a3,a3,1480 # ffffffffc0205b10 <commands+0x1668>
ffffffffc0203550:	00002617          	auipc	a2,0x2
ffffffffc0203554:	94860613          	addi	a2,a2,-1720 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0203558:	11400593          	li	a1,276
ffffffffc020355c:	00002517          	auipc	a0,0x2
ffffffffc0203560:	71c50513          	addi	a0,a0,1820 # ffffffffc0205c78 <commands+0x17d0>
ffffffffc0203564:	ba1fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0203568:	00003697          	auipc	a3,0x3
ffffffffc020356c:	85068693          	addi	a3,a3,-1968 # ffffffffc0205db8 <commands+0x1910>
ffffffffc0203570:	00002617          	auipc	a2,0x2
ffffffffc0203574:	92860613          	addi	a2,a2,-1752 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0203578:	11200593          	li	a1,274
ffffffffc020357c:	00002517          	auipc	a0,0x2
ffffffffc0203580:	6fc50513          	addi	a0,a0,1788 # ffffffffc0205c78 <commands+0x17d0>
ffffffffc0203584:	b81fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0203588:	00003697          	auipc	a3,0x3
ffffffffc020358c:	87068693          	addi	a3,a3,-1936 # ffffffffc0205df8 <commands+0x1950>
ffffffffc0203590:	00002617          	auipc	a2,0x2
ffffffffc0203594:	90860613          	addi	a2,a2,-1784 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0203598:	11100593          	li	a1,273
ffffffffc020359c:	00002517          	auipc	a0,0x2
ffffffffc02035a0:	6dc50513          	addi	a0,a0,1756 # ffffffffc0205c78 <commands+0x17d0>
ffffffffc02035a4:	b61fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02035a8:	00002697          	auipc	a3,0x2
ffffffffc02035ac:	6e868693          	addi	a3,a3,1768 # ffffffffc0205c90 <commands+0x17e8>
ffffffffc02035b0:	00002617          	auipc	a2,0x2
ffffffffc02035b4:	8e860613          	addi	a2,a2,-1816 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc02035b8:	0ee00593          	li	a1,238
ffffffffc02035bc:	00002517          	auipc	a0,0x2
ffffffffc02035c0:	6bc50513          	addi	a0,a0,1724 # ffffffffc0205c78 <commands+0x17d0>
ffffffffc02035c4:	b41fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02035c8:	00002697          	auipc	a3,0x2
ffffffffc02035cc:	7f068693          	addi	a3,a3,2032 # ffffffffc0205db8 <commands+0x1910>
ffffffffc02035d0:	00002617          	auipc	a2,0x2
ffffffffc02035d4:	8c860613          	addi	a2,a2,-1848 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc02035d8:	10b00593          	li	a1,267
ffffffffc02035dc:	00002517          	auipc	a0,0x2
ffffffffc02035e0:	69c50513          	addi	a0,a0,1692 # ffffffffc0205c78 <commands+0x17d0>
ffffffffc02035e4:	b21fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02035e8:	00002697          	auipc	a3,0x2
ffffffffc02035ec:	6e868693          	addi	a3,a3,1768 # ffffffffc0205cd0 <commands+0x1828>
ffffffffc02035f0:	00002617          	auipc	a2,0x2
ffffffffc02035f4:	8a860613          	addi	a2,a2,-1880 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc02035f8:	10900593          	li	a1,265
ffffffffc02035fc:	00002517          	auipc	a0,0x2
ffffffffc0203600:	67c50513          	addi	a0,a0,1660 # ffffffffc0205c78 <commands+0x17d0>
ffffffffc0203604:	b01fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0203608:	00002697          	auipc	a3,0x2
ffffffffc020360c:	6a868693          	addi	a3,a3,1704 # ffffffffc0205cb0 <commands+0x1808>
ffffffffc0203610:	00002617          	auipc	a2,0x2
ffffffffc0203614:	88860613          	addi	a2,a2,-1912 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0203618:	10800593          	li	a1,264
ffffffffc020361c:	00002517          	auipc	a0,0x2
ffffffffc0203620:	65c50513          	addi	a0,a0,1628 # ffffffffc0205c78 <commands+0x17d0>
ffffffffc0203624:	ae1fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0203628:	00002697          	auipc	a3,0x2
ffffffffc020362c:	6a868693          	addi	a3,a3,1704 # ffffffffc0205cd0 <commands+0x1828>
ffffffffc0203630:	00002617          	auipc	a2,0x2
ffffffffc0203634:	86860613          	addi	a2,a2,-1944 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0203638:	0f000593          	li	a1,240
ffffffffc020363c:	00002517          	auipc	a0,0x2
ffffffffc0203640:	63c50513          	addi	a0,a0,1596 # ffffffffc0205c78 <commands+0x17d0>
ffffffffc0203644:	ac1fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(count == 0);
ffffffffc0203648:	00003697          	auipc	a3,0x3
ffffffffc020364c:	92068693          	addi	a3,a3,-1760 # ffffffffc0205f68 <commands+0x1ac0>
ffffffffc0203650:	00002617          	auipc	a2,0x2
ffffffffc0203654:	84860613          	addi	a2,a2,-1976 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0203658:	15e00593          	li	a1,350
ffffffffc020365c:	00002517          	auipc	a0,0x2
ffffffffc0203660:	61c50513          	addi	a0,a0,1564 # ffffffffc0205c78 <commands+0x17d0>
ffffffffc0203664:	aa1fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(nr_free == 0);
ffffffffc0203668:	00002697          	auipc	a3,0x2
ffffffffc020366c:	4a868693          	addi	a3,a3,1192 # ffffffffc0205b10 <commands+0x1668>
ffffffffc0203670:	00002617          	auipc	a2,0x2
ffffffffc0203674:	82860613          	addi	a2,a2,-2008 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0203678:	15200593          	li	a1,338
ffffffffc020367c:	00002517          	auipc	a0,0x2
ffffffffc0203680:	5fc50513          	addi	a0,a0,1532 # ffffffffc0205c78 <commands+0x17d0>
ffffffffc0203684:	a81fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0203688:	00002697          	auipc	a3,0x2
ffffffffc020368c:	73068693          	addi	a3,a3,1840 # ffffffffc0205db8 <commands+0x1910>
ffffffffc0203690:	00002617          	auipc	a2,0x2
ffffffffc0203694:	80860613          	addi	a2,a2,-2040 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0203698:	15000593          	li	a1,336
ffffffffc020369c:	00002517          	auipc	a0,0x2
ffffffffc02036a0:	5dc50513          	addi	a0,a0,1500 # ffffffffc0205c78 <commands+0x17d0>
ffffffffc02036a4:	a61fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02036a8:	00002697          	auipc	a3,0x2
ffffffffc02036ac:	6d068693          	addi	a3,a3,1744 # ffffffffc0205d78 <commands+0x18d0>
ffffffffc02036b0:	00001617          	auipc	a2,0x1
ffffffffc02036b4:	7e860613          	addi	a2,a2,2024 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc02036b8:	0f600593          	li	a1,246
ffffffffc02036bc:	00002517          	auipc	a0,0x2
ffffffffc02036c0:	5bc50513          	addi	a0,a0,1468 # ffffffffc0205c78 <commands+0x17d0>
ffffffffc02036c4:	a41fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02036c8:	00003697          	auipc	a3,0x3
ffffffffc02036cc:	86068693          	addi	a3,a3,-1952 # ffffffffc0205f28 <commands+0x1a80>
ffffffffc02036d0:	00001617          	auipc	a2,0x1
ffffffffc02036d4:	7c860613          	addi	a2,a2,1992 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc02036d8:	14a00593          	li	a1,330
ffffffffc02036dc:	00002517          	auipc	a0,0x2
ffffffffc02036e0:	59c50513          	addi	a0,a0,1436 # ffffffffc0205c78 <commands+0x17d0>
ffffffffc02036e4:	a21fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02036e8:	00003697          	auipc	a3,0x3
ffffffffc02036ec:	82068693          	addi	a3,a3,-2016 # ffffffffc0205f08 <commands+0x1a60>
ffffffffc02036f0:	00001617          	auipc	a2,0x1
ffffffffc02036f4:	7a860613          	addi	a2,a2,1960 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc02036f8:	14800593          	li	a1,328
ffffffffc02036fc:	00002517          	auipc	a0,0x2
ffffffffc0203700:	57c50513          	addi	a0,a0,1404 # ffffffffc0205c78 <commands+0x17d0>
ffffffffc0203704:	a01fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0203708:	00002697          	auipc	a3,0x2
ffffffffc020370c:	7d868693          	addi	a3,a3,2008 # ffffffffc0205ee0 <commands+0x1a38>
ffffffffc0203710:	00001617          	auipc	a2,0x1
ffffffffc0203714:	78860613          	addi	a2,a2,1928 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0203718:	14600593          	li	a1,326
ffffffffc020371c:	00002517          	auipc	a0,0x2
ffffffffc0203720:	55c50513          	addi	a0,a0,1372 # ffffffffc0205c78 <commands+0x17d0>
ffffffffc0203724:	9e1fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0203728:	00002697          	auipc	a3,0x2
ffffffffc020372c:	79068693          	addi	a3,a3,1936 # ffffffffc0205eb8 <commands+0x1a10>
ffffffffc0203730:	00001617          	auipc	a2,0x1
ffffffffc0203734:	76860613          	addi	a2,a2,1896 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0203738:	14500593          	li	a1,325
ffffffffc020373c:	00002517          	auipc	a0,0x2
ffffffffc0203740:	53c50513          	addi	a0,a0,1340 # ffffffffc0205c78 <commands+0x17d0>
ffffffffc0203744:	9c1fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(p0 + 2 == p1);
ffffffffc0203748:	00002697          	auipc	a3,0x2
ffffffffc020374c:	76068693          	addi	a3,a3,1888 # ffffffffc0205ea8 <commands+0x1a00>
ffffffffc0203750:	00001617          	auipc	a2,0x1
ffffffffc0203754:	74860613          	addi	a2,a2,1864 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0203758:	14000593          	li	a1,320
ffffffffc020375c:	00002517          	auipc	a0,0x2
ffffffffc0203760:	51c50513          	addi	a0,a0,1308 # ffffffffc0205c78 <commands+0x17d0>
ffffffffc0203764:	9a1fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0203768:	00002697          	auipc	a3,0x2
ffffffffc020376c:	65068693          	addi	a3,a3,1616 # ffffffffc0205db8 <commands+0x1910>
ffffffffc0203770:	00001617          	auipc	a2,0x1
ffffffffc0203774:	72860613          	addi	a2,a2,1832 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0203778:	13f00593          	li	a1,319
ffffffffc020377c:	00002517          	auipc	a0,0x2
ffffffffc0203780:	4fc50513          	addi	a0,a0,1276 # ffffffffc0205c78 <commands+0x17d0>
ffffffffc0203784:	981fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0203788:	00002697          	auipc	a3,0x2
ffffffffc020378c:	70068693          	addi	a3,a3,1792 # ffffffffc0205e88 <commands+0x19e0>
ffffffffc0203790:	00001617          	auipc	a2,0x1
ffffffffc0203794:	70860613          	addi	a2,a2,1800 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0203798:	13e00593          	li	a1,318
ffffffffc020379c:	00002517          	auipc	a0,0x2
ffffffffc02037a0:	4dc50513          	addi	a0,a0,1244 # ffffffffc0205c78 <commands+0x17d0>
ffffffffc02037a4:	961fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02037a8:	00002697          	auipc	a3,0x2
ffffffffc02037ac:	6b068693          	addi	a3,a3,1712 # ffffffffc0205e58 <commands+0x19b0>
ffffffffc02037b0:	00001617          	auipc	a2,0x1
ffffffffc02037b4:	6e860613          	addi	a2,a2,1768 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc02037b8:	13d00593          	li	a1,317
ffffffffc02037bc:	00002517          	auipc	a0,0x2
ffffffffc02037c0:	4bc50513          	addi	a0,a0,1212 # ffffffffc0205c78 <commands+0x17d0>
ffffffffc02037c4:	941fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02037c8:	00002697          	auipc	a3,0x2
ffffffffc02037cc:	67868693          	addi	a3,a3,1656 # ffffffffc0205e40 <commands+0x1998>
ffffffffc02037d0:	00001617          	auipc	a2,0x1
ffffffffc02037d4:	6c860613          	addi	a2,a2,1736 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc02037d8:	13c00593          	li	a1,316
ffffffffc02037dc:	00002517          	auipc	a0,0x2
ffffffffc02037e0:	49c50513          	addi	a0,a0,1180 # ffffffffc0205c78 <commands+0x17d0>
ffffffffc02037e4:	921fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02037e8:	00002697          	auipc	a3,0x2
ffffffffc02037ec:	5d068693          	addi	a3,a3,1488 # ffffffffc0205db8 <commands+0x1910>
ffffffffc02037f0:	00001617          	auipc	a2,0x1
ffffffffc02037f4:	6a860613          	addi	a2,a2,1704 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc02037f8:	13600593          	li	a1,310
ffffffffc02037fc:	00002517          	auipc	a0,0x2
ffffffffc0203800:	47c50513          	addi	a0,a0,1148 # ffffffffc0205c78 <commands+0x17d0>
ffffffffc0203804:	901fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(!PageProperty(p0));
ffffffffc0203808:	00002697          	auipc	a3,0x2
ffffffffc020380c:	62068693          	addi	a3,a3,1568 # ffffffffc0205e28 <commands+0x1980>
ffffffffc0203810:	00001617          	auipc	a2,0x1
ffffffffc0203814:	68860613          	addi	a2,a2,1672 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0203818:	13100593          	li	a1,305
ffffffffc020381c:	00002517          	auipc	a0,0x2
ffffffffc0203820:	45c50513          	addi	a0,a0,1116 # ffffffffc0205c78 <commands+0x17d0>
ffffffffc0203824:	8e1fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0203828:	00002697          	auipc	a3,0x2
ffffffffc020382c:	72068693          	addi	a3,a3,1824 # ffffffffc0205f48 <commands+0x1aa0>
ffffffffc0203830:	00001617          	auipc	a2,0x1
ffffffffc0203834:	66860613          	addi	a2,a2,1640 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0203838:	14f00593          	li	a1,335
ffffffffc020383c:	00002517          	auipc	a0,0x2
ffffffffc0203840:	43c50513          	addi	a0,a0,1084 # ffffffffc0205c78 <commands+0x17d0>
ffffffffc0203844:	8c1fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(total == 0);
ffffffffc0203848:	00002697          	auipc	a3,0x2
ffffffffc020384c:	73068693          	addi	a3,a3,1840 # ffffffffc0205f78 <commands+0x1ad0>
ffffffffc0203850:	00001617          	auipc	a2,0x1
ffffffffc0203854:	64860613          	addi	a2,a2,1608 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0203858:	15f00593          	li	a1,351
ffffffffc020385c:	00002517          	auipc	a0,0x2
ffffffffc0203860:	41c50513          	addi	a0,a0,1052 # ffffffffc0205c78 <commands+0x17d0>
ffffffffc0203864:	8a1fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(total == nr_free_pages());
ffffffffc0203868:	00002697          	auipc	a3,0x2
ffffffffc020386c:	10068693          	addi	a3,a3,256 # ffffffffc0205968 <commands+0x14c0>
ffffffffc0203870:	00001617          	auipc	a2,0x1
ffffffffc0203874:	62860613          	addi	a2,a2,1576 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0203878:	12b00593          	li	a1,299
ffffffffc020387c:	00002517          	auipc	a0,0x2
ffffffffc0203880:	3fc50513          	addi	a0,a0,1020 # ffffffffc0205c78 <commands+0x17d0>
ffffffffc0203884:	881fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0203888:	00002697          	auipc	a3,0x2
ffffffffc020388c:	42868693          	addi	a3,a3,1064 # ffffffffc0205cb0 <commands+0x1808>
ffffffffc0203890:	00001617          	auipc	a2,0x1
ffffffffc0203894:	60860613          	addi	a2,a2,1544 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0203898:	0ef00593          	li	a1,239
ffffffffc020389c:	00002517          	auipc	a0,0x2
ffffffffc02038a0:	3dc50513          	addi	a0,a0,988 # ffffffffc0205c78 <commands+0x17d0>
ffffffffc02038a4:	861fc0ef          	jal	ra,ffffffffc0200104 <__panic>

ffffffffc02038a8 <default_free_pages>:
{
ffffffffc02038a8:	1141                	addi	sp,sp,-16
ffffffffc02038aa:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02038ac:	18058063          	beqz	a1,ffffffffc0203a2c <default_free_pages+0x184>
    for (; p != base + n; p++)
ffffffffc02038b0:	00359693          	slli	a3,a1,0x3
ffffffffc02038b4:	96ae                	add	a3,a3,a1
ffffffffc02038b6:	068e                	slli	a3,a3,0x3
ffffffffc02038b8:	96aa                	add	a3,a3,a0
ffffffffc02038ba:	02d50d63          	beq	a0,a3,ffffffffc02038f4 <default_free_pages+0x4c>
ffffffffc02038be:	651c                	ld	a5,8(a0)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02038c0:	8b85                	andi	a5,a5,1
ffffffffc02038c2:	14079563          	bnez	a5,ffffffffc0203a0c <default_free_pages+0x164>
ffffffffc02038c6:	651c                	ld	a5,8(a0)
ffffffffc02038c8:	8385                	srli	a5,a5,0x1
ffffffffc02038ca:	8b85                	andi	a5,a5,1
ffffffffc02038cc:	14079063          	bnez	a5,ffffffffc0203a0c <default_free_pages+0x164>
ffffffffc02038d0:	87aa                	mv	a5,a0
ffffffffc02038d2:	a809                	j	ffffffffc02038e4 <default_free_pages+0x3c>
ffffffffc02038d4:	6798                	ld	a4,8(a5)
ffffffffc02038d6:	8b05                	andi	a4,a4,1
ffffffffc02038d8:	12071a63          	bnez	a4,ffffffffc0203a0c <default_free_pages+0x164>
ffffffffc02038dc:	6798                	ld	a4,8(a5)
ffffffffc02038de:	8b09                	andi	a4,a4,2
ffffffffc02038e0:	12071663          	bnez	a4,ffffffffc0203a0c <default_free_pages+0x164>
        p->flags = 0;
ffffffffc02038e4:	0007b423          	sd	zero,8(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02038e8:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc02038ec:	04878793          	addi	a5,a5,72
ffffffffc02038f0:	fed792e3          	bne	a5,a3,ffffffffc02038d4 <default_free_pages+0x2c>
    base->property = n;
ffffffffc02038f4:	2581                	sext.w	a1,a1
ffffffffc02038f6:	cd0c                	sw	a1,24(a0)
    SetPageProperty(base);
ffffffffc02038f8:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02038fc:	4789                	li	a5,2
ffffffffc02038fe:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0203902:	0000e697          	auipc	a3,0xe
ffffffffc0203906:	c7e68693          	addi	a3,a3,-898 # ffffffffc0211580 <free_area>
ffffffffc020390a:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc020390c:	669c                	ld	a5,8(a3)
ffffffffc020390e:	9db9                	addw	a1,a1,a4
ffffffffc0203910:	0000e717          	auipc	a4,0xe
ffffffffc0203914:	c8b72023          	sw	a1,-896(a4) # ffffffffc0211590 <free_area+0x10>
    if (list_empty(&free_list))
ffffffffc0203918:	08d78f63          	beq	a5,a3,ffffffffc02039b6 <default_free_pages+0x10e>
            struct Page *page = le2page(le, page_link);
ffffffffc020391c:	fe078713          	addi	a4,a5,-32
ffffffffc0203920:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list))
ffffffffc0203922:	4801                	li	a6,0
ffffffffc0203924:	02050613          	addi	a2,a0,32
            if (base < page)
ffffffffc0203928:	00e56a63          	bltu	a0,a4,ffffffffc020393c <default_free_pages+0x94>
    return listelm->next;
ffffffffc020392c:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc020392e:	02d70563          	beq	a4,a3,ffffffffc0203958 <default_free_pages+0xb0>
        while ((le = list_next(le)) != &free_list)
ffffffffc0203932:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0203934:	fe078713          	addi	a4,a5,-32
            if (base < page)
ffffffffc0203938:	fee57ae3          	bgeu	a0,a4,ffffffffc020392c <default_free_pages+0x84>
ffffffffc020393c:	00080663          	beqz	a6,ffffffffc0203948 <default_free_pages+0xa0>
ffffffffc0203940:	0000e817          	auipc	a6,0xe
ffffffffc0203944:	c4b83023          	sd	a1,-960(a6) # ffffffffc0211580 <free_area>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0203948:	638c                	ld	a1,0(a5)
    prev->next = next->prev = elm;
ffffffffc020394a:	e390                	sd	a2,0(a5)
ffffffffc020394c:	e590                	sd	a2,8(a1)
    elm->next = next;
ffffffffc020394e:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc0203950:	f10c                	sd	a1,32(a0)
    if (le != &free_list)
ffffffffc0203952:	02d59163          	bne	a1,a3,ffffffffc0203974 <default_free_pages+0xcc>
ffffffffc0203956:	a091                	j	ffffffffc020399a <default_free_pages+0xf2>
    prev->next = next->prev = elm;
ffffffffc0203958:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020395a:	f514                	sd	a3,40(a0)
ffffffffc020395c:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020395e:	f11c                	sd	a5,32(a0)
                list_add(le, &(base->page_link));
ffffffffc0203960:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list)
ffffffffc0203962:	00d70563          	beq	a4,a3,ffffffffc020396c <default_free_pages+0xc4>
ffffffffc0203966:	4805                	li	a6,1
ffffffffc0203968:	87ba                	mv	a5,a4
ffffffffc020396a:	b7e9                	j	ffffffffc0203934 <default_free_pages+0x8c>
ffffffffc020396c:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc020396e:	85be                	mv	a1,a5
    if (le != &free_list)
ffffffffc0203970:	02d78163          	beq	a5,a3,ffffffffc0203992 <default_free_pages+0xea>
        if (p + p->property == base)
ffffffffc0203974:	ff85a803          	lw	a6,-8(a1) # ff8 <BASE_ADDRESS-0xffffffffc01ff008>
        p = le2page(le, page_link);
ffffffffc0203978:	fe058613          	addi	a2,a1,-32
        if (p + p->property == base)
ffffffffc020397c:	02081713          	slli	a4,a6,0x20
ffffffffc0203980:	9301                	srli	a4,a4,0x20
ffffffffc0203982:	00371793          	slli	a5,a4,0x3
ffffffffc0203986:	97ba                	add	a5,a5,a4
ffffffffc0203988:	078e                	slli	a5,a5,0x3
ffffffffc020398a:	97b2                	add	a5,a5,a2
ffffffffc020398c:	02f50e63          	beq	a0,a5,ffffffffc02039c8 <default_free_pages+0x120>
ffffffffc0203990:	751c                	ld	a5,40(a0)
    if (le != &free_list)
ffffffffc0203992:	fe078713          	addi	a4,a5,-32
ffffffffc0203996:	00d78d63          	beq	a5,a3,ffffffffc02039b0 <default_free_pages+0x108>
        if (base + base->property == p)
ffffffffc020399a:	4d0c                	lw	a1,24(a0)
ffffffffc020399c:	02059613          	slli	a2,a1,0x20
ffffffffc02039a0:	9201                	srli	a2,a2,0x20
ffffffffc02039a2:	00361693          	slli	a3,a2,0x3
ffffffffc02039a6:	96b2                	add	a3,a3,a2
ffffffffc02039a8:	068e                	slli	a3,a3,0x3
ffffffffc02039aa:	96aa                	add	a3,a3,a0
ffffffffc02039ac:	04d70063          	beq	a4,a3,ffffffffc02039ec <default_free_pages+0x144>
}
ffffffffc02039b0:	60a2                	ld	ra,8(sp)
ffffffffc02039b2:	0141                	addi	sp,sp,16
ffffffffc02039b4:	8082                	ret
ffffffffc02039b6:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc02039b8:	02050713          	addi	a4,a0,32
    prev->next = next->prev = elm;
ffffffffc02039bc:	e398                	sd	a4,0(a5)
ffffffffc02039be:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc02039c0:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc02039c2:	f11c                	sd	a5,32(a0)
}
ffffffffc02039c4:	0141                	addi	sp,sp,16
ffffffffc02039c6:	8082                	ret
            p->property += base->property;
ffffffffc02039c8:	4d1c                	lw	a5,24(a0)
ffffffffc02039ca:	0107883b          	addw	a6,a5,a6
ffffffffc02039ce:	ff05ac23          	sw	a6,-8(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02039d2:	57f5                	li	a5,-3
ffffffffc02039d4:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc02039d8:	02053803          	ld	a6,32(a0)
ffffffffc02039dc:	7518                	ld	a4,40(a0)
            base = p;
ffffffffc02039de:	8532                	mv	a0,a2
    prev->next = next;
ffffffffc02039e0:	00e83423          	sd	a4,8(a6)
    next->prev = prev;
ffffffffc02039e4:	659c                	ld	a5,8(a1)
ffffffffc02039e6:	01073023          	sd	a6,0(a4)
ffffffffc02039ea:	b765                	j	ffffffffc0203992 <default_free_pages+0xea>
            base->property += p->property;
ffffffffc02039ec:	ff87a703          	lw	a4,-8(a5)
ffffffffc02039f0:	fe878693          	addi	a3,a5,-24
ffffffffc02039f4:	9db9                	addw	a1,a1,a4
ffffffffc02039f6:	cd0c                	sw	a1,24(a0)
ffffffffc02039f8:	5775                	li	a4,-3
ffffffffc02039fa:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02039fe:	6398                	ld	a4,0(a5)
ffffffffc0203a00:	679c                	ld	a5,8(a5)
}
ffffffffc0203a02:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0203a04:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203a06:	e398                	sd	a4,0(a5)
ffffffffc0203a08:	0141                	addi	sp,sp,16
ffffffffc0203a0a:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0203a0c:	00002697          	auipc	a3,0x2
ffffffffc0203a10:	57c68693          	addi	a3,a3,1404 # ffffffffc0205f88 <commands+0x1ae0>
ffffffffc0203a14:	00001617          	auipc	a2,0x1
ffffffffc0203a18:	48460613          	addi	a2,a2,1156 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0203a1c:	0ab00593          	li	a1,171
ffffffffc0203a20:	00002517          	auipc	a0,0x2
ffffffffc0203a24:	25850513          	addi	a0,a0,600 # ffffffffc0205c78 <commands+0x17d0>
ffffffffc0203a28:	edcfc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(n > 0);
ffffffffc0203a2c:	00002697          	auipc	a3,0x2
ffffffffc0203a30:	58468693          	addi	a3,a3,1412 # ffffffffc0205fb0 <commands+0x1b08>
ffffffffc0203a34:	00001617          	auipc	a2,0x1
ffffffffc0203a38:	46460613          	addi	a2,a2,1124 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0203a3c:	0a700593          	li	a1,167
ffffffffc0203a40:	00002517          	auipc	a0,0x2
ffffffffc0203a44:	23850513          	addi	a0,a0,568 # ffffffffc0205c78 <commands+0x17d0>
ffffffffc0203a48:	ebcfc0ef          	jal	ra,ffffffffc0200104 <__panic>

ffffffffc0203a4c <default_alloc_pages>:
    assert(n > 0);
ffffffffc0203a4c:	cd51                	beqz	a0,ffffffffc0203ae8 <default_alloc_pages+0x9c>
    if (n > nr_free)
ffffffffc0203a4e:	0000e597          	auipc	a1,0xe
ffffffffc0203a52:	b3258593          	addi	a1,a1,-1230 # ffffffffc0211580 <free_area>
ffffffffc0203a56:	0105a803          	lw	a6,16(a1)
ffffffffc0203a5a:	862a                	mv	a2,a0
ffffffffc0203a5c:	02081793          	slli	a5,a6,0x20
ffffffffc0203a60:	9381                	srli	a5,a5,0x20
ffffffffc0203a62:	00a7ee63          	bltu	a5,a0,ffffffffc0203a7e <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc0203a66:	87ae                	mv	a5,a1
ffffffffc0203a68:	a801                	j	ffffffffc0203a78 <default_alloc_pages+0x2c>
        if (p->property >= n)
ffffffffc0203a6a:	ff87a703          	lw	a4,-8(a5)
ffffffffc0203a6e:	02071693          	slli	a3,a4,0x20
ffffffffc0203a72:	9281                	srli	a3,a3,0x20
ffffffffc0203a74:	00c6f763          	bgeu	a3,a2,ffffffffc0203a82 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0203a78:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc0203a7a:	feb798e3          	bne	a5,a1,ffffffffc0203a6a <default_alloc_pages+0x1e>
        return NULL;
ffffffffc0203a7e:	4501                	li	a0,0
}
ffffffffc0203a80:	8082                	ret
        struct Page *p = le2page(le, page_link);
ffffffffc0203a82:	fe078513          	addi	a0,a5,-32
    if (page != NULL)
ffffffffc0203a86:	dd6d                	beqz	a0,ffffffffc0203a80 <default_alloc_pages+0x34>
    return listelm->prev;
ffffffffc0203a88:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0203a8c:	0087b303          	ld	t1,8(a5)
    prev->next = next;
ffffffffc0203a90:	00060e1b          	sext.w	t3,a2
ffffffffc0203a94:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc0203a98:	01133023          	sd	a7,0(t1)
        if (page->property > n)
ffffffffc0203a9c:	02d67b63          	bgeu	a2,a3,ffffffffc0203ad2 <default_alloc_pages+0x86>
            struct Page *p = page + n;
ffffffffc0203aa0:	00361693          	slli	a3,a2,0x3
ffffffffc0203aa4:	96b2                	add	a3,a3,a2
ffffffffc0203aa6:	068e                	slli	a3,a3,0x3
ffffffffc0203aa8:	96aa                	add	a3,a3,a0
            p->property = page->property - n;
ffffffffc0203aaa:	41c7073b          	subw	a4,a4,t3
ffffffffc0203aae:	ce98                	sw	a4,24(a3)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0203ab0:	00868613          	addi	a2,a3,8
ffffffffc0203ab4:	4709                	li	a4,2
ffffffffc0203ab6:	40e6302f          	amoor.d	zero,a4,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc0203aba:	0088b703          	ld	a4,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc0203abe:	02068613          	addi	a2,a3,32
    prev->next = next->prev = elm;
ffffffffc0203ac2:	0105a803          	lw	a6,16(a1)
ffffffffc0203ac6:	e310                	sd	a2,0(a4)
ffffffffc0203ac8:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc0203acc:	f698                	sd	a4,40(a3)
    elm->prev = prev;
ffffffffc0203ace:	0316b023          	sd	a7,32(a3)
        nr_free -= n;
ffffffffc0203ad2:	41c8083b          	subw	a6,a6,t3
ffffffffc0203ad6:	0000e717          	auipc	a4,0xe
ffffffffc0203ada:	ab072d23          	sw	a6,-1350(a4) # ffffffffc0211590 <free_area+0x10>
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0203ade:	5775                	li	a4,-3
ffffffffc0203ae0:	17a1                	addi	a5,a5,-24
ffffffffc0203ae2:	60e7b02f          	amoand.d	zero,a4,(a5)
ffffffffc0203ae6:	8082                	ret
{
ffffffffc0203ae8:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0203aea:	00002697          	auipc	a3,0x2
ffffffffc0203aee:	4c668693          	addi	a3,a3,1222 # ffffffffc0205fb0 <commands+0x1b08>
ffffffffc0203af2:	00001617          	auipc	a2,0x1
ffffffffc0203af6:	3a660613          	addi	a2,a2,934 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0203afa:	08300593          	li	a1,131
ffffffffc0203afe:	00002517          	auipc	a0,0x2
ffffffffc0203b02:	17a50513          	addi	a0,a0,378 # ffffffffc0205c78 <commands+0x17d0>
{
ffffffffc0203b06:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0203b08:	dfcfc0ef          	jal	ra,ffffffffc0200104 <__panic>

ffffffffc0203b0c <default_init_memmap>:
{
ffffffffc0203b0c:	7179                	addi	sp,sp,-48
ffffffffc0203b0e:	f406                	sd	ra,40(sp)
ffffffffc0203b10:	f022                	sd	s0,32(sp)
ffffffffc0203b12:	ec26                	sd	s1,24(sp)
ffffffffc0203b14:	e84a                	sd	s2,16(sp)
ffffffffc0203b16:	e44e                	sd	s3,8(sp)
ffffffffc0203b18:	e052                	sd	s4,0(sp)
    assert(n > 0);
ffffffffc0203b1a:	12058563          	beqz	a1,ffffffffc0203c44 <default_init_memmap+0x138>
ffffffffc0203b1e:	892e                	mv	s2,a1
ffffffffc0203b20:	842a                	mv	s0,a0
    for (; p != base + 3; p++)
ffffffffc0203b22:	0d850a13          	addi	s4,a0,216
ffffffffc0203b26:	84aa                	mv	s1,a0
        cprintf("p的虚拟地址: 0x%016lx.\n", (uintptr_t)p);
ffffffffc0203b28:	00002997          	auipc	s3,0x2
ffffffffc0203b2c:	49098993          	addi	s3,s3,1168 # ffffffffc0205fb8 <commands+0x1b10>
ffffffffc0203b30:	85a6                	mv	a1,s1
ffffffffc0203b32:	854e                	mv	a0,s3
    for (; p != base + 3; p++)
ffffffffc0203b34:	04848493          	addi	s1,s1,72
        cprintf("p的虚拟地址: 0x%016lx.\n", (uintptr_t)p);
ffffffffc0203b38:	d86fc0ef          	jal	ra,ffffffffc02000be <cprintf>
    for (; p != base + 3; p++)
ffffffffc0203b3c:	ff449ae3          	bne	s1,s4,ffffffffc0203b30 <default_init_memmap+0x24>
    for (; p != base + n; p++)
ffffffffc0203b40:	00391693          	slli	a3,s2,0x3
ffffffffc0203b44:	96ca                	add	a3,a3,s2
ffffffffc0203b46:	068e                	slli	a3,a3,0x3
ffffffffc0203b48:	96a2                	add	a3,a3,s0
ffffffffc0203b4a:	02d40463          	beq	s0,a3,ffffffffc0203b72 <default_init_memmap+0x66>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0203b4e:	6418                	ld	a4,8(s0)
        assert(PageReserved(p));
ffffffffc0203b50:	87a2                	mv	a5,s0
ffffffffc0203b52:	8b05                	andi	a4,a4,1
ffffffffc0203b54:	e709                	bnez	a4,ffffffffc0203b5e <default_init_memmap+0x52>
ffffffffc0203b56:	a0f9                	j	ffffffffc0203c24 <default_init_memmap+0x118>
ffffffffc0203b58:	6798                	ld	a4,8(a5)
ffffffffc0203b5a:	8b05                	andi	a4,a4,1
ffffffffc0203b5c:	c761                	beqz	a4,ffffffffc0203c24 <default_init_memmap+0x118>
        p->flags = p->property = 0;
ffffffffc0203b5e:	0007ac23          	sw	zero,24(a5)
ffffffffc0203b62:	0007b423          	sd	zero,8(a5)
ffffffffc0203b66:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0203b6a:	04878793          	addi	a5,a5,72
ffffffffc0203b6e:	fed795e3          	bne	a5,a3,ffffffffc0203b58 <default_init_memmap+0x4c>
    base->property = n;
ffffffffc0203b72:	2901                	sext.w	s2,s2
ffffffffc0203b74:	01242c23          	sw	s2,24(s0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0203b78:	4789                	li	a5,2
ffffffffc0203b7a:	00840713          	addi	a4,s0,8
ffffffffc0203b7e:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0203b82:	0000e697          	auipc	a3,0xe
ffffffffc0203b86:	9fe68693          	addi	a3,a3,-1538 # ffffffffc0211580 <free_area>
ffffffffc0203b8a:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0203b8c:	669c                	ld	a5,8(a3)
ffffffffc0203b8e:	0127093b          	addw	s2,a4,s2
ffffffffc0203b92:	0000e717          	auipc	a4,0xe
ffffffffc0203b96:	9f272f23          	sw	s2,-1538(a4) # ffffffffc0211590 <free_area+0x10>
    if (list_empty(&free_list))
ffffffffc0203b9a:	04d78e63          	beq	a5,a3,ffffffffc0203bf6 <default_init_memmap+0xea>
            struct Page *page = le2page(le, page_link);
ffffffffc0203b9e:	fe078713          	addi	a4,a5,-32
ffffffffc0203ba2:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list))
ffffffffc0203ba4:	4501                	li	a0,0
ffffffffc0203ba6:	02040613          	addi	a2,s0,32
            if (base < page)
ffffffffc0203baa:	00e46a63          	bltu	s0,a4,ffffffffc0203bbe <default_init_memmap+0xb2>
    return listelm->next;
ffffffffc0203bae:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0203bb0:	02d70963          	beq	a4,a3,ffffffffc0203be2 <default_init_memmap+0xd6>
        while ((le = list_next(le)) != &free_list)
ffffffffc0203bb4:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0203bb6:	fe078713          	addi	a4,a5,-32
            if (base < page)
ffffffffc0203bba:	fee47ae3          	bgeu	s0,a4,ffffffffc0203bae <default_init_memmap+0xa2>
ffffffffc0203bbe:	c509                	beqz	a0,ffffffffc0203bc8 <default_init_memmap+0xbc>
ffffffffc0203bc0:	0000e717          	auipc	a4,0xe
ffffffffc0203bc4:	9cb73023          	sd	a1,-1600(a4) # ffffffffc0211580 <free_area>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0203bc8:	6398                	ld	a4,0(a5)
    prev->next = next->prev = elm;
ffffffffc0203bca:	e390                	sd	a2,0(a5)
}
ffffffffc0203bcc:	70a2                	ld	ra,40(sp)
ffffffffc0203bce:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0203bd0:	f41c                	sd	a5,40(s0)
    elm->prev = prev;
ffffffffc0203bd2:	f018                	sd	a4,32(s0)
ffffffffc0203bd4:	7402                	ld	s0,32(sp)
ffffffffc0203bd6:	64e2                	ld	s1,24(sp)
ffffffffc0203bd8:	6942                	ld	s2,16(sp)
ffffffffc0203bda:	69a2                	ld	s3,8(sp)
ffffffffc0203bdc:	6a02                	ld	s4,0(sp)
ffffffffc0203bde:	6145                	addi	sp,sp,48
ffffffffc0203be0:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0203be2:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0203be4:	f414                	sd	a3,40(s0)
ffffffffc0203be6:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0203be8:	f01c                	sd	a5,32(s0)
                list_add(le, &(base->page_link));
ffffffffc0203bea:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list)
ffffffffc0203bec:	02d70363          	beq	a4,a3,ffffffffc0203c12 <default_init_memmap+0x106>
ffffffffc0203bf0:	4505                	li	a0,1
ffffffffc0203bf2:	87ba                	mv	a5,a4
ffffffffc0203bf4:	b7c9                	j	ffffffffc0203bb6 <default_init_memmap+0xaa>
        list_add(&free_list, &(base->page_link));
ffffffffc0203bf6:	02040713          	addi	a4,s0,32
    elm->next = next;
ffffffffc0203bfa:	f41c                	sd	a5,40(s0)
    elm->prev = prev;
ffffffffc0203bfc:	f01c                	sd	a5,32(s0)
}
ffffffffc0203bfe:	70a2                	ld	ra,40(sp)
ffffffffc0203c00:	7402                	ld	s0,32(sp)
    prev->next = next->prev = elm;
ffffffffc0203c02:	e398                	sd	a4,0(a5)
ffffffffc0203c04:	e798                	sd	a4,8(a5)
ffffffffc0203c06:	64e2                	ld	s1,24(sp)
ffffffffc0203c08:	6942                	ld	s2,16(sp)
ffffffffc0203c0a:	69a2                	ld	s3,8(sp)
ffffffffc0203c0c:	6a02                	ld	s4,0(sp)
ffffffffc0203c0e:	6145                	addi	sp,sp,48
ffffffffc0203c10:	8082                	ret
ffffffffc0203c12:	70a2                	ld	ra,40(sp)
ffffffffc0203c14:	7402                	ld	s0,32(sp)
ffffffffc0203c16:	e290                	sd	a2,0(a3)
ffffffffc0203c18:	64e2                	ld	s1,24(sp)
ffffffffc0203c1a:	6942                	ld	s2,16(sp)
ffffffffc0203c1c:	69a2                	ld	s3,8(sp)
ffffffffc0203c1e:	6a02                	ld	s4,0(sp)
ffffffffc0203c20:	6145                	addi	sp,sp,48
ffffffffc0203c22:	8082                	ret
        assert(PageReserved(p));
ffffffffc0203c24:	00002697          	auipc	a3,0x2
ffffffffc0203c28:	3b468693          	addi	a3,a3,948 # ffffffffc0205fd8 <commands+0x1b30>
ffffffffc0203c2c:	00001617          	auipc	a2,0x1
ffffffffc0203c30:	26c60613          	addi	a2,a2,620 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0203c34:	05900593          	li	a1,89
ffffffffc0203c38:	00002517          	auipc	a0,0x2
ffffffffc0203c3c:	04050513          	addi	a0,a0,64 # ffffffffc0205c78 <commands+0x17d0>
ffffffffc0203c40:	cc4fc0ef          	jal	ra,ffffffffc0200104 <__panic>
    assert(n > 0);
ffffffffc0203c44:	00002697          	auipc	a3,0x2
ffffffffc0203c48:	36c68693          	addi	a3,a3,876 # ffffffffc0205fb0 <commands+0x1b08>
ffffffffc0203c4c:	00001617          	auipc	a2,0x1
ffffffffc0203c50:	24c60613          	addi	a2,a2,588 # ffffffffc0204e98 <commands+0x9f0>
ffffffffc0203c54:	04a00593          	li	a1,74
ffffffffc0203c58:	00002517          	auipc	a0,0x2
ffffffffc0203c5c:	02050513          	addi	a0,a0,32 # ffffffffc0205c78 <commands+0x17d0>
ffffffffc0203c60:	ca4fc0ef          	jal	ra,ffffffffc0200104 <__panic>

ffffffffc0203c64 <swapfs_init>:
#include <ide.h>
#include <pmm.h>
#include <assert.h>

void
swapfs_init(void) {
ffffffffc0203c64:	1141                	addi	sp,sp,-16
    static_assert((PGSIZE % SECTSIZE) == 0);
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0203c66:	4505                	li	a0,1
swapfs_init(void) {
ffffffffc0203c68:	e406                	sd	ra,8(sp)
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0203c6a:	f68fc0ef          	jal	ra,ffffffffc02003d2 <ide_device_valid>
ffffffffc0203c6e:	cd01                	beqz	a0,ffffffffc0203c86 <swapfs_init+0x22>
        panic("swap fs isn't available.\n");
    }
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0203c70:	4505                	li	a0,1
ffffffffc0203c72:	f66fc0ef          	jal	ra,ffffffffc02003d8 <ide_device_size>
}
ffffffffc0203c76:	60a2                	ld	ra,8(sp)
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0203c78:	810d                	srli	a0,a0,0x3
ffffffffc0203c7a:	0000e797          	auipc	a5,0xe
ffffffffc0203c7e:	8ca7b323          	sd	a0,-1850(a5) # ffffffffc0211540 <max_swap_offset>
}
ffffffffc0203c82:	0141                	addi	sp,sp,16
ffffffffc0203c84:	8082                	ret
        panic("swap fs isn't available.\n");
ffffffffc0203c86:	00002617          	auipc	a2,0x2
ffffffffc0203c8a:	3b260613          	addi	a2,a2,946 # ffffffffc0206038 <default_pmm_manager+0x50>
ffffffffc0203c8e:	45b5                	li	a1,13
ffffffffc0203c90:	00002517          	auipc	a0,0x2
ffffffffc0203c94:	3c850513          	addi	a0,a0,968 # ffffffffc0206058 <default_pmm_manager+0x70>
ffffffffc0203c98:	c6cfc0ef          	jal	ra,ffffffffc0200104 <__panic>

ffffffffc0203c9c <swapfs_read>:

int
swapfs_read(swap_entry_t entry, struct Page *page) {
ffffffffc0203c9c:	1141                	addi	sp,sp,-16
ffffffffc0203c9e:	e406                	sd	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203ca0:	00855793          	srli	a5,a0,0x8
ffffffffc0203ca4:	c7b5                	beqz	a5,ffffffffc0203d10 <swapfs_read+0x74>
ffffffffc0203ca6:	0000e717          	auipc	a4,0xe
ffffffffc0203caa:	89a70713          	addi	a4,a4,-1894 # ffffffffc0211540 <max_swap_offset>
ffffffffc0203cae:	6318                	ld	a4,0(a4)
ffffffffc0203cb0:	06e7f063          	bgeu	a5,a4,ffffffffc0203d10 <swapfs_read+0x74>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203cb4:	0000d717          	auipc	a4,0xd
ffffffffc0203cb8:	7e470713          	addi	a4,a4,2020 # ffffffffc0211498 <pages>
ffffffffc0203cbc:	6310                	ld	a2,0(a4)
ffffffffc0203cbe:	00001717          	auipc	a4,0x1
ffffffffc0203cc2:	02270713          	addi	a4,a4,34 # ffffffffc0204ce0 <commands+0x838>
ffffffffc0203cc6:	00002697          	auipc	a3,0x2
ffffffffc0203cca:	61268693          	addi	a3,a3,1554 # ffffffffc02062d8 <nbase>
ffffffffc0203cce:	40c58633          	sub	a2,a1,a2
ffffffffc0203cd2:	630c                	ld	a1,0(a4)
ffffffffc0203cd4:	860d                	srai	a2,a2,0x3
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203cd6:	0000d717          	auipc	a4,0xd
ffffffffc0203cda:	78270713          	addi	a4,a4,1922 # ffffffffc0211458 <npage>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203cde:	02b60633          	mul	a2,a2,a1
ffffffffc0203ce2:	0037959b          	slliw	a1,a5,0x3
ffffffffc0203ce6:	629c                	ld	a5,0(a3)
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203ce8:	6318                	ld	a4,0(a4)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203cea:	963e                	add	a2,a2,a5
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203cec:	00c61793          	slli	a5,a2,0xc
ffffffffc0203cf0:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0203cf2:	0632                	slli	a2,a2,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203cf4:	02e7fa63          	bgeu	a5,a4,ffffffffc0203d28 <swapfs_read+0x8c>
ffffffffc0203cf8:	0000d797          	auipc	a5,0xd
ffffffffc0203cfc:	79078793          	addi	a5,a5,1936 # ffffffffc0211488 <va_pa_offset>
ffffffffc0203d00:	639c                	ld	a5,0(a5)
}
ffffffffc0203d02:	60a2                	ld	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203d04:	46a1                	li	a3,8
ffffffffc0203d06:	963e                	add	a2,a2,a5
ffffffffc0203d08:	4505                	li	a0,1
}
ffffffffc0203d0a:	0141                	addi	sp,sp,16
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203d0c:	ed2fc06f          	j	ffffffffc02003de <ide_read_secs>
ffffffffc0203d10:	86aa                	mv	a3,a0
ffffffffc0203d12:	00002617          	auipc	a2,0x2
ffffffffc0203d16:	35e60613          	addi	a2,a2,862 # ffffffffc0206070 <default_pmm_manager+0x88>
ffffffffc0203d1a:	45d1                	li	a1,20
ffffffffc0203d1c:	00002517          	auipc	a0,0x2
ffffffffc0203d20:	33c50513          	addi	a0,a0,828 # ffffffffc0206058 <default_pmm_manager+0x70>
ffffffffc0203d24:	be0fc0ef          	jal	ra,ffffffffc0200104 <__panic>
ffffffffc0203d28:	86b2                	mv	a3,a2
ffffffffc0203d2a:	06a00593          	li	a1,106
ffffffffc0203d2e:	00001617          	auipc	a2,0x1
ffffffffc0203d32:	fba60613          	addi	a2,a2,-70 # ffffffffc0204ce8 <commands+0x840>
ffffffffc0203d36:	00001517          	auipc	a0,0x1
ffffffffc0203d3a:	04a50513          	addi	a0,a0,74 # ffffffffc0204d80 <commands+0x8d8>
ffffffffc0203d3e:	bc6fc0ef          	jal	ra,ffffffffc0200104 <__panic>

ffffffffc0203d42 <swapfs_write>:

int
swapfs_write(swap_entry_t entry, struct Page *page) {
ffffffffc0203d42:	1141                	addi	sp,sp,-16
ffffffffc0203d44:	e406                	sd	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203d46:	00855793          	srli	a5,a0,0x8
ffffffffc0203d4a:	c7b5                	beqz	a5,ffffffffc0203db6 <swapfs_write+0x74>
ffffffffc0203d4c:	0000d717          	auipc	a4,0xd
ffffffffc0203d50:	7f470713          	addi	a4,a4,2036 # ffffffffc0211540 <max_swap_offset>
ffffffffc0203d54:	6318                	ld	a4,0(a4)
ffffffffc0203d56:	06e7f063          	bgeu	a5,a4,ffffffffc0203db6 <swapfs_write+0x74>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203d5a:	0000d717          	auipc	a4,0xd
ffffffffc0203d5e:	73e70713          	addi	a4,a4,1854 # ffffffffc0211498 <pages>
ffffffffc0203d62:	6310                	ld	a2,0(a4)
ffffffffc0203d64:	00001717          	auipc	a4,0x1
ffffffffc0203d68:	f7c70713          	addi	a4,a4,-132 # ffffffffc0204ce0 <commands+0x838>
ffffffffc0203d6c:	00002697          	auipc	a3,0x2
ffffffffc0203d70:	56c68693          	addi	a3,a3,1388 # ffffffffc02062d8 <nbase>
ffffffffc0203d74:	40c58633          	sub	a2,a1,a2
ffffffffc0203d78:	630c                	ld	a1,0(a4)
ffffffffc0203d7a:	860d                	srai	a2,a2,0x3
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203d7c:	0000d717          	auipc	a4,0xd
ffffffffc0203d80:	6dc70713          	addi	a4,a4,1756 # ffffffffc0211458 <npage>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203d84:	02b60633          	mul	a2,a2,a1
ffffffffc0203d88:	0037959b          	slliw	a1,a5,0x3
ffffffffc0203d8c:	629c                	ld	a5,0(a3)
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203d8e:	6318                	ld	a4,0(a4)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203d90:	963e                	add	a2,a2,a5
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203d92:	00c61793          	slli	a5,a2,0xc
ffffffffc0203d96:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0203d98:	0632                	slli	a2,a2,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203d9a:	02e7fa63          	bgeu	a5,a4,ffffffffc0203dce <swapfs_write+0x8c>
ffffffffc0203d9e:	0000d797          	auipc	a5,0xd
ffffffffc0203da2:	6ea78793          	addi	a5,a5,1770 # ffffffffc0211488 <va_pa_offset>
ffffffffc0203da6:	639c                	ld	a5,0(a5)
}
ffffffffc0203da8:	60a2                	ld	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203daa:	46a1                	li	a3,8
ffffffffc0203dac:	963e                	add	a2,a2,a5
ffffffffc0203dae:	4505                	li	a0,1
}
ffffffffc0203db0:	0141                	addi	sp,sp,16
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203db2:	e50fc06f          	j	ffffffffc0200402 <ide_write_secs>
ffffffffc0203db6:	86aa                	mv	a3,a0
ffffffffc0203db8:	00002617          	auipc	a2,0x2
ffffffffc0203dbc:	2b860613          	addi	a2,a2,696 # ffffffffc0206070 <default_pmm_manager+0x88>
ffffffffc0203dc0:	45e5                	li	a1,25
ffffffffc0203dc2:	00002517          	auipc	a0,0x2
ffffffffc0203dc6:	29650513          	addi	a0,a0,662 # ffffffffc0206058 <default_pmm_manager+0x70>
ffffffffc0203dca:	b3afc0ef          	jal	ra,ffffffffc0200104 <__panic>
ffffffffc0203dce:	86b2                	mv	a3,a2
ffffffffc0203dd0:	06a00593          	li	a1,106
ffffffffc0203dd4:	00001617          	auipc	a2,0x1
ffffffffc0203dd8:	f1460613          	addi	a2,a2,-236 # ffffffffc0204ce8 <commands+0x840>
ffffffffc0203ddc:	00001517          	auipc	a0,0x1
ffffffffc0203de0:	fa450513          	addi	a0,a0,-92 # ffffffffc0204d80 <commands+0x8d8>
ffffffffc0203de4:	b20fc0ef          	jal	ra,ffffffffc0200104 <__panic>

ffffffffc0203de8 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0203de8:	00054783          	lbu	a5,0(a0)
ffffffffc0203dec:	cb91                	beqz	a5,ffffffffc0203e00 <strlen+0x18>
    size_t cnt = 0;
ffffffffc0203dee:	4781                	li	a5,0
        cnt ++;
ffffffffc0203df0:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc0203df2:	00f50733          	add	a4,a0,a5
ffffffffc0203df6:	00074703          	lbu	a4,0(a4)
ffffffffc0203dfa:	fb7d                	bnez	a4,ffffffffc0203df0 <strlen+0x8>
    }
    return cnt;
}
ffffffffc0203dfc:	853e                	mv	a0,a5
ffffffffc0203dfe:	8082                	ret
    size_t cnt = 0;
ffffffffc0203e00:	4781                	li	a5,0
}
ffffffffc0203e02:	853e                	mv	a0,a5
ffffffffc0203e04:	8082                	ret

ffffffffc0203e06 <strnlen>:
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203e06:	c185                	beqz	a1,ffffffffc0203e26 <strnlen+0x20>
ffffffffc0203e08:	00054783          	lbu	a5,0(a0)
ffffffffc0203e0c:	cf89                	beqz	a5,ffffffffc0203e26 <strnlen+0x20>
    size_t cnt = 0;
ffffffffc0203e0e:	4781                	li	a5,0
ffffffffc0203e10:	a021                	j	ffffffffc0203e18 <strnlen+0x12>
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203e12:	00074703          	lbu	a4,0(a4)
ffffffffc0203e16:	c711                	beqz	a4,ffffffffc0203e22 <strnlen+0x1c>
        cnt ++;
ffffffffc0203e18:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203e1a:	00f50733          	add	a4,a0,a5
ffffffffc0203e1e:	fef59ae3          	bne	a1,a5,ffffffffc0203e12 <strnlen+0xc>
    }
    return cnt;
}
ffffffffc0203e22:	853e                	mv	a0,a5
ffffffffc0203e24:	8082                	ret
    size_t cnt = 0;
ffffffffc0203e26:	4781                	li	a5,0
}
ffffffffc0203e28:	853e                	mv	a0,a5
ffffffffc0203e2a:	8082                	ret

ffffffffc0203e2c <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0203e2c:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0203e2e:	0585                	addi	a1,a1,1
ffffffffc0203e30:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0203e34:	0785                	addi	a5,a5,1
ffffffffc0203e36:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0203e3a:	fb75                	bnez	a4,ffffffffc0203e2e <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0203e3c:	8082                	ret

ffffffffc0203e3e <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203e3e:	00054783          	lbu	a5,0(a0)
ffffffffc0203e42:	0005c703          	lbu	a4,0(a1)
ffffffffc0203e46:	cb91                	beqz	a5,ffffffffc0203e5a <strcmp+0x1c>
ffffffffc0203e48:	00e79c63          	bne	a5,a4,ffffffffc0203e60 <strcmp+0x22>
        s1 ++, s2 ++;
ffffffffc0203e4c:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203e4e:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
ffffffffc0203e52:	0585                	addi	a1,a1,1
ffffffffc0203e54:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203e58:	fbe5                	bnez	a5,ffffffffc0203e48 <strcmp+0xa>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e5a:	4501                	li	a0,0
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0203e5c:	9d19                	subw	a0,a0,a4
ffffffffc0203e5e:	8082                	ret
ffffffffc0203e60:	0007851b          	sext.w	a0,a5
ffffffffc0203e64:	9d19                	subw	a0,a0,a4
ffffffffc0203e66:	8082                	ret

ffffffffc0203e68 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0203e68:	00054783          	lbu	a5,0(a0)
ffffffffc0203e6c:	cb91                	beqz	a5,ffffffffc0203e80 <strchr+0x18>
        if (*s == c) {
ffffffffc0203e6e:	00b79563          	bne	a5,a1,ffffffffc0203e78 <strchr+0x10>
ffffffffc0203e72:	a809                	j	ffffffffc0203e84 <strchr+0x1c>
ffffffffc0203e74:	00b78763          	beq	a5,a1,ffffffffc0203e82 <strchr+0x1a>
            return (char *)s;
        }
        s ++;
ffffffffc0203e78:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0203e7a:	00054783          	lbu	a5,0(a0)
ffffffffc0203e7e:	fbfd                	bnez	a5,ffffffffc0203e74 <strchr+0xc>
    }
    return NULL;
ffffffffc0203e80:	4501                	li	a0,0
}
ffffffffc0203e82:	8082                	ret
ffffffffc0203e84:	8082                	ret

ffffffffc0203e86 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0203e86:	ca01                	beqz	a2,ffffffffc0203e96 <memset+0x10>
ffffffffc0203e88:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0203e8a:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0203e8c:	0785                	addi	a5,a5,1
ffffffffc0203e8e:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0203e92:	fec79de3          	bne	a5,a2,ffffffffc0203e8c <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0203e96:	8082                	ret

ffffffffc0203e98 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0203e98:	ca19                	beqz	a2,ffffffffc0203eae <memcpy+0x16>
ffffffffc0203e9a:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0203e9c:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0203e9e:	0585                	addi	a1,a1,1
ffffffffc0203ea0:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0203ea4:	0785                	addi	a5,a5,1
ffffffffc0203ea6:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0203eaa:	fec59ae3          	bne	a1,a2,ffffffffc0203e9e <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0203eae:	8082                	ret

ffffffffc0203eb0 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0203eb0:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203eb4:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0203eb6:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203eba:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0203ebc:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203ec0:	f022                	sd	s0,32(sp)
ffffffffc0203ec2:	ec26                	sd	s1,24(sp)
ffffffffc0203ec4:	e84a                	sd	s2,16(sp)
ffffffffc0203ec6:	f406                	sd	ra,40(sp)
ffffffffc0203ec8:	e44e                	sd	s3,8(sp)
ffffffffc0203eca:	84aa                	mv	s1,a0
ffffffffc0203ecc:	892e                	mv	s2,a1
ffffffffc0203ece:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0203ed2:	2a01                	sext.w	s4,s4

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
ffffffffc0203ed4:	03067e63          	bgeu	a2,a6,ffffffffc0203f10 <printnum+0x60>
ffffffffc0203ed8:	89be                	mv	s3,a5
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0203eda:	00805763          	blez	s0,ffffffffc0203ee8 <printnum+0x38>
ffffffffc0203ede:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0203ee0:	85ca                	mv	a1,s2
ffffffffc0203ee2:	854e                	mv	a0,s3
ffffffffc0203ee4:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0203ee6:	fc65                	bnez	s0,ffffffffc0203ede <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203ee8:	1a02                	slli	s4,s4,0x20
ffffffffc0203eea:	020a5a13          	srli	s4,s4,0x20
ffffffffc0203eee:	00002797          	auipc	a5,0x2
ffffffffc0203ef2:	33278793          	addi	a5,a5,818 # ffffffffc0206220 <error_string+0x38>
ffffffffc0203ef6:	9a3e                	add	s4,s4,a5
}
ffffffffc0203ef8:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203efa:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0203efe:	70a2                	ld	ra,40(sp)
ffffffffc0203f00:	69a2                	ld	s3,8(sp)
ffffffffc0203f02:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203f04:	85ca                	mv	a1,s2
ffffffffc0203f06:	8326                	mv	t1,s1
}
ffffffffc0203f08:	6942                	ld	s2,16(sp)
ffffffffc0203f0a:	64e2                	ld	s1,24(sp)
ffffffffc0203f0c:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203f0e:	8302                	jr	t1
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0203f10:	03065633          	divu	a2,a2,a6
ffffffffc0203f14:	8722                	mv	a4,s0
ffffffffc0203f16:	f9bff0ef          	jal	ra,ffffffffc0203eb0 <printnum>
ffffffffc0203f1a:	b7f9                	j	ffffffffc0203ee8 <printnum+0x38>

ffffffffc0203f1c <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0203f1c:	7119                	addi	sp,sp,-128
ffffffffc0203f1e:	f4a6                	sd	s1,104(sp)
ffffffffc0203f20:	f0ca                	sd	s2,96(sp)
ffffffffc0203f22:	e8d2                	sd	s4,80(sp)
ffffffffc0203f24:	e4d6                	sd	s5,72(sp)
ffffffffc0203f26:	e0da                	sd	s6,64(sp)
ffffffffc0203f28:	fc5e                	sd	s7,56(sp)
ffffffffc0203f2a:	f862                	sd	s8,48(sp)
ffffffffc0203f2c:	f06a                	sd	s10,32(sp)
ffffffffc0203f2e:	fc86                	sd	ra,120(sp)
ffffffffc0203f30:	f8a2                	sd	s0,112(sp)
ffffffffc0203f32:	ecce                	sd	s3,88(sp)
ffffffffc0203f34:	f466                	sd	s9,40(sp)
ffffffffc0203f36:	ec6e                	sd	s11,24(sp)
ffffffffc0203f38:	892a                	mv	s2,a0
ffffffffc0203f3a:	84ae                	mv	s1,a1
ffffffffc0203f3c:	8d32                	mv	s10,a2
ffffffffc0203f3e:	8ab6                	mv	s5,a3
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0203f40:	5b7d                	li	s6,-1
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203f42:	00002a17          	auipc	s4,0x2
ffffffffc0203f46:	14ea0a13          	addi	s4,s4,334 # ffffffffc0206090 <default_pmm_manager+0xa8>
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203f4a:	05e00b93          	li	s7,94
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203f4e:	00002c17          	auipc	s8,0x2
ffffffffc0203f52:	29ac0c13          	addi	s8,s8,666 # ffffffffc02061e8 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203f56:	000d4503          	lbu	a0,0(s10)
ffffffffc0203f5a:	02500793          	li	a5,37
ffffffffc0203f5e:	001d0413          	addi	s0,s10,1
ffffffffc0203f62:	00f50e63          	beq	a0,a5,ffffffffc0203f7e <vprintfmt+0x62>
            if (ch == '\0') {
ffffffffc0203f66:	c521                	beqz	a0,ffffffffc0203fae <vprintfmt+0x92>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203f68:	02500993          	li	s3,37
ffffffffc0203f6c:	a011                	j	ffffffffc0203f70 <vprintfmt+0x54>
            if (ch == '\0') {
ffffffffc0203f6e:	c121                	beqz	a0,ffffffffc0203fae <vprintfmt+0x92>
            putch(ch, putdat);
ffffffffc0203f70:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203f72:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0203f74:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203f76:	fff44503          	lbu	a0,-1(s0)
ffffffffc0203f7a:	ff351ae3          	bne	a0,s3,ffffffffc0203f6e <vprintfmt+0x52>
ffffffffc0203f7e:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0203f82:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0203f86:	4981                	li	s3,0
ffffffffc0203f88:	4801                	li	a6,0
        width = precision = -1;
ffffffffc0203f8a:	5cfd                	li	s9,-1
ffffffffc0203f8c:	5dfd                	li	s11,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203f8e:	05500593          	li	a1,85
                if (ch < '0' || ch > '9') {
ffffffffc0203f92:	4525                	li	a0,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203f94:	fdd6069b          	addiw	a3,a2,-35
ffffffffc0203f98:	0ff6f693          	andi	a3,a3,255
ffffffffc0203f9c:	00140d13          	addi	s10,s0,1
ffffffffc0203fa0:	1ed5ef63          	bltu	a1,a3,ffffffffc020419e <vprintfmt+0x282>
ffffffffc0203fa4:	068a                	slli	a3,a3,0x2
ffffffffc0203fa6:	96d2                	add	a3,a3,s4
ffffffffc0203fa8:	4294                	lw	a3,0(a3)
ffffffffc0203faa:	96d2                	add	a3,a3,s4
ffffffffc0203fac:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0203fae:	70e6                	ld	ra,120(sp)
ffffffffc0203fb0:	7446                	ld	s0,112(sp)
ffffffffc0203fb2:	74a6                	ld	s1,104(sp)
ffffffffc0203fb4:	7906                	ld	s2,96(sp)
ffffffffc0203fb6:	69e6                	ld	s3,88(sp)
ffffffffc0203fb8:	6a46                	ld	s4,80(sp)
ffffffffc0203fba:	6aa6                	ld	s5,72(sp)
ffffffffc0203fbc:	6b06                	ld	s6,64(sp)
ffffffffc0203fbe:	7be2                	ld	s7,56(sp)
ffffffffc0203fc0:	7c42                	ld	s8,48(sp)
ffffffffc0203fc2:	7ca2                	ld	s9,40(sp)
ffffffffc0203fc4:	7d02                	ld	s10,32(sp)
ffffffffc0203fc6:	6de2                	ld	s11,24(sp)
ffffffffc0203fc8:	6109                	addi	sp,sp,128
ffffffffc0203fca:	8082                	ret
            padc = '-';
ffffffffc0203fcc:	87b2                	mv	a5,a2
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203fce:	00144603          	lbu	a2,1(s0)
ffffffffc0203fd2:	846a                	mv	s0,s10
ffffffffc0203fd4:	b7c1                	j	ffffffffc0203f94 <vprintfmt+0x78>
            precision = va_arg(ap, int);
ffffffffc0203fd6:	000aac83          	lw	s9,0(s5)
            goto process_precision;
ffffffffc0203fda:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0203fde:	0aa1                	addi	s5,s5,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203fe0:	846a                	mv	s0,s10
            if (width < 0)
ffffffffc0203fe2:	fa0dd9e3          	bgez	s11,ffffffffc0203f94 <vprintfmt+0x78>
                width = precision, precision = -1;
ffffffffc0203fe6:	8de6                	mv	s11,s9
ffffffffc0203fe8:	5cfd                	li	s9,-1
ffffffffc0203fea:	b76d                	j	ffffffffc0203f94 <vprintfmt+0x78>
            if (width < 0)
ffffffffc0203fec:	fffdc693          	not	a3,s11
ffffffffc0203ff0:	96fd                	srai	a3,a3,0x3f
ffffffffc0203ff2:	00ddfdb3          	and	s11,s11,a3
ffffffffc0203ff6:	00144603          	lbu	a2,1(s0)
ffffffffc0203ffa:	2d81                	sext.w	s11,s11
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203ffc:	846a                	mv	s0,s10
ffffffffc0203ffe:	bf59                	j	ffffffffc0203f94 <vprintfmt+0x78>
    if (lflag >= 2) {
ffffffffc0204000:	4705                	li	a4,1
ffffffffc0204002:	008a8593          	addi	a1,s5,8
ffffffffc0204006:	01074463          	blt	a4,a6,ffffffffc020400e <vprintfmt+0xf2>
    else if (lflag) {
ffffffffc020400a:	22080863          	beqz	a6,ffffffffc020423a <vprintfmt+0x31e>
        return va_arg(*ap, unsigned long);
ffffffffc020400e:	000ab603          	ld	a2,0(s5)
ffffffffc0204012:	46c1                	li	a3,16
ffffffffc0204014:	8aae                	mv	s5,a1
ffffffffc0204016:	a291                	j	ffffffffc020415a <vprintfmt+0x23e>
                precision = precision * 10 + ch - '0';
ffffffffc0204018:	fd060c9b          	addiw	s9,a2,-48
                ch = *fmt;
ffffffffc020401c:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204020:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0204022:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0204026:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc020402a:	fad56ce3          	bltu	a0,a3,ffffffffc0203fe2 <vprintfmt+0xc6>
            for (precision = 0; ; ++ fmt) {
ffffffffc020402e:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0204030:	002c969b          	slliw	a3,s9,0x2
                ch = *fmt;
ffffffffc0204034:	00044603          	lbu	a2,0(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0204038:	0196873b          	addw	a4,a3,s9
ffffffffc020403c:	0017171b          	slliw	a4,a4,0x1
ffffffffc0204040:	0117073b          	addw	a4,a4,a7
                if (ch < '0' || ch > '9') {
ffffffffc0204044:	fd06069b          	addiw	a3,a2,-48
                precision = precision * 10 + ch - '0';
ffffffffc0204048:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc020404c:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc0204050:	fcd57fe3          	bgeu	a0,a3,ffffffffc020402e <vprintfmt+0x112>
ffffffffc0204054:	b779                	j	ffffffffc0203fe2 <vprintfmt+0xc6>
            putch(va_arg(ap, int), putdat);
ffffffffc0204056:	000aa503          	lw	a0,0(s5)
ffffffffc020405a:	85a6                	mv	a1,s1
ffffffffc020405c:	0aa1                	addi	s5,s5,8
ffffffffc020405e:	9902                	jalr	s2
            break;
ffffffffc0204060:	bddd                	j	ffffffffc0203f56 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0204062:	4705                	li	a4,1
ffffffffc0204064:	008a8993          	addi	s3,s5,8
ffffffffc0204068:	01074463          	blt	a4,a6,ffffffffc0204070 <vprintfmt+0x154>
    else if (lflag) {
ffffffffc020406c:	1c080463          	beqz	a6,ffffffffc0204234 <vprintfmt+0x318>
        return va_arg(*ap, long);
ffffffffc0204070:	000ab403          	ld	s0,0(s5)
            if ((long long)num < 0) {
ffffffffc0204074:	1c044a63          	bltz	s0,ffffffffc0204248 <vprintfmt+0x32c>
            num = getint(&ap, lflag);
ffffffffc0204078:	8622                	mv	a2,s0
ffffffffc020407a:	8ace                	mv	s5,s3
ffffffffc020407c:	46a9                	li	a3,10
ffffffffc020407e:	a8f1                	j	ffffffffc020415a <vprintfmt+0x23e>
            err = va_arg(ap, int);
ffffffffc0204080:	000aa783          	lw	a5,0(s5)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0204084:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0204086:	0aa1                	addi	s5,s5,8
            if (err < 0) {
ffffffffc0204088:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc020408c:	8fb5                	xor	a5,a5,a3
ffffffffc020408e:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0204092:	12d74963          	blt	a4,a3,ffffffffc02041c4 <vprintfmt+0x2a8>
ffffffffc0204096:	00369793          	slli	a5,a3,0x3
ffffffffc020409a:	97e2                	add	a5,a5,s8
ffffffffc020409c:	639c                	ld	a5,0(a5)
ffffffffc020409e:	12078363          	beqz	a5,ffffffffc02041c4 <vprintfmt+0x2a8>
                printfmt(putch, putdat, "%s", p);
ffffffffc02040a2:	86be                	mv	a3,a5
ffffffffc02040a4:	00002617          	auipc	a2,0x2
ffffffffc02040a8:	22c60613          	addi	a2,a2,556 # ffffffffc02062d0 <error_string+0xe8>
ffffffffc02040ac:	85a6                	mv	a1,s1
ffffffffc02040ae:	854a                	mv	a0,s2
ffffffffc02040b0:	1cc000ef          	jal	ra,ffffffffc020427c <printfmt>
ffffffffc02040b4:	b54d                	j	ffffffffc0203f56 <vprintfmt+0x3a>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02040b6:	000ab603          	ld	a2,0(s5)
ffffffffc02040ba:	0aa1                	addi	s5,s5,8
ffffffffc02040bc:	1a060163          	beqz	a2,ffffffffc020425e <vprintfmt+0x342>
            if (width > 0 && padc != '-') {
ffffffffc02040c0:	00160413          	addi	s0,a2,1
ffffffffc02040c4:	15b05763          	blez	s11,ffffffffc0204212 <vprintfmt+0x2f6>
ffffffffc02040c8:	02d00593          	li	a1,45
ffffffffc02040cc:	10b79d63          	bne	a5,a1,ffffffffc02041e6 <vprintfmt+0x2ca>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02040d0:	00064783          	lbu	a5,0(a2)
ffffffffc02040d4:	0007851b          	sext.w	a0,a5
ffffffffc02040d8:	c905                	beqz	a0,ffffffffc0204108 <vprintfmt+0x1ec>
ffffffffc02040da:	000cc563          	bltz	s9,ffffffffc02040e4 <vprintfmt+0x1c8>
ffffffffc02040de:	3cfd                	addiw	s9,s9,-1
ffffffffc02040e0:	036c8263          	beq	s9,s6,ffffffffc0204104 <vprintfmt+0x1e8>
                    putch('?', putdat);
ffffffffc02040e4:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02040e6:	14098f63          	beqz	s3,ffffffffc0204244 <vprintfmt+0x328>
ffffffffc02040ea:	3781                	addiw	a5,a5,-32
ffffffffc02040ec:	14fbfc63          	bgeu	s7,a5,ffffffffc0204244 <vprintfmt+0x328>
                    putch('?', putdat);
ffffffffc02040f0:	03f00513          	li	a0,63
ffffffffc02040f4:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02040f6:	0405                	addi	s0,s0,1
ffffffffc02040f8:	fff44783          	lbu	a5,-1(s0)
ffffffffc02040fc:	3dfd                	addiw	s11,s11,-1
ffffffffc02040fe:	0007851b          	sext.w	a0,a5
ffffffffc0204102:	fd61                	bnez	a0,ffffffffc02040da <vprintfmt+0x1be>
            for (; width > 0; width --) {
ffffffffc0204104:	e5b059e3          	blez	s11,ffffffffc0203f56 <vprintfmt+0x3a>
ffffffffc0204108:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc020410a:	85a6                	mv	a1,s1
ffffffffc020410c:	02000513          	li	a0,32
ffffffffc0204110:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0204112:	e40d82e3          	beqz	s11,ffffffffc0203f56 <vprintfmt+0x3a>
ffffffffc0204116:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0204118:	85a6                	mv	a1,s1
ffffffffc020411a:	02000513          	li	a0,32
ffffffffc020411e:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0204120:	fe0d94e3          	bnez	s11,ffffffffc0204108 <vprintfmt+0x1ec>
ffffffffc0204124:	bd0d                	j	ffffffffc0203f56 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0204126:	4705                	li	a4,1
ffffffffc0204128:	008a8593          	addi	a1,s5,8
ffffffffc020412c:	01074463          	blt	a4,a6,ffffffffc0204134 <vprintfmt+0x218>
    else if (lflag) {
ffffffffc0204130:	0e080863          	beqz	a6,ffffffffc0204220 <vprintfmt+0x304>
        return va_arg(*ap, unsigned long);
ffffffffc0204134:	000ab603          	ld	a2,0(s5)
ffffffffc0204138:	46a1                	li	a3,8
ffffffffc020413a:	8aae                	mv	s5,a1
ffffffffc020413c:	a839                	j	ffffffffc020415a <vprintfmt+0x23e>
            putch('0', putdat);
ffffffffc020413e:	03000513          	li	a0,48
ffffffffc0204142:	85a6                	mv	a1,s1
ffffffffc0204144:	e03e                	sd	a5,0(sp)
ffffffffc0204146:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0204148:	85a6                	mv	a1,s1
ffffffffc020414a:	07800513          	li	a0,120
ffffffffc020414e:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0204150:	0aa1                	addi	s5,s5,8
ffffffffc0204152:	ff8ab603          	ld	a2,-8(s5)
            goto number;
ffffffffc0204156:	6782                	ld	a5,0(sp)
ffffffffc0204158:	46c1                	li	a3,16
            printnum(putch, putdat, num, base, width, padc);
ffffffffc020415a:	2781                	sext.w	a5,a5
ffffffffc020415c:	876e                	mv	a4,s11
ffffffffc020415e:	85a6                	mv	a1,s1
ffffffffc0204160:	854a                	mv	a0,s2
ffffffffc0204162:	d4fff0ef          	jal	ra,ffffffffc0203eb0 <printnum>
            break;
ffffffffc0204166:	bbc5                	j	ffffffffc0203f56 <vprintfmt+0x3a>
            lflag ++;
ffffffffc0204168:	00144603          	lbu	a2,1(s0)
ffffffffc020416c:	2805                	addiw	a6,a6,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020416e:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0204170:	b515                	j	ffffffffc0203f94 <vprintfmt+0x78>
            goto reswitch;
ffffffffc0204172:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0204176:	4985                	li	s3,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204178:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020417a:	bd29                	j	ffffffffc0203f94 <vprintfmt+0x78>
            putch(ch, putdat);
ffffffffc020417c:	85a6                	mv	a1,s1
ffffffffc020417e:	02500513          	li	a0,37
ffffffffc0204182:	9902                	jalr	s2
            break;
ffffffffc0204184:	bbc9                	j	ffffffffc0203f56 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0204186:	4705                	li	a4,1
ffffffffc0204188:	008a8593          	addi	a1,s5,8
ffffffffc020418c:	01074463          	blt	a4,a6,ffffffffc0204194 <vprintfmt+0x278>
    else if (lflag) {
ffffffffc0204190:	08080d63          	beqz	a6,ffffffffc020422a <vprintfmt+0x30e>
        return va_arg(*ap, unsigned long);
ffffffffc0204194:	000ab603          	ld	a2,0(s5)
ffffffffc0204198:	46a9                	li	a3,10
ffffffffc020419a:	8aae                	mv	s5,a1
ffffffffc020419c:	bf7d                	j	ffffffffc020415a <vprintfmt+0x23e>
            putch('%', putdat);
ffffffffc020419e:	85a6                	mv	a1,s1
ffffffffc02041a0:	02500513          	li	a0,37
ffffffffc02041a4:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02041a6:	fff44703          	lbu	a4,-1(s0)
ffffffffc02041aa:	02500793          	li	a5,37
ffffffffc02041ae:	8d22                	mv	s10,s0
ffffffffc02041b0:	daf703e3          	beq	a4,a5,ffffffffc0203f56 <vprintfmt+0x3a>
ffffffffc02041b4:	02500713          	li	a4,37
ffffffffc02041b8:	1d7d                	addi	s10,s10,-1
ffffffffc02041ba:	fffd4783          	lbu	a5,-1(s10)
ffffffffc02041be:	fee79de3          	bne	a5,a4,ffffffffc02041b8 <vprintfmt+0x29c>
ffffffffc02041c2:	bb51                	j	ffffffffc0203f56 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02041c4:	00002617          	auipc	a2,0x2
ffffffffc02041c8:	0fc60613          	addi	a2,a2,252 # ffffffffc02062c0 <error_string+0xd8>
ffffffffc02041cc:	85a6                	mv	a1,s1
ffffffffc02041ce:	854a                	mv	a0,s2
ffffffffc02041d0:	0ac000ef          	jal	ra,ffffffffc020427c <printfmt>
ffffffffc02041d4:	b349                	j	ffffffffc0203f56 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc02041d6:	00002617          	auipc	a2,0x2
ffffffffc02041da:	0e260613          	addi	a2,a2,226 # ffffffffc02062b8 <error_string+0xd0>
            if (width > 0 && padc != '-') {
ffffffffc02041de:	00002417          	auipc	s0,0x2
ffffffffc02041e2:	0db40413          	addi	s0,s0,219 # ffffffffc02062b9 <error_string+0xd1>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02041e6:	8532                	mv	a0,a2
ffffffffc02041e8:	85e6                	mv	a1,s9
ffffffffc02041ea:	e032                	sd	a2,0(sp)
ffffffffc02041ec:	e43e                	sd	a5,8(sp)
ffffffffc02041ee:	c19ff0ef          	jal	ra,ffffffffc0203e06 <strnlen>
ffffffffc02041f2:	40ad8dbb          	subw	s11,s11,a0
ffffffffc02041f6:	6602                	ld	a2,0(sp)
ffffffffc02041f8:	01b05d63          	blez	s11,ffffffffc0204212 <vprintfmt+0x2f6>
ffffffffc02041fc:	67a2                	ld	a5,8(sp)
ffffffffc02041fe:	2781                	sext.w	a5,a5
ffffffffc0204200:	e43e                	sd	a5,8(sp)
                    putch(padc, putdat);
ffffffffc0204202:	6522                	ld	a0,8(sp)
ffffffffc0204204:	85a6                	mv	a1,s1
ffffffffc0204206:	e032                	sd	a2,0(sp)
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0204208:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc020420a:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020420c:	6602                	ld	a2,0(sp)
ffffffffc020420e:	fe0d9ae3          	bnez	s11,ffffffffc0204202 <vprintfmt+0x2e6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204212:	00064783          	lbu	a5,0(a2)
ffffffffc0204216:	0007851b          	sext.w	a0,a5
ffffffffc020421a:	ec0510e3          	bnez	a0,ffffffffc02040da <vprintfmt+0x1be>
ffffffffc020421e:	bb25                	j	ffffffffc0203f56 <vprintfmt+0x3a>
        return va_arg(*ap, unsigned int);
ffffffffc0204220:	000ae603          	lwu	a2,0(s5)
ffffffffc0204224:	46a1                	li	a3,8
ffffffffc0204226:	8aae                	mv	s5,a1
ffffffffc0204228:	bf0d                	j	ffffffffc020415a <vprintfmt+0x23e>
ffffffffc020422a:	000ae603          	lwu	a2,0(s5)
ffffffffc020422e:	46a9                	li	a3,10
ffffffffc0204230:	8aae                	mv	s5,a1
ffffffffc0204232:	b725                	j	ffffffffc020415a <vprintfmt+0x23e>
        return va_arg(*ap, int);
ffffffffc0204234:	000aa403          	lw	s0,0(s5)
ffffffffc0204238:	bd35                	j	ffffffffc0204074 <vprintfmt+0x158>
        return va_arg(*ap, unsigned int);
ffffffffc020423a:	000ae603          	lwu	a2,0(s5)
ffffffffc020423e:	46c1                	li	a3,16
ffffffffc0204240:	8aae                	mv	s5,a1
ffffffffc0204242:	bf21                	j	ffffffffc020415a <vprintfmt+0x23e>
                    putch(ch, putdat);
ffffffffc0204244:	9902                	jalr	s2
ffffffffc0204246:	bd45                	j	ffffffffc02040f6 <vprintfmt+0x1da>
                putch('-', putdat);
ffffffffc0204248:	85a6                	mv	a1,s1
ffffffffc020424a:	02d00513          	li	a0,45
ffffffffc020424e:	e03e                	sd	a5,0(sp)
ffffffffc0204250:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0204252:	8ace                	mv	s5,s3
ffffffffc0204254:	40800633          	neg	a2,s0
ffffffffc0204258:	46a9                	li	a3,10
ffffffffc020425a:	6782                	ld	a5,0(sp)
ffffffffc020425c:	bdfd                	j	ffffffffc020415a <vprintfmt+0x23e>
            if (width > 0 && padc != '-') {
ffffffffc020425e:	01b05663          	blez	s11,ffffffffc020426a <vprintfmt+0x34e>
ffffffffc0204262:	02d00693          	li	a3,45
ffffffffc0204266:	f6d798e3          	bne	a5,a3,ffffffffc02041d6 <vprintfmt+0x2ba>
ffffffffc020426a:	00002417          	auipc	s0,0x2
ffffffffc020426e:	04f40413          	addi	s0,s0,79 # ffffffffc02062b9 <error_string+0xd1>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204272:	02800513          	li	a0,40
ffffffffc0204276:	02800793          	li	a5,40
ffffffffc020427a:	b585                	j	ffffffffc02040da <vprintfmt+0x1be>

ffffffffc020427c <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020427c:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc020427e:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0204282:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0204284:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0204286:	ec06                	sd	ra,24(sp)
ffffffffc0204288:	f83a                	sd	a4,48(sp)
ffffffffc020428a:	fc3e                	sd	a5,56(sp)
ffffffffc020428c:	e0c2                	sd	a6,64(sp)
ffffffffc020428e:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0204290:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0204292:	c8bff0ef          	jal	ra,ffffffffc0203f1c <vprintfmt>
}
ffffffffc0204296:	60e2                	ld	ra,24(sp)
ffffffffc0204298:	6161                	addi	sp,sp,80
ffffffffc020429a:	8082                	ret

ffffffffc020429c <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc020429c:	715d                	addi	sp,sp,-80
ffffffffc020429e:	e486                	sd	ra,72(sp)
ffffffffc02042a0:	e0a2                	sd	s0,64(sp)
ffffffffc02042a2:	fc26                	sd	s1,56(sp)
ffffffffc02042a4:	f84a                	sd	s2,48(sp)
ffffffffc02042a6:	f44e                	sd	s3,40(sp)
ffffffffc02042a8:	f052                	sd	s4,32(sp)
ffffffffc02042aa:	ec56                	sd	s5,24(sp)
ffffffffc02042ac:	e85a                	sd	s6,16(sp)
ffffffffc02042ae:	e45e                	sd	s7,8(sp)
    if (prompt != NULL) {
ffffffffc02042b0:	c901                	beqz	a0,ffffffffc02042c0 <readline+0x24>
        cprintf("%s", prompt);
ffffffffc02042b2:	85aa                	mv	a1,a0
ffffffffc02042b4:	00002517          	auipc	a0,0x2
ffffffffc02042b8:	01c50513          	addi	a0,a0,28 # ffffffffc02062d0 <error_string+0xe8>
ffffffffc02042bc:	e03fb0ef          	jal	ra,ffffffffc02000be <cprintf>
readline(const char *prompt) {
ffffffffc02042c0:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02042c2:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02042c4:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02042c6:	4aa9                	li	s5,10
ffffffffc02042c8:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02042ca:	0000db97          	auipc	s7,0xd
ffffffffc02042ce:	d76b8b93          	addi	s7,s7,-650 # ffffffffc0211040 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02042d2:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02042d6:	e1ffb0ef          	jal	ra,ffffffffc02000f4 <getchar>
ffffffffc02042da:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc02042dc:	00054b63          	bltz	a0,ffffffffc02042f2 <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02042e0:	00a95b63          	bge	s2,a0,ffffffffc02042f6 <readline+0x5a>
ffffffffc02042e4:	029a5463          	bge	s4,s1,ffffffffc020430c <readline+0x70>
        c = getchar();
ffffffffc02042e8:	e0dfb0ef          	jal	ra,ffffffffc02000f4 <getchar>
ffffffffc02042ec:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc02042ee:	fe0559e3          	bgez	a0,ffffffffc02042e0 <readline+0x44>
            return NULL;
ffffffffc02042f2:	4501                	li	a0,0
ffffffffc02042f4:	a099                	j	ffffffffc020433a <readline+0x9e>
        else if (c == '\b' && i > 0) {
ffffffffc02042f6:	03341463          	bne	s0,s3,ffffffffc020431e <readline+0x82>
ffffffffc02042fa:	e8b9                	bnez	s1,ffffffffc0204350 <readline+0xb4>
        c = getchar();
ffffffffc02042fc:	df9fb0ef          	jal	ra,ffffffffc02000f4 <getchar>
ffffffffc0204300:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0204302:	fe0548e3          	bltz	a0,ffffffffc02042f2 <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0204306:	fea958e3          	bge	s2,a0,ffffffffc02042f6 <readline+0x5a>
ffffffffc020430a:	4481                	li	s1,0
            cputchar(c);
ffffffffc020430c:	8522                	mv	a0,s0
ffffffffc020430e:	de5fb0ef          	jal	ra,ffffffffc02000f2 <cputchar>
            buf[i ++] = c;
ffffffffc0204312:	009b87b3          	add	a5,s7,s1
ffffffffc0204316:	00878023          	sb	s0,0(a5)
ffffffffc020431a:	2485                	addiw	s1,s1,1
ffffffffc020431c:	bf6d                	j	ffffffffc02042d6 <readline+0x3a>
        else if (c == '\n' || c == '\r') {
ffffffffc020431e:	01540463          	beq	s0,s5,ffffffffc0204326 <readline+0x8a>
ffffffffc0204322:	fb641ae3          	bne	s0,s6,ffffffffc02042d6 <readline+0x3a>
            cputchar(c);
ffffffffc0204326:	8522                	mv	a0,s0
ffffffffc0204328:	dcbfb0ef          	jal	ra,ffffffffc02000f2 <cputchar>
            buf[i] = '\0';
ffffffffc020432c:	0000d517          	auipc	a0,0xd
ffffffffc0204330:	d1450513          	addi	a0,a0,-748 # ffffffffc0211040 <buf>
ffffffffc0204334:	94aa                	add	s1,s1,a0
ffffffffc0204336:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc020433a:	60a6                	ld	ra,72(sp)
ffffffffc020433c:	6406                	ld	s0,64(sp)
ffffffffc020433e:	74e2                	ld	s1,56(sp)
ffffffffc0204340:	7942                	ld	s2,48(sp)
ffffffffc0204342:	79a2                	ld	s3,40(sp)
ffffffffc0204344:	7a02                	ld	s4,32(sp)
ffffffffc0204346:	6ae2                	ld	s5,24(sp)
ffffffffc0204348:	6b42                	ld	s6,16(sp)
ffffffffc020434a:	6ba2                	ld	s7,8(sp)
ffffffffc020434c:	6161                	addi	sp,sp,80
ffffffffc020434e:	8082                	ret
            cputchar(c);
ffffffffc0204350:	4521                	li	a0,8
ffffffffc0204352:	da1fb0ef          	jal	ra,ffffffffc02000f2 <cputchar>
            i --;
ffffffffc0204356:	34fd                	addiw	s1,s1,-1
ffffffffc0204358:	bfbd                	j	ffffffffc02042d6 <readline+0x3a>
