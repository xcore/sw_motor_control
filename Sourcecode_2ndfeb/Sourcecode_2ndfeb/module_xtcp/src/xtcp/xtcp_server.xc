/**
 * Module:  module_xtcp
 * Version: 2v0
 * Build:   bff4c572d34fec7e82e1e9d525d0b6585e034630
 * File:    xtcp_server.xc
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
#include "xtcp_cmd.h"
#include "xtcp_client.h"
#include "xtcp_server.h"
#include "xtcp_server_impl.h"

static int notified[MAX_XTCP_CLIENTS];
static int pending_event[MAX_XTCP_CLIENTS];

static xtcp_connection_t dummy_conn;

static void handle_xtcp_cmd(chanend c,
                            int i,
                            xtcp_cmd_t cmd,
                            int conn_id)
{
  switch (cmd) 
    {
    case XTCP_CMD_LISTEN: {
      int port_number;
      xtcp_protocol_t protocol;
      slave {
        c :> port_number;
        c :> protocol;
      }
      xtcpd_listen(i, port_number, protocol);
      break;
    }
    case XTCP_CMD_UNLISTEN: {
      int port_number;
      slave {
        c :> port_number;
      }
      xtcpd_unlisten(i, port_number);
      break;
    }
    case XTCP_CMD_CONNECT: {
      int port_number;
      xtcp_ipaddr_t ipaddr;
      xtcp_protocol_t protocol;
      slave {        
        c :> port_number;
        for (int j=0;j<4;j++)
          c :> ipaddr[j];
        c :> protocol;
        xtcpd_connect(i, port_number, ipaddr, protocol);
      }
      break;
    }
    case XTCP_CMD_BIND_REMOTE : {
      xtcp_ipaddr_t ipaddr;
      int port_number;
      slave {
        for (int j=0;j<4;j++)
          c :> ipaddr[j];
        c :> port_number;
      }
      xtcpd_bind_remote(i, conn_id, ipaddr, port_number);
      break;
    }
    case XTCP_CMD_BIND_LOCAL : {
      int port_number;
      slave {
        c :> port_number;
      }
      xtcpd_bind_local(i, conn_id, port_number);
      break;
    }
    case XTCP_CMD_INIT_SEND: 
      xtcpd_init_send(i, conn_id);
      break;    
    case XTCP_CMD_SET_APPSTATE: {
      xtcp_appstate_t appstate;
      slave {
        c :> appstate;
      }
      xtcpd_set_appstate(i, conn_id, appstate);
      break;
    }
    case XTCP_CMD_ABORT:
      xtcpd_abort(i, conn_id);
      break;
    case XTCP_CMD_CLOSE: 
      xtcpd_close(i, conn_id);
      break;
    case XTCP_CMD_SET_POLL_INTERVAL: {
      int poll_interval;
      slave {
        c :> poll_interval;
      }
      xtcpd_set_poll_interval(i, conn_id, poll_interval);
      }
      break;
    case XTCP_CMD_JOIN_GROUP: {
      xtcp_ipaddr_t ipaddr;
      slave {
        c :> ipaddr[0];
        c :> ipaddr[1];
        c :> ipaddr[2];
        c :> ipaddr[3];
      }
      xtcpd_join_group(ipaddr);
      }
      break;
    case XTCP_CMD_LEAVE_GROUP: {
      xtcp_ipaddr_t ipaddr;
      slave {
        c :> ipaddr[0];
        c :> ipaddr[1];
        c :> ipaddr[2];
        c :> ipaddr[3];
      }
      xtcpd_leave_group(ipaddr);
      }
      break;    
    case XTCP_CMD_GET_MAC_ADDRESS: 
      {
        unsigned char mac_addr[6];
        xtcpd_get_mac_address(mac_addr);
        c <: mac_addr[0];
        c <: mac_addr[1];
        c <: mac_addr[2];
        c <: mac_addr[3];
        c <: mac_addr[4];
        c <: mac_addr[5];
      }
      break;
    case XTCP_CMD_GET_IPCONFIG: 
      {        
        xtcp_ipconfig_t ipconfig;
        xtcpd_get_ipconfig(ipconfig);
        master {
          for (int i=0;i<4;i++) 
            c <: ipconfig.ipaddr[i];
          
          for (int i=0;i<4;i++)
            c <: ipconfig.netmask[i];

          for (int i=0;i<4;i++)
            c <: ipconfig.gateway[i];
        }
      }
      break;
    case XTCP_CMD_ACK_RECV:
      xtcpd_ack_recv(conn_id);      
      break;
    case XTCP_CMD_ACK_RECV_MODE:     
      xtcpd_ack_recv_mode(conn_id);      
      break;
    }
}




static void send_conn_and_complete(chanend c, 
                                   xtcp_connection_t &conn)
{
  #pragma unsafe arrays
  for(int i=0;i<sizeof(conn)>>2;i++) {
    outuint(c, (conn,unsigned int[])[i]);
  }
  outct(c, XS1_CT_END);
  chkct(c, XS1_CT_END);
}

int xtcpd_service_client0(chanend xtcp, int i, int waiting_link)
{
  int activity = 1;
  unsigned char tok;
  unsigned int cmd;
  unsigned int conn_id;
  select 
      {
      case inct_byref(xtcp, tok):
        if (tok == XS1_CT_END) {
          // the other side has responded to the transaction
          notified[i] = 0;
          if (pending_event[i] != -1) {
            dummy_conn.event = pending_event[i];
            
            send_conn_and_complete(xtcp, dummy_conn);
            pending_event[i] = -1;
            if (i==waiting_link) {
              outct(xtcp, XS1_CT_END);
              notified[i] = 1;
            }
          }          
        }
        else {
          outct(xtcp, XS1_CT_END);
          if (!notified[i])
            outct(xtcp, XS1_CT_END);
          cmd = inuint(xtcp);
          conn_id = inuint(xtcp);
          chkct(xtcp, XS1_CT_END);
          outct(xtcp, XS1_CT_END);
          handle_xtcp_cmd(xtcp, i, cmd, conn_id);
          if (notified[i]) 
            outct(xtcp, XS1_CT_END);
        }
        break;
      default:
        activity = 0;
        break;
      }
  return activity;
}

void xtcpd_service_clients(chanend xtcp[], int num_xtcp){
    int activity = 1;
    while (activity) {
      activity = 0;
      for (int i=0;i<num_xtcp;i++)
        activity |= xtcpd_service_client0(xtcp[i], i, -1);
      
  }	
}

void xtcpd_service_clients_until_ready(int waiting_link,
                                       chanend xtcp[], 
                                       int num_xtcp)
{
  if (!notified[waiting_link]) {
    outct(xtcp[waiting_link], XS1_CT_END);
    notified[waiting_link] = 1;
  }
  while (notified[waiting_link]) {
    for (int i=0;i<num_xtcp;i++)
      xtcpd_service_client0(xtcp[i], i, waiting_link);	 	
  }	
}



void xtcpd_send_event(chanend c,
                      xtcp_event_type_t event,
                      xtcpd_state_t &s)
{
  s.conn.event = event;
  send_conn_and_complete(c, s.conn);
}

#pragma unsafe arrays
void xtcpd_recv(chanend xtcp[],
                int linknum,
                int num_xtcp,
                xtcpd_state_t &s,
                unsigned char data[],
                int datalen)
{
  int client_ready = 0;
  if (linknum != 0){
	  client_ready = 0;
  }

  do {
    s.conn.event = XTCP_RECV_DATA;
    send_conn_and_complete(xtcp[linknum], s.conn);
    master {
      xtcp[linknum] :> client_ready;
      if (client_ready) {
        xtcp[linknum] <: datalen;
        for (int i=0;i<datalen;i++)
          xtcp[linknum] <: data[i];
      }
    }
    if (!client_ready) {
      xtcpd_service_clients_until_ready(linknum, xtcp, num_xtcp);      
    }
  } while (!client_ready);

  return;
}


int xtcpd_send(chanend c,        
               xtcp_event_type_t event,
               xtcpd_state_t &s,
               unsigned char data[],
               int mss)
{
  int len;
  s.conn.event = event;
  s.conn.mss = mss;
  send_conn_and_complete(c, s.conn);
  master {
    c :> len;
    for (int i=0;i<len;i++)
      c :> data[i];
  }
  return len;
}

#if XTCP_SUPPORT_DEPRECATED_1V3_FEATURES
void xtcpd_send_config_event(chanend c, 
                             xtcp_config_event_t event,
                             xtcp_ipconfig_t &ipconfig)
{
  master {
    //    c <: XTCP_CONFIG_EVENT;
    c <: event;
    c <: ipconfig;
  }
}
#endif



void xtcpd_server_init() {
  for (int i=0;i<MAX_XTCP_CLIENTS;i++) {
    notified[i] = 0;
    pending_event[i] = -1;
  }
}

void xtcpd_queue_event(chanend c, int linknum, int event)
{
  pending_event[linknum] = event;
  if (!notified[linknum]) {
    outct(c, XS1_CT_END);
    notified[linknum] = 1;
  }
  return;
}
