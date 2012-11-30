/**
 * Module:  module_dsc_qei
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

/*****************************************************************************\
	This code is designed to work on a Motor with a Max speed of 4000 RPM,
	and a 1024 counts per revolution.

	The QEI data is read in via a 4-bit port. With assignments as follows:-

	 bit_3   bit_2   bit_1    bit_0
	-------  -----  -------  -------
  Un-used  Index  Phase_B  Phase_A

	In normal operation the B and A bits change as a grey-code,
	with the following convention

			  ----------->  Counter-Clockwise
	BA:  00 01 11 10 00
			  <-----------  Clockwise

	During one revolution, BA will change 1024 times,
	Index will take the value of zero 1023 times, and the value one once only,
  at the position origin. 
	NB When the motor starts, it is NOT normally at the origin

	A look-up table is used to encode the above 3 input bits, into 3 output bits
	with the following meanings:

	  bit_2      bit_1     bit_0
	---------  ----------  -----
  Not-Index  Anit-Clock  Error

	Bit_2 is Zero, when Index detected
  Bit_1 is Zero, fir clockwise direction
	Bit_0 is Zero, for normal sequence of BA bits
 
\*****************************************************************************/

#include <stdio.h>
#include <assert.h>

#include <xs1.h>
#include "qei_server.h"
#include "qei_commands.h"
#include "dsc_config.h"

#ifndef NUMBER_OF_MOTORS
#define NUMBER_OF_MOTORS 1
#endif

// This is the loop time for 4000RPM on a 1024 count QEI
#pragma xta command "analyze loop qei_main_loop"
#pragma xta command "set required - 14.64 us"

// Order is 00 -> 10 -> 11 -> 01  Clockwise direction
// Order is 00 -> 01 -> 11 -> 10  Anti-Clockwise direction
// 6 signals Forward direction
// 4 signals Reverse direction
// 5 signals Error condition

static const unsigned char lookup[8][4] = {
		{ 5, 4, 6, 5 }, // 00 00
		{ 6, 5, 5, 4 }, // 00 01
		{ 4, 5, 5, 6 }, // 00 10
		{ 5, 6, 4, 5 }, // 00 11
		{ 0, 0, 0, 0 }, // 01 xx
		{ 0, 0, 0, 0 }, // 01 xx
		{ 0, 0, 0, 0 }, // 01 xx
		{ 0, 0, 0, 0 }, // 01 xx
};


#pragma unsafe arrays
void do_qei ( streaming chanend c_qei, port in pQEI )
{
	unsigned pos = 0, v, ts1, ts2, ok=0, old_pins=0, new_pins;
	timer t;

	pQEI :> new_pins;
	t :> ts1;

	while (1) {
#pragma xta endpoint "qei_main_loop"
		select {
			case pQEI when pinsneq(new_pins) :> new_pins :
			{
				new_pins &= 0x7; // Clear Un-used bit_3

				if ((new_pins & 0x3) != old_pins) {
					ts2 = ts1;
					t :> ts1;
				}
				v = lookup[new_pins][old_pins];
				if (!v) {
					pos = 0;
					ok = 1;
				} else {
					{ v, pos } = lmul(1, pos, v, -5);
				}
				old_pins = new_pins & 0x3;
			}
			break;
			case c_qei :> int :
			{
				c_qei <: pos;
				c_qei <: ts1;
				c_qei <: ts2;
				c_qei <: ok;
			}
			break;
		}
	}
}

#pragma unsafe arrays
void do_multiple_qei ( streaming chanend c_qei[], port in pQEI[] )
{
	unsigned pos[NUMBER_OF_MOTORS], v, ts1[NUMBER_OF_MOTORS], ts2[NUMBER_OF_MOTORS];
	unsigned ok[NUMBER_OF_MOTORS], old_pins[NUMBER_OF_MOTORS], new_pins[NUMBER_OF_MOTORS];
	unsigned cur_pins;
	timer t;

	for (int q=0; q<NUMBER_OF_MOTORS; ++q) {
		old_pins[q] = 0;
		pQEI[q] :> new_pins[q];
		t :> ts1[q];
		pos[q] = 0;
		ok[q] = 0;
	}

	while (1) {
#pragma xta endpoint "qei_main_loop"
		select {
			case (int q=0; q<NUMBER_OF_MOTORS; ++q) pQEI[q] when pinsneq(new_pins[q]) :> new_pins[q] :
			{
				cur_pins = new_pins[q] & 0x7; // Clear Un-used bit_3

				if ((cur_pins & 0x3) != old_pins[q]) {
					ts2[q] = ts1[q];
					t :> ts1[q];
				}
				v = lookup[cur_pins][old_pins[q]];
				if (!v) {
					pos[q] = 0;
					ok[q] = 1;
				} else {
					{ v, pos[q] } = lmul(1, pos[q], v, -5);
				}
				old_pins[q] = cur_pins & 0x3;
			}
			break;
			case (int q=0; q<NUMBER_OF_MOTORS; ++q) c_qei[q] :> int :
			{
				c_qei[q] <: pos[q];
				c_qei[q] <: ts1[q];
				c_qei[q] <: ts2[q];
				c_qei[q] <: ok[q];
			}
			break;
		}
	}
}


