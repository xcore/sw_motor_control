/**
 * Module:  app_basic_bldc
 * Version: 1v1
 * Build:
 * File:    torque_cntrl_run_motor.h
 * Author: 	Srikanth
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
#ifndef TORQUE_CNTRL_RUN_MOTOR_H_
#define TORQUE_CNTRL_RUN_MOTOR_H_

#include <xs1.h>
#include "watchdog.h"
#include "hall_input.h"
#include "pwm_cli.h"

#define INIT_PWM_VAL 	500

/* run the motor using pwm on the high side and normal switching on the low side */
void torque_cotrolled_run_motor1 ( chanend c_wd, chanend c_pwm, chanend c_control, port in p_hall, port out p_pwm_lo[]);
void torque_cotrolled_run_motor2 ( chanend c_pwm2, chanend c_control2, port in p_hall2, port out p_pwm_lo2[]);

#endif /* TORQUE_CNTRL_RUN_MOTOR_H_ */
