/**
 * Module:  module_dsc_blocks
 * Version: 1v0alpha1
 * Build:   128bfdf87839aeec0e38320c3524102eb996ecd5
 * File:    sine_lookup.h
 * Modified by : Srikanth
 * Last Modified on : 04-May-2011
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
#ifndef __SINE_LOOKUP_H__
#define __SINE_LOOKUP_H__

extern int sine_table[];

/** \brief Look up the fixed point sine value
 *
 * This looks up the sine of a value. The value is the index into the
 * sine table, rather than a particular angualar measurement.
 *
 * \brief deg the index of the sine value to look up
 */
int sine( unsigned deg );

/** \brief Look up the fixed point cosine value
 *
 * This looks up the cosine of a value. The value is the index into the
 * sine table, rather than a particular angualar measurement.
 *
 * \brief deg the index of the cosine value to look up
 */
int cosine( unsigned deg );

#endif /*__SINE_LOOKUP_H__*/
