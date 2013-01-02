/*
 * adc_7265.h
 *
 *  Created on: Jul 6, 2011
 *      Author: A SRIKANTH
 */

#ifndef ADC_7265_H_
#define ADC_7265_H_

#include "adc_common.h"

#define ADC_FILTER_7265

// ADC_TRIGGER_DELAY needs to be tuned to move the ADC trigger point into the centre of the 'OFF' period.
// The 'test_pwm' application can be run in the simulator to tune the parameter.  Use the following
// command line:
//    xsim --vcd-tracing "-core stdcore[1] -ports" bin\test_pwm.xe > trace.vcd
//
// Then open the 'Waveforms' perspective in the XDE, click the 'load VCD file' icon and look at the
// traces named 'PORT_M1_LO_A', 'PORT_M1_LO_B', 'PORT_M1_LO_C', and 'PORT_ADC_CONV'.  The ADC conversion
// trigger should go high in the centre of the low periods of all of the motor control ports. This
// occurs periodically, but an example can be found at around 94.8us into the simulaton.
#define ADC_TRIGGER_DELAY 1980

//MB~ Revisit this for low speeds, we need more calibration points
// For 600RPM and 61kHz sample rate, 1 revolution is 6100 samples. Choose next highest power of 2
#define CALIBRATION_BITS 13
#define NUM_CALIBRATIONS (1 << CALIBRATION_BITS)	// Number of calibration points required
#define HALF_CALIBRATIONS (NUM_CALIBRATIONS >> 1)	// Half No. of calibration points (used for rounding)

typedef struct ADC_PHASE_TAG // Structure containing data for one phase of ADC Trigger
{
	int adc_val; // ADC measured current value
	int rem_val; // Remainder used for error diffusion
	unsigned calib_val; // Calibration values
	int calib_acc; // Accumultor for the calibration average
} ADC_PHASE_TYP;

typedef struct ADC_TRIG_TAG // Structure containing data for one ADC Trigger
{
	ADC_PHASE_TYP phase_data[USED_ADC_PHASES];
	int calib_cnt; // Counter used in ADC calibration
	timer my_timer;	// timer
	unsigned time_stamp; 	// time-stamp
	char guard_off;	// Guard
	int mux_id; // Mux input identifier
} ADC_TRIG_TYP;

typedef struct ADC_7265_TAG // Structure containing ADC-7265 data
{
	ADC_TRIG_TYP trig_data[ADC_NUMBER_OF_TRIGGERS];
} ADC_7265_TYP;

/** \brief Implements the AD7265 triggered ADC service
 *
 *  This implements the AD hardware interface to the 7265 ADC device.  It has two ports to allow reading two
 *  simultaneous current readings for a single motor.
 *
 *  \param c_adc the array of ADC server control channels
 *  \param c_trig the array of channels to recieve triggers from the PWM modules
 *  \param clk an XCORE clock to provide clocking to the ADC
 *  \param SCLK the external clock pin on the ADC
 *  \param CNVST the convert strobe on the ADC
 *  \param DATA_A the first data port on the ADC
 *  \param DATA_B the second data port on the ADC
 *  \param MUX a port to allow the selection of the analogue MUX input
 *
 */
void adc_7265_triggered( streaming chanend c_adc[ADC_NUMBER_OF_TRIGGERS] ,chanend c_trig[ADC_NUMBER_OF_TRIGGERS] ,clock clk ,out port SCLK ,port CNVST ,in buffered port:32 p_adc_data[NUMBER_OF_MOTORS] ,port out MUX );

#endif /* ADC_7265_H_ */
