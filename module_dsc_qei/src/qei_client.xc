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
#include <xs1.h>
#include "qei_commands.h"
#include "qei_client.h"

{unsigned, unsigned, unsigned } get_qei_data( streaming chanend c_qei )
//MB~ {unsigned, unsigned, unsigned, unsigned } get_qei_data( streaming chanend c_qei ) //MB~ DBG
{
	unsigned meas_angl; // Angular position of motor (from origin)
	unsigned new_time; // New time stamp
	unsigned prev_time; // Previous time stamp
	unsigned angl_valid; // Flag set when angular position is valid
	unsigned meas_speed; // Speed calculated from time difference


//MB~	c_qei :> new_pins; // MB~ dbg
	c_qei <: QEI_CMD_POS_REQ;
	c_qei :> meas_angl;
	c_qei :> new_time;
	c_qei :> prev_time;
	c_qei :> angl_valid;

	meas_angl &= (QEI_COUNT_MAX-1);

	// Calculate the speed
	if (new_time == prev_time)
		meas_speed = 0;
	else {
#if PLATFORM_REFERENCE_MHZ == 100
		// 6000000000 = 10ns -> 1min (100 MHz ports)
		meas_speed = 3000000000 / ((new_time - prev_time) * QEI_COUNT_MAX);
		meas_speed <<= 1;
#else
		// 15000000000 = 4ns -> 1min (250 MHz ports)
		meas_speed = 1875000000 / ((new_time - prev_time) * QEI_COUNT_MAX);
		meas_speed <<= 3;
#endif
	}

	return { meas_speed ,meas_angl ,angl_valid };
//MB~		return {meas_speed, meas_angl, angl_valid, new_pins}; //MB~ dbg
}
