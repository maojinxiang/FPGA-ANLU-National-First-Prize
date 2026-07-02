// ============================================================
// 模块名称: udp_echo_test
// 功能描述: UDP回环测试（接收到UDP数据后原样发回）
//           用于验证UDP协议栈的发送功能
// ============================================================
module udp_echo_test(
    input               clk,
    input               rst_n,

    // UDP接收接口
    input               app_rx_data_valid,
    input [7:0]         app_rx_data,
    input [15:0]        app_rx_data_length,

    // UDP发送接口
    input               udp_tx_ready,
    input               app_tx_ack,
    output reg          app_tx_data_request,
    output reg          app_tx_data_valid,
    output reg [7:0]    app_tx_data,
    output reg [15:0]   udp_data_length
);

// 简单的回环：收到什么就发什么
reg [1:0] STATE;
localparam IDLE           = 2'd0;
localparam WAIT_ACK       = 2'd1;
localparam ECHO_DATA      = 2'd2;

reg [15:0] rx_length;
reg [15:0] tx_count;
reg [7:0]  echo_buffer[255:0];
reg [7:0]  rx_count;

// 接收数据到缓冲区
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rx_count <= 8'd0;
        rx_length <= 16'd0;
    end
    else begin
        if(app_rx_data_valid) begin
            echo_buffer[rx_count] <= app_rx_data;
            if(rx_count == 0) begin
                rx_length <= app_rx_data_length;
            end
            rx_count <= rx_count + 1'b1;
        end
        else if(STATE == ECHO_DATA && tx_count >= rx_length) begin
            rx_count <= 8'd0;
        end
    end
end

// 发送状态机
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        app_tx_data_request <= 1'b0;
        app_tx_data_valid   <= 1'b0;
        app_tx_data         <= 8'd0;
        udp_data_length     <= 16'd0;
        tx_count            <= 16'd0;
        STATE               <= IDLE;
    end
    else begin
        case(STATE)
            IDLE: begin
                app_tx_data_request <= 1'b0;
                app_tx_data_valid   <= 1'b0;
                tx_count            <= 16'd0;

                // 接收完成且有数据，准备回发
                if(rx_count > 0 && !app_rx_data_valid) begin
                    app_tx_data_request <= 1'b1;
                    udp_data_length     <= rx_length;
                    STATE               <= WAIT_ACK;
                end
            end

            WAIT_ACK: begin
                if(app_tx_ack) begin
                    app_tx_data_request <= 1'b0;
                    STATE               <= ECHO_DATA;
                end
            end

            ECHO_DATA: begin
                if(tx_count >= rx_length) begin
                    app_tx_data_valid <= 1'b0;
                    tx_count          <= 16'd0;
                    STATE             <= IDLE;
                end
                else begin
                    app_tx_data_valid <= 1'b1;
                    app_tx_data       <= echo_buffer[tx_count[7:0]];
                    tx_count          <= tx_count + 1'b1;
                end
            end

            default: STATE <= IDLE;
        endcase
    end
end

endmodule
