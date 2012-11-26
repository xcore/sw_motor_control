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

#ifdef USE_CAN

#include "control_comms_can.h"
#include "CanIncludes.h"
#include "CanFunctions.h"
#include "shared_io.h"


#define COUNTER_MASK  0xfff

void do_comms_can( chanend c_commands[], chanend rxChan, chanend txChan)
{
	struct CanPacket p;
	unsigned int sender_address, count = 1, value;
	unsigned int speed[2] = {1000,1000};
	unsigned int set_speed = 1000;
	unsigned int error_flag[2] = {0,0};
	unsigned int Ia[2],Ib[2],Ic[2],Iq_set_point[2],Id_out[2],Iq_out[2]; // motor1 parameters

	// Loop forever processing packets
	while( 1 ) {

		// Wait for a command
		value = inuint(rxChan);
	    receivePacket(rxChan, p);

		// Increment the count
		count = (count + 1) & COUNTER_MASK;

		// Check that the packet is for us (Address = 0x1)
		if (p.ID == 0x1 ) {

			// Check that it is the correct length (8 bytes)
			if ( p.DLC == 8 ) {

				// The first 2 bytes of the packet are the sender address
				sender_address = (p.DATA[0] << 8) + p.DATA[1];

				// Write the sender address, making sure that it is less than 127
				p.ID  = sender_address & 0x7F;

				//Select what to do based on the command send
				switch ( p.DATA[2] ) 
				{
					case 1 : //Send CAN frame 1

						// Get the speed ,Ia,Ib of motor1
						for (unsigned int m=0; m<NUMBER_OF_MOTORS; m++) {
							c_commands[m] <: CMD_GET_VALS;
							c_commands[m] :> speed[m];
							c_commands[m] :> Ia[m];
							c_commands[m] :> Ib[m];
						}

						// Put the speeds into the packet
						p.DATA[0] = ( ( speed[0] >> 8) & 0xFF);
						p.DATA[1] = ( ( speed[0] >> 0 ) & 0xFF);
						p.DATA[2] = ( ( speed[1] >> 8 ) & 0xFF);
						p.DATA[3] = ( ( speed[1] >> 0 ) & 0xFF);

						// Put the Ia and Ib into the packet
						p.DATA[4] = ( (Ia[0] >> 8 ) & 0xFF);
						p.DATA[5] = ( (Ia[0] >> 0 ) & 0xFF);
						p.DATA[6] = ( (Ib[0] >> 8) & 0xFF);
						p.DATA[7] = ( (Ib[0] >> 0 ) & 0xFF);

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
						for (unsigned int m=0; m<NUMBER_OF_MOTORS; m++) {
							c_commands[m] <: CMD_SET_SPEED;
							c_commands[m] <: set_speed;
						}

						// FUDGE - Make the set speed = ( speed / 2 )
               			speed[0] = set_speed >> 1;
               			speed[1] = set_speed >> 1;
						break;

					case 3: //send CAN frame 2
						//get Ic,Iq_set_point,Iq_out and Id_out of motor1
						for (unsigned int m=0; m<NUMBER_OF_MOTORS; m++) {
							c_commands[m] <: CMD_GET_VALS2;
							c_commands[m] :> Ic[m];
							c_commands[m] :> Iq_set_point[m];
							c_commands[m] :> Id_out[m];
							c_commands[m] :> Iq_out[m];
						}


						// Put Ic and Iq_set_point into the packet
						p.DATA[0] = ( ( Ic[0]           >> 8) & 0xFF);
						p.DATA[1] = ( ( Ic[0]           >> 0 ) & 0xFF);
						p.DATA[2] = ( ( Iq_set_point[0] >> 8 ) & 0xFF);
						p.DATA[3] = ( ( Iq_set_point[0] >> 0 ) & 0xFF);

						// Put Id_out and Iq_out into the packet
						p.DATA[4] = ( ( Id_out[0] >> 8 ) & 0xFF);
						p.DATA[5] = ( ( Id_out[0] >> 0 ) & 0xFF);
						p.DATA[6] = ( ( Iq_out[0] >> 8) & 0xFF);
						p.DATA[7] = ( ( Iq_out[0] >> 0 ) & 0xFF);

						// Finally, send the packet
						outuint(txChan, count);
						sendPacket(txChan, p);

						// Increment the packet count
						count = (count + 1) & COUNTER_MASK;
						break;

			    case 4: //send CAN packet 3
			    	//sends motor 2 data
					for (unsigned int m=0; m<NUMBER_OF_MOTORS; m++) {
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
						c_commands[m] :> error_flag[m];
					}

					// Put Ia2 and Ib2 into the packet
					p.DATA[0] = ( ( Ia[1] >> 8) & 0xFF);
					p.DATA[1] = ( ( Ia[1] >> 0 ) & 0xFF);
					p.DATA[2] = ( ( Ib[1] >> 8 ) & 0xFF);
				    p.DATA[3] = ( ( Ib[1] >> 0 ) & 0xFF);

				    	// Put Ic2 and Iq_set_point into the packet
			        p.DATA[4] = ( ( Ic[1]           >> 8 ) & 0xFF);
			        p.DATA[5] = ( ( Ic[1]           >> 0 ) & 0xFF);
			        p.DATA[6] = ( ( Iq_set_point[1] >> 8) & 0xFF);
			        p.DATA[7] = ( ( Iq_set_point[1] >> 0 ) & 0xFF);

			        // Finally, send the packet
			        outuint(txChan, count);
			        sendPacket(txChan, p);

			        // Increment the packet count
			        count = (count + 1) & COUNTER_MASK;
			        break;

			    case 5:  //send CAN packet 4
			    	//sends motor 2 data and fault

			    	// Put Id_out and Iq_out into the packet
					p.DATA[0] = ( ( Id_out[1] >> 8) & 0xFF);
					p.DATA[1] = ( ( Id_out[1] >> 0 ) & 0xFF);
					p.DATA[2] = ( ( Iq_out[1] >> 8 ) & 0xFF);
					p.DATA[3] = ( ( Iq_out[1] >> 0 ) & 0xFF);

					// Put error flags of motor1 and 2 into the packet(last 2 bytes vacant i.e.,6 and 7)
					p.DATA[4] = ( ( error_flag[0] >> 0 ) & 0xFF);
					p.DATA[5] = ( ( error_flag[1] >> 0 ) & 0xFF);
					p.DATA[6] = ( ( Iq_out[1]     >> 8) & 0xFF);
					p.DATA[7] = ( ( Iq_out[1]     >> 0 ) & 0xFF);

					// Finally, send the packet
					outuint(txChan, count);
					sendPacket(txChan, p);

					// Increment the packet count
					count = (count + 1) & COUNTER_MASK;
					break;

			    default :// Unknown command - ignore it.
			    break;
			  } // switch ( p.DATA[2] ) 
			}
		}
	}
}



#endif  //USE_CAN
