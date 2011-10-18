/**
 * The copyrights, all other intellectual and industrial 
 * property rights are retained by XMOS and/or its licensors. 
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2011
 *
 * In the case where this code is a modification of existing code
 * under a separate license, the separate license terms are shown
 * below. The modifications to the code are still covered by the 
 * copyright notice above.
 *
 **/                                   
#include "sine_lookup.h"
#include "sine_table_big.h"

#define SINE_TABLE_LIMIT 256

int sine( unsigned angle )
{
#ifdef FAULHABER_MOTOR
	unsigned x = (angle >> 2)
#else
	unsigned x = angle;
#endif
	x &= (SINE_TABLE_LIMIT-1);
	return sine_table[x];
}


int cosine( unsigned angle )
{
#ifdef FAULHABER_MOTOR
	unsigned x = (angle>>2);
#else
	unsigned x = angle;
#endif
	x += (SINE_TABLE_LIMIT>>2);
	x &= (SINE_TABLE_LIMIT-1);
	return sine_table[x];
}

