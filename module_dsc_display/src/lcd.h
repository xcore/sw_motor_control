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
#ifndef _LCD_H_
#define _LCD_H_

#include <xccompat.h>

#define CHAR_BUF_SIZE	21*4

#ifdef __XC__
	/** \brief The control structure for the LCD ports.
         *
         *  The display uses an I2C interface with an extra control signal
         *  to support selection between a data read/write and a control
         *  read/write.  This extra signal is bit zero of the p_core1_shared
         *  member - which contains no other signals despite the name.
	 */
	typedef struct lcd_interface_t
	{
		out port p_lcd_sclk;      //!< i2c serial clock
		out port p_lcd_mosi;      //!< i2c serial data
		out port p_lcd_cs_n;      //!< i2c chip select
		out port p_core1_shared;  //!< Display data/control select
	} lcd_interface_t;
#endif

/** \brief Reverse the order of bytes in the array
 *
 * \param s the byte array to reverse
 */
void reverse(char s[]);

/** \brief Convert an integer into a base 10 ASCII string
 *
 * \param n the integer to represent in string form
 * \param s the output byte array to contain the number
 */
void itoa(int n, char s[]);

/** \brief Initialise the LCD device
 *
 * \param p the LCD interface description
 */
void lcd_ports_init( REFERENCE_PARAM(lcd_interface_t, p) );

/** \brief Write a byte to the LCD
 *
 * \param p the LCD interface description
 * \param i the byte to write
 * \param is_data a boolean indicating if the write is data or control information
 */
void lcd_byte_out( REFERENCE_PARAM(lcd_interface_t, p), unsigned char i, int is_data );

/** \brief Clear the LCD
 *
 * \param p the LCD interface description
 */
void lcd_clear( REFERENCE_PARAM(lcd_interface_t, p) );

/** \brief Draw an image on the LCD
 *
 *  Draw an image on the LCD.  The image is assumed to cover the complete
 *  LCD.  The size of the LCD is 128 wide by 32 high.
 *
 * \param image a byte array containing the image data.
 * \param p the LCD interface description
 */
void lcd_draw_image( const unsigned char image[], REFERENCE_PARAM(lcd_interface_t, p) );

/** \brief Write text to a row on the LCD
 *
 * Display a row of text. The LCD columns beyond the end of the string will be
 * cleared.
 *
 * \param string the ASCII string to display on the LCD
 * \param lcd_row the character row on which to display the string
 * \param p the LCD interface description
 */
void lcd_draw_text_row( const char string[], int lcd_row, REFERENCE_PARAM(lcd_interface_t, p) );

/** \brief Macro for writing data to the LCD
 *
 * \param p the LCD interface description
 * \param i the data to write
 */
#define lcd_data_out(p, i)         	lcd_byte_out(p, i, 1)

/** \brief Macro for writing a control byte to the LCD
 *
 * \param p the LCD interface description
 * \param i the data to write
 */
#define lcd_comm_out(p, i)         	lcd_byte_out(p, i, 0)

#endif /* _LCD_H_ */
