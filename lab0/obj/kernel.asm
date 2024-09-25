
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080200000 <kern_entry>:
#include <memlayout.h>

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    la sp, bootstacktop
    80200000:	00003117          	auipc	sp,0x3
    80200004:	00010113          	mv	sp,sp

    tail kern_init
    80200008:	a009                	j	8020000a <kern_init>

000000008020000a <kern_init>:
#include <sbi.h>
int kern_init(void) __attribute__((noreturn));

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
    8020000a:	00003517          	auipc	a0,0x3
    8020000e:	ffe50513          	addi	a0,a0,-2 # 80203008 <edata>
    80200012:	00003617          	auipc	a2,0x3
    80200016:	ff660613          	addi	a2,a2,-10 # 80203008 <edata>
int kern_init(void) {
    8020001a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
    8020001c:	4581                	li	a1,0
    8020001e:	8e09                	sub	a2,a2,a0
int kern_init(void) {
    80200020:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
    80200022:	08c000ef          	jal	ra,802000ae <memset>

    const char *message = "(THU.CST) os is loading ...\n";
    cprintf("%s\n\n", message);
    80200026:	00000597          	auipc	a1,0x0
    8020002a:	4a258593          	addi	a1,a1,1186 # 802004c8 <sbi_console_putchar+0x1a>
    8020002e:	00000517          	auipc	a0,0x0
    80200032:	4ba50513          	addi	a0,a0,1210 # 802004e8 <sbi_console_putchar+0x3a>
    80200036:	020000ef          	jal	ra,80200056 <cprintf>
   while (1)
    8020003a:	a001                	j	8020003a <kern_init+0x30>

000000008020003c <cputch>:

/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void cputch(int c, int *cnt) {
    8020003c:	1141                	addi	sp,sp,-16
    8020003e:	e022                	sd	s0,0(sp)
    80200040:	e406                	sd	ra,8(sp)
    80200042:	842e                	mv	s0,a1
    cons_putc(c);
    80200044:	048000ef          	jal	ra,8020008c <cons_putc>
    (*cnt)++;
    80200048:	401c                	lw	a5,0(s0)
}
    8020004a:	60a2                	ld	ra,8(sp)
    (*cnt)++;
    8020004c:	2785                	addiw	a5,a5,1
    8020004e:	c01c                	sw	a5,0(s0)
}
    80200050:	6402                	ld	s0,0(sp)
    80200052:	0141                	addi	sp,sp,16
    80200054:	8082                	ret

0000000080200056 <cprintf>:
 * cprintf - formats a string and writes it to stdout
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...) {
    80200056:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
    80200058:	02810313          	addi	t1,sp,40 # 80203028 <edata+0x20>
int cprintf(const char *fmt, ...) {
    8020005c:	8e2a                	mv	t3,a0
    8020005e:	f42e                	sd	a1,40(sp)
    80200060:	f832                	sd	a2,48(sp)
    80200062:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
    80200064:	00000517          	auipc	a0,0x0
    80200068:	fd850513          	addi	a0,a0,-40 # 8020003c <cputch>
    8020006c:	004c                	addi	a1,sp,4
    8020006e:	869a                	mv	a3,t1
    80200070:	8672                	mv	a2,t3
int cprintf(const char *fmt, ...) {
    80200072:	ec06                	sd	ra,24(sp)
    80200074:	e0ba                	sd	a4,64(sp)
    80200076:	e4be                	sd	a5,72(sp)
    80200078:	e8c2                	sd	a6,80(sp)
    8020007a:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
    8020007c:	e41a                	sd	t1,8(sp)
    int cnt = 0;
    8020007e:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
    80200080:	0ac000ef          	jal	ra,8020012c <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
    80200084:	60e2                	ld	ra,24(sp)
    80200086:	4512                	lw	a0,4(sp)
    80200088:	6125                	addi	sp,sp,96
    8020008a:	8082                	ret

000000008020008c <cons_putc>:

/* cons_init - initializes the console devices */
void cons_init(void) {}

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
    8020008c:	0ff57513          	zext.b	a0,a0
    80200090:	a939                	j	802004ae <sbi_console_putchar>

0000000080200092 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    80200092:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
    80200094:	e589                	bnez	a1,8020009e <strnlen+0xc>
    80200096:	a811                	j	802000aa <strnlen+0x18>
        cnt ++;
    80200098:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
    8020009a:	00f58863          	beq	a1,a5,802000aa <strnlen+0x18>
    8020009e:	00f50733          	add	a4,a0,a5
    802000a2:	00074703          	lbu	a4,0(a4)
    802000a6:	fb6d                	bnez	a4,80200098 <strnlen+0x6>
    802000a8:	85be                	mv	a1,a5
    }
    return cnt;
}
    802000aa:	852e                	mv	a0,a1
    802000ac:	8082                	ret

00000000802000ae <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
    802000ae:	ca01                	beqz	a2,802000be <memset+0x10>
    802000b0:	962a                	add	a2,a2,a0
    char *p = s;
    802000b2:	87aa                	mv	a5,a0
        *p ++ = c;
    802000b4:	0785                	addi	a5,a5,1
    802000b6:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
    802000ba:	fec79de3          	bne	a5,a2,802000b4 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
    802000be:	8082                	ret

00000000802000c0 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
    802000c0:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
    802000c4:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
    802000c6:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
    802000ca:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
    802000cc:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
    802000d0:	f022                	sd	s0,32(sp)
    802000d2:	ec26                	sd	s1,24(sp)
    802000d4:	e84a                	sd	s2,16(sp)
    802000d6:	f406                	sd	ra,40(sp)
    802000d8:	e44e                	sd	s3,8(sp)
    802000da:	84aa                	mv	s1,a0
    802000dc:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
    802000de:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
    802000e2:	2a01                	sext.w	s4,s4
    if (num >= base) {
    802000e4:	03067e63          	bgeu	a2,a6,80200120 <printnum+0x60>
    802000e8:	89be                	mv	s3,a5
        while (-- width > 0)
    802000ea:	00805763          	blez	s0,802000f8 <printnum+0x38>
    802000ee:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
    802000f0:	85ca                	mv	a1,s2
    802000f2:	854e                	mv	a0,s3
    802000f4:	9482                	jalr	s1
        while (-- width > 0)
    802000f6:	fc65                	bnez	s0,802000ee <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
    802000f8:	1a02                	slli	s4,s4,0x20
    802000fa:	00000797          	auipc	a5,0x0
    802000fe:	3f678793          	addi	a5,a5,1014 # 802004f0 <sbi_console_putchar+0x42>
    80200102:	020a5a13          	srli	s4,s4,0x20
    80200106:	9a3e                	add	s4,s4,a5
}
    80200108:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
    8020010a:	000a4503          	lbu	a0,0(s4)
}
    8020010e:	70a2                	ld	ra,40(sp)
    80200110:	69a2                	ld	s3,8(sp)
    80200112:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
    80200114:	85ca                	mv	a1,s2
    80200116:	87a6                	mv	a5,s1
}
    80200118:	6942                	ld	s2,16(sp)
    8020011a:	64e2                	ld	s1,24(sp)
    8020011c:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
    8020011e:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
    80200120:	03065633          	divu	a2,a2,a6
    80200124:	8722                	mv	a4,s0
    80200126:	f9bff0ef          	jal	ra,802000c0 <printnum>
    8020012a:	b7f9                	j	802000f8 <printnum+0x38>

