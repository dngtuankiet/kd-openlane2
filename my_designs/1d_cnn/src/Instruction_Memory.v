`timescale 1 ns / 1 ps

module Instruction_Memory #(
    parameter AWIDTH 			= 10,
    parameter DWIDTH 			= 64
)(
    input  wire                 CLK,
    input  wire                 RST,

    //================================//
    //          From Arbiter          //
    //================================//
    input  wire                 arbiter_IM_wvalid_i,
    input  wire [AWIDTH-1:0]    arbiter_IM_waddr_i,
    input  wire [DWIDTH-1:0]    arbiter_IM_wdata_i,

    //================================//
    //         From Controller        //
    //================================//
    input  wire                 ctrl_rd_en_i,
    input  wire [AWIDTH-1:0]    ctrl_addr_i,

    //================================//
    //          To Controller         //
    //================================//
    output wire [DWIDTH-1:0]    instruction_o,
    output wire                 instruction_valid_o
);

    //-------------------------------------//
    //          Wire Declarations          //
    //-------------------------------------//
    wire [DWIDTH-1:0]           instruction_dout_w;

    //-------------------------------------//
    //         Register Declarations       //
    //-------------------------------------//
    reg                         ctrl_rd_en_r;

    //-------------------------------------//
    //              Output                //
    //-------------------------------------//
    assign instruction_o        = ctrl_rd_en_r ? instruction_dout_w : {DWIDTH{1'b0}};
    assign instruction_valid_o  = ctrl_rd_en_r;

    //-------------------------------------//
    //          Valid Delay Line          //
    //-------------------------------------//
    always @(posedge CLK) begin
        if (!RST) begin
            ctrl_rd_en_r        <= 1'b0;
        end
        else begin
            ctrl_rd_en_r        <= ctrl_rd_en_i;
        end
    end

    //-------------------------------------//
    //              Memory                //
    //-------------------------------------//
    Dual_Port_BRAM #(
        .AWIDTH                 (AWIDTH),
        .DWIDTH                 (DWIDTH)
    ) u_instruction_mem (
        .clka                   (CLK),
        .rst_n                  (RST),
        .ena                    (arbiter_IM_wvalid_i),
        .wea                    (arbiter_IM_wvalid_i),
        .addra                  (arbiter_IM_waddr_i),
        .dina                   (arbiter_IM_wdata_i),
        .douta                  (),

        .clkb                   (CLK),
        .enb                    (ctrl_rd_en_i),
        .web                    (1'b0),
        .addrb                  (ctrl_addr_i),
        .dinb                   ({DWIDTH{1'b0}}),
        .doutb                  (instruction_dout_w)
    );

endmodule
