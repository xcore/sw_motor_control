/**
 * Module:  module_dsc_adc
 * Version: 1v0alpha2
 * Build:   2a548667d36ce36c64c58f05b5390ec71cb253fa
 * File:    adc_client.xc
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
int Ia_calib = 0, Ib_calib = 0, Ic_calib = 0;

void do_adc_calibration( chanend c_adc )
{
	unsigned a,b,c;


	for (int i = 0; i < ADC_CALIB_POINTS; i++)
	{
		/* get ADC reading */
		c_adc <: 0;
		slave
		{
			c_adc :> a;
			c_adc :> b;
			c_adc :> c;
		}

		Ia_calib += a;
		Ia_calib += b;
		Ic_calib += c;
	}

	/* convert to 16 bit from 14 bit */
	Ia_calib = Ia_calib << 2;
	Ib_calib = Ib_calib << 2;
	Ic_calib = Ic_calib << 2;

	/* calculate average and offset for signed 14bit*/
	Ia_calib = ((Ia_calib >> 6) - 8192);
	Ib_calib = ((Ib_calib >> 6) - 8192);
	Ic_calib = ((Ic_calib >> 6) - 8192);
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
	c_adc <: 0;

	slave
	{
		c_adc :> a;
		c_adc :> b;
		c_adc :> c;
	}

	/* turn currents into a signed 16 bit number and applies calibrated offset */
	Ia = a + Ia_calib; /* apply calibration offset */
	Ia <<= 2; /* convert to 16bit */
	Ia -= 32768; /* apply vertical offset to make a signed value */

	Ib = b + Ib_calib;
	Ib <<= 2;
	Ib -= 32768;

	Ic = c + Ic_calib;
	Ic <<= 2;
	Ic -= 32768;

	return {Ia, Ib, Ic};
}

