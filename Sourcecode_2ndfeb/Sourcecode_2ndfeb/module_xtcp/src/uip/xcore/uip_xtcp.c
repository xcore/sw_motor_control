/**
 * Module:  module_xtcp
 * Version: 2v0
 * Build:   bff4c572d34fec7e82e1e9d525d0b6585e034630
 * File:    uip_xtcp.c
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
#include "uip.h"
#include "xtcp_client.h"
#include "xtcp_server.h"
#include "xtcp_server_impl.h"
#include "timer.h"
#include <print.h>
#include "dhcpc.h"
#include "igmp.h"
#include "uip_arp.h"

#define DHCPC_SERVER_PORT  67
#define DHCPC_CLIENT_PORT  68


#ifndef NULL
#define NULL ((void *) 0)
#endif

#define MAX_GUID 200
static int guid = 1;

static chanend *xtcp_links;
static int xtcp_num;

#define NUM_TCP_LISTENERS 10
#define NUM_UDP_LISTENERS 10

struct listener_info_t {
  int active;
  int port_number;
  int linknum;
};


static int prev_ifstate[MAX_XTCP_CLIENTS];
struct listener_info_t tcp_listeners[NUM_TCP_LISTENERS] = {{0}};
struct listener_info_t udp_listeners[NUM_UDP_LISTENERS] = {{0}};

static struct xtcpd_state_t  *lookup_xtcpd_state(int conn_id) {
  int i=0;
  for (i=0;i<UIP_CONNS;i++) {
    xtcpd_state_t *s = (xtcpd_state_t *) &(uip_conns[i].appstate);
    if (s->conn.id == conn_id) 
      return s;
  } 
  for (i=0;i<UIP_UDP_CONNS;i++) {
    xtcpd_state_t *s = (xtcpd_state_t *) &(uip_udp_conns[i].appstate);
    if (s->conn.id == conn_id) 
      return s;
  } 
  return NULL;
}


void xtcpd_init(chanend xtcp_links_init[], int n)
{
  int i;
  xtcp_links = xtcp_links_init;
  xtcp_num = n;
  for(i=0;i<MAX_XTCP_CLIENTS;i++)
    prev_ifstate[i] = -1;
  xtcpd_server_init();
}

static int get_listener_linknum(struct listener_info_t listeners[],
                                int n,
                                int local_port)
{
  int i, linknum = -1;
  for (i=0;i<n;i++)
    if (listeners[i].active && 
        local_port == listeners[i].port_number) {
      linknum = listeners[i].linknum;
      break;
    }
  return linknum;
}
                          

void xtcpd_init_state(xtcpd_state_t *s,
                      xtcp_protocol_t protocol,
                      xtcp_ipaddr_t remote_addr,
                      int local_port,
                      int remote_port,
                      void *conn) {
  int i;
  if (s->s.connect_request) {

  }
  else {
    s->conn.id = guid;
    s->conn.connection_type = XTCP_SERVER_CONNECTION;
    s->linknum = get_listener_linknum(tcp_listeners,
                                      NUM_TCP_LISTENERS,
                                      local_port);
  }
  
  
  s->conn.appstate = 0;
  s->conn.local_port = HTONS(local_port);
  s->conn.remote_port = HTONS(remote_port);
  s->conn.protocol = protocol;
  s->s.closed = 0;
  s->s.send_request = 0;
  s->s.close_request = 0;
  s->s.abort_request = 0;
  s->s.poll_interval = 0;
  s->s.connect_request = 0;
  s->s.ack_recv_mode = 0;
  s->s.uip_conn = (int) conn;
  for (i=0;i<4;i++)
    s->conn.remote_addr[i] = remote_addr[i];
  guid++;
  if (guid>MAX_GUID) 
    guid = 1;
}


static void xtcpd_event(xtcp_event_type_t event,
                        xtcpd_state_t *s)
{
  if (s->linknum != -1) {
    xtcpd_service_clients_until_ready(s->linknum, xtcp_links, xtcp_num);
    xtcpd_send_event(xtcp_links[s->linknum], event, s);
  }
}

static void unregister_listener(struct listener_info_t listeners[],
                                int linknum,
                                int port_number,
                                int n){
  
  int i;
  for (i=0;i<n;i++){
    if (listeners[i].port_number == HTONS(port_number) &&
        listeners[i].active)
      {
      listeners[i].active = 0;
      }
  }
}

static void register_listener(struct listener_info_t listeners[],
                              int linknum,
                              int port_number,
                              int n)
{
  int i;
    for (i=0;i<n;i++)
      if (!listeners[i].active)
        break;
    
    if (i==n) {
      printstr("Error: max number of listeners reached");
    }
    else {
      listeners[i].active = 1;
      listeners[i].port_number = HTONS(port_number);
      listeners[i].linknum = linknum;
    }
}

void xtcpd_unlisten(int linknum, int port_number){
	unregister_listener(tcp_listeners, linknum, port_number, NUM_TCP_LISTENERS);
	uip_unlisten(HTONS(port_number));
}

void xtcpd_listen(int linknum, int port_number, xtcp_protocol_t p)
{

  if (p == XTCP_PROTOCOL_TCP) {
    register_listener(tcp_listeners, linknum, port_number, NUM_TCP_LISTENERS);
    uip_listen(HTONS(port_number));    
  }
  else {
    uip_ipaddr_t addr;
    struct uip_udp_conn *conn;
    uip_ipaddr(addr, 255,255,255,255);
    conn = uip_udp_new(&addr, 0);
    if(conn != NULL)  {
      xtcpd_state_t *s = (xtcpd_state_t *) &(conn->appstate);
      //      printstr("Listen: ");
      //      printintln(conn);
      //      printintln(&s->s.poll_interval);
      uip_udp_bind(conn, HTONS(port_number));
      s->s.connect_request = 1;
      s->linknum = linknum;
      s->conn.connection_type = XTCP_SERVER_CONNECTION;
      s->conn.id = guid;
      guid++;
      if (guid>MAX_GUID) 
        guid = 1;

    }
  }
  //  printintln(uip_udp_conns[0].appstate.s.poll_interval);
  return;
}


void xtcpd_bind_local(int linknum, int conn_id, int port_number)
{
  xtcpd_state_t *s = lookup_xtcpd_state(conn_id);
  s->conn.local_port = port_number;
  if (s->conn.protocol == XTCP_PROTOCOL_UDP) 
    ((struct uip_udp_conn *) s->s.uip_conn)->lport = HTONS(port_number);    
  else 
    ((struct uip_conn *) s->s.uip_conn)->lport = HTONS(port_number);    
}

void xtcpd_bind_remote(int linknum, 
                       int conn_id, 
                       xtcp_ipaddr_t addr,
                       int port_number)
{
  xtcpd_state_t *s = lookup_xtcpd_state(conn_id);
  if (s->conn.protocol == XTCP_PROTOCOL_UDP) {
    struct uip_udp_conn *conn = (struct uip_udp_conn *) s->s.uip_conn;
    s->conn.remote_port = port_number;
    conn->rport = HTONS(port_number);    
    XTCP_IPADDR_CPY(s->conn.remote_addr, addr);
    conn->ripaddr[0] = (addr[1] << 8) | addr[0];
    conn->ripaddr[1] = (addr[3] << 8) | addr[2];
  }            
}

void xtcpd_connect(int linknum, int port_number, xtcp_ipaddr_t addr, 
                   xtcp_protocol_t p) {
  uip_ipaddr_t uipaddr;
  uip_ipaddr(uipaddr, addr[0], addr[1], addr[2], addr[3]);
  if (p == XTCP_PROTOCOL_TCP) {
    struct uip_conn *conn = uip_connect(&uipaddr, HTONS(port_number)); 
    if (conn != NULL) {
         xtcpd_state_t *s = (xtcpd_state_t *) &(conn->appstate);
         s->linknum = linknum;
         s->s.connect_request = 1;      
         s->conn.connection_type = XTCP_CLIENT_CONNECTION;
       }
  }
  else {
    struct uip_udp_conn *conn;
    conn = uip_udp_new(&uipaddr, HTONS(port_number));
    if (conn != NULL) {
      xtcpd_state_t *s = (xtcpd_state_t *) &(conn->appstate);
      s->linknum = linknum;
      s->s.connect_request = 1;      
      s->conn.connection_type = XTCP_CLIENT_CONNECTION;
    }
  }
  return;
}


void xtcpd_init_send(int linknum, int conn_id)
{
  xtcpd_state_t *s = lookup_xtcpd_state(conn_id);
  if (s != NULL) {
    s->s.send_request++;
  }
}


void xtcpd_set_appstate(int linknum, int conn_id, xtcp_appstate_t appstate)
{
  xtcpd_state_t *s = lookup_xtcpd_state(conn_id);
  if (s != NULL) {
    s->conn.appstate = appstate;
  }
}


void xtcpd_abort(int linknum, int conn_id)
{
  xtcpd_state_t *s = lookup_xtcpd_state(conn_id);
  if (s != NULL) {
    s->s.abort_request = 1;
  }
}

void xtcpd_close(int linknum, int conn_id)
{
  xtcpd_state_t *s = lookup_xtcpd_state(conn_id);
  if (s != NULL) {
    s->s.close_request = 1;
  }
}

void xtcpd_ack_recv_mode(int conn_id)
{
  xtcpd_state_t *s = lookup_xtcpd_state(conn_id);
  if (s != NULL) {
    s->s.ack_recv_mode = 1;
  }
}

void xtcpd_ack_recv(int conn_id)
{
  xtcpd_state_t *s = lookup_xtcpd_state(conn_id);
  if (s != NULL) {
    ((struct uip_conn *) s->s.uip_conn)->tcpstateflags &= ~UIP_STOPPED;
  }
}


static int needs_poll(xtcpd_state_t *s)
{
  return (s->s.connect_request | s->s.send_request | s->s.abort_request | s->s.close_request);
}

int uip_conn_needs_poll(struct uip_conn *uip_conn)
{
  xtcpd_state_t *s = (xtcpd_state_t *) &(uip_conn->appstate);
  return needs_poll(s);
}

int uip_udp_conn_needs_poll(struct uip_udp_conn *uip_udp_conn)
{
  xtcpd_state_t *s = (xtcpd_state_t *) &(uip_udp_conn->appstate);
  return needs_poll(s);
}

void uip_xtcpd_handle_poll(xtcpd_state_t *s)
{
 if (s->s.abort_request) {
    if (uip_udpconnection()) {
      uip_udp_conn->lport = 0;
      xtcpd_event(XTCP_CLOSED, s);    
    }
    else
      uip_abort();
    s->s.abort_request = 0;
  }
  else if (s->s.close_request) {
    if (uip_udpconnection()) {
      uip_udp_conn->lport = 0;
      xtcpd_event(XTCP_CLOSED, s);    
    }
    else
      uip_close();
    s->s.close_request = 0;
  }
  else
  if (s->s.connect_request) {    
    if (uip_udpconnection()) {   
      //      printstr("Connect: ");
      //      printintln(uip_udp_conn);
      xtcpd_init_state(s,
                       XTCP_PROTOCOL_UDP,
                       (unsigned char *) uip_udp_conn->ripaddr,
                       uip_udp_conn->lport,
                       uip_udp_conn->rport,
                       uip_udp_conn);   
      xtcpd_event(XTCP_NEW_CONNECTION, s);
      s->s.connect_request = 0;
    }
  }
  else if (s->s.send_request) {
    int len;
    if (s->linknum != -1) {
      xtcpd_service_clients_until_ready(s->linknum, xtcp_links, xtcp_num);
      len = xtcpd_send(xtcp_links[s->linknum], 
                       XTCP_REQUEST_DATA,
                       s, 
                       uip_appdata,
                       uip_udpconnection() ? XTCP_CLIENT_BUF_SIZE : uip_mss());
      uip_send(uip_appdata, len);
    }
    s->s.send_request--;
  }      
  else if (s->s.poll_interval != 0 &&
           timer_expired(&(s->s.tmr)))
    {
      xtcpd_event(XTCP_POLL, s);
      timer_set(&(s->s.tmr), s->s.poll_interval);
    }
}



#define BUF ((struct uip_tcpip_hdr *)&uip_buf[UIP_LLH_LEN])
#define FBUF ((struct uip_tcpip_hdr *)&uip_reassbuf[0])
#define ICMPBUF ((struct uip_icmpip_hdr *)&uip_buf[UIP_LLH_LEN])
#define UDPBUF ((struct uip_udpip_hdr *)&uip_buf[UIP_LLH_LEN])

void 
xtcpd_appcall(void)
{
  xtcpd_state_t *s;
  
  if (uip_udpconnection() &&
      (uip_udp_conn->lport == HTONS(DHCPC_CLIENT_PORT) ||
       uip_udp_conn->lport == HTONS(DHCPC_SERVER_PORT))) {   
    dhcpc_appcall();
    return;
  }

  if (uip_udpconnection()){
    s = (xtcpd_state_t *) &(uip_udp_conn->appstate);
    if (uip_newdata()) {
      s->conn.remote_port = HTONS(UDPBUF->srcport);
      uip_ipaddr_copy(s->conn.remote_addr, BUF->srcipaddr);
    }
  }
  else
    if (uip_conn == NULL) {
      printstr("dodgy uip_conn");
      return;
    }
    else
      s = (xtcpd_state_t *) &(uip_conn->appstate);

  
  

  if (!uip_udpconnection() && uip_connected()) {
    xtcpd_init_state(s,
                     XTCP_PROTOCOL_TCP,
                     (unsigned char *) uip_conn->ripaddr,
                     uip_conn->lport,
                     uip_conn->rport,
                     uip_conn);
    xtcpd_event(XTCP_NEW_CONNECTION, s);
  }
  
  if (uip_acked()) {
    int len;
    if (s->linknum != -1) {
      xtcpd_service_clients_until_ready(s->linknum, xtcp_links, xtcp_num);
      len = xtcpd_send(xtcp_links[s->linknum], 
                       XTCP_SENT_DATA, 
                       s, 
                       uip_appdata,
                       uip_udpconnection() ? XTCP_CLIENT_BUF_SIZE : uip_mss());
      if (len != 0)
        uip_send(uip_appdata, len);
    }
  }  
  
    if (uip_newdata() && uip_len > 0) {
    if (s->linknum != -1) {
      if (!uip_udpconnection() && s->s.ack_recv_mode) {
        uip_stop();
      }      
      xtcpd_service_clients_until_ready(s->linknum, xtcp_links, xtcp_num);
      xtcpd_recv(xtcp_links, s->linknum, xtcp_num,
                 s, 
                 uip_appdata, 
                 uip_datalen());
    }

  }
  
  else if (uip_aborted()) {
    xtcpd_event(XTCP_ABORTED, s);
    return;
  } 
  else if (uip_timedout()) {
    xtcpd_event(XTCP_TIMED_OUT, s);
    return;
  }
  
  if (uip_rexmit()) {
    int len;
    if (s->linknum != -1) {
      xtcpd_service_clients_until_ready(s->linknum, xtcp_links, xtcp_num);    
      len = xtcpd_send(xtcp_links[s->linknum], 
                       XTCP_RESEND_DATA, 
                       s, 
                       uip_appdata,
                       uip_udpconnection() ? XTCP_CLIENT_BUF_SIZE : uip_mss());
      if (len != 0)
        uip_send(uip_appdata, len);
    }    
  }

  if (uip_poll()) {
    uip_xtcpd_handle_poll(s);
  }  
  
  if (uip_closed()) {
    if (!s->s.closed){
      s->s.closed = 1;

      xtcpd_event(XTCP_CLOSED, s);
    }
    return;
  }

}

static int uip_ifstate = 0;


void xtcpd_get_ipconfig(xtcp_ipconfig_t *ipconfig) 
{
  ipconfig->ipaddr[0] = uip_ipaddr1(uip_hostaddr);
  ipconfig->ipaddr[1] = uip_ipaddr2(uip_hostaddr);
  ipconfig->ipaddr[2] = uip_ipaddr3(uip_hostaddr);
  ipconfig->ipaddr[3] = uip_ipaddr4(uip_hostaddr);
  ipconfig->netmask[0] = uip_ipaddr1(uip_netmask);
  ipconfig->netmask[1] = uip_ipaddr2(uip_netmask);
  ipconfig->netmask[2] = uip_ipaddr3(uip_netmask);
  ipconfig->netmask[3] = uip_ipaddr4(uip_netmask);
  ipconfig->gateway[0] = uip_ipaddr1(uip_draddr);
  ipconfig->gateway[1] = uip_ipaddr2(uip_draddr);
  ipconfig->gateway[2] = uip_ipaddr3(uip_draddr);
  ipconfig->gateway[3] = uip_ipaddr4(uip_draddr);  
}

void uip_xtcpd_send_config(int linknum)
{
  if (uip_ifstate) {
    xtcpd_queue_event(xtcp_links[linknum], linknum, XTCP_IFUP);
  }
  else {
    xtcpd_queue_event(xtcp_links[linknum], linknum, XTCP_IFDOWN);
  }
}


void uip_xtcp_checkstate() 
{
  int i;

  for (i=0;i<xtcp_num;i++) {
    if (uip_ifstate != prev_ifstate[i]) {
      uip_xtcpd_send_config(i);
      prev_ifstate[i] = uip_ifstate;
    }
  }
  
}


void uip_xtcp_up() {
  uip_ifstate = 1;
}

void uip_xtcp_down() {
  uip_ifstate = 0;
}

                         
int get_uip_xtcp_ifstate() 
{
  return uip_ifstate;
}


void xtcpd_set_poll_interval(int linknum, int conn_id, int poll_interval)
{
  xtcpd_state_t *s = lookup_xtcpd_state(conn_id);
  if (s != NULL && s->conn.protocol == XTCP_PROTOCOL_UDP) {
    s->s.poll_interval = poll_interval;
    timer_set(&(s->s.tmr), poll_interval * CLOCK_SECOND/1000);
  }
}

void xtcpd_join_group(xtcp_ipaddr_t addr)
{
  uip_ipaddr_t ipaddr;
  uip_ipaddr(ipaddr, addr[0], addr[1], addr[2], addr[3]);
  igmp_join_group(ipaddr);
}

void xtcpd_leave_group(xtcp_ipaddr_t addr)
{
  uip_ipaddr_t ipaddr;
  uip_ipaddr(ipaddr, addr[0], addr[1], addr[2], addr[3]);
  igmp_leave_group(ipaddr);
}

void xtcpd_get_mac_address(unsigned char mac_addr[]){
  mac_addr[0] = uip_ethaddr.addr[0];
  mac_addr[1] = uip_ethaddr.addr[1];
  mac_addr[2] = uip_ethaddr.addr[2];
  mac_addr[3] = uip_ethaddr.addr[3];
  mac_addr[4] = uip_ethaddr.addr[4];
  mac_addr[5] = uip_ethaddr.addr[5];
}
