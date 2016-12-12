#!/bin/bash


set -e
# Exportacao da configuracao SAP
su - ecqadm -c 'R3trans -w EXPORTALL.log export_all.r3t'


su - db2ecq -c env > /backup/variaveis_ambiente_pre_refresh$(date -I).txt
su - db2ecq -c '/db2/db2ecq/sqllib/adm/db2set -all' > /backup/db2set_pre_refresh$(date -I).txt
su - db2ecq -c 'db2 get db cfg for ECQ' > /backup/db_cfg_ECQ$(date -I).txt || echo warn: failed to backup db configuration

su - db2ecq -c db2stop || echo warn: failed to stop db. Ignore if it\'s already stopped


mount | grep -q /mnt/ecplockbox || {
  mount  -o  nolock,rsize=8192,wsize=8192,intr  datadomain02:/data/col1/ecplockbox  /mnt/ecplockbox  -t  nfs
}

[ -f /opt/ddbda/config/db2_ddbda.cfg ] && {
  echo Fazendo backup do arquivo de configuração ddboost
  \cp /opt/ddbda/config/db2_ddbda.cfg /opt/ddbda/config/db2_ddbda.cfg.$(date -I)
} || true
echo Copiando arquivo de configuração do ECP para /opt/ddbda/config/db2_ddbda.cfg
\cp /opt/ddbda/config/db2_ddbda.cfg.ecp /opt/ddbda/config/db2_ddbda.cfg

# Descomente o seguinte, caso seja necessario reconfigurar o DDBoost
# /opt/ddbda/bin/ddbmadmin -P -z /opt/ddbda/config/db2_ddbda.cfg
# /opt/ddbda/bin/ddbmadmin -U



time su - db2ecq -c "db2start && \
db2 restore db ECP load /usr/lib/ddbda/lib64/libddboostdb2.so \
options @/opt/ddbda/config/db2_ddbda.cfg \
ON /db2/ECQ/sapdata1, /db2/ECQ/sapdata2, /db2/ECQ/sapdata3, /db2/ECQ/sapdata4 \
INTO ECQ \
LOGTARGET /backup/logs_restore/ \
WITH 3 BUFFERS \
REPLACE EXISTING \
PARALLELISM 2 \
WITHOUT PROMPTING " || {
  echo Comando de restore retornou $?
  echo Ignorando e continuando...
}

du -hs /backup/logs_restore/

su - db2ecq -c "db2 update db cfg for ECQ using MIRRORLOGPATH NULL"
su - db2ecq -c "db2 update db cfg for ECQ using NUM_LOG_SPAN 0"
su - db2ecq -c "db2 update db cfg for ECQ using MAX_LOG 0"
su - db2ecq -c "db2 update db cfg for ECQ using LOGFILSIZ 27500"
su - db2ecq -c "db2 update db cfg for ECQ using LOGPRIMARY 200"


# Remove o conf do DDBoost, pois ja houve caso em que
# o mesmo travou o rollforward
rm /opt/ddbda/config/db2_ddbda.cfg

time su - db2ecq -c "db2 rollforward db ECQ to end of logs and complete overflow log path '(/backup/logs_restore/)'" || {
  echo Erro ao fazer rollforward
  exit 5
}

# verificar quais das configuracoes a seguir podem ser aplicadas antes do rollforward
su - db2ecq -c "db2 update db cfg for ECQ using MIRRORLOGPATH NULL"
su - db2ecq -c "db2 update db cfg for ECQ using NUM_LOG_SPAN 0"
su - db2ecq -c "db2 update db cfg for ECQ using MAX_LOG 0"
su - db2ecq -c "db2 update db cfg for ECQ using LOGFILSIZ 27500"
su - db2ecq -c "db2 update db cfg for ECQ using LOGPRIMARY 200"

su - db2ecq -c "db2 update db cfg for ECQ using LOGARCHMETH1 OFF" || true

echo Copiando arquivo de configuracao do ddboost-ecq para /opt/ddbda/config/db2_ddbda.cfg
\cp -a /opt/ddbda/config/db2_ddbda.cfg.ecq /opt/ddbda/config/db2_ddbda.cfg


su - db2ecq -c "db2 'call get_dbsize_info(?,?,?,-1);'" | grep -A1 DATABASESIZE

su - db2ecq -c "db2 update db cfg for ECQ using LOGARCHMETH1 OFF" || true


echo 'Ative o banco com su - db2ecq -c "db2 activate db ECQ"'
su - db2ecq -c "db2 activate db ECQ" || {
  echo Falha ao fazer ativar o banco
#  exit 6
}

