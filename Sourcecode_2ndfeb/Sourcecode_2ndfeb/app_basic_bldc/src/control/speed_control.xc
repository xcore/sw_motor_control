/**
 * Module:  app_basic_bldc
 * Version: 1v0alpha1
 * Build:   d6f1b08bc373431180841b062ab3e165ce3c38f7
 * File:    speed_control.xc
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
#include <xs1.h>

#include "dsc_config.h"
#include "shared_io.h"
#include "pid_regulator.h"

void speed_control(chanend c_control, chanend c_lcd, chanend c_ethernet )
{
	timer t;
	unsigned ts;

	unsigned set_speed = 500;
	unsigned speed = 0;
	int pwm = 0, calced_pwm = 0;
	unsigned uPwm = 0;
	unsigned temp;
	unsigned cmd;

	unsigned startup = 1;

	pid_data pid;

	// speed loop settings
	// {10*32768, 200, 0} => CD load
	// {1*32768, 200, 0} => Motor with no load

	int Kp=1*8000, Ki=40, Kd=40;
	init_pid( Kp, Ki, Kd, pid );

	t :> ts;

	while (startup < 2000)
	{
		c_control <: 2;
		c_control <: 200;
		startup++;
		t when timerafter (ts + 100000) :> ts;
	}

	while (1)
	{
		#pragma ordered
		select
		{
		case t when timerafter (ts + 100000) :> ts:
			c_control <: 1;
			c_control :> speed;

			/* 304 rpm/V - assume 24V maps to PWM_MAX_VALUE */
			calced_pwm =  (set_speed * PWM_MAX_VALUE) / (304*24);

			pwm = calced_pwm + pid_regulator_delta_cust_error((int)(set_speed - speed), pid );

			if (pwm > 4000)
				pwm = 4000;
			if (pwm < 50)
				pwm = 50;

			uPwm = (unsigned)pwm;

			c_control <: 2;
			c_control <: uPwm;
			break;

		case c_lcd :> cmd: /* Process a command received from the display */
			if (cmd == CMD_GET_IQ)
			{
				c_lcd <: speed;
				c_lcd <: set_speed;
				c_lcd <: pwm;
			}
			else if (cmd == CMD_SET_SPEED)
			{
				c_lcd :> set_speed;
			}
			else if(cmd == CMD_DIR)
			{
				c_lcd :> temp;
				c_control <: 4;

				c_control <: temp ;

			}
			break;

		case c_ethernet :> cmd: /* Process a command received from the Ethernet */
			if (cmd == CMD_GET_VALS)
			{
				c_ethernet <: speed;
				c_ethernet <: set_speed;
			}
			else if (cmd == CMD_SET_SPEED)
			{
				c_ethernet :> set_speed;
			}
			else
			{
				// Ignore invalid command
			}

			break;
		}
	}
}
