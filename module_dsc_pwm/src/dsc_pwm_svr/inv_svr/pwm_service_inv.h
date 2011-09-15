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

/** \brief Implementation of the centre aligned inverted pair PWM server, with ADC synchronization
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
void do_pwm_inv_triggered( chanend c_pwm, chanend c_adc_trig, in port dummy_port, buffered out port:32 p_pwm[],  buffered out port:32 p_pwm_inv[], clock clk);



/** \brief Implementation of the centre aligned inverted pair PWM server
 *
 *  \param c_pwm the control channel for setting PWM values
 *  \param p_pwm the array of PWM ports
 *  \param p_pwm_inv the array of inverted PWM ports
 *  \param clk a clock for generating accurate PWM timing
 */
void do_pwm_inv( chanend c_pwm, buffered out port:32 p_pwm[],  buffered out port:32 p_pwm_inv[], clock clk);


