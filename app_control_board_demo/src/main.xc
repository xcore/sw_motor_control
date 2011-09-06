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

#include <xs1.h>
#include <platform.h>

#include <stdio.h>
#include <string.h>
#include <safestring.h>
#include <print.h>

#include "adc_7265.h"
#include "adc_client.h"
#include "dsc_config.h"
#include "hall_input.h"
#include "pos_estimator.h"
#include "pwm_cli.h"
#include "pwm_service.h"
#include "shared_io.h"
#include "qei_server.h"
#include "qei_client.h"

// Ethernet control headers
#include "control_comms_eth.h"
#include "xtcp_client.h"
#include "uip_server.h"
#include "ethernet_server.h"
#include "getmac.h"

#ifdef USE_XSCOPE
#include <xscope.h>
#endif

#define CMD_WELCOME		0
#define CMD_READ_ADC 	1
#define CMD_READ_HALL 	2
#define CMD_PWM_1 		3
#define CMD_PWM_2 		4
#define CMD_QEI 		5
#define CMD_HELP		6

const char net_commands[][8] = {
	"ip",
	"adc",
	"hall",
	"pwm1",
	"pwm2",
	"qei",
	"help"
};

const char mode_titles[][21] = {
	"XMOS Control Demo",
	"Current ADC values",
	"Current hall sensor",
	"PWM for motor 1",
	"PWM for motor 2",
	"Quadrature encoder"
};

static const char s_welcome_message[] =
		"XMOS Motor Control Board demonstration\r\n\n"
		"Type 'HELP' for a list of commands\r\n"
		"(Please use a line mode terminal)\r\n";

static const char s_help_message[] =
		"Command:\r\n\n"
		"ADC\t\t\t- Read the ADC\r\n"
		"HALL\t\t\t- Read the Hall sensors\r\n"
		"PWM1 a,b,c\t\t- Set the PWM values for motor 1\r\n"
		"PWM2 a,b,c\t\t- Set the PWM values for motor 2\r\n"
		"QEI\t\t\t- Read the quadrature encoder position\r\n\n";

const unsigned pwm_mode_values[13][3] = {
		{0x100,0x100,0x100},
		{0x800,0x100,0x100},
		{0x800,0x800,0x100},
		{0x000,0x800,0x100},
		{0x100,0x800,0x800},
		{0x100,0x100,0x800},
		{0x800,0x100,0x800},
		{0xF00,0x100,0xF00},
		{0xF00,0x100,0x100},
		{0xF00,0xF00,0x100},
		{0x100,0xF00,0x100},
		{0x100,0xF00,0xF00},
		{0x100,0x100,0xF00},
};

// Define where everything is
#define INTERFACE_CORE 0
#define MOTOR_CORE 1

// LCD & Button Ports
on stdcore[INTERFACE_CORE]: lcd_interface_t lcd_ports = { PORT_SPI_CLK, PORT_SPI_MOSI, PORT_SPI_SS_DISPLAY, PORT_SPI_DSA };
on stdcore[INTERFACE_CORE]: in port p_btns = PORT_BUTTONS;
on stdcore[INTERFACE_CORE]: out port p_leds = PORT_LEDS;

//CAN and ETH reset port
on stdcore[INTERFACE_CORE] : out port p_shared_rs=PORT_SHARED_RS;

// OTP for MAC address
on stdcore[INTERFACE_CORE]: port otp_data = XS1_PORT_32A; 	// OTP_DATA_PORT
on stdcore[INTERFACE_CORE]: out port otp_addr = XS1_PORT_16A;	// OTP_ADDR_PORT
on stdcore[INTERFACE_CORE]: port otp_ctrl = XS1_PORT_16B;	// OTP_CTRL_PORT

// Ethernet Ports
on stdcore[INTERFACE_CORE]: clock clk_mii_ref = XS1_CLKBLK_REF;
on stdcore[INTERFACE_CORE]: clock clk_smi = XS1_CLKBLK_3;
on stdcore[INTERFACE_CORE]: smi_interface_t smi = { PORT_ETH_MDIO, PORT_ETH_MDC, 0 };
on stdcore[INTERFACE_CORE]: mii_interface_t mii =
{
	XS1_CLKBLK_1, XS1_CLKBLK_2,
	PORT_ETH_RXCLK, PORT_ETH_RXER, PORT_ETH_RXD, PORT_ETH_RXDV,
	PORT_ETH_TXCLK, PORT_ETH_TXEN, PORT_ETH_TXD,
};

