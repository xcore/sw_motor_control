/**
 * Module:  module_dsc_pwm
 * Version: 0v9sd
 * Build:   55b0e052aa4b17ec7f8cae79c0d68f82e9fcab33
 * File:    pwm_service_noinv.xc
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
#include "pwm_service_noinv.h"

/*
 * Assembly PWM operation loop
 */
extern unsigned pwm_op_noinv( unsigned chan_id0, unsigned chan_id1, unsigned chan_id2,
		t_out_data data0, t_out_data data1, t_out_data data2, unsigned mode,
		buffered out port:32 p_pwm[], chanend c );

/*
 * Port configuration
 */
static void do_pwm_port_config_noinv(  buffered out port:32 p_pwm[], clock clk )
{
	unsigned i;

	configure_clock_rate(clk, 50, 1);

	for (i = 0; i < PWM_CHAN_COUNT; i++)
	{
		configure_out_port(p_pwm[i], clk, 0);
	}

	start_clock(clk);
}

void do_pwm_noinv( chanend c_pwm, buffered out port:32 p_pwm[],  clock clk)
{
	t_out_data pwm_out_data0, pwm_out_data1, pwm_out_data2;
	unsigned mode;
	unsigned chan_id0, chan_id1, chan_id2;

	do_pwm_port_config_noinv( p_pwm, clk);

	/* wait for initial update */
	c_pwm :> mode;


	while (1)
	{
		slave
		{
			/* get ordered pwm channels */
			c_pwm :> chan_id0;
			c_pwm :> chan_id1;
			c_pwm :> chan_id2;

			/* get channel information */
			c_pwm :> pwm_out_data0.ts0;
			c_pwm :> pwm_out_data0.out0;
			c_pwm :> pwm_out_data0.ts1;
			c_pwm :> pwm_out_data0.out1;

			c_pwm :> pwm_out_data1.ts0;
			c_pwm :> pwm_out_data1.out0;
			c_pwm :> pwm_out_data1.ts1;
			c_pwm :> pwm_out_data1.out1;


			c_pwm :> pwm_out_data2.ts0;
			c_pwm :> pwm_out_data2.out0;
			c_pwm :> pwm_out_data2.ts1;
			c_pwm :> pwm_out_data2.out1;
		}

		mode = pwm_op_noinv( chan_id0, chan_id1, chan_id2, pwm_out_data0, pwm_out_data1, pwm_out_data2, mode, p_pwm, c_pwm );
	}
}