su - db2ecq -c "db2 grant SECADM on database to user sapecq" || true
su - db2ecq -c "db2 grant DBADM on database to user sapecq" || true

su - db2ecq -c bash << \EOF
set -e
db2 export to tables_to_transfer.del of del MODIFIED BY NOCHARDEL "select 'db2 transfer ownership of table ',substr(tabschema,1,6), '.\\\"',  substr(tabname,1,30), '\\\" to user SAPECQ preserve privileges' from syscat.tables where owner = 'SAPECP' and type = 'T'"
sed s/,//g tables_to_transfer.del > tables_to_transfer.bash
bash tables_to_transfer.bash
EOF

su - db2ecq -c bash << \EOF
db2 export to views_to_transfer.del of del MODIFIED BY NOCHARDEL "select 'db2 transfer ownership of view ',substr(tabschema,1,6) as TABSCHEMA, '.\\\"',  substr(tabname,1,30) as TABNAME, '\\\" to user SAPECQ preserve privileges' from syscat.tables where owner = 'SAPECP' and  type = 'V'"
sed s/,//g views_to_transfer.del > views_to_transfer.bash
bash views_to_transfer.bash
EOF


echo Liberando o SAP'*'
su - db2ecq -c "db2 \"update sapecp.usr02 set UFLAG=0 where BNAME='SAP*' and MANDT='300'\"";
su - db2ecq -c "db2 \"delete from sapecp.usr02 where BNAME='SAP*' and MANDT='300'\"";

echo Criando Indices
su - db2ecq -c 'db2 create index SAPECP.\"BKPF~Z09\"  on SAPECP.BKPF  \( \"MANDT\",\"AWSYS\" \) COLLECT SAMPLED DETAILED STATISTICS' &
su - db2ecq -c 'db2 create index SAPECP.\"COBK~Z09\"  on SAPECP.COBK  \( \"MANDT\",\"LOGSYSTEM\",\"AWSYS\" \) COLLECT SAMPLED DETAILED  STATISTICS' &
su - db2ecq -c 'db2 create index SAPECP.\"COEP~Z09\"  on SAPECP.COEP  \( \"MANDT\",\"LOGSYSO\",\"LOGSYSP\" \) COLLECT SAMPLED DETAILED  STATISTICS' &
su - db2ecq -c 'db2 create index SAPECP.\"COES~Z09\"  on SAPECP.COES  \( \"MANDT\",\"AWSYS\" \) COLLECT SAMPLED DETAILED  STATISTICS' &
su - db2ecq -c 'db2 create index SAPECP.\"COFIS~Z09\" on SAPECP.COFIS \( \"RCLNT\",\"LOGSYS\",\"RLOGSYS\",\"SLOGSYS\" \) COLLECT SAMPLED DETAILED  STATISTICS' &
su - db2ecq -c 'db2 create index SAPECP.\"GLPCP~Z09\" on SAPECP.GLPCP \( \"RCLNT\",\"AWSYS\",\"LOGSYS\" \) COLLECT SAMPLED DETAILED  STATISTICS' &
su - db2ecq -c 'db2 create index SAPECP.\"GLPCT~Z09\" on SAPECP.GLPCT \( \"RCLNT\",\"LOGSYS\" \) COLLECT SAMPLED DETAILED  STATISTICS' &
su - db2ecq -c 'db2 create index SAPECP.\"MKPF~Z09\"  on SAPECP.MKPF  \( \"MANDT\",\"AWSYS\" \) COLLECT SAMPLED DETAILED  STATISTICS' &
su - db2ecq -c 'db2 create index SAPECP.\"VBFA~Z09\"  on SAPECP.VBFA  \( \"MANDT\",\"LOGSYS\" \) COLLECT SAMPLED DETAILED  STATISTICS' &
su - db2ecq -c 'db2 create index SAPECP.\"SRRELROLES~Z09\" on SAPECP.SRRELROLES \( \"CLIENT\",\"LOGSYS\" \) COLLECT SAMPLED DETAILED  STATISTICS' &
su - db2ecq -c 'db2 create index SAPECP.\"FAGLFLEXA~Z09\"  on SAPECP.FAGLFLEXA  \( \"RCLNT\",\"LOGSYS\" \) COLLECT SAMPLED DETAILED  STATISTICS' &

wait


# Importacao da configuracao SAP
su - ecqadm -c 'R3trans -w IMPORTALL.log import_ALL.r3t'
#sap* pass
