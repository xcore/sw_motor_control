#include <xs1.h>
#include <print.h>
#include "lcd.h"
#include "shared_io.h"
#include "lcd_logo.h"


int test_boot_status ( void );


// Function to test the X-link by looking for ULPI data from the XTAG2
int test_x_link ( in port p_xlink )
{
	unsigned int has_change[4] = { 0, 0, 0, 0 }, c_port_val, l_port_val, time;
	timer t;

	// Enable the pull-downs to prevent the ports floating
	set_port_pull_down(p_xlink);

	// Get the initial values for the ports
	p_xlink :> c_port_val;
	l_port_val = c_port_val;

	// Get the initial timer value
	t :> time;

	// Loop sampling the port until timeout
	while ( 1 )
	{
		select
		{
			// Timeout after 1 second
			case t when timerafter(time + 100000000) :> time :
				printstrln("XMOS LINK: timeout");
				return 0;
				break;

			// Wait for a change of data on the X-Link pins
			case p_xlink when pinsneq(c_port_val) :> c_port_val:

				// Check bit 0
				if ( (c_port_val & 0x1) != (l_port_val & 0x1) )
				{
					has_change[0] = 1;
				}

				// Check bit 1
				if ( (c_port_val & 0x2) != (l_port_val & 0x2) )
				{
					has_change[1] = 1;
				}

				// Check bit 2
				if ( (c_port_val & 0x4) != (l_port_val & 0x4) )
				{
					has_change[2] = 1;
				}

				// Check bit 3
				if ( (c_port_val & 0x8) != (l_port_val & 0x8) )
				{
					has_change[3] = 1;
				}

				// Copy over the current port value to the old port value
				l_port_val = c_port_val;

				// Test if all the bits have changed
				if ( ( has_change[0] == 1 ) && ( has_change[1] == 1 ) && ( has_change[2] == 1 ) && ( has_change[3] == 1 ) )
				{
					return 1;
					//printstrln("changed");
				}

				break;
		}
	}

	return 0;
}


