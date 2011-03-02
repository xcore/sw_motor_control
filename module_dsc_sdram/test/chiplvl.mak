xn = ../../app_pwm_test/src/XP-DSC-BLDC.xn
all: build
build:
	xcc -Wall -O2 -g ${xn} sdram_test.xc ../src/dsc_sdram.xc ../src/dsc_sdram_asm.S -I../src issim.s xsyscall.s -DCHIPLVL -DSDRAM_PACKET_NWORDS=32
install:
	xobjdump --split a.xe > /dev/null
	cp -f qsim.do /allhomes/larry/chip_sdram/verif_tests_hw/XS1-040/Z_Applications/sdram_dsc
	cp -f image_n0c0.elf /allhomes/larry/chip_sdram/verif_tests_hw/XS1-040/Z_Applications/sdram_dsc/binary0.elf
	rm -f image_n0c0.elf config.xml platform_def.xn program_info.txt
