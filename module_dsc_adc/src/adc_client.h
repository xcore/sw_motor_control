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

#include "adc_common.h"

typedef struct ADC_DATA_TAG // Structure containing ADC data
{
	int vals[NUM_ADC_PHASES]; // Array of ADC values for each phase
} ADC_DATA_TYP;

/*---------------------------------------------------------------------------*/

/** \brief ADC calibration sequence
 *
 * This switches the ADC server into calibration mode.  After a number (NUM_CALIBRATIONS) of samples
 * the server reverts to non-calibration mode, and subsequent calls to the function
 * get_adc_vals_calibrated_int16 will take the measured average of the calibration
 * period as an offset
 *
 * \param c_adc the control channel to the ADC server
 */
void do_adc_calibration( streaming chanend c_adc );

/*---------------------------------------------------------------------------*/

/** \brief Get values converted from 14 bit unsigned to 16 bit signed and calibrated
 *
 * Read a set of current values from the motor, and convert them into a
 * standardized 16 bit scale
 *
 * \param c_adc the control channel to the ADC server
 */
{int, int, int} get_adc_vals_calibrated_int16( streaming chanend c_adc );

/*---------------------------------------------------------------------------*/

/** \brief Get 12-bit ADC values and convert to signed 32-bit integer
 *
 * Read 2 of 3 ADC values from the motor, and convert them into signed 32-bit integer
 *
 * \param c_adc the control channel to the ADC server
 */
void get_adc_vals_calibrated_int16_mb( streaming chanend c_adc ,ADC_DATA_TYP &adc_data_s );

/*---------------------------------------------------------------------------*/

#endif /* __ADC_CLIENT_H__ */
