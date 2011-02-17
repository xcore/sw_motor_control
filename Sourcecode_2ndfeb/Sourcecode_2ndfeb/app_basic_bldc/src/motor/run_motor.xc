/**
 * Module:  app_basic_bldc
 * Version: 1v0alpha1
 * Build:   d6f1b08bc373431180841b062ab3e165ce3c38f7
 * File:    run_motor.xc
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
#include "run_motor.h"

#define MOTOR_POLE_PAIRS (NUMBER_OF_POLES>>1)

void run_motor ( chanend c_wd, chanend c_pwm, chanend c_control, port in p_hall, port out p_pwm_lo[])
{

	/* counter clockwise direction sequence */
	/* sequence of low side of bridge */
	unsigned bldc_ph_a_lo[6] = {0,1,1,0,0,0};
	unsigned bldc_ph_b_lo[6] = {0,0,0,1,1,0};
	unsigned bldc_ph_c_lo[6] = {1,0,0,0,0,1};

	/* sequence of high side of bridge */
	const unsigned bldc_high_seq[6] = {1,1,2,2,0,0};

	/* clockwise direction sequence */
	/* sequence of low side of bridge */
	unsigned bldc_ph_a_lo1[6] = {0,0,0,0,1,1};
	unsigned bldc_ph_b_lo1[6] = {1,1,0,0,0,0};
	unsigned bldc_ph_c_lo1[6] = {0,0,1,1,0,0};

	/* sequence of high side of bridge */
	const unsigned bldc_high_seq1[6] = {2,0,0,1,1,2};
	unsigned high_chan, hall_state = 0, pin_state = 0, pwm_val = 240, flag=1;
	unsigned ts, ts0, delta_t;
	unsigned speed = 0;
	unsigned hall_flg = 1;
	timer t;
	unsigned cmd;
	unsigned tempcount=0;
	unsigned tempcount1 =0;

	/* allow the WD to get going */
	t :> ts;
	t when timerafter(ts+100000000) :> ts;

	/* enable motor */
	c_wd <: WD_CMD_START;

	/* main loop */
	while (1)
	{
		select
		{
		/* wait for a change in the hall sensor - this is what this update loop is locked to*/
		case do_hall_select( hall_state, pin_state, p_hall );
		/* if we get a change in PWM value (i.e. current) then update it.. */
		case c_control :> cmd:
			switch (cmd)
			{
			case 1:
				c_control <: speed;
				break;
			case 2:
				c_control :> pwm_val;
				break;
			case 4:
				c_control :> flag;
				break;

			default:
			break;
			}
		break;
		}

		/* handle hall states */
		if (hall_state == HALL_INV)
			hall_state = 0;

		if (hall_flg == 1 && hall_state == 0)
		{
			/* get time and calculate RPM */
			ts0 = ts;
			t :> ts;
			delta_t = ts - ts0;
			speed = 3000000000 / ( delta_t );
			hall_flg = 0;
			tempcount = 0;
			tempcount1 =0;
		}

		if (hall_flg == 0 && hall_state != 0 )
		{
			hall_flg = 1;
		}

		if(hall_flg !=0 )
		{
			tempcount++;
			if(tempcount >= 200)
			{
				speed = 0;
				tempcount =0;
			}
		}
		else if(hall_flg == 0 )
		{
			tempcount1++;
			if(tempcount1 >= 200)
			{
				speed = 0;
				tempcount1 =0;
			}
		}
		if (flag)
		{
			high_chan = bldc_high_seq[hall_state];
			/* do output */
			p_pwm_lo[0] <: bldc_ph_a_lo[hall_state];
			p_pwm_lo[1] <: bldc_ph_b_lo[hall_state];
			p_pwm_lo[2] <: bldc_ph_c_lo[hall_state];
		}
		else
		{
			high_chan = bldc_high_seq1[hall_state];
			/* do output */
			p_pwm_lo[0] <: bldc_ph_a_lo1[hall_state];
			p_pwm_lo[1] <: bldc_ph_b_lo1[hall_state];
			p_pwm_lo[2] <: bldc_ph_c_lo1[hall_state];
		}
		update_pwm( c_pwm, pwm_val, high_chan );
	}
}
