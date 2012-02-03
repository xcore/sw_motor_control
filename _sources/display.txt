Display and Shared IO Interface
===============================

This module provides a details on the display interface and shared IO manager used in the XMOS Motor Control Development Platform.

The shared IO manager interfaces to the following components on the board:

   * A Newhaven Display NHD-C12832A1Z-FSW-FBW-3V3 128 x 32 pixel monochrome LCD display via a SPI like interface.
   * The 4 push button surface mount switches (marked A-D).


Provision could also be made in this thread to drive the 4 surface mount LEDs next to switches A-D.


Hardware Interface
++++++++++++++++++

The interface is implemented using 11 pins in total, including:


   * 1 x 4 bit port to control the display address / data signal.
   * 3 x 1-bit ports for the display chip select, serial clock and data signals.
   * 1 x 4-bit ports for the buttons A-D. 



Operation
+++++++++

The following files are used for the display and shared IO manager.

``lcd.h`` 
 Prototypes for LCD functions.
``lcd.xc`` 
 LCD driver functions.
``lcd_data.h`` 
 Contains the lcd driver font map.
``lcd_logo.h`` 
 Contains the XMOS logo as a unsigned char array.
``shared_io.h`` 
 Header for the  main shared IO server and defines commands this thread uses.
``shared_io.xc`` 
 Contains the main shared IO server routine. 

The shared IO manager that interacts with the hardware is a single thread with three channels connecting to it.
The function is called from main with parameters passing a structure containing the appropriate ports into it.
The server thread prototype is:

::

    void display_shared_io_manager( chanend c_speed[],
                                    REFERENCE_PARAM(lcd_interface_t, p),
                                    in port btns,
                                    out port leds )


The purpose of each argument is as follows:

``c_speed`` 
 An array of speed control channel for controlling the motors.
``p`` 
 A reference to the control structure describing the LCD interface.
``btns`` 
 A 4 bit input port attached to the buttons.
``leds`` 
 A 4 bit output port attached to the leds.

The main shared IO manager is constructed from a ``select`` statement within a ``while(1)`` loop, so that it gets executed repeatedly.

``case t when timerafter(time + 10000000) :> time :`` 
  Timer that executes at 10Hz. This gets the current speed, current Iq and speed setpoint from the motor control loops and updates the display with the new values. It also debounces the buttons.

``case !btn_en => btns when pinsneq(value) :> value:`` 
  Execute commands if a button is pressed.

The switches are debounced by setting the ``but_en`` guard signal to two whenever a button is pressed. 
The 10Hz timer in the select statement decrements the value by one, if the value is not 0, on each iteration though its loop.
Therefore, after a minimum of 200ms and a maximum of 300ms the switch is re-enabled.


LCD Communication
+++++++++++++++++

Communication with the LCD is done using a ``lcd_byte_out`` function.
This communicates directly with the ports to the display.
The protocol is unidirectional SPI with a separate command / data pin which specifies if the current data transfer is a command or data word.

The procedure for sending a byte to the display is:

   * Select the display using the CS_N signal.
   * Set the address / data flag.
   * Clock out the 8 bits of data MSB first by:
     - Setting the data pin to the bit value.
     - Setting clock high.
     - Setting clock low.
   * Deselect the display using the CS\_N signal.


The following functions are provided that use the ``lcd_byte_out`` function to send data to the display:

``lcd_clear`` 
 This wipes the display by writing blank characters into the displays output buffer.
``lcd_draw_image`` 
 This takes an unsigned char array of size 512 bytes and writes it to the display. Hence, it can be used to display images on the display.
``lcd_draw_text_row`` 
 Writes a row of 21 characters to the display on the row specified by lcd_row (0-3).


The display is configured as 128 columns x 4 byte rows, as the byte writes the data to 8 pixel rows in one transfer.  
A 5x7 pixel font map is provided for the characters A-z, a-z, 0-9 and standard punctuation.

The command set for the display is defined in the datasheet.
When sending data to the display it is best to try to send the data as fast as possible.  
This is because the display has to be turned off, whilst the data is being written to it.  
Therefore, writing large amounts of data on a regular basis can cause the display to flicker.
