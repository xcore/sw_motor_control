/**
 * Module:  app_basic_bldc
 * Version: 1v1
 * Build:
 * File:    torque_speed_cntrl.xc
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

#include <xs1.h>
#include "dsc_config.h"
#include "shared_io_motor.h"
#include "pid_regulator.h"
#include "print.h"
#define MSec 100000

/* speed loop settings*/
int Kp=1*5000, Ki=100, Kd=5;
int Kp1=1*8000, Ki1=100, Kd1=5;

/* torque_speed_control1() function updates pwm value based on pid regulator values
 * and sends the updated values to other threads using channels for motor 1*/
void torque_speed_control1(chanend c_control, chanend c_lcd, chanend c_adc)
{
	unsigned ts, set_speed = 500, speed = 0, uPwm = 0, temp, cmd, startup = 1,state = 0;
	int pwm = 0, calced_pwm = 0, pwm_speed=0, Ifb;
	/* 32 bit timer declaration */
	timer t;
	/* pid variables */
	pid_data pid, pid_t;

	/* initialise PID settings */
	init_pid( Kp, Ki, Kd, pid );
	init_pid( Kp1, Ki1, Kd1, pid_t );
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
	printstrln(" Motors Running...Counter Clock Wise Direction...");
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
		/* igbt state updates */
			c_control <: 5;
			c_control :> state;
		/* Ia as feedback */
			if(state == 1)
			{
				c_adc <: 0;
				c_adc :> Ifb;
			}

		/* Ib as feedback */
			if(state == 2)
			{
				c_adc <: 1;
				c_adc :> Ifb;
			}

		/* Ic as feedback */
			if(state == 3)
			{
				c_adc <: 2;
				c_adc :> Ifb;
			}

		/* 304 rpm/V - assume 24V maps to PWM_MAX_VALUE */
			calced_pwm =  (set_speed * PWM_MAX_VALUE) / (304*24);

		/* Updating pwm as per speed feedback and speed reference */
			pwm_speed = calced_pwm  + pid_regulator_delta_cust_error((int)(set_speed - speed), pid );
			if (pwm > 4000)
				pwm = 4000;
			if (pwm < -4000)
				pwm = -4000;

		/* Updating pwm as per current feedback */
			pwm = pwm_speed + pid_regulator_delta_cust_error((int)(pwm_speed - Ifb), pid_t );
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
				//c_lcd <: pwm;
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

/* torque_speed_control2() function updates pwm value based on pid regulator values
 * and sends the updated values to other threads using channels for motor 2 */
void torque_speed_control2 (chanend c_control2, chanend c_lcd2, chanend c_adc2)
{
	unsigned ts, set_speed = 500, speed = 0, uPwm = 0, temp, cmd, startup = 1,state = 0;
	int pwm = 0, calced_pwm = 0, pwm_speed=0, Ifb;
	/* 32 bit timer declaration */
	timer t;
	/* pid variables */
	pid_data pid, pid_t;

	/* initialise PID settings */
	init_pid( Kp, Ki, Kd, pid );
	init_pid( Kp1, Ki1, Kd1, pid_t );
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
		/* igbt state updates */
			c_control2 <: 5;
			c_control2 :> state;
		/* Ia as feedback */
			if(state == 1)
			{
				c_adc2 <: 3;
				c_adc2 :> Ifb;
			}

		/* Ib as feedback */
			if(state == 2)
			{
				c_adc2 <: 4;
				c_adc2 :> Ifb;
			}

		/* Ic as feedback */
			if(state == 3)
			{
				c_adc2 <: 5;
				c_adc2 :> Ifb;
			}

		/* 304 rpm/V - assume 24V maps to PWM_MAX_VALUE */
			calced_pwm =  (set_speed * PWM_MAX_VALUE) / (304*24);

		/* Updating pwm as per speed feedback and speed reference */
			pwm_speed = calced_pwm  + pid_regulator_delta_cust_error((int)(set_speed - speed), pid );
			if (pwm > 4000)
				pwm = 4000;
			if (pwm < -4000)
				pwm = -4000;

		/* Updating pwm as per current feedback */
			pwm = pwm_speed + pid_regulator_delta_cust_error((int)(pwm_speed - Ifb), pid_t );
			if (pwm > 4000)
				pwm = 4000;
			if (pwm < 50)
				pwm = 50;

			uPwm = (unsigned)pwm;
			c_control2 <: 2;
			c_control2 <: uPwm;
			break;

		case c_lcd2 :> cmd: /* Process a command received from the display */
			if (cmd == CMD_GET_IQ2)
			{
				c_lcd2 <: speed;
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
