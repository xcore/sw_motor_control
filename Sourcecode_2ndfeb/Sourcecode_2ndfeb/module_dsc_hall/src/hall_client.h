/**
 * Module:  module_dsc_hall
 * Version: 1v0alpha2
 * Build:   60a90cca6296c0154ccc44e1375cc3966292f74e
 * File:    hall_client.h
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
#ifndef HALL_CLIENT_H_
#define HALL_CLIENT_H_

/* get position, speed and delta */
{unsigned, unsigned, unsigned} get_hall_pos_speed_delta( chanend c_hall );

#endif /* HALL_CLIENT_H_ */
