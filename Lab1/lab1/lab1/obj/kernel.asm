
bin/kernel:     file format elf64-littleriscv


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
    8020000e:	00650513          	addi	a0,a0,6 # 80204010 <ticks>
    80200012:	00004617          	auipc	a2,0x4
    80200016:	01660613          	addi	a2,a2,22 # 80204028 <end>
int kern_init(void) {
    8020001a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
    8020001c:	8e09                	sub	a2,a2,a0
    8020001e:	4581                	li	a1,0
int kern_init(void) {
    80200020:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
    80200022:	15d000ef          	jal	ra,8020097e <memset>

    cons_init();  // init the console
    80200026:	13a000ef          	jal	ra,80200160 <cons_init>

    const char *message = "(THU.CST) os is loading ...\n";
    cprintf("%s\n\n", message);
    8020002a:	00001597          	auipc	a1,0x1
    8020002e:	96658593          	addi	a1,a1,-1690 # 80200990 <etext>
    80200032:	00001517          	auipc	a0,0x1
    80200036:	97e50513          	addi	a0,a0,-1666 # 802009b0 <etext+0x20>
    8020003a:	030000ef          	jal	ra,8020006a <cprintf>

    print_kerninfo();
    8020003e:	062000ef          	jal	ra,802000a0 <print_kerninfo>

    // grade_backtrace();

    idt_init();  // init interrupt descriptor table
    80200042:	12e000ef          	jal	ra,80200170 <idt_init>

    // rdtime in mbare mode crashes
    clock_init();  // init clock interrupt
    80200046:	0e8000ef          	jal	ra,8020012e <clock_init>

    intr_enable();  // enable irq interrupt
    8020004a:	120000ef          	jal	ra,8020016a <intr_enable>
    
    while (1)
    8020004e:	a001                	j	8020004e <kern_init+0x44>

0000000080200050 <cputch>:

/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void cputch(int c, int *cnt) {
    80200050:	1141                	addi	sp,sp,-16
    80200052:	e022                	sd	s0,0(sp)
    80200054:	e406                	sd	ra,8(sp)
    80200056:	842e                	mv	s0,a1
    cons_putc(c);
    80200058:	10a000ef          	jal	ra,80200162 <cons_putc>
    (*cnt)++;
    8020005c:	401c                	lw	a5,0(s0)
}
    8020005e:	60a2                	ld	ra,8(sp)
    (*cnt)++;
    80200060:	2785                	addiw	a5,a5,1
    80200062:	c01c                	sw	a5,0(s0)
}
    80200064:	6402                	ld	s0,0(sp)
    80200066:	0141                	addi	sp,sp,16
    80200068:	8082                	ret

000000008020006a <cprintf>:
 * cprintf - formats a string and writes it to stdout
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...) {
    8020006a:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
    8020006c:	02810313          	addi	t1,sp,40 # 80204028 <end>
int cprintf(const char *fmt, ...) {
    80200070:	8e2a                	mv	t3,a0
    80200072:	f42e                	sd	a1,40(sp)
    80200074:	f832                	sd	a2,48(sp)
    80200076:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
    80200078:	00000517          	auipc	a0,0x0
    8020007c:	fd850513          	addi	a0,a0,-40 # 80200050 <cputch>
    80200080:	004c                	addi	a1,sp,4
    80200082:	869a                	mv	a3,t1
    80200084:	8672                	mv	a2,t3
int cprintf(const char *fmt, ...) {
    80200086:	ec06                	sd	ra,24(sp)
    80200088:	e0ba                	sd	a4,64(sp)
    8020008a:	e4be                	sd	a5,72(sp)
    8020008c:	e8c2                	sd	a6,80(sp)
    8020008e:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
    80200090:	e41a                	sd	t1,8(sp)
    int cnt = 0;
    80200092:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
    80200094:	4fe000ef          	jal	ra,80200592 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
    80200098:	60e2                	ld	ra,24(sp)
    8020009a:	4512                	lw	a0,4(sp)
    8020009c:	6125                	addi	sp,sp,96
    8020009e:	8082                	ret

00000000802000a0 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
    802000a0:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
    802000a2:	00001517          	auipc	a0,0x1
    802000a6:	91650513          	addi	a0,a0,-1770 # 802009b8 <etext+0x28>
void print_kerninfo(void) {
    802000aa:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
    802000ac:	fbfff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  entry  0x%016x (virtual)\n", kern_init);
    802000b0:	00000597          	auipc	a1,0x0
    802000b4:	f5a58593          	addi	a1,a1,-166 # 8020000a <kern_init>
    802000b8:	00001517          	auipc	a0,0x1
    802000bc:	92050513          	addi	a0,a0,-1760 # 802009d8 <etext+0x48>
    802000c0:	fabff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  etext  0x%016x (virtual)\n", etext);
    802000c4:	00001597          	auipc	a1,0x1
    802000c8:	8cc58593          	addi	a1,a1,-1844 # 80200990 <etext>
    802000cc:	00001517          	auipc	a0,0x1
    802000d0:	92c50513          	addi	a0,a0,-1748 # 802009f8 <etext+0x68>
    802000d4:	f97ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  edata  0x%016x (virtual)\n", edata);
    802000d8:	00004597          	auipc	a1,0x4
    802000dc:	f3858593          	addi	a1,a1,-200 # 80204010 <ticks>
    802000e0:	00001517          	auipc	a0,0x1
    802000e4:	93850513          	addi	a0,a0,-1736 # 80200a18 <etext+0x88>
    802000e8:	f83ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  end    0x%016x (virtual)\n", end);
    802000ec:	00004597          	auipc	a1,0x4
    802000f0:	f3c58593          	addi	a1,a1,-196 # 80204028 <end>
    802000f4:	00001517          	auipc	a0,0x1
    802000f8:	94450513          	addi	a0,a0,-1724 # 80200a38 <etext+0xa8>
    802000fc:	f6fff0ef          	jal	ra,8020006a <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
    80200100:	00004597          	auipc	a1,0x4
    80200104:	32758593          	addi	a1,a1,807 # 80204427 <end+0x3ff>
    80200108:	00000797          	auipc	a5,0x0
    8020010c:	f0278793          	addi	a5,a5,-254 # 8020000a <kern_init>
    80200110:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
    80200114:	43f7d593          	srai	a1,a5,0x3f
}
    80200118:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
    8020011a:	3ff5f593          	andi	a1,a1,1023
    8020011e:	95be                	add	a1,a1,a5
    80200120:	85a9                	srai	a1,a1,0xa
    80200122:	00001517          	auipc	a0,0x1
    80200126:	93650513          	addi	a0,a0,-1738 # 80200a58 <etext+0xc8>
}
    8020012a:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
    8020012c:	bf3d                	j	8020006a <cprintf>

000000008020012e <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    8020012e:	1141                	addi	sp,sp,-16
    80200130:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
    80200132:	02000793          	li	a5,32
    80200136:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
    8020013a:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
    8020013e:	67e1                	lui	a5,0x18
    80200140:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0x801e7960>
    80200144:	953e                	add	a0,a0,a5
    80200146:	7e8000ef          	jal	ra,8020092e <sbi_set_timer>
}
    8020014a:	60a2                	ld	ra,8(sp)
    ticks = 0;
    8020014c:	00004797          	auipc	a5,0x4
    80200150:	ec07b223          	sd	zero,-316(a5) # 80204010 <ticks>
    cprintf("++ setup timer interrupts\n");
    80200154:	00001517          	auipc	a0,0x1
    80200158:	93450513          	addi	a0,a0,-1740 # 80200a88 <etext+0xf8>
}
    8020015c:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
    8020015e:	b731                	j	8020006a <cprintf>

