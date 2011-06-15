#include <xs1.h>
#include <xclib.h>
#include <print.h>
#include <string.h>
#include "lcd.h"
#include "lcd_data.h"


// String operations - reverse characters
void reverse(char s[])
{
	int i, j;
	char c;

	for (i = 0, j = strlen(s) - 1; i < j; i++, j--)
	{
		c = s[i];
		s[i] = s[j];
		s[j] = c;
	}
}


// String operations - itoa
void itoa(int n, char s[])
{
	int i, sign;

	if ((sign = n) < 0)
	{
		n = -n;
	}
	i = 0;

	do
	{
		s[i++] = n % 10 + '0';
	} while ((n /= 10) > 0);

	if (sign < 0)
	{
		s[i++] = '-';
	}
	s[i] = '\0';
	reverse(s);
}


// Initiate the LCD ports
void lcd_ports_init(REFERENCE_PARAM(lcd_interface_t, p))
{
	/*
	// configure ports and clock blocks
	configure_clock_rate(p.clk_lcd_1, 100, 2); // 25MHz clk block, making SPI clock 12.5MHz
	configure_out_port(p.p_lcd_sclk, p.clk_lcd_1, 0);
	configure_clock_src(p.clk_lcd_2, p.p_lcd_sclk);
	configure_out_port(p.p_lcd_mosi, p.clk_lcd_2, 0);
	clearbuf(p.p_lcd_mosi);
	clearbuf(p.p_lcd_sclk);
	start_clock(p.clk_lcd_1);
	start_clock(p.clk_lcd_2);
	p.p_lcd_sclk <: 0xFF;
	*/

	/*
    // Configure the display ports for port timers
    configure_clock_ref (p.clk_lcd_1, 4);
    configure_out_port (p.p_lcd_sclk, p.clk_lcd_1, 0);
    configure_out_port (p.p_lcd_mosi, p.clk_lcd_1, 0);
    configure_out_port (p.p_lcd_cs_n, p.clk_lcd_1, 1);
    start_clock (p.clk_lcd_1);
    */
}


// Send a byte out to the LCD
void lcd_byte_out(REFERENCE_PARAM(lcd_interface_t, p), unsigned char c, int is_data, unsigned int port_val)
{
	/*
	// Using clock blocks
	unsigned int data = (unsigned int) c;

	// Select the display
	p.p_lcd_cs_n <: 0;

	if (is_data)
	{
		// address
		p.p_core1_shared <: (port_val |= 0b1000);
	}
	else
	{
		// command
		p.p_core1_shared <: (port_val &= 0b0111);
	}

	// MSB-first bit order - SPI standard
	p.p_lcd_mosi <: bitrev(data) >> 24;
	p.p_lcd_sclk <: 0xAA;
	p.p_lcd_sclk <: 0xAA;
	sync( p.p_lcd_sclk );

	// Deselect the display
	p.p_lcd_cs_n <: 1;
	*/

	/*
	// Using port timers
	unsigned int t, i;
	unsigned int data = (unsigned int) c;

	// Select the display
	p.p_lcd_cs_n <: 0;

	if (is_data)
	{
		// address
		p.p_core1_shared <: (port_val |= 0b1000);
	}
	else
	{
		// command
		p.p_core1_shared <: (port_val &= 0b0111);
	}

	// Get the value of the port timer
	p.p_lcd_sclk <: 0 @ t;
	t += 10;

	// Loop through all 8 bits
	for ( i = 0; i < 8; i++)
	{
		// Send the clock low
		p.p_lcd_sclk @ t <: 0;

		// MSb-first bit order - SPI standard
		p.p_lcd_mosi @ t <: ( data >> (7 - i));

		// Wait for the setup time
		t += 10;

		// Send the clock high
		p.p_lcd_sclk @ t <: 1;

		// Wait for the clock high cycle
		t += 10;

		sync(p.p_lcd_sclk);
	}

	// Deselect the display
	p.p_lcd_sclk <: 0;
	p.p_lcd_cs_n <: 1;*/

	// Using timers
	unsigned int time, i;
	unsigned int data = (unsigned int) c;
	timer t;

	// Select the display
	p.p_lcd_cs_n <: 0;

	if (is_data)
	{
		// address
		p.p_core1_shared <: (port_val |= 0b1000);
	}
	else
	{
		// command
		p.p_core1_shared <: (port_val &= 0b0111);
	}

	// Get the value of the current timer
	//t :> time;

	// Loop through all 8 bits
	#pragma loop unroll
	for ( i = 0; i < 8; i++)
	{
		// MSb-first bit order - SPI standard
		p.p_lcd_mosi <: ( data >> (7 - i));
		sync(p.p_lcd_mosi);

		// Wait for the setup time
		//t when timerafter ( time + 8 ) :> time;

		// Send the clock high
		p.p_lcd_sclk <: 1;
		sync(p.p_lcd_sclk);

		// Wait for the clock high cycle
		//t when timerafter ( time + 8 ) :> time;

		// Send the clock low
		p.p_lcd_sclk <: 0;
		sync(p.p_lcd_sclk);
	}

	// Deselect the display
	p.p_lcd_cs_n <: 1;

}


