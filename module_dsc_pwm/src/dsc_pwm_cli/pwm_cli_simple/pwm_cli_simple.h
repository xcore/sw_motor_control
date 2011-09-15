/**
 * Module:  module_dsc_pwm
 * Version: 1v1
 * Build:
 * File:    pwm_cli_bldc.h
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
#include "pwm_cli_common.h"

/** \brief Update the PWM server with a new value for a particular channel
 *
 *  On the next cycle through the PWM, the server will update the PWM
 *  pulse widths.
 *
 *	\param ctrl the client control structure for this PWM server
 *  \param c the control channel for the PWM server
 *  \param value an array of three 24 bit values for the PWM server
 *  \param pwm_chan the channel to output this value onto
 */
void update_pwm_simple( t_pwm_control& ctrl, chanend c, unsigned value, unsigned pwm_chan );

