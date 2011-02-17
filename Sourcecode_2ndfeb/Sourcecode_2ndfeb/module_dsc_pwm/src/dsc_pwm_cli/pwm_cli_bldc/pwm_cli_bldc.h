/**
 * Module:  module_dsc_pwm
 * Version: 0v9sd
 * Build:   171b0edc1da8cc48077795eb92c73d0fb72d28b7
 * File:    pwm_cli_bldc.h
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
#include "pwm_cli_common.h"

#ifdef PWM_BLDC_MODE
void calculate_data_out( unsigned value, t_out_data &pwm_out_data );

void update_pwm( chanend c, unsigned value, unsigned pwm_chan );
#endif
