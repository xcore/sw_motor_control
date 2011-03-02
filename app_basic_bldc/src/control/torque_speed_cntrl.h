/**
 * Module:  app_basic_bldc
 * Version: 1v1
 * Build:
 * File:    torque_speed_cntrl.h
 * Author: 	Srikanth
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
#ifndef __TORQUE_SPEED_CONTROL_H__
#define __TORQUE_SPEED_CONTROL_H__

void torque_speed_control1(chanend c_control, chanend c_lcd,  chanend c_adc );
void torque_speed_control2(chanend c_control2, chanend c_lcd2, chanend c_adc2 );

#endif
