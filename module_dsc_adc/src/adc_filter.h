/**
 * \file adc_filter.h
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

/** \brief Perform a low pass filter on the ADC values
 *
 * Perform a low pass filter consisting of ADC_FILT_SAMPLE_COUNT samples
 * on the filter data.
 *
 * \param adc0_val the array of values from ADC channel 0
 * \param adc1_val the array of values from ADC channel 1
 * \param adc2_val the array of values from ADC channel 2
 * \param pos the current fill marker in the array
 */
{int,int,int} do_lp_filter( int adc0_val[], int adc1_val[], int adc2_val[], unsigned pos );
