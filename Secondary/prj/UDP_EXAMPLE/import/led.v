// ============================================================
// 模块名称: led
// 功能描述: UDP以太网控制LED和数码管显示
//           兼容Android_logic1_py上位机协议
// 协议格式:
//   8字节数据包:
//   byte0[7:4]: 单色LED控制（4位）
//   byte0[3:0]: 模式选择（0xF=LED模式，0x0=数码管模式）
//   byte1[7:0]: LED模式下为dled输出，数码管模式为数字7和6的BCD码
//   byte2[7:0]: LED模式下为tub输出，数码管模式为数字5和4的BCD码
//   byte3[7:0]: 数码管模式为数字3和2的BCD码
//   byte4[7:0]: 数码管模式为数字1和0的BCD码
//   byte5-7: 保留（未使用）
// ============================================================
module led(
    input                                 app_rx_data_valid       ,
    input                 [   7:   0]     app_rx_data             ,
    input  wire           [  15:   0]     app_rx_data_length      ,
    input                                 udp_rx_clk              ,
    input  wire                           reset                   ,

    output          [3:0] led_data_1 ,
    output reg      [7:0] dled ,
    output reg      [7:0] tub
);

// 数据接收缓冲区和计数器
reg  [63:0]led_data;
reg  [15:0] cnt;

// 数码管相关寄存器
reg  [3:0]  bcd_code[7:0];      // 8个数字的BCD码
reg  [7:0]  seg_decode[7:0];    // 8个数字的段码
reg  [15:0] scan_div;            // 扫描分频计数器
reg  [2:0]  scan_cnt;            // 扫描位选计数器（0~7）

integer i;

// ============================================================
// 1. UDP数据接收计数器
// ============================================================
always @(posedge udp_rx_clk or negedge reset) begin
    if(!reset)  begin
        cnt <= 16'b0;
    end
    else if (app_rx_data_valid & cnt<(app_rx_data_length-1)) begin
        cnt <= cnt+1;
    end
    else if (app_rx_data_valid & cnt==(app_rx_data_length-1))
        cnt <= 16'b0;
    else
        cnt <= cnt;
end

// ============================================================
// 2. 接收UDP数据到64位缓冲区
// ============================================================
always @(posedge udp_rx_clk or negedge reset) begin
    if(!reset)
        led_data <= 64'b0;
    else if (app_rx_data_valid)
        case (cnt)
            0: led_data[63:56] <= app_rx_data;  // byte0: 单色LED[7:4] + 模式选择[3:0]
            1: led_data[55:48] <= app_rx_data;  // byte1: LED模式=dled, 数码管=数字7/6
            2: led_data[47:40] <= app_rx_data;  // byte2: LED模式=tub, 数码管=数字5/4
            3: led_data[39:32] <= app_rx_data;  // byte3: 数码管=数字3/2
            4: led_data[31:24] <= app_rx_data;  // byte4: 数码管=数字1/0
            5: led_data[23:16] <= app_rx_data;  // byte5: 保留
            6: led_data[15:8]  <= app_rx_data;  // byte6: 保留
            7: led_data[7:0]   <= app_rx_data;  // byte7: 保留
        endcase
    else
        led_data <= led_data;
end

// ============================================================
// 3. 提取BCD码（用于数码管显示）
// ============================================================
always @(posedge udp_rx_clk or negedge reset) begin
    if(!reset) begin
        for(i=0; i<8; i=i+1) begin
            bcd_code[i] <= 4'b0000;
        end
    end
    else begin
        // byte1[7:4]=数字7, byte1[3:0]=数字6
        bcd_code[7] <= led_data[55:52];
        bcd_code[6] <= led_data[51:48];
        // byte2[7:4]=数字5, byte2[3:0]=数字4
        bcd_code[5] <= led_data[47:44];
        bcd_code[4] <= led_data[43:40];
        // byte3[7:4]=数字3, byte3[3:0]=数字2
        bcd_code[3] <= led_data[39:36];
        bcd_code[2] <= led_data[35:32];
        // byte4[7:4]=数字1, byte4[3:0]=数字0
        bcd_code[1] <= led_data[31:28];
        bcd_code[0] <= led_data[27:24];
    end
