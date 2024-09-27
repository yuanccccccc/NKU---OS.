
bin/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000080200000 <kern_entry>:
#include <memlayout.h>

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    la sp, bootstacktop
    80200000:	00004117          	auipc	sp,0x4
    80200004:	00010113          	mv	sp,sp

    tail kern_init
    80200008:	a009                	j	8020000a <kern_init>

000000008020000a <kern_init>:
int kern_init(void) __attribute__((noreturn));
void grade_backtrace(void);

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
    8020000a:	00004517          	auipc	a0,0x4
    8020000e:	00650513          	addi	a0,a0,6 # 80204010 <edata>
    80200012:	00004617          	auipc	a2,0x4
    80200016:	01e60613          	addi	a2,a2,30 # 80204030 <end>
int kern_init(void) {
    8020001a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
    8020001c:	8e09                	sub	a2,a2,a0
    8020001e:	4581                	li	a1,0
int kern_init(void) {
    80200020:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
    80200022:	5ce000ef          	jal	ra,802005f0 <memset>

    cons_init();  // init the console
    80200026:	14e000ef          	jal	ra,80200174 <cons_init>

    const char *message = "(THU.CST) os is loading ...\n";
    cprintf("%s\n\n", message);
    8020002a:	00001597          	auipc	a1,0x1
    8020002e:	a1e58593          	addi	a1,a1,-1506 # 80200a48 <etext+0x6>
    80200032:	00001517          	auipc	a0,0x1
    80200036:	a3650513          	addi	a0,a0,-1482 # 80200a68 <etext+0x26>
    8020003a:	036000ef          	jal	ra,80200070 <cprintf>

    print_kerninfo();
    8020003e:	066000ef          	jal	ra,802000a4 <print_kerninfo>

    // grade_backtrace();

    idt_init();  // init interrupt descriptor table
    80200042:	142000ef          	jal	ra,80200184 <idt_init>

    // rdtime in mbare mode crashes
    clock_init();  // init clock interrupt
    80200046:	0ec000ef          	jal	ra,80200132 <clock_init>

    intr_enable();  // enable irq interrupt
    8020004a:	134000ef          	jal	ra,8020017e <intr_enable>
    asm("mret");// 测试非法指令异常
    8020004e:	30200073          	mret
    asm("ebreak");// 测试断点异常
    80200052:	9002                	ebreak
    
    while (1)
        ;
    80200054:	a001                	j	80200054 <kern_init+0x4a>

0000000080200056 <cputch>:

/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void cputch(int c, int *cnt) {
    80200056:	1141                	addi	sp,sp,-16
    80200058:	e022                	sd	s0,0(sp)
    8020005a:	e406                	sd	ra,8(sp)
    8020005c:	842e                	mv	s0,a1
    cons_putc(c);
    8020005e:	118000ef          	jal	ra,80200176 <cons_putc>
    (*cnt)++;
    80200062:	401c                	lw	a5,0(s0)
}
    80200064:	60a2                	ld	ra,8(sp)
    (*cnt)++;
    80200066:	2785                	addiw	a5,a5,1
    80200068:	c01c                	sw	a5,0(s0)
}
    8020006a:	6402                	ld	s0,0(sp)
    8020006c:	0141                	addi	sp,sp,16
    8020006e:	8082                	ret

0000000080200070 <cprintf>:
 * cprintf - formats a string and writes it to stdout
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...) {
    80200070:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
    80200072:	02810313          	addi	t1,sp,40 # 80204028 <ticks>
int cprintf(const char *fmt, ...) {
    80200076:	f42e                	sd	a1,40(sp)
    80200078:	f832                	sd	a2,48(sp)
    8020007a:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
    8020007c:	862a                	mv	a2,a0
    8020007e:	004c                	addi	a1,sp,4
    80200080:	00000517          	auipc	a0,0x0
    80200084:	fd650513          	addi	a0,a0,-42 # 80200056 <cputch>
    80200088:	869a                	mv	a3,t1
int cprintf(const char *fmt, ...) {
    8020008a:	ec06                	sd	ra,24(sp)
    8020008c:	e0ba                	sd	a4,64(sp)
    8020008e:	e4be                	sd	a5,72(sp)
    80200090:	e8c2                	sd	a6,80(sp)
    80200092:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
    80200094:	e41a                	sd	t1,8(sp)
    int cnt = 0;
    80200096:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
    80200098:	5d6000ef          	jal	ra,8020066e <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
    8020009c:	60e2                	ld	ra,24(sp)
    8020009e:	4512                	lw	a0,4(sp)
    802000a0:	6125                	addi	sp,sp,96
    802000a2:	8082                	ret

00000000802000a4 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
    802000a4:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
    802000a6:	00001517          	auipc	a0,0x1
    802000aa:	9ca50513          	addi	a0,a0,-1590 # 80200a70 <etext+0x2e>
void print_kerninfo(void) {
    802000ae:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
    802000b0:	fc1ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  entry  0x%016x (virtual)\n", kern_init);
    802000b4:	00000597          	auipc	a1,0x0
    802000b8:	f5658593          	addi	a1,a1,-170 # 8020000a <kern_init>
    802000bc:	00001517          	auipc	a0,0x1
    802000c0:	9d450513          	addi	a0,a0,-1580 # 80200a90 <etext+0x4e>
    802000c4:	fadff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  etext  0x%016x (virtual)\n", etext);
    802000c8:	00001597          	auipc	a1,0x1
    802000cc:	97a58593          	addi	a1,a1,-1670 # 80200a42 <etext>
    802000d0:	00001517          	auipc	a0,0x1
    802000d4:	9e050513          	addi	a0,a0,-1568 # 80200ab0 <etext+0x6e>
    802000d8:	f99ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  edata  0x%016x (virtual)\n", edata);
    802000dc:	00004597          	auipc	a1,0x4
    802000e0:	f3458593          	addi	a1,a1,-204 # 80204010 <edata>
    802000e4:	00001517          	auipc	a0,0x1
    802000e8:	9ec50513          	addi	a0,a0,-1556 # 80200ad0 <etext+0x8e>
    802000ec:	f85ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  end    0x%016x (virtual)\n", end);
    802000f0:	00004597          	auipc	a1,0x4
    802000f4:	f4058593          	addi	a1,a1,-192 # 80204030 <end>
    802000f8:	00001517          	auipc	a0,0x1
    802000fc:	9f850513          	addi	a0,a0,-1544 # 80200af0 <etext+0xae>
    80200100:	f71ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
    80200104:	00004597          	auipc	a1,0x4
    80200108:	32b58593          	addi	a1,a1,811 # 8020442f <end+0x3ff>
    8020010c:	00000797          	auipc	a5,0x0
    80200110:	efe78793          	addi	a5,a5,-258 # 8020000a <kern_init>
    80200114:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
    80200118:	43f7d593          	srai	a1,a5,0x3f
}
    8020011c:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
    8020011e:	3ff5f593          	andi	a1,a1,1023
    80200122:	95be                	add	a1,a1,a5
    80200124:	85a9                	srai	a1,a1,0xa
    80200126:	00001517          	auipc	a0,0x1
    8020012a:	9ea50513          	addi	a0,a0,-1558 # 80200b10 <etext+0xce>
}
    8020012e:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
    80200130:	b781                	j	80200070 <cprintf>

0000000080200132 <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    80200132:	1141                	addi	sp,sp,-16
    80200134:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
    80200136:	02000793          	li	a5,32
    8020013a:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
    8020013e:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
    80200142:	67e1                	lui	a5,0x18
    80200144:	6a078793          	addi	a5,a5,1696 # 186a0 <BASE_ADDRESS-0x801e7960>
    80200148:	953e                	add	a0,a0,a5
    8020014a:	0c1000ef          	jal	ra,80200a0a <sbi_set_timer>
}
    8020014e:	60a2                	ld	ra,8(sp)
    ticks = 0;
    80200150:	00004797          	auipc	a5,0x4
    80200154:	ec07bc23          	sd	zero,-296(a5) # 80204028 <ticks>
    cprintf("++ setup timer interrupts\n");
    80200158:	00001517          	auipc	a0,0x1
    8020015c:	9e850513          	addi	a0,a0,-1560 # 80200b40 <etext+0xfe>
}
    80200160:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
    80200162:	b739                	j	80200070 <cprintf>

