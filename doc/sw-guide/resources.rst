Resource usage
==============

The table shows the resource usage for the main components in the systemm.  The
transforms are a functional library and thus do not have a thread or port usage.


+------------+-----------+------------+--------------+-----------+----------+
| Component  | Threads   | Memory     | Channel Ends | 1b Ports  | 4b ports |
+------------+-----------+------------+--------------+-----------+----------+
| ADC        | 1         |            | 2            |           |          |
+------------+-----------+------------+--------------+-----------+----------+
| PWM        | 1         |            | 2            | 6         | 0        |
+------------+-----------+------------+--------------+-----------+----------+
| Transforms | 0         |            | 0            | 0         | 0        |
+------------+-----------+------------+--------------+-----------+----------+
| QEI        | 1         |            |              | 0         | 1        |
+------------+-----------+------------+--------------+-----------+----------+
| Watchdog   | 1         |            | 1            | 1         | 0        |
+------------+-----------+------------+--------------+-----------+----------+

See the documentation for the ethernet and CAN software components for their
resource usage.

MIPS
----

Loop timing per MIPS available.


