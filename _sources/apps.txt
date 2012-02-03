Motor Control Platform Example Applications
===========================================

The current release package ships with two example applications.


   * An application showing an example Field Oriented Control (FOC) control loop for two motors
   * An application showing speed control of two motors using simple sector based commutation

Each application is capable of spinning two motors at speeds between 500 and 3800 RPM.  The *A* and *B* buttons on the
control board increase and decrease the speed. The display shows the demand speed, and the current speed of each of
the two motors.

If an over-current state is detected by the system, or if the motor spins in an unexpected direction, or stalls, then
the motor will be shut down, and *FAULT* will appear by the motor in the display.


Basic BLDC Speed Control Application ``app_basic_bldc``
+++++++++++++++++++++++++++++++++++++++++++++++++++++++

This application makes use of the following functionality.

   * PWM
   * Hall Input
   * Display
   * Ethernet & Communications
   * Processing Blocks

|newpage|

Motor Control Loop
~~~~~~~~~~~~~~~~~~

The main motor control code for this application can be found in the file ``src/motor/run_motor.xc``. The motor control thread is
launched using the following function.

::

  void run_motor ( chanend c_wd, 
	chanend c_pwm, 
	chanend c_control, 
	port in p_hall, 
	port out p_pwm_lo[],
        chanend? c_wd );

The core of this function is a continuous loop that receives the position of the rotor as measured by the hall sensor, and
selects which coil to energise based on that position.

After initially pausing and starting the watchdog the main loop is entered. The main loop responds to two events. The first
event is a change in hall sensor state. This will trigger an update to the low side of the inverters (p_pwm_lo) and also to
the PWM side of the inverter based on the hall sensor state. The output states are defined by the lookup arrays declared at
the start of the function.

::

  /* sequence of low side of bridge */
  unsigned bldc_ph_a_lo[6] = {1,1,0,0,0,0};
  unsigned bldc_ph_b_lo[6] = {0,0,1,1,0,0};
  unsigned bldc_ph_c_lo[6] = {0,0,0,0,1,1};

  /* sequence of high side of bridge */
  const unsigned bldc_high_seq[6] = {1,2,2,0,0,1};


The other event that can be responded to is a command from the c_control channel. This can take the form of two commands. The
first command is a request to read the current speed value. The second command is a request to change the PWM value that is
being sent to the PWM thread and subsequently the motor.

Speed Control Loop
~~~~~~~~~~~~~~~~~~

The speed control loop for this application can be found in the file ``src/control/speed_control.xc``. The thread is launched by calling
the following function.

::

  void speed_control(chanend c_control, chanend c_lcd, chanend c_can_eth_shared );


This thread begins by initialising the PID data structure with the required coefficients. Following this a startup sequence is
entered. This triggers open loop control to get the motor to begin rotating. After a sufficient time period the main speed loop
is entered into.

The main loop consists of a select statement that responds to three events. The first event is a timed event that triggers the
PID control and an update to the motor control threads PWM value. This simply applies the calculated PID error to the set point
that is requested.

The second and third events are a request from the LCD and buttons thread or the communication I/O thread. This can either be a request
from the display for updated speed, set point and PWM demand values or a change in set point. 

FOC Application ``app_dsc_demo``
++++++++++++++++++++++++++++++++

This application makes use of the following functionality.

   * PWM
   * QEI
   * ADC
   * Display
   * Ethernet & Communications
   * Processing Blocks

Control Loop
~~~~~~~~~~~~

The control loop can be found in the file ``src/motor/inner_loop.xc``. The thread is launched by calling the following function.

::

  void run_motor (
    chanend? c_in,
    chanend? c_out,
    chanend c_pwm,
    streaming chanend c_qei,
    chanend c_adc,
    chanend c_speed,
    chanend? c_wd,
    port in p_hall,
    chanend c_can_eth_shared)

The control loop takes input from the encoder, a set speed from the control modules and applies it via
PWM. It contains two controllers in one loop, the speed controller and the current controller.  The
speed controller uses the QEI input to measure the speed of the motor, in order to bring the motor to
the correct demand speed.  The output of this controller is a tangential torque which is required to
acheive that demand speed.  The torque is passed through the ``iq_set_point`` variable.  The
``id_set_point`` variable is always zero, as no force is required in the radial direction. The torque
is a direct consequence of current flow in the coils, and therefore the ``iq_set_point`` is also a
measure of the demand current.

The second controller is the torque/current controller.  This uses the measured coil currents from the ADC,
and tries to make them equal to the ``iq_set_point`` demand. The output of this controller is the extra
current required to deliver the required torque.  This is used to set the PWM duty cycles for the three
coils.

Because the motor is spinning, and the mathematics for the algorithm is done in the frame of reference
of the spinning rotor, the QEI is used to find the rotor angle. A Park transform is used to transform
between the fixed coil frame of reference and the spinning rotor frame of reference.

The Clarke transform is used to convert the three currents in the coils into a radial and tangential two
component current. This is possible because the coil currents have only two degrees of freedom, the
third coil current being the sum of the other two.

This loop is a simple example of how a control loop may be implemented and the function calls that would be
used to achieve this.

The first two arguments, ``c_in`` and ``c_out`` are used to synchronize the PWMs for multiple motors so that they
do not have their ADC dead time in exactly the same time.

Further information on field oriented motor control can be found at:

    * http://en.wikipedia.org/wiki/Field-Oriented_Control

Control loop customization
~~~~~~~~~~~~~~~~~~~~~~~~~~

As described, there are two distinct control loops in the FOC design, but they are both coded into a single
loop.  Separating these into two loops, running in two different threads, may be necessary for designs that
have a complex algorithm governing the speed.

The speed control part of the loop uses measurements from the QEI to determine the speed, and a set point
that is passed in on a channel from the display or comms threads.  To extract the speed control algorithm
and put it into another thread, the following actions could be taken.

  * Move the speed control PID calculation into a new thread (the speed control thread).
  * Move the UI/comms channel processing into the new thread.
  * Add a new channel to join the new thread to the torque control thread.
  * On a regular timer, send a query to the torque control thread to retreive the rotor speed.
    Alternatively, the QEI thread could be adjusted to have an extra channel input so that the
    speed control thread could query the QEI.
  * After the speed control thread has performed the algorithm to determine the new demand tangential
    torque, send the result to the torque control thread through the channel.

In this way, the speed control thread can take advantage of a full 62.5 MIPS.  Speed ramping, damping,
filtering, or predictive torque control could all be implemented.




