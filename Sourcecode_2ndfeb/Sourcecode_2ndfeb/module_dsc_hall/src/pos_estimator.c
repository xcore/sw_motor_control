/**
 * Module:  module_dsc_hall
 * Version: 1v0alpha1
 * Build:   128bfdf87839aeec0e38320c3524102eb996ecd5
 * File:    pos_estimator.c
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
#include "pos_estimator.h"

#define TABLE_ENTRIES_PER_COMM	600

unsigned pos_estimation_lookup[TABLE_ENTRIES_PER_COMM * 6];


// initialise the lookup table
void init_pos_estimation( )
{
	for (int i = 0; i < (TABLE_ENTRIES_PER_COMM * 6); i++ )
	{
		// 600 tenths of a degree per comutation, matches our sine lookup
		pos_estimation_lookup[i] = (i * 600) / TABLE_ENTRIES_PER_COMM;
	}
}


// calculate the increment in the last sector based on number of PWM cycles
unsigned pos_hall_update(unsigned ticks )
{
	unsigned new_inc;

	// calculate increment
	if (ticks == 0)
	{
		new_inc = TABLE_ENTRIES_PER_COMM * 3;
	}
	else
	{
		// calculate inc, do rounding
		new_inc = ((TABLE_ENTRIES_PER_COMM*3)<<16) / ticks;
		new_inc = new_inc + 52428; // plus 0.8 * 2^16, so round up boundary is 0.2
		new_inc = new_inc >> 16;
	}

	if (new_inc == 0)
	{
		new_inc = 1;
	}

	return new_inc;
}


//
unsigned get_pos( unsigned inc, int *pos, unsigned *ticks )
{
	// update position & num ticks
	*pos = *pos + inc;
	*ticks += 1;

	// wrap around
	if (*pos > (TABLE_ENTRIES_PER_COMM * 6))
	{
		*pos = 0;
	}

	// make sure we don't overflow
	while (*pos > (TABLE_ENTRIES_PER_COMM * 6))
	{
		*pos -=  (TABLE_ENTRIES_PER_COMM * 6);
	}

	// return theta
	return pos_estimation_lookup[*pos];
}
