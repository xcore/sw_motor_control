/**
 * Module:  module_dsc_display
 * Version: 1v0module_dsc_display3
 * Build:
 * File:    shared_io_motor.xc
 * Author: 	Srikanth
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

#include "xs1.h"
#include <dsc_config.h>
#include "lcd.h"
#include "shared_io_motor.h"
#include "stdio.h"
#include "print.h"

/* Manages the display, buttons and shared ports. */
void display_shared_io_motor( chanend c_lcd, chanend c_lcd2, REFERENCE_PARAM(lcd_interface_t, p), in port btns[])
{
	unsigned int time, MIN_VAL=0, speed1 = 0, speed2 = 0, set_speed = INITIAL_SET_SPEED;
	/* Default port value on device boot */
	unsigned int port_val = 0b0010;
	unsigned int btn_en[4] = {0,0,0,0};
	unsigned toggle = 1;
	char my_string[50];
	unsigned ts,temp=0;
	timer t,x;

	/* Initiate the LCD ports */
	lcd_ports_init(p);

	/* Output the default value to the port */
	p.p_core1_shared <: port_val;

	/* Initiate the LCD*/
	lcd_comm_out(p, 0xE2, port_val);		/* RESET */
	lcd_comm_out(p, 0xA0, port_val);		/* RAM->SEG output = normal */
	lcd_comm_out(p, 0xAE, port_val);		/* Display OFF */
	lcd_comm_out(p, 0xC0, port_val);		/* COM scan direction = normal */
	lcd_comm_out(p, 0xA2, port_val);		/* 1/9 bias */
	lcd_comm_out(p, 0xC8, port_val);		/*  Reverse */
	lcd_comm_out(p, 0x2F, port_val);		/* power control set */
	lcd_comm_out(p, 0x20, port_val);		/* resistor ratio set */
	lcd_comm_out(p, 0x81, port_val);		/* Electronic volume command (set contrast) */
	lcd_comm_out(p, 0x3F, port_val);		/* Electronic volume value (contrast value) */
	lcd_clear(port_val, p);					/* Clear the display RAM */
	lcd_comm_out(p, 0xB0, port_val);		/* Reset page and column addresses */
	lcd_comm_out(p, 0x10, port_val);		/* column address upper 4 bits + 0x10 */
	lcd_comm_out(p, 0x00, port_val);		/* column address lower 4 bits + 0x00 */

	/* Get the initial time value */
	t :> time;

	/* Loop forever processing commands */
	while (1)
	{
		select
		{
		/* Timer event at 10Hz */
			case t when timerafter(time + 10000000) :> time:
		/* Get the motor 1 speed and motor 2 speed */
				c_lcd <: CMD_GET_IQ;
				c_lcd :> speed1;
				c_lcd :> set_speed;

				c_lcd2 <: CMD_GET_IQ2;
				c_lcd2 :> speed2;


		/* Calculate the strings here */
		/* Now update the display */
				lcd_draw_text_row( "  XMOS DSC Demo 2011\n", 0, port_val, p );
				sprintf(my_string, "  Set Speed: %04d RPM\n", set_speed );
				lcd_draw_text_row( my_string, 1, port_val, p );

				sprintf(my_string, "  Speed1 : 	 %04d RPM\n", speed1 );
				lcd_draw_text_row( my_string, 2, port_val, p );

				sprintf(my_string, "  Speed2 : 	 %04d RPM\n", speed2 );
				lcd_draw_text_row( my_string, 3, port_val, p );

		/* Switch debouncing - run through and decrement their counters. */
				for  ( int i = 0; i < 3; i ++ )
				{
					if ( btn_en[i] != 0)
						btn_en[i]--;
				}
				break;

		/* Button A is up */
			case !btn_en[0] => btns[0] when pinseq(0) :> void:
		/* Increase the speed, by the increment */
				set_speed += PWM_INC_DEC_VAL;
				if (set_speed > 6500)
					set_speed = 6500;
		/* Update the speed control loop */
				c_lcd <: CMD_SET_SPEED;
				c_lcd <: set_speed;

				c_lcd2 <: CMD_SET_SPEED2;
				c_lcd2 <: set_speed;
		/* Increment the debouncer */
				btn_en[0] = 4;
				break;

		/* Button B is down */
			case !btn_en[1] => btns[1] when pinseq(0) :> void:

				set_speed -= PWM_INC_DEC_VAL;
		/* Limit the speed to the minimum value */
				if (set_speed < MIN_RPM)
				{
					set_speed = MIN_RPM;
					MIN_VAL = set_speed;
				}

		/* Update the speed control loop */
				c_lcd <: CMD_SET_SPEED;
				c_lcd <: set_speed;

				c_lcd2 <: CMD_SET_SPEED2;
				c_lcd2 <: set_speed;
		/* Increment the debouncer */
				btn_en[1] = 4;
				break;

		/* Button C */
			case !btn_en[2] => btns[2] when pinseq(0) :> void:

				toggle = !toggle;
				temp = set_speed;

		/* to avoid jerks during the direction change*/
				while(set_speed > 100)
				{
				set_speed -= 50;
		/* Update the speed control loop */
				c_lcd <: CMD_SET_SPEED;
				c_lcd <: set_speed;
				c_lcd2 <: CMD_SET_SPEED2;
				c_lcd2 <: set_speed;
				x :> ts;
				x when timerafter(ts+3000000) :> ts;
				}
				set_speed  =0;
				if(toggle == 0)
				printstrln(" Motors Running...Clock Wise Direction...");
			else
				printstrln(" Motors Running...Counter Clock Wise Direction...");
		/* Update the speed control loop */
				c_lcd <: CMD_SET_SPEED;
				c_lcd <: set_speed;
				c_lcd2 <: CMD_SET_SPEED2;
				c_lcd2 <: set_speed;
		/* Update the direction change */
				c_lcd <: CMD_DIR;
				c_lcd <: toggle;
				c_lcd2 <: CMD_DIR2;
				c_lcd2 <: toggle;
		/* to avoid jerks during the direction change*/
				while(set_speed < temp)
				{
					set_speed += 50;
					c_lcd <: CMD_SET_SPEED;
					c_lcd <: set_speed;
					c_lcd2 <: CMD_SET_SPEED2;
					c_lcd2 <: set_speed;
					x :> ts;
					x when timerafter(ts+3000000) :> ts;
				}
				set_speed  = temp;
		/* Update the speed control loop */
				c_lcd <: CMD_SET_SPEED;
				c_lcd <: set_speed;
				c_lcd2 <: CMD_SET_SPEED2;
				c_lcd2 <: set_speed;

		/* Increment the debouncer */
				btn_en[2] = 4;
				break;

		/* Button D */
			case !btn_en[3] => btns[3] when pinseq(0) :> void:

		/* Increment the debouncer */
				btn_en[3] = 4;
				break;
		}
	}
}
