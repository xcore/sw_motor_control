/**
 * File:    inner_loop.xc
 *
 * The copyrights, all other intellectual and industrial 
 * property rights are retained by XMOS and/or its licensors. 
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2011
 *
 * In the case where this code is a modification of existing code
 * under a separate license, the separate license terms are shown
 * below. The modifications to the code are still covered by the 
 * copyright notice above.
 *
 * run_motor() function initially runs in open loop, spinning the magnetic field around at a fixed
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

#define MOTOR_P 2100
#define MOTOR_I 6
#define MOTOR_D 0
#define SEC 100000000
#define Kp 5000
#define Ki 100
#define Kd 40
#define PWM_MAX_LIMIT 3800
#define PWM_MIN_LIMIT 200
#define OFFSET_14 16383

#define STALL_SPEED 100
#define STALL_TRIP_COUNT 5000

#define LDO_MOTOR_SPIN 1 // Motor spins like an LDO Motor

#define FIRST_HALL_STATE 0b001 // 1st Hall state of 6-state cycle

// Choose last Hall state of 6-state cycle, depending on spin direction
#if (LDO_MOTOR_SPIN == 1)
	#define LAST_HALL_STATE 0b011
#else
	#define LAST_HALL_STATE 0b101
#endif

// This is half of the coil sector angle (6 sectors = 60 degrees per sector, 30 degrees per half sector)
#define THETA_HALF_PHASE (QEI_COUNT_MAX * 30 / 360 / NUMBER_OF_POLES)

#define IQ_OPEN_LOOP 2000 // Iq value for open-loop mode
#define ID_OPEN_LOOP 0		// Id value for open-loop mode
#define INIT_HALL 0 // Initial Hall state
#define INIT_THETA 0 // Initial start-up angle
#define INIT_SPEED 4000 // Initial start-up speed
#define DEMO_LIMIT 1000000 // Demo. terminated after this number of FOC iterations

#define STR_LEN 80 // String Length

#define ERROR_OVERCURRENT 0x1 //MB~
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
	pid_data pid_speed;	/* Speed PID control structure */
	pid_data pid_d;	/* Id PID control structure */
	pid_data pid_q;	/* Iq PID control structure */
	t_pwm_control pwm_ctrl;	// structure containing PWM data, (written to shared memory)
	int meas_Is[NUM_PHASES]; // Array of measured coil currents from ADC
	int cnts[NUM_MOTOR_STATES]; // array of counters for each motor state	
	unsigned id; // Unique Motor identifier e.g. 0 or 1
	MOTOR_STATE_TYP state; // Current motor state
	unsigned prev_hall; // previous hall state value
	int set_theta;	// theta value
	int set_speed;	// Demand speed set by the user/comms interface
	int set_id;	// Ideal current producing radial magnetic field.
	int set_iq;	// Ideal current producing tangential magnetic field
	int start_theta; // Theta start position during warm-up (START and SEARCH states)
	unsigned err_flgs;	// Fault detection flags

	int out_id;	// Output radial current value
	int out_iq;	// Output measured tangential current value
	int meas_theta;	// Position as measured by the QEI
	int meas_speed;	// speed as measured by the QEI
	int angl_valid;	// Status flag returned by QEI when angular position origin has been found */
	int theta_offset;	// Phase difference between the QEI and the coils

	unsigned tmp; // Debug variable
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


	motor_s.id = motor_id; // Unique Motor identifier e.g. 0 or 1
	motor_s.cnts[START] = 0;
	motor_s.state = START;
	motor_s.prev_hall = INIT_HALL;
	motor_s.set_theta = INIT_THETA;
	motor_s.set_speed = INIT_SPEED;
	motor_s.start_theta = 0; // Theta start position during warm-up (START and SEARCH states)
	motor_s.set_id = 0;	// Ideal current producing radial magnetic field (NB never update as no radial force is required)
	motor_s.set_iq = 0;	// Ideal current producing tangential magnetic field. (NB Updated based on the speed error)
	motor_s.err_flgs = 0; 	// Clear fault detection flags

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

	motor_s.meas_speed = motor_s.set_speed;

	for (phase_cnt = 0; phase_cnt < NUM_PHASES; phase_cnt++)
	{ 
		motor_s.meas_Is[phase_cnt] = -1;
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


	out_pwm = (inp_I + OFFSET_14) >> 3; // Convert coil current to PWM value

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
	unsigned out_pwm[],	// Array of PWM variables
	int inp_id, // Input radial current from the current control PIDs
	int inp_iq, // Input tangential currents from the current control PIDs
	unsigned inp_theta	// Input demand theta
)
{
	int I_coil[NUM_PHASES];	// array of intermediate coil currents for each phase
	int alpha_tmp = 0, beta_tmp = 0; // Intermediate currents as a 2D vector
	int phase_cnt; // phase counter


	/* Inverse park  [d,q] to [alpha, beta] */
	inverse_park_transform( alpha_tmp, beta_tmp, inp_id, inp_iq, inp_theta  );

	/* Final voltages applied */
	inverse_clarke_transform( I_coil[PHASE_A ] ,I_coil[PHASE_B] ,I_coil[PHASE_C] ,alpha_tmp ,beta_tmp );

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
	motor_s.set_theta = (motor_s.start_theta >> 2) & (QEI_COUNT_MAX-1);
#else
	motor_s.set_theta = (motor_s.start_theta >> 4) & (QEI_COUNT_MAX-1);
#endif
	motor_s.out_id = ID_OPEN_LOOP;
	motor_s.out_iq = IQ_OPEN_LOOP;

	motor_s.start_theta++; // Update start position ready for next iteration
} // calc_open_loop_pwm
/*****************************************************************************/
void calc_foc_pwm ( // Calculate FOC PWM output values
	MOTOR_DATA_TYP &motor_s // reference to structure containing motor data
)
{
	int alpha = 0, beta = 0;	// Measured currents once transformed to a 2D vector
	int Id_in = 0, Iq_in = 0;	/* Measured radial and tangential currents in the rotor frame of reference */
	int Id_err = 0, Iq_err = 0;	/* The difference between the actual coil currents, and the demand coil currents */


#pragma xta label "foc_loop_read_hardware"

	// Bring theta into the correct phase (adjustment between QEI and motor windings)
	motor_s.set_theta = motor_s.meas_theta - motor_s.theta_offset;
	motor_s.set_theta &= (QEI_COUNT_MAX - 1);

#pragma xta label "foc_loop_clarke"

	/* To calculate alpha and beta currents */
	clarke_transform(motor_s.meas_Is[PHASE_A], motor_s.meas_Is[PHASE_B], motor_s.meas_Is[PHASE_C], alpha, beta );

#pragma xta label "foc_loop_park"

	/* Id and Iq outputs derived from park transform */
	park_transform( Id_in, Iq_in, alpha, beta, motor_s.set_theta  );

#pragma xta label "foc_loop_speed_pid"

	/* Applying Speed PID */
	motor_s.set_iq = pid_regulator_delta_cust_error_speed( (int)(motor_s.set_speed - motor_s.meas_speed) ,motor_s.pid_speed );
	if (motor_s.set_iq <0) motor_s.set_iq = 0;

	/* Apply PID control to Iq and Id */
	Iq_err = Iq_in - motor_s.set_iq;
	Id_err = Id_in - motor_s.set_id;

#pragma xta label "foc_loop_id_iq_pid"

	motor_s.out_iq = pid_regulator_delta_cust_error_Iq_control( Iq_err, motor_s.pid_q );
	motor_s.out_id = pid_regulator_delta_cust_error_Id_control( Id_err, motor_s.pid_d );

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
 *          ------------> Clock-Wise ------------>
 * (011) -> 001 -> 101 -> 100 -> 110 -> 010 -> 011 -> (001)
 *          <---------- Anti-Clockwise <----------
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
			if (motor_s.prev_hall == LAST_HALL_STATE)
			{ // Spinning in correct direction

				// Check if position offset needs updating. MB~ I don't understand this check, it always appears to be TRUE.
				if (motor_s.meas_theta < (QEI_COUNT_MAX/NUMBER_OF_POLES)) 
				{ // Find the offset between the rotor and the QEI
					motor_s.theta_offset = (THETA_HALF_PHASE + motor_s.meas_theta);
					motor_state = FOC; // Switch to main FOC state
					motor_s.cnts[FOC] = 0; // Initialise FOC-state counter 
if (dbg) { printint(motor_s.id); printstr( " SE: " ); printintln( motor_s.cnts[SEARCH] ); } 
				} // if (motor_s.meas_theta < (QEI_COUNT_MAX/NUMBER_OF_POLES))
			} // if (motor_s.prev_hall == LAST_HALL_STATE)
			else
			{ // We are probably spinning in the wrong direction!-(
				motor_s.err_flgs |= ERROR_DIRECTION;
				motor_state = STOP; // Switch to stop state
				motor_s.cnts[STOP] = 0; // Initialise stop-state counter 
if (dbg) { printint(motor_s.id); printstr( " SE- " ); printintln( motor_s.cnts[SEARCH] ); } 
			} // else !(motor_s.prev_hall == LAST_HALL_STATE)
		} // if (inp_hall == FIRST_HALL_STATE)

		motor_s.prev_hall = inp_hall; // Store hall state for next iteration
	} // if (motor_s.prev_hall != inp_hall)

	return motor_state; // Return updated motor state
} // check_hall_state
/*****************************************************************************/
unsigned update_motor_state( // Update state of motor based on motor sensor data
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
	unsigned stop_motor;	/* Fault detection */


	// Update motor state based on new sensor data
	switch( motor_s.state )
	{
		case START : // Intial entry state
			if (1 == motor_s.angl_valid) // Check if angular postion origin found
			{
				motor_s.state = SEARCH; // Switch to search state
				motor_s.cnts[SEARCH] = 0; // Initialise search-state counter
if (dbg) { printint(motor_s.id); printstr( " SA: " ); printintln( motor_s.cnts[START] ); } 
			} // if (1 == motor_s.angl_valid)
		break; // case START

		case SEARCH : // Turn motor using Hall state, and update motor state
			motor_state = check_hall_state( motor_s ,inp_hall ); 
 			motor_s.state = motor_state; // NB Required due to XC compiler rules
		break; // case SEARCH 
	
		case FOC : // Normal FOC state
			// Check for a stall
// if (dbg) { printint(motor_s.id); printchar(': '); printint( motor_s.meas_speed ); printchar(' '); printint( motor_s.meas_theta ); printchar(' '); printintln( motor_s.valid ); }
			if (motor_s.meas_speed < STALL_SPEED) 
			{
				motor_s.state = STALL; // Switch to stall state
				motor_s.cnts[STALL] = 0; // Initialise stall-state counter 
if (dbg) { printint(motor_s.id); printstr( " FO: " ); printintln( motor_s.cnts[FOC] ); } 
			} // if (motor_s.meas_speed < STALL_SPEED)
			else
			{
				// Check if it is time to stop demo
				if (motor_s.cnts[FOC] > DEMO_LIMIT)
				{
					motor_s.state = STOP; // Switch to stop state
					motor_s.cnts[STOP] = 0; // Initialise stop-state counter 
				} // if (motor_s.cnts[FOC] > DEMO_LIMIT)
			} // else !(motor_s.meas_speed < STALL_SPEED)
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
			stop_motor = 1; // Set flag to stop motor
			return stop_motor;
		break; // case STOP
	
    default: // Unsupported
			assert(0 == 1); // Motor state not supported
    break;
	} // switch( motor_s.state )

	stop_motor = 0; // Do NOT stop motor
	return stop_motor;
} // update_motor_state
/*****************************************************************************/
#pragma unsafe arrays
void use_motor ( // Start motor, and run step through different motor states
	MOTOR_DATA_TYP &motor_s, // reference to structure containing motor data
	chanend? c_in, 
	chanend c_pwm, 
	streaming chanend c_qei, 
	streaming chanend c_adc, 
	chanend c_speed, 
	chanend? c_wd, 
	port in p_hall, 
	chanend c_can_eth_shared 
#ifdef MB
	chanend? c_out, 
#endif //MB
)
{
	unsigned pwm_vals[NUM_PHASES]; // Array of PWM values

	int phase_cnt; // phase counter
	int id_out = 0, iq_out = 0;	/* The demand radial and tangential currents from the current control PIDs */
	unsigned command;	// Command received from the control interface
	unsigned new_hall;	// New Hall state

	unsigned stop_motor = 0;	/* Fault detection */



	// initialise arrays
	for (phase_cnt = 0; phase_cnt < NUM_PHASES; phase_cnt++)
	{ 
		pwm_vals[phase_cnt] = 0;
	} // for phase_cnt

	/* Main loop */
	while (0 == stop_motor)
	{
#pragma xta endpoint "foc_loop"
		select
		{
		case c_speed :> command:		/* This case responds to speed control through shared I/O */
#pragma xta label "foc_loop_speed_comms"
			if(command == CMD_GET_IQ)
			{
				c_speed <: motor_s.meas_speed;
				c_speed <: motor_s.set_speed;
			}
			else if (command == CMD_SET_SPEED)
			{
				c_speed :> motor_s.set_speed;
			}
			else if(command == CMD_GET_FAULT)
			{
				c_speed <: motor_s.err_flgs;
			}

		break; // case c_speed :> command:

		case c_can_eth_shared :> command:		//This case responds to CAN or ETHERNET commands
#pragma xta label "foc_loop_shared_comms"
			if(command == CMD_GET_VALS)
			{
				c_can_eth_shared <: motor_s.meas_speed;
				c_can_eth_shared <: motor_s.meas_Is[PHASE_A];
				c_can_eth_shared <: motor_s.meas_Is[PHASE_B];
			}
			else if(command == CMD_GET_VALS2)
			{
				c_can_eth_shared <: motor_s.meas_Is[PHASE_C];
				c_can_eth_shared <: motor_s.set_iq;
				c_can_eth_shared <: id_out;
				c_can_eth_shared <: iq_out;
			}

			else if (command == CMD_SET_SPEED)
			{
				c_can_eth_shared :> motor_s.set_speed;
			}
			else if (command == CMD_GET_FAULT)
			{
				c_can_eth_shared <: motor_s.err_flgs;
			}

		break; // case c_can_eth_shared :> command:

		default:	// This case updates the motor state
			if(stop_motor == 0)
			{
				p_hall :> new_hall; // Get new hall state

				// Check error status
				if (!(new_hall & 0b1000))
				{
					motor_s.err_flgs |= ERROR_OVERCURRENT;
					stop_motor = 1; // Switch to stop state
				} // if (!(new_hall & 0b1000))
				else
				{
					/* Get the position from encoder module. NB returns valid=0 at start-up  */
					{ motor_s.meas_speed ,motor_s.meas_theta ,motor_s.angl_valid } = get_qei_data( c_qei );
//MB~			{ motor_s.meas_speed ,motor_s.meas_theta ,motor_s.angl_valid ,motor_s.tmp } = get_qei_data( c_qei ); //MB~ dbg

					/* Get ADC readings */
					{motor_s.meas_Is[PHASE_A], motor_s.meas_Is[PHASE_B], motor_s.meas_Is[PHASE_C]} = get_adc_vals_calibrated_int16( c_adc );

					stop_motor = update_motor_state( motor_s ,new_hall );
				} // else !(!(new_hall & 0b1000))

				// Check if motor needs stopping
				if (1 == stop_motor)
				{
					// Set PWM values to stop motor
					error_pwm_values( pwm_vals );
				} // if (1 == stop_motor)
				else
				{
					// Convert Output DQ values to PWM values
					dq_to_pwm( pwm_vals ,motor_s.out_id ,motor_s.out_iq ,motor_s.set_theta ); // Convert Output DQ values to PWM values
				} // else !(1 == stop_motor)

#ifdef USE_XSCOPE
				if ((motor_s.cnts[FOC] & 0x1) == 0) 
				{
					if (isnull(c_in)) 
					{
						xscope_probe_data(0, motor_s.meas_speed);
				    xscope_probe_data(1, motor_s.set_iq);
	    			xscope_probe_data(2, pwm_vals[PHASE_A]);
//MB~	    			xscope_probe_data(3, pwm_vals[PHASE_B]);
	    			xscope_probe_data(3, motor_s.meas_Is[PHASE_C]); //MB~
	    			xscope_probe_data(4, motor_s.meas_Is[PHASE_A]);
						xscope_probe_data(5, motor_s.meas_Is[PHASE_B]);
	  			} // if (isnull(c_in)) 
				} // if ((motor_s.cnts[FOC] & 0x1) == 0) 
#endif
				update_pwm_inv( motor_s.pwm_ctrl ,c_pwm, pwm_vals ); // Update the PWM values
			} // if(stop_motor==0)
		break; // default:

		}	// select
	}	// while (0 == stop_motor)

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
	chanend? c_in, 
	chanend? c_out, 
	chanend c_pwm, 
	streaming chanend c_qei, 
	streaming chanend c_adc, 
	chanend c_speed, 
	chanend? c_wd, 
	port in p_hall, 
	chanend c_can_eth_shared 
)
{
	MOTOR_DATA_TYP motor_s; // Structure containing motor data


	timer t;	/* Timer */
	unsigned ts1;	/* timestamp */


	// First send my PWM server the shared memory structure address
	pwm_share_control_buffer_address_with_server(c_pwm, motor_s.pwm_ctrl );

	// Pause to allow the rest of the system to settle
	{
		unsigned thread_id = get_logical_core_id();
		t :> ts1;
		t when timerafter(ts1+2*SEC+256*thread_id) :> void;
	}

	/* ADC centrepoint calibration before we start the PWM */
	do_adc_calibration( c_adc );

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

	/* PID control initialisation... */
	init_pid( MOTOR_P, MOTOR_I, MOTOR_D, motor_s.pid_d );
	init_pid( MOTOR_P, MOTOR_I, MOTOR_D, motor_s.pid_q );
	init_pid( Kp, Ki, Kd, motor_s.pid_speed );

	init_motor( motor_s ,motor_id );	// Initialise motor data

	if (0 == motor_id) printstrln( "Demo Starts" ); // NB Prevent duplicate display lines

	// start-and-run motor
	use_motor( motor_s ,c_in ,c_pwm ,c_qei ,c_adc ,c_speed ,c_wd ,p_hall ,c_can_eth_shared );

	// NB First Motor to finish displays
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
} // run_motor
/*****************************************************************************/
// inner_loop.xc
