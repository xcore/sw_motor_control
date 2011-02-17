/**
 * Module:  app_basic_bldc
 * Version: 1v0alpha1
 * Build:   73e3f5032a883e9f72779143401b3392bb65d5bb
 * File:    main.xc
 *
 * The copyrights, all other intellectual and industrial 
 * property rights are retained by XMOS and/or its licensors. 
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2010
 *
 * In the case where this code is a modification of existing code
 * under a separate license, the separate license terms are shown
 * below. The modifications to the code are still covered by the 
 * copyright notice above.
 *
 **/                                   
#include <xs1.h>
#include <platform.h>

#include "hall_input.h"
#include "pwm_cli.h"
#include "pwm_service.h"
#include "run_motor.h"
#include "watchdog.h"
#include "shared_io.h"
#include "speed_control.h"
#include "initialisation.h"
#ifdef USE_ETH
#include "ethernet_server.h"
#include "getmac.h"
#include "control_comms_eth.h"
#include "uip_server.h"
#endif
#include <stdio.h>

//extern unsigned hall_pos[7];

/* core with all the interfaces */
on stdcore[INTERFACE_CORE]: lcd_interface_t lcd_ports = { PORT_DS_SCLK, PORT_DS_MOSI, PORT_DS_CS_N, PORT_CORE1_SHARED };
on stdcore[INTERFACE_CORE]: port in btns[4] = {PORT_BUTTON_A, PORT_BUTTON_B, PORT_BUTTON_C, PORT_BUTTON_D};

/* motor core ports */
on stdcore[MOTOR_CORE]: port in p_hall = PORT_M1_ENCODER;
on stdcore[MOTOR_CORE]: buffered out port:32 p_pwm_hi[3] = {PORT_M1_HI_A, PORT_M1_HI_B, PORT_M1_HI_C};
on stdcore[MOTOR_CORE]: out port p_motor_lo[3] = {PORT_M1_LO_A, PORT_M1_LO_B, PORT_M1_LO_C};
on stdcore[MOTOR_CORE]: out port i2c_wd = PORT_I2C_WD_SHARED;
on stdcore[MOTOR_CORE]: clock pwm_clk = XS1_CLKBLK_1;

#ifdef USE_ETH
// OTP for MAC address
on stdcore[INTERFACE_CORE]: port otp_data = XS1_PORT_32B; 	// OTP_DATA_PORT
on stdcore[INTERFACE_CORE]: out port otp_addr = XS1_PORT_16C;	// OTP_ADDR_PORT
on stdcore[INTERFACE_CORE]: port otp_ctrl = XS1_PORT_16D;	// OTP_CTRL_PORT

// Ethernet Ports
on stdcore[INTERFACE_CORE]: clock clk_mii_ref = XS1_CLKBLK_REF;
on stdcore[INTERFACE_CORE]: clock clk_smi = XS1_CLKBLK_3;
on stdcore[INTERFACE_CORE]: smi_interface_t smi = { PORT_ETH_MDIO, PORT_ETH_MDC, 1 };
on stdcore[INTERFACE_CORE]: mii_interface_t mii =
{
    XS1_CLKBLK_1, XS1_CLKBLK_2,
    PORT_ETH_RXCLK, PORT_ETH_RXER, PORT_ETH_RXD, PORT_ETH_RXDV,
    PORT_ETH_TXCLK, PORT_ETH_TXEN, PORT_ETH_TXD,
};
#endif

int main ( void )
{
	chan c_wd, c_pwm, c_control, c_lcd, c_can, c_eth_shared, c_eth, c_mac_rx[1], c_mac_tx[1], c_xtcp[2], c_connect_status;

	par
	{
		/* L2 */
#ifdef USE_ETH
		on stdcore[PROCESSING_CORE] : init_tcp_server( c_mac_rx[0], c_mac_tx[0], c_xtcp, c_connect_status );
		on stdcore[PROCESSING_CORE] : do_comms_eth( c_eth, c_xtcp[1] );
#endif

		on stdcore[INTERFACE_CORE]: speed_control( c_control, c_lcd, c_eth );
		on stdcore[INTERFACE_CORE]: display_shared_io_manager( c_eth_shared, c_can, c_lcd, lcd_ports, btns);
		on stdcore[INTERFACE_CORE]: init_ethernet_server(otp_data, otp_addr, otp_ctrl, clk_smi, clk_mii_ref, smi, mii, c_mac_rx, c_mac_tx, c_connect_status, c_eth_shared); /* 4 threads */

		/* L1 */
		on stdcore[MOTOR_CORE]: do_pwm( c_pwm, p_pwm_hi, pwm_clk);
		on stdcore[MOTOR_CORE]: run_motor ( c_wd, c_pwm, c_control, p_hall, p_motor_lo );
		on stdcore[MOTOR_CORE]: do_wd(c_wd, i2c_wd);


	}
	return 0;
}
