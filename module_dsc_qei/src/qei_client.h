/*
 * Module:  module_dsc_qei
 * File:    qei_client.h
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
#ifdef USE_XSCOPE
#include <xscope.h>
#endif

#include "dsc_config.h"      
                             
#include "qei_commands.h"

#ifndef __QEI_CLIENT_H__
#define __QEI_CLIENT_H__

#define HALF_QEI_CNT (QEI_PER_REV >> 1) // 180 degrees of rotation
#define QEI_REV_MASK (QEI_PER_REV - 1) // Mask used to force QEI count into base-range [0..QEI_REV_MASK] 

/* These defines are used to calculate offset between Hall-state origin, and QEI origin.
 * There are 6 Hall-states per revolution, 60 degrees each, half-way through each state is therefore 30 degrees.
 * There are 1024 QEI counts/rev (QEI_PER_REV)
 */
#define QEI_PER_POLE (QEI_PER_REV / NUM_POLE_PAIRS) // e.g. 256 No. of QEI sensors per pole 
#define QEI_POLE_MASK (QEI_PER_POLE - 1) // Mask used to force QEI count into base-range [0..QEI_POLE_MASK] 

#define THETA_HALF_PHASE (QEI_PER_POLE / 12) // e.g. ~21 CoilSectorAngle/2 (6 sectors = 60 degrees per sector, 30 degrees per half sector)


/** \brief Get the position from the QEI server
 *
 *  \param c_qei The control channel for the QEI server
 *  \return the speed, position and valid state
 */
{ int ,int ,int } get_qei_data( streaming chanend c_qei );


#endif /* __QEI_CLIENT_H__ */
