/**
 * Module:  module_dsc_pwm
 * Version: 1v1
 * Build:
 * File:    pwm_cli_bldc.xc
 * Author: 	Srikanth
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
#include "pwm_cli_bldc.h"

#ifdef PWM_BLDC_MODE
	extern unsigned chan_id_buf[2];
	extern unsigned mode_buf[2];
	extern t_out_data pwm_out_data_buf[2];
	extern unsigned pwm_cur_buf;

	extern unsigned chan_id_buf2[2];
	extern unsigned mode_buf2[2];
	extern t_out_data pwm_out_data_buf2[2];
	extern unsigned pwm_cur_buf2;


/* Note: This function will only look at 1 channel */
static void order_pwm_bldc( unsigned &mode, unsigned &chan_id, t_out_data pwm_out_data)
{
	switch(pwm_out_data.cat)
	{
	case SINGLE:
		mode = 1;
		break;
	case DOUBLE:
		mode = 2;
		break;
	case LONG_SINGLE:
		mode = 1;
		break;
	}
}

void update_pwm1( chanend c, unsigned value, unsigned pwm_chan )
{
	/* update the buffer we write to */
	if (pwm_cur_buf == 0)
		pwm_cur_buf = 1;
	else pwm_cur_buf = 0;

	/* get active channels and load into buffer */
	chan_id_buf[pwm_cur_buf] = pwm_chan;

	/* calculate the required outputs */
	calculate_data_out( value, pwm_out_data_buf[pwm_cur_buf] );

	/* now order them and work out the mode */
	order_pwm_bldc( mode_buf[pwm_cur_buf], chan_id_buf[pwm_cur_buf], pwm_out_data_buf[pwm_cur_buf] );

	/* trigger update */
	c <: pwm_cur_buf;
}

void update_pwm2( chanend c2, unsigned value2, unsigned pwm_chan2 )
{
	/* update the buffer we write to */
	if (pwm_cur_buf2 == 0)
		pwm_cur_buf2 = 1;
	else pwm_cur_buf2 = 0;

	/* get active channels and load into buffer */
	chan_id_buf2[pwm_cur_buf2] = pwm_chan2;

	/* calculate the required outputs */
	calculate_data_out( value2, pwm_out_data_buf2[pwm_cur_buf2] );

	/* now order them and work out the mode */
	order_pwm_bldc( mode_buf2[pwm_cur_buf2], chan_id_buf2[pwm_cur_buf2], pwm_out_data_buf2[pwm_cur_buf2] );

	/* trigger update */
	c2 <: pwm_cur_buf2;
}
#endif