// Clear the display
void lcd_clear( unsigned int port_val, REFERENCE_PARAM(lcd_interface_t, p) )
{
	unsigned int i, j, n = 0;
	unsigned char page = 0xB0;						// Page Address + 0xB0

	lcd_comm_out(p, 0xAE, port_val);				// Display OFF
	lcd_comm_out(p, 0x40, port_val);				// Display start address + 0x40
	lcd_comm_out(p, 0xA7, port_val);				// Invert

#pragma loop unroll
#pragma unsafe arrays
	for (i=0; i < 4; i++)							// 32 pixel display / 8 pixels per page = 4 pages
	{
		lcd_comm_out(p, page, port_val);			// send page address
		lcd_comm_out(p, 0x10, port_val);			// column address upper 4 bits + 0x10
		lcd_comm_out(p, 0x00, port_val);			// column address lower 4 bits + 0x00

		for (j=0; j < 128; j++)						// 128 columns wide
		{
			// Send the blank data
			lcd_data_out(p, 0x00, port_val);
			n++;									// point to next picture data
		}

		page++;										// after 128 columns, go to next page
	}

	lcd_comm_out(p, 0xAF, port_val);				// Display ON
}


// Draw an image to the display
void lcd_draw_image( unsigned char image[], unsigned int port_val, REFERENCE_PARAM(lcd_interface_t, p) )
{
	unsigned int i, j, n = 0;
	unsigned char page = 0xB0;						// Page Address + 0xB0

	lcd_comm_out(p, 0xAE, port_val);				// Display OFF
	lcd_comm_out(p, 0x40, port_val);				// Display start address + 0x40
	lcd_comm_out(p, 0xA7, port_val);				// Invert

#pragma loop unroll
#pragma unsafe arrays
	for (i=0; i < 4; i++)							// 32 pixel display / 8 pixels per page = 4 pages
	{
		lcd_comm_out(p, page, port_val);			// send page address
		lcd_comm_out(p, 0x10, port_val);			// column address upper 4 bits + 0x10
		lcd_comm_out(p, 0x00, port_val);			// column address lower 4 bits + 0x00

		for (j=0; j < 128; j++)						// 128 columns wide
		{
			lcd_data_out(p, image[n], port_val);	// send picture data
			n++;									// point to next picture data
		}

		page++;										// after 128 columns, go to next page
	}

	lcd_comm_out(p, 0xAF, port_val);				// Display ON
}


// Draw a row of text to the display
void lcd_draw_text_row( char string[], int lcd_row, unsigned int port_val, REFERENCE_PARAM(lcd_interface_t, p) )
{
	unsigned int i = 0, offset, col_pos = 0;

	unsigned char page = 0xB0 + lcd_row;		// Page Address + 0xB0 + row

	lcd_comm_out(p, 0xAE, port_val);			// Display OFF
	lcd_comm_out(p, 0x40, port_val);			// Display start address + 0x40
	lcd_comm_out(p, 0xA6, port_val);			// Non invert
	lcd_comm_out(p, page, port_val);			// Update page address
	lcd_comm_out(p, 0x10, port_val);			// column address upper 4 bits + 0x10
	lcd_comm_out(p, 0x00, port_val);			// column address lower 4 bits + 0x00

	// Loop through all the characters
	while (1)
	{
		// If we are at the end of the string, or it's too long, break.
		if ((string[i] == '\0') || (string[i] == '\n') || (i >= 21 ))
		{
			break;
		}

		// Check char is in range, otherwise unsafe arrays break
		if ((string[i] < 32) || (string[i] > 127))
		{
			// If not, print a space instead
			string[i] = ' ';
		}

#pragma unsafe arrays
		// Calculate the offset into the array
		offset = (string[i] - 32) * FONT_WIDTH;

		// Print a char, along with a space between chars
		lcd_data_out(p, font[offset++], port_val);
		lcd_data_out(p, font[offset++], port_val);
		lcd_data_out(p, font[offset++], port_val);
		lcd_data_out(p, font[offset++], port_val);
		lcd_data_out(p, font[offset++], port_val);
		lcd_data_out(p, 0x00, port_val);

		// Mark that we have written 6 rows
		col_pos += 6;

		// Move onto the next char
		i++;
	}

	// Blank the rest of the row
	while ( col_pos <= 127 )
	{
		lcd_data_out(p, 0x00, port_val);
		col_pos++;
	}

	lcd_comm_out(p, 0xAF, port_val);			// Display ON
}
