// ===========================================================================
// Copyright (c) 2011-2020 Anlogic Inc. All Right Reserved.
//
// TEL: 86-21-61633787
// WEB: http://www.anlogic.com/
// ===========================================================================
//
//
//  
//
//
// ===========================================================================

module rx_client_fifo#(
    parameter DEVICE           = "PH1"//"PH1","EG4"
)
  (
    // Local-link Interface
    input            rd_clk,
    input            rd_sreset,
    output reg [7:0] rd_data_out,
    output reg       rd_sof_n,
    output           rd_eof_n,
    output reg       rd_src_rdy_n,
    input            rd_dst_rdy_n,
    output [3:0]     rx_fifo_status,

    // Client Interface
    input            wr_clk,
    input            wr_sreset,
    input            wr_enable,
    input [7:0]      rx_data,
    input            rx_data_valid,
    input            rx_good_frame,
    input            rx_bad_frame,
    output           overflow
  );


  //----------------------------------------------------------------------------
  // Define Internal Signals
  //----------------------------------------------------------------------------

  wire        GND;
  wire        VCC;
  wire [7:0]  GND_BUS;

  // Encode rd_state_machine states
  parameter WAIT_s      = 3'b000;
  parameter QUEUE1_s    = 3'b001;
  parameter QUEUE2_s    = 3'b010;
  parameter QUEUE3_s    = 3'b011;
  parameter QUEUE_SOF_s = 3'b100;
  parameter SOF_s       = 3'b101;
  parameter DATA_s      = 3'b110;
  parameter EOF_s       = 3'b111;

  reg [2:0]   rd_state;
  reg [2:0]   rd_nxt_state;

  // Encode wr_state_machine states
  parameter IDLE_s   = 3'b000;
  parameter FRAME_s  = 3'b001;
  parameter END_s    = 3'b010;
  parameter GF_s     = 3'b011;
  parameter BF_s     = 3'b100;
  parameter OVFLOW_s = 3'b101;

  reg  [2:0]  wr_state;
  reg  [2:0]  wr_nxt_state;


  wire        wr_en;
  wire        wr_en_u;
  wire        wr_en_l;
  reg  [11:0] wr_addr;
  wire        wr_addr_inc;
  wire        wr_start_addr_load;
  wire        wr_addr_reload;
  reg  [11:0] wr_start_addr;
  reg  [7:0]  wr_data_bram;
  reg  [7:0]  wr_data_pipe[0:1];
  reg  [0:0]  wr_eof_bram;
  reg         wr_dv_pipe[0:1];
  reg         wr_gf_pipe[0:1];
  reg         wr_bf_pipe[0:1];
  reg         frame_in_fifo;

  reg  [11:0] rd_addr;
  wire        rd_addr_inc;
  reg         rd_addr_reload;
  wire [7:0]  rd_data_bram_u;
  wire [7:0]  rd_data_bram_l;
  reg  [7:0]  rd_data_pipe_u;
  reg  [7:0]  rd_data_pipe_l;
  reg  [7:0]  rd_data_pipe;
  wire [0:0]  rd_eof_bram_u;
  wire [0:0]  rd_eof_bram_l;
  reg         rd_en;
  reg         rd_bram_u;
  reg         rd_bram_u_reg;
  reg         rd_pull_frame;
  reg         rd_eof;


  reg         wr_store_frame_tog = 1'b0;

  wire        rd_store_frame_sync;

  reg         rd_store_frame_delay = 1'b0;
  reg         rd_store_frame= 1'b0;
  reg  [8:0]  rd_frames;
  reg         wr_fifo_full;

  reg  [1:0]  old_rd_addr;
  reg         update_addr_tog= 1'b0;
  wire        update_addr_tog_sync;
  reg         update_addr_tog_sync_reg= 1'b0;
  
  reg  [11:0] wr_rd_addr;
  wire [12:0] wr_addr_diff_in;
  reg  [11:0] wr_addr_diff;

  reg  [3:0]  wr_fifo_status;

  reg         rd_eof_n_int= 1'b0;

  reg  [1:0]  rd_valid_pipe;


  //----------------------------------------------------------------------------
  // Begin FIFO architecture
  //----------------------------------------------------------------------------

  assign GND     = 1'b0;
  assign VCC     = 1'b1;
  assign GND_BUS = 8'b0;


  //----------------------------------------------------------------------------
  // Read State machines and control
  //----------------------------------------------------------------------------

  // local link state machine
  // states are WAIT, QUEUE1, QUEUE2, QUEUE3, SOF, DATA, EOF
  // clock state to next state
  always @(posedge rd_clk)
  begin
     if (rd_sreset == 1'b1) begin
        rd_state <= WAIT_s;
     end
     else begin
        rd_state <= rd_nxt_state;
     end
  end

  assign rd_eof_n = rd_eof_n_int;

  // decode next state, combinatorial
  always @(rd_state or frame_in_fifo or rd_eof or rd_dst_rdy_n or
           rd_eof_n_int or rd_valid_pipe)
  begin
     case (rd_state)
        WAIT_s : begin
           // wait till there is a full frame in the fifo
           // then start to load the pipeline
           if (frame_in_fifo == 1'b1 && rd_eof_n_int == 1'b1) begin
              rd_nxt_state <= QUEUE1_s;
           end
           else begin
              rd_nxt_state <= WAIT_s;
           end
        end

        QUEUE1_s : begin
           // load the output pipeline
           // this takes three clocks
           rd_nxt_state <= QUEUE2_s;
        end

        QUEUE2_s : begin
           rd_nxt_state <= QUEUE3_s;
        end

        QUEUE3_s : begin
           rd_nxt_state <= QUEUE_SOF_s;
        end

        QUEUE_SOF_s : begin
           // used mark sof at end of queue
           rd_nxt_state <= DATA_s;  // move straight to frame.
        end

        SOF_s : begin
           // used to mark sof when following straight from eof
           if (rd_dst_rdy_n == 1'b0) begin
              rd_nxt_state <= DATA_s;
           end
           else begin
              rd_nxt_state <= SOF_s;
           end
        end

        DATA_s : begin
           // When the eof marker is detected from the BRAM output
           // move to EOF state
           if (rd_dst_rdy_n == 1'b0 && rd_eof == 1'b1) begin
              rd_nxt_state <= EOF_s;
           end
           else begin
              rd_nxt_state <= DATA_s;
           end
        end

        EOF_s : begin
           // hold in this state until dst rdy is low
           // and eof bit is accepted on interface
           // If there is a frame in the fifo, then the next frame
           // will already be queued into the pipe line so move straight
           // to sof state.
           if (rd_dst_rdy_n == 1'b0) begin
              if (rd_valid_pipe[1] == 1'b1) begin
                 rd_nxt_state <= SOF_s;
              end
              else begin
                 rd_nxt_state <= WAIT_s;
              end
           end
           else begin
              rd_nxt_state <= EOF_s;
           end
         end

         default : begin
           rd_nxt_state <= WAIT_s;
         end

     endcase
  end

  // detect if frame in fifo was high 3 reads ago
  // this is used to ensure we only treat data in the pipeline as valid if
  // frame in fifo goes high at or before the eof of the current frame
  // It may be that there is valid data (i.e a partial packet has been written)
  // but until the end of that packet we do not know if it is a good packet
  always @(posedge rd_clk)
  begin
     if (rd_dst_rdy_n == 1'b0) begin
        rd_valid_pipe <= {rd_valid_pipe[0], frame_in_fifo};
     end
  end

  // decode the output signals depending on current state.
  // decode sof signal.
  always @(posedge rd_clk)
  begin
     if (rd_sreset == 1'b1) begin
        rd_sof_n <= 1'b1;
     end
     else begin
        case (rd_state)
           QUEUE_SOF_s :
              // no need to wait for dst rdy to be low, as there is valid data
              rd_sof_n <= 1'b0;
           SOF_s :
              // needed to wait till rd_dst_rdy is low to ensure eof signal has
              // been accepted onto the interface before asserting sof.
              if (rd_dst_rdy_n == 1'b0) begin
                 rd_sof_n <= 1'b0;
              end
           default :
              // needed to wait till rd_dst_rdy is low to ensure sof signal has
              // been accepted onto the interface.
              if (rd_dst_rdy_n == 1'b0) begin
                 rd_sof_n <= 1'b1;
              end
        endcase
     end
  end

  // decode eof signal
  // check init value of this reg is 1.
  always @(posedge rd_clk)
  begin
     if (rd_sreset == 1'b1) begin
        rd_eof_n_int <= 1'b1;
     end
     else if (rd_dst_rdy_n == 1'b0) begin
        // needed to wait till rd_dst_rdy is low to ensure penultimate byte of
        // frame has been accepted onto the interface before asserting eof and
        // that eof is accepted before moving on
        case (rd_state)
           EOF_s :
              rd_eof_n_int <= 1'b0;
           default :
              rd_eof_n_int <= 1'b1;
        endcase
        // queue sof is not needed if init value is 1
     end
  end

  // decode data output
  always @(posedge rd_clk)
  begin
     if (rd_en == 1'b1) begin
        rd_data_out <= rd_data_pipe;
     end
  end

  // decode the output scr_rdy signal
  // want to remove the dependancy of src_rdy from dst rdy
  // check init value of this reg is 1'b1
  always @(posedge rd_clk)
  begin
     if (rd_sreset == 1'b1) begin
        rd_src_rdy_n <= 1'b1;
     end
     else begin
        case (rd_state)
           QUEUE_SOF_s :
              rd_src_rdy_n <= 1'b0;
           SOF_s :
              rd_src_rdy_n <= 1'b0;
           DATA_s :
              rd_src_rdy_n <= 1'b0;
           EOF_s :
              rd_src_rdy_n <= 1'b0;
           default :
              if (rd_dst_rdy_n == 1'b0) begin
                 rd_src_rdy_n <= 1'b1;
              end
         endcase
     end
  end


  // decode internal control signals
  // rd_en is used to enable the BRAM read and load the output pipe
  always @(rd_state or rd_dst_rdy_n)
  begin
     case (rd_state)
         WAIT_s :
              rd_en <= 1'b0;
         QUEUE1_s :
              rd_en <= 1'b1;
         QUEUE2_s :
              rd_en <= 1'b1;
         QUEUE3_s :
              rd_en <= 1'b1;
         QUEUE_SOF_s :
              rd_en <= 1'b1;
         default :
              rd_en <= !rd_dst_rdy_n;
     endcase
  end

  // rd_addr_inc is used to enable the BRAM read address to increment
  assign rd_addr_inc = rd_en;


  // When the current frame is output, if there is no frame in the fifo, then
  // the fifo must wait until a new frame is written in.  This requires the read
  // address to be moved back to where the new frame will be written.  The pipe
  // is then reloaded using the QUEUE states
  always @(posedge rd_clk)
  begin
     if (rd_sreset == 1'b1)
        rd_addr_reload <= 1'b0;
     else
        if (rd_state == EOF_s && rd_nxt_state == WAIT_s)
           rd_addr_reload <= 1'b1;
        else
           rd_addr_reload <= 1'b0;
  end

  // Data is available if there is at leat one frame stored in the FIFO.
  always @(posedge rd_clk)
  begin
     if (rd_sreset == 1'b1) begin
        frame_in_fifo <= 1'b0;
     end
     else begin
        if (rd_frames != 9'b0) begin
           frame_in_fifo <= 1'b1;
        end
        else begin
           frame_in_fifo <= 1'b0;
        end
     end
  end

  // when a frame has been stored need to convert to rd clock domain for frame
  // count store.
  // sync_block resync_wr_store_frame_tog
  // (
    // .clk       (rd_clk),
    // .data_in   (wr_store_frame_tog),
    // .data_out  (rd_store_frame_sync)
  // );
  
reg [1:0]wr_store_frame_tog_reg;
always@(posedge rd_clk)
begin
	wr_store_frame_tog_reg <= {wr_store_frame_tog_reg[0],wr_store_frame_tog};
end
assign rd_store_frame_sync = wr_store_frame_tog_reg[1];

  always @(posedge rd_clk)
  begin
     rd_store_frame_delay <= rd_store_frame_sync;
  end

  // edge detect of the resynchronized frame count
  always @(posedge rd_clk)
  begin
     if (rd_sreset == 1'b1) begin
        rd_store_frame       <= 1'b0;
     end
     else begin
        // edge detector
        if ((rd_store_frame_delay ^ rd_store_frame_sync) == 1'b1) begin
           rd_store_frame    <= 1'b1;
        end
        else begin
           rd_store_frame    <= 1'b0;
        end
     end
  end

  always @(posedge rd_clk)
  begin
     if (rd_sreset == 1'b1) begin
        rd_pull_frame <= 1'b0;
     end
     else begin
        if (rd_state == SOF_s && rd_nxt_state != SOF_s) begin
           rd_pull_frame <= 1'b1;
        end
        else if (rd_state == QUEUE_SOF_s && rd_nxt_state != QUEUE_SOF_s) begin
           rd_pull_frame <= 1'b1;
        end
        else begin
           rd_pull_frame <= 1'b0;
        end
     end
  end


  // Up/Down counter to monitor the number of frames stored within the
  // the FIFO. Note:
  //    * decrements at the beginning of a frame read cycle
  //    * increments at the end of a frame write cycle
  always @(posedge rd_clk)
  begin
     if (rd_sreset == 1'b1) begin
        rd_frames <= 9'b0;
     end
     else begin
        // A frame is written to the fifo in this cycle, and no frame is being
        // read out on the same cycle
        if (rd_store_frame == 1'b1 && rd_pull_frame == 1'b0) begin
           rd_frames <= rd_frames + 1;
        end
        // A frame is being read out on this cycle and no frame is being
        // written on the same cycle
        else if (rd_store_frame == 1'b0 && rd_pull_frame == 1'b1) begin
           rd_frames <= rd_frames - 1;
        end
     end
  end


  //----------------------------------------------------------------------------
  // Write State machines and control
  //----------------------------------------------------------------------------

  // write state machine
  // states are IDLE, FRAME, EOF, GF, BF, OVFLOW
  // clock state to next state
  always @(posedge wr_clk)
  begin
     if (wr_sreset == 1'b1) begin
        wr_state <= IDLE_s;
     end
     else if (wr_enable == 1'b1) begin
        wr_state <= wr_nxt_state;
     end
  end

  // decode next state, combinatorial
  always @(wr_state or wr_dv_pipe[1] or wr_gf_pipe[1] or wr_bf_pipe[1]
          or wr_eof_bram[0] or wr_fifo_full)
  begin
     case (wr_state)
        IDLE_s : begin
           // there is data in the incoming pipeline when dv_pipe(1) goes high
           if (wr_dv_pipe[1] == 1'b1) begin
              wr_nxt_state <= FRAME_s;
           end
           else begin
              wr_nxt_state <= IDLE_s;
           end
        end

        FRAME_s : begin
              // if fifo is full then go to overflow state.
              // if the good or bad flag is detected the end
              // of the frame has been reached!
              // this transistion occurs when the gb flag
              // is on the clock edge immediately following
              // the end of the frame.
              // if the eof_bram signal is detected then data valid has
              // fallen low and the end of frame has been detected.
              if (wr_fifo_full == 1'b1) begin
                 wr_nxt_state <= OVFLOW_s;
              end
              else if (wr_gf_pipe[1] == 1'b1) begin
                 wr_nxt_state <= GF_s;
              end
              else if (wr_bf_pipe[1] == 1'b1) begin
                 wr_nxt_state <= BF_s;
              end
              else if (wr_eof_bram[0] == 1'b1) begin
                 wr_nxt_state <= END_s;
              end
              else begin
                 wr_nxt_state <= FRAME_s;
              end
           end

           END_s : begin
              // if frame is full then go to overflow state
              // else wait until the good or bad flag has been received.
              if (wr_gf_pipe[1] == 1'b1) begin
                 wr_nxt_state <= GF_s;
              end
              else if (wr_bf_pipe[1] == 1'b1) begin
                 wr_nxt_state <= BF_s;
              end
              else begin
                 wr_nxt_state <= END_s;
              end
           end

           GF_s : begin
              // wait for next frame
              wr_nxt_state <= IDLE_s;
           end

           BF_s : begin
              // wait for next frame
              wr_nxt_state <= IDLE_s;
           end

           OVFLOW_s : begin
              // wait until the good or bad flag received.
              if (wr_gf_pipe[1] == 1'b1 || wr_bf_pipe[1] == 1'b1) begin
                 wr_nxt_state <= IDLE_s;
              end
              else begin
                 wr_nxt_state <= OVFLOW_s;
              end
           end

           default : begin
              wr_nxt_state <= IDLE_s;
           end

        endcase
  end


  // decode control signals
  // wr_en is used to enable the BRAM write and loading of the input pipeline
  assign wr_en = (wr_state == FRAME_s) ? 1'b1 : 1'b0;

  // the upper and lower signals are used to distinguish between the upper and
  // lower BRAM
  assign wr_en_l = wr_en & !wr_addr[11];
  assign wr_en_u = wr_en & wr_addr[11];

  // increment the write address when we are receiving a frame
  assign wr_addr_inc = (wr_state == FRAME_s) ? 1'b1 : 1'b0;

  // if the fifo overflows or a frame is to be dropped, we need to move the
  // write address back to the start of the frame.  This allows the data to be
  // overwritten.
  assign wr_addr_reload = (wr_state == BF_s || wr_state == OVFLOW_s)
                          ? 1'b1 : 1'b0;

  // the start address is saved when in the WAIT state
  assign wr_start_addr_load = (wr_state == IDLE_s) ? 1'b1 : 1'b0;

  // we need to know when a frame is stored, in order to increment the count of
  // frames stored in the fifo.
  always @(posedge wr_clk)
  begin  // process
     if (wr_enable == 1'b1) begin
        if (wr_state == GF_s) begin
           wr_store_frame_tog <= ! wr_store_frame_tog;
        end
     end
  end


  //----------------------------------------------------------------------------
  // Address counters
  //----------------------------------------------------------------------------

  // write address is incremented when write enable signal has been asserted
  always @(posedge wr_clk)
  begin
     if (wr_sreset == 1'b1) begin
        wr_addr <= 12'b0;
     end
     else if (wr_enable == 1'b1) begin
        if (wr_addr_reload == 1'b1) begin
           wr_addr <= wr_start_addr;
        end
        else if (wr_addr_inc == 1'b1) begin
           wr_addr <= wr_addr + 1;
        end
     end
  end

  // store the start address
  always @(posedge wr_clk)
  begin
     if (wr_sreset == 1'b1) begin
        wr_start_addr <= 12'b0;
     end
     else if (wr_enable == 1'b1) begin
        if (wr_start_addr_load == 1'b1) begin
           wr_start_addr <= wr_addr;
        end
     end
  end

  // read address is incremented when read enable signal has been asserted
  always @(posedge rd_clk)
  begin
     if (rd_sreset == 1'b1) begin
        rd_addr <= 12'b0;
     end
     else begin
        if (rd_addr_reload == 1'b1) begin
           rd_addr <= rd_addr - 3;
        end
        else if (rd_addr_inc == 1'b1) begin
           rd_addr <= rd_addr + 1;
        end
     end
  end

  // which BRAM is read from is dependant on the upper bit of the address
  // space.  this needs to be registered to give the correct timing.
  always @(posedge rd_clk)
  begin
     if (rd_sreset == 1'b1) begin
        rd_bram_u <= 1'b0;
        rd_bram_u_reg <= 1'b0;
     end
     else if (rd_addr_inc == 1'b1) begin
        rd_bram_u <= rd_addr[11];
        rd_bram_u_reg <= rd_bram_u;
     end
  end


  //----------------------------------------------------------------------------
  // Data Pipelines
  //----------------------------------------------------------------------------

  // register data inputs to bram
  // no reset to allow srl16 target
  always @(posedge wr_clk)
  begin
     if (wr_enable == 1'b1) begin
        wr_data_pipe[0] <= rx_data;
        wr_data_pipe[1] <= wr_data_pipe[0];
        wr_data_bram    <= wr_data_pipe[1];
     end
  end

  // no reset to allow srl16 target
  always @(posedge wr_clk)
  begin
     if (wr_sreset == 1'b1) begin
        wr_dv_pipe[0] <= 0;
        wr_dv_pipe[1] <= 0;
        wr_eof_bram   <= 0;
     end
     else if (wr_enable == 1'b1) begin
        wr_dv_pipe[0] <= rx_data_valid;
        wr_dv_pipe[1] <= wr_dv_pipe[0];
        wr_eof_bram[0] <= wr_dv_pipe[1] & !wr_dv_pipe[0];
     end
  end

   // no reset to allow srl16 target
  always @(posedge wr_clk)
  begin
     if (wr_enable == 1'b1) begin
        wr_gf_pipe[0] <= rx_good_frame;
        wr_gf_pipe[1] <= wr_gf_pipe[0];
        wr_bf_pipe[0] <= rx_bad_frame;
        wr_bf_pipe[1] <= wr_bf_pipe[0];
     end
  end

  // register data outputs from bram
  // no reset to allow srl16 target
  always @(posedge rd_clk)
  begin
     if (rd_en == 1'b1) begin
        rd_data_pipe_u <= rd_data_bram_u;
        rd_data_pipe_l <= rd_data_bram_l;
        if (rd_bram_u_reg == 1'b1) begin
           rd_data_pipe <= rd_data_pipe_u;
        end
        else begin
           rd_data_pipe <= rd_data_pipe_l;
        end
     end
  end

  // register data outputs from bram
  always @(posedge rd_clk)
  begin
     if (rd_en == 1'b1) begin
        if (rd_bram_u == 1'b1) begin
           rd_eof <= rd_eof_bram_u[0];
        end
        else begin
           rd_eof <= rd_eof_bram_l[0];
        end
     end
  end


  //----------------------------------------------------------------------------
  // Overflow functionality
  //----------------------------------------------------------------------------

  // to minimise the number of read address updates the bottom 6 bits of the 
  // read address are not passed across and the write domain will only sample 
  // them when bits 5 and 4 of the read address transition from 01 to 10.  
  // Since this is for full detection this just means that if the read stops
  // the write will hit full up to 64 locations early
  
  // need to use two bits and look for an increment transition as reload can cause
  // a decrement on this boundary (decrement is only by 3 so above bit 2 should be safe)
  always @(posedge rd_clk)
  begin
     if (rd_sreset == 1'b1) begin
        old_rd_addr <= 2'b00;
        update_addr_tog <= 1'b0;
     end
     else begin
        old_rd_addr <= rd_addr[5:4];
        if (rd_addr[5:4] == 2'b10 & old_rd_addr == 2'b01) begin
           update_addr_tog <= !update_addr_tog;
        end
     end
  end

  // sync_block sync_rd_addr_tog
  // (
    // .clk      (wr_clk),
    // .data_in  (update_addr_tog),
    // .data_out (update_addr_tog_sync)
  // );
  
reg [1:0]update_addr_tog_reg;
always@(posedge wr_clk)
begin
	update_addr_tog_reg <= {update_addr_tog_reg[0],update_addr_tog};
end
assign update_addr_tog_sync = update_addr_tog_reg[1];

  // Convert the synchronized read address pointer gray code back to binary.
  always @(posedge wr_clk)
  begin
     if (wr_sreset == 1'b1) begin
        update_addr_tog_sync_reg <= 1'b0;
        wr_rd_addr               <= 12'd0;
     end
     else begin
        update_addr_tog_sync_reg <= update_addr_tog_sync;
        if (update_addr_tog_sync_reg ^ update_addr_tog_sync) begin
           wr_rd_addr <= {rd_addr[11:6], 6'd0};
        end
     end
  end
  
  assign wr_addr_diff_in = {1'b0,wr_rd_addr} - {1'b0,wr_addr};

  // Obtain the difference between write and read pointers.
  always @(posedge wr_clk)
  begin
     if (wr_sreset == 1'b1) begin
        wr_addr_diff <= 12'b0;
     end
     else begin
        wr_addr_diff <= wr_addr_diff_in[11:0];
     end
  end

  // Detect when the FIFO is full
  // The FIFO is considered to be full if the write address
  // pointer is within 0 to 3 of the read address pointer.
  always @(posedge wr_clk)
  begin
     if (wr_sreset == 1'b1) begin
        wr_fifo_full <= 1'b0;
     end
     else if (wr_enable == 1'b1) begin
        if (wr_addr_diff[11:4] == 8'b0 && wr_addr_diff[3:2] != 2'b0) begin
           wr_fifo_full <= 1'b1;
        end
        else begin
           wr_fifo_full <= 1'b0;
        end
     end
  end

  assign overflow = (wr_state == OVFLOW_s) ? 1'b1 : 1'b0;


  //----------------------------------------------------------------------------
  // FIFO Status Signals
  //----------------------------------------------------------------------------

  // The FIFO status signal is four bits which represents the occupancy
  // of the FIFO in 16'ths.  To generate this signal we therefore only
  // need to compare the 4 most significant bits of the write address
  // pointer with the 4 most significant bits of the read address
  // pointer.

  // already have fifo status on write side through wr_addr_diff.
  // calculate fifo status here and output on the wr clock domain.

  always @(posedge wr_clk)
  begin
     if (wr_sreset == 1'b1) begin
         wr_fifo_status <= 4'b0;
     end
     else if (wr_enable == 1'b1) begin
        if (wr_addr_diff == 12'b0) begin
           wr_fifo_status <= 4'b0;
        end
        else begin
           wr_fifo_status[3] <= !wr_addr_diff[11];
           wr_fifo_status[2] <= !wr_addr_diff[10];
           wr_fifo_status[1] <= !wr_addr_diff[9];
           wr_fifo_status[0] <= !wr_addr_diff[8];
        end
     end
  end

  assign rx_fifo_status = wr_fifo_status;


  //----------------------------------------------------------------------------
  // Instantiate Memory
  //----------------------------------------------------------------------------

RAMB16_S9_S9#(
.DEVICE				  (DEVICE)
)
 ramgen_l ( 
	.doa(), 
	.cea(1),
	.dia({wr_eof_bram,wr_data_bram}), 
	.addra(wr_addr[10:0]), 
	.clka(wr_clk), 
	.wea(wr_en_l), 
	// .rsta(wr_sreset), 
	.dob({rd_eof_bram_l,rd_data_bram_l}), 
	.dib(), 
	.addrb(rd_addr[10:0]), 
	.clkb(rd_clk), 
	.web(0), 
	.ceb(rd_en)
	// .rstb(rd_sreset)
);


RAMB16_S9_S9#(
.DEVICE				  (DEVICE)
) 
ramgen_u ( 
	.doa(), 
	.cea(1),
	.dia({wr_eof_bram,wr_data_bram}), 
	.addra(wr_addr[10:0]), 
	.clka(wr_clk), 
	.wea(wr_en_u), 
	// .rsta(wr_sreset), 
	.dob({rd_eof_bram_u,rd_data_bram_u}), 
	.dib(), 
	.addrb(rd_addr[10:0]), 
	.clkb(rd_clk), 
	.web(0),
	.ceb(rd_en)
	// .rstb(rd_sreset)
);


endmodule
