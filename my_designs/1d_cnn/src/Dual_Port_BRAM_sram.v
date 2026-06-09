`timescale 1 ns / 1 ps

// SRAM-backed Dual_Port_BRAM using sky130_sram_2kbyte_1rw1r_32x512_8.
//
// Hard macros are used when:
//   AWIDTH >= 9  (macro depth = 512, 9-bit address)
//   DWIDTH >= SRAM_MIN_DWIDTH (64) and DWIDTH is a multiple of 32
// Otherwise falls back to RTL register arrays.
//
// Instruction_Memory instance (AWIDTH=10, DWIDTH=64):
//   BANKS        = ceil(1024/512) = 2   (depth partitions)
//   MACROS_WIDE  = 64/32        = 2   (32-bit slices per bank for 64-bit width)
//   Total macros = 4 x sky130_sram_2kbyte_1rw1r_32x512_8
//
// All other Dual_Port_BRAM instances (DWIDTH=16) use the RTL fallback.
//
// Write arbitration: port A (clka) has priority; port B (clkb) write only fires
// when port A is not writing.  Reads are always routed to the read-only port 1
// of the macro.

module Dual_Port_BRAM
#(
    parameter AWIDTH          = 10,
    parameter DWIDTH          = 32,
    parameter SRAM_MIN_DWIDTH = 64
)
(
    input  wire              clka,
    input  wire              rst_n,

    input  wire              ena,
    input  wire              wea,
    input  wire [AWIDTH-1:0] addra,
    input  wire [DWIDTH-1:0] dina,
    output wire [DWIDTH-1:0] douta,

    input  wire              clkb,
    input  wire              enb,
    input  wire              web,
    input  wire [AWIDTH-1:0] addrb,
    input  wire [DWIDTH-1:0] dinb,
    output wire [DWIDTH-1:0] doutb
);

    localparam DEPTH        = (1 << AWIDTH);
    localparam MACRO_AW     = 9;                         // sky130_sram_2kbyte_1rw1r_32x512_8: 512 depth = 9-bit addr
    localparam MACRO_DW     = 32;                        // data width per macro
    localparam MACRO_NMASKS = 4;                         // number of write-mask bits
    localparam MACROS_WIDE  = DWIDTH / MACRO_DW;         // macros side-by-side for full DWIDTH
    localparam USE_SRAM     = (AWIDTH  >= MACRO_AW)  &&
                              (DWIDTH  >= SRAM_MIN_DWIDTH) &&
                              ((DWIDTH % MACRO_DW) == 0);
    localparam BANKS        = (DEPTH + (1 << MACRO_AW) - 1) >> MACRO_AW;
    localparam BANK_SEL_W   = (BANKS <= 1) ? 1 : $clog2(BANKS);

    genvar bank_g, wide_g;
    generate
        if (USE_SRAM) begin : gen_sram

            // -------------------------------------------------------
            // Write arbitration (port A has priority)
            // -------------------------------------------------------
            wire                   write_a_w        = ena && wea;
            wire                   write_b_w        = enb && web;
            wire                   write_en_w       = write_a_w || write_b_w;
            wire [AWIDTH-1:0]      write_addr_w     = write_a_w ? addra : addrb;
            wire [DWIDTH-1:0]      write_data_w     = write_a_w ? dina  : dinb;
            // Bank select: upper bits above MACRO_AW
            wire [BANK_SEL_W-1:0]  write_bank_w     = write_addr_w >> MACRO_AW;
            wire [MACRO_AW-1:0]    write_maddr_w    = write_addr_w[MACRO_AW-1:0];

            // -------------------------------------------------------
            // Read routing (reads use read-only port 1)
            // -------------------------------------------------------
            wire                   read_a_w         = ena && !wea;
            wire                   read_b_w         = enb && !web;
            wire                   read_en_w        = read_a_w || read_b_w;
            wire [AWIDTH-1:0]      read_addr_w      = read_a_w ? addra : addrb;
            wire [BANK_SEL_W-1:0]  read_bank_w      = read_addr_w >> MACRO_AW;
            wire [MACRO_AW-1:0]    read_maddr_w     = read_addr_w[MACRO_AW-1:0];

            // Capture which bank and which output port the read was for
            reg [BANK_SEL_W-1:0]   read_bank_q;
            reg                    read_to_a_q;
            reg                    read_to_b_q;

            always @(posedge clka) begin
                if (!rst_n) begin
                    read_bank_q <= {BANK_SEL_W{1'b0}};
                    read_to_a_q <= 1'b0;
                    read_to_b_q <= 1'b0;
                end else begin
                    read_bank_q <= read_bank_w;
                    read_to_a_q <= read_a_w;
                    read_to_b_q <= (!read_a_w) && read_b_w;
                end
            end

            // -------------------------------------------------------
            // SRAM array: BANKS depth-banks, each MACROS_WIDE macros wide
            // -------------------------------------------------------
            wire [DWIDTH-1:0] macro_dout1_w [0:BANKS-1];

            for (bank_g = 0; bank_g < BANKS; bank_g = bank_g + 1) begin : gen_depth_bank
                wire bank_w_sel = write_en_w && (write_bank_w == bank_g[BANK_SEL_W-1:0]);
                wire bank_r_sel = read_en_w  && (read_bank_w  == bank_g[BANK_SEL_W-1:0]);

                for (wide_g = 0; wide_g < MACROS_WIDE; wide_g = wide_g + 1) begin : gen_width_slice
                    wire [MACRO_DW-1:0] wdata_slice = write_data_w[wide_g*MACRO_DW +: MACRO_DW];
                    wire [MACRO_DW-1:0] dout1_slice;

                    assign macro_dout1_w[bank_g][wide_g*MACRO_DW +: MACRO_DW] = dout1_slice;

                    sky130_sram_2kbyte_1rw1r_32x512_8 u_sram (
                        // RW port (port 0) — used for writes
                        .clk0   (clka),
                        .csb0   (!bank_w_sel),
                        .web0   (!write_en_w),
                        .wmask0 ({MACRO_NMASKS{write_en_w}}),
                        .addr0  (write_maddr_w),
                        .din0   (wdata_slice),
                        .dout0  (),
                        // R-only port (port 1) — used for reads
                        .clk1   (clkb),
                        .csb1   (!bank_r_sel),
                        .addr1  (read_maddr_w),
                        .dout1  (dout1_slice)
                    );
                end
            end

            assign douta = read_to_a_q ? macro_dout1_w[read_bank_q] : {DWIDTH{1'b0}};
            assign doutb = read_to_b_q ? macro_dout1_w[read_bank_q] : {DWIDTH{1'b0}};

        end else begin : gen_rtl_fallback

            // -------------------------------------------------------
            // RTL register fallback for narrow/shallow memories
            // -------------------------------------------------------
            reg [DWIDTH-1:0] mem [0:DEPTH-1];
            reg [DWIDTH-1:0] douta_r;
            reg [DWIDTH-1:0] doutb_r;

            always @(posedge clka) begin
                if (!rst_n)
                    douta_r <= {DWIDTH{1'b0}};
                else if (ena) begin
                    if (wea) mem[addra] <= dina;
                    douta_r <= mem[addra];
                end else
                    douta_r <= {DWIDTH{1'b0}};
            end

            always @(posedge clkb) begin
                if (!rst_n)
                    doutb_r <= {DWIDTH{1'b0}};
                else if (enb) begin
                    if (web) mem[addrb] <= dinb;
                    doutb_r <= mem[addrb];
                end else
                    doutb_r <= {DWIDTH{1'b0}};
            end

            assign douta = douta_r;
            assign doutb = doutb_r;
        end
    endgenerate

endmodule
