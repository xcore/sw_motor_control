/**
 * Module:  module_dsc_blocks
 * Version: 1v0alpha1
 * Build:   c9e25ba4f74e9049d5da65cb5c829a3d932ed199
 * File:    pid_regulator.c
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
#include "pid_regulator.h"
#include <xs1.h>

extern int frac_mul( int a, int b );

/* initialise PID settings */
void init_pid( int Kp, int Ki, int Kd, pid_data *d )
{
	d->Kp = Kp;
	d->Ki = Ki;
	d->Kd = Kd;

	d->integral = 0;
	d->previous_error = 0;
}


/* PID controller algorithm
 * Assumptions:
 * 		1) dt is always 1
 * 		2) PID_RESOLUTION is correctly defined in the pid_regulator.h file
 * 		3) Min and Max outputs are defined appropriately in pid_regulator.h
 */
int pid_regulator( int set_point, int actual, pid_data *d )
{

	/* PID algorithm */
	int error = set_point - actual;
	d->integral = d->integral + error;

	/* clamp integral to signed 16bit range*/
	if (d->integral > 32768)
		d->integral = 32768;
	if (d->integral < -32768)
		d->integral = -32768;

	int derivative = (error - d->previous_error);
	d->previous_error = error;
	int result = actual + (((d->Kp * error) >> PID_RESOLUTION) + ((d->Ki * d->integral) >> PID_RESOLUTION) + ((d->Kd * derivative)  >> PID_RESOLUTION));

	/* check for max / min */
	if (result > PID_MAX_OUTPUT)
		result = PID_MAX_OUTPUT;
	else if (result < PID_MIN_OUTPUT)
		result = PID_MIN_OUTPUT;

	return result;

}

int pid_regulator_delta( int set_point, int actual, pid_data *d )
{

	/* PID algorithm */
	int error = set_point - actual;

	d->integral = d->integral + error;

	int derivative = (error - d->previous_error);
	d->previous_error = error;

	return ((((d->Kp * error) >> PID_RESOLUTION) + frac_mul( d->Ki, d->integral ) + ((d->Kd * derivative)  >> PID_RESOLUTION)));


}

int pid_regulator_delta_cust_error( int error, pid_data *d )
{

	/* PID algorithm */

	d->integral = d->integral + error;
	int derivative = (error - d->previous_error);
	d->previous_error = error;

	return ((((d->Kp * error) >> PID_RESOLUTION) + frac_mul( d->Ki, d->integral ) + ((d->Kd * derivative)  >> PID_RESOLUTION)));

}
