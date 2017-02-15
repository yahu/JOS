#include <inc/lib.h>

int
pageref(void *v)
{
	pte_t pte;
    //cprintf("addr %x,",(uint32_t)v);
	if (!(vpd[PDX(v)] & PTE_P)){
	 //   cprintf("   ptd = 0\n");
        return 0;
	}

	pte = vpt[PGNUM(v)];
	if (!(pte & PTE_P)){
	    cprintf("   pte = 0\n");
		return 0;
	}
	//cprintf("   phyaddr is %x,its ref is %d\n", pte & ~0xfff ,pages[PGNUM(pte)].pp_ref);
	return pages[PGNUM(pte)].pp_ref;
}
