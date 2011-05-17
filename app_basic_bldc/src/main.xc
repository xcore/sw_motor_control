/**
 * Module:  app_basic_bldc
 * Version: 1v1
 * Build:
 * File:    main.xc
 * Author: 	L & T
 *
 * The copyrights, all other intellectual and industrial 
 * property rights are retained by XMOS and/or its licensors. 
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2011
 *
 * In the case where this code is a modification of existing code
 * under a separate license, the separate license terms are shown
 * below. The modifications to the code are still covered by the 
 * copyright notice above.
 *
 **/

#define USE_ETH
//#define USE_CAN

#include <xs1.h>
#include <platform.h>

#include <stdio.h>

#include "hall_input.h"
#include "pwm_cli.h"
#include "pwm_service.h"
#include "run_motor.h"
#include "watchdog.h"
#include "shared_io.h"
#include "speed_cntrl.h"
#include "initialisation.h"

// CAN control headers
#include "control_comms_can.h"
#include "CanPhy.h"

// Ethernet control headers
#include "control_comms_eth.h"
#include "xtcp_client.h"
#include "uip_server.h"
#include "ethernet_server.h"
#include "getmac.h"

#ifdef USE_XSCOPE
#include <xscope.h>
#endif

/* core with LCD and BUTTON interfaces */
on stdcore[INTERFACE_CORE]: lcd_interface_t lcd_ports = { PORT_DS_SCLK, PORT_DS_MOSI, PORT_DS_CS_N, PORT_CORE1_SHARED };
on stdcore[INTERFACE_CORE]: port in btns[4] = {PORT_BUTTON_A, PORT_BUTTON_B, PORT_BUTTON_C, PORT_BUTTON_D};

/* motor1 core ports */

on stdcore[MOTOR_CORE]: port in p_hall = PORT_M1_ENCODER;
on stdcore[MOTOR_CORE]: buffered out port:32 p_pwm_hi1[3] = {PORT_M1_HI_A, PORT_M1_HI_B, PORT_M1_HI_C};
on stdcore[MOTOR_CORE]: out port p_motor_lo1[3] = {PORT_M1_LO_A, PORT_M1_LO_B, PORT_M1_LO_C};
on stdcore[MOTOR_CORE]: out port i2c_wd = PORT_I2C_WD_SHARED;
on stdcore[MOTOR_CORE]: clock pwm_clk = XS1_CLKBLK_1;

/* motor2 core ports */
on stdcore[MOTOR_CORE]: port in p_hall2 = PORT_M2_ENCODER;
on stdcore[MOTOR_CORE]: buffered out port:32 p_pwm_hi2[3] = {PORT_M2_HI_A, PORT_M2_HI_B, PORT_M2_HI_C};
on stdcore[MOTOR_CORE]: out port p_motor_lo2[3] = {PORT_M2_LO_A, PORT_M2_LO_B, PORT_M2_LO_C};
on stdcore[MOTOR_CORE]: clock pwm_clk2 = XS1_CLKBLK_4;

// CAN
on stdcore[INTERFACE_CORE] : clock p_can_clk = XS1_CLKBLK_4;
on stdcore[INTERFACE_CORE] : buffered in port:32 p_can_rx = PORT_CAN_RX;
on stdcore[INTERFACE_CORE] : port p_can_tx = PORT_CAN_TX;

// OTP for MAC address
on stdcore[INTERFACE_CORE]: port otp_data = XS1_PORT_32B;
on stdcore[INTERFACE_CORE]: out port otp_addr = XS1_PORT_16C;
on stdcore[INTERFACE_CORE]: port otp_ctrl = XS1_PORT_16D;

// Ethernet Ports
on stdcore[INTERFACE_CORE]: clock clk_mii_ref = XS1_CLKBLK_REF;
on stdcore[INTERFACE_CORE]: clock clk_smi = XS1_CLKBLK_3;
on stdcore[INTERFACE_CORE]: smi_interface_t smi = { PORT_ETH_MDIO, PORT_ETH_MDC, 1 };
on stdcore[INTERFACE_CORE]: mii_interface_t mii = { XS1_CLKBLK_1, XS1_CLKBLK_2, PORT_ETH_RXCLK, PORT_ETH_RXER, PORT_ETH_RXD, PORT_ETH_RXDV, PORT_ETH_TXCLK, PORT_ETH_TXEN, PORT_ETH_TXD };


int main ( void )
{
	chan c_wd, c_pwm1, c_control1, c_lcd1, c_control2, c_pwm2, c_lcd2, c_ctrl, c_eth_reset, c_can_reset;


#ifdef USE_CAN
	chan c_rxChan, c_txChan;
#endif

#ifdef USE_ETH
	chan c_mac_rx[1], c_mac_tx[1], c_xtcp[1], c_connect_status;
#endif

	par
	{
#ifdef USE_CAN
		on stdcore[PROCESSING_CORE] : do_comms_can( c_ctrl, c_rxChan, c_txChan, c_can_reset );

		on stdcore[INTERFACE_CORE] : canPhyRxTx( c_rxChan, c_txChan, p_can_clk, p_can_rx, p_can_tx );
#endif

#ifdef USE_ETH
		on stdcore[PROCESSING_CORE] : init_tcp_server( c_mac_rx[0], c_mac_tx[0], c_xtcp, c_connect_status );
		on stdcore[PROCESSING_CORE] : do_comms_eth( c_ctrl, c_xtcp[0] );

		on stdcore[INTERFACE_CORE]: init_ethernet_server(otp_data, otp_addr, otp_ctrl, clk_smi, clk_mii_ref, smi, mii, c_mac_rx, c_mac_tx, c_connect_status, c_eth_reset); // +4 threads
#endif

		/* L2 */
		on stdcore[INTERFACE_CORE]: speed_control1( c_control1, c_lcd1 );
		on stdcore[INTERFACE_CORE]: speed_control2( c_control2, c_lcd2 );
		on stdcore[INTERFACE_CORE]: {
#ifdef USE_XSCOPE
			xscope_register(5,
					XSCOPE_CONTINUOUS, "PWM 1", XSCOPE_UINT , "n",
					XSCOPE_CONTINUOUS, "PWM 2", XSCOPE_UINT , "n",
					XSCOPE_CONTINUOUS, "Speed 1", XSCOPE_UINT , "rpm",
					XSCOPE_CONTINUOUS, "Speed 2", XSCOPE_UINT , "rpm",
					XSCOPE_CONTINUOUS, "Set Speed", XSCOPE_UINT, "rpm"
			);
#endif
			display_shared_io_motor( c_lcd1, c_lcd2, lcd_ports, btns);
		}

		/* L1 */
		on stdcore[MOTOR_CORE]: do_pwm1( c_pwm1, p_pwm_hi1, pwm_clk);
		on stdcore[MOTOR_CORE]: run_motor1 ( c_wd, c_pwm1, c_control1, p_hall, p_motor_lo1 );
		on stdcore[MOTOR_CORE]: do_pwm2( c_pwm2, p_pwm_hi2, pwm_clk2);
		on stdcore[MOTOR_CORE]: run_motor2 ( c_pwm2, c_control2, p_hall2, p_motor_lo2 );
		on stdcore[MOTOR_CORE]: do_wd(c_wd, i2c_wd);


	}
	return 0;
}