// Motor 1 ports
on stdcore[MOTOR_CORE]: port in p_hall1 = PORT_M1_HALLSENSOR;
on stdcore[MOTOR_CORE]: buffered out port:32 p_pwm_hi1[3] = {PORT_M1_HI_A, PORT_M1_HI_B, PORT_M1_HI_C};
on stdcore[MOTOR_CORE]: buffered out port:32 p_pwm_lo1[3] = {PORT_M1_LO_A, PORT_M1_LO_B, PORT_M1_LO_C};
on stdcore[MOTOR_CORE]: clock pwm_clk1 = XS1_CLKBLK_REF;
on stdcore[MOTOR_CORE]: port in p_qei1 = PORT_M1_ENCODER;

// Motor 2 ports
on stdcore[MOTOR_CORE]: port in p_hall2 = PORT_M2_HALLSENSOR;
on stdcore[MOTOR_CORE]: buffered out port:32 p_pwm_hi2[3] = {PORT_M2_HI_A, PORT_M2_HI_B, PORT_M2_HI_C};
on stdcore[MOTOR_CORE]: buffered out port:32 p_pwm_lo2[3] = {PORT_M2_LO_A, PORT_M2_LO_B, PORT_M2_LO_C};
on stdcore[MOTOR_CORE]: clock pwm_clk2 = XS1_CLKBLK_4;
on stdcore[MOTOR_CORE]: port in p_qei2 = PORT_M2_ENCODER;

// Watchdog port
on stdcore[INTERFACE_CORE]: out port i2c_wd = PORT_WATCHDOG;

on stdcore[MOTOR_CORE]: out port ADC_SCLK = PORT_ADC_CLK;
on stdcore[MOTOR_CORE]: port ADC_CNVST = PORT_ADC_CONV;
on stdcore[MOTOR_CORE]: buffered in port:32 ADC_DATA_A = PORT_ADC_MISOA;
on stdcore[MOTOR_CORE]: buffered in port:32 ADC_DATA_B = PORT_ADC_MISOB;
on stdcore[MOTOR_CORE]: out port ADC_MUX = PORT_ADC_MUX;
on stdcore[MOTOR_CORE]: in port ADC_SYNC_PORT1 = XS1_PORT_16A;
on stdcore[MOTOR_CORE]: in port ADC_SYNC_PORT2 = XS1_PORT_16B;
on stdcore[MOTOR_CORE]: clock adc_clk = XS1_CLKBLK_2;

// Function to initialise and run the TCP/IP server
void init_tcp_server(chanend c_mac_rx, chanend c_mac_tx, chanend c_xtcp[], chanend c_connect_status)
{
#if 1
	xtcp_ipconfig_t ipconfig =
	{
	  {0,0,0,0},		// ip address
	  {0,0,0,0},		// netmask
	  {0,0,0,0}       	// gateway
	};
#else
	xtcp_ipconfig_t ipconfig =
	{
	  {169, 254, 0, 1},	// ip address
	  {255,255,0,0},	// netmask
	  {0,0,0,0}       	// gateway
	};
#endif

	// Start the TCP/IP server
	uip_server(c_mac_rx, c_mac_tx, c_xtcp, 1, ipconfig, c_connect_status);
}


// Function to initialise and run the Ethernet server
void init_ethernet_server( port p_otp_data, out port p_otp_addr, port p_otp_ctrl, clock clk_smi, clock clk_mii, smi_interface_t &p_smi, mii_interface_t &p_mii, chanend c_mac_rx[], chanend c_mac_tx[], chanend c_connect_status, out port p_reset)
{
	int mac_address[2];

	// Bring the ethernet PHY out of reset
	p_reset <: 0x2;

	// Get the MAC address
	ethernet_getmac_otp(p_otp_data, p_otp_addr, p_otp_ctrl, (mac_address, char[]));

	// Initiate the PHY
	phy_init(clk_smi, null, p_smi, p_mii);

	// Run the Ethernet server
	ethernet_server(p_mii, mac_address, c_mac_rx, 1, c_mac_tx, 1, p_smi, c_connect_status);
}

unsigned parse_command(char rx_buf[], unsigned rx_length, int &result1, int &result2, int &result3)
{
	unsigned cmd;
	unsigned found;

	printstr(rx_buf);

	if (rx_buf[0] == 0xd || rx_buf[1] == 0x0a) return -1;

	for (cmd=0; cmd<CMD_HELP; ++cmd) {
		found=1;
		for (unsigned c=0; net_commands[cmd][c]!=0; ++c) {
			char ch=rx_buf[c];
			if (ch >= 'A' && ch <='Z') ch += ('a'-'A');
			if (ch != net_commands[cmd][c]) {
				found=0;
				break;
			}
		}
		if (found==1) break;
	}

	if (found==0) return CMD_HELP;

	return cmd;
}

