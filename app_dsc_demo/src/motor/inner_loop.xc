/**
 * Module:  app_dsc_demo
 * Version: 1v0alpha1
 * Build:   60a90cca6296c0154ccc44e1375cc3966292f74e
 * File:    inner_loop.xc
 * Modified by : Srikanth
 * Last Modified on : 04-May-2011
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
#include "inner_loop.h"
#include "hall_input.h"
#include "pwm_cli.h"
#include "clarke.h"
#include "park.h"
#include "pid_regulator.h"
#include "adc_filter.h"
#include "adc_client.h"
#include "hall_client.h"
#include <print.h>
#include "qei_client.h"

#define MOTOR_P (8192)
#define MOTOR_I 33
#define MOTOR_D 0
#define SEC 100000000

#pragma unsafe arrays
void run_motor ( chanend c_pwm, chanend c_qei, chanend c_adc, chanend c_control, chanend c_speed, chanend c_commands_can )
{
	/* transform variables */
	int Ia_in = 0, Ib_in = 0, Ic_in = 0;
	int alpha_out = 0, beta_out = 0;
	int Id_in = 0, Iq_in = 0;
	int id_out = 0, iq_out = 0;
	int Id_err = 0, Iq_err = 0;
	int alpha_in = 0, beta_in = 0;
	int Va = 0, Vb = 0, Vc = 0;
	int iq_set_point = 0;
	int id_set_point = 0; // always zero for BLDC

	unsigned theta = 0, speed = 0, can;
	unsigned pwm[3] = {0, 0, 0};
	unsigned cmd, cmm_speed, ts = 0;

	pid_data pid_d;
	pid_data pid_q;
	
	timer t;
	/* allow the WD to get going */
	t :> ts;
	t when timerafter(ts+ SEC) :> ts;

	/* PID control initialisation... will need tuning! */
	init_pid( MOTOR_P, MOTOR_I, MOTOR_D, pid_d);
	init_pid( MOTOR_P, MOTOR_I, MOTOR_D, pid_q);
	/* zero pwm */
	pwm[0] = 0;
	pwm[1] = 0;
	pwm[2] = 0;

	/* ADC centrepoint calibration */
	update_pwm( c_pwm, pwm );

	do_adc_calibration( c_adc );

	/* update PWM */
	update_pwm( c_pwm, pwm );

	/* main loop */
	while (1)
	{
	select
	{
	/* respond to outer loop demand */

		case c_control :> cmd:
			switch(cmd)
			{
			case 0:
				c_control :> iq_set_point;
				break;

			case 1:
				c_control <: speed;
				break;
			}
			break;

			case c_commands_can :> can:
				if (can == 1)
				{
					c_commands_can <: pwm[0];
					c_commands_can <: pwm[1];
				//	c_commands_can <: pwm[2];
				}
			break;

		case c_speed :> cmm_speed:
			if(cmm_speed == 2)
			{
				c_speed <: speed;
			//	c_speed <: Ia_in;
			//	c_speed <: Ib_in;
			//	c_speed <: Ic_in;
			}
			break;

		default:

			/* get ADC readings */
			{Ia_in, Ib_in, Ic_in} = get_adc_vals_calibrated_int16( c_adc );

			/* get the position */
			theta = get_qei_position ( c_qei );
			theta *= 2;

			if (theta >= 2000 )
				theta = theta - 2000;
			/* to get speed */
			speed = get_qei_speed ( c_qei );

			/*
			 * What follows is an example of function calls that would be required to complete a
			 * FOC algorithm. This is an example only and is not functional!
			 */

			/* calculate alpha_in and beta_in */
			clarke_transform(alpha_in, beta_in, Ia_in, Ib_in, Ic_in);

			/* calculate Id_in and Iq_in */
			park_transform( Id_in, Iq_in, alpha_in, beta_in, theta  );

			/* apply PID control to Iq and Id */

			Iq_err = iq_set_point - Iq_in;
			Id_err = id_set_point - Id_in;

			iq_out = pid_regulator_delta_cust_error2( Iq_err, pid_q );

			id_out = pid_regulator_delta_cust_error3( Id_err, pid_d );

			iq_out >>= 1;
			id_out >>= 1;

			/* inverse park  [d,q] to [alpha, beta] */
			inverse_park_transform( alpha_out, beta_out, id_out, iq_out, theta  );

			/* do inverse clark to get voltages */
			inverse_clarke_transform( Va, Vb, Vc, alpha_out, beta_out );

			pwm[0] = (Va + 16383) >> 3;
				if (pwm[0] < 0)
				pwm[0] =  - pwm[0];

			pwm[1] = (Vb + 16383) >> 3;
			if (pwm[1] < 0)
				pwm[1] =  - pwm[1];

			pwm[2] = (Vc + 16383) >> 3;
			if (pwm[2] < 0)
				pwm[2] =  - pwm[2];

			/* clamp to avoid switching issues */

			for (int j = 0; j < 3; j++)
			{
				if (pwm[j] > 3900)
					pwm[j] = 3900;
				if (pwm[j] < 400 && pwm[j] != 0)
					pwm[j] = 400;
			}

			// Update the PWM values
			update_pwm( c_pwm, pwm );
			break;
		}
	}
}
