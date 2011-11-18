/**
 * Module:  module_dsc_adc
 * Version: 1v0alpha2
 * Build:   2a548667d36ce36c64c58f05b5390ec71cb253fa
 * File:    adc_client.xc
 * Modified by : Srikanth
 * Last Modified on : 26-May-2011
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

#ifdef __dsc_config_h_exists__
#include <dsc_config.h>
#endif

void do_adc_calibration( streaming chanend c_adc )
{
	c_adc <: 1;
}

{int, int, int} get_adc_vals_calibrated_int16( streaming chanend c_adc )
{
	int a, b, c;

	/* request and then receive adc data */
	c_adc <: 0;
	c_adc :> a;
	c_adc :> b;
	c_adc :> c;

	/* convert to 14 bit from 12 bit */
	a = a << 2;
	b = b << 2;
	c = c << 2;

	return {a, b, c};
}




