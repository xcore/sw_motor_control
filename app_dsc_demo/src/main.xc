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
#include <print.h>

#include "adc_7265.h"
#include "dsc_config.h"
#include "hall_input.h"
#include "inner_loop.h"
#include "pos_estimator.h"
#include "pwm_cli_inv.h"
#include "pwm_service_inv.h"
#include "shared_io.h"
#include "watchdog.h"
#include "qei_server.h"

#ifdef USE_ETH
#include "control_comms_eth.h"
#include "ethernet_server.h"
#include "getmac.h"
#include "uip_server.h"
#include "xtcp_client.h"
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
on stdcore[INTERFACE_CORE]: lcd_interface_t lcd_ports = { PORT_SPI_CLK, PORT_SPI_MOSI, PORT_SPI_SS_DISPLAY, PORT_SPI_DSA };
on stdcore[INTERFACE_CORE]: in port p_btns = PORT_BUTTONS;
on stdcore[INTERFACE_CORE]: out port p_leds = PORT_LEDS;

//CAN and ETH reset port
on stdcore[INTERFACE_CORE] : out port p_shared_rs=PORT_SHARED_RS;

#ifdef USE_CAN
	// CAN
	on stdcore[INTERFACE_CORE] : clock p_can_clk = XS1_CLKBLK_4;
	on stdcore[INTERFACE_CORE] : buffered in port:32 p_can_rx = PORT_CAN_RX;
	on stdcore[INTERFACE_CORE] : port p_can_tx = PORT_CAN_TX;

#endif

#ifdef USE_ETH
	// OTP for MAC address
	on stdcore[INTERFACE_CORE]: port otp_data = XS1_PORT_32A; 	// OTP_DATA_PORT
	on stdcore[INTERFACE_CORE]: out port otp_addr = XS1_PORT_16A;	// OTP_ADDR_PORT
	on stdcore[INTERFACE_CORE]: port otp_ctrl = XS1_PORT_16B;	// OTP_CTRL_PORT

	// Ethernet Ports
	on stdcore[INTERFACE_CORE]: clock clk_mii_ref = XS1_CLKBLK_REF;
	on stdcore[INTERFACE_CORE]: clock clk_smi = XS1_CLKBLK_3;
	on stdcore[INTERFACE_CORE]: smi_interface_t smi = { PORT_ETH_MDIO, PORT_ETH_MDC, 0 };
	on stdcore[INTERFACE_CORE]: mii_interface_t mii =
	{
	    XS1_CLKBLK_1, XS1_CLKBLK_2,
	    PORT_ETH_RXCLK, PORT_ETH_RXER, PORT_ETH_RXD, PORT_ETH_RXDV,
	    PORT_ETH_TXCLK, PORT_ETH_TXEN, PORT_ETH_TXD,
	};
#endif

// Motor 1 ports
on stdcore[MOTOR_CORE]: port in p_hall1 = PORT_M1_HALLSENSOR;
on stdcore[MOTOR_CORE]: buffered out port:32 p_pwm_hi1[3] = {PORT_M1_HI_A, PORT_M1_HI_B, PORT_M1_HI_C};
on stdcore[MOTOR_CORE]: buffered out port:32 p_pwm_lo1[3] = {PORT_M1_LO_A, PORT_M1_LO_B, PORT_M1_LO_C};
on stdcore[MOTOR_CORE]: clock pwm_clk1 = XS1_CLKBLK_REF;

// Motor 2 ports
on stdcore[MOTOR_CORE]: port in p_hall2 = PORT_M2_HALLSENSOR;
on stdcore[MOTOR_CORE]: buffered out port:32 p_pwm_hi2[3] = {PORT_M2_HI_A, PORT_M2_HI_B, PORT_M2_HI_C};
on stdcore[MOTOR_CORE]: buffered out port:32 p_pwm_lo2[3] = {PORT_M2_LO_A, PORT_M2_LO_B, PORT_M2_LO_C};
on stdcore[MOTOR_CORE]: clock pwm_clk2 = XS1_CLKBLK_4;

