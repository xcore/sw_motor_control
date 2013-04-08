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
#include "hall_server.h"
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
#define INTERFACE_TILE 0
#define MOTOR_TILE 1

// LCD & Button Ports
on tile[INTERFACE_TILE]: lcd_interface_t lcd_ports = { PORT_SPI_CLK, PORT_SPI_MOSI, PORT_SPI_SS_DISPLAY, PORT_SPI_DSA };
on tile[INTERFACE_TILE]: in port p_btns = PORT_BUTTONS;
on tile[INTERFACE_TILE]: out port p_leds = PORT_LEDS;

//CAN and ETH reset port
on tile[INTERFACE_TILE] : out port p_shared_rs = PORT_SHARED_RS;

// Motor ports
on tile[MOTOR_TILE]: port in p4_hall[NUMBER_OF_MOTORS] = { PORT_M1_HALLSENSOR ,PORT_M2_HALLSENSOR };
on tile[MOTOR_TILE]: clock pwm_clk[NUMBER_OF_MOTORS] = { XS1_CLKBLK_REF ,XS1_CLKBLK_4 };
on tile[MOTOR_TILE]: buffered out port:32 p32_pwm_hi[NUMBER_OF_MOTORS][NUM_ADC_PHASES] 
	= {	{PORT_M1_HI_A, PORT_M1_HI_B, PORT_M1_HI_C} ,{PORT_M2_HI_A, PORT_M2_HI_B, PORT_M2_HI_C} };
on tile[MOTOR_TILE]: buffered out port:32 p32_pwm_lo[NUMBER_OF_MOTORS][NUM_ADC_PHASES] 
	= {	{PORT_M1_LO_A, PORT_M1_LO_B, PORT_M1_LO_C} ,{PORT_M2_LO_A, PORT_M2_LO_B, PORT_M2_LO_C} };

// QEI ports
on tile[MOTOR_TILE]: port in p_qei[NUMBER_OF_MOTORS] = { PORT_M1_ENCODER, PORT_M2_ENCODER };

// Watchdog port
on tile[INTERFACE_TILE]: out port i2c_wd = PORT_WATCHDOG;

// ADC ports
on tile[MOTOR_TILE]: in port p16_adc_sync[NUMBER_OF_MOTORS] = { XS1_PORT_16A ,XS1_PORT_16B }; // NB Dummy port
on tile[MOTOR_TILE]: buffered in port:32 p32_adc_data[NUM_ADC_DATA_PORTS] = { PORT_ADC_MISOA ,PORT_ADC_MISOB }; 
on tile[MOTOR_TILE]: out port p1_adc_sclk = PORT_ADC_CLK; // 1-bit port connecting to external ADC serial clock
on tile[MOTOR_TILE]: port p1_ready = PORT_ADC_CONV; // 1-bit port used to as ready signal for p32_adc_data ports and ADC chip
on tile[MOTOR_TILE]: out port p4_adc_mux = PORT_ADC_MUX; // 4-bit port used to control multiplexor on ADC chip
on tile[MOTOR_TILE]: clock adc_xclk = XS1_CLKBLK_2; // Internal XMOS clock

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
	on tile[INTERFACE_TILE] : clock p_can_clk = XS1_CLKBLK_4;
	on tile[INTERFACE_TILE] : buffered in port:32 p_can_rx = PORT_CAN_RX;
	on tile[INTERFACE_TILE] : port p_can_tx = PORT_CAN_TX;

/*****************************************************************************/
void init_can_phy( chanend c_rxChan, chanend c_txChan, clock p_can_clk, buffered in port:32 p_can_rx, port p_can_tx, out port p_shared_rs)
{
	p_shared_rs <: 0;

	canPhyRxTx( c_rxChan, c_txChan, p_can_clk, p_can_rx, p_can_tx );
} // init_can_phy 
#endif

