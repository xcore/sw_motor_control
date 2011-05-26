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
#include "shared_io.h"

#define MOTOR_P 2100//4000//(8000)
#define MOTOR_I 6//11//33
#define MOTOR_D 0
#define SEC 100000000

#ifdef USE_XSCOPE
#include <xscope.h>
#endif
#pragma unsafe arrays
void run_motor ( chanend c_pwm, chanend c_qei, chanend c_adc, chanend c_control, chanend c_speed, chanend c_hall, port in p_hall )
{
	/* transform variables */
	int Ia_in = 0, Ib_in = 0, Ic_in = 0;
	int Ia1_in = 0, Ib1_in =0, Ic1_in =0;
	int alpha_out = 0, beta_out = 0;
	int Id_in = 0, Iq_in = 0;
	int id_out = 0, iq_out = 0;
	int Id_err = 0, Iq_err = 0;
	int alpha_in = 0, beta_in = 0;
	int Va = 0, Vb = 0, Vc = 0;
	int iq_set_point = 0;
	int id_set_point = 0; // always zero for BLDC

	unsigned set_speed = 2000;

	//int Kp=1*32768, Ki=200, Kd=0;
	//int Kp= 12000, Ki=4, Kd=10;
	//int Kp= 6000, Ki=500, Kd=0;
	int Kp= 6000, Ki=800, Kd=40;
	//int Kp= 12000, Ki=1, Kd=1;
	//int Kp= 8000, Ki=40, Kd=0;
	//int Kp= 1000, Ki=40, Kd=0;
	//static int i = 0;
	int count;

	unsigned theta = 0, speed = 0, can, theta_dis=0;
	unsigned hall_state = 0, pin_state = 0;
	unsigned pwm[3] = {0, 0, 0}, pwm_fb = 0;
	unsigned cmd, cmm_speed, ts = 0;

	/*SVPWM*/
	int Sector = 0;
	int lnTa=0,lnTb=0,lnTc=0,lnt1=0,lnt2=0;
	int lnX=0, lnY=0, lnZ=0;

	pid_data pid;
	pid_data pid_d;
	pid_data pid_q;
	
	timer t;
	/* allow the WD to get going */
	t :> ts;
	t when timerafter(ts+ SEC) :> ts;

	/* PID control initialisation... will need tuning! */
	init_pid( MOTOR_P, MOTOR_I, MOTOR_D, pid_d);
	init_pid( MOTOR_P, MOTOR_I, MOTOR_D, pid_q);
	init_pid( Kp, Ki, Kd, pid );
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
			//	c_control :> iq_set_point;
			//	c_control :> pwm_fb;
				break;

			case 1:
			//	c_control <: speed;
				break;
			}
			break;
#if 0
			case c_commands_can :> can:
				if (can == 1)
				{
					c_commands_can <: pwm[0];
					c_commands_can <: pwm[1];
				//	c_commands_can <: pwm[2];
				}
			break;
#endif
		case c_speed :> cmm_speed:
			if(cmm_speed == 2)
			{
				c_speed <: speed;
				c_speed <: iq_set_point;
				c_speed <: iq_out;
				c_speed <: set_speed;
			}
			else if (cmm_speed == CMD_SET_SPEED)
			{
				c_speed :> set_speed;
				if (set_speed < 1000)
					set_speed = 1000;
			}
			else
			{
				// Ignore invalid command
			}

			break;


//case t when timerafter (ts + 1000) :> ts:

		default:

			//do_hall_test( p_hall );
			/* get ADC readings */
			{Ia_in, Ib_in, Ic_in} = get_adc_vals_calibrated_int16( c_adc );
            //Ic1_in = -(Ia1_in - Ib1_in);

            //Ia_in = (Ib1_in + Ic1_in);
            //Ib_in = (Ia1_in + Ic1_in);
            //Ic_in = (Ib1_in + Ia1_in);

			/* get the position */
			theta = get_qei_position ( c_qei );
#if 0
			theta *= 2;

			if (theta >= 2048 )
				theta = theta - 2048;
#endif

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
			//iq_set_point += 20;
			//if(iq_set_point >=1000)
			//	iq_set_point = 1000;
			iq_set_point = pid_regulator_delta_cust_error((int)(set_speed - speed), pid );

			//if (iq_set_point > 8000)
				//iq_set_point = 8000;
			//if (iq_set_point < -8000)
				//iq_set_point = -8000;

			Iq_err = iq_set_point - Iq_in;
			Id_err = id_set_point - Id_in;

			iq_out = pid_regulator_delta_cust_error2( Iq_err, pid_q );

			id_out = pid_regulator_delta_cust_error3( Id_err, pid_d );


			/* inverse park  [d,q] to [alpha, beta] */
			inverse_park_transform( alpha_out, beta_out, id_out, iq_out, theta  );

			/* do inverse clark to get voltages */
			inverse_clarke_transform( Va, Vb, Vc, alpha_out, beta_out );
#if 0
            if(Va > 16383)
            	Va = 16383;
            if(Va < -16383)
            	Va = -16383;
            if(Vb > 16383)
				Vb = 16383;
			if(Vb < -16383)
				Vb = -16383;
			if(Vc > 16383)
				Vc = 16383;
			if(Vc < -16383)
				Vc = -16383;
#endif
#if 0
			pwm[0] = ((Va + 16383)/16) + 1000;
			pwm[1] = ((Vb + 16383)/16) + 1000;
			pwm[2] = ((Vc + 16383)/16) + 1000;
#endif
			//pwm[0] = ((Va + 16383)/8) ;
			//pwm[1] = ((Vb + 16383)/8) ;
			//pwm[2] = ((Vc + 16383)/8) ;

			pwm[0] = (Va + 16383) >> 3;
			//pwm[0] = pwm[0] +1000;
			//pwm[0] = pwm[0] + pwm_fb;
				if (pwm[0] < 0)
				pwm[0] =  - pwm[0];

			pwm[1] = (Vb + 16383) >> 3;
		//	pwm[1] = pwm[1] +1000;
			//pwm[1] = pwm[1] + pwm_fb;
			if (pwm[1] < 0)
				pwm[1] =  - pwm[1];

			pwm[2] = (Vc + 16383) >> 3;
		//	pwm[2] = pwm[2] +1000;
			//pwm[2] = pwm[2] + pwm_fb;
			if (pwm[2] < 0)
				pwm[2] =  - pwm[2];

			for (int j = 0; j < 3; j++)
			{
				if (pwm[j] > 3800)
					pwm[j] = 3800;
				if (pwm[j] < 200 )
					pwm[j] = 200;
			}

			// Update the PWM values
			update_pwm( c_pwm, pwm );
#ifdef USE_XSCOPE
			{
				static unsigned count=0;
				++count;
				if (count==500){
					xscope_probe_data(0, pwm[0]);
					xscope_probe_data(1, pwm[1]);
					xscope_probe_data(2, pwm[2]);

					xscope_probe_data(3, Ia_in);
					xscope_probe_data(4, Ib_in);
					xscope_probe_data(5, Ic_in);

					xscope_probe_data(6, theta);
					xscope_probe_data(7, speed);

					xscope_probe_data(8, iq_set_point);

					count=0;
				}
			}
#endif
			break;
		//default:
		//	break;
		}
	}
}
