`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: anlgoic
// Author: 	xg 
// description: app write and read test pattern generator and check
//////////////////////////////////////////////////////////////////////////////////

`define DEBUG
`include "../include/global_def.v"

module app_wrrd 
	(   
		input   clk,
        input   rst_n,
		input   sd_clk,
		input			Sdr_init_done,//synthesis keep
		input			Sdr_init_ref_vld,
		input   		full_flag_net,
		input                sdr_data_valid,//synthesis keep
		input     [23:0]     sdr_data,
		input 				 Sdr_busy,
        output						App_wr_en, 
        output  [`ADDR_WIDTH-1:0]	App_wr_addr,  
		output	[`DM_WIDTH-1:0]		App_wr_dm,
		output	[`DATA_WIDTH-1:0]	App_wr_din,
		
		output						App_rd_en,
		output	reg [`ADDR_WIDTH-1:0]	App_rd_addr,
		input						Sdr_rd_en,
		input	[`DATA_WIDTH-1:0]	Sdr_rd_dout,
        output  full_flag,
		output reg            wr_done,//synthesis keep
		input  [11:0 ] udp_wrusedw
		// output	reg		Check_ok	
	);
reg [18:0]w_addr_cnt;
// reg	[2:0]	judge_cnt;
// reg			tx_vld;
// reg	[13:0]	tx_cnt;
// reg			wr_en;
// reg	[`ADDR_WIDTH-1:0]	wr_addr,wr_addr_1d;
// reg	[`DATA_WIDTH-1:0]	wr_din;
// reg						rd_en;
// reg	[`ADDR_WIDTH-1:0]	rd_addr,rd_addr_1d;
	
wire wr_done_debug;//synthesis keep
assign wr_done_debug = wr_done;

assign App_wr_dm =4'b0;
reg [8:0] wr_fifo_cnt;//synthesis keep
wire  [9:0] rdusedw;//synthesis keep
wire  [23:0] sdr_rd_data;//synthesis keep
reg wr_fifo_rd_en;//synthesis keep
wire full_flag;//synthesis keep
wire empty_flag;//synthesis keep
fifo_sdr_data_2 u_wr_fifo_sdr_data(
   .rst			   			(~rst_n		)	,  //asynchronous port,active hight
   .clkw		   			(sd_clk		),  //write clock
   .clkr		   			(clk		),  //read clock
   .we			   			(sdr_data_valid			),  //write enable,active hight
   .di			   			(sdr_data			),  //write data
   .re			   			(wr_fifo_rd_en			),  //ead enable,active hight
   .	dout		    	(App_wr_din		),  //read data
   . 	valid		     	(		),  //read data valid flag
   .	full_flag	    	(full_flag	),  //fifo full flag
   .	empty_flag	    	(empty_flag	),  //fifo empty flag
   .	afull		    	(afull		),  //fifo almost full flag
   .	aempty		    	(aempty		),  //fifo almost empty flag
   .	wrusedw	  	    	(wrusedw	)	,  	//	stored data number in fifo
   .	rdusedw 	    	(rdusedw 	)//available data number for read //会持续两个快的时钟周期
 
);

assign App_wr_en = wr_fifo_rd_en;
reg wr_fifo_rd_en_reg;
//assign App_wr_en = wr_fifo_rd_en_reg ;
//	always @(posedge clk or negedge rst_n)           
//		begin                                        
//			if(!rst_n)                               
//			wr_fifo_cnt <=9'b0;	                                   
//			else if(wr_fifo_cnt == 9'b0 & wr_fifo_rd_en )
//			wr_fifo_cnt <= wr_fifo_cnt+1'b1;
//			else if (wr_fifo_cnt >9'b0 & wr_fifo_cnt < 9'd511 & !Sdr_busy) 
//			wr_fifo_cnt <= wr_fifo_cnt+1'b1;
//			else if (wr_fifo_cnt == 9'd511)
//			wr_fifo_cnt <=9'b0;										 
//			else       
//			wr_fifo_cnt <= wr_fifo_cnt;                              
//		end                                          

reg [1:0] brust_rd_cnt;
reg empty_flag_reg;

	always @(posedge clk )           
		begin                                                                     
			empty_flag_reg <=empty_flag;	                                                                
		end   
	always @(posedge clk or negedge rst_n)           
		begin                                        
			if(!rst_n)                               
			wr_fifo_rd_en <=1'b0;	                                   
			else if( !Sdr_busy  & Sdr_init_ref_vld == 1'b0 & w_addr_cnt <= 19'd307199 & (rdusedw>4))
			wr_fifo_rd_en <= 1'b1;	
			else if (!Sdr_busy  & Sdr_init_ref_vld == 1'b0 & w_addr_cnt == 19'd307196 & (rdusedw==4))
            wr_fifo_rd_en <= 1'b1;							 
			else if (brust_rd_cnt ==3)       
			wr_fifo_rd_en <= 1'b0;  
			else
			wr_fifo_rd_en <=wr_fifo_rd_en;                            
		end    


	always @(posedge clk or negedge rst_n)           
		begin                                        
			if(!rst_n)                               
			brust_rd_cnt <=2'b0;	                                   							 
			else  if (wr_fifo_rd_en & (brust_rd_cnt<3))      
			brust_rd_cnt <=brust_rd_cnt+1;  
			else if   (wr_fifo_rd_en & (brust_rd_cnt==3))    
			brust_rd_cnt <=2'b0;                        
		end   


	always @(posedge clk or negedge rst_n)           
		begin                                        
			if(!rst_n)                               
			wr_fifo_rd_en_reg <=1'b0;	                                   							 
			else       
			wr_fifo_rd_en_reg <=wr_fifo_rd_en;                              
		end    
        
