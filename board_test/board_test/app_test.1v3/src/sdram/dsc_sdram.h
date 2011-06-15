#ifndef SDRAM_H_
#define SDRAM_H_

#include <xccompat.h>

	// Define how big the SDRAM packets of data are. Currently 32 words = 128 bytes.
	#define SDRAM_PACKET_NWORDS 32

	// For Micron MT48LC16M16 256Mbit
	#define SDRAM_BROWS        13
	#define SDRAM_BCOLUMNS     9
	#define SDRAM_NROWS        (1 << SDRAM_BROWS)
	#define SDRAM_NCOLUMNS     (1 << SDRAM_BCOLUMNS)
	#define SDRAM_NBANKS       4
	#define SDRAM_T_REF_MS     64

	#define SDRAM_NWORDS (SDRAM_NROWS * SDRAM_NCOLUMNS * SDRAM_NBANKS / 2)

	#ifdef __XC__
		typedef struct sdram_interface_t
		{
			port p_sdram_dq;
			out port p_sdram_cke;
			out port p_sdram_dqml;
			out port p_sdram_dqmh;
			out port p_sdram_clk;
			out buffered port:4 p_sdram_we;
			out buffered port:4 p_sdram_ras;
			out buffered port:4 p_sdram_cas;
			out buffered port:4 p_sdram_cs;
			out port p_sdram_a;
			clock b_sdram;
		} sdram_interface_t;

		void sdram_server(chanend c_sdram, REFERENCE_PARAM(sdram_interface_t, p));
	#endif

	/*
	Write a packet::

		c_sdram <: 1;
		master
		{
			c_sdram <: address;
			for (i = 0; i < SDRAM_PACKET_NWORDS; i++)
			{
				c_sdram <: packet[i];
			}
		}

	Read all contents::

		c_sdram <: 2;

		for (i = 0; i < SDRAM_NWORDS; i++)
		{
			c_sdram :> word;
		}

	Address structure::

			 col | (row << log2(SDRAM_NCOLUMNS)) | (bank << (log2(SDRAM_NCOLUMNS) + log2(SDRAM_NROWS)))

	Addressing SDRAM locations, so for example for a byte-wide SDRAM the address is a byte address.
	*/

#endif /* SDRAM_H_ */
