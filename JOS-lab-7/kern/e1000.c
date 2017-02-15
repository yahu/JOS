#include <inc/x86.h>
#include <kern/e1000.h>
#include <kern/pci.h>
#include <inc/string.h>
#include <inc/stdio.h>
#include <inc/mmu.h>
#include <kern/pmap.h>
#include <kern/env.h>
// LAB 6: Your driver code here

volatile uint32_t *e1000bar0;
struct tx_desc *td_ring;
struct rx_desc *rd_ring;

static void
hexdump(const char *prefix, const void *data, int len);

int e1000_pic_attach(struct pci_func *pcif){
    extern pde_t *kern_pgdir;
    struct Page * pp;

    physaddr_t td_ringpa;
    physaddr_t rd_ringpa;

    physaddr_t pp_pa;




    int i;


    cprintf("in e1000_pic_attach\n");
    pci_func_enable(pcif);

    boot_map_region(kern_pgdir, KSTACKTOP, ROUNDUP(pcif->reg_size[0],PGSIZE),
                   pcif->reg_base[0], PTE_PCD|PTE_PWT | PTE_W | PTE_P);//| PTE_W


    e1000bar0 = (volatile uint32_t *)KSTACKTOP;

    //initial e1000 tansmit function
    e1000_init_tx();
    //initial e1000 recieve function
    e1000_init_rx();

    cprintf("e1000 's status is %x\n",e1000bar0[2]);
   // return 1;
   return 0;
}

void e1000_init_tx(){
    struct Page * pp;

    physaddr_t td_ringpa;
    physaddr_t pp_pa;
    int i;

    if((pp = page_alloc(ALLOC_ZERO)) == 0)
        panic("alloc page error\n");
    pp->pp_ref = 1;

    td_ring = (struct tx_desc *)page2kva(pp);
    td_ringpa = page2pa(pp);

    e1000bar0[E1000_TDBAL / 4] = td_ringpa;
    e1000bar0[E1000_TDBAH / 4] = 0;
    e1000bar0[E1000_TDH / 4] = 0;
    e1000bar0[E1000_TDT / 4] = 0;
    e1000bar0[E1000_TDLEN / 4] = E1000_TDRING_SZ * sizeof(*td_ring);

    for(i=0;i < E1000_TDRING_SZ;i++,i++){
        if((pp = page_alloc(ALLOC_ZERO)) == 0)
            panic("page alloc error\n");
        pp->pp_ref = 1;
        pp_pa = page2pa(pp);

        td_ring[i].addr = pp_pa;
        td_ring[i].status |= E1000_TXD_STAT_DD;
        td_ring[i + 1].addr = pp_pa + PGSIZE / 2;
        td_ring[i+1].status |= E1000_TXD_STAT_DD;
      //  cprintf("td_ring[%d].addr = %x\n",i,td_ring[i].addr);
       // cprintf("td_ring[%d].addr = %x\n",i+1,td_ring[i+1].addr);
    }
    e1000bar0[E1000_TCTL / 4] = 0;
    e1000bar0[E1000_TCTL / 4] |= E1000_TCTL_EN | E1000_TCTL_PSP |
                (0x10 << E1000_TCTL_CT_OFFSET) | (0x40<< E1000_TCTL_COLD_OFFSET);

    e1000bar0[E1000_TIPG / 4] = 0;
    e1000bar0[E1000_TIPG / 4] |= (10 << E1000_TIPG_OFFSET)  | (8 << E1000_TIPG1_OFFSET) |
                (6 << E1000_TIPG2_OFFSET);



}
void e1000_init_rx(){

    struct Page * pp;

    physaddr_t rd_ringpa;
    physaddr_t pp_pa;
    int i;

    e1000bar0[E1000_RAL / 4] = 0x12005452;  //0x12005452;//0x52540012;//0x00123456;
    e1000bar0[E1000_RAH / 4] = 0x5634;  //0x5634;//0x3456;//0x5254;
    e1000bar0[E1000_RAH / 4]  |= E1000_RAH_AV;

    e1000bar0[E1000_RCTL / 4] = 0;

    cprintf("e1000bar0[E1000_RAL /4 ] =%x\n",e1000bar0[E1000_RAL /4 ]);
    cprintf("e1000bar0[E1000_RAH /4 ] =%x\n",e1000bar0[E1000_RAH /4 ]);
    for(i=0;i < E1000_MTA_SZ;i+=4){
        e1000bar0[(E1000_MTA + i) /4] = 0;
    }


    if((pp = page_alloc(ALLOC_ZERO)) == 0)
        panic("alloc page error\n");
    pp->pp_ref = 1;

    rd_ring = (struct rx_desc *)page2kva(pp);
    rd_ringpa = page2pa(pp);

    e1000bar0[E1000_RDBAL / 4] = rd_ringpa;
    e1000bar0[E1000_RDBAH / 4] = 0;
    e1000bar0[E1000_RDH / 4] = 1;
    e1000bar0[E1000_RDT / 4] = 0;
    e1000bar0[E1000_RDLEN / 4] = E1000_RDRING_SZ * sizeof(*rd_ring);

    for(i=0;i < E1000_RDRING_SZ;i++,i++){
        if((pp = page_alloc(ALLOC_ZERO)) == 0)
            panic("page alloc error\n");
        pp->pp_ref = 1;
        pp_pa = page2pa(pp);

        rd_ring[i].addr = pp_pa;
        rd_ring[i].status = 0;
        rd_ring[i + 1].addr = pp_pa + PGSIZE / 2;
        rd_ring[i+1].status = 0;
      //  cprintf("td_ring[%d].addr = %x\n",i,td_ring[i].addr);
       // cprintf("td_ring[%d].addr = %x\n",i+1,td_ring[i+1].addr);
    }

    e1000bar0[E1000_RCTL / 4] = 0;
    e1000bar0[E1000_RCTL / 4] |= E1000_RCTL_EN | E1000_RCTL_LBM_NO | E1000_RCTL_RDMTS_HALF |
                        E1000_RCTL_SZ_2048 |E1000_RCTL_SECRC ;


}





