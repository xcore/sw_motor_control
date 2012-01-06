==================================================================
Quick start guide for the XMOS Motor Control platform, version 2.0
==================================================================

Supported hardware
------------------

XMOS Bushless DC Motor Control development platform *XK-MC-LVM2*.

Configure the hardware
----------------------

The XMOS Brushless DC Motor development platform consists of two separate boards, as shown in
:ref:`sw_motor_control_boards`.

.. _sw_motor_control_boards:

.. figure:: images/boards.*

   Motor control development platform

To configure the hardware, follow these steps:

.. steps::

  #. Connect the power board to the control board with the 50-way ribbon cable.

  #. Connect the first motor to the MOTOR1 connector on the power board, and the second motor to
     the MOTOR2 connector.
        
  #. Connect the quadrature encoder connections from each motor to the power board.  

  #. Connect the XMOS XTAG-2 debug adaptor to the 20 pin XSYS header, and use a USB cable to connect the adapter to your PC.

  #. Connect a 24V power supply to the power section of the BLDC board.
   
.. danger::
   
   Do **not** put the 24V power supply into the control board. The control board takes a 5V power
   supply and will be damaged by 24V. 
      
The demo application spins the motors using a field-oriented control algorithm.  The display shows
the speed of each motor, and the demand speed of both.  Buttons A and B alter the demand speed for the system.

Control board
~~~~~~~~~~~~~

By default, the power board provides power to the control board. Jumper J2 can be set to the alternative (East)
position to allow a separate 5V power supply to be provided to the control board, as shown in :ref:`sw_motor_control_j2`.

.. _sw_motor_control_j2:

.. figure:: images/jumper-2.*

   Jumper J2 configuration
		
The ADC configuration jumpers J33 and J34 on the control board must be set as follows in order
for the default firmware to run correctly.  J33 must be set to *South*, and J34 must be set to *North*. 

.. figure:: images/jumper-b.*

   Jumper J34 and J35 configuration


   .. image:: images/control.png
      :width: 100%

   +--------+---------------------------------+----------------------------------------+
   | J2     | *West* - power from Power Board | *East* - power from External connector |
   +--------+---------------------------------+----------------------------------------+
   | J33    | *North* - single ended ADC      | *South* - differential ADC             |
   +--------+---------------------------------+----------------------------------------+
   | J34    | *North* - 0 to 2 Vref ADC range | *South* - 0 - Vref ADC range           |
   +--------+---------------------------------+----------------------------------------+
   
   .. image:: images/jumper-b.*

Power board
~~~~~~~~~~~

The power board has 6 configuration jumpers, J31 to J36.  These will typically be set to *South*
to enable the hall effect port. Setting to *North* will enable the back-EMF zero crossing detection, but the
default firmware implementations do not use this sensor.

   .. image:: images/power.png
      :width: 100%

   +-----------+-----------------------------------------+--------------------------------------------------+
   | J6        | *Fitted* - standard watchdog protection | *Absent* - watchdog requires SW1 to be depressed |
   +-----------+-----------------------------------------+--------------------------------------------------+
   | J31 - J36 | *North* - zero cross detectors          | *South* - hall sensors                           |
   +-----------+-----------------------------------------+--------------------------------------------------+

   *WARNING* - When connecting the quadrature encoder cable to the LDO motors, the connector can often
   be inserted into the motor both correctly, and upside down.  Check that the the alignment flanges on
   the motor match those on the connector before inserting.  The quadrature encoder will be permanently
   damaged with an incorrectly inserted connector.

   .. image:: images/quadrature.*


Configure the firmware
----------------------

The firmware consists of two application projects: a basic BLDC application that controls the motors using
simple hall sector-based commutation, and a dual-axis FOC control application.

.. only:: xde-outside

  The firmware is configured and loaded onto XMOS hardware using the XMOS Development Tools. See the
  :ref:`Installation instructions <install>` for more information.

Create a demo application
~~~~~~~~~~~~~~~~~~~~~~~~~

.. only:: xde-html

  .. cssclass:: xde-inside

    The firmware is provided as source code, which can be imported from the Developer Column directly into your workspace.
  
    .. raw:: html
 
       <ul class="iconmenu">
         <li class="xde-import"><a href="http://www.xmos.com/automate?automate=ImportComponent&partnum=XM-000011-SW">Click here to create a new project for the motor control firmware.</a></li>
       </ul>

    .. tip::
  
      The XDE creates a new project for the demo and imports all of the associated projects. The original source files are available
      in the directories ``app_basic_bldc`` and ``app_dsc_demo``.

