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
#include "qei_server.h"
#include "qei_commands.h"
#include "dsc_config.h"

// This is the loop time for 4000RPM on a 1024 count QEI
#pragma xta command "analyze loop qei_main_loop"
#pragma xta command "set required - 14.64 us"


/*****************************************************************************/
void init_qei_data( // Initialise  QEI data for one motor
	QEI_PARAM_S &inp_qei_s // Reference to structure containing QEI parameters for one motor
)
{
	inp_qei_s.prev_phases = 0; // Clear Previous phase values
	inp_qei_s.orig_found = 0; // Clear flag indicating when motor at origin (index)
	inp_qei_s.ang_pos = 0; // Reset angular position of motor (from origin)
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
 *		 1: Anit-Clocwise, 
 *		 0: Unknown    (The motor has either stopped, or jumped one or more phases)
 *		-1: Clocwise, 
 */
static const signed char get_spin[QEI_PHASES][QEI_PHASES] = {
		{ 0, -1, 1, 0 }, // 00
		{ 1, 0, 0, -1 }, // 01
		{ -1, 0, 0, 1 }, // 10
		{ 0, 1, -1, 0 }  // 11
};

	unsigned cur_phases; // Current set of phase values
	unsigned origin; // Flag set when motor at origin position 
	signed char cur_spin; // current spin direction
	timer my_tymer;


	origin = inp_pins & 0x4; 		// Extract origin flag 
	cur_phases = inp_pins & 0x3; // Extract Phase bits

	// If phases have changed, get new time stamp
	if (cur_phases != inp_qei_s.prev_phases) 
	{
		inp_qei_s.prev_time = inp_qei_s.inp_time; // Store previous time stamp
		my_tymer :> inp_qei_s.inp_time;		// Get new time stamp
	}

	// Check if motor at origin
	if (origin)
	{ // Reset position
		inp_qei_s.ang_pos = 0; // Reset position value
		inp_qei_s.orig_found = 1; // Set origin found flag
	} // if (origin) 
	else 
	{ // Increment/Decrement position
		cur_spin = get_spin[cur_phases][inp_qei_s.prev_phases]; // Decoded spin fom phase info.
		inp_qei_s.ang_pos += cur_spin; // Increment/Decrement angular position
	} // else !(origin) 

	inp_qei_s.prev_phases = cur_phases; // Store phase value
} // service_input_pins
/*****************************************************************************/
#pragma unsafe arrays
void service_client_request( // Send processed QEI data to client
	QEI_PARAM_S &inp_qei_s, // Reference to structure containing QEI parameters for one motor
	streaming chanend c_qei // Data channel to client (carries processed QEI data)
)
{
	// Send processed QEI data to client
	c_qei <: inp_qei_s.ang_pos;
	c_qei <: inp_qei_s.inp_time;
	c_qei <: inp_qei_s.prev_time;
	c_qei <: inp_qei_s.orig_found;
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


	init_qei_data( qei_data_s );

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
		init_qei_data( all_qei_s[q] );

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


