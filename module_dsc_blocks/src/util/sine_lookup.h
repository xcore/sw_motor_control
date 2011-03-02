/**
 * Module:  module_dsc_blocks
 * Version: 1v0alpha1
 * Build:   128bfdf87839aeec0e38320c3524102eb996ecd5
 * File:    sine_lookup.h
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

extern long long sine_table[];

// Lookup sine value in integer tenths of degrees (so i = 10 is 1 deg)
// @return sin(x) * (2^32)
long long sine( unsigned deg );

// Lookup cosine value in integer tenths of degrees (so i = 10 is 1 deg)
// @return sin(x) * (2^32)
long long cosine( unsigned deg );

#endif /*__SINE_LOOKUP_H__*/
