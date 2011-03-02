/**
 * Module:  module_dsc_pwm
 * Version: 1v0alpha1
 * Build:   7a2a09d4b5f4c539a6da099d60946a3057ee7e34
 * File:    dsc_pwm_common_types.h
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
#ifndef DSC_ALT_PWM_COMMON_TYPES_H_
#define DSC_ALT_PWM_COMMON_TYPES_H_

#include "dsc_pwm_common.h"

typedef enum PWM_OUTPUT_CAT
{
	LONG_SINGLE,
	SINGLE,
	DOUBLE
} e_pwm_cat;

/* if changing this then change the corresponding value in dsc_pwm_common.h */
typedef struct PWM_OUT_DATA
{
	/* N */
	unsigned ts0;  // 0
	unsigned out0; // 1
	unsigned ts1;  // 2
	unsigned out1; // 3

	/* N' */
	unsigned inv_ts0;  // 4
	unsigned inv_out0; // 5
	unsigned inv_ts1;  // 6
	unsigned inv_out1; // 7

	/* other info */
	e_pwm_cat cat;
	unsigned value;
} t_out_data;


#endif /* DSC_ALT_PWM_COMMON_TYPES_H_ */
