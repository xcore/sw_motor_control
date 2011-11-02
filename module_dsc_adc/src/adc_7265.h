/*
 * adc_7265.h
 *
 *  Created on: Jul 6, 2011
 *      Author: A SRIKANTH
 */

#ifndef ADC_7265_H_
#define ADC_7265_H_

#include "adc_common.h"

/** \brief Implements the AD7265 triggered ADC service
 *
 *  This implements the AD hardware interface to the 7265 ADC device.  It has two ports to allow reading two
 *  simultaneous current readings for a single motor.
 *
 *  \param c_adc the array of ADC server control channels
 *  \param c_trig the array of channels to recieve triggers from the PWM modules
 *  \param clk an XCORE clock to provide clocking to the ADC
 *  \param SCLK the external clock pin on the ADC
 *  \param CNVST the convert strobe on the ADC
 *  \param DATA_A the first data port on the ADC
 *  \param DATA_B the second data port on the ADC
 *  \param MUX a port to allow the selection of the analogue MUX input
 *
 */
void adc_7265_triggered( streaming chanend c_adc[ADC_NUMBER_OF_TRIGGERS], chanend c_trig[ADC_NUMBER_OF_TRIGGERS], clock clk, out port SCLK, port CNVST, in buffered port:32 DATA_A, in buffered port:32 DATA_B, port out MUX );

#endif /* ADC_7265_H_ */
