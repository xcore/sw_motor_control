/**
 * Module:  module_dsc_adc
 * Version: 1v0alpha3
 * Build:   dcbd8f9dde72e43ef93c00d47bed86a114e0d6ac
 * File:    adc_ltc1408.xc
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
#include "adc_ltc1408.h"
#include "adc_common.h"
#include <stdlib.h>

// The number of channels to store when sampling the ADC
#define ADC_CHANS 6

// These are the calibration values
static int calibration_a[2] = {0,0}, calibration_b[2] = {0,0}, calibration_c[2] = {0,0};

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

static void calibrate(clock clk, buffered out port:32 CNVST, in buffered port:32 DATA)
{
	int adc_val[6];

	adc_get_data_ltc1408_singleshot( adc_val, 0, CNVST, DATA, clk );
	calibration_a[0] = adc_val[0];
	calibration_b[0] = adc_val[1];
	calibration_c[0] = adc_val[2];
	calibration_a[1] = adc_val[3];
	calibration_b[1] = adc_val[4];
	calibration_c[1] = adc_val[5];
}


void adc_ltc1408_triggered( chanend c_adc[], chanend c_trig[], clock clk, port out SCLK, buffered out port:32 CNVST, in buffered port:32 DATA)
{
	int adc_val[6];
	int cmd;
	unsigned char ct;

	timer t;
	unsigned ts;

	configure_adc_ports_ltc1408(clk, SCLK, CNVST, DATA);

	while (1)
	{
		select
		{
		case (int trig=0; trig<NUM_ADC_TRIGGERS; ++trig) inct_byref(c_trig[trig], ct):
			if (ct == XS1_CT_END)
			{
				t :> ts;
				t when timerafter(ts + 1740) :> ts;
				adc_get_data_ltc1408_singleshot( adc_val, 0, CNVST, DATA, clk );
			}
			break;
		case (int trig=0; trig<NUM_ADC_TRIGGERS; ++trig) c_adc[trig] :> cmd:
			if (cmd == 1) {
				calibrate(clk, CNVST, DATA);
			} else if (trig == 0) {
				master {
					c_adc[trig] <: adc_val[0] - calibration_a[0];
					c_adc[trig] <: adc_val[1] - calibration_b[0];
					c_adc[trig] <: adc_val[2] - calibration_c[0];
				}
			} else {
				master {
					c_adc[trig] <: adc_val[3] - calibration_a[1];
					c_adc[trig] <: adc_val[4] - calibration_b[1];
					c_adc[trig] <: adc_val[5] - calibration_c[1];
				}
			}
			break;
		}

	}
}