void do_demo_interface(chanend c_xtcp, chanend commands)
{
	// Buttons and display
	timer tmr;
	unsigned timestamp;
	unsigned buttons = 0, buttons_active=1;

	// Current PWM values
	unsigned pwm[3][2] = {{0,0},{0,0},{0,0}};
	unsigned pwm_state[2] = {0,0};

	// TCP connection
	xtcp_connection_t conn;
	unsigned char tx_buf[512];
	unsigned char rx_buf[512];
	unsigned rx_length;

	// Input mode
	unsigned input_mode = CMD_WELCOME;

	// Initialise the LCD
	lcd_ports_init(lcd_ports);
	tmr :> timestamp;
	timestamp += 1000000;

	// Listen for connections on TCP control port
	xtcp_listen(c_xtcp, TCP_CONTROL_PORT, XTCP_PROTOCOL_TCP);

	while (1)
	{
		int result1, result2, result3;

		select
		{
			case (buttons_active==1) => p_btns when pinsneq(buttons) :> buttons:
			{
				unsigned p=0;

				switch (buttons)
				{
				case 0xE: // Button A
					input_mode = (input_mode==CMD_QEI)? CMD_WELCOME : input_mode+1;
					break;
				case 0xD: // Button B
					input_mode = (input_mode==CMD_WELCOME)? CMD_QEI : input_mode-1;
					break;
				case 0xB: // Button C
					switch (input_mode)
					{
					case CMD_PWM_1:
						p=0;
						break;
					case CMD_PWM_2:
						p=1;
						break;
					}
					pwm_state[p] = (pwm_state[p]==12)? 0 : pwm_state[p]+1;
					pwm[0][p] = pwm_mode_values[pwm_state[p]][0];
					pwm[1][p] = pwm_mode_values[pwm_state[p]][1];
					pwm[2][p] = pwm_mode_values[pwm_state[p]][2];
					break;
				case 0x7: // Button D
					switch (input_mode)
					{
					case CMD_PWM_1:
						p=0;
						break;
					case CMD_PWM_2:
						p=1;
						break;
					}
					pwm_state[p] = (pwm_state[p]==0)? 12 : pwm_state[p]-1;
					pwm[0][p] = pwm_mode_values[pwm_state[p]][0];
					pwm[1][p] = pwm_mode_values[pwm_state[p]][1];
					pwm[2][p] = pwm_mode_values[pwm_state[p]][2];
					break;
				default:
					break;
				}
				tmr :> timestamp;
				timestamp += 1000000;
				buttons_active = 0;
			}
			break;

			case tmr when timerafter(timestamp) :> void:
			{
				lcd_draw_text_row(mode_titles[input_mode], 0, lcd_ports);

				switch (input_mode)
				{
				case CMD_WELCOME:
				{
					xtcp_ipconfig_t ip;
					xtcp_get_ipconfig(c_xtcp, ip);

					if (ip.ipaddr[0] == 0) {
						safestrcpy(rx_buf, "IP: acquiring");
					} else {
						sprintf(rx_buf, "IP: %d.%d.%d.%d", ip.ipaddr[0], ip.ipaddr[1], ip.ipaddr[2], ip.ipaddr[3]);
					}
					lcd_draw_text_row(rx_buf, 1, lcd_ports);
					sprintf(rx_buf, "Port: %d", TCP_CONTROL_PORT);
					lcd_draw_text_row(rx_buf, 2, lcd_ports);
					break;
				}
				case CMD_READ_ADC:
					commands <: CMD_READ_ADC;
					commands :> result1;
					commands :> result2;
					commands :> result3;
					sprintf(rx_buf, " M1: 0x%x 0x%x", result1, result2);
					lcd_draw_text_row(rx_buf, 1, lcd_ports);

					commands :> result1;
					commands :> result2;
					commands :> result3;
					sprintf(rx_buf, " M2: 0x%x 0x%x", result1, result2);
					lcd_draw_text_row(rx_buf, 2, lcd_ports);
					break;

				case CMD_READ_HALL:
					commands <: CMD_READ_HALL;
					commands :> result1;
					commands :> result2;
					sprintf(rx_buf, " Hall1: 0x%x", result1);
					lcd_draw_text_row(rx_buf, 1, lcd_ports);
					sprintf(rx_buf, " Hall2: 0x%x", result2);
					lcd_draw_text_row(rx_buf, 2, lcd_ports);
					break;

				case CMD_PWM_1:
					sprintf(rx_buf, " PWM1: %x %x %x", pwm[0][0], pwm[1][0], pwm[2][0]);
					lcd_draw_text_row(rx_buf, 1, lcd_ports);
					rx_buf[0] = 0;
					lcd_draw_text_row(rx_buf, 2, lcd_ports);
					break;

				case CMD_PWM_2:
					sprintf(rx_buf, " PWM2: %x %x %x", pwm[0][1], pwm[1][1], pwm[2][1]);
					lcd_draw_text_row(rx_buf, 1, lcd_ports);
					rx_buf[0] = 0;
					lcd_draw_text_row(rx_buf, 2, lcd_ports);
					break;

				case CMD_QEI:
					commands <: CMD_QEI;
					commands :> result1;
					commands :> result2;
					sprintf(rx_buf, " QEI1: %x", result1);
					lcd_draw_text_row(rx_buf, 1, lcd_ports);
					sprintf(rx_buf, " QEI2: %x", result2);
					lcd_draw_text_row(rx_buf, 2, lcd_ports);
					break;
				}

				buttons_active=1;
				timestamp += 5000000; // 20Hz
			}
			break;

			// Get an event
			case xtcp_event(c_xtcp, conn):
			{
				unsigned command;

				if (conn.local_port == TCP_CONTROL_PORT) {

					// We have received an event from the TCP stack, so respond appropriately
					switch (conn.event)
					{
					case XTCP_NEW_CONNECTION:
						safestrcpy(tx_buf, s_welcome_message);
						xtcp_init_send(c_xtcp, conn);
						break;

					case XTCP_RECV_DATA:
						// Get the packet
						rx_length = xtcp_recv(c_xtcp, rx_buf);
						switch (parse_command(rx_buf, rx_length, result1, result2, result3)) {
						case CMD_READ_ADC:
						{
							unsigned result4, dummy;
							input_mode = CMD_READ_ADC;
							commands <: CMD_READ_ADC;
							commands :> result1;
							commands :> result2;
							commands :> dummy;
							commands :> result3;
							commands :> result4;
							commands :> dummy;
							sprintf(tx_buf, "ADC1: 0x%x 0x%x\r\nADC2: 0x%x 0x%x\r\n", result1, result2, result3, result4);
							xtcp_init_send(c_xtcp, conn);
						}
						break;
						case CMD_READ_HALL:
						{
							input_mode = CMD_READ_HALL;
							commands <: CMD_READ_HALL;
							commands :> result1;
							commands :> result2;
							sprintf(tx_buf, "Hall sensors: %x,%x\r\n", result1, result2);
							xtcp_init_send(c_xtcp, conn);
						}
						break;
						case CMD_PWM_1:
						{
							input_mode = CMD_PWM_1;
							pwm[0][0] = result1;
							pwm[1][0] = result2;
							pwm[2][0] = result3;
							sprintf(tx_buf, "Motor1 PWM set to: %d,%d,%d\r\n", result1, result2, result3);
							xtcp_init_send(c_xtcp, conn);
						}
						break;
						case CMD_PWM_2:
						{
							input_mode = CMD_PWM_2;
							pwm[0][1] = result1;
							pwm[1][1] = result2;
							pwm[2][1] = result3;
							sprintf(tx_buf, "Motor2 PWM set to: %d,%d,%d\r\n", result1, result2, result3);
							xtcp_init_send(c_xtcp, conn);
						}
						break;
						case CMD_QEI:
						{
							input_mode = CMD_QEI;
							commands <: CMD_QEI;
							commands :> result1;
							commands :> result2;
							sprintf(tx_buf, "QEI positions: %d,%d\r\n", result1, result2);
							xtcp_init_send(c_xtcp, conn);
						}
						break;
						case CMD_HELP:
						{
							safestrcpy(tx_buf, s_help_message);
							xtcp_init_send(c_xtcp, conn);
						}
						break;
						}
						break;

					case XTCP_SENT_DATA:
						// Indicate that we have sent everything
						xtcp_send(c_xtcp, null, 0);
						break;

					case XTCP_REQUEST_DATA:
					case XTCP_RESEND_DATA:
						// Send the data buffer
						xtcp_send(c_xtcp, tx_buf, strlen(tx_buf));
						break;

					case XTCP_TIMED_OUT:
					case XTCP_ABORTED:
					case XTCP_CLOSED:
						// Ask for connection to be closed
						xtcp_close(c_xtcp, conn);
						break;
					}

					// Mark event as handled
					conn.event = XTCP_ALREADY_HANDLED;
				}
			}
			break;
		}
	}
}