0000000080200164 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
    80200164:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
    80200168:	67e1                	lui	a5,0x18
    8020016a:	6a078793          	addi	a5,a5,1696 # 186a0 <BASE_ADDRESS-0x801e7960>
    8020016e:	953e                	add	a0,a0,a5
    80200170:	09b0006f          	j	80200a0a <sbi_set_timer>

0000000080200174 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
    80200174:	8082                	ret

0000000080200176 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
    80200176:	0ff57513          	andi	a0,a0,255
    8020017a:	0750006f          	j	802009ee <sbi_console_putchar>

000000008020017e <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
    8020017e:	100167f3          	csrrsi	a5,sstatus,2
    80200182:	8082                	ret

0000000080200184 <idt_init>:

void idt_init(void) {
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
    80200184:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
    80200188:	00000797          	auipc	a5,0x0
    8020018c:	38c78793          	addi	a5,a5,908 # 80200514 <__alltraps>
    80200190:	10579073          	csrw	stvec,a5
}
    80200194:	8082                	ret

0000000080200196 <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
    80200196:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
    80200198:	1141                	addi	sp,sp,-16
    8020019a:	e022                	sd	s0,0(sp)
    8020019c:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
    8020019e:	00001517          	auipc	a0,0x1
    802001a2:	b3250513          	addi	a0,a0,-1230 # 80200cd0 <etext+0x28e>
void print_regs(struct pushregs *gpr) {
    802001a6:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
    802001a8:	ec9ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
    802001ac:	640c                	ld	a1,8(s0)
    802001ae:	00001517          	auipc	a0,0x1
    802001b2:	b3a50513          	addi	a0,a0,-1222 # 80200ce8 <etext+0x2a6>
    802001b6:	ebbff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
    802001ba:	680c                	ld	a1,16(s0)
    802001bc:	00001517          	auipc	a0,0x1
    802001c0:	b4450513          	addi	a0,a0,-1212 # 80200d00 <etext+0x2be>
    802001c4:	eadff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
    802001c8:	6c0c                	ld	a1,24(s0)
    802001ca:	00001517          	auipc	a0,0x1
    802001ce:	b4e50513          	addi	a0,a0,-1202 # 80200d18 <etext+0x2d6>
    802001d2:	e9fff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
    802001d6:	700c                	ld	a1,32(s0)
    802001d8:	00001517          	auipc	a0,0x1
    802001dc:	b5850513          	addi	a0,a0,-1192 # 80200d30 <etext+0x2ee>
    802001e0:	e91ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
    802001e4:	740c                	ld	a1,40(s0)
    802001e6:	00001517          	auipc	a0,0x1
    802001ea:	b6250513          	addi	a0,a0,-1182 # 80200d48 <etext+0x306>
    802001ee:	e83ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
    802001f2:	780c                	ld	a1,48(s0)
    802001f4:	00001517          	auipc	a0,0x1
    802001f8:	b6c50513          	addi	a0,a0,-1172 # 80200d60 <etext+0x31e>
    802001fc:	e75ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
    80200200:	7c0c                	ld	a1,56(s0)
    80200202:	00001517          	auipc	a0,0x1
    80200206:	b7650513          	addi	a0,a0,-1162 # 80200d78 <etext+0x336>
    8020020a:	e67ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
    8020020e:	602c                	ld	a1,64(s0)
    80200210:	00001517          	auipc	a0,0x1
    80200214:	b8050513          	addi	a0,a0,-1152 # 80200d90 <etext+0x34e>
    80200218:	e59ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
    8020021c:	642c                	ld	a1,72(s0)
    8020021e:	00001517          	auipc	a0,0x1
    80200222:	b8a50513          	addi	a0,a0,-1142 # 80200da8 <etext+0x366>
    80200226:	e4bff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
    8020022a:	682c                	ld	a1,80(s0)
    8020022c:	00001517          	auipc	a0,0x1
    80200230:	b9450513          	addi	a0,a0,-1132 # 80200dc0 <etext+0x37e>
    80200234:	e3dff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
    80200238:	6c2c                	ld	a1,88(s0)
    8020023a:	00001517          	auipc	a0,0x1
    8020023e:	b9e50513          	addi	a0,a0,-1122 # 80200dd8 <etext+0x396>
    80200242:	e2fff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
    80200246:	702c                	ld	a1,96(s0)
    80200248:	00001517          	auipc	a0,0x1
    8020024c:	ba850513          	addi	a0,a0,-1112 # 80200df0 <etext+0x3ae>
    80200250:	e21ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
    80200254:	742c                	ld	a1,104(s0)
    80200256:	00001517          	auipc	a0,0x1
    8020025a:	bb250513          	addi	a0,a0,-1102 # 80200e08 <etext+0x3c6>
    8020025e:	e13ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
    80200262:	782c                	ld	a1,112(s0)
    80200264:	00001517          	auipc	a0,0x1
    80200268:	bbc50513          	addi	a0,a0,-1092 # 80200e20 <etext+0x3de>
    8020026c:	e05ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
    80200270:	7c2c                	ld	a1,120(s0)
    80200272:	00001517          	auipc	a0,0x1
    80200276:	bc650513          	addi	a0,a0,-1082 # 80200e38 <etext+0x3f6>
    8020027a:	df7ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
    8020027e:	604c                	ld	a1,128(s0)
    80200280:	00001517          	auipc	a0,0x1
    80200284:	bd050513          	addi	a0,a0,-1072 # 80200e50 <etext+0x40e>
    80200288:	de9ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
    8020028c:	644c                	ld	a1,136(s0)
    8020028e:	00001517          	auipc	a0,0x1
    80200292:	bda50513          	addi	a0,a0,-1062 # 80200e68 <etext+0x426>
    80200296:	ddbff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
    8020029a:	684c                	ld	a1,144(s0)
    8020029c:	00001517          	auipc	a0,0x1
    802002a0:	be450513          	addi	a0,a0,-1052 # 80200e80 <etext+0x43e>
    802002a4:	dcdff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
    802002a8:	6c4c                	ld	a1,152(s0)
    802002aa:	00001517          	auipc	a0,0x1
    802002ae:	bee50513          	addi	a0,a0,-1042 # 80200e98 <etext+0x456>
    802002b2:	dbfff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
    802002b6:	704c                	ld	a1,160(s0)
    802002b8:	00001517          	auipc	a0,0x1
    802002bc:	bf850513          	addi	a0,a0,-1032 # 80200eb0 <etext+0x46e>
    802002c0:	db1ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
    802002c4:	744c                	ld	a1,168(s0)
    802002c6:	00001517          	auipc	a0,0x1
    802002ca:	c0250513          	addi	a0,a0,-1022 # 80200ec8 <etext+0x486>
    802002ce:	da3ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
    802002d2:	784c                	ld	a1,176(s0)
    802002d4:	00001517          	auipc	a0,0x1
    802002d8:	c0c50513          	addi	a0,a0,-1012 # 80200ee0 <etext+0x49e>
    802002dc:	d95ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
    802002e0:	7c4c                	ld	a1,184(s0)
    802002e2:	00001517          	auipc	a0,0x1
    802002e6:	c1650513          	addi	a0,a0,-1002 # 80200ef8 <etext+0x4b6>
    802002ea:	d87ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
    802002ee:	606c                	ld	a1,192(s0)
    802002f0:	00001517          	auipc	a0,0x1
    802002f4:	c2050513          	addi	a0,a0,-992 # 80200f10 <etext+0x4ce>
    802002f8:	d79ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
    802002fc:	646c                	ld	a1,200(s0)
    802002fe:	00001517          	auipc	a0,0x1
    80200302:	c2a50513          	addi	a0,a0,-982 # 80200f28 <etext+0x4e6>
    80200306:	d6bff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
    8020030a:	686c                	ld	a1,208(s0)
    8020030c:	00001517          	auipc	a0,0x1
    80200310:	c3450513          	addi	a0,a0,-972 # 80200f40 <etext+0x4fe>
    80200314:	d5dff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
    80200318:	6c6c                	ld	a1,216(s0)
    8020031a:	00001517          	auipc	a0,0x1
    8020031e:	c3e50513          	addi	a0,a0,-962 # 80200f58 <etext+0x516>
    80200322:	d4fff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
    80200326:	706c                	ld	a1,224(s0)
    80200328:	00001517          	auipc	a0,0x1
    8020032c:	c4850513          	addi	a0,a0,-952 # 80200f70 <etext+0x52e>
    80200330:	d41ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
    80200334:	746c                	ld	a1,232(s0)
    80200336:	00001517          	auipc	a0,0x1
    8020033a:	c5250513          	addi	a0,a0,-942 # 80200f88 <etext+0x546>
    8020033e:	d33ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
    80200342:	786c                	ld	a1,240(s0)
    80200344:	00001517          	auipc	a0,0x1
    80200348:	c5c50513          	addi	a0,a0,-932 # 80200fa0 <etext+0x55e>
    8020034c:	d25ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
    80200350:	7c6c                	ld	a1,248(s0)
}
    80200352:	6402                	ld	s0,0(sp)
    80200354:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
    80200356:	00001517          	auipc	a0,0x1
    8020035a:	c6250513          	addi	a0,a0,-926 # 80200fb8 <etext+0x576>
}
    8020035e:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
    80200360:	bb01                	j	80200070 <cprintf>

