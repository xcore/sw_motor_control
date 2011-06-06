/**
 * Module:  module_dsc_adc
 * Version: 1v0alpha2
 * Build:   2a548667d36ce36c64c58f05b5390ec71cb253fa
 * File:    adc_client.xc
 * Modified by : Srikanth
 * Last Modified on : 31-May-2011
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

#define ADC_CALIB_POINTS	64

static int Ia_calib = 0, Ib_calib = 0, Ic_calib = 0;

void do_adc_calibration( chanend c_adc )
{
	unsigned a,b,c;
	for (int i = 0; i < ADC_CALIB_POINTS; i++)
	{
		/* get ADC reading */
		c_adc <: 3;
		slave
		{
			c_adc :> a;
			c_adc :> b;
			c_adc :> c;
		}
		Ia_calib += a;
		Ib_calib += b;
		Ic_calib += c;
	}
	    Ia_calib = (Ia_calib >> 6);
		Ib_calib = (Ib_calib >> 6);
		Ic_calib = (Ic_calib >> 6);
}

{unsigned, unsigned, unsigned} get_adc_vals_raw( chanend c_adc )
{
	unsigned a, b, c;

	c_adc <: 0;

	slave
	{
		c_adc :> a;
		c_adc :> b;
		c_adc :> c;
	}

	return {a,b,c};
}

{int, int, int} get_adc_vals_calibrated_int16( chanend c_adc )
{
	unsigned a, b, c;
	int Ia, Ib, Ic;

	/* request and then receive adc data */
	c_adc <: 3;

	slave
	{
		c_adc :> a;
		c_adc :> b;
		c_adc :> c;
	}
	/* apply calibration offset */

	Ia = a - Ia_calib;
  	Ib = b - Ib_calib;
	Ic = c - Ic_calib;

	return {Ia, Ib, Ic};
}