.. cssclass:: xde-outside

  The firmware is provided as source code, which can be downloaded from the XMOS website. The source code
  be imported into the XDE or built on the command-line.
  
  To use the XDE, follow these steps:
  
  .. steps::
  
    #. Choose :menuitem:`File,Import`.
    #. Double-click on the **General** option, select **Existing Projects
       into Workspace** and click **Next**.
    #. In the **Import** dialog box, click **Browse** (next to the **Select
       archive file** text box).
    #. Select the downloaded ZIP file and click **Open**.
    #. Click **Finish**.
	
	   The XDE imports a set of projects into your workspace.
	
	#. In the **Project Explorer**, click the folder ``sw_motor_control`` to expand it.
	#. Right-click on either the sub-folder ``app_basic_bldc`` or ``app_dsc_demo`` and select :menuitem:`Copy`.
	#. Right-click an empty area of the workspace and select :menuitem:`Paste`.
	#. In the dialog that appears, enter a name for the application and click **OK**.

  To use the command-line tools, follow these steps:
  
  .. steps::
  
    #. Unzip the firmware package file.
	   
    # Change to either directory ``sw_motor_control`` and copy either the directory ``app_basic_bldc`` or ``app_dsc_demo`` 
	  to a new directory.
  
      You can modify the source files in this directory without changing the original files.
    
	
Configure the firmware settings
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The firmware is configured by modifying the demo source code. Here are some things you can modify.

.. actions::

   :Select between Ethernet or CAN control:

     By default the software is controlled by the buttons around the LCD and the Ethernet interface.
     To use CAN instead, open the source file ``src/dsc_config.h``, enable the macro
     `USE_CAN`` and disable the macro ``USE_ETH``.

   :Change the TCP/IP address:

     By default the Ethernet and TCP/IP interface has a statically allocated IP address of 169.254.0.1 (a link local IP address),
     and a net mask of 255.255.0.0.  To change these values, open the file ``src/main.xc`` and search for the function
     ``init_tcp_server`` which contains these values.

There are other compile time configuration options present in the file ``dsc_config.h``. These are described in more detail
in the :ref:`sw_motor_control_sw_guide <software guide>`.

Build and run the firmware
~~~~~~~~~~~~~~~~~~~~~~~~~~
	
To build and run the firmware from the XDE, follow these steps:

.. steps::

  #. Select your project in the **Project Explorer** and click **Build** |-| |button build| |-|.
  
     The XDE builds the firmware, displaying progress in the **Console**. On completion, it 
     adds the compiled binary file to the **bin** sub-folder.

     .. |button build| image:: images/button-build.*
        :iconmargin:

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

  #. Check the **hardware** option and select the **L2 Motor Control Board**
     from the **Hardware** list.

  #. Click **Run**.

The XDE loads your executable, displaying any output generated by your
program in the **Console**.  
  
.. tip::
    
  For more information on XDE Run Configurations, see :ref:`xde_run_program`.
   
.. cssclass:: xde-outside

  To build and run the firmware using the command-line tools, follow these steps:

  .. steps:: 

    #. Change to the application directory and enter the following command:
  
       :command:``xmake all``

       This command builds the software and produces an executable file ``bin/Release/app_dsc_demo.xe``.
 
    #. Enter the following command:
  
       :command:`xrun bin/Release/app_dsc_demo.xe`


LCD feedback
  The LCD shows the current speed of each motor, and the demand speed.  Both motors have the same demand speed.

Controlling the motor speed
  Button A increases the demand speed in steps of 100 RPM.  Button B decreases the motor speed in steps of 100 RPM.

The buttons change the demand speed within a maximum and minimum of ``MIN_RPM`` and ``MAX_RPM``.  These are configured
in the file ``dsc_config.h`` file, and are 500 and 3800.


Using the GUI interface
-----------------------

The GUI application is available from XMOS on request. It is based on the LabView suite, and so requires the LabView
8.1 runtime environment to be installed on the user's PC.  This is available from the LabView website, at 
*http://joule.ni.com/nidu/cds/view/p/id/861/lang/en*.

  .. image:: images/gui.png
     :width: 100%


For interfacing to the board using CAN, LabView supports the Kvaser Leaf Light HS USB to CAN dongle.

When the application is run (Motor Control.exe), the interface will appear, and a dialog will pop up asking to have
the user select CAN or Ethernet.  If Ethernet is selected then the IP address of the board will be required. The
firmware flashed onto the board by default will have the IP address 169.254.0.1 (a link local IP address).

The watchdog timer hardware override
------------------------------------

On the power board there is a watchdog timer override button.  This allows a physical override to prevent the XMOS
device watchdog pulse stream to reach the watchdog timer cutout device.  By default, jumper J6 on the power board will
be present.  This means the watchdog circuit on the power board will be directly connected to the XMOS device.

By removing jumper J6, the button SW1 will need to be held to enable the connection between the XMOS device and the
watchdog circuit on the power board.  This configuration is useful when testing out new algorithms.  The user would
hold the button down for normal operation, but if an error occurs and there is a risk of damage to the motors or
the power board, the button can be quickly released to prevent the FETs from being energized further.


Further reading
---------------

Visit *http://www.xmos.com/applications/motor-control* for further information and updates.




