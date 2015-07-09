#!/bin/bash


su - db2ecq -c bash << \EOF
set -e
db2 export to views_to_transfer.del of del MODIFIED BY NOCHARDEL "select 'db2 transfer ownership of view ',substr(tabschema,1,6), '.\\\"',  substr(tabname,1,30), '\\\" to user SAPECQ preserve privileges' from syscat.tables where owner = 'SAPECP' and type = 'V'" 
sed s/,//g views_to_transfer.del > views_to_transfer.bash
bash views_to_transfer.bash
EOF



su - db2ecq -c bash << \EOF
set -e
db2 export to tables_to_transfer.del of del MODIFIED BY NOCHARDEL "select 'db2 transfer ownership of table ',substr(tabschema,1,6), '.\\\"',  substr(tabname,1,30), '\\\" to user SAPECQ preserve privileges' from syscat.tables where owner = 'SAPECP' and type = 'T'" 
sed s/,//g tables_to_transfer.del > tables_to_transfer.bash
bash tables_to_transfer.bash
EOF

