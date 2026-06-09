`timescale 1 ns / 1 ps

module Dual_Port_BRAM
#(
    parameter AWIDTH = 10,
    parameter DWIDTH = 32
)
(
    input  wire                 clka,
    input  wire                 rst_n,

    //================================//
    //             Port A             //
    //================================//
    input  wire                 ena,
    input  wire                 wea,
    input  wire [AWIDTH-1:0]    addra,
    input  wire [DWIDTH-1:0]    dina,
    output reg  [DWIDTH-1:0]    douta,

    //================================//
    //             Port B             //
    //================================//
    input  wire                 clkb,
    input  wire                 enb,
    input  wire                 web,
    input  wire [AWIDTH-1:0]    addrb,
    input  wire [DWIDTH-1:0]    dinb,
    output reg  [DWIDTH-1:0]    doutb
);

    //-------------------------------------//
    //         Register Declarations       //
    //-------------------------------------//
    reg [DWIDTH-1:0] mem [0:(1 << AWIDTH)-1];

    //-------------------------------------//
    //              Port A                //
    //-------------------------------------//
    always @(posedge clka) begin
        if (!rst_n) begin
            douta <= {DWIDTH{1'b0}};
        end
        else if (ena) begin
            if (wea) begin
                mem[addra] <= dina;
            end
            douta <= mem[addra];
        end
        else begin
            douta <= {DWIDTH{1'b0}};
        end
    end

    //-------------------------------------//
    //              Port B                //
    //-------------------------------------//
    always @(posedge clkb) begin
        if (!rst_n) begin
            doutb <= {DWIDTH{1'b0}};
        end
        else if (enb) begin
            if (web) begin
                mem[addrb] <= dinb;
            end
            doutb <= mem[addrb];
        end
        else begin
            doutb <= {DWIDTH{1'b0}};
        end
    end

endmodule
