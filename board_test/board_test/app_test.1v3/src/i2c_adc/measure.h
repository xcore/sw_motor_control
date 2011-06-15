/*
 * @ModuleName 	measure
 * @Author 	Corin Rathbone
 * @Date 	27/08/2009
 * @Version 	1.0
 * @Description Measure signals on the control board
 *
 * The copyrights, all other intellectual and industrial
 * property rights are retained by XMOS and/or its licensors.
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2009
 */

#ifndef __MEASURE_H__
#define __MEASURE_H__

	// Define the IIC addresses
	#define iic_address_adc			0x6A // 6A 53

	// Prototype functions
	void measure_task ( chanend c_control, port p_iic_scl, port p_iic_sda );

#endif

