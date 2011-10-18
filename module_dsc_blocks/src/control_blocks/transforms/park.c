/**
 * Module:  module_dsc_blocks
 * Version: 1v0alpha1
 * Build:   128bfdf87839aeec0e38320c3524102eb996ecd5
 * File:    park.c
 * Modified by: Upendra
 * Last Modified on : 18-May-2011
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
#include "park.h"
#include "transform_constants.h"
#include "sine_lookup.h"

// Do a park transform
void park_transform( int *Id, int *Iq, int I_a, int I_b, unsigned theta )
{
	int tmp;
	int s = sine( theta );
	int c = cosine( theta );

	tmp = (((I_a * c ) >> 14) + ((I_b * s ) >> 14));
	*Id = tmp ;

	tmp = (((I_b * c ) >> 14) - ((I_a * s ) >> 14));
	*Iq = tmp ;

}


// Do an inverse park transform
void inverse_park_transform( int *I_alpha, int *I_beta, int Id, int Iq, unsigned theta )
{
	int tmp;
	int s = sine( theta );
	int c = cosine( theta );

	tmp = ((( Id * c ) >> 14) - ((Iq * s ) >> 14));
	*I_alpha = tmp;

	tmp = ((( Id * s ) >> 14) + ((Iq * c ) >> 14));
	*I_beta = tmp;

}
