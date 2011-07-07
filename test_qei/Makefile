# Custom Stuff
BUILD_FLAGS=
XCC_FLAGS= -fsubword-select -Wall -O3 -g -report -DFAULHABER_MOTOR

APP_NAME=test_qei

# Standard stuff below here...
TARGET = XP-DSC-BLDC
BASE_DIR = .

DSC_BASIC_BLDC_DIRS = src

SOURCE_DIRS += $(DSC_BASIC_BLDC_DIRS)
INCLUDE_DIRS += $(DSC_BASIC_BLDC_DIRS)

USED_MODULES  = module_dsc_display module_dsc_qei

USE_XTCP_MAC_CUSTOM_FILTER=1

include ../module_xmos_common/build/Makefile.common

clean: clean_common

all: $(BIN_DIR)/$(APP_NAME).xe
	@echo Build complete

