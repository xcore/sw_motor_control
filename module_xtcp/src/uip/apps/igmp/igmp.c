/**
 * Module:  module_xtcp
 * Version: 1v3
 * Build:   44b99e7cf03c809c736b69d6c73c1a796cb47676
 * File:    igmp.c
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
#include "uip_arp.h"
#include "timer.h"
#include <string.h>
#include <print.h>
#define UNSOLICITED_REPORT_INTERVAL 10

#define MAX_IGMP_GROUPS 10

#define  IGMP_MEMBERSHIP_QUERY 0x11
#define  IGMP_MEMBERSHIP_REPORT 0x16
#define  IGMP_LEAVE_GROUP 0x17

#define PROTO_IGMP 0x02

#define UIP_ETHTYPE_IP  0x0800

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

typedef struct ip_options_t {
  u8_t options[4];
} ip_options_t;

typedef struct igmp_msg_t {
 u8_t           msgtype;
 u8_t           max_response;
 u16_t          checksum;
 u16_t          addr[2];
} igmp_msg_t;

enum igmp_state_t {
  NON_MEMBER,
  PENDING_JOIN,
  DELAYED_MEMBER,
  IDLE_MEMBER,
  PENDING_LEAVE
};

typedef struct igmp_group_state_t {
  int state;
  uip_ipaddr_t addr;
  int flag;
  struct uip_timer timer;
} igmp_group_state_t;

static igmp_group_state_t groups[MAX_IGMP_GROUPS];

static u16_t ipid;
#define IPBUF ((struct ethip_hdr *)&uip_buf[0])
#define OPTBUF ((struct ip_options_t *)&uip_buf[sizeof(struct ethip_hdr)])
#define IGMPBUF ((struct igmp_msg_t *)&uip_buf[sizeof(struct ethip_hdr) + sizeof(struct ip_options_t)])

static uip_ipaddr_t allgroups_ipaddr;
static uip_ipaddr_t leavegroup_ipaddr;

void igmp_init() 
{
  int i;
  for (i=0;i<MAX_IGMP_GROUPS;i++)
    groups[i].state = NON_MEMBER;
  uip_ipaddr(allgroups_ipaddr, 224, 0, 0, 1);
  uip_ipaddr(leavegroup_ipaddr, 224, 0, 0, 2);
}

static void create_igmp_msg(int msgtype,
                            uip_ipaddr_t dest_addr,
                            uip_ipaddr_t group_addr)
{
  u16_t checksum;
  unsigned char dest_hwaddr[6];
  uip_len = sizeof(struct ethip_hdr) + 
    sizeof(ip_options_t) + 
    sizeof(igmp_msg_t);
  
  dest_hwaddr[0] = 0x01;
  dest_hwaddr[1] = 0x00;
  dest_hwaddr[2] = 0x5e;
  dest_hwaddr[3] = dest_addr[0] >> 8; 
  dest_hwaddr[4] = dest_addr[1] & 0xf;
  dest_hwaddr[5] = dest_addr[1] >> 8; 
  memcpy(IPBUF->ethhdr.dest.addr, dest_hwaddr, 6);
  memcpy(IPBUF->ethhdr.src.addr, uip_ethaddr.addr, 6);

  uip_ipaddr_copy(IPBUF->destipaddr, dest_addr);
  uip_ipaddr_copy(IPBUF->srcipaddr, uip_hostaddr);
  IPBUF->ethhdr.type = HTONS(UIP_ETHTYPE_IP);
  IPBUF->vhl = 0x46;
  IPBUF->tos = 0;
  IPBUF->len[0] = (32 >> 8);
  IPBUF->len[1] = (32 & 0xff);
  IPBUF->ipid[0] = ipid >> 8 ;
  IPBUF->ipid[1] = ipid & 0xff; 
  ipid++;
  IPBUF->ipoffset[0] = IPBUF->ipoffset[1] = 0;
  IPBUF->ttl = 1;//UIP_TTL;
  IPBUF->proto = PROTO_IGMP;
  IPBUF->ipchksum = 0;
  OPTBUF->options[0] = 0x94;
  OPTBUF->options[1] = 0x04;
  OPTBUF->options[2] = 0x00;
  OPTBUF->options[3] = 0x00;
  checksum = uip_chksum((u16_t *) &uip_buf[UIP_LLH_LEN], UIP_IPH_LEN+sizeof(ip_options_t));
  if (checksum == 0)
    checksum = 0xffff;
  //  checksum = uip_ipchksum();  
  IPBUF->ipchksum = ~checksum;  
  IGMPBUF->msgtype = msgtype;
  IGMPBUF->max_response = 0x0;
  checksum = (IGMPBUF->msgtype);
  checksum += group_addr[0];
  checksum += group_addr[1];
  IGMPBUF->checksum = ~checksum;
  uip_ipaddr_copy(IGMPBUF->addr, group_addr);
  return;
}

static void send_membership_report(igmp_group_state_t *s)
{
  create_igmp_msg(IGMP_MEMBERSHIP_REPORT, s->addr, s->addr);
  return;
}

static void send_leave_group(igmp_group_state_t *s)
{
  create_igmp_msg(IGMP_LEAVE_GROUP, leavegroup_ipaddr, s->addr);
  return;
}

static void igmp_group_periodic(igmp_group_state_t *s)
{
  switch (s->state)
    {
    case NON_MEMBER:
    case IDLE_MEMBER:
      break;
    case PENDING_JOIN:      
      send_membership_report(s);
      s->flag = 1;
      s->state = DELAYED_MEMBER;
      timer_set(&s->timer, UNSOLICITED_REPORT_INTERVAL * CLOCK_SECOND);
      break;
    case DELAYED_MEMBER:
      if (timer_expired(&s->timer))  {
        send_membership_report(s);
        s->flag = 1;
        s->state = IDLE_MEMBER;
      }
      break;
    case PENDING_LEAVE:
      if (s->flag)
        send_leave_group(s);
      s->state = NON_MEMBER;
      break;
    }  
  return;
}

void igmp_periodic() 
{
  int i;
  for (i=0;i<MAX_IGMP_GROUPS;i++) {
    igmp_group_periodic(&groups[i]);
    if (uip_len > 0)
      break;
  }
  return;
}

static int igmp_checksum_valid() 
{
  u16_t chksum;
  chksum = (IGMPBUF->max_response << 8) | IGMPBUF->msgtype;
  chksum += IGMPBUF->addr[0];
  chksum += IGMPBUF->addr[1];
  return (IGMPBUF->checksum == ~chksum);
}

void igmp_in()
{
  switch (IGMPBUF->msgtype) 
    {
    case IGMP_MEMBERSHIP_QUERY: {
      int to_all_groups = uip_ipaddr_cmp(IGMPBUF->addr, allgroups_ipaddr);
      int i=0;
      if (igmp_checksum_valid())
        for (i=0;i<MAX_IGMP_GROUPS;i++) {
          if ((groups[i].state == IDLE_MEMBER ||
               groups[i].state == DELAYED_MEMBER)
              &&
              (to_all_groups || uip_ipaddr_cmp(IGMPBUF->addr, groups[i].addr)))
            {
              groups[i].state = DELAYED_MEMBER;
              // should be random up to max response time
              timer_set(&groups[i].timer,
                        (IGMPBUF->max_response >> 5) * CLOCK_SECOND);
            }
        }
      }     
      break;
    case IGMP_MEMBERSHIP_REPORT: {
      int i=0;
      if (igmp_checksum_valid())
        for (i=0;i<MAX_IGMP_GROUPS;i++) {
          if ((groups[i].state == DELAYED_MEMBER)
              &&
              uip_ipaddr_cmp(IGMPBUF->addr, groups[i].addr))
            {
              groups[i].state = IDLE_MEMBER;
              groups[i].flag = 0;
            }
        }
      }
      break;    
    }
  // nothing to send
  uip_len = 0;
}



void igmp_join_group(uip_ipaddr_t addr)
{
  int i;
  for (i=0;i<MAX_IGMP_GROUPS;i++)
    if (groups[i].state == NON_MEMBER)
      break;

  if (i==MAX_IGMP_GROUPS)
    printstr("error: max igmp groups reached");
  else {
    uip_ipaddr_copy(groups[i].addr, addr);
    groups[i].state = PENDING_JOIN;
  }
  return;
}

void igmp_leave_group(uip_ipaddr_t addr)
{
  int i;
  for (i=0;i<MAX_IGMP_GROUPS;i++)
    if ((groups[i].state == IDLE_MEMBER ||
         ((groups[i].state == DELAYED_MEMBER)
          && uip_ipaddr_cmp(addr, groups[i].addr))))
      groups[i].state = PENDING_LEAVE;
  return;
}

int igmp_check_addr(uip_ipaddr_t addr) 
{
  int i;
  for (i=0;i<MAX_IGMP_GROUPS;i++)
    if ((groups[i].state == IDLE_MEMBER ||
         ((groups[i].state == DELAYED_MEMBER)
          && uip_ipaddr_cmp(addr, groups[i].addr))))
      return 1;
  return 0;
}
