/**
 * Module:  module_dsc_display
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
	p.p_lcd_cs_n <: 1;

	p.p_lcd_sclk <: 1;
	sync(p.p_lcd_sclk);

	p.p_lcd_sclk <: 0;
	sync(p.p_lcd_sclk);

	p.p_lcd_sclk <: 1;
	sync(p.p_lcd_sclk);

	p.p_lcd_sclk <: 0;
	sync(p.p_lcd_sclk);

	p.p_lcd_sclk <: 1;
	sync(p.p_lcd_sclk);

	p.p_lcd_sclk <: 0;
	sync(p.p_lcd_sclk);

	// Now initialize the device
	lcd_comm_out(p, 0xE2);		/* RESET */
	lcd_comm_out(p, 0xA0);		/* RAM->SEG output = normal */
	lcd_comm_out(p, 0xAE);		/* Display OFF */
	lcd_comm_out(p, 0xC0);		/* COM scan direction = normal */
	lcd_comm_out(p, 0xA2);		/* 1/9 bias */
	lcd_comm_out(p, 0xC8);		/*  Reverse */
	lcd_comm_out(p, 0x2F);		/* power control set */
	lcd_comm_out(p, 0x20);		/* resistor ratio set */
	lcd_comm_out(p, 0x81);		/* Electronic volume command (set contrast) */
	lcd_comm_out(p, 0x3F);		/* Electronic volume value (contrast value) */
	lcd_clear(p);				/* Clear the display RAM */
	lcd_comm_out(p, 0xB0);		/* Reset page and column addresses */
	lcd_comm_out(p, 0x10);		/* column address upper 4 bits + 0x10 */
	lcd_comm_out(p, 0x00);		/* column address lower 4 bits + 0x00 */
}


// Send a byte out to the LCD
void lcd_byte_out(REFERENCE_PARAM(lcd_interface_t, p), unsigned char c, int is_data)
{
	unsigned int i;
	unsigned int data = (unsigned int) c;

	// Select the display
	p.p_lcd_cs_n <: 0;

	if (is_data)
	{
		// address
		p.p_core1_shared <: 1;
	}
	else
	{
		// command
		p.p_core1_shared <: 0;
	}

	// Loop through all 8 bits
	#pragma loop unroll
	for ( i = 0; i < 8; i++)
	{
		// MSb-first bit order - SPI standard
		p.p_lcd_mosi <: ( data >> (7 - i));
		sync(p.p_lcd_mosi);

		// Send the clock high
		p.p_lcd_sclk <: 1;
		sync(p.p_lcd_sclk);

		// Send the clock low
		p.p_lcd_sclk <: 0;
		sync(p.p_lcd_sclk);
	}

	// Deselect the display
	p.p_lcd_cs_n <: 1;

}


// Clear the display
void lcd_clear( REFERENCE_PARAM(lcd_interface_t, p) )
{
	unsigned int i, j, n = 0;
	unsigned char page = 0xB0;						// Page Address + 0xB0

	lcd_comm_out(p, 0xAE);				// Display OFF
	lcd_comm_out(p, 0x40);				// Display start address + 0x40
	lcd_comm_out(p, 0xA7);				// Invert

#pragma loop unroll
#pragma unsafe arrays
	for (i=0; i < 4; i++)							// 32 pixel display / 8 pixels per page = 4 pages
	{
		lcd_comm_out(p, page);			// send page address
		lcd_comm_out(p, 0x10);			// column address upper 4 bits + 0x10
		lcd_comm_out(p, 0x00);			// column address lower 4 bits + 0x00

		for (j=0; j < 128; j++)						// 128 columns wide
		{
			// Send the blank data
			lcd_data_out(p, 0x00);
			n++;									// point to next picture data
		}

		page++;										// after 128 columns, go to next page
	}

	lcd_comm_out(p, 0xAF);				// Display ON
}


// Draw an image to the display
void lcd_draw_image( const unsigned char image[], REFERENCE_PARAM(lcd_interface_t, p) )
{
	unsigned int i, j, n = 0;
	unsigned char page = 0xB0;						// Page Address + 0xB0

	lcd_comm_out(p, 0xAE);				// Display OFF
	lcd_comm_out(p, 0x40);				// Display start address + 0x40
	lcd_comm_out(p, 0xA7);				// Invert

#pragma loop unroll
#pragma unsafe arrays
	for (i=0; i < 4; i++)							// 32 pixel display / 8 pixels per page = 4 pages
	{
		lcd_comm_out(p, page);			// send page address
		lcd_comm_out(p, 0x10);			// column address upper 4 bits + 0x10
		lcd_comm_out(p, 0x00);			// column address lower 4 bits + 0x00

		for (j=0; j < 128; j++)						// 128 columns wide
		{
			lcd_data_out(p, image[n]);	// send picture data
			n++;									// point to next picture data
		}

		page++;										// after 128 columns, go to next page
	}

	lcd_comm_out(p, 0xAF);				// Display ON
}


// Draw a row of text to the display
void lcd_draw_text_row( const char string[], int lcd_row, REFERENCE_PARAM(lcd_interface_t, p) )
{
	unsigned int i = 0, offset, col_pos = 0;

	unsigned char page = 0xB0 + lcd_row;		// Page Address + 0xB0 + row

	lcd_comm_out(p, 0xAE);			// Display OFF
	lcd_comm_out(p, 0x40);			// Display start address + 0x40
	lcd_comm_out(p, 0xA6);			// Non invert
	lcd_comm_out(p, page);			// Update page address
	lcd_comm_out(p, 0x10);			// column address upper 4 bits + 0x10
	lcd_comm_out(p, 0x00);			// column address lower 4 bits + 0x00

	// Loop through all the characters
	while (1)
	{
		char c = string[i];
		// If we are at the end of the string, or it's too long, break.
		if ((c == '\0') || (c == '\n') || (i >= 21 ))
		{
			break;
		}

		// Check char is in range, otherwise unsafe arrays break
		if ((c < 32) || (c > 127))
		{
			// If not, print a space instead
			c = ' ';
		}

#pragma unsafe arrays
		// Calculate the offset into the array
		offset = (c - 32) * FONT_WIDTH;

		// Print a char, along with a space between chars
		lcd_data_out(p, font[offset++]);
		lcd_data_out(p, font[offset++]);
		lcd_data_out(p, font[offset++]);
		lcd_data_out(p, font[offset++]);
		lcd_data_out(p, font[offset++]);
		lcd_data_out(p, 0x00);

		// Mark that we have written 6 rows
		col_pos += 6;

		// Move onto the next char
		i++;
	}

	// Blank the rest of the row
	while ( col_pos <= 127 )
	{
		lcd_data_out(p, 0x00);
		col_pos++;
	}

	lcd_comm_out(p, 0xAF);			// Display ON
}
