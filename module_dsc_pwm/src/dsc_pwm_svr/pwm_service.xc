/**
 * Module:  module_dsc_pwm
 * Version: 1v1
 * Build:
 * File:    pwm_service.xc
 * Author: 	Srikanth
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
#include "dsc_pwm_common.h"
#include "pwm_service.h"
#include "pwm_service_inv.h"
#include "pwm_service_noinv.h"
#include "pwm_service_bldc.h"

#ifdef PWM_NOINV_MODE

	void do_pwm( chanend c_pwm, buffered out port:32 p_pwm[], buffered out port:32 p_pwm_inv[], clock clk)
	{
		do_pwm_noinv( c_pwm, p_pwm, clk);
	}

#endif

#ifdef PWM_INV_MODE

	#if LOCK_ADC_TO_PWM

		void do_pwm( chanend c_pwm, chanend c_adc_trig, in port dummy_port, buffered out port:32 p_pwm[],  buffered out port:32 p_pwm_inv[], clock clk)
		{
			 do_pwm_inv( c_pwm, c_adc_trig, dummy_port, p_pwm,  p_pwm_inv, clk);
		}

	#else

		void do_pwm( chanend c_pwm, buffered out port:32 p_pwm[],  buffered out port:32 p_pwm_inv[], clock clk)
		{
			do_pwm_inv( c_pwm, p_pwm,  p_pwm_inv, clk);
		}

	#endif

#endif

#ifdef PWM_BLDC_MODE

	void do_pwm1( chanend c_pwm, buffered out port:32 p_pwm_lo[], clock clk)
	{
		do_pwm_bldc1( c_pwm, p_pwm_lo, clk);
	}

	void do_pwm2( chanend c_pwm2, buffered out port:32 p_pwm_lo2[], clock clk2)
	{
		do_pwm_bldc2( c_pwm2, p_pwm_lo2, clk2);
	}

#endif





