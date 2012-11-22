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
#define Kp 5000
#define Ki 100
#define Kd 40
#define PWM_MAX_LIMIT 3800
#define PWM_MIN_LIMIT 200
#define OFFSET_14 16383

#define STALL_SPEED 100
#define STALL_TRIP_COUNT 5000

#define ERROR_OVERCURRENT 0x1
#define ERROR_UNDERVOLTAGE 0x2
#define ERROR_STALL 0x4

// This is half of the coil sector angle (6 sectors = 60 degrees per sector, 30 degrees per half sector)
#define THETA_HALF_PHASE (QEI_COUNT_MAX * 30 / 360 / NUMBER_OF_POLES)

#pragma xta command "add exclusion foc_loop_motor_fault"
#pragma xta command "add exclusion foc_loop_speed_comms"
#pragma xta command "add exclusion foc_loop_shared_comms"
#pragma xta command "add exclusion foc_loop_startup"
#pragma xta command "analyze loop foc_loop"
#pragma xta command "set required - 40 us"

/*
 * run_motor() function initially runs in open loop, spinning the magnetic field around at a fixed
 * torque until the QEI reports that it has an accurate position measurement.  After this time,
 * it uses the hall sensors to calculate the phase difference between the QEI zero point and the
 * hall sectors, and therefore between the motors coils and the QEI disc.
 *
 * After this, the full field oriented control is used to commutate the rotor. Each iteration
 * of the control loop does the following actions:
 *
 *   Reads the QEI and ADC state
 *   Calculate the Id and Iq values by transforming the coil currents reported by the ADC
 *   Use the speed value from the QEI in a speed control PID, producing a demand Iq value
 *   Use the demand Iq and the measured Iq and Id in two current control PIDs
 *   Transform the current control PID outputs into coil demand currents
 *   Use these to set the PWM duty cycles for the next PWM phase
 *
 * This is a standard FOC algorithm, with the current and speed control loops combined.
 *
 * Notes:
 *
 *   when theta=0, the Iq component (the major magnetic vector) transforms to the Ia current.
 *   therefore we want to have theta=0 aligned with the centre of the '001' state of hall effect
 *   detector.
 **/

