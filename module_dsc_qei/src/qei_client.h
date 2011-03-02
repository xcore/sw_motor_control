/**
 * Module:  module_dsc_qei
 * Version: 1v0alpha0
 * Build:   5436fb1843bebb6a68cd194ba182e8ad9506e264
 * File:    qei_client.h
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
#ifndef __QEI_CLIENT_H__
#define __QEI_CLIENT_H__

int get_qei_position ( chanend c_qei );

int get_qei_speed ( chanend c_qei );

int qei_pos_known ( chanend c_qei );

int qei_cw ( chanend c_qei );

#endif /* __QEI_CLIENT_H__ */
