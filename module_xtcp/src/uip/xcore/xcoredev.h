/**
 * Module:  module_xtcp
 * Version: 1v3
 * Build:   44b99e7cf03c809c736b69d6c73c1a796cb47676
 * File:    xcoredev.h
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
#ifndef __XCOREDEV_H__
#define __XCOREDEV_H__

#include <xccompat.h>

void xcoredev_init(chanend mac_rx, chanend mac_tx);
unsigned int xcoredev_read(chanend mac_rx, int n);
void xcoredev_send(chanend mac_tx);

#endif /* __XCOREDEV_H__ */
