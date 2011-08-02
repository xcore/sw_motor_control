Motor Control Platform Software Guide
=====================================


Introduction
++++++++++++

The XMOS motor control development platform is provided with a software framework and example control loop. This document provides information relating to the structure, implementation and use of the software modules that are specific to the motor control development platform.

For information on the XMOS Motor Control Development Platform hardware please see the Motor Control Platform Hardware Manual.


Software Modules
++++++++++++++++

The provided framework consists of a number of modules that provide functions that combined to provide an integrated control system. The provided application utilises modules that provide the following:

   * Pulse Width Modulation (PWM)
   * Quadrature Encoder Interface (QEI)
   * Analogue to Digital Converter (ADC) Interface
   * Hall Sensor Interface
   * Display & Shared IO Interface
   * Low Level Communications Interfaces (CAN and Ethernet)
   * Application Level Communications (Control Interfaces)
   * Computation blocks library


In contrast to a typical microcontroller, hardware interfaces that are implemented on XMOS devices are all described in software. This gives the developer the flexibility to implement or customise any interface they require. This gives designers wider options when selecting the ADC's or PWM schemes that are required for the solution that is being developed.

Each of the modules is discussed in detail in the sections below.

The modules listed above comprise of one or more threads. The architecture of the threads is shown in the figure \ref{fig_ThreadDiag}. 

