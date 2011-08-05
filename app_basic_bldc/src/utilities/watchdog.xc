/**
 * Module:  app_basic_bldc
 * Version: 1v0alpha1
 * Build:   1a950f97dabd166488e2b4ec0bb1fd750b532de8
 * File:    watchdog.xc
 * Modified by : Srikanth
 * Last Modified on : 05-Jul-2011
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
#include "watchdog.h"
#include <xs1.h>

/* handle all watchdog functions */
void do_wd(chanend c_wd, out port wd)
{
	unsigned cmd;
	unsigned shared_out = 0;

	timer t;
	unsigned ts;
	unsigned ts2;

	t :> ts;

	while (1)
	{
		select
		{
			case c_wd :> cmd:
				switch(cmd)
				{
				case WD_CMD_START: // produce a rising edge on the WD_EN
					t :> ts;
					shared_out &= ~0x1;
					wd <: shared_out; // go low
					t :> ts2;
					t when timerafter(ts2+10000) :> ts2;
					shared_out |= 0x1;
					wd <: shared_out; // go high
					break;
				}
				break;
			case t when timerafter(ts + 100000) :> ts:
				shared_out ^= 0x2;
				break;
		}
		wd <: shared_out;
	}

}
