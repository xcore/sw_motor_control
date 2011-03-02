/**
 * Module:  module_xtcp
 * Version: 2v0
 * Build:   bff4c572d34fec7e82e1e9d525d0b6585e034630
 * File:    uip_server.h
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
#ifndef _uip_server_h_
#define _uip_server_h_
#include "xtcp_client.h"

/**  uIP based xtcp server.
 *
 *  \param mac_rx           Rx channel connected to ethernet server
 *  \param mac_tx           Tx channel connected to ethernet server
 *  \param xtcp             Client channel array
 *  \param num_xtcp_clients The number of clients connected to the server
 *  \param ipconfig         An data structure representing the IP config 
 *                          (ip address, netmask and gateway) of the device.
 *                          Leave NULL for automatic address allocation.
 *  \param connect_status   This chanend needs to be connected to the connect
 *                          status output of the ethernet mac.
 *
 *  This function implements an xtcp tcp/ip server in a thread.
 *  It uses a port of the uIP stack which is then interfaces over the
 *  xtcp channel array.
 *
 *  The IP setup is based on the ipconfig parameter. If this
 *  parameter is NULL then an automatic IP address is found (using dhcp or
 *  ipv4 link local addressing if no dhcp server is present). Otherwise
 *  it uses the ipconfig structure to allocate a static ip address.
 * 
 *  The clients can communicate with the server using the API found 
 *  in xtcp_client.h 
 *
 *  \sa  xtcp_event()
 **/
#ifdef __XC__
void
uip_server(chanend mac_rx, 
           chanend mac_tx, 
           chanend xtcp[], 
           int num_xtcp_clients,
           xtcp_ipconfig_t &?ipconfig,
           chanend connect_status);
#else
void uip_server(chanend mac_rx, 
                chanend mac_tx, 
                chanend xtcp[], 
                int num_xtcp_clients,
                xtcp_ipconfig_t *ipconfig,
                chanend connect_status);
#endif

#endif // _uip_server_h_
