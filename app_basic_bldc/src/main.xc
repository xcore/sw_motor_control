/**
 * Module:  app_basic_bldc
 * Version: 1v1
 * Build:
 * File:    main.xc
 * Author: 	L & T
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
#include <stdio.h>

#include "dsc_config.h"
#include "hall_input.h"
#include "pwm_cli_simple.h"
#include "pwm_service_simple.h"
#include "run_motor.h"
#include "watchdog.h"
#include "shared_io.h"
#include "speed_cntrl.h"

// Ethernet control headers
#ifdef USE_ETH
#include "xtcp.h"
#include "ethernet_board_support.h"
#include "control_comms_eth.h"
#endif

// CAN control headers
#ifdef USE_CAN
#include "control_comms_can.h"
#include "CanPhy.h"
#endif

#ifdef USE_XSCOPE
#include <xscope.h>
#endif

// Define where everything is
#define INTERFACE_CORE 0
#define MOTOR_CORE 1

/* core with LCD and BUTTON interfaces */
on tile[INTERFACE_CORE]: lcd_interface_t lcd_ports = { PORT_SPI_CLK, PORT_SPI_MOSI, PORT_SPI_SS_DISPLAY, PORT_SPI_DSA };
on tile[INTERFACE_CORE]: in port p_btns = PORT_BUTTONS;
on tile[INTERFACE_CORE]: out port p_leds = PORT_LEDS;

/* motor1 core ports */
on tile[MOTOR_CORE]: port in p_hall1 = PORT_M1_HALLSENSOR;
on tile[MOTOR_CORE]: buffered out port:32 p_pwm_hi1[3] = {PORT_M1_HI_A, PORT_M1_HI_B, PORT_M1_HI_C};
on tile[MOTOR_CORE]: out port p_motor_lo1[3] = {PORT_M1_LO_A, PORT_M1_LO_B, PORT_M1_LO_C};
on tile[INTERFACE_CORE]: out port i2c_wd = PORT_WATCHDOG;
on tile[MOTOR_CORE]: clock pwm_clk = XS1_CLKBLK_1;

/* motor2 core ports */
on tile[MOTOR_CORE]: port in p_hall2 = PORT_M2_HALLSENSOR;
on tile[MOTOR_CORE]: buffered out port:32 p_pwm_hi2[3] = {PORT_M2_HI_A, PORT_M2_HI_B, PORT_M2_HI_C};
on tile[MOTOR_CORE]: out port p_motor_lo2[3] = {PORT_M2_LO_A, PORT_M2_LO_B, PORT_M2_LO_C};
on tile[MOTOR_CORE]: clock pwm_clk2 = XS1_CLKBLK_4;

//CAN and ETH reset port
on tile[INTERFACE_CORE] : out port p_shared_rs=PORT_SHARED_RS;

#ifdef USE_ETH
	// These intializers are taken from the ethernet_board_support.h header for
	// XMOS dev boards. If you are using a different board you will need to
	// supply explicit port structure intializers for these values
	ethernet_xtcp_ports_t xtcp_ports =
  {	on ETHERNET_DEFAULT_TILE: OTP_PORTS_INITIALIZER,
   														ETHERNET_DEFAULT_SMI_INIT,
   														ETHERNET_DEFAULT_MII_INIT_lite,
   														ETHERNET_DEFAULT_RESET_INTERFACE_INIT
	};

#if 1
	// IP Config - change this to suit your network.  Leave with all 0 values to use DHCP/AutoIP
	xtcp_ipconfig_t ipconfig = 
	{	{ 0, 0, 0, 0 }, // ip address (eg 192,168,0,2)
		{ 0, 0, 0, 0 }, // netmask (eg 255,255,255,0)
		{ 0, 0, 0, 0 } // gateway (eg 192,168,0,1)
	};
#else // #if
	xtcp_ipconfig_t ipconfig =
	{
	  {169, 254, 0, 1},	// ip address
	  {255,255,0,0},	// netmask
	  {0,0,0,0}       	// gateway
	};
#endif // else !#if
#endif // #ifdef USE_ETH

