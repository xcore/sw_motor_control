
.. _motor_control_platform_qs:

Motor Control Platform Quick Start Guide
========================================

.. _motor_control_platform_qs_introduction:

Introduction
------------

The XMOS Motor Control Platform simplifies the development of applications requiring
multi-axis field orientated control of motors, fieldbus and industrial Ethernet.

.. _motor_control_platform_boards:

.. figure:: images/boards-wide.*

   Motor Control Platform

The kit contains the following hardware:

.. points::
  :class: compact

  - A control board comprising a 500MHz XS1-L2 processor, Ethernet interface, CAN interface, a discrete 2-channel 12-bit sample-and-hold ADC, LCD display and XSYS interface
  - A power board comprising 2 motor connectors, 2 connectors for QEI sensors, 6x24V 5A per channel inverters and a 0V zero-crossing detector (up to 1 MHz)
  - 50-way ribbon cable for connecting the control board and power board
  - XTAG-2 debug adapter
  - 24V power supply

The board firmware includes a dual-axis field oriented control application and
simple commutation application for BLDC motors. A single core can 
drive the current loop for a 3-phase BLDC motor at up to 125kHz, with a 
PWM resolution of 4ns. The firmware is built from the following 
software components, which can be used in a wide range of motor
control applications:

.. only:: html

  .. points::
    :class: compact

    - `10/100MBit Ethernet interface </published/ethernet>`_ and `TCP/IP stack </published/tcpip-stack>`_
    - `0.5Mbit CAN interface </published/can>`_
    - 2 Hall sensor inputs
    - 3-phase complementary symmetrical PWM with dead time insertion

.. only:: latex

  .. points::
    :class: compact

    - 10/100MBit Ethernet interface
    - 0.5Mbit CAN interface
    - 2 Hall sensor inputs
    - 3-phase complementary symmetrical PWM with dead time insertion

Multiple chips can be connected to scale to a nearly unlimited number of coordinated 
axes for robotics and other applications, or the control board can be used by 
itself as a generic L2 development platform.

The kit is supported by the following tools:

.. points::
  :class: compact

  - Demo GUI based on LABView run-time, which allows you to control the demo applications from a host PC using the Ethernet or CAN interface.
  - XMOS Development Tools, which provide everything you need to develop your own applications, including an IDE, real-time software scope and timing analyzer.
   
.. _motor_control_platform_qs_setup_hardware_and_run_firmware_demo:

Set up the hardware to run the firmware demo 
--------------------------------------------

The Motor Control Platform comes with a dual-axis FOC application programmed into
flash memory on the control card. To set up the hardware and run this demo, follow
these steps:

.. steps::

  #. Connect the control board interface to the power board interface using the 50-wire ribbon cable.

  #. Connect the 8-wire cable on one of the motors to the MOTOR-1 connector, and
     connect the 4-wire cable to the MOT-1 connector. Connect the second motor
     to the MOTOR-2 and MOT-2 connectors the same way.
  
  #. Connect the 24V supply to the power board, and use a power lead with an IEC 320-C13 connector (also known as a "Kettle Lead", not provided)
     to connect the power supply to a mains outlet.
   
     .. danger::
   
       Do **not** connect the 24V power supply to the control board. The control board takes a 6V power
       supply and will be damaged by 24V. 

On power-up, the motors should start spinning at a demand speed of 1000RPM. The LCD 
shows the speed of each motor, and the demand speed of both. You can use buttons A and
B to alter the demand speed for the system in steps of 100RPM.

.. _motor_control_platform_qs_control_firmware_with_gui:

Control the application using a GUI interface
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

XMOS has developed a demo GUI application that allows you to control the
board from a host PC using either the Ethernet or CAN interface. The GUI application is
available for Windows and requires the LabView 8.1 runtime environment to be installed on 
your PC.

.. only:: html
  
  .. points::
    :class: compact

    - `Download the GUI Interface </partnum/XM-001564-SM>`_
    - `Download the LabView 8.1 runtime environment <http://joule.ni.com/nidu/cds/view/p/id/861/lang/en>`_

.. only:: latex

  .. figure:: images/gui.png
    :width: 100%
	 
    Demo GUI application

  The GUI interface can be downloaded from:
	
  `<http://www.xmos.com/partnum/XM-001564-SM>`_
	
  The LabView 8.1 runtime environment can be downloaded from:

  `<http://joule.ni.com/nidu/cds/view/p/id/861/lang/en>`_

To run the GUI, unzip the download archive to an empty directory and run the file ``MotorControl.exe``.

On launching the GUI, a dialog pops up asking you to select CAN or Ethernet. If you select Ethernet,
you are then asked to provide the IP address of the board. The default firmware uses IP address
169.254.0.1 (a link local IP address).

