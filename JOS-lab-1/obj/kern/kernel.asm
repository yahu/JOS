
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# physical addresses [0, 4MB).  This 4MB region will be suffice
	# until we set up our real page table in i386_vm_init in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 03 01 00 00       	call   f0100141 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
		monitor(NULL);
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
f0100047:	8d 5d 14             	lea    0x14(%ebp),%ebx
{
	va_list ap;

	va_start(ap, fmt);
	cprintf("kernel warning at %s:%d: ", file, line);
f010004a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010004d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100051:	8b 45 08             	mov    0x8(%ebp),%eax
f0100054:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100058:	c7 04 24 20 1a 10 f0 	movl   $0xf0101a20,(%esp)
f010005f:	e8 c7 08 00 00       	call   f010092b <cprintf>
	vcprintf(fmt, ap);
f0100064:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100068:	8b 45 10             	mov    0x10(%ebp),%eax
f010006b:	89 04 24             	mov    %eax,(%esp)
f010006e:	e8 85 08 00 00       	call   f01008f8 <vcprintf>
	cprintf("\n");
f0100073:	c7 04 24 cb 1a 10 f0 	movl   $0xf0101acb,(%esp)
f010007a:	e8 ac 08 00 00       	call   f010092b <cprintf>
	va_end(ap);
}
f010007f:	83 c4 14             	add    $0x14,%esp
f0100082:	5b                   	pop    %ebx
f0100083:	5d                   	pop    %ebp
f0100084:	c3                   	ret    

