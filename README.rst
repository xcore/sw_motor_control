DSC
.......

:Stable release:  1.0.0

:Status:  under development

:Maintainer: https://github.com/DavidNorman


This is the demonstration software for the XMOS DSC motor control evaluation board

Key Features
============

   * Simple commutation of two BLDC motors

To Do
=====

   * Demo example controls the motors with the buttons and LCD.  Add instructions for using
     ethernet and CAN.

   * Allow motors to be controlled at different speeds.

Firmware Overview
=================

The software is split into modules, as describes below:

   :apps_control: Three example Java applications for external control of the demo.
   :app_basic_bldc: Simple 2 motor BLDC commutation example
   :app_dsc_demo: Currently non-functional example for FOC control
   :module_can: XMOS CAN module
   :module_dsc_adc: Interface to the on-board ADC
   :module_dsc_blocks: Useful code blocks, eg PID controller, spatial transforms, SIN tables.
   :module_dsc_comms: Code to bridge the ethernet/CAN into the main code loop
   :module_dsc_display: Module for operating the LCD and buttons
   :module_dsc_hall: Interface to the Hall sensors
   :module_dsc_logging: Used by the incomplete FOC code for logging data to the SDRAM.
   :module_dsc_pwm: Provides accurately timed PWM signals for the bridge drivers
   :module_dsc_qei: An example of a quadrature encoder interface
   :module_dsc_sdram: Provides read and write for the on-board SDRAM.  Used by the logging system.
   :module_ethernet: The XMOS ethernet MII module
   :module_locks: Software locks for the ethernet buffering
   :module_xmos_common: Common makefile and build tools
   :module_xtcp: An instance of the XMOS TCP/IP stack


Known Issues
============

   * CAN and Ethernet control are not enabled by default

Required Repositories
================

   * The xmos_mc is a standalone repository

Support
=======

Contact davidn@xmos.com for techincal support.



