=================================================================
Quickstart guide for the XMOS Motor Control platform, version 2.0
=================================================================

Supported hardware
------------------

XMOS Bushless DC Motor Control development platform *XK-MC-LVM2*


Setting up the hardware
-----------------------

  The XMOS Brushless DC Motor development platform comes as two separate boards.  The first board is the
  control and processing board.  This is joined with a 50 way ribbon cable to the power board.

      - Connect the power board to the control board with the 50 way ribbon cable.

      - Connect the first motor to the MOTOR1 connector on the power board, and the second motor to
        the MOTOR2 connection.
        
      - Connect the quadrature encoder connections from each motor to the power board.  

      - Connect the XMOS JTAG adaptor to the 20 pin IDC header, and connect it to the PC with a USB cable.

      - Connect a 24V power supply to the power section of the BLDC board.
      
   **WARNING** : Do *NOT* put the 24V power supply into the control board. The control board takes a 5V power
   supply and will be damaged by 24V. 
      
   The default application will spin the motors using a field oriented control algorithm.  The display will show
   the speed of each motor, and the demand speed of both.  Buttons A and B will alter the demand speed for the system.

Control board
~~~~~~~~~~~~~

   By default, the power board will provide power to the control board. Jumper J2 can be set to the alternative (East)
   position to allow a separate 5V power supply to be provided to the control board.
        
   The ADC configuration jumpers, J34 and J35 on the control board must be set as follows in order
   for the default firmware to correctly run.  J34 must be set to *South*, and J35 must be set to *North*. 

   .. image:: control.png
      :width: 100%

Power board
~~~~~~~~~~~

   The power board has 6 configuration jumpers, J31 to J36.  These will typically be set to *South*
   to enable the hall effect port. Setting to *North* will enable the back-EMF zero crossing detection, but the
   default firmware implementations do not use this sensor.

   .. image:: power.png
      :width: 100%


Configuring the firmware
------------------------

  The default firmware comes from the application directory called **app_dsc_demo**.  This is the dual axis FOC control
  algorithm.  An alternative application, **app_basic_bldc**, is provided, which controls the motors using simple
  hall sector based commutation.

  Selecting Ethernet or CAN control
    By default the software is set up to be controlled by the buttons around the LCD, and also by the ethernet interface.
    If CAN is a preferred choice of control, then the **app_dsc_demo\src\dsc_config.h** can be modified.  The preprocessor
    macros **USE_ETH** and **USE_CAN** can be commented out as appropriate to enable ethernet, CAN, or neither.
    
  Changing the TCP/IP address
    By default the ethernet and TCP/IP interface has a statically allocated IP address of 169.254.0.1 (a link local IP address),
    and a net mask of 255.255.0.0.  To change this, edit the file **app_basic_bldc/src/main.xc** or **app_dsc_demo/src/main.xc**.
    Contained in this file is the address configuration structure which is passed to the TCP/IP module, in a function called
    **init_tcp_server()**.

  There are other compile time configuration options present in the *dsc_config.h* file. These are described in more detail
  in the software guide.

Building the firmware
---------------------

  The XTAG-2 debug adapter supplied with the kit can be connected to the board to provide a JTAG interface from
  your development system that you can use to load and debug software. You need to install a set of drivers for
  the XTAG-2 debug adapter and download a set of free Development Tools (11.10 or later) from the XMOS website:

    http://www.xmos.com/tools

  Instructions on installing and using the XMOS Tools can be found in the XMOS Tools
  User Guide http://www.xmos.com/published/xtools_en.


  Once the software is configured as required, the system can be built by executing the following make command in an XMOS
  Tools Prompt.  The command should be executed in the root directory, or the **app_dsc_demo** directory.

    *xmake all*

  The command will build the software and produce an executable file:
  
    *app_dsc_demo/bin/Release/app_dsc_demo.xe*

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

  To build, select the appropraite project in the Project Explorer and click the *Build* icon.

Running the firmware
--------------------

  The main FOC application can be run on the hardware by executing the following command within an XMOS command line:

    *xrun app_dsc_demo/bin/Release/app_dsc_demo.xe*

  Alternatively, from within the XDE:

    - Right click on the binary within the project.
    - Choose *Run As* > *Run Configurations*
    - Choose *hardware* and select the relevant XTAG-2 adapter
    - Select the *Run UART server* check box.
    - Click on *Apply* if configuration has changed
    - Click on *Run*

  LCD feedback
    The LCD shows the current speed of each motor, and the demand speed.  Both motors have the same demand speed.

  Controlling the motor speed
    Button A increases the demand speed in steps of 100 RPM.  Button B decreases the motor speed in steps of 100 RPM.

  The buttons will change the demand speed within a maximum and minimum of *MIN_RPM* and *MAX_RPM*.  These are configured
  in the *dsc_config.h* file, and are 500 and 3800.

Using the GUI interface
-----------------------

The GUI application is available from XMOS on request. It is based on the LabView suite, and so requires the LabView
8.1 runtime environment to be installed on the user's PC.  This is available from the LabView website, at 
*http://joule.ni.com/nidu/cds/view/p/id/861/lang/en*.

  .. image:: gui.png
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




