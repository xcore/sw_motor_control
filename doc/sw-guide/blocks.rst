Processing Blocks
=================

This module provides a number of standard computation functions that are utilised in motor control. These are outlined below.

   * PID Calculation Routines
   * Clarke & Park Transforms
   * Sine & Cosine lookup


PID Calculation Routines
++++++++++++++++++++++++

The processing blocks module provides the following PID calculation routines. The coefficients are signed 16 bit fixed point.

::

  #include "pid_regulator.h"

  void init_pid( int Kp, int Ki, int Kd, pid_data *d );

  int pid_regulator( int set_point, int actual, pid_data *d );

  int pid_regulator_delta( int set_point, int actual, pid_data *d );

  int pid_regulator_delta_cust_error( int error, pid_data *d );

  int pid_regulator_delta_cust_error_speed( int error, pid_data &d );

  int pid_regulator_delta_cust_error_Iq_control( int error, pid_data &iq );

  int pid_regulator_delta_cust_error_Id_control( int error, pid_data &id );

``init_pid`` initialises the ``pid_data`` structure values with the coefficient values for *Kp*, *Ki* and *Kd*. These value are the proportional,
integral and differential coefficients controlling the PID controller. The compile time constant ``PID_RESOLUTION`` determines how many fractional bits
are present in these coefficients.

``pid_regulator`` performs a standard PID calculation using the ``set_point`` and ``actual`` values. It calculates the error and applies the PID coefficients
and then returns the result. The returned error will be applied to the ``set_point`` value.

``pid_regulator_delta`` performs a standard PID calculation using the ``set_point`` and ``actual`` values. It calculates the error and applies the PID
coefficients and then returns the resulting error.

``pid_regulator_delta_cust_error`` performs a standard PID calculation using a previously calculated error value. It calculates the error and applies
the PID coefficients and then returns the resulting error.

``pid_regulator_delta_cust_error_speed``, ``pid_regulator_delta_cust_error_Iq_control`` and ``pid_regulator_delta_cust_error_Id_control`` are
customized control PIDs that limit the output to a specific range appropriate to the variable being controlled.

Clarke & Park Transforms
++++++++++++++++++++++++

The processing blocks module provides the following Clarke and park transforms. The internal coefficients are all fixed point values.

::

  #include "park.h"
  void park_transform( int *Id, int *Iq,
                       int I_alpha, int I_beta,
                       unsigned theta );

  void inverse_park_transform( int *I_alpha, int *I_beta,
                               int Id, int Iq,
                               unsigned theta );


  #include "clarke.h"
  void clarke_transform( int *I_alpha, int *I_beta,
                         int Ia, int Ib, int Ic );

  void inverse_clarke_transform( int *Ia, int *Ib, int *Ic,
                                 int alpha, int beta );


Each function has the calculation outputs passed as references (e.g. as pointers in C) and the inputs
passed as normal arguments. The Park transform moves the rotating frame of reference of values relative to the stator
(and the QEI and ADCs) into the frame of reference of the rotor. 
The Clarke transform takes 3-vector values which are gathered by measurement of the three coils and
transforms them into a 2-vector value.  This is possible because the 3-vectors have only 2 degrees of freedom, the current in
one of the coils being the sum of the other two. See a description of Field Oriented Control for more information.


Sine & Cosine lookup
++++++++++++++++++++

The sine and cosine functions are largely provided for use in the Park transforms, but may be used by other
functions if required. The sine table provided has a 256 entry lookup. This is convenient for a 1024 step full
circle QEI on a 4 pole motor, since each angular increment in the QEI represents 4 times the electrical
angle. Thus the 0-1023 range merely needs to be looked up in a 0-255 range, with the upper 2 bits truncated.

The lookup functions provided are as follows.

::

  #include "sine_lookup.h"

  inline long long sine( unsigned angle );
  inline long long cosine( unsigned angle );

