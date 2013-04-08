/**
 * File:    inner_loop.xc_motor() function initially runs in open loop, spinning the magnetic field around at a fixed
 * torque until the QEI reports that it has an accurate position measurement.  After this time,
 * it uses the hall sensors to calculate the phase difference between the QEI zero point and the
 * hall sectors, and therefore between the motors coils and the QEI disc.
 *
 * After this, the full field oriented control is used to commutate the rotor. Each iteration
 * of the control loop does the following actions:
 *
 *   Reads the QEI and ADC state
 *   Calculate the Id and Iq values by transforming the coil currents reported by the ADC
 *   Use the speed value from the QEI in a speed control PID, producing a demand Iq value
 *   Use the demand Iq and the measured Iq and Id in two current control PIDs
 *   Transform the current control PID outputs into coil demand currents
 *   Use these to set the PWM duty cycles for the next PWM phase
 *
 * This is a standard FOC algorithm, with the current and speed control loops combined.
 *
 * Notes:
 *
 *   when theta=0, the Iq component (the major magnetic vector) transforms to the Ia current.
 *   therefore we want to have theta=0 aligned with the centre of the '001' state of hall effect
 *   detector.
 **/
#include <stdlib.h>
#include <safestring.h>
#include <xs1.h>
#include <print.h>
#include <assert.h>

#include "mathuint.h"
#include "pid_regulator.h"
#include "hall_client.h"
#include "qei_client.h"
#include "adc_client.h"
#include "pwm_cli_inv.h"
#include "clarke.h"
#include "park.h"
#include "watchdog.h"
#include "shared_io.h"
#include "inner_loop.h"

#ifdef USE_XSCOPE
#include <xscope.h>
#endif

#define SEC 100000000
#define PWM_MAX_LIMIT 3800
#define PWM_MIN_LIMIT 200
#define OFFSET_14 16383

#define STALL_SPEED 100
#define STALL_TRIP_COUNT 5000

#define LDO_MOTOR_SPIN 1 // Motor spins like an LDO Motor

#define FIRST_HALL_STATE 0b001 // 1st Hall state of 6-state cycle

#define INIT_HALL 0 // Initial Hall state
#define INIT_THETA 0 // Initial start-up angle

#define REQ_VELOCITY 4000 // Initial start-up speed
#define REQ_IQ_OPENLOOP 2000 // Used in tuning
#define REQ_ID_OPENLOOP 0		// Id value for open-loop mode

// Set-up defines for scaling ...
#define SHIFT_20 20
#define SHIFT_16 16
#define SHIFT_9   9

#define PHASE_BITS SHIFT_20 // No of bits in phase offset scaling factor 
#define PHASE_DENOM (1 << PHASE_BITS)
#define HALF_PHASE (PHASE_DENOM >> 1)

#define PHI_GRAD 11880 // 0.01133 as integer ratio PHI_GRAD/PHASE_DENOM
#define PHI_INTERCEPT 35693527 // 34.04 as integer ratio PHI_INTERCEPT/PHASE_DENOM

#define GAMMA_GRAD 7668 // 0.007313 as integer ratio GAMMA_GRAD/PHASE_DENOM
#define GAMMA_INTERCEPT 33019658 // 31.49 as integer ratio GAMMA_INTERCEPT/PHASE_DENOM

#define VEL_GRAD 10000 // (Estimated_Current)^2 = VEL_GRAD * Angular_Velocity

#define XTR_SCALE_BITS SHIFT_16 // Used to generate 2^n scaling factor
#define XTR_HALF_SCALE (1 << (XTR_SCALE_BITS - 1)) // Half Scaling factor (used in rounding)

#define XTR_COEF_BITS SHIFT_9 // Used to generate filter coef divisor. coef_div = 1/2^n
#define XTR_COEF_DIV (1 << XTR_COEF_BITS) // Coef divisor
#define XTR_HALF_COEF (XTR_COEF_DIV >> 1) // Half of Coef divisor

#define PROPORTIONAL 1 // Selects between 'proportional' and 'offset' error corrections
#define VELOC_CLOSED 1 // Selects fully closed loop (both velocity, Iq and Id)
#define IQ_ID_CLOSED 1 // Selcects Iq/Id closed-loop, velocity open-loop

#ifdef USE_XSCOPE
//	#define DEMO_LIMIT 100000 // XSCOPE
	#define DEMO_LIMIT 200000 // XSCOPE
#else // ifdef USE_XSCOPE
	#define DEMO_LIMIT 9000000
#endif // else !USE_XSCOPE

#define STR_LEN 80 // String Length

#define ERROR_OVERCURRENT 0x1
#define ERROR_UNDERVOLTAGE 0x2
#define ERROR_STALL 0x4
#define ERROR_DIRECTION 0x8

#pragma xta command "add exclusion foc_loop_motor_fault"
#pragma xta command "add exclusion foc_loop_speed_comms"
#pragma xta command "add exclusion foc_loop_shared_comms"
#pragma xta command "add exclusion foc_loop_startup"
#pragma xta command "analyze loop foc_loop"
#pragma xta command "set required - 40 us"

/** Different Estimation algorithms for coil currents Iq (and Id)*/
typedef enum IQ_EST_TAG
{
  TRANSFORM = 0,	// Uses Park/Clarke transforms on measured ADC coil currents
  EXTREMA,				// Uses Extrema of measured ADC coil currents
  VELOCITY,				// Uses measured velocity
  NUM_IQ_ESTIMATES    // Handy Value!-)
} IQ_EST_TYP;

/** Different Motor Phases */
typedef enum PHASE_TAG
{
  PHASE_A = 0,  // 1st Phase
  PHASE_B,		  // 2nd Phase
  PHASE_C,		  // 3rd Phase
  NUM_PHASES    // Handy Value!-)
} PHASE_TYP;

/** Different Motor Phases */
typedef enum MOTOR_STATE_TAG
{
  START = 0,	// Initial entry state
  SEARCH,		// Turn motor until FOC start condition found
  FOC,		  // Normal FOC state
	STALL,		// state where motor stalled
	STOP,			// Error state where motor stopped
  NUM_MOTOR_STATES	// Handy Value!-)
} MOTOR_STATE_TYP;

// WARNING: If altering Error types. Also update error-message in init_motor()
/** Different Motor Phases */
typedef enum ERROR_TAG
{
	OVERCURRENT = 0,
	UNDERVOLTAGE,
	STALLED,
	DIRECTION,
  NUM_ERR_TYPS	// Handy Value!-)
} ERROR_TYP;

typedef struct STRING_TAG // Structure containing string
{
	char str[STR_LEN]; // Array of characters
} STRING_TYP;

