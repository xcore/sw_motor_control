/**
 * \file adc_common.h
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
#ifndef __ADC_COMMON_H__
#define __ADC_COMMON_H__

// The token which is passed over the control channel for triggering the ADC
#define ADC_TRIG_TOKEN  1

// The number of channels to store when sampling the ADC
#define ADC_CHANS 6

// Count of the number of elements in the ADC filter array
#define ADC_FILT_SAMPLE_COUNT 31

#endif /* __ADC_COMMON_H__ */
