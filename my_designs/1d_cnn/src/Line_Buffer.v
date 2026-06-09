`timescale 1 ns / 1 ps

module Line_Buffer #(
    parameter DWIDTH = 16
)(
    input  wire                     CLK,
    input  wire                     RST,

    //================================//
    //         Control Signals        //
    //================================//
    input  wire                     load_i,
    input  wire                     shift_en_i,

    //================================//
    //        Parallel IFM Input       //
    //================================//
    input  wire [DWIDTH-1:0]        ifm_bank0_i,
    input  wire [DWIDTH-1:0]        ifm_bank1_i,
    input  wire [DWIDTH-1:0]        ifm_bank2_i,
    input  wire [DWIDTH-1:0]        ifm_bank3_i,

    input  wire                     ifm_bank0_valid_i,
    input  wire                     ifm_bank1_valid_i,
    input  wire                     ifm_bank2_valid_i,
    input  wire                     ifm_bank3_valid_i,

    //================================//
    //       Serial East Output        //
    //================================//
    output wire [DWIDTH-1:0]        east_ifmap_o,
    output wire                     east_ifmap_valid_o
);

    //-------------------------------------//
    //         Register Declarations       //
    //-------------------------------------//
    reg [DWIDTH-1:0]                buf0_r;
    reg [DWIDTH-1:0]                buf1_r;
    reg [DWIDTH-1:0]                buf2_r;

    reg                             buf0_valid_r;
    reg                             buf1_valid_r;
    reg                             buf2_valid_r;

    //-------------------------------------//
    //          Wire Declarations          //
    //-------------------------------------//
    wire [DWIDTH-1:0]               east_ifmap_w;
    wire                            east_ifmap_valid_w;

    //-------------------------------------//
    //         Output Assignment          //
    //-------------------------------------//
    assign east_ifmap_w       = shift_en_i ? buf0_r       : {DWIDTH{1'b0}};
    assign east_ifmap_valid_w = shift_en_i ? buf0_valid_r : 1'b0;

    assign east_ifmap_o       = east_ifmap_w;
    assign east_ifmap_valid_o = east_ifmap_valid_w;

    //-------------------------------------//
    //             Sequential             //
    //-------------------------------------//
    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            buf0_r       <= {DWIDTH{1'b0}};
            buf1_r       <= {DWIDTH{1'b0}};
            buf2_r       <= {DWIDTH{1'b0}};
            buf0_valid_r <= 1'b0;
            buf1_valid_r <= 1'b0;
            buf2_valid_r <= 1'b0;
        end
        else begin
            if (load_i) begin
                // bank0 is bypassed directly at top-level.
                // line buffer only stores the remaining three lanes:
                // serial order after bypass = bank1 -> bank2 -> bank3
                buf0_r       <= ifm_bank1_i;
                buf1_r       <= ifm_bank2_i;
                buf2_r       <= ifm_bank3_i;
                buf0_valid_r <= ifm_bank1_valid_i;
                buf1_valid_r <= ifm_bank2_valid_i;
                buf2_valid_r <= ifm_bank3_valid_i;
            end

            if (shift_en_i) begin
                buf0_r       <= buf1_r;
                buf1_r       <= buf2_r;
                buf2_r       <= {DWIDTH{1'b0}};

                buf0_valid_r <= buf1_valid_r;
                buf1_valid_r <= buf2_valid_r;
                buf2_valid_r <= 1'b0;
            end
        end
    end

endmodule