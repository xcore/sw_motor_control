#include <xs1.h>
#include <platform.h>

#include <print.h>

#include "pwm_cli.h"
#include "pwm_service.h"

/* WARNING: This test application is for use in simuation only.  It may damage a motor if applied
 * to a working system.
 */

/* motor1 core ports */
on stdcore[1]: port in p_hall = PORT_M1_ENCODER;
on stdcore[1]: buffered out port:32 p_pwm_hi1[3] = {PORT_M1_HI_A, PORT_M1_HI_B, PORT_M1_HI_C};
on stdcore[1]: buffered out port:32 p_pwm_lo1[3] = {PORT_M1_LO_A, PORT_M1_LO_B, PORT_M1_LO_C};
on stdcore[1]: clock pwm_clk = XS1_CLKBLK_1;


void do_test(chanend c_pwm)
{
	unsigned value[3];
	t_pwm_control pwm_ctrl;

	pwm_share_control_buffer_address_with_server(c_pwm, pwm_ctrl);

	value[0] = 15;
	value[1] = 1000;
	value[2] = 4080;
	update_pwm(pwm_ctrl, c_pwm, value);
}

int main ( void )
{
	chan c_pwm;

	par
	{
		/* L1 */
		on stdcore[1]: do_pwm( c_pwm, p_pwm_hi1, p_pwm_lo1, pwm_clk);
		on stdcore[1]: do_test( c_pwm );
	}
	return 0;
}
