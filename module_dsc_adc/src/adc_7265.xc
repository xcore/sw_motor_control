/*
 * adc_7265.xc
 *
 *  Created on: Jul 6, 2011
 *  Author: A SRIKANTH
 */

#include <assert.h>

#include <xs1.h>
#include <platform.h>
#include <xclib.h>
#include <adc_common.h>
#include <adc_7265.h>

#define ADC_FILTER_7265

// This parameter needs to be tuned to move the ADC trigger point into the centre of the 'OFF' period.
// The 'test_pwm' application can be run in the simulator to tune the parameter.  Use the following
// command line:
//    xsim --vcd-tracing "-core stdcore[1] -ports" bin\test_pwm.xe > trace.vcd
//
// Then open the 'Waveforms' perspective in the XDE, click the 'load VCD file' icon and look at the
// traces named 'PORT_M1_LO_A', 'PORT_M1_LO_B', 'PORT_M1_LO_C', and 'PORT_ADC_CONV'.  The ADC conversion
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

// 1 revolution at 600RPM is 0.1sec, at 61kHz needs at lease 6.1k samples
#define CALIBRATION_COUNT 8192

/*****************************************************************************/
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
} // configure_adc_ports_7265
/*****************************************************************************/
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

#ifdef ADC_FILTER_7265
	adc_val[0] = (adc_val[0] >> 1) + (val1 >> 1);
	adc_val[1] = (adc_val[1] >> 1) + (val3 >> 1);
#else
	adc_val[0] = val1;
	adc_val[1] = val3;
#endif

} // adc_get_data_7265
/*****************************************************************************/
#pragma unsafe arrays
void adc_7265_triggered( // Thread to service ADC channels
	streaming chanend c_adc[ADC_NUMBER_OF_TRIGGERS], // ADC data Channel connecting to Control (inner_loop.xc)
	chanend c_adc_trig[ADC_NUMBER_OF_TRIGGERS], // Channel receiving control token triggers from PWM thread
	clock clk, 
	out port SCLK, 
	port CNVST, 
	in buffered port:32 DATA_A, 
	in buffered port:32 DATA_B, 
	port out MUX 
)
{
	int adc_val[ADC_NUMBER_OF_TRIGGERS][USED_ADC_PHASES];
	int cmd_id; // command identifier
	unsigned char cntrl_tokn; // control token
	int phase_cnt; // ADC Phase counter
	int trig_id; // trigger identifier
	int phase_id; // identifies one of 3 phases of ADC data

	timer my_timers[ADC_NUMBER_OF_TRIGGERS];
	unsigned time_stamps[ADC_NUMBER_OF_TRIGGERS];
	char guard_off[ADC_NUMBER_OF_TRIGGERS];


	set_thread_fast_mode_on();

	configure_adc_ports_7265( clk, SCLK, CNVST, DATA_A, DATA_B, MUX );

	for (trig_id=0; trig_id<ADC_NUMBER_OF_TRIGGERS; ++trig_id) 
	{
		for (phase_cnt=0; phase_cnt<USED_ADC_PHASES; ++phase_cnt) 
		{
			adc_val[trig_id][phase_cnt] = 0;
		} // for phase_cnt

		guard_off[trig_id] = 0;
	} // for trig_id


	while (1)
	{
#pragma xta endpoint "adc_7265_main_loop"
#pragma ordered
		select
		{
		// Service any Control Tokens that are received
		case (int trig_id=0; trig_id<ADC_NUMBER_OF_TRIGGERS; ++trig_id) inct_byref(c_adc_trig[trig_id], cntrl_tokn):
			// Check control token type
			if (cntrl_tokn == XS1_CT_END)
			{ // Kick-off capture of ADC values
				my_timers[trig_id] :> time_stamps[trig_id]; // get current time
				time_stamps[trig_id] += ADC_TRIGGER_DELAY; // Increment to time of ADC value capture
				guard_off[trig_id] = 1; // Switch guard OFF to allow capture
			}
		break;

		// If quard is OFF, load 'my_timer' at time 'time_stamp' 
		case (int trig_id=0; trig_id<ADC_NUMBER_OF_TRIGGERS; ++trig_id) guard_off[trig_id] => my_timers[trig_id] when timerafter(time_stamps[trig_id]) :> void:
			guard_off[trig_id] = 0; // Set guard ON

			adc_get_data_7265( adc_val[trig_id], trigger_channel_to_adc_mux[trig_id], CNVST, DATA_A, DATA_B, MUX );

			if (calibration_mode[trig_id] > 0) 
			{
				calibration_mode[trig_id]--;

				for (phase_cnt=0; phase_cnt<USED_ADC_PHASES; ++phase_cnt) 
				{
					calibration_acc[trig_id][phase_cnt] += adc_val[trig_id][phase_cnt];
				} // for phase_cnt

				if (calibration_mode[trig_id] == 0) 
				{
					for (phase_cnt=0; phase_cnt<USED_ADC_PHASES; ++phase_cnt) 
					{
						calibration[trig_id][phase_cnt] = calibration_acc[trig_id][phase_cnt] / CALIBRATION_COUNT;
					} // for phase_cnt
				}
			} // if (calibration_mode[trig_id] > 0) 
		break;

		// Service any client request for ADC data
		case (int trig_id=0; trig_id<ADC_NUMBER_OF_TRIGGERS; ++trig_id) c_adc[trig_id] :> cmd_id:
			switch(cmd_id)
			{
				case CMD_REQ_ADC : // Request for ADC data
					for (phase_cnt=0; phase_cnt<USED_ADC_PHASES; ++phase_cnt) 
					{
						phase_id = adc_val[trig_id][phase_cnt] - calibration[trig_id][phase_cnt];
						c_adc[trig_id] <: phase_id;
					} // for phase_cnt
				break; // case START

				case CMD_CAL_ADC : // Calibration
					calibration_mode[trig_id] = CALIBRATION_COUNT;

					for (phase_cnt=0; phase_cnt<USED_ADC_PHASES; ++phase_cnt) 
					{
						calibration[trig_id][phase_cnt] = 0;
					} // for phase_cnt
				break; // case START

		    default: // Unsupported Command
					assert(0 == 1); // Error: Received unsupported ADC command
  		  break;
			} // switch(cmd_id)

		break;
		} // select
	} // while (1)
} // adc_7265_triggered
/*****************************************************************************/
// adc_7265.xc
