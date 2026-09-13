open_hw_manager
connect_hw_server
open_hw_target
set device [lindex [get_hw_devices] 0]
current_hw_device $device
refresh_hw_device -update_hw_probes false $device
set_property PROGRAM.FILE {artifacts/laplace_pi_hybrid_telemetry.bit} $device
program_hw_devices $device
puts "PROGRAMMED $device with artifacts/laplace_pi_hybrid_telemetry.bit"
close_hw_target
disconnect_hw_server
close_hw_manager