f0100085 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100085:	55                   	push   %ebp
f0100086:	89 e5                	mov    %esp,%ebp
f0100088:	56                   	push   %esi
f0100089:	53                   	push   %ebx
f010008a:	83 ec 10             	sub    $0x10,%esp
f010008d:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100090:	83 3d 00 23 11 f0 00 	cmpl   $0x0,0xf0112300
f0100097:	75 3d                	jne    f01000d6 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f0100099:	89 35 00 23 11 f0    	mov    %esi,0xf0112300

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f010009f:	fa                   	cli    
f01000a0:	fc                   	cld    
/*
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
f01000a1:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");

	va_start(ap, fmt);
	cprintf("kernel panic at %s:%d: ", file, line);
f01000a4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000a7:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000ab:	8b 45 08             	mov    0x8(%ebp),%eax
f01000ae:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000b2:	c7 04 24 3a 1a 10 f0 	movl   $0xf0101a3a,(%esp)
f01000b9:	e8 6d 08 00 00       	call   f010092b <cprintf>
	vcprintf(fmt, ap);
f01000be:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000c2:	89 34 24             	mov    %esi,(%esp)
f01000c5:	e8 2e 08 00 00       	call   f01008f8 <vcprintf>
	cprintf("\n");
f01000ca:	c7 04 24 cb 1a 10 f0 	movl   $0xf0101acb,(%esp)
f01000d1:	e8 55 08 00 00       	call   f010092b <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000dd:	e8 ca 06 00 00       	call   f01007ac <monitor>
f01000e2:	eb f2                	jmp    f01000d6 <_panic+0x51>

f01000e4 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f01000e4:	55                   	push   %ebp
f01000e5:	89 e5                	mov    %esp,%ebp
f01000e7:	53                   	push   %ebx
f01000e8:	83 ec 14             	sub    $0x14,%esp
f01000eb:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f01000ee:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000f2:	c7 04 24 52 1a 10 f0 	movl   $0xf0101a52,(%esp)
f01000f9:	e8 2d 08 00 00       	call   f010092b <cprintf>
	if (x > 0)
f01000fe:	85 db                	test   %ebx,%ebx
f0100100:	7e 0d                	jle    f010010f <test_backtrace+0x2b>
		test_backtrace(x-1);
f0100102:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100105:	89 04 24             	mov    %eax,(%esp)
f0100108:	e8 d7 ff ff ff       	call   f01000e4 <test_backtrace>
f010010d:	eb 1c                	jmp    f010012b <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010010f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100116:	00 
f0100117:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010011e:	00 
f010011f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100126:	e8 75 05 00 00       	call   f01006a0 <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f010012b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010012f:	c7 04 24 6e 1a 10 f0 	movl   $0xf0101a6e,(%esp)
f0100136:	e8 f0 07 00 00       	call   f010092b <cprintf>
}
f010013b:	83 c4 14             	add    $0x14,%esp
f010013e:	5b                   	pop    %ebx
f010013f:	5d                   	pop    %ebp
f0100140:	c3                   	ret    

f0100141 <i386_init>:

void
i386_init(void)
{
f0100141:	55                   	push   %ebp
f0100142:	89 e5                	mov    %esp,%ebp
f0100144:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100147:	b8 60 29 11 f0       	mov    $0xf0112960,%eax
f010014c:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f0100151:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100155:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010015c:	00 
f010015d:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f0100164:	e8 cd 13 00 00       	call   f0101536 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100169:	e8 3c 03 00 00       	call   f01004aa <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010016e:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100175:	00 
f0100176:	c7 04 24 89 1a 10 f0 	movl   $0xf0101a89,(%esp)
f010017d:	e8 a9 07 00 00       	call   f010092b <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f0100182:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f0100189:	e8 56 ff ff ff       	call   f01000e4 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010018e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100195:	e8 12 06 00 00       	call   f01007ac <monitor>
f010019a:	eb f2                	jmp    f010018e <i386_init+0x4d>
f010019c:	00 00                	add    %al,(%eax)
	...

f01001a0 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba 84 00 00 00       	mov    $0x84,%edx
f01001a8:	ec                   	in     (%dx),%al
f01001a9:	ec                   	in     (%dx),%al
f01001aa:	ec                   	in     (%dx),%al
f01001ab:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f01001ac:	5d                   	pop    %ebp
f01001ad:	c3                   	ret    

f01001ae <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001ae:	55                   	push   %ebp
f01001af:	89 e5                	mov    %esp,%ebp
f01001b1:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001b6:	ec                   	in     (%dx),%al
f01001b7:	89 c2                	mov    %eax,%edx
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001b9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01001be:	f6 c2 01             	test   $0x1,%dl
f01001c1:	74 09                	je     f01001cc <serial_proc_data+0x1e>
f01001c3:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01001c8:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001c9:	0f b6 c0             	movzbl %al,%eax
}
f01001cc:	5d                   	pop    %ebp
f01001cd:	c3                   	ret    

f01001ce <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001ce:	55                   	push   %ebp
f01001cf:	89 e5                	mov    %esp,%ebp
f01001d1:	57                   	push   %edi
f01001d2:	56                   	push   %esi
f01001d3:	53                   	push   %ebx
f01001d4:	83 ec 0c             	sub    $0xc,%esp
f01001d7:	89 c6                	mov    %eax,%esi
	int c;

	while ((c = (*proc)()) != -1) {
		if (c == 0)
			continue;
		cons.buf[cons.wpos++] = c;
f01001d9:	bb 44 25 11 f0       	mov    $0xf0112544,%ebx
f01001de:	bf 40 23 11 f0       	mov    $0xf0112340,%edi
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001e3:	eb 1b                	jmp    f0100200 <cons_intr+0x32>
		if (c == 0)
f01001e5:	85 c0                	test   %eax,%eax
f01001e7:	74 17                	je     f0100200 <cons_intr+0x32>
			continue;
		cons.buf[cons.wpos++] = c;
f01001e9:	8b 13                	mov    (%ebx),%edx
f01001eb:	88 04 3a             	mov    %al,(%edx,%edi,1)
f01001ee:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f01001f1:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f01001f6:	ba 00 00 00 00       	mov    $0x0,%edx
f01001fb:	0f 44 c2             	cmove  %edx,%eax
f01001fe:	89 03                	mov    %eax,(%ebx)
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100200:	ff d6                	call   *%esi
f0100202:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100205:	75 de                	jne    f01001e5 <cons_intr+0x17>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100207:	83 c4 0c             	add    $0xc,%esp
f010020a:	5b                   	pop    %ebx
f010020b:	5e                   	pop    %esi
f010020c:	5f                   	pop    %edi
f010020d:	5d                   	pop    %ebp
f010020e:	c3                   	ret    

f010020f <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010020f:	55                   	push   %ebp
f0100210:	89 e5                	mov    %esp,%ebp
f0100212:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100215:	b8 9a 05 10 f0       	mov    $0xf010059a,%eax
f010021a:	e8 af ff ff ff       	call   f01001ce <cons_intr>
}
f010021f:	c9                   	leave  
f0100220:	c3                   	ret    

f0100221 <serial_intr>:
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100221:	55                   	push   %ebp
f0100222:	89 e5                	mov    %esp,%ebp
f0100224:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f0100227:	83 3d 24 23 11 f0 00 	cmpl   $0x0,0xf0112324
f010022e:	74 0a                	je     f010023a <serial_intr+0x19>
		cons_intr(serial_proc_data);
f0100230:	b8 ae 01 10 f0       	mov    $0xf01001ae,%eax
f0100235:	e8 94 ff ff ff       	call   f01001ce <cons_intr>
}
f010023a:	c9                   	leave  
f010023b:	c3                   	ret    

f010023c <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f010023c:	55                   	push   %ebp
f010023d:	89 e5                	mov    %esp,%ebp
f010023f:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100242:	e8 da ff ff ff       	call   f0100221 <serial_intr>
	kbd_intr();
f0100247:	e8 c3 ff ff ff       	call   f010020f <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f010024c:	8b 15 40 25 11 f0    	mov    0xf0112540,%edx
f0100252:	b8 00 00 00 00       	mov    $0x0,%eax
f0100257:	3b 15 44 25 11 f0    	cmp    0xf0112544,%edx
f010025d:	74 1e                	je     f010027d <cons_getc+0x41>
		c = cons.buf[cons.rpos++];
f010025f:	0f b6 82 40 23 11 f0 	movzbl -0xfeedcc0(%edx),%eax
f0100266:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
f0100269:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.rpos = 0;
f010026f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100274:	0f 44 d1             	cmove  %ecx,%edx
f0100277:	89 15 40 25 11 f0    	mov    %edx,0xf0112540
		return c;
	}
	return 0;
}
f010027d:	c9                   	leave  
f010027e:	c3                   	ret    

f010027f <getchar>:
	cons_putc(c);
}

int
getchar(void)
{
f010027f:	55                   	push   %ebp
f0100280:	89 e5                	mov    %esp,%ebp
f0100282:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100285:	e8 b2 ff ff ff       	call   f010023c <cons_getc>
f010028a:	85 c0                	test   %eax,%eax
f010028c:	74 f7                	je     f0100285 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010028e:	c9                   	leave  
f010028f:	c3                   	ret    

f0100290 <iscons>:

int
iscons(int fdnum)
{
f0100290:	55                   	push   %ebp
f0100291:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100293:	b8 01 00 00 00       	mov    $0x1,%eax
f0100298:	5d                   	pop    %ebp
f0100299:	c3                   	ret    

f010029a <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010029a:	55                   	push   %ebp
f010029b:	89 e5                	mov    %esp,%ebp
f010029d:	57                   	push   %edi
f010029e:	56                   	push   %esi
f010029f:	53                   	push   %ebx
f01002a0:	83 ec 2c             	sub    $0x2c,%esp
f01002a3:	89 c7                	mov    %eax,%edi
f01002a5:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01002aa:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01002ab:	a8 20                	test   $0x20,%al
f01002ad:	75 21                	jne    f01002d0 <cons_putc+0x36>
f01002af:	bb 00 00 00 00       	mov    $0x0,%ebx
f01002b4:	be fd 03 00 00       	mov    $0x3fd,%esi
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f01002b9:	e8 e2 fe ff ff       	call   f01001a0 <delay>
f01002be:	89 f2                	mov    %esi,%edx
f01002c0:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01002c1:	a8 20                	test   $0x20,%al
f01002c3:	75 0b                	jne    f01002d0 <cons_putc+0x36>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002c5:	83 c3 01             	add    $0x1,%ebx
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01002c8:	81 fb 00 32 00 00    	cmp    $0x3200,%ebx
f01002ce:	75 e9                	jne    f01002b9 <cons_putc+0x1f>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
f01002d0:	89 fa                	mov    %edi,%edx
f01002d2:	89 f8                	mov    %edi,%eax
f01002d4:	88 55 e7             	mov    %dl,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002d7:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002dc:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002dd:	b2 79                	mov    $0x79,%dl
f01002df:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002e0:	84 c0                	test   %al,%al
f01002e2:	78 21                	js     f0100305 <cons_putc+0x6b>
f01002e4:	bb 00 00 00 00       	mov    $0x0,%ebx
f01002e9:	be 79 03 00 00       	mov    $0x379,%esi
		delay();
f01002ee:	e8 ad fe ff ff       	call   f01001a0 <delay>
f01002f3:	89 f2                	mov    %esi,%edx
f01002f5:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002f6:	84 c0                	test   %al,%al
f01002f8:	78 0b                	js     f0100305 <cons_putc+0x6b>
f01002fa:	83 c3 01             	add    $0x1,%ebx
f01002fd:	81 fb 00 32 00 00    	cmp    $0x3200,%ebx
f0100303:	75 e9                	jne    f01002ee <cons_putc+0x54>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100305:	ba 78 03 00 00       	mov    $0x378,%edx
f010030a:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010030e:	ee                   	out    %al,(%dx)
f010030f:	b2 7a                	mov    $0x7a,%dl
f0100311:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100316:	ee                   	out    %al,(%dx)
f0100317:	b8 08 00 00 00       	mov    $0x8,%eax
f010031c:	ee                   	out    %al,(%dx)
static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
		c |= 0x0700;
f010031d:	89 f8                	mov    %edi,%eax
f010031f:	80 cc 07             	or     $0x7,%ah
f0100322:	f7 c7 00 ff ff ff    	test   $0xffffff00,%edi
f0100328:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f010032b:	89 f8                	mov    %edi,%eax
f010032d:	25 ff 00 00 00       	and    $0xff,%eax
f0100332:	83 f8 09             	cmp    $0x9,%eax
f0100335:	0f 84 89 00 00 00    	je     f01003c4 <cons_putc+0x12a>
f010033b:	83 f8 09             	cmp    $0x9,%eax
f010033e:	7f 12                	jg     f0100352 <cons_putc+0xb8>
f0100340:	83 f8 08             	cmp    $0x8,%eax
f0100343:	0f 85 af 00 00 00    	jne    f01003f8 <cons_putc+0x15e>
f0100349:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0100350:	eb 18                	jmp    f010036a <cons_putc+0xd0>
f0100352:	83 f8 0a             	cmp    $0xa,%eax
f0100355:	8d 76 00             	lea    0x0(%esi),%esi
f0100358:	74 40                	je     f010039a <cons_putc+0x100>
f010035a:	83 f8 0d             	cmp    $0xd,%eax
f010035d:	8d 76 00             	lea    0x0(%esi),%esi
f0100360:	0f 85 92 00 00 00    	jne    f01003f8 <cons_putc+0x15e>
f0100366:	66 90                	xchg   %ax,%ax
f0100368:	eb 38                	jmp    f01003a2 <cons_putc+0x108>
	case '\b':
		if (crt_pos > 0) {
f010036a:	0f b7 05 30 23 11 f0 	movzwl 0xf0112330,%eax
f0100371:	66 85 c0             	test   %ax,%ax
f0100374:	0f 84 e8 00 00 00    	je     f0100462 <cons_putc+0x1c8>
			crt_pos--;
f010037a:	83 e8 01             	sub    $0x1,%eax
f010037d:	66 a3 30 23 11 f0    	mov    %ax,0xf0112330
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100383:	0f b7 c0             	movzwl %ax,%eax
f0100386:	66 81 e7 00 ff       	and    $0xff00,%di
f010038b:	83 cf 20             	or     $0x20,%edi
f010038e:	8b 15 2c 23 11 f0    	mov    0xf011232c,%edx
f0100394:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100398:	eb 7b                	jmp    f0100415 <cons_putc+0x17b>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010039a:	66 83 05 30 23 11 f0 	addw   $0x50,0xf0112330
f01003a1:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003a2:	0f b7 05 30 23 11 f0 	movzwl 0xf0112330,%eax
f01003a9:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003af:	c1 e8 10             	shr    $0x10,%eax
f01003b2:	66 c1 e8 06          	shr    $0x6,%ax
f01003b6:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003b9:	c1 e0 04             	shl    $0x4,%eax
f01003bc:	66 a3 30 23 11 f0    	mov    %ax,0xf0112330
f01003c2:	eb 51                	jmp    f0100415 <cons_putc+0x17b>
		break;
	case '\t':
		cons_putc(' ');
f01003c4:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c9:	e8 cc fe ff ff       	call   f010029a <cons_putc>
		cons_putc(' ');
f01003ce:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d3:	e8 c2 fe ff ff       	call   f010029a <cons_putc>
		cons_putc(' ');
f01003d8:	b8 20 00 00 00       	mov    $0x20,%eax
f01003dd:	e8 b8 fe ff ff       	call   f010029a <cons_putc>
		cons_putc(' ');
f01003e2:	b8 20 00 00 00       	mov    $0x20,%eax
f01003e7:	e8 ae fe ff ff       	call   f010029a <cons_putc>
		cons_putc(' ');
f01003ec:	b8 20 00 00 00       	mov    $0x20,%eax
f01003f1:	e8 a4 fe ff ff       	call   f010029a <cons_putc>
f01003f6:	eb 1d                	jmp    f0100415 <cons_putc+0x17b>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003f8:	0f b7 05 30 23 11 f0 	movzwl 0xf0112330,%eax
f01003ff:	0f b7 c8             	movzwl %ax,%ecx
f0100402:	8b 15 2c 23 11 f0    	mov    0xf011232c,%edx
f0100408:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f010040c:	83 c0 01             	add    $0x1,%eax
f010040f:	66 a3 30 23 11 f0    	mov    %ax,0xf0112330
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100415:	66 81 3d 30 23 11 f0 	cmpw   $0x7cf,0xf0112330
f010041c:	cf 07 
f010041e:	76 42                	jbe    f0100462 <cons_putc+0x1c8>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100420:	a1 2c 23 11 f0       	mov    0xf011232c,%eax
f0100425:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010042c:	00 
f010042d:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100433:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100437:	89 04 24             	mov    %eax,(%esp)
f010043a:	e8 56 11 00 00       	call   f0101595 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010043f:	8b 15 2c 23 11 f0    	mov    0xf011232c,%edx
f0100445:	b8 80 07 00 00       	mov    $0x780,%eax
f010044a:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100450:	83 c0 01             	add    $0x1,%eax
f0100453:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100458:	75 f0                	jne    f010044a <cons_putc+0x1b0>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010045a:	66 83 2d 30 23 11 f0 	subw   $0x50,0xf0112330
f0100461:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100462:	8b 0d 28 23 11 f0    	mov    0xf0112328,%ecx
f0100468:	89 cb                	mov    %ecx,%ebx
f010046a:	b8 0e 00 00 00       	mov    $0xe,%eax
f010046f:	89 ca                	mov    %ecx,%edx
f0100471:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100472:	0f b7 35 30 23 11 f0 	movzwl 0xf0112330,%esi
f0100479:	83 c1 01             	add    $0x1,%ecx
f010047c:	89 f0                	mov    %esi,%eax
f010047e:	66 c1 e8 08          	shr    $0x8,%ax
f0100482:	89 ca                	mov    %ecx,%edx
f0100484:	ee                   	out    %al,(%dx)
f0100485:	b8 0f 00 00 00       	mov    $0xf,%eax
f010048a:	89 da                	mov    %ebx,%edx
f010048c:	ee                   	out    %al,(%dx)
f010048d:	89 f0                	mov    %esi,%eax
f010048f:	89 ca                	mov    %ecx,%edx
f0100491:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100492:	83 c4 2c             	add    $0x2c,%esp
f0100495:	5b                   	pop    %ebx
f0100496:	5e                   	pop    %esi
f0100497:	5f                   	pop    %edi
f0100498:	5d                   	pop    %ebp
f0100499:	c3                   	ret    

f010049a <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010049a:	55                   	push   %ebp
f010049b:	89 e5                	mov    %esp,%ebp
f010049d:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01004a0:	8b 45 08             	mov    0x8(%ebp),%eax
f01004a3:	e8 f2 fd ff ff       	call   f010029a <cons_putc>
}
f01004a8:	c9                   	leave  
f01004a9:	c3                   	ret    

f01004aa <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004aa:	55                   	push   %ebp
f01004ab:	89 e5                	mov    %esp,%ebp
f01004ad:	57                   	push   %edi
f01004ae:	56                   	push   %esi
f01004af:	53                   	push   %ebx
f01004b0:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f01004b3:	b8 00 80 0b f0       	mov    $0xf00b8000,%eax
f01004b8:	0f b7 10             	movzwl (%eax),%edx
	*cp = (uint16_t) 0xA55A;
f01004bb:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
f01004c0:	0f b7 00             	movzwl (%eax),%eax
f01004c3:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01004c7:	74 11                	je     f01004da <cons_init+0x30>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f01004c9:	c7 05 28 23 11 f0 b4 	movl   $0x3b4,0xf0112328
f01004d0:	03 00 00 
f01004d3:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f01004d8:	eb 16                	jmp    f01004f0 <cons_init+0x46>
	} else {
		*cp = was;
f01004da:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01004e1:	c7 05 28 23 11 f0 d4 	movl   $0x3d4,0xf0112328
f01004e8:	03 00 00 
f01004eb:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f01004f0:	8b 0d 28 23 11 f0    	mov    0xf0112328,%ecx
f01004f6:	89 cb                	mov    %ecx,%ebx
f01004f8:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004fd:	89 ca                	mov    %ecx,%edx
f01004ff:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100500:	83 c1 01             	add    $0x1,%ecx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100503:	89 ca                	mov    %ecx,%edx
f0100505:	ec                   	in     (%dx),%al
f0100506:	0f b6 f8             	movzbl %al,%edi
f0100509:	c1 e7 08             	shl    $0x8,%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010050c:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100511:	89 da                	mov    %ebx,%edx
f0100513:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100514:	89 ca                	mov    %ecx,%edx
f0100516:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100517:	89 35 2c 23 11 f0    	mov    %esi,0xf011232c
	crt_pos = pos;
f010051d:	0f b6 c8             	movzbl %al,%ecx
f0100520:	09 cf                	or     %ecx,%edi
f0100522:	66 89 3d 30 23 11 f0 	mov    %di,0xf0112330
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100529:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f010052e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100533:	89 da                	mov    %ebx,%edx
f0100535:	ee                   	out    %al,(%dx)
f0100536:	b2 fb                	mov    $0xfb,%dl
f0100538:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f010053d:	ee                   	out    %al,(%dx)
f010053e:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f0100543:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100548:	89 ca                	mov    %ecx,%edx
f010054a:	ee                   	out    %al,(%dx)
f010054b:	b2 f9                	mov    $0xf9,%dl
f010054d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100552:	ee                   	out    %al,(%dx)
f0100553:	b2 fb                	mov    $0xfb,%dl
f0100555:	b8 03 00 00 00       	mov    $0x3,%eax
f010055a:	ee                   	out    %al,(%dx)
f010055b:	b2 fc                	mov    $0xfc,%dl
f010055d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100562:	ee                   	out    %al,(%dx)
f0100563:	b2 f9                	mov    $0xf9,%dl
f0100565:	b8 01 00 00 00       	mov    $0x1,%eax
f010056a:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010056b:	b2 fd                	mov    $0xfd,%dl
f010056d:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010056e:	3c ff                	cmp    $0xff,%al
f0100570:	0f 95 c0             	setne  %al
f0100573:	0f b6 f0             	movzbl %al,%esi
f0100576:	89 35 24 23 11 f0    	mov    %esi,0xf0112324
f010057c:	89 da                	mov    %ebx,%edx
f010057e:	ec                   	in     (%dx),%al
f010057f:	89 ca                	mov    %ecx,%edx
f0100581:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100582:	85 f6                	test   %esi,%esi
f0100584:	75 0c                	jne    f0100592 <cons_init+0xe8>
		cprintf("Serial port does not exist!\n");
f0100586:	c7 04 24 a4 1a 10 f0 	movl   $0xf0101aa4,(%esp)
f010058d:	e8 99 03 00 00       	call   f010092b <cprintf>
}
f0100592:	83 c4 1c             	add    $0x1c,%esp
f0100595:	5b                   	pop    %ebx
f0100596:	5e                   	pop    %esi
f0100597:	5f                   	pop    %edi
f0100598:	5d                   	pop    %ebp
f0100599:	c3                   	ret    

f010059a <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f010059a:	55                   	push   %ebp
f010059b:	89 e5                	mov    %esp,%ebp
f010059d:	53                   	push   %ebx
f010059e:	83 ec 14             	sub    $0x14,%esp
f01005a1:	ba 64 00 00 00       	mov    $0x64,%edx
f01005a6:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01005a7:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f01005ac:	a8 01                	test   $0x1,%al
f01005ae:	0f 84 dd 00 00 00    	je     f0100691 <kbd_proc_data+0xf7>
f01005b4:	b2 60                	mov    $0x60,%dl
f01005b6:	ec                   	in     (%dx),%al
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01005b7:	3c e0                	cmp    $0xe0,%al
f01005b9:	75 11                	jne    f01005cc <kbd_proc_data+0x32>
		// E0 escape character
		shift |= E0ESC;
f01005bb:	83 0d 20 23 11 f0 40 	orl    $0x40,0xf0112320
f01005c2:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
f01005c7:	e9 c5 00 00 00       	jmp    f0100691 <kbd_proc_data+0xf7>
	} else if (data & 0x80) {
f01005cc:	84 c0                	test   %al,%al
f01005ce:	79 35                	jns    f0100605 <kbd_proc_data+0x6b>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01005d0:	8b 15 20 23 11 f0    	mov    0xf0112320,%edx
f01005d6:	89 c1                	mov    %eax,%ecx
f01005d8:	83 e1 7f             	and    $0x7f,%ecx
f01005db:	f6 c2 40             	test   $0x40,%dl
f01005de:	0f 44 c1             	cmove  %ecx,%eax
		shift &= ~(shiftcode[data] | E0ESC);
f01005e1:	0f b6 c0             	movzbl %al,%eax
f01005e4:	0f b6 80 e0 1a 10 f0 	movzbl -0xfefe520(%eax),%eax
f01005eb:	83 c8 40             	or     $0x40,%eax
f01005ee:	0f b6 c0             	movzbl %al,%eax
f01005f1:	f7 d0                	not    %eax
f01005f3:	21 c2                	and    %eax,%edx
f01005f5:	89 15 20 23 11 f0    	mov    %edx,0xf0112320
f01005fb:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
f0100600:	e9 8c 00 00 00       	jmp    f0100691 <kbd_proc_data+0xf7>
	} else if (shift & E0ESC) {
f0100605:	8b 15 20 23 11 f0    	mov    0xf0112320,%edx
f010060b:	f6 c2 40             	test   $0x40,%dl
f010060e:	74 0c                	je     f010061c <kbd_proc_data+0x82>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100610:	83 c8 80             	or     $0xffffff80,%eax
		shift &= ~E0ESC;
f0100613:	83 e2 bf             	and    $0xffffffbf,%edx
f0100616:	89 15 20 23 11 f0    	mov    %edx,0xf0112320
	}

	shift |= shiftcode[data];
f010061c:	0f b6 c0             	movzbl %al,%eax
	shift ^= togglecode[data];
f010061f:	0f b6 90 e0 1a 10 f0 	movzbl -0xfefe520(%eax),%edx
f0100626:	0b 15 20 23 11 f0    	or     0xf0112320,%edx
f010062c:	0f b6 88 e0 1b 10 f0 	movzbl -0xfefe420(%eax),%ecx
f0100633:	31 ca                	xor    %ecx,%edx
f0100635:	89 15 20 23 11 f0    	mov    %edx,0xf0112320

	c = charcode[shift & (CTL | SHIFT)][data];
f010063b:	89 d1                	mov    %edx,%ecx
f010063d:	83 e1 03             	and    $0x3,%ecx
f0100640:	8b 0c 8d e0 1c 10 f0 	mov    -0xfefe320(,%ecx,4),%ecx
f0100647:	0f b6 1c 01          	movzbl (%ecx,%eax,1),%ebx
	if (shift & CAPSLOCK) {
f010064b:	f6 c2 08             	test   $0x8,%dl
f010064e:	74 1b                	je     f010066b <kbd_proc_data+0xd1>
		if ('a' <= c && c <= 'z')
f0100650:	89 d9                	mov    %ebx,%ecx
f0100652:	8d 43 9f             	lea    -0x61(%ebx),%eax
f0100655:	83 f8 19             	cmp    $0x19,%eax
f0100658:	77 05                	ja     f010065f <kbd_proc_data+0xc5>
			c += 'A' - 'a';
f010065a:	83 eb 20             	sub    $0x20,%ebx
f010065d:	eb 0c                	jmp    f010066b <kbd_proc_data+0xd1>
		else if ('A' <= c && c <= 'Z')
f010065f:	83 e9 41             	sub    $0x41,%ecx
			c += 'a' - 'A';
f0100662:	8d 43 20             	lea    0x20(%ebx),%eax
f0100665:	83 f9 19             	cmp    $0x19,%ecx
f0100668:	0f 46 d8             	cmovbe %eax,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010066b:	f7 d2                	not    %edx
f010066d:	f6 c2 06             	test   $0x6,%dl
f0100670:	75 1f                	jne    f0100691 <kbd_proc_data+0xf7>
f0100672:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100678:	75 17                	jne    f0100691 <kbd_proc_data+0xf7>
		cprintf("Rebooting!\n");
f010067a:	c7 04 24 c1 1a 10 f0 	movl   $0xf0101ac1,(%esp)
f0100681:	e8 a5 02 00 00       	call   f010092b <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100686:	ba 92 00 00 00       	mov    $0x92,%edx
f010068b:	b8 03 00 00 00       	mov    $0x3,%eax
f0100690:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100691:	89 d8                	mov    %ebx,%eax
f0100693:	83 c4 14             	add    $0x14,%esp
f0100696:	5b                   	pop    %ebx
f0100697:	5d                   	pop    %ebp
f0100698:	c3                   	ret    
f0100699:	00 00                	add    %al,(%eax)
f010069b:	00 00                	add    %al,(%eax)
f010069d:	00 00                	add    %al,(%eax)
	...

f01006a0 <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01006a0:	55                   	push   %ebp
f01006a1:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f01006a3:	b8 00 00 00 00       	mov    $0x0,%eax
f01006a8:	5d                   	pop    %ebp
f01006a9:	c3                   	ret    

f01006aa <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f01006aa:	55                   	push   %ebp
f01006ab:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f01006ad:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f01006b0:	5d                   	pop    %ebp
f01006b1:	c3                   	ret    

f01006b2 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006b2:	55                   	push   %ebp
f01006b3:	89 e5                	mov    %esp,%ebp
f01006b5:	83 ec 18             	sub    $0x18,%esp
	extern char entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006b8:	c7 04 24 f0 1c 10 f0 	movl   $0xf0101cf0,(%esp)
f01006bf:	e8 67 02 00 00       	call   f010092b <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006c4:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006cb:	00 
f01006cc:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006d3:	f0 
f01006d4:	c7 04 24 7c 1d 10 f0 	movl   $0xf0101d7c,(%esp)
f01006db:	e8 4b 02 00 00       	call   f010092b <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006e0:	c7 44 24 08 05 1a 10 	movl   $0x101a05,0x8(%esp)
f01006e7:	00 
f01006e8:	c7 44 24 04 05 1a 10 	movl   $0xf0101a05,0x4(%esp)
f01006ef:	f0 
f01006f0:	c7 04 24 a0 1d 10 f0 	movl   $0xf0101da0,(%esp)
f01006f7:	e8 2f 02 00 00       	call   f010092b <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006fc:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f0100703:	00 
f0100704:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f010070b:	f0 
f010070c:	c7 04 24 c4 1d 10 f0 	movl   $0xf0101dc4,(%esp)
f0100713:	e8 13 02 00 00       	call   f010092b <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100718:	c7 44 24 08 60 29 11 	movl   $0x112960,0x8(%esp)
f010071f:	00 
f0100720:	c7 44 24 04 60 29 11 	movl   $0xf0112960,0x4(%esp)
f0100727:	f0 
f0100728:	c7 04 24 e8 1d 10 f0 	movl   $0xf0101de8,(%esp)
f010072f:	e8 f7 01 00 00       	call   f010092b <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100734:	b8 5f 2d 11 f0       	mov    $0xf0112d5f,%eax
f0100739:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f010073e:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100744:	85 c0                	test   %eax,%eax
f0100746:	0f 48 c2             	cmovs  %edx,%eax
f0100749:	c1 f8 0a             	sar    $0xa,%eax
f010074c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100750:	c7 04 24 0c 1e 10 f0 	movl   $0xf0101e0c,(%esp)
f0100757:	e8 cf 01 00 00       	call   f010092b <cprintf>
		(end-entry+1023)/1024);
	return 0;
}
f010075c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100761:	c9                   	leave  
f0100762:	c3                   	ret    

f0100763 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100763:	55                   	push   %ebp
f0100764:	89 e5                	mov    %esp,%ebp
f0100766:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100769:	a1 b0 1e 10 f0       	mov    0xf0101eb0,%eax
f010076e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100772:	a1 ac 1e 10 f0       	mov    0xf0101eac,%eax
f0100777:	89 44 24 04          	mov    %eax,0x4(%esp)
f010077b:	c7 04 24 09 1d 10 f0 	movl   $0xf0101d09,(%esp)
f0100782:	e8 a4 01 00 00       	call   f010092b <cprintf>
f0100787:	a1 bc 1e 10 f0       	mov    0xf0101ebc,%eax
f010078c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100790:	a1 b8 1e 10 f0       	mov    0xf0101eb8,%eax
f0100795:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100799:	c7 04 24 09 1d 10 f0 	movl   $0xf0101d09,(%esp)
f01007a0:	e8 86 01 00 00       	call   f010092b <cprintf>
	return 0;
}
f01007a5:	b8 00 00 00 00       	mov    $0x0,%eax
f01007aa:	c9                   	leave  
f01007ab:	c3                   	ret    

f01007ac <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007ac:	55                   	push   %ebp
f01007ad:	89 e5                	mov    %esp,%ebp
f01007af:	57                   	push   %edi
f01007b0:	56                   	push   %esi
f01007b1:	53                   	push   %ebx
f01007b2:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007b5:	c7 04 24 38 1e 10 f0 	movl   $0xf0101e38,(%esp)
f01007bc:	e8 6a 01 00 00       	call   f010092b <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007c1:	c7 04 24 5c 1e 10 f0 	movl   $0xf0101e5c,(%esp)
f01007c8:	e8 5e 01 00 00       	call   f010092b <cprintf>

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01007cd:	bf ac 1e 10 f0       	mov    $0xf0101eac,%edi
	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");


	while (1) {
		buf = readline("K> ");
f01007d2:	c7 04 24 12 1d 10 f0 	movl   $0xf0101d12,(%esp)
f01007d9:	e8 d2 0a 00 00       	call   f01012b0 <readline>
f01007de:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007e0:	85 c0                	test   %eax,%eax
f01007e2:	74 ee                	je     f01007d2 <monitor+0x26>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007e4:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
f01007eb:	be 00 00 00 00       	mov    $0x0,%esi
f01007f0:	eb 06                	jmp    f01007f8 <monitor+0x4c>
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007f2:	c6 03 00             	movb   $0x0,(%ebx)
f01007f5:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01007f8:	0f b6 03             	movzbl (%ebx),%eax
f01007fb:	84 c0                	test   %al,%al
f01007fd:	74 6c                	je     f010086b <monitor+0xbf>
f01007ff:	0f be c0             	movsbl %al,%eax
f0100802:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100806:	c7 04 24 16 1d 10 f0 	movl   $0xf0101d16,(%esp)
f010080d:	e8 cc 0c 00 00       	call   f01014de <strchr>
f0100812:	85 c0                	test   %eax,%eax
f0100814:	75 dc                	jne    f01007f2 <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f0100816:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100819:	74 50                	je     f010086b <monitor+0xbf>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010081b:	83 fe 0f             	cmp    $0xf,%esi
f010081e:	66 90                	xchg   %ax,%ax
f0100820:	75 16                	jne    f0100838 <monitor+0x8c>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100822:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100829:	00 
f010082a:	c7 04 24 1b 1d 10 f0 	movl   $0xf0101d1b,(%esp)
f0100831:	e8 f5 00 00 00       	call   f010092b <cprintf>
f0100836:	eb 9a                	jmp    f01007d2 <monitor+0x26>
			return 0;
		}
		argv[argc++] = buf;
f0100838:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010083c:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f010083f:	0f b6 03             	movzbl (%ebx),%eax
f0100842:	84 c0                	test   %al,%al
f0100844:	75 0c                	jne    f0100852 <monitor+0xa6>
f0100846:	eb b0                	jmp    f01007f8 <monitor+0x4c>
			buf++;
f0100848:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010084b:	0f b6 03             	movzbl (%ebx),%eax
f010084e:	84 c0                	test   %al,%al
f0100850:	74 a6                	je     f01007f8 <monitor+0x4c>
f0100852:	0f be c0             	movsbl %al,%eax
f0100855:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100859:	c7 04 24 16 1d 10 f0 	movl   $0xf0101d16,(%esp)
f0100860:	e8 79 0c 00 00       	call   f01014de <strchr>
f0100865:	85 c0                	test   %eax,%eax
f0100867:	74 df                	je     f0100848 <monitor+0x9c>
f0100869:	eb 8d                	jmp    f01007f8 <monitor+0x4c>
			buf++;
	}
	argv[argc] = 0;
f010086b:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100872:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100873:	85 f6                	test   %esi,%esi
f0100875:	0f 84 57 ff ff ff    	je     f01007d2 <monitor+0x26>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010087b:	8b 07                	mov    (%edi),%eax
f010087d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100881:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100884:	89 04 24             	mov    %eax,(%esp)
f0100887:	e8 dd 0b 00 00       	call   f0101469 <strcmp>
f010088c:	ba 00 00 00 00       	mov    $0x0,%edx
f0100891:	85 c0                	test   %eax,%eax
f0100893:	74 1d                	je     f01008b2 <monitor+0x106>
f0100895:	a1 b8 1e 10 f0       	mov    0xf0101eb8,%eax
f010089a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010089e:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008a1:	89 04 24             	mov    %eax,(%esp)
f01008a4:	e8 c0 0b 00 00       	call   f0101469 <strcmp>
f01008a9:	85 c0                	test   %eax,%eax
f01008ab:	75 28                	jne    f01008d5 <monitor+0x129>
f01008ad:	ba 01 00 00 00       	mov    $0x1,%edx
			return commands[i].func(argc, argv, tf);
f01008b2:	6b d2 0c             	imul   $0xc,%edx,%edx
f01008b5:	8b 45 08             	mov    0x8(%ebp),%eax
f01008b8:	89 44 24 08          	mov    %eax,0x8(%esp)
f01008bc:	8d 45 a8             	lea    -0x58(%ebp),%eax
f01008bf:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008c3:	89 34 24             	mov    %esi,(%esp)
f01008c6:	ff 92 b4 1e 10 f0    	call   *-0xfefe14c(%edx)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008cc:	85 c0                	test   %eax,%eax
f01008ce:	78 1d                	js     f01008ed <monitor+0x141>
f01008d0:	e9 fd fe ff ff       	jmp    f01007d2 <monitor+0x26>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008d5:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008d8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008dc:	c7 04 24 38 1d 10 f0 	movl   $0xf0101d38,(%esp)
f01008e3:	e8 43 00 00 00       	call   f010092b <cprintf>
f01008e8:	e9 e5 fe ff ff       	jmp    f01007d2 <monitor+0x26>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008ed:	83 c4 5c             	add    $0x5c,%esp
f01008f0:	5b                   	pop    %ebx
f01008f1:	5e                   	pop    %esi
f01008f2:	5f                   	pop    %edi
f01008f3:	5d                   	pop    %ebp
f01008f4:	c3                   	ret    
f01008f5:	00 00                	add    %al,(%eax)
	...

f01008f8 <vcprintf>:
	*cnt++;
}

int
vcprintf(const char *fmt, va_list ap)
{
f01008f8:	55                   	push   %ebp
f01008f9:	89 e5                	mov    %esp,%ebp
f01008fb:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01008fe:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100905:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100908:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010090c:	8b 45 08             	mov    0x8(%ebp),%eax
f010090f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100913:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100916:	89 44 24 04          	mov    %eax,0x4(%esp)
f010091a:	c7 04 24 45 09 10 f0 	movl   $0xf0100945,(%esp)
f0100921:	e8 97 04 00 00       	call   f0100dbd <vprintfmt>
	return cnt;
}
f0100926:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100929:	c9                   	leave  
f010092a:	c3                   	ret    

f010092b <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010092b:	55                   	push   %ebp
f010092c:	89 e5                	mov    %esp,%ebp
f010092e:	83 ec 18             	sub    $0x18,%esp
	vprintfmt((void*)putch, &cnt, fmt, ap);
	return cnt;
}

int
cprintf(const char *fmt, ...)
f0100931:	8d 45 0c             	lea    0xc(%ebp),%eax
{
	va_list ap;
	int cnt;

	va_start(ap, fmt);
	cnt = vcprintf(fmt, ap);
f0100934:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100938:	8b 45 08             	mov    0x8(%ebp),%eax
f010093b:	89 04 24             	mov    %eax,(%esp)
f010093e:	e8 b5 ff ff ff       	call   f01008f8 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100943:	c9                   	leave  
f0100944:	c3                   	ret    

f0100945 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100945:	55                   	push   %ebp
f0100946:	89 e5                	mov    %esp,%ebp
f0100948:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f010094b:	8b 45 08             	mov    0x8(%ebp),%eax
f010094e:	89 04 24             	mov    %eax,(%esp)
f0100951:	e8 44 fb ff ff       	call   f010049a <cputchar>
	*cnt++;
}
f0100956:	c9                   	leave  
f0100957:	c3                   	ret    
	...

f0100960 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100960:	55                   	push   %ebp
f0100961:	89 e5                	mov    %esp,%ebp
f0100963:	57                   	push   %edi
f0100964:	56                   	push   %esi
f0100965:	53                   	push   %ebx
f0100966:	83 ec 14             	sub    $0x14,%esp
f0100969:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010096c:	89 55 e8             	mov    %edx,-0x18(%ebp)
f010096f:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100972:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100975:	8b 1a                	mov    (%edx),%ebx
f0100977:	8b 01                	mov    (%ecx),%eax
f0100979:	89 45 ec             	mov    %eax,-0x14(%ebp)
	
	while (l <= r) {
f010097c:	39 c3                	cmp    %eax,%ebx
f010097e:	0f 8f 9c 00 00 00    	jg     f0100a20 <stab_binsearch+0xc0>
f0100984:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
		int true_m = (l + r) / 2, m = true_m;
f010098b:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010098e:	01 d8                	add    %ebx,%eax
f0100990:	89 c7                	mov    %eax,%edi
f0100992:	c1 ef 1f             	shr    $0x1f,%edi
f0100995:	01 c7                	add    %eax,%edi
f0100997:	d1 ff                	sar    %edi
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100999:	39 df                	cmp    %ebx,%edi
f010099b:	7c 33                	jl     f01009d0 <stab_binsearch+0x70>
f010099d:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f01009a0:	8b 55 f0             	mov    -0x10(%ebp),%edx
f01009a3:	0f b6 44 82 04       	movzbl 0x4(%edx,%eax,4),%eax
f01009a8:	39 f0                	cmp    %esi,%eax
f01009aa:	0f 84 bc 00 00 00    	je     f0100a6c <stab_binsearch+0x10c>
f01009b0:	8d 44 7f fd          	lea    -0x3(%edi,%edi,2),%eax
f01009b4:	8d 54 82 04          	lea    0x4(%edx,%eax,4),%edx
f01009b8:	89 f8                	mov    %edi,%eax
			m--;
f01009ba:	83 e8 01             	sub    $0x1,%eax
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009bd:	39 d8                	cmp    %ebx,%eax
f01009bf:	7c 0f                	jl     f01009d0 <stab_binsearch+0x70>
f01009c1:	0f b6 0a             	movzbl (%edx),%ecx
f01009c4:	83 ea 0c             	sub    $0xc,%edx
f01009c7:	39 f1                	cmp    %esi,%ecx
f01009c9:	75 ef                	jne    f01009ba <stab_binsearch+0x5a>
f01009cb:	e9 9e 00 00 00       	jmp    f0100a6e <stab_binsearch+0x10e>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01009d0:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f01009d3:	eb 3c                	jmp    f0100a11 <stab_binsearch+0xb1>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f01009d5:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f01009d8:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
f01009da:	8d 5f 01             	lea    0x1(%edi),%ebx
f01009dd:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f01009e4:	eb 2b                	jmp    f0100a11 <stab_binsearch+0xb1>
		} else if (stabs[m].n_value > addr) {
f01009e6:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01009e9:	76 14                	jbe    f01009ff <stab_binsearch+0x9f>
			*region_right = m - 1;
f01009eb:	83 e8 01             	sub    $0x1,%eax
f01009ee:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01009f1:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01009f4:	89 02                	mov    %eax,(%edx)
f01009f6:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f01009fd:	eb 12                	jmp    f0100a11 <stab_binsearch+0xb1>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01009ff:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100a02:	89 01                	mov    %eax,(%ecx)
			l = m;
			addr++;
f0100a04:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100a08:	89 c3                	mov    %eax,%ebx
f0100a0a:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0100a11:	39 5d ec             	cmp    %ebx,-0x14(%ebp)
f0100a14:	0f 8d 71 ff ff ff    	jge    f010098b <stab_binsearch+0x2b>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a1a:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100a1e:	75 0f                	jne    f0100a2f <stab_binsearch+0xcf>
		*region_right = *region_left - 1;
f0100a20:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a23:	8b 03                	mov    (%ebx),%eax
f0100a25:	83 e8 01             	sub    $0x1,%eax
f0100a28:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100a2b:	89 02                	mov    %eax,(%edx)
f0100a2d:	eb 57                	jmp    f0100a86 <stab_binsearch+0x126>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a2f:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100a32:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a34:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a37:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a39:	39 c1                	cmp    %eax,%ecx
f0100a3b:	7d 28                	jge    f0100a65 <stab_binsearch+0x105>
		     l > *region_left && stabs[l].n_type != type;
f0100a3d:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a40:	8b 5d f0             	mov    -0x10(%ebp),%ebx
f0100a43:	0f b6 54 93 04       	movzbl 0x4(%ebx,%edx,4),%edx
f0100a48:	39 f2                	cmp    %esi,%edx
f0100a4a:	74 19                	je     f0100a65 <stab_binsearch+0x105>
f0100a4c:	8d 54 40 fd          	lea    -0x3(%eax,%eax,2),%edx
f0100a50:	8d 54 93 04          	lea    0x4(%ebx,%edx,4),%edx
		     l--)
f0100a54:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a57:	39 c1                	cmp    %eax,%ecx
f0100a59:	7d 0a                	jge    f0100a65 <stab_binsearch+0x105>
		     l > *region_left && stabs[l].n_type != type;
f0100a5b:	0f b6 1a             	movzbl (%edx),%ebx
f0100a5e:	83 ea 0c             	sub    $0xc,%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a61:	39 f3                	cmp    %esi,%ebx
f0100a63:	75 ef                	jne    f0100a54 <stab_binsearch+0xf4>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
f0100a65:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100a68:	89 02                	mov    %eax,(%edx)
f0100a6a:	eb 1a                	jmp    f0100a86 <stab_binsearch+0x126>
	}
}
f0100a6c:	89 f8                	mov    %edi,%eax
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a6e:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a71:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f0100a74:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100a78:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100a7b:	0f 82 54 ff ff ff    	jb     f01009d5 <stab_binsearch+0x75>
f0100a81:	e9 60 ff ff ff       	jmp    f01009e6 <stab_binsearch+0x86>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f0100a86:	83 c4 14             	add    $0x14,%esp
f0100a89:	5b                   	pop    %ebx
f0100a8a:	5e                   	pop    %esi
f0100a8b:	5f                   	pop    %edi
f0100a8c:	5d                   	pop    %ebp
f0100a8d:	c3                   	ret    

f0100a8e <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100a8e:	55                   	push   %ebp
f0100a8f:	89 e5                	mov    %esp,%ebp
f0100a91:	83 ec 38             	sub    $0x38,%esp
f0100a94:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100a97:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100a9a:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100a9d:	8b 75 08             	mov    0x8(%ebp),%esi
f0100aa0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100aa3:	c7 03 c4 1e 10 f0    	movl   $0xf0101ec4,(%ebx)
	info->eip_line = 0;
f0100aa9:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100ab0:	c7 43 08 c4 1e 10 f0 	movl   $0xf0101ec4,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100ab7:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100abe:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100ac1:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100ac8:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100ace:	76 12                	jbe    f0100ae2 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100ad0:	b8 cc 75 10 f0       	mov    $0xf01075cc,%eax
f0100ad5:	3d c5 5b 10 f0       	cmp    $0xf0105bc5,%eax
f0100ada:	0f 86 58 01 00 00    	jbe    f0100c38 <debuginfo_eip+0x1aa>
f0100ae0:	eb 1c                	jmp    f0100afe <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100ae2:	c7 44 24 08 ce 1e 10 	movl   $0xf0101ece,0x8(%esp)
f0100ae9:	f0 
f0100aea:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100af1:	00 
f0100af2:	c7 04 24 db 1e 10 f0 	movl   $0xf0101edb,(%esp)
f0100af9:	e8 87 f5 ff ff       	call   f0100085 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100afe:	80 3d cb 75 10 f0 00 	cmpb   $0x0,0xf01075cb
f0100b05:	0f 85 2d 01 00 00    	jne    f0100c38 <debuginfo_eip+0x1aa>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b0b:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b12:	b8 c4 5b 10 f0       	mov    $0xf0105bc4,%eax
f0100b17:	2d fc 20 10 f0       	sub    $0xf01020fc,%eax
f0100b1c:	c1 f8 02             	sar    $0x2,%eax
f0100b1f:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b25:	83 e8 01             	sub    $0x1,%eax
f0100b28:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b2b:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b2e:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b31:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b35:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100b3c:	b8 fc 20 10 f0       	mov    $0xf01020fc,%eax
f0100b41:	e8 1a fe ff ff       	call   f0100960 <stab_binsearch>
	if (lfile == 0)
f0100b46:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b49:	85 c0                	test   %eax,%eax
f0100b4b:	0f 84 e7 00 00 00    	je     f0100c38 <debuginfo_eip+0x1aa>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b51:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100b54:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b57:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b5a:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b5d:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b60:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b64:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100b6b:	b8 fc 20 10 f0       	mov    $0xf01020fc,%eax
f0100b70:	e8 eb fd ff ff       	call   f0100960 <stab_binsearch>

	if (lfun <= rfun) {
f0100b75:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100b78:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f0100b7b:	7f 31                	jg     f0100bae <debuginfo_eip+0x120>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b7d:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100b80:	8b 80 fc 20 10 f0    	mov    -0xfefdf04(%eax),%eax
f0100b86:	ba cc 75 10 f0       	mov    $0xf01075cc,%edx
f0100b8b:	81 ea c5 5b 10 f0    	sub    $0xf0105bc5,%edx
f0100b91:	39 d0                	cmp    %edx,%eax
f0100b93:	73 08                	jae    f0100b9d <debuginfo_eip+0x10f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100b95:	05 c5 5b 10 f0       	add    $0xf0105bc5,%eax
f0100b9a:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100b9d:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0100ba0:	6b c6 0c             	imul   $0xc,%esi,%eax
f0100ba3:	8b 80 04 21 10 f0    	mov    -0xfefdefc(%eax),%eax
f0100ba9:	89 43 10             	mov    %eax,0x10(%ebx)
f0100bac:	eb 06                	jmp    f0100bb4 <debuginfo_eip+0x126>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100bae:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100bb1:	8b 75 e4             	mov    -0x1c(%ebp),%esi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100bb4:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100bbb:	00 
f0100bbc:	8b 43 08             	mov    0x8(%ebx),%eax
f0100bbf:	89 04 24             	mov    %eax,(%esp)
f0100bc2:	e8 44 09 00 00       	call   f010150b <strfind>
f0100bc7:	2b 43 08             	sub    0x8(%ebx),%eax
f0100bca:	89 43 0c             	mov    %eax,0xc(%ebx)
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
f0100bcd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100bd0:	6b c6 0c             	imul   $0xc,%esi,%eax
f0100bd3:	05 fc 20 10 f0       	add    $0xf01020fc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100bd8:	eb 06                	jmp    f0100be0 <debuginfo_eip+0x152>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100bda:	83 ee 01             	sub    $0x1,%esi
f0100bdd:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100be0:	39 fe                	cmp    %edi,%esi
f0100be2:	7c 25                	jl     f0100c09 <debuginfo_eip+0x17b>
f0100be4:	89 c1                	mov    %eax,%ecx
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100be6:	0f b6 50 04          	movzbl 0x4(%eax),%edx
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100bea:	80 fa 84             	cmp    $0x84,%dl
f0100bed:	74 65                	je     f0100c54 <debuginfo_eip+0x1c6>
f0100bef:	80 fa 64             	cmp    $0x64,%dl
f0100bf2:	75 e6                	jne    f0100bda <debuginfo_eip+0x14c>
f0100bf4:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100bf8:	74 e0                	je     f0100bda <debuginfo_eip+0x14c>
f0100bfa:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0100c00:	eb 52                	jmp    f0100c54 <debuginfo_eip+0x1c6>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c02:	05 c5 5b 10 f0       	add    $0xf0105bc5,%eax
f0100c07:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c09:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100c0c:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f0100c0f:	7d 31                	jge    f0100c42 <debuginfo_eip+0x1b4>
		for (lline = lfun + 1;
f0100c11:	83 c0 01             	add    $0x1,%eax
f0100c14:	6b d0 0c             	imul   $0xc,%eax,%edx
f0100c17:	81 c2 00 21 10 f0    	add    $0xf0102100,%edx
f0100c1d:	eb 07                	jmp    f0100c26 <debuginfo_eip+0x198>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100c1f:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100c23:	83 c0 01             	add    $0x1,%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c26:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f0100c29:	7d 17                	jge    f0100c42 <debuginfo_eip+0x1b4>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c2b:	0f b6 0a             	movzbl (%edx),%ecx
f0100c2e:	83 c2 0c             	add    $0xc,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c31:	80 f9 a0             	cmp    $0xa0,%cl
f0100c34:	74 e9                	je     f0100c1f <debuginfo_eip+0x191>
f0100c36:	eb 0a                	jmp    f0100c42 <debuginfo_eip+0x1b4>
f0100c38:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c3d:	8d 76 00             	lea    0x0(%esi),%esi
f0100c40:	eb 05                	jmp    f0100c47 <debuginfo_eip+0x1b9>
f0100c42:	b8 00 00 00 00       	mov    $0x0,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
}
f0100c47:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100c4a:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100c4d:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100c50:	89 ec                	mov    %ebp,%esp
f0100c52:	5d                   	pop    %ebp
f0100c53:	c3                   	ret    
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100c54:	8b 01                	mov    (%ecx),%eax
f0100c56:	ba cc 75 10 f0       	mov    $0xf01075cc,%edx
f0100c5b:	81 ea c5 5b 10 f0    	sub    $0xf0105bc5,%edx
f0100c61:	39 d0                	cmp    %edx,%eax
f0100c63:	72 9d                	jb     f0100c02 <debuginfo_eip+0x174>
f0100c65:	eb a2                	jmp    f0100c09 <debuginfo_eip+0x17b>
	...

f0100c70 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100c70:	55                   	push   %ebp
f0100c71:	89 e5                	mov    %esp,%ebp
f0100c73:	57                   	push   %edi
f0100c74:	56                   	push   %esi
f0100c75:	53                   	push   %ebx
f0100c76:	83 ec 4c             	sub    $0x4c,%esp
f0100c79:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100c7c:	89 d6                	mov    %edx,%esi
f0100c7e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c81:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100c84:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100c87:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100c8a:	8b 45 10             	mov    0x10(%ebp),%eax
f0100c8d:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100c90:	8b 7d 18             	mov    0x18(%ebp),%edi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100c93:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100c96:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100c9b:	39 d1                	cmp    %edx,%ecx
f0100c9d:	72 15                	jb     f0100cb4 <printnum+0x44>
f0100c9f:	77 07                	ja     f0100ca8 <printnum+0x38>
f0100ca1:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100ca4:	39 d0                	cmp    %edx,%eax
f0100ca6:	76 0c                	jbe    f0100cb4 <printnum+0x44>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100ca8:	83 eb 01             	sub    $0x1,%ebx
f0100cab:	85 db                	test   %ebx,%ebx
f0100cad:	8d 76 00             	lea    0x0(%esi),%esi
f0100cb0:	7f 61                	jg     f0100d13 <printnum+0xa3>
f0100cb2:	eb 70                	jmp    f0100d24 <printnum+0xb4>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100cb4:	89 7c 24 10          	mov    %edi,0x10(%esp)
f0100cb8:	83 eb 01             	sub    $0x1,%ebx
f0100cbb:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100cbf:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100cc3:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0100cc7:	8b 5c 24 0c          	mov    0xc(%esp),%ebx
f0100ccb:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0100cce:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
f0100cd1:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100cd4:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100cd8:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100cdf:	00 
f0100ce0:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100ce3:	89 04 24             	mov    %eax,(%esp)
f0100ce6:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100ce9:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100ced:	e8 ae 0a 00 00       	call   f01017a0 <__udivdi3>
f0100cf2:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0100cf5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100cf8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100cfc:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100d00:	89 04 24             	mov    %eax,(%esp)
f0100d03:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100d07:	89 f2                	mov    %esi,%edx
f0100d09:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d0c:	e8 5f ff ff ff       	call   f0100c70 <printnum>
f0100d11:	eb 11                	jmp    f0100d24 <printnum+0xb4>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100d13:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100d17:	89 3c 24             	mov    %edi,(%esp)
f0100d1a:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d1d:	83 eb 01             	sub    $0x1,%ebx
f0100d20:	85 db                	test   %ebx,%ebx
f0100d22:	7f ef                	jg     f0100d13 <printnum+0xa3>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100d24:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100d28:	8b 74 24 04          	mov    0x4(%esp),%esi
f0100d2c:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100d2f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d33:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100d3a:	00 
f0100d3b:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100d3e:	89 14 24             	mov    %edx,(%esp)
f0100d41:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100d44:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100d48:	e8 83 0b 00 00       	call   f01018d0 <__umoddi3>
f0100d4d:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100d51:	0f be 80 e9 1e 10 f0 	movsbl -0xfefe117(%eax),%eax
f0100d58:	89 04 24             	mov    %eax,(%esp)
f0100d5b:	ff 55 e4             	call   *-0x1c(%ebp)
}
f0100d5e:	83 c4 4c             	add    $0x4c,%esp
f0100d61:	5b                   	pop    %ebx
f0100d62:	5e                   	pop    %esi
f0100d63:	5f                   	pop    %edi
f0100d64:	5d                   	pop    %ebp
f0100d65:	c3                   	ret    

f0100d66 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100d66:	55                   	push   %ebp
f0100d67:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100d69:	83 fa 01             	cmp    $0x1,%edx
f0100d6c:	7e 0e                	jle    f0100d7c <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100d6e:	8b 10                	mov    (%eax),%edx
f0100d70:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100d73:	89 08                	mov    %ecx,(%eax)
f0100d75:	8b 02                	mov    (%edx),%eax
f0100d77:	8b 52 04             	mov    0x4(%edx),%edx
f0100d7a:	eb 22                	jmp    f0100d9e <getuint+0x38>
	else if (lflag)
f0100d7c:	85 d2                	test   %edx,%edx
f0100d7e:	74 10                	je     f0100d90 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100d80:	8b 10                	mov    (%eax),%edx
f0100d82:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d85:	89 08                	mov    %ecx,(%eax)
f0100d87:	8b 02                	mov    (%edx),%eax
f0100d89:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d8e:	eb 0e                	jmp    f0100d9e <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100d90:	8b 10                	mov    (%eax),%edx
f0100d92:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d95:	89 08                	mov    %ecx,(%eax)
f0100d97:	8b 02                	mov    (%edx),%eax
f0100d99:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100d9e:	5d                   	pop    %ebp
f0100d9f:	c3                   	ret    

f0100da0 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100da0:	55                   	push   %ebp
f0100da1:	89 e5                	mov    %esp,%ebp
f0100da3:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100da6:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100daa:	8b 10                	mov    (%eax),%edx
f0100dac:	3b 50 04             	cmp    0x4(%eax),%edx
f0100daf:	73 0a                	jae    f0100dbb <sprintputch+0x1b>
		*b->buf++ = ch;
f0100db1:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0100db4:	88 0a                	mov    %cl,(%edx)
f0100db6:	83 c2 01             	add    $0x1,%edx
f0100db9:	89 10                	mov    %edx,(%eax)
}
f0100dbb:	5d                   	pop    %ebp
f0100dbc:	c3                   	ret    

f0100dbd <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100dbd:	55                   	push   %ebp
f0100dbe:	89 e5                	mov    %esp,%ebp
f0100dc0:	57                   	push   %edi
f0100dc1:	56                   	push   %esi
f0100dc2:	53                   	push   %ebx
f0100dc3:	83 ec 5c             	sub    $0x5c,%esp
f0100dc6:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100dc9:	8b 75 0c             	mov    0xc(%ebp),%esi
f0100dcc:	8b 5d 10             	mov    0x10(%ebp),%ebx
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f0100dcf:	c7 45 c8 ff ff ff ff 	movl   $0xffffffff,-0x38(%ebp)
f0100dd6:	eb 11                	jmp    f0100de9 <vprintfmt+0x2c>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100dd8:	85 c0                	test   %eax,%eax
f0100dda:	0f 84 16 04 00 00    	je     f01011f6 <vprintfmt+0x439>
				return;
			putch(ch, putdat);
f0100de0:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100de4:	89 04 24             	mov    %eax,(%esp)
f0100de7:	ff d7                	call   *%edi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100de9:	0f b6 03             	movzbl (%ebx),%eax
f0100dec:	83 c3 01             	add    $0x1,%ebx
f0100def:	83 f8 25             	cmp    $0x25,%eax
f0100df2:	75 e4                	jne    f0100dd8 <vprintfmt+0x1b>
f0100df4:	c6 45 dc 20          	movb   $0x20,-0x24(%ebp)
f0100df8:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
f0100dff:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
f0100e06:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0100e0d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100e12:	eb 06                	jmp    f0100e1a <vprintfmt+0x5d>
f0100e14:	c6 45 dc 2d          	movb   $0x2d,-0x24(%ebp)
f0100e18:	89 c3                	mov    %eax,%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e1a:	0f b6 13             	movzbl (%ebx),%edx
f0100e1d:	0f b6 c2             	movzbl %dl,%eax
f0100e20:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100e23:	8d 43 01             	lea    0x1(%ebx),%eax
f0100e26:	83 ea 23             	sub    $0x23,%edx
f0100e29:	80 fa 55             	cmp    $0x55,%dl
f0100e2c:	0f 87 a7 03 00 00    	ja     f01011d9 <vprintfmt+0x41c>
f0100e32:	0f b6 d2             	movzbl %dl,%edx
f0100e35:	ff 24 95 78 1f 10 f0 	jmp    *-0xfefe088(,%edx,4)
f0100e3c:	c6 45 dc 30          	movb   $0x30,-0x24(%ebp)
f0100e40:	eb d6                	jmp    f0100e18 <vprintfmt+0x5b>
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100e42:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100e45:	83 ea 30             	sub    $0x30,%edx
f0100e48:	89 55 cc             	mov    %edx,-0x34(%ebp)
				ch = *fmt;
f0100e4b:	0f be 10             	movsbl (%eax),%edx
				if (ch < '0' || ch > '9')
f0100e4e:	8d 5a d0             	lea    -0x30(%edx),%ebx
f0100e51:	83 fb 09             	cmp    $0x9,%ebx
f0100e54:	77 54                	ja     f0100eaa <vprintfmt+0xed>
f0100e56:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100e59:	8b 4d cc             	mov    -0x34(%ebp),%ecx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100e5c:	83 c0 01             	add    $0x1,%eax
				precision = precision * 10 + ch - '0';
f0100e5f:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0100e62:	8d 4c 4a d0          	lea    -0x30(%edx,%ecx,2),%ecx
				ch = *fmt;
f0100e66:	0f be 10             	movsbl (%eax),%edx
				if (ch < '0' || ch > '9')
f0100e69:	8d 5a d0             	lea    -0x30(%edx),%ebx
f0100e6c:	83 fb 09             	cmp    $0x9,%ebx
f0100e6f:	76 eb                	jbe    f0100e5c <vprintfmt+0x9f>
f0100e71:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0100e74:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100e77:	eb 31                	jmp    f0100eaa <vprintfmt+0xed>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100e79:	8b 55 14             	mov    0x14(%ebp),%edx
f0100e7c:	8d 5a 04             	lea    0x4(%edx),%ebx
f0100e7f:	89 5d 14             	mov    %ebx,0x14(%ebp)
f0100e82:	8b 12                	mov    (%edx),%edx
f0100e84:	89 55 cc             	mov    %edx,-0x34(%ebp)
			goto process_precision;
f0100e87:	eb 21                	jmp    f0100eaa <vprintfmt+0xed>

		case '.':
			if (width < 0)
f0100e89:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100e8d:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e92:	0f 49 55 e4          	cmovns -0x1c(%ebp),%edx
f0100e96:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100e99:	e9 7a ff ff ff       	jmp    f0100e18 <vprintfmt+0x5b>
f0100e9e:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
			goto reswitch;
f0100ea5:	e9 6e ff ff ff       	jmp    f0100e18 <vprintfmt+0x5b>

		process_precision:
			if (width < 0)
f0100eaa:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100eae:	0f 89 64 ff ff ff    	jns    f0100e18 <vprintfmt+0x5b>
f0100eb4:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0100eb7:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100eba:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0100ebd:	89 55 cc             	mov    %edx,-0x34(%ebp)
f0100ec0:	e9 53 ff ff ff       	jmp    f0100e18 <vprintfmt+0x5b>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100ec5:	83 c1 01             	add    $0x1,%ecx
			goto reswitch;
f0100ec8:	e9 4b ff ff ff       	jmp    f0100e18 <vprintfmt+0x5b>
f0100ecd:	89 45 e0             	mov    %eax,-0x20(%ebp)

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100ed0:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ed3:	8d 50 04             	lea    0x4(%eax),%edx
f0100ed6:	89 55 14             	mov    %edx,0x14(%ebp)
f0100ed9:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100edd:	8b 00                	mov    (%eax),%eax
f0100edf:	89 04 24             	mov    %eax,(%esp)
f0100ee2:	ff d7                	call   *%edi
f0100ee4:	8b 5d e0             	mov    -0x20(%ebp),%ebx
			break;
f0100ee7:	e9 fd fe ff ff       	jmp    f0100de9 <vprintfmt+0x2c>
f0100eec:	89 45 e0             	mov    %eax,-0x20(%ebp)

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100eef:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ef2:	8d 50 04             	lea    0x4(%eax),%edx
f0100ef5:	89 55 14             	mov    %edx,0x14(%ebp)
f0100ef8:	8b 00                	mov    (%eax),%eax
f0100efa:	89 c2                	mov    %eax,%edx
f0100efc:	c1 fa 1f             	sar    $0x1f,%edx
f0100eff:	31 d0                	xor    %edx,%eax
f0100f01:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100f03:	83 f8 06             	cmp    $0x6,%eax
f0100f06:	7f 0b                	jg     f0100f13 <vprintfmt+0x156>
f0100f08:	8b 14 85 d0 20 10 f0 	mov    -0xfefdf30(,%eax,4),%edx
f0100f0f:	85 d2                	test   %edx,%edx
f0100f11:	75 20                	jne    f0100f33 <vprintfmt+0x176>
				printfmt(putch, putdat, "error %d", err);
f0100f13:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f17:	c7 44 24 08 fa 1e 10 	movl   $0xf0101efa,0x8(%esp)
f0100f1e:	f0 
f0100f1f:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100f23:	89 3c 24             	mov    %edi,(%esp)
f0100f26:	e8 53 03 00 00       	call   f010127e <printfmt>
f0100f2b:	8b 5d e0             	mov    -0x20(%ebp),%ebx
		// error message
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100f2e:	e9 b6 fe ff ff       	jmp    f0100de9 <vprintfmt+0x2c>
				printfmt(putch, putdat, "error %d", err);
			else
				printfmt(putch, putdat, "%s", p);
f0100f33:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100f37:	c7 44 24 08 03 1f 10 	movl   $0xf0101f03,0x8(%esp)
f0100f3e:	f0 
f0100f3f:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100f43:	89 3c 24             	mov    %edi,(%esp)
f0100f46:	e8 33 03 00 00       	call   f010127e <printfmt>
f0100f4b:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100f4e:	e9 96 fe ff ff       	jmp    f0100de9 <vprintfmt+0x2c>
f0100f53:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f56:	89 c3                	mov    %eax,%ebx
f0100f58:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0100f5b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100f5e:	89 45 c0             	mov    %eax,-0x40(%ebp)
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100f61:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f64:	8d 50 04             	lea    0x4(%eax),%edx
f0100f67:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f6a:	8b 00                	mov    (%eax),%eax
f0100f6c:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100f6f:	85 c0                	test   %eax,%eax
f0100f71:	b8 06 1f 10 f0       	mov    $0xf0101f06,%eax
f0100f76:	0f 45 45 c4          	cmovne -0x3c(%ebp),%eax
f0100f7a:	89 45 c4             	mov    %eax,-0x3c(%ebp)
				p = "(null)";
			if (width > 0 && padc != '-')
f0100f7d:	83 7d c0 00          	cmpl   $0x0,-0x40(%ebp)
f0100f81:	7e 06                	jle    f0100f89 <vprintfmt+0x1cc>
f0100f83:	80 7d dc 2d          	cmpb   $0x2d,-0x24(%ebp)
f0100f87:	75 13                	jne    f0100f9c <vprintfmt+0x1df>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100f89:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f0100f8c:	0f be 02             	movsbl (%edx),%eax
f0100f8f:	85 c0                	test   %eax,%eax
f0100f91:	0f 85 9b 00 00 00    	jne    f0101032 <vprintfmt+0x275>
f0100f97:	e9 88 00 00 00       	jmp    f0101024 <vprintfmt+0x267>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f9c:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100fa0:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0100fa3:	89 0c 24             	mov    %ecx,(%esp)
f0100fa6:	e8 00 04 00 00       	call   f01013ab <strnlen>
f0100fab:	8b 55 c0             	mov    -0x40(%ebp),%edx
f0100fae:	29 c2                	sub    %eax,%edx
f0100fb0:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100fb3:	85 d2                	test   %edx,%edx
f0100fb5:	7e d2                	jle    f0100f89 <vprintfmt+0x1cc>
					putch(padc, putdat);
f0100fb7:	0f be 4d dc          	movsbl -0x24(%ebp),%ecx
f0100fbb:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100fbe:	89 5d c0             	mov    %ebx,-0x40(%ebp)
f0100fc1:	89 d3                	mov    %edx,%ebx
f0100fc3:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100fc7:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100fca:	89 04 24             	mov    %eax,(%esp)
f0100fcd:	ff d7                	call   *%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100fcf:	83 eb 01             	sub    $0x1,%ebx
f0100fd2:	85 db                	test   %ebx,%ebx
f0100fd4:	7f ed                	jg     f0100fc3 <vprintfmt+0x206>
f0100fd6:	8b 5d c0             	mov    -0x40(%ebp),%ebx
f0100fd9:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0100fe0:	eb a7                	jmp    f0100f89 <vprintfmt+0x1cc>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100fe2:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0100fe6:	74 1a                	je     f0101002 <vprintfmt+0x245>
f0100fe8:	8d 50 e0             	lea    -0x20(%eax),%edx
f0100feb:	83 fa 5e             	cmp    $0x5e,%edx
f0100fee:	76 12                	jbe    f0101002 <vprintfmt+0x245>
					putch('?', putdat);
f0100ff0:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100ff4:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0100ffb:	ff 55 dc             	call   *-0x24(%ebp)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100ffe:	66 90                	xchg   %ax,%ax
f0101000:	eb 0a                	jmp    f010100c <vprintfmt+0x24f>
					putch('?', putdat);
				else
					putch(ch, putdat);
f0101002:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101006:	89 04 24             	mov    %eax,(%esp)
f0101009:	ff 55 dc             	call   *-0x24(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010100c:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f0101010:	0f be 03             	movsbl (%ebx),%eax
f0101013:	85 c0                	test   %eax,%eax
f0101015:	74 05                	je     f010101c <vprintfmt+0x25f>
f0101017:	83 c3 01             	add    $0x1,%ebx
f010101a:	eb 29                	jmp    f0101045 <vprintfmt+0x288>
f010101c:	89 fe                	mov    %edi,%esi
f010101e:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0101021:	8b 5d cc             	mov    -0x34(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101024:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101028:	7f 2e                	jg     f0101058 <vprintfmt+0x29b>
f010102a:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010102d:	e9 b7 fd ff ff       	jmp    f0100de9 <vprintfmt+0x2c>
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101032:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f0101035:	83 c2 01             	add    $0x1,%edx
f0101038:	89 7d dc             	mov    %edi,-0x24(%ebp)
f010103b:	89 f7                	mov    %esi,%edi
f010103d:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0101040:	89 5d cc             	mov    %ebx,-0x34(%ebp)
f0101043:	89 d3                	mov    %edx,%ebx
f0101045:	85 f6                	test   %esi,%esi
f0101047:	78 99                	js     f0100fe2 <vprintfmt+0x225>
f0101049:	83 ee 01             	sub    $0x1,%esi
f010104c:	79 94                	jns    f0100fe2 <vprintfmt+0x225>
f010104e:	89 fe                	mov    %edi,%esi
f0101050:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0101053:	8b 5d cc             	mov    -0x34(%ebp),%ebx
f0101056:	eb cc                	jmp    f0101024 <vprintfmt+0x267>
f0101058:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f010105b:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f010105e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101062:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0101069:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010106b:	83 eb 01             	sub    $0x1,%ebx
f010106e:	85 db                	test   %ebx,%ebx
f0101070:	7f ec                	jg     f010105e <vprintfmt+0x2a1>
f0101072:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0101075:	e9 6f fd ff ff       	jmp    f0100de9 <vprintfmt+0x2c>
f010107a:	89 45 e0             	mov    %eax,-0x20(%ebp)
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010107d:	83 f9 01             	cmp    $0x1,%ecx
f0101080:	7e 16                	jle    f0101098 <vprintfmt+0x2db>
		return va_arg(*ap, long long);
f0101082:	8b 45 14             	mov    0x14(%ebp),%eax
f0101085:	8d 50 08             	lea    0x8(%eax),%edx
f0101088:	89 55 14             	mov    %edx,0x14(%ebp)
f010108b:	8b 10                	mov    (%eax),%edx
f010108d:	8b 48 04             	mov    0x4(%eax),%ecx
f0101090:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0101093:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0101096:	eb 32                	jmp    f01010ca <vprintfmt+0x30d>
	else if (lflag)
f0101098:	85 c9                	test   %ecx,%ecx
f010109a:	74 18                	je     f01010b4 <vprintfmt+0x2f7>
		return va_arg(*ap, long);
f010109c:	8b 45 14             	mov    0x14(%ebp),%eax
f010109f:	8d 50 04             	lea    0x4(%eax),%edx
f01010a2:	89 55 14             	mov    %edx,0x14(%ebp)
f01010a5:	8b 00                	mov    (%eax),%eax
f01010a7:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01010aa:	89 c1                	mov    %eax,%ecx
f01010ac:	c1 f9 1f             	sar    $0x1f,%ecx
f01010af:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f01010b2:	eb 16                	jmp    f01010ca <vprintfmt+0x30d>
	else
		return va_arg(*ap, int);
f01010b4:	8b 45 14             	mov    0x14(%ebp),%eax
f01010b7:	8d 50 04             	lea    0x4(%eax),%edx
f01010ba:	89 55 14             	mov    %edx,0x14(%ebp)
f01010bd:	8b 00                	mov    (%eax),%eax
f01010bf:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01010c2:	89 c2                	mov    %eax,%edx
f01010c4:	c1 fa 1f             	sar    $0x1f,%edx
f01010c7:	89 55 d4             	mov    %edx,-0x2c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01010ca:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01010cd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01010d0:	b8 0a 00 00 00       	mov    $0xa,%eax
			if ((long long) num < 0) {
f01010d5:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f01010d9:	0f 89 b8 00 00 00    	jns    f0101197 <vprintfmt+0x3da>
				putch('-', putdat);
f01010df:	89 74 24 04          	mov    %esi,0x4(%esp)
f01010e3:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01010ea:	ff d7                	call   *%edi
				num = -(long long) num;
f01010ec:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01010ef:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01010f2:	f7 d9                	neg    %ecx
f01010f4:	83 d3 00             	adc    $0x0,%ebx
f01010f7:	f7 db                	neg    %ebx
f01010f9:	b8 0a 00 00 00       	mov    $0xa,%eax
f01010fe:	e9 94 00 00 00       	jmp    f0101197 <vprintfmt+0x3da>
f0101103:	89 45 e0             	mov    %eax,-0x20(%ebp)
			base = 10;
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101106:	89 ca                	mov    %ecx,%edx
f0101108:	8d 45 14             	lea    0x14(%ebp),%eax
f010110b:	e8 56 fc ff ff       	call   f0100d66 <getuint>
f0101110:	89 c1                	mov    %eax,%ecx
f0101112:	89 d3                	mov    %edx,%ebx
f0101114:	b8 0a 00 00 00       	mov    $0xa,%eax
			base = 10;
			goto number;
f0101119:	eb 7c                	jmp    f0101197 <vprintfmt+0x3da>
f010111b:	89 45 e0             	mov    %eax,-0x20(%ebp)

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f010111e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101122:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f0101129:	ff d7                	call   *%edi
			putch('X', putdat);
f010112b:	89 74 24 04          	mov    %esi,0x4(%esp)
f010112f:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f0101136:	ff d7                	call   *%edi
			putch('X', putdat);
f0101138:	89 74 24 04          	mov    %esi,0x4(%esp)
f010113c:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f0101143:	ff d7                	call   *%edi
f0101145:	8b 5d e0             	mov    -0x20(%ebp),%ebx
			break;
f0101148:	e9 9c fc ff ff       	jmp    f0100de9 <vprintfmt+0x2c>
f010114d:	89 45 e0             	mov    %eax,-0x20(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
f0101150:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101154:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010115b:	ff d7                	call   *%edi
			putch('x', putdat);
f010115d:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101161:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0101168:	ff d7                	call   *%edi
			num = (unsigned long long)
f010116a:	8b 45 14             	mov    0x14(%ebp),%eax
f010116d:	8d 50 04             	lea    0x4(%eax),%edx
f0101170:	89 55 14             	mov    %edx,0x14(%ebp)
f0101173:	8b 08                	mov    (%eax),%ecx
f0101175:	bb 00 00 00 00       	mov    $0x0,%ebx
f010117a:	b8 10 00 00 00       	mov    $0x10,%eax
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f010117f:	eb 16                	jmp    f0101197 <vprintfmt+0x3da>
f0101181:	89 45 e0             	mov    %eax,-0x20(%ebp)

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101184:	89 ca                	mov    %ecx,%edx
f0101186:	8d 45 14             	lea    0x14(%ebp),%eax
f0101189:	e8 d8 fb ff ff       	call   f0100d66 <getuint>
f010118e:	89 c1                	mov    %eax,%ecx
f0101190:	89 d3                	mov    %edx,%ebx
f0101192:	b8 10 00 00 00       	mov    $0x10,%eax
			base = 16;
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101197:	0f be 55 dc          	movsbl -0x24(%ebp),%edx
f010119b:	89 54 24 10          	mov    %edx,0x10(%esp)
f010119f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01011a2:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01011a6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01011aa:	89 0c 24             	mov    %ecx,(%esp)
f01011ad:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011b1:	89 f2                	mov    %esi,%edx
f01011b3:	89 f8                	mov    %edi,%eax
f01011b5:	e8 b6 fa ff ff       	call   f0100c70 <printnum>
f01011ba:	8b 5d e0             	mov    -0x20(%ebp),%ebx
			break;
f01011bd:	e9 27 fc ff ff       	jmp    f0100de9 <vprintfmt+0x2c>
f01011c2:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01011c5:	89 45 e0             	mov    %eax,-0x20(%ebp)

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01011c8:	89 74 24 04          	mov    %esi,0x4(%esp)
f01011cc:	89 14 24             	mov    %edx,(%esp)
f01011cf:	ff d7                	call   *%edi
f01011d1:	8b 5d e0             	mov    -0x20(%ebp),%ebx
			break;
f01011d4:	e9 10 fc ff ff       	jmp    f0100de9 <vprintfmt+0x2c>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01011d9:	89 74 24 04          	mov    %esi,0x4(%esp)
f01011dd:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01011e4:	ff d7                	call   *%edi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01011e6:	8d 43 ff             	lea    -0x1(%ebx),%eax
f01011e9:	80 38 25             	cmpb   $0x25,(%eax)
f01011ec:	0f 84 f7 fb ff ff    	je     f0100de9 <vprintfmt+0x2c>
f01011f2:	89 c3                	mov    %eax,%ebx
f01011f4:	eb f0                	jmp    f01011e6 <vprintfmt+0x429>
				/* do nothing */;
			break;
		}
	}
}
f01011f6:	83 c4 5c             	add    $0x5c,%esp
f01011f9:	5b                   	pop    %ebx
f01011fa:	5e                   	pop    %esi
f01011fb:	5f                   	pop    %edi
f01011fc:	5d                   	pop    %ebp
f01011fd:	c3                   	ret    

