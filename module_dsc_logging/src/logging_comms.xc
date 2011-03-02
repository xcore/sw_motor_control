/**
 * Module:  module_dsc_logging
 * Version: 1v0alpha0
 * Build:   128bfdf87839aeec0e38320c3524102eb996ecd5
 * File:    logging_comms.xc
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
#include "logging_comms.h"
#include "ethernet_server.h"
#include "uip_server.h"
#include "xtcp_client.h"
#include "dsc_sdram.h"


// Ethernet logging interface thread
void do_logging_eth( chanend c_data, chanend tcp_svr )
{
	xtcp_connection_t conn;
	unsigned char tx_buf[1024];
	unsigned char rx_buf[1024];
	unsigned int n, tmp, i;
	timer t;
	unsigned int time;

	// Wait for 1 second after bootup to allow everything to 'settle'
	t :> time;
	t when timerafter ( time + 100000000 ) :> time;

	//slave xtcp_event(tcp_svr, conn);
	//if (conn.event != XTCP_IFDOWN)
	//	printf("Didn't get XTCP_IFDOWN!");

	// listen on a port
	xtcp_listen(tcp_svr, TCP_LOGGING_PORT, XTCP_PROTOCOL_TCP);

	// Loop forever processing Ethernet requests
	while (1)
	{
		// Get a TCP/IP event.
		slave xtcp_event(tcp_svr, conn);

		// We have received an event from the TCP stack, so respond appropriately
		switch (conn.event)
		{
			case XTCP_NEW_CONNECTION:
				printstr( "LOGGING: Connection from " );
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

					// Get the data
					n = xtcp_recv(tcp_svr, rx_buf);

					// Test
					if (rx_buf[0] == 'A')
					{
						// Get the record of data
						for ( i = 0; i < (SDRAM_PACKET_NWORDS*4*8); i=i+4 )
						{
							// Get the current word from memory
							tmp = inuint(c_data);
							tx_buf[i] = (tmp >> 24) & 0xFF;
							tx_buf[i+1] = (tmp >> 16) & 0xFF;
							tx_buf[i+2] = (tmp >> 8) & 0xFF;
							tx_buf[i+3] = (tmp >> 0) & 0xFF;
						}

						// Send the data
						xtcp_init_send(tcp_svr, conn);

						// Say how much of the buffer should be sent
						n = 1024;
					}
					else if (rx_buf[0] == 'g' && rx_buf[1] == 'o')
					{
						// Start sending the data
						c_data <: 1;

						// Get the record of data
						for ( i = 0; i < (SDRAM_PACKET_NWORDS*4*8); i=i+4 )
						{
							// Get the current word from memory
							tmp = inuint(c_data);
							tx_buf[i] = (tmp >> 24) & 0xFF;
							tx_buf[i+1] = (tmp >> 16) & 0xFF;
							tx_buf[i+2] = (tmp >> 8) & 0xFF;
							tx_buf[i+3] = (tmp >> 0) & 0xFF;
						}

						// Send the data
						xtcp_init_send(tcp_svr, conn);

						// Say how much of the buffer should be sent
						n = 1024;
					}
					else
					{
						// It's an erronous packet, so do nothing
					}

			    	break;

			case XTCP_SENT_DATA:
				// Close the connection
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

				printstr( "LOGGING: Closed connection from " );
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