global complete
proc wait_to_complete {} {
global complete
set complete [vucomplete]
if (!$complete) {after 5000 wait_to_complete} else { exit }
}

dbset db mysql
dbset bm tpcc
diset connection mysql_host $::env(DBHOST)
diset connection mysql_port $::env(DBPORT)
diset tpcc mysql_user $::env(MYSQL_USER)
diset tpcc mysql_pass $::env(MYSQL_PASSWORD)
diset tpcc mysql_count_ware $::env(WH)
diset tpcc mysql_num_vu $::env(VU)
diset tpcc mysql_dbase tpcc
diset tpcc mysql_storage_engine innodb
diset tpcc mysql_partition true
print dict
buildschema
wait_to_complete
