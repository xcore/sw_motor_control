/*
 * Module:  module_dsc_blocks
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
 */                                   
#ifndef CLARKE_H_
#define CLARKE_H_

#ifdef __XC__

	// XC Versions

	/** \brief Perform a clarke transform
	 *
	 * A Clarke transform is a 3D to 2D transformation where the 3D components
	 * have only 2 degrees of freedom.  It is used to convert the three current
	 * values in the 120 degree separation coils into a radial and tangential
	 * component values.
	 *
	 * \param Ia the parameter from coil A
	 * \param Ib the parameter from coil B
	 * \param Ic the parameter from coil C
	 * \param I_alpha the output tangential component
	 * \param I_beta the output radial component
	 */
	void clarke_transform( int Ia, int Ib, int Ic, int &I_alpha, int &I_beta );

	/** \brief Perform an inverse clarke transform
	 *
	 * The inverse Clarke transform is a 2D to 3D transformation where the 3D components
	 * have only 2 degrees of freedom.  It is used to convert radial and tangential components
         * of the current vector into the three coil currents.
	 *
	 * \param Ia the output parameter for coil A
	 * \param Ib the output parameter for coil B
	 * \param Ic the output parameter for coil C
	 * \param alpha the input tangential component
	 * \param beta the input radial component
	 */
	void inverse_clarke_transform( int &Ia, int &Ib, int &Ic, int alpha, int beta );

#else

	// C Versions
	void clarke_transform( int Ia, int Ib, int Ic, int *I_alpha, int *I_beta );
	void inverse_clarke_transform( int *Ia, int *Ib, int *Ic, int alpha, int beta );

#endif

#endif /* CLARKE_H_ */
