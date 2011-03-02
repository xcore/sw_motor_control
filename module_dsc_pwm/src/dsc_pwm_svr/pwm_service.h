/**
 * Module:  module_dsc_pwm
 * Version: 1v1
 * Build:
 * File:    pwm_service.h
 * Author: 	Srikanth
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
#ifndef PWM_SERVICE_H_
#define PWM_SERVICE_H_

#include <xs1.h>
#include <xclib.h>
#include "dsc_config.h"
#include "dsc_pwm_common.h"
#include "dsc_pwm_common_types.h"

/******************************************************/
/* Basic BLDC commutation just requires PWM on the    */
/* low side of the half bridge. The upper side of the */
/* bridge needs to be controlled by the application   */
/******************************************************/

#ifdef PWM_BLDC_MODE

void do_pwm1( chanend c_pwm, buffered out port:32 p_pwm[], clock clk);
void do_pwm2( chanend c_pwm2, buffered out port:32 p_pwm2[], clock clk2);

#elif defined PWM_INV_MODE || defined PWM_NOINV_MODE /*TODO: check the NOINV mode... not been used for a while */

#if LOCK_ADC_TO_PWM
void do_pwm( chanend c_pwm, chanend c_adc_trig, in port dummy_port, buffered out port:32 p_pwm[],  buffered out port:32 p_pwm_inv[], clock clk);
#else
void do_pwm( chanend c_pwm, buffered out port:32 p_pwm[],  buffered out port:32 p_pwm_inv[], clock clk);
#endif

#endif

#endif /*PWM_SERVICE_H_*/
