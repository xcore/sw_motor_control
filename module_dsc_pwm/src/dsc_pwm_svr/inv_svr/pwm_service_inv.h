/**
 * Module:  module_dsc_pwm
 * Version: 1v0alpha1
 * Build:   f29fa5888a0d92c83949f37a31efe2ec19a95534
 * File:    pwm_service_inv.h
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
#include "dsc_pwm_common.h"
#include "dsc_pwm_common_types.h"

/*
 * Operate centre synchronised PWM on three ports with inverted PWM channels
 */
#if LOCK_ADC_TO_PWM
void do_pwm_inv( chanend c_pwm, chanend c_adc_trig, in port dummy_port, buffered out port:32 p_pwm[],  buffered out port:32 p_pwm_inv[], clock clk);
#else
void do_pwm_inv( chanend c_pwm, buffered out port:32 p_pwm[],  buffered out port:32 p_pwm_inv[], clock clk);
#endif

#ifdef USE_PWM_CYCLE_COUNTER
unsigned get_pwm_cycle_counter();
#endif

