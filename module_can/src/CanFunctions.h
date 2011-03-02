/**
 * Module:  module_can
 * Version: 0v1alpha0
 * Build:   7b4ce104b91d882bdeb9db5c7d7dbf820c33e783
 * File:    CanFunctions.h
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
#ifndef _CAN_FUNCTIONS
#define _CAN_FUNCTIONS

#ifdef __XC__

void printPacket(struct CanPacket &p);
void initPacket(struct CanPacket &p);
void randomizePacket(struct CanPacket &p, int bitZero);
void sendPacket(chanend c, struct CanPacket &p);
void receivePacket(chanend c, struct CanPacket &p);

#pragma select handler
void rxReady(buffered in port:32 p, unsigned int &time);

#endif

#endif
