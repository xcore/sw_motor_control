/**
 * File:    inner_loop.h
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
#ifndef _INNER_LOOP_H_
#define _INNER_LOOP_H_

/* run the motor inner loop */
void run_motor ( unsigned motor_id ,chanend? c_wd ,chanend c_pwm ,streaming chanend c_hall 
	,streaming chanend c_qei ,streaming chanend c_adc ,chanend c_speed ,chanend c_can_eth_shared );

#endif /* _INNER_LOOP_H_ */
