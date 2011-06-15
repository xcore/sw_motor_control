.globl issim
.globl issim.nstackwords
.linkset issim.nstackwords, 1
issim:
  entsp 1
  ldc r0, 99  // OSCALL_IS_SIMULATION
  bl _DoSyscall
  eq r0, r0, 1
  retsp 1
