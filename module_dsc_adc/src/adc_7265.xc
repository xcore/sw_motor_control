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

#ifdef USE_XSCOPE
#include <xscope.h>
#endif


#define ADC_FILTER_7265

// This parameter needs to be tuned to move the ADC trigger point into the centre of the 'OFF' period.
// The 'test_pwm' application can be run in the simulator to tune the parameter.  Use the following
// command line:
//    xsim --vcd-tracing "-core stdcore[1] -ports" bin\Release\test_pwm.xe > trace.vcd
//
// Then open the 'Signals' and 'Waves' panes in the XDE, load the VCD file and look at the traces
// named 'PORT_M1_LO_A', 'PORT_M1_LO_B', 'PORT_M1_LO_C', and 'PORT_ADC_CONV'.  The ADC conversion
// trigger should go high in the centre of the low periods of all of the motor control ports. This
// occurs periodically, but an example can be found at around 94.8us into the simulaton.
#define ADC_TRIGGER_DELAY 1980

#pragma xta command "analyze loop adc_7265_main_loop"
#pragma xta command "set required - 40 us"

// This array determines the mapping from trigger channel to which analogue input to select in the ADC mux
static int trigger_channel_to_adc_mux[2] = { 0, 2 };

// These are the calibration values
static unsigned calibration[ADC_NUMBER_OF_TRIGGERS][2];

// Mode to say if we are currently calibrating the ADC
static int calibration_mode[ADC_NUMBER_OF_TRIGGERS];

// Accumultor for the calibration average
static int calibration_acc[ADC_NUMBER_OF_TRIGGERS][2];


static void configure_adc_ports_7265(clock clk, out port SCLK, port CNVST, in buffered port:32 DATA_A, in buffered port:32 DATA_B, out port MUX)
{
	// configure the clock to be 16MHz
    //configure_clock_rate_at_least(clk, 16, 1);
    configure_clock_rate_at_most(clk, 16, 1);
    configure_port_clock_output(SCLK, clk);

    // ports require postive strobes, but the ADC needs a negative strobe. use the port pin invert function
    // to satisfy both
    configure_out_port(CNVST, clk, 1);
    set_port_inv(CNVST);
    CNVST <: 0;

    // configure the data ports to strobe data in to the buffer using the serial clock
	configure_in_port_strobed_slave(DATA_A, CNVST, clk);
	configure_in_port_strobed_slave(DATA_B, CNVST, clk);

	// sample the data in on falling edge of the serial clock
    set_port_sample_delay( DATA_A );
    set_port_sample_delay( DATA_B );

    // start the ADC serial clock port
    start_clock(clk);
}

#pragma unsafe arrays
static void adc_get_data_7265( int adc_val[], unsigned channel, port CNVST, in buffered port:32 DATA_A, in buffered port:32 DATA_B, out port MUX )
{
	unsigned val1 = 0, val3 = 0;
	unsigned ts;

	MUX <: channel;

    clearbuf(DATA_A);
    clearbuf(DATA_B);

	CNVST <: 1 @ts;
	ts += 16;
	CNVST @ts <: 0;

	sync(CNVST);

	endin(DATA_A);
	DATA_A :> val1;

	endin(DATA_B);
	DATA_B :> val3;

	val1 = bitrev(val1);
	val3 = bitrev(val3);

	val1 = val1 >> 4;
	val3 = val3 >> 4;

	val1 = 0x00000FFF & val1;
	val3 = 0x00000FFF & val3;

#ifdef USE_XSCOPE
	xscope_probe_data(0, val1);
	xscope_probe_data(1, val3);
#endif

#ifdef ADC_FILTER_7265
	adc_val[0] = (adc_val[0] >> 1) + (val1 >> 1);
	adc_val[1] = (adc_val[1] >> 1) + (val3 >> 1);
#else
	adc_val[0] = val1;
	adc_val[1] = val3;
#endif

}

#pragma unsafe arrays
void adc_7265_triggered( chanend c_adc[ADC_NUMBER_OF_TRIGGERS], chanend c_trig[ADC_NUMBER_OF_TRIGGERS], clock clk, out port SCLK, port CNVST, in buffered port:32 DATA_A, in buffered port:32 DATA_B, port out MUX )
{
	int adc_val[ADC_NUMBER_OF_TRIGGERS][2];
	int cmd;
	unsigned char ct;

	timer t[ADC_NUMBER_OF_TRIGGERS];
	unsigned ts[ADC_NUMBER_OF_TRIGGERS];
	char go[ADC_NUMBER_OF_TRIGGERS];

	set_thread_fast_mode_on();

	configure_adc_ports_7265( clk, SCLK, CNVST, DATA_A, DATA_B, MUX );

	for (unsigned int c=0; c<ADC_NUMBER_OF_TRIGGERS; ++c) {
		adc_val[c][0] = 0;
		adc_val[c][1] = 0;
		go[c] = 0;
	}


	while (1)
	{
#pragma xta endpoint "adc_7265_main_loop"
#pragma ordered
		select
		{
		case (int trig=0; trig<ADC_NUMBER_OF_TRIGGERS; ++trig) inct_byref(c_trig[trig], ct):
			if (ct == ADC_TRIG_TOKEN)
			{
				t[trig] :> ts[trig];
				ts[trig] += ADC_TRIGGER_DELAY;
				go[trig] = 1;
			}
			break;

		case (int trig=0; trig<ADC_NUMBER_OF_TRIGGERS; ++trig) go[trig] => t[trig] when timerafter(ts[trig]) :> void:
			go[trig] = 0;
			adc_get_data_7265( adc_val[trig], trigger_channel_to_adc_mux[trig], CNVST, DATA_A, DATA_B, MUX );
			if (calibration_mode[trig] > 0) {
				calibration_mode[trig]--;
				calibration_acc[trig][0] += adc_val[trig][0];
				calibration_acc[trig][1] += adc_val[trig][1];
				if (calibration_mode[trig] == 0) {
					calibration[trig][0] = calibration_acc[trig][0] / 512;
					calibration[trig][1] = calibration_acc[trig][1] / 512;
				}
			}
			break;

		case (int trig=0; trig<ADC_NUMBER_OF_TRIGGERS; ++trig) c_adc[trig] :> cmd:
			if (cmd == 1) {
				calibration_mode[trig] = 512;
				calibration_acc[trig][0]=0;
				calibration_acc[trig][1]=0;
			} else {
				master {
					unsigned a = adc_val[trig][0] - calibration[trig][0];
					unsigned b = adc_val[trig][1] - calibration[trig][1];
					c_adc[trig] <: a;
					c_adc[trig] <: b;
					c_adc[trig] <: -(a+b);
				}
			}
			break;
		}
	}
}