#pragma unsafe arrays
void run_motor ( chanend? c_in, chanend? c_out, chanend c_pwm, streaming chanend c_qei, streaming chanend c_adc, chanend c_speed, chanend? c_wd, port in p_hall, chanend c_can_eth_shared )
{
	/* Measured coil currents from ADC */
	int Ia_in = 0, Ib_in = 0, Ic_in = 0;

	/* Measured currents once transformed to a 2D vector */
	int alpha_in = 0, beta_in = 0;

	/* Measured radial and tangential currents in the rotor frame of reference */
	int Id_in = 0, Iq_in = 0;

	/* Ideal current producing tangential magnetic field. Generates torque in the
	 * rotor, and therefore set by the speed error */
	int iq_set_point = 0;

	/* Ideal current producing radial magnetic field. Since no radial force is required
	 * to spin the rotor, this is always zero for PMSM and BLDC motors */
	int id_set_point = 0;

	/* Speed PID control structure */
	pid_data pid_speed;

	/* Id PID control structure */
	pid_data pid_d;

	/* Iq PID control structure */
	pid_data pid_q;

	/* The difference between the actual coil currents, and the demand coil currents
	 * required to produce the correct magnetic field
	 */
	int Id_err = 0, Iq_err = 0;

	/* The demand radial and tangential currents from the current control PIDs */
	int id_out = 0, iq_out = 0;

	/* The demand currents as a 2D vector */
	int alpha_out = 0, beta_out = 0;

	/* The demand currents as coil currents */
	int Ia_out, Ib_out, Ic_out;

	/* PWM variables */
	unsigned pwm[3] = {0, 0, 0};
	t_pwm_control pwm_ctrl;

	/* General state management */
	unsigned start_up = 0;

	/* Position and speed as measured by the QEI */
	unsigned meas_theta = 0, valid = 0;
	int meas_speed = 1000;

	unsigned set_theta = 0;	// Demand theta set after calculating error
	int set_speed = 1000;	// Demand speed set by the user/comms interface

	// Phase difference between the QEI and the coils
	unsigned theta_offset = -1;

	// Command received from the control interface
	unsigned command;

	/* Hall state */
	unsigned hall, last_hall=0;

	/* Fault detection */
	unsigned error_flags=0;
	unsigned stop_motor=0;
	unsigned stall_count=0;

	/* Timer and timestamp */
	timer t;
	unsigned ts1;

	/* General counter for the number of iterations of the control loop */
	unsigned cycle_count=0;



	// First send my PWM server the shared memory structure address
	pwm_share_control_buffer_address_with_server(c_pwm, pwm_ctrl);

	// Pause to allow the rest of the system to settle
	{
		unsigned thread_id = get_logical_core_id();
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
		unsigned thread_id = get_logical_core_id();
		t :> ts1;
		t when timerafter(ts1+1*SEC) :> void;
	}

	/* PID control initialisation... */
	init_pid( MOTOR_P, MOTOR_I, MOTOR_D, pid_d);
	init_pid( MOTOR_P, MOTOR_I, MOTOR_D, pid_q);
	init_pid( Kp, Ki, Kd, pid_speed );

	// Initially - pretend that the speed and the set speed are the same
	meas_speed = set_speed;

	/* Main loop */
	while (1)
	{
#pragma xta endpoint "foc_loop"
		select
		{
		case c_speed :> command:		/* This case responds to speed control through shared I/O */
#pragma xta label "foc_loop_speed_comms"
			if(command == CMD_GET_IQ)
			{
				c_speed <: meas_speed;
				c_speed <: set_speed;
			}
			else if (command == CMD_SET_SPEED)
			{
				c_speed :> set_speed;
			}
			else if(command == CMD_GET_FAULT)
			{
				c_speed <: error_flags;
			}

		break; // case c_speed :> command:

		case c_can_eth_shared :> command:		//This case responds to CAN or ETHERNET commands
#pragma xta label "foc_loop_shared_comms"
			if(command == CMD_GET_VALS)
			{
				c_can_eth_shared <: meas_speed;
				c_can_eth_shared <: Ia_in;
				c_can_eth_shared <: Ib_in;
			}
			else if(command == CMD_GET_VALS2)
			{
				c_can_eth_shared <: Ic_in;
				c_can_eth_shared <: iq_set_point;
				c_can_eth_shared <: id_out;
				c_can_eth_shared <: iq_out;
			}

			else if (command == CMD_SET_SPEED)
			{
				c_can_eth_shared :> set_speed;
			}
			else if (command == CMD_GET_FAULT)
			{
				c_can_eth_shared <: error_flags;
			}

		break; // case c_can_eth_shared :> command:


		default:	/* Initially the below case runs in open loop with the hall sensor responses and then reverts back to main FOC algorithem */
			if(stop_motor==0)
			{

				/* Get hall state */
				last_hall = hall;
				p_hall :> hall;

				/* Check error status */
				if(!(hall & 0b1000)) 
				{
					error_flags |= ERROR_OVERCURRENT;
				}

				/* Initial startup code using HALL mode */
				if (valid==0 || theta_offset==-1 )
				{
#pragma xta label "foc_loop_startup"

					{meas_speed, meas_theta, valid } = get_qei_data( c_qei );

					if (valid && (last_hall&0x7)==0b011 && (hall&0x7)==0b010) 
					{
						// We are spinning in the wrong direction
						pwm[0]=-1;
						pwm[1]=-1;
						pwm[2]=-1;
						stop_motor=1;
					} // if (valid && (last_hall&0x7)==0b011 && (hall&0x7)==0b010)
					else 
					{
						// Find the offset between the rotor and the QEI
						if (valid && (last_hall&0x7)==0b011 && (hall&0x7)==0b001 && theta_offset==-1 && meas_theta < (QEI_COUNT_MAX/NUMBER_OF_POLES)) 
						{
							theta_offset = (THETA_HALF_PHASE + meas_theta);
						}

						/* Spin the magnetic field around regardless of the encoder */
#if PLATFORM_REFERENCE_MHZ == 100
						set_theta = (start_up >> 2) & (QEI_COUNT_MAX-1);
#else
						set_theta = (start_up >> 4) & (QEI_COUNT_MAX-1);
#endif

						iq_out = 2000;
						id_out = 0;

						/* Inverse park  [d,q] to [alpha, beta] */
						inverse_park_transform( alpha_out, beta_out, id_out, iq_out, set_theta  );

						/* Final voltages applied */
						inverse_clarke_transform( Ia_out, Ib_out, Ic_out, alpha_out, beta_out );

						/* Scale to 12bit unsigned for PWM output */
						pwm[0] = (Ia_out + OFFSET_14) >> 3;
						if (pwm[0] > PWM_MAX_LIMIT) pwm[0] = PWM_MAX_LIMIT;
						else if (pwm[0] < PWM_MIN_LIMIT) pwm[0] = PWM_MIN_LIMIT;
						pwm[1] = (Ib_out + OFFSET_14) >> 3;
						if (pwm[1] > PWM_MAX_LIMIT) pwm[1] = PWM_MAX_LIMIT;
						else if (pwm[1] < PWM_MIN_LIMIT) pwm[1] = PWM_MIN_LIMIT;
						pwm[2] = (Ic_out + OFFSET_14) >> 3;
						if (pwm[2] > PWM_MAX_LIMIT) pwm[2] = PWM_MAX_LIMIT;
						else if (pwm[2] < PWM_MIN_LIMIT) pwm[2] = PWM_MIN_LIMIT;
					} // else !(valid && (last_hall&0x7)==0b011 && (hall&0x7)==0b010)

					/* Update the PWM values */
					update_pwm_inv( pwm_ctrl, c_pwm, pwm );

					start_up++;
				} // if (valid==0 || theta_offset==-1 )
				else
				{
					cycle_count++;

#pragma xta label "foc_loop_read_hardware"

					/* ---	FOC ALGORITHM	--- */

					/* Get the position from encoder module */
					{meas_speed, meas_theta, valid } = get_qei_data( c_qei );

					// Check for a stall
					if (meas_speed < STALL_SPEED) 
					{
						if (stall_count > STALL_TRIP_COUNT) 
						{
							error_flags |= ERROR_STALL;
						}
						else 
						{
							stall_count++;
						}
					} // if (meas_speed < STALL_SPEED) 
					else 
					{
						stall_count=0;
					} // else !(meas_speed < STALL_SPEED) 

					// Bring theta into the correct phase (adjustment between QEI and motor windings)
					set_theta = meas_theta - theta_offset;
					set_theta &= (QEI_COUNT_MAX-1);

#pragma xta label "foc_loop_clarke"

					/* Get ADC readings */
					{Ia_in, Ib_in, Ic_in} = get_adc_vals_calibrated_int16( c_adc );

					/* To calculate alpha and beta currents */
					clarke_transform(Ia_in, Ib_in, Ic_in, alpha_in, beta_in);

#pragma xta label "foc_loop_park"

					/* Id and Iq outputs derived from park transform */
					park_transform( Id_in, Iq_in, alpha_in, beta_in, set_theta  );

#pragma xta label "foc_loop_speed_pid"

					/* Applying Speed PID */
					iq_set_point = pid_regulator_delta_cust_error_speed((int)(set_speed - meas_speed), pid_speed );
					if (iq_set_point <0) iq_set_point = 0;

					/* Apply PID control to Iq and Id */
					Iq_err = Iq_in - iq_set_point;
					Id_err = Id_in - id_set_point;

#pragma xta label "foc_loop_id_iq_pid"

					iq_out = pid_regulator_delta_cust_error_Iq_control( Iq_err, pid_q );
					id_out = pid_regulator_delta_cust_error_Id_control( Id_err, pid_d );

#pragma xta label "foc_loop_inverse_park"

					/* Inverse park  [d,q] to [alpha, beta] */
					inverse_park_transform( alpha_out, beta_out, id_out, iq_out, set_theta  );

#pragma xta label "foc_loop_inverse_clarke"

					/* Final voltages applied */
					inverse_clarke_transform( Ia_out, Ib_out, Ic_out, alpha_out, beta_out );

#pragma xta label "foc_loop_update_pwm"

					/* Scale to 12bit unsigned for PWM output */
					pwm[0] = (Ia_out + OFFSET_14) >> 3;
					if (pwm[0] > PWM_MAX_LIMIT) pwm[0] = PWM_MAX_LIMIT;
					else if (pwm[0] < PWM_MIN_LIMIT) pwm[0] = PWM_MIN_LIMIT;
					pwm[1] = (Ib_out + OFFSET_14) >> 3;
					if (pwm[1] > PWM_MAX_LIMIT) pwm[2] = PWM_MAX_LIMIT;
					else if (pwm[1] < PWM_MIN_LIMIT) pwm[2] = PWM_MIN_LIMIT;
					pwm[2] = (Ic_out + OFFSET_14) >> 3;
					if (pwm[2] > PWM_MAX_LIMIT) pwm[2] = PWM_MAX_LIMIT;
					else if (pwm[2] < PWM_MIN_LIMIT) pwm[2] = PWM_MIN_LIMIT;


					if(error_flags) 
					{
#pragma xta label "foc_loop_motor_fault"
						pwm[0]=-1;
						pwm[1]=-1;
						pwm[2]=-1;
						stop_motor=1;
					} // if(error_flags) 

					/* Update the PWM values */
					update_pwm_inv( pwm_ctrl, c_pwm, pwm );

#ifdef USE_XSCOPE
					if ((cycle_count & 0x1) == 0) 
					{
						if (isnull(c_in)) 
						{
							xscope_probe_data(0, meas_speed);
					    xscope_probe_data(1, iq_set_point);
					    xscope_probe_data(2, pwm[0]);
					    xscope_probe_data(3, pwm[1]);
					    xscope_probe_data(4, Ia_in);
					    xscope_probe_data(5, Ib_in);
					  } // if (isnull(c_in)) 
					} // if ((cycle_count & 0x1) == 0) 
#endif
				} // else ! (valid==0 || theta_offset==-1 )
			} // if(stop_motor==0)
		break; // default:


		}	// select
	}	// while (1)
} // run_motor
/*****************************************************************************/
// inner_loop.xc
