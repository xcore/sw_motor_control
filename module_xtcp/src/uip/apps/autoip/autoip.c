/**
 * Module:  module_xtcp
 * Version: 1v3
 * Build:   44b99e7cf03c809c736b69d6c73c1a796cb47676
 * File:    autoip.c
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
#include "autoip.h"
#include "uip_arp.h"
#include "timer.h"
#include "clock-arch.h"
#include <print.h>
#include <string.h>

struct arp_hdr {
  struct uip_eth_hdr ethhdr;
  u16_t hwtype;
  u16_t protocol;
  u8_t hwlen;
  u8_t protolen;
  u16_t opcode;
  struct uip_eth_addr shwaddr;
  u16_t sipaddr[2];
  struct uip_eth_addr dhwaddr;
  u16_t dipaddr[2];
};

struct ethip_hdr {
  struct uip_eth_hdr ethhdr;
  /* IP header. */
  u8_t vhl,
    tos,
    len[2],
    ipid[2],
    ipoffset[2],
    ttl,
    proto;
  u16_t ipchksum;
  u16_t srcipaddr[2],
    destipaddr[2];
};

#define ARP_REQUEST 1
#define ARP_REPLY   2

#define ARP_HWTYPE_ETH 1

// Values taken from RFC 3927

#define PROBE_WAIT           1  // second   (initial random delay)
#define PROBE_NUM            3  //          (number of probe packets)
#define PROBE_MIN            1  // second   (minimum delay till repeated probe)
#define PROBE_MAX            2  // seconds  (maximum delay till repeated probe)
#define ANNOUNCE_WAIT        2  // seconds  (delay before announcing)
#define ANNOUNCE_NUM         2  //          (number of announcement packets)
#define ANNOUNCE_INTERVAL    2  // seconds  (time between announcement packets)
#define MAX_CONFLICTS       10  //          (max conflicts before rate limiting)
#define RATE_LIMIT_INTERVAL 60  // seconds  (delay between successive attempts)
#define DEFEND_INTERVAL     10  // seconds  (minimum interval between defensive
                                //           ARPs).
enum autoip_machine_state {
  DISABLED,
  NO_ADDRESS,
  WAIT_FOR_PROBE,
  PROBING,
  WAIT_FOR_ANNOUNCE,
  ANNOUNCING,
  CONFIGURED
};

struct autoip_state_t {
  enum autoip_machine_state state;
  int probes_sent;
  int announces_sent;
  int num_conflicts;
  int limit_rate;
  unsigned int rand;
  unsigned int seed;
  struct uip_timer timer;
  uip_ipaddr_t ipaddr;
};

#define BUF   ((struct arp_hdr *)&uip_buf[0])

static unsigned int a=1664525;
static unsigned int c=1013904223;

#define RAND(x) do {x = a*x+c;} while (0)

static struct autoip_state_t my_autoip_state;

static struct autoip_state_t *autoip_state = &my_autoip_state;

void autoip_init(int seed) 
{
  autoip_state->state = DISABLED;
  autoip_state->probes_sent = 0;
  autoip_state->announces_sent = 0;
  autoip_state->num_conflicts = 0;
  autoip_state->limit_rate = 0;  
  autoip_state->seed = seed;
  autoip_state->rand = seed;
}

static void random_timer_set(struct uip_timer *t,
                      int a,
                      int b)
{ 
  long long x;
  RAND(autoip_state->rand);
  x = autoip_state->rand * (b-a);
  x = x >> 32;
  timer_set(t, a + x);
}                     

static void create_arp_packet() 
{
  memset(BUF->ethhdr.dest.addr, 0xff, 6);
  memset(BUF->dhwaddr.addr, 0x00, 6);
  memcpy(BUF->ethhdr.src.addr, uip_ethaddr.addr, 6);
  memcpy(BUF->shwaddr.addr, uip_ethaddr.addr, 6);
  
  BUF->opcode = HTONS(ARP_REQUEST); /* ARP request. */
  BUF->hwtype = HTONS(ARP_HWTYPE_ETH);
  BUF->protocol = HTONS(UIP_ETHTYPE_IP);
  BUF->hwlen = 6;
  BUF->protolen = 4;
  BUF->ethhdr.type = HTONS(UIP_ETHTYPE_ARP); 
  uip_appdata = &uip_buf[UIP_TCPIP_HLEN + UIP_LLH_LEN];    
  uip_len = sizeof(struct arp_hdr);

}

