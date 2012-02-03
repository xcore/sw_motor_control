Advanced Motor Control 
.......................

:Stable release:  2.0

:Status:  Design Ready

:Maintainer: https://github.com/DavidNorman

Firmware and documentation to go with the XMOS XK-MC-LVM2 and XP-MC-CTRL-L2 Motor Control Development Kits.

Key Features
============

   * Dual Axis Field Oriented Control (Speed Control) of PMSM Motors
   * Dual Axis Trapezoidal Commutation (Speed Control) of BLDC Motors
   * Up to 142kHz inner loop performance
   * Complementary PWM up to 48 KHz at 11-bit complementary PWM resolution  
   * CAN or Ethernet interface with LabView GUI, or use push-button control
   * Component based approach to motor drive and communications interfaces

Firmware Overview
=================

The software is split into modules and applicatons, as describes below:

============== ======================= =====================================================================
Type           Name                    Description
-------------- ----------------------- ---------------------------------------------------------------------  
Application    app_dsc_demo            Fully functional dual axis FOC speed control of two LDO PMSM motors 
Application    app_control_board_demo  Standalone control board demonstration example                                                                 
Application    app_basic_bldc          Simple dual axis motor BLDC trapezoidal commutation example         
Application    app_power_board_test    Manufacturing test sw for power board                               
Application    app_control_board_test  Manufacturing test sw for power board                               
Host Software  gui                     LabView gui for ethernet or CAN control of dev board from PC        
Component      module_dsc_adc          Interfaces to various external ADCs for current sampling            
Component      module_dsc_blocks       Inner loop transforms (e.g. park, clarke, PI)                       
Component      module_dsc_comms        Code to bridge the ethernet/CAN into the main code loop             
Component      module_dsc_display      Module for operating the LCD and buttons                            
Component      module_dsc_hall         Interface to Hall sensors (only used for BLDC commutation)           
Component      module_dsc_qei          A quadrature encoder interface                 
============== ======================= =====================================================================


Required Modules
================

In addition, the code imports and uses the following components from the xcore github repos:

============ ======================================= ============================================
Type         Name                                    Description
------------ --------------------------------------- --------------------------------------------
Component    git://github.com/xcore/sc_ethernet.git  Ethernet MII module
Component    git://github.com/xcore/sc_xtcp.git      TCP/IP stack
Component    git://github.com/xcore/sc_can.git       CAN phy/mac module
Component    git://github.com/xcore/sc_pwm.git       PWM module
Component    git://github.com/xcore/xcommon.git      Common makefile and build tools
============ ======================================= ============================================
 

Known Issues
============

See CHANGELOG.rst

Documentation
=============

http://github.xcore.com/sw_motor_control

Getting Started and Installation
================================

If you have purchased one of the XMOS motor control kits (available from digikey), the doc directory contains a quickstart guide to get your board up and running quickly. The doc directory also contains a user guide for the motor control application firmware and components. 

Support
=======

Issues may be submitted via the Issues tab in this github repo. Response to any issues submitted as at the discretion of the manitainer for this line.





