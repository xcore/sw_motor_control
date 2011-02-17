/**
 * Module:  module_dsc_blocks
 * Version: 1v0alpha1
 * Build:   c9e25ba4f74e9049d5da65cb5c829a3d932ed199
 * File:    pid_regulator.h
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

#define PID_RESOLUTION	15
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
void init_pid( int Kp, int Ki, int Kd, pid_data &d );
#else
// C Version
int pid_regulator( int set_point, int actual, pid_data *d );
int pid_regulator_delta( int set_point, int actual, pid_data *d );
int pid_regulator_delta_cust_error( int error, pid_data *d );
void init_pid( int Kp, int Ki, int Kd, pid_data *d );
#endif

#endif
