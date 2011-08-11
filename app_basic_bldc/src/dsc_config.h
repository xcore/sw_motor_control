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
#define PWM_BLDC_MODE 1

// Define the number of motors
#define NUMBER_OF_MOTORS 2

// Define dead time period in 10ns period, i.e. dead time = PWM_DEAD_TIME * 10ns
#define PWM_DEAD_TIME 10

// Define the resolution of PWM (affects operational freq. as tied to ref clock)
#define PWM_MAX_VALUE 4096

// Define if ADC sampling is locked to PWM switching. The ADC sampling will occur in the middle of the  switching sequence.
// It is triggered over a channel. Set this define to 0 to disable this feature
#define LOCK_ADC_TO_PWM 0

// Define where everything is
#define INTERFACE_CORE 0
#define MOTOR_CORE 1

// Define the ethernet OTP core for getting the mac address, this should be the same as the
// core that the ethernet thread runs on, unless you give the ethernet thread the mac address
// in some other way
#define ETHERNET_OTP_CORE 0

// Check to prevent error where the OTP is on a different core
#if ETHERNET_OTP_CORE != INTERFACE_CORE
	#error OTP and Interfaces are defined on different cores.
#endif

// Define the port for the control app to connect to
#define TCP_CONTROL_PORT 9595

// Define the number of poles the motor has
#define NUMBER_OF_POLES	8

// Value to increase/decrease the speed by when the button is pressed
#define PWM_INC_DEC_VAL 100

// Initial speed set point in RPM
#define INITIAL_SET_SPEED 0

// Minimum RPM value for the motor
#define MIN_RPM 100

// Maximum RPM value for the motor
#define MAX_RPM 4000

/* define the number of clients for the QEI module */
#define QEI_CLIENT_COUNT 2

#define BLDC_BASIC

//Use CAN or ETHERNET communication
//#define USE_CAN
#define USE_ETH

//#define USE_XSCOPE

#endif /* _DSC_CONFIG__H_ */
