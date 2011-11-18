/**
 * \file adc_ltc1408.h
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
#include <xs1.h>
#include <xclib.h>

#include "adc_common.h"

/** \brief Execute the triggered ADC server
 *
 * This is the server thread implementation for the LTC1408 ADC device.
 *
 * \param c_adc the array of ADC control channels
 * \param c_trig the array of channels to receive triggers from the PWM modules
 * \param clk the clock for the ADC device serial port
 * \param SCLK the port which feeds the ADC serial clock
 * \param CNVST the ADC convert strobe
 * \param DATA the ADC data port
 */
void adc_ltc1408_triggered( chanend c_adc[], chanend c_trig[], clock clk, port out SCLK, buffered out port:32 CNVST, in buffered port:32 DATA);
