/**
 * Module:  module_dsc_pwm
 * Version: 1v1
 * Build:
 * File:    pwm_service_bldc.h
 * Author: 	Srikanth
 *
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

#ifndef __PWM_SERVICE_BLDC_H_
#define __PWM_SERVICE_BLDC_H_

#include "dsc_pwm_common.h"
#include "dsc_pwm_common_types.h"

/*
 * Basic BLDC pwm operation
 */
void do_pwm_bldc( chanend c_pwm, buffered out port:32 p_pwm[], clock clk);


#endif
