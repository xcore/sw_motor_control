/*
 * Module:  module_dsc_hall
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
 */                                   
#ifndef HALL_CLIENT_H_
#define HALL_CLIENT_H_

/** \brief Get position, speed and delta from a hall server
 *
 *  The client library function for a hall sensor server
 *
 *  \param c_hall the channel for communicating with the hall server
 */
{unsigned, unsigned, unsigned} get_hall_pos_speed_delta( chanend c_hall );

#endif /* HALL_CLIENT_H_ */
