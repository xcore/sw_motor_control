# Custom Stuff
BUILD_FLAGS=
XCC_FLAGS= -O3 -g -report
# additional XCC flags for xscope library '-lxscope'

APP_NAME=dsc_basic_bldc

# Standard stuff below here...
TARGET = XP-DSC-BLDC
BASE_DIR = .

DSC_BASIC_BLDC_DIRS = src src/motor src/control src/utilities src/ethernet

SOURCE_DIRS += $(DSC_BASIC_BLDC_DIRS)
INCLUDE_DIRS += $(DSC_BASIC_BLDC_DIRS)

USED_MODULES = module_dsc_hall.1v0alpha4 module_dsc_pwm.1v0alpha4 module_dsc_display.1v0module_dsc_display2 module_dsc_blocks.1v0alpha4
USED_MODULES += module_ethernet module_locks module_xtcp module_dsc_comms module_can.0v1alpha1

USE_XTCP_MAC_CUSTOM_FILTER=1

include ../module_xmos_common/build/Makefile.common

clean: clean_common

all: $(BIN_DIR)/$(APP_NAME).xe
	@echo Build complete

