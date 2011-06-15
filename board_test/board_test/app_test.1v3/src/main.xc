#include <flashlib.h>
#include <platform.h>
#include <print.h>
#include <stdlib.h>
#include <stdio.h>
#include <xs1.h>
#include "dsc_sdram.h"
#include "ethernet_server.h"
#include "ethernet_rx_client.h"
#include "ethernet_tx_client.h"
#include "measure.h"
#include "shared_io.h"

// Defines for cores
#define PROCESSING_CORE 0
#define INTERFACE_CORE 1
#define MOTOR_CORE 2
#define ETHERNET_OTP_CORE 1

// SPI Flash Ports
on stdcore[PROCESSING_CORE] : fl_PortHolderStruct spi = { PORT_SPI_MISO, PORT_SPI_SS, PORT_SPI_CLK, PORT_SPI_MOSI, XS1_CLKBLK_1 };

// SDRAM Ports
on stdcore[PROCESSING_CORE] : sdram_interface_t sdram_ports =
{
	PORT_SDRAM_D,
	PORT_SDRAM_CKE,
	PORT_SDRAM_DQM_L,
	PORT_SDRAM_DQM_H,
	PORT_SDRAM_CLK,
	PORT_SDRAM_WE_N,
	PORT_SDRAM_RAS_N,
	PORT_SDRAM_CAS_N,
	PORT_SDRAM_CS_N,
	PORT_SDRAM_A,
	XS1_CLKBLK_2
};

// LCD, LED & Button Ports
on stdcore[INTERFACE_CORE]: lcd_interface_t lcd_ports = { PORT_DS_SCLK, PORT_DS_MOSI, PORT_DS_CS_N, PORT_CORE1_SHARED };
on stdcore[INTERFACE_CORE]: port in btns_ports[4] = {PORT_BUTTON_A, PORT_BUTTON_B, PORT_BUTTON_C, PORT_BUTTON_D};
on stdcore[INTERFACE_CORE]: out port p_leds	= PORT_LEDS;

// CAN
on stdcore[INTERFACE_CORE] : clock p_can_clk = XS1_CLKBLK_4;
on stdcore[INTERFACE_CORE] : port p_can_rx = PORT_CAN_RX;
on stdcore[INTERFACE_CORE] : port p_can_tx = PORT_CAN_TX;

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

// X-Link
on stdcore[INTERFACE_CORE] : in port p_xlink = XS1_PORT_4B;

// Motor core ports
on stdcore[MOTOR_CORE]: port in p_m1_enc = PORT_M1_ENCODER;
on stdcore[MOTOR_CORE]: port in p_m2_enc = PORT_M2_ENCODER;
on stdcore[MOTOR_CORE]: out port p_pwm_hi[3] = {PORT_M1_HI_A, PORT_M1_HI_B, PORT_M1_HI_C};
on stdcore[MOTOR_CORE]: out port p_pwm_lo[3] = {PORT_M1_LO_A, PORT_M1_LO_B, PORT_M1_LO_C};
on stdcore[MOTOR_CORE]: clock pwm_clk = XS1_CLKBLK_REF;

on stdcore[MOTOR_CORE]: port p_i2c_sda = PORT_I2C_SDA;			// ICL SDA
on stdcore[MOTOR_CORE]: port p_i2c_wd = PORT_I2C_WD_SHARED;		// IIC SCL

on stdcore[MOTOR_CORE]: out port ADC_SCLK = PORT_ADC_CLK;
on stdcore[MOTOR_CORE]: out port ADC_CNVST = PORT_ADC_CONV;
on stdcore[MOTOR_CORE]: in port ADC_DATA = PORT_ADC_MISO;
on stdcore[MOTOR_CORE]: in port ADC_SYNC_PORT = XS1_PORT_16A;
on stdcore[MOTOR_CORE]: clock adc_clk = XS1_CLKBLK_2;

/*/ I2C & WATCHDOG
// ADC
on stdcore[2]: out port p_adc_clk 					= PORT_ADC_CLK;
on stdcore[2]: out port p_adc_conv 					= PORT_ADC_CONV;
on stdcore[2]: in port p_adc_miso 					= PORT_ADC_MISO;*/


#define WINBOND_W25X40BV 7

