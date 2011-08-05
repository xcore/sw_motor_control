/**
 * Module:  module_dsc_blocks
 * Version: 1v0alpha1
 * Build:   128bfdf87839aeec0e38320c3524102eb996ecd5
 * File:    park.h
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
#ifndef PARK_H_
#define PARK_H_

#ifdef __XC__

	// XC versions
	void park_transform( int &Id, int &Iq, int I_alpha, int I_beta, unsigned theta );
	void inverse_park_transform( int &I_alpha, int &I_beta, int Id, int Iq, unsigned theta );

#else

	// C versions
	void park_transform( int *Id, int *Iq, int I_alpha, int I_beta, unsigned theta );
	void inverse_park_transform( int *I_alpha, int *I_beta, int Id, int Iq, unsigned theta );

#endif

#endif /* PARK_H_ */
