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
#include <stdlib.h>
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
	inp_qei_s.diff_time = 0; // NB Initially this is used to count input-pin changes
	inp_qei_s.id = inp_id; // Clear Previous phase values
	inp_qei_s.orig_cnt = 0; // Reset counter indicating how many times motor has passed origin (index)
	inp_qei_s.ang_cnt = 0; // Reset counter indicating angular position of motor (from origin)
	inp_qei_s.theta = 0; // Reset angular position returned to client
	inp_qei_s.spin_sign; // Clear Sign of spin direction
	inp_qei_s.prev_state = QEI_STALL; // Initialise previous QEI state
	inp_qei_s.err_cnt = 0; // Initialise counter for invalid QEI states
	inp_qei_s.confid = 1; // Initialise confidence value

	inp_qei_s.prev_time = 0;
	inp_qei_s.prev_orig = 0;
	inp_qei_s.prev_phases = 0;

	inp_qei_s.filt_val = 0; // filtered value
	inp_qei_s.coef_err = 0; // Coefficient diffusion error
	inp_qei_s.scale_err = 0; // Scaling diffusion error 

	inp_qei_s.dbg = 0;
} // init_qei_data
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

		if (inp_ang > (-QEI_PER_REV))
		{
			out_theta = inp_ang; // Normal case -ve
		} // if (inp_ang > -QEI_PER_REV)
		else 
		{
			if (inp_ang > (-QEI_CNT_LIMIT))
			{
				out_theta = inp_ang + QEI_PER_REV; // False -ve counts occured
			} // if (inp_ang > -QEI_CNT_LIMIT)
			else 
			{ // Origin Missed - Correct counters
				inp_qei_s.orig_cnt--; // Decrement origin counter
				inp_qei_s.ang_cnt += QEI_PER_REV; // Add a whole rotation

				out_theta = inp_qei_s.ang_cnt; // Now a normal case -ve
			} // else !(inp_ang < QEI_CNT_LIMIT)
		} // else !(inp_ang > -QEI_CNT_LIMIT)
		
	} // if (0 > inp_ang)
	else
	{ // Positive angles

		if (inp_ang < QEI_PER_REV)
		{
			out_theta = inp_ang; // Normal case +ve
		} // if (inp_ang < QEI_PER_REV)
		else 
		{
			if (inp_ang < QEI_CNT_LIMIT)
			{
				out_theta = inp_ang - QEI_PER_REV; // False +ve counts occured
			} // if (inp_ang < QEI_CNT_LIMIT)
			else 
			{ // Origin Missed - Correct counters
				inp_qei_s.orig_cnt++; // Increment origin counter
				inp_qei_s.ang_cnt -= QEI_PER_REV; // Subtract a whole rotation

				out_theta = inp_qei_s.ang_cnt; // Now a normal case +ve
			} // else !(inp_ang > -QEI_CNT_LIMIT)
		} // else !(inp_ang < QEI_PER_REV)

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
 *	Order is 00 -> 01 -> 11 -> 10  Clockwise direction
 *	Order is 00 -> 10 -> 11 -> 01  Anti-Clockwise direction
 *
 *	Spin-state is
 *		-1: CLOCK Clocwise rotation, 
 *		 0: STALL (The motor has probably stopped)
 *		 1: ANTI Anti-Clocwise rotation, 
 *		 2: JUMP (The motor has probably jumped 2 phases)
 */

/*	NB We are going to use a convention that a Clock-wise spin has +ve value.
 *	This does NOT mean the motor will spin clock-wise! 
 *	This depends on the observers position relative to the motor.
 *	The following table satisfies the above convention when accessed as:-
 *		Spin = get_spin_state[Old_Phase][New_phase]
 */
static const signed char get_spin_state[QEI_PHASES][QEI_PHASES] = {
		{ QEI_STALL,	QEI_CLOCK,	QEI_ANTI,		QEI_JUMP	}, // 00
		{ QEI_ANTI,		QEI_STALL,	QEI_JUMP,		QEI_CLOCK	}, // 01
		{ QEI_CLOCK,	QEI_JUMP,		QEI_STALL,	QEI_ANTI	}, // 10
		{ QEI_JUMP,		QEI_ANTI,		QEI_CLOCK,	QEI_STALL	}  // 11
};

	QEI_ENUM_TYP cur_state; // current QEI spin state
	unsigned ang_time; // time when angular position measured
	unsigned cur_phases; // Current set of phase values
	unsigned orig_flg; // Flag set when motor at origin position 
	signed char cur_spin; // current spin direction
	int cur_theta; // current theta value (returned to client)
	int test_diff; // test time difference for sensible value
	timer my_tymer;


// if (inp_qei_s.id) xscope_probe_data( 5 ,(inp_pins << 10));
	cur_phases = inp_pins & 0x3; // Extract Phase bits

	// Check if phases have changed
	if (cur_phases != inp_qei_s.prev_phases) 
	{
		// Get new time stamp ..
		my_tymer :> ang_time;	// Get new time stamp
		test_diff = (int)(ang_time - inp_qei_s.prev_time);

// if (inp_qei_s.id) xscope_probe_data( 4 ,(ang_time >> 20) );
		// Check for sensible time
		if (THR_TICKS_PER_QEI < test_diff)
		{ // Sensible time!
			// Update QEI-state
			cur_state = get_spin_state[inp_qei_s.prev_phases][cur_phases]; // Decoded spin fom phase info. New Correct

			cur_spin = get_spin_value( inp_qei_s ,cur_state );

			// Update spin direction	
			if (cur_spin < 0)
			{
				inp_qei_s.spin_sign = -1; // -ve spin direction
			} // if (cur_spin < 0)
			else
			{
				inp_qei_s.spin_sign = 1;  // +ve spin direction
			} // else !(cur_spin < 0)

			inp_qei_s.ang_cnt += cur_spin; // Increment/Decrement angular position
	
			orig_flg = inp_pins & 0x4; 		// Extract origin flag 
	
			// Check if motor at origin
			if (orig_flg != inp_qei_s.prev_orig)
			{
				if (orig_flg)
				{ // Reset position ( 'orig_flg' transition  0 --> 1 )
					inp_qei_s.orig_cnt += inp_qei_s.spin_sign; // Update origin counter
					inp_qei_s.ang_cnt = 0; // Reset position value
				} // if (orig_flg)
	
				inp_qei_s.prev_orig = orig_flg;
			} // if (orig_flg != inp_qei_s.prev_orig)
	
			// Update theta value
			cur_theta = get_theta_value( inp_qei_s ,inp_qei_s.ang_cnt );
			inp_qei_s.theta = cur_theta; // Store angular position at new time stamp

			// Check for end of start-up phase
			if (START_UP_CHANGES <= inp_qei_s.diff_time)
			{
				inp_qei_s.diff_time = test_diff; // Store sensible time difference
			} // if (START_UP_CHANGES <= inp_qei_s.diff_time)
			else
			{
				inp_qei_s.diff_time++; // Update number of input pin changes
			} // if (START_UP_CHANGES <= inp_qei_s.diff_time)

			inp_qei_s.prev_time = ang_time; // Store time stamp
			inp_qei_s.prev_phases = cur_phases; // Store old phase value

// if (inp_qei_s.id) xscope_probe_data( 0 ,inp_qei_s.theta );
// if (inp_qei_s.id) xscope_probe_data( 1 ,(inp_qei_s.spin_sign << 9) );
// if (inp_qei_s.id) xscope_probe_data( 2 ,(inp_qei_s.diff_time >> 2) );
		} // if (THR_TICKS_PER_QEI < test_diff)
	}	// if (cur_phases != inp_qei_s.prev_phases)
} // service_input_pins
/*****************************************************************************/
int filter_velocity( // Smooths velocity estimate using low-pass filter
	QEI_PARAM_S &qei_data_s, // Reference to structure containing QEI parameters for one motor
	int meas_veloc // Angular velocity of motor measured in Ticks/angle_position
) // Returns filtered output value
/* This is a 1st order IIR filter, it is configured as a low-pass filter, 
 * The input velocity value is up-scaled, to allow integer arithmetic to be used.
 * The output mean value is down-scaled by the same amount.
 * Error diffusion is used to keep control of systematic quantisation errors.
 */
{
	int scaled_inp = (meas_veloc << QEI_SCALE_BITS); // Upscaled QEI input value
	int diff_val; // Difference between input and filtered output
	int increment; // new increment to filtered output value
	int out_val; // filtered output value


	// Form difference with previous filter output
	diff_val = scaled_inp - qei_data_s.filt_val;

	// Multiply difference by filter coefficient (alpha)
	diff_val += qei_data_s.coef_err; // Add in diffusion error;
	increment = (diff_val + QEI_HALF_COEF) >> QEI_COEF_BITS ; // Multiply by filter coef (with rounding)
	qei_data_s.coef_err = diff_val - (increment << QEI_COEF_BITS); // Evaluate new quantisation error value 

	qei_data_s.filt_val += increment; // Update (up-scaled) filtered output value

	// Update mean value by down-scaling filtered output value
	qei_data_s.filt_val += qei_data_s.scale_err; // Add in diffusion error;
	out_val = (qei_data_s.filt_val + QEI_HALF_SCALE) >> QEI_SCALE_BITS; // Down-scale
	qei_data_s.scale_err = qei_data_s.filt_val - (out_val << QEI_SCALE_BITS); // Evaluate new remainder value 

	return out_val; // return filtered output value
} // filter_velocity
/*****************************************************************************/
#pragma unsafe arrays
void service_client_request( // Send processed QEI data to client
	QEI_PARAM_S &inp_qei_s, // Reference to structure containing QEI parameters for one motor
	streaming chanend c_qei // Data channel to client (carries processed QEI data)
)
/*	The speed is calculated assuming the angular change is always 1 position.
 *	Experiment shows this to be more robust than using the actual position change, e.g. one of [0, 1, 2]
 *	This is because, the actual positions are estimates (and are sometimes incorrect)
 *	Whereas using the value 1, is effectively applying a lo-pass filter to the position change.
 *
 *	NB If angular position has NOT updated since last transmission, then the same data is re-transmitted
 */
{
	int meas_veloc; // Angular velocity of motor measured in Ticks/angle_position
	int smooth_veloc; // Smoothed velocity (low-pass filtered)


	// Check if we have received sufficient data to estimate velocity
  if (START_UP_CHANGES < inp_qei_s.diff_time)
	{
		meas_veloc = inp_qei_s.spin_sign * (int)TICKS_PER_MIN_PER_QEI / (int)inp_qei_s.diff_time; // Calculate new speed estimate.
  } // if (START_UP_CHANGES < inp_qei_s.diff_time)
	else
	{
		meas_veloc = inp_qei_s.spin_sign; // Default value
  } // if else !(START_UP_CHANGES < inp_qei_s.diff_time)

	smooth_veloc = filter_velocity( inp_qei_s ,meas_veloc );
// if (inp_qei_s.id) xscope_probe_data( 1 ,smooth_veloc);
// if (inp_qei_s.id) xscope_probe_data( 1 ,smooth_veloc);

	c_qei <: (inp_qei_s.theta & QEI_REV_MASK); // Send value in range [0..QEI_REV_MASK]
	c_qei <: smooth_veloc;			
	c_qei <: inp_qei_s.orig_cnt;
} // service_client_request
/*****************************************************************************/
#pragma unsafe arrays
void do_qei ( 
	unsigned motor_id, // Motor identifier
	streaming chanend c_qei, // data channel to client (carries processed QEI data)
	port in pQEI  						// Input port (carries raw QEI motor data)
)
{
	QEI_PARAM_S qei_data_s; // Structure containing QEI parameters for one motor
	unsigned inp_pins; // Set of raw data values on input port pins


	init_qei_data( qei_data_s ,motor_id ); // Initialise QEI data for motor_0

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


	for (int motor_id=0; motor_id<NUMBER_OF_MOTORS; ++motor_id) 
	{
		init_qei_data( all_qei_s[motor_id] ,motor_id ); // Initialise QEI data for current motor
	}

	while (1) {
#pragma xta endpoint "qei_main_loop"
#pragma ordered
		select {
			// Service any change on input port pins
			case (int motor_id=0; motor_id<NUMBER_OF_MOTORS; motor_id++) pQEI[motor_id] when pinsneq(inp_pins[motor_id]) :> inp_pins[motor_id] :
			{
				service_input_pins( all_qei_s[motor_id] ,inp_pins[motor_id] );
			} // case
			break;

			// Service any client request for data
			case (int motor_id=0; motor_id<NUMBER_OF_MOTORS; motor_id++) c_qei[motor_id] :> int :
			{
				service_client_request( all_qei_s[motor_id] ,c_qei[motor_id] );
			} // case
			break;
		} // select
	}	// while (1)
} // do_multiple_qei
/*****************************************************************************/
// qei_server.xc


