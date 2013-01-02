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

#define QEI_PER_POLE (QEI_COUNT_MAX / NUM_POLE_PAIRS) // e.g. 256 No. of QEI sensors per pole 
#define THETA_HALF_PHASE (QEI_PER_POLE / 12) // e.g. ~21 CoilSectorAngle/2 (6 sectors = 60 degrees per sector, 30 degrees per half sector)


/* run the motor inner loop */
void run_motor ( unsigned motor_id ,chanend? c_wd ,chanend c_pwm ,streaming chanend c_qei 
	,streaming chanend c_adc ,chanend c_speed ,port in p_hall ,chanend c_can_eth_shared );

#endif /* _INNER_LOOP_H_ */
