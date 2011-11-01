#include <xs1.h>
#include <platform.h>

#include <print.h>

#include "pwm_cli_inv.h"
#include "pwm_service_inv.h"
#include "adc_7265.h"

/* WARNING: This test application is for use in simuation only.  It may damage a motor if applied
 * to a working system.
 *
 * Try using the command line:
 *   xsim --vcd-tracing "-core stdcore[1] -ports" bin\test_pwm.xe > trace.vcd
 */

/* motor1 core ports */
on stdcore[1]: port in p_hall = PORT_M1_ENCODER;
on stdcore[1]: buffered out port:32 p_pwm_hi1[3] = {PORT_M1_HI_A, PORT_M1_HI_B, PORT_M1_HI_C};
on stdcore[1]: buffered out port:32 p_pwm_lo1[3] = {PORT_M1_LO_A, PORT_M1_LO_B, PORT_M1_LO_C};
on stdcore[1]: clock pwm_clk1 = XS1_CLKBLK_1;

on stdcore[1]: out port ADC_SCLK = PORT_ADC_CLK;
on stdcore[1]: port ADC_CNVST = PORT_ADC_CONV;
on stdcore[1]: buffered in port:32 ADC_DATA_A = PORT_ADC_MISOA;
on stdcore[1]: buffered in port:32 ADC_DATA_B = PORT_ADC_MISOB;
on stdcore[1]: out port ADC_MUX = PORT_ADC_MUX;
on stdcore[1]: in port ADC_SYNC_PORT1 = XS1_PORT_16A;
on stdcore[1]: in port ADC_SYNC_PORT2 = XS1_PORT_16B;
on stdcore[1]: clock adc_clk = XS1_CLKBLK_2;


void do_test(chanend c_pwm[])
{
	unsigned value[3];
	t_pwm_control pwm_ctrl;

	pwm_share_control_buffer_address_with_server(c_pwm[0], pwm_ctrl);

	value[0] = 1000;
	value[1] = 2000;
	value[2] = 3000;
	update_pwm_inv(pwm_ctrl, c_pwm[0], value);
}

void dummy_thread()
{
	while (1);
}

int main ( void )
{
	chan c_pwm[1], c_adc[1], c_adc_trig[1];

	par
	{
		/* L1 */
		on stdcore[1]: do_pwm_inv_triggered( c_pwm[0], c_adc_trig[0], ADC_SYNC_PORT1, p_pwm_hi1, p_pwm_lo1, pwm_clk1 );
		on stdcore[1]: do_test( c_pwm );
		on stdcore[1]: adc_7265_triggered( c_adc, c_adc_trig, adc_clk, ADC_SCLK, ADC_CNVST, ADC_DATA_A, ADC_DATA_B, ADC_MUX );

		// These can be used to simulate other threads running in the motor core, for tuning purposes
		on stdcore[1]: dummy_thread();
		on stdcore[1]: dummy_thread();
		on stdcore[1]: dummy_thread();
		on stdcore[1]: dummy_thread();
		on stdcore[1]: dummy_thread();
	}
	return 0;
}
