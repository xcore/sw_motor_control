/**
 * Module:  module_dsc_pwm
 * Version: 1v0alpha1
 * Build:   f29fa5888a0d92c83949f37a31efe2ec19a95534
 * File:    pwm_op_inv.S
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
#include "dsc_config.h"

.extern pwm_op_inv
.globl pwm_op_inv.nstackwords
.globl pwm_op_inv.maxthreads
.globl pwm_op_inv.maxtimers
.globl pwm_op_inv.maxchanends

.linkset pwm_op_inv.nstackwords, 13
.linkset pwm_op_inv.maxchanends, 1
.linkset pwm_op_inv.maxtimers, 0
.linkset pwm_op_inv.maxthreads, 0

.globl pwm_op_inv
.cc_top pwm_op_inv.func, pwm_op_inv
.text

// r0 - buf
// r1 - p_pwm,
// r2 - p_pwm_inv,
// r3 - channel,
// sp[14] - address of shared memory buffer
// sp[15] - adc trigger channel
// sp[16] - dummy port for adc trigger
pwm_op_inv:
	entsp 13

	// callee save
	stw r4, sp[1]
	stw r5, sp[2]
	stw r6, sp[3]
	stw r7, sp[4]
	stw r8, sp[5]
	stw r9, sp[6]
	stw r10, sp[7]

	stw r0, sp[8]	// buf
	stw r1, sp[9]	// p_pwm
	stw r2, sp[10]  // p_pwm_inv
	stw r3, sp[11]  // channel

	/*
	 * now arrange stuff:
	 * r0 - pwm port 0,    r1  - pwm port1,  r2 - pwm port2,
	 * r3 - out_data0,     r4  - out_data1,  r5 - out_data2
	 * r6 - pwm_inv_port0  r7  - sync_point, r8 - tmp
	 * r9 - pwm_inv_port1  r10 - chanend,   r11 - pwm_inv_port2
	 *
	 * r10 loaded by PWM mode
	 */
	mov r8, r1  // p_pwm
	mov r7, r0  // buf

	/* load ports and data pointers */
	//prep for reading port order array
	ldw r11, sp[14]
	ldc r0, 12
	mul r0, r7, r0 // buf * 12
	add r11, r0, r11 // now at top of correct chan_id_buf

	// prep for reading data_out
	ldw r5, sp[14]
	ldc r2, OFFSET_OF_DATA_OUT
	add r5, r5, r2
	ldc r2, (SIZE_OF_T_DATA_OUT*3)
	mul r7, r7, r2 // buf * r2
	add r5, r5, r7 // now at top of correct array of structs

	ldc r2, SIZE_OF_T_DATA_OUT
	ldw r0, r11[0] // chan_id_buf[0]
	mul r3, r0, r2 // mult chan_id_buf[0] by SIZE_OF_T_DATA_OUT
	add r3, r5, r3 // out_data0 assigned
	ldw r0, r8[r0] // port 0 assigned

	ldw r1, r11[1] // chan_id_buf[1]
	mul r4, r1, r2 // mult chan_id_buf[1] by SIZE_OF_T_DATA_OUT
	add r4, r5, r4 // out_data1 assigned
	ldw r1, r8[r1] // port 1 assigned

	ldw r6, r11[2] // chan_id_buf[2]
	mul r10, r6, r2 // mult chan_id_buf[2] by SIZE_OF_T_DATA_OUT
	add r5, r5, r10 // out_data1 assigned
	ldw r2, r8[r6] // port 2 assigned

	/* load inverted ports */
	ldw r10, sp[10]
	// inv port 0
	ldw r6, r11[0]
	ldw r6, r10[r6]

	// inv port 1
	ldw r9, r11[1]
	ldw r9, r10[r9]

	// inv port 2
	ldw r11, r11[2]
	ldw r11, r10[r11]

	// read mode
	ldw r7, sp[8]
	ldw r8, sp[14]
	ldc r10, OFFSET_OF_MODE_BUF
	add r8, r8, r10
	ldaw r8, r8[r7]
	ldw r10, r8[0]

	// get current time stamp
	getts r7, res[r0]

	ldc r8, INIT_SYNC_INCREMENT
	add r7, r8, r7

	// check mode and branch as appropriate
	eq r8, r10, 1
	bt r8, PWM_MODE_1
	eq r8, r10, 2
	bt r8, PWM_MODE_2
	eq r8, r10, 3
	bt r8, PWM_MODE_3
	eq r8, r10, 4
	bt r8, PWM_MODE_4
	eq r8, r10, 5
	bt r8, PWM_MODE_5
	eq r8, r10, 6
	bt r8, PWM_MODE_6
	eq r8, r10, 7
	bt r8, PWM_MODE_7

