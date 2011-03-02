/**
 * Module:  module_dsc_pwm
 * Version: 0v9sd
 * Build:   22de876873ca24a1b0bd2df0d3509379cdcc2090
 * File:    pwm_op_noinv.S
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
//
// This implements all PWM configurations for 3 channel
// PWM. The mode of operation should be updated using
// the appropriate functions in the dsc_pwm_cli API
//
// 26 Apr 2010

#include <xs1.h>
#include "dsc_pwm_common.h"


.extern pwm_op_noinv
.globl pwm_op_noinv.nstackwords
.globl pwm_op_noinv.maxthreads
.globl pwm_op_noinv.maxtimers
.globl pwm_op_noinv.maxchanends

.linkset pwm_op_noinv.nstackwords, 8
.linkset pwm_op_noinv.maxchanends, 1
.linkset pwm_op_noinv.maxtimers, 0
.linkset pwm_op_noinv.maxthreads, 0

.globl pwm_op_noinv
.cc_top pwm_op_noinv.func, pwm_op_noinv
.text

// r0 - chan_id0,
// r1 - chan_id1,
// r2 - chan_id2, 
// r3 - pwm_out_data0, 
// sp9 - pwm_out_data1,
// sp10 - pwm_out_data2,
// sp11 - mode,
// sp12 - p_pwm
// sp14 - channel
pwm_op_noinv:
	entsp 8

	// callee save
	stw r4, sp[1]
	stw r5, sp[2]
	stw r6, sp[3]
	stw r7, sp[4]
	stw r8, sp[5]
	stw r9, sp[6]
	stw r10, sp[7]

	/*
	 * now arrange stuff:
	 * r0 - pwm port 0, r1 - pwm port1,  r2 - pwm port2, 
	 * r3 - out_data0,  r4 - out_data1,  r5 - out_data2
	 * r6 - mode        r7 - sync_point, r8 - tmp0
	 * r9 - tmp1		r10- chanend
	 */
	ldw r8, sp[12]
	
	ldw r0, r8[r0]
	ldw r1, r8[r1]
	ldw r2, r8[r2]
	ldw r4, sp[9]
	ldw r5, sp[10]
	ldw r6, sp[11]
	ldw r10, sp[13]
	
	// get current time stamp
	getts r7, res[r0]

	ldc r8, INIT_SYNC_INCREMENT
	add r7, r8, r7
	// mask off to 16bits
	mkmsk r8, 16
	and r7, r8, r7

	// check mode and branch as appropriate
	eq r8, r6, 1
	bt r8, PWM_MODE_1
	eq r8, r6, 2
	bt r8, PWM_MODE_2
	eq r8, r6, 3
	bt r8, PWM_MODE_3
	eq r8, r6, 4
	bt r8, PWM_MODE_4
	eq r8, r6, 5
	bt r8, PWM_MODE_5
	eq r8, r6, 6
	bt r8, PWM_MODE_6
	eq r8, r6, 7
	bt r8, PWM_MODE_7

PWM_STOP:
	bu	PWM_STOP

PWM_MODE_1:
	// Channel 0
	ldw r8, r3[0]
	sub r8, r7, r8 
	setpt res[r0], r8
	ldw r8, r3[1]
	out res[r0], r8

	// Channel 1
	ldw r8, r4[0]
	sub r8, r7, r8
	setpt res[r1], r8
	ldw r8, r4[1]
	out res[r1], r8
	
	// Channel 2
	ldw r8, r5[0]
	sub r8, r7, r8
	setpt res[r2], r8
	ldw r8, r5[1]
	out res[r2], r8

	// setup event
	ldap r11, GO_UPDATE_M1
	setv res[r10], r11
	eeu res[r10]
	setsr 0x1

	// update SYNC timestamp
	ldc r8, SYNC_INCREMENT
	add r7, r8, r7
	mkmsk r8, 16
	and r7, r8, r7

	// clear events
	clrsr 0x1
	clre

	bu PWM_MODE_1
	
