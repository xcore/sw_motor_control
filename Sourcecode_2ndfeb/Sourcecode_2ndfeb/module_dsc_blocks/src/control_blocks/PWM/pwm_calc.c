/**
 * Module:  module_dsc_blocks
 * Version: 1v0alpha2
 * Build:   d6f1b08bc373431180841b062ab3e165ce3c38f7
 * File:    pwm_calc.c
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
#include "dsc_config.h"
#include "transform_constants.h"
#include <print.h>

void spwm_duty_calc( unsigned *chan1, unsigned *chan2, unsigned *chan3, int V1, int V2, int V3, unsigned theta )
{

	int sector = 0;
	int PWM1 = 0, PWM2 = 0, PWM3 = 0;
	int T0 = 0, T1 = 0, T2 = 0;

	/* calculate sector */
	if (theta >= 0 && theta <= 6000)
		sector = 3;
	else if (theta > 600 && theta <= 1200)
		sector = 1;
	else if (theta > 1200 && theta <= 1800)
		sector = 5;
	else if (theta > 1800 && theta <= 2400)
		sector = 4;
	else if (theta > 2400 && theta <= 3000)
		sector = 6;
	else if (theta > 3000 && theta <= 3600)
		sector = 2;
	else
	{
		printstr("spwm calc error: invalid theta\n");
		printintln(theta);
	}

	 switch (sector)
	 {
	 case (1): /* sector (0,0,1) 060-120deg*/
	 	 T1 = -V3;
	 	 T2 = -V2;
	 	 T0 = PWM_MAX_VALUE - T1 - T2;
	 	 PWM3 = T0 >> 1;
	 	 PWM1 = PWM3 + T1;
	 	 PWM2 = PWM1 + T2;
	 	 break;
	 case (2): /* sector (0,1,0) 300-360deg*/
	 	 T1 = -V1;
	 	 T2 = -V3;
	 	 T0 = PWM_MAX_VALUE - T1 - T2;
	 	 PWM2 = T0 >> 1;
	 	 PWM3 = PWM2 + T1;
	 	 PWM1 = PWM3 + T2;
	 	 break;
	 case (3): /* sector (0,1,1) 000-060deg*/
	 	 T1 = V1;
	 	 T2 = V2;
	 	 T0 = PWM_MAX_VALUE - T1 - T2;
	 	 PWM3 = T0 >> 1;
	 	 PWM2 = PWM3 + T1;
	 	 PWM1 = PWM2 + T2;
	 	 break;
	 case (4): /* sector (1,0,0) 180-240deg*/
	 	 T1 = -V2;
	 	 T2 = -V1;
	 	 T0 = PWM_MAX_VALUE - T1 - T2;
	 	 PWM1 = T0 >> 1;
	 	 PWM2 = PWM1 + T1;
	 	 PWM3 = PWM2 + T2;
	 	 break;
	 case (5): /* sector (1,0,1) 120-180deg*/
	 	 T1 = V3;
	 	 T2 = V1;
	 	 T0 = PWM_MAX_VALUE - T1 - T2;
	 	 PWM1 = T0 >> 1;
	 	 PWM3 = PWM1 + T1;
	 	 PWM2 = PWM3 + T2;
	 	 break;
	 case (6): /* sector (1,1,0) 240-300deg*/
	 	 T1 = V2;
	 	 T2 = V3;
	 	 T0 = PWM_MAX_VALUE - T1 - T2;
	 	 PWM2 = T0 >> 1;
	 	 PWM1 = PWM2 + T1;
	 	 PWM3 = PWM1 + T2;
	 	 break;
	 default: /* stop the motor by switching everything to ground */
	 	 PWM1 = 0;
	 	 PWM2 = 0;
	 	 PWM3 = 0;
	 	 break;
	 }
	 *chan1 = PWM1;
	 *chan2 = PWM2;
	 *chan3 = PWM3;
}


void svpwm_calc(  unsigned *chan1, unsigned *chan2, unsigned *chan3, int Valpha, int Vbeta, unsigned theta )
{
	unsigned sector = 0;
	int Ualpha = 0, Ubeta = 0;
	int X, Y, Z;
	unsigned PWM1, PWM2, PWM3;

	Ualpha = (443 * PWM_MAX_VALUE * Valpha) >> 8;
	Ubeta = PWM_MAX_VALUE * Vbeta;

	X = Ubeta;
	Y = (Ualpha + Ubeta) >> 1;
	Z = (Ubeta - Ualpha) >> 1;

	if (Y < 0)
	{
		if (Z < 0)
			sector = 5;
		else
		{
			if (X <= 0)
				sector = 4;
			else
				sector = 3;
		}
	}
	else
	{
		if (Z < 0)
		{
			if (X <= 0)
				sector = 6;
			else
				sector = 1;
		}
		else
			sector = 2;
	}

	switch (sector)
	{
	case (1):
	case (4):
		PWM1 = (PWM_MAX_VALUE + X - Z) >> 1;
		PWM2 = PWM1 + Z;
		PWM3 = PWM2 - X;
		break;
	case (2):
	case (5):
		PWM1 = (PWM_MAX_VALUE + Y - Z) >> 1;
		PWM2 = PWM1 + Z;
		PWM3 = PWM1 - Y;
		break;
	case (3):
	case (6):
		PWM1 = (PWM_MAX_VALUE - X + Y) >> 1;
		PWM3 = PWM1 - Y;
		PWM2 = PWM3 + X;
		break;
	}

	*chan1 = PWM1;
	*chan2 = PWM2;
	*chan3 = PWM3;
}
