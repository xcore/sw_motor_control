/**
 * Module:  module_dsc_logging
 * Version: 1v0alpha1
 * Build:   c8420856b3ffd33a58ac7544991fc1ed1d35737c
 * File:    logging_if.xc
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
#include "logging_if.h"
#include "dsc_sdram.h"


// Concentrate the logging information into a buffer
void logging_concentrator( chanend data_out, chanend c_outer_loop, chanend c_inner_loop )
{
	unsigned int buf[31], i, junk, time;
	char cjunk;
	timer t;

	// Fill the buffer with zeros initially
	for ( i = 0; i < ( SDRAM_PACKET_NWORDS - 1 ); i++)
	{
		buf[i] = 0x0;
	}

	// Get the initial time
	t :> time;

	// Loop forever buffering data
	while (1)
	{
		select
		{
			// Get the values from the outer loop
			case c_outer_loop :> buf[0]: // speed
				c_outer_loop :> buf[1]; // set_speed
				c_outer_loop :> buf[2]; // Iq_set_point
				break;

			// Get the values from the inner loop
			case c_inner_loop :> junk :
				buf[3] = inuint( c_inner_loop ); // Ia_in
				buf[4] = inuint( c_inner_loop ); // Ib_in
				buf[5] = inuint( c_inner_loop ); // Ic_in
				buf[6] = inuint( c_inner_loop ); // Iq_set_point
				buf[7] = inuint( c_inner_loop ); // Iq_in
				buf[8] = inuint( c_inner_loop ); // Id_in
				buf[9] = inuint( c_inner_loop ); // Iq_out
				buf[10] = inuint( c_inner_loop ); // Id_out
				buf[11] = inuint( c_inner_loop ); // theta
				buf[12] = inuint( c_inner_loop ); // speed
				buf[13] = inuint( c_inner_loop ); // delta
				buf[14] = inuint( c_inner_loop ); // pwm[0]
				buf[15] = inuint( c_inner_loop ); // pwm[1]
				buf[16] = inuint( c_inner_loop ); // pwm[2]
				break;

			// Send the values to the logging engine
			case inct_byref(data_out, cjunk):

				// dump in the time val
				t :> junk;
				buf[17] = ( junk - time );

				for ( i = 0; i < ( SDRAM_PACKET_NWORDS - 1 ); i++)
				{
					outuint(data_out, buf[i]);
				}
				
				outct(data_out,1);

				break;
		}
	}
}


// The actual logging server that stores the data
void logging_server(chanend c_sdram, chanend c_logging_data, chanend c_data_read)
{
	unsigned int junk, i, time, tmp; // act_time
	unsigned int address = 0, stop_logging = 1;
	unsigned int record_number = 0;
	unsigned int data[SDRAM_PACKET_NWORDS];
	timer t;

	// SDRAM_NWORDS = 8388608
	// SDRAM_PACKET_NWORDS = 32

	// Get time
	t :> time;

	// Wait for 1 secs before logging
	t when timerafter ( time + 100000000 ) :> time;

	// Loop forever waiting for commands.
	while ( 1 )
	{

		select
		{
			// Command to read all data.
			case c_data_read :> junk:

				// Read from all the memory
				c_sdram <: 2;

				for (i = 0; i < ( SDRAM_NWORDS ); i++)
				{
						// Get the current word from memory
						c_sdram :> tmp; //data[j];

						// Do something with the data here
						outuint(c_data_read, tmp); //data[j]);
				}

				break;

			// Write the record at 20kHz
			case stop_logging => t when timerafter(time + 5000) :> time: //act_time:

				// Add the record numer to the record
				data[0] = record_number;
				record_number++;

				// Request the data
				outct(c_logging_data, 1);

				// Get the data, apart from the first byte that has the packet id
				for ( i = 1; i < SDRAM_PACKET_NWORDS; i++)
				{
					//data[i] = 0xDEADBEEF;
					data[i] = inuint(c_logging_data);
				}
				
				chkct(c_logging_data,1);

				// Write the record.
				c_sdram <: 1;
				master
				{
					c_sdram <: address;

					for (i = 0; i < SDRAM_PACKET_NWORDS; i++)
					{
						c_sdram <: data[i];
					}
				}

				// Calculate the memory location for the record - it's 16bits wide, so add 64 not 32.
				address = address + (SDRAM_PACKET_NWORDS * 2);

				// If we have stepped off the end of the memory array, go back to the first location
				if ( address >= (SDRAM_NWORDS*2) )
				{
					address = 0;
					stop_logging = 0;
				}

				break;
		}
	}
}
