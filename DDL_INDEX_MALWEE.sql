CREATE INDEX "SAPECP"."BKPF~Z09"       ON "SAPECP"."BKPF"       ("MANDT",  "AWSYS")                  COLLECT    SAMPLED  DETAILED  STATISTICS;
CREATE INDEX "SAPECP"."COBK~Z09"       ON "SAPECP"."COBK"       ("MANDT",  "LOGSYSTEM",   "AWSYS")   COLLECT    SAMPLED  DETAILED  STATISTICS;
CREATE INDEX "SAPECP"."COEP~Z09"       ON "SAPECP"."COEP"       ("MANDT",  "LOGSYSO",     "LOGSYSP") COLLECT    SAMPLED  DETAILED  STATISTICS;
CREATE INDEX "SAPECP"."COES~Z09"       ON "SAPECP"."COES"       ("MANDT",  "AWSYS")                  COLLECT    SAMPLED  DETAILED  STATISTICS;
CREATE INDEX "SAPECP"."COFIS~Z09"      ON "SAPECP"."COFIS"      ("RCLNT",  "LOGSYS",      "RLOGSYS", "SLOGSYS") COLLECT SAMPLED DETAILED STATISTICS;
CREATE INDEX "SAPECP"."GLPCP~Z09"      ON "SAPECP"."GLPCP"      ("RCLNT",  "AWSYS",       "LOGSYS")  COLLECT    SAMPLED  DETAILED  STATISTICS;
CREATE INDEX "SAPECP"."GLPCT~Z09"      ON "SAPECP"."GLPCT"      ("RCLNT",  "LOGSYS")      COLLECT    SAMPLED    DETAILED  STATISTICS;
CREATE INDEX "SAPECP"."MKPF~Z09"       ON "SAPECP"."MKPF"       ("MANDT",  "AWSYS")       COLLECT    SAMPLED    DETAILED  STATISTICS;
CREATE INDEX "SAPECP"."SRRELROLES~Z09" ON "SAPECP"."SRRELROLES" ("CLIENT", "LOGSYS")      COLLECT    SAMPLED    DETAILED  STATISTICS;
CREATE INDEX "SAPECP"."FAGLFLEXA~Z09"  ON "SAPECP"."FAGLFLEXA"  ("RCLNT",  "LOGSYS")      COLLECT    SAMPLED    DETAILED  STATISTICS; 
CREATE INDEX "SAPECP"."VBFA~Z09"      ON "SAPECP"."VBFA"      ("MANDT",  "LOGSYS")      COLLECT    SAMPLED    DETAILED  STATISTICS 
