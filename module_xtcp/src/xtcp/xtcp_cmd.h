/**
 * Module:  module_xtcp
 * Version: 2v0
 * Build:   46357bd9ecd24c11524b8a5a484e4e77daaf167d
 * File:    xtcp_cmd.h
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
#ifndef   _xtcp_cmd_h_
#define   _xtcp_cmd_h_

#define XTCP_CMD_TOKEN 128

typedef enum xtcp_cmd_t {
  XTCP_CMD_LISTEN,
  XTCP_CMD_UNLISTEN,
  XTCP_CMD_CONNECT,
  XTCP_CMD_BIND_LOCAL,
  XTCP_CMD_BIND_REMOTE,
  XTCP_CMD_INIT_SEND,
  XTCP_CMD_SET_APPSTATE,
  XTCP_CMD_CLOSE,
  XTCP_CMD_ABORT,
  XTCP_CMD_TIMED_OUT,
  XTCP_CMD_SET_POLL_INTERVAL,
  XTCP_CMD_JOIN_GROUP,
  XTCP_CMD_LEAVE_GROUP,
  XTCP_CMD_GET_MAC_ADDRESS,
  XTCP_CMD_GET_IPCONFIG,
  XTCP_CMD_ACK_RECV,
  XTCP_CMD_ACK_RECV_MODE
} xtcp_cmd_t;

#endif // _xtcp_cmd_h_
