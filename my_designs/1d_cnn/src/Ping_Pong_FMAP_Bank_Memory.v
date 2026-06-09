`timescale 1 ns / 1 ps

module Ping_Pong_FMAP_Bank_Memory #(
    parameter AWIDTH            		= 10,
    parameter DWIDTH            		= 16,
    parameter NBANKS            		= 4,
    parameter TOTAL_DWIDTH      		= NBANKS * DWIDTH
)(
    input  wire                         CLK,
    input  wire                         RST,

    //================================//
    //          From Arbiter          //
    //================================//
    input  wire                         arbiter_FM_wvalid_i,
    input  wire [AWIDTH-1:0]            arbiter_FM_waddr_i,
    input  wire [TOTAL_DWIDTH-1:0]      arbiter_FM_wdata_i,

    input  wire                         arbiter_FM_arvalid_i,
    input  wire [AWIDTH-1:0]            arbiter_FM_raddr_i,
    output wire [TOTAL_DWIDTH-1:0]      arbiter_FM_rdata_o,

    //================================//
    //         From Controller        //
    //================================//
    input  wire                         ctrl_bank0_rd_en_i,
    input  wire                         ctrl_bank1_rd_en_i,
    input  wire                         ctrl_bank2_rd_en_i,
    input  wire                         ctrl_bank3_rd_en_i,

    input  wire                         ctrl_bank0_wr_en_i,
    input  wire                         ctrl_bank1_wr_en_i,
    input  wire                         ctrl_bank2_wr_en_i,
    input  wire                         ctrl_bank3_wr_en_i,

    input  wire [AWIDTH-1:0]            ctrl_bank0_addr_i,
    input  wire [AWIDTH-1:0]            ctrl_bank1_addr_i,
    input  wire [AWIDTH-1:0]            ctrl_bank2_addr_i,
    input  wire [AWIDTH-1:0]            ctrl_bank3_addr_i,

    //================================//
    //            From PEA            //
    //================================//
    input  wire [DWIDTH-1:0]            bank0_mem_ofmap_i,
    input  wire [DWIDTH-1:0]            bank1_mem_ofmap_i,
    input  wire [DWIDTH-1:0]            bank2_mem_ofmap_i,
    input  wire [DWIDTH-1:0]            bank3_mem_ofmap_i,

    input  wire                         bank0_mem_ofmap_valid_i,
    input  wire                         bank1_mem_ofmap_valid_i,
    input  wire                         bank2_mem_ofmap_valid_i,
    input  wire                         bank3_mem_ofmap_valid_i,

    //================================//
    //             To PEA             //
    //================================//
    output wire [DWIDTH-1:0]            bank0_mem_ifmap_o,
    output wire [DWIDTH-1:0]            bank1_mem_ifmap_o,
    output wire [DWIDTH-1:0]            bank2_mem_ifmap_o,
    output wire [DWIDTH-1:0]            bank3_mem_ifmap_o,

    output wire                         bank0_mem_ifmap_valid_o,
    output wire                         bank1_mem_ifmap_valid_o,
    output wire                         bank2_mem_ifmap_valid_o,
    output wire                         bank3_mem_ifmap_valid_o
);

    //-------------------------------------//
    //          Wire Declarations          //
    //-------------------------------------//
    wire [DWIDTH-1:0]                   arbiter_FM_dout0_w;
    wire [DWIDTH-1:0]                   arbiter_FM_dout1_w;
    wire [DWIDTH-1:0]                   arbiter_FM_dout2_w;
    wire [DWIDTH-1:0]                   arbiter_FM_dout3_w;

    wire [DWIDTH-1:0]                   bank0_dout_w;
    wire [DWIDTH-1:0]                   bank1_dout_w;
    wire [DWIDTH-1:0]                   bank2_dout_w;
    wire [DWIDTH-1:0]                   bank3_dout_w;

    wire [DWIDTH-1:0]                   arbiter_FM_wdata0_w;
    wire [DWIDTH-1:0]                   arbiter_FM_wdata1_w;
    wire [DWIDTH-1:0]                   arbiter_FM_wdata2_w;
    wire [DWIDTH-1:0]                   arbiter_FM_wdata3_w;

    wire                                ctrl_bank0_en_w;
    wire                                ctrl_bank1_en_w;
    wire                                ctrl_bank2_en_w;
    wire                                ctrl_bank3_en_w;

    wire                                ctrl_bank0_we_w;
    wire                                ctrl_bank1_we_w;
    wire                                ctrl_bank2_we_w;
    wire                                ctrl_bank3_we_w;

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
    assign arbiter_FM_wdata0_w          = arbiter_FM_wdata_i[DWIDTH*1-1:DWIDTH*0];
    assign arbiter_FM_wdata1_w          = arbiter_FM_wdata_i[DWIDTH*2-1:DWIDTH*1];
    assign arbiter_FM_wdata2_w          = arbiter_FM_wdata_i[DWIDTH*3-1:DWIDTH*2];
    assign arbiter_FM_wdata3_w          = arbiter_FM_wdata_i[DWIDTH*4-1:DWIDTH*3];

    assign arbiter_FM_rdata_o           = {arbiter_FM_dout3_w,
                                           arbiter_FM_dout2_w,
                                           arbiter_FM_dout1_w,
                                           arbiter_FM_dout0_w};

    //-------------------------------------//
    //            Read / Write            //
    //-------------------------------------//
    assign ctrl_bank0_we_w              = ctrl_bank0_wr_en_i & bank0_mem_ofmap_valid_i;
    assign ctrl_bank1_we_w              = ctrl_bank1_wr_en_i & bank1_mem_ofmap_valid_i;
    assign ctrl_bank2_we_w              = ctrl_bank2_wr_en_i & bank2_mem_ofmap_valid_i;
    assign ctrl_bank3_we_w              = ctrl_bank3_wr_en_i & bank3_mem_ofmap_valid_i;

    assign ctrl_bank0_en_w              = ctrl_bank0_rd_en_i | ctrl_bank0_we_w;
    assign ctrl_bank1_en_w              = ctrl_bank1_rd_en_i | ctrl_bank1_we_w;
    assign ctrl_bank2_en_w              = ctrl_bank2_rd_en_i | ctrl_bank2_we_w;
    assign ctrl_bank3_en_w              = ctrl_bank3_rd_en_i | ctrl_bank3_we_w;

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

    //-------------------------------------//
    //          To PEA Read Path          //
    //-------------------------------------//
    assign bank0_mem_ifmap_valid_o      = ctrl_bank0_rd_en_r;
    assign bank1_mem_ifmap_valid_o      = ctrl_bank1_rd_en_r;
    assign bank2_mem_ifmap_valid_o      = ctrl_bank2_rd_en_r;
    assign bank3_mem_ifmap_valid_o      = ctrl_bank3_rd_en_r;

    assign bank0_mem_ifmap_o            = ctrl_bank0_rd_en_r ? bank0_dout_w : {DWIDTH{1'b0}};
    assign bank1_mem_ifmap_o            = ctrl_bank1_rd_en_r ? bank1_dout_w : {DWIDTH{1'b0}};
    assign bank2_mem_ifmap_o            = ctrl_bank2_rd_en_r ? bank2_dout_w : {DWIDTH{1'b0}};
    assign bank3_mem_ifmap_o            = ctrl_bank3_rd_en_r ? bank3_dout_w : {DWIDTH{1'b0}};

    //-------------------------------------//
    //               Bank 0               //
    //-------------------------------------//
    Dual_Port_BRAM #(
        .AWIDTH                         (AWIDTH),
        .DWIDTH                         (DWIDTH)
    ) u_bank0 (
        .clka                           (CLK),
        .rst_n                          (RST),
        .ena                            (arbiter_FM_wvalid_i | arbiter_FM_arvalid_i),
        .wea                            (arbiter_FM_wvalid_i),
        .addra                          (arbiter_FM_wvalid_i ? arbiter_FM_waddr_i : arbiter_FM_raddr_i),
        .dina                           (arbiter_FM_wdata0_w),
        .douta                          (arbiter_FM_dout0_w),

        .clkb                           (CLK),
        .enb                            (ctrl_bank0_en_w),
        .web                            (ctrl_bank0_we_w),
        .addrb                          (ctrl_bank0_addr_i),
        .dinb                           (bank0_mem_ofmap_i),
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
        .ena                            (arbiter_FM_wvalid_i | arbiter_FM_arvalid_i),
        .wea                            (arbiter_FM_wvalid_i),
        .addra                          (arbiter_FM_wvalid_i ? arbiter_FM_waddr_i : arbiter_FM_raddr_i),
        .dina                           (arbiter_FM_wdata1_w),
        .douta                          (arbiter_FM_dout1_w),

        .clkb                           (CLK),
        .enb                            (ctrl_bank1_en_w),
        .web                            (ctrl_bank1_we_w),
        .addrb                          (ctrl_bank1_addr_i),
        .dinb                           (bank1_mem_ofmap_i),
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
        .ena                            (arbiter_FM_wvalid_i | arbiter_FM_arvalid_i),
        .wea                            (arbiter_FM_wvalid_i),
        .addra                          (arbiter_FM_wvalid_i ? arbiter_FM_waddr_i : arbiter_FM_raddr_i),
        .dina                           (arbiter_FM_wdata2_w),
        .douta                          (arbiter_FM_dout2_w),

        .clkb                           (CLK),
        .enb                            (ctrl_bank2_en_w),
        .web                            (ctrl_bank2_we_w),
        .addrb                          (ctrl_bank2_addr_i),
        .dinb                           (bank2_mem_ofmap_i),
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
        .ena                            (arbiter_FM_wvalid_i | arbiter_FM_arvalid_i),
        .wea                            (arbiter_FM_wvalid_i),
        .addra                          (arbiter_FM_wvalid_i ? arbiter_FM_waddr_i : arbiter_FM_raddr_i),
        .dina                           (arbiter_FM_wdata3_w),
        .douta                          (arbiter_FM_dout3_w),

        .clkb                           (CLK),
        .enb                            (ctrl_bank3_en_w),
        .web                            (ctrl_bank3_we_w),
        .addrb                          (ctrl_bank3_addr_i),
        .dinb                           (bank3_mem_ofmap_i),
        .doutb                          (bank3_dout_w)
    );

endmodule