0000000080200362 <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
    80200362:	1141                	addi	sp,sp,-16
    80200364:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
    80200366:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
    80200368:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
    8020036a:	00001517          	auipc	a0,0x1
    8020036e:	c6650513          	addi	a0,a0,-922 # 80200fd0 <etext+0x58e>
void print_trapframe(struct trapframe *tf) {
    80200372:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
    80200374:	cfdff0ef          	jal	ra,80200070 <cprintf>
    print_regs(&tf->gpr);
    80200378:	8522                	mv	a0,s0
    8020037a:	e1dff0ef          	jal	ra,80200196 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
    8020037e:	10043583          	ld	a1,256(s0)
    80200382:	00001517          	auipc	a0,0x1
    80200386:	c6650513          	addi	a0,a0,-922 # 80200fe8 <etext+0x5a6>
    8020038a:	ce7ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
    8020038e:	10843583          	ld	a1,264(s0)
    80200392:	00001517          	auipc	a0,0x1
    80200396:	c6e50513          	addi	a0,a0,-914 # 80201000 <etext+0x5be>
    8020039a:	cd7ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    8020039e:	11043583          	ld	a1,272(s0)
    802003a2:	00001517          	auipc	a0,0x1
    802003a6:	c7650513          	addi	a0,a0,-906 # 80201018 <etext+0x5d6>
    802003aa:	cc7ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
    802003ae:	11843583          	ld	a1,280(s0)
}
    802003b2:	6402                	ld	s0,0(sp)
    802003b4:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
    802003b6:	00001517          	auipc	a0,0x1
    802003ba:	c7a50513          	addi	a0,a0,-902 # 80201030 <etext+0x5ee>
}
    802003be:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
    802003c0:	b945                	j	80200070 <cprintf>

00000000802003c2 <interrupt_handler>:


