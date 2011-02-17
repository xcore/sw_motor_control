/**
 * Module:  module_xtcp
 * Version: 2v0
 * Build:   46357bd9ecd24c11524b8a5a484e4e77daaf167d
 * File:    xtcp_server_conf.h
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
#include "timer.h"

typedef struct xtcp_server_state_t {
  int send_request;
  int abort_request;
  int close_request;  
  int poll_interval;
  int connect_request;
  int closed;
  struct uip_timer tmr;
  int uip_conn;
  int ack_recv_mode;
} xtcp_server_state_t;
