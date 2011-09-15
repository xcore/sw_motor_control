/**
 * Module:  module_dsc_pwm
 * Version: 1v0alpha1
 * Build:   1c0d37662e0881e71e5aeb8e90c3c0b660c318c6
 * File:    pwm_cli_inv.xc
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
#include "pwm_cli_inv.h"
#include "dsc_config.h"

void update_pwm_inv( t_pwm_control& ctrl, chanend c, unsigned value[])
{
	unsigned pwm_val[PWM_CHAN_COUNT];

	/* update buffer value for next calculation */
	if (ctrl.pwm_cur_buf == 1) {
		ctrl.pwm_cur_buf = 0;
	} else {
		ctrl.pwm_cur_buf = 1;
	}

	/* store new values */
	for (int pwm_chan = 0; pwm_chan < PWM_CHAN_COUNT; pwm_chan++)
		pwm_val[pwm_chan] = value[pwm_chan];

	/* initialise PWM channel list */
	for (int i = 0; i < PWM_CHAN_COUNT; i++) {
		ctrl.chan_id_buf[ctrl.pwm_cur_buf][i] = i;
	}

	/* calculate the required outputs */
	for (int i = 0; i < PWM_CHAN_COUNT; i++) {
		/* clamp to avoid issues with LONG_SINGLE */
		if (pwm_val[i] > (PWM_MAX_VALUE - (32+PWM_DEAD_TIME))) {
			pwm_val[i] = (PWM_MAX_VALUE - (32+PWM_DEAD_TIME));
		}
		calculate_data_out_ref( pwm_val[i],
				ctrl.pwm_out_data_buf[ctrl.pwm_cur_buf][i].ts0,
				ctrl.pwm_out_data_buf[ctrl.pwm_cur_buf][i].out0,
				ctrl.pwm_out_data_buf[ctrl.pwm_cur_buf][i].ts1,
				ctrl.pwm_out_data_buf[ctrl.pwm_cur_buf][i].out1,
				ctrl.pwm_out_data_buf[ctrl.pwm_cur_buf][i].cat );
		calculate_data_out_ref( (pwm_val[i]+PWM_DEAD_TIME),
				ctrl.pwm_out_data_buf[ctrl.pwm_cur_buf][i].inv_ts0,
				ctrl.pwm_out_data_buf[ctrl.pwm_cur_buf][i].inv_out0,
				ctrl.pwm_out_data_buf[ctrl.pwm_cur_buf][i].inv_ts1,
				ctrl.pwm_out_data_buf[ctrl.pwm_cur_buf][i].inv_out1,
				ctrl.pwm_out_data_buf[ctrl.pwm_cur_buf][i].cat );
	}

	/* now order them and work out the mode */
	order_pwm( ctrl.mode_buf[ctrl.pwm_cur_buf], ctrl.chan_id_buf[ctrl.pwm_cur_buf], ctrl.pwm_out_data_buf[ctrl.pwm_cur_buf] );

	if (ctrl.mode_buf[ctrl.pwm_cur_buf] < 1 || ctrl.mode_buf[ctrl.pwm_cur_buf] > 7 ) {
		unsigned e_check = 1;
		asm("ecallt %0" : "=r"(e_check));
	}

	c <: ctrl.pwm_cur_buf;
}

