/**
 * Module:  module_dsc_qei
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

/*****************************************************************************\
	This code is designed to work on a Motor with a Max speed of 4000 RPM,
	and a 1024 counts per revolution.

	The QEI data is read in via a 4-bit port. With assignments as follows:-

	 bit_3   bit_2   bit_1    bit_0
	-------  -----  -------  -------
  Un-used  Index  Phase_B  Phase_A

	In normal operation the B and A bits change as a grey-code,
	with the following convention

			  ----------->  Counter-Clockwise
	BA:  00 01 11 10 00
			  <-----------  Clockwise

	During one revolution, BA will change 1024 times,
	Index will take the value of zero 1023 times, and the value one once only,
  at the position origin. 
	NB When the motor starts, it is NOT normally at the origin

	A look-up table is used to decode the 2 phase bits, into a spin direction
	with the following meanings: 
		 1: Anit-Clocwise, 
		 0: Unknown    (The motor has either stopped, or jumped one or more phases)
		-1: Clocwise, 

	The timer is read every time the phase bits change. I.E. 1024 times per revolution

	The angular postion is incremented/decremented (with the spin value) if the 
	motor is NOT at the origin. 
	If the motor is at the origin, the angular position is reset to zero.

\*****************************************************************************/

#include <stdio.h>
#include <assert.h>

#include <xs1.h>
#include <print.h>

#include "qei_server.h"
#include "qei_commands.h"
#include "dsc_config.h"

// This is the loop time for 4000RPM on a 1024 count QEI
#pragma xta command "analyze loop qei_main_loop"
#pragma xta command "set required - 14.64 us"

#define HIST_SIZ 8192
//MB~ static unsigned short hist[HIST_SIZ]; //MB~ dbg

