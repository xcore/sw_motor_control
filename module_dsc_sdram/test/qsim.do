vcd file trace.vcd

# vcd add -r is recursive

# SDRAM
set sdram /XSystem/XNode_inst0
vcd add $sdram/sdram_clk
vcd add $sdram/sdram_cke
vcd add $sdram/sdram_cs
vcd add $sdram/sdram_ras
vcd add $sdram/sdram_cas
vcd add $sdram/sdram_we
vcd add $sdram/sdram_dq(15:0)
vcd add $sdram/sdram_addr(12:0)
vcd add $sdram/sdram_ba(1:0)
vcd add $sdram/sdram_dqm(1:0)

# Core 0
set xcore0 /XSystem/XNode_inst0/XS1_040_CHIP_TOP_inst/XS1_040_inst/XS1_040_i/XCoreTile0_OTP_IOCtl_inst/XCoreTile_inst/XCoreTile_i/xcoreTop_inst0
vcd add $xcore0/clk

# Current instruction
vcd add $xcore0/e2_pc(31:0)

# Port 16B
vcd add $xcore0/pipeStageE1E2_inst0/pipeStageE2_inst0/resourceManager_inst0/ports_inst0/portInOut16Bit_inst1/sReg_r
vcd add $xcore0/pipeStageE1E2_inst0/pipeStageE2_inst0/resourceManager_inst0/ports_inst0/portInOut16Bit_inst1/tReg_r
vcd add $xcore0/pipeStageE1E2_inst0/pipeStageE2_inst0/resourceManager_inst0/ports_inst0/portInOut16Bit_inst1/sRegSize_r
vcd add $xcore0/pipeStageE1E2_inst0/pipeStageE2_inst0/resourceManager_inst0/ports_inst0/portInOut16Bit_inst1/tRegSize_r

# Write-back result
vcd add $xcore0/regStackFile_inst0/writeTid
vcd add $xcore0/regStackFile_inst0/writeRegId1
vcd add $xcore0/regStackFile_inst0/writeData1

do $env(XMOS_ROOT)/arch_xcore_rtl/scripts/qsim/runAll.do
