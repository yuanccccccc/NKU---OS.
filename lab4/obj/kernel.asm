
bin/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c020a2b7          	lui	t0,0xc020a
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
ffffffffc0200028:	c020a137          	lui	sp,0xc020a

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc020002c:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200030:	03628293          	addi	t0,t0,54 # ffffffffc0200036 <kern_init>
    jr t0
ffffffffc0200034:	8282                	jr	t0

ffffffffc0200036 <kern_init>:
void grade_backtrace(void);

int kern_init(void)
{
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200036:	0000b517          	auipc	a0,0xb
ffffffffc020003a:	02a50513          	addi	a0,a0,42 # ffffffffc020b060 <edata>
ffffffffc020003e:	00016617          	auipc	a2,0x16
ffffffffc0200042:	5c260613          	addi	a2,a2,1474 # ffffffffc0216600 <end>
{
ffffffffc0200046:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200048:	8e09                	sub	a2,a2,a0
ffffffffc020004a:	4581                	li	a1,0
{
ffffffffc020004c:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004e:	1fd040ef          	jal	ra,ffffffffc0204a4a <memset>

    cons_init(); // init the console
ffffffffc0200052:	506000ef          	jal	ra,ffffffffc0200558 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc0200056:	00005597          	auipc	a1,0x5
ffffffffc020005a:	e5258593          	addi	a1,a1,-430 # ffffffffc0204ea8 <etext>
ffffffffc020005e:	00005517          	auipc	a0,0x5
ffffffffc0200062:	e6a50513          	addi	a0,a0,-406 # ffffffffc0204ec8 <etext+0x20>
ffffffffc0200066:	06a000ef          	jal	ra,ffffffffc02000d0 <cprintf>

    print_kerninfo();
ffffffffc020006a:	1ca000ef          	jal	ra,ffffffffc0200234 <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc020006e:	7a3000ef          	jal	ra,ffffffffc0201010 <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc0200072:	558000ef          	jal	ra,ffffffffc02005ca <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc0200076:	5d4000ef          	jal	ra,ffffffffc020064a <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc020007a:	084020ef          	jal	ra,ffffffffc02020fe <vmm_init>
    proc_init(); // init process table
ffffffffc020007e:	654040ef          	jal	ra,ffffffffc02046d2 <proc_init>

    ide_init();  // init ide devices
ffffffffc0200082:	42a000ef          	jal	ra,ffffffffc02004ac <ide_init>
    swap_init(); // init swap
ffffffffc0200086:	321020ef          	jal	ra,ffffffffc0202ba6 <swap_init>

    clock_init();  // init clock interrupt
ffffffffc020008a:	47a000ef          	jal	ra,ffffffffc0200504 <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020008e:	53e000ef          	jal	ra,ffffffffc02005cc <intr_enable>

    cpu_idle(); // run idle process
ffffffffc0200092:	033040ef          	jal	ra,ffffffffc02048c4 <cpu_idle>

ffffffffc0200096 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200096:	1141                	addi	sp,sp,-16
ffffffffc0200098:	e022                	sd	s0,0(sp)
ffffffffc020009a:	e406                	sd	ra,8(sp)
ffffffffc020009c:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020009e:	4bc000ef          	jal	ra,ffffffffc020055a <cons_putc>
    (*cnt) ++;
ffffffffc02000a2:	401c                	lw	a5,0(s0)
}
ffffffffc02000a4:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc02000a6:	2785                	addiw	a5,a5,1
ffffffffc02000a8:	c01c                	sw	a5,0(s0)
}
ffffffffc02000aa:	6402                	ld	s0,0(sp)
ffffffffc02000ac:	0141                	addi	sp,sp,16
ffffffffc02000ae:	8082                	ret

ffffffffc02000b0 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000b0:	1101                	addi	sp,sp,-32
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000b2:	86ae                	mv	a3,a1
ffffffffc02000b4:	862a                	mv	a2,a0
ffffffffc02000b6:	006c                	addi	a1,sp,12
ffffffffc02000b8:	00000517          	auipc	a0,0x0
ffffffffc02000bc:	fde50513          	addi	a0,a0,-34 # ffffffffc0200096 <cputch>
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000c0:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000c2:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000c4:	24d040ef          	jal	ra,ffffffffc0204b10 <vprintfmt>
    return cnt;
}
ffffffffc02000c8:	60e2                	ld	ra,24(sp)
ffffffffc02000ca:	4532                	lw	a0,12(sp)
ffffffffc02000cc:	6105                	addi	sp,sp,32
ffffffffc02000ce:	8082                	ret

ffffffffc02000d0 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000d0:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000d2:	02810313          	addi	t1,sp,40 # ffffffffc020a028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000d6:	f42e                	sd	a1,40(sp)
ffffffffc02000d8:	f832                	sd	a2,48(sp)
ffffffffc02000da:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000dc:	862a                	mv	a2,a0
ffffffffc02000de:	004c                	addi	a1,sp,4
ffffffffc02000e0:	00000517          	auipc	a0,0x0
ffffffffc02000e4:	fb650513          	addi	a0,a0,-74 # ffffffffc0200096 <cputch>
ffffffffc02000e8:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc02000ea:	ec06                	sd	ra,24(sp)
ffffffffc02000ec:	e0ba                	sd	a4,64(sp)
ffffffffc02000ee:	e4be                	sd	a5,72(sp)
ffffffffc02000f0:	e8c2                	sd	a6,80(sp)
ffffffffc02000f2:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000f4:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000f6:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000f8:	219040ef          	jal	ra,ffffffffc0204b10 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02000fc:	60e2                	ld	ra,24(sp)
ffffffffc02000fe:	4512                	lw	a0,4(sp)
ffffffffc0200100:	6125                	addi	sp,sp,96
ffffffffc0200102:	8082                	ret

ffffffffc0200104 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc0200104:	a999                	j	ffffffffc020055a <cons_putc>

ffffffffc0200106 <getchar>:
    return cnt;
}

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc0200106:	1141                	addi	sp,sp,-16
ffffffffc0200108:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020010a:	484000ef          	jal	ra,ffffffffc020058e <cons_getc>
ffffffffc020010e:	dd75                	beqz	a0,ffffffffc020010a <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200110:	60a2                	ld	ra,8(sp)
ffffffffc0200112:	0141                	addi	sp,sp,16
ffffffffc0200114:	8082                	ret

ffffffffc0200116 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0200116:	715d                	addi	sp,sp,-80
ffffffffc0200118:	e486                	sd	ra,72(sp)
ffffffffc020011a:	e0a2                	sd	s0,64(sp)
ffffffffc020011c:	fc26                	sd	s1,56(sp)
ffffffffc020011e:	f84a                	sd	s2,48(sp)
ffffffffc0200120:	f44e                	sd	s3,40(sp)
ffffffffc0200122:	f052                	sd	s4,32(sp)
ffffffffc0200124:	ec56                	sd	s5,24(sp)
ffffffffc0200126:	e85a                	sd	s6,16(sp)
ffffffffc0200128:	e45e                	sd	s7,8(sp)
    if (prompt != NULL) {
ffffffffc020012a:	c901                	beqz	a0,ffffffffc020013a <readline+0x24>
        cprintf("%s", prompt);
ffffffffc020012c:	85aa                	mv	a1,a0
ffffffffc020012e:	00005517          	auipc	a0,0x5
ffffffffc0200132:	da250513          	addi	a0,a0,-606 # ffffffffc0204ed0 <etext+0x28>
ffffffffc0200136:	f9bff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
readline(const char *prompt) {
ffffffffc020013a:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020013c:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc020013e:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0200140:	4aa9                	li	s5,10
ffffffffc0200142:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0200144:	0000bb97          	auipc	s7,0xb
ffffffffc0200148:	f1cb8b93          	addi	s7,s7,-228 # ffffffffc020b060 <edata>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020014c:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0200150:	fb7ff0ef          	jal	ra,ffffffffc0200106 <getchar>
ffffffffc0200154:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0200156:	00054b63          	bltz	a0,ffffffffc020016c <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020015a:	00a95b63          	bge	s2,a0,ffffffffc0200170 <readline+0x5a>
ffffffffc020015e:	029a5463          	bge	s4,s1,ffffffffc0200186 <readline+0x70>
        c = getchar();
ffffffffc0200162:	fa5ff0ef          	jal	ra,ffffffffc0200106 <getchar>
ffffffffc0200166:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0200168:	fe0559e3          	bgez	a0,ffffffffc020015a <readline+0x44>
            return NULL;
ffffffffc020016c:	4501                	li	a0,0
ffffffffc020016e:	a099                	j	ffffffffc02001b4 <readline+0x9e>
        else if (c == '\b' && i > 0) {
ffffffffc0200170:	03341463          	bne	s0,s3,ffffffffc0200198 <readline+0x82>
ffffffffc0200174:	e8b9                	bnez	s1,ffffffffc02001ca <readline+0xb4>
        c = getchar();
ffffffffc0200176:	f91ff0ef          	jal	ra,ffffffffc0200106 <getchar>
ffffffffc020017a:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc020017c:	fe0548e3          	bltz	a0,ffffffffc020016c <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200180:	fea958e3          	bge	s2,a0,ffffffffc0200170 <readline+0x5a>
ffffffffc0200184:	4481                	li	s1,0
            cputchar(c);
ffffffffc0200186:	8522                	mv	a0,s0
ffffffffc0200188:	f7dff0ef          	jal	ra,ffffffffc0200104 <cputchar>
            buf[i ++] = c;
ffffffffc020018c:	009b87b3          	add	a5,s7,s1
ffffffffc0200190:	00878023          	sb	s0,0(a5)
ffffffffc0200194:	2485                	addiw	s1,s1,1
ffffffffc0200196:	bf6d                	j	ffffffffc0200150 <readline+0x3a>
        else if (c == '\n' || c == '\r') {
ffffffffc0200198:	01540463          	beq	s0,s5,ffffffffc02001a0 <readline+0x8a>
ffffffffc020019c:	fb641ae3          	bne	s0,s6,ffffffffc0200150 <readline+0x3a>
            cputchar(c);
ffffffffc02001a0:	8522                	mv	a0,s0
ffffffffc02001a2:	f63ff0ef          	jal	ra,ffffffffc0200104 <cputchar>
            buf[i] = '\0';
ffffffffc02001a6:	0000b517          	auipc	a0,0xb
ffffffffc02001aa:	eba50513          	addi	a0,a0,-326 # ffffffffc020b060 <edata>
ffffffffc02001ae:	94aa                	add	s1,s1,a0
ffffffffc02001b0:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc02001b4:	60a6                	ld	ra,72(sp)
ffffffffc02001b6:	6406                	ld	s0,64(sp)
ffffffffc02001b8:	74e2                	ld	s1,56(sp)
ffffffffc02001ba:	7942                	ld	s2,48(sp)
ffffffffc02001bc:	79a2                	ld	s3,40(sp)
ffffffffc02001be:	7a02                	ld	s4,32(sp)
ffffffffc02001c0:	6ae2                	ld	s5,24(sp)
ffffffffc02001c2:	6b42                	ld	s6,16(sp)
ffffffffc02001c4:	6ba2                	ld	s7,8(sp)
ffffffffc02001c6:	6161                	addi	sp,sp,80
ffffffffc02001c8:	8082                	ret
            cputchar(c);
ffffffffc02001ca:	4521                	li	a0,8
ffffffffc02001cc:	f39ff0ef          	jal	ra,ffffffffc0200104 <cputchar>
            i --;
ffffffffc02001d0:	34fd                	addiw	s1,s1,-1
ffffffffc02001d2:	bfbd                	j	ffffffffc0200150 <readline+0x3a>

ffffffffc02001d4 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001d4:	00016317          	auipc	t1,0x16
ffffffffc02001d8:	29c30313          	addi	t1,t1,668 # ffffffffc0216470 <is_panic>
ffffffffc02001dc:	00032303          	lw	t1,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001e0:	715d                	addi	sp,sp,-80
ffffffffc02001e2:	ec06                	sd	ra,24(sp)
ffffffffc02001e4:	e822                	sd	s0,16(sp)
ffffffffc02001e6:	f436                	sd	a3,40(sp)
ffffffffc02001e8:	f83a                	sd	a4,48(sp)
ffffffffc02001ea:	fc3e                	sd	a5,56(sp)
ffffffffc02001ec:	e0c2                	sd	a6,64(sp)
ffffffffc02001ee:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001f0:	02031c63          	bnez	t1,ffffffffc0200228 <__panic+0x54>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02001f4:	4785                	li	a5,1
ffffffffc02001f6:	8432                	mv	s0,a2
ffffffffc02001f8:	00016717          	auipc	a4,0x16
ffffffffc02001fc:	26f72c23          	sw	a5,632(a4) # ffffffffc0216470 <is_panic>

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200200:	862e                	mv	a2,a1
    va_start(ap, fmt);
ffffffffc0200202:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200204:	85aa                	mv	a1,a0
ffffffffc0200206:	00005517          	auipc	a0,0x5
ffffffffc020020a:	cd250513          	addi	a0,a0,-814 # ffffffffc0204ed8 <etext+0x30>
    va_start(ap, fmt);
ffffffffc020020e:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200210:	ec1ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200214:	65a2                	ld	a1,8(sp)
ffffffffc0200216:	8522                	mv	a0,s0
ffffffffc0200218:	e99ff0ef          	jal	ra,ffffffffc02000b0 <vcprintf>
    cprintf("\n");
ffffffffc020021c:	00006517          	auipc	a0,0x6
ffffffffc0200220:	a7450513          	addi	a0,a0,-1420 # ffffffffc0205c90 <commands+0xc98>
ffffffffc0200224:	eadff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc0200228:	3aa000ef          	jal	ra,ffffffffc02005d2 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc020022c:	4501                	li	a0,0
ffffffffc020022e:	130000ef          	jal	ra,ffffffffc020035e <kmonitor>
ffffffffc0200232:	bfed                	j	ffffffffc020022c <__panic+0x58>

ffffffffc0200234 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200234:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200236:	00005517          	auipc	a0,0x5
ffffffffc020023a:	cf250513          	addi	a0,a0,-782 # ffffffffc0204f28 <etext+0x80>
void print_kerninfo(void) {
ffffffffc020023e:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200240:	e91ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc0200244:	00000597          	auipc	a1,0x0
ffffffffc0200248:	df258593          	addi	a1,a1,-526 # ffffffffc0200036 <kern_init>
ffffffffc020024c:	00005517          	auipc	a0,0x5
ffffffffc0200250:	cfc50513          	addi	a0,a0,-772 # ffffffffc0204f48 <etext+0xa0>
ffffffffc0200254:	e7dff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200258:	00005597          	auipc	a1,0x5
ffffffffc020025c:	c5058593          	addi	a1,a1,-944 # ffffffffc0204ea8 <etext>
ffffffffc0200260:	00005517          	auipc	a0,0x5
ffffffffc0200264:	d0850513          	addi	a0,a0,-760 # ffffffffc0204f68 <etext+0xc0>
ffffffffc0200268:	e69ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc020026c:	0000b597          	auipc	a1,0xb
ffffffffc0200270:	df458593          	addi	a1,a1,-524 # ffffffffc020b060 <edata>
ffffffffc0200274:	00005517          	auipc	a0,0x5
ffffffffc0200278:	d1450513          	addi	a0,a0,-748 # ffffffffc0204f88 <etext+0xe0>
ffffffffc020027c:	e55ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200280:	00016597          	auipc	a1,0x16
ffffffffc0200284:	38058593          	addi	a1,a1,896 # ffffffffc0216600 <end>
ffffffffc0200288:	00005517          	auipc	a0,0x5
ffffffffc020028c:	d2050513          	addi	a0,a0,-736 # ffffffffc0204fa8 <etext+0x100>
ffffffffc0200290:	e41ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200294:	00016597          	auipc	a1,0x16
ffffffffc0200298:	76b58593          	addi	a1,a1,1899 # ffffffffc02169ff <end+0x3ff>
ffffffffc020029c:	00000797          	auipc	a5,0x0
ffffffffc02002a0:	d9a78793          	addi	a5,a5,-614 # ffffffffc0200036 <kern_init>
ffffffffc02002a4:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002a8:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02002ac:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002ae:	3ff5f593          	andi	a1,a1,1023
ffffffffc02002b2:	95be                	add	a1,a1,a5
ffffffffc02002b4:	85a9                	srai	a1,a1,0xa
ffffffffc02002b6:	00005517          	auipc	a0,0x5
ffffffffc02002ba:	d1250513          	addi	a0,a0,-750 # ffffffffc0204fc8 <etext+0x120>
}
ffffffffc02002be:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002c0:	bd01                	j	ffffffffc02000d0 <cprintf>

ffffffffc02002c2 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02002c2:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02002c4:	00005617          	auipc	a2,0x5
ffffffffc02002c8:	c3460613          	addi	a2,a2,-972 # ffffffffc0204ef8 <etext+0x50>
ffffffffc02002cc:	04d00593          	li	a1,77
ffffffffc02002d0:	00005517          	auipc	a0,0x5
ffffffffc02002d4:	c4050513          	addi	a0,a0,-960 # ffffffffc0204f10 <etext+0x68>
void print_stackframe(void) {
ffffffffc02002d8:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002da:	efbff0ef          	jal	ra,ffffffffc02001d4 <__panic>

ffffffffc02002de <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002de:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e0:	00005617          	auipc	a2,0x5
ffffffffc02002e4:	df860613          	addi	a2,a2,-520 # ffffffffc02050d8 <commands+0xe0>
ffffffffc02002e8:	00005597          	auipc	a1,0x5
ffffffffc02002ec:	e1058593          	addi	a1,a1,-496 # ffffffffc02050f8 <commands+0x100>
ffffffffc02002f0:	00005517          	auipc	a0,0x5
ffffffffc02002f4:	e1050513          	addi	a0,a0,-496 # ffffffffc0205100 <commands+0x108>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002f8:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002fa:	dd7ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
ffffffffc02002fe:	00005617          	auipc	a2,0x5
ffffffffc0200302:	e1260613          	addi	a2,a2,-494 # ffffffffc0205110 <commands+0x118>
ffffffffc0200306:	00005597          	auipc	a1,0x5
ffffffffc020030a:	e3258593          	addi	a1,a1,-462 # ffffffffc0205138 <commands+0x140>
ffffffffc020030e:	00005517          	auipc	a0,0x5
ffffffffc0200312:	df250513          	addi	a0,a0,-526 # ffffffffc0205100 <commands+0x108>
ffffffffc0200316:	dbbff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
ffffffffc020031a:	00005617          	auipc	a2,0x5
ffffffffc020031e:	e2e60613          	addi	a2,a2,-466 # ffffffffc0205148 <commands+0x150>
ffffffffc0200322:	00005597          	auipc	a1,0x5
ffffffffc0200326:	e4658593          	addi	a1,a1,-442 # ffffffffc0205168 <commands+0x170>
ffffffffc020032a:	00005517          	auipc	a0,0x5
ffffffffc020032e:	dd650513          	addi	a0,a0,-554 # ffffffffc0205100 <commands+0x108>
ffffffffc0200332:	d9fff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    }
    return 0;
}
ffffffffc0200336:	60a2                	ld	ra,8(sp)
ffffffffc0200338:	4501                	li	a0,0
ffffffffc020033a:	0141                	addi	sp,sp,16
ffffffffc020033c:	8082                	ret

ffffffffc020033e <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc020033e:	1141                	addi	sp,sp,-16
ffffffffc0200340:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200342:	ef3ff0ef          	jal	ra,ffffffffc0200234 <print_kerninfo>
    return 0;
}
ffffffffc0200346:	60a2                	ld	ra,8(sp)
ffffffffc0200348:	4501                	li	a0,0
ffffffffc020034a:	0141                	addi	sp,sp,16
ffffffffc020034c:	8082                	ret

ffffffffc020034e <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc020034e:	1141                	addi	sp,sp,-16
ffffffffc0200350:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200352:	f71ff0ef          	jal	ra,ffffffffc02002c2 <print_stackframe>
    return 0;
}
ffffffffc0200356:	60a2                	ld	ra,8(sp)
ffffffffc0200358:	4501                	li	a0,0
ffffffffc020035a:	0141                	addi	sp,sp,16
ffffffffc020035c:	8082                	ret

ffffffffc020035e <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc020035e:	7115                	addi	sp,sp,-224
ffffffffc0200360:	e962                	sd	s8,144(sp)
ffffffffc0200362:	8c2a                	mv	s8,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200364:	00005517          	auipc	a0,0x5
ffffffffc0200368:	cdc50513          	addi	a0,a0,-804 # ffffffffc0205040 <commands+0x48>
kmonitor(struct trapframe *tf) {
ffffffffc020036c:	ed86                	sd	ra,216(sp)
ffffffffc020036e:	e9a2                	sd	s0,208(sp)
ffffffffc0200370:	e5a6                	sd	s1,200(sp)
ffffffffc0200372:	e1ca                	sd	s2,192(sp)
ffffffffc0200374:	fd4e                	sd	s3,184(sp)
ffffffffc0200376:	f952                	sd	s4,176(sp)
ffffffffc0200378:	f556                	sd	s5,168(sp)
ffffffffc020037a:	f15a                	sd	s6,160(sp)
ffffffffc020037c:	ed5e                	sd	s7,152(sp)
ffffffffc020037e:	e566                	sd	s9,136(sp)
ffffffffc0200380:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200382:	d4fff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200386:	00005517          	auipc	a0,0x5
ffffffffc020038a:	ce250513          	addi	a0,a0,-798 # ffffffffc0205068 <commands+0x70>
ffffffffc020038e:	d43ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    if (tf != NULL) {
ffffffffc0200392:	000c0563          	beqz	s8,ffffffffc020039c <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc0200396:	8562                	mv	a0,s8
ffffffffc0200398:	49a000ef          	jal	ra,ffffffffc0200832 <print_trapframe>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc020039c:	4501                	li	a0,0
ffffffffc020039e:	4581                	li	a1,0
ffffffffc02003a0:	4601                	li	a2,0
ffffffffc02003a2:	48a1                	li	a7,8
ffffffffc02003a4:	00000073          	ecall
ffffffffc02003a8:	00005c97          	auipc	s9,0x5
ffffffffc02003ac:	c50c8c93          	addi	s9,s9,-944 # ffffffffc0204ff8 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02003b0:	00005997          	auipc	s3,0x5
ffffffffc02003b4:	ce098993          	addi	s3,s3,-800 # ffffffffc0205090 <commands+0x98>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003b8:	00005917          	auipc	s2,0x5
ffffffffc02003bc:	ce090913          	addi	s2,s2,-800 # ffffffffc0205098 <commands+0xa0>
        if (argc == MAXARGS - 1) {
ffffffffc02003c0:	4a3d                	li	s4,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003c2:	00005b17          	auipc	s6,0x5
ffffffffc02003c6:	cdeb0b13          	addi	s6,s6,-802 # ffffffffc02050a0 <commands+0xa8>
    if (argc == 0) {
ffffffffc02003ca:	00005a97          	auipc	s5,0x5
ffffffffc02003ce:	d2ea8a93          	addi	s5,s5,-722 # ffffffffc02050f8 <commands+0x100>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003d2:	4b8d                	li	s7,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02003d4:	854e                	mv	a0,s3
ffffffffc02003d6:	d41ff0ef          	jal	ra,ffffffffc0200116 <readline>
ffffffffc02003da:	842a                	mv	s0,a0
ffffffffc02003dc:	dd65                	beqz	a0,ffffffffc02003d4 <kmonitor+0x76>
ffffffffc02003de:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02003e2:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003e4:	c999                	beqz	a1,ffffffffc02003fa <kmonitor+0x9c>
ffffffffc02003e6:	854a                	mv	a0,s2
ffffffffc02003e8:	644040ef          	jal	ra,ffffffffc0204a2c <strchr>
ffffffffc02003ec:	c925                	beqz	a0,ffffffffc020045c <kmonitor+0xfe>
            *buf ++ = '\0';
ffffffffc02003ee:	00144583          	lbu	a1,1(s0)
ffffffffc02003f2:	00040023          	sb	zero,0(s0)
ffffffffc02003f6:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003f8:	f5fd                	bnez	a1,ffffffffc02003e6 <kmonitor+0x88>
    if (argc == 0) {
ffffffffc02003fa:	dce9                	beqz	s1,ffffffffc02003d4 <kmonitor+0x76>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003fc:	6582                	ld	a1,0(sp)
ffffffffc02003fe:	00005d17          	auipc	s10,0x5
ffffffffc0200402:	bfad0d13          	addi	s10,s10,-1030 # ffffffffc0204ff8 <commands>
    if (argc == 0) {
ffffffffc0200406:	8556                	mv	a0,s5
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200408:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020040a:	0d61                	addi	s10,s10,24
ffffffffc020040c:	5f6040ef          	jal	ra,ffffffffc0204a02 <strcmp>
ffffffffc0200410:	c919                	beqz	a0,ffffffffc0200426 <kmonitor+0xc8>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200412:	2405                	addiw	s0,s0,1
ffffffffc0200414:	09740463          	beq	s0,s7,ffffffffc020049c <kmonitor+0x13e>
ffffffffc0200418:	000d3503          	ld	a0,0(s10)
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020041c:	6582                	ld	a1,0(sp)
ffffffffc020041e:	0d61                	addi	s10,s10,24
ffffffffc0200420:	5e2040ef          	jal	ra,ffffffffc0204a02 <strcmp>
ffffffffc0200424:	f57d                	bnez	a0,ffffffffc0200412 <kmonitor+0xb4>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200426:	00141793          	slli	a5,s0,0x1
ffffffffc020042a:	97a2                	add	a5,a5,s0
ffffffffc020042c:	078e                	slli	a5,a5,0x3
ffffffffc020042e:	97e6                	add	a5,a5,s9
ffffffffc0200430:	6b9c                	ld	a5,16(a5)
ffffffffc0200432:	8662                	mv	a2,s8
ffffffffc0200434:	002c                	addi	a1,sp,8
ffffffffc0200436:	fff4851b          	addiw	a0,s1,-1
ffffffffc020043a:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc020043c:	f8055ce3          	bgez	a0,ffffffffc02003d4 <kmonitor+0x76>
}
ffffffffc0200440:	60ee                	ld	ra,216(sp)
ffffffffc0200442:	644e                	ld	s0,208(sp)
ffffffffc0200444:	64ae                	ld	s1,200(sp)
ffffffffc0200446:	690e                	ld	s2,192(sp)
ffffffffc0200448:	79ea                	ld	s3,184(sp)
ffffffffc020044a:	7a4a                	ld	s4,176(sp)
ffffffffc020044c:	7aaa                	ld	s5,168(sp)
ffffffffc020044e:	7b0a                	ld	s6,160(sp)
ffffffffc0200450:	6bea                	ld	s7,152(sp)
ffffffffc0200452:	6c4a                	ld	s8,144(sp)
ffffffffc0200454:	6caa                	ld	s9,136(sp)
ffffffffc0200456:	6d0a                	ld	s10,128(sp)
ffffffffc0200458:	612d                	addi	sp,sp,224
ffffffffc020045a:	8082                	ret
        if (*buf == '\0') {
ffffffffc020045c:	00044783          	lbu	a5,0(s0)
ffffffffc0200460:	dfc9                	beqz	a5,ffffffffc02003fa <kmonitor+0x9c>
        if (argc == MAXARGS - 1) {
ffffffffc0200462:	03448863          	beq	s1,s4,ffffffffc0200492 <kmonitor+0x134>
        argv[argc ++] = buf;
ffffffffc0200466:	00349793          	slli	a5,s1,0x3
ffffffffc020046a:	0118                	addi	a4,sp,128
ffffffffc020046c:	97ba                	add	a5,a5,a4
ffffffffc020046e:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200472:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200476:	2485                	addiw	s1,s1,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200478:	e591                	bnez	a1,ffffffffc0200484 <kmonitor+0x126>
ffffffffc020047a:	b749                	j	ffffffffc02003fc <kmonitor+0x9e>
            buf ++;
ffffffffc020047c:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020047e:	00044583          	lbu	a1,0(s0)
ffffffffc0200482:	ddad                	beqz	a1,ffffffffc02003fc <kmonitor+0x9e>
ffffffffc0200484:	854a                	mv	a0,s2
ffffffffc0200486:	5a6040ef          	jal	ra,ffffffffc0204a2c <strchr>
ffffffffc020048a:	d96d                	beqz	a0,ffffffffc020047c <kmonitor+0x11e>
ffffffffc020048c:	00044583          	lbu	a1,0(s0)
ffffffffc0200490:	bf91                	j	ffffffffc02003e4 <kmonitor+0x86>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200492:	45c1                	li	a1,16
ffffffffc0200494:	855a                	mv	a0,s6
ffffffffc0200496:	c3bff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
ffffffffc020049a:	b7f1                	j	ffffffffc0200466 <kmonitor+0x108>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020049c:	6582                	ld	a1,0(sp)
ffffffffc020049e:	00005517          	auipc	a0,0x5
ffffffffc02004a2:	c2250513          	addi	a0,a0,-990 # ffffffffc02050c0 <commands+0xc8>
ffffffffc02004a6:	c2bff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    return 0;
ffffffffc02004aa:	b72d                	j	ffffffffc02003d4 <kmonitor+0x76>

ffffffffc02004ac <ide_init>:
#include <stdio.h>
#include <string.h>
#include <trap.h>
#include <riscv.h>

void ide_init(void) {}
ffffffffc02004ac:	8082                	ret

ffffffffc02004ae <ide_device_valid>:

#define MAX_IDE 2
#define MAX_DISK_NSECS 56
static char ide[MAX_DISK_NSECS * SECTSIZE];

bool ide_device_valid(unsigned short ideno) { return ideno < MAX_IDE; }
ffffffffc02004ae:	00253513          	sltiu	a0,a0,2
ffffffffc02004b2:	8082                	ret

ffffffffc02004b4 <ide_device_size>:

size_t ide_device_size(unsigned short ideno) { return MAX_DISK_NSECS; }
ffffffffc02004b4:	03800513          	li	a0,56
ffffffffc02004b8:	8082                	ret

ffffffffc02004ba <ide_read_secs>:

int ide_read_secs(unsigned short ideno, uint32_t secno, void *dst,
                  size_t nsecs) {
    int iobase = secno * SECTSIZE;
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc02004ba:	0000b797          	auipc	a5,0xb
ffffffffc02004be:	fa678793          	addi	a5,a5,-90 # ffffffffc020b460 <ide>
ffffffffc02004c2:	0095959b          	slliw	a1,a1,0x9
                  size_t nsecs) {
ffffffffc02004c6:	1141                	addi	sp,sp,-16
ffffffffc02004c8:	8532                	mv	a0,a2
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc02004ca:	95be                	add	a1,a1,a5
ffffffffc02004cc:	00969613          	slli	a2,a3,0x9
                  size_t nsecs) {
ffffffffc02004d0:	e406                	sd	ra,8(sp)
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc02004d2:	58a040ef          	jal	ra,ffffffffc0204a5c <memcpy>
    return 0;
}
ffffffffc02004d6:	60a2                	ld	ra,8(sp)
ffffffffc02004d8:	4501                	li	a0,0
ffffffffc02004da:	0141                	addi	sp,sp,16
ffffffffc02004dc:	8082                	ret

ffffffffc02004de <ide_write_secs>:

int ide_write_secs(unsigned short ideno, uint32_t secno, const void *src,
                   size_t nsecs) {
ffffffffc02004de:	8732                	mv	a4,a2
    int iobase = secno * SECTSIZE;
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc02004e0:	0095979b          	slliw	a5,a1,0x9
ffffffffc02004e4:	0000b517          	auipc	a0,0xb
ffffffffc02004e8:	f7c50513          	addi	a0,a0,-132 # ffffffffc020b460 <ide>
                   size_t nsecs) {
ffffffffc02004ec:	1141                	addi	sp,sp,-16
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc02004ee:	00969613          	slli	a2,a3,0x9
ffffffffc02004f2:	85ba                	mv	a1,a4
ffffffffc02004f4:	953e                	add	a0,a0,a5
                   size_t nsecs) {
ffffffffc02004f6:	e406                	sd	ra,8(sp)
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc02004f8:	564040ef          	jal	ra,ffffffffc0204a5c <memcpy>
    return 0;
}
ffffffffc02004fc:	60a2                	ld	ra,8(sp)
ffffffffc02004fe:	4501                	li	a0,0
ffffffffc0200500:	0141                	addi	sp,sp,16
ffffffffc0200502:	8082                	ret

ffffffffc0200504 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc0200504:	67e1                	lui	a5,0x18
ffffffffc0200506:	6a078793          	addi	a5,a5,1696 # 186a0 <BASE_ADDRESS-0xffffffffc01e7960>
ffffffffc020050a:	00016717          	auipc	a4,0x16
ffffffffc020050e:	f6f73723          	sd	a5,-146(a4) # ffffffffc0216478 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200512:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc0200516:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200518:	953e                	add	a0,a0,a5
ffffffffc020051a:	4601                	li	a2,0
ffffffffc020051c:	4881                	li	a7,0
ffffffffc020051e:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200522:	02000793          	li	a5,32
ffffffffc0200526:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc020052a:	00005517          	auipc	a0,0x5
ffffffffc020052e:	c4e50513          	addi	a0,a0,-946 # ffffffffc0205178 <commands+0x180>
    ticks = 0;
ffffffffc0200532:	00016797          	auipc	a5,0x16
ffffffffc0200536:	f807bf23          	sd	zero,-98(a5) # ffffffffc02164d0 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020053a:	be59                	j	ffffffffc02000d0 <cprintf>

ffffffffc020053c <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020053c:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200540:	00016797          	auipc	a5,0x16
ffffffffc0200544:	f3878793          	addi	a5,a5,-200 # ffffffffc0216478 <timebase>
ffffffffc0200548:	639c                	ld	a5,0(a5)
ffffffffc020054a:	4581                	li	a1,0
ffffffffc020054c:	4601                	li	a2,0
ffffffffc020054e:	953e                	add	a0,a0,a5
ffffffffc0200550:	4881                	li	a7,0
ffffffffc0200552:	00000073          	ecall
ffffffffc0200556:	8082                	ret

ffffffffc0200558 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200558:	8082                	ret

ffffffffc020055a <cons_putc>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020055a:	100027f3          	csrr	a5,sstatus
ffffffffc020055e:	8b89                	andi	a5,a5,2
ffffffffc0200560:	0ff57513          	andi	a0,a0,255
ffffffffc0200564:	e799                	bnez	a5,ffffffffc0200572 <cons_putc+0x18>
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200566:	4581                	li	a1,0
ffffffffc0200568:	4601                	li	a2,0
ffffffffc020056a:	4885                	li	a7,1
ffffffffc020056c:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc0200570:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc0200572:	1101                	addi	sp,sp,-32
ffffffffc0200574:	ec06                	sd	ra,24(sp)
ffffffffc0200576:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0200578:	05a000ef          	jal	ra,ffffffffc02005d2 <intr_disable>
ffffffffc020057c:	6522                	ld	a0,8(sp)
ffffffffc020057e:	4581                	li	a1,0
ffffffffc0200580:	4601                	li	a2,0
ffffffffc0200582:	4885                	li	a7,1
ffffffffc0200584:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200588:	60e2                	ld	ra,24(sp)
ffffffffc020058a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020058c:	a081                	j	ffffffffc02005cc <intr_enable>

ffffffffc020058e <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020058e:	100027f3          	csrr	a5,sstatus
ffffffffc0200592:	8b89                	andi	a5,a5,2
ffffffffc0200594:	eb89                	bnez	a5,ffffffffc02005a6 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc0200596:	4501                	li	a0,0
ffffffffc0200598:	4581                	li	a1,0
ffffffffc020059a:	4601                	li	a2,0
ffffffffc020059c:	4889                	li	a7,2
ffffffffc020059e:	00000073          	ecall
ffffffffc02005a2:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc02005a4:	8082                	ret
int cons_getc(void) {
ffffffffc02005a6:	1101                	addi	sp,sp,-32
ffffffffc02005a8:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc02005aa:	028000ef          	jal	ra,ffffffffc02005d2 <intr_disable>
ffffffffc02005ae:	4501                	li	a0,0
ffffffffc02005b0:	4581                	li	a1,0
ffffffffc02005b2:	4601                	li	a2,0
ffffffffc02005b4:	4889                	li	a7,2
ffffffffc02005b6:	00000073          	ecall
ffffffffc02005ba:	2501                	sext.w	a0,a0
ffffffffc02005bc:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02005be:	00e000ef          	jal	ra,ffffffffc02005cc <intr_enable>
}
ffffffffc02005c2:	60e2                	ld	ra,24(sp)
ffffffffc02005c4:	6522                	ld	a0,8(sp)
ffffffffc02005c6:	6105                	addi	sp,sp,32
ffffffffc02005c8:	8082                	ret

ffffffffc02005ca <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc02005ca:	8082                	ret

ffffffffc02005cc <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02005cc:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02005d0:	8082                	ret

ffffffffc02005d2 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02005d2:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02005d6:	8082                	ret

ffffffffc02005d8 <pgfault_handler>:
    set_csr(sstatus, SSTATUS_SUM);
}

/* trap_in_kernel - test if trap happened in kernel */
bool trap_in_kernel(struct trapframe *tf) {
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02005d8:	10053783          	ld	a5,256(a0)
    cprintf("page falut at 0x%08x: %c/%c\n", tf->badvaddr,
            trap_in_kernel(tf) ? 'K' : 'U',
            tf->cause == CAUSE_STORE_PAGE_FAULT ? 'W' : 'R');
}

static int pgfault_handler(struct trapframe *tf) {
ffffffffc02005dc:	1141                	addi	sp,sp,-16
ffffffffc02005de:	e022                	sd	s0,0(sp)
ffffffffc02005e0:	e406                	sd	ra,8(sp)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02005e2:	1007f793          	andi	a5,a5,256
static int pgfault_handler(struct trapframe *tf) {
ffffffffc02005e6:	842a                	mv	s0,a0
    cprintf("page falut at 0x%08x: %c/%c\n", tf->badvaddr,
ffffffffc02005e8:	11053583          	ld	a1,272(a0)
ffffffffc02005ec:	05500613          	li	a2,85
ffffffffc02005f0:	c399                	beqz	a5,ffffffffc02005f6 <pgfault_handler+0x1e>
ffffffffc02005f2:	04b00613          	li	a2,75
ffffffffc02005f6:	11843703          	ld	a4,280(s0)
ffffffffc02005fa:	47bd                	li	a5,15
ffffffffc02005fc:	05700693          	li	a3,87
ffffffffc0200600:	00f70463          	beq	a4,a5,ffffffffc0200608 <pgfault_handler+0x30>
ffffffffc0200604:	05200693          	li	a3,82
ffffffffc0200608:	00005517          	auipc	a0,0x5
ffffffffc020060c:	e6850513          	addi	a0,a0,-408 # ffffffffc0205470 <commands+0x478>
ffffffffc0200610:	ac1ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    extern struct mm_struct *check_mm_struct;
    print_pgfault(tf);
    if (check_mm_struct != NULL) {
ffffffffc0200614:	00016797          	auipc	a5,0x16
ffffffffc0200618:	ef478793          	addi	a5,a5,-268 # ffffffffc0216508 <check_mm_struct>
ffffffffc020061c:	6388                	ld	a0,0(a5)
ffffffffc020061e:	c911                	beqz	a0,ffffffffc0200632 <pgfault_handler+0x5a>
        return do_pgfault(check_mm_struct, tf->cause, tf->badvaddr);
ffffffffc0200620:	11043603          	ld	a2,272(s0)
ffffffffc0200624:	11842583          	lw	a1,280(s0)
    }
    panic("unhandled page fault.\n");
}
ffffffffc0200628:	6402                	ld	s0,0(sp)
ffffffffc020062a:	60a2                	ld	ra,8(sp)
ffffffffc020062c:	0141                	addi	sp,sp,16
        return do_pgfault(check_mm_struct, tf->cause, tf->badvaddr);
ffffffffc020062e:	0160206f          	j	ffffffffc0202644 <do_pgfault>
    panic("unhandled page fault.\n");
ffffffffc0200632:	00005617          	auipc	a2,0x5
ffffffffc0200636:	e5e60613          	addi	a2,a2,-418 # ffffffffc0205490 <commands+0x498>
ffffffffc020063a:	06200593          	li	a1,98
ffffffffc020063e:	00005517          	auipc	a0,0x5
ffffffffc0200642:	e6a50513          	addi	a0,a0,-406 # ffffffffc02054a8 <commands+0x4b0>
ffffffffc0200646:	b8fff0ef          	jal	ra,ffffffffc02001d4 <__panic>

ffffffffc020064a <idt_init>:
    write_csr(sscratch, 0);
ffffffffc020064a:	14005073          	csrwi	sscratch,0
    write_csr(stvec, &__alltraps);
ffffffffc020064e:	00000797          	auipc	a5,0x0
ffffffffc0200652:	48278793          	addi	a5,a5,1154 # ffffffffc0200ad0 <__alltraps>
ffffffffc0200656:	10579073          	csrw	stvec,a5
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc020065a:	000407b7          	lui	a5,0x40
ffffffffc020065e:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc0200662:	8082                	ret

ffffffffc0200664 <print_regs>:
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200664:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc0200666:	1141                	addi	sp,sp,-16
ffffffffc0200668:	e022                	sd	s0,0(sp)
ffffffffc020066a:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020066c:	00005517          	auipc	a0,0x5
ffffffffc0200670:	e5450513          	addi	a0,a0,-428 # ffffffffc02054c0 <commands+0x4c8>
void print_regs(struct pushregs *gpr) {
ffffffffc0200674:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200676:	a5bff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020067a:	640c                	ld	a1,8(s0)
ffffffffc020067c:	00005517          	auipc	a0,0x5
ffffffffc0200680:	e5c50513          	addi	a0,a0,-420 # ffffffffc02054d8 <commands+0x4e0>
ffffffffc0200684:	a4dff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200688:	680c                	ld	a1,16(s0)
ffffffffc020068a:	00005517          	auipc	a0,0x5
ffffffffc020068e:	e6650513          	addi	a0,a0,-410 # ffffffffc02054f0 <commands+0x4f8>
ffffffffc0200692:	a3fff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200696:	6c0c                	ld	a1,24(s0)
ffffffffc0200698:	00005517          	auipc	a0,0x5
ffffffffc020069c:	e7050513          	addi	a0,a0,-400 # ffffffffc0205508 <commands+0x510>
ffffffffc02006a0:	a31ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02006a4:	700c                	ld	a1,32(s0)
ffffffffc02006a6:	00005517          	auipc	a0,0x5
ffffffffc02006aa:	e7a50513          	addi	a0,a0,-390 # ffffffffc0205520 <commands+0x528>
ffffffffc02006ae:	a23ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02006b2:	740c                	ld	a1,40(s0)
ffffffffc02006b4:	00005517          	auipc	a0,0x5
ffffffffc02006b8:	e8450513          	addi	a0,a0,-380 # ffffffffc0205538 <commands+0x540>
ffffffffc02006bc:	a15ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02006c0:	780c                	ld	a1,48(s0)
ffffffffc02006c2:	00005517          	auipc	a0,0x5
ffffffffc02006c6:	e8e50513          	addi	a0,a0,-370 # ffffffffc0205550 <commands+0x558>
ffffffffc02006ca:	a07ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02006ce:	7c0c                	ld	a1,56(s0)
ffffffffc02006d0:	00005517          	auipc	a0,0x5
ffffffffc02006d4:	e9850513          	addi	a0,a0,-360 # ffffffffc0205568 <commands+0x570>
ffffffffc02006d8:	9f9ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02006dc:	602c                	ld	a1,64(s0)
ffffffffc02006de:	00005517          	auipc	a0,0x5
ffffffffc02006e2:	ea250513          	addi	a0,a0,-350 # ffffffffc0205580 <commands+0x588>
ffffffffc02006e6:	9ebff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02006ea:	642c                	ld	a1,72(s0)
ffffffffc02006ec:	00005517          	auipc	a0,0x5
ffffffffc02006f0:	eac50513          	addi	a0,a0,-340 # ffffffffc0205598 <commands+0x5a0>
ffffffffc02006f4:	9ddff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02006f8:	682c                	ld	a1,80(s0)
ffffffffc02006fa:	00005517          	auipc	a0,0x5
ffffffffc02006fe:	eb650513          	addi	a0,a0,-330 # ffffffffc02055b0 <commands+0x5b8>
ffffffffc0200702:	9cfff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200706:	6c2c                	ld	a1,88(s0)
ffffffffc0200708:	00005517          	auipc	a0,0x5
ffffffffc020070c:	ec050513          	addi	a0,a0,-320 # ffffffffc02055c8 <commands+0x5d0>
ffffffffc0200710:	9c1ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200714:	702c                	ld	a1,96(s0)
ffffffffc0200716:	00005517          	auipc	a0,0x5
ffffffffc020071a:	eca50513          	addi	a0,a0,-310 # ffffffffc02055e0 <commands+0x5e8>
ffffffffc020071e:	9b3ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200722:	742c                	ld	a1,104(s0)
ffffffffc0200724:	00005517          	auipc	a0,0x5
ffffffffc0200728:	ed450513          	addi	a0,a0,-300 # ffffffffc02055f8 <commands+0x600>
ffffffffc020072c:	9a5ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200730:	782c                	ld	a1,112(s0)
ffffffffc0200732:	00005517          	auipc	a0,0x5
ffffffffc0200736:	ede50513          	addi	a0,a0,-290 # ffffffffc0205610 <commands+0x618>
ffffffffc020073a:	997ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc020073e:	7c2c                	ld	a1,120(s0)
ffffffffc0200740:	00005517          	auipc	a0,0x5
ffffffffc0200744:	ee850513          	addi	a0,a0,-280 # ffffffffc0205628 <commands+0x630>
ffffffffc0200748:	989ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc020074c:	604c                	ld	a1,128(s0)
ffffffffc020074e:	00005517          	auipc	a0,0x5
ffffffffc0200752:	ef250513          	addi	a0,a0,-270 # ffffffffc0205640 <commands+0x648>
ffffffffc0200756:	97bff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc020075a:	644c                	ld	a1,136(s0)
ffffffffc020075c:	00005517          	auipc	a0,0x5
ffffffffc0200760:	efc50513          	addi	a0,a0,-260 # ffffffffc0205658 <commands+0x660>
ffffffffc0200764:	96dff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200768:	684c                	ld	a1,144(s0)
ffffffffc020076a:	00005517          	auipc	a0,0x5
ffffffffc020076e:	f0650513          	addi	a0,a0,-250 # ffffffffc0205670 <commands+0x678>
ffffffffc0200772:	95fff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200776:	6c4c                	ld	a1,152(s0)
ffffffffc0200778:	00005517          	auipc	a0,0x5
ffffffffc020077c:	f1050513          	addi	a0,a0,-240 # ffffffffc0205688 <commands+0x690>
ffffffffc0200780:	951ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200784:	704c                	ld	a1,160(s0)
ffffffffc0200786:	00005517          	auipc	a0,0x5
ffffffffc020078a:	f1a50513          	addi	a0,a0,-230 # ffffffffc02056a0 <commands+0x6a8>
ffffffffc020078e:	943ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200792:	744c                	ld	a1,168(s0)
ffffffffc0200794:	00005517          	auipc	a0,0x5
ffffffffc0200798:	f2450513          	addi	a0,a0,-220 # ffffffffc02056b8 <commands+0x6c0>
ffffffffc020079c:	935ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02007a0:	784c                	ld	a1,176(s0)
ffffffffc02007a2:	00005517          	auipc	a0,0x5
ffffffffc02007a6:	f2e50513          	addi	a0,a0,-210 # ffffffffc02056d0 <commands+0x6d8>
ffffffffc02007aa:	927ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02007ae:	7c4c                	ld	a1,184(s0)
ffffffffc02007b0:	00005517          	auipc	a0,0x5
ffffffffc02007b4:	f3850513          	addi	a0,a0,-200 # ffffffffc02056e8 <commands+0x6f0>
ffffffffc02007b8:	919ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02007bc:	606c                	ld	a1,192(s0)
ffffffffc02007be:	00005517          	auipc	a0,0x5
ffffffffc02007c2:	f4250513          	addi	a0,a0,-190 # ffffffffc0205700 <commands+0x708>
ffffffffc02007c6:	90bff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02007ca:	646c                	ld	a1,200(s0)
ffffffffc02007cc:	00005517          	auipc	a0,0x5
ffffffffc02007d0:	f4c50513          	addi	a0,a0,-180 # ffffffffc0205718 <commands+0x720>
ffffffffc02007d4:	8fdff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02007d8:	686c                	ld	a1,208(s0)
ffffffffc02007da:	00005517          	auipc	a0,0x5
ffffffffc02007de:	f5650513          	addi	a0,a0,-170 # ffffffffc0205730 <commands+0x738>
ffffffffc02007e2:	8efff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02007e6:	6c6c                	ld	a1,216(s0)
ffffffffc02007e8:	00005517          	auipc	a0,0x5
ffffffffc02007ec:	f6050513          	addi	a0,a0,-160 # ffffffffc0205748 <commands+0x750>
ffffffffc02007f0:	8e1ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc02007f4:	706c                	ld	a1,224(s0)
ffffffffc02007f6:	00005517          	auipc	a0,0x5
ffffffffc02007fa:	f6a50513          	addi	a0,a0,-150 # ffffffffc0205760 <commands+0x768>
ffffffffc02007fe:	8d3ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200802:	746c                	ld	a1,232(s0)
ffffffffc0200804:	00005517          	auipc	a0,0x5
ffffffffc0200808:	f7450513          	addi	a0,a0,-140 # ffffffffc0205778 <commands+0x780>
ffffffffc020080c:	8c5ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200810:	786c                	ld	a1,240(s0)
ffffffffc0200812:	00005517          	auipc	a0,0x5
ffffffffc0200816:	f7e50513          	addi	a0,a0,-130 # ffffffffc0205790 <commands+0x798>
ffffffffc020081a:	8b7ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020081e:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200820:	6402                	ld	s0,0(sp)
ffffffffc0200822:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200824:	00005517          	auipc	a0,0x5
ffffffffc0200828:	f8450513          	addi	a0,a0,-124 # ffffffffc02057a8 <commands+0x7b0>
}
ffffffffc020082c:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020082e:	8a3ff06f          	j	ffffffffc02000d0 <cprintf>

ffffffffc0200832 <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc0200832:	1141                	addi	sp,sp,-16
ffffffffc0200834:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200836:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200838:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc020083a:	00005517          	auipc	a0,0x5
ffffffffc020083e:	f8650513          	addi	a0,a0,-122 # ffffffffc02057c0 <commands+0x7c8>
void print_trapframe(struct trapframe *tf) {
ffffffffc0200842:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200844:	88dff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200848:	8522                	mv	a0,s0
ffffffffc020084a:	e1bff0ef          	jal	ra,ffffffffc0200664 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc020084e:	10043583          	ld	a1,256(s0)
ffffffffc0200852:	00005517          	auipc	a0,0x5
ffffffffc0200856:	f8650513          	addi	a0,a0,-122 # ffffffffc02057d8 <commands+0x7e0>
ffffffffc020085a:	877ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc020085e:	10843583          	ld	a1,264(s0)
ffffffffc0200862:	00005517          	auipc	a0,0x5
ffffffffc0200866:	f8e50513          	addi	a0,a0,-114 # ffffffffc02057f0 <commands+0x7f8>
ffffffffc020086a:	867ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc020086e:	11043583          	ld	a1,272(s0)
ffffffffc0200872:	00005517          	auipc	a0,0x5
ffffffffc0200876:	f9650513          	addi	a0,a0,-106 # ffffffffc0205808 <commands+0x810>
ffffffffc020087a:	857ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020087e:	11843583          	ld	a1,280(s0)
}
ffffffffc0200882:	6402                	ld	s0,0(sp)
ffffffffc0200884:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200886:	00005517          	auipc	a0,0x5
ffffffffc020088a:	f9a50513          	addi	a0,a0,-102 # ffffffffc0205820 <commands+0x828>
}
ffffffffc020088e:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200890:	841ff06f          	j	ffffffffc02000d0 <cprintf>

ffffffffc0200894 <interrupt_handler>:

static volatile int in_swap_tick_event = 0;
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200894:	11853783          	ld	a5,280(a0)
    switch (cause) {
ffffffffc0200898:	472d                	li	a4,11
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc020089a:	0786                	slli	a5,a5,0x1
ffffffffc020089c:	8385                	srli	a5,a5,0x1
    switch (cause) {
ffffffffc020089e:	06f76f63          	bltu	a4,a5,ffffffffc020091c <interrupt_handler+0x88>
ffffffffc02008a2:	00005717          	auipc	a4,0x5
ffffffffc02008a6:	8f270713          	addi	a4,a4,-1806 # ffffffffc0205194 <commands+0x19c>
ffffffffc02008aa:	078a                	slli	a5,a5,0x2
ffffffffc02008ac:	97ba                	add	a5,a5,a4
ffffffffc02008ae:	439c                	lw	a5,0(a5)
ffffffffc02008b0:	97ba                	add	a5,a5,a4
ffffffffc02008b2:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02008b4:	00005517          	auipc	a0,0x5
ffffffffc02008b8:	b6c50513          	addi	a0,a0,-1172 # ffffffffc0205420 <commands+0x428>
ffffffffc02008bc:	815ff06f          	j	ffffffffc02000d0 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02008c0:	00005517          	auipc	a0,0x5
ffffffffc02008c4:	b4050513          	addi	a0,a0,-1216 # ffffffffc0205400 <commands+0x408>
ffffffffc02008c8:	809ff06f          	j	ffffffffc02000d0 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02008cc:	00005517          	auipc	a0,0x5
ffffffffc02008d0:	af450513          	addi	a0,a0,-1292 # ffffffffc02053c0 <commands+0x3c8>
ffffffffc02008d4:	ffcff06f          	j	ffffffffc02000d0 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc02008d8:	00005517          	auipc	a0,0x5
ffffffffc02008dc:	b0850513          	addi	a0,a0,-1272 # ffffffffc02053e0 <commands+0x3e8>
ffffffffc02008e0:	ff0ff06f          	j	ffffffffc02000d0 <cprintf>
            break;
        case IRQ_U_EXT:
            cprintf("User software interrupt\n");
            break;
        case IRQ_S_EXT:
            cprintf("Supervisor external interrupt\n");
ffffffffc02008e4:	00005517          	auipc	a0,0x5
ffffffffc02008e8:	b6c50513          	addi	a0,a0,-1172 # ffffffffc0205450 <commands+0x458>
ffffffffc02008ec:	fe4ff06f          	j	ffffffffc02000d0 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc02008f0:	1141                	addi	sp,sp,-16
ffffffffc02008f2:	e406                	sd	ra,8(sp)
            clock_set_next_event();
ffffffffc02008f4:	c49ff0ef          	jal	ra,ffffffffc020053c <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc02008f8:	00016797          	auipc	a5,0x16
ffffffffc02008fc:	bd878793          	addi	a5,a5,-1064 # ffffffffc02164d0 <ticks>
ffffffffc0200900:	639c                	ld	a5,0(a5)
ffffffffc0200902:	06400713          	li	a4,100
ffffffffc0200906:	0785                	addi	a5,a5,1
ffffffffc0200908:	02e7f733          	remu	a4,a5,a4
ffffffffc020090c:	00016697          	auipc	a3,0x16
ffffffffc0200910:	bcf6b223          	sd	a5,-1084(a3) # ffffffffc02164d0 <ticks>
ffffffffc0200914:	c709                	beqz	a4,ffffffffc020091e <interrupt_handler+0x8a>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200916:	60a2                	ld	ra,8(sp)
ffffffffc0200918:	0141                	addi	sp,sp,16
ffffffffc020091a:	8082                	ret
            print_trapframe(tf);
ffffffffc020091c:	bf19                	j	ffffffffc0200832 <print_trapframe>
}
ffffffffc020091e:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200920:	06400593          	li	a1,100
ffffffffc0200924:	00005517          	auipc	a0,0x5
ffffffffc0200928:	b1c50513          	addi	a0,a0,-1252 # ffffffffc0205440 <commands+0x448>
}
ffffffffc020092c:	0141                	addi	sp,sp,16
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc020092e:	fa2ff06f          	j	ffffffffc02000d0 <cprintf>

ffffffffc0200932 <exception_handler>:

void exception_handler(struct trapframe *tf) {
    int ret;
    switch (tf->cause) {
ffffffffc0200932:	11853783          	ld	a5,280(a0)
ffffffffc0200936:	473d                	li	a4,15
ffffffffc0200938:	16f76463          	bltu	a4,a5,ffffffffc0200aa0 <exception_handler+0x16e>
ffffffffc020093c:	00005717          	auipc	a4,0x5
ffffffffc0200940:	88870713          	addi	a4,a4,-1912 # ffffffffc02051c4 <commands+0x1cc>
ffffffffc0200944:	078a                	slli	a5,a5,0x2
ffffffffc0200946:	97ba                	add	a5,a5,a4
ffffffffc0200948:	439c                	lw	a5,0(a5)
void exception_handler(struct trapframe *tf) {
ffffffffc020094a:	1101                	addi	sp,sp,-32
ffffffffc020094c:	e822                	sd	s0,16(sp)
ffffffffc020094e:	ec06                	sd	ra,24(sp)
ffffffffc0200950:	e426                	sd	s1,8(sp)
    switch (tf->cause) {
ffffffffc0200952:	97ba                	add	a5,a5,a4
ffffffffc0200954:	842a                	mv	s0,a0
ffffffffc0200956:	8782                	jr	a5
                print_trapframe(tf);
                panic("handle pgfault failed. %e\n", ret);
            }
            break;
        case CAUSE_STORE_PAGE_FAULT:
            cprintf("Store/AMO page fault\n");
ffffffffc0200958:	00005517          	auipc	a0,0x5
ffffffffc020095c:	a5050513          	addi	a0,a0,-1456 # ffffffffc02053a8 <commands+0x3b0>
ffffffffc0200960:	f70ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200964:	8522                	mv	a0,s0
ffffffffc0200966:	c73ff0ef          	jal	ra,ffffffffc02005d8 <pgfault_handler>
ffffffffc020096a:	84aa                	mv	s1,a0
ffffffffc020096c:	12051b63          	bnez	a0,ffffffffc0200aa2 <exception_handler+0x170>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200970:	60e2                	ld	ra,24(sp)
ffffffffc0200972:	6442                	ld	s0,16(sp)
ffffffffc0200974:	64a2                	ld	s1,8(sp)
ffffffffc0200976:	6105                	addi	sp,sp,32
ffffffffc0200978:	8082                	ret
            cprintf("Instruction address misaligned\n");
ffffffffc020097a:	00005517          	auipc	a0,0x5
ffffffffc020097e:	88e50513          	addi	a0,a0,-1906 # ffffffffc0205208 <commands+0x210>
}
ffffffffc0200982:	6442                	ld	s0,16(sp)
ffffffffc0200984:	60e2                	ld	ra,24(sp)
ffffffffc0200986:	64a2                	ld	s1,8(sp)
ffffffffc0200988:	6105                	addi	sp,sp,32
            cprintf("Instruction access fault\n");
ffffffffc020098a:	f46ff06f          	j	ffffffffc02000d0 <cprintf>
ffffffffc020098e:	00005517          	auipc	a0,0x5
ffffffffc0200992:	89a50513          	addi	a0,a0,-1894 # ffffffffc0205228 <commands+0x230>
ffffffffc0200996:	b7f5                	j	ffffffffc0200982 <exception_handler+0x50>
            cprintf("Illegal instruction\n");
ffffffffc0200998:	00005517          	auipc	a0,0x5
ffffffffc020099c:	8b050513          	addi	a0,a0,-1872 # ffffffffc0205248 <commands+0x250>
ffffffffc02009a0:	b7cd                	j	ffffffffc0200982 <exception_handler+0x50>
            cprintf("Breakpoint\n");
ffffffffc02009a2:	00005517          	auipc	a0,0x5
ffffffffc02009a6:	8be50513          	addi	a0,a0,-1858 # ffffffffc0205260 <commands+0x268>
ffffffffc02009aa:	bfe1                	j	ffffffffc0200982 <exception_handler+0x50>
            cprintf("Load address misaligned\n");
ffffffffc02009ac:	00005517          	auipc	a0,0x5
ffffffffc02009b0:	8c450513          	addi	a0,a0,-1852 # ffffffffc0205270 <commands+0x278>
ffffffffc02009b4:	b7f9                	j	ffffffffc0200982 <exception_handler+0x50>
            cprintf("Load access fault\n");
ffffffffc02009b6:	00005517          	auipc	a0,0x5
ffffffffc02009ba:	8da50513          	addi	a0,a0,-1830 # ffffffffc0205290 <commands+0x298>
ffffffffc02009be:	f12ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc02009c2:	8522                	mv	a0,s0
ffffffffc02009c4:	c15ff0ef          	jal	ra,ffffffffc02005d8 <pgfault_handler>
ffffffffc02009c8:	84aa                	mv	s1,a0
ffffffffc02009ca:	d15d                	beqz	a0,ffffffffc0200970 <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc02009cc:	8522                	mv	a0,s0
ffffffffc02009ce:	e65ff0ef          	jal	ra,ffffffffc0200832 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc02009d2:	86a6                	mv	a3,s1
ffffffffc02009d4:	00005617          	auipc	a2,0x5
ffffffffc02009d8:	8d460613          	addi	a2,a2,-1836 # ffffffffc02052a8 <commands+0x2b0>
ffffffffc02009dc:	0b300593          	li	a1,179
ffffffffc02009e0:	00005517          	auipc	a0,0x5
ffffffffc02009e4:	ac850513          	addi	a0,a0,-1336 # ffffffffc02054a8 <commands+0x4b0>
ffffffffc02009e8:	fecff0ef          	jal	ra,ffffffffc02001d4 <__panic>
            cprintf("AMO address misaligned\n");
ffffffffc02009ec:	00005517          	auipc	a0,0x5
ffffffffc02009f0:	8dc50513          	addi	a0,a0,-1828 # ffffffffc02052c8 <commands+0x2d0>
ffffffffc02009f4:	b779                	j	ffffffffc0200982 <exception_handler+0x50>
            cprintf("Store/AMO access fault\n");
ffffffffc02009f6:	00005517          	auipc	a0,0x5
ffffffffc02009fa:	8ea50513          	addi	a0,a0,-1814 # ffffffffc02052e0 <commands+0x2e8>
ffffffffc02009fe:	ed2ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200a02:	8522                	mv	a0,s0
ffffffffc0200a04:	bd5ff0ef          	jal	ra,ffffffffc02005d8 <pgfault_handler>
ffffffffc0200a08:	84aa                	mv	s1,a0
ffffffffc0200a0a:	d13d                	beqz	a0,ffffffffc0200970 <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc0200a0c:	8522                	mv	a0,s0
ffffffffc0200a0e:	e25ff0ef          	jal	ra,ffffffffc0200832 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200a12:	86a6                	mv	a3,s1
ffffffffc0200a14:	00005617          	auipc	a2,0x5
ffffffffc0200a18:	89460613          	addi	a2,a2,-1900 # ffffffffc02052a8 <commands+0x2b0>
ffffffffc0200a1c:	0bd00593          	li	a1,189
ffffffffc0200a20:	00005517          	auipc	a0,0x5
ffffffffc0200a24:	a8850513          	addi	a0,a0,-1400 # ffffffffc02054a8 <commands+0x4b0>
ffffffffc0200a28:	facff0ef          	jal	ra,ffffffffc02001d4 <__panic>
            cprintf("Environment call from U-mode\n");
ffffffffc0200a2c:	00005517          	auipc	a0,0x5
ffffffffc0200a30:	8cc50513          	addi	a0,a0,-1844 # ffffffffc02052f8 <commands+0x300>
ffffffffc0200a34:	b7b9                	j	ffffffffc0200982 <exception_handler+0x50>
            cprintf("Environment call from S-mode\n");
ffffffffc0200a36:	00005517          	auipc	a0,0x5
ffffffffc0200a3a:	8e250513          	addi	a0,a0,-1822 # ffffffffc0205318 <commands+0x320>
ffffffffc0200a3e:	b791                	j	ffffffffc0200982 <exception_handler+0x50>
            cprintf("Environment call from H-mode\n");
ffffffffc0200a40:	00005517          	auipc	a0,0x5
ffffffffc0200a44:	8f850513          	addi	a0,a0,-1800 # ffffffffc0205338 <commands+0x340>
ffffffffc0200a48:	bf2d                	j	ffffffffc0200982 <exception_handler+0x50>
            cprintf("Environment call from M-mode\n");
ffffffffc0200a4a:	00005517          	auipc	a0,0x5
ffffffffc0200a4e:	90e50513          	addi	a0,a0,-1778 # ffffffffc0205358 <commands+0x360>
ffffffffc0200a52:	bf05                	j	ffffffffc0200982 <exception_handler+0x50>
            cprintf("Instruction page fault\n");
ffffffffc0200a54:	00005517          	auipc	a0,0x5
ffffffffc0200a58:	92450513          	addi	a0,a0,-1756 # ffffffffc0205378 <commands+0x380>
ffffffffc0200a5c:	b71d                	j	ffffffffc0200982 <exception_handler+0x50>
            cprintf("Load page fault\n");
ffffffffc0200a5e:	00005517          	auipc	a0,0x5
ffffffffc0200a62:	93250513          	addi	a0,a0,-1742 # ffffffffc0205390 <commands+0x398>
ffffffffc0200a66:	e6aff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200a6a:	8522                	mv	a0,s0
ffffffffc0200a6c:	b6dff0ef          	jal	ra,ffffffffc02005d8 <pgfault_handler>
ffffffffc0200a70:	84aa                	mv	s1,a0
ffffffffc0200a72:	ee050fe3          	beqz	a0,ffffffffc0200970 <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc0200a76:	8522                	mv	a0,s0
ffffffffc0200a78:	dbbff0ef          	jal	ra,ffffffffc0200832 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200a7c:	86a6                	mv	a3,s1
ffffffffc0200a7e:	00005617          	auipc	a2,0x5
ffffffffc0200a82:	82a60613          	addi	a2,a2,-2006 # ffffffffc02052a8 <commands+0x2b0>
ffffffffc0200a86:	0d300593          	li	a1,211
ffffffffc0200a8a:	00005517          	auipc	a0,0x5
ffffffffc0200a8e:	a1e50513          	addi	a0,a0,-1506 # ffffffffc02054a8 <commands+0x4b0>
ffffffffc0200a92:	f42ff0ef          	jal	ra,ffffffffc02001d4 <__panic>
}
ffffffffc0200a96:	6442                	ld	s0,16(sp)
ffffffffc0200a98:	60e2                	ld	ra,24(sp)
ffffffffc0200a9a:	64a2                	ld	s1,8(sp)
ffffffffc0200a9c:	6105                	addi	sp,sp,32
            print_trapframe(tf);
ffffffffc0200a9e:	bb51                	j	ffffffffc0200832 <print_trapframe>
ffffffffc0200aa0:	bb49                	j	ffffffffc0200832 <print_trapframe>
                print_trapframe(tf);
ffffffffc0200aa2:	8522                	mv	a0,s0
ffffffffc0200aa4:	d8fff0ef          	jal	ra,ffffffffc0200832 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200aa8:	86a6                	mv	a3,s1
ffffffffc0200aaa:	00004617          	auipc	a2,0x4
ffffffffc0200aae:	7fe60613          	addi	a2,a2,2046 # ffffffffc02052a8 <commands+0x2b0>
ffffffffc0200ab2:	0da00593          	li	a1,218
ffffffffc0200ab6:	00005517          	auipc	a0,0x5
ffffffffc0200aba:	9f250513          	addi	a0,a0,-1550 # ffffffffc02054a8 <commands+0x4b0>
ffffffffc0200abe:	f16ff0ef          	jal	ra,ffffffffc02001d4 <__panic>

ffffffffc0200ac2 <trap>:
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200ac2:	11853783          	ld	a5,280(a0)
ffffffffc0200ac6:	0007c363          	bltz	a5,ffffffffc0200acc <trap+0xa>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
ffffffffc0200aca:	b5a5                	j	ffffffffc0200932 <exception_handler>
        interrupt_handler(tf);
ffffffffc0200acc:	b3e1                	j	ffffffffc0200894 <interrupt_handler>
	...

ffffffffc0200ad0 <__alltraps>:
    LOAD  x2,2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200ad0:	14011073          	csrw	sscratch,sp
ffffffffc0200ad4:	712d                	addi	sp,sp,-288
ffffffffc0200ad6:	e406                	sd	ra,8(sp)
ffffffffc0200ad8:	ec0e                	sd	gp,24(sp)
ffffffffc0200ada:	f012                	sd	tp,32(sp)
ffffffffc0200adc:	f416                	sd	t0,40(sp)
ffffffffc0200ade:	f81a                	sd	t1,48(sp)
ffffffffc0200ae0:	fc1e                	sd	t2,56(sp)
ffffffffc0200ae2:	e0a2                	sd	s0,64(sp)
ffffffffc0200ae4:	e4a6                	sd	s1,72(sp)
ffffffffc0200ae6:	e8aa                	sd	a0,80(sp)
ffffffffc0200ae8:	ecae                	sd	a1,88(sp)
ffffffffc0200aea:	f0b2                	sd	a2,96(sp)
ffffffffc0200aec:	f4b6                	sd	a3,104(sp)
ffffffffc0200aee:	f8ba                	sd	a4,112(sp)
ffffffffc0200af0:	fcbe                	sd	a5,120(sp)
ffffffffc0200af2:	e142                	sd	a6,128(sp)
ffffffffc0200af4:	e546                	sd	a7,136(sp)
ffffffffc0200af6:	e94a                	sd	s2,144(sp)
ffffffffc0200af8:	ed4e                	sd	s3,152(sp)
ffffffffc0200afa:	f152                	sd	s4,160(sp)
ffffffffc0200afc:	f556                	sd	s5,168(sp)
ffffffffc0200afe:	f95a                	sd	s6,176(sp)
ffffffffc0200b00:	fd5e                	sd	s7,184(sp)
ffffffffc0200b02:	e1e2                	sd	s8,192(sp)
ffffffffc0200b04:	e5e6                	sd	s9,200(sp)
ffffffffc0200b06:	e9ea                	sd	s10,208(sp)
ffffffffc0200b08:	edee                	sd	s11,216(sp)
ffffffffc0200b0a:	f1f2                	sd	t3,224(sp)
ffffffffc0200b0c:	f5f6                	sd	t4,232(sp)
ffffffffc0200b0e:	f9fa                	sd	t5,240(sp)
ffffffffc0200b10:	fdfe                	sd	t6,248(sp)
ffffffffc0200b12:	14002473          	csrr	s0,sscratch
ffffffffc0200b16:	100024f3          	csrr	s1,sstatus
ffffffffc0200b1a:	14102973          	csrr	s2,sepc
ffffffffc0200b1e:	143029f3          	csrr	s3,stval
ffffffffc0200b22:	14202a73          	csrr	s4,scause
ffffffffc0200b26:	e822                	sd	s0,16(sp)
ffffffffc0200b28:	e226                	sd	s1,256(sp)
ffffffffc0200b2a:	e64a                	sd	s2,264(sp)
ffffffffc0200b2c:	ea4e                	sd	s3,272(sp)
ffffffffc0200b2e:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200b30:	850a                	mv	a0,sp
    jal trap
ffffffffc0200b32:	f91ff0ef          	jal	ra,ffffffffc0200ac2 <trap>

ffffffffc0200b36 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200b36:	6492                	ld	s1,256(sp)
ffffffffc0200b38:	6932                	ld	s2,264(sp)
ffffffffc0200b3a:	10049073          	csrw	sstatus,s1
ffffffffc0200b3e:	14191073          	csrw	sepc,s2
ffffffffc0200b42:	60a2                	ld	ra,8(sp)
ffffffffc0200b44:	61e2                	ld	gp,24(sp)
ffffffffc0200b46:	7202                	ld	tp,32(sp)
ffffffffc0200b48:	72a2                	ld	t0,40(sp)
ffffffffc0200b4a:	7342                	ld	t1,48(sp)
ffffffffc0200b4c:	73e2                	ld	t2,56(sp)
ffffffffc0200b4e:	6406                	ld	s0,64(sp)
ffffffffc0200b50:	64a6                	ld	s1,72(sp)
ffffffffc0200b52:	6546                	ld	a0,80(sp)
ffffffffc0200b54:	65e6                	ld	a1,88(sp)
ffffffffc0200b56:	7606                	ld	a2,96(sp)
ffffffffc0200b58:	76a6                	ld	a3,104(sp)
ffffffffc0200b5a:	7746                	ld	a4,112(sp)
ffffffffc0200b5c:	77e6                	ld	a5,120(sp)
ffffffffc0200b5e:	680a                	ld	a6,128(sp)
ffffffffc0200b60:	68aa                	ld	a7,136(sp)
ffffffffc0200b62:	694a                	ld	s2,144(sp)
ffffffffc0200b64:	69ea                	ld	s3,152(sp)
ffffffffc0200b66:	7a0a                	ld	s4,160(sp)
ffffffffc0200b68:	7aaa                	ld	s5,168(sp)
ffffffffc0200b6a:	7b4a                	ld	s6,176(sp)
ffffffffc0200b6c:	7bea                	ld	s7,184(sp)
ffffffffc0200b6e:	6c0e                	ld	s8,192(sp)
ffffffffc0200b70:	6cae                	ld	s9,200(sp)
ffffffffc0200b72:	6d4e                	ld	s10,208(sp)
ffffffffc0200b74:	6dee                	ld	s11,216(sp)
ffffffffc0200b76:	7e0e                	ld	t3,224(sp)
ffffffffc0200b78:	7eae                	ld	t4,232(sp)
ffffffffc0200b7a:	7f4e                	ld	t5,240(sp)
ffffffffc0200b7c:	7fee                	ld	t6,248(sp)
ffffffffc0200b7e:	6142                	ld	sp,16(sp)
    # go back from supervisor call
    sret
ffffffffc0200b80:	10200073          	sret

ffffffffc0200b84 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200b84:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200b86:	bf45                	j	ffffffffc0200b36 <__trapret>
	...

ffffffffc0200b8a <pa2page.part.4>:
page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
}

static inline struct Page *
pa2page(uintptr_t pa) {
ffffffffc0200b8a:	1141                	addi	sp,sp,-16
    if (PPN(pa) >= npage) {
        panic("pa2page called with invalid pa");
ffffffffc0200b8c:	00005617          	auipc	a2,0x5
ffffffffc0200b90:	ce460613          	addi	a2,a2,-796 # ffffffffc0205870 <commands+0x878>
ffffffffc0200b94:	06200593          	li	a1,98
ffffffffc0200b98:	00005517          	auipc	a0,0x5
ffffffffc0200b9c:	cf850513          	addi	a0,a0,-776 # ffffffffc0205890 <commands+0x898>
pa2page(uintptr_t pa) {
ffffffffc0200ba0:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0200ba2:	e32ff0ef          	jal	ra,ffffffffc02001d4 <__panic>

ffffffffc0200ba6 <alloc_pages>:
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
ffffffffc0200ba6:	715d                	addi	sp,sp,-80
ffffffffc0200ba8:	e0a2                	sd	s0,64(sp)
ffffffffc0200baa:	fc26                	sd	s1,56(sp)
ffffffffc0200bac:	f84a                	sd	s2,48(sp)
ffffffffc0200bae:	f44e                	sd	s3,40(sp)
ffffffffc0200bb0:	f052                	sd	s4,32(sp)
ffffffffc0200bb2:	ec56                	sd	s5,24(sp)
ffffffffc0200bb4:	e486                	sd	ra,72(sp)
ffffffffc0200bb6:	842a                	mv	s0,a0
ffffffffc0200bb8:	00016497          	auipc	s1,0x16
ffffffffc0200bbc:	92048493          	addi	s1,s1,-1760 # ffffffffc02164d8 <pmm_manager>
        {
            page = pmm_manager->alloc_pages(n);
        }
        local_intr_restore(intr_flag);

        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0200bc0:	4985                	li	s3,1
ffffffffc0200bc2:	00016a17          	auipc	s4,0x16
ffffffffc0200bc6:	8e6a0a13          	addi	s4,s4,-1818 # ffffffffc02164a8 <swap_init_ok>

        extern struct mm_struct *check_mm_struct;
        // cprintf("page %x, call swap_out in alloc_pages %d\n",page, n);
        swap_out(check_mm_struct, n, 0);
ffffffffc0200bca:	0005091b          	sext.w	s2,a0
ffffffffc0200bce:	00016a97          	auipc	s5,0x16
ffffffffc0200bd2:	93aa8a93          	addi	s5,s5,-1734 # ffffffffc0216508 <check_mm_struct>
ffffffffc0200bd6:	a00d                	j	ffffffffc0200bf8 <alloc_pages+0x52>
            page = pmm_manager->alloc_pages(n);
ffffffffc0200bd8:	609c                	ld	a5,0(s1)
ffffffffc0200bda:	6f9c                	ld	a5,24(a5)
ffffffffc0200bdc:	9782                	jalr	a5
        swap_out(check_mm_struct, n, 0);
ffffffffc0200bde:	4601                	li	a2,0
ffffffffc0200be0:	85ca                	mv	a1,s2
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0200be2:	ed0d                	bnez	a0,ffffffffc0200c1c <alloc_pages+0x76>
ffffffffc0200be4:	0289ec63          	bltu	s3,s0,ffffffffc0200c1c <alloc_pages+0x76>
ffffffffc0200be8:	000a2783          	lw	a5,0(s4)
ffffffffc0200bec:	2781                	sext.w	a5,a5
ffffffffc0200bee:	c79d                	beqz	a5,ffffffffc0200c1c <alloc_pages+0x76>
        swap_out(check_mm_struct, n, 0);
ffffffffc0200bf0:	000ab503          	ld	a0,0(s5)
ffffffffc0200bf4:	746020ef          	jal	ra,ffffffffc020333a <swap_out>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200bf8:	100027f3          	csrr	a5,sstatus
ffffffffc0200bfc:	8b89                	andi	a5,a5,2
            page = pmm_manager->alloc_pages(n);
ffffffffc0200bfe:	8522                	mv	a0,s0
ffffffffc0200c00:	dfe1                	beqz	a5,ffffffffc0200bd8 <alloc_pages+0x32>
        intr_disable();
ffffffffc0200c02:	9d1ff0ef          	jal	ra,ffffffffc02005d2 <intr_disable>
ffffffffc0200c06:	609c                	ld	a5,0(s1)
ffffffffc0200c08:	8522                	mv	a0,s0
ffffffffc0200c0a:	6f9c                	ld	a5,24(a5)
ffffffffc0200c0c:	9782                	jalr	a5
ffffffffc0200c0e:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0200c10:	9bdff0ef          	jal	ra,ffffffffc02005cc <intr_enable>
ffffffffc0200c14:	6522                	ld	a0,8(sp)
        swap_out(check_mm_struct, n, 0);
ffffffffc0200c16:	4601                	li	a2,0
ffffffffc0200c18:	85ca                	mv	a1,s2
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0200c1a:	d569                	beqz	a0,ffffffffc0200be4 <alloc_pages+0x3e>
    }
    // cprintf("n %d,get page %x, No %d in alloc_pages\n",n,page,(page-pages));
    return page;
}
ffffffffc0200c1c:	60a6                	ld	ra,72(sp)
ffffffffc0200c1e:	6406                	ld	s0,64(sp)
ffffffffc0200c20:	74e2                	ld	s1,56(sp)
ffffffffc0200c22:	7942                	ld	s2,48(sp)
ffffffffc0200c24:	79a2                	ld	s3,40(sp)
ffffffffc0200c26:	7a02                	ld	s4,32(sp)
ffffffffc0200c28:	6ae2                	ld	s5,24(sp)
ffffffffc0200c2a:	6161                	addi	sp,sp,80
ffffffffc0200c2c:	8082                	ret

ffffffffc0200c2e <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200c2e:	100027f3          	csrr	a5,sstatus
ffffffffc0200c32:	8b89                	andi	a5,a5,2
ffffffffc0200c34:	eb89                	bnez	a5,ffffffffc0200c46 <free_pages+0x18>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0200c36:	00016797          	auipc	a5,0x16
ffffffffc0200c3a:	8a278793          	addi	a5,a5,-1886 # ffffffffc02164d8 <pmm_manager>
ffffffffc0200c3e:	639c                	ld	a5,0(a5)
ffffffffc0200c40:	0207b303          	ld	t1,32(a5)
ffffffffc0200c44:	8302                	jr	t1
void free_pages(struct Page *base, size_t n) {
ffffffffc0200c46:	1101                	addi	sp,sp,-32
ffffffffc0200c48:	ec06                	sd	ra,24(sp)
ffffffffc0200c4a:	e822                	sd	s0,16(sp)
ffffffffc0200c4c:	e426                	sd	s1,8(sp)
ffffffffc0200c4e:	842a                	mv	s0,a0
ffffffffc0200c50:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0200c52:	981ff0ef          	jal	ra,ffffffffc02005d2 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0200c56:	00016797          	auipc	a5,0x16
ffffffffc0200c5a:	88278793          	addi	a5,a5,-1918 # ffffffffc02164d8 <pmm_manager>
ffffffffc0200c5e:	639c                	ld	a5,0(a5)
ffffffffc0200c60:	85a6                	mv	a1,s1
ffffffffc0200c62:	8522                	mv	a0,s0
ffffffffc0200c64:	739c                	ld	a5,32(a5)
ffffffffc0200c66:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200c68:	6442                	ld	s0,16(sp)
ffffffffc0200c6a:	60e2                	ld	ra,24(sp)
ffffffffc0200c6c:	64a2                	ld	s1,8(sp)
ffffffffc0200c6e:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0200c70:	95dff06f          	j	ffffffffc02005cc <intr_enable>

ffffffffc0200c74 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200c74:	100027f3          	csrr	a5,sstatus
ffffffffc0200c78:	8b89                	andi	a5,a5,2
ffffffffc0200c7a:	eb89                	bnez	a5,ffffffffc0200c8c <nr_free_pages+0x18>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0200c7c:	00016797          	auipc	a5,0x16
ffffffffc0200c80:	85c78793          	addi	a5,a5,-1956 # ffffffffc02164d8 <pmm_manager>
ffffffffc0200c84:	639c                	ld	a5,0(a5)
ffffffffc0200c86:	0287b303          	ld	t1,40(a5)
ffffffffc0200c8a:	8302                	jr	t1
size_t nr_free_pages(void) {
ffffffffc0200c8c:	1141                	addi	sp,sp,-16
ffffffffc0200c8e:	e406                	sd	ra,8(sp)
ffffffffc0200c90:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0200c92:	941ff0ef          	jal	ra,ffffffffc02005d2 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0200c96:	00016797          	auipc	a5,0x16
ffffffffc0200c9a:	84278793          	addi	a5,a5,-1982 # ffffffffc02164d8 <pmm_manager>
ffffffffc0200c9e:	639c                	ld	a5,0(a5)
ffffffffc0200ca0:	779c                	ld	a5,40(a5)
ffffffffc0200ca2:	9782                	jalr	a5
ffffffffc0200ca4:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0200ca6:	927ff0ef          	jal	ra,ffffffffc02005cc <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0200caa:	8522                	mv	a0,s0
ffffffffc0200cac:	60a2                	ld	ra,8(sp)
ffffffffc0200cae:	6402                	ld	s0,0(sp)
ffffffffc0200cb0:	0141                	addi	sp,sp,16
ffffffffc0200cb2:	8082                	ret

ffffffffc0200cb4 <get_pte>:
// parameter:
//  pgdir:  the kernel virtual base address of PDT
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0200cb4:	7139                	addi	sp,sp,-64
ffffffffc0200cb6:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0200cb8:	01e5d493          	srli	s1,a1,0x1e
ffffffffc0200cbc:	1ff4f493          	andi	s1,s1,511
ffffffffc0200cc0:	048e                	slli	s1,s1,0x3
ffffffffc0200cc2:	94aa                	add	s1,s1,a0
    if (!(*pdep1 & PTE_V)) {
ffffffffc0200cc4:	6094                	ld	a3,0(s1)
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0200cc6:	f04a                	sd	s2,32(sp)
ffffffffc0200cc8:	ec4e                	sd	s3,24(sp)
ffffffffc0200cca:	e852                	sd	s4,16(sp)
ffffffffc0200ccc:	fc06                	sd	ra,56(sp)
ffffffffc0200cce:	f822                	sd	s0,48(sp)
ffffffffc0200cd0:	e456                	sd	s5,8(sp)
ffffffffc0200cd2:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V)) {
ffffffffc0200cd4:	0016f793          	andi	a5,a3,1
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0200cd8:	892e                	mv	s2,a1
ffffffffc0200cda:	8a32                	mv	s4,a2
ffffffffc0200cdc:	00015997          	auipc	s3,0x15
ffffffffc0200ce0:	7ac98993          	addi	s3,s3,1964 # ffffffffc0216488 <npage>
    if (!(*pdep1 & PTE_V)) {
ffffffffc0200ce4:	e7bd                	bnez	a5,ffffffffc0200d52 <get_pte+0x9e>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc0200ce6:	12060c63          	beqz	a2,ffffffffc0200e1e <get_pte+0x16a>
ffffffffc0200cea:	4505                	li	a0,1
ffffffffc0200cec:	ebbff0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc0200cf0:	842a                	mv	s0,a0
ffffffffc0200cf2:	12050663          	beqz	a0,ffffffffc0200e1e <get_pte+0x16a>
    return page - pages + nbase;
ffffffffc0200cf6:	00015b17          	auipc	s6,0x15
ffffffffc0200cfa:	7fab0b13          	addi	s6,s6,2042 # ffffffffc02164f0 <pages>
ffffffffc0200cfe:	000b3503          	ld	a0,0(s6)
ffffffffc0200d02:	00080ab7          	lui	s5,0x80
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0200d06:	00015997          	auipc	s3,0x15
ffffffffc0200d0a:	78298993          	addi	s3,s3,1922 # ffffffffc0216488 <npage>
ffffffffc0200d0e:	40a40533          	sub	a0,s0,a0
ffffffffc0200d12:	8519                	srai	a0,a0,0x6
ffffffffc0200d14:	9556                	add	a0,a0,s5
ffffffffc0200d16:	0009b703          	ld	a4,0(s3)
ffffffffc0200d1a:	00c51793          	slli	a5,a0,0xc
    return page->ref;
}

static inline void
set_page_ref(struct Page *page, int val) {
    page->ref = val;
ffffffffc0200d1e:	4685                	li	a3,1
ffffffffc0200d20:	c014                	sw	a3,0(s0)
ffffffffc0200d22:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0200d24:	0532                	slli	a0,a0,0xc
ffffffffc0200d26:	14e7f363          	bgeu	a5,a4,ffffffffc0200e6c <get_pte+0x1b8>
ffffffffc0200d2a:	00015797          	auipc	a5,0x15
ffffffffc0200d2e:	7b678793          	addi	a5,a5,1974 # ffffffffc02164e0 <va_pa_offset>
ffffffffc0200d32:	639c                	ld	a5,0(a5)
ffffffffc0200d34:	6605                	lui	a2,0x1
ffffffffc0200d36:	4581                	li	a1,0
ffffffffc0200d38:	953e                	add	a0,a0,a5
ffffffffc0200d3a:	511030ef          	jal	ra,ffffffffc0204a4a <memset>
    return page - pages + nbase;
ffffffffc0200d3e:	000b3683          	ld	a3,0(s6)
ffffffffc0200d42:	40d406b3          	sub	a3,s0,a3
ffffffffc0200d46:	8699                	srai	a3,a3,0x6
ffffffffc0200d48:	96d6                	add	a3,a3,s5
  asm volatile("sfence.vma");
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type) {
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0200d4a:	06aa                	slli	a3,a3,0xa
ffffffffc0200d4c:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0200d50:	e094                	sd	a3,0(s1)
    }
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0200d52:	77fd                	lui	a5,0xfffff
ffffffffc0200d54:	068a                	slli	a3,a3,0x2
ffffffffc0200d56:	0009b703          	ld	a4,0(s3)
ffffffffc0200d5a:	8efd                	and	a3,a3,a5
ffffffffc0200d5c:	00c6d793          	srli	a5,a3,0xc
ffffffffc0200d60:	0ce7f163          	bgeu	a5,a4,ffffffffc0200e22 <get_pte+0x16e>
ffffffffc0200d64:	00015a97          	auipc	s5,0x15
ffffffffc0200d68:	77ca8a93          	addi	s5,s5,1916 # ffffffffc02164e0 <va_pa_offset>
ffffffffc0200d6c:	000ab403          	ld	s0,0(s5)
ffffffffc0200d70:	01595793          	srli	a5,s2,0x15
ffffffffc0200d74:	1ff7f793          	andi	a5,a5,511
ffffffffc0200d78:	96a2                	add	a3,a3,s0
ffffffffc0200d7a:	00379413          	slli	s0,a5,0x3
ffffffffc0200d7e:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V)) {
ffffffffc0200d80:	6014                	ld	a3,0(s0)
ffffffffc0200d82:	0016f793          	andi	a5,a3,1
ffffffffc0200d86:	e3ad                	bnez	a5,ffffffffc0200de8 <get_pte+0x134>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc0200d88:	080a0b63          	beqz	s4,ffffffffc0200e1e <get_pte+0x16a>
ffffffffc0200d8c:	4505                	li	a0,1
ffffffffc0200d8e:	e19ff0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc0200d92:	84aa                	mv	s1,a0
ffffffffc0200d94:	c549                	beqz	a0,ffffffffc0200e1e <get_pte+0x16a>
    return page - pages + nbase;
ffffffffc0200d96:	00015b17          	auipc	s6,0x15
ffffffffc0200d9a:	75ab0b13          	addi	s6,s6,1882 # ffffffffc02164f0 <pages>
ffffffffc0200d9e:	000b3503          	ld	a0,0(s6)
ffffffffc0200da2:	00080a37          	lui	s4,0x80
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0200da6:	0009b703          	ld	a4,0(s3)
ffffffffc0200daa:	40a48533          	sub	a0,s1,a0
ffffffffc0200dae:	8519                	srai	a0,a0,0x6
ffffffffc0200db0:	9552                	add	a0,a0,s4
ffffffffc0200db2:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0200db6:	4685                	li	a3,1
ffffffffc0200db8:	c094                	sw	a3,0(s1)
ffffffffc0200dba:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0200dbc:	0532                	slli	a0,a0,0xc
ffffffffc0200dbe:	08e7fa63          	bgeu	a5,a4,ffffffffc0200e52 <get_pte+0x19e>
ffffffffc0200dc2:	000ab783          	ld	a5,0(s5)
ffffffffc0200dc6:	6605                	lui	a2,0x1
ffffffffc0200dc8:	4581                	li	a1,0
ffffffffc0200dca:	953e                	add	a0,a0,a5
ffffffffc0200dcc:	47f030ef          	jal	ra,ffffffffc0204a4a <memset>
    return page - pages + nbase;
ffffffffc0200dd0:	000b3683          	ld	a3,0(s6)
ffffffffc0200dd4:	40d486b3          	sub	a3,s1,a3
ffffffffc0200dd8:	8699                	srai	a3,a3,0x6
ffffffffc0200dda:	96d2                	add	a3,a3,s4
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0200ddc:	06aa                	slli	a3,a3,0xa
ffffffffc0200dde:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0200de2:	e014                	sd	a3,0(s0)
ffffffffc0200de4:	0009b703          	ld	a4,0(s3)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0200de8:	068a                	slli	a3,a3,0x2
ffffffffc0200dea:	757d                	lui	a0,0xfffff
ffffffffc0200dec:	8ee9                	and	a3,a3,a0
ffffffffc0200dee:	00c6d793          	srli	a5,a3,0xc
ffffffffc0200df2:	04e7f463          	bgeu	a5,a4,ffffffffc0200e3a <get_pte+0x186>
ffffffffc0200df6:	000ab503          	ld	a0,0(s5)
ffffffffc0200dfa:	00c95913          	srli	s2,s2,0xc
ffffffffc0200dfe:	1ff97913          	andi	s2,s2,511
ffffffffc0200e02:	96aa                	add	a3,a3,a0
ffffffffc0200e04:	00391513          	slli	a0,s2,0x3
ffffffffc0200e08:	9536                	add	a0,a0,a3
}
ffffffffc0200e0a:	70e2                	ld	ra,56(sp)
ffffffffc0200e0c:	7442                	ld	s0,48(sp)
ffffffffc0200e0e:	74a2                	ld	s1,40(sp)
ffffffffc0200e10:	7902                	ld	s2,32(sp)
ffffffffc0200e12:	69e2                	ld	s3,24(sp)
ffffffffc0200e14:	6a42                	ld	s4,16(sp)
ffffffffc0200e16:	6aa2                	ld	s5,8(sp)
ffffffffc0200e18:	6b02                	ld	s6,0(sp)
ffffffffc0200e1a:	6121                	addi	sp,sp,64
ffffffffc0200e1c:	8082                	ret
            return NULL;
ffffffffc0200e1e:	4501                	li	a0,0
ffffffffc0200e20:	b7ed                	j	ffffffffc0200e0a <get_pte+0x156>
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0200e22:	00005617          	auipc	a2,0x5
ffffffffc0200e26:	a1660613          	addi	a2,a2,-1514 # ffffffffc0205838 <commands+0x840>
ffffffffc0200e2a:	0e400593          	li	a1,228
ffffffffc0200e2e:	00005517          	auipc	a0,0x5
ffffffffc0200e32:	a3250513          	addi	a0,a0,-1486 # ffffffffc0205860 <commands+0x868>
ffffffffc0200e36:	b9eff0ef          	jal	ra,ffffffffc02001d4 <__panic>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0200e3a:	00005617          	auipc	a2,0x5
ffffffffc0200e3e:	9fe60613          	addi	a2,a2,-1538 # ffffffffc0205838 <commands+0x840>
ffffffffc0200e42:	0ef00593          	li	a1,239
ffffffffc0200e46:	00005517          	auipc	a0,0x5
ffffffffc0200e4a:	a1a50513          	addi	a0,a0,-1510 # ffffffffc0205860 <commands+0x868>
ffffffffc0200e4e:	b86ff0ef          	jal	ra,ffffffffc02001d4 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0200e52:	86aa                	mv	a3,a0
ffffffffc0200e54:	00005617          	auipc	a2,0x5
ffffffffc0200e58:	9e460613          	addi	a2,a2,-1564 # ffffffffc0205838 <commands+0x840>
ffffffffc0200e5c:	0ec00593          	li	a1,236
ffffffffc0200e60:	00005517          	auipc	a0,0x5
ffffffffc0200e64:	a0050513          	addi	a0,a0,-1536 # ffffffffc0205860 <commands+0x868>
ffffffffc0200e68:	b6cff0ef          	jal	ra,ffffffffc02001d4 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0200e6c:	86aa                	mv	a3,a0
ffffffffc0200e6e:	00005617          	auipc	a2,0x5
ffffffffc0200e72:	9ca60613          	addi	a2,a2,-1590 # ffffffffc0205838 <commands+0x840>
ffffffffc0200e76:	0e100593          	li	a1,225
ffffffffc0200e7a:	00005517          	auipc	a0,0x5
ffffffffc0200e7e:	9e650513          	addi	a0,a0,-1562 # ffffffffc0205860 <commands+0x868>
ffffffffc0200e82:	b52ff0ef          	jal	ra,ffffffffc02001d4 <__panic>

ffffffffc0200e86 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc0200e86:	1141                	addi	sp,sp,-16
ffffffffc0200e88:	e022                	sd	s0,0(sp)
ffffffffc0200e8a:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0200e8c:	4601                	li	a2,0
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc0200e8e:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0200e90:	e25ff0ef          	jal	ra,ffffffffc0200cb4 <get_pte>
    if (ptep_store != NULL) {
ffffffffc0200e94:	c011                	beqz	s0,ffffffffc0200e98 <get_page+0x12>
        *ptep_store = ptep;
ffffffffc0200e96:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc0200e98:	c511                	beqz	a0,ffffffffc0200ea4 <get_page+0x1e>
ffffffffc0200e9a:	611c                	ld	a5,0(a0)
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0200e9c:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc0200e9e:	0017f713          	andi	a4,a5,1
ffffffffc0200ea2:	e709                	bnez	a4,ffffffffc0200eac <get_page+0x26>
}
ffffffffc0200ea4:	60a2                	ld	ra,8(sp)
ffffffffc0200ea6:	6402                	ld	s0,0(sp)
ffffffffc0200ea8:	0141                	addi	sp,sp,16
ffffffffc0200eaa:	8082                	ret
    if (PPN(pa) >= npage) {
ffffffffc0200eac:	00015717          	auipc	a4,0x15
ffffffffc0200eb0:	5dc70713          	addi	a4,a4,1500 # ffffffffc0216488 <npage>
ffffffffc0200eb4:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc0200eb6:	078a                	slli	a5,a5,0x2
ffffffffc0200eb8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0200eba:	02e7f063          	bgeu	a5,a4,ffffffffc0200eda <get_page+0x54>
    return &pages[PPN(pa) - nbase];
ffffffffc0200ebe:	00015717          	auipc	a4,0x15
ffffffffc0200ec2:	63270713          	addi	a4,a4,1586 # ffffffffc02164f0 <pages>
ffffffffc0200ec6:	6308                	ld	a0,0(a4)
ffffffffc0200ec8:	60a2                	ld	ra,8(sp)
ffffffffc0200eca:	6402                	ld	s0,0(sp)
ffffffffc0200ecc:	fff80737          	lui	a4,0xfff80
ffffffffc0200ed0:	97ba                	add	a5,a5,a4
ffffffffc0200ed2:	079a                	slli	a5,a5,0x6
ffffffffc0200ed4:	953e                	add	a0,a0,a5
ffffffffc0200ed6:	0141                	addi	sp,sp,16
ffffffffc0200ed8:	8082                	ret
ffffffffc0200eda:	cb1ff0ef          	jal	ra,ffffffffc0200b8a <pa2page.part.4>

ffffffffc0200ede <page_remove>:
    }
}

// page_remove - free an Page which is related linear address la and has an
// validated pte
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc0200ede:	1101                	addi	sp,sp,-32
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0200ee0:	4601                	li	a2,0
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc0200ee2:	e426                	sd	s1,8(sp)
ffffffffc0200ee4:	ec06                	sd	ra,24(sp)
ffffffffc0200ee6:	e822                	sd	s0,16(sp)
ffffffffc0200ee8:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0200eea:	dcbff0ef          	jal	ra,ffffffffc0200cb4 <get_pte>
    if (ptep != NULL) {
ffffffffc0200eee:	c511                	beqz	a0,ffffffffc0200efa <page_remove+0x1c>
    if (*ptep & PTE_V) {  //(1) check if this page table entry is
ffffffffc0200ef0:	611c                	ld	a5,0(a0)
ffffffffc0200ef2:	842a                	mv	s0,a0
ffffffffc0200ef4:	0017f713          	andi	a4,a5,1
ffffffffc0200ef8:	e711                	bnez	a4,ffffffffc0200f04 <page_remove+0x26>
        page_remove_pte(pgdir, la, ptep);
    }
}
ffffffffc0200efa:	60e2                	ld	ra,24(sp)
ffffffffc0200efc:	6442                	ld	s0,16(sp)
ffffffffc0200efe:	64a2                	ld	s1,8(sp)
ffffffffc0200f00:	6105                	addi	sp,sp,32
ffffffffc0200f02:	8082                	ret
    if (PPN(pa) >= npage) {
ffffffffc0200f04:	00015717          	auipc	a4,0x15
ffffffffc0200f08:	58470713          	addi	a4,a4,1412 # ffffffffc0216488 <npage>
ffffffffc0200f0c:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc0200f0e:	078a                	slli	a5,a5,0x2
ffffffffc0200f10:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0200f12:	02e7fe63          	bgeu	a5,a4,ffffffffc0200f4e <page_remove+0x70>
    return &pages[PPN(pa) - nbase];
ffffffffc0200f16:	00015717          	auipc	a4,0x15
ffffffffc0200f1a:	5da70713          	addi	a4,a4,1498 # ffffffffc02164f0 <pages>
ffffffffc0200f1e:	6308                	ld	a0,0(a4)
ffffffffc0200f20:	fff80737          	lui	a4,0xfff80
ffffffffc0200f24:	97ba                	add	a5,a5,a4
ffffffffc0200f26:	079a                	slli	a5,a5,0x6
ffffffffc0200f28:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0200f2a:	411c                	lw	a5,0(a0)
ffffffffc0200f2c:	fff7871b          	addiw	a4,a5,-1
ffffffffc0200f30:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0200f32:	cb11                	beqz	a4,ffffffffc0200f46 <page_remove+0x68>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc0200f34:	00043023          	sd	zero,0(s0)
// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la) {
    // flush_tlb();
    // The flush_tlb flush the entire TLB, is there any better way?
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0200f38:	12048073          	sfence.vma	s1
}
ffffffffc0200f3c:	60e2                	ld	ra,24(sp)
ffffffffc0200f3e:	6442                	ld	s0,16(sp)
ffffffffc0200f40:	64a2                	ld	s1,8(sp)
ffffffffc0200f42:	6105                	addi	sp,sp,32
ffffffffc0200f44:	8082                	ret
            free_page(page);
ffffffffc0200f46:	4585                	li	a1,1
ffffffffc0200f48:	ce7ff0ef          	jal	ra,ffffffffc0200c2e <free_pages>
ffffffffc0200f4c:	b7e5                	j	ffffffffc0200f34 <page_remove+0x56>
ffffffffc0200f4e:	c3dff0ef          	jal	ra,ffffffffc0200b8a <pa2page.part.4>

ffffffffc0200f52 <page_insert>:
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0200f52:	7179                	addi	sp,sp,-48
ffffffffc0200f54:	e44e                	sd	s3,8(sp)
ffffffffc0200f56:	89b2                	mv	s3,a2
ffffffffc0200f58:	f022                	sd	s0,32(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0200f5a:	4605                	li	a2,1
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0200f5c:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0200f5e:	85ce                	mv	a1,s3
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0200f60:	ec26                	sd	s1,24(sp)
ffffffffc0200f62:	f406                	sd	ra,40(sp)
ffffffffc0200f64:	e84a                	sd	s2,16(sp)
ffffffffc0200f66:	e052                	sd	s4,0(sp)
ffffffffc0200f68:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0200f6a:	d4bff0ef          	jal	ra,ffffffffc0200cb4 <get_pte>
    if (ptep == NULL) {
ffffffffc0200f6e:	cd49                	beqz	a0,ffffffffc0201008 <page_insert+0xb6>
    page->ref += 1;
ffffffffc0200f70:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V) {
ffffffffc0200f72:	611c                	ld	a5,0(a0)
ffffffffc0200f74:	892a                	mv	s2,a0
ffffffffc0200f76:	0016871b          	addiw	a4,a3,1
ffffffffc0200f7a:	c018                	sw	a4,0(s0)
ffffffffc0200f7c:	0017f713          	andi	a4,a5,1
ffffffffc0200f80:	ef05                	bnez	a4,ffffffffc0200fb8 <page_insert+0x66>
ffffffffc0200f82:	00015797          	auipc	a5,0x15
ffffffffc0200f86:	56e78793          	addi	a5,a5,1390 # ffffffffc02164f0 <pages>
ffffffffc0200f8a:	6398                	ld	a4,0(a5)
    return page - pages + nbase;
ffffffffc0200f8c:	8c19                	sub	s0,s0,a4
ffffffffc0200f8e:	000806b7          	lui	a3,0x80
ffffffffc0200f92:	8419                	srai	s0,s0,0x6
ffffffffc0200f94:	9436                	add	s0,s0,a3
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0200f96:	042a                	slli	s0,s0,0xa
ffffffffc0200f98:	8c45                	or	s0,s0,s1
ffffffffc0200f9a:	00146413          	ori	s0,s0,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc0200f9e:	00893023          	sd	s0,0(s2)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0200fa2:	12098073          	sfence.vma	s3
    return 0;
ffffffffc0200fa6:	4501                	li	a0,0
}
ffffffffc0200fa8:	70a2                	ld	ra,40(sp)
ffffffffc0200faa:	7402                	ld	s0,32(sp)
ffffffffc0200fac:	64e2                	ld	s1,24(sp)
ffffffffc0200fae:	6942                	ld	s2,16(sp)
ffffffffc0200fb0:	69a2                	ld	s3,8(sp)
ffffffffc0200fb2:	6a02                	ld	s4,0(sp)
ffffffffc0200fb4:	6145                	addi	sp,sp,48
ffffffffc0200fb6:	8082                	ret
    if (PPN(pa) >= npage) {
ffffffffc0200fb8:	00015717          	auipc	a4,0x15
ffffffffc0200fbc:	4d070713          	addi	a4,a4,1232 # ffffffffc0216488 <npage>
ffffffffc0200fc0:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc0200fc2:	078a                	slli	a5,a5,0x2
ffffffffc0200fc4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0200fc6:	04e7f363          	bgeu	a5,a4,ffffffffc020100c <page_insert+0xba>
    return &pages[PPN(pa) - nbase];
ffffffffc0200fca:	00015a17          	auipc	s4,0x15
ffffffffc0200fce:	526a0a13          	addi	s4,s4,1318 # ffffffffc02164f0 <pages>
ffffffffc0200fd2:	000a3703          	ld	a4,0(s4)
ffffffffc0200fd6:	fff80537          	lui	a0,0xfff80
ffffffffc0200fda:	953e                	add	a0,a0,a5
ffffffffc0200fdc:	051a                	slli	a0,a0,0x6
ffffffffc0200fde:	953a                	add	a0,a0,a4
        if (p == page) {
ffffffffc0200fe0:	00a40a63          	beq	s0,a0,ffffffffc0200ff4 <page_insert+0xa2>
    page->ref -= 1;
ffffffffc0200fe4:	411c                	lw	a5,0(a0)
ffffffffc0200fe6:	fff7869b          	addiw	a3,a5,-1
ffffffffc0200fea:	c114                	sw	a3,0(a0)
        if (page_ref(page) ==
ffffffffc0200fec:	c691                	beqz	a3,ffffffffc0200ff8 <page_insert+0xa6>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0200fee:	12098073          	sfence.vma	s3
ffffffffc0200ff2:	bf69                	j	ffffffffc0200f8c <page_insert+0x3a>
ffffffffc0200ff4:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0200ff6:	bf59                	j	ffffffffc0200f8c <page_insert+0x3a>
            free_page(page);
ffffffffc0200ff8:	4585                	li	a1,1
ffffffffc0200ffa:	c35ff0ef          	jal	ra,ffffffffc0200c2e <free_pages>
ffffffffc0200ffe:	000a3703          	ld	a4,0(s4)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0201002:	12098073          	sfence.vma	s3
ffffffffc0201006:	b759                	j	ffffffffc0200f8c <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc0201008:	5571                	li	a0,-4
ffffffffc020100a:	bf79                	j	ffffffffc0200fa8 <page_insert+0x56>
ffffffffc020100c:	b7fff0ef          	jal	ra,ffffffffc0200b8a <pa2page.part.4>

ffffffffc0201010 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0201010:	00006797          	auipc	a5,0x6
ffffffffc0201014:	b4878793          	addi	a5,a5,-1208 # ffffffffc0206b58 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201018:	638c                	ld	a1,0(a5)
void pmm_init(void) {
ffffffffc020101a:	715d                	addi	sp,sp,-80
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020101c:	00005517          	auipc	a0,0x5
ffffffffc0201020:	89c50513          	addi	a0,a0,-1892 # ffffffffc02058b8 <commands+0x8c0>
void pmm_init(void) {
ffffffffc0201024:	e486                	sd	ra,72(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0201026:	00015717          	auipc	a4,0x15
ffffffffc020102a:	4af73923          	sd	a5,1202(a4) # ffffffffc02164d8 <pmm_manager>
void pmm_init(void) {
ffffffffc020102e:	e0a2                	sd	s0,64(sp)
ffffffffc0201030:	fc26                	sd	s1,56(sp)
ffffffffc0201032:	f84a                	sd	s2,48(sp)
ffffffffc0201034:	f44e                	sd	s3,40(sp)
ffffffffc0201036:	f052                	sd	s4,32(sp)
ffffffffc0201038:	ec56                	sd	s5,24(sp)
ffffffffc020103a:	e85a                	sd	s6,16(sp)
ffffffffc020103c:	e45e                	sd	s7,8(sp)
ffffffffc020103e:	e062                	sd	s8,0(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0201040:	00015417          	auipc	s0,0x15
ffffffffc0201044:	49840413          	addi	s0,s0,1176 # ffffffffc02164d8 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201048:	888ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    pmm_manager->init();
ffffffffc020104c:	601c                	ld	a5,0(s0)
ffffffffc020104e:	00015497          	auipc	s1,0x15
ffffffffc0201052:	43a48493          	addi	s1,s1,1082 # ffffffffc0216488 <npage>
ffffffffc0201056:	00015917          	auipc	s2,0x15
ffffffffc020105a:	49a90913          	addi	s2,s2,1178 # ffffffffc02164f0 <pages>
ffffffffc020105e:	679c                	ld	a5,8(a5)
ffffffffc0201060:	9782                	jalr	a5
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0201062:	57f5                	li	a5,-3
ffffffffc0201064:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc0201066:	00005517          	auipc	a0,0x5
ffffffffc020106a:	86a50513          	addi	a0,a0,-1942 # ffffffffc02058d0 <commands+0x8d8>
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc020106e:	00015717          	auipc	a4,0x15
ffffffffc0201072:	46f73923          	sd	a5,1138(a4) # ffffffffc02164e0 <va_pa_offset>
    cprintf("physcial memory map:\n");
ffffffffc0201076:	85aff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc020107a:	46c5                	li	a3,17
ffffffffc020107c:	06ee                	slli	a3,a3,0x1b
ffffffffc020107e:	40100613          	li	a2,1025
ffffffffc0201082:	16fd                	addi	a3,a3,-1
ffffffffc0201084:	0656                	slli	a2,a2,0x15
ffffffffc0201086:	07e005b7          	lui	a1,0x7e00
ffffffffc020108a:	00005517          	auipc	a0,0x5
ffffffffc020108e:	85e50513          	addi	a0,a0,-1954 # ffffffffc02058e8 <commands+0x8f0>
ffffffffc0201092:	83eff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201096:	777d                	lui	a4,0xfffff
ffffffffc0201098:	00016797          	auipc	a5,0x16
ffffffffc020109c:	56778793          	addi	a5,a5,1383 # ffffffffc02175ff <end+0xfff>
ffffffffc02010a0:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc02010a2:	00088737          	lui	a4,0x88
ffffffffc02010a6:	00015697          	auipc	a3,0x15
ffffffffc02010aa:	3ee6b123          	sd	a4,994(a3) # ffffffffc0216488 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02010ae:	00015717          	auipc	a4,0x15
ffffffffc02010b2:	44f73123          	sd	a5,1090(a4) # ffffffffc02164f0 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02010b6:	4701                	li	a4,0
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02010b8:	4685                	li	a3,1
ffffffffc02010ba:	fff80837          	lui	a6,0xfff80
ffffffffc02010be:	a019                	j	ffffffffc02010c4 <pmm_init+0xb4>
ffffffffc02010c0:	00093783          	ld	a5,0(s2)
        SetPageReserved(pages + i);
ffffffffc02010c4:	00671613          	slli	a2,a4,0x6
ffffffffc02010c8:	97b2                	add	a5,a5,a2
ffffffffc02010ca:	07a1                	addi	a5,a5,8
ffffffffc02010cc:	40d7b02f          	amoor.d	zero,a3,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02010d0:	6090                	ld	a2,0(s1)
ffffffffc02010d2:	0705                	addi	a4,a4,1
ffffffffc02010d4:	010607b3          	add	a5,a2,a6
ffffffffc02010d8:	fef764e3          	bltu	a4,a5,ffffffffc02010c0 <pmm_init+0xb0>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02010dc:	00093503          	ld	a0,0(s2)
ffffffffc02010e0:	fe0007b7          	lui	a5,0xfe000
ffffffffc02010e4:	00661693          	slli	a3,a2,0x6
ffffffffc02010e8:	97aa                	add	a5,a5,a0
ffffffffc02010ea:	96be                	add	a3,a3,a5
ffffffffc02010ec:	c02007b7          	lui	a5,0xc0200
ffffffffc02010f0:	7af6eb63          	bltu	a3,a5,ffffffffc02018a6 <pmm_init+0x896>
ffffffffc02010f4:	00015997          	auipc	s3,0x15
ffffffffc02010f8:	3ec98993          	addi	s3,s3,1004 # ffffffffc02164e0 <va_pa_offset>
ffffffffc02010fc:	0009b583          	ld	a1,0(s3)
    if (freemem < mem_end) {
ffffffffc0201100:	47c5                	li	a5,17
ffffffffc0201102:	07ee                	slli	a5,a5,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201104:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end) {
ffffffffc0201106:	02f6f763          	bgeu	a3,a5,ffffffffc0201134 <pmm_init+0x124>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc020110a:	6585                	lui	a1,0x1
ffffffffc020110c:	15fd                	addi	a1,a1,-1
ffffffffc020110e:	96ae                	add	a3,a3,a1
    if (PPN(pa) >= npage) {
ffffffffc0201110:	00c6d713          	srli	a4,a3,0xc
ffffffffc0201114:	48c77863          	bgeu	a4,a2,ffffffffc02015a4 <pmm_init+0x594>
    pmm_manager->init_memmap(base, n);
ffffffffc0201118:	6010                	ld	a2,0(s0)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc020111a:	75fd                	lui	a1,0xfffff
ffffffffc020111c:	8eed                	and	a3,a3,a1
    return &pages[PPN(pa) - nbase];
ffffffffc020111e:	9742                	add	a4,a4,a6
    pmm_manager->init_memmap(base, n);
ffffffffc0201120:	6a10                	ld	a2,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201122:	40d786b3          	sub	a3,a5,a3
ffffffffc0201126:	071a                	slli	a4,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc0201128:	00c6d593          	srli	a1,a3,0xc
ffffffffc020112c:	953a                	add	a0,a0,a4
ffffffffc020112e:	9602                	jalr	a2
ffffffffc0201130:	0009b583          	ld	a1,0(s3)
    cprintf("vapaofset is %llu\n",va_pa_offset);
ffffffffc0201134:	00005517          	auipc	a0,0x5
ffffffffc0201138:	80450513          	addi	a0,a0,-2044 # ffffffffc0205938 <commands+0x940>
ffffffffc020113c:	f95fe0ef          	jal	ra,ffffffffc02000d0 <cprintf>

    return page;
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201140:	601c                	ld	a5,0(s0)
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc0201142:	00015417          	auipc	s0,0x15
ffffffffc0201146:	33e40413          	addi	s0,s0,830 # ffffffffc0216480 <boot_pgdir>
    pmm_manager->check();
ffffffffc020114a:	7b9c                	ld	a5,48(a5)
ffffffffc020114c:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc020114e:	00005517          	auipc	a0,0x5
ffffffffc0201152:	80250513          	addi	a0,a0,-2046 # ffffffffc0205950 <commands+0x958>
ffffffffc0201156:	f7bfe0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc020115a:	00009697          	auipc	a3,0x9
ffffffffc020115e:	ea668693          	addi	a3,a3,-346 # ffffffffc020a000 <boot_page_table_sv39>
ffffffffc0201162:	00015797          	auipc	a5,0x15
ffffffffc0201166:	30d7bf23          	sd	a3,798(a5) # ffffffffc0216480 <boot_pgdir>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc020116a:	c02007b7          	lui	a5,0xc0200
ffffffffc020116e:	10f6e8e3          	bltu	a3,a5,ffffffffc0201a7e <pmm_init+0xa6e>
ffffffffc0201172:	0009b783          	ld	a5,0(s3)
ffffffffc0201176:	8e9d                	sub	a3,a3,a5
ffffffffc0201178:	00015797          	auipc	a5,0x15
ffffffffc020117c:	36d7b823          	sd	a3,880(a5) # ffffffffc02164e8 <boot_cr3>
    // assert(npage <= KMEMSIZE / PGSIZE);
    // The memory starts at 2GB in RISC-V
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store=nr_free_pages();
ffffffffc0201180:	af5ff0ef          	jal	ra,ffffffffc0200c74 <nr_free_pages>

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0201184:	6098                	ld	a4,0(s1)
ffffffffc0201186:	c80007b7          	lui	a5,0xc8000
ffffffffc020118a:	83b1                	srli	a5,a5,0xc
    nr_free_store=nr_free_pages();
ffffffffc020118c:	8a2a                	mv	s4,a0
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc020118e:	0ce7e8e3          	bltu	a5,a4,ffffffffc0201a5e <pmm_init+0xa4e>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc0201192:	6008                	ld	a0,0(s0)
ffffffffc0201194:	44050263          	beqz	a0,ffffffffc02015d8 <pmm_init+0x5c8>
ffffffffc0201198:	03451793          	slli	a5,a0,0x34
ffffffffc020119c:	42079e63          	bnez	a5,ffffffffc02015d8 <pmm_init+0x5c8>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc02011a0:	4601                	li	a2,0
ffffffffc02011a2:	4581                	li	a1,0
ffffffffc02011a4:	ce3ff0ef          	jal	ra,ffffffffc0200e86 <get_page>
ffffffffc02011a8:	78051b63          	bnez	a0,ffffffffc020193e <pmm_init+0x92e>

    struct Page *p1, *p2;
    p1 = alloc_page();
ffffffffc02011ac:	4505                	li	a0,1
ffffffffc02011ae:	9f9ff0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc02011b2:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc02011b4:	6008                	ld	a0,0(s0)
ffffffffc02011b6:	4681                	li	a3,0
ffffffffc02011b8:	4601                	li	a2,0
ffffffffc02011ba:	85d6                	mv	a1,s5
ffffffffc02011bc:	d97ff0ef          	jal	ra,ffffffffc0200f52 <page_insert>
ffffffffc02011c0:	7a051f63          	bnez	a0,ffffffffc020197e <pmm_init+0x96e>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc02011c4:	6008                	ld	a0,0(s0)
ffffffffc02011c6:	4601                	li	a2,0
ffffffffc02011c8:	4581                	li	a1,0
ffffffffc02011ca:	aebff0ef          	jal	ra,ffffffffc0200cb4 <get_pte>
ffffffffc02011ce:	78050863          	beqz	a0,ffffffffc020195e <pmm_init+0x94e>
    assert(pte2page(*ptep) == p1);
ffffffffc02011d2:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc02011d4:	0017f713          	andi	a4,a5,1
ffffffffc02011d8:	3e070463          	beqz	a4,ffffffffc02015c0 <pmm_init+0x5b0>
    if (PPN(pa) >= npage) {
ffffffffc02011dc:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02011de:	078a                	slli	a5,a5,0x2
ffffffffc02011e0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02011e2:	3ce7f163          	bgeu	a5,a4,ffffffffc02015a4 <pmm_init+0x594>
    return &pages[PPN(pa) - nbase];
ffffffffc02011e6:	00093683          	ld	a3,0(s2)
ffffffffc02011ea:	fff80637          	lui	a2,0xfff80
ffffffffc02011ee:	97b2                	add	a5,a5,a2
ffffffffc02011f0:	079a                	slli	a5,a5,0x6
ffffffffc02011f2:	97b6                	add	a5,a5,a3
ffffffffc02011f4:	72fa9563          	bne	s5,a5,ffffffffc020191e <pmm_init+0x90e>
    assert(page_ref(p1) == 1);
ffffffffc02011f8:	000aab83          	lw	s7,0(s5)
ffffffffc02011fc:	4785                	li	a5,1
ffffffffc02011fe:	70fb9063          	bne	s7,a5,ffffffffc02018fe <pmm_init+0x8ee>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc0201202:	6008                	ld	a0,0(s0)
ffffffffc0201204:	76fd                	lui	a3,0xfffff
ffffffffc0201206:	611c                	ld	a5,0(a0)
ffffffffc0201208:	078a                	slli	a5,a5,0x2
ffffffffc020120a:	8ff5                	and	a5,a5,a3
ffffffffc020120c:	00c7d613          	srli	a2,a5,0xc
ffffffffc0201210:	66e67e63          	bgeu	a2,a4,ffffffffc020188c <pmm_init+0x87c>
ffffffffc0201214:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201218:	97e2                	add	a5,a5,s8
ffffffffc020121a:	0007bb03          	ld	s6,0(a5) # ffffffffc8000000 <end+0x7de9a00>
ffffffffc020121e:	0b0a                	slli	s6,s6,0x2
ffffffffc0201220:	00db7b33          	and	s6,s6,a3
ffffffffc0201224:	00cb5793          	srli	a5,s6,0xc
ffffffffc0201228:	56e7f863          	bgeu	a5,a4,ffffffffc0201798 <pmm_init+0x788>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc020122c:	4601                	li	a2,0
ffffffffc020122e:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201230:	9b62                	add	s6,s6,s8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0201232:	a83ff0ef          	jal	ra,ffffffffc0200cb4 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201236:	0b21                	addi	s6,s6,8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0201238:	55651063          	bne	a0,s6,ffffffffc0201778 <pmm_init+0x768>

    p2 = alloc_page();
ffffffffc020123c:	4505                	li	a0,1
ffffffffc020123e:	969ff0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc0201242:	8b2a                	mv	s6,a0
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0201244:	6008                	ld	a0,0(s0)
ffffffffc0201246:	46d1                	li	a3,20
ffffffffc0201248:	6605                	lui	a2,0x1
ffffffffc020124a:	85da                	mv	a1,s6
ffffffffc020124c:	d07ff0ef          	jal	ra,ffffffffc0200f52 <page_insert>
ffffffffc0201250:	50051463          	bnez	a0,ffffffffc0201758 <pmm_init+0x748>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0201254:	6008                	ld	a0,0(s0)
ffffffffc0201256:	4601                	li	a2,0
ffffffffc0201258:	6585                	lui	a1,0x1
ffffffffc020125a:	a5bff0ef          	jal	ra,ffffffffc0200cb4 <get_pte>
ffffffffc020125e:	4c050d63          	beqz	a0,ffffffffc0201738 <pmm_init+0x728>
    assert(*ptep & PTE_U);
ffffffffc0201262:	611c                	ld	a5,0(a0)
ffffffffc0201264:	0107f713          	andi	a4,a5,16
ffffffffc0201268:	4a070863          	beqz	a4,ffffffffc0201718 <pmm_init+0x708>
    assert(*ptep & PTE_W);
ffffffffc020126c:	8b91                	andi	a5,a5,4
ffffffffc020126e:	48078563          	beqz	a5,ffffffffc02016f8 <pmm_init+0x6e8>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc0201272:	6008                	ld	a0,0(s0)
ffffffffc0201274:	611c                	ld	a5,0(a0)
ffffffffc0201276:	8bc1                	andi	a5,a5,16
ffffffffc0201278:	46078063          	beqz	a5,ffffffffc02016d8 <pmm_init+0x6c8>
    assert(page_ref(p2) == 1);
ffffffffc020127c:	000b2783          	lw	a5,0(s6)
ffffffffc0201280:	43779c63          	bne	a5,s7,ffffffffc02016b8 <pmm_init+0x6a8>

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc0201284:	4681                	li	a3,0
ffffffffc0201286:	6605                	lui	a2,0x1
ffffffffc0201288:	85d6                	mv	a1,s5
ffffffffc020128a:	cc9ff0ef          	jal	ra,ffffffffc0200f52 <page_insert>
ffffffffc020128e:	40051563          	bnez	a0,ffffffffc0201698 <pmm_init+0x688>
    assert(page_ref(p1) == 2);
ffffffffc0201292:	000aa703          	lw	a4,0(s5)
ffffffffc0201296:	4789                	li	a5,2
ffffffffc0201298:	3ef71063          	bne	a4,a5,ffffffffc0201678 <pmm_init+0x668>
    assert(page_ref(p2) == 0);
ffffffffc020129c:	000b2783          	lw	a5,0(s6)
ffffffffc02012a0:	3a079c63          	bnez	a5,ffffffffc0201658 <pmm_init+0x648>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc02012a4:	6008                	ld	a0,0(s0)
ffffffffc02012a6:	4601                	li	a2,0
ffffffffc02012a8:	6585                	lui	a1,0x1
ffffffffc02012aa:	a0bff0ef          	jal	ra,ffffffffc0200cb4 <get_pte>
ffffffffc02012ae:	38050563          	beqz	a0,ffffffffc0201638 <pmm_init+0x628>
    assert(pte2page(*ptep) == p1);
ffffffffc02012b2:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc02012b4:	00177793          	andi	a5,a4,1
ffffffffc02012b8:	30078463          	beqz	a5,ffffffffc02015c0 <pmm_init+0x5b0>
    if (PPN(pa) >= npage) {
ffffffffc02012bc:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02012be:	00271793          	slli	a5,a4,0x2
ffffffffc02012c2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02012c4:	2ed7f063          	bgeu	a5,a3,ffffffffc02015a4 <pmm_init+0x594>
    return &pages[PPN(pa) - nbase];
ffffffffc02012c8:	00093683          	ld	a3,0(s2)
ffffffffc02012cc:	fff80637          	lui	a2,0xfff80
ffffffffc02012d0:	97b2                	add	a5,a5,a2
ffffffffc02012d2:	079a                	slli	a5,a5,0x6
ffffffffc02012d4:	97b6                	add	a5,a5,a3
ffffffffc02012d6:	32fa9163          	bne	s5,a5,ffffffffc02015f8 <pmm_init+0x5e8>
    assert((*ptep & PTE_U) == 0);
ffffffffc02012da:	8b41                	andi	a4,a4,16
ffffffffc02012dc:	70071163          	bnez	a4,ffffffffc02019de <pmm_init+0x9ce>

    page_remove(boot_pgdir, 0x0);
ffffffffc02012e0:	6008                	ld	a0,0(s0)
ffffffffc02012e2:	4581                	li	a1,0
ffffffffc02012e4:	bfbff0ef          	jal	ra,ffffffffc0200ede <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc02012e8:	000aa703          	lw	a4,0(s5)
ffffffffc02012ec:	4785                	li	a5,1
ffffffffc02012ee:	6cf71863          	bne	a4,a5,ffffffffc02019be <pmm_init+0x9ae>
    assert(page_ref(p2) == 0);
ffffffffc02012f2:	000b2783          	lw	a5,0(s6)
ffffffffc02012f6:	6a079463          	bnez	a5,ffffffffc020199e <pmm_init+0x98e>

    page_remove(boot_pgdir, PGSIZE);
ffffffffc02012fa:	6008                	ld	a0,0(s0)
ffffffffc02012fc:	6585                	lui	a1,0x1
ffffffffc02012fe:	be1ff0ef          	jal	ra,ffffffffc0200ede <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0201302:	000aa783          	lw	a5,0(s5)
ffffffffc0201306:	50079363          	bnez	a5,ffffffffc020180c <pmm_init+0x7fc>
    assert(page_ref(p2) == 0);
ffffffffc020130a:	000b2783          	lw	a5,0(s6)
ffffffffc020130e:	4c079f63          	bnez	a5,ffffffffc02017ec <pmm_init+0x7dc>

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc0201312:	00043b03          	ld	s6,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc0201316:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201318:	000b3783          	ld	a5,0(s6)
ffffffffc020131c:	078a                	slli	a5,a5,0x2
ffffffffc020131e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201320:	28e7f263          	bgeu	a5,a4,ffffffffc02015a4 <pmm_init+0x594>
    return &pages[PPN(pa) - nbase];
ffffffffc0201324:	fff806b7          	lui	a3,0xfff80
ffffffffc0201328:	00093503          	ld	a0,0(s2)
ffffffffc020132c:	97b6                	add	a5,a5,a3
ffffffffc020132e:	079a                	slli	a5,a5,0x6
ffffffffc0201330:	00f506b3          	add	a3,a0,a5
ffffffffc0201334:	4290                	lw	a2,0(a3)
ffffffffc0201336:	4685                	li	a3,1
ffffffffc0201338:	48d61a63          	bne	a2,a3,ffffffffc02017cc <pmm_init+0x7bc>
    return page - pages + nbase;
ffffffffc020133c:	8799                	srai	a5,a5,0x6
ffffffffc020133e:	00080ab7          	lui	s5,0x80
ffffffffc0201342:	97d6                	add	a5,a5,s5
    return KADDR(page2pa(page));
ffffffffc0201344:	00c79693          	slli	a3,a5,0xc
ffffffffc0201348:	82b1                	srli	a3,a3,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc020134a:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc020134c:	46e6f363          	bgeu	a3,a4,ffffffffc02017b2 <pmm_init+0x7a2>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0201350:	0009b683          	ld	a3,0(s3)
ffffffffc0201354:	97b6                	add	a5,a5,a3
    return pa2page(PDE_ADDR(pde));
ffffffffc0201356:	639c                	ld	a5,0(a5)
ffffffffc0201358:	078a                	slli	a5,a5,0x2
ffffffffc020135a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020135c:	24e7f463          	bgeu	a5,a4,ffffffffc02015a4 <pmm_init+0x594>
    return &pages[PPN(pa) - nbase];
ffffffffc0201360:	415787b3          	sub	a5,a5,s5
ffffffffc0201364:	079a                	slli	a5,a5,0x6
ffffffffc0201366:	953e                	add	a0,a0,a5
ffffffffc0201368:	4585                	li	a1,1
ffffffffc020136a:	8c5ff0ef          	jal	ra,ffffffffc0200c2e <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc020136e:	000b3783          	ld	a5,0(s6)
    if (PPN(pa) >= npage) {
ffffffffc0201372:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201374:	078a                	slli	a5,a5,0x2
ffffffffc0201376:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201378:	22e7f663          	bgeu	a5,a4,ffffffffc02015a4 <pmm_init+0x594>
    return &pages[PPN(pa) - nbase];
ffffffffc020137c:	00093503          	ld	a0,0(s2)
ffffffffc0201380:	415787b3          	sub	a5,a5,s5
ffffffffc0201384:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd1[0]));
ffffffffc0201386:	953e                	add	a0,a0,a5
ffffffffc0201388:	4585                	li	a1,1
ffffffffc020138a:	8a5ff0ef          	jal	ra,ffffffffc0200c2e <free_pages>
    boot_pgdir[0] = 0;
ffffffffc020138e:	601c                	ld	a5,0(s0)
ffffffffc0201390:	0007b023          	sd	zero,0(a5)
  asm volatile("sfence.vma");
ffffffffc0201394:	12000073          	sfence.vma
    flush_tlb();

    assert(nr_free_store==nr_free_pages());
ffffffffc0201398:	8ddff0ef          	jal	ra,ffffffffc0200c74 <nr_free_pages>
ffffffffc020139c:	68aa1163          	bne	s4,a0,ffffffffc0201a1e <pmm_init+0xa0e>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc02013a0:	00005517          	auipc	a0,0x5
ffffffffc02013a4:	8d850513          	addi	a0,a0,-1832 # ffffffffc0205c78 <commands+0xc80>
ffffffffc02013a8:	d29fe0ef          	jal	ra,ffffffffc02000d0 <cprintf>
static void check_boot_pgdir(void) {
    size_t nr_free_store;
    pte_t *ptep;
    int i;

    nr_free_store=nr_free_pages();
ffffffffc02013ac:	8c9ff0ef          	jal	ra,ffffffffc0200c74 <nr_free_pages>

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc02013b0:	6098                	ld	a4,0(s1)
ffffffffc02013b2:	c02007b7          	lui	a5,0xc0200
    nr_free_store=nr_free_pages();
ffffffffc02013b6:	8a2a                	mv	s4,a0
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc02013b8:	00c71693          	slli	a3,a4,0xc
ffffffffc02013bc:	18d7f563          	bgeu	a5,a3,ffffffffc0201546 <pmm_init+0x536>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02013c0:	83b1                	srli	a5,a5,0xc
ffffffffc02013c2:	6008                	ld	a0,0(s0)
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc02013c4:	c0200ab7          	lui	s5,0xc0200
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02013c8:	1ae7f163          	bgeu	a5,a4,ffffffffc020156a <pmm_init+0x55a>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc02013cc:	7bfd                	lui	s7,0xfffff
ffffffffc02013ce:	6b05                	lui	s6,0x1
ffffffffc02013d0:	a029                	j	ffffffffc02013da <pmm_init+0x3ca>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02013d2:	00cad713          	srli	a4,s5,0xc
ffffffffc02013d6:	18f77a63          	bgeu	a4,a5,ffffffffc020156a <pmm_init+0x55a>
ffffffffc02013da:	0009b583          	ld	a1,0(s3)
ffffffffc02013de:	4601                	li	a2,0
ffffffffc02013e0:	95d6                	add	a1,a1,s5
ffffffffc02013e2:	8d3ff0ef          	jal	ra,ffffffffc0200cb4 <get_pte>
ffffffffc02013e6:	16050263          	beqz	a0,ffffffffc020154a <pmm_init+0x53a>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc02013ea:	611c                	ld	a5,0(a0)
ffffffffc02013ec:	078a                	slli	a5,a5,0x2
ffffffffc02013ee:	0177f7b3          	and	a5,a5,s7
ffffffffc02013f2:	19579963          	bne	a5,s5,ffffffffc0201584 <pmm_init+0x574>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc02013f6:	609c                	ld	a5,0(s1)
ffffffffc02013f8:	9ada                	add	s5,s5,s6
ffffffffc02013fa:	6008                	ld	a0,0(s0)
ffffffffc02013fc:	00c79713          	slli	a4,a5,0xc
ffffffffc0201400:	fceae9e3          	bltu	s5,a4,ffffffffc02013d2 <pmm_init+0x3c2>
    }

    assert(boot_pgdir[0] == 0);
ffffffffc0201404:	611c                	ld	a5,0(a0)
ffffffffc0201406:	62079c63          	bnez	a5,ffffffffc0201a3e <pmm_init+0xa2e>

    struct Page *p;
    p = alloc_page();
ffffffffc020140a:	4505                	li	a0,1
ffffffffc020140c:	f9aff0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc0201410:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0201412:	6008                	ld	a0,0(s0)
ffffffffc0201414:	4699                	li	a3,6
ffffffffc0201416:	10000613          	li	a2,256
ffffffffc020141a:	85d6                	mv	a1,s5
ffffffffc020141c:	b37ff0ef          	jal	ra,ffffffffc0200f52 <page_insert>
ffffffffc0201420:	1e051c63          	bnez	a0,ffffffffc0201618 <pmm_init+0x608>
    assert(page_ref(p) == 1);
ffffffffc0201424:	000aa703          	lw	a4,0(s5) # ffffffffc0200000 <kern_entry>
ffffffffc0201428:	4785                	li	a5,1
ffffffffc020142a:	44f71163          	bne	a4,a5,ffffffffc020186c <pmm_init+0x85c>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc020142e:	6008                	ld	a0,0(s0)
ffffffffc0201430:	6b05                	lui	s6,0x1
ffffffffc0201432:	4699                	li	a3,6
ffffffffc0201434:	100b0613          	addi	a2,s6,256 # 1100 <BASE_ADDRESS-0xffffffffc01fef00>
ffffffffc0201438:	85d6                	mv	a1,s5
ffffffffc020143a:	b19ff0ef          	jal	ra,ffffffffc0200f52 <page_insert>
ffffffffc020143e:	40051763          	bnez	a0,ffffffffc020184c <pmm_init+0x83c>
    assert(page_ref(p) == 2);
ffffffffc0201442:	000aa703          	lw	a4,0(s5)
ffffffffc0201446:	4789                	li	a5,2
ffffffffc0201448:	3ef71263          	bne	a4,a5,ffffffffc020182c <pmm_init+0x81c>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc020144c:	00005597          	auipc	a1,0x5
ffffffffc0201450:	96458593          	addi	a1,a1,-1692 # ffffffffc0205db0 <commands+0xdb8>
ffffffffc0201454:	10000513          	li	a0,256
ffffffffc0201458:	598030ef          	jal	ra,ffffffffc02049f0 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc020145c:	100b0593          	addi	a1,s6,256
ffffffffc0201460:	10000513          	li	a0,256
ffffffffc0201464:	59e030ef          	jal	ra,ffffffffc0204a02 <strcmp>
ffffffffc0201468:	44051b63          	bnez	a0,ffffffffc02018be <pmm_init+0x8ae>
    return page - pages + nbase;
ffffffffc020146c:	00093683          	ld	a3,0(s2)
ffffffffc0201470:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0201474:	5b7d                	li	s6,-1
    return page - pages + nbase;
ffffffffc0201476:	40da86b3          	sub	a3,s5,a3
ffffffffc020147a:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc020147c:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc020147e:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0201480:	00cb5b13          	srli	s6,s6,0xc
ffffffffc0201484:	0166f733          	and	a4,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc0201488:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020148a:	10f77f63          	bgeu	a4,a5,ffffffffc02015a8 <pmm_init+0x598>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc020148e:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0201492:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0201496:	96be                	add	a3,a3,a5
ffffffffc0201498:	10068023          	sb	zero,256(a3) # fffffffffff80100 <end+0x3fd69b00>
    assert(strlen((const char *)0x100) == 0);
ffffffffc020149c:	510030ef          	jal	ra,ffffffffc02049ac <strlen>
ffffffffc02014a0:	54051f63          	bnez	a0,ffffffffc02019fe <pmm_init+0x9ee>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc02014a4:	00043b83          	ld	s7,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc02014a8:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02014aa:	000bb683          	ld	a3,0(s7) # fffffffffffff000 <end+0x3fde8a00>
ffffffffc02014ae:	068a                	slli	a3,a3,0x2
ffffffffc02014b0:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage) {
ffffffffc02014b2:	0ef6f963          	bgeu	a3,a5,ffffffffc02015a4 <pmm_init+0x594>
    return KADDR(page2pa(page));
ffffffffc02014b6:	0166fb33          	and	s6,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc02014ba:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02014bc:	0efb7663          	bgeu	s6,a5,ffffffffc02015a8 <pmm_init+0x598>
ffffffffc02014c0:	0009b983          	ld	s3,0(s3)
    free_page(p);
ffffffffc02014c4:	4585                	li	a1,1
ffffffffc02014c6:	8556                	mv	a0,s5
ffffffffc02014c8:	99b6                	add	s3,s3,a3
ffffffffc02014ca:	f64ff0ef          	jal	ra,ffffffffc0200c2e <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc02014ce:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage) {
ffffffffc02014d2:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02014d4:	078a                	slli	a5,a5,0x2
ffffffffc02014d6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02014d8:	0ce7f663          	bgeu	a5,a4,ffffffffc02015a4 <pmm_init+0x594>
    return &pages[PPN(pa) - nbase];
ffffffffc02014dc:	00093503          	ld	a0,0(s2)
ffffffffc02014e0:	fff809b7          	lui	s3,0xfff80
ffffffffc02014e4:	97ce                	add	a5,a5,s3
ffffffffc02014e6:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd0[0]));
ffffffffc02014e8:	953e                	add	a0,a0,a5
ffffffffc02014ea:	4585                	li	a1,1
ffffffffc02014ec:	f42ff0ef          	jal	ra,ffffffffc0200c2e <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc02014f0:	000bb783          	ld	a5,0(s7)
    if (PPN(pa) >= npage) {
ffffffffc02014f4:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02014f6:	078a                	slli	a5,a5,0x2
ffffffffc02014f8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02014fa:	0ae7f563          	bgeu	a5,a4,ffffffffc02015a4 <pmm_init+0x594>
    return &pages[PPN(pa) - nbase];
ffffffffc02014fe:	00093503          	ld	a0,0(s2)
ffffffffc0201502:	97ce                	add	a5,a5,s3
ffffffffc0201504:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd1[0]));
ffffffffc0201506:	953e                	add	a0,a0,a5
ffffffffc0201508:	4585                	li	a1,1
ffffffffc020150a:	f24ff0ef          	jal	ra,ffffffffc0200c2e <free_pages>
    boot_pgdir[0] = 0;
ffffffffc020150e:	601c                	ld	a5,0(s0)
ffffffffc0201510:	0007b023          	sd	zero,0(a5) # ffffffffc0200000 <kern_entry>
  asm volatile("sfence.vma");
ffffffffc0201514:	12000073          	sfence.vma
    flush_tlb();

    assert(nr_free_store==nr_free_pages());
ffffffffc0201518:	f5cff0ef          	jal	ra,ffffffffc0200c74 <nr_free_pages>
ffffffffc020151c:	3caa1163          	bne	s4,a0,ffffffffc02018de <pmm_init+0x8ce>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0201520:	00005517          	auipc	a0,0x5
ffffffffc0201524:	90850513          	addi	a0,a0,-1784 # ffffffffc0205e28 <commands+0xe30>
ffffffffc0201528:	ba9fe0ef          	jal	ra,ffffffffc02000d0 <cprintf>
}
ffffffffc020152c:	6406                	ld	s0,64(sp)
ffffffffc020152e:	60a6                	ld	ra,72(sp)
ffffffffc0201530:	74e2                	ld	s1,56(sp)
ffffffffc0201532:	7942                	ld	s2,48(sp)
ffffffffc0201534:	79a2                	ld	s3,40(sp)
ffffffffc0201536:	7a02                	ld	s4,32(sp)
ffffffffc0201538:	6ae2                	ld	s5,24(sp)
ffffffffc020153a:	6b42                	ld	s6,16(sp)
ffffffffc020153c:	6ba2                	ld	s7,8(sp)
ffffffffc020153e:	6c02                	ld	s8,0(sp)
ffffffffc0201540:	6161                	addi	sp,sp,80
    kmalloc_init();
ffffffffc0201542:	4640106f          	j	ffffffffc02029a6 <kmalloc_init>
ffffffffc0201546:	6008                	ld	a0,0(s0)
ffffffffc0201548:	bd75                	j	ffffffffc0201404 <pmm_init+0x3f4>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc020154a:	00004697          	auipc	a3,0x4
ffffffffc020154e:	74e68693          	addi	a3,a3,1870 # ffffffffc0205c98 <commands+0xca0>
ffffffffc0201552:	00004617          	auipc	a2,0x4
ffffffffc0201556:	43e60613          	addi	a2,a2,1086 # ffffffffc0205990 <commands+0x998>
ffffffffc020155a:	19d00593          	li	a1,413
ffffffffc020155e:	00004517          	auipc	a0,0x4
ffffffffc0201562:	30250513          	addi	a0,a0,770 # ffffffffc0205860 <commands+0x868>
ffffffffc0201566:	c6ffe0ef          	jal	ra,ffffffffc02001d4 <__panic>
ffffffffc020156a:	86d6                	mv	a3,s5
ffffffffc020156c:	00004617          	auipc	a2,0x4
ffffffffc0201570:	2cc60613          	addi	a2,a2,716 # ffffffffc0205838 <commands+0x840>
ffffffffc0201574:	19d00593          	li	a1,413
ffffffffc0201578:	00004517          	auipc	a0,0x4
ffffffffc020157c:	2e850513          	addi	a0,a0,744 # ffffffffc0205860 <commands+0x868>
ffffffffc0201580:	c55fe0ef          	jal	ra,ffffffffc02001d4 <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0201584:	00004697          	auipc	a3,0x4
ffffffffc0201588:	75468693          	addi	a3,a3,1876 # ffffffffc0205cd8 <commands+0xce0>
ffffffffc020158c:	00004617          	auipc	a2,0x4
ffffffffc0201590:	40460613          	addi	a2,a2,1028 # ffffffffc0205990 <commands+0x998>
ffffffffc0201594:	19e00593          	li	a1,414
ffffffffc0201598:	00004517          	auipc	a0,0x4
ffffffffc020159c:	2c850513          	addi	a0,a0,712 # ffffffffc0205860 <commands+0x868>
ffffffffc02015a0:	c35fe0ef          	jal	ra,ffffffffc02001d4 <__panic>
ffffffffc02015a4:	de6ff0ef          	jal	ra,ffffffffc0200b8a <pa2page.part.4>
    return KADDR(page2pa(page));
ffffffffc02015a8:	00004617          	auipc	a2,0x4
ffffffffc02015ac:	29060613          	addi	a2,a2,656 # ffffffffc0205838 <commands+0x840>
ffffffffc02015b0:	06900593          	li	a1,105
ffffffffc02015b4:	00004517          	auipc	a0,0x4
ffffffffc02015b8:	2dc50513          	addi	a0,a0,732 # ffffffffc0205890 <commands+0x898>
ffffffffc02015bc:	c19fe0ef          	jal	ra,ffffffffc02001d4 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc02015c0:	00004617          	auipc	a2,0x4
ffffffffc02015c4:	4a860613          	addi	a2,a2,1192 # ffffffffc0205a68 <commands+0xa70>
ffffffffc02015c8:	07400593          	li	a1,116
ffffffffc02015cc:	00004517          	auipc	a0,0x4
ffffffffc02015d0:	2c450513          	addi	a0,a0,708 # ffffffffc0205890 <commands+0x898>
ffffffffc02015d4:	c01fe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc02015d8:	00004697          	auipc	a3,0x4
ffffffffc02015dc:	3d068693          	addi	a3,a3,976 # ffffffffc02059a8 <commands+0x9b0>
ffffffffc02015e0:	00004617          	auipc	a2,0x4
ffffffffc02015e4:	3b060613          	addi	a2,a2,944 # ffffffffc0205990 <commands+0x998>
ffffffffc02015e8:	16100593          	li	a1,353
ffffffffc02015ec:	00004517          	auipc	a0,0x4
ffffffffc02015f0:	27450513          	addi	a0,a0,628 # ffffffffc0205860 <commands+0x868>
ffffffffc02015f4:	be1fe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc02015f8:	00004697          	auipc	a3,0x4
ffffffffc02015fc:	49868693          	addi	a3,a3,1176 # ffffffffc0205a90 <commands+0xa98>
ffffffffc0201600:	00004617          	auipc	a2,0x4
ffffffffc0201604:	39060613          	addi	a2,a2,912 # ffffffffc0205990 <commands+0x998>
ffffffffc0201608:	17d00593          	li	a1,381
ffffffffc020160c:	00004517          	auipc	a0,0x4
ffffffffc0201610:	25450513          	addi	a0,a0,596 # ffffffffc0205860 <commands+0x868>
ffffffffc0201614:	bc1fe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0201618:	00004697          	auipc	a3,0x4
ffffffffc020161c:	6f068693          	addi	a3,a3,1776 # ffffffffc0205d08 <commands+0xd10>
ffffffffc0201620:	00004617          	auipc	a2,0x4
ffffffffc0201624:	37060613          	addi	a2,a2,880 # ffffffffc0205990 <commands+0x998>
ffffffffc0201628:	1a500593          	li	a1,421
ffffffffc020162c:	00004517          	auipc	a0,0x4
ffffffffc0201630:	23450513          	addi	a0,a0,564 # ffffffffc0205860 <commands+0x868>
ffffffffc0201634:	ba1fe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0201638:	00004697          	auipc	a3,0x4
ffffffffc020163c:	4e868693          	addi	a3,a3,1256 # ffffffffc0205b20 <commands+0xb28>
ffffffffc0201640:	00004617          	auipc	a2,0x4
ffffffffc0201644:	35060613          	addi	a2,a2,848 # ffffffffc0205990 <commands+0x998>
ffffffffc0201648:	17c00593          	li	a1,380
ffffffffc020164c:	00004517          	auipc	a0,0x4
ffffffffc0201650:	21450513          	addi	a0,a0,532 # ffffffffc0205860 <commands+0x868>
ffffffffc0201654:	b81fe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0201658:	00004697          	auipc	a3,0x4
ffffffffc020165c:	59068693          	addi	a3,a3,1424 # ffffffffc0205be8 <commands+0xbf0>
ffffffffc0201660:	00004617          	auipc	a2,0x4
ffffffffc0201664:	33060613          	addi	a2,a2,816 # ffffffffc0205990 <commands+0x998>
ffffffffc0201668:	17b00593          	li	a1,379
ffffffffc020166c:	00004517          	auipc	a0,0x4
ffffffffc0201670:	1f450513          	addi	a0,a0,500 # ffffffffc0205860 <commands+0x868>
ffffffffc0201674:	b61fe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0201678:	00004697          	auipc	a3,0x4
ffffffffc020167c:	55868693          	addi	a3,a3,1368 # ffffffffc0205bd0 <commands+0xbd8>
ffffffffc0201680:	00004617          	auipc	a2,0x4
ffffffffc0201684:	31060613          	addi	a2,a2,784 # ffffffffc0205990 <commands+0x998>
ffffffffc0201688:	17a00593          	li	a1,378
ffffffffc020168c:	00004517          	auipc	a0,0x4
ffffffffc0201690:	1d450513          	addi	a0,a0,468 # ffffffffc0205860 <commands+0x868>
ffffffffc0201694:	b41fe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc0201698:	00004697          	auipc	a3,0x4
ffffffffc020169c:	50868693          	addi	a3,a3,1288 # ffffffffc0205ba0 <commands+0xba8>
ffffffffc02016a0:	00004617          	auipc	a2,0x4
ffffffffc02016a4:	2f060613          	addi	a2,a2,752 # ffffffffc0205990 <commands+0x998>
ffffffffc02016a8:	17900593          	li	a1,377
ffffffffc02016ac:	00004517          	auipc	a0,0x4
ffffffffc02016b0:	1b450513          	addi	a0,a0,436 # ffffffffc0205860 <commands+0x868>
ffffffffc02016b4:	b21fe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc02016b8:	00004697          	auipc	a3,0x4
ffffffffc02016bc:	4d068693          	addi	a3,a3,1232 # ffffffffc0205b88 <commands+0xb90>
ffffffffc02016c0:	00004617          	auipc	a2,0x4
ffffffffc02016c4:	2d060613          	addi	a2,a2,720 # ffffffffc0205990 <commands+0x998>
ffffffffc02016c8:	17700593          	li	a1,375
ffffffffc02016cc:	00004517          	auipc	a0,0x4
ffffffffc02016d0:	19450513          	addi	a0,a0,404 # ffffffffc0205860 <commands+0x868>
ffffffffc02016d4:	b01fe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc02016d8:	00004697          	auipc	a3,0x4
ffffffffc02016dc:	49868693          	addi	a3,a3,1176 # ffffffffc0205b70 <commands+0xb78>
ffffffffc02016e0:	00004617          	auipc	a2,0x4
ffffffffc02016e4:	2b060613          	addi	a2,a2,688 # ffffffffc0205990 <commands+0x998>
ffffffffc02016e8:	17600593          	li	a1,374
ffffffffc02016ec:	00004517          	auipc	a0,0x4
ffffffffc02016f0:	17450513          	addi	a0,a0,372 # ffffffffc0205860 <commands+0x868>
ffffffffc02016f4:	ae1fe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(*ptep & PTE_W);
ffffffffc02016f8:	00004697          	auipc	a3,0x4
ffffffffc02016fc:	46868693          	addi	a3,a3,1128 # ffffffffc0205b60 <commands+0xb68>
ffffffffc0201700:	00004617          	auipc	a2,0x4
ffffffffc0201704:	29060613          	addi	a2,a2,656 # ffffffffc0205990 <commands+0x998>
ffffffffc0201708:	17500593          	li	a1,373
ffffffffc020170c:	00004517          	auipc	a0,0x4
ffffffffc0201710:	15450513          	addi	a0,a0,340 # ffffffffc0205860 <commands+0x868>
ffffffffc0201714:	ac1fe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(*ptep & PTE_U);
ffffffffc0201718:	00004697          	auipc	a3,0x4
ffffffffc020171c:	43868693          	addi	a3,a3,1080 # ffffffffc0205b50 <commands+0xb58>
ffffffffc0201720:	00004617          	auipc	a2,0x4
ffffffffc0201724:	27060613          	addi	a2,a2,624 # ffffffffc0205990 <commands+0x998>
ffffffffc0201728:	17400593          	li	a1,372
ffffffffc020172c:	00004517          	auipc	a0,0x4
ffffffffc0201730:	13450513          	addi	a0,a0,308 # ffffffffc0205860 <commands+0x868>
ffffffffc0201734:	aa1fe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0201738:	00004697          	auipc	a3,0x4
ffffffffc020173c:	3e868693          	addi	a3,a3,1000 # ffffffffc0205b20 <commands+0xb28>
ffffffffc0201740:	00004617          	auipc	a2,0x4
ffffffffc0201744:	25060613          	addi	a2,a2,592 # ffffffffc0205990 <commands+0x998>
ffffffffc0201748:	17300593          	li	a1,371
ffffffffc020174c:	00004517          	auipc	a0,0x4
ffffffffc0201750:	11450513          	addi	a0,a0,276 # ffffffffc0205860 <commands+0x868>
ffffffffc0201754:	a81fe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0201758:	00004697          	auipc	a3,0x4
ffffffffc020175c:	39068693          	addi	a3,a3,912 # ffffffffc0205ae8 <commands+0xaf0>
ffffffffc0201760:	00004617          	auipc	a2,0x4
ffffffffc0201764:	23060613          	addi	a2,a2,560 # ffffffffc0205990 <commands+0x998>
ffffffffc0201768:	17200593          	li	a1,370
ffffffffc020176c:	00004517          	auipc	a0,0x4
ffffffffc0201770:	0f450513          	addi	a0,a0,244 # ffffffffc0205860 <commands+0x868>
ffffffffc0201774:	a61fe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0201778:	00004697          	auipc	a3,0x4
ffffffffc020177c:	34868693          	addi	a3,a3,840 # ffffffffc0205ac0 <commands+0xac8>
ffffffffc0201780:	00004617          	auipc	a2,0x4
ffffffffc0201784:	21060613          	addi	a2,a2,528 # ffffffffc0205990 <commands+0x998>
ffffffffc0201788:	16f00593          	li	a1,367
ffffffffc020178c:	00004517          	auipc	a0,0x4
ffffffffc0201790:	0d450513          	addi	a0,a0,212 # ffffffffc0205860 <commands+0x868>
ffffffffc0201794:	a41fe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201798:	86da                	mv	a3,s6
ffffffffc020179a:	00004617          	auipc	a2,0x4
ffffffffc020179e:	09e60613          	addi	a2,a2,158 # ffffffffc0205838 <commands+0x840>
ffffffffc02017a2:	16e00593          	li	a1,366
ffffffffc02017a6:	00004517          	auipc	a0,0x4
ffffffffc02017aa:	0ba50513          	addi	a0,a0,186 # ffffffffc0205860 <commands+0x868>
ffffffffc02017ae:	a27fe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    return KADDR(page2pa(page));
ffffffffc02017b2:	86be                	mv	a3,a5
ffffffffc02017b4:	00004617          	auipc	a2,0x4
ffffffffc02017b8:	08460613          	addi	a2,a2,132 # ffffffffc0205838 <commands+0x840>
ffffffffc02017bc:	06900593          	li	a1,105
ffffffffc02017c0:	00004517          	auipc	a0,0x4
ffffffffc02017c4:	0d050513          	addi	a0,a0,208 # ffffffffc0205890 <commands+0x898>
ffffffffc02017c8:	a0dfe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc02017cc:	00004697          	auipc	a3,0x4
ffffffffc02017d0:	46468693          	addi	a3,a3,1124 # ffffffffc0205c30 <commands+0xc38>
ffffffffc02017d4:	00004617          	auipc	a2,0x4
ffffffffc02017d8:	1bc60613          	addi	a2,a2,444 # ffffffffc0205990 <commands+0x998>
ffffffffc02017dc:	18800593          	li	a1,392
ffffffffc02017e0:	00004517          	auipc	a0,0x4
ffffffffc02017e4:	08050513          	addi	a0,a0,128 # ffffffffc0205860 <commands+0x868>
ffffffffc02017e8:	9edfe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02017ec:	00004697          	auipc	a3,0x4
ffffffffc02017f0:	3fc68693          	addi	a3,a3,1020 # ffffffffc0205be8 <commands+0xbf0>
ffffffffc02017f4:	00004617          	auipc	a2,0x4
ffffffffc02017f8:	19c60613          	addi	a2,a2,412 # ffffffffc0205990 <commands+0x998>
ffffffffc02017fc:	18600593          	li	a1,390
ffffffffc0201800:	00004517          	auipc	a0,0x4
ffffffffc0201804:	06050513          	addi	a0,a0,96 # ffffffffc0205860 <commands+0x868>
ffffffffc0201808:	9cdfe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc020180c:	00004697          	auipc	a3,0x4
ffffffffc0201810:	40c68693          	addi	a3,a3,1036 # ffffffffc0205c18 <commands+0xc20>
ffffffffc0201814:	00004617          	auipc	a2,0x4
ffffffffc0201818:	17c60613          	addi	a2,a2,380 # ffffffffc0205990 <commands+0x998>
ffffffffc020181c:	18500593          	li	a1,389
ffffffffc0201820:	00004517          	auipc	a0,0x4
ffffffffc0201824:	04050513          	addi	a0,a0,64 # ffffffffc0205860 <commands+0x868>
ffffffffc0201828:	9adfe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(page_ref(p) == 2);
ffffffffc020182c:	00004697          	auipc	a3,0x4
ffffffffc0201830:	56c68693          	addi	a3,a3,1388 # ffffffffc0205d98 <commands+0xda0>
ffffffffc0201834:	00004617          	auipc	a2,0x4
ffffffffc0201838:	15c60613          	addi	a2,a2,348 # ffffffffc0205990 <commands+0x998>
ffffffffc020183c:	1a800593          	li	a1,424
ffffffffc0201840:	00004517          	auipc	a0,0x4
ffffffffc0201844:	02050513          	addi	a0,a0,32 # ffffffffc0205860 <commands+0x868>
ffffffffc0201848:	98dfe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc020184c:	00004697          	auipc	a3,0x4
ffffffffc0201850:	50c68693          	addi	a3,a3,1292 # ffffffffc0205d58 <commands+0xd60>
ffffffffc0201854:	00004617          	auipc	a2,0x4
ffffffffc0201858:	13c60613          	addi	a2,a2,316 # ffffffffc0205990 <commands+0x998>
ffffffffc020185c:	1a700593          	li	a1,423
ffffffffc0201860:	00004517          	auipc	a0,0x4
ffffffffc0201864:	00050513          	mv	a0,a0
ffffffffc0201868:	96dfe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(page_ref(p) == 1);
ffffffffc020186c:	00004697          	auipc	a3,0x4
ffffffffc0201870:	4d468693          	addi	a3,a3,1236 # ffffffffc0205d40 <commands+0xd48>
ffffffffc0201874:	00004617          	auipc	a2,0x4
ffffffffc0201878:	11c60613          	addi	a2,a2,284 # ffffffffc0205990 <commands+0x998>
ffffffffc020187c:	1a600593          	li	a1,422
ffffffffc0201880:	00004517          	auipc	a0,0x4
ffffffffc0201884:	fe050513          	addi	a0,a0,-32 # ffffffffc0205860 <commands+0x868>
ffffffffc0201888:	94dfe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc020188c:	86be                	mv	a3,a5
ffffffffc020188e:	00004617          	auipc	a2,0x4
ffffffffc0201892:	faa60613          	addi	a2,a2,-86 # ffffffffc0205838 <commands+0x840>
ffffffffc0201896:	16d00593          	li	a1,365
ffffffffc020189a:	00004517          	auipc	a0,0x4
ffffffffc020189e:	fc650513          	addi	a0,a0,-58 # ffffffffc0205860 <commands+0x868>
ffffffffc02018a2:	933fe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02018a6:	00004617          	auipc	a2,0x4
ffffffffc02018aa:	06a60613          	addi	a2,a2,106 # ffffffffc0205910 <commands+0x918>
ffffffffc02018ae:	07f00593          	li	a1,127
ffffffffc02018b2:	00004517          	auipc	a0,0x4
ffffffffc02018b6:	fae50513          	addi	a0,a0,-82 # ffffffffc0205860 <commands+0x868>
ffffffffc02018ba:	91bfe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02018be:	00004697          	auipc	a3,0x4
ffffffffc02018c2:	50a68693          	addi	a3,a3,1290 # ffffffffc0205dc8 <commands+0xdd0>
ffffffffc02018c6:	00004617          	auipc	a2,0x4
ffffffffc02018ca:	0ca60613          	addi	a2,a2,202 # ffffffffc0205990 <commands+0x998>
ffffffffc02018ce:	1ac00593          	li	a1,428
ffffffffc02018d2:	00004517          	auipc	a0,0x4
ffffffffc02018d6:	f8e50513          	addi	a0,a0,-114 # ffffffffc0205860 <commands+0x868>
ffffffffc02018da:	8fbfe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc02018de:	00004697          	auipc	a3,0x4
ffffffffc02018e2:	37a68693          	addi	a3,a3,890 # ffffffffc0205c58 <commands+0xc60>
ffffffffc02018e6:	00004617          	auipc	a2,0x4
ffffffffc02018ea:	0aa60613          	addi	a2,a2,170 # ffffffffc0205990 <commands+0x998>
ffffffffc02018ee:	1b800593          	li	a1,440
ffffffffc02018f2:	00004517          	auipc	a0,0x4
ffffffffc02018f6:	f6e50513          	addi	a0,a0,-146 # ffffffffc0205860 <commands+0x868>
ffffffffc02018fa:	8dbfe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02018fe:	00004697          	auipc	a3,0x4
ffffffffc0201902:	1aa68693          	addi	a3,a3,426 # ffffffffc0205aa8 <commands+0xab0>
ffffffffc0201906:	00004617          	auipc	a2,0x4
ffffffffc020190a:	08a60613          	addi	a2,a2,138 # ffffffffc0205990 <commands+0x998>
ffffffffc020190e:	16b00593          	li	a1,363
ffffffffc0201912:	00004517          	auipc	a0,0x4
ffffffffc0201916:	f4e50513          	addi	a0,a0,-178 # ffffffffc0205860 <commands+0x868>
ffffffffc020191a:	8bbfe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc020191e:	00004697          	auipc	a3,0x4
ffffffffc0201922:	17268693          	addi	a3,a3,370 # ffffffffc0205a90 <commands+0xa98>
ffffffffc0201926:	00004617          	auipc	a2,0x4
ffffffffc020192a:	06a60613          	addi	a2,a2,106 # ffffffffc0205990 <commands+0x998>
ffffffffc020192e:	16a00593          	li	a1,362
ffffffffc0201932:	00004517          	auipc	a0,0x4
ffffffffc0201936:	f2e50513          	addi	a0,a0,-210 # ffffffffc0205860 <commands+0x868>
ffffffffc020193a:	89bfe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc020193e:	00004697          	auipc	a3,0x4
ffffffffc0201942:	0a268693          	addi	a3,a3,162 # ffffffffc02059e0 <commands+0x9e8>
ffffffffc0201946:	00004617          	auipc	a2,0x4
ffffffffc020194a:	04a60613          	addi	a2,a2,74 # ffffffffc0205990 <commands+0x998>
ffffffffc020194e:	16200593          	li	a1,354
ffffffffc0201952:	00004517          	auipc	a0,0x4
ffffffffc0201956:	f0e50513          	addi	a0,a0,-242 # ffffffffc0205860 <commands+0x868>
ffffffffc020195a:	87bfe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc020195e:	00004697          	auipc	a3,0x4
ffffffffc0201962:	0da68693          	addi	a3,a3,218 # ffffffffc0205a38 <commands+0xa40>
ffffffffc0201966:	00004617          	auipc	a2,0x4
ffffffffc020196a:	02a60613          	addi	a2,a2,42 # ffffffffc0205990 <commands+0x998>
ffffffffc020196e:	16900593          	li	a1,361
ffffffffc0201972:	00004517          	auipc	a0,0x4
ffffffffc0201976:	eee50513          	addi	a0,a0,-274 # ffffffffc0205860 <commands+0x868>
ffffffffc020197a:	85bfe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc020197e:	00004697          	auipc	a3,0x4
ffffffffc0201982:	08a68693          	addi	a3,a3,138 # ffffffffc0205a08 <commands+0xa10>
ffffffffc0201986:	00004617          	auipc	a2,0x4
ffffffffc020198a:	00a60613          	addi	a2,a2,10 # ffffffffc0205990 <commands+0x998>
ffffffffc020198e:	16600593          	li	a1,358
ffffffffc0201992:	00004517          	auipc	a0,0x4
ffffffffc0201996:	ece50513          	addi	a0,a0,-306 # ffffffffc0205860 <commands+0x868>
ffffffffc020199a:	83bfe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020199e:	00004697          	auipc	a3,0x4
ffffffffc02019a2:	24a68693          	addi	a3,a3,586 # ffffffffc0205be8 <commands+0xbf0>
ffffffffc02019a6:	00004617          	auipc	a2,0x4
ffffffffc02019aa:	fea60613          	addi	a2,a2,-22 # ffffffffc0205990 <commands+0x998>
ffffffffc02019ae:	18200593          	li	a1,386
ffffffffc02019b2:	00004517          	auipc	a0,0x4
ffffffffc02019b6:	eae50513          	addi	a0,a0,-338 # ffffffffc0205860 <commands+0x868>
ffffffffc02019ba:	81bfe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02019be:	00004697          	auipc	a3,0x4
ffffffffc02019c2:	0ea68693          	addi	a3,a3,234 # ffffffffc0205aa8 <commands+0xab0>
ffffffffc02019c6:	00004617          	auipc	a2,0x4
ffffffffc02019ca:	fca60613          	addi	a2,a2,-54 # ffffffffc0205990 <commands+0x998>
ffffffffc02019ce:	18100593          	li	a1,385
ffffffffc02019d2:	00004517          	auipc	a0,0x4
ffffffffc02019d6:	e8e50513          	addi	a0,a0,-370 # ffffffffc0205860 <commands+0x868>
ffffffffc02019da:	ffafe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc02019de:	00004697          	auipc	a3,0x4
ffffffffc02019e2:	22268693          	addi	a3,a3,546 # ffffffffc0205c00 <commands+0xc08>
ffffffffc02019e6:	00004617          	auipc	a2,0x4
ffffffffc02019ea:	faa60613          	addi	a2,a2,-86 # ffffffffc0205990 <commands+0x998>
ffffffffc02019ee:	17e00593          	li	a1,382
ffffffffc02019f2:	00004517          	auipc	a0,0x4
ffffffffc02019f6:	e6e50513          	addi	a0,a0,-402 # ffffffffc0205860 <commands+0x868>
ffffffffc02019fa:	fdafe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc02019fe:	00004697          	auipc	a3,0x4
ffffffffc0201a02:	40268693          	addi	a3,a3,1026 # ffffffffc0205e00 <commands+0xe08>
ffffffffc0201a06:	00004617          	auipc	a2,0x4
ffffffffc0201a0a:	f8a60613          	addi	a2,a2,-118 # ffffffffc0205990 <commands+0x998>
ffffffffc0201a0e:	1af00593          	li	a1,431
ffffffffc0201a12:	00004517          	auipc	a0,0x4
ffffffffc0201a16:	e4e50513          	addi	a0,a0,-434 # ffffffffc0205860 <commands+0x868>
ffffffffc0201a1a:	fbafe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc0201a1e:	00004697          	auipc	a3,0x4
ffffffffc0201a22:	23a68693          	addi	a3,a3,570 # ffffffffc0205c58 <commands+0xc60>
ffffffffc0201a26:	00004617          	auipc	a2,0x4
ffffffffc0201a2a:	f6a60613          	addi	a2,a2,-150 # ffffffffc0205990 <commands+0x998>
ffffffffc0201a2e:	19000593          	li	a1,400
ffffffffc0201a32:	00004517          	auipc	a0,0x4
ffffffffc0201a36:	e2e50513          	addi	a0,a0,-466 # ffffffffc0205860 <commands+0x868>
ffffffffc0201a3a:	f9afe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(boot_pgdir[0] == 0);
ffffffffc0201a3e:	00004697          	auipc	a3,0x4
ffffffffc0201a42:	2b268693          	addi	a3,a3,690 # ffffffffc0205cf0 <commands+0xcf8>
ffffffffc0201a46:	00004617          	auipc	a2,0x4
ffffffffc0201a4a:	f4a60613          	addi	a2,a2,-182 # ffffffffc0205990 <commands+0x998>
ffffffffc0201a4e:	1a100593          	li	a1,417
ffffffffc0201a52:	00004517          	auipc	a0,0x4
ffffffffc0201a56:	e0e50513          	addi	a0,a0,-498 # ffffffffc0205860 <commands+0x868>
ffffffffc0201a5a:	f7afe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0201a5e:	00004697          	auipc	a3,0x4
ffffffffc0201a62:	f1268693          	addi	a3,a3,-238 # ffffffffc0205970 <commands+0x978>
ffffffffc0201a66:	00004617          	auipc	a2,0x4
ffffffffc0201a6a:	f2a60613          	addi	a2,a2,-214 # ffffffffc0205990 <commands+0x998>
ffffffffc0201a6e:	16000593          	li	a1,352
ffffffffc0201a72:	00004517          	auipc	a0,0x4
ffffffffc0201a76:	dee50513          	addi	a0,a0,-530 # ffffffffc0205860 <commands+0x868>
ffffffffc0201a7a:	f5afe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc0201a7e:	00004617          	auipc	a2,0x4
ffffffffc0201a82:	e9260613          	addi	a2,a2,-366 # ffffffffc0205910 <commands+0x918>
ffffffffc0201a86:	0c300593          	li	a1,195
ffffffffc0201a8a:	00004517          	auipc	a0,0x4
ffffffffc0201a8e:	dd650513          	addi	a0,a0,-554 # ffffffffc0205860 <commands+0x868>
ffffffffc0201a92:	f42fe0ef          	jal	ra,ffffffffc02001d4 <__panic>

ffffffffc0201a96 <tlb_invalidate>:
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0201a96:	12058073          	sfence.vma	a1
}
ffffffffc0201a9a:	8082                	ret

ffffffffc0201a9c <pgdir_alloc_page>:
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc0201a9c:	7179                	addi	sp,sp,-48
ffffffffc0201a9e:	e84a                	sd	s2,16(sp)
ffffffffc0201aa0:	892a                	mv	s2,a0
    struct Page *page = alloc_page();
ffffffffc0201aa2:	4505                	li	a0,1
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc0201aa4:	f022                	sd	s0,32(sp)
ffffffffc0201aa6:	ec26                	sd	s1,24(sp)
ffffffffc0201aa8:	e44e                	sd	s3,8(sp)
ffffffffc0201aaa:	f406                	sd	ra,40(sp)
ffffffffc0201aac:	84ae                	mv	s1,a1
ffffffffc0201aae:	89b2                	mv	s3,a2
    struct Page *page = alloc_page();
ffffffffc0201ab0:	8f6ff0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc0201ab4:	842a                	mv	s0,a0
    if (page != NULL) {
ffffffffc0201ab6:	cd19                	beqz	a0,ffffffffc0201ad4 <pgdir_alloc_page+0x38>
        if (page_insert(pgdir, page, la, perm) != 0) {
ffffffffc0201ab8:	85aa                	mv	a1,a0
ffffffffc0201aba:	86ce                	mv	a3,s3
ffffffffc0201abc:	8626                	mv	a2,s1
ffffffffc0201abe:	854a                	mv	a0,s2
ffffffffc0201ac0:	c92ff0ef          	jal	ra,ffffffffc0200f52 <page_insert>
ffffffffc0201ac4:	ed39                	bnez	a0,ffffffffc0201b22 <pgdir_alloc_page+0x86>
        if (swap_init_ok) {
ffffffffc0201ac6:	00015797          	auipc	a5,0x15
ffffffffc0201aca:	9e278793          	addi	a5,a5,-1566 # ffffffffc02164a8 <swap_init_ok>
ffffffffc0201ace:	439c                	lw	a5,0(a5)
ffffffffc0201ad0:	2781                	sext.w	a5,a5
ffffffffc0201ad2:	eb89                	bnez	a5,ffffffffc0201ae4 <pgdir_alloc_page+0x48>
}
ffffffffc0201ad4:	8522                	mv	a0,s0
ffffffffc0201ad6:	70a2                	ld	ra,40(sp)
ffffffffc0201ad8:	7402                	ld	s0,32(sp)
ffffffffc0201ada:	64e2                	ld	s1,24(sp)
ffffffffc0201adc:	6942                	ld	s2,16(sp)
ffffffffc0201ade:	69a2                	ld	s3,8(sp)
ffffffffc0201ae0:	6145                	addi	sp,sp,48
ffffffffc0201ae2:	8082                	ret
            swap_map_swappable(check_mm_struct, la, page, 0);
ffffffffc0201ae4:	00015797          	auipc	a5,0x15
ffffffffc0201ae8:	a2478793          	addi	a5,a5,-1500 # ffffffffc0216508 <check_mm_struct>
ffffffffc0201aec:	6388                	ld	a0,0(a5)
ffffffffc0201aee:	4681                	li	a3,0
ffffffffc0201af0:	8622                	mv	a2,s0
ffffffffc0201af2:	85a6                	mv	a1,s1
ffffffffc0201af4:	037010ef          	jal	ra,ffffffffc020332a <swap_map_swappable>
            assert(page_ref(page) == 1);
ffffffffc0201af8:	4018                	lw	a4,0(s0)
            page->pra_vaddr = la;
ffffffffc0201afa:	fc04                	sd	s1,56(s0)
            assert(page_ref(page) == 1);
ffffffffc0201afc:	4785                	li	a5,1
ffffffffc0201afe:	fcf70be3          	beq	a4,a5,ffffffffc0201ad4 <pgdir_alloc_page+0x38>
ffffffffc0201b02:	00004697          	auipc	a3,0x4
ffffffffc0201b06:	d9e68693          	addi	a3,a3,-610 # ffffffffc02058a0 <commands+0x8a8>
ffffffffc0201b0a:	00004617          	auipc	a2,0x4
ffffffffc0201b0e:	e8660613          	addi	a2,a2,-378 # ffffffffc0205990 <commands+0x998>
ffffffffc0201b12:	14800593          	li	a1,328
ffffffffc0201b16:	00004517          	auipc	a0,0x4
ffffffffc0201b1a:	d4a50513          	addi	a0,a0,-694 # ffffffffc0205860 <commands+0x868>
ffffffffc0201b1e:	eb6fe0ef          	jal	ra,ffffffffc02001d4 <__panic>
            free_page(page);
ffffffffc0201b22:	8522                	mv	a0,s0
ffffffffc0201b24:	4585                	li	a1,1
ffffffffc0201b26:	908ff0ef          	jal	ra,ffffffffc0200c2e <free_pages>
            return NULL;
ffffffffc0201b2a:	4401                	li	s0,0
ffffffffc0201b2c:	b765                	j	ffffffffc0201ad4 <pgdir_alloc_page+0x38>

ffffffffc0201b2e <_fifo_init_mm>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0201b2e:	00015797          	auipc	a5,0x15
ffffffffc0201b32:	9ca78793          	addi	a5,a5,-1590 # ffffffffc02164f8 <pra_list_head>
 */
static int
_fifo_init_mm(struct mm_struct *mm)
{
    list_init(&pra_list_head);
    mm->sm_priv = &pra_list_head;
ffffffffc0201b36:	f51c                	sd	a5,40(a0)
ffffffffc0201b38:	e79c                	sd	a5,8(a5)
ffffffffc0201b3a:	e39c                	sd	a5,0(a5)
    // cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
    return 0;
}
ffffffffc0201b3c:	4501                	li	a0,0
ffffffffc0201b3e:	8082                	ret

ffffffffc0201b40 <_fifo_init>:

static int
_fifo_init(void)
{
    return 0;
}
ffffffffc0201b40:	4501                	li	a0,0
ffffffffc0201b42:	8082                	ret

ffffffffc0201b44 <_fifo_set_unswappable>:

static int
_fifo_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}
ffffffffc0201b44:	4501                	li	a0,0
ffffffffc0201b46:	8082                	ret

ffffffffc0201b48 <_fifo_tick_event>:

static int
_fifo_tick_event(struct mm_struct *mm)
{
    return 0;
}
ffffffffc0201b48:	4501                	li	a0,0
ffffffffc0201b4a:	8082                	ret

ffffffffc0201b4c <_fifo_check_swap>:
{
ffffffffc0201b4c:	711d                	addi	sp,sp,-96
ffffffffc0201b4e:	fc4e                	sd	s3,56(sp)
ffffffffc0201b50:	f852                	sd	s4,48(sp)
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0201b52:	00004517          	auipc	a0,0x4
ffffffffc0201b56:	2f650513          	addi	a0,a0,758 # ffffffffc0205e48 <commands+0xe50>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0201b5a:	698d                	lui	s3,0x3
ffffffffc0201b5c:	4a31                	li	s4,12
{
ffffffffc0201b5e:	e8a2                	sd	s0,80(sp)
ffffffffc0201b60:	e4a6                	sd	s1,72(sp)
ffffffffc0201b62:	ec86                	sd	ra,88(sp)
ffffffffc0201b64:	e0ca                	sd	s2,64(sp)
ffffffffc0201b66:	f456                	sd	s5,40(sp)
ffffffffc0201b68:	f05a                	sd	s6,32(sp)
ffffffffc0201b6a:	ec5e                	sd	s7,24(sp)
ffffffffc0201b6c:	e862                	sd	s8,16(sp)
ffffffffc0201b6e:	e466                	sd	s9,8(sp)
    assert(pgfault_num == 4);
ffffffffc0201b70:	00015417          	auipc	s0,0x15
ffffffffc0201b74:	92040413          	addi	s0,s0,-1760 # ffffffffc0216490 <pgfault_num>
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0201b78:	d58fe0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0201b7c:	01498023          	sb	s4,0(s3) # 3000 <BASE_ADDRESS-0xffffffffc01fd000>
    assert(pgfault_num == 4);
ffffffffc0201b80:	4004                	lw	s1,0(s0)
ffffffffc0201b82:	4791                	li	a5,4
ffffffffc0201b84:	2481                	sext.w	s1,s1
ffffffffc0201b86:	14f49963          	bne	s1,a5,ffffffffc0201cd8 <_fifo_check_swap+0x18c>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0201b8a:	00004517          	auipc	a0,0x4
ffffffffc0201b8e:	31650513          	addi	a0,a0,790 # ffffffffc0205ea0 <commands+0xea8>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0201b92:	6a85                	lui	s5,0x1
ffffffffc0201b94:	4b29                	li	s6,10
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0201b96:	d3afe0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0201b9a:	016a8023          	sb	s6,0(s5) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
    assert(pgfault_num == 4);
ffffffffc0201b9e:	00042903          	lw	s2,0(s0)
ffffffffc0201ba2:	2901                	sext.w	s2,s2
ffffffffc0201ba4:	2a991a63          	bne	s2,s1,ffffffffc0201e58 <_fifo_check_swap+0x30c>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0201ba8:	00004517          	auipc	a0,0x4
ffffffffc0201bac:	32050513          	addi	a0,a0,800 # ffffffffc0205ec8 <commands+0xed0>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0201bb0:	6b91                	lui	s7,0x4
ffffffffc0201bb2:	4c35                	li	s8,13
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0201bb4:	d1cfe0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0201bb8:	018b8023          	sb	s8,0(s7) # 4000 <BASE_ADDRESS-0xffffffffc01fc000>
    assert(pgfault_num == 4);
ffffffffc0201bbc:	4004                	lw	s1,0(s0)
ffffffffc0201bbe:	2481                	sext.w	s1,s1
ffffffffc0201bc0:	27249c63          	bne	s1,s2,ffffffffc0201e38 <_fifo_check_swap+0x2ec>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0201bc4:	00004517          	auipc	a0,0x4
ffffffffc0201bc8:	32c50513          	addi	a0,a0,812 # ffffffffc0205ef0 <commands+0xef8>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0201bcc:	6909                	lui	s2,0x2
ffffffffc0201bce:	4cad                	li	s9,11
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0201bd0:	d00fe0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0201bd4:	01990023          	sb	s9,0(s2) # 2000 <BASE_ADDRESS-0xffffffffc01fe000>
    assert(pgfault_num == 4);
ffffffffc0201bd8:	401c                	lw	a5,0(s0)
ffffffffc0201bda:	2781                	sext.w	a5,a5
ffffffffc0201bdc:	22979e63          	bne	a5,s1,ffffffffc0201e18 <_fifo_check_swap+0x2cc>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc0201be0:	00004517          	auipc	a0,0x4
ffffffffc0201be4:	33850513          	addi	a0,a0,824 # ffffffffc0205f18 <commands+0xf20>
ffffffffc0201be8:	ce8fe0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0201bec:	6795                	lui	a5,0x5
ffffffffc0201bee:	4739                	li	a4,14
ffffffffc0201bf0:	00e78023          	sb	a4,0(a5) # 5000 <BASE_ADDRESS-0xffffffffc01fb000>
    assert(pgfault_num == 5);
ffffffffc0201bf4:	4004                	lw	s1,0(s0)
ffffffffc0201bf6:	4795                	li	a5,5
ffffffffc0201bf8:	2481                	sext.w	s1,s1
ffffffffc0201bfa:	1ef49f63          	bne	s1,a5,ffffffffc0201df8 <_fifo_check_swap+0x2ac>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0201bfe:	00004517          	auipc	a0,0x4
ffffffffc0201c02:	2f250513          	addi	a0,a0,754 # ffffffffc0205ef0 <commands+0xef8>
ffffffffc0201c06:	ccafe0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0201c0a:	01990023          	sb	s9,0(s2)
    assert(pgfault_num == 5);
ffffffffc0201c0e:	401c                	lw	a5,0(s0)
ffffffffc0201c10:	2781                	sext.w	a5,a5
ffffffffc0201c12:	1c979363          	bne	a5,s1,ffffffffc0201dd8 <_fifo_check_swap+0x28c>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0201c16:	00004517          	auipc	a0,0x4
ffffffffc0201c1a:	28a50513          	addi	a0,a0,650 # ffffffffc0205ea0 <commands+0xea8>
ffffffffc0201c1e:	cb2fe0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0201c22:	016a8023          	sb	s6,0(s5)
    assert(pgfault_num == 6);
ffffffffc0201c26:	401c                	lw	a5,0(s0)
ffffffffc0201c28:	4719                	li	a4,6
ffffffffc0201c2a:	2781                	sext.w	a5,a5
ffffffffc0201c2c:	18e79663          	bne	a5,a4,ffffffffc0201db8 <_fifo_check_swap+0x26c>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0201c30:	00004517          	auipc	a0,0x4
ffffffffc0201c34:	2c050513          	addi	a0,a0,704 # ffffffffc0205ef0 <commands+0xef8>
ffffffffc0201c38:	c98fe0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0201c3c:	01990023          	sb	s9,0(s2)
    assert(pgfault_num == 7);
ffffffffc0201c40:	401c                	lw	a5,0(s0)
ffffffffc0201c42:	471d                	li	a4,7
ffffffffc0201c44:	2781                	sext.w	a5,a5
ffffffffc0201c46:	14e79963          	bne	a5,a4,ffffffffc0201d98 <_fifo_check_swap+0x24c>
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0201c4a:	00004517          	auipc	a0,0x4
ffffffffc0201c4e:	1fe50513          	addi	a0,a0,510 # ffffffffc0205e48 <commands+0xe50>
ffffffffc0201c52:	c7efe0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0201c56:	01498023          	sb	s4,0(s3)
    assert(pgfault_num == 8);
ffffffffc0201c5a:	401c                	lw	a5,0(s0)
ffffffffc0201c5c:	4721                	li	a4,8
ffffffffc0201c5e:	2781                	sext.w	a5,a5
ffffffffc0201c60:	10e79c63          	bne	a5,a4,ffffffffc0201d78 <_fifo_check_swap+0x22c>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0201c64:	00004517          	auipc	a0,0x4
ffffffffc0201c68:	26450513          	addi	a0,a0,612 # ffffffffc0205ec8 <commands+0xed0>
ffffffffc0201c6c:	c64fe0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0201c70:	018b8023          	sb	s8,0(s7)
    assert(pgfault_num == 9);
ffffffffc0201c74:	401c                	lw	a5,0(s0)
ffffffffc0201c76:	4725                	li	a4,9
ffffffffc0201c78:	2781                	sext.w	a5,a5
ffffffffc0201c7a:	0ce79f63          	bne	a5,a4,ffffffffc0201d58 <_fifo_check_swap+0x20c>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc0201c7e:	00004517          	auipc	a0,0x4
ffffffffc0201c82:	29a50513          	addi	a0,a0,666 # ffffffffc0205f18 <commands+0xf20>
ffffffffc0201c86:	c4afe0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0201c8a:	6795                	lui	a5,0x5
ffffffffc0201c8c:	4739                	li	a4,14
ffffffffc0201c8e:	00e78023          	sb	a4,0(a5) # 5000 <BASE_ADDRESS-0xffffffffc01fb000>
    assert(pgfault_num == 10);
ffffffffc0201c92:	4004                	lw	s1,0(s0)
ffffffffc0201c94:	47a9                	li	a5,10
ffffffffc0201c96:	2481                	sext.w	s1,s1
ffffffffc0201c98:	0af49063          	bne	s1,a5,ffffffffc0201d38 <_fifo_check_swap+0x1ec>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0201c9c:	00004517          	auipc	a0,0x4
ffffffffc0201ca0:	20450513          	addi	a0,a0,516 # ffffffffc0205ea0 <commands+0xea8>
ffffffffc0201ca4:	c2cfe0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0201ca8:	6785                	lui	a5,0x1
ffffffffc0201caa:	0007c783          	lbu	a5,0(a5) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
ffffffffc0201cae:	06979563          	bne	a5,s1,ffffffffc0201d18 <_fifo_check_swap+0x1cc>
    assert(pgfault_num == 11);
ffffffffc0201cb2:	401c                	lw	a5,0(s0)
ffffffffc0201cb4:	472d                	li	a4,11
ffffffffc0201cb6:	2781                	sext.w	a5,a5
ffffffffc0201cb8:	04e79063          	bne	a5,a4,ffffffffc0201cf8 <_fifo_check_swap+0x1ac>
}
ffffffffc0201cbc:	60e6                	ld	ra,88(sp)
ffffffffc0201cbe:	6446                	ld	s0,80(sp)
ffffffffc0201cc0:	64a6                	ld	s1,72(sp)
ffffffffc0201cc2:	6906                	ld	s2,64(sp)
ffffffffc0201cc4:	79e2                	ld	s3,56(sp)
ffffffffc0201cc6:	7a42                	ld	s4,48(sp)
ffffffffc0201cc8:	7aa2                	ld	s5,40(sp)
ffffffffc0201cca:	7b02                	ld	s6,32(sp)
ffffffffc0201ccc:	6be2                	ld	s7,24(sp)
ffffffffc0201cce:	6c42                	ld	s8,16(sp)
ffffffffc0201cd0:	6ca2                	ld	s9,8(sp)
ffffffffc0201cd2:	4501                	li	a0,0
ffffffffc0201cd4:	6125                	addi	sp,sp,96
ffffffffc0201cd6:	8082                	ret
    assert(pgfault_num == 4);
ffffffffc0201cd8:	00004697          	auipc	a3,0x4
ffffffffc0201cdc:	19868693          	addi	a3,a3,408 # ffffffffc0205e70 <commands+0xe78>
ffffffffc0201ce0:	00004617          	auipc	a2,0x4
ffffffffc0201ce4:	cb060613          	addi	a2,a2,-848 # ffffffffc0205990 <commands+0x998>
ffffffffc0201ce8:	05200593          	li	a1,82
ffffffffc0201cec:	00004517          	auipc	a0,0x4
ffffffffc0201cf0:	19c50513          	addi	a0,a0,412 # ffffffffc0205e88 <commands+0xe90>
ffffffffc0201cf4:	ce0fe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(pgfault_num == 11);
ffffffffc0201cf8:	00004697          	auipc	a3,0x4
ffffffffc0201cfc:	30068693          	addi	a3,a3,768 # ffffffffc0205ff8 <commands+0x1000>
ffffffffc0201d00:	00004617          	auipc	a2,0x4
ffffffffc0201d04:	c9060613          	addi	a2,a2,-880 # ffffffffc0205990 <commands+0x998>
ffffffffc0201d08:	07400593          	li	a1,116
ffffffffc0201d0c:	00004517          	auipc	a0,0x4
ffffffffc0201d10:	17c50513          	addi	a0,a0,380 # ffffffffc0205e88 <commands+0xe90>
ffffffffc0201d14:	cc0fe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0201d18:	00004697          	auipc	a3,0x4
ffffffffc0201d1c:	2b868693          	addi	a3,a3,696 # ffffffffc0205fd0 <commands+0xfd8>
ffffffffc0201d20:	00004617          	auipc	a2,0x4
ffffffffc0201d24:	c7060613          	addi	a2,a2,-912 # ffffffffc0205990 <commands+0x998>
ffffffffc0201d28:	07200593          	li	a1,114
ffffffffc0201d2c:	00004517          	auipc	a0,0x4
ffffffffc0201d30:	15c50513          	addi	a0,a0,348 # ffffffffc0205e88 <commands+0xe90>
ffffffffc0201d34:	ca0fe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(pgfault_num == 10);
ffffffffc0201d38:	00004697          	auipc	a3,0x4
ffffffffc0201d3c:	28068693          	addi	a3,a3,640 # ffffffffc0205fb8 <commands+0xfc0>
ffffffffc0201d40:	00004617          	auipc	a2,0x4
ffffffffc0201d44:	c5060613          	addi	a2,a2,-944 # ffffffffc0205990 <commands+0x998>
ffffffffc0201d48:	07000593          	li	a1,112
ffffffffc0201d4c:	00004517          	auipc	a0,0x4
ffffffffc0201d50:	13c50513          	addi	a0,a0,316 # ffffffffc0205e88 <commands+0xe90>
ffffffffc0201d54:	c80fe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(pgfault_num == 9);
ffffffffc0201d58:	00004697          	auipc	a3,0x4
ffffffffc0201d5c:	24868693          	addi	a3,a3,584 # ffffffffc0205fa0 <commands+0xfa8>
ffffffffc0201d60:	00004617          	auipc	a2,0x4
ffffffffc0201d64:	c3060613          	addi	a2,a2,-976 # ffffffffc0205990 <commands+0x998>
ffffffffc0201d68:	06d00593          	li	a1,109
ffffffffc0201d6c:	00004517          	auipc	a0,0x4
ffffffffc0201d70:	11c50513          	addi	a0,a0,284 # ffffffffc0205e88 <commands+0xe90>
ffffffffc0201d74:	c60fe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(pgfault_num == 8);
ffffffffc0201d78:	00004697          	auipc	a3,0x4
ffffffffc0201d7c:	21068693          	addi	a3,a3,528 # ffffffffc0205f88 <commands+0xf90>
ffffffffc0201d80:	00004617          	auipc	a2,0x4
ffffffffc0201d84:	c1060613          	addi	a2,a2,-1008 # ffffffffc0205990 <commands+0x998>
ffffffffc0201d88:	06a00593          	li	a1,106
ffffffffc0201d8c:	00004517          	auipc	a0,0x4
ffffffffc0201d90:	0fc50513          	addi	a0,a0,252 # ffffffffc0205e88 <commands+0xe90>
ffffffffc0201d94:	c40fe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(pgfault_num == 7);
ffffffffc0201d98:	00004697          	auipc	a3,0x4
ffffffffc0201d9c:	1d868693          	addi	a3,a3,472 # ffffffffc0205f70 <commands+0xf78>
ffffffffc0201da0:	00004617          	auipc	a2,0x4
ffffffffc0201da4:	bf060613          	addi	a2,a2,-1040 # ffffffffc0205990 <commands+0x998>
ffffffffc0201da8:	06700593          	li	a1,103
ffffffffc0201dac:	00004517          	auipc	a0,0x4
ffffffffc0201db0:	0dc50513          	addi	a0,a0,220 # ffffffffc0205e88 <commands+0xe90>
ffffffffc0201db4:	c20fe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(pgfault_num == 6);
ffffffffc0201db8:	00004697          	auipc	a3,0x4
ffffffffc0201dbc:	1a068693          	addi	a3,a3,416 # ffffffffc0205f58 <commands+0xf60>
ffffffffc0201dc0:	00004617          	auipc	a2,0x4
ffffffffc0201dc4:	bd060613          	addi	a2,a2,-1072 # ffffffffc0205990 <commands+0x998>
ffffffffc0201dc8:	06400593          	li	a1,100
ffffffffc0201dcc:	00004517          	auipc	a0,0x4
ffffffffc0201dd0:	0bc50513          	addi	a0,a0,188 # ffffffffc0205e88 <commands+0xe90>
ffffffffc0201dd4:	c00fe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(pgfault_num == 5);
ffffffffc0201dd8:	00004697          	auipc	a3,0x4
ffffffffc0201ddc:	16868693          	addi	a3,a3,360 # ffffffffc0205f40 <commands+0xf48>
ffffffffc0201de0:	00004617          	auipc	a2,0x4
ffffffffc0201de4:	bb060613          	addi	a2,a2,-1104 # ffffffffc0205990 <commands+0x998>
ffffffffc0201de8:	06100593          	li	a1,97
ffffffffc0201dec:	00004517          	auipc	a0,0x4
ffffffffc0201df0:	09c50513          	addi	a0,a0,156 # ffffffffc0205e88 <commands+0xe90>
ffffffffc0201df4:	be0fe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(pgfault_num == 5);
ffffffffc0201df8:	00004697          	auipc	a3,0x4
ffffffffc0201dfc:	14868693          	addi	a3,a3,328 # ffffffffc0205f40 <commands+0xf48>
ffffffffc0201e00:	00004617          	auipc	a2,0x4
ffffffffc0201e04:	b9060613          	addi	a2,a2,-1136 # ffffffffc0205990 <commands+0x998>
ffffffffc0201e08:	05e00593          	li	a1,94
ffffffffc0201e0c:	00004517          	auipc	a0,0x4
ffffffffc0201e10:	07c50513          	addi	a0,a0,124 # ffffffffc0205e88 <commands+0xe90>
ffffffffc0201e14:	bc0fe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(pgfault_num == 4);
ffffffffc0201e18:	00004697          	auipc	a3,0x4
ffffffffc0201e1c:	05868693          	addi	a3,a3,88 # ffffffffc0205e70 <commands+0xe78>
ffffffffc0201e20:	00004617          	auipc	a2,0x4
ffffffffc0201e24:	b7060613          	addi	a2,a2,-1168 # ffffffffc0205990 <commands+0x998>
ffffffffc0201e28:	05b00593          	li	a1,91
ffffffffc0201e2c:	00004517          	auipc	a0,0x4
ffffffffc0201e30:	05c50513          	addi	a0,a0,92 # ffffffffc0205e88 <commands+0xe90>
ffffffffc0201e34:	ba0fe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(pgfault_num == 4);
ffffffffc0201e38:	00004697          	auipc	a3,0x4
ffffffffc0201e3c:	03868693          	addi	a3,a3,56 # ffffffffc0205e70 <commands+0xe78>
ffffffffc0201e40:	00004617          	auipc	a2,0x4
ffffffffc0201e44:	b5060613          	addi	a2,a2,-1200 # ffffffffc0205990 <commands+0x998>
ffffffffc0201e48:	05800593          	li	a1,88
ffffffffc0201e4c:	00004517          	auipc	a0,0x4
ffffffffc0201e50:	03c50513          	addi	a0,a0,60 # ffffffffc0205e88 <commands+0xe90>
ffffffffc0201e54:	b80fe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(pgfault_num == 4);
ffffffffc0201e58:	00004697          	auipc	a3,0x4
ffffffffc0201e5c:	01868693          	addi	a3,a3,24 # ffffffffc0205e70 <commands+0xe78>
ffffffffc0201e60:	00004617          	auipc	a2,0x4
ffffffffc0201e64:	b3060613          	addi	a2,a2,-1232 # ffffffffc0205990 <commands+0x998>
ffffffffc0201e68:	05500593          	li	a1,85
ffffffffc0201e6c:	00004517          	auipc	a0,0x4
ffffffffc0201e70:	01c50513          	addi	a0,a0,28 # ffffffffc0205e88 <commands+0xe90>
ffffffffc0201e74:	b60fe0ef          	jal	ra,ffffffffc02001d4 <__panic>

ffffffffc0201e78 <_fifo_swap_out_victim>:
    list_entry_t *head = (list_entry_t *)mm->sm_priv;
ffffffffc0201e78:	7518                	ld	a4,40(a0)
{
ffffffffc0201e7a:	1141                	addi	sp,sp,-16
ffffffffc0201e7c:	e406                	sd	ra,8(sp)
    assert(head != NULL);
ffffffffc0201e7e:	c731                	beqz	a4,ffffffffc0201eca <_fifo_swap_out_victim+0x52>
    assert(in_tick == 0);
ffffffffc0201e80:	e60d                	bnez	a2,ffffffffc0201eaa <_fifo_swap_out_victim+0x32>
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc0201e82:	631c                	ld	a5,0(a4)
    if (entry != head)
ffffffffc0201e84:	00f70d63          	beq	a4,a5,ffffffffc0201e9e <_fifo_swap_out_victim+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc0201e88:	6394                	ld	a3,0(a5)
ffffffffc0201e8a:	6798                	ld	a4,8(a5)
}
ffffffffc0201e8c:	60a2                	ld	ra,8(sp)
        *ptr_page = le2page(entry, pra_page_link);
ffffffffc0201e8e:	fd878793          	addi	a5,a5,-40
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201e92:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc0201e94:	e314                	sd	a3,0(a4)
ffffffffc0201e96:	e19c                	sd	a5,0(a1)
}
ffffffffc0201e98:	4501                	li	a0,0
ffffffffc0201e9a:	0141                	addi	sp,sp,16
ffffffffc0201e9c:	8082                	ret
ffffffffc0201e9e:	60a2                	ld	ra,8(sp)
        *ptr_page = NULL;
ffffffffc0201ea0:	0005b023          	sd	zero,0(a1)
}
ffffffffc0201ea4:	4501                	li	a0,0
ffffffffc0201ea6:	0141                	addi	sp,sp,16
ffffffffc0201ea8:	8082                	ret
    assert(in_tick == 0);
ffffffffc0201eaa:	00004697          	auipc	a3,0x4
ffffffffc0201eae:	19668693          	addi	a3,a3,406 # ffffffffc0206040 <commands+0x1048>
ffffffffc0201eb2:	00004617          	auipc	a2,0x4
ffffffffc0201eb6:	ade60613          	addi	a2,a2,-1314 # ffffffffc0205990 <commands+0x998>
ffffffffc0201eba:	03c00593          	li	a1,60
ffffffffc0201ebe:	00004517          	auipc	a0,0x4
ffffffffc0201ec2:	fca50513          	addi	a0,a0,-54 # ffffffffc0205e88 <commands+0xe90>
ffffffffc0201ec6:	b0efe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(head != NULL);
ffffffffc0201eca:	00004697          	auipc	a3,0x4
ffffffffc0201ece:	16668693          	addi	a3,a3,358 # ffffffffc0206030 <commands+0x1038>
ffffffffc0201ed2:	00004617          	auipc	a2,0x4
ffffffffc0201ed6:	abe60613          	addi	a2,a2,-1346 # ffffffffc0205990 <commands+0x998>
ffffffffc0201eda:	03b00593          	li	a1,59
ffffffffc0201ede:	00004517          	auipc	a0,0x4
ffffffffc0201ee2:	faa50513          	addi	a0,a0,-86 # ffffffffc0205e88 <commands+0xe90>
ffffffffc0201ee6:	aeefe0ef          	jal	ra,ffffffffc02001d4 <__panic>

ffffffffc0201eea <_fifo_map_swappable>:
    list_entry_t *entry = &(page->pra_page_link);
ffffffffc0201eea:	02860713          	addi	a4,a2,40
    list_entry_t *head = (list_entry_t *)mm->sm_priv;
ffffffffc0201eee:	751c                	ld	a5,40(a0)
    assert(entry != NULL && head != NULL);
ffffffffc0201ef0:	cb09                	beqz	a4,ffffffffc0201f02 <_fifo_map_swappable+0x18>
ffffffffc0201ef2:	cb81                	beqz	a5,ffffffffc0201f02 <_fifo_map_swappable+0x18>
    __list_add(elm, listelm, listelm->next);
ffffffffc0201ef4:	6794                	ld	a3,8(a5)
}
ffffffffc0201ef6:	4501                	li	a0,0
    prev->next = next->prev = elm;
ffffffffc0201ef8:	e298                	sd	a4,0(a3)
ffffffffc0201efa:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0201efc:	fa14                	sd	a3,48(a2)
    elm->prev = prev;
ffffffffc0201efe:	f61c                	sd	a5,40(a2)
ffffffffc0201f00:	8082                	ret
{
ffffffffc0201f02:	1141                	addi	sp,sp,-16
    assert(entry != NULL && head != NULL);
ffffffffc0201f04:	00004697          	auipc	a3,0x4
ffffffffc0201f08:	10c68693          	addi	a3,a3,268 # ffffffffc0206010 <commands+0x1018>
ffffffffc0201f0c:	00004617          	auipc	a2,0x4
ffffffffc0201f10:	a8460613          	addi	a2,a2,-1404 # ffffffffc0205990 <commands+0x998>
ffffffffc0201f14:	02c00593          	li	a1,44
ffffffffc0201f18:	00004517          	auipc	a0,0x4
ffffffffc0201f1c:	f7050513          	addi	a0,a0,-144 # ffffffffc0205e88 <commands+0xe90>
{
ffffffffc0201f20:	e406                	sd	ra,8(sp)
    assert(entry != NULL && head != NULL);
ffffffffc0201f22:	ab2fe0ef          	jal	ra,ffffffffc02001d4 <__panic>

ffffffffc0201f26 <check_vma_overlap.isra.0.part.1>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0201f26:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0201f28:	00004697          	auipc	a3,0x4
ffffffffc0201f2c:	14068693          	addi	a3,a3,320 # ffffffffc0206068 <commands+0x1070>
ffffffffc0201f30:	00004617          	auipc	a2,0x4
ffffffffc0201f34:	a6060613          	addi	a2,a2,-1440 # ffffffffc0205990 <commands+0x998>
ffffffffc0201f38:	08d00593          	li	a1,141
ffffffffc0201f3c:	00004517          	auipc	a0,0x4
ffffffffc0201f40:	14c50513          	addi	a0,a0,332 # ffffffffc0206088 <commands+0x1090>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0201f44:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0201f46:	a8efe0ef          	jal	ra,ffffffffc02001d4 <__panic>

ffffffffc0201f4a <mm_create>:
{
ffffffffc0201f4a:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0201f4c:	03000513          	li	a0,48
{
ffffffffc0201f50:	e022                	sd	s0,0(sp)
ffffffffc0201f52:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0201f54:	273000ef          	jal	ra,ffffffffc02029c6 <kmalloc>
ffffffffc0201f58:	842a                	mv	s0,a0
    if (mm != NULL)
ffffffffc0201f5a:	c115                	beqz	a0,ffffffffc0201f7e <mm_create+0x34>
        if (swap_init_ok)
ffffffffc0201f5c:	00014797          	auipc	a5,0x14
ffffffffc0201f60:	54c78793          	addi	a5,a5,1356 # ffffffffc02164a8 <swap_init_ok>
ffffffffc0201f64:	439c                	lw	a5,0(a5)
    elm->prev = elm->next = elm;
ffffffffc0201f66:	e408                	sd	a0,8(s0)
ffffffffc0201f68:	e008                	sd	a0,0(s0)
        mm->mmap_cache = NULL;
ffffffffc0201f6a:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0201f6e:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0201f72:	02052023          	sw	zero,32(a0)
        if (swap_init_ok)
ffffffffc0201f76:	2781                	sext.w	a5,a5
ffffffffc0201f78:	eb81                	bnez	a5,ffffffffc0201f88 <mm_create+0x3e>
            mm->sm_priv = NULL;
ffffffffc0201f7a:	02053423          	sd	zero,40(a0)
}
ffffffffc0201f7e:	8522                	mv	a0,s0
ffffffffc0201f80:	60a2                	ld	ra,8(sp)
ffffffffc0201f82:	6402                	ld	s0,0(sp)
ffffffffc0201f84:	0141                	addi	sp,sp,16
ffffffffc0201f86:	8082                	ret
            swap_init_mm(mm);
ffffffffc0201f88:	392010ef          	jal	ra,ffffffffc020331a <swap_init_mm>
}
ffffffffc0201f8c:	8522                	mv	a0,s0
ffffffffc0201f8e:	60a2                	ld	ra,8(sp)
ffffffffc0201f90:	6402                	ld	s0,0(sp)
ffffffffc0201f92:	0141                	addi	sp,sp,16
ffffffffc0201f94:	8082                	ret

ffffffffc0201f96 <vma_create>:
{
ffffffffc0201f96:	1101                	addi	sp,sp,-32
ffffffffc0201f98:	e04a                	sd	s2,0(sp)
ffffffffc0201f9a:	892a                	mv	s2,a0
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0201f9c:	03000513          	li	a0,48
{
ffffffffc0201fa0:	e822                	sd	s0,16(sp)
ffffffffc0201fa2:	e426                	sd	s1,8(sp)
ffffffffc0201fa4:	ec06                	sd	ra,24(sp)
ffffffffc0201fa6:	84ae                	mv	s1,a1
ffffffffc0201fa8:	8432                	mv	s0,a2
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0201faa:	21d000ef          	jal	ra,ffffffffc02029c6 <kmalloc>
    if (vma != NULL)
ffffffffc0201fae:	c509                	beqz	a0,ffffffffc0201fb8 <vma_create+0x22>
        vma->vm_start = vm_start;
ffffffffc0201fb0:	01253423          	sd	s2,8(a0)
        vma->vm_end = vm_end;
ffffffffc0201fb4:	e904                	sd	s1,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0201fb6:	cd00                	sw	s0,24(a0)
}
ffffffffc0201fb8:	60e2                	ld	ra,24(sp)
ffffffffc0201fba:	6442                	ld	s0,16(sp)
ffffffffc0201fbc:	64a2                	ld	s1,8(sp)
ffffffffc0201fbe:	6902                	ld	s2,0(sp)
ffffffffc0201fc0:	6105                	addi	sp,sp,32
ffffffffc0201fc2:	8082                	ret

ffffffffc0201fc4 <find_vma>:
    if (mm != NULL)
ffffffffc0201fc4:	c51d                	beqz	a0,ffffffffc0201ff2 <find_vma+0x2e>
        vma = mm->mmap_cache;
ffffffffc0201fc6:	691c                	ld	a5,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0201fc8:	c781                	beqz	a5,ffffffffc0201fd0 <find_vma+0xc>
ffffffffc0201fca:	6798                	ld	a4,8(a5)
ffffffffc0201fcc:	02e5f663          	bgeu	a1,a4,ffffffffc0201ff8 <find_vma+0x34>
            list_entry_t *list = &(mm->mmap_list), *le = list;
ffffffffc0201fd0:	87aa                	mv	a5,a0
    return listelm->next;
ffffffffc0201fd2:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc0201fd4:	00f50f63          	beq	a0,a5,ffffffffc0201ff2 <find_vma+0x2e>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc0201fd8:	fe87b703          	ld	a4,-24(a5)
ffffffffc0201fdc:	fee5ebe3          	bltu	a1,a4,ffffffffc0201fd2 <find_vma+0xe>
ffffffffc0201fe0:	ff07b703          	ld	a4,-16(a5)
ffffffffc0201fe4:	fee5f7e3          	bgeu	a1,a4,ffffffffc0201fd2 <find_vma+0xe>
                vma = le2vma(le, list_link);
ffffffffc0201fe8:	1781                	addi	a5,a5,-32
        if (vma != NULL)
ffffffffc0201fea:	c781                	beqz	a5,ffffffffc0201ff2 <find_vma+0x2e>
            mm->mmap_cache = vma;
ffffffffc0201fec:	e91c                	sd	a5,16(a0)
}
ffffffffc0201fee:	853e                	mv	a0,a5
ffffffffc0201ff0:	8082                	ret
    struct vma_struct *vma = NULL;
ffffffffc0201ff2:	4781                	li	a5,0
}
ffffffffc0201ff4:	853e                	mv	a0,a5
ffffffffc0201ff6:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0201ff8:	6b98                	ld	a4,16(a5)
ffffffffc0201ffa:	fce5fbe3          	bgeu	a1,a4,ffffffffc0201fd0 <find_vma+0xc>
            mm->mmap_cache = vma;
ffffffffc0201ffe:	e91c                	sd	a5,16(a0)
    return vma;
ffffffffc0202000:	b7fd                	j	ffffffffc0201fee <find_vma+0x2a>

ffffffffc0202002 <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202002:	6590                	ld	a2,8(a1)
ffffffffc0202004:	0105b803          	ld	a6,16(a1)
{
ffffffffc0202008:	1141                	addi	sp,sp,-16
ffffffffc020200a:	e406                	sd	ra,8(sp)
ffffffffc020200c:	872a                	mv	a4,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc020200e:	01066863          	bltu	a2,a6,ffffffffc020201e <insert_vma_struct+0x1c>
ffffffffc0202012:	a8b9                	j	ffffffffc0202070 <insert_vma_struct+0x6e>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0202014:	fe87b683          	ld	a3,-24(a5)
ffffffffc0202018:	04d66763          	bltu	a2,a3,ffffffffc0202066 <insert_vma_struct+0x64>
ffffffffc020201c:	873e                	mv	a4,a5
ffffffffc020201e:	671c                	ld	a5,8(a4)
    while ((le = list_next(le)) != list)
ffffffffc0202020:	fef51ae3          	bne	a0,a5,ffffffffc0202014 <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc0202024:	02a70463          	beq	a4,a0,ffffffffc020204c <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0202028:	ff073683          	ld	a3,-16(a4) # 7fff0 <BASE_ADDRESS-0xffffffffc0180010>
    assert(prev->vm_start < prev->vm_end);
ffffffffc020202c:	fe873883          	ld	a7,-24(a4)
ffffffffc0202030:	08d8f063          	bgeu	a7,a3,ffffffffc02020b0 <insert_vma_struct+0xae>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202034:	04d66e63          	bltu	a2,a3,ffffffffc0202090 <insert_vma_struct+0x8e>
    }
    if (le_next != list)
ffffffffc0202038:	00f50a63          	beq	a0,a5,ffffffffc020204c <insert_vma_struct+0x4a>
ffffffffc020203c:	fe87b683          	ld	a3,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202040:	0506e863          	bltu	a3,a6,ffffffffc0202090 <insert_vma_struct+0x8e>
    assert(next->vm_start < next->vm_end);
ffffffffc0202044:	ff07b603          	ld	a2,-16(a5)
ffffffffc0202048:	02c6f263          	bgeu	a3,a2,ffffffffc020206c <insert_vma_struct+0x6a>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc020204c:	5114                	lw	a3,32(a0)
    vma->vm_mm = mm;
ffffffffc020204e:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0202050:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0202054:	e390                	sd	a2,0(a5)
ffffffffc0202056:	e710                	sd	a2,8(a4)
}
ffffffffc0202058:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc020205a:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc020205c:	f198                	sd	a4,32(a1)
    mm->map_count++;
ffffffffc020205e:	2685                	addiw	a3,a3,1
ffffffffc0202060:	d114                	sw	a3,32(a0)
}
ffffffffc0202062:	0141                	addi	sp,sp,16
ffffffffc0202064:	8082                	ret
    if (le_prev != list)
ffffffffc0202066:	fca711e3          	bne	a4,a0,ffffffffc0202028 <insert_vma_struct+0x26>
ffffffffc020206a:	bfd9                	j	ffffffffc0202040 <insert_vma_struct+0x3e>
ffffffffc020206c:	ebbff0ef          	jal	ra,ffffffffc0201f26 <check_vma_overlap.isra.0.part.1>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202070:	00004697          	auipc	a3,0x4
ffffffffc0202074:	0c868693          	addi	a3,a3,200 # ffffffffc0206138 <commands+0x1140>
ffffffffc0202078:	00004617          	auipc	a2,0x4
ffffffffc020207c:	91860613          	addi	a2,a2,-1768 # ffffffffc0205990 <commands+0x998>
ffffffffc0202080:	09300593          	li	a1,147
ffffffffc0202084:	00004517          	auipc	a0,0x4
ffffffffc0202088:	00450513          	addi	a0,a0,4 # ffffffffc0206088 <commands+0x1090>
ffffffffc020208c:	948fe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202090:	00004697          	auipc	a3,0x4
ffffffffc0202094:	0e868693          	addi	a3,a3,232 # ffffffffc0206178 <commands+0x1180>
ffffffffc0202098:	00004617          	auipc	a2,0x4
ffffffffc020209c:	8f860613          	addi	a2,a2,-1800 # ffffffffc0205990 <commands+0x998>
ffffffffc02020a0:	08c00593          	li	a1,140
ffffffffc02020a4:	00004517          	auipc	a0,0x4
ffffffffc02020a8:	fe450513          	addi	a0,a0,-28 # ffffffffc0206088 <commands+0x1090>
ffffffffc02020ac:	928fe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc02020b0:	00004697          	auipc	a3,0x4
ffffffffc02020b4:	0a868693          	addi	a3,a3,168 # ffffffffc0206158 <commands+0x1160>
ffffffffc02020b8:	00004617          	auipc	a2,0x4
ffffffffc02020bc:	8d860613          	addi	a2,a2,-1832 # ffffffffc0205990 <commands+0x998>
ffffffffc02020c0:	08b00593          	li	a1,139
ffffffffc02020c4:	00004517          	auipc	a0,0x4
ffffffffc02020c8:	fc450513          	addi	a0,a0,-60 # ffffffffc0206088 <commands+0x1090>
ffffffffc02020cc:	908fe0ef          	jal	ra,ffffffffc02001d4 <__panic>

ffffffffc02020d0 <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
ffffffffc02020d0:	1141                	addi	sp,sp,-16
ffffffffc02020d2:	e022                	sd	s0,0(sp)
ffffffffc02020d4:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc02020d6:	6508                	ld	a0,8(a0)
ffffffffc02020d8:	e406                	sd	ra,8(sp)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc02020da:	00a40c63          	beq	s0,a0,ffffffffc02020f2 <mm_destroy+0x22>
    __list_del(listelm->prev, listelm->next);
ffffffffc02020de:	6118                	ld	a4,0(a0)
ffffffffc02020e0:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc02020e2:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc02020e4:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02020e6:	e398                	sd	a4,0(a5)
ffffffffc02020e8:	19b000ef          	jal	ra,ffffffffc0202a82 <kfree>
    return listelm->next;
ffffffffc02020ec:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc02020ee:	fea418e3          	bne	s0,a0,ffffffffc02020de <mm_destroy+0xe>
    }
    kfree(mm); // kfree mm
ffffffffc02020f2:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc02020f4:	6402                	ld	s0,0(sp)
ffffffffc02020f6:	60a2                	ld	ra,8(sp)
ffffffffc02020f8:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc02020fa:	1890006f          	j	ffffffffc0202a82 <kfree>

ffffffffc02020fe <vmm_init>:

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc02020fe:	7139                	addi	sp,sp,-64
ffffffffc0202100:	f822                	sd	s0,48(sp)
ffffffffc0202102:	f426                	sd	s1,40(sp)
ffffffffc0202104:	fc06                	sd	ra,56(sp)
ffffffffc0202106:	f04a                	sd	s2,32(sp)
ffffffffc0202108:	ec4e                	sd	s3,24(sp)
ffffffffc020210a:	e852                	sd	s4,16(sp)
ffffffffc020210c:	e456                	sd	s5,8(sp)
}

static void
check_vma_struct(void)
{
    struct mm_struct *mm = mm_create();
ffffffffc020210e:	e3dff0ef          	jal	ra,ffffffffc0201f4a <mm_create>
    assert(mm != NULL);
ffffffffc0202112:	842a                	mv	s0,a0
ffffffffc0202114:	03200493          	li	s1,50
ffffffffc0202118:	e919                	bnez	a0,ffffffffc020212e <vmm_init+0x30>
ffffffffc020211a:	a989                	j	ffffffffc020256c <vmm_init+0x46e>
        vma->vm_start = vm_start;
ffffffffc020211c:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc020211e:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202120:	00052c23          	sw	zero,24(a0)
    int i;
    for (i = step1; i >= 1; i--)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202124:	14ed                	addi	s1,s1,-5
ffffffffc0202126:	8522                	mv	a0,s0
ffffffffc0202128:	edbff0ef          	jal	ra,ffffffffc0202002 <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc020212c:	c88d                	beqz	s1,ffffffffc020215e <vmm_init+0x60>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020212e:	03000513          	li	a0,48
ffffffffc0202132:	095000ef          	jal	ra,ffffffffc02029c6 <kmalloc>
ffffffffc0202136:	85aa                	mv	a1,a0
ffffffffc0202138:	00248793          	addi	a5,s1,2
    if (vma != NULL)
ffffffffc020213c:	f165                	bnez	a0,ffffffffc020211c <vmm_init+0x1e>
        assert(vma != NULL);
ffffffffc020213e:	00004697          	auipc	a3,0x4
ffffffffc0202142:	28268693          	addi	a3,a3,642 # ffffffffc02063c0 <commands+0x13c8>
ffffffffc0202146:	00004617          	auipc	a2,0x4
ffffffffc020214a:	84a60613          	addi	a2,a2,-1974 # ffffffffc0205990 <commands+0x998>
ffffffffc020214e:	0df00593          	li	a1,223
ffffffffc0202152:	00004517          	auipc	a0,0x4
ffffffffc0202156:	f3650513          	addi	a0,a0,-202 # ffffffffc0206088 <commands+0x1090>
ffffffffc020215a:	87afe0ef          	jal	ra,ffffffffc02001d4 <__panic>
    for (i = step1; i >= 1; i--)
ffffffffc020215e:	03700493          	li	s1,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202162:	1f900913          	li	s2,505
ffffffffc0202166:	a819                	j	ffffffffc020217c <vmm_init+0x7e>
        vma->vm_start = vm_start;
ffffffffc0202168:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc020216a:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc020216c:	00052c23          	sw	zero,24(a0)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202170:	0495                	addi	s1,s1,5
ffffffffc0202172:	8522                	mv	a0,s0
ffffffffc0202174:	e8fff0ef          	jal	ra,ffffffffc0202002 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202178:	03248a63          	beq	s1,s2,ffffffffc02021ac <vmm_init+0xae>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020217c:	03000513          	li	a0,48
ffffffffc0202180:	047000ef          	jal	ra,ffffffffc02029c6 <kmalloc>
ffffffffc0202184:	85aa                	mv	a1,a0
ffffffffc0202186:	00248793          	addi	a5,s1,2
    if (vma != NULL)
ffffffffc020218a:	fd79                	bnez	a0,ffffffffc0202168 <vmm_init+0x6a>
        assert(vma != NULL);
ffffffffc020218c:	00004697          	auipc	a3,0x4
ffffffffc0202190:	23468693          	addi	a3,a3,564 # ffffffffc02063c0 <commands+0x13c8>
ffffffffc0202194:	00003617          	auipc	a2,0x3
ffffffffc0202198:	7fc60613          	addi	a2,a2,2044 # ffffffffc0205990 <commands+0x998>
ffffffffc020219c:	0e600593          	li	a1,230
ffffffffc02021a0:	00004517          	auipc	a0,0x4
ffffffffc02021a4:	ee850513          	addi	a0,a0,-280 # ffffffffc0206088 <commands+0x1090>
ffffffffc02021a8:	82cfe0ef          	jal	ra,ffffffffc02001d4 <__panic>
ffffffffc02021ac:	6418                	ld	a4,8(s0)
ffffffffc02021ae:	479d                	li	a5,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc02021b0:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc02021b4:	2ee40063          	beq	s0,a4,ffffffffc0202494 <vmm_init+0x396>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc02021b8:	fe873603          	ld	a2,-24(a4)
ffffffffc02021bc:	ffe78693          	addi	a3,a5,-2
ffffffffc02021c0:	24d61a63          	bne	a2,a3,ffffffffc0202414 <vmm_init+0x316>
ffffffffc02021c4:	ff073683          	ld	a3,-16(a4)
ffffffffc02021c8:	24f69663          	bne	a3,a5,ffffffffc0202414 <vmm_init+0x316>
ffffffffc02021cc:	0795                	addi	a5,a5,5
ffffffffc02021ce:	6718                	ld	a4,8(a4)
    for (i = 1; i <= step2; i++)
ffffffffc02021d0:	feb792e3          	bne	a5,a1,ffffffffc02021b4 <vmm_init+0xb6>
ffffffffc02021d4:	491d                	li	s2,7
ffffffffc02021d6:	4495                	li	s1,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc02021d8:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc02021dc:	85a6                	mv	a1,s1
ffffffffc02021de:	8522                	mv	a0,s0
ffffffffc02021e0:	de5ff0ef          	jal	ra,ffffffffc0201fc4 <find_vma>
ffffffffc02021e4:	8a2a                	mv	s4,a0
        assert(vma1 != NULL);
ffffffffc02021e6:	30050763          	beqz	a0,ffffffffc02024f4 <vmm_init+0x3f6>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc02021ea:	00148593          	addi	a1,s1,1
ffffffffc02021ee:	8522                	mv	a0,s0
ffffffffc02021f0:	dd5ff0ef          	jal	ra,ffffffffc0201fc4 <find_vma>
ffffffffc02021f4:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc02021f6:	2c050f63          	beqz	a0,ffffffffc02024d4 <vmm_init+0x3d6>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc02021fa:	85ca                	mv	a1,s2
ffffffffc02021fc:	8522                	mv	a0,s0
ffffffffc02021fe:	dc7ff0ef          	jal	ra,ffffffffc0201fc4 <find_vma>
        assert(vma3 == NULL);
ffffffffc0202202:	2a051963          	bnez	a0,ffffffffc02024b4 <vmm_init+0x3b6>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0202206:	00348593          	addi	a1,s1,3
ffffffffc020220a:	8522                	mv	a0,s0
ffffffffc020220c:	db9ff0ef          	jal	ra,ffffffffc0201fc4 <find_vma>
        assert(vma4 == NULL);
ffffffffc0202210:	32051263          	bnez	a0,ffffffffc0202534 <vmm_init+0x436>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0202214:	00448593          	addi	a1,s1,4
ffffffffc0202218:	8522                	mv	a0,s0
ffffffffc020221a:	dabff0ef          	jal	ra,ffffffffc0201fc4 <find_vma>
        assert(vma5 == NULL);
ffffffffc020221e:	2e051b63          	bnez	a0,ffffffffc0202514 <vmm_init+0x416>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0202222:	008a3783          	ld	a5,8(s4)
ffffffffc0202226:	20979763          	bne	a5,s1,ffffffffc0202434 <vmm_init+0x336>
ffffffffc020222a:	010a3783          	ld	a5,16(s4)
ffffffffc020222e:	21279363          	bne	a5,s2,ffffffffc0202434 <vmm_init+0x336>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0202232:	0089b783          	ld	a5,8(s3)
ffffffffc0202236:	20979f63          	bne	a5,s1,ffffffffc0202454 <vmm_init+0x356>
ffffffffc020223a:	0109b783          	ld	a5,16(s3)
ffffffffc020223e:	21279b63          	bne	a5,s2,ffffffffc0202454 <vmm_init+0x356>
ffffffffc0202242:	0495                	addi	s1,s1,5
ffffffffc0202244:	0915                	addi	s2,s2,5
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0202246:	f9549be3          	bne	s1,s5,ffffffffc02021dc <vmm_init+0xde>
ffffffffc020224a:	4491                	li	s1,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc020224c:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc020224e:	85a6                	mv	a1,s1
ffffffffc0202250:	8522                	mv	a0,s0
ffffffffc0202252:	d73ff0ef          	jal	ra,ffffffffc0201fc4 <find_vma>
ffffffffc0202256:	0004859b          	sext.w	a1,s1
        if (vma_below_5 != NULL)
ffffffffc020225a:	c90d                	beqz	a0,ffffffffc020228c <vmm_init+0x18e>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc020225c:	6914                	ld	a3,16(a0)
ffffffffc020225e:	6510                	ld	a2,8(a0)
ffffffffc0202260:	00004517          	auipc	a0,0x4
ffffffffc0202264:	04850513          	addi	a0,a0,72 # ffffffffc02062a8 <commands+0x12b0>
ffffffffc0202268:	e69fd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc020226c:	00004697          	auipc	a3,0x4
ffffffffc0202270:	06468693          	addi	a3,a3,100 # ffffffffc02062d0 <commands+0x12d8>
ffffffffc0202274:	00003617          	auipc	a2,0x3
ffffffffc0202278:	71c60613          	addi	a2,a2,1820 # ffffffffc0205990 <commands+0x998>
ffffffffc020227c:	10c00593          	li	a1,268
ffffffffc0202280:	00004517          	auipc	a0,0x4
ffffffffc0202284:	e0850513          	addi	a0,a0,-504 # ffffffffc0206088 <commands+0x1090>
ffffffffc0202288:	f4dfd0ef          	jal	ra,ffffffffc02001d4 <__panic>
ffffffffc020228c:	14fd                	addi	s1,s1,-1
    for (i = 4; i >= 0; i--)
ffffffffc020228e:	fd2490e3          	bne	s1,s2,ffffffffc020224e <vmm_init+0x150>
    }

    mm_destroy(mm);
ffffffffc0202292:	8522                	mv	a0,s0
ffffffffc0202294:	e3dff0ef          	jal	ra,ffffffffc02020d0 <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0202298:	00004517          	auipc	a0,0x4
ffffffffc020229c:	05050513          	addi	a0,a0,80 # ffffffffc02062e8 <commands+0x12f0>
ffffffffc02022a0:	e31fd0ef          	jal	ra,ffffffffc02000d0 <cprintf>

// check_pgfault - check correctness of pgfault handler
static void
check_pgfault(void)
{
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc02022a4:	9d1fe0ef          	jal	ra,ffffffffc0200c74 <nr_free_pages>
ffffffffc02022a8:	89aa                	mv	s3,a0

    check_mm_struct = mm_create();
ffffffffc02022aa:	ca1ff0ef          	jal	ra,ffffffffc0201f4a <mm_create>
ffffffffc02022ae:	00014797          	auipc	a5,0x14
ffffffffc02022b2:	24a7bd23          	sd	a0,602(a5) # ffffffffc0216508 <check_mm_struct>
ffffffffc02022b6:	84aa                	mv	s1,a0
    assert(check_mm_struct != NULL);
ffffffffc02022b8:	36050663          	beqz	a0,ffffffffc0202624 <vmm_init+0x526>

    struct mm_struct *mm = check_mm_struct;
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc02022bc:	00014797          	auipc	a5,0x14
ffffffffc02022c0:	1c478793          	addi	a5,a5,452 # ffffffffc0216480 <boot_pgdir>
ffffffffc02022c4:	0007b903          	ld	s2,0(a5)
    assert(pgdir[0] == 0);
ffffffffc02022c8:	00093783          	ld	a5,0(s2)
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc02022cc:	01253c23          	sd	s2,24(a0)
    assert(pgdir[0] == 0);
ffffffffc02022d0:	2c079e63          	bnez	a5,ffffffffc02025ac <vmm_init+0x4ae>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02022d4:	03000513          	li	a0,48
ffffffffc02022d8:	6ee000ef          	jal	ra,ffffffffc02029c6 <kmalloc>
ffffffffc02022dc:	842a                	mv	s0,a0
    if (vma != NULL)
ffffffffc02022de:	18050b63          	beqz	a0,ffffffffc0202474 <vmm_init+0x376>
        vma->vm_end = vm_end;
ffffffffc02022e2:	002007b7          	lui	a5,0x200
ffffffffc02022e6:	e81c                	sd	a5,16(s0)
        vma->vm_flags = vm_flags;
ffffffffc02022e8:	4789                	li	a5,2

    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);
    assert(vma != NULL);

    insert_vma_struct(mm, vma);
ffffffffc02022ea:	85aa                	mv	a1,a0
        vma->vm_flags = vm_flags;
ffffffffc02022ec:	cc1c                	sw	a5,24(s0)
    insert_vma_struct(mm, vma);
ffffffffc02022ee:	8526                	mv	a0,s1
        vma->vm_start = vm_start;
ffffffffc02022f0:	00043423          	sd	zero,8(s0)
    insert_vma_struct(mm, vma);
ffffffffc02022f4:	d0fff0ef          	jal	ra,ffffffffc0202002 <insert_vma_struct>

    uintptr_t addr = 0x100;
    assert(find_vma(mm, addr) == vma);
ffffffffc02022f8:	10000593          	li	a1,256
ffffffffc02022fc:	8526                	mv	a0,s1
ffffffffc02022fe:	cc7ff0ef          	jal	ra,ffffffffc0201fc4 <find_vma>
ffffffffc0202302:	10000793          	li	a5,256

    int i, sum = 0;
    for (i = 0; i < 100; i++)
ffffffffc0202306:	16400713          	li	a4,356
    assert(find_vma(mm, addr) == vma);
ffffffffc020230a:	2ca41163          	bne	s0,a0,ffffffffc02025cc <vmm_init+0x4ce>
    {
        *(char *)(addr + i) = i;
ffffffffc020230e:	00f78023          	sb	a5,0(a5) # 200000 <BASE_ADDRESS-0xffffffffc0000000>
        sum += i;
ffffffffc0202312:	0785                	addi	a5,a5,1
    for (i = 0; i < 100; i++)
ffffffffc0202314:	fee79de3          	bne	a5,a4,ffffffffc020230e <vmm_init+0x210>
        sum += i;
ffffffffc0202318:	6705                	lui	a4,0x1
    for (i = 0; i < 100; i++)
ffffffffc020231a:	10000793          	li	a5,256
        sum += i;
ffffffffc020231e:	35670713          	addi	a4,a4,854 # 1356 <BASE_ADDRESS-0xffffffffc01fecaa>
    }
    for (i = 0; i < 100; i++)
ffffffffc0202322:	16400613          	li	a2,356
    {
        sum -= *(char *)(addr + i);
ffffffffc0202326:	0007c683          	lbu	a3,0(a5)
ffffffffc020232a:	0785                	addi	a5,a5,1
ffffffffc020232c:	9f15                	subw	a4,a4,a3
    for (i = 0; i < 100; i++)
ffffffffc020232e:	fec79ce3          	bne	a5,a2,ffffffffc0202326 <vmm_init+0x228>
    }
    assert(sum == 0);
ffffffffc0202332:	2c071963          	bnez	a4,ffffffffc0202604 <vmm_init+0x506>
    return pa2page(PDE_ADDR(pde));
ffffffffc0202336:	00093783          	ld	a5,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc020233a:	00014a97          	auipc	s5,0x14
ffffffffc020233e:	14ea8a93          	addi	s5,s5,334 # ffffffffc0216488 <npage>
ffffffffc0202342:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202346:	078a                	slli	a5,a5,0x2
ffffffffc0202348:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020234a:	20e7f563          	bgeu	a5,a4,ffffffffc0202554 <vmm_init+0x456>
    return &pages[PPN(pa) - nbase];
ffffffffc020234e:	00005697          	auipc	a3,0x5
ffffffffc0202352:	cd268693          	addi	a3,a3,-814 # ffffffffc0207020 <nbase>
ffffffffc0202356:	0006ba03          	ld	s4,0(a3)
ffffffffc020235a:	414786b3          	sub	a3,a5,s4
ffffffffc020235e:	069a                	slli	a3,a3,0x6
    return page - pages + nbase;
ffffffffc0202360:	8699                	srai	a3,a3,0x6
ffffffffc0202362:	96d2                	add	a3,a3,s4
    return KADDR(page2pa(page));
ffffffffc0202364:	00c69793          	slli	a5,a3,0xc
ffffffffc0202368:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc020236a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020236c:	28e7f063          	bgeu	a5,a4,ffffffffc02025ec <vmm_init+0x4ee>
ffffffffc0202370:	00014797          	auipc	a5,0x14
ffffffffc0202374:	17078793          	addi	a5,a5,368 # ffffffffc02164e0 <va_pa_offset>
ffffffffc0202378:	6380                	ld	s0,0(a5)

    pde_t *pd1 = pgdir, *pd0 = page2kva(pde2page(pgdir[0]));
    page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));
ffffffffc020237a:	4581                	li	a1,0
ffffffffc020237c:	854a                	mv	a0,s2
ffffffffc020237e:	9436                	add	s0,s0,a3
ffffffffc0202380:	b5ffe0ef          	jal	ra,ffffffffc0200ede <page_remove>
    return pa2page(PDE_ADDR(pde));
ffffffffc0202384:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc0202386:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc020238a:	078a                	slli	a5,a5,0x2
ffffffffc020238c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020238e:	1ce7f363          	bgeu	a5,a4,ffffffffc0202554 <vmm_init+0x456>
    return &pages[PPN(pa) - nbase];
ffffffffc0202392:	00014417          	auipc	s0,0x14
ffffffffc0202396:	15e40413          	addi	s0,s0,350 # ffffffffc02164f0 <pages>
ffffffffc020239a:	6008                	ld	a0,0(s0)
ffffffffc020239c:	414787b3          	sub	a5,a5,s4
ffffffffc02023a0:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd0[0]));
ffffffffc02023a2:	953e                	add	a0,a0,a5
ffffffffc02023a4:	4585                	li	a1,1
ffffffffc02023a6:	889fe0ef          	jal	ra,ffffffffc0200c2e <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc02023aa:	00093783          	ld	a5,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc02023ae:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc02023b2:	078a                	slli	a5,a5,0x2
ffffffffc02023b4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02023b6:	18e7ff63          	bgeu	a5,a4,ffffffffc0202554 <vmm_init+0x456>
    return &pages[PPN(pa) - nbase];
ffffffffc02023ba:	6008                	ld	a0,0(s0)
ffffffffc02023bc:	414787b3          	sub	a5,a5,s4
ffffffffc02023c0:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd1[0]));
ffffffffc02023c2:	4585                	li	a1,1
ffffffffc02023c4:	953e                	add	a0,a0,a5
ffffffffc02023c6:	869fe0ef          	jal	ra,ffffffffc0200c2e <free_pages>
    pgdir[0] = 0;
ffffffffc02023ca:	00093023          	sd	zero,0(s2)
  asm volatile("sfence.vma");
ffffffffc02023ce:	12000073          	sfence.vma
    flush_tlb();

    mm->pgdir = NULL;
ffffffffc02023d2:	0004bc23          	sd	zero,24(s1)
    mm_destroy(mm);
ffffffffc02023d6:	8526                	mv	a0,s1
ffffffffc02023d8:	cf9ff0ef          	jal	ra,ffffffffc02020d0 <mm_destroy>
    check_mm_struct = NULL;
ffffffffc02023dc:	00014797          	auipc	a5,0x14
ffffffffc02023e0:	1207b623          	sd	zero,300(a5) # ffffffffc0216508 <check_mm_struct>

    assert(nr_free_pages_store == nr_free_pages());
ffffffffc02023e4:	891fe0ef          	jal	ra,ffffffffc0200c74 <nr_free_pages>
ffffffffc02023e8:	1aa99263          	bne	s3,a0,ffffffffc020258c <vmm_init+0x48e>

    cprintf("check_pgfault() succeeded!\n");
ffffffffc02023ec:	00004517          	auipc	a0,0x4
ffffffffc02023f0:	f9c50513          	addi	a0,a0,-100 # ffffffffc0206388 <commands+0x1390>
ffffffffc02023f4:	cddfd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
}
ffffffffc02023f8:	7442                	ld	s0,48(sp)
ffffffffc02023fa:	70e2                	ld	ra,56(sp)
ffffffffc02023fc:	74a2                	ld	s1,40(sp)
ffffffffc02023fe:	7902                	ld	s2,32(sp)
ffffffffc0202400:	69e2                	ld	s3,24(sp)
ffffffffc0202402:	6a42                	ld	s4,16(sp)
ffffffffc0202404:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0202406:	00004517          	auipc	a0,0x4
ffffffffc020240a:	fa250513          	addi	a0,a0,-94 # ffffffffc02063a8 <commands+0x13b0>
}
ffffffffc020240e:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0202410:	cc1fd06f          	j	ffffffffc02000d0 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0202414:	00004697          	auipc	a3,0x4
ffffffffc0202418:	dac68693          	addi	a3,a3,-596 # ffffffffc02061c0 <commands+0x11c8>
ffffffffc020241c:	00003617          	auipc	a2,0x3
ffffffffc0202420:	57460613          	addi	a2,a2,1396 # ffffffffc0205990 <commands+0x998>
ffffffffc0202424:	0f000593          	li	a1,240
ffffffffc0202428:	00004517          	auipc	a0,0x4
ffffffffc020242c:	c6050513          	addi	a0,a0,-928 # ffffffffc0206088 <commands+0x1090>
ffffffffc0202430:	da5fd0ef          	jal	ra,ffffffffc02001d4 <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0202434:	00004697          	auipc	a3,0x4
ffffffffc0202438:	e1468693          	addi	a3,a3,-492 # ffffffffc0206248 <commands+0x1250>
ffffffffc020243c:	00003617          	auipc	a2,0x3
ffffffffc0202440:	55460613          	addi	a2,a2,1364 # ffffffffc0205990 <commands+0x998>
ffffffffc0202444:	10100593          	li	a1,257
ffffffffc0202448:	00004517          	auipc	a0,0x4
ffffffffc020244c:	c4050513          	addi	a0,a0,-960 # ffffffffc0206088 <commands+0x1090>
ffffffffc0202450:	d85fd0ef          	jal	ra,ffffffffc02001d4 <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0202454:	00004697          	auipc	a3,0x4
ffffffffc0202458:	e2468693          	addi	a3,a3,-476 # ffffffffc0206278 <commands+0x1280>
ffffffffc020245c:	00003617          	auipc	a2,0x3
ffffffffc0202460:	53460613          	addi	a2,a2,1332 # ffffffffc0205990 <commands+0x998>
ffffffffc0202464:	10200593          	li	a1,258
ffffffffc0202468:	00004517          	auipc	a0,0x4
ffffffffc020246c:	c2050513          	addi	a0,a0,-992 # ffffffffc0206088 <commands+0x1090>
ffffffffc0202470:	d65fd0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(vma != NULL);
ffffffffc0202474:	00004697          	auipc	a3,0x4
ffffffffc0202478:	f4c68693          	addi	a3,a3,-180 # ffffffffc02063c0 <commands+0x13c8>
ffffffffc020247c:	00003617          	auipc	a2,0x3
ffffffffc0202480:	51460613          	addi	a2,a2,1300 # ffffffffc0205990 <commands+0x998>
ffffffffc0202484:	12400593          	li	a1,292
ffffffffc0202488:	00004517          	auipc	a0,0x4
ffffffffc020248c:	c0050513          	addi	a0,a0,-1024 # ffffffffc0206088 <commands+0x1090>
ffffffffc0202490:	d45fd0ef          	jal	ra,ffffffffc02001d4 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0202494:	00004697          	auipc	a3,0x4
ffffffffc0202498:	d1468693          	addi	a3,a3,-748 # ffffffffc02061a8 <commands+0x11b0>
ffffffffc020249c:	00003617          	auipc	a2,0x3
ffffffffc02024a0:	4f460613          	addi	a2,a2,1268 # ffffffffc0205990 <commands+0x998>
ffffffffc02024a4:	0ee00593          	li	a1,238
ffffffffc02024a8:	00004517          	auipc	a0,0x4
ffffffffc02024ac:	be050513          	addi	a0,a0,-1056 # ffffffffc0206088 <commands+0x1090>
ffffffffc02024b0:	d25fd0ef          	jal	ra,ffffffffc02001d4 <__panic>
        assert(vma3 == NULL);
ffffffffc02024b4:	00004697          	auipc	a3,0x4
ffffffffc02024b8:	d6468693          	addi	a3,a3,-668 # ffffffffc0206218 <commands+0x1220>
ffffffffc02024bc:	00003617          	auipc	a2,0x3
ffffffffc02024c0:	4d460613          	addi	a2,a2,1236 # ffffffffc0205990 <commands+0x998>
ffffffffc02024c4:	0fb00593          	li	a1,251
ffffffffc02024c8:	00004517          	auipc	a0,0x4
ffffffffc02024cc:	bc050513          	addi	a0,a0,-1088 # ffffffffc0206088 <commands+0x1090>
ffffffffc02024d0:	d05fd0ef          	jal	ra,ffffffffc02001d4 <__panic>
        assert(vma2 != NULL);
ffffffffc02024d4:	00004697          	auipc	a3,0x4
ffffffffc02024d8:	d3468693          	addi	a3,a3,-716 # ffffffffc0206208 <commands+0x1210>
ffffffffc02024dc:	00003617          	auipc	a2,0x3
ffffffffc02024e0:	4b460613          	addi	a2,a2,1204 # ffffffffc0205990 <commands+0x998>
ffffffffc02024e4:	0f900593          	li	a1,249
ffffffffc02024e8:	00004517          	auipc	a0,0x4
ffffffffc02024ec:	ba050513          	addi	a0,a0,-1120 # ffffffffc0206088 <commands+0x1090>
ffffffffc02024f0:	ce5fd0ef          	jal	ra,ffffffffc02001d4 <__panic>
        assert(vma1 != NULL);
ffffffffc02024f4:	00004697          	auipc	a3,0x4
ffffffffc02024f8:	d0468693          	addi	a3,a3,-764 # ffffffffc02061f8 <commands+0x1200>
ffffffffc02024fc:	00003617          	auipc	a2,0x3
ffffffffc0202500:	49460613          	addi	a2,a2,1172 # ffffffffc0205990 <commands+0x998>
ffffffffc0202504:	0f700593          	li	a1,247
ffffffffc0202508:	00004517          	auipc	a0,0x4
ffffffffc020250c:	b8050513          	addi	a0,a0,-1152 # ffffffffc0206088 <commands+0x1090>
ffffffffc0202510:	cc5fd0ef          	jal	ra,ffffffffc02001d4 <__panic>
        assert(vma5 == NULL);
ffffffffc0202514:	00004697          	auipc	a3,0x4
ffffffffc0202518:	d2468693          	addi	a3,a3,-732 # ffffffffc0206238 <commands+0x1240>
ffffffffc020251c:	00003617          	auipc	a2,0x3
ffffffffc0202520:	47460613          	addi	a2,a2,1140 # ffffffffc0205990 <commands+0x998>
ffffffffc0202524:	0ff00593          	li	a1,255
ffffffffc0202528:	00004517          	auipc	a0,0x4
ffffffffc020252c:	b6050513          	addi	a0,a0,-1184 # ffffffffc0206088 <commands+0x1090>
ffffffffc0202530:	ca5fd0ef          	jal	ra,ffffffffc02001d4 <__panic>
        assert(vma4 == NULL);
ffffffffc0202534:	00004697          	auipc	a3,0x4
ffffffffc0202538:	cf468693          	addi	a3,a3,-780 # ffffffffc0206228 <commands+0x1230>
ffffffffc020253c:	00003617          	auipc	a2,0x3
ffffffffc0202540:	45460613          	addi	a2,a2,1108 # ffffffffc0205990 <commands+0x998>
ffffffffc0202544:	0fd00593          	li	a1,253
ffffffffc0202548:	00004517          	auipc	a0,0x4
ffffffffc020254c:	b4050513          	addi	a0,a0,-1216 # ffffffffc0206088 <commands+0x1090>
ffffffffc0202550:	c85fd0ef          	jal	ra,ffffffffc02001d4 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0202554:	00003617          	auipc	a2,0x3
ffffffffc0202558:	31c60613          	addi	a2,a2,796 # ffffffffc0205870 <commands+0x878>
ffffffffc020255c:	06200593          	li	a1,98
ffffffffc0202560:	00003517          	auipc	a0,0x3
ffffffffc0202564:	33050513          	addi	a0,a0,816 # ffffffffc0205890 <commands+0x898>
ffffffffc0202568:	c6dfd0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(mm != NULL);
ffffffffc020256c:	00004697          	auipc	a3,0x4
ffffffffc0202570:	c2c68693          	addi	a3,a3,-980 # ffffffffc0206198 <commands+0x11a0>
ffffffffc0202574:	00003617          	auipc	a2,0x3
ffffffffc0202578:	41c60613          	addi	a2,a2,1052 # ffffffffc0205990 <commands+0x998>
ffffffffc020257c:	0d700593          	li	a1,215
ffffffffc0202580:	00004517          	auipc	a0,0x4
ffffffffc0202584:	b0850513          	addi	a0,a0,-1272 # ffffffffc0206088 <commands+0x1090>
ffffffffc0202588:	c4dfd0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc020258c:	00004697          	auipc	a3,0x4
ffffffffc0202590:	dd468693          	addi	a3,a3,-556 # ffffffffc0206360 <commands+0x1368>
ffffffffc0202594:	00003617          	auipc	a2,0x3
ffffffffc0202598:	3fc60613          	addi	a2,a2,1020 # ffffffffc0205990 <commands+0x998>
ffffffffc020259c:	14200593          	li	a1,322
ffffffffc02025a0:	00004517          	auipc	a0,0x4
ffffffffc02025a4:	ae850513          	addi	a0,a0,-1304 # ffffffffc0206088 <commands+0x1090>
ffffffffc02025a8:	c2dfd0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(pgdir[0] == 0);
ffffffffc02025ac:	00004697          	auipc	a3,0x4
ffffffffc02025b0:	d7468693          	addi	a3,a3,-652 # ffffffffc0206320 <commands+0x1328>
ffffffffc02025b4:	00003617          	auipc	a2,0x3
ffffffffc02025b8:	3dc60613          	addi	a2,a2,988 # ffffffffc0205990 <commands+0x998>
ffffffffc02025bc:	12100593          	li	a1,289
ffffffffc02025c0:	00004517          	auipc	a0,0x4
ffffffffc02025c4:	ac850513          	addi	a0,a0,-1336 # ffffffffc0206088 <commands+0x1090>
ffffffffc02025c8:	c0dfd0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(find_vma(mm, addr) == vma);
ffffffffc02025cc:	00004697          	auipc	a3,0x4
ffffffffc02025d0:	d6468693          	addi	a3,a3,-668 # ffffffffc0206330 <commands+0x1338>
ffffffffc02025d4:	00003617          	auipc	a2,0x3
ffffffffc02025d8:	3bc60613          	addi	a2,a2,956 # ffffffffc0205990 <commands+0x998>
ffffffffc02025dc:	12900593          	li	a1,297
ffffffffc02025e0:	00004517          	auipc	a0,0x4
ffffffffc02025e4:	aa850513          	addi	a0,a0,-1368 # ffffffffc0206088 <commands+0x1090>
ffffffffc02025e8:	bedfd0ef          	jal	ra,ffffffffc02001d4 <__panic>
    return KADDR(page2pa(page));
ffffffffc02025ec:	00003617          	auipc	a2,0x3
ffffffffc02025f0:	24c60613          	addi	a2,a2,588 # ffffffffc0205838 <commands+0x840>
ffffffffc02025f4:	06900593          	li	a1,105
ffffffffc02025f8:	00003517          	auipc	a0,0x3
ffffffffc02025fc:	29850513          	addi	a0,a0,664 # ffffffffc0205890 <commands+0x898>
ffffffffc0202600:	bd5fd0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(sum == 0);
ffffffffc0202604:	00004697          	auipc	a3,0x4
ffffffffc0202608:	d4c68693          	addi	a3,a3,-692 # ffffffffc0206350 <commands+0x1358>
ffffffffc020260c:	00003617          	auipc	a2,0x3
ffffffffc0202610:	38460613          	addi	a2,a2,900 # ffffffffc0205990 <commands+0x998>
ffffffffc0202614:	13500593          	li	a1,309
ffffffffc0202618:	00004517          	auipc	a0,0x4
ffffffffc020261c:	a7050513          	addi	a0,a0,-1424 # ffffffffc0206088 <commands+0x1090>
ffffffffc0202620:	bb5fd0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(check_mm_struct != NULL);
ffffffffc0202624:	00004697          	auipc	a3,0x4
ffffffffc0202628:	ce468693          	addi	a3,a3,-796 # ffffffffc0206308 <commands+0x1310>
ffffffffc020262c:	00003617          	auipc	a2,0x3
ffffffffc0202630:	36460613          	addi	a2,a2,868 # ffffffffc0205990 <commands+0x998>
ffffffffc0202634:	11d00593          	li	a1,285
ffffffffc0202638:	00004517          	auipc	a0,0x4
ffffffffc020263c:	a5050513          	addi	a0,a0,-1456 # ffffffffc0206088 <commands+0x1090>
ffffffffc0202640:	b95fd0ef          	jal	ra,ffffffffc02001d4 <__panic>

ffffffffc0202644 <do_pgfault>:
 *            was a read (0) or write (1).
 *         -- The U/S flag (bit 2) indicates whether the processor was executing at user mode (1)
 *            or supervisor mode (0) at the time of the exception.
 */
int do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr)
{
ffffffffc0202644:	7179                	addi	sp,sp,-48
    int ret = -E_INVAL;
    // try to find a vma which include addr
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0202646:	85b2                	mv	a1,a2
{
ffffffffc0202648:	f022                	sd	s0,32(sp)
ffffffffc020264a:	ec26                	sd	s1,24(sp)
ffffffffc020264c:	f406                	sd	ra,40(sp)
ffffffffc020264e:	e84a                	sd	s2,16(sp)
ffffffffc0202650:	8432                	mv	s0,a2
ffffffffc0202652:	84aa                	mv	s1,a0
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0202654:	971ff0ef          	jal	ra,ffffffffc0201fc4 <find_vma>

    pgfault_num++;
ffffffffc0202658:	00014797          	auipc	a5,0x14
ffffffffc020265c:	e3878793          	addi	a5,a5,-456 # ffffffffc0216490 <pgfault_num>
ffffffffc0202660:	439c                	lw	a5,0(a5)
ffffffffc0202662:	2785                	addiw	a5,a5,1
ffffffffc0202664:	00014717          	auipc	a4,0x14
ffffffffc0202668:	e2f72623          	sw	a5,-468(a4) # ffffffffc0216490 <pgfault_num>
    // If the addr is in the range of a mm's vma?
    if (vma == NULL || vma->vm_start > addr)
ffffffffc020266c:	c551                	beqz	a0,ffffffffc02026f8 <do_pgfault+0xb4>
ffffffffc020266e:	651c                	ld	a5,8(a0)
ffffffffc0202670:	08f46463          	bltu	s0,a5,ffffffffc02026f8 <do_pgfault+0xb4>
     *    (read  an non_existed addr && addr is readable)
     * THEN
     *    continue process
     */
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE)
ffffffffc0202674:	4d1c                	lw	a5,24(a0)
    uint32_t perm = PTE_U;
ffffffffc0202676:	4941                	li	s2,16
    if (vma->vm_flags & VM_WRITE)
ffffffffc0202678:	8b89                	andi	a5,a5,2
ffffffffc020267a:	efb1                	bnez	a5,ffffffffc02026d6 <do_pgfault+0x92>
    {
        perm |= READ_WRITE;
    }
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc020267c:	767d                	lui	a2,0xfffff

    pte_t *ptep = NULL;

    // try to find a pte, if pte's PT(Page Table) isn't existed, then create a PT.
    // (notice the 3th parameter '1')
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL)
ffffffffc020267e:	6c88                	ld	a0,24(s1)
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc0202680:	8c71                	and	s0,s0,a2
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL)
ffffffffc0202682:	85a2                	mv	a1,s0
ffffffffc0202684:	4605                	li	a2,1
ffffffffc0202686:	e2efe0ef          	jal	ra,ffffffffc0200cb4 <get_pte>
ffffffffc020268a:	c941                	beqz	a0,ffffffffc020271a <do_pgfault+0xd6>
    {
        cprintf("get_pte in do_pgfault failed\n");
        goto failed;
    }
    if (*ptep == 0)
ffffffffc020268c:	610c                	ld	a1,0(a0)
ffffffffc020268e:	c5b1                	beqz	a1,ffffffffc02026da <do_pgfault+0x96>
         *    swap_in(mm, addr, &page) : 分配一个内存页，然后根据
         *    PTE中的swap条目的addr，找到磁盘页的地址，将磁盘页的内容读入这个内存页
         *    page_insert ： 建立一个Page的phy addr与线性addr la的映射
         *    swap_map_swappable ： 设置页面可交换
         */
        if (swap_init_ok)
ffffffffc0202690:	00014797          	auipc	a5,0x14
ffffffffc0202694:	e1878793          	addi	a5,a5,-488 # ffffffffc02164a8 <swap_init_ok>
ffffffffc0202698:	439c                	lw	a5,0(a5)
ffffffffc020269a:	2781                	sext.w	a5,a5
ffffffffc020269c:	c7bd                	beqz	a5,ffffffffc020270a <do_pgfault+0xc6>
        {
            struct Page *page = NULL;
            // 你要编写的内容在这里，请基于上文说明以及下文的英文注释完成代码编写
            //(1）根据 mm 和 addr，尝试将正确的磁盘页内容加载到 page 管理的内存中。
            swap_in(mm, addr, &page);
ffffffffc020269e:	85a2                	mv	a1,s0
ffffffffc02026a0:	0030                	addi	a2,sp,8
ffffffffc02026a2:	8526                	mv	a0,s1
            struct Page *page = NULL;
ffffffffc02026a4:	e402                	sd	zero,8(sp)
            swap_in(mm, addr, &page);
ffffffffc02026a6:	5a9000ef          	jal	ra,ffffffffc020344e <swap_in>
            //(2) 根据 mm、addr 和 page，设置物理地址和逻辑地址之间的映射。
            page_insert(mm->pgdir, page, addr, perm);
ffffffffc02026aa:	65a2                	ld	a1,8(sp)
ffffffffc02026ac:	6c88                	ld	a0,24(s1)
ffffffffc02026ae:	86ca                	mv	a3,s2
ffffffffc02026b0:	8622                	mv	a2,s0
ffffffffc02026b2:	8a1fe0ef          	jal	ra,ffffffffc0200f52 <page_insert>
            //(3) 使页面可交换。
            swap_map_swappable(mm, addr, page, 1);
ffffffffc02026b6:	6622                	ld	a2,8(sp)
ffffffffc02026b8:	4685                	li	a3,1
ffffffffc02026ba:	85a2                	mv	a1,s0
ffffffffc02026bc:	8526                	mv	a0,s1
ffffffffc02026be:	46d000ef          	jal	ra,ffffffffc020332a <swap_map_swappable>
            page->pra_vaddr = addr;
ffffffffc02026c2:	6722                	ld	a4,8(sp)
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
            goto failed;
        }
    }

    ret = 0;
ffffffffc02026c4:	4781                	li	a5,0
            page->pra_vaddr = addr;
ffffffffc02026c6:	ff00                	sd	s0,56(a4)
failed:
    return ret;
}
ffffffffc02026c8:	70a2                	ld	ra,40(sp)
ffffffffc02026ca:	7402                	ld	s0,32(sp)
ffffffffc02026cc:	64e2                	ld	s1,24(sp)
ffffffffc02026ce:	6942                	ld	s2,16(sp)
ffffffffc02026d0:	853e                	mv	a0,a5
ffffffffc02026d2:	6145                	addi	sp,sp,48
ffffffffc02026d4:	8082                	ret
        perm |= READ_WRITE;
ffffffffc02026d6:	495d                	li	s2,23
ffffffffc02026d8:	b755                	j	ffffffffc020267c <do_pgfault+0x38>
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL)
ffffffffc02026da:	6c88                	ld	a0,24(s1)
ffffffffc02026dc:	864a                	mv	a2,s2
ffffffffc02026de:	85a2                	mv	a1,s0
ffffffffc02026e0:	bbcff0ef          	jal	ra,ffffffffc0201a9c <pgdir_alloc_page>
    ret = 0;
ffffffffc02026e4:	4781                	li	a5,0
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL)
ffffffffc02026e6:	f16d                	bnez	a0,ffffffffc02026c8 <do_pgfault+0x84>
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
ffffffffc02026e8:	00004517          	auipc	a0,0x4
ffffffffc02026ec:	a0050513          	addi	a0,a0,-1536 # ffffffffc02060e8 <commands+0x10f0>
ffffffffc02026f0:	9e1fd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    ret = -E_NO_MEM;
ffffffffc02026f4:	57f1                	li	a5,-4
            goto failed;
ffffffffc02026f6:	bfc9                	j	ffffffffc02026c8 <do_pgfault+0x84>
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
ffffffffc02026f8:	85a2                	mv	a1,s0
ffffffffc02026fa:	00004517          	auipc	a0,0x4
ffffffffc02026fe:	99e50513          	addi	a0,a0,-1634 # ffffffffc0206098 <commands+0x10a0>
ffffffffc0202702:	9cffd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    int ret = -E_INVAL;
ffffffffc0202706:	57f5                	li	a5,-3
        goto failed;
ffffffffc0202708:	b7c1                	j	ffffffffc02026c8 <do_pgfault+0x84>
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
ffffffffc020270a:	00004517          	auipc	a0,0x4
ffffffffc020270e:	a0650513          	addi	a0,a0,-1530 # ffffffffc0206110 <commands+0x1118>
ffffffffc0202712:	9bffd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    ret = -E_NO_MEM;
ffffffffc0202716:	57f1                	li	a5,-4
            goto failed;
ffffffffc0202718:	bf45                	j	ffffffffc02026c8 <do_pgfault+0x84>
        cprintf("get_pte in do_pgfault failed\n");
ffffffffc020271a:	00004517          	auipc	a0,0x4
ffffffffc020271e:	9ae50513          	addi	a0,a0,-1618 # ffffffffc02060c8 <commands+0x10d0>
ffffffffc0202722:	9affd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    ret = -E_NO_MEM;
ffffffffc0202726:	57f1                	li	a5,-4
        goto failed;
ffffffffc0202728:	b745                	j	ffffffffc02026c8 <do_pgfault+0x84>

ffffffffc020272a <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc020272a:	c125                	beqz	a0,ffffffffc020278a <slob_free+0x60>
		return;

	if (size)
ffffffffc020272c:	e1a5                	bnez	a1,ffffffffc020278c <slob_free+0x62>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020272e:	100027f3          	csrr	a5,sstatus
ffffffffc0202732:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0202734:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202736:	e3bd                	bnez	a5,ffffffffc020279c <slob_free+0x72>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0202738:	00009797          	auipc	a5,0x9
ffffffffc020273c:	91878793          	addi	a5,a5,-1768 # ffffffffc020b050 <slobfree>
ffffffffc0202740:	639c                	ld	a5,0(a5)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0202742:	6798                	ld	a4,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0202744:	00a7fa63          	bgeu	a5,a0,ffffffffc0202758 <slob_free+0x2e>
ffffffffc0202748:	00e56c63          	bltu	a0,a4,ffffffffc0202760 <slob_free+0x36>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc020274c:	00e7fa63          	bgeu	a5,a4,ffffffffc0202760 <slob_free+0x36>
    return 0;
ffffffffc0202750:	87ba                	mv	a5,a4
ffffffffc0202752:	6798                	ld	a4,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0202754:	fea7eae3          	bltu	a5,a0,ffffffffc0202748 <slob_free+0x1e>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0202758:	fee7ece3          	bltu	a5,a4,ffffffffc0202750 <slob_free+0x26>
ffffffffc020275c:	fee57ae3          	bgeu	a0,a4,ffffffffc0202750 <slob_free+0x26>
			break;

	if (b + b->units == cur->next) {
ffffffffc0202760:	4110                	lw	a2,0(a0)
ffffffffc0202762:	00461693          	slli	a3,a2,0x4
ffffffffc0202766:	96aa                	add	a3,a3,a0
ffffffffc0202768:	08d70b63          	beq	a4,a3,ffffffffc02027fe <slob_free+0xd4>
		b->units += cur->next->units;
		b->next = cur->next->next;
	} else
		b->next = cur->next;

	if (cur + cur->units == b) {
ffffffffc020276c:	4394                	lw	a3,0(a5)
		b->next = cur->next;
ffffffffc020276e:	e518                	sd	a4,8(a0)
	if (cur + cur->units == b) {
ffffffffc0202770:	00469713          	slli	a4,a3,0x4
ffffffffc0202774:	973e                	add	a4,a4,a5
ffffffffc0202776:	08e50f63          	beq	a0,a4,ffffffffc0202814 <slob_free+0xea>
		cur->units += b->units;
		cur->next = b->next;
	} else
		cur->next = b;
ffffffffc020277a:	e788                	sd	a0,8(a5)

	slobfree = cur;
ffffffffc020277c:	00009717          	auipc	a4,0x9
ffffffffc0202780:	8cf73a23          	sd	a5,-1836(a4) # ffffffffc020b050 <slobfree>
    if (flag) {
ffffffffc0202784:	c199                	beqz	a1,ffffffffc020278a <slob_free+0x60>
        intr_enable();
ffffffffc0202786:	e47fd06f          	j	ffffffffc02005cc <intr_enable>
ffffffffc020278a:	8082                	ret
		b->units = SLOB_UNITS(size);
ffffffffc020278c:	05bd                	addi	a1,a1,15
ffffffffc020278e:	8191                	srli	a1,a1,0x4
ffffffffc0202790:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202792:	100027f3          	csrr	a5,sstatus
ffffffffc0202796:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0202798:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020279a:	dfd9                	beqz	a5,ffffffffc0202738 <slob_free+0xe>
{
ffffffffc020279c:	1101                	addi	sp,sp,-32
ffffffffc020279e:	e42a                	sd	a0,8(sp)
ffffffffc02027a0:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc02027a2:	e31fd0ef          	jal	ra,ffffffffc02005d2 <intr_disable>
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02027a6:	00009797          	auipc	a5,0x9
ffffffffc02027aa:	8aa78793          	addi	a5,a5,-1878 # ffffffffc020b050 <slobfree>
ffffffffc02027ae:	639c                	ld	a5,0(a5)
        return 1;
ffffffffc02027b0:	6522                	ld	a0,8(sp)
ffffffffc02027b2:	4585                	li	a1,1
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02027b4:	6798                	ld	a4,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02027b6:	00a7fa63          	bgeu	a5,a0,ffffffffc02027ca <slob_free+0xa0>
ffffffffc02027ba:	00e56c63          	bltu	a0,a4,ffffffffc02027d2 <slob_free+0xa8>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02027be:	00e7fa63          	bgeu	a5,a4,ffffffffc02027d2 <slob_free+0xa8>
    return 0;
ffffffffc02027c2:	87ba                	mv	a5,a4
ffffffffc02027c4:	6798                	ld	a4,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02027c6:	fea7eae3          	bltu	a5,a0,ffffffffc02027ba <slob_free+0x90>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02027ca:	fee7ece3          	bltu	a5,a4,ffffffffc02027c2 <slob_free+0x98>
ffffffffc02027ce:	fee57ae3          	bgeu	a0,a4,ffffffffc02027c2 <slob_free+0x98>
	if (b + b->units == cur->next) {
ffffffffc02027d2:	4110                	lw	a2,0(a0)
ffffffffc02027d4:	00461693          	slli	a3,a2,0x4
ffffffffc02027d8:	96aa                	add	a3,a3,a0
ffffffffc02027da:	04d70763          	beq	a4,a3,ffffffffc0202828 <slob_free+0xfe>
		b->next = cur->next;
ffffffffc02027de:	e518                	sd	a4,8(a0)
	if (cur + cur->units == b) {
ffffffffc02027e0:	4394                	lw	a3,0(a5)
ffffffffc02027e2:	00469713          	slli	a4,a3,0x4
ffffffffc02027e6:	973e                	add	a4,a4,a5
ffffffffc02027e8:	04e50663          	beq	a0,a4,ffffffffc0202834 <slob_free+0x10a>
		cur->next = b;
ffffffffc02027ec:	e788                	sd	a0,8(a5)
	slobfree = cur;
ffffffffc02027ee:	00009717          	auipc	a4,0x9
ffffffffc02027f2:	86f73123          	sd	a5,-1950(a4) # ffffffffc020b050 <slobfree>
    if (flag) {
ffffffffc02027f6:	e58d                	bnez	a1,ffffffffc0202820 <slob_free+0xf6>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc02027f8:	60e2                	ld	ra,24(sp)
ffffffffc02027fa:	6105                	addi	sp,sp,32
ffffffffc02027fc:	8082                	ret
		b->units += cur->next->units;
ffffffffc02027fe:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0202800:	6718                	ld	a4,8(a4)
		b->units += cur->next->units;
ffffffffc0202802:	9e35                	addw	a2,a2,a3
ffffffffc0202804:	c110                	sw	a2,0(a0)
	if (cur + cur->units == b) {
ffffffffc0202806:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0202808:	e518                	sd	a4,8(a0)
	if (cur + cur->units == b) {
ffffffffc020280a:	00469713          	slli	a4,a3,0x4
ffffffffc020280e:	973e                	add	a4,a4,a5
ffffffffc0202810:	f6e515e3          	bne	a0,a4,ffffffffc020277a <slob_free+0x50>
		cur->units += b->units;
ffffffffc0202814:	4118                	lw	a4,0(a0)
		cur->next = b->next;
ffffffffc0202816:	6510                	ld	a2,8(a0)
		cur->units += b->units;
ffffffffc0202818:	9eb9                	addw	a3,a3,a4
ffffffffc020281a:	c394                	sw	a3,0(a5)
		cur->next = b->next;
ffffffffc020281c:	e790                	sd	a2,8(a5)
ffffffffc020281e:	bfb9                	j	ffffffffc020277c <slob_free+0x52>
}
ffffffffc0202820:	60e2                	ld	ra,24(sp)
ffffffffc0202822:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0202824:	da9fd06f          	j	ffffffffc02005cc <intr_enable>
		b->units += cur->next->units;
ffffffffc0202828:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc020282a:	6718                	ld	a4,8(a4)
		b->units += cur->next->units;
ffffffffc020282c:	9e35                	addw	a2,a2,a3
ffffffffc020282e:	c110                	sw	a2,0(a0)
		b->next = cur->next->next;
ffffffffc0202830:	e518                	sd	a4,8(a0)
ffffffffc0202832:	b77d                	j	ffffffffc02027e0 <slob_free+0xb6>
		cur->units += b->units;
ffffffffc0202834:	4118                	lw	a4,0(a0)
		cur->next = b->next;
ffffffffc0202836:	6510                	ld	a2,8(a0)
		cur->units += b->units;
ffffffffc0202838:	9eb9                	addw	a3,a3,a4
ffffffffc020283a:	c394                	sw	a3,0(a5)
		cur->next = b->next;
ffffffffc020283c:	e790                	sd	a2,8(a5)
ffffffffc020283e:	bf45                	j	ffffffffc02027ee <slob_free+0xc4>

ffffffffc0202840 <__slob_get_free_pages.isra.0>:
  struct Page * page = alloc_pages(1 << order);
ffffffffc0202840:	4785                	li	a5,1
static void* __slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0202842:	1141                	addi	sp,sp,-16
  struct Page * page = alloc_pages(1 << order);
ffffffffc0202844:	00a7953b          	sllw	a0,a5,a0
static void* __slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0202848:	e406                	sd	ra,8(sp)
  struct Page * page = alloc_pages(1 << order);
ffffffffc020284a:	b5cfe0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
  if(!page)
ffffffffc020284e:	cd1d                	beqz	a0,ffffffffc020288c <__slob_get_free_pages.isra.0+0x4c>
    return page - pages + nbase;
ffffffffc0202850:	00014797          	auipc	a5,0x14
ffffffffc0202854:	ca078793          	addi	a5,a5,-864 # ffffffffc02164f0 <pages>
ffffffffc0202858:	6394                	ld	a3,0(a5)
ffffffffc020285a:	00004797          	auipc	a5,0x4
ffffffffc020285e:	7c678793          	addi	a5,a5,1990 # ffffffffc0207020 <nbase>
ffffffffc0202862:	8d15                	sub	a0,a0,a3
ffffffffc0202864:	6394                	ld	a3,0(a5)
ffffffffc0202866:	8519                	srai	a0,a0,0x6
    return KADDR(page2pa(page));
ffffffffc0202868:	00014797          	auipc	a5,0x14
ffffffffc020286c:	c2078793          	addi	a5,a5,-992 # ffffffffc0216488 <npage>
    return page - pages + nbase;
ffffffffc0202870:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc0202872:	6398                	ld	a4,0(a5)
ffffffffc0202874:	00c51793          	slli	a5,a0,0xc
ffffffffc0202878:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc020287a:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc020287c:	00e7fb63          	bgeu	a5,a4,ffffffffc0202892 <__slob_get_free_pages.isra.0+0x52>
ffffffffc0202880:	00014797          	auipc	a5,0x14
ffffffffc0202884:	c6078793          	addi	a5,a5,-928 # ffffffffc02164e0 <va_pa_offset>
ffffffffc0202888:	6394                	ld	a3,0(a5)
ffffffffc020288a:	9536                	add	a0,a0,a3
}
ffffffffc020288c:	60a2                	ld	ra,8(sp)
ffffffffc020288e:	0141                	addi	sp,sp,16
ffffffffc0202890:	8082                	ret
ffffffffc0202892:	86aa                	mv	a3,a0
ffffffffc0202894:	00003617          	auipc	a2,0x3
ffffffffc0202898:	fa460613          	addi	a2,a2,-92 # ffffffffc0205838 <commands+0x840>
ffffffffc020289c:	06900593          	li	a1,105
ffffffffc02028a0:	00003517          	auipc	a0,0x3
ffffffffc02028a4:	ff050513          	addi	a0,a0,-16 # ffffffffc0205890 <commands+0x898>
ffffffffc02028a8:	92dfd0ef          	jal	ra,ffffffffc02001d4 <__panic>

ffffffffc02028ac <slob_alloc.isra.1.constprop.3>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc02028ac:	1101                	addi	sp,sp,-32
ffffffffc02028ae:	ec06                	sd	ra,24(sp)
ffffffffc02028b0:	e822                	sd	s0,16(sp)
ffffffffc02028b2:	e426                	sd	s1,8(sp)
ffffffffc02028b4:	e04a                	sd	s2,0(sp)
	assert( (size + SLOB_UNIT) < PAGE_SIZE );
ffffffffc02028b6:	01050713          	addi	a4,a0,16
ffffffffc02028ba:	6785                	lui	a5,0x1
ffffffffc02028bc:	0cf77563          	bgeu	a4,a5,ffffffffc0202986 <slob_alloc.isra.1.constprop.3+0xda>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc02028c0:	00f50493          	addi	s1,a0,15
ffffffffc02028c4:	8091                	srli	s1,s1,0x4
ffffffffc02028c6:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02028c8:	10002673          	csrr	a2,sstatus
ffffffffc02028cc:	8a09                	andi	a2,a2,2
ffffffffc02028ce:	e64d                	bnez	a2,ffffffffc0202978 <slob_alloc.isra.1.constprop.3+0xcc>
	prev = slobfree;
ffffffffc02028d0:	00008917          	auipc	s2,0x8
ffffffffc02028d4:	78090913          	addi	s2,s2,1920 # ffffffffc020b050 <slobfree>
ffffffffc02028d8:	00093683          	ld	a3,0(s2)
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc02028dc:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc02028de:	4398                	lw	a4,0(a5)
ffffffffc02028e0:	0a975063          	bge	a4,s1,ffffffffc0202980 <slob_alloc.isra.1.constprop.3+0xd4>
		if (cur == slobfree) {
ffffffffc02028e4:	00d78b63          	beq	a5,a3,ffffffffc02028fa <slob_alloc.isra.1.constprop.3+0x4e>
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc02028e8:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc02028ea:	4018                	lw	a4,0(s0)
ffffffffc02028ec:	02975a63          	bge	a4,s1,ffffffffc0202920 <slob_alloc.isra.1.constprop.3+0x74>
ffffffffc02028f0:	00093683          	ld	a3,0(s2)
ffffffffc02028f4:	87a2                	mv	a5,s0
		if (cur == slobfree) {
ffffffffc02028f6:	fed799e3          	bne	a5,a3,ffffffffc02028e8 <slob_alloc.isra.1.constprop.3+0x3c>
    if (flag) {
ffffffffc02028fa:	e225                	bnez	a2,ffffffffc020295a <slob_alloc.isra.1.constprop.3+0xae>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc02028fc:	4501                	li	a0,0
ffffffffc02028fe:	f43ff0ef          	jal	ra,ffffffffc0202840 <__slob_get_free_pages.isra.0>
ffffffffc0202902:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0202904:	cd15                	beqz	a0,ffffffffc0202940 <slob_alloc.isra.1.constprop.3+0x94>
			slob_free(cur, PAGE_SIZE);
ffffffffc0202906:	6585                	lui	a1,0x1
ffffffffc0202908:	e23ff0ef          	jal	ra,ffffffffc020272a <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020290c:	10002673          	csrr	a2,sstatus
ffffffffc0202910:	8a09                	andi	a2,a2,2
ffffffffc0202912:	ee15                	bnez	a2,ffffffffc020294e <slob_alloc.isra.1.constprop.3+0xa2>
			cur = slobfree;
ffffffffc0202914:	00093783          	ld	a5,0(s2)
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc0202918:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc020291a:	4018                	lw	a4,0(s0)
ffffffffc020291c:	fc974ae3          	blt	a4,s1,ffffffffc02028f0 <slob_alloc.isra.1.constprop.3+0x44>
			if (cur->units == units) /* exact fit? */
ffffffffc0202920:	04e48963          	beq	s1,a4,ffffffffc0202972 <slob_alloc.isra.1.constprop.3+0xc6>
				prev->next = cur + units;
ffffffffc0202924:	00449693          	slli	a3,s1,0x4
ffffffffc0202928:	96a2                	add	a3,a3,s0
ffffffffc020292a:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc020292c:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc020292e:	9f05                	subw	a4,a4,s1
ffffffffc0202930:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0202932:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0202934:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0202936:	00008717          	auipc	a4,0x8
ffffffffc020293a:	70f73d23          	sd	a5,1818(a4) # ffffffffc020b050 <slobfree>
    if (flag) {
ffffffffc020293e:	e20d                	bnez	a2,ffffffffc0202960 <slob_alloc.isra.1.constprop.3+0xb4>
}
ffffffffc0202940:	8522                	mv	a0,s0
ffffffffc0202942:	60e2                	ld	ra,24(sp)
ffffffffc0202944:	6442                	ld	s0,16(sp)
ffffffffc0202946:	64a2                	ld	s1,8(sp)
ffffffffc0202948:	6902                	ld	s2,0(sp)
ffffffffc020294a:	6105                	addi	sp,sp,32
ffffffffc020294c:	8082                	ret
        intr_disable();
ffffffffc020294e:	c85fd0ef          	jal	ra,ffffffffc02005d2 <intr_disable>
ffffffffc0202952:	4605                	li	a2,1
			cur = slobfree;
ffffffffc0202954:	00093783          	ld	a5,0(s2)
ffffffffc0202958:	b7c1                	j	ffffffffc0202918 <slob_alloc.isra.1.constprop.3+0x6c>
        intr_enable();
ffffffffc020295a:	c73fd0ef          	jal	ra,ffffffffc02005cc <intr_enable>
ffffffffc020295e:	bf79                	j	ffffffffc02028fc <slob_alloc.isra.1.constprop.3+0x50>
ffffffffc0202960:	c6dfd0ef          	jal	ra,ffffffffc02005cc <intr_enable>
}
ffffffffc0202964:	8522                	mv	a0,s0
ffffffffc0202966:	60e2                	ld	ra,24(sp)
ffffffffc0202968:	6442                	ld	s0,16(sp)
ffffffffc020296a:	64a2                	ld	s1,8(sp)
ffffffffc020296c:	6902                	ld	s2,0(sp)
ffffffffc020296e:	6105                	addi	sp,sp,32
ffffffffc0202970:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0202972:	6418                	ld	a4,8(s0)
ffffffffc0202974:	e798                	sd	a4,8(a5)
ffffffffc0202976:	b7c1                	j	ffffffffc0202936 <slob_alloc.isra.1.constprop.3+0x8a>
        intr_disable();
ffffffffc0202978:	c5bfd0ef          	jal	ra,ffffffffc02005d2 <intr_disable>
ffffffffc020297c:	4605                	li	a2,1
ffffffffc020297e:	bf89                	j	ffffffffc02028d0 <slob_alloc.isra.1.constprop.3+0x24>
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0202980:	843e                	mv	s0,a5
ffffffffc0202982:	87b6                	mv	a5,a3
ffffffffc0202984:	bf71                	j	ffffffffc0202920 <slob_alloc.isra.1.constprop.3+0x74>
	assert( (size + SLOB_UNIT) < PAGE_SIZE );
ffffffffc0202986:	00004697          	auipc	a3,0x4
ffffffffc020298a:	a6a68693          	addi	a3,a3,-1430 # ffffffffc02063f0 <commands+0x13f8>
ffffffffc020298e:	00003617          	auipc	a2,0x3
ffffffffc0202992:	00260613          	addi	a2,a2,2 # ffffffffc0205990 <commands+0x998>
ffffffffc0202996:	06300593          	li	a1,99
ffffffffc020299a:	00004517          	auipc	a0,0x4
ffffffffc020299e:	a7650513          	addi	a0,a0,-1418 # ffffffffc0206410 <commands+0x1418>
ffffffffc02029a2:	833fd0ef          	jal	ra,ffffffffc02001d4 <__panic>

ffffffffc02029a6 <kmalloc_init>:
slob_init(void) {
  cprintf("use SLOB allocator\n");
}

inline void 
kmalloc_init(void) {
ffffffffc02029a6:	1141                	addi	sp,sp,-16
  cprintf("use SLOB allocator\n");
ffffffffc02029a8:	00004517          	auipc	a0,0x4
ffffffffc02029ac:	a8050513          	addi	a0,a0,-1408 # ffffffffc0206428 <commands+0x1430>
kmalloc_init(void) {
ffffffffc02029b0:	e406                	sd	ra,8(sp)
  cprintf("use SLOB allocator\n");
ffffffffc02029b2:	f1efd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    slob_init();
    cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc02029b6:	60a2                	ld	ra,8(sp)
    cprintf("kmalloc_init() succeeded!\n");
ffffffffc02029b8:	00004517          	auipc	a0,0x4
ffffffffc02029bc:	a1850513          	addi	a0,a0,-1512 # ffffffffc02063d0 <commands+0x13d8>
}
ffffffffc02029c0:	0141                	addi	sp,sp,16
    cprintf("kmalloc_init() succeeded!\n");
ffffffffc02029c2:	f0efd06f          	j	ffffffffc02000d0 <cprintf>

ffffffffc02029c6 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc02029c6:	1101                	addi	sp,sp,-32
ffffffffc02029c8:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc02029ca:	6905                	lui	s2,0x1
{
ffffffffc02029cc:	e822                	sd	s0,16(sp)
ffffffffc02029ce:	ec06                	sd	ra,24(sp)
ffffffffc02029d0:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc02029d2:	fef90793          	addi	a5,s2,-17 # fef <BASE_ADDRESS-0xffffffffc01ff011>
{
ffffffffc02029d6:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc02029d8:	04a7fc63          	bgeu	a5,a0,ffffffffc0202a30 <kmalloc+0x6a>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc02029dc:	4561                	li	a0,24
ffffffffc02029de:	ecfff0ef          	jal	ra,ffffffffc02028ac <slob_alloc.isra.1.constprop.3>
ffffffffc02029e2:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc02029e4:	cd21                	beqz	a0,ffffffffc0202a3c <kmalloc+0x76>
	bb->order = find_order(size);
ffffffffc02029e6:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc02029ea:	4501                	li	a0,0
	for ( ; size > 4096 ; size >>=1)
ffffffffc02029ec:	00f95763          	bge	s2,a5,ffffffffc02029fa <kmalloc+0x34>
ffffffffc02029f0:	6705                	lui	a4,0x1
ffffffffc02029f2:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc02029f4:	2505                	addiw	a0,a0,1
	for ( ; size > 4096 ; size >>=1)
ffffffffc02029f6:	fef74ee3          	blt	a4,a5,ffffffffc02029f2 <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc02029fa:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc02029fc:	e45ff0ef          	jal	ra,ffffffffc0202840 <__slob_get_free_pages.isra.0>
ffffffffc0202a00:	e488                	sd	a0,8(s1)
ffffffffc0202a02:	842a                	mv	s0,a0
	if (bb->pages) {
ffffffffc0202a04:	c935                	beqz	a0,ffffffffc0202a78 <kmalloc+0xb2>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202a06:	100027f3          	csrr	a5,sstatus
ffffffffc0202a0a:	8b89                	andi	a5,a5,2
ffffffffc0202a0c:	e3a1                	bnez	a5,ffffffffc0202a4c <kmalloc+0x86>
		bb->next = bigblocks;
ffffffffc0202a0e:	00014797          	auipc	a5,0x14
ffffffffc0202a12:	a8a78793          	addi	a5,a5,-1398 # ffffffffc0216498 <bigblocks>
ffffffffc0202a16:	639c                	ld	a5,0(a5)
		bigblocks = bb;
ffffffffc0202a18:	00014717          	auipc	a4,0x14
ffffffffc0202a1c:	a8973023          	sd	s1,-1408(a4) # ffffffffc0216498 <bigblocks>
		bb->next = bigblocks;
ffffffffc0202a20:	e89c                	sd	a5,16(s1)
  return __kmalloc(size, 0);
}
ffffffffc0202a22:	8522                	mv	a0,s0
ffffffffc0202a24:	60e2                	ld	ra,24(sp)
ffffffffc0202a26:	6442                	ld	s0,16(sp)
ffffffffc0202a28:	64a2                	ld	s1,8(sp)
ffffffffc0202a2a:	6902                	ld	s2,0(sp)
ffffffffc0202a2c:	6105                	addi	sp,sp,32
ffffffffc0202a2e:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0202a30:	0541                	addi	a0,a0,16
ffffffffc0202a32:	e7bff0ef          	jal	ra,ffffffffc02028ac <slob_alloc.isra.1.constprop.3>
		return m ? (void *)(m + 1) : 0;
ffffffffc0202a36:	01050413          	addi	s0,a0,16
ffffffffc0202a3a:	f565                	bnez	a0,ffffffffc0202a22 <kmalloc+0x5c>
ffffffffc0202a3c:	4401                	li	s0,0
}
ffffffffc0202a3e:	8522                	mv	a0,s0
ffffffffc0202a40:	60e2                	ld	ra,24(sp)
ffffffffc0202a42:	6442                	ld	s0,16(sp)
ffffffffc0202a44:	64a2                	ld	s1,8(sp)
ffffffffc0202a46:	6902                	ld	s2,0(sp)
ffffffffc0202a48:	6105                	addi	sp,sp,32
ffffffffc0202a4a:	8082                	ret
        intr_disable();
ffffffffc0202a4c:	b87fd0ef          	jal	ra,ffffffffc02005d2 <intr_disable>
		bb->next = bigblocks;
ffffffffc0202a50:	00014797          	auipc	a5,0x14
ffffffffc0202a54:	a4878793          	addi	a5,a5,-1464 # ffffffffc0216498 <bigblocks>
ffffffffc0202a58:	639c                	ld	a5,0(a5)
		bigblocks = bb;
ffffffffc0202a5a:	00014717          	auipc	a4,0x14
ffffffffc0202a5e:	a2973f23          	sd	s1,-1474(a4) # ffffffffc0216498 <bigblocks>
		bb->next = bigblocks;
ffffffffc0202a62:	e89c                	sd	a5,16(s1)
        intr_enable();
ffffffffc0202a64:	b69fd0ef          	jal	ra,ffffffffc02005cc <intr_enable>
ffffffffc0202a68:	6480                	ld	s0,8(s1)
}
ffffffffc0202a6a:	60e2                	ld	ra,24(sp)
ffffffffc0202a6c:	64a2                	ld	s1,8(sp)
ffffffffc0202a6e:	8522                	mv	a0,s0
ffffffffc0202a70:	6442                	ld	s0,16(sp)
ffffffffc0202a72:	6902                	ld	s2,0(sp)
ffffffffc0202a74:	6105                	addi	sp,sp,32
ffffffffc0202a76:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0202a78:	45e1                	li	a1,24
ffffffffc0202a7a:	8526                	mv	a0,s1
ffffffffc0202a7c:	cafff0ef          	jal	ra,ffffffffc020272a <slob_free>
  return __kmalloc(size, 0);
ffffffffc0202a80:	b74d                	j	ffffffffc0202a22 <kmalloc+0x5c>

ffffffffc0202a82 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0202a82:	c175                	beqz	a0,ffffffffc0202b66 <kfree+0xe4>
{
ffffffffc0202a84:	1101                	addi	sp,sp,-32
ffffffffc0202a86:	e426                	sd	s1,8(sp)
ffffffffc0202a88:	ec06                	sd	ra,24(sp)
ffffffffc0202a8a:	e822                	sd	s0,16(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE-1))) {
ffffffffc0202a8c:	03451793          	slli	a5,a0,0x34
ffffffffc0202a90:	84aa                	mv	s1,a0
ffffffffc0202a92:	eb8d                	bnez	a5,ffffffffc0202ac4 <kfree+0x42>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202a94:	100027f3          	csrr	a5,sstatus
ffffffffc0202a98:	8b89                	andi	a5,a5,2
ffffffffc0202a9a:	efc9                	bnez	a5,ffffffffc0202b34 <kfree+0xb2>
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0202a9c:	00014797          	auipc	a5,0x14
ffffffffc0202aa0:	9fc78793          	addi	a5,a5,-1540 # ffffffffc0216498 <bigblocks>
ffffffffc0202aa4:	6394                	ld	a3,0(a5)
ffffffffc0202aa6:	ce99                	beqz	a3,ffffffffc0202ac4 <kfree+0x42>
			if (bb->pages == block) {
ffffffffc0202aa8:	669c                	ld	a5,8(a3)
ffffffffc0202aaa:	6a80                	ld	s0,16(a3)
ffffffffc0202aac:	0af50e63          	beq	a0,a5,ffffffffc0202b68 <kfree+0xe6>
    return 0;
ffffffffc0202ab0:	4601                	li	a2,0
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0202ab2:	c801                	beqz	s0,ffffffffc0202ac2 <kfree+0x40>
			if (bb->pages == block) {
ffffffffc0202ab4:	6418                	ld	a4,8(s0)
ffffffffc0202ab6:	681c                	ld	a5,16(s0)
ffffffffc0202ab8:	00970f63          	beq	a4,s1,ffffffffc0202ad6 <kfree+0x54>
ffffffffc0202abc:	86a2                	mv	a3,s0
ffffffffc0202abe:	843e                	mv	s0,a5
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0202ac0:	f875                	bnez	s0,ffffffffc0202ab4 <kfree+0x32>
    if (flag) {
ffffffffc0202ac2:	e659                	bnez	a2,ffffffffc0202b50 <kfree+0xce>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0202ac4:	6442                	ld	s0,16(sp)
ffffffffc0202ac6:	60e2                	ld	ra,24(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0202ac8:	ff048513          	addi	a0,s1,-16
}
ffffffffc0202acc:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0202ace:	4581                	li	a1,0
}
ffffffffc0202ad0:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0202ad2:	c59ff06f          	j	ffffffffc020272a <slob_free>
				*last = bb->next;
ffffffffc0202ad6:	ea9c                	sd	a5,16(a3)
ffffffffc0202ad8:	e641                	bnez	a2,ffffffffc0202b60 <kfree+0xde>
    return pa2page(PADDR(kva));
ffffffffc0202ada:	c02007b7          	lui	a5,0xc0200
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0202ade:	4018                	lw	a4,0(s0)
ffffffffc0202ae0:	08f4ea63          	bltu	s1,a5,ffffffffc0202b74 <kfree+0xf2>
ffffffffc0202ae4:	00014797          	auipc	a5,0x14
ffffffffc0202ae8:	9fc78793          	addi	a5,a5,-1540 # ffffffffc02164e0 <va_pa_offset>
ffffffffc0202aec:	6394                	ld	a3,0(a5)
    if (PPN(pa) >= npage) {
ffffffffc0202aee:	00014797          	auipc	a5,0x14
ffffffffc0202af2:	99a78793          	addi	a5,a5,-1638 # ffffffffc0216488 <npage>
ffffffffc0202af6:	639c                	ld	a5,0(a5)
    return pa2page(PADDR(kva));
ffffffffc0202af8:	8c95                	sub	s1,s1,a3
    if (PPN(pa) >= npage) {
ffffffffc0202afa:	80b1                	srli	s1,s1,0xc
ffffffffc0202afc:	08f4f963          	bgeu	s1,a5,ffffffffc0202b8e <kfree+0x10c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b00:	00004797          	auipc	a5,0x4
ffffffffc0202b04:	52078793          	addi	a5,a5,1312 # ffffffffc0207020 <nbase>
ffffffffc0202b08:	639c                	ld	a5,0(a5)
ffffffffc0202b0a:	00014697          	auipc	a3,0x14
ffffffffc0202b0e:	9e668693          	addi	a3,a3,-1562 # ffffffffc02164f0 <pages>
ffffffffc0202b12:	6288                	ld	a0,0(a3)
ffffffffc0202b14:	8c9d                	sub	s1,s1,a5
ffffffffc0202b16:	049a                	slli	s1,s1,0x6
  free_pages(kva2page(kva), 1 << order);
ffffffffc0202b18:	4585                	li	a1,1
ffffffffc0202b1a:	9526                	add	a0,a0,s1
ffffffffc0202b1c:	00e595bb          	sllw	a1,a1,a4
ffffffffc0202b20:	90efe0ef          	jal	ra,ffffffffc0200c2e <free_pages>
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0202b24:	8522                	mv	a0,s0
}
ffffffffc0202b26:	6442                	ld	s0,16(sp)
ffffffffc0202b28:	60e2                	ld	ra,24(sp)
ffffffffc0202b2a:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0202b2c:	45e1                	li	a1,24
}
ffffffffc0202b2e:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0202b30:	bfbff06f          	j	ffffffffc020272a <slob_free>
        intr_disable();
ffffffffc0202b34:	a9ffd0ef          	jal	ra,ffffffffc02005d2 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0202b38:	00014797          	auipc	a5,0x14
ffffffffc0202b3c:	96078793          	addi	a5,a5,-1696 # ffffffffc0216498 <bigblocks>
ffffffffc0202b40:	6394                	ld	a3,0(a5)
ffffffffc0202b42:	c699                	beqz	a3,ffffffffc0202b50 <kfree+0xce>
			if (bb->pages == block) {
ffffffffc0202b44:	669c                	ld	a5,8(a3)
ffffffffc0202b46:	6a80                	ld	s0,16(a3)
ffffffffc0202b48:	00f48763          	beq	s1,a5,ffffffffc0202b56 <kfree+0xd4>
        return 1;
ffffffffc0202b4c:	4605                	li	a2,1
ffffffffc0202b4e:	b795                	j	ffffffffc0202ab2 <kfree+0x30>
        intr_enable();
ffffffffc0202b50:	a7dfd0ef          	jal	ra,ffffffffc02005cc <intr_enable>
ffffffffc0202b54:	bf85                	j	ffffffffc0202ac4 <kfree+0x42>
				*last = bb->next;
ffffffffc0202b56:	00014797          	auipc	a5,0x14
ffffffffc0202b5a:	9487b123          	sd	s0,-1726(a5) # ffffffffc0216498 <bigblocks>
ffffffffc0202b5e:	8436                	mv	s0,a3
ffffffffc0202b60:	a6dfd0ef          	jal	ra,ffffffffc02005cc <intr_enable>
ffffffffc0202b64:	bf9d                	j	ffffffffc0202ada <kfree+0x58>
ffffffffc0202b66:	8082                	ret
ffffffffc0202b68:	00014797          	auipc	a5,0x14
ffffffffc0202b6c:	9287b823          	sd	s0,-1744(a5) # ffffffffc0216498 <bigblocks>
ffffffffc0202b70:	8436                	mv	s0,a3
ffffffffc0202b72:	b7a5                	j	ffffffffc0202ada <kfree+0x58>
    return pa2page(PADDR(kva));
ffffffffc0202b74:	86a6                	mv	a3,s1
ffffffffc0202b76:	00003617          	auipc	a2,0x3
ffffffffc0202b7a:	d9a60613          	addi	a2,a2,-614 # ffffffffc0205910 <commands+0x918>
ffffffffc0202b7e:	06e00593          	li	a1,110
ffffffffc0202b82:	00003517          	auipc	a0,0x3
ffffffffc0202b86:	d0e50513          	addi	a0,a0,-754 # ffffffffc0205890 <commands+0x898>
ffffffffc0202b8a:	e4afd0ef          	jal	ra,ffffffffc02001d4 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0202b8e:	00003617          	auipc	a2,0x3
ffffffffc0202b92:	ce260613          	addi	a2,a2,-798 # ffffffffc0205870 <commands+0x878>
ffffffffc0202b96:	06200593          	li	a1,98
ffffffffc0202b9a:	00003517          	auipc	a0,0x3
ffffffffc0202b9e:	cf650513          	addi	a0,a0,-778 # ffffffffc0205890 <commands+0x898>
ffffffffc0202ba2:	e32fd0ef          	jal	ra,ffffffffc02001d4 <__panic>

ffffffffc0202ba6 <swap_init>:

static void check_swap(void);

int
swap_init(void)
{
ffffffffc0202ba6:	7135                	addi	sp,sp,-160
ffffffffc0202ba8:	ed06                	sd	ra,152(sp)
ffffffffc0202baa:	e922                	sd	s0,144(sp)
ffffffffc0202bac:	e526                	sd	s1,136(sp)
ffffffffc0202bae:	e14a                	sd	s2,128(sp)
ffffffffc0202bb0:	fcce                	sd	s3,120(sp)
ffffffffc0202bb2:	f8d2                	sd	s4,112(sp)
ffffffffc0202bb4:	f4d6                	sd	s5,104(sp)
ffffffffc0202bb6:	f0da                	sd	s6,96(sp)
ffffffffc0202bb8:	ecde                	sd	s7,88(sp)
ffffffffc0202bba:	e8e2                	sd	s8,80(sp)
ffffffffc0202bbc:	e4e6                	sd	s9,72(sp)
ffffffffc0202bbe:	e0ea                	sd	s10,64(sp)
ffffffffc0202bc0:	fc6e                	sd	s11,56(sp)
     swapfs_init();
ffffffffc0202bc2:	4a2010ef          	jal	ra,ffffffffc0204064 <swapfs_init>
     // if (!(1024 <= max_swap_offset && max_swap_offset < MAX_SWAP_OFFSET_LIMIT))
     // {
     //      panic("bad max_swap_offset %08x.\n", max_swap_offset);
     // }
     // Since the IDE is faked, it can only store 7 pages at most to pass the test
     if (!(7 <= max_swap_offset &&
ffffffffc0202bc6:	00014797          	auipc	a5,0x14
ffffffffc0202bca:	9d278793          	addi	a5,a5,-1582 # ffffffffc0216598 <max_swap_offset>
ffffffffc0202bce:	6394                	ld	a3,0(a5)
ffffffffc0202bd0:	010007b7          	lui	a5,0x1000
ffffffffc0202bd4:	17e1                	addi	a5,a5,-8
ffffffffc0202bd6:	ff968713          	addi	a4,a3,-7
ffffffffc0202bda:	4ae7e863          	bltu	a5,a4,ffffffffc020308a <swap_init+0x4e4>
        max_swap_offset < MAX_SWAP_OFFSET_LIMIT)) {
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
     }

     sm = &swap_manager_fifo;
ffffffffc0202bde:	00008797          	auipc	a5,0x8
ffffffffc0202be2:	42278793          	addi	a5,a5,1058 # ffffffffc020b000 <swap_manager_fifo>
     int r = sm->init();
ffffffffc0202be6:	6798                	ld	a4,8(a5)
     sm = &swap_manager_fifo;
ffffffffc0202be8:	00014697          	auipc	a3,0x14
ffffffffc0202bec:	8af6bc23          	sd	a5,-1864(a3) # ffffffffc02164a0 <sm>
     int r = sm->init();
ffffffffc0202bf0:	9702                	jalr	a4
ffffffffc0202bf2:	8aaa                	mv	s5,a0
     
     if (r == 0)
ffffffffc0202bf4:	c10d                	beqz	a0,ffffffffc0202c16 <swap_init+0x70>
          cprintf("SWAP: manager = %s\n", sm->name);
          check_swap();
     }

     return r;
}
ffffffffc0202bf6:	60ea                	ld	ra,152(sp)
ffffffffc0202bf8:	644a                	ld	s0,144(sp)
ffffffffc0202bfa:	8556                	mv	a0,s5
ffffffffc0202bfc:	64aa                	ld	s1,136(sp)
ffffffffc0202bfe:	690a                	ld	s2,128(sp)
ffffffffc0202c00:	79e6                	ld	s3,120(sp)
ffffffffc0202c02:	7a46                	ld	s4,112(sp)
ffffffffc0202c04:	7aa6                	ld	s5,104(sp)
ffffffffc0202c06:	7b06                	ld	s6,96(sp)
ffffffffc0202c08:	6be6                	ld	s7,88(sp)
ffffffffc0202c0a:	6c46                	ld	s8,80(sp)
ffffffffc0202c0c:	6ca6                	ld	s9,72(sp)
ffffffffc0202c0e:	6d06                	ld	s10,64(sp)
ffffffffc0202c10:	7de2                	ld	s11,56(sp)
ffffffffc0202c12:	610d                	addi	sp,sp,160
ffffffffc0202c14:	8082                	ret
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc0202c16:	00014797          	auipc	a5,0x14
ffffffffc0202c1a:	88a78793          	addi	a5,a5,-1910 # ffffffffc02164a0 <sm>
ffffffffc0202c1e:	639c                	ld	a5,0(a5)
ffffffffc0202c20:	00004517          	auipc	a0,0x4
ffffffffc0202c24:	8a050513          	addi	a0,a0,-1888 # ffffffffc02064c0 <commands+0x14c8>
ffffffffc0202c28:	00014417          	auipc	s0,0x14
ffffffffc0202c2c:	9b040413          	addi	s0,s0,-1616 # ffffffffc02165d8 <free_area>
ffffffffc0202c30:	638c                	ld	a1,0(a5)
          swap_init_ok = 1;
ffffffffc0202c32:	4785                	li	a5,1
ffffffffc0202c34:	00014717          	auipc	a4,0x14
ffffffffc0202c38:	86f72a23          	sw	a5,-1932(a4) # ffffffffc02164a8 <swap_init_ok>
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc0202c3c:	c94fd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
ffffffffc0202c40:	641c                	ld	a5,8(s0)
check_swap(void)
{
    //backup mem env
     int ret, count = 0, total = 0, i;
     list_entry_t *le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202c42:	36878863          	beq	a5,s0,ffffffffc0202fb2 <swap_init+0x40c>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0202c46:	ff07b703          	ld	a4,-16(a5)
ffffffffc0202c4a:	8305                	srli	a4,a4,0x1
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0202c4c:	8b05                	andi	a4,a4,1
ffffffffc0202c4e:	36070663          	beqz	a4,ffffffffc0202fba <swap_init+0x414>
     int ret, count = 0, total = 0, i;
ffffffffc0202c52:	4481                	li	s1,0
ffffffffc0202c54:	4901                	li	s2,0
ffffffffc0202c56:	a031                	j	ffffffffc0202c62 <swap_init+0xbc>
ffffffffc0202c58:	ff07b703          	ld	a4,-16(a5)
        assert(PageProperty(p));
ffffffffc0202c5c:	8b09                	andi	a4,a4,2
ffffffffc0202c5e:	34070e63          	beqz	a4,ffffffffc0202fba <swap_init+0x414>
        count ++, total += p->property;
ffffffffc0202c62:	ff87a703          	lw	a4,-8(a5)
ffffffffc0202c66:	679c                	ld	a5,8(a5)
ffffffffc0202c68:	2905                	addiw	s2,s2,1
ffffffffc0202c6a:	9cb9                	addw	s1,s1,a4
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202c6c:	fe8796e3          	bne	a5,s0,ffffffffc0202c58 <swap_init+0xb2>
ffffffffc0202c70:	89a6                	mv	s3,s1
     }
     assert(total == nr_free_pages());
ffffffffc0202c72:	802fe0ef          	jal	ra,ffffffffc0200c74 <nr_free_pages>
ffffffffc0202c76:	69351263          	bne	a0,s3,ffffffffc02032fa <swap_init+0x754>
     cprintf("BEGIN check_swap: count %d, total %d\n",count,total);
ffffffffc0202c7a:	8626                	mv	a2,s1
ffffffffc0202c7c:	85ca                	mv	a1,s2
ffffffffc0202c7e:	00004517          	auipc	a0,0x4
ffffffffc0202c82:	88a50513          	addi	a0,a0,-1910 # ffffffffc0206508 <commands+0x1510>
ffffffffc0202c86:	c4afd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
     
     //now we set the phy pages env     
     struct mm_struct *mm = mm_create();
ffffffffc0202c8a:	ac0ff0ef          	jal	ra,ffffffffc0201f4a <mm_create>
ffffffffc0202c8e:	8baa                	mv	s7,a0
     assert(mm != NULL);
ffffffffc0202c90:	60050563          	beqz	a0,ffffffffc020329a <swap_init+0x6f4>

     extern struct mm_struct *check_mm_struct;
     assert(check_mm_struct == NULL);
ffffffffc0202c94:	00014797          	auipc	a5,0x14
ffffffffc0202c98:	87478793          	addi	a5,a5,-1932 # ffffffffc0216508 <check_mm_struct>
ffffffffc0202c9c:	639c                	ld	a5,0(a5)
ffffffffc0202c9e:	60079e63          	bnez	a5,ffffffffc02032ba <swap_init+0x714>

     check_mm_struct = mm;

     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0202ca2:	00013797          	auipc	a5,0x13
ffffffffc0202ca6:	7de78793          	addi	a5,a5,2014 # ffffffffc0216480 <boot_pgdir>
ffffffffc0202caa:	0007bb03          	ld	s6,0(a5)
     check_mm_struct = mm;
ffffffffc0202cae:	00014797          	auipc	a5,0x14
ffffffffc0202cb2:	84a7bd23          	sd	a0,-1958(a5) # ffffffffc0216508 <check_mm_struct>
     assert(pgdir[0] == 0);
ffffffffc0202cb6:	000b3783          	ld	a5,0(s6)
     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0202cba:	01653c23          	sd	s6,24(a0)
     assert(pgdir[0] == 0);
ffffffffc0202cbe:	4e079263          	bnez	a5,ffffffffc02031a2 <swap_init+0x5fc>

     struct vma_struct *vma = vma_create(BEING_CHECK_VALID_VADDR, CHECK_VALID_VADDR, VM_WRITE | VM_READ);
ffffffffc0202cc2:	6599                	lui	a1,0x6
ffffffffc0202cc4:	460d                	li	a2,3
ffffffffc0202cc6:	6505                	lui	a0,0x1
ffffffffc0202cc8:	aceff0ef          	jal	ra,ffffffffc0201f96 <vma_create>
ffffffffc0202ccc:	85aa                	mv	a1,a0
     assert(vma != NULL);
ffffffffc0202cce:	4e050a63          	beqz	a0,ffffffffc02031c2 <swap_init+0x61c>

     insert_vma_struct(mm, vma);
ffffffffc0202cd2:	855e                	mv	a0,s7
ffffffffc0202cd4:	b2eff0ef          	jal	ra,ffffffffc0202002 <insert_vma_struct>

     //setup the temp Page Table vaddr 0~4MB
     cprintf("setup Page Table for vaddr 0X1000, so alloc a page\n");
ffffffffc0202cd8:	00004517          	auipc	a0,0x4
ffffffffc0202cdc:	87050513          	addi	a0,a0,-1936 # ffffffffc0206548 <commands+0x1550>
ffffffffc0202ce0:	bf0fd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
     pte_t *temp_ptep=NULL;
     temp_ptep = get_pte(mm->pgdir, BEING_CHECK_VALID_VADDR, 1);
ffffffffc0202ce4:	018bb503          	ld	a0,24(s7)
ffffffffc0202ce8:	4605                	li	a2,1
ffffffffc0202cea:	6585                	lui	a1,0x1
ffffffffc0202cec:	fc9fd0ef          	jal	ra,ffffffffc0200cb4 <get_pte>
     assert(temp_ptep!= NULL);
ffffffffc0202cf0:	4e050963          	beqz	a0,ffffffffc02031e2 <swap_init+0x63c>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc0202cf4:	00004517          	auipc	a0,0x4
ffffffffc0202cf8:	8a450513          	addi	a0,a0,-1884 # ffffffffc0206598 <commands+0x15a0>
ffffffffc0202cfc:	00014997          	auipc	s3,0x14
ffffffffc0202d00:	81498993          	addi	s3,s3,-2028 # ffffffffc0216510 <check_rp>
ffffffffc0202d04:	bccfd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
     
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202d08:	00014a17          	auipc	s4,0x14
ffffffffc0202d0c:	828a0a13          	addi	s4,s4,-2008 # ffffffffc0216530 <swap_in_seq_no>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc0202d10:	8c4e                	mv	s8,s3
          check_rp[i] = alloc_page();
ffffffffc0202d12:	4505                	li	a0,1
ffffffffc0202d14:	e93fd0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc0202d18:	00ac3023          	sd	a0,0(s8)
          assert(check_rp[i] != NULL );
ffffffffc0202d1c:	32050763          	beqz	a0,ffffffffc020304a <swap_init+0x4a4>
ffffffffc0202d20:	651c                	ld	a5,8(a0)
          assert(!PageProperty(check_rp[i]));
ffffffffc0202d22:	8b89                	andi	a5,a5,2
ffffffffc0202d24:	30079363          	bnez	a5,ffffffffc020302a <swap_init+0x484>
ffffffffc0202d28:	0c21                	addi	s8,s8,8
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202d2a:	ff4c14e3          	bne	s8,s4,ffffffffc0202d12 <swap_init+0x16c>
     }
     list_entry_t free_list_store = free_list;
ffffffffc0202d2e:	601c                	ld	a5,0(s0)
     assert(list_empty(&free_list));
     
     //assert(alloc_page() == NULL);
     
     unsigned int nr_free_store = nr_free;
     nr_free = 0;
ffffffffc0202d30:	00013c17          	auipc	s8,0x13
ffffffffc0202d34:	7e0c0c13          	addi	s8,s8,2016 # ffffffffc0216510 <check_rp>
     list_entry_t free_list_store = free_list;
ffffffffc0202d38:	ec3e                	sd	a5,24(sp)
ffffffffc0202d3a:	641c                	ld	a5,8(s0)
ffffffffc0202d3c:	f03e                	sd	a5,32(sp)
     unsigned int nr_free_store = nr_free;
ffffffffc0202d3e:	481c                	lw	a5,16(s0)
ffffffffc0202d40:	f43e                	sd	a5,40(sp)
    elm->prev = elm->next = elm;
ffffffffc0202d42:	00014797          	auipc	a5,0x14
ffffffffc0202d46:	8887bf23          	sd	s0,-1890(a5) # ffffffffc02165e0 <free_area+0x8>
ffffffffc0202d4a:	00014797          	auipc	a5,0x14
ffffffffc0202d4e:	8887b723          	sd	s0,-1906(a5) # ffffffffc02165d8 <free_area>
     nr_free = 0;
ffffffffc0202d52:	00014797          	auipc	a5,0x14
ffffffffc0202d56:	8807ab23          	sw	zero,-1898(a5) # ffffffffc02165e8 <free_area+0x10>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
        free_pages(check_rp[i],1);
ffffffffc0202d5a:	000c3503          	ld	a0,0(s8)
ffffffffc0202d5e:	4585                	li	a1,1
ffffffffc0202d60:	0c21                	addi	s8,s8,8
ffffffffc0202d62:	ecdfd0ef          	jal	ra,ffffffffc0200c2e <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202d66:	ff4c1ae3          	bne	s8,s4,ffffffffc0202d5a <swap_init+0x1b4>
     }
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc0202d6a:	01042c03          	lw	s8,16(s0)
ffffffffc0202d6e:	4791                	li	a5,4
ffffffffc0202d70:	50fc1563          	bne	s8,a5,ffffffffc020327a <swap_init+0x6d4>
     
     cprintf("set up init env for check_swap begin!\n");
ffffffffc0202d74:	00004517          	auipc	a0,0x4
ffffffffc0202d78:	8ac50513          	addi	a0,a0,-1876 # ffffffffc0206620 <commands+0x1628>
ffffffffc0202d7c:	b54fd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0202d80:	6685                	lui	a3,0x1
     //setup initial vir_page<->phy_page environment for page relpacement algorithm 

     
     pgfault_num=0;
ffffffffc0202d82:	00013797          	auipc	a5,0x13
ffffffffc0202d86:	7007a723          	sw	zero,1806(a5) # ffffffffc0216490 <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0202d8a:	4629                	li	a2,10
     pgfault_num=0;
ffffffffc0202d8c:	00013797          	auipc	a5,0x13
ffffffffc0202d90:	70478793          	addi	a5,a5,1796 # ffffffffc0216490 <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0202d94:	00c68023          	sb	a2,0(a3) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
     assert(pgfault_num==1);
ffffffffc0202d98:	4398                	lw	a4,0(a5)
ffffffffc0202d9a:	4585                	li	a1,1
ffffffffc0202d9c:	2701                	sext.w	a4,a4
ffffffffc0202d9e:	38b71263          	bne	a4,a1,ffffffffc0203122 <swap_init+0x57c>
     *(unsigned char *)0x1010 = 0x0a;
ffffffffc0202da2:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==1);
ffffffffc0202da6:	4394                	lw	a3,0(a5)
ffffffffc0202da8:	2681                	sext.w	a3,a3
ffffffffc0202daa:	38e69c63          	bne	a3,a4,ffffffffc0203142 <swap_init+0x59c>
     *(unsigned char *)0x2000 = 0x0b;
ffffffffc0202dae:	6689                	lui	a3,0x2
ffffffffc0202db0:	462d                	li	a2,11
ffffffffc0202db2:	00c68023          	sb	a2,0(a3) # 2000 <BASE_ADDRESS-0xffffffffc01fe000>
     assert(pgfault_num==2);
ffffffffc0202db6:	4398                	lw	a4,0(a5)
ffffffffc0202db8:	4589                	li	a1,2
ffffffffc0202dba:	2701                	sext.w	a4,a4
ffffffffc0202dbc:	2eb71363          	bne	a4,a1,ffffffffc02030a2 <swap_init+0x4fc>
     *(unsigned char *)0x2010 = 0x0b;
ffffffffc0202dc0:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==2);
ffffffffc0202dc4:	4394                	lw	a3,0(a5)
ffffffffc0202dc6:	2681                	sext.w	a3,a3
ffffffffc0202dc8:	2ee69d63          	bne	a3,a4,ffffffffc02030c2 <swap_init+0x51c>
     *(unsigned char *)0x3000 = 0x0c;
ffffffffc0202dcc:	668d                	lui	a3,0x3
ffffffffc0202dce:	4631                	li	a2,12
ffffffffc0202dd0:	00c68023          	sb	a2,0(a3) # 3000 <BASE_ADDRESS-0xffffffffc01fd000>
     assert(pgfault_num==3);
ffffffffc0202dd4:	4398                	lw	a4,0(a5)
ffffffffc0202dd6:	458d                	li	a1,3
ffffffffc0202dd8:	2701                	sext.w	a4,a4
ffffffffc0202dda:	30b71463          	bne	a4,a1,ffffffffc02030e2 <swap_init+0x53c>
     *(unsigned char *)0x3010 = 0x0c;
ffffffffc0202dde:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==3);
ffffffffc0202de2:	4394                	lw	a3,0(a5)
ffffffffc0202de4:	2681                	sext.w	a3,a3
ffffffffc0202de6:	30e69e63          	bne	a3,a4,ffffffffc0203102 <swap_init+0x55c>
     *(unsigned char *)0x4000 = 0x0d;
ffffffffc0202dea:	6691                	lui	a3,0x4
ffffffffc0202dec:	4635                	li	a2,13
ffffffffc0202dee:	00c68023          	sb	a2,0(a3) # 4000 <BASE_ADDRESS-0xffffffffc01fc000>
     assert(pgfault_num==4);
ffffffffc0202df2:	4398                	lw	a4,0(a5)
ffffffffc0202df4:	2701                	sext.w	a4,a4
ffffffffc0202df6:	37871663          	bne	a4,s8,ffffffffc0203162 <swap_init+0x5bc>
     *(unsigned char *)0x4010 = 0x0d;
ffffffffc0202dfa:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==4);
ffffffffc0202dfe:	439c                	lw	a5,0(a5)
ffffffffc0202e00:	2781                	sext.w	a5,a5
ffffffffc0202e02:	38e79063          	bne	a5,a4,ffffffffc0203182 <swap_init+0x5dc>
     
     check_content_set();
     assert( nr_free == 0);         
ffffffffc0202e06:	481c                	lw	a5,16(s0)
ffffffffc0202e08:	3e079d63          	bnez	a5,ffffffffc0203202 <swap_init+0x65c>
ffffffffc0202e0c:	00013797          	auipc	a5,0x13
ffffffffc0202e10:	72478793          	addi	a5,a5,1828 # ffffffffc0216530 <swap_in_seq_no>
ffffffffc0202e14:	00013717          	auipc	a4,0x13
ffffffffc0202e18:	74470713          	addi	a4,a4,1860 # ffffffffc0216558 <swap_out_seq_no>
ffffffffc0202e1c:	00013617          	auipc	a2,0x13
ffffffffc0202e20:	73c60613          	addi	a2,a2,1852 # ffffffffc0216558 <swap_out_seq_no>
     for(i = 0; i<MAX_SEQ_NO ; i++) 
         swap_out_seq_no[i]=swap_in_seq_no[i]=-1;
ffffffffc0202e24:	56fd                	li	a3,-1
ffffffffc0202e26:	c394                	sw	a3,0(a5)
ffffffffc0202e28:	c314                	sw	a3,0(a4)
ffffffffc0202e2a:	0791                	addi	a5,a5,4
ffffffffc0202e2c:	0711                	addi	a4,a4,4
     for(i = 0; i<MAX_SEQ_NO ; i++) 
ffffffffc0202e2e:	fef61ce3          	bne	a2,a5,ffffffffc0202e26 <swap_init+0x280>
ffffffffc0202e32:	00013697          	auipc	a3,0x13
ffffffffc0202e36:	78668693          	addi	a3,a3,1926 # ffffffffc02165b8 <check_ptep>
ffffffffc0202e3a:	00013817          	auipc	a6,0x13
ffffffffc0202e3e:	6d680813          	addi	a6,a6,1750 # ffffffffc0216510 <check_rp>
ffffffffc0202e42:	6d05                	lui	s10,0x1
    if (PPN(pa) >= npage) {
ffffffffc0202e44:	00013c97          	auipc	s9,0x13
ffffffffc0202e48:	644c8c93          	addi	s9,s9,1604 # ffffffffc0216488 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0202e4c:	00004d97          	auipc	s11,0x4
ffffffffc0202e50:	1d4d8d93          	addi	s11,s11,468 # ffffffffc0207020 <nbase>
ffffffffc0202e54:	00013c17          	auipc	s8,0x13
ffffffffc0202e58:	69cc0c13          	addi	s8,s8,1692 # ffffffffc02164f0 <pages>
     
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         check_ptep[i]=0;
ffffffffc0202e5c:	0006b023          	sd	zero,0(a3)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0202e60:	4601                	li	a2,0
ffffffffc0202e62:	85ea                	mv	a1,s10
ffffffffc0202e64:	855a                	mv	a0,s6
ffffffffc0202e66:	e842                	sd	a6,16(sp)
         check_ptep[i]=0;
ffffffffc0202e68:	e436                	sd	a3,8(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0202e6a:	e4bfd0ef          	jal	ra,ffffffffc0200cb4 <get_pte>
ffffffffc0202e6e:	66a2                	ld	a3,8(sp)
         //cprintf("i %d, check_ptep addr %x, value %x\n", i, check_ptep[i], *check_ptep[i]);
         assert(check_ptep[i] != NULL);
ffffffffc0202e70:	6842                	ld	a6,16(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0202e72:	e288                	sd	a0,0(a3)
         assert(check_ptep[i] != NULL);
ffffffffc0202e74:	1e050b63          	beqz	a0,ffffffffc020306a <swap_init+0x4c4>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0202e78:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0202e7a:	0017f613          	andi	a2,a5,1
ffffffffc0202e7e:	18060a63          	beqz	a2,ffffffffc0203012 <swap_init+0x46c>
    if (PPN(pa) >= npage) {
ffffffffc0202e82:	000cb603          	ld	a2,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202e86:	078a                	slli	a5,a5,0x2
ffffffffc0202e88:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202e8a:	14c7f863          	bgeu	a5,a2,ffffffffc0202fda <swap_init+0x434>
    return &pages[PPN(pa) - nbase];
ffffffffc0202e8e:	000db703          	ld	a4,0(s11)
ffffffffc0202e92:	000c3603          	ld	a2,0(s8)
ffffffffc0202e96:	00083583          	ld	a1,0(a6)
ffffffffc0202e9a:	8f99                	sub	a5,a5,a4
ffffffffc0202e9c:	079a                	slli	a5,a5,0x6
ffffffffc0202e9e:	e43a                	sd	a4,8(sp)
ffffffffc0202ea0:	97b2                	add	a5,a5,a2
ffffffffc0202ea2:	14f59863          	bne	a1,a5,ffffffffc0202ff2 <swap_init+0x44c>
ffffffffc0202ea6:	6785                	lui	a5,0x1
ffffffffc0202ea8:	9d3e                	add	s10,s10,a5
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202eaa:	6795                	lui	a5,0x5
ffffffffc0202eac:	06a1                	addi	a3,a3,8
ffffffffc0202eae:	0821                	addi	a6,a6,8
ffffffffc0202eb0:	fafd16e3          	bne	s10,a5,ffffffffc0202e5c <swap_init+0x2b6>
         assert((*check_ptep[i] & PTE_V));          
     }
     cprintf("set up init env for check_swap over!\n");
ffffffffc0202eb4:	00004517          	auipc	a0,0x4
ffffffffc0202eb8:	82450513          	addi	a0,a0,-2012 # ffffffffc02066d8 <commands+0x16e0>
ffffffffc0202ebc:	a14fd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    int ret = sm->check_swap();
ffffffffc0202ec0:	00013797          	auipc	a5,0x13
ffffffffc0202ec4:	5e078793          	addi	a5,a5,1504 # ffffffffc02164a0 <sm>
ffffffffc0202ec8:	639c                	ld	a5,0(a5)
ffffffffc0202eca:	7f9c                	ld	a5,56(a5)
ffffffffc0202ecc:	9782                	jalr	a5
     // now access the virt pages to test  page relpacement algorithm 
     ret=check_content_access();
     assert(ret==0);
ffffffffc0202ece:	40051663          	bnez	a0,ffffffffc02032da <swap_init+0x734>

     nr_free = nr_free_store;
ffffffffc0202ed2:	77a2                	ld	a5,40(sp)
ffffffffc0202ed4:	00013717          	auipc	a4,0x13
ffffffffc0202ed8:	70f72a23          	sw	a5,1812(a4) # ffffffffc02165e8 <free_area+0x10>
     free_list = free_list_store;
ffffffffc0202edc:	67e2                	ld	a5,24(sp)
ffffffffc0202ede:	00013717          	auipc	a4,0x13
ffffffffc0202ee2:	6ef73d23          	sd	a5,1786(a4) # ffffffffc02165d8 <free_area>
ffffffffc0202ee6:	7782                	ld	a5,32(sp)
ffffffffc0202ee8:	00013717          	auipc	a4,0x13
ffffffffc0202eec:	6ef73c23          	sd	a5,1784(a4) # ffffffffc02165e0 <free_area+0x8>

     //restore kernel mem env
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         free_pages(check_rp[i],1);
ffffffffc0202ef0:	0009b503          	ld	a0,0(s3)
ffffffffc0202ef4:	4585                	li	a1,1
ffffffffc0202ef6:	09a1                	addi	s3,s3,8
ffffffffc0202ef8:	d37fd0ef          	jal	ra,ffffffffc0200c2e <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202efc:	ff499ae3          	bne	s3,s4,ffffffffc0202ef0 <swap_init+0x34a>
     } 

     //free_page(pte2page(*temp_ptep));
     
     mm_destroy(mm);
ffffffffc0202f00:	855e                	mv	a0,s7
ffffffffc0202f02:	9ceff0ef          	jal	ra,ffffffffc02020d0 <mm_destroy>

     pde_t *pd1=pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc0202f06:	00013797          	auipc	a5,0x13
ffffffffc0202f0a:	57a78793          	addi	a5,a5,1402 # ffffffffc0216480 <boot_pgdir>
ffffffffc0202f0e:	639c                	ld	a5,0(a5)
    if (PPN(pa) >= npage) {
ffffffffc0202f10:	000cb703          	ld	a4,0(s9)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202f14:	6394                	ld	a3,0(a5)
ffffffffc0202f16:	068a                	slli	a3,a3,0x2
ffffffffc0202f18:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202f1a:	0ce6f063          	bgeu	a3,a4,ffffffffc0202fda <swap_init+0x434>
    return &pages[PPN(pa) - nbase];
ffffffffc0202f1e:	67a2                	ld	a5,8(sp)
ffffffffc0202f20:	000c3503          	ld	a0,0(s8)
ffffffffc0202f24:	8e9d                	sub	a3,a3,a5
ffffffffc0202f26:	069a                	slli	a3,a3,0x6
    return page - pages + nbase;
ffffffffc0202f28:	8699                	srai	a3,a3,0x6
ffffffffc0202f2a:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0202f2c:	00c69793          	slli	a5,a3,0xc
ffffffffc0202f30:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202f32:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202f34:	2ee7f763          	bgeu	a5,a4,ffffffffc0203222 <swap_init+0x67c>
     free_page(pde2page(pd0[0]));
ffffffffc0202f38:	00013797          	auipc	a5,0x13
ffffffffc0202f3c:	5a878793          	addi	a5,a5,1448 # ffffffffc02164e0 <va_pa_offset>
ffffffffc0202f40:	639c                	ld	a5,0(a5)
ffffffffc0202f42:	96be                	add	a3,a3,a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202f44:	629c                	ld	a5,0(a3)
ffffffffc0202f46:	078a                	slli	a5,a5,0x2
ffffffffc0202f48:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202f4a:	08e7f863          	bgeu	a5,a4,ffffffffc0202fda <swap_init+0x434>
    return &pages[PPN(pa) - nbase];
ffffffffc0202f4e:	69a2                	ld	s3,8(sp)
ffffffffc0202f50:	4585                	li	a1,1
ffffffffc0202f52:	413787b3          	sub	a5,a5,s3
ffffffffc0202f56:	079a                	slli	a5,a5,0x6
ffffffffc0202f58:	953e                	add	a0,a0,a5
ffffffffc0202f5a:	cd5fd0ef          	jal	ra,ffffffffc0200c2e <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0202f5e:	000b3783          	ld	a5,0(s6)
    if (PPN(pa) >= npage) {
ffffffffc0202f62:	000cb703          	ld	a4,0(s9)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202f66:	078a                	slli	a5,a5,0x2
ffffffffc0202f68:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202f6a:	06e7f863          	bgeu	a5,a4,ffffffffc0202fda <swap_init+0x434>
    return &pages[PPN(pa) - nbase];
ffffffffc0202f6e:	000c3503          	ld	a0,0(s8)
ffffffffc0202f72:	413787b3          	sub	a5,a5,s3
ffffffffc0202f76:	079a                	slli	a5,a5,0x6
     free_page(pde2page(pd1[0]));
ffffffffc0202f78:	4585                	li	a1,1
ffffffffc0202f7a:	953e                	add	a0,a0,a5
ffffffffc0202f7c:	cb3fd0ef          	jal	ra,ffffffffc0200c2e <free_pages>
     pgdir[0] = 0;
ffffffffc0202f80:	000b3023          	sd	zero,0(s6)
  asm volatile("sfence.vma");
ffffffffc0202f84:	12000073          	sfence.vma
    return listelm->next;
ffffffffc0202f88:	641c                	ld	a5,8(s0)
     flush_tlb();

     le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202f8a:	00878963          	beq	a5,s0,ffffffffc0202f9c <swap_init+0x3f6>
         struct Page *p = le2page(le, page_link);
         count --, total -= p->property;
ffffffffc0202f8e:	ff87a703          	lw	a4,-8(a5)
ffffffffc0202f92:	679c                	ld	a5,8(a5)
ffffffffc0202f94:	397d                	addiw	s2,s2,-1
ffffffffc0202f96:	9c99                	subw	s1,s1,a4
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202f98:	fe879be3          	bne	a5,s0,ffffffffc0202f8e <swap_init+0x3e8>
     }
     assert(count==0);
ffffffffc0202f9c:	28091f63          	bnez	s2,ffffffffc020323a <swap_init+0x694>
     assert(total==0);
ffffffffc0202fa0:	2a049d63          	bnez	s1,ffffffffc020325a <swap_init+0x6b4>

     cprintf("check_swap() succeeded!\n");
ffffffffc0202fa4:	00003517          	auipc	a0,0x3
ffffffffc0202fa8:	78450513          	addi	a0,a0,1924 # ffffffffc0206728 <commands+0x1730>
ffffffffc0202fac:	924fd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
ffffffffc0202fb0:	b199                	j	ffffffffc0202bf6 <swap_init+0x50>
     int ret, count = 0, total = 0, i;
ffffffffc0202fb2:	4481                	li	s1,0
ffffffffc0202fb4:	4901                	li	s2,0
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202fb6:	4981                	li	s3,0
ffffffffc0202fb8:	b96d                	j	ffffffffc0202c72 <swap_init+0xcc>
        assert(PageProperty(p));
ffffffffc0202fba:	00003697          	auipc	a3,0x3
ffffffffc0202fbe:	51e68693          	addi	a3,a3,1310 # ffffffffc02064d8 <commands+0x14e0>
ffffffffc0202fc2:	00003617          	auipc	a2,0x3
ffffffffc0202fc6:	9ce60613          	addi	a2,a2,-1586 # ffffffffc0205990 <commands+0x998>
ffffffffc0202fca:	0bd00593          	li	a1,189
ffffffffc0202fce:	00003517          	auipc	a0,0x3
ffffffffc0202fd2:	4e250513          	addi	a0,a0,1250 # ffffffffc02064b0 <commands+0x14b8>
ffffffffc0202fd6:	9fefd0ef          	jal	ra,ffffffffc02001d4 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0202fda:	00003617          	auipc	a2,0x3
ffffffffc0202fde:	89660613          	addi	a2,a2,-1898 # ffffffffc0205870 <commands+0x878>
ffffffffc0202fe2:	06200593          	li	a1,98
ffffffffc0202fe6:	00003517          	auipc	a0,0x3
ffffffffc0202fea:	8aa50513          	addi	a0,a0,-1878 # ffffffffc0205890 <commands+0x898>
ffffffffc0202fee:	9e6fd0ef          	jal	ra,ffffffffc02001d4 <__panic>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0202ff2:	00003697          	auipc	a3,0x3
ffffffffc0202ff6:	6be68693          	addi	a3,a3,1726 # ffffffffc02066b0 <commands+0x16b8>
ffffffffc0202ffa:	00003617          	auipc	a2,0x3
ffffffffc0202ffe:	99660613          	addi	a2,a2,-1642 # ffffffffc0205990 <commands+0x998>
ffffffffc0203002:	0fd00593          	li	a1,253
ffffffffc0203006:	00003517          	auipc	a0,0x3
ffffffffc020300a:	4aa50513          	addi	a0,a0,1194 # ffffffffc02064b0 <commands+0x14b8>
ffffffffc020300e:	9c6fd0ef          	jal	ra,ffffffffc02001d4 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0203012:	00003617          	auipc	a2,0x3
ffffffffc0203016:	a5660613          	addi	a2,a2,-1450 # ffffffffc0205a68 <commands+0xa70>
ffffffffc020301a:	07400593          	li	a1,116
ffffffffc020301e:	00003517          	auipc	a0,0x3
ffffffffc0203022:	87250513          	addi	a0,a0,-1934 # ffffffffc0205890 <commands+0x898>
ffffffffc0203026:	9aefd0ef          	jal	ra,ffffffffc02001d4 <__panic>
          assert(!PageProperty(check_rp[i]));
ffffffffc020302a:	00003697          	auipc	a3,0x3
ffffffffc020302e:	5ae68693          	addi	a3,a3,1454 # ffffffffc02065d8 <commands+0x15e0>
ffffffffc0203032:	00003617          	auipc	a2,0x3
ffffffffc0203036:	95e60613          	addi	a2,a2,-1698 # ffffffffc0205990 <commands+0x998>
ffffffffc020303a:	0de00593          	li	a1,222
ffffffffc020303e:	00003517          	auipc	a0,0x3
ffffffffc0203042:	47250513          	addi	a0,a0,1138 # ffffffffc02064b0 <commands+0x14b8>
ffffffffc0203046:	98efd0ef          	jal	ra,ffffffffc02001d4 <__panic>
          assert(check_rp[i] != NULL );
ffffffffc020304a:	00003697          	auipc	a3,0x3
ffffffffc020304e:	57668693          	addi	a3,a3,1398 # ffffffffc02065c0 <commands+0x15c8>
ffffffffc0203052:	00003617          	auipc	a2,0x3
ffffffffc0203056:	93e60613          	addi	a2,a2,-1730 # ffffffffc0205990 <commands+0x998>
ffffffffc020305a:	0dd00593          	li	a1,221
ffffffffc020305e:	00003517          	auipc	a0,0x3
ffffffffc0203062:	45250513          	addi	a0,a0,1106 # ffffffffc02064b0 <commands+0x14b8>
ffffffffc0203066:	96efd0ef          	jal	ra,ffffffffc02001d4 <__panic>
         assert(check_ptep[i] != NULL);
ffffffffc020306a:	00003697          	auipc	a3,0x3
ffffffffc020306e:	62e68693          	addi	a3,a3,1582 # ffffffffc0206698 <commands+0x16a0>
ffffffffc0203072:	00003617          	auipc	a2,0x3
ffffffffc0203076:	91e60613          	addi	a2,a2,-1762 # ffffffffc0205990 <commands+0x998>
ffffffffc020307a:	0fc00593          	li	a1,252
ffffffffc020307e:	00003517          	auipc	a0,0x3
ffffffffc0203082:	43250513          	addi	a0,a0,1074 # ffffffffc02064b0 <commands+0x14b8>
ffffffffc0203086:	94efd0ef          	jal	ra,ffffffffc02001d4 <__panic>
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
ffffffffc020308a:	00003617          	auipc	a2,0x3
ffffffffc020308e:	40660613          	addi	a2,a2,1030 # ffffffffc0206490 <commands+0x1498>
ffffffffc0203092:	02a00593          	li	a1,42
ffffffffc0203096:	00003517          	auipc	a0,0x3
ffffffffc020309a:	41a50513          	addi	a0,a0,1050 # ffffffffc02064b0 <commands+0x14b8>
ffffffffc020309e:	936fd0ef          	jal	ra,ffffffffc02001d4 <__panic>
     assert(pgfault_num==2);
ffffffffc02030a2:	00003697          	auipc	a3,0x3
ffffffffc02030a6:	5b668693          	addi	a3,a3,1462 # ffffffffc0206658 <commands+0x1660>
ffffffffc02030aa:	00003617          	auipc	a2,0x3
ffffffffc02030ae:	8e660613          	addi	a2,a2,-1818 # ffffffffc0205990 <commands+0x998>
ffffffffc02030b2:	09800593          	li	a1,152
ffffffffc02030b6:	00003517          	auipc	a0,0x3
ffffffffc02030ba:	3fa50513          	addi	a0,a0,1018 # ffffffffc02064b0 <commands+0x14b8>
ffffffffc02030be:	916fd0ef          	jal	ra,ffffffffc02001d4 <__panic>
     assert(pgfault_num==2);
ffffffffc02030c2:	00003697          	auipc	a3,0x3
ffffffffc02030c6:	59668693          	addi	a3,a3,1430 # ffffffffc0206658 <commands+0x1660>
ffffffffc02030ca:	00003617          	auipc	a2,0x3
ffffffffc02030ce:	8c660613          	addi	a2,a2,-1850 # ffffffffc0205990 <commands+0x998>
ffffffffc02030d2:	09a00593          	li	a1,154
ffffffffc02030d6:	00003517          	auipc	a0,0x3
ffffffffc02030da:	3da50513          	addi	a0,a0,986 # ffffffffc02064b0 <commands+0x14b8>
ffffffffc02030de:	8f6fd0ef          	jal	ra,ffffffffc02001d4 <__panic>
     assert(pgfault_num==3);
ffffffffc02030e2:	00003697          	auipc	a3,0x3
ffffffffc02030e6:	58668693          	addi	a3,a3,1414 # ffffffffc0206668 <commands+0x1670>
ffffffffc02030ea:	00003617          	auipc	a2,0x3
ffffffffc02030ee:	8a660613          	addi	a2,a2,-1882 # ffffffffc0205990 <commands+0x998>
ffffffffc02030f2:	09c00593          	li	a1,156
ffffffffc02030f6:	00003517          	auipc	a0,0x3
ffffffffc02030fa:	3ba50513          	addi	a0,a0,954 # ffffffffc02064b0 <commands+0x14b8>
ffffffffc02030fe:	8d6fd0ef          	jal	ra,ffffffffc02001d4 <__panic>
     assert(pgfault_num==3);
ffffffffc0203102:	00003697          	auipc	a3,0x3
ffffffffc0203106:	56668693          	addi	a3,a3,1382 # ffffffffc0206668 <commands+0x1670>
ffffffffc020310a:	00003617          	auipc	a2,0x3
ffffffffc020310e:	88660613          	addi	a2,a2,-1914 # ffffffffc0205990 <commands+0x998>
ffffffffc0203112:	09e00593          	li	a1,158
ffffffffc0203116:	00003517          	auipc	a0,0x3
ffffffffc020311a:	39a50513          	addi	a0,a0,922 # ffffffffc02064b0 <commands+0x14b8>
ffffffffc020311e:	8b6fd0ef          	jal	ra,ffffffffc02001d4 <__panic>
     assert(pgfault_num==1);
ffffffffc0203122:	00003697          	auipc	a3,0x3
ffffffffc0203126:	52668693          	addi	a3,a3,1318 # ffffffffc0206648 <commands+0x1650>
ffffffffc020312a:	00003617          	auipc	a2,0x3
ffffffffc020312e:	86660613          	addi	a2,a2,-1946 # ffffffffc0205990 <commands+0x998>
ffffffffc0203132:	09400593          	li	a1,148
ffffffffc0203136:	00003517          	auipc	a0,0x3
ffffffffc020313a:	37a50513          	addi	a0,a0,890 # ffffffffc02064b0 <commands+0x14b8>
ffffffffc020313e:	896fd0ef          	jal	ra,ffffffffc02001d4 <__panic>
     assert(pgfault_num==1);
ffffffffc0203142:	00003697          	auipc	a3,0x3
ffffffffc0203146:	50668693          	addi	a3,a3,1286 # ffffffffc0206648 <commands+0x1650>
ffffffffc020314a:	00003617          	auipc	a2,0x3
ffffffffc020314e:	84660613          	addi	a2,a2,-1978 # ffffffffc0205990 <commands+0x998>
ffffffffc0203152:	09600593          	li	a1,150
ffffffffc0203156:	00003517          	auipc	a0,0x3
ffffffffc020315a:	35a50513          	addi	a0,a0,858 # ffffffffc02064b0 <commands+0x14b8>
ffffffffc020315e:	876fd0ef          	jal	ra,ffffffffc02001d4 <__panic>
     assert(pgfault_num==4);
ffffffffc0203162:	00003697          	auipc	a3,0x3
ffffffffc0203166:	51668693          	addi	a3,a3,1302 # ffffffffc0206678 <commands+0x1680>
ffffffffc020316a:	00003617          	auipc	a2,0x3
ffffffffc020316e:	82660613          	addi	a2,a2,-2010 # ffffffffc0205990 <commands+0x998>
ffffffffc0203172:	0a000593          	li	a1,160
ffffffffc0203176:	00003517          	auipc	a0,0x3
ffffffffc020317a:	33a50513          	addi	a0,a0,826 # ffffffffc02064b0 <commands+0x14b8>
ffffffffc020317e:	856fd0ef          	jal	ra,ffffffffc02001d4 <__panic>
     assert(pgfault_num==4);
ffffffffc0203182:	00003697          	auipc	a3,0x3
ffffffffc0203186:	4f668693          	addi	a3,a3,1270 # ffffffffc0206678 <commands+0x1680>
ffffffffc020318a:	00003617          	auipc	a2,0x3
ffffffffc020318e:	80660613          	addi	a2,a2,-2042 # ffffffffc0205990 <commands+0x998>
ffffffffc0203192:	0a200593          	li	a1,162
ffffffffc0203196:	00003517          	auipc	a0,0x3
ffffffffc020319a:	31a50513          	addi	a0,a0,794 # ffffffffc02064b0 <commands+0x14b8>
ffffffffc020319e:	836fd0ef          	jal	ra,ffffffffc02001d4 <__panic>
     assert(pgdir[0] == 0);
ffffffffc02031a2:	00003697          	auipc	a3,0x3
ffffffffc02031a6:	17e68693          	addi	a3,a3,382 # ffffffffc0206320 <commands+0x1328>
ffffffffc02031aa:	00002617          	auipc	a2,0x2
ffffffffc02031ae:	7e660613          	addi	a2,a2,2022 # ffffffffc0205990 <commands+0x998>
ffffffffc02031b2:	0cd00593          	li	a1,205
ffffffffc02031b6:	00003517          	auipc	a0,0x3
ffffffffc02031ba:	2fa50513          	addi	a0,a0,762 # ffffffffc02064b0 <commands+0x14b8>
ffffffffc02031be:	816fd0ef          	jal	ra,ffffffffc02001d4 <__panic>
     assert(vma != NULL);
ffffffffc02031c2:	00003697          	auipc	a3,0x3
ffffffffc02031c6:	1fe68693          	addi	a3,a3,510 # ffffffffc02063c0 <commands+0x13c8>
ffffffffc02031ca:	00002617          	auipc	a2,0x2
ffffffffc02031ce:	7c660613          	addi	a2,a2,1990 # ffffffffc0205990 <commands+0x998>
ffffffffc02031d2:	0d000593          	li	a1,208
ffffffffc02031d6:	00003517          	auipc	a0,0x3
ffffffffc02031da:	2da50513          	addi	a0,a0,730 # ffffffffc02064b0 <commands+0x14b8>
ffffffffc02031de:	ff7fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
     assert(temp_ptep!= NULL);
ffffffffc02031e2:	00003697          	auipc	a3,0x3
ffffffffc02031e6:	39e68693          	addi	a3,a3,926 # ffffffffc0206580 <commands+0x1588>
ffffffffc02031ea:	00002617          	auipc	a2,0x2
ffffffffc02031ee:	7a660613          	addi	a2,a2,1958 # ffffffffc0205990 <commands+0x998>
ffffffffc02031f2:	0d800593          	li	a1,216
ffffffffc02031f6:	00003517          	auipc	a0,0x3
ffffffffc02031fa:	2ba50513          	addi	a0,a0,698 # ffffffffc02064b0 <commands+0x14b8>
ffffffffc02031fe:	fd7fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
     assert( nr_free == 0);         
ffffffffc0203202:	00003697          	auipc	a3,0x3
ffffffffc0203206:	48668693          	addi	a3,a3,1158 # ffffffffc0206688 <commands+0x1690>
ffffffffc020320a:	00002617          	auipc	a2,0x2
ffffffffc020320e:	78660613          	addi	a2,a2,1926 # ffffffffc0205990 <commands+0x998>
ffffffffc0203212:	0f400593          	li	a1,244
ffffffffc0203216:	00003517          	auipc	a0,0x3
ffffffffc020321a:	29a50513          	addi	a0,a0,666 # ffffffffc02064b0 <commands+0x14b8>
ffffffffc020321e:	fb7fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
    return KADDR(page2pa(page));
ffffffffc0203222:	00002617          	auipc	a2,0x2
ffffffffc0203226:	61660613          	addi	a2,a2,1558 # ffffffffc0205838 <commands+0x840>
ffffffffc020322a:	06900593          	li	a1,105
ffffffffc020322e:	00002517          	auipc	a0,0x2
ffffffffc0203232:	66250513          	addi	a0,a0,1634 # ffffffffc0205890 <commands+0x898>
ffffffffc0203236:	f9ffc0ef          	jal	ra,ffffffffc02001d4 <__panic>
     assert(count==0);
ffffffffc020323a:	00003697          	auipc	a3,0x3
ffffffffc020323e:	4ce68693          	addi	a3,a3,1230 # ffffffffc0206708 <commands+0x1710>
ffffffffc0203242:	00002617          	auipc	a2,0x2
ffffffffc0203246:	74e60613          	addi	a2,a2,1870 # ffffffffc0205990 <commands+0x998>
ffffffffc020324a:	11c00593          	li	a1,284
ffffffffc020324e:	00003517          	auipc	a0,0x3
ffffffffc0203252:	26250513          	addi	a0,a0,610 # ffffffffc02064b0 <commands+0x14b8>
ffffffffc0203256:	f7ffc0ef          	jal	ra,ffffffffc02001d4 <__panic>
     assert(total==0);
ffffffffc020325a:	00003697          	auipc	a3,0x3
ffffffffc020325e:	4be68693          	addi	a3,a3,1214 # ffffffffc0206718 <commands+0x1720>
ffffffffc0203262:	00002617          	auipc	a2,0x2
ffffffffc0203266:	72e60613          	addi	a2,a2,1838 # ffffffffc0205990 <commands+0x998>
ffffffffc020326a:	11d00593          	li	a1,285
ffffffffc020326e:	00003517          	auipc	a0,0x3
ffffffffc0203272:	24250513          	addi	a0,a0,578 # ffffffffc02064b0 <commands+0x14b8>
ffffffffc0203276:	f5ffc0ef          	jal	ra,ffffffffc02001d4 <__panic>
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc020327a:	00003697          	auipc	a3,0x3
ffffffffc020327e:	37e68693          	addi	a3,a3,894 # ffffffffc02065f8 <commands+0x1600>
ffffffffc0203282:	00002617          	auipc	a2,0x2
ffffffffc0203286:	70e60613          	addi	a2,a2,1806 # ffffffffc0205990 <commands+0x998>
ffffffffc020328a:	0eb00593          	li	a1,235
ffffffffc020328e:	00003517          	auipc	a0,0x3
ffffffffc0203292:	22250513          	addi	a0,a0,546 # ffffffffc02064b0 <commands+0x14b8>
ffffffffc0203296:	f3ffc0ef          	jal	ra,ffffffffc02001d4 <__panic>
     assert(mm != NULL);
ffffffffc020329a:	00003697          	auipc	a3,0x3
ffffffffc020329e:	efe68693          	addi	a3,a3,-258 # ffffffffc0206198 <commands+0x11a0>
ffffffffc02032a2:	00002617          	auipc	a2,0x2
ffffffffc02032a6:	6ee60613          	addi	a2,a2,1774 # ffffffffc0205990 <commands+0x998>
ffffffffc02032aa:	0c500593          	li	a1,197
ffffffffc02032ae:	00003517          	auipc	a0,0x3
ffffffffc02032b2:	20250513          	addi	a0,a0,514 # ffffffffc02064b0 <commands+0x14b8>
ffffffffc02032b6:	f1ffc0ef          	jal	ra,ffffffffc02001d4 <__panic>
     assert(check_mm_struct == NULL);
ffffffffc02032ba:	00003697          	auipc	a3,0x3
ffffffffc02032be:	27668693          	addi	a3,a3,630 # ffffffffc0206530 <commands+0x1538>
ffffffffc02032c2:	00002617          	auipc	a2,0x2
ffffffffc02032c6:	6ce60613          	addi	a2,a2,1742 # ffffffffc0205990 <commands+0x998>
ffffffffc02032ca:	0c800593          	li	a1,200
ffffffffc02032ce:	00003517          	auipc	a0,0x3
ffffffffc02032d2:	1e250513          	addi	a0,a0,482 # ffffffffc02064b0 <commands+0x14b8>
ffffffffc02032d6:	efffc0ef          	jal	ra,ffffffffc02001d4 <__panic>
     assert(ret==0);
ffffffffc02032da:	00003697          	auipc	a3,0x3
ffffffffc02032de:	42668693          	addi	a3,a3,1062 # ffffffffc0206700 <commands+0x1708>
ffffffffc02032e2:	00002617          	auipc	a2,0x2
ffffffffc02032e6:	6ae60613          	addi	a2,a2,1710 # ffffffffc0205990 <commands+0x998>
ffffffffc02032ea:	10300593          	li	a1,259
ffffffffc02032ee:	00003517          	auipc	a0,0x3
ffffffffc02032f2:	1c250513          	addi	a0,a0,450 # ffffffffc02064b0 <commands+0x14b8>
ffffffffc02032f6:	edffc0ef          	jal	ra,ffffffffc02001d4 <__panic>
     assert(total == nr_free_pages());
ffffffffc02032fa:	00003697          	auipc	a3,0x3
ffffffffc02032fe:	1ee68693          	addi	a3,a3,494 # ffffffffc02064e8 <commands+0x14f0>
ffffffffc0203302:	00002617          	auipc	a2,0x2
ffffffffc0203306:	68e60613          	addi	a2,a2,1678 # ffffffffc0205990 <commands+0x998>
ffffffffc020330a:	0c000593          	li	a1,192
ffffffffc020330e:	00003517          	auipc	a0,0x3
ffffffffc0203312:	1a250513          	addi	a0,a0,418 # ffffffffc02064b0 <commands+0x14b8>
ffffffffc0203316:	ebffc0ef          	jal	ra,ffffffffc02001d4 <__panic>

ffffffffc020331a <swap_init_mm>:
     return sm->init_mm(mm);
ffffffffc020331a:	00013797          	auipc	a5,0x13
ffffffffc020331e:	18678793          	addi	a5,a5,390 # ffffffffc02164a0 <sm>
ffffffffc0203322:	639c                	ld	a5,0(a5)
ffffffffc0203324:	0107b303          	ld	t1,16(a5)
ffffffffc0203328:	8302                	jr	t1

ffffffffc020332a <swap_map_swappable>:
     return sm->map_swappable(mm, addr, page, swap_in);
ffffffffc020332a:	00013797          	auipc	a5,0x13
ffffffffc020332e:	17678793          	addi	a5,a5,374 # ffffffffc02164a0 <sm>
ffffffffc0203332:	639c                	ld	a5,0(a5)
ffffffffc0203334:	0207b303          	ld	t1,32(a5)
ffffffffc0203338:	8302                	jr	t1

ffffffffc020333a <swap_out>:
{
ffffffffc020333a:	711d                	addi	sp,sp,-96
ffffffffc020333c:	ec86                	sd	ra,88(sp)
ffffffffc020333e:	e8a2                	sd	s0,80(sp)
ffffffffc0203340:	e4a6                	sd	s1,72(sp)
ffffffffc0203342:	e0ca                	sd	s2,64(sp)
ffffffffc0203344:	fc4e                	sd	s3,56(sp)
ffffffffc0203346:	f852                	sd	s4,48(sp)
ffffffffc0203348:	f456                	sd	s5,40(sp)
ffffffffc020334a:	f05a                	sd	s6,32(sp)
ffffffffc020334c:	ec5e                	sd	s7,24(sp)
ffffffffc020334e:	e862                	sd	s8,16(sp)
     for (i = 0; i != n; ++ i)
ffffffffc0203350:	cde9                	beqz	a1,ffffffffc020342a <swap_out+0xf0>
ffffffffc0203352:	8ab2                	mv	s5,a2
ffffffffc0203354:	892a                	mv	s2,a0
ffffffffc0203356:	8a2e                	mv	s4,a1
ffffffffc0203358:	4401                	li	s0,0
ffffffffc020335a:	00013997          	auipc	s3,0x13
ffffffffc020335e:	14698993          	addi	s3,s3,326 # ffffffffc02164a0 <sm>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203362:	00003b17          	auipc	s6,0x3
ffffffffc0203366:	446b0b13          	addi	s6,s6,1094 # ffffffffc02067a8 <commands+0x17b0>
                    cprintf("SWAP: failed to save\n");
ffffffffc020336a:	00003b97          	auipc	s7,0x3
ffffffffc020336e:	426b8b93          	addi	s7,s7,1062 # ffffffffc0206790 <commands+0x1798>
ffffffffc0203372:	a825                	j	ffffffffc02033aa <swap_out+0x70>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203374:	67a2                	ld	a5,8(sp)
ffffffffc0203376:	8626                	mv	a2,s1
ffffffffc0203378:	85a2                	mv	a1,s0
ffffffffc020337a:	7f94                	ld	a3,56(a5)
ffffffffc020337c:	855a                	mv	a0,s6
     for (i = 0; i != n; ++ i)
ffffffffc020337e:	2405                	addiw	s0,s0,1
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203380:	82b1                	srli	a3,a3,0xc
ffffffffc0203382:	0685                	addi	a3,a3,1
ffffffffc0203384:	d4dfc0ef          	jal	ra,ffffffffc02000d0 <cprintf>
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc0203388:	6522                	ld	a0,8(sp)
                    free_page(page);
ffffffffc020338a:	4585                	li	a1,1
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc020338c:	7d1c                	ld	a5,56(a0)
ffffffffc020338e:	83b1                	srli	a5,a5,0xc
ffffffffc0203390:	0785                	addi	a5,a5,1
ffffffffc0203392:	07a2                	slli	a5,a5,0x8
ffffffffc0203394:	00fc3023          	sd	a5,0(s8)
                    free_page(page);
ffffffffc0203398:	897fd0ef          	jal	ra,ffffffffc0200c2e <free_pages>
          tlb_invalidate(mm->pgdir, v);
ffffffffc020339c:	01893503          	ld	a0,24(s2)
ffffffffc02033a0:	85a6                	mv	a1,s1
ffffffffc02033a2:	ef4fe0ef          	jal	ra,ffffffffc0201a96 <tlb_invalidate>
     for (i = 0; i != n; ++ i)
ffffffffc02033a6:	048a0d63          	beq	s4,s0,ffffffffc0203400 <swap_out+0xc6>
          int r = sm->swap_out_victim(mm, &page, in_tick);
ffffffffc02033aa:	0009b783          	ld	a5,0(s3)
ffffffffc02033ae:	8656                	mv	a2,s5
ffffffffc02033b0:	002c                	addi	a1,sp,8
ffffffffc02033b2:	7b9c                	ld	a5,48(a5)
ffffffffc02033b4:	854a                	mv	a0,s2
ffffffffc02033b6:	9782                	jalr	a5
          if (r != 0) {
ffffffffc02033b8:	e12d                	bnez	a0,ffffffffc020341a <swap_out+0xe0>
          v=page->pra_vaddr; 
ffffffffc02033ba:	67a2                	ld	a5,8(sp)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc02033bc:	01893503          	ld	a0,24(s2)
ffffffffc02033c0:	4601                	li	a2,0
          v=page->pra_vaddr; 
ffffffffc02033c2:	7f84                	ld	s1,56(a5)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc02033c4:	85a6                	mv	a1,s1
ffffffffc02033c6:	8effd0ef          	jal	ra,ffffffffc0200cb4 <get_pte>
          assert((*ptep & PTE_V) != 0);
ffffffffc02033ca:	611c                	ld	a5,0(a0)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc02033cc:	8c2a                	mv	s8,a0
          assert((*ptep & PTE_V) != 0);
ffffffffc02033ce:	8b85                	andi	a5,a5,1
ffffffffc02033d0:	cfb9                	beqz	a5,ffffffffc020342e <swap_out+0xf4>
          if (swapfs_write( (page->pra_vaddr/PGSIZE+1)<<8, page) != 0) {
ffffffffc02033d2:	65a2                	ld	a1,8(sp)
ffffffffc02033d4:	7d9c                	ld	a5,56(a1)
ffffffffc02033d6:	83b1                	srli	a5,a5,0xc
ffffffffc02033d8:	00178513          	addi	a0,a5,1
ffffffffc02033dc:	0522                	slli	a0,a0,0x8
ffffffffc02033de:	557000ef          	jal	ra,ffffffffc0204134 <swapfs_write>
ffffffffc02033e2:	d949                	beqz	a0,ffffffffc0203374 <swap_out+0x3a>
                    cprintf("SWAP: failed to save\n");
ffffffffc02033e4:	855e                	mv	a0,s7
ffffffffc02033e6:	cebfc0ef          	jal	ra,ffffffffc02000d0 <cprintf>
                    sm->map_swappable(mm, v, page, 0);
ffffffffc02033ea:	0009b783          	ld	a5,0(s3)
ffffffffc02033ee:	6622                	ld	a2,8(sp)
ffffffffc02033f0:	4681                	li	a3,0
ffffffffc02033f2:	739c                	ld	a5,32(a5)
ffffffffc02033f4:	85a6                	mv	a1,s1
ffffffffc02033f6:	854a                	mv	a0,s2
     for (i = 0; i != n; ++ i)
ffffffffc02033f8:	2405                	addiw	s0,s0,1
                    sm->map_swappable(mm, v, page, 0);
ffffffffc02033fa:	9782                	jalr	a5
     for (i = 0; i != n; ++ i)
ffffffffc02033fc:	fa8a17e3          	bne	s4,s0,ffffffffc02033aa <swap_out+0x70>
}
ffffffffc0203400:	8522                	mv	a0,s0
ffffffffc0203402:	60e6                	ld	ra,88(sp)
ffffffffc0203404:	6446                	ld	s0,80(sp)
ffffffffc0203406:	64a6                	ld	s1,72(sp)
ffffffffc0203408:	6906                	ld	s2,64(sp)
ffffffffc020340a:	79e2                	ld	s3,56(sp)
ffffffffc020340c:	7a42                	ld	s4,48(sp)
ffffffffc020340e:	7aa2                	ld	s5,40(sp)
ffffffffc0203410:	7b02                	ld	s6,32(sp)
ffffffffc0203412:	6be2                	ld	s7,24(sp)
ffffffffc0203414:	6c42                	ld	s8,16(sp)
ffffffffc0203416:	6125                	addi	sp,sp,96
ffffffffc0203418:	8082                	ret
                    cprintf("i %d, swap_out: call swap_out_victim failed\n",i);
ffffffffc020341a:	85a2                	mv	a1,s0
ffffffffc020341c:	00003517          	auipc	a0,0x3
ffffffffc0203420:	32c50513          	addi	a0,a0,812 # ffffffffc0206748 <commands+0x1750>
ffffffffc0203424:	cadfc0ef          	jal	ra,ffffffffc02000d0 <cprintf>
                  break;
ffffffffc0203428:	bfe1                	j	ffffffffc0203400 <swap_out+0xc6>
     for (i = 0; i != n; ++ i)
ffffffffc020342a:	4401                	li	s0,0
ffffffffc020342c:	bfd1                	j	ffffffffc0203400 <swap_out+0xc6>
          assert((*ptep & PTE_V) != 0);
ffffffffc020342e:	00003697          	auipc	a3,0x3
ffffffffc0203432:	34a68693          	addi	a3,a3,842 # ffffffffc0206778 <commands+0x1780>
ffffffffc0203436:	00002617          	auipc	a2,0x2
ffffffffc020343a:	55a60613          	addi	a2,a2,1370 # ffffffffc0205990 <commands+0x998>
ffffffffc020343e:	06900593          	li	a1,105
ffffffffc0203442:	00003517          	auipc	a0,0x3
ffffffffc0203446:	06e50513          	addi	a0,a0,110 # ffffffffc02064b0 <commands+0x14b8>
ffffffffc020344a:	d8bfc0ef          	jal	ra,ffffffffc02001d4 <__panic>

ffffffffc020344e <swap_in>:
{
ffffffffc020344e:	7179                	addi	sp,sp,-48
ffffffffc0203450:	e84a                	sd	s2,16(sp)
ffffffffc0203452:	892a                	mv	s2,a0
     struct Page *result = alloc_page();
ffffffffc0203454:	4505                	li	a0,1
{
ffffffffc0203456:	ec26                	sd	s1,24(sp)
ffffffffc0203458:	e44e                	sd	s3,8(sp)
ffffffffc020345a:	f406                	sd	ra,40(sp)
ffffffffc020345c:	f022                	sd	s0,32(sp)
ffffffffc020345e:	84ae                	mv	s1,a1
ffffffffc0203460:	89b2                	mv	s3,a2
     struct Page *result = alloc_page();
ffffffffc0203462:	f44fd0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
     assert(result!=NULL);
ffffffffc0203466:	c129                	beqz	a0,ffffffffc02034a8 <swap_in+0x5a>
     pte_t *ptep = get_pte(mm->pgdir, addr, 0);
ffffffffc0203468:	842a                	mv	s0,a0
ffffffffc020346a:	01893503          	ld	a0,24(s2)
ffffffffc020346e:	4601                	li	a2,0
ffffffffc0203470:	85a6                	mv	a1,s1
ffffffffc0203472:	843fd0ef          	jal	ra,ffffffffc0200cb4 <get_pte>
ffffffffc0203476:	892a                	mv	s2,a0
     if ((r = swapfs_read((*ptep), result)) != 0)
ffffffffc0203478:	6108                	ld	a0,0(a0)
ffffffffc020347a:	85a2                	mv	a1,s0
ffffffffc020347c:	421000ef          	jal	ra,ffffffffc020409c <swapfs_read>
     cprintf("swap_in: load disk swap entry %d with swap_page in vadr 0x%x\n", (*ptep)>>8, addr);
ffffffffc0203480:	00093583          	ld	a1,0(s2)
ffffffffc0203484:	8626                	mv	a2,s1
ffffffffc0203486:	00003517          	auipc	a0,0x3
ffffffffc020348a:	fca50513          	addi	a0,a0,-54 # ffffffffc0206450 <commands+0x1458>
ffffffffc020348e:	81a1                	srli	a1,a1,0x8
ffffffffc0203490:	c41fc0ef          	jal	ra,ffffffffc02000d0 <cprintf>
}
ffffffffc0203494:	70a2                	ld	ra,40(sp)
     *ptr_result=result;
ffffffffc0203496:	0089b023          	sd	s0,0(s3)
}
ffffffffc020349a:	7402                	ld	s0,32(sp)
ffffffffc020349c:	64e2                	ld	s1,24(sp)
ffffffffc020349e:	6942                	ld	s2,16(sp)
ffffffffc02034a0:	69a2                	ld	s3,8(sp)
ffffffffc02034a2:	4501                	li	a0,0
ffffffffc02034a4:	6145                	addi	sp,sp,48
ffffffffc02034a6:	8082                	ret
     assert(result!=NULL);
ffffffffc02034a8:	00003697          	auipc	a3,0x3
ffffffffc02034ac:	f9868693          	addi	a3,a3,-104 # ffffffffc0206440 <commands+0x1448>
ffffffffc02034b0:	00002617          	auipc	a2,0x2
ffffffffc02034b4:	4e060613          	addi	a2,a2,1248 # ffffffffc0205990 <commands+0x998>
ffffffffc02034b8:	07f00593          	li	a1,127
ffffffffc02034bc:	00003517          	auipc	a0,0x3
ffffffffc02034c0:	ff450513          	addi	a0,a0,-12 # ffffffffc02064b0 <commands+0x14b8>
ffffffffc02034c4:	d11fc0ef          	jal	ra,ffffffffc02001d4 <__panic>

ffffffffc02034c8 <default_init>:
    elm->prev = elm->next = elm;
ffffffffc02034c8:	00013797          	auipc	a5,0x13
ffffffffc02034cc:	11078793          	addi	a5,a5,272 # ffffffffc02165d8 <free_area>
ffffffffc02034d0:	e79c                	sd	a5,8(a5)
ffffffffc02034d2:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc02034d4:	0007a823          	sw	zero,16(a5)
}
ffffffffc02034d8:	8082                	ret

ffffffffc02034da <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc02034da:	00013517          	auipc	a0,0x13
ffffffffc02034de:	10e56503          	lwu	a0,270(a0) # ffffffffc02165e8 <free_area+0x10>
ffffffffc02034e2:	8082                	ret

ffffffffc02034e4 <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc02034e4:	715d                	addi	sp,sp,-80
ffffffffc02034e6:	f84a                	sd	s2,48(sp)
    return listelm->next;
ffffffffc02034e8:	00013917          	auipc	s2,0x13
ffffffffc02034ec:	0f090913          	addi	s2,s2,240 # ffffffffc02165d8 <free_area>
ffffffffc02034f0:	00893783          	ld	a5,8(s2)
ffffffffc02034f4:	e486                	sd	ra,72(sp)
ffffffffc02034f6:	e0a2                	sd	s0,64(sp)
ffffffffc02034f8:	fc26                	sd	s1,56(sp)
ffffffffc02034fa:	f44e                	sd	s3,40(sp)
ffffffffc02034fc:	f052                	sd	s4,32(sp)
ffffffffc02034fe:	ec56                	sd	s5,24(sp)
ffffffffc0203500:	e85a                	sd	s6,16(sp)
ffffffffc0203502:	e45e                	sd	s7,8(sp)
ffffffffc0203504:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0203506:	31278463          	beq	a5,s2,ffffffffc020380e <default_check+0x32a>
ffffffffc020350a:	ff07b703          	ld	a4,-16(a5)
ffffffffc020350e:	8305                	srli	a4,a4,0x1
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0203510:	8b05                	andi	a4,a4,1
ffffffffc0203512:	30070263          	beqz	a4,ffffffffc0203816 <default_check+0x332>
    int count = 0, total = 0;
ffffffffc0203516:	4401                	li	s0,0
ffffffffc0203518:	4481                	li	s1,0
ffffffffc020351a:	a031                	j	ffffffffc0203526 <default_check+0x42>
ffffffffc020351c:	ff07b703          	ld	a4,-16(a5)
        assert(PageProperty(p));
ffffffffc0203520:	8b09                	andi	a4,a4,2
ffffffffc0203522:	2e070a63          	beqz	a4,ffffffffc0203816 <default_check+0x332>
        count++, total += p->property;
ffffffffc0203526:	ff87a703          	lw	a4,-8(a5)
ffffffffc020352a:	679c                	ld	a5,8(a5)
ffffffffc020352c:	2485                	addiw	s1,s1,1
ffffffffc020352e:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0203530:	ff2796e3          	bne	a5,s2,ffffffffc020351c <default_check+0x38>
ffffffffc0203534:	89a2                	mv	s3,s0
    }
    assert(total == nr_free_pages());
ffffffffc0203536:	f3efd0ef          	jal	ra,ffffffffc0200c74 <nr_free_pages>
ffffffffc020353a:	73351e63          	bne	a0,s3,ffffffffc0203c76 <default_check+0x792>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020353e:	4505                	li	a0,1
ffffffffc0203540:	e66fd0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc0203544:	8a2a                	mv	s4,a0
ffffffffc0203546:	46050863          	beqz	a0,ffffffffc02039b6 <default_check+0x4d2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020354a:	4505                	li	a0,1
ffffffffc020354c:	e5afd0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc0203550:	89aa                	mv	s3,a0
ffffffffc0203552:	74050263          	beqz	a0,ffffffffc0203c96 <default_check+0x7b2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0203556:	4505                	li	a0,1
ffffffffc0203558:	e4efd0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc020355c:	8aaa                	mv	s5,a0
ffffffffc020355e:	4c050c63          	beqz	a0,ffffffffc0203a36 <default_check+0x552>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0203562:	2d3a0a63          	beq	s4,s3,ffffffffc0203836 <default_check+0x352>
ffffffffc0203566:	2caa0863          	beq	s4,a0,ffffffffc0203836 <default_check+0x352>
ffffffffc020356a:	2ca98663          	beq	s3,a0,ffffffffc0203836 <default_check+0x352>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020356e:	000a2783          	lw	a5,0(s4)
ffffffffc0203572:	2e079263          	bnez	a5,ffffffffc0203856 <default_check+0x372>
ffffffffc0203576:	0009a783          	lw	a5,0(s3)
ffffffffc020357a:	2c079e63          	bnez	a5,ffffffffc0203856 <default_check+0x372>
ffffffffc020357e:	411c                	lw	a5,0(a0)
ffffffffc0203580:	2c079b63          	bnez	a5,ffffffffc0203856 <default_check+0x372>
    return page - pages + nbase;
ffffffffc0203584:	00013797          	auipc	a5,0x13
ffffffffc0203588:	f6c78793          	addi	a5,a5,-148 # ffffffffc02164f0 <pages>
ffffffffc020358c:	639c                	ld	a5,0(a5)
ffffffffc020358e:	00004717          	auipc	a4,0x4
ffffffffc0203592:	a9270713          	addi	a4,a4,-1390 # ffffffffc0207020 <nbase>
ffffffffc0203596:	6310                	ld	a2,0(a4)
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0203598:	00013717          	auipc	a4,0x13
ffffffffc020359c:	ef070713          	addi	a4,a4,-272 # ffffffffc0216488 <npage>
ffffffffc02035a0:	6314                	ld	a3,0(a4)
ffffffffc02035a2:	40fa0733          	sub	a4,s4,a5
ffffffffc02035a6:	8719                	srai	a4,a4,0x6
ffffffffc02035a8:	9732                	add	a4,a4,a2
ffffffffc02035aa:	06b2                	slli	a3,a3,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02035ac:	0732                	slli	a4,a4,0xc
ffffffffc02035ae:	2cd77463          	bgeu	a4,a3,ffffffffc0203876 <default_check+0x392>
    return page - pages + nbase;
ffffffffc02035b2:	40f98733          	sub	a4,s3,a5
ffffffffc02035b6:	8719                	srai	a4,a4,0x6
ffffffffc02035b8:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02035ba:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02035bc:	4ed77d63          	bgeu	a4,a3,ffffffffc0203ab6 <default_check+0x5d2>
    return page - pages + nbase;
ffffffffc02035c0:	40f507b3          	sub	a5,a0,a5
ffffffffc02035c4:	8799                	srai	a5,a5,0x6
ffffffffc02035c6:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02035c8:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02035ca:	34d7f663          	bgeu	a5,a3,ffffffffc0203916 <default_check+0x432>
    assert(alloc_page() == NULL);
ffffffffc02035ce:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02035d0:	00093c03          	ld	s8,0(s2)
ffffffffc02035d4:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc02035d8:	01092b03          	lw	s6,16(s2)
    elm->prev = elm->next = elm;
ffffffffc02035dc:	00013797          	auipc	a5,0x13
ffffffffc02035e0:	0127b223          	sd	s2,4(a5) # ffffffffc02165e0 <free_area+0x8>
ffffffffc02035e4:	00013797          	auipc	a5,0x13
ffffffffc02035e8:	ff27ba23          	sd	s2,-12(a5) # ffffffffc02165d8 <free_area>
    nr_free = 0;
ffffffffc02035ec:	00013797          	auipc	a5,0x13
ffffffffc02035f0:	fe07ae23          	sw	zero,-4(a5) # ffffffffc02165e8 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc02035f4:	db2fd0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc02035f8:	2e051f63          	bnez	a0,ffffffffc02038f6 <default_check+0x412>
    free_page(p0);
ffffffffc02035fc:	4585                	li	a1,1
ffffffffc02035fe:	8552                	mv	a0,s4
ffffffffc0203600:	e2efd0ef          	jal	ra,ffffffffc0200c2e <free_pages>
    free_page(p1);
ffffffffc0203604:	4585                	li	a1,1
ffffffffc0203606:	854e                	mv	a0,s3
ffffffffc0203608:	e26fd0ef          	jal	ra,ffffffffc0200c2e <free_pages>
    free_page(p2);
ffffffffc020360c:	4585                	li	a1,1
ffffffffc020360e:	8556                	mv	a0,s5
ffffffffc0203610:	e1efd0ef          	jal	ra,ffffffffc0200c2e <free_pages>
    assert(nr_free == 3);
ffffffffc0203614:	01092703          	lw	a4,16(s2)
ffffffffc0203618:	478d                	li	a5,3
ffffffffc020361a:	2af71e63          	bne	a4,a5,ffffffffc02038d6 <default_check+0x3f2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020361e:	4505                	li	a0,1
ffffffffc0203620:	d86fd0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc0203624:	89aa                	mv	s3,a0
ffffffffc0203626:	28050863          	beqz	a0,ffffffffc02038b6 <default_check+0x3d2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020362a:	4505                	li	a0,1
ffffffffc020362c:	d7afd0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc0203630:	8aaa                	mv	s5,a0
ffffffffc0203632:	3e050263          	beqz	a0,ffffffffc0203a16 <default_check+0x532>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0203636:	4505                	li	a0,1
ffffffffc0203638:	d6efd0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc020363c:	8a2a                	mv	s4,a0
ffffffffc020363e:	3a050c63          	beqz	a0,ffffffffc02039f6 <default_check+0x512>
    assert(alloc_page() == NULL);
ffffffffc0203642:	4505                	li	a0,1
ffffffffc0203644:	d62fd0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc0203648:	38051763          	bnez	a0,ffffffffc02039d6 <default_check+0x4f2>
    free_page(p0);
ffffffffc020364c:	4585                	li	a1,1
ffffffffc020364e:	854e                	mv	a0,s3
ffffffffc0203650:	ddefd0ef          	jal	ra,ffffffffc0200c2e <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0203654:	00893783          	ld	a5,8(s2)
ffffffffc0203658:	23278f63          	beq	a5,s2,ffffffffc0203896 <default_check+0x3b2>
    assert((p = alloc_page()) == p0);
ffffffffc020365c:	4505                	li	a0,1
ffffffffc020365e:	d48fd0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc0203662:	32a99a63          	bne	s3,a0,ffffffffc0203996 <default_check+0x4b2>
    assert(alloc_page() == NULL);
ffffffffc0203666:	4505                	li	a0,1
ffffffffc0203668:	d3efd0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc020366c:	30051563          	bnez	a0,ffffffffc0203976 <default_check+0x492>
    assert(nr_free == 0);
ffffffffc0203670:	01092783          	lw	a5,16(s2)
ffffffffc0203674:	2e079163          	bnez	a5,ffffffffc0203956 <default_check+0x472>
    free_page(p);
ffffffffc0203678:	854e                	mv	a0,s3
ffffffffc020367a:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc020367c:	00013797          	auipc	a5,0x13
ffffffffc0203680:	f587be23          	sd	s8,-164(a5) # ffffffffc02165d8 <free_area>
ffffffffc0203684:	00013797          	auipc	a5,0x13
ffffffffc0203688:	f577be23          	sd	s7,-164(a5) # ffffffffc02165e0 <free_area+0x8>
    nr_free = nr_free_store;
ffffffffc020368c:	00013797          	auipc	a5,0x13
ffffffffc0203690:	f567ae23          	sw	s6,-164(a5) # ffffffffc02165e8 <free_area+0x10>
    free_page(p);
ffffffffc0203694:	d9afd0ef          	jal	ra,ffffffffc0200c2e <free_pages>
    free_page(p1);
ffffffffc0203698:	4585                	li	a1,1
ffffffffc020369a:	8556                	mv	a0,s5
ffffffffc020369c:	d92fd0ef          	jal	ra,ffffffffc0200c2e <free_pages>
    free_page(p2);
ffffffffc02036a0:	4585                	li	a1,1
ffffffffc02036a2:	8552                	mv	a0,s4
ffffffffc02036a4:	d8afd0ef          	jal	ra,ffffffffc0200c2e <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc02036a8:	4515                	li	a0,5
ffffffffc02036aa:	cfcfd0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc02036ae:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc02036b0:	28050363          	beqz	a0,ffffffffc0203936 <default_check+0x452>
ffffffffc02036b4:	651c                	ld	a5,8(a0)
ffffffffc02036b6:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc02036b8:	8b85                	andi	a5,a5,1
ffffffffc02036ba:	54079e63          	bnez	a5,ffffffffc0203c16 <default_check+0x732>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc02036be:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02036c0:	00093b03          	ld	s6,0(s2)
ffffffffc02036c4:	00893a83          	ld	s5,8(s2)
ffffffffc02036c8:	00013797          	auipc	a5,0x13
ffffffffc02036cc:	f127b823          	sd	s2,-240(a5) # ffffffffc02165d8 <free_area>
ffffffffc02036d0:	00013797          	auipc	a5,0x13
ffffffffc02036d4:	f127b823          	sd	s2,-240(a5) # ffffffffc02165e0 <free_area+0x8>
    assert(alloc_page() == NULL);
ffffffffc02036d8:	ccefd0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc02036dc:	50051d63          	bnez	a0,ffffffffc0203bf6 <default_check+0x712>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc02036e0:	08098a13          	addi	s4,s3,128
ffffffffc02036e4:	8552                	mv	a0,s4
ffffffffc02036e6:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc02036e8:	01092b83          	lw	s7,16(s2)
    nr_free = 0;
ffffffffc02036ec:	00013797          	auipc	a5,0x13
ffffffffc02036f0:	ee07ae23          	sw	zero,-260(a5) # ffffffffc02165e8 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc02036f4:	d3afd0ef          	jal	ra,ffffffffc0200c2e <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc02036f8:	4511                	li	a0,4
ffffffffc02036fa:	cacfd0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc02036fe:	4c051c63          	bnez	a0,ffffffffc0203bd6 <default_check+0x6f2>
ffffffffc0203702:	0889b783          	ld	a5,136(s3)
ffffffffc0203706:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0203708:	8b85                	andi	a5,a5,1
ffffffffc020370a:	4a078663          	beqz	a5,ffffffffc0203bb6 <default_check+0x6d2>
ffffffffc020370e:	0909a703          	lw	a4,144(s3)
ffffffffc0203712:	478d                	li	a5,3
ffffffffc0203714:	4af71163          	bne	a4,a5,ffffffffc0203bb6 <default_check+0x6d2>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0203718:	450d                	li	a0,3
ffffffffc020371a:	c8cfd0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc020371e:	8c2a                	mv	s8,a0
ffffffffc0203720:	46050b63          	beqz	a0,ffffffffc0203b96 <default_check+0x6b2>
    assert(alloc_page() == NULL);
ffffffffc0203724:	4505                	li	a0,1
ffffffffc0203726:	c80fd0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc020372a:	44051663          	bnez	a0,ffffffffc0203b76 <default_check+0x692>
    assert(p0 + 2 == p1);
ffffffffc020372e:	438a1463          	bne	s4,s8,ffffffffc0203b56 <default_check+0x672>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0203732:	4585                	li	a1,1
ffffffffc0203734:	854e                	mv	a0,s3
ffffffffc0203736:	cf8fd0ef          	jal	ra,ffffffffc0200c2e <free_pages>
    free_pages(p1, 3);
ffffffffc020373a:	458d                	li	a1,3
ffffffffc020373c:	8552                	mv	a0,s4
ffffffffc020373e:	cf0fd0ef          	jal	ra,ffffffffc0200c2e <free_pages>
ffffffffc0203742:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0203746:	04098c13          	addi	s8,s3,64
ffffffffc020374a:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc020374c:	8b85                	andi	a5,a5,1
ffffffffc020374e:	3e078463          	beqz	a5,ffffffffc0203b36 <default_check+0x652>
ffffffffc0203752:	0109a703          	lw	a4,16(s3)
ffffffffc0203756:	4785                	li	a5,1
ffffffffc0203758:	3cf71f63          	bne	a4,a5,ffffffffc0203b36 <default_check+0x652>
ffffffffc020375c:	008a3783          	ld	a5,8(s4)
ffffffffc0203760:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0203762:	8b85                	andi	a5,a5,1
ffffffffc0203764:	3a078963          	beqz	a5,ffffffffc0203b16 <default_check+0x632>
ffffffffc0203768:	010a2703          	lw	a4,16(s4)
ffffffffc020376c:	478d                	li	a5,3
ffffffffc020376e:	3af71463          	bne	a4,a5,ffffffffc0203b16 <default_check+0x632>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0203772:	4505                	li	a0,1
ffffffffc0203774:	c32fd0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc0203778:	36a99f63          	bne	s3,a0,ffffffffc0203af6 <default_check+0x612>
    free_page(p0);
ffffffffc020377c:	4585                	li	a1,1
ffffffffc020377e:	cb0fd0ef          	jal	ra,ffffffffc0200c2e <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0203782:	4509                	li	a0,2
ffffffffc0203784:	c22fd0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc0203788:	34aa1763          	bne	s4,a0,ffffffffc0203ad6 <default_check+0x5f2>

    free_pages(p0, 2);
ffffffffc020378c:	4589                	li	a1,2
ffffffffc020378e:	ca0fd0ef          	jal	ra,ffffffffc0200c2e <free_pages>
    free_page(p2);
ffffffffc0203792:	4585                	li	a1,1
ffffffffc0203794:	8562                	mv	a0,s8
ffffffffc0203796:	c98fd0ef          	jal	ra,ffffffffc0200c2e <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020379a:	4515                	li	a0,5
ffffffffc020379c:	c0afd0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc02037a0:	89aa                	mv	s3,a0
ffffffffc02037a2:	48050a63          	beqz	a0,ffffffffc0203c36 <default_check+0x752>
    assert(alloc_page() == NULL);
ffffffffc02037a6:	4505                	li	a0,1
ffffffffc02037a8:	bfefd0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
ffffffffc02037ac:	2e051563          	bnez	a0,ffffffffc0203a96 <default_check+0x5b2>

    assert(nr_free == 0);
ffffffffc02037b0:	01092783          	lw	a5,16(s2)
ffffffffc02037b4:	2c079163          	bnez	a5,ffffffffc0203a76 <default_check+0x592>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc02037b8:	4595                	li	a1,5
ffffffffc02037ba:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc02037bc:	00013797          	auipc	a5,0x13
ffffffffc02037c0:	e377a623          	sw	s7,-468(a5) # ffffffffc02165e8 <free_area+0x10>
    free_list = free_list_store;
ffffffffc02037c4:	00013797          	auipc	a5,0x13
ffffffffc02037c8:	e167ba23          	sd	s6,-492(a5) # ffffffffc02165d8 <free_area>
ffffffffc02037cc:	00013797          	auipc	a5,0x13
ffffffffc02037d0:	e157ba23          	sd	s5,-492(a5) # ffffffffc02165e0 <free_area+0x8>
    free_pages(p0, 5);
ffffffffc02037d4:	c5afd0ef          	jal	ra,ffffffffc0200c2e <free_pages>
    return listelm->next;
ffffffffc02037d8:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc02037dc:	01278963          	beq	a5,s2,ffffffffc02037ee <default_check+0x30a>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc02037e0:	ff87a703          	lw	a4,-8(a5)
ffffffffc02037e4:	679c                	ld	a5,8(a5)
ffffffffc02037e6:	34fd                	addiw	s1,s1,-1
ffffffffc02037e8:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc02037ea:	ff279be3          	bne	a5,s2,ffffffffc02037e0 <default_check+0x2fc>
    }
    assert(count == 0);
ffffffffc02037ee:	26049463          	bnez	s1,ffffffffc0203a56 <default_check+0x572>
    assert(total == 0);
ffffffffc02037f2:	46041263          	bnez	s0,ffffffffc0203c56 <default_check+0x772>
}
ffffffffc02037f6:	60a6                	ld	ra,72(sp)
ffffffffc02037f8:	6406                	ld	s0,64(sp)
ffffffffc02037fa:	74e2                	ld	s1,56(sp)
ffffffffc02037fc:	7942                	ld	s2,48(sp)
ffffffffc02037fe:	79a2                	ld	s3,40(sp)
ffffffffc0203800:	7a02                	ld	s4,32(sp)
ffffffffc0203802:	6ae2                	ld	s5,24(sp)
ffffffffc0203804:	6b42                	ld	s6,16(sp)
ffffffffc0203806:	6ba2                	ld	s7,8(sp)
ffffffffc0203808:	6c02                	ld	s8,0(sp)
ffffffffc020380a:	6161                	addi	sp,sp,80
ffffffffc020380c:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc020380e:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0203810:	4401                	li	s0,0
ffffffffc0203812:	4481                	li	s1,0
ffffffffc0203814:	b30d                	j	ffffffffc0203536 <default_check+0x52>
        assert(PageProperty(p));
ffffffffc0203816:	00003697          	auipc	a3,0x3
ffffffffc020381a:	cc268693          	addi	a3,a3,-830 # ffffffffc02064d8 <commands+0x14e0>
ffffffffc020381e:	00002617          	auipc	a2,0x2
ffffffffc0203822:	17260613          	addi	a2,a2,370 # ffffffffc0205990 <commands+0x998>
ffffffffc0203826:	11b00593          	li	a1,283
ffffffffc020382a:	00003517          	auipc	a0,0x3
ffffffffc020382e:	fbe50513          	addi	a0,a0,-66 # ffffffffc02067e8 <commands+0x17f0>
ffffffffc0203832:	9a3fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0203836:	00003697          	auipc	a3,0x3
ffffffffc020383a:	02a68693          	addi	a3,a3,42 # ffffffffc0206860 <commands+0x1868>
ffffffffc020383e:	00002617          	auipc	a2,0x2
ffffffffc0203842:	15260613          	addi	a2,a2,338 # ffffffffc0205990 <commands+0x998>
ffffffffc0203846:	0e600593          	li	a1,230
ffffffffc020384a:	00003517          	auipc	a0,0x3
ffffffffc020384e:	f9e50513          	addi	a0,a0,-98 # ffffffffc02067e8 <commands+0x17f0>
ffffffffc0203852:	983fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0203856:	00003697          	auipc	a3,0x3
ffffffffc020385a:	03268693          	addi	a3,a3,50 # ffffffffc0206888 <commands+0x1890>
ffffffffc020385e:	00002617          	auipc	a2,0x2
ffffffffc0203862:	13260613          	addi	a2,a2,306 # ffffffffc0205990 <commands+0x998>
ffffffffc0203866:	0e700593          	li	a1,231
ffffffffc020386a:	00003517          	auipc	a0,0x3
ffffffffc020386e:	f7e50513          	addi	a0,a0,-130 # ffffffffc02067e8 <commands+0x17f0>
ffffffffc0203872:	963fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0203876:	00003697          	auipc	a3,0x3
ffffffffc020387a:	05268693          	addi	a3,a3,82 # ffffffffc02068c8 <commands+0x18d0>
ffffffffc020387e:	00002617          	auipc	a2,0x2
ffffffffc0203882:	11260613          	addi	a2,a2,274 # ffffffffc0205990 <commands+0x998>
ffffffffc0203886:	0e900593          	li	a1,233
ffffffffc020388a:	00003517          	auipc	a0,0x3
ffffffffc020388e:	f5e50513          	addi	a0,a0,-162 # ffffffffc02067e8 <commands+0x17f0>
ffffffffc0203892:	943fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0203896:	00003697          	auipc	a3,0x3
ffffffffc020389a:	0ba68693          	addi	a3,a3,186 # ffffffffc0206950 <commands+0x1958>
ffffffffc020389e:	00002617          	auipc	a2,0x2
ffffffffc02038a2:	0f260613          	addi	a2,a2,242 # ffffffffc0205990 <commands+0x998>
ffffffffc02038a6:	10200593          	li	a1,258
ffffffffc02038aa:	00003517          	auipc	a0,0x3
ffffffffc02038ae:	f3e50513          	addi	a0,a0,-194 # ffffffffc02067e8 <commands+0x17f0>
ffffffffc02038b2:	923fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02038b6:	00003697          	auipc	a3,0x3
ffffffffc02038ba:	f4a68693          	addi	a3,a3,-182 # ffffffffc0206800 <commands+0x1808>
ffffffffc02038be:	00002617          	auipc	a2,0x2
ffffffffc02038c2:	0d260613          	addi	a2,a2,210 # ffffffffc0205990 <commands+0x998>
ffffffffc02038c6:	0fb00593          	li	a1,251
ffffffffc02038ca:	00003517          	auipc	a0,0x3
ffffffffc02038ce:	f1e50513          	addi	a0,a0,-226 # ffffffffc02067e8 <commands+0x17f0>
ffffffffc02038d2:	903fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(nr_free == 3);
ffffffffc02038d6:	00003697          	auipc	a3,0x3
ffffffffc02038da:	06a68693          	addi	a3,a3,106 # ffffffffc0206940 <commands+0x1948>
ffffffffc02038de:	00002617          	auipc	a2,0x2
ffffffffc02038e2:	0b260613          	addi	a2,a2,178 # ffffffffc0205990 <commands+0x998>
ffffffffc02038e6:	0f900593          	li	a1,249
ffffffffc02038ea:	00003517          	auipc	a0,0x3
ffffffffc02038ee:	efe50513          	addi	a0,a0,-258 # ffffffffc02067e8 <commands+0x17f0>
ffffffffc02038f2:	8e3fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02038f6:	00003697          	auipc	a3,0x3
ffffffffc02038fa:	03268693          	addi	a3,a3,50 # ffffffffc0206928 <commands+0x1930>
ffffffffc02038fe:	00002617          	auipc	a2,0x2
ffffffffc0203902:	09260613          	addi	a2,a2,146 # ffffffffc0205990 <commands+0x998>
ffffffffc0203906:	0f400593          	li	a1,244
ffffffffc020390a:	00003517          	auipc	a0,0x3
ffffffffc020390e:	ede50513          	addi	a0,a0,-290 # ffffffffc02067e8 <commands+0x17f0>
ffffffffc0203912:	8c3fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0203916:	00003697          	auipc	a3,0x3
ffffffffc020391a:	ff268693          	addi	a3,a3,-14 # ffffffffc0206908 <commands+0x1910>
ffffffffc020391e:	00002617          	auipc	a2,0x2
ffffffffc0203922:	07260613          	addi	a2,a2,114 # ffffffffc0205990 <commands+0x998>
ffffffffc0203926:	0eb00593          	li	a1,235
ffffffffc020392a:	00003517          	auipc	a0,0x3
ffffffffc020392e:	ebe50513          	addi	a0,a0,-322 # ffffffffc02067e8 <commands+0x17f0>
ffffffffc0203932:	8a3fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(p0 != NULL);
ffffffffc0203936:	00003697          	auipc	a3,0x3
ffffffffc020393a:	05268693          	addi	a3,a3,82 # ffffffffc0206988 <commands+0x1990>
ffffffffc020393e:	00002617          	auipc	a2,0x2
ffffffffc0203942:	05260613          	addi	a2,a2,82 # ffffffffc0205990 <commands+0x998>
ffffffffc0203946:	12300593          	li	a1,291
ffffffffc020394a:	00003517          	auipc	a0,0x3
ffffffffc020394e:	e9e50513          	addi	a0,a0,-354 # ffffffffc02067e8 <commands+0x17f0>
ffffffffc0203952:	883fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(nr_free == 0);
ffffffffc0203956:	00003697          	auipc	a3,0x3
ffffffffc020395a:	d3268693          	addi	a3,a3,-718 # ffffffffc0206688 <commands+0x1690>
ffffffffc020395e:	00002617          	auipc	a2,0x2
ffffffffc0203962:	03260613          	addi	a2,a2,50 # ffffffffc0205990 <commands+0x998>
ffffffffc0203966:	10800593          	li	a1,264
ffffffffc020396a:	00003517          	auipc	a0,0x3
ffffffffc020396e:	e7e50513          	addi	a0,a0,-386 # ffffffffc02067e8 <commands+0x17f0>
ffffffffc0203972:	863fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0203976:	00003697          	auipc	a3,0x3
ffffffffc020397a:	fb268693          	addi	a3,a3,-78 # ffffffffc0206928 <commands+0x1930>
ffffffffc020397e:	00002617          	auipc	a2,0x2
ffffffffc0203982:	01260613          	addi	a2,a2,18 # ffffffffc0205990 <commands+0x998>
ffffffffc0203986:	10600593          	li	a1,262
ffffffffc020398a:	00003517          	auipc	a0,0x3
ffffffffc020398e:	e5e50513          	addi	a0,a0,-418 # ffffffffc02067e8 <commands+0x17f0>
ffffffffc0203992:	843fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0203996:	00003697          	auipc	a3,0x3
ffffffffc020399a:	fd268693          	addi	a3,a3,-46 # ffffffffc0206968 <commands+0x1970>
ffffffffc020399e:	00002617          	auipc	a2,0x2
ffffffffc02039a2:	ff260613          	addi	a2,a2,-14 # ffffffffc0205990 <commands+0x998>
ffffffffc02039a6:	10500593          	li	a1,261
ffffffffc02039aa:	00003517          	auipc	a0,0x3
ffffffffc02039ae:	e3e50513          	addi	a0,a0,-450 # ffffffffc02067e8 <commands+0x17f0>
ffffffffc02039b2:	823fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02039b6:	00003697          	auipc	a3,0x3
ffffffffc02039ba:	e4a68693          	addi	a3,a3,-438 # ffffffffc0206800 <commands+0x1808>
ffffffffc02039be:	00002617          	auipc	a2,0x2
ffffffffc02039c2:	fd260613          	addi	a2,a2,-46 # ffffffffc0205990 <commands+0x998>
ffffffffc02039c6:	0e200593          	li	a1,226
ffffffffc02039ca:	00003517          	auipc	a0,0x3
ffffffffc02039ce:	e1e50513          	addi	a0,a0,-482 # ffffffffc02067e8 <commands+0x17f0>
ffffffffc02039d2:	803fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02039d6:	00003697          	auipc	a3,0x3
ffffffffc02039da:	f5268693          	addi	a3,a3,-174 # ffffffffc0206928 <commands+0x1930>
ffffffffc02039de:	00002617          	auipc	a2,0x2
ffffffffc02039e2:	fb260613          	addi	a2,a2,-78 # ffffffffc0205990 <commands+0x998>
ffffffffc02039e6:	0ff00593          	li	a1,255
ffffffffc02039ea:	00003517          	auipc	a0,0x3
ffffffffc02039ee:	dfe50513          	addi	a0,a0,-514 # ffffffffc02067e8 <commands+0x17f0>
ffffffffc02039f2:	fe2fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02039f6:	00003697          	auipc	a3,0x3
ffffffffc02039fa:	e4a68693          	addi	a3,a3,-438 # ffffffffc0206840 <commands+0x1848>
ffffffffc02039fe:	00002617          	auipc	a2,0x2
ffffffffc0203a02:	f9260613          	addi	a2,a2,-110 # ffffffffc0205990 <commands+0x998>
ffffffffc0203a06:	0fd00593          	li	a1,253
ffffffffc0203a0a:	00003517          	auipc	a0,0x3
ffffffffc0203a0e:	dde50513          	addi	a0,a0,-546 # ffffffffc02067e8 <commands+0x17f0>
ffffffffc0203a12:	fc2fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0203a16:	00003697          	auipc	a3,0x3
ffffffffc0203a1a:	e0a68693          	addi	a3,a3,-502 # ffffffffc0206820 <commands+0x1828>
ffffffffc0203a1e:	00002617          	auipc	a2,0x2
ffffffffc0203a22:	f7260613          	addi	a2,a2,-142 # ffffffffc0205990 <commands+0x998>
ffffffffc0203a26:	0fc00593          	li	a1,252
ffffffffc0203a2a:	00003517          	auipc	a0,0x3
ffffffffc0203a2e:	dbe50513          	addi	a0,a0,-578 # ffffffffc02067e8 <commands+0x17f0>
ffffffffc0203a32:	fa2fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0203a36:	00003697          	auipc	a3,0x3
ffffffffc0203a3a:	e0a68693          	addi	a3,a3,-502 # ffffffffc0206840 <commands+0x1848>
ffffffffc0203a3e:	00002617          	auipc	a2,0x2
ffffffffc0203a42:	f5260613          	addi	a2,a2,-174 # ffffffffc0205990 <commands+0x998>
ffffffffc0203a46:	0e400593          	li	a1,228
ffffffffc0203a4a:	00003517          	auipc	a0,0x3
ffffffffc0203a4e:	d9e50513          	addi	a0,a0,-610 # ffffffffc02067e8 <commands+0x17f0>
ffffffffc0203a52:	f82fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(count == 0);
ffffffffc0203a56:	00003697          	auipc	a3,0x3
ffffffffc0203a5a:	08268693          	addi	a3,a3,130 # ffffffffc0206ad8 <commands+0x1ae0>
ffffffffc0203a5e:	00002617          	auipc	a2,0x2
ffffffffc0203a62:	f3260613          	addi	a2,a2,-206 # ffffffffc0205990 <commands+0x998>
ffffffffc0203a66:	15100593          	li	a1,337
ffffffffc0203a6a:	00003517          	auipc	a0,0x3
ffffffffc0203a6e:	d7e50513          	addi	a0,a0,-642 # ffffffffc02067e8 <commands+0x17f0>
ffffffffc0203a72:	f62fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(nr_free == 0);
ffffffffc0203a76:	00003697          	auipc	a3,0x3
ffffffffc0203a7a:	c1268693          	addi	a3,a3,-1006 # ffffffffc0206688 <commands+0x1690>
ffffffffc0203a7e:	00002617          	auipc	a2,0x2
ffffffffc0203a82:	f1260613          	addi	a2,a2,-238 # ffffffffc0205990 <commands+0x998>
ffffffffc0203a86:	14500593          	li	a1,325
ffffffffc0203a8a:	00003517          	auipc	a0,0x3
ffffffffc0203a8e:	d5e50513          	addi	a0,a0,-674 # ffffffffc02067e8 <commands+0x17f0>
ffffffffc0203a92:	f42fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0203a96:	00003697          	auipc	a3,0x3
ffffffffc0203a9a:	e9268693          	addi	a3,a3,-366 # ffffffffc0206928 <commands+0x1930>
ffffffffc0203a9e:	00002617          	auipc	a2,0x2
ffffffffc0203aa2:	ef260613          	addi	a2,a2,-270 # ffffffffc0205990 <commands+0x998>
ffffffffc0203aa6:	14300593          	li	a1,323
ffffffffc0203aaa:	00003517          	auipc	a0,0x3
ffffffffc0203aae:	d3e50513          	addi	a0,a0,-706 # ffffffffc02067e8 <commands+0x17f0>
ffffffffc0203ab2:	f22fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0203ab6:	00003697          	auipc	a3,0x3
ffffffffc0203aba:	e3268693          	addi	a3,a3,-462 # ffffffffc02068e8 <commands+0x18f0>
ffffffffc0203abe:	00002617          	auipc	a2,0x2
ffffffffc0203ac2:	ed260613          	addi	a2,a2,-302 # ffffffffc0205990 <commands+0x998>
ffffffffc0203ac6:	0ea00593          	li	a1,234
ffffffffc0203aca:	00003517          	auipc	a0,0x3
ffffffffc0203ace:	d1e50513          	addi	a0,a0,-738 # ffffffffc02067e8 <commands+0x17f0>
ffffffffc0203ad2:	f02fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0203ad6:	00003697          	auipc	a3,0x3
ffffffffc0203ada:	fc268693          	addi	a3,a3,-62 # ffffffffc0206a98 <commands+0x1aa0>
ffffffffc0203ade:	00002617          	auipc	a2,0x2
ffffffffc0203ae2:	eb260613          	addi	a2,a2,-334 # ffffffffc0205990 <commands+0x998>
ffffffffc0203ae6:	13d00593          	li	a1,317
ffffffffc0203aea:	00003517          	auipc	a0,0x3
ffffffffc0203aee:	cfe50513          	addi	a0,a0,-770 # ffffffffc02067e8 <commands+0x17f0>
ffffffffc0203af2:	ee2fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0203af6:	00003697          	auipc	a3,0x3
ffffffffc0203afa:	f8268693          	addi	a3,a3,-126 # ffffffffc0206a78 <commands+0x1a80>
ffffffffc0203afe:	00002617          	auipc	a2,0x2
ffffffffc0203b02:	e9260613          	addi	a2,a2,-366 # ffffffffc0205990 <commands+0x998>
ffffffffc0203b06:	13b00593          	li	a1,315
ffffffffc0203b0a:	00003517          	auipc	a0,0x3
ffffffffc0203b0e:	cde50513          	addi	a0,a0,-802 # ffffffffc02067e8 <commands+0x17f0>
ffffffffc0203b12:	ec2fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0203b16:	00003697          	auipc	a3,0x3
ffffffffc0203b1a:	f3a68693          	addi	a3,a3,-198 # ffffffffc0206a50 <commands+0x1a58>
ffffffffc0203b1e:	00002617          	auipc	a2,0x2
ffffffffc0203b22:	e7260613          	addi	a2,a2,-398 # ffffffffc0205990 <commands+0x998>
ffffffffc0203b26:	13900593          	li	a1,313
ffffffffc0203b2a:	00003517          	auipc	a0,0x3
ffffffffc0203b2e:	cbe50513          	addi	a0,a0,-834 # ffffffffc02067e8 <commands+0x17f0>
ffffffffc0203b32:	ea2fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0203b36:	00003697          	auipc	a3,0x3
ffffffffc0203b3a:	ef268693          	addi	a3,a3,-270 # ffffffffc0206a28 <commands+0x1a30>
ffffffffc0203b3e:	00002617          	auipc	a2,0x2
ffffffffc0203b42:	e5260613          	addi	a2,a2,-430 # ffffffffc0205990 <commands+0x998>
ffffffffc0203b46:	13800593          	li	a1,312
ffffffffc0203b4a:	00003517          	auipc	a0,0x3
ffffffffc0203b4e:	c9e50513          	addi	a0,a0,-866 # ffffffffc02067e8 <commands+0x17f0>
ffffffffc0203b52:	e82fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(p0 + 2 == p1);
ffffffffc0203b56:	00003697          	auipc	a3,0x3
ffffffffc0203b5a:	ec268693          	addi	a3,a3,-318 # ffffffffc0206a18 <commands+0x1a20>
ffffffffc0203b5e:	00002617          	auipc	a2,0x2
ffffffffc0203b62:	e3260613          	addi	a2,a2,-462 # ffffffffc0205990 <commands+0x998>
ffffffffc0203b66:	13300593          	li	a1,307
ffffffffc0203b6a:	00003517          	auipc	a0,0x3
ffffffffc0203b6e:	c7e50513          	addi	a0,a0,-898 # ffffffffc02067e8 <commands+0x17f0>
ffffffffc0203b72:	e62fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0203b76:	00003697          	auipc	a3,0x3
ffffffffc0203b7a:	db268693          	addi	a3,a3,-590 # ffffffffc0206928 <commands+0x1930>
ffffffffc0203b7e:	00002617          	auipc	a2,0x2
ffffffffc0203b82:	e1260613          	addi	a2,a2,-494 # ffffffffc0205990 <commands+0x998>
ffffffffc0203b86:	13200593          	li	a1,306
ffffffffc0203b8a:	00003517          	auipc	a0,0x3
ffffffffc0203b8e:	c5e50513          	addi	a0,a0,-930 # ffffffffc02067e8 <commands+0x17f0>
ffffffffc0203b92:	e42fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0203b96:	00003697          	auipc	a3,0x3
ffffffffc0203b9a:	e6268693          	addi	a3,a3,-414 # ffffffffc02069f8 <commands+0x1a00>
ffffffffc0203b9e:	00002617          	auipc	a2,0x2
ffffffffc0203ba2:	df260613          	addi	a2,a2,-526 # ffffffffc0205990 <commands+0x998>
ffffffffc0203ba6:	13100593          	li	a1,305
ffffffffc0203baa:	00003517          	auipc	a0,0x3
ffffffffc0203bae:	c3e50513          	addi	a0,a0,-962 # ffffffffc02067e8 <commands+0x17f0>
ffffffffc0203bb2:	e22fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0203bb6:	00003697          	auipc	a3,0x3
ffffffffc0203bba:	e1268693          	addi	a3,a3,-494 # ffffffffc02069c8 <commands+0x19d0>
ffffffffc0203bbe:	00002617          	auipc	a2,0x2
ffffffffc0203bc2:	dd260613          	addi	a2,a2,-558 # ffffffffc0205990 <commands+0x998>
ffffffffc0203bc6:	13000593          	li	a1,304
ffffffffc0203bca:	00003517          	auipc	a0,0x3
ffffffffc0203bce:	c1e50513          	addi	a0,a0,-994 # ffffffffc02067e8 <commands+0x17f0>
ffffffffc0203bd2:	e02fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0203bd6:	00003697          	auipc	a3,0x3
ffffffffc0203bda:	dda68693          	addi	a3,a3,-550 # ffffffffc02069b0 <commands+0x19b8>
ffffffffc0203bde:	00002617          	auipc	a2,0x2
ffffffffc0203be2:	db260613          	addi	a2,a2,-590 # ffffffffc0205990 <commands+0x998>
ffffffffc0203be6:	12f00593          	li	a1,303
ffffffffc0203bea:	00003517          	auipc	a0,0x3
ffffffffc0203bee:	bfe50513          	addi	a0,a0,-1026 # ffffffffc02067e8 <commands+0x17f0>
ffffffffc0203bf2:	de2fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0203bf6:	00003697          	auipc	a3,0x3
ffffffffc0203bfa:	d3268693          	addi	a3,a3,-718 # ffffffffc0206928 <commands+0x1930>
ffffffffc0203bfe:	00002617          	auipc	a2,0x2
ffffffffc0203c02:	d9260613          	addi	a2,a2,-622 # ffffffffc0205990 <commands+0x998>
ffffffffc0203c06:	12900593          	li	a1,297
ffffffffc0203c0a:	00003517          	auipc	a0,0x3
ffffffffc0203c0e:	bde50513          	addi	a0,a0,-1058 # ffffffffc02067e8 <commands+0x17f0>
ffffffffc0203c12:	dc2fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(!PageProperty(p0));
ffffffffc0203c16:	00003697          	auipc	a3,0x3
ffffffffc0203c1a:	d8268693          	addi	a3,a3,-638 # ffffffffc0206998 <commands+0x19a0>
ffffffffc0203c1e:	00002617          	auipc	a2,0x2
ffffffffc0203c22:	d7260613          	addi	a2,a2,-654 # ffffffffc0205990 <commands+0x998>
ffffffffc0203c26:	12400593          	li	a1,292
ffffffffc0203c2a:	00003517          	auipc	a0,0x3
ffffffffc0203c2e:	bbe50513          	addi	a0,a0,-1090 # ffffffffc02067e8 <commands+0x17f0>
ffffffffc0203c32:	da2fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0203c36:	00003697          	auipc	a3,0x3
ffffffffc0203c3a:	e8268693          	addi	a3,a3,-382 # ffffffffc0206ab8 <commands+0x1ac0>
ffffffffc0203c3e:	00002617          	auipc	a2,0x2
ffffffffc0203c42:	d5260613          	addi	a2,a2,-686 # ffffffffc0205990 <commands+0x998>
ffffffffc0203c46:	14200593          	li	a1,322
ffffffffc0203c4a:	00003517          	auipc	a0,0x3
ffffffffc0203c4e:	b9e50513          	addi	a0,a0,-1122 # ffffffffc02067e8 <commands+0x17f0>
ffffffffc0203c52:	d82fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(total == 0);
ffffffffc0203c56:	00003697          	auipc	a3,0x3
ffffffffc0203c5a:	e9268693          	addi	a3,a3,-366 # ffffffffc0206ae8 <commands+0x1af0>
ffffffffc0203c5e:	00002617          	auipc	a2,0x2
ffffffffc0203c62:	d3260613          	addi	a2,a2,-718 # ffffffffc0205990 <commands+0x998>
ffffffffc0203c66:	15200593          	li	a1,338
ffffffffc0203c6a:	00003517          	auipc	a0,0x3
ffffffffc0203c6e:	b7e50513          	addi	a0,a0,-1154 # ffffffffc02067e8 <commands+0x17f0>
ffffffffc0203c72:	d62fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(total == nr_free_pages());
ffffffffc0203c76:	00003697          	auipc	a3,0x3
ffffffffc0203c7a:	87268693          	addi	a3,a3,-1934 # ffffffffc02064e8 <commands+0x14f0>
ffffffffc0203c7e:	00002617          	auipc	a2,0x2
ffffffffc0203c82:	d1260613          	addi	a2,a2,-750 # ffffffffc0205990 <commands+0x998>
ffffffffc0203c86:	11e00593          	li	a1,286
ffffffffc0203c8a:	00003517          	auipc	a0,0x3
ffffffffc0203c8e:	b5e50513          	addi	a0,a0,-1186 # ffffffffc02067e8 <commands+0x17f0>
ffffffffc0203c92:	d42fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0203c96:	00003697          	auipc	a3,0x3
ffffffffc0203c9a:	b8a68693          	addi	a3,a3,-1142 # ffffffffc0206820 <commands+0x1828>
ffffffffc0203c9e:	00002617          	auipc	a2,0x2
ffffffffc0203ca2:	cf260613          	addi	a2,a2,-782 # ffffffffc0205990 <commands+0x998>
ffffffffc0203ca6:	0e300593          	li	a1,227
ffffffffc0203caa:	00003517          	auipc	a0,0x3
ffffffffc0203cae:	b3e50513          	addi	a0,a0,-1218 # ffffffffc02067e8 <commands+0x17f0>
ffffffffc0203cb2:	d22fc0ef          	jal	ra,ffffffffc02001d4 <__panic>

ffffffffc0203cb6 <default_free_pages>:
{
ffffffffc0203cb6:	1141                	addi	sp,sp,-16
ffffffffc0203cb8:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0203cba:	16058e63          	beqz	a1,ffffffffc0203e36 <default_free_pages+0x180>
    for (; p != base + n; p++)
ffffffffc0203cbe:	00659693          	slli	a3,a1,0x6
ffffffffc0203cc2:	96aa                	add	a3,a3,a0
ffffffffc0203cc4:	02d50d63          	beq	a0,a3,ffffffffc0203cfe <default_free_pages+0x48>
ffffffffc0203cc8:	651c                	ld	a5,8(a0)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0203cca:	8b85                	andi	a5,a5,1
ffffffffc0203ccc:	14079563          	bnez	a5,ffffffffc0203e16 <default_free_pages+0x160>
ffffffffc0203cd0:	651c                	ld	a5,8(a0)
ffffffffc0203cd2:	8385                	srli	a5,a5,0x1
ffffffffc0203cd4:	8b85                	andi	a5,a5,1
ffffffffc0203cd6:	14079063          	bnez	a5,ffffffffc0203e16 <default_free_pages+0x160>
ffffffffc0203cda:	87aa                	mv	a5,a0
ffffffffc0203cdc:	a809                	j	ffffffffc0203cee <default_free_pages+0x38>
ffffffffc0203cde:	6798                	ld	a4,8(a5)
ffffffffc0203ce0:	8b05                	andi	a4,a4,1
ffffffffc0203ce2:	12071a63          	bnez	a4,ffffffffc0203e16 <default_free_pages+0x160>
ffffffffc0203ce6:	6798                	ld	a4,8(a5)
ffffffffc0203ce8:	8b09                	andi	a4,a4,2
ffffffffc0203cea:	12071663          	bnez	a4,ffffffffc0203e16 <default_free_pages+0x160>
        p->flags = 0;
ffffffffc0203cee:	0007b423          	sd	zero,8(a5)
    page->ref = val;
ffffffffc0203cf2:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0203cf6:	04078793          	addi	a5,a5,64
ffffffffc0203cfa:	fed792e3          	bne	a5,a3,ffffffffc0203cde <default_free_pages+0x28>
    base->property = n;
ffffffffc0203cfe:	2581                	sext.w	a1,a1
ffffffffc0203d00:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0203d02:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0203d06:	4789                	li	a5,2
ffffffffc0203d08:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0203d0c:	00013697          	auipc	a3,0x13
ffffffffc0203d10:	8cc68693          	addi	a3,a3,-1844 # ffffffffc02165d8 <free_area>
ffffffffc0203d14:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0203d16:	669c                	ld	a5,8(a3)
ffffffffc0203d18:	9db9                	addw	a1,a1,a4
ffffffffc0203d1a:	00013717          	auipc	a4,0x13
ffffffffc0203d1e:	8cb72723          	sw	a1,-1842(a4) # ffffffffc02165e8 <free_area+0x10>
    if (list_empty(&free_list))
ffffffffc0203d22:	0cd78163          	beq	a5,a3,ffffffffc0203de4 <default_free_pages+0x12e>
            struct Page *page = le2page(le, page_link);
ffffffffc0203d26:	fe878713          	addi	a4,a5,-24
ffffffffc0203d2a:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list))
ffffffffc0203d2c:	4801                	li	a6,0
ffffffffc0203d2e:	01850613          	addi	a2,a0,24
            if (base < page)
ffffffffc0203d32:	00e56a63          	bltu	a0,a4,ffffffffc0203d46 <default_free_pages+0x90>
    return listelm->next;
ffffffffc0203d36:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0203d38:	04d70f63          	beq	a4,a3,ffffffffc0203d96 <default_free_pages+0xe0>
        while ((le = list_next(le)) != &free_list)
ffffffffc0203d3c:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0203d3e:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0203d42:	fee57ae3          	bgeu	a0,a4,ffffffffc0203d36 <default_free_pages+0x80>
ffffffffc0203d46:	00080663          	beqz	a6,ffffffffc0203d52 <default_free_pages+0x9c>
ffffffffc0203d4a:	00013817          	auipc	a6,0x13
ffffffffc0203d4e:	88b83723          	sd	a1,-1906(a6) # ffffffffc02165d8 <free_area>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0203d52:	638c                	ld	a1,0(a5)
    prev->next = next->prev = elm;
ffffffffc0203d54:	e390                	sd	a2,0(a5)
ffffffffc0203d56:	e590                	sd	a2,8(a1)
    elm->next = next;
ffffffffc0203d58:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0203d5a:	ed0c                	sd	a1,24(a0)
    if (le != &free_list)
ffffffffc0203d5c:	06d58a63          	beq	a1,a3,ffffffffc0203dd0 <default_free_pages+0x11a>
        if (p + p->property == base)
ffffffffc0203d60:	ff85a603          	lw	a2,-8(a1) # ff8 <BASE_ADDRESS-0xffffffffc01ff008>
        p = le2page(le, page_link);
ffffffffc0203d64:	fe858713          	addi	a4,a1,-24
        if (p + p->property == base)
ffffffffc0203d68:	02061793          	slli	a5,a2,0x20
ffffffffc0203d6c:	83e9                	srli	a5,a5,0x1a
ffffffffc0203d6e:	97ba                	add	a5,a5,a4
ffffffffc0203d70:	04f51b63          	bne	a0,a5,ffffffffc0203dc6 <default_free_pages+0x110>
            p->property += base->property;
ffffffffc0203d74:	491c                	lw	a5,16(a0)
ffffffffc0203d76:	9e3d                	addw	a2,a2,a5
ffffffffc0203d78:	fec5ac23          	sw	a2,-8(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0203d7c:	57f5                	li	a5,-3
ffffffffc0203d7e:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0203d82:	01853803          	ld	a6,24(a0)
ffffffffc0203d86:	7110                	ld	a2,32(a0)
            base = p;
ffffffffc0203d88:	853a                	mv	a0,a4
    prev->next = next;
ffffffffc0203d8a:	00c83423          	sd	a2,8(a6)
    next->prev = prev;
ffffffffc0203d8e:	659c                	ld	a5,8(a1)
ffffffffc0203d90:	01063023          	sd	a6,0(a2)
ffffffffc0203d94:	a815                	j	ffffffffc0203dc8 <default_free_pages+0x112>
    prev->next = next->prev = elm;
ffffffffc0203d96:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0203d98:	f114                	sd	a3,32(a0)
ffffffffc0203d9a:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0203d9c:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0203d9e:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list)
ffffffffc0203da0:	00d70563          	beq	a4,a3,ffffffffc0203daa <default_free_pages+0xf4>
ffffffffc0203da4:	4805                	li	a6,1
ffffffffc0203da6:	87ba                	mv	a5,a4
ffffffffc0203da8:	bf59                	j	ffffffffc0203d3e <default_free_pages+0x88>
ffffffffc0203daa:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc0203dac:	85be                	mv	a1,a5
    if (le != &free_list)
ffffffffc0203dae:	00d78d63          	beq	a5,a3,ffffffffc0203dc8 <default_free_pages+0x112>
        if (p + p->property == base)
ffffffffc0203db2:	ff85a603          	lw	a2,-8(a1)
        p = le2page(le, page_link);
ffffffffc0203db6:	fe858713          	addi	a4,a1,-24
        if (p + p->property == base)
ffffffffc0203dba:	02061793          	slli	a5,a2,0x20
ffffffffc0203dbe:	83e9                	srli	a5,a5,0x1a
ffffffffc0203dc0:	97ba                	add	a5,a5,a4
ffffffffc0203dc2:	faf509e3          	beq	a0,a5,ffffffffc0203d74 <default_free_pages+0xbe>
ffffffffc0203dc6:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc0203dc8:	fe878713          	addi	a4,a5,-24
ffffffffc0203dcc:	00d78963          	beq	a5,a3,ffffffffc0203dde <default_free_pages+0x128>
        if (base + base->property == p)
ffffffffc0203dd0:	4910                	lw	a2,16(a0)
ffffffffc0203dd2:	02061693          	slli	a3,a2,0x20
ffffffffc0203dd6:	82e9                	srli	a3,a3,0x1a
ffffffffc0203dd8:	96aa                	add	a3,a3,a0
ffffffffc0203dda:	00d70e63          	beq	a4,a3,ffffffffc0203df6 <default_free_pages+0x140>
}
ffffffffc0203dde:	60a2                	ld	ra,8(sp)
ffffffffc0203de0:	0141                	addi	sp,sp,16
ffffffffc0203de2:	8082                	ret
ffffffffc0203de4:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0203de6:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0203dea:	e398                	sd	a4,0(a5)
ffffffffc0203dec:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0203dee:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0203df0:	ed1c                	sd	a5,24(a0)
}
ffffffffc0203df2:	0141                	addi	sp,sp,16
ffffffffc0203df4:	8082                	ret
            base->property += p->property;
ffffffffc0203df6:	ff87a703          	lw	a4,-8(a5)
ffffffffc0203dfa:	ff078693          	addi	a3,a5,-16
ffffffffc0203dfe:	9e39                	addw	a2,a2,a4
ffffffffc0203e00:	c910                	sw	a2,16(a0)
ffffffffc0203e02:	5775                	li	a4,-3
ffffffffc0203e04:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0203e08:	6398                	ld	a4,0(a5)
ffffffffc0203e0a:	679c                	ld	a5,8(a5)
}
ffffffffc0203e0c:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0203e0e:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203e10:	e398                	sd	a4,0(a5)
ffffffffc0203e12:	0141                	addi	sp,sp,16
ffffffffc0203e14:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0203e16:	00003697          	auipc	a3,0x3
ffffffffc0203e1a:	ce268693          	addi	a3,a3,-798 # ffffffffc0206af8 <commands+0x1b00>
ffffffffc0203e1e:	00002617          	auipc	a2,0x2
ffffffffc0203e22:	b7260613          	addi	a2,a2,-1166 # ffffffffc0205990 <commands+0x998>
ffffffffc0203e26:	09f00593          	li	a1,159
ffffffffc0203e2a:	00003517          	auipc	a0,0x3
ffffffffc0203e2e:	9be50513          	addi	a0,a0,-1602 # ffffffffc02067e8 <commands+0x17f0>
ffffffffc0203e32:	ba2fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(n > 0);
ffffffffc0203e36:	00003697          	auipc	a3,0x3
ffffffffc0203e3a:	cea68693          	addi	a3,a3,-790 # ffffffffc0206b20 <commands+0x1b28>
ffffffffc0203e3e:	00002617          	auipc	a2,0x2
ffffffffc0203e42:	b5260613          	addi	a2,a2,-1198 # ffffffffc0205990 <commands+0x998>
ffffffffc0203e46:	09b00593          	li	a1,155
ffffffffc0203e4a:	00003517          	auipc	a0,0x3
ffffffffc0203e4e:	99e50513          	addi	a0,a0,-1634 # ffffffffc02067e8 <commands+0x17f0>
ffffffffc0203e52:	b82fc0ef          	jal	ra,ffffffffc02001d4 <__panic>

ffffffffc0203e56 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0203e56:	c959                	beqz	a0,ffffffffc0203eec <default_alloc_pages+0x96>
    if (n > nr_free)
ffffffffc0203e58:	00012597          	auipc	a1,0x12
ffffffffc0203e5c:	78058593          	addi	a1,a1,1920 # ffffffffc02165d8 <free_area>
ffffffffc0203e60:	0105a803          	lw	a6,16(a1)
ffffffffc0203e64:	862a                	mv	a2,a0
ffffffffc0203e66:	02081793          	slli	a5,a6,0x20
ffffffffc0203e6a:	9381                	srli	a5,a5,0x20
ffffffffc0203e6c:	00a7ee63          	bltu	a5,a0,ffffffffc0203e88 <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc0203e70:	87ae                	mv	a5,a1
ffffffffc0203e72:	a801                	j	ffffffffc0203e82 <default_alloc_pages+0x2c>
        if (p->property >= n)
ffffffffc0203e74:	ff87a703          	lw	a4,-8(a5)
ffffffffc0203e78:	02071693          	slli	a3,a4,0x20
ffffffffc0203e7c:	9281                	srli	a3,a3,0x20
ffffffffc0203e7e:	00c6f763          	bgeu	a3,a2,ffffffffc0203e8c <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0203e82:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc0203e84:	feb798e3          	bne	a5,a1,ffffffffc0203e74 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc0203e88:	4501                	li	a0,0
}
ffffffffc0203e8a:	8082                	ret
        struct Page *p = le2page(le, page_link);
ffffffffc0203e8c:	fe878513          	addi	a0,a5,-24
    if (page != NULL)
ffffffffc0203e90:	dd6d                	beqz	a0,ffffffffc0203e8a <default_alloc_pages+0x34>
    return listelm->prev;
ffffffffc0203e92:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0203e96:	0087b303          	ld	t1,8(a5)
    prev->next = next;
ffffffffc0203e9a:	00060e1b          	sext.w	t3,a2
ffffffffc0203e9e:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc0203ea2:	01133023          	sd	a7,0(t1)
        if (page->property > n)
ffffffffc0203ea6:	02d67863          	bgeu	a2,a3,ffffffffc0203ed6 <default_alloc_pages+0x80>
            struct Page *p = page + n;
ffffffffc0203eaa:	061a                	slli	a2,a2,0x6
ffffffffc0203eac:	962a                	add	a2,a2,a0
            p->property = page->property - n;
ffffffffc0203eae:	41c7073b          	subw	a4,a4,t3
ffffffffc0203eb2:	ca18                	sw	a4,16(a2)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0203eb4:	00860693          	addi	a3,a2,8
ffffffffc0203eb8:	4709                	li	a4,2
ffffffffc0203eba:	40e6b02f          	amoor.d	zero,a4,(a3)
    __list_add(elm, listelm, listelm->next);
ffffffffc0203ebe:	0088b703          	ld	a4,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc0203ec2:	01860693          	addi	a3,a2,24
    prev->next = next->prev = elm;
ffffffffc0203ec6:	0105a803          	lw	a6,16(a1)
ffffffffc0203eca:	e314                	sd	a3,0(a4)
ffffffffc0203ecc:	00d8b423          	sd	a3,8(a7)
    elm->next = next;
ffffffffc0203ed0:	f218                	sd	a4,32(a2)
    elm->prev = prev;
ffffffffc0203ed2:	01163c23          	sd	a7,24(a2)
        nr_free -= n;
ffffffffc0203ed6:	41c8083b          	subw	a6,a6,t3
ffffffffc0203eda:	00012717          	auipc	a4,0x12
ffffffffc0203ede:	71072723          	sw	a6,1806(a4) # ffffffffc02165e8 <free_area+0x10>
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0203ee2:	5775                	li	a4,-3
ffffffffc0203ee4:	17c1                	addi	a5,a5,-16
ffffffffc0203ee6:	60e7b02f          	amoand.d	zero,a4,(a5)
ffffffffc0203eea:	8082                	ret
{
ffffffffc0203eec:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0203eee:	00003697          	auipc	a3,0x3
ffffffffc0203ef2:	c3268693          	addi	a3,a3,-974 # ffffffffc0206b20 <commands+0x1b28>
ffffffffc0203ef6:	00002617          	auipc	a2,0x2
ffffffffc0203efa:	a9a60613          	addi	a2,a2,-1382 # ffffffffc0205990 <commands+0x998>
ffffffffc0203efe:	07700593          	li	a1,119
ffffffffc0203f02:	00003517          	auipc	a0,0x3
ffffffffc0203f06:	8e650513          	addi	a0,a0,-1818 # ffffffffc02067e8 <commands+0x17f0>
{
ffffffffc0203f0a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0203f0c:	ac8fc0ef          	jal	ra,ffffffffc02001d4 <__panic>

ffffffffc0203f10 <default_init_memmap>:
{
ffffffffc0203f10:	7179                	addi	sp,sp,-48
ffffffffc0203f12:	f406                	sd	ra,40(sp)
ffffffffc0203f14:	f022                	sd	s0,32(sp)
ffffffffc0203f16:	ec26                	sd	s1,24(sp)
ffffffffc0203f18:	e84a                	sd	s2,16(sp)
ffffffffc0203f1a:	e44e                	sd	s3,8(sp)
ffffffffc0203f1c:	e052                	sd	s4,0(sp)
    assert(n > 0);
ffffffffc0203f1e:	12058363          	beqz	a1,ffffffffc0204044 <default_init_memmap+0x134>
ffffffffc0203f22:	892e                	mv	s2,a1
ffffffffc0203f24:	842a                	mv	s0,a0
    for (; p != base + 3; p++)
ffffffffc0203f26:	0c050a13          	addi	s4,a0,192
ffffffffc0203f2a:	84aa                	mv	s1,a0
        cprintf("p的虚拟地址: 0x%016lx.\n", (uintptr_t)p);
ffffffffc0203f2c:	00003997          	auipc	s3,0x3
ffffffffc0203f30:	bfc98993          	addi	s3,s3,-1028 # ffffffffc0206b28 <commands+0x1b30>
ffffffffc0203f34:	85a6                	mv	a1,s1
ffffffffc0203f36:	854e                	mv	a0,s3
    for (; p != base + 3; p++)
ffffffffc0203f38:	04048493          	addi	s1,s1,64
        cprintf("p的虚拟地址: 0x%016lx.\n", (uintptr_t)p);
ffffffffc0203f3c:	994fc0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    for (; p != base + 3; p++)
ffffffffc0203f40:	ff449ae3          	bne	s1,s4,ffffffffc0203f34 <default_init_memmap+0x24>
    for (; p != base + n; p++)
ffffffffc0203f44:	00691693          	slli	a3,s2,0x6
ffffffffc0203f48:	96a2                	add	a3,a3,s0
ffffffffc0203f4a:	02d40463          	beq	s0,a3,ffffffffc0203f72 <default_init_memmap+0x62>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0203f4e:	6418                	ld	a4,8(s0)
        assert(PageReserved(p));
ffffffffc0203f50:	87a2                	mv	a5,s0
ffffffffc0203f52:	8b05                	andi	a4,a4,1
ffffffffc0203f54:	e709                	bnez	a4,ffffffffc0203f5e <default_init_memmap+0x4e>
ffffffffc0203f56:	a0f9                	j	ffffffffc0204024 <default_init_memmap+0x114>
ffffffffc0203f58:	6798                	ld	a4,8(a5)
ffffffffc0203f5a:	8b05                	andi	a4,a4,1
ffffffffc0203f5c:	c761                	beqz	a4,ffffffffc0204024 <default_init_memmap+0x114>
        p->flags = p->property = 0;
ffffffffc0203f5e:	0007a823          	sw	zero,16(a5)
ffffffffc0203f62:	0007b423          	sd	zero,8(a5)
ffffffffc0203f66:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0203f6a:	04078793          	addi	a5,a5,64
ffffffffc0203f6e:	fed795e3          	bne	a5,a3,ffffffffc0203f58 <default_init_memmap+0x48>
    base->property = n;
ffffffffc0203f72:	2901                	sext.w	s2,s2
ffffffffc0203f74:	01242823          	sw	s2,16(s0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0203f78:	4789                	li	a5,2
ffffffffc0203f7a:	00840713          	addi	a4,s0,8
ffffffffc0203f7e:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0203f82:	00012697          	auipc	a3,0x12
ffffffffc0203f86:	65668693          	addi	a3,a3,1622 # ffffffffc02165d8 <free_area>
ffffffffc0203f8a:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0203f8c:	669c                	ld	a5,8(a3)
ffffffffc0203f8e:	0127093b          	addw	s2,a4,s2
ffffffffc0203f92:	00012717          	auipc	a4,0x12
ffffffffc0203f96:	65272b23          	sw	s2,1622(a4) # ffffffffc02165e8 <free_area+0x10>
    if (list_empty(&free_list))
ffffffffc0203f9a:	04d78e63          	beq	a5,a3,ffffffffc0203ff6 <default_init_memmap+0xe6>
            struct Page *page = le2page(le, page_link);
ffffffffc0203f9e:	fe878713          	addi	a4,a5,-24
ffffffffc0203fa2:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list))
ffffffffc0203fa4:	4501                	li	a0,0
ffffffffc0203fa6:	01840613          	addi	a2,s0,24
            if (base < page)
ffffffffc0203faa:	00e46a63          	bltu	s0,a4,ffffffffc0203fbe <default_init_memmap+0xae>
    return listelm->next;
ffffffffc0203fae:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0203fb0:	02d70963          	beq	a4,a3,ffffffffc0203fe2 <default_init_memmap+0xd2>
        while ((le = list_next(le)) != &free_list)
ffffffffc0203fb4:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0203fb6:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0203fba:	fee47ae3          	bgeu	s0,a4,ffffffffc0203fae <default_init_memmap+0x9e>
ffffffffc0203fbe:	c509                	beqz	a0,ffffffffc0203fc8 <default_init_memmap+0xb8>
ffffffffc0203fc0:	00012717          	auipc	a4,0x12
ffffffffc0203fc4:	60b73c23          	sd	a1,1560(a4) # ffffffffc02165d8 <free_area>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0203fc8:	6398                	ld	a4,0(a5)
    prev->next = next->prev = elm;
ffffffffc0203fca:	e390                	sd	a2,0(a5)
}
ffffffffc0203fcc:	70a2                	ld	ra,40(sp)
ffffffffc0203fce:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0203fd0:	f01c                	sd	a5,32(s0)
    elm->prev = prev;
ffffffffc0203fd2:	ec18                	sd	a4,24(s0)
ffffffffc0203fd4:	7402                	ld	s0,32(sp)
ffffffffc0203fd6:	64e2                	ld	s1,24(sp)
ffffffffc0203fd8:	6942                	ld	s2,16(sp)
ffffffffc0203fda:	69a2                	ld	s3,8(sp)
ffffffffc0203fdc:	6a02                	ld	s4,0(sp)
ffffffffc0203fde:	6145                	addi	sp,sp,48
ffffffffc0203fe0:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0203fe2:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0203fe4:	f014                	sd	a3,32(s0)
ffffffffc0203fe6:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0203fe8:	ec1c                	sd	a5,24(s0)
                list_add(le, &(base->page_link));
ffffffffc0203fea:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list)
ffffffffc0203fec:	02d70363          	beq	a4,a3,ffffffffc0204012 <default_init_memmap+0x102>
ffffffffc0203ff0:	4505                	li	a0,1
ffffffffc0203ff2:	87ba                	mv	a5,a4
ffffffffc0203ff4:	b7c9                	j	ffffffffc0203fb6 <default_init_memmap+0xa6>
        list_add(&free_list, &(base->page_link));
ffffffffc0203ff6:	01840713          	addi	a4,s0,24
    elm->next = next;
ffffffffc0203ffa:	f01c                	sd	a5,32(s0)
    elm->prev = prev;
ffffffffc0203ffc:	ec1c                	sd	a5,24(s0)
}
ffffffffc0203ffe:	70a2                	ld	ra,40(sp)
ffffffffc0204000:	7402                	ld	s0,32(sp)
    prev->next = next->prev = elm;
ffffffffc0204002:	e398                	sd	a4,0(a5)
ffffffffc0204004:	e798                	sd	a4,8(a5)
ffffffffc0204006:	64e2                	ld	s1,24(sp)
ffffffffc0204008:	6942                	ld	s2,16(sp)
ffffffffc020400a:	69a2                	ld	s3,8(sp)
ffffffffc020400c:	6a02                	ld	s4,0(sp)
ffffffffc020400e:	6145                	addi	sp,sp,48
ffffffffc0204010:	8082                	ret
ffffffffc0204012:	70a2                	ld	ra,40(sp)
ffffffffc0204014:	7402                	ld	s0,32(sp)
ffffffffc0204016:	e290                	sd	a2,0(a3)
ffffffffc0204018:	64e2                	ld	s1,24(sp)
ffffffffc020401a:	6942                	ld	s2,16(sp)
ffffffffc020401c:	69a2                	ld	s3,8(sp)
ffffffffc020401e:	6a02                	ld	s4,0(sp)
ffffffffc0204020:	6145                	addi	sp,sp,48
ffffffffc0204022:	8082                	ret
        assert(PageReserved(p));
ffffffffc0204024:	00003697          	auipc	a3,0x3
ffffffffc0204028:	b2468693          	addi	a3,a3,-1244 # ffffffffc0206b48 <commands+0x1b50>
ffffffffc020402c:	00002617          	auipc	a2,0x2
ffffffffc0204030:	96460613          	addi	a2,a2,-1692 # ffffffffc0205990 <commands+0x998>
ffffffffc0204034:	05600593          	li	a1,86
ffffffffc0204038:	00002517          	auipc	a0,0x2
ffffffffc020403c:	7b050513          	addi	a0,a0,1968 # ffffffffc02067e8 <commands+0x17f0>
ffffffffc0204040:	994fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(n > 0);
ffffffffc0204044:	00003697          	auipc	a3,0x3
ffffffffc0204048:	adc68693          	addi	a3,a3,-1316 # ffffffffc0206b20 <commands+0x1b28>
ffffffffc020404c:	00002617          	auipc	a2,0x2
ffffffffc0204050:	94460613          	addi	a2,a2,-1724 # ffffffffc0205990 <commands+0x998>
ffffffffc0204054:	04900593          	li	a1,73
ffffffffc0204058:	00002517          	auipc	a0,0x2
ffffffffc020405c:	79050513          	addi	a0,a0,1936 # ffffffffc02067e8 <commands+0x17f0>
ffffffffc0204060:	974fc0ef          	jal	ra,ffffffffc02001d4 <__panic>

ffffffffc0204064 <swapfs_init>:
#include <ide.h>
#include <pmm.h>
#include <assert.h>

void
swapfs_init(void) {
ffffffffc0204064:	1141                	addi	sp,sp,-16
    static_assert((PGSIZE % SECTSIZE) == 0);
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0204066:	4505                	li	a0,1
swapfs_init(void) {
ffffffffc0204068:	e406                	sd	ra,8(sp)
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc020406a:	c44fc0ef          	jal	ra,ffffffffc02004ae <ide_device_valid>
ffffffffc020406e:	cd01                	beqz	a0,ffffffffc0204086 <swapfs_init+0x22>
        panic("swap fs isn't available.\n");
    }
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0204070:	4505                	li	a0,1
ffffffffc0204072:	c42fc0ef          	jal	ra,ffffffffc02004b4 <ide_device_size>
}
ffffffffc0204076:	60a2                	ld	ra,8(sp)
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0204078:	810d                	srli	a0,a0,0x3
ffffffffc020407a:	00012797          	auipc	a5,0x12
ffffffffc020407e:	50a7bf23          	sd	a0,1310(a5) # ffffffffc0216598 <max_swap_offset>
}
ffffffffc0204082:	0141                	addi	sp,sp,16
ffffffffc0204084:	8082                	ret
        panic("swap fs isn't available.\n");
ffffffffc0204086:	00003617          	auipc	a2,0x3
ffffffffc020408a:	b2260613          	addi	a2,a2,-1246 # ffffffffc0206ba8 <default_pmm_manager+0x50>
ffffffffc020408e:	45b5                	li	a1,13
ffffffffc0204090:	00003517          	auipc	a0,0x3
ffffffffc0204094:	b3850513          	addi	a0,a0,-1224 # ffffffffc0206bc8 <default_pmm_manager+0x70>
ffffffffc0204098:	93cfc0ef          	jal	ra,ffffffffc02001d4 <__panic>

ffffffffc020409c <swapfs_read>:

int
swapfs_read(swap_entry_t entry, struct Page *page) {
ffffffffc020409c:	1141                	addi	sp,sp,-16
ffffffffc020409e:	e406                	sd	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc02040a0:	00855793          	srli	a5,a0,0x8
ffffffffc02040a4:	cfb9                	beqz	a5,ffffffffc0204102 <swapfs_read+0x66>
ffffffffc02040a6:	00012717          	auipc	a4,0x12
ffffffffc02040aa:	4f270713          	addi	a4,a4,1266 # ffffffffc0216598 <max_swap_offset>
ffffffffc02040ae:	6318                	ld	a4,0(a4)
ffffffffc02040b0:	04e7f963          	bgeu	a5,a4,ffffffffc0204102 <swapfs_read+0x66>
    return page - pages + nbase;
ffffffffc02040b4:	00012717          	auipc	a4,0x12
ffffffffc02040b8:	43c70713          	addi	a4,a4,1084 # ffffffffc02164f0 <pages>
ffffffffc02040bc:	6310                	ld	a2,0(a4)
ffffffffc02040be:	00003717          	auipc	a4,0x3
ffffffffc02040c2:	f6270713          	addi	a4,a4,-158 # ffffffffc0207020 <nbase>
ffffffffc02040c6:	40c58633          	sub	a2,a1,a2
ffffffffc02040ca:	630c                	ld	a1,0(a4)
ffffffffc02040cc:	8619                	srai	a2,a2,0x6
    return KADDR(page2pa(page));
ffffffffc02040ce:	00012717          	auipc	a4,0x12
ffffffffc02040d2:	3ba70713          	addi	a4,a4,954 # ffffffffc0216488 <npage>
    return page - pages + nbase;
ffffffffc02040d6:	962e                	add	a2,a2,a1
    return KADDR(page2pa(page));
ffffffffc02040d8:	6314                	ld	a3,0(a4)
ffffffffc02040da:	00c61713          	slli	a4,a2,0xc
ffffffffc02040de:	8331                	srli	a4,a4,0xc
ffffffffc02040e0:	0037959b          	slliw	a1,a5,0x3
    return page2ppn(page) << PGSHIFT;
ffffffffc02040e4:	0632                	slli	a2,a2,0xc
    return KADDR(page2pa(page));
ffffffffc02040e6:	02d77a63          	bgeu	a4,a3,ffffffffc020411a <swapfs_read+0x7e>
ffffffffc02040ea:	00012797          	auipc	a5,0x12
ffffffffc02040ee:	3f678793          	addi	a5,a5,1014 # ffffffffc02164e0 <va_pa_offset>
ffffffffc02040f2:	639c                	ld	a5,0(a5)
}
ffffffffc02040f4:	60a2                	ld	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc02040f6:	46a1                	li	a3,8
ffffffffc02040f8:	963e                	add	a2,a2,a5
ffffffffc02040fa:	4505                	li	a0,1
}
ffffffffc02040fc:	0141                	addi	sp,sp,16
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc02040fe:	bbcfc06f          	j	ffffffffc02004ba <ide_read_secs>
ffffffffc0204102:	86aa                	mv	a3,a0
ffffffffc0204104:	00003617          	auipc	a2,0x3
ffffffffc0204108:	adc60613          	addi	a2,a2,-1316 # ffffffffc0206be0 <default_pmm_manager+0x88>
ffffffffc020410c:	45d1                	li	a1,20
ffffffffc020410e:	00003517          	auipc	a0,0x3
ffffffffc0204112:	aba50513          	addi	a0,a0,-1350 # ffffffffc0206bc8 <default_pmm_manager+0x70>
ffffffffc0204116:	8befc0ef          	jal	ra,ffffffffc02001d4 <__panic>
ffffffffc020411a:	86b2                	mv	a3,a2
ffffffffc020411c:	06900593          	li	a1,105
ffffffffc0204120:	00001617          	auipc	a2,0x1
ffffffffc0204124:	71860613          	addi	a2,a2,1816 # ffffffffc0205838 <commands+0x840>
ffffffffc0204128:	00001517          	auipc	a0,0x1
ffffffffc020412c:	76850513          	addi	a0,a0,1896 # ffffffffc0205890 <commands+0x898>
ffffffffc0204130:	8a4fc0ef          	jal	ra,ffffffffc02001d4 <__panic>

ffffffffc0204134 <swapfs_write>:

int
swapfs_write(swap_entry_t entry, struct Page *page) {
ffffffffc0204134:	1141                	addi	sp,sp,-16
ffffffffc0204136:	e406                	sd	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204138:	00855793          	srli	a5,a0,0x8
ffffffffc020413c:	cfb9                	beqz	a5,ffffffffc020419a <swapfs_write+0x66>
ffffffffc020413e:	00012717          	auipc	a4,0x12
ffffffffc0204142:	45a70713          	addi	a4,a4,1114 # ffffffffc0216598 <max_swap_offset>
ffffffffc0204146:	6318                	ld	a4,0(a4)
ffffffffc0204148:	04e7f963          	bgeu	a5,a4,ffffffffc020419a <swapfs_write+0x66>
    return page - pages + nbase;
ffffffffc020414c:	00012717          	auipc	a4,0x12
ffffffffc0204150:	3a470713          	addi	a4,a4,932 # ffffffffc02164f0 <pages>
ffffffffc0204154:	6310                	ld	a2,0(a4)
ffffffffc0204156:	00003717          	auipc	a4,0x3
ffffffffc020415a:	eca70713          	addi	a4,a4,-310 # ffffffffc0207020 <nbase>
ffffffffc020415e:	40c58633          	sub	a2,a1,a2
ffffffffc0204162:	630c                	ld	a1,0(a4)
ffffffffc0204164:	8619                	srai	a2,a2,0x6
    return KADDR(page2pa(page));
ffffffffc0204166:	00012717          	auipc	a4,0x12
ffffffffc020416a:	32270713          	addi	a4,a4,802 # ffffffffc0216488 <npage>
    return page - pages + nbase;
ffffffffc020416e:	962e                	add	a2,a2,a1
    return KADDR(page2pa(page));
ffffffffc0204170:	6314                	ld	a3,0(a4)
ffffffffc0204172:	00c61713          	slli	a4,a2,0xc
ffffffffc0204176:	8331                	srli	a4,a4,0xc
ffffffffc0204178:	0037959b          	slliw	a1,a5,0x3
    return page2ppn(page) << PGSHIFT;
ffffffffc020417c:	0632                	slli	a2,a2,0xc
    return KADDR(page2pa(page));
ffffffffc020417e:	02d77a63          	bgeu	a4,a3,ffffffffc02041b2 <swapfs_write+0x7e>
ffffffffc0204182:	00012797          	auipc	a5,0x12
ffffffffc0204186:	35e78793          	addi	a5,a5,862 # ffffffffc02164e0 <va_pa_offset>
ffffffffc020418a:	639c                	ld	a5,0(a5)
}
ffffffffc020418c:	60a2                	ld	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc020418e:	46a1                	li	a3,8
ffffffffc0204190:	963e                	add	a2,a2,a5
ffffffffc0204192:	4505                	li	a0,1
}
ffffffffc0204194:	0141                	addi	sp,sp,16
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204196:	b48fc06f          	j	ffffffffc02004de <ide_write_secs>
ffffffffc020419a:	86aa                	mv	a3,a0
ffffffffc020419c:	00003617          	auipc	a2,0x3
ffffffffc02041a0:	a4460613          	addi	a2,a2,-1468 # ffffffffc0206be0 <default_pmm_manager+0x88>
ffffffffc02041a4:	45e5                	li	a1,25
ffffffffc02041a6:	00003517          	auipc	a0,0x3
ffffffffc02041aa:	a2250513          	addi	a0,a0,-1502 # ffffffffc0206bc8 <default_pmm_manager+0x70>
ffffffffc02041ae:	826fc0ef          	jal	ra,ffffffffc02001d4 <__panic>
ffffffffc02041b2:	86b2                	mv	a3,a2
ffffffffc02041b4:	06900593          	li	a1,105
ffffffffc02041b8:	00001617          	auipc	a2,0x1
ffffffffc02041bc:	68060613          	addi	a2,a2,1664 # ffffffffc0205838 <commands+0x840>
ffffffffc02041c0:	00001517          	auipc	a0,0x1
ffffffffc02041c4:	6d050513          	addi	a0,a0,1744 # ffffffffc0205890 <commands+0x898>
ffffffffc02041c8:	80cfc0ef          	jal	ra,ffffffffc02001d4 <__panic>

ffffffffc02041cc <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc02041cc:	8526                	mv	a0,s1
	jalr s0
ffffffffc02041ce:	9402                	jalr	s0

	jal do_exit
ffffffffc02041d0:	4e6000ef          	jal	ra,ffffffffc02046b6 <do_exit>

ffffffffc02041d4 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc02041d4:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc02041d8:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc02041dc:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc02041de:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc02041e0:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc02041e4:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc02041e8:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc02041ec:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc02041f0:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc02041f4:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc02041f8:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc02041fc:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc0204200:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0204204:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0204208:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc020420c:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc0204210:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0204212:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0204214:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0204218:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc020421c:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc0204220:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0204224:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0204228:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc020422c:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc0204230:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc0204234:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0204238:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc020423c:	8082                	ret

ffffffffc020423e <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - 分配一个proc_struct并初始化proc_struct的所有字段
static struct proc_struct *
alloc_proc(void)
{
ffffffffc020423e:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0204240:	0e800513          	li	a0,232
{
ffffffffc0204244:	e022                	sd	s0,0(sp)
ffffffffc0204246:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0204248:	f7efe0ef          	jal	ra,ffffffffc02029c6 <kmalloc>
ffffffffc020424c:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc020424e:	c529                	beqz	a0,ffffffffc0204298 <alloc_proc+0x5a>
         *       struct trapframe *tf;                       // 当前中断的陷阱帧
         *       uintptr_t cr3;                              // CR3寄存器：页目录表（PDT）的基地址
         *       uint32_t flags;                             // 进程标志
         *       char name[PROC_NAME_LEN + 1];               // 进程名称
         */
        proc->cr3 = boot_cr3;
ffffffffc0204250:	00012797          	auipc	a5,0x12
ffffffffc0204254:	29878793          	addi	a5,a5,664 # ffffffffc02164e8 <boot_cr3>
ffffffffc0204258:	639c                	ld	a5,0(a5)
        proc->tf = NULL;
        memset(&(proc->context), 0, sizeof(struct context));
ffffffffc020425a:	07000613          	li	a2,112
ffffffffc020425e:	4581                	li	a1,0
        proc->cr3 = boot_cr3;
ffffffffc0204260:	f55c                	sd	a5,168(a0)
        proc->tf = NULL;
ffffffffc0204262:	0a053023          	sd	zero,160(a0)
        memset(&(proc->context), 0, sizeof(struct context));
ffffffffc0204266:	03050513          	addi	a0,a0,48
ffffffffc020426a:	7e0000ef          	jal	ra,ffffffffc0204a4a <memset>
        proc->state = PROC_UNINIT;
ffffffffc020426e:	57fd                	li	a5,-1
ffffffffc0204270:	1782                	slli	a5,a5,0x20
ffffffffc0204272:	e01c                	sd	a5,0(s0)
        proc->pid = -1;
        proc->runs = 0;
ffffffffc0204274:	00042423          	sw	zero,8(s0)
        proc->kstack = 0;
ffffffffc0204278:	00043823          	sd	zero,16(s0)
        proc->need_resched = 0;
ffffffffc020427c:	00042c23          	sw	zero,24(s0)
        proc->parent = NULL;
ffffffffc0204280:	02043023          	sd	zero,32(s0)
        proc->mm = NULL;
ffffffffc0204284:	02043423          	sd	zero,40(s0)
        proc->flags = 0;
ffffffffc0204288:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, sizeof(proc->name));
ffffffffc020428c:	4641                	li	a2,16
ffffffffc020428e:	4581                	li	a1,0
ffffffffc0204290:	0b440513          	addi	a0,s0,180
ffffffffc0204294:	7b6000ef          	jal	ra,ffffffffc0204a4a <memset>
    }
    return proc;
}
ffffffffc0204298:	8522                	mv	a0,s0
ffffffffc020429a:	60a2                	ld	ra,8(sp)
ffffffffc020429c:	6402                	ld	s0,0(sp)
ffffffffc020429e:	0141                	addi	sp,sp,16
ffffffffc02042a0:	8082                	ret

ffffffffc02042a2 <forkret>:
// 注意：forkret的地址在copy_thread函数中设置
//       在switch_to之后，当前进程将在此处执行。
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc02042a2:	00012797          	auipc	a5,0x12
ffffffffc02042a6:	20e78793          	addi	a5,a5,526 # ffffffffc02164b0 <current>
ffffffffc02042aa:	639c                	ld	a5,0(a5)
ffffffffc02042ac:	73c8                	ld	a0,160(a5)
ffffffffc02042ae:	8d7fc06f          	j	ffffffffc0200b84 <forkrets>

ffffffffc02042b2 <set_proc_name>:
{
ffffffffc02042b2:	1101                	addi	sp,sp,-32
ffffffffc02042b4:	e822                	sd	s0,16(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02042b6:	0b450413          	addi	s0,a0,180
{
ffffffffc02042ba:	e426                	sd	s1,8(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02042bc:	4641                	li	a2,16
{
ffffffffc02042be:	84ae                	mv	s1,a1
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02042c0:	8522                	mv	a0,s0
ffffffffc02042c2:	4581                	li	a1,0
{
ffffffffc02042c4:	ec06                	sd	ra,24(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02042c6:	784000ef          	jal	ra,ffffffffc0204a4a <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc02042ca:	8522                	mv	a0,s0
}
ffffffffc02042cc:	6442                	ld	s0,16(sp)
ffffffffc02042ce:	60e2                	ld	ra,24(sp)
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc02042d0:	85a6                	mv	a1,s1
}
ffffffffc02042d2:	64a2                	ld	s1,8(sp)
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc02042d4:	463d                	li	a2,15
}
ffffffffc02042d6:	6105                	addi	sp,sp,32
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc02042d8:	7840006f          	j	ffffffffc0204a5c <memcpy>

ffffffffc02042dc <get_proc_name>:
{
ffffffffc02042dc:	1101                	addi	sp,sp,-32
ffffffffc02042de:	e822                	sd	s0,16(sp)
    memset(name, 0, sizeof(name));
ffffffffc02042e0:	00012417          	auipc	s0,0x12
ffffffffc02042e4:	18040413          	addi	s0,s0,384 # ffffffffc0216460 <name.1565>
{
ffffffffc02042e8:	e426                	sd	s1,8(sp)
    memset(name, 0, sizeof(name));
ffffffffc02042ea:	4641                	li	a2,16
{
ffffffffc02042ec:	84aa                	mv	s1,a0
    memset(name, 0, sizeof(name));
ffffffffc02042ee:	4581                	li	a1,0
ffffffffc02042f0:	8522                	mv	a0,s0
{
ffffffffc02042f2:	ec06                	sd	ra,24(sp)
    memset(name, 0, sizeof(name));
ffffffffc02042f4:	756000ef          	jal	ra,ffffffffc0204a4a <memset>
    return memcpy(name, proc->name, PROC_NAME_LEN);
ffffffffc02042f8:	8522                	mv	a0,s0
}
ffffffffc02042fa:	6442                	ld	s0,16(sp)
ffffffffc02042fc:	60e2                	ld	ra,24(sp)
    return memcpy(name, proc->name, PROC_NAME_LEN);
ffffffffc02042fe:	0b448593          	addi	a1,s1,180
}
ffffffffc0204302:	64a2                	ld	s1,8(sp)
    return memcpy(name, proc->name, PROC_NAME_LEN);
ffffffffc0204304:	463d                	li	a2,15
}
ffffffffc0204306:	6105                	addi	sp,sp,32
    return memcpy(name, proc->name, PROC_NAME_LEN);
ffffffffc0204308:	af91                	j	ffffffffc0204a5c <memcpy>

ffffffffc020430a <init_main>:

// init_main - 第二个内核线程，用于创建user_main内核线程
static int
init_main(void *arg)
{
    cprintf("这是initproc, pid = %d, 名称 = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc020430a:	00012797          	auipc	a5,0x12
ffffffffc020430e:	1a678793          	addi	a5,a5,422 # ffffffffc02164b0 <current>
ffffffffc0204312:	639c                	ld	a5,0(a5)
{
ffffffffc0204314:	1101                	addi	sp,sp,-32
ffffffffc0204316:	e426                	sd	s1,8(sp)
    cprintf("这是initproc, pid = %d, 名称 = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc0204318:	43c4                	lw	s1,4(a5)
{
ffffffffc020431a:	e822                	sd	s0,16(sp)
ffffffffc020431c:	842a                	mv	s0,a0
    cprintf("这是initproc, pid = %d, 名称 = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc020431e:	853e                	mv	a0,a5
{
ffffffffc0204320:	ec06                	sd	ra,24(sp)
    cprintf("这是initproc, pid = %d, 名称 = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc0204322:	fbbff0ef          	jal	ra,ffffffffc02042dc <get_proc_name>
ffffffffc0204326:	862a                	mv	a2,a0
ffffffffc0204328:	85a6                	mv	a1,s1
ffffffffc020432a:	00003517          	auipc	a0,0x3
ffffffffc020432e:	92e50513          	addi	a0,a0,-1746 # ffffffffc0206c58 <default_pmm_manager+0x100>
ffffffffc0204332:	d9ffb0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("To U: \"%s\".\n", (const char *)arg);
ffffffffc0204336:	85a2                	mv	a1,s0
ffffffffc0204338:	00003517          	auipc	a0,0x3
ffffffffc020433c:	95050513          	addi	a0,a0,-1712 # ffffffffc0206c88 <default_pmm_manager+0x130>
ffffffffc0204340:	d91fb0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("To U: \"嗯.., 再见, 再见. :)\"\n");
ffffffffc0204344:	00003517          	auipc	a0,0x3
ffffffffc0204348:	95450513          	addi	a0,a0,-1708 # ffffffffc0206c98 <default_pmm_manager+0x140>
ffffffffc020434c:	d85fb0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    return 0;
}
ffffffffc0204350:	60e2                	ld	ra,24(sp)
ffffffffc0204352:	6442                	ld	s0,16(sp)
ffffffffc0204354:	64a2                	ld	s1,8(sp)
ffffffffc0204356:	4501                	li	a0,0
ffffffffc0204358:	6105                	addi	sp,sp,32
ffffffffc020435a:	8082                	ret

ffffffffc020435c <proc_run>:
{
ffffffffc020435c:	1101                	addi	sp,sp,-32
    if (proc != current)
ffffffffc020435e:	00012797          	auipc	a5,0x12
ffffffffc0204362:	15278793          	addi	a5,a5,338 # ffffffffc02164b0 <current>
{
ffffffffc0204366:	e426                	sd	s1,8(sp)
    if (proc != current)
ffffffffc0204368:	6384                	ld	s1,0(a5)
{
ffffffffc020436a:	ec06                	sd	ra,24(sp)
ffffffffc020436c:	e822                	sd	s0,16(sp)
ffffffffc020436e:	e04a                	sd	s2,0(sp)
    if (proc != current)
ffffffffc0204370:	02a48c63          	beq	s1,a0,ffffffffc02043a8 <proc_run+0x4c>
ffffffffc0204374:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204376:	100027f3          	csrr	a5,sstatus
ffffffffc020437a:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020437c:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020437e:	e3b1                	bnez	a5,ffffffffc02043c2 <proc_run+0x66>
            lcr3(proc->cr3);
ffffffffc0204380:	745c                	ld	a5,168(s0)
            current = proc;
ffffffffc0204382:	00012717          	auipc	a4,0x12
ffffffffc0204386:	12873723          	sd	s0,302(a4) # ffffffffc02164b0 <current>

#define barrier() __asm__ __volatile__ ("fence" ::: "memory")

static inline void
lcr3(unsigned int cr3) {
    write_csr(sptbr, SATP32_MODE | (cr3 >> RISCV_PGSHIFT));
ffffffffc020438a:	80000737          	lui	a4,0x80000
ffffffffc020438e:	00c7d79b          	srliw	a5,a5,0xc
ffffffffc0204392:	8fd9                	or	a5,a5,a4
ffffffffc0204394:	18079073          	csrw	satp,a5
            switch_to(&(prev->context), &(next->context));
ffffffffc0204398:	03040593          	addi	a1,s0,48
ffffffffc020439c:	03048513          	addi	a0,s1,48
ffffffffc02043a0:	e35ff0ef          	jal	ra,ffffffffc02041d4 <switch_to>
    if (flag) {
ffffffffc02043a4:	00091863          	bnez	s2,ffffffffc02043b4 <proc_run+0x58>
}
ffffffffc02043a8:	60e2                	ld	ra,24(sp)
ffffffffc02043aa:	6442                	ld	s0,16(sp)
ffffffffc02043ac:	64a2                	ld	s1,8(sp)
ffffffffc02043ae:	6902                	ld	s2,0(sp)
ffffffffc02043b0:	6105                	addi	sp,sp,32
ffffffffc02043b2:	8082                	ret
ffffffffc02043b4:	6442                	ld	s0,16(sp)
ffffffffc02043b6:	60e2                	ld	ra,24(sp)
ffffffffc02043b8:	64a2                	ld	s1,8(sp)
ffffffffc02043ba:	6902                	ld	s2,0(sp)
ffffffffc02043bc:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02043be:	a0efc06f          	j	ffffffffc02005cc <intr_enable>
        intr_disable();
ffffffffc02043c2:	a10fc0ef          	jal	ra,ffffffffc02005d2 <intr_disable>
        return 1;
ffffffffc02043c6:	4905                	li	s2,1
ffffffffc02043c8:	bf65                	j	ffffffffc0204380 <proc_run+0x24>

ffffffffc02043ca <find_proc>:
    if (0 < pid && pid < MAX_PID)
ffffffffc02043ca:	0005071b          	sext.w	a4,a0
ffffffffc02043ce:	6789                	lui	a5,0x2
ffffffffc02043d0:	fff7069b          	addiw	a3,a4,-1
ffffffffc02043d4:	17f9                	addi	a5,a5,-2
ffffffffc02043d6:	04d7e063          	bltu	a5,a3,ffffffffc0204416 <find_proc+0x4c>
{
ffffffffc02043da:	1141                	addi	sp,sp,-16
ffffffffc02043dc:	e022                	sd	s0,0(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc02043de:	45a9                	li	a1,10
ffffffffc02043e0:	842a                	mv	s0,a0
ffffffffc02043e2:	853a                	mv	a0,a4
{
ffffffffc02043e4:	e406                	sd	ra,8(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc02043e6:	2ab000ef          	jal	ra,ffffffffc0204e90 <hash32>
ffffffffc02043ea:	02051693          	slli	a3,a0,0x20
ffffffffc02043ee:	82f1                	srli	a3,a3,0x1c
ffffffffc02043f0:	0000e517          	auipc	a0,0xe
ffffffffc02043f4:	07050513          	addi	a0,a0,112 # ffffffffc0212460 <hash_list>
ffffffffc02043f8:	96aa                	add	a3,a3,a0
ffffffffc02043fa:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc02043fc:	a029                	j	ffffffffc0204406 <find_proc+0x3c>
            if (proc->pid == pid)
ffffffffc02043fe:	f2c7a703          	lw	a4,-212(a5) # 1f2c <BASE_ADDRESS-0xffffffffc01fe0d4>
ffffffffc0204402:	00870c63          	beq	a4,s0,ffffffffc020441a <find_proc+0x50>
    return listelm->next;
ffffffffc0204406:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204408:	fef69be3          	bne	a3,a5,ffffffffc02043fe <find_proc+0x34>
}
ffffffffc020440c:	60a2                	ld	ra,8(sp)
ffffffffc020440e:	6402                	ld	s0,0(sp)
    return NULL;
ffffffffc0204410:	4501                	li	a0,0
}
ffffffffc0204412:	0141                	addi	sp,sp,16
ffffffffc0204414:	8082                	ret
    return NULL;
ffffffffc0204416:	4501                	li	a0,0
}
ffffffffc0204418:	8082                	ret
ffffffffc020441a:	60a2                	ld	ra,8(sp)
ffffffffc020441c:	6402                	ld	s0,0(sp)
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc020441e:	f2878513          	addi	a0,a5,-216
}
ffffffffc0204422:	0141                	addi	sp,sp,16
ffffffffc0204424:	8082                	ret

ffffffffc0204426 <do_fork>:
{
ffffffffc0204426:	7179                	addi	sp,sp,-48
ffffffffc0204428:	e84a                	sd	s2,16(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc020442a:	00012917          	auipc	s2,0x12
ffffffffc020442e:	09e90913          	addi	s2,s2,158 # ffffffffc02164c8 <nr_process>
ffffffffc0204432:	00092703          	lw	a4,0(s2)
{
ffffffffc0204436:	f406                	sd	ra,40(sp)
ffffffffc0204438:	f022                	sd	s0,32(sp)
ffffffffc020443a:	ec26                	sd	s1,24(sp)
ffffffffc020443c:	e44e                	sd	s3,8(sp)
ffffffffc020443e:	e052                	sd	s4,0(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0204440:	6785                	lui	a5,0x1
ffffffffc0204442:	1ef75063          	bge	a4,a5,ffffffffc0204622 <do_fork+0x1fc>
ffffffffc0204446:	89ae                	mv	s3,a1
ffffffffc0204448:	84b2                	mv	s1,a2
    if ((proc = alloc_proc()) == NULL)
ffffffffc020444a:	df5ff0ef          	jal	ra,ffffffffc020423e <alloc_proc>
ffffffffc020444e:	842a                	mv	s0,a0
ffffffffc0204450:	1c050b63          	beqz	a0,ffffffffc0204626 <do_fork+0x200>
    proc->parent = current;
ffffffffc0204454:	00012a17          	auipc	s4,0x12
ffffffffc0204458:	05ca0a13          	addi	s4,s4,92 # ffffffffc02164b0 <current>
ffffffffc020445c:	000a3783          	ld	a5,0(s4)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0204460:	4509                	li	a0,2
    proc->parent = current;
ffffffffc0204462:	f01c                	sd	a5,32(s0)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0204464:	f42fc0ef          	jal	ra,ffffffffc0200ba6 <alloc_pages>
    if (page != NULL)
ffffffffc0204468:	c129                	beqz	a0,ffffffffc02044aa <do_fork+0x84>
    return page - pages + nbase;
ffffffffc020446a:	00012797          	auipc	a5,0x12
ffffffffc020446e:	08678793          	addi	a5,a5,134 # ffffffffc02164f0 <pages>
ffffffffc0204472:	6394                	ld	a3,0(a5)
ffffffffc0204474:	00003797          	auipc	a5,0x3
ffffffffc0204478:	bac78793          	addi	a5,a5,-1108 # ffffffffc0207020 <nbase>
ffffffffc020447c:	40d506b3          	sub	a3,a0,a3
ffffffffc0204480:	6388                	ld	a0,0(a5)
ffffffffc0204482:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204484:	00012797          	auipc	a5,0x12
ffffffffc0204488:	00478793          	addi	a5,a5,4 # ffffffffc0216488 <npage>
    return page - pages + nbase;
ffffffffc020448c:	96aa                	add	a3,a3,a0
    return KADDR(page2pa(page));
ffffffffc020448e:	6398                	ld	a4,0(a5)
ffffffffc0204490:	00c69793          	slli	a5,a3,0xc
ffffffffc0204494:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0204496:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204498:	1ae7fb63          	bgeu	a5,a4,ffffffffc020464e <do_fork+0x228>
ffffffffc020449c:	00012797          	auipc	a5,0x12
ffffffffc02044a0:	04478793          	addi	a5,a5,68 # ffffffffc02164e0 <va_pa_offset>
ffffffffc02044a4:	639c                	ld	a5,0(a5)
ffffffffc02044a6:	96be                	add	a3,a3,a5
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc02044a8:	e814                	sd	a3,16(s0)
    assert(current->mm == NULL);
ffffffffc02044aa:	000a3783          	ld	a5,0(s4)
ffffffffc02044ae:	779c                	ld	a5,40(a5)
ffffffffc02044b0:	16079f63          	bnez	a5,ffffffffc020462e <do_fork+0x208>
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc02044b4:	681c                	ld	a5,16(s0)
ffffffffc02044b6:	6709                	lui	a4,0x2
ffffffffc02044b8:	ee070713          	addi	a4,a4,-288 # 1ee0 <BASE_ADDRESS-0xffffffffc01fe120>
ffffffffc02044bc:	97ba                	add	a5,a5,a4
    *(proc->tf) = *tf;
ffffffffc02044be:	8626                	mv	a2,s1
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc02044c0:	f05c                	sd	a5,160(s0)
    *(proc->tf) = *tf;
ffffffffc02044c2:	873e                	mv	a4,a5
ffffffffc02044c4:	12048893          	addi	a7,s1,288
ffffffffc02044c8:	00063803          	ld	a6,0(a2)
ffffffffc02044cc:	6608                	ld	a0,8(a2)
ffffffffc02044ce:	6a0c                	ld	a1,16(a2)
ffffffffc02044d0:	6e14                	ld	a3,24(a2)
ffffffffc02044d2:	01073023          	sd	a6,0(a4)
ffffffffc02044d6:	e708                	sd	a0,8(a4)
ffffffffc02044d8:	eb0c                	sd	a1,16(a4)
ffffffffc02044da:	ef14                	sd	a3,24(a4)
ffffffffc02044dc:	02060613          	addi	a2,a2,32
ffffffffc02044e0:	02070713          	addi	a4,a4,32
ffffffffc02044e4:	ff1612e3          	bne	a2,a7,ffffffffc02044c8 <do_fork+0xa2>
    proc->tf->gpr.a0 = 0;
ffffffffc02044e8:	0407b823          	sd	zero,80(a5)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc02044ec:	10098d63          	beqz	s3,ffffffffc0204606 <do_fork+0x1e0>
    if (++last_pid >= MAX_PID)
ffffffffc02044f0:	00007717          	auipc	a4,0x7
ffffffffc02044f4:	b6870713          	addi	a4,a4,-1176 # ffffffffc020b058 <last_pid.1575>
ffffffffc02044f8:	4318                	lw	a4,0(a4)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc02044fa:	0137b823          	sd	s3,16(a5)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc02044fe:	fc1c                	sd	a5,56(s0)
    if (++last_pid >= MAX_PID)
ffffffffc0204500:	0017051b          	addiw	a0,a4,1
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204504:	00000697          	auipc	a3,0x0
ffffffffc0204508:	d9e68693          	addi	a3,a3,-610 # ffffffffc02042a2 <forkret>
    if (++last_pid >= MAX_PID)
ffffffffc020450c:	00007797          	auipc	a5,0x7
ffffffffc0204510:	b4a7a623          	sw	a0,-1204(a5) # ffffffffc020b058 <last_pid.1575>
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204514:	f814                	sd	a3,48(s0)
    if (++last_pid >= MAX_PID)
ffffffffc0204516:	6789                	lui	a5,0x2
ffffffffc0204518:	0ef55963          	bge	a0,a5,ffffffffc020460a <do_fork+0x1e4>
    if (last_pid >= next_safe)
ffffffffc020451c:	00007797          	auipc	a5,0x7
ffffffffc0204520:	b4078793          	addi	a5,a5,-1216 # ffffffffc020b05c <next_safe.1574>
ffffffffc0204524:	439c                	lw	a5,0(a5)
ffffffffc0204526:	00012497          	auipc	s1,0x12
ffffffffc020452a:	0ca48493          	addi	s1,s1,202 # ffffffffc02165f0 <proc_list>
ffffffffc020452e:	06f54063          	blt	a0,a5,ffffffffc020458e <do_fork+0x168>
        next_safe = MAX_PID;
ffffffffc0204532:	6789                	lui	a5,0x2
ffffffffc0204534:	00007717          	auipc	a4,0x7
ffffffffc0204538:	b2f72423          	sw	a5,-1240(a4) # ffffffffc020b05c <next_safe.1574>
ffffffffc020453c:	4581                	li	a1,0
ffffffffc020453e:	87aa                	mv	a5,a0
ffffffffc0204540:	00012497          	auipc	s1,0x12
ffffffffc0204544:	0b048493          	addi	s1,s1,176 # ffffffffc02165f0 <proc_list>
    repeat:
ffffffffc0204548:	6889                	lui	a7,0x2
ffffffffc020454a:	882e                	mv	a6,a1
ffffffffc020454c:	6609                	lui	a2,0x2
        le = list;
ffffffffc020454e:	00012697          	auipc	a3,0x12
ffffffffc0204552:	0a268693          	addi	a3,a3,162 # ffffffffc02165f0 <proc_list>
ffffffffc0204556:	6694                	ld	a3,8(a3)
        while ((le = list_next(le)) != list)
ffffffffc0204558:	00968f63          	beq	a3,s1,ffffffffc0204576 <do_fork+0x150>
            if (proc->pid == last_pid)
ffffffffc020455c:	f3c6a703          	lw	a4,-196(a3)
ffffffffc0204560:	08e78e63          	beq	a5,a4,ffffffffc02045fc <do_fork+0x1d6>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0204564:	fee7d9e3          	bge	a5,a4,ffffffffc0204556 <do_fork+0x130>
ffffffffc0204568:	fec757e3          	bge	a4,a2,ffffffffc0204556 <do_fork+0x130>
ffffffffc020456c:	6694                	ld	a3,8(a3)
ffffffffc020456e:	863a                	mv	a2,a4
ffffffffc0204570:	4805                	li	a6,1
        while ((le = list_next(le)) != list)
ffffffffc0204572:	fe9695e3          	bne	a3,s1,ffffffffc020455c <do_fork+0x136>
ffffffffc0204576:	c591                	beqz	a1,ffffffffc0204582 <do_fork+0x15c>
ffffffffc0204578:	00007717          	auipc	a4,0x7
ffffffffc020457c:	aef72023          	sw	a5,-1312(a4) # ffffffffc020b058 <last_pid.1575>
ffffffffc0204580:	853e                	mv	a0,a5
ffffffffc0204582:	00080663          	beqz	a6,ffffffffc020458e <do_fork+0x168>
ffffffffc0204586:	00007797          	auipc	a5,0x7
ffffffffc020458a:	acc7ab23          	sw	a2,-1322(a5) # ffffffffc020b05c <next_safe.1574>
    proc->pid = p;
ffffffffc020458e:	c048                	sw	a0,4(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0204590:	45a9                	li	a1,10
ffffffffc0204592:	2501                	sext.w	a0,a0
ffffffffc0204594:	0fd000ef          	jal	ra,ffffffffc0204e90 <hash32>
ffffffffc0204598:	1502                	slli	a0,a0,0x20
ffffffffc020459a:	0000e797          	auipc	a5,0xe
ffffffffc020459e:	ec678793          	addi	a5,a5,-314 # ffffffffc0212460 <hash_list>
ffffffffc02045a2:	8171                	srli	a0,a0,0x1c
ffffffffc02045a4:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc02045a6:	6518                	ld	a4,8(a0)
ffffffffc02045a8:	0d840793          	addi	a5,s0,216
ffffffffc02045ac:	6494                	ld	a3,8(s1)
    prev->next = next->prev = elm;
ffffffffc02045ae:	e31c                	sd	a5,0(a4)
ffffffffc02045b0:	e51c                	sd	a5,8(a0)
    nr_process++;
ffffffffc02045b2:	00092783          	lw	a5,0(s2)
    elm->next = next;
ffffffffc02045b6:	f078                	sd	a4,224(s0)
    elm->prev = prev;
ffffffffc02045b8:	ec68                	sd	a0,216(s0)
    list_add(&proc_list, &(proc->list_link));
ffffffffc02045ba:	0c840713          	addi	a4,s0,200
    prev->next = next->prev = elm;
ffffffffc02045be:	e298                	sd	a4,0(a3)
    elm->next = next;
ffffffffc02045c0:	e874                	sd	a3,208(s0)
    nr_process++;
ffffffffc02045c2:	2785                	addiw	a5,a5,1
    elm->prev = prev;
ffffffffc02045c4:	e464                	sd	s1,200(s0)
    wakeup_proc(proc);
ffffffffc02045c6:	8522                	mv	a0,s0
    prev->next = next->prev = elm;
ffffffffc02045c8:	00012697          	auipc	a3,0x12
ffffffffc02045cc:	02e6b823          	sd	a4,48(a3) # ffffffffc02165f8 <proc_list+0x8>
    nr_process++;
ffffffffc02045d0:	00012717          	auipc	a4,0x12
ffffffffc02045d4:	eef72c23          	sw	a5,-264(a4) # ffffffffc02164c8 <nr_process>
    wakeup_proc(proc);
ffffffffc02045d8:	308000ef          	jal	ra,ffffffffc02048e0 <wakeup_proc>
    ret = proc->pid;
ffffffffc02045dc:	4040                	lw	s0,4(s0)
    cprintf("do_fork out\n");
ffffffffc02045de:	00002517          	auipc	a0,0x2
ffffffffc02045e2:	66a50513          	addi	a0,a0,1642 # ffffffffc0206c48 <default_pmm_manager+0xf0>
ffffffffc02045e6:	aebfb0ef          	jal	ra,ffffffffc02000d0 <cprintf>
}
ffffffffc02045ea:	8522                	mv	a0,s0
ffffffffc02045ec:	70a2                	ld	ra,40(sp)
ffffffffc02045ee:	7402                	ld	s0,32(sp)
ffffffffc02045f0:	64e2                	ld	s1,24(sp)
ffffffffc02045f2:	6942                	ld	s2,16(sp)
ffffffffc02045f4:	69a2                	ld	s3,8(sp)
ffffffffc02045f6:	6a02                	ld	s4,0(sp)
ffffffffc02045f8:	6145                	addi	sp,sp,48
ffffffffc02045fa:	8082                	ret
                if (++last_pid >= next_safe)
ffffffffc02045fc:	2785                	addiw	a5,a5,1
ffffffffc02045fe:	00c7dd63          	bge	a5,a2,ffffffffc0204618 <do_fork+0x1f2>
ffffffffc0204602:	4585                	li	a1,1
ffffffffc0204604:	bf89                	j	ffffffffc0204556 <do_fork+0x130>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204606:	89be                	mv	s3,a5
ffffffffc0204608:	b5e5                	j	ffffffffc02044f0 <do_fork+0xca>
        last_pid = 1;
ffffffffc020460a:	4785                	li	a5,1
ffffffffc020460c:	00007717          	auipc	a4,0x7
ffffffffc0204610:	a4f72623          	sw	a5,-1460(a4) # ffffffffc020b058 <last_pid.1575>
ffffffffc0204614:	4505                	li	a0,1
ffffffffc0204616:	bf31                	j	ffffffffc0204532 <do_fork+0x10c>
                    if (last_pid >= MAX_PID)
ffffffffc0204618:	0117c363          	blt	a5,a7,ffffffffc020461e <do_fork+0x1f8>
                        last_pid = 1;
ffffffffc020461c:	4785                	li	a5,1
                    goto repeat;
ffffffffc020461e:	4585                	li	a1,1
ffffffffc0204620:	b72d                	j	ffffffffc020454a <do_fork+0x124>
    int ret = -E_NO_FREE_PROC;
ffffffffc0204622:	546d                	li	s0,-5
ffffffffc0204624:	bf6d                	j	ffffffffc02045de <do_fork+0x1b8>
    kfree(proc);
ffffffffc0204626:	c5cfe0ef          	jal	ra,ffffffffc0202a82 <kfree>
    ret = -E_NO_MEM;
ffffffffc020462a:	5471                	li	s0,-4
    goto fork_out;
ffffffffc020462c:	bf4d                	j	ffffffffc02045de <do_fork+0x1b8>
    assert(current->mm == NULL);
ffffffffc020462e:	00002697          	auipc	a3,0x2
ffffffffc0204632:	5ea68693          	addi	a3,a3,1514 # ffffffffc0206c18 <default_pmm_manager+0xc0>
ffffffffc0204636:	00001617          	auipc	a2,0x1
ffffffffc020463a:	35a60613          	addi	a2,a2,858 # ffffffffc0205990 <commands+0x998>
ffffffffc020463e:	12200593          	li	a1,290
ffffffffc0204642:	00002517          	auipc	a0,0x2
ffffffffc0204646:	5ee50513          	addi	a0,a0,1518 # ffffffffc0206c30 <default_pmm_manager+0xd8>
ffffffffc020464a:	b8bfb0ef          	jal	ra,ffffffffc02001d4 <__panic>
ffffffffc020464e:	00001617          	auipc	a2,0x1
ffffffffc0204652:	1ea60613          	addi	a2,a2,490 # ffffffffc0205838 <commands+0x840>
ffffffffc0204656:	06900593          	li	a1,105
ffffffffc020465a:	00001517          	auipc	a0,0x1
ffffffffc020465e:	23650513          	addi	a0,a0,566 # ffffffffc0205890 <commands+0x898>
ffffffffc0204662:	b73fb0ef          	jal	ra,ffffffffc02001d4 <__panic>

ffffffffc0204666 <kernel_thread>:
{
ffffffffc0204666:	7129                	addi	sp,sp,-320
ffffffffc0204668:	fa22                	sd	s0,304(sp)
ffffffffc020466a:	f626                	sd	s1,296(sp)
ffffffffc020466c:	f24a                	sd	s2,288(sp)
ffffffffc020466e:	84ae                	mv	s1,a1
ffffffffc0204670:	892a                	mv	s2,a0
ffffffffc0204672:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0204674:	4581                	li	a1,0
ffffffffc0204676:	12000613          	li	a2,288
ffffffffc020467a:	850a                	mv	a0,sp
{
ffffffffc020467c:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc020467e:	3cc000ef          	jal	ra,ffffffffc0204a4a <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc0204682:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc0204684:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc0204686:	100027f3          	csrr	a5,sstatus
ffffffffc020468a:	edd7f793          	andi	a5,a5,-291
ffffffffc020468e:	1207e793          	ori	a5,a5,288
ffffffffc0204692:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204694:	860a                	mv	a2,sp
ffffffffc0204696:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc020469a:	00000797          	auipc	a5,0x0
ffffffffc020469e:	b3278793          	addi	a5,a5,-1230 # ffffffffc02041cc <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02046a2:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02046a4:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02046a6:	d81ff0ef          	jal	ra,ffffffffc0204426 <do_fork>
}
ffffffffc02046aa:	70f2                	ld	ra,312(sp)
ffffffffc02046ac:	7452                	ld	s0,304(sp)
ffffffffc02046ae:	74b2                	ld	s1,296(sp)
ffffffffc02046b0:	7912                	ld	s2,288(sp)
ffffffffc02046b2:	6131                	addi	sp,sp,320
ffffffffc02046b4:	8082                	ret

ffffffffc02046b6 <do_exit>:
{
ffffffffc02046b6:	1141                	addi	sp,sp,-16
    panic("进程退出!!.\n");
ffffffffc02046b8:	00002617          	auipc	a2,0x2
ffffffffc02046bc:	54860613          	addi	a2,a2,1352 # ffffffffc0206c00 <default_pmm_manager+0xa8>
ffffffffc02046c0:	17e00593          	li	a1,382
ffffffffc02046c4:	00002517          	auipc	a0,0x2
ffffffffc02046c8:	56c50513          	addi	a0,a0,1388 # ffffffffc0206c30 <default_pmm_manager+0xd8>
{
ffffffffc02046cc:	e406                	sd	ra,8(sp)
    panic("进程退出!!.\n");
ffffffffc02046ce:	b07fb0ef          	jal	ra,ffffffffc02001d4 <__panic>

ffffffffc02046d2 <proc_init>:
    elm->prev = elm->next = elm;
ffffffffc02046d2:	00012797          	auipc	a5,0x12
ffffffffc02046d6:	f1e78793          	addi	a5,a5,-226 # ffffffffc02165f0 <proc_list>

// proc_init - 通过自身设置第一个内核线程idleproc "idle"
//           - 创建第二个内核线程init_main
void proc_init(void)
{
ffffffffc02046da:	1101                	addi	sp,sp,-32
ffffffffc02046dc:	00012717          	auipc	a4,0x12
ffffffffc02046e0:	f0f73e23          	sd	a5,-228(a4) # ffffffffc02165f8 <proc_list+0x8>
ffffffffc02046e4:	00012717          	auipc	a4,0x12
ffffffffc02046e8:	f0f73623          	sd	a5,-244(a4) # ffffffffc02165f0 <proc_list>
ffffffffc02046ec:	ec06                	sd	ra,24(sp)
ffffffffc02046ee:	e822                	sd	s0,16(sp)
ffffffffc02046f0:	e426                	sd	s1,8(sp)
ffffffffc02046f2:	e04a                	sd	s2,0(sp)
ffffffffc02046f4:	0000e797          	auipc	a5,0xe
ffffffffc02046f8:	d6c78793          	addi	a5,a5,-660 # ffffffffc0212460 <hash_list>
ffffffffc02046fc:	00012717          	auipc	a4,0x12
ffffffffc0204700:	d6470713          	addi	a4,a4,-668 # ffffffffc0216460 <name.1565>
ffffffffc0204704:	e79c                	sd	a5,8(a5)
ffffffffc0204706:	e39c                	sd	a5,0(a5)
ffffffffc0204708:	07c1                	addi	a5,a5,16
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc020470a:	fee79de3          	bne	a5,a4,ffffffffc0204704 <proc_init+0x32>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc020470e:	b31ff0ef          	jal	ra,ffffffffc020423e <alloc_proc>
ffffffffc0204712:	00012797          	auipc	a5,0x12
ffffffffc0204716:	daa7b323          	sd	a0,-602(a5) # ffffffffc02164b8 <idleproc>
ffffffffc020471a:	00012417          	auipc	s0,0x12
ffffffffc020471e:	d9e40413          	addi	s0,s0,-610 # ffffffffc02164b8 <idleproc>
ffffffffc0204722:	12050963          	beqz	a0,ffffffffc0204854 <proc_init+0x182>
    {
        panic("无法分配idleproc。\n");
    }
    // 检查proc结构
    int *context_mem = (int *)kmalloc(sizeof(struct context));
ffffffffc0204726:	07000513          	li	a0,112
ffffffffc020472a:	a9cfe0ef          	jal	ra,ffffffffc02029c6 <kmalloc>
    memset(context_mem, 0, sizeof(struct context));
ffffffffc020472e:	07000613          	li	a2,112
ffffffffc0204732:	4581                	li	a1,0
    int *context_mem = (int *)kmalloc(sizeof(struct context));
ffffffffc0204734:	84aa                	mv	s1,a0
    memset(context_mem, 0, sizeof(struct context));
ffffffffc0204736:	314000ef          	jal	ra,ffffffffc0204a4a <memset>
    int context_init_flag = memcmp(&(idleproc->context), context_mem, sizeof(struct context));
ffffffffc020473a:	6008                	ld	a0,0(s0)
ffffffffc020473c:	85a6                	mv	a1,s1
ffffffffc020473e:	07000613          	li	a2,112
ffffffffc0204742:	03050513          	addi	a0,a0,48
ffffffffc0204746:	32e000ef          	jal	ra,ffffffffc0204a74 <memcmp>
ffffffffc020474a:	892a                	mv	s2,a0

    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN);
ffffffffc020474c:	453d                	li	a0,15
ffffffffc020474e:	a78fe0ef          	jal	ra,ffffffffc02029c6 <kmalloc>
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc0204752:	463d                	li	a2,15
ffffffffc0204754:	4581                	li	a1,0
    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN);
ffffffffc0204756:	84aa                	mv	s1,a0
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc0204758:	2f2000ef          	jal	ra,ffffffffc0204a4a <memset>
    int proc_name_flag = memcmp(&(idleproc->name), proc_name_mem, PROC_NAME_LEN);
ffffffffc020475c:	6008                	ld	a0,0(s0)
ffffffffc020475e:	463d                	li	a2,15
ffffffffc0204760:	85a6                	mv	a1,s1
ffffffffc0204762:	0b450513          	addi	a0,a0,180
ffffffffc0204766:	30e000ef          	jal	ra,ffffffffc0204a74 <memcmp>

    if (idleproc->cr3 == boot_cr3 &&
ffffffffc020476a:	601c                	ld	a5,0(s0)
ffffffffc020476c:	00012717          	auipc	a4,0x12
ffffffffc0204770:	d7c70713          	addi	a4,a4,-644 # ffffffffc02164e8 <boot_cr3>
ffffffffc0204774:	6318                	ld	a4,0(a4)
ffffffffc0204776:	77d4                	ld	a3,168(a5)
ffffffffc0204778:	08e68d63          	beq	a3,a4,ffffffffc0204812 <proc_init+0x140>
    {
        cprintf("alloc_proc() 正确!\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc020477c:	4709                	li	a4,2
ffffffffc020477e:	e398                	sd	a4,0(a5)
    idleproc->kstack = (uintptr_t)bootstack;
    idleproc->need_resched = 1;
ffffffffc0204780:	4485                	li	s1,1
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204782:	00004717          	auipc	a4,0x4
ffffffffc0204786:	87e70713          	addi	a4,a4,-1922 # ffffffffc0208000 <bootstack>
ffffffffc020478a:	eb98                	sd	a4,16(a5)
    set_proc_name(idleproc, "idle");
ffffffffc020478c:	00002597          	auipc	a1,0x2
ffffffffc0204790:	56c58593          	addi	a1,a1,1388 # ffffffffc0206cf8 <default_pmm_manager+0x1a0>
    idleproc->need_resched = 1;
ffffffffc0204794:	cf84                	sw	s1,24(a5)
    set_proc_name(idleproc, "idle");
ffffffffc0204796:	853e                	mv	a0,a5
ffffffffc0204798:	b1bff0ef          	jal	ra,ffffffffc02042b2 <set_proc_name>
    nr_process++;
ffffffffc020479c:	00012797          	auipc	a5,0x12
ffffffffc02047a0:	d2c78793          	addi	a5,a5,-724 # ffffffffc02164c8 <nr_process>
ffffffffc02047a4:	439c                	lw	a5,0(a5)

    current = idleproc;
ffffffffc02047a6:	6018                	ld	a4,0(s0)

    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc02047a8:	4601                	li	a2,0
    nr_process++;
ffffffffc02047aa:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc02047ac:	00002597          	auipc	a1,0x2
ffffffffc02047b0:	55458593          	addi	a1,a1,1364 # ffffffffc0206d00 <default_pmm_manager+0x1a8>
ffffffffc02047b4:	00000517          	auipc	a0,0x0
ffffffffc02047b8:	b5650513          	addi	a0,a0,-1194 # ffffffffc020430a <init_main>
    nr_process++;
ffffffffc02047bc:	00012697          	auipc	a3,0x12
ffffffffc02047c0:	d0f6a623          	sw	a5,-756(a3) # ffffffffc02164c8 <nr_process>
    current = idleproc;
ffffffffc02047c4:	00012797          	auipc	a5,0x12
ffffffffc02047c8:	cee7b623          	sd	a4,-788(a5) # ffffffffc02164b0 <current>
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc02047cc:	e9bff0ef          	jal	ra,ffffffffc0204666 <kernel_thread>
    if (pid <= 0)
ffffffffc02047d0:	0ca05e63          	blez	a0,ffffffffc02048ac <proc_init+0x1da>
    {
        panic("创建init_main失败。\n");
    }

    initproc = find_proc(pid);
ffffffffc02047d4:	bf7ff0ef          	jal	ra,ffffffffc02043ca <find_proc>
    set_proc_name(initproc, "init");
ffffffffc02047d8:	00002597          	auipc	a1,0x2
ffffffffc02047dc:	55858593          	addi	a1,a1,1368 # ffffffffc0206d30 <default_pmm_manager+0x1d8>
    initproc = find_proc(pid);
ffffffffc02047e0:	00012797          	auipc	a5,0x12
ffffffffc02047e4:	cea7b023          	sd	a0,-800(a5) # ffffffffc02164c0 <initproc>
    set_proc_name(initproc, "init");
ffffffffc02047e8:	acbff0ef          	jal	ra,ffffffffc02042b2 <set_proc_name>

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc02047ec:	601c                	ld	a5,0(s0)
ffffffffc02047ee:	cfd9                	beqz	a5,ffffffffc020488c <proc_init+0x1ba>
ffffffffc02047f0:	43dc                	lw	a5,4(a5)
ffffffffc02047f2:	efc9                	bnez	a5,ffffffffc020488c <proc_init+0x1ba>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc02047f4:	00012797          	auipc	a5,0x12
ffffffffc02047f8:	ccc78793          	addi	a5,a5,-820 # ffffffffc02164c0 <initproc>
ffffffffc02047fc:	639c                	ld	a5,0(a5)
ffffffffc02047fe:	c7bd                	beqz	a5,ffffffffc020486c <proc_init+0x19a>
ffffffffc0204800:	43dc                	lw	a5,4(a5)
ffffffffc0204802:	06979563          	bne	a5,s1,ffffffffc020486c <proc_init+0x19a>
}
ffffffffc0204806:	60e2                	ld	ra,24(sp)
ffffffffc0204808:	6442                	ld	s0,16(sp)
ffffffffc020480a:	64a2                	ld	s1,8(sp)
ffffffffc020480c:	6902                	ld	s2,0(sp)
ffffffffc020480e:	6105                	addi	sp,sp,32
ffffffffc0204810:	8082                	ret
    if (idleproc->cr3 == boot_cr3 &&
ffffffffc0204812:	73d8                	ld	a4,160(a5)
ffffffffc0204814:	f725                	bnez	a4,ffffffffc020477c <proc_init+0xaa>
        idleproc->tf == NULL &&
ffffffffc0204816:	f60913e3          	bnez	s2,ffffffffc020477c <proc_init+0xaa>
        idleproc->state == PROC_UNINIT &&
ffffffffc020481a:	6394                	ld	a3,0(a5)
ffffffffc020481c:	577d                	li	a4,-1
ffffffffc020481e:	1702                	slli	a4,a4,0x20
ffffffffc0204820:	f4e69ee3          	bne	a3,a4,ffffffffc020477c <proc_init+0xaa>
        idleproc->pid == -1 &&
ffffffffc0204824:	4798                	lw	a4,8(a5)
ffffffffc0204826:	fb39                	bnez	a4,ffffffffc020477c <proc_init+0xaa>
        idleproc->runs == 0 &&
ffffffffc0204828:	6b98                	ld	a4,16(a5)
ffffffffc020482a:	fb29                	bnez	a4,ffffffffc020477c <proc_init+0xaa>
        idleproc->need_resched == 0 &&
ffffffffc020482c:	4f98                	lw	a4,24(a5)
ffffffffc020482e:	2701                	sext.w	a4,a4
        idleproc->kstack == 0 &&
ffffffffc0204830:	f731                	bnez	a4,ffffffffc020477c <proc_init+0xaa>
        idleproc->need_resched == 0 &&
ffffffffc0204832:	7398                	ld	a4,32(a5)
ffffffffc0204834:	f721                	bnez	a4,ffffffffc020477c <proc_init+0xaa>
        idleproc->parent == NULL &&
ffffffffc0204836:	7798                	ld	a4,40(a5)
ffffffffc0204838:	f331                	bnez	a4,ffffffffc020477c <proc_init+0xaa>
        idleproc->mm == NULL &&
ffffffffc020483a:	0b07a703          	lw	a4,176(a5)
ffffffffc020483e:	8f49                	or	a4,a4,a0
ffffffffc0204840:	2701                	sext.w	a4,a4
ffffffffc0204842:	ff0d                	bnez	a4,ffffffffc020477c <proc_init+0xaa>
        cprintf("alloc_proc() 正确!\n");
ffffffffc0204844:	00002517          	auipc	a0,0x2
ffffffffc0204848:	49c50513          	addi	a0,a0,1180 # ffffffffc0206ce0 <default_pmm_manager+0x188>
ffffffffc020484c:	885fb0ef          	jal	ra,ffffffffc02000d0 <cprintf>
ffffffffc0204850:	601c                	ld	a5,0(s0)
ffffffffc0204852:	b72d                	j	ffffffffc020477c <proc_init+0xaa>
        panic("无法分配idleproc。\n");
ffffffffc0204854:	00002617          	auipc	a2,0x2
ffffffffc0204858:	46c60613          	addi	a2,a2,1132 # ffffffffc0206cc0 <default_pmm_manager+0x168>
ffffffffc020485c:	19900593          	li	a1,409
ffffffffc0204860:	00002517          	auipc	a0,0x2
ffffffffc0204864:	3d050513          	addi	a0,a0,976 # ffffffffc0206c30 <default_pmm_manager+0xd8>
ffffffffc0204868:	96dfb0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc020486c:	00002697          	auipc	a3,0x2
ffffffffc0204870:	4f468693          	addi	a3,a3,1268 # ffffffffc0206d60 <default_pmm_manager+0x208>
ffffffffc0204874:	00001617          	auipc	a2,0x1
ffffffffc0204878:	11c60613          	addi	a2,a2,284 # ffffffffc0205990 <commands+0x998>
ffffffffc020487c:	1c700593          	li	a1,455
ffffffffc0204880:	00002517          	auipc	a0,0x2
ffffffffc0204884:	3b050513          	addi	a0,a0,944 # ffffffffc0206c30 <default_pmm_manager+0xd8>
ffffffffc0204888:	94dfb0ef          	jal	ra,ffffffffc02001d4 <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc020488c:	00002697          	auipc	a3,0x2
ffffffffc0204890:	4ac68693          	addi	a3,a3,1196 # ffffffffc0206d38 <default_pmm_manager+0x1e0>
ffffffffc0204894:	00001617          	auipc	a2,0x1
ffffffffc0204898:	0fc60613          	addi	a2,a2,252 # ffffffffc0205990 <commands+0x998>
ffffffffc020489c:	1c600593          	li	a1,454
ffffffffc02048a0:	00002517          	auipc	a0,0x2
ffffffffc02048a4:	39050513          	addi	a0,a0,912 # ffffffffc0206c30 <default_pmm_manager+0xd8>
ffffffffc02048a8:	92dfb0ef          	jal	ra,ffffffffc02001d4 <__panic>
        panic("创建init_main失败。\n");
ffffffffc02048ac:	00002617          	auipc	a2,0x2
ffffffffc02048b0:	46460613          	addi	a2,a2,1124 # ffffffffc0206d10 <default_pmm_manager+0x1b8>
ffffffffc02048b4:	1c000593          	li	a1,448
ffffffffc02048b8:	00002517          	auipc	a0,0x2
ffffffffc02048bc:	37850513          	addi	a0,a0,888 # ffffffffc0206c30 <default_pmm_manager+0xd8>
ffffffffc02048c0:	915fb0ef          	jal	ra,ffffffffc02001d4 <__panic>

ffffffffc02048c4 <cpu_idle>:

// cpu_idle - 在kern_init结束时，第一个内核线程idleproc将执行以下工作
void cpu_idle(void)
{
ffffffffc02048c4:	1141                	addi	sp,sp,-16
ffffffffc02048c6:	e022                	sd	s0,0(sp)
ffffffffc02048c8:	e406                	sd	ra,8(sp)
ffffffffc02048ca:	00012417          	auipc	s0,0x12
ffffffffc02048ce:	be640413          	addi	s0,s0,-1050 # ffffffffc02164b0 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc02048d2:	6018                	ld	a4,0(s0)
ffffffffc02048d4:	4f1c                	lw	a5,24(a4)
ffffffffc02048d6:	2781                	sext.w	a5,a5
ffffffffc02048d8:	dff5                	beqz	a5,ffffffffc02048d4 <cpu_idle+0x10>
        {
            schedule();
ffffffffc02048da:	038000ef          	jal	ra,ffffffffc0204912 <schedule>
ffffffffc02048de:	bfd5                	j	ffffffffc02048d2 <cpu_idle+0xe>

ffffffffc02048e0 <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc02048e0:	411c                	lw	a5,0(a0)
ffffffffc02048e2:	4705                	li	a4,1
ffffffffc02048e4:	37f9                	addiw	a5,a5,-2
ffffffffc02048e6:	00f77563          	bgeu	a4,a5,ffffffffc02048f0 <wakeup_proc+0x10>
    proc->state = PROC_RUNNABLE;
ffffffffc02048ea:	4789                	li	a5,2
ffffffffc02048ec:	c11c                	sw	a5,0(a0)
ffffffffc02048ee:	8082                	ret
wakeup_proc(struct proc_struct *proc) {
ffffffffc02048f0:	1141                	addi	sp,sp,-16
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc02048f2:	00002697          	auipc	a3,0x2
ffffffffc02048f6:	49668693          	addi	a3,a3,1174 # ffffffffc0206d88 <default_pmm_manager+0x230>
ffffffffc02048fa:	00001617          	auipc	a2,0x1
ffffffffc02048fe:	09660613          	addi	a2,a2,150 # ffffffffc0205990 <commands+0x998>
ffffffffc0204902:	45a5                	li	a1,9
ffffffffc0204904:	00002517          	auipc	a0,0x2
ffffffffc0204908:	4c450513          	addi	a0,a0,1220 # ffffffffc0206dc8 <default_pmm_manager+0x270>
wakeup_proc(struct proc_struct *proc) {
ffffffffc020490c:	e406                	sd	ra,8(sp)
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc020490e:	8c7fb0ef          	jal	ra,ffffffffc02001d4 <__panic>

ffffffffc0204912 <schedule>:
}

void
schedule(void) {
ffffffffc0204912:	1141                	addi	sp,sp,-16
ffffffffc0204914:	e406                	sd	ra,8(sp)
ffffffffc0204916:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204918:	100027f3          	csrr	a5,sstatus
ffffffffc020491c:	8b89                	andi	a5,a5,2
ffffffffc020491e:	4401                	li	s0,0
ffffffffc0204920:	e3d1                	bnez	a5,ffffffffc02049a4 <schedule+0x92>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc0204922:	00012797          	auipc	a5,0x12
ffffffffc0204926:	b8e78793          	addi	a5,a5,-1138 # ffffffffc02164b0 <current>
ffffffffc020492a:	0007b883          	ld	a7,0(a5)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc020492e:	00012797          	auipc	a5,0x12
ffffffffc0204932:	b8a78793          	addi	a5,a5,-1142 # ffffffffc02164b8 <idleproc>
ffffffffc0204936:	6388                	ld	a0,0(a5)
        current->need_resched = 0;
ffffffffc0204938:	0008ac23          	sw	zero,24(a7) # 2018 <BASE_ADDRESS-0xffffffffc01fdfe8>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc020493c:	04a88e63          	beq	a7,a0,ffffffffc0204998 <schedule+0x86>
ffffffffc0204940:	0c888693          	addi	a3,a7,200
ffffffffc0204944:	00012617          	auipc	a2,0x12
ffffffffc0204948:	cac60613          	addi	a2,a2,-852 # ffffffffc02165f0 <proc_list>
        le = last;
ffffffffc020494c:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc020494e:	4581                	li	a1,0
        do {
            if ((le = list_next(le)) != &proc_list) {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE) {
ffffffffc0204950:	4809                	li	a6,2
    return listelm->next;
ffffffffc0204952:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list) {
ffffffffc0204954:	00c78863          	beq	a5,a2,ffffffffc0204964 <schedule+0x52>
                if (next->state == PROC_RUNNABLE) {
ffffffffc0204958:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc020495c:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE) {
ffffffffc0204960:	01070463          	beq	a4,a6,ffffffffc0204968 <schedule+0x56>
                    break;
                }
            }
        } while (le != last);
ffffffffc0204964:	fef697e3          	bne	a3,a5,ffffffffc0204952 <schedule+0x40>
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0204968:	c589                	beqz	a1,ffffffffc0204972 <schedule+0x60>
ffffffffc020496a:	4198                	lw	a4,0(a1)
ffffffffc020496c:	4789                	li	a5,2
ffffffffc020496e:	00f70e63          	beq	a4,a5,ffffffffc020498a <schedule+0x78>
            next = idleproc;
        }
        next->runs ++;
ffffffffc0204972:	451c                	lw	a5,8(a0)
ffffffffc0204974:	2785                	addiw	a5,a5,1
ffffffffc0204976:	c51c                	sw	a5,8(a0)
        if (next != current) {
ffffffffc0204978:	00a88463          	beq	a7,a0,ffffffffc0204980 <schedule+0x6e>
            proc_run(next);
ffffffffc020497c:	9e1ff0ef          	jal	ra,ffffffffc020435c <proc_run>
    if (flag) {
ffffffffc0204980:	e419                	bnez	s0,ffffffffc020498e <schedule+0x7c>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0204982:	60a2                	ld	ra,8(sp)
ffffffffc0204984:	6402                	ld	s0,0(sp)
ffffffffc0204986:	0141                	addi	sp,sp,16
ffffffffc0204988:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc020498a:	852e                	mv	a0,a1
ffffffffc020498c:	b7dd                	j	ffffffffc0204972 <schedule+0x60>
}
ffffffffc020498e:	6402                	ld	s0,0(sp)
ffffffffc0204990:	60a2                	ld	ra,8(sp)
ffffffffc0204992:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0204994:	c39fb06f          	j	ffffffffc02005cc <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0204998:	00012617          	auipc	a2,0x12
ffffffffc020499c:	c5860613          	addi	a2,a2,-936 # ffffffffc02165f0 <proc_list>
ffffffffc02049a0:	86b2                	mv	a3,a2
ffffffffc02049a2:	b76d                	j	ffffffffc020494c <schedule+0x3a>
        intr_disable();
ffffffffc02049a4:	c2ffb0ef          	jal	ra,ffffffffc02005d2 <intr_disable>
        return 1;
ffffffffc02049a8:	4405                	li	s0,1
ffffffffc02049aa:	bfa5                	j	ffffffffc0204922 <schedule+0x10>

ffffffffc02049ac <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02049ac:	00054783          	lbu	a5,0(a0)
ffffffffc02049b0:	cb91                	beqz	a5,ffffffffc02049c4 <strlen+0x18>
    size_t cnt = 0;
ffffffffc02049b2:	4781                	li	a5,0
        cnt ++;
ffffffffc02049b4:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc02049b6:	00f50733          	add	a4,a0,a5
ffffffffc02049ba:	00074703          	lbu	a4,0(a4)
ffffffffc02049be:	fb7d                	bnez	a4,ffffffffc02049b4 <strlen+0x8>
    }
    return cnt;
}
ffffffffc02049c0:	853e                	mv	a0,a5
ffffffffc02049c2:	8082                	ret
    size_t cnt = 0;
ffffffffc02049c4:	4781                	li	a5,0
}
ffffffffc02049c6:	853e                	mv	a0,a5
ffffffffc02049c8:	8082                	ret

ffffffffc02049ca <strnlen>:
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
ffffffffc02049ca:	c185                	beqz	a1,ffffffffc02049ea <strnlen+0x20>
ffffffffc02049cc:	00054783          	lbu	a5,0(a0)
ffffffffc02049d0:	cf89                	beqz	a5,ffffffffc02049ea <strnlen+0x20>
    size_t cnt = 0;
ffffffffc02049d2:	4781                	li	a5,0
ffffffffc02049d4:	a021                	j	ffffffffc02049dc <strnlen+0x12>
    while (cnt < len && *s ++ != '\0') {
ffffffffc02049d6:	00074703          	lbu	a4,0(a4)
ffffffffc02049da:	c711                	beqz	a4,ffffffffc02049e6 <strnlen+0x1c>
        cnt ++;
ffffffffc02049dc:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02049de:	00f50733          	add	a4,a0,a5
ffffffffc02049e2:	fef59ae3          	bne	a1,a5,ffffffffc02049d6 <strnlen+0xc>
    }
    return cnt;
}
ffffffffc02049e6:	853e                	mv	a0,a5
ffffffffc02049e8:	8082                	ret
    size_t cnt = 0;
ffffffffc02049ea:	4781                	li	a5,0
}
ffffffffc02049ec:	853e                	mv	a0,a5
ffffffffc02049ee:	8082                	ret

ffffffffc02049f0 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc02049f0:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc02049f2:	0585                	addi	a1,a1,1
ffffffffc02049f4:	fff5c703          	lbu	a4,-1(a1)
ffffffffc02049f8:	0785                	addi	a5,a5,1
ffffffffc02049fa:	fee78fa3          	sb	a4,-1(a5)
ffffffffc02049fe:	fb75                	bnez	a4,ffffffffc02049f2 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0204a00:	8082                	ret

ffffffffc0204a02 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0204a02:	00054783          	lbu	a5,0(a0)
ffffffffc0204a06:	0005c703          	lbu	a4,0(a1)
ffffffffc0204a0a:	cb91                	beqz	a5,ffffffffc0204a1e <strcmp+0x1c>
ffffffffc0204a0c:	00e79c63          	bne	a5,a4,ffffffffc0204a24 <strcmp+0x22>
        s1 ++, s2 ++;
ffffffffc0204a10:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0204a12:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
ffffffffc0204a16:	0585                	addi	a1,a1,1
ffffffffc0204a18:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0204a1c:	fbe5                	bnez	a5,ffffffffc0204a0c <strcmp+0xa>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0204a1e:	4501                	li	a0,0
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0204a20:	9d19                	subw	a0,a0,a4
ffffffffc0204a22:	8082                	ret
ffffffffc0204a24:	0007851b          	sext.w	a0,a5
ffffffffc0204a28:	9d19                	subw	a0,a0,a4
ffffffffc0204a2a:	8082                	ret

ffffffffc0204a2c <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0204a2c:	00054783          	lbu	a5,0(a0)
ffffffffc0204a30:	cb91                	beqz	a5,ffffffffc0204a44 <strchr+0x18>
        if (*s == c) {
ffffffffc0204a32:	00b79563          	bne	a5,a1,ffffffffc0204a3c <strchr+0x10>
ffffffffc0204a36:	a809                	j	ffffffffc0204a48 <strchr+0x1c>
ffffffffc0204a38:	00b78763          	beq	a5,a1,ffffffffc0204a46 <strchr+0x1a>
            return (char *)s;
        }
        s ++;
ffffffffc0204a3c:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0204a3e:	00054783          	lbu	a5,0(a0)
ffffffffc0204a42:	fbfd                	bnez	a5,ffffffffc0204a38 <strchr+0xc>
    }
    return NULL;
ffffffffc0204a44:	4501                	li	a0,0
}
ffffffffc0204a46:	8082                	ret
ffffffffc0204a48:	8082                	ret

ffffffffc0204a4a <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0204a4a:	ca01                	beqz	a2,ffffffffc0204a5a <memset+0x10>
ffffffffc0204a4c:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0204a4e:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0204a50:	0785                	addi	a5,a5,1
ffffffffc0204a52:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0204a56:	fec79de3          	bne	a5,a2,ffffffffc0204a50 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0204a5a:	8082                	ret

ffffffffc0204a5c <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0204a5c:	ca19                	beqz	a2,ffffffffc0204a72 <memcpy+0x16>
ffffffffc0204a5e:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0204a60:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0204a62:	0585                	addi	a1,a1,1
ffffffffc0204a64:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0204a68:	0785                	addi	a5,a5,1
ffffffffc0204a6a:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0204a6e:	fec59ae3          	bne	a1,a2,ffffffffc0204a62 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0204a72:	8082                	ret

ffffffffc0204a74 <memcmp>:
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
    const char *s1 = (const char *)v1;
    const char *s2 = (const char *)v2;
    while (n -- > 0) {
ffffffffc0204a74:	c21d                	beqz	a2,ffffffffc0204a9a <memcmp+0x26>
        if (*s1 != *s2) {
ffffffffc0204a76:	00054783          	lbu	a5,0(a0)
ffffffffc0204a7a:	0005c703          	lbu	a4,0(a1)
ffffffffc0204a7e:	962a                	add	a2,a2,a0
ffffffffc0204a80:	00f70963          	beq	a4,a5,ffffffffc0204a92 <memcmp+0x1e>
ffffffffc0204a84:	a829                	j	ffffffffc0204a9e <memcmp+0x2a>
ffffffffc0204a86:	00054783          	lbu	a5,0(a0)
ffffffffc0204a8a:	0005c703          	lbu	a4,0(a1)
ffffffffc0204a8e:	00e79863          	bne	a5,a4,ffffffffc0204a9e <memcmp+0x2a>
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
        }
        s1 ++, s2 ++;
ffffffffc0204a92:	0505                	addi	a0,a0,1
ffffffffc0204a94:	0585                	addi	a1,a1,1
    while (n -- > 0) {
ffffffffc0204a96:	fea618e3          	bne	a2,a0,ffffffffc0204a86 <memcmp+0x12>
    }
    return 0;
ffffffffc0204a9a:	4501                	li	a0,0
}
ffffffffc0204a9c:	8082                	ret
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0204a9e:	40e7853b          	subw	a0,a5,a4
ffffffffc0204aa2:	8082                	ret

ffffffffc0204aa4 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0204aa4:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0204aa8:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0204aaa:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0204aae:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0204ab0:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0204ab4:	f022                	sd	s0,32(sp)
ffffffffc0204ab6:	ec26                	sd	s1,24(sp)
ffffffffc0204ab8:	e84a                	sd	s2,16(sp)
ffffffffc0204aba:	f406                	sd	ra,40(sp)
ffffffffc0204abc:	e44e                	sd	s3,8(sp)
ffffffffc0204abe:	84aa                	mv	s1,a0
ffffffffc0204ac0:	892e                	mv	s2,a1
ffffffffc0204ac2:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0204ac6:	2a01                	sext.w	s4,s4

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
ffffffffc0204ac8:	03067e63          	bgeu	a2,a6,ffffffffc0204b04 <printnum+0x60>
ffffffffc0204acc:	89be                	mv	s3,a5
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0204ace:	00805763          	blez	s0,ffffffffc0204adc <printnum+0x38>
ffffffffc0204ad2:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0204ad4:	85ca                	mv	a1,s2
ffffffffc0204ad6:	854e                	mv	a0,s3
ffffffffc0204ad8:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0204ada:	fc65                	bnez	s0,ffffffffc0204ad2 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0204adc:	1a02                	slli	s4,s4,0x20
ffffffffc0204ade:	020a5a13          	srli	s4,s4,0x20
ffffffffc0204ae2:	00002797          	auipc	a5,0x2
ffffffffc0204ae6:	48e78793          	addi	a5,a5,1166 # ffffffffc0206f70 <error_string+0x38>
ffffffffc0204aea:	9a3e                	add	s4,s4,a5
}
ffffffffc0204aec:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0204aee:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0204af2:	70a2                	ld	ra,40(sp)
ffffffffc0204af4:	69a2                	ld	s3,8(sp)
ffffffffc0204af6:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0204af8:	85ca                	mv	a1,s2
ffffffffc0204afa:	8326                	mv	t1,s1
}
ffffffffc0204afc:	6942                	ld	s2,16(sp)
ffffffffc0204afe:	64e2                	ld	s1,24(sp)
ffffffffc0204b00:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0204b02:	8302                	jr	t1
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0204b04:	03065633          	divu	a2,a2,a6
ffffffffc0204b08:	8722                	mv	a4,s0
ffffffffc0204b0a:	f9bff0ef          	jal	ra,ffffffffc0204aa4 <printnum>
ffffffffc0204b0e:	b7f9                	j	ffffffffc0204adc <printnum+0x38>

ffffffffc0204b10 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0204b10:	7119                	addi	sp,sp,-128
ffffffffc0204b12:	f4a6                	sd	s1,104(sp)
ffffffffc0204b14:	f0ca                	sd	s2,96(sp)
ffffffffc0204b16:	e8d2                	sd	s4,80(sp)
ffffffffc0204b18:	e4d6                	sd	s5,72(sp)
ffffffffc0204b1a:	e0da                	sd	s6,64(sp)
ffffffffc0204b1c:	fc5e                	sd	s7,56(sp)
ffffffffc0204b1e:	f862                	sd	s8,48(sp)
ffffffffc0204b20:	f06a                	sd	s10,32(sp)
ffffffffc0204b22:	fc86                	sd	ra,120(sp)
ffffffffc0204b24:	f8a2                	sd	s0,112(sp)
ffffffffc0204b26:	ecce                	sd	s3,88(sp)
ffffffffc0204b28:	f466                	sd	s9,40(sp)
ffffffffc0204b2a:	ec6e                	sd	s11,24(sp)
ffffffffc0204b2c:	892a                	mv	s2,a0
ffffffffc0204b2e:	84ae                	mv	s1,a1
ffffffffc0204b30:	8d32                	mv	s10,a2
ffffffffc0204b32:	8ab6                	mv	s5,a3
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0204b34:	5b7d                	li	s6,-1
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204b36:	00002a17          	auipc	s4,0x2
ffffffffc0204b3a:	2aaa0a13          	addi	s4,s4,682 # ffffffffc0206de0 <default_pmm_manager+0x288>
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0204b3e:	05e00b93          	li	s7,94
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0204b42:	00002c17          	auipc	s8,0x2
ffffffffc0204b46:	3f6c0c13          	addi	s8,s8,1014 # ffffffffc0206f38 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0204b4a:	000d4503          	lbu	a0,0(s10) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
ffffffffc0204b4e:	02500793          	li	a5,37
ffffffffc0204b52:	001d0413          	addi	s0,s10,1
ffffffffc0204b56:	00f50e63          	beq	a0,a5,ffffffffc0204b72 <vprintfmt+0x62>
            if (ch == '\0') {
ffffffffc0204b5a:	c521                	beqz	a0,ffffffffc0204ba2 <vprintfmt+0x92>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0204b5c:	02500993          	li	s3,37
ffffffffc0204b60:	a011                	j	ffffffffc0204b64 <vprintfmt+0x54>
            if (ch == '\0') {
ffffffffc0204b62:	c121                	beqz	a0,ffffffffc0204ba2 <vprintfmt+0x92>
            putch(ch, putdat);
ffffffffc0204b64:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0204b66:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0204b68:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0204b6a:	fff44503          	lbu	a0,-1(s0)
ffffffffc0204b6e:	ff351ae3          	bne	a0,s3,ffffffffc0204b62 <vprintfmt+0x52>
ffffffffc0204b72:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0204b76:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0204b7a:	4981                	li	s3,0
ffffffffc0204b7c:	4801                	li	a6,0
        width = precision = -1;
ffffffffc0204b7e:	5cfd                	li	s9,-1
ffffffffc0204b80:	5dfd                	li	s11,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204b82:	05500593          	li	a1,85
                if (ch < '0' || ch > '9') {
ffffffffc0204b86:	4525                	li	a0,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204b88:	fdd6069b          	addiw	a3,a2,-35
ffffffffc0204b8c:	0ff6f693          	andi	a3,a3,255
ffffffffc0204b90:	00140d13          	addi	s10,s0,1
ffffffffc0204b94:	1ed5ef63          	bltu	a1,a3,ffffffffc0204d92 <vprintfmt+0x282>
ffffffffc0204b98:	068a                	slli	a3,a3,0x2
ffffffffc0204b9a:	96d2                	add	a3,a3,s4
ffffffffc0204b9c:	4294                	lw	a3,0(a3)
ffffffffc0204b9e:	96d2                	add	a3,a3,s4
ffffffffc0204ba0:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0204ba2:	70e6                	ld	ra,120(sp)
ffffffffc0204ba4:	7446                	ld	s0,112(sp)
ffffffffc0204ba6:	74a6                	ld	s1,104(sp)
ffffffffc0204ba8:	7906                	ld	s2,96(sp)
ffffffffc0204baa:	69e6                	ld	s3,88(sp)
ffffffffc0204bac:	6a46                	ld	s4,80(sp)
ffffffffc0204bae:	6aa6                	ld	s5,72(sp)
ffffffffc0204bb0:	6b06                	ld	s6,64(sp)
ffffffffc0204bb2:	7be2                	ld	s7,56(sp)
ffffffffc0204bb4:	7c42                	ld	s8,48(sp)
ffffffffc0204bb6:	7ca2                	ld	s9,40(sp)
ffffffffc0204bb8:	7d02                	ld	s10,32(sp)
ffffffffc0204bba:	6de2                	ld	s11,24(sp)
ffffffffc0204bbc:	6109                	addi	sp,sp,128
ffffffffc0204bbe:	8082                	ret
            padc = '-';
ffffffffc0204bc0:	87b2                	mv	a5,a2
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204bc2:	00144603          	lbu	a2,1(s0)
ffffffffc0204bc6:	846a                	mv	s0,s10
ffffffffc0204bc8:	b7c1                	j	ffffffffc0204b88 <vprintfmt+0x78>
            precision = va_arg(ap, int);
ffffffffc0204bca:	000aac83          	lw	s9,0(s5)
            goto process_precision;
ffffffffc0204bce:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0204bd2:	0aa1                	addi	s5,s5,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204bd4:	846a                	mv	s0,s10
            if (width < 0)
ffffffffc0204bd6:	fa0dd9e3          	bgez	s11,ffffffffc0204b88 <vprintfmt+0x78>
                width = precision, precision = -1;
ffffffffc0204bda:	8de6                	mv	s11,s9
ffffffffc0204bdc:	5cfd                	li	s9,-1
ffffffffc0204bde:	b76d                	j	ffffffffc0204b88 <vprintfmt+0x78>
            if (width < 0)
ffffffffc0204be0:	fffdc693          	not	a3,s11
ffffffffc0204be4:	96fd                	srai	a3,a3,0x3f
ffffffffc0204be6:	00ddfdb3          	and	s11,s11,a3
ffffffffc0204bea:	00144603          	lbu	a2,1(s0)
ffffffffc0204bee:	2d81                	sext.w	s11,s11
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204bf0:	846a                	mv	s0,s10
ffffffffc0204bf2:	bf59                	j	ffffffffc0204b88 <vprintfmt+0x78>
    if (lflag >= 2) {
ffffffffc0204bf4:	4705                	li	a4,1
ffffffffc0204bf6:	008a8593          	addi	a1,s5,8
ffffffffc0204bfa:	01074463          	blt	a4,a6,ffffffffc0204c02 <vprintfmt+0xf2>
    else if (lflag) {
ffffffffc0204bfe:	22080863          	beqz	a6,ffffffffc0204e2e <vprintfmt+0x31e>
        return va_arg(*ap, unsigned long);
ffffffffc0204c02:	000ab603          	ld	a2,0(s5)
ffffffffc0204c06:	46c1                	li	a3,16
ffffffffc0204c08:	8aae                	mv	s5,a1
ffffffffc0204c0a:	a291                	j	ffffffffc0204d4e <vprintfmt+0x23e>
                precision = precision * 10 + ch - '0';
ffffffffc0204c0c:	fd060c9b          	addiw	s9,a2,-48
                ch = *fmt;
ffffffffc0204c10:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204c14:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0204c16:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0204c1a:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc0204c1e:	fad56ce3          	bltu	a0,a3,ffffffffc0204bd6 <vprintfmt+0xc6>
            for (precision = 0; ; ++ fmt) {
ffffffffc0204c22:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0204c24:	002c969b          	slliw	a3,s9,0x2
                ch = *fmt;
ffffffffc0204c28:	00044603          	lbu	a2,0(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0204c2c:	0196873b          	addw	a4,a3,s9
ffffffffc0204c30:	0017171b          	slliw	a4,a4,0x1
ffffffffc0204c34:	0117073b          	addw	a4,a4,a7
                if (ch < '0' || ch > '9') {
ffffffffc0204c38:	fd06069b          	addiw	a3,a2,-48
                precision = precision * 10 + ch - '0';
ffffffffc0204c3c:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc0204c40:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc0204c44:	fcd57fe3          	bgeu	a0,a3,ffffffffc0204c22 <vprintfmt+0x112>
ffffffffc0204c48:	b779                	j	ffffffffc0204bd6 <vprintfmt+0xc6>
            putch(va_arg(ap, int), putdat);
ffffffffc0204c4a:	000aa503          	lw	a0,0(s5)
ffffffffc0204c4e:	85a6                	mv	a1,s1
ffffffffc0204c50:	0aa1                	addi	s5,s5,8
ffffffffc0204c52:	9902                	jalr	s2
            break;
ffffffffc0204c54:	bddd                	j	ffffffffc0204b4a <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0204c56:	4705                	li	a4,1
ffffffffc0204c58:	008a8993          	addi	s3,s5,8
ffffffffc0204c5c:	01074463          	blt	a4,a6,ffffffffc0204c64 <vprintfmt+0x154>
    else if (lflag) {
ffffffffc0204c60:	1c080463          	beqz	a6,ffffffffc0204e28 <vprintfmt+0x318>
        return va_arg(*ap, long);
ffffffffc0204c64:	000ab403          	ld	s0,0(s5)
            if ((long long)num < 0) {
ffffffffc0204c68:	1c044a63          	bltz	s0,ffffffffc0204e3c <vprintfmt+0x32c>
            num = getint(&ap, lflag);
ffffffffc0204c6c:	8622                	mv	a2,s0
ffffffffc0204c6e:	8ace                	mv	s5,s3
ffffffffc0204c70:	46a9                	li	a3,10
ffffffffc0204c72:	a8f1                	j	ffffffffc0204d4e <vprintfmt+0x23e>
            err = va_arg(ap, int);
ffffffffc0204c74:	000aa783          	lw	a5,0(s5)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0204c78:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0204c7a:	0aa1                	addi	s5,s5,8
            if (err < 0) {
ffffffffc0204c7c:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0204c80:	8fb5                	xor	a5,a5,a3
ffffffffc0204c82:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0204c86:	12d74963          	blt	a4,a3,ffffffffc0204db8 <vprintfmt+0x2a8>
ffffffffc0204c8a:	00369793          	slli	a5,a3,0x3
ffffffffc0204c8e:	97e2                	add	a5,a5,s8
ffffffffc0204c90:	639c                	ld	a5,0(a5)
ffffffffc0204c92:	12078363          	beqz	a5,ffffffffc0204db8 <vprintfmt+0x2a8>
                printfmt(putch, putdat, "%s", p);
ffffffffc0204c96:	86be                	mv	a3,a5
ffffffffc0204c98:	00000617          	auipc	a2,0x0
ffffffffc0204c9c:	23860613          	addi	a2,a2,568 # ffffffffc0204ed0 <etext+0x28>
ffffffffc0204ca0:	85a6                	mv	a1,s1
ffffffffc0204ca2:	854a                	mv	a0,s2
ffffffffc0204ca4:	1cc000ef          	jal	ra,ffffffffc0204e70 <printfmt>
ffffffffc0204ca8:	b54d                	j	ffffffffc0204b4a <vprintfmt+0x3a>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0204caa:	000ab603          	ld	a2,0(s5)
ffffffffc0204cae:	0aa1                	addi	s5,s5,8
ffffffffc0204cb0:	1a060163          	beqz	a2,ffffffffc0204e52 <vprintfmt+0x342>
            if (width > 0 && padc != '-') {
ffffffffc0204cb4:	00160413          	addi	s0,a2,1
ffffffffc0204cb8:	15b05763          	blez	s11,ffffffffc0204e06 <vprintfmt+0x2f6>
ffffffffc0204cbc:	02d00593          	li	a1,45
ffffffffc0204cc0:	10b79d63          	bne	a5,a1,ffffffffc0204dda <vprintfmt+0x2ca>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204cc4:	00064783          	lbu	a5,0(a2)
ffffffffc0204cc8:	0007851b          	sext.w	a0,a5
ffffffffc0204ccc:	c905                	beqz	a0,ffffffffc0204cfc <vprintfmt+0x1ec>
ffffffffc0204cce:	000cc563          	bltz	s9,ffffffffc0204cd8 <vprintfmt+0x1c8>
ffffffffc0204cd2:	3cfd                	addiw	s9,s9,-1
ffffffffc0204cd4:	036c8263          	beq	s9,s6,ffffffffc0204cf8 <vprintfmt+0x1e8>
                    putch('?', putdat);
ffffffffc0204cd8:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0204cda:	14098f63          	beqz	s3,ffffffffc0204e38 <vprintfmt+0x328>
ffffffffc0204cde:	3781                	addiw	a5,a5,-32
ffffffffc0204ce0:	14fbfc63          	bgeu	s7,a5,ffffffffc0204e38 <vprintfmt+0x328>
                    putch('?', putdat);
ffffffffc0204ce4:	03f00513          	li	a0,63
ffffffffc0204ce8:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204cea:	0405                	addi	s0,s0,1
ffffffffc0204cec:	fff44783          	lbu	a5,-1(s0)
ffffffffc0204cf0:	3dfd                	addiw	s11,s11,-1
ffffffffc0204cf2:	0007851b          	sext.w	a0,a5
ffffffffc0204cf6:	fd61                	bnez	a0,ffffffffc0204cce <vprintfmt+0x1be>
            for (; width > 0; width --) {
ffffffffc0204cf8:	e5b059e3          	blez	s11,ffffffffc0204b4a <vprintfmt+0x3a>
ffffffffc0204cfc:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0204cfe:	85a6                	mv	a1,s1
ffffffffc0204d00:	02000513          	li	a0,32
ffffffffc0204d04:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0204d06:	e40d82e3          	beqz	s11,ffffffffc0204b4a <vprintfmt+0x3a>
ffffffffc0204d0a:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0204d0c:	85a6                	mv	a1,s1
ffffffffc0204d0e:	02000513          	li	a0,32
ffffffffc0204d12:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0204d14:	fe0d94e3          	bnez	s11,ffffffffc0204cfc <vprintfmt+0x1ec>
ffffffffc0204d18:	bd0d                	j	ffffffffc0204b4a <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0204d1a:	4705                	li	a4,1
ffffffffc0204d1c:	008a8593          	addi	a1,s5,8
ffffffffc0204d20:	01074463          	blt	a4,a6,ffffffffc0204d28 <vprintfmt+0x218>
    else if (lflag) {
ffffffffc0204d24:	0e080863          	beqz	a6,ffffffffc0204e14 <vprintfmt+0x304>
        return va_arg(*ap, unsigned long);
ffffffffc0204d28:	000ab603          	ld	a2,0(s5)
ffffffffc0204d2c:	46a1                	li	a3,8
ffffffffc0204d2e:	8aae                	mv	s5,a1
ffffffffc0204d30:	a839                	j	ffffffffc0204d4e <vprintfmt+0x23e>
            putch('0', putdat);
ffffffffc0204d32:	03000513          	li	a0,48
ffffffffc0204d36:	85a6                	mv	a1,s1
ffffffffc0204d38:	e03e                	sd	a5,0(sp)
ffffffffc0204d3a:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0204d3c:	85a6                	mv	a1,s1
ffffffffc0204d3e:	07800513          	li	a0,120
ffffffffc0204d42:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0204d44:	0aa1                	addi	s5,s5,8
ffffffffc0204d46:	ff8ab603          	ld	a2,-8(s5)
            goto number;
ffffffffc0204d4a:	6782                	ld	a5,0(sp)
ffffffffc0204d4c:	46c1                	li	a3,16
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0204d4e:	2781                	sext.w	a5,a5
ffffffffc0204d50:	876e                	mv	a4,s11
ffffffffc0204d52:	85a6                	mv	a1,s1
ffffffffc0204d54:	854a                	mv	a0,s2
ffffffffc0204d56:	d4fff0ef          	jal	ra,ffffffffc0204aa4 <printnum>
            break;
ffffffffc0204d5a:	bbc5                	j	ffffffffc0204b4a <vprintfmt+0x3a>
            lflag ++;
ffffffffc0204d5c:	00144603          	lbu	a2,1(s0)
ffffffffc0204d60:	2805                	addiw	a6,a6,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204d62:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0204d64:	b515                	j	ffffffffc0204b88 <vprintfmt+0x78>
            goto reswitch;
ffffffffc0204d66:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0204d6a:	4985                	li	s3,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204d6c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0204d6e:	bd29                	j	ffffffffc0204b88 <vprintfmt+0x78>
            putch(ch, putdat);
ffffffffc0204d70:	85a6                	mv	a1,s1
ffffffffc0204d72:	02500513          	li	a0,37
ffffffffc0204d76:	9902                	jalr	s2
            break;
ffffffffc0204d78:	bbc9                	j	ffffffffc0204b4a <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0204d7a:	4705                	li	a4,1
ffffffffc0204d7c:	008a8593          	addi	a1,s5,8
ffffffffc0204d80:	01074463          	blt	a4,a6,ffffffffc0204d88 <vprintfmt+0x278>
    else if (lflag) {
ffffffffc0204d84:	08080d63          	beqz	a6,ffffffffc0204e1e <vprintfmt+0x30e>
        return va_arg(*ap, unsigned long);
ffffffffc0204d88:	000ab603          	ld	a2,0(s5)
ffffffffc0204d8c:	46a9                	li	a3,10
ffffffffc0204d8e:	8aae                	mv	s5,a1
ffffffffc0204d90:	bf7d                	j	ffffffffc0204d4e <vprintfmt+0x23e>
            putch('%', putdat);
ffffffffc0204d92:	85a6                	mv	a1,s1
ffffffffc0204d94:	02500513          	li	a0,37
ffffffffc0204d98:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0204d9a:	fff44703          	lbu	a4,-1(s0)
ffffffffc0204d9e:	02500793          	li	a5,37
ffffffffc0204da2:	8d22                	mv	s10,s0
ffffffffc0204da4:	daf703e3          	beq	a4,a5,ffffffffc0204b4a <vprintfmt+0x3a>
ffffffffc0204da8:	02500713          	li	a4,37
ffffffffc0204dac:	1d7d                	addi	s10,s10,-1
ffffffffc0204dae:	fffd4783          	lbu	a5,-1(s10)
ffffffffc0204db2:	fee79de3          	bne	a5,a4,ffffffffc0204dac <vprintfmt+0x29c>
ffffffffc0204db6:	bb51                	j	ffffffffc0204b4a <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0204db8:	00002617          	auipc	a2,0x2
ffffffffc0204dbc:	25860613          	addi	a2,a2,600 # ffffffffc0207010 <error_string+0xd8>
ffffffffc0204dc0:	85a6                	mv	a1,s1
ffffffffc0204dc2:	854a                	mv	a0,s2
ffffffffc0204dc4:	0ac000ef          	jal	ra,ffffffffc0204e70 <printfmt>
ffffffffc0204dc8:	b349                	j	ffffffffc0204b4a <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0204dca:	00002617          	auipc	a2,0x2
ffffffffc0204dce:	23e60613          	addi	a2,a2,574 # ffffffffc0207008 <error_string+0xd0>
            if (width > 0 && padc != '-') {
ffffffffc0204dd2:	00002417          	auipc	s0,0x2
ffffffffc0204dd6:	23740413          	addi	s0,s0,567 # ffffffffc0207009 <error_string+0xd1>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0204dda:	8532                	mv	a0,a2
ffffffffc0204ddc:	85e6                	mv	a1,s9
ffffffffc0204dde:	e032                	sd	a2,0(sp)
ffffffffc0204de0:	e43e                	sd	a5,8(sp)
ffffffffc0204de2:	be9ff0ef          	jal	ra,ffffffffc02049ca <strnlen>
ffffffffc0204de6:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0204dea:	6602                	ld	a2,0(sp)
ffffffffc0204dec:	01b05d63          	blez	s11,ffffffffc0204e06 <vprintfmt+0x2f6>
ffffffffc0204df0:	67a2                	ld	a5,8(sp)
ffffffffc0204df2:	2781                	sext.w	a5,a5
ffffffffc0204df4:	e43e                	sd	a5,8(sp)
                    putch(padc, putdat);
ffffffffc0204df6:	6522                	ld	a0,8(sp)
ffffffffc0204df8:	85a6                	mv	a1,s1
ffffffffc0204dfa:	e032                	sd	a2,0(sp)
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0204dfc:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0204dfe:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0204e00:	6602                	ld	a2,0(sp)
ffffffffc0204e02:	fe0d9ae3          	bnez	s11,ffffffffc0204df6 <vprintfmt+0x2e6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204e06:	00064783          	lbu	a5,0(a2)
ffffffffc0204e0a:	0007851b          	sext.w	a0,a5
ffffffffc0204e0e:	ec0510e3          	bnez	a0,ffffffffc0204cce <vprintfmt+0x1be>
ffffffffc0204e12:	bb25                	j	ffffffffc0204b4a <vprintfmt+0x3a>
        return va_arg(*ap, unsigned int);
ffffffffc0204e14:	000ae603          	lwu	a2,0(s5)
ffffffffc0204e18:	46a1                	li	a3,8
ffffffffc0204e1a:	8aae                	mv	s5,a1
ffffffffc0204e1c:	bf0d                	j	ffffffffc0204d4e <vprintfmt+0x23e>
ffffffffc0204e1e:	000ae603          	lwu	a2,0(s5)
ffffffffc0204e22:	46a9                	li	a3,10
ffffffffc0204e24:	8aae                	mv	s5,a1
ffffffffc0204e26:	b725                	j	ffffffffc0204d4e <vprintfmt+0x23e>
        return va_arg(*ap, int);
ffffffffc0204e28:	000aa403          	lw	s0,0(s5)
ffffffffc0204e2c:	bd35                	j	ffffffffc0204c68 <vprintfmt+0x158>
        return va_arg(*ap, unsigned int);
ffffffffc0204e2e:	000ae603          	lwu	a2,0(s5)
ffffffffc0204e32:	46c1                	li	a3,16
ffffffffc0204e34:	8aae                	mv	s5,a1
ffffffffc0204e36:	bf21                	j	ffffffffc0204d4e <vprintfmt+0x23e>
                    putch(ch, putdat);
ffffffffc0204e38:	9902                	jalr	s2
ffffffffc0204e3a:	bd45                	j	ffffffffc0204cea <vprintfmt+0x1da>
                putch('-', putdat);
ffffffffc0204e3c:	85a6                	mv	a1,s1
ffffffffc0204e3e:	02d00513          	li	a0,45
ffffffffc0204e42:	e03e                	sd	a5,0(sp)
ffffffffc0204e44:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0204e46:	8ace                	mv	s5,s3
ffffffffc0204e48:	40800633          	neg	a2,s0
ffffffffc0204e4c:	46a9                	li	a3,10
ffffffffc0204e4e:	6782                	ld	a5,0(sp)
ffffffffc0204e50:	bdfd                	j	ffffffffc0204d4e <vprintfmt+0x23e>
            if (width > 0 && padc != '-') {
ffffffffc0204e52:	01b05663          	blez	s11,ffffffffc0204e5e <vprintfmt+0x34e>
ffffffffc0204e56:	02d00693          	li	a3,45
ffffffffc0204e5a:	f6d798e3          	bne	a5,a3,ffffffffc0204dca <vprintfmt+0x2ba>
ffffffffc0204e5e:	00002417          	auipc	s0,0x2
ffffffffc0204e62:	1ab40413          	addi	s0,s0,427 # ffffffffc0207009 <error_string+0xd1>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204e66:	02800513          	li	a0,40
ffffffffc0204e6a:	02800793          	li	a5,40
ffffffffc0204e6e:	b585                	j	ffffffffc0204cce <vprintfmt+0x1be>

ffffffffc0204e70 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0204e70:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0204e72:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0204e76:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0204e78:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0204e7a:	ec06                	sd	ra,24(sp)
ffffffffc0204e7c:	f83a                	sd	a4,48(sp)
ffffffffc0204e7e:	fc3e                	sd	a5,56(sp)
ffffffffc0204e80:	e0c2                	sd	a6,64(sp)
ffffffffc0204e82:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0204e84:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0204e86:	c8bff0ef          	jal	ra,ffffffffc0204b10 <vprintfmt>
}
ffffffffc0204e8a:	60e2                	ld	ra,24(sp)
ffffffffc0204e8c:	6161                	addi	sp,sp,80
ffffffffc0204e8e:	8082                	ret

ffffffffc0204e90 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc0204e90:	9e3707b7          	lui	a5,0x9e370
ffffffffc0204e94:	2785                	addiw	a5,a5,1
ffffffffc0204e96:	02f5053b          	mulw	a0,a0,a5
    return (hash >> (32 - bits));
ffffffffc0204e9a:	02000793          	li	a5,32
ffffffffc0204e9e:	40b785bb          	subw	a1,a5,a1
}
ffffffffc0204ea2:	00b5553b          	srlw	a0,a0,a1
ffffffffc0204ea6:	8082                	ret
