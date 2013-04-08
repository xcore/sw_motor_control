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

/*****************************************************************************/
void init_pid_consts( // Initialise a set of PID Constants
	PID_CONST_TYP * pid_const_p, // Pointer to PID constants data structure
	int inp_K_p, // Input Proportional Error constant
	int inp_K_i, // Input Integral Error constant
	int inp_K_d, // Input Differential Error constant
	int inp_resolution // Input PID resolution
)
{
	pid_const_p->K_p = inp_K_p;
	pid_const_p->K_i = inp_K_i;
	pid_const_p->K_d = inp_K_d;
	pid_const_p->resolution = inp_resolution;

	// Calculate rounding error based on resolution
	pid_const_p->half_res = (1 << (pid_const_p->resolution - 1));
} // init_pid_consts
/*****************************************************************************/
void initialise_pid( // Initialise PID regulator 
	PID_REGULATOR_TYP * pid_regul_p // Pointer to PID regulator data structure
)
{
	// Initialise variables
	pid_regul_p->sum_err = 0;
	pid_regul_p->prev_err = 0;
	pid_regul_p->qnt_err = 0;
	pid_regul_p->rem = 0;
} // initialise_pid
/*****************************************************************************/
int get_pid_regulator_correction( // Computes new PID correction based on input error
	unsigned motor_id, // Unique Motor identifier e.g. 0 or 1
	PID_REGULATOR_TYP * pid_regul_p, // Pointer to PID regulator data structure
	PID_CONST_TYP * pid_const_p, // Local pointer to PID constants data structure
	int meas_val, // measured value
	int requ_val // request value
)
{
	int inp_err = (requ_val - meas_val); // Compute input error
	int diff_err; // Compute difference error
	int tmp_err; // temporary error
	int down_err; // down-scaled error
	S64_T res_64; // Result at 64-bit precision
	int res_32; // Result at 32-bit precision


	// Build 64-bit result
	res_64 = (S64_T)pid_const_p->K_p * (S64_T)inp_err;

	// Check if Integral Error used
	if (pid_const_p->K_i)
	{
		tmp_err = inp_err + pid_regul_p->rem; // Add-in previous remainder
		down_err = (int)((tmp_err + (S64_T)pid_const_p->half_res) >> pid_const_p->resolution); // Down-scale error 
		pid_regul_p->rem = tmp_err - (down_err << pid_const_p->resolution); // Update remainder

		pid_regul_p->sum_err += down_err; // Update Sum of (down-scaled) errors
		res_64 += (S64_T)pid_const_p->K_i * (S64_T)pid_regul_p->sum_err;
	} // if (pid_const_p->K_d)
 
	// Check if Differential Error used
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

	return res_32;
}
/*****************************************************************************/
// pid_regulator.c
