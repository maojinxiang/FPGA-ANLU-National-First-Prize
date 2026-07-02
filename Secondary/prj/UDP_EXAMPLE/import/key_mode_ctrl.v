// ============================================================
// 模块名称: key_mode_ctrl
// 功能描述: 按键模式控制模块
//           key3: 图片发送模式触发
//           key4: 母板模式切换（0x0001摄像头 ↔ 0x0003 SD卡）
// ============================================================
module key_mode_ctrl(
    input               clk,
    input               rst_n,
    input               key3,           // key3按键输入（低电平有效）
    input               key4,           // key4按键输入（低电平有效）

    // ===== 控制输出 =====
    output reg          img_mode,       // 1=图片发送模式，0=LED/数码管模式
    output reg          sd_trigger,     // SD卡读取触发信号（脉冲）
    output reg          img_send_start, // 图片发送启动信号（持续高电平）

    // ===== 母板模式切换输出 =====
    output reg [15:0]   mode_cmd,       // 发送给母板的模式命令
    output reg          mode_cmd_valid  // 命令有效信号（脉冲）
);

// ============================================================================
// 按键去抖动和边沿检测（key3）
// ============================================================================
reg [19:0]  key3_cnt;       // 按键去抖计数器
reg         key3_stable;    // 稳定后的按键值
reg         key3_stable_d1; // 延迟1拍
wire        key3_negedge;   // 按键按下沿

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        key3_cnt <= 20'd0;
        key3_stable <= 1'b1;
    end
    else begin
        if(key3 == key3_stable) begin
            key3_cnt <= 20'd0;
        end
        else begin
            key3_cnt <= key3_cnt + 1'd1;
            if(key3_cnt >= 20'd1000000) begin  // 8ms去抖
                key3_stable <= key3;
                key3_cnt <= 20'd0;
            end
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        key3_stable_d1 <= 1'b1;
    else
        key3_stable_d1 <= key3_stable;
end

assign key3_negedge = key3_stable_d1 && !key3_stable;  // 按下沿

// ============================================================================
// 按键去抖动和边沿检测（key4）
// ============================================================================
reg [19:0]  key4_cnt;       // 按键去抖计数器
reg         key4_stable;    // 稳定后的按键值
reg         key4_stable_d1; // 延迟1拍
wire        key4_negedge;   // 按键按下沿

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        key4_cnt <= 20'd0;
        key4_stable <= 1'b1;
    end
    else begin
        if(key4 == key4_stable) begin
            key4_cnt <= 20'd0;
        end
        else begin
            key4_cnt <= key4_cnt + 1'd1;
            if(key4_cnt >= 20'd1000000) begin  // 8ms去抖
                key4_stable <= key4;
                key4_cnt <= 20'd0;
            end
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        key4_stable_d1 <= 1'b1;
    else
        key4_stable_d1 <= key4_stable;
end

assign key4_negedge = key4_stable_d1 && !key4_stable;  // 按下沿

// ============================================================================
// key4: 母板模式切换逻辑（0x0001摄像头 ↔ 0x0003 SD卡）
// ============================================================================
reg         mode_toggle;     // 模式切换标志（0=SD卡0x0003, 1=摄像头0x0001）
reg [31:0]  mode_cmd_timer;  // 命令有效持续计数器

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mode_toggle <= 1'b0;         // 默认SD卡模式
        mode_cmd <= 16'h0003;        // 默认0x0003
        mode_cmd_valid <= 1'b0;
        mode_cmd_timer <= 32'd0;
    end
    else begin
        // 命令有效信号持续1ms后自动清零
        if(mode_cmd_valid && mode_cmd_timer > 0) begin
            mode_cmd_timer <= mode_cmd_timer - 1'd1;
            if(mode_cmd_timer == 32'd1) begin
                mode_cmd_valid <= 1'b0;
            end
        end

        // 检测key4按下，切换模式
        if(key4_negedge) begin
            mode_toggle <= ~mode_toggle;
            mode_cmd <= mode_toggle ? 16'h0003 : 16'h0001;  // 切换：0→1(0x0001), 1→0(0x0003)
            mode_cmd_valid <= 1'b1;
            mode_cmd_timer <= 32'd125000;  // 1ms @ 125MHz
        end
    end
end

// ============================================================================
// key3: 图片发送控制逻辑
// ============================================================================
localparam  IDLE        = 3'd0;  // 空闲
localparam  SD_PULSE    = 3'd1;  // SD卡触发脉冲
localparam  WAIT_SD     = 3'd2;  // 等待SD卡读取完成
localparam  SEND_PULSE  = 3'd3;  // 发送脉冲（保持一段时间）
localparam  COOLDOWN    = 3'd4;  // 冷却时间

reg [2:0]   STATE;
reg [31:0]  timer;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        STATE          <= IDLE;
        img_mode       <= 1'b0;
        sd_trigger     <= 1'b0;
        img_send_start <= 1'b0;
        timer          <= 32'd0;
    end
    else begin
        case(STATE)
            // ========== 状态0：空闲 ==========
            IDLE: begin
                img_mode       <= 1'b0;
                sd_trigger     <= 1'b0;
                img_send_start <= 1'b0;
                timer          <= 32'd0;

                // 检测按键按下
                if(key3_negedge) begin
                    img_mode   <= 1'b1;
                    sd_trigger <= 1'b1;
                    STATE      <= SD_PULSE;
                end
            end

            // ========== 状态1：SD卡触发脉冲（25ms）==========
            SD_PULSE: begin
                timer <= timer + 1'd1;

                if(timer >= 32'd3125000) begin  // 25ms @ 125MHz
                    sd_trigger <= 1'b0;
                    timer      <= 32'd0;
                    STATE      <= WAIT_SD;
                end
            end

            // ========== 状态2：等待SD卡读取（2秒）==========
            WAIT_SD: begin
                timer <= timer + 1'd1;

                // 等待2秒，确保SD卡读取完成
                if(timer >= 32'd250000000) begin  // 2s @ 125MHz
                    img_send_start <= 1'b1;  // 拉高发送信号
                    timer          <= 32'd0;
                    STATE          <= SEND_PULSE;
                end
            end

            // ========== 状态3：发送脉冲（保持3秒，足够发送完整帧）==========
            SEND_PULSE: begin
                timer <= timer + 1'd1;

                // 保持img_send_start高电平3秒
                // 640*480图片大约2-3秒发送完成
                if(timer >= 32'd375000000) begin  // 3s @ 125MHz
                    img_send_start <= 1'b0;  // 拉低信号
                    img_mode       <= 1'b0;
                    timer          <= 32'd0;
                    STATE          <= COOLDOWN;
                end
            end

            // ========== 状态4：冷却时间（1秒）==========
            COOLDOWN: begin
                timer <= timer + 1'd1;

                // 冷却1秒，防止误触发
                if(timer >= 32'd125000000) begin  // 1s @ 125MHz
                    timer <= 32'd0;
                    STATE <= IDLE;
                end
            end

            default: STATE <= IDLE;
        endcase
    end
end

endmodule