0000000080200160 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
    80200160:	8082                	ret

0000000080200162 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
    80200162:	0ff57513          	zext.b	a0,a0
    80200166:	7ae0006f          	j	80200914 <sbi_console_putchar>

000000008020016a <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
    8020016a:	100167f3          	csrrsi	a5,sstatus,2
    8020016e:	8082                	ret

0000000080200170 <idt_init>:

void idt_init(void) {
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
    80200170:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
    80200174:	00000797          	auipc	a5,0x0
    80200178:	2fc78793          	addi	a5,a5,764 # 80200470 <__alltraps>
    8020017c:	10579073          	csrw	stvec,a5
}
    80200180:	8082                	ret

0000000080200182 <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
    80200182:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
    80200184:	1141                	addi	sp,sp,-16
    80200186:	e022                	sd	s0,0(sp)
    80200188:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
    8020018a:	00001517          	auipc	a0,0x1
    8020018e:	91e50513          	addi	a0,a0,-1762 # 80200aa8 <etext+0x118>
void print_regs(struct pushregs *gpr) {
    80200192:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
    80200194:	ed7ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
    80200198:	640c                	ld	a1,8(s0)
    8020019a:	00001517          	auipc	a0,0x1
    8020019e:	92650513          	addi	a0,a0,-1754 # 80200ac0 <etext+0x130>
    802001a2:	ec9ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
    802001a6:	680c                	ld	a1,16(s0)
    802001a8:	00001517          	auipc	a0,0x1
    802001ac:	93050513          	addi	a0,a0,-1744 # 80200ad8 <etext+0x148>
    802001b0:	ebbff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
    802001b4:	6c0c                	ld	a1,24(s0)
    802001b6:	00001517          	auipc	a0,0x1
    802001ba:	93a50513          	addi	a0,a0,-1734 # 80200af0 <etext+0x160>
    802001be:	eadff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
    802001c2:	700c                	ld	a1,32(s0)
    802001c4:	00001517          	auipc	a0,0x1
    802001c8:	94450513          	addi	a0,a0,-1724 # 80200b08 <etext+0x178>
    802001cc:	e9fff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
    802001d0:	740c                	ld	a1,40(s0)
    802001d2:	00001517          	auipc	a0,0x1
    802001d6:	94e50513          	addi	a0,a0,-1714 # 80200b20 <etext+0x190>
    802001da:	e91ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
    802001de:	780c                	ld	a1,48(s0)
    802001e0:	00001517          	auipc	a0,0x1
    802001e4:	95850513          	addi	a0,a0,-1704 # 80200b38 <etext+0x1a8>
    802001e8:	e83ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
    802001ec:	7c0c                	ld	a1,56(s0)
    802001ee:	00001517          	auipc	a0,0x1
    802001f2:	96250513          	addi	a0,a0,-1694 # 80200b50 <etext+0x1c0>
    802001f6:	e75ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
    802001fa:	602c                	ld	a1,64(s0)
    802001fc:	00001517          	auipc	a0,0x1
    80200200:	96c50513          	addi	a0,a0,-1684 # 80200b68 <etext+0x1d8>
    80200204:	e67ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
    80200208:	642c                	ld	a1,72(s0)
    8020020a:	00001517          	auipc	a0,0x1
    8020020e:	97650513          	addi	a0,a0,-1674 # 80200b80 <etext+0x1f0>
    80200212:	e59ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
    80200216:	682c                	ld	a1,80(s0)
    80200218:	00001517          	auipc	a0,0x1
    8020021c:	98050513          	addi	a0,a0,-1664 # 80200b98 <etext+0x208>
    80200220:	e4bff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
    80200224:	6c2c                	ld	a1,88(s0)
    80200226:	00001517          	auipc	a0,0x1
    8020022a:	98a50513          	addi	a0,a0,-1654 # 80200bb0 <etext+0x220>
    8020022e:	e3dff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
    80200232:	702c                	ld	a1,96(s0)
    80200234:	00001517          	auipc	a0,0x1
    80200238:	99450513          	addi	a0,a0,-1644 # 80200bc8 <etext+0x238>
    8020023c:	e2fff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
    80200240:	742c                	ld	a1,104(s0)
    80200242:	00001517          	auipc	a0,0x1
    80200246:	99e50513          	addi	a0,a0,-1634 # 80200be0 <etext+0x250>
    8020024a:	e21ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
    8020024e:	782c                	ld	a1,112(s0)
    80200250:	00001517          	auipc	a0,0x1
    80200254:	9a850513          	addi	a0,a0,-1624 # 80200bf8 <etext+0x268>
    80200258:	e13ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
    8020025c:	7c2c                	ld	a1,120(s0)
    8020025e:	00001517          	auipc	a0,0x1
    80200262:	9b250513          	addi	a0,a0,-1614 # 80200c10 <etext+0x280>
    80200266:	e05ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
    8020026a:	604c                	ld	a1,128(s0)
    8020026c:	00001517          	auipc	a0,0x1
    80200270:	9bc50513          	addi	a0,a0,-1604 # 80200c28 <etext+0x298>
    80200274:	df7ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
    80200278:	644c                	ld	a1,136(s0)
    8020027a:	00001517          	auipc	a0,0x1
    8020027e:	9c650513          	addi	a0,a0,-1594 # 80200c40 <etext+0x2b0>
    80200282:	de9ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
    80200286:	684c                	ld	a1,144(s0)
    80200288:	00001517          	auipc	a0,0x1
    8020028c:	9d050513          	addi	a0,a0,-1584 # 80200c58 <etext+0x2c8>
    80200290:	ddbff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
    80200294:	6c4c                	ld	a1,152(s0)
    80200296:	00001517          	auipc	a0,0x1
    8020029a:	9da50513          	addi	a0,a0,-1574 # 80200c70 <etext+0x2e0>
    8020029e:	dcdff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
    802002a2:	704c                	ld	a1,160(s0)
    802002a4:	00001517          	auipc	a0,0x1
    802002a8:	9e450513          	addi	a0,a0,-1564 # 80200c88 <etext+0x2f8>
    802002ac:	dbfff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
    802002b0:	744c                	ld	a1,168(s0)
    802002b2:	00001517          	auipc	a0,0x1
    802002b6:	9ee50513          	addi	a0,a0,-1554 # 80200ca0 <etext+0x310>
    802002ba:	db1ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
    802002be:	784c                	ld	a1,176(s0)
    802002c0:	00001517          	auipc	a0,0x1
    802002c4:	9f850513          	addi	a0,a0,-1544 # 80200cb8 <etext+0x328>
    802002c8:	da3ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
    802002cc:	7c4c                	ld	a1,184(s0)
    802002ce:	00001517          	auipc	a0,0x1
    802002d2:	a0250513          	addi	a0,a0,-1534 # 80200cd0 <etext+0x340>
    802002d6:	d95ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
    802002da:	606c                	ld	a1,192(s0)
    802002dc:	00001517          	auipc	a0,0x1
    802002e0:	a0c50513          	addi	a0,a0,-1524 # 80200ce8 <etext+0x358>
    802002e4:	d87ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
    802002e8:	646c                	ld	a1,200(s0)
    802002ea:	00001517          	auipc	a0,0x1
    802002ee:	a1650513          	addi	a0,a0,-1514 # 80200d00 <etext+0x370>
    802002f2:	d79ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
    802002f6:	686c                	ld	a1,208(s0)
    802002f8:	00001517          	auipc	a0,0x1
    802002fc:	a2050513          	addi	a0,a0,-1504 # 80200d18 <etext+0x388>
    80200300:	d6bff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
    80200304:	6c6c                	ld	a1,216(s0)
    80200306:	00001517          	auipc	a0,0x1
    8020030a:	a2a50513          	addi	a0,a0,-1494 # 80200d30 <etext+0x3a0>
    8020030e:	d5dff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
    80200312:	706c                	ld	a1,224(s0)
    80200314:	00001517          	auipc	a0,0x1
    80200318:	a3450513          	addi	a0,a0,-1484 # 80200d48 <etext+0x3b8>
    8020031c:	d4fff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
    80200320:	746c                	ld	a1,232(s0)
    80200322:	00001517          	auipc	a0,0x1
    80200326:	a3e50513          	addi	a0,a0,-1474 # 80200d60 <etext+0x3d0>
    8020032a:	d41ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
    8020032e:	786c                	ld	a1,240(s0)
    80200330:	00001517          	auipc	a0,0x1
    80200334:	a4850513          	addi	a0,a0,-1464 # 80200d78 <etext+0x3e8>
    80200338:	d33ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
    8020033c:	7c6c                	ld	a1,248(s0)
}
    8020033e:	6402                	ld	s0,0(sp)
    80200340:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
    80200342:	00001517          	auipc	a0,0x1
    80200346:	a4e50513          	addi	a0,a0,-1458 # 80200d90 <etext+0x400>
}
    8020034a:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
    8020034c:	bb39                	j	8020006a <cprintf>

