Application Level Communications Interfaces
===========================================

This module provides a details on the higher application level communication interfaces used in the XMOS Motor Control
Development Platform.

The motor control platform has been written to take advantage of the XMOS Ethernet and XMOS CAN open source components.
With suitable compile time options, the example applications will automatically contain ethernet or CAN control modules.
A high level communication server has been written for each, and these interface to the standard MAC and PHY components
for the two protocols.  These high level server threads are called *do_comms_eth* and *do_comms_can*.

Documentation for the CAN, Ethernet and TCP/IP XMOS components can be found in the software guides for those components,
either on the xmos.com website or from the relevent open source respositories.

A LabView runtime based control application, suitable for both CAN and Ethernet control, is included with the software
release, in the *gui* subdirectory.

do_comms_eth
++++++++++++

The thread do_comms_eth interfaces to the TCP/IP stack and provides a server interface on the TCP port defined by TCP_CONTROL_PORT
(this is typically defined as 9595).  See the documentation for the *sc_xtcp* and *sc_ethernet* modules, which describe the use
of the TCP/IP service and Ethernet services.

After configuring the TCP port and TCP/IP stack interface, the thread sits in a while(1){} loop processing TCP/IP events. 
The following actions are performed based on the event type:


   * ``XTCP_NEW_CONNECTION`` - No action is taken.
   * ``XTCP_RECV_DATA`` - Main processing function, described below.
   * ``XTCP_SENT_DATA`` - Closes the send request by sending a 0 byte packet.
   * ``XTCP_REQUEST_DATA / XTCP_RESEND_DATA`` - Sends the data generated during the XTCP_RECV_DATA event to the client.
   * ``XTCP_CLOSED`` - Closes the connection.


The main processing function receives a packet from the client and processes it, responding with data as appropriate. The
format of the accepted packets are:

``^1|xxxx`` - This sets the speed of the motors to the value given in the 4 digit number. The value is given as a hexadecimal
number.

``^2|`` - This requests the current state of the motor be sent to the remote client.  The server replies with the text string

::

    ^2|aaaa|bbbb|cccc|dddd|eeee|ffff|gggg|hhhh|iiii|jjjj|kkkk|llll|mmmm|nnnn|oo|pp

    aaaa - Speed of motor 1
    bbbb - Speed of motor 2
    cccc - Current Ia for motor 1
    dddd - Current Ib for motor 1
    eeee - Current Ic for motor 1
    ffff - Iq Set Point for motor 1
    gggg - Id output for motor 1
    hhhh - Iq output for motor 1
    iiii - Current Ia for motor 2
    jjjj - Current Ib for motor 2
    kkkk - Current Ic for motor 2
    llll - Iq Set Point for motor 2
    mmmm - Id output for motor 2
    nnnn - Iq output for motor 2
    oo   - Fault flag for motor 1
    pp   - Fault flag for motor 2

The files for this thread are in ``control_comms_eth.xc`` and ``control_comms_eth.h``

do_comms_can
++++++++++++

XMOS provides an independent CAN component in the *sc_can* open source repository. See the documentation for that
component for more details of the CAN PHY interface.

This thread is similar in operation to the do_comms_eth thread, and provides the same interface to the speed_control_loop.

It works by configuring the CAN interface and then sitting in a while(1){} loop receiving packets from the CAN interface.
Once the thread receives a packet from the client, it looks at the command type, and processes it accordingly.

   * If command type (byte 2) equals 1, then this command replies with the current speed and other measured data.
   * If command type (byte 2) equals 2, then this command sets the desired speed from the data supplied in the packet.

The format of a received CAN packet is:

   * 2 bytes - sender address - used to address the return packet if required.
   * 1 byte - command type 
   * 4 bytes - desired speed in big-endian order if command equals 2.

The format of a transmitted CAN packet is:

   * 4 bytes - current speed in big-endian order.
   * 2 bytes - the measured Ia for motor 1.
   * 2 bytes - the measured Ib for motor 1.


The files for this thread are in ``control_comms_can.xc`` and ``control_comms_can.h``



