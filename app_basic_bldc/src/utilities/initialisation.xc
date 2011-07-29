/**
 * Module:  app_basic_bldc
 * Version: 1v0alpha1
 * Build:   1bf1040d1aaa1b63b4a955dd58d6723c17052f1d
 * File:    initialisation.xc
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

#include <print.h>

#include "ethernet_server.h"
#include "getmac.h"
#include "uip_server.h"

int mac_address[2];

// Function to initialise and run the TCP/IP server
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
		  {169, 254,0,1},	// ip address
		  {255,255,0,0},	// netmask
		  {0,0,0,0}       	// gateway
		};
	#endif

	// Start the TCP/IP server
	uip_server(c_mac_rx, c_mac_tx, c_xtcp, 1, ipconfig, c_connect_status);
}


// Function to initialise and run the Ethernet server
void init_ethernet_server( port p_otp_data, out port p_otp_addr, port p_otp_ctrl, clock clk_smi, clock clk_mii, smi_interface_t &p_smi, mii_interface_t &p_mii, chanend c_mac_rx[], chanend c_mac_tx[], chanend c_connect_status, chanend c_eth_reset)
{
	// Get the MAC address
	ethernet_getmac_otp(p_otp_data, p_otp_addr, p_otp_ctrl, (mac_address, char[]));

	// Initiate the PHY
	phy_init(clk_smi, null, c_eth_reset, p_smi, p_mii);

	// Run the Ethernet server
	ethernet_server(p_mii, mac_address, c_mac_rx, 1, c_mac_tx, 1, p_smi, c_connect_status);
}


