#!/bin/bash


mymail(){ 
  sed 's/^/  /g' | mailx -s "$1" "$2"
}

{
  grep /backup.sh /var/log/cron | tail -20
  echo '=================='
  tail -15 /db2/db2smn/backup.log
  echo '=================='
  ls -lad /backup/DB2SMN/SMN.0.db2smn.*
  echo '=================='
  du -hs /backup/DB2SMN/SMN.0.db2smn.*
} | mymail "report backup $(hostname)" diogo.ti@malwee.com.br

