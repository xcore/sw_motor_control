/*
 * adc_7265.h
 *
 *  Created on: Jul 6, 2011
 *      Author: A SRIKANTH
 */

#ifndef ADC_7265_H_
#define ADC_7265_H_

#define ADC_TRIG_TOKEN  1

static void configure_adc_ports_7265(clock clk, port out SCLK, port out CNVST, in buffered port:32 DATA_A, in buffered port:32 DATA_B, port out MUX);
static void adc_get_data_7265( int adc_val[], port out CNVST, in buffered port:32 DATA_A, in buffered port:32 DATA_B, port out MUX );
void adc_7265_triggered( chanend c_adc, chanend c_trig, clock clk, port out SCLK, port out CNVST, in buffered port:32 DATA_A, in buffered port:32 DATA_B, port out MUX );

#endif /* ADC_7265_H_ */
