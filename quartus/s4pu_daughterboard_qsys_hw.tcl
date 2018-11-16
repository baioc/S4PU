# TCL File Generated by Component Editor 13.0sp1
# Wed Nov 14 16:41:15 BRST 2018
# DO NOT MODIFY


# 
# s4pu_daughterboard_qsys "S4PU Daughterboard (Memory Bridge)" v16.0
# Gabriel B. Sant'Anna 2018.11.14.16:41:15
# A "daughterboard" module wrapping the Simple Forth Processing Unit and exposing external access to it's main memory.
# 

# 
# request TCL package from ACDS 13.1
# 
package require -exact qsys 13.1


# 
# module s4pu_daughterboard_qsys
# 
set_module_property DESCRIPTION "A \"daughterboard\" module wrapping the Simple Forth Processing Unit and exposing external access to it's main memory."
set_module_property NAME s4pu_daughterboard_qsys
set_module_property VERSION 16.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property GROUP "Embedded Processors"
set_module_property AUTHOR "Gabriel B. Sant'Anna"
set_module_property ICON_PATH ../docs/figures/misc/S4PU160VHD.png
set_module_property DISPLAY_NAME "S4PU Daughterboard (Memory Bridge)"
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property ANALYZE_HDL AUTO
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL S4PU_Daughterboard
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
add_fileset_file S4PU.vhd VHDL PATH vhdl/s4pu/S4PU.vhd
add_fileset_file S4PU_Control.vhd VHDL PATH vhdl/s4pu/S4PU_Control.vhd
add_fileset_file S4PU_Datapath.vhd VHDL PATH vhdl/s4pu/S4PU_Datapath.vhd
add_fileset_file S4PU_Daughterboard.vhd VHDL PATH vhdl/s4pu/S4PU_Daughterboard.vhd TOP_LEVEL_FILE
add_fileset_file LIFO_Stack.vhd VHDL PATH vhdl/sequential/LIFO_Stack.vhd
add_fileset_file Reg.vhd VHDL PATH vhdl/sequential/Reg.vhd
add_fileset_file ALU_16.vhd VHDL PATH vhdl/combinatorial/ALU_16.vhd
add_fileset_file Multiplexer.vhd VHDL PATH vhdl/combinatorial/Multiplexer.vhd
add_fileset_file onchip_ram.vhd VHDL PATH magic/onchip_ram/onchip_ram.vhd
add_fileset_file prog_rom.vhd VHDL PATH magic/prog_rom/prog_rom.vhd
add_fileset_file dual_ram.vhd VHDL PATH magic/dual_ram/dual_ram.vhd


# 
# parameters
# 
add_parameter ARCH POSITIVE 16 "Internal bus size, must be at least 16-bit."
set_parameter_property ARCH DEFAULT_VALUE 16
set_parameter_property ARCH DISPLAY_NAME ARCH
set_parameter_property ARCH TYPE POSITIVE
set_parameter_property ARCH ENABLED false
set_parameter_property ARCH UNITS None
set_parameter_property ARCH ALLOWED_RANGES 1:2147483647
set_parameter_property ARCH DESCRIPTION "Internal bus size, must be at least 16-bit."
set_parameter_property ARCH HDL_PARAMETER true


# 
# display items
# 
add_display_item "" Architecture GROUP ""
add_display_item Architecture ARCH PARAMETER ""


# 
# connection point clock_sink
# 
add_interface clock_sink clock end
set_interface_property clock_sink clockRate 0
set_interface_property clock_sink ENABLED true
set_interface_property clock_sink EXPORT_OF ""
set_interface_property clock_sink PORT_NAME_MAP ""
set_interface_property clock_sink SVD_ADDRESS_GROUP ""

add_interface_port clock_sink clock clk Input 1


# 
# connection point reset_sink
# 
add_interface reset_sink reset end
set_interface_property reset_sink associatedClock clock_sink
set_interface_property reset_sink synchronousEdges DEASSERT
set_interface_property reset_sink ENABLED true
set_interface_property reset_sink EXPORT_OF ""
set_interface_property reset_sink PORT_NAME_MAP ""
set_interface_property reset_sink SVD_ADDRESS_GROUP ""

add_interface_port reset_sink reset_n reset_n Input 1


# 
# connection point conduit_end
# 
add_interface conduit_end conduit end
set_interface_property conduit_end associatedClock clock_sink
set_interface_property conduit_end associatedReset reset_sink
set_interface_property conduit_end ENABLED true
set_interface_property conduit_end EXPORT_OF ""
set_interface_property conduit_end PORT_NAME_MAP ""
set_interface_property conduit_end SVD_ADDRESS_GROUP ""

add_interface_port conduit_end mode export Input 1


# 
# connection point avalon_slave
# 
add_interface avalon_slave avalon end
set_interface_property avalon_slave addressUnits WORDS
set_interface_property avalon_slave associatedClock clock_sink
set_interface_property avalon_slave associatedReset reset_sink
set_interface_property avalon_slave bitsPerSymbol 8
set_interface_property avalon_slave burstOnBurstBoundariesOnly false
set_interface_property avalon_slave burstcountUnits WORDS
set_interface_property avalon_slave explicitAddressSpan 0
set_interface_property avalon_slave holdTime 0
set_interface_property avalon_slave linewrapBursts false
set_interface_property avalon_slave maximumPendingReadTransactions 0
set_interface_property avalon_slave readLatency 0
set_interface_property avalon_slave readWaitTime 1
set_interface_property avalon_slave setupTime 0
set_interface_property avalon_slave timingUnits Cycles
set_interface_property avalon_slave writeWaitTime 0
set_interface_property avalon_slave ENABLED true
set_interface_property avalon_slave EXPORT_OF ""
set_interface_property avalon_slave PORT_NAME_MAP ""
set_interface_property avalon_slave SVD_ADDRESS_GROUP ""

add_interface_port avalon_slave ext_write write Input 1
add_interface_port avalon_slave ext_address address Input arch
add_interface_port avalon_slave ext_writedata writedata Input arch
add_interface_port avalon_slave ext_readdata readdata Output arch
set_interface_assignment avalon_slave embeddedsw.configuration.isFlash 0
set_interface_assignment avalon_slave embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment avalon_slave embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment avalon_slave embeddedsw.configuration.isPrintableDevice 0
