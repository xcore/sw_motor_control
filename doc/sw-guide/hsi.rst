Hall Sensor Interface
=====================

The hall sensor interface is used for measuring speed and estimating the position of the motor. 

Hall Sensor Usage
+++++++++++++++++

The hall sensor input module provides a number of functions and options in its usage. A listing of the available functions is given below.

::

  #include "hall_input.h"

  void run_hall_speed_timed( chanend c_hall, 
	chanend c_speed, 
	port in p_hall, 
	chanend ?c_logging_0, 
	chanend ?c_logging_1 );

  void do_hall( unsigned &hall_state, 
	unsigned &cur_pin_state, 
	port in p_hall );
	
  select do_hall_select( unsigned &hall_state, 
	unsigned &cur_pin_state, 
	port in p_hall );

``run_hall_speed_timed(...)`` provides a server thread which measures the time between hall sensor state transitions on a 4 bit port as provided on the motor control platform. This functions implementation is described in more detail below.

``do_hall(...)`` simply writes the next hall state into the *hall_state* variable and current pin state into the cur_pin_state variable.

``do_hall_select(...)`` is the same as ``do_hall`` but is a select function. This function is used in the basic BLDC demonstration application.


Hall Sensor Client
++++++++++++++++++

When using the hall sensor server thread as described above, the information may be accessed by using the client functions as listed below.

::

  #include "hall_client.h"

  {unsigned,unsigned,unsigned} get_hall_pos_speed_delta(chanend c_hall);


``get_hall_pos_speed_delta(...)`` will request and subsequently return the theta, speed and delta values respectively from the hall input server thread. The theta value is an estimated value, speed is in revolutions per minute (RPM) and delta is currently used for debugging purposes.

Hall Sensor Server Implementation
+++++++++++++++++++++++++++++++++

*This code is currently considered experimental*

The function ``run_hall_speed_timed(...)`` provides a thread that handles hall sensor input functions, speed and angle estimations.

After initialising the ports and initialising the current hall sensor state the code enters a startup phase. This is where an ideal
theta value is passed to the client as the motor is not yet actually turning, so no angular estimation can be made. This continues
until the hall sensor thread has received two transitions. 

Following the initial startup sequence the hall sensor thread enters the main operational loop. This comprises of a select statement
that handles either a request for information from the clients, a timeout to detect no rotation or a state transition on hall sensor.

When a new transition is received the new hall state is stored and the current theta base value is updated. This base value is defined
as the angular location of the hall sensor within the motor. The system then defines what the next hall sensor state it should wait
for will be.

Once the base angle and next state values have been updated the timing calculations are completed to define the speed and angle
calculation. Speed calculation is defined by looking for a full mechanical rotation of the motor where it returns to a defined state.

When the thread receives a request for speed and angle information these are calculated and then delivered over the change. The angle
estimation is done by considering the time the motor has taken to travel over a hall sensor sector. It assumes that the hall sensor
data is requested at a regular time over the sector (which as it is blocked by the PWM it will be in the example FOC implementation).

Once the values are calculated they are provided to the client over the channel.


