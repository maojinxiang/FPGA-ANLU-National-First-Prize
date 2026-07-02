`timescale 1ns / 1ps

//********************************************************************************
// Module : udp_to_sdram_writer
// Function: 鎺ユ敹UDP瀛楄妭娴侊紝鍚堟垚32浣峈GB鏁版嵁骞跺啓鍏DRAM锛堝幓闄dr_init_done渚濊禆锛?
//********************************************************************************
module udp_to_sdram_writer
#(
    parameter PIXEL_COUNT = 307200 // 640*480 pixels per frame
)
(
    input                   clk,            // udp_clk domain
    input                   reset,          // active-high reset

    input                   udp_data_valid,
    input      [7:0]        udp_data,

    output reg              write_req,
    input                   write_req_ack,
    output reg              write_en,
    output reg [31:0]       write_data
);

    localparam S_IDLE      = 2'd0;
    localparam S_WAIT_ACK  = 2'd1;
    localparam S_STREAM    = 2'd2;

    // Small pixel FIFO prevents byte loss while the SDRAM path accepts a new frame
    localparam FIFO_DEPTH     = 256;
    localparam FIFO_ADDR_BITS = 8;

    reg [1:0] state;
    reg       write_ready;

    reg [1:0] udp_data_valid_sync;
    reg [7:0] udp_data_sync_1;
    reg [7:0] udp_data_sync_2;

    reg [1:0]  assemble_cnt;
    reg [23:0] assemble_data;

    reg [23:0] pixel_fifo [0:FIFO_DEPTH-1];
    reg [FIFO_ADDR_BITS-1:0] fifo_wr_ptr;
    reg [FIFO_ADDR_BITS-1:0] fifo_rd_ptr;
    reg [FIFO_ADDR_BITS:0]   fifo_count;

    reg [18:0] pixel_cnt;

    wire udp_data_valid_stable = udp_data_valid_sync[1];
    wire [7:0] udp_data_stable = udp_data_sync_2;

    wire fifo_empty = (fifo_count == 0);
    wire fifo_full  = (fifo_count == FIFO_DEPTH);

    wire start_frame = (state == S_IDLE) && udp_data_valid_stable;
    wire pop_pixel   = write_ready && !fifo_empty;

    wire push_pixel_raw = udp_data_valid_stable &&
                          (assemble_cnt == 2'd2) &&
                          (pixel_cnt < PIXEL_COUNT);
    wire push_pixel = push_pixel_raw && (!fifo_full || pop_pixel);

    wire frame_pixels_done = (pixel_cnt == PIXEL_COUNT);

    // Synchronise UDP payload into the local clock domain
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            udp_data_valid_sync <= 2'b00;
            udp_data_sync_1     <= 8'h00;
            udp_data_sync_2     <= 8'h00;
        end else begin
            udp_data_valid_sync <= {udp_data_valid_sync[0], udp_data_valid};
            udp_data_sync_1     <= udp_data;
            udp_data_sync_2     <= udp_data_sync_1;
        end
    end

    // Frame control and buffering logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state        <= S_IDLE;
            write_req    <= 1'b0;
            write_en     <= 1'b0;
            write_data   <= 32'h00000000;
            write_ready  <= 1'b0;

            assemble_cnt  <= 2'd0;
            assemble_data <= 24'h000000;

            fifo_wr_ptr <= {FIFO_ADDR_BITS{1'b0}};
            fifo_rd_ptr <= {FIFO_ADDR_BITS{1'b0}};
            fifo_count  <= {(FIFO_ADDR_BITS+1){1'b0}};

            pixel_cnt <= 19'd0;
        end else begin
            write_en <= 1'b0;

            case (state)
                S_IDLE: begin
                    write_ready <= 1'b0;
                    if (start_frame) begin
                        state       <= S_WAIT_ACK;
                        write_req   <= 1'b1;

                        assemble_cnt  <= 2'd0;
                        assemble_data <= 24'h000000;

                        fifo_wr_ptr <= {FIFO_ADDR_BITS{1'b0}};
                        fifo_rd_ptr <= {FIFO_ADDR_BITS{1'b0}};
                        fifo_count  <= {(FIFO_ADDR_BITS+1){1'b0}};

                        pixel_cnt <= 19'd0;
                    end else begin
                        write_req <= 1'b0;
                    end
                end

                S_WAIT_ACK: begin
                    if (write_req_ack) begin
                        write_req   <= 1'b0;
                        write_ready <= 1'b1;
                        state       <= S_STREAM;
                    end
                end

                S_STREAM: begin
                    if (frame_pixels_done && fifo_empty && !udp_data_valid_stable && !push_pixel_raw) begin
                        state        <= S_IDLE;
                        write_ready  <= 1'b0;
                        assemble_cnt <= 2'd0;
                    end
                end
            endcase

            if (udp_data_valid_stable) begin
                case (assemble_cnt)
                    2'd0: begin
                        assemble_data[23:16] <= udp_data_stable;
                        assemble_cnt         <= 2'd1;
                    end
                    2'd1: begin
                        assemble_data[15:8] <= udp_data_stable;
                        assemble_cnt        <= 2'd2;
                    end
                    2'd2: begin
                        assemble_data[7:0] <= udp_data_stable;
                        assemble_cnt       <= 2'd0;
                    end
                    default: assemble_cnt <= 2'd0;
                endcase
            end

            if (!start_frame) begin
                if (push_pixel) begin
                    pixel_fifo[fifo_wr_ptr] <= {assemble_data[23:8], udp_data_stable};
                    fifo_wr_ptr             <= fifo_wr_ptr + 1'b1;
                end
                if (pop_pixel) begin
                    write_data <= {8'h00, pixel_fifo[fifo_rd_ptr]};
                    write_en   <= 1'b1;
                    fifo_rd_ptr <= fifo_rd_ptr + 1'b1;
                end

                case ({push_pixel, pop_pixel})
                    2'b10: fifo_count <= fifo_count + 1'b1;
                    2'b01: fifo_count <= fifo_count - 1'b1;
                    default: fifo_count <= fifo_count;
                endcase
            end

            if (start_frame) begin
                pixel_cnt <= 19'd0;
            end else if (push_pixel && (pixel_cnt < PIXEL_COUNT)) begin
                pixel_cnt <= pixel_cnt + 1'b1;
            end
        end
    end
endmodule

//********************************************************************************
// Module : app
// Function: 瑙嗛瀛愮郴缁熼《灞傘€傚唴閮ㄥ皝瑁呬簡浠庝緥绋?绉绘鐨凷DRAM鎺у埗鍣ㄥ拰HDMI鏄剧ず閫昏緫銆?
//           杩欐槸鎮ㄩ」鐩腑鐨勬柊 app 妯″潡銆?
//********************************************************************************
module app
(
    // ----- 绯荤粺杈撳叆 -----
    input                   udp_clk,       // 鐢ㄤ簬鎺ユ敹UDP鏁版嵁鐨勬椂閽?
    input                   mem_clk,       // 鐢ㄤ簬SDRAM鎺у埗鍣ㄧ殑鏃堕挓 (渚嬪 125MHz)
    input                   mem_clk_sft,   // SDRAM IP鎵€闇€鐨勭浉绉绘椂閽?
    input                   video_clk,     // HDMI鍍忕礌鏃堕挓 (渚嬪 25.175MHz)
    input                   video_clk_5x,  // 5鍊嶅儚绱犳椂閽?
    input                   reset,         // 楂樼數骞虫湁鏁堝浣?

    // ----- UDP鏁版嵁杈撳叆鎺ュ彛 -----
    input                   app_rx_data_valid,
    input      [7:0]        app_rx_data,

    // ----- 涓庨《灞係DRAM IP鐨勬帴鍙?-----
    input                   Sdr_init_done,
    output                  App_wr_en,
    output     [20:0]       App_wr_addr,
    output     [31:0]       App_wr_din,
    output     [3:0]        App_wr_dm,
    output                  App_rd_en,
    output     [20:0]       App_rd_addr,
    input                   Sdr_rd_en,
    input      [31:0]       Sdr_rd_dout,

    // ----- HDMI鐗╃悊杈撳嚭鎺ュ彛 -----
    output                  HDMI_CLK_P,
    output                  HDMI_D2_P,
    output                  HDMI_D1_P,
    output                  HDMI_D0_P
);

    // --- 杩炴帴鍐呴儴妯″潡鐨勭嚎缃?---
    wire                    write_req;
    wire                    write_req_ack;
    wire                    write_en;
    wire       [31:0]       write_data;
    wire                    video_read_req;
    wire                    video_read_req_ack;
    wire                    video_read_en;
    wire       [31:0]       video_read_data;
    wire                    hs_0, vs_0, de_0;
    wire                    hs, vs, de;
    wire       [23:0]       vout_data;

    // 1. 鏂板妯″潡锛歎DP鏁版嵁鍐欏叆SDRAM鐨勬帶鍒跺櫒
    udp_to_sdram_writer u_udp_writer (
        .clk            (udp_clk),
        .reset          (reset),
        .udp_data_valid (app_rx_data_valid),
        .udp_data       (app_rx_data),
        .write_req      (write_req),
        .write_req_ack  (write_req_ack),
        .write_en       (write_en),
        .write_data     (write_data)
    );

    // 2. 渚嬬▼6鏍稿績妯″潡锛歋DRAM璇诲啓浠茶鍣?(frame_read_write)
    frame_read_write #(
        .ADDR_BITS(21),
        .READ_DATA_BITS(32),
        .WRITE_DATA_BITS(32)
    )
    frame_read_write_m0(
        .mem_clk					(mem_clk),
        .rst						(reset),
        .Sdr_init_done				(Sdr_init_done),
        .Sdr_init_ref_vld			(1'b0),
        .Sdr_busy					(1'b0),
        
        .App_rd_en					(App_rd_en),
        .App_rd_addr				(App_rd_addr),
        .Sdr_rd_en					(Sdr_rd_en),
        .Sdr_rd_dout				(Sdr_rd_dout),
        
        .read_clk                   (video_clk),
        .read_req                   (video_read_req),
        .read_req_ack               (video_read_req_ack),
        .read_finish                (),
        .read_addr_0                (21'd0),
        .read_addr_index            (2'd0),
        .read_len                   (21'd307200), // 640 * 480
        .read_en                    (video_read_en),
        .read_data                  (video_read_data),
        
        .App_wr_en					(App_wr_en),
        .App_wr_addr				(App_wr_addr),
        .App_wr_din					(App_wr_din),
        .App_wr_dm					(App_wr_dm),
        
        .write_clk                  (udp_clk),
        .write_req                  (write_req),
        .write_req_ack              (write_req_ack),
        .write_finish               (),
        .write_addr_0               (21'd0),
        .write_addr_index           (2'd0),
        .write_len                  (21'd307200), // 640 * 480
        .write_en                   (write_en),
        .write_data                 (write_data)
    );

    // 3. 渚嬬▼6鏍稿績妯″潡锛氳棰戞椂搴忓彂鐢熷櫒 (video_timing_data)
    video_timing_data video_timing_data_m0 (
        .video_clk                  (video_clk),
        .rst                        (reset),
        .read_req                   (video_read_req),
        .read_req_ack               (video_read_req_ack),
        .hs                         (hs_0),
        .vs                         (vs_0),
        .de                         (de_0)
    );

    // 4. 渚嬬▼6鏍稿績妯″潡锛氳棰戞暟鎹欢杩熷榻?(video_delay)
    video_delay video_delay_m0 (
        .video_clk                  (video_clk),
        .rst                        (reset),
        .read_en					(video_read_en),
        .read_data					(video_read_data[23:0]),
        .hs                         (hs_0),
        .vs                         (vs_0),
        .de                         (de_0),
        .hs_r                       (hs),
        .vs_r                       (vs),
        .de_r                       (de),
        .vout_data					(vout_data)
    );

    // 5. 渚嬬▼6鏍稿績妯″潡锛欻DMI鐗╃悊灞傚彂閫佸櫒 (hdmi_tx)
    hdmi_tx #(.FAMILY("EG4"))
    u_hdmi_tx (
		.PXLCLK_I                   (video_clk),
		.PXLCLK_5X_I                (video_clk_5x),
		.RST_N                      (~reset),
		.VGA_HS                     (hs),
		.VGA_VS                     (vs),
		.VGA_DE                     (de),
		.VGA_RGB                    (vout_data),
		.HDMI_CLK_P                 (HDMI_CLK_P),
		.HDMI_D2_P                  (HDMI_D2_P),
		.HDMI_D1_P                  (HDMI_D1_P),
		.HDMI_D0_P                  (HDMI_D0_P)
	);

endmodule

