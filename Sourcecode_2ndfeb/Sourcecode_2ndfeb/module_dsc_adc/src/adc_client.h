/**
 * Module:  module_dsc_adc
 * Version: 1v0alpha2
 * Build:   60a90cca6296c0154ccc44e1375cc3966292f74e
 * File:    adc_client.h
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
#ifndef __ADC_CLIENT_H__
#define __ADC_CLIENT_H__

/* ADC calibration sequence */
void do_adc_calibration( chanend c_adc );

/* get raw values in whatever format the ADC delivers them in */
{unsigned, unsigned, unsigned} get_adc_vals_raw( chanend c_adc );

/* get values converted from 14 bit unsigned to 16 bit signed and calibrated */
{int, int, int} get_adc_vals_calibrated_int16( chanend c_adc );



#endif /* __ADC_CLIENT_H__ */
