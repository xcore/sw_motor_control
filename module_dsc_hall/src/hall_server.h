/**
 * The copyrights, all other intellectual and industrial 
 * property rights are retained by XMOS and/or its licensors. 
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2012
 *
 * In the case where this code is a modification of existing code
 * under a separate license, the separate license terms are shown
 * below. The modifications to the code are still covered by the 
 * copyright notice above.
 *
 **/                                   
#ifndef _HALL_SERVER_H_
#define _HALL_SERVER_H_


#include <xs1.h>
#include <print.h>
#include <assert.h>

#include "dsc_config.h"
#include "hall_commands.h"

/** Structure containing HALL parameters for one motor */
typedef struct HALL_PARAM_TAG // 
{
	unsigned inp_val; // Raw value on input port pins
	unsigned out_val; // Filtered output value
	int id; // Unique motor identifier
} HALL_PARAM_S;

/*****************************************************************************/
void do_multiple_hall( // Get Hall Sensor data from motor and send to client
	streaming chanend c_hall[], // Array of data channels to client (carries processed Hall data)
	port in p4_hall[]					// Array of input port (carries raw Hall motor data)
);
/*****************************************************************************/
#endif // _HALL_SERVER_H_



