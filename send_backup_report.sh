#!/bin/bash


mymail(){ 
  sed 's/^/  /g' | mailx -s "$1" "$2"
}


BACKUP_LOG="$(echo /db2/db2[a-z][a-z][a-z]/backup.log)"
[ -f "$BACKUP_LOG" ] || BACKUP_LOG="$(echo /usr/sap/[A-Z][A-Z][A-Z]/backup.log)"
[ -f "$BACKUP_LOG" ] || BACKUP_LOG="$(find /usr/sap/HN[DQP]/HDB0[0-9]/`hostname`/trace/ -mtime -1 -name script_log_backup_\*)"

CRON_LOG=/var/log/cron
[ -f "$CRON_LOG" ] || CRON_LOG=/var/log/messages

hanabackupFiles(){
  find /usr/sap/HN[DQP]/H*0[0-9]/backup/data/* -mtime -1
}

{
  grep -E '/backupH?N?[DQP]?.sh' $CRON_LOG | tail -20
  echo '=================='
  tail -n 15 $BACKUP_LOG
  echo '=================='
  ls -lad /backup/DB2[A-Z][A-Z][A-Z]/[A-Z][A-Z][A-Z].0.db2[a-z][a-z][a-z].* /backup/SBO*/[bB]* `hanabackupFiles` 2>/dev/null
  echo '=================='
  du -hs /backup/DB2[A-Z][A-Z][A-Z]/[A-Z][A-Z][A-Z].0.db2[a-z][a-z][a-z].* /backup/SBO*/[bB]* `hanabackupFiles` 2>/dev/null
} | mymail "report backup $(hostname)" diogo.ti@malwee.com.br

