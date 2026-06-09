`timescale 1 ns / 1 ps

module Bias_Bank_Memory #(
    parameter AWIDTH       				= 10,
    parameter DWIDTH       				= 16,
    parameter NBANKS       				= 4,
    parameter TOTAL_DWIDTH 				= NBANKS * DWIDTH
)(
    input  wire                         CLK,
    input  wire                         RST,

    //================================//
    //          From Arbiter          //
    //================================//
    input  wire                         arbiter_BM_wvalid_i,
    input  wire [AWIDTH-1:0]            arbiter_BM_waddr_i,
    input  wire [TOTAL_DWIDTH-1:0]      arbiter_BM_wdata_i,

    //================================//
    //         From Controller        //
    //================================//
    input  wire                         ctrl_bank0_rd_en_i,
    input  wire                         ctrl_bank1_rd_en_i,
    input  wire                         ctrl_bank2_rd_en_i,
    input  wire                         ctrl_bank3_rd_en_i,

    input  wire [AWIDTH-1:0]            ctrl_bank0_addr_i,
    input  wire [AWIDTH-1:0]            ctrl_bank1_addr_i,
    input  wire [AWIDTH-1:0]            ctrl_bank2_addr_i,
    input  wire [AWIDTH-1:0]            ctrl_bank3_addr_i,

    //================================//
    //             To PEA             //
    //================================//
    output wire [DWIDTH-1:0]            bank0_mem_bias_o,
    output wire [DWIDTH-1:0]            bank1_mem_bias_o,
    output wire [DWIDTH-1:0]            bank2_mem_bias_o,
    output wire [DWIDTH-1:0]            bank3_mem_bias_o,

    output wire                         bank0_mem_bias_valid_o,
    output wire                         bank1_mem_bias_valid_o,
    output wire                         bank2_mem_bias_valid_o,
    output wire                         bank3_mem_bias_valid_o
);

    //-------------------------------------//
    //          Wire Declarations          //
    //-------------------------------------//
    wire [DWIDTH-1:0]                   bank0_dout_w;
    wire [DWIDTH-1:0]                   bank1_dout_w;
    wire [DWIDTH-1:0]                   bank2_dout_w;
    wire [DWIDTH-1:0]                   bank3_dout_w;

    wire [DWIDTH-1:0]                   arbiter_BM_wdata0_w;
    wire [DWIDTH-1:0]                   arbiter_BM_wdata1_w;
    wire [DWIDTH-1:0]                   arbiter_BM_wdata2_w;
    wire [DWIDTH-1:0]                   arbiter_BM_wdata3_w;

    //-------------------------------------//
    //         Register Declarations       //
    //-------------------------------------//
    reg                                 ctrl_bank0_rd_en_r;
    reg                                 ctrl_bank1_rd_en_r;
    reg                                 ctrl_bank2_rd_en_r;
    reg                                 ctrl_bank3_rd_en_r;

    //-------------------------------------//
    //             Write Data             //
    //-------------------------------------//
    assign arbiter_BM_wdata0_w          = arbiter_BM_wdata_i[DWIDTH*1-1:DWIDTH*0];
    assign arbiter_BM_wdata1_w          = arbiter_BM_wdata_i[DWIDTH*2-1:DWIDTH*1];
    assign arbiter_BM_wdata2_w          = arbiter_BM_wdata_i[DWIDTH*3-1:DWIDTH*2];
    assign arbiter_BM_wdata3_w          = arbiter_BM_wdata_i[DWIDTH*4-1:DWIDTH*3];

    //-------------------------------------//
    //             Read Valid             //
    //-------------------------------------//
    always @(posedge CLK) begin
        if (!RST) begin
            ctrl_bank0_rd_en_r          <= 1'b0;
            ctrl_bank1_rd_en_r          <= 1'b0;
            ctrl_bank2_rd_en_r          <= 1'b0;
            ctrl_bank3_rd_en_r          <= 1'b0;
        end
        else begin
            ctrl_bank0_rd_en_r          <= ctrl_bank0_rd_en_i;
            ctrl_bank1_rd_en_r          <= ctrl_bank1_rd_en_i;
            ctrl_bank2_rd_en_r          <= ctrl_bank2_rd_en_i;
            ctrl_bank3_rd_en_r          <= ctrl_bank3_rd_en_i;
        end
    end

    assign bank0_mem_bias_valid_o       = ctrl_bank0_rd_en_r;
    assign bank1_mem_bias_valid_o       = ctrl_bank1_rd_en_r;
    assign bank2_mem_bias_valid_o       = ctrl_bank2_rd_en_r;
    assign bank3_mem_bias_valid_o       = ctrl_bank3_rd_en_r;

    assign bank0_mem_bias_o             = ctrl_bank0_rd_en_r ? bank0_dout_w : {DWIDTH{1'b0}};
    assign bank1_mem_bias_o             = ctrl_bank1_rd_en_r ? bank1_dout_w : {DWIDTH{1'b0}};
    assign bank2_mem_bias_o             = ctrl_bank2_rd_en_r ? bank2_dout_w : {DWIDTH{1'b0}};
    assign bank3_mem_bias_o             = ctrl_bank3_rd_en_r ? bank3_dout_w : {DWIDTH{1'b0}};

    //-------------------------------------//
    //               Bank 0               //
    //-------------------------------------//
    Dual_Port_BRAM #(
        .AWIDTH                         (AWIDTH),
        .DWIDTH                         (DWIDTH)
    ) u_bank0 (
        .clka                           (CLK),
        .rst_n                          (RST),
        .ena                            (arbiter_BM_wvalid_i),
        .wea                            (arbiter_BM_wvalid_i),
        .addra                          (arbiter_BM_waddr_i),
        .dina                           (arbiter_BM_wdata0_w),
        .douta                          (),

        .clkb                           (CLK),
        .enb                            (ctrl_bank0_rd_en_i),
        .web                            (1'b0),
        .addrb                          (ctrl_bank0_addr_i),
        .dinb                           ({DWIDTH{1'b0}}),
        .doutb                          (bank0_dout_w)
    );

    //-------------------------------------//
    //               Bank 1               //
    //-------------------------------------//
    Dual_Port_BRAM #(
        .AWIDTH                         (AWIDTH),
        .DWIDTH                         (DWIDTH)
    ) u_bank1 (
        .clka                           (CLK),
        .rst_n                          (RST),
        .ena                            (arbiter_BM_wvalid_i),
        .wea                            (arbiter_BM_wvalid_i),
        .addra                          (arbiter_BM_waddr_i),
        .dina                           (arbiter_BM_wdata1_w),
        .douta                          (),

        .clkb                           (CLK),
        .enb                            (ctrl_bank1_rd_en_i),
        .web                            (1'b0),
        .addrb                          (ctrl_bank1_addr_i),
        .dinb                           ({DWIDTH{1'b0}}),
        .doutb                          (bank1_dout_w)
    );

    //-------------------------------------//
    //               Bank 2               //
    //-------------------------------------//
    Dual_Port_BRAM #(
        .AWIDTH                         (AWIDTH),
        .DWIDTH                         (DWIDTH)
    ) u_bank2 (
        .clka                           (CLK),
        .rst_n                          (RST),
        .ena                            (arbiter_BM_wvalid_i),
        .wea                            (arbiter_BM_wvalid_i),
        .addra                          (arbiter_BM_waddr_i),
        .dina                           (arbiter_BM_wdata2_w),
        .douta                          (),

        .clkb                           (CLK),
        .enb                            (ctrl_bank2_rd_en_i),
        .web                            (1'b0),
        .addrb                          (ctrl_bank2_addr_i),
        .dinb                           ({DWIDTH{1'b0}}),
        .doutb                          (bank2_dout_w)
    );

    //-------------------------------------//
    //               Bank 3               //
    //-------------------------------------//
    Dual_Port_BRAM #(
        .AWIDTH                         (AWIDTH),
        .DWIDTH                         (DWIDTH)
    ) u_bank3 (
        .clka                           (CLK),
        .rst_n                          (RST),
        .ena                            (arbiter_BM_wvalid_i),
        .wea                            (arbiter_BM_wvalid_i),
        .addra                          (arbiter_BM_waddr_i),
        .dina                           (arbiter_BM_wdata3_w),
        .douta                          (),

        .clkb                           (CLK),
        .enb                            (ctrl_bank3_rd_en_i),
        .web                            (1'b0),
        .addrb                          (ctrl_bank3_addr_i),
        .dinb                           ({DWIDTH{1'b0}}),
        .doutb                          (bank3_dout_w)
    );

endmodule