reg [18:0]w_addr_cnt;
	always @(posedge clk or negedge rst_n)           
		begin                                        
			if(!rst_n) begin                              
			w_addr_cnt <= 19'b0;
			wr_done <=1'b0;
			end	                                   
			else if(App_wr_en & w_addr_cnt < 19'd307199)                                
			w_addr_cnt <=w_addr_cnt +1'b1;										 
			else if(App_wr_en & w_addr_cnt == 19'd307199) 
			begin
			w_addr_cnt <=19'b0;
			wr_done <=1'b1;
			end	
			else begin
			w_addr_cnt <=w_addr_cnt;
			wr_done <=wr_done;
			end
		end  
        
reg [15:0]sdr_rd_delay;
	always @(posedge clk or negedge rst_n)           
		begin                                        
			if(!rst_n) begin                              
			sdr_rd_delay <= 19'b0;
			end	                                   
			else if(wr_done & sdr_rd_delay < 19'd1000)                                
			sdr_rd_delay <=sdr_rd_delay +1'b1;										 
			else 
			sdr_rd_delay <=sdr_rd_delay;
		end  
 reg [18:0] sdr_rd_done_cnt;//synthesis keep
 
 reg  sdr_en_done;   //synthesis keep
 	always @(posedge clk or negedge rst_n)           
		begin                                        
			if(!rst_n) begin                              
			sdr_rd_done_cnt <= 19'b0;
			sdr_en_done <=1'b0;
			end	                                   
			else if(Sdr_rd_en & sdr_rd_done_cnt < 19'd307199)                                
			sdr_rd_done_cnt <=sdr_rd_done_cnt +1'b1;										 
			else if(Sdr_rd_en & sdr_rd_done_cnt == 19'd307199) 
			begin
			sdr_rd_done_cnt <=19'b0;
			sdr_en_done <=1'b1;
			end	
			else begin
			sdr_rd_done_cnt <=sdr_rd_done_cnt;
			sdr_en_done <=sdr_en_done;
			end
		end                                          
assign App_wr_addr = w_addr_cnt;




//以太网读sdram

//地址产生
reg [1:0] burst_sdr_rd_cnt;
reg [18:0] r_addr_cnt;//synthesis keep
reg app_rd_en_reg;//synthesis keep
reg rd_done;//synthesis keep
	always @(posedge clk or negedge rst_n)           
		begin                                        
			if(!rst_n) begin                              
			r_addr_cnt <= 19'b0;
			rd_done <=1'b0;
            app_rd_en_reg<=1'b0;
			end	                                   
			else if(!Sdr_busy & r_addr_cnt < 19'd307199 &  (sdr_rd_delay== 1000) & !rd_done & (udp_wrusedw < 'd2048) & Sdr_init_ref_vld == 1'b0 & burst_sdr_rd_cnt == 2'b0 )                                
			begin
            r_addr_cnt <=r_addr_cnt +1'b1;										 
			app_rd_en_reg <= 1'b1;
            end
			else if (!Sdr_busy & r_addr_cnt < 19'd307199 &  (sdr_rd_delay== 1000) & !rd_done & (udp_wrusedw < 'd2048) & Sdr_init_ref_vld == 1'b0 & (burst_sdr_rd_cnt > 0 &  burst_sdr_rd_cnt < 3))
			begin
            r_addr_cnt <=r_addr_cnt +1'b1;										 
			app_rd_en_reg <= 1'b1;
            end
			else if (!Sdr_busy & r_addr_cnt < 19'd307199 &  (sdr_rd_delay== 1000) & !rd_done & (udp_wrusedw < 'd2048) & Sdr_init_ref_vld == 1'b0 & burst_sdr_rd_cnt == 3)
			begin									 
			app_rd_en_reg <= 1'b0;
            end
            else if(!Sdr_busy & r_addr_cnt == 19'd307199 & (sdr_rd_delay== 1000) & !rd_done & (udp_wrusedw < 'd2048)& Sdr_init_ref_vld == 1'b0) 
			begin
			r_addr_cnt <=r_addr_cnt+1'b1;
			rd_done <=1'b1;
            app_rd_en_reg <= 1'b1;
			end	
			else begin
			r_addr_cnt <=r_addr_cnt;
			rd_done <=rd_done;
            app_rd_en_reg<=1'b0;
			end
		end        


	always @(posedge clk or negedge rst_n)           
		begin                                        
			if(!rst_n)                               
			burst_sdr_rd_cnt <=2'b0;	                                   							 
			else  if (app_rd_en_reg & (burst_sdr_rd_cnt<3))      
			burst_sdr_rd_cnt <=burst_sdr_rd_cnt+1;  
			else if   (app_rd_en_reg & (burst_sdr_rd_cnt==3))    
			burst_sdr_rd_cnt <=2'b0;                        
		end 


assign App_rd_en     =app_rd_en_reg;

	always @(posedge clk or negedge rst_n)           
		begin                                        
			if(!rst_n) begin                              
			App_rd_addr <= 19'b0;
			end	                                   
			else if(App_rd_en & App_rd_addr < 19'd307199)                                
			App_rd_addr <=App_rd_addr +1'b1;										 
			else if(App_wr_en & App_rd_addr == 19'd307199) 
			begin
			App_rd_addr <=19'b0;
			end	
			else begin
			App_rd_addr <=App_rd_addr;
			end
		end

//sdram 有效读出的计数

reg [18:0] sdr_rd_cnt;//synthesis keep
reg sdr_rd_done  ; //synthesis keep
	always @(posedge clk or negedge rst_n)           
		begin                                        
			if(!rst_n) begin                              
			sdr_rd_cnt <= 19'b0;
			sdr_rd_done <=1'b0;
			end	                                   
			else if(Sdr_rd_en & !sdr_rd_done)                                
			begin
            sdr_rd_cnt <=sdr_rd_cnt +1'b1;										 
            end
            else if(sdr_rd_cnt == 19'd307199) 
			begin
			sdr_rd_done <=1'b1;
			end	
			else begin
			sdr_rd_cnt <=sdr_rd_cnt;
			sdr_rd_done <=sdr_rd_done;
			end
		end 
//读有效信号的产生

// always @(posedge Clk)
// begin
// 	if(Rst)
// 		judge_cnt <= 'd0;
// 	else if(Sdr_init_done)
// 		judge_cnt <= judge_cnt+1'b1;
// end	
	
	
// always @(posedge Clk)
// begin
// 	if(Rst)
// 		tx_vld <= 'd0;
// 	else if(judge_cnt==3'b111 & (!Sdr_init_ref_vld))
// 		tx_vld <= 1'b1;
// 	else if(tx_cnt[13] | Sdr_init_ref_vld)
// 		tx_vld <= 1'b0;
// end

// always @(posedge Clk)
// begin
// 	if(Rst)
// 		tx_cnt <= 'd0;
// 	else if(tx_vld)
// 		tx_cnt <= tx_cnt+1'b1;
// 	else
// 		tx_cnt <= 'd0;
// end



// always @(posedge Clk)
// begin
// 	if(Rst)
// 		begin	
// 			wr_en <= 1'b0;
// 			wr_addr <= 'd0;
// 			wr_din <= 'd0;
			
// 			wr_addr_1d <= 'd0;
// 		end
// 	else 
// 		if(tx_cnt[12:11]==2'b01)
// 			begin
// 				wr_en <= 1'b1;
// 				wr_addr <= wr_addr+1'b1;
// 				wr_din <= wr_din+1'b1;
// 			end
// 		else
// 			begin
// 				wr_en <= 1'b0;
// 				wr_addr <= wr_addr;
// 				wr_din <= wr_din;
// 			end
// 		wr_addr_1d <= wr_addr;
// end
// assign		App_wr_en=wr_en;
// assign  	App_wr_addr=wr_addr_1d;
// assign		App_wr_dm=4'b0000;
// assign		App_wr_din=wr_din;


// always @(posedge Clk)
// begin
// 	if(Rst)
// 		begin	
// 			rd_en <= 1'b0;
// 			rd_addr <= 'd0;
// 			rd_addr_1d <= 'd0;
// 		end
// 	else 
// 		if(tx_cnt[12:11]==2'b11)
// 			begin
// 				rd_en <= 1'b1;
// 				rd_addr <= rd_addr+1'b1;
// 			end
// 		else
// 			begin
// 				rd_en <= 1'b0;
// 				rd_addr <= rd_addr;
// 			end
// 		rd_addr_1d <= rd_addr;
// end

// assign App_rd_en=rd_en;
// assign App_rd_addr=rd_addr_1d;


// reg			Sdr_rd_en_1d;
// reg	[15:0]	init_data,Sdr_rd_dout_1d;

// always @(posedge Clk)
// begin
// 	if(Rst)
// 		init_data <= 'd0;
// 	else if(Sdr_rd_en)
// 		init_data <= init_data+1'b1;
// end

// always @(posedge Clk)
// begin
// 	Sdr_rd_dout_1d <= Sdr_rd_dout[15:0];
// 	Sdr_rd_en_1d <= Sdr_rd_en;
	
// 	if(Sdr_rd_en_1d)
// 		if(init_data!=Sdr_rd_dout_1d)
// 			Check_ok <= 1'b1;
// 		else
// 			Check_ok <= 1'b0;
// 	else
// 		Check_ok <= 1'b0;
// end
	



endmodule 
