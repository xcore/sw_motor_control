==================================================================================
Quickstart guide for the XMOS Brushless DC Motor development platform, version 2.0
==================================================================================

Setting up the hardware
-----------------------

  The XMOS Brushless DC Motor development platform comes as two separate boards.  The first board is the
  control and processing board.  This is joined with a 50 way ribbon cable to the power board.

      - Connect the power board to the control board with the 50 way ribbon cable.

      - Connect the first motor to the MOTOR1 connector on the power board, and the second motor to
        the MOTOR2 connection.
        
      - Connect the quadrature encoder connections from each motor to the power board.  

      - Connect the XMOS JTAG adaptor to the appropriate port, and connect it back to the PC with a USB cable.

      - Connect a 24V power supply to the power section of the BLDC board.
      
      - By default, the power board will provide power to the control board. Jumper J2 can be set to the alternative
        position to allow a separate 5V power supply to be provided to the control board.
        
      - The default application will spin the motors using a field oriented control algorithm.  The display will show
        the speed of each motor, and the demand speed of both.  Buttons A and B will alter the demand speed for the system.

Configuring the firmware
------------------------

  The default firmware comes from the application directory called **app_dsc_demo**.  This is the dual axis FOC control
  algorithm.  An alternative application, **app_basic_bldc**, is provided, which controls the motors using simple
  hall sector based commuation.

  Selecting Ethernet or CAN control
    By default the software is set up to be controlled by the buttons around the LCD, and also by the ethernet interface.
    If CAN is a preferred choice of control, then the **app_dsc_demo\src\dsc_config.h** can be modified.  The preprocessor
    macros **USE_ETH** and **USE_CAN** can be commented out as approriate to enable ethernet, CAN, or neither.

  Changing the TCP/IP address
    By default the ethernet and TCP/IP interface has a statically allocated IP address of 169.254.0.1 (a link local IP address),
    and a net mask of 255.255.0.0.  To change this, edit the file **app_basic_bldc/src/main.xc** or **app_dsc_demo/src/main.xc**.
    Contained in this file is the address configuration structure which is passed to the TCP/IP module, in a function called
    **init_tcp_server()**.

Building the firmware
---------------------
  Once the software is configured as required, the system can be built by executing the following make command in an XMOS
  Tools Prompt.  The command should be executed in the root directory, or the **app_dsc_demo** directory.

    *xmake all*

  The command will build the software and produce an executable file:
  
    *app_dsc_demo/bin/Release/dsc_basic_bldc.xe*

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

    *xrun app_dsc_demo/bin/Release/dsc_basic_bldc.xe*

  Alternatively, using the 11.2.0 development tools or later and AVB version 5v0.1 or later, from within the XDE:

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



The watchdog timer hardware override
------------------------------------

On the power board there is a watchdog timer override button.  This allows a physical override to prevent the XMOS
device watchdog pulse stream to reach the watchdog timer cutout device.  By default, jumper J6 on the power board will
be present.  This means the watchdog circuit on the power board will be directly connected to the XMOS device.

By removing jumper J6, the button SW1 will need to be held to enable the connection between the XMOS device and the
watchdog circuit on the power board.  This configuration is useful when testing out new algorithms.  The user would
hold the button down for normal operation, but if an error occurs and there is a risk of damage to the motors or
the power board, the button can be quickly released to prevent the FETs from being energized further.





