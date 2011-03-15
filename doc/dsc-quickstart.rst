==================================================================================
Quickstart guide for the XMOS Brushless DC Motor development platform, version 1.0
==================================================================================

Setting up the hardware
-----------------------
    The XMOS Brushless DC Motor development platform typically uses two power supplies (24V and 5V), an XMOS JTAG adaptor,
    and one or two motors.

      - Connect the motors to the board first.  The software will run with one or two motors. When a single motor is being
        used connect it to port 1 as this is the port that has its speed reported to the PC control applications.

      - Connect the XMOS JTAG adaptor to the appropriate port, and connect it to the PC with a USB cable.

      - Connect a 5V power supply to the XMOS processor half of the BLDC board. Do not do this if there are wire links
        between the power and processor sides of the board.  The links will be over the isolation barrier by the text label
	**5V LINK**.

      - Connect a 24V power supply to the power section of the BLDC board.  Do not have the power section
        of the board powered without the 5V section being powered.

Configuring the firmware
------------------------
  Selecting Ethernet or CAN control
    By default the software is set up to be controlled by the buttons around the LCD, and also by the ethernet interface.
 
    If a CAN bus is the preferred choice of control, and an appropriate CAN interface is available (CANUSB T980), then the
    file **app_basic_bldc/src/main.xc** can be modified.  At the top of the file are two pre-processor directives that allow
    the selection of ethernet or CAN.

  Changing the TCP/IP address
    By default the ethernet and TCP/IP interface has a statically allocated IP address of 10.0.102.33, and a net mask of
    255.255.240.0.  To change this, edit the file **app_basic_bldc/src/utilities/initialization.xc**.  Contained in this file
    is the address configuration structure which is passed to the TCP/IP module.

Building the firmware
---------------------
  Once the software is configured as required, the system can be built by executing the following make command in an XMOS
  Tools Prompt.  The command should be executed in the distribution root directory, or the **app_basic_bldc** directory.

    *xmake all*

  The command will build the software and produce an executable file:
  
    **app_basic_bldc/bin/XP-DSC-BLDC/dsc_basic_bldc.xe**

  This can be run on the hardware by executing:

    *xrun --io app_basic_bldc/bin/XP-DSC-BLDC/dsc_basic_bldc.xe*



Running the firmware
--------------------
  LCD feedback
    The LCD shows the current speed of each motor, and the demand speed.  Both motors have the same demand speed.

  Controlling the motor speed
    Button A increases the demand speed in steps of 100 RPM.  Button B decreases the motor speed in steps of 100 RPM.

  Controlling the motor direction
    Button C reverses the direction of the motor.

Using the ethernet control application
--------------------------------------
  An application to drive the ethernet interface is present in the **apps_control/eth_control** directory.  To build it you
  must use the Eclipse IDE.  An appropriate workspace is set up in the directory apps_control.  Alternatively, a pre-built
  JAR file for this application is present at **apps_control/eth_control/EthernetControl.jar**.  Version 6.1 of the Java Runtime
  Environment is required. Typically the application would be started with
  
    *java.exe -jar EthernetControl.jar*

  To use the application, type in the ethernet address of the motor control board and click Connect.  Momentarily, the PC
  will connect to the motor control board.  If the debug console of the motor control board is being traced (by starting
  the XE application with the --io flag, or by running from within the XMOS IDE), then the control connection will be
  reported.

  A large dial shows the current motor speeds, and a slider control allows the user to adjust the speed. Both motors have the
  same demand speed, and the speed of motor 1 is reported in the dial.


Using the CAN control application
---------------------------------
  Like the ethernet control application, the CAN control application can be built from within the Eclipse IDE, or
  the prebuilt version can be used.  The prebuilt version is at **apps_control/can_control/CanControl.jar**.  The 
  application has been designed to work with the CANUSB T980 dongle, which converts commands given to a USB serial
  port into CAN bus packets.

  Installing the CAN drivers
    The user will need to download and install the drivers for the CANUSB T980 dongle.  Once installed, the CAN bug will
    appear to the PC to be a COM port.  A check that this has been done correctly can easily be performed by using the
    Windows device manager to check the number and names of the COM ports with the dongle removed, then inserted. 

    Next the RXTX Java communcation library will need to be installed.  The directory **apps_control/can_control/lib**
    contains two directories, **32bit** and **64bit**.  In each one are three files:

      - **rxTxComm.jar** - This needs to be copied to the Java runtime **lib/ext** directory

      - **rxTxParallel.dll** - This needs to be copied to the Java runtime **bin** directory

      - **rxTxSerial.dll** - This needs to be copied to the Java runtime **bin** directory

    Once this is complete, the CanControl.far file should be able to be operated correctly.  Typically you would start the
    application using
    
      *java.exe -jar CanControl.jar*

   
  The operation of the CAN control application is much the same as the ethernet application.  It has a dial showing the speed
  of motor 1, and a slider control to control the demand speed for both motors.



