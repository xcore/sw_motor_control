/**
 * Module:  module_dsc_blocks
 * Version: 1v0alpha1
 * Build:   128bfdf87839aeec0e38320c3524102eb996ecd5
 * File:    pwm_calc.h
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
#ifndef __SVPWM_H__
#define __SVPWM_H__

#ifdef __XC__

	// XC version
	void spwm_duty_calc( unsigned &chan1, unsigned &chan2, unsigned &chan3, int V1, int V2, int V3, unsigned theta );
	void svpwm_calc(  unsigned &chan1, unsigned &chan2, unsigned &chan3, int Valpha, int Vbeta, unsigned theta );

#else

	// C version
	void spwm_duty_calc( unsigned *chan1, unsigned *chan2, unsigned *chan3, int V1, int V2, int V3, unsigned theta );
	void svpwm_calc(  unsigned *chan1, unsigned *chan2, unsigned *chan3, int Valpha, int Vbeta, unsigned theta );

#endif

#endif /* __SVPWM_H__ */
