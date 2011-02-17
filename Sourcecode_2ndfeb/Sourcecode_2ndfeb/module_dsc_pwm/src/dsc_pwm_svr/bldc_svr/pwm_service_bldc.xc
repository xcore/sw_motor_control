/**
 * Module:  module_dsc_pwm
 * Version: 1v0alpha2
 * Build:   280fc2259bcf2719c6b83e517d854c7666e0c448
 * File:    pwm_service_bldc.xc
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
#include "pwm_service_bldc.h"
#include "dsc_config.h"

/******************************************************/
/* Basic BLDC commutation just requires PWM on the    */
/* low side of the half bridge. The upper side of the */
/* bridge needs to be controlled by the application   */
/******************************************************/

#ifdef PWM_BLDC_MODE
unsigned chan_id_buf[2];
unsigned mode_buf[2];
t_out_data pwm_out_data_buf[2];
unsigned pwm_cur_buf = 0;


/*
 * Operate PWM output - runs forever internally as updates are done using shared memory
 */
extern unsigned pwm_op_bldc( unsigned buf, buffered out port:32 p_pwm[], chanend c );

static void do_pwm_port_config_bldc(  buffered out port:32 p_pwm[], clock clk )
{
	unsigned i;

	configure_clock_rate(clk, 100, 1);

	for (i = 0; i < 3; i++)
	{
		configure_out_port(p_pwm[i], clk, 0);
	}

	start_clock(clk);

}

void do_pwm_bldc( chanend c_pwm, buffered out port:32 p_pwm[], clock clk)
{
	unsigned mode;

	do_pwm_port_config_bldc( p_pwm, clk);

	/* wait for initial update */
	c_pwm :> mode;

	while (1)
	{
		/* we never actually come out of this, activity on channel triggers buffer change over */
		mode = pwm_op_bldc( mode, p_pwm, c_pwm );
	}

}
#endif