f01011fe <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01011fe:	55                   	push   %ebp
f01011ff:	89 e5                	mov    %esp,%ebp
f0101201:	83 ec 28             	sub    $0x28,%esp
f0101204:	8b 45 08             	mov    0x8(%ebp),%eax
f0101207:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
f010120a:	85 c0                	test   %eax,%eax
f010120c:	74 04                	je     f0101212 <vsnprintf+0x14>
f010120e:	85 d2                	test   %edx,%edx
f0101210:	7f 07                	jg     f0101219 <vsnprintf+0x1b>
f0101212:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0101217:	eb 3b                	jmp    f0101254 <vsnprintf+0x56>
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101219:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010121c:	8d 44 10 ff          	lea    -0x1(%eax,%edx,1),%eax
f0101220:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101223:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010122a:	8b 45 14             	mov    0x14(%ebp),%eax
f010122d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101231:	8b 45 10             	mov    0x10(%ebp),%eax
f0101234:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101238:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010123b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010123f:	c7 04 24 a0 0d 10 f0 	movl   $0xf0100da0,(%esp)
f0101246:	e8 72 fb ff ff       	call   f0100dbd <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010124b:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010124e:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101251:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f0101254:	c9                   	leave  
f0101255:	c3                   	ret    

f0101256 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101256:	55                   	push   %ebp
f0101257:	89 e5                	mov    %esp,%ebp
f0101259:	83 ec 18             	sub    $0x18,%esp

	return b.cnt;
}