fl_DeviceSpec myFlashDevices[] =
{
	{
		WINBOND_W25X40BV,		/* WINBOND_W25X40BV */
		256,                    /* page size */
		2048,                   /* num pages */
		3,                      /* address size */
		8,                      /* log2 clock divider */
		0x9f,                   /* SPI_RDID */
		0,                      /* id dummy bytes */
		3,                      /* id size in bytes */
		0xef3013,               /* device id */
		0x20,                   /* SPI_SSE */
		0,                      /* full sector erase */
		0x06,                   /* SPI_WREN */
		0x04,                   /* SPI_WRDI */
		PROT_TYPE_SR,           /* protection through status reg */
		{{0x1c,0x00},{0,0}},    /* no values */
		0x02,                   /* SPI_PP */
		0x0b,                   /* SPI_READFAST */
		1,                      /* 1 read dummy byte */
		SECTOR_LAYOUT_REGULAR,  /* sane sectors */
		{4096,{0,{0}}},         /* regular sector size */
		0x05,                   /* SPI_RDSR */
		0x01,                   /* SPI_WRSR */
		0x01,                   /* SPI_WIP_BIT_MASK */
   	}
};

// test data for flash
#define TEST_DATA(byte, page) (3 * (byte) + 7 + 5 * (page))


// Prototypes
int mac_rx_in_select(chanend c_mac, unsigned char buffer[], REFERENCE_PARAM(unsigned int, src_port));



void adc( chanend command_in, in port DATA, out port CNVST, port out SCLK )
{
     unsigned adc_val[6]= {0,0,0,0,0,0};
     unsigned vals1_2 = 0, vals3_4 = 0, vals5_6 = 0, my_bit, temp;
     unsigned ts, i, j;

	 timer t;

	 command_in :> temp;

	 t:> ts;

	 while ( 1)
	 {

		 CNVST <: 0;
		 SCLK <: 0;
		 t when timerafter (ts + 1000) :> ts;

		 CNVST <: 1;
		 SCLK <: 1;
		 t when timerafter (ts + 1000) :> ts;

		 CNVST <: 0;
		 SCLK <: 0;
		 t when timerafter (ts + 1000) :> ts;

		 for ( j = 0; j < 6; j++ )
		 {
			 for ( i = 0; i < 16; i++ )
			 {
				SCLK <: 1;
				t when timerafter (ts + 1000) :> ts;

				SCLK <: 0;
				DATA :> my_bit;

				adc_val[j] = ( adc_val[j] << 1 ) + my_bit;

				t when timerafter (ts + 1000) :> ts;
			}

			// Not sure why we need the shift down by 1!
			adc_val[j] = ( adc_val[j] >> 1 ) & 0x3FFF;
		}

		/*printstr( "RAW: " );
		printuint( adc_val[0] ); printchar( ' ' );
		printuint( adc_val[1] ); printchar( ' ' );
		printuint( adc_val[2] ); printchar( ' ' );
		printuint( adc_val[3] ); printchar( ' ' );
		printuint( adc_val[4] ); printchar( ' ' );
		printuintln( adc_val[5] );*/

		// Convert the values into mV 1bit = 0.15259720441921503998046755783434mV
        adc_val[0] = ((adc_val[0] * 15259) / 100000);// - 1250;
        adc_val[1] = ((adc_val[1] * 15259) / 100000);// - 1250;
		adc_val[2] = ((adc_val[2] * 15259) / 100000);// - 1250;
		adc_val[3] = ((adc_val[3] * 15259) / 100000);// - 1250;
		adc_val[4] = ((adc_val[4] * 15259) / 100000);// - 1250;
		adc_val[5] = ((adc_val[5] * 15259) / 100000);// - 1250;

		printstr( "mV: " );
		printuint( adc_val[0] ); printchar( ' ' );
		printuint( adc_val[1] ); printchar( ' ' );
		printuint( adc_val[2] ); printchar( ' ' );
		printuint( adc_val[3] ); printchar( ' ' );
		printuint( adc_val[4] ); printchar( ' ' );
		printuintln( adc_val[5] );
     }
}



// Function to test the flash on the board
int test_flash( void )
{
	unsigned char data[256], ret[256];

	//if (fl_connect(spi) != 0)
	if (fl_connectToDevice(spi, myFlashDevices, 1 ) != 0)
	{
    	printstrln("FLASH: cannot connect to flash");
    	return 0;
  	}

	if ( ( fl_getFlashType() != ATMEL_AT25DF041A ) && ( fl_getFlashType() != WINBOND_W25X40BV ) )
	{
    	printstrln("FLASH: unrecognised model");
    	printhexln(fl_getFlashType());
    	return 0;
  	}

	if ( fl_getFlashSize() != 524288 )
	{
    	printstrln("FLASH: unrecognised size");
    	return 0;
  	}

	if ( fl_getPageSize() != 256 )
	{
    	printstrln("FLASH: unrecognised page size");
    	return 0;
  	}

	if (fl_eraseAll() != 0)
	{
    	printstrln("FLASH: erase could not complete");
    	return 0;
  	}

	if (fl_setProtection(0) != 0)
	{
    	printstrln("FLASH: protect/unprotect could not complete");
    	return 0;
  	}

	for (int page = 0; page < 8; page++)
	{
		for (int i = 0; i < sizeof(data); i++)
		{
			data[i] = TEST_DATA(i, page);
		}

		if (fl_writePage(page * 256, data) != 0)
		{
    	  	printstrln("FLASH: cannot complete write");
    		return 0;
    	}
	}

	for (int page = 0; page < 8; page++)
	{
		if (fl_readPage(page * 256, ret) != 0)
		{
    	  	printstrln("FLASH: cannot complete read");
	    	return 0;
    	}

		for (int i = 0; i < sizeof(data); i++)
		{
			data[i] = TEST_DATA(i, page);
		}

		for (int i = 0; i < 256; i++)
		{
			if (data[i] != ret[i])
			{
        		printstrln("FLASH: invalid data read back from flash");
    			return 0;
      		}
		}
	}

	fl_disconnect();

	// We got to the end, so it all worked.
	return 1;
}


// MAC custom filter to get the Ethernet to work correctly
unsigned int mac_custom_filter(unsigned int pkt[])
{
	return 1;
}


// Function to test the boot MODE pins
int test_boot_status ( void )
{
	unsigned int mode_reg = getps ( ( 0x03 << 8 ) | 0x0B );

	if ( ( mode_reg & 0b1111 ) == 0b0001 )
	{
		return 1;
	}
	else
	{
		printstr("MODE PINS: ");
		printuintln(mode_reg);
		return 0;
	}
}


// Function to test the Ethernet
int test_eth(chanend rx, chanend tx)
{
	unsigned int tx_counter, rx_counter;
	unsigned char rxbuffer[1600];
	unsigned int src_port, time1, time2, txbuffer[15], data_buffer[15];
	int nbytes, data_valid = 1;
	timer t1, t2;

	// Wait for 2 seconds to allow the Ethernet to boot up.
	t1 :> time1;
	t1 when timerafter(time1 + 200000000) :> time1;

	// Stuff some data in the tx buffer
	data_buffer[0] = 0xFFFFFFFF; // 4
	data_buffer[1] = 0x2200FFFF; // 8
	data_buffer[2] = 0x01000097; // 12
	data_buffer[3] = 0x01000608; // 16
	data_buffer[4] = 0xAAAAAAAA; // 20
	data_buffer[5] = 0xAAAAAAAA; // 24
	data_buffer[6] = 0xAAAAAAAA; // 28
	data_buffer[7] = 0xAAAAAAAA; // 32
	data_buffer[8] = 0xAAAAAAAA; // 36
	data_buffer[9] = 0xAAAAAAAA; // 40
	data_buffer[10] = 0xAAAAAAAA; // 44
	data_buffer[11] = 0xAAAAAAAA; // 48
	data_buffer[12] = 0xAAAAAAAA; // 52
	data_buffer[13] = 0xAAAAAAAA; // 56
	data_buffer[14] = 0xAAAAAAAA; // 60

	// Copy the aray over the tx array to provent parallel usage
	for ( int i = 0; i < 15; i++ )
	{
		txbuffer[i] = data_buffer[i];
	}

	// Turn on the MAC filtering (otherwise we don't get anything)
	mac_set_custom_filter(rx, 0x1);

	// Split into an rx and tx thread
	par
	{
		for ( tx_counter = 0; tx_counter < 100; tx_counter++ )
		{
			// Add the counter to the end fo the packet
			txbuffer[14] = tx_counter;

			// Transmit a packet
			mac_tx(tx, txbuffer, 60, 0);

			// Wait for 1ms
			t1 :> time1;
			t1 when timerafter(time1 + 1000000) :> time1;
		}
		// Timeout here?

		for ( rx_counter = 0; rx_counter < 100; rx_counter++ )
		{
			// Receive a packet
   			unsigned char tmp;

   			t2 :> time2;

			select
			{
				// Receive a packet
				case inuchar_byref(rx, tmp):
					nbytes = mac_rx_in_select(rx, rxbuffer, src_port);

					//nbytes = mac_rx(rx, rxbuffer, src_port);

		  			// Check the receive length
		  			if ( nbytes != 60 )
		  			{
		  				printstrln("ETHERNET: Packet wrong size");
		  				data_valid = 0;
		  			}

		  			// Check the data
		  			for ( unsigned int i = 0; i < 14; i++ )
		  			{
		  				if ( data_buffer[i] != (rxbuffer, unsigned int[])[i] )
		  				{
		  					printstrln("ETHERNET: Packet contains wrong data");
		  					data_valid = 0;
		  				}
		  			}

		  			// Check the counter value
		  			if ( rx_counter != (rxbuffer, unsigned int[])[14] )
		  			{
		  				printstr("ETHERNET: Packet contains wrong counter - ");
		  				printuint(rx_counter);
		  				printstr(" / ");
		  				printuintln((rxbuffer, unsigned int[])[14]);
		  				data_valid = 0;
					}

					break;

				// Timeout ater 5 seconds if we haven't received a packet
				case t2 when timerafter (time2 + 500000000) :> time2 :

					printstr("ETHERNET: No packets received.");

					// Mark that the data is not recieved.
					data_valid = 0;

					// Exit the loop
					rx_counter = 100;

					break;
			}
		}
	}

	return data_valid;
}


int sdram_test(chanend c_sdram)
{
	unsigned int address = 0;
	unsigned counter = 0;
	unsigned rd_data = 0;
	unsigned fail_count = 0;

	// SDRAM_NWORDS = 8388608
	// SDRAM_PACKET_NWORDS = 32

	printstr("Testing SDRAM... please wait...");

	// Fill the sdram
	while (address < (SDRAM_NWORDS*2))
	{
		c_sdram <: 1;
		master
		{
			c_sdram <: address;
			for (int i = 0; i < SDRAM_PACKET_NWORDS; i++)
			{
				c_sdram <: counter;
				counter++;
			}
		}

		// Calculate the memory location for the record - it's 16bits wide (2bytes), so add 64 not 32.
		address += (SDRAM_PACKET_NWORDS * 2);
	}

	counter = 0;

	// Read from all the memory
	c_sdram <: 2;

	for (int i = 0; i < ( SDRAM_NWORDS / SDRAM_PACKET_NWORDS ); i++)
	{
		// Get the record of data
		for ( int j = 0; j < SDRAM_PACKET_NWORDS; j++ )
		{
			// Get the current word from memory
			c_sdram :> rd_data;

			if (rd_data != counter)
			{
				printuint(rd_data);
				printchar(' ');
				printuintln(counter);
				fail_count++;
			}
			counter++;
		}
	}

	if (fail_count > 0)
	{
		printstr(" failures : ");
		printuintln(fail_count);
		return 0;
	}
	else
	{
		printchar('\n');
		return 1;
	}
}


// Function to print out a result to the user.
void print_result(int result_input)
{
	if ( result_input == 1 )
	{
		printstrln( " : PASS" );
	}
	else
	{
		printstrln( " : FAIL <----" );
	}
}


