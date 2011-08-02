/**
 * Module:  app_dsc_demo
 * Version: 1v0alpha1
 * Build:   1887e6b30ecc00395f02fb3a27027fd6fcf3a300
 * File:    dsc_config.h
 * Modified by : A Srikanth
 * Last Modified on : 05-Jul-2011
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

// Define the PWM operation mode:
// PWM_INV_MODE - output all 6 channels. 3 channels the inverse of the other 3 (A, A', B, B', C, C')
// PWM_NOINV_MODE - output 3 channels (A, B, C)
// PWM_BLDC_MODE - output only 2 enabled channels at a time
#define PWM_INV_MODE 1

// Define dead time period in 10ns period, i.e. dead time = PWM_DEAD_TIME * 10ns
#define PWM_DEAD_TIME 120

// Define the resolution of PWM (affects operational freq. as tied to ref clock)
#define PWM_MAX_VALUE 4096

// Define the hall effect & position estimation operation mode:
// HALL_POS_ESTIMATION - deliver an estimated theta for based on the frequency of requests of theta
// HALL_SECTOR - output sector update onto channel when it happens
#define HALL_POS_ESTIMATION 1

// Define if ADC sampling is locked to PWM switching. The ADC sampling will occur in the middle of the  switching sequence.
// It is triggered over a channel. Set this define to 0 to disable this feature
#define LOCK_ADC_TO_PWM 1

// Define if you want to push ADC data out to the ethernet logging channel
#define ADC_LOGGING_ON 0

// The number of logging channels
#define LOGGING_CHANS 6

// Define where everything is
//#define PROCESSING_CORE 0
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

// Define whether we want a static IP or not. Set to 1 to use DHCP, set to 0 to use static IP
#define USE_DHCP 0

// Define the IP if a static one is used
#define STATIC_IP_BYTE_0 169
#define STATIC_IP_BYTE_1 254
#define STATIC_IP_BYTE_2 0
#define STATIC_IP_BYTE_3 1

// Define the port for the control app to connect to
#define TCP_CONTROL_PORT 9595

// Define the port for the logging app to connect to
#define TCP_LOGGING_PORT 9596

// Define the number of poles the motor has
#define NUMBER_OF_POLES	8

// Define this to enable the CAN interface
//#define USE_CAN

// Define this to enable the Ethernet interface
#define USE_ETH

// Check that both interfaces are not defined
#if defined(USE_CAN) && defined(USE_ETH)
	#error Both CAN and Ethernet are enabled.
#endif

// Define this to use the motor
#define USE_MOTOR

// Uncomment to cause the software to reset on a trap or exception.
#define RESET_ON_TRAP

//#define PWM_TIME_PERIOD 50 //uS

// Value to increase/decrease the speed by when the button is pressed
#define PWM_INC_DEC_VAL 100

// Initial speed set point in RPM
#define INITIAL_SET_SPEED 0

// Minimum RPM value for the motor
#define MIN_RPM 500

// Maximum RPM value for the motor
#define MAX_RPM 3800

// Maximum Iq value for the motor
#define MAX_IQ 8000

#define BLDC_FOC

// define display string for value transmitted to motor control loop (usuall "Iq" or "PWM Value")
#define LCD_SETTING_STRING "PWM"

#endif /* _DSC_CONFIG__H_ */
