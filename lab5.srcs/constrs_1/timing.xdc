# Timing constraints for the Accelerometer SPI port

# clock used to latch data to/from accelerometer
set sclk_ratio 100 
create_generated_clock -name sclk -source [get_ports CLK100MHZ] -divide_by $sclk_ratio [get_ports ACL_SCLK]

# Relax constraints between clocks
# MOSI
# Setup check is launched on sys_clk_pin where sclk is falling and latched on next sclk rising edge
# Hold check is launched on sys_clk_pin where sclk is falling and latched on previous sclk rising edge
set_multicycle_path -setup -start -from [get_clocks sys_clk_pin] -to [get_clocks sclk] [expr $sclk_ratio/2]
set_multicycle_path -hold -start -from [get_clocks sys_clk_pin] -to [get_clocks sclk] [expr $sclk_ratio-1]

# MISO
# Setup check is launched on sclk falling edge and latched on sys_clk_pin associated with next sclk rising edge
# Hold check is launched on sclk falling edge and latched on sys_clk_pin associated with previous sclk rising edge
set_multicycle_path -setup -end -from [get_clocks sclk] -to [get_clocks sys_clk_pin] [expr $sclk_ratio/2]
set_multicycle_path -hold -end -from [get_clocks sclk] -to [get_clocks sys_clk_pin] [expr $sclk_ratio-1]

# From ADXL362 Datasheet, Table 10
# Setup time for accelerometer MOSI

# Delay for MOSI port to clk input
# Trace delay is ignored because only mismatched lengths matter for this.
# Max is worst case for setup constraint
set_output_delay -clock [get_clocks sclk] -clock_fall -max -add_delay 20.000 [get_ports ACL_MOSI]
# Min is worst case for hold constraint
set_output_delay -clock [get_clocks sclk] -clock_fall -min -add_delay -20.000 [get_ports ACL_MOSI]

# Delay for clock edge to data return
# Min is fastest trace estimate + accelerometer min clk-to-MISO delay 
set_input_delay -clock [get_clocks sclk] -clock_fall -min -add_delay 0.000 [get_ports ACL_MISO]
# Min is slowest trace estimate (1 ns) + accelerometer max clk-to-MISO delay (35 ns)
set_input_delay -clock [get_clocks sclk] -clock_fall -max -add_delay 36.000 [get_ports ACL_MISO]

# CSN delay. 100 ns is the setup. Hold is not an issue due to state machine design.
set_output_delay -clock [get_clocks sclk] -clock_fall -max -add_delay 100 [get_ports ACL_CSN]
set_output_delay -clock [get_clocks sclk] -clock_fall -min -add_delay 0 [get_ports ACL_CSN]