GO_UPDATE_M1:
	// get mode
	chkct res[r10], 0x1
	outct res[r10], 0x1
	in r0, res[r10]
	chkct res[r10], 0x1
	outct res[r10], 0x1

	// return mode
	ldw r4, sp[1]
	ldw r5, sp[2]
	ldw r6, sp[3]
	ldw r7, sp[4]
	ldw r8, sp[5]
	ldw r9, sp[6]
	ldw r10, sp[7]

	retsp 8

PWM_MODE_2:
	// Channel 0
	ldw r8, r3[0]
	sub r8, r7, r8
	setpt res[r0], r8
	ldw r8, r3[1]
	out res[r0], r8
	
	// Channel 1
	ldw r8, r4[0]
	sub r8, r7, r8
	setpt res[r1], r8
	ldw r8, r4[1]
	out res[r1], r8
	
	// Channel 2
	ldw r8, r5[0]
	sub r8, r7, r8
	setpt res[r2], r8
	ldw r8, r5[1]
	out res[r2], r8
	
	// Channel 0
	ldw r8, r3[2]
	add r8, r7, r8
	setpt res[r0], r8
	ldw r8, r3[3]
	out res[r0], r8
	
	// setup event
	ldap r11, GO_UPDATE_M1
	setv res[r10], r11
	eeu res[r10]
	setsr 0x1

	// update SYNC timestamp
	ldc r8, SYNC_INCREMENT
	add r7, r8, r7
	mkmsk r8, 16
	and r7, r8, r7
	
	// clear events
	clrsr 0x1
	clre
	
	bu PWM_MODE_2

PWM_MODE_3:
	// Channel 0
	ldw r8, r3[0]
	sub r8, r7, r8
	setpt res[r0], r8
	ldw r8, r3[1]
	out res[r0], r8

	// Channel 1
	ldw r8, r4[0]
	sub r8, r7, r8
	setpt res[r1], r8
	ldw r8, r4[1]
	out res[r1], r8
	
	// Channel 2
	ldw r8, r5[0]
	sub r8, r7, r8
	setpt res[r2], r8
	ldw r8, r5[1]
	out res[r2], r8
	
	// Channel 1
	ldw r8, r4[2]
	add r8, r7, r8
	setpt res[r1], r8
	ldw r8, r4[3]
	out res[r1], r8

	// Channel 0
	ldw r8, r3[2]
	add r8, r7, r8
	setpt res[r0], r8
	ldw r8, r3[3]
	out res[r0], r8


	// setup event
	ldap r11, GO_UPDATE_M1
	setv res[r10], r11
	eeu res[r10]
	setsr 0x1

	// update SYNC timestamp
	ldc r8, SYNC_INCREMENT
	add r7, r8, r7
	mkmsk r8, 16
	and r7, r8, r7
	
	// clear events
	clrsr 0x1
	clre
	
	bu PWM_MODE_3
	
PWM_MODE_4:
	// Channel 0
	ldw r8, r3[0]
	sub r8, r7, r8
	setpt res[r0], r8
	ldw r8, r3[1]
	out res[r0], r8

	// Channel 1
	ldw r8, r4[0]
	sub r8, r7, r8
	setpt res[r1], r8
	ldw r8, r4[1]
	out res[r1], r8

	// Channel 2
	ldw r8, r5[0]
	sub r8, r7, r8
	setpt res[r2], r8
	ldw r8, r5[1]
	out res[r2], r8

	// Channel 2
	ldw r8, r5[2]
	add r8, r7, r8
	setpt res[r2], r8
	ldw r8, r5[3]
	out res[r2], r8

	// Channel 1
	ldw r8, r4[2]
	add r8, r7, r8
	setpt res[r1], r8
	ldw r8, r4[3]
	out res[r1], r8

	// Channel 0
	ldw r8, r3[2]
	add r8, r7, r8
	setpt res[r0], r8
	ldw r8, r3[3]
	out res[r0], r8

	// setup event
	ldap r11, GO_UPDATE_M1
	setv res[r10], r11
	eeu res[r10]
	setsr 0x1

	// update SYNC timestamp
	ldc r8, SYNC_INCREMENT
	add r7, r8, r7
	mkmsk r8, 16
	and r7, r8, r7

	// clear events
	clrsr 0x1
	clre

	bu PWM_MODE_4

