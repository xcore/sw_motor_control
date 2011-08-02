Analogue to Digital Converter (ADC) Interface

The analogue to digital interface currently provided is written for the LTC1408. This provides a clocked serial output following a sample and hold conversion trigger signal. The physical interface of the ADC is not covered in detail as the interface for ADC's will vary from manufacturer to manufacturer. An example of the interface for the MAX1379 is also available in this module.

Besides the client and server interfaces the key issue discussed in this section is the synchronisation of the ADC to the PWM and how this is achieved on the ADC side.

The define LOCK_ADC_TO_PWM must be 0 or 1 for off and on respectively. This defines whether the ADC readings are triggered by the PWM so that measurements can be taken at the appropriate point in the PWM cycle.

ADC Server Usage

The following include and function call are required to operate the ADC software as a server. This server is utilised in the case where the ADC is locked to the PWM.



#include "adc_ltc1408.h"

void adc_ltc1408_triggered( chanend c_adc, 
	clock clk, 
	port out SCLK, 
	buffered out port:32 CNVST, 
	in buffered port:32 DATA, 
	chanend c_trig)

chanend c_adc is the channel where values from the ADC are received.

clock clk is the clock block for control data flow to and from the ADC

port out SCLK, buffered out port:32 CNVST and in buffered port:32 DATA are the ports used for interfacing to the ADC.  

chanend c_trig is the channel between the PWM and the ADC threads that triggers the conversion of the ADC.

ADC Client Usage
The functions below are the primary method of collecting ADC data from the ADC service. 

The client can be utilised as follows:


#include "adc_client.h"

void do_adc_calibration(chanend c_adc);

{unsigned,unsigned,unsigned} get_adc_vals_raw(chanend c_adc);

{int, int, int} get_adc_vals_calibrated_int16(chanend c_adc);


do_adc_calibration(...) is used to initialise the ADC and calibrate the 0 point. This does an average over 64 ADC readings.

get_adc_vals_raw(...) is used to get the raw values from the ADC. In the case of the LTC1408 these are the raw 14 bit values that the ADC delivers. This is a multiple return function in channel order.

get_adc_vals_calibrated_int16(...) is used to get the three ADC values with the zero calibration, offset and scaling applied to get a signed 16 bit value. This is a multiple return function in channel order.

There is also an example of an experimental server providing continuous ADC readings that are filtered and provided when requested by the client side.


ADC Server Implementation

The ADC server implementation discussed here is the triggered variant of the ADC code.

The ADC server first configures the ports as clocked inputs and outputs. Following this the main loop is entered. 

ADC readings are triggered by the receipt of a trigger control token over the channel. A token is used as this offers minimum latency for channel communication. Following the token being received the ADC values are read after a time constant that is calibrated to align with the appropriate measurement point.

ADC values can be requested from the server at any point. There are three commands that can be passed indicating whether the client wishes to receive ADC values [0:2], [3:5] or [0:5].
