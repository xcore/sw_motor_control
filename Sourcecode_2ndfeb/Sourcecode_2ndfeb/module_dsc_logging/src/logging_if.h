/**
 * Module:  module_dsc_logging
 * Version: 1v0alpha0
 * Build:   5d6686afecb5db37cdac3b154d9bbbf21c03d5ff
 * File:    logging_if.h
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
#ifndef __LOGGING_IF_H__
#define __LOGGING_IF_H__

	void logging_server( chanend c_sdram, chanend c_logging_data, chanend c_data_read );
	void logging_concentrator( chanend data_out, chanend c_outer_loop, chanend c_inner_loop );

#endif /* __LOGGING_IF_H__ */
