/*
 * Module:  module_dsc_comms
 * File:    control_comms_eth.h
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
#ifndef _CONTROL_COMMS_ETH_H_
#define _CONTROL_COMMS_ETH_H_
#include <dsc_config.h>


/** \brief Implement the high level Ethernet control server
 *
 * This control the motors based on commands from the ethernet/TCP stack
 *
 * \param c_commands Array of command channels for motors
 * \param tcp_svr channel to the TCP/IP thread
 */
void do_comms_eth( chanend c_commands[], chanend tcp_svr );


#endif /* _CONTROL_COMMS_ETH_H_ */
