set root [file normalize [file join [file dirname [info script]] ..]]
open_project [file join $root build laplace laplace.xpr]
open_run impl_1

# Hysteresis fix (HIGH/LOW_COUNT_THRESHOLD=14/10) added a small amount of logic to
# encoder_speed_hybrid; default route missed setup by only -0.015 ns. Same remedy as
# the first hybrid build: optimize the already-routed design and reroute changed nets.
phys_opt_design -directive AggressiveExplore
route_design -directive AggressiveExplore

set out [file join $root reports laplace_hybrid_fix_postroute]
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

write_checkpoint -force [file join $out laplace_pi_hybrid_telemetry_fixed.dcp]
write_bitstream -force [file join $out laplace_pi_hybrid_telemetry_fixed.bit]
puts "HYBRID FIX POST-ROUTE BUILD PASS"
