#include "ns.h"

#define debug 0
extern union Nsipc nsipcbuf;

void
output(envid_t ns_envid)
{
	binaryname = "ns_output";

	// LAB 6: Your code here:
	// 	- read a packet from the network server
	//	- send the packet to the device driver
	uint32_t req, whom;
	int perm, r;


	while (1) {

		perm = 0;
		req = ipc_recv((int32_t *) &whom, (void *) &nsipcbuf, &perm);

		if (debug)
			cprintf("req %d from %08x [page %08x: %x]\n",
				req, whom, vpt[PGNUM(&nsipcbuf)], (uint32_t)&nsipcbuf);

		// All requests must contain an argument page
		if (!(perm & PTE_P)) {
			cprintf("Invalid request from %08x: no argument page\n",
				whom);
			continue; // just leave it hanging...
		}

		if(whom != ns_envid || req != NSREQ_OUTPUT)
            goto unmap;

        while(sys_tx_packet(nsipcbuf.pkt.jp_data,nsipcbuf.pkt.jp_len) < 0){
            cprintf("transmit packet fail,try again\n");
            sys_yield();
        }


	//ipc_send(whom, r, pg, perm);
unmap:
        sys_page_unmap(0, (void*)&nsipcbuf);
	}
}
