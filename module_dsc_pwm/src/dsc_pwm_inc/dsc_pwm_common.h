/**
 * Module:  module_dsc_pwm
 * Version: 1v0alpha1
 * Build:   1c0d37662e0881e71e5aeb8e90c3c0b660c318c6
 * File:    dsc_pwm_common.h
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
#ifndef __DSC_ALT_PWM_H_
#define __DSC_ALT_PWM_H_

#include "dsc_config.h"

/* --- NO MODIFICATIONS REQUIRED BELOW HERE --- */

#if LOCK_ADC_TO_PWM
#include "adc_common.h"
#endif

#define PWM_CHAN_COUNT 3

#define BLDC_SEQUENCE_0	{4,2,2,0,0,4}
#define BLDC_SEQUENCE_1	{1,1,5,5,3,3}

#define SYNC_INCREMENT (PWM_MAX_VALUE)
#define INIT_SYNC_INCREMENT (SYNC_INCREMENT)

// The offset and size of components in the PWM control structure
#ifdef PWM_BLDC_MODE
#define OFFSET_OF_CHAN_ID  0
#define OFFSET_OF_MODE_BUF 8
#define OFFSET_OF_DATA_OUT 16
#define SIZE_OF_T_DATA_OUT 40
#else
#define OFFSET_OF_CHAN_ID  0
#define OFFSET_OF_MODE_BUF 24
#define OFFSET_OF_DATA_OUT 32
#define SIZE_OF_T_DATA_OUT 40
#endif

#endif /*DSC_ALT_PWM_H_*/
