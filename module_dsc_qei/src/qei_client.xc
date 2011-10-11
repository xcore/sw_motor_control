/**
 * Module:  module_dsc_qei
 * Version: 1v0alpha0
 * Build:   e89e295a87b36dc1ad5ce82058b7434d3df4bb94
 * File:    qei_client.xc
 * Modified by : Srikanth
 * Last Modified on : 26-May-2011
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

#ifdef FAULHABER_MOTOR
#define QEI_COUNT_MAX (1024 * 4)
#else
#define QEI_COUNT_MAX (256 * 4)
#endif

{unsigned, unsigned} get_qei_data( streaming chanend c_qei )
{
	unsigned p, t;

	c_qei <: QEI_CMD_POS_REQ;
	c_qei :> p;
	c_qei :> t;

	p &= (QEI_COUNT_MAX-1);

	return {t, p};
}

unsigned get_speed(unsigned ts, unsigned last_ts, unsigned pos, unsigned last_pos)
{
	unsigned speed;
	if (ts == last_ts)
		return 0;
	else
	{
		int delta = pos - last_pos;
		if (delta < 0) delta = -delta;

		// 24kHz main loop gives one measurement every 41.6usec
		// 4000RPM is 66.6 revs/sec
		// 66.6 revs/sec = 66.6*QEI_COUNT (=68266.6 counts/sec)
		// = approx 2.8 counts per sample - this is what we expect delta to be

		// 5859375 * 1024 = multiplier from revs per 10ns to RPM
		// QEI_COUNT_MAX = multiplier from QEI angle to full revolutions
		speed = 5859375 * delta / (QEI_COUNT_MAX / 1024);
		speed /= (ts - last_ts);
	}
	return speed;
}

