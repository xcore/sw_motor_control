/**
 * Module:  module_dsc_blocks
 * Version: 1v0alpha1
 * Build:   128bfdf87839aeec0e38320c3524102eb996ecd5
 * File:    clarke.h
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
#ifndef CLARKE_H_
#define CLARKE_H_

#ifdef __XC__

	// XC Versions
	void clarke_transform( int &I_alpha, int &I_beta, int Ia, int Ib, int Ic );
	void inverse_clarke_transform( int &Ia, int &Ib, int &Ic, int alpha, int beta );

#else

	// C Versions
	void clarke_transform( int *I_alpha, int *I_beta, int Ia, int Ib, int Ic );
	void inverse_clarke_transform( int *Ia, int *Ib, int *Ic, int alpha, int beta );

#endif

#endif /* CLARKE_H_ */
