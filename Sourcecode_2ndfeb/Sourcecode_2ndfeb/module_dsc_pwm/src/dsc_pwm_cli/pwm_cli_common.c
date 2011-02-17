/**
 * Module:  module_dsc_pwm
 * Version: 1v0alpha1
 * Build:   1c0d37662e0881e71e5aeb8e90c3c0b660c318c6
 * File:    pwm_cli_common.c
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
#include "pwm_cli_common.h"
#include "dsc_pwm_common.h"
#include "dsc_config.h"
#include <print.h>

unsigned pwm_val[PWM_CHAN_COUNT];

extern unsigned chan_id_buf[2][PWM_CHAN_COUNT];
extern unsigned mode_buf[2];
extern t_out_data pwm_out_data_buf[2][PWM_CHAN_COUNT];
extern unsigned pwm_cur_buf;

void init_pwm_vals( )
{
	for (int i = 0; i < PWM_CHAN_COUNT; i++)
		pwm_val[i] = 0;
}

void print_pwm_out( t_out_data pwm_out_data[] )
{
	printstr("[0].ts0 = "); printuintln(pwm_out_data[0].ts0);
	printstr("[1].ts0 = "); printuintln(pwm_out_data[1].ts0);
	printstr("[2].ts0 = "); printuintln(pwm_out_data[2].ts0);

	printstr("[0].out0 = "); printhexln(pwm_out_data[0].out0);
	printstr("[1].out0 = "); printhexln(pwm_out_data[1].out0);
	printstr("[2].out0 = "); printhexln(pwm_out_data[2].out0);

	printstr("[0].ts1 = "); printuintln(pwm_out_data[0].ts1);
	printstr("[1].ts1 = "); printuintln(pwm_out_data[1].ts1);
	printstr("[2].ts1 = "); printuintln(pwm_out_data[2].ts1);

	printstr("[0].out1 = "); printhexln(pwm_out_data[0].out1);
	printstr("[1].out1 = "); printhexln(pwm_out_data[1].out1);
	printstr("[2].out1 = "); printhexln(pwm_out_data[2].out1);

	printstr("[0].inv_ts0 = "); printuintln(pwm_out_data[0].inv_ts0);
	printstr("[1].inv_ts0 = "); printuintln(pwm_out_data[1].inv_ts0);
	printstr("[2].inv_ts0 = "); printuintln(pwm_out_data[2].inv_ts0);

	printstr("[0].inv_out0 = "); printhexln(pwm_out_data[0].inv_out0);
	printstr("[1].inv_out0 = "); printhexln(pwm_out_data[1].inv_out0);
	printstr("[2].inv_out0 = "); printhexln(pwm_out_data[2].inv_out0);

	printstr("[0].inv_ts1 = "); printuintln(pwm_out_data[0].inv_ts1);
	printstr("[1].inv_ts1 = "); printuintln(pwm_out_data[1].inv_ts1);
	printstr("[2].inv_ts1 = "); printuintln(pwm_out_data[2].inv_ts1);

	printstr("[0].inv_out1 = "); printhexln(pwm_out_data[0].inv_out1);
	printstr("[1].inv_out1 = "); printhexln(pwm_out_data[1].inv_out1);
	printstr("[2].inv_out1 = "); printhexln(pwm_out_data[2].inv_out1);

	printstr("[0].cat = "); printuintln(pwm_out_data[0].cat);
	printstr("[1].cat = "); printuintln(pwm_out_data[1].cat);
	printstr("[2].cat = "); printuintln(pwm_out_data[2].cat);
}


/*
 * Used by INV and NOINV modes
 */
