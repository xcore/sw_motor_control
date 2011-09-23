/**
 * Module:  module_dsc_display
 * Version: 1v0module_dsc_display3
 * File:    shared_io.xc
 * Modified by : Srikanth
 * Last Modified on : 28-Jul-2011
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
#include <stdio.h>

#include "dsc_config.h"

#include "lcd.h"
#include "shared_io.h"
#include "lcd_logo.h"

#ifndef NUMBER_OF_MOTORS
#define NUMBER_OF_MOTORS 1
#endif

#ifndef MIN_RPM
#define MIN_RPM 100
#endif

#ifndef MAX_RPM
#define MAX_RPM 3000
#endif

/* Manages the display, buttons and shared ports. */
void display_shared_io_manager( chanend c_speed[], REFERENCE_PARAM(lcd_interface_t, p), in port btns, out port leds )
{
	unsigned int time, MIN_VAL=0, speed[2], set_speed = 1000;
	unsigned int btn_en = 0;
	unsigned toggle = 1,  value;
	char my_string[50];
	unsigned ts,temp=0;
	timer timer_1,timer_2;

	leds <: 0;

	/* Initiate the LCD ports */
	lcd_ports_init(p);

	/* Output the default value to the port */
	p.p_core1_shared <:0;

	/* Get the initial time value */
	timer_1 :> time;

	/* Loop forever processing commands */
	while (1)
	{
		select
		{
		/* Timer event at 10Hz */
			case timer_1 when timerafter(time + 10000000) :> time:
			{
				unsigned new_speed[2], new_set_speed, oc_fault[2], uv_fault[2];

				/* Get the motor 1 speed and motor 2 speed */
				for (int m=0; m<NUMBER_OF_MOTORS; m++) {
					c_speed[m] <: CMD_GET_IQ;
					c_speed[m] :> new_speed[m];
					c_speed[m] :> new_set_speed;

					c_speed[m] <: CMD_GET_FAULT;
					c_speed[m] :> oc_fault[m];
					c_speed[m] :> uv_fault[m];
				}

				if (new_speed[0] != speed[0] || new_speed[1] != speed[1] || new_set_speed != set_speed) {
					speed[0] = new_speed[0];
					speed[1] = new_speed[1];
					set_speed = new_set_speed;

					/* Calculate the strings here */
					/* Now update the display */
#ifdef USE_CAN
					lcd_draw_text_row( "  XMOS Demo 2011: CAN\n", 0, p );
#endif
#ifdef USE_ETH
					lcd_draw_text_row( "  XMOS Demo 2011: ETH\n", 0, p );
#endif
					sprintf(my_string, "  Set Speed: %04d RPM\n", set_speed );
					lcd_draw_text_row( my_string, 1, p );

					if (oc_fault[0]) {
						sprintf(my_string, "  Motor 1: FAULT" );
					} else {
						sprintf(my_string, "  Speed1: %04d RPM%c\n", speed[0], (uv_fault[0]?'*':' ') );
					}
					lcd_draw_text_row( my_string, 2, p );

					if (oc_fault[1]) {
						sprintf(my_string, "  Motor 2: FAULT" );
					} else {
						sprintf(my_string, "  Speed2: %04d RPM%c\n", speed[1], (uv_fault[1]?'*':' ') );
					}
					lcd_draw_text_row( my_string, 3, p );
				}

				/* Switch debouncing - run through and decrement debouncer */
				if ( btn_en > 0)
					btn_en--;
			}
			break;

			case !btn_en => btns when pinsneq(value) :> value:
				value = (~value & 0x0000000F);

				if (value == 0) {
					leds <: 0;
				}
				else if(value == 1)
				{
					leds <: 1;

					/* Increase the speed, by the increment */
					set_speed += 100;
					if (set_speed > MAX_RPM)
						set_speed = MAX_RPM;

					/* Update the speed control loop */
					for (int m=0; m<NUMBER_OF_MOTORS; m++) {
						c_speed[m] <: CMD_SET_SPEED;
						c_speed[m] <: set_speed;
					}

					/* Increment the debouncer */
					btn_en = 2;
				}

				else if(value == 2)
				{
					leds <: 2;

					set_speed -= 100;
					/* Limit the speed to the minimum value */
					if (set_speed < MIN_RPM)
					{
						set_speed = MIN_RPM;
						MIN_VAL = set_speed;
					}
					/* Update the speed control loop */
					for (int m=0; m<NUMBER_OF_MOTORS; m++) {
						c_speed[m] <: CMD_SET_SPEED;
						c_speed[m] <: set_speed;
					}

					/* Increment the debouncer */
					btn_en = 2;
				}

				else if(value == 8)
				{
					leds <: 4;

					toggle = !toggle;
					temp = set_speed;
					/* to avoid jerks during the direction change*/
					while(set_speed > MIN_RPM)
					{
						set_speed -= STEP_SPEED;
						/* Update the speed control loop */
						for (int m=0; m<NUMBER_OF_MOTORS; m++) {
							c_speed[m] <: CMD_SET_SPEED;
							c_speed[m] <: set_speed;
						}
						timer_2 :> ts;
						timer_2 when timerafter(ts + _30_Msec) :> ts;
					}
					set_speed  =0;
					/* Update the speed control loop */
					for (int m=0; m<NUMBER_OF_MOTORS; m++) {
						c_speed[m] <: CMD_SET_SPEED;
						c_speed[m] <: set_speed;
					}
					/* Update the direction change */
					for (int m=0; m<NUMBER_OF_MOTORS; m++) {
						c_speed[m] <: CMD_DIR;
						c_speed[m] <: toggle;

					}

					/* to avoid jerks during the direction change*/
					while(set_speed < temp)
					{
						set_speed += STEP_SPEED;
						for (int m=0; m<NUMBER_OF_MOTORS; m++) {
							c_speed[m] <: CMD_SET_SPEED;
							c_speed[m] <: set_speed;
						}

						timer_2 :> ts;
						timer_2 when timerafter(ts + _30_Msec) :> ts;
					}
					set_speed  = temp;
					/* Update the speed control loop */
					for (int m=0; m<NUMBER_OF_MOTORS; m++) {
						c_speed[m] <: CMD_SET_SPEED;
						c_speed[m] <: set_speed;
					}

					/* Increment the debouncer */
					btn_en = 2;
				}
			break;

			default:
			break;
		}
	}
}

