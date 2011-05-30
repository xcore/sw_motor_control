/**
 * Module:  app_dsc_demo
 * Version: 1v0alpha1
 * Build:   60a90cca6296c0154ccc44e1375cc3966292f74e
 * File:    inner_loop.xc
 * Modified by : Srikanth
 * Last Modified on : 26-May-2011
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
#include "qei_client.h"
#include "shared_io.h"
#include "watchdog.h"

#define MOTOR_P 2100
#define MOTOR_I 6
#define MOTOR_D 0
#define SEC 100000000
#define Kp 5000
#define Ki 100
#define Kd 40
#define PWM_MAX_LIMIT 3800
#define PWM_MIN_LIMIT 200
#define OFFSET_14 16383
#define ITERATION_LIMIT 500

const unsigned bldc_high_seq[6] = {2,0,0,1,1,2};
const unsigned bldc_new_seq[3] = {0,1,2};

/*
 *run_motor() function Initially runs in open loop uses hall sensor outputs and finds hall_state.
 *Based on the hall state it identifies the rotor position and give the commutation sequence to
 *Upper and Lower IGBT's. After rotating for some number of iterations it finds zero hall state
 *and executes field oriented control algorithem.It get actual speed and position of rotor using
 *encoder module and phase currents using ADC then it updates PWM based on this values. This
 *funcntion uses five channels c_wd for watchdog timer, c_qei to get the update speed and position,
 *c_speed for display and c_adc for currents.
 **/

#pragma unsafe arrays
void run_motor ( chanend c_pwm, chanend c_qei, chanend c_adc, chanend c_speed, chanend c_wd, port in p_hall )
{
	/* Currents from ADC */
	int Ia_in = 0, Ib_in = 0, Ic_in = 0;

	/* Clark transform variable declaration */
	int alpha_in = 0, beta_in = 0;

	/* Park transform variables */
	int Id_in = 0, Iq_in = 0;

	/* PID variables */
	int id_out = 0, iq_out = 0;
	int Id_err = 0, Iq_err = 0;

	/* Inverse Park transform outputs */
	int alpha_out = 0, beta_out = 0;

	/* PWM variables */
	unsigned pwm[3] = {0, 0, 0};
	int Va = 0, Vb = 0, Vc = 0;

	/* Speed feed back variable */
	int iq_set_point = 0;

	/* Always zero for BLDC */
	int id_set_point = 0;

	/* Open loop variables running in Hall mode */
	unsigned high_chan = 0, new_chan = 0, hall_state = 0, pin_state = 0, pwm_val = 300;
	unsigned bldc_hall_mode = 1, counter=0;

	/* Position and Speed */
	unsigned theta = 0, speed = 0, set_speed = 2000;
	unsigned cmm_speed, ts = 0;

	/* Speed PID structure */
	pid_data pid;

	/* Id PID User defined datatype */
	pid_data pid_d;

	/* Iq PID structure */
	pid_data pid_q;
	
	timer t;
	t :> ts;

	/* allow the WD to get going */
	t when timerafter(ts+ SEC) :> ts;
	c_wd <: WD_CMD_START;

	/* PID control initialisation... */
	init_pid( MOTOR_P, MOTOR_I, MOTOR_D, pid_d);
	init_pid( MOTOR_P, MOTOR_I, MOTOR_D, pid_q);
	init_pid( Kp, Ki, Kd, pid );

	/* Zero pwm */
	pwm[0] = 0;
	pwm[1] = 0;
	pwm[2] = 0;

	/* Update PWM */
	update_pwm( c_pwm, pwm );

	/* ADC centrepoint calibration */
	do_adc_calibration( c_adc );

	/* Update PWM */
	update_pwm( c_pwm, pwm );

	/* Main loop */
	while (1)
	{
		select
		{
		/* This case responds to speed control through shared I/O */
		case c_speed :> cmm_speed:
			if(cmm_speed == 2)
			{
				c_speed <: speed;
				c_speed <: set_speed;
			}
			else if (cmm_speed == CMD_SET_SPEED)
			{
				c_speed :> set_speed;
			}
			else
			{
				/* Ignore invalid command */
			}

			break;

		/* Initially the below case runs in open loop with the hall sensor responses and then reverts
		 * back to main FOC algorithem */
		default:
			if (bldc_hall_mode==1)
			{
				/* Change in the hall sensor states detected */
				do_hall_select( hall_state, pin_state, p_hall );

				/* Handling hall states */
				if (hall_state == HALL_INV)
					hall_state = 0;

				/* Do output and switch on the IGBT's */
				high_chan = bldc_high_seq[hall_state];
				new_chan =  bldc_new_seq[high_chan];

				/* Updates pwm_val on Lower IGBT's based on Hall state */
				if (new_chan == 0)
				{
					pwm[0] = pwm_val;
					pwm[1] = 0 ;
					pwm[2] = 0;
				}
				else if (new_chan == 1)
				{
					pwm[0] = 0;
					pwm[1] = pwm_val ;
					pwm[2] = 0;
				}
				else
				{
					pwm[0] = 0;
					pwm[1] = 0;
					pwm[2] = pwm_val;
				}

				/* Open loop ends after 500 iterations and zero position of hall state detected */
				if ((counter >= ITERATION_LIMIT) && (hall_state == 0))
				{
					bldc_hall_mode = 0;
				}
				counter++;

				/* Update the PWM values */
				update_pwm( c_pwm, pwm );

			}
			else
			{
				/* Get ADC readings */
				{Ia_in, Ib_in, Ic_in} = get_adc_vals_calibrated_int16( c_adc );

				/* Get the position from encoder module */
				theta = get_qei_position ( c_qei );

				/* Actual speed calculated using encoder module */
				speed = get_qei_speed ( c_qei );

				/* To calculate alpha and beta currents */
				clarke_transform(alpha_in, beta_in, Ia_in, Ib_in, Ic_in);

				/* Id and Iq outputs derived from park transform */
				park_transform( Id_in, Iq_in, alpha_in, beta_in, theta  );

				/* Applying Speed PID */
				iq_set_point = pid_regulator_delta_cust_error_speed((int)(set_speed - speed), pid );

				/* Apply PID control to Iq and Id */
				Iq_err = iq_set_point - Iq_in;
				Id_err = id_set_point - Id_in;

				iq_out = pid_regulator_delta_cust_error_Iq_control( Iq_err, pid_q );

				id_out = pid_regulator_delta_cust_error_Id_control( Id_err, pid_d );

				/* Inverse park  [d,q] to [alpha, beta] */
				inverse_park_transform( alpha_out, beta_out, id_out, iq_out, theta  );

				/* Final voltages applied */
				inverse_clarke_transform( Va, Vb, Vc, alpha_out, beta_out );

				/* Scale to 12bit unsigned for PWM output */
				pwm[0] = (Va + OFFSET_14) >> 3;
				pwm[1] = (Vb + OFFSET_14) >> 3;
				pwm[2] = (Vc + OFFSET_14) >> 3;

				/* Clamp to avoid switching issues */
				for (int j = 0; j < 3; j++)
				{
					if (pwm[j] > PWM_MAX_LIMIT)
						pwm[j] = PWM_MAX_LIMIT;
					if (pwm[j] < PWM_MIN_LIMIT )
						pwm[j] = PWM_MIN_LIMIT;
				}

				/* Update the PWM values */
				update_pwm( c_pwm, pwm );
			}
		break;
		}
	}
}