/*****************************************************************************/
void init_qei_data( // Initialise  QEI data for one motor
	QEI_PARAM_S &inp_qei_s, // Reference to structure containing QEI parameters for one motor
	int inp_id  // Input unique motor identifier
)
{
//MB~ for(int cnt=0; cnt<HIST_SIZ; cnt++) hist[cnt] = 0; //MB~

	inp_qei_s.id = inp_id; // Clear Previous phase values
	inp_qei_s.prev_phases = 0; // Clear Previous phase values
	inp_qei_s.orig_cnt = 0; // Reset counter indicating how many times motor has passed origin (index)
	inp_qei_s.ang_cnt = 0; // Reset counter indicating angular position of motor (from origin)

	inp_qei_s.prev_orig = 0; // Debug variable
	inp_qei_s.cnt = 0; // Debug variable
	inp_qei_s.tmp = 0; // Debug variable
} // service_client_request
/*****************************************************************************/
#pragma unsafe arrays
void service_input_pins( // Get QEI data from motor and send to client
	QEI_PARAM_S &inp_qei_s, // Reference to structure containing QEI parameters for one motor
	unsigned inp_pins // Set of raw data values on input port pins
)
{
/* get_spin is a table for converting pins values to spin values
 *	Order is 00 -> 10 -> 11 -> 01  Clockwise direction
 *	Order is 00 -> 01 -> 11 -> 10  Anti-Clockwise direction
 *
 *	Spin-state is
 *		-1: CLOCK Clocwise rotation, 
 *		 0: STALL (The motor has probably stopped)
 *		 1: ANTI Anti-Clocwise rotation, 
 *		 2: JUMP (The motor has probably jumped 2 phases)
 */

// MB~ At present this table has wrong spin direction convention
static const signed char get_spin_state[QEI_PHASES][QEI_PHASES] = {
		{ QEI_STALL,	QEI_CLOCK,	QEI_ANTI,		QEI_JUMP	}, // 00
		{ QEI_ANTI,		QEI_STALL,	QEI_JUMP,		QEI_CLOCK	}, // 01
		{ QEI_CLOCK,	QEI_JUMP,		QEI_STALL,	QEI_ANTI	}, // 10
		{ QEI_JUMP,		QEI_ANTI,		QEI_CLOCK,	QEI_STALL	}  // 11
};

	unsigned cur_phases; // Current set of phase values
	unsigned origin; // Flag set when motor at origin position 
	signed char cur_spin; // current spin direction
	timer my_tymer;


	origin = inp_pins & 0x4; 		// Extract origin flag 
	cur_phases = inp_pins & 0x3; // Extract Phase bits

	// Check if phases have changed
	if (cur_phases != inp_qei_s.prev_phases) 
	{
		// Get new time stamp ..
		inp_qei_s.prev_time = inp_qei_s.inp_time; // Store previous time stamp
		my_tymer :> inp_qei_s.inp_time;		// Get new time stamp

		// Update angular position
		cur_spin = get_spin_state[cur_phases][inp_qei_s.prev_phases]; // Decoded spin fom phase info.
		inp_qei_s.ang_cnt += cur_spin; // Increment/Decrement angular position
		inp_qei_s.prev_phases = cur_phases; // Store old phase value

		// Check if motor at origin
		if (origin != inp_qei_s.prev_orig)
		{
			if (origin)
			{ // Reset position ( Origin transition  0 --> 1 )
				inp_qei_s.orig_cnt++; // Increment origin counter

// hist[4096 + inp_qei_s.ang_cnt]++; // MB~ dbg

				inp_qei_s.ang_cnt = 0; // Reset position value

#ifdef MB
if (1000 < inp_qei_s.orig_cnt)
{
if (inp_qei_s.id)
{
	for(int cnt=0; cnt<HIST_SIZ; cnt++)
	{ 
		if (0 < hist[cnt])
		{
			printint( (cnt - 4096) );
			printchar(' ');
			printintln( hist[cnt] );
		} // if (0 < hist[cnt])
	} // for cnt
} //if (inp_qei_s.id)
inp_qei_s.orig_cnt = 1;

} // if (2000 < inp_qei_s.orig_cnt)

// Check for missed origin signals
if (inp_qei_s.id)
{
	inp_qei_s.cnt++; // Increment origin counter

	if (inp_qei_s.cnt == 100)
	{
		printint( inp_qei_s.orig_cnt );
		printchar(' ');
		printintln( inp_qei_s.tmp );

		inp_qei_s.cnt = 0; // Increment origin counter
		inp_qei_s.tmp = 0;
	} //if (inp_qei_s.cnt == 1000)
} // if (inp_qei_s.id)
#endif //MB

			} // if (origin)

			inp_qei_s.prev_orig = origin; //MB~ dbg
		} // if (origin != inp_qei_s.prev_orig)

	}	// if (cur_phases != inp_qei_s.prev_phases)

} // service_input_pins
/*****************************************************************************/
#pragma unsafe arrays
void service_client_request( // Send processed QEI data to client
	QEI_PARAM_S &inp_qei_s, // Reference to structure containing QEI parameters for one motor
	streaming chanend c_qei // Data channel to client (carries processed QEI data)
)
{
	// Send processed QEI data to client
	c_qei <: inp_qei_s.ang_cnt;
	c_qei <: inp_qei_s.inp_time;
	c_qei <: inp_qei_s.prev_time;
	c_qei <: inp_qei_s.orig_cnt;
} // service_client_request
/*****************************************************************************/
#pragma unsafe arrays
void do_qei ( 
	streaming chanend c_qei, // data channel to client (carries processed QEI data)
	port in pQEI  						// Input port (carries raw QEI motor data)
)
{
	QEI_PARAM_S qei_data_s; // Structure containing QEI parameters for one motor
	unsigned inp_pins; // Set of raw data values on input port pins
	timer my_tymer;


	init_qei_data( qei_data_s ,0 ); // Initialise QEI data for motor_0

	pQEI :> inp_pins;
	my_tymer :> qei_data_s.inp_time;

	while (1) {
#pragma xta endpoint "qei_main_loop"
		select {
			// Service any change on input port pins
			case pQEI when pinsneq(inp_pins) :> inp_pins :
			{
				service_input_pins( qei_data_s ,inp_pins );
			} // case
			break;

			// Service any client request for data
			case c_qei :> int :
			{
				service_client_request( qei_data_s ,c_qei );
			} // case
			break;
		} // select
	}	// while (1)
} // do_qei
/*****************************************************************************/
#pragma unsafe arrays
void do_multiple_qei( // Get QEI data from motor and send to client
	streaming chanend c_qei[], // Array of data channel to client (carries processed QEI data)
	port in pQEI[] 						 // Array of input port (carries raw QEI motor data)
)
{
	QEI_PARAM_S all_qei_s[NUMBER_OF_MOTORS]; // Array of structures containing QEI parameters for all motor
	unsigned inp_pins[NUMBER_OF_MOTORS]; // Set of raw data values on input port pins
	timer my_tymer;


	for (int q=0; q<NUMBER_OF_MOTORS; ++q) 
	{
		init_qei_data( all_qei_s[q] ,q ); // Initialise QEI data for current motor

		pQEI[q] :> inp_pins[q];
		my_tymer :> all_qei_s[q].inp_time;
	}

	while (1) {
#pragma xta endpoint "qei_main_loop"
		select {
			// Service any change on input port pins
			case (int q=0; q<NUMBER_OF_MOTORS; ++q) pQEI[q] when pinsneq(inp_pins[q]) :> inp_pins[q] :
			{
				service_input_pins( all_qei_s[q] ,inp_pins[q] );
			} // case
			break;

			// Service any client request for data
			case (int q=0; q<NUMBER_OF_MOTORS; ++q) c_qei[q] :> int :
			{
				service_client_request( all_qei_s[q] ,c_qei[q] );
			} // case
			break;
		} // select
	}	// while (1)
} // do_multiple_qei
/*****************************************************************************/
// qei_server.xc


