

PostgreSQL Backup in Linux



- Use pg_dump.exe
  location: ...PostgreSQL\x.x\bin\
- Command Line
  e.g. 1
  set -e
  set -o pipefail
  
  sendy_config="/var/www/html/includes/config.php"
  sendy_db_user=
  sendy_db_password=
  sendy_db_name=
  
  PostgreSQL\x.x\bin\pg_dump.exe -U "${sendy_db_user}" \
  -p"$"{sendy_db_password}" \
  "${sendy_db_name}" \
  | gzip > "/var/lib/sendy-backup/$(date +%F)_sendy.sql.gz"
  
  e.g. 2
  PostgreSQL\x.x\bin\pg_dump.exe --file=g:\test\asist_basico.backup  --format=custom --no-owner --compress=9 --ignore-version --host=localhost --port=5433 -U postgres asist_basico (db name)
- adsf


select * from information_schema.schemata  where schema_name='pgagent';

SELECT * FROM pgagent.pga_job;
SELECT * FROM pgagent.pga_jobAgent;
SELECT * FROM pgagent.pga_jobClass;
SELECT * FROM pgagent.pga_jobLog;
