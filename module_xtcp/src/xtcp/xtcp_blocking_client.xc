/**
 * Module:  module_xtcp
 * Version: 2v0
 * Build:   044a13030cb0b50e28a3be24f98bad85fa8837fd
 * File:    xtcp_blocking_client.xc
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
#include "xtcp_client.h"

void xtcp_wait_for_ifup(chanend tcp_svr)
{
  xtcp_connection_t conn;
  conn.event = XTCP_ALREADY_HANDLED;
  do {
    slave xtcp_event(tcp_svr, conn);
  } while (conn.event != XTCP_IFUP);
  return;
}

xtcp_connection_t xtcp_wait_for_connection(chanend tcp_svr)
{
  xtcp_connection_t conn;
  conn.event = XTCP_ALREADY_HANDLED;
  do {
    slave xtcp_event(tcp_svr, conn);
  } while (conn.event != XTCP_NEW_CONNECTION);
  return conn;
}

int xtcp_write(chanend tcp_svr, 
               xtcp_connection_t &conn,
               unsigned char buf[],
               int len)
{
  int finished = 0;
  int success = 1;
  int index = 0, prev = 0;
  int id = conn.id;
  xtcp_init_send(tcp_svr, conn);
  while (!finished) {
    slave xtcp_event(tcp_svr, conn);
    switch (conn.event) 
      {
      case XTCP_NEW_CONNECTION:
        xtcp_close(tcp_svr, conn);
        break;
      case XTCP_REQUEST_DATA:
      case XTCP_SENT_DATA:
        { int sendlen = (len - index);
          if (sendlen > conn.mss)
            sendlen = conn.mss;
          
          xtcp_sendi(tcp_svr, buf, index, sendlen);
          prev = index;
          index += sendlen;        
          if (sendlen == 0)
            finished = 1;
        }
        break;
      case XTCP_RESEND_DATA:
        xtcp_sendi(tcp_svr, buf, prev, (index-prev));
        break;
      case XTCP_RECV_DATA:
        slave { tcp_svr <: 0; } // delay packet receive
        if (prev != len) 
          success = 0;
        finished = 1;
        break;
      case XTCP_TIMED_OUT:
      case XTCP_ABORTED:
      case XTCP_CLOSED:
        if (conn.id == id) {
          finished = 1;
          success = 0;
        }       
        break;
      case XTCP_IFDOWN:
        finished = 1;
        success = 0;
        break;
      }
  }
  return success;
}
                

int xtcp_read(chanend tcp_svr, 
              xtcp_connection_t &conn,
              unsigned char buf[],
              int minlen)
{
  int rlen = 0;
  int id = conn.id;
  while (rlen < minlen) {
    slave xtcp_event(tcp_svr, conn);
    switch (conn.event) 
      {
      case XTCP_NEW_CONNECTION:
        xtcp_close(tcp_svr, conn);
        break;
      case XTCP_RECV_DATA: 
        {
          int n;
          n = xtcp_recvi(tcp_svr, buf, rlen);
          rlen += n;
        }
        break;
      case XTCP_REQUEST_DATA:
      case XTCP_SENT_DATA:
      case XTCP_RESEND_DATA:
        xtcp_send(tcp_svr, null, 0);
        break;
      case XTCP_TIMED_OUT:
      case XTCP_ABORTED:
      case XTCP_CLOSED:
        if (conn.id == id) 
          return -1;
        break;
      case XTCP_IFDOWN:
        return -1;
      }
  }
  return rlen;
}

