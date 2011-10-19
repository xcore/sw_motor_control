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
#include "pwm_cli_inv.h"

#define INIT_PWM_VAL 	500
#define SEC 100000000
#define SPEED_COUNT 1500000000
#define STATE_LIMIT 250
#define MAX_LIMIT 10
#define MAX_ROT 60000
#define MAX_RUN 59000
#define CHECK_LIMIT 30000
#define CHECK_LIMIT1 30010
#define QEI_COUNT1 0
#define QEI_COUNT2 1024
#define ADC_COUNT1 2000
#define ADC_COUNT2 3000

/* run the motor using pwm on the high side and normal switching on the low side */
void run_motor( chanend? c_wd, chanend? c_ctrl_in, chanend? c_ctrl_out, chanend c_pwm, chanend c_adc, streaming chanend c_qei, port in p_hall);

#endif /* _RUN_MOTOR_H_ */