typedef struct MOTOR_DATA_TAG // Structure containing motor state data
{
	STRING_TYP err_strs[NUM_ERR_TYPS]; // Array of error messages
	MOTOR_STATE_TYP state; // Current motor state
	PID_CONST_TYP pid_consts[NUM_IQ_ESTIMATES][NUM_PIDS]; // array of PID const data for different IQ Estimate algorithms 
	PID_REGULATOR_TYP pid_regs[NUM_PIDS]; // array of pid regulators used for motor control
	int cnts[NUM_MOTOR_STATES]; // array of counters for each motor state	
	ADC_DATA_TYP meas_adc; // Structure containing measured data from ADC
	int meas_theta;	// Position as measured by the QEI
	int meas_veloc;	// angular velocity as measured by the QEI
	int meas_speed;	// speed, i.e. magnitude of angular velocity
	int est_Id;	// Estimated radial current value
	int est_Iq;	// Estimated tangential current value
	int req_Id;	// Requested current producing radial magnetic field.
	int req_Iq;	// Requested current producing tangential magnetic field
	int req_veloc;	// Requested (target) angular velocity set by the user/comms interface
	int half_veloc;	// Half requested angular velocity
	int Id_openloop;	// Requested Id value when tuning open-loop
	int Iq_openloop;	// Requested Iq value when tuning open-loop
	int pid_veloc;	// Output of angular velocity PID
	int pid_Id;	// Output of 'radial' current PID
	int pid_Iq;	// Output of 'tangential' current PID
	int set_Vd;	// Demand 'radial' voltage set by control loop
	int set_Vq;	// Demand 'tangential' voltage set by control loop 
	int set_theta;	// theta value
	int start_theta; // Theta start position during warm-up (START and SEARCH states)

	int iters; // Iterations of inner_loop
	unsigned id; // Unique Motor identifier e.g. 0 or 1
	unsigned prev_hall; // previous hall state value
	unsigned end_hall; // hall state at end of cycle. I.e. next value is first value of cycle (001)
	int Iq_alg;	// Algorithm used to estimate coil current Iq (and Id)
	unsigned err_flgs;	// Fault detection flags
	unsigned xscope;	// Flag set when xscope output required

	int rev_cnt;	// rev. counter (No. of origin traversals)
	int theta_offset;	// Phase difference between the QEI and the coils
	int phi_err;	// Error diffusion value for Phi value
	int phi_off;	// Phi value offset
	int gamma_est;	// Estimate of leading-angle, used to 'pull' pole towards coil.
	int gamma_off;	// Gamma value offset
	int gamma_err;	// Error diffusion value for Gamma value
	int Iq_err;	// Error diffusion value for scaling of measured Iq
	int adc_err;	// Error diffusion value for ADC extrema filter
	int prev_angl; 	// previous angular position
	unsigned prev_time; 	// previous time stamp
	unsigned mem_addr; // Shared memory address
	unsigned cur_buf; // Current double-buffer in use at shared memory address

	int filt_val; // filtered value
	int coef_err; // Coefficient diffusion error
	int scale_err; // Scaling diffusion error 

	int temp; // MB~ Dbg
} MOTOR_DATA_TYP;

static int dbg = 0; // Debug variable

