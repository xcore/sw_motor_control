_ReadCtrlRegister:
  getr r2, 2
  ldc r3, 0
_ReadCtrlRegister_nid:
  shr r4, r2, 24
  mkmsk r11, 8
  and r4, r4, r11
  or r3, r3, r4
_ReadCtrlRegister_pid:
  shr r4, r2, 16
  mkmsk r11, 8
  and r4, r4, r11
  shl r3, r3, 8
  or r3, r3, r4
_ReadCtrlRegister_chid:
  shr r4, r2, 8
  mkmsk r11, 8
  and r4, r4, r11
  shl r3, r3, 8
  or r3, r3, r4
_ReadCtrlRegister_ss:
  mov r4, r2
  ldc r11, 0xc3
  eq r11, r0, r11
  bf r11, _RCRStartSend
  ldc r11, 1
  shl r11, r11, 16
  xor r4, r2, r11

_RCRStartSend:
  mov r11, r4
  shr r11, r11, 16
  shl r11, r11, 8
  or r11, r11, r0
  shl r11, r11, 8
  ldc r10, 12
  or r11, r11, r10
  setd res[r2], r11
_RCRStartSend_cmd:
  ldc r11, 0xc1
  outct res[r2], r11
  shr r11, r3, 16
  shr r10, r3, 8
  outt res[r2], r11
  outt res[r2], r10
  outt res[r2], r3
  shr r11, r1, 8
  outt res[r2], r11
  outt res[r2], r1
_RCRStartSend_end:
  outct res[r2], 0x01

_RCRStartSend_retmsg:
  inct  r0, res[r2]
  ldc r1, 0x03
  ldc r3, 0x04
  eq  r4, r1, r0
  bt  r4, _regRdValid
  eq  r4, r0, r3
  bt  r4, _regRdInvalid
  freer res[r2]
  retsp 0
_regRdValid:
  in r0, res[r2]
  chkct res[r2], 0x01
  freer res[r2]
  retsp 0

_regRdInvalid:
  chkct res[r2], 0x01
  freer res[r2]
  retsp 0
_WriteCtrlRegister:
  getr r5, 2
  ldc r3, 0

_WriteCtrlRegister_nid:
  shr r4, r5, 24
  mkmsk r11, 8
  and r4, r4, r11
  or r3, r3, r4
_WriteCtrlRegister_pid:
  shr r4, r5, 16
  mkmsk r11, 8
  and r4, r4, r11
  shl r3, r3, 8
  or r3, r3, r4
_WriteCtrlRegister_chid:
  shr r4, r5, 8
  mkmsk r11, 8
  and r4, r4, r11
  shl r3, r3, 8
  or r3, r3, r4
_WriteCtrlRegister_ss:
  mov r4, r5
  ldc r11, 0xc3
  eq r11, r0, r11
  bf r11, _WCRStartSend
  ldc r11, 1
  shl r11, r11, 16
  xor r4, r5, r11

_WCRStartSend:
  mov r11, r4
  shr r11, r11, 16
  shl r11, r11, 8
  or r11, r11, r0
  shl r11, r11, 8
  ldc r10, 12
  or r11, r11, r10
  setd res[r5], r11
_WCRStartSend_cmd:
  ldc r11, 0xc0
  outct res[r5], r11
  shr r11, r3, 16
  shr r10, r3, 8
  outt res[r5], r11
  outt res[r5], r10
  outt res[r5], r3
  shr r11, r1, 8
  outt res[r5], r11
  outt res[r5], r1
  out res[r5], r2
  ldc r11, 0x01
  outct res[r5], r11

_WCRStartSend_retmsg:
  inct r0, res [r5]
  ldc r1, 0x03
  ldc r3, 0x04
  eq  r4, r1, r0
  bt  r4, _regWrValid
  eq  r4, r0, r3
  bt  r4, _regWrInvalid
  freer res[r5]
  retsp 0

_regWrValid:
  chkct res[r5], 0x01
  freer res[r5]
  retsp 0

