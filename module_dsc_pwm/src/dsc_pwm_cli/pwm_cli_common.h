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

#ifdef __XC__
inline void calculate_data_out_quick( unsigned value, REFERENCE_PARAM(t_out_data,pwm_out_data) )
{
	pwm_out_data.cat = DOUBLE;
	pwm_out_data.out0 = 0xFFFFFFFF;
	pwm_out_data.out1 = 0x7FFFFFFF;
	pwm_out_data.inv_out0 = 0xFFFFFFFF;
	pwm_out_data.inv_out1 = 0x7FFFFFFF;
	pwm_out_data.ts0 = (value >> 1);
	pwm_out_data.ts1 = (value >> 1)-31;
	pwm_out_data.inv_ts0 = ((value+PWM_DEAD_TIME) >> 1);
	pwm_out_data.inv_ts1 = ((value+PWM_DEAD_TIME) >> 1) - 31;
}
#endif

// Calculate required ordering of operation
void order_pwm( REFERENCE_PARAM(unsigned,mode), unsigned chan_id[], t_out_data pwm_out_data[]);


/** \brief Share the control buffer address with the server
 *
 *  The PWM client and server share a common block of memory.  The client passes a reference
 *  to this block through to the server at initalization time.
 *
 *  \param c The PWM control channel
 *  \param ctrl The shared PWM control data structure reference
 */
void pwm_share_control_buffer_address_with_server(chanend c, REFERENCE_PARAM(t_pwm_control, ctrl));

#endif /* _PWM_CLI_COMMON__H_ */