// Manages the display, buttons and shared ports.
void display_shared_io_manager( chanend c_eth, chanend c_can, chanend c_control, REFERENCE_PARAM(lcd_interface_t, p), out port p_leds, in port btns[], in port p_xlink, port p_can_rx, port p_can_tx )
{
	unsigned int	val = 1, time, time2, have_failed = 0, have_passed, my_data[3];
	unsigned int 	is_pressed[3], continue_loop, but_val, shared_val = 0, my_cmd;
	char 			btn_id[4] = {'A','B','C','D'};
	int				temp;
	unsigned int 	eth_command, can_command, gen_cmd;
	unsigned int 	port_val = 0b0010;		// Default port value on device boot
	unsigned int 	btn_en[4] = {0,0,0,0};
	signed int 		iq = 0;
	timer 			t, t2;


	// Initiate the LCD ports
	lcd_ports_init(p);

	// Output the default value to the port
	p.p_core1_shared <: port_val;

	// Initiate the LCD
	lcd_comm_out(p, 0xE2, port_val);		// RESET
	lcd_comm_out(p, 0xA0, port_val);		// RAM->SEG output = normal
	lcd_comm_out(p, 0xAE, port_val);		// Display OFF
	lcd_comm_out(p, 0xC0, port_val);		// COM scan direction = normal
	lcd_comm_out(p, 0xA2, port_val);		// 1/9 bias
	lcd_comm_out(p, 0xC8, port_val);		// Reverse
	lcd_comm_out(p, 0x2F, port_val);		// power control set
	lcd_comm_out(p, 0x20, port_val);		// resistor ratio set
	lcd_comm_out(p, 0x81, port_val);		// Electronic volume command (set contrast)
	lcd_comm_out(p, 0x3F, port_val);		// Electronic volume value (contrast value)
	lcd_clear(port_val, p);					// Clear the display RAM
	lcd_comm_out(p, 0xB0, port_val);		// Reset page and column addresses
	lcd_comm_out(p, 0x10, port_val);		// column address upper 4 bits + 0x10
	lcd_comm_out(p, 0x00, port_val);		// column address lower 4 bits + 0x00

	// Get the initial time value
	t :> time;

	// Loop forever processing commands
	while (1)
	{
		select
		{
			// Timer event at 10Hz
			case t when timerafter(time + 10000000) :> time:

				// Switch debouncing - run through and decrement their counters.
				for  ( int i = 0; i < 2; i ++ )
				{
					if ( btn_en[i] != 0)
					{
						btn_en[i]--;
					}
				}

				break;

			// Get a command from the commander
			case c_control :> my_cmd:

				// Process the commands
				if ( my_cmd == TEST_LED_BUT )
				{
					printstr( "Press the button next to the lit LED\n" );

					have_passed = 1;

					for (int i = 0; i < 4; i++)
					{
						printchar( btn_id[i] );
						p_leds <: 0x1 << i;

						t :> time;

						select
						{
							// Got button press?
							case btns[i] when pinseq(0) :> temp:
								printstr( "\tPASS\n" );
								break;

							// Time out after 5s
							case t when timerafter(time + 500000000) :> time:
								printstr( "\tFAIL\n" );
								have_passed = 0;
								break;
						}
					}

					// Return that we have passed
					c_control <: have_passed;

					// Turn off the LEDs
					p_leds <: 0;
				}
				else if ( my_cmd == TEST_DISPLAY_0 )
				{
					//
					lcd_draw_text_row( "\n", 0, port_val, p );
					lcd_draw_text_row( "\n", 1, port_val, p );
					lcd_draw_text_row( "\n", 2, port_val, p );
					lcd_draw_text_row( "\n", 3, port_val, p );

					c_control <: 1;
				}
				else if ( my_cmd == TEST_DISPLAY_1 )
				{
					//
					lcd_draw_image( all_set, port_val, p );
					c_control <: 1;
				}
				else if ( my_cmd == TEST_DISPLAY_2 )
				{
					//
					lcd_draw_image( xmos_logo, port_val, p );
					c_control <: 1;
				}
				else if ( my_cmd == TEST_MODE_PINS )
				{
					//
					temp = test_boot_status();
					c_control <: temp;
				}
				else if ( my_cmd == TEST_X_LINK )
				{
					//
					temp = test_x_link(p_xlink);
					c_control <: temp;
				}
				else if ( my_cmd == TEST_CAN )
				{
					// Turn the CAN transceiver off
					port_val |= 0b0010;
					port_val &= 0b1110;
					p.p_core1_shared <: port_val;

					// Wait For 1ms
					t :> time;
					t when timerafter (time + 100000) :> time;

					// Set the bus low
					p_can_tx <: 0;

					// Get the bus state
					p_can_rx :> my_data[0];

					// Turn the CAN transceiver on and TERM off.
					port_val &= 0b1101;
					port_val &= 0b1110;
					p.p_core1_shared <: port_val;

					// Wait For 1ms
					t :> time;
					t when timerafter (time + 100000) :> time;

					// Set the bus low
					p_can_tx <: 0;

					// Wait For 1ms
					t :> time;
					t when timerafter (time + 100000) :> time;

					// Get the bus state
					p_can_rx :> my_data[1];

					// Set the bus high
					p_can_tx <: 1;

					// Wait For 1ms
					t :> time;
					t when timerafter (time + 100000) :> time;

					// Get the bus state
					p_can_rx :> my_data[2];

					// Check the test outcomes
					if ( ( my_data[0] == 1 ) && ( my_data[1] == 0 ) && ( my_data[2] == 1 ) )
					{
						c_control <: 1;
					}
					else
					{
						printstrln("CAN Error...");
						printuintln(my_data[0]);
						printuintln(my_data[1]);
						printuintln(my_data[1]);

						c_control <: 0;
					}
				}
				else if ( my_cmd == PRESS_A )
				{
					continue_loop = 1;

					// Loop flashing the LEDs until we have tested all the buttons
					while ( continue_loop )
					{
						// Loop forever writting to the LEDs
						select
						{
							case btns[0] when pinseq(0) :> but_val:

								// Send that we have finished OK
								c_control <: 1;

								// Break the loop
								continue_loop = 0;

								break;
						}
					}
				}
				else if ( my_cmd == PRESS_A_W )
				{
					continue_loop = 1;

					// Get the current time
					t2 :> time2;

					// Loop flashing the LEDs until we have tested all the buttons
					while ( continue_loop )
					{
						// Loop forever writting to the LEDs
						select
						{
							// Timeout after 5 seconds
							case t2 when timerafter (time2 + 500000000) :> time2 :

								// Send that we have failed
								c_control <: 0;

								// Break the loop
								continue_loop = 0;

								break;

							case btns[0] when pinseq(0) :> but_val:

								// Send that we have finished OK
								c_control <: 1;

								// Break the loop
								continue_loop = 0;

								break;
						}
					}
				}
				else
				{
					printstr ( "control_in error!\n" );
				}

				break;

			// Ethernet PHY reset
			case c_eth :> eth_command :

				if ( eth_command == 1 )
				{
					port_val |= 0b0100;
				}
				else // eth_command == 0
				{
					// ETH_RST_LO
					port_val &= 0b1011;
				}

				// Output the value to the shared port
				p.p_core1_shared <: port_val;
				break;

			// CAN driver TERM & RST
			case c_can :> can_command :

				switch (can_command)
				{
					case CAN_TERM_HI :
						port_val |= 0b0001;
						break;

					case CAN_TERM_LO :
						port_val &= 0b1110;
						break;

					case CAN_RST_HI :
						port_val |= 0b0010;
						break;

					case CAN_RST_LO :
						port_val &= 0b1101;
						break;

					default :
						// ERROR
						break;
				}

				// Output the value to the shared port
				p.p_core1_shared <: port_val;
				break;

			// Button A is up
			case !btn_en[0] => btns[0] when pinseq(0) :> void:


				// Increment the debouncer
				btn_en[0] = 4;
				break;

			// Button B is down
			case !btn_en[1] => btns[1] when pinseq(0) :> void:

				// Increment the debouncer
				btn_en[1] = 4;
				break;

			// Button C
			case !btn_en[2] => btns[2] when pinseq(0) :> void:

				// Increment the debouncer
				btn_en[2] = 4;
				break;

			// Button D
			case !btn_en[3] => btns[3] when pinseq(0) :> void:

				// Increment the debouncer
				btn_en[3] = 4;
				break;
		}
	}
}
