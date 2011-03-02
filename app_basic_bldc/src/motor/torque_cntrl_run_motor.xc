/**
 * Module:  app_basic_bldc
 * Version: 1v1
 * Build:
 * File:    torque_cntrl_run_motor.xc
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



#include "torque_cntrl_run_motor.h"

/* number of pole pairs are TWO so we are defining that below*/
#define MOTOR_POLE_PAIRS (NUMBER_OF_POLES>>1)
/*
 *torque_cotrolled_run_motor1() function uses hall sensor outputs and finds hall_state. Based on
 *the hall state it identifies the rotor position and give the commutation
 *sequence to Upper and Lower IGBT's  then it calculates speed and updates PWM
 *values. This funcntion uses three channels c_wd for watchdog timer, c_control
 *to update speed, pwm, lower IGBT state changes and direction flag values
 *between the threads for motor 1.
 **/

/* counter clockwise direction commutation sequence for low side of bridge */
unsigned bldc_ph_a_lo[6] = {0,1,1,0,0,0};
unsigned bldc_ph_b_lo[6] = {0,0,0,1,1,0};
unsigned bldc_ph_c_lo[6] = {1,0,0,0,0,1};
/* counter clockwise direction commutation sequence for high side of bridge */
const unsigned bldc_high_seq[6] = {1,1,2,2,0,0};
/* clockwise direction commutation sequence for low side of bridge */
unsigned bldc_ph_a_lo1[6] = {0,0,0,0,1,1};
unsigned bldc_ph_b_lo1[6] = {1,1,0,0,0,0};
unsigned bldc_ph_c_lo1[6] = {0,0,1,1,0,0};
/* clockwise direction commutation sequence for high side of bridge */
const unsigned bldc_high_seq1[6] = {2,0,0,1,1,2};

