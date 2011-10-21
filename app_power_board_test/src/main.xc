/**
 * Module:  app_basic_bldc
 * Version: 1v1
 * Build:
 * File:    main.xc
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

#include <xs1.h>
#include <platform.h>
#include <stdio.h>
#include <print.h>
#include <stdlib.h>

#include "pwm_service_inv.h"
#include "run_motor.h"
#include "watchdog.h"
#include "qei_server.h"
#include "adc_7265.h"
#include "dsc_config.h"


// Motor 1 ports
on stdcore[MOTOR_CORE]: port in p_hall1 = PORT_M1_HALLSENSOR;
on stdcore[MOTOR_CORE]: buffered out port:32 p_pwm_hi1[3] = {PORT_M1_HI_A, PORT_M1_HI_B, PORT_M1_HI_C};
on stdcore[MOTOR_CORE]: buffered out port:32 p_pwm_lo1[3] = {PORT_M1_LO_A, PORT_M1_LO_B, PORT_M1_LO_C};
on stdcore[MOTOR_CORE]: clock pwm_clk1 = XS1_CLKBLK_REF;
on stdcore[MOTOR_CORE]: port in p_qei1 = PORT_M1_ENCODER;

// Motor 2 ports
on stdcore[MOTOR_CORE]: port in p_hall2 = PORT_M2_HALLSENSOR;
on stdcore[MOTOR_CORE]: buffered out port:32 p_pwm_hi2[3] = {PORT_M2_HI_A, PORT_M2_HI_B, PORT_M2_HI_C};
on stdcore[MOTOR_CORE]: buffered out port:32 p_pwm_lo2[3] = {PORT_M2_LO_A, PORT_M2_LO_B, PORT_M2_LO_C};
on stdcore[MOTOR_CORE]: clock pwm_clk2 = XS1_CLKBLK_4;
on stdcore[MOTOR_CORE]: port in p_qei2 = PORT_M2_ENCODER;

// Watchdog port
on stdcore[INTERFACE_CORE]: out port i2c_wd = PORT_WATCHDOG;

//ADC
on stdcore[MOTOR_CORE]: out port ADC_SCLK = PORT_ADC_CLK;
on stdcore[MOTOR_CORE]: port ADC_CNVST = PORT_ADC_CONV;
on stdcore[MOTOR_CORE]: buffered in port:32 ADC_DATA_A = PORT_ADC_MISOA;
on stdcore[MOTOR_CORE]: buffered in port:32 ADC_DATA_B = PORT_ADC_MISOB;
on stdcore[MOTOR_CORE]: out port ADC_MUX = PORT_ADC_MUX;
on stdcore[MOTOR_CORE]: in port ADC_SYNC_PORT1 = XS1_PORT_16A;
on stdcore[MOTOR_CORE]: in port ADC_SYNC_PORT2 = XS1_PORT_16B;
on stdcore[MOTOR_CORE]: clock adc_clk = XS1_CLKBLK_2;

void do_complete(chanend c_done)
{
	unsigned fail;
	c_done :> fail;

	printstr("Done\n");

	if (fail == 0) {
		printstr("Pass\n");
		exit(0);
	} else {
		printstr("FAIL\n");
		if ((fail & 0x11) == 0x11) printstr("ADC 1\n");
		if ((fail & 0x10) == 0x10) printstr("Hall 1\n");
		if ((fail & 0x08) == 0x08) printstr("QEI 1\n");
		if ((fail & 0x04) == 0x04) printstr("ADC 2\n");
		if ((fail & 0x02) == 0x02) printstr("Hall 2\n");
		if ((fail & 0x01) == 0x01) printstr("QEI 2\n");
		exit(1);
	}
}

int main ( void )
{
	chan c_wd, c_ctrl, c_done;
	chan c_pwm[NUMBER_OF_MOTORS];
	chan c_adc_trig[NUMBER_OF_MOTORS];
	streaming chan c_adc[NUMBER_OF_MOTORS];
	streaming chan c_qei[NUMBER_OF_MOTORS];

	par
	{
		/* L2 */
		on stdcore[INTERFACE_CORE]: do_complete(c_done);
		on stdcore[INTERFACE_CORE]: do_wd(c_wd, i2c_wd);

		/* L1 */
		on stdcore[MOTOR_CORE]: run_motor( null, c_ctrl, c_wd, c_pwm[0], c_adc[0], c_qei[0], p_hall1 );
		on stdcore[MOTOR_CORE] : do_pwm_inv_triggered( c_pwm[0], c_adc_trig[0], ADC_SYNC_PORT1, p_pwm_hi1, p_pwm_lo1, pwm_clk1 );
		on stdcore[MOTOR_CORE] : do_qei ( c_qei[0], p_qei1 );

		on stdcore[MOTOR_CORE]: run_motor( c_ctrl, c_done, null, c_pwm[1], c_adc[1], c_qei[1], p_hall2 );
		on stdcore[MOTOR_CORE] : do_pwm_inv_triggered( c_pwm[1], c_adc_trig[1], ADC_SYNC_PORT2, p_pwm_hi2, p_pwm_lo2, pwm_clk2 );
		on stdcore[MOTOR_CORE] : do_qei ( c_qei[1], p_qei2 );

		on stdcore[MOTOR_CORE] : adc_7265_triggered( c_adc, c_adc_trig, adc_clk, ADC_SCLK, ADC_CNVST, ADC_DATA_A, ADC_DATA_B, ADC_MUX );
	}
	return 0;
}
