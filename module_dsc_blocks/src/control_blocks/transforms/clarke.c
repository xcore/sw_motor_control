/**
 * Module:  module_dsc_blocks
 * Version: 1v0alpha1
 * Build:   128bfdf87839aeec0e38320c3524102eb996ecd5
 * File:    clarke.c
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
#include "clarke.h"
#include "transform_constants.h"


// Do a clarke transform
void clarke_transform( int *I_alpha, int *I_beta, int Ia, int Ib, int Ic )
{
	int tmp;

	tmp = Ia - ((Ib +Ic)>>1);
	*I_alpha = (tmp * ONE_PU)/THREE_BY_2PU;

	tmp = (ROOT_3_BY_2 * (Ib - Ic))>>14;
	*I_beta = (tmp * ONE_PU)/THREE_BY_2PU;

}


// Do an inverse clarke transform
void inverse_clarke_transform( int *Ia, int *Ib, int *Ic, int alpha, int beta )
{
	int tmp ;

	*Ia = beta;

	tmp = (-beta ) + ((ROOT_THREE * alpha ) >> 14);
	tmp = tmp >> 1;
	*Ib = tmp;

	tmp = (-beta ) - ((ROOT_THREE * alpha ) >> 14);
	tmp = tmp >> 1;
	*Ic = tmp;

}