void do_demo_motor(chanend commands, chanend c_pwm[], chanend c_qei[], chanend c_adc[], in port p_hall1, in port p_hall2)
{
	unsigned cmd;
	unsigned r1, r2, r3;
	unsigned pwm[3];

	t_pwm_control pwm_ctrl1;
	t_pwm_control pwm_ctrl2;

	pwm_share_control_buffer_address_with_server(c_pwm[0], pwm_ctrl1);
	pwm_share_control_buffer_address_with_server(c_pwm[1], pwm_ctrl2);

	pwm[0] = 0;
	pwm[1] = 0;
	pwm[2] = 0;
	update_pwm(pwm_ctrl1, c_pwm[0], pwm);
	update_pwm(pwm_ctrl2, c_pwm[1], pwm);

	while (1)
	{
		select
		{
			case commands :> cmd:
			{
				switch (cmd)
				{
				case CMD_READ_ADC:
					{ r1, r2, r3 } = get_adc_vals_calibrated_int16(c_adc[0]);
					commands <: r1;
					commands <: r2;
					commands <: r3;
					{ r1, r2, r3 } = get_adc_vals_calibrated_int16(c_adc[1]);
					commands <: r1;
					commands <: r2;
					commands <: r3;
					break;

				case CMD_READ_HALL:
					p_hall1 :> r1;
					commands <: r1;
					p_hall2 :> r1;
					commands <: r1;
					break;

				case CMD_PWM_1:
					commands :> pwm[0];
					commands :> pwm[1];
					commands :> pwm[2];
					update_pwm(pwm_ctrl1, c_pwm[0], pwm);
					break;

				case CMD_PWM_2:
					commands :> pwm[0];
					commands :> pwm[1];
					commands :> pwm[2];
					update_pwm(pwm_ctrl2, c_pwm[1], pwm);
					break;

				case CMD_QEI:
					r1 = get_qei_position(c_qei[0]);
					commands <: r1;
					r1 = get_qei_position(c_qei[1]);
					commands <: r1;
					break;
				}
			}
			break;
		}
	}
}