void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
    802003c2:	11853783          	ld	a5,280(a0)
    switch (cause) {
    802003c6:	472d                	li	a4,11
    intptr_t cause = (tf->cause << 1) >> 1;
    802003c8:	0786                	slli	a5,a5,0x1
    802003ca:	8385                	srli	a5,a5,0x1
    switch (cause) {
    802003cc:	06f76a63          	bltu	a4,a5,80200440 <interrupt_handler+0x7e>
    802003d0:	00000717          	auipc	a4,0x0
    802003d4:	78c70713          	addi	a4,a4,1932 # 80200b5c <etext+0x11a>
    802003d8:	078a                	slli	a5,a5,0x2
    802003da:	97ba                	add	a5,a5,a4
    802003dc:	439c                	lw	a5,0(a5)
    802003de:	97ba                	add	a5,a5,a4
    802003e0:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
    802003e2:	00001517          	auipc	a0,0x1
    802003e6:	89e50513          	addi	a0,a0,-1890 # 80200c80 <etext+0x23e>
    802003ea:	b159                	j	80200070 <cprintf>
            cprintf("Hypervisor software interrupt\n");
    802003ec:	00001517          	auipc	a0,0x1
    802003f0:	87450513          	addi	a0,a0,-1932 # 80200c60 <etext+0x21e>
    802003f4:	b9b5                	j	80200070 <cprintf>
            cprintf("User software interrupt\n");
    802003f6:	00001517          	auipc	a0,0x1
    802003fa:	82a50513          	addi	a0,a0,-2006 # 80200c20 <etext+0x1de>
    802003fe:	b98d                	j	80200070 <cprintf>
            cprintf("Supervisor software interrupt\n");
    80200400:	00001517          	auipc	a0,0x1
    80200404:	84050513          	addi	a0,a0,-1984 # 80200c40 <etext+0x1fe>
    80200408:	b1a5                	j	80200070 <cprintf>
            break;
        case IRQ_U_EXT:
            cprintf("User software interrupt\n");
            break;
        case IRQ_S_EXT:
            cprintf("Supervisor external interrupt\n");
    8020040a:	00001517          	auipc	a0,0x1
    8020040e:	8a650513          	addi	a0,a0,-1882 # 80200cb0 <etext+0x26e>
    80200412:	b9b9                	j	80200070 <cprintf>
void interrupt_handler(struct trapframe *tf) {
    80200414:	1141                	addi	sp,sp,-16
    80200416:	e406                	sd	ra,8(sp)
            clock_set_next_event();
    80200418:	d4dff0ef          	jal	ra,80200164 <clock_set_next_event>
            tick++;  // 增加时钟中断计数
    8020041c:	00004717          	auipc	a4,0x4
    80200420:	bfc70713          	addi	a4,a4,-1028 # 80204018 <tick>
    80200424:	631c                	ld	a5,0(a4)
            if (tick >= 100) {
    80200426:	06300693          	li	a3,99
            tick++;  // 增加时钟中断计数
    8020042a:	0785                	addi	a5,a5,1
    8020042c:	00004617          	auipc	a2,0x4
    80200430:	bef63623          	sd	a5,-1044(a2) # 80204018 <tick>
            if (tick >= 100) {
    80200434:	631c                	ld	a5,0(a4)
    80200436:	00f6e663          	bltu	a3,a5,80200442 <interrupt_handler+0x80>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
    8020043a:	60a2                	ld	ra,8(sp)
    8020043c:	0141                	addi	sp,sp,16
    8020043e:	8082                	ret
            print_trapframe(tf);
    80200440:	b70d                	j	80200362 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
    80200442:	06400593          	li	a1,100
    80200446:	00001517          	auipc	a0,0x1
    8020044a:	85a50513          	addi	a0,a0,-1958 # 80200ca0 <etext+0x25e>
    8020044e:	c23ff0ef          	jal	ra,80200070 <cprintf>
                num++;  // 增加打印行计数
    80200452:	00004717          	auipc	a4,0x4
    80200456:	bbe70713          	addi	a4,a4,-1090 # 80204010 <edata>
    8020045a:	631c                	ld	a5,0(a4)
                if (num >= 10) {
    8020045c:	46a5                	li	a3,9
                num++;  // 增加打印行计数
    8020045e:	0785                	addi	a5,a5,1
    80200460:	00004617          	auipc	a2,0x4
    80200464:	baf63823          	sd	a5,-1104(a2) # 80204010 <edata>
                if (num >= 10) {
    80200468:	631c                	ld	a5,0(a4)
    8020046a:	fcf6f8e3          	bgeu	a3,a5,8020043a <interrupt_handler+0x78>
}
    8020046e:	60a2                	ld	ra,8(sp)
    80200470:	0141                	addi	sp,sp,16
                    sbi_shutdown();  // 调用关机函数
    80200472:	ab55                	j	80200a26 <sbi_shutdown>

0000000080200474 <exception_handler>:

void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
    80200474:	11853783          	ld	a5,280(a0)
    80200478:	472d                	li	a4,11
    8020047a:	02f76763          	bltu	a4,a5,802004a8 <exception_handler+0x34>
    8020047e:	4705                	li	a4,1
    80200480:	00f71733          	sll	a4,a4,a5
    80200484:	6785                	lui	a5,0x1
    80200486:	17cd                	addi	a5,a5,-13
    80200488:	8ff9                	and	a5,a5,a4
    8020048a:	ef91                	bnez	a5,802004a6 <exception_handler+0x32>
void exception_handler(struct trapframe *tf) {
    8020048c:	1141                	addi	sp,sp,-16
    8020048e:	e022                	sd	s0,0(sp)
    80200490:	e406                	sd	ra,8(sp)
    80200492:	00877793          	andi	a5,a4,8
    80200496:	842a                	mv	s0,a0
    80200498:	e3a1                	bnez	a5,802004d8 <exception_handler+0x64>
    8020049a:	8b11                	andi	a4,a4,4
    8020049c:	e719                	bnez	a4,802004aa <exception_handler+0x36>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
    8020049e:	6402                	ld	s0,0(sp)
    802004a0:	60a2                	ld	ra,8(sp)
    802004a2:	0141                	addi	sp,sp,16
            print_trapframe(tf);
    802004a4:	bd7d                	j	80200362 <print_trapframe>
    802004a6:	8082                	ret
    802004a8:	bd6d                	j	80200362 <print_trapframe>
            cprintf("Exception type: Illegal instruction\n");
    802004aa:	00000517          	auipc	a0,0x0
    802004ae:	6e650513          	addi	a0,a0,1766 # 80200b90 <etext+0x14e>
    802004b2:	bbfff0ef          	jal	ra,80200070 <cprintf>
            cprintf("Illegal instruction caught at 0x%08x\n", tf->epc);
    802004b6:	10843583          	ld	a1,264(s0)
    802004ba:	00000517          	auipc	a0,0x0
    802004be:	6fe50513          	addi	a0,a0,1790 # 80200bb8 <etext+0x176>
    802004c2:	bafff0ef          	jal	ra,80200070 <cprintf>
            tf->epc += 4;  // 假设每条指令占4个字节
    802004c6:	10843783          	ld	a5,264(s0)
}
    802004ca:	60a2                	ld	ra,8(sp)
            tf->epc += 4;  // 假设每条指令占4个字节
    802004cc:	0791                	addi	a5,a5,4
    802004ce:	10f43423          	sd	a5,264(s0)
}
    802004d2:	6402                	ld	s0,0(sp)
    802004d4:	0141                	addi	sp,sp,16
    802004d6:	8082                	ret
            cprintf("Exception type: breakpoint\n");
    802004d8:	00000517          	auipc	a0,0x0
    802004dc:	70850513          	addi	a0,a0,1800 # 80200be0 <etext+0x19e>
    802004e0:	b91ff0ef          	jal	ra,80200070 <cprintf>
            cprintf("ebreak caught at 0x%08x\n", tf->epc);
    802004e4:	10843583          	ld	a1,264(s0)
    802004e8:	00000517          	auipc	a0,0x0
    802004ec:	71850513          	addi	a0,a0,1816 # 80200c00 <etext+0x1be>
    802004f0:	b81ff0ef          	jal	ra,80200070 <cprintf>
            tf->epc += 4;  // 假设每条指令占4个字节
    802004f4:	10843783          	ld	a5,264(s0)
}
    802004f8:	60a2                	ld	ra,8(sp)
            tf->epc += 4;  // 假设每条指令占4个字节
    802004fa:	0791                	addi	a5,a5,4
    802004fc:	10f43423          	sd	a5,264(s0)
}
    80200500:	6402                	ld	s0,0(sp)
    80200502:	0141                	addi	sp,sp,16
    80200504:	8082                	ret

0000000080200506 <trap>:

/* trap_dispatch - dispatch based on what type of trap occurred */
static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
    80200506:	11853783          	ld	a5,280(a0)
    8020050a:	0007c363          	bltz	a5,80200510 <trap+0xa>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
    8020050e:	b79d                	j	80200474 <exception_handler>
        interrupt_handler(tf);
    80200510:	bd4d                	j	802003c2 <interrupt_handler>
	...

0000000080200514 <__alltraps>:
    .endm

    .globl __alltraps
.align(2)
__alltraps:
    SAVE_ALL
    80200514:	14011073          	csrw	sscratch,sp
    80200518:	712d                	addi	sp,sp,-288
    8020051a:	e002                	sd	zero,0(sp)
    8020051c:	e406                	sd	ra,8(sp)
    8020051e:	ec0e                	sd	gp,24(sp)
    80200520:	f012                	sd	tp,32(sp)
    80200522:	f416                	sd	t0,40(sp)
    80200524:	f81a                	sd	t1,48(sp)
    80200526:	fc1e                	sd	t2,56(sp)
    80200528:	e0a2                	sd	s0,64(sp)
    8020052a:	e4a6                	sd	s1,72(sp)
    8020052c:	e8aa                	sd	a0,80(sp)
    8020052e:	ecae                	sd	a1,88(sp)
    80200530:	f0b2                	sd	a2,96(sp)
    80200532:	f4b6                	sd	a3,104(sp)
    80200534:	f8ba                	sd	a4,112(sp)
    80200536:	fcbe                	sd	a5,120(sp)
    80200538:	e142                	sd	a6,128(sp)
    8020053a:	e546                	sd	a7,136(sp)
    8020053c:	e94a                	sd	s2,144(sp)
    8020053e:	ed4e                	sd	s3,152(sp)
    80200540:	f152                	sd	s4,160(sp)
    80200542:	f556                	sd	s5,168(sp)
    80200544:	f95a                	sd	s6,176(sp)
    80200546:	fd5e                	sd	s7,184(sp)
    80200548:	e1e2                	sd	s8,192(sp)
    8020054a:	e5e6                	sd	s9,200(sp)
    8020054c:	e9ea                	sd	s10,208(sp)
    8020054e:	edee                	sd	s11,216(sp)
    80200550:	f1f2                	sd	t3,224(sp)
    80200552:	f5f6                	sd	t4,232(sp)
    80200554:	f9fa                	sd	t5,240(sp)
    80200556:	fdfe                	sd	t6,248(sp)
    80200558:	14001473          	csrrw	s0,sscratch,zero
    8020055c:	100024f3          	csrr	s1,sstatus
    80200560:	14102973          	csrr	s2,sepc
    80200564:	143029f3          	csrr	s3,stval
    80200568:	14202a73          	csrr	s4,scause
    8020056c:	e822                	sd	s0,16(sp)
    8020056e:	e226                	sd	s1,256(sp)
    80200570:	e64a                	sd	s2,264(sp)
    80200572:	ea4e                	sd	s3,272(sp)
    80200574:	ee52                	sd	s4,280(sp)

    move  a0, sp
    80200576:	850a                	mv	a0,sp
    jal trap
    80200578:	f8fff0ef          	jal	ra,80200506 <trap>

000000008020057c <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
    8020057c:	6492                	ld	s1,256(sp)
    8020057e:	6932                	ld	s2,264(sp)
    80200580:	10049073          	csrw	sstatus,s1
    80200584:	14191073          	csrw	sepc,s2
    80200588:	60a2                	ld	ra,8(sp)
    8020058a:	61e2                	ld	gp,24(sp)
    8020058c:	7202                	ld	tp,32(sp)
    8020058e:	72a2                	ld	t0,40(sp)
    80200590:	7342                	ld	t1,48(sp)
    80200592:	73e2                	ld	t2,56(sp)
    80200594:	6406                	ld	s0,64(sp)
    80200596:	64a6                	ld	s1,72(sp)
    80200598:	6546                	ld	a0,80(sp)
    8020059a:	65e6                	ld	a1,88(sp)
    8020059c:	7606                	ld	a2,96(sp)
    8020059e:	76a6                	ld	a3,104(sp)
    802005a0:	7746                	ld	a4,112(sp)
    802005a2:	77e6                	ld	a5,120(sp)
    802005a4:	680a                	ld	a6,128(sp)
    802005a6:	68aa                	ld	a7,136(sp)
    802005a8:	694a                	ld	s2,144(sp)
    802005aa:	69ea                	ld	s3,152(sp)
    802005ac:	7a0a                	ld	s4,160(sp)
    802005ae:	7aaa                	ld	s5,168(sp)
    802005b0:	7b4a                	ld	s6,176(sp)
    802005b2:	7bea                	ld	s7,184(sp)
    802005b4:	6c0e                	ld	s8,192(sp)
    802005b6:	6cae                	ld	s9,200(sp)
    802005b8:	6d4e                	ld	s10,208(sp)
    802005ba:	6dee                	ld	s11,216(sp)
    802005bc:	7e0e                	ld	t3,224(sp)
    802005be:	7eae                	ld	t4,232(sp)
    802005c0:	7f4e                	ld	t5,240(sp)
    802005c2:	7fee                	ld	t6,248(sp)
    802005c4:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
    802005c6:	10200073          	sret

00000000802005ca <strnlen>:
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
    802005ca:	c185                	beqz	a1,802005ea <strnlen+0x20>
    802005cc:	00054783          	lbu	a5,0(a0)
    802005d0:	cf89                	beqz	a5,802005ea <strnlen+0x20>
    size_t cnt = 0;
    802005d2:	4781                	li	a5,0
    802005d4:	a021                	j	802005dc <strnlen+0x12>
    while (cnt < len && *s ++ != '\0') {
    802005d6:	00074703          	lbu	a4,0(a4)
    802005da:	c711                	beqz	a4,802005e6 <strnlen+0x1c>
        cnt ++;
    802005dc:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
    802005de:	00f50733          	add	a4,a0,a5
    802005e2:	fef59ae3          	bne	a1,a5,802005d6 <strnlen+0xc>
    }
    return cnt;
}
    802005e6:	853e                	mv	a0,a5
    802005e8:	8082                	ret
    size_t cnt = 0;
    802005ea:	4781                	li	a5,0
}
    802005ec:	853e                	mv	a0,a5
    802005ee:	8082                	ret

00000000802005f0 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
    802005f0:	ca01                	beqz	a2,80200600 <memset+0x10>
    802005f2:	962a                	add	a2,a2,a0
    char *p = s;
    802005f4:	87aa                	mv	a5,a0
        *p ++ = c;
    802005f6:	0785                	addi	a5,a5,1
    802005f8:	feb78fa3          	sb	a1,-1(a5) # fff <BASE_ADDRESS-0x801ff001>
    while (n -- > 0) {
    802005fc:	fec79de3          	bne	a5,a2,802005f6 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
    80200600:	8082                	ret

0000000080200602 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
    80200602:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
    80200606:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
    80200608:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
    8020060c:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
    8020060e:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
    80200612:	f022                	sd	s0,32(sp)
    80200614:	ec26                	sd	s1,24(sp)
    80200616:	e84a                	sd	s2,16(sp)
    80200618:	f406                	sd	ra,40(sp)
    8020061a:	e44e                	sd	s3,8(sp)
    8020061c:	84aa                	mv	s1,a0
    8020061e:	892e                	mv	s2,a1
    80200620:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
    80200624:	2a01                	sext.w	s4,s4

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
    80200626:	03067e63          	bgeu	a2,a6,80200662 <printnum+0x60>
    8020062a:	89be                	mv	s3,a5
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
    8020062c:	00805763          	blez	s0,8020063a <printnum+0x38>
    80200630:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
    80200632:	85ca                	mv	a1,s2
    80200634:	854e                	mv	a0,s3
    80200636:	9482                	jalr	s1
        while (-- width > 0)
    80200638:	fc65                	bnez	s0,80200630 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
    8020063a:	1a02                	slli	s4,s4,0x20
    8020063c:	020a5a13          	srli	s4,s4,0x20
    80200640:	00001797          	auipc	a5,0x1
    80200644:	b9878793          	addi	a5,a5,-1128 # 802011d8 <error_string+0x38>
    80200648:	9a3e                	add	s4,s4,a5
}
    8020064a:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
    8020064c:	000a4503          	lbu	a0,0(s4)
}
    80200650:	70a2                	ld	ra,40(sp)
    80200652:	69a2                	ld	s3,8(sp)
    80200654:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
    80200656:	85ca                	mv	a1,s2
    80200658:	8326                	mv	t1,s1
}
    8020065a:	6942                	ld	s2,16(sp)
    8020065c:	64e2                	ld	s1,24(sp)
    8020065e:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
    80200660:	8302                	jr	t1
        printnum(putch, putdat, result, base, width - 1, padc);
    80200662:	03065633          	divu	a2,a2,a6
    80200666:	8722                	mv	a4,s0
    80200668:	f9bff0ef          	jal	ra,80200602 <printnum>
    8020066c:	b7f9                	j	8020063a <printnum+0x38>

