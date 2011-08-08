.. _sec_api:

API
===

.. _sec_conf_defines:

Configuration Defines
---------------------

The file dsc_config.h must be provided in the application source
code. This file can set the following defines:

**PWM_BLDC_MODE**

    With this set, the motor is spun using basic BLDC commutation. The PWM is
    single sided, with the high side of the half-bridge operated by the top level
    application.

**PWM_NOINV_MODE**

    With this set, the PWM is a non-inverted centre symmetric set of channels.

**PWM_INV_MODE**

    With this set, the PWM is an sinverted centre symmetric set of channels.

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
    electrical rotations to each physical rotation.

ADC
---

Client functions
++++++++++++++++

.. doxygenfunction:: do_adc_calibration

.. doxygenfunction:: get_adc_vals_raw

.. doxygenfunction:: get_adc_vals_calibrated_int16

Server functions
++++++++++++++++

.. doxygenfunction:: adc_7265_triggered

.. doxygenfunction:: adc_ltc1408_filtered

.. doxygenfunction:: adc_ltc1408_triggered

.. doxygenfunction:: run_adc_max1379

.. doxygenfunction:: do_lp_filter

QEI
---

Client functions
++++++++++++++++

.. doxygenfunction:: get_qei_position

.. doxygenfunction:: get_qei_speed

.. doxygenfunction:: qei_pos_known

.. doxygenfunction:: qei_cw

Server functions
++++++++++++++++

.. doxygenfunction:: do_qei


PWM
---

Client functions
++++++++++++++++

BLDC PWM mode
~~~~~~~~~~~~~

.. doxygenfunction:: update_pwm1

.. doxygenfunction:: update_pwm2

Inverting and non-inverting centre aligned PWM
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. doxygenfunction:: update_pwm

Server functions
++++++++++++++++

BLDC PWM mode
~~~~~~~~~~~~~

.. doxygenfunction:: do_pwm1

.. doxygenfunction:: do_pwm2

Inverting and non-inverting centre aligned PWM
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. doxygenfunction:: do_pwm

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

.. doxygenfunction:: lcd_data_out

.. doxygenfunction:: lcd_comm_out


Display and reset server
++++++++++++++++++++++++

.. doxygenfunction:: display_shared_io_motor

