/*
 * @ModuleName 	iic
 * @Author 	Ali Dixon & Corin Rathbone
 * @Date 	27/08/2009
 * @Version 	2.0
 * @Description IIC interface driver
 *
 * The copyrights, all other intellectual and industrial
 * property rights are retained by XMOS and/or its licensors.
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2009
 */

#ifndef __IIC_H__
#define __IIC_H__

	#include "sw_comps_common.h"

	#define IIC_WE 0
	#define IIC_RE 1

	// times are in units of 10ns
	#define iic_bittime 			500 //= 200 250 // 400Khz
	#define iic_scl_high_time 		120
	#define iic_scl_low_time 		260
	#define iic_bus_free_time 		120
	#define iic_start_cond_setup_time 	120
	#define iic_start_cond_hold_time   	120
	#define iic_write_cycle_time        	1000000  // 5ms
	#define iic_write_ack_poll_time     	10000

	typedef enum IIC_CMD
	{
	  IIC_CMD_error = 0,
	  IIC_CMD_initialise,
	  IIC_CMD_read,
	  IIC_CMD_write,
	  IIC_CMD_finish

	} IIC_CMD_t;

	// Prototype functions
	XMOS_RTN_t 	iic_initialise ( port PORT_IIC_SCL, port PORT_IIC_SDA );
	XMOS_RTN_t 	iic_read ( port PORT_IIC_SCL, port PORT_IIC_SDA, uint address, char data[], uint numBytes, uint clkStretch );
	XMOS_RTN_t 	iic_write ( port PORT_IIC_SCL, port PORT_IIC_SDA, uint address, char data[], uint numBytes );

#endif

