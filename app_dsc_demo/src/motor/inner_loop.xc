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

#pragma xta command "add exclusion foc_loop_motor_fault"
#pragma xta command "add exclusion foc_loop_speed_comms"
#pragma xta command "add exclusion foc_loop_shared_comms"
#pragma xta command "add exclusion foc_loop_startup"
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
void run_motor ( chanend? c_in, chanend? c_out, chanend c_pwm, streaming chanend c_qei, chanend c_adc, chanend c_speed, chanend? c_wd, port in p_hall, chanend c_can_eth_shared )
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
	unsigned start_up = 1024;

	/* Position and Speed */
	unsigned theta = 0, valid = 0;
	int speed = 1000, set_speed = 1000;

	// Channel comms
	unsigned cmm_speed;
	unsigned comm_shared;

	/* Hall state */
	unsigned hall, last_hall=0;

	/* Fault detection */
	unsigned OC_fault_flag=0, UV_fault_flag=0, err_flag=0, count=0;

	/* Timer and timestamp */
	timer t;
	unsigned ts1;

	/*  */
	unsigned cycle_count=0;

	/* Speed PID structure */
	pid_data pid;

	/* Id PID User defined datatype */
	pid_data pid_d;

	/* Iq PID structure */
	pid_data pid_q;
	
	// First send my PWM server the shared memory structure address
	pwm_share_control_buffer_address_with_server(c_pwm, pwm_ctrl);

	// Pause to allow the rest of the system to settle
	{
		unsigned thread_id = get_thread_id();
		t :> ts1;
		t when timerafter(ts1+2*SEC+256*thread_id) :> void;
	}

	/* ADC centrepoint calibration before we start the PWM */
	do_adc_calibration( c_adc );

	/* allow the WD to get going */
	if (!isnull(c_wd)) {
		c_wd <: WD_CMD_START;
	}

	// Pause to allow the rest of the system to settle
	{
		unsigned thread_id = get_thread_id();
		t :> ts1;
		t when timerafter(ts1+1*SEC) :> void;
	}

	/* PID control initialisation... */
	init_pid( MOTOR_P, MOTOR_I, MOTOR_D, pid_d);
	init_pid( MOTOR_P, MOTOR_I, MOTOR_D, pid_q);
	init_pid( Kp, Ki, Kd, pid );

	// Initially - pretend that the speed and the set speed are the same
	speed = set_speed;

	/* Main loop */
	while (1)
	{
#pragma xta endpoint "foc_loop"
		select
		{
		/* This case responds to speed control through shared I/O */
		case c_speed :> cmm_speed:
#pragma xta label "foc_loop_speed_comms"
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
#pragma xta label "foc_loop_shared_comms"
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
				c_can_eth_shared <: valid;
			}

			break;

		/* Initially the below case runs in open loop with the hall sensor responses and then reverts
		 * back to main FOC algorithem */
		default:
			if(err_flag==0)
			{

				/* Get hall state */
				last_hall = hall;
				p_hall :> hall;

				/* Check error status */
				if(hall & 0b1000) {
					OC_fault_flag=0;
				} else {
					OC_fault_flag=1;
				}

				/* Initial startup code using HALL mode */
				if (start_up < QEI_COUNT_MAX<<4 || valid==0)
				{
#pragma xta label "foc_loop_startup"

					{speed, theta, valid } = get_qei_data( c_qei );

					/* Check we are spinning in the right direction */
					if ((last_hall&0x7)==0b011 && (hall&0x7)==0b010) {
						// Turning the wrong direction
						  pwm[0]=-1;
						  pwm[1]=-1;
						  pwm[2]=-1;
						  err_flag=1;
					} else {

						/* Spin the magnetic field around regardless of the encoder */
#if PLATFORM_REFERENCE_MHZ == 100
						theta = (start_up >> 2) & (QEI_COUNT_MAX-1);
#else
						theta = (start_up >> 4) & (QEI_COUNT_MAX-1);
#endif

						iq_out = 2000;
						id_out = 0;

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
					}

					/* Update the PWM values */
					update_pwm_inv( pwm_ctrl, c_pwm, pwm );

					start_up++;
				}
				else
				{
					cycle_count++;

#pragma xta label "foc_loop_read_hardware"

					/* ---	FOC ALGORITHM	--- */
					/* Get ADC readings */
					{Ia_in, Ib_in, Ic_in} = get_adc_vals_calibrated_int16( c_adc );

					/* Get the position from encoder module */
					{speed, theta, valid } = get_qei_data( c_qei );

					// Bring theta into the correct phase (adjustment between QEI and motor windings
					theta = theta + THETA_PHASE;
					if (theta >= THETA_LIMIT) theta = theta - THETA_LIMIT;

#pragma xta label "foc_loop_clarke"

					/* To calculate alpha and beta currents */
					clarke_transform(alpha_in, beta_in, Ia_in, Ib_in, Ic_in);

#pragma xta label "foc_loop_park"

					/* Id and Iq outputs derived from park transform */
					park_transform( Id_in, Iq_in, alpha_in, beta_in, theta  );

#pragma xta label "foc_loop_speed_pid"

					/* Applying Speed PID */
					iq_set_point = pid_regulator_delta_cust_error_speed((int)(set_speed - speed), pid );
					if (iq_set_point <0) iq_set_point = 0;

					/* Apply PID control to Iq and Id */
					Iq_err = Iq_in - iq_set_point;
					Id_err = Id_in - id_set_point;

#pragma xta label "foc_loop_id_iq_pid"

					iq_out = pid_regulator_delta_cust_error_Iq_control( Iq_err, pid_q );
					id_out = pid_regulator_delta_cust_error_Id_control( Id_err, pid_d );

#pragma xta label "foc_loop_inverse_park"

					/* Inverse park  [d,q] to [alpha, beta] */
					inverse_park_transform( alpha_out, beta_out, id_out, iq_out, theta  );

#pragma xta label "foc_loop_inverse_clarke"

					/* Final voltages applied */
					inverse_clarke_transform( Va, Vb, Vc, alpha_out, beta_out );

#pragma xta label "foc_loop_update_pwm"

					/* Scale to 12bit unsigned for PWM output */
					pwm[0] = (Va + OFFSET_14) >> 3;
					if (pwm[0] > PWM_MAX_LIMIT) pwm[0] = PWM_MAX_LIMIT;
					if (pwm[0] < PWM_MIN_LIMIT) pwm[0] = PWM_MIN_LIMIT;
					pwm[1] = (Vb + OFFSET_14) >> 3;
					if (pwm[1] > PWM_MAX_LIMIT) pwm[2] = PWM_MAX_LIMIT;
					if (pwm[1] < PWM_MIN_LIMIT) pwm[2] = PWM_MIN_LIMIT;
					pwm[2] = (Vc + OFFSET_14) >> 3;
					if (pwm[2] > PWM_MAX_LIMIT) pwm[2] = PWM_MAX_LIMIT;
					if (pwm[2] < PWM_MIN_LIMIT) pwm[2] = PWM_MIN_LIMIT;


					if((OC_fault_flag==1)||(UV_fault_flag==1)) {
#pragma xta label "foc_loop_motor_fault"
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
					        	xscope_probe_data(0, speed);
					        	xscope_probe_data(1, iq_set_point);
					        	xscope_probe_data(2, Va);
					        	xscope_probe_data(3, Vb);
					        }
					}
#endif
				}
			}
			break;
		}
	}
}
