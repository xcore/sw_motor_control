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
#include "hall_input.h"
#include "pwm_cli.h"
#include "pwm_service.h"
#include "run_motor.h"
#include "watchdog.h"
#include "shared_io_motor.h"
#include "speed_cntrl.h"
#include "initialisation.h"
#include <stdio.h>


/* core with LCD and BUTTON interfaces */
on stdcore[INTERFACE_CORE]: lcd_interface_t lcd_ports = { PORT_DS_SCLK, PORT_DS_MOSI, PORT_DS_CS_N, PORT_CORE1_SHARED };
on stdcore[INTERFACE_CORE]: port in btns[4] = {PORT_BUTTON_A, PORT_BUTTON_B, PORT_BUTTON_C, PORT_BUTTON_D};

/* motor1 core ports */

on stdcore[MOTOR_CORE]: port in p_hall = PORT_M1_ENCODER;
on stdcore[MOTOR_CORE]: buffered out port:32 p_pwm_hi1[3] = {PORT_M1_HI_A, PORT_M1_HI_B, PORT_M1_HI_C};
on stdcore[MOTOR_CORE]: out port p_motor_lo1[3] = {PORT_M1_LO_A, PORT_M1_LO_B, PORT_M1_LO_C};
on stdcore[MOTOR_CORE]: out port i2c_wd = PORT_I2C_WD_SHARED;
on stdcore[MOTOR_CORE]: clock pwm_clk = XS1_CLKBLK_1;

/* motor2 core ports */
on stdcore[MOTOR_CORE]: port in p_hall2 = PORT_M2_ENCODER;
on stdcore[MOTOR_CORE]: buffered out port:32 p_pwm_hi2[3] = {PORT_M2_HI_A, PORT_M2_HI_B, PORT_M2_HI_C};
on stdcore[MOTOR_CORE]: out port p_motor_lo2[3] = {PORT_M2_LO_A, PORT_M2_LO_B, PORT_M2_LO_C};
on stdcore[MOTOR_CORE]: clock pwm_clk2 = XS1_CLKBLK_4;

int main ( void )
{
	chan c_wd, c_pwm1, c_control1, c_lcd1, c_control2, c_pwm2, c_lcd2 ;

	par
	{
		/* L2 */
		on stdcore[INTERFACE_CORE]: speed_control1( c_control1, c_lcd1 );
		on stdcore[INTERFACE_CORE]: speed_control2( c_control2, c_lcd2 );
		on stdcore[INTERFACE_CORE]: display_shared_io_motor( c_lcd1, c_lcd2, lcd_ports, btns);

		/* L1 */
		on stdcore[MOTOR_CORE]: do_pwm1( c_pwm1, p_pwm_hi1, pwm_clk);
		on stdcore[MOTOR_CORE]: run_motor1 ( c_wd, c_pwm1, c_control1, p_hall, p_motor_lo1 );
		on stdcore[MOTOR_CORE]: do_pwm2( c_pwm2, p_pwm_hi2, pwm_clk2);
		on stdcore[MOTOR_CORE]: run_motor2 ( c_pwm2, c_control2, p_hall2, p_motor_lo2 );
		on stdcore[MOTOR_CORE]: do_wd(c_wd, i2c_wd);

	}
	return 0;
}
