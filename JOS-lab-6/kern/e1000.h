#ifndef JOS_KERN_E1000_H
#define JOS_KERN_E1000_H

#include <inc/types.h>
#include <kern/pci.h>

#define E1000_TDRING_SZ     32
#define E1000_RDRING_SZ     48
#define E1000_PACKET_MAXSZ  1518 //maximum size of an Ethernet packet is 1518 bytes

/* Transmit Control */
#define E1000_TCTL     0x00400
    #define E1000_TCTL_RST    0x00000001    /* software reset */
    #define E1000_TCTL_EN     0x00000002    /* enable tx */
    #define E1000_TCTL_BCE    0x00000004    /* busy check enable */
    #define E1000_TCTL_PSP    0x00000008    /* pad short packets */
    #define E1000_TCTL_CT     0x00000ff0    /* collision threshold */
        #define E1000_TCTL_CT_OFFSET 4
    #define E1000_TCTL_COLD   0x003ff000    /* collision distance */
        #define E1000_TCTL_COLD_OFFSET 12

#define E1000_TIPG     0x00410  /*Transmit IPG*/
    #define E1000_TIPG_OFFSET   0
    #define E1000_TIPG1_OFFSET  10
    #define E1000_TIPG2_OFFSET  20

#define E1000_TDBAL    0x03800  /* TX Descriptor Base Address Low - RW */
#define E1000_TDBAH    0x03804  /* TX Descriptor Base Address High - RW */
#define E1000_TDLEN    0x03808  /* TX Descriptor Length - RW */
#define E1000_TDH      0x03810  /* TX Descriptor Head - RW */
#define E1000_TDT      0x03818  /* TX Descripotr Tail - RW */

#define E1000_TXD_CMD_EOP    0x01/* End of Packet */
#define E1000_TXD_CMD_RS     0x08 /* Report Status */

#define E1000_TXD_STAT_DD    0x01 /* Descriptor Done */

#define E1000_RAL      0X05400      /*store low 32 bit address of MAC */
#define E1000_RAH      0X05404      /*store high 16 bit address of MAC ,and some arribute bits */
    #define E1000_RAH_AV    0X80000000  /* Recieve Address valid*/

#define E1000_MTA      0x05200
    #define E1000_MTA_SZ 128

#define E1000_IMS      0x000D0  /* Interrupt Mask Set - RW */



#define E1000_RDBAL    0x02800  /* RX Descriptor Base Address Low - RW */
#define E1000_RDBAH    0x02804  /* RX Descriptor Base Address High - RW */
#define E1000_RDLEN    0x02808  /* RX Descriptor Length - RW */
#define E1000_RDH      0x02810  /* RX Descriptor Head - RW */
#define E1000_RDT      0x02818  /* RX Descriptor Tail - RW */

/* Receive Status */
#define E1000_RXD_STAT_DD       0x01    /* Descriptor Done */
#define E1000_RXD_STAT_EOP      0x02    /* End of Packet */

/* Receive Control */
#define E1000_RCTL              0x00100
    #define E1000_RCTL_EN             0x00000002    /* enable */
    #define E1000_RCTL_MPE            0x00000010    /* multicast promiscuous enab */
    #define E1000_RCTL_LPE            0x00000020    /* long packet enable */
    #define E1000_RCTL_LBM_NO         0x00000000    /* no loopback mode */
    #define E1000_RCTL_RDMTS_HALF     0x00000000    /* rx desc min threshold size */
    #define E1000_RCTL_RDMTS_QUAT     0x00000100    /* rx desc min threshold size */
    #define E1000_RCTL_RDMTS_EIGTH    0x00000200    /* rx desc min threshold size */
    #define E1000_RCTL_MO_SHIFT       12            /* multicast offset shift */
    #define E1000_RCTL_MO_0           0x00000000    /* multicast offset 11:0 */
    #define E1000_RCTL_MO_1           0x00001000    /* multicast offset 12:1 */
    #define E1000_RCTL_MO_2           0x00002000    /* multicast offset 13:2 */
    #define E1000_RCTL_MO_3           0x00003000    /* multicast offset 15:4 */
    #define E1000_RCTL_BAM            0x00008000    /* broadcast enable */
    #define E1000_RCTL_SZ_2048        0x00000000    /* rx buffer size 2048 */
    #define E1000_RCTL_BSEX           0x02000000    /* Buffer size extension */
    #define E1000_RCTL_SECRC          0x04000000    /* Strip Ethernet CRC */


struct tx_desc
{
	uint64_t addr;
	uint16_t length;
	uint8_t cso;
	uint8_t cmd;
	uint8_t status;
	uint8_t css;
	uint16_t special;
};

struct rx_desc
{
	uint64_t addr;
	uint16_t length;
	uint16_t csum;
	uint8_t status;
	uint8_t errors;
	uint16_t special;
};


int
e1000_pic_attach(struct pci_func *pcif);

void e1000_init_tx();
void e1000_init_rx();

int
e1000_tx_packet(char * data,int length);

int
e1000_rx_packet(char * data,int *length);


#endif	// JOS_KERN_E1000_H
