/**
 * Module:  app_basic_bldc
 * Version: 1v1
 * Build:
 * File:    run_motor.xc
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



#include "run_motor.h"

/* number of pole pairs are TWO so we are defining that below*/
#define MOTOR_POLE_PAIRS (NUMBER_OF_POLES>>1)

/* counter clockwise direction commutation sequence for low side of bridge */
static unsigned bldc_ph_a_lo[6] = {0,1,1,0,0,0};
static unsigned bldc_ph_b_lo[6] = {0,0,0,1,1,0};
static unsigned bldc_ph_c_lo[6] = {1,0,0,0,0,1};
/* counter clockwise direction commutation sequence for high side of bridge */
const unsigned bldc_high_seq[6] = {1,1,2,2,0,0};
/* clockwise direction commutation sequence for low side of bridge */
static unsigned bldc_ph_a_lo1[6] = {0,0,0,0,1,1};
static unsigned bldc_ph_b_lo1[6] = {1,1,0,0,0,0};
static unsigned bldc_ph_c_lo1[6] = {0,0,1,1,0,0};
/* clockwise direction commutation sequence for high side of bridge */
const unsigned bldc_high_seq1[6] = {2,0,0,1,1,2};

/*
 *run_motor1() function uses hall sensor outputs and finds hall_state. Based on
 *the hall state it identifies the rotor position and give the commutation
 *sequence to Upper and Lower IGBT's  then it calculates speed and updates PWM
 *values. This funcntion uses three channels c_wd for watchdog timer, c_control
 *to update speed, pwm, lower IGBT state changes and direction flag values
 *between the threads for motor 1.
 **/

void run_motor(chanend c_pwm, chanend c_control, port in p_hall, port out p_pwm_lo[], chanend? c_wd)
{
	unsigned high_chan, hall_state = 0, pin_state = 0, pwm_val = 240, dir_flag=1;
	unsigned ts, ts0, delta_t, speed = 0, hall_flg = 1, cmd;
	unsigned state0 = 0, statenot0 =0 ;
	unsigned set_speed=500;
	t_pwm_control pwm_ctrl;
	timer t;

	// First send my PWM server the shared memory structure address
	pwm_share_control_buffer_address_with_server(c_pwm, pwm_ctrl);

	// Pause to allow the rest of the system to settle
	t :> ts;
	t when timerafter(ts+ (5*SEC)) :> ts;

	if (!isnull(c_wd)) {
		/* allow the WD to get going and enable motor */
		c_wd <: WD_CMD_START;
	}

	t :> ts;

	/* main loop */
	while (1)
	{
		select
		{
		/* wait for a change in the hall sensor - this is what this update loop is locked to */
		case do_hall_select( hall_state, pin_state, p_hall );

		case c_control :> cmd:
			switch (cmd)
			{
			/* updates speed changes between threads */
				case 1:
					c_control <: speed;
					break;

				/* upadates pwm values between threads*/
				case 2:
					c_control :> pwm_val;
					break;

				/* upadates direction changes of motor rotation based on Button C */
				case 4:
					c_control :> dir_flag;
					break;

				default:
					break;
			}
			break;
		}

		/* handling hall states */
		if (hall_state == HALL_INV)
			hall_state = 0;

		/* this loop calculates speed */
		if (hall_flg == 1 && hall_state == 0)
		{
		/* get time and calculate RPM */
			ts0 = ts;
			t :> ts;
			delta_t = ts - ts0;
		/*caculate speed using equation below */
			speed = SPEED_COUNT / ( delta_t );
			hall_flg = 0;
			state0 = 0;
			statenot0 =0;
		}

		if (hall_flg == 0 && hall_state != 0 )
			hall_flg = 1;

		/* Check for motor1 halt state */
		if(hall_flg !=0 )
		{
			state0++;
			if(state0 >= STATE_LIMIT)
			{
				speed = 0;
				state0 =0;
			}
		}
		else if(hall_flg == 0 )
		{
			statenot0++;
			if(statenot0 >= STATE_LIMIT)
			{
				speed = 0;
				statenot0 =0;
			}
		}

		/* Identifies the direction flag and sends commutation sequence to spin the
		 * motor CW or CCW */
		if (dir_flag)
		{
			high_chan = bldc_high_seq[hall_state];
			/* do output and switch on the IGBT's */
			p_pwm_lo[0] <: bldc_ph_a_lo[hall_state];
			p_pwm_lo[1] <: bldc_ph_b_lo[hall_state];
			p_pwm_lo[2] <: bldc_ph_c_lo[hall_state];
		}
		else
		{
			high_chan = bldc_high_seq1[hall_state];
			/* do output and switch on the IGBT's */
			p_pwm_lo[0] <: bldc_ph_a_lo1[hall_state];
			p_pwm_lo[1] <: bldc_ph_b_lo1[hall_state];
			p_pwm_lo[2] <: bldc_ph_c_lo1[hall_state];
		}

		/* updates pwm_val */
		update_pwm( pwm_ctrl, c_pwm, pwm_val, high_chan );

	}
}
