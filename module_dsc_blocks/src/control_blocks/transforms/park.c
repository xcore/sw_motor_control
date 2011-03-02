/**
 * Module:  module_dsc_blocks
 * Version: 1v0alpha1
 * Build:   128bfdf87839aeec0e38320c3524102eb996ecd5
 * File:    park.c
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
	long long tmp;

	tmp = (( (I_alpha * cosine( theta )) + (I_beta * sine( theta ))) >> 32);
	*Id = (int)tmp;

	tmp = (( (I_beta * cosine( theta )) - (I_alpha * sine( theta ))) >> 32);
	*Iq = (int)tmp;
}


// Do an inverse park transform
void inverse_park_transform( int *I_alpha, int *I_beta, int Id, int Iq, unsigned theta )
{
	long long tmp;

	tmp = (( ((long long)Id * cosine( theta )) - ((long long)Iq *   sine( theta )) ) >> 32);
	*I_alpha = (int)tmp;

	tmp = (( ((long long)Id *   sine( theta )) + ((long long)Iq * cosine( theta )) ) >> 32);
	*I_beta = (int)tmp;

}
