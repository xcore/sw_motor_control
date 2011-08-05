/**
 * Module:  module_dsc_display
 * Version: 1v0module_dsc_display3
 * File:    shared_io.xc
 * Modified by : A Srikanth
 * Last Modified on : 05-Aug-2011
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
#include "dsc_config.h"
#include "lcd.h"
#include "shared_io.h"
#include "stdio.h"
#include "lcd_logo.h"
#include "print.h"

#ifndef DISPLAY
#define	DISPLAY

void splash(REFERENCE_PARAM(lcd_interface_t, p), unsigned int port_val )
{
	timer t;
	unsigned ts;

	lcd_draw_image(xmos_logo, port_val, p);
	t :> ts;
	t when timerafter(ts+500000000) :> ts;
	lcd_clear(port_val, p);					/* Clear the display RAM */
	lcd_comm_out(p, 0xB0, port_val);		/* Reset page and column addresses */
	lcd_comm_out(p, 0x10, port_val);		/* column address upper 4 bits + 0x10 */
	lcd_comm_out(p, 0x00, port_val);		/* column address lower 4 bits + 0x00 */
}

/* Manages the display, buttons and shared ports. */
void display_shared_io_motor( chanend c_lcd1, chanend c_lcd2, REFERENCE_PARAM(lcd_interface_t, p), in port btns,chanend c_can_command,out port p_shared_rs,chanend c_eth_command,chanend c_gui_en )
{
	unsigned int time, MIN_VAL=0, speed1 = 0, speed2 = 0, set_speed = INITIAL_SET_SPEED;
	/* Default port value on device boot */
	unsigned int port_val = 0b0010;
	unsigned int btn_en = 0;
	unsigned toggle = 1,  value;
	char my_string[50];
	unsigned ts,temp=0;
	timer timer_1,timer_2;
	unsigned can_command,eth_command;
	unsigned ref_speed_flag=0,cmd;

	/* Initiate the LCD ports */
	lcd_ports_init(p);

	/* Output the default value to the port */
	p.p_core1_shared <:0;

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

	splash(p, port_val );

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
				c_lcd1 <: CMD_GET_IQ;
				c_lcd1 :> speed1;
				c_lcd1 :> set_speed;
#ifdef BLDC_BASIC
				c_lcd2 <: CMD_GET_IQ_2;
				c_lcd2 :> speed2;
#endif

  		/* Calculate the strings here */
		/* Now update the display */
#ifdef USE_CAN
				lcd_draw_text_row( "  XMOS Demo 2011: CAN\n", 0, port_val, p );
#endif
#ifdef USE_ETH
				lcd_draw_text_row( "  XMOS Demo 2011: ETH\n", 0, port_val, p );
#endif
				sprintf(my_string, "  Set Speed: %04d RPM\n", set_speed );
				lcd_draw_text_row( my_string, 1, port_val, p );
#ifdef BLDC_FOC
				sprintf(my_string, "  Speed : 	  %04d RPM\n", speed1 );
				lcd_draw_text_row( my_string, 2, port_val, p );
#endif

#ifdef BLDC_BASIC
				sprintf(my_string, "  Speed1 : 	 %04d RPM\n", speed1 );
				lcd_draw_text_row( my_string, 2, port_val, p );

				sprintf(my_string, "  Speed2 : 	 %04d RPM\n", speed2 );
				lcd_draw_text_row( my_string, 3, port_val, p );
#endif

		/* Switch debouncing - run through and decrement their counters. */
				for  ( int i = 0; i < 3; i ++ )
				{
					if ( btn_en != 0)
						btn_en--;
				}
			    break;

	    /* Enable CAN PHY */
			case c_can_command :> can_command :

					switch (can_command)
					{
					 case CAN_RS_LO :
						    port_val &= 0b1110;
						    p_shared_rs<:port_val;
							break;

					default :
							break;
					 }
            break;

		/* Enable ETHERNET PHY */
		   case c_eth_command :> eth_command :
						switch (eth_command)
						{

						 case 1 :
								port_val |= 0b0010;
								p_shared_rs<:port_val;
								break;

						default :
								break;
						 }
					break;
	   /* Enable or Disable button functionalities based on CAN and ETH command*/
			case c_gui_en:>cmd:
					if(cmd==GUI_ENABLED)
					{
					 c_gui_en:>ref_speed_flag;
					}
						break;
			case !btn_en => btns :> value:
				value = (~value & BUTTON_MASK);
		/* Button A */
				if(value == 1)
				{
					if(ref_speed_flag==0)
					{
		/* Increase the speed, by the increment */
					set_speed += PWM_INC_DEC_VAL;
					if (set_speed > MAX_RPM)
						set_speed = MAX_RPM;
					}
		/* Update the speed control loop */
					c_lcd1 <: CMD_SET_SPEED;
					c_lcd1 <: set_speed;
#ifdef BLDC_BASIC
					c_lcd2 <: CMD_SET_SPEED_2;
					c_lcd2 <: set_speed;
#endif
		/* Increment the debouncer */
					btn_en = 12;
				}

		/* Button B */
				if(value == 2)
				{
					if(ref_speed_flag==0)
					{
					set_speed -= PWM_INC_DEC_VAL;
		/* Limit the speed to the minimum value */
					if (set_speed < MIN_RPM)
					{
						set_speed = MIN_RPM;
						MIN_VAL = set_speed;
					}
					}
		/* Update the speed control loop */
					c_lcd1 <: CMD_SET_SPEED;
					c_lcd1 <: set_speed;
#ifdef BLDC_BASIC
					c_lcd2 <: CMD_SET_SPEED_2;
					c_lcd2 <: set_speed;
#endif
		/* Increment the debouncer */
					btn_en = 12;
				}

#ifdef BLDC_BASIC
		/* Button C */
				if(value == 8)
				{
					toggle = !toggle;
					temp = set_speed;
		/* to avoid jerks during the direction change*/
					while(set_speed > MIN_RPM)
					{
						set_speed -= STEP_SPEED;
		/* Update the speed control loop */
						c_lcd1 <: CMD_SET_SPEED;
						c_lcd1 <: set_speed;
						c_lcd2 <: CMD_SET_SPEED_2;
						c_lcd2 <: set_speed;
						timer_2 :> ts;
						timer_2 when timerafter(ts + MSEC_30) :> ts;
					}
					set_speed  =0;
		/* Update the speed control loop */
					c_lcd1 <: CMD_SET_SPEED;
					c_lcd1 <: set_speed;
					c_lcd2 <: CMD_SET_SPEED_2;
					c_lcd2 <: set_speed;
		/* Update the direction change */
					c_lcd1 <: CMD_DIR;
					c_lcd1 <: toggle;
					c_lcd2 <: CMD_DIR_2;
					c_lcd2 <: toggle;
		/* to avoid jerks during the direction change*/
					while(set_speed < temp)
					{
						set_speed += STEP_SPEED;
						c_lcd1 <: CMD_SET_SPEED;
						c_lcd1 <: set_speed;
						c_lcd2 <: CMD_SET_SPEED_2;
						c_lcd2 <: set_speed;
						timer_2 :> ts;
						timer_2 when timerafter(ts + MSEC_30) :> ts;
					}
					set_speed  = temp;
		/* Update the speed control loop */
					c_lcd1 <: CMD_SET_SPEED;
					c_lcd1 <: set_speed;
					c_lcd2 <: CMD_SET_SPEED_2;
					c_lcd2 <: set_speed;
		/* Increment the debouncer */
					btn_en = 12;
				}
#endif

		/* Button D */
				if(value == 4)
				{
		/* Increment the debouncer */
				btn_en = 12;
				}

			break;

		}
	}
}
#endif /* DISPLAY */
