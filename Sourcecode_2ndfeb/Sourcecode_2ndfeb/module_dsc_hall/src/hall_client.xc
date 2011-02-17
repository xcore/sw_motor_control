/**
 * Module:  module_dsc_hall
 * Version: 1v0alpha2
 * Build:   60a90cca6296c0154ccc44e1375cc3966292f74e
 * File:    hall_client.xc
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
#include <xs1.h>

{unsigned, unsigned, unsigned} get_hall_pos_speed_delta( chanend c_hall )
{
	unsigned theta, speed, delta;

	/* get position & speed & delta*/
	c_hall <: 0;
	c_hall :> theta;
	c_hall :> speed;
	c_hall :> delta;

	return {theta, speed, delta};
}
