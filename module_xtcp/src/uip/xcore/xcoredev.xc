/**
 * Module:  module_xtcp
 * Version: 2v0
 * Build:   bff4c572d34fec7e82e1e9d525d0b6585e034630
 * File:    xcoredev.xc
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
#include <xs1.h>
#include "ethernet_rx_client.h"
#include "ethernet_tx_client.h"
#include "mac_custom_filter.h"

extern unsigned short uip_len;
extern unsigned int uip_buf32[];

static unsigned char mac_addr[6];

/*---------------------------------------------------------------------------*/
void
xcoredev_init(chanend rx, chanend tx)
{
  mac_get_macaddr(tx, mac_addr);

  // Configure the mac link to send the server anything
  // arp or ip
  mac_set_custom_filter(rx, MAC_FILTER_ARPIP);
}

/*---------------------------------------------------------------------------*/
#pragma unsafe arrays
unsigned int
xcoredev_read(chanend rx, int n)
{
  unsigned int len = 0;
  unsigned int src_port;
  select 
    {
    case safe_mac_rx(rx, (uip_buf32, unsigned char[]), len, src_port, n):
      break;
    default:      
      break;
    }
  return len <= n ? len : 0;
}

/*---------------------------------------------------------------------------*/
void
xcoredev_send(chanend tx)
{
  int len = uip_len;
  if (len != 0) {
    if (len < 64)  {
      for (int i=len;i<64;i++) 
        (uip_buf32, unsigned char[])[i] = 0;      
      len=64;
    }

    mac_tx(tx, uip_buf32, len, -1);
  }
}
/*---------------------------------------------------------------------------*/
