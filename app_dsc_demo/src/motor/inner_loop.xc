/**
 * File:    inner_loop.xc
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
#include "inner_loop.h"
#include "hall_input.h"
#include "pwm_cli_inv.h"
#include "clarke.h"
#include "park.h"
#include "pid_regulator.h"
#include "adc_filter.h"
#include "adc_client.h"
#include "hall_client.h"
#include "qei_client.h"
#include "shared_io.h"
#include "watchdog.h"

#ifdef USE_XSCOPE
#include <xscope.h>
#endif

#define MOTOR_P 2100
#define MOTOR_I 6
#define MOTOR_D 0
#define SEC 100000000
#define MSec 100000
#define Kp 5000
#define Ki 100
#define Kd 40
#define PWM_MAX_LIMIT 3800
#define PWM_MIN_LIMIT 200
#define OFFSET_14 16383
#define RAMP 50
#define THETA_LIMIT 1024 									// 1024 is the counts around the QEI
#define THETA_PHASE 85 //(THETA_LIMIT / NUMBER_OF_POLES / 3) 	// Phase offset of 120 degrees


#pragma xta command "analyze loop foc_loop"
#pragma xta command "set required - 40 us"

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
void run_motor ( chanend? c_in, chanend? c_out, chanend c_pwm, chanend c_qei, chanend c_adc, chanend c_speed, chanend? c_wd, port in p_hall, chanend c_can_eth_shared )
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
	t_pwm_control pwm_ctrl;

	/* Speed feed back variable */
	int iq_set_point = 0;

	/* Always zero for BLDC */
	int id_set_point = 0;

	/* General state management */
	unsigned start_up = 1, counter = 0;

	/* Position and Speed */
	unsigned theta = 0, speed = 0, set_speed = 1000, theta_flag = 0, run = 0;
	unsigned cmm_speed;
	unsigned comm_shared;

	/* Fault detection */
	unsigned OC_fault_flag=0, UV_fault_flag=0, err_flag=0, count=0, oc_status=0b0000;

	/* Timer and timestamp */
	timer t;
	unsigned ts;

	/*  */
	unsigned cycle_count=0;

	/* Speed PID structure */
	pid_data pid;

	/* Id PID User defined datatype */
	pid_data pid_d;

	/* Iq PID structure */
	pid_data pid_q;
	
	if (!isnull(c_in)) {
		while (1);
	}

	// First send my PWM server the shared memory structure address
	pwm_share_control_buffer_address_with_server(c_pwm, pwm_ctrl);

	// Pause to allow the rest of the system to settle
	{
		unsigned thread_id = get_thread_id();
		t :> ts;
		t when timerafter(ts+2*SEC+256*thread_id) :> ts;
	}

	/* Zero pwm */
	pwm[0] = 0;
	pwm[1] = 0;
	pwm[2] = 0;

	/* ADC centrepoint calibration before we start the PWM */
	do_adc_calibration( c_adc );

	/* Update PWM */
	update_pwm_inv( pwm_ctrl, c_pwm, pwm );

	/* allow the WD to get going */
	if (!isnull(c_wd)) {
		c_wd <: WD_CMD_START;
	}

	// Pause to allow the rest of the system to settle
	{
		unsigned thread_id = get_thread_id();
		t :> ts;
		t when timerafter(ts+1*SEC) :> ts;
	}

	/* PID control initialisation... */
	init_pid( MOTOR_P, MOTOR_I, MOTOR_D, pid_d);
	init_pid( MOTOR_P, MOTOR_I, MOTOR_D, pid_q);
	init_pid( Kp, Ki, Kd, pid );

	/* Main loop */
	while (1)
	{
#pragma xta endpoint "foc_loop"
		select
		{
		/* This case responds to speed control through shared I/O */
		case c_speed :> cmm_speed:
			if(cmm_speed == CMD_GET_IQ)
			{
				c_speed <: speed;
				c_speed <: set_speed;
			}
			else if (cmm_speed == CMD_SET_SPEED)
			{
				c_speed :> set_speed;
			}
			else if(cmm_speed == CMD_GET_FAULT)
			{
				c_speed <: OC_fault_flag;
				c_speed <: UV_fault_flag;

			}

			break;

		//This case responds to CAN or ETHERNET commands
		case c_can_eth_shared :> comm_shared:
			if(comm_shared == CMD_GET_VALS)
			{
				c_can_eth_shared <: speed;
				c_can_eth_shared <: Ia_in;
				c_can_eth_shared <: Ib_in;
			}
			else if(comm_shared == CMD_GET_VALS2)
			{
				c_can_eth_shared <: Ic_in;
				c_can_eth_shared <: iq_set_point;
				c_can_eth_shared <: id_out;
				c_can_eth_shared <: iq_out;
			}

			else if (comm_shared == CMD_SET_SPEED)
			{
				c_can_eth_shared :> set_speed;
			}
			else if (comm_shared == CMD_GET_FAULT)
			{
				c_can_eth_shared <: OC_fault_flag;
				c_can_eth_shared <: theta_flag;
			}

			break;

		/* Initially the below case runs in open loop with the hall sensor responses and then reverts
		 * back to main FOC algorithem */
		default:
			if(err_flag==0)
			{

				/* Get OC fault pin status */
				p_hall :> oc_status;
				if(oc_status & 0b1000) {
					OC_fault_flag=0;
				} else {
					OC_fault_flag=1;
				}

				/* Initial startup code using HALL mode */
				if (start_up==0)
				{
					while (speed < 2000) {
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
						update_pwm_inv( pwm_ctrl, c_pwm, pwm );

						/* Ramp the set_speed up */
						t when timerafter(ts+ 5* MSec ) :> ts;
						set_speed = set_speed + RAMP;
					}
					start_up = 1;
				}
				else
				{
					cycle_count++;

					/* Hunt for correct phase difference */
					if(run == 0) {
						counter++;
						if(counter >= 4000) {
							if((set_speed == 2000) && (speed < 1500)) {
							theta_flag = 1;
							}
							run = 1;
						}
					}

					/* ---	FOC ALGORITHM	--- */
					/* Get ADC readings */
					{Ia_in, Ib_in, Ic_in} = get_adc_vals_calibrated_int16( c_adc );

					/* Get the position from encoder module */
					theta = get_qei_position ( c_qei );

//					if(theta_flag)
//					{
						theta = theta + THETA_PHASE;
						if (theta >= THETA_LIMIT) theta = theta - THETA_LIMIT;
//					}

					/* Actual speed calculated using encoder module */
					speed = get_qei_speed ( c_qei );

					/* To calculate alpha and beta currents */
					clarke_transform(alpha_in, beta_in, Ia_in, Ib_in, Ic_in);

					/* Id and Iq outputs derived from park transform */
					park_transform( Id_in, Iq_in, alpha_in, beta_in, theta  );

					/* Applying Speed PID */
					iq_set_point = pid_regulator_delta_cust_error_speed((int)(set_speed - speed), pid );

//					Iq_in = 1;
//					Id_in = 0;

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

					if((OC_fault_flag==1)||(UV_fault_flag==1)) {
						count++;
						if(count==10)
						{
						  pwm[0]=-1;
						  pwm[1]=-1;
						  pwm[2]=-1;
						  err_flag=1;
						}
					}
					/* Update the PWM values */
					update_pwm_inv( pwm_ctrl, c_pwm, pwm );

#ifdef USE_XSCOPE
					if ((cycle_count & 0x1) == 0) {
						if (isnull(c_in)) {
//							xscope_probe_data(0, Ia_in);
//							xscope_probe_data(1, Ib_in);
							xscope_probe_data(2, pwm[0]);
							xscope_probe_data(3, pwm[2]);
							xscope_probe_data(4, iq_out);
						}
					}
#endif
				}
			}
			break;
		}
	}
}
