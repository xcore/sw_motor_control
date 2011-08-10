/**
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
#include <print.h>
#include <stdio.h>

#include "shared_io.h"
#include "qei_server.h"
#include "qei_client.h"
#include "lcd.h"


// LCD, LED & Button Ports
on stdcore[0]: lcd_interface_t lcd_ports = { PORT_SPI_CLK, PORT_SPI_MOSI, PORT_SPI_SS_DISPLAY, PORT_SPI_DSA };

on stdcore[1]: port in p_qei = PORT_M1_ENCODER;

void display(chanend c)
{
	char my_string[50];

	timer tmr;
	unsigned t;

	/* Initiate the LCD ports */
	lcd_ports_init(lcd_ports);

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
				lcd_draw_text_row( my_string, 1, lcd_ports );

				sprintf(my_string, " Speed %d\n", spd );
				lcd_draw_text_row( my_string, 2, lcd_ports );

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
		on stdcore[0] : display(c_qei);

		// Xcore 2 - MOTOR_CORE
		on stdcore[1] : do_qei ( c_qei, p_qei );
	}

	return 0;
}
