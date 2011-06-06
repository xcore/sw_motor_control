/**
 * Module:  module_dsc_adc
 * Version: 1v0alpha3
 * Build:   dcbd8f9dde72e43ef93c00d47bed86a114e0d6ac
 * File:    adc_ltc1408.xc
 * Modified by : Srikanth
 * Last Modified on : 31-May-2011
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
#include "adc_ltc1408.h"
#include "adc_common.h"
#include <stdlib.h>
#include <print.h>

static void configure_adc_ports_ltc1408(clock clk, port out SCLK, buffered out port:32 CNVST, in buffered port:32 DATA)
{
    configure_clock_rate_at_least(clk, 100, 10);

    configure_port_clock_output(SCLK, clk);
    configure_out_port(CNVST, clk, 0);
	configure_in_port(DATA, clk);

    set_port_sample_delay( DATA ); // clock in on falling edge

    start_clock(clk);
}

#pragma unsafe arrays
static void adc_get_data_ltc1408( unsigned adc_val[], unsigned count,  buffered out port:32 CNVST, in buffered port:32 DATA )
{

	unsigned val1 = 0, val3 = 0, val5 = 0;
	unsigned ts;

	for (int i = 0; i < count; i++)
	{
		// trigger conversion
		CNVST <: 0x0000002 @ ts;
		ts += 33;
		DATA @ ts :> val1;
		val1 = bitrev(val1);
		ts += 32;
		DATA @ ts :> val3;
		val3 = bitrev(val3);
		ts += 32;
		DATA @ ts :> val5;
		val5 = bitrev(val5);

		adc_val[(i*6)+0] = 0x3FFF & (val1 >> 17);
		adc_val[(i*6)+1] = 0x3FFF & (val1 >>  1);
		adc_val[(i*6)+2] = 0x3FFF & (val3 >> 17);
		adc_val[(i*6)+3] = 0x3FFF & (val3 >>  1);
		adc_val[(i*6)+4] = 0x3FFF & (val5 >> 17);
		adc_val[(i*6)+5] = 0x3FFF & (val5 >>  1);

	}

}

#pragma unsafe arrays
static void adc_get_data_ltc1408_singleshot( int adc_val[], unsigned offset, buffered out port:32 CNVST, in buffered port:32 DATA, clock clk )
{

	unsigned val1 = 0, val3 = 0, val5 = 0;

	stop_clock(clk);

	#define ADC_CONVERSION_TRIG (1<<31)
    CNVST <: ADC_CONVERSION_TRIG;
    clearbuf(DATA);
    start_clock(clk);
//	CNVST <: 0x0000001 @ ts;
//	asm("out res[%0],%1" :: "r"(CNVST),"r"(0x1));
//	asm("getts %0,res[%1]" :"=r"(ts) :"r"(CNVST));
//	ts += 2;
	DATA :> val1;
	CNVST <: 0;
	DATA :> val1;
	val1 = bitrev(val1);
	DATA :> val3;
	val3 = bitrev(val3);
	DATA :> val5;
    val5 = bitrev(val5);

	adc_val[offset+0] = 0x3FFF & (val1 >> 16);
	adc_val[offset+1] = 0x3FFF & (val1 >>  0);
	adc_val[offset+2] = 0x3FFF & (val3 >> 16);
	adc_val[offset+3] = 0x3FFF & (val3 >>  0);
	adc_val[offset+4] = 0x3FFF & (val5 >> 16);
	adc_val[offset+5] = 0x3FFF & (val5 >>  0);


}

void adc_ltc1408_test( clock clk, port out SCLK, buffered out port:32 CNVST, in buffered port:32 DATA )
{
	int adc_val[6];

    configure_adc_ports_ltc1408(clk, SCLK, CNVST, DATA);

    while (1)
    {
    	adc_get_data_ltc1408_singleshot( adc_val, 0, CNVST, DATA, clk );
   		printintln(adc_val[0]);
   		printintln(adc_val[1]);
   		printintln(adc_val[2]);
    }
}

void adc_ltc1408_triggered( chanend c_adc, clock clk, port out SCLK, buffered out port:32 CNVST, in buffered port:32 DATA, chanend c_trig, chanend ?c_logging0, chanend ?c_logging1, chanend ?c_logging2)
{
	int adc_val[6];
	int cmd;
	unsigned char ct;

	timer t;
	unsigned ts;

	configure_adc_ports_ltc1408(clk, SCLK, CNVST, DATA);

	while (1)
	{
		select
		{
		case inct_byref(c_trig, ct):
			if (ct == ADC_TRIG_TOKEN)
			{
				t :> ts;
				t when timerafter(ts + 1740) :> ts;
				adc_get_data_ltc1408_singleshot( adc_val, 0, CNVST, DATA, clk );
			}
			break;
		case c_adc :> cmd:
			switch (cmd)
			{
			case 0:
				master {
					c_adc <: adc_val[0];
					c_adc <: adc_val[1];
					c_adc <: adc_val[2];
				}
				break;
			case 3:
				master {
					c_adc <: adc_val[3];
					c_adc <: adc_val[4];
					c_adc <: adc_val[5];
				}
				break;
			case 6:
				master {
					c_adc <: adc_val[0];
					c_adc <: adc_val[1];
					c_adc <: adc_val[2];
					c_adc <: adc_val[3];
					c_adc <: adc_val[4];
					c_adc <: adc_val[5];
				}
				break;
			}
		break;
		}

	}
}


//#pragma unsafe arrays
void adc_ltc1408_filtered( chanend c_adc, clock clk, port out SCLK, buffered out port:32 CNVST, in buffered port:32 DATA, chanend ?c_logging0, chanend ?c_logging1, chanend ?c_logging2 )
{
	/* repeated to easily accomodate a rotating adc buffer */
	static int xcoeffs[] = {
	  -1837118, -1292872,  -495230,   558396,  1855534,  3368050,
	   5052608,  6852256,  8699044, 10517552, 12229104, 13756388,
	  15028144, 15983602, 16576332, 16777214, 16576332, 15983602,
	  15028144, 13756388, 12229104, 10517552,  8699044,  6852256,
	   5052608,  3368050,  1855534,   558396,  -495230, -1292872,
	  -1837118,
	  -1837118, -1292872,  -495230,   558396,  1855534,  3368050,
	   5052608,  6852256,  8699044, 10517552, 12229104, 13756388,
	  15028144, 15983602, 16576332, 16777214, 16576332, 15983602,
	  15028144, 13756388, 12229104, 10517552,  8699044,  6852256,
	   5052608,  3368050,  1855534,   558396,  -495230, -1292872,
	  -1837118,
	};

	int adc_val[ADC_FILT_SAMPLE_COUNT * ADC_CHANS];

	int h,l,r,i,j;
	int adc_tmp[ADC_CHANS],adc_filt[ADC_CHANS];
	int filt_chan = 0, filt_offset = 0;
	int write_pos=0, adc_chan=0;
	unsigned trig_ts,cmd,log_flag=0,pos=0,val=0,sample_count = 0,insert_pos=0;

	timer t;

	configure_adc_ports_ltc1408(clk, SCLK, CNVST, DATA);

    t :> trig_ts;

    stop_clock(clk);

	#define ADC_CONVERSION_TRIG (1<<31)
    CNVST <: ADC_CONVERSION_TRIG;
    clearbuf(DATA);
    start_clock(clk);
    sample_count = 3;
    pos = 0;
    adc_chan = 2; // we start at ADC 2
    /* initialise write position */
    write_pos = ADC_FILT_SAMPLE_COUNT;

    CNVST <: 0;

    while (1)
    {
    	select
    	{
			case c_adc :> cmd:
				switch (cmd)
				{
				case 0:
					master
					{
						c_adc <: adc_filt[0];
						c_adc <: adc_filt[1];
						c_adc <: adc_filt[2];
					}
					break;
				case 7:
					log_flag = 1;
					break;
				}
			break;
//			case t when timerafter(trig_ts+1000000000) :> trig_ts:
//				log_flag = 1;
//				break;
			case DATA :> val:
				if (sample_count != 1)
					CNVST <: 0;
				else
					CNVST <: ADC_CONVERSION_TRIG; 	// trigger conversion

				val = bitrev(val);

				adc_tmp[adc_chan] = 0x3FFF & (val >> 16);
				adc_chan += 1;

				adc_tmp[adc_chan] = 0x3FFF & (val >>  0);

#if 0
				if (log_flag == 1)
				{
					if (adc_chan == 1)
					{
						if (!isnull(c_logging0))
							c_logging0 <: adc_tmp[0]; // log channel ADC0
						if (!isnull(c_logging1))
							c_logging1 <: adc_tmp[1]; // log channel ADC1
					}
				}
#endif

				adc_chan += 1;
				if (adc_chan >= ADC_CHANS)
					adc_chan = 0;

				switch (sample_count)
				{
				case 3:
					h=l=0;
					#pragma loop unroll
					for (j = 0; j < 10; j++) {h,l} = macs(xcoeffs[pos+j], adc_val[filt_offset+j], h, l);
					sample_count = 2;
					break;
				case 2:
					#pragma loop unroll
					for (j = 10; j < 20; j++) {h,l} = macs(xcoeffs[pos+j], adc_val[filt_offset+j], h, l);
					sample_count = 1;
					break;
				case 1:
					/* finish filtering */
					#pragma loop unroll
					for (j = 20; j < ADC_FILT_SAMPLE_COUNT; j++) {h,l} = macs(xcoeffs[pos+j], adc_val[filt_offset+j], h, l);

					r  = (l >> 12) & 0x000FFFFF;
					r |= (h << 20) & 0xFFF00000;
					r >>= 12;
					{r,l} = macs(r,312640474,0,0);

					/* store filtered value */
					adc_filt[filt_chan] = r;

					/* update channel we are filtering and calculate buffer offset */
					if (filt_chan < ADC_CHANS-1) filt_chan += 1;
					else filt_chan = 0;
					filt_offset = filt_chan*ADC_FILT_SAMPLE_COUNT;

					/* insert new values */
					insert_pos = pos;
					#pragma loop unroll
					for (i=0; i < ADC_CHANS; i++)
					{
						adc_val[insert_pos] = adc_tmp[i];
						insert_pos += ADC_FILT_SAMPLE_COUNT;
					}

					/* logging */
#if 0
					if (log_flag == 1)
					{
						if (!isnull(c_logging0))
							c_logging0 <: adc_tmp[1]; // log channel ADC0
						if (!isnull(c_logging1))
							c_logging1 <: adc_tmp[2]; // log channel ADC1
					}
#endif

					/* update position */
					if (pos < ADC_FILT_SAMPLE_COUNT-1) pos += 1;
					else pos = 0;

					/* reset state machine to top */
					sample_count = 3;
					break;
				}


				break;
    	}
    }


}

