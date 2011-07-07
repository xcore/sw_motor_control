  /**
 * Module:  app_dsc_demo
 * Version: 1v0alpha1
 * Build:   dcbd8f9dde72e43ef93c00d47bed86a114e0d6ac
 * File:    main.xc
 * Modified by : Srikanth
 * Last Modified on : 26-May-2011
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
#include <xs1.h>
#include <platform.h>
#include <print.h>
#include <stdio.h>

#include "dsc_config.h"
#include "shared_io.h"
#include "qei_server.h"
#include "qei_client.h"
#include "lcd.h"


// LCD, LED & Button Ports
on stdcore[INTERFACE_CORE]: lcd_interface_t lcd_ports =
{
    //XS1_CLKBLK_4, // XS1_CLKBLK_5,
    PORT_DS_SCLK, PORT_DS_MOSI, PORT_DS_CS_N, PORT_CORE1_SHARED
};

on stdcore[MOTOR_CORE]: port in p_qei = PORT_M1_ENCODER;

void display(chanend c)
{
	char my_string[50];

	timer tmr;
	unsigned t;

	// The shared port value - shared port is shared between LCD and something else
	unsigned int port_val = 0b0010;

	/* Initiate the LCD ports */
	lcd_ports_init(lcd_ports);

	/* Output the default value to the port */
	lcd_ports.p_core1_shared <: port_val;

	/* Initiate the LCD*/
	lcd_comm_out(lcd_ports, 0xE2, port_val);		/* RESET */
	lcd_comm_out(lcd_ports, 0xA0, port_val);		/* RAM->SEG output = normal */
	lcd_comm_out(lcd_ports, 0xAE, port_val);		/* Display OFF */
	lcd_comm_out(lcd_ports, 0xC0, port_val);		/* COM scan direction = normal */
	lcd_comm_out(lcd_ports, 0xA2, port_val);		/* 1/9 bias */
	lcd_comm_out(lcd_ports, 0xC8, port_val);		/*  Reverse */
	lcd_comm_out(lcd_ports, 0x2F, port_val);		/* power control set */
	lcd_comm_out(lcd_ports, 0x20, port_val);		/* resistor ratio set */
	lcd_comm_out(lcd_ports, 0x81, port_val);		/* Electronic volume command (set contrast) */
	lcd_comm_out(lcd_ports, 0x3F, port_val);		/* Electronic volume value (contrast value) */
	lcd_clear(port_val, lcd_ports);					/* Clear the display RAM */
	lcd_comm_out(lcd_ports, 0xB0, port_val);		/* Reset page and column addresses */
	lcd_comm_out(lcd_ports, 0x10, port_val);		/* column address upper 4 bits + 0x10 */
	lcd_comm_out(lcd_ports, 0x00, port_val);		/* column address lower 4 bits + 0x00 */

	tmr :> t;

	// Loop forever processing commands
	while (1)
	{
		select
		{
			case tmr when timerafter(t) :> void :
			{
				unsigned pos = get_qei_position(c);
				unsigned spd = get_qei_speed(c);

				sprintf(my_string, " Position %d\n", pos );
				lcd_draw_text_row( my_string, 1, port_val, lcd_ports );

				sprintf(my_string, " Speed %d\n", spd );
				lcd_draw_text_row( my_string, 2, port_val, lcd_ports );

				t += 10000000;
			}
			break;
		}
	}
}

// Program Entry Point
int main ( void )
{
	chan c_qei;

	par
	{
		// Xcore 1 - INTERFACE_CORE
		on stdcore[INTERFACE_CORE] : display(c_qei);

		// Xcore 2 - MOTOR_CORE
#ifdef USE_MOTOR
		on stdcore[MOTOR_CORE] : do_qei ( c_qei, p_qei );
#endif
	}

	return 0;
}
