/**
 * Module:  module_ethernet
 * Version: 1v3
 * Build:   de8861aed4ba040f8c4c57c33c74360088e4a8bf
 * File:    mii_filter.h
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
void one_port_filter(mii_packet_t buf[],
                     const int mac[2],
                     REFERENCE_PARAM(mii_queue_t, free_queue),
                     REFERENCE_PARAM(mii_queue_t, internal_q),
                     streaming chanend c);

void two_port_filter(mii_packet_t buf[],
                     const int mac[2],
                     REFERENCE_PARAM(mii_queue_t,free_q),
                     REFERENCE_PARAM(mii_queue_t,internal_q),
                     REFERENCE_PARAM(mii_queue_t,q1),
                     REFERENCE_PARAM(mii_queue_t,q2),
                     streaming chanend c0,
                     streaming chanend c1);