void torque_cotrolled_run_motor1 ( chanend c_wd, chanend c_pwm, chanend c_control, port in p_hall, port out p_pwm_lo[])
{
	unsigned high_chan, hall_state = 0, pin_state = 0, pwm_val = 240, dir_flag=1;
	unsigned ts, ts0, delta_t, speed = 0, hall_flg = 1, cmd;
	unsigned state0 = 0, statenot0 =0, igbt_state =0;

	/* 32 bit timer declaration */
	timer t;
	t :> ts;
	/* delay function for 1 sec */
	t when timerafter(ts+100000000) :> ts;
	/* allow the WD to get going and enable motor */
	c_wd <: WD_CMD_START;

	/* main loop */
	while (1)
	{
		select
		{
		/* wait for a change in the hall sensor - this is what this update loop is locked to */
		case do_hall_select( hall_state, pin_state, p_hall );
		/* if we get a change in PWM value (i.e. current) then update it.. */

		case c_control :> cmd:
			switch (cmd)
			{
		/* updates speed changes */
			case 1:
				c_control <: speed;
				break;

		/* upadates pwm values */
			case 2:
				c_control :> pwm_val;
				break;

		/* upadates direction changes of motor rotation based on Button C */
			case 4:
				c_control :> dir_flag;
				break;

		/* the lower IGBT state changing sequence when the motor starts running */
			case 5:
				c_control <: igbt_state;
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
			speed = 3000000000 / ( delta_t );
			speed = speed * 2;
			hall_flg = 0;
			state0 = 0;
			statenot0 =0;
		}

		if (hall_flg == 0 && hall_state != 0 )
			hall_flg = 1;

		if(hall_flg !=0 )
		{
			state0++;
			if(state0 >= 200)
			{
				speed = 0;
				state0 =0;
			}
		}
		else if(hall_flg == 0 )
		{
			statenot0++;
			if(statenot0 >= 200)
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
		/* This states are used to send Ia, Ib, or Ic as feed back current in
		 * speed control thread */
			if(bldc_ph_a_lo[hall_state] == 1)
				igbt_state =1;
			if (bldc_ph_b_lo[hall_state] ==1)
				igbt_state =2;
			if (bldc_ph_c_lo[hall_state] == 1)
				igbt_state =3;
		}
		else
		{
			high_chan = bldc_high_seq1[hall_state];
		/* do output and switch on the IGBT's */
			p_pwm_lo[0] <: bldc_ph_a_lo1[hall_state];
			p_pwm_lo[1] <: bldc_ph_b_lo1[hall_state];
			p_pwm_lo[2] <: bldc_ph_c_lo1[hall_state];
		/* This states are used to send Ia, Ib, or Ic as feed back current in
		 * speed control thread */
			if(bldc_ph_a_lo1[hall_state] == 1)
				igbt_state =1;
			if (bldc_ph_b_lo1[hall_state] ==1)
				igbt_state =2;
			if (bldc_ph_c_lo1[hall_state] == 1)
				igbt_state =3;
		}

		/* updates pwm_val */
		update_pwm1( c_pwm, pwm_val, high_chan );

	}
}

/*
 *torque_cotrolled_run_motor2() function uses hall sensor outputs and finds hall_state. Based on
 *the hall state it identifies the rotor position and give the commutation
 *sequence to Upper and Lower IGBT's  then it calculates speed and updates PWM
 *values. This funcntion uses three channels c_wd for watchdog timer, c_control
 *to update speed, pwm, lower IGBT state changes and direction flag values
 *between the threads for motor 2.
 **/

void torque_cotrolled_run_motor2 ( chanend c_pwm2, chanend c_control2, port in p_hall2, port out p_pwm_lo2[])
{
	unsigned high_chan, hall_state = 0, pin_state = 0, pwm_val = 240, dir_flag=1;
	unsigned ts, ts0, delta_t, speed = 0, hall_flg = 1, cmd;
	unsigned state0 = 0, statenot0 =0, igbt_state =0;

	/* 32 bit timer declaration */
	timer t;
	t :> ts;
	/* delay function for 1 sec */
	t when timerafter(ts+100000000) :> ts;
	/* allow the WD to get going and enable motor */

	/* main loop */
	while (1)
	{
		select
		{
		/* wait for a change in the hall sensor - this is what this update loop is locked to */
		case do_hall_select( hall_state, pin_state, p_hall2 );
		/* if we get a change in PWM value (i.e. current) then update it.. */

		case c_control2 :> cmd:
			switch (cmd)
			{
		/* updates speed changes */
			case 1:
				c_control2 <: speed;
				break;

		/* upadates pwm values */
			case 2:
				c_control2 :> pwm_val;
				break;

		/* upadates direction changes of motor rotation based on Button C */
			case 7:
				c_control2 :> dir_flag;
				break;

		/* the lower IGBT state changing sequence when the motor starts running */
			case 5:
				c_control2 <: igbt_state;
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
			speed = 3000000000 / ( delta_t );
			speed = speed * 2;
			hall_flg = 0;
			state0 = 0;
			statenot0 =0;
		}

		if (hall_flg == 0 && hall_state != 0 )
			hall_flg = 1;

		if(hall_flg !=0 )
		{
			state0++;
			if(state0 >= 200)
			{
				speed = 0;
				state0 =0;
			}
		}
		else if(hall_flg == 0 )
		{
			statenot0++;
			if(statenot0 >= 200)
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
			p_pwm_lo2[0] <: bldc_ph_a_lo[hall_state];
			p_pwm_lo2[1] <: bldc_ph_b_lo[hall_state];
			p_pwm_lo2[2] <: bldc_ph_c_lo[hall_state];
		/* This states are used to send Ia, Ib, or Ic as feed back current in
		 * speed control thread */
			if(bldc_ph_a_lo[hall_state] == 1)
				igbt_state =1;
			if (bldc_ph_b_lo[hall_state] ==1)
				igbt_state =2;
			if (bldc_ph_c_lo[hall_state] == 1)
				igbt_state =3;
		}
		else
		{
			high_chan = bldc_high_seq1[hall_state];
		/* do output and switch on the IGBT's */
			p_pwm_lo2[0] <: bldc_ph_a_lo1[hall_state];
			p_pwm_lo2[1] <: bldc_ph_b_lo1[hall_state];
			p_pwm_lo2[2] <: bldc_ph_c_lo1[hall_state];
		/* This states are used to send Ia, Ib, or Ic as feed back current in
		 * speed control thread */
			if(bldc_ph_a_lo1[hall_state] == 1)
				igbt_state =1;
			if (bldc_ph_b_lo1[hall_state] ==1)
				igbt_state =2;
			if (bldc_ph_c_lo1[hall_state] == 1)
				igbt_state =3;
		}

		/* updates pwm_val */
		update_pwm2( c_pwm2, pwm_val, high_chan );

	}
}
