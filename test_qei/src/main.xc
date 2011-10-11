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

on stdcore[1]: port in p_qei1 = PORT_M1_ENCODER;
on stdcore[1]: port in p_qei2 = PORT_M2_ENCODER;

void display(streaming chanend c1, streaming chanend c2)
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
				unsigned pos1, spd1, ts1, lpo1, lts1;
				unsigned pos2, spd2, ts2, lpo2, lts2;

				{ts1, pos1} = get_qei_data( c1 );
				{ts2, pos2} = get_qei_data( c2 );

				// Calculate speed
				spd1 = get_speed(ts1, lts1, pos1, lpo1);
				lts1 = ts1;
				lpo1 = pos1;
				spd2 = get_speed(ts2, lts2, pos2, lpo2);
				lts2 = ts2;
				lpo2 = pos2;


				sprintf(my_string, " Position1 %d\n", pos1 );
				lcd_draw_text_row( my_string, 0, lcd_ports );
				sprintf(my_string, " Speed1 %d\n", spd1 );
				lcd_draw_text_row( my_string, 1, lcd_ports );

				sprintf(my_string, " Position2 %d\n", pos2 );
				lcd_draw_text_row( my_string, 2, lcd_ports );
				sprintf(my_string, " Speed2 %d\n", spd2 );
				lcd_draw_text_row( my_string, 3, lcd_ports );

				t += 10000000;
			}
			break;
		}
	}
}

// Program Entry Point
int main ( void )
{
	streaming chan c_qei1, c_qei2;

	par
	{
		// Xcore 1 - INTERFACE_CORE
		on stdcore[0] : display(c_qei1, c_qei2);

		// Xcore 2 - MOTOR_CORE
		on stdcore[1] : do_qei( c_qei1, p_qei1 );
		on stdcore[1] : do_qei( c_qei2, p_qei2 );
	}

	return 0;
}
