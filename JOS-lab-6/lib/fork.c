// implement fork from user space

#include <inc/string.h>
#include <inc/lib.h>

// PTE_COW marks copy-on-write page table entries.
// It is one of the bits explicitly allocated to user processes (PTE_AVAIL).
#define PTE_COW		0x800

//
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
	void *addr = (void *) utf->utf_fault_va;
	uint32_t err = utf->utf_err;
	int r;
    pte_t pte ;
    envid_t envid;
	// Check that the faulting access was (1) a write, and (2) to a
	// copy-on-write page.  If not, panic.
	// Hint:
	//   Use the read-only page table mappings at vpt
	//   (see <inc/memlayout.h>).

	// LAB 4: Your code here.
	//ptep = pgdir_walk(curenv->env_pgdir,addr,0);

	pte = ((pte_t *)UVPT)[PGNUM(addr)];
	//cprintf("address %x 's pte is %x\n",(uint32_t)addr,(uint32_t)pte);

	if((uint32_t)addr >= UTOP || !(err & PTE_P)  || !(err & PTE_W ) || !(pte & PTE_COW))
        panic("page fault and it's type is not Copy-on-Write\n");


	// Allocate a new page, map it at a temporary location (PFTEMP),
	// copy the data from the old page to the new page, then move the new
	// page to the old page's address.
	// Hint:
	//   You should make three system calls.
	//   No need to explicitly delete the old page's mapping.

	// LAB 4: Your code here.
	envid = sys_getenvid();
	if(sys_page_alloc(envid, (void *)PFTEMP, PTE_U | PTE_W | PTE_P) < 0)
        panic("in pgfault,sys_page_alloc fail\n");

    // cprintf("inpgfault,before memmove\n");
    addr = (void *)( (uint32_t)addr & ~0xfff );
    memmove((void *)PFTEMP,addr,PGSIZE);

    if(sys_page_map(0, (void *)PFTEMP,0, addr, PTE_U | PTE_W |PTE_P) < 0)
        panic("in pgfault,sys_page_map fail\n");

    if( (r = sys_page_unmap(0, (void *)PFTEMP))<0)
        panic("in pgfault,sys_page_unmap fail\n");

	//panic("pgfault not implemented");
}

//
// Map our virtual page pn (address pn*PGSIZE) into the target envid
// at the same virtual address.  If the page is writable or copy-on-write,
// the new mapping must be created copy-on-write, and then our mapping must be
// marked copy-on-write as well.  (Exercise: Why do we need to mark ours
// copy-on-write again if it was already copy-on-write at the beginning of
// this function?)
//
// Returns: 0 on success, < 0 on error.
// It is also OK to panic on error.
//
static int
duppage(envid_t envid, unsigned pn)
{
	int r;
	pte_t pte;
	int perm;

	// LAB 4: Your code here.

	if( !(((pte_t*)vpd)[PDX(pn*PGSIZE)] & PTE_P) ){
	    cprintf("in duppage,PDX error\n");
	}

    pte = ((pte_t *)UVPT)[pn];
    perm = PTE_P | PTE_U;

    if((pte & PTE_COW) || (pte & PTE_W) )
        perm = (pte | PTE_COW) & ~PTE_W;
        //perm =perm | PTE_COW;
    if( sys_page_map(0, (void*) (pn*PGSIZE),envid, (void *)(pn*PGSIZE), perm) < 0)
        return -E_FAULT;

    //cprintf("duppage 1.1,pn=%x\n",pn);
    if( (pte & PTE_COW) || (pte & PTE_W) ){
         if( sys_page_map(0, (void *)(pn*PGSIZE),0, (void *)(pn*PGSIZE), perm) < 0)
            return -E_FAULT;
    }

    //cprintf("duppage 1.2,pn=%x\n",pn);
	//panic("duppage not implemented");
	return 0;
}

//
// User-level fork with copy-on-write.
// Set up our page fault handler appropriately.
// Create a child.
// Copy our address space and page fault handler setup to the child.
// Then mark the child as runnable and return.
//
// Returns: child's envid to the parent, 0 to the child, < 0 on error.
// It is also OK to panic on error.
//
// Hint:
//   Use vpd, vpt, and duppage.
//   Remember to fix "thisenv" in the child process.
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
envid_t
fork(void)
{
	// LAB 4: Your code here.
	envid_t envid;
    uintptr_t pn;
    uintptr_t addr;
    pte_t pte;
    extern unsigned char end[];
    extern void _pgfault_upcall(void);

    set_pgfault_handler(pgfault);

    if((envid = sys_exofork()) == 0){
        // if at here,which means it's son process now,and this process's env_pgfault_upcall  field is 0,because
        // after env_alloc() initilize it 0,wo have not changed it .so first use set_pgfault_handler() will alloc
        // one new page at address UXSTACKTOP - PGSIZE,at same time set env_pgfault_upcall field and _pgfault_handler field

        //debug print
        // cprintf("son process ,fork re value is %x\n",envid);

       // set_pgfault_handler(pgfault);

        struct Env * envp= (struct Env*)envs;
    //   sys_cputs("sys_cputs curenv->env_id=%x\n", envid);
        envid_t curenvid = sys_getenvid();

        while(envp < envs + NENV && curenvid != envp->env_id)
            envp++;

        if(envp >= envs + NENV){
            cprintf("envp >= envs + NENV\n");
            sys_env_destroy(envid);
        }
        thisenv = envp;

        return 0;
    }
    //debug print
   // cprintf("parent process ,fork re value is %x\n",envid);


   for(pn=0;pn * PGSIZE < UTOP - PGSIZE;pn++ ){

        if( !(((pte_t*)vpd)[PDX(pn*PGSIZE)] & PTE_P) )
            continue;
        pte = ((pte_t *)UVPT)[pn];

        if(pte & PTE_P){
          // cprintf("in duppage pn=%x,pte = %x\n",pn,(uint32_t)pte);
            duppage(envid,pn);
        }
    }


    if(sys_env_set_pgfault_upcall(envid, _pgfault_upcall) < 0){
        panic("in fork,sys_env_set_pgfault_upcall fail\n");
    }
    if(sys_page_alloc(envid,(void *)(UXSTACKTOP - PGSIZE),PTE_W | PTE_U |PTE_P) < 0){
        panic("in fork,sys_page_alloc\n");
    }


    sys_env_set_status(envid,ENV_RUNNABLE);
    return envid;

	//panic("fork not implemented");
}

// Challenge!
int
sfork(void)
{
	panic("sfork not implemented");
	return -E_INVAL;
}