int
snprintf(char *buf, int n, const char *fmt, ...)
f010125c:	8d 45 14             	lea    0x14(%ebp),%eax
{
	va_list ap;
	int rc;

	va_start(ap, fmt);
	rc = vsnprintf(buf, n, fmt, ap);
f010125f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101263:	8b 45 10             	mov    0x10(%ebp),%eax
f0101266:	89 44 24 08          	mov    %eax,0x8(%esp)
f010126a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010126d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101271:	8b 45 08             	mov    0x8(%ebp),%eax
f0101274:	89 04 24             	mov    %eax,(%esp)
f0101277:	e8 82 ff ff ff       	call   f01011fe <vsnprintf>
	va_end(ap);

	return rc;
}
f010127c:	c9                   	leave  
f010127d:	c3                   	ret    

f010127e <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f010127e:	55                   	push   %ebp
f010127f:	89 e5                	mov    %esp,%ebp
f0101281:	83 ec 18             	sub    $0x18,%esp
		}
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
f0101284:	8d 45 14             	lea    0x14(%ebp),%eax
{
	va_list ap;

	va_start(ap, fmt);
	vprintfmt(putch, putdat, fmt, ap);
f0101287:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010128b:	8b 45 10             	mov    0x10(%ebp),%eax
f010128e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101292:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101295:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101299:	8b 45 08             	mov    0x8(%ebp),%eax
f010129c:	89 04 24             	mov    %eax,(%esp)
f010129f:	e8 19 fb ff ff       	call   f0100dbd <vprintfmt>
	va_end(ap);
}
f01012a4:	c9                   	leave  
f01012a5:	c3                   	ret    
	...

