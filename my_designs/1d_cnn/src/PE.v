`timescale 1 ns / 1 ps

module PE #(
    parameter DATA_DWIDTH = 16,
    parameter FRAC_BITS   = 8
)(
    input  wire                             CLK,
    input  wire                             RST,

    //================================//
    //             Control            //
    //================================//
    input  wire                             first_ifmap_i,
    input  wire                             last_ifmap_i,
    input  wire                             execute_i,

    //================================//
    //          North IFMAP           //
    //================================//
    input  wire signed [DATA_DWIDTH-1:0]    north_ifmap_i,
    input  wire                             north_ifmap_valid_i,

    //================================//
    //           East IFMAP           //
    //================================//
    input  wire signed [DATA_DWIDTH-1:0]    east_ifmap_i,
    input  wire                             east_ifmap_valid_i,

    //================================//
    //         Forward Outputs        //
    //================================//
    output reg  signed [DATA_DWIDTH-1:0]    south_ifmap_o,
    output reg                              south_ifmap_valid_o,

    output reg  signed [DATA_DWIDTH-1:0]    west_ifmap_o,
    output reg                              west_ifmap_valid_o,

    //================================//
    //           Weight / Bias        //
    //================================//
    input  wire signed [DATA_DWIDTH-1:0]    mem_weight_i,
    input  wire                             mem_weight_valid_i,

    input  wire signed [DATA_DWIDTH-1:0]    mem_bias_i,
    input  wire                             mem_bias_valid_i,

    //================================//
    //             OFMAP              //
    //================================//
    output reg  signed [DATA_DWIDTH-1:0]    mem_ofmap_o,
    output reg                              mem_ofmap_valid_o
);

    //-------------------------------------//
    //            Function               //
    //-------------------------------------//
    function [DATA_DWIDTH-1:0] sat_q16;
        input signed [31:0] value_i;
        begin
            if (value_i > 32'sd32767) begin
                sat_q16 = 16'sh7FFF;
            end
            else if (value_i < -32'sd32768) begin
                sat_q16 = 16'sh8000;
            end
            else begin
                sat_q16 = value_i[DATA_DWIDTH-1:0];
            end
        end
    endfunction

    //-------------------------------------//
    //          Wire Declarations          //
    //-------------------------------------//
    wire signed [DATA_DWIDTH-1:0]           ifmap_in_w;
    wire                                     ifmap_valid_w;

    wire signed [(2*DATA_DWIDTH)-1:0]       mult_full_w;
    wire signed [31:0]                      mult_q_w;
    wire signed [31:0]                      accumulator_w;

    //-------------------------------------//
    //         Register Declarations       //
    //-------------------------------------//
    reg  signed [31:0]                      accumulator_r;

    //-------------------------------------//
    //            Input Select             //
    //-------------------------------------//
    assign ifmap_in_w = north_ifmap_valid_i ? north_ifmap_i : 
						east_ifmap_valid_i  ? east_ifmap_i  : {DATA_DWIDTH{1'b0}};

    assign ifmap_valid_w = north_ifmap_valid_i | east_ifmap_valid_i;

    //-------------------------------------//
    //           Multiply / MAC           //
    //-------------------------------------//
    assign mult_full_w = (ifmap_valid_w && mem_weight_valid_i) ?
                         ($signed(ifmap_in_w) * $signed(mem_weight_i)) :
                         {((2*DATA_DWIDTH)){1'b0}};

    assign mult_q_w    = $signed(mult_full_w) >>> FRAC_BITS;

    assign accumulator_w = mem_bias_valid_i ?
                           ($signed({{16{mem_bias_i[DATA_DWIDTH-1]}}, mem_bias_i}) + mult_q_w) :
                           (accumulator_r + mult_q_w);

    //-------------------------------------//
    //             Sequential             //
    //-------------------------------------//
    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            accumulator_r       <= 32'sd0;
            south_ifmap_o       <= {DATA_DWIDTH{1'b0}};
            south_ifmap_valid_o <= 1'b0;
            west_ifmap_o        <= {DATA_DWIDTH{1'b0}};
            west_ifmap_valid_o  <= 1'b0;
            mem_ofmap_o         <= {DATA_DWIDTH{1'b0}};
            mem_ofmap_valid_o   <= 1'b0;
        end
        else begin
            if (execute_i) begin
                if (ifmap_valid_w) begin
                    accumulator_r <= accumulator_w;
                end
                else begin
                    accumulator_r <= accumulator_r;
                end

                south_ifmap_o       <= ifmap_in_w;
                south_ifmap_valid_o <= ifmap_valid_w;

                west_ifmap_o        <= ifmap_in_w;
                west_ifmap_valid_o  <= ifmap_valid_w;

                if (last_ifmap_i && ifmap_valid_w) begin
                    mem_ofmap_o       <= sat_q16(accumulator_w);
                    mem_ofmap_valid_o <= 1'b1;
                end
                else begin
                    mem_ofmap_o       <= {DATA_DWIDTH{1'b0}};
                    mem_ofmap_valid_o <= 1'b0;
                end
            end
            else begin
                accumulator_r       <= 32'sd0;
                south_ifmap_o       <= {DATA_DWIDTH{1'b0}};
                south_ifmap_valid_o <= 1'b0;
                west_ifmap_o        <= {DATA_DWIDTH{1'b0}};
                west_ifmap_valid_o  <= 1'b0;
                mem_ofmap_o         <= {DATA_DWIDTH{1'b0}};
                mem_ofmap_valid_o   <= 1'b0;
            end
        end
    end

endmodule
