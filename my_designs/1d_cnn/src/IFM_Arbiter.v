`timescale 1 ns / 1 ps

module IFM_Arbiter #(
    parameter DWIDTH = 16
)(
    //================================//
    //         From FM Memory         //
    //================================//
    input  wire [DWIDTH-1:0]    bank0_mem_ifmap_i,
    input  wire [DWIDTH-1:0]    bank1_mem_ifmap_i,
    input  wire [DWIDTH-1:0]    bank2_mem_ifmap_i,
    input  wire [DWIDTH-1:0]    bank3_mem_ifmap_i,

    input  wire                 bank0_mem_ifmap_valid_i,
    input  wire                 bank1_mem_ifmap_valid_i,
    input  wire                 bank2_mem_ifmap_valid_i,
    input  wire                 bank3_mem_ifmap_valid_i,

    //================================//
    //         From Controller        //
    //================================//
    input  wire [1:0]           ifm_bank0_sel_i,
    input  wire [1:0]           ifm_bank1_sel_i,
    input  wire [1:0]           ifm_bank2_sel_i,
    input  wire [1:0]           ifm_bank3_sel_i,

    //================================//
    //          To PEA / FIFO         //
    //================================//
    output reg  [DWIDTH-1:0]    ifm_bank0_o,
    output reg  [DWIDTH-1:0]    ifm_bank1_o,
    output reg  [DWIDTH-1:0]    ifm_bank2_o,
    output reg  [DWIDTH-1:0]    ifm_bank3_o,

    output wire                 ifm_bank0_valid_o,
    output wire                 ifm_bank1_valid_o,
    output wire                 ifm_bank2_valid_o,
    output wire                 ifm_bank3_valid_o
);

    //-------------------------------------//
    //          Wire Declarations          //
    //-------------------------------------//
    wire                        fetch_valid_w;

    //-------------------------------------//
    //         Fetch Slot Valid           //
    //-------------------------------------//
    assign fetch_valid_w     = bank0_mem_ifmap_valid_i |
                               bank1_mem_ifmap_valid_i |
                               bank2_mem_ifmap_valid_i |
                               bank3_mem_ifmap_valid_i;

    // A fetch slot is considered valid even when some selected banks
    // are zero-injected. Data is already forced to zero by the memory
    // wrapper when a read is disabled.
    assign ifm_bank0_valid_o = fetch_valid_w;
    assign ifm_bank1_valid_o = fetch_valid_w;
    assign ifm_bank2_valid_o = fetch_valid_w;
    assign ifm_bank3_valid_o = fetch_valid_w;

    //-------------------------------------//
    //            Lane Select             //
    //-------------------------------------//
    always @(*) begin
        case (ifm_bank0_sel_i)
            2'd0: ifm_bank0_o = bank0_mem_ifmap_i;
            2'd1: ifm_bank0_o = bank1_mem_ifmap_i;
            2'd2: ifm_bank0_o = bank2_mem_ifmap_i;
            default: ifm_bank0_o = bank3_mem_ifmap_i;
        endcase
    end

    always @(*) begin
        case (ifm_bank1_sel_i)
            2'd0: ifm_bank1_o = bank0_mem_ifmap_i;
            2'd1: ifm_bank1_o = bank1_mem_ifmap_i;
            2'd2: ifm_bank1_o = bank2_mem_ifmap_i;
            default: ifm_bank1_o = bank3_mem_ifmap_i;
        endcase
    end

    always @(*) begin
        case (ifm_bank2_sel_i)
            2'd0: ifm_bank2_o = bank0_mem_ifmap_i;
            2'd1: ifm_bank2_o = bank1_mem_ifmap_i;
            2'd2: ifm_bank2_o = bank2_mem_ifmap_i;
            default: ifm_bank2_o = bank3_mem_ifmap_i;
        endcase
    end

    always @(*) begin
        case (ifm_bank3_sel_i)
            2'd0: ifm_bank3_o = bank0_mem_ifmap_i;
            2'd1: ifm_bank3_o = bank1_mem_ifmap_i;
            2'd2: ifm_bank3_o = bank2_mem_ifmap_i;
            default: ifm_bank3_o = bank3_mem_ifmap_i;
        endcase
    end

endmodule
