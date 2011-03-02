/**
 * Module:  module_dsc_comms
 * Version: 1v0alpha0
 * Build:   8234dc1c93e3702c697f99474a8ca1e7d28a61cc
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
 **/                                   
#ifndef _CONTROL_COMMS_CAN_H_
#define _CONTROL_COMMS_CAN_H_

void do_comms_can( chanend c_speed, chanend rxChan, chanend txChan, chanend c_control_can );

#endif /* _CONTROL_COMMS_CAN_H_ */
