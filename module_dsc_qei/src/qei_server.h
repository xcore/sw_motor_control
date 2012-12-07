/*
 * Module:  module_dsc_qei
 * File:    qei_server.h
 *
 * The copyrights, all other intellectual and industrial 
 * property rights are retained by XMOS and/or its licensors. 
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2010
 *
 * In the case where this code is a modification of existing code
 * under a separate license, the separate license terms are shown
 * below. The modifications to the code are still covered by the 
 * copyright notice above.
 *
 */                                   
#ifndef __QEI_SERVER_H__
#define __QEI_SERVER_H__
#include <xs1.h>

#include "dsc_config.h"
#include "qei_client.h"

#ifndef NUMBER_OF_MOTORS
#define NUMBER_OF_MOTORS 1
#endif

#define MAX_CONFID 2 // Maximum confidence value
#define MAX_QEI_ERR 3 // Maximum number of consecutive QEI errors allowed

#define HALF_QEI_CNT (QEI_COUNT_MAX >> 1) // 180 degrees of rotation
#define QEI_CNT_LIMIT (QEI_COUNT_MAX + HALF_QEI_CNT) // 540 degrees of rotation

#define QEI_PHASES 4	// 4 combinatations of Phases_B & Phases_A  E.g. [ 00 01 11 10 ]

/** Different Motor Phases */
typedef enum QEI_ENUM_TAG
{
  QEI_CLOCK = -1, // Clockwise Phase change
  QEI_STALL = 0,  // Same Phase
  QEI_ANTI = 1,		// Anti-Clockwise Phase change
  QEI_JUMP = 2,		// Jumped 2 Phases
} QEI_ENUM_TYP;

/** Structure containing QEI parameters for one motor */
typedef struct QEI_PARAM_TAG // 
{
	unsigned inp_pins; // Raw data values on input port pins
	unsigned prev_phases; // Previous phase values
	unsigned inp_time; // Input time stamp
	unsigned prev_time; // Previous time stamp
	QEI_ENUM_TYP prev_state; // Previous QEI state
	int err_cnt; // counter for invalid QEI states
	int orig_cnt; // Increment every time motor passes origin (index)
	int ang_cnt; // Counts angular position of motor (from origin)
	int theta; // angular position returned to client
	int prev_orig; // Previous origin flag
	int confid; // Confidence in current qei-state
	int id; // Unique motor identifier
} QEI_PARAM_S;

/** Structure containing array of QEI parameters for all motors */
typedef struct ALL_QEI_TAG // 
{
	QEI_PARAM_S qei_data[NUMBER_OF_MOTORS]; // Array of QEI parameters for all motors */
} ALL_QEI_S;

/** \brief Implementation of the QEI server thread
 *
 *  \param c_qei The control channel used by the client
 *  \param p_qei The hardware port where the quadrature encoder is located
 */
void do_qei ( streaming chanend c_qei, port in p_qei );

/** \brief Implementation of the QEI server thread that services multiple QEI devices
 *
 *  \param c_qei The control channels used by the client
 *  \param p_qei The hardware ports where the quadrature encoder is located
 */
void do_multiple_qei ( streaming chanend c_qei[], port in p_qei[] );


#endif /*__QEI_SERVER_H__ */
