/**
 * Module:  app_basic_bldc
 * Version: 1v1
 * Build:
 * File:    run_motor.h
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
#ifndef _RUN_MOTOR_H_
#define _RUN_MOTOR_H_

#include <xs1.h>
#include "watchdog.h"
#include "hall_input.h"
#include "pwm_cli.h"

#define INIT_PWM_VAL 	500
#define SEC 100000000
#define SPEED_COUNT 3000000000
#define STATE_LIMIT 250

/* run the motor using pwm on the high side and normal switching on the low side */
void run_motor1 ( chanend c_wd, chanend c_pwm, chanend c_control, port in p_hall, port out p_pwm_lo[]);
void run_motor2 ( chanend c_pwm2, chanend c_control2, port in p_hall2, port out p_pwm_lo2[]);

#endif /* _RUN_MOTOR_H_ */
