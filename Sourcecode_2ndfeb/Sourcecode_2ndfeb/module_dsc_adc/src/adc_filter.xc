/**
 * Module:  module_dsc_adc
 * Version: 1v0alpha3
 * Build:   dcbd8f9dde72e43ef93c00d47bed86a114e0d6ac
 * File:    adc_filter.xc
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
#include <xclib.h>
#include <xs1.h>
#include "adc_common.h"


#pragma unsafe arrays
{int,int,int} do_lp_filter( int adc0_val[], int adc1_val[], int adc2_val[], unsigned pos )
{
	static int xcoeffs[] = {
	  -1837118, -1292872,  -495230,   558396,  1855534,  3368050,
	   5052608,  6852256,  8699044, 10517552, 12229104, 13756388,
	  15028144, 15983602, 16576332, 16777214, 16576332, 15983602,
	  15028144, 13756388, 12229104, 10517552,  8699044,  6852256,
	   5052608,  3368050,  1855534,   558396,  -495230, -1292872,
	  -1837118,
	  -1837118, -1292872,  -495230,   558396,  1855534,  3368050,
	  5052608,  6852256,  8699044, 10517552, 12229104, 13756388,
	  15028144, 15983602, 16576332, 16777214, 16576332, 15983602,
	  15028144, 13756388, 12229104, 10517552,  8699044,  6852256,
	  5052608,  3368050,  1855534,   558396,  -495230, -1292872,
	  -1837118,
	};

	int r0=0,r1=0,r2=0,h=0,l=0,j=0;

	#pragma loop unroll
	for (j = 0; j <= ADC_FILT_SAMPLE_COUNT; j++) {h,l} = macs(xcoeffs[pos+j], adc0_val[j], h, l);

	r0  = (l >> 12) & 0x000FFFFF;
	r0 |= (h << 20) & 0xFFF00000;
	r0 >>= 12;
	{r0,l} = macs(r0,312640474,0,0);

	h=l=0;
	#pragma loop unroll
	for (j = 0; j <= ADC_FILT_SAMPLE_COUNT; j++) {h,l} = macs(xcoeffs[pos+j], adc1_val[j], h, l);

	r1  = (l >> 12) & 0x000FFFFF;
	r1 |= (h << 20) & 0xFFF00000;
	r1 >>= 12;
	{r1,l} = macs(r1,312640474,0,0);

	h=l=0;
	#pragma loop unroll
	for (j = 0; j <= ADC_FILT_SAMPLE_COUNT; j++) {h,l} = macs(xcoeffs[pos+j], adc2_val[j], h, l);

	r2  = (l >> 12) & 0x000FFFFF;
	r2 |= (h << 20) & 0xFFF00000;
	r2 >>= 12;
	{r2,l} = macs(r2,312640474,0,0);

	return {r0,r1,r2};
}
