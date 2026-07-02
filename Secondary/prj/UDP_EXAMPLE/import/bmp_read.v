
module bmp_read(
	input                       clk,
	input                       rst,
	output                      ready,
	input                       find,
	input                       sd_init_done,                //SD card initialization completed
	output reg[3:0]             state_code,                  //state indication coding,
															 // 0:SD card is initializing,
															 // 1:wait for the button to press
															 // 2:looking for the bmp file
															 // 3:reading
	input[15:0]                 bmp_width,                   //search the width of bmp
	output reg                  write_req,                   //start writing request
	input                       write_req_ack,               //write request response
	output reg                  sd_sec_read,                 //SD card sector read
	output reg[31:0]            sd_sec_read_addr,            //SD card sector read address
	input[7:0]                  sd_sec_read_data,            //SD card sector read data
	input                       sd_sec_read_data_valid,      //SD card sector read data valid
	input                       sd_sec_read_end,             //SD card sector read end
	output reg                  bmp_data_wr_en,              //bmp image data write enable
	output reg[23:0]            bmp_data                     //bmp image data
);
localparam S_IDLE         = 0;
localparam S_FIND         = 1;
localparam S_READ_WAIT    = 2;
localparam S_READ         = 3;
localparam S_END          = 4;

localparam HEADER_SIZE    = 54;

reg[3:0]         state;
reg[9:0]         rd_cnt;                     //sector read length counter
reg[7:0]         header_0;
reg[7:0]         header_1;
reg[31:0]        file_len;
reg[31:0]        data_offset;                //pixel data start offset (从BMP头读取)
reg[31:0]        width;
reg[31:0]        height;                     //image height
reg[15:0]        bpp;                        //bits per pixel (24 or 32)
reg[31:0]        bmp_len_cnt;                //bmp file length counter
reg              found;
wire             bmp_data_valid;             //bmp image data valid
reg[1:0]         bmp_len_cnt_tmp;            //bmp RGB counter: 0 1 2 (24bit) or 0 1 2 3 (32bit)
reg[31:0]        pixel_cnt;                  //已输出的像素计数器
reg[31:0]        total_pixels;               //总像素数 = width * height
reg[31:0]        row_bytes;                  //每行的字节数（含填充）
reg[31:0]        pixel_in_row;               //当前行中的像素计数

