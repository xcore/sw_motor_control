/* Read data from stdin and write it to the OTP */

#include <syscall.h>
#include <print.h>
#include <otp.h>
#include <stdlib.h>
#include <platform.h>

#define D_PROG_STRING	"\nOTP programmer for XP-DSC-BLDC 1V1\n"
#define D_SERIAL_NUM	29010000
#define D_SERIAL_START	11
#define D_SERIAL_STOP	31
#define D_BOARD_IDENT	0x00030111
#define D_MAC_UPPER		0x00000022
#define D_MAC_LOWER		0x97003000



/* Bitmap at address 0x7ff:
 * Bitfield 	 Name 	 Description
 * [31] 	validFlag 	If ==0, this structure has been written and should be processed.
 * [30] 	newbitmapFlag 	If ==0, this bitmap is now invalid, and a new bitmap should be processed which follows the structure.
 * [25:29] 	headerLength 	Length of structure in words (including bitmap) rounded up to the next even number.
 * [22:24] 	numMac 	Number of MAC addresses that follow this bitmap (0-7).
 * [21] 	serialFlag 	if ==1, Board serial number follows bitmap.
 * [20] 	boardIDFlag 	if == 1, XMOS Board Identifier follows bitmap.
 * [19] 	boardIDStrFlag 	if == 1, Board ID string (null terminated) follows bitmap.
 * [18] 	oscSpeed 	if == 0, 25Mhz clock input to XCore. if ==1, undefined.
 * [0:17] 	undefined 	Leave =1.
 */

#define MASK(x) ((1 << x) - 1)
#define VALID_FLAG(x) ((x & MASK(1)) << 31)
#define NEW_BITMAP_FLAG(x) ((x & MASK(1)) << 30)
#define HEADER_LENGTH(x) ((x & MASK(5)) << 25)
#define NUM_MAC(x) ((x & MASK(3)) << 22)
#define SERIAL_FLAG(x) ((x & MASK(1)) << 21)
#define BOARD_ID_FLAG(x) ((x & MASK(1)) << 20)
#define BOARD_ID_STR_FLAG(x) ((x & MASK(1)) << 19)
#define OSC_SPEED_FLAG(x) ((x & MASK(1)) << 18)
#define RESERVED ((~0 & MASK(18)) << 0)


// Convert a hex char into the integer value
int charValue(char c)
{
	if (c >= '0' && c <= '9')
	{
		return c - '0';
	}

	if (c >= 'a' && c <= 'f')
	{
		return c + 0xa - 'a';
	}

	if (c >= 'A' && c <= 'F')
	{
		return c + 0xa - 'A';
	}

	return -1;
}


// Read board seial number from stdin. Must be string of 3 decimal digits with no seperators.
unsigned int readserialnum( void )
{
	char buf[4];
	unsigned int val;

	if (_read(FD_STDIN, buf, 4) < 4)
	{
		return 0;
	}

	if (buf[3] != '\n')
	{
		return 0;
	}

	// Check that all the characters are digits
	for (unsigned i = 0; i < 3; i++)
	{
		int val = charValue(buf[i]);

		if ( (val < 0) | (val > 9) )
		{
			return 0;
		}
	}

	val  = charValue(buf[0]) * 100;
	val += charValue(buf[1]) * 10;
	val += charValue(buf[2]);

	return val;
}


