#!/bin/bash

# This script is used to alert about failures in archiving logs

mymail(){
  sed 's/^/  /g' | mailx -s "$1" "$2"
}

TMPFILE=$(mktemp)
set -e
db2diag -H 1h | grep -B7 'Unable to archive log file .* from failarchpath' | grep -E 'LEVEL:|Unable to archive log|--' > $TMPFILE

(head -100 ; echo -e "\n####[REDACTED]###########################################\n" ; tail -100 ) < $TMPFILE | mymail "DB2 ALERT $(hostname)" basis@malwee.com.br

