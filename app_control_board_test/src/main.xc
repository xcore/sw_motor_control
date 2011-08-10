/**
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
#include <print.h>

#include "lcd.h"
#include "shared_io.h"

extern unsigned char xmos_logo[];

// LCD
on stdcore[0]: lcd_interface_t p = { PORT_SPI_CLK, PORT_SPI_MOSI, PORT_SPI_SS_DISPLAY, PORT_SPI_DSA };

// GPIO
on stdcore[0]: out port leds = PORT_LEDS;
on stdcore[0]: in port btns = PORT_BUTTONS;

//CAN and ETH reset port
on stdcore[0] : out port p_shared_rs=PORT_SHARED_RS;

// CAN
on stdcore[0] : clock can_clk = XS1_CLKBLK_4;
on stdcore[0] : buffered in port:32 p_can_rx = PORT_CAN_RX;
on stdcore[0] : port p_can_tx = PORT_CAN_TX;

unsigned char black[16*32];

// OTP for MAC address

// Ethernet Ports
on stdcore[0]: clock eth_rx_clk_blk = XS1_CLKBLK_1;
on stdcore[0]: in port eth_rx_clk = PORT_ETH_RXCLK;
on stdcore[0]: buffered in port:32 eth_rx_data = PORT_ETH_RXD;
on stdcore[0]: in port eth_rx_valid = PORT_ETH_RXDV;

on stdcore[0]: clock eth_tx_clk_blk = XS1_CLKBLK_2;
on stdcore[0]: in port eth_tx_clk = PORT_ETH_TXCLK;
on stdcore[0]: buffered out port:32 eth_tx_data = PORT_ETH_TXD;
on stdcore[0]: out port eth_tx_enable = PORT_ETH_TXEN;

void waitfor(unsigned ms)
{
	timer t;
	unsigned ts;
	t :> ts;
	t when timerafter(ts + ms * 1000000) :> void;
}

void reset_devices()
{
	timer t;
	unsigned ts;

	p_shared_rs <: 0;
	t :> ts;
	t when timerafter(ts+10000000) :> void;
	p_shared_rs <: 0x2;
}

int test_buttons_and_leds()
{
	btns when pinseq(0xF) :> void;
	waitfor(10);

	printstr("Press the button next to each LED as it lights\n");
	leds <: 0x10;
	btns when pinseq(0xE) :> void;
	btns when pinseq(0xF) :> void;
	waitfor(10);

	leds <: 0x20;
	btns when pinseq(0xD) :> void;
	btns when pinseq(0xF) :> void;
	waitfor(10);

	leds <: 0x80;
	btns when pinseq(0xB) :> void;
	btns when pinseq(0xF) :> void;
	waitfor(10);

	leds <: 0x40;
	btns when pinseq(0x7) :> void;
	btns when pinseq(0xF) :> void;
	waitfor(10);

	printstr("Press any button if all LEDs are lit\n");
	leds <: 0xF0;
	btns when pinseq(0x7) :> void;
	btns when pinseq(0xF) :> void;
	waitfor(10);

	leds <: 0x00;

	return 1;
}

int test_display()
{
	for (unsigned i=0; i<16*32; i++) black[i] = 0xff;

	/* Initiate the LCD ports */
	lcd_ports_init(p);

	btns when pinseq(0xF) :> void;
	waitfor(10);

	printstr("Press any button when the display is all black\n");
	lcd_clear(p);
	btns when pinsneq(0xF) :> void;
	btns when pinseq(0xF) :> void;
	waitfor(10);

	printstr("Press any button when the display is all white\n");
	lcd_draw_image(black, p);
	btns when pinsneq(0xF) :> void;
	btns when pinseq(0xF) :> void;
	waitfor(10);

	printstr("Press any button when the display shows the splash screen\n");
	lcd_draw_image(xmos_logo, p);
	btns when pinsneq(0xF) :> void;
	btns when pinseq(0xF) :> void;
	waitfor(10);

	return 1;
}

