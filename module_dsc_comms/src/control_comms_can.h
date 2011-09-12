/*
 * Module:  module_dsc_comms
 * File:    control_comms_can.h
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
 */

#ifndef _CONTROL_COMMS_CAN_H_
#define _CONTROL_COMMS_CAN_H_
#include <dsc_config.h>

/**
 *  \brief This is a thread which performs the higher level control for the CAN interface.
 *
 *  Use it in conjunction with the thread 'canPhyRxTx' from the module module_can.
 *
 *  \param c_commands Channel array for interfacing to the motors
 *  \param rxChan Connect to the rxChan port on the canPhyRxTx
 *  \param txChan Connect to the txChan port on the canPhyRxTx
 */
void do_comms_can( chanend c_commands[], chanend rxChan, chanend txChan);

#endif /* _CONTROL_COMMS_CAN_H_ */

