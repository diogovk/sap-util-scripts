#!/bin/bash


mymail(){ 
  sed 's/^/  /g' | mailx -s "$1" "$2"
}


BACKUP_LOG="$(echo /db2/db2[a-z][a-z][a-z]/backup.log)"
[ -f "$BACKUP_LOG" ] || BACKUP_LOG="$(echo /usr/sap/[A-Z][A-Z][A-Z]/backup.log)"

{
  grep /backup.sh /var/log/cron | tail -20
  echo '=================='
  tail -15 "$BACKUP_LOG"
  echo '=================='
  ls -lad /backup/DB2[A-Z][A-Z][A-Z]/[A-Z][A-Z][A-Z].0.db2[a-z][a-z][a-z].* /backup/SBO*/[bB]* 2>/dev/null
  echo '=================='
  du -hs /backup/DB2[A-Z][A-Z][A-Z]/[A-Z][A-Z][A-Z].0.db2[a-z][a-z][a-z].* /backup/SBO*/[bB]* 2>/dev/null
} | mymail "report backup $(hostname)" diogo.ti@malwee.com.br

