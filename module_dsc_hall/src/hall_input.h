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

	#define HALL_INV	99

	// Takes a 4 bit port, H1 on the MSB
	void run_hall( chanend c_hall, port in p_hall );

	// same as above, but some variations that are used for experimentaiton
	void run_hall_speed( chanend c_hall, chanend c_speed, port in p_hall );
	void run_hall_speed_timed_avg( chanend c_hall, chanend c_speed, port in p_hall );
	void run_hall_speed_timed( chanend c_hall, chanend c_speed, port in p_hall, chanend ?c_logging_0, chanend ?c_logging_1 );
	void do_hall( unsigned &hall_state, unsigned &cur_pin_state, port in p_hall );
	select do_hall_select( unsigned &hall_state, unsigned &cur_pin_state, port in p_hall );
	void do_hall_test( port in p_hall );

#endif /* _HALL_INPUT_H_ */



