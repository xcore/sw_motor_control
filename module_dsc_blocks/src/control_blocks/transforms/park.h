/*
 * Module:  module_dsc_blocks
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
 */                                   
#ifndef PARK_H_
#define PARK_H_

#ifdef __XC__

	// XC versions

	/** \brief Perform a Park transform
	 *
	 * A Park transform is a 2D to 2D transform which takes the radial and tangential
	 * components of a measurement (for instance the magnetic flux or total coil
	 * currents) and converts them to a rotating frame of reference.  Typically
	 * this is the rotating frame of reference attached to the spinning rotor.
	 *
	 * \param Id the output tangential component
	 * \param Iq the output radial component
	 * \param I_alpha the input tangential component
	 * \param I_beta the input radial component
	 * \param theta the angle between the fixed and rotating frames of reference
	 */
	void park_transform( int &Id, int &Iq, int I_alpha, int I_beta, unsigned theta );


	/** \brief Perform an inverse Park transform
	 *
	 * A Park transform is a 2D to 2D transform which takes the radial and tangential
	 * components of a measurement (for instance the magnetic flux or total coil
	 * currents) and converts them to a rotating frame of reference.  Typically
	 * this is the rotating frame of reference attached to the spinning rotor.
	 *
	 * \param I_alpha the output tangential component
	 * \param I_beta the output radial component
	 * \param Id the input tangential component
	 * \param Iq the intput radial component
	 * \param theta the angle between the fixed and rotating frames of reference
	 */
	void inverse_park_transform( int &I_alpha, int &I_beta, int Id, int Iq, unsigned theta );

#else

	// C versions
	void park_transform( int *Id, int *Iq, int I_alpha, int I_beta, unsigned theta );
	void inverse_park_transform( int *I_alpha, int *I_beta, int Id, int Iq, unsigned theta );

#endif

#endif /* PARK_H_ */