PWM_STOP:
	bu	PWM_STOP

PWM_MODE_1:
	// load channel
	ldw r10, sp[11]

PWM_MODE_1_LOOP:

	// Channel 0
	ldw r8, r3[0]
	sub r8, r7, r8 
	setpt res[r0], r8
	ldw r8, r3[4]
	sub r8, r7, r8
	setpt res[r6], r8
	ldw r8, r3[1]
	out res[r0], r8
	ldw r8, r3[5]
	out res[r6], r8

	// Channel 1
	ldw r8, r4[0]
	sub r8, r7, r8
	setpt res[r1], r8
	ldw r8, r4[4]
	sub r8, r7, r8
	setpt res[r9], r8
	ldw r8, r4[1]
	out res[r1], r8
	ldw r8, r4[5]
	out res[r9], r8
	
	// Channel 2
	ldw r8, r5[0]
	sub r8, r7, r8
	setpt res[r2], r8
	ldw r8, r5[4]
	sub r8, r7, r8
	setpt res[r11], r8
	ldw r8, r5[1]
	out res[r2], r8
	ldw r8, r5[5]
	out res[r11], r8

	// trigger adc
	#if LOCK_ADC_TO_PWM
	ldw r8, sp[16] // load port
	setpt res[r8], r7 // pt = sync point
	ldw r10, sp[15] // load adc trig chanend
	in r8, res[r8] // wait until we hit setpt
	outct res[r10], ADC_TRIG_TOKEN // send adc trig token
	ldw r10, sp[11] // load clobbered chanend
	#endif

	// setup event
	mov r8, r11
	ldap r11, GO_UPDATE_M1
	setv res[r10], r11
	eeu res[r10]
	setsr 0x1
	// clear events
	clrsr 0x1
	clre
	mov r11, r8

	// update SYNC timestamp
	ldc r8, SYNC_INCREMENT
	add r7, r8, r7

	bu PWM_MODE_1
	
