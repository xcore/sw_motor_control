/**
 * Module:  module_dsc_blocks
 * Version: 1v0alpha1
 * Build:   c9e25ba4f74e9049d5da65cb5c829a3d932ed199
 * File:    pid_regulator.c
 * Modified by : Srikanth
 * Last Modified on : 26-May-2011
 *
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

const PID_CONST_TYP pid_const_Id = { DQ_P ,DQ_I ,DQ_D ,DQ_INTEGRAL_LIMIT ,D_HI_LIM ,D_LO_LIM ,PID_RESOLUTION };
const PID_CONST_TYP pid_const_Iq = { DQ_P ,DQ_I ,DQ_D ,DQ_INTEGRAL_LIMIT ,Q_LIMIT ,-Q_LIMIT ,PID_RESOLUTION };
const PID_CONST_TYP pid_const_speed = { SPEED_P ,SPEED_I ,SPEED_D ,SPEED_INTEGRAL_LIMIT ,SPEED_HI_LIM ,-SPEED_HI_LIM ,PID_RESOLUTION };

/*****************************************************************************/
void initialise_pid( // Initialise PID settings
	PID_REGULATOR_TYP * pid_regul_p, // Pointer to PID regulator data structure
	PID_ENUM pid_id // Identifies which PID is being initialised
)
{
	// Assign correct constants based on PID identifier
	switch( pid_id )
	{
		case I_D :
			pid_regul_p->consts = pid_const_Id; // Assign Id constants
		break; // case I_D

		case I_Q :
			pid_regul_p->consts = pid_const_Iq; // Assign Iq constants
		break; // case I_Q

		case SPEED :
			pid_regul_p->consts = pid_const_speed; // Assign Iq constants
		break; // case SPEED

		default :
			assert( 0 == 1 ); // ERROR: Unsupported PID regulator
		break; // default

	} // switch( pid_id )

	// Calculate rounding error based on resolution
	pid_regul_p->consts.half_res = (1 << (pid_regul_p->consts.resolution - 1));

	// Initialise variables
	pid_regul_p->sum_err = 0;
	pid_regul_p->prev_err = 0;
	pid_regul_p->qnt_err = 0;
	pid_regul_p->rem = 0;
} // inititialise_pid
/*****************************************************************************/
int get_pid_regulator_correction( // Computes new PID correction based on input error
	unsigned motor_id, // Unique Motor identifier e.g. 0 or 1
	PID_REGULATOR_TYP * pid_regul_p, // Pointer to PID regulator data structure
	int meas_val, // measured value
	int requ_val // request value
)
#define MAX_32 0x40000000
{
	PID_CONST_TYP * pid_const_p = &(pid_regul_p->consts); // Local pointer to PID constants data structure
	int inp_err = (requ_val - meas_val); // Compute input error
	int diff_err; // Compute difference error
	int tmp_err; // temporary error
	int down_err; // down-scaled error
	S64_T res_64; // Result at 64-bit precision
	int res_32; // Result at 32-bit precision



	// Build 64-bit result
	res_64 = (S64_T)pid_const_p->K_p * (S64_T)inp_err;

	if (pid_const_p->K_i)
	{
		tmp_err = inp_err + pid_regul_p->rem; // Add-in previous remainder
		down_err = (int)((tmp_err + (S64_T)pid_const_p->half_res) >> pid_const_p->resolution); // Down-scale error 
		pid_regul_p->rem = tmp_err - (down_err << pid_const_p->resolution); // Update remainder

		pid_regul_p->sum_err += down_err; // Update Sum of (down-scaled) errors
		res_64 += (S64_T)pid_const_p->K_i * (S64_T)pid_regul_p->sum_err;
	} // if (pid_const_p->K_d)
 
	if (pid_const_p->K_d)
	{
		diff_err = (inp_err - pid_regul_p->prev_err); // Compute difference error

		res_64 += (S64_T)pid_const_p->K_d * (S64_T)diff_err;

		pid_regul_p->prev_err = inp_err; // Update previous error
	} // if (pid_const_p->K_d)
pid_regul_p->prev_err = inp_err; // MB~ Dbg
 
	// Convert to 32-bit result ...

	res_64 += pid_regul_p->qnt_err; // Add-in previous quantisation (diffusion) error
	res_32 = (int)((res_64 + (S64_T)pid_const_p->half_res) >> pid_const_p->resolution); // Down-scale result
	pid_regul_p->qnt_err = res_64 - ((S64_T)res_32 << pid_const_p->resolution); // Update diffusion error

// if (motor_id) printintln( res_32 );
#ifdef MB // Do we want these clamps?
	// If necessary, Clip res_32
	if (res_32 > pid_const_p->max_lim)
	{
		res_32 = pid_const_p->max_lim;
	} // if (res_32 > pid_const_p->max_lim)
	else
	{
		if (res_32 < pid_const_p->min_lim)
		{
			res_32 = pid_const_p->min_lim;
		} // if (res_32 < pid_const_p->min_lim)
	} // else !(res_32 > pid_const_p->mix_lim)

	// If necessary, Clip Sum-of-errors 
	if (pid_regul_p->sum_err > pid_const_p->sum_lim)
	{
		pid_regul_p->sum_err = pid_const_p->sum_lim;
	} // if (pid_regul_p->sum_err > pid_const_p->sum_lim)
	else
	{
		if (pid_regul_p->sum_err < -pid_const_p->sum_lim)
		{
			pid_regul_p->sum_err = -pid_const_p->sum_lim;
		} // if (pid_regul_p->sum_err < -pid_const_p->sum_lim)
	} // else !(pid_regul_p->sum_err > pid_const_p->sum_lim)
#endif //MB // Do we want these clamps?

	return res_32;
}
/*****************************************************************************/
#ifdef MB // Depreciated
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

