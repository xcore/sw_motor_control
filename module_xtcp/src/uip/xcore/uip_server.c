/**
 * Module:  module_xtcp
 * Version: 2v0
 * Build:   03fa26971a2e68b5caa9b9c38fc25323889e8b85
 * File:    uip_server.c
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
#include <print.h>
#include <xccompat.h>
#include <string.h>
#include "uip.h"
#include "uip_arp.h"
#include "uip-split.h"
#include "xcoredev.h"
#include "xtcp_server.h"
#include "timer.h"
#include "uip_server.h"
#include "ethernet_rx_client.h"
#include "ethernet_tx_client.h"
#include "uip_xtcp.h"
#include "autoip.h"
#include "igmp.h"


int uip_conn_needs_poll(struct uip_conn *uip_conn);
int uip_udp_conn_needs_poll(struct uip_udp_conn *uip_udp_conn);


#define BUF ((struct uip_eth_hdr *)&uip_buf[0])

/* Make sure that the uip_buf is word aligned */
unsigned int uip_buf32[(UIP_BUFSIZE + 5)>>2];
u8_t *uip_buf = (u8_t *) &uip_buf32[0];

static void send(chanend mac_tx) {
   uip_split_output(mac_tx);
   uip_len = 0;
}

void
uip_log(char *m)
{
  printstr("uIP log message: ");
  printstr(m);
  printstr("\n");
}


static int static_ip = 0;
static xtcp_ipconfig_t static_ipconfig;

void
uip_server(chanend mac_rx, chanend mac_tx, chanend xtcp[], int num_xtcp,
           xtcp_ipconfig_t *ipconfig, chanend connect_status)
{
  int i;
  uip_ipaddr_t ipaddr;
  struct uip_timer 
    periodic_timer, arp_timer, autoip_timer,
    igmp_timer;
  struct uip_eth_addr hwaddr;

  if (ipconfig != NULL)
    memcpy(&static_ipconfig, ipconfig, sizeof(xtcp_ipconfig_t));

  timer_set(&periodic_timer, CLOCK_SECOND / 10);
  timer_set(&autoip_timer, CLOCK_SECOND / 2);
  timer_set(&igmp_timer, CLOCK_SECOND / 10); 
  timer_set(&arp_timer, CLOCK_SECOND * 10);
  
  mac_get_macaddr(mac_tx, hwaddr.addr);
  uip_setethaddr(hwaddr);


  xcoredev_init(mac_rx, mac_tx);
  uip_init();
#if UIP_IGMP
  igmp_init();
#endif
  if (ipconfig != NULL && (ipconfig->ipaddr[0] != 0 ||
                           ipconfig->ipaddr[1] != 0 ||
                           ipconfig->ipaddr[2] != 0 ||
                           ipconfig->ipaddr[3] != 0))
    {  
      //      uip_xtcp_up();
      static_ip = 1;
      printstr("Using static ip\n");
    }
  else 
    printstr("Using dynamic ip\n");
  
  if (ipconfig == NULL)
    uip_ipaddr(ipaddr, 0, 0, 0, 0);

  if (ipconfig != NULL)
    uip_ipaddr(ipaddr, 
               ipconfig->ipaddr[0],
               ipconfig->ipaddr[1],
               ipconfig->ipaddr[2],
               ipconfig->ipaddr[3]);
  uip_sethostaddr(ipaddr);
  
  if (ipconfig != NULL)
    uip_ipaddr(ipaddr, 
               ipconfig->gateway[0],
               ipconfig->gateway[1],
               ipconfig->gateway[2],
               ipconfig->gateway[3]);
  uip_setdraddr(ipaddr);

  if (ipconfig != NULL)
    uip_ipaddr(ipaddr, 
               ipconfig->netmask[0],
               ipconfig->netmask[1],
               ipconfig->netmask[2],
               ipconfig->netmask[3]);
  uip_setnetmask(ipaddr);
  
  { int hwsum = 
      hwaddr.addr[0] +
      hwaddr.addr[1] +
      hwaddr.addr[2] +
      hwaddr.addr[3] +
      hwaddr.addr[4] +
      hwaddr.addr[5];
    autoip_init(hwsum + (hwsum << 16) + (hwsum << 24));
    dhcpc_init(&(hwaddr.addr), 6);   
    xtcpd_init(xtcp, num_xtcp);
  }
  
  while(1) {
    xtcpd_service_clients(xtcp, num_xtcp);    

    for(i=0;i<UIP_CONNS;i++) {
      if (uip_conn_needs_poll(&uip_conns[i])) {
        uip_poll_conn(&uip_conns[i]);
        if(uip_len > 0) {
          uip_arp_out(NULL);
          send(mac_tx);
        }  
      }
    }
    
    for(i=0;i<UIP_UDP_CONNS;i++) {
      if (uip_udp_conn_needs_poll(&uip_udp_conns[i])) {
	uip_udp_periodic(i);
        if(uip_len > 0) {
          uip_arp_out(&uip_udp_conns[i]);
          send(mac_tx);
        }          
      }
    }

    uip_xtcp_checkstate();
    uip_xtcp_checklink(connect_status);
    uip_len = xcoredev_read(mac_rx, UIP_CONF_BUFFER_SIZE);
    if(uip_len > 0) {
      if(BUF->type == htons(UIP_ETHTYPE_IP)) {
	uip_arp_ipin();
	uip_input();
	if(uip_len > 0) {
          if (uip_udpconnection()) 
            uip_arp_out(uip_udp_conn);          
          else 
            uip_arp_out(NULL);
	  send(mac_tx);
	}
      } else if(BUF->type == htons(UIP_ETHTYPE_ARP)) {
	uip_arp_arpin();

	if(uip_len > 0) {
	  send(mac_tx);
	}
        for(i = 0; i < UIP_UDP_CONNS; i++) {
          uip_udp_arp_event(i);
          if(uip_len > 0) {
            uip_arp_out(&uip_udp_conns[i]);
            send(mac_tx);
          }
        }
      }
    }

    for(i=0;i<UIP_UDP_CONNS;i++) {
      if (uip_udp_conn_has_ack(&uip_udp_conns[i])) {
	uip_udp_ackdata(i);
        if(uip_len > 0) {
          uip_arp_out(&uip_udp_conns[i]);
          send(mac_tx);
        }          
      }
    }


    if(timer_expired(&arp_timer)) {
      timer_reset(&arp_timer);
      uip_arp_timer();
    }  

    if(timer_expired(&autoip_timer)) {
      timer_reset(&autoip_timer);
      autoip_periodic();
      if(uip_len > 0) {
        send(mac_tx);        
      }      
    }  

#if UIP_IGMP
    if(timer_expired(&igmp_timer)) {
      timer_reset(&igmp_timer);
      igmp_periodic();
      if(uip_len > 0) {
        send(mac_tx);
      }      
    }  
#endif

    if (timer_expired(&periodic_timer)) {
      
      for(i = 0;i<UIP_UDP_CONNS;i++) {       
	uip_udp_periodic(i);
	if(uip_len > 0) {
	  uip_arp_out(&uip_udp_conns[i]);
	  send(mac_tx);
	}
      }

      for(i=0;i<UIP_CONNS;i++) {
	uip_periodic(i);
	if(uip_len > 0) {
	  uip_arp_out(NULL);
	  send(mac_tx);
	}
      }

      timer_reset(&periodic_timer);      
    }


  }
  return;
}


