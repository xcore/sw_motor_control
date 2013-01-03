/*
 * adc_7265.xc
 *
 *  Created on: Jul 6, 2011
 *  Author: A SRIKANTH
 */

#include <stdlib.h>
#include <assert.h>

#include <xs1.h>
#include <platform.h>
#include <xclib.h>
#include <print.h>

#include <adc_common.h>
#include <adc_7265.h>

#pragma xta command "analyze loop adc_7265_main_loop"
#pragma xta command "set required - 40 us"

/*****************************************************************************/
void init_adc_phase( // Initialise the data for this phase of one ADC trigger
	ADC_PHASE_TYP &phase_data_s // Reference to structure containing data for this phase of one ADC trigger
)
{
	phase_data_s.calib_acc = 0;
	phase_data_s.calib_val = 0;
	phase_data_s.adc_val = 0;
	phase_data_s.rem_val = 0;
} // init_adc_phase
/*****************************************************************************/
void init_adc_trigger( // Initialise the data for this ADC trigger
	ADC_TRIG_TYP &trig_data_s, // Reference to structure containing data for this ADC trigger
	int inp_mux  // Mapping from 'trigger channel' to 'analogue ADC mux input'
)
{
	int phase_cnt; // ADC Phase counter


	for (phase_cnt=0; phase_cnt<USED_ADC_PHASES; ++phase_cnt) 
	{
		init_adc_phase( trig_data_s.phase_data[phase_cnt] );

		trig_data_s.guard_off = 0; // Initialise guard to ON
		trig_data_s.mux_id = inp_mux; // Assign Mux port for this trigger
	} // for phase_cnt

} // init_adc_trigger
/*****************************************************************************/
static void configure_adc_data_port( // Configure this ADC data port
	in buffered port:32 inp_data_port, // ADC input data port
	port p1_adc_off,	// 1-bit port used to switch ADC conversions On/Off. NB Active Low
	clock xclk 
)
{
	// configure the data ports to strobe data in to the buffer using the serial clock
	configure_in_port_strobed_slave( inp_data_port ,p1_adc_off ,xclk );

	set_port_sample_delay( inp_data_port ); // Set port to sample data on falling edge of clock
} // configure_adc_data_port
/*****************************************************************************/
static void configure_adc_ports_7265( // Configure all ADC data ports
	in buffered port:32 p32_data[NUM_ADC_DATA_PORTS], // Array of 32-bit buffered ADC data ports
	clock xclk, 
	out port p_serial_clk, 
	port p1_adc_off,	// 1-bit port used to switch ADC conversions On/Off. NB Active Low 
	out port p4_mux	// 4-bit port used to control multiplexor on ADC chip
)
{
	int port_cnt; // port counter


	// configure the clock to be 16MHz

	//configure_clock_rate_at_least(xclk, 16, 1);
	configure_clock_rate_at_most(xclk, 16, 1);
	configure_port_clock_output( p_serial_clk, xclk ); // Drive ADC serial clock port with XMOS clock

	// Ports require +ve strobes, but ADC needs a -ve strobe. Therefore use the port pin invert function to satisfy both
	configure_out_port( p1_adc_off ,xclk ,1 ); // Set initial value of port to 1 (ADC Off)
	set_port_inv( p1_adc_off ); // Configure port to invert data which is sampled and driven on its pin.
	p1_adc_off <: 0; // Switch off ADC conversions. NB Active Low

	// For each port, configure the data ports to strobe data in to the buffer using the serial clock
	for (port_cnt=0; port_cnt<NUM_ADC_DATA_PORTS; port_cnt++)
	{
		configure_adc_data_port( p32_data[port_cnt] ,p1_adc_off ,xclk );
	} // for port_cnt

	// Start the ADC serial clock port
	start_clock( xclk );
} // configure_adc_ports_7265
/*****************************************************************************/
void enable_adc_capture( // Do set-up to allow ADC values for this trigger to be captured
	ADC_TRIG_TYP &trig_data_s // Reference to structure containing data for this ADC trigger
)
{
	trig_data_s.my_timer :> trig_data_s.time_stamp; 	// get current time
	trig_data_s.time_stamp += ADC_TRIGGER_DELAY;				// Increment to time of ADC value capture
	trig_data_s.guard_off = 1;													// Switch guard OFF to allow capture
} // enable_adc_capture
/*****************************************************************************/
void service_control_token( // Services client control token for this trigger
	ADC_TRIG_TYP &trig_data_s, // Reference to structure containing data for this ADC trigger
	int trig_id, // trigger identifier
	unsigned char inp_token // input control token
)
{
	switch(inp_token)
	{
		case XS1_CT_END : // Request for ADC values
			enable_adc_capture( trig_data_s ); // Enable capture of ADC values
		break; // case XS1_CT_END
	
    default: // Unsupported Control Token
			assert(0 == 1); // Error: Unknown Control Token
		break;
	} // switch(inp_token)

} // service_control_token 
/*****************************************************************************/
#pragma unsafe arrays
static void get_adc_port_data( // Get ADC data from one port
	ADC_PHASE_TYP &phase_data_s, // Reference to structure containing data for this phase of one ADC trigger
	in buffered port:32 inp_data_port // ADC input data port for one phase
)
{
	unsigned inp_val; // input value read from buffered ports
	unsigned tmp_val; // Temporary manipulation value
	int sum_val; // input plus remainder


	endin( inp_data_port ); // End the previous input on this buffered port
	inp_data_port :> inp_val; // Get new input

	tmp_val = bitrev( inp_val );	// Reverse bit order
	tmp_val >>= 4;								// Shift right by 4 bits
	tmp_val &= 0x00000FFF;				// Mask out LS 12 bits

#ifdef ADC_FILTER_7265
	// Create filtered value and store in tmp_val ...

	sum_val = (int)tmp_val + phase_data_s.rem_val; // Add in old remainder
	tmp_val = (phase_data_s.adc_val + sum_val) >> 1; // 1st order filter
	phase_data_s.rem_val = sum_val - (int)(tmp_val << 1); // Calculate new remainder
#endif

	phase_data_s.adc_val = (int)tmp_val;

} // get_adc_port_data
/*****************************************************************************/
#pragma unsafe arrays
static void get_trigger_data_7265( 
	ADC_TRIG_TYP &trig_data_s, // Reference to structure containing data for this ADC trigger
	in buffered port:32 p32_data[NUM_ADC_DATA_PORTS],  // Array of 32-bit buffered ADC data ports
	port p1_adc_off,	// 1-bit port used to switch ADC conversions On/Off. NB Active Low 
	out port p4_mux	// 4-bit port used to control multiplexor on ADC chip
)
{
	int port_cnt; // port counter
	unsigned time_stamp;


	p4_mux <: trig_data_s.mux_id; // Signal to Multiplexor which input to use for this trigger

	// Loop through phases
	for (port_cnt=0; port_cnt<NUM_ADC_DATA_PORTS; port_cnt++)
	{
		clearbuf( p32_data[port_cnt] );
	} // for port_cnt

	p1_adc_off <: 1 @time_stamp; // Switch On ADC conversions. NB Active Low
	time_stamp += 16;
	p1_adc_off @time_stamp <: 0; // Switch Off ADC conversions. NB Active Low

	sync( p1_adc_off ); // Wait until port has completed any pending outputs

	// Get ADC data for each used phase
	for (port_cnt=0; port_cnt<NUM_ADC_DATA_PORTS; port_cnt++)
	{
		get_adc_port_data( trig_data_s.phase_data[port_cnt] ,p32_data[port_cnt] );
	} // for port_cnt

} // get_trigger_data_7265
/*****************************************************************************/
void calibrate_trigger( // Do calibration for this trigger
	ADC_TRIG_TYP &trig_data_s, // Reference to structure containing data for this ADC trigger
	int trig_id // trigger identifier
)
{
	int phase_cnt; // ADC Phase counter


	trig_data_s.calib_cnt--; // Update No. of calibration points left to collect

	// Loop through used phases
	for (phase_cnt=0; phase_cnt<USED_ADC_PHASES; ++phase_cnt) 
	{
		trig_data_s.phase_data[phase_cnt].calib_acc += trig_data_s.phase_data[phase_cnt].adc_val; // Sum ADC values
	} // for phase_cnt


	// Check if we have all calibration data
	if (trig_data_s.calib_cnt == 0) 
	{
		// Loop through used phases
		for (phase_cnt=0; phase_cnt<USED_ADC_PHASES; ++phase_cnt) 
		{
			trig_data_s.phase_data[phase_cnt].calib_val = (trig_data_s.phase_data[phase_cnt].calib_acc + HALF_CALIBRATIONS) >> CALIBRATION_BITS; // Form average value
		} // for phase_cnt
	} // if (calib_mode == 0) 

} // calibrate_trigger
/*****************************************************************************/
void update_adc_trigger_data( // Update ADC values for this trigger
	ADC_TRIG_TYP &trig_data_s, // Reference to structure containing data for this ADC trigger
	in buffered port:32 p32_data[NUM_ADC_DATA_PORTS], // Array of 32-bit buffered ADC data ports
	port p1_adc_off,	// 1-bit port used to switch ADC conversions On/Off. NB Active Low 
	int trig_id, // trigger identifier
	out port p4_mux	// 4-bit port used to control multiplexor on ADC chip
)
{
	get_trigger_data_7265( trig_data_s ,p32_data ,p1_adc_off ,p4_mux );	// Get ADC values for this trigger	

	// Check if we are collecting calibration data
	if (trig_data_s.calib_cnt > 0) 
	{
		calibrate_trigger( trig_data_s ,trig_id );
	} // if (calibration_mode[trig_id] > 0) 

	trig_data_s.guard_off = 0; // Reset guard to ON
} // update_adc_trigger_data
/*****************************************************************************/
void service_data_request( // Services client command data request for this trigger
	ADC_TRIG_TYP &trig_data_s, // Reference to structure containing data for this trigger
	streaming chanend c_control, // ADC Channel connecting to Control, for this trigger
	int trig_id, // trigger identifier
	int inp_cmd // input command
)
{
	int phase_cnt; // ADC Phase counter


	switch(inp_cmd)
	{
		case ADC_CMD_REQ : // Request for ADC data
			for (phase_cnt=0; phase_cnt<USED_ADC_PHASES; ++phase_cnt) 
			{
				c_control <: (trig_data_s.phase_data[phase_cnt].adc_val - trig_data_s.phase_data[phase_cnt].calib_val);
			} // for phase_cnt
		break; // case ADC_CMD_REQ 
	
		case ADC_CMD_CAL : // Start Calibration
			trig_data_s.calib_cnt = NUM_CALIBRATIONS;

			for (phase_cnt=0; phase_cnt<USED_ADC_PHASES; ++phase_cnt) 
			{
				trig_data_s.phase_data[phase_cnt].calib_val = 0;
			} // for phase_cnt
		break; // case ADC_CMD_CAL 
	
    default: // Unsupported Command
			assert(0 == 1); // Error: Received unsupported ADC command
	  		  break;
	} // switch(inp_cmd)
} // service_data_request 
/*****************************************************************************/
#pragma unsafe arrays
void adc_7265_triggered( // Thread for ADC server
	streaming chanend c_control[NUM_ADC_TRIGGERS], // Array of ADC control Channels connecting to Control (inner_loop.xc)
	chanend c_trigger[NUM_ADC_TRIGGERS], // Array of channels receiving control token triggers from PWM threads
	in buffered port:32 p32_data[NUM_ADC_DATA_PORTS], // Array of 32-bit buffered ADC data ports
	clock xclk, // Internal XMOS clock
	out port p_serial_clk, // Port connecting to external ADC serial clock
	port p1_adc_off,	// 1-bit port used to switch ADC conversions On/Off. NB Active Low
	out port p4_mux	// 4-bit port used to control multiplexor on ADC chip
)
{
	int trigger_channel_to_adc_mux[NUM_ADC_TRIGGERS] = { 0, 2 }; // Mapping array from 'trigger channel' to 'analogue ADC mux input' See. AD7265 data-sheet
	ADC_TRIG_TYP trig_data[NUM_ADC_TRIGGERS];

	unsigned char cntrl_token; // control token
	int cmd_id; // command identifier
	int trig_id; // trigger identifier


	// Initialise data structure for each trigger
	for (trig_id=0; trig_id<NUM_ADC_TRIGGERS; ++trig_id) 
	{
		init_adc_trigger( trig_data[trig_id] ,trigger_channel_to_adc_mux[trig_id] );
	} // for trig_id

	set_thread_fast_mode_on();

	configure_adc_ports_7265( p32_data ,xclk ,p_serial_clk ,p1_adc_off ,p4_mux );

	while (1)
	{
#pragma xta endpoint "adc_7265_main_loop"
#pragma ordered
		select
		{
			// Service any Control Tokens that are received
			case (int trig_id=0; trig_id<NUM_ADC_TRIGGERS; ++trig_id) inct_byref( c_trigger[trig_id], cntrl_token ):
				service_control_token( trig_data[trig_id] ,trig_id ,cntrl_token );
			break;
	
			// If guard is OFF, load 'my_timer' at time 'time_stamp' 
			case (int trig_id=0; trig_id<NUM_ADC_TRIGGERS; ++trig_id) trig_data[trig_id].guard_off => trig_data[trig_id].my_timer when timerafter( trig_data[trig_id].time_stamp ) :> void:
				update_adc_trigger_data( trig_data[trig_id] ,p32_data ,p1_adc_off ,trig_id ,p4_mux ); 
			break;
	
			// Service any client request for ADC data
			case (int trig_id=0; trig_id<NUM_ADC_TRIGGERS; ++trig_id) c_control[trig_id] :> cmd_id:
				service_data_request( trig_data[trig_id] ,c_control[trig_id] ,trig_id ,cmd_id );
			break;
		} // select
	} // while (1)
} // adc_7265_triggered
/*****************************************************************************/
// adc_7265.xc
