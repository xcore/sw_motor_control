/**
 * Module:  module_dsc_hall
 * Version: 1v0alpha2
 * Build:   280fc2259bcf2719c6b83e517d854c7666e0c448
 * File:    hall_input.xc
 * Modified by : Upendra
 * Last Modified on : 01-Jul-2011
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
#include "hall_input.h"
#include "pos_estimator.h"
#include <stdlib.h>
#include "dsc_config.h"
#include <print.h>

/* Hall lookup table 							Hall      => Sector
	NB These are in "grey-code order" */
const unsigned hall_pos[8] = { 	HALL_INV,	/* 0bx000 = 0 => INVALID */
								2,			/* 0bx001 = 1 => 0 */
								4,			/* 0bx010 = 2 => 4 */
								3,			/* 0bx011 = 3 => 5 */
								0,			/* 0bx100 = 4 => 2 */
								1,			/* 0bx101 = 5 => 1 */
								5,			/* 0bx110 = 6 => 3 */
								HALL_INV };	/* 0bx111 = 7 => INVALID */

const unsigned rev_pos[6] = { 	0b0001,		/* 0bx001 <= 0 */
				  				0b0101,		/* 0bx101 <= 1 */
								0b0100,		/* 0bx100 <= 2 */
								0b0110,		/* 0bx110 <= 3 */
								0b0010,		/* 0bx010 <= 4 */
								0b0011 };	/* 0bx011 <= 5 */

void do_hall( unsigned &hall_state, unsigned &cur_pin_state, port in p_hall )
{
	p_hall when pinsneq(cur_pin_state) :> cur_pin_state;
	/* alert channel listener we got a change in state */
	hall_state = hall_pos[cur_pin_state & 0b111];
}

select do_hall_select( unsigned &hall_state, unsigned &cur_pin_state, port in p_hall )
{
	case p_hall when pinsneq(cur_pin_state) :> cur_pin_state:
	/* alert channel listener we got a change in state */
	hall_state = hall_pos[cur_pin_state & 0b111];
	break;
}

void run_hall_speed_timed( chanend c_hall, chanend c_speed, port in p_hall, chanend ?c_logging_0, chanend ?c_logging_1  )
{
	timer t;
	unsigned ts;
	unsigned pin_state, next_pin_state;
	unsigned cur_state, new_state;
	unsigned speed = 0, theta = 0, frac = 0;
	int tmp;
	unsigned cmd;

	/* timestamps of current and previous edges */
	unsigned tz = 0;
	unsigned t0 = 0;
	unsigned delta_t = 0;

	/* timings for speed, this will wait for 1 mechanical rotation for timing */
	unsigned speed_tz = 0;
	unsigned speed_t0 = 0;
	unsigned speed_delta_t = 0;
	unsigned cur_elec_rot = 0;

	/* last calculated value when in the sector */
	unsigned base;
	unsigned limit[6] = {600, 1200, 1900, 2400, 3000, 0};
//	unsigned limit[6] = {602, 1237, 1795, 2416, 3024, 0};
	unsigned update = 0;

	/* init */
	set_port_pull_down(p_hall);
	p_hall :> pin_state;
	cur_state = hall_pos[pin_state & 0b111];

	// Code below is a fudge to stop an exception caused by stepping off the end of the array.
	if (cur_state == HALL_INV)
	{
		printstr("Invalid hall state detected...\n");
		printuintln(pin_state);
		exit(1);
	}

	theta = limit[cur_state];

	if (cur_state == 5)
		next_pin_state = rev_pos[0];
	else
		next_pin_state = rev_pos[cur_state+1];

	/* startup sequence */
	for (int i = 0; i < 2;)
	{
		select
		{
//		case p_hall when pinsneq(pin_state) :> pin_state:
		case p_hall when pinseq(next_pin_state) :> pin_state:

			cur_state = hall_pos[pin_state & 0b111]; // update current state
			if (cur_state == 5)
				next_pin_state = rev_pos[0];
			else
				next_pin_state = rev_pos[cur_state+1];

			base = theta; // save base angle

			tz = t0; // save last ts
			t :> t0; // get new ts for this point

			delta_t = t0 - tz; // calculate time delta for 60 deg

			i++;
			break;
		case c_hall :> cmd:
			theta += 1;

			if (theta >= 3600)
				theta -= 3600;

			c_hall <: theta;
			c_hall <: speed;
			c_hall <: limit[cur_state];
			break;
		case c_speed :> cmd:
			c_speed <: delta_t;
			break;
		}

	}

	// Main hall loop
	while (1)
	{
		select
		{
			case p_hall when pinseq(next_pin_state) :> pin_state:
				t :> ts;
				
				new_state = hall_pos[pin_state & 0b111];
				
				//theta = ((int)(ts - t0) * ((limit[new_state] - limit[cur_state] + 3600)%3600) ) / delta_t;
				theta = ((int)(ts - t0) * 600 ) / delta_t;
				theta = theta + base;

				while (theta >= 3600)
					theta -= 3600;

				cur_state = new_state; // update current state
				
				/* update next state to wait for... means we can't accidentally skip or go the wrong direction
				 * but not great if a hall sensor fails
				 */
				if (cur_state == 5)
					next_pin_state = rev_pos[0];
				else
					next_pin_state = rev_pos[cur_state+1];

				/* speed timing */
				if (cur_state == 2)
				{
					/* update speed time if we have done a complete mechanical rotation*/
					if (cur_elec_rot == NUMBER_OF_POLES)
					{
						speed_tz = speed_t0;
						speed_t0 = ts;
						speed_delta_t = speed_t0 - speed_tz;
						cur_elec_rot = 0;
					}
					else
						cur_elec_rot += 1;

				}

				if (cur_state == 2)
				{
					if (update == 1)
					{
						// calibrate position -> state 2 == 180 deg, plus some error (~10deg?)
						int diff = limit[2] - theta;
						base = theta + ((diff*4)>>3) ;
						update = 0;
					}
					else {
						update = 1;
						base = theta;
					}
				}
				else
				{
						base = theta; // save base angle
						update = 0;
				}


				tz = t0; // save last ts at this point
				t :> t0; // get new ts for this point

				delta_t = t0 - tz; // calculate time delta for 360 deg
				break;
			case t when timerafter(speed_t0+5000000) :> ts: /* time out for RPM */
				speed_delta_t = 0xFFFFFFFF; /* will force RPM to 0 */
				break;
			case c_hall :> cmd:

				tmp = (int)(ts - t0) * 600 + frac;
				theta = tmp / delta_t;
				frac = tmp % delta_t;
				theta += base;

				while (theta >= 3600)
					theta -= 3600;

				if (speed_delta_t == 0)
					speed = 0;
				else
				{
					speed = 3000000000 / speed_delta_t;
					speed <<= 1;
				}

				c_hall <: theta;
				c_hall <: speed;
				c_hall <: limit[cur_state];
				break;
			case c_speed :> cmd:
				c_speed <: speed_delta_t;
				break;
		}
	}

}
