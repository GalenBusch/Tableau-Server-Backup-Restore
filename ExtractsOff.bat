D:
cd "Tableau Server\packages\pgsql.20183.18.1019.1426\bin"
set PGPASSWORD=<your PG tblwgadmin password>
(
echo UPDATE SCHEDULES SET Active='f';
) | psql -h <server.url.com> -d workgroup -U tblwgadmin -p 8060
