  /**
 * Module:  app_dsc_demo
 * Version: 1v0alpha1
 * Build:   dcbd8f9dde72e43ef93c00d47bed86a114e0d6ac
 * File:    main.xc
 * Modified by : A Srikanth
 * Last Modified on : 06-Jul-2011
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

#include "CanPhy.h"
#include "adc_7265.h"
#include "control_comms_can.h"
#include "control_comms_eth.h"
#include "dsc_config.h"
#include "ethernet_server.h"
#include "getmac.h"
#include "hall_input.h"
#include "inner_loop.h"
#include "pos_estimator.h"
#include "pwm_cli.h"
#include "pwm_service.h"
#include "shared_io.h"
#include "uip_server.h"
#include "watchdog.h"
#include "xtcp_client.h"
#include "qei_server.h"

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
on stdcore[MOTOR_CORE]: port in p_qei1 = PORT_M1_ENCODER;

// Motor 2 ports
on stdcore[MOTOR_CORE]: port in p_hall2 = PORT_M2_HALLSENSOR;
on stdcore[MOTOR_CORE]: buffered out port:32 p_pwm_hi2[3] = {PORT_M2_HI_A, PORT_M2_HI_B, PORT_M2_HI_C};
on stdcore[MOTOR_CORE]: buffered out port:32 p_pwm_lo2[3] = {PORT_M2_LO_A, PORT_M2_LO_B, PORT_M2_LO_C};
on stdcore[MOTOR_CORE]: clock pwm_clk2 = XS1_CLKBLK_4;
on stdcore[MOTOR_CORE]: port in p_qei2 = PORT_M2_ENCODER;

// Watchdog port
on stdcore[INTERFACE_CORE]: out port i2c_wd = PORT_WATCHDOG;

on stdcore[MOTOR_CORE]: out port ADC_SCLK = PORT_ADC_CLK;
on stdcore[MOTOR_CORE]: out port ADC_CNVST = PORT_ADC_CONV;
on stdcore[MOTOR_CORE]: buffered in port:32 ADC_DATA_A = PORT_ADC_MISOA;
on stdcore[MOTOR_CORE]: buffered in port:32 ADC_DATA_B = PORT_ADC_MISOB;
on stdcore[MOTOR_CORE]: out port ADC_MUX = PORT_ADC_MUX;
on stdcore[MOTOR_CORE]: in port ADC_SYNC_PORT1 = XS1_PORT_16A;
on stdcore[MOTOR_CORE]: in port ADC_SYNC_PORT2 = XS1_PORT_16B;
on stdcore[MOTOR_CORE]: clock adc_clk = XS1_CLKBLK_2;


// Function to initise and run the TCP/IP server
void init_tcp_server(chanend c_mac_rx, chanend c_mac_tx, chanend c_xtcp[], chanend c_connect_status)
{
	#if USE_DHCP
		xtcp_ipconfig_t ipconfig =
		{
		  {0,0,0,0},		// ip address
		  {0,0,0,0},		// netmask
		  {0,0,0,0}       	// gateway
		};

		printstr("Using Dynamic IP config\n");
	#else
		xtcp_ipconfig_t ipconfig =
		{
		  {169, 254,0,1},	// ip address
		  {255,255,0,0},	// netmask
		  {0,0,0,0}       	// gateway
		};

		printstr("Using Static IP config\n");
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

// Program Entry Point
int main ( void )
{
	chan c_wd, c_speed[2], c_commands[2];
	chan c_qei[2], c_pwm[2], c_adc[2], c_adc_trig[2];

#ifdef USE_CAN
	chan c_rxChan, c_txChan, c_can_command;
#endif
#ifdef USE_ETH
	chan c_mac_rx[1], c_mac_tx[1], c_xtcp[1], c_connect_status;
#endif


	par
	{
		// Xcore 0 - INTERFACE_CORE
#ifdef USE_CAN
		on stdcore[INTERFACE_CORE] : do_comms_can( c_commands, c_rxChan, c_txChan, c_can_reset);
		on stdcore[INTERFACE_CORE] : canPhyRxTx( c_rxChan, c_txChan, p_can_clk, p_can_rx, p_can_tx );
#endif

#ifdef USE_ETH
		on stdcore[MOTOR_CORE] : init_tcp_server( c_mac_rx[0], c_mac_tx[0], c_xtcp, c_connect_status );
		on stdcore[INTERFACE_CORE] : do_comms_eth( c_commands, c_xtcp[0] );
		on stdcore[INTERFACE_CORE]: init_ethernet_server(otp_data, otp_addr, otp_ctrl, clk_smi, clk_mii_ref, smi, mii, c_mac_rx, c_mac_tx, c_connect_status, p_shared_rs);
#endif

		on stdcore[INTERFACE_CORE] : do_wd( c_wd, i2c_wd );
		on stdcore[INTERFACE_CORE] : display_shared_io_manager( c_speed, lcd_ports, p_btns, p_leds);


		// Xcore 1 - MOTOR_CORE
		on stdcore[MOTOR_CORE] : run_motor( c_pwm[0], c_qei[0], c_adc[0], c_speed[0], c_wd, p_hall1, c_commands[0]);
		on stdcore[MOTOR_CORE] : do_pwm( c_pwm[0], c_adc_trig[0], ADC_SYNC_PORT1, p_pwm_hi1, p_pwm_lo1, pwm_clk1 );
		on stdcore[MOTOR_CORE] : do_qei ( c_qei[0], p_qei1 );

//		on stdcore[MOTOR_CORE] : run_motor( c_pwm[1], c_qei[1], c_adc[1], c_speed[1], null, p_hall2, c_commands[1]);
//		on stdcore[MOTOR_CORE] : do_pwm( c_pwm[1], c_adc_trig[1], ADC_SYNC_PORT2, p_pwm_hi2, p_pwm_lo2, pwm_clk2 );
//		on stdcore[MOTOR_CORE] : do_qei ( c_qei[1], p_qei2 );

		on stdcore[MOTOR_CORE] : adc_7265_triggered( c_adc, c_adc_trig, adc_clk, ADC_SCLK, ADC_CNVST, ADC_DATA_A, ADC_DATA_B, ADC_MUX );
	}

	return 0;
}
