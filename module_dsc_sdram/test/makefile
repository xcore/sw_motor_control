xn = ../../app_pwm_test/src/XP-DSC-BLDC.xn
all:
	xcc -Wall -O2 -g ${xn} sdram_test.xc ../src/dsc_sdram.xc ../src/dsc_sdram_asm.S -I../src issim.s -DSDRAM_PACKET_NWORDS=32
