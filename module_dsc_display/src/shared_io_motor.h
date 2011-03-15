/**
 * Module:  module_dsc_display
 * Version: 1v0module_dsc_display3
 * Build:
 * File:    shared_io_motor.h
 * Author: 	L & T
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
#ifndef SHARED_IO_MOTOR_H_
#define SHARED_IO_MOTOR_H_

#include <xccompat.h>

// Individual command interfaces

#define CMD_GET_VALS		1
#define CMD_GET_IQ		2
#define CMD_SET_SPEED		3
#define CMD_DIR         	4
#define CMD_GET_IQ2		5
#define CMD_SET_SPEED2		6
#define CMD_DIR2        	7
#define STEP_SPEED 		50
#define _30_Msec		3000000
#define MSec 100000

#ifdef __XC__
typedef struct lcd_interface_t
{
	out port p_lcd_sclk; // buffered port:8
	out port p_lcd_mosi; // buffered port:8
	out port p_lcd_cs_n;
	out port p_core1_shared;
} lcd_interface_t;


/**
 *  \brief The general IO controller and processor
 *
 *  \param c_lcd1
 *  \param c_lcd2
 *  \param p the LCD interface port structure
 *  \param btns an array of 1 bit button ports
 *  \param ctrl a control channel (or null)
 *  \param c_eth_reset input saying when the ethernet module has reset
 *  \param c_can_reset input saying when the CAN module has reset
 */
void display_shared_io_motor( chanend c_lcd1, chanend c_lcd2, REFERENCE_PARAM(lcd_interface_t, p), in port btns[], chanend? ctrli, chanend? c_eth_reset, chanend? c_can_reset);
#endif

#endif /* SHARED_IO_MOTOR_H_ */