To use the CAN interface, you must first configure the firmware to use the CAN interface 
(see :ref:`motor_control_platform_qs_configure_application_settings`). LabView supports the Kvaser Leaf Light HS USB to CAN dongle.

.. _motor_control_platform_qs_configure_firmware_demo:

Configure the firmware demo
---------------------------

The firmware demo is provided as a source code archive. To configure,
you should modify the source code for the dual-axis FOC application, 
build the project and load it onto your hardware using the XMOS Development Tools.

.. cssclass:: xde-outside

  .. only:: html
  
    .. points::
      :class: compact

      - `Download the Motor Control Firmware </partnum/XM-000011-SW">`_
      - `Download the XMOS Development Tools <http://www.xmos.com/tools>`_

  .. only:: latex
  
    The motor control firmware is available from:
	
    `<http://www.xmos.com/partnum/XM-000011-SW>`_
	
    The XMOS Development Tools are available from:
   
    `<http://www.xmos.com/tools>`_

  For instructions on installing the tools and XTAG-2 driver, and on starting up the tools, see
  :ref:`installation` and :ref:`get_started`.

.. _motor_control_platform_qs_create_demo_application:
  
Create a demo application
~~~~~~~~~~~~~~~~~~~~~~~~~

.. only:: html

  .. cssclass:: xde-inside

    The firmware is provided as source code, which can be imported from the Developer Column directly into your workspace. To import,
    follow these steps:
	
    .. steps::
  
      #. |new xde project button| `Click here to to launch the **New XDE Project** wizard with L2 Control Board the Dual-Axis Motor Control demo selected </?automate=NewProject&boardid=0003011X&boardstring=L2 Control Board&amp&template=Control Board Demo (Dual Axis FOC Motor Control)">`_.

         If the XDE is unable to connect to the XMOS server, an error message is displayed. Check your network connection
         and click **Retry**.
  
      #. In **Name**, enter a name for the application.
    
      #. To import, click **OK**.
	  
         The XDE creates a new demo application and imports all of the required software components.

.. cssclass:: xde-outside

  You can create a demo application either in the XMOS Development Environment (XDE) or on the command-line. XMOS recommends
  making a copy of the original application so that you can easily revert to the default firmware settings in the future.
  
  **Create an application using the XDE** |XDE icon|

  .. steps::
  
    #. Choose :menuitem:`File,Import`.
    #. Double-click on the **General** option, select **Existing Projects
       into Workspace** and click **Next**.
    #. In the **Import** dialog box, click **Browse** (next to the **Select
       archive file** text box). In the dialog that appears, browse to the directory 
       in which you downloaded the firmware archive, select it (``.zip`` extension) 
       and click **Open**.
    #. Click **Finish**.
	
       The XDE imports a set of projects into your workspace.
	
    #. In the **Project Explorer**, click the folder ``sw_motor_control`` to expand it.
    #. Right-click on the sub-folder ``app_dsc_demo`` and select :menuitem:`Copy`,
       then right-click the folder ``sw_motor_control`` and select :menuitem:`Paste`.
       In the dialog that appears, enter a name for your application and click **OK**.
    #. Double-click on the file ``sw_motor_control/Makefile`` to open it
       in an editor, and ensure that your application is checked as enabled in the build.

  |newpage|
  
  **Create an application on the command line** |CMD icon|
  
  .. steps::
 
    #. Unzip the firmware archive.
   
    #. Change to the directory ``sw_motor_control`` and copy the directory ``app_dsc_demo`` 
       to a new directory. For example, in Linux type the following command:
	   
       :command:`cp -fr app_dsc_demo app_my_demo`

    #. Edit the file ``sw_motor_control/Makefile`` and add the name of your application
       to the ``BUILD_SUBDIRS`` environment variable.

.. _motor_control_platform_qs_configure_application_settings:

Configure your application settings
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Application settings are configured by modifying the source code.

.. paragraph-headings::

  * Change the TCP/IP address

    By default the Ethernet and TCP/IP interface has a statically allocated IP address of 169.254.0.1 (a link local IP address)
    and a net mask of 255.255.0.0.  To change, in your application directory open the file ``src/main.xc`` and search for the function
    ``init_tcp_server`` which contains these values; modify as required.

  * Switch from Ethernet to CAN control

    By default the application is controlled by the buttons around the LCD and the Ethernet interface.
    To use CAN instead, in your application directory open the source file ``src/dsc_config.h``, enable the macro
    ``USE_CAN`` and disable the macro ``USE_ETH``.

