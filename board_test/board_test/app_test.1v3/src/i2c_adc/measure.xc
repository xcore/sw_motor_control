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

#include <xs1.h>
#include <platform.h>
#include <print.h>
#include "iic.h"
#include "measure.h"


#define STEP_VOLTAGE	454
#define STEP_DEVIANCE	50
#define TEMP_MV			500
#define TEMP_DEVIANCE	50
#define VOLT_MV			18000 //24000
#define VOLT_DEVIANCE	500


// Main accelerometer task
void measure_task ( chanend c_control, port p_iic_scl, port p_iic_sda )
{
	char 			wrData[2], rdData[8];
	unsigned int	adc_value[12], time, i, temp, current_mv, have_passed;
	signed int		my_r;
	timer 			t;

	// Initialise the I2C port
	iic_initialise ( p_iic_scl, p_iic_sda );

	// Setup the ADC to sample all channels
	//wrData[0] = 0xF0;
	//iic_write ( p_iic_scl, p_iic_sda, iic_address_adc, wrData, 1 );

	// Loop getting data
	while ( 1 )
	{
		c_control :> temp;

		// Get the ADC values
		for ( i = 0; i < 12; i++ )
		{
			// Setup the ADC to sample the channel
			wrData[0] = 0x61 + (i << 1);
			iic_write ( p_iic_scl, p_iic_sda, iic_address_adc, wrData, 1 );

			// Read the data from the ADC
			iic_read ( p_iic_scl, p_iic_sda, iic_address_adc, rdData, 2, 1 );

			// Get the 10-bit values from the data received and scale to mV ( adc_value * (5000 / 1024) )
			adc_value[i] = ( ( ( ( ( rdData[0] & 0x3 ) << 8 ) + rdData[1] ) * 320000 ) >> 16 );

			// Wait for 1ms
			t :> time;
			t when timerafter (time + 100000) :> time;
		}

		// AN_0 is 1 down from 5V so start at that end.
		current_mv = STEP_VOLTAGE * 10;
		have_passed = 1;

		// Check the header ADC input results
		for ( i = 0; i < 10; i++ )
		{
			if ( ( adc_value[i] > (current_mv + STEP_DEVIANCE) ) || ( adc_value[i] < (current_mv - STEP_DEVIANCE) ) )
			{
				have_passed = 0;

				printstr("ADC AIN");
				printuint(i);
				printstr(" FAIL : ");
				printuint(adc_value[i]);
				printstr("mV\n");
			}

			current_mv -= STEP_VOLTAGE;
		}

		// Check the voltage input
		if ( ( (adc_value[10] * 6) > (VOLT_MV + VOLT_DEVIANCE) ) || ( (adc_value[10] * 6) < (VOLT_MV - VOLT_DEVIANCE) ) )
		{
			have_passed = 0;
			printstr("ADC AIN_10 (VOLTS)");
			printuint(i);
			printstr(" FAIL : ");
			printuint(adc_value[10] * 6);
			printstr("mV\n");
		}

		// Check the temperature input
		if ( ( adc_value[11] > (TEMP_MV + TEMP_DEVIANCE) ) || ( adc_value[11] < (TEMP_MV - TEMP_DEVIANCE) ) )
		{
			have_passed = 0;
			printstr("ADC AIN_11 (TEMP)");
			printuint(i);
			printstr(" FAIL : ");
			printuint(adc_value[11]);
			printstr("mV\n");
		}

		my_r = ( ( ( 5000 * 1000 ) / adc_value[11] ) - 1000 );

		printstr("R: ");
		printintln(my_r);

		c_control <: 1;
	}
}