GO_UPDATE_M1:
	// get mode
	chkct res[r10], 0x1
	outct res[r10], 0x1
	in r0, res[r10]
	chkct res[r10], 0x1
	outct res[r10], 0x1

	stw r7, sp[13] // save TS

	ldw r8, sp[9]   // p_pwm
	mov r7, r0  // buf
	stw r7, sp[12]

	/* load ports and data pointers */
	//prep for reading port order array
	ldw r11, sp[14]
	ldc r0, 12
	mul r0, r7, r0 // buf * 12
	add r11, r0, r11 // now at top of correct chan_id_buf

	// prep for reading data_out
    ldw r5, sp[14]
    ldc r2, OFFSET_OF_DATA_OUT
    add r5, r5, r2
    ldc r2, (SIZE_OF_T_DATA_OUT*3)
    mul r7, r7, r2 // buf * r2
    add r5, r5, r7 // now at top of correct array of structs

	ldc r2, SIZE_OF_T_DATA_OUT
	ldw r0, r11[0] // chan_id_buf[0]
	mul r3, r0, r2 // mult chan_id_buf[0] by SIZE_OF_T_DATA_OUT
	add r3, r5, r3 // out_data0 assigned
	ldw r0, r8[r0] // port 0 assigned

	ldw r1, r11[1] // chan_id_buf[1]
	mul r4, r1, r2 // mult chan_id_buf[1] by SIZE_OF_T_DATA_OUT
	add r4, r5, r4 // out_data1 assigned
	ldw r1, r8[r1] // port 1 assigned

	ldw r6, r11[2] // chan_id_buf[2]
	mul r10, r6, r2 // mult chan_id_buf[2] by SIZE_OF_T_DATA_OUT
	add r5, r5, r10 // out_data1 assigned
	ldw r2, r8[r6] // port 2 assigned

	/* load inverted ports */
	ldw r10, sp[10]
	// inv port 0
	ldw r6, r11[0]
	ldw r6, r10[r6]

	// inv port 1
	ldw r9, r11[1]
	ldw r9, r10[r9]

	// inv port 2
	ldw r11, r11[2]
	ldw r11, r10[r11]

	// read mode
    ldw r7, sp[12] // load in buffer number
    ldw r8, sp[14]
    ldc r10, OFFSET_OF_MODE_BUF
    add r8, r8, r10
    ldaw r8, r8[r7]
    ldw r10, r8[0]

	// update time stamp => start time = old_start_time + SYNC_INCREMENT
	ldw r7, sp[13]
	ldc r8, SYNC_INCREMENT
	add r7, r8, r7

	// check mode and branch as appropriate
	eq r8, r10, 1
	bt r8, PWM_MODE_1
	eq r8, r10, 2
	bt r8, PWM_MODE_2
	eq r8, r10, 3
	bt r8, PWM_MODE_3
	eq r8, r10, 4
	bt r8, PWM_MODE_4
	eq r8, r10, 5
	bt r8, PWM_MODE_5
	eq r8, r10, 6
	bt r8, PWM_MODE_6
	eq r8, r10, 7
	bt r8, PWM_MODE_7
	bu	PWM_STOP

PWM_MODE_2:
	// load channel
	ldw r10, sp[11]

PWM_MODE_2_LOOP:

	// Channel 0
	ldw r8, r3[0]
	sub r8, r7, r8
	setpt res[r0], r8
	ldw r8, r3[4]
	sub r8, r7, r8
	setpt res[r6], r8
	ldw r8, r3[1]
	out res[r0], r8
	ldw r8, r3[5]
	out res[r6], r8

	// Channel 1
	ldw r8, r4[0]
	sub r8, r7, r8
	setpt res[r1], r8
	ldw r8, r4[4]
	sub r8, r7, r8
	setpt res[r9], r8
	ldw r8, r4[1]
	out res[r1], r8
	ldw r8, r4[5]
	out res[r9], r8
	
	// Channel 2
	ldw r8, r5[0]
	sub r8, r7, r8
	setpt res[r2], r8
	ldw r8, r5[4]
	sub r8, r7, r8
	setpt res[r11], r8
	ldw r8, r5[1]
	out res[r2], r8
	ldw r8, r5[5]
	out res[r11], r8

	// trigger adc
	#if LOCK_ADC_TO_PWM
	ldw r8, sp[16] // load port
	setpt res[r8], r7 // pt = sync point
	ldw r10, sp[15] // load adc trig chanend
	in r8, res[r8] // wait until we hit setpt
	outct res[r10], ADC_TRIG_TOKEN // send adc trig token
	ldw r10, sp[11] // load clobbered chanend
	#endif

	// Channel 0
	ldw r8, r3[2]
	add r8, r7, r8
	setpt res[r0], r8
	ldw r8, r3[6]
	add r8, r7, r8
	setpt res[r6], r8
	ldw r8, r3[3]
	out res[r0], r8
	ldw r8, r3[7]
	out res[r6], r8
	
	// setup event
	mov r8, r11
	ldap r11, GO_UPDATE_M1
	setv res[r10], r11
	eeu res[r10]
	setsr 0x1
	// clear events
	clrsr 0x1
	clre
	mov r11, r8

	// update SYNC timestamp
	ldc r8, SYNC_INCREMENT
	add r7, r8, r7
	mkmsk r8, 16
	and r7, r8, r7
	
	bu PWM_MODE_2

