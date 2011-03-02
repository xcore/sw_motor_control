/**
 * Module:  module_can
 * Version: 0v1alpha1
 * Build:   b9ffd761ba594efadb3239e27317d8b1245851ac
 * File:    CanIncludes.h
 *
 * The copyrights, all other intellectual and industrial 
 * property rights are retained by XMOS and/or its licensors. 
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2010
 *
 * In the case where this code is a modification of existing code
 * under a separate license, the separate license terms are shown
 * below. The modifications to the code are still covered by the 
 * copyright notice above.
 *
 **/                                   
#ifndef _CAN_INCLUDES
#define _CAN_INCLUDES

//#define DEBUG

/*
 * Assuming 25 time quanta then the following baud rates are avaliable.
 * If the time quanta are changed then you will need to ensure that the
 * CLOCK_DIV is still a integer
 *
 * BAUD_RATE  CLOCK_DIV
 * 1000000      2
 *  500000      4
 *  400000      5
 *  250000      8
 *  200000     10
 *  125000     16
 *  100000     20
 *  80000      25
 *  62500      32
 *  50000      40
 *  40000      50
 *  31250      64
 *  25000      80
 *  20000     100
 *  16000     125
 *  15625     128
 *  12500     160
 *  10000     200
 *  8000      250
 *  7813      256
 *  5000      400
 */

#define SYSTEM_CLOCK 100000000
#define BAUD_RATE      500000 // 1000000

#define QUANTA_SYNC      1
#define QUANTA_PROP      8
#define QUANTA_PHASE1    8
#define QUANTA_PHASE2    8
#define QUANTA_SJW       4
#define QUANTA_TOTAL    (QUANTA_SYNC + QUANTA_PROP + QUANTA_PHASE1 + QUANTA_PHASE2)
#define CLOCK_DIV       (SYSTEM_CLOCK / (BAUD_RATE * QUANTA_TOTAL * 2))

typedef enum {
	STATE_SOF          =  0,
	STATE_ID           =  1,
	STATE_SRR          =  2,
	STATE_IEB          =  3,
	STATE_EID          =  4,
	STATE_RTR          =  5,
	STATE_RB1          =  6,
	STATE_RB0          =  7,
	STATE_DLC          =  8,
	STATE_DATA_BIT7    =  9,
	STATE_DATA_BIT6    = 10,
	STATE_DATA_BIT5    = 11,
	STATE_DATA_BIT4    = 12,
	STATE_DATA_BIT3    = 13,
	STATE_DATA_BIT2    = 14,
	STATE_DATA_BIT1    = 15,
	STATE_DATA_BIT0    = 16,
	STATE_CRC          = 17,
	STATE_CRC_DEL      = 18,
	STATE_ACK          = 19,
	STATE_ACK_DEL      = 20,
	STATE_EOF          = 21,
	STATE_INTERMISSION = 22,
	STATE_OVERLOAD     = 23,
	STATE_OVERLOAD_DEL = 24,
	STATE_BUS_IDLE     = 25,

} STATE;

typedef enum {
	ERROR_NONE          = 0,
	ERROR_BIT_ERROR     = 1,
	ERROR_STUFF_ERROR   = 2,
	ERROR_FORM_ERROR    = 3,
	ERROR_CRC_ERROR     = 4,
	ERROR_ILLEGAL_STATE = 5,
	ERROR_NO_ACK        = 6,
} ERROR;

struct CanPacket {
	unsigned DATA[8]; // First in struct so that worst-case path is quicker

	unsigned SOF;
	unsigned ID;
	unsigned SRR;
	unsigned IEB;
	unsigned EID;
	unsigned RTR;
	unsigned RB1;
	unsigned RB0;
	unsigned DLC;
	unsigned CRC;
	unsigned CRC_DEL;
	unsigned ACK_DEL;
	unsigned _EOF; /* Uses _ because EOF is reserved */
};

struct CanPhyState {
	STATE        state;
	ERROR        error;
	unsigned int packetCrc;

	int          txActive;
	int          txComplete;

	int          activeError;
	int          rxErrorCount;
	int          txErrorCount;
	int          doCrc;
};

#endif
