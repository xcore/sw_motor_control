/**
 * Module:  module_dsc_blocks
 * Version: 1v0alpha1
 * Build:   128bfdf87839aeec0e38320c3524102eb996ecd5
 * File:    sine_cosine.c
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
#include "sine_lookup.h"
#include "sine_table_big.h"

inline long long sine( unsigned deg )
{
	unsigned x = deg;

	return sine_table[x];
}

inline long long cosine( unsigned deg )
{
	unsigned x = deg + 900;

	while (x >= 3600)
	{
		x = x - 3600;
	}

	return sine_table[x];
}



