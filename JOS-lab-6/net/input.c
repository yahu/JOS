#include "ns.h"
#include <inc/x86.h>
#define debug 0

extern union Nsipc nsipcbuf;

static void
delay(void)
{
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
void
input(envid_t ns_envid)
{
	binaryname = "ns_input";

	// LAB 6: Your code here:
	// 	- read a packet from the device driver
	//	- send it to the network server
	// Hint: When you IPC a page to the network server, it will be
	// reading from it for a while, so don't immediately receive
	// another packet in to the same physical page.

	int perm, r;

	while (1) {

        nsipcbuf.pkt.jp_len = 0;

        sys_rx_packet(nsipcbuf.pkt.jp_data, &nsipcbuf.pkt.jp_len);
		ipc_send(ns_envid,NSREQ_INPUT,(void *)&nsipcbuf,PTE_P | PTE_U | PTE_W);

		/*delay();*/
		sys_yield();
		sys_yield();
		sys_yield();
        }

}
