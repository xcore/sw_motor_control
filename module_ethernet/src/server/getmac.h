/**
 * Module:  module_ethernet
 * Version: 1v4
 * Build:   d3c5347cdae4e3489ef0484a98cf3e6824343bb6
 * File:    getmac.h
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
/*************************************************************************
 *
 * Ethernet MAC Layer Implementation
 * IEEE 802.3 Device MAC Address
 *
 *
 *
 * Retreives three bytes of MAC address from OTP.
 *
 *************************************************************************/

#ifndef _getmac_h_
#define _getmac_h_

#ifdef __XC__
/** Retrieves least significant 24bits from MAC address stored in OTP.
 *
 *  \param otp_data Data port connected to otp
 *  \param otp_addr Address port connected to otp
 *  \param otp_ctrl Control port connected to otp
 *  \param macaddr Array to be filled with the retrieved MAC address
 *
 **/
void ethernet_getmac_otp(port otp_data, out port otp_addr, port otp_ctrl, char macaddr[]);
#endif

#endif
