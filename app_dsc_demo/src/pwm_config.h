/**
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

#ifndef _PWM_CONFIG__H_
#define _PWM_CONFIG__H_

// Define this to include XSCOPE support
#define USE_XSCOPE 1

// dead time is 1200. Configure this in ReferenceFrequency cycles (See .xn file)
#define HALF_DEAD_TIME 150  // Currently configured for 250 MHz Ref-Freq (4 ns period)
#define PWM_DEAD_TIME (HALF_DEAD_TIME << 1)

// Define the resolution of PWM (affects operational freq. as tied to ref clock)
#define PWM_MAX_VALUE 4096

#define PWM_LIM_VALUE (PWM_MAX_VALUE - PWM_DEAD_TIME - 32) // Limiting value to avoid issues with LONG_SINGLE

// Define if ADC sampling is locked to PWM switching. The ADC sampling will occur in the middle of the  switching sequence.
// It is triggered over a channel. Set this define to 0 to disable this feature
#define LOCK_ADC_TO_PWM 1

#endif