int main ( void )
{
	chan c_qei[NUMBER_OF_MOTORS], c_pwm[NUMBER_OF_MOTORS];
	chan c_adc[NUMBER_OF_MOTORS], c_adc_trig[NUMBER_OF_MOTORS];
	chan c_mac_rx[1], c_mac_tx[1], c_xtcp[1], c_connect_status;
	chan c_demo_commands;

	par
	{
		on stdcore[MOTOR_CORE] : init_tcp_server( c_mac_rx[0], c_mac_tx[0], c_xtcp, c_connect_status );
		on stdcore[INTERFACE_CORE]: init_ethernet_server(otp_data, otp_addr, otp_ctrl, clk_smi, clk_mii_ref, smi, mii, c_mac_rx, c_mac_tx, c_connect_status, p_shared_rs);

		on stdcore[INTERFACE_CORE] : do_demo_interface(c_xtcp[0], c_demo_commands);
		on stdcore[MOTOR_CORE] : do_demo_motor(c_demo_commands, c_pwm, c_qei, c_adc, p_hall1, p_hall2);

		on stdcore[MOTOR_CORE] : do_pwm( c_pwm[0], c_adc_trig[0], ADC_SYNC_PORT1, p_pwm_hi1, p_pwm_lo1, pwm_clk1 );
		on stdcore[MOTOR_CORE] : do_qei ( c_qei[0], p_qei1 );
		on stdcore[MOTOR_CORE] : do_pwm( c_pwm[1], c_adc_trig[1], ADC_SYNC_PORT2, p_pwm_hi2, p_pwm_lo2, pwm_clk2 );
		on stdcore[MOTOR_CORE] : do_qei ( c_qei[1], p_qei2 );

		on stdcore[MOTOR_CORE] : adc_7265_triggered( c_adc, c_adc_trig, adc_clk, ADC_SCLK, ADC_CNVST, ADC_DATA_A, ADC_DATA_B, ADC_MUX );
	}

	return 0;
}
