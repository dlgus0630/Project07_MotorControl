set root [file normalize [file join [file dirname [info script]] ..]]
create_project -force dev_hybrid_check [file join $root build dev_hybrid_check] -part xc7a35tcpg236-1
add_files [glob [file join $root common *.v]]
add_files [glob [file join $root laplace rtl *.v]]
set_property file_type Verilog [get_files *.v]
add_files -fileset sim_1 [file join $root laplace tb tb_encoder_hybrid.v]
set_property top tb_encoder_hybrid [get_filesets sim_1]
set_property xsim.simulate.runtime 0ns [get_filesets sim_1]
update_compile_order -fileset sim_1
reset_simulation -simset sim_1 -mode behavioral
launch_simulation -simset sim_1 -mode behavioral
run all
close_sim
