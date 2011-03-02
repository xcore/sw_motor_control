/**
 * Module:  module_can
 * Version: 0v1alpha0
 * Build:   7b4ce104b91d882bdeb9db5c7d7dbf820c33e783
 * File:    CanCFunctions.c
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

#include "CanIncludes.h"

extern int alignTable[];

void initAlignTable() {
	int aligned = QUANTA_TOTAL - QUANTA_PHASE2;

	for (int zeros = 0; zeros < 33; zeros++) {
		alignTable[zeros] = QUANTA_TOTAL;
	}

	for (int zeros = 1; zeros < 32; zeros++) {
		if (zeros < aligned) {
			// Edge is late, in the propagation delay segment need to extend the bit time
			int phaseError = aligned - zeros;
			if (phaseError <= QUANTA_SJW) {
				// Maximum compensation allowed by spec
				alignTable[zeros] = QUANTA_TOTAL + phaseError;
			}
		} else if (zeros > aligned) {
			// Edge is early, in the propagation delay segment need to reduce the bit time
			int phaseError = zeros - aligned;
			if (phaseError <= QUANTA_SJW) {
				// Maximum compensate allowed by spec
				alignTable[zeros] = QUANTA_TOTAL - phaseError;
			}
		}
	}

	/*
	 * Used when starting the RX state machine in order to align to the sample time
	 * in one instruction
	 */
	alignTable[33] = QUANTA_TOTAL - QUANTA_PHASE2;
}
