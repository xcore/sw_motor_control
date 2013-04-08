/**
 * The copyrights, all other intellectual and industrial 
 * property rights are retained by XMOS and/or its licensors. 
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2013
 *
 * In the case where this code is a modification of existing code
 * under a separate license, the separate license terms are shown
 * below. The modifications to the code are still covered by the 
 * copyright notice above.
 *
 **/                                   

#include "hall_client.h"


/*****************************************************************************/
unsigned get_hall_data(
	streaming chanend c_hall // Streaming channel for Hall sensor data
)
{
	unsigned new_hall; // new hall data


	c_hall <: HALL_CMD_DATA_REQ; // Request new hall sensor data
	c_hall :> new_hall;						// Read new hall sensor data

	return new_hall;
} // get_hall_data
/*****************************************************************************/
{unsigned, unsigned, unsigned} get_hall_pos_speed_delta( chanend c_hall )
{
	unsigned theta, speed, delta;

	/* get position & speed & delta*/
	c_hall <: 0;
	c_hall :> theta;
	c_hall :> speed;
	c_hall :> delta;

	return {theta, speed, delta};
} // get_hall_pos_speed_delta
/*****************************************************************************/
// hall_client.xc
