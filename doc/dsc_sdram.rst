=======================
DSC SDRAM specification
=======================


:version: 1.1.1

+------------+---------+-------------------------------------------------+----+
| 2010/10/19 | 1.1.1   | Note about debug interrupts                     | LS |
+------------+---------+-------------------------------------------------+----+
| 2010/10/19 | 1.1     | Read goes into self refresh too (bug fix)       | LS |
+------------+---------+-------------------------------------------------+----+
| 2010/10/14 | 1.0.1   | Updates to interface, sync with dsc_sdram.h     | LS |
+------------+---------+-------------------------------------------------+----+
| 2010/10/11 | 1.0     | Initial version                                 | LS |
+------------+---------+-------------------------------------------------+----+


For DSC 1V0 release (November 2010)
===================================


Operation
---------

Only logging.

Driver writes log entries into specified addresses and puts SDRAM into self-refresh mode when not in use. It can also read the whole SDRAM.

Writes are short bursts of ``N`` 32-bit words, ``N`` being a compile time option with some minimum value (3).

A read returns all data from SDRAM. Implementation operates in 128-byte buffer chunks so that client does not stall the SDRAM inside an I/O loop. Self refresh is entered between chunks to allow client to take time to process data.


Performance
-----------

Expecting 12.5 MB/s write bandwidth. Read bandwidth can be lower, which is ok.

Log entries are received, written into SRAM and then copied from SRAM into SDRAM. This reduces link utilisation and brings overall data rate down to less than a half of the 12.5 MB/s bandwidth. That should still be ok.


Failure recovery
----------------

The idea is to be able to read the SDRAM by sending a request via Ethernet after a failure.

A failure is defined as something bad happenning to the L1 (motor control core).

The SDRAM driver, Ethernet driver, and related parts of the L2 (services core) must stay in a healthy state for the read request to come through and be processed. Shared memory between these parts and the rest of the system is recommended as means of decoupling (channels are blocking and not suitable for fault tolerance).


Interface
---------

Channel (see discussion above)::

         void sdram(chanend c_sdram);

.. BEGIN COPY-AND-PASTE FROM HEADER FILE

Write a packet::

         c_sdram <: 1;
         master {
              c_sdram <: address;
              for (i = 0; i < SDRAM_PACKET_NWORDS; i++) {
                  c_sdram <: packet[i];
              }
         }

Read all contents::

         c_sdram <: 2;
         slave {
              for (i = 0; i < SDRAM_NWORDS; i++) {
                  c_sdram :> word;
              }
         }

Address structure::

         col | (row << log2(SDRAM_NCOLUMNS)) | (bank << (log2(SDRAM_NCOLUMNS) + log2(SDRAM_NROWS)))

Addressing SDRAM locations, so for example for a byte-wide SDRAM the address is a byte address.

NOTE: debug interrupts (like calls to print.h) may interrupt the I/O loop, which will in turn corrupt the data since the SDRAM stops self refreshing.

.. END COPY-AND-PASTE FROM HEADER FILE
