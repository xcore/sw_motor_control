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
   * Display & Shared IO Interface
   * Low Level Communications Interfaces (CAN and Ethernet)
   * Application Level Communications (Control Interfaces)
   * Computation blocks library


In contrast to a typical microcontroller, hardware interfaces are implemented on XMOS devices in software. This gives the developer the flexibility to implement or customise any interface they require. This gives designers wider options when selecting ADC's or PWM schemes.

The modules listed above are implemented in one or more processor threads. The architecture of the threads is shown below.

   .. image:: images/threadDiag.png