#ifdef USE_CAN
	// CAN
	on tile[INTERFACE_CORE] : clock p_can_clk = XS1_CLKBLK_4;
	on tile[INTERFACE_CORE] : buffered in port:32 p_can_rx = PORT_CAN_RX;
	on tile[INTERFACE_CORE] : port p_can_tx = PORT_CAN_TX;

/*****************************************************************************/
void init_can_phy( chanend c_rxChan, chanend c_txChan, clock p_can_clk, buffered in port:32 p_can_rx, port p_can_tx, out port p_shared_rs)
{
	p_shared_rs <: 0;

	canPhyRxTx( c_rxChan, c_txChan, p_can_clk, p_can_rx, p_can_tx );
} // init_can_phy 
#endif
/*****************************************************************************/
int main ( void )
{
	chan c_wd, c_commands[NUMBER_OF_MOTORS], c_speed[NUMBER_OF_MOTORS], c_control[NUMBER_OF_MOTORS], c_pwm[NUMBER_OF_MOTORS];

#ifdef USE_ETH
	chan c_ethernet[1];
#endif

#ifdef USE_CAN
	chan c_rxChan, c_txChan;
#endif

	par
	{
#ifdef USE_ETH
		on ETHERNET_DEFAULT_TILE: ethernet_xtcp_server( xtcp_ports ,ipconfig ,c_ethernet ,1 ); // The Ethernet & TCP/IP server core(thread)
		on tile[MOTOR_CORE] : do_comms_eth( c_commands, c_ethernet[0] ); // core(thread) to extract Motor commands from ethernet commands
#endif

#ifdef USE_CAN
		on tile[INTERFACE_CORE] : do_comms_can( c_commands, c_rxChan, c_txChan);
		on tile[INTERFACE_CORE] : init_can_phy( c_rxChan, c_txChan, p_can_clk, p_can_rx, p_can_tx, p_shared_rs );
#endif

		/* L2 */
		on tile[INTERFACE_CORE]: do_wd(c_wd, i2c_wd);

		on tile[INTERFACE_CORE] : display_shared_io_manager( c_speed, lcd_ports, p_btns, p_leds);

		on tile[MOTOR_CORE]: speed_control( c_control[0], c_speed[0], c_commands[0]);
		on tile[MOTOR_CORE]: run_motor(c_pwm[0], c_control[0], p_hall1, p_motor_lo1, c_wd );
		on tile[MOTOR_CORE]: do_pwm_simple(c_pwm[0], p_pwm_hi1, pwm_clk);

		on tile[MOTOR_CORE]: speed_control( c_control[1], c_speed[1], c_commands[1]);
		on tile[MOTOR_CORE]: run_motor(c_pwm[1], c_control[1], p_hall2, p_motor_lo2, null );
		on tile[MOTOR_CORE]: do_pwm_simple(c_pwm[1], p_pwm_hi2, pwm_clk2);

#ifdef MB
		on tile[INTERFACE_CORE]: {
#ifdef USE_XSCOPE
			xscope_register(5,
					XSCOPE_CONTINUOUS, "PWM 1", XSCOPE_UINT , "n",
					XSCOPE_CONTINUOUS, "PWM 2", XSCOPE_UINT , "n",
					XSCOPE_CONTINUOUS, "Speed 1", XSCOPE_UINT , "rpm",
					XSCOPE_CONTINUOUS, "Speed 2", XSCOPE_UINT , "rpm",
					XSCOPE_CONTINUOUS, "Set Speed", XSCOPE_UINT, "rpm"
			);
#endif
			display_shared_io_manager( c_speed, lcd_ports, p_btns, p_leds);
		}

		/* L1 */
		on tile[MOTOR_CORE]: do_pwm_simple(c_pwm[0], p_pwm_hi1, pwm_clk);
		on tile[MOTOR_CORE]: run_motor(c_pwm[0], c_control[0], p_hall1, p_motor_lo1, c_wd );
		on tile[MOTOR_CORE]: do_pwm_simple(c_pwm[1], p_pwm_hi2, pwm_clk2);
		on tile[MOTOR_CORE]: run_motor(c_pwm[1], c_control[1], p_hall2, p_motor_lo2, null );
#endif //MB~

	} // par
	return 0;
} // main
/*****************************************************************************/
// main.xc