end

// ============================================================
// 4. 数码管BCD到7段码解码
// ============================================================
always @(posedge udp_rx_clk or negedge reset) begin
    if(!reset) begin
        for(i=0; i<8; i=i+1) begin
            seg_decode[i] <= 8'b11111111;  // 复位全灭（共阳极）
        end
    end
    else begin
        // 对8个数字分别解码
        for(i=0; i<8; i=i+1) begin
            case(bcd_code[i])
                4'h0: seg_decode[i] <= 8'b1100_0000;  // 0
                4'h1: seg_decode[i] <= 8'b1111_1001;  // 1
                4'h2: seg_decode[i] <= 8'b1010_0100;  // 2
                4'h3: seg_decode[i] <= 8'b1011_0000;  // 3
                4'h4: seg_decode[i] <= 8'b1001_1001;  // 4
                4'h5: seg_decode[i] <= 8'b1001_0010;  // 5
                4'h6: seg_decode[i] <= 8'b1000_0010;  // 6
                4'h7: seg_decode[i] <= 8'b1111_1000;  // 7
                4'h8: seg_decode[i] <= 8'b1000_0000;  // 8
                4'h9: seg_decode[i] <= 8'b1001_0000;  // 9
                4'hE: seg_decode[i] <= 8'b1111_1111;  // 空格（用于前导空格）
                default: seg_decode[i] <= 8'b1111_1111;  // 其他值熄灭
            endcase
        end
    end
end

// ============================================================
// 5. 数码管扫描计数器（约1kHz扫描频率）
// ============================================================
always @(posedge udp_rx_clk or negedge reset) begin
    if(!reset) begin
        scan_div <= 16'd0;
        scan_cnt <= 3'b000;
    end
    else begin
        scan_div <= scan_div + 1'b1;
        // scan_div溢出时切换扫描位
        if(scan_div == 16'hFFFF) begin
            scan_cnt <= scan_cnt + 1'b1;
        end
    end
end

// ============================================================
// 6. 输出控制：根据模式选择LED或数码管输出
// ============================================================
always @(posedge udp_rx_clk or negedge reset) begin
    if(!reset) begin
        tub  <= 8'b11111111;  // 复位时全灭
        dled <= 8'b11111111;
    end
    else begin
        case(led_data[59:56])  // byte0[3:0] = 模式选择
            4'hF: begin  // LED模式（上位机发送0xF）
                tub  <= led_data[47:40];  // 直接输出byte2到tub
                dled <= led_data[55:48];  // 直接输出byte1到dled
            end
            4'h0: begin  // 数码管模式（上位机发送0x0）
                // 动态扫描显示8位数码管
                case(scan_cnt)
                    3'd0: begin tub <= seg_decode[7]; dled <= 8'b11111110; end  // 数字7
                    3'd1: begin tub <= seg_decode[6]; dled <= 8'b11111101; end  // 数字6
                    3'd2: begin tub <= seg_decode[5]; dled <= 8'b11111011; end  // 数字5
                    3'd3: begin tub <= seg_decode[4]; dled <= 8'b11110111; end  // 数字4
                    3'd4: begin tub <= seg_decode[3]; dled <= 8'b11101111; end  // 数字3
                    3'd5: begin tub <= seg_decode[2]; dled <= 8'b11011111; end  // 数字2
                    3'd6: begin tub <= seg_decode[1]; dled <= 8'b10111111; end  // 数字1
                    3'd7: begin tub <= seg_decode[0]; dled <= 8'b01111111; end  // 数字0
                    default: begin tub <= 8'b11111111; dled <= 8'b11111111; end
                endcase
            end
            default: begin  // 其他模式：保持熄灭
                tub  <= 8'b11111111;
                dled <= 8'b11111111;
            end
        endcase
    end
end

// ============================================================
// 7. 单色LED输出（4个LED灯）
// ============================================================
assign led_data_1 = led_data[63:60];  // byte0[7:4] = 单色LED控制

endmodule
