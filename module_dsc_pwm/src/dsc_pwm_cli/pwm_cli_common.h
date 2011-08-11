/**
 * Module:  module_dsc_pwm
 * Version: 1v0alpha1
 * Build:   128bfdf87839aeec0e38320c3524102eb996ecd5
 * File:    pwm_cli_common.h
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
#ifndef _PWM_CLI_COMMON__H_
#define _PWM_CLI_COMMON__H_

#include <xs1.h>
#include <xccompat.h>

#include "dsc_pwm_common_types.h"
#include "dsc_pwm_common.h"

/** \brief Initialise PWM control state
 *
 */
void init_pwm_vals( );

// Calculate timings for PWM output
void calculate_data_out( unsigned value, REFERENCE_PARAM(t_out_data,pwm_out_data) );
void calculate_data_out_ref( unsigned value, REFERENCE_PARAM(unsigned,ts0), REFERENCE_PARAM(unsigned,out0), REFERENCE_PARAM(unsigned,ts1), REFERENCE_PARAM(unsigned,out1), REFERENCE_PARAM(e_pwm_cat,cat));

// Calculate required ordering of operation
void order_pwm( REFERENCE_PARAM(unsigned,mode), unsigned chan_id[], t_out_data pwm_out_data[]);


// Share the control buffer address with the server
void pwm_share_control_buffer_address_with_server(chanend c, REFERENCE_PARAM(t_pwm_control, ctrl));

#endif /* _PWM_CLI_COMMON__H_ */
