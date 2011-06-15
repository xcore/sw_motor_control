/* Micron MT48 SDRAM, 16-bit data */

#include <platform.h>
#include "dsc_sdram.h"

#if SDRAM_PACKET_NWORDS <= 3
#error "packet size min 3 words"
#endif

#define CLOCK_DIVIDE 4
#define CYCLE_NS (20 * CLOCK_DIVIDE)


static void uswait(int us)
{
  timer T;
  int t;
  T :> t;
  us = 10;
  for (int i = 0; i < us; i++)
  {
#ifndef CHIPLVL
      T when timerafter(t + 100) :> t;
#endif
  }
}

// Function prototypes for assembler
void write_asm(port dq, out port cke, out buffered port:4 we, out buffered port:4 ras, out buffered port:4 cas, out port a, const int packet[], int packet_nwords, int row_bank, int col_bank);
void read_asm(port dq, out port cke, out buffered port:4 we, out buffered port:4 ras, out buffered port:4 cas, out port a, int buffer[], int row_bank, int col_bank);


// Function to write 1 record of SDRAM_PACKET_NWORDS to memory
#pragma unsafe arrays
static inline void write(chanend c, port dq, out port cke, out port dqml, out port dqmh, out buffered port:4 we, out buffered port:4 ras, out buffered port:4 cas, out port a)
{
  int address;
  int row_bank, col_bank;
  int packet[SDRAM_PACKET_NWORDS];

  slave {
    c :> address;
    for (int i = 0; i < SDRAM_PACKET_NWORDS; i++) {
      c :> packet[i];
    }
  }
  row_bank = address >> SDRAM_BCOLUMNS;
  col_bank = (row_bank & ~((1 << SDRAM_BROWS) - 1)) | (address & ((1 << SDRAM_BCOLUMNS) - 1));

  /*
  time     0    8        9         10           11          N+9   N+10       N+11        N+12     N+13
  command  NOP  REFRESH  ACTIVE    WRITE        NOP  ...    NOP   TERMINATE  PRECHARGE   REFRESH  NOP
  WE       1    1        1         0            1           1     0          0           1        1
  RAS      1    0        0         1            1           1     1          0           0        1
  CAS      1    0        1         0            1           1     1          1           0        1
  CKE      1                                                                             0
  A                      row&bank  column&bank                               all banks*
  DQ                               data1        data2       dataN
  DQM      low
                                * all banks must be precharged before refresh
  */
#define PACKET_WRITE_NS ((SDRAM_PACKET_NWORDS * 2 + 6) * CYCLE_NS)

#if 0
  a <: row_bank;
  cke <: 1 @ t0;

  t = t0 + 8;
  we @ t <: 0b1011;
  ras @ t <: 0b1100;
  cas @ t <: 0b1010;

  t = t0 + 10;
  a @ t <: col_bank;
  dq @ t <: packet[0];

  t = t0 + 10 + SDRAM_PACKET_NWORDS * 2;
  we @ t <: 0b1100;
  dq <: packet[1];
  ras @ t <: 0b1001;
  cas @ t <: 0b1011;
  dq <: packet[2];
  a <: 0x400;
  t = t + 2;
  cke @ t <: 0;

  for (i = 3; i < SDRAM_PACKET_NWORDS; i++) {
    dq <: packet[i];
  }
#else
  /* handcoded implementation */
  /* pending compiler optimisations */
  write_asm(dq, cke, we, ras, cas, a, packet, SDRAM_PACKET_NWORDS, row_bank, col_bank);
#endif
}


// Function to read all of memory
#pragma unsafe arrays
static inline void read(chanend c, port dq, out port cke, out port dqml, out port dqmh, out buffered port:4 we, out buffered port:4 ras, out buffered port:4 cas, out port a)
{
    for (int bank = 0; bank < SDRAM_NBANKS; bank++)
    {
      for (int row = 0; row < SDRAM_NROWS; row++)
      {
        for (int column = 0; column < SDRAM_NCOLUMNS; column += 64)
        {
          int t0, t;
          int x, j;

          /* 32 words at a time */
          int buffer[32];

          int row_bank = row | (bank << SDRAM_BROWS);
          int col_bank = column | (bank << SDRAM_BROWS);

          /*
          time     0    8        9         10           11   12       73     74         75          76       77
          command  NOP  REFRESH  ACTIVE    READ         NOP  NOP ...  NOP    TERMINATE  PRECHARGE   REFRESH  NOP
          WE       1    1        1         1            1    1        1      0          0           1        1
          RAS      1    0        0         1            1    1        1      1          0           0        1
          CAS      1    0        1         0            1    1        1      1          1           0        1
          CKE      1                                                                                0
          A                      row&bank  column&bank                                  all banks*
          DQ                               pre-read          data1    data30 data31     data32
          DQM      low
                                * all banks must be precharged before refresh
          */
#define PACKET_READ_NS ((32 * 2 + 10) * CYCLE_NS)

#if 0
          a <: row_bank;
          cke <: 1 @ t0;

          t = t0 + 8;
          we @ t <: 0b1111;
          ras @ t <: 0b1100;
          cas @ t <: 0b1010;

          t = t0 + 10;
          a @ t <: col_bank;

          t = t0 + 11;
          dq @ t :> void;
          dq :> buffer[0];

          t = t0 + 74;
          we @ t <: 0b1100;
          dq :> buffer[1];
          ras @ t <: 0b1001;
          cas @ t <: 0b1011;
          dq :> buffer[2];
          a <: 0x400;
          t = t + 2;
          cke @ t <: 0;

          for (int i = 3; i < 32; i++) {
            dq :> buffer[i];
          }
#else
          /* handcoded implementation */
          /* pending compiler optimisations */
          read_asm(dq, cke, we, ras, cas, a, buffer, row_bank, col_bank);
#endif
          /* turn back to output - dq is expected to be an output port */
          dq <: 0;

          /* staying in self refresh, other side can take time */
          for (int i = 0; i < 32; i++) {
            c <: buffer[i];
          }
        }
      }
    }
}