PWM_MODE_3:
	// load channel
	ldw r10, sp[11]

PWM_MODE_3_LOOP:

	// Channel 0
	ldw r8, r3[0]
	sub r8, r7, r8
	setpt res[r0], r8
	ldw r8, r3[4]
	sub r8, r7, r8
	setpt res[r6], r8
	ldw r8, r3[1]
	out res[r0], r8
	ldw r8, r3[5]
	out res[r6], r8

	// Channel 1
	ldw r8, r4[0]
	sub r8, r7, r8
	setpt res[r1], r8
	ldw r8, r4[4]
	sub r8, r7, r8
	setpt res[r9], r8
	ldw r8, r4[1]
	out res[r1], r8
	ldw r8, r4[5]
	out res[r9], r8
	
	// Channel 2
	ldw r8, r5[0]
	sub r8, r7, r8
	setpt res[r2], r8
	ldw r8, r5[4]
	sub r8, r7, r8
	setpt res[r11], r8
	ldw r8, r5[1]
	out res[r2], r8
	ldw r8, r5[5]
	out res[r11], r8

	// trigger adc
	#if LOCK_ADC_TO_PWM
	ldw r8, sp[16] // load port
	setpt res[r8], r7 // pt = sync point
	ldw r10, sp[15] // load adc trig chanend
	in r8, res[r8] // wait until we hit setpt
	outct res[r10], ADC_TRIG_TOKEN // send adc trig token
	ldw r10, sp[11] // load clobbered chanend
	#endif

	// Channel 1
	ldw r8, r4[2]
	add r8, r7, r8
	setpt res[r1], r8
	ldw r8, r4[6]
	add r8, r7, r8
	setpt res[r9], r8
	ldw r8, r4[3]
	out res[r1], r8
	ldw r8, r4[7]
	out res[r9], r8

	// Channel 0
	ldw r8, r3[2]
	add r8, r7, r8
	setpt res[r0], r8
	ldw r8, r3[6]
	add r8, r7, r8
	setpt res[r6], r8
	ldw r8, r3[3]
	out res[r0], r8
	ldw r8, r3[7]
	out res[r6], r8

	// setup event
	mov r8, r11
	ldap r11, GO_UPDATE_M1
	setv res[r10], r11
	eeu res[r10]
	setsr 0x1
	// clear events
	clrsr 0x1
	clre
	mov r11, r8

	// update SYNC timestamp
	ldc r8, SYNC_INCREMENT
	add r7, r8, r7
	mkmsk r8, 16
	and r7, r8, r7
	
	bu PWM_MODE_3
	
PWM_MODE_4:
	// load channel end
	ldw r10, sp[11]