int test_can()
{
	unsigned int success = 1;

	configure_clock_ref(can_clk, 32);
	configure_in_port_no_ready(p_can_rx, can_clk);
	set_port_clock(p_can_tx, can_clk);

	p_can_tx <: 1;

	start_clock(can_clk);

	printstr("Testing CAN\n");

	// Write out a bit pattern and read it in, checking that it is the same
	par
	{
		// Send
		{
			waitfor(10);
			p_can_tx <: 0;

			p_can_tx <: 1;
			p_can_tx <: 0;
			p_can_tx <: 1;
			p_can_tx <: 0;
			p_can_tx <: 1;
			p_can_tx <: 0;
			p_can_tx <: 0;
			p_can_tx <: 1;
			p_can_tx <: 1;
			p_can_tx <: 0;
			p_can_tx <: 0;
			p_can_tx <: 1;
			p_can_tx <: 1;
			p_can_tx <: 0;
			p_can_tx <: 0;
			p_can_tx <: 1;

			p_can_tx <: 1;
			p_can_tx <: 1;
			p_can_tx <: 1;
			p_can_tx <: 0;
			p_can_tx <: 0;
			p_can_tx <: 0;
			p_can_tx <: 0;
			p_can_tx <: 1;
			p_can_tx <: 0;
			p_can_tx <: 0;
			p_can_tx <: 0;
			p_can_tx <: 1;
			p_can_tx <: 1;
			p_can_tx <: 1;
			p_can_tx <: 0;
			p_can_tx <: 0;
		}

		// Receive
		{
			unsigned int rxd;
			p_can_rx when pinseq(0) :> void;
			p_can_rx :> rxd;
			if (rxd != 0b00111000100001111001100110010101) {
				printstr("Invalid data received from CAN: ");
				printhex(rxd);
				printchar('\n');
				success = 0;
			}
		}
	}

	return success;
}


// Ethernet timing constants
#define PAD_DELAY_RECEIVE    0
#define PAD_DELAY_TRANSMIT   0
#define CLK_DELAY_RECEIVE    0
#define CLK_DELAY_TRANSMIT   7

int test_ethernet()
{
	unsigned done = 0;

	// Setup receive MII pins

	set_port_use_on(eth_rx_clk);
	eth_rx_clk :> int;
	set_port_use_on(eth_rx_data);
	set_port_use_on(eth_rx_valid);

	set_pad_delay(eth_rx_clk, PAD_DELAY_RECEIVE);

	set_port_strobed(eth_rx_data);
	set_port_slave(eth_rx_data);

	set_clock_on(eth_rx_clk_blk);
	set_clock_src(eth_rx_clk_blk, eth_rx_clk);
	set_clock_ready_src(eth_rx_clk_blk, eth_rx_valid);
	set_port_clock(eth_rx_data, eth_rx_clk_blk);
	set_port_clock(eth_rx_valid, eth_rx_clk_blk);

	set_clock_rise_delay(eth_rx_clk_blk, CLK_DELAY_RECEIVE);

	start_clock(eth_rx_clk_blk);

	clearbuf(eth_rx_data);

	// Setup transmit MII pins

	set_port_use_on(eth_tx_clk);
	set_port_use_on(eth_tx_data);
	set_port_use_on(eth_tx_enable);

	set_pad_delay(eth_tx_clk, PAD_DELAY_TRANSMIT);

	eth_tx_data <: 0;
	eth_tx_enable <: 0;
	sync(eth_tx_data);
	sync(eth_tx_enable);

	set_port_strobed(eth_tx_data);
	set_port_master(eth_tx_data);
	clearbuf(eth_tx_data);

	set_port_ready_src(eth_tx_enable, eth_tx_data);
	set_port_mode_ready(eth_tx_enable);

	set_clock_on(eth_tx_clk_blk);
	set_clock_src(eth_tx_clk_blk, eth_tx_clk);
	set_port_clock(eth_tx_data, eth_tx_clk_blk);
	set_port_clock(eth_tx_enable, eth_tx_clk_blk);

	set_clock_fall_delay(eth_tx_clk_blk, CLK_DELAY_TRANSMIT);

	start_clock(eth_tx_clk_blk);

	clearbuf(eth_tx_data);

	printstr("Testing ethernet\n");

	par
	{
		// Receive
		{
			unsigned int rxd;
			unsigned i=1;

			eth_rx_valid when pinseq(1) :> int;
			eth_rx_data when pinseq(0xD) :> int;

			do
			{
				select
				{
					case eth_rx_data :> rxd:
					{
						if (rxd != i)
						{
							printstr("Received incorrect data during ethernet test\n");
							done = 2;
						}
						i++;
					}
					break;

					case eth_rx_valid when pinseq(0) :> int:
					{
						done = 1;
						break;
					}
				}
			} while (!done);

		};

		// Send
		{
			unsigned int txd;

			eth_tx_data <: 0x55555555;
			eth_tx_data <: 0x55555555;
			eth_tx_data <: 0xD5555555;

			for (unsigned i=1; i<256; i++)
			{
				eth_tx_data <: i;
			}
		};
	}
	return (done == 1) ? 1 : 0;
}


int main ( void )
{
	reset_devices();

	if (!test_buttons_and_leds()) return 0;
	if (!test_display()) return 0;
	if (!test_can()) return 0;
	if (!test_ethernet()) return 0;

	printstr("Passed\n");

	return 0;
}
