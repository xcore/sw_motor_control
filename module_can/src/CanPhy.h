/**
 * Module:  module_can
 * Version: 0v1alpha0
 * Build:   7b4ce104b91d882bdeb9db5c7d7dbf820c33e783
 * File:    CanPhy.h
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
#ifndef _CAN_PHY
#define _CAN_PHY

#ifdef __XC__

/**
 *  \brief This is the thread for the CAN Phy support
 *
 *  \param rxChan for data that has been received from the CAN bus
 *  \param txChan for data to transmit on the CAN bus
 *  \clk the transmission clock
 *  \canRx the receive port pins
 *  \panTx the transmit port pins
 */
void canPhyRxTx(chanend rxChan, chanend txChan, clock clk, buffered in port:32 canRx, port canTx);
#endif

#endif