000000008020012c <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
    8020012c:	7119                	addi	sp,sp,-128
    8020012e:	f4a6                	sd	s1,104(sp)
    80200130:	f0ca                	sd	s2,96(sp)
    80200132:	ecce                	sd	s3,88(sp)
    80200134:	e8d2                	sd	s4,80(sp)
    80200136:	e4d6                	sd	s5,72(sp)
    80200138:	e0da                	sd	s6,64(sp)
    8020013a:	fc5e                	sd	s7,56(sp)
    8020013c:	f06a                	sd	s10,32(sp)
    8020013e:	fc86                	sd	ra,120(sp)
    80200140:	f8a2                	sd	s0,112(sp)
    80200142:	f862                	sd	s8,48(sp)
    80200144:	f466                	sd	s9,40(sp)
    80200146:	ec6e                	sd	s11,24(sp)
    80200148:	892a                	mv	s2,a0
    8020014a:	84ae                	mv	s1,a1
    8020014c:	8d32                	mv	s10,a2
    8020014e:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    80200150:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
    80200154:	5b7d                	li	s6,-1
    80200156:	00000a97          	auipc	s5,0x0
    8020015a:	3cea8a93          	addi	s5,s5,974 # 80200524 <sbi_console_putchar+0x76>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
    8020015e:	00000b97          	auipc	s7,0x0
    80200162:	5a2b8b93          	addi	s7,s7,1442 # 80200700 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    80200166:	000d4503          	lbu	a0,0(s10)
    8020016a:	001d0413          	addi	s0,s10,1
    8020016e:	01350a63          	beq	a0,s3,80200182 <vprintfmt+0x56>
            if (ch == '\0') {
    80200172:	c121                	beqz	a0,802001b2 <vprintfmt+0x86>
            putch(ch, putdat);
    80200174:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    80200176:	0405                	addi	s0,s0,1
            putch(ch, putdat);
    80200178:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    8020017a:	fff44503          	lbu	a0,-1(s0)
    8020017e:	ff351ae3          	bne	a0,s3,80200172 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
    80200182:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
    80200186:	02000793          	li	a5,32
        lflag = altflag = 0;
    8020018a:	4c81                	li	s9,0
    8020018c:	4881                	li	a7,0
        width = precision = -1;
    8020018e:	5c7d                	li	s8,-1
    80200190:	5dfd                	li	s11,-1
    80200192:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
    80200196:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
    80200198:	fdd6059b          	addiw	a1,a2,-35
    8020019c:	0ff5f593          	zext.b	a1,a1
    802001a0:	00140d13          	addi	s10,s0,1
    802001a4:	04b56263          	bltu	a0,a1,802001e8 <vprintfmt+0xbc>
    802001a8:	058a                	slli	a1,a1,0x2
    802001aa:	95d6                	add	a1,a1,s5
    802001ac:	4194                	lw	a3,0(a1)
    802001ae:	96d6                	add	a3,a3,s5
    802001b0:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
    802001b2:	70e6                	ld	ra,120(sp)
    802001b4:	7446                	ld	s0,112(sp)
    802001b6:	74a6                	ld	s1,104(sp)
    802001b8:	7906                	ld	s2,96(sp)
    802001ba:	69e6                	ld	s3,88(sp)
    802001bc:	6a46                	ld	s4,80(sp)
    802001be:	6aa6                	ld	s5,72(sp)
    802001c0:	6b06                	ld	s6,64(sp)
    802001c2:	7be2                	ld	s7,56(sp)
    802001c4:	7c42                	ld	s8,48(sp)
    802001c6:	7ca2                	ld	s9,40(sp)
    802001c8:	7d02                	ld	s10,32(sp)
    802001ca:	6de2                	ld	s11,24(sp)
    802001cc:	6109                	addi	sp,sp,128
    802001ce:	8082                	ret
            padc = '0';
    802001d0:	87b2                	mv	a5,a2
            goto reswitch;
    802001d2:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
    802001d6:	846a                	mv	s0,s10
    802001d8:	00140d13          	addi	s10,s0,1
    802001dc:	fdd6059b          	addiw	a1,a2,-35
    802001e0:	0ff5f593          	zext.b	a1,a1
    802001e4:	fcb572e3          	bgeu	a0,a1,802001a8 <vprintfmt+0x7c>
            putch('%', putdat);
    802001e8:	85a6                	mv	a1,s1
    802001ea:	02500513          	li	a0,37
    802001ee:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
    802001f0:	fff44783          	lbu	a5,-1(s0)
    802001f4:	8d22                	mv	s10,s0
    802001f6:	f73788e3          	beq	a5,s3,80200166 <vprintfmt+0x3a>
    802001fa:	ffed4783          	lbu	a5,-2(s10)
    802001fe:	1d7d                	addi	s10,s10,-1
    80200200:	ff379de3          	bne	a5,s3,802001fa <vprintfmt+0xce>
    80200204:	b78d                	j	80200166 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
    80200206:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
    8020020a:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
    8020020e:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
    80200210:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
    80200214:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
    80200218:	02d86463          	bltu	a6,a3,80200240 <vprintfmt+0x114>
                ch = *fmt;
    8020021c:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
    80200220:	002c169b          	slliw	a3,s8,0x2
    80200224:	0186873b          	addw	a4,a3,s8
    80200228:	0017171b          	slliw	a4,a4,0x1
    8020022c:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
    8020022e:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
    80200232:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
    80200234:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
    80200238:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
    8020023c:	fed870e3          	bgeu	a6,a3,8020021c <vprintfmt+0xf0>
            if (width < 0)
    80200240:	f40ddce3          	bgez	s11,80200198 <vprintfmt+0x6c>
                width = precision, precision = -1;
    80200244:	8de2                	mv	s11,s8
    80200246:	5c7d                	li	s8,-1
    80200248:	bf81                	j	80200198 <vprintfmt+0x6c>
            if (width < 0)
    8020024a:	fffdc693          	not	a3,s11
    8020024e:	96fd                	srai	a3,a3,0x3f
    80200250:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
    80200254:	00144603          	lbu	a2,1(s0)
    80200258:	2d81                	sext.w	s11,s11
    8020025a:	846a                	mv	s0,s10
            goto reswitch;
    8020025c:	bf35                	j	80200198 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
    8020025e:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
    80200262:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
    80200266:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
    80200268:	846a                	mv	s0,s10
            goto process_precision;
    8020026a:	bfd9                	j	80200240 <vprintfmt+0x114>
    if (lflag >= 2) {
    8020026c:	4705                	li	a4,1
            precision = va_arg(ap, int);
    8020026e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
    80200272:	01174463          	blt	a4,a7,8020027a <vprintfmt+0x14e>
    else if (lflag) {
    80200276:	1a088e63          	beqz	a7,80200432 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
    8020027a:	000a3603          	ld	a2,0(s4)
    8020027e:	46c1                	li	a3,16
    80200280:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
    80200282:	2781                	sext.w	a5,a5
    80200284:	876e                	mv	a4,s11
    80200286:	85a6                	mv	a1,s1
    80200288:	854a                	mv	a0,s2
    8020028a:	e37ff0ef          	jal	ra,802000c0 <printnum>
            break;
    8020028e:	bde1                	j	80200166 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
    80200290:	000a2503          	lw	a0,0(s4)
    80200294:	85a6                	mv	a1,s1
    80200296:	0a21                	addi	s4,s4,8
    80200298:	9902                	jalr	s2
            break;
    8020029a:	b5f1                	j	80200166 <vprintfmt+0x3a>
    if (lflag >= 2) {
    8020029c:	4705                	li	a4,1
            precision = va_arg(ap, int);
    8020029e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
    802002a2:	01174463          	blt	a4,a7,802002aa <vprintfmt+0x17e>
    else if (lflag) {
    802002a6:	18088163          	beqz	a7,80200428 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
    802002aa:	000a3603          	ld	a2,0(s4)
    802002ae:	46a9                	li	a3,10
    802002b0:	8a2e                	mv	s4,a1
    802002b2:	bfc1                	j	80200282 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
    802002b4:	00144603          	lbu	a2,1(s0)
            altflag = 1;
    802002b8:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
    802002ba:	846a                	mv	s0,s10
            goto reswitch;
    802002bc:	bdf1                	j	80200198 <vprintfmt+0x6c>
            putch(ch, putdat);
    802002be:	85a6                	mv	a1,s1
    802002c0:	02500513          	li	a0,37
    802002c4:	9902                	jalr	s2
            break;
    802002c6:	b545                	j	80200166 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
    802002c8:	00144603          	lbu	a2,1(s0)
            lflag ++;
    802002cc:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
    802002ce:	846a                	mv	s0,s10
            goto reswitch;
    802002d0:	b5e1                	j	80200198 <vprintfmt+0x6c>
    if (lflag >= 2) {
    802002d2:	4705                	li	a4,1
            precision = va_arg(ap, int);
    802002d4:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
    802002d8:	01174463          	blt	a4,a7,802002e0 <vprintfmt+0x1b4>
    else if (lflag) {
    802002dc:	14088163          	beqz	a7,8020041e <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
    802002e0:	000a3603          	ld	a2,0(s4)
    802002e4:	46a1                	li	a3,8
    802002e6:	8a2e                	mv	s4,a1
    802002e8:	bf69                	j	80200282 <vprintfmt+0x156>
            putch('0', putdat);
    802002ea:	03000513          	li	a0,48
    802002ee:	85a6                	mv	a1,s1
    802002f0:	e03e                	sd	a5,0(sp)
    802002f2:	9902                	jalr	s2
            putch('x', putdat);
    802002f4:	85a6                	mv	a1,s1
    802002f6:	07800513          	li	a0,120
    802002fa:	9902                	jalr	s2
            num = (unsigned long long)va_arg(ap, void *);
    802002fc:	0a21                	addi	s4,s4,8
            goto number;
    802002fe:	6782                	ld	a5,0(sp)
    80200300:	46c1                	li	a3,16
            num = (unsigned long long)va_arg(ap, void *);
    80200302:	ff8a3603          	ld	a2,-8(s4)
            goto number;
    80200306:	bfb5                	j	80200282 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
    80200308:	000a3403          	ld	s0,0(s4)
    8020030c:	008a0713          	addi	a4,s4,8
    80200310:	e03a                	sd	a4,0(sp)
    80200312:	14040263          	beqz	s0,80200456 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
    80200316:	0fb05763          	blez	s11,80200404 <vprintfmt+0x2d8>
    8020031a:	02d00693          	li	a3,45
    8020031e:	0cd79163          	bne	a5,a3,802003e0 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    80200322:	00044783          	lbu	a5,0(s0)
    80200326:	0007851b          	sext.w	a0,a5
    8020032a:	cf85                	beqz	a5,80200362 <vprintfmt+0x236>
    8020032c:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
    80200330:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    80200334:	000c4563          	bltz	s8,8020033e <vprintfmt+0x212>
    80200338:	3c7d                	addiw	s8,s8,-1
    8020033a:	036c0263          	beq	s8,s6,8020035e <vprintfmt+0x232>
                    putch('?', putdat);
    8020033e:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
    80200340:	0e0c8e63          	beqz	s9,8020043c <vprintfmt+0x310>
    80200344:	3781                	addiw	a5,a5,-32
    80200346:	0ef47b63          	bgeu	s0,a5,8020043c <vprintfmt+0x310>
                    putch('?', putdat);
    8020034a:	03f00513          	li	a0,63
    8020034e:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    80200350:	000a4783          	lbu	a5,0(s4)
    80200354:	3dfd                	addiw	s11,s11,-1
    80200356:	0a05                	addi	s4,s4,1
    80200358:	0007851b          	sext.w	a0,a5
    8020035c:	ffe1                	bnez	a5,80200334 <vprintfmt+0x208>
            for (; width > 0; width --) {
    8020035e:	01b05963          	blez	s11,80200370 <vprintfmt+0x244>
    80200362:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
    80200364:	85a6                	mv	a1,s1
    80200366:	02000513          	li	a0,32
    8020036a:	9902                	jalr	s2
            for (; width > 0; width --) {
    8020036c:	fe0d9be3          	bnez	s11,80200362 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
    80200370:	6a02                	ld	s4,0(sp)
    80200372:	bbd5                	j	80200166 <vprintfmt+0x3a>
    if (lflag >= 2) {
    80200374:	4705                	li	a4,1
            precision = va_arg(ap, int);
    80200376:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
    8020037a:	01174463          	blt	a4,a7,80200382 <vprintfmt+0x256>
    else if (lflag) {
    8020037e:	08088d63          	beqz	a7,80200418 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
    80200382:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
    80200386:	0a044d63          	bltz	s0,80200440 <vprintfmt+0x314>
            num = getint(&ap, lflag);
    8020038a:	8622                	mv	a2,s0
    8020038c:	8a66                	mv	s4,s9
    8020038e:	46a9                	li	a3,10
    80200390:	bdcd                	j	80200282 <vprintfmt+0x156>
            err = va_arg(ap, int);
    80200392:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
    80200396:	4719                	li	a4,6
            err = va_arg(ap, int);
    80200398:	0a21                	addi	s4,s4,8
            if (err < 0) {
    8020039a:	41f7d69b          	sraiw	a3,a5,0x1f
    8020039e:	8fb5                	xor	a5,a5,a3
    802003a0:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
    802003a4:	02d74163          	blt	a4,a3,802003c6 <vprintfmt+0x29a>
    802003a8:	00369793          	slli	a5,a3,0x3
    802003ac:	97de                	add	a5,a5,s7
    802003ae:	639c                	ld	a5,0(a5)
    802003b0:	cb99                	beqz	a5,802003c6 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
    802003b2:	86be                	mv	a3,a5
    802003b4:	00000617          	auipc	a2,0x0
    802003b8:	16c60613          	addi	a2,a2,364 # 80200520 <sbi_console_putchar+0x72>
    802003bc:	85a6                	mv	a1,s1
    802003be:	854a                	mv	a0,s2
    802003c0:	0ce000ef          	jal	ra,8020048e <printfmt>
    802003c4:	b34d                	j	80200166 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
    802003c6:	00000617          	auipc	a2,0x0
    802003ca:	14a60613          	addi	a2,a2,330 # 80200510 <sbi_console_putchar+0x62>
    802003ce:	85a6                	mv	a1,s1
    802003d0:	854a                	mv	a0,s2
    802003d2:	0bc000ef          	jal	ra,8020048e <printfmt>
    802003d6:	bb41                	j	80200166 <vprintfmt+0x3a>
                p = "(null)";
    802003d8:	00000417          	auipc	s0,0x0
    802003dc:	13040413          	addi	s0,s0,304 # 80200508 <sbi_console_putchar+0x5a>
                for (width -= strnlen(p, precision); width > 0; width --) {
    802003e0:	85e2                	mv	a1,s8
    802003e2:	8522                	mv	a0,s0
    802003e4:	e43e                	sd	a5,8(sp)
    802003e6:	cadff0ef          	jal	ra,80200092 <strnlen>
    802003ea:	40ad8dbb          	subw	s11,s11,a0
    802003ee:	01b05b63          	blez	s11,80200404 <vprintfmt+0x2d8>
                    putch(padc, putdat);
    802003f2:	67a2                	ld	a5,8(sp)
    802003f4:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
    802003f8:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
    802003fa:	85a6                	mv	a1,s1
    802003fc:	8552                	mv	a0,s4
    802003fe:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
    80200400:	fe0d9ce3          	bnez	s11,802003f8 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    80200404:	00044783          	lbu	a5,0(s0)
    80200408:	00140a13          	addi	s4,s0,1
    8020040c:	0007851b          	sext.w	a0,a5
    80200410:	d3a5                	beqz	a5,80200370 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
    80200412:	05e00413          	li	s0,94
    80200416:	bf39                	j	80200334 <vprintfmt+0x208>
        return va_arg(*ap, int);
    80200418:	000a2403          	lw	s0,0(s4)
    8020041c:	b7ad                	j	80200386 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
    8020041e:	000a6603          	lwu	a2,0(s4)
    80200422:	46a1                	li	a3,8
    80200424:	8a2e                	mv	s4,a1
    80200426:	bdb1                	j	80200282 <vprintfmt+0x156>
    80200428:	000a6603          	lwu	a2,0(s4)
    8020042c:	46a9                	li	a3,10
    8020042e:	8a2e                	mv	s4,a1
    80200430:	bd89                	j	80200282 <vprintfmt+0x156>
    80200432:	000a6603          	lwu	a2,0(s4)
    80200436:	46c1                	li	a3,16
    80200438:	8a2e                	mv	s4,a1
    8020043a:	b5a1                	j	80200282 <vprintfmt+0x156>
                    putch(ch, putdat);
    8020043c:	9902                	jalr	s2
    8020043e:	bf09                	j	80200350 <vprintfmt+0x224>
                putch('-', putdat);
    80200440:	85a6                	mv	a1,s1
    80200442:	02d00513          	li	a0,45
    80200446:	e03e                	sd	a5,0(sp)
    80200448:	9902                	jalr	s2
                num = -(long long)num;
    8020044a:	6782                	ld	a5,0(sp)
    8020044c:	8a66                	mv	s4,s9
    8020044e:	40800633          	neg	a2,s0
    80200452:	46a9                	li	a3,10
    80200454:	b53d                	j	80200282 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
    80200456:	03b05163          	blez	s11,80200478 <vprintfmt+0x34c>
    8020045a:	02d00693          	li	a3,45
    8020045e:	f6d79de3          	bne	a5,a3,802003d8 <vprintfmt+0x2ac>
                p = "(null)";
    80200462:	00000417          	auipc	s0,0x0
    80200466:	0a640413          	addi	s0,s0,166 # 80200508 <sbi_console_putchar+0x5a>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    8020046a:	02800793          	li	a5,40
    8020046e:	02800513          	li	a0,40
    80200472:	00140a13          	addi	s4,s0,1
    80200476:	bd6d                	j	80200330 <vprintfmt+0x204>
    80200478:	00000a17          	auipc	s4,0x0
    8020047c:	091a0a13          	addi	s4,s4,145 # 80200509 <sbi_console_putchar+0x5b>
    80200480:	02800513          	li	a0,40
    80200484:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
    80200488:	05e00413          	li	s0,94
    8020048c:	b565                	j	80200334 <vprintfmt+0x208>

000000008020048e <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
    8020048e:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
    80200490:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
    80200494:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
    80200496:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
    80200498:	ec06                	sd	ra,24(sp)
    8020049a:	f83a                	sd	a4,48(sp)
    8020049c:	fc3e                	sd	a5,56(sp)
    8020049e:	e0c2                	sd	a6,64(sp)
    802004a0:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
    802004a2:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
    802004a4:	c89ff0ef          	jal	ra,8020012c <vprintfmt>
}
    802004a8:	60e2                	ld	ra,24(sp)
    802004aa:	6161                	addi	sp,sp,80
    802004ac:	8082                	ret

00000000802004ae <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
    802004ae:	4781                	li	a5,0
    802004b0:	00003717          	auipc	a4,0x3
    802004b4:	b5073703          	ld	a4,-1200(a4) # 80203000 <SBI_CONSOLE_PUTCHAR>
    802004b8:	88ba                	mv	a7,a4
    802004ba:	852a                	mv	a0,a0
    802004bc:	85be                	mv	a1,a5
    802004be:	863e                	mv	a2,a5
    802004c0:	00000073          	ecall
    802004c4:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
    802004c6:	8082                	ret
