/**
 * Module:  app_basic_bldc
 * Version: 1v1
 * Build:
 * File:    speed_cntrl.h
 * Author: 	L & T
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
#ifndef ___SPEED_CONTROL_H__
#define ___SPEED_CONTROL_H__

void speed_control(chanend c_control, chanend c_lcd,chanend c_commands_can );

#endif
