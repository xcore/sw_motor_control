/**
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


void do_wd(chanend c_wd, out port wd)
{
	unsigned cmd, wd_enabled = 1, shared_out = 0;
	unsigned ts, ts2;
	timer t;

	t :> ts;

	// Loop forever processing commands
	while (1)
	{
		select
		{
			// Get a command from the out loop
			case c_wd :> cmd:
				switch(cmd)
				{
					case WD_CMD_START: // produce a rising edge on the WD_EN
						shared_out &= ~0x1;
						wd <: shared_out; // go low
						t :> ts2;
						t when timerafter(ts2+10000) :> ts2;
						shared_out |= 0x1;
						wd <: shared_out; // go high
						break;
	
					// if the watchdog is enabled, kick it
					case WD_CMD_DIS_MOTOR :
						// mark that the watchdog should now not run
						wd_enabled = 0;
						break;					
				}
				break;
				
			case t when timerafter(ts + 100000) :> ts:
				if ( wd_enabled == 1 )
				{
					shared_out ^= 0x2;
				}
				
				break;
		}
		
		// Send out the new value to the shared port
		wd <: shared_out;
	}
}
