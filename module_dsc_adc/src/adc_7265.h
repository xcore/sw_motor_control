/*
 * adc_7265.h
 *
 *  Created on: Jul 6, 2011
 *      Author: A SRIKANTH
 */

#ifndef ADC_7265_H_
#define ADC_7265_H_

#include "adc_common.h"

/*	The AD7265 data-sheet refers to the following signals:-
 *		SCLK:				Serial Clock frequency (can be configured to between  4..16 MHz.)
 *		CS#:				Chip Select. Ready signal (Falling edge starts sample conversion)
 *		A[0..2]:		Multiplexer Select. Selects inputs to be sampled.
 *		SGL/DIFF:		Selects between Single-ended/Differential mode.
 *		RANGE:			Selects between 0..Vref and 0..2xVref.
 *		Vdrive:			Max. analogue voltage corresponding to Max. 12-bit sample (Hardwired tp 3.3V)
 *		REF_SELECT:	Selects internal/external ref. (Hardwired to 2.5V internal)
 *
 *	The Motor-Control Board has been hardwired for differential mode.
 *	There are 2 jumper settings for controlling the following signals:-
 *		SGL/DIFF:		Should be set to 0 for Differential mode.
 *		RANGE:			Should be set to 0 for 0..Vref range.
 *
 *	The S/W application needs to set A[0..2].
 *	In differential mode (SGl/DIFF = 0): 
 *		A[0] selects between Fully/Pseudo Differential. We choose A[0] = 0 for Fully Differential.
 *		A[1,2] is dependant on the motor identifier, and selects between Motor ports V1/V3/V5
 *
 *	The AD7265 returns a sample with 12 active bits of data.
 *	For our configuration (SGL/DIFF=0, A[0]=0, RANGE=0), these bit are in 2's compliment format.
 *
 *	There can also be zero padding bits both before and after the active bits.
 *	For this application 14, 15, or 16-bit samples can be used. 
 *	If timings are set up correctly, the padding bits are expected to be as follows:-
 *
 *	Total-Sample-Size  Pad-Before-MSB  Pad-After-LSB  
 *	-----------------  --------------  -------------
 *	    14                 2               0
 *	    15                 2               1
 *	    16                 2               2
 */
#define ADC_PAD_BITS 0 // 0..2 No. of padding bits after Least-Significant active bit of sample

#define ADC_ACTIVE_BITS 12 // No. of active bits in ADC Sample
#define WORD16_BITS 16 // No. of bits in 16-bit word
#define ADC_DIFF_BITS (WORD16_BITS - ADC_ACTIVE_BITS) //4 Difference between Word16 and active bits 
#define ADC_MIN_BITS 14 // Minimum No. of bits to in ADC sample (including padding bits)

#define ADC_TOTAL_BITS (ADC_MIN_BITS + ADC_PAD_BITS) //14..16 Total No. of bits to in ADC sample (including padding bits)
#define ADC_SHIFT_BITS (ADC_DIFF_BITS - ADC_PAD_BITS) //4..2 No. of bits to shift to get 16-bit word alignment
#define ADC_MASK 0xFFF0 // Mask for 12 active bits in MS bits of 16-bit word

/*	The AD7265 clock frequency (SCLK) can be configured to between  4..16 MHz.
 *	The PWM requires a 16-bit sample every 61 KHz, this translates to a minimum ADC frequency of 977 KHz.
 *  In order to trigger capture from the ADC digital ouput on a rising edge, 
 *	the SCLK frequency must be less than 13.7 MHz.
 *	Considering all above constraints. We set the ADC frequency to 8 MHz
 */
#define ADC_SCLK_MHZ 8 // ADC Serial Clock frequency (in MHz)

#define ADC_FILTER_7265

#define NUM_ADC_DATA_PORTS 2 // The number data ports on the ADC chip (AD7265)

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

#define ADC_SCALE_BITS 16 // Used to generate 2^n scaling factor
#define ADC_HALF_SCALE (1 << (ADC_SCALE_BITS - 1)) // Half Scaling factor (used in rounding)

#define ADC_MAX_COEF_BITS 13 // Used to generate max. filter coef divisor. coef_div = 1/2^n
#define ADC_MAX_COEF_DIV (1 << ADC_MAX_COEF_BITS) // Max. coef divisor

typedef struct ADC_PHASE_TAG // Structure containing data for one phase of ADC Trigger
{
	unsigned adc_val; // ADC measured current value
	int mean; // local mean value
	int filt_val; // filtered value
	int coef_err; // Coefficient diffusion error
	int scale_err; // Scaling diffusion error 
} ADC_PHASE_TYP;

typedef struct ADC_FILT_TAG // Structure containing data for one ADC Trigger
{
	int coef_div; // coef = 1/coef_div 
	int coef_bits; // coef_div = 2^coef_bits
	int half_div; // half coef_div (used for rounding)
} ADC_FILT_TYP;

typedef struct ADC_TRIG_TAG // Structure containing data for one ADC Trigger
{
	ADC_PHASE_TYP phase_data[USED_ADC_PHASES];
	ADC_FILT_TYP filt; // Filter parameters. NB Need to have separate structure to satisfy XC rules on aliasing
	timer my_timer;	// timer
	unsigned time_stamp; 	// time-stamp
	char guard_off;	// Guard
	int mux_id; // Mux input identifier
	int filt_cnt; // Counter used in filter
} ADC_TRIG_TYP;

typedef struct ADC_7265_TAG // Structure containing ADC-7265 data
{
	ADC_TRIG_TYP trig_data[NUM_ADC_TRIGGERS];
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
void adc_7265_triggered( 
	streaming chanend c_control[NUM_ADC_TRIGGERS],
	chanend c_trigger[NUM_ADC_TRIGGERS],
	in buffered port:32 p_data[NUM_ADC_DATA_PORTS], 
	clock xclk,
	out port p_serial_clk,
	port p_conv_strobe,
	port out p_mux
);

#endif /* ADC_7265_H_ */
