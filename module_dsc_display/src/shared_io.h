/**
 * Module:  module_dsc_display
 * Version: 1v0module_dsc_display3
 * File:    shared_io.h
 * Modified by : A Srikanth
 * Last Modified on : 05-Aug-2011
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

	/* Individual command interfaces */

	#define CMD_GET_VALS	1
	#define CMD_GET_IQ		2
	#define CMD_SET_SPEED	3
    #define CMD_DIR         4
	#define CMD_GET_IQ_2	5
	#define CMD_SET_SPEED_2	6
	#define CMD_DIR_2       7
	#define STEP_SPEED 		50
	#define MSEC_30			2000000
	#define MSEC_BY_2		50000
	#define MSEC 			100000
	#define CAN_RS_LO		2
	#define BUTTON_MASK		0x0000000F

	#define ETH_RST_HI 		0
	#define ETH_RST_LO		1
	#define CMD_GET_VALS_2	4
    #define GUI_ENABLED     1

	#ifdef __XC__
		typedef struct lcd_interface_t
		{
			out port p_lcd_sclk; /* buffered port:8 */
			out port p_lcd_mosi; /* buffered port:8 */
			out port p_lcd_cs_n;
			out port p_core1_shared;
		} lcd_interface_t;

		void display_shared_io_motor( chanend c_lcd1, chanend c_lcd2, REFERENCE_PARAM(lcd_interface_t, p), in port btns,chanend c_can_reset,out port p_shared_rs,chanend c_eth_command,chanend c_gui_en);
	#endif

#endif /* SHARED_IO_H_ */