000000008020066e <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
    8020066e:	7119                	addi	sp,sp,-128
    80200670:	f4a6                	sd	s1,104(sp)
    80200672:	f0ca                	sd	s2,96(sp)
    80200674:	e8d2                	sd	s4,80(sp)
    80200676:	e4d6                	sd	s5,72(sp)
    80200678:	e0da                	sd	s6,64(sp)
    8020067a:	fc5e                	sd	s7,56(sp)
    8020067c:	f862                	sd	s8,48(sp)
    8020067e:	f06a                	sd	s10,32(sp)
    80200680:	fc86                	sd	ra,120(sp)
    80200682:	f8a2                	sd	s0,112(sp)
    80200684:	ecce                	sd	s3,88(sp)
    80200686:	f466                	sd	s9,40(sp)
    80200688:	ec6e                	sd	s11,24(sp)
    8020068a:	892a                	mv	s2,a0
    8020068c:	84ae                	mv	s1,a1
    8020068e:	8d32                	mv	s10,a2
    80200690:	8ab6                	mv	s5,a3
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
    80200692:	5b7d                	li	s6,-1
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
    80200694:	00001a17          	auipc	s4,0x1
    80200698:	9b0a0a13          	addi	s4,s4,-1616 # 80201044 <etext+0x602>
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
                if (altflag && (ch < ' ' || ch > '~')) {
    8020069c:	05e00b93          	li	s7,94
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
    802006a0:	00001c17          	auipc	s8,0x1
    802006a4:	b00c0c13          	addi	s8,s8,-1280 # 802011a0 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    802006a8:	000d4503          	lbu	a0,0(s10)
    802006ac:	02500793          	li	a5,37
    802006b0:	001d0413          	addi	s0,s10,1
    802006b4:	00f50e63          	beq	a0,a5,802006d0 <vprintfmt+0x62>
            if (ch == '\0') {
    802006b8:	c521                	beqz	a0,80200700 <vprintfmt+0x92>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    802006ba:	02500993          	li	s3,37
    802006be:	a011                	j	802006c2 <vprintfmt+0x54>
            if (ch == '\0') {
    802006c0:	c121                	beqz	a0,80200700 <vprintfmt+0x92>
            putch(ch, putdat);
    802006c2:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    802006c4:	0405                	addi	s0,s0,1
            putch(ch, putdat);
    802006c6:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    802006c8:	fff44503          	lbu	a0,-1(s0)
    802006cc:	ff351ae3          	bne	a0,s3,802006c0 <vprintfmt+0x52>
    802006d0:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
    802006d4:	02000793          	li	a5,32
        lflag = altflag = 0;
    802006d8:	4981                	li	s3,0
    802006da:	4801                	li	a6,0
        width = precision = -1;
    802006dc:	5cfd                	li	s9,-1
    802006de:	5dfd                	li	s11,-1
        switch (ch = *(unsigned char *)fmt ++) {
    802006e0:	05500593          	li	a1,85
                if (ch < '0' || ch > '9') {
    802006e4:	4525                	li	a0,9
        switch (ch = *(unsigned char *)fmt ++) {
    802006e6:	fdd6069b          	addiw	a3,a2,-35
    802006ea:	0ff6f693          	andi	a3,a3,255
    802006ee:	00140d13          	addi	s10,s0,1
    802006f2:	1ed5ef63          	bltu	a1,a3,802008f0 <vprintfmt+0x282>
    802006f6:	068a                	slli	a3,a3,0x2
    802006f8:	96d2                	add	a3,a3,s4
    802006fa:	4294                	lw	a3,0(a3)
    802006fc:	96d2                	add	a3,a3,s4
    802006fe:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
    80200700:	70e6                	ld	ra,120(sp)
    80200702:	7446                	ld	s0,112(sp)
    80200704:	74a6                	ld	s1,104(sp)
    80200706:	7906                	ld	s2,96(sp)
    80200708:	69e6                	ld	s3,88(sp)
    8020070a:	6a46                	ld	s4,80(sp)
    8020070c:	6aa6                	ld	s5,72(sp)
    8020070e:	6b06                	ld	s6,64(sp)
    80200710:	7be2                	ld	s7,56(sp)
    80200712:	7c42                	ld	s8,48(sp)
    80200714:	7ca2                	ld	s9,40(sp)
    80200716:	7d02                	ld	s10,32(sp)
    80200718:	6de2                	ld	s11,24(sp)
    8020071a:	6109                	addi	sp,sp,128
    8020071c:	8082                	ret
            padc = '-';
    8020071e:	87b2                	mv	a5,a2
        switch (ch = *(unsigned char *)fmt ++) {
    80200720:	00144603          	lbu	a2,1(s0)
    80200724:	846a                	mv	s0,s10
    80200726:	b7c1                	j	802006e6 <vprintfmt+0x78>
            precision = va_arg(ap, int);
    80200728:	000aac83          	lw	s9,0(s5)
            goto process_precision;
    8020072c:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
    80200730:	0aa1                	addi	s5,s5,8
        switch (ch = *(unsigned char *)fmt ++) {
    80200732:	846a                	mv	s0,s10
            if (width < 0)
    80200734:	fa0dd9e3          	bgez	s11,802006e6 <vprintfmt+0x78>
                width = precision, precision = -1;
    80200738:	8de6                	mv	s11,s9
    8020073a:	5cfd                	li	s9,-1
    8020073c:	b76d                	j	802006e6 <vprintfmt+0x78>
            if (width < 0)
    8020073e:	fffdc693          	not	a3,s11
    80200742:	96fd                	srai	a3,a3,0x3f
    80200744:	00ddfdb3          	and	s11,s11,a3
    80200748:	00144603          	lbu	a2,1(s0)
    8020074c:	2d81                	sext.w	s11,s11
        switch (ch = *(unsigned char *)fmt ++) {
    8020074e:	846a                	mv	s0,s10
    80200750:	bf59                	j	802006e6 <vprintfmt+0x78>
    if (lflag >= 2) {
    80200752:	4705                	li	a4,1
    80200754:	008a8593          	addi	a1,s5,8
    80200758:	01074463          	blt	a4,a6,80200760 <vprintfmt+0xf2>
    else if (lflag) {
    8020075c:	22080863          	beqz	a6,8020098c <vprintfmt+0x31e>
        return va_arg(*ap, unsigned long);
    80200760:	000ab603          	ld	a2,0(s5)
    80200764:	46c1                	li	a3,16
    80200766:	8aae                	mv	s5,a1
    80200768:	a291                	j	802008ac <vprintfmt+0x23e>
                precision = precision * 10 + ch - '0';
    8020076a:	fd060c9b          	addiw	s9,a2,-48
                ch = *fmt;
    8020076e:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
    80200772:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
    80200774:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
    80200778:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
    8020077c:	fad56ce3          	bltu	a0,a3,80200734 <vprintfmt+0xc6>
            for (precision = 0; ; ++ fmt) {
    80200780:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
    80200782:	002c969b          	slliw	a3,s9,0x2
                ch = *fmt;
    80200786:	00044603          	lbu	a2,0(s0)
                precision = precision * 10 + ch - '0';
    8020078a:	0196873b          	addw	a4,a3,s9
    8020078e:	0017171b          	slliw	a4,a4,0x1
    80200792:	0117073b          	addw	a4,a4,a7
                if (ch < '0' || ch > '9') {
    80200796:	fd06069b          	addiw	a3,a2,-48
                precision = precision * 10 + ch - '0';
    8020079a:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
    8020079e:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
    802007a2:	fcd57fe3          	bgeu	a0,a3,80200780 <vprintfmt+0x112>
    802007a6:	b779                	j	80200734 <vprintfmt+0xc6>
            putch(va_arg(ap, int), putdat);
    802007a8:	000aa503          	lw	a0,0(s5)
    802007ac:	85a6                	mv	a1,s1
    802007ae:	0aa1                	addi	s5,s5,8
    802007b0:	9902                	jalr	s2
            break;
    802007b2:	bddd                	j	802006a8 <vprintfmt+0x3a>
    if (lflag >= 2) {
    802007b4:	4705                	li	a4,1
    802007b6:	008a8993          	addi	s3,s5,8
    802007ba:	01074463          	blt	a4,a6,802007c2 <vprintfmt+0x154>
    else if (lflag) {
    802007be:	1c080463          	beqz	a6,80200986 <vprintfmt+0x318>
        return va_arg(*ap, long);
    802007c2:	000ab403          	ld	s0,0(s5)
            if ((long long)num < 0) {
    802007c6:	1c044a63          	bltz	s0,8020099a <vprintfmt+0x32c>
            num = getint(&ap, lflag);
    802007ca:	8622                	mv	a2,s0
    802007cc:	8ace                	mv	s5,s3
    802007ce:	46a9                	li	a3,10
    802007d0:	a8f1                	j	802008ac <vprintfmt+0x23e>
            err = va_arg(ap, int);
    802007d2:	000aa783          	lw	a5,0(s5)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
    802007d6:	4719                	li	a4,6
            err = va_arg(ap, int);
    802007d8:	0aa1                	addi	s5,s5,8
            if (err < 0) {
    802007da:	41f7d69b          	sraiw	a3,a5,0x1f
    802007de:	8fb5                	xor	a5,a5,a3
    802007e0:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
    802007e4:	12d74963          	blt	a4,a3,80200916 <vprintfmt+0x2a8>
    802007e8:	00369793          	slli	a5,a3,0x3
    802007ec:	97e2                	add	a5,a5,s8
    802007ee:	639c                	ld	a5,0(a5)
    802007f0:	12078363          	beqz	a5,80200916 <vprintfmt+0x2a8>
                printfmt(putch, putdat, "%s", p);
    802007f4:	86be                	mv	a3,a5
    802007f6:	00001617          	auipc	a2,0x1
    802007fa:	a9260613          	addi	a2,a2,-1390 # 80201288 <error_string+0xe8>
    802007fe:	85a6                	mv	a1,s1
    80200800:	854a                	mv	a0,s2
    80200802:	1cc000ef          	jal	ra,802009ce <printfmt>
    80200806:	b54d                	j	802006a8 <vprintfmt+0x3a>
            if ((p = va_arg(ap, char *)) == NULL) {
    80200808:	000ab603          	ld	a2,0(s5)
    8020080c:	0aa1                	addi	s5,s5,8
    8020080e:	1a060163          	beqz	a2,802009b0 <vprintfmt+0x342>
            if (width > 0 && padc != '-') {
    80200812:	00160413          	addi	s0,a2,1
    80200816:	15b05763          	blez	s11,80200964 <vprintfmt+0x2f6>
    8020081a:	02d00593          	li	a1,45
    8020081e:	10b79d63          	bne	a5,a1,80200938 <vprintfmt+0x2ca>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    80200822:	00064783          	lbu	a5,0(a2)
    80200826:	0007851b          	sext.w	a0,a5
    8020082a:	c905                	beqz	a0,8020085a <vprintfmt+0x1ec>
    8020082c:	000cc563          	bltz	s9,80200836 <vprintfmt+0x1c8>
    80200830:	3cfd                	addiw	s9,s9,-1
    80200832:	036c8263          	beq	s9,s6,80200856 <vprintfmt+0x1e8>
                    putch('?', putdat);
    80200836:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
    80200838:	14098f63          	beqz	s3,80200996 <vprintfmt+0x328>
    8020083c:	3781                	addiw	a5,a5,-32
    8020083e:	14fbfc63          	bgeu	s7,a5,80200996 <vprintfmt+0x328>
                    putch('?', putdat);
    80200842:	03f00513          	li	a0,63
    80200846:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    80200848:	0405                	addi	s0,s0,1
    8020084a:	fff44783          	lbu	a5,-1(s0)
    8020084e:	3dfd                	addiw	s11,s11,-1
    80200850:	0007851b          	sext.w	a0,a5
    80200854:	fd61                	bnez	a0,8020082c <vprintfmt+0x1be>
            for (; width > 0; width --) {
    80200856:	e5b059e3          	blez	s11,802006a8 <vprintfmt+0x3a>
    8020085a:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
    8020085c:	85a6                	mv	a1,s1
    8020085e:	02000513          	li	a0,32
    80200862:	9902                	jalr	s2
            for (; width > 0; width --) {
    80200864:	e40d82e3          	beqz	s11,802006a8 <vprintfmt+0x3a>
    80200868:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
    8020086a:	85a6                	mv	a1,s1
    8020086c:	02000513          	li	a0,32
    80200870:	9902                	jalr	s2
            for (; width > 0; width --) {
    80200872:	fe0d94e3          	bnez	s11,8020085a <vprintfmt+0x1ec>
    80200876:	bd0d                	j	802006a8 <vprintfmt+0x3a>
    if (lflag >= 2) {
    80200878:	4705                	li	a4,1
    8020087a:	008a8593          	addi	a1,s5,8
    8020087e:	01074463          	blt	a4,a6,80200886 <vprintfmt+0x218>
    else if (lflag) {
    80200882:	0e080863          	beqz	a6,80200972 <vprintfmt+0x304>
        return va_arg(*ap, unsigned long);
    80200886:	000ab603          	ld	a2,0(s5)
    8020088a:	46a1                	li	a3,8
    8020088c:	8aae                	mv	s5,a1
    8020088e:	a839                	j	802008ac <vprintfmt+0x23e>
            putch('0', putdat);
    80200890:	03000513          	li	a0,48
    80200894:	85a6                	mv	a1,s1
    80200896:	e03e                	sd	a5,0(sp)
    80200898:	9902                	jalr	s2
            putch('x', putdat);
    8020089a:	85a6                	mv	a1,s1
    8020089c:	07800513          	li	a0,120
    802008a0:	9902                	jalr	s2
            num = (unsigned long long)va_arg(ap, void *);
    802008a2:	0aa1                	addi	s5,s5,8
    802008a4:	ff8ab603          	ld	a2,-8(s5)
            goto number;
    802008a8:	6782                	ld	a5,0(sp)
    802008aa:	46c1                	li	a3,16
            printnum(putch, putdat, num, base, width, padc);
    802008ac:	2781                	sext.w	a5,a5
    802008ae:	876e                	mv	a4,s11
    802008b0:	85a6                	mv	a1,s1
    802008b2:	854a                	mv	a0,s2
    802008b4:	d4fff0ef          	jal	ra,80200602 <printnum>
            break;
    802008b8:	bbc5                	j	802006a8 <vprintfmt+0x3a>
            lflag ++;
    802008ba:	00144603          	lbu	a2,1(s0)
    802008be:	2805                	addiw	a6,a6,1
        switch (ch = *(unsigned char *)fmt ++) {
    802008c0:	846a                	mv	s0,s10
            goto reswitch;
    802008c2:	b515                	j	802006e6 <vprintfmt+0x78>
            goto reswitch;
    802008c4:	00144603          	lbu	a2,1(s0)
            altflag = 1;
    802008c8:	4985                	li	s3,1
        switch (ch = *(unsigned char *)fmt ++) {
    802008ca:	846a                	mv	s0,s10
            goto reswitch;
    802008cc:	bd29                	j	802006e6 <vprintfmt+0x78>
            putch(ch, putdat);
    802008ce:	85a6                	mv	a1,s1
    802008d0:	02500513          	li	a0,37
    802008d4:	9902                	jalr	s2
            break;
    802008d6:	bbc9                	j	802006a8 <vprintfmt+0x3a>
    if (lflag >= 2) {
    802008d8:	4705                	li	a4,1
    802008da:	008a8593          	addi	a1,s5,8
    802008de:	01074463          	blt	a4,a6,802008e6 <vprintfmt+0x278>
    else if (lflag) {
    802008e2:	08080d63          	beqz	a6,8020097c <vprintfmt+0x30e>
        return va_arg(*ap, unsigned long);
    802008e6:	000ab603          	ld	a2,0(s5)
    802008ea:	46a9                	li	a3,10
    802008ec:	8aae                	mv	s5,a1
    802008ee:	bf7d                	j	802008ac <vprintfmt+0x23e>
            putch('%', putdat);
    802008f0:	85a6                	mv	a1,s1
    802008f2:	02500513          	li	a0,37
    802008f6:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
    802008f8:	fff44703          	lbu	a4,-1(s0)
    802008fc:	02500793          	li	a5,37
    80200900:	8d22                	mv	s10,s0
    80200902:	daf703e3          	beq	a4,a5,802006a8 <vprintfmt+0x3a>
    80200906:	02500713          	li	a4,37
    8020090a:	1d7d                	addi	s10,s10,-1
    8020090c:	fffd4783          	lbu	a5,-1(s10)
    80200910:	fee79de3          	bne	a5,a4,8020090a <vprintfmt+0x29c>
    80200914:	bb51                	j	802006a8 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
    80200916:	00001617          	auipc	a2,0x1
    8020091a:	96260613          	addi	a2,a2,-1694 # 80201278 <error_string+0xd8>
    8020091e:	85a6                	mv	a1,s1
    80200920:	854a                	mv	a0,s2
    80200922:	0ac000ef          	jal	ra,802009ce <printfmt>
    80200926:	b349                	j	802006a8 <vprintfmt+0x3a>
                p = "(null)";
    80200928:	00001617          	auipc	a2,0x1
    8020092c:	94860613          	addi	a2,a2,-1720 # 80201270 <error_string+0xd0>
            if (width > 0 && padc != '-') {
    80200930:	00001417          	auipc	s0,0x1
    80200934:	94140413          	addi	s0,s0,-1727 # 80201271 <error_string+0xd1>
                for (width -= strnlen(p, precision); width > 0; width --) {
    80200938:	8532                	mv	a0,a2
    8020093a:	85e6                	mv	a1,s9
    8020093c:	e032                	sd	a2,0(sp)
    8020093e:	e43e                	sd	a5,8(sp)
    80200940:	c8bff0ef          	jal	ra,802005ca <strnlen>
    80200944:	40ad8dbb          	subw	s11,s11,a0
    80200948:	6602                	ld	a2,0(sp)
    8020094a:	01b05d63          	blez	s11,80200964 <vprintfmt+0x2f6>
    8020094e:	67a2                	ld	a5,8(sp)
    80200950:	2781                	sext.w	a5,a5
    80200952:	e43e                	sd	a5,8(sp)
                    putch(padc, putdat);
    80200954:	6522                	ld	a0,8(sp)
    80200956:	85a6                	mv	a1,s1
    80200958:	e032                	sd	a2,0(sp)
                for (width -= strnlen(p, precision); width > 0; width --) {
    8020095a:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
    8020095c:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
    8020095e:	6602                	ld	a2,0(sp)
    80200960:	fe0d9ae3          	bnez	s11,80200954 <vprintfmt+0x2e6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    80200964:	00064783          	lbu	a5,0(a2)
    80200968:	0007851b          	sext.w	a0,a5
    8020096c:	ec0510e3          	bnez	a0,8020082c <vprintfmt+0x1be>
    80200970:	bb25                	j	802006a8 <vprintfmt+0x3a>
        return va_arg(*ap, unsigned int);
    80200972:	000ae603          	lwu	a2,0(s5)
    80200976:	46a1                	li	a3,8
    80200978:	8aae                	mv	s5,a1
    8020097a:	bf0d                	j	802008ac <vprintfmt+0x23e>
    8020097c:	000ae603          	lwu	a2,0(s5)
    80200980:	46a9                	li	a3,10
    80200982:	8aae                	mv	s5,a1
    80200984:	b725                	j	802008ac <vprintfmt+0x23e>
        return va_arg(*ap, int);
    80200986:	000aa403          	lw	s0,0(s5)
    8020098a:	bd35                	j	802007c6 <vprintfmt+0x158>
        return va_arg(*ap, unsigned int);
    8020098c:	000ae603          	lwu	a2,0(s5)
    80200990:	46c1                	li	a3,16
    80200992:	8aae                	mv	s5,a1
    80200994:	bf21                	j	802008ac <vprintfmt+0x23e>
                    putch(ch, putdat);
    80200996:	9902                	jalr	s2
    80200998:	bd45                	j	80200848 <vprintfmt+0x1da>
                putch('-', putdat);
    8020099a:	85a6                	mv	a1,s1
    8020099c:	02d00513          	li	a0,45
    802009a0:	e03e                	sd	a5,0(sp)
    802009a2:	9902                	jalr	s2
                num = -(long long)num;
    802009a4:	8ace                	mv	s5,s3
    802009a6:	40800633          	neg	a2,s0
    802009aa:	46a9                	li	a3,10
    802009ac:	6782                	ld	a5,0(sp)
    802009ae:	bdfd                	j	802008ac <vprintfmt+0x23e>
            if (width > 0 && padc != '-') {
    802009b0:	01b05663          	blez	s11,802009bc <vprintfmt+0x34e>
    802009b4:	02d00693          	li	a3,45
    802009b8:	f6d798e3          	bne	a5,a3,80200928 <vprintfmt+0x2ba>
    802009bc:	00001417          	auipc	s0,0x1
    802009c0:	8b540413          	addi	s0,s0,-1867 # 80201271 <error_string+0xd1>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    802009c4:	02800513          	li	a0,40
    802009c8:	02800793          	li	a5,40
    802009cc:	b585                	j	8020082c <vprintfmt+0x1be>

00000000802009ce <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
    802009ce:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
    802009d0:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
    802009d4:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
    802009d6:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
    802009d8:	ec06                	sd	ra,24(sp)
    802009da:	f83a                	sd	a4,48(sp)
    802009dc:	fc3e                	sd	a5,56(sp)
    802009de:	e0c2                	sd	a6,64(sp)
    802009e0:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
    802009e2:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
    802009e4:	c8bff0ef          	jal	ra,8020066e <vprintfmt>
}
    802009e8:	60e2                	ld	ra,24(sp)
    802009ea:	6161                	addi	sp,sp,80
    802009ec:	8082                	ret

00000000802009ee <sbi_console_putchar>:

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
    802009ee:	00003797          	auipc	a5,0x3
    802009f2:	61278793          	addi	a5,a5,1554 # 80204000 <bootstacktop>
    __asm__ volatile (
    802009f6:	6398                	ld	a4,0(a5)
    802009f8:	4781                	li	a5,0
    802009fa:	88ba                	mv	a7,a4
    802009fc:	852a                	mv	a0,a0
    802009fe:	85be                	mv	a1,a5
    80200a00:	863e                	mv	a2,a5
    80200a02:	00000073          	ecall
    80200a06:	87aa                	mv	a5,a0
}
    80200a08:	8082                	ret

0000000080200a0a <sbi_set_timer>:

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
    80200a0a:	00003797          	auipc	a5,0x3
    80200a0e:	61678793          	addi	a5,a5,1558 # 80204020 <SBI_SET_TIMER>
    __asm__ volatile (
    80200a12:	6398                	ld	a4,0(a5)
    80200a14:	4781                	li	a5,0
    80200a16:	88ba                	mv	a7,a4
    80200a18:	852a                	mv	a0,a0
    80200a1a:	85be                	mv	a1,a5
    80200a1c:	863e                	mv	a2,a5
    80200a1e:	00000073          	ecall
    80200a22:	87aa                	mv	a5,a0
}
    80200a24:	8082                	ret

0000000080200a26 <sbi_shutdown>:


void sbi_shutdown(void)
{
    sbi_call(SBI_SHUTDOWN,0,0,0);
    80200a26:	00003797          	auipc	a5,0x3
    80200a2a:	5e278793          	addi	a5,a5,1506 # 80204008 <SBI_SHUTDOWN>
    __asm__ volatile (
    80200a2e:	6398                	ld	a4,0(a5)
    80200a30:	4781                	li	a5,0
    80200a32:	88ba                	mv	a7,a4
    80200a34:	853e                	mv	a0,a5
    80200a36:	85be                	mv	a1,a5
    80200a38:	863e                	mv	a2,a5
    80200a3a:	00000073          	ecall
    80200a3e:	87aa                	mv	a5,a0
    80200a40:	8082                	ret
