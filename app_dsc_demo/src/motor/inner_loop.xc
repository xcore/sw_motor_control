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

#include "pid_regulator.h"
#include "qei_commands.h"
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

#define IQ_OPEN_LOOP 2000 // Iq value for open-loop mode
#define ID_OPEN_LOOP 0		// Id value for open-loop mode
#define INIT_HALL 0 // Initial Hall state
#define INIT_THETA 0 // Initial start-up angle
#define INIT_SPEED 400 // Initial start-up speed

#ifdef USE_XSCOPE
	#define DEMO_LIMIT 100000 // XSCOPE
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
	ADC_DATA_TYP meas_adc; // Structure containing measured data from ADC
	MOTOR_STATE_TYP state; // Current motor state
	PID_REGULATOR_TYP pids[NUM_PIDS]; // array of pid regulators used for motor control
	int cnts[NUM_MOTOR_STATES]; // array of counters for each motor state	
	int iters; // Iterations of inner_loop
	unsigned id; // Unique Motor identifier e.g. 0 or 1
	unsigned prev_hall; // previous hall state value
	unsigned end_hall; // hall state at end of cycle. I.e. next value is first value of cycle (001)
	int set_theta;	// theta value
	int set_veloc;	// Demand angular velocity set by the user/comms interface
	int half_veloc;	// Half demand angular velocity
	int set_id;	// Ideal current producing radial magnetic field.
	int set_iq;	// Ideal current producing tangential magnetic field
	int start_theta; // Theta start position during warm-up (START and SEARCH states)
	unsigned err_flgs;	// Fault detection flags

	int out_id;	// Output radial current value
	int out_iq;	// Output measured tangential current value
	int iq_start;	// Initial Iq value for starting in open-loop mode
	int meas_theta;	// Position as measured by the QEI
	int meas_veloc;	// angular velocity as measured by the QEI
	int meas_speed;	// speed, i.e. magnitude of angular velocity
	int rev_cnt;	// rev. counter (No. of origin traversals)
	int theta_offset;	// Phase difference between the QEI and the coils
	int prev_angl; 	// previous angular position
	unsigned prev_time; 	// previous time stamp
	unsigned mem_addr; // Shared memory address
	unsigned cur_buf; // Current double-buffer in use at shared memory address
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


	/* PID control initialisation... */
	for (pid_cnt = 0; pid_cnt < NUM_PIDS; pid_cnt++)
	{ 
		initialise_pid( motor_s.pids[pid_cnt] ,pid_cnt );
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


	motor_s.set_theta = 0;
	motor_s.set_veloc = -INIT_SPEED;
	motor_s.half_veloc = (motor_s.set_veloc >> 1);
	motor_s.start_theta = 0; // Theta start position during warm-up (START and SEARCH states)
	motor_s.theta_offset = 0; // Offset between Hall-state and QEI origin
	motor_s.set_id = 0;	// Ideal current producing radial magnetic field (NB never update as no radial force is required)
	motor_s.set_iq = 0;	// Ideal current producing tangential magnetic field. (NB Updated based on the speed error)
	motor_s.err_flgs = 0; 	// Clear fault detection flags
	motor_s.prev_time = 0; 	// previous time stamp
	motor_s.prev_angl = 0; 	// previous angular position
	motor_s.cur_buf = 0; 	// Initialise which double-buffer in use
	motor_s.mem_addr = 0; 	// Signal unassigned address

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
	motor_s.meas_veloc = motor_s.set_veloc;
	motor_s.meas_speed = abs(motor_s.set_veloc);

	// Initialise variables dependant on spin direction
	if (0 > motor_s.set_veloc)
	{ // Negative spin direction
		motor_s.iq_start = -IQ_OPEN_LOOP;

		// Choose last Hall state of 6-state cycle NB depends on motor-type
		if (LDO_MOTOR_SPIN)
		{
			motor_s.end_hall = 0b011;
		} // if (LDO_MOTOR_SPIN
		else
		{
			motor_s.end_hall = 0b101;
		} // else !(LDO_MOTOR_SPIN
	} // if (0 > motor_s.set_veloc)
	else
	{ // Positive spin direction
		motor_s.iq_start = IQ_OPEN_LOOP;

		// Choose last Hall state of 6-state cycle NB depends on motor-type
		if (LDO_MOTOR_SPIN)
		{
			motor_s.end_hall = 0b101;
		} // if (LDO_MOTOR_SPIN
		else
		{
			motor_s.end_hall = 0b011;
		} // else !(LDO_MOTOR_SPIN
	} // else !(0 > motor_s.set_veloc)

	for (phase_cnt = 0; phase_cnt < NUM_PHASES; phase_cnt++)
	{ 
		motor_s.meas_adc.vals[phase_cnt] = -1;
	} // for phase_cnt

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
	int inp_id, // Input radial current from the current control PIDs
	int inp_iq, // Input tangential currents from the current control PIDs
	unsigned inp_theta	// Input demand theta
)
{
	int I_coil[NUM_PHASES];	// array of intermediate coil currents for each phase
	int alpha_new = 0, beta_new = 0; // New Intermediate currents as a 2D vector
	int phase_cnt; // phase counter


	/* Inverse park  [d,q] to [alpha, beta] */
	inverse_park_transform( alpha_new, beta_new, inp_id, inp_iq, inp_theta  );

	// Final voltages applied: 
	inverse_clarke_transform( I_coil[PHASE_A] ,I_coil[PHASE_B] ,I_coil[PHASE_C] ,alpha_new ,beta_new ); // Correct order

	/* Scale to 12bit unsigned for PWM output */
	for (phase_cnt = 0; phase_cnt < NUM_PHASES; phase_cnt++)
	{ 
		out_pwm[phase_cnt] = scale_to_12bit( I_coil[phase_cnt] );
	} // for phase_cnt

} // dq_to_pwm
/*****************************************************************************/
void calc_open_loop_pwm ( // Calculate open-loop PWM output values to spins magnetic field around (regardless of the encoder)
	MOTOR_DATA_TYP &motor_s // reference to structure containing motor data
)
{

#if PLATFORM_REFERENCE_MHZ == 100
	assert ( 0 == 1 ); // MB~ 100 MHz Untested
	motor_s.set_theta = motor_s.start_theta >> 2;
#else
	motor_s.set_theta = motor_s.start_theta >> 4;
#endif

	// NB QEI_REV_MASK correctly maps -ve values into +ve range 0 <= theta < QEI_PER_REV;
	motor_s.set_theta &= QEI_REV_MASK; // Convert to base-range [0..QEI_REV_MASK]
	motor_s.out_id = ID_OPEN_LOOP;
	motor_s.out_iq = motor_s.iq_start;

	// Update start position ready for next iteration

	if (motor_s.set_veloc < 0)
	{
		motor_s.start_theta--; // Step on motor in ANTI-clockwise direction
	} // if (motor_s.set_veloc < 0)
	else
	{
		motor_s.start_theta++; // Step on motor in Clockwise direction
	} // else !(motor_s.set_veloc < 0)
} // calc_open_loop_pwm
/*****************************************************************************/
void calc_foc_pwm ( // Calculate FOC PWM output values
	MOTOR_DATA_TYP &motor_s // reference to structure containing motor data
)
{
	int alpha = 0, beta = 0;	// Measured currents once transformed to a 2D vector
	int Id_in = 0, Iq_in = 0;	/* Measured radial and tangential currents in the rotor frame of reference */


#pragma xta label "foc_loop_read_hardware"

	// Calculate driving theta value from measured value and offset
	motor_s.set_theta = motor_s.meas_theta + motor_s.theta_offset;

	motor_s.set_theta &= QEI_REV_MASK; // Convert to base-range [0..QEI_REV_MASK]

#pragma xta label "foc_loop_clarke"

	/* To calculate alpha and beta currents */
	clarke_transform(motor_s.meas_adc.vals[PHASE_A], motor_s.meas_adc.vals[PHASE_B], motor_s.meas_adc.vals[PHASE_C], alpha, beta );

#pragma xta label "foc_loop_park"

	// Calculate actual coil currents (Id & Iq) using park transform
	park_transform( Id_in, Iq_in, alpha, beta, motor_s.set_theta  );

#pragma xta label "foc_loop_speed_pid"

	// Applying Speed PID.

	motor_s.set_iq = get_pid_regulator_correction( motor_s.id ,motor_s.pids[SPEED] ,motor_s.meas_veloc ,motor_s.set_veloc );
// if (motor_s.id) xscope_probe_data( 5 ,motor_s.pids[SPEED].sum_err );

#pragma xta label "foc_loop_id_iq_pid"


	/* Apply PID control to Iq and Id */
	motor_s.out_iq = get_pid_regulator_correction( motor_s.id ,motor_s.pids[I_Q] ,Iq_in ,motor_s.set_iq );

	motor_s.out_id = get_pid_regulator_correction( motor_s.id ,motor_s.pids[I_D] ,Id_in ,motor_s.set_id );

} // calc_foc_pwm
/*****************************************************************************/
MOTOR_STATE_TYP check_hall_state( // Inspect Hall-state and update motor-state if necessary
	MOTOR_DATA_TYP &motor_s, // Reference to structure containing motor data
	unsigned inp_hall // Input Hall state
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


	inp_hall &= 0x7; // Clear Over-Current bit

	// Check for change in Hall state
	if (motor_s.prev_hall != inp_hall)
	{
		// Check for 1st Hall state, as we only do this check once a revolution
		if (inp_hall == FIRST_HALL_STATE) 
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
		} // if (inp_hall == FIRST_HALL_STATE)

		motor_s.prev_hall = inp_hall; // Store hall state for next iteration
	} // if (motor_s.prev_hall != inp_hall)

	return motor_state; // Return updated motor state
} // check_hall_state
/*****************************************************************************/
void update_motor_state( // Update state of motor based on motor sensor data
	MOTOR_DATA_TYP &motor_s, // reference to structure containing motor data
	unsigned inp_hall // Input Hall state
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
			motor_state = check_hall_state( motor_s ,inp_hall ); 
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
	streaming chanend c_qei, 
	streaming chanend c_adc_cntrl, 
	chanend c_speed, 
	port in p_hall, 
	chanend c_can_eth_shared 
)
{
	unsigned pwm_vals[NUM_PHASES]; // Array of PWM values

	int phase_cnt; // phase counter
	int id_out = 0, iq_out = 0;	/* The demand radial and tangential currents from the current control PIDs */
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
					c_speed <: motor_s.set_veloc;
				break; // case CMD_GET_IQ
	
				case CMD_SET_SPEED :
					c_speed :> motor_s.set_veloc;
					motor_s.half_veloc = (motor_s.set_veloc >> 1);
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
				c_can_eth_shared <: motor_s.set_iq;
				c_can_eth_shared <: id_out;
				c_can_eth_shared <: iq_out;
			}
			else if (command == CMD_SET_SPEED)
			{
				c_can_eth_shared :> motor_s.set_veloc;
				motor_s.half_veloc = (motor_s.set_veloc >> 1);
			}
			else if (command == CMD_GET_FAULT)
			{
				c_can_eth_shared <: motor_s.err_flgs;
			}

		break; // case c_can_eth_shared :> command:

		default:	// This case updates the motor state
			motor_s.iters++; // Increment No. of iterations 

			if (STOP != motor_s.state)
			{
				// Check if it is time to stop demo
				if (motor_s.iters > DEMO_LIMIT)
				{
					motor_s.state = STOP; // Switch to stop state
					motor_s.cnts[STOP] = 0; // Initialise stop-state counter 
				} // if (motor_s.iters > DEMO_LIMIT)

				p_hall :> new_hall; // Get new hall state
if (motor_s.id) xscope_probe_data( 5 ,(100 * (new_hall & 7)));

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
if (motor_s.id) xscope_probe_data( 1 ,motor_s.meas_theta );
if (motor_s.id) xscope_probe_data( 2 ,motor_s.meas_veloc );
if (motor_s.id) xscope_probe_data( 3 ,motor_s.rev_cnt );

						motor_s.meas_speed = abs( motor_s.meas_veloc ); // NB Used to spot stalling behaviour
					/* Get ADC readings */
					get_adc_vals_calibrated_int16_mb( c_adc_cntrl ,motor_s.meas_adc );

					update_motor_state( motor_s ,new_hall );
if (motor_s.id) xscope_probe_data( 0 ,motor_s.set_theta );
if (motor_s.id) xscope_probe_data( 4 ,motor_s.theta_offset );
				} // else !(!(new_hall & 0b1000))

				// Check if motor needs stopping
				if (STOP == motor_s.state)
				{
					// Set PWM values to stop motor
					error_pwm_values( pwm_vals );
				} // if (STOP == motor_s.state)
				else
				{
					// Convert Output DQ values to PWM values
					dq_to_pwm( motor_s ,pwm_vals ,motor_s.out_id ,motor_s.out_iq ,motor_s.set_theta ); // Convert Output DQ values to PWM values

					update_pwm_inv( c_pwm ,pwm_vals ,motor_s.id ,motor_s.cur_buf ,motor_s.mem_addr ); // Update the PWM values

#ifdef USE_XSCOPE
					if ((motor_s.cnts[FOC] & 0x1) == 0) // If even, (NB Forgotton why this works!-(
					{
						if (0 == motor_s.id) // Check if 1st Motor
						{
/*
							xscope_probe_data(0, motor_s.meas_veloc );
				  	  xscope_probe_data(1, motor_s.set_iq );
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
	streaming chanend c_qei, 
	streaming chanend c_adc_cntrl, 
	chanend c_speed, 
	port in p_hall, 
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

	/* ADC centrepoint calibration before we start the PWM */
	do_adc_calibration( c_adc_cntrl );

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
	use_motor( motor_s ,c_pwm ,c_qei ,c_adc_cntrl ,c_speed ,p_hall ,c_can_eth_shared );

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