000000008020034e <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
    8020034e:	1141                	addi	sp,sp,-16
    80200350:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
    80200352:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
    80200354:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
    80200356:	00001517          	auipc	a0,0x1
    8020035a:	a5250513          	addi	a0,a0,-1454 # 80200da8 <etext+0x418>
void print_trapframe(struct trapframe *tf) {
    8020035e:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
    80200360:	d0bff0ef          	jal	ra,8020006a <cprintf>
    print_regs(&tf->gpr);
    80200364:	8522                	mv	a0,s0
    80200366:	e1dff0ef          	jal	ra,80200182 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
    8020036a:	10043583          	ld	a1,256(s0)
    8020036e:	00001517          	auipc	a0,0x1
    80200372:	a5250513          	addi	a0,a0,-1454 # 80200dc0 <etext+0x430>
    80200376:	cf5ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
    8020037a:	10843583          	ld	a1,264(s0)
    8020037e:	00001517          	auipc	a0,0x1
    80200382:	a5a50513          	addi	a0,a0,-1446 # 80200dd8 <etext+0x448>
    80200386:	ce5ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    8020038a:	11043583          	ld	a1,272(s0)
    8020038e:	00001517          	auipc	a0,0x1
    80200392:	a6250513          	addi	a0,a0,-1438 # 80200df0 <etext+0x460>
    80200396:	cd5ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
    8020039a:	11843583          	ld	a1,280(s0)
}
    8020039e:	6402                	ld	s0,0(sp)
    802003a0:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
    802003a2:	00001517          	auipc	a0,0x1
    802003a6:	a6650513          	addi	a0,a0,-1434 # 80200e08 <etext+0x478>
}
    802003aa:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
    802003ac:	b97d                	j	8020006a <cprintf>

00000000802003ae <interrupt_handler>:


