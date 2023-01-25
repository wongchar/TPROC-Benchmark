proc wait_vu {} {
set x 0
set timerstop 0
while {!$timerstop} {
  incr x
  after 1000
  update
  if {  [ vucomplete ] } { set timerstop 1 }
  }
return
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
diset tpcc mysql_driver timed
print dict
vuset logtotemp 1
tcset logtotemp 1
tcset timestamps 1
tcset refreshrate 1
tcset unique 1
loadscript
vuset vu $::env(VU)
vucreate
tcstart
tcstatus
vurun
wait_vu
vudestroy
tcstop
