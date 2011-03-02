/**
 * Module:  module_ethernet
 * Version: 1v4_dscalpha0
 * Build:   b6078358f705bcefdaf7d6f86941fd786afea152
 * File:    ethernet_server.h
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
#ifndef _ethernet_server_h_
#define _ethernet_server_h_

#include "smi.h"
#include "mii.h"

#ifdef __XC__

/** Reset and initialize the ethernet phy.
 *
 *  This function resets the ethernet phy and initializes the MII resources.
 *  It should be called before calling ethernet_server(). This function is
 *  designed to work with SMSC phys models: ...
 * 
 *  \param clk_smi       The clock block used for smi clocking
 *  \param p_mii_resetn  This port connected to the phy reset line. This
 *                       parameter can be null if the reset line is multiplexed
 *                       on the SMI MDIO port.
 *  \param smi0          The SMI resources to connect to the phy
 *  \param mii0          The MII resources to connect to the phy
 *
 **/
void phy_init(clock clk_smi,
              out port ?p_mii_resetn,
              chanend ?c_mii_resetn,
              smi_interface_t &smi0,
              mii_interface_t &mii0);

void phy_init_two_port(clock clk_smi,
                       out port ?p_mii_resetn,
                       smi_interface_t &smi0,
                       smi_interface_t &smi1,
                       mii_interface_t &mii0,
                       mii_interface_t &mii1);

/** Single MII port MAC/ethernet server.
 *
 *  This function provides both MII layer and MAC layer functionality. 
 *  It runs in 5 threads and communicates to clients over the channel array 
 *  parameters. 
 *
 *  \param mii                  The mii interface resources that the
 *                              server will connect to
 *  \param mac_address          The mac_address the server will use. 
 *                              This should be a two-word array that stores the
 *                              6-byte macaddr in a little endian manner (so
 *                              reinterpreting the array as a char array is as
 *                              one would expect)
 *  \param rx                   An array of chanends to connect to clients of
 *                              the server who wish to receive packets.
 *  \param num_rx               The number of clients connected to the rx array
 *  \param tx                   An array of chanends to connect to clients of
 *                              the server who wish to transmit packets.
 *  \param num_tx               The number of clients connected to the txx array
 *  \param smi                  An optional parameter of resources to connect 
 *                              to a PHY (via SMI) to check when the link is up.
 *
 *  \param connect_status       An optional parameter of a channel that is
 *                              signalled when the link goes up or down
 *                              (requires the smi parameter to be supplied).
 *
 * The clients connected via the rx/tx channels can communicate with the
 * server using the APIs found in ethernet_rx_client.h and ethernet_tx_client.h
 *
 * If the smi and connect_status parameters are supplied then the 
 * connect_status channel will output when the link goes up or down. 
 * The channel will output a zero byte, followed by the status (1 for up,
 * 0 for down), followed by a zero byte, followed by an END control token.,
 *
 * The following code snippet is an example of how to receive this update:
 *
 * \verbatim
 *    (void) inuchar(connect_status);
 *    new_status = inuchar(c);
 *    (void) inuchar(c, 0);
 *    (void) inct(c);
 * \endverbatim
 **/
void ethernet_server(mii_interface_t &m,
                     int mac_address[],
                     chanend rx[],
                     int num_rx,
                     chanend tx[],
                     int num_tx,
                     smi_interface_t &?smi,
                     chanend ?connect_status);

void ethernet_server_two_port(mii_interface_t &mii1,
                              mii_interface_t &mii2,
                              int mac_address[],
                              chanend rx[],
                              int num_rx,
                              chanend tx[],
                              int num_tx,
                              smi_interface_t ?smi[2],
                              chanend ?connect_status);

#endif

#endif // _ethernet_server_h_
