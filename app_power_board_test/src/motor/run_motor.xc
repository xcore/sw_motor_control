/**
 * Module:  app_basic_bldc
 * Version: 1v1
 * Build:
 * File:    run_motor.xc
 * Author: 	L & T
 *
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


#include <print.h>
#include <limits.h>
#include <stdlib.h>

#include "adc_client.h"
#include "adc_7265.h"
#include "qei_client.h"
#include "clarke.h"
#include "park.h"
#include "watchdog.h"

#include "run_motor.h"

#define PWM_MAX_LIMIT 3800
#define PWM_MIN_LIMIT 200
#define OFFSET_14 16383


void run_motor(chanend? c_ctrl_in, chanend? c_ctrl_out, chanend? c_wd, chanend c_pwm, streaming chanend c_adc, streaming chanend c_qei, port in p_hall)
{
	/* FOC variables */
	int id_out = 0, iq_out = 0;

	/* ADC variables */
	int a, b, c;
	int maxa = INT_MIN, mina = INT_MAX, maxb = INT_MIN, minb = INT_MAX, maxc = INT_MIN, minc = INT_MAX;

	/* Inverse Park transform outputs */
	int alpha_out = 0, beta_out = 0;

	/* PWM variables */
	unsigned pwm[3] = {0, 0, 0};
	int Va = 0, Vb = 0, Vc = 0;
	t_pwm_control pwm_ctrl;

	/* Hall variable */
	unsigned hall=0;

	/* General state management */
	unsigned start_up = 1024;

	/* Position and Speed */
	unsigned theta = 0, last_theta=-1, speed = 0, valid=0;
	unsigned qei_spd=1, qei_pos=1;

	/* Fault detection */
	unsigned OC_fault_flag=0, oc_status=0b0000;

	/* Timer and timestamp */
	timer t;
	unsigned ts1;

	/* Pass/Fail */
	unsigned fail=0;

	if (isnull(c_ctrl_in)) {
		printstr("POWER BOARD TEST\nStarting...\n");
	} else {
		c_ctrl_in :> fail;
	}

	// First send my PWM server the shared memory structure address
	pwm_share_control_buffer_address_with_server(c_pwm, pwm_ctrl);

	// Pause to allow the rest of the system to settle
	{
		unsigned thread_id = get_thread_id();
		t :> ts1;
		t when timerafter(ts1+2*SEC+256*thread_id) :> void;
	}

	/* Zero pwm */
	pwm[0] = 0;
	pwm[1] = 0;
	pwm[2] = 0;

	/* ADC centrepoint calibration before we start the PWM */
	do_adc_calibration( c_adc );

	/* Update PWM */
	update_pwm_inv( pwm_ctrl, c_pwm, pwm );

	/* allow the WD to get going */
	if (!isnull(c_wd)) {
		c_wd <: WD_CMD_START;
	}

	/* Main loop */
	while (start_up < QEI_COUNT_MAX*128)
	{
		/* Get OC fault pin status */
		p_hall :> oc_status;
		if(oc_status & 0b1000) {
			OC_fault_flag=0;
		} else {
			OC_fault_flag=1;
		}

		// Track hall
		hall |= (1<<(oc_status&0b0111));

		// Read ADC
		{a, b, c} = get_adc_vals_calibrated_int16( c_adc );

		// Read QEI
		{speed, theta, valid} = get_qei_data( c_qei );

		/* Spin the magnetic field around regardless of the encoder */
		theta = (start_up >> 2) & (QEI_COUNT_MAX-1);
		start_up++;

		iq_out = 2000;
		id_out = 0;

		/* Inverse park  [d,q] to [alpha, beta] */
		inverse_park_transform( alpha_out, beta_out, id_out, iq_out, theta  );

		/* Final voltages applied */
		inverse_clarke_transform( Va, Vb, Vc, alpha_out, beta_out );

		/* Scale to 12bit unsigned for PWM output */
		pwm[0] = (Va + OFFSET_14) >> 3;
		pwm[1] = (Vb + OFFSET_14) >> 3;
		pwm[2] = (Vc + OFFSET_14) >> 3;

		/* Clamp to avoid switching issues */
		for (int j = 0; j < 3; j++)
		{
			if (pwm[j] > PWM_MAX_LIMIT)
				pwm[j] = PWM_MAX_LIMIT;
			if (pwm[j] < PWM_MIN_LIMIT )
				pwm[j] = PWM_MIN_LIMIT;
		}

		/* Update the PWM values */
		update_pwm_inv( pwm_ctrl, c_pwm, pwm );

		if (start_up > QEI_COUNT_MAX*64) {

			// Record ADC
			if (mina > a) mina = a;
			if (maxa < a) maxa = a;
			if (minb > b) minb = b;
			if (maxb < b) maxb = b;
			if (minc > c) minc = c;
			if (maxc < c) maxc = c;

			// Check QEI speed
			if (speed < 10 || speed > 10000) qei_spd=0;

			// Check QEI position
			{
				int pos_diff = theta - last_theta;
				if (pos_diff < 0 || valid==0) qei_pos=0;
			}
		}
	}

	// Kill PWM
	pwm[0] = -1;
	pwm[1] = -1;
	pwm[2] = -1;
	update_pwm_inv( pwm_ctrl, c_pwm, pwm );

	// Verify ADC
	{
		unsigned p=1;
		if (maxa < 0) p = 0;
		if (maxb < 0) p = 0;
		if (maxc < 0) p = 0;
		if (mina > 0) p = 0;
		if (minb > 0) p = 0;
		if (minc > 0) p = 0;

		fail <<= 1;
		fail |= (p==1)?0:1;
	}

	// Verify hall
	fail <<= 1;
	fail |= (hall == 0b01111110)?0:1;

	// Verify QEI
	fail <<= 1;
	fail |= (qei_pos==0 || qei_spd==0)?1:0;

	// Trigger next motor
	c_ctrl_out <: fail;
}