f01012b0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01012b0:	55                   	push   %ebp
f01012b1:	89 e5                	mov    %esp,%ebp
f01012b3:	57                   	push   %edi
f01012b4:	56                   	push   %esi
f01012b5:	53                   	push   %ebx
f01012b6:	83 ec 1c             	sub    $0x1c,%esp
f01012b9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01012bc:	85 c0                	test   %eax,%eax
f01012be:	74 10                	je     f01012d0 <readline+0x20>
		cprintf("%s", prompt);
f01012c0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012c4:	c7 04 24 03 1f 10 f0 	movl   $0xf0101f03,(%esp)
f01012cb:	e8 5b f6 ff ff       	call   f010092b <cprintf>

	i = 0;
	echoing = iscons(0);
f01012d0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01012d7:	e8 b4 ef ff ff       	call   f0100290 <iscons>
f01012dc:	89 c7                	mov    %eax,%edi
f01012de:	be 00 00 00 00       	mov    $0x0,%esi
	while (1) {
		c = getchar();
f01012e3:	e8 97 ef ff ff       	call   f010027f <getchar>
f01012e8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01012ea:	85 c0                	test   %eax,%eax
f01012ec:	79 17                	jns    f0101305 <readline+0x55>
			cprintf("read error: %e\n", c);
f01012ee:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012f2:	c7 04 24 ec 20 10 f0 	movl   $0xf01020ec,(%esp)
f01012f9:	e8 2d f6 ff ff       	call   f010092b <cprintf>
f01012fe:	b8 00 00 00 00       	mov    $0x0,%eax
			return NULL;
f0101303:	eb 76                	jmp    f010137b <readline+0xcb>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101305:	83 f8 08             	cmp    $0x8,%eax
f0101308:	74 08                	je     f0101312 <readline+0x62>
f010130a:	83 f8 7f             	cmp    $0x7f,%eax
f010130d:	8d 76 00             	lea    0x0(%esi),%esi
f0101310:	75 19                	jne    f010132b <readline+0x7b>
f0101312:	85 f6                	test   %esi,%esi
f0101314:	7e 15                	jle    f010132b <readline+0x7b>
			if (echoing)
f0101316:	85 ff                	test   %edi,%edi
f0101318:	74 0c                	je     f0101326 <readline+0x76>
				cputchar('\b');
f010131a:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f0101321:	e8 74 f1 ff ff       	call   f010049a <cputchar>
			i--;
f0101326:	83 ee 01             	sub    $0x1,%esi
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
			return NULL;
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101329:	eb b8                	jmp    f01012e3 <readline+0x33>
			if (echoing)
				cputchar('\b');
			i--;
		} else if (c >= ' ' && i < BUFLEN-1) {
f010132b:	83 fb 1f             	cmp    $0x1f,%ebx
f010132e:	66 90                	xchg   %ax,%ax
f0101330:	7e 23                	jle    f0101355 <readline+0xa5>
f0101332:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101338:	7f 1b                	jg     f0101355 <readline+0xa5>
			if (echoing)
f010133a:	85 ff                	test   %edi,%edi
f010133c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101340:	74 08                	je     f010134a <readline+0x9a>
				cputchar(c);
f0101342:	89 1c 24             	mov    %ebx,(%esp)
f0101345:	e8 50 f1 ff ff       	call   f010049a <cputchar>
			buf[i++] = c;
f010134a:	88 9e 60 25 11 f0    	mov    %bl,-0xfeedaa0(%esi)
f0101350:	83 c6 01             	add    $0x1,%esi
f0101353:	eb 8e                	jmp    f01012e3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f0101355:	83 fb 0a             	cmp    $0xa,%ebx
f0101358:	74 05                	je     f010135f <readline+0xaf>
f010135a:	83 fb 0d             	cmp    $0xd,%ebx
f010135d:	75 84                	jne    f01012e3 <readline+0x33>
			if (echoing)
f010135f:	85 ff                	test   %edi,%edi
f0101361:	74 0c                	je     f010136f <readline+0xbf>
				cputchar('\n');
f0101363:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f010136a:	e8 2b f1 ff ff       	call   f010049a <cputchar>
			buf[i] = 0;
f010136f:	c6 86 60 25 11 f0 00 	movb   $0x0,-0xfeedaa0(%esi)
f0101376:	b8 60 25 11 f0       	mov    $0xf0112560,%eax
			return buf;
		}
	}
}
f010137b:	83 c4 1c             	add    $0x1c,%esp
f010137e:	5b                   	pop    %ebx
f010137f:	5e                   	pop    %esi
f0101380:	5f                   	pop    %edi
f0101381:	5d                   	pop    %ebp
f0101382:	c3                   	ret    
	...

