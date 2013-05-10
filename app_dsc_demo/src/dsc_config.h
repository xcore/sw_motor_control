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

/* This is a bit of a cludge, we are using a non-standard configuration
 * where the timer on the tile for inner_loop() is running at 250 MHz,
 * but other timers are running at the default of 100 MHz.
 * Currently this flexibility to define timer frequencies for each tile does not exist.
 * Therefore, we set up the timer frequency here.
 */
#ifndef PLATFORM_REFERENCE_MHZ
#define PLATFORM_REFERENCE_MHZ 250
#define PLATFORM_REFERENCE_KHZ (1000 * PLATFORM_REFERENCE_MHZ) 
#define PLATFORM_REFERENCE_HZ  (1000 * PLATFORM_REFERENCE_KHZ) // NB Uses 28-bits
#endif

#define SECOND PLATFORM_REFERENCE_HZ // One Second in Clock ticks
#define MILLI_SEC (PLATFORM_REFERENCE_KHZ) // One milli-second in clock ticks
#define MICRO_SEC (PLATFORM_REFERENCE_MHZ) // One micro-second in clock ticks

#endif /* _DSC_CONFIG__H_ */
