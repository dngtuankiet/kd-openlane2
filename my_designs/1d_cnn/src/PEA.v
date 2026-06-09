`timescale 1 ns / 1 ps

module PEA #(
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
    input  wire                             ifm_from_north_i,

    //================================//
    //          North Inputs          //
    //================================//
    input  wire signed [DATA_DWIDTH-1:0]    bank0_mem_ifmap_i,
    input  wire                             bank0_mem_ifmap_valid_i,

    input  wire signed [DATA_DWIDTH-1:0]    bank1_mem_ifmap_i,
    input  wire                             bank1_mem_ifmap_valid_i,

    input  wire signed [DATA_DWIDTH-1:0]    bank2_mem_ifmap_i,
    input  wire                             bank2_mem_ifmap_valid_i,

    input  wire signed [DATA_DWIDTH-1:0]    bank3_mem_ifmap_i,
    input  wire                             bank3_mem_ifmap_valid_i,

    //================================//
    //        External East Input      //
    //================================//
    input  wire signed [DATA_DWIDTH-1:0]    east_ifmap_i,
    input  wire                             east_ifmap_valid_i,

    //================================//
    //         Row Weights/Biases      //
    //================================//
    input  wire signed [DATA_DWIDTH-1:0]    row0_mem_weight_i,
    input  wire                             row0_mem_weight_valid_i,
    input  wire signed [DATA_DWIDTH-1:0]    row1_mem_weight_i,
    input  wire                             row1_mem_weight_valid_i,
    input  wire signed [DATA_DWIDTH-1:0]    row2_mem_weight_i,
    input  wire                             row2_mem_weight_valid_i,
    input  wire signed [DATA_DWIDTH-1:0]    row3_mem_weight_i,
    input  wire                             row3_mem_weight_valid_i,

    input  wire signed [DATA_DWIDTH-1:0]    row0_mem_bias_i,
    input  wire                             row0_mem_bias_valid_i,
    input  wire signed [DATA_DWIDTH-1:0]    row1_mem_bias_i,
    input  wire                             row1_mem_bias_valid_i,
    input  wire signed [DATA_DWIDTH-1:0]    row2_mem_bias_i,
    input  wire                             row2_mem_bias_valid_i,
    input  wire signed [DATA_DWIDTH-1:0]    row3_mem_bias_i,
    input  wire                             row3_mem_bias_valid_i,

    //================================//
    //           OFMAP Output          //
    //================================//
    output wire signed [DATA_DWIDTH-1:0]    bank0_mem_ofmap_o,
    output wire                             bank0_mem_ofmap_valid_o,

    output wire signed [DATA_DWIDTH-1:0]    bank1_mem_ofmap_o,
    output wire                             bank1_mem_ofmap_valid_o,

    output wire signed [DATA_DWIDTH-1:0]    bank2_mem_ofmap_o,
    output wire                             bank2_mem_ofmap_valid_o,

    output wire signed [DATA_DWIDTH-1:0]    bank3_mem_ofmap_o,
    output wire                             bank3_mem_ofmap_valid_o
);

    //-------------------------------------//
    //         Register Declarations       //
    //-------------------------------------//
    reg                                    first_ifmap_r [0:2];
    reg                                    last_ifmap_r  [0:2];
    reg                                    execute_r     [0:2];

    reg  signed [DATA_DWIDTH-1:0]          east_ifmap_delay_r [0:2];
    reg                                    east_ifmap_valid_delay_r [0:2];

    //-------------------------------------//
    //          Wire Declarations          //
    //-------------------------------------//
    wire signed [DATA_DWIDTH-1:0]          south_data_w [0:15];
    wire                                   south_valid_w[0:15];

    wire signed [DATA_DWIDTH-1:0]          west_data_w  [0:15];
    wire                                   west_valid_w [0:15];

    wire signed [DATA_DWIDTH-1:0]          mem_ofmap_w  [0:15];
    wire                                   mem_ofmap_valid_w [0:15];

    wire signed [DATA_DWIDTH-1:0]          row0_north_ifmap_w [0:3];
    wire                                   row0_north_ifmap_valid_w [0:3];

    genvar                                 row_g;
    genvar                                 col_g;

    //-------------------------------------//
    //       Control / East Pipelines      //
    //-------------------------------------//
    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            first_ifmap_r[0] <= 1'b0;
            first_ifmap_r[1] <= 1'b0;
            first_ifmap_r[2] <= 1'b0;

            last_ifmap_r[0]  <= 1'b0;
            last_ifmap_r[1]  <= 1'b0;
            last_ifmap_r[2]  <= 1'b0;

            execute_r[0]     <= 1'b0;
            execute_r[1]     <= 1'b0;
            execute_r[2]     <= 1'b0;

            east_ifmap_delay_r[0] <= {DATA_DWIDTH{1'b0}};
            east_ifmap_delay_r[1] <= {DATA_DWIDTH{1'b0}};
            east_ifmap_delay_r[2] <= {DATA_DWIDTH{1'b0}};

            east_ifmap_valid_delay_r[0] <= 1'b0;
            east_ifmap_valid_delay_r[1] <= 1'b0;
            east_ifmap_valid_delay_r[2] <= 1'b0;
        end
        else begin
            first_ifmap_r[0] <= first_ifmap_i;
            first_ifmap_r[1] <= first_ifmap_r[0];
            first_ifmap_r[2] <= first_ifmap_r[1];

            last_ifmap_r[0]  <= last_ifmap_i;
            last_ifmap_r[1]  <= last_ifmap_r[0];
            last_ifmap_r[2]  <= last_ifmap_r[1];

            execute_r[0]     <= execute_i;
            execute_r[1]     <= execute_r[0];
            execute_r[2]     <= execute_r[1];

            east_ifmap_delay_r[0]       <= east_ifmap_i;
            east_ifmap_delay_r[1]       <= east_ifmap_delay_r[0];
            east_ifmap_delay_r[2]       <= east_ifmap_delay_r[1];

            east_ifmap_valid_delay_r[0] <= east_ifmap_valid_i;
            east_ifmap_valid_delay_r[1] <= east_ifmap_valid_delay_r[0];
            east_ifmap_valid_delay_r[2] <= east_ifmap_valid_delay_r[1];
        end
    end

    //-------------------------------------//
    //        Row0 North Gating           //
    //-------------------------------------//
    assign row0_north_ifmap_w[0]       = bank0_mem_ifmap_i;
    assign row0_north_ifmap_w[1]       = bank1_mem_ifmap_i;
    assign row0_north_ifmap_w[2]       = bank2_mem_ifmap_i;
    assign row0_north_ifmap_w[3]       = bank3_mem_ifmap_i;

    assign row0_north_ifmap_valid_w[0] = ifm_from_north_i && bank0_mem_ifmap_valid_i;
    assign row0_north_ifmap_valid_w[1] = ifm_from_north_i && bank1_mem_ifmap_valid_i;
    assign row0_north_ifmap_valid_w[2] = ifm_from_north_i && bank2_mem_ifmap_valid_i;
    assign row0_north_ifmap_valid_w[3] = ifm_from_north_i && bank3_mem_ifmap_valid_i;

    //-------------------------------------//
    //             PE Array               //
    //-------------------------------------//
    generate
        for (row_g = 0; row_g < 4; row_g = row_g + 1) begin : gen_row
            for (col_g = 0; col_g < 4; col_g = col_g + 1) begin : gen_col
                localparam integer PE_IDX    = (row_g * 4) + col_g;
                localparam integer NORTH_IDX = (row_g == 0) ? 0 : (((row_g - 1) * 4) + col_g);
                localparam integer EAST_IDX  = (PE_IDX < 15) ? (PE_IDX + 1) : PE_IDX;

                PE #(
                    .DATA_DWIDTH(DATA_DWIDTH),
                    .FRAC_BITS  (FRAC_BITS)
                ) u_pe (
                    .CLK                (CLK),
                    .RST                (RST),

                    .first_ifmap_i      ((row_g == 0) ? first_ifmap_i :
                                         (row_g == 1) ? first_ifmap_r[0] :
                                         (row_g == 2) ? first_ifmap_r[1] :
                                                        first_ifmap_r[2]),

                    .last_ifmap_i       ((row_g == 0) ? last_ifmap_i :
                                         (row_g == 1) ? last_ifmap_r[0] :
                                         (row_g == 2) ? last_ifmap_r[1] :
                                                        last_ifmap_r[2]),

                    .execute_i          ((row_g == 0) ? execute_i :
                                         (row_g == 1) ? execute_r[0] :
                                         (row_g == 2) ? execute_r[1] :
                                                        execute_r[2]),

                    .north_ifmap_i      ((row_g == 0) ?
                                         row0_north_ifmap_w[col_g] :
                                         south_data_w[NORTH_IDX]),

                    .north_ifmap_valid_i((row_g == 0) ?
                                         row0_north_ifmap_valid_w[col_g] :
                                         south_valid_w[NORTH_IDX]),

                    .east_ifmap_i       ((col_g == 3) ?
                                         ((row_g == 0) ? east_ifmap_i :
                                          (row_g == 1) ? east_ifmap_delay_r[0] :
                                          (row_g == 2) ? east_ifmap_delay_r[1] :
                                                         east_ifmap_delay_r[2]) :
                                         west_data_w[EAST_IDX]),

                    .east_ifmap_valid_i ((col_g == 3) ?
                                         ((row_g == 0) ? east_ifmap_valid_i :
                                          (row_g == 1) ? east_ifmap_valid_delay_r[0] :
                                          (row_g == 2) ? east_ifmap_valid_delay_r[1] :
                                                         east_ifmap_valid_delay_r[2]) :
                                         west_valid_w[EAST_IDX]),

                    .south_ifmap_o      (south_data_w[PE_IDX]),
                    .south_ifmap_valid_o(south_valid_w[PE_IDX]),
                    .west_ifmap_o       (west_data_w[PE_IDX]),
                    .west_ifmap_valid_o (west_valid_w[PE_IDX]),

                    .mem_weight_i       ((row_g == 0) ? row0_mem_weight_i :
                                         (row_g == 1) ? row1_mem_weight_i :
                                         (row_g == 2) ? row2_mem_weight_i :
                                                        row3_mem_weight_i),

                    .mem_weight_valid_i ((row_g == 0) ? row0_mem_weight_valid_i :
                                         (row_g == 1) ? row1_mem_weight_valid_i :
                                         (row_g == 2) ? row2_mem_weight_valid_i :
                                                        row3_mem_weight_valid_i),

                    .mem_bias_i         ((row_g == 0) ? row0_mem_bias_i :
                                         (row_g == 1) ? row1_mem_bias_i :
                                         (row_g == 2) ? row2_mem_bias_i :
                                                        row3_mem_bias_i),

                    .mem_bias_valid_i   ((row_g == 0) ? row0_mem_bias_valid_i :
                                         (row_g == 1) ? row1_mem_bias_valid_i :
                                         (row_g == 2) ? row2_mem_bias_valid_i :
                                                        row3_mem_bias_valid_i),

                    .mem_ofmap_o        (mem_ofmap_w[PE_IDX]),
                    .mem_ofmap_valid_o  (mem_ofmap_valid_w[PE_IDX])
                );
            end
        end
    endgenerate

    //-------------------------------------//
    //           OFMAP Mapping            //
    //-------------------------------------//
    assign bank0_mem_ofmap_o       = mem_ofmap_valid_w[0]  ? mem_ofmap_w[0]  :
                                     mem_ofmap_valid_w[4]  ? mem_ofmap_w[4]  :
                                     mem_ofmap_valid_w[8]  ? mem_ofmap_w[8]  :
                                                             mem_ofmap_w[12];
    assign bank0_mem_ofmap_valid_o = mem_ofmap_valid_w[0]  |
                                     mem_ofmap_valid_w[4]  |
                                     mem_ofmap_valid_w[8]  |
                                     mem_ofmap_valid_w[12];

    assign bank1_mem_ofmap_o       = mem_ofmap_valid_w[1]  ? mem_ofmap_w[1]  :
                                     mem_ofmap_valid_w[5]  ? mem_ofmap_w[5]  :
                                     mem_ofmap_valid_w[9]  ? mem_ofmap_w[9]  :
                                                             mem_ofmap_w[13];
    assign bank1_mem_ofmap_valid_o = mem_ofmap_valid_w[1]  |
                                     mem_ofmap_valid_w[5]  |
                                     mem_ofmap_valid_w[9]  |
                                     mem_ofmap_valid_w[13];

    assign bank2_mem_ofmap_o       = mem_ofmap_valid_w[2]  ? mem_ofmap_w[2]  :
                                     mem_ofmap_valid_w[6]  ? mem_ofmap_w[6]  :
                                     mem_ofmap_valid_w[10] ? mem_ofmap_w[10] :
                                                             mem_ofmap_w[14];
    assign bank2_mem_ofmap_valid_o = mem_ofmap_valid_w[2]  |
                                     mem_ofmap_valid_w[6]  |
                                     mem_ofmap_valid_w[10] |
                                     mem_ofmap_valid_w[14];

    assign bank3_mem_ofmap_o       = mem_ofmap_valid_w[3]  ? mem_ofmap_w[3]  :
                                     mem_ofmap_valid_w[7]  ? mem_ofmap_w[7]  :
                                     mem_ofmap_valid_w[11] ? mem_ofmap_w[11] :
                                                             mem_ofmap_w[15];
    assign bank3_mem_ofmap_valid_o = mem_ofmap_valid_w[3]  |
                                     mem_ofmap_valid_w[7]  |
                                     mem_ofmap_valid_w[11] |
                                     mem_ofmap_valid_w[15];

endmodule