static int dhcp_done = 0;

void
dhcpc_configured(const struct dhcpc_state *s)
{
  printstr("dhcp configured\n");
  printint(uip_ipaddr1(s->ipaddr));
  printstr(".");
  printint(uip_ipaddr2(s->ipaddr));
  printstr(".");
  printint(uip_ipaddr3(s->ipaddr));
  printstr(".");
  printint(uip_ipaddr4(s->ipaddr));
  printstr("\n");
  autoip_stop();
  uip_sethostaddr(s->ipaddr);
  uip_setdraddr(s->default_router);
  uip_setnetmask(s->netmask);
  uip_xtcp_up();
  dhcp_done = 1;
}



void autoip_configured(uip_ipaddr_t autoip_ipaddr)
{
  if (!dhcp_done) {
    uip_ipaddr_t ipaddr;
    printstr("ipv4ll: ");
    printint(uip_ipaddr1(autoip_ipaddr));
    printstr(".");
    printint(uip_ipaddr2(autoip_ipaddr));
    printstr(".");
    printint(uip_ipaddr3(autoip_ipaddr));
    printstr(".");
    printint(uip_ipaddr4(autoip_ipaddr));
    printstr("\n");
    uip_sethostaddr(autoip_ipaddr);
    uip_ipaddr(ipaddr,255,255,0,0);
    uip_setnetmask(ipaddr);
    uip_ipaddr(ipaddr,0,0,0,0);
    uip_setdraddr(ipaddr);
    uip_xtcp_up();
  }
}

void uip_linkup() {
  if (get_uip_xtcp_ifstate())
    uip_xtcp_down();
  
  if (static_ip) {
    uip_ipaddr_t ipaddr;
    uip_ipaddr(ipaddr, 
               static_ipconfig.ipaddr[0],
               static_ipconfig.ipaddr[1],
               static_ipconfig.ipaddr[2],
               static_ipconfig.ipaddr[3]);
    uip_sethostaddr(ipaddr);
    uip_ipaddr(ipaddr, 
               static_ipconfig.gateway[0],
               static_ipconfig.gateway[1],
               static_ipconfig.gateway[2],
               static_ipconfig.gateway[3]);
    uip_setdraddr(ipaddr);
    uip_ipaddr(ipaddr, 
               static_ipconfig.netmask[0],
               static_ipconfig.netmask[1],
               static_ipconfig.netmask[2],
               static_ipconfig.netmask[3]);
    uip_setnetmask(ipaddr);   
    uip_xtcp_up();
  }
  else {
    printstr("link up\n");
    dhcp_done = 0;
    dhcpc_stop();
    autoip_stop();
    dhcpc_start();
  }
}

void uip_linkdown() {
  dhcp_done = 0;
  dhcpc_stop();
  autoip_stop();
  uip_xtcp_down();
}
