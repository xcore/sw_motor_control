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

Motor Control Loop
~~~~~~~~~~~~~~~~~~

The main motor control code for this application can be located in ``src/motor/run_motor.xc``. The motor control thread is
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

The speed control loop for this application can be found in ``src/control/speed_control.xc``. The thread is launched by calling
the following function.

::

  void speed_control(chanend c_control, chanend c_lcd, chanend c_can_eth_shared );


This thread begins by initialising the PID data structure with the required coefficients. Following this a startup sequence is
entered. This triggers open loop control to get the motor to begin rotating. After a sufficient time period the main speed loop
is entered into.

The main loop consists of a select statement that responds to three events. The first event is a timed event that triggers the
PID control and an update to the motor control threads PWM value. This simply applies the calculated PID error to the set point
that is requested.

The second and third events are a request from the LCD and buttons thread or the ethernet thread. This can either be a request
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

The control loop can be found in ``src/motor/inner_loop.xc``. The thread is launched by calling the following function.

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
PWM. It utilises the feedback from the ADC and calculations done using the Park and Clarke transforms and
application of PID regulation of *I_d* and *I_q*.  The resulting values of *V_a*, *V_b* and *V_c* are
output to the PWM.

This loop is a simple example of how a control loop may be implemented and the function calls that would be
used to achieve this.

The first two arguments, *c_in* and *c_out* are used to synchronize the PWMs for multiple motors so that they
do not have their ADC dead time in exactly the same time.