// make sure there enough refresh rates during reads and writes
#define REFRESH_MAX_NS (SDRAM_T_REF_MS * 1000000 / SDRAM_NROWS)
#if PACKET_WRITE_NS >= REFRESH_MAX_NS
#error "insufficient refresh rate during write - decrease packet size?"
#endif
#if PACKET_READ_NS >= REFRESH_MAX_NS
#error "insufficient refresh rate during read"
#endif


// Function to initiate the memory interface
static inline void init(port dq, out port cke, out port dqml, out port dqmh, out port clk, out buffered port:4 we, out buffered port:4 ras, out buffered port:4 cas, out buffered port:4 cs, out port a, clock b)
{
  int t;

  /* ports and clock blocks */
  /* do not start clock yet */
  asm("setc res[%0], 0x200F" :: "r"(dq));
  asm("settw res[%0], %1" :: "r"(dq), "r"(32));
  set_clock_div(b, CLOCK_DIVIDE);
  set_port_clock(dq, b);
  set_port_clock(cke, b);
  set_port_clock(dqml, b);
  set_port_clock(dqmh, b);
  set_port_clock(clk, b);
  set_port_clock(we, b);
  set_port_clock(ras, b);
  set_port_clock(cas, b);
  set_port_clock(cs, b);
  set_port_clock(a, b);
  start_clock(b);

  /* all signals to defaults, command to INHIBIT */
  cs <: 0xFF;
  dq <: 0;
  cke <: 0;
  dqml <: 1;
  dqmh <: 1;
  clk <: 0;
  we <: 0xFF;
  ras <: 0xFF;
  cas <: 0xFF;
  a <: 0;

  /* start clock and provide 100us for SDRAM start up */
  /* assert CKE in between */
  uswait(100);
  set_port_mode_clock(clk);
  uswait(100);
  cke <: 1;
  uswait(100);

  /* PRECHARGE all banks (A10=1) and wait 20ns */
  /* 2 x AUTOREFRESH with at least 66ns in between */
  /* continue with NOP instead of INHIBIT */
  a <: (1 << 10);
  cs <: 0xFF @ t;
  t += 20;
  cs @ t <: 0x00;
  we @ t <: 0xFE;
  ras @ t <: 0xFE;
  cas @ t <: 0xFF;
  sync(cas);
  cs <: 0x00 @ t;
  t += 20;
  we @ t <: 0xFF;
  ras @ t <: 0xFE;
  cas @ t <: 0xFE;
  we <: 0xFF;
  ras <: 0xFE;
  cas <: 0xFE;
  sync(cas);

  /* assert DQM */
  dqml <: 0;
  dqmh <: 0;

  /* configuration */
  /* settings: CL2, continuous sequential programmed burst */
  a <: 0x0027;  /* 000|0|00|010|0|111 */
  cs <: 0x00 @ t;
  t += 20;
  we @ t <: 0xFE;
  ras @ t <: 0xFE;
  cas @ t <: 0xFE;
  sync(cas);

  /* initially not in self refresh mode - SDRAM is empty */
}


// Main SDRAM server_thread
void sdram_server(chanend c_sdram, REFERENCE_PARAM(sdram_interface_t, p))
{
	int cmd;

	// Initiate the memory
	init(p.p_sdram_dq, p.p_sdram_cke, p.p_sdram_dqml, p.p_sdram_dqmh, p.p_sdram_clk, p.p_sdram_we, p.p_sdram_ras, p.p_sdram_cas, p.p_sdram_cs, p.p_sdram_a, p.b_sdram);

	// Loop forever
	while (1)
	{
		// Get a command
		c_sdram :> cmd;

		// Do the correct thing for the command or trap
		switch (cmd)
		{
			case 1: write(c_sdram, p.p_sdram_dq, p.p_sdram_cke, p.p_sdram_dqml, p.p_sdram_dqmh, p.p_sdram_we, p.p_sdram_ras, p.p_sdram_cas, p.p_sdram_a); break;
			case 2: read(c_sdram, p.p_sdram_dq, p.p_sdram_cke, p.p_sdram_dqml, p.p_sdram_dqmh, p.p_sdram_we, p.p_sdram_ras, p.p_sdram_cas, p.p_sdram_a); break;
			default: asm("ecallf %0" :: "r"(0)); break;
		}
	}
}