PWM_MODE_5:
	// Channel 0
	ldw r8, r3[0]
	sub r8, r7, r8
	setpt res[r0], r8
	ldw r8, r3[1]
	out res[r0], r8

	// Channel 1
	ldw r8, r4[0]
	sub r8, r7, r8
	setpt res[r1], r8
	ldw r8, r4[1]
	out res[r1], r8

	// Channel 2
	ldw r8, r5[0]
	sub r8, r7, r8
	setpt res[r2], r8
	ldw r8, r5[1]
	out res[r2], r8

	// Channel 1
	ldw r8, r4[2]
	add r8, r7, r8
	setpt res[r1], r8
	ldw r8, r4[3]
	out res[r1], r8

	// update SYNC timestamp
	ldc r8, SYNC_INCREMENT
	add r7, r8, r7
	mkmsk r8, 16
	and r7, r8, r7

	// setup event
	ldap r11, GO_UPDATE_M7
	setv res[r10], r11
	eeu res[r10]
	setsr 0x1
	// clear events
	clrsr 0x1
	clre

	bu PWM_MODE_5

PWM_MODE_6:
	// TODO clear events
	// Channel 0
	ldw r8, r3[0]
	sub r8, r7, r8
	setpt res[r0], r8
	ldw r8, r3[1]
	out res[r0], r8

	// Channel 1
	ldw r8, r4[0]
	sub r8, r7, r8
	setpt res[r1], r8
	ldw r8, r4[1]
	out res[r1], r8

	// Channel 2
	ldw r8, r5[0]
	sub r8, r7, r8
	setpt res[r2], r8
	ldw r8, r5[1]
	out res[r2], r8

	// Channel 2
	ldw r8, r5[2]
	add r8, r7, r8
	setpt res[r2], r8
	ldw r8, r5[3]
	out res[r2], r8

	// Channel 1
	ldw r8, r4[2]
	add r8, r7, r8
	setpt res[r1], r8
	ldw r8, r4[3]
	out res[r1], r8

	// update SYNC timestamp
	ldc r8, SYNC_INCREMENT
	add r7, r8, r7
	mkmsk r8, 16
	and r7, r8, r7

	// setup event
	ldap r11, GO_UPDATE_M7
	setv res[r10], r11
	eeu res[r10]
	setsr 0x1
	// clear events
	clrsr 0x1
	clre

	bu PWM_MODE_6

PWM_MODE_7:
	// Channel 0
	ldw r8, r3[0]
	sub r8, r7, r8
	setpt res[r0], r8
	ldw r8, r3[1]
	out res[r0], r8

	// Channel 1
	ldw r8, r4[0]
	sub r8, r7, r8
	setpt res[r1], r8
	ldw r8, r4[1]
	out res[r1], r8

	// Channel 2
	ldw r8, r5[0]
	sub r8, r7, r8
	setpt res[r2], r8
	ldw r8, r5[1]
	out res[r2], r8

	// update SYNC timestamp
	ldc r8, SYNC_INCREMENT
	add r7, r8, r7
	mkmsk r8, 16
	and r7, r8, r7

	// setup event
	ldap r11, GO_UPDATE_M7
	setv res[r10], r11
	eeu res[r10]
	setsr 0x1

	// clear events
	clrsr 0x1
	clre

	bu PWM_MODE_7

GO_UPDATE_M7:
	// Channel 0
	ldw r8, r3[0]
	sub r8, r7, r8
	setpt res[r0], r8
	ldc r8, 0
	out res[r0], r8

	// get mode
	chkct res[r10], 0x1
	outct res[r10], 0x1
	in r0, res[r10]
	chkct res[r10], 0x1
	outct res[r10], 0x1

	// return mode
	ldw r4, sp[1]
	ldw r5, sp[2]
	ldw r6, sp[3]
	ldw r7, sp[4]
	ldw r8, sp[5]
	ldw r9, sp[6]
	ldw r10, sp[7]

	retsp 8

.cc_bottom pwm_op_noinv.func
	
