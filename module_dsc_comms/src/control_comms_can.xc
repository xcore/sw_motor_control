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

#ifdef BLDC_BASIC
// Thread that does the CAN control interface
void do_comms_can( chanend c_commands_can, chanend rxChan, chanend txChan, chanend c_control_can,chanend c_commands_can2)
{
	struct CanPacket p;
	unsigned int sender_address, count = 1, value;
	unsigned int speed1 = 1000,speed2=1000;
	unsigned int set_speed = 1000;
	unsigned  error_flag1=0,error_flag2=0;
	unsigned int Ia=0,Ib=0,Ic=0,Iq_set_point=0,Id_out=0,Iq_out=0;
	unsigned int Ia2=0,Ib2=0,Ic2=0,Iq_set_point2=0,Id_out2=0,Iq_out2=0;
	//unsigned ref_speed_flag1=0;

   //enable CAN
     c_control_can<:CAN_RS_LO;

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

			//Select what to do based on the command send
			       switch ( p.DATA[2] )
				{
					case 1 : // send CAN packet 1

						//Get motor1 data
						c_commands_can <: CMD_GET_VALS;
						c_commands_can :> speed1;
						//c_commands_can :> set_speed;
						//c_commands_can :> error_flag1;
						//Get motor2 data
						c_commands_can2<:CMD_GET_VALS;
						c_commands_can2 :> speed2;
						//c_commands_can2 :> error_flag2;

						// Put the speed into the packet
						p.DATA[0] = ( ( speed1 >> 8) & 0xFF);
						p.DATA[1] = ( ( speed1 >> 0 ) & 0xFF);
						p.DATA[2] = ( ( speed2 >> 8 ) & 0xFF);
						p.DATA[3] = ( ( speed2 >> 0 ) & 0xFF);

						// Put Ia and Ib into the packet
						p.DATA[4] = ( (Ia >> 8 ) & 0xFF);
						p.DATA[5] = ( (Ia >> 0 ) & 0xFF);
						p.DATA[6] = ( (Ib >> 8) & 0xFF);
						p.DATA[7] = ( (Ib >> 0 ) & 0xFF);

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

						// Send the set speed to the command thread for motor1
						c_commands_can <: CMD_SET_SPEED;
						c_commands_can <: set_speed;

						// Send the set speed to the command thread for motor1
						c_commands_can2 <: CMD_SET_SPEED;
						c_commands_can2 <: set_speed;
						// FUDGE - Make the set speed = ( speed / 2 )
               			speed1 = set_speed >> 1;
               			speed2 = set_speed >> 1;

						break;
					case 3: //send CAN packet 2
						//Giving some junk values as current values not applicable for BASIC_BLDC

					// Put Ic and Iq_set_point into the packet
						p.DATA[0] = ( ( Ic           >> 8) & 0xFF);
						p.DATA[1] = ( ( Ic           >> 0 ) & 0xFF);
						p.DATA[2] = ( ( Iq_set_point >> 8 ) & 0xFF);
						p.DATA[3] = ( ( Iq_set_point >> 0 ) & 0xFF);

					// Put Id_out and Iq_out into the packet
						p.DATA[4] = ( ( Id_out >> 8 ) & 0xFF);
						p.DATA[5] = ( ( Id_out >> 0 ) & 0xFF);
						p.DATA[6] = ( ( Iq_out >> 8) & 0xFF);
						p.DATA[7] = ( ( Iq_out >> 0 ) & 0xFF);

					// Finally, send the packet
						outuint(txChan, count);
						sendPacket(txChan, p);

					// Increment the packet count
						count = (count + 1) & COUNTER_MASK;
					break;

			    case 4://send CAN packet 3

				// Put Ia2 and Ib2 into the packet
					p.DATA[0] = ( ( Ia2 >> 8) & 0xFF);
					p.DATA[1] = ( ( Ia2 >> 0 ) & 0xFF);
					p.DATA[2] = ( ( Ib2 >> 8 ) & 0xFF);
				    p.DATA[3] = ( ( Ib2 >> 0 ) & 0xFF);

			// Put Ic2 and Iq_set_point2 into the packet
			        p.DATA[4] = ( ( Ic2           >> 8 ) & 0xFF);
			        p.DATA[5] = ( ( Ic2           >> 0 ) & 0xFF);
			        p.DATA[6] = ( ( Iq_set_point2 >> 8) & 0xFF);
			        p.DATA[7] = ( ( Iq_set_point2 >> 0 ) & 0xFF);

			// Finally, send the packet
				outuint(txChan, count);
				sendPacket(txChan, p);

			// Increment the packet count
				count = (count + 1) & COUNTER_MASK;


		     	break;
			 case 5:   //send can packet 4

				 // Put Id_out2 and Iq_out2 into the packet
					p.DATA[0] = ( ( Id_out2 >> 8) & 0xFF);
					p.DATA[1] = ( ( Id_out2 >> 0 ) & 0xFF);
					p.DATA[2] = ( ( Iq_out2 >> 8 ) & 0xFF);
					p.DATA[3] = ( ( Iq_out2 >> 0 ) & 0xFF);

				// Put error_flags  into the packet
					p.DATA[4] = ( ( error_flag1 >> 0 ) & 0xFF);
					p.DATA[5] = ( ( error_flag2 >> 0 ) & 0xFF);
					p.DATA[6] = ( ( Iq_out2     >> 8) & 0xFF);   //unused byte
					p.DATA[7] = ( ( Iq_out2     >> 0 ) & 0xFF);  //unused byte

				// Finally, send the packet
					outuint(txChan, count);
					sendPacket(txChan, p);

				// Increment the packet count
					count = (count + 1) & COUNTER_MASK;
				break;
		 default :// Unknown command - ignore it.
						//printstr("Unknown\n");

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
#endif    //BLDC_BASIC

#ifdef BLDC_FOC
void do_comms_can( chanend c_commands_can, chanend rxChan, chanend txChan, chanend c_control_can)
{
	struct CanPacket p;
	unsigned int sender_address, count = 1, value;
	unsigned int speed1 = 1000,speed2=0;
	unsigned int set_speed = 1000;
	unsigned  error_flag1=0,error_flag2=0;   //fault indication
	unsigned int Ia=0,Ib=0,Ic=0,Iq_set_point=0,Id_out=0,Iq_out=0; // motor1 parameters
	unsigned int Ia2=0,Ib2=0,Ic2=0,Iq_set_point2=0,Id_out2=0,Iq_out2=0;  //motor2 parameters

    //enable CAN
    c_control_can<:CAN_RS_LO;
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

			//Select what to do based on the command send
			       switch ( p.DATA[2] )
				{
					case 1 : //Send CAN frame 1

						// Get the speed ,Ia,Ib of motor1

						c_commands_can <: CMD_GET_VALS;
						c_commands_can :> speed1;
						c_commands_can :> Ia;
						c_commands_can :> Ib;

						// Put the speed1 and speed2 into the packet
						p.DATA[0] = ( ( speed1 >> 8) & 0xFF);
						p.DATA[1] = ( ( speed1 >> 0 ) & 0xFF);
						p.DATA[2] = ( ( speed2 >> 8 ) & 0xFF);
						p.DATA[3] = ( ( speed2 >> 0 ) & 0xFF);

						// Put the Ia and Ib into the packet
						p.DATA[4] = ( (Ia >> 8 ) & 0xFF);
						p.DATA[5] = ( (Ia >> 0 ) & 0xFF);
						p.DATA[6] = ( (Ib >> 8) & 0xFF);
						p.DATA[7] = ( (Ib >> 0 ) & 0xFF);

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
						c_commands_can <: CMD_SET_SPEED;
						c_commands_can <: set_speed;

						// FUDGE - Make the set speed = ( speed / 2 )
               			speed1 = set_speed >> 1;


						break;
					case 3: //send CAN frame 2
						//get Ic,Iq_set_point,Iq_out and Id_out of motor1
						c_commands_can <: CMD_GET_VALS2;
						c_commands_can :> Ic;
						c_commands_can :> Iq_set_point;
						c_commands_can :> Id_out;
						c_commands_can :> Iq_out;


					// Put Ic and Iq_set_point into the packet
						p.DATA[0] = ( ( Ic           >> 8) & 0xFF);
						p.DATA[1] = ( ( Ic           >> 0 ) & 0xFF);
						p.DATA[2] = ( ( Iq_set_point >> 8 ) & 0xFF);
						p.DATA[3] = ( ( Iq_set_point >> 0 ) & 0xFF);

					// Put Id_out and Iq_out into the packet
						p.DATA[4] = ( ( Id_out >> 8 ) & 0xFF);
						p.DATA[5] = ( ( Id_out >> 0 ) & 0xFF);
						p.DATA[6] = ( ( Iq_out >> 8) & 0xFF);
						p.DATA[7] = ( ( Iq_out >> 0 ) & 0xFF);

					// Finally, send the packet
						outuint(txChan, count);
						sendPacket(txChan, p);

					// Increment the packet count
						count = (count + 1) & COUNTER_MASK;
					break;

			    case 4: //send CAN packet 3
			    	//sends motor 2 data

				// Put Ia2 and Ib2 into the packet
					p.DATA[0] = ( ( Ia2 >> 8) & 0xFF);
					p.DATA[1] = ( ( Ia2 >> 0 ) & 0xFF);
					p.DATA[2] = ( ( Ib2 >> 8 ) & 0xFF);
				    p.DATA[3] = ( ( Ib2 >> 0 ) & 0xFF);

			// Put Ic2 and Iq_set_point into the packet
			        p.DATA[4] = ( ( Ic2           >> 8 ) & 0xFF);
			        p.DATA[5] = ( ( Ic2           >> 0 ) & 0xFF);
			        p.DATA[6] = ( ( Iq_set_point2 >> 8) & 0xFF);
			        p.DATA[7] = ( ( Iq_set_point2 >> 0 ) & 0xFF);

			// Finally, send the packet
				outuint(txChan, count);
				sendPacket(txChan, p);

			// Increment the packet count
				count = (count + 1) & COUNTER_MASK;


		     	break;
			 case 5:  //send CAN packet 4
                  //sends motor 2 data and fault

				// Put Id_out and Iq_out into the packet
					p.DATA[0] = ( ( Id_out2 >> 8) & 0xFF);
					p.DATA[1] = ( ( Id_out2 >> 0 ) & 0xFF);
					p.DATA[2] = ( ( Iq_out2 >> 8 ) & 0xFF);
					p.DATA[3] = ( ( Iq_out2 >> 0 ) & 0xFF);

				// Put error flags of motor1 and 2 into the packet(last 2 bytes vacant i.e.,6 and 7)
					p.DATA[4] = ( ( error_flag1 >> 0 ) & 0xFF);
					p.DATA[5] = ( ( error_flag2 >> 0 ) & 0xFF);
					p.DATA[6] = ( ( Iq_out2     >> 8) & 0xFF);
					p.DATA[7] = ( ( Iq_out2     >> 0 ) & 0xFF);

				// Finally, send the packet
					outuint(txChan, count);
					sendPacket(txChan, p);

				// Increment the packet count
					count = (count + 1) & COUNTER_MASK;
				break;
		 default :// Unknown command - ignore it.
						//printstr("Unknown\n");

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

#endif  //BLDC_FOC



#endif  //USE_CAN