void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
    802003ae:	11853783          	ld	a5,280(a0)
    802003b2:	472d                	li	a4,11
    802003b4:	0786                	slli	a5,a5,0x1
    802003b6:	8385                	srli	a5,a5,0x1
    802003b8:	06f76163          	bltu	a4,a5,8020041a <interrupt_handler+0x6c>
    802003bc:	00001717          	auipc	a4,0x1
    802003c0:	b1470713          	addi	a4,a4,-1260 # 80200ed0 <etext+0x540>
    802003c4:	078a                	slli	a5,a5,0x2
    802003c6:	97ba                	add	a5,a5,a4
    802003c8:	439c                	lw	a5,0(a5)
    802003ca:	97ba                	add	a5,a5,a4
    802003cc:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
    802003ce:	00001517          	auipc	a0,0x1
    802003d2:	ab250513          	addi	a0,a0,-1358 # 80200e80 <etext+0x4f0>
    802003d6:	b951                	j	8020006a <cprintf>
            cprintf("Hypervisor software interrupt\n");
    802003d8:	00001517          	auipc	a0,0x1
    802003dc:	a8850513          	addi	a0,a0,-1400 # 80200e60 <etext+0x4d0>
    802003e0:	b169                	j	8020006a <cprintf>
            cprintf("User software interrupt\n");
    802003e2:	00001517          	auipc	a0,0x1
    802003e6:	a3e50513          	addi	a0,a0,-1474 # 80200e20 <etext+0x490>
    802003ea:	b141                	j	8020006a <cprintf>
            cprintf("Supervisor software interrupt\n");
    802003ec:	00001517          	auipc	a0,0x1
    802003f0:	a5450513          	addi	a0,a0,-1452 # 80200e40 <etext+0x4b0>
    802003f4:	b99d                	j	8020006a <cprintf>
            break;
        static int tick_count = 0;  // 用于计数时钟中断
	static int print_line_count = 0;  // 用于计数打印的行数
        case IRQ_S_TIMER:
            // 处理定时器中断
            tick_count++;  // 增加时钟中断计数
    802003f6:	00004717          	auipc	a4,0x4
    802003fa:	c2670713          	addi	a4,a4,-986 # 8020401c <tick_count.1>
    802003fe:	431c                	lw	a5,0(a4)
            if (tick_count >= 100) {
    80200400:	06300693          	li	a3,99
            tick_count++;  // 增加时钟中断计数
    80200404:	0017861b          	addiw	a2,a5,1
    80200408:	c310                	sw	a2,0(a4)
            if (tick_count >= 100) {
    8020040a:	00c6c963          	blt	a3,a2,8020041c <interrupt_handler+0x6e>
    8020040e:	8082                	ret
            break;
        case IRQ_U_EXT:
            cprintf("User software interrupt\n");
            break;
        case IRQ_S_EXT:
            cprintf("Supervisor external interrupt\n");
    80200410:	00001517          	auipc	a0,0x1
    80200414:	aa050513          	addi	a0,a0,-1376 # 80200eb0 <etext+0x520>
    80200418:	b989                	j	8020006a <cprintf>
            break;
        case IRQ_M_EXT:
            cprintf("Machine software interrupt\n");
            break;
        default:
            print_trapframe(tf);
    8020041a:	bf15                	j	8020034e <print_trapframe>
void interrupt_handler(struct trapframe *tf) {
    8020041c:	1141                	addi	sp,sp,-16
    cprintf("%d ticks\n", TICK_NUM);
    8020041e:	06400593          	li	a1,100
    80200422:	00001517          	auipc	a0,0x1
    80200426:	a7e50513          	addi	a0,a0,-1410 # 80200ea0 <etext+0x510>
void interrupt_handler(struct trapframe *tf) {
    8020042a:	e406                	sd	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
    8020042c:	c3fff0ef          	jal	ra,8020006a <cprintf>
                print_line_count++;  // 增加打印行计数
    80200430:	00004717          	auipc	a4,0x4
    80200434:	be870713          	addi	a4,a4,-1048 # 80204018 <print_line_count.0>
    80200438:	431c                	lw	a5,0(a4)
                tick_count = 0;  // 重置时钟计数器
    8020043a:	00004697          	auipc	a3,0x4
    8020043e:	be06a123          	sw	zero,-1054(a3) # 8020401c <tick_count.1>
                if (print_line_count >= 10) {
    80200442:	46a5                	li	a3,9
                print_line_count++;  // 增加打印行计数
    80200444:	0017861b          	addiw	a2,a5,1
    80200448:	c310                	sw	a2,0(a4)
                if (print_line_count >= 10) {
    8020044a:	00c6c563          	blt	a3,a2,80200454 <interrupt_handler+0xa6>
            break;
    }
}
    8020044e:	60a2                	ld	ra,8(sp)
    80200450:	0141                	addi	sp,sp,16
    80200452:	8082                	ret
    80200454:	60a2                	ld	ra,8(sp)
    80200456:	0141                	addi	sp,sp,16
    sbi_shutdown();
    80200458:	a9c5                	j	80200948 <sbi_shutdown>

000000008020045a <trap>:
    }
}

/* trap_dispatch - dispatch based on what type of trap occurred */
static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
    8020045a:	11853783          	ld	a5,280(a0)
    8020045e:	0007c763          	bltz	a5,8020046c <trap+0x12>
    switch (tf->cause) {
    80200462:	472d                	li	a4,11
    80200464:	00f76363          	bltu	a4,a5,8020046a <trap+0x10>
 * trap - handles or dispatches an exception/interrupt. if and when trap()
 * returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) { trap_dispatch(tf); }
    80200468:	8082                	ret
            print_trapframe(tf);
    8020046a:	b5d5                	j	8020034e <print_trapframe>
        interrupt_handler(tf);
    8020046c:	b789                	j	802003ae <interrupt_handler>
	...

0000000080200470 <__alltraps>:
    .endm

    .globl __alltraps
.align(2)
__alltraps:
    SAVE_ALL
    80200470:	14011073          	csrw	sscratch,sp
    80200474:	712d                	addi	sp,sp,-288
    80200476:	e002                	sd	zero,0(sp)
    80200478:	e406                	sd	ra,8(sp)
    8020047a:	ec0e                	sd	gp,24(sp)
    8020047c:	f012                	sd	tp,32(sp)
    8020047e:	f416                	sd	t0,40(sp)
    80200480:	f81a                	sd	t1,48(sp)
    80200482:	fc1e                	sd	t2,56(sp)
    80200484:	e0a2                	sd	s0,64(sp)
    80200486:	e4a6                	sd	s1,72(sp)
    80200488:	e8aa                	sd	a0,80(sp)
    8020048a:	ecae                	sd	a1,88(sp)
    8020048c:	f0b2                	sd	a2,96(sp)
    8020048e:	f4b6                	sd	a3,104(sp)
    80200490:	f8ba                	sd	a4,112(sp)
    80200492:	fcbe                	sd	a5,120(sp)
    80200494:	e142                	sd	a6,128(sp)
    80200496:	e546                	sd	a7,136(sp)
    80200498:	e94a                	sd	s2,144(sp)
    8020049a:	ed4e                	sd	s3,152(sp)
    8020049c:	f152                	sd	s4,160(sp)
    8020049e:	f556                	sd	s5,168(sp)
    802004a0:	f95a                	sd	s6,176(sp)
    802004a2:	fd5e                	sd	s7,184(sp)
    802004a4:	e1e2                	sd	s8,192(sp)
    802004a6:	e5e6                	sd	s9,200(sp)
    802004a8:	e9ea                	sd	s10,208(sp)
    802004aa:	edee                	sd	s11,216(sp)
    802004ac:	f1f2                	sd	t3,224(sp)
    802004ae:	f5f6                	sd	t4,232(sp)
    802004b0:	f9fa                	sd	t5,240(sp)
    802004b2:	fdfe                	sd	t6,248(sp)
    802004b4:	14001473          	csrrw	s0,sscratch,zero
    802004b8:	100024f3          	csrr	s1,sstatus
    802004bc:	14102973          	csrr	s2,sepc
    802004c0:	143029f3          	csrr	s3,stval
    802004c4:	14202a73          	csrr	s4,scause
    802004c8:	e822                	sd	s0,16(sp)
    802004ca:	e226                	sd	s1,256(sp)
    802004cc:	e64a                	sd	s2,264(sp)
    802004ce:	ea4e                	sd	s3,272(sp)
    802004d0:	ee52                	sd	s4,280(sp)

    move  a0, sp
    802004d2:	850a                	mv	a0,sp
    jal trap
    802004d4:	f87ff0ef          	jal	ra,8020045a <trap>

00000000802004d8 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
    802004d8:	6492                	ld	s1,256(sp)
    802004da:	6932                	ld	s2,264(sp)
    802004dc:	10049073          	csrw	sstatus,s1
    802004e0:	14191073          	csrw	sepc,s2
    802004e4:	60a2                	ld	ra,8(sp)
    802004e6:	61e2                	ld	gp,24(sp)
    802004e8:	7202                	ld	tp,32(sp)
    802004ea:	72a2                	ld	t0,40(sp)
    802004ec:	7342                	ld	t1,48(sp)
    802004ee:	73e2                	ld	t2,56(sp)
    802004f0:	6406                	ld	s0,64(sp)
    802004f2:	64a6                	ld	s1,72(sp)
    802004f4:	6546                	ld	a0,80(sp)
    802004f6:	65e6                	ld	a1,88(sp)
    802004f8:	7606                	ld	a2,96(sp)
    802004fa:	76a6                	ld	a3,104(sp)
    802004fc:	7746                	ld	a4,112(sp)
    802004fe:	77e6                	ld	a5,120(sp)
    80200500:	680a                	ld	a6,128(sp)
    80200502:	68aa                	ld	a7,136(sp)
    80200504:	694a                	ld	s2,144(sp)
    80200506:	69ea                	ld	s3,152(sp)
    80200508:	7a0a                	ld	s4,160(sp)
    8020050a:	7aaa                	ld	s5,168(sp)
    8020050c:	7b4a                	ld	s6,176(sp)
    8020050e:	7bea                	ld	s7,184(sp)
    80200510:	6c0e                	ld	s8,192(sp)
    80200512:	6cae                	ld	s9,200(sp)
    80200514:	6d4e                	ld	s10,208(sp)
    80200516:	6dee                	ld	s11,216(sp)
    80200518:	7e0e                	ld	t3,224(sp)
    8020051a:	7eae                	ld	t4,232(sp)
    8020051c:	7f4e                	ld	t5,240(sp)
    8020051e:	7fee                	ld	t6,248(sp)
    80200520:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
    80200522:	10200073          	sret

0000000080200526 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
    80200526:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
    8020052a:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
    8020052c:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
    80200530:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
    80200532:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
    80200536:	f022                	sd	s0,32(sp)
    80200538:	ec26                	sd	s1,24(sp)
    8020053a:	e84a                	sd	s2,16(sp)
    8020053c:	f406                	sd	ra,40(sp)
    8020053e:	e44e                	sd	s3,8(sp)
    80200540:	84aa                	mv	s1,a0
    80200542:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
    80200544:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
    80200548:	2a01                	sext.w	s4,s4
    if (num >= base) {
    8020054a:	03067e63          	bgeu	a2,a6,80200586 <printnum+0x60>
    8020054e:	89be                	mv	s3,a5
        while (-- width > 0)
    80200550:	00805763          	blez	s0,8020055e <printnum+0x38>
    80200554:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
    80200556:	85ca                	mv	a1,s2
    80200558:	854e                	mv	a0,s3
    8020055a:	9482                	jalr	s1
        while (-- width > 0)
    8020055c:	fc65                	bnez	s0,80200554 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
    8020055e:	1a02                	slli	s4,s4,0x20
    80200560:	00001797          	auipc	a5,0x1
    80200564:	9a078793          	addi	a5,a5,-1632 # 80200f00 <etext+0x570>
    80200568:	020a5a13          	srli	s4,s4,0x20
    8020056c:	9a3e                	add	s4,s4,a5
}
    8020056e:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
    80200570:	000a4503          	lbu	a0,0(s4)
}
    80200574:	70a2                	ld	ra,40(sp)
    80200576:	69a2                	ld	s3,8(sp)
    80200578:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
    8020057a:	85ca                	mv	a1,s2
    8020057c:	87a6                	mv	a5,s1
}
    8020057e:	6942                	ld	s2,16(sp)
    80200580:	64e2                	ld	s1,24(sp)
    80200582:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
    80200584:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
    80200586:	03065633          	divu	a2,a2,a6
    8020058a:	8722                	mv	a4,s0
    8020058c:	f9bff0ef          	jal	ra,80200526 <printnum>
    80200590:	b7f9                	j	8020055e <printnum+0x38>

