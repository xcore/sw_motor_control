/**
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
#define WD_CMD_EN_MOTOR		1
#define WD_CMD_DIS_MOTOR	2
#define WD_CMD_TICK			3
#define WD_CMD_START		4

/** \brief Run the watchdog timer server
 *
 * The watchdog timer needs a constant stream of pulses to prevent it
 * from shutting down the motor.  This is a thread server which implements
 * the watchdog timer output.
 *
 * The watchdog control port should have two bits attached to the watchdog
 * circuitry. Bit zero will get a rising edge whenever the watchdog is to
 * be reset, and bit one will have the pulse train.
 *
 * \param c_wd the control channel for controlling the watchdog
 * \param wd the control port for the watchdog device
 */
void do_wd(chanend c_wd, out port wd);
