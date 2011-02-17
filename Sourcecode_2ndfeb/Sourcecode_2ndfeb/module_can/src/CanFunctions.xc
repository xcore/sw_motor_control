/**
 * Module:  module_can
 * Version: 0v1alpha0
 * Build:   7b4ce104b91d882bdeb9db5c7d7dbf820c33e783
 * File:    CanFunctions.xc
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
#include <print.h>
#include <stdlib.h>
#include <xs1.h>

#include "CanIncludes.h"
#include "CanFunctions.h"

void printPacket(struct CanPacket &p) {
	printstr("SOF: ");
	printhexln(p.SOF);
	printstr("ID: ");
	printhexln(p.ID);
	if (p.IEB == 1) {
		printstr("SRR: ");
		printhexln(p.SRR);
		printstr("IEB: ");
		printhexln(p.IEB);
		printstr("EID: ");
		printhexln(p.EID);
		printstr("RTR: ");
		printhexln(p.RTR);
		printstr("RB1: ");
		printhexln(p.RB1);
	} else {
		printstr("RTR: ");
		printhexln(p.RTR);
		printstr("IEB: ");
		printhexln(p.IEB);
	}
	printstr("RB0: ");
	printhexln(p.RB0);
	printstr("DLC: ");
	printhexln(p.DLC);

	for (int i = 0; i < 8; i++) {
		printstr("DATA[");
		printint(i);
		printstr("]:");
		printhexln(p.DATA[i]);
	}
	printstr("CRC: ");
	printhexln(p.CRC);
	printstr("CRCdel: ");
	printhexln(p.CRC_DEL);
	printstr("ACKdel: ");
	printhexln(p.ACK_DEL);
	printstr("EOF: ");
	printhexln(p._EOF);
}

void initPacket(struct CanPacket &p) {
	p.SOF = 0;
	p.ID  = 0;
	p.SRR = 0;
	p.IEB = 0;
	p.EID = 0;
	p.RTR = 0;
	p.RB1 = 0;
	p.RB0 = 0;
	p.DLC = 0;
	for (int i = 0; i < 8; i++) {
		p.DATA[i] = 0;
	}
	p.CRC = 0;
	p.CRC_DEL = 1;
	p.ACK_DEL = 1;
	p._EOF = 0xf7;
}

void randomizePacket(struct CanPacket &p, int bitZero) {
	// Fields which are fixed unless injecting errors
	p.SOF = 0;
	p.RB0 = 0;
	p.CRC_DEL = 1;
	p.ACK_DEL = 1;
	p._EOF = 0x7F;

	p.ID  = rand() & 0x7ff;
	if (rand() & 0x1) {
		// Create extended packet
		p.SRR = 0;
		p.IEB = 1;
		p.EID = rand() & 0x3ffff;
		p.RTR = 0;
		p.RB1 = 0;

		p.EID = (p.EID & ~1) | bitZero;
	} else {
		// Create normal packet
		p.SRR = 0;
		p.IEB = 0;
		p.EID = 0;
		p.RTR = 0;
		p.RB1 = 0;

		p.ID = (p.ID & ~1) | bitZero;
	}

	p.DLC = rand() % 9;
	for (int i = 0; i < p.DLC; i++) {
		p.DATA[i] = rand() & 0xff;
	}

	// CRC is calculated by transmitter
	p.CRC = 0;
}

#pragma unsafe arrays
void sendPacket(chanend c, struct CanPacket &p) {
//	outuint(c, p.SOF);
	outuint(c, p.ID);
	outuint(c, p.SRR);
	outuint(c, p.IEB);
	outuint(c, p.EID);
	outuint(c, p.RTR);
//	outuint(c, p.RB1);
//	outuint(c, p.RB0);
	outuint(c, p.DLC);
	outuint(c, p.DATA[0]);
	outuint(c, p.DATA[1]);
	outuint(c, p.DATA[2]);
	outuint(c, p.DATA[3]);
	outuint(c, p.DATA[4]);
	outuint(c, p.DATA[5]);
	outuint(c, p.DATA[6]);
	outuint(c, p.DATA[7]);
//	outuint(c, p.CRC);
//	outuint(c, p.CRC_DEL);
//	outuint(c, p.ACK_DEL);
//	outuint(c, _EOF);
}

#pragma unsafe arrays
void receivePacket(chanend c, struct CanPacket &p) {
//	p.SOF = 0;
	p.ID  = inuint(c);
	p.SRR = inuint(c);
	p.IEB = inuint(c);
	p.EID = inuint(c);
	p.RTR = inuint(c);
//	p.RB1 = 0;
//	p.RB0 = 0;
	p.DLC = inuint(c);
	p.DATA[0] = inuint(c);
	p.DATA[1] = inuint(c);
	p.DATA[2] = inuint(c);
	p.DATA[3] = inuint(c);
	p.DATA[4] = inuint(c);
	p.DATA[5] = inuint(c);
	p.DATA[6] = inuint(c);
	p.DATA[7] = inuint(c);
//	p.CRC = 0;
//	p.CRC_DEL = 1;
//	p.ACK_DEL = 1;
//	p._EOF = 0x7f;
}

// Needing to be in a different file due to BUG 8295
void rxReady(buffered in port:32 p, unsigned int &time) {
}