PWM_MODE_4_LOOP:

	// Channel 0
	ldw r8, r3[0] // load time for A
	sub r8, r7, r8 // calc time for A
	setpt res[r0], r8 // setpt for A
	ldw r8, r3[4] // load time for A'
	sub r8, r7, r8 // calc time for A'
	setpt res[r6], r8 // setpt for A'
	ldw r8, r3[1] // load output value A
	out res[r0], r8 // put output value into port
	ldw r8, r3[5] // load output value A'
	out res[r6], r8 // put output value into port

	// Channel 1
	ldw r8, r4[0]
	sub r8, r7, r8
	setpt res[r1], r8
	ldw r8, r4[4]
	sub r8, r7, r8
	setpt res[r9], r8
	ldw r8, r4[1]
	out res[r1], r8
	ldw r8, r4[5]
	out res[r9], r8

	// Channel 2
	ldw r8, r5[0]
	sub r8, r7, r8
	setpt res[r2], r8
	ldw r8, r5[4]
	sub r8, r7, r8
	setpt res[r11], r8
	ldw r8, r5[1]
	out res[r2], r8
	ldw r8, r5[5]
	out res[r11], r8

	// trigger adc
	#if LOCK_ADC_TO_PWM
	ldw r8, sp[16] // load port
	setpt res[r8], r7 // pt = sync point
	ldw r10, sp[15] // load adc trig chanend
	in r8, res[r8] // wait until we hit setpt
	outct res[r10], ADC_TRIG_TOKEN // send adc trig token
	ldw r10, sp[11] // load clobbered chanend
	#endif

	// Channel 2
	ldw r8, r5[2]
	add r8, r7, r8
	setpt res[r2], r8
	ldw r8, r5[6]
	add r8, r7, r8
	setpt res[r11], r8
	ldw r8, r5[3]
	out res[r2], r8
	ldw r8, r5[7]
	out res[r11], r8

	// Channel 1
	ldw r8, r4[2]
	add r8, r7, r8
	setpt res[r1], r8
	ldw r8, r4[6]
	add r8, r7, r8
	setpt res[r9], r8
	ldw r8, r4[3]
	out res[r1], r8
	ldw r8, r4[7]
	out res[r9], r8

	// Channel 0
	ldw r8, r3[2]
	add r8, r7, r8
	setpt res[r0], r8
	ldw r8, r3[6]
	add r8, r7, r8
	setpt res[r6], r8
	ldw r8, r3[3]
	out res[r0], r8
	ldw r8, r3[7]
	out res[r6], r8


	// setup event
	mov r8, r11
	ldap r11, GO_UPDATE_M1
	setv res[r10], r11
	eeu res[r10]
	setsr 0x1
	// clear events
	clrsr 0x1
	clre
	mov r11, r8

	// update SYNC timestamp
	ldc r8, SYNC_INCREMENT
	add r7, r8, r7
	mkmsk r8, 16
	and r7, r8, r7

	bu PWM_MODE_4

PWM_MODE_5:
	// load channel
	ldw r10, sp[11]

PWM_MODE_5_LOOP:

	// Channel 0
	ldw r8, r3[0]
	sub r8, r7, r8
	setpt res[r0], r8
	ldw r8, r3[4]
	sub r8, r7, r8
	setpt res[r6], r8
	ldw r8, r3[1]
	out res[r0], r8
	ldw r8, r3[5]
	out res[r6], r8

	// Channel 1
	ldw r8, r4[0]
	sub r8, r7, r8
	setpt res[r1], r8
	ldw r8, r4[4]
	sub r8, r7, r8
	setpt res[r9], r8
	ldw r8, r4[1]
	out res[r1], r8
	ldw r8, r4[5]
	out res[r9], r8

	// Channel 2
	ldw r8, r5[0]
	sub r8, r7, r8
	setpt res[r2], r8
	ldw r8, r5[4]
	sub r8, r7, r8
	setpt res[r11], r8
	ldw r8, r5[1]
	out res[r2], r8
	ldw r8, r5[5]
	out res[r11], r8
	// trigger adc
	#if LOCK_ADC_TO_PWM
	ldw r8, sp[16] // load port
	setpt res[r8], r7 // pt = sync point
	ldw r10, sp[15] // load adc trig chanend
	in r8, res[r8] // wait until we hit setpt
	outct res[r10], ADC_TRIG_TOKEN // send adc trig token
	ldw r10, sp[11] // load clobbered chanend
	#endif

	// Channel 1
	ldw r8, r4[2]
	add r8, r7, r8
	setpt res[r1], r8
	ldw r8, r4[6]
	add r8, r7, r8
	setpt res[r9], r8
	ldw r8, r4[3]
	out res[r1], r8
	ldw r8, r4[7]
	out res[r9], r8

	// update SYNC timestamp
	ldc r8, SYNC_INCREMENT
	add r7, r8, r7
	mkmsk r8, 16
	and r7, r8, r7

	// setup event
	mov r8, r11
	ldap r11, GO_UPDATE_M7
	setv res[r10], r11
	eeu res[r10]
	setsr 0x1
	// clear events
	clrsr 0x1
	clre
	mov r11, r8

	bu PWM_MODE_5

