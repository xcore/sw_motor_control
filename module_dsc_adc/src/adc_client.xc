/**
 * Module:  module_dsc_adc
 * Version: 1v0alpha2
 * Build:   2a548667d36ce36c64c58f05b5390ec71cb253fa
 * File:    adc_client.xc
 * Modified by : Srikanth
 * Last Modified on : 04-May-2011
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
#include <print.h>

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
		//printintln(Ia_calib);
		//printintln(Ib_calib);
		//printintln(Ic_calib);
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
    //Ia = a;
	Ia = (int)a - Ia_calib; /* apply calibration offset */
    //Ia = Ia*4;
//	  Ia = Ia*4 ;

	//Ib = b;
	Ib = (int)b - Ib_calib;
	//Ib = Ib*10  ;
	//Ib = Ib*4 ;

	//Ic = c;
	Ic = (int)c - Ic_calib;
//	Ic = Ic*10 ;
	//Ic = Ic*4 ;

	return {Ia, Ib, Ic};
}




