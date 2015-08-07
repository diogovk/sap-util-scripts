#!/bin/bash


ansible -u root sap_db2 -m shell -a 'if su - {{DB2USER}} -c "db2diag -H 10m | grep \"Unable to archive log file\" " 
then exit 1
else exit 0
fi'

