/**
 * Module:  app_basic_bldc
 * Version: 1v1
 * Build:
 * File:    speed_cntrl.xc
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

#include <xs1.h>
#include "dsc_config.h"
#include "shared_io.h"
#include "pid_regulator.h"

#ifdef USE_XSCOPE
#include <xscope.h>
#endif

/* speed loop settings*/
static int Kp=1*8000, Ki=40, Kd=0;

/* speed_control1() function updates pwm value based on pid regulator values
 * and sends the updated values to other threads using channels for motor 1*/
void speed_control1(chanend c_control, chanend c_lcd )
{
	unsigned ts, set_speed = 500, speed = 0, uPwm = 0, temp, cmd, startup = 1 ;
	int pwm = 0, calced_pwm = 0 ;
	/* 32 bit timer declaration */
	timer t;
	/* pid variables */
	pid_data pid ;
	/* initialise PID settings */
	init_pid( Kp, Ki, Kd, pid );
	/* taking current timer value */
	t :> ts;

	/* motor wakeup function */
	while (startup < 2000)
	{
		c_control <: 2;
		c_control <: 200;
		startup++;
	/* delay function for 1ms */
		t when timerafter (ts + MSec) :> ts;
	}

	/*main loop for speed control */
	while (1)
	{
		#pragma ordered
		select
		{
		/* updates control parameters for every 1 ms */
		case t when timerafter (ts + MSec) :> ts:
		/* to get updated speed value from runmotor function */
			c_control <: 1;
			c_control :> speed;

		/* 304 rpm/V - assume 24V maps to PWM_MAX_VALUE */
			calced_pwm =  (set_speed * PWM_MAX_VALUE) / (304*24);

		/* Updating pwm as per speed feedback and speed reference */
			pwm = calced_pwm  + pid_regulator_delta_cust_error((int)(set_speed - speed), pid );
		/* Maximum and Minimum PWM limits */

			if (pwm > 4000)
				pwm = 4000;
			if (pwm < 50)
				pwm = 50;

			uPwm = (unsigned)pwm;
			c_control <: 2;
			c_control <: uPwm;
#ifdef USE_XSCOPE
			xscope_probe_data(0, uPwm);
#endif
			break;

		case c_lcd :> cmd: /* Process a command received from the display */
			if (cmd == CMD_GET_IQ)
			{
				c_lcd <: speed;
				c_lcd <: set_speed;
#ifdef USE_XSCOPE
				xscope_probe_data(2, speed);
				xscope_probe_data(4, set_speed);
#endif
			}
			else if (cmd == CMD_SET_SPEED)
			{
				c_lcd :> set_speed;
			}
			else if(cmd == CMD_DIR)
			{
				c_lcd :> temp;
				c_control <: 4;
				c_control <: temp;
			}
			break;
		}

	}
}

/* speed_control2() function updates pwm value based on pid regulator values
 * and sends the updated values to other threads using channels for motor 2 */
void speed_control2 (chanend c_control2, chanend c_lcd2 )
{
	unsigned ts, set_speed = 500, speed = 0, uPwm = 0, temp, cmd, startup = 1 ;
	int pwm = 0, calced_pwm = 0 ;
	/* 32 bit timer declaration */
	timer t;
	/* pid variables */
	pid_data pid;

	/* initialise PID settings */
	init_pid( Kp, Ki, Kd, pid );
	/* taking current timer value */
	t :> ts;

	/* motor wakeup function */
	while (startup < 2000)
	{
		c_control2 <: 2;
		c_control2 <: 200;
		startup++;
	/* delay function for 1ms */
		t when timerafter (ts + MSec) :> ts;
	}

	/*main loop for speed control */
	while (1)
	{
		#pragma ordered
		select
		{
		/* updates control parameters for every 1 ms */
		case t when timerafter (ts + MSec) :> ts:
		/* to get updated speed value from runmotor function */
			c_control2 <: 1;
			c_control2 :> speed;

		/* 304 rpm/V - assume 24V maps to PWM_MAX_VALUE */
			calced_pwm =  (set_speed * PWM_MAX_VALUE) / (304*24);

		/* Updating pwm as per speed feedback and speed reference */
			pwm = calced_pwm  + pid_regulator_delta_cust_error((int)(set_speed - speed), pid );

			if (pwm > 4000)
				pwm = 4000;
			if (pwm < 50)
				pwm = 50;

			uPwm = (unsigned)pwm;
			c_control2 <: 2;
			c_control2 <: uPwm;
#ifdef USE_XSCOPE
			xscope_probe_data(1, uPwm);
#endif
			break;

		case c_lcd2 :> cmd: /* Process a command received from the display */
			if (cmd == CMD_GET_IQ2)
			{
				c_lcd2 <: speed;
#ifdef USE_XSCOPE
				xscope_probe_data(3, speed);
#endif
			}
			else if (cmd == CMD_SET_SPEED2)
			{
				c_lcd2 :> set_speed;
			}
			else if(cmd == CMD_DIR2)
			{
				c_lcd2 :> temp;
				c_control2 <: 7;
				c_control2 <: temp;
			}
			break;

		}

	}
}
