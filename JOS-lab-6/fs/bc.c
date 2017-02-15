
#include "fs.h"

// Return the virtual address of this disk block.
void*
diskaddr(uint32_t blockno)
{
	if (blockno == 0 || (super && blockno >= super->s_nblocks))
		panic("bad block number %08x in diskaddr", blockno);
	return (char*) (DISKMAP + blockno * BLKSIZE);
}

// Is this virtual address mapped?
bool
va_is_mapped(void *va)
{
	return (vpd[PDX(va)] & PTE_P) && (vpt[PGNUM(va)] & PTE_P);
}

// Is this virtual address dirty?
bool
va_is_dirty(void *va)
{
	return (vpt[PGNUM(va)] & PTE_D) != 0;
}

// Fault any disk block that is read or written in to memory by
// loading it from disk.
// Hint: Use ide_read and BLKSECTS.
static void
bc_pgfault(struct UTrapframe *utf)
{
	void *addr = (void *) utf->utf_fault_va;
	uint32_t blockno = ((uint32_t)addr - DISKMAP) / BLKSIZE;
	int r;
    uint32_t pgatr;
	// Check that the fault was within the block cache region
	if (addr < (void*)DISKMAP || addr >= (void*)(DISKMAP + DISKSIZE))
		panic("page fault in FS: eip %08x, va %08x, err %04x",
		      utf->utf_eip, addr, utf->utf_err);

	// Sanity check the block number.
	if (super && blockno >= super->s_nblocks)
		panic("reading non-existent block %08x\n", blockno);

	// Allocate a page in the disk map region, read the contents
	// of the block from the disk into that page, and mark the
	// page not-dirty (since reading the data from disk will mark
	// the page dirty).
	//
	// LAB 5: Your code here
	//panic("bc_pgfault not implemented");
	//addr = ROUNDDOWN(addr,PGSIZE);

	if((r = sys_page_alloc(sys_getenvid(),addr,PTE_P | PTE_U |PTE_W)) < 0)
	    panic("page alloc error:%e\n",r);

	if((r = ide_read(blockno * BLKSECTS,addr,BLKSECTS)) < 0)
        panic("ide reader error:%e\n",r);

    //addr has been mapped by sys_page_alloc
    pgatr = PGOFF( vpt[PGNUM(addr)] ) & ~PTE_D ;
    if((r = sys_page_map(0, addr, 0, addr, pgatr)) < 0)
        panic("page map error:%e\n",r);

	// Check that the block we read was allocated. (exercise for
	// the reader: why do we do this *after* reading the block
	// in?)
	if (bitmap && block_is_free(blockno))
		panic("reading free block %08x\n", blockno);
}

// Flush the contents of the block containing VA out to disk if
// necessary, then clear the PTE_D bit using sys_page_map.
// If the block is not in the block cache or is not dirty, does
// nothing.
// Hint: Use va_is_mapped, va_is_dirty, and ide_write.
// Hint: Use the PTE_SYSCALL constant when calling sys_page_map.
// Hint: Don't forget to round addr down.
void
flush_block(void *addr)
{
	uint32_t blockno = ((uint32_t)addr - DISKMAP) / BLKSIZE;
    uint32_t pgatri;


	if (addr < (void*)DISKMAP || addr >= (void*)(DISKMAP + DISKSIZE))
		panic("flush_block of bad va %08x", addr);

	// LAB 5: Your code here.
	if(!va_is_mapped(addr))
        return;
    if( !(vpt[PGNUM(addr)] & PTE_D))
        return;

    if (super && blockno >= super->s_nblocks)
		panic("writing non-existent block %08x\n", blockno);

    if(ide_write(blockno * BLKSECTS, ROUNDDOWN(addr,PGSIZE), BLKSECTS) < 0)
        panic("ide write error\n");

    pgatri = PGOFF( vpt[PGNUM(addr)] ) & ~PTE_D;

    if(sys_page_map(0,ROUNDDOWN(addr,PGSIZE),0,ROUNDDOWN(addr,PGSIZE),pgatri) < 0)
        panic("page map error");
	//panic("flush_block not implemented");
}

// Test that the block cache works, by smashing the superblock and
// reading it back.
static void
check_bc(void)
{
	struct Super backup;

	// back up super block
	memmove(&backup, diskaddr(1), sizeof backup);

	// smash it
	strcpy(diskaddr(1), "OOPS!\n");
	flush_block(diskaddr(1));
	assert(va_is_mapped(diskaddr(1)));
	assert(!va_is_dirty(diskaddr(1)));

	// clear it out
	sys_page_unmap(0, diskaddr(1));
	assert(!va_is_mapped(diskaddr(1)));

	// read it back in
	assert(strcmp(diskaddr(1), "OOPS!\n") == 0);

	// fix it
	memmove(diskaddr(1), &backup, sizeof backup);
	flush_block(diskaddr(1));

	cprintf("block cache is good\n");
}

void
bc_init(void)
{
	set_pgfault_handler(bc_pgfault);
	check_bc();
}
