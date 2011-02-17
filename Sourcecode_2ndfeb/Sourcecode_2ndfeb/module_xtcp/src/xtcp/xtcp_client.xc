/**
 * Module:  module_xtcp
 * Version: 2v0
 * Build:   bff4c572d34fec7e82e1e9d525d0b6585e034630
 * File:    xtcp_client.xc
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
#include <print.h>
#include <xccompat.h>
#include "xtcp_client.h"
#include "xtcp_cmd.h"

static void send_cmd(chanend c, xtcp_cmd_t cmd, int conn_id)
{
  outct(c, XTCP_CMD_TOKEN);
  chkct(c, XS1_CT_END);
  chkct(c, XS1_CT_END);
  outuint(c, cmd);
  outuint(c, conn_id);
  outct(c, XS1_CT_END);
  chkct(c, XS1_CT_END);  
}

void xtcp_listen(chanend tcp_svr, int port_number, xtcp_protocol_t p) {
  send_cmd(tcp_svr, XTCP_CMD_LISTEN, 0);
  master {
    tcp_svr <: port_number;
    tcp_svr <: p;
  }
}

void xtcp_unlisten(chanend tcp_svr, int port_number) {
  send_cmd(tcp_svr, XTCP_CMD_UNLISTEN, 0);
  master {
    tcp_svr <: port_number;
  }
}

void xtcp_connect(chanend tcp_svr, 
                  int port_number, 
                  xtcp_ipaddr_t ipaddr,
                  xtcp_protocol_t p)
{
  send_cmd(tcp_svr, XTCP_CMD_CONNECT, 0);
  master {
    tcp_svr <: port_number;
    for(int i=0;i<4;i++) 
      tcp_svr <: ipaddr[i];
    tcp_svr <: p;
  }
}

void xtcp_bind_local(chanend tcp_svr, xtcp_connection_t &conn, 
                     int port_number)
{
  send_cmd(tcp_svr, XTCP_CMD_BIND_LOCAL, conn.id);
  master {
    tcp_svr <: port_number;
  }
}

void xtcp_bind_remote(chanend tcp_svr, xtcp_connection_t &conn, 
                      xtcp_ipaddr_t addr, int port_number)
{
  send_cmd(tcp_svr, XTCP_CMD_BIND_REMOTE, conn.id);
  master {
    for (int i=0;i<4;i++)
      tcp_svr <: addr[i];
    tcp_svr <: port_number;
  }
}

#pragma unsafe arrays
transaction xtcp_event(chanend tcp_svr, xtcp_connection_t &conn)
{
  for(int i=0;i<sizeof(conn)>>2;i++) {
    tcp_svr :> (conn,unsigned int[])[i];  
  }
}

void do_xtcp_event(chanend tcp_svr, xtcp_connection_t &conn) {
  slave xtcp_event(tcp_svr, conn);
}

void xtcp_init_send(chanend tcp_svr,                    
                    REFERENCE_PARAM(xtcp_connection_t, conn))
{
  send_cmd(tcp_svr, XTCP_CMD_INIT_SEND, conn.id);
}

void xtcp_set_connection_appstate(chanend tcp_svr, 
                                  REFERENCE_PARAM(xtcp_connection_t, conn), 
                                  xtcp_appstate_t appstate)
{
  send_cmd(tcp_svr, XTCP_CMD_SET_APPSTATE, conn.id);
  master {
    tcp_svr <: appstate;
  }
}

void xtcp_close(chanend tcp_svr,
                REFERENCE_PARAM(xtcp_connection_t,conn)) 
{
  send_cmd(tcp_svr, XTCP_CMD_CLOSE, conn.id);
}

void xtcp_ack_recv(chanend tcp_svr,
                   REFERENCE_PARAM(xtcp_connection_t,conn)) 
{
  send_cmd(tcp_svr, XTCP_CMD_ACK_RECV, conn.id);
}

void xtcp_ack_recv_mode(chanend tcp_svr,
                        REFERENCE_PARAM(xtcp_connection_t,conn)) 
{
  send_cmd(tcp_svr, XTCP_CMD_ACK_RECV_MODE, conn.id);
}


void xtcp_abort(chanend tcp_svr,
                REFERENCE_PARAM(xtcp_connection_t,conn))
{
  send_cmd(tcp_svr, XTCP_CMD_ABORT, conn.id);
}



int xtcp_recvi(chanend tcp_svr, unsigned char data[], int index) 
{
  int len;
  slave {
    tcp_svr <: 1;
    tcp_svr :> len;
    for (int i=index;i<index+len;i++)
      tcp_svr :> data[i];
  }
  return len;
}

int xtcp_recv(chanend tcp_svr, unsigned char data[]) {
  return xtcp_recvi(tcp_svr, data, 0);
}


void xtcp_sendi(chanend tcp_svr,
                unsigned char ?data[],
                int index,
                int len)
{
  slave {
    tcp_svr <: len;
    for (int i=index;i<index+len;i++)
      tcp_svr <: data[i];
  }
}

void xtcp_send(chanend tcp_svr,
               unsigned char ?data[],
               int len)
{
  xtcp_sendi(tcp_svr, data, 0, len);
}

void xtcp_uint_to_ipaddr(xtcp_ipaddr_t ipaddr, unsigned int i) {
  ipaddr[0] = i & 0xff;
  i >>= 8;
  ipaddr[1] = i & 0xff;
  i >>= 8;
  ipaddr[2] = i & 0xff;
  i >>= 8;
  ipaddr[3] = i & 0xff;
}

void xtcp_set_poll_interval(chanend tcp_svr,
                            REFERENCE_PARAM(xtcp_connection_t, conn),
                            int poll_interval)
{
  send_cmd(tcp_svr, XTCP_CMD_SET_POLL_INTERVAL, conn.id);
  master {
    tcp_svr <: poll_interval;
  }
}

void xtcp_join_multicast_group(chanend tcp_svr,
                               xtcp_ipaddr_t addr)
{
  send_cmd(tcp_svr, XTCP_CMD_JOIN_GROUP, 0);
  master {
    tcp_svr <: addr[0];
    tcp_svr <: addr[1];
    tcp_svr <: addr[2];
    tcp_svr <: addr[3];
  }
}

void xtcp_leave_multicast_group(chanend tcp_svr,
                               xtcp_ipaddr_t addr)
{
  send_cmd(tcp_svr, XTCP_CMD_LEAVE_GROUP, 0);
  master {
    tcp_svr <: addr[0];
    tcp_svr <: addr[1];
    tcp_svr <: addr[2];
    tcp_svr <: addr[3];
  }
}

void xtcp_get_mac_address(chanend tcp_svr, unsigned char mac_addr[])
{
	send_cmd(tcp_svr, XTCP_CMD_GET_MAC_ADDRESS, 0);
	tcp_svr :> mac_addr[0];
	tcp_svr :> mac_addr[1];
	tcp_svr :> mac_addr[2];
	tcp_svr :> mac_addr[3];
	tcp_svr :> mac_addr[4];
	tcp_svr :> mac_addr[5];
}

void xtcp_get_ipconfig(chanend tcp_svr, 
                       xtcp_ipconfig_t &ipconfig)
{
  send_cmd(tcp_svr, XTCP_CMD_GET_IPCONFIG, 0);
  slave {
    tcp_svr :> ipconfig.ipaddr[0];
    tcp_svr :> ipconfig.ipaddr[1];
    tcp_svr :> ipconfig.ipaddr[2];
    tcp_svr :> ipconfig.ipaddr[3];
    tcp_svr :> ipconfig.netmask[0];
    tcp_svr :> ipconfig.netmask[1];
    tcp_svr :> ipconfig.netmask[2];
    tcp_svr :> ipconfig.netmask[3];
    tcp_svr :> ipconfig.gateway[0];
    tcp_svr :> ipconfig.gateway[1];
    tcp_svr :> ipconfig.gateway[2];
    tcp_svr :> ipconfig.gateway[3];
  }
}

extern inline void xtcp_complete_send(chanend c_xtcp);
