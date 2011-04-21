#include <xs1.h>
#include <platform.h>

#include <print.h>

#include "pwm_cli.h"
#include "pwm_service.h"

/* motor1 core ports */
on stdcore[MOTOR_CORE]: port in p_hall = PORT_M1_ENCODER;
on stdcore[MOTOR_CORE]: buffered out port:32 p_pwm_hi1[3] = {PORT_M1_HI_A, PORT_M1_HI_B, PORT_M1_HI_C};
on stdcore[MOTOR_CORE]: buffered out port:32 p_pwm_lo1[3] = {PORT_M1_LO_A, PORT_M1_LO_B, PORT_M1_LO_C};
on stdcore[MOTOR_CORE]: out port i2c_wd = PORT_I2C_WD_SHARED;
on stdcore[MOTOR_CORE]: clock pwm_clk = XS1_CLKBLK_1;


void do_test(chanend c_pwm)
{
	unsigned value[3];
	value[0] = 15;
	value[1] = 1000;
	value[2] = 4080;
	update_pwm(c_pwm, value);
}

int main ( void )
{
	chan c_pwm;

	par
	{
		/* L1 */
		on stdcore[MOTOR_CORE]: do_pwm( c_pwm, p_pwm_hi1, p_pwm_lo1, pwm_clk);
		on stdcore[MOTOR_CORE]: do_test( c_pwm );
	}
	return 0;
}