void order_pwm( unsigned *mode, unsigned *chan_id, t_out_data *pwm_out_data)
{
	unsigned chan_id_tmp;
	unsigned sngle = 0, long_single = 0, dble = 0;
	int e_check = 0;


	for (int i = 0; i < PWM_CHAN_COUNT; i++)
	{
		switch(pwm_out_data[i].cat)
		{
		case SINGLE:
			sngle++;
			break;
		case DOUBLE:
			dble++;
			break;
		case LONG_SINGLE:
			long_single++;
			break;
		}
	}

	if (sngle == 3)
	{
		*mode = 1;
		return;
	}

	if (long_single == 1 && sngle == 2)
	{
		*mode = 7;
		/* need to find the long single and put it first */
		for (int i = 0; i < PWM_CHAN_COUNT; i++)
		{
			if (pwm_out_data[i].cat == LONG_SINGLE && i != 0)
			{
				if (i != 0)
				{

					chan_id_tmp = chan_id[0];
					chan_id[0] = chan_id[i];
					chan_id[i] = chan_id_tmp;
				}
				return;
			}
		}
		printstr("PWM ERROR 1\n");
		e_check = 1;
		asm("ecallt %0" : "=r"(e_check));
	}

	if (dble == 1 && sngle == 2)
	{
		*mode = 2;
		/* need to find the double and put it first */
		for (int i = 1; i < PWM_CHAN_COUNT; i++)
		{
			if (pwm_out_data[i].cat == DOUBLE )
			{

				chan_id_tmp = chan_id[0];
				chan_id[0] = chan_id[i];
				chan_id[i] = chan_id_tmp;

				return;
			}
		}
		printstr("PWM ERROR 2\n");
		e_check = 1;
		asm("ecallt %0" : "=r"(e_check));
	}

	if (dble == 2 && sngle == 1)
	{
		*mode = 3;
		/* need to find the single and put it last */
		for (int i = 0; i < PWM_CHAN_COUNT; i++)
		{
			if (pwm_out_data[i].cat == SINGLE )
			{
				if (i != PWM_CHAN_COUNT-1)
				{
//					swap_pwm_data( pwm_out_data[PWM_CHAN_COUNT-1], pwm_out_data[i] );

					chan_id_tmp = chan_id[PWM_CHAN_COUNT-1];
					chan_id[PWM_CHAN_COUNT-1] = chan_id[i];
					chan_id[i] = chan_id_tmp;
				}
			}
		}

		/* now order by length, only go as far as last but one - it is already in the right place */
		for (int i = 0; i < PWM_CHAN_COUNT-2; i++) /* start point loop */
		{
			unsigned max_index = i;
			for (int j = i+1; j < PWM_CHAN_COUNT-1; j++)
			{
				if (pwm_out_data[j].value > pwm_out_data[max_index].value)
					max_index = j;
			}

			/* swap if we need to, but it might be in the right place */
			if (max_index != i)
			{
//				swap_pwm_data( pwm_out_data[max_index], pwm_out_data[i] );

				chan_id_tmp = chan_id[i];
				chan_id[i] = chan_id[max_index];
				chan_id[max_index] = chan_id_tmp;
			}

		}
		return;
	}

	if (dble == 3)
	{
		*mode = 4;

		/* now order by length*/
		for (int i = 0; i < PWM_CHAN_COUNT-1; i++) /* start point loop */
		{
			unsigned max_index = i;
			for (int j = i+1; j < PWM_CHAN_COUNT; j++)
			{
				if (pwm_out_data[j].value > pwm_out_data[max_index].value)
					max_index = j;
			}

			/* swap if we need to, but it might be in the right place */
			if (max_index != i)
			{
//				swap_pwm_data( pwm_out_data[max_index], pwm_out_data[i] );

				chan_id_tmp = chan_id[i];
				chan_id[i] = chan_id[max_index];
				chan_id[max_index] = chan_id_tmp;
			}

		}
		return;
	}

	if (long_single == 1 && dble == 1 && sngle == 1)
	{
		*mode = 5;

		/* need to find the single and put it last */
		for (int i = 0; i < PWM_CHAN_COUNT; i++)
		{
			if (pwm_out_data[i].cat == SINGLE )
			{
				if (i != PWM_CHAN_COUNT-1)
				{
//					swap_pwm_data( pwm_out_data[PWM_CHAN_COUNT-1], pwm_out_data[i] );

					chan_id_tmp = chan_id[PWM_CHAN_COUNT-1];
					chan_id[PWM_CHAN_COUNT-1] = chan_id[i];
					chan_id[i] = chan_id_tmp;
				}
			}
		}

		/* need to find the double and put it in the middle */
		for (int i = 0; i < PWM_CHAN_COUNT; i++)
		{
			if (pwm_out_data[i].cat == DOUBLE )
			{
				// TODO: assumes 3 channel
				if (i != 1)
				{
//					swap_pwm_data( pwm_out_data[1], pwm_out_data[i] );

					chan_id_tmp = chan_id[1];
					chan_id[1] = chan_id[i];
					chan_id[i] = chan_id_tmp;
				}
			}
		}

		/* long single should be first by definition */
		e_check = (pwm_out_data[0].cat != LONG_SINGLE);
		printstr("PWM ERROR 3\n");
		asm("ecallt %0" : "=r"(e_check));

		return;
	}

	if (long_single == 1 && dble == 2)
	{
		*mode = 6;

		/* need to find the long single and put it first */
		for (int i = 0; i < PWM_CHAN_COUNT; i++)
		{
			if (pwm_out_data[i].cat == LONG_SINGLE )
			{
				if (i != 0)
				{
//					swap_pwm_data( pwm_out_data[0], pwm_out_data[i] );

					chan_id_tmp = chan_id[0];
					chan_id[0] = chan_id[i];
					chan_id[i] = chan_id_tmp;
				}
			}
		}

		/* need to find the double and put it in the middle */
		for (int i = 0; i < PWM_CHAN_COUNT; i++)
		{
			if (pwm_out_data[i].cat == DOUBLE )
			{
				if (i != 1) // TODO: assumes 3 channel
				{
//					swap_pwm_data( pwm_out_data[1], pwm_out_data[i] );

					chan_id_tmp = chan_id[1];
					chan_id[1] = chan_id[i];
					chan_id[i] = chan_id_tmp;
				}
			}
		}

		/* long single should be first by definition */
		e_check = (pwm_out_data[0].cat != LONG_SINGLE);
		printstr("PWM ERROR 4\n");
		asm("ecallt %0" : "=r"(e_check));


		return;
	}
}


