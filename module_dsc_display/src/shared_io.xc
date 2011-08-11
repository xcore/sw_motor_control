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
#include <dsc_config.h>
#include "lcd.h"
#include "shared_io.h"
#include "stdio.h"
#include "lcd_logo.h"
#include "print.h"


#ifdef BLDC_BASIC
/* Manages the display, buttons and shared ports. */
void display_shared_io_manager( chanend c_speed[], REFERENCE_PARAM(lcd_interface_t, p), in port btns,chanend c_can_command,out port p_shared_rs,chanend c_eth_command )
{
	unsigned int time, MIN_VAL=0, speed1 = 0, speed2 = 0, set_speed = INITIAL_SET_SPEED;
	/* Default port value on device boot */
	unsigned int port_val = 0b0001;
	unsigned int btn_en = 0;
	unsigned toggle = 1,  value;
	char my_string[50];
	unsigned ts,temp=0;
	timer timer_1,timer_2;
	unsigned can_command,eth_command;

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
		/* Get the motor 1 speed and motor 2 speed */
			for (int m=0; m<NUMBER_OF_MOTORS; m++) {
				c_speed[m] <: CMD_GET_IQ;
				c_speed[m] :> speed1;
				c_speed[m] :> set_speed;
			}

				//can commands


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

				sprintf(my_string, "  Speed1 : 	 %04d RPM\n", speed1 );
				lcd_draw_text_row( my_string, 2, p );

				sprintf(my_string, "  Speed2 : 	 %04d RPM\n", speed2 );
				lcd_draw_text_row( my_string, 3, p );

		/* Switch debouncing - run through and decrement their counters. */
				for  ( int i = 0; i < 3; i ++ )
				{
					if ( btn_en != 0)
						btn_en--;
				}
			    break;
			 //Enable CAN PHY
			case c_can_command :> can_command :

					switch (can_command)
					{

					 case CAN_RS_LO :
						    port_val &= 0b1110;
						    p_shared_rs<:port_val;
							break;

					default :
						   // ERROR
							break;
					 }

            break;
            //Enable ETHERNET PHY
		   case c_eth_command :> eth_command :

						switch (eth_command)
						{

						 case 1 :
								//port_val &= 0b1101;
								port_val |= 0b0010;
								p_shared_rs<:port_val;
								break;

						default :
							   // ERROR
								break;
						 }
					break;
			case !btn_en => btns :> value:
				value = (~value & 0x0000000F);
				if(value == 1)
				{
		/* Increase the speed, by the increment */
					set_speed += PWM_INC_DEC_VAL;
					if (set_speed > MAX_RPM)
						set_speed = MAX_RPM;

		/* Update the speed control loop */
					for (int m=0; m<NUMBER_OF_MOTORS; m++) {
						c_speed[m] <: CMD_SET_SPEED;
						c_speed[m] <: set_speed;
					}

		/* Increment the debouncer */
					btn_en = 8;
				}
				if(value == 2)
				{
					set_speed -= PWM_INC_DEC_VAL;
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
					btn_en = 8;
				}
				if(value == 8)
				{
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
					btn_en = 8;
				}
			break;

			default:
			break;
		}
	}
}
#endif

#ifdef BLDC_FOC

void display_shared_io_manager( chanend c_speed[], REFERENCE_PARAM(lcd_interface_t, p), in port btns,chanend c_can_command,out port p_shared_rs,chanend c_eth_command)
{
	unsigned int time,  value;
	unsigned int port_val = 0b0010;		// Default port value on device boot
	unsigned int speed = 0, set_speed = INITIAL_SET_SPEED;
	unsigned int btn_en = 0;
	unsigned  can_command,eth_command;

//	int pwm[3] = {0,0,0};

	char my_string[50];
	timer t;

	// Initiate the LCD ports
	lcd_ports_init(p);

	// Output the default value to the port
	p.p_core1_shared <: 0;

	// Get the initial time value
	t :> time;

	// Loop forever processing commands
	while (1)
	{
		select
		{
	// Timer event at 10Hz
			case t when timerafter(time + 10000000) :> time:

	// Get actual speed
				c_speed[0] <: 2;
				c_speed[0] :> speed;
				c_speed[0] :> set_speed;

	// Calculate the strings here

	// Now update the display
				lcd_draw_text_row( "  XMOS DSC Demo 2011\n", 0, p );
#ifdef USE_CAN
				lcd_draw_text_row( "  CAN control\n", 1, p );
#endif
#ifdef USE_ETH
				lcd_draw_text_row( "  ETHERNET control\n", 1, p );
#endif
				sprintf(my_string, "  Set Speed: %04d RPM\n", set_speed );
				lcd_draw_text_row( my_string, 2, p );

				sprintf(my_string, "  Speed:     %04d RPM\n", speed );
				lcd_draw_text_row( my_string, 3, p );

	// Switch debouncing - run through and decrement their counters
				for  ( int i = 0; i < 2; i++ )
				{
					if ( btn_en != 0)
						btn_en--;
				}
			break;
        // Enable CAN PHY
			case c_can_command :> can_command :

				switch (can_command)
				{
				 case CAN_RS_LO :
						port_val &= 0b1110;
						p_shared_rs<:port_val;
						break;

				default :
					   // ERROR
						break;
				 }

						break;
        // Enable ETHERNET PHY
			case c_eth_command :> eth_command :

				switch (eth_command)
				{
				 case 1:
						port_val|= 0b0010;
						p_shared_rs<:port_val;
						break;

				default :
					   // ERROR
						break;
				 }

						break;

			case !btn_en => btns :> value:
				value = (~value & 0x0000000F);
				if(value == 1)
				{
	// Increase the speed, by the increment
					set_speed += PWM_INC_DEC_VAL;

	// Limit the speed to the maximum value
					if (set_speed > MAX_RPM)
					{
						set_speed = MAX_RPM;
					}

	// Update the speed control loop
					for (int m=0; m<NUMBER_OF_MOTORS; m++) {
						c_speed[m] <: CMD_SET_SPEED;
						c_speed[m] <: set_speed;
					}

	// Increment the debouncer
					btn_en = 12;
				}
				if(value == 2)
				{
					set_speed -= PWM_INC_DEC_VAL;

	// Limit the speed to the minimum value
					if (set_speed < MIN_RPM)
					{
						set_speed = MIN_RPM;
					}

	// Update the speed control loop
					for (int m=0; m<NUMBER_OF_MOTORS; m++) {
						c_speed[m] <: CMD_SET_SPEED;
						c_speed[m] <: set_speed;
					}

	// Increment the debouncer
					btn_en = 12;
				}
				if(value == 8)
				{
	// Increment the debouncer
				btn_en = 12;
				}
	// Button D
				if(value == 4)
				{
	// Increment the debouncer
				btn_en = 12;
				}
			break;
		}
	}
}
#endif

