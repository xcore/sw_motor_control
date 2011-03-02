/**
 * Module:  module_dsc_sdram
 * Version: 1v0alpha0
 * Build:   2b714bd1f271ed978d676942d56a0a867ed72da3
 * File:    dsc_sdram_asm.S
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
// write_asm(dq, cke, we, ras, cas, a, packet, packet_nwords, row_bank, col_bank)
//   r0   dq
//   r1   cke
//   r2   we
//   r3   ras
//   r4   cas
//   r5   a
//   r6   packet
//   r9   t0
//   r10  temporary
//   r11  temporary
.globl write_asm
.globl write_asm.nstackwords
.globl write_asm.locnochandec
.linkset write_asm.nstackwords, 8
.linkset write_asm.locnochandec, 1
write_asm:
  entsp     8
  stw       r4, sp[1]
  stw       r5, sp[2]
  stw       r6, sp[3]
  stw       r7, sp[4]
  stw       r8, sp[5]
  stw       r9, sp[6]
  stw       r10, sp[7]
  ldw       r4, sp[9]
  ldw       r5, sp[10]
  ldw       r6, sp[11]
  ldw       r11, sp[13]
  out       res[r5], r11
  ldc       r11, 1
  out       res[r1], r11
  syncr     res[r1]
  getts     r9, res[r1]
  add       r11, r9, 8
  setpt     res[r2], r11
  setpt     res[r3], r11
  setpt     res[r4], r11
  ldc       r11, 11
  out       res[r2], r11
  ldc       r11, 12
  out       res[r3], r11
  ldc       r11, 10
  out       res[r4], r11
  add       r10, r9, 10
  setpt     res[r5], r10
  ldw       r11, sp[14]
  out       res[r5], r11
  setpt     res[r0], r10
  ldw       r11, r6[0]
  out       res[r0], r11
  ldc       r11, 64
  add       r11, r9, r11
  add       r9, r11, 10
  setpt     res[r2], r9
  setpt     res[r3], r9
  setpt     res[r4], r9
  ldc       r11, 12
  out       res[r2], r11
  ldw       r11, r6[1]
  out       res[r0], r11
  ldc       r11, 9
  out       res[r3], r11
  ldc       r11, 11
  out       res[r4], r11
  ldw       r11, r6[2]
  out       res[r0], r11
  ldc       r11, 0x400
  out       res[r5], r11
  add       r9, r9, 2
  setpt     res[r1], r9
  ldc       r11, 0
  out       res[r1], r11
  ldc       r10, 3
  ldw       r2, sp[12]
L1:
  ldw       r11, r6[r10]
  out       res[r0], r11
  add       r10, r10, 1
  lsu       r11, r10, r2
  bt        r11, L1
  ldw       r4, sp[1]
  ldw       r5, sp[2]
  ldw       r6, sp[3]
  ldw       r7, sp[4]
  ldw       r8, sp[5]
  ldw       r9, sp[6]
  ldw       r10, sp[7]
  retsp     8

// read_asm(dq, cke, we, ras, cas, a, buffer, row_bank, col_bank)
//   r0   dq
//   r1   cke
//   r2   we
//   r3   ras
//   r4   cas
//   r5   a
//   r6   buffer
//   r9   t0
//   r10  temporary
//   r11  temporary
.globl read_asm
.globl read_asm.nstackwords
.globl read_asm.locnochandec
.linkset read_asm.nstackwords, 8
.linkset read_asm.locnochandec, 1
read_asm:
  entsp     8
  stw       r4, sp[1]
  stw       r5, sp[2]
  stw       r6, sp[3]
  stw       r7, sp[4]
  stw       r8, sp[5]
  stw       r9, sp[6]
  stw       r10, sp[7]
  ldw       r4, sp[9]
  ldw       r5, sp[10]
  ldw       r6, sp[11]
  ldw       r11, sp[12]
  out       res[r5], r11
  ldc       r11, 1
  out       res[r1], r11
  syncr     res[r1]
  getts     r9, res[r1]
  add       r11, r9, 8
  setpt     res[r2], r11
  setpt     res[r3], r11
  setpt     res[r4], r11
  ldc       r11, 15
  out       res[r2], r11
  ldc       r11, 12
  out       res[r3], r11
  ldc       r11, 10
  out       res[r4], r11
  add       r10, r9, 10
  setpt     res[r5], r10
  ldw       r11, sp[13]
  out       res[r5], r11
  add       r10, r10, 1
  setpt     res[r0], r10
  in        r11, res[r0]
  in        r11, res[r0]
  stw       r11, r6[0]
  ldc       r11, 74
  add       r9, r9, r11
  setpt     res[r2], r9
  setpt     res[r3], r9
  setpt     res[r4], r9
  ldc       r11, 12
  out       res[r2], r11
  in        r11, res[r0]
  stw       r11, r6[1]
  ldc       r11, 9
  out       res[r3], r11
  ldc       r11, 11
  out       res[r4], r11
  in        r11, res[r0]
  stw       r11, r6[2]
  ldc       r11, 0x400
  out       res[r5], r11
  add       r9, r9, 2
  setpt     res[r1], r9
  ldc       r11, 0
  out       res[r1], r11
  ldc       r10, 3
  ldc       r2, 32
L2:
  in        r11, res[r0]
  stw       r11, r6[r10]
  add       r10, r10, 1
  lsu       r11, r10, r2
  bt        r11, L2
  ldw       r4, sp[1]
  ldw       r5, sp[2]
  ldw       r6, sp[3]
  ldw       r7, sp[4]
  ldw       r8, sp[5]
  ldw       r9, sp[6]
  ldw       r10, sp[7]
  retsp     8
