.. _sec_api:

API
===

.. _sec_conf_defines:

Configuration Defines
---------------------

The file dsc_config.h must be provided in the application source
code. This file can set the following defines:

**PWM_DEAD_TIME**

    This is the period, in 10ns intervals, which is not counted towards the PWM
    time as the PWM is output.

**PWM_MAX_VALUE**

    The PWM input is clamped to this value

**LOCK_ADC_TO_PWM**

    If this is defined, the PWM outputs synchronization information to a channel
    and dummy port, allowing the ADC module to synchronize the ADC measurement
    to the dead time when all PWM channels are off.

**NUMBER_OF_POLES**

    This is the number of poles in the motor.  It is therefore ratio of the number of
    electrical rotations to each physical rotation. If a motor has a single winding per
    coil, then it is called a 2 pole motor. Two sets of windings per coil makes a
    four pole motor, and so on.

**USE_CAN**

    When defined, the CAN controller in included in the executable. This option is
    mutually exclusive with Ethernet.
    
**USE_ETH**

    When defined, the Ethernet controller is included in the executable.  This option is
    mutually exclusive with CAN.

**TCP_CONTROL_PORT**

    When the Ethernet controller is included, this is the TCP port that the server
    listens on, for receiving control information.

**MIN_RPM**

    The minimum RPM that the controllers can set.

**MAX_RPM**

    The maximum RPM that the controllers can set.

External modules
----------------

For documentation on the Ethernet, CAN and PWM modules, see the relevent XMOS software module documentation.


ADC
---

Client functions
++++++++++++++++

.. doxygenfunction:: do_adc_calibration

.. doxygenfunction:: get_adc_vals_calibrated_int16

Server functions
++++++++++++++++

.. doxygenfunction:: adc_7265_triggered

.. doxygenfunction:: adc_ltc1408_triggered

.. doxygenfunction:: run_adc_max1379

QEI
---

Client functions
++++++++++++++++

.. doxygenfunction:: get_qei_data

Server functions
++++++++++++++++

.. doxygenfunction:: do_qei

.. doxygenfunction:: do_multiple_qei



Hall sensors
------------

Client functions
++++++++++++++++

.. doxygenfunction:: get_hall_pos_speed_delta

.. doxygenfunction:: do_hall

.. doxygenfunction:: do_hall_select


Server functions
++++++++++++++++

.. doxygenfunction:: run_hall

.. doxygenfunction:: run_hall_speed

.. doxygenfunction:: run_hall_speed_timed_avg

.. doxygenfunction:: run_hall_speed_timed


Computational Blocks
--------------------

.. doxygenfunction:: park_transform

.. doxygenfunction:: inverse_park_transform

.. doxygenfunction:: clarke_transform

.. doxygenfunction:: inverse_clarke_transform

.. doxygenfunction:: sine

.. doxygenfunction:: cosine

Watchdog Timer
--------------

.. doxygenfunction:: do_wd


High level communications
-------------------------

Ethernet control
++++++++++++++++

.. doxygenfunction:: do_comms_eth

CAN control
+++++++++++

.. doxygenfunction:: do_comms_can


LCD display and PHY reset
-------------------------

LCD
+++

.. doxygenstruct:: lcd_interface_t

.. doxygenfunction:: reverse

.. doxygenfunction:: itoa

.. doxygenfunction:: lcd_ports_init

.. doxygenfunction:: lcd_byte_out

.. doxygenfunction:: lcd_clear

.. doxygenfunction:: lcd_draw_image

.. doxygenfunction:: lcd_draw_text_row


