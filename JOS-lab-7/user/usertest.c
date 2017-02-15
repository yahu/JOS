
#include <inc/lib.h>

void
umain(int argc, char **argv)
{
    char data[50] = "hello world\n";
    sys_tx_packet(data,50);

}

