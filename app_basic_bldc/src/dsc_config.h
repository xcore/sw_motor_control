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

// Define the number of motors
#define NUMBER_OF_MOTORS 2

// Define the port for the control app to connect to
#define TCP_CONTROL_PORT 9595

// Define the number of poles the motor has
#define NUMBER_OF_POLES	4

// Define this to enable the CAN interface
//#define USE_CAN

// Define this to enable the Ethernet interface
#define USE_ETH

// Check that both interfaces are not defined
#if defined(USE_CAN) && defined(USE_ETH)
	#error Both CAN and Ethernet are enabled.
#endif

// Minimum RPM value for the motor
#define MIN_RPM 100

// Maximum RPM value for the motor
#define MAX_RPM 4000

/* define the number of clients for the QEI module */
#define QEI_CLIENT_COUNT 2

#define BLDC_BASIC

// Define this to include XSCOPE support
//#define USE_XSCOPE

#endif /* _DSC_CONFIG__H_ */
