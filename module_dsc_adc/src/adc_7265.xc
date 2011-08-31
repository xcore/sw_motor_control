/*
 * adc_7265.xc
 *
 *  Created on: Jul 6, 2011
 *  Author: A SRIKANTH
 */

#include <xs1.h>
#include <platform.h>
#include <xclib.h>
#include <adc_common.h>
#include <adc_7265.h>

// This array determines the mapping from trigger channel to which analogue input to select in the ADC mux
static int trigger_channel_to_adc_mux[2] = { 0, 2 };

// These are the calibration values
static unsigned calibration_a[2] = {0,0}, calibration_b[2] = {0,0}, calibration_c[2] = {0,0};

static void configure_adc_ports_7265(clock clk, port out SCLK, port out CNVST, in buffered port:32 DATA_A, in buffered port:32 DATA_B, port out MUX)
{
    configure_clock_rate_at_least(clk, 100, 6);
    configure_port_clock_output(SCLK, clk);
    configure_out_port(CNVST, clk, 1);
	configure_in_port(DATA_A, clk);
	configure_in_port(DATA_B, clk);

    set_port_sample_delay( DATA_A ); // clock in on falling edge
    set_port_sample_delay( DATA_B ); // clock in on falling edge

    start_clock(clk);
}

#pragma unsafe arrays
static void adc_get_data_7265( int adc_val[], unsigned channel, port out CNVST, in buffered port:32 DATA_A, in buffered port:32 DATA_B, port out MUX )
{
	unsigned val1 = 0, val3 = 0;
	unsigned ts;

	MUX <: channel;

	CNVST <: 0 @ts;
	ts += 16;
	CNVST @ts <: 1;

	par
	{
			DATA_A @ ts :> val1;
			DATA_B @ ts :> val3;
	}

	val1 = bitrev(val1);
	val3 = bitrev(val3);

	val1 = val1 >> 2;
	val3 = val3 >> 2;

	val1 = 0x00000FFF & val1;
	val3 = 0x00000FFF & val3;

	adc_val[0] = val1;
	adc_val[1] = val3;

}

static void calibrate(port out CNVST, in buffered port:32 DATA_A, in buffered port:32 DATA_B, port out MUX)
{
	int adc[2];

	adc_get_data_7265( adc, trigger_channel_to_adc_mux[0], CNVST, DATA_A, DATA_B, MUX );
	calibration_a[0] = adc[0];
	calibration_b[0] = adc[1];
	calibration_c[0] = -(adc[0]+adc[1]);

	adc_get_data_7265( adc, trigger_channel_to_adc_mux[1], CNVST, DATA_A, DATA_B, MUX );
	calibration_a[0] = adc[0];
	calibration_b[0] = adc[1];
	calibration_c[0] = -(adc[0]+adc[1]);
}


#pragma unsafe arrays
void adc_7265_triggered( chanend c_adc[], chanend c_trig[], clock clk, port out SCLK, port out CNVST, in buffered port:32 DATA_A, in buffered port:32 DATA_B, port out MUX )
{
	int adc_val[ADC_NUMBER_OF_TRIGGERS][2];
	int cmd;
	unsigned char ct;

	timer t;
	unsigned ts;

	configure_adc_ports_7265( clk, SCLK, CNVST, DATA_A, DATA_B, MUX );

	while (1)
	{
		select
		{
		case (int trig=0; trig<ADC_NUMBER_OF_TRIGGERS; ++trig) inct_byref(c_trig[trig], ct):
			if (ct == ADC_TRIG_TOKEN)
			{
				t :> ts;
				t when timerafter(ts + 1740) :> ts;
				adc_get_data_7265( adc_val[trig], trigger_channel_to_adc_mux[trig], CNVST, DATA_A, DATA_B, MUX );
			}
			break;
		case (int trig=0; trig<ADC_NUMBER_OF_TRIGGERS; ++trig) c_adc[trig] :> cmd:
			if (cmd == 1) {
				calibrate(CNVST, DATA_A, DATA_B, MUX);
			} else {
				master {
					c_adc[trig] <: adc_val[trig][0] - calibration_a[trig];
					c_adc[trig] <: adc_val[trig][1] - calibration_b[trig];
					c_adc[trig] <: -(adc_val[trig][0] + adc_val[trig][1]) - calibration_c[trig];
				}
			}
			break;
		}
	}
}

