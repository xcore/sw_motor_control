/**
 * Module:  app_dsc_demo
 * Version: 1v0alpha1
 * Build:   dcbd8f9dde72e43ef93c00d47bed86a114e0d6ac
 * File:    outer_loop.xc
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
#include <print.h>
#include "dsc_config.h"
#include "inner_loop.h"
#include "outer_loop.h"
#include "pid_regulator.h"
#include "watchdog.h"
#include "shared_io.h"

void speed_control_loop( chanend c_wd, chanend c_speed, chanend c_control_out, chanend c_command_can, chanend c_command_eth, chanend c_display, chanend ?c_logging )
{
	#define SPEED_AVG 35

	unsigned ts, ts2, ts3, cmd;
	unsigned set_speed = INITIAL_SET_SPEED;
	unsigned speed = 0;
	int iq = 0;
	int Torque = 0;
	unsigned log_flag = 1;
	unsigned delta_t = 0;
	unsigned int my_loop=0;
	timer t, t2, t3;
	pid_data pid;

	// speed loop settings 10, 0, 0
	int Kp=10*32768, Ki=00, Kd=0;
	init_pid( Kp, Ki, Kd, pid );

	/* delay to allow the WD to get going */
	t :> ts;
	t when timerafter(ts+100000000) :> ts;
	
	// enable motor via watchdog
	c_wd <: WD_CMD_START;	
	
	// Get the initial timer values
	t :> ts;
	t2 :> ts2;
	t3 :> ts3;

	/* initialise speed setting */
	set_speed = 0;

	// Loop forever running the main control loop
	while (1)
	{
		#pragma ordered
		select
		{
			case t when timerafter (ts + 100000) :> ts: /* Run the main control loop at 20kHz */
				/* Gets the delta_t from hall sensor thread */
				c_speed <: 1;
				c_speed :> delta_t;

				/* Calculate the speed if the delta_t is valid. */
				if (delta_t != 0)
				{
					speed = ( 3000000000 / delta_t );
					speed <<= 1;
				}

				/* calculate required torque */
				Torque = pid_regulator_delta_cust_error((int)(set_speed - speed), pid );

				if (Torque < 0)
				{
					Torque = 1;
				}

				/* iq to Torque conversion */
				iq = Torque * 3;

				/* Send out the control value to the motor */
				c_control_out <: iq;

				/* logging */
				if ( ( log_flag == 1 ) && ( !isnull( c_logging ) ) )
				{
					c_logging <: speed;
					c_logging <: set_speed;
					c_logging <: iq;
				}
				break;

			/* this second case allows the outer loop to run through a sequence of steps for experimentation */
			case t2 when timerafter (ts2 + 100000000) :> ts2:

				if (my_loop > 2 && my_loop < 10) /* between 2s and 10s define the speed as 500 RPM */
				{
					set_speed = 500;
				}
				else if (my_loop == 10) /* at 10s set the speed to 0 and disable motor drive */
				{
					set_speed = 0;
					
					// Turn off the half bridges
					c_wd <: WD_CMD_DIS_MOTOR;
					printstr("Experiment sequence finished\n" );
				}

				// Increment the loop counter				
				my_loop++;
				break;
				
				
			case c_command_can :> cmd: /* Process a command received from the CAN */
				if (cmd == CMD_GET_VALS)
				{
					c_command_can <: speed;
					c_command_can <: set_speed;
				}
				else if (cmd == CMD_SET_SPEED)
				{
					c_command_can :> set_speed;
				}
				else
				{
					// Ignore invalid command
				}

				break;

			case c_command_eth :> cmd: /* Process a command received from the Ethernet */
				if (cmd == CMD_GET_VALS)
				{
					c_command_eth <: speed;
					c_command_eth <: set_speed;
				}
				else if (cmd == CMD_SET_SPEED)
				{
					c_command_eth :> set_speed;
				}
				else
				{
					// Ignore invalid command
				}

				break;

			case c_display :> cmd: /* Process a command received from the display */
				if (cmd == CMD_GET_IQ)
				{
					c_display <: speed;
					c_display <: set_speed;
					c_display <: iq;
				}
				else if (cmd == CMD_SET_SPEED)
				{
					c_display :> set_speed;
				}
				else
				{
					// Ignore invalid command
				}

				break;
		}
	}
}
