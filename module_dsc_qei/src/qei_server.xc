/**
 * Module:  module_dsc_qei
 * Version: 1v0alpha0
 * Build:   3a9f71a8be03a46f99a43ab12f3b1932762e406f
 * File:    qei_server.xc
 * Modified by : Srikanth
 * Last Modified on : 26-May-2011
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
#include "qei_commands.h"
#include "dsc_config.h"
#include <stdio.h>

#define INVALID_STATE 0xFFFF

static unsigned update_pos( unsigned cur_pos, int delta );
static unsigned calc_state ( unsigned A, unsigned B, unsigned I);
static select do_state_0( in port pQEI, unsigned &pos, unsigned &pos_valid, unsigned &state, unsigned &CW, unsigned &next_state, unsigned &tmp, unsigned &A, unsigned &B, unsigned &I, timer t, unsigned &ts1, unsigned &ts2 );
static select do_state_1( in port pQEI, unsigned &pos, unsigned &pos_valid, unsigned &state, unsigned &CW, unsigned &next_state, unsigned &tmp, unsigned &A, unsigned &B, unsigned &I, timer t, unsigned &ts1, unsigned &ts2 );
static select do_state_2( in port pQEI, unsigned &pos, unsigned &pos_valid, unsigned &state, unsigned &CW, unsigned &next_state, unsigned &tmp, unsigned &A, unsigned &B, unsigned &I, timer t, unsigned &ts1, unsigned &ts2 );
static select do_state_3( in port pQEI, unsigned &pos, unsigned &pos_valid, unsigned &state, unsigned &CW, unsigned &next_state, unsigned &tmp, unsigned &A, unsigned &B, unsigned &I, timer t, unsigned &ts1, unsigned &ts2 );
static select do_state_4( in port pQEI, unsigned &pos, unsigned &pos_valid, unsigned &state, unsigned &CW, unsigned &next_state, unsigned &tmp, unsigned &A, unsigned &B, unsigned &I, timer t, unsigned &ts1, unsigned &ts2 );
{unsigned, unsigned, unsigned} calc_pin_vals( unsigned val );
{unsigned, unsigned, unsigned} get_pin_vals( port in pQEI );

void do_qei ( chanend c_qei, port in pQEI )
{
	unsigned state = 0;
	unsigned A=0, B=0, I=0;
	unsigned cmd_qei;

	unsigned ts1 = 0, ts2 = 0;
	unsigned next_state = 0;
	unsigned pos = 0, pos_valid = 0, CW = 0;
	unsigned tmp = 0 ;
	timer t;

	{A, B, I} = get_pin_vals( pQEI );
	state = calc_state( A, B, I );

	while (1)
	{
		select
		{
			case c_qei :> cmd_qei:
				switch (cmd_qei)
				{
					case QEI_CMD_POS_REQ:
						c_qei <: pos;
						break;

					case QEI_CMD_SPEED_REQ:
						c_qei <: ts1;
						c_qei <: ts2;
						break;

					case QEI_CMD_POS_KNOWN_REQ:
						c_qei <: pos_valid;
						break;

					case QEI_CMD_CW_REQ:
						c_qei <: CW;
						break;

					default:
						/* ignore unknown command */
						break;
				}
				break;

			default:
				switch (state)
				{
					case 0:
						do_state_0( pQEI, pos, pos_valid, state, CW, next_state, tmp, A, B, I, t, ts1, ts2 );
						break;

					case 1:
						do_state_1( pQEI, pos, pos_valid, state, CW, next_state, tmp, A, B, I, t, ts1, ts2 );
						break;

					case 2:
						do_state_2( pQEI, pos, pos_valid, state, CW, next_state, tmp, A, B, I, t, ts1, ts2 );
						break;

					case 3:
						do_state_3( pQEI, pos, pos_valid, state, CW, next_state, tmp, A, B, I, t, ts1, ts2 );
						break;

					case 4:
						do_state_4( pQEI, pos, pos_valid, state, CW, next_state, tmp, A, B, I, t, ts1, ts2 );
						break;

					default:
						state = calc_state( A, B, I ); // calculate where we should be
						if (state == INVALID_STATE) state = 1; // goto default state if we can't find a correct one
						break;
				}
				break;
		}
	}
}

static unsigned calc_state ( unsigned A, unsigned B, unsigned I)
{
	if (A == 0)
	{
		if (B == 0)
		{
			if (I == 1)
				return 0;
			else /* I == 0 */
				return 4;
		}
		else /* B == 1 */
		{
			if (I == 0)
				return 3;
			else
				return INVALID_STATE;
		}
	}
	else /* A == 1 */
	{
		if (B == 0)
		{
			if (I == 0)
				return 1;
			else
				return INVALID_STATE;
		}
		else /* B == 1 */
		{
			if (I == 0)
				return 2;
			else
				return INVALID_STATE;
		}
	}

	return INVALID_STATE;
}

static unsigned update_pos( unsigned cur_pos, int delta )
{
#ifdef FAULHABER_MOTOR
	#define QEI_COUNT_MAX (1024 * 4)
#else
	#define QEI_COUNT_MAX (256 * 4)
#endif
	int pos;

	pos = cur_pos;
	pos += delta;

	if (pos < 0)
		pos += QEI_COUNT_MAX;
	if (pos > QEI_COUNT_MAX)
		pos -= QEI_COUNT_MAX;

	return (unsigned)pos;
}

