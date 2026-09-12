source [file join [file dirname [info script]] common.tcl]
set ::env(PYTHON) $py
unset -nocomplain ::env(PYTHONHOME)
unset -nocomplain ::env(PYTHONPATH)
gate clear open_loop

set simdir [file join $root build laplace_open_loop_sim]
create_project -force laplace_open_loop_sim $simdir -part xc7a35tcpg236-1
add_rtl laplace
add_files -fileset sim_1 [file join $root laplace tb tb_laplace_motor.v]
set_property file_type Verilog [get_files *.v]
set_property top tb_laplace_motor [get_filesets sim_1]
set_property xsim.elaborate.relax true [get_filesets sim_1]
set_property xsim.simulate.runtime 0ns [get_filesets sim_1]
update_compile_order -fileset sim_1
launch_simulation -simset sim_1 -mode behavioral
run all
close_sim

set logpath [file join $simdir laplace_open_loop_sim.sim sim_1 behav xsim simulate.log]
if {![file exists $logpath]} {error "Simulation log missing: $logpath"}
set f [open $logpath r]
set log [read $f]
close $f
file mkdir [file join $root reports]
file copy -force $logpath [file join $root reports tb_laplace_motor.log]
if {[regexp {TEST FAIL|FATAL|ERROR:} $log] || ![string match "*TEST PASS tb_laplace_motor*" $log]} {
    error "FAILED tb_laplace_motor"
}
gate mark open_loop
puts "OPEN-LOOP XSIM PASS"