//根据实际的data_offset判断数据有效性，而不是硬编码54
assign bmp_data_valid = (sd_sec_read_data_valid == 1'b1 && bmp_len_cnt >= data_offset && bmp_len_cnt < file_len);
assign ready = (state == S_IDLE);
always@(posedge clk or posedge rst)
begin
	if(rst == 1'b1)
		rd_cnt <= 10'd0;
	else if(state == S_FIND)
	begin
		if(sd_sec_read_data_valid == 1'b1)
			rd_cnt <= rd_cnt + 10'd1;
		else if(sd_sec_read_end == 1'b1)
			rd_cnt <= 10'd0;
	end
	else
		rd_cnt <= 10'd0;
end

always@(posedge clk or posedge rst)
begin
	if(rst == 1'b1)
	begin
		header_0 <= 8'd0;
		header_1 <= 8'd0;
		file_len <= 32'd0;
		data_offset <= 32'd54;  // 默认值
		width <= 32'd0;
		height <= 32'd0;
		bpp <= 16'd0;
		found <= 1'b0;
		total_pixels <= 32'd0;
		row_bytes <= 32'd0;
	end
	else if(state == S_FIND && sd_sec_read_data_valid == 1'b1)
	begin
		//file header
		if(rd_cnt == 10'd0)
			header_0 <= sd_sec_read_data;
		if(rd_cnt == 10'd1)
			header_1 <= sd_sec_read_data;
        //file length
		if(rd_cnt == 10'd2)
			file_len[7:0] <= sd_sec_read_data;
		if(rd_cnt == 10'd3)
			file_len[15:8] <= sd_sec_read_data;
		if(rd_cnt == 10'd4)
			file_len[23:16] <= sd_sec_read_data;
		if(rd_cnt == 10'd5)
			file_len[31:24] <= sd_sec_read_data;
        //pixel data offset (关键！从偏移10-13读取真实的数据起始位置)
		if(rd_cnt == 10'd10)
			data_offset[7:0] <= sd_sec_read_data;
		if(rd_cnt == 10'd11)
			data_offset[15:8] <= sd_sec_read_data;
		if(rd_cnt == 10'd12)
			data_offset[23:16] <= sd_sec_read_data;
		if(rd_cnt == 10'd13)
			data_offset[31:24] <= sd_sec_read_data;
        //image width (offset 18-21)
		if(rd_cnt == 10'd18)
			width[7:0] <= sd_sec_read_data;
		if(rd_cnt == 10'd19)
			width[15:8] <= sd_sec_read_data;
		if(rd_cnt == 10'd20)
			width[23:16] <= sd_sec_read_data;
		if(rd_cnt == 10'd21)
			width[31:24] <= sd_sec_read_data;
        //image height (offset 22-25) - 关键！需要读取高度来计算总像素数
		if(rd_cnt == 10'd22)
			height[7:0] <= sd_sec_read_data;
		if(rd_cnt == 10'd23)
			height[15:8] <= sd_sec_read_data;
		if(rd_cnt == 10'd24)
			height[23:16] <= sd_sec_read_data;
		if(rd_cnt == 10'd25)
			height[31:24] <= sd_sec_read_data;
        //bits per pixel (BPP) at offset 28-29
		if(rd_cnt == 10'd28)
			bpp[7:0] <= sd_sec_read_data;
		if(rd_cnt == 10'd29)
			bpp[15:8] <= sd_sec_read_data;
        //check the width of the image and file header after the end of the file header
        //支持24位和32位BMP
		if(rd_cnt == 10'd54 && header_0 == "B" && header_1 == "M" && width[15:0] == bmp_width && (bpp == 16'd24 || bpp == 16'd32))
		begin
			found <= 1'b1;
			// 计算总像素数和每行字节数
			total_pixels <= width * height;
			// 24位BMP: 每像素3字节, 每行需4字节对齐
			// 32位BMP: 每像素4字节, 自然对齐
			if(bpp == 16'd24)
				row_bytes <= ((width * 3 + 3) >> 2) << 2;  // 向上取整到4的倍数
			else
				row_bytes <= width * 4;  // 32位已对齐
		end
	end
	else if(state != S_FIND)
		found <= 1'b0;
end

//bmp file length counter
always@(posedge clk or posedge rst)
begin
	if(rst == 1'b1)
		bmp_len_cnt <= 32'd0;
	else if(state == S_READ)
	begin
		if(sd_sec_read_data_valid == 1'b1)
			bmp_len_cnt <= bmp_len_cnt + 32'd1;
	end
	else if(state == S_END)
		bmp_len_cnt <= 32'd0;
end

//像素计数器 - 跟踪已输出的像素数
always@(posedge clk or posedge rst)
begin
	if(rst == 1'b1)
		pixel_cnt <= 32'd0;
	else if(state == S_READ)
	begin
		if(bmp_data_wr_en == 1'b1)
			pixel_cnt <= pixel_cnt + 32'd1;
	end
	else if(state == S_END)
		pixel_cnt <= 32'd0;
end

//行内像素计数器 - 用于检测行结束和跳过填充字节
always@(posedge clk or posedge rst)
begin
	if(rst == 1'b1)
		pixel_in_row <= 32'd0;
	else if(state == S_READ)
	begin
		if(bmp_data_wr_en == 1'b1)
		begin
			if(pixel_in_row >= (width - 1))
				pixel_in_row <= 32'd0;  // 行结束，重置
			else
				pixel_in_row <= pixel_in_row + 32'd1;
		end
	end
	else if(state == S_END)
		pixel_in_row <= 32'd0;
end

//bmp RGB counter (根据BPP决定最大值：24位=2, 32位=3)
//关键修复：添加行内像素检查，防止填充字节进入RGB计数器
always@(posedge clk or posedge rst)
begin
	if(rst == 1'b1)
		bmp_len_cnt_tmp <= 2'd0;
	else if(state == S_READ)
	begin
		// 关键修复：同时检查总像素数和行内像素位置，避免填充字节
		// 只有在当前像素是有效像素时才递增RGB计数器
		if(bmp_data_valid == 1'b1 && pixel_cnt < total_pixels && pixel_in_row < width)
		begin
			// 24位BMP: 0->1->2->0 (读3字节)
			// 32位BMP: 0->1->2->3->0 (读4字节，但只用前3字节)
			if(bpp == 16'd24)
				bmp_len_cnt_tmp <= (bmp_len_cnt_tmp == 2'd2) ? 2'd0 : bmp_len_cnt_tmp + 2'd1;
			else // 32位BMP
				bmp_len_cnt_tmp <= (bmp_len_cnt_tmp == 2'd3) ? 2'd0 : bmp_len_cnt_tmp + 2'd1;
		end
		// 当读到填充字节时（pixel_in_row >= width），保持计数器不变
		// 这样填充字节就不会被误当作RGB数据
	end
	else if(state == S_END)
		bmp_len_cnt_tmp <= 2'd0;
end

always@(posedge clk or posedge rst)
begin
	if(rst == 1'b1)
	begin
		bmp_data_wr_en <= 1'b0;
		bmp_data <= 24'd0;
	end
	else if(state == S_READ)
	begin
		// BMP文件格式: BGR存储顺序（无论24位还是32位）
		// 目标输出格式: bmp_data = {R[23:16], G[15:8], B[7:0]}（与摄像头一致）
		// 24位BMP: 从文件读取 B, G, R (3字节)
		// 32位BMP: 从文件读取 B, G, R, A (4字节，A被忽略)

		// 关键修复：同时检查总像素数和行内像素位置
		if(pixel_cnt < total_pixels && pixel_in_row < width)
		begin
			if(bmp_len_cnt_tmp == 2'd0 && bmp_data_valid == 1'b1)
			begin
				bmp_data_wr_en <= 1'b0;
				bmp_data[7:0] <= sd_sec_read_data;  // 第1字节 Blue -> 存到 [7:0]
			end
			else if(bmp_len_cnt_tmp == 2'd1 && bmp_data_valid == 1'b1)
			begin
				bmp_data_wr_en <= 1'b0;
				bmp_data[15:8] <= sd_sec_read_data;  // 第2字节 Green -> 存到 [15:8]
			end
			else if(bmp_len_cnt_tmp == 2'd2 && bmp_data_valid == 1'b1)
			begin
				// 第3字节 Red
				bmp_data[23:16] <= sd_sec_read_data;  // Red -> 存到 [23:16]
				// 此时 bmp_data = {R[23:16], G[15:8], B[7:0]} 符合目标格式
				// 24位BMP: 已读完BGR，立即输出
				// 32位BMP: 还需读取Alpha（但不影响RGB数据）
				if(bpp == 16'd24)
					bmp_data_wr_en <= 1'b1;  // 24位BMP: 输出RGB数据
				else
					bmp_data_wr_en <= 1'b0;  // 32位BMP: 等待Alpha字节
			end
			else if(bmp_len_cnt_tmp == 2'd3 && bmp_data_valid == 1'b1)
			begin
				// 第4字节 Alpha（32位BMP专用）
				// Alpha通道被忽略，bmp_data中的RGB数据保持不变
				bmp_data_wr_en <= 1'b1;  // 32位BMP: 输出RGB数据，忽略Alpha
			end
			else
				bmp_data_wr_en <= 1'b0;
		end
		else
		begin
			// 超出有效像素范围（填充字节或已完成），停止输出
			bmp_data_wr_en <= 1'b0;
		end
	end
	else
		bmp_data_wr_en <= 1'b0;
end

always@(posedge clk or posedge rst)
begin
	if(rst == 1'b1)
	begin
		state <= S_IDLE;
		sd_sec_read <= 1'b0;
		sd_sec_read_addr <= 32'd16000;
		write_req <= 1'b0;
		state_code <= 4'd0;
	end
	else if(sd_init_done == 1'b0)
	begin
		state <= S_IDLE;
	end
	else
		case(state)
			S_IDLE:
			begin
				state_code <= 4'd1;
				if(find == 1'b1)
					state <= S_FIND;
				sd_sec_read_addr <= {sd_sec_read_addr[31:3],3'd0};//address 8 aligned
			end
			S_FIND:
			begin
				state_code <= 4'd2;
				if(sd_sec_read_end == 1'b1)
				begin
            	state_code <= 4'd3;
					if(found == 1'b1)
					begin
						state <= S_READ_WAIT;
						sd_sec_read <= 1'b0;
						write_req <= 1'b1;//start writing data
					end
					else
					begin
						//search every 8 sectors(4K)
						sd_sec_read_addr <= sd_sec_read_addr + 32'd8;
					end
				end
				else
				begin
					sd_sec_read <= 1'b1;
				end
			end
			S_READ_WAIT:
			begin
				if(write_req_ack == 1'b1)//write data response
				begin
					state <= S_READ;//read SD card data
					write_req <= 1'b0;
				end
			end
			S_READ:
			begin
				state_code <= 4'd4;
				if(sd_sec_read_end == 1'b1)
				begin
					sd_sec_read_addr <= sd_sec_read_addr + 32'd1;
					sd_sec_read <= 1'b0;
					// 修改结束条件：当读取到足够的像素数时结束，而不是读到文件末尾
					if(pixel_cnt >= total_pixels)
					begin
						state <= S_END;
						sd_sec_read <= 1'b0;
					end
				end
				else
				begin
					sd_sec_read <= 1'b1;
				end
			end
			S_END:
				state <= S_IDLE;
			default:
				state <= S_IDLE;
		endcase
end
endmodule