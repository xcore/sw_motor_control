
.. _l2_control_board_qs:

L2 Control Board Quick Start Guide
==================================

.. _l2_control_board_qs_introduction:

Introduction
------------

The XMOS L2 control board can be used to develop Ethernet and CAN based products based on
an XMOS XS1-L2 device.

.. _l2_control_board_qs_boards:

.. figure:: images/ctrl-board.*

   L2 control board

The kit consists of the following hardware:

.. points::
  :class: compact

  - A control board comprising a 500MHz XS1-L2 processor, Ethernet interface, CAN interface, a discrete 2-channel 12-bit sample-and-hold ADC, LCD display and XSYS interface
  - XTAG-2 debug adapter
  - 6V power supply

|newpage|

The board firmware includes a set of demo applications based on the following software components:

.. points::
  :class: compact

  - 10/100MBit Ethernet and TCP/IP interface
  - 3-phase complementary symmetrical PWM with dead time insertion

The kit is supported by the XMOS Development Tools, which provide everything you need to 
develop your own applications, including an IDE, real-time software scope and timing analyzer.
   
.. _l2_control_board_qs_setup_hardware_and_run_firmware_demo:

Set up the hardware and run the firmware demo 
---------------------------------------------

To set up the hardware and run this demo, follow these steps:

.. steps::

  #. Connect a host PC to the 10/100 ENET connector using an Ethernet cable.

  #. Connect the 6V supply to the bard.

On power-up, the LCD shows the current measurement mode and readings.
You can use buttons A and B to cycle between modes as follows.
  
.. paragraph-headings::

  * Startup screen and TCP/IP address display

    By default, the firmware attempts to acquire an IP address using DHCP. If a DHCP server is
    not found, a link local IP address is eventually assigned. The display is updated to
    show the IP address when it is assigned.

  *  ADC value readout
  
     The ADC has two channels, each of which can be multiplexed to one of two sources. 
     The LCD shows two lines, prefixed with M1 and M2. The M1 line shows the measured
     values of interface pins [1,2], and the M2 line shows the values
     of interface pins [4,5].
  
  *  Hall value readout

     The LCD shows two values, prefixed with Hall1 and Hall2. The Hall1 line shows
     the 4-bit value sampled on interface pins [45,41,40,39], and the Hall2 line shows the
     4-bit value sampled on pins [46,44,43,42].

  *  PWM channel 1 control, PWM channel 2 control
  
     The firmware outputs two 24-bit PWM pulse trains. The first channel is output on
     pins [27..32], the second on pins [33..38].
     
     |newpage|
	 
     The LCD shows the current PWM duty cycles.
     Pressing the C and D buttons changes the duty cycles through the following pattern.

     +-------+-------+-------+
     | 0x100 | 0x100 | 0x100 |
     +-------+-------+-------+
     | 0x800 | 0x100 | 0x100 |
     +-------+-------+-------+
     | 0x800 | 0x800 | 0x100 |
     +-------+-------+-------+
     | 0x000 | 0x800 | 0x100 |
     +-------+-------+-------+
     | 0x100 | 0x800 | 0x800 |
     +-------+-------+-------+
     | 0x100 | 0x100 | 0x800 |
     +-------+-------+-------+
     | 0x800 | 0x100 | 0x800 |
     +-------+-------+-------+
     | 0xF00 | 0x100 | 0xF00 |
     +-------+-------+-------+
     | 0xF00 | 0x100 | 0x100 |
     +-------+-------+-------+
     | 0xF00 | 0xF00 | 0x100 |
     +-------+-------+-------+
     | 0x100 | 0xF00 | 0x100 |
     +-------+-------+-------+
     | 0x100 | 0xF00 | 0xF00 |
     +-------+-------+-------+
     | 0x100 | 0x100 | 0xF00 |
     +-------+-------+-------+
  
  * QEI value readout

    Up to 2 QEI encoders may be attached, one to pins [21..19] and the other to pins [24..22].
    If attached, the LED displays the position of the two encoders.
	
    Pins 21 and 24 are I signals, which should pulse once per revolution at the zero point.
    The other pins are the quadrature channels.
	

.. _l2_control_board_qs_configure_hardware:

Jumper settings
---------------

The jumper settings are shown in :ref:`l2_control_board_qs_control_jumpers`.
Jumpers J2 and J34 should be set as shown. Jumper J33 controls the ADC range.

.. _l2_control_board_qs_control_jumpers:

.. figure:: images/ctrl-control-jumpers.*

   Control board jumper settings
