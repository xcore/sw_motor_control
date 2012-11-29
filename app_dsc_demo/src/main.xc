/**
 *
 * The copyrights, all other intellectual and industrial 
 * property rights are retained by XMOS and/or its licensors. 
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2010
 *
 * In the case where this code is a modification of existing code
 * under a separate license, the separate license terms are shown
 * below. The modifications to the code are still covered by the 
 * copyright notice above.
 *
 **/                                   
#include <xs1.h>
#include <platform.h>

#include "dsc_config.h"
#include "shared_io.h"
#include "watchdog.h"
#include "inner_loop.h"
#include "pwm_service_inv.h"
#include "qei_server.h"
#include "adc_7265.h"

#ifdef USE_ETH
#include "control_comms_eth.h"
#include "ethernet_xtcp_server.h"
#include "ethernet_board_support.h"
#endif

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

// LCD & Button Ports
on tile[INTERFACE_CORE]: lcd_interface_t lcd_ports = { PORT_SPI_CLK, PORT_SPI_MOSI, PORT_SPI_SS_DISPLAY, PORT_SPI_DSA };
on tile[INTERFACE_CORE]: in port p_btns = PORT_BUTTONS;
on tile[INTERFACE_CORE]: out port p_leds = PORT_LEDS;

//CAN and ETH reset port
on tile[INTERFACE_CORE] : out port p_shared_rs=PORT_SHARED_RS;

// Motor 1 ports
on tile[MOTOR_CORE]: port in p_hall1 = PORT_M1_HALLSENSOR;
on tile[MOTOR_CORE]: buffered out port:32 p_pwm_hi1[3] = {PORT_M1_HI_A, PORT_M1_HI_B, PORT_M1_HI_C};
on tile[MOTOR_CORE]: buffered out port:32 p_pwm_lo1[3] = {PORT_M1_LO_A, PORT_M1_LO_B, PORT_M1_LO_C};
on tile[MOTOR_CORE]: clock pwm_clk1 = XS1_CLKBLK_REF;

// Motor 2 ports
on tile[MOTOR_CORE]: port in p_hall2 = PORT_M2_HALLSENSOR;
on tile[MOTOR_CORE]: buffered out port:32 p_pwm_hi2[3] = {PORT_M2_HI_A, PORT_M2_HI_B, PORT_M2_HI_C};
on tile[MOTOR_CORE]: buffered out port:32 p_pwm_lo2[3] = {PORT_M2_LO_A, PORT_M2_LO_B, PORT_M2_LO_C};
on tile[MOTOR_CORE]: clock pwm_clk2 = XS1_CLKBLK_4;

// QEI ports
on tile[MOTOR_CORE]: port in p_qei[2] = { PORT_M1_ENCODER, PORT_M2_ENCODER };

// Watchdog port
on tile[INTERFACE_CORE]: out port i2c_wd = PORT_WATCHDOG;

on tile[MOTOR_CORE]: out port ADC_SCLK = PORT_ADC_CLK;
on tile[MOTOR_CORE]: port ADC_CNVST = PORT_ADC_CONV;
on tile[MOTOR_CORE]: buffered in port:32 ADC_DATA_A = PORT_ADC_MISOA;
on tile[MOTOR_CORE]: buffered in port:32 ADC_DATA_B = PORT_ADC_MISOB;
on tile[MOTOR_CORE]: out port ADC_MUX = PORT_ADC_MUX;
on tile[MOTOR_CORE]: in port ADC_SYNC_PORT1 = XS1_PORT_16A;
on tile[MOTOR_CORE]: in port ADC_SYNC_PORT2 = XS1_PORT_16B;
on tile[MOTOR_CORE]: clock adc_clk = XS1_CLKBLK_2;

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

	// IP Config - change this to suit your network.  Leave with all 0 values to use DHCP/AutoIP
	xtcp_ipconfig_t ipconfig = 
	{	{ 0, 0, 0, 0 }, // ip address (eg 192,168,0,2)
		{ 0, 0, 0, 0 }, // netmask (eg 255,255,255,0)
		{ 0, 0, 0, 0 } // gateway (eg 192,168,0,1)
	};
