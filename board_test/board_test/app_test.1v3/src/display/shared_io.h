#ifndef SHARED_IO_H_
#define SHARED_IO_H_

	#include <xccompat.h>

	// Individual command interfaces
	#define ETH_RST_HI 		0
	#define ETH_RST_LO		1

	#define CAN_TERM_HI		1
	#define CAN_TERM_LO		2
	#define CAN_RST_HI		4
	#define CAN_RST_LO		8

	// Definitions for commands
	#define TEST_LED_BUT	1
	#define TEST_DISPLAY_0 	2
	#define TEST_DISPLAY_1 	3
	#define TEST_DISPLAY_2 	4
	#define TEST_MODE_PINS	5
	#define TEST_X_LINK		6
	#define TEST_CAN		7
	#define PRESS_A			8
	#define PRESS_A_W		9

	#ifdef __XC__
		typedef struct lcd_interface_t
		{
			//clock clk_lcd_1;
			//clock clk_lcd_2;

			out port p_lcd_sclk; // buffered port:8
			out port p_lcd_mosi; // buffered port:8
			out port p_lcd_cs_n;
			out port p_core1_shared;
		} lcd_interface_t;

		void display_shared_io_manager( chanend c_eth, chanend c_can, chanend c_control, REFERENCE_PARAM(lcd_interface_t, p), out port p_leds, in port btns[], in port p_xlink, port p_can_rx, port p_can_tx );
	#endif

#endif /* SHARED_IO_H_ */
