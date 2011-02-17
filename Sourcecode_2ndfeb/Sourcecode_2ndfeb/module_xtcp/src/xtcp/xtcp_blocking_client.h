/**
 * Module:  module_xtcp
 * Version: 2v0
 * Build:   044a13030cb0b50e28a3be24f98bad85fa8837fd
 * File:    xtcp_blocking_client.h
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
#ifndef _xtcp_blocking_client_h_
#define _xtcp_blocking_client_h_

void xtcp_wait_for_ifup(chanend tcp_svr);

xtcp_connection_t 
xtcp_wait_for_connection(chanend tcp_svr);

int xtcp_write(chanend tcp_svr, 
               REFERENCE_PARAM(xtcp_connection_t, conn),
               unsigned char buf[],
               int len);

int xtcp_read(chanend tcp_svr, 
              REFERENCE_PARAM(xtcp_connection_t, conn),
              unsigned char buf[],
              int minlen);

#endif
