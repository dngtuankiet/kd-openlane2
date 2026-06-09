# Implementation SDC for CNN_1D_Core
# Conservative 20 ns clock period (50 MHz) for sky130A.
# Input/output delays are 30% of period (6 ns) to leave timing slack for P&R.

create_clock -name CLK -period 20.0 [get_ports CLK]

# Register the reset like any other synchronous input
set_input_delay -clock CLK -max 6.0 [get_ports RST]
set_input_delay -clock CLK -min 0.0 [get_ports RST]

# AXI-lite write channel
set_input_delay -clock CLK -max 6.0 [get_ports {axi_waddr_i[*] axi_wdata_i[*] axi_wvalid_i}]
set_input_delay -clock CLK -min 0.0 [get_ports {axi_waddr_i[*] axi_wdata_i[*] axi_wvalid_i}]

# AXI-lite read-address channel
set_input_delay -clock CLK -max 6.0 [get_ports {axi_raddr_i[*] axi_arvalid_i}]
set_input_delay -clock CLK -min 0.0 [get_ports {axi_raddr_i[*] axi_arvalid_i}]

# AXI-lite read-data output
set_output_delay -clock CLK -max 6.0 [get_ports {axi_rdata_o[*]}]
set_output_delay -clock CLK -min 0.0 [get_ports {axi_rdata_o[*]}]

# The two SRAM clock pins are driven by the same CLK net; tell the timer
# that clk0 and clk1 on every macro instance are the same clock.
set_multicycle_path -setup 1 -from [get_clocks CLK] -to [get_clocks CLK]
