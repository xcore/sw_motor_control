/**
 * Module:  app_basic_bldc
 * Version: 1v1
 * Build:
 * File:    dsc_config.h
 * Author: 	L & T
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
#ifndef _DSC_CONFIG__H_
#define _DSC_CONFIG__H_

// Define the PWM operation mode:
// PWM_INV_MODE - output all 6 channels. 3 channels the inverse of the other 3 (A, A', B, B', C, C')
// PWM_NOINV_MODE - output 3 channels (A, B, C)
// PWM_BLDC_MODE - output only 2 enabled channels at a time
#define PWM_INV_MODE 1

// Define the number of motors
#define NUMBER_OF_MOTORS 2

// Define dead time period in 10ns period, i.e. dead time = PWM_DEAD_TIME * 10ns
#define PWM_DEAD_TIME 10

// Define the number of poles the motor has
#define NUMBER_OF_POLES	8

// Define the resolution of PWM (affects operational freq. as tied to ref clock)
#define PWM_MAX_VALUE 4096

// Define if ADC sampling is locked to PWM switching. The ADC sampling will occur in the middle of the  switching sequence.
// It is triggered over a channel. Set this define to 0 to disable this feature
#define LOCK_ADC_TO_PWM 1

// Define the port for the control app to connect to
#define TCP_CONTROL_PORT 23

// Define this to include XSCOPE support
//#define USE_XSCOPE

#endif /* _DSC_CONFIG__H_ */
