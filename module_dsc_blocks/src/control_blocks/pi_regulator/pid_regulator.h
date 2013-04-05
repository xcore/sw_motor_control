/**
 * Module:  module_dsc_blocks
 * Version: 1v0alpha1
 * Build:   c9e25ba4f74e9049d5da65cb5c829a3d932ed199
 * File:    pid_regulator.h
 * Modified by : Srikanth
 * Last Modified on : 04-May-2011
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

#ifndef __PI_REGULATOR_H__
#define __PI_REGULATOR_H__

#include <stdio.h>
#include <assert.h>

#ifdef __dsc_config_h_exists__
#include <dsc_config.h>
#endif

#ifdef USE_XSCOPE
#include <xscope.h>
#endif

#define DQ_INTEGRAL_LIMIT 8192
#define Q_LIMIT 12000
#define D_HI_LIM 6000
#define D_LO_LIM -4000

#define SPEED_INTEGRAL_LIMIT 10000000
#define SPEED_HI_LIM 8000000
#define SPEED_LO_LIM 0

#ifdef BLDC_FOC
#define PID_RESOLUTION 13
//MB~ #define PID_RESOLUTION 16 // tuning
#endif

#ifdef BLDC_BASIC
#define PID_RESOLUTION 15
#endif

#ifndef PID_RESOLUTION
#define PID_RESOLUTION 15
#endif

// Test/tuning values
#define MB_P 11200
#define MB_I (8 << PID_RESOLUTION)
// #define MB_I 0
#define MB_D 0

// PID contant definitions for Current Control (Id and Iq)
//--------------------------------------------------------
// values based on Velocity Estimated Iq
#define DQ_P 12000
#define DQ_I (8 << PID_RESOLUTION)
#define DQ_D 0

// Values based on Measured Iq
/*
#define DQ_P 400000
#define DQ_I (256 << PID_RESOLUTION)
#define DQ_D 0
*/

// PID contant definitions for Speed Control
//------------------------------------------
#define SPEED_P 20000
#define SPEED_I (3 << PID_RESOLUTION)
#define SPEED_D 0

/** Different PID Regulators */
typedef enum PID_ETAG
{
  SPEED = 0,	// Speed 
  I_D,		  	// Radial Current (in rotor frame of reference)
  I_Q,		  	// Tangential (Torque) Current (in rotor frame of reference)
  NUM_PIDS    // Handy Value!-)
} PID_ENUM;

typedef signed long long S64_T;

// Structure of Constant definitions for PID regulator
typedef struct PID_CONST_TAG
{
	int K_p; // PID Previous-error mix-amount
	int K_i; // PID Integral-error mix-amount
	int K_d; // PID Derivative-error mix-amount
	int sum_lim; // Limit for sum of errors
	int max_lim; // Maximum allowed result value
	int min_lim; // Minimum allowed result value
	int resolution;
	int half_res;
} PID_CONST_TYP;

typedef struct PID_REGULATOR_TAG 
{
	PID_CONST_TYP consts; // Structure containing all constants for this PID regulator
	int prev_err; // Previous error
	int sum_err; // Sum of errors
	int rem; // Remainder
	int qnt_err; // Quantisation Error
} PID_REGULATOR_TYP;

#ifdef __XC__
// XC Version
/*****************************************************************************/
void initialise_pid( // Initialise PID settings
	PID_REGULATOR_TYP &pid_regul_s, // Reference to PID regulator data structure
	PID_ENUM pid_id // Identifies which PID is being initialised
);
/*****************************************************************************/
int get_pid_regulator_correction( // Computes new PID correction based on input error
	unsigned motor_id, // Unique Motor identifier e.g. 0 or 1
	PID_REGULATOR_TYP &pid_regul_s, // Reference to PID regulator data structure
	int meas_val, // measured value
	int requ_val // request value
);
/*****************************************************************************/
#else // ifdef __XC__
// C Version
/*****************************************************************************/
void inititialise_pid( // Initialise PID settings
	PID_REGULATOR_TYP * pid_regul_p, // Pointer to PID regulator data structure
	PID_ENUM pid_id // Identifies which PID is being initialised
);
/*****************************************************************************/
int get_pid_regulator_correction( // Computes new PID correction based on input error
	unsigned motor_id, // Unique Motor identifier e.g. 0 or 1
	PID_REGULATOR_TYP * pid_regul_p, // Pointer to PID regulator data structure
	int meas_val, // measured value
	int requ_val // request value
);
/*****************************************************************************/
#endif // else !__XC__

#ifdef MB // Depreciated
#define PID_MAX_OUTPUT	32768
#define PID_MIN_OUTPUT  -32767

typedef struct S_PID {
	int previous_error;
	int integral;
	int Kp;
	int Ki;
	int Kd;
} pid_data;

#ifdef __XC__
// XC Version
int pid_regulator( int set_point, int actual, pid_data &d );
int pid_regulator_delta( int set_point, int actual, pid_data &d );
int pid_regulator_delta_cust_error( int error, pid_data &d );
int pid_regulator_delta_cust_error_speed( int error, pid_data &d );
int pid_regulator_delta_cust_error_Iq_control( int error, pid_data &iq );
int pid_regulator_delta_cust_error_Id_control( int error, pid_data &id );
void init_pid( int Kp, int Ki, int Kd, pid_data &d );
#else
// C Version
int pid_regulator( int set_point, int actual, pid_data *d );
int pid_regulator_delta( int set_point, int actual, pid_data *d );
int pid_regulator_delta_cust_error( int error, pid_data *d );
int pid_regulator_delta_cust_error_speed( int error, pid_data *d );
int pid_regulator_delta_cust_error_Iq_control( int error, pid_data *iq );
int pid_regulator_delta_cust_error_Id_control( int error, pid_data *id );
void init_pid( int Kp, int Ki, int Kd, pid_data *d );
#endif

#endif //MB~ Depreciated

#endif // ifndef __PI_REGULATOR_H__
