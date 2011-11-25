This repository holds nagios plugins that I've built


check_mysql_stat_delta
======================

Motivation
----------------------

Some of the mysql 'show status' variables just keep increasing in value as the server is running, for example 'Queries'. It would be nice to get a per second
value for these variables. This check will create a file to keep the time and previous value at the last execution. On each execution, it will get the new value
for the variable time and calculate :

> (delta time) / (delta value)