PWM_MODE_6:
	// load channel
	ldw r10, sp[11]

PWM_MODE_6_LOOP:

	// Channel 0
	ldw r8, r3[0]
	sub r8, r7, r8
	setpt res[r0], r8
	ldw r8, r3[4]
	sub r8, r7, r8
	setpt res[r6], r8
	ldw r8, r3[1]
	out res[r0], r8
	ldw r8, r3[5]
	out res[r6], r8

	// Channel 1
	ldw r8, r4[0]
	sub r8, r7, r8
	setpt res[r1], r8
	ldw r8, r4[4]
	sub r8, r7, r8
	setpt res[r9], r8
	ldw r8, r4[1]
	out res[r1], r8
	ldw r8, r4[5]
	out res[r9], r8

	// Channel 2
	ldw r8, r5[0]
	sub r8, r7, r8
	setpt res[r2], r8
	ldw r8, r5[4]
	sub r8, r7, r8
	setpt res[r11], r8
	ldw r8, r5[1]
	out res[r2], r8
	ldw r8, r5[5]
	out res[r11], r8

	// trigger adc
	#if LOCK_ADC_TO_PWM
	ldw r8, sp[16] // load port
	setpt res[r8], r7 // pt = sync point
	ldw r10, sp[15] // load adc trig chanend
	in r8, res[r8] // wait until we hit setpt
	outct res[r10], ADC_TRIG_TOKEN // send adc trig token
	ldw r10, sp[11] // load clobbered chanend
	#endif

	// Channel 2
	ldw r8, r5[2]
	add r8, r7, r8
	setpt res[r2], r8
	ldw r8, r5[6]
	add r8, r7, r8
	setpt res[r11], r8
	ldw r8, r5[3]
	out res[r2], r8
	ldw r8, r5[7]
	out res[r11], r8

	// Channel 1
	ldw r8, r4[2]
	add r8, r7, r8
	setpt res[r1], r8
	ldw r8, r4[6]
	add r8, r7, r8
	setpt res[r9], r8
	ldw r8, r4[3]
	out res[r1], r8
	ldw r8, r4[7]
	out res[r9], r8

	// update SYNC timestamp
	ldc r8, SYNC_INCREMENT
	add r7, r8, r7
	mkmsk r8, 16
	and r7, r8, r7

	// setup event
	mov r8, r11
	ldap r11, GO_UPDATE_M7
	setv res[r10], r11
	eeu res[r10]
	setsr 0x1
	// clear events
	clrsr 0x1
	clre
	mov r11, r8

	bu PWM_MODE_6

PWM_MODE_7:
	// load channel
	ldw r10, sp[11]

PWM_MODE_7_LOOP:

	// Channel 0
	ldw r8, r3[0]
	sub r8, r7, r8
	setpt res[r0], r8
	ldw r8, r3[4]
	sub r8, r7, r8
	setpt res[r6], r8
	ldw r8, r3[1]
	out res[r0], r8
	ldw r8, r3[5]
	out res[r6], r8

	// Channel 1
	ldw r8, r4[0]
	sub r8, r7, r8
	setpt res[r1], r8
	ldw r8, r4[4]
	sub r8, r7, r8
	setpt res[r9], r8
	ldw r8, r4[1]
	out res[r1], r8
	ldw r8, r4[5]
	out res[r9], r8

	// Channel 2
	ldw r8, r5[0]
	sub r8, r7, r8
	setpt res[r2], r8
	ldw r8, r5[4]
	sub r8, r7, r8
	setpt res[r11], r8
	ldw r8, r5[1]
	out res[r2], r8
	ldw r8, r5[5]
	out res[r11], r8

	// trigger adc
	#if LOCK_ADC_TO_PWM
	ldw r8, sp[16] // load port
	setpt res[r8], r7 // pt = sync point
	ldw r10, sp[15] // load adc trig chanend
	in r8, res[r8] // wait until we hit setpt
	outct res[r10], ADC_TRIG_TOKEN // send adc trig token
	ldw r10, sp[11] // load clobbered chanend
	#endif

	// update SYNC timestamp
	ldc r8, SYNC_INCREMENT
	add r7, r8, r7
	mkmsk r8, 16
	and r7, r8, r7

	// setup event
	mov r8, r11
	ldap r11, GO_UPDATE_M7
	setv res[r10], r11
	eeu res[r10]
	setsr 0x1
	// clear events
	clrsr 0x1
	clre
	mov r11, r8

	bu PWM_MODE_7

