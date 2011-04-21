./.build_XP-DSC-BLDC/pwm_service.o : $(patsubst %.h,$(TARGET_DIR)/%.hstat,$(filter $(NOTDIR_HEADER_FILES),dsc_pwm_common.h pwm_service.h pwm_service_inv.h pwm_service_noinv.h pwm_service_bldc.h ))
