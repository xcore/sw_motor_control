/*
 *  adc_7265.xc
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
    configure_clock_rate_at_least(clk, 100, 6); // adc clock rate 16MHz
    configure_port_clock_output(SCLK, clk);
    configure_out_port(CNVST, clk, 1);
	configure_in_port(DATA_A, clk);
	configure_in_port(DATA_B, clk);

    set_port_sample_delay( DATA_A ); // clock in on falling edge
    set_port_sample_delay( DATA_B ); // clock in on falling edge

    start_clock(clk);
}

#pragma unsafe arrays
static void adc_get_data_7265( int adc_val[], port out CNVST, in buffered port:32 DATA_A, in buffered port:32 DATA_B, port out MUX )
{
	unsigned Va1 = 0, Vb1 = 0;
	unsigned ts;

	MUX <: 0x0;

	CNVST <: 0 @ts;
	ts += 16;
	CNVST @ts <: 1;

	par
	{
			DATA_A @ ts :> Va1;
			DATA_B @ ts :> Vb1;
	}

	Va1 = bitrev(Va1);
	Vb1 = bitrev(Vb1);

	Va1 = Va1 >> 2;
	Vb1 = Vb1 >> 2;

	Va1 = ADC_MASK & Va1;
	Vb1 = ADC_MASK & Vb1;

	adc_val[0] = Va1;
	adc_val[1] = Vb1;

}

void adc_7265_triggered( chanend c_adc, chanend c_trig, clock clk, port out SCLK, port out CNVST, in buffered port:32 DATA_A, in buffered port:32 DATA_B, port out MUX )
{
	int adc_val[6];
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
				adc_get_data_7265( adc_val, CNVST, DATA_A, DATA_B, MUX );
			}
			break;
		case c_adc :> cmd:
			switch (cmd)
			{
			case 0:
				master {
					c_adc <: adc_val[0];
					c_adc <: adc_val[1];
				}
				break;
			case 3:
					/* stub */
				break;
			case 6:
					/* stub */
				break;
			}
		break;
		}

	}
}