#ifdef USE_XSCOPE
/*****************************************************************************/
void xscope_user_init()
{
	xscope_register( 9
		,XSCOPE_CONTINUOUS, "s_theta", XSCOPE_INT , "n"
		,XSCOPE_CONTINUOUS, "m_theta", XSCOPE_INT , "n"
		,XSCOPE_CONTINUOUS, "m_veloc", XSCOPE_INT , "n"
		,XSCOPE_CONTINUOUS, "set_Vq", XSCOPE_INT , "n"
		,XSCOPE_CONTINUOUS, "pid_vel", XSCOPE_INT , "n"
		,XSCOPE_CONTINUOUS, "req_vel", XSCOPE_INT , "n"
		,XSCOPE_CONTINUOUS, "est_Iq", XSCOPE_INT , "n"
		,XSCOPE_CONTINUOUS, "pid_Iq", XSCOPE_INT , "n"
		,XSCOPE_CONTINUOUS, "targ_Iq", XSCOPE_INT , "n"
/*
		,XSCOPE_CONTINUOUS, "rev_cnt", XSCOPE_INT , "n"
		,XSCOPE_CONTINUOUS, "r_Iq", XSCOPE_INT , "n"
		,XSCOPE_CONTINUOUS, "m_Iq", XSCOPE_INT , "n"
		,XSCOPE_CONTINUOUS, "c_Iq", XSCOPE_INT , "n"
		,XSCOPE_CONTINUOUS, "p_err", XSCOPE_INT , "n"
		,XSCOPE_CONTINUOUS, "s_err", XSCOPE_INT , "n"
		,XSCOPE_CONTINUOUS, "s_err", XSCOPE_INT , "n"
		,XSCOPE_CONTINUOUS, "pwm_A", XSCOPE_INT , "n"
		,XSCOPE_CONTINUOUS, "pwm_B", XSCOPE_INT , "n"
		,XSCOPE_CONTINUOUS, "pwm_C", XSCOPE_INT , "n"

		,XSCOPE_CONTINUOUS, "adc", XSCOPE_INT , "n"
		,XSCOPE_CONTINUOUS, "filt", XSCOPE_INT , "n"
		,XSCOPE_CONTINUOUS, "bits", XSCOPE_INT , "n"
		,XSCOPE_CONTINUOUS, "calib", XSCOPE_INT , "n"
		,XSCOPE_CONTINUOUS, "cnt", XSCOPE_INT , "n"
		XSCOPE_CONTINUOUS, "Set Speed", XSCOPE_UINT , "n"
		XSCOPE_CONTINUOUS, "Theta", XSCOPE_UINT , "n"
		XSCOPE_CONTINUOUS, "PWM[0]", XSCOPE_UINT , "n"
*/
	); // xscope_register 

	xscope_config_io( XSCOPE_IO_BASIC ); // Enable XScope printing
} // xscope_user_init
#endif
/*****************************************************************************/
int main ( void ) // Program Entry Point
{
	chan c_wd;
	chan c_speed[NUMBER_OF_MOTORS];
	chan c_commands[NUMBER_OF_MOTORS];
	chan c_adc_trig[NUMBER_OF_MOTORS];
	chan c_pwm[NUMBER_OF_MOTORS];
	streaming chan c_hall[NUMBER_OF_MOTORS];
	streaming chan c_qei[NUMBER_OF_MOTORS];
	streaming chan c_adc_cntrl[NUMBER_OF_MOTORS];
	streaming chan c_dbg[NUMBER_OF_MOTORS];

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
		on tile[INTERFACE_TILE] : do_comms_eth( c_commands, c_ethernet[0] ); // core(thread) to extract Motor commands from ethernet commands
#endif

#ifdef USE_CAN
		on tile[INTERFACE_TILE] : do_comms_can( c_commands, c_rxChan, c_txChan);
		on tile[INTERFACE_TILE] : init_can_phy( c_rxChan, c_txChan, p_can_clk, p_can_rx, p_can_tx, p_shared_rs );
#endif

		on tile[INTERFACE_TILE] : do_wd( c_wd, i2c_wd );
		on tile[INTERFACE_TILE] : display_shared_io_manager( c_speed, lcd_ports, p_btns, p_leds);

		on tile[MOTOR_TILE] : 
		{
			run_motor( 0 ,c_wd ,c_pwm[0] ,c_hall[0] ,c_qei[0] ,c_adc_cntrl[0] ,c_speed[0] ,c_commands[0] ); // Special case of 1st Motor
		} // on tile[MOTOR_TILE]

		// Loop through remaining motors
		par (int motor_cnt=1; motor_cnt<NUMBER_OF_MOTORS; motor_cnt++)
			on tile[MOTOR_TILE] : run_motor( motor_cnt ,null ,c_pwm[motor_cnt] ,c_hall[motor_cnt] ,c_qei[motor_cnt] 
				,c_adc_cntrl[motor_cnt] ,c_speed[motor_cnt] ,c_commands[motor_cnt] );

		// Loop through all motors
		par (int motor_cnt=0; motor_cnt<NUMBER_OF_MOTORS; motor_cnt++)
		{
			on tile[MOTOR_TILE] : do_pwm_inv_triggered( motor_cnt ,c_pwm[motor_cnt] ,p32_pwm_hi[motor_cnt] ,p32_pwm_lo[motor_cnt] ,c_adc_trig[motor_cnt] ,p16_adc_sync[motor_cnt] ,pwm_clk[motor_cnt] );

#ifdef USE_SEPARATE_QEI_THREADS
			on tile[MOTOR_TILE] : do_qei ( motor_cnt ,c_qei[motor_cnt], p_qei[motor_cnt] );
#endif // #ifdef USE_SEPARATE_QEI_THREADS
		}

#ifndef USE_SEPARATE_QEI_THREADS
		on tile[MOTOR_TILE] : do_multiple_qei( c_qei, p_qei );
#endif // #ifndef USE_SEPARATE_QEI_THREADS

		on tile[MOTOR_TILE] : do_multiple_hall( c_hall ,p4_hall );

		on tile[MOTOR_TILE] : adc_7265_triggered( c_adc_cntrl ,c_adc_trig ,p32_adc_data ,adc_xclk ,p1_adc_sclk ,p1_ready ,p4_adc_mux );
	} // par
	return 0;
} // main
/*****************************************************************************/
// main.xc
