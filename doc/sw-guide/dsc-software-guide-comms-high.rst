Application Level Communications Interfaces
===========================================

This module provides a details on the higher application level communication interfaces used in the XMOS Motor Control Development Platform.
The figure below shows the main threads that are used.

  .. figure:: images/comms_threads.png


The ethernet_server and uip_server threads are the Ethernet and TCP/IP interface, as detailed in the previous section.
The speed_control_loop and run_motor threads are the outer and inner control loops for the motors.
The canPhyRxTx is the CAN interface, as previously discussed.


do_comms_eth
++++++++++++

The thread do_comms_eth interfaces to the TCP/IP stack and provides a server interface on the TCP port defined by TCP_CONTROL_PORT (this is typically defined as 9595).

After configuring the TCP port and TCP/IP stack interface, the thread just sits in a while(1){} loop processing TCP/IP events. 
The following actions are performed based on the event type:


   * XTCP_NEW_CONNECTION - Prints the IP address that the connection is from to the debug output.
   * XTCP_RECV_DATA - Main processing function, described below.
   * XTCP_SENT_DATA - Closes the send request by sending a 0 byte packet.
   * XTCP_REQUEST_DATA / XTCP_RESEND_DATA - Sends the data generated during the XTCP_RECV_DATA event to the client.
   * XTCP_CLOSED - Closes the connection and prints the IP address that the connection was from to the debug output.


The main processing function, receives a packet from the client and processes it according to the criteria below: 

   * if the packets starts "go" then this signals a new connection and nothing is done.
   * if the packets starts "set" then the next four little-endian ordered bytes are converted into the desired speed and sent to the speed_control_loop thread.
   * if the packets starts "speed" then the current and desired speeds from the speed_control_loop thread are placed in little-endian order into a packet of length 8 bytes and flagged to be returned to the client.
   * if the packets starts "stop" then the connection is closed.


The files for this thread are in ``control_comms_eth.xc`` and ``control_comms_eth.h``

do_comms_can
++++++++++++

This thread is similar in operation to the do_comms_eth thread, and provides the same interface to the speed_control_loop.

It works by configuring the CAN interface and then sitting in a while(1){} loop receiving packets from the CAN interface.
Once the thread receives a packet from the client, it looks at the command type, and processes it accordingly.

   * If command type (byte 2) equals 1, then this command sends the current speed and desired speed to the client.
   * If command type (byte 2) equals 2, then this command sets the desired speed from the data supplied in the packet.

The format of a received CAN packet is:

   * 2 bytes - sender address - used to address the return packet if required.
   * 1 byte - command type 
   * 4 bytes - desired speed in big-endian order if command equals 2.

The format of a transmitted CAN packet is:

   * 4 bytes - current speed in big-endian order.
   * 4 bytes - desired speed in big-endian order.


The files for this thread are in ``control_comms_can.xc`` and ``control_comms_can.h``