// Get the board information and write it to the OTP
void get_data(chanend c_data_0, chanend c_data_1, chanend c_data_2)
{
	char buf[2];
	unsigned data[19];
	unsigned mac_u[8], mac_l[8];
	unsigned part_serial_number, serial_number, board_identifier, num_MAC_address;

	#if defined(__XS1_L__)
		printstr(D_PROG_STRING);
	#else
		#error "Wrong target"
	#endif

	printstr("\nEnter last 3 digits of serial number (3 digits): ");
	part_serial_number = readserialnum();

	// Check that the serial number is in the range for this board
	if ((part_serial_number < D_SERIAL_START) || (part_serial_number > D_SERIAL_STOP))
	{
		printstrln("Serial number out of range\n");
		_Exit(2);
	}

	serial_number = D_SERIAL_NUM + part_serial_number;
	board_identifier = D_BOARD_IDENT;
	num_MAC_address = 1;
	mac_u[0] = D_MAC_UPPER;
	mac_l[0] = D_MAC_LOWER + part_serial_number;

	// Now, print out the data to the user
	printstr("\nSerial Number: ");
	printuint(serial_number);

	printstr("\nBoard Identifier: 0x");
	printhex(board_identifier);

	printstr("\nNum Of MAC Addresses: ");
	printuint(num_MAC_address);

	printstr("\nMAC address : ");
	printhex(mac_u[0]);
	printhex(mac_l[0]);

	printstr("\n\nEnter 1 to confirm data for writing, 0 to cancel: ");

	// Get them to enter a 1 to confirm
	if (_read(FD_STDIN, buf, 2) < 2)
	{
		printstrln("Error reading value from stdin\n");
		_Exit(2);
	}

	// Check if we can write the data
	if ( charValue(buf[0]) == 1 )
	{
		unsigned int has_serial = 0;
		unsigned int has_board_id = 0;
		unsigned int data_length = 0;
		unsigned int dp = 0;
		unsigned int otp_return;

		// Test if we have a board identifier
		if ( board_identifier != 0 )
		{
			has_board_id = 1;

			data[dp] = board_identifier;
			dp++;
		}

		// Test if we have a serial number
		if ( serial_number != 0 )
		{
			has_serial = 1;

			data[dp] = serial_number;
			dp++;
		}

		// Add the MAC addresses to the data buffer
		for ( unsigned int i = 0; i < num_MAC_address; i++ )
		{
			data[dp] = mac_l[i];
			dp++;

			data[dp] = mac_u[i];
			dp++;
		}

		// Setup the bitmap byte
		data[dp] = (VALID_FLAG(0) | NEW_BITMAP_FLAG(1) | HEADER_LENGTH(4) | NUM_MAC(num_MAC_address) | SERIAL_FLAG(has_serial) | BOARD_ID_FLAG(has_board_id) | BOARD_ID_STR_FLAG(0) | OSC_SPEED_FLAG(1) | RESERVED);
		dp++;

		// Calcualate the data length
		data_length = ( num_MAC_address * 2 ) + has_serial + has_board_id + 1;

		// Check that it matches what we have calculated.
		if ( dp != data_length )
		{
			printstrln("Error in calcualating OTP data length\n");
			_Exit(2);
		}

		// Print data for checking
		for ( unsigned int i = 0; i < data_length; i++ )
		{
			printstr("\n0x");
			printhex(data[i]);
		}

		printstr("\nWritting OTPs...\n\n");

		// Send the data out to the core 0
			c_data_0 <: data_length;

			// Send the data to core 0
			for ( unsigned int i = 0; i < data_length; i++ )
			{
				c_data_0 <: data[i];
			}

			// Get the return value
			c_data_0 :> otp_return;

			// Check the return value
			if (otp_return == 0)
			{
				printstr("\nOTP data written to Xcore 0\n");
			}
			else
			{
				printstr("\nError: Failed to write OTP data to Xcore 0\n");
				_Exit(2);
			}

		// Send the data out to the core 1
			c_data_1 <: data_length;

			// Send the data to core 1
			for ( unsigned int i = 0; i < data_length; i++ )
			{
				c_data_1 <: data[i];
			}

			// Get the return value
			c_data_1 :> otp_return;

			// Check the return value
			if (otp_return == 0)
			{
				printstr("\nOTP data written to Xcore 1\n");
			}
			else
			{
				printstr("\nError: Failed to write OTP data to Xcore 1\n");
				_Exit(2);
			}

		// Send the data out to the core 2
			c_data_2 <: data_length;

			// Send the data to core 2
			for ( unsigned int i = 0; i < data_length; i++ )
			{
				c_data_2 <: data[i];
			}

			// Get the return value
			c_data_2 :> otp_return;

			// Check the return value
			if (otp_return == 0)
			{
				printstr("\nOTP data written to Xcore 2\n");
			}
			else
			{
				printstr("\nError: Failed to write OTP data to Xcore 2\n");
				_Exit(2);
			}

		printstr("\nOTP Programming Completed\n");
		_Exit(0);
	}
	else
	{
		printstr("\nOTP data not written\n");
		_Exit(2);
	}
}


// Thread to wite otp data to otp on that core.
void write_data(chanend c_data_in, port otp_data, out port otp_addr, out port otp_ctrl)
{
	unsigned int data_length;
	unsigned data[19];
	Options options;
	timer t;

	// Setup the OTP options
	InitOptions(options);
	options.EnableChargePump = 1;
	options.differential_mode = 0;

	// Get the length of the otp data
	c_data_in :> data_length;

	// Check the length of the data
	if ( ( data_length > 0  ) && ( data_length <= 19 ) )
	{
		// Get the otp data
		for ( unsigned int i = 0; i < data_length; i++ )
		{
			c_data_in:> data[i];

			// Print it for sanity
			printstr("\n0x");
			printhex(data[i]);
		}

		// Write to the OTP and check what happened
		if (!Program(t, otp_data, otp_addr, otp_ctrl, 0x800 - data_length, data, data_length, options))
		{
			printstrln("Error writing MAC address to OTP\n");
			c_data_in <: 1;
		}
		else
		{
			// Writing worked, so return 0
			c_data_in <: 0;
		}
	}
	else
	{
		// Exit with an error printed if the data is the wrong length
		printstrln("Error getting OTP data - it's too long\n");
		_Exit(1);
	}
}


// OTP ports for core 0
on stdcore[0] : port otp_data_0 = XS1_PORT_32B;
on stdcore[0] : out port otp_addr_0 = XS1_PORT_16C;
on stdcore[0] : out port otp_ctrl_0 = XS1_PORT_16D;


// OTP ports for core 1
on stdcore[1] : port otp_data_1 = XS1_PORT_32B;
on stdcore[1] : out port otp_addr_1 = XS1_PORT_16C;
on stdcore[1] : out port otp_ctrl_1 = XS1_PORT_16D;


// OTP ports for core 2
on stdcore[2] : port otp_data_2 = XS1_PORT_32B;
on stdcore[2] : out port otp_addr_2 = XS1_PORT_16C;
on stdcore[2] : out port otp_ctrl_2 = XS1_PORT_16D;


// Program entry point
int main()
{
	chan c_data_0, c_data_1, c_data_2;

	par
	{
		// Xcore 0
		on stdcore[0] : get_data(c_data_0, c_data_1, c_data_2);
		on stdcore[0] : write_data(c_data_0, otp_data_0, otp_addr_0, otp_ctrl_0);

		// Xcore 1
		on stdcore[1] : write_data(c_data_1, otp_data_1, otp_addr_1, otp_ctrl_1);

		// Xcore 2
		on stdcore[2] : write_data(c_data_2, otp_data_2, otp_addr_2, otp_ctrl_2);
	}

	return 0;
}
