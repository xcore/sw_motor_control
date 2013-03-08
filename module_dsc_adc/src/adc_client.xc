/**
 * Module:  module_dsc_adc
 * Version: 1v0alpha2
 * Build:   2a548667d36ce36c64c58f05b5390ec71cb253fa
 * File:    adc_client.xc
 * Modified by : Srikanth
 * Last Modified on : 26-May-2011
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

#include "adc_client.h"

#ifdef __dsc_config_h_exists__
#include <dsc_config.h>
#endif

/*****************************************************************************/
void get_adc_vals_calibrated_int16_mb( 
	streaming chanend c_adc_cntrl, // channel connecting to ADC thread
	ADC_DATA_TYP &adc_data_s // Reference to structure containing ADC data
)
{
	int phase_cnt; // ADC Phase counter
	int adc_sum = 0; // Accumulator for transmitted ADC Phases


	c_adc_cntrl <: ADC_CMD_REQ;	// Request ADC data */

	// Loop through used phases of ADC data
	for (phase_cnt=0; phase_cnt<USED_ADC_PHASES; ++phase_cnt) 
	{
		c_adc_cntrl :> adc_data_s.vals[phase_cnt];	// Receive One phase of ADC data

		adc_sum += adc_data_s.vals[phase_cnt]; // Add adc value to sum
	} // for phase_cnt

	// Calculate last ADC phase from previous phases (NB Sum of phases is zero)
	adc_data_s.vals[(NUM_ADC_PHASES - 1)] = -adc_sum;

	return;
} // get_adc_vals_calibrated_int16_mb
/*****************************************************************************/
// adc_client.xc
