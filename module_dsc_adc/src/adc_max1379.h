/*
 * Module:  module_dsc_adc
 * File:    adc_max1379.h
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
 */                                   
#ifndef ADC_MAX1379_H_
#define ADC_MAX1379_H_

/** \brief The server thread for the MAX1379 ADC device
 *
 * Implements the server thread for the MAX1379 ADC device
 *
 * \param c_adc the array of ADC control channels
 * \param clk the clock for the ADC device serial port
 * \param SCLK the port which feeds the ADC serial clock
 * \param CNVST the ADC convert strobe
 * \param SEL the chip select for the ADC device
 * \param DATA the ADC data port
 */
void run_adc_max1379( chanend c_adc[], clock clk, port out SCLK,  port out CNVST,  port out SEL, in buffered port:32 DATA);

#endif /*ADC_MAX1379_H_*/