// QEI ports
on stdcore[MOTOR_CORE]: port in p_qei[2] = { PORT_M1_ENCODER, PORT_M2_ENCODER };

// Watchdog port
on stdcore[INTERFACE_CORE]: out port i2c_wd = PORT_WATCHDOG;

on stdcore[MOTOR_CORE]: out port ADC_SCLK = PORT_ADC_CLK;
on stdcore[MOTOR_CORE]: port ADC_CNVST = PORT_ADC_CONV;
on stdcore[MOTOR_CORE]: buffered in port:32 ADC_DATA_A = PORT_ADC_MISOA;
on stdcore[MOTOR_CORE]: buffered in port:32 ADC_DATA_B = PORT_ADC_MISOB;
on stdcore[MOTOR_CORE]: out port ADC_MUX = PORT_ADC_MUX;
on stdcore[MOTOR_CORE]: in port ADC_SYNC_PORT1 = XS1_PORT_16A;
on stdcore[MOTOR_CORE]: in port ADC_SYNC_PORT2 = XS1_PORT_16B;
on stdcore[MOTOR_CORE]: clock adc_clk = XS1_CLKBLK_2;

#ifdef USE_ETH

// Function to initise and run the TCP/IP server
void init_tcp_server(chanend c_mac_rx, chanend c_mac_tx, chanend c_xtcp[], chanend c_connect_status)
{
#if 0
	xtcp_ipconfig_t ipconfig =
	{
	  {0,0,0,0},		// ip address
	  {0,0,0,0},		// netmask
	  {0,0,0,0}       	// gateway
	};
#else
	xtcp_ipconfig_t ipconfig =
	{
	  {192, 168, 0, 1},	// ip address
	  {255,255,0,0},	// netmask
	  {0,0,0,0}       	// gateway
	};
#endif

	// Start the TCP/IP server
	uip_server(c_mac_rx, c_mac_tx, c_xtcp, 1, ipconfig, c_connect_status);
}


// Function to initise and run the Ethernet server
void init_ethernet_server( port p_otp_data, out port p_otp_addr, port p_otp_ctrl, clock clk_smi, clock clk_mii, smi_interface_t &p_smi, mii_interface_t &p_mii, chanend c_mac_rx[], chanend c_mac_tx[], chanend c_connect_status, out port p_reset )
{
		int mac_address[2];

		// Bring the ethernet PHY out of reset
		p_reset <: 0x2;

		// Get the MAC address
		ethernet_getmac_otp(p_otp_data, p_otp_addr, p_otp_ctrl, (mac_address, char[]));

		// Initiate the PHY
		phy_init(clk_smi, null, p_smi, p_mii);

		// Run the Ethernet server
		ethernet_server(p_mii, mac_address, c_mac_rx, 1, c_mac_tx, 1, p_smi, c_connect_status);
}
#endif


#ifdef USE_CAN
void init_can_phy( chanend c_rxChan, chanend c_txChan, clock p_can_clk, buffered in port:32 p_can_rx, port p_can_tx, out port p_shared_rs)
{
	p_shared_rs <: 0;

	canPhyRxTx( c_rxChan, c_txChan, p_can_clk, p_can_rx, p_can_tx );
}
#endif