_regWrInvalid:
  chkct res[r5], 0x01
  freer res[r5]
  retsp 0
_WriteXlinkPassFailStub:
  getr r5, 2

  ldc r3, 0

_WriteXlinkPassFailStub_nid:
  shr r4, r5, 24
  mkmsk r11, 8
  and r4, r4, r11
  or r3, r3, r4

_WriteXlinkPassFailStub_pid:
  shr r4, r5, 16
  mkmsk r11, 8
  and r4, r4, r11

  mkmsk r11, 24
  and r1, r1, r11
  mov r11, r4
  shl r11, r11, 24
  or r1, r1, r11
  shl r3, r3, 8
  or r3, r3, r4

_WriteXlinkPassFailStub_chid:
  shr r4, r5, 8
  mkmsk r11, 8
  and r4, r4, r11
  shl r3, r3, 8
  or r3, r3, r4
_WriteXlinkPassFailStub_ss:
  mov r4, r5
  ldc r7, 0xc3
  ldc r11, 0xc3
  ldc r11, 1
  shl r11, r11, 24
  xor r4, r5, r11
_WXSStartSend:
  mov r11, r4
  shr r11, r11, 16
  shl r11, r11, 8
  or r11, r11, r7
  shl r11, r11, 8
  ldc r10, 12
  or r11, r11, r10
  setd res[r5], r11
  ldc r11, 0xc0
  outct res[r5], r11
  shr r11, r3, 16
  shr r10, r3, 8
  outt res[r5], r11
  outt res[r5], r10
  outt res[r5], r3
  shr r11, r0, 8
  outt res[r5], r11
  outt res[r5], r0
  out res[r5], r1
  ldc r11, 0x01
  outct res[r5], r11

_WXSStartSend_retmsg:
  inct r7, res [r5]
  ldc r8, 0x03
  ldc r3, 0x04
  eq  r4, r8, r7
  bt  r4, _regWrValid
  eq  r4, r7, r3
  bt  r4, _regWrInvalid
  freer res[r5]

  retsp 0

.globl _DoXlinkSyscall
.align 2
_DoXlinkSyscall:
  entsp 1
  mov r8, r0
  mov r9, r1
  mov r10, r2
_DoXlinkSyscall_cpuID:
  ldc r11, 0x30b
  get r0, ps[r11]
  shr r1, r0, 16
  zext r1, 8
  bt r1, _DoXlinkSyscall_lp
  bl _InitXlinkSyscall_Enable
_DoXlinkSyscall_lp:
  ldc r0, 0xc3
  ldc r1, 128
  bl _ReadCtrlRegister
  ldc r3, 1
  mkmsk r3, 32
  shr r3, r3, 1
  not r3, r3
  and r3, r0, r3
  bf r3, _DoXlinkSyscall_lp
_DoXlinkSyscall_dn:
  mov r0, r8
  mov r1, r9
  mov r2, r10
  bl _WriteXlinkPassFailStub
  clre
  waiteu

_InitXlinkSyscall_Enable:
  entsp 1
  ldc r0, 0xc3
  ldc r1, 128
  bl _ReadCtrlRegister
  mov r2, r0
_InitXlinkSysCall_setbit:
  ldc r4, 0x1
  shl r4, r4, 24
  shl r4, r4, 7
  or r2, r2, r4
_InitXlinkSysCall_baudRateA:
  mkmsk r4, 4
  shl r4, r4, 8
  mkmsk r3, 4
  or r4, r4, r3
  not r4, r4
  and r2, r2, r4
_InitXlinkSysCall_baudRateB:
  ldc r4, 5
  shl r4, r4, 8
  ldc r3, 5
  or r4, r4, r3
  or r2, r2, r4
_InitXlinkSysCall_resetXLinks:
  ldc r4, 0x1
  shl r4, r4, 24
  or r2, r2, r4
  ldc r0, 0xc3
  ldc r1, 128
  bl _WriteCtrlRegister
  retsp 1
