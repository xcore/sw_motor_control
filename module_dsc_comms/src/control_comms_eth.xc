/**
 * Module:  module_dsc_comms
 * Version: 1v0alpha1
 * Build:   73e3f5032a883e9f72779143401b3392bb65d5bb
 * File:    control_comms_eth.xc
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
#include <print.h>
#include "dsc_config.h"

#ifdef USE_ETH
#include "control_comms_eth.h"
#include "ethernet_server.h"
#include "uip_server.h"
#include "xtcp_client.h"
#include "shared_io_motor.h"


// Print out the current IP address
static void print_ip( chanend xtcp )
{
	xtcp_ipconfig_t ip;
	xtcp_get_ipconfig(xtcp, ip);

	printstr( "IP addr: " );
	printuint( ip.ipaddr[0] );
	printchar( '.' );
	printuint( ip.ipaddr[1] );
	printchar( '.' );
	printuint( ip.ipaddr[2] );
	printchar( '.' );
	printuint( ip.ipaddr[3] );
	printchar( '\n' );
}


// Print out the current MAC address
static void print_mac( chanend xtcp )
{
	unsigned char mac[6];
	xtcp_get_mac_address(xtcp, mac);

	printstr( "MAC: " );
	printhex( mac[0] );
	printchar( ':' );
	printhex( mac[1] );
	printchar( ':' );
	printhex( mac[2] );
	printchar( ':' );
	printhex( mac[3] );
	printchar( ':' );
	printhex( mac[4] );
	printchar( ':' );
	printhex( mac[5] );
	printchar( '\n' );
}


// Thread that does the Ethernet control interface
void do_comms_eth( chanend c_speed, chanend tcp_svr )
{
	xtcp_connection_t conn;
	unsigned char tx_buf[512];
	unsigned char rx_buf[512];
	unsigned int speed = 0;
	unsigned int set_speed = 500;
	unsigned int n;

	slave xtcp_event(tcp_svr, conn);
	if (conn.event != XTCP_IFDOWN)
	{
		printstr("Didn't get XTCP_IFDOWN!\n");
	}

	// Print out the MAC and IP addresses to the user
	print_mac( tcp_svr );
	print_ip( tcp_svr );

	// listen on a port
	xtcp_listen(tcp_svr, TCP_CONTROL_PORT, XTCP_PROTOCOL_TCP);

	// Loop forever processing TCP/IP events
	while (1)
	{
		// Get an event
		slave xtcp_event(tcp_svr, conn);

		// We have received an event from the TCP stack, so respond appropriately
        switch (conn.event)
        {
                case XTCP_NEW_CONNECTION:
					printstr( "CONTROL: Connection from " );
					printuint( conn.remote_addr[0] );
					printchar( '.' );
					printuint( conn.remote_addr[1] );
					printchar( '.' );
					printuint( conn.remote_addr[2] );
					printchar( '.' );
					printuint( conn.remote_addr[3] );
					printchar( '\n' );
                    break;

                case XTCP_RECV_DATA:
                	// Get the packet
                	n = xtcp_recv(tcp_svr, rx_buf);

                	// Do some response based on the command
                	if (rx_buf[0] == 's' && rx_buf[1] == 'p' && rx_buf[2] == 'e' && rx_buf[3] == 'e' && rx_buf[4] == 'd')
                	{
						c_speed <: CMD_GET_VALS;
						c_speed :> speed;
						c_speed :> set_speed;

						// Put the speed in the tx buffer
						tx_buf[0] = ( ( speed >> 0 ) & 0xFF);
						tx_buf[1] = ( ( speed >> 8 ) & 0xFF);
						tx_buf[2] = ( ( speed >> 16 ) & 0xFF);
						tx_buf[3] = ( ( speed >> 24 ) & 0xFF);

						// Put the set speed in the tx buffer
						tx_buf[4] = ( ( set_speed >> 0 ) & 0xFF);
						tx_buf[5] = ( ( set_speed >> 8 ) & 0xFF);
						tx_buf[6] = ( ( set_speed >> 16 ) & 0xFF);
						tx_buf[7] = ( ( set_speed >> 24 ) & 0xFF);

						// Say how much of the buffer should be sent
                		n = 8;

                		// Initiate the sending of the buffer
                		xtcp_init_send(tcp_svr, conn);
					}
                	else if (rx_buf[0] == 's' && rx_buf[1] == 'e' && rx_buf[2] == 't')
                	{
                		if (n == 7)
                		{
                			// Convert the value into the set speed
                			set_speed  = rx_buf[6] << 24;
                			set_speed += rx_buf[5] << 16;
                			set_speed += rx_buf[4] << 8;
                			set_speed += rx_buf[3];

                			// Send it to the main control loop
                			c_speed <: CMD_SET_SPEED;
                			c_speed <: set_speed;
                		}
                	}
                	else if (rx_buf[0] == 'g' && rx_buf[1] == 'o')
                	{
						// New connection, but we don't need to do anything.
					}
                	else if (rx_buf[0] == 's' && rx_buf[1] == 't' && rx_buf[2] == 'o' && rx_buf[3] == 'p')
                	{
                		xtcp_close(tcp_svr, conn);
					}
                	else
                	{
                		rx_buf[n] = '\0';
						printstr( "CONTROL: Error: received " );
						printuint( n );
						printstr( " bytes: " );
						printstr( rx_buf );
						printchar( '\n' );
                	}
                    break;

                case XTCP_SENT_DATA:
                	xtcp_send(tcp_svr, null, 0);
                	break;

                case XTCP_REQUEST_DATA:
                case XTCP_RESEND_DATA:
                	xtcp_send(tcp_svr, tx_buf, n);
                	break;

                case XTCP_TIMED_OUT:
                case XTCP_ABORTED:
                case XTCP_CLOSED:
                	xtcp_close(tcp_svr, conn);

                	printstr( "CONTROL: Closed connection from " );
					printuint( conn.remote_addr[0] );
					printchar( '.' );
					printuint( conn.remote_addr[1] );
					printchar( '.' );
					printuint( conn.remote_addr[2] );
					printchar( '.' );
					printuint( conn.remote_addr[3] );
					printchar( '\n' );

                    break;
        }
	}
}
#endif
