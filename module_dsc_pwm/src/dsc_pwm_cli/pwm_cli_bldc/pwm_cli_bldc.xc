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

void update_pwm( t_pwm_control& ctrl, chanend c, unsigned value, unsigned pwm_chan )
{
	/* update the buffer we write to */
	if (ctrl.pwm_cur_buf == 0)
		ctrl.pwm_cur_buf = 1;
	else ctrl.pwm_cur_buf = 0;

	/* get active channels and load into buffer */
	ctrl.chan_id_buf[ctrl.pwm_cur_buf] = pwm_chan;

	/* calculate the required outputs */
	calculate_data_out( value, ctrl.pwm_out_data_buf[ctrl.pwm_cur_buf] );

	/* now order them and work out the mode */
	order_pwm_bldc( ctrl.mode_buf[ctrl.pwm_cur_buf], ctrl.chan_id_buf[ctrl.pwm_cur_buf], ctrl.pwm_out_data_buf[ctrl.pwm_cur_buf] );

	/* trigger update */
	c <: ctrl;
}

#endif