int e1000_tx_packet(char * data,int length){

    struct tx_desc * desc_tial = &td_ring[e1000bar0[E1000_TDT / 4]];
    uint64_t addr;

    if(! desc_tial->status & E1000_TXD_STAT_DD)
        return -1;

    desc_tial->status &= ~E1000_TXD_STAT_DD;
    desc_tial->length = length;
    desc_tial->cmd |= E1000_TXD_CMD_RS | E1000_TXD_CMD_EOP;

    memmove(KADDR(desc_tial->addr),data,desc_tial->length);

    e1000bar0[E1000_TDT / 4] = (e1000bar0[E1000_TDT / 4] + 1) % E1000_TDRING_SZ;

    return 0;
}


int e1000_rx_packet(char * rdata,int *rlength){


    struct rx_desc * desc_tial = &rd_ring[(e1000bar0[E1000_RDT / 4] + 1) % E1000_RDRING_SZ ];


    if(! (desc_tial->status & E1000_RXD_STAT_DD) )
        return -1;

    if((*rlength=desc_tial->length) > E1000_PACKET_MAXSZ)
        panic("recieve packet whose size is bigger than e1000 max packer size that we have assume\n");
    user_mem_assert(curenv,(void*)rdata,*rlength,PTE_U |PTE_P |PTE_W);

    memmove(rdata,KADDR(desc_tial->addr),desc_tial->length);

   /* cprintf("recieve index:%x\n",(uint32_t)e1000bar0[E1000_RDT / 4]);
    hexdump("recieve in kernel:", (void *)KADDR( desc_tial->addr ), desc_tial->length);
    */

    e1000bar0[E1000_RDT / 4] = (e1000bar0[E1000_RDT / 4] + 1) % E1000_RDRING_SZ;
    desc_tial->status = 0;
    return 0;
}


static void
hexdump(const char *prefix, const void *data, int len)
{
	int i;
	char buf[80];
	char *end = buf + sizeof(buf);
	char *out = NULL;
	for (i = 0; i < len; i++) {
		if (i % 16 == 0)
			out = buf + snprintf(buf, end - buf,
					     "%s%04x   ", prefix, i);
		out += snprintf(out, end - out, "%02x", ((uint8_t*)data)[i]);
		if (i % 16 == 15 || i == len - 1)
			cprintf("%.*s\n", out - buf, buf);
		if (i % 2 == 1)
			*(out++) = ' ';
		if (i % 16 == 7)
			*(out++) = ' ';
	}
}
