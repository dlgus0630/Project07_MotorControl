source [file join [file dirname [info script]] common.tcl]
source [file join $root vivado laplace_config.tcl]
if {$laplace_mode ni {internal open_loop closed_loop}} {error "laplace_mode must be internal, open_loop, or closed_loop"}
set external [expr {$laplace_mode ne "internal"}]
set open_loop [expr {$laplace_mode eq "open_loop"}]
# Open-loop uses raw pulse display; 256 keeps the unused normalization path timing-safe.
set counts 256
if {$laplace_mode eq "closed_loop"} {
    if {![string is integer -strict $laplace_counts_full_scale] || $laplace_counts_full_scale<=0} {
        error "Set measured laplace_counts_full_scale before closed_loop. Use open_loop to measure pulses first."
    }
    set counts $laplace_counts_full_scale
}
create_project -force laplace [file join $root build laplace] -part xc7a35tcpg236-1
add_rtl laplace
set_property top laplace_basys3_top [current_fileset]
set_property generic [list EXTERNAL_MOTOR=$external OPEN_LOOP=$open_loop ENCODER_COUNTS_FULL_SCALE=$counts] [current_fileset]
add_files -fileset constrs_1 [file join $root laplace constraints basys3.xdc]
update_compile_order -fileset sources_1
puts "PROJECT CREATED: laplace_mode=$laplace_mode; no synthesis has run."
