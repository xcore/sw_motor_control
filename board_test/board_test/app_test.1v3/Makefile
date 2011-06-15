TARGET ?= xp-dsc-bldc
BASE_DIR = .

DEMO_SOURCE_DIRS = src src/display src/sdram src/i2c_adc

SOURCE_DIRS += $(DEMO_SOURCE_DIRS) 

INCLUDE_DIRS += $(DEMO_SOURCE_DIRS) ../../shared

XCC_FLAGS += -save-temps -Wall -g -O3 -fsubword-select -report -lflash -DMAC_CUSTOM_FILTER

USED_MODULES = module_ethernet.1v3

include $(BASE_DIR)/../module_xmos_common.1v0/build/Makefile.common

all: $(BIN_DIR)/dsc_board_test.xe
	@echo Build complete

clean: clean_common
