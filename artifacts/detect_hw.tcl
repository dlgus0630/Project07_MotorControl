open_hw_manager
connect_hw_server
open_hw_target
set devices [get_hw_devices]
puts "HW_DEVICES: $devices"
foreach d $devices {
    puts "DEVICE $d PART=[get_property PART $d]"
}
close_hw_target
disconnect_hw_server
close_hw_manager
