/**
 * Module:  app_dsc_demo
 * Version: 1v0alpha1
 * Build:   60a90cca6296c0154ccc44e1375cc3966292f74e
 * File:    outer_loop.h
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
#ifndef _OUTER_LOOP_H_
#define _OUTER_LOOP_H_

void speed_control_loop( chanend c_wd, chanend c_speed, chanend c_control_out, chanend c_command_can, chanend c_command_eth, chanend c_display, chanend ?c_logging );

#endif /* _OUTER_LOOP_H_ */
