/**
 * Module:  module_dsc_adc
 * Version: 1v0alpha1
 * Build:   9350f3fb5b203bc0e87504d0f69b9d0a9a59b80a
 * File:    adc_ltc1408.h
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
#include "dsc_config.h"
#include "adc_common.h"

void adc_ltc1408_test( clock clk, port out SCLK, buffered out port:32 CNVST, in buffered port:32 DATA );

void adc_ltc1408_filtered( chanend c_adc, clock clk, port out SCLK, buffered out port:32 CNVST, in buffered port:32 DATA, chanend ?c_logging0, chanend ?c_logging1, chanend ?c_logging2 );

void adc_ltc1408_triggered( chanend c_adc, clock clk, port out SCLK, buffered out port:32 CNVST, in buffered port:32 DATA, chanend c_trig, chanend ?c_logging0, chanend ?c_logging1, chanend ?c_logging2);
