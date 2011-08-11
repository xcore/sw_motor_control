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
#include "lcd.h"


// LCD, LED & Button Ports
on stdcore[0]: lcd_interface_t lcd_ports = { PORT_SPI_CLK, PORT_SPI_MOSI, PORT_SPI_SS_DISPLAY, PORT_SPI_DSA };

on stdcore[1]: port in p_hall1 = PORT_M1_HALLSENSOR;
on stdcore[1]: port in p_hall2 = PORT_M2_HALLSENSOR;

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
				unsigned pos1, pos2;
				c <: 0;
				c :> pos1;
				c :> pos2;

				sprintf(my_string, " Hall1 0x%x\n", pos1 );
				lcd_draw_text_row( my_string, 1, lcd_ports );

				sprintf(my_string, " Hall2 0x%x\n", pos2 );
				lcd_draw_text_row( my_string, 2, lcd_ports );

				t += 10000000;
			}
			break;
		}
	}
}

void run_hall(chanend c, in port p_hall1, in port p_hall2)
{
	while (1)
	{
		select
		{
			case c :> unsigned :
			{
				unsigned val;
				p_hall1 :> val;
				c <: val;
				p_hall2 :> val;
				c <: val;
			}
			break;
		}
	}
}

// Program Entry Point
int main ( void )
{
	chan c;

	par
	{
		// Xcore 1 - INTERFACE_CORE
		on stdcore[0] : display(c);

		// Xcore 2 - MOTOR_CORE
		on stdcore[1] : run_hall( c, p_hall1, p_hall2 );
	}

	return 0;
}
