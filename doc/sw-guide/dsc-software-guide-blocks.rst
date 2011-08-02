Processing Blocks
=================

This module provides a number of standard computation functions that are utilised in motor control. These are outlined below.

   * PID Calculation Routines
   * Clarke & Park Transforms
   * Sine & Cosine lookup


PID Calculation Routines
++++++++++++++++++++++++

The processing blocks module provides the following PID calculation routines. The coefficients are signed 16 bit fixed point.


#include "pid_regulator.h"

void init_pid( int Kp, int Ki, int Kd, pid_data *d );

int pid_regulator( int set_point, int actual, pid_data *d );
	
int pid_regulator_delta( int set_point, int actual, pid_data *d );
	
int pid_regulator_delta_cust_error( int error, pid_data *d );


init_pid(...) is used to initialise the pid_data structure values with the coefficient values for $Kp$, $Ki$ and $Kd$.

pid_regulator(...) does a standard PID calculation using the set_point and actual values. It calculates the error and applies the PID coefficients and then returns the result. The returned error will be applied to the set_point value.

pid_regulator_delta(...) does a standard PID calculation using the set_point and actual values. It calculates the error and applies the PID coefficients and then returns the resulting error.

pid_regulator_delta_cust_error(...) does a standard PID calculation using a precalculated error value. It calculates the error and applies the PID coefficients and then returns the resulting error.


Clarke & Park Transforms
++++++++++++++++++++++++

The processing blocks module provides the following Clarke and park transforms. The internal coefficients are all fixed point values.


#include "park.h"
void park_transform( int *Id, int *Iq, 
	int I_alpha, int I_beta, unsigned theta );
void inverse_park_transform( int *I_alpha, int *I_beta, 
	int Id, int Iq, unsigned theta );

#include "clarke.h"
void clarke_transform( int *I_alpha, int *I_beta, 
	int Ia, int Ib, int Ic );
void inverse_clarke_transform( int *Ia, int *Ib, int *Ic, 
	int alpha, int beta );


Each function has the calculation destinations passed as pointers (or references in XC) and the inputs to the calculations are passed as normal arguments.


Sine & Cosine lookup
++++++++++++++++++++

The sine and cosine functions are largely provided for use in the Park transforms, but may be used by other functions if required. The sine table provided operate in 0.1 degree steps. The valid range is 0 to 3599.

The lookup functions provided are as follows.


#include "sine_cosine.h"

inline long long sine( unsigned deg );
inline long long cosine( unsigned deg );

