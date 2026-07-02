module addr_crt (
 input         clk,
 input         rst_n,
 input   [7:0] udp_data,
 input         udp_vaild,
 input   [15:0]udp_length,
 
 output reg [15:0] wr_addr,
 output reg       wr_en,
 output        rd_en,
 output  [23:0] ram_data
);

reg done;
assign rd_en=done;
reg [7:0] ram_data_1;
reg [7:0] ram_data_2;
reg [7:0] ram_data_3;
assign ram_data = {ram_data_1,ram_data_2,ram_data_3};
reg flag;
reg [15:0] wr_addr_cnt;
reg [2:0] cnt;
always @(posedge clk or negedge rst_n ) begin
    if(!rst_n)begin
    wr_addr_cnt<=0;
        wr_en<=0;
            ram_data_1<=0;
            ram_data_2<=0;
            ram_data_3<=0;
            done<=0;
    end
        else if (udp_vaild  & cnt==0)
            begin
                wr_en<=1'b1;
                flag<=(udp_data == 8'hf1)?1'b1:1'b0;
            end
            else if (udp_vaild  & cnt==5 & flag)
            begin
                wr_en<=1'b1;
                ram_data_3<=udp_data;
            end
    else if (udp_vaild  & cnt==4 & flag)
            begin
                wr_en<=1'b1;
                ram_data_2<=udp_data;
            end
    else if (udp_vaild  & cnt==3 & flag)
            begin
                wr_en<=1'b1;
                ram_data_1<=udp_data;
            end
            else if (udp_vaild & cnt==2 & flag)
            begin
                wr_en<=1'b1;
                wr_addr[7:0]<=udp_data;
            end
            else if (udp_vaild &  cnt==1 & flag)
            begin
                wr_en<=1'b1;
                wr_addr[15:8]<=udp_data;
            end
        else begin
                wr_en<=1'b0;
                ram_data_1<=ram_data_1;
                ram_data_2<=ram_data_2;
                ram_data_3<=ram_data_3;
        end

end


always @(posedge clk or negedge rst_n ) begin
    if(!rst_n)begin
    cnt<=0;
    end
    else if (udp_vaild & cnt==0  & udp_data == 8'hf1)begin
    cnt<=cnt+1;
    end 
    else if (udp_vaild & cnt>0 & cnt<5  & flag)begin
    cnt<=cnt+1;
    end 
    else if (udp_vaild & cnt==5)  
    cnt<=0;
    else 
    cnt <= cnt;   
end

endmodule



//记length个有效时钟
/*always @(posedge clk or negedge rst_n ) begin
    if(!rst_n)
        cnt_length;
    else if (cnt_vaild==1)
        cnt_length<=cnt_length+1;
    else if (0<cnt_length<udp_length-1)
        cnt_length<=cnt_length+1;
    else if (cnt_length==udp_length-1)
        cnt_length<=0;
    else
        cnt_length<=cnt_length;    
end*/

//列计数器
/*always @(posedge clk or negedge rst_n ) begin
    if(!rst_n)
    cnt_h<=0;
    else if (cnt_vaild==1)begin
            if (cnt_h<10'd639)
            cnt_h<=cnt_h+1;
            else if (cnt_h==10'd639)
            cnt_h<=0;
    end
end

//行计数器
always @(posedge clk or negedge rst_n ) begin
    if(!rst_n)
    cnt_v<=0;
    else if (cnt_h<10'd639)
            cnt_v<=cnt_v;
    else if (cnt_h==10'd639)
            cnt_v<=cnt_v+1;
    else if (cnt_h==10'd639 & cnt_v==10'd479 )begin
            cnt_v<=0;
    end
end

//ram地址生成
always @(posedge clk or negedge rst_n ) begin
    if(!rst_n)begin
    wr_addr<=0;
    done<=0;
    end
    else if (cnt_vaild==1)begin
            if (cnt_h<10'd255 & cnt_v<10'd127)
            wr_addr<=wr_addr+1;
            else if (cnt_h==10'd255 & cnt_v==10'd127)begin
            wr_addr<=0;
            done<=1;
            end
    else wr_addr<=wr_addr;
    end
end*/
    
