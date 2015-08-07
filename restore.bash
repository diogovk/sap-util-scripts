#!/bin/bash

# script to test restore in another machine

set -e

mount | grep -q /mnt/ecplockbox || {
  mount  -o  nolock,rsize=8192,wsize=8192,intr  datadomain02:/data/col1/ecplockbox  /mnt/ecplockbox  -t  nfs
}

su - db2ecp -c db2stop 

[ ! -f /opt/ddbda/config/db2_ddbda.cfg -a -f /opt/ddbda/config/db2_ddbda.cfg.disabled ] && {
  echo Reativando configuracao /opt/ddbda/config/db2_ddbda.cfg.disabled "->" /opt/ddbda/config/db2_ddbda.cfg
  mv /opt/ddbda/config/db2_ddbda.cfg.disabled /opt/ddbda/config/db2_ddbda.cfg
} || true

time su - db2ecp -c "db2start && db2 restore db ECP \
load /usr/lib/ddbda/lib64/libddboostdb2.so \
open 4 sessions \
options @/opt/ddbda/config/db2_ddbda.cfg \
LOGTARGET /backup/logs_restore/ \
REPLACE EXISTING \
WITHOUT PROMPTING " || {
  echo Comando de restore retornou $?
}

du -hs /backup/logs_restore/

time su - db2ecp -c "db2 rollforward db ECP to end of logs and complete overflow log path '(/backup/logs_restore/)'" || {
  echo Erro ao fazer rollforward
  exit 5
}

su - db2ecp -c "db2 'call get_dbsize_info(?,?,?,-1);'" | grep -A1 DATABASESIZE

su - db2ecp -c "db2 activate db ECP" || {
  echo Falha ao fazer ativar o banco
  exit 6
}

mv /opt/ddbda/config/db2_ddbda.cfg /opt/ddbda/config/db2_ddbda.cfg.disabled
echo DDBoost \"desabilitado\"
echo Lembre-se de verificar a configuracao LOG_MIRROR

su - db2ecp -c "db2 \"update sapecp.usr02 set UFLAG=0 where BNAME='SAP*' and MANDT='300'\"";
su - db2ecp -c "db2 \"delete from sapecp.usr02 where BNAME='SAP*' and MANDT='300'\"";

#sap* pass
