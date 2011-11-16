Resource usage
==============

The table shows the resource usage for the main components in the system.  The
transforms are a functional library and thus do not have a thread or port usage.


+------------+-----------+------------+--------------+-----------+----------+
| Component  | Threads   | Memory     | Channel Ends | 1b Ports  | 4b ports |
+------------+-----------+------------+--------------+-----------+----------+
| ADC        | 1         | 2.2KB      | 2            | 4         | 1        |
+------------+-----------+------------+--------------+-----------+----------+
| PWM        | 1         | 2.8KB      | 2            | 6         | 0        |
+------------+-----------+------------+--------------+-----------+----------+
| Transforms | 0         | 264B       | 0            | 0         | 0        |
+------------+-----------+------------+--------------+-----------+----------+
| QEI        | 1         | 400B       | 1            | 0         | 1        |
+------------+-----------+------------+--------------+-----------+----------+
| Watchdog   | 1         | 120B       | 1            | 1         | 0        |
+------------+-----------+------------+--------------+-----------+----------+
| PID        | 0         | 300B       | 0            | 0         | 0        |
+------------+-----------+------------+--------------+-----------+----------+

See the documentation for the ethernet and CAN software components for their
resource usage.

MIPS
----

This table shows the FOC control loop worst case timing, against the number of threads
running in the motor control core. These values were measured on a 500MHz core.

+-------------------+-----------------+------------+
| Number of threads | MIPS per thread | Loop time  |
+-------------------+-----------------+------------+
| 4                 | 125             | 7.9 us     |
+-------------------+-----------------+------------+
| 5                 | 100             | 10 us      |
+-------------------+-----------------+------------+
| 6                 | 83.3            | 12 us      |
+-------------------+-----------------+------------+
| 7                 | 71.4            | 14 us      |
+-------------------+-----------------+------------+
| 8                 | 62.5            | 16 us      |
+-------------------+-----------------+------------+

For a single motor, using PWM, ADC, QEI and a control loop, only 4 threads are required on
the motor core. Another core can be used to provide further functionality, or for a single
motor, the remaining 4 threads in the motor core can be used for control and IO, giving a
single core FOC motor control solution.

A dual motor, single core FOC solution can be created, by using the dual-QEI mode of the
QEI server.  The threads for such a solution would be:

  * PWM for motor 1
  * PWM for motor 2
  * dual QEI
  * Control loop for motor 1
  * Control loop for motor 2
  * ADC
  * Watchdog and main application
  * CAN PHY interface


