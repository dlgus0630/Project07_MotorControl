set root [file normalize [file join [file dirname [info script]] ..]]
open_project [file join $root build laplace laplace.xpr]
open_run impl_1

# The default route missed setup by 0.113 ns. Optimize the already-routed design,
# reroute changed nets, and only write a bitstream after independent timing/DRC checks.
phys_opt_design -directive AggressiveExplore
route_design -directive AggressiveExplore

set out [file join $root reports laplace_hybrid_postroute]
file mkdir $out
report_utilization -file [file join $out utilization.rpt]
report_timing_summary -report_unconstrained -file [file join $out timing.rpt]
report_drc -file [file join $out drc.rpt]
check_timing -verbose -file [file join $out check_timing.rpt]

foreach type {max min} {
    set path [get_timing_paths -delay_type $type -max_paths 1]
    if {[llength $path] != 1} {error "No timing path found for $type"}
    set slack [get_property SLACK $path]
    puts "FINAL $type SLACK $slack ns"
    if {$slack < 0} {error "Timing failed ($type): $slack ns"}
}
set violations [get_drc_violations -quiet -filter {SEVERITY == Error}]
if {[llength $violations] > 0} {error "DRC errors; bitstream blocked"}

write_checkpoint -force [file join $out laplace_pi_hybrid_telemetry.dcp]
write_bitstream -force [file join $out laplace_pi_hybrid_telemetry.bit]
puts "HYBRID POST-ROUTE BUILD PASS"
