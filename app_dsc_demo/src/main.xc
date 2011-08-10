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
on stdcore[INTERFACE_CORE]: in port btns = PORT_BUTTONS;

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

// Motor core ports
on stdcore[MOTOR_CORE]: port in p_hall = PORT_M1_HALLSENSOR;
on stdcore[MOTOR_CORE]: buffered out port:32 p_pwm_hi[3] = {PORT_M1_HI_A, PORT_M1_HI_B, PORT_M1_HI_C};
on stdcore[MOTOR_CORE]: buffered out port:32 p_pwm_lo[3] = {PORT_M1_LO_A, PORT_M1_LO_B, PORT_M1_LO_C};
on stdcore[MOTOR_CORE]: clock pwm_clk = XS1_CLKBLK_REF;
on stdcore[MOTOR_CORE]: port in p_qei = PORT_M1_ENCODER;
on stdcore[INTERFACE_CORE]: out port i2c_wd = PORT_WATCHDOG;

on stdcore[MOTOR_CORE]: out port ADC_SCLK = PORT_ADC_CLK;
on stdcore[MOTOR_CORE]: out port ADC_CNVST = PORT_ADC_CONV;
on stdcore[MOTOR_CORE]: buffered in port:32 ADC_DATA_A = PORT_ADC_MISOA;
on stdcore[MOTOR_CORE]: buffered in port:32 ADC_DATA_B = PORT_ADC_MISOB;
on stdcore[MOTOR_CORE]: out port ADC_MUX = PORT_ADC_MUX;
on stdcore[MOTOR_CORE]: in port ADC_SYNC_PORT = XS1_PORT_16A;
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
		  {STATIC_IP_BYTE_0, STATIC_IP_BYTE_1, STATIC_IP_BYTE_2, STATIC_IP_BYTE_3},	// ip address
		  {255,255,0,0},	// netmask
		  {0,0,0,0}       	// gateway
		};

		printstr("Using Static IP config\n");
	#endif

	// Start the TCP/IP server
	uip_server(c_mac_rx, c_mac_tx, c_xtcp, 2, ipconfig, c_connect_status);
}


// Function to initise and run the Ethernet server
void init_ethernet_server( port p_otp_data, out port p_otp_addr, port p_otp_ctrl, clock clk_smi, clock clk_mii, smi_interface_t &p_smi, mii_interface_t &p_mii, chanend c_mac_rx[], chanend c_mac_tx[], chanend c_connect_status, chanend c_eth_shared )
{
		int mac_address[2];

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
	chan c_control, c_eth_shared, c_speed, c_commands_eth,c_commands_can,c_can_reset,c_eth_reset;
	chan c_qei;
#ifdef USE_CAN
	chan c_rxChan, c_txChan,c_can_command ;
#endif
#ifdef USE_ETH
	chan c_sdram, c_logging_data, c_data_read, c_mac_rx[1], c_mac_tx[1], c_xtcp[2], c_connect_status;
#endif
#ifdef USE_MOTOR
	chan c_wd, c_pwm, c_hall, c_adc, c_adc_trig;
#endif

	par
	{
		// Xcore 0 - INTERFACE_CORE
#ifdef USE_CAN
		on stdcore[INTERFACE_CORE] : do_comms_can( c_commands_can, c_rxChan, c_txChan, c_can_reset);
		on stdcore[INTERFACE_CORE] : canPhyRxTx( c_rxChan, c_txChan, p_can_clk, p_can_rx, p_can_tx );
#endif

#ifdef USE_ETH
		//on stdcore[INTERFACE_CORE] : logging_server( c_sdram, c_logging_data, c_data_read );
		//on stdcore[INTERFACE_CORE] : sdram_server( c_sdram, sdram_ports );
		on stdcore[MOTOR_CORE] : init_tcp_server( c_mac_rx[0], c_mac_tx[0], c_xtcp, c_connect_status );
		on stdcore[MOTOR_CORE] : do_comms_eth( c_commands_eth, c_xtcp[1] );
		//on stdcore[INTERFACE_CORE] : do_logging_eth( c_data_read, c_xtcp[0] );
#endif

	
		on stdcore[INTERFACE_CORE] : display_shared_io_manager( c_speed, lcd_ports, btns, c_can_reset, p_shared_rs,c_eth_reset);

#ifdef USE_ETH
		on stdcore[INTERFACE_CORE]: init_ethernet_server(otp_data, otp_addr, otp_ctrl, clk_smi, clk_mii_ref, smi, mii, c_mac_rx, c_mac_tx, c_connect_status, c_eth_shared); // +4 threads
#endif

		// Xcore 1 - MOTOR_CORE
#ifdef USE_MOTOR
		on stdcore[INTERFACE_CORE] : do_wd( c_wd, i2c_wd );
		on stdcore[MOTOR_CORE] : do_pwm( c_pwm, c_adc_trig, ADC_SYNC_PORT, p_pwm_hi, p_pwm_lo, pwm_clk );
#ifdef USE_CAN
		on stdcore[MOTOR_CORE] : run_motor ( c_pwm, c_qei, c_adc, c_speed, c_wd, p_hall,c_commands_can );
#endif
#ifdef USE_ETH
		on stdcore[MOTOR_CORE] : run_motor ( c_pwm, c_qei, c_adc, c_speed, c_wd, p_hall,c_commands_eth);
#endif
		//on stdcore[MOTOR_CORE] : adc_ltc1408_triggered( c_adc, adc_clk, ADC_SCLK, ADC_CNVST, ADC_DATA, c_adc_trig, null, null, null );
		on stdcore[MOTOR_CORE] : adc_7265_triggered( c_adc, c_adc_trig, adc_clk, ADC_SCLK, ADC_CNVST, ADC_DATA_A, ADC_DATA_B, ADC_MUX );
		on stdcore[MOTOR_CORE] : do_qei ( c_qei, p_qei );
#endif
	}

	return 0;
}