#endif

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
int main ( void ) // Program Entry Point
{
	chan c_wd;
	chan c_motor_comms;
	chan c_speed[NUMBER_OF_MOTORS];
	chan c_commands[NUMBER_OF_MOTORS];
	chan c_pwm[NUMBER_OF_MOTORS];
	chan c_adc_trig[NUMBER_OF_MOTORS];
	streaming chan c_adc[NUMBER_OF_MOTORS];
	streaming chan c_qei[NUMBER_OF_MOTORS];

#ifdef USE_ETH
	chan c_ethernet[1]; // NB Need to declare an array of 1 element, because ethernet_xtcp_server() expects array reference 
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

		on tile[INTERFACE_CORE] : do_wd( c_wd, i2c_wd );
		on tile[INTERFACE_CORE] : display_shared_io_manager( c_speed, lcd_ports, p_btns, p_leds);

		on tile[MOTOR_CORE] : 
		{
#ifdef USE_XSCOPE
			xscope_register( 6,
					XSCOPE_CONTINUOUS, "speed", XSCOPE_INT , "n",
					XSCOPE_CONTINUOUS, "iq", XSCOPE_INT , "n",
					XSCOPE_CONTINUOUS, "va", XSCOPE_INT , "n",
					XSCOPE_CONTINUOUS, "vb", XSCOPE_INT , "n",
					XSCOPE_CONTINUOUS, "ia", XSCOPE_INT , "n",
					XSCOPE_CONTINUOUS, "ib", XSCOPE_INT , "n"
//					XSCOPE_CONTINUOUS, "Set Speed", XSCOPE_UINT , "n",
//					XSCOPE_CONTINUOUS, "Theta", XSCOPE_UINT , "n"
//					XSCOPE_CONTINUOUS, "PWM[0]", XSCOPE_UINT , "n"
			); // xscope_register 
#endif
			run_motor( null, c_motor_comms, c_pwm[0], c_qei[0], c_adc[0], c_speed[0], c_wd, p_hall1, c_commands[0]);
		} // on tile[MOTOR_CORE]

		on tile[MOTOR_CORE] : do_pwm_inv_triggered( c_pwm[0], c_adc_trig[0], ADC_SYNC_PORT1, p_pwm_hi1, p_pwm_lo1, pwm_clk1 );

#if NUMBER_OF_MOTORS > 1
		on tile[MOTOR_CORE] : run_motor( c_motor_comms, null, c_pwm[1], c_qei[1], c_adc[1], c_speed[1], null, p_hall2, c_commands[1]);
		on tile[MOTOR_CORE] : do_pwm_inv_triggered( c_pwm[1], c_adc_trig[1], ADC_SYNC_PORT2, p_pwm_hi2, p_pwm_lo2, pwm_clk2 );

#ifdef USE_SEPARATE_QEI_THREADS
		on tile[MOTOR_CORE] : do_qei ( c_qei[0], p_qei[0] );
		on tile[MOTOR_CORE] : do_qei ( c_qei[1], p_qei[1] );
#else // #ifdef USE_SEPARATE_QEI_THREADS
		on tile[MOTOR_CORE] : do_multiple_qei( c_qei, p_qei );
#endif // else !#ifdef USE_SEPARATE_QEI_THREADS

#else // #if NUMBER_OF_MOTORS > 1
		on tile[MOTOR_CORE] : do_qei ( c_qei[0], p_qei[0] );
#endif // else !#if NUMBER_OF_MOTORS > 1

		on tile[MOTOR_CORE] : adc_7265_triggered( c_adc, c_adc_trig, adc_clk, ADC_SCLK, ADC_CNVST, ADC_DATA_A, ADC_DATA_B, ADC_MUX );
	} // par

	return 0;
} // main
/*****************************************************************************/
// main.xc
