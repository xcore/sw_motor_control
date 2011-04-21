/**
 * Module:  module_dsc_pwm
 * Version: 1v1
 * Build:
 * File:    pwm_service_bldc2.xc
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
#include "pwm_service_bldc.h"
#include "dsc_config.h"

#ifdef PWM_BLDC_MODE

/******************************************************/
/* Basic BLDC commutation just requires PWM on the    */
/* low side of the half bridge. The upper side of the */
/* bridge needs to be controlled by the application   */
/******************************************************/

unsigned chan_id_buf2[2];
unsigned mode_buf2[2];
t_out_data pwm_out_data_buf2[2];
unsigned pwm_cur_buf2 = 0;


/*
 * Operate PWM output - runs forever internally as updates are done using shared memory
 */
extern unsigned pwm_op_bldc2( unsigned buf, buffered out port:32 p_pwm2[], chanend c2 );

static void do_pwm_port_config_bldc(  buffered out port:32 p_pwm2[], clock clk2 )
{
	unsigned i;

	configure_clock_rate(clk2, 100, 1);

	for (i = 0; i < 3; i++)
	{
		configure_out_port(p_pwm2[i], clk2, 0);
	}

	start_clock(clk2);

}

void do_pwm_bldc2( chanend c_pwm2, buffered out port:32 p_pwm2[], clock clk2)
{
	unsigned mode;

	do_pwm_port_config_bldc( p_pwm2, clk2);

	/* wait for initial update */
	c_pwm2 :> mode;

	while (1)
	{
		/* we never actually come out of this, activity on channel triggers buffer change over */
		mode = pwm_op_bldc2( mode, p_pwm2, c_pwm2 );
	}

}
#endif

