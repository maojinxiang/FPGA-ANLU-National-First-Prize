  module udp_cam_ctrl_tf(
      input               clk,
      input               rst_n,

      // ===== SDRAM read side =====
      output reg          read_req,
      input               read_req_ack,
      output reg          read_en,
      input      [31:0]   read_data,

      // ===== UDP stack interface =====
      input               udp_tx_ready,
      input               app_tx_ack,
      output reg          app_tx_data_request,
      output reg          app_tx_data_valid,
      output reg  [7:0]   app_tx_data,
      output reg [15:0]   udp_data_length
  );

  // -----------------------------------------------------------------------------
  // Constant configuration (match camera path RGB888 formatting)
  // -----------------------------------------------------------------------------
  localparam IMG_HEADER       = 32'hAA00_55FF;
  localparam IMG_WIDTH        = 32'd640;
  localparam IMG_HEIGHT       = 32'd480;
  localparam IMG_TOTAL        = IMG_WIDTH * IMG_HEIGHT * 3;   // RGB888
  localparam IMG_FRAMSIZE     = 32'd636;                      // packet payload (except last)
  localparam IMG_FRAMTOTAL    = 32'd1450;                     // ceil(921600 / 636)
  localparam LAST_FRAMSIZE    = 32'd36;                       // final packet payload
  localparam IMG_HEADER_LEN   = 9'd256;                       // 32 bytes header
  localparam HEADER_BYTES     = 16'd32;

  // ============================================================================
  // State machine encoding
  // ============================================================================
  localparam START_UDP       = 3'd0;
  localparam WAIT_FIFO_RDY   = 3'd1;
  localparam WAIT_UDP_DATA   = 3'd2;
  localparam WAIT_ACK        = 3'd3;
  localparam SEND_UDP_HEADER = 3'd4;
  localparam SEND_UDP_DATA   = 3'd5;
  localparam DELAY           = 3'd6;

  reg [2:0] state;

  // ============================================================================
  // Registers
  // ============================================================================
  reg [31:0] img_framseq;       // packet sequence inside one frame
  reg [31:0] img_picseq;        // frame counter
  reg [31:0] img_offset;        // byte offset of current packet
  reg  [8:0] header_cnt;        // header byte pointer (multiples of 8 bits)
  reg [15:0] data_cnt;          // payload byte counter (0..639/35)
  reg [21:0] delay_cnt;         // idle cycles between packets
  reg [31:0] data_reg;          // SDRAM data latch
  reg  [1:0] byte_sel;          // selects byte within data_reg
  reg        start_read;        // schedules next SDRAM read

  wire [31:0] curr_payload_bytes =
      (img_framseq == IMG_FRAMTOTAL - 1) ? LAST_FRAMSIZE : IMG_FRAMSIZE;
  wire [15:0] payload_limit      = curr_payload_bytes[15:0];
  wire        last_payload_byte  = (data_cnt + 16'd1 >= payload_limit);

  wire [255:0] udp_header = {
      curr_payload_bytes,
      img_framseq,
      img_picseq,
      img_offset,
      IMG_TOTAL,
      IMG_HEIGHT,
      IMG_WIDTH,
      IMG_HEADER
  };

  // ============================================================================
  // Main FSM
  // ============================================================================
  always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
          state               <= START_UDP;
          app_tx_data_request <= 1'b0;
          app_tx_data_valid   <= 1'b0;
          app_tx_data         <= 8'd0;
          udp_data_length     <= HEADER_BYTES + IMG_FRAMSIZE[15:0];
          img_framseq         <= 32'd0;
          img_picseq          <= 32'd0;
          img_offset          <= 32'd0;
          header_cnt          <= 9'd0;
          data_cnt            <= 16'd0;
          delay_cnt           <= 22'd0;
          read_req            <= 1'b0;
          read_en             <= 1'b0;
          data_reg            <= 32'd0;
          byte_sel            <= 2'd0;
          start_read          <= 1'b0;
      end else begin
          case(state)
              START_UDP: begin
                  app_tx_data_request <= 1'b0;
                  app_tx_data_valid   <= 1'b0;
                  data_cnt            <= 16'd0;
                  img_framseq         <= 32'd0;
                  img_offset          <= 32'd0;
                  read_req            <= 1'b0;
                  read_en             <= 1'b0;
                  img_picseq          <= img_picseq + 1'd1;
                  delay_cnt           <= 22'd0;
                  start_read          <= 1'b0;
                  state               <= WAIT_FIFO_RDY;
              end

              WAIT_FIFO_RDY: begin
                  if(delay_cnt >= 22'd2000) begin
                      delay_cnt <= 22'd0;
                      state     <= WAIT_UDP_DATA;
                  end else begin
                      delay_cnt <= delay_cnt + 1'd1;
                  end

                  if(delay_cnt == 22'd10)
                      read_req <= 1'b1;
                  else if(read_req_ack)
                      read_req <= 1'b0;

                  start_read <= 1'b0;
              end

              WAIT_UDP_DATA: begin
                  app_tx_data_request <= 1'b1;
                  app_tx_data_valid   <= 1'b0;
                  read_en             <= 1'b0;
                  start_read          <= 1'b0;

                  if(udp_tx_ready)
                      state <= WAIT_ACK;
              end

              WAIT_ACK: begin
                  app_tx_data_request <= app_tx_ack ? 1'b0 : 1'b1;
                  app_tx_data_valid   <= 1'b0;
                  read_en             <= 1'b0;
                  start_read          <= 1'b0;

                  if(app_tx_ack) begin
                      header_cnt        <= 9'd8;
                      data_cnt          <= 16'd0;
                      byte_sel          <= 2'd0;
                      app_tx_data_valid <= 1'b1;
                      app_tx_data       <= udp_header[7:0];
                      udp_data_length   <= HEADER_BYTES + payload_limit;
                      state             <= SEND_UDP_HEADER;
                  end
              end

              SEND_UDP_HEADER: begin
                  app_tx_data_valid <= 1'b1;
                  app_tx_data       <= udp_header[header_cnt +: 8];
                  start_read        <= 1'b0;

                  if(header_cnt == IMG_HEADER_LEN - 9'd8) begin
                      header_cnt <= 9'd0;
                      start_read <= 1'b1;
                      state      <= SEND_UDP_DATA;
                  end else begin
                      header_cnt <= header_cnt + 9'd8;
                  end
              end

              SEND_UDP_DATA: begin
                  read_en <= start_read;
                  if(read_en)
                      data_reg <= read_data;

                  case(byte_sel) 
                      2'd0: app_tx_data <= data_reg[15:8];//B
                      2'd1: app_tx_data <= data_reg[23:16];//G
                      default: app_tx_data <= data_reg[31:24];//R
                  endcase

                  app_tx_data_valid <= 1'b1;

                  if(byte_sel == 2'd2) begin
                      byte_sel   <= 2'd0;
                      start_read <= (data_cnt + 16'd1 < payload_limit);
                  end else begin
                      byte_sel   <= byte_sel + 2'd1;
                      start_read <= 1'b0;
                  end

                  if(last_payload_byte) begin
                      read_en           <= 1'b0;
                      app_tx_data_valid <= 1'b0;
                      data_cnt          <= 16'd0;
                      state             <= DELAY;
                  end else begin
                      data_cnt <= data_cnt + 16'd1;
                  end
              end

              DELAY: begin
                  if(delay_cnt >= 22'd800) begin
                      delay_cnt   <= 22'd0;
                      img_framseq <= img_framseq + 1'd1;
                      img_offset  <= img_offset + curr_payload_bytes;

                      if(img_framseq >= (IMG_FRAMTOTAL - 1))
                          state <= START_UDP;
                      else
                          state <= WAIT_UDP_DATA;
                  end else begin
                      delay_cnt <= delay_cnt + 1'd1;
                  end

                  start_read <= 1'b0;
              end

              default: state <= START_UDP;
          endcase
      end
  end

  endmodule