int pid_regulator_delta_cust_error_speed( int error, pid_data *d )
{
	/* PID algorithm */
	int result=0;

	d->integral = d->integral + error;

	if (d->integral > SPEED_INTEGRAL_LIMIT) d->integral = SPEED_INTEGRAL_LIMIT;
	else if (d->integral < -SPEED_INTEGRAL_LIMIT) d->integral = -SPEED_INTEGRAL_LIMIT;

	int derivative = (error - d->previous_error);
	d->previous_error = error;

	result = (((d->Kp * error) + (d->Kd * derivative)) >> PID_RESOLUTION) + frac_mul( d->Ki, d->integral);

#ifdef BLDC_FOC
	if (result > SPEED_LIMIT)
	{
printf("B\n");
		result = (result >> 2);
	} // if (result > SPEED_LIMIT)
	else
	{
		if (result < -SPEED_LIMIT)
		{
printf("S\n");
			result = -((-result) >> 2);
		} // if (result < -SPEED_LIMIT)
	} // else !(result > SPEED_LIMIT)
#endif


	return result;
}

int pid_regulator_delta_cust_error_Iq_control( int error, pid_data *iq )
{
	/* PID algorithm */
	int result=0;

	iq->integral = iq->integral + error;

	if (iq->integral > DQ_INTEGRAL_LIMIT) iq->integral = DQ_INTEGRAL_LIMIT;
	else if (iq->integral < -DQ_INTEGRAL_LIMIT) iq->integral = -DQ_INTEGRAL_LIMIT;

	int derivative = (error - iq->previous_error);
	iq->previous_error = error;

	result = (((iq->Kp * error) + (iq->Kd * derivative)) >> PID_RESOLUTION) + frac_mul( iq->Ki, iq->integral );

	if(result > Q_LIMIT) result = Q_LIMIT;
	else if(result < -Q_LIMIT) result = -Q_LIMIT;

	return result;

}

int pid_regulator_delta_cust_error_Id_control( int error, pid_data *id )
{
	/* PID algorithm */
	int result=0;

	id->integral = id->integral + error;

	if (id->integral > DQ_INTEGRAL_LIMIT) id->integral = DQ_INTEGRAL_LIMIT;
	else if (id->integral < -DQ_INTEGRAL_LIMIT) id->integral = -DQ_INTEGRAL_LIMIT;

	int derivative = (error - id->previous_error);
	id->previous_error = error;

	result = (((id->Kp * error) + (id->Kd * derivative)) >> PID_RESOLUTION) + frac_mul( id->Ki, id->integral );

	if(result > D_LIMIT) result = D_LIMIT;
	else if(result < -D_LIMIT) result = -D_LIMIT;

	return result;
}
#endif //MB~ Depreciated
/*****************************************************************************/
// pid_regulator.c
