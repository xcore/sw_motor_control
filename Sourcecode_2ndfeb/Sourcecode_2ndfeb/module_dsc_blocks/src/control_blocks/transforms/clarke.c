/**
 * Module:  module_dsc_blocks
 * Version: 1v0alpha1
 * Build:   128bfdf87839aeec0e38320c3524102eb996ecd5
 * File:    clarke.c
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
#include "clarke.h"
#include "transform_constants.h"


// Do a clarke transform
void clarke_transform( int *I_alpha, int *I_beta, int Ia, int Ib, int Ic )
{
	long long tmp;

	*I_alpha = Ia;

	tmp = ((ONE_OVER_ROOT_3 * Ib) - (ONE_OVER_ROOT_3 * Ic)) >> 32;
	*I_beta = (int)(tmp);
}


// Do an inverse clarke transform
void inverse_clarke_transform( int *Ia, int *Ib, int *Ic, int alpha, int beta )
{
	long long tmp;

	*Ia = alpha;

	tmp = (-alpha) + ((ROOT_THREE * (long long)beta) >> 32);
	tmp = tmp >> 1;
	*Ib = (int)tmp;

	tmp = (-alpha) - ((ROOT_THREE * (long long)beta) >> 32);
	tmp = tmp >> 1;
	*Ic = (int)tmp;
}