The file ``src/dsc_config.h`` contains other compile-time configuration options. These options are described in more detail
in the :ref:`motor control software guide <doc:7328>`.

.. _motor_control_platform_qs_build_and_run_application:

Build and run your application
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. cssclass:: xde-inside

  Once you have configured your application, you must build it into an executable binary
  and load this binary onto your hardware. To build and run, follow these steps:

.. cssclass:: xde-outside

  Once you have configured your application, you must build it into an executable binary
  and load this binary onto your hardware. 

  **To use the XDE** |XDE icon|

.. steps::


  #. Select your application in the **Project Explorer** and click **Build** |-| |button build| |-|.
  
     The XDE builds the firmware, displaying progress in the **Console**. If there are no errors,
     the XDE adds the compiled binary to the application folder ``bin/Debug``.

     .. |button build| image:: images/button-build.*
        :iconmargin:

  #. Ensure that your XMOS XTAG-2 debug adaptor is connected to the XSYS connector 
     on the control board, and use a USB cable (not provided) to connect the adapter to your PC.

  #. Choose :menuitem:`Run,Run Configurations`.

  #. In the left panel, double-click **XCore Application**.

     The XDE creates a new configuration and displays the default
     settings in the right panel.

  #. In **Name**, enter a name such as ``Demo App``.

  #. The XDE tries to identify the target project and executable for you.
     To select one yourself, click **Browse** to the right of the
     **Project** text box and select your project in the **Project
     Selection** dialog box. Then click **Search Project** and select the
     executable file in the **Program Selection** dialog box.

  #. Ensure that the **hardware** option is selected, and in the **Target**
     drop-down list select your target board.
	 
  #. Click **Run**.

     The XDE loads your executable, displaying any output generated by your
     program in the **Console**.  
     
.. cssclass:: xde-outside

  **To use the command-line tools** |CMD icon|
  
  .. steps:: 

    #. Change to your application directory and enter the following command:
  
       :command:`xmake all`

       The tools build your application. If there are no errors, the tools create a
       binary in the sub-folder ``bin/Debug``.

    #. Ensure that your XMOS XTAG-2 debug adaptor is connected to the XSYS connector 
       on the control board, and use a USB cable (not provided) to connect the adapter to your PC.
	   
    #. To run, enter the following command:
  
       :command:`xrun bin/Debug/*binary*.xe`

.. _motor_control_platform_qs_configure_hardware:

Configure the hardware
----------------------

The hardware can be configured by modifying the jumper settings on the control board and power board.

.. _motor_control_platform_qs_control_board_jumper_settings:

Control board jumper settings
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The control board jumper settings are shown in :ref:`sw_motor_control_board`.
Jumper J2 controls the power source for the board.
The board can be powered from either the power board or from a separate 6V power supply.
For the default firmware to run correctly, jumpers J33 and J34 must be set as shown.

.. _sw_motor_control_board:

.. figure:: images/control-jumpers-wide.*

   Control board jumper settings

|newpage|

.. _motor_control_platform_qs_power_board_jumper_settings:

Power board jumper settings
~~~~~~~~~~~~~~~~~~~~~~~~~~~

The power board jumper settings are shown in :ref:`sw_motor_control_power`.
Jumper J6 controls the watchdog protection mode. If enabled, the watchdog circuit is directly connected
to the processor, otherwise you must hold button SW1 on the control board to enable the watchdog connection. 
This latter configuration is useful for testing new software algorithms: hold down the button for normal operation, 
and if an error occurs causing risk of damage to the motors or power board, release the button to prevent the 
FETs from being further engerized.

.. _sw_motor_control_power:

.. figure:: images/power-jumpers-wide.*

   Power board jumper settings

Jumpers J31 to J36 are used to enable either the hall sensors or zero-cross detectors. Note that the default
application firmware does not use the zero-cross detectors.

.. _motor_control_platform_qs_motor_connectors:

Motor connectors
----------------

If one of the 5-wire quadrature cables becomes disconnected from its motor, care must be taken
when reconnecting it to ensure that the alignment flanges on the cable match those on the connector
**before** inserting, as shown in :ref:`sw_motor_control_quad_encoder_connector`.
Inserting the cable incorrectly may permanently damage your hardware.

.. _sw_motor_control_quad_encoder_connector:

.. figure:: images/quadrature.*

  5-wire quadrature encoder connection
	

.. |new xde project button| image:: images/button-new-xde-project.png
   :iconmargin:
   
.. |XDE icon| image:: images/ico-xde.*
   :iconmargin:
   :iconmarginheight: 2
   :iconmarginraise:

.. |CMD icon| image:: images/ico-cmd.*
   :iconmargin:
   :iconmarginheight: 2
   :iconmarginraise: