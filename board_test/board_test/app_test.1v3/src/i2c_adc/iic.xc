/*
 * @ModuleName 	iic
 * @Author 	Ali Dixon & Corin Rathbone
 * @Date 	27/08/2009
 * @Version 	2.0
 * @Description IIC interface driver
 *
 * The copyrights, all other intellectual and industrial
 * property rights are retained by XMOS and/or its licensors.
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2009
 */

#include <xs1.h>
#include <platform.h>
#include <print.h>
#include "iic.h"

// Timer for phy
timer IIC_timer;


// Wait for the specified amount of time
void iic_phy_wait ( signed delay )
{
	uint time;
	IIC_timer :> time;
	IIC_timer when timerafter ( time + delay ) :> uint tmp;
}


// Release the bus
XMOS_RTN_t iic_initialise ( port PORT_IIC_SCL, port PORT_IIC_SDA )
{
	XMOS_RTN_t returnCode = XMOS_SUCCESS;
	uint scl_value;
	uint sda_value;

	scl_value = 0;
	sda_value = 0;

	while ( ( scl_value != 1 ) || ( sda_value != 1 ) )
	{
		PORT_IIC_SCL :> scl_value;
		PORT_IIC_SDA :> sda_value;
	}

	iic_phy_wait ( 10 * iic_bittime );

	scl_value = 0;
	sda_value = 0;

	while ( ( scl_value != 1 ) || ( sda_value != 1 ) )
	{
		PORT_IIC_SCL :> scl_value;
		PORT_IIC_SDA :> sda_value;
	}

	return returnCode;
}


// Generate start condition
void iic_phy_master_start ( port PORT_IIC_SCL, port PORT_IIC_SDA )
{
	PORT_IIC_SCL <: 1;
	PORT_IIC_SDA <: 1;
	iic_phy_wait ( iic_start_cond_setup_time );

	PORT_IIC_SDA <: 0;
	iic_phy_wait ( iic_start_cond_hold_time );

	PORT_IIC_SCL <: 0;
}


// Generate stop condition
void iic_phy_master_stop ( port PORT_IIC_SCL, port PORT_IIC_SDA )
{
	PORT_IIC_SDA <: 0;
	iic_phy_wait ( iic_scl_low_time );

	PORT_IIC_SCL <: 1;
	iic_phy_wait ( iic_scl_high_time );

	PORT_IIC_SDA <: 1;
	iic_phy_wait ( iic_bus_free_time );
}


// Send a bit
uint iic_phy_sendBit ( port PORT_IIC_SCL, port PORT_IIC_SDA, uint bit )
{
	uint time;

	IIC_timer :> time;
	PORT_IIC_SDA <: bit;

	time += iic_scl_low_time;
	IIC_timer when timerafter ( time ) :> time;
	PORT_IIC_SCL <: 1;        // set clock high

	time += iic_scl_high_time;
	IIC_timer when timerafter ( time ) :> time;
	PORT_IIC_SCL <: 0;        // set clock low

	return 0;
}


// Receive a bit
uint iic_phy_receiveBit ( port PORT_IIC_SCL, port PORT_IIC_SDA )
{
	uint bit;
	uint time;

	IIC_timer :> time;
	PORT_IIC_SDA :> int tmp;

	time += iic_scl_low_time;
	IIC_timer when timerafter ( time ) :> time;
	PORT_IIC_SCL <: 1;        // set clock high

	PORT_IIC_SDA :> bit;

	time += iic_scl_high_time;
	IIC_timer when timerafter ( time ) :> time;
	PORT_IIC_SCL <: 0;        // set clock low

	return bit;
}


// Send a byte
XMOS_RTN_t iic_phy_sendByte ( port PORT_IIC_SCL, port PORT_IIC_SDA, uint inByte, uint expectAck )
{
	uint bitCount;
	uint bit;
	uint byte;
	uint ack;
	uint time;
	XMOS_RTN_t returnCode = XMOS_SUCCESS;

	byte = inByte;
	bitCount = 0;

	IIC_timer :> time;

	while ( bitCount < 8 )
	{
		bit = ( byte & 0x80 ) >> 7;

		PORT_IIC_SDA <: bit;

		time += iic_scl_low_time;
		IIC_timer when timerafter ( time ) :> time;
		PORT_IIC_SCL <: 1;        // set clock high

		byte = byte << 1;
		bitCount = bitCount + 1;

		time += iic_scl_high_time;
		IIC_timer when timerafter ( time ) :> time;
		PORT_IIC_SCL <: 0;        // set clock low
	}

	PORT_IIC_SDA :> int tmp;

	ack = iic_phy_receiveBit ( PORT_IIC_SCL, PORT_IIC_SDA );

	if (ack != expectAck)
	{
		returnCode = XMOS_FAIL;
	}

	return returnCode;
}


// Receive a byte
uint iic_phy_receiveByte ( port PORT_IIC_SCL, port PORT_IIC_SDA, uint ack )
{
	uint bitCount;
	uint bit;
	uint time;
	uint byte;

	byte = 0;
	bitCount = 0;

	IIC_timer :> time;

	// set to input
	PORT_IIC_SDA :> int tmp;

	while (bitCount < 8)
	{
		time += iic_scl_low_time;
		IIC_timer when timerafter(time) :> time;
		PORT_IIC_SCL <: 1;        // set clock high

		PORT_IIC_SDA :> bit;

		byte = (byte << 1) | bit;
		bitCount = bitCount + 1;

		time += iic_scl_high_time;
		IIC_timer when timerafter(time) :> time;
		PORT_IIC_SCL <: 0;        // set clock low
	}

	PORT_IIC_SDA :> int tmp;

	iic_phy_sendBit ( PORT_IIC_SCL, PORT_IIC_SDA, ack );

	return byte;
}


// Poll to determine when write completes
uint iic_checkWriteComplete ( port PORT_IIC_SCL, port PORT_IIC_SDA, uint address )
{
	uint time;

	while (1)
	{
		iic_phy_master_start( PORT_IIC_SCL, PORT_IIC_SDA );

		if ( iic_phy_sendByte ( PORT_IIC_SCL, PORT_IIC_SDA, address | IIC_WE, 0 ) == XMOS_SUCCESS)
		{
			break;
		}

		IIC_timer :> time;
		IIC_timer when timerafter ( time + iic_write_ack_poll_time ) :> time;
	}

	iic_phy_master_stop( PORT_IIC_SCL, PORT_IIC_SDA );

	return 0;
}


// Write to IIC device
XMOS_RTN_t iic_write ( port PORT_IIC_SCL, port PORT_IIC_SDA, uint address, char data[], uint numBytes )
{
	XMOS_RTN_t returnCode = XMOS_SUCCESS;
	uint startIndex = 0;
	uint i = 0;

	iic_phy_master_start ( PORT_IIC_SCL, PORT_IIC_SDA );

	returnCode = iic_phy_sendByte ( PORT_IIC_SCL, PORT_IIC_SDA, address | IIC_WE, 0 );

	for ( i=0; i<numBytes; i++)
	{
		if (returnCode == XMOS_SUCCESS)
		{
			returnCode = iic_phy_sendByte ( PORT_IIC_SCL, PORT_IIC_SDA, data[startIndex+i], 0 );
		}
		else
		{
			break;
		}
	}

	if (returnCode == XMOS_SUCCESS)
	{
		iic_phy_master_stop ( PORT_IIC_SCL, PORT_IIC_SDA );
		iic_checkWriteComplete ( PORT_IIC_SCL, PORT_IIC_SDA, address );
	}

	return returnCode;
}


// Read from IIC device - it sends ctrl byte and address
// It receives numBytes, acking each one and does not ack the final byte
XMOS_RTN_t iic_read ( port PORT_IIC_SCL, port PORT_IIC_SDA, uint address, char data[], uint numBytes, uint clkStretch )
{
	uint i, time;
	XMOS_RTN_t returnCode = XMOS_SUCCESS;

	iic_phy_master_start ( PORT_IIC_SCL, PORT_IIC_SDA );
	iic_phy_sendByte ( PORT_IIC_SCL, PORT_IIC_SDA, address | IIC_RE, 0 );

	for ( i=0; i<numBytes-1; i++ )
	{
		if ( clkStretch == 1 )
		{
			IIC_timer :> time;
			IIC_timer when timerafter(time + iic_bittime) :> time;

			clkStretch = 0;
		}

		data[i] = iic_phy_receiveByte ( PORT_IIC_SCL, PORT_IIC_SDA, 0 );
	}

	// receive final byte and dont ack to signal end of transfer
	data[i] = iic_phy_receiveByte ( PORT_IIC_SCL, PORT_IIC_SDA, 1);
	iic_phy_master_stop ( PORT_IIC_SCL, PORT_IIC_SDA );

	return returnCode;
}

