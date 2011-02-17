/**
 * Module:  module_xtcp
 * Version: 2v0
 * Build:   78711bfe1af34008dd985d9c346af0460d052095
 * File:    uip_xtcp_support.xc
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
#include "uip_xtcp.h"
#include <print.h>

static int linkstate = 0;

void uip_xtcp_checklink(chanend connect_status)
{
  unsigned char ifnum;
  select 
    {
    case inuchar_byref(connect_status, ifnum):
      {
        int status;
        status = inuchar(connect_status);
        (void) inuchar(connect_status);
        (void) inct(connect_status);
        if (!status && linkstate) {
          linkstate = 0;
          uip_linkdown();
        }
        if (status && !linkstate) {
          linkstate = 1;
          uip_linkup();  
        }
        break;
      }
    default:
      break;
    }
  return;
}