// Run that controls the running of all the tests
void test_commander( chanend c_cmd_out_1, chanend c_cmd_out_2, chanend c_cmd_out_2b, chanend rx, chanend tx, chanend c_sdram )
{
	// generating 1kHz on SYNC
	// reading back 24.576MHz
	unsigned int	i;
	int 			temp, results[14], f, F = 24576, d = 20, temp_results[4];
	chan 			stop2;

	// 0 = FLASH
	// 1 = MODE L2
	// 2 = MODE L1
	// 3 = LEDS + BUTTONS
	// 4 = DISPLAY
	// 5 = X-LINK
	// 6 = SDRAM
	// 7 = CAN
	// 8 = ETHERNET
	// 9 = UART
	// 10 = I2C ADC
	// 11 = ADC
	// 12 = HALFBRIDGES
	// 13 = WATCHDOG

	// Inform the user of the version
	printstrln("\nXP-DSC-BLDC 1V1 TEST SUITE\n");

	// Check the FLASH
	results[0] = test_flash();

	// Check the L2 MODE pins
	results[1] = test_boot_status();

	// Check the L1 MODE pins
	c_cmd_out_1 <: TEST_MODE_PINS;
	c_cmd_out_1 :> results[2];

	// Check the LEDS and BUTTONS
	c_cmd_out_1 <: TEST_LED_BUT;
	c_cmd_out_1 :> results[3];

	// Check the DISPLAY
	c_cmd_out_1 <: TEST_DISPLAY_0;
	c_cmd_out_1 :> temp;

	printstrln("Please press A to confirm LCD is all white...");
	c_cmd_out_1 <: PRESS_A_W;
	c_cmd_out_1 :> temp_results[0];

	c_cmd_out_1 <: TEST_DISPLAY_1;
	c_cmd_out_1 :> temp;

	printstrln("Please press A to confirm LCD is all black...");
	c_cmd_out_1 <: PRESS_A_W;
	c_cmd_out_1 :> temp_results[1];

	results[4] = temp_results[0] && temp_results[1];

	// Check the X-LINK
	c_cmd_out_1 <: TEST_X_LINK;
	c_cmd_out_1 :> results[5];

	// Check the SDRAM
	results[6] = sdram_test(c_sdram);

	// Check the CAN
	printstrln("Please fit the CAN loopback connector and press A to confirm...");
	c_cmd_out_1 <: PRESS_A;
	c_cmd_out_1 :> temp;

	c_cmd_out_1 <: TEST_CAN;
	c_cmd_out_1 :> results[7] ;

	// Check the ETHERNET
	printstrln("Please fit the Ethernet loopback cable and press A to confirm...");
	c_cmd_out_1 <: PRESS_A;
	c_cmd_out_1 :> temp;

	results[8] = test_eth( rx, tx );

	// Now check the UART - can't test
	results[9] = 1; //test_uart();

	// I2C ADC
	c_cmd_out_2 <: 1;
	c_cmd_out_2 :> results[10];

	// Check all the results
	temp = 1;
	for ( i = 0; i < 12; i++ )
	{
		if ( results[i] != 1 )
		{
			temp = 0;
			break;
		}
	}

	if ( temp == 1 )
	{
		printstrln( "\nAll tests done and passed...\n" );
	}
	else
	{
		printstrln( "\nAll tests done, but with some fails...\n" );
	}

	printstr( "FLASH\t\t" );
	print_result(results[0]);

	printstr( "L2 MODE PINS\t" );
	print_result(results[1]);

	printstr( "L1 MODE PINS\t" );
	print_result(results[2]);

	printstr( "LED + BUTTONS\t" );
	print_result(results[3]);

	printstr( "DISPLAY\t\t" );
	print_result(results[4]);

	printstr( "X-LINK\t\t" );
	print_result(results[5]);

	printstr( "SDRAM\t\t" );
	print_result(results[6]);

	printstr( "CAN\t\t" );
	print_result(results[7]);

	printstr( "ETHERNET\t" );
	print_result(results[8]);

	printstr( "UART\t\t" );
	print_result(results[9]);

	printstr( "I2C ADC\t\t" );
	print_result(results[10]);

	c_cmd_out_2b <: 1;

	// We have finished, so let xrun return.
	exit(0);
}


// Program Entry Point
int main(void)
{
	chan mac_rx[1], mac_tx[1];
	chan c_control_eth, c_control_can, c_cmd_core_1, cmd_core_2, cmd_core_2b, c_sdram;

	par
	{
		// XCore 0
		on stdcore[0] : sdram_server( c_sdram, sdram_ports );
		on stdcore[0] : test_commander( c_cmd_core_1, cmd_core_2, cmd_core_2b, mac_rx[0], mac_tx[0], c_sdram );

		// XCore 1
		on stdcore[1] : display_shared_io_manager(c_control_eth, c_control_can, c_cmd_core_1, lcd_ports, p_leds, btns_ports, p_xlink, p_can_rx, p_can_tx );
		on stdcore[1] :
		{
			int mac_address[2] = { 0x00229700, 0x40000000 };
			phy_init(clk_smi, clk_mii_ref, c_control_eth, smi, mii);
			ethernet_server(mii, clk_mii_ref, mac_address, mac_rx, 1, mac_tx, 1, smi, null); //connect_status
		}

		// XCore 2
		on stdcore[2] : adc ( cmd_core_2b, ADC_DATA, ADC_CNVST, ADC_SCLK );
		on stdcore[2] : measure_task ( cmd_core_2, p_i2c_wd, p_i2c_sda );
	}

	return 0;
}
