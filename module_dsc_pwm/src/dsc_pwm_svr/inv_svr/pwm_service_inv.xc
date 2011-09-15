/**
 * Module:  module_dsc_pwm
 * Version: 1v0alpha3
 * Build:   dcbd8f9dde72e43ef93c00d47bed86a114e0d6ac
 * File:    pwm_service_inv.xc
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
#include "pwm_service_inv.h"
#include "dsc_config.h"


#if LOCK_ADC_TO_PWM

extern unsigned pwm_op_inv( unsigned buf, buffered out port:32 p_pwm[], buffered out port:32 p_pwm_inv[], chanend c, unsigned control, chanend c_trig, in port dummy_port );

static void do_pwm_port_config_inv_adc_trig( in port dummy, buffered out port:32 p_pwm[], buffered out port:32 p_pwm_inv[], clock clk )
{
	unsigned i;

	for (i = 0; i < PWM_CHAN_COUNT; i++)
	{
		configure_out_port(p_pwm[i], clk, 0);
		configure_out_port(p_pwm_inv[i], clk, 0);
		set_port_inv(p_pwm_inv[i]);
	}

	/* dummy port used to send ADC trigger */
	configure_in_port(dummy,clk);

	start_clock(clk);
}

void do_pwm_inv_triggered( chanend c_pwm, chanend c_adc_trig, in port dummy_port, buffered out port:32 p_pwm[], buffered out port:32 p_pwm_inv[], clock clk)
{

	unsigned buf, control;

	/* First read the shared memory buffer address from the client */
	c_pwm :> control;

	/* configure the ports */
	do_pwm_port_config_inv_adc_trig( dummy_port, p_pwm, p_pwm_inv, clk );

	/* wait for initial update */
	c_pwm :> buf;

	while (1)
	{
		buf = pwm_op_inv( buf, p_pwm, p_pwm_inv, c_pwm, control, c_adc_trig, dummy_port );
	}

}
#else

extern unsigned pwm_op_inv( unsigned buf, buffered out port:32 p_pwm[], buffered out port:32 p_pwm_inv[], chanend c, unsigned control );

static void do_pwm_port_config_inv(  buffered out port:32 p_pwm[], buffered out port:32 p_pwm_inv[], clock clk )
{
	unsigned i;

	for (i = 0; i < PWM_CHAN_COUNT; i++)
	{
		configure_out_port(p_pwm[i], clk, 0);
		configure_out_port(p_pwm_inv[i], clk, 0);
		set_port_inv(p_pwm_inv[i]);
	}

	start_clock(clk);
}

void do_pwm_inv( chanend c_pwm, buffered out port:32 p_pwm[],  buffered out port:32 p_pwm_inv[], clock clk)
{

	unsigned buf, control;

	/* First read the shared memory buffer address from the client */
	c_pwm :> control;

	/* configure the ports */
	do_pwm_port_config_inv( p_pwm, p_pwm_inv, clk);

	/* wait for initial update */
	c_pwm :> buf;

	while (1)
	{
		buf = pwm_op_inv( buf, p_pwm, p_pwm_inv, c_pwm, control );
	}

}
#endif
