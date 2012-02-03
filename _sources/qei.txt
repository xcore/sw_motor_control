Quadrature Encoder Input
========================

The quadrature encoder input (QEI) module is provided with a library for both running the thread that handles the direct interface to the pins and also for retrieving
and calculating the appropriate information from that thread. 

The particular interface that is implemented utilises three signals comprising of two quadrature output (A and B) and an index output (I). A and B provide incremental
information while I indicates a return to 0 or origin. The signals A and B are provided out of phase so that the direction of rotation can be resolved.

  .. image:: images/QeiOutput.pdf
     :align: center

Configuration
+++++++++++++

The QEI module provides one or multiple QEI device versions of the server. If more than one QEI device is interfaced to the XMOS device, then the designer can
opt to use multiple single-device QEI server threads, or one multi-device thread.

The multiple-QEI service loop has a worst-case timing of 1.4us, therefore being able to service two 1024 position QEI devices spinning at 20kRPM.

|newpage|

QEI Server Usage
++++++++++++++++

To initiate the service the following include is required as well as the function call shown. This defines the ports that are required to read the interface and
the channel that will be utilised by the client thread.  The compile time constant *NUMBER_OF_MOTORS* is used to determine how many clients and ports are
serviced by the multi-device QEI server.

::

  #include "qei_server.h"

  void do_qei( streaming chanend c_qei, port in pQEI);

  void do_qei_multiple( streaming chanend c_qei[NUMBER_OF_MOTORS], port in pQEI[NUMBER_OF_MOTORS]);
 


QEI Client Usage
++++++++++++++++

To access the information provided by the quadrature encoder the functions listed below can used.

::

  #include "qei_client.h"

  { unsigned, unsigned, unsigned } get_qei_data( chanend c_qei );


The three values are the speed, position and valid state. The position value is returned as a count
from the index zero position and speed is returned in revolutions per minute (RPM). 

The third value indicates whether the QEI interface has received an index signal and therefore that the position is
valid.


