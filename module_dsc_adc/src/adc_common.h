/*
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

#include <xs1.h>

// Define this to include XSCOPE support
#define USE_XSCOPE 1

#ifdef USE_XSCOPE
#include <xscope.h>
#endif

#ifdef __dsc_config_h_exists__
#include <dsc_config.h>
#endif

#ifndef NUMBER_OF_MOTORS
#define NUMBER_OF_MOTORS 1
#endif

#define NUM_ADC_TRIGGERS NUMBER_OF_MOTORS	// The number of trigger channels coming from PWM units

/** Different ADC Phases */
typedef enum ADC_PHASE_ETAG
{
  ADC_PHASE_A = 0,
  ADC_PHASE_B,
  ADC_PHASE_C,
	NUM_ADC_PHASES // 3 ADC phases [A, B, C]
} ADC_PHASE_ENUM;

#define USED_ADC_PHASES (NUM_ADC_PHASES - 1) // NB 3rd Phase can be inferred as 3 phases sum to zero

// Count of the number of elements in the ADC filter array
#define ADC_FILT_SAMPLE_COUNT 31


/** Different ADC Commands */
typedef enum CMD_ADC_ETAG
{
  ADC_CMD_REQ = 0,  // Request ADC data
  NUM_ADC_CMDS    // Handy Value!-)
} CMD_ADC_ENUM;

#endif /* __ADC_COMMON_H__ */