static void send_probe() 
{
  create_arp_packet();
  uip_ipaddr_copy(BUF->dipaddr, autoip_state->ipaddr);
  BUF->sipaddr[0] = 0;
  BUF->sipaddr[1] = 0;
  autoip_state->probes_sent++;
  random_timer_set(&autoip_state->timer,
                   PROBE_MIN * CLOCK_SECOND,
                   PROBE_MAX * CLOCK_SECOND);
}

static void send_announce() 
{
  create_arp_packet();
  uip_ipaddr_copy(BUF->dipaddr, autoip_state->ipaddr);
  uip_ipaddr_copy(BUF->sipaddr, autoip_state->ipaddr);

  autoip_state->announces_sent++;
  timer_set(&autoip_state->timer, ANNOUNCE_INTERVAL * CLOCK_SECOND);
}

void autoip_periodic() 
{
  switch (autoip_state->state) 
    {
    case DISABLED:
      break;
    case NO_ADDRESS: 
      {
        int r1,r2;
        if (!autoip_state->limit_rate || timer_expired(&autoip_state->timer)) {
          RAND(autoip_state->rand);          
          r1 = autoip_state->rand & 0xff;
          r2 = (autoip_state->rand & 0xff00) >> 8;
          uip_ipaddr(&(autoip_state->ipaddr),169,254,r1,r2);
          autoip_state->state = WAIT_FOR_PROBE;
          random_timer_set(&autoip_state->timer, 0, PROBE_WAIT * CLOCK_SECOND);
        }
        break;
      }
    case WAIT_FOR_PROBE:
      if (timer_expired(&autoip_state->timer)) {
        autoip_state->state = PROBING;
        send_probe();
      }
      break;
    case PROBING:
      if (timer_expired(&autoip_state->timer)) 
        {
          if (autoip_state->probes_sent == PROBE_NUM) {
            // configured
            autoip_state->state = WAIT_FOR_ANNOUNCE;
            timer_set(&autoip_state->timer, ANNOUNCE_WAIT * CLOCK_SECOND);
          }
          else 
            send_probe();
        }      
      break;
    case WAIT_FOR_ANNOUNCE:
      if (timer_expired(&autoip_state->timer)) {
        if (autoip_state->num_conflicts == 0) {
          autoip_state->state = ANNOUNCING;
          send_announce();
        }
        else {
          autoip_state->state = NO_ADDRESS;
          autoip_state->probes_sent = 0;
          autoip_state->announces_sent = 0;
          autoip_state->num_conflicts = 0;
          autoip_state->limit_rate = 
            autoip_state->limit_rate ||
            (autoip_state->num_conflicts > MAX_CONFLICTS);
          timer_set(&autoip_state->timer, RATE_LIMIT_INTERVAL * CLOCK_SECOND);
        }
      }
      break;
    case ANNOUNCING:
      send_announce();
      if (autoip_state->announces_sent == ANNOUNCE_NUM) {
        autoip_state->state = CONFIGURED;
        autoip_configured(autoip_state->ipaddr);
      }
      break;
    case CONFIGURED:
      break;
    }
  return;
}

void autoip_arp_in()
{
  switch (autoip_state->state)
    {
      case WAIT_FOR_PROBE:
      case PROBING:
      case WAIT_FOR_ANNOUNCE:
        if (uip_ipaddr_cmp(BUF->sipaddr, autoip_state->ipaddr)) {
          autoip_state->num_conflicts++;
        }       
        break;
    default:
      break;
    }
  return;
}

void autoip_start() 
{
  //  printstr("ipv4ll allocation started\n");
  if (autoip_state->state == DISABLED) {
    autoip_state->rand = autoip_state->seed;
    RAND(autoip_state->rand);
    autoip_state->state = NO_ADDRESS;
    autoip_state->probes_sent = 0;
    autoip_state->announces_sent = 0;
    autoip_state->num_conflicts = 0;
    autoip_state->limit_rate = 0;  
  }
}

void autoip_stop() 
{
  //  printstr("ipv4ll allocation stopped\n");
  autoip_state->state = DISABLED;
}