GO_UPDATE_M7:
	// Channel 0
	ldw r8, r3[0]
	sub r8, r7, r8
	setpt res[r0], r8
	ldw r8, r3[4]
	sub r8, r7, r8
	setpt res[r6], r8
	ldc r8, 0
	out res[r0], r8
	out res[r6], r8

	// get mode
	chkct res[r10], 0x1
	outct res[r10], 0x1
	in r0, res[r10]
	chkct res[r10], 0x1
	outct res[r10], 0x1

	// save TS
	stw r7, sp[13]

	// load up arrays
	ldw r8, sp[9]   // p_pwm
	mov r7, r0  // buf
	stw r7, sp[12]

	/* load ports and data pointers */
	//prep for reading port order array
	ldw r11, sp[14]
	ldc r0, 12
	mul r0, r7, r0 // buf * 12
	add r11, r0, r11 // now at top of correct chan_id_buf

	// prep for reading data_out
    ldw r5, sp[14]
    ldc r2, OFFSET_OF_DATA_OUT
    add r5, r5, r2
    ldc r2, (SIZE_OF_T_DATA_OUT*3)
    mul r7, r7, r2 // buf * r2
    add r5, r5, r7 // now at top of correct array of structs

	ldc r2, SIZE_OF_T_DATA_OUT
	ldw r0, r11[0] // chan_id_buf[0]
	mul r3, r0, r2 // mult chan_id_buf[0] by SIZE_OF_T_DATA_OUT
	add r3, r5, r3 // out_data0 assigned
	ldw r0, r8[r0] // port 0 assigned

	ldw r1, r11[1] // chan_id_buf[1]
	mul r4, r1, r2 // mult chan_id_buf[1] by SIZE_OF_T_DATA_OUT
	add r4, r5, r4 // out_data1 assigned
	ldw r1, r8[r1] // port 1 assigned

	ldw r6, r11[2] // chan_id_buf[2]
	mul r10, r6, r2 // mult chan_id_buf[2] by SIZE_OF_T_DATA_OUT
	add r5, r5, r10 // out_data1 assigned
	ldw r2, r8[r6] // port 2 assigned

	/* load inverted ports */
	ldw r10, sp[10]
	// inv port 0
	ldw r6, r11[0]
	ldw r6, r10[r6]

	// inv port 1
	ldw r9, r11[1]
	ldw r9, r10[r9]

	// inv port 2
	ldw r11, r11[2]
	ldw r11, r10[r11]

	// read mode
    ldw r7, sp[12] // load in buffer number
    ldw r8, sp[14]
    ldc r10, OFFSET_OF_MODE_BUF
    add r8, r8, r10
    ldaw r8, r8[r7]
    ldw r10, r8[0]

	// get current time stamp
	ldw r7, sp[13]

	ldc r8, SYNC_INCREMENT
	add r7, r8, r7

	// check mode and branch as appropriate
	eq r8, r10, 1
	bt r8, PWM_MODE_1
	eq r8, r10, 2
	bt r8, PWM_MODE_2
	eq r8, r10, 3
	bt r8, PWM_MODE_3
	eq r8, r10, 4
	bt r8, PWM_MODE_4
	eq r8, r10, 5
	bt r8, PWM_MODE_5
	eq r8, r10, 6
	bt r8, PWM_MODE_6
	eq r8, r10, 7
	bt r8, PWM_MODE_7
	bu	PWM_STOP


.cc_bottom pwm_op_inv.func

