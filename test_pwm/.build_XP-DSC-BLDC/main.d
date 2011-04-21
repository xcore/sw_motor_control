./.build_XP-DSC-BLDC/main.o : $(patsubst %.h,$(TARGET_DIR)/%.hstat,$(filter $(NOTDIR_HEADER_FILES),xs1.h platform.h print.h pwm_cli.h pwm_service.h ))
