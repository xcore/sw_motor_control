# Custom Stuff
BUILD_FLAGS=
XCC_FLAGS= -fsubword-select -Wall -O3 -g -report -lxscope
# add -lxscope to the end of the compiler flags to include xscope library

APP_NAME=dsc_foc_demo

# Standard stuff below here...
TARGET = XP-DSC-BLDC
BASE_DIR = .

DSC_BASIC_BLDC_DIRS = src src/ethernet src/motor src/utilities

SOURCE_DIRS += $(DSC_BASIC_BLDC_DIRS)
INCLUDE_DIRS += $(DSC_BASIC_BLDC_DIRS)

USED_MODULES  = module_can.0v1alpha1 module_dsc_adc.1v0alpha4 module_dsc_blocks.1v0alpha4 module_dsc_comms.1v0alpha3 
USED_MODULES += module_dsc_display module_dsc_hall module_dsc_logging 
USED_MODULES += module_dsc_pwm module_dsc_sdram module_ethernet module_locks module_xtcp
USED_MODULES += module_dsc_qei

USE_XTCP_MAC_CUSTOM_FILTER=1

include ../module_xmos_common/build/Makefile.common

clean: clean_common

all: $(BIN_DIR)/$(APP_NAME).xe
	@echo Build complete

