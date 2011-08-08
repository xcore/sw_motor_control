/**
 * Module:  module_dsc_display
 * Version: 1v0module_dsc_display3
 * Build:
 * File:    shared_io.h
 * Modified by : Srikanth
 * Last Modified on : 27-May-2011
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
#include <dsc_config.h>

#ifdef __XC__
	/** \brief The control structure for the LCD ports
	*/
	typedef struct lcd_interface_t
	{
		out port p_lcd_sclk; // buffered port:8
		out port p_lcd_mosi; // buffered port:8
		out port p_lcd_cs_n;
		out port p_core1_shared;
	} lcd_interface_t;
#endif

	// Individual command interfaces
#ifdef BLDC_BASIC

	#define CMD_GET_VALS	1
	#define CMD_GET_IQ		2
	#define CMD_SET_SPEED	3
    #define CMD_DIR         4
	#define CMD_GET_IQ2		5
	#define CMD_SET_SPEED2	6
	#define CMD_DIR2        7
	#define STEP_SPEED 		50
	#define _30_Msec		2000000
	#define _Msec_2_		50000
	#define MSec 			100000
	#define CAN_RS_LO		2

	#ifdef __XC__
		void display_shared_io_motor( chanend c_lcd1, chanend c_lcd2, REFERENCE_PARAM(lcd_interface_t, p), in port btns,chanend c_can_reset,out port p_shared_rs,chanend c_eth_command );
	#endif
#endif

#ifdef BLDC_FOC

	#define ETH_RST_HI 		0
	#define ETH_RST_LO		1
	#define CAN_RS_LO		2
	#define	CMD_DIR			10

	#define CMD_GET_VALS	1
	#define CMD_GET_IQ		2
	#define CMD_SET_SPEED	3
    #define CMD_GET_VALS2	4

	#ifdef __XC__
		void display_shared_io_manager( chanend c_speed, REFERENCE_PARAM(lcd_interface_t, p), in port btns,chanend c_can_command,out port p_shared_rs,chanend c_eth_command);
	#endif
#endif

#endif /* SHARED_IO_H_ */
