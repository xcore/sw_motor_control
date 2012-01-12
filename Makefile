# This variable should contain a space separated list of all
# the directories containing buildable applications (usually
# prefixed with the app_ prefix)
#
# If the variable is set to "all" then all directories that start with app_
# are built.
BUILD_SUBDIRS = app_dsc_demo app_basic_bldc app_control_board_demo app_control_board_test app_power_board_test test_hall test_pwm test_qei

XMOS_MAKE_PATH ?= ..
include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.toplevel
