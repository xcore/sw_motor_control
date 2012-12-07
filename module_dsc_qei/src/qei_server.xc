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

/*****************************************************************************/
void init_qei_data( // Initialise  QEI data for one motor
	QEI_PARAM_S &inp_qei_s, // Reference to structure containing QEI parameters for one motor
	int inp_id  // Input unique motor identifier
)
{
	inp_qei_s.id = inp_id; // Clear Previous phase values
	inp_qei_s.prev_phases = 0; // Clear Previous phase values
	inp_qei_s.orig_cnt = 0; // Reset counter indicating how many times motor has passed origin (index)
	inp_qei_s.ang_cnt = 0; // Reset counter indicating angular position of motor (from origin)
	inp_qei_s.theta = 0; // Reset angular position returned to client
	inp_qei_s.prev_orig = 0; // Reset previous origin value
	inp_qei_s.prev_state = QEI_STALL; // Initialise previous QEI state
	inp_qei_s.err_cnt = 0; // Initialise counter for invalid QEI states
	inp_qei_s.confid = 1; // Initialise confidence value
} // service_client_request
/*****************************************************************************/
signed char get_spin_value( // Estimate spin value from QEI states
	QEI_PARAM_S &inp_qei_s, // Reference to structure containing QEI parameters for one motor
	QEI_ENUM_TYP cur_state // current QEI-state
) // Returns output spin value
{
	QEI_ENUM_TYP prev_state = inp_qei_s.prev_state; // local copy of previous QEI-state
	signed char out_spin; // Output spin value


	// Check bit_0 of previous state
	if (prev_state & 0x1)
	{ // Valid previous spin state (CLOCK or ANTI)

		// Check bit_0 of current state
		if (cur_state & 0x1)
		{ // Valid current spin state (CLOCK or ANTI)
			out_spin = prev_state; // Use previous spin (For this case state-value is spin value)

			// Check for change of valid state (CLOCK <--> ANTI)
			if (cur_state != prev_state)
			{
				// Check confidence levels
				if (0 < inp_qei_s.confid)
				{ // Still have some confidence
					cur_state = prev_state; // Revert to previous state
					inp_qei_s.confid--; // Decrease confidence level
				} // if (0 < inp_qei_s.confid)
				else
				{ // No confidence left. (Move to STALL state next time)
					cur_state = QEI_STALL; // Revert to previous state
					inp_qei_s.err_cnt = 0; // Reset count of invalid states
				} // else !(0 < inp_qei_s.confid)
			} // if (cur_state != prev_state)
			else
			{ // Normal Case: Maintainig same valid spin direction
				if (MAX_CONFID > inp_qei_s.confid) inp_qei_s.confid++; // Increase confidence level
			} // else !(cur_state != prev_state)
		} // if (cur_state & 0x1)
		else
		{ // Invalid current spin state (STALL or JUMP)
			if (QEI_JUMP != cur_state)
			{ // cur_state == QEI_STALL 
				out_spin = prev_state; // Stay with previous spin value for possible STALL
			} // if (QEI_JUMP != cur_state)
			else
			{ // cur_state == QEI_JUMP 
				out_spin = (prev_state << 1); // Double spin as phase jump detected
			} // else !(QEI_JUMP != cur_state)

			// Check confidence levels
			if (0 < inp_qei_s.confid)
			{ // Still have some confidence
				cur_state = prev_state; // Revert to previous state
				inp_qei_s.confid--; // Decrease confidence level
			} // if (0 < inp_qei_s.confid)
			else
			{ // No confidence left. (Will move to current invalid state next time)
				inp_qei_s.err_cnt = 0; // Reset count of invalid states
			} // else !(0 < inp_qei_s.confid)
		} // else !(cur_state & 0x1)
	} // if (prev_state & 0x1)
	else
	{ // Invalid previous spin state

		// Check bit_0 of current state
		if (cur_state & 0x1)
		{ // Valid current spin state (CLOCK or ANTI)
			out_spin = cur_state; // Use new state value

			inp_qei_s.confid++; // Increase confidence level
		} // if (cur_state & 0x1)
		else
		{ // Invalid current spin state (STALL or JUMP)
			out_spin = 0; // Zero Spin for invalid state

			assert(MAX_QEI_ERR > inp_qei_s.err_cnt); // Too Many QEI errors

			inp_qei_s.err_cnt++; // Increment invalid state cnt
		} // else !(cur_state & 0x1)
	} // else !(prev_state & 0x1)

	inp_qei_s.prev_state = cur_state; // Store old QEI state value

	return out_spin; // Return output spin value
} // get_spin_value
/*****************************************************************************/
int get_theta_value( // Calculate theta value (returned to client) from local angular count
	QEI_PARAM_S &inp_qei_s, // Reference to structure containing QEI parameters for one motor
	int inp_ang // local angular input count
) // Returns theta value
/*
 *	This function checks for a 'missed origin' and ensures theta is in correct range ...
 *	The local angular position (inp_qei_s.ang_cnt) should be in the range  
 *	-540 Degrees <= ang_cnt <= 540 degrees
 *  The theta value should be in the range  
 *	-360 Degrees <= ang_cnt <= 360 degrees
 *
 * The if-then-else statements are arranged with the most likely first to reduce computation
 */
{
	int out_theta; // theta value (returned to client)


	if (0 > inp_ang)
	{ // Negative angles

		if (inp_ang > (-QEI_COUNT_MAX))
		{
			out_theta = inp_ang; // Normal case -ve
		} // if (inp_ang > -QEI_COUNT_MAX)
		else 
		{
			if (inp_ang > (-QEI_CNT_LIMIT))
			{
				out_theta = inp_ang + QEI_COUNT_MAX; // False -ve counts occured
			} // if (inp_ang > -QEI_CNT_LIMIT)
			else 
			{ // Origin Missed - Correct counters
				inp_qei_s.orig_cnt++; // Increment origin counter
				inp_qei_s.ang_cnt += QEI_COUNT_MAX; // Add a whole rotation

				out_theta = inp_qei_s.ang_cnt; // Now a normal case -ve
			} // else !(inp_ang < QEI_CNT_LIMIT)
		} // else !(inp_ang > -QEI_CNT_LIMIT)
		
	} // if (0 > inp_ang)
	else
	{ // Positive angles

		if (inp_ang < QEI_COUNT_MAX)
		{
			out_theta = inp_ang; // Normal case +ve
		} // if (inp_ang < QEI_COUNT_MAX)
		else 
		{
			if (inp_ang < QEI_CNT_LIMIT)
			{
				out_theta = inp_ang - QEI_COUNT_MAX; // False +ve counts occured
			} // if (inp_ang < QEI_CNT_LIMIT)
			else 
			{ // Origin Missed - Correct counters
				inp_qei_s.orig_cnt++; // Increment origin counter
				inp_qei_s.ang_cnt -= QEI_COUNT_MAX; // Subtract a whole rotation

				out_theta = inp_qei_s.ang_cnt; // Now a normal case +ve
			} // else !(inp_ang > -QEI_CNT_LIMIT)
		} // else !(inp_ang < QEI_COUNT_MAX)

	} // else !(0 > inp_ang)

	return out_theta; // return theta value (returned to client)
} // get_theta_value  
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

	QEI_ENUM_TYP cur_state; // current QEI spin state
	unsigned cur_phases; // Current set of phase values
	unsigned origin; // Flag set when motor at origin position 
	signed char cur_spin; // current spin direction
	int cur_theta; // current theta value (returned to client)
	timer my_tymer;


	origin = inp_pins & 0x4; 		// Extract origin flag 
	cur_phases = inp_pins & 0x3; // Extract Phase bits

	// Check if phases have changed
	if (cur_phases != inp_qei_s.prev_phases) 
	{
		// Get new time stamp ..
		inp_qei_s.prev_time = inp_qei_s.inp_time; // Store previous time stamp
		my_tymer :> inp_qei_s.inp_time;		// Get new time stamp

		// Update QEI-state
		cur_state = get_spin_state[cur_phases][inp_qei_s.prev_phases]; // Decoded spin fom phase info.
	
		// Update spin value
		cur_spin = get_spin_value( inp_qei_s ,cur_state );

		inp_qei_s.ang_cnt += cur_spin; // Increment/Decrement angular position

		// Check if motor at origin
		if (origin != inp_qei_s.prev_orig)
		{
			if (origin)
			{ // Reset position ( Origin transition  0 --> 1 )
				inp_qei_s.orig_cnt++; // Increment origin counter
				inp_qei_s.ang_cnt = 0; // Reset position value
			} // if (origin)

			inp_qei_s.prev_orig = origin;
		} // if (origin != inp_qei_s.prev_orig)

		// Update theta value
		cur_theta = get_theta_value( inp_qei_s ,inp_qei_s.ang_cnt );
		inp_qei_s.theta = cur_theta; // NB Dummy variable used due to XC restrictions

		inp_qei_s.prev_phases = cur_phases; // Store old phase value
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
	c_qei <: inp_qei_s.theta;
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


