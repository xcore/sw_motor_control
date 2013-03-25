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


void clarke_transform( // Do a clarke transform

	int Ia, 
	int Ib, 
	int Ic, 
	int *I_alpha, 
	int *I_beta 
)
{
	*I_alpha = Ia;
	*I_beta = (ONE_OVER_ROOT_3 * (Ib - Ic) + 8192 ) >> 14;
} // clarke_transform 
/*****************************************************************************/
void inverse_clarke_transform( // Inverse clarke transform
	int *Ia, 
	int *Ib, 
	int *Ic, 
	int alpha, 
	int beta 
)
{
	int sqrt3_beta = ((ROOT_THREE * beta ) >> 14); // sqrt(3) * beta


	*Ia = alpha;
	*Ib = (-alpha + sqrt3_beta) >> 1;
	*Ic = (-alpha - sqrt3_beta) >> 1;
} // inverse_clarke_transform
/*****************************************************************************/
// clarke.c
