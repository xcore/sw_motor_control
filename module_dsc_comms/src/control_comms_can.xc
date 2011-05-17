/**
 * Module:  module_dsc_comms
 * Version: 1v0alpha1
 * Build:   73e3f5032a883e9f72779143401b3392bb65d5bb
 * File:    control_comms_can.xc
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

#include "control_comms_can.h"
#include "CanIncludes.h"
#include "CanFunctions.h"
#include "shared_io.h"

#define COUNTER_MASK  0xfff


// Thread that does the CAN control interface
void do_comms_can( chanend c_speed, chanend rxChan, chanend txChan, chanend c_reset)
{
	struct CanPacket p;
	unsigned int sender_address, count = 1, value;
	unsigned int speed = 1000;
	unsigned int set_speed = 1000;

	// Come out of CAN reset
	c_reset <: 1;

	// Loop forever processing packets
	while( 1 )
	{
		// Wait for a command
		value = inuint(rxChan);
		receivePacket(rxChan, p);

		// Increment the count
		count = (count + 1) & COUNTER_MASK;

		// Check that the packet is for us (Address = 0x1)
		if (p.ID == 0x1 )
		{
			// Check that it is the correct length (8 bytes)
			if ( p.DLC == 8 )
			{
				// The first 2 bytes of the packet are the sender address
				sender_address = (p.DATA[0] << 8) + p.DATA[1];

				// Select what to do based on the command send
				switch ( p.DATA[2] )
				{
					case 1 : // Speed Command

						// Get the speed and set point
						c_speed <: CMD_GET_VALS;
						c_speed :> speed;
						c_speed :> set_speed;

						// Fields which are fixed
						p.SOF = 0;
						p.RB0 = 0;
						p.CRC_DEL = 1;
						p.ACK_DEL = 1;
						p._EOF = 0x7F;
						p.DLC = 8;
						p.CRC = 0; // CRC is calculated by transmitter

						// Create a normal packet
						p.SRR = 0;
						p.IEB = 0;
						p.EID = 0;
						p.RTR = 0;
						p.RB1 = 0;

						// Write the sender address, making sure that it is less than 127
						p.ID  = sender_address & 0x7F;

						// Put the speed into the packet
						p.DATA[0] = ( ( speed >> 24 ) & 0xFF);
						p.DATA[1] = ( ( speed >> 16 ) & 0xFF);
						p.DATA[2] = ( ( speed >> 8 ) & 0xFF);
						p.DATA[3] = ( ( speed >> 0 ) & 0xFF);

						// Put the set_speed into the packet
						p.DATA[4] = ( ( set_speed >> 24 ) & 0xFF);
						p.DATA[5] = ( ( set_speed >> 16 ) & 0xFF);
						p.DATA[6] = ( ( set_speed >> 8 ) & 0xFF);
						p.DATA[7] = ( ( set_speed >> 0 ) & 0xFF);

						// Finally, send the packet
						outuint(txChan, count);
						sendPacket(txChan, p);

						// Increment the packet count
						count = (count + 1) & COUNTER_MASK;

						break;

					case 2 : // Set Command

						// Rebuild the speed from the packet
						set_speed = ((p.DATA[3] & 0xFF) << 24);
						set_speed = set_speed + ((p.DATA[4] & 0xFF) << 16);
						set_speed = set_speed + ((p.DATA[5] & 0xFF) << 8);
						set_speed = set_speed + ((p.DATA[6] & 0xFF) << 0);

						// Send the set speed to the command thread
						c_speed <: CMD_SET_SPEED;
						c_speed <: set_speed;

               			speed = set_speed >> 1;

						break;

					default : // Unknown command - ignore it.
						break;
				}
			}
			else
			{
				// Packet too short - ignore it.
			}
		}
		else
		{
			// Erronous packet received - ignore it.
		}
	}
}


