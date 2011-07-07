/**
 * Module:  module_dsc_display
 * Version: 1v0module_dsc_display0
 * Build:   2dfe7de13fb331bd93dee1a7397dfbf4cac3f053
 * File:    lcd.h
 * Modified by : Srikanth
 * Last Modified on : 27-May-2011
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
#ifndef _LCD_H_
#define _LCD_H_

#include <xccompat.h>

#define CHAR_BUF_SIZE	21*4

typedef struct lcd_interface_t
{
	out port p_lcd_sclk; // buffered port:8
	out port p_lcd_mosi; // buffered port:8
	out port p_lcd_cs_n;
	out port p_core1_shared;
} lcd_interface_t;

void reverse(char s[]);
void itoa(int n, char s[]);

void lcd_ports_init( REFERENCE_PARAM(lcd_interface_t, p) );
void lcd_byte_out( REFERENCE_PARAM(lcd_interface_t, p), unsigned char i, int is_data, unsigned int port_val );

void lcd_clear( unsigned int port_val, REFERENCE_PARAM(lcd_interface_t, p) );
void lcd_draw_image( unsigned char image[], unsigned int port_val, REFERENCE_PARAM(lcd_interface_t, p) );
void lcd_draw_text_row( char string[], int lcd_row, unsigned int port_val, REFERENCE_PARAM(lcd_interface_t, p) );

#define lcd_data_out(p, i, v)         	lcd_byte_out(p, i, 1, v)
#define lcd_comm_out(p, i, v)         	lcd_byte_out(p, i, 0, v)

#endif /* _LCD_H_ */
