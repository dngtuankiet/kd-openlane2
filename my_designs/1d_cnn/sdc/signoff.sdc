# Signoff SDC for CNN_1D_Core
# Matches impl.sdc; tighten when the design converges.

create_clock -name CLK -period 20.0 [get_ports CLK]

set_input_delay -clock CLK -max 6.0 [get_ports RST]
set_input_delay -clock CLK -min 0.0 [get_ports RST]

set_input_delay -clock CLK -max 6.0 [get_ports {axi_waddr_i[*] axi_wdata_i[*] axi_wvalid_i}]
set_input_delay -clock CLK -min 0.0 [get_ports {axi_waddr_i[*] axi_wdata_i[*] axi_wvalid_i}]

set_input_delay -clock CLK -max 6.0 [get_ports {axi_raddr_i[*] axi_arvalid_i}]
set_input_delay -clock CLK -min 0.0 [get_ports {axi_raddr_i[*] axi_arvalid_i}]

set_output_delay -clock CLK -max 6.0 [get_ports {axi_rdata_o[*]}]
set_output_delay -clock CLK -min 0.0 [get_ports {axi_rdata_o[*]}]

set_multicycle_path -setup 1 -from [get_clocks CLK] -to [get_clocks CLK]
