/*
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

// Set the number of motors
#define NUMBER_OF_MOTORS 2

// Define where everything is
#define INTERFACE_CORE 0
#define MOTOR_CORE 1

// Define the number of poles the motor has
#define NUMBER_OF_POLES	8


// Define the number different QEI sensors (angular positions)
#ifdef FAULHABER_MOTOR
#define QEI_COUNT_MAX (1024 * 4)
#else
#define MAX_SPEC_RPM 4000 // Maximum specified motor speed
#define QEI_COUNT_MAX (256 * 4)
#endif

// Value to increase/decrease the speed by when the button is pressed
#define PWM_INC_DEC_VAL 100

// Initial speed set point in RPM
#define INITIAL_SET_SPEED 0

// Minimum RPM value for the motor
#define MIN_RPM 100

// Maximum RPM value for the motor
#define MAX_RPM 4000

// Maximum Iq value for the motor
#define MAX_IQ 8000

/* define the number of clients for the QEI module */
#define QEI_CLIENT_COUNT 2

#define BLDC_BASIC

//#define USE_XSCOPE

#endif /* _DSC_CONFIG__H_ */
