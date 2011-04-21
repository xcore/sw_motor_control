# Custom Stuff
BUILD_FLAGS=
XCC_FLAGS= -O3 -g -report
# additional XCC flags for xscope library '-lxscope'

APP_NAME=test_pwm

# Standard stuff below here...
TARGET = XP-DSC-BLDC
BASE_DIR = .

DSC_BASIC_BLDC_DIRS = src

SOURCE_DIRS += $(DSC_BASIC_BLDC_DIRS)
INCLUDE_DIRS += $(DSC_BASIC_BLDC_DIRS)

USED_MODULES = module_dsc_pwm.1v0alpha4

include ../module_xmos_common/build/Makefile.common

clean: clean_common

all: $(BIN_DIR)/$(APP_NAME).xe
	@echo Build complete

