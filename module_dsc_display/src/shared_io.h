/**
 * Module:  module_dsc_display
 *
 * The copyrights, all other intellectual and industrial 
 * property rights are retained by XMOS and/or its licensors. 
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2011
 *
 * In the case where this code is a modification of existing code
 * under a separate license, the separate license terms are shown
 * below. The modifications to the code are still covered by the 
 * copyright notice above.
 *
 **/                                   
#ifndef SHARED_IO_H_
#define SHARED_IO_H_

#include <xccompat.h>
#include "lcd.h"

// Individual command interfaces

#define CMD_GET_VALS	1
#define CMD_GET_IQ		2
#define CMD_SET_SPEED	3
#define CMD_DIR         4
#define CMD_GET_VALS2	5
#define CMD_GET_FAULT   6

#define STEP_SPEED 		50
#define _30_Msec		2000000
#define _Msec_2_		50000
#define MSec 			100000

#define ETH_RST_HI 		0
#define ETH_RST_LO		1
#define CAN_RS_LO		2


#ifdef __XC__
	void display_shared_io_manager( chanend c_speed[], REFERENCE_PARAM(lcd_interface_t, p), in port btns, out port leds);
#endif

#endif /* SHARED_IO_H_ */
