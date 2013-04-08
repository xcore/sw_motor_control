/**
 * Module:  module_dsc_hall
 * Version: 1v0alpha2
 * Build:   c8420856b3ffd33a58ac7544991fc1ed1d35737c
 * File:    hall_input.h
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
#ifndef _HALL_INPUT_H_
#define _HALL_INPUT_H_

#include <xs1.h>

#ifndef NUMBER_OF_POLES       
#define NUMBER_OF_POLES       4
#endif // NUMBER_OF_POLES       

// Indicates an invalid hall state
#define HALL_INV	99

/** \brief A basic hall encoder server
 *
 *  This implements the basic hall sensor server
 *
 *  \param c_hall the control channel for reading hall position
 *  \param p_hall the port for reading the hall sensor data
 */
void run_hall( chanend c_hall, port in p_hall );

/** \brief A hall encoder server that also calculates motor speed
 *
 *  This implements the hall sensor server
 *
 *  \param c_hall the control channel for reading hall position
 *  \param c_speed the control channel for reading the rotor speed
 *  \param p_hall the port for reading the hall sensor data
 */
void run_hall_speed( chanend c_hall, chanend c_speed, port in p_hall );

/** \brief A hall encoder server that also calculates motor speed
 *
 *  This implements the hall sensor server, where the speed is
 *  calculated using a timed average of many values.
 *
 *  \param c_hall the control channel for reading hall position
 *  \param c_speed the control channel for reading the rotor speed
 *  \param p_hall the port for reading the hall sensor data
 */
void run_hall_speed_timed_avg( chanend c_hall, chanend c_speed, port in p_hall );

/** \brief A hall encoder server that also calculates motor speed
 *
 *  This implements the hall sensor server, where the speed is
 *  calculated using a timed average of many values.
 *
 *  \param c_hall the control channel for reading hall position
 *  \param c_speed the control channel for reading the rotor speed
 *  \param p_hall the port for reading the hall sensor data
 *  \param c_logging_0 an optional channel for logging the hall data on port 0
 *  \param c_logging_1 an optional channel for logging the hall data on port 1
 */
void run_hall_speed_timed( chanend c_hall, chanend c_speed, port in p_hall, chanend ?c_logging_0, chanend ?c_logging_1 );

/** \brief A blocking read of the hall port
 *
 *   \param hall_state the output hall state
 *   \param cur_pin_state the last value read from the hall encoder port
 *   \param p_hall the hall port
 */
void do_hall( unsigned &hall_state, unsigned &cur_pin_state, port in p_hall );

/** \brief A selectable read of the hall pins
 *
 *   This selectable function becomes ready when the hall pins change state
 *
 *   \param hall_state the output hall state
 *   \param cur_pin_state the last value read from the hall encoder port
 *   \param p_hall the hall port
 */
select do_hall_select( unsigned &hall_state, unsigned &cur_pin_state, port in p_hall );


#endif /* _HALL_INPUT_H_ */



