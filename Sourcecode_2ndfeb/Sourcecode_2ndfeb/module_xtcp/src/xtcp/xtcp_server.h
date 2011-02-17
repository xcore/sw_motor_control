/**
 * Module:  module_xtcp
 * Version: 2v0
 * Build:   044a13030cb0b50e28a3be24f98bad85fa8837fd
 * File:    xtcp_server.h
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
#ifndef __xtcp_server_h__ 
#define __xtcp_server_h__ 
#include <xccompat.h>
#include "xtcp_client.h"
#include "xtcp_server_conf.h"

#define MAX_XTCP_CLIENTS 10

typedef struct xtcpd_state_t {
  unsigned int linknum;
  xtcp_connection_t conn;
  xtcp_server_state_t s;
} xtcpd_state_t;


void xtcpd_init(chanend xtcp[], int num_xtcp);

void xtcpd_send_event(chanend c, xtcp_event_type_t event, 
                      REFERENCE_PARAM(xtcpd_state_t, s));

void xtcpd_send_null_event(chanend c);

void xtcpd_service_clients(chanend xtcp[], int num_xtcp);
void xtcpd_service_clients_until_ready(int waiting_link,
                                       chanend xtcp[], 
                                       int num_xtcp);

void xtcpd_recv(chanend xtcp[],
                int linknum,
                int num_xtcp,
                REFERENCE_PARAM(xtcpd_state_t, s),
                unsigned char data[],
                int datalen);

int xtcpd_send(chanend c, 
               xtcp_event_type_t event,
               REFERENCE_PARAM(xtcpd_state_t, s),
               unsigned char data[],
               int mss);

void xtcpd_get_mac_address(unsigned char []);

void xtcpd_server_init(void);

void xtcpd_queue_event(chanend c, int linknum, int event);
#endif