f0101390 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101390:	55                   	push   %ebp
f0101391:	89 e5                	mov    %esp,%ebp
f0101393:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101396:	b8 00 00 00 00       	mov    $0x0,%eax
f010139b:	80 3a 00             	cmpb   $0x0,(%edx)
f010139e:	74 09                	je     f01013a9 <strlen+0x19>
		n++;
f01013a0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01013a3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01013a7:	75 f7                	jne    f01013a0 <strlen+0x10>
		n++;
	return n;
}
f01013a9:	5d                   	pop    %ebp
f01013aa:	c3                   	ret    

f01013ab <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01013ab:	55                   	push   %ebp
f01013ac:	89 e5                	mov    %esp,%ebp
f01013ae:	53                   	push   %ebx
f01013af:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01013b2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01013b5:	85 c9                	test   %ecx,%ecx
f01013b7:	74 19                	je     f01013d2 <strnlen+0x27>
f01013b9:	80 3b 00             	cmpb   $0x0,(%ebx)
f01013bc:	74 14                	je     f01013d2 <strnlen+0x27>
f01013be:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f01013c3:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01013c6:	39 c8                	cmp    %ecx,%eax
f01013c8:	74 0d                	je     f01013d7 <strnlen+0x2c>
f01013ca:	80 3c 03 00          	cmpb   $0x0,(%ebx,%eax,1)
f01013ce:	75 f3                	jne    f01013c3 <strnlen+0x18>
f01013d0:	eb 05                	jmp    f01013d7 <strnlen+0x2c>
f01013d2:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f01013d7:	5b                   	pop    %ebx
f01013d8:	5d                   	pop    %ebp
f01013d9:	c3                   	ret    

f01013da <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01013da:	55                   	push   %ebp
f01013db:	89 e5                	mov    %esp,%ebp
f01013dd:	53                   	push   %ebx
f01013de:	8b 45 08             	mov    0x8(%ebp),%eax
f01013e1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01013e4:	ba 00 00 00 00       	mov    $0x0,%edx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01013e9:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01013ed:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f01013f0:	83 c2 01             	add    $0x1,%edx
f01013f3:	84 c9                	test   %cl,%cl
f01013f5:	75 f2                	jne    f01013e9 <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f01013f7:	5b                   	pop    %ebx
f01013f8:	5d                   	pop    %ebp
f01013f9:	c3                   	ret    

f01013fa <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01013fa:	55                   	push   %ebp
f01013fb:	89 e5                	mov    %esp,%ebp
f01013fd:	56                   	push   %esi
f01013fe:	53                   	push   %ebx
f01013ff:	8b 45 08             	mov    0x8(%ebp),%eax
f0101402:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101405:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101408:	85 f6                	test   %esi,%esi
f010140a:	74 18                	je     f0101424 <strncpy+0x2a>
f010140c:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f0101411:	0f b6 1a             	movzbl (%edx),%ebx
f0101414:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101417:	80 3a 01             	cmpb   $0x1,(%edx)
f010141a:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010141d:	83 c1 01             	add    $0x1,%ecx
f0101420:	39 ce                	cmp    %ecx,%esi
f0101422:	77 ed                	ja     f0101411 <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101424:	5b                   	pop    %ebx
f0101425:	5e                   	pop    %esi
f0101426:	5d                   	pop    %ebp
f0101427:	c3                   	ret    

f0101428 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101428:	55                   	push   %ebp
f0101429:	89 e5                	mov    %esp,%ebp
f010142b:	56                   	push   %esi
f010142c:	53                   	push   %ebx
f010142d:	8b 75 08             	mov    0x8(%ebp),%esi
f0101430:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101433:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101436:	89 f0                	mov    %esi,%eax
f0101438:	85 c9                	test   %ecx,%ecx
f010143a:	74 27                	je     f0101463 <strlcpy+0x3b>
		while (--size > 0 && *src != '\0')
f010143c:	83 e9 01             	sub    $0x1,%ecx
f010143f:	74 1d                	je     f010145e <strlcpy+0x36>
f0101441:	0f b6 1a             	movzbl (%edx),%ebx
f0101444:	84 db                	test   %bl,%bl
f0101446:	74 16                	je     f010145e <strlcpy+0x36>
			*dst++ = *src++;
f0101448:	88 18                	mov    %bl,(%eax)
f010144a:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010144d:	83 e9 01             	sub    $0x1,%ecx
f0101450:	74 0e                	je     f0101460 <strlcpy+0x38>
			*dst++ = *src++;
f0101452:	83 c2 01             	add    $0x1,%edx
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101455:	0f b6 1a             	movzbl (%edx),%ebx
f0101458:	84 db                	test   %bl,%bl
f010145a:	75 ec                	jne    f0101448 <strlcpy+0x20>
f010145c:	eb 02                	jmp    f0101460 <strlcpy+0x38>
f010145e:	89 f0                	mov    %esi,%eax
			*dst++ = *src++;
		*dst = '\0';
f0101460:	c6 00 00             	movb   $0x0,(%eax)
f0101463:	29 f0                	sub    %esi,%eax
	}
	return dst - dst_in;
}
f0101465:	5b                   	pop    %ebx
f0101466:	5e                   	pop    %esi
f0101467:	5d                   	pop    %ebp
f0101468:	c3                   	ret    

f0101469 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101469:	55                   	push   %ebp
f010146a:	89 e5                	mov    %esp,%ebp
f010146c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010146f:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101472:	0f b6 01             	movzbl (%ecx),%eax
f0101475:	84 c0                	test   %al,%al
f0101477:	74 15                	je     f010148e <strcmp+0x25>
f0101479:	3a 02                	cmp    (%edx),%al
f010147b:	75 11                	jne    f010148e <strcmp+0x25>
		p++, q++;
f010147d:	83 c1 01             	add    $0x1,%ecx
f0101480:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101483:	0f b6 01             	movzbl (%ecx),%eax
f0101486:	84 c0                	test   %al,%al
f0101488:	74 04                	je     f010148e <strcmp+0x25>
f010148a:	3a 02                	cmp    (%edx),%al
f010148c:	74 ef                	je     f010147d <strcmp+0x14>
f010148e:	0f b6 c0             	movzbl %al,%eax
f0101491:	0f b6 12             	movzbl (%edx),%edx
f0101494:	29 d0                	sub    %edx,%eax
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101496:	5d                   	pop    %ebp
f0101497:	c3                   	ret    

f0101498 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101498:	55                   	push   %ebp
f0101499:	89 e5                	mov    %esp,%ebp
f010149b:	53                   	push   %ebx
f010149c:	8b 55 08             	mov    0x8(%ebp),%edx
f010149f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01014a2:	8b 45 10             	mov    0x10(%ebp),%eax
	while (n > 0 && *p && *p == *q)
