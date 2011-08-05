/**
 * Module:  app_dsc_demo
 * Version: 1v0alpha0
 * Build:   8b9b7f06e54cf08659c20477a643c0cd958c1510
 * File:    watchdog.h
 * Modified by : A Srikanth
 * Last Modified on : 05-Aug-2011
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
#define WD_CMD_TICK		3
#define WD_CMD_START		4

void do_wd(chanend c_wd, out port wd);
