/**
 * Module:  module_dsc_pwm
 * Version: 0v9sd
 * Build:   97d69132d554f6a6acc8796db60ec9b843c6cf3b
 * File:    pwm_cli.h
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
#ifndef ALT_PWM_CLI_H_
#define ALT_PWM_CLI_H_

#include <xs1.h>
#include "dsc_pwm_common.h"
#include "dsc_pwm_common_types.h"
#include "pwm_cli_common.h"

/******************************************************/
/* Basic BLDC commutation just requires PWM on the    */
/* low side of the half bridge. The upper side of the */
/* bridge needs to be controlled by the application   */
/******************************************************/

#ifdef PWM_NOINV_MODE
#include "pwm_cli_noinv.h"
#endif

#ifdef PWM_INV_MODE
#include "pwm_cli_inv.h"
#endif

#ifdef PWM_BLDC_MODE
#include "pwm_cli_bldc.h"
#endif

#endif /*ALT_PWM_CLI_H_*/