f01014a5:	85 c0                	test   %eax,%eax
f01014a7:	74 23                	je     f01014cc <strncmp+0x34>
f01014a9:	0f b6 1a             	movzbl (%edx),%ebx
f01014ac:	84 db                	test   %bl,%bl
f01014ae:	74 24                	je     f01014d4 <strncmp+0x3c>
f01014b0:	3a 19                	cmp    (%ecx),%bl
f01014b2:	75 20                	jne    f01014d4 <strncmp+0x3c>
f01014b4:	83 e8 01             	sub    $0x1,%eax
f01014b7:	74 13                	je     f01014cc <strncmp+0x34>
		n--, p++, q++;
f01014b9:	83 c2 01             	add    $0x1,%edx
f01014bc:	83 c1 01             	add    $0x1,%ecx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01014bf:	0f b6 1a             	movzbl (%edx),%ebx
f01014c2:	84 db                	test   %bl,%bl
f01014c4:	74 0e                	je     f01014d4 <strncmp+0x3c>
f01014c6:	3a 19                	cmp    (%ecx),%bl
f01014c8:	74 ea                	je     f01014b4 <strncmp+0x1c>
f01014ca:	eb 08                	jmp    f01014d4 <strncmp+0x3c>
f01014cc:	b8 00 00 00 00       	mov    $0x0,%eax
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01014d1:	5b                   	pop    %ebx
f01014d2:	5d                   	pop    %ebp
f01014d3:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01014d4:	0f b6 02             	movzbl (%edx),%eax
f01014d7:	0f b6 11             	movzbl (%ecx),%edx
f01014da:	29 d0                	sub    %edx,%eax
f01014dc:	eb f3                	jmp    f01014d1 <strncmp+0x39>

f01014de <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01014de:	55                   	push   %ebp
f01014df:	89 e5                	mov    %esp,%ebp
f01014e1:	8b 45 08             	mov    0x8(%ebp),%eax
f01014e4:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01014e8:	0f b6 10             	movzbl (%eax),%edx
f01014eb:	84 d2                	test   %dl,%dl
f01014ed:	74 15                	je     f0101504 <strchr+0x26>
		if (*s == c)
f01014ef:	38 ca                	cmp    %cl,%dl
f01014f1:	75 07                	jne    f01014fa <strchr+0x1c>
f01014f3:	eb 14                	jmp    f0101509 <strchr+0x2b>
f01014f5:	38 ca                	cmp    %cl,%dl
f01014f7:	90                   	nop
f01014f8:	74 0f                	je     f0101509 <strchr+0x2b>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01014fa:	83 c0 01             	add    $0x1,%eax
f01014fd:	0f b6 10             	movzbl (%eax),%edx
f0101500:	84 d2                	test   %dl,%dl
f0101502:	75 f1                	jne    f01014f5 <strchr+0x17>
f0101504:	b8 00 00 00 00       	mov    $0x0,%eax
		if (*s == c)
			return (char *) s;
	return 0;
}
f0101509:	5d                   	pop    %ebp
f010150a:	c3                   	ret    

f010150b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010150b:	55                   	push   %ebp
f010150c:	89 e5                	mov    %esp,%ebp
f010150e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101511:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101515:	0f b6 10             	movzbl (%eax),%edx
f0101518:	84 d2                	test   %dl,%dl
f010151a:	74 18                	je     f0101534 <strfind+0x29>
		if (*s == c)
f010151c:	38 ca                	cmp    %cl,%dl
f010151e:	75 0a                	jne    f010152a <strfind+0x1f>
f0101520:	eb 12                	jmp    f0101534 <strfind+0x29>
f0101522:	38 ca                	cmp    %cl,%dl
f0101524:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101528:	74 0a                	je     f0101534 <strfind+0x29>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010152a:	83 c0 01             	add    $0x1,%eax
f010152d:	0f b6 10             	movzbl (%eax),%edx
f0101530:	84 d2                	test   %dl,%dl
f0101532:	75 ee                	jne    f0101522 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f0101534:	5d                   	pop    %ebp
f0101535:	c3                   	ret    

f0101536 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101536:	55                   	push   %ebp
f0101537:	89 e5                	mov    %esp,%ebp
f0101539:	83 ec 0c             	sub    $0xc,%esp
f010153c:	89 1c 24             	mov    %ebx,(%esp)
f010153f:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101543:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101547:	8b 7d 08             	mov    0x8(%ebp),%edi
f010154a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010154d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101550:	85 c9                	test   %ecx,%ecx
f0101552:	74 30                	je     f0101584 <memset+0x4e>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101554:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010155a:	75 25                	jne    f0101581 <memset+0x4b>
f010155c:	f6 c1 03             	test   $0x3,%cl
f010155f:	75 20                	jne    f0101581 <memset+0x4b>
		c &= 0xFF;