// Program Entry Point
int main ( void )
{
	chan c_wd, c_speed[NUMBER_OF_MOTORS], c_commands[NUMBER_OF_MOTORS];
	chan c_pwm[NUMBER_OF_MOTORS];
	streaming chan c_adc[NUMBER_OF_MOTORS];
	chan c_adc_trig[NUMBER_OF_MOTORS], c_motor_comms;
	streaming chan c_qei[NUMBER_OF_MOTORS];

#ifdef USE_CAN
	chan c_rxChan, c_txChan;
#endif
#ifdef USE_ETH
	chan c_mac_rx[1], c_mac_tx[1], c_xtcp[1], c_connect_status;
#endif

	par
	{
		// Xcore 0 - INTERFACE_CORE
#ifdef USE_CAN
		on stdcore[INTERFACE_CORE] : do_comms_can( c_commands, c_rxChan, c_txChan);
		on stdcore[INTERFACE_CORE] : init_can_phy( c_rxChan, c_txChan, p_can_clk, p_can_rx, p_can_tx, p_shared_rs );
#endif

#ifdef USE_ETH
		on stdcore[INTERFACE_CORE] : init_tcp_server( c_mac_rx[0], c_mac_tx[0], c_xtcp, c_connect_status );
		on stdcore[INTERFACE_CORE]: init_ethernet_server(otp_data, otp_addr, otp_ctrl, clk_smi, clk_mii_ref, smi, mii, c_mac_rx, c_mac_tx, c_connect_status, p_shared_rs);
		on stdcore[MOTOR_CORE] : do_comms_eth( c_commands, c_xtcp[0] );
#endif

		on stdcore[INTERFACE_CORE] : do_wd( c_wd, i2c_wd );
		on stdcore[INTERFACE_CORE] : display_shared_io_manager( c_speed, lcd_ports, p_btns, p_leds);


		// Xcore 1 - MOTOR_CORE
		on stdcore[MOTOR_CORE] : {
#ifdef USE_XSCOPE
			xscope_register(6,
					XSCOPE_CONTINUOUS, "speed", XSCOPE_INT , "n",
					XSCOPE_CONTINUOUS, "iq", XSCOPE_INT , "n",
					XSCOPE_CONTINUOUS, "va", XSCOPE_INT , "n",
					XSCOPE_CONTINUOUS, "vb", XSCOPE_INT , "n",
					XSCOPE_CONTINUOUS, "ia", XSCOPE_INT , "n",
					XSCOPE_CONTINUOUS, "ib", XSCOPE_INT , "n"
//					XSCOPE_CONTINUOUS, "Set Speed", XSCOPE_UINT , "n",
//					XSCOPE_CONTINUOUS, "Theta", XSCOPE_UINT , "n"
//					XSCOPE_CONTINUOUS, "PWM[0]", XSCOPE_UINT , "n"
			);
#endif
			run_motor( null, c_motor_comms, c_pwm[0], c_qei[0], c_adc[0], c_speed[0], c_wd, p_hall1, c_commands[0]);
		}

		on stdcore[MOTOR_CORE] : do_pwm_inv_triggered( c_pwm[0], c_adc_trig[0], ADC_SYNC_PORT1, p_pwm_hi1, p_pwm_lo1, pwm_clk1 );

#if NUMBER_OF_MOTORS > 1
		on stdcore[MOTOR_CORE] : run_motor( c_motor_comms, null, c_pwm[1], c_qei[1], c_adc[1], c_speed[1], null, p_hall2, c_commands[1]);
		on stdcore[MOTOR_CORE] : do_pwm_inv_triggered( c_pwm[1], c_adc_trig[1], ADC_SYNC_PORT2, p_pwm_hi2, p_pwm_lo2, pwm_clk2 );

#ifdef USE_SEPARATE_QEI_THREADS
		on stdcore[MOTOR_CORE] : do_qei ( c_qei[0], p_qei[0] );
		on stdcore[MOTOR_CORE] : do_qei ( c_qei[1], p_qei[1] );
#else
		on stdcore[MOTOR_CORE] : do_multiple_qei( c_qei, p_qei );
#endif

#else
		on stdcore[MOTOR_CORE] : do_qei ( c_qei[0], p_qei[0] );
#endif

		on stdcore[MOTOR_CORE] : adc_7265_triggered( c_adc, c_adc_trig, adc_clk, ADC_SCLK, ADC_CNVST, ADC_DATA_A, ADC_DATA_B, ADC_MUX );
	}

	return 0;
}
