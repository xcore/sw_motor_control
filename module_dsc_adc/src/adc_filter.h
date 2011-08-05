/**
 * Module:  module_dsc_adc
 * Version: 1v0alpha1
 * Build:   1dad8e7b44076dc4fbd1a5431e1773c4e9b94f42
 * File:    adc_filter.h
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
#include "adc_common.h"

{int,int,int} do_lp_filter( int adc0_val[], int adc1_val[], int adc2_val[], unsigned pos );