f0101561:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101564:	89 d3                	mov    %edx,%ebx
f0101566:	c1 e3 08             	shl    $0x8,%ebx
f0101569:	89 d6                	mov    %edx,%esi
f010156b:	c1 e6 18             	shl    $0x18,%esi
f010156e:	89 d0                	mov    %edx,%eax
f0101570:	c1 e0 10             	shl    $0x10,%eax
f0101573:	09 f0                	or     %esi,%eax
f0101575:	09 d0                	or     %edx,%eax
		asm volatile("cld; rep stosl\n"
f0101577:	09 d8                	or     %ebx,%eax
f0101579:	c1 e9 02             	shr    $0x2,%ecx
f010157c:	fc                   	cld    
f010157d:	f3 ab                	rep stos %eax,%es:(%edi)
{
	char *p;

	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010157f:	eb 03                	jmp    f0101584 <memset+0x4e>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101581:	fc                   	cld    
f0101582:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101584:	89 f8                	mov    %edi,%eax
f0101586:	8b 1c 24             	mov    (%esp),%ebx
f0101589:	8b 74 24 04          	mov    0x4(%esp),%esi
f010158d:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0101591:	89 ec                	mov    %ebp,%esp
f0101593:	5d                   	pop    %ebp
f0101594:	c3                   	ret    

f0101595 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101595:	55                   	push   %ebp
f0101596:	89 e5                	mov    %esp,%ebp
f0101598:	83 ec 08             	sub    $0x8,%esp
f010159b:	89 34 24             	mov    %esi,(%esp)
f010159e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01015a2:	8b 45 08             	mov    0x8(%ebp),%eax
f01015a5:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
f01015a8:	8b 75 0c             	mov    0xc(%ebp),%esi
	d = dst;
f01015ab:	89 c7                	mov    %eax,%edi
	if (s < d && s + n > d) {
f01015ad:	39 c6                	cmp    %eax,%esi
f01015af:	73 35                	jae    f01015e6 <memmove+0x51>
f01015b1:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01015b4:	39 d0                	cmp    %edx,%eax
f01015b6:	73 2e                	jae    f01015e6 <memmove+0x51>
		s += n;
		d += n;
f01015b8:	01 cf                	add    %ecx,%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01015ba:	f6 c2 03             	test   $0x3,%dl
f01015bd:	75 1b                	jne    f01015da <memmove+0x45>
f01015bf:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01015c5:	75 13                	jne    f01015da <memmove+0x45>
f01015c7:	f6 c1 03             	test   $0x3,%cl
f01015ca:	75 0e                	jne    f01015da <memmove+0x45>
			asm volatile("std; rep movsl\n"
f01015cc:	83 ef 04             	sub    $0x4,%edi
f01015cf:	8d 72 fc             	lea    -0x4(%edx),%esi
f01015d2:	c1 e9 02             	shr    $0x2,%ecx
f01015d5:	fd                   	std    
f01015d6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01015d8:	eb 09                	jmp    f01015e3 <memmove+0x4e>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01015da:	83 ef 01             	sub    $0x1,%edi
f01015dd:	8d 72 ff             	lea    -0x1(%edx),%esi
f01015e0:	fd                   	std    
f01015e1:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01015e3:	fc                   	cld    
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01015e4:	eb 20                	jmp    f0101606 <memmove+0x71>
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01015e6:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01015ec:	75 15                	jne    f0101603 <memmove+0x6e>
f01015ee:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01015f4:	75 0d                	jne    f0101603 <memmove+0x6e>
f01015f6:	f6 c1 03             	test   $0x3,%cl
f01015f9:	75 08                	jne    f0101603 <memmove+0x6e>
			asm volatile("cld; rep movsl\n"
f01015fb:	c1 e9 02             	shr    $0x2,%ecx
f01015fe:	fc                   	cld    
f01015ff:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101601:	eb 03                	jmp    f0101606 <memmove+0x71>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101603:	fc                   	cld    
f0101604:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101606:	8b 34 24             	mov    (%esp),%esi
f0101609:	8b 7c 24 04          	mov    0x4(%esp),%edi
f010160d:	89 ec                	mov    %ebp,%esp
f010160f:	5d                   	pop    %ebp
f0101610:	c3                   	ret    

f0101611 <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f0101611:	55                   	push   %ebp
f0101612:	89 e5                	mov    %esp,%ebp
f0101614:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101617:	8b 45 10             	mov    0x10(%ebp),%eax
f010161a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010161e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101621:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101625:	8b 45 08             	mov    0x8(%ebp),%eax
f0101628:	89 04 24             	mov    %eax,(%esp)
f010162b:	e8 65 ff ff ff       	call   f0101595 <memmove>
}
f0101630:	c9                   	leave  
f0101631:	c3                   	ret    

f0101632 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101632:	55                   	push   %ebp
f0101633:	89 e5                	mov    %esp,%ebp
f0101635:	57                   	push   %edi
f0101636:	56                   	push   %esi
f0101637:	53                   	push   %ebx
f0101638:	8b 75 08             	mov    0x8(%ebp),%esi
f010163b:	8b 7d 0c             	mov    0xc(%ebp),%edi
f010163e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101641:	85 c9                	test   %ecx,%ecx
f0101643:	74 36                	je     f010167b <memcmp+0x49>
		if (*s1 != *s2)
f0101645:	0f b6 06             	movzbl (%esi),%eax
f0101648:	0f b6 1f             	movzbl (%edi),%ebx
f010164b:	38 d8                	cmp    %bl,%al
f010164d:	74 20                	je     f010166f <memcmp+0x3d>
f010164f:	eb 14                	jmp    f0101665 <memcmp+0x33>
f0101651:	0f b6 44 16 01       	movzbl 0x1(%esi,%edx,1),%eax
f0101656:	0f b6 5c 17 01       	movzbl 0x1(%edi,%edx,1),%ebx
f010165b:	83 c2 01             	add    $0x1,%edx
f010165e:	83 e9 01             	sub    $0x1,%ecx
f0101661:	38 d8                	cmp    %bl,%al
f0101663:	74 12                	je     f0101677 <memcmp+0x45>
			return (int) *s1 - (int) *s2;
f0101665:	0f b6 c0             	movzbl %al,%eax
f0101668:	0f b6 db             	movzbl %bl,%ebx
f010166b:	29 d8                	sub    %ebx,%eax
f010166d:	eb 11                	jmp    f0101680 <memcmp+0x4e>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010166f:	83 e9 01             	sub    $0x1,%ecx
f0101672:	ba 00 00 00 00       	mov    $0x0,%edx
f0101677:	85 c9                	test   %ecx,%ecx
f0101679:	75 d6                	jne    f0101651 <memcmp+0x1f>
f010167b:	b8 00 00 00 00       	mov    $0x0,%eax
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
}
f0101680:	5b                   	pop    %ebx
f0101681:	5e                   	pop    %esi
f0101682:	5f                   	pop    %edi
f0101683:	5d                   	pop    %ebp
f0101684:	c3                   	ret    

f0101685 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101685:	55                   	push   %ebp
f0101686:	89 e5                	mov    %esp,%ebp
f0101688:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f010168b:	89 c2                	mov    %eax,%edx
f010168d:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101690:	39 d0                	cmp    %edx,%eax
f0101692:	73 15                	jae    f01016a9 <memfind+0x24>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101694:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f0101698:	38 08                	cmp    %cl,(%eax)
f010169a:	75 06                	jne    f01016a2 <memfind+0x1d>
f010169c:	eb 0b                	jmp    f01016a9 <memfind+0x24>
f010169e:	38 08                	cmp    %cl,(%eax)
f01016a0:	74 07                	je     f01016a9 <memfind+0x24>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01016a2:	83 c0 01             	add    $0x1,%eax
f01016a5:	39 c2                	cmp    %eax,%edx
f01016a7:	77 f5                	ja     f010169e <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01016a9:	5d                   	pop    %ebp
f01016aa:	c3                   	ret    

f01016ab <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01016ab:	55                   	push   %ebp
f01016ac:	89 e5                	mov    %esp,%ebp
f01016ae:	57                   	push   %edi
f01016af:	56                   	push   %esi
f01016b0:	53                   	push   %ebx
f01016b1:	83 ec 04             	sub    $0x4,%esp
f01016b4:	8b 55 08             	mov    0x8(%ebp),%edx
f01016b7:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01016ba:	0f b6 02             	movzbl (%edx),%eax
f01016bd:	3c 20                	cmp    $0x20,%al
f01016bf:	74 04                	je     f01016c5 <strtol+0x1a>
f01016c1:	3c 09                	cmp    $0x9,%al
f01016c3:	75 0e                	jne    f01016d3 <strtol+0x28>
		s++;
f01016c5:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01016c8:	0f b6 02             	movzbl (%edx),%eax
f01016cb:	3c 20                	cmp    $0x20,%al
f01016cd:	74 f6                	je     f01016c5 <strtol+0x1a>
f01016cf:	3c 09                	cmp    $0x9,%al
f01016d1:	74 f2                	je     f01016c5 <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
f01016d3:	3c 2b                	cmp    $0x2b,%al
f01016d5:	75 0c                	jne    f01016e3 <strtol+0x38>
		s++;
f01016d7:	83 c2 01             	add    $0x1,%edx
f01016da:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
f01016e1:	eb 15                	jmp    f01016f8 <strtol+0x4d>
	else if (*s == '-')
f01016e3:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
f01016ea:	3c 2d                	cmp    $0x2d,%al
f01016ec:	75 0a                	jne    f01016f8 <strtol+0x4d>
		s++, neg = 1;
f01016ee:	83 c2 01             	add    $0x1,%edx
f01016f1:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01016f8:	85 db                	test   %ebx,%ebx
f01016fa:	0f 94 c0             	sete   %al
f01016fd:	74 05                	je     f0101704 <strtol+0x59>
f01016ff:	83 fb 10             	cmp    $0x10,%ebx
f0101702:	75 18                	jne    f010171c <strtol+0x71>
f0101704:	80 3a 30             	cmpb   $0x30,(%edx)
f0101707:	75 13                	jne    f010171c <strtol+0x71>
f0101709:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f010170d:	8d 76 00             	lea    0x0(%esi),%esi
f0101710:	75 0a                	jne    f010171c <strtol+0x71>
		s += 2, base = 16;
f0101712:	83 c2 02             	add    $0x2,%edx
f0101715:	bb 10 00 00 00       	mov    $0x10,%ebx
		s++;
	else if (*s == '-')
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010171a:	eb 15                	jmp    f0101731 <strtol+0x86>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010171c:	84 c0                	test   %al,%al
f010171e:	66 90                	xchg   %ax,%ax
f0101720:	74 0f                	je     f0101731 <strtol+0x86>
f0101722:	bb 0a 00 00 00       	mov    $0xa,%ebx
f0101727:	80 3a 30             	cmpb   $0x30,(%edx)
f010172a:	75 05                	jne    f0101731 <strtol+0x86>
		s++, base = 8;
f010172c:	83 c2 01             	add    $0x1,%edx
f010172f:	b3 08                	mov    $0x8,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101731:	b8 00 00 00 00       	mov    $0x0,%eax
f0101736:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101738:	0f b6 0a             	movzbl (%edx),%ecx
f010173b:	89 cf                	mov    %ecx,%edi
f010173d:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0101740:	80 fb 09             	cmp    $0x9,%bl
f0101743:	77 08                	ja     f010174d <strtol+0xa2>
			dig = *s - '0';
f0101745:	0f be c9             	movsbl %cl,%ecx
f0101748:	83 e9 30             	sub    $0x30,%ecx
f010174b:	eb 1e                	jmp    f010176b <strtol+0xc0>
		else if (*s >= 'a' && *s <= 'z')
f010174d:	8d 5f 9f             	lea    -0x61(%edi),%ebx
f0101750:	80 fb 19             	cmp    $0x19,%bl
f0101753:	77 08                	ja     f010175d <strtol+0xb2>
			dig = *s - 'a' + 10;
f0101755:	0f be c9             	movsbl %cl,%ecx
f0101758:	83 e9 57             	sub    $0x57,%ecx
f010175b:	eb 0e                	jmp    f010176b <strtol+0xc0>
		else if (*s >= 'A' && *s <= 'Z')
f010175d:	8d 5f bf             	lea    -0x41(%edi),%ebx
f0101760:	80 fb 19             	cmp    $0x19,%bl
f0101763:	77 15                	ja     f010177a <strtol+0xcf>
			dig = *s - 'A' + 10;
f0101765:	0f be c9             	movsbl %cl,%ecx
f0101768:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f010176b:	39 f1                	cmp    %esi,%ecx
f010176d:	7d 0b                	jge    f010177a <strtol+0xcf>
			break;
		s++, val = (val * base) + dig;
f010176f:	83 c2 01             	add    $0x1,%edx
f0101772:	0f af c6             	imul   %esi,%eax
f0101775:	8d 04 01             	lea    (%ecx,%eax,1),%eax
		// we don't properly detect overflow!
	}
f0101778:	eb be                	jmp    f0101738 <strtol+0x8d>
f010177a:	89 c1                	mov    %eax,%ecx

	if (endptr)
f010177c:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101780:	74 05                	je     f0101787 <strtol+0xdc>
		*endptr = (char *) s;
f0101782:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101785:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0101787:	89 ca                	mov    %ecx,%edx
f0101789:	f7 da                	neg    %edx
f010178b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f010178f:	0f 45 c2             	cmovne %edx,%eax
}
f0101792:	83 c4 04             	add    $0x4,%esp
f0101795:	5b                   	pop    %ebx
f0101796:	5e                   	pop    %esi
f0101797:	5f                   	pop    %edi
f0101798:	5d                   	pop    %ebp
f0101799:	c3                   	ret    
f010179a:	00 00                	add    %al,(%eax)
f010179c:	00 00                	add    %al,(%eax)
	...

f01017a0 <__udivdi3>:
f01017a0:	55                   	push   %ebp
f01017a1:	89 e5                	mov    %esp,%ebp
f01017a3:	57                   	push   %edi
f01017a4:	56                   	push   %esi
f01017a5:	83 ec 10             	sub    $0x10,%esp
f01017a8:	8b 45 14             	mov    0x14(%ebp),%eax
f01017ab:	8b 55 08             	mov    0x8(%ebp),%edx
f01017ae:	8b 75 10             	mov    0x10(%ebp),%esi
f01017b1:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01017b4:	85 c0                	test   %eax,%eax
f01017b6:	89 55 f0             	mov    %edx,-0x10(%ebp)
f01017b9:	75 35                	jne    f01017f0 <__udivdi3+0x50>
f01017bb:	39 fe                	cmp    %edi,%esi
f01017bd:	77 61                	ja     f0101820 <__udivdi3+0x80>
f01017bf:	85 f6                	test   %esi,%esi
f01017c1:	75 0b                	jne    f01017ce <__udivdi3+0x2e>
f01017c3:	b8 01 00 00 00       	mov    $0x1,%eax
f01017c8:	31 d2                	xor    %edx,%edx
f01017ca:	f7 f6                	div    %esi
f01017cc:	89 c6                	mov    %eax,%esi
f01017ce:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f01017d1:	31 d2                	xor    %edx,%edx
f01017d3:	89 f8                	mov    %edi,%eax
f01017d5:	f7 f6                	div    %esi
f01017d7:	89 c7                	mov    %eax,%edi
f01017d9:	89 c8                	mov    %ecx,%eax
f01017db:	f7 f6                	div    %esi
f01017dd:	89 c1                	mov    %eax,%ecx
f01017df:	89 fa                	mov    %edi,%edx
f01017e1:	89 c8                	mov    %ecx,%eax
f01017e3:	83 c4 10             	add    $0x10,%esp
f01017e6:	5e                   	pop    %esi
f01017e7:	5f                   	pop    %edi
f01017e8:	5d                   	pop    %ebp
f01017e9:	c3                   	ret    
f01017ea:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01017f0:	39 f8                	cmp    %edi,%eax
f01017f2:	77 1c                	ja     f0101810 <__udivdi3+0x70>
f01017f4:	0f bd d0             	bsr    %eax,%edx
f01017f7:	83 f2 1f             	xor    $0x1f,%edx
f01017fa:	89 55 f4             	mov    %edx,-0xc(%ebp)
f01017fd:	75 39                	jne    f0101838 <__udivdi3+0x98>
f01017ff:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0101802:	0f 86 a0 00 00 00    	jbe    f01018a8 <__udivdi3+0x108>
f0101808:	39 f8                	cmp    %edi,%eax
f010180a:	0f 82 98 00 00 00    	jb     f01018a8 <__udivdi3+0x108>
f0101810:	31 ff                	xor    %edi,%edi
f0101812:	31 c9                	xor    %ecx,%ecx
f0101814:	89 c8                	mov    %ecx,%eax
f0101816:	89 fa                	mov    %edi,%edx
f0101818:	83 c4 10             	add    $0x10,%esp
f010181b:	5e                   	pop    %esi
f010181c:	5f                   	pop    %edi
f010181d:	5d                   	pop    %ebp
f010181e:	c3                   	ret    
f010181f:	90                   	nop
f0101820:	89 d1                	mov    %edx,%ecx
f0101822:	89 fa                	mov    %edi,%edx
f0101824:	89 c8                	mov    %ecx,%eax
f0101826:	31 ff                	xor    %edi,%edi
f0101828:	f7 f6                	div    %esi
f010182a:	89 c1                	mov    %eax,%ecx
f010182c:	89 fa                	mov    %edi,%edx
f010182e:	89 c8                	mov    %ecx,%eax
f0101830:	83 c4 10             	add    $0x10,%esp
f0101833:	5e                   	pop    %esi
f0101834:	5f                   	pop    %edi
f0101835:	5d                   	pop    %ebp
f0101836:	c3                   	ret    
f0101837:	90                   	nop
f0101838:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
f010183c:	89 f2                	mov    %esi,%edx
f010183e:	d3 e0                	shl    %cl,%eax
f0101840:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101843:	b8 20 00 00 00       	mov    $0x20,%eax
f0101848:	2b 45 f4             	sub    -0xc(%ebp),%eax
f010184b:	89 c1                	mov    %eax,%ecx
f010184d:	d3 ea                	shr    %cl,%edx
f010184f:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
f0101853:	0b 55 ec             	or     -0x14(%ebp),%edx
f0101856:	d3 e6                	shl    %cl,%esi
f0101858:	89 c1                	mov    %eax,%ecx
f010185a:	89 75 e8             	mov    %esi,-0x18(%ebp)
f010185d:	89 fe                	mov    %edi,%esi
f010185f:	d3 ee                	shr    %cl,%esi
f0101861:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
f0101865:	89 55 ec             	mov    %edx,-0x14(%ebp)
f0101868:	8b 55 f0             	mov    -0x10(%ebp),%edx
f010186b:	d3 e7                	shl    %cl,%edi
f010186d:	89 c1                	mov    %eax,%ecx
f010186f:	d3 ea                	shr    %cl,%edx
f0101871:	09 d7                	or     %edx,%edi
f0101873:	89 f2                	mov    %esi,%edx
f0101875:	89 f8                	mov    %edi,%eax
f0101877:	f7 75 ec             	divl   -0x14(%ebp)
f010187a:	89 d6                	mov    %edx,%esi
f010187c:	89 c7                	mov    %eax,%edi
f010187e:	f7 65 e8             	mull   -0x18(%ebp)
f0101881:	39 d6                	cmp    %edx,%esi
f0101883:	89 55 ec             	mov    %edx,-0x14(%ebp)
f0101886:	72 30                	jb     f01018b8 <__udivdi3+0x118>
f0101888:	8b 55 f0             	mov    -0x10(%ebp),%edx
f010188b:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
f010188f:	d3 e2                	shl    %cl,%edx
f0101891:	39 c2                	cmp    %eax,%edx
f0101893:	73 05                	jae    f010189a <__udivdi3+0xfa>
f0101895:	3b 75 ec             	cmp    -0x14(%ebp),%esi
f0101898:	74 1e                	je     f01018b8 <__udivdi3+0x118>
f010189a:	89 f9                	mov    %edi,%ecx
f010189c:	31 ff                	xor    %edi,%edi
f010189e:	e9 71 ff ff ff       	jmp    f0101814 <__udivdi3+0x74>
f01018a3:	90                   	nop
f01018a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01018a8:	31 ff                	xor    %edi,%edi
f01018aa:	b9 01 00 00 00       	mov    $0x1,%ecx
f01018af:	e9 60 ff ff ff       	jmp    f0101814 <__udivdi3+0x74>
f01018b4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01018b8:	8d 4f ff             	lea    -0x1(%edi),%ecx
f01018bb:	31 ff                	xor    %edi,%edi
f01018bd:	89 c8                	mov    %ecx,%eax
f01018bf:	89 fa                	mov    %edi,%edx
f01018c1:	83 c4 10             	add    $0x10,%esp
f01018c4:	5e                   	pop    %esi
f01018c5:	5f                   	pop    %edi
f01018c6:	5d                   	pop    %ebp
f01018c7:	c3                   	ret    
	...

f01018d0 <__umoddi3>:
f01018d0:	55                   	push   %ebp
f01018d1:	89 e5                	mov    %esp,%ebp
f01018d3:	57                   	push   %edi
f01018d4:	56                   	push   %esi
f01018d5:	83 ec 20             	sub    $0x20,%esp
f01018d8:	8b 55 14             	mov    0x14(%ebp),%edx
f01018db:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01018de:	8b 7d 10             	mov    0x10(%ebp),%edi
f01018e1:	8b 75 0c             	mov    0xc(%ebp),%esi
f01018e4:	85 d2                	test   %edx,%edx
f01018e6:	89 c8                	mov    %ecx,%eax
f01018e8:	89 4d f4             	mov    %ecx,-0xc(%ebp)
f01018eb:	75 13                	jne    f0101900 <__umoddi3+0x30>
f01018ed:	39 f7                	cmp    %esi,%edi
f01018ef:	76 3f                	jbe    f0101930 <__umoddi3+0x60>
f01018f1:	89 f2                	mov    %esi,%edx
f01018f3:	f7 f7                	div    %edi
f01018f5:	89 d0                	mov    %edx,%eax
f01018f7:	31 d2                	xor    %edx,%edx
f01018f9:	83 c4 20             	add    $0x20,%esp
f01018fc:	5e                   	pop    %esi
f01018fd:	5f                   	pop    %edi
f01018fe:	5d                   	pop    %ebp
f01018ff:	c3                   	ret    
f0101900:	39 f2                	cmp    %esi,%edx
f0101902:	77 4c                	ja     f0101950 <__umoddi3+0x80>
f0101904:	0f bd ca             	bsr    %edx,%ecx
f0101907:	83 f1 1f             	xor    $0x1f,%ecx
f010190a:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010190d:	75 51                	jne    f0101960 <__umoddi3+0x90>
f010190f:	3b 7d f4             	cmp    -0xc(%ebp),%edi
f0101912:	0f 87 e0 00 00 00    	ja     f01019f8 <__umoddi3+0x128>
f0101918:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010191b:	29 f8                	sub    %edi,%eax
f010191d:	19 d6                	sbb    %edx,%esi
f010191f:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0101922:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101925:	89 f2                	mov    %esi,%edx
f0101927:	83 c4 20             	add    $0x20,%esp
f010192a:	5e                   	pop    %esi
f010192b:	5f                   	pop    %edi
f010192c:	5d                   	pop    %ebp
f010192d:	c3                   	ret    
f010192e:	66 90                	xchg   %ax,%ax
f0101930:	85 ff                	test   %edi,%edi
f0101932:	75 0b                	jne    f010193f <__umoddi3+0x6f>
f0101934:	b8 01 00 00 00       	mov    $0x1,%eax
f0101939:	31 d2                	xor    %edx,%edx
f010193b:	f7 f7                	div    %edi
f010193d:	89 c7                	mov    %eax,%edi
f010193f:	89 f0                	mov    %esi,%eax
f0101941:	31 d2                	xor    %edx,%edx
f0101943:	f7 f7                	div    %edi
f0101945:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101948:	f7 f7                	div    %edi
f010194a:	eb a9                	jmp    f01018f5 <__umoddi3+0x25>
f010194c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101950:	89 c8                	mov    %ecx,%eax
f0101952:	89 f2                	mov    %esi,%edx
f0101954:	83 c4 20             	add    $0x20,%esp
f0101957:	5e                   	pop    %esi
f0101958:	5f                   	pop    %edi
f0101959:	5d                   	pop    %ebp
f010195a:	c3                   	ret    
f010195b:	90                   	nop
f010195c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101960:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101964:	d3 e2                	shl    %cl,%edx
f0101966:	89 55 f4             	mov    %edx,-0xc(%ebp)
f0101969:	ba 20 00 00 00       	mov    $0x20,%edx
f010196e:	2b 55 f0             	sub    -0x10(%ebp),%edx
f0101971:	89 55 ec             	mov    %edx,-0x14(%ebp)
f0101974:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f0101978:	89 fa                	mov    %edi,%edx
f010197a:	d3 ea                	shr    %cl,%edx
f010197c:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101980:	0b 55 f4             	or     -0xc(%ebp),%edx
f0101983:	d3 e7                	shl    %cl,%edi
f0101985:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f0101989:	89 55 f4             	mov    %edx,-0xc(%ebp)
f010198c:	89 f2                	mov    %esi,%edx
f010198e:	89 7d e8             	mov    %edi,-0x18(%ebp)
f0101991:	89 c7                	mov    %eax,%edi
f0101993:	d3 ea                	shr    %cl,%edx
f0101995:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101999:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010199c:	89 c2                	mov    %eax,%edx
f010199e:	d3 e6                	shl    %cl,%esi
f01019a0:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f01019a4:	d3 ea                	shr    %cl,%edx
f01019a6:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f01019aa:	09 d6                	or     %edx,%esi
f01019ac:	89 f0                	mov    %esi,%eax
f01019ae:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01019b1:	d3 e7                	shl    %cl,%edi
f01019b3:	89 f2                	mov    %esi,%edx
f01019b5:	f7 75 f4             	divl   -0xc(%ebp)
f01019b8:	89 d6                	mov    %edx,%esi
f01019ba:	f7 65 e8             	mull   -0x18(%ebp)
f01019bd:	39 d6                	cmp    %edx,%esi
f01019bf:	72 2b                	jb     f01019ec <__umoddi3+0x11c>
f01019c1:	39 c7                	cmp    %eax,%edi
f01019c3:	72 23                	jb     f01019e8 <__umoddi3+0x118>
f01019c5:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f01019c9:	29 c7                	sub    %eax,%edi
f01019cb:	19 d6                	sbb    %edx,%esi
f01019cd:	89 f0                	mov    %esi,%eax
f01019cf:	89 f2                	mov    %esi,%edx
f01019d1:	d3 ef                	shr    %cl,%edi
f01019d3:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f01019d7:	d3 e0                	shl    %cl,%eax
f01019d9:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f01019dd:	09 f8                	or     %edi,%eax
f01019df:	d3 ea                	shr    %cl,%edx
f01019e1:	83 c4 20             	add    $0x20,%esp
f01019e4:	5e                   	pop    %esi
f01019e5:	5f                   	pop    %edi
f01019e6:	5d                   	pop    %ebp
f01019e7:	c3                   	ret    
f01019e8:	39 d6                	cmp    %edx,%esi
f01019ea:	75 d9                	jne    f01019c5 <__umoddi3+0xf5>
f01019ec:	2b 45 e8             	sub    -0x18(%ebp),%eax
f01019ef:	1b 55 f4             	sbb    -0xc(%ebp),%edx
f01019f2:	eb d1                	jmp    f01019c5 <__umoddi3+0xf5>
f01019f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01019f8:	39 f2                	cmp    %esi,%edx
f01019fa:	0f 82 18 ff ff ff    	jb     f0101918 <__umoddi3+0x48>
f0101a00:	e9 1d ff ff ff       	jmp    f0101922 <__umoddi3+0x52>
