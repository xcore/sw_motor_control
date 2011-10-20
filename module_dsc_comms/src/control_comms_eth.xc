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
#include "shared_io.h"

void to_hex_string(int number, char& lsb, char& msb)
{
	int digit = number & 0xF;
	if (digit <= 0x9) {
		lsb = digit + '0';
	} else if (digit <= 0xF) {
		lsb = digit + 'A' - 10;
	} else {
		lsb = '-';
	}
	digit = (number & 0xF0) >> 4;
	if (digit <= 0x9) {
		msb = digit + '0';
	} else if (digit <= 0xF) {
		msb = digit + 'A' - 10;
	} else {
		msb = '-';
	}
}

int from_hex_string(char digit)
{
	if (digit >= '0' && digit <= '9') return digit - '0';
	if (digit >= 'A' && digit <= 'F') return digit - 'A' + 10;
	return 0;
}

unsigned char tx_buf[128];
unsigned char rx_buf[128];

void do_comms_eth( chanend c_commands[], chanend tcp_svr )
{
	xtcp_connection_t conn;
	unsigned int speed[2] = {0,0};
	unsigned int set_speed = 500;
	unsigned int n;

	unsigned int Ia[2],Ib[2],Ic[2];
	unsigned int Iq_set_point[2],Id_out[2],Iq_out[2];
    unsigned int fault_flag[2];

	slave xtcp_event(tcp_svr, conn);
	if (conn.event != XTCP_IFDOWN)
	{
		printstr("Didn't get XTCP_IFDOWN!\n");
	}

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
                    break;

                case XTCP_RECV_DATA:
                	// Get the packet
                	n = xtcp_recv(tcp_svr, rx_buf);

                	// Do some response based on the command
                	if (rx_buf[0] == '^' && rx_buf[1] == '2' && rx_buf[2] == '|')
                	{
                		for (unsigned m=0; m<NUMBER_OF_MOTORS; ++m) {
                    		c_commands[m] <: CMD_GET_VALS;
                    		c_commands[m] :> speed[m];
                    		c_commands[m] :> Ia[m];
                    		c_commands[m] :> Ib[m];

                    		c_commands[m] <: CMD_GET_VALS2;
                    		c_commands[m] :> Ic[m];
                    		c_commands[m] :> Iq_set_point[m];
                    		c_commands[m] :> Id_out[m];
                    		c_commands[m] :> Iq_out[m];

                    		c_commands[m] <: CMD_GET_FAULT;
                    		c_commands[m] :> fault_flag[m];
                		}


						tx_buf[0]  = '^';
						tx_buf[1]  = '2';
 						tx_buf[2]  = '|';

						// Put the speed1 in the tx buffer
						to_hex_string( ( speed[0] >> 0 ) & 0xFF, tx_buf[6], tx_buf[5]);
						to_hex_string( ( speed[0] >> 8 ) & 0xFF, tx_buf[4], tx_buf[3]);

						tx_buf[7]  = '|';

						// Put the speed2 in the tx buffer
						to_hex_string( ( speed[1] >> 0 ) & 0xFF, tx_buf[11], tx_buf[10]);
						to_hex_string( ( speed[1] >> 8 ) & 0xFF, tx_buf[9], tx_buf[8]);

						tx_buf[12]  = '|';

						// Put Ia in the tx buffer
						to_hex_string( ( Ia[0] >> 0 ) & 0xFF, tx_buf[16], tx_buf[15]);
						to_hex_string( ( Ia[0] >> 8 ) & 0xFF, tx_buf[14], tx_buf[13]);

						tx_buf[17]  = '|';

						// Put Ib in the tx buffer
						to_hex_string( ( Ib[0] >> 0 ) & 0xFF, tx_buf[21], tx_buf[20]);
						to_hex_string( ( Ib[0] >> 8 ) & 0xFF, tx_buf[19], tx_buf[18]);

						tx_buf[22]  = '|';

						// Put Ic in the tx buffer
						to_hex_string( ( Ic[0] >> 0 ) & 0xFF, tx_buf[26], tx_buf[25]);
						to_hex_string( ( Ic[0] >> 8 ) & 0xFF, tx_buf[24], tx_buf[23]);

						tx_buf[27]  = '|';

						// Put Iq_set_point in the tx buffer
						to_hex_string( ( Iq_set_point[0] >> 0 ) & 0xFF, tx_buf[31], tx_buf[30]);
						to_hex_string( ( Iq_set_point[0] >> 8 ) & 0xFF, tx_buf[29], tx_buf[28]);

						tx_buf[32]  = '|';

						// Put Id_out in the tx buffer
						to_hex_string( ( Id_out[0] >> 0 ) & 0xFF, tx_buf[36], tx_buf[35]);
						to_hex_string( ( Id_out[0] >> 8 ) & 0xFF, tx_buf[34], tx_buf[33]);

						tx_buf[37]  = '|';

						// Put Iq_out in the tx buffer
						to_hex_string( ( Iq_out[0] >> 0 ) & 0xFF, tx_buf[41], tx_buf[40]);
						to_hex_string( ( Iq_out[0] >> 8 ) & 0xFF, tx_buf[39], tx_buf[38]);

						tx_buf[42]  = '|';

						// Put Ia2 in the tx buffer
						to_hex_string( ( Ia[1] >> 0 ) & 0xFF, tx_buf[46], tx_buf[45]);
						to_hex_string( ( Ia[1] >> 8 ) & 0xFF, tx_buf[44], tx_buf[43]);

						tx_buf[47]  = '|';

						// Put Ib2 in the tx buffer
						to_hex_string( ( Ib[1] >> 0 ) & 0xFF, tx_buf[51], tx_buf[50]);
						to_hex_string( ( Ib[1] >> 8 ) & 0xFF, tx_buf[49], tx_buf[48]);

						tx_buf[52]  = '|';

						// Put Ic2 in the tx buffer
						to_hex_string( ( Ic[1] >> 0 ) & 0xFF, tx_buf[56], tx_buf[55]);
						to_hex_string( ( Ic[1] >> 8 ) & 0xFF, tx_buf[54], tx_buf[53]);

						tx_buf[57]  = '|';

						// Put Iq_set_point2 in the tx buffer
						to_hex_string( ( Iq_set_point[1] >> 0 ) & 0xFF, tx_buf[61], tx_buf[60]);
						to_hex_string( ( Iq_set_point[1] >> 8 ) & 0xFF, tx_buf[59], tx_buf[58]);

						tx_buf[62]  = '|';

						// Put Id_out2 in the tx buffer
						to_hex_string( ( Id_out[1] >> 0 ) & 0xFF, tx_buf[66], tx_buf[65]);
						to_hex_string( ( Id_out[1] >> 8 ) & 0xFF, tx_buf[64], tx_buf[63]);

						tx_buf[67]  = '|';

						// Put Iq_out2 in the tx buffer
						to_hex_string( ( Iq_out[1] >> 0 ) & 0xFF, tx_buf[71], tx_buf[70]);
						to_hex_string( ( Iq_out[1] >> 8 ) & 0xFF, tx_buf[69], tx_buf[68]);

						tx_buf[72]  = '|';

						// Put Iq_out2 in the tx buffer
						to_hex_string( ( fault_flag[0] >> 0 ) & 0xFF, tx_buf[74], tx_buf[73]);
						tx_buf[75]  = '|';
						to_hex_string( ( fault_flag[1] >> 0 ) & 0xFF, tx_buf[77], tx_buf[76]);


                        tx_buf[78] = '!';


						// Say how much of the buffer should be sent
                		n = 79;

                		// Initiate the sending of the buffer
                		xtcp_init_send(tcp_svr, conn);
					}
                	else if (rx_buf[0] == '^'&& rx_buf[1] == '1' && rx_buf[2] == '|')
                	{
                		if (n >= 7)
                		{
                			// Convert the value into the set speed
                			set_speed  = from_hex_string(rx_buf[3]) << 12;
                			set_speed += from_hex_string(rx_buf[4]) << 8;
                			set_speed += from_hex_string(rx_buf[5]) << 4;
                			set_speed += from_hex_string(rx_buf[6]);

                			// Send it to the main control loop
                			for (unsigned m=0; m<NUMBER_OF_MOTORS; ++m) {
                    			c_commands[m] <: CMD_SET_SPEED;
                    			c_commands[m] <: set_speed;
                			}

                		}
                	}

                	else
                	{
                		rx_buf[n] = '\0';

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

                    break;
        }
	}
}

#endif  //USE_ETH


