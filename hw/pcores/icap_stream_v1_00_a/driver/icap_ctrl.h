#include "xdevcfg.h"
#include "xaxidma.h"
#include "xparameters.h"
#include <stdio.h>
#include "xparameters.h"
#include "xil_printf.h"
#include "xil_io.h"
#include <stdlib.h>
#include "xscugic.h"
#include "ff.h"
#define MAX_BS_NUM 5
#define BS1_ADDR 0x200000
#define BS2_ADDR 0x300000
#define BS3_ADDR 0x400000
#define BS4_ADDR 0x500000
#define BS5_ADDR 0x600000

typedef struct bit_info{
        char name[128];
        int  size;
        int  addr;
        struct bit_info *prev;
        struct bit_info *next;
} bs_info;

#define TX_INTR_ID		XPAR_FABRIC_ICAP_STREAM_0_ICAP_INTR_OUT_INTR

#define XPAR_XAXIDMA_NUM_INSTANCES 1
/* Definitions for peripheral AXI_DMA_0 */
#define XPAR_AXI_DMA_0_DEVICE_ID 0
#define XPAR_AXI_DMA_0_BASEADDR XPAR_ICAP_STREAM_0_BASEADDR
#define XPAR_AXI_DMA_0_HIGHADDR XPAR_ICAP_STREAM_0_HIGHADDR
#define XPAR_AXI_DMA_0_SG_INCLUDE_STSCNTRL_STRM 0
#define XPAR_AXI_DMA_0_INCLUDE_MM2S_DRE 0
#define XPAR_AXI_DMA_0_INCLUDE_S2MM_DRE 0
#define XPAR_AXI_DMA_0_INCLUDE_MM2S 1
#define XPAR_AXI_DMA_0_INCLUDE_S2MM 0
#define XPAR_AXI_DMA_0_M_AXI_MM2S_DATA_WIDTH 32
#define XPAR_AXI_DMA_0_M_AXI_S2MM_DATA_WIDTH 32
#define XPAR_AXI_DMA_0_INCLUDE_SG 0
#define XPAR_AXI_DMA_0_ENABLE_MULTI_CHANNEL 0
#define XPAR_AXI_DMA_0_NUM_MM2S_CHANNELS 1
#define XPAR_AXI_DMA_0_NUM_S2MM_CHANNELS 0


/******************************************************************/

/* Canonical definitions for peripheral AXI_DMA_0 */
#define XPAR_AXIDMA_0_DEVICE_ID XPAR_AXI_DMA_0_DEVICE_ID
#define XPAR_AXIDMA_0_BASEADDR 0x6AC00000
#define XPAR_AXIDMA_0_SG_INCLUDE_STSCNTRL_STRM 0
#define XPAR_AXIDMA_0_INCLUDE_MM2S 1
#define XPAR_AXIDMA_0_INCLUDE_MM2S_DRE 0
#define XPAR_AXIDMA_0_M_AXI_MM2S_DATA_WIDTH 32
#define XPAR_AXIDMA_0_INCLUDE_S2MM 0
#define XPAR_AXIDMA_0_INCLUDE_S2MM_DRE 0
#define XPAR_AXIDMA_0_M_AXI_S2MM_DATA_WIDTH 32
#define XPAR_AXIDMA_0_INCLUDE_SG 0
#define XPAR_AXIDMA_0_ENABLE_MULTI_CHANNEL 0
#define XPAR_AXIDMA_0_NUM_MM2S_CHANNELS 1
#define XPAR_AXIDMA_0_NUM_S2MM_CHANNELS 0


/* Definitions for Fabric interrupts connected to ps7_scugic_0 */
#define XPAR_FABRIC_AXI_DMA_0_MM2S_INTROUT_INTR XPAR_FABRIC_ICAP_STREAM_0_MM2S_INTROUT_INTR
#define XPAR_FABRIC_AXI_DMA_0_S2MM_INTROUT_INTR 90

/******************************************************************/

/* Canonical definitions for Fabric interrupts connected to ps7_scugic_0 */
#define XPAR_FABRIC_AXIDMA_0_MM2S_INTROUT_VEC_ID XPAR_FABRIC_AXI_DMA_0_MM2S_INTROUT_INTR
#define XPAR_FABRIC_AXIDMA_0_S2MM_INTROUT_VEC_ID XPAR_FABRIC_AXI_DMA_0_S2MM_INTROUT_INTR

/******************************************************************/

#define RESET_TIMEOUT_COUNTER	10000

#define XDCFG_CTRL_ICAP_PR_MASK	  	0xF7FFFFFF /**< Disable PCAP for PR */

/* Flags interrupt handlers use to notify the application context the events.
*/
volatile int TxDone;
volatile int RxDone;
volatile int Error;

int Init_Icap_Ctrl(XScuGic * InterruptController);
int Config_PR_Bitstream(char *bs_name);
int Prefetch_PR_Bitstream(char *bs_name);