0000000080200592 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
    80200592:	7119                	addi	sp,sp,-128
    80200594:	f4a6                	sd	s1,104(sp)
    80200596:	f0ca                	sd	s2,96(sp)
    80200598:	ecce                	sd	s3,88(sp)
    8020059a:	e8d2                	sd	s4,80(sp)
    8020059c:	e4d6                	sd	s5,72(sp)
    8020059e:	e0da                	sd	s6,64(sp)
    802005a0:	fc5e                	sd	s7,56(sp)
    802005a2:	f06a                	sd	s10,32(sp)
    802005a4:	fc86                	sd	ra,120(sp)
    802005a6:	f8a2                	sd	s0,112(sp)
    802005a8:	f862                	sd	s8,48(sp)
    802005aa:	f466                	sd	s9,40(sp)
    802005ac:	ec6e                	sd	s11,24(sp)
    802005ae:	892a                	mv	s2,a0
    802005b0:	84ae                	mv	s1,a1
    802005b2:	8d32                	mv	s10,a2
    802005b4:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    802005b6:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
    802005ba:	5b7d                	li	s6,-1
    802005bc:	00001a97          	auipc	s5,0x1
    802005c0:	978a8a93          	addi	s5,s5,-1672 # 80200f34 <etext+0x5a4>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
    802005c4:	00001b97          	auipc	s7,0x1
    802005c8:	b4cb8b93          	addi	s7,s7,-1204 # 80201110 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    802005cc:	000d4503          	lbu	a0,0(s10)
    802005d0:	001d0413          	addi	s0,s10,1
    802005d4:	01350a63          	beq	a0,s3,802005e8 <vprintfmt+0x56>
            if (ch == '\0') {
    802005d8:	c121                	beqz	a0,80200618 <vprintfmt+0x86>
            putch(ch, putdat);
    802005da:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    802005dc:	0405                	addi	s0,s0,1
            putch(ch, putdat);
    802005de:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    802005e0:	fff44503          	lbu	a0,-1(s0)
    802005e4:	ff351ae3          	bne	a0,s3,802005d8 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
    802005e8:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
    802005ec:	02000793          	li	a5,32
        lflag = altflag = 0;
    802005f0:	4c81                	li	s9,0
    802005f2:	4881                	li	a7,0
        width = precision = -1;
    802005f4:	5c7d                	li	s8,-1
    802005f6:	5dfd                	li	s11,-1
    802005f8:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
    802005fc:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
    802005fe:	fdd6059b          	addiw	a1,a2,-35
    80200602:	0ff5f593          	zext.b	a1,a1
    80200606:	00140d13          	addi	s10,s0,1
    8020060a:	04b56263          	bltu	a0,a1,8020064e <vprintfmt+0xbc>
    8020060e:	058a                	slli	a1,a1,0x2
    80200610:	95d6                	add	a1,a1,s5
    80200612:	4194                	lw	a3,0(a1)
    80200614:	96d6                	add	a3,a3,s5
    80200616:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
    80200618:	70e6                	ld	ra,120(sp)
    8020061a:	7446                	ld	s0,112(sp)
    8020061c:	74a6                	ld	s1,104(sp)
    8020061e:	7906                	ld	s2,96(sp)
    80200620:	69e6                	ld	s3,88(sp)
    80200622:	6a46                	ld	s4,80(sp)
    80200624:	6aa6                	ld	s5,72(sp)
    80200626:	6b06                	ld	s6,64(sp)
    80200628:	7be2                	ld	s7,56(sp)
    8020062a:	7c42                	ld	s8,48(sp)
    8020062c:	7ca2                	ld	s9,40(sp)
    8020062e:	7d02                	ld	s10,32(sp)
    80200630:	6de2                	ld	s11,24(sp)
    80200632:	6109                	addi	sp,sp,128
    80200634:	8082                	ret
            padc = '0';
    80200636:	87b2                	mv	a5,a2
            goto reswitch;
    80200638:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
    8020063c:	846a                	mv	s0,s10
    8020063e:	00140d13          	addi	s10,s0,1
    80200642:	fdd6059b          	addiw	a1,a2,-35
    80200646:	0ff5f593          	zext.b	a1,a1
    8020064a:	fcb572e3          	bgeu	a0,a1,8020060e <vprintfmt+0x7c>
            putch('%', putdat);
    8020064e:	85a6                	mv	a1,s1
    80200650:	02500513          	li	a0,37
    80200654:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
    80200656:	fff44783          	lbu	a5,-1(s0)
    8020065a:	8d22                	mv	s10,s0
    8020065c:	f73788e3          	beq	a5,s3,802005cc <vprintfmt+0x3a>
    80200660:	ffed4783          	lbu	a5,-2(s10)
    80200664:	1d7d                	addi	s10,s10,-1
    80200666:	ff379de3          	bne	a5,s3,80200660 <vprintfmt+0xce>
    8020066a:	b78d                	j	802005cc <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
    8020066c:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
    80200670:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
    80200674:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
    80200676:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
    8020067a:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
    8020067e:	02d86463          	bltu	a6,a3,802006a6 <vprintfmt+0x114>
                ch = *fmt;
    80200682:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
    80200686:	002c169b          	slliw	a3,s8,0x2
    8020068a:	0186873b          	addw	a4,a3,s8
    8020068e:	0017171b          	slliw	a4,a4,0x1
    80200692:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
    80200694:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
    80200698:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
    8020069a:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
    8020069e:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
    802006a2:	fed870e3          	bgeu	a6,a3,80200682 <vprintfmt+0xf0>
            if (width < 0)
    802006a6:	f40ddce3          	bgez	s11,802005fe <vprintfmt+0x6c>
                width = precision, precision = -1;
    802006aa:	8de2                	mv	s11,s8
    802006ac:	5c7d                	li	s8,-1
    802006ae:	bf81                	j	802005fe <vprintfmt+0x6c>
            if (width < 0)
    802006b0:	fffdc693          	not	a3,s11
    802006b4:	96fd                	srai	a3,a3,0x3f
    802006b6:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
    802006ba:	00144603          	lbu	a2,1(s0)
    802006be:	2d81                	sext.w	s11,s11
    802006c0:	846a                	mv	s0,s10
            goto reswitch;
    802006c2:	bf35                	j	802005fe <vprintfmt+0x6c>
            precision = va_arg(ap, int);
    802006c4:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
    802006c8:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
    802006cc:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
    802006ce:	846a                	mv	s0,s10
            goto process_precision;
    802006d0:	bfd9                	j	802006a6 <vprintfmt+0x114>
    if (lflag >= 2) {
    802006d2:	4705                	li	a4,1
            precision = va_arg(ap, int);
    802006d4:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
    802006d8:	01174463          	blt	a4,a7,802006e0 <vprintfmt+0x14e>
    else if (lflag) {
    802006dc:	1a088e63          	beqz	a7,80200898 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
    802006e0:	000a3603          	ld	a2,0(s4)
    802006e4:	46c1                	li	a3,16
    802006e6:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
    802006e8:	2781                	sext.w	a5,a5
    802006ea:	876e                	mv	a4,s11
    802006ec:	85a6                	mv	a1,s1
    802006ee:	854a                	mv	a0,s2
    802006f0:	e37ff0ef          	jal	ra,80200526 <printnum>
            break;
    802006f4:	bde1                	j	802005cc <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
    802006f6:	000a2503          	lw	a0,0(s4)
    802006fa:	85a6                	mv	a1,s1
    802006fc:	0a21                	addi	s4,s4,8
    802006fe:	9902                	jalr	s2
            break;
    80200700:	b5f1                	j	802005cc <vprintfmt+0x3a>
    if (lflag >= 2) {
    80200702:	4705                	li	a4,1
            precision = va_arg(ap, int);
    80200704:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
    80200708:	01174463          	blt	a4,a7,80200710 <vprintfmt+0x17e>
    else if (lflag) {
    8020070c:	18088163          	beqz	a7,8020088e <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
    80200710:	000a3603          	ld	a2,0(s4)
    80200714:	46a9                	li	a3,10
    80200716:	8a2e                	mv	s4,a1
    80200718:	bfc1                	j	802006e8 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
    8020071a:	00144603          	lbu	a2,1(s0)
            altflag = 1;
    8020071e:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
    80200720:	846a                	mv	s0,s10
            goto reswitch;
    80200722:	bdf1                	j	802005fe <vprintfmt+0x6c>
            putch(ch, putdat);
    80200724:	85a6                	mv	a1,s1
    80200726:	02500513          	li	a0,37
    8020072a:	9902                	jalr	s2
            break;
    8020072c:	b545                	j	802005cc <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
    8020072e:	00144603          	lbu	a2,1(s0)
            lflag ++;
    80200732:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
    80200734:	846a                	mv	s0,s10
            goto reswitch;
    80200736:	b5e1                	j	802005fe <vprintfmt+0x6c>
    if (lflag >= 2) {
    80200738:	4705                	li	a4,1
            precision = va_arg(ap, int);
    8020073a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
    8020073e:	01174463          	blt	a4,a7,80200746 <vprintfmt+0x1b4>
    else if (lflag) {
    80200742:	14088163          	beqz	a7,80200884 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
    80200746:	000a3603          	ld	a2,0(s4)
    8020074a:	46a1                	li	a3,8
    8020074c:	8a2e                	mv	s4,a1
    8020074e:	bf69                	j	802006e8 <vprintfmt+0x156>
            putch('0', putdat);
    80200750:	03000513          	li	a0,48
    80200754:	85a6                	mv	a1,s1
    80200756:	e03e                	sd	a5,0(sp)
    80200758:	9902                	jalr	s2
            putch('x', putdat);
    8020075a:	85a6                	mv	a1,s1
    8020075c:	07800513          	li	a0,120
    80200760:	9902                	jalr	s2
            num = (unsigned long long)va_arg(ap, void *);
    80200762:	0a21                	addi	s4,s4,8
            goto number;
    80200764:	6782                	ld	a5,0(sp)
    80200766:	46c1                	li	a3,16
            num = (unsigned long long)va_arg(ap, void *);
    80200768:	ff8a3603          	ld	a2,-8(s4)
            goto number;
    8020076c:	bfb5                	j	802006e8 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
    8020076e:	000a3403          	ld	s0,0(s4)
    80200772:	008a0713          	addi	a4,s4,8
    80200776:	e03a                	sd	a4,0(sp)
    80200778:	14040263          	beqz	s0,802008bc <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
    8020077c:	0fb05763          	blez	s11,8020086a <vprintfmt+0x2d8>
    80200780:	02d00693          	li	a3,45
    80200784:	0cd79163          	bne	a5,a3,80200846 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    80200788:	00044783          	lbu	a5,0(s0)
    8020078c:	0007851b          	sext.w	a0,a5
    80200790:	cf85                	beqz	a5,802007c8 <vprintfmt+0x236>
    80200792:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
    80200796:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    8020079a:	000c4563          	bltz	s8,802007a4 <vprintfmt+0x212>
    8020079e:	3c7d                	addiw	s8,s8,-1
    802007a0:	036c0263          	beq	s8,s6,802007c4 <vprintfmt+0x232>
                    putch('?', putdat);
    802007a4:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
    802007a6:	0e0c8e63          	beqz	s9,802008a2 <vprintfmt+0x310>
    802007aa:	3781                	addiw	a5,a5,-32
    802007ac:	0ef47b63          	bgeu	s0,a5,802008a2 <vprintfmt+0x310>
                    putch('?', putdat);
    802007b0:	03f00513          	li	a0,63
    802007b4:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    802007b6:	000a4783          	lbu	a5,0(s4)
    802007ba:	3dfd                	addiw	s11,s11,-1
    802007bc:	0a05                	addi	s4,s4,1
    802007be:	0007851b          	sext.w	a0,a5
    802007c2:	ffe1                	bnez	a5,8020079a <vprintfmt+0x208>
            for (; width > 0; width --) {
    802007c4:	01b05963          	blez	s11,802007d6 <vprintfmt+0x244>
    802007c8:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
    802007ca:	85a6                	mv	a1,s1
    802007cc:	02000513          	li	a0,32
    802007d0:	9902                	jalr	s2
            for (; width > 0; width --) {
    802007d2:	fe0d9be3          	bnez	s11,802007c8 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
    802007d6:	6a02                	ld	s4,0(sp)
    802007d8:	bbd5                	j	802005cc <vprintfmt+0x3a>
    if (lflag >= 2) {
    802007da:	4705                	li	a4,1
            precision = va_arg(ap, int);
    802007dc:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
    802007e0:	01174463          	blt	a4,a7,802007e8 <vprintfmt+0x256>
    else if (lflag) {
    802007e4:	08088d63          	beqz	a7,8020087e <vprintfmt+0x2ec>
        return va_arg(*ap, long);
    802007e8:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
    802007ec:	0a044d63          	bltz	s0,802008a6 <vprintfmt+0x314>
            num = getint(&ap, lflag);
    802007f0:	8622                	mv	a2,s0
    802007f2:	8a66                	mv	s4,s9
    802007f4:	46a9                	li	a3,10
    802007f6:	bdcd                	j	802006e8 <vprintfmt+0x156>
            err = va_arg(ap, int);
    802007f8:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
    802007fc:	4719                	li	a4,6
            err = va_arg(ap, int);
    802007fe:	0a21                	addi	s4,s4,8
            if (err < 0) {
    80200800:	41f7d69b          	sraiw	a3,a5,0x1f
    80200804:	8fb5                	xor	a5,a5,a3
    80200806:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
    8020080a:	02d74163          	blt	a4,a3,8020082c <vprintfmt+0x29a>
    8020080e:	00369793          	slli	a5,a3,0x3
    80200812:	97de                	add	a5,a5,s7
    80200814:	639c                	ld	a5,0(a5)
    80200816:	cb99                	beqz	a5,8020082c <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
    80200818:	86be                	mv	a3,a5
    8020081a:	00000617          	auipc	a2,0x0
    8020081e:	71660613          	addi	a2,a2,1814 # 80200f30 <etext+0x5a0>
    80200822:	85a6                	mv	a1,s1
    80200824:	854a                	mv	a0,s2
    80200826:	0ce000ef          	jal	ra,802008f4 <printfmt>
    8020082a:	b34d                	j	802005cc <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
    8020082c:	00000617          	auipc	a2,0x0
    80200830:	6f460613          	addi	a2,a2,1780 # 80200f20 <etext+0x590>
    80200834:	85a6                	mv	a1,s1
    80200836:	854a                	mv	a0,s2
    80200838:	0bc000ef          	jal	ra,802008f4 <printfmt>
    8020083c:	bb41                	j	802005cc <vprintfmt+0x3a>
                p = "(null)";
    8020083e:	00000417          	auipc	s0,0x0
    80200842:	6da40413          	addi	s0,s0,1754 # 80200f18 <etext+0x588>
                for (width -= strnlen(p, precision); width > 0; width --) {
    80200846:	85e2                	mv	a1,s8
    80200848:	8522                	mv	a0,s0
    8020084a:	e43e                	sd	a5,8(sp)
    8020084c:	116000ef          	jal	ra,80200962 <strnlen>
    80200850:	40ad8dbb          	subw	s11,s11,a0
    80200854:	01b05b63          	blez	s11,8020086a <vprintfmt+0x2d8>
                    putch(padc, putdat);
    80200858:	67a2                	ld	a5,8(sp)
    8020085a:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
    8020085e:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
    80200860:	85a6                	mv	a1,s1
    80200862:	8552                	mv	a0,s4
    80200864:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
    80200866:	fe0d9ce3          	bnez	s11,8020085e <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    8020086a:	00044783          	lbu	a5,0(s0)
    8020086e:	00140a13          	addi	s4,s0,1
    80200872:	0007851b          	sext.w	a0,a5
    80200876:	d3a5                	beqz	a5,802007d6 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
    80200878:	05e00413          	li	s0,94
    8020087c:	bf39                	j	8020079a <vprintfmt+0x208>
        return va_arg(*ap, int);
    8020087e:	000a2403          	lw	s0,0(s4)
    80200882:	b7ad                	j	802007ec <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
    80200884:	000a6603          	lwu	a2,0(s4)
    80200888:	46a1                	li	a3,8
    8020088a:	8a2e                	mv	s4,a1
    8020088c:	bdb1                	j	802006e8 <vprintfmt+0x156>
    8020088e:	000a6603          	lwu	a2,0(s4)
    80200892:	46a9                	li	a3,10
    80200894:	8a2e                	mv	s4,a1
    80200896:	bd89                	j	802006e8 <vprintfmt+0x156>
    80200898:	000a6603          	lwu	a2,0(s4)
    8020089c:	46c1                	li	a3,16
    8020089e:	8a2e                	mv	s4,a1
    802008a0:	b5a1                	j	802006e8 <vprintfmt+0x156>
                    putch(ch, putdat);
    802008a2:	9902                	jalr	s2
    802008a4:	bf09                	j	802007b6 <vprintfmt+0x224>
                putch('-', putdat);
    802008a6:	85a6                	mv	a1,s1
    802008a8:	02d00513          	li	a0,45
    802008ac:	e03e                	sd	a5,0(sp)
    802008ae:	9902                	jalr	s2
                num = -(long long)num;
    802008b0:	6782                	ld	a5,0(sp)
    802008b2:	8a66                	mv	s4,s9
    802008b4:	40800633          	neg	a2,s0
    802008b8:	46a9                	li	a3,10
    802008ba:	b53d                	j	802006e8 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
    802008bc:	03b05163          	blez	s11,802008de <vprintfmt+0x34c>
    802008c0:	02d00693          	li	a3,45
    802008c4:	f6d79de3          	bne	a5,a3,8020083e <vprintfmt+0x2ac>
                p = "(null)";
    802008c8:	00000417          	auipc	s0,0x0
    802008cc:	65040413          	addi	s0,s0,1616 # 80200f18 <etext+0x588>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    802008d0:	02800793          	li	a5,40
    802008d4:	02800513          	li	a0,40
    802008d8:	00140a13          	addi	s4,s0,1
    802008dc:	bd6d                	j	80200796 <vprintfmt+0x204>
    802008de:	00000a17          	auipc	s4,0x0
    802008e2:	63ba0a13          	addi	s4,s4,1595 # 80200f19 <etext+0x589>
    802008e6:	02800513          	li	a0,40
    802008ea:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
    802008ee:	05e00413          	li	s0,94
    802008f2:	b565                	j	8020079a <vprintfmt+0x208>

00000000802008f4 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
    802008f4:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
    802008f6:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
    802008fa:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
    802008fc:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
    802008fe:	ec06                	sd	ra,24(sp)
    80200900:	f83a                	sd	a4,48(sp)
    80200902:	fc3e                	sd	a5,56(sp)
    80200904:	e0c2                	sd	a6,64(sp)
    80200906:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
    80200908:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
    8020090a:	c89ff0ef          	jal	ra,80200592 <vprintfmt>
}
    8020090e:	60e2                	ld	ra,24(sp)
    80200910:	6161                	addi	sp,sp,80
    80200912:	8082                	ret

0000000080200914 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
    80200914:	4781                	li	a5,0
    80200916:	00003717          	auipc	a4,0x3
    8020091a:	6ea73703          	ld	a4,1770(a4) # 80204000 <SBI_CONSOLE_PUTCHAR>
    8020091e:	88ba                	mv	a7,a4
    80200920:	852a                	mv	a0,a0
    80200922:	85be                	mv	a1,a5
    80200924:	863e                	mv	a2,a5
    80200926:	00000073          	ecall
    8020092a:	87aa                	mv	a5,a0
int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
    8020092c:	8082                	ret

000000008020092e <sbi_set_timer>:
    __asm__ volatile (
    8020092e:	4781                	li	a5,0
    80200930:	00003717          	auipc	a4,0x3
    80200934:	6f073703          	ld	a4,1776(a4) # 80204020 <SBI_SET_TIMER>
    80200938:	88ba                	mv	a7,a4
    8020093a:	852a                	mv	a0,a0
    8020093c:	85be                	mv	a1,a5
    8020093e:	863e                	mv	a2,a5
    80200940:	00000073          	ecall
    80200944:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
    80200946:	8082                	ret

0000000080200948 <sbi_shutdown>:
    __asm__ volatile (
    80200948:	4781                	li	a5,0
    8020094a:	00003717          	auipc	a4,0x3
    8020094e:	6be73703          	ld	a4,1726(a4) # 80204008 <SBI_SHUTDOWN>
    80200952:	88ba                	mv	a7,a4
    80200954:	853e                	mv	a0,a5
    80200956:	85be                	mv	a1,a5
    80200958:	863e                	mv	a2,a5
    8020095a:	00000073          	ecall
    8020095e:	87aa                	mv	a5,a0


void sbi_shutdown(void)
{
    sbi_call(SBI_SHUTDOWN,0,0,0);
    80200960:	8082                	ret

0000000080200962 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    80200962:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
    80200964:	e589                	bnez	a1,8020096e <strnlen+0xc>
    80200966:	a811                	j	8020097a <strnlen+0x18>
        cnt ++;
    80200968:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
    8020096a:	00f58863          	beq	a1,a5,8020097a <strnlen+0x18>
    8020096e:	00f50733          	add	a4,a0,a5
    80200972:	00074703          	lbu	a4,0(a4)
    80200976:	fb6d                	bnez	a4,80200968 <strnlen+0x6>
    80200978:	85be                	mv	a1,a5
    }
    return cnt;
}
    8020097a:	852e                	mv	a0,a1
    8020097c:	8082                	ret

000000008020097e <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
    8020097e:	ca01                	beqz	a2,8020098e <memset+0x10>
    80200980:	962a                	add	a2,a2,a0
    char *p = s;
    80200982:	87aa                	mv	a5,a0
        *p ++ = c;
    80200984:	0785                	addi	a5,a5,1
    80200986:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
    8020098a:	fec79de3          	bne	a5,a2,80200984 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
    8020098e:	8082                	ret
