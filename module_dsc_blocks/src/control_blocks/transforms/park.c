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
void park_transform( int *Id, int *Iq, int I_alpha, int I_beta, unsigned theta )
{
	int tmp;

	tmp = (((I_alpha * cosine( theta )) >> 14) + ((I_beta * sine( theta )) >> 14));
	*Id = tmp ;

	tmp = (((I_beta * cosine( theta )) >> 14) - ((I_alpha * sine( theta ))>> 14));
	*Iq = tmp ;

}


// Do an inverse park transform
void inverse_park_transform( int *I_alpha, int *I_beta, int Id, int Iq, unsigned theta )
{
	int tmp;

	tmp = (((Id * cosine( theta ))/16384) - ((Iq *  sine( theta )) /16384));
	*I_alpha = tmp;

	tmp = ((( Id *   sine( theta ))/16384)+ ((Iq * cosine( theta ))/16384));
	*I_beta = tmp;

}
