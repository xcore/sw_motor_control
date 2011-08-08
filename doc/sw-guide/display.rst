Display & Shared IO Interface
=============================

This module provides a details on the display interface and shared IO manager used in the XMOS Motor Control Development Platform.

The shared IO manager interfaces to the following components on the board:

   * A Newhaven Display NHD-C12832A1Z-FSW-FBW-3V3 128 x 32 pixel monochrome LCD display via a SPI like interface.
   * Ethernet reset signal.
   * CAN PHY control signals (TERM and RS).
   * The 4 push button surface mount switches (marked A-D).


Provision could also be made in this thread to drive the 4 surface mount LEDs next to switches A-D.


Hardware Interface
++++++++++++++++++

The interface is implemented using ports on XCore 1 - it uses 11 pins in total, including:


   * 1 x 4 bit port shared between the Ethernet reset, CAN control and display address / data signals.
   * 3 x 1-bit ports for the display chip select, serial clock and data signals.
   * 4 x 1-bit ports for the buttons A-D. 



Operation
+++++++++

The following files are used for the display and shared IO manager.

   * ``lcd.h`` - prototypes for LCD functions
   * ``lcd.xc`` - LCD driver functions
   * ``lcd_data.h`` - contains the lcd driver font map.
   * ``lcd_logo.h`` - contains the XMOS logo as a unsigned char array.
   * ``shared_io.h`` - header for the  main shared IO server and defines commands this thread uses.
   * ``shared_io.xc`` - contains the main shared IO server routine. 

The shared IO manager that interacts with the hardware is a single thread with three channels connecting to it.
The function is called from main with parameters passing a structure containing the appropriate ports into it.
The server_thread prototype is:


void display_shared_io_manager( chanend c_eth, chanend c_can, chanend c_control, REFERENCE_PARAM(lcd_interface_t, p), in port btns[] )


The input channels are used for the following communications:

   * c_eth - receives Ethernet reset signals from the Ethernet MAC.
   * c_can - receives changes for the CAN control signals from the CAN PHY.
   * c_control - receives speed and current information from the main motor control thread and sets the speed requested.

The main shared IO manager is constructed from a select statement that sits inside a while(1) loop, so that it gets executed repeatedly.


   * case t when timerafter(time + 10000000) :> time : - timer that executes at 10Hz. This gets the current speed, current Iq and speed setpoint from the outer motor speed control loop and updates the display with the new values. It also debounces the buttons.
   * case c_eth :> eth_command : - receives Ethernet reset signals from the Ethernet MAC and sets/unsets the appropriate bit.
   * case c_can :> can_command : - receives changes for the CAN control signals from the CAN PHY and sets/unsets the appropriate bits.
   * case !btn_en[0] => btns[0] when pinseq(0) :> void : - execute commands if button A is pressed. Increases the desired speed by PWM\_INC\_DEC\_VAL and sends it to the outer motor speed control loop.
   * case !btn_en[1] => btns[1] when pinseq(0) :> void : - execute commands if button B is pressed. Decreases the desired speed by PWM\_INC\_DEC\_VAL and sends it to the outer motor speed control loop.
   * case !btn_en[2] => btns[2] when pinseq(0) :> void : - execute commands if button C is pressed. No actual command is executed.
   * case !btn_en[3] => btns[3] when pinseq(0) :> void : - execute commands if button D is pressed. No actual command is executed.


The switches are debounced by incrementing the but\_en guard signal for that switch by 4 each time they are pressed.
This prevents the code for this button being run until the guard has reached 0.

The 10Hz timer in the select statement decrements the value by one, if the value is not 0, on each iteration though it's loop.

Therefore, after a minimum of 300ms and a maximum of 400ms the switch is re-enabled.


LCD Communication
+++++++++++++++++

Communication with the LCD is done using a lcd_byte_out(...) function.
This communicates directly with the ports to the display.
The protocol is unidirectional SPI with a separate command / data pin which specifies if the current data transfer is a command or data word.

The procedure for sending a byte to the display is:

   * Select the display using the CS_N signal.
   * Set the address / data flag (this requires knowing the current port_val as it is on the shared port).
Clock out the 8 bits of data MSB first by:
     - Setting the data pin to the bit value.
     - Setting clock high.
     - Setting clock low.
   * Deselect the display using the CS\_N signal.


The following functions are provided that use the lcd_byte_out(..) function to send data to the display:

   * lcd_clear(..) - this wipes the display by writing blank characters into the displays output buffer.
   * lcd_draw_image(..) - this takes an unsigned char array of size 512 bytes and writes it to the display. Hence, it can be used to display images on the display.
   * lcd_draw_text_row(..) - writes a row of 21 characters to the display on the row specified by lcd_row (0-3).


The display is configured as 128 columns x 4 byte rows, as the byte writes the data to 8 pixel rows in one transfer.

A 5x7 pixel font map is provided for the characters A-z, a-z, 0-9 and standard punctuation.

The command set for the display is defined in the datasheet.
When sending data to the display it is best to try to send the data as fast as possible.

This is because the display has to be turned off, whilst the data is being written to it.

Therefore, writing large amounts of data on a regular basis can cause the display to flicker.
