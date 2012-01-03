===========================================================
Quickstart guide for the XMOS L2 Control Board, version 2.0
===========================================================

Supported hardware
------------------

XMOS Control development platform *XP-MC-CTRL-L2*


Setting up the hardware
-----------------------

  The XMOS L2 control platform comes as a single board. It requires a 6V power supply

      - Connect the XMOS JTAG adaptor to the 20 pin IDC header, and connect it to the PC with a USB cable.

      - Connect a 6V power supply to the board.

   **WARNING** : Do *NOT* put a 24V power supply into the control board. The control board takes a 6V power
   supply and will be damaged by 24V. 
      
   The default application will allow the user to select display of several IO parameters, and allow a TELNET
   client to attach and control the demo.
   

Control board
~~~~~~~~~~~~~

   Jumper J2 must be set to the East position to allow a separate 6V power supply to power the board.
        
   The ADC configuration jumpers, J34 and J35 on the control board must be set as follows in order
   for the default firmware to correctly run.  J34 must be set to *South*, and J35 must be set to *North*. 

   .. image:: control.png
      :width: 100%

   +--------+---------------------------------+----------------------------------------+
   | J2     | *West* - power from Power Board | *East* - power from External connector |
   +--------+---------------------------------+----------------------------------------+
   | J33    | *North* - single ended ADC      | *South* - differential ADC             |
   +--------+---------------------------------+----------------------------------------+
   | J34    | *North* - 0 to 2 Vref ADC range | *South* - 0 - Vref ADC range           |
   +--------+---------------------------------+----------------------------------------+

   .. image:: jumper-2.pdf

   .. image:: jumper-b.pdf


Configuring the firmware
------------------------

  The default firmware comes from the application directory called **app_control_board_demo**.  
      
  Changing the TCP/IP address
    By default the ethernet and TCP/IP interface uses DHCP to try to get an IP address.
    To change this, edit the file **app_control_board_demo/src/main.xc**.
    Contained in this file is the address configuration structure which is passed to the TCP/IP module, in a function called
    **init_tcp_server()**.

Building the firmware
---------------------

  The XTAG-2 debug adapter supplied with the kit can be connected to the board to provide a JTAG interface from
  your development system that you can use to load and debug software. You need to install a set of drivers for
  the XTAG-2 debug adapter and download a set of free Development Tools (11.11 or later) from the XMOS website:

    http://www.xmos.com/tools

  Instructions on installing and using the XMOS Tools can be found in the XMOS Tools
  User Guide http://www.xmos.com/published/xtools_en.


  Once the software is configured as required, the system can be built by executing the following make command in an XMOS
  Tools Prompt.  The command should be executed in the root directory, or the **app_control_board_demo** directory.

    *xmake all*

  The command will build the software and produce an executable file:
  
    *app_control_board_demo/bin/Release/app_control_board_demo.xe*

  Alternatively, the project can be imported into the XDE tool. Once it is imported, the sw_motor_control project can
  be selected, and the options for building and running each application can be selected.
  To install the software, open the XDE (XMOS Development Tools) and
  follow these steps:

  - Choose *File* > *Import*.
  - Choose *General* > *Existing Projects into Workspace* and click *Next*.
  - Click *Browse* next to *Select archive file* and select the file firmware ZIP file.
  - Make sure the projects you want to import are ticked in the *Projects* list. Import
    all the components and whichever applications you are interested in. 
  - Click *Finish*.

  To build, select the appropriate project in the Project Explorer and click the *Build* icon.

Running the firmware
--------------------

  The example application can be run on the hardware by executing the following command within an XMOS command line:

    *xrun app_control_board_demo/bin/Release/app_control_board_demo.xe*

  Alternatively, from within the XDE:

    - Right click on the binary within the project.
    - Choose *Run As* > *Run Configurations*
    - Choose *hardware* and select the relevant XTAG-2 adapter
    - Select the *Run UART server* check box.
    - Click on *Apply* if configuration has changed
    - Click on *Run*

  LCD feedback
    The LCD shows the current mode and any readings appropriate to that mode.

  Controlling the mode
    The A and B buttons allow the user to cycle between each mode.  The modes are:
    
    *  Startup screen and TCP/IP address display
    *  ADC value value readout
    *  Hall sensor value readout
    *  PWM channel 1 control
    *  PWM channel 2 control
    *  QEI value readout

    In the PWM channel control modes, buttons C and D will change the PWM duty cycle in a pre-defined pattern.
    
Specific details for each mode
------------------------------

Startup and TCP/IP address readout
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The TCP/IP address will either be statically or dynamically assigned.  By default, the firmware will attempt to
use dynamic configuration.  If a DHCP server is not found, then a link local IP address will eventually be
assigned. 

The readout changes to show the IP address whenever it is assigned.

ADC readout
~~~~~~~~~~~

The ADC has two channels of ADC, each of which can be multiplexed to one of two sources. 
The display shows two lines, prefixed with M1 and M2.  The M1 line shows the measured
ADC values of *M1_PH_A_CRNT* and *M1_PH_B_CRNT* from the control board connector.  Likewise,
the M2 line shows the values of *M2_PH_A_CRNT* and *M2_PH_B_CRNT*.

Hall sensor readout
~~~~~~~~~~~~~~~~~~~

The hall sensor readout shows two values, the hall sensor values read from the control board
connector.

The Hall1 line shows the value from the 4 bit port consisting of signals (*M1_OC_FAULT*, *E_HS2_M1*,
*E_HS1_M1*, *E_HS0_M1*).  Likewise, the Hall2 line shows the values of the signals (*M2_OC_FAULT*, *E_HS2_M2*,
*E_HS1_M2*, *E_HS0_M2*). 

PWM controllers
~~~~~~~~~~~~~~~

When selected, the display shows the current PWM duty cycles, represented as their 24 bit unsigned
values, as the PWM API requires.  For the PWM channel 1 controller, the six signals on the
control board connector are (*ISO_M1_LOA*, *ISO_M1_HIA*, *ISO_M1_LOB*, *ISO_M1_HIB*, *ISO_M1_LOC*, *ISO_M1_HIC*).
Likewise, the control signals modified by the PWM channel 2 controller are (*ISO_M2_LOA*, *ISO_M2_HIA*,
*ISO_M2_LOB*, *ISO_M2_HIB*, *ISO_M2_LOC*, *ISO_M2_HIC*).

Pressing the C and D buttons will change the duty cycles through the following table.

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

QEI readout
~~~~~~~~~~~

By attaching QEI devices to the QEI signals on the control board connector, the position
of the two devices will be displayed.

The QEI signals are (*ISO_M1ENCO_I*, *ISO_M1ENCO_A*, *ISO_M1ENCO_B*) for the first QEI device, and
(*ISO_M2ENCO_I*, *ISO_M2ENCO_A*, *ISO_M2ENCO_B*) for the second.

The I signals are the index signals, which should pulse once per revolution at the zero
point.  The A and B are the quadrature channels.

Further reading
---------------

Visit *http://www.xmos.com/applications/motor-control* for further information and updates.