void calculate_data_out( unsigned value, t_out_data *pwm_out_data )
{
	pwm_out_data->out1 = 0;
	pwm_out_data->ts1 = 0;
	pwm_out_data->inv_out1 = 0;
	pwm_out_data->inv_ts1 = 0;

	// very low values
	if (value <= 31)
	{
		pwm_out_data->cat = SINGLE;
		// compiler work around, bug 8218
		/* pwm_out_data.out0 = ((1 << value)-1);  */
		asm("mkmsk %0, %1"
				: "=r"(pwm_out_data->out0)
				: "r"(value));
		pwm_out_data->out0 <<= (value >> 1); // move it to the middle

		pwm_out_data->ts0 = 16;
		return;
	}

	// close to PWM_MAX_VALUE
	if (value >= (PWM_MAX_VALUE-31))
	{
		unsigned tmp;
		pwm_out_data->cat = LONG_SINGLE;
		tmp = PWM_MAX_VALUE - value; // number of 0's
		tmp = 32 - tmp; // number of 1's

		// compiler work around, bug 8218
		/* pwm_out_data.out0 = ((1 << value)-1);  */
		asm("mkmsk %0, %1"
				: "=r"(pwm_out_data->out0)
		  	    : "r"(tmp));

		pwm_out_data->out0 <<= (32 - tmp);
		pwm_out_data->ts0 = (PWM_MAX_VALUE >> 1) + ((PWM_MAX_VALUE - value) >> 1); // MAX + (num 0's / 2)
		return;
	}

	// low mid range
	if (value < 64)
	{
		unsigned tmp;
		pwm_out_data->cat = DOUBLE;

		if (value == 63)
			tmp = 32;
		else
			tmp = value >> 1;

		// compiler work around, bug 8218
		/* pwm_out_data.out0 = ((1 << (value >> 1))-1);  */
		asm("mkmsk %0, %1"
				: "=r"(pwm_out_data->out0)
				: "r"(tmp));


		tmp = value - tmp;

		// compiler work around, bug 8218
		asm("mkmsk %0, %1"
				: "=r"(pwm_out_data->out1)
				: "r"(tmp));
		/* pwm_out_data.out1 = ((1 << (value - (value >> 1)))-1);  */

		pwm_out_data->ts0 = 32;
		pwm_out_data->ts1 = 0;
		return;
	}

	// midrange
	pwm_out_data->cat = DOUBLE;
	pwm_out_data->out0 = 0xFFFFFFFF;
	pwm_out_data->out1 = 0x7FFFFFFF;

	pwm_out_data->ts0 = (value >> 1);
	pwm_out_data->ts1 = (value >> 1)-31;

}

void calculate_data_out_ref( unsigned value, unsigned *ts0, unsigned *out0, unsigned *ts1, unsigned *out1, e_pwm_cat *cat )
{
	*out1 = 0;
	*ts1 = 0;

	// very low values
	if (value < 32)
	{
		*cat = SINGLE;
		// compiler work around, bug 8218
		/* pwm_out_data.out0 = ((1 << value)-1);  */
		asm("mkmsk %0, %1"
				: "=r"(*out0)
				: "r"(value));
		*out0 <<= 16-(value >> 1); // move it to the middle
		*ts0 = 16;

		/* DOUBLE mode safe values */
		*out1 = 0;
		*ts1 = 100;

		return;
	}

	// close to PWM_MAX_VALUE
	/* Its pretty impossible to apply dead time to values this high... so update function should clamp the values to
	 * PWM_MAX - (31+PWM_DEAD_TIME)
	 */
	if (value >= (PWM_MAX_VALUE-31))
	{
		unsigned tmp;
		*cat = LONG_SINGLE;
		tmp = PWM_MAX_VALUE - value; // number of 0's
		tmp = 32 - tmp; // number of 1's

		// compiler work around, bug 8218
		/* pwm_out_data.out0 = ((1 << value)-1);  */
		asm("mkmsk %0, %1"
				: "=r"(*out0)
		  	    : "r"(tmp));

		*out0 <<= (32 - tmp);
		*ts0 = (PWM_MAX_VALUE >> 1) + ((PWM_MAX_VALUE - value) >> 1); // MAX + (num 0's / 2)
		return;
	}

	// low mid range
	if (value < 64)
	{
		unsigned tmp;
		*cat = DOUBLE;

		if (value == 63)
			tmp = 32;
		else
			tmp = value >> 1;

		// compiler work around, bug 8218
		/* pwm_out_data.out0 = ((1 << (value >> 1))-1);  */
		asm("mkmsk %0, %1"
				: "=r"(*out0)
				: "r"(tmp));

		/* pwm_out_data.out1 = ((1 << (value - (value >> 1)))-1);  */
		// compiler work around, bug 8218
		tmp = value - tmp;
		asm("mkmsk %0, %1"
				: "=r"(*out1)
				: "r"(tmp));

		*ts0 = 32;
		*ts1 = 0;
		return;
	}

	// midrange
	*cat = DOUBLE;
	*out0 = 0xFFFFFFFF;
	*out1 = 0x7FFFFFFF;

	*ts0 = (value >> 1);
	*ts1 = (value >> 1)-31;

}

