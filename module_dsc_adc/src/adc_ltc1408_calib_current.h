/**
 * Module:  module_dsc_adc
 * Version: 1v1
 * Build:
 * File:    adc_ltc1408_calib_current.h
 * Author: 	Srikanth
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
#include <xs1.h>
#include <xclib.h>
#include "dsc_config.h"
#include "adc_common.h"

#ifndef ADC_LTC1408_CALIB_CURRENT_H_
#define ADC_LTC1408_CALIB_CURRENT_H_

void adc_ltc1408_calib_current( chanend c_adc, chanend c_adc2, clock clk, port out SCLK, buffered out port:32 CNVST, in buffered port:32 DATA );

#endif
