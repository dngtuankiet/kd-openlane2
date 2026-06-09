`timescale 1 ns / 1 ps

module CNN_1D_Core #(
    parameter AWIDTH           = 10,
    parameter DWIDTH           = 16,
    parameter INST_DWIDTH      = 64,
    parameter AXI_WADDR_WIDTH  = 13,
    parameter AXI_RADDR_WIDTH  = 13,
    parameter AXI_WDATA_DWIDTH = 64,
    parameter AXI_RDATA_DWIDTH = 64,
    parameter EXEC_DEPTH       = 16,
    parameter COL_PE_NUM       = 4,
    parameter ROW_PE_NUM       = 4,
    parameter FRAC_BITS        = 8
)(
    input  wire                            CLK,
    input  wire                            RST,
    input  wire [AXI_WADDR_WIDTH-1:0]      axi_waddr_i,
    input  wire [AXI_WDATA_DWIDTH-1:0]     axi_wdata_i,
    input  wire                            axi_wvalid_i,
    input  wire [AXI_RADDR_WIDTH-1:0]      axi_raddr_i,
    input  wire                            axi_arvalid_i,
    output wire [AXI_RDATA_DWIDTH-1:0]     axi_rdata_o
);

    //-------------------------------------//
    //          Wire Declarations          //
    //-------------------------------------//
    wire                        arbiter_load_flag_w;
    wire                        arbiter_start_flag_w;
    wire                        arbiter_done_flag_w;
    wire [AWIDTH-1:0]           arbiter_max_IM_addr_w;

    wire                        arbiter_IM_wvalid_w;
    wire [AWIDTH-1:0]           arbiter_IM_waddr_w;
    wire [INST_DWIDTH-1:0]      arbiter_IM_wdata_w;

    wire                        arbiter_Ping_FM_wvalid_w;
    wire [AWIDTH-1:0]           arbiter_Ping_FM_waddr_w;
    wire [AXI_WDATA_DWIDTH-1:0] arbiter_Ping_FM_wdata_w;
    wire                        arbiter_Ping_FM_arvalid_w;
    wire [AWIDTH-1:0]           arbiter_Ping_FM_raddr_w;
    wire [AXI_RDATA_DWIDTH-1:0] arbiter_Ping_FM_rdata_w;

    wire                        arbiter_Pong_FM_wvalid_w;
    wire [AWIDTH-1:0]           arbiter_Pong_FM_waddr_w;
    wire [AXI_WDATA_DWIDTH-1:0] arbiter_Pong_FM_wdata_w;
    wire                        arbiter_Pong_FM_arvalid_w;
    wire [AWIDTH-1:0]           arbiter_Pong_FM_raddr_w;
    wire [AXI_RDATA_DWIDTH-1:0] arbiter_Pong_FM_rdata_w;

    wire                        arbiter_WM_wvalid_w;
    wire [AWIDTH-1:0]           arbiter_WM_waddr_w;
    wire [AXI_WDATA_DWIDTH-1:0] arbiter_WM_wdata_w;

    wire                        arbiter_BM_wvalid_w;
    wire [AWIDTH-1:0]           arbiter_BM_waddr_w;
    wire [AXI_WDATA_DWIDTH-1:0] arbiter_BM_wdata_w;

    wire [2:0]                  controller_state_w;
    wire                        controller_complete_w;

    wire                        instruction_valid_w;
    wire [INST_DWIDTH-1:0]      instruction_w;
    wire                        ctrl_IM_rd_en_w;
    wire [AWIDTH-1:0]           ctrl_IM_addr_w;

    wire                        ctrl_WM_bank0_rd_en_w;
    wire                        ctrl_WM_bank1_rd_en_w;
    wire                        ctrl_WM_bank2_rd_en_w;
    wire                        ctrl_WM_bank3_rd_en_w;
    wire [AWIDTH-1:0]           ctrl_WM_bank0_addr_w;
    wire [AWIDTH-1:0]           ctrl_WM_bank1_addr_w;
    wire [AWIDTH-1:0]           ctrl_WM_bank2_addr_w;
    wire [AWIDTH-1:0]           ctrl_WM_bank3_addr_w;

    wire                        ctrl_BM_bank0_rd_en_w;
    wire                        ctrl_BM_bank1_rd_en_w;
    wire                        ctrl_BM_bank2_rd_en_w;
    wire                        ctrl_BM_bank3_rd_en_w;
    wire [AWIDTH-1:0]           ctrl_BM_bank0_addr_w;
    wire [AWIDTH-1:0]           ctrl_BM_bank1_addr_w;
    wire [AWIDTH-1:0]           ctrl_BM_bank2_addr_w;
    wire [AWIDTH-1:0]           ctrl_BM_bank3_addr_w;

    wire                        ctrl_Ping_FM_bank0_rd_en_w;
    wire                        ctrl_Ping_FM_bank1_rd_en_w;
    wire                        ctrl_Ping_FM_bank2_rd_en_w;
    wire                        ctrl_Ping_FM_bank3_rd_en_w;
    wire                        ctrl_Ping_FM_bank0_wr_en_w;
    wire                        ctrl_Ping_FM_bank1_wr_en_w;
    wire                        ctrl_Ping_FM_bank2_wr_en_w;
    wire                        ctrl_Ping_FM_bank3_wr_en_w;
    wire [AWIDTH-1:0]           ctrl_Ping_FM_bank0_addr_w;
    wire [AWIDTH-1:0]           ctrl_Ping_FM_bank1_addr_w;
    wire [AWIDTH-1:0]           ctrl_Ping_FM_bank2_addr_w;
    wire [AWIDTH-1:0]           ctrl_Ping_FM_bank3_addr_w;

    wire                        ctrl_Pong_FM_bank0_rd_en_w;
    wire                        ctrl_Pong_FM_bank1_rd_en_w;
    wire                        ctrl_Pong_FM_bank2_rd_en_w;
    wire                        ctrl_Pong_FM_bank3_rd_en_w;
    wire                        ctrl_Pong_FM_bank0_wr_en_w;
    wire                        ctrl_Pong_FM_bank1_wr_en_w;
    wire                        ctrl_Pong_FM_bank2_wr_en_w;
    wire                        ctrl_Pong_FM_bank3_wr_en_w;
    wire [AWIDTH-1:0]           ctrl_Pong_FM_bank0_addr_w;
    wire [AWIDTH-1:0]           ctrl_Pong_FM_bank1_addr_w;
    wire [AWIDTH-1:0]           ctrl_Pong_FM_bank2_addr_w;
    wire [AWIDTH-1:0]           ctrl_Pong_FM_bank3_addr_w;

    wire [1:0]                  ifm_bank0_sel_w;
    wire [1:0]                  ifm_bank1_sel_w;
    wire [1:0]                  ifm_bank2_sel_w;
    wire [1:0]                  ifm_bank3_sel_w;

    wire                        first_ifmap_w;
    wire                        last_ifmap_w;
    wire                        execute_w;
    wire                        ifm_from_north_w;
    wire                        line_buffer_load_phase_w;
    wire                        line_buffer_bypass_phase_w;
    wire                        line_buffer_shift_w;

    wire [DWIDTH-1:0]           ping_bank0_ifmap_w;
    wire [DWIDTH-1:0]           ping_bank1_ifmap_w;
    wire [DWIDTH-1:0]           ping_bank2_ifmap_w;
    wire [DWIDTH-1:0]           ping_bank3_ifmap_w;
    wire                        ping_bank0_ifmap_valid_w;
    wire                        ping_bank1_ifmap_valid_w;
    wire                        ping_bank2_ifmap_valid_w;
    wire                        ping_bank3_ifmap_valid_w;

    wire [DWIDTH-1:0]           pong_bank0_ifmap_w;
    wire [DWIDTH-1:0]           pong_bank1_ifmap_w;
    wire [DWIDTH-1:0]           pong_bank2_ifmap_w;
    wire [DWIDTH-1:0]           pong_bank3_ifmap_w;
    wire                        pong_bank0_ifmap_valid_w;
    wire                        pong_bank1_ifmap_valid_w;
    wire                        pong_bank2_ifmap_valid_w;
    wire                        pong_bank3_ifmap_valid_w;

    wire [DWIDTH-1:0]           ifm_mem_bank0_w;
    wire [DWIDTH-1:0]           ifm_mem_bank1_w;
    wire [DWIDTH-1:0]           ifm_mem_bank2_w;
    wire [DWIDTH-1:0]           ifm_mem_bank3_w;
    wire                        ifm_mem_bank0_valid_w;
    wire                        ifm_mem_bank1_valid_w;
    wire                        ifm_mem_bank2_valid_w;
    wire                        ifm_mem_bank3_valid_w;

    wire [DWIDTH-1:0]           arbiter_bank0_ifmap_w;
    wire [DWIDTH-1:0]           arbiter_bank1_ifmap_w;
    wire [DWIDTH-1:0]           arbiter_bank2_ifmap_w;
    wire [DWIDTH-1:0]           arbiter_bank3_ifmap_w;
    wire                        arbiter_bank0_ifmap_valid_w;
    wire                        arbiter_bank1_ifmap_valid_w;
    wire                        arbiter_bank2_ifmap_valid_w;
    wire                        arbiter_bank3_ifmap_valid_w;

    wire                        arbiter_ifmap_valid_w;

    wire [DWIDTH-1:0]           east_ifmap_w;
    wire                        east_ifmap_valid_w;

    wire                        line_buffer_load_w;
    wire                        line_buffer_bypass_w;

    wire [DWIDTH-1:0]           pea_east_ifmap_w;
    wire                        pea_east_ifmap_valid_w;

    wire [DWIDTH-1:0]           bank0_mem_weight_w;
    wire [DWIDTH-1:0]           bank1_mem_weight_w;
    wire [DWIDTH-1:0]           bank2_mem_weight_w;
    wire [DWIDTH-1:0]           bank3_mem_weight_w;
    wire                        bank0_mem_weight_valid_w;
    wire                        bank1_mem_weight_valid_w;
    wire                        bank2_mem_weight_valid_w;
    wire                        bank3_mem_weight_valid_w;

    wire [DWIDTH-1:0]           bank0_mem_bias_w;
    wire [DWIDTH-1:0]           bank1_mem_bias_w;
    wire [DWIDTH-1:0]           bank2_mem_bias_w;
    wire [DWIDTH-1:0]           bank3_mem_bias_w;
    wire                        bank0_mem_bias_valid_w;
    wire                        bank1_mem_bias_valid_w;
    wire                        bank2_mem_bias_valid_w;
    wire                        bank3_mem_bias_valid_w;

    wire [DWIDTH-1:0]           bank0_mem_ofmap_w;
    wire [DWIDTH-1:0]           bank1_mem_ofmap_w;
    wire [DWIDTH-1:0]           bank2_mem_ofmap_w;
    wire [DWIDTH-1:0]           bank3_mem_ofmap_w;
    wire                        bank0_mem_ofmap_valid_w;
    wire                        bank1_mem_ofmap_valid_w;
    wire                        bank2_mem_ofmap_valid_w;
    wire                        bank3_mem_ofmap_valid_w;

    //-------------------------------------//
    //              Arbiter                //
    //-------------------------------------//
    assign arbiter_ifmap_valid_w = arbiter_bank0_ifmap_valid_w |
                                   arbiter_bank1_ifmap_valid_w |
                                   arbiter_bank2_ifmap_valid_w |
                                   arbiter_bank3_ifmap_valid_w;

    assign line_buffer_load_w    = line_buffer_load_phase_w &&
                                   arbiter_ifmap_valid_w;

    assign line_buffer_bypass_w  = line_buffer_bypass_phase_w &&
                                   arbiter_ifmap_valid_w;

    // serial order preserved from old line buffer:
    // bypass first output = bank3
    assign pea_east_ifmap_w       = line_buffer_bypass_w ? arbiter_bank0_ifmap_w       : east_ifmap_w;
    assign pea_east_ifmap_valid_w = line_buffer_bypass_w ? arbiter_bank0_ifmap_valid_w : east_ifmap_valid_w;

    Global_Arbiter #(
        .MAWIDTH            (AWIDTH),
        .INST_MDWIDTH       (INST_DWIDTH),
        .AXI_WADDR_WIDTH    (AXI_WADDR_WIDTH),
        .AXI_RADDR_WIDTH    (AXI_RADDR_WIDTH),
        .AXI_WDATA_MDWIDTH  (AXI_WDATA_DWIDTH),
        .AXI_RDATA_MDWIDTH  (AXI_RDATA_DWIDTH)
    ) u_global_arbiter (
        .CLK                       (CLK),
        .RST                       (RST),
        .axi_waddr_i               (axi_waddr_i),
        .axi_wdata_i               (axi_wdata_i),
        .axi_wvalid_i              (axi_wvalid_i),
        .axi_raddr_i               (axi_raddr_i),
        .axi_arvalid_i             (axi_arvalid_i),
        .axi_rdata_o               (axi_rdata_o),
        .direct_load_i             (1'b0),
        .direct_start_i            (1'b0),
        .direct_done_i             (1'b0),
        .state_i                   (controller_state_w),
        .completed_i               (controller_complete_w),
        .load_flag_o               (arbiter_load_flag_w),
        .start_flag_o              (arbiter_start_flag_w),
        .done_flag_o               (arbiter_done_flag_w),
        .max_IM_addr_o             (arbiter_max_IM_addr_w),
        .arbiter_IM_wvalid_o       (arbiter_IM_wvalid_w),
        .arbiter_IM_waddr_o        (arbiter_IM_waddr_w),
        .arbiter_IM_wdata_o        (arbiter_IM_wdata_w),
        .arbiter_Ping_FM_wvalid_o  (arbiter_Ping_FM_wvalid_w),
        .arbiter_Ping_FM_waddr_o   (arbiter_Ping_FM_waddr_w),
        .arbiter_Ping_FM_wdata_o   (arbiter_Ping_FM_wdata_w),
        .arbiter_Ping_FM_arvalid_o (arbiter_Ping_FM_arvalid_w),
        .arbiter_Ping_FM_raddr_o   (arbiter_Ping_FM_raddr_w),
        .arbiter_Ping_FM_rdata_i   (arbiter_Ping_FM_rdata_w),
        .arbiter_Pong_FM_wvalid_o  (arbiter_Pong_FM_wvalid_w),
        .arbiter_Pong_FM_waddr_o   (arbiter_Pong_FM_waddr_w),
        .arbiter_Pong_FM_wdata_o   (arbiter_Pong_FM_wdata_w),
        .arbiter_Pong_FM_arvalid_o (arbiter_Pong_FM_arvalid_w),
        .arbiter_Pong_FM_raddr_o   (arbiter_Pong_FM_raddr_w),
        .arbiter_Pong_FM_rdata_i   (arbiter_Pong_FM_rdata_w),
        .arbiter_WM_wvalid_o       (arbiter_WM_wvalid_w),
        .arbiter_WM_waddr_o        (arbiter_WM_waddr_w),
        .arbiter_WM_wdata_o        (arbiter_WM_wdata_w),
        .arbiter_BM_wvalid_o       (arbiter_BM_wvalid_w),
        .arbiter_BM_waddr_o        (arbiter_BM_waddr_w),
        .arbiter_BM_wdata_o        (arbiter_BM_wdata_w)
    );

    //-------------------------------------//
    //            Controller               //
    //-------------------------------------//
    Controller #(
        .AWIDTH           (AWIDTH),
        .DWIDTH           (DWIDTH),
        .INST_DWIDTH      (INST_DWIDTH),
        .AXI_WDATA_DWIDTH (AXI_WDATA_DWIDTH),
        .EXEC_DEPTH       (EXEC_DEPTH),
        .COL_PE_NUM       (COL_PE_NUM),
        .ROW_PE_NUM       (ROW_PE_NUM)
    ) u_controller (
        .CLK                        (CLK),
        .RST                        (RST),
        .load_flag_i                (arbiter_load_flag_w),
        .start_flag_i               (arbiter_start_flag_w),
        .done_flag_i                (arbiter_done_flag_w),
        .max_IM_addr_i              (arbiter_max_IM_addr_w),
        .state_o                    (controller_state_w),
        .complete_o                 (controller_complete_w),

        .ctrl_WM_bank0_rd_en_o      (ctrl_WM_bank0_rd_en_w),
        .ctrl_WM_bank1_rd_en_o      (ctrl_WM_bank1_rd_en_w),
        .ctrl_WM_bank2_rd_en_o      (ctrl_WM_bank2_rd_en_w),
        .ctrl_WM_bank3_rd_en_o      (ctrl_WM_bank3_rd_en_w),
        .ctrl_WM_bank0_addr_o       (ctrl_WM_bank0_addr_w),
        .ctrl_WM_bank1_addr_o       (ctrl_WM_bank1_addr_w),
        .ctrl_WM_bank2_addr_o       (ctrl_WM_bank2_addr_w),
        .ctrl_WM_bank3_addr_o       (ctrl_WM_bank3_addr_w),

        .ctrl_BM_bank0_rd_en_o      (ctrl_BM_bank0_rd_en_w),
        .ctrl_BM_bank1_rd_en_o      (ctrl_BM_bank1_rd_en_w),
        .ctrl_BM_bank2_rd_en_o      (ctrl_BM_bank2_rd_en_w),
        .ctrl_BM_bank3_rd_en_o      (ctrl_BM_bank3_rd_en_w),
        .ctrl_BM_bank0_addr_o       (ctrl_BM_bank0_addr_w),
        .ctrl_BM_bank1_addr_o       (ctrl_BM_bank1_addr_w),
        .ctrl_BM_bank2_addr_o       (ctrl_BM_bank2_addr_w),
        .ctrl_BM_bank3_addr_o       (ctrl_BM_bank3_addr_w),

        .ctrl_IM_rd_en_o            (ctrl_IM_rd_en_w),
        .ctrl_IM_addr_o             (ctrl_IM_addr_w),
        .instruction_i              (instruction_w),
        .instruction_valid_i        (instruction_valid_w),

        .ctrl_Ping_FM_bank0_rd_en_o (ctrl_Ping_FM_bank0_rd_en_w),
        .ctrl_Ping_FM_bank1_rd_en_o (ctrl_Ping_FM_bank1_rd_en_w),
        .ctrl_Ping_FM_bank2_rd_en_o (ctrl_Ping_FM_bank2_rd_en_w),
        .ctrl_Ping_FM_bank3_rd_en_o (ctrl_Ping_FM_bank3_rd_en_w),
        .ctrl_Ping_FM_bank0_wr_en_o (ctrl_Ping_FM_bank0_wr_en_w),
        .ctrl_Ping_FM_bank1_wr_en_o (ctrl_Ping_FM_bank1_wr_en_w),
        .ctrl_Ping_FM_bank2_wr_en_o (ctrl_Ping_FM_bank2_wr_en_w),
        .ctrl_Ping_FM_bank3_wr_en_o (ctrl_Ping_FM_bank3_wr_en_w),
        .ctrl_Ping_FM_bank0_addr_o  (ctrl_Ping_FM_bank0_addr_w),
        .ctrl_Ping_FM_bank1_addr_o  (ctrl_Ping_FM_bank1_addr_w),
        .ctrl_Ping_FM_bank2_addr_o  (ctrl_Ping_FM_bank2_addr_w),
        .ctrl_Ping_FM_bank3_addr_o  (ctrl_Ping_FM_bank3_addr_w),

        .ctrl_Pong_FM_bank0_rd_en_o (ctrl_Pong_FM_bank0_rd_en_w),
        .ctrl_Pong_FM_bank1_rd_en_o (ctrl_Pong_FM_bank1_rd_en_w),
        .ctrl_Pong_FM_bank2_rd_en_o (ctrl_Pong_FM_bank2_rd_en_w),
        .ctrl_Pong_FM_bank3_rd_en_o (ctrl_Pong_FM_bank3_rd_en_w),
        .ctrl_Pong_FM_bank0_wr_en_o (ctrl_Pong_FM_bank0_wr_en_w),
        .ctrl_Pong_FM_bank1_wr_en_o (ctrl_Pong_FM_bank1_wr_en_w),
        .ctrl_Pong_FM_bank2_wr_en_o (ctrl_Pong_FM_bank2_wr_en_w),
        .ctrl_Pong_FM_bank3_wr_en_o (ctrl_Pong_FM_bank3_wr_en_w),
        .ctrl_Pong_FM_bank0_addr_o  (ctrl_Pong_FM_bank0_addr_w),
        .ctrl_Pong_FM_bank1_addr_o  (ctrl_Pong_FM_bank1_addr_w),
        .ctrl_Pong_FM_bank2_addr_o  (ctrl_Pong_FM_bank2_addr_w),
        .ctrl_Pong_FM_bank3_addr_o  (ctrl_Pong_FM_bank3_addr_w),

        .ifm_bank0_sel_o            (ifm_bank0_sel_w),
        .ifm_bank1_sel_o            (ifm_bank1_sel_w),
        .ifm_bank2_sel_o            (ifm_bank2_sel_w),
        .ifm_bank3_sel_o            (ifm_bank3_sel_w),

        .bank0_mem_ofmap_valid_i    (bank0_mem_ofmap_valid_w),
        .bank1_mem_ofmap_valid_i    (bank1_mem_ofmap_valid_w),
        .bank2_mem_ofmap_valid_i    (bank2_mem_ofmap_valid_w),
        .bank3_mem_ofmap_valid_i    (bank3_mem_ofmap_valid_w),

        .first_ifmap_o              (first_ifmap_w),
        .last_ifmap_o               (last_ifmap_w),
        .execute_o                  (execute_w),
        .ifm_from_north_o           (ifm_from_north_w),
        .line_buffer_load_o         (line_buffer_load_phase_w),
        .line_buffer_bypass_o       (line_buffer_bypass_phase_w),
        .line_buffer_shift_o        (line_buffer_shift_w)
    );

    //-------------------------------------//
    //              Memories               //
    //-------------------------------------//
    Instruction_Memory #(
        .AWIDTH(AWIDTH),
        .DWIDTH(INST_DWIDTH)
    ) u_instruction_memory (
        .CLK                 (CLK),
        .RST                 (RST),
        .arbiter_IM_wvalid_i (arbiter_IM_wvalid_w),
        .arbiter_IM_waddr_i  (arbiter_IM_waddr_w),
        .arbiter_IM_wdata_i  (arbiter_IM_wdata_w),
        .ctrl_rd_en_i        (ctrl_IM_rd_en_w),
        .ctrl_addr_i         (ctrl_IM_addr_w),
        .instruction_o       (instruction_w),
        .instruction_valid_o (instruction_valid_w)
    );

    Weight_Bank_Memory #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH)
    ) u_weight_memory (
        .CLK                      (CLK),
        .RST                      (RST),
        .arbiter_WM_wvalid_i      (arbiter_WM_wvalid_w),
        .arbiter_WM_waddr_i       (arbiter_WM_waddr_w),
        .arbiter_WM_wdata_i       (arbiter_WM_wdata_w),
        .ctrl_bank0_rd_en_i       (ctrl_WM_bank0_rd_en_w),
        .ctrl_bank1_rd_en_i       (ctrl_WM_bank1_rd_en_w),
        .ctrl_bank2_rd_en_i       (ctrl_WM_bank2_rd_en_w),
        .ctrl_bank3_rd_en_i       (ctrl_WM_bank3_rd_en_w),
        .ctrl_bank0_addr_i        (ctrl_WM_bank0_addr_w),
        .ctrl_bank1_addr_i        (ctrl_WM_bank1_addr_w),
        .ctrl_bank2_addr_i        (ctrl_WM_bank2_addr_w),
        .ctrl_bank3_addr_i        (ctrl_WM_bank3_addr_w),
        .bank0_mem_weight_o       (bank0_mem_weight_w),
        .bank1_mem_weight_o       (bank1_mem_weight_w),
        .bank2_mem_weight_o       (bank2_mem_weight_w),
        .bank3_mem_weight_o       (bank3_mem_weight_w),
        .bank0_mem_weight_valid_o (bank0_mem_weight_valid_w),
        .bank1_mem_weight_valid_o (bank1_mem_weight_valid_w),
        .bank2_mem_weight_valid_o (bank2_mem_weight_valid_w),
        .bank3_mem_weight_valid_o (bank3_mem_weight_valid_w)
    );

    Bias_Bank_Memory #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH)
    ) u_bias_memory (
        .CLK                    (CLK),
        .RST                    (RST),
        .arbiter_BM_wvalid_i    (arbiter_BM_wvalid_w),
        .arbiter_BM_waddr_i     (arbiter_BM_waddr_w),
        .arbiter_BM_wdata_i     (arbiter_BM_wdata_w),
        .ctrl_bank0_rd_en_i     (ctrl_BM_bank0_rd_en_w),
        .ctrl_bank1_rd_en_i     (ctrl_BM_bank1_rd_en_w),
        .ctrl_bank2_rd_en_i     (ctrl_BM_bank2_rd_en_w),
        .ctrl_bank3_rd_en_i     (ctrl_BM_bank3_rd_en_w),
        .ctrl_bank0_addr_i      (ctrl_BM_bank0_addr_w),
        .ctrl_bank1_addr_i      (ctrl_BM_bank1_addr_w),
        .ctrl_bank2_addr_i      (ctrl_BM_bank2_addr_w),
        .ctrl_bank3_addr_i      (ctrl_BM_bank3_addr_w),
        .bank0_mem_bias_o       (bank0_mem_bias_w),
        .bank1_mem_bias_o       (bank1_mem_bias_w),
        .bank2_mem_bias_o       (bank2_mem_bias_w),
        .bank3_mem_bias_o       (bank3_mem_bias_w),
        .bank0_mem_bias_valid_o (bank0_mem_bias_valid_w),
        .bank1_mem_bias_valid_o (bank1_mem_bias_valid_w),
        .bank2_mem_bias_valid_o (bank2_mem_bias_valid_w),
        .bank3_mem_bias_valid_o (bank3_mem_bias_valid_w)
    );

    Ping_Pong_FMAP_Bank_Memory #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH)
    ) u_ping_fmap_memory (
        .CLK                     (CLK),
        .RST                     (RST),
        .arbiter_FM_wvalid_i     (arbiter_Ping_FM_wvalid_w),
        .arbiter_FM_waddr_i      (arbiter_Ping_FM_waddr_w),
        .arbiter_FM_wdata_i      (arbiter_Ping_FM_wdata_w),
        .arbiter_FM_arvalid_i    (arbiter_Ping_FM_arvalid_w),
        .arbiter_FM_raddr_i      (arbiter_Ping_FM_raddr_w),
        .arbiter_FM_rdata_o      (arbiter_Ping_FM_rdata_w),
        .ctrl_bank0_rd_en_i      (ctrl_Ping_FM_bank0_rd_en_w),
        .ctrl_bank1_rd_en_i      (ctrl_Ping_FM_bank1_rd_en_w),
        .ctrl_bank2_rd_en_i      (ctrl_Ping_FM_bank2_rd_en_w),
        .ctrl_bank3_rd_en_i      (ctrl_Ping_FM_bank3_rd_en_w),
        .ctrl_bank0_wr_en_i      (ctrl_Ping_FM_bank0_wr_en_w),
        .ctrl_bank1_wr_en_i      (ctrl_Ping_FM_bank1_wr_en_w),
        .ctrl_bank2_wr_en_i      (ctrl_Ping_FM_bank2_wr_en_w),
        .ctrl_bank3_wr_en_i      (ctrl_Ping_FM_bank3_wr_en_w),
        .ctrl_bank0_addr_i       (ctrl_Ping_FM_bank0_addr_w),
        .ctrl_bank1_addr_i       (ctrl_Ping_FM_bank1_addr_w),
        .ctrl_bank2_addr_i       (ctrl_Ping_FM_bank2_addr_w),
        .ctrl_bank3_addr_i       (ctrl_Ping_FM_bank3_addr_w),
        .bank0_mem_ofmap_i       (bank0_mem_ofmap_w),
        .bank1_mem_ofmap_i       (bank1_mem_ofmap_w),
        .bank2_mem_ofmap_i       (bank2_mem_ofmap_w),
        .bank3_mem_ofmap_i       (bank3_mem_ofmap_w),
        .bank0_mem_ofmap_valid_i (bank0_mem_ofmap_valid_w),
        .bank1_mem_ofmap_valid_i (bank1_mem_ofmap_valid_w),
        .bank2_mem_ofmap_valid_i (bank2_mem_ofmap_valid_w),
        .bank3_mem_ofmap_valid_i (bank3_mem_ofmap_valid_w),
        .bank0_mem_ifmap_o       (ping_bank0_ifmap_w),
        .bank1_mem_ifmap_o       (ping_bank1_ifmap_w),
        .bank2_mem_ifmap_o       (ping_bank2_ifmap_w),
        .bank3_mem_ifmap_o       (ping_bank3_ifmap_w),
        .bank0_mem_ifmap_valid_o (ping_bank0_ifmap_valid_w),
        .bank1_mem_ifmap_valid_o (ping_bank1_ifmap_valid_w),
        .bank2_mem_ifmap_valid_o (ping_bank2_ifmap_valid_w),
        .bank3_mem_ifmap_valid_o (ping_bank3_ifmap_valid_w)
    );

    Ping_Pong_FMAP_Bank_Memory #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH)
    ) u_pong_fmap_memory (
        .CLK                     (CLK),
        .RST                     (RST),
        .arbiter_FM_wvalid_i     (arbiter_Pong_FM_wvalid_w),
        .arbiter_FM_waddr_i      (arbiter_Pong_FM_waddr_w),
        .arbiter_FM_wdata_i      (arbiter_Pong_FM_wdata_w),
        .arbiter_FM_arvalid_i    (arbiter_Pong_FM_arvalid_w),
        .arbiter_FM_raddr_i      (arbiter_Pong_FM_raddr_w),
        .arbiter_FM_rdata_o      (arbiter_Pong_FM_rdata_w),
        .ctrl_bank0_rd_en_i      (ctrl_Pong_FM_bank0_rd_en_w),
        .ctrl_bank1_rd_en_i      (ctrl_Pong_FM_bank1_rd_en_w),
        .ctrl_bank2_rd_en_i      (ctrl_Pong_FM_bank2_rd_en_w),
        .ctrl_bank3_rd_en_i      (ctrl_Pong_FM_bank3_rd_en_w),
        .ctrl_bank0_wr_en_i      (ctrl_Pong_FM_bank0_wr_en_w),
        .ctrl_bank1_wr_en_i      (ctrl_Pong_FM_bank1_wr_en_w),
        .ctrl_bank2_wr_en_i      (ctrl_Pong_FM_bank2_wr_en_w),
        .ctrl_bank3_wr_en_i      (ctrl_Pong_FM_bank3_wr_en_w),
        .ctrl_bank0_addr_i       (ctrl_Pong_FM_bank0_addr_w),
        .ctrl_bank1_addr_i       (ctrl_Pong_FM_bank1_addr_w),
        .ctrl_bank2_addr_i       (ctrl_Pong_FM_bank2_addr_w),
        .ctrl_bank3_addr_i       (ctrl_Pong_FM_bank3_addr_w),
        .bank0_mem_ofmap_i       (bank0_mem_ofmap_w),
        .bank1_mem_ofmap_i       (bank1_mem_ofmap_w),
        .bank2_mem_ofmap_i       (bank2_mem_ofmap_w),
        .bank3_mem_ofmap_i       (bank3_mem_ofmap_w),
        .bank0_mem_ofmap_valid_i (bank0_mem_ofmap_valid_w),
        .bank1_mem_ofmap_valid_i (bank1_mem_ofmap_valid_w),
        .bank2_mem_ofmap_valid_i (bank2_mem_ofmap_valid_w),
        .bank3_mem_ofmap_valid_i (bank3_mem_ofmap_valid_w),
        .bank0_mem_ifmap_o       (pong_bank0_ifmap_w),
        .bank1_mem_ifmap_o       (pong_bank1_ifmap_w),
        .bank2_mem_ifmap_o       (pong_bank2_ifmap_w),
        .bank3_mem_ifmap_o       (pong_bank3_ifmap_w),
        .bank0_mem_ifmap_valid_o (pong_bank0_ifmap_valid_w),
        .bank1_mem_ifmap_valid_o (pong_bank1_ifmap_valid_w),
        .bank2_mem_ifmap_valid_o (pong_bank2_ifmap_valid_w),
        .bank3_mem_ifmap_valid_o (pong_bank3_ifmap_valid_w)
    );

    //-------------------------------------//
    //         IFM / PEA Datapath         //
    //-------------------------------------//
    assign ifm_mem_bank0_w       = ping_bank0_ifmap_valid_w ? ping_bank0_ifmap_w : pong_bank0_ifmap_w;
    assign ifm_mem_bank1_w       = ping_bank1_ifmap_valid_w ? ping_bank1_ifmap_w : pong_bank1_ifmap_w;
    assign ifm_mem_bank2_w       = ping_bank2_ifmap_valid_w ? ping_bank2_ifmap_w : pong_bank2_ifmap_w;
    assign ifm_mem_bank3_w       = ping_bank3_ifmap_valid_w ? ping_bank3_ifmap_w : pong_bank3_ifmap_w;
    assign ifm_mem_bank0_valid_w = ping_bank0_ifmap_valid_w | pong_bank0_ifmap_valid_w;
    assign ifm_mem_bank1_valid_w = ping_bank1_ifmap_valid_w | pong_bank1_ifmap_valid_w;
    assign ifm_mem_bank2_valid_w = ping_bank2_ifmap_valid_w | pong_bank2_ifmap_valid_w;
    assign ifm_mem_bank3_valid_w = ping_bank3_ifmap_valid_w | pong_bank3_ifmap_valid_w;

    IFM_Arbiter #(
        .DWIDTH(DWIDTH)
    ) u_ifm_arbiter (
        .bank0_mem_ifmap_i       (ifm_mem_bank0_w),
        .bank1_mem_ifmap_i       (ifm_mem_bank1_w),
        .bank2_mem_ifmap_i       (ifm_mem_bank2_w),
        .bank3_mem_ifmap_i       (ifm_mem_bank3_w),
        .bank0_mem_ifmap_valid_i (ifm_mem_bank0_valid_w),
        .bank1_mem_ifmap_valid_i (ifm_mem_bank1_valid_w),
        .bank2_mem_ifmap_valid_i (ifm_mem_bank2_valid_w),
        .bank3_mem_ifmap_valid_i (ifm_mem_bank3_valid_w),
        .ifm_bank0_sel_i         (ifm_bank0_sel_w),
        .ifm_bank1_sel_i         (ifm_bank1_sel_w),
        .ifm_bank2_sel_i         (ifm_bank2_sel_w),
        .ifm_bank3_sel_i         (ifm_bank3_sel_w),
        .ifm_bank0_o             (arbiter_bank0_ifmap_w),
        .ifm_bank1_o             (arbiter_bank1_ifmap_w),
        .ifm_bank2_o             (arbiter_bank2_ifmap_w),
        .ifm_bank3_o             (arbiter_bank3_ifmap_w),
        .ifm_bank0_valid_o       (arbiter_bank0_ifmap_valid_w),
        .ifm_bank1_valid_o       (arbiter_bank1_ifmap_valid_w),
        .ifm_bank2_valid_o       (arbiter_bank2_ifmap_valid_w),
        .ifm_bank3_valid_o       (arbiter_bank3_ifmap_valid_w)
    );

    Line_Buffer #(
        .DWIDTH(DWIDTH)
    ) u_line_buffer (
        .CLK                (CLK),
        .RST                (RST),
        .load_i             (line_buffer_load_w),
        .shift_en_i         (line_buffer_shift_w),
        .ifm_bank0_i        (arbiter_bank0_ifmap_w),
        .ifm_bank1_i        (arbiter_bank1_ifmap_w),
        .ifm_bank2_i        (arbiter_bank2_ifmap_w),
        .ifm_bank3_i        (arbiter_bank3_ifmap_w),
        .ifm_bank0_valid_i  (arbiter_bank0_ifmap_valid_w),
        .ifm_bank1_valid_i  (arbiter_bank1_ifmap_valid_w),
        .ifm_bank2_valid_i  (arbiter_bank2_ifmap_valid_w),
        .ifm_bank3_valid_i  (arbiter_bank3_ifmap_valid_w),
        .east_ifmap_o       (east_ifmap_w),
        .east_ifmap_valid_o (east_ifmap_valid_w)
    );

    PEA #(
        .DATA_DWIDTH(DWIDTH),
        .FRAC_BITS  (FRAC_BITS)
    ) u_pea (
        .CLK                     (CLK),
        .RST                     (RST),
        .first_ifmap_i           (first_ifmap_w),
        .last_ifmap_i            (last_ifmap_w),
        .execute_i               (execute_w),
        .ifm_from_north_i        (ifm_from_north_w),
        .bank0_mem_ifmap_i       (arbiter_bank0_ifmap_w),
        .bank0_mem_ifmap_valid_i (arbiter_bank0_ifmap_valid_w),
        .bank1_mem_ifmap_i       (arbiter_bank1_ifmap_w),
        .bank1_mem_ifmap_valid_i (arbiter_bank1_ifmap_valid_w),
        .bank2_mem_ifmap_i       (arbiter_bank2_ifmap_w),
        .bank2_mem_ifmap_valid_i (arbiter_bank2_ifmap_valid_w),
        .bank3_mem_ifmap_i       (arbiter_bank3_ifmap_w),
        .bank3_mem_ifmap_valid_i (arbiter_bank3_ifmap_valid_w),
        .east_ifmap_i            (pea_east_ifmap_w),
        .east_ifmap_valid_i      (pea_east_ifmap_valid_w),
        .row0_mem_weight_i       (bank0_mem_weight_w),
        .row0_mem_weight_valid_i (bank0_mem_weight_valid_w),
        .row1_mem_weight_i       (bank1_mem_weight_w),
        .row1_mem_weight_valid_i (bank1_mem_weight_valid_w),
        .row2_mem_weight_i       (bank2_mem_weight_w),
        .row2_mem_weight_valid_i (bank2_mem_weight_valid_w),
        .row3_mem_weight_i       (bank3_mem_weight_w),
        .row3_mem_weight_valid_i (bank3_mem_weight_valid_w),
        .row0_mem_bias_i         (bank0_mem_bias_w),
        .row0_mem_bias_valid_i   (bank0_mem_bias_valid_w),
        .row1_mem_bias_i         (bank1_mem_bias_w),
        .row1_mem_bias_valid_i   (bank1_mem_bias_valid_w),
        .row2_mem_bias_i         (bank2_mem_bias_w),
        .row2_mem_bias_valid_i   (bank2_mem_bias_valid_w),
        .row3_mem_bias_i         (bank3_mem_bias_w),
        .row3_mem_bias_valid_i   (bank3_mem_bias_valid_w),
        .bank0_mem_ofmap_o       (bank0_mem_ofmap_w),
        .bank0_mem_ofmap_valid_o (bank0_mem_ofmap_valid_w),
        .bank1_mem_ofmap_o       (bank1_mem_ofmap_w),
        .bank1_mem_ofmap_valid_o (bank1_mem_ofmap_valid_w),
        .bank2_mem_ofmap_o       (bank2_mem_ofmap_w),
        .bank2_mem_ofmap_valid_o (bank2_mem_ofmap_valid_w),
        .bank3_mem_ofmap_o       (bank3_mem_ofmap_w),
        .bank3_mem_ofmap_valid_o (bank3_mem_ofmap_valid_w)
    );

endmodule
