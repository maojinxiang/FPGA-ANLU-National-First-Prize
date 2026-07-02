`timescale 1ns / 1ps
//********************************************************************** 
// -------------------------------------------------------------------
// >>>>>>>>>>>>>>>>>>>>>>>Copyright Notice<<<<<<<<<<<<<<<<<<<<<<<<<<<< 
// ------------------------------------------------------------------- 
//             /\ --------------- 
//            /  \ ------------- 
//           / /\ \ -----------
//          / /  \ \ ---------
//         / /    \ \ ------- 
//        / /      \ \ ----- 
//       / /_ _ _   \ \ --- 
//      /_ _ _ _ _\  \_\ -
//*********************************************************************** 
// Author: suluyang 
// Email:luyang.su@anlogic.com 
// Date:2020/10/26 
// Description: 
// 
// web：www.anlogic.com 
//------------------------------------------------------------------- 
//*********************************************************************/
module udp_loopback(

input   wire		app_rx_clk		   ,
input   wire		app_tx_clk		   ,
input   wire		reset              ,
input   wire [23:0]	app_rx_data        ,
input   wire		app_rx_data_valid  ,
input   wire [15:0] app_rx_data_length ,
			
input   wire		udp_tx_ready       ,
input   wire		app_tx_ack         ,
output  wire  [7:0] app_tx_data        ,
output	reg  		app_tx_data_request,
output	reg  		app_tx_data_valid  ,
output  reg  [15:0]	udp_data_length	 ,  //s
output  full_flag,
output [11:0 ] udp_wrusedw		
);
parameter  			 	DEVICE            = "EG4";//"PH1","EG4"
reg         app_tx_data_read;
wire [11:0] udp_packet_fifo_data_cnt;//synthesis keep
reg  [15:0] fifo_read_data_cnt;
reg  [15:0] udp_data_length_reg_ff1;
reg  [15:0] udp_data_length_reg_ff2;
wire [23:0]  app_tx_data_reg;


wire  [15:0] fifo_read_data_cnt_wire;
assign fifo_read_data_cnt_wire =fifo_read_data_cnt ;
assign app_tx_data = (fifo_read_data_cnt_wire == 3 )? app_tx_data_reg [7:0] : ((fifo_read_data_cnt_wire == 2 )? app_tx_data_reg [15:8] : ((fifo_read_data_cnt_wire == 1 )? app_tx_data_reg [23:16] : 0));

reg [1:0]   STATE;
localparam  WAIT_UDP_DATA   = 2'd0;
localparam  WAIT_ACK        = 2'd1;
localparam  SEND_UDP_DATA   = 2'd2;
localparam  DELAY           = 2'd3;

// assign udp_packet_fifo_data_cnt = 1;

wire empty_flag;//synthesis keep

ram_fifo#
(
	.DEVICE       	(DEVICE       	),//"PH1","EG4","SF1","EF2","EF3","AL"
	.DATA_WIDTH_W 	(24				),//写数据位宽
	.ADDR_WIDTH_W 	(12 			),//写地址位宽
	.DATA_WIDTH_R 	(24 			),//读数据位宽
	.ADDR_WIDTH_R 	(12 			),//读地址位宽
	.SHOW_AHEAD_EN	(1				)//普通/SHOWAHEAD模式
)
udp_packet_fifo
(
	.rst			(reset				), 
	.di				(app_rx_data		), 
	.clkw			(app_rx_clk			), 
	.we				(app_rx_data_valid	),
	.clkr			(app_tx_clk			), 
	.re				(app_tx_data_read	), 
	.do				(app_tx_data_reg	), 
	.empty_flag		(	empty_flag				), 
	.full_flag		(full_flag					), 
	.wrusedw		(	udp_wrusedw				), 
	.rdusedw		(udp_packet_fifo_data_cnt)//udp_packet_fifo_data_cnt)
);


// fifo_sdr_data_2 udp_packet_fifo(
//    .rst			   			(reset	)	,  //asynchronous port,active hight
//    .clkw		   			(app_rx_clk		),  //write clock
//    .clkr		   			(app_tx_clk		),  //read clock
//    .we			   			(app_rx_data_valid			),  //write enable,active hight
//    .di			   			(app_rx_data			),  //write data
//    .re			   			(app_tx_data_read			),  //ead enable,active hight
//    .	dout		    	(app_tx_data_reg		),  //read data
//    . 	valid		     	(app_tx_data_valid		),  //read data valid flag
//    .	full_flag	    	(full_flag	),  //fifo full flag
//    .	empty_flag	    	(empty_flag	),  //fifo empty flag
//    .	afull		    	(		),  //fifo almost full flag
//    .	aempty		    	(		),  //fifo almost empty flag
//    .	wrusedw	  	    	(	)	,  	//	stored data number in fifo
//    .	rdusedw 	    	( 	)//available data number for read
 
// );


always@(posedge app_tx_clk or posedge reset)
begin
	if(reset) begin
		udp_data_length_reg_ff1 <= 16'd0;
		udp_data_length_reg_ff2 <= 16'd0;
	end	
	else if(app_rx_data_valid)
	begin 
		udp_data_length_reg_ff1 <= app_rx_data_length;
		udp_data_length_reg_ff2 <= udp_data_length_reg_ff1;
	end
end

reg [19:0]tx_cnt ;//synthesis keep
always@(posedge app_tx_clk or posedge reset)
begin
	if(reset) begin
		tx_cnt <= 20'd0;
	end	
	else if(app_tx_data_valid)
	begin 
    tx_cnt<=tx_cnt+1;
	end
end

reg [15:0]cnt;
always@(posedge app_tx_clk or posedge reset)
begin
	if(reset) begin
		app_tx_data_request <= 1'b0;
		app_tx_data_read 	<= 1'b0;
		app_tx_data_valid 	<= 1'b0;
		fifo_read_data_cnt 	<= 16'd0;
		udp_data_length 	<= 16'd0;
        cnt <=16'b0;
		STATE 				<= WAIT_UDP_DATA;
	end
	else begin
	   case(STATE)
			WAIT_UDP_DATA: // 0
				begin
                    cnt<=16'b0;
					if((udp_packet_fifo_data_cnt > 12'd0)  && (~app_rx_data_valid) && udp_tx_ready) begin
                  //if(!empty_flag && (~app_rx_data_valid) && udp_tx_ready) begin
                   // if( (~app_rx_data_valid) && udp_tx_ready) begin
						app_tx_data_request <= 1'b1;
						STATE 				<= WAIT_ACK;
					end
					else begin
						app_tx_data_request <= 1'b0;
     
						STATE 				<= WAIT_UDP_DATA;
					end
				end
			WAIT_ACK: // 1
				begin
				   if(app_tx_ack) begin
						app_tx_data_request <= 1'b0;
						app_tx_data_read 	<= 1'b1;
						app_tx_data_valid 	<= 1'b0;
						udp_data_length 	<= udp_data_length_reg_ff2;//
						STATE 				<= SEND_UDP_DATA;
					end
					else begin
						app_tx_data_request <= 1'b1;
						app_tx_data_read	<= 1'b0;
						app_tx_data_valid 	<= 1'b0;
						udp_data_length 	<= 16'd0;
						STATE 				<= WAIT_ACK;
					end
				end
			SEND_UDP_DATA: // 2
				begin
					if(fifo_read_data_cnt == (udp_data_length_reg_ff2 )) begin
						fifo_read_data_cnt 	<= 16'd0;
						app_tx_data_valid 	<= 1'b0;
						app_tx_data_read 	<= 1'b0;
						STATE 				<= DELAY;
					end
					else  if (fifo_read_data_cnt == 0 )begin
						fifo_read_data_cnt 	<= fifo_read_data_cnt + 1'b1;
						app_tx_data_valid  	<= 1'b1;
						app_tx_data_read 	<= 1'b0;
						STATE 				<= SEND_UDP_DATA;
					end		
					else begin
						fifo_read_data_cnt 	<= fifo_read_data_cnt + 1'b1;
						app_tx_data_valid  	<= 1'b1;
						app_tx_data_read 	<= 1'b0;
						STATE 				<= SEND_UDP_DATA;
					end				
				end
			DELAY:
				begin
					if(cnt<16'h00000fff)begin
                    	cnt<=cnt+1'b1;
						STATE 	<= DELAY;
                        end
					else
						STATE 	<= WAIT_UDP_DATA;
				end
			default: STATE 		<= WAIT_UDP_DATA;
		endcase
	end
end

endmodule
