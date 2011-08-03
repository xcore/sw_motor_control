/**
 * \file adc_client.h
 *
 * The copyrights, all other intellectual and industrial 
 * property rights are retained by XMOS and/or its licensors. 
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2011
 *
 * In the case where this code is a modification of existing code
 * under a separate license, the separate license terms are shown
 * below. The modifications to the code are still covered by the 
 * copyright notice above.
 *
 **/

#ifndef __ADC_CLIENT_H__
#define __ADC_CLIENT_H__

/** \brief ADC calibration sequence
 *
 * This reads a set of ADC values and takes an average.  This is then
 * used as a baseline for further ADC readings.
 *
 * \param c_adc the control channel to the ADC server
 */
void do_adc_calibration( chanend c_adc );

/** \brief Get raw values from the ADC server
 *
 * Read motor current values from the ADC server, and return the
 * values without converting them.
 *
 * \param c_adc the control channel to the ADC server
 */
{unsigned, unsigned, unsigned} get_adc_vals_raw( chanend c_adc );

/** \brief Get values converted from 14 bit unsigned to 16 bit signed and calibrated
 *
 * Read a set of current values from the motor, and convert them into a
 * standardized 16 bit scale
 *
 * \param c_adc the control channel to the ADC server
 */
{int, int, int} get_adc_vals_calibrated_int16( chanend c_adc );



#endif /* __ADC_CLIENT_H__ */
