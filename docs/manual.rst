.. highlight:: bash

===========
User Manual
===========

Dock\ *Flow*
============

Syntax
------


Score\ *Flow*
=============

Options
-------

Advanced Use
------------
By using the **--write-only** flag, all input files will be written in the following scheme:
**PROJECT**.chemflow/ScoreFlow/**PROTOCOL**/**receptor**/

System Setup
    One can customize the system setup (**tleap.in**) inside a job.

Simulation protocol
    The procedures for each protocol can also be modified, the user must review "ScoreFlow.run.template".

The *run input files* for Amber and MM(PB,GB)-SA, namely:
min1.in, heat.in, equil.in, md.in ... can also be manually modified at wish :)
After the modifications, rerun ScoreFlow using \-\-run-only.
Lig\ *Flow*
===========

Options
-------

Advanced Options
----------------
