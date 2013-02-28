/**
 * Module:  module_dsc_display
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
#include <assert.h>

#ifdef __dsc_config_h_exists__
#include "dsc_config.h"
#endif

#include "lcd.h"
#include "shared_io.h"

#ifndef NUMBER_OF_MOTORS
#define NUMBER_OF_MOTORS 1
#endif

#ifndef MIN_RPM
#define MIN_RPM 100
#endif

#ifndef MAX_RPM
#define MAX_RPM 3000
#endif

#define ERR_LIM 10 // No. of consecutive button value errors allowed

/*****************************************************************************/
void update_speed_control( // Updates the speed control loop
	chanend c_speed[], // speed channel
	unsigned int cmd_id, // Command identifier
	unsigned int cmd_val // Command value
)
{
	int motor_cnt; // motor counter

	// Loop through motors
	for (motor_cnt=0; motor_cnt<NUMBER_OF_MOTORS; motor_cnt++) 
	{
		c_speed[motor_cnt] <: cmd_id;
		c_speed[motor_cnt] <: cmd_val;
	} // for motor_cnt
} // update_speed_control 
/*****************************************************************************/
void display_shared_io_manager( // Manages the display, buttons and shared ports.
	chanend c_speed[], 
	REFERENCE_PARAM(lcd_interface_t, p), 
	in port btns, 
	out port leds
)
{
	char my_string[50]; // array of display characters
	int new_meas_speed[NUMBER_OF_MOTORS]; // Array containing new measured speeds
	int old_meas_speed[NUMBER_OF_MOTORS]; // Array containing old measured speeds
	int fault[NUMBER_OF_MOTORS]; // Array containing motor fault ids
	int new_req_speed; // new requested speed
	int old_req_speed = 1000; // old requested speed
	int speed_change; // flag set when new speed parameters differ from old
	int cur_speed; // current speed
	unsigned int btn_en = 0; // button debounce counter
	int motor_cnt; // motor counter
	int toggle = 1; // indicates motor spin direction 
	unsigned btns_val; // value that encodes state of buttons
	int err_cnt; // error counter

	timer timer_10Hz; // 10Hz timer
	timer timer_30ms; // 30ms timer
	unsigned int time_10Hz_val; // 10Hz timer value
	unsigned int time_30ms_val; // 30ms timer value


	// Initialise array of old measured speeds
	for (motor_cnt=0; motor_cnt<NUMBER_OF_MOTORS; motor_cnt++)
	{
		old_meas_speed[motor_cnt]=0;
	} // for motor_cnt

	leds <: 0;

	/* Initiate the LCD ports */
	lcd_ports_init(p);

	/* Output the default value to the port */
	p.p_core1_shared <:0;

	/* Get the initial time value */
	timer_10Hz :> time_10Hz_val;

	/* Loop forever processing commands */
	while (1)
	{
		select
		{
		/* Timer event at 10Hz */
			case timer_10Hz when timerafter(time_10Hz_val + 10000000) :> time_10Hz_val:
			{
				/* Get the motor speeds from channels. NB Do this as quickly as possible */
				for (motor_cnt=0; motor_cnt<NUMBER_OF_MOTORS; motor_cnt++) 
				{
					c_speed[motor_cnt] <: CMD_GET_IQ;
					c_speed[motor_cnt] :> new_meas_speed[motor_cnt];
					c_speed[motor_cnt] :> new_req_speed;

					c_speed[motor_cnt] <: CMD_GET_FAULT;
					c_speed[motor_cnt] :> fault[motor_cnt];
				} // for motor_cnt

				// Check for speed change
				if (new_req_speed != old_req_speed)
				{ 
					speed_change = 1; // flag speed change
				} // if (new_req_speed != old_req_speed)
				else
				{ 
					speed_change = 0; // no speed change (so far)

					for (motor_cnt=0; motor_cnt<NUMBER_OF_MOTORS; motor_cnt++) 
					{
						if (new_meas_speed[motor_cnt] != old_meas_speed[motor_cnt])
						{
							speed_change = 1; // flag speed change
							break; // Early loop exit
						} // if (new_meas_speed[motor_cnt] != old_meas_speed[motor_cnt])
					} // for motor_cnt
				} // if (new_req_speed != old_req_speed)

				if (speed_change) 
				{
#ifdef USE_CAN
					lcd_draw_text_row( "  XMOS Demo 2013: CAN\n", 0, p );
#endif
#ifdef USE_ETH
					lcd_draw_text_row( "  XMOS Demo 2013: ETH\n", 0, p );
#endif
					// update old speed parameters ...

					old_req_speed = new_req_speed;
					sprintf(my_string, "  SetVeloc:%5d RPM\n", old_req_speed );
					lcd_draw_text_row( my_string, 1, p );

					for (motor_cnt=0; motor_cnt<NUMBER_OF_MOTORS; motor_cnt++) 
					{
						old_meas_speed[motor_cnt] = (old_meas_speed[motor_cnt] + new_meas_speed[motor_cnt]) >> 1;

						if (fault[motor_cnt]) 
						{
							sprintf(my_string, "  Motor%1d: FAULT = %02d\n" ,(motor_cnt + 1) ,fault[motor_cnt] );
						} 
						else 
						{
							sprintf(my_string, "  Velocty%1d:%5d RPM\n" ,(motor_cnt + 1) ,old_meas_speed[motor_cnt] );
						}

						lcd_draw_text_row( my_string ,(motor_cnt + 2) ,p );
					} // for motor_cnt
				} // if (speed_change)

				if ( btn_en > 0) btn_en--; // decrement switch debouncer
			}
			break; // case timer_10Hz when timerafter(time_10Hz_val + 10000000) :> time_10Hz_val:

			case !btn_en => btns when pinsneq(btns_val) :> btns_val:
				btns_val = (~btns_val & 0x0000000F); // Invert and mask out 4 most LS (active) bits

				// check for button change
				if (btns_val)
				{
					// Decode buttons value
					switch( btns_val )
					{
						case 1 : // Increase the speed, by the increment
							err_cnt = 0; // Valid button value so clear error count
							leds <: 1;
			
							old_req_speed += 100;
							if (old_req_speed > MAX_RPM) old_req_speed = MAX_RPM;
						break; // case 1
	
						case 2 : // Decrease the speed, by the increment
							err_cnt = 0; // Valid button value so clear error count
							leds <: 2;
			
							old_req_speed -= 100;
							/* Limit the speed to the minimum value */
							if (old_req_speed < MIN_RPM)
							{
								old_req_speed = MIN_RPM;
							}
						break; // case 2
	
						case 8 : // Change direction of spin
							err_cnt = 0; // Valid button value so clear error count
							leds <: 4;
			
							toggle = !toggle;
							cur_speed = old_req_speed;
			
							/* to avoid jerks during the direction change*/
							while(cur_speed > MIN_RPM)
							{
								cur_speed -= STEP_SPEED;
			
								update_speed_control( c_speed ,CMD_SET_SPEED ,cur_speed ); // Decrease speed
			
								timer_30ms :> time_30ms_val;
								timer_30ms when timerafter(time_30ms_val + _30_Msec) :> time_30ms_val;
							}
			
							update_speed_control( c_speed ,CMD_SET_SPEED ,0 ); // Set speed to zero
			
							update_speed_control( c_speed ,CMD_DIR ,toggle ); // Change direction
			
							/* to avoid jerks during the direction change*/
							while(cur_speed < old_req_speed )
							{
								cur_speed += STEP_SPEED;
			
								update_speed_control( c_speed ,CMD_SET_SPEED ,cur_speed ); // Increase speed
			
								timer_30ms :> time_30ms_val;
								timer_30ms when timerafter(time_30ms_val + _30_Msec) :> time_30ms_val;
							} // while(old_req_speed < temp)
						break; // case 8
	
				    default: // btns_val unsupported
							assert(err_cnt < ERR_LIM); // Check for persistant error

							err_cnt++; // Increment error count
				    break;
					} // switch( btns_val )

					update_speed_control( c_speed ,CMD_SET_SPEED ,old_req_speed ); // Update the speed control loop
			
					btn_en = 2;	// Set the debouncer
				} // if (btns_val)
				else
				{	// No change
					err_cnt = 0; // Valid button value so clear error count
					leds <: 0;
				} // else !(btns_val)

			break; // case !btn_en => btns when pinsneq(btns_val) :> btns_val:

/* JMB 21-NOV-2012  NOT required: Also improves response to push buttons!-)
 *		default:
 *		break;
 */
		} // select
	} // while (1)
} // display_shared_io_manager
/*****************************************************************************/
// shared_io.sc 

