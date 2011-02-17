/**
 * Module:  app_basic_bldc
 * Version: 1v0alpha1
 * Build:   607e2782d91b59f267e6a192021cc1ccca2e67f9
 * File:    run_motor.h
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
#ifndef RUN_MOTOR_H_
#define RUN_MOTOR_H_

#include <xs1.h>
#include "watchdog.h"
#include "hall_input.h"
#include "pwm_cli.h"

#define INIT_PWM_VAL 	500

/* run the motor using pwm on the high side and normal switching on the low side */
void run_motor ( chanend c_wd, chanend c_pwm, chanend c_control, port in p_hall, port out p_pwm_lo[]);

#endif /* RUN_MOTOR_H_ */