{unsigned, unsigned, unsigned} calc_pin_vals( unsigned val )
{
	unsigned A,B,I;

	/* extract values */
	A = 0x1 & (val >> 0);
	B = 0x1 & (val >> 1);
	I = 0x1 & (val >> 2);

	return {A,B,I};
}

{unsigned, unsigned, unsigned} get_pin_vals( port in pQEI )
{
	unsigned tmp, A, B, I;

	pQEI :> tmp;

	/* extract values */
	A = 0x1 & (tmp >> 0);
	B = 0x1 & (tmp >> 1);
	I = 0x1 & (tmp >> 2);

	return {A,B,I};
}

static select do_state_0( in port pQEI, unsigned &pos, unsigned &pos_valid, unsigned &state, unsigned &CW, unsigned &next_state, unsigned &tmp, unsigned &A, unsigned &B, unsigned &I, timer t, unsigned &ts1, unsigned &ts2 )
{
	case pQEI when pinsneq(0b001) :> tmp:
		{A, B, I} = calc_pin_vals( tmp );
		next_state = calc_state( A, B, I );
		if (next_state == 1)
		{
			ts1 = ts2;
			t :> ts2;
			pos = update_pos( pos, +1 );
			CW = 1;
			state = next_state;
		}
		else if (next_state == 4)
		{
			pos_valid = 1;
			state = next_state;
		} else if (next_state == 0)
		{
			state = next_state;
		}
		else state = INVALID_STATE;
		break;
}

static select do_state_1( in port pQEI, unsigned &pos, unsigned &pos_valid, unsigned &state, unsigned &CW, unsigned &next_state, unsigned &tmp, unsigned &A, unsigned &B, unsigned &I, timer t, unsigned &ts1, unsigned &ts2 )
{
	case pQEI when pinsneq(0b100) :> tmp:
		{A, B, I} = calc_pin_vals( tmp );
		next_state = calc_state( A, B, I );
		if (next_state == 0)
		{
			pos = 0;
			pos_valid = 1;
			CW = 0;
			state = next_state;
		}
		else if (next_state == 4)
		{
			ts1 = ts2;
			t :> ts2;
			pos = update_pos( pos, -1 );
			CW = 0;
			state = next_state;
		}
		else if (next_state == 2)
		{
			ts1 = ts2;
			t :> ts2;
			pos = update_pos( pos, +1 );
			CW = 1;
			state = next_state;
		} else if (next_state == 1)
		{
			state = next_state;
		}
		else state = INVALID_STATE;
		break;
}


static select do_state_2( in port pQEI, unsigned &pos, unsigned &pos_valid, unsigned &state, unsigned &CW, unsigned &next_state, unsigned &tmp, unsigned &A, unsigned &B, unsigned &I, timer t, unsigned &ts1, unsigned &ts2 )
{
	case pQEI when pinsneq(0b110) :> tmp:
		{A, B, I} = calc_pin_vals( tmp );
		next_state = calc_state( A, B, I );

		if (next_state == 1)
		{
			ts1 = ts2;
			t :> ts2;
			pos = update_pos( pos, -1 );
			CW = 0;
			state = next_state;
		} else if (next_state == 3)
		{
			ts1 = ts2;
			t :> ts2;
			pos = update_pos( pos, +1 );
			CW = 1;
			state = next_state;
		} else if (next_state == 2)
		{
			state = next_state;
		}
		else state = INVALID_STATE;
		break;
}

static select do_state_3( in port pQEI, unsigned &pos, unsigned &pos_valid, unsigned &state, unsigned &CW, unsigned &next_state, unsigned &tmp, unsigned &A, unsigned &B, unsigned &I, timer t, unsigned &ts1, unsigned &ts2 )
{
	case pQEI when pinsneq(0b010) :> tmp:
		{A, B, I} = calc_pin_vals( tmp );
		next_state = calc_state( A, B, I );

		if (next_state == 2)
		{
			ts1 = ts2;
			t :> ts2;
			pos = update_pos( pos, -1 );
			CW = 0;
			state = next_state;
		}
		else if (next_state == 4)
		{
			ts1 = ts2;
			t :> ts2;
			pos = update_pos( pos, +1 );
			CW = 1;
			state = next_state;
		}
		else if (next_state == 3)
		{
			state = next_state;
		}
		else state = INVALID_STATE;
		break;
}

static select do_state_4( in port pQEI, unsigned &pos, unsigned &pos_valid, unsigned &state, unsigned &CW, unsigned &next_state, unsigned &tmp, unsigned &A, unsigned &B, unsigned &I, timer t, unsigned &ts1, unsigned &ts2 )
{
	case pQEI when pinsneq(0b000) :> tmp:
		{A, B, I} = calc_pin_vals( tmp );
		next_state = calc_state( A, B, I );

		if (next_state == 3)
		{
			ts1 = ts2;
			t :> ts2;
			pos = update_pos( pos, -1 );
			CW = 0;
			state = next_state;
		} else 	if (next_state == 1)
		{
			ts1 = ts2;
			t :> ts2;
			pos = update_pos( pos, +1 );
			CW = 1;
			state = next_state;
		}
		else if (next_state == 0)
		{
			pos = 0;
			pos_valid = 1;
			CW = 1;
			state = next_state;
		}
		else if (next_state == 4)
		{
			state = next_state;
		}
		else state = INVALID_STATE;
		break;
}
