/**
 * Module:  module_dsc_adc
 * Version: 0v9sd
 * Build:   d60ef6389ff4e99d65127601580f5fa2abbb09b2
 * File:    adc_max1379.xc
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
#include <xclib.h>
#include <platform.h>

#include "adc_common.h"
#include "adc_max1379.h"

#define MS 100000
#define US 100

// These are the calibration values
static int calibration_a[2] = {0,0}, calibration_b[2] = {0,0}, calibration_c[2] = {0,0};


static void configure_adc_ports_max1379(clock clk, port out SCLK,  port out CNVST, in buffered port:32 DATA)
{
	if (XS1_TIMER_MHZ == 100)
		configure_clock_rate(clk, 100, 6);

	if (XS1_TIMER_MHZ == 200)
			configure_clock_rate(clk, 100, 12);

	configure_port_clock_output(SCLK, clk);
	configure_in_port_strobed_master(DATA, CNVST, clk);
	set_port_inv(CNVST);
	
	start_clock(clk);
}

{unsigned, unsigned} adc_get_data_max1379 ( port out CNVST, in buffered port:32 DATA)
{
	unsigned din;
	unsigned adc1, adc2;
	
	DATA :> din;
	
	din = bitrev(din) >> 4;
	adc2 = (din & 0xFFF);
	adc1 = (din & 0xFFF000) >> 12;
	
	return {adc1, adc2};
}

static void calibrate(port out CNVST,  port out SEL, in buffered port:32 DATA)
{
	unsigned adc1, adc2;
	SEL <: 0;
	{adc1, adc2} = adc_get_data_max1379(CNVST, DATA);
	calibration_a[0] = adc1;
	calibration_b[0] = adc2;
	calibration_c[0] = -(adc1+adc2);

	SEL <: 1;
	{adc1, adc2} = adc_get_data_max1379(CNVST, DATA);
	calibration_a[1] = adc1;
	calibration_b[1] = adc2;
	calibration_c[1] = -(adc1+adc2);
}


void run_adc_max1379( chanend c_adc[], clock clk, port out SCLK,  port out CNVST,  port out SEL, in buffered port:32 DATA)
{
	timer t;
	unsigned ts, cmd;
	
	int adc1, adc2, adc3;
	
	configure_adc_ports_max1379(clk, SCLK, CNVST, DATA);
	
	SEL <: 0;

	/* startup delay */
	t :> ts;
	t when timerafter(ts + (2*MS)) :> ts;
	
	while (1)
	{
		select {
			case (int trig=0; trig<NUM_ADC_TRIGGERS; ++trig) c_adc[trig] :> cmd:
				if (cmd == 1) {
					calibrate(CNVST, SEL, DATA);
				} else {
					SEL <: trig;
					{adc1, adc2} = adc_get_data_max1379(CNVST, DATA);
					adc3 = -(adc1 + adc2);

					master {
						c_adc[0] <: adc1 - calibration_a[trig];
						c_adc[0] <: adc2 - calibration_b[trig];
						c_adc[0] <: adc3 - calibration_c[trig];
					}
				}
				break;
		}
	}
}


