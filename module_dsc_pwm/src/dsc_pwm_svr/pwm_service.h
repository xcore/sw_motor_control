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


#ifdef PWM_BLDC_MODE

/** \brief Implementation of the BLDC PWM server
 *
 *  Implements the server thread for the PWM outputs
 *
 *  \param motor the index of the motor being controlled
 *  \param c_pwm control channel for setting PWM values
 *  \param p_pwm the buffered IO ports for the 3 PWM channels
 *  \param clk a clock for generating accurate PWM timing
 */
void do_pwm( chanend c_pwm, buffered out port:32 p_pwm[], clock clk);


#elif defined PWM_INV_MODE || defined PWM_NOINV_MODE

#if LOCK_ADC_TO_PWM

/** \brief Implementation of the non BLDC server
 *
 *  This server includes a port which triggers the ADC measurement
 *
 *  \param c_pwm the control channel for setting PWM values
 *  \param c_adc_trig the control channel for triggering the ADC
 *  \param dummy_port a dummy port used for precise timing of the ADC trigger
 *  \param p_pwm the array of PWM ports
 *  \param p_pwm_inv the array of inverted PWM ports
 *  \param clk a clock for generating accurate PWM timing
 */
void do_pwm( chanend c_pwm, chanend c_adc_trig, in port dummy_port, buffered out port:32 p_pwm[],  buffered out port:32 p_pwm_inv[], clock clk);

#else

/** \brief Implementation of the non BLDC server
 *
 *  \param c_pwm the control channel for setting PWM values
 *  \param p_pwm the array of PWM ports
 *  \param p_pwm_inv the array of inverted PWM ports
 *  \param clk a clock for generating accurate PWM timing
 */
void do_pwm( chanend c_pwm, buffered out port:32 p_pwm[],  buffered out port:32 p_pwm_inv[], clock clk);

#endif

#endif

#endif /*PWM_SERVICE_H_*/
