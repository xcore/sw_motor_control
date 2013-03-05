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
#ifndef _DSC_CONFIG__H_
#define _DSC_CONFIG__H_

// Define the number of motors
#define NUMBER_OF_MOTORS 2

// Define the port for the control app to connect to
#define TCP_CONTROL_PORT 9595

// Define this to enable the CAN interface
//	#define USE_CAN

// Define this to enable the Ethernet interface
#define USE_ETH

// Check that both interfaces are not defined
#if defined(USE_CAN) && defined(USE_ETH)
	#error Both CAN and Ethernet are enabled.
#endif

#define BLDC_FOC

// Define this to include XSCOPE support
#define USE_XSCOPE 1

// This section to be used for specifying motor type ...

#define NUM_POLE_PAIRS	4 // Define the number of pole-pairs

// Define the number different QEI sensors (angular positions)
#ifdef FAULHABER_MOTOR
#define QEI_PER_REV (1024 * 4)
#else
#define QEI_PER_REV (256 * 4)
#endif


#define MAX_SPEC_RPM 4000 // Maximum specified motor speed

// Maximum user-assigned RPM value for the motor
#define MAX_USER_RPM 3800

// Minimum user-assigned RPM value for the motor
//MB~ #define MIN_USER_RPM 500
#define MIN_USER_RPM 50 //MB~


#endif /* _DSC_CONFIG__H_ */
