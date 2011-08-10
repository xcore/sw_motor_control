/*
 * adc_7265.xc
 *
 *  Created on: Jul 6, 2011
 *  Author: A SRIKANTH
 */

#include <xs1.h>
#include <platform.h>
#include <xclib.h>
#include <adc_7265.h>

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

void adc_7265_triggered( chanend c_adc, chanend c_trig, clock clk, port out SCLK, port out CNVST, in buffered port:32 DATA_A, in buffered port:32 DATA_B, port out MUX )
{
	int adc_val1[2], adc_val2[2];
	int cmd;
	unsigned char ct;

	timer t;
	unsigned ts;

	configure_adc_ports_7265( clk, SCLK, CNVST, DATA_A, DATA_B, MUX );
	while (1)
	{
		select
		{
		case inct_byref(c_trig, ct):
			if (ct == ADC_TRIG_TOKEN)
			{
				t :> ts;
				t when timerafter(ts + 1740) :> ts;
				adc_get_data_7265( adc_val1, 0, CNVST, DATA_A, DATA_B, MUX );
			}
			break;
		case c_adc :> cmd:
			switch (cmd)
			{
			case 0:
				master {
					c_adc <: adc_val1[0];
					c_adc <: adc_val1[1];
					c_adc <: -(adc_val1[0] + adc_val1[1]);
				}
				break;
			case 3:
				master {
					c_adc <: adc_val2[0];
					c_adc <: adc_val2[1];
					c_adc <: -(adc_val2[0] + adc_val2[1]);
				}
				break;
			case 6:
				master {
					c_adc <: adc_val1[0];
					c_adc <: adc_val1[1];
					c_adc <: -(adc_val1[0] + adc_val1[1]);
					c_adc <: adc_val2[0];
					c_adc <: adc_val2[1];
					c_adc <: -(adc_val2[0] + adc_val2[1]);
				}
				break;
			}
		break;
		}

	}
}

