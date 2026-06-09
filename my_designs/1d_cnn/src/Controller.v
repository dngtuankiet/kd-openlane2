`timescale 1 ns / 1 ps

module Controller #(
    parameter AWIDTH               = 10,
    parameter DWIDTH               = 16,
    parameter INST_DWIDTH          = 64,
    parameter AXI_WDATA_DWIDTH     = 64,
    parameter EXEC_DEPTH           = 16,
    parameter COL_PE_NUM           = 4,
    parameter ROW_PE_NUM           = 4
)(
    input  wire                    CLK,
    input  wire                    RST,

    //================================//
    //          From Arbiter          //
    //================================//
    input  wire                    load_flag_i,
    input  wire                    start_flag_i,
    input  wire                    done_flag_i,
    input  wire [AWIDTH-1:0]       max_IM_addr_i,
    output wire [2:0]              state_o,
    output wire                    complete_o,

    //================================//
    //        To Weight Memory        //
    //================================//
    output wire                    ctrl_WM_bank0_rd_en_o,
    output wire                    ctrl_WM_bank1_rd_en_o,
    output wire                    ctrl_WM_bank2_rd_en_o,
    output wire                    ctrl_WM_bank3_rd_en_o,

    output wire [AWIDTH-1:0]       ctrl_WM_bank0_addr_o,
    output wire [AWIDTH-1:0]       ctrl_WM_bank1_addr_o,
    output wire [AWIDTH-1:0]       ctrl_WM_bank2_addr_o,
    output wire [AWIDTH-1:0]       ctrl_WM_bank3_addr_o,

    //================================//
    //         To Bias Memory         //
    //================================//
    output wire                    ctrl_BM_bank0_rd_en_o,
    output wire                    ctrl_BM_bank1_rd_en_o,
    output wire                    ctrl_BM_bank2_rd_en_o,
    output wire                    ctrl_BM_bank3_rd_en_o,

    output wire [AWIDTH-1:0]       ctrl_BM_bank0_addr_o,
    output wire [AWIDTH-1:0]       ctrl_BM_bank1_addr_o,
    output wire [AWIDTH-1:0]       ctrl_BM_bank2_addr_o,
    output wire [AWIDTH-1:0]       ctrl_BM_bank3_addr_o,

    //================================//
    //      To Instruction Memory     //
    //================================//
    output wire                    ctrl_IM_rd_en_o,
    output wire [AWIDTH-1:0]       ctrl_IM_addr_o,

    //================================//
    //    From Instruction Memory     //
    //================================//
    input  wire [INST_DWIDTH-1:0]  instruction_i,
    input  wire                    instruction_valid_i,

    //================================//
    //        To Ping FM Memory       //
    //================================//
    output wire                    ctrl_Ping_FM_bank0_rd_en_o,
    output wire                    ctrl_Ping_FM_bank1_rd_en_o,
    output wire                    ctrl_Ping_FM_bank2_rd_en_o,
    output wire                    ctrl_Ping_FM_bank3_rd_en_o,

    output wire                    ctrl_Ping_FM_bank0_wr_en_o,
    output wire                    ctrl_Ping_FM_bank1_wr_en_o,
    output wire                    ctrl_Ping_FM_bank2_wr_en_o,
    output wire                    ctrl_Ping_FM_bank3_wr_en_o,

    output wire [AWIDTH-1:0]       ctrl_Ping_FM_bank0_addr_o,
    output wire [AWIDTH-1:0]       ctrl_Ping_FM_bank1_addr_o,
    output wire [AWIDTH-1:0]       ctrl_Ping_FM_bank2_addr_o,
    output wire [AWIDTH-1:0]       ctrl_Ping_FM_bank3_addr_o,

    //================================//
    //        To Pong FM Memory       //
    //================================//
    output wire                    ctrl_Pong_FM_bank0_rd_en_o,
    output wire                    ctrl_Pong_FM_bank1_rd_en_o,
    output wire                    ctrl_Pong_FM_bank2_rd_en_o,
    output wire                    ctrl_Pong_FM_bank3_rd_en_o,

    output wire                    ctrl_Pong_FM_bank0_wr_en_o,
    output wire                    ctrl_Pong_FM_bank1_wr_en_o,
    output wire                    ctrl_Pong_FM_bank2_wr_en_o,
    output wire                    ctrl_Pong_FM_bank3_wr_en_o,

    output wire [AWIDTH-1:0]       ctrl_Pong_FM_bank0_addr_o,
    output wire [AWIDTH-1:0]       ctrl_Pong_FM_bank1_addr_o,
    output wire [AWIDTH-1:0]       ctrl_Pong_FM_bank2_addr_o,
    output wire [AWIDTH-1:0]       ctrl_Pong_FM_bank3_addr_o,

    //================================//
    //         To IFM Arbiter         //
    //================================//
    output wire [1:0]              ifm_bank0_sel_o,
    output wire [1:0]              ifm_bank1_sel_o,
    output wire [1:0]              ifm_bank2_sel_o,
    output wire [1:0]              ifm_bank3_sel_o,

    //================================//
    //            From PEA            //
    //================================//
    input  wire                    bank0_mem_ofmap_valid_i,
    input  wire                    bank1_mem_ofmap_valid_i,
    input  wire                    bank2_mem_ofmap_valid_i,
    input  wire                    bank3_mem_ofmap_valid_i,

    //================================//
    //             To PEA             //
    //================================//
    output wire                    first_ifmap_o,
    output wire                    last_ifmap_o,
    output wire                    execute_o,
    output wire                    ifm_from_north_o,

    //================================//
    //        To Line Buffer          //
    //================================//
    output wire                    line_buffer_load_o,
    output wire                    line_buffer_bypass_o,
    output wire                    line_buffer_shift_o
);

    //================================//
    //           Localparam           //
    //================================//
    localparam [2:0] s_IDLE        = 3'd0;
    localparam [2:0] s_LOAD        = 3'd1;
    localparam [2:0] s_FETCH       = 3'd2;
    localparam [2:0] s_DECODE      = 3'd3;
    localparam [2:0] s_EXEC        = 3'd4;
    localparam [2:0] s_READ        = 3'd5;

    //================================//
    //       Register Declaration     //
    //================================//
    reg  [2:0]                     current_state_r;
    reg  [2:0]                     next_state_r;

    reg  [AWIDTH:0]                ctrl_IM_addr_r;

    reg  [15:0]                    INPUT_WIDTH_r;
    reg  [11:0]                    IN_CH_r;
    reg  [11:0]                    OUT_CH_r;
    reg  [3:0]                     KERNEL_r;
    reg  [3:0]                     STRIDE_r;
    reg  [3:0]                     PAD_r;
    reg  [15:0]                    OUTPUT_WIDTH_r;

    reg  [15:0]                    INPUT_WIDTH_counter_r;
    reg  [11:0]                    IN_CH_counter_r;
    reg  [11:0]                    OUT_CH_counter_r;
    reg  [3:0]                     KERNEL_counter_r;
	
    reg  [15:0]                    OUTPUT_WIDTH_counter_r;
	reg  [15:0]                    OUTPUT_WIDTH_counter_d1_r;

    reg  [11:0]                    IN_CH_counter_d1_r;
    reg  [11:0]                    IN_CH_counter_d2_r;
    reg  [11:0]                    IN_CH_counter_d3_r;

    reg  [3:0]                     KERNEL_counter_d1_r;
    reg  [3:0]                     KERNEL_counter_d2_r;
    reg  [3:0]                     KERNEL_counter_d3_r;

    reg  [11:0]                    OUT_CH_counter_d1_r;
    reg  [11:0]                    OUT_CH_counter_d2_r;
    reg  [11:0]                    OUT_CH_counter_d3_r;
    reg  [11:0]                    OUT_CH_counter_d4_r;
    reg  [11:0]                    OUT_CH_counter_d5_r;
	
    reg  [1:0]                     OFMAP_row_counter_r;


    reg                            wm_row1_rd_en_r;
    reg                            wm_row2_rd_en_r;
    reg                            wm_row3_rd_en_r;

    reg                            bm_row1_rd_en_r;
    reg                            bm_row2_rd_en_r;
    reg                            bm_row3_rd_en_r;

    reg                            first_ifmap_r;
    reg                            last_ifmap_r;
    reg                            execute_r;
    reg                            ifm_from_north_r;
    reg                            line_buffer_load_r;
    reg                            line_buffer_bypass_r;
    reg                            line_buffer_shift_r;

    reg                            waiting_last_ofmap_r;
	
	reg                            read_WM_BM_stop_r;
	
    reg  [2:0]                     last_ofmap_cnt_r;
	reg                           last_exec_tile_r;
	
    //================================//
    //         Wire Declaration       //
    //================================//
    wire                           fletch_done_flag_w;
    wire                           Ping_Pong_Select_w;

    wire [AWIDTH+3:0]              IFM_bank0_base_addr_w;
    wire [AWIDTH+3:0]              IFM_bank1_base_addr_w;
    wire [AWIDTH+3:0]              IFM_bank2_base_addr_w;
    wire [AWIDTH+3:0]              IFM_bank3_base_addr_w;

    wire                           IFM_bank0_addr_valid_w;
    wire                           IFM_bank1_addr_valid_w;
    wire                           IFM_bank2_addr_valid_w;
    wire                           IFM_bank3_addr_valid_w;

    wire [AWIDTH-1:0]              IFM_bank0_mem_addr_w;
    wire [AWIDTH-1:0]              IFM_bank1_mem_addr_w;
    wire [AWIDTH-1:0]              IFM_bank2_mem_addr_w;
    wire [AWIDTH-1:0]              IFM_bank3_mem_addr_w;

    wire [AWIDTH-1:0]              IFM_kernel_addr_offset_w;

    wire                           IFM_phys_bank0_rd_en_w;
    wire                           IFM_phys_bank1_rd_en_w;
    wire                           IFM_phys_bank2_rd_en_w;
    wire                           IFM_phys_bank3_rd_en_w;

    wire [AWIDTH-1:0]              IFM_phys_bank0_addr_w;
    wire [AWIDTH-1:0]              IFM_phys_bank1_addr_w;
    wire [AWIDTH-1:0]              IFM_phys_bank2_addr_w;
    wire [AWIDTH-1:0]              IFM_phys_bank3_addr_w;

    wire                           kernel_last_w;
    wire                           in_ch_last_w;
    wire                           input_width_last_w;
    wire                           output_width_last_w;
    wire                           out_ch_last_w;

    wire                           kernel_fetch_ifm_w;

    wire                           ofmap_write_fire_w;
    wire [11:0]                    ofmap_out_ch_w;
    wire [AWIDTH-1:0]              ofmap_write_addr_w;
    wire [31:0]                    wm_bank0_addr_calc_w;
    wire [31:0]                    wm_bank1_addr_calc_w;
    wire [31:0]                    wm_bank2_addr_calc_w;
    wire [31:0]                    wm_bank3_addr_calc_w;
    wire [11:0]                    bm_bank0_addr_calc_w;
    wire [11:0]                    bm_bank1_addr_calc_w;
    wire [11:0]                    bm_bank2_addr_calc_w;
    wire [11:0]                    bm_bank3_addr_calc_w;
    wire [AWIDTH+3:0]              IFM_kernel_addr_offset_ext_w;
    wire [AWIDTH+3:0]              PAD_ext_w;
    wire [31:0]                    IFM_bank0_mem_addr_calc_w;
    wire [31:0]                    IFM_bank1_mem_addr_calc_w;
    wire [31:0]                    IFM_bank2_mem_addr_calc_w;
    wire [31:0]                    IFM_bank3_mem_addr_calc_w;
    wire [11:0]                    OFMAP_row_counter_ext_w;
    wire [31:0]                    ofmap_write_addr_calc_w;

    wire                           wm_row0_rd_en_w;
    wire                           bm_row0_rd_en_w;

    wire                           first_ifmap_int_w;
    wire                           last_ifmap_int_w;
    wire                           execute_int_w;

    wire                           ifm_from_north_pre_w;
    wire                           line_buffer_load_pre_w;
    wire                           line_buffer_bypass_pre_w;
    wire                           line_buffer_shift_pre_w;

    wire                           last_ifm_issue_w;
    wire                           last_ofmap_valid_w;
    wire                           last_exec_tile_w;
    wire                           last_ofmap_count_hit_w;
    localparam [2:0]               ROW_PE_NUM_LOCAL = ROW_PE_NUM;
    localparam [1:0]               OFMAP_ROW_LAST = ROW_PE_NUM_LOCAL[1:0] - 2'd1;

    //================================//
    //              FSM               //
    //================================//
    always @(*) begin
        case (current_state_r)
            s_IDLE:   next_state_r = load_flag_i ? s_LOAD : s_IDLE;
            s_LOAD:   next_state_r = start_flag_i ? s_FETCH : s_LOAD;
            s_FETCH:  next_state_r = fletch_done_flag_w ? s_DECODE : s_FETCH;
            s_DECODE: next_state_r = instruction_valid_i ? s_EXEC : s_READ;
            s_EXEC:   next_state_r = last_ofmap_valid_w ?
                                     ((ctrl_IM_addr_r > {1'b0, max_IM_addr_i}) ? s_READ : s_FETCH) :
                                     s_EXEC;
            s_READ:   next_state_r = done_flag_i ? s_IDLE : s_READ;
            default:  next_state_r = s_IDLE;
        endcase
    end

    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            current_state_r <= s_IDLE;
        end
        else begin
            current_state_r <= next_state_r;
        end
    end

    assign state_o                 = current_state_r;
    assign complete_o              = (current_state_r == s_READ);

    //================================//
    //           FETCH State          //
    //================================//
    assign ctrl_IM_rd_en_o         = (current_state_r == s_FETCH);
    assign ctrl_IM_addr_o          = ctrl_IM_addr_r[AWIDTH-1:0];
    assign fletch_done_flag_w      = ctrl_IM_rd_en_o;

    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            ctrl_IM_addr_r         <= {(AWIDTH+1){1'b0}};
        end
        else begin
            if (current_state_r == s_IDLE) begin
                ctrl_IM_addr_r     <= {(AWIDTH+1){1'b0}};
            end
            else if (current_state_r == s_FETCH) begin
                ctrl_IM_addr_r     <= ctrl_IM_addr_r + 1'b1;
            end
        end
    end

    //================================//
    //          DECODE State          //
    //================================//
    function [15:0] calc_out_width;
        input [15:0] in_width_i;
        input [3:0]  stride_i;
        begin
            case (stride_i)
                4'd1: calc_out_width = in_width_i;
                4'd2: calc_out_width = (in_width_i + 16'd1) >> 1;
                default: calc_out_width = in_width_i;
            endcase
        end
    endfunction

    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            INPUT_WIDTH_r          <= 16'd0;
            IN_CH_r                <= 12'd0;
            OUT_CH_r               <= 12'd0;
            KERNEL_r               <= 4'd0;
            STRIDE_r               <= 4'd0;
            PAD_r                  <= 4'd0;
            OUTPUT_WIDTH_r         <= 16'd0;
        end
        else begin
            if (current_state_r == s_IDLE) begin
                INPUT_WIDTH_r      <= 16'd0;
                IN_CH_r            <= 12'd0;
                OUT_CH_r           <= 12'd0;
                KERNEL_r           <= 4'd0;
                STRIDE_r           <= 4'd0;
                PAD_r              <= 4'd0;
                OUTPUT_WIDTH_r     <= 16'd0;
            end
            else if ((current_state_r == s_DECODE) && instruction_valid_i) begin
                INPUT_WIDTH_r      <= instruction_i[59:44];
                IN_CH_r            <= instruction_i[43:32];
                OUT_CH_r           <= instruction_i[31:20];
                KERNEL_r           <= instruction_i[19:16];
                STRIDE_r           <= instruction_i[15:12];
                PAD_r              <= instruction_i[11:8];
                OUTPUT_WIDTH_r     <= calc_out_width(instruction_i[59:44], instruction_i[15:12]);
            end
        end
    end

    //================================//
    //           EXEC State           //
    //================================//
    assign kernel_last_w           = (KERNEL_counter_r       == (KERNEL_r       - 1'b1));
    assign in_ch_last_w            = (IN_CH_counter_r        == (IN_CH_r         - 1'b1));
    assign input_width_last_w      = (INPUT_WIDTH_counter_r  >= (INPUT_WIDTH_r   - COL_PE_NUM));
	
    assign output_width_last_w     = (OUTPUT_WIDTH_counter_r >= (OUTPUT_WIDTH_r  - COL_PE_NUM));
    assign out_ch_last_w           = (OUT_CH_counter_r       >= (OUT_CH_r        - ROW_PE_NUM));

    assign kernel_fetch_ifm_w      = (KERNEL_counter_r == 4'd0) ||
                                     (KERNEL_counter_r == 4'd1) ||
                                     (KERNEL_counter_r == 4'd5);

    assign last_ifm_issue_w        = (current_state_r == s_EXEC) &&
                                     kernel_fetch_ifm_w &&
                                     kernel_last_w &&
                                     in_ch_last_w &&
                                     input_width_last_w &&
                                     output_width_last_w &&
                                     out_ch_last_w;

    // assign last_exec_tile_w        = (OUTPUT_WIDTH_counter_d1_r >= (OUTPUT_WIDTH_r  - COL_PE_NUM)) && out_ch_last_w && last_ifmap_r;
	assign last_exec_tile_w			= read_WM_BM_stop_r;
    assign last_ofmap_count_hit_w  = (last_ofmap_cnt_r == (ROW_PE_NUM-1));

    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            INPUT_WIDTH_counter_r  <= 16'd0;
            IN_CH_counter_r        <= 12'd0;
            OUT_CH_counter_r       <= 12'd0;
            KERNEL_counter_r       <= 4'd0;
			
            OUTPUT_WIDTH_counter_r <= 16'd0;
			OUTPUT_WIDTH_counter_d1_r	<= 16'd0;

            IN_CH_counter_d1_r     <= 12'd0;
            IN_CH_counter_d2_r     <= 12'd0;
            IN_CH_counter_d3_r     <= 12'd0;

            KERNEL_counter_d1_r    <= 4'd0;
            KERNEL_counter_d2_r    <= 4'd0;
            KERNEL_counter_d3_r    <= 4'd0;

            OUT_CH_counter_d1_r    <= 12'd0;
            OUT_CH_counter_d2_r    <= 12'd0;
            OUT_CH_counter_d3_r    <= 12'd0;
            OUT_CH_counter_d4_r    <= 12'd0;
            OUT_CH_counter_d5_r    <= 12'd0;

            waiting_last_ofmap_r   <= 1'b0;
            last_ofmap_cnt_r       <= 3'd0;
			last_exec_tile_r		<= 0;
			
			read_WM_BM_stop_r			<= 0;
        end
        else begin
            if (current_state_r == s_EXEC) begin
				if(in_ch_last_w && kernel_last_w && input_width_last_w && out_ch_last_w && output_width_last_w)
					read_WM_BM_stop_r	<= 1'b1;
				else
					read_WM_BM_stop_r	<= read_WM_BM_stop_r;
					
				if(last_exec_tile_w)
					last_exec_tile_r	<= last_exec_tile_w;
				else 
					last_exec_tile_r	<= last_exec_tile_r;
					
                if (last_exec_tile_r && bank0_mem_ofmap_valid_i) begin
                    last_ofmap_cnt_r <= last_ofmap_cnt_r + 1'b1;
                end
                else begin
                    last_ofmap_cnt_r <= 0;
                end

                if (!waiting_last_ofmap_r) begin
					OUTPUT_WIDTH_counter_d1_r	<= OUTPUT_WIDTH_counter_r;
						
                    IN_CH_counter_d1_r <= IN_CH_counter_r;
                    IN_CH_counter_d2_r <= IN_CH_counter_d1_r;
                    IN_CH_counter_d3_r <= IN_CH_counter_d2_r;

                    KERNEL_counter_d1_r <= KERNEL_counter_r;
                    KERNEL_counter_d2_r <= KERNEL_counter_d1_r;
                    KERNEL_counter_d3_r <= KERNEL_counter_d2_r;

                    OUT_CH_counter_d1_r <= OUT_CH_counter_r;
                    OUT_CH_counter_d2_r <= OUT_CH_counter_d1_r;
                    OUT_CH_counter_d3_r <= OUT_CH_counter_d2_r;
					OUT_CH_counter_d4_r <= OUT_CH_counter_d3_r;
					OUT_CH_counter_d5_r <= OUT_CH_counter_d4_r;
				
                    if (kernel_last_w) begin
                        KERNEL_counter_r <= 4'd0;

                        if (in_ch_last_w) begin
                            IN_CH_counter_r <= 12'd0;

							if (output_width_last_w) begin
                                OUTPUT_WIDTH_counter_r <= 16'd0;
							
                                if (out_ch_last_w) begin
                                    OUT_CH_counter_r <= 12'd0;
                                end
                                else begin
                                    OUT_CH_counter_r <= OUT_CH_counter_r + ROW_PE_NUM;
                                end
                            end
                            else begin
                                OUTPUT_WIDTH_counter_r <= OUTPUT_WIDTH_counter_r + COL_PE_NUM;
                            end
								
                            if (input_width_last_w) begin
                                INPUT_WIDTH_counter_r <= 16'd0;
                            end
                            else begin
                                INPUT_WIDTH_counter_r <= INPUT_WIDTH_counter_r + ROW_PE_NUM;
                            end
                        end
                        else begin
                            IN_CH_counter_r <= IN_CH_counter_r + 1'b1;
                        end
                    end
                    else begin
                        KERNEL_counter_r <= KERNEL_counter_r + 1'b1;
                    end
                end
            end
            else begin
                INPUT_WIDTH_counter_r  <= 16'd0;
                IN_CH_counter_r        <= 12'd0;
                OUT_CH_counter_r       <= 12'd0;
                KERNEL_counter_r       <= 4'd0;
                OUTPUT_WIDTH_counter_r <= 16'd0;
				OUTPUT_WIDTH_counter_d1_r	<= 16'd0;

                IN_CH_counter_d1_r     <= 12'd0;
                IN_CH_counter_d2_r     <= 12'd0;
                IN_CH_counter_d3_r     <= 12'd0;

                KERNEL_counter_d1_r    <= 4'd0;
                KERNEL_counter_d2_r    <= 4'd0;
                KERNEL_counter_d3_r    <= 4'd0;

                OUT_CH_counter_d1_r    <= 12'd0;
                OUT_CH_counter_d2_r    <= 12'd0;
                OUT_CH_counter_d3_r    <= 12'd0;
                OUT_CH_counter_d4_r    <= 12'd0;
                OUT_CH_counter_d5_r    <= 12'd0;
				
                waiting_last_ofmap_r   <= 1'b0;
                last_ofmap_cnt_r       <= 3'd0;
				last_exec_tile_r		<= 0;
				
				read_WM_BM_stop_r			<= 0;
            end
        end
    end

    //================================//
    //         Weight Memory          //
    //================================//
    assign wm_row0_rd_en_w         = (current_state_r == s_EXEC) && !read_WM_BM_stop_r;

    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            wm_row1_rd_en_r <= 1'b0;
            wm_row2_rd_en_r <= 1'b0;
            wm_row3_rd_en_r <= 1'b0;
        end
        else begin
            wm_row1_rd_en_r <= wm_row0_rd_en_w;
            wm_row2_rd_en_r <= wm_row1_rd_en_r;
            wm_row3_rd_en_r <= wm_row2_rd_en_r;
        end
    end

    assign ctrl_WM_bank0_rd_en_o   = wm_row0_rd_en_w;
    assign ctrl_WM_bank1_rd_en_o   = wm_row1_rd_en_r;
    assign ctrl_WM_bank2_rd_en_o   = wm_row2_rd_en_r;
    assign ctrl_WM_bank3_rd_en_o   = wm_row3_rd_en_r;

    assign wm_bank0_addr_calc_w    = (((({20'd0, OUT_CH_counter_r} >> 2)    * {20'd0, IN_CH_r}) + {20'd0, IN_CH_counter_r})    * {28'd0, KERNEL_r}) + {28'd0, KERNEL_counter_r};
    assign wm_bank1_addr_calc_w    = (((({20'd0, OUT_CH_counter_d1_r} >> 2) * {20'd0, IN_CH_r}) + {20'd0, IN_CH_counter_d1_r}) * {28'd0, KERNEL_r}) + {28'd0, KERNEL_counter_d1_r};
    assign wm_bank2_addr_calc_w    = (((({20'd0, OUT_CH_counter_d2_r} >> 2) * {20'd0, IN_CH_r}) + {20'd0, IN_CH_counter_d2_r}) * {28'd0, KERNEL_r}) + {28'd0, KERNEL_counter_d2_r};
    assign wm_bank3_addr_calc_w    = (((({20'd0, OUT_CH_counter_d3_r} >> 2) * {20'd0, IN_CH_r}) + {20'd0, IN_CH_counter_d3_r}) * {28'd0, KERNEL_r}) + {28'd0, KERNEL_counter_d3_r};

	assign ctrl_WM_bank0_addr_o = ctrl_WM_bank0_rd_en_o ? wm_bank0_addr_calc_w[AWIDTH-1:0] : {AWIDTH{1'b0}};
	assign ctrl_WM_bank1_addr_o = ctrl_WM_bank1_rd_en_o ? wm_bank1_addr_calc_w[AWIDTH-1:0] : {AWIDTH{1'b0}};
	assign ctrl_WM_bank2_addr_o = ctrl_WM_bank2_rd_en_o ? wm_bank2_addr_calc_w[AWIDTH-1:0] : {AWIDTH{1'b0}};
	assign ctrl_WM_bank3_addr_o = ctrl_WM_bank3_rd_en_o ? wm_bank3_addr_calc_w[AWIDTH-1:0] : {AWIDTH{1'b0}};

    //================================//
    //          Bias Memory           //
    //================================//
    assign bm_row0_rd_en_w         = (current_state_r == s_EXEC) &&
                                     (KERNEL_counter_r == 0) &&
                                     (IN_CH_counter_r == 0) &&
                                     !read_WM_BM_stop_r;

    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            bm_row1_rd_en_r <= 1'b0;
            bm_row2_rd_en_r <= 1'b0;
            bm_row3_rd_en_r <= 1'b0;
        end
        else begin
            bm_row1_rd_en_r <= bm_row0_rd_en_w;
            bm_row2_rd_en_r <= bm_row1_rd_en_r;
            bm_row3_rd_en_r <= bm_row2_rd_en_r;
        end
    end

    assign ctrl_BM_bank0_rd_en_o   = bm_row0_rd_en_w;
    assign ctrl_BM_bank1_rd_en_o   = bm_row1_rd_en_r;
    assign ctrl_BM_bank2_rd_en_o   = bm_row2_rd_en_r;
    assign ctrl_BM_bank3_rd_en_o   = bm_row3_rd_en_r;

    assign bm_bank0_addr_calc_w    = OUT_CH_counter_r    >> 2;
    assign bm_bank1_addr_calc_w    = OUT_CH_counter_d1_r >> 2;
    assign bm_bank2_addr_calc_w    = OUT_CH_counter_d2_r >> 2;
    assign bm_bank3_addr_calc_w    = OUT_CH_counter_d3_r >> 2;

    assign ctrl_BM_bank0_addr_o    = bm_row0_rd_en_w ? bm_bank0_addr_calc_w[AWIDTH-1:0] : {AWIDTH{1'b0}};
    assign ctrl_BM_bank1_addr_o    = bm_row1_rd_en_r ? bm_bank1_addr_calc_w[AWIDTH-1:0] : {AWIDTH{1'b0}};
    assign ctrl_BM_bank2_addr_o    = bm_row2_rd_en_r ? bm_bank2_addr_calc_w[AWIDTH-1:0] : {AWIDTH{1'b0}};
    assign ctrl_BM_bank3_addr_o    = bm_row3_rd_en_r ? bm_bank3_addr_calc_w[AWIDTH-1:0] : {AWIDTH{1'b0}};

    //================================//
    //      IFM Address Generation    //
    //================================//
    assign IFM_kernel_addr_offset_w = (KERNEL_counter_r == 4'd1) ? {{(AWIDTH-4){1'b0}}, 4'd4} :
                                      (KERNEL_counter_r == 4'd5) ? {{(AWIDTH-4){1'b0}}, 4'd8} :
                                      {AWIDTH{1'b0}};

    assign IFM_kernel_addr_offset_ext_w = {{4{1'b0}}, IFM_kernel_addr_offset_w};
    assign PAD_ext_w                    = {{AWIDTH{1'b0}}, PAD_r};

    assign IFM_bank0_base_addr_w   = INPUT_WIDTH_counter_r[AWIDTH+3:0] - PAD_ext_w + IFM_kernel_addr_offset_ext_w;
    assign IFM_bank1_base_addr_w   = INPUT_WIDTH_counter_r[AWIDTH+3:0] + {{(AWIDTH+3){1'b0}}, 1'b1} - PAD_ext_w + IFM_kernel_addr_offset_ext_w;
    assign IFM_bank2_base_addr_w   = INPUT_WIDTH_counter_r[AWIDTH+3:0] + {{(AWIDTH+2){1'b0}}, 2'd2} - PAD_ext_w + IFM_kernel_addr_offset_ext_w;
    assign IFM_bank3_base_addr_w   = INPUT_WIDTH_counter_r[AWIDTH+3:0] + {{(AWIDTH+2){1'b0}}, 2'd3} - PAD_ext_w + IFM_kernel_addr_offset_ext_w;

    assign ifm_bank0_sel_o         = IFM_bank0_base_addr_w[1:0];
    assign ifm_bank1_sel_o         = IFM_bank1_base_addr_w[1:0];
    assign ifm_bank2_sel_o         = IFM_bank2_base_addr_w[1:0];
    assign ifm_bank3_sel_o         = IFM_bank3_base_addr_w[1:0];

    assign IFM_bank0_addr_valid_w  = (IFM_bank0_base_addr_w < INPUT_WIDTH_r[AWIDTH+3:0]);
    assign IFM_bank1_addr_valid_w  = (IFM_bank1_base_addr_w < INPUT_WIDTH_r[AWIDTH+3:0]);
    assign IFM_bank2_addr_valid_w  = (IFM_bank2_base_addr_w < INPUT_WIDTH_r[AWIDTH+3:0]);
    assign IFM_bank3_addr_valid_w  = (IFM_bank3_base_addr_w < INPUT_WIDTH_r[AWIDTH+3:0]);

    assign IFM_bank0_mem_addr_calc_w = (({20'd0, IN_CH_counter_r} * {16'd0, INPUT_WIDTH_r}) >> 2) + {{(32-AWIDTH){1'b0}}, IFM_bank0_base_addr_w[AWIDTH+1:2]};
    assign IFM_bank1_mem_addr_calc_w = (({20'd0, IN_CH_counter_r} * {16'd0, INPUT_WIDTH_r}) >> 2) + {{(32-AWIDTH){1'b0}}, IFM_bank1_base_addr_w[AWIDTH+1:2]};
    assign IFM_bank2_mem_addr_calc_w = (({20'd0, IN_CH_counter_r} * {16'd0, INPUT_WIDTH_r}) >> 2) + {{(32-AWIDTH){1'b0}}, IFM_bank2_base_addr_w[AWIDTH+1:2]};
    assign IFM_bank3_mem_addr_calc_w = (({20'd0, IN_CH_counter_r} * {16'd0, INPUT_WIDTH_r}) >> 2) + {{(32-AWIDTH){1'b0}}, IFM_bank3_base_addr_w[AWIDTH+1:2]};

    assign IFM_bank0_mem_addr_w    = IFM_bank0_mem_addr_calc_w[AWIDTH-1:0];
    assign IFM_bank1_mem_addr_w    = IFM_bank1_mem_addr_calc_w[AWIDTH-1:0];
    assign IFM_bank2_mem_addr_w    = IFM_bank2_mem_addr_calc_w[AWIDTH-1:0];
    assign IFM_bank3_mem_addr_w    = IFM_bank3_mem_addr_calc_w[AWIDTH-1:0];

    assign IFM_phys_bank0_rd_en_w  = ((ifm_bank0_sel_o == 2'd0) && IFM_bank0_addr_valid_w) ||
                                     ((ifm_bank1_sel_o == 2'd0) && IFM_bank1_addr_valid_w) ||
                                     ((ifm_bank2_sel_o == 2'd0) && IFM_bank2_addr_valid_w) ||
                                     ((ifm_bank3_sel_o == 2'd0) && IFM_bank3_addr_valid_w);

    assign IFM_phys_bank1_rd_en_w  = ((ifm_bank0_sel_o == 2'd1) && IFM_bank0_addr_valid_w) ||
                                     ((ifm_bank1_sel_o == 2'd1) && IFM_bank1_addr_valid_w) ||
                                     ((ifm_bank2_sel_o == 2'd1) && IFM_bank2_addr_valid_w) ||
                                     ((ifm_bank3_sel_o == 2'd1) && IFM_bank3_addr_valid_w);

    assign IFM_phys_bank2_rd_en_w  = ((ifm_bank0_sel_o == 2'd2) && IFM_bank0_addr_valid_w) ||
                                     ((ifm_bank1_sel_o == 2'd2) && IFM_bank1_addr_valid_w) ||
                                     ((ifm_bank2_sel_o == 2'd2) && IFM_bank2_addr_valid_w) ||
                                     ((ifm_bank3_sel_o == 2'd2) && IFM_bank3_addr_valid_w);

    assign IFM_phys_bank3_rd_en_w  = ((ifm_bank0_sel_o == 2'd3) && IFM_bank0_addr_valid_w) ||
                                     ((ifm_bank1_sel_o == 2'd3) && IFM_bank1_addr_valid_w) ||
                                     ((ifm_bank2_sel_o == 2'd3) && IFM_bank2_addr_valid_w) ||
                                     ((ifm_bank3_sel_o == 2'd3) && IFM_bank3_addr_valid_w);

    assign IFM_phys_bank0_addr_w   = ((ifm_bank0_sel_o == 2'd0) && IFM_bank0_addr_valid_w) ? IFM_bank0_mem_addr_w :
                                     ((ifm_bank1_sel_o == 2'd0) && IFM_bank1_addr_valid_w) ? IFM_bank1_mem_addr_w :
                                     ((ifm_bank2_sel_o == 2'd0) && IFM_bank2_addr_valid_w) ? IFM_bank2_mem_addr_w :
                                     ((ifm_bank3_sel_o == 2'd0) && IFM_bank3_addr_valid_w) ? IFM_bank3_mem_addr_w :
                                                                                              {AWIDTH{1'b0}};

    assign IFM_phys_bank1_addr_w   = ((ifm_bank0_sel_o == 2'd1) && IFM_bank0_addr_valid_w) ? IFM_bank0_mem_addr_w :
                                     ((ifm_bank1_sel_o == 2'd1) && IFM_bank1_addr_valid_w) ? IFM_bank1_mem_addr_w :
                                     ((ifm_bank2_sel_o == 2'd1) && IFM_bank2_addr_valid_w) ? IFM_bank2_mem_addr_w :
                                     ((ifm_bank3_sel_o == 2'd1) && IFM_bank3_addr_valid_w) ? IFM_bank3_mem_addr_w :
                                                                                              {AWIDTH{1'b0}};

    assign IFM_phys_bank2_addr_w   = ((ifm_bank0_sel_o == 2'd2) && IFM_bank0_addr_valid_w) ? IFM_bank0_mem_addr_w :
                                     ((ifm_bank1_sel_o == 2'd2) && IFM_bank1_addr_valid_w) ? IFM_bank1_mem_addr_w :
                                     ((ifm_bank2_sel_o == 2'd2) && IFM_bank2_addr_valid_w) ? IFM_bank2_mem_addr_w :
                                     ((ifm_bank3_sel_o == 2'd2) && IFM_bank3_addr_valid_w) ? IFM_bank3_mem_addr_w :
                                                                                              {AWIDTH{1'b0}};

    assign IFM_phys_bank3_addr_w   = ((ifm_bank0_sel_o == 2'd3) && IFM_bank0_addr_valid_w) ? IFM_bank0_mem_addr_w :
                                     ((ifm_bank1_sel_o == 2'd3) && IFM_bank1_addr_valid_w) ? IFM_bank1_mem_addr_w :
                                     ((ifm_bank2_sel_o == 2'd3) && IFM_bank2_addr_valid_w) ? IFM_bank2_mem_addr_w :
                                     ((ifm_bank3_sel_o == 2'd3) && IFM_bank3_addr_valid_w) ? IFM_bank3_mem_addr_w :
                                                                                              {AWIDTH{1'b0}};

    assign Ping_Pong_Select_w      = ctrl_IM_addr_r[0];

    //================================//
    //        OFMAP Write-Back        //
    //================================//
    assign ofmap_write_fire_w      = bank0_mem_ofmap_valid_i |
                                     bank1_mem_ofmap_valid_i |
                                     bank2_mem_ofmap_valid_i |
                                     bank3_mem_ofmap_valid_i;

    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            OFMAP_row_counter_r <= 2'd0;
        end
        else begin
            if (current_state_r != s_EXEC) begin
                OFMAP_row_counter_r <= 2'd0;
            end
            else if (ofmap_write_fire_w) begin
                if (OFMAP_row_counter_r == OFMAP_ROW_LAST) begin
                    OFMAP_row_counter_r <= 2'd0;
                end
                else begin
                    OFMAP_row_counter_r <= OFMAP_row_counter_r + 1'b1;
                end
            end
        end
    end

    assign OFMAP_row_counter_ext_w = {{10{1'b0}}, OFMAP_row_counter_r};
    assign ofmap_out_ch_w          = OUT_CH_counter_d5_r + OFMAP_row_counter_ext_w;
    assign ofmap_write_addr_calc_w = (OUTPUT_WIDTH_counter_r == 0) ?
									((({20'd0, ofmap_out_ch_w} * {16'd0, OUTPUT_WIDTH_r}) >> 2) + (({16'd0, OUTPUT_WIDTH_r} - ROW_PE_NUM) >> 2)):
									((({20'd0, ofmap_out_ch_w} * {16'd0, OUTPUT_WIDTH_r}) >> 2) + (({16'd0, OUTPUT_WIDTH_counter_r} - ROW_PE_NUM) >> 2));
    assign ofmap_write_addr_w      = ofmap_write_addr_calc_w[AWIDTH-1:0];
	// assign ofmap_write_addr_w      = (((ofmap_out_ch_w * OUTPUT_WIDTH_r) >> 2) + ((OUTPUT_WIDTH_counter_d1_r-ROW_PE_NUM) >> 2));
									  
    assign last_ofmap_valid_w      = last_exec_tile_r &&
                                     bank0_mem_ofmap_valid_i &&
                                     last_ofmap_count_hit_w;

    //================================//
    //         Ping FM Memory         //
    //================================//
    assign ctrl_Ping_FM_bank0_rd_en_o = (current_state_r == s_EXEC) &&
                                        Ping_Pong_Select_w &&
                                        kernel_fetch_ifm_w &&
                                        IFM_phys_bank0_rd_en_w &&
                                        !read_WM_BM_stop_r;

    assign ctrl_Ping_FM_bank1_rd_en_o = (current_state_r == s_EXEC) &&
                                        Ping_Pong_Select_w &&
                                        kernel_fetch_ifm_w &&
                                        IFM_phys_bank1_rd_en_w &&
                                        !read_WM_BM_stop_r;

    assign ctrl_Ping_FM_bank2_rd_en_o = (current_state_r == s_EXEC) &&
                                        Ping_Pong_Select_w &&
                                        kernel_fetch_ifm_w &&
                                        IFM_phys_bank2_rd_en_w &&
                                        !read_WM_BM_stop_r;

    assign ctrl_Ping_FM_bank3_rd_en_o = (current_state_r == s_EXEC) &&
                                        Ping_Pong_Select_w &&
                                        kernel_fetch_ifm_w &&
                                        IFM_phys_bank3_rd_en_w &&
                                        !read_WM_BM_stop_r;

    assign ctrl_Ping_FM_bank0_wr_en_o = (current_state_r == s_EXEC) &&
                                        (~Ping_Pong_Select_w) &&
                                        bank0_mem_ofmap_valid_i;

    assign ctrl_Ping_FM_bank1_wr_en_o = (current_state_r == s_EXEC) &&
                                        (~Ping_Pong_Select_w) &&
                                        bank1_mem_ofmap_valid_i;

    assign ctrl_Ping_FM_bank2_wr_en_o = (current_state_r == s_EXEC) &&
                                        (~Ping_Pong_Select_w) &&
                                        bank2_mem_ofmap_valid_i;

    assign ctrl_Ping_FM_bank3_wr_en_o = (current_state_r == s_EXEC) &&
                                        (~Ping_Pong_Select_w) &&
                                        bank3_mem_ofmap_valid_i;

    assign ctrl_Ping_FM_bank0_addr_o  = ctrl_Ping_FM_bank0_rd_en_o ? IFM_phys_bank0_addr_w :
                                        ctrl_Ping_FM_bank0_wr_en_o ? ofmap_write_addr_w :
                                        {AWIDTH{1'b0}};

    assign ctrl_Ping_FM_bank1_addr_o  = ctrl_Ping_FM_bank1_rd_en_o ? IFM_phys_bank1_addr_w :
                                        ctrl_Ping_FM_bank1_wr_en_o ? ofmap_write_addr_w :
                                        {AWIDTH{1'b0}};

    assign ctrl_Ping_FM_bank2_addr_o  = ctrl_Ping_FM_bank2_rd_en_o ? IFM_phys_bank2_addr_w :
                                        ctrl_Ping_FM_bank2_wr_en_o ? ofmap_write_addr_w :
                                        {AWIDTH{1'b0}};

    assign ctrl_Ping_FM_bank3_addr_o  = ctrl_Ping_FM_bank3_rd_en_o ? IFM_phys_bank3_addr_w :
                                        ctrl_Ping_FM_bank3_wr_en_o ? ofmap_write_addr_w :
                                        {AWIDTH{1'b0}};

    //================================//
    //         Pong FM Memory         //
    //================================//
    assign ctrl_Pong_FM_bank0_rd_en_o = (current_state_r == s_EXEC) &&
                                        (~Ping_Pong_Select_w) &&
                                        kernel_fetch_ifm_w &&
                                        IFM_phys_bank0_rd_en_w &&
                                        !read_WM_BM_stop_r;

    assign ctrl_Pong_FM_bank1_rd_en_o = (current_state_r == s_EXEC) &&
                                        (~Ping_Pong_Select_w) &&
                                        kernel_fetch_ifm_w &&
                                        IFM_phys_bank1_rd_en_w &&
                                        !read_WM_BM_stop_r;

    assign ctrl_Pong_FM_bank2_rd_en_o = (current_state_r == s_EXEC) &&
                                        (~Ping_Pong_Select_w) &&
                                        kernel_fetch_ifm_w &&
                                        IFM_phys_bank2_rd_en_w &&
                                        !read_WM_BM_stop_r;

    assign ctrl_Pong_FM_bank3_rd_en_o = (current_state_r == s_EXEC) &&
                                        (~Ping_Pong_Select_w) &&
                                        kernel_fetch_ifm_w &&
                                        IFM_phys_bank3_rd_en_w &&
                                        !read_WM_BM_stop_r;

    assign ctrl_Pong_FM_bank0_wr_en_o = (current_state_r == s_EXEC) &&
                                        Ping_Pong_Select_w &&
                                        bank0_mem_ofmap_valid_i;

    assign ctrl_Pong_FM_bank1_wr_en_o = (current_state_r == s_EXEC) &&
                                        Ping_Pong_Select_w &&
                                        bank1_mem_ofmap_valid_i;

    assign ctrl_Pong_FM_bank2_wr_en_o = (current_state_r == s_EXEC) &&
                                        Ping_Pong_Select_w &&
                                        bank2_mem_ofmap_valid_i;

    assign ctrl_Pong_FM_bank3_wr_en_o = (current_state_r == s_EXEC) &&
                                        Ping_Pong_Select_w &&
                                        bank3_mem_ofmap_valid_i;

    assign ctrl_Pong_FM_bank0_addr_o  = ctrl_Pong_FM_bank0_rd_en_o ? IFM_phys_bank0_addr_w :
                                        ctrl_Pong_FM_bank0_wr_en_o ? ofmap_write_addr_w :
                                        {AWIDTH{1'b0}};

    assign ctrl_Pong_FM_bank1_addr_o  = ctrl_Pong_FM_bank1_rd_en_o ? IFM_phys_bank1_addr_w :
                                        ctrl_Pong_FM_bank1_wr_en_o ? ofmap_write_addr_w :
                                        {AWIDTH{1'b0}};

    assign ctrl_Pong_FM_bank2_addr_o  = ctrl_Pong_FM_bank2_rd_en_o ? IFM_phys_bank2_addr_w :
                                        ctrl_Pong_FM_bank2_wr_en_o ? ofmap_write_addr_w :
                                        {AWIDTH{1'b0}};

    assign ctrl_Pong_FM_bank3_addr_o  = ctrl_Pong_FM_bank3_rd_en_o ? IFM_phys_bank3_addr_w :
                                        ctrl_Pong_FM_bank3_wr_en_o ? ofmap_write_addr_w :
                                        {AWIDTH{1'b0}};

    //================================//
    //         To PEA Control         //
    //================================//
    assign first_ifmap_int_w        = (current_state_r == s_EXEC) &&
                                      (KERNEL_counter_r == 4'd0) &&
                                      (IN_CH_counter_r == 0) &&
                                      !waiting_last_ofmap_r;

    assign last_ifmap_int_w         = (current_state_r == s_EXEC) &&
                                      kernel_last_w &&
                                      in_ch_last_w &&
                                      !waiting_last_ofmap_r;

    assign execute_int_w            = (current_state_r == s_EXEC) &&
                                      !waiting_last_ofmap_r;

    assign ifm_from_north_pre_w     = (current_state_r == s_EXEC) &&
                                      (KERNEL_counter_r == 4'd0) &&
                                      !waiting_last_ofmap_r;

    assign line_buffer_load_pre_w   = (current_state_r == s_EXEC) &&
                                      ((KERNEL_counter_r == 4'd1) ||
                                       (KERNEL_counter_r == 4'd5)) &&
                                      !waiting_last_ofmap_r;

    assign line_buffer_bypass_pre_w = line_buffer_load_pre_w;

    assign line_buffer_shift_pre_w  = (current_state_r == s_EXEC) &&
                                      !waiting_last_ofmap_r &&
                                      !ifm_from_north_pre_w &&
                                      !line_buffer_bypass_pre_w &&
                                      !last_ifm_issue_w;

    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            first_ifmap_r        <= 1'b0;
            last_ifmap_r         <= 1'b0;
            execute_r            <= 1'b0;
            ifm_from_north_r     <= 1'b0;
            line_buffer_load_r   <= 1'b0;
            line_buffer_bypass_r <= 1'b0;
            line_buffer_shift_r  <= 1'b0;
        end
        else begin
            first_ifmap_r        <= first_ifmap_int_w;
            last_ifmap_r         <= last_ifmap_int_w;
            execute_r            <= execute_int_w;

            // delay 1 cycle to match IFMAP memory output
            ifm_from_north_r     <= ifm_from_north_pre_w;
            line_buffer_load_r   <= line_buffer_load_pre_w;
            line_buffer_bypass_r <= line_buffer_bypass_pre_w;
            line_buffer_shift_r  <= line_buffer_shift_pre_w;
        end
    end

    assign first_ifmap_o           = first_ifmap_r;
    assign last_ifmap_o            = last_ifmap_r;
    assign execute_o               = execute_r;
    assign ifm_from_north_o        = ifm_from_north_r;
    assign line_buffer_load_o      = line_buffer_load_r;
    assign line_buffer_bypass_o    = line_buffer_bypass_r;
    assign line_buffer_shift_o     = line_buffer_shift_r;

endmodule
