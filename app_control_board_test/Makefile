# Custom Stuff
BUILD_FLAGS=
XCC_FLAGS= -O3 -g -report

APP_NAME=app_control_board_test

# Standard stuff below here...
TARGET = XS1-L2A-QF124
BASE_DIR = .


SOURCE_DIRS = src
INCLUDE_DIRS = src

USED_MODULES = module_dsc_display

include ../module_xmos_common/build/Makefile.common

clean: clean_common

all: $(BIN_DIR)/$(APP_NAME).xe
	@echo Build complete

