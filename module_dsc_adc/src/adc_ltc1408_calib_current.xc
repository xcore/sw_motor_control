/**
 * Module:  module_dsc_adc
 * Version: 1v1
 * Build:
 * File:    adc_ltc1408_calib_current.xc
 * Author: 	Srikanth
 *
 * The copyrights, all other intellectual and industrial 
 * property rights are retained by XMOS and/or its licensors. 
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2011
 *
 * In the case where this code is a modification of existing code
 * under a separate license, the separate license terms are shown
 * below. The modifications to the code are still covered by the 
 * copyright notice above.
 *
 **/


#include "adc_ltc1408_calib_current.h"
#include "adc_common.h"
#include "adc_filter.h"
#include "adc_client.h"
#define ADC_CALIB_POINTS	64
#define V_OFFSET 32768
#define S_OFFSET 8192

timer t;
unsigned time;

static void configure_adc_ports_ltc1408(clock clk, port out SCLK, buffered out port:32 CNVST, in buffered port:32 DATA)
{
    configure_clock_rate_at_least(clk, 100, 10);

    configure_port_clock_output(SCLK, clk);
    configure_out_port(CNVST, clk, 0);
	configure_in_port(DATA, clk);

    set_port_sample_delay( DATA ); // clock in on falling edge

    start_clock(clk);
}

#pragma unsafe arrays
static void adc_get_data_ltc1408_singleshot( int adc_val[], unsigned offset, buffered out port:32 CNVST, in buffered port:32 DATA, clock clk )
{
	unsigned val1 = 0, val3 = 0, val5 = 0;

	stop_clock(clk);

	#define ADC_CONVERSION_TRIG (1<<31)
    CNVST <: ADC_CONVERSION_TRIG;
    clearbuf(DATA);
    start_clock(clk);
//	CNVST <: 0x0000001 @ ts;
//	asm("out res[%0],%1" :: "r"(CNVST),"r"(0x1));
//	asm("getts %0,res[%1]" :"=r"(ts) :"r"(CNVST));
//	ts += 2;
	DATA :> val1;
	CNVST <: 0;
	DATA :> val1;
	val1 = bitrev(val1);
	DATA :> val3;
	val3 = bitrev(val3);
	DATA :> val5;
    val5 = bitrev(val5);

	adc_val[offset+0] = 0x3FFF & (val1 >> 16);
	adc_val[offset+1] = 0x3FFF & (val1 >>  0);
	adc_val[offset+2] = 0x3FFF & (val3 >> 16);
	adc_val[offset+3] = 0x3FFF & (val3 >>  0);
	adc_val[offset+4] = 0x3FFF & (val5 >> 16);
	adc_val[offset+5] = 0x3FFF & (val5 >>  0);
}

void adc_ltc1408_calib_current( chanend c_adc, chanend c_adc2, clock clk, port out SCLK, buffered out port:32 CNVST, in buffered port:32 DATA )
{
	int adc_val[6], cmd, cmd2, Ia_calib = 0, Ib_calib = 0, Ic_calib = 0, Ia, Ib, Ic, Ia_calib2 = 0, Ib_calib2 = 0, Ic_calib2 = 0, Ia2, Ib2, Ic2;

    configure_adc_ports_ltc1408(clk, SCLK, CNVST, DATA);

    for (int i = 0; i < ADC_CALIB_POINTS; i++)
	{
		/* get ADC reading */
    	adc_get_data_ltc1408_singleshot( adc_val, 0, CNVST, DATA, clk );
		Ia_calib += adc_val[0];
		Ib_calib += adc_val[1];
		Ic_calib += adc_val[2];
		Ia_calib2 += adc_val[3];
		Ib_calib2 += adc_val[4];
		Ic_calib2 += adc_val[5];

	}

	/* convert to 16 bit from 14 bit */
	Ia_calib = Ia_calib << 2;
	Ib_calib = Ib_calib << 2;
	Ic_calib = Ic_calib << 2;

	Ia_calib2 = Ia_calib2 << 2;
	Ib_calib2 = Ib_calib2 << 2;
	Ic_calib2 = Ic_calib2 << 2;

	/* calculate average and offset for signed 14bit*/
	Ia_calib = ((Ia_calib >> 6) - S_OFFSET);
	Ib_calib = ((Ib_calib >> 6) - S_OFFSET);
	Ic_calib = ((Ic_calib >> 6) - S_OFFSET);
	Ia_calib2 = ((Ia_calib2 >> 6) - S_OFFSET);
	Ib_calib2 = ((Ib_calib2 >> 6) - S_OFFSET);
	Ic_calib2 = ((Ic_calib2 >> 6) - S_OFFSET);

    while (1)
    {
    	select
		{
			// Timer event at 10Hz
			case t when timerafter(time + 50000) :> time:
				adc_get_data_ltc1408_singleshot( adc_val, 0, CNVST, DATA, clk );
				Ia_calib = 0;
				Ib_calib = 0;
				Ic_calib = 0;

				Ia_calib2 = 0;
				Ib_calib2 = 0;
				Ic_calib2 = 0;

				Ia = adc_val[0] + Ia_calib; /* apply calibration offset */
				Ia <<= 2; /* convert to 16bit */
				Ia -= V_OFFSET; /* apply vertical offset to make a signed value */

				Ib = adc_val[1] + Ib_calib; /* apply calibration offset */
				Ib <<= 2; /* convert to 16bit */
				Ib -= V_OFFSET; /* apply vertical offset to make a signed value */

				Ic = adc_val[2] + Ic_calib; /* apply calibration offset */
				Ic <<= 2; /* convert to 16bit */
				Ic -= V_OFFSET; /* apply vertical offset to make a signed value */

				Ia2 = adc_val[3] + Ia_calib2; /* apply calibration offset */
				Ia2 <<= 2; /* convert to 16bit */
				Ia2 -= V_OFFSET; /* apply vertical offset to make a signed value */

				Ib2 = adc_val[4] + Ib_calib2; /* apply calibration offset */
				Ib2 <<= 2; /* convert to 16bit */
				Ib2 -= V_OFFSET; /* apply vertical offset to make a signed value */

				Ic2 = adc_val[5] + Ic_calib2; /* apply calibration offset */
				Ic2 <<= 2; /* convert to 16bit */
				Ic2 -= V_OFFSET; /* apply vertical offset to make a signed value */

				break;

			case c_adc :> cmd:
				if(cmd == 0)
					c_adc <: Ia;
				else if(cmd == 1)
					c_adc <: Ib;
				else if (cmd ==2)
					c_adc <: Ic;
			break;

			case c_adc2 :> cmd2:
				if(cmd2 == 3)
					c_adc2 <: Ia2;
				else if (cmd2 ==4)
					c_adc2 <: Ib2;
				else if (cmd2 ==5)
					c_adc2 <: Ic2;

				break;

			default:
				break;

		}
	}
}
