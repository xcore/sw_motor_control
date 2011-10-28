Motor Control Platform Software Guide
=====================================

Introduction
++++++++++++

The XMOS motor control development platform is provided with a software framework and example control loop. This document provides information relating to the structure, implementation and use of the software modules that are specific to the motor control development platform, and interfacing to associated peripheral modules such as the CAN component.

For information on the XMOS Motor Control Development Platform hardware please see the Motor Control Platform Hardware Manual.


Software Modules
++++++++++++++++

The framework consists of a number of modules that provide functions for an integrated control system. The application utilises modules that provide the following:

   * Pulse Width Modulation (PWM)
   * Quadrature Encoder Interface (QEI)
   * Analogue to Digital Converter (ADC) Interface
   * Hall Sensor Interface
   * Display Interface
   * Application Level Communications (Control Interfaces)
   * Computation blocks library

The system utilizes the XMOS standard open source IP blocks for low level Ethernet and CAN interfaces.

In contrast to a typical microcontroller, hardware interfaces are implemented on XMOS devices in software. This gives the developer the flexibility to implement or customise any interface they require. Designers have a greater number of options when selecting ADC's, PWM schemes or control and measurement interfaces.

The modules listed above are implemented in one or more processor threads. The architecture of the threads is shown below for both the basic BLDC and FOC configurations. The red and green components show the optional control threads for ethernet and CAN.

Simple BLDC commutation thread diagram
======================================

   .. image:: images/bldc-thread.*
      :width: 100%

Field Oriented Control thread diagram
=====================================

   .. image:: images/foc-thread.*
      :width: 100%

In the diagrams, the rectangular blocks are ports, the circles are threads, the solid lines are channel communication, and the dotted lines are port IO.

The ethernet control threads are shown in green, and the CAN threads are shown in red.  The system can function with either the CAN or ethernet control,
methods, or with neither of them.

.. toctree::
   :maxdepth: 2

   apps
   blocks
   display
   pwm
   adc
   comms-high
   hsi
   qei
   api
   resources



