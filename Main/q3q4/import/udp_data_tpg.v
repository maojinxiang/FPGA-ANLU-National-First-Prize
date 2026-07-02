module udp_data_tpg(
		
input    wire		 clk				,
input    wire		 reset              ,

output   reg  [7:0]	 tpg_data        	,//数据输出
output   reg 		 tpg_data_valid  	,//数据有效信号
output   reg  [15:0] tpg_data_udp_length,//数据长度（包含帧头）
output   reg 		 tpg_data_done,
input    wire        tpg_data_enable	,//数据激励使能
input    wire [15:0] tpg_data_header0	,//帧头0
input    wire [15:0] tpg_data_header1   ,//帧头1
input    wire [15:0] tpg_data_type      ,//数据帧类型
input    wire [15:0] tpg_data_length    ,//数据长度
input    wire [15:0] tpg_data_num		,//产生的帧个数
input    wire [7:0]  tpg_data_ifg		

);

reg [11:0] 		cnt0;
wire 			add_cnt0;
wire 			end_cnt0;  
reg [11:0] 		cnt1;
wire 			add_cnt1;
wire 			end_cnt1; 
reg             add_en;
reg [7:0]       ifg_reg;
reg             cnt_en;

//计数器1 产生帧数据
always@(posedge clk or posedge reset)begin
    if(reset)begin
        cnt0 <= 0;
    end
    else if(add_cnt0)begin
        if(end_cnt0)
            cnt0 <= 0;
        else
            cnt0 <= cnt0 + 1;
    end
end

assign add_cnt0 = tpg_data_enable && add_en && cnt_en;
assign end_cnt0 = add_cnt0 && cnt0 == tpg_data_length + 8 ;

//计数器2 统计发送帧个数
always@(posedge clk or posedge reset)begin 
    if(reset)begin
        cnt1 <= 0;
    end
    else if(add_cnt1)begin
        if(end_cnt1)
            cnt1 <= 0;
        else
            cnt1 <= cnt1 + 1;
    end
end

assign add_cnt1 = end_cnt0 && cnt_en;
assign end_cnt1 = add_cnt1 && cnt1 == tpg_data_num - 1;


always@(posedge clk or posedge reset)
begin
	if(reset)begin
		tpg_data        	<= 8'h0a;
		tpg_data_valid  	<= 0;
		tpg_data_udp_length <= 0;
		add_en              <= 1;
		cnt_en				<= 1;
		tpg_data_done		<= 0;
		ifg_reg             <= tpg_data_ifg;
	end	
	else begin 
		if(tpg_data_enable && cnt_en)begin
		
			tpg_data_udp_length <= tpg_data_length + 8;
						
			if(end_cnt1)
				cnt_en	<= 0;//发送一次结束标志			
			
			case(cnt0)
				0:begin
					tpg_data[7:0]    	<= tpg_data_header0[15:8];
					tpg_data_valid  	<= 1;
				end
				1:begin
					tpg_data[7:0]    	<= tpg_data_header0[7:0];
					tpg_data_valid  	<= 1;					
				end				
				2:begin
					tpg_data[7:0]    	<= tpg_data_header1[15:8];
					tpg_data_valid  	<= 1;					
				end				
				3:begin
					tpg_data[7:0]    	<= tpg_data_header1[7:0];
					tpg_data_valid  	<= 1;				
				end				
				4:begin
					tpg_data[7:0]    	<= tpg_data_type[15:8];
					tpg_data_valid  	<= 1;				
				end				
				5:begin
					tpg_data[7:0]    	<= tpg_data_type[7:0];
					tpg_data_valid  	<= 1;					
				end
				6:begin
					tpg_data[7:0]    	<= tpg_data_length[15:8];
					tpg_data_valid  	<= 1;				
				end
				7:begin
					tpg_data[7:0]    	<= tpg_data_length[7:0];
					tpg_data_valid  	<= 1;				
				end
				tpg_data_udp_length - 1:begin
					tpg_data[7:0]    	<= cnt0 - 8;
					tpg_data_valid  	<= 1;
					add_en              <= 0;//计数器暂停计数
				end				
				tpg_data_udp_length :begin
					tpg_data[7:0]    	<= 8'h00;
					tpg_data_valid  	<= 0;
					ifg_reg             <= ifg_reg - 1;
					tpg_data_done		<= 0;
					if(ifg_reg == 0)begin//调整IFG
						add_en              <= 1;//计数器开始计数
						tpg_data_done		<= 1;
						ifg_reg             <= tpg_data_ifg;
					end
				end
				default: begin
					tpg_data[7:0]    	<= cnt0 - 8;
					tpg_data_valid  	<= 1;				
				end
			endcase
		end
		else begin
			tpg_data        	<= 0;
			tpg_data_valid  	<= 0;
			tpg_data_udp_length <= 0;
		end
	end
end


endmodule