/*****************************************************************************/
void init_motor( // initialise data structure for one motor
	MOTOR_DATA_TYP &motor_s, // reference to structure containing motor data
	unsigned motor_id // Unique Motor identifier e.g. 0 or 1
)
{
	int phase_cnt; // phase counter
	int err_cnt; // phase counter
	int pid_cnt; // PID counter


	// Initialise PID constants [ K_p ,K_i ,Kd, ,resolution ] ...

	init_pid_consts( motor_s.pid_consts[EXTREMA][I_D]		,400000 ,(256 << PID_RESOLUTION)	,0 ,PID_RESOLUTION );
	init_pid_consts( motor_s.pid_consts[EXTREMA][I_Q]		,400000 ,(256 << PID_RESOLUTION)	,0 ,PID_RESOLUTION );
	init_pid_consts( motor_s.pid_consts[EXTREMA][SPEED]	,20000	,(3 << PID_RESOLUTION)		,0 ,PID_RESOLUTION );

	init_pid_consts( motor_s.pid_consts[VELOCITY][I_D]		,12000 ,(8 << PID_RESOLUTION) ,0 ,PID_RESOLUTION );
	init_pid_consts( motor_s.pid_consts[VELOCITY][I_Q]		,12000 ,(8 << PID_RESOLUTION) ,0 ,PID_RESOLUTION );
	init_pid_consts( motor_s.pid_consts[VELOCITY][SPEED]	,11200 ,(8 << PID_RESOLUTION) ,0 ,PID_RESOLUTION );

	// Initialise PID regulators
	for (pid_cnt = 0; pid_cnt < NUM_PIDS; pid_cnt++)
	{ 
		initialise_pid( motor_s.pid_regs[pid_cnt] );
	} // for pid_cnt
	
	motor_s.id = motor_id; // Unique Motor identifier e.g. 0 or 1
	motor_s.iters = 0;
	motor_s.cnts[START] = 0;
	motor_s.state = START;
	motor_s.prev_hall = INIT_HALL;

// Choose last Hall state of 6-state cycle, depending on spin direction
#if (LDO_MOTOR_SPIN == 1)
	#define LAST_HALL_STATE 0b011
#else
	#define LAST_HALL_STATE 0b101
#endif

	motor_s.req_veloc = REQ_VELOCITY;
	motor_s.half_veloc = (motor_s.req_veloc >> 1);

	motor_s.Iq_alg = EXTREMA; // [TRANSFORM VELOCITY EXTREMA] Assign algorithm used to estimate coil current Iq (and Id)
	motor_s.set_theta = 0;
	motor_s.start_theta = 0; // Theta start position during warm-up (START and SEARCH states)
	motor_s.theta_offset = 0; // Offset between Hall-state and QEI origin
	motor_s.phi_err = 0; // Erro diffusion value for phi estimate
	motor_s.pid_Id = 0;	// Output from radial current PID
	motor_s.pid_Iq = 0;	// Output from tangential current PID
	motor_s.pid_veloc = 0;	// Output from velocity PID
	motor_s.set_Vd = 0;	// Ideal current producing radial magnetic field (NB never update as no radial force is required)
	motor_s.set_Vq = 0;	// Ideal current producing tangential magnetic field. (NB Updated based on the speed error)
	motor_s.est_Iq = 0;	// Clear Iq value estimated from measured angular velocity
	motor_s.err_flgs = 0; 	// Clear fault detection flags
	motor_s.xscope = 0; 	// Clear xscope print flag
	motor_s.prev_time = 0; 	// previous time stamp
	motor_s.prev_angl = 0; 	// previous angular position
	motor_s.cur_buf = 0; 	// Initialise which double-buffer in use
	motor_s.mem_addr = 0; 	// Signal unassigned address
	motor_s.coef_err = 0; // Clear Extrema Coef. diffusion error
	motor_s.scale_err = 0; // Clear Extrema Scaling diffusion error
	motor_s.Iq_err = 0; // Clear Error diffusion value for measured Iq
	motor_s.gamma_est = 0;	// Estimate of leading-angle, used to 'pull' pole towards coil.
	motor_s.gamma_off = 0;	// Gamma value offset
	motor_s.gamma_err = 0;	// Error diffusion value for Gamma value

	// Initialise error strings
	for (err_cnt=0; err_cnt<NUM_ERR_TYPS; err_cnt++)
	{
		safestrcpy( motor_s.err_strs[err_cnt].str ,"No Message! Please add in function init_motor()" );
	} // for err_cnt

	safestrcpy( motor_s.err_strs[OVERCURRENT].str ,"Over-Current Detected" );
	safestrcpy( motor_s.err_strs[UNDERVOLTAGE].str ,"Under-Voltage Detected" );
	safestrcpy( motor_s.err_strs[STALLED].str ,"Motor Stalled Persistently" );
	safestrcpy( motor_s.err_strs[DIRECTION].str ,"Motor Spinning In Wrong Direction!" );

	// NB Display will require following variables, before we have measured them! ...
	motor_s.meas_veloc = motor_s.req_veloc;
	motor_s.meas_speed = abs(motor_s.req_veloc);

	// Initialise variables dependant on spin direction
	if (0 > motor_s.req_veloc)
	{ // Negative spin direction
		motor_s.gamma_off = -GAMMA_INTERCEPT;
		motor_s.phi_off = -PHI_INTERCEPT;
		motor_s.Id_openloop = -REQ_ID_OPENLOOP; // Requested Id value when tuning open-loop
		motor_s.Iq_openloop = -REQ_IQ_OPENLOOP; // Requested Iq value when tuning open-loop

		// Choose last Hall state of 6-state cycle NB depends on motor-type
		if (LDO_MOTOR_SPIN)
		{
			motor_s.end_hall = 0b011;
		} // if (LDO_MOTOR_SPIN
		else
		{
			motor_s.end_hall = 0b101;
		} // else !(LDO_MOTOR_SPIN
	} // if (0 > motor_s.req_veloc)
	else
	{ // Positive spin direction
		motor_s.gamma_off = GAMMA_INTERCEPT;
		motor_s.phi_off = PHI_INTERCEPT;
		motor_s.Id_openloop = REQ_ID_OPENLOOP; // Requested Id value when tuning open-loop
		motor_s.Iq_openloop = REQ_IQ_OPENLOOP; // Requested Iq value when tuning open-loop

		// Choose last Hall state of 6-state cycle NB depends on motor-type
		if (LDO_MOTOR_SPIN)
		{
			motor_s.end_hall = 0b101;
		} // if (LDO_MOTOR_SPIN
		else
		{
			motor_s.end_hall = 0b011;
		} // else !(LDO_MOTOR_SPIN
	} // else !(0 > motor_s.req_veloc)

	motor_s.req_Id = motor_s.Id_openloop; // Requested 'radial' current
	motor_s.req_Iq = motor_s.Iq_openloop; // Requested 'tangential' current
	motor_s.filt_val = motor_s.Iq_openloop; // Preset filtered Iq value to something sensible

	for (phase_cnt = 0; phase_cnt < NUM_PHASES; phase_cnt++)
	{ 
		motor_s.meas_adc.vals[phase_cnt] = -1;
	} // for phase_cnt

	motor_s.temp = 0; // MB~ Dbg
} // init_motor
/*****************************************************************************/
void error_pwm_values( // Set PWM values to error condition
	unsigned pwm_vals[]	// Array of PWM variables
)
{
	int phase_cnt; // phase counter


	// loop through all phases
	for (phase_cnt = 0; phase_cnt < NUM_PHASES; phase_cnt++)
	{ 
		pwm_vals[phase_cnt] = -1;
	} // for phase_cnt
} // error_pwm_values
/*****************************************************************************/
int filter_adc_extrema( 		// Smooths adc extrema values using low-pass filter
	MOTOR_DATA_TYP &motor_s,	// reference to structure containing motor data
	int extreme_val						// Either a minimum or maximum ADC value
) // Returns filtered output value
/* This is a 1st order IIR filter, it is configured as a low-pass filter, 
 * The input value is up-scaled, to allow integer arithmetic to be used.
 * The output mean value is down-scaled by the same amount.
 * Error diffusion is used to keep control of systematic quantisation errors.
 */
{
	int scaled_inp = (extreme_val << XTR_SCALE_BITS); // Upscaled QEI input value
	int diff_val; // Difference between input and filtered output
	int increment; // new increment to filtered output value
	int out_val; // filtered output value


	// Form difference with previous filter output
	diff_val = scaled_inp - motor_s.filt_val;

	// Multiply difference by filter coefficient (alpha)
	diff_val += motor_s.coef_err; // Add in diffusion error;
	increment = (diff_val + XTR_HALF_COEF) >> XTR_COEF_BITS ; // Multiply by filter coef (with rounding)
	motor_s.coef_err = diff_val - (increment << XTR_COEF_BITS); // Evaluate new quantisation error value 

	motor_s.filt_val += increment; // Update (up-scaled) filtered output value

	// Update mean value by down-scaling filtered output value
	motor_s.filt_val += motor_s.scale_err; // Add in diffusion error;
	out_val = (motor_s.filt_val + XTR_HALF_SCALE) >> XTR_SCALE_BITS; // Down-scale
	motor_s.scale_err = motor_s.filt_val - (out_val << XTR_SCALE_BITS); // Evaluate new remainder value 

	return out_val; // return filtered output value
} // filter_adc_extrema
/*****************************************************************************/
int smooth_adc_maxima( // Smooths maximum ADC values
	MOTOR_DATA_TYP &motor_s // reference to structure containing motor data
)
{
	int max_val = motor_s.meas_adc.vals[0]; // Initialise maximum to first phase
	int phase_cnt; // phase counter
	int out_val; // filtered output value


	for (phase_cnt = 1; phase_cnt < NUM_PHASES; phase_cnt++)
	{ 
		if (max_val < motor_s.meas_adc.vals[phase_cnt]) max_val = motor_s.meas_adc.vals[phase_cnt]; // Update maximum
	} // for phase_cnt

	out_val = filter_adc_extrema( motor_s ,max_val );

	return out_val;
} // smooth_adc_maxima
/*****************************************************************************/
int smooth_adc_minima( // Smooths minimum ADC values
	MOTOR_DATA_TYP &motor_s // reference to structure containing motor data
)
{
	int min_val = motor_s.meas_adc.vals[0]; // Initialise minimum to first phase
	int phase_cnt; // phase counter
	int out_val; // filtered output value


	for (phase_cnt = 1; phase_cnt < NUM_PHASES; phase_cnt++)
	{ 
		if (min_val > motor_s.meas_adc.vals[phase_cnt]) min_val = motor_s.meas_adc.vals[phase_cnt]; // Update minimum
	} // for phase_cnt

	out_val = filter_adc_extrema( motor_s ,min_val );

	return out_val;
} // smooth_adc_minima
/*****************************************************************************/
void estimate_Iq_from_ADC_extrema( // Estimate Iq value from ADC signals. NB Assumes requested Id is Zero
	MOTOR_DATA_TYP &motor_s // reference to structure containing motor data
)
{
	int out_val; // Measured Iq output value


	if (0 > motor_s.req_veloc)
	{ // Iq is negative for negative velocity
		out_val = smooth_adc_minima( motor_s );
	} // if (0 > motor_s.req_veloc)
	else
	{ // Iq is positive for positive velocity
		out_val = smooth_adc_maxima( motor_s );
	} // if (0 > motor_s.req_veloc)

	motor_s.est_Iq = out_val;
	motor_s.est_Id = 0;
} // estimate_Iq_from_ADC_extrema
/*****************************************************************************/
void estimate_Iq_from_velocity( // Estimates tangential coil current from measured velocity
	MOTOR_DATA_TYP &motor_s // reference to structure containing motor data
)
/* This function uses the following relationship
 * est_Iq = GRAD * sqrt( meas_veloc )   where GRAD was found by experiment.
 * WARNING: GRAD will be different for different motors.
 */
{
	int scaled_vel = VEL_GRAD * motor_s.meas_veloc; // scaled angular velocity


	if (0 > motor_s.meas_veloc)
	{
		motor_s.est_Iq = -sqrtuint( -scaled_vel );
	} // if (0 > motor_s.meas_veloc)
	else
	{
		motor_s.est_Iq = sqrtuint( scaled_vel );
	} // if (0 > motor_s.meas_veloc)
} // estimate_Iq_from_velocity
/*****************************************************************************/
void estimate_Iq_using_transforms( // Calculate Id & Iq currents using transforms. NB Required if requested Id is NON-zero
	MOTOR_DATA_TYP &motor_s // reference to structure containing motor data
)
{
	int alpha_meas = 0, beta_meas = 0;	// Measured currents once transformed to a 2D vector
	int scaled_phi;	// Scaled Phi offset
	int phi_est;	// Estimated phase difference between PWM and ADC sinusoids
	int theta_park;	// Estimated theta value to get Max. Iq value from Park transform

#pragma xta label "foc_loop_clarke"

	// To calculate alpha and beta currents from measured data
	clarke_transform( motor_s.meas_adc.vals[PHASE_A], motor_s.meas_adc.vals[PHASE_B], motor_s.meas_adc.vals[PHASE_C], alpha_meas, beta_meas );
// if (motor_s.xscope) xscope_probe_data( 6 ,beta_meas );

	// Update Phi estimate ...
	scaled_phi = motor_s.meas_veloc * PHI_GRAD + motor_s.phi_off + motor_s.phi_err;
	phi_est = (scaled_phi + HALF_PHASE) >> PHASE_BITS;
	motor_s.phi_err = scaled_phi - (phi_est << PHASE_BITS);

	// Calculate theta value for Park transform
	theta_park = motor_s.meas_theta + motor_s.theta_offset + phi_est;
	theta_park &= QEI_REV_MASK; // Convert to base-range [0..QEI_REV_MASK]

#pragma xta label "foc_loop_park"

	// Estimate coil currents (Id & Iq) using park transform
	park_transform( motor_s.est_Id ,motor_s.est_Iq ,alpha_meas ,beta_meas ,theta_park );

} // estimate_Iq_using_transforms
/*****************************************************************************/
unsigned scale_to_12bit( // Returns coil current converted to 12-bit unsigned
	int inp_I  // Input coil current
)
{
	unsigned out_pwm; // output 12bit PWM value


	out_pwm = (inp_I + OFFSET_14) >> 3; // Convert coil current to PWM value. NB Always +ve

	// Clip PWM value into 12-bit range
	if (out_pwm > PWM_MAX_LIMIT)
	{ 
		out_pwm = PWM_MAX_LIMIT;
	} // if (out_pwm > PWM_MAX_LIMIT)
	else
	{
		if (out_pwm < PWM_MIN_LIMIT) out_pwm = PWM_MIN_LIMIT;
	} // else !(out_pwm > PWM_MAX_LIMIT)

	return out_pwm; // return clipped 12-bit PWM value
} // scale_to_12bit
/*****************************************************************************/
void dq_to_pwm ( // Convert Id & Iq input values to 3 PWM output values 
	MOTOR_DATA_TYP &motor_s, // Reference to structure containing motor data
	unsigned out_pwm[],	// Array of PWM variables
	int set_Vd, // Demand Radial voltage from the Voltage control PIDs
	int set_Vq, // Demand tangential voltage from the Voltage control PIDs
	unsigned inp_theta	// Input demand theta
)
{
	int volts[NUM_PHASES];	// array of intermediate demand voltages for each phase
	int alpha_set = 0, beta_set = 0; // New intermediate demand voltages as a 2D vector
	int phase_cnt; // phase counter

	// Inverse park  [d, q, theta] --> [alpha, beta]
	inverse_park_transform( alpha_set, beta_set, set_Vd, set_Vq, inp_theta  );

// if (motor_s.xscope) xscope_probe_data( 3 ,set_Vq );
// if (motor_s.xscope) xscope_probe_data( 4 ,alpha_set );
// if (motor_s.xscope) xscope_probe_data( 11 ,beta_set );

	// Final voltages applied: 
	inverse_clarke_transform( volts[PHASE_A] ,volts[PHASE_B] ,volts[PHASE_C] ,alpha_set ,beta_set ); // Correct order

	/* Scale to 12bit unsigned for PWM output */
	for (phase_cnt = 0; phase_cnt < NUM_PHASES; phase_cnt++)
	{ 
		out_pwm[phase_cnt] = scale_to_12bit( volts[phase_cnt] );
	} // for phase_cnt

// if (motor_s.xscope) xscope_probe_data( 0 ,out_pwm[PHASE_A] );
// if (motor_s.xscope) xscope_probe_data( 1 ,out_pwm[PHASE_B] );
// if (motor_s.xscope) xscope_probe_data( 2 ,out_pwm[PHASE_C] );
} // dq_to_pwm
/*****************************************************************************/
void calc_open_loop_pwm ( // Calculate open-loop PWM output values to spins magnetic field around (regardless of the encoder)
	MOTOR_DATA_TYP &motor_s // reference to structure containing motor data
)
{
	motor_s.set_Vd = motor_s.Id_openloop;
	motor_s.set_Vq = motor_s.Iq_openloop;

#if PLATFORM_REFERENCE_MHZ == 100
	assert ( 0 == 1 ); // MB~ 100 MHz Untested
	motor_s.set_theta = motor_s.start_theta >> 2;
#else
	motor_s.set_theta = motor_s.start_theta >> 4;
#endif

	// NB QEI_REV_MASK correctly maps -ve values into +ve range 0 <= theta < QEI_PER_REV;
	motor_s.set_theta &= QEI_REV_MASK; // Convert to base-range [0..QEI_REV_MASK]

	// Update start position ready for next iteration

	if (motor_s.req_veloc < 0)
	{
		motor_s.start_theta--; // Step on motor in ANTI-clockwise direction
	} // if (motor_s.req_veloc < 0)
	else
	{
		motor_s.start_theta++; // Step on motor in Clockwise direction
	} // else !(motor_s.req_veloc < 0)
} // calc_open_loop_pwm
/*****************************************************************************/
void calc_foc_pwm( // Calculate FOC PWM output values
	MOTOR_DATA_TYP &motor_s // reference to structure containing motor data
)
/* The estimated tangential coil current (Iq), is much less than the requested value (Iq)
 * (The ratio is between 25..42 for the LDO motors)
 * The estimated and requested values fed into the Iq PID must be simliar to ensure correct operation
 * Therefore, the requested value is scaled down by a factor of 32.
 */
{
	int targ_Iq;	// target measured Iq (scaled down requested Iq value)
	int corr_Id;	// Correction to radial current value
	int corr_Iq;	// Correction to tangential current value
	int corr_veloc;	// Correction to angular velocity
	int scaled_phase;	// Scaled Phase offset


	assert(motor_s.Iq_alg != TRANSFORM ); // Currently Unsupported. (PID tuning required for TRANSFORM)

#pragma xta label "foc_loop_speed_pid"

	// Applying Speed PID.

if (motor_s.xscope) xscope_probe_data( 5 ,motor_s.req_veloc );
	corr_veloc = get_pid_regulator_correction( motor_s.id ,motor_s.pid_regs[SPEED] ,motor_s.pid_consts[motor_s.Iq_alg][SPEED] ,motor_s.meas_veloc ,motor_s.req_veloc );

	// Calculate velocity PID output
	if (PROPORTIONAL)
	{ // Proportional update
		motor_s.pid_veloc = corr_veloc;
	} // if (PROPORTIONAL)
	else
	{ // Offset update
		motor_s.pid_veloc = motor_s.req_Iq + corr_veloc;
	} // else !(PROPORTIONAL)

if (motor_s.xscope) xscope_probe_data( 4 ,motor_s.pid_veloc );

	if (VELOC_CLOSED)
	{ // Evaluate set IQ from velocity PID
		motor_s.req_Iq = motor_s.pid_veloc;
	} // if (VELOC_CLOSED)
	else
	{ 
		motor_s.req_Iq = motor_s.Iq_openloop;
	} // if (VELOC_CLOSED)

#pragma xta label "foc_loop_id_iq_pid"

	// Select algorithm for estimateing coil current Iq (and Id)
	// WARNING: Changing algorithm will require re-tuning of PID values
	switch ( motor_s.Iq_alg )
	{
		case TRANSFORM : // Use Park/Clarke transforms
			estimate_Iq_using_transforms( motor_s );
			targ_Iq = (motor_s.req_Iq + 16) >> 5; // Scale requested value to be of same order as estimated value
		break; // case TRANSFORM
	
		case EXTREMA : // Use Extrema of measured ADC values
			estimate_Iq_from_ADC_extrema( motor_s );
			targ_Iq = (motor_s.req_Iq + 16) >> 5; // Scale requested value to be of same order as estimated value
		break; // case EXTREMA 
	
		case VELOCITY : // Use measured velocity
			estimate_Iq_from_velocity( motor_s );
			targ_Iq = motor_s.req_Iq; // NB No scaling required
		break; // case VELOCITY 
	
    default: // Unsupported
			printstr("ERROR: Unsupported Iq Estimation algorithm > "); 
			printintln( motor_s.Iq_alg );
			assert(0 == 1);
    break;
	} // switch (motor_s.Iq_alg)

if (motor_s.xscope) xscope_probe_data( 6 ,motor_s.est_Iq );

	// Apply PID control to Iq and Id

if (motor_s.xscope) xscope_probe_data( 8 ,targ_Iq );
	corr_Iq = get_pid_regulator_correction( motor_s.id ,motor_s.pid_regs[I_Q] ,motor_s.pid_consts[motor_s.Iq_alg][I_Q] ,motor_s.est_Iq ,targ_Iq );
	corr_Id = get_pid_regulator_correction( motor_s.id ,motor_s.pid_regs[I_D] ,motor_s.pid_consts[motor_s.Iq_alg][I_D] ,motor_s.est_Id ,motor_s.req_Id  );

	if (PROPORTIONAL)
	{ // Proportional update
		motor_s.pid_Id = corr_Id;
		motor_s.pid_Iq = corr_Iq;
	} // if (PROPORTIONAL)
	else
	{ // Offset update
		motor_s.pid_Id = motor_s.set_Vd + corr_Id;
		motor_s.pid_Iq = motor_s.set_Vq + corr_Iq;
	} // else !(PROPORTIONAL)
if (motor_s.xscope) xscope_probe_data( 7 ,motor_s.pid_Iq );

	if (IQ_ID_CLOSED)
	{ // Update set DQ values
		motor_s.set_Vd = motor_s.pid_Id; //MB~ Dbg
		motor_s.set_Vd = motor_s.req_Id;

		motor_s.set_Vq = motor_s.pid_Iq;
	} // if (IQ_ID_CLOSED)
	else
	{
		calc_open_loop_pwm( motor_s );
	} // if (IQ_ID_CLOSED)

if (motor_s.xscope) xscope_probe_data( 3 ,motor_s.set_Vq );

	// Update Gamma estimate ...
	scaled_phase = motor_s.meas_veloc * GAMMA_GRAD + motor_s.gamma_off + motor_s.gamma_err;
	motor_s.gamma_est = (scaled_phase + HALF_PHASE) >> PHASE_BITS;
	motor_s.gamma_err = scaled_phase - (motor_s.gamma_est << PHASE_BITS);

	// Update 'demand' theta value for next dq_to_pwm iteration
	motor_s.set_theta = motor_s.meas_theta + motor_s.theta_offset + motor_s.gamma_est;
	motor_s.set_theta &= QEI_REV_MASK; // Convert to base-range [0..QEI_REV_MASK]
if (motor_s.xscope) xscope_probe_data( 0 ,motor_s.set_theta );

} // calc_foc_pwm
/*****************************************************************************/
MOTOR_STATE_TYP check_hall_state( // Inspect Hall-state and update motor-state if necessary
	MOTOR_DATA_TYP &motor_s, // Reference to structure containing motor data
	unsigned hall_inp // Input Hall state
) // Returns new motor-state
/* The input pins from the Hall port hold the following data
 * Bit_3: Over-current flag (NB Value zero is over-current)
 * Bit_2: Hall Sensor Phase_A
 * Bit_1: Hall Sensor Phase_B
 * Bit_0: Hall Sensor Phase_C
 *
 * The Sensor bits are toggled every 180 degrees. 
 * Each phase is separated by 120 degrees. This gives the following bit pattern for ABC
 * 
 *          <---------- Anti-Clockwise <----------
 * (011) -> 001 -> 101 -> 100 -> 110 -> 010 -> 011 -> (001)
 *          ------------> Clock-Wise ------------>
 * 
 * WARNING: Each motor manufacturer uses their own definition for spin direction.
 * So key Hall-states are implemented as defines e.g. FIRST_HALL and LAST_HALL
 *
 * For the purposes of this algorithm, the angular position origin is defined as
 * the transition from the last-state to the first-state.
 */
{
	MOTOR_STATE_TYP motor_state = motor_s.state; // Initialise to old motor state


	hall_inp &= 0x7; // Clear Over-Current bit

	// Check for change in Hall state
	if (motor_s.prev_hall != hall_inp)
	{
		// Check for 1st Hall state, as we only do this check once a revolution
		if (hall_inp == FIRST_HALL_STATE) 
		{
			// Check for correct spin direction
			if (motor_s.prev_hall == motor_s.end_hall)
			{ // Spinning in correct direction

				// Check if the angular origin has been found, AND, we have done more than one revolution
				if (1 < abs(motor_s.rev_cnt))
				{
					/* Calculate the offset between arbitary set_theta and actual measured theta,
					 * NB There are multiple values of set_theta that can be used for each meas_theta, 
           * depending on the number of pole pairs. E.g. [0, 256, 512, 768] are equivalent.
					 */
					motor_s.theta_offset = motor_s.set_theta - motor_s.meas_theta;
					motor_state = FOC; // Switch to main FOC state
					motor_s.cnts[FOC] = 0; // Initialise FOC-state counter 
				} // if (0 < motor_s.rev_cnt)
			} // if (motor_s.prev_hall == motor_s.end_hall)
			else
			{ // We are probably spinning in the wrong direction!-(
				motor_s.err_flgs |= ERROR_DIRECTION;
				motor_state = STOP; // Switch to stop state
				motor_s.cnts[STOP] = 0; // Initialise stop-state counter 
if (dbg) { printint(motor_s.id); printstr( " SE- " ); printintln( motor_s.cnts[SEARCH] ); } 
			} // else !(motor_s.prev_hall == motor_s.end_hall)
		} // if (hall_inp == FIRST_HALL_STATE)

		motor_s.prev_hall = hall_inp; // Store hall state for next iteration
	} // if (motor_s.prev_hall != hall_inp)

	return motor_state; // Return updated motor state
} // check_hall_state
/*****************************************S************************************/
void update_motor_state( // Update state of motor based on motor sensor data
	MOTOR_DATA_TYP &motor_s, // reference to structure containing motor data
	unsigned hall_inp // Input Hall state
)
/* This routine is inplemented as a Finite-State-Machine (FSM) with the following 5 states:-
 *	START:	Initial entry state
 *	SEARCH: Warm-up state where the motor is turned until the FOC start condition is found
 *	FOC: 		Normal FOC state
 *	STALL:	Motor has stalled, 
 *	STOP:		Error state: Destination state if error conditions are detected
 *
 * During the SEARCH state, the motor runs in open loop with the hall sensor responses,
 *  then when synchronisation has been achieved the motor switches to the FOC state, which uses the main FOC algorithm.
 * If too long a time is spent in the STALL state, this becomes an error and the motor is stopped.
 */
{
	MOTOR_STATE_TYP motor_state; // local motor state


	// Update motor state based on new sensor data
	switch( motor_s.state )
	{
		case START : // Intial entry state
			if (0 != motor_s.rev_cnt) // Check if angular position origin found
			{
				motor_s.state = SEARCH; // Switch to search state
				motor_s.cnts[SEARCH] = 0; // Initialise search-state counter
if (dbg) { printint(motor_s.id); printstr( " SA: " ); printintln( motor_s.cnts[START] ); } 
			} // if (0 != motor_s.rev_cnt)
		break; // case START

		case SEARCH : // Turn motor using Hall state, and update motor state
			motor_state = check_hall_state( motor_s ,hall_inp ); 
 			motor_s.state = motor_state; // NB Required due to XC compiler rules
		break; // case SEARCH 
	
		case FOC : // Normal FOC state
			// Check for a stall
// if (dbg) { printint(motor_s.id); printchar(': '); printint( motor_s.meas_veloc ); printchar(' '); printint( motor_s.meas_theta ); printchar(' '); printintln( motor_s.valid ); }
			// check for correct spin direction
      if (0 > motor_s.half_veloc)
			{
				if (motor_s.meas_veloc > -motor_s.half_veloc)
				{	// Spinning in wrong direction
					motor_s.err_flgs |= ERROR_DIRECTION;
					motor_s.state = STOP; // Switch to stop state
					motor_s.cnts[STOP] = 0; // Initialise stop-state counter 
				} // if (motor_s.meas_veloc > -motor_s.half_veloc)
      } // if (0 > motor_s.half_veloc)
			else
			{
				if (motor_s.meas_veloc < -motor_s.half_veloc)
				{	// Spinning in wrong direction
					motor_s.err_flgs |= ERROR_DIRECTION;
					motor_s.state = STOP; // Switch to stop state
					motor_s.cnts[STOP] = 0; // Initialise stop-state counter 
				} // if (motor_s.meas_veloc < -motor_s.half_veloc)
      } // if (0 > motor_s.half_veloc)

			if (motor_s.meas_speed < STALL_SPEED) 
			{
				motor_s.state = STALL; // Switch to stall state
				motor_s.cnts[STALL] = 0; // Initialise stall-state counter 
if (dbg) { printint(motor_s.id); printstr( " FO: " ); printintln( motor_s.cnts[FOC] ); } 
			} // if (motor_s.meas_speed < STALL_SPEED)
		break; // case FOC
	
		case STALL : // state where motor stalled
			// Check if still stalled
			if (motor_s.meas_speed < STALL_SPEED) 
			{
				// Check if too many stalled states
				if (motor_s.cnts[STALL] > STALL_TRIP_COUNT) 
				{
					motor_s.err_flgs |= ERROR_STALL;
					motor_s.state = STOP; // Switch to stop state
					motor_s.cnts[STOP] = 0; // Initialise stop-state counter 
if (dbg) { printint(motor_s.id); printstr( " SL- " ); printintln( motor_s.cnts[STALL] ); } 
				} // if (motor_s.cnts[STALL] > STALL_TRIP_COUNT) 
			} // if (motor_s.meas_speed < STALL_SPEED) 
			else
			{ // No longer stalled
				motor_s.state = FOC; // Switch to main FOC state
				motor_s.cnts[FOC] = 0; // Initialise FOC-state counter 
if (dbg) { printint(motor_s.id); printstr( " SL: " ); printintln( motor_s.cnts[STALL] ); } 
			} // else !(motor_s.meas_speed < STALL_SPEED) 
		break; // case STALL
	
		case STOP : // Error state where motor stopped
			// Absorbing state. Nothing to do
		break; // case STOP
	
    default: // Unsupported
			assert(0 == 1); // Motor state not supported
    break;
	} // switch( motor_s.state )

	motor_s.cnts[motor_s.state]++; // Update counter for new motor state 

	// Select correct method of calculating DQ values
#pragma fallthrough
	switch( motor_s.state )
	{
		case START : // Intial entry state
			calc_open_loop_pwm( motor_s );
		break; // case START

		case SEARCH : // Turn motor until FOC start condition found
 			calc_open_loop_pwm( motor_s );
		break; // case SEARCH 
	
		case FOC : // Normal FOC state
			calc_foc_pwm( motor_s );
		break; // case FOC

		case STALL : // state where motor stalled
			calc_foc_pwm( motor_s );
		break; // case STALL

		case STOP : // Error state where motor stopped
			// Nothing to do
		break; // case STOP
	
    default: // Unsupported
			assert(0 == 1); // Motor state not supported
    break;
	} // switch( motor_s.state )

	return;
} // update_motor_state
/*****************************************************************************/
#pragma unsafe arrays
void use_motor ( // Start motor, and run step through different motor states
	MOTOR_DATA_TYP &motor_s, // reference to structure containing motor data
	chanend c_pwm, 
	streaming chanend c_hall, 
	streaming chanend c_qei, 
	streaming chanend c_adc_cntrl, 
	chanend c_speed, 
	chanend c_can_eth_shared 
)
{
	unsigned pwm_vals[NUM_PHASES]; // Array of PWM values

	int phase_cnt; // phase counter
	unsigned command;	// Command received from the control interface
	unsigned new_hall;	// New Hall state


	// initialise arrays
	for (phase_cnt = 0; phase_cnt < NUM_PHASES; phase_cnt++)
	{ 
		pwm_vals[phase_cnt] = 0;
	} // for phase_cnt

#ifdef SHARED_MEM
	c_pwm :> motor_s.mem_addr; // Receive shared memory address from PWM server
#endif // #ifdef SHARED_MEM

	/* Main loop */
	while (STOP != motor_s.state)
	{
#pragma xta endpoint "foc_loop"
		select
		{
		case c_speed :> command:		/* This case responds to speed control through shared I/O */
#pragma xta label "foc_loop_speed_comms"
			switch(command)
			{
				case CMD_GET_IQ :
					c_speed <: motor_s.meas_veloc;
					c_speed <: motor_s.req_veloc;
				break; // case CMD_GET_IQ
	
				case CMD_SET_SPEED :
					c_speed :> motor_s.req_veloc;
					motor_s.half_veloc = (motor_s.req_veloc >> 1);
				break; // case CMD_SET_SPEED 
	
				case CMD_GET_FAULT :
					c_speed <: motor_s.err_flgs;
				break; // case CMD_GET_FAULT 
	
		    default: // Unsupported
					assert(0 == 1); // command NOT supported
		    break; // default
			} // switch(command)

		break; // case c_speed :> command:

		case c_can_eth_shared :> command:		//This case responds to CAN or ETHERNET commands
#pragma xta label "foc_loop_shared_comms"
			if(command == CMD_GET_VALS)
			{
				c_can_eth_shared <: motor_s.meas_veloc;
				c_can_eth_shared <: motor_s.meas_adc.vals[PHASE_A];
				c_can_eth_shared <: motor_s.meas_adc.vals[PHASE_B];
			}
			else if(command == CMD_GET_VALS2)
			{
				c_can_eth_shared <: motor_s.meas_adc.vals[PHASE_C];
				c_can_eth_shared <: motor_s.pid_veloc;
				c_can_eth_shared <: motor_s.pid_Id;
				c_can_eth_shared <: motor_s.pid_Iq;
			}
			else if (command == CMD_SET_SPEED)
			{
				c_can_eth_shared :> motor_s.req_veloc;
				motor_s.half_veloc = (motor_s.req_veloc >> 1);
			}
			else if (command == CMD_GET_FAULT)
			{
				c_can_eth_shared <: motor_s.err_flgs;
			}

		break; // case c_can_eth_shared :> command:

		default:	// This case updates the motor state
			motor_s.iters++; // Increment No. of iterations 

			// NB There is not enough band-width to probe all xscope data
			if ((motor_s.id) & !(motor_s.iters & 15)) // probe every 8th value
			{
				motor_s.xscope = 1; // Switch ON xscope probe
			} // if ((motor_s.id) & !(motor_s.iters & 7))
			else
			{
				motor_s.xscope = 0; // Switch OFF xscope probe
			} // if ((motor_s.id) & !(motor_s.iters & 7))
// motor_s.xscope = 0; // MB~ Crude Switch

			if (STOP != motor_s.state)
			{
				// Check if it is time to stop demo
				if (motor_s.iters > DEMO_LIMIT)
				{
					motor_s.state = STOP; // Switch to stop state
					motor_s.cnts[STOP] = 0; // Initialise stop-state counter 
				} // if (motor_s.iters > DEMO_LIMIT)

				new_hall = get_hall_data( c_hall ); // Get new hall state
// if (motor_s.xscope) xscope_probe_data( 5 ,(100 * (new_hall & 7)));

				// Check error status
				if (!(new_hall & 0b1000))
				{
					motor_s.err_flgs |= ERROR_OVERCURRENT;
					motor_s.state = STOP; // Switch to stop state
					motor_s.cnts[STOP] = 0; // Initialise stop-state counter 
				} // if (!(new_hall & 0b1000))
				else
				{
					/* Get the position from encoder module. NB returns rev_cnt=0 at start-up  */
					{ motor_s.meas_veloc ,motor_s.meas_theta ,motor_s.rev_cnt } = get_qei_data( c_qei );
						motor_s.meas_speed = abs( motor_s.meas_veloc ); // NB Used to spot stalling behaviour

						if (4400 < motor_s.meas_speed) // Safety
						{
							printstr("AngVel:"); printintln( motor_s.meas_veloc );
								motor_s.state= STOP;
						} // if (4100 < motor_s.meas_veloc)

// if (motor_s.xscope) xscope_probe_data( 0 ,motor_s.rev_cnt );
if (motor_s.xscope) xscope_probe_data( 1 ,motor_s.meas_theta );
if (motor_s.xscope) xscope_probe_data( 2 ,motor_s.meas_veloc );

					/* Get ADC readings */
					get_adc_vals_calibrated_int16_mb( c_adc_cntrl ,motor_s.meas_adc );
// if (motor_s.xscope) xscope_probe_data( 3 ,motor_s.meas_adc.vals[PHASE_A] );
// if (motor_s.xscope) xscope_probe_data( 4 ,motor_s.meas_adc.vals[PHASE_B] );
// if (motor_s.xscope) xscope_probe_data( 5 ,motor_s.meas_adc.vals[PHASE_C] );

					update_motor_state( motor_s ,new_hall );
				} // else !(!(new_hall & 0b1000))

				// Check if motor needs stopping
				if (STOP == motor_s.state)
				{
					// Set PWM values to stop motor
					error_pwm_values( pwm_vals );
				} // if (STOP == motor_s.state)
				else
				{
					// Convert new set DQ values to PWM values
if (motor_s.xscope) xscope_probe_data( 0 ,motor_s.set_theta );
					dq_to_pwm( motor_s ,pwm_vals ,motor_s.set_Vd ,motor_s.set_Vq ,motor_s.set_theta ); // Convert Output DQ values to PWM values

					update_pwm_inv( c_pwm ,pwm_vals ,motor_s.id ,motor_s.cur_buf ,motor_s.mem_addr ); // Update the PWM values

#ifdef USE_XSCOPE
					if ((motor_s.cnts[FOC] & 0x1) == 0) // If even, (NB Forgotton why this works!-(
					{
						if (0 == motor_s.id) // Check if 1st Motor
						{
/*
							xscope_probe_data(0, motor_s.meas_veloc );
				  	  xscope_probe_data(1, motor_s.set_Vq );
	    				xscope_probe_data(2, pwm_vals[PHASE_A] );
	    				xscope_probe_data(3, pwm_vals[PHASE_B]);
							xscope_probe_data(4, motor_s.meas_adc.vals[PHASE_A] );
							xscope_probe_data(5, motor_s.meas_adc.vals[PHASE_B]);
*/
						} // if (0 == motor_s.id)
					} // if ((motor_s.cnts[FOC] & 0x1) == 0) 
#endif
				} // else !(STOP == motor_s.state)
			} // if (STOP != motor_s.state)
		break; // default:

		}	// select

	}	// while (STOP != motor_s.state)

} // use_motor
/*****************************************************************************/
void error_handling( // Prints out error messages
	MOTOR_DATA_TYP &motor_s // Reference to structure containing motor data
)
{
	int err_cnt; // counter for different error types 
	unsigned cur_flgs = motor_s.err_flgs; // local copy of error flags

	// Loop through error types
	for (err_cnt=0; err_cnt<NUM_ERR_TYPS; err_cnt++)
	{
		// Test LS-bit for active flag
		if (cur_flgs & 1)
		{
			printstrln( motor_s.err_strs[err_cnt].str );
		} // if (cur_flgs & 1)

		cur_flgs >>= 1; // Discard flag
	} // for err_cnt

} // error_handling
/*****************************************************************************/
#pragma unsafe arrays
void run_motor ( 
	unsigned motor_id,
	chanend? c_wd,
	chanend c_pwm,
	streaming chanend c_hall, 
	streaming chanend c_qei, 
	streaming chanend c_adc_cntrl, 
	chanend c_speed, 
	chanend c_can_eth_shared 
)
{
	MOTOR_DATA_TYP motor_s; // Structure containing motor data
	timer t;	/* Timer */
	unsigned ts1;	/* timestamp */


	// Pause to allow the rest of the system to settle
	{
		unsigned thread_id = get_logical_core_id();
		t :> ts1;
		t when timerafter(ts1+2*SEC+256*thread_id) :> void;
	}

	/* allow the WD to get going */
	if (!isnull(c_wd)) 
	{
		c_wd <: WD_CMD_START;
	}

	// Pause to allow the rest of the system to settle
	{
		unsigned thread_id = get_logical_core_id();
		t :> ts1;
		t when timerafter(ts1+1*SEC) :> void;
	}

	init_motor( motor_s ,motor_id );	// Initialise motor data

	if (0 == motor_id) printstrln( "Demo Starts" ); // NB Prevent duplicate display lines

	// start-and-run motor
	use_motor( motor_s ,c_pwm ,c_hall ,c_qei ,c_adc_cntrl ,c_speed ,c_can_eth_shared );

	if (1 == motor_id)
	{
		if (motor_s.err_flgs)
		{
			printstr( "Demo Ended Due to Following Errors on Motor " );
			printintln(motor_s.id);
			error_handling( motor_s );
		} // if (motor_s.err_flgs)
		else
		{
			printstrln( "Demo Ended Normally" );
		} // else !(motor_s.err_flgs)

		_Exit(1); // Exit without flushing buffers
	} // if (0 == motor_id)
} // run_motor
/*****************************************************************************/
// inner_loop.